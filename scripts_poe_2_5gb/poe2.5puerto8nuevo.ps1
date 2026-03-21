# =========================================================
# SCRIPT: poeport82.5_FULL.ps1 (PROCESO COMPLETO 2.5G)
# =========================================================
if ($PSScriptRoot) { $baseDir = $PSScriptRoot } else { $baseDir = Get-Location }

$fwFile     = "$baseDir\upg_appimage2.bin"
$configFile = "$baseDir\port8_snmp.bin"
$macFile    = "$baseDir\mac.txt"
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)"

if (-not (Test-Path $fwFile) -or -not (Test-Path $configFile)) {
    Write-Host " [!] ERROR: Faltan archivos .bin (upg_appimage2 / config)" -ForegroundColor Red
    pause; exit
}

do {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   HELLOTEK 2.5G - FLASHEO Y CONFIGURACIÓN COMPLETA      " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    $ip = "192.168.18.1"
    $auth = "admin:admin." # Clave inicial de fábrica del 2.5G

    # [1] CAPTURA MAC
    Write-Host "[1/5] Identificando..." -NoNewline
    arp -d $ip 2>$null
    Test-Connection $ip -Count 1 -Quiet | Out-Null
    $macResult = ""
    $arpTable = arp -a $ip | Out-String
    if ($arpTable -match "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})") {
        $macResult = $matches[0].ToUpper().Replace("-",":")
        Write-Host " [MAC: $macResult]" -ForegroundColor Green
    }

    # [2] MODO FLASH
    Write-Host "[2/5] Modo Flash..." -NoNewline
    curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/toBootLoadUpgrade.cgi" -H "Referer: http://$ip/upgrade.htm" -H "User-Agent: $ua" --max-time 5
    Start-Sleep -Seconds 5
    Write-Host " [OK]" -ForegroundColor Green

    # [3] SUBIDA FIRMWARE
    Write-Host "[3/5] Subiendo Firmware..." -NoNewline
    curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/upg_appimage.bin" -H "Referer: http://$ip/upgrade.htm" -H "User-Agent: $ua" -F "filename=@$fwFile"
    Write-Host " [OK]" -ForegroundColor Green
    Write-Host "      Grabando (30s)..."
    Start-Sleep -Seconds 30

    # [4] SUBIDA CONFIGURACIÓN
    Write-Host "[4/5] Subiendo Config SNMP..." -NoNewline
    curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/SW_CFG.bin" -H "Referer: http://$ip/saveconfig.htm" -H "User-Agent: $ua" -F "filename=@$configFile"
    Write-Host " [OK]" -ForegroundColor Green

    # [5] SEGURIDAD (somos123.)
    Write-Host "[5/5] Aplicando Clave..." -NoNewline
    Start-Sleep -Seconds 25
    curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/usermng.cgi" -H "Referer: http://$ip/usermng.htm" -d "U=admin&NU=admin&U=somos123.&U=somos123."
    Write-Host " [LISTO]" -ForegroundColor Green

    # REGISTRO
    if ($macResult) {
        $macResult | Add-Content -Path $macFile
        [System.Console]::Beep(1000, 150)
    }

    $n = Read-Host "ENTER Siguiente / 'S' Salir"
} while ($n -ne "s")