@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Pasta de projetos = um nivel acima de onde este .bat esta (dentro de .Scripts)
for %%I in ("%~dp0..\..\..") do set "BASE=%%~fI"

echo ============================================
echo   ADICIONAR ANOTACAO DE PROJETO
echo ============================================
echo Pasta base: %BASE%
echo.

if not exist "%BASE%" (
    echo Nao foi possivel acessar a pasta base: %BASE%
    pause
    exit /b 1
)

:: ---------- Localiza o projeto pelo indice ----------
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
echo Disciplina e revisao sao opcionais - deixe em branco para uma anotacao
echo geral do projeto (nao ligada a uma disciplina/revisao especifica).
set /p "DISC_INPUT=Disciplina (TER, DRN, SAA, SES ou em branco): "

set "DISC="
if defined DISC_INPUT (
    for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command ". '%~dp0..\..\config\PastasConfig.ps1'; Resolve-Disciplina '!DISC_INPUT!'"`) do set "DISC=%%V"
    if not defined DISC (
        echo Disciplina nao reconhecida, a anotacao ficara como "geral".
    )
)

set /p "REV=Revisao (ex: R01, ou em branco): "

echo.
set /p "TEXTO=Anotacao: "

if not defined TEXTO (
    echo Nenhuma anotacao informada. Nada foi salvo.
    pause
    exit /b 1
)

set "AUTOR_SUGESTAO=%USERNAME%"
set /p "AUTOR=Autor (Enter para usar '%AUTOR_SUGESTAO%'): "
if not defined AUTOR set "AUTOR=%AUTOR_SUGESTAO%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\ps1\adicionar_anotacao.ps1" -Root "!PROJDIR!" -Disciplina "!DISC!" -Revisao "!REV!" -Autor "!AUTOR!" -Texto "!TEXTO!"

echo.
pause
