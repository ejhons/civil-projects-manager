param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$Disciplina
)

. (Join-Path $PSScriptRoot "..\..\config\PastasConfig.ps1")

$pastaRelativa = Get-PastaDisciplina $Disciplina
if (-not $pastaRelativa) {
    Write-Host "Disciplina invalida: $Disciplina"
    exit 1
}

$pastaDisciplina = Join-Path $Root $pastaRelativa
if (-not (Test-Path $pastaDisciplina)) {
    Write-Host "Pasta da disciplina nao encontrada: $pastaDisciplina"
    exit 1
}

$extensoes = Get-ExtensoesRevisao
$pastaDesenhos = Join-Path $pastaDisciplina "01.DESENHOS"
$pastaDocumentos = Join-Path $pastaDisciplina "02.DOCUMENTOS"
$metaPath = Join-Path $Root "_metadata.json"

# ---------- Sugestao de revisao atual (metadados + nomes de arquivo) ----------
function ObterMaxRevisaoArquivos($pasta) {
    if (-not (Test-Path $pasta)) { return $null }
    $arquivos = Get-ChildItem -Path $pasta -File -ErrorAction SilentlyContinue |
    Where-Object { $extensoes -contains $_.Extension.ToLower() }
    $max = -1
    foreach ($a in $arquivos) {
        if ($a.BaseName -match '(?i)-R(\d{2})') {
            $n = [int]$Matches[1]
            if ($n -gt $max) { $max = $n }
        }
    }
    if ($max -ge 0) { return $max } else { return $null }
}

$revArqDesenhos = ObterMaxRevisaoArquivos $pastaDesenhos
$revArqDocumentos = ObterMaxRevisaoArquivos $pastaDocumentos
# $revArquivos = @($revArqDesenhos, $revArqDocumentos) | Where-Object { $_ -ne $null } |
# Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
$revArquivos = $null
$arrayValidos = @($revArqDesenhos, $revArqDocumentos) | Where-Object { $_ -ne $null }
if ($arrayValidos) {
    $revArquivos = [int]($arrayValidos | Measure-Object -Maximum).Maximum
}


Write-Host ("  Ultima revisao no _metadata.json: R{0}" -f $revArqDesenhos)
Write-Host ("  Ultima revisao no _metadata.json: R{0}" -f $revArqDocumentos)

$revMeta = $null
if (Test-Path $metaPath) {
    try {
        $meta = Get-Content -LiteralPath $metaPath -Raw | ConvertFrom-Json
        if ($meta.entregas) {
            $nums = @($meta.entregas) | Where-Object { $_.disciplina -eq $Disciplina } | ForEach-Object {
                if ($_.revisao -match '(?i)R(\d{2})') { [int]$Matches[1] }
            }
            if ($nums) { $revMeta = [int]($nums | Measure-Object -Maximum).Maximum }
        }
    }
    catch { }
}

Write-Host ""
Write-Host "=== $Disciplina ==="
if ($null -ne $revMeta) { Write-Host ("  Ultima revisao no _metadata.json: R{0:D2}" -f $revMeta) }
if ($null -ne $revArquivos) { Write-Host ("  Maior revisao encontrada nos arquivos: R{0:D2}" -f $revArquivos) }
if ($null -eq $revMeta -and $null -eq $revArquivos) {
    Write-Host "  Nenhuma revisao anterior encontrada (nem nos metadados, nem nos arquivos)."
}

$sugestao = $null
$candidatos = @($revMeta, $revArquivos) | Where-Object { $_ -ne $null }
if ($candidatos) { $sugestao = [int]($candidatos | Measure-Object -Maximum).Maximum }
$sugestaoTexto = if ($null -ne $sugestao) { "R{0:D2}" -f $sugestao } else { "" }

$prompt = if ($sugestaoTexto -ne "") {
    "Qual a revisao ATUAL de $Disciplina (a que sera arquivada)? [Enter = $sugestaoTexto]"
}
else {
    "Qual a revisao ATUAL de $Disciplina (ex: R00)?"
}
$entrada = Read-Host $prompt
if ([string]::IsNullOrWhiteSpace($entrada)) { $entrada = $sugestaoTexto }
$entrada = $entrada.Trim().ToUpper()

