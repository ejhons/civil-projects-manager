# Sistema de Automação de Projetos — Addamento

Conjunto de scripts (Windows `.bat` + PowerShell) e ferramentas visuais (HTML) para padronizar a criação, entrega, revisão e documentação de projetos de Terraplenagem, Drenagem, Esgoto e Rede de Água.

Tudo roda localmente, sem instalar nada além do que o Windows já traz (cmd, PowerShell e um navegador Chrome/Edge para as ferramentas visuais).

---

## 1. Estrutura de pastas

```
Projetos em Andamento\
├── .Scripts\                          ← todos os scripts ficam aqui
│   ├── painel.bat
│   ├── config.json                    ← nomes/formatos de pasta centralizados
│   ├── PastasConfig.ps1                ← módulo lido por todos os .ps1
│   ├── criar_estrutura_projeto.bat
│   ├── criar_estrutura.ps1
│   ├── criar_metadata.ps1
│   ├── criar_pasta_enviados.bat
│   ├── criar_pasta_entrega.ps1
│   ├── registrar_entrega.ps1
│   ├── adicionar-recebido.bat
│   ├── criar_revisao.bat
│   ├── criar_revisao.ps1
│   ├── aprovar_enviado.bat
│   ├── limpar_bkp.bat
│   ├── limpar_bkp.ps1
│   ├── adicionar-anotacao.bat
│   ├── adicionar_anotacao.ps1
│   ├── criar_metadata_retroativo.bat
│   ├── inicializar_metadata_existente.ps1
│   ├── editor_metadados.html
│   └── overview_projetos.html
│
├── 261.MRU.BVEUS2\                    ← um projeto = NUMERO.CODIGOCLIENTE.SIGLA
│   ├── _metadata.json                 ← "banco de dados" do projeto
│   ├── 00.BASE\
│   │   ├── _BACKUP\
│   │   └── 01.QTO\
│   ├── 01.TERRAPLENAGEM\
│   │   ├── 01.DESENHOS\
│   │   │   ├── _PDF R01\              ← staging temporário da revisão em andamento
│   │   │   │   ├── PDF\
│   │   │   │   ├── DWG\
│   │   │   │   ├── CAD\
│   │   │   │   └── C3D\
│   │   │   ├── _BKP\                  ← backups de revisões já entregues
│   │   │   │   └── PROJETO ENTREGUE R00\
│   │   │   ├── 01.IMG\
│   │   │   └── 02.BLK\
│   │   ├── 02.DOCUMENTOS\
│   │   │   ├── _BKP\
│   │   │   │   └── PROJETO ENTREGUE R00\
│   │   │   ├── 00.BRIEFING\
│   │   │   ├── 01.CUBAÇÃO\
│   │   │   ├── 02.PAVIMENTAÇÃO\
│   │   │   ├── 03.ANEXOS\
│   │   │   └── 04.QUANTITATIVOS\
│   │   ├── 03.CARDENETA DE CAMPO\
│   │   └── 04.BIM\
│   ├── 02.DRENAGEM\        (mesma lógica de 01.DESENHOS / 02.DOCUMENTOS)
│   ├── 03.ESGOTO\          (idem)
│   ├── 04.REDE DE ÁGUA\    (idem, com pasta extra 03.EPANET)
│   ├── _ENVIADOS\
│   │   └── BVEUS2 TERR 2026.09.17 R01\
│   │       ├── 01.DESENHOS\
│   │       │   ├── 01.PDF\
│   │       │   └── 02.DWG\
│   │       │       └── 01.IMG\
│   │       └── 02.DOCUMENTOS\
│   │           ├── 01.ANEXOS\
│   │           └── 02.CUBAÇÃO\        (só para TERR)
│   ├── _RECEBIDOS\
│   │   └── 2026.06.30 - TOPOGRAFIA - EMAIL\
│   └── _REFERÊNCIAS\
│
└── 260.XXX.OUTRO\
    └── ...
```

### Códigos de disciplina usados em todo o sistema

| Código  | Disciplina    | Pasta correspondente |
| -------- | ------------- | -------------------- |
| `TERR` | Terraplenagem | `01.TERRAPLENAGEM` |
| `DRN`  | Drenagem      | `02.DRENAGEM`      |
| `SES`  | Esgoto        | `03.ESGOTO`        |
| `SAA`  | Água         | `04.REDE DE ÁGUA` |

