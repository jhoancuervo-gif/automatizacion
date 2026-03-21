# =========================================================
# SCRIPT: poe_25g_NATIVO_PS.ps1
# FIX: MOTOR NATIVO PARA EVITAR BLOQUEO DE ANTIVIRUS (000)
# =========================================================

$baseDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$configFile = Join-Path $baseDir "port8_snmp.bin"
$macFile    = Join-Path $baseDir "mac.txt"
$ip = "192.168.18.1"

# Forzamos limpieza de errores visuales
[Console]::OutputEncoding = [System.Text.Encoding]::ASCII

# 1. VERIFICACION DE ARCHIVO
if (-not (Test-Path $configFile)) {
    Write-Host " [!] ERROR: No se encuentra port8_snmp.bin" -ForegroundColor Red
    pause; exit
}

do {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   HELLOTEK 2.5G - CARGA NATIVA (ANTI-BLOCK)              " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    # [1] IDENTIFICACION MAC
    Write-Host "[1/3] Identificando equipo..." -NoNewline
    arp -d $ip 2>$null
    Test-Connection $ip -Count 1 -Quiet | Out-Null
    
    $macResult = "00:00:00:00:00:00"
    if ((arp -a $ip | Out-String) -match "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})") {
        $macResult = $matches[0].ToUpper().Replace("-",":")
        Write-Host " [MAC: $macResult]" -ForegroundColor Green
    } else {
        Write-Host " [NO DETECTADO]" -ForegroundColor Red
        $n = Read-Host "ENTER reintentar / 'S' salir"; if ($n -eq "s") { break } else { continue }
    }

    # [2] LOGIN NATIVO (Basic Auth)
    Write-Host "[2/3] Validando acceso..." -NoNewline
    $user = "admin"
    $pass = "somos123." # Probamos primero la nueva
    
    # Creamos la credencial en el formato que Windows prefiere
    $pair = "$($user):$($pass)"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $headers = @{ Authorization = "Basic $base64" }

    try {
        $test = Invoke-WebRequest -Uri "http://$ip/index.htm" -Headers $headers -TimeoutSec 5 -UseBasicParsing
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        # Si falla, intentamos con admin:admin
        $pair = "admin:admin"
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
        $base64 = [System.Convert]::ToBase64String($bytes)
        $headers = @{ Authorization = "Basic $base64" }
        try {
            $test = Invoke-WebRequest -Uri "http://$ip/index.htm" -Headers $headers -TimeoutSec 5 -UseBasicParsing
            Write-Host " [OK: admin]" -ForegroundColor Green
        } catch {
            Write-Host " [ERROR DE ACCESO]" -ForegroundColor Red; pause; continue
        }
    }

    # [3] SUBIDA DE ARCHIVO (Metodo Multipart Nativo)
    Write-Host "[3/3] Subiendo configuracion..." -NoNewline
    
    try {
        # Preparamos el archivo para enviarlo como "Multipart Form Data"
        $fileBytes = [System.IO.File]::ReadAllBytes($configFile)
        $LF = "`r`n"
        $boundary = "----WebKitFormBoundary" + [System.Guid]::NewGuid().ToString().Replace("-","")
        $body = "--$boundary$LF"
        $body += "Content-Disposition: form-data; name=`"filename`"; filename=`"port8_snmp.bin`"$LF"
        $body += "Content-Type: application/octet-stream$LF$LF"
        
        $postData = [System.Text.Encoding]::GetEncoding('ISO-8859-1').GetBytes($body) + $fileBytes + [System.Text.Encoding]::GetEncoding('ISO-8859-1').GetBytes("$LF--$boundary--$LF")

        $res = Invoke-WebRequest -Uri "http://$ip/cgi/SW_CFG.bin" `
                                 -Method Post `
                                 -Headers $headers `
                                 -ContentType "multipart/form-data; boundary=$boundary" `
                                 -Body $postData `
                                 -TimeoutSec 30 `
                                 -UseBasicParsing

        if ($res.StatusCode -eq 200 -or $res.StatusCode -eq 302) {
            Write-Host " [EXITOSO]" -ForegroundColor Green
            $macResult | Add-Content -Path $macFile
            [System.Console]::Beep(1000, 200)
        }
    } catch {
        Write-Host " [FALLO CRITICO]" -ForegroundColor Red
        Write-Host " Detalle: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    Write-Host "========================================" -ForegroundColor Cyan
    $next = Read-Host "ENTER Siguiente / 'S' Salir"
} while ($next -ne "s")