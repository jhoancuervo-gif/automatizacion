# =========================================================
# SCRIPT: poe_25g_FIX_COMPANERO.ps1
# FIX: PROTECCION DE RUTA Y LIMPIEZA DE CARACTERES
# =========================================================

if ($PSScriptRoot) { $baseDir = $PSScriptRoot } else { $baseDir = Get-Location }

# Forzamos comillas en la ruta por si hay espacios
$configFile = "$baseDir\port8_snmp.bin"
$macFile    = "$baseDir\mac.txt"
$ip = "192.168.18.1"

# Forzamos la consola a usar una codificacion estandar
[Console]::OutputEncoding = [System.Text.Encoding]::ASCII

do {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   HELLOTEK 2.5G - CARGA CONFIG SNMP (FIX COMPANERO)      " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    # [1] CAPTURA MAC
    Write-Host "[1/3] Identificando equipo..." -NoNewline
    arp -d $ip 2>$null
    Start-Sleep -Milliseconds 500
    Test-Connection $ip -Count 1 -Quiet | Out-Null
    
    $arpTable = arp -a $ip | Out-String
    if ($arpTable -match "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})") {
        $macResult = $matches[0].ToUpper().Replace("-",":")
        Write-Host " [MAC: $macResult]" -ForegroundColor Green
    } else {
        Write-Host " [NO DETECTADO]" -ForegroundColor Red
        $retry = Read-Host "ENTER reintentar / 'S' salir"; if ($retry -eq "s") { break } else { continue }
    }

    # [2] VALIDACION DE ACCESO
    Write-Host "[2/3] Validando credenciales..." -NoNewline
    $authList = @("admin:somos123.", "admin:admin")
    $validAuth = $null

    foreach ($cred in $authList) {
        $test = curl.exe -u "$cred" -s -o NUL -w "%{http_code}" "http://$ip/index.htm" --connect-timeout 5 --max-time 8
        if ($test -eq "200") {
            $validAuth = $cred
            Write-Host " [OK: $cred]" -ForegroundColor Green
            break
        }
    }

    if (-not $validAuth) {
        Write-Host " [ERROR: No hay acceso]" -ForegroundColor Red
        pause; continue
    }

    # [3] CARGA DE CONFIGURACION
    Write-Host "[3/3] Subiendo archivo..." -NoNewline
    
    # Pequeña pausa para que el switch procese el login antes del POST pesado
    Start-Sleep -Seconds 1

    # IMPORTANTE: Usamos comillas dobles para la ruta del archivo binario
    $res = curl.exe -u "$validAuth" -s -o NUL -w "%{http_code}" `
             --connect-timeout 15 --max-time 45 `
             -H "Referer: http://$ip/saveconfig.htm" `
             -X POST "http://$ip/cgi/SW_CFG.bin" -F "filename=@$configFile"

    if ($res -eq "200" -or $res -eq "302") {
        Write-Host " [OK - EXITOSO]" -ForegroundColor Green
        if ($macResult) { "$macResult" | Add-Content -Path "$macFile" }
        Write-Host "      Reiniciando equipo..."
        Start-Sleep -Seconds 5
    } else {
        # Si da 000, imprimimos una sugerencia de red
        Write-Host " [FALLO: Codigo HTTP $res]" -ForegroundColor Red
        if ($res -eq "000") { 
            Write-Host "      (Posible bloqueo de Firewall o cable defectuoso)" -ForegroundColor Yellow 
        }
    }

    Write-Host "========================================" -ForegroundColor Cyan
    $n = Read-Host "ENTER Siguiente / 'S' Salir"
} while ($n -ne "s")