Ao digitar nos scripts, `TER` é aceito como sinônimo de `TERR`.

### Convenção de revisão

Arquivos de elaboração (dwg, xlsx, imagens) trazem `-R00`, `-R01`, `-R02`... no nome. As pastas de entrega e backup seguem o mesmo padrão (`R00`, `R01`...).

---

## 2. `config.json` + `PastasConfig.ps1` — configuração central

Em vez de cada script ter os nomes de pasta, códigos de disciplina e formatos "cravados" no meio do código, tudo isso vive em um único arquivo:**`config.json`** (dentro de `.Scripts\config`).

`PastasConfig.ps1` é um módulo carregado por todos os `.ps1` (via dot-source,`. "$PSScriptRoot\PastasConfig.ps1"`) que lê esse `config.json` uma vez e expõe funções prontas: `Resolve-Disciplina`, `Get-PastaDisciplina`, `Get-ExtensoesRevisao`, `Get-NomeEntrega`, `Get-NomeRecebido`, `Get-NomeBackupRevisao`, `New-EstruturaProjeto`, `New-EstruturaEntrega`, etc.
Os `.bat` que precisam desses valores chamam o PowerShell rapidamente para consultá-los (o mesmo padrão já usado para outras coisas, como a data de hoje).

O que está no `config.json`:

```json
{
  "formato_data": "yyyy.MM.dd",
  "pasta_bkp": "_BKP",
  "prefixo_pdf_temp": "_PDF",
  "formatos_nome": {
    "entrega": "{sigla} {disciplina} {data} {revisao}",
    "recebido": "{data} - {identificacao} - {fonte}",
    "backup_revisao": "PROJETO ENTREGUE {revisao}"
  },
  "extensoes_revisao": [".dwg", ".dxf", ".xlsx", "..."],
  "estrutura_base": ["00.BASE\\_BACKUP", "..."],
  "estrutura_entrega_base": ["01.DESENHOS\\01.PDF", "..."],
  "disciplinas": {
    "TERR": {
      "aliases": ["TER", "TERR"],
      "pasta": "01.TERRAPLENAGEM",
      "subpastas": ["01.DESENHOS\\01.IMG", "..."],
      "entrega_extras": ["02.DOCUMENTOS\\02.CUBAÇÃO"]
    }
  }
}
```

**O que isso permite mudar sem tocar em nenhum `.bat` ou `.ps1`:**

- Renomear a pasta de uma disciplina (ex.: se um dia `04.REDE DE ÁGUA` virar `04.ABASTECIMENTO`), ou adicionar apelidos aceitos na hora de digitar
  (`aliases`).
- Adicionar/remover subpastas criadas para uma disciplina.
- Mudar o formato do nome das pastas de entrega, recebido ou backup de revisão (ex.: trocar a ordem `{sigla} {disciplina} {data} {revisao}`).
- Adicionar novas extensões de arquivo que entram no backup/renomeação de revisão.
- Trocar o nome da pasta `_BKP` ou o prefixo `_PDF`.

**Para adicionar uma disciplina nova** (ex. "Pavimentação" separada de Terraplenagem), edite o `config.json` acrescentando um bloco em `"disciplinas"` com `aliases`, `pasta`, `subpastas` e `entrega_extras` — os scripts passam a reconhecer automaticamente, sem editar nenhum `.bat`/`.ps1`.

**O que ainda não está centralizado (pendências conhecidas):**

- Os chips de disciplina no `editor_metadados.html` e o dropdown em `overview_projetos.html` continuam com `TERR`/`DRN`/`SAA`/`SES` fixos no HTML — daria para fazer esses dois lerem o `config.json` também (já que ambos já têm acesso à pasta de projetos), mas ainda não foi feito.
- Padrões de busca por pastas já existentes (ex. localizar uma pasta de entrega já criada em `_ENVIADOS`) assumem que o nome tem sigla e disciplina nesta ordem — uma mudança muito grande no formato pode exigir ajuste manual nesses trechos de busca.

---

## 3. Instalação / configuração inicial

