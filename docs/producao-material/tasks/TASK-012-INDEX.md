# Índice de tarefas do PLAN-012

**Total de tasks**: 13
**Tamanho dominante**: small (8 small · 5 medium)
**Convenções aplicadas**: derivadas da ficha (`keelson.config.json`) e dos perfis
`guidelines/project/backend/node-22.md` / `guidelines/project/frontend/next-16.md` —
Conventional Commits, camadas schema (Zod) → service (Prisma) → routes (Express) no
backend, Server Components por padrão + RTK Query para estado de servidor no frontend.

## Status agregado

- Todo: 4
- In Progress: 0
- Done: 9
- Blocked: 0

## Ordem de execução (waves)

### Wave 1 (paralelizável, setup-first) — ✅ concluída
- [x] TASK-012-001 ✅ Done — Migrar schema: `MnemonicStrip`/`MnemonicFrame` + `TIRA_MNEMONICA` aditivo (fatia sensível — migração)
- [x] TASK-012-002 ✅ Done — Exportar `assertRawContentReachable` de `contents.service.ts` (fatia sensível — segurança)
- [x] TASK-012-003 ✅ Done — Criar `tira.schema.ts` — validação Zod de Quadro
- [x] TASK-012-009 ✅ Done — Estender `types/domain.ts` (frontend) com `MnemonicStrip`/`MnemonicFrame`

### Wave 2 (depende de Wave 1) — ✅ concluída
- [x] TASK-012-004 ✅ Done — Estender `domain/types.ts` (backend) com `TIRA_MNEMONICA` e confirmar paridade
- [x] TASK-012-005 ✅ Done — Abrir a Tira mnemônica — geração idempotente e leitura
- [x] TASK-012-010 ✅ Done — Estender `store/api.ts` com endpoints RTK Query da Tira

### Wave 3 (depende de Wave 2) — ✅ concluída
- [x] TASK-012-006 ✅ Done — Reindexar posições em duas fases e reordenar Quadros (fatia sensível — DEC-012-003/RISK-011-003)
- [x] TASK-012-011 ✅ Done — Criar `tira-frontend-contract.test.ts` — paridade cross-repo

### Wave 4 (depende de Wave 3)
- [ ] TASK-012-007 ⏸ Todo — CRUD de Quadro — adicionar, editar e remover

### Wave 5 (depende de Wave 4)
- [ ] TASK-012-008 ⏸ Todo — Expor `tira.routes.ts` sob a barreira EDITOR/ADMIN (fatia sensível — gate 8 obrigatório)

### Wave 6 (depende de Wave 5 e Wave 2)
- [ ] TASK-012-012 ⏸ Todo — Construir a tela da Tira mnemônica (quadro a quadro) (gate 9 — screenVerify)

### Wave 7 (depende de Wave 6)
- [ ] TASK-012-013 ⏸ Todo — Adicionar navegação condicional da Quebra da regra para a Tira

## Cobertura de FRs

| FR | TASKs |
|----|-------|
| FR-011-001 | TASK-012-005, TASK-012-008, TASK-012-011, TASK-012-012, TASK-012-013 |
| FR-011-002 | TASK-012-005, TASK-012-008 |
| FR-011-003 | TASK-012-003, TASK-012-007, TASK-012-008, TASK-012-010, TASK-012-011, TASK-012-012 |
| FR-011-004 | TASK-012-003, TASK-012-007, TASK-012-008, TASK-012-010, TASK-012-011, TASK-012-012 |
| FR-011-005 | TASK-012-007, TASK-012-008, TASK-012-010, TASK-012-011, TASK-012-012 |
| FR-011-006 | TASK-012-003, TASK-012-006, TASK-012-008, TASK-012-010, TASK-012-011, TASK-012-012 |
| FR-011-007 | TASK-012-005, TASK-012-007, TASK-012-008, TASK-012-010, TASK-012-011, TASK-012-012 |
| FR-011-008 | TASK-012-005 |
| FR-011-009 | TASK-012-006, TASK-012-007 |
| FR-011-010 | TASK-012-008, TASK-012-012 |
| FR-011-011 | TASK-012-012 |

**NFRs** (não são aresta formal do grafo de TASK — campo `Realiza (FRs)` é FR-only,
`graph.sh:371`; provados via os ACs que os cobrem, tabela abaixo): NFR-011-001 →
AC-011-017/022 (TASK-012-005/006/007/008) · NFR-011-002 → AC-011-010/011 (TASK-012-006) ·
NFR-011-003 → AC-011-015 (TASK-012-005/006/007) · NFR-011-004 → AC-011-018 (TASK-012-004) ·
NFR-011-005 → AC-011-019 (TASK-012-003/012) · NFR-011-006 → AC-011-020 (TASK-012-005/006/007).

## Cobertura de ACs

| AC | TASKs |
|----|-------|
| AC-011-001 | TASK-012-005, TASK-012-012 |
| AC-011-002 | TASK-012-005 |
| AC-011-003 | TASK-012-005, TASK-012-012 |
| AC-011-004 | TASK-012-007, TASK-012-012 |
| AC-011-005 | TASK-012-007, TASK-012-012 |
| AC-011-006 | TASK-012-007, TASK-012-012 |
| AC-011-007 | TASK-012-007, TASK-012-012 |
| AC-011-008 | TASK-012-007, TASK-012-012 |
| AC-011-009 | TASK-012-007, TASK-012-012 |
| AC-011-010 | TASK-012-006, TASK-012-012 |
| AC-011-011 | TASK-012-006, TASK-012-012 |
| AC-011-012 | TASK-012-007, TASK-012-012 |
| AC-011-013 | TASK-012-005 |
| AC-011-014 | TASK-012-006, TASK-012-007 |
| AC-011-015 | TASK-012-005, TASK-012-006, TASK-012-007 |
| AC-011-016 | TASK-012-008, TASK-012-012 |
| AC-011-017 | TASK-012-008, TASK-012-012 |
| AC-011-018 | TASK-012-004 |
| AC-011-019 | TASK-012-012 |
| AC-011-020 | TASK-012-005, TASK-012-006, TASK-012-007 |
| AC-011-021 | TASK-012-005 |
| AC-011-022 | TASK-012-005, TASK-012-006, TASK-012-007, TASK-012-008 |
| AC-011-023 | TASK-012-005, TASK-012-008, TASK-012-012 (gate 9), TASK-012-013 |
| AC-011-024 | TASK-012-007, TASK-012-012 |
| AC-011-025 | TASK-012-005 |

Cobertura total: 25/25 ACs, 11/11 FRs, 6/6 NFRs de SPEC-011 — sem FEATs (fluxo único,
A-011-010), sem decomposição parcial (`--only` não usado).
