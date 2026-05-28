@echo off
title Reparador de Sincronizacion - Reinel
cd /d "%~dp0"
echo Limpiando cache y forzando actualizacion...
git fetch --all
git reset --hard origin/main
echo.
echo ==========================================
echo    ACTUALIZACION EXITOSA (MODO FORZADO)
echo ==========================================
echo Ya cuentas con el script actualizado.
pause