1. Copie a pasta `.Scripts` (com todos os arquivos) para dentro de **"Projetos em Andamento"**.
2. (Opcional, recomendado) Adicione `...\Projetos em Andamento\.Scripts` à variável de ambiente **PATH** do Windows, para poder digitar
   `adicionar-recebido` de qualquer lugar do `cmd`:
   - `Win` → "variáveis de ambiente" → Editar as variáveis de ambiente do sistema → Variáveis de Ambiente → Path (do usuário) → Editar → Novo → cole o caminho da pasta `.Scripts` → OK em tudo → abra um novo `cmd`.
3. Crie um atalho do `painel.bat` na área de trabalho (renomeie para "Painel de Projetos" e troque o ícone, se quiser algo mais discreto que um `.bat` solto).
4. Os arquivos `.html` (`editor_metadados.html`, `overview_projetos.html`) abrem com duplo clique, em Chrome ou Edge. Funcionam 100% offline.

Nenhum dado é enviado para fora da máquina/servidor — tudo é lido e escrito localmente.

---

## 4. `painel.bat` — menu único

Ponto de entrada de tudo. Mostra um menu numerado; cada opção chama o script correspondente e volta ao menu ao terminar.

```
1. Criar novo projeto
2. Criar entrega em _ENVIADOS
3. Adicionar recebido em _RECEBIDOS
4. Criar revisao (backup + incremento -RXX)
5. Aprovar enviado (_PDF RXX -> _ENVIADOS)
6. Limpar _BKP e pastas temporarias (_PDF)
7. Gerar/atualizar metadados de projeto existente
8. Abrir editor de metadados (formulario)
9. Abrir overview de todos os projetos
0. Sair
```

---

## 5. `criar_estrutura_projeto.bat`

Cria um projeto novo do zero, dentro de "Projetos em Andamento".

**Pede:** nome do empreendimento, sigla (5-6 letras), código do cliente (3-4 letras), número sequencial do projeto, nome do cliente, localidade, e quais disciplinas serão desenvolvidas (S/N para cada uma).

**Faz:**

- Cria a pasta raiz `NUMERO.CODIGO.SIGLA` com toda a árvore de pastas (`00.BASE`, disciplinas escolhidas, `_ENVIADOS`, `_RECEBIDOS`, `_REFERÊNCIAS`).
- Gera o `_metadata.json` inicial (via `criar_metadata.ps1`) com os dados informados.

---

## 6. `criar_pasta_enviados.bat`

Cria uma pasta de entrega dentro de `_ENVIADOS` de um projeto já existente.

**Pede:** índice do projeto (sigla, número ou nome — busca dentro de "Projetos em Andamento"), disciplina, data (sugere hoje), revisão (sugere a próxima automaticamente, olhando as pastas já existentes em `_ENVIADOS`), responsável e observações.

**Faz:**

