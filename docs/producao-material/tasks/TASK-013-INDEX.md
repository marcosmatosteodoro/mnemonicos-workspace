# Índice de tarefas do PLAN-013

**Total de tasks**: 6
**Tamanho dominante**: small
**Convenções aplicadas**: Conventional Commits · Jest 30 + Testing Library (`jsdom`,
`next/jest`) · branch única `feat/producao-material-pwa-support`, executada em worktree
isolado (`C:/kwt/pwa`) — nunca na working tree principal
(`mnemonicos-frontend/`), onde PLAN-012/F4 executa concorrentemente.

## Status agregado

- Todo: 2
- In Progress: 0
- Done: 4
- Blocked: 0

## Ordem de execução (waves)

### Wave 1 (paralelizável)
- [x] TASK-013-001 ✅ Done — Criar conjunto de ícones estáticos do app-shell

### Wave 2 (depende de Wave 1)
- [x] TASK-013-002 ✅ Done — Criar manifesto de aplicação (`app/manifest.ts`)

### Wave 3 (depende de Wave 2)
- [x] TASK-013-003 ✅ Done — Service worker: precache do app-shell e política de fetch

### Wave 4 (depende de Wave 3)
- [x] TASK-013-004 ✅ Done — Service worker: ciclo de atualização e kill-switch

### Wave 5 (depende de Wave 4)
- [ ] TASK-013-005 ⏸ Todo — Registro do service worker e verificação de instalabilidade

### Wave 6 (depende de Wave 5)
- [ ] TASK-013-006 ⏸ Todo — Verificação de não-regressão de sessão com SW ativo (fatia
      sensível)

> Waves de tamanho 1: a cadeia de dependência de componentes do PLAN (COMP-013-002 →
> COMP-013-001 → COMP-013-003 → COMP-013-004) é linear (PLAN §3/§7), sem paralelismo real
> disponível nesta fatia.

## Cobertura de FRs

| FR | TASKs |
|----|-------|
| FR-013-001 | TASK-013-001, TASK-013-002, TASK-013-003, TASK-013-005 |
| FR-013-002 | TASK-013-002, TASK-013-005 |
| FR-013-003 | TASK-013-001, TASK-013-002 |
| FR-013-004 | TASK-013-001, TASK-013-002 |
| FR-013-005 | TASK-013-003, TASK-013-004, TASK-013-005 |
| FR-013-006 | TASK-013-004 |

## Cobertura de ACs

| AC | TASKs | Gate |
|----|-------|------|
| AC-013-001 | TASK-013-005 | 9 (screenVerify) |
| AC-013-002 | TASK-013-001 (parte — dimensão dos ícones), TASK-013-005 | 9 (screenVerify) |
| AC-013-003 | TASK-013-005 | 1 |
| AC-013-004 | TASK-013-003 | 1 |
| AC-013-005 | TASK-013-006 | 9 (screenVerify) |
| AC-013-006 | TASK-013-004 | 1 |
| AC-013-007 | TASK-013-005 | 9 (screenVerify) |
| AC-013-008 | TASK-013-003 | 1 |
| AC-013-009 | TASK-013-004 | 1 |
| AC-013-010 | TASK-013-002 (parte — manifesto), TASK-013-003 (parte — precache) | 1 |
| AC-013-011 | TASK-013-006 | 9 (screenVerify) |
| AC-013-012 | TASK-013-004 | 1 |

> SPEC-013 não declara FEATs (§5) — sem seção "Cobertura por funcionalidade" (Etapa 4,
> nota do contrato).
