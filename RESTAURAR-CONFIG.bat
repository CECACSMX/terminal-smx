@echo off
rem ================================================================
rem  RESTAURAR-CONFIG.bat  -  Terminal SMX
rem  Deja Windows Terminal como estaba antes de CONFIGURAR.bat.
rem  Se lanza igual que INSTALAR.bat: mira alli por que no usamos
rem  "powershell -ExecutionPolicy Bypass -File".
rem ================================================================
title Terminal SMX - Restaurar

set "SMX_SCRIPT=%~dp0Configurar-Terminal.ps1"

if not exist "%SMX_SCRIPT%" (
    echo No encuentro Configurar-Terminal.ps1 junto a este archivo.
    echo Descomprime la carpeta entera antes de ejecutar.
    pause
    exit /b 1
)

powershell.exe -NoProfile -Command "& ([scriptblock]::Create([IO.File]::ReadAllText($env:SMX_SCRIPT, [Text.Encoding]::UTF8))) -Restaurar"

echo.
pause