- Cria `_ENVIADOS\SIGLA DISC DATA REV\` com a estrutura padrão (`01.DESENHOS\01.PDF`, `01.DESENHOS\02.DWG\01.IMG`,`02.DOCUMENTOS\01.ANEXOS`, mais `02.CUBAÇÃO` para TERR e `03.EPANET` para SAA).
- Registra a entrega no `_metadata.json` (via `registrar_entrega.ps1`) — disciplina, data, revisão, responsável, observações.
- Se havia uma revisão em aberto (criada pelo `criar_revisao.bat`) para essa disciplina/revisão, fecha ela automaticamente preenchendo a `data_envio`.

---

## 7. `adicionar-recebido.bat`

Copia arquivos recebidos (de clientes, topografia, etc.) para dentro de `_RECEBIDOS`. Pode ser chamado de **qualquer pasta do computador** (inclusive fora da rede do projeto), desde que o PATH tenha sido configurado — funciona como um comando próprio do Windows, no estilo `git`.

**Pede:** índice do projeto, data (sugere hoje), identificação/assunto, fonte, e o caminho da pasta de origem com os arquivos (dá pra arrastar a pasta para dentro da janela do `cmd`).

**Faz:**

- Cria `_RECEBIDOS\DATA - IDENTIFICAÇÃO - FONTE\` (se já existir, usa a mesma, sem duplicar).
- Copia os arquivos da origem com `robocopy /E` (inclui subpastas). Rodar de novo com os mesmos dados só atualiza o que mudou, não duplica.
- Não mexe no `_metadata.json` (decisão explícita — não é necessário para este fluxo).

---

## 8. `criar_revisao.bat` + `criar_revisao.ps1`

Inicia uma nova revisão em uma ou mais disciplinas: faz backup dos arquivos da elaboração atual e incrementa a numeração `-RXX` para a próxima revisão.

**Pede:** índice do projeto, disciplinas a revisar (uma ou mais, separadas por espaço — raramente todas de uma vez).

**Para cada disciplina, faz:**

1. Sugere a revisão atual cruzando duas fontes: a última revisão registrada no `_metadata.json` e o maior `-RXX` encontrado nos nomes de arquivo em
   `01.DESENHOS`/`02.DOCUMENTOS`. Você confirma ou digita outra.
2. Copia (backup) os arquivos `.dwg`, `.dxf`, `.xlsx`, `.xls`, `.jpg`, `.jpeg`, `.png`, `.tif`/`.tiff` que estão **direto** em `01.DESENHOS` e em `02.DOCUMENTOS` (sem entrar em subpastas) para
   `..._BKP\PROJETO ENTREGUE R0X\` (cria a pasta `_BKP` se não existir).
3. Renomeia, no lugar original, os arquivos que tinham `-R0X` no nome para `-R0(X+1)`. Se já existir um arquivo com o nome de destino, avisa e não sobrescreve.
4. Registra o início da revisão no `_metadata.json`, em um array `revisoes` — disciplina, revisão anterior, revisão nova, data de início.
5. A `data_envio` fica em aberto até a entrega correspondente ser registrada (ver seção 5).

---

## 9. `aprovar_enviado.bat`

Move/copia os arquivos aprovados da área de revisão (`_PDF RXX`) para a pasta de entrega em `_ENVIADOS`.

**Pede:** índice do projeto, disciplina, revisão (sugere a revisão em aberto no `_metadata.json`, se houver).

**Faz:**

- Localiza `01.DESENHOS\_PDF R0X\` (com subpastas `PDF`, `DWG`, `CAD`, `C3D` — usa as que existirem).
- Localiza a pasta de entrega correspondente em `_ENVIADOS`; se não existir ainda, pergunta a data e cria a estrutura padrão na hora.
- **Move** (não copia) os arquivos:
  - `_PDF R0X\PDF\*` → `_ENVIADOS\...\01.DESENHOS\01.PDF`
  - `_PDF R0X\DWG\*`, `\CAD\*`, `\C3D\*` → todos juntos em
    `_ENVIADOS\...\01.DESENHOS\02.DWG`
- **Copia** (mantém o original) os PDFs de `02.DOCUMENTOS` cujo nome contenha a revisão (ex.: `*R01*.pdf`) para `_ENVIADOS\...\02.DOCUMENTOS\01.ANEXOS`.

Depois disso, os arquivos em `_ENVIADOS` ficam prontos para assinatura do engenheiro responsável.

---

## 10. `limpar_bkp.bat` + `limpar_bkp.ps1`

Faxina nas pastas `_BKP` e nas pastas temporárias `_PDF`/`_PDF RXX`.

**Pede:** índice do projeto, disciplinas a limpar (uma, várias, ou `TODAS`).

**Faz, para cada disciplina, sempre com confirmação antes de apagar:**

- Lista tudo o que está dentro de `01.DESENHOS\_BKP` e `02.DOCUMENTOS\_BKP` que **não** seja uma pasta `PROJETO ENTREGUE...`(arquivos soltos, pastas de versões antigas fora do padrão).
- Lista qualquer pasta `_PDF` ou `_PDF RXX` dentro de `01.DESENHOS`.
- Mostra a lista completa e só apaga se você digitar **`SIM`** exatamente. Qualquer outra resposta cancela, sem tocar em nada.

Nunca apaga pastas `PROJETO ENTREGUE RXX` — são o que deve permanecer.

---

## 11. `adicionar-anotacao.bat` — anotações de projeto

Registro rápido de uma observação/decisão ligada a um projeto (e, opcionalmente, a uma disciplina e revisão específicas), sem precisar abrir o editor de metadados. Como `adicionar-recebido.bat`, pode ser chamado de qualquer pasta do computador se o PATH estiver configurado (seção 3).

**Pede:** 

- índice do projeto;
- disciplina (opcional — em branco vira uma anotação "GERAL", não ligada a nenhuma disciplina);
- revisão (opcional);
- o texto da anotação;
- e o autor (sugere automaticamente o usuário logado no Windows via `%USERNAME%`, você pode trocar).

**Faz:**

- Grava no `_metadata.json`, em um array `anotacoes`, um registro com disciplina, revisão, autor, texto e data/hora — tudo timestampado automaticamente, sem depender de o usuário lembrar de preencher.

```json
{
  "disciplina": "TERR",
  "revisao": "R01",
  "autor": "jsilva",
  "texto": "Cliente pediu para revisar o greide próximo ao talude sul",
  "data": "2026-09-18 11:20"
}
```

Isso fica separado do campo `observacoes` de cada entrega (que é sobre umaentrega específica) — `anotacoes` é para registrar decisões e comentários a qualquer momento do trabalho, não só na hora de entregar.

*Pendência conhecida:* nem o `editor_metadados.html` nem o `overview_projetos.html` mostram essas anotações ainda — hoje elas só ficam guardadas no `_metadata.json`, para consulta futura ou até que a exibição seja implementada.

---

## 12. `criar_metadata_retroativo.bat` + `inicializar_metadata_existente.ps1`

Gera (ou atualiza) o `_metadata.json` de um projeto que já existia antes deste sistema, ou que perdeu o arquivo.

**Pede:** índice do projeto; nome, cliente e localidade (se o `_metadata.json` já existir, mostra os valores atuais como sugestão —Enter mantém).

**Faz:**

- Detecta quais disciplinas foram desenvolvidas (checando se as pastas `01.TERRAPLENAGEM`, `02.DRENAGEM`, `03.ESGOTO`, `04.REDE DE ÁGUA` existem).
- Reconstrói o histórico de entregas lendo os nomes das pastas dentro de `_ENVIADOS`.
- Preserva responsável/observações já preenchidos manualmente em entregas existentes (não sobrescreve ao rodar de novo).

---

## 13. `editor_metadados.html`

Formulário visual para editar o `_metadata.json` sem mexer em texto puro.

- Abre a pasta "Projetos em Andamento" uma vez (Chrome/Edge lembram a permissão entre sessões — veja seção 13).
- Escolhe o projeto numa lista com busca.
- Edita nome, cliente, localidade, disciplinas (chips), e a tabela de entregas (disciplina, data, revisão, responsável, observações) — adiciona ou remove linhas.
- Botão **Salvar** grava direto no arquivo original (Chrome/Edge) ou baixa uma cópia para você mover manualmente (outros navegadores).

---

## 14. `overview_projetos.html`

Painel de leitura de todos os projetos de uma vez.

- Lê o `_metadata.json` de cada pasta de projeto.
- Mostra cards de resumo (total de projetos, total de entregas, projetos sem metadados, disciplina mais comum).
- Tabela ordenável por sigla, número, cliente, localidade, disciplinas, quantidade de entregas e data da última entrega.
- Busca por sigla, cliente, localidade ou disciplina.
- Clique numa linha expande o histórico de entregas daquele projeto.
- Botão **"✎ Editar"** em cada linha abre o `editor_metadados.html` já apontando para aquele projeto.
- Lista separada de pastas sem `_metadata.json`, indicando rodar o `criar_metadata_retroativo.bat`.

---

## 15. Pasta lembrada entre sessões (Chrome/Edge)

Tanto o editor quanto o overview usam a File System Access API do navegador para guardar a referência da pasta "Projetos em Andamento" (via IndexedDB, local ao navegador/computador). Assim:

- Na primeira vez, você seleciona a pasta normalmente.
- Nas próximas, a página tenta reconectar sozinha; se o navegador exigir reconfirmação, aparece um botão "Continuar com a pasta salva" (um clique).

Isso é por navegador/computador — trocar de máquina ou de navegador exige selecionar a pasta de novo uma vez.

---

## 16. `_metadata.json` — estrutura de dados

Cada projeto tem um `_metadata.json` na sua raiz:

```json
{
  "numero": "261",
  "codigo_cliente": "MRU",
  "sigla": "BVEUS2",
  "nome_projeto": "Nome do empreendimento",
  "cliente": "Nome do cliente",
  "localidade": "Cidade/UF",
  "disciplinas": ["TERR", "SAA"],
  "criado_em": "2026-09-17 10:32",
  "entregas": [
    {
      "disciplina": "TERR",
      "data": "2026.09.17",
      "revisao": "R01",
      "responsavel": "Fulano",
      "observacoes": "Revisão do greide após reunião com cliente",
      "pasta": "_ENVIADOS\\BVEUS2 TERR 2026.09.17 R01",
      "registrado_em": "2026-09-17 14:05"
    }
  ],
  "revisoes": [
    {
      "disciplina": "TERR",
      "revisao_anterior": "R00",
      "revisao_nova": "R01",
      "data_inicio": "2026-09-15 09:10",
      "data_envio": "2026-09-17 14:05"
    }
  ],
  "anotacoes": [
    {
      "disciplina": "TERR",
      "revisao": "R01",
      "autor": "jsilva",
      "texto": "Cliente pediu para revisar o greide próximo ao talude sul",
      "data": "2026-09-18 11:20"
    }
  ]
}
```

- **`entregas`**: uma linha por vez que `_ENVIADOS` recebeu uma entrega (via `criar_pasta_enviados.bat`).
- **`revisoes`**: uma linha por vez que uma revisão foi iniciada (via `criar_revisao.bat`). `data_envio` fica `null` até a entrega correspondente ser registrada — é o que dá a métrica de "quanto tempo uma revisão ficou em elaboração".
- **`anotacoes`**: comentários e decisões registrados a qualquer momento (via `adicionar-anotacao.bat`), com autor e data/hora automáticos. Disciplina "GERAL" significa uma anotação não ligada a uma disciplina específica.

---

## 17. Fluxo de trabalho típico, do início ao fim

1. **Criar o projeto** → `criar_estrutura_projeto.bat` (opção 1 do painel).
2. **Elaborar** os desenhos/documentos normalmente em `01.DESENHOS` e `02.DOCUMENTOS` (arquivos com `-R00` no nome).
3. Quando estiver pronto para gerar PDFs para revisão interna, colocar os arquivos em `01.DESENHOS\_PDF R00\{PDF,DWG,CAD,C3D}` (ainda manual —não há comando para isso).
4. **Aprovar** os arquivos revisados internamente → `aprovar_enviado.bat` (opção 5) — move para `_ENVIADOS`, prontos para assinatura do engenheiro responsável.
5. **Registrar a entrega** → `criar_pasta_enviados.bat` (opção 2), se ainda não tiver sido criada automaticamente pelo passo anterior — grava no histórico quem trabalhou e observações.
6. Cliente manda comentários / nova topografia → **Adicionar recebido** (opção 3).
7. Chegou a hora de nova revisão → **Criar revisão** (opção 4) — arquiva os arquivos atuais em `_BKP\PROJETO ENTREGUE R0X` e renomeia para `-R0(X+1)`.
8. Repete os passos 2 a 7 a cada ciclo de revisão.
9. De vez em quando → **Limpar _BKP** (opção 6) para tirar lixo acumulado, mantendo só os backups de "projeto entregue".
10. Para consultar o panorama geral → **Overview de projetos** (opção 9), e para corrigir algo pontual → **Editor de metadados** (opção 8).

---

## 18. Requisitos e observações técnicas

- **Windows 10/11**, com PowerShell disponível (já vem por padrão).
- **Chrome ou Edge** para `editor_metadados.html` e `overview_projetos.html` (usam a File System Access API — não funcionam completamente no Firefox ou Safari).
- Os `.bat` usam `chcp 65001` para lidar com acentos (Ç, Ã, Á, É). Se algum script mostrar caracteres estranhos, salve o `.bat` novamente como UTF-8 puro (sem BOM) no Bloco de Notas.
- Caminhos de rede (`\\SERVIDOR\...`) são tratados com `pushd`, que resolve o problema clássico do `cmd` não aceitar UNC como diretório atual.
- `robocopy` (usado em `adicionar-recebido.bat` e `aprovar_enviado.bat`) já vem em todo Windows moderno — não precisa instalar nada.
- Nenhum dado de projeto é enviado para fora da rede local — tudo roda e fica salvo na própria máquina/servidor.

---

## 19. O que ainda é manual (não automatizado)

- Colocar os arquivos gerados na `_PDF RXX\{PDF,DWG,CAD,C3D}` antes de aprovar — quem gera esses arquivos (CAD/Civil 3D) ainda organiza essa etapa manualmente.
- Assinatura digital/física dos documentos em `_ENVIADOS`.
- Preenchimento de decisões técnicas detalhadas — o campo "observações" das entregas é de texto livre, sem estrutura própria.
