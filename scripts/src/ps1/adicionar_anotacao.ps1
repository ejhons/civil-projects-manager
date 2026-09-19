param(
    [Parameter(Mandatory = $true)][string]$Root,
    [string]$Disciplina = "",
    [string]$Revisao = "",
    [string]$Autor = "",
    [Parameter(Mandatory = $true)][string]$Texto
)

$metaPath = Join-Path $Root "_metadata.json"

if (Test-Path $metaPath) {
    try { $meta = Get-Content -LiteralPath $metaPath -Raw | ConvertFrom-Json } catch { $meta = $null }
}
if (-not $meta) {
    $meta = [ordered]@{
        numero = ""; codigo_cliente = ""; sigla = ""; nome_projeto = ""; cliente = ""; localidade = "";
        disciplinas = @(); criado_em = (Get-Date -Format "yyyy-MM-dd HH:mm"); entregas = @(); revisoes = @(); anotacoes = @()
    }
}

$metaHash = [ordered]@{}
foreach ($p in $meta.PSObject.Properties) { $metaHash[$p.Name] = $p.Value }
if (-not $metaHash.Contains("anotacoes")) { $metaHash["anotacoes"] = @() }

$anotacoesAtuais = @()
if ($metaHash["anotacoes"]) { $anotacoesAtuais = @($metaHash["anotacoes"]) }

$novaAnotacao = [ordered]@{
    disciplina = if ($Disciplina) { $Disciplina } else { "GERAL" }
    revisao    = $Revisao
    autor      = $Autor
    texto      = $Texto
    data       = (Get-Date -Format "yyyy-MM-dd HH:mm")
}
$anotacoesAtuais += $novaAnotacao
$metaHash["anotacoes"] = $anotacoesAtuais

$metaHash | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $metaPath -Encoding UTF8

Write-Host "Anotacao registrada em: $metaPath"
Write-Host "  [$($novaAnotacao.disciplina)$(if ($Revisao) { " $Revisao" })] {$Autor}: $Texto"
