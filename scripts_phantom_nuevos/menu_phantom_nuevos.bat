@echo off
cls
title SUB-MENU: PHANTOM NUEVOS
:inicio
cls
echo ==========================================================
echo           SUB-MENU: PHANTOM NUEVOS - CUERVO
echo ==========================================================
echo.
echo  1. EJECUTAR PHANTOM NUEVOS (Flashear + Limpiar Raiz)
echo  2. VERIFICAR EN PORTAL (macs.txt de raiz)
echo.
echo  0. VOLVER AL MENU PRINCIPAL
echo.
echo ==========================================================
set /p "op= Seleccione una opcion: "

if "%op%"=="1" goto flashear
if "%op%"=="2" goto verificar
if "%op%"=="0" exit
goto inicio

:flashear
echo.
echo [!] Iniciando flasheo de equipo nuevo...
python phantom.py
pause
goto inicio

:verificar
echo.
echo [!] Consultando portal (macs.txt en raiz)...
python verificar_macs_portal.py
pause
goto inicio