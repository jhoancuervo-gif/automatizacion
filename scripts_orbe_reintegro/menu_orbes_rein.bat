@echo off
cls
title SUB-MENU: ORBE REINTEGRO
:inicio
cls
echo ==========================================================
echo           SUB-MENU: ORBE REINTEGRO - CUERVO
echo ==========================================================
echo.
echo  1. EJECUTAR REINTEGRO (Solo Flashear + Abrir Reporte)
echo  2. VERIFICAR MACs EN PORTAL (macs.txt)
echo  3. ELIMINAR MACs DEL PORTAL (macs.txt)
echo.
echo  0. VOLVER AL MENU PRINCIPAL
echo.
echo ==========================================================
set /p "op= Seleccione una opcion: "

if "%op%"=="1" goto flashear
if "%op%"=="2" goto verificar
if "%op%"=="3" goto eliminar
if "%op%"=="0" exit
goto inicio

:flashear
echo.
echo [!] Iniciando proceso de flasheo de Orbes...
python orbe_reintegro.py
echo.
echo [+] Flasheo finalizado. Reporte abierto en Bloc de notas.
pause
goto inicio

:verificar
echo.
echo [!] Consultando portal para equipos en macs.txt...
python verificar_macs_portal.py
:: La pausa ahora la maneja el script de Python automáticamente
goto inicio

:eliminar
echo.
echo [!] Iniciando borrado en portal para equipos en macs.txt...
python eliminar_macs_portal.py
:: La pausa ahora la maneja el script de Python automáticamente
goto inicio