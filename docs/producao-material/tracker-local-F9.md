# Tracker local — F9 (SPEC-032 / PLAN-033)

Registro das operações de Jira que ficaram por fazer, porque esta sessão não tem acesso ao
conector Atlassian. Nada aqui foi aplicado ao quadro `KAN`. Quando o acesso voltar, rode
`/keelson:jira-sync producao-material --dry-run` e aplique a partir desta lista. Ids de
tipo e transição medidos neste board: `CLAUDE.md` do workspace e `docs/_meta/jira.KAN.md`.

## Estruturas a criar

| Artefato | Tipo Jira | Pai | Estado alvo agora |
|---|---|---|---|
| SPEC-032 — Controle de qualidade e gate de versão aprovada | Epic (`10006`) | — (fatia 9 do épico KAN-6) | intocado pelo ciclo |
| FEAT-032-001 — Aprovação da Versão vigente com checklist e segregação de funções | História (`10009`) | Epic da SPEC-032 | `21` Em andamento |
| FEAT-032-002 — Carimbo de Versão aprovada no PDF exportado | História (`10009`) | Epic da SPEC-032 | `21` Em andamento |
| TASK-033-001 — Migração de aprovação de Versão | Subtask (`10007`) | FEAT-032-001 | `41` Concluído |
| TASK-033-002 — Sinal de alteração da Tira mnemônica | Subtask (`10007`) | FEAT-032-001 | `41` Concluído |
| TASK-033-003 — Aprovação de Versão (backend) | Subtask (`10007`) | FEAT-032-001 | `21` Em andamento |
| TASK-033-004 — Leitura do estado de aprovação | Subtask (`10007`) | FEAT-032-001 | `11` Tarefas pendentes |
| TASK-033-005 — Carimbo de aprovação no PDF | Subtask (`10007`) | FEAT-032-002 | `21` Em andamento |
| TASK-033-006 — Tipos e mutation de aprovação (frontend) | Subtask (`10007`) | FEAT-032-001 | `11` Tarefas pendentes |
| TASK-033-007 — Painel de aprovação (frontend) | Subtask (`10007`) | FEAT-032-001 | `11` Tarefas pendentes |

Teto do §9: nenhuma História passa de `31` Em análise pelo ciclo. `41` é ato do Diretor
depois do merge.

## Log de operações pendentes (mais recente no topo)

- 2026-09-29 20:31: retomada da Wave 2 — TASK-033-003/005 seguem em `21`; Histórias em `21`.
- 2026-09-27: Wave 1 fechada — TASK-033-001/002 → `41` Concluído (closure `723805a`).
- 2026-09-27: largada da F9 sem raiz no tracker — conector MCP Atlassian sem autenticação
  (degradação registrada no ledger da sessão `b1505f46`).
