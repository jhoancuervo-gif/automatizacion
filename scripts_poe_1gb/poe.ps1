﻿# =========================================================
# SCRIPT: poe.ps1 - VERSIÓN COMPATIBLE (PowerShell 5.1+)
# =========================================================

# Obtiene la carpeta donde está guardado este archivo .ps1 de forma automática
$currentDir = $PSScriptRoot
$rootDir    = Split-Path -Parent $currentDir
$backupDir  = Join-Path $rootDir "backups_macs"

# Define las rutas de los archivos de forma relativa al directorio actual
$fwFile     = Join-Path $currentDir "upg_appimage.bin"
$configFile = Join-Path $currentDir "Configmanage.bin"
$macFile    = Join-Path $currentDir "mac.txt"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Validación rápida: Detener si no existen los archivos necesarios
if (-not (Test-Path $fwFile)) { 
    Write-Host " [!] ERROR: No se encuentra '$fwFile' en la carpeta." -ForegroundColor Red
    Write-Host " [!] Verifique que el archivo upg_appimage.bin existe en la misma carpeta del script." -ForegroundColor Yellow
    pause; exit 
}

if (-not (Test-Path $configFile)) { 
    Write-Host " [!] ERROR: No se encuentra '$configFile' en la carpeta." -ForegroundColor Red
    Write-Host " [!] Verifique que el archivo Configmanage.bin existe en la misma carpeta del script." -ForegroundColor Yellow
    pause; exit 
}

