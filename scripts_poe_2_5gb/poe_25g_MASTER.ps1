# =========================================================
# SCRIPT: poe_25g_MASTER.ps1
# VERSION: PORTABLE + AUTO-CREACION TXT
# =========================================================

# --- RUTAS AUTOMÁTICAS ---
if ($PSScriptRoot) { $baseDir = $PSScriptRoot } else { $baseDir = Get-Location }

$fwFile     = "$baseDir\upg_appimage2.bin"
$configFile = "$baseDir\Configmanage2.bin"
$macFile    = "$baseDir\mac.txt"

# --- VERIFICACIÓN DE SEGURIDAD ---
# 1. Si no existe mac.txt, LO CREA automáticamente
if (-not (Test-Path $macFile)) { 
    New-Item -Path $macFile -ItemType File -Force | Out-Null
    Write-Host " [INFO] Archivo mac.txt creado correctamente." -ForegroundColor Gray
}

# 2. Verifica que existan los archivos binarios obligatorios
if (-not (Test-Path $fwFile) -or -not (Test-Path $configFile)) {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Red
    Write-Host " [ERROR] FALTAN LOS ARCHIVOS .BIN" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Red
    Write-Host " Buscando en: $baseDir"
    Write-Host " Asegúrate de poner 'upg_appimage2.bin' y 'Configmanage2.bin'"
    Write-Host " en la misma carpeta que este script."
    Read-Host "Presione Enter para salir"
    Break
}

$ip = "192.168.18.1"
$auth = "admin:admin." 
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

do {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   HELLOTEK 2.5G - PORTABLE (REGISTRO AUTOMATICO)         " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    # [1] CAPTURA MAC
    Write-Host "[1/5] Identificando..." -NoNewline
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

    # [2] MODO FLASH
    Write-Host "[2/5] Modo Flash..." -NoNewline
    curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/toBootLoadUpgrade.cgi" -H "Referer: http://$ip/upgrade.htm" -H "User-Agent: $ua" --max-time 5
    Start-Sleep -Seconds 5
    Write-Host " [OK]" -ForegroundColor Green

    # [3] FIRMWARE
    Write-Host "[3/5] Subiendo Firmware..." -NoNewline
    curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/upg_appimage.bin" -H "Referer: http://$ip/upgrade.htm" -H "User-Agent: $ua" -F "filename=@$fwFile"
    Write-Host " [OK]" -ForegroundColor Green
    
    Write-Host "      Grabando (30s)..."
    Start-Sleep -Seconds 30

    # [4] CONFIGURACION
    Write-Host "[4/5] Subiendo Config..." -NoNewline
    curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/SW_CFG.bin" -H "Referer: http://$ip/saveconfig.htm" -H "User-Agent: $ua" -F "filename=@$configFile"
    Write-Host " [OK]" -ForegroundColor Green

    # [5] REINICIO Y CLAVE
    Write-Host "[5/5] Seguridad (somos123)..." -ForegroundColor Yellow
    Write-Host "      Reiniciando..." -NoNewline
    
    $vivo = $false
    Start-Sleep -Seconds 25 
    
    for($i=0; $i -lt 25; $i++) {
        if(Test-Connection $ip -Count 1 -Quiet) { $vivo = $true; break }
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
    }

    if($vivo) {
        Start-Sleep -Seconds 4 
        curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/usermng.cgi" -H "Referer: http://$ip/usermng.htm" -H "User-Agent: $ua" -d "U=admin&NU=admin&U=somos123.&U=somos123."
        curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/usermng.cgi" -d "type=2&username=admin&password=somos123.&confirm_password=somos123."
        
        Write-Host " [LISTO]" -ForegroundColor Green
        
        # Guardado en mac.txt (Que ya sabemos que existe)
        "$macResult" | Add-Content -Path $macFile
        Write-Host "      [REGISTRADO]" -ForegroundColor Cyan
        [System.Console]::Beep(1000, 150)
    } else {
        Write-Host " [ERROR: NO VOLVIO]" -ForegroundColor Red
        [System.Console]::Beep(500, 500)
    }

    $n = Read-Host "ENTER Siguiente / 'S' Salir"
    if ($n -eq "s") { break }

} while ($true)