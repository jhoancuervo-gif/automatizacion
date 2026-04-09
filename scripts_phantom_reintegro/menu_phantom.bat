@echo off
setlocal enabledelayedexpansion
cls
title MENU PHANTOM REINTEGRO - CUERVO

:menu
cls
:: Interfaz Profesional con Colores de PowerShell
powershell -Command "Write-Host '  +----------------------------------------------------------+' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '             MENU: PHANTOM REINTEGRO                      ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦----------------------------------------------------------¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦                                                          ¦' -ForegroundColor Magenta"

powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  1. REINTEGRO COMPLETO           4. VERIFICAR MACS PORTAL' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  2. REINTEGRO PERSONALIZADO      5. ELIMINAR MACS PORTAL ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  3. PRUEBA DE CONEXION                                   ' -NoNewline -ForegroundColor White; Write-Host '¦' -ForegroundColor Magenta"

powershell -Command "Write-Host '  ¦                                                          ¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦----------------------------------------------------------¦' -ForegroundColor Magenta"
powershell -Command "Write-Host '  ¦' -NoNewline -ForegroundColor Magenta; Write-Host '  0. ??  VOLVER AL MENU PRINCIPAL                         ' -NoNewline -ForegroundColor Yellow; Write-Host '¦' -ForegroundColor Magenta"
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
powershell -Command "Write-Host '  [!] Ejecutando REINTEGRO COMPLETO...' -ForegroundColor Cyan" [cite: 19]
python phantom_reintegro.py [cite: 19]
pause
goto menu

:op2
echo.
powershell -Command "Write-Host '  [!] Ejecutando REINTEGRO PERSONALIZADO...' -ForegroundColor Cyan"
python phantom_reintegro.py
pause
goto menu

:op3
echo.
powershell -Command "Write-Host '  [!] Iniciando PRUEBA DE CONEXIÓN...' -ForegroundColor Cyan"
python phantom_reintegro.py [cite: 20]
pause
goto menu

:op4
echo.
powershell -Command "Write-Host '  --- VERIFICAR MACs PORTAL ---' -ForegroundColor Cyan" [cite: 21]
if exist "..\macs.txt" ( [cite: 21]
    powershell -Command "Write-Host '  [+] Archivo macs.txt encontrado en la raiz' -ForegroundColor Green" [cite: 21]
    set /p "continuar=  >> ¿Continuar? (S/N): " [cite: 21]
    if /i "!continuar!"=="S" ( [cite: 21]
        python verificar_macs_portal.py [cite: 21]
    )
) else (
    powershell -Command "Write-Host '  [-] ERROR: No hay archivo macs.txt en la raiz.' -ForegroundColor Red" [cite: 21]
)
pause
goto menu

:op5
echo.
powershell -Command "Write-Host '  --- ELIMINAR MACs PORTAL ---' -ForegroundColor Red" [cite: 22]
if exist "..\macs.txt" ( [cite: 22]
    python eliminar_macs_portal.py [cite: 22]
) else (
    powershell -Command "Write-Host '  [-] ERROR: No hay archivo macs.txt para eliminar.' -ForegroundColor Red" [cite: 22]
)
pause
goto menu