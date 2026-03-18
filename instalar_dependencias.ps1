# =========================================================
# SCRIPT: instalar_dependencias.ps1 - CONFIGURACIÓN DE ENTORNO
# =========================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   CONFIGURADOR DE DEPENDENCIAS - PROYECTO CUERVO        " -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "==========================================================" -ForegroundColor Cyan

# --- 1. VERIFICAR PYTHON ---
Write-Host "`n[1/3] Verificando Python..." -ForegroundColor Yellow
if (Get-Command python -ErrorAction SilentlyContinue) {
    $pyVer = python --version
    Write-Host " [+] $pyVer detectado." -ForegroundColor Green
    
    Write-Host " [+] Actualizando pip e instalando librerias Python..." -ForegroundColor Gray
    python -m pip install --upgrade pip --quiet
    # Instalamos las 3 librerías clave que usas
    python -m pip install requests beautifulsoup4 asyncssh python-dotenv --quiet
    Write-Host " ✅ Librerias Python listas (requests, bs4, asyncssh, dotenv)." -ForegroundColor Green
} else {
    Write-Host " ❌ Python NO está instalado. Por favor instálelo desde python.org" -ForegroundColor Red
}

# --- 2. VERIFICAR MÓDULOS POWERSHELL ---
Write-Host "`n[2/3] Verificando Módulos PowerShell..." -ForegroundColor Yellow
# Aunque usamos mayormente comandos nativos y curl, aseguramos compatibilidad
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Write-Host " ✅ Politica de ejecucion ajustada a RemoteSigned." -ForegroundColor Green

# --- 3. VERIFICAR CURL (Vital para POEs) ---
Write-Host "`n[3/3] Verificando CURL..." -ForegroundColor Yellow
if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
    Write-Host " ✅ CURL detectado y listo para flashear." -ForegroundColor Green
} else {
    Write-Host " ⚠️ CURL no detectado. Si usa Windows 10/11 ya deberia venir incluido." -ForegroundColor Yellow
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "   TODO LISTO. Ya puede usar los scripts en esta PC.     " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Presione ENTER para volver al menu..."
Read-Host