@echo off
TITLE Lanzador de Instalador de Dependencias
SET SCRIPT_NAME=DEPENDENCIA.ps1

:: Verificar si se corre como administrador
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Ejecutando con privilegios de Administrador.
) else (
    echo [!] ERROR: Este script requiere permisos de Administrador.
    echo Intentando elevar privilegios...
    powershell -Command "Start-Process '%0' -Verb RunAs"
    exit /b
)

:: Cambiar al directorio donde reside el archivo .bat
cd /d "%~dp0"

:: Verificar si el archivo .ps1 existe
if not exist "%SCRIPT_NAME%" (
    echo [!] ERROR: No se encuentra el archivo %SCRIPT_NAME% en esta carpeta.
    pause
    exit /b
)

echo.
echo Iniciando proceso de instalacion...
echo -----------------------------------------
:: Ejecutar PowerShell saltando la politica de restriccion
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_NAME%"

echo.
echo Proceso finalizado.
pause