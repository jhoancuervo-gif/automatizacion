# =========================================================
# SCRIPT: poe.ps1 - RUTAS UNIVERSALES Y BACKUP
# =========================================================

# Obtiene la carpeta donde está guardado este archivo .ps1 de forma automática
$currentDir = $PSScriptRoot
$rootDir    = Split-Path -Parent $currentDir
$backupDir  = Join-Path $rootDir "backups_macs"

# Define las rutas de los archivos de forma relativa al directorio actual
$fwFile     = Join-Path $currentDir "upg_appimage.bin"
$configFile = Join-Path $currentDir "port8_snmp.bin"
$macFile    = Join-Path $currentDir "mac.txt"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Validación rápida: Detener si no existen los archivos necesarios
if (-not (Test-Path $fwFile)) { 
    Write-Host " [!] ERROR: No se encuentra '$fwFile' en la carpeta." -ForegroundColor Red
    pause; exit 
}

do {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   HELLOTEK - PROCESO DE ALTO RENDIMIENTO (UNIVERSAL)    " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    $ip = "192.168.18.1"
    $auth = "admin:admin"

    # --- PASO 1: CAPTURA DE MAC ---
    Write-Host "[1/5] Identificando equipo..." -ForegroundColor Yellow
    arp -d $ip 2>$null
    Test-Connection $ip -Count 1 -Quiet | Out-Null
    
    $macResult = ""
    $arpTable = arp -a $ip | Out-String
    if ($arpTable -match "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})") {
        $macResult = $matches[0].ToUpper().Replace("-",":")
        Write-Host " -> MAC Detectada: $macResult" -ForegroundColor Green
    }

    if ([string]::IsNullOrWhiteSpace($macResult)) {
        Write-Host " [!] ERROR: No se detectó MAC. Verifique conexión." -ForegroundColor Red
        $choice = Read-Host "ENTER para reintentar / 'S' para salir"
        if ($choice -eq "s") { break } else { continue }
    }

    # --- PASO 2, 3 y 4: CARGAS ---
    Write-Host "[2/5] Preparando Flash..." -ForegroundColor Yellow
    curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/toBootLoadUpgrade.cgi" --max-time 5

    Write-Host "[3/5] Enviando Firmware..." -NoNewline
    curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/upg_appimage.bin" -F "FN=@$fwFile"
    Write-Host " [OK]" -ForegroundColor Green
    Start-Sleep -Seconds 22

    Write-Host "[4/5] Enviando Configuración..." -NoNewline
    curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/SG1008.bin" -F "FN=@$configFile"
    Write-Host " [OK]" -ForegroundColor Green

    # --- PASO 5: CAMBIO DE CONTRASEÑA REFORZADO ---
    Write-Host "[5/5] Aplicando seguridad (somos123.)..." -ForegroundColor Yellow
    
    Write-Host "Esperando reinicio para validar clave..." -NoNewline
    $switchVivo = $false
    for($i=0; $i -lt 12; $i++) {
        Write-Host "." -NoNewline
        if(Test-Connection $ip -Count 1 -Quiet) { $switchVivo = $true; break }
        Start-Sleep -Seconds 2
    }

    if($switchVivo) {
        Start-Sleep -Seconds 2 
        # Referer añadido para compatibilidad con la interfaz web del Hellotek
        curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/usermng.cgi" `
        -H "Referer: http://$ip/usermng.htm" `
        -d "U=admin&NU=admin&U=somos123.&U=somos123." `
        --max-time 5
        
        Write-Host " [PETICIÓN ENVIADA]" -ForegroundColor Green
    } else {
        Write-Host " [ERROR: TIEMPO AGOTADO]" -ForegroundColor Red
    }

    # GUARDADO Y CIERRE (Modificado solo para guardar en local y en backup)
    if ($macResult) {
        # 1. Guarda en el mac.txt de su misma carpeta local
        $macResult | Add-Content -Path $macFile
        
        # 2. Guarda el historial en la carpeta backups_macs de la raíz
        if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
        $fecha = Get-Date -Format "yyyy-MM-dd"
        $historial = Join-Path $backupDir "poe_1gb_historial_$fecha.txt"
        Add-Content -Path $historial -Value "$(Get-Date -Format 'HH:mm:ss') | 1Gb | $macResult" -Encoding UTF8
    }

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "FINALIZADO: $macResult" -ForegroundColor Green
    [System.Console]::Beep(1000, 150)

    $next = Read-Host "Presione ENTER para el siguiente switch / 'S' para salir"
} while ($next -ne "s")