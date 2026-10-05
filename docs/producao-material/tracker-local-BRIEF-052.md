# Tracker local — BRIEF-052 avulso (asterisco de obrigatório na mesma linha do rótulo)

**RECONCILIADO em 2026-10-05**: card KAN-228 criado no Jira (Tarefa, Backlog). Histórico abaixo.

## Card a criar

| Campo | Valor |
|---|---|
| Projeto | `KAN` (`mp-consultoria.atlassian.net`) |
| Tipo | **Tarefa** (`10008`, `issueType.standalone`). Card único, sem subtask |
| Pai | nenhum (sem épico) |
| Link | `Relates` → **KAN-216** (origem do defeito: PR #39 do frontend, `9c1e179`) |
| Resumo | Asterisco de campo obrigatório quebra linha: deve ficar "texto *" na mesma linha |
| Descrição | Pedido como dito, causa (label `flex-col` separa texto e `*`), critério de aceite e fora de escopo do [BRIEF-052](briefs/BRIEF-052-asterisco-obrigatorio-mesma-linha-avulso.md) |
| Status inicial | Backlog: Tarefa nasce em Backlog no fluxo direcional (ver `docs/_meta/jira.KAN.md`) |

## Fila de operações pendentes (aplicar de cima para baixo)

1. `searchJiraIssuesUsingJql` por `project = KAN AND summary ~ "asterisco"`: confirmar que ninguém
   criou o card à mão enquanto o conector estava fora. Se já existir, use essa key e pule o passo 2.
2. `createJiraIssue` com os campos acima. Medir o status no retorno, que deve ser Backlog.
3. `createIssueLink` `Relates` entre a key nova e o KAN-216 (conferir o nome do tipo em
   `getIssueLinkTypes`).
4. Gravar a key na linha `**Jira**:` do BRIEF-052 e no log abaixo.
5. Mover o card só quando a implementação começar (trilho do CLAUDE.md, ids consultados por origem
   em `getTransitionsForJiraIssue`).

## Log (mais recente no topo)

- 2026-10-05 13:37 (-03): sync com o Jira. Busca anti-duplicata sem correspondência (resultados eram cards antigos e distintos); `createJiraIssue` → **KAN-228** (Tarefa), status medido no retorno: **Backlog**, sem mover. Links Relates criados: KAN-216.
- 2026-10-05: BRIEF-052 e este arquivo criados localmente, com o conector Atlassian sem acesso.
