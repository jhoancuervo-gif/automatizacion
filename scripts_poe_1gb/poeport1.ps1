# =========================================================
# SCRIPT: poe.ps1 - CARGA SNMP CON VALIDACIÓN DE REINICIO
# =========================================================

$currentDir = $PSScriptRoot
$rootDir    = Split-Path -Parent $currentDir
$backupDir  = Join-Path $rootDir "backups_macs"

$configFile = Join-Path $currentDir "Configmanage.bin"
$macFile    = Join-Path $currentDir "mac.txt"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not (Test-Path $configFile)) { 
    Write-Host " [!] ERROR: No se encuentra '$configFile'." -ForegroundColor Red
    pause; exit 
}

do {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   HELLOTEK - CARGA DE CONFIGURACIÓN SNMP (8 PUERTOS)    " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    $ip = "192.168.18.1"
    $auth = "admin:somos123."

    # --- PASO 1: CAPTURA DE MAC ---
    Write-Host "[1/2] Identificando equipo..." -ForegroundColor Yellow
    arp -d $ip 2>$null
    Test-Connection $ip -Count 1 -Quiet | Out-Null
    
    $macResult = ""
    $arpTable = arp -a $ip | Out-String
    if ($arpTable -match "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})") {
        $macResult = $matches[0].ToUpper().Replace("-",":")
        Write-Host " -> MAC Detectada: $macResult" -ForegroundColor Green
    }

    if ([string]::IsNullOrWhiteSpace($macResult)) {
        Write-Host " [!] ERROR: No se detectó MAC." -ForegroundColor Red
        $choice = Read-Host "ENTER para reintentar / 'S' para salir"
        if ($choice -eq "s") { break } else { continue }
    }

    # --- PASO 2: CARGA Y VERIFICACIÓN ---
    Write-Host "[2/2] Enviando Configuración..." -NoNewline
    
    # Ejecutamos curl capturando el error silenciosamente
    $process = Start-Process curl.exe -ArgumentList "-u $auth -s -o NUL -X POST `"http://$ip/cgi/SG1008.bin`" -F `"FN=@$configFile`"" -Wait -PassThru -NoNewWindow

    # Esperamos un momento a que el switch procese
    Start-Sleep -Seconds 3

    # Verificamos si el switch sigue vivo o está reiniciando
    Write-Host " Verificando respuesta..." -NoNewline
    $check = Test-Connection $ip -Count 1 -Quiet

    if ($check) {
        Write-Host " [OK - APLICADO]" -ForegroundColor Green
    } else {
        # Si no responde ping, es que se está reiniciando (buena señal)
        Write-Host " [REINICIANDO... OK]" -ForegroundColor Cyan
    }

    # --- GUARDADO DE LOGS ---
    if ($macResult) {
        $macResult | Add-Content -Path $macFile
        if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
        $fecha = Get-Date -Format "yyyy-MM-dd"
        $historial = Join-Path $backupDir "poe_8port_snmp_$fecha.txt"
        Add-Content -Path $historial -Value "$(Get-Date -Format 'HH:mm:ss') | SNMP_8P | $macResult" -Encoding UTF8
    }

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "FINALIZADO CON ÉXITO: $macResult" -ForegroundColor Green
    [System.Console]::Beep(1000, 150)

    $next = Read-Host "Presione ENTER para el siguiente switch / 'S' para salir"
} while ($next -ne "s")