param(
    [Parameter(Mandatory = $true)][string]$DestinoBase,
    [Parameter(Mandatory = $true)][string]$Disciplina
)

. (Join-Path $PSScriptRoot "..\..\config\PastasConfig.ps1")

New-EstruturaEntrega -DestinoBase $DestinoBase -Codigo $Disciplina

Write-Host "Estrutura de entrega criada em: $DestinoBase"
