@echo off
setlocal
cd /d "%~dp0"
title SISTEMA DE AUTOMATIZACION - CUERVO

echo [1/3] Sincronizando con GitHub...
git pull origin main --quiet

echo [2/3] Ejecutando diagnostico de salud...
powershell -ExecutionPolicy Bypass -File "core\system_doctor.ps1"

echo [3/3] Iniciando interfaz de PowerShell...
powershell -ExecutionPolicy Bypass -File "menu_principal.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [!] Hubo un error al iniciar el sistema.
    pause
)
