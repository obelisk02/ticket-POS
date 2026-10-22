@echo off
title Asistente de Configuracion de Impresora Termica POS
color 0A
echo ================================================================
echo    ASISTENTE DE DIAGNOSTICO Y DRIVER DE IMPRESORA POS (SIX)
echo ================================================================
echo.
powershell -ExecutionPolicy Bypass -NoProfile -Command "& {
    Write-Host '1. Escaneando impresoras instaladas en Windows...' -ForegroundColor Yellow
    $printers = Get-Printer | Select-Object Name, DriverName, PortName, PrinterStatus
    $printers | Format-Table -AutoSize
    
    Write-Host '2. Escaneando puertos de comunicacion (USB / COM / Serie)...' -ForegroundColor Yellow
    $ports = Get-PrinterPort | Where-Object { $_.Name -match 'USB|COM' } | Select-Object Name, Description
    $ports | Format-Table -AutoSize
    
    Write-Host '3. Escaneando dispositivos USB/POS conectados...' -ForegroundColor Yellow
    $posPnp = Get-CimInstance Win32_PnPEntity | Where-Object { $_.Name -match 'POS|Printer|Thermal|Ticket|Print|Serial' } | Select-Object Name, DeviceID, Status
    if ($posPnp) {
        $posPnp | Format-Table -AutoSize
    } else {
        Write-Host '   (No se detectaron dispositivos con nombre explicito POS/Thermal en PnP)' -ForegroundColor DarkGray
    }

    Write-Host '----------------------------------------------------------------' -ForegroundColor Cyan
    Write-Host 'CONSEJO DE CONFIGURACION PARA TU IMPRESORA TERMICA:' -ForegroundColor White
    Write-Host ' - Si tu impresora viene con instalador (POS-58 / POS-80 / Xprinter):' -ForegroundColor Green
    Write-Host '   Ejecuta su instalador de fabrica y asignala al puerto USB (generalmente USB001).'
    Write-Host ' - En las Propiedades de la Impresora en Windows -> Opciones avanzadas:'
    Write-Host '   Configura el tamano de papel en: 80 x 297 mm (o Roll Paper 80mm / 58mm).'
    Write-Host ' - Nuestra solucion ya detectara automaticamente la impresora en el selector web.'
    Write-Host '----------------------------------------------------------------' -ForegroundColor Cyan
}"
echo.
echo Presiona cualquier tecla para salir...
pause >nul
