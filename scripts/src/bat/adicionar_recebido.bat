@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Pasta de projetos = um nivel acima de onde este .bat esta (dentro de .Scripts)
for %%I in ("%~dp0..\..\..") do set "BASE=%%~fI"

echo ============================================
echo   ADICIONAR RECEBIDO
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

:: ---------- DATA (padrao hoje, formato YYYY.MM.DD) ----------
set "TODAY="
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy.MM.dd"') do set "TODAY=%%i"

if defined TODAY (
    set /p "DATA=Data do recebimento (Enter para usar '!TODAY!'): "
    if "!DATA!"=="" set "DATA=!TODAY!"
) else (
    set /p "DATA=Data do recebimento (formato YYYY.MM.DD): "
)

set /p "IDENT=Identificacao/assunto (ex: TOPOGRAFIA): "
set /p "FONTE=Fonte (ex: EMAIL, CLIENTE, DRIVE): "

set "NOMEPASTA="
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command ". '%~dp0..\..\config\PastasConfig.ps1'; Get-NomeRecebido -Data '!DATA!' -Identificacao '!IDENT!' -Fonte '!FONTE!'"`) do set "NOMEPASTA=%%V"
if not defined NOMEPASTA set "NOMEPASTA=!DATA! - !IDENT! - !FONTE!"
set "DESTINO=!PROJDIR!\_RECEBIDOS\!NOMEPASTA!"

echo.
if exist "!DESTINO!" (
    echo Essa pasta de recebido ja existe - os arquivos serao adicionados a ela:
) else (
    echo Criando pasta de recebido:
)
echo !DESTINO!

md "!DESTINO!" 2>nul

echo.
echo Dica: voce pode arrastar a pasta de origem para esta janela para preencher o caminho.
set /p "ORIGEM=Caminho da pasta de origem com os arquivos a copiar: "

:: remove aspas caso o caminho venha entre aspas (comum ao arrastar arquivos)
set "ORIGEM=!ORIGEM:"=!"

if not exist "!ORIGEM!" (
    echo.
    echo Pasta de origem nao encontrada: !ORIGEM!
    pause
    exit /b 1
)

echo.
echo Copiando arquivos de:
echo   !ORIGEM!
echo para:
echo   !DESTINO!
echo.

robocopy "!ORIGEM!" "!DESTINO!" /E /R:2 /W:2

if errorlevel 8 (
    echo.
    echo Ocorreram erros na copia. Verifique as mensagens acima.
) else (
    echo.
    echo Copia concluida com sucesso.
)

pause
