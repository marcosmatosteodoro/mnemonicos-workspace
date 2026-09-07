# Índice de tarefas do PLAN-018

**Total de tasks**: 2
**Tamanho dominante**: small
**Convenções aplicadas**: derivadas da ficha (`keelson.config.json`) e do perfil
`guidelines/project/frontend/next-16.md` — Conventional Commits, `'use client'` só onde
há estado/evento, Jest 30 + Testing Library (`jsdom`, `next/jest`), branch única
`feat/campos-senha-toggle` executada em worktree isolado (`C:/kwt/kan72-toggle-senha`).

## Status agregado

- Todo: 2
- In Progress: 0
- Done: 0
- Blocked: 0

## Ordem de execução (waves)

### Wave 1 (paralelizável)
- [ ] TASK-018-001 ⏸ Todo — Criar o componente `PasswordField` com toggle de
      visibilidade

### Wave 2 (depende de Wave 1)
- [ ] TASK-018-002 ⏸ Todo — Integrar `PasswordField` no `LoginForm`

> Wave única de tamanho 1 em cada nível: a cadeia de dependência dos 2 COMPs do PLAN
> (COMP-018-002 → COMP-018-001, PLAN §3/§7) é linear, sem paralelismo real disponível
> nesta fatia.

## Cobertura de FRs

| FR | TASKs |
|----|-------|
| FR-016-001 | TASK-018-001, TASK-018-002 |
| FR-016-002 | TASK-018-001 |
| FR-016-003 | TASK-018-001 |
| FR-016-004 | TASK-018-001 |
| FR-016-005 | TASK-018-001 |
| FR-016-006 | TASK-018-001 |
| FR-016-007 | TASK-018-001, TASK-018-002 |

**NFRs** (não são aresta formal do grafo de TASK — campo `Realiza (FRs)` é FR-only;
provados via os ACs que os cobrem, tabela abaixo): NFR-016-001 → AC-016-004/010
(TASK-018-001) · NFR-016-002 → AC-016-008 (TASK-018-001) · NFR-016-003 → AC-016-007/009
(TASK-018-002) · NFR-016-004 → AC-016-005 (TASK-018-001).

## Cobertura de ACs

| AC | TASKs |
|----|-------|
| AC-016-001 | TASK-018-001 |
| AC-016-002 | TASK-018-001 |
| AC-016-003 | TASK-018-001 |
| AC-016-004 | TASK-018-001 |
| AC-016-005 | TASK-018-001 |
| AC-016-006 | TASK-018-001 (parte — implementação única, sem duplicação), TASK-018-002 (parte — LoginForm de fato consome) |
| AC-016-007 | TASK-018-002 |
| AC-016-008 | TASK-018-001 |
| AC-016-009 | TASK-018-002 |
| AC-016-010 | TASK-018-001 |

Cobertura total: 10/10 ACs, 7/7 FRs, 4/4 NFRs de SPEC-016 — sem FEATs (SPEC-016 não
declara FEATs §5), sem decomposição parcial (`--only` não usado). Todos os ACs fecham
por gate 1 (teste automatizado) — `gates.screenVerify` está ativo na ficha, mas nenhum AC
desta SPEC exige caminhada de tela: toggle síncrono, local, sem I/O (PLAN §1, "Estratégia
de teste"; DoD do PLAN, item 5).
