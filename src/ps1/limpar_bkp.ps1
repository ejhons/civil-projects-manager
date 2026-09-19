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

$pastaDesenhos = Join-Path $pastaDisciplina "01.DESENHOS"
$pastaDocumentos = Join-Path $pastaDisciplina "02.DOCUMENTOS"
$bkpDesenhos = Join-Path $pastaDesenhos (Get-PastaBkp)
$bkpDocumentos = Join-Path $pastaDocumentos (Get-PastaBkp)

$itensParaExcluir = @()

# ---------- Dentro de _BKP: manter so as pastas "PROJETO ENTREGUE ..." (definido no config.json) ----------
function ColetarLixoDeBkp($pastaBkp, $rotulo) {
    if (-not (Test-Path $pastaBkp)) { return @() }
    $itens = Get-ChildItem -Path $pastaBkp -Force -ErrorAction SilentlyContinue
    $lixo = $itens | Where-Object { -not (Test-EhBackupDeEntrega $_.Name) }
    foreach ($i in $lixo) {
        Write-Host ("  [$rotulo] " + $(if ($i.PSIsContainer) { "pasta: " } else { "arquivo: " }) + $i.Name)
    }
    return $lixo
}

# ---------- Pastas temporarias _PDF / _PDF RXX (definido no config.json) dentro de 01.DESENHOS ----------
function ColetarPastasPdfTemporarias($pasta) {
    if (-not (Test-Path $pasta)) { return @() }
    $pastasPdf = Get-ChildItem -Path $pasta -Directory -Force -ErrorAction SilentlyContinue |
    Where-Object { Test-EhPastaPdfTemp $_.Name }
    foreach ($p in $pastasPdf) {
        Write-Host "  [01.DESENHOS] pasta temporaria: $($p.Name)"
    }
    return $pastasPdf
}

Write-Host ""
Write-Host "=== $Disciplina ==="
Write-Host "Verificando itens que seriam removidos..."
Write-Host ""

$lixoBkpDesenhos = ColetarLixoDeBkp $bkpDesenhos   "01.DESENHOS\_BKP"
$lixoBkpDocumentos = ColetarLixoDeBkp $bkpDocumentos "02.DOCUMENTOS\_BKP"
$pastasPdfTemp = ColetarPastasPdfTemporarias $pastaDesenhos

$itensParaExcluir = @($lixoBkpDesenhos) + @($lixoBkpDocumentos) + @($pastasPdfTemp)

if (-not $itensParaExcluir -or $itensParaExcluir.Count -eq 0) {
    Write-Host "Nada para limpar em $Disciplina."
    exit 0
}

Write-Host ""
Write-Host "Total de itens a remover: $($itensParaExcluir.Count)"
$confirmacao = Read-Host "Digite SIM para confirmar a exclusao destes itens em $Disciplina (qualquer outra coisa cancela)"

if ($confirmacao -ne "SIM") {
    Write-Host "Cancelado - nada foi removido em $Disciplina."
    exit 0
}

$removidos = 0
foreach ($item in $itensParaExcluir) {
    try {
        Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction Stop
        $removidos++
    }
    catch {
        Write-Host "  ERRO ao remover $($item.FullName): $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "$removidos de $($itensParaExcluir.Count) item(ns) removido(s) em $Disciplina."
