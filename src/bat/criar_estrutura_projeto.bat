@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: A pasta de projetos e um nivel acima de onde este .bat esta (dentro de .Scripts)
for %%I in ("%~dp0..\..\..") do set "BASE=%%~fI"
pushd "%BASE%"

echo ============================================
echo   CRIACAO DE ESTRUTURA DE PASTAS DE PROJETO
echo ============================================
echo.

set /p NOME=Nome do projeto/empreendimento: 
set /p SIGLA=Sigla do projeto (5 a 6 letras): 
set /p COD=Codigo do cliente/empresa (3 a 4 letras): 
set /p NUM=Numero sequencial do projeto (ex: 001): 
set /p CLIENTE=Nome do cliente: 
set /p LOCAL=Localidade do empreendimento (cidade/UF): 

echo.
echo Quais tipos de projeto serao desenvolvidos?
set /p TER=  Terraplenagem? (S/N): 
set /p DRN=  Drenagem? (S/N): 
set /p SES=  Esgoto? (S/N): 
set /p SAA=  Rede de Agua? (S/N): 

set "ROOT=%NUM%.%COD%.%SIGLA%"

echo.
echo Criando estrutura em: %CD%\%ROOT%
echo.

:: ---------- Monta lista de disciplinas selecionadas ----------
set "DISCIPLINAS="
if /i "%TER%"=="S" set "DISCIPLINAS=%DISCIPLINAS%TER,"
if /i "%DRN%"=="S" set "DISCIPLINAS=%DISCIPLINAS%DRN,"
if /i "%SES%"=="S" set "DISCIPLINAS=%DISCIPLINAS%SES,"
if /i "%SAA%"=="S" set "DISCIPLINAS=%DISCIPLINAS%SAA,"

:: ---------- Cria toda a arvore de pastas a partir do config.json ----------
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\ps1\criar_estrutura.ps1" -Root "%ROOT%" -Sigla "%SIGLA%" -Disciplinas "%DISCIPLINAS%"

:: ---------- Grava metadados do projeto (_metadata.json) ----------
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\ps1\criar_metadata.ps1" -Root "%ROOT%" -Num "%NUM%" -Cod "%COD%" -Sigla "%SIGLA%" -Nome "%NOME%" -Cliente "%CLIENTE%" -Local "%LOCAL%" -Disciplinas "%DISCIPLINAS%"

echo.
echo Estrutura criada com sucesso para o projeto "%NOME%" (%ROOT%)
popd
pause
