@echo off
setlocal enabledelayedexpansion
cls
title MENU PHANTOM F2 REINTEGRO - CUERVO

:menu
cls
:: Interfaz Profesional con Colores de PowerShell
powershell -Command "Write-Host '  +----------------------------------------------------------+' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '            MENU: PHANTOM F2 REINTEGRO (212-215)          ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦----------------------------------------------------------¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦                                                          ¦' -ForegroundColor Magenta"

powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  1. REINTEGRO COMPLETO           4. VERIFICAR MACS PORTAL' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  2. REINTEGRO PERSONALIZADO      5. ELIMINAR MACS PORTAL ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  3. PRUEBA DE CONEXIÓN                                   ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"

powershell -Command "Write-Host '  ¦                                                          ¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦----------------------------------------------------------¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  0.   VOLVER AL MENU PRINCIPAL                           ' -NoNewline -ForegroundColor Yellow; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  +----------------------------------------------------------+' -ForegroundColor Magenta"
echo.
set /p "opcion=  >> Seleccione una opcion: "

if "%opcion%"=="1" goto op1
if "%opcion%"=="2" goto op2
if "%opcion%"=="3" goto op3
if "%opcion%"=="4" goto op4
if "%opcion%"=="5" goto op5
if "%opcion%"=="0" exit
goto menu

:op1
echo.
powershell -Command "Write-Host '  [!] Ejecutando REINTEGRO F2 COMPLETO...' -ForegroundColor Cyan"
python Phantomsf2Rein.py
pause
goto menu

:op2
echo.
powershell -Command "Write-Host '  [!] Ejecutando REINTEGRO F2 PERSONALIZADO...' -ForegroundColor Cyan"
python Phantomsf2Rein.py
pause
goto menu

:op3
echo.
powershell -Command "Write-Host '  [!] Iniciando PRUEBA DE CONEXIÓN F2...' -ForegroundColor Cyan"
python Phantomsf2Rein.py
pause
goto menu

:op4
echo.
powershell -Command "Write-Host '  --- VERIFICAR MACs PORTAL (F2) ---' -ForegroundColor Cyan"
if exist "..\macs.txt" (
    powershell -Command "Write-Host '  [+] Archivo macs.txt encontrado' -ForegroundColor Green"
    set /p "continuar=  >> ¿Continuar? (S/N): "
    if /i "!continuar!"=="S" (
        python verificar_macs_portal.py
    )
) else (
    powershell -Command "Write-Host '  [-] ERROR: No hay macs.txt en la raiz.' -ForegroundColor Red"
)
pause
goto menu

:op5
echo.
powershell -Command "Write-Host '  --- ELIMINAR MACs PORTAL (F2) ---' -ForegroundColor Red"
if exist "..\macs.txt" (
    python eliminar_macs_portal.py
) else (
    powershell -Command "Write-Host '  [-] ERROR: No hay archivo macs.txt para eliminar.' -ForegroundColor Red"
)
pause
goto menu