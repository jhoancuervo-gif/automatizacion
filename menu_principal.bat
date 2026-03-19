@echo off
setlocal
:: Se posiciona en la carpeta donde esta este archivo
cd /d "%~dp0"
title SISTEMA DE AUTOMATIZACION - CUERVO

echo [1/2] Sincronizando con GitHub...
:: Descarga los cambios. Si no hay internet, saltara al siguiente paso.
git pull origin main --quiet

echo [2/2] Iniciando interfaz de PowerShell...
:: Lanza el script de PowerShell actualizado
powershell -ExecutionPolicy Bypass -File "menu_principal.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [!] Hubo un error al iniciar el sistema.
    pause
)