do {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   HELLOTEK - PROCESO DE ALTO RENDIMIENTO (UNIVERSAL)    " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    $ip = "192.168.18.1"
    $auth = "admin:admin"
    $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($auth))

    # --- PASO 1: CAPTURA DE MAC ---
    Write-Host "[1/5] Identificando equipo..." -ForegroundColor Yellow
    arp -d $ip 2>$null
    Test-Connection $ip -Count 1 -Quiet | Out-Null
    
    $macResult = ""
    $arpTable = arp -a $ip | Out-String
    if ($arpTable -match "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})") {
        $macResult = $matches[0].ToUpper().Replace("-",":")
        Write-Host " -> MAC Detectada: $macResult" -ForegroundColor Green
    }

    if ([string]::IsNullOrWhiteSpace($macResult)) {
        Write-Host " [!] ERROR: No se detectó MAC. Verifique conexión." -ForegroundColor Red
        Write-Host " [!] Asegúrese que el switch está conectado y tiene IP $ip" -ForegroundColor Yellow
        $choice = Read-Host "ENTER para reintentar / 'S' para salir"
        if ($choice -eq "s") { break } else { continue }
    }

    # --- PASO 2: PREPARAR FLASH ---
    Write-Host "[2/5] Preparando Flash..." -ForegroundColor Yellow
    try {
        $headers = @{
            "Authorization" = "Basic $base64Auth"
        }
        
        $response = Invoke-WebRequest -Uri "http://$ip/cgi/toBootLoadUpgrade.cgi" `
            -Method Post `
            -Headers $headers `
            -TimeoutSec 5 `
            -UseBasicParsing
        
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [ADVERTENCIA] No se pudo preparar Flash, continuando..." -ForegroundColor Yellow
    }

    # --- PASO 3: ENVIAR FIRMWARE CON MÉTODO COMPATIBLE ---
    Write-Host "[3/5] Enviando Firmware..." -ForegroundColor Yellow
    
    # Verificar que el archivo existe y mostrar su tamaño
    if (Test-Path $fwFile) {
        $fwSize = (Get-Item $fwFile).Length
        Write-Host " -> Archivo firmware encontrado: $($fwSize) bytes" -ForegroundColor Gray
    } else {
        Write-Host " [!] ERROR: Archivo firmware no encontrado!" -ForegroundColor Red
        continue
    }
    
    # Probar conectividad antes de enviar
    Write-Host " -> Verificando conectividad con $ip..." -NoNewline
    if (Test-Connection $ip -Count 1 -Quiet) {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " FALLO" -ForegroundColor Red
        $choice = Read-Host "ENTER para reintentar / 'S' para salir"
        if ($choice -eq "s") { break } else { continue }
    }
    
    # Enviar firmware usando Invoke-WebRequest con -InFile (método compatible)
    Write-Host " -> Enviando firmware, espere (puede tomar hasta 30 segundos)..." -ForegroundColor Yellow
    
    try {
        # Método 1: Usar Invoke-WebRequest con -Form (PowerShell 6+)
        # Método 2: Usar curl con manejo mejorado
        # Vamos a usar curl pero con mejor formato
        
        # Crear un archivo temporal para el boundary
        $boundary = [System.Guid]::NewGuid().ToString()
        $tempFile = [System.IO.Path]::GetTempFileName()
        
        # Leer el archivo firmware como bytes
        $fileBytes = [System.IO.File]::ReadAllBytes($fwFile)
        
        # Crear el cuerpo multipart manualmente
        $bodyLines = @()
        $bodyLines += "--$boundary"
        $bodyLines += "Content-Disposition: form-data; name=`"FN`"; filename=`"upg_appimage.bin`""
        $bodyLines += "Content-Type: application/octet-stream"
        $bodyLines += ""
        $bodyLines += [System.Text.Encoding]::GetEncoding("iso-8859-1").GetString($fileBytes)
        $bodyLines += "--$boundary--"
        
        $body = [string]::Join("`r`n", $bodyLines)
        $bodyBytes = [System.Text.Encoding]::GetEncoding("iso-8859-1").GetBytes($body)
        
        # Configurar headers
        $headers = @{
            "Authorization" = "Basic $base64Auth"
            "Content-Type" = "multipart/form-data; boundary=$boundary"
        }
        
        # Enviar la solicitud
        $response = Invoke-WebRequest -Uri "http://$ip/cgi/upg_appimage.bin" `
            -Method Post `
            -Headers $headers `
            -Body $bodyBytes `
            -TimeoutSec 30 `
            -UseBasicParsing
        
        if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 302) {
            Write-Host " [OK] Firmware enviado exitosamente" -ForegroundColor Green
        } else {
            Write-Host " [ERROR] HTTP $($response.StatusCode)" -ForegroundColor Red
            
            $continuar = Read-Host "¿Desea continuar de todos modos? (S/N)"
            if ($continuar -ne "s") { 
                Write-Host "Proceso cancelado por el usuario." -ForegroundColor Red
                continue 
            }
        }
    } catch {
        Write-Host " [ERROR] Falló el envío del firmware" -ForegroundColor Red
        Write-Host " [!] $($_.Exception.Message)" -ForegroundColor Yellow
        
        # Último intento con curl mejorado
        Write-Host " -> Intentando método alternativo con curl..." -ForegroundColor Yellow
        
        try {
            # Usar curl con la ruta entre comillas dobles
            $curlCmd = "curl.exe -u $auth -X POST ""http://$ip/cgi/upg_appimage.bin"" -F ""FN=@`"$fwFile`"" --max-time 30 --connect-timeout 10 -v"
            Write-Host "    Comando: $curlCmd" -ForegroundColor Gray
            
            $result = Invoke-Expression $curlCmd 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host " [OK] Firmware enviado con curl" -ForegroundColor Green
            } else {
                Write-Host " [ERROR] También falló curl. Código: $LASTEXITCODE" -ForegroundColor Red
                if ($result) {
                    Write-Host " [!] $result" -ForegroundColor Yellow
                }
                
                $continuar = Read-Host "¿Desea continuar de todos modos? (S/N)"
                if ($continuar -ne "s") { 
                    Write-Host "Proceso cancelado por el usuario." -ForegroundColor Red
                    continue 
                }
            }
        } catch {
            Write-Host " [ERROR] $_" -ForegroundColor Red
            $continuar = Read-Host "¿Desea continuar de todos modos? (S/N)"
            if ($continuar -ne "s") { 
                Write-Host "Proceso cancelado por el usuario." -ForegroundColor Red
                continue 
            }
        }
    }
    
    # Espera para el reinicio
    Write-Host " -> Esperando reinicio del switch (20 segundos)..." -ForegroundColor Yellow
    for($i=1; $i -le 20; $i++) {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
    }
    Write-Host ""

    # --- PASO 4: ENVIAR CONFIGURACIÓN ---
    Write-Host "[4/5] Enviando Configuración..." -ForegroundColor Yellow
    
    if (Test-Path $configFile) {
        $cfgSize = (Get-Item $configFile).Length
        Write-Host " -> Archivo configuración encontrado: $($cfgSize) bytes" -ForegroundColor Gray
    }
    
    try {
        # Método compatible para enviar configuración
        $boundary = [System.Guid]::NewGuid().ToString()
        $fileBytes = [System.IO.File]::ReadAllBytes($configFile)
        
        $bodyLines = @()
        $bodyLines += "--$boundary"
        $bodyLines += "Content-Disposition: form-data; name=`"FN`"; filename=`"Configmanage.bin`""
        $bodyLines += "Content-Type: application/octet-stream"
        $bodyLines += ""
        $bodyLines += [System.Text.Encoding]::GetEncoding("iso-8859-1").GetString($fileBytes)
        $bodyLines += "--$boundary--"
        
        $body = [string]::Join("`r`n", $bodyLines)
        $bodyBytes = [System.Text.Encoding]::GetEncoding("iso-8859-1").GetBytes($body)
        
        $headers = @{
            "Authorization" = "Basic $base64Auth"
            "Content-Type" = "multipart/form-data; boundary=$boundary"
        }
        
        $response = Invoke-WebRequest -Uri "http://$ip/cgi/SG1008.bin" `
            -Method Post `
            -Headers $headers `
            -Body $bodyBytes `
            -TimeoutSec 15 `
            -UseBasicParsing
        
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [ERROR] No se pudo enviar configuración" -ForegroundColor Red
        Write-Host " [!] $($_.Exception.Message)" -ForegroundColor Yellow
    }

    # --- PASO 5: CAMBIO DE CONTRASEÑA ---
    Write-Host "[5/5] Aplicando seguridad (somos123)..." -ForegroundColor Yellow
    
    Write-Host " -> Esperando que el switch vuelva a estar disponible..." -NoNewline
    $switchVivo = $false
    for($i=0; $i -lt 20; $i++) {
        Start-Sleep -Seconds 2
        Write-Host "." -NoNewline
        if(Test-Connection $ip -Count 1 -Quiet) { 
            $switchVivo = $true
            Write-Host " CONECTADO" -ForegroundColor Green
            break 
        }
    }
    
    if(!$switchVivo) {
        Write-Host " NO RESPONDE" -ForegroundColor Red
    }

    if($switchVivo) {
        Start-Sleep -Seconds 3
        
        # Cambiar contraseña
        Write-Host " -> Cambiando contraseña a 'somos123.'..." -NoNewline
        
        try {
            $postData = "U=admin&NU=admin&U=somos123.&U=somos123."
            
            $headers = @{
                "Authorization" = "Basic $base64Auth"
                "Referer" = "http://$ip/usermng.htm"
                "Content-Type" = "application/x-www-form-urlencoded"
            }
            
            $response = Invoke-WebRequest -Uri "http://$ip/cgi/usermng.cgi" `
                -Method Post `
                -Headers $headers `
                -Body $postData `
                -TimeoutSec 10 `
                -UseBasicParsing
            
            Write-Host " [OK]" -ForegroundColor Green
        } catch {
            Write-Host " [FALLO]" -ForegroundColor Red
            Write-Host " [!] Error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host " [!] Switch no responde, no se pudo cambiar contraseña" -ForegroundColor Red
    }

    # GUARDADO Y CIERRE
    if ($macResult) {
        # 1. Guarda en el mac.txt de su misma carpeta local
        $macResult | Out-File -FilePath $macFile -Append -Encoding UTF8
        
        # 2. Guarda el historial en la carpeta backups_macs de la raíz
        if (-not (Test-Path $backupDir)) { 
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null 
        }
        
        $fecha = Get-Date -Format "yyyy-MM-dd"
        $historial = Join-Path $backupDir "poe_1gb_historial_$fecha.txt"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        if (-not (Test-Path $historial)) {
            Add-Content -Path $historial -Value "=== HISTORIAL DE SWITCHES POE ===" -Encoding UTF8
            Add-Content -Path $historial -Value "Fecha de creación: $timestamp" -Encoding UTF8
            Add-Content -Path $historial -Value "----------------------------------------" -Encoding UTF8
        }
        
        Add-Content -Path $historial -Value "$timestamp | 1Gb | $macResult" -Encoding UTF8
        
        Write-Host "`n[INFO] MAC guardada en:" -ForegroundColor Cyan
        Write-Host "  - Local: $macFile" -ForegroundColor Gray
        Write-Host "  - Backup: $historial" -ForegroundColor Gray
    }

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "FINALIZADO: $macResult" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    
    [System.Console]::Beep(1000, 150)
    [System.Console]::Beep(1200, 150)

    $next = Read-Host "`nPresione ENTER para el siguiente switch / 'S' para salir"
} while ($next -ne "s")

Write-Host "`nScript finalizado. ¡Hasta luego!" -ForegroundColor Cyan