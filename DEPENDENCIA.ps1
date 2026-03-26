# =========================================================
# SCRIPT: instalar_dependencias_v2.3_FIXED.ps1
# =========================================================

$ErrorActionPreference = "Stop"

try {
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "   INSTALADOR DE DEPENDENCIAS    " -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan

    # 1. VERIFICAR PYTHON
    Write-Host "`n[1/6] Verificando Python..." -ForegroundColor Yellow
    $pythonCmd = $null
    if (Get-Command python -ErrorAction SilentlyContinue) { $pythonCmd = "python" }
    elseif (Get-Command python3 -ErrorAction SilentlyContinue) { $pythonCmd = "python3" }
    else { throw "Python no esta instalado o no esta en el PATH." }
    Write-Host "OK: Python detectado" -ForegroundColor Green

    # 2. ENTORNO VIRTUAL
    Write-Host "`n[2/6] Verificando entorno virtual..." -ForegroundColor Yellow
    $venvPath = ".venv"
    $pythonVenv = Join-Path $venvPath "Scripts\python.exe"
    if (-Not (Test-Path $venvPath)) {
        Write-Host "Creando entorno virtual..." -ForegroundColor Cyan
        & $pythonCmd -m venv $venvPath
    }

    # 3. INSTALAR DEPENDENCIAS
    Write-Host "`n[3/6] Instalando dependencias..." -ForegroundColor Yellow
    $packages = @("requests", "beautifulsoup4", "asyncssh", "python-dotenv")
    foreach ($pkg in $packages) {
        Write-Host "Instalando $pkg..." -ForegroundColor Cyan
        & $pythonVenv -m pip install $pkg --quiet
    }

    # 4. VERIFICAR NMAP
    Write-Host "`n[4/6] Verificando Nmap..." -ForegroundColor Yellow
    if (-not (Get-Command nmap -ErrorAction SilentlyContinue)) {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        if ($isAdmin) {
            Write-Host "Instalando Nmap..." -ForegroundColor Cyan
            winget install -e --id Insecure.Nmap --accept-source-agreements --accept-package-agreements
        } else {
            Write-Host "AVISO: Ejecuta como ADMIN para instalar Nmap automaticamente." -ForegroundColor Yellow
        }
    } else {
        Write-Host "OK: Nmap ya esta disponible." -ForegroundColor Green
    }

    Write-Host "`n=========================================" -ForegroundColor Cyan
    Write-Host "   INSTALACION COMPLETA Y FUNCIONAL   " -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Cyan

} catch {
    Write-Host "`nERROR DETECTADO:" -ForegroundColor Red
    Write-Host $($_.Exception.Message) -ForegroundColor Red
} finally {
    Write-Host "`nPresiona cualquier tecla para salir..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}