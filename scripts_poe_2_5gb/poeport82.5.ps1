# =========================================================
# SCRIPT: poe_25g_MASTER_ROBUSTO.ps1
# FIX: CONTROL DE TIMEOUTS Y DOBLE AUTH
# =========================================================

if ($PSScriptRoot) { $baseDir = $PSScriptRoot } else { $baseDir = Get-Location }

$configFile = "$baseDir\port8_snmp.bin"
$macFile    = "$baseDir\mac.txt"
$ip = "192.168.18.1"
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

do {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   HELLOTEK 2.5G - CARGA CONFIG SNMP (ESTABLE)            " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    # [1] CAPTURA MAC
    Write-Host "[1/2] Identificando equipo..." -NoNewline
    arp -d $ip 2>$null
    Test-Connection $ip -Count 1 -Quiet | Out-Null
    
    $arpTable = arp -a $ip | Out-String
    if ($arpTable -match "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})") {
        $macResult = $matches[0].ToUpper().Replace("-",":")
        Write-Host " [MAC: $macResult]" -ForegroundColor Green
    } else {
        Write-Host " [NO DETECTADO]" -ForegroundColor Red
        $retry = Read-Host "ENTER reintentar / 'S' salir"; if ($retry -eq "s") { break } else { continue }
    }

    # [2] VALIDACIÓN DE ACCESO (Para evitar que se cuelgue por clave)
    Write-Host "[2/3] Validando credenciales..." -NoNewline
    $authList = @("admin:somos123.", "admin:admin")
    $validAuth = $null

    foreach ($cred in $authList) {
        # --connect-timeout evita que el script se quede "pensando" si no hay respuesta
        $test = curl.exe -u "$cred" -s -o NUL -w "%{http_code}" "http://$ip/index.htm" --connect-timeout 5 --max-time 8
        if ($test -eq "200") {
            $validAuth = $cred
            Write-Host " [OK: $cred]" -ForegroundColor Green
            break
        }
    }

    if (-not $validAuth) {
        Write-Host " [ERROR: No hay acceso al switch]" -ForegroundColor Red
        pause; continue
    }

    # [3] CARGA DE CONFIGURACIÓN
    Write-Host "[3/3] Subiendo Configuración..." -NoNewline
    
    # Añadimos --max-time 40 para que, si el switch no responde, el script recupere el control
    $res = curl.exe -u "$validAuth" -s -o NUL -w "%{http_code}" `
             --connect-timeout 10 --max-time 40 `
             -H "Referer: http://$ip/saveconfig.htm" `
             -X POST "http://$ip/cgi/SW_CFG.bin" -F "filename=@$configFile"

    if ($res -eq "200" -or $res -eq "302") {
        Write-Host " [OK - APLICADO]" -ForegroundColor Green
        Write-Host "      Esperando reinicio (15s)..." -NoNewline
        for($i=0; $i -lt 15; $i++) { Write-Host "." -NoNewline; Start-Sleep -Seconds 1 }
        
        if ($macResult) { "$macResult" | Add-Content -Path $macFile }
        [System.Console]::Beep(1000, 150)
    } else {
        Write-Host " [FALLO: Código HTTP $res]" -ForegroundColor Red
    }

    Write-Host "`n========================================" -ForegroundColor Cyan
    $n = Read-Host "ENTER Siguiente Switch / 'S' Salir"
} while ($n -ne "s")