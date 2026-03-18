@echo off
cls
title SUB-MENU: ORBES NUEVAS
:inicio
cls
echo ==========================================================
echo           SUB-MENU: ORBES NUEVAS - CUERVO
echo ==========================================================
echo.
echo  1. EJECUTAR ORBES NUEVAS (Flashear Automatico)
echo  2. VERIFICAR EN PORTAL (macs.txt de raiz)
echo.
echo  0. VOLVER AL MENU PRINCIPAL
echo.
echo ==========================================================
set /p "op= Seleccione una opcion: "

if "%op%"=="1" goto flashear
if "%op%"=="2" goto verificar
if "%op%"=="0" exit /b
goto inicio

:flashear
python orbe.py
pause
goto inicio

:verificar
python verificar_macs_portal.py
pause
goto inicio