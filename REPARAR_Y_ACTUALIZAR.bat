@echo off
title Reparador de Sincronizacion - Reinel
echo Limpiando cache y forzando actualizacion...
git fetch --all
git reset --hard origin/main
echo.
echo ==========================================
echo    ACTUALIZACION EXITOSA (MODO FORZADO)
echo ==========================================
echo Ya deberias ver la opcion 8. TVBOX.
pause