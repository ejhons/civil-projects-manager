param(
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][string]$Num,
    [Parameter(Mandatory=$true)][string]$Cod,
    [Parameter(Mandatory=$true)][string]$Sigla,
    [string]$Nome = "",
    [string]$Cliente = "",
    [string]$Local = "",
    [string]$Disciplinas = ""
)

$metaPath = Join-Path $Root "_metadata.json"

$disciplinasArray = @()
if ($Disciplinas -ne "") {
    $disciplinasArray = @($Disciplinas -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
}

if (Test-Path $metaPath) {
    Write-Host "Ja existe um _metadata.json em '$metaPath' - nao foi sobrescrito."
    exit 0
}

$metadata = [ordered]@{
    numero         = $Num
    codigo_cliente = $Cod
    sigla          = $Sigla
    nome_projeto   = $Nome
    cliente        = $Cliente
    localidade     = $Local
    disciplinas    = $disciplinasArray
    criado_em      = (Get-Date -Format "yyyy-MM-dd HH:mm")
    entregas       = @()
}

$metadata | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $metaPath -Encoding UTF8

Write-Host "Metadados criados em: $metaPath"