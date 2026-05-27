@echo off
setlocal
cd /d "%~dp0"
title SISTEMA DE AUTOMATIZACION - CUERVO

echo [1/3] Verificando estado del repositorio...

:: Evitar que git se cuelgue esperando credenciales por teclado
set GIT_TERMINAL_PROMPT=0

:: Fetch con limite de velocidad: si la red se estanca (<1KB/s por 8s), cancela y continua
git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=8 fetch origin --quiet
if %errorlevel% neq 0 (
    echo [!] No se pudo contactar GitHub a tiempo. Se omite la sincronizacion.
    goto :SkipSync
)

:: Detectar si existen cambios locales (nuevos, modificados o eliminados)
set _CAMBIOS_LOCALES=0
for /f "tokens=*" %%a in ('git status --porcelain 2^>nul') do set _CAMBIOS_LOCALES=1

if "%_CAMBIOS_LOCALES%"=="1" (
    echo.
    echo [!] Se detectaron cambios locales. Sincronizacion automatica OMITIDA.
    echo     Para actualizar manualmente ejecuta: git pull origin main
    echo.
) else (
    git merge --ff-only origin/main --quiet
    if %errorlevel% equ 0 (
        echo [OK] Repositorio actualizado desde GitHub.
    ) else (
        echo [!] No se pudo actualizar automaticamente. Verifique su conexion.
    )
)
set _CAMBIOS_LOCALES=

:SkipSync

echo [2/3] Ejecutando diagnostico de salud...
powershell -ExecutionPolicy Bypass -File "core\system_doctor.ps1"

echo [3/3] Iniciando interfaz de PowerShell...
powershell -ExecutionPolicy Bypass -File "menu_principal.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [!] Hubo un error al iniciar el sistema.
    pause
)
