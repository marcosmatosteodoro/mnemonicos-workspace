# Índice de tarefas do PLAN-006

**Total de tasks**: 14
**Tamanho dominante**: medium (10 medium, 4 small)
**Convenções aplicadas**: derivadas da ficha/perfil — Conventional Commits; branch única do épico `feat/producao-material-mnemora-studio` (`git.branchStrategy: unica`); closure commita TASK a TASK; testes backend Jest + supertest (integração sobre Postgres `test:integration`), frontend Jest + Testing Library (jsdom); `gates.screenVerify` ativo.

## Status agregado

- Todo: 3
- In Progress: 0
- Done: 11
- Blocked: 0

## Ordem de execução (waves)

### Wave 1 (sequencial — migração força a wave) — ✅ concluída 2026-09-04
- [x] TASK-006-001 ✅ Done — Migrar o schema Prisma: enums e models de Conteúdo bruto e Quebra da regra
- [x] TASK-006-002 ✅ Done — Consolidar `Paginated<T>` no domínio e estender `GET /disciplines` com temas
- [x] TASK-006-003 ✅ Done — Registrar o segmento de rota `content` na área interna

### Wave 2 (paralela — territórios disjuntos) — ✅ concluída 2026-09-05
- [x] TASK-006-004 ✅ Done — Espelhar os tipos de domínio cross-repo (enums, interfaces, rótulos pt-BR)
- [x] TASK-006-005 ✅ Done — Trocar a semente para Obrigação Tributária + EDITOR de dev
- [x] TASK-006-006 ✅ Done — `contents.service` + `contents.schema`: ciclo de vida do Conteúdo bruto

### Wave 3 (paralela parcial — T007/T008/T010 disjuntos, T009 sequencial após T008 por overlap de arquivo) — ✅ concluída 2026-09-05 (1 retry consolidado)
- [x] TASK-006-007 ✅ Done — Estender a rede de paridade cross-repo aos dois enums novos
- [x] TASK-006-008 ✅ Done — `contents.service`: listar com alcance, ordenação determinística e resumo
- [x] TASK-006-009 ✅ Done — `contents.service`: Quebra da regra — upsert 1:1, obrigatoriedade e inalcançabilidade
- [x] TASK-006-010 ✅ Done — Sanear e estender `src/store/api.ts` (RTK Query)

### Wave 4 (depende de Wave 3) — ✅ concluída 2026-09-05 (1 retry test-only)
- [x] TASK-006-011 ✅ Done — `contents.routes.ts`: 7 rotas sob a barreira + tripwire 12→19 + `contents.integration.test.ts`

### Wave 5 (depende de Wave 4)
- [ ] TASK-006-012 ⏸ Todo — Tela de listagem de Conteúdos brutos
- [ ] TASK-006-013 ⏸ Todo — Formulário de Conteúdo bruto: criação, edição e remoção
- [ ] TASK-006-014 ⏸ Todo — Tela da Quebra da regra

## Cobertura de FRs

| FR | TASKs |
|----|-------|
| FR-005-001 | TASK-006-001, TASK-006-006, TASK-006-011 |
| FR-005-002 | TASK-006-006 |
| FR-005-003 | TASK-006-006, TASK-006-013 |
| FR-005-004 | TASK-006-013 |
| FR-005-005 | TASK-006-008, TASK-006-010, TASK-006-012 |
| FR-005-006 | TASK-006-006, TASK-006-011, TASK-006-013 |
| FR-005-007 | TASK-006-006, TASK-006-013 |
| FR-005-008 | TASK-006-006, TASK-006-011 |
| FR-005-009 | TASK-006-013 |
| FR-005-010 | TASK-006-001, TASK-006-006, TASK-006-013 |
| FR-005-011 | TASK-006-006 |
| FR-005-012 | TASK-006-008, TASK-006-012, TASK-006-013 |
| FR-005-013 | TASK-006-001, TASK-006-006 |
| FR-005-014 | TASK-006-001, TASK-006-009 |
| FR-005-015 | TASK-006-001, TASK-006-009 |
| FR-005-016 | TASK-006-009, TASK-006-011 |
| FR-005-017 | TASK-006-009, TASK-006-014 |
| FR-005-018 | TASK-006-014 |
| FR-005-019 | TASK-006-009, TASK-006-010, TASK-006-014 |
| FR-005-020 | TASK-006-009, TASK-006-014 |
| FR-005-021 | TASK-006-008, TASK-006-012 |
| FR-005-022 | TASK-006-012, TASK-006-013 |
| FR-005-023 | TASK-006-012 |
| FR-005-024 | TASK-006-002, TASK-006-008, TASK-006-012 |

