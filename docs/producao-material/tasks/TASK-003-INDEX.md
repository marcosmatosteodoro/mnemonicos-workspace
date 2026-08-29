# Índice de tarefas do PLAN-003

**Total de tasks**: 16
**Tamanho dominante**: medium
**Convenções aplicadas**: branch única do épico `feat/producao-material-mnemora-studio` (estratégia `unica` — todas as fatias entram nela); Conventional Commits (sem automação de release); backend Jest 30 + ts-jest + supertest (`mnemonicos-backend/tests/{unit,integration}/`, env fictícia em `tests/setup-env.ts`); frontend Jest 30 via `next/jest` + Testing Library (`mnemonicos-frontend/`); `gates.security: true`; `gates.screenVerify` ativo (Playwright MCP) nas TASKs de tela (014, 015).

## Status agregado

- Todo: 7
- In Progress: 0
- Done: 9
- Blocked: 0

## Ordem de execução (waves)

### Wave 1 (fundação)
- [x] TASK-003-001 ✅ Done — Declarar as novas variáveis de ambiente da fatia (chore)
- [x] TASK-003-002 ✅ Done — Migração aditiva `add_session_and_user_disabled`
- [x] TASK-003-005 ✅ Done — Tipos de domínio espelhados nos dois repos

### Wave 2 (depende da Wave 1)
- [x] TASK-003-003 ✅ Done — Libs de cripto e auditoria (`password`, `tokens`, `audit`)
- [x] TASK-003-004 ✅ Done — Lógica pura de rotação de sessão (`session-rotation.ts`)
- [x] TASK-003-016 ✅ Done — Harness de teste de integração com banco (furo no plano, depende de 002)

### Wave 3 (depende da Wave 2)
- [x] TASK-003-006 ✅ Done — Serviço de autenticação (`auth.service.ts` + `auth.schema.ts`)
- [x] TASK-003-008 ✅ Done — Freio de login por chave composta (`login-rate-limit.ts`)
- [x] TASK-003-012 ✅ Done — Seed do primeiro ADMIN a partir de `env`

### Wave 4 (depende da Wave 3)
- [ ] TASK-003-007 ⏸ Todo — Middlewares `authenticate` / `authorize` + `Express.Request.auth`

### Wave 5 (depende da Wave 4)
- [ ] TASK-003-009 ⏸ Todo — Rotas de auth + cookies de sessão + `cookie-parser`
- [ ] TASK-003-010 ⏸ Todo — Gestão de contas por ADMIN (módulo `users/`)

### Wave 6 (depende da Wave 5)
- [ ] TASK-003-011 ⏸ Todo — Montagem deny-by-default em `routes.ts` + suíte de conformidade
- [ ] TASK-003-013 ⏸ Todo — Store do frontend (`api.ts` com re-auth + `proxy.ts`)

### Wave 7 (depende da Wave 6)
- [ ] TASK-003-014 ⏸ Todo — Tela de login
- [ ] TASK-003-015 ⏸ Todo — Shell da área interna

## Cobertura de FRs

| FR | TASKs |
|----|-------|
| FR-002-001 | TASK-003-006 |
| FR-002-002 | TASK-003-006 |
| FR-002-003 | TASK-003-004 |
| FR-002-004 | TASK-003-004 |
| FR-002-005 | TASK-003-004 |
| FR-002-006 | TASK-003-006 |
| FR-002-007 | TASK-003-006 |
| FR-002-008 | TASK-003-008 |
| FR-002-009 | TASK-003-014 |
| FR-002-010 | TASK-003-007 |
| FR-002-011 | TASK-003-007 |
| FR-002-012 | TASK-003-007, TASK-003-013 |
| FR-002-013 | TASK-003-015 |
| FR-002-014 | TASK-003-010 |
| FR-002-015 | TASK-003-010 |
| FR-002-016 | TASK-003-010 |
| FR-002-017 | TASK-003-010 |
| FR-002-018 | TASK-003-010 |
| FR-002-019 | TASK-003-010 |
| FR-002-020 | TASK-003-010 |
| FR-002-021 | TASK-003-012 |
| FR-002-022 | TASK-003-010 |
| FR-002-023 | TASK-003-015 |
| FR-002-024 | TASK-003-006 |

<!-- NFRs não entram nesta tabela (campo `Realiza (FRs)` só aceita IDs `FR-`). Cobertura de NFR
via AC nos Critérios de pronto: NFR-002-001 → AC-002-014 (TASK-003-011, TASK-003-007, TASK-003-009); NFR-002-002 →
AC-002-015 (TASK-003-007); NFR-002-003 → AC-002-024 (TASK-003-003, TASK-003-006, TASK-003-010); NFR-002-004
→ AC-002-024 (TASK-003-006, TASK-003-010); NFR-002-005 → AC-002-002/AC-002-024 (TASK-003-003); NFR-002-006 →
AC-002-003 (TASK-003-008); NFR-002-007 → AC-002-025 (TASK-003-005); NFR-002-008 → AC-002-001
(TASK-003-009); NFR-002-009 → item de idioma pt-BR (TASK-003-014). -->

## Cobertura de ACs

| AC | TASKs |
|----|-------|
| AC-002-001 | TASK-003-009 |
| AC-002-002 | TASK-003-003, TASK-003-006 |
| AC-002-003 | TASK-003-008 |
| AC-002-004 | TASK-003-004, TASK-003-006 |
| AC-002-005 | TASK-003-004, TASK-003-006 |
| AC-002-006 | TASK-003-004, TASK-003-006 |
| AC-002-007 | TASK-003-006 |
| AC-002-008 | TASK-003-006 |
| AC-002-009 | TASK-003-014 |
| AC-002-010 | TASK-003-007, TASK-003-011 |
| AC-002-011 | TASK-003-007 |
| AC-002-012 | TASK-003-007 |
| AC-002-013 | TASK-003-015 (gate 9 + gate 1) |
| AC-002-014 | TASK-003-011, TASK-003-007, TASK-003-009 |
| AC-002-015 | TASK-003-007 |
| AC-002-016 | TASK-003-010 |
| AC-002-017 | TASK-003-010 |
| AC-002-018 | TASK-003-010, TASK-003-011 |
| AC-002-019 | TASK-003-010 |
| AC-002-020 | TASK-003-010 |
| AC-002-021 | TASK-003-010 |
| AC-002-022 | TASK-003-010 |
| AC-002-023 | TASK-003-012 |
| AC-002-024 | TASK-003-003, TASK-003-006, TASK-003-010 |
| AC-002-025 | TASK-003-005 |
| AC-002-026 | TASK-003-004, TASK-003-006 |
| AC-002-027 | TASK-003-015 |
| AC-002-028 | TASK-003-013, TASK-003-014 |
| AC-002-029 | TASK-003-006 |

## Cobertura por funcionalidade

<!-- P = a FEAT é a Funcionalidade primária da TASK. TASKs 001, 002, 003, 005, 009 e 011 não
aparecem: `Realiza (FRs)` = `nenhuma` (chore ou só NFR via AC), sem FR que derive FEAT. -->

| FEAT | TASKs (P = primária) | Done |
|------|----------------------|------|
| FEAT-002-001 | TASK-003-004 (P), TASK-003-006 (P), TASK-003-008 (P), TASK-003-014 (P), TASK-003-015 | 0/5 |
| FEAT-002-002 | TASK-003-007 (P), TASK-003-013 (P), TASK-003-015 (P) | 0/3 |
| FEAT-002-003 | TASK-003-006, TASK-003-010 (P), TASK-003-012 (P) | 0/3 |
