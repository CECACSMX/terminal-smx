@echo off
rem ================================================================
rem  DESINSTALAR.bat  -  Terminal SMX
rem  Quita el banner y el tema de tu perfil de PowerShell.
rem  Oh My Posh y la fuente se quedan instalados.
rem ================================================================
title Terminal SMX - Desinstalar

set "SMX_SCRIPT=%~dp0Instalar-Terminal.ps1"

if not exist "%SMX_SCRIPT%" (
    echo No encuentro Instalar-Terminal.ps1 junto a este archivo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -Command "& ([scriptblock]::Create([IO.File]::ReadAllText($env:SMX_SCRIPT, [Text.Encoding]::UTF8))) -Desinstalar"

echo.
pause
