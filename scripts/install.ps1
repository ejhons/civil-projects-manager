# Define os caminhos principais baseados no local de execução do script
$pastaProjeto = $PSScriptRoot
$caminhoBat = "$pastaProjeto\main.bat"
$caminhoIcone = "$pastaProjeto\assets\icons\favicon.ico" 

# --- 1. CRIAR ATALHO NA ÝREA DE TRABALHO ---
$caminhoDesktop = [Environment]::GetFolderPath("Desktop")
$caminhoAtalho = "$caminhoDesktop\Gerenciador de Projetos.lnk"

# Usa o objeto WScript.Shell do Windows para criar o atalho
$wshShell = New-Object -ComObject WScript.Shell
$atalho = $wshShell.CreateShortcut($caminhoAtalho)

$atalho.TargetPath = $caminhoBat
$atalho.WorkingDirectory = $pastaProjeto
$atalho.IconLocation = $caminhoIcone
$atalho.Save()

Write-Host "Atalho criado na Area de Trabalho com sucesso!" -ForegroundColor Green

# --- 2. ADICIONAR ÀS VARIÝVEIS DE AMBIENTE (PATH) ---
# Pega a variável Path atual do Usuário
$pathAtual = [Environment]::GetEnvironmentVariable("Path", "User")

# Verifica se a pasta do projeto já está no Path para evitar duplicação
if ($pathAtual -notlike "*$pastaProjeto*") {
    # Adiciona a pasta ao final do Path atual
    $novoPath = $pathAtual + ";" + $pastaProjeto
    [Environment]::SetEnvironmentVariable("Path", $novoPath, "User")
    
    Write-Host "Pasta do projeto adicionada ao PATH do usuário!" -ForegroundColor Green
    Write-Host "Agora você pode digitar 'pmng' de qualquer lugar no terminal." -ForegroundColor Yellow
}
else {
    Write-Host "A pasta do projeto já estava nas variáveis de ambiente." -ForegroundColor Cyan
}

Write-Host "`nInstalação concluída! Talvez seja necessário fechar e abrir os terminais atuais para o novo PATH funcionar."