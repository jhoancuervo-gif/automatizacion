# ==============================================================================
# ESTACIÓN DE TRABAJO - CONFIGURACIÓN ORIGINAL + LIMPIEZA SOMOS
# ==============================================================================

# ==============================================================================
# ESTACIÓN DE TRABAJO - CONFIGURACIÓN CON RUTA INTELIGENTE
# ==============================================================================

# 1. RUTAS AUTOMÁTICAS (Ahora busca en la carpeta actual y en la de arriba)
# ==============================================================================
# CONFIGURACIÓN DE RUTAS INTELIGENTES
# ==============================================================================
$scriptDir = $PSScriptRoot
$adbRelativo = "platform-tools\adb.exe"

# 1. Buscamos en la carpeta actual (por si acaso)
$pathLocal = Join-Path $scriptDir $adbRelativo

# 2. Buscamos en la carpeta de arriba (La raíz del proyecto CUERVO)
$parentDir = Split-Path $scriptDir -Parent
$pathPadre = Join-Path $parentDir $adbRelativo

# 3. Validación de la ruta real
if (Test-Path $pathLocal) {
    $adbExe = $pathLocal
} elseif (Test-Path $pathPadre) {
    $adbExe = $pathPadre
} else {
    Write-Host "❌ ERROR CRÍTICO: No se encontró 'platform-tools\adb.exe'" -ForegroundColor Red
    Write-Host "Buscado en: $pathLocal" -ForegroundColor Gray
    Write-Host "Buscado en: $pathPadre" -ForegroundColor Gray
    Write-Host "`n[!] Asegúrate de que la carpeta 'platform-tools' esté en la raíz de CUERVO." -ForegroundColor Yellow
    Pause
    exit
}

Write-Host "[OK] ADB detectado en: $adbExe" -ForegroundColor Green

$ArchivoMAC = Join-Path $scriptDir "tvboxes_configurados.txt"
$ArchivoBackup = Join-Path $scriptDir "mac_backup.txt"
$MaxParalelo = 5

# 2. DETECTAR MI IP ACTUAL AUTOMÁTICAMENTE
$miIP_Detectada = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.InterfaceAlias -notlike "*Wi-Fi*" -and 
    $_.InterfaceAlias -notlike "*vEthernet*" -and 
    $_.IPAddress -like "192.168.10.*"
} | Select-Object -First 1).IPAddress

if (-not $miIP_Detectada) { $miIP_Detectada = "0.0.0.0" }

$segmentoBase = "192.168.10."
$RangoIPs = 200..250

while ($true) {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "   ESTACION - CONFIGURACION FULL " -ForegroundColor Magenta
    Write-Host "   IP PC: $miIP_Detectada | Rango: ." -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Magenta

    $Cantidad = 0
    $inputUser = Read-Host "`n¿Cuántos equipos quieres procesar en este lote?"
    if (-not [int]::TryParse($inputUser, [ref]$Cantidad)) { $Cantidad = 1 }

    & $adbExe kill-server 2>$null
    & $adbExe start-server 2>$null

    # 4. ESCANEO RÁPIDO NMAP
    $tvboxes = @()
    Write-Host "`n🔍 Buscando $Cantidad equipos..." -ForegroundColor Cyan
    
    do {
        $nmapOut = nmap -p 5555 --open -n -T5 192.168.10.200-230 -oG -
        $ipsEncontradas = $nmapOut | Select-String "Host: (\d+\.\d+\.\d+\.\d+)" | ForEach-Object { $_.Matches.Groups[1].Value } | Where-Object { $_ -ne $miIP_Detectada }

        foreach ($ip in $ipsEncontradas) {
            if ($ip -notin $tvboxes) {
                $tvboxes += $ip
                Write-Host "  -> ENCONTRADO: $ip" -ForegroundColor Green
            }
            if ($tvboxes.Count -ge $Cantidad) { break }
        }
        if ($tvboxes.Count -lt $Cantidad) { Start-Sleep -Seconds 1 }
    } while ($tvboxes.Count -lt $Cantidad)

    # 5. CONFIGURACIÓN Y LIMPIEZA (TUS COMANDOS ORIGINALES)
    Write-Host "`n🚀 Aplicando configuraciones y limpieza..." -ForegroundColor Cyan
    $macsFinales = @()
    
    foreach ($ip in $tvboxes) {
        $serial = "${ip}:5555"
        $null = & $adbExe connect $serial

        # Extraer MAC (Prioridad eth0)
        $m = & $adbExe -s $serial shell "cat /sys/class/net/eth0/address 2>/dev/null || cat /sys/class/net/wlan0/address 2>/dev/null" 2>$null
        
        if ($m) {
            $mac = $m.Trim().ToUpper()
            $macsFinales += $mac
            
            # --- TUS COMANDOS ORIGINALES DE CONFIGURACION ---
            # 1. Idioma y zona (persist)
            & $adbExe -s $serial shell "setprop persist.sys.language es" 2>$null
            & $adbExe -s $serial shell "setprop persist.sys.country US" 2>$null
            & $adbExe -s $serial shell "setprop persist.sys.timezone America/Bogota" 2>$null
            
            # 2. Configuracion adicional de idioma
            & $adbExe -s $serial shell "settings put system system_locales es-US" 2>$null
            
            # --- LIMPIEZA DE APP SOMOS ---
            $pkgs = & $adbExe -s $serial shell "pm list packages | grep somos" 2>$null
            if ($pkgs) {
                foreach ($line in $pkgs) {
                    $AppID = $line.Replace("package:", "").Trim()
                    if ($AppID) {
                        & $adbExe -s $serial shell "am force-stop $AppID; pm clear $AppID; pm uninstall --user 0 $AppID" >$null 2>&1
                    }
                }
            }

            # --- DESACTIVAR WIFI (TUS COMANDOS ORIGINALES) ---
            & $adbExe -s $serial shell "svc wifi disable" 2>$null
            & $adbExe -s $serial shell "settings put global wifi_on 0" 2>$null
            & $adbExe -s $serial shell "settings put global wifi_scan_always_enabled 0" 2>$null
            
            Start-Sleep -Milliseconds 500
            
            # --- REINICIAR ---
            & $adbExe -s $serial shell "reboot" 2>$null
            Write-Host "  [OK] $ip - $mac (Configurado)" -ForegroundColor Green
        }
    }

    # 6. REPORTE Y FINALIZACIÓN
    $macsFinales | Out-File -FilePath $ArchivoMAC -Encoding UTF8
    $macsFinales | ForEach-Object { "$(Get-Date -Format 'HH:mm') | $_" } | Out-File -FilePath $ArchivoBackup -Append
    
    Write-Host "`n[LISTO] Reporte generado." -ForegroundColor Green
    Start-Process notepad.exe $ArchivoMAC
    [System.Console]::Beep(523, 200)

    $ask = Read-Host "`n¿Siguiente lote? (S/N)"
    if ($ask -notmatch "S|s") { break }
}