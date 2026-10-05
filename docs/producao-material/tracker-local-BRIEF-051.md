# Tracker local — BRIEF-051 avulso (botão "Voltar" na criação e na edição de Conteúdo bruto)

**RECONCILIADO em 2026-10-05**: card KAN-227 criado no Jira (Tarefa, Backlog). Histórico abaixo.

## Card a criar

| Campo | Valor |
|---|---|
| Projeto | `KAN` (`mp-consultoria.atlassian.net`) |
| Tipo | **Tarefa** (`10008`, `issueType.standalone`). Card único, sem subtask (pedido do Diretor: "só um jira mesmo") |
| Pai | nenhum (sem épico) |
| Resumo | Conteúdo bruto: "Conteúdos brutos" vira botão "Voltar" na criação e na edição |
| Descrição | Pedido como dito, interpretação, critério de aceite e fora de escopo do [BRIEF-051](briefs/BRIEF-051-conteudo-voltar-botao-avulso.md) |
| Status inicial | Backlog: Tarefa nasce em Backlog no fluxo direcional (ver `docs/_meta/jira.KAN.md`) |

## Fila de operações pendentes (aplicar de cima para baixo)

1. `searchJiraIssuesUsingJql` por `project = KAN AND summary ~ "Voltar"`: confirmar que ninguém
   criou o card à mão enquanto o conector estava fora. Se já existir, use essa key e pule o passo 2.
2. `createJiraIssue` com os campos acima. Medir o status no retorno, que deve ser Backlog.
3. Gravar a key na linha `**Jira**:` do BRIEF-051 e no log abaixo.
4. Mover o card só quando a implementação começar (trilho do CLAUDE.md: Backlog `4` → Tarefas
   pendentes `6` → Em andamento). Antes, consultar `getTransitionsForJiraIssue`, porque os ids
   são por origem.

## Log (mais recente no topo)

- 2026-10-05 13:37 (-03): sync com o Jira. Busca anti-duplicata sem correspondência (resultados eram cards antigos e distintos); `createJiraIssue` → **KAN-227** (Tarefa), status medido no retorno: **Backlog**, sem mover.
- 2026-10-05: BRIEF-051 e este arquivo criados localmente, com o conector Atlassian sem acesso.
