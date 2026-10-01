# Mapa Jira — projeto KAN (mp-consultoria)

Configuração do sync keelson↔Jira. **Config, nunca ledger** — a régua do que entra e do
que não entra está em [README.md](README.md).

## Identidade do projeto

| Campo | Valor | Como foi obtido |
| --- | --- | --- |
| `site` | `https://mp-consultoria.atlassian.net/` | URL do board informada pelo Diretor, 2026-08-23 |
| `cloudId` | `455dadeb-0906-4adf-9500-c9bfb2b979bd` | Resolvido pelo conector a partir do hostname |
| `projectKey` | `KAN` | Segmento `/projects/KAN/` da URL |
| `boardId` | `2` | Segmento `/boards/2` da URL |

O `cloudId` foi confirmado por `getAccessibleAtlassianResources` em 2026-08-27 — único
site retornado, bate exatamente com o valor acima. Projeto `KAN` (id `10001`, nome
"Mnemonicos") confirmado visível nesse cloudId na mesma sessão.

## ✅ `issueType` medido (2026-08-27)

`jira.enabled` está **`true`** na ficha desde 2026-08-27, com os quatro papéis preenchidos
a partir do `createmeta` real do projeto (nunca fixados de cabeça):

```
mcp__atlassian__getJiraProjectIssueTypesMetadata
  cloudId: 455dadeb-0906-4adf-9500-c9bfb2b979bd
  projectIdOrKey: KAN
```

| Papel na ficha | O que é no ciclo | Tipo medido (pt-BR / en) | Id | hierarchyLevel |
| --- | --- | --- | --- | --- |
| `spec` | Épico da SPEC (2+ funcionalidades) | Epic | `10006` | 1 |
| `feature` | História por funcionalidade | História / Story | `10009` | 0 |
| `task` | Subtarefa por TASK | Subtask | `10007` | -1 |
| `standalone` | Brief avulso (mudança pontual) | Tarefa / Task | `10008` | 0 |

⚠️ `KAN` é *team-managed* (next-gen) — estes ids são **escopados a este projeto**; não
reaproveitar em outro projeto do mesmo site, mesmo com o mesmo nome de tipo.

**Epic-raiz criado**: `KAN-6` — "MNEMORA STUDIO — fábrica interna do material mnemônico",
via `/keelson:specify-epic` (BRIEF-2026-08-27-mnemora-studio-epic.md, slug
`producao-material`). https://mp-consultoria.atlassian.net/browse/KAN-6

## ✅ Transições medidas (2026-09-06)

`jira.transition` está **`"auto"`** na ficha desde 2026-09-06 (trocado pelo Diretor). Ids
medidos via `getTransitionsForJiraIssue` em 3 cards reais de 2 tipos (`KAN-29`/`KAN-42`
Subtask, `KAN-27` História) — **idênticos nos 3**, mesmo workflow global para os dois
tipos (`isGlobal: true`, `hasScreen: false` em todas, nenhum validator/post-function com
tela própria encontrado):

| id | Nome da transição | Status-alvo | `statusCategory` |
|----|--------------------|-------------|-------------------|
| `11` | Itens Pendentes | Tarefas pendentes (`10004`) | Itens Pendentes (`new`) |
| `21` | Em andamento | Em andamento (`10005`) | Em andamento (`indeterminate`) |
| `31` | In Review | Em análise (`10006`) | Em andamento (`indeterminate`) |
| `41` | Itens concluídos | Concluído (`10007`) | Itens concluídos (`done`) |

**Tarefa (`standalone`) medido em 2026-09-06** via `getTransitionsForJiraIssue` em
`KAN-43` — idêntico aos dois tipos acima (mesmo workflow global, ids `11`/`21`/`31`/`41`).
`KAN-43` e `KAN-44` transicionados para `41` (Concluído) nesta medição — os dois briefs
avulsos (BRIEF-007, BRIEF-008) já estavam com Status: Concluído localmente desde
2026-09-05, mas ficaram parados em "Tarefas pendentes" no board até este ponto por falta
do id de transição para o tipo.

