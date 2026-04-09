@echo off
cls
title SUB-MENU: ORBE REINTEGRO - CUERVO
:inicio
cls
:: Interfaz Profesional con Colores de PowerShell
powershell -Command "Write-Host '  +----------------------------------------------------------+' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '               SUB-MENU: ORBE REINTEGRO - CUERVO          ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦----------------------------------------------------------¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦                                                          ¦' -ForegroundColor Magenta"

powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  1. ?? EJECUTAR REINTEGRO (Flashear + Reporte)           ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  2. ?? VERIFICAR EN PORTAL (macs.txt)                    ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  3. ? ELIMINAR DEL PORTAL (macs.txt)                     ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"

powershell -Command "Write-Host '  ¦                                                          ¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦----------------------------------------------------------¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  0. ??  VOLVER AL MENU PRINCIPAL                          ' -NoNewline -ForegroundColor Yellow; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  +----------------------------------------------------------+' -ForegroundColor Magenta"
echo.
set /p "op=  >> Seleccione una opción: "

if "%op%"=="1" goto flashear
if "%op%"=="2" goto verificar
if "%op%"=="3" goto eliminar
if "%op%"=="0" exit
goto inicio

:flashear
echo.
powershell -Command "Write-Host '  [!] Iniciando proceso de flasheo de Orbes...' -ForegroundColor Cyan"
python orbe_reintegro.py
echo.
powershell -Command "Write-Host '  [+] Flasheo finalizado. Reporte abierto en Bloc de notas.' -ForegroundColor Green"
pause
goto inicio

:verificar
echo.
powershell -Command "Write-Host '  [!] Consultando portal para equipos en macs.txt...' -ForegroundColor Cyan"
python verificar_macs_portal.py
:: La pausa la maneja el script de Python según tu código original
goto inicio

:eliminar
echo.
powershell -Command "Write-Host '  [!] Iniciando borrado en portal para equipos en macs.txt...' -ForegroundColor Red"
python eliminar_macs_portal.py
pause
goto inicio