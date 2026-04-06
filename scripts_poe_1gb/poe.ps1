# =========================================================
# SCRIPT: poe_estable.ps1 - ALTA ESTABILIDAD
# =========================================================

$baseDir = $PSScriptRoot
$fwFile  = Join-Path $baseDir "upg_appimage.bin"
$configFile = Join-Path $baseDir "Configmanage.bin" # Archivo con Port Forward y DHCP Filter
$macFile = Join-Path $baseDir "mac.txt"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

do {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   HELLOTEK - PROCESO DE ALTA ESTABILIDAD               " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    $ip = "192.168.18.1"
    $passwords = @("admin", "somos123.")
    $auth = ""

    # --- VALIDACIÓN DE ACCESO ---
    Write-Host "[0/5] Validando acceso..." -NoNewline
    foreach ($p in $passwords) {
        $testAuth = "admin:$p"
        $check = curl.exe -u $testAuth -s -o NUL -w "%{http_code}" "http://$ip/index.htm" --max-time 2
        if ($check -eq "200") { $auth = $testAuth; break }
    }

    if (!$auth) {
        Write-Host " [ERROR: SIN ACCESO]" -ForegroundColor Red
        $choice = Read-Host "Presione ENTER para reintentar / 'S' para salir"
        if ($choice -eq "s") { break } else { continue }
    }
    Write-Host " [OK]" -ForegroundColor Green

    # --- PASO 1: CAPTURA DE MAC ---
    Write-Host "[1/5] Identificando equipo..." -NoNewline
    arp -d $ip 2>$null
    Test-Connection $ip -Count 1 -Quiet | Out-Null
    $arpTable = arp -a $ip | Out-String
    if ($arpTable -match "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})") {
        $macResult = $matches[0].ToUpper().Replace("-",":")
        Write-Host " -> MAC: $macResult" -ForegroundColor Green
    }

    # --- PASO 2: PREPARACIÓN FLASH ---
    Write-Host "[2/5] Preparando Flash..." -NoNewline
    curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/toBootLoadUpgrade.cgi" --max-time 5
    Write-Host " [OK]" -ForegroundColor Green
    Start-Sleep -Seconds 2

    # --- PASO 3: FIRMWARE CON REINTENTO ---
    $success = $false
    Write-Host "[3/5] Enviando Firmware..." -NoNewline
    for($i=1; $i -le 3; $i++){
        $res = curl.exe -u $auth -s -o NUL -w "%{http_code}" -X POST "http://$ip/cgi/upg_appimage.bin" -F "FN=@$fwFile"
        if($res -eq "200"){ $success = $true; break }
        Write-Host " (R$i..)" -NoNewline
        Start-Sleep -Seconds 3
    }
    if($success){ Write-Host " [OK]" -ForegroundColor Green; Start-Sleep -Seconds 25 } 
    else { Write-Host " [FALLÓ]" -ForegroundColor Red }

    # --- PASO 4: CONFIGURACIÓN (DHCP Filter y Port Forward) ---
    # Según manual: El puerto 8 debe quedar apagado en DHCP Filter [cite: 41]
    Write-Host "[4/5] Enviando Configuracion..." -NoNewline
    $success = $false
    for($i=1; $i -le 3; $i++){
        $res = curl.exe -u $auth -s -o NUL -w "%{http_code}" -X POST "http://$ip/cgi/SG1008.bin" -F "FN=@$configFile"
        if($res -eq "200"){ $success = $true; break }
        Write-Host " (R$i..)" -NoNewline
        Start-Sleep -Seconds 3
    }
    if($success){ Write-Host " [OK]" -ForegroundColor Green } 
    else { Write-Host " [FALLÓ]" -ForegroundColor Red }

    # --- PASO 5: SEGURIDAD Y REINICIO ---
    Write-Host "[5/5] Aplicando seguridad final..." -ForegroundColor Yellow
    Write-Host "Esperando estabilidad de red..." -NoNewline
    $switchVivo = $false
    for($i=0; $i -lt 15; $i++) {
        Write-Host "." -NoNewline
        if(Test-Connection $ip -Count 1 -Quiet) { $switchVivo = $true; break }
        Start-Sleep -Seconds 2
    }

    if($switchVivo) {
        Start-Sleep -Seconds 5 # Tiempo extra para carga de servicios
        curl.exe -u $auth -s -o NUL -X POST "http://$ip/cgi/usermng.cgi" `
        -H "Referer: http://$ip/usermng.htm" `
        -d "U=admin&NU=admin&P1=somos123.&P2=somos123." `
        --max-time 5
        Write-Host " [PETICION ENVIADA]" -ForegroundColor Green
    }

    # GUARDADO DE RESULTADO
    if ($macResult) { $macResult | Add-Content -Path $macFile -ErrorAction SilentlyContinue }

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "PROCESO COMPLETADO PARA: $macResult" -ForegroundColor Green
    [System.Console]::Beep(1000, 200)

    $next = Read-Host "Presione ENTER para el siguiente switch / 'S' para salir"
} while ($next -ne "s")