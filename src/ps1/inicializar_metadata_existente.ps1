param(
    [Parameter(Mandatory = $true)][string]$Root,
    [string]$Num = "",
    [string]$Cod = "",
    [string]$Sigla = "",
    [string]$Nome = "",
    [string]$Cliente = "",
    [string]$Local = ""
)

. (Join-Path $PSScriptRoot "..\..\config\PastasConfig.ps1")

$metaPath = Join-Path $Root "_metadata.json"

# ---------- Detecta disciplinas pelas pastas existentes (config.json) ----------
$disciplinasDetectadas = @()
foreach ($prop in $Config.disciplinas.PSObject.Properties) {
    $codigo = $prop.Name
    $pastaRelativa = $prop.Value.pasta
    if (Test-Path (Join-Path $Root $pastaRelativa)) {
        $disciplinasDetectadas += $codigo
    }
}

# ---------- Preserva entregas ja registradas manualmente, se houver ----------
$entregasAnteriores = @{}
if (Test-Path $metaPath) {
    try {
        $anterior = Get-Content -LiteralPath $metaPath -Raw | ConvertFrom-Json
        if ($anterior.entregas) {
            foreach ($e in @($anterior.entregas)) {
                $chave = "$($e.disciplina)|$($e.data)|$($e.revisao)"
                $entregasAnteriores[$chave] = $e
            }
        }
    }
    catch {
        Write-Host "Aviso: nao foi possivel ler o _metadata.json anterior, sera recriado do zero."
    }
}

# ---------- Detecta entregas existentes em _ENVIADOS ----------
$entregas = @()
$enviadosPath = Join-Path $Root "_ENVIADOS"
if (Test-Path $enviadosPath) {
    $pastasEntrega = Get-ChildItem -Path $enviadosPath -Directory
    foreach ($p in $pastasEntrega) {
        $partes = $p.Name -split '\s+'
        if ($partes.Count -ge 4) {
            $discPasta = $partes[1]
            $dataPasta = $partes[2]
            $revPasta = $partes[3]
            $chave = "$discPasta|$dataPasta|$revPasta"

            if ($entregasAnteriores.ContainsKey($chave)) {
                # ja existia (possivelmente com responsavel/observacoes preenchidos) - preserva
                $entregas += $entregasAnteriores[$chave]
            }
            else {
                $entregas += [ordered]@{
                    disciplina    = $discPasta
                    data          = $dataPasta
                    revisao       = $revPasta
                    responsavel   = ""
                    observacoes   = "Importado automaticamente - preencher"
                    pasta         = "_ENVIADOS\$($p.Name)"
                    registrado_em = (Get-Date -Format "yyyy-MM-dd HH:mm")
                }
            }
        }
    }
}

$metadata = [ordered]@{
    numero         = $Num
    codigo_cliente = $Cod
    sigla          = $Sigla
    nome_projeto   = $Nome
    cliente        = $Cliente
    localidade     = $Local
    disciplinas    = $disciplinasDetectadas
    criado_em      = (Get-Date -Format "yyyy-MM-dd HH:mm")
    entregas       = $entregas
}

$metadata | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $metaPath -Encoding UTF8

Write-Host ""
Write-Host "Metadados criados/atualizados em: $metaPath"
Write-Host "Disciplinas detectadas: $($disciplinasDetectadas -join ', ')"
Write-Host "Entregas encontradas em _ENVIADOS: $($entregas.Count)"
Write-Host ""
Write-Host "Os campos 'responsavel' e algumas 'observacoes' podem ter ficado em branco."
Write-Host "Use o editor_metadados.html para preencher sem mexer no arquivo de texto."
