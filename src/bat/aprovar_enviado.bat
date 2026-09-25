@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Pasta de projetos = um nivel acima de onde este .bat esta (dentro de .Scripts)
for %%I in ("%~dp0..\..\..") do set "BASE=%%~fI"

echo ============================================
echo   APROVAR ENVIADO
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

for %%I in ("!PROJDIR!") do set "CURFOLDER=%%~nxI"
set "SIGLA="
for /f "tokens=3 delims=." %%s in ("!CURFOLDER!") do set "SIGLA=%%s"
if not defined SIGLA set /p "SIGLA=Nao detectei a sigla pelo nome da pasta. Digite a sigla: "

:: ---------- Disciplina (resolvida via config.json) ----------
:PEDIR_DISC
set "DISC_INPUT="
set /p "DISC_INPUT=Disciplina (TER, DRN, SAA ou SES): "
set "COD="
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command ". '%~dp0..\..\config\PastasConfig.ps1'; Resolve-Disciplina '!DISC_INPUT!'"`) do set "COD=%%V"
if not defined COD (
    echo Disciplina invalida. Digite TER, DRN, SAA ou SES.
    goto PEDIR_DISC
)
set "DISCFOLDER="
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command ". '%~dp0..\..\config\PastasConfig.ps1'; Get-PastaDisciplina '!COD!'"`) do set "DISCFOLDER=%%V"

:: ---------- Revisao (sugere pela revisao em aberto no _metadata.json) ----------
set "REV_SUGESTAO="
if exist "!PROJDIR!\_metadata.json" (
    for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "try { $m = Get-Content -Raw '!PROJDIR!\_metadata.json' | ConvertFrom-Json; $r = @($m.revisoes) | Where-Object { $_.disciplina -eq '!COD!' -and [string]::IsNullOrEmpty($_.data_envio) } | Select-Object -Last 1; if ($r) { $r.revisao_nova } } catch {}"`) do set "REV_SUGESTAO=%%V"
)

if defined REV_SUGESTAO (
    set /p "REV=Revisao a aprovar (Enter para usar '!REV_SUGESTAO!'): "
    if "!REV!"=="" set "REV=!REV_SUGESTAO!"
) else (
    set /p "REV=Revisao a aprovar (ex: R01): "
)
set "REV=!REV!"
echo !REV! | findstr /i "^R" >nul
if errorlevel 1 (
    set "REVNUM=0!REV!"
    set "REVNUM=!REVNUM:~-2!"
    set "REV=R!REVNUM!"
)
set "REV=!REV: =!"

echo.
echo Projeto: !SIGLA!   Disciplina: !COD!   Revisao: !REV!
echo.

:: ---------- Localiza a pasta de revisao pendente (prefixo definido no config.json) ----------
set "PREFIXO_PDF="
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command ". '%~dp0..\..\config\PastasConfig.ps1'; Get-PrefixoPdfTemp"`) do set "PREFIXO_PDF=%%V"
if not defined PREFIXO_PDF set "PREFIXO_PDF=_PDF"
set "SRC_PDF=!PROJDIR!\!DISCFOLDER!\01.DESENHOS\!PREFIXO_PDF! !REV!"

if not exist "!SRC_PDF!" (
    echo Nao encontrei a pasta de revisao pendente:
    echo   !SRC_PDF!
    echo Nada para aprovar.
    pause
    exit /b 1
)

:: ---------- Localiza (ou cria) a pasta de destino em _ENVIADOS ----------
set "ECOUNT=0"
if exist "!PROJDIR!\_ENVIADOS" (
    for /d %%D in ("!PROJDIR!\_ENVIADOS\!SIGLA! !COD! * !REV!") do (
        set /a ECOUNT+=1
        set "EMATCH!ECOUNT!=%%~fD"
    )
)

