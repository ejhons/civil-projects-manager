@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: SCRIPTDIR = onde este .bat e seus .ps1 estao (ex: .Scripts)
set "SCRIPTDIR=%~dp0.."
if "%SCRIPTDIR:~-1%"=="\" set "SCRIPTDIR=%SCRIPTDIR:~0,-1%"

:: BASE = pasta de projetos, um nivel acima de .Scripts
for %%I in ("%~dp0..\..\..") do set "BASE=%%~fI"

echo ============================================
echo   CRIAR REVISAO
echo ============================================
echo Pasta base: %BASE%
echo.

if not exist "%BASE%" (
    echo Nao foi possivel acessar a pasta base: %BASE%
    pause
    exit /b 1
)

set /p "INDICE=Indice do projeto (ex: 261.MRU.BVEUS2, ou so a sigla/numero): "

set "COUNT=0"
for /d %%D in ("%BASE%\*%INDICE%*") do (
    set /a COUNT+=1
    set "MATCH!COUNT!=%%~fD"
)

if "%COUNT%"=="0" (
    echo.
    echo Nenhuma pasta encontrada com "%INDICE%" em %BASE%
    pause
    exit /b 1
)

if "%COUNT%"=="1" (
    set "PROJDIR=%MATCH1%"
    echo.
    echo Projeto encontrado: %MATCH1%
) else (
    echo.
    echo Foram encontradas %COUNT% pastas com "%INDICE%":
    for /l %%N in (1,1,%COUNT%) do echo   %%N. !MATCH%%N!
    echo.
    set /p "ESCOLHA=Digite o numero da pasta correta: "
    call set "PROJDIR=%%MATCH%ESCOLHA%%%"
)

if not defined PROJDIR (
    echo Escolha invalida.
    pause
    exit /b 1
)

echo.
echo Dificilmente todas as disciplinas sao revisadas de uma vez -
echo informe uma ou mais, separadas por espaco.
set /p "DISCS=Disciplinas a revisar (TER, DRN, SAA, SES): "

if not defined DISCS (
    echo Nenhuma disciplina informada.
    pause
    exit /b 1
)


for %%D in (%DISCS%) do (
    set "COD="
    for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command ". '%SCRIPTDIR%\..\config\PastasConfig.ps1'; Resolve-Disciplina '%%D'"`) do set "COD=%%V"
    
    if not defined COD (
        echo.
        echo Disciplina invalida, ignorada: %%D
    ) else (
        echo "%COD%"
        echo "%PROJDIR%"
        powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPTDIR%\ps1\criar_revisao.ps1" -Root "!PROJDIR!" -Disciplina "!COD!"
    )
)

echo.
echo Concluido.
pause
