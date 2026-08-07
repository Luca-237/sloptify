@echo off
REM Wrapper para ejecutar el script de PowerShell
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0start.ps1"
pause
