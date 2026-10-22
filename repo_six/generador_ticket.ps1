param (
    [double]$Total = 0,
    [string]$Fecha = "",
    [string]$Folio = "",
    [string]$Ceco = "",
    [string]$Nombre = "",
    [string]$CU = "",
    [string]$Lugar = "Morelia, Michoacán",
    [int]$NumItems = 0,
    [string]$OutputFile = ""
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Convert-NumberToSpanishWords([long]$n) {
    if ($n -eq 0) { return "CERO" }
    
    $unidades = @("", "UN", "DOS", "TRES", "CUATRO", "CINCO", "SEIS", "SIETE", "OCHO", "NUEVE",
                  "DIEZ", "ONCE", "DOCE", "TRECE", "CATORCE", "QUINCE", "DIECISEIS", "DIECISIETE",
                  "DIECIOCHO", "DIECINUEVE", "VEINTE", "VEINTIUN", "VEINTIDOS", "VEINTITRES",
                  "VEINTICUATRO", "VEINTICINCO", "VEINTISEIS", "VEINTISIETE", "VEINTIOCHO", "VEINTINUEVE")
    $decenas = @("", "DIEZ", "VEINTE", "TREINTA", "CUARENTA", "CINCUENTA", "SESENTA", "SETENTA", "OCHENTA", "NOVENTA")
    $centenas = @("", "CIENTO", "DOSCIENTOS", "TRESCIENTOS", "CUATROCIENTOS", "QUINIENTOS", "SEISCIENTOS", "SETECIENTOS", "OCHOCIENTOS", "NOVECIENTOS")

    function ConvertGroup([int]$num) {
        $res = ""
        $c = [math]::Floor($num / 100)
        $resto = $num % 100
        
        if ($num -eq 100) { return "CIEN" }
        if ($c -gt 0) {
            $res += $centenas[$c] + " "
        }
        
        if ($resto -lt 30) {
            $res += $unidades[$resto]
        } else {
            $d = [math]::Floor($resto / 10)
            $u = $resto % 10
            $res += $decenas[$d]
            if ($u -gt 0) {
                $res += " Y " + $unidades[$u]
            }
        }
        return $res.Trim()
    }

    $resFinal = ""
    $millones = [math]::Floor($n / 1000000)
    $miles = [math]::Floor(($n % 1000000) / 1000)
    $unid = $n % 1000

    if ($millones -gt 0) {
        if ($millones -eq 1) {
            $resFinal += "UN MILLON "
        } else {
            $resFinal += (ConvertGroup $millones) + " MILLONES "
        }
    }

    if ($miles -gt 0) {
        if ($miles -eq 1) {
            $resFinal += "UN MIL "
        } else {
            $resFinal += (ConvertGroup $miles) + " MIL "
        }
    }

    if ($unid -gt 0) {
        $resFinal += (ConvertGroup $unid)
    }

    return $resFinal.Trim()
}

# Sucursales SIX oficiales
$sucursales = @(
    @{ Nombre = "MICH SIX CAMELINAS"; Ceco = "300481920" },
    @{ Nombre = "MICH SIX VENTURA PUENTE"; Ceco = "300482105" },
    @{ Nombre = "MICH SIX LA HUERTA"; Ceco = "300483421" },
    @{ Nombre = "MICH SIX ALTOZANO"; Ceco = "300485632" },
    @{ Nombre = "MICH SIX ACUEDUCTO"; Ceco = "300489710" },
    @{ Nombre = "MICH SIX SOLIDARIDAD"; Ceco = "300486240" },
    @{ Nombre = "MICH SIX LAS TIJERAS"; Ceco = "300481194" },
    @{ Nombre = "MICH SIX MADERO PONIENTE"; Ceco = "300487315" }
)

# Total entre 200 y 600 pesos si no se especifica
if ($Total -le 200 -or $Total -gt 600) {
    # Generar total aleatorio creíble entre 205 y 595
    $base = Get-Random -Minimum 205 -Maximum 595
    $conCentavos = (Get-Random -Minimum 0 -Maximum 4) -eq 0
    $Total = if ($conCentavos) { $base + 0.50 } else { [double]$base }
}

# Sucursal y CECO aleatorios si no se especifican
if (-not $Nombre -or -not $Ceco) {
    $selSuc = $sucursales | Get-Random
    if (-not $Nombre) { $Nombre = $selSuc.Nombre }
    if (-not $Ceco) { $Ceco = $selSuc.Ceco }
}

# Defaults
if (-not $Folio) {
    $Folio = "T-" + (Get-Random -Minimum 100000 -Maximum 999999)
}
if (-not $CU) {
    $CU = [guid]::NewGuid().ToString().ToLower()
}
if (-not $Fecha) {
    $now = Get-Date
    # Hora comercial creíble (10am a 10pm)
    $h24 = Get-Random -Minimum 10 -Maximum 22
    $min = Get-Random -Minimum 0 -Maximum 59
    $amPm = if ($h24 -lt 12) { "a. m." } else { "p. m." }
    $h12 = if ($h24 % 12 -eq 0) { 12 } else { $h24 % 12 }
    $Fecha = "{0:D2}/{1:D2}/{2:D4} {3:D2}:{4:D2} {5}" -f $now.Day, $now.Month, $now.Year, $h12, $min, $amPm
}

# Cantidad de productos adaptada al monto si no se especifica
if ($NumItems -le 0) {
    if ($Total -lt 500) { $NumItems = Get-Random -Minimum 2 -Maximum 4 }
    elseif ($Total -lt 1000) { $NumItems = Get-Random -Minimum 3 -Maximum 5 }
    else { $NumItems = Get-Random -Minimum 3 -Maximum 6 }
}

# Load products
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$prodsPath = Join-Path $scriptDir "productos.json"
$prods = Get-Content -Path $prodsPath -Encoding UTF8 | ConvertFrom-Json

# Pick random products
if ($NumItems -lt 1) { $NumItems = 2 }
if ($NumItems -gt $prods.Count) { $NumItems = $prods.Count }

$selected = $prods | Get-Random -Count $NumItems
if ($selected -is [string]) { $selected = @($selected) }

# Distribute total
$itemsData = @()
$remaining = $Total

for ($i = 0; $i -lt $selected.Count; $i++) {
    $p = $selected[$i]
    if ($i -eq $selected.Count - 1) {
        $lineTot = [math]::Round($remaining, 2)
    } else {
        $minPortion = 20.0
        $maxPortion = $remaining - (($selected.Count - 1 - $i) * $minPortion)
        if ($maxPortion -le $minPortion) {
            $lineTot = [math]::Round($remaining / ($selected.Count - $i), 0)
        } else {
            $lineTot = [math]::Round((Get-Random -Minimum ([int]$minPortion) -Maximum ([int]$maxPortion)), 0)
        }
    }
    $remaining -= $lineTot
    
    # Assign realistic quantity: 1, 2, 3, 4, 6
    $possibleQ = @(1, 1, 1, 2, 2, 3, 4, 6) | Where-Object { $_ -le [math]::Floor($lineTot / 15) }
    $cant = if ($possibleQ.Count -gt 0) { $possibleQ | Get-Random } else { 1 }

    $itemsData += [PSCustomObject]@{
        Cant = $cant
        Desc = $p
        Total = $lineTot
    }
}

# Number to words
$pesos = [long][math]::Floor($Total)
$centavos = [int][math]::Round(($Total - $pesos) * 100)
$centavosStr = "{0:D2}/100 PESOS M.N." -f $centavos
$totalEnLetra = (Convert-NumberToSpanishWords $pesos) + " " + $centavosStr

# Build table rows HTML
$filasHtml = ""
foreach ($item in $itemsData) {
    $totFormatted = ("$" + [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F2}", $item.Total))
    $filasHtml += @"
      <tr>
        <td class="col-cant">$($item.Cant)</td>
        <td class="col-desc">$($item.Desc)</td>
        <td class="col-tot">$totFormatted</td>
      </tr>
"@ + "`n"
}
$filasHtml = $filasHtml.TrimEnd()

# Load template and replace
$tmplPath = Join-Path $scriptDir "plantilla_ticket.html"
$tmpl = Get-Content -Path $tmplPath -Raw -Encoding UTF8

$totalFormatted = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F2}", $Total)

$html = $tmpl.Replace("{{FOLIO}}", $Folio)
$html = $html.Replace("{{ESTATUS}}", "Liberada")
$html = $html.Replace("{{CECO}}", $Ceco)
$html = $html.Replace("{{NOMBRE}}", $Nombre)
$html = $html.Replace("{{CU}}", $CU)
$html = $html.Replace("{{LUGAR_EXP}}", $Lugar)
$html = $html.Replace("{{FECHA_EXP}}", $Fecha)
$html = $html.Replace("{{FILAS_PRODUCTOS}}", $filasHtml)
$html = $html.Replace("{{TOTAL}}", $totalFormatted)
$html = $html.Replace("{{TOTAL_LETRA}}", $totalEnLetra)

if ($OutputFile) {
    [System.IO.File]::WriteAllText($OutputFile, $html, [System.Text.Encoding]::UTF8)
    Write-Output "Ticket generado exitosamente en: $OutputFile"
} else {
    Write-Output $html
}
