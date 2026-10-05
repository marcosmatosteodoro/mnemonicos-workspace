# Tracker local — BRIEF-058

**PENDENTE**: o card ainda não existe no Jira. Foi criado localmente em 2026-10-05, com o acesso
ao conector retirado pelo Diretor. Quando o acesso voltar, aplique a fila abaixo e grave a key no
BRIEF-058 (linha `**Jira**:`).

## Card a criar

| Campo | Valor |
|---|---|
| Projeto | `KAN` (`mp-consultoria.atlassian.net`) |
| Tipo | **Tarefa** (`10008`, `issueType.standalone`). Card único |
| Pai | nenhum (sem épico) |
| Link | `Relates` → **KAN-223** e **KAN-220** |
| Resumo | Editar conta: "Confirmar senha" ausente na redefinição (KAN-223 aplicado em código morto) |
| Descrição | Pedido como dito, interpretação, premissas, critério de aceite e fora de escopo do [BRIEF-058](briefs/BRIEF-058-editar-conta-confirmar-senha-avulso.md) |
| Status inicial | Backlog: História e Tarefa nascem em Backlog no fluxo direcional (ver `docs/_meta/jira.KAN.md`) |

## Fila de operações pendentes (aplicar de cima para baixo)

1. `searchJiraIssuesUsingJql` por `project = KAN AND summary ~ "Confirmar senha"`: confirmar que ninguém
   criou o card à mão enquanto o conector estava fora. Se já existir, use essa key e pule o passo 2.
2. `createJiraIssue` com os campos acima. Medir o status no retorno, que deve ser Backlog.
3. Gravar a key na linha `**Jira**:` do BRIEF-058 e no log abaixo.
4. `createIssueLink` `Relates` para os cards da linha Link (conferir o nome do tipo em `getIssueLinkTypes`).
5. Mover o card só quando a implementação começar (trilho do CLAUDE.md, ids consultados por origem
   em `getTransitionsForJiraIssue`).

## Log (mais recente no topo)

- 2026-10-05: BRIEF-058 e este arquivo criados localmente, com o conector Atlassian sem acesso.
