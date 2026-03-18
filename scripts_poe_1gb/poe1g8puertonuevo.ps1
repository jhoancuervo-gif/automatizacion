# =========================================================
# SCRIPT: poeport81G_FULL.ps1 (PROCESO COMPLETO 1GB)
# =========================================================
$currentDir = $PSScriptRoot
$rootDir    = Split-Path -Parent $currentDir
$backupDir  = Join-Path $rootDir "backups_macs"

$fwFile     = Join-Path $currentDir "upg_appimage.bin"
$configFile = Join-Path $currentDir "port8_snmp.bin"
$macFile    = Join-Path $currentDir "mac.txt"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not (Test-Path $fwFile) -or -not (Test-Path $configFile)) { 
    Write-Host " [!] ERROR: Faltan archivos .bin en la carpeta." -ForegroundColor Red
    pause; exit 
}

do {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   HELLOTEK 1G - FLASHEO Y CONFIGURACIÓN COMPLETA        " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    $ip = "192.168.18.1"
    $authInitial = "admin:admin"
    $authFinal   = "admin:somos123."

    # [1] IDENTIFICACIÓN
    Write-Host "[1/5] Identificando equipo..." -ForegroundColor Yellow
    arp -d $ip 2>$null
    Test-Connection $ip -Count 1 -Quiet | Out-Null
    $macResult = ""
    $arpTable = arp -a $ip | Out-String
    if ($arpTable -match "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})") {
        $macResult = $matches[0].ToUpper().Replace("-",":")
        Write-Host " -> MAC Detectada: $macResult" -ForegroundColor Green
    }

    # [2] MODO FLASH
    Write-Host "[2/5] Activando Modo Flash..." -NoNewline
    curl.exe -u $authInitial -s -o NUL -X POST "http://$ip/cgi/toBootLoadUpgrade.cgi" --max-time 5
    Write-Host " [OK]" -ForegroundColor Green

    # [3] SUBIDA DE FIRMWARE
    Write-Host "[3/5] Enviando Firmware ($($fwFile | Split-Path -Leaf))..." -NoNewline
    curl.exe -u $authInitial -s -o NUL -X POST "http://$ip/cgi/upg_appimage.bin" -F "FN=@$fwFile"
    Write-Host " [OK]" -ForegroundColor Green
    Write-Host "      Grabando en memoria (25s)..."
    Start-Sleep -Seconds 25

    # [4] CARGA DE CONFIGURACIÓN
    Write-Host "[4/5] Enviando Configuración SNMP..." -NoNewline
    curl.exe -u $authInitial -s -o NUL -X POST "http://$ip/cgi/SG1008.bin" -F "FN=@$configFile"
    Write-Host " [OK]" -ForegroundColor Green

    # [5] CAMBIO DE CLAVE (somos123.)
    Write-Host "[5/5] Aplicando Seguridad..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
    curl.exe -u $authInitial -s -o NUL -X POST "http://$ip/cgi/usermng.cgi" `
    -H "Referer: http://$ip/usermng.htm" `
    -d "U=admin&NU=admin&U=somos123.&U=somos123."
    Write-Host " -> Credenciales actualizadas." -ForegroundColor Green

    # REGISTRO
    if ($macResult) {
        $macResult | Add-Content -Path $macFile
        if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
        $fecha = Get-Date -Format "yyyy-MM-dd"
        Add-Content -Path (Join-Path $backupDir "historial_1G_$fecha.txt") -Value "$(Get-Date -Format 'HH:mm:ss') | 1G | $macResult"
    }

    Write-Host "========================================" -ForegroundColor Cyan
    [System.Console]::Beep(1000, 150)
    $next = Read-Host "ENTER para siguiente / 'S' para salir"
} while ($next -ne "s")