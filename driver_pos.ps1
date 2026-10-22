<#
.SYNOPSIS
    Driver y Spooler de Impresion para Impresoras Termicas POS (SIX Tickets)
.DESCRIPTION
    Permite enviar datos RAW (ESC/POS) o paginas HTML renderizadas directamente
    a cualquier impresora termica POS instalada en Windows usando la API Win32 de Spooler.
#>

param (
    [string]$Accion = "list",            # "list", "print-raw", "print-html", "test"
    [string]$Impresora = "",             # Nombre de la impresora (o default)
    [string]$Archivo = "",               # Ruta del archivo HTML o RAW
    [string]$Texto = "",                 # Texto o comandos a enviar
    [int]$AnchoMm = 80,                  # 80 o 58 mm
    [switch]$CortePapel                  # Enviar comando de corte de papel al final
)

# Cargar Helper Win32 Spooler para impresion RAW directa
$rawPrinterCode = @'
using System;
using System.IO;
using System.Runtime.InteropServices;

public class RawPrinterHelper {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public class DOCINFOA {
        [MarshalAs(UnmanagedType.LPStr)] public string pDocName;
        [MarshalAs(UnmanagedType.LPStr)] public string pOutputFile;
        [MarshalAs(UnmanagedType.LPStr)] public string pDataType;
    }

