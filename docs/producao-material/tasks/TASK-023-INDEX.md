# Índice de tarefas do PLAN-023

**Total de tasks**: 17
**Tamanho dominante**: small (10 small · 7 medium)
**Convenções aplicadas**: derivadas da ficha (`keelson.config.json`) e dos perfis
`guidelines/project/backend/node-22.md` / `guidelines/project/frontend/next-16.md` —
Conventional Commits, camadas schema (Zod) → service (Prisma) → routes (Express) no
backend, Server/Client Components + RTK Query para estado de servidor no frontend. Branch
única: `feat/producao-material-mnemora-studio` (branch do épico MNEMORA STUDIO, Estratégia
unica — decisão 4.126, F5 é uma fatia do épico, nunca abre branch própria).

## Status agregado

- Todo: 10
- In Progress: 0
- Done: 7
- Blocked: 0

## Ordem de execução (waves)

### Wave 1 (paralelizável, setup-first) — ✅ concluída
- [x] TASK-023-001 ✅ Done — Migração de schema Prisma (`VisualAssociation`, FK, enum, LinkEvent) (fatia sensível — migração; aplicada ao DEV com autorização do Diretor)
- [x] TASK-023-002 ✅ Done — `image-signature.ts`: detecção de assinatura de bytes (fatia sensível — segurança; gate 8 aprovado)
- [x] TASK-023-003 ✅ Done — `visual-associations.schema.ts`: validação Zod
- [x] TASK-023-004 ✅ Done — Extensão `tira.schema.ts`: schema do vínculo
- [x] TASK-023-005 ✅ Done — Extensão `types/domain.ts` (frontend) — 1 retry (paridade cross-repo, achado do gate 1-7; campo trazido ao backend nesta wave, antecipando parte de TASK-023-011/017)

### Wave 2 (depende de Wave 1) — ✅ concluída
- [x] TASK-023-006 ✅ Done — `visual-association-storage.ts`: camada de acesso ao binário (bytea)
- [x] TASK-023-007 ✅ Done — Extensão `store/api.ts` (RTK Query)

### Wave 3 (depende de Wave 2)
- [ ] TASK-023-008 ⏸ Todo — Criar e editar associação visual (upload, CRUD write, guarda de escrita) (fatia sensível — upload + assinatura de bytes + autoria)
- [ ] TASK-023-009 ⏸ Todo — `visual-association-picker.tsx` (seletor reusável)

### Wave 4 (depende de Wave 3)
- [ ] TASK-023-010 ⏸ Todo — Remover associação visual com trava de vínculo (fatia sensível — guarda reusada + alcance)
- [ ] TASK-023-011 ⏸ Todo — Vínculo de associação visual a Quadro (link/unlink) (fatia sensível — reuso de guarda de F4 + regra de negócio central)
- [ ] TASK-023-012 ⏸ Todo — `visual-library-board.tsx` (client component — CRUD UI do acervo) (gate 9)
- [ ] TASK-023-013 ⏸ Todo — Enxerto em `mnemonic-strip-board.tsx` (vínculo/desvínculo por Quadro) (gate 9)

### Wave 5 (depende de Wave 4)
- [ ] TASK-023-014 ⏸ Todo — Listar/buscar/sugerir categoria da biblioteca (backend)
- [ ] TASK-023-015 ⏸ Todo — `(interno)/visual-library/page.tsx` (casca + correção do guard de navegação)

### Wave 6 (depende de Wave 5)
- [ ] TASK-023-016 ⏸ Todo — Entrega do binário da imagem (`GET /visual-associations/:id/image`)
- [ ] TASK-023-017 ⏸ Todo — Rede de paridade cross-repo (chore)

## Cobertura de FRs

