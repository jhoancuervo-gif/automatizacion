@echo off
cls
title SUB-MENU: PHANTOM NUEVOS - CUERVO
:inicio
cls
:: Interfaz Profesional con Colores de PowerShell
powershell -Command "Write-Host '  +----------------------------------------------------------+' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '               SUB-MENU: PHANTOM NUEVOS - CUERVO          ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦----------------------------------------------------------¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦                                                          ¦' -ForegroundColor Magenta"

powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  1.  EJECUTAR PHANTOM NUEVOS (Flashear + Limpiar Raiz)   ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  2.  VERIFICAR EN PORTAL (macs.txt de raiz)              ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"

powershell -Command "Write-Host '  ¦                                                          ¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦----------------------------------------------------------¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  0.   VOLVER AL MENU PRINCIPAL                           ' -NoNewline -ForegroundColor Yellow; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  +----------------------------------------------------------+' -ForegroundColor Magenta"
echo.
set /p "op=  >> Seleccione una opcion: "

if "%op%"=="1" goto flashear
if "%op%"=="2" goto verificar
if "%op%"=="0" exit
goto inicio

:flashear
echo.
powershell -Command "Write-Host '  [!] Iniciando flasheo de equipo nuevo...' -ForegroundColor Cyan"
python phantom.py
pause
goto inicio

:verificar
echo.
powershell -Command "Write-Host '  [!] Consultando portal (macs.txt en raiz)...' -ForegroundColor Cyan"
python verificar_macs_portal.py
pause
goto inicio