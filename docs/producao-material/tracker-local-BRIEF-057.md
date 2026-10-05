# Tracker local — BRIEF-057

**RECONCILIADO em 2026-10-05**: card KAN-233 criado no Jira (Tarefa, Backlog). Histórico abaixo.

## Card a criar

| Campo | Valor |
|---|---|
| Projeto | `KAN` (`mp-consultoria.atlassian.net`) |
| Tipo | **Tarefa** (`10008`, `issueType.standalone`). Card único |
| Pai | nenhum (sem épico) |
| Resumo | Nenhum link sublinhado na aplicação |
| Descrição | Pedido como dito, interpretação, premissas, critério de aceite e fora de escopo do [BRIEF-057](briefs/BRIEF-057-links-sem-sublinhado-avulso.md) |
| Status inicial | Backlog: História e Tarefa nascem em Backlog no fluxo direcional (ver `docs/_meta/jira.KAN.md`) |

## Fila de operações pendentes (aplicar de cima para baixo)

1. `searchJiraIssuesUsingJql` por `project = KAN AND summary ~ "sublinhado"`: confirmar que ninguém
   criou o card à mão enquanto o conector estava fora. Se já existir, use essa key e pule o passo 2.
2. `createJiraIssue` com os campos acima. Medir o status no retorno, que deve ser Backlog.
3. Gravar a key na linha `**Jira**:` do BRIEF-057 e no log abaixo.
4. Mover o card só quando a implementação começar (trilho do CLAUDE.md, ids consultados por origem
   em `getTransitionsForJiraIssue`).

## Log (mais recente no topo)

- 2026-10-05 13:37 (-03): sync com o Jira. Busca anti-duplicata sem correspondência (resultados eram cards antigos e distintos); `createJiraIssue` → **KAN-233** (Tarefa), status medido no retorno: **Backlog**, sem mover.
- 2026-10-05: BRIEF-057 e este arquivo criados localmente, com o conector Atlassian sem acesso.
