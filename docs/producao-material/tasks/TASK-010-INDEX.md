# Índice de tarefas do PLAN-010

**Total de tasks**: 3
**Tamanho dominante**: medium
**Convenções aplicadas**: branch única `feat/producao-material-mnemora-studio`
(`git.branchStrategy: unica`, `git.branchNaming: slug`); Conventional Commits
(`commit.convention: conventional`); Jest 30 + ts-jest (unit `npm --prefix
mnemonicos-backend test`; integração `npm --prefix mnemonicos-backend run
test:integration`); sem componente frontend (mecanismo 100% backend, sem UI —
A-009-004/A-009-005); nenhuma TASK gera Roteiro do gate 9.

## Status agregado

- Todo: 0
- In Progress: 0
- Done: 3
- Blocked: 0

## Ordem de execução (waves)

### Wave 1 (setup-first — migração) — ✅ concluída 2026-09-06
- [x] TASK-010-001 ✅ Done

### Wave 2 (depende de Wave 1) — ✅ concluída 2026-09-06
- [x] TASK-010-002 ✅ Done

### Wave 3 (depende de Wave 2) — ✅ concluída 2026-09-06
- [x] TASK-010-003 ✅ Done

## Cobertura de FRs

| FR | TASKs |
|----|-------|
| FR-009-001 | TASK-010-003 |
| FR-009-002 | TASK-010-003 |
| FR-009-003 | TASK-010-003 |
| FR-009-004 | TASK-010-003 |
| FR-009-005 | TASK-010-003 |
| FR-009-006 | TASK-010-002 |
| FR-009-007 | TASK-010-002 |
| FR-009-008 | TASK-010-001 |
| FR-009-009 | TASK-010-003 |
| FR-009-010 | TASK-010-002 |

## Cobertura de ACs

| AC | TASKs |
|----|-------|
| AC-009-001 | TASK-010-003 |
| AC-009-002 | TASK-010-003 |
| AC-009-003 | TASK-010-003 |
| AC-009-004 | TASK-010-003 |
| AC-009-005 | TASK-010-003 |
| AC-009-006 | TASK-010-002 |
| AC-009-007 | TASK-010-001 (parte — FK Restrict/sobrevivência), TASK-010-003 (parte — nenhum evento novo na remoção) |
| AC-009-008 | TASK-010-001, TASK-010-002 |
| AC-009-009 | TASK-010-003 |
| AC-009-010 | TASK-010-003 |

<!-- Sem seção "Cobertura por funcionalidade": SPEC-009 não declara FEATs (§5 sem heading `### FEAT-`) — a funcionalidade é a própria SPEC. -->
