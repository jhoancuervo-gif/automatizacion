@echo off
cls
title SUB-MENU: GESTION DE SWITCHES POE 2.5G - CUERVO
:inicio
cls
:: Interfaz Profesional con Colores de PowerShell
powershell -Command "Write-Host '  +----------------------------------------------------------+' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '           SUB-MENU: GESTIÓN DE SWITCHES POE 2.5G         ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦----------------------------------------------------------¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦                                                          ¦' -ForegroundColor Magenta"

powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  1. EQUIPO NUEVO PUERTO 1        4. CONFIG. PUERTO 1     ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  2. EQUIPO NUEVO PUERTO 8        3. CONFIG. PUERTO 8     ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"

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
if "%op%"=="3" goto firmware8
if "%op%"=="4" goto configuracion8
if "%op%"=="5" goto configurar_ip
if "%op%"=="6" goto revertir_ip
if "%op%"=="0" exit
goto inicio

:puerto1
echo.
powershell -Command "Write-Host '  [!] Iniciando proceso para puerto 1 (Nuevo)...' -ForegroundColor Cyan"
PowerShell -ExecutionPolicy Bypass -File "%~dp0poe_25g_MASTER.ps1"
pause
goto inicio

:puerto8nuevo
echo.
powershell -Command "Write-Host '  [!] Iniciando proceso para Puerto 8 (Nuevo)...' -ForegroundColor Cyan"
PowerShell -ExecutionPolicy Bypass -File "%~dp0poe2.5puerto8nuevo.ps1"
pause
goto inicio

:firmware8
echo.
powershell -Command "Write-Host '  [!] Iniciando Cambio de Firmware Puerto 8...' -ForegroundColor Cyan"
PowerShell -ExecutionPolicy Bypass -File "%~dp0puerto1reintegro.ps1"
pause
goto inicio

:configuracion8
echo.
powershell -Command "Write-Host '  [!] Iniciando Cambio de Configuración Puerto 1...' -ForegroundColor Cyan"
PowerShell -ExecutionPolicy Bypass -File "%~dp0poeport82.5.ps1"
pause
goto inicio

:configurar_ip
echo.
powershell -Command "Write-Host '  [!] Aplicando IP Estática Definitiva...' -ForegroundColor Green"
PowerShell -ExecutionPolicy Bypass -File "%~dp0Configurar Ip poe.ps1"
pause
goto inicio

:revertir_ip
echo.
powershell -Command "Write-Host '  [!] Restaurando adaptador a modo DHCP...' -ForegroundColor Yellow"
PowerShell -ExecutionPolicy Bypass -File "%~dp0revertir_ip.ps1"
pause
goto inicio