## Cobertura de NFRs

| NFR | TASKs |
|-----|-------|
| NFR-005-001 | TASK-006-003, TASK-006-011 |
| NFR-005-002 | TASK-006-004, TASK-006-012, TASK-006-013, TASK-006-014 |
| NFR-005-003 | TASK-006-005 |
| NFR-005-004 | TASK-006-002, TASK-006-008, TASK-006-010 |
| NFR-005-005 | TASK-006-004, TASK-006-007 |
| NFR-005-006 | TASK-006-006, TASK-006-009, TASK-006-011 |
| NFR-005-007 | TASK-006-001, TASK-006-005 |

## Cobertura de ACs

| AC | TASKs |
|----|-------|
| AC-005-001 | TASK-006-006, TASK-006-008 |
| AC-005-002 | TASK-006-006, TASK-006-013 |
| AC-005-003 | TASK-006-006 |
| AC-005-004 | TASK-006-002, TASK-006-006, TASK-006-013 |
| AC-005-005 | TASK-006-013 |
| AC-005-006 | TASK-006-013 |
| AC-005-007 | TASK-006-013 |
| AC-005-008 | TASK-006-006, TASK-006-013 |
| AC-005-009 | TASK-006-006, TASK-006-013 |
| AC-005-010 | TASK-006-013 |
| AC-005-011 | TASK-006-013 |
| AC-005-012 | TASK-006-013 |
| AC-005-013 | TASK-006-006, TASK-006-009 |
| AC-005-014 | TASK-006-006, TASK-006-013 |
| AC-005-015 | TASK-006-006, TASK-006-013 |
| AC-005-016 | TASK-006-008, TASK-006-011, TASK-006-012 |
| AC-005-018 | TASK-006-008, TASK-006-012 |
| AC-005-019 | TASK-006-009, TASK-006-014 |
| AC-005-020 | TASK-006-009 |
| AC-005-021 | TASK-006-009 |
| AC-005-022 | TASK-006-009, TASK-006-013, TASK-006-014 |
| AC-005-023 | TASK-006-014 |
| AC-005-024 | TASK-006-009, TASK-006-014 |
| AC-005-025 | TASK-006-008, TASK-006-012 |
| AC-005-026 | TASK-006-011 |
| AC-005-027 | TASK-006-005 |
| AC-005-028 | TASK-006-010 |
| AC-005-029 | TASK-006-012, TASK-006-013, TASK-006-014 |
| AC-005-030 | TASK-006-007 |
| AC-005-031 | TASK-006-009, TASK-006-011 |
| AC-005-032 | TASK-006-001 |
| AC-005-033 | TASK-006-012, TASK-006-013 |
| AC-005-034 | TASK-006-012 |
| AC-005-035 | TASK-006-008 |
| AC-005-036 | TASK-006-006 |
| AC-005-037 | TASK-006-006, TASK-006-009, TASK-006-011, TASK-006-013 |

> **AC-005-017** — vão de numeração intencional. A exibição da prioridade de apresentação (Alta/Média/Baixa) saiu de F2 (SPEC-005 §4.2; PLAN-006 DEC-006-009; A-005-001 permanece selado como premissa, não como código). Será provado em **F10**. Nenhuma TASK de PLAN-006 o cobre — correto.

## Cobertura por funcionalidade

| FEAT | TASKs (P = primária) | Done |
|------|----------------------|------|
| FEAT-005-001 | TASK-006-001 (P), TASK-006-002 (P), TASK-006-006 (P), TASK-006-008 (P), TASK-006-010, TASK-006-011 (P), TASK-006-012 (P), TASK-006-013 (P) | 6/8 |
| FEAT-005-002 | TASK-006-001, TASK-006-008, TASK-006-009 (P), TASK-006-010, TASK-006-011, TASK-006-012, TASK-006-013, TASK-006-014 (P) | 5/8 |
