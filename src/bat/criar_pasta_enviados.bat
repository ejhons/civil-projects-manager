@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Pasta de projetos = um nivel acima de onde este .bat esta (dentro de .Scripts)
for %%I in ("%~dp0..\..\..") do set "BASE=%%~fI"

echo ============================================
echo   NOVA ENTREGA EM _ENVIADOS
echo ============================================
echo Pasta base: %BASE%
echo.
set /p "INDICE=Indice do projeto (ex: 261.MRU.BVEUS2, ou so a sigla/numero): "

if not exist "%BASE%" (
    echo.
    echo Nao foi possivel acessar a pasta base: %BASE%
    pause
    exit /b 1
)

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

pushd "%PROJDIR%"

:: ---------- SIGLA (detectada pela pasta do projeto encontrada NUM.COD.SIGLA) ----------
for %%I in (".") do set "CURFOLDER=%%~nxI"
set "SIGLA="
for /f "tokens=3 delims=." %%s in ("!CURFOLDER!") do set "SIGLA=%%s"

if not defined SIGLA (
    set /p "SIGLA=Nao foi possivel detectar a sigla pelo nome da pasta. Digite a sigla do projeto: "
) else (
    echo Sigla detectada: !SIGLA!
)

:: ---------- DISCIPLINA ----------
:PEDIR_DISC
set "DISC_INPUT="
set /p "DISC_INPUT=Disciplina (TER, DRN, SAA ou SES): "
set "DISC="
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command ". '%~dp0..\..\config\PastasConfig.ps1'; Resolve-Disciplina '!DISC_INPUT!'"`) do set "DISC=%%V"
if not defined DISC (
    echo Disciplina invalida. Digite TER, DRN, SAA ou SES.
    goto PEDIR_DISC
)

:: ---------- DATA (padrao hoje, formato YYYY.MM.DD) ----------
set "TODAY="
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy.MM.dd"') do set "TODAY=%%i"

if defined TODAY (
    set /p "DATA=Data da entrega (Enter para usar '!TODAY!'): "
    if "!DATA!"=="" set "DATA=!TODAY!"
) else (
    set /p "DATA=Data da entrega (formato YYYY.MM.DD): "
)

:: ---------- REVISAO (sugere a proxima automaticamente) ----------
set "MAXREV=-1"
if exist "_ENVIADOS" (
    for /d %%D in ("_ENVIADOS\!SIGLA! !DISC! *") do (
        set "FOLDERNAME=%%~nxD"
        set "LASTTOKEN="
        for %%A in (!FOLDERNAME!) do set "LASTTOKEN=%%A"
        set "NUMPART=!LASTTOKEN:R=!"
        set "NUMPART=!NUMPART:r=!"
        set /a "NUMVAL=100!NUMPART! %% 100" 2>nul
        if defined NUMVAL if !NUMVAL! gtr !MAXREV! set "MAXREV=!NUMVAL!"
    )
)
set /a "NEXTREV=MAXREV+1"
set "NEXTREVSTR=0!NEXTREV!"
set "NEXTREVSTR=!NEXTREVSTR:~-2!"
set "NEXTREVSTR=R!NEXTREVSTR!"

set /p "REV=Numero da revisao (Enter para usar '!NEXTREVSTR!'): "
if "!REV!"=="" set "REV=!NEXTREVSTR!"
:: normaliza caso o usuario digite so o numero (ex: 5 -> R05)
echo !REV! | findstr /i "^R" >nul
if errorlevel 1 (
    set "REVNUM=0!REV!"
    set "REVNUM=!REVNUM:~-2!"
    set "REV=R!REVNUM!"
) else (
    set "REV=!REV: =!"
)

:: ---------- RESPONSAVEL / OBSERVACOES (para o historico) ----------
set /p "RESP=Quem trabalhou nesta entrega (nome): "
set /p "OBS=Observacoes/decisoes desta revisao (opcional): "

:: ---------- MONTA A PASTA DE ENTREGA ----------
set "NOMEENTREGA="
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command ". '%~dp0..\..\config\PastasConfig.ps1'; Get-NomeEntrega -Sigla '!SIGLA!' -Disciplina '!DISC!' -Data '!DATA!' -Revisao '!REV!'"`) do set "NOMEENTREGA=%%V"
if not defined NOMEENTREGA set "NOMEENTREGA=!SIGLA! !DISC! !DATA! !REV!"
set "ENTREGA=_ENVIADOS\!NOMEENTREGA!"

echo.
echo Criando: !ENTREGA!
echo.

md "!ENTREGA!" 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\ps1\criar_pasta_entrega.ps1" -DestinoBase "!ENTREGA!" -Disciplina "!DISC!"

:: ---------- Registra a entrega no historico (_metadata.json) ----------
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\ps1\registrar_entrega.ps1" -Root "%CD%" -Disciplina "!DISC!" -Data "!DATA!" -Revisao "!REV!" -Responsavel "!RESP!" -Observacoes "!OBS!" -Pasta "!ENTREGA!"

echo.
echo Pasta de entrega criada com sucesso:
echo !ENTREGA!
popd
pause
