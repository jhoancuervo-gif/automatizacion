# ==============================================================================
# ESTACIÓN DE TRABAJO - PARALELO TOTAL (FIX DE SINTAXIS)
# ==============================================================================

$scriptDir = $PSScriptRoot
$adbExe = Join-Path $scriptDir "platform-tools\adb.exe"
$ArchivoMAC = Join-Path $scriptDir "tvboxes_configurados.txt"
$ArchivoBackup = Join-Path $scriptDir "mac_backup.txt"
$CantidadGlobal = 0

$miIP_Detectada = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
        $_.InterfaceAlias -notlike "*Wi-Fi*" -and $_.IPAddress -like "192.168.10.*"
    } | Select-Object -First 1).IPAddress
if (-not $miIP_Detectada) { $miIP_Detectada = "0.0.0.0" }

while ($true) {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "    ESTACION CUERVO - PARALELO FIX     " -ForegroundColor Magenta
    Write-Host "    IP PC: $miIP_Detectada | Rango: .200-.230" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Magenta

    $inputUser = Read-Host "`n¿Cuántos equipos vas a procesar hoy?"
    if ($inputUser -as [int]) { $CantidadGlobal = [int]$inputUser } else { $CantidadGlobal = 1 }

    & $adbExe kill-server 2>$null
    & $adbExe start-server 2>$null

    $tvboxes = @()
    Write-Host "`n:mag: Buscando $CantidadGlobal equipos..." -ForegroundColor Cyan

    do {
        $nmapOut = nmap -p 5555 --open -n -T5 192.168.10.200-230 -oG -
        $ipsEncontradas = $nmapOut | Select-String "Host: (\d+\.\d+\.\d+\.\d+)" | ForEach-Object { $_.Matches.Groups[1].Value } | Where-Object { $_ -ne $miIP_Detectada }

        foreach ($ip in $ipsEncontradas) {
            if ($ip -notin $tvboxes -and $tvboxes.Count -lt $CantidadGlobal) {
                $tvboxes += $ip
                Write-Host "  -> ENCONTRADO: $ip ($($tvboxes.Count)/$CantidadGlobal)" -ForegroundColor Green
            }
        }
        if ($tvboxes.Count -lt $CantidadGlobal) { Start-Sleep -Seconds 1 }
    } while ($tvboxes.Count -lt $CantidadGlobal)

    Write-Host "`n:rocket: Procesando todos los equipos al tiempo..." -ForegroundColor Cyan
    $jobs = @()

    foreach ($ip in $tvboxes) {
        $jobs += Start-Job -ScriptBlock {
            param($ip, $adbExe)

            # Conexión inicial
            & $adbExe connect "${ip}:5555" | Out-Null

            # 1. Obtener MAC
            $m = & $adbExe -s "${ip}:5555" shell "cat /sys/class/net/eth0/address 2>/dev/null || cat /sys/class/net/wlan0/address 2>/dev/null"

            if ($m) {
                $mac = $m.Trim().ToUpper()

                # 2. Configuración Regional (Comandos individuales para evitar errores de comillas)
                & $adbExe -s "${ip}:5555" shell "setprop persist.sys.language es"
                & $adbExe -s "${ip}:5555" shell "setprop persist.sys.country US"
                & $adbExe -s "${ip}:5555" shell "setprop persist.sys.timezone America/Bogota"
                & $adbExe -s "${ip}:5555" shell "settings put system system_locales es-US"

                # 3. Limpieza de APP SOMOS
                $pkgs = & $adbExe -s "${ip}:5555" shell "pm list packages | grep somos"
                if ($pkgs) {
                    foreach ($line in $pkgs) {
                        $AppID = $line.Replace("package:", "").Trim()
                        if ($AppID) {
                            & $adbExe -s "${ip}:5555" shell "pm uninstall --user 0 $AppID"
                        }
                    }
                }

                # 4. WiFi OFF y Reboot
                & $adbExe -s "${ip}:5555" shell "svc wifi disable"
                & $adbExe -s "${ip}:5555" shell "settings put global wifi_on 0"
                & $adbExe -s "${ip}:5555" shell "reboot"

                return "$ip|$mac"
            }
        } -ArgumentList $ip, $adbExe
    }

    Write-Host ":hourglass_flowing_sand: Trabajando en segundo plano... espera un momento." -ForegroundColor Yellow
    $resultados = $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job

    $macsFinales = @()
    foreach ($linea in $resultados) {
        if ($linea -match "\|") {
            $data = $linea.Split("|")
            $macsFinales += $data[1]
            Write-Host "  [OK] $($data[0]) -> $($data[1])" -ForegroundColor Green
        }
    }

    $macsFinales | Out-File -FilePath $ArchivoMAC -Encoding UTF8
    $macsFinales | ForEach-Object { "$(Get-Date -Format 'HH:mm') | $_" } | Out-File -FilePath $ArchivoBackup -Append

    Write-Host "`n[LISTO] Reporte generado." -ForegroundColor Green
    Start-Process notepad.exe $ArchivoMAC
    [System.Console]::Beep(523, 200)

    $ask = Read-Host "`n¿Siguiente lote? (S/N)"
    if ($ask -notmatch "S|s") { break }
}