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
    # DEPENDENCIA.ps1 vive en Herramientas/, asi que la raiz del proyecto es el PADRE.
    # El .venv debe quedar en la raiz (donde system_doctor.ps1 y menu_principal.ps1 lo buscan).
    $ProjectRoot = Split-Path $PSScriptRoot -Parent
    $venvPath = Join-Path $ProjectRoot ".venv"
    $pythonVenv = Join-Path $venvPath "Scripts\python.exe"
    
    # Un venv es VALIDO solo si existe Scripts\python.exe (no basta con la carpeta).
    # Si la carpeta existe pero esta incompleta/danada, se recrea.
    if (-Not (Test-Path $pythonVenv)) {
        if (Test-Path $venvPath) {
            Write-Host "Entorno virtual incompleto o danado. Recreando..." -ForegroundColor Yellow
            Remove-Item $venvPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        Write-Host "Creando entorno virtual en $venvPath..." -ForegroundColor Cyan
        & $pythonCmd -m venv "$venvPath"

        # Verificar que realmente quedo creado
        if (-Not (Test-Path $pythonVenv)) {
            throw "No se pudo crear el entorno virtual en '$venvPath'. Verifique que Python tenga el modulo 'venv' y permisos de escritura en la carpeta del proyecto."
        }
        Write-Host "OK: Entorno virtual creado correctamente." -ForegroundColor Green
    }
    else {
        Write-Host "OK: Entorno virtual ya existe y es valido." -ForegroundColor Green
    }

    # 3. INSTALAR DEPENDENCIAS
    Write-Host "`n[3/6] Instalando dependencias..." -ForegroundColor Yellow
    # requirements.txt vive en la raiz del proyecto (no en Herramientas/).
    $reqFile = Join-Path $ProjectRoot "requirements.txt"
    if (Test-Path $reqFile) {
        Write-Host "Instalando desde requirements.txt..." -ForegroundColor Cyan
        & $pythonVenv -m pip install -r "$reqFile" --quiet
    } else {
        Write-Host "AVISO: No se encontro requirements.txt. Usando lista interna." -ForegroundColor Yellow
        $packages = @("requests", "beautifulsoup4", "asyncssh", "python-dotenv", "selenium")
        foreach ($pkg in $packages) {
            Write-Host "Instalando $pkg..." -ForegroundColor Cyan
            & $pythonVenv -m pip install $pkg --quiet
        }
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
    $errMsg = $_.Exception.Message
    Write-Host "`nERROR DETECTADO:" -ForegroundColor Red
    Write-Host $errMsg -ForegroundColor Red
    # Notificar a Discord (canal de errores), si el helper esta disponible
    $DiscordPS = Join-Path (Split-Path $PSScriptRoot -Parent) "core\discord_notifier.ps1"
    if (Test-Path $DiscordPS) {
        . $DiscordPS
        # Cargar .env si aun no esta en el entorno (cuando se ejecuta fuera del menu)
        if (-not $env:DISCORD_WEBHOOK_ERRORES) {
            $envFile = Join-Path (Split-Path $PSScriptRoot -Parent) ".env"
            if (Test-Path $envFile) {
                Get-Content $envFile | ForEach-Object {
                    if ($_ -match '^\s*([^#][^=]*)\s*=\s*(.*)$') {
                        [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim().Trim('"'), "Process")
                    }
                }
            }
        }
        Send-DiscordError -Script "DEPENDENCIA.ps1 (Instalar Dependencias)" -Message $errMsg
    }
} finally {
    Write-Host "`nPresiona cualquier tecla para salir..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}