# =========================================================
# SCRIPT: instalar_dependencias_v2.2.ps1
# =========================================================

# Forzar que los errores detengan el script
$ErrorActionPreference = "Stop"

try {

    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "   INSTALADOR DE DEPENDENCIAS    " -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan

    # -------------------------------
    # 1. VALIDAR PYTHON
    # -------------------------------
    Write-Host "`n[1/6] Verificando Python..." -ForegroundColor Yellow

    $pythonCmd = $null

    if (Get-Command python -ErrorAction SilentlyContinue) {
        $pythonCmd = "python"
    } elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
        $pythonCmd = "python3"
    } else {
        throw "Python no está instalado o no está en el PATH."
    }

    Write-Host "✔️ Python detectado: $pythonCmd" -ForegroundColor Green
    & $pythonCmd --version

    # -------------------------------
    # 2. CREAR ENTORNO VIRTUAL
    # -------------------------------
    Write-Host "`n[2/6] Verificando entorno virtual (.venv)..." -ForegroundColor Yellow

    $venvPath = ".venv"
    $venvActivate = ".\.venv\Scripts\Activate"

    $recrearVenv = $false

    if (Test-Path $venvPath) {

        if (-Not (Test-Path $venvActivate)) {
            Write-Host "⚠️ Entorno virtual corrupto. Se recreará..." -ForegroundColor Yellow
            Remove-Item -Recurse -Force $venvPath
            $recrearVenv = $true
        } else {
            Write-Host "✔️ Entorno virtual válido" -ForegroundColor Green
        }

    } else {
        $recrearVenv = $true
    }

    if ($recrearVenv) {
        Write-Host "➡️ Creando entorno virtual..." -ForegroundColor Cyan
        & $pythonCmd -m venv $venvPath

        if ($LASTEXITCODE -ne 0) {
            throw "Error creando entorno virtual."
        }

        Write-Host "✔️ Entorno virtual creado correctamente" -ForegroundColor Green
    }

    # -------------------------------
    # 3. ACTIVAR ENTORNO VIRTUAL
    # -------------------------------
    Write-Host "`n[3/6] Activando entorno virtual..." -ForegroundColor Yellow

    $venvActivate = ".\.venv\Scripts\Activate"

    if (Test-Path $venvActivate) {
        . $venvActivate
        Write-Host "✔️ Entorno virtual activado" -ForegroundColor Green
    } else {
        throw "No se encontró el script de activación del entorno virtual."
    }

    # -------------------------------
    # 4. INSTALAR DEPENDENCIAS
    # -------------------------------
    Write-Host "`n[4/6] Instalando dependencias..." -ForegroundColor Yellow

    & $pythonCmd -m pip install --upgrade pip

    $packages = @(
        "requests",
        "beautifulsoup4",
        "asyncssh",
        "python-dotenv"
    )

    foreach ($pkg in $packages) {
        Write-Host "➡️ Instalando $pkg..." -ForegroundColor Cyan
        & $pythonCmd -m pip install $pkg
    }

    Write-Host "✔️ Dependencias instaladas correctamente" -ForegroundColor Green

    # -------------------------------
    # 5. VALIDAR CURL
    # -------------------------------
    Write-Host "`n[5/6] Verificando CURL..." -ForegroundColor Yellow

    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        Write-Host "✔️ CURL disponible" -ForegroundColor Green
    } else {
        Write-Host "⚠️ CURL no encontrado" -ForegroundColor Yellow
    }

    # -------------------------------
    # 6. INSTALAR NMAP
    # -------------------------------
    Write-Host "`n[6/6] Verificando Nmap..." -ForegroundColor Yellow

    if (Get-Command nmap -ErrorAction SilentlyContinue) {
        Write-Host "✔️ Nmap ya está instalado" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Nmap no encontrado. Intentando instalar..." -ForegroundColor Yellow

        if (Get-Command winget -ErrorAction SilentlyContinue) {

            Write-Host "➡️ Instalando Nmap con winget..." -ForegroundColor Cyan

            winget install -e --id Insecure.Nmap --accept-source-agreements --accept-package-agreements

            Start-Sleep -Seconds 3

        } else {
            Write-Host "❌ winget no disponible. Instala Nmap manualmente." -ForegroundColor Red
        }
    }

    # Validación final de Nmap
    if (-Not (Get-Command nmap -ErrorAction SilentlyContinue)) {

        $nmapPath = "C:\Program Files (x86)\Nmap"

        if (Test-Path $nmapPath) {
            $env:Path += ";$nmapPath"
            Write-Host "✔️ Nmap agregado al PATH en esta sesión" -ForegroundColor Green
        }

        if (Get-Command nmap -ErrorAction SilentlyContinue) {
            Write-Host "✔️ Nmap funcional" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Nmap instalado pero no accesible aún" -ForegroundColor Yellow
        }

    } else {
        Write-Host "✔️ Nmap listo para usar" -ForegroundColor Green
    }

    # -------------------------------
    # FINAL
    # -------------------------------
    Write-Host "`n=========================================" -ForegroundColor Cyan
    Write-Host "   ✅ INSTALACIÓN COMPLETA Y FUNCIONAL   " -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Cyan

}
catch {
    Write-Host "`n❌ ERROR DETECTADO:" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
}
finally {
    Write-Host "`nPresiona cualquier tecla para salir..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}