if "!ECOUNT!"=="0" (
    echo.
    echo Nenhuma pasta de entrega encontrada em _ENVIADOS para !SIGLA! !COD! !REV!.
    set "TODAY="
    for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy.MM.dd"') do set "TODAY=%%i"
    if defined TODAY (
        set /p "DATA=Data da entrega para criar a pasta (Enter para usar '!TODAY!'): "
        if "!DATA!"=="" set "DATA=!TODAY!"
    ) else (
        set /p "DATA=Data da entrega para criar a pasta (formato YYYY.MM.DD): "
    )
    set "NOMEENTREGA="
    for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command ". '%~dp0..\..\config\PastasConfig.ps1'; Get-NomeEntrega -Sigla '!SIGLA!' -Disciplina '!COD!' -Data '!DATA!' -Revisao '!REV!'"`) do set "NOMEENTREGA=%%V"
    if not defined NOMEENTREGA set "NOMEENTREGA=!SIGLA! !COD! !DATA! !REV!"
    set "DESTINO=!PROJDIR!\_ENVIADOS\!NOMEENTREGA!"
    md "!DESTINO!" 2>nul
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0criar_pasta_entrega.ps1" -DestinoBase "!DESTINO!" -Disciplina "!COD!"
    echo Pasta criada: !DESTINO!
) else if "!ECOUNT!"=="1" (
    set "DESTINO=!EMATCH1!"
    echo Pasta de entrega encontrada: !DESTINO!
) else (
    echo.
    echo Foram encontradas !ECOUNT! pastas de entrega:
    for /l %%N in (1,1,!ECOUNT!) do echo   %%N. !EMATCH%%N!
    echo.
    set /p "ESCOLHAE=Digite o numero da pasta correta: "
    call set "DESTINO=%%EMATCH%ESCOLHAE%%%"
)

if not defined DESTINO (
    echo Escolha invalida.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   Movendo arquivos aprovados de 01.DESENHOS
echo ============================================

if exist "!SRC_PDF!\PDF" (
    robocopy "!SRC_PDF!\PDF" "!DESTINO!\01.DESENHOS\01.PDF" /R:2 /W:2 >nul
    echo   PDF: movido de _PDF !REV!\PDF
)
if exist "!SRC_PDF!\DWG" (
    robocopy "!SRC_PDF!\DWG" "!DESTINO!\01.DESENHOS\02.DWG" /R:2 /W:2 >nul
    echo   DWG: movido de _PDF !REV!\DWG
)
if exist "!SRC_PDF!\CAD" (
    robocopy "!SRC_PDF!\CAD" "!DESTINO!\01.DESENHOS\02.DWG" /R:2 /W:2 >nul
    echo   CAD: movido de _PDF !REV!\CAD
)
if exist "!SRC_PDF!\C3D" (
    robocopy "!SRC_PDF!\C3D" "!DESTINO!\01.DESENHOS\03.C3D" /R:2 /W:2 >nul
    echo   C3D: movido de _PDF !REV!\C3D
)

echo.
echo ============================================
echo   Copiando documentos (PDF) de 02.DOCUMENTOS
echo ============================================

set "SRC_DOCS=!PROJDIR!\!DISCFOLDER!\02.DOCUMENTOS"
if exist "!SRC_DOCS!" (
    robocopy "!SRC_DOCS!" "!DESTINO!\02.DOCUMENTOS\01.ANEXOS" "*!REV!*.pdf" /R:2 /W:2 >nul
    echo   PDFs de 02.DOCUMENTOS com "!REV!" no nome copiados para 02.DOCUMENTOS\01.ANEXOS
) else (
    echo   Pasta 02.DOCUMENTOS nao encontrada, nada copiado.
)

echo.
echo ============================================
echo   Concluido
echo ============================================
echo Destino: !DESTINO!
echo Os arquivos de 01.DESENHOS foram MOVIDOS de _PDF !REV! para _ENVIADOS.
echo Os documentos de 02.DOCUMENTOS foram apenas COPIADOS (originais preservados).
pause
