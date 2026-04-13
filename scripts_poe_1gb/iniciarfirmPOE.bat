@echo off
cls
title SUB-MENU: GESTION DE SWITCHES POE - CUERVO
:inicio
cls
:: Colores: 0 = Negro, 5 = Púrpura/Magenta (usaremos comandos echo con colores de PowerShell para mayor impacto)
powershell -Command "Write-Host '  +----------------------------------------------------------+' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '           SUB-MENU: GESTION DE SWITCHES POE 1.0 Gb       ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦----------------------------------------------------------¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦                                                          ¦' -ForegroundColor Magenta"

powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  1. EQUIPO NUEVO PUERTO 1        3. CONFIG. PUERTO 1     ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  2. EQUIPO NUEVO PUERTO 8        4. CONFIG. PUERTO 8     ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"

powershell -Command "Write-Host '  ¦                                                          ¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦----------------------------------------------------------¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  [ ?? RED / IP ]                                         ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"

powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  5. CONFIGURAR IP FIJA (192.168.18.2)                    ' -NoNewline -ForegroundColor Cyan; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  6. REVERTIR IP A DHCP (INTERNET)                        ' -NoNewline -ForegroundColor Cyan; Write-Host '¦' -ForegroundColor Magenta"

powershell -Command "Write-Host '  ¦                                                          ¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦----------------------------------------------------------¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  0. ??  VOLVER AL MENU PRINCIPAL                          ' -NoNewline -ForegroundColor Yellow; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  +----------------------------------------------------------+' -ForegroundColor Magenta"
echo.
set /p "op=  >> Seleccione una opcion: "

if "%op%"=="1" goto puerto1
if "%op%"=="2" goto puerto8nuevo
if "%op%"=="3" goto configuracion1
if "%op%"=="4" goto firmware8
if "%op%"=="5" goto configurar_ip
if "%op%"=="6" goto revertir_ip
if "%op%"=="7" goto revertir_ip
if "%op%"=="0" exit
goto inicio

:puerto1
echo.
powershell -Command "Write-Host '  [!] Ejecutando poe.ps1...' -ForegroundColor Cyan"
PowerShell -ExecutionPolicy Bypass -File "%~dp0poe.ps1"
pause
goto inicio

:puerto8nuevo
echo.
powershell -Command "Write-Host '  [!] Ejecutando poe1g8puertonuevo.ps1...' -ForegroundColor Cyan"
PowerShell -ExecutionPolicy Bypass -File "%~dp0poe1g8puertonuevo.ps1"
pause
goto inicio

:firmware8
echo.
powershell -Command "Write-Host '  [!] Ejecutando firmware8.ps1...' -ForegroundColor Cyan"
PowerShell -ExecutionPolicy Bypass -File "%~dp0poeport81G.ps1"
pause
goto inicio

:configuracion1
echo.
powershell -Command "Write-Host '  [!] Ejecutando configuracion1.ps1...' -ForegroundColor Cyan"
PowerShell -ExecutionPolicy Bypass -File "%~dp0poeport1.ps1"
pause
goto inicio

:configurar_ip
echo.
powershell -Command "Write-Host '  [!] Configurando IP estática para auditoría...' -ForegroundColor Green"
PowerShell -ExecutionPolicy Bypass -File "%~dp0Configurar Ip poe.ps1"
pause
goto inicio

:revertir_ip
echo.
powershell -Command "Write-Host '  [!] Restaurando adaptador a modo DHCP...' -ForegroundColor Yellow"
PowerShell -ExecutionPolicy Bypass -File "%~dp0revertir_ip.ps1"
pause
goto inicio