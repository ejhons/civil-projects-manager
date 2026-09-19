param(
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][string]$Disciplina,
    [Parameter(Mandatory=$true)][string]$Data,
    [Parameter(Mandatory=$true)][string]$Revisao,
    [string]$Responsavel = "",
    [string]$Observacoes = "",
    [string]$Pasta = ""
)

$metaPath = Join-Path $Root "_metadata.json"

if (Test-Path $metaPath) {
    $metadata = Get-Content -LiteralPath $metaPath -Raw | ConvertFrom-Json
} else {
    Write-Host "Nenhum _metadata.json encontrado em '$Root' - criando um novo com dados minimos."
    $metadata = [ordered]@{
        numero         = ""
        codigo_cliente = ""
        sigla          = ""
        nome_projeto   = ""
        cliente        = ""
        localidade     = ""
        disciplinas    = @()
        criado_em      = (Get-Date -Format "yyyy-MM-dd HH:mm")
        entregas       = @()
    }
}

$novaEntrega = [ordered]@{
    disciplina    = $Disciplina
    data          = $Data
    revisao       = $Revisao
    responsavel   = $Responsavel
    observacoes   = $Observacoes
    pasta         = $Pasta
    registrado_em = (Get-Date -Format "yyyy-MM-dd HH:mm")
}

# ConvertFrom-Json pode devolver um objeto unico (nao array) se so havia 1 entrega - normaliza
$entregasAtuais = @()
if ($metadata.entregas) { $entregasAtuais = @($metadata.entregas) }
$entregasAtuais += $novaEntrega

# PSCustomObject nao aceita atribuicao direta de propriedade com "="; usa Add-Member/forca hashtable
$metadataHash = [ordered]@{}
foreach ($prop in $metadata.PSObject.Properties) {
    $metadataHash[$prop.Name] = $prop.Value
}
$metadataHash["entregas"] = $entregasAtuais

# ---------- Fecha a revisao correspondente (data_envio), se houver uma em aberto ----------
if ($metadataHash.Contains("revisoes") -and $metadataHash["revisoes"]) {
    $revisoes = @($metadataHash["revisoes"])
    $revisaoAberta = $revisoes | Where-Object {
        $_.disciplina -eq $Disciplina -and $_.revisao_nova -eq $Revisao -and [string]::IsNullOrEmpty($_.data_envio)
    } | Select-Object -First 1

    if ($revisaoAberta) {
        $revisaoAberta.data_envio = (Get-Date -Format "yyyy-MM-dd HH:mm")
        $metadataHash["revisoes"] = $revisoes
        Write-Host "Revisao $Disciplina $Revisao fechada (data_envio preenchida)."
    }
}

$metadataHash | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $metaPath -Encoding UTF8

Write-Host "Entrega registrada em: $metaPath"
Write-Host "  Disciplina: $Disciplina | Data: $Data | Revisao: $Revisao | Responsavel: $Responsavel"
