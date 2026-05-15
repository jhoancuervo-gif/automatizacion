# ==============================================================================
# ESTACIÓN DE TRABAJO CUERVO - V2.20 (BORRADO QUIRÚRGICO DE ORIGEN)
# ==============================================================================

$scriptDir = $PSScriptRoot
$adbExe = Join-Path $scriptDir "platform-tools\adb.exe"
$ArchivoMAC = Join-Path $scriptDir "tvboxes_configurados.txt"
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
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "    ESTACION DE TRABAJO CUERVO - V2.20  " -ForegroundColor Magenta
    Write-Host "    IP PC: $miIP_Detectada | DHCP: .200-.250 " -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host " 1. Configurar y Limpiar App SOMOS" -ForegroundColor Cyan
    Write-Host " 2. HARD RESET (Borrado de Fabrica)" -ForegroundColor Yellow
    Write-Host " 3. Salir" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Magenta

    $Opcion = Read-Host "`nElige una opcion (1, 2 o 3)"
    if ($Opcion -eq "3") { break }
    if ($Opcion -notmatch "^[12]$") { continue }

    $Cantidad = 0
    $inputUser = Read-Host "¿Equipos para este lote?"
    if (-not [int]::TryParse($inputUser, [ref]$Cantidad)) { $Cantidad = 1 }

    & $adbExe kill-server 2>$null
    & $adbExe start-server 2>$null

    $AccionPendiente = if ($Opcion -eq "1") { "CONFIGURAR" } else { "FORMATEAR" }
    Write-Host "`n🔍 MODO CENTINELA: Esperando a que $Cantidad equipos esten listos para $AccionPendiente..." -ForegroundColor Cyan
    
    $ipsEncontradas = @()
    $intentos = 0

    while ($ipsEncontradas.Count -lt $Cantidad) {
        $ScanPool = [runspacefactory]::CreateRunspacePool(1, 50)
        $ScanPool.Open()
        $ScanHilos = @()

        foreach ($i in 200..250) {
            $ipTest = "192.168.10.$i"
            if ($ipTest -eq $miIP_Detectada -or $ipsEncontradas -contains $ipTest) { continue }

            $ScanBlock = {
                param($targetIp)
                $socket = New-Object System.Net.Sockets.TcpClient
                try {
                    $connect = $socket.BeginConnect($targetIp, 5555, $null, $null)
                    if ($connect.AsyncWaitHandle.WaitOne(800, $false) -and $socket.Connected) {
                        $socket.Close()
                        return $targetIp
                    }
                } catch {}
                if ($socket) { $socket.Close(); $socket.Dispose() }
                return $null
            }

            $PSInstance = [powershell]::Create().AddScript($ScanBlock).AddArgument($ipTest)
            $PSInstance.RunspacePool = $ScanPool
            $ScanHilos += [PSCustomObject]@{ Pipe = $PSInstance; Result = $PSInstance.BeginInvoke() }
        }

        foreach ($hilo in $ScanHilos) {
            $res = $hilo.Pipe.EndInvoke($hilo.Result)
            if ($res -and $ipsEncontradas.Count -lt $Cantidad) {
                $ipsEncontradas += $res
                Write-Host "  [+] ADB LISTO: $res ($($ipsEncontradas.Count)/$Cantidad)" -ForegroundColor Green
                [System.Console]::Beep(800, 200)
            }
            $hilo.Pipe.Dispose()
        }
        $ScanPool.Close()
        $ScanPool.Dispose()

        if ($ipsEncontradas.Count -lt $Cantidad) {
            $intentos++
            $faltan = $Cantidad - $ipsEncontradas.Count
            Write-Host "  ⏳ Faltan $faltan equipos. Buscando de nuevo... (Intento $intentos)" -ForegroundColor DarkGray
            Start-Sleep -Seconds 2
            
            if ($intentos -ge 15) {
                $forzar = Read-Host "`n⚠️ Han pasado 30s. ¿Forzar ejecución con los $($ipsEncontradas.Count) encontrados? (S/N)"
                if ($forzar -match "S|s") { break }
                $intentos = 0
            }
        }
    }

    $AccionTxt = if ($Opcion -eq "1") { "Configurando" } else { "Enviando Factory Reset a" }
    Write-Host "`n🚀 $AccionTxt $($ipsEncontradas.Count) equipos simultáneamente..." -ForegroundColor Cyan
    
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxParalelo)
    $RunspacePool.Open()
    $hilos = @()

    foreach ($ip in $ipsEncontradas) {
        $ScriptBlock = {
            param($targetIp, $pathADB, $modo)
            try {
                $serial = "${targetIp}:5555"
                $null = & $pathADB connect $serial
                Start-Sleep -Milliseconds 600
                
                $macRaw = & $pathADB -s $serial shell "cat /sys/class/net/eth0/address 2>/dev/null || cat /sys/class/net/wlan0/address 2>/dev/null"
                $mac = if ($macRaw -match '([0-9A-F]{2}:){5}[0-9A-F]{2}') { $macRaw.Trim().ToUpper() } else { "MAC_DESCONOCIDA" }

                if ($modo -eq "1") {
                    # ==========================================================
                    # 1. DESTRUCCIÓN QUIRÚRGICA DEL ORIGEN
                    # ==========================================================
                    # Remontamos en lectura/escritura y borramos SOLO los APKs de Somos
                    $null = & $pathADB -s $serial shell "su 0 mount -o rw,remount /"
                    $null = & $pathADB -s $serial shell "su 0 rm -f /system/preinstall/*omos*.apk"
                    $null = & $pathADB -s $serial shell "su 0 rm -f /system/preinstall/*OMOS*.apk"

                    # ==========================================================
                    # 2. CONFIGURACIÓN DEL SISTEMA
                    # ==========================================================
                    $cmds = @(
                        "setprop persist.sys.language es",
                        "setprop persist.sys.country US",
                        "setprop persist.sys.timezone America/Bogota",
                        "settings put system system_locales es-US",
                        "settings put global wifi_on 0",
                        "svc wifi disable"
                    )
                    foreach ($c in $cmds) { $null = & $pathADB -s $serial shell $c }

                    # ==========================================================
                    # 3. LIMPIEZA DE LA APP ACTIVA (Si ya se instaló en el usuario)
                    # ==========================================================
                    # Se agregó "-i" al grep por si aparece como SomosTV
                    $pkgs = & $pathADB -s $serial shell "pm list packages | grep -i somos"
                    if ($pkgs) {
                        foreach ($line in $pkgs) {
                            $line = $line -replace "`r", ""
                            if ($line -match "package:(.+)") {
                                $appId = $matches[1].Trim()
                                $null = & $pathADB -s $serial shell "am force-stop $appId"
                                $null = & $pathADB -s $serial shell "pm clear $appId"
                                $null = & $pathADB -s $serial shell "pm uninstall --user 0 $appId"
                            }
                        }
                    }

                    Start-Sleep -Milliseconds 500
                    $null = & $pathADB -s $serial shell reboot
                    return "OK|$targetIp|$mac"
                } 
                else {
                    $resetCmd = "am broadcast -a android.intent.action.MASTER_CLEAR -p android --receiver-foreground"
                    $null = & $pathADB -s $serial shell "su 0 $resetCmd || $resetCmd"
                    return "RESET|$targetIp|$mac"
                }

            } catch {
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
        } elseif ($data[0] -eq 'RESET') {
            Write-Host "  [⚠️ EN RESET] $($data[1]) -> $($data[2]) (El equipo se reiniciara)" -ForegroundColor Yellow
        } else {
            Write-Host "  [X] $($data[1]) -> Fallo" -ForegroundColor Red
        }
        $hilo.Pipe.Dispose()
    }
    $RunspacePool.Close()

    if ($Opcion -eq "1" -and $macsFinales.Count -gt 0) {
        $macsFinales | Out-File -FilePath $ArchivoMAC -Encoding UTF8
        $macsFinales | ForEach-Object { "$(Get-Date -Format 'HH:mm') | $_" } | Out-File -FilePath $ArchivoBackup -Append
        
        Write-Host "`n✅ Reporte generado exitosamente." -ForegroundColor Green
        Start-Process notepad.exe $ArchivoMAC
        [System.Console]::Beep(523, 300)
    } elseif ($Opcion -eq "2") {
        Write-Host "`n✅ Comandos de Factory Reset enviados. Espera a que los equipos inicien." -ForegroundColor Green
        [System.Console]::Beep(440, 400)
    }

    if ((Read-Host "`n¿Siguiente lote o volver al menu? (S para continuar)") -notmatch "S|s") { break }
}