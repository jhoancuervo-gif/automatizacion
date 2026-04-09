@echo off
setlocal enabledelayedexpansion
cls
title MENU PHANTOM REINTEGRO

:menu
cls
echo ============================
echo   MENU PHANTOM REINTEGRO
echo ============================
echo   1. REINTEGRO COMPLETO
echo   2. REINTEGRO PERSONALIZADO
echo   3. PRUEBA DE CONEXION
echo   4. VERIFICAR MACs PORTAL
echo   5. ELIMINAR MACs PORTAL
echo   6. VOLVER AL MENU PRINCIPAL
echo ============================
echo.
set /p "opcion=Seleccione: "

if "%opcion%"=="1" goto op1
if "%opcion%"=="2" goto op2
if "%opcion%"=="3" goto op3
if "%opcion%"=="4" goto op4
if "%opcion%"=="5" goto op5
if "%opcion%"=="6" goto :eof

echo Opcion no valida
pause
goto menu

:op1
echo.
echo REINTEGRO COMPLETO (212-215)
echo.
python Phantomsf2Rein.py
pause
goto menu

:op2
echo.
echo REINTEGRO PERSONALIZADO
echo.
python Phantomsf2Rein.py
pause
goto menu

:op3
echo.
echo PRUEBA DE CONEXION
echo.
python Phantomsf2Rein.py
pause
goto menu

:op4
cls
echo ============================
echo   VERIFICAR MACs PORTAL
echo ============================
echo.
if exist "..\macs.txt" (
    echo Archivo macs.txt encontrado en la raiz
    echo.
    set /p "continuar=Continuar? (S/N): "
    if /i "!continuar!"=="S" (
        python verificar_macs_portal.py
    )
) else (
    echo No hay archivo macs.txt en la raiz de automatizacion.
    echo Ejecute primero un proceso para capturar MACs.
)
pause
goto menu

:op5
cls
echo ============================
echo   ELIMINAR MACs PORTAL
echo ============================
echo.
if exist "..\macs.txt" (
    python eliminar_macs_portal.py
) else (
    echo No hay archivo macs.txt en la raiz de automatizacion.
)
pause
goto menu