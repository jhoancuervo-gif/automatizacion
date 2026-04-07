@echo off
cls
title SUB-MENU: GESTION DE SWITCHES POE 2.5G - CUERVO
:inicio
cls
echo ==========================================================
echo           SUB-MENU: GESTION DE SWITCHES POE 2.5G
echo ==========================================================
echo.
echo  1. EQUIPO NUEVO PUERTO 1 
echo  2. EQUIPO NUEVO PUERTO 8 
echo  3. CAMBIAR CONFIGURACION PUERTO 8 
echo  4. CAMBIAR CONFIGURACION PUERTO 1
echo ----------------------------------------------------------
echo  5. CONFIGURAR IP FIJA (192.168.18.2)
echo  6. REVERTIR IP A DHCP (INTERNET)
echo.
echo  0. VOLVER AL MENU PRINCIPAL
echo.
echo ==========================================================
set /p "op= Seleccione una opcion: "

if "%op%"=="1" goto puerto1
if "%op%"=="2" goto puerto8nuevo
if "%op%"=="3" goto firmware8
if "%op%"=="4" goto configuracion8
if "%op%"=="5" goto configurar_ip
if "%op%"=="6" goto revertir_ip
if "%op%"=="0" exit
goto inicio

:puerto1
echo.
echo [!] Iniciando proceso para puerto 1 (Nuevo)...
PowerShell -ExecutionPolicy Bypass -File "%~dp0poe_25g_MASTER.ps1"
pause
goto inicio

:puerto8nuevo
echo.
echo [!] Iniciando proceso para Puerto 8 (Nuevo)...
PowerShell -ExecutionPolicy Bypass -File "%~dp0poe2.5puerto8nuevo.ps1"
pause
goto inicio

:firmware8
echo.
echo [!] Iniciando Cambio de Firmware Puerto 8...
PowerShell -ExecutionPolicy Bypass -File "%~dp0firmware2.5_8.ps1"
pause
goto inicio

:configuracion8
echo.
echo [!] Iniciando Cambio de Configuracion Puerto 1...
PowerShell -ExecutionPolicy Bypass -File "%~dp0configuracion2.5_1.ps1"
pause
goto inicio

:configurar_ip
echo.
echo [!] Aplicando IP Estatica Definitiva...
:: Asegúrate de que el nombre del archivo coincida con el que guardaste
PowerShell -ExecutionPolicy Bypass -File "%~dp0Configurar Ip poe.ps1"
pause
goto inicio

:revertir_ip
echo.
echo [!] Restaurando adaptador a modo DHCP...
PowerShell -ExecutionPolicy Bypass -File "%~dp0revertir_ip.ps1"
pause
goto inicio