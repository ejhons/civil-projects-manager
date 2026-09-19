@echo off
chcp 65001 >nul
title Painel de Projetos
setlocal enabledelayedexpansion

set "BASE=%~dp0"
if "%BASE:~-1%"=="\" set "BASE=%BASE:~0,-1%"

:MENU
cls
echo ================================================
echo               PAINEL DE PROJETOS
echo ================================================
echo   Pasta base: %BASE%
echo.
echo   1. Criar novo projeto
echo   2. Criar entrega em _ENVIADOS
echo   3. Adicionar recebido em _RECEBIDOS
echo   4. Criar revisao (backup + incremento -RXX)
echo   5. Aprovar enviado (_PDF RXX -^> _ENVIADOS)
echo   6. Limpar _BKP e pastas temporarias (_PDF)
echo   7. Adicionar anotacao de projeto
echo   8. Gerar/atualizar metadados de projeto existente
echo   9. Abrir editor de metadados (formulario)
echo   10. Abrir overview de todos os projetos
echo   0. Sair
echo.
set /p "OPCAO=Escolha uma opcao: "

if "%OPCAO%"=="1" (
    call :RODAR "src\bat\criar_estrutura_projeto.bat"
    goto MENU
)
if "%OPCAO%"=="2" (
    call :RODAR "src\bat\criar_pasta_enviados.bat"
    goto MENU
)
if "%OPCAO%"=="3" (
    call :RODAR "src\bat\adicionar_recebido.bat"
    goto MENU
)
if "%OPCAO%"=="4" (
    call :RODAR "src\bat\criar_revisao.bat"
    goto MENU
)
if "%OPCAO%"=="5" (
    call :RODAR "src\bat\aprovar_enviado.bat"
    goto MENU
)
if "%OPCAO%"=="6" (
    call :RODAR "src\bat\limpar_bkp.bat"
    goto MENU
)
if "%OPCAO%"=="7" (
    call :RODAR "src\bat\adicionar_anotacao.bat"
    goto MENU
)
if "%OPCAO%"=="8" (
    call :RODAR "src\bat\criar_metadata_retroativo.bat"
    goto MENU
)
if "%OPCAO%"=="9" (
    call :ABRIR "views\editor_metadados.html"
    goto MENU
)
if "%OPCAO%"=="10" (
    call :ABRIR "views\overview_projetos.html"
    goto MENU
)
if "%OPCAO%"=="0" exit /b 0

echo.
echo Opcao invalida.
pause
goto MENU

:RODAR
if not exist "%BASE%\%~1" (
    echo.
    echo Arquivo nao encontrado: %BASE%\%~1
    pause
    exit /b 1
)
call "%BASE%\%~1"
exit /b 0

:ABRIR
if not exist "%BASE%\%~1" (
    echo.
    echo Arquivo nao encontrado: %BASE%\%~1
    pause
    exit /b 1
)
start "" "%BASE%\%~1"
exit /b 0
