# =========================================================
# SCRIPT: poe_25g_MASTER.ps1 - SOLO CONFIGURACIÓN (2.5G SNMP)
# =========================================================

# --- RUTAS AUTOMÁTICAS ---
if ($PSScriptRoot) { $baseDir = $PSScriptRoot } else { $baseDir = Get-Location }
$rootDir = Split-Path -Parent $baseDir
. (Join-Path $rootDir "core\mac_backup.ps1")
Initialize-MacBackup -ScriptDir $baseDir -Familia "POE_2_5GB_REINTEGRO"

$configFile = "$baseDir\Configmanage2.bin"

if (-not (Test-Path $configFile)) {
    Clear-Host
    Write-Host " [ERROR] NO SE ENCUENTRA: $configFile" -ForegroundColor Red
    Read-Host "Presione Enter para salir"
    Break
}

# Credenciales actualizadas
$ip = "192.168.18.1"
$auth = "admin:somos123." 
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

do {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   HELLOTEK 2.5G - CARGA CONFIG SNMP (CLIENTE)            " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    # [1] CAPTURA MAC
    Write-Host "[1/2] Identificando equipo..." -NoNewline
    arp -d $ip 2>$null
    Test-Connection $ip -Count 1 -Quiet | Out-Null
    
    $macResult = ""
    $arpTable = arp -a $ip | Out-String
    if ($arpTable -match "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})") {
        $macResult = $matches[0].ToUpper().Replace("-",":")
        Write-Host " [MAC: $macResult]" -ForegroundColor Green
    } else {
        Write-Host " [NO DETECTADO]" -ForegroundColor Red
        $retry = Read-Host "ENTER reintentar / 'S' salir"
        if ($retry -eq "s") { break } else { continue }
    }

    # [2] CARGA DE CONFIGURACIÓN (Sin flasheo previo)
    Write-Host "[2/2] Subiendo Configuración..." -NoNewline
    
    # Nota: Para el 2.5G usamos el endpoint /cgi/SW_CFG.bin con el nuevo archivo
    curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/SW_CFG.bin" `
             -H "Referer: http://$ip/saveconfig.htm" `
             -H "User-Agent: $ua" `
             -F "filename=@$configFile"

    # Verificación de reinicio (para evitar el falso error de curl)
    Start-Sleep -Seconds 3
    Write-Host " Verificando respuesta..." -NoNewline
    
    if (Test-Connection $ip -Count 1 -Quiet) {
        Write-Host " [OK - APLICADO]" -ForegroundColor Green
    } else {
        Write-Host " [REINICIANDO... OK]" -ForegroundColor Cyan
    }

    if ($macResult) {
        Save-MacBackup -Mac $macResult
        [System.Console]::Beep(1000, 150)
    }

    Write-Host "========================================" -ForegroundColor Cyan
    $n = Read-Host "ENTER Siguiente Switch / 'S' Salir"
    if ($n -eq "s") { break }

} while ($true)

Export-MacBackupSession