    [DllImport("winspool.Drv", EntryPoint = "OpenPrinterA", SetLastError = true, CharSet = CharSet.Ansi, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
    public static extern bool OpenPrinter([MarshalAs(UnmanagedType.LPStr)] string szPrinter, out IntPtr hPrinter, IntPtr pd);

    [DllImport("winspool.Drv", EntryPoint = "ClosePrinter", SetLastError = true, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
    public static extern bool ClosePrinter(IntPtr hPrinter);

    [DllImport("winspool.Drv", EntryPoint = "StartDocPrinterA", SetLastError = true, CharSet = CharSet.Ansi, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
    public static extern bool StartDocPrinter(IntPtr hPrinter, Int32 level, [In, MarshalAs(UnmanagedType.LPStruct)] DOCINFOA di);

    [DllImport("winspool.Drv", EntryPoint = "EndDocPrinter", SetLastError = true, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
    public static extern bool EndDocPrinter(IntPtr hPrinter);

    [DllImport("winspool.Drv", EntryPoint = "StartPagePrinter", SetLastError = true, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
    public static extern bool StartPagePrinter(IntPtr hPrinter);

    [DllImport("winspool.Drv", EntryPoint = "EndPagePrinter", SetLastError = true, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
    public static extern bool EndPagePrinter(IntPtr hPrinter);

    [DllImport("winspool.Drv", EntryPoint = "WritePrinter", SetLastError = true, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
    public static extern bool WritePrinter(IntPtr hPrinter, IntPtr pBytes, Int32 dwCount, out Int32 dwWritten);

    public static bool SendBytesToPrinter(string szPrinterName, byte[] bytes) {
        IntPtr hPrinter = new IntPtr(0);
        DOCINFOA di = new DOCINFOA();
        bool bSuccess = false;
        di.pDocName = "Ticket SIX POS";
        di.pDataType = "RAW";

        if (OpenPrinter(szPrinterName, out hPrinter, IntPtr.Zero)) {
            if (StartDocPrinter(hPrinter, 1, di)) {
                if (StartPagePrinter(hPrinter)) {
                    IntPtr pUnmanagedBytes = Marshal.AllocCoTaskMem(bytes.Length);
                    Marshal.Copy(bytes, 0, pUnmanagedBytes, bytes.Length);
                    int dwWritten = 0;
                    bSuccess = WritePrinter(hPrinter, pUnmanagedBytes, bytes.Length, out dwWritten);
                    Marshal.FreeCoTaskMem(pUnmanagedBytes);
                    EndPagePrinter(hPrinter);
                }
                EndDocPrinter(hPrinter);
            }
            ClosePrinter(hPrinter);
        }
        return bSuccess;
    }
}
'@

if (-not ([System.Management.Automation.PSTypeName]'RawPrinterHelper').Type) {
    Add-Type -TypeDefinition $rawPrinterCode
}

# Funciones de Soporte
function Get-ListaImpresoras {
    $printers = Get-Printer | Select-Object Name, DriverName, PortName, PrinterStatus, Type
    return $printers
}

function Send-EscPosRaw {
    param(
        [string]$printerName,
        [byte[]]$bytes
    )

    if (-not $printerName) {
        $defaultPrinterObj = Get-CimInstance -ClassName Win32_Printer | Where-Object { $_.Default -eq $true }
        if ($defaultPrinterObj) {
            $printerName = $defaultPrinterObj.Name
        } else {
            $first = Get-Printer | Select-Object -First 1
            if ($first) { $printerName = $first.Name }
        }
    }

    if (-not $printerName) {
        Write-Host "Error: No se encontro ninguna impresora configurada." -ForegroundColor Red
        return $false
    }

    Write-Host "Enviando $($bytes.Length) bytes RAW a '$printerName'..." -ForegroundColor Cyan
    $ok = [RawPrinterHelper]::SendBytesToPrinter($printerName, $bytes)
    if ($ok) {
        Write-Host "[OK] Impresion enviada con exito al spooler de '$printerName'." -ForegroundColor Green
        return $true
    } else {
        $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-Host "[X] Error al enviar a '$printerName'. Codigo Win32: $err" -ForegroundColor Red
        return $false
    }
}

function Build-EscPosTicket {
    param(
        [hashtable]$t,
        [int]$ancho = 80
    )

    $ms = New-Object System.IO.MemoryStream

    # Comandos ESC/POS estandar
    $ESC = 0x1B
    $GS  = 0x1D
    $LF  = 0x0A

    # Inicializar impresora: ESC @
    $ms.WriteByte($ESC); $ms.WriteByte(0x40)

    # Seleccion de pagina de codigos (CP850 / Multilingual): ESC t 2
    $ms.WriteByte($ESC); $ms.WriteByte(0x74); $ms.WriteByte(0x02)

    # Helper para escribir texto con encoding IBM850 / Latin1
    $encoding = [System.Text.Encoding]::GetEncoding("iso-8859-1")

    # Helper para alineacion: 0 = Izquierda, 1 = Centro, 2 = Derecha
    function Set-AlignLocal([int]$a) {
        $ms.WriteByte($ESC); $ms.WriteByte(0x61); $ms.WriteByte($a)
    }

    # Helper para negrita: 1 = On, 0 = Off
    function Set-BoldLocal([int]$b) {
        $ms.WriteByte($ESC); $ms.WriteByte(0x45); $ms.WriteByte($b)
    }

    function Write-TextLocal([string]$txt) {
        $b = $encoding.GetBytes($txt)
        $ms.Write($b, 0, $b.Length)
    }

    # Ancho de linea (columnas) segun 80mm o 58mm
    $cols = if ($ancho -eq 58) { 32 } else { 46 }

    # --- ENCABEZADO ---
    Set-AlignLocal 1
    Set-BoldLocal 1
    # Titulo SIX en doble tamano
    $ms.WriteByte($GS); $ms.WriteByte(0x21); $ms.WriteByte(0x11) # Double height & width
    Write-TextLocal "*** SIX ***`n"
    $ms.WriteByte($GS); $ms.WriteByte(0x21); $ms.WriteByte(0x00) # Normal size
    Set-BoldLocal 0

    Write-TextLocal "CONTROLADORA DE NEGOCIOS COMERCIALES`n"
    Write-TextLocal "RFC: CNC820428674`n"
    Write-TextLocal "Ave. Alfonso Reyes # 2202, Col. Bella Vista`n"
    Write-TextLocal "Monterrey, Nuevo Leon, MEX. C.P. 64410`n"
    Write-TextLocal "Regimen General de Ley Personas Morales`n"
    Write-TextLocal ("-" * $cols + "`n")

    Set-BoldLocal 1
    Write-TextLocal "TICKET DE VENTA`n"
    Set-BoldLocal 0

    # --- DATOS DEL TICKET ---
    Set-AlignLocal 0
    $folioStr = "Folio: " + $t.Folio
    $statusStr = "Estatus: " + $t.Estatus
    $padSpace = $cols - $folioStr.Length - $statusStr.Length
    if ($padSpace -lt 1) { $padSpace = 1 }
    Write-TextLocal ($folioStr + (" " * $padSpace) + $statusStr + "`n")
    Write-TextLocal ("CECO: " + $t.Ceco + "`n")
    Write-TextLocal ("Nombre: " + $t.Nombre + "`n")
    Write-TextLocal ("C.U: " + $t.CU + "`n")
    Write-TextLocal ("Lugar exp: " + $t.Lugar + "`n")
    Write-TextLocal ("Fecha exp: " + $t.Fecha + "`n")
    Write-TextLocal ("-" * $cols + "`n")

    # --- TABLA DE PRODUCTOS ---
    $wCant = 3
    $wTot = 8
    $wDesc = $cols - $wCant - $wTot - 2
    if ($wDesc -lt 10) { $wDesc = 10 }

    Set-BoldLocal 1
    $head = "Cant " + "Descripcion".PadRight($wDesc).Substring(0, $wDesc) + "  " + "Total".PadLeft($wTot)
    Write-TextLocal ($head + "`n")
    Set-BoldLocal 0
    Write-TextLocal ("-" * $cols + "`n")

    foreach ($prod in $t.Productos) {
        $cantStr = $prod.Cant.ToString().PadRight($wCant).Substring(0, $wCant)
        $totStr = ("$" + [string]::Format("{0:N2}", [double]$prod.Total)).PadLeft($wTot)
        
        $descRaw = $prod.Desc
        if ($descRaw.Length -gt $wDesc) {
            $descLine1 = $descRaw.Substring(0, $wDesc)
            $descRest = $descRaw.Substring($wDesc).Trim()
            Write-TextLocal ($cantStr + " " + $descLine1 + " " + $totStr + "`n")
            while ($descRest.Length -gt 0) {
                $chunkLen = [math]::Min($wDesc, $descRest.Length)
                $chunk = $descRest.Substring(0, $chunkLen)
                $descRest = $descRest.Substring($chunkLen).Trim()
                Write-TextLocal ((" " * ($wCant + 1)) + $chunk + "`n")
            }
        } else {
            $descPadded = $descRaw.PadRight($wDesc)
            Write-TextLocal ($cantStr + " " + $descPadded + " " + $totStr + "`n")
        }
    }

    Write-TextLocal ("-" * $cols + "`n")

    # --- TOTALES ---
    Set-AlignLocal 2
    Set-BoldLocal 1
    $ms.WriteByte($GS); $ms.WriteByte(0x21); $ms.WriteByte(0x01) # Double height
    $totFormatted = "$" + [string]::Format("{0:N2}", [double]$t.Total)
    Write-TextLocal ("TOTAL: " + $totFormatted + "`n")
    $ms.WriteByte($GS); $ms.WriteByte(0x21); $ms.WriteByte(0x00) # Normal
    Set-BoldLocal 0

    Set-AlignLocal 1
    Write-TextLocal ($t.TotalLetra + "`n`n")

    # --- FOOTER ---
    Write-TextLocal "Tipo de pago: Efectivo`n`n"
    Write-TextLocal "Necesitas Factura? Envia tu ticket,`n"
    Write-TextLocal "CSF y forma de pago a facturacionsix@expins.mx`n"
    Write-TextLocal "Dudas? 800 CERVEZA (2378392)`n`n"
    Set-BoldLocal 1
    Write-TextLocal "PAGO EN UNA SOLA EXHIBICION`n"
    Set-BoldLocal 0

    # Avance de papel (4 lineas en blanco)
    Write-TextLocal "`n`n`n`n"

    # Corte de papel completo: GS V 0
    $ms.WriteByte($GS); $ms.WriteByte(0x56); $ms.WriteByte(0x00)

    $resultBytes = $ms.ToArray()
    $ms.Dispose()
    return $resultBytes
}

function Print-HtmlTicketHeadless {
    param(
        [string]$printerName,
        [string]$htmlPath
    )

    if (-not (Test-Path $htmlPath)) {
        Write-Host "Error: No existe el archivo HTML: $htmlPath" -ForegroundColor Red
        return $false
    }
    
    $fullPath = (Resolve-Path $htmlPath).Path
    $edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    if (-not (Test-Path $edgePath)) {
        $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
    }

    if (Test-Path $edgePath) {
        Write-Host "Imprimiendo '$fullPath' a traves de Microsoft Edge hacia '$printerName'..." -ForegroundColor Cyan
        $args = "--headless --disable-gpu --no-margins --print-to-printer=`"$printerName`" `"file:///$fullPath`""
        $process = Start-Process -FilePath $edgePath -ArgumentList $args -PassThru -Wait
        return $true
    } else {
        Write-Host "Edge no encontrado para impresion directa. Abriendo en navegador..." -ForegroundColor Yellow
        Start-Process $fullPath
        return $true
    }
}

# --- EJECUCIÓN SEGÚN ACCIÓN ---
switch ($Accion.ToLower()) {
    "list" {
        Write-Host "=== IMPRESORAS INSTALADAS EN WINDOWS ===" -ForegroundColor Yellow
        $lista = Get-ListaImpresoras
        $lista | Format-Table Name, DriverName, PortName, PrinterStatus -AutoSize
    }

    "test" {
        $testTicket = @{
            Folio = "T-TEST99"
            Estatus = "Liberada"
            Ceco = "300481920"
            Nombre = "MICH SIX CAMELINAS"
            CU = [guid]::NewGuid().ToString().ToLower()
            Lugar = "Morelia, Michoacan"
            Fecha = (Get-Date -Format "dd/MM/yyyy hh:mm tt")
            Productos = @(
                @{ Cant = 2; Desc = "INDIO BEAUTY 4X6 BOT 355ML"; Total = 161.04 },
                @{ Cant = 3; Desc = "Strongbow Rose 1X12 BOT 330ML"; Total = 122.42 },
                @{ Cant = 1; Desc = "Strongbow Honey Local 1X8 BOT"; Total = 68.54 }
            )
            Total = 352.00
            TotalLetra = "TRESCIENTOS CINCUENTA Y DOS 00/100 PESOS M.N."
        }

        $bytes = Build-EscPosTicket -t $testTicket -ancho $AnchoMm
        Send-EscPosRaw -printerName $Impresora -bytes $bytes
    }

    "print-raw" {
        if ($Archivo -and (Test-Path $Archivo)) {
            $bytes = [System.IO.File]::ReadAllBytes($Archivo)
            Send-EscPosRaw -printerName $Impresora -bytes $bytes
        } elseif ($Texto) {
            $encoding = [System.Text.Encoding]::GetEncoding("iso-8859-1")
            $bytes = $encoding.GetBytes($Texto)
            if ($CortePapel) {
                $bytes += [byte[]]@(0x0A, 0x0A, 0x0A, 0x1D, 0x56, 0x00)
            }
            Send-EscPosRaw -printerName $Impresora -bytes $bytes
        } else {
            Write-Host "Especifique -Archivo o -Texto para imprimir en modo RAW." -ForegroundColor Red
        }
    }

    "print-html" {
        if ($Archivo -and (Test-Path $Archivo)) {
            Print-HtmlTicketHeadless -printerName $Impresora -htmlPath $Archivo
        } else {
            Write-Host "Especifique una ruta valida en -Archivo." -ForegroundColor Red
        }
    }

    default {
        Write-Host "Accion desconocida: $Accion. Use 'list', 'test', 'print-raw', o 'print-html'." -ForegroundColor Red
    }
}
