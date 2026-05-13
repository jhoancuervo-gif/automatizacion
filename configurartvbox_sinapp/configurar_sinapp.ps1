# ==============================================================================
# ESTACIÓN DE TRABAJO CUERVO - CONFIGURACIÓN FULL + LIMPIEZA SOMOS (RUNSPACES)
# ==============================================================================

# 1. RUTAS AUTOMÁTICAS
$scriptDir = $PSScriptRoot
$adbExe = Join-Path $scriptDir "platform-tools\adb.exe"
$ArchivoMAC = Join-Path $scriptDir "tvboxes_configurados.txt"
$ArchivoBackup = Join-Path $scriptDir "mac_backup.txt"
$MaxParalelo = 10 # <-- Límite de equipos en simultáneo real

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
    Write-Host "   ESTACION DE TRABAJO CUERVO - MODO MULTIHILO " -ForegroundColor Magenta
    Write-Host "   IP PC: $miIP_Detectada | Rango: $segmentoBase$($RangoIPs[0])-$($RangoIPs[-1])" -ForegroundColor Gray
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
        $nmapOut = nmap -p 5555 --open -n -T5 192.168.10.200-250 -oG -
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

    # 5. CONFIGURACIÓN Y LIMPIEZA EN PARALELO (MULTIHILO REAL)
    Write-Host "`n🚀 Aplicando configuraciones a $($tvboxes.Count) equipos simultáneamente (Max: $MaxParalelo)..." -ForegroundColor Cyan
    
    # Crear un Pool de hilos para ejecución simultánea real y ultrarrápida
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxParalelo)
    $RunspacePool.Open()
    $hilos = @()

    foreach ($ip in $tvboxes) {
        $ScriptBlock = {
            param($targetIp, $adbPath)
            
            $serial = "${targetIp}:5555"
            $null = & $adbPath connect $serial 2>$null

            # Extraer MAC (Prioridad eth0). Silencioso si falla.
            $m = & $adbPath -s $serial shell "cat /sys/class/net/eth0/address 2>/dev/null || cat /sys/class/net/wlan0/address 2>/dev/null" 2>$null
            
            if ($m) {
                $mac = $m.Trim().ToUpper()
                
                # --- COMANDOS DE CONFIGURACION ---
                & $adbPath -s $serial shell "setprop persist.sys.language es" 2>$null
                & $adbPath -s $serial shell "setprop persist.sys.country US" 2>$null
                & $adbPath -s $serial shell "setprop persist.sys.timezone America/Bogota" 2>$null
                & $adbPath -s $serial shell "settings put system system_locales es-US" 2>$null
                
                # --- LIMPIEZA DE APP SOMOS ---
                $pkgs = & $adbPath -s $serial shell "pm list packages | grep somos" 2>$null
                if ($pkgs) {
                    foreach ($line in $pkgs) {
                        $AppID = $line.Replace("package:", "").Trim()
                        if ($AppID) {
                            & $adbPath -s $serial shell "am force-stop $AppID; pm clear $AppID; pm uninstall --user 0 $AppID" >$null 2>&1
                        }
                    }
                }

                # --- DESACTIVAR WIFI ---
                & $adbPath -s $serial shell "svc wifi disable" 2>$null
                & $adbPath -s $serial shell "settings put global wifi_on 0" 2>$null
                & $adbPath -s $serial shell "settings put global wifi_scan_always_enabled 0" 2>$null
                
                Start-Sleep -Milliseconds 500
                & $adbPath -s $serial shell "reboot" 2>$null
                
                return [PSCustomObject]@{ Status = 'OK'; IP = $targetIp; MAC = $mac }
            }
            return [PSCustomObject]@{ Status = 'FAIL'; IP = $targetIp; MAC = $null }
        }

        # Configurar el hilo con sus variables (se inyectan $ip y $adbExe)
        $PSInstance = [powershell]::Create().AddScript($ScriptBlock).AddArgument($ip).AddArgument($adbExe)
        $PSInstance.RunspacePool = $RunspacePool

        # Iniciar el hilo inmediatamente y guardarlo para recolectar el resultado luego
        $hilos += [PSCustomObject]@{
            Pipe   = $PSInstance
            Result = $PSInstance.BeginInvoke()
        }
    }

    # Esperar a que terminen y recolectar resultados de la estación
    $macsFinales = @()
    foreach ($hilo in $hilos) {
        # EndInvoke bloquea hasta que este hilo específico termine
        $res = $hilo.Pipe.EndInvoke($hilo.Result)
        $hilo.Pipe.Dispose() # Limpiar memoria usada por el hilo
        
        if ($res.Status -eq 'OK') {
            Write-Host "  [OK] $($res.IP) - $($res.MAC) (Configurado)" -ForegroundColor Green
            $macsFinales += $res.MAC
        }
    }
    
    # Cerrar el pool de hilos
    $RunspacePool.Close()
    $RunspacePool.Dispose()

    # 6. REPORTE Y FINALIZACIÓN
    if ($macsFinales.Count -gt 0) {
        $macsFinales | Out-File -FilePath $ArchivoMAC -Encoding UTF8
        $macsFinales | ForEach-Object { "$(Get-Date -Format 'HH:mm') | $_" } | Out-File -FilePath $ArchivoBackup -Append
        
        Write-Host "`n[LISTO] Reporte generado para $($macsFinales.Count) equipos." -ForegroundColor Green
        Start-Process notepad.exe $ArchivoMAC
        [System.Console]::Beep(523, 200)
    }
    else {
        Write-Host "`n[AVISO] No se configuró exitosamente ningún equipo en este lote o no hubo conexión ADB." -ForegroundColor Yellow
    }

    $ask = Read-Host "`n¿Siguiente lote? (S/N)"
    if ($ask -notmatch "S|s") { break }
}