**Epic medido em 2026-09-16** via `getTransitionsForJiraIssue` em `KAN-121` — fecha o
quarto e último tipo: idêntico aos três acima, mesmo workflow global, ids `11`/`21`/`31`/
`41`, `isGlobal: true` e `hasScreen: false` nas quatro. A suspeita que motivou a medição
(Epic com workflow próprio, comum em projeto team-managed) **não se confirmou** — mas a
régua que a gerou continua: tipo novo no board se mede antes de mover, não se deduz de
ter batido nos outros quatro. Nenhum card foi transicionado nesta medição.

## 🔴 Fluxos novos (Diretor, 2026-10-01) — substituem a tabela acima

O Diretor trocou o fluxo do board em 2026-10-01 para que card novo nasça em **Backlog**. A
partir daqui são **dois fluxos**; a tabela de 2026-09-06 acima continua como histórico, mas
**não vale mais para História e Tarefa**.

### Status (ids medidos via `getTransitionsForJiraIssue`)

| Status (pt-BR no quadro) | Nome no editor de fluxo | Id | `statusCategory` | Fluxos |
| --- | --- | --- | --- | --- |
| Backlog | BACKLOG | `10046` | `new` | História, Tarefa |
| Tarefas pendentes | TO DO | `10004` | `new` | todos |
| Em andamento | IN PROGRESS | `10005` | `indeterminate` | todos |
| Analise pendente | ANALISE PENDENTE | `10047` | **`new`** | História, Tarefa |
| Em análise | IN REVIEW | `10006` | `indeterminate` | História, Tarefa |
| Concluído | DONE | `10007` | `done` | todos |

⚠️ "Analise pendente" (`10047`) foi criado com categoria **`new`** (Itens Pendentes), não
`indeterminate`. Relatório ou JQL por `statusCategory` conta card nesse status como "não
iniciado". Se não for intencional, o Diretor ajusta a categoria no editor de fluxo.

### Epic e Subtask — fluxo simples, global

TO DO · IN PROGRESS · DONE, todas as transições "Qualquer" (de qualquer status). Ids aceitos
pelo endpoint de transição, medidos por tentativa real em `KAN-192` e `KAN-218` (Epic, em
Tarefas pendentes) em 2026-10-01: **`11`** Tarefas pendentes · **`21`** Em andamento ·
**`41`** Concluído. Nascem em Tarefas pendentes. **Sem Backlog e sem Em análise** — o `31`
saiu destes tipos. Subtask não foi movida para medir; o desenho do fluxo que o Diretor
enviou é o mesmo do Epic. Confirmar na primeira transição real de Subtask.

### História e Tarefa — fluxo direcional

Desenho (Diretor): `Create → BACKLOG ⇄ TO DO ⇄ IN PROGRESS ⇄ ANALISE PENDENTE ⇄ IN REVIEW →
DONE → BACKLOG`. Nenhuma transição é global (`isGlobal: false`), e **o id depende do status
de origem**: o mesmo número leva a lugares diferentes conforme a origem.

| Origem → Alvo | Id | Nome da transição | Medido em |
| --- | --- | --- | --- |
| Tarefas pendentes → Backlog | `5` | Despriorizar | KAN-219 (História) |
| Tarefas pendentes → Em andamento | `6` | Iniciar trabalho | KAN-219 (História) |
| Backlog → Tarefas pendentes | `4` | Priorizando | KAN-193 (História) |
| Concluído → Backlog | `3` | Despriorizar | KAN-185 (História), KAN-43 (Tarefa) |
| Em andamento → … | — | **não medido** (nenhum card neste status) | — |
| Analise pendente → … | — | **não medido** | — |
| Em análise → … (inclui → Concluído) | — | **não medido** | — |

Para a Tarefa só a origem Concluído foi observada. Ela bateu com a História (`3`), mas o par
de Tarefas pendentes não se deduz disso: mede-se no primeiro uso. **Regra até a tabela fechar:
antes de cada transição, `getTransitionsForJiraIssue` no card e uso do id devolvido para o
status-alvo.** Cada par novo observado entra nesta tabela.

**Cards de 2026-10-01 movidos para Backlog**: KAN-193…217 e KAN-219…224 (31 Histórias, via
`5`). KAN-192 e KAN-218 (Epics) ficaram em Tarefas pendentes, porque o fluxo do Epic não tem
Backlog.

## Campos

*A preencher na primeira medição: campos obrigatórios por tipo, prioridade, responsável,
estratégia de escrita.*

## Etapas/Colunas

*A preencher: colunas do board 2, status-alvo de cada etapa do ciclo, coluna de nascimento
por tipo de issue.*

<!-- Sugestão gerada por /keelson:init (2026-09-06) a partir do `getTransitionsForJiraIssue`
     já medido acima (seção "Transições medidas") — pré-preenchida por statusCategory, não
     aplicada: o Diretor confirma/ajusta a coluna `Coluna` (rótulo do board) e promove a
     tabela removendo este comentário. Story/Subtask medidos; Epic e Tarefa (standalone)
     ainda não têm transição observada — linhas correspondentes ficam de fora até medir.

| Etapa | Nível | Coluna | Status-alvo (ID) | Gatilho |
| --- | --- | --- | --- | --- |
| TASK iniciada | subtask | ? | Em andamento (10005) | despacho da TASK ao developer |
| TASK concluída | subtask | ? | Concluído (10007) | closure da TASK (Done) |
| Trabalho iniciado (Story) | story | ? | Em andamento (10005) | primeira TASK da Story despachada |
| Funcionalidade pronta p/ QA | story | ? | Em análise (10006) | todas as TASKs da FEAT Done — decisão do Diretor (ver "Trilho do board" abaixo): a História fecha só após revisão própria, não vai direto a Concluído |
| Fase iniciada (Story) | story | ? | Em andamento (10005) | --phase start-dev (linha acrescentada por /keelson:init 2026-09-16 — protocolo §13; ids já medidos acima) |
| Fase concluída (Story) | story | ? | Em análise (10006) | --phase finish-dev (idem — alinhada à decisão do Diretor: História não vai direto a Concluído) |
| Fase iniciada (Subtask) | subtask | ? | Em andamento (10005) | --phase start-dev (idem) |
| Fase concluída (Subtask) | subtask | ? | Concluído (10007) | --phase finish-dev (idem) |
| ? | epic | ? | — não medido — | --phase start-dev (linha nasce comentada — mover Epic é opt-in explícito do Diretor) |
| ? | epic | ? | — não medido — | --phase finish-dev (idem) |

-->

## Trilho do board

Uso do trilho nesta primeira aplicação (`transition: "auto"`, 2026-09-06): subtask com
TASK `Done` → id `41` (Concluído); História com todas as subtasks fechadas → id `31` (Em
análise, não Concluído — decisão do Diretor: a História só fecha depois de revisão
própria, mesmo com as subtasks todas prontas). Epic não movido nesta rodada (fora do
pedido).

### Fecho pós-merge (decisão do Diretor, 2026-09-16)

⚠️ **Procedimento humano, não gatilho de sync.** O catálogo de gatilhos do protocolo é
fechado (§3): "pós-merge" não é um marco canônico, então nada aqui dispara sozinho — o
motor ignora esta subseção. Ela existe para o **Tech Lead** executar via conector MCP
quando o Diretor avisar que mergeou. A régua completa está no
[CLAUDE.md](../../CLAUDE.md) do workspace, seção *Trilho do card*; o resumo operacional:

1. História mergeada → Concluído. **Desde 2026-10-01** o `--phase finish-dev` deixa a
   História em **Análise pendente** (decisão do Diretor), e o fluxo é direcional: Concluído
   só se alcança a partir de Em análise, então o caminho é Análise pendente → Em análise →
   Concluído. Os ids desses dois saltos ainda **não estão medidos**; consulte as transições
   do card (seção *Fluxos novos*). *Até 2026-09-30: `31 → 41` direto, ids globais.*
2. Consultar os filhos do épico por JQL (`project = KAN AND parent = <EPIC>`) — estado
   lido do quadro, nunca de memória de sessão nem do `INDEX.md` do slug.
3. Todos os filhos em `41` → épico para `41`. **Qualquer** filho aberto → épico intocado.

O passo 3 teve um caso vivo que contradiz a leitura ingênua: **KAN-106** ("Pipeline de
publicação — PDF") teve sua única História, KAN-107, em `41` e permaneceu em `21` (Em
andamento) por decisão do Diretor em 2026-09-16 (o épico ainda receberia trabalho —
RISK-025-007/RISK-024-001 em aberto). **Revertido no mesmo dia**: o Diretor pediu o
fechamento explicitamente mesmo com os dois riscos ainda sem resolução formal — KAN-106
foi movido para `41`. Épico aberto com todos os filhos fechados não é, por si só, dívida
a limpar: confirme a intenção antes de mover, porque o quadro não distingue "esvaziou" de
"vai receber mais" — mas a confirmação pode legitimamente escolher fechar mesmo com risco
pendente registrado fora do Jira.

Isto é doutrina deste projeto, não do plugin. O keelson não tem verbo de fase pós-merge
(só `start-dev` e `finish-dev`), e por contrato o `/keelson:auto` e o `/keelson:integrate`
param no teto de desenvolvimento (§9) — nenhum dos dois fecha card.

## Achados de config

*A preencher conforme a execução revelar: validator invisível, id que mudou, post-function
que não dispara. A medição justifica a régua; ela não é a régua.*

- **`getTransitionsForJiraIssue` mente para o Epic** (2026-10-01). Em `KAN-192` (Epic, em
  Tarefas pendentes) a consulta listou `11`, `21`, `31`, `41`, `2` (→ Backlog) e `3` (→
  Analise pendente), todas `isGlobal: true` e `isAvailable: true`. A transição `2` foi
  **recusada** pelo endpoint: "Transition id '2' is not valid for this issue", com
  `allowedValues` só `11`, `21`, `41`. Provável causa: o projeto team-managed compartilha
  os status entre os fluxos e a consulta não filtra pelo fluxo do tipo. Para o Epic,
  vale o `allowedValues` do erro (ou o desenho do fluxo), **não a lista da consulta**.
  Para História e Tarefa, a consulta bateu com a execução nos pares medidos.
- **Fluxo de História e Tarefa deixou de ser global** (2026-10-01). Os ganchos do keelson
  com `transition: "auto"` que usem `21`/`31`/`41` fixos para História falham **em
  silêncio** (sync best-effort). Desde então, o trilho do card no `CLAUDE.md` exige
  consultar as transições do card antes de mover História/Tarefa.

- **`issueType.spec` (Epic, id `10006`, hierarchyLevel 1) não tem campo `parent`** —
  confirmado via `getJiraIssueTypeMetaWithFields` (KAN, issueTypeId `10006`) em
  2026-09-13: a lista de campos do createmeta não inclui `parent` (projeto team-managed
  sem nível acima de Epic/Advanced Roadmaps). Consequência: uma SPEC nova que é fatia de
  um épico-raiz já existente (ex.: KAN-6, "MNEMORA STUDIO") **não pode** ser criada com
  `parent: KAN-6` — mesmo nível hierárquico (1), não adjacente (§7.0 do protocolo). O
  stub-raiz da largada (§16) nasce **sem parent** e é ligado ao épico-raiz por
  `createIssueLink` tipo `Relates` (id `10003`). Primeiro caso: KAN-85 (stub SPEC-022,
  fatia F5) ↔ KAN-6, 2026-09-13. Segundo caso: KAN-121 (SPEC-026, fatia F7,
  `epicPolicy: multi-feature` com 4 FEATs — projeção plena, criação no gancho do
  specify por exceção do §16) ↔ KAN-6, 2026-09-16.
