@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Pasta base = a pasta onde este .bat esta salvo (coloque-o dentro de "Projetos em Addamento")
set "BASE=%~dp0..\..\.."
if "%BASE:~-1%"=="\" set "BASE=%BASE:~0,-1%"

echo ============================================
echo   METADADOS DE PROJETO JA EXISTENTE
echo ============================================
echo Pasta base: %BASE%
echo.
set /p "INDICE=Indice do projeto (ex: 261.MRU.BVEUS2, ou so a sigla/numero): "

if not exist "%BASE%" (
    echo.
    echo Nao foi possivel acessar a pasta base: %BASE%
    echo Verifique a conexao com o servidor ou ajuste a variavel BASE no inicio deste script.
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

for %%I in (".") do set "CURFOLDER=%%~nxI"
set "NUM="
set "COD="
set "SIGLA="
for /f "tokens=1-3 delims=." %%a in ("!CURFOLDER!") do (
    set "NUM=%%a"
    set "COD=%%b"
    set "SIGLA=%%c"
)

if not defined SIGLA (
    echo.
    echo Nao foi possivel detectar NUM.COD.SIGLA pelo nome da pasta: !CURFOLDER!
    set /p "NUM=Numero do projeto: "
    set /p "COD=Codigo do cliente: "
    set /p "SIGLA=Sigla do projeto: "
) else (
    echo.
    echo Detectado pelo nome da pasta: Numero=!NUM!  Codigo=!COD!  Sigla=!SIGLA!
)

:: ---------- Recupera dados ja preenchidos, se o _metadata.json ja existir ----------
set "NOME_ATUAL="
set "CLIENTE_ATUAL="
set "LOCAL_ATUAL="
if exist "_metadata.json" (
    for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "try { (Get-Content -Raw '_metadata.json' | ConvertFrom-Json).nome_projeto } catch {}"`) do set "NOME_ATUAL=%%V"
    for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "try { (Get-Content -Raw '_metadata.json' | ConvertFrom-Json).cliente } catch {}"`) do set "CLIENTE_ATUAL=%%V"
    for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "try { (Get-Content -Raw '_metadata.json' | ConvertFrom-Json).localidade } catch {}"`) do set "LOCAL_ATUAL=%%V"
)

echo.
if defined NOME_ATUAL (
    set /p "NOME=Nome do projeto/empreendimento (Enter para manter '!NOME_ATUAL!'): "
    if "!NOME!"=="" set "NOME=!NOME_ATUAL!"
) else (
    set /p "NOME=Nome do projeto/empreendimento: "
)
if defined CLIENTE_ATUAL (
    set /p "CLIENTE=Nome do cliente (Enter para manter '!CLIENTE_ATUAL!'): "
    if "!CLIENTE!"=="" set "CLIENTE=!CLIENTE_ATUAL!"
) else (
    set /p "CLIENTE=Nome do cliente: "
)
if defined LOCAL_ATUAL (
    set /p "LOCAL=Localidade do empreendimento (Enter para manter '!LOCAL_ATUAL!'): "
    if "!LOCAL!"=="" set "LOCAL=!LOCAL_ATUAL!"
) else (
    set /p "LOCAL=Localidade do empreendimento (cidade/UF): "
)

set "SOBRESCREVER=S"
if exist "_metadata.json" (
    echo.
    echo Ja existe um _metadata.json nesta pasta.
    set /p "SOBRESCREVER=Atualizar com os dados acima e re-detectar disciplinas/entregas? (S/N): "
)

if /i "%SOBRESCREVER%"=="S" (
    echo.
    echo Detectando disciplinas e entregas existentes...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\ps1\inicializar_metadata_existente.ps1" -Root "%CD%" -Num "!NUM!" -Cod "!COD!" -Sigla "!SIGLA!" -Nome "!NOME!" -Cliente "!CLIENTE!" -Local "!LOCAL!"
) else (
    echo.
    echo Operacao cancelada, nada foi alterado.
)

popd
pause