| FR | TASKs |
|----|-------|
| FR-022-001 | TASK-023-002, TASK-023-008 |
| FR-022-002 | TASK-023-002, TASK-023-008 |
| FR-022-003 | TASK-023-008 |
| FR-022-004 | TASK-023-003, TASK-023-008 |
| FR-022-005 | TASK-023-012 |
| FR-022-006 | TASK-023-008, TASK-023-012 |
| FR-022-007 | TASK-023-010 |
| FR-022-008 | TASK-023-010 |
| FR-022-009 | TASK-023-008, TASK-023-012 |
| FR-022-010 | TASK-023-012, TASK-023-014, TASK-023-015 |
| FR-022-011 | TASK-023-012, TASK-023-014 |
| FR-022-012 | TASK-023-012, TASK-023-014 |
| FR-022-013 | TASK-023-009, TASK-023-011, TASK-023-013 |
| FR-022-014 | TASK-023-011 |
| FR-022-015 | TASK-023-011, TASK-023-013 |
| FR-022-016 | TASK-023-005, TASK-023-011, TASK-023-013 |
| FR-022-017 | TASK-023-013 |
| FR-022-018 | TASK-023-011 |
| FR-022-019 | TASK-023-010, TASK-023-011, TASK-023-014 |
| FR-022-020 | TASK-023-001, TASK-023-011 |
| FR-022-021 | TASK-023-011 |
| FR-022-022 | TASK-023-010, TASK-023-012 |
| FR-022-023 | TASK-023-008, TASK-023-010, TASK-023-011 |
| FR-022-024 | TASK-023-011 |
| FR-022-025 | TASK-023-012, TASK-023-014 |

**NFRs** (não são aresta formal do grafo de TASK — campo `Realiza (FRs)` é FR-only; provados
via os ACs que os cobrem): NFR-022-001 → AC-022-001/002 (TASK-023-002/008) · NFR-022-002 →
AC-022-002 (TASK-023-002) · NFR-022-003 → route-authz-matrix (TASK-023-008/010/011/014/016)
· NFR-022-004 → AC-022-003 (TASK-023-008) · NFR-022-005 → AC-022-023 (TASK-023-016) ·
NFR-022-006 → AC-022-024 (TASK-023-011) + rede de paridade (TASK-023-017) · NFR-022-007 →
AC-022-025 (TASK-023-014).

## Cobertura de ACs

| AC | TASKs |
|----|-------|
| AC-022-001 | TASK-023-002, TASK-023-008 |
| AC-022-002 | TASK-023-002, TASK-023-008 |
| AC-022-003 | TASK-023-008 |
| AC-022-004 | TASK-023-008 |
| AC-022-005 | TASK-023-012 |
| AC-022-006 | TASK-023-008, TASK-023-012 |
| AC-022-007 | TASK-023-010 |
| AC-022-008 | TASK-023-010 |
| AC-022-009 | TASK-023-012, TASK-023-014 |
| AC-022-010 | TASK-023-012, TASK-023-014 |
| AC-022-011 | TASK-023-009, TASK-023-011, TASK-023-013 |
| AC-022-012 | TASK-023-011, TASK-023-013 |
| AC-022-013 | TASK-023-011, TASK-023-013 |
| AC-022-014 | TASK-023-008, TASK-023-010, TASK-023-011, TASK-023-014, TASK-023-016 |
| AC-022-015 | TASK-023-011 |
| AC-022-016 | TASK-023-010, TASK-023-011, TASK-023-014 |
| AC-022-017 | TASK-023-001, TASK-023-013 |
| AC-022-018 | TASK-023-011, TASK-023-013 |
| AC-022-019 | TASK-023-010, TASK-023-012 |
| AC-022-020 | TASK-023-008, TASK-023-010, TASK-023-011 |
| AC-022-021 | TASK-023-011 |
| AC-022-022 | TASK-023-012, TASK-023-014 |
| AC-022-023 | TASK-023-016 |
| AC-022-024 | TASK-023-011 |
| AC-022-025 | TASK-023-014 |

## Cobertura por funcionalidade

| FEAT | TASKs (P = primária) | Done |
|------|----------------------|------|
| FEAT-022-001 (Gestão do acervo) | TASK-023-002 (P), TASK-023-003 (P), TASK-023-008 (P), TASK-023-010, TASK-023-012 (P) | 0/5 |
| FEAT-022-002 (Navegação e busca) | TASK-023-012, TASK-023-014 (P), TASK-023-015 (P) | 0/3 |
| FEAT-022-003 (Vínculo a Quadros) | TASK-023-001 (P), TASK-023-005 (P), TASK-023-008, TASK-023-009 (P), TASK-023-010 (P), TASK-023-011 (P), TASK-023-012, TASK-023-013 (P), TASK-023-014 (FR-022-019, transversal) | 0/9 |

Cobertura total: 25/25 ACs, 25/25 FRs, 7/7 NFRs de SPEC-022 — 3/3 FEATs cobertas, sem
decomposição parcial (`--only` não usado).
