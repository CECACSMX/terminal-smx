@echo off
rem ================================================================
rem  INSTALAR.bat  -  Terminal SMX
rem  Doble clic para personalizar tu terminal de PowerShell.
rem
rem  Por que no usamos "powershell -ExecutionPolicy Bypass -File"?
rem   - Muchos antivirus bloquean esa orden: el malware la usa mucho.
rem   - Windows PowerShell 5.1 leeria mal las tildes del .ps1.
rem  Por eso leemos el .ps1 como texto UTF-8 y lo ejecutamos como
rem  bloque de script. La politica de ejecucion no se aplica a un
rem  bloque creado asi: no es una barrera de seguridad, solo evita
rem  ejecutar scripts por accidente.
rem ================================================================
title Terminal SMX

rem %~dp0 es la carpeta donde esta este .bat
set "SMX_SCRIPT=%~dp0Instalar-Terminal.ps1"

if not exist "%SMX_SCRIPT%" (
    echo No encuentro Instalar-Terminal.ps1 junto a este archivo.
    echo Descomprime la carpeta entera antes de ejecutar.
    pause
    exit /b 1
)

powershell.exe -NoProfile -Command "& ([scriptblock]::Create([IO.File]::ReadAllText($env:SMX_SCRIPT, [Text.Encoding]::UTF8)))"

echo.
pause
