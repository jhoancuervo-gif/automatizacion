@echo off
setlocal
title LIMPIADOR TV BOX - CUERVO
color 0b

:: Obtener la ruta donde esta el BAT
set "SCRIPT_DIR=%~dp0"
set "PS_FILE=%SCRIPT_DIR%configurar_sinapp.ps1"

echo ========================================
echo      ESTACION DE TRABAJO CUERVO
echo ========================================
echo.

:: Ejecutar PowerShell saltando bloqueos de Windows
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_FILE%"

echo.
echo ========================================
echo        PROCESO FINALIZADO
echo ========================================
pause