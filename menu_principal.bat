@echo off
:: Detecta la carpeta donde se encuentra este archivo y se posiciona en ella
cd /d "%~dp0"
title SISTEMA DE AUTOMATIZACION - CUERVO
powershell -ExecutionPolicy Bypass -File "menu_principal.ps1"
pause