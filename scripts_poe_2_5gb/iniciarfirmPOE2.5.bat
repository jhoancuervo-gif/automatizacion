@echo off
cls
title SUB-MENU: GESTION DE SWITCHES POE
:inicio
cls
echo ==========================================================
echo           SUB-MENU: GESTION DE SWITCHES POE
echo ==========================================================
echo.
echo  1. EQUIPO NUEVO PUERTO 1 
echo  2. EQUIPO NUEVO PUERTO 8 
echo  3. CAMBIAR CONFIGURACION PUERTO 8 
echo  4. CAMBIAR CONFIGURACION PUERTO 1
echo.
echo  0. VOLVER AL MENU PRINCIPAL
echo.
echo ==========================================================
set /p "op= Seleccione una opcion: "

if "%op%"=="1" goto puerto1
if "%op%"=="2" goto puerto8nuevo
if "%op%"=="3" goto firmware8
if "%op%"=="4" goto configuracion8
if "%op%"=="0" exit
goto inicio

:puerto1
echo.
echo [!] Iniciando proceso para puerto 1 (Nuevo)...
PowerShell -ExecutionPolicy Bypass -File "poe_25g_MASTER.ps1"
pause
goto inicio

:puerto8nuevo
echo.
echo [!] Iniciando proceso para Puerto 8 (Nuevo)...
PowerShell -ExecutionPolicy Bypass -File "poe2.5puerto8nuevo.ps1"
pause
goto inicio

:firmware8
echo.
echo [!] Iniciando Cambio de Firmware Puerto 8...
PowerShell -ExecutionPolicy Bypass -File "poeport82.5.ps1"
pause
goto inicio

:configuracion8
echo.
echo [!] Iniciando Cambio de Firmware Puerto 8...
PowerShell -ExecutionPolicy Bypass -File "puerto1reintegro.ps1"
pause
goto inicio