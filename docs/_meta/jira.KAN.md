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

Não medido ainda para o tipo **Epic** nem **Tarefa** (`standalone`) — meça antes de mover
um card desses tipos; não assuma os mesmos ids só porque bateram em Subtask/História.

## Campos

*A preencher na primeira medição: campos obrigatórios por tipo, prioridade, responsável,
estratégia de escrita.*

## Etapas/Colunas

*A preencher: colunas do board 2, status-alvo de cada etapa do ciclo, coluna de nascimento
por tipo de issue.*

## Trilho do board

Uso do trilho nesta primeira aplicação (`transition: "auto"`, 2026-09-06): subtask com
TASK `Done` → id `41` (Concluído); História com todas as subtasks fechadas → id `31` (Em
análise, não Concluído — decisão do Diretor: a História só fecha depois de revisão
própria, mesmo com as subtasks todas prontas). Epic não movido nesta rodada (fora do
pedido).

## Achados de config

*A preencher conforme a execução revelar: validator invisível, id que mudou, post-function
que não dispara. A medição justifica a régua; ela não é a régua.*
