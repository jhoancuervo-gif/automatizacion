@echo off
setlocal
cd /d "%~dp0.."
title ENVIAR MEJORAS A GITHUB

echo ===========================================
echo     SOLUCIONES CUERVO - CLOUD SYNC
echo ===========================================
echo.

:: 1. Agrega todos los cambios (scripts nuevos, JSONs corregidos, etc.)
echo [1/3] Preparando archivos para la nube...
git add .

:: 2. Pide tu comentario del dia
echo.
set /p msg="Que cambiaste o mejoraste hoy?: "

:: Si le das Enter sin escribir nada, pone un mensaje por defecto
if "%msg%"=="" set msg="Actualizacion de rutina de los scripts"

:: 3. Registra y sube
echo.
echo [2/3] Registrando cambios localmente...
git commit -m "%msg%"

echo.
echo [3/3] Subiendo a GitHub...
git push origin main

echo.
echo ===========================================
echo [OK] !Listo! Tus cambios ya estan en la nube.
echo Tus companeros los veran al abrir su menu.
echo ===========================================
pause