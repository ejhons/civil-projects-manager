@echo off
echo Iniciando instalação...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
pause