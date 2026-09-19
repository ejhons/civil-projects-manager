# PastasConfig.ps1
# Carregado por dot-source nos outros scripts: . "$PSScriptRoot\PastasConfig.ps1"
# Centraliza tudo que hoje seria "hardcoded": nomes de pasta, formatos e listas.

$script:CaminhoConfig = Join-Path $PSScriptRoot "config.json"

if (-not (Test-Path $script:CaminhoConfig)) {
    throw "config.json nao encontrado em: $script:CaminhoConfig"
}

$Config = Get-Content -LiteralPath $script:CaminhoConfig -Raw | ConvertFrom-Json

function Resolve-Disciplina {
    param([string]$Texto)
    if ([string]::IsNullOrWhiteSpace($Texto)) { return $null }
    $alvo = $Texto.Trim().ToUpper()
    foreach ($prop in $Config.disciplinas.PSObject.Properties) {
        if (@($prop.Value.aliases) -contains $alvo) { return $prop.Name }
    }
    return $null
}

function Get-PastaDisciplina {
    param([string]$Codigo)
    return $Config.disciplinas.$Codigo.pasta
}

function Get-SubpastasDisciplina {
    param([string]$Codigo)
    return @($Config.disciplinas.$Codigo.subpastas)
}

function Get-ExtrasEntrega {
    param([string]$Codigo)
    return @($Config.disciplinas.$Codigo.entrega_extras)
}

function Get-ExtensoesRevisao {
    return @($Config.extensoes_revisao)
}

function Get-PastaBkp { return $Config.pasta_bkp }
function Get-PrefixoPdfTemp { return $Config.prefixo_pdf_temp }
function Get-FormatoData { return $Config.formato_data }

function Get-NomeEntrega {
    param([string]$Sigla, [string]$Disciplina, [string]$Data, [string]$Revisao)
    $nome = $Config.formatos_nome.entrega
    $nome = $nome.Replace('{sigla}', $Sigla)
    $nome = $nome.Replace('{disciplina}', $Disciplina)
    $nome = $nome.Replace('{data}', $Data)
    $nome = $nome.Replace('{revisao}', $Revisao)
    return $nome
}

function Get-NomeRecebido {
    param([string]$Data, [string]$Identificacao, [string]$Fonte)
    $nome = $Config.formatos_nome.recebido
    $nome = $nome.Replace('{data}', $Data)
    $nome = $nome.Replace('{identificacao}', $Identificacao)
    $nome = $nome.Replace('{fonte}', $Fonte)
    return $nome
}

function Get-NomeBackupRevisao {
    param([string]$Revisao)
    return $Config.formatos_nome.backup_revisao.Replace('{revisao}', $Revisao)
}

function Get-PrefixoLiteral {
    # Pega a parte fixa de um formato ate o primeiro "{", para casar nomes de pasta
    # com regex sem precisar saber o valor exato do placeholder (ex: revisao).
    param([string]$Formato)
    $idx = $Formato.IndexOf('{')
    if ($idx -lt 0) { return $Formato }
    return $Formato.Substring(0, $idx).TrimEnd()
}

function Test-EhBackupDeEntrega {
    # Retorna verdadeiro se o nome da pasta é um backup "PROJETO ENTREGUE ..." valido
    param([string]$Nome)
    $prefixo = Get-PrefixoLiteral $Config.formatos_nome.backup_revisao
    return $Nome -match ('(?i)^' + [regex]::Escape($prefixo) + '(\s.*)?$')
}

function Test-EhPastaPdfTemp {
    # Retorna verdadeiro se o nome da pasta e uma pasta temporaria "_PDF" / "_PDF RXX"
    param([string]$Nome)
    $prefixo = Get-PrefixoPdfTemp
    return $Nome -match ('(?i)^' + [regex]::Escape($prefixo) + '(\s.*)?$')
}

function New-EstruturaEntrega {
    # Cria a estrutura padrao de uma pasta de entrega (_ENVIADOS\...) + extras da disciplina
    param([string]$DestinoBase, [string]$Codigo)
    foreach ($sub in $Config.estrutura_entrega_base) {
        New-Item -ItemType Directory -Path (Join-Path $DestinoBase $sub) -Force | Out-Null
    }
    foreach ($extra in (Get-ExtrasEntrega $Codigo)) {
        New-Item -ItemType Directory -Path (Join-Path $DestinoBase $extra) -Force | Out-Null
    }
}

function New-EstruturaProjeto {
    # Cria a estrutura base do projeto + as disciplinas informadas, incluindo
    # uma pasta-exemplo em _ENVIADOS para cada disciplina (com placeholders
    # YYYY.MM.DD e RXX, para servir de modelo visual).
    param([string]$Root, [string]$Sigla, [string[]]$Disciplinas)

    foreach ($sub in $Config.estrutura_base) {
        New-Item -ItemType Directory -Path (Join-Path $Root $sub) -Force | Out-Null
    }

    foreach ($cod in $Disciplinas) {
        $pastaDisc = Get-PastaDisciplina $cod
        if (-not $pastaDisc) { continue }

        foreach ($sub in (Get-SubpastasDisciplina $cod)) {
            New-Item -ItemType Directory -Path (Join-Path $Root (Join-Path $pastaDisc $sub)) -Force | Out-Null
        }

        # $nomeExemplo = Get-NomeEntrega -Sigla $Sigla -Disciplina $cod -Data "YYYY.MM.DD" -Revisao "RXX"
        # $destinoExemplo = Join-Path $Root (Join-Path "_ENVIADOS" $nomeExemplo)
        # New-EstruturaEntrega -DestinoBase $destinoExemplo -Codigo $cod
    }
}
