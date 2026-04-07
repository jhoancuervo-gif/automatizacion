@echo off
cls
title SUB-MENU: GESTION DE SWITCHES POE - CUERVO
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
if "%op%"=="4" goto configuracion1
if "%op%"=="5" goto configurar_ip
if "%op%"=="6" goto revertir_ip
if "%op%"=="0" exit
goto inicio

:puerto1
echo.
echo [!] Ejecutando poe.ps1...
PowerShell -ExecutionPolicy Bypass -File "%~dp0poe.ps1"
pause
goto inicio

:puerto8nuevo
echo.
echo [!] Ejecutando poe1g8puertonuevo.ps1...
PowerShell -ExecutionPolicy Bypass -File "%~dp0poe1g8puertonuevo.ps1"
pause
goto inicio

:firmware8
echo.
echo [!] Ejecutando firmware8.ps1...
PowerShell -ExecutionPolicy Bypass -File "%~dp0firmware8.ps1"
pause
goto inicio

:configuracion1
echo.
echo [!] Ejecutando configuracion1.ps1...
PowerShell -ExecutionPolicy Bypass -File "%~dp0configuracion1.ps1"
pause
goto inicio

:configurar_ip
echo.
echo [!] Configurando IP estatica para auditoria...
:: Llama al script que me pasaste
PowerShell -ExecutionPolicy Bypass -File "%~dp0Configurar Ip poe.ps1"
pause
goto inicio

:revertir_ip
echo.
echo [!] Restaurando adaptador a modo DHCP...
:: Llama al nuevo script de reversion
PowerShell -ExecutionPolicy Bypass -File "%~dp0revertir_ip.ps1"
pause
goto inicio