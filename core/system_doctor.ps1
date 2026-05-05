# =====================================================================
# SYSTEM DOCTOR - VERIFICADOR DE SALUD DEL SISTEMA
# =====================================================================
$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Check-Health {
    Write-Host "`n  [🔍] INICIANDO DIAGNOSTICO DE SISTEMA..." -ForegroundColor Cyan
    Write-Host "  --------------------------------------------------" -ForegroundColor Gray
    $allOk = $true

    # 1. Verificar Internet
    Write-Host "  [1/5] Verificando conexion a Internet... " -NoNewline
    if (Test-Connection -ComputerName google.com -Count 1 -Quiet) {
        Write-Host "OK" -ForegroundColor Green
    } else {
        Write-Host "FALLO" -ForegroundColor Red
        Write-Host "        (Verifica tu conexion para poder sincronizar GitHub y el Portal)" -ForegroundColor Gray
        $allOk = $false
    }

    # 2. Verificar Herramientas Criticas
    $tools = @("python", "git", "nmap")
    Write-Host "  [2/5] Verificando herramientas instaladas..."
    foreach ($tool in $tools) {
        Write-Host "        - $tool: " -NoNewline
        if (Get-Command $tool -ErrorAction SilentlyContinue) {
            Write-Host "INSTALADO" -ForegroundColor Green
        } else {
            Write-Host "NO ENCONTRADO" -ForegroundColor Red
            $allOk = $false
        }
    }

    # 3. Verificar Archivo .env
    Write-Host "  [3/5] Verificando configuracion (.env)... " -NoNewline
    $envPath = Join-Path $PSScriptRoot "..\.env"
    if (Test-Path $envPath) {
        $content = Get-Content $envPath
        if ($content -match "ISP_USERNAME=" -and $content -match "ISP_PASSWORD=") {
            Write-Host "OK" -ForegroundColor Green
        } else {
            Write-Host "INCOMPLETO" -ForegroundColor Yellow
            Write-Host "        (Faltan credenciales del Portal ISP)" -ForegroundColor Gray
            $allOk = $false
        }
    } else {
        Write-Host "NO EXISTE" -ForegroundColor Red
        $allOk = $false
    }

    # 4. Verificar Entorno Python (.venv)
    Write-Host "  [4/5] Verificando entorno virtual (.venv)... " -NoNewline
    $venvPath = Join-Path $PSScriptRoot "..\.venv"
    if (Test-Path $venvPath) {
        Write-Host "OK" -ForegroundColor Green
    } else {
        Write-Host "NO ENCONTRADO" -ForegroundColor Yellow
        Write-Host "        (Ejecute la opcion 11 del menu principal para crearlo)" -ForegroundColor Gray
        $allOk = $false
    }

    # 5. Verificar Carpetas de Trabajo
    Write-Host "  [5/5] Verificando carpetas de produccion... " -NoNewline
    $backupPath = Join-Path $PSScriptRoot "..\backups_macs"
    if (Test-Path $backupPath) {
        Write-Host "OK" -ForegroundColor Green
    } else {
        New-Item -ItemType Directory -Path $backupPath | Out-Null
        Write-Host "CREADA" -ForegroundColor Green
    }

    Write-Host "  --------------------------------------------------" -ForegroundColor Gray
    if ($allOk) {
        Write-Host "  [✔] SISTEMA SALUDABLE. LISTO PARA OPERAR." -ForegroundColor Green
        Start-Sleep -Seconds 1
    } else {
        Write-Host "  [!] SE DETECTARON ADVERTENCIAS O ERRORES." -ForegroundColor Yellow
        Write-Host "      Revise los puntos marcados en rojo antes de continuar." -ForegroundColor Gray
        Pause
    }
}

Check-Health
