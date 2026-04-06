# =========================================================
# SCRIPT: poe.ps1 - SOLUCIÓN DEFINITIVA PASO 4 (CONFIG)
# =========================================================

$currentDir = $PSScriptRoot
$fwFile     = Join-Path $currentDir "upg_appimage.bin"
$configFile = Join-Path $currentDir "Configmanage.bin"
$macFile    = Join-Path $currentDir "mac.txt"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

do {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   HELLOTEK - FORZADO DE CONFIGURACIÓN Y REBOOT          " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    $ip = "192.168.18.1"
    $auth = "admin:admin"

    # --- PASO 1: MAC ---
    Write-Host "[1/5] Identificando equipo..." -ForegroundColor Yellow
    arp -d $ip 2>$null
    Test-Connection $ip -Count 1 -Quiet | Out-Null
    $macResult = ""
    $arpTable = arp -a $ip | Out-String
    if ($arpTable -match "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})") {
        $macResult = $matches[0].ToUpper().Replace("-",":")
        Write-Host " -> MAC Detectada: $macResult" -ForegroundColor Green
    }

    # --- PASO 2: PREPARACIÓN ---
    Write-Host "[2/5] Preparando Flash..." -ForegroundColor Yellow
    curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/toBootLoadUpgrade.cgi"
    Start-Sleep -Seconds 5

    # --- PASO 3: FIRMWARE (ESTO YA TE FUNCIONA) ---
    Write-Host "[3/5] Enviando Firmware..." -NoNewline
    curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/upg_appimage.bin" -F "FN=@$fwFile" -H "Expect:"
    Write-Host " [OK - REINICIANDO]" -ForegroundColor Green
    
    # Espera a que el equipo se apague y vuelva a subir tras el firmware
    Write-Host "Esperando reinicio por Firmware (45s)..." -ForegroundColor Gray
    Start-Sleep -Seconds 45
    while (!(Test-Connection $ip -Count 1 -Quiet)) { Start-Sleep -Seconds 2 }

    # --- PASO 4: CONFIGURACIÓN (REFORZADO) ---
    Write-Host "[4/5] Enviando Configuración..." -NoNewline
    # CAMBIO CLAVE: Usamos 'config_manage.cgi' y enviamos el flag 'Import=Import'
    # Muchos Hellotek no procesan el .bin si no reciben el valor del botón 'Import'
    curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/config_manage.cgi" `
        -H "Referer: http://$ip/config_manage.htm" `
        -F "FN=@$configFile" `
        -F "Import=Import" `
        -H "Expect:"
    
    Write-Host " [ENVIADA]" -ForegroundColor Green
    
    # FORZADO DE REBOOT POST-CONFIG
    # Si el switch no se reinicia solo tras la config, este comando lo obliga
    Write-Host "Aplicando cambios (Reboot manual)..." -ForegroundColor Yellow
    curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/sys_reboot.cgi" -H "Referer: http://$ip/sys_reboot.htm"
    
    # --- PASO 5: SEGURIDAD ---
    Write-Host "[5/5] Validando seguridad..." -ForegroundColor Yellow
    Write-Host "Esperando que el switch vuelva..." -NoNewline
    $caida = $false
    for($i=0; $i -lt 15; $i++) {
        Write-Host "." -NoNewline
        if(Test-Connection $ip -Count 1 -Quiet) { $caida = $true; break }
        Start-Sleep -Seconds 2
    }

    if($caida) {
        Start-Sleep -Seconds 3
        curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/usermng.cgi" `
            -H "Referer: http://$ip/usermng.htm" `
            -d "U=admin&NU=admin&U=somos123.&U=somos123."
        Write-Host " [PROCESO COMPLETADO]" -ForegroundColor Green
    }

    if ($macResult) { $macResult | Add-Content -Path $macFile }
    Write-Host "========================================" -ForegroundColor Cyan
    [System.Console]::Beep(1000, 150)
    $next = Read-Host "ENTER para siguiente / 'S' para salir"
} while ($next -ne "s")