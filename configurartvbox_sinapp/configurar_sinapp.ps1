# ==============================================================================
# ESTACIÓN DE TRABAJO CUERVO - V2.46 (AGREGADA OPCIÓN 3: OCULTAR DEV MENU)
# ==============================================================================

$scriptDir = $PSScriptRoot
$adbExe = Join-Path $scriptDir "platform-tools\adb.exe"
$ArchivoMAC = Join-Path $scriptDir "tvboxes_configurados.txt"
$ArchivoMDM = Join-Path $scriptDir "tvboxes_CON_AGENTE.txt"  
$ArchivoBackup = Join-Path $scriptDir "mac_backup.txt"
$MaxParalelo = 15 

if (-not (Test-Path $adbExe)) { 
    Write-Host "❌ ERROR: No veo adb.exe en $adbExe" -ForegroundColor Red
    pause; exit 
}

$miIP_Detectada = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
        $_.InterfaceAlias -notlike "*Wi-Fi*" -and 
        $_.InterfaceAlias -notlike "*vEthernet*" -and 
        $_.IPAddress -like "192.168.10.*"
    } | Select-Object -First 1).IPAddress

if (-not $miIP_Detectada) { $miIP_Detectada = "0.0.0.0" }

while ($true) {
    Clear-Host
    Write-Host "=========================================================" -ForegroundColor Magenta
    Write-Host "    ESTACION DE TRABAJO CUERVO - V2.46 [MULTI-TAREA]     " -ForegroundColor Magenta
    Write-Host "    IP PC: $miIP_Detectada | DHCP: .200-.250            " -ForegroundColor Gray
    Write-Host "=========================================================" -ForegroundColor Magenta
    Write-Host " 1. Configurar y Limpiar App SOMOS (Filtra y Reporta MDM)" -ForegroundColor Cyan
    Write-Host " 2. HARD RESET / Borrado de Fabrica (Fuerza MDM + Clean)" -ForegroundColor Yellow
    Write-Host " 3. Solo OCULTAR Opciones de Desarrollador (Equipos listos)" -ForegroundColor Green
    Write-Host " 4. Salir" -ForegroundColor Red
    Write-Host "=========================================================" -ForegroundColor Magenta

    $Opcion = Read-Host "`nElige una opcion (1, 2, 3 o 4)"
    if ($Opcion -eq "4") { return }
    if ($Opcion -notmatch "^[123]$") { continue }

    $CantidadMesa = 0
    $inputUser = Read-Host "¿Cuantos equipos TOTALES tienes conectados físicamente en la mesa?"
    if (-not [int]::TryParse($inputUser, [ref]$CantidadMesa)) { $CantidadMesa = 1 }

    &$adbExe kill-server 2>$null
    &$adbExe start-server 2>$null

    $AccionPendiente = if ($Opcion -eq "1") { "CONFIGURAR" } elseif ($Opcion -eq "2") { "FORMATEAR" } else { "OCULTAR MENU DEV" }
    Write-Host "`n🔍 MODO CENTINELA: Analizando lote de $CantidadMesa equipos para $AccionPendiente..." -ForegroundColor Cyan
    
    $ipsEncontradas = @()
    $ipsDescartadasMDM = @()
    $macsDetectadasMDM = @() 
    $intentos = 0

    while (($ipsEncontradas.Count + $ipsDescartadasMDM.Count) -lt $CantidadMesa) {
        $ScanPool = [runspacefactory]::CreateRunspacePool(1, 50)
        $ScanPool.Open()
        $ScanHilos = @()

        foreach ($i in 200..250) {
            $ipTest = "192.168.10.$i"
            if ($ipTest -eq $miIP_Detectada -or $ipsEncontradas -contains $ipTest -or $ipsDescartadasMDM -contains $ipTest) { continue }

            $ScanBlock = {
                param($targetIp, $pathADB, $modoMenu)
                $socket = New-Object System.Net.Sockets.TcpClient
                try {
                    $connect = $socket.BeginConnect($targetIp, 5555, $null, $null)
                    if ($connect.AsyncWaitHandle.WaitOne(800, $false) -and $socket.Connected) {
                        $socket.Close()
                        
                        $serial = "${targetIp}:5555"
                        $null = &$pathADB connect $serial
                        Start-Sleep -Milliseconds 200
                        
                        $macRaw = &$pathADB -s $serial shell "cat /sys/class/net/eth0/address 2>/dev/null || cat /sys/class/net/wlan0/address 2>/dev/null"
                        $mac = if ($macRaw -match '([0-9A-F]{2}:){5}[0-9A-F]{2}') { $macRaw.Trim().ToUpper() } else { "MAC_DESCONOCIDA" }

                        $hasMDM = &$pathADB -s $serial shell "pm list packages" | Select-String "com.somos.mdmagent"
                        
                        if ($hasMDM) {
                            if ($modoMenu -eq "2") {
                                return "MDM_RESET|$targetIp|$mac"
                            }
                            else {
                                return "MDM_SKIP|$targetIp|$mac"
                            }
                        }
                        else {
                            return "CLEAN|$targetIp|$mac"
                        }
                    }
                }
                catch {}
                if ($socket) { $socket.Close(); $socket.Dispose() }
                return $null
            }

            $PSInstance = [powershell]::Create().AddScript($ScanBlock).AddArgument($ipTest).AddArgument($adbExe).AddArgument($Opcion)
            $PSInstance.RunspacePool = $ScanPool
            $ScanHilos += [PSCustomObject]@{ Pipe = $PSInstance; Result = $PSInstance.BeginInvoke() }
        }

        foreach ($hilo in $ScanHilos) {
            $res = $hilo.Pipe.EndInvoke($hilo.Result)
            if ($res) {
                $status, $ipResult, $macResult = $res -split '\|'
                
                if (($ipsEncontradas.Count + $ipsDescartadasMDM.Count) -lt $CantidadMesa) {
                    if ($status -eq "CLEAN" -and $ipsEncontradas -notcontains $ipResult) {
                        $ipsEncontradas += $ipResult
                        Write-Host "  [+] ADB LISTO: $ipResult (Limpio)" -ForegroundColor Green
                        [System.Console]::Beep(800, 150)
                    }
                    elseif ($status -eq "MDM_RESET" -and $ipsEncontradas -notcontains $ipResult) {
                        $ipsEncontradas += $ipResult
                        Write-Host "  [⚠️ MDM DETECTADO] IP $ipResult agregada al lote para forzar HARD RESET." -ForegroundColor Yellow
                        [System.Console]::Beep(440, 250)
                    }
                    elseif ($status -eq "MDM_SKIP" -and $ipsDescartadasMDM -notcontains $ipResult) {
                        $ipsDescartadasMDM += $ipResult
                        $macsDetectadasMDM += $macResult
                        Write-Host "  [❌ DESCARTADO] Equipo con AGENTE MDM en $ipResult -> MAC: $macResult" -ForegroundColor Red
                        [System.Console]::Beep(300, 400)
                    }
                }
            }
            $hilo.Pipe.Dispose()
        }
        $ScanPool.Close()
        $ScanPool.Dispose()

        $Evaluados = $ipsEncontradas.Count + $ipsDescartadasMDM.Count
        if ($Evaluados -lt $CantidadMesa) {
            $intentos++
            $faltan = $CantidadMesa - $Evaluados
            Write-Host "  ⏳ Detectados: $Evaluados de $CantidadMesa en mesa. Escaneando $faltan restantes... (Intento $intentos)" -ForegroundColor DarkGray
            Start-Sleep -Seconds 2
            
            if ($intentos -ge 15) {
                $forzar = Read-Host "`n⚠️ Han pasado 30s de escaneo. ¿Deseas avanzar ya con lo que se haya detectado? (S/N)"
                if ($forzar -match "S|s") { break }
                $intentos = 0
            }
        }
    }

    if ($macsDetectadasMDM.Count -gt 0) {
        $macsDetectadasMDM | Out-File -FilePath $ArchivoMDM -Encoding UTF8
        Write-Host "`n⚠️ Generado reporte de equipos con AGENTE MDM ($($macsDetectadasMDM.Count) detectados)." -ForegroundColor Yellow
        Start-Process notepad.exe $ArchivoMDM
    }

    if ($ipsEncontradas.Count -eq 0) {
        Write-Host "`n⚠️ Lote cerrado sin equipos procesables. Todos los conectados tenían MDM y fueron listados." -ForegroundColor Yellow
        if ((Read-Host "`n¿Siguiente lote o volver al menu? (S para continuar)") -notmatch "S|s") { break }
        continue
    }

    $AccionTxt = if ($Opcion -eq "1") { "Configurando quirúrgicamente" } elseif ($Opcion -eq "2") { "Enviando comandos de Factory Reset masivo a" } else { "Ocultando menú de desarrollo en" }
    Write-Host "`n🚀 Lote cerrado con éxito. $AccionTxt $($ipsEncontradas.Count) equipos simultáneamente..." -ForegroundColor Cyan
    
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxParalelo)
    $RunspacePool.Open()
    $hilos = @()

    foreach ($ip in $ipsEncontradas) {
        $ScriptBlock = {
            param($targetIp, $pathADB, $modo)
            try {
                $serial = "${targetIp}:5555"
                $null = &$pathADB connect $serial
                Start-Sleep -Milliseconds 400
                
                $macRaw = &$pathADB -s $serial shell "cat /sys/class/net/eth0/address 2>/dev/null || cat /sys/class/net/wlan0/address 2>/dev/null"
                $mac = if ($macRaw -match '([0-9A-F]{2}:){5}[0-9A-F]{2}') { $macRaw.Trim().ToUpper() } else { "MAC_DESCONOCIDA" }

                if ($modo -eq "1") {
                    $null = &$pathADB -s $serial shell "su 0 mount -o rw,remount /"
                    $null = &$pathADB -s $serial shell "su 0 rm -f /system/preinstall/*omos*.apk"
                    $null = &$pathADB -s $serial shell "su 0 rm -f /system/preinstall/*OMOS*.apk"

                    $cmds = @(
                        "setprop persist.sys.language es",
                        "setprop persist.sys.country US",
                        "setprop persist.sys.timezone America/Bogota",
                        "settings put system system_locales es-US",
                        "settings put global wifi_on 0",
                        "svc wifi disable"
                    )
                    foreach ($c in $cmds) { $null = &$pathADB -s $serial shell $c }

                    $pkgs = &$pathADB -s $serial shell "pm list packages | grep -i somos"
                    if ($pkgs) {
                        foreach ($line in $pkgs) {
                            $line = $line -replace "`r", ""
                            if ($line -match "package:(.+)") {
                                $appId = $matches[1].Trim()
                                if ($appId -ne "com.somos.mdmagent") {
                                    $null = &$pathADB -s $serial shell "am force-stop $appId"
                                    $null = &$pathADB -s $serial shell "pm clear $appId"
                                    $null = &$pathADB -s $serial shell "pm uninstall --user 0 $appId"
                                }
                            }
                        }
                    }

                    Start-Sleep -Milliseconds 500
                    $null = &$pathADB -s $serial shell reboot
                    return "OK|$targetIp|$mac"
                }
                elseif ($modo -eq "3") {
                    # Lógica de la NUEVA OPCIÓN 3: Solo ocultar el menú de desarrollador
                    $null = &$pathADB -s $serial shell "settings put global development_settings_enabled 0"
                    return "HIDDEN|$targetIp|$mac"
                }
                else {
                    $resetCmd = "am broadcast -a android.intent.action.MASTER_CLEAR -p android --receiver-foreground"
                    $null = &$pathADB -s $serial shell "su 0 $resetCmd || $resetCmd"
                    Start-Sleep -Milliseconds 300
                    $null = &$pathADB -s $serial shell "su 0 svc power reboot recovery || reboot recovery"
                    return "RESET|$targetIp|$mac"
                }

            }
            catch {
                return "EXCEPTION|$targetIp|$($_.Exception.Message)"
            }
        }

        $PSInstance = [powershell]::Create().AddScript($ScriptBlock).AddArgument($ip).AddArgument($adbExe).AddArgument($Opcion)
        $PSInstance.RunspacePool = $RunspacePool
        $hilos += [PSCustomObject]@{ Pipe = $PSInstance; Result = $PSInstance.BeginInvoke() }
    }

    $macsFinales = @()
    foreach ($hilo in $hilos) {
        $output = $hilo.Pipe.EndInvoke($hilo.Result)
        $data = $output -split '\|'
        
        if ($data[0] -eq 'OK') {
            Write-Host "  [OK - CONFIGURADO] $($data[1]) -> $($data[2])" -ForegroundColor Green
            $macsFinales += $data[2]
        }
        elseif ($data[0] -eq 'HIDDEN') {
            Write-Host "  [OK - MENÚ OCULTO] $($data[1]) -> $($data[2])" -ForegroundColor Green
        }
        elseif ($data[0] -eq 'RESET') {
            Write-Host "  [⚠️ EN RESET / RECOVERY] $($data[1]) -> $($data[2])" -ForegroundColor Yellow
        }
        else {
            Write-Host "  [X] $($data[1]) -> Fallo" -ForegroundColor Red
        }
        $hilo.Pipe.Dispose()
    }
    $RunspacePool.Close()

    if ($Opcion -eq "1" -and $macsFinales.Count -gt 0) {
        $macsFinales | Out-File -FilePath $ArchivoMAC -Encoding UTF8
        $macsFinales | ForEach-Object { "$(Get-Date -Format 'HH:mm') | $_" } | Out-File -FilePath $ArchivoBackup -Append
        
        Write-Host "`n✅ Reporte generado para equipos configurados." -ForegroundColor Green
        Start-Process notepad.exe $ArchivoMAC
        [System.Console]::Beep(523, 300)
    }
    elseif ($Opcion -eq "2") {
        Write-Host "`n✅ Ráfaga de comandos de formateo enviada al lote." -ForegroundColor Green
        [System.Console]::Beep(440, 400)
    }
    elseif ($Opcion -eq "3") {
        Write-Host "`n✅ Menú de desarrollo ocultado en todos los equipos detectados." -ForegroundColor Green
        [System.Console]::Beep(523, 300)
    }

    if ((Read-Host "`n¿Siguiente lote o volver al menu? (S para continuar)") -notmatch "S|s") { break }
}