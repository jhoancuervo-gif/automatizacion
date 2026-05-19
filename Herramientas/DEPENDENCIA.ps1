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
    
    # Buscar el ejecutable real ignorando los alias de la tienda si es posible
    $pythonPath = (Get-Command python.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
    if (-not $pythonPath) {
        $pythonPath = (Get-Command python3.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
    }

    if ($pythonPath) {
        try {
            # Verificar si realmente funciona (que no sea el alias de la Windows Store vacío)
            $ver = & $pythonPath --version 2>&1
            if ($ver -match "Python") {
                $pythonCmd = $pythonPath
                Write-Host "OK: Python detectado en $pythonCmd" -ForegroundColor Green
            } else {
                throw "El comando 'python' detectado no es válido o es un alias de la Windows Store."
            }
        } catch {
            throw "Python detectado pero no se puede ejecutar. Por favor, instale Python desde python.org y marque 'Add Python to PATH'."
        }
    } else {
        throw "Python no esta instalado o no esta en el PATH. Descarguelo de python.org"
    }

    # 2. ENTORNO VIRTUAL
    Write-Host "`n[2/6] Verificando entorno virtual..." -ForegroundColor Yellow
    $venvPath = Join-Path (Split-Path $PSScriptRoot -Parent) ".venv"
    $pythonVenv = Join-Path $venvPath "Scripts\python.exe"
    
    if (-Not (Test-Path $venvPath)) {
        Write-Host "Creando entorno virtual en $venvPath..." -ForegroundColor Cyan
        & $pythonCmd -m venv "$venvPath"
    }

    # 3. INSTALAR DEPENDENCIAS
    Write-Host "`n[3/6] Instalando dependencias..." -ForegroundColor Yellow
    $packages = @("requests", "beautifulsoup4", "asyncssh", "python-dotenv", "selenium")
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