param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$Sigla,
    [string]$Disciplinas = ""   # lista separada por virgula, ex: "TERR,DRN"
)

. (Join-Path $PSScriptRoot "..\..\config\PastasConfig.ps1")

$listaDisciplinas = @()
if ($Disciplinas -ne "") {
    $listaDisciplinas = $Disciplinas -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
}

New-EstruturaProjeto -Root $Root -Sigla $Sigla -Disciplinas $listaDisciplinas

Write-Host "Estrutura de pastas criada em: $Root"
Write-Host "Disciplinas: $($listaDisciplinas -join ', ')"