if ($entrada -notmatch '^R(\d{2})$') {
    Write-Host "Revisao invalida ou nao informada para $Disciplina. Pulando esta disciplina."
    exit 1
}
$numAtual = [int]$Matches[1]
$numNova = $numAtual + 1
$revAtualStr = "R{0:D2}" -f $numAtual
$revNovaStr = "R{0:D2}" -f $numNova

Write-Host "Revisao atual: $revAtualStr  ->  Nova revisao: $revNovaStr"
Write-Host ""

# ---------- Backup + renomeacao ----------
function ProcessarPasta($pastaOrigem, $rotulo) {
    if (-not (Test-Path $pastaOrigem)) {
        Write-Host "  ($rotulo nao encontrada, pulando: $pastaOrigem)"
        return
    }

    $arquivos = Get-ChildItem -Path $pastaOrigem -File -ErrorAction SilentlyContinue |
    Where-Object { $extensoes -contains $_.Extension.ToLower() }

    if (-not $arquivos) {
        Write-Host "  Nenhum arquivo dwg/xlsx/imagem encontrado em $rotulo."
        return
    }

    $bkpDestino = Join-Path (Join-Path $pastaOrigem (Get-PastaBkp)) (Get-NomeBackupRevisao $revAtualStr)
    New-Item -ItemType Directory -Path $bkpDestino -Force | Out-Null

    foreach ($a in $arquivos) {
        Copy-Item -LiteralPath $a.FullName -Destination (Join-Path $bkpDestino $a.Name) -Force
    }
    Write-Host "  [$rotulo] Backup de $($arquivos.Count) arquivo(s) em: $bkpDestino"

    $padraoAtual = "-$revAtualStr"
    $renomeados = 0

    
    Write-Host ""    
    $confirmacao = Read-Host "Digite SIM para renomear os arquivos indicados com a revisão $padraoAtual (qualquer outra coisa cancela)"


    if ($confirmacao -ne "SIM") {
        Write-Host "Cancelado - Arquivos na pasta não foram renomeados."
        return
    }

    foreach ($a in $arquivos) {
        if ($a.Name -match [regex]::Escape($padraoAtual)) {
            $novoNome = [regex]::Replace($a.Name, [regex]::Escape($padraoAtual), "-$revNovaStr", 'IgnoreCase')
            $novoCaminho = Join-Path $pastaOrigem $novoNome
            if (Test-Path $novoCaminho) {
                Write-Host "  AVISO: ja existe '$novoNome' - nao renomeei '$($a.Name)'"
            }
            else {
                Rename-Item -LiteralPath $a.FullName -NewName $novoNome
                $renomeados++
            }
        }
    }
    Write-Host "  [$rotulo] Renomeados $renomeados arquivo(s) para -$revNovaStr"
}

ProcessarPasta $pastaDesenhos   "01.DESENHOS"
ProcessarPasta $pastaDocumentos "02.DOCUMENTOS"

# ---------- Registra o inicio da revisao no _metadata.json ----------
if (Test-Path $metaPath) {
    try { $meta = Get-Content -LiteralPath $metaPath -Raw | ConvertFrom-Json } catch { $meta = $null }
}
if (-not $meta) {
    $meta = [ordered]@{
        numero = ""; codigo_cliente = ""; sigla = ""; nome_projeto = ""; cliente = ""; localidade = "";
        disciplinas = @(); criado_em = (Get-Date -Format "yyyy-MM-dd HH:mm"); entregas = @(); revisoes = @()
    }
}

$metaHash = [ordered]@{}
foreach ($p in $meta.PSObject.Properties) { $metaHash[$p.Name] = $p.Value }
if (-not $metaHash.Contains("revisoes")) { $metaHash["revisoes"] = @() }

$revisoesAtuais = @()
if ($metaHash["revisoes"]) { $revisoesAtuais = @($metaHash["revisoes"]) }

$revisoesAtuais += [ordered]@{
    disciplina       = $Disciplina
    revisao_anterior = $revAtualStr
    revisao_nova     = $revNovaStr
    data_inicio      = (Get-Date -Format "yyyy-MM-dd HH:mm")
    data_envio       = $null
}
$metaHash["revisoes"] = $revisoesAtuais

$metaHash | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $metaPath -Encoding UTF8

Write-Host ""
Write-Host "Revisao registrada no _metadata.json: $Disciplina $revAtualStr -> $revNovaStr (inicio agora, envio em aberto)"
