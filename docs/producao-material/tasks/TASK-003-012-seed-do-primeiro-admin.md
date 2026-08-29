# TASK-003-012: Seed do primeiro ADMIN a partir de `env`

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: FR-002-021
**Funcionalidade**: FEAT-002-003 (primária)
**Componente**: COMP-003-018
**Wave**: 3
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 + ts-jest — integração em `mnemonicos-backend/tests/integration/` sobre Prisma real (Postgres do `docker-compose`). Gates: `npm --prefix mnemonicos-backend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: TASK-003-002, TASK-003-003, TASK-003-016
- **Bloqueia**: nenhuma

## Contexto

COMP-003-018 / DEC-003-008 / FR-002-021 / AC-002-023 / A-002-010. `prisma/seed.ts` hoje não cria usuário. Esta task faz o `main()` criar **exatamente um** ADMIN inicial a partir de `env.SEED_ADMIN_EMAIL` + `env.SEED_ADMIN_PASSWORD`, de forma idempotente (guarda `count(User, role=ADMIN) === 0`), e terminar sem criar quando as credenciais de bootstrap não estão configuradas (inclusive config parcial) — **nunca** senha embutida no código. Fatia sensível (bootstrap de permissão) → `security-engineer`.

## Escopo

### Inclui
- `mnemonicos-backend/prisma/seed.ts` — no `main()` (antes ou depois do seed de conteúdo): se `env.SEED_ADMIN_EMAIL` **e** `env.SEED_ADMIN_PASSWORD` presentes **e** `count(User, role=ADMIN) === 0` → `prisma.user.create` com `role: 'ADMIN'`, `passwordHash` de `hashPassword`. Config parcial (só uma das duas) → tratada como ausente. Ausentes → `console.log` informativo e segue sem criar. Nenhuma senha embutida.
- `mnemonicos-backend/tests/integration/seed.test.ts` — exercita a rotina de seed do ADMIN isolada (`seedAdmin()` ou equivalente exportado).
- Meio de execução dos `*.integration.test.ts` desta TASK: o harness de TASK-003-016 — config `jest.integration.config.ts`, helper `tests/integration/db.ts` (`testPrisma` + `resetDb()` no `beforeEach`), comando `npm --prefix mnemonicos-backend run test:integration`.

### Não inclui
- Criação de contas por rota (TASK-003-010).
- O seed de conteúdo existente (Direito Administrativo/Constitucional — mantido).
- As chaves `SEED_ADMIN_*` no `.env.example` (TASK-003-001).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Extrair a rotina de seed do ADMIN em função testável.
2. Guarda: só cria se as **duas** vars presentes **e** `count(ADMIN) === 0`.
3. `hashPassword(env.SEED_ADMIN_PASSWORD)` — nunca literal.
4. Teste de integração cobrindo os quatro cenários: env completa, rerun idempotente, env ausente, env parcial.

## Critérios de pronto

- [ ] Testes cobrem AC-002-023 (com env → exatamente 1 ADMIN; sem env → nenhum ADMIN, sem senha embutida) — verificação executável: `npm --prefix mnemonicos-backend test -- seed` → (a) env setada + base sem ADMIN → após a rotina, `count(User, role=ADMIN) === 1` e `verifyPassword(env.SEED_ADMIN_PASSWORD, hash)` → `true`; (b) rodar de novo → ainda `=== 1` (idempotência); (c) env ausente → `count(User, role=ADMIN) === 0` (uma senha embutida como fallback faria este caso falhar com 1 ADMIN criado); (d) config **parcial** (só `SEED_ADMIN_EMAIL` **ou** só `SEED_ADMIN_PASSWORD`) → tratada como ausente: **nenhum** ADMIN criado, nenhuma senha default (`Tests: ≥1 passed` para o caso parcial). `Tests: ≥4 passed` no total. Fixada antes do código.
- [ ] O seed recusa o valor-placeholder do `.env.example` (herdado do gate 8 da Wave 1 — `SEED_ADMIN_PASSWORD` do `.env.example` é utilizável: 38 chars, passa `.min(12)`, está no histórico público do repo → seria credencial default da conta de maior privilégio) — verificação executável: `npm --prefix mnemonicos-backend test -- seed` → com `SEED_ADMIN_PASSWORD` igual ao literal exato de `mnemonicos-backend/.env.example`, a rotina **aborta** citando o nome da variável (sem o valor) e **nenhum** ADMIN é criado; a mutação que remove essa recusa deixa o teste vermelho. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md`, §6.4 — bootstrap sem segredo embutido; README do repo vence em conflito).
- [ ] Code review aprovado.

## Riscos específicos

- Em CI/dev sem as vars, nenhum ADMIN é criado — comportamento esperado; o primeiro acesso do ambiente exige as vars no `env` e um rerun do seed.
- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-backend/prisma/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-08-29T02:02:00-03:00
**Data conclusão**: 2026-08-29T08:45:00-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 8efc829
**Jira**: KAN-22
**Implementado por**: developer
**Revisado por**: code-reviewer (1–7) · security-engineer (8) · performance-engineer (10) — Wave 3, diff acumulado + delta do retry, re-review APROVADO nos três
**Tentativas**: 1
**Cobertura final**: n/a
**Arquivos modificados**:
  - mnemonicos-backend/prisma/seed-admin.ts (novo)
  - mnemonicos-backend/prisma/seed.ts
  - mnemonicos-backend/tests/integration/seed-admin.integration.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando — unit 85/85 · integração 46/46
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado — re-review do delta APROVADO
- [x] ACs verificados — AC-002-023 (env completa → 1 ADMIN; ausente/parcial → 0; idempotente) + recusa do placeholder de SEED_ADMIN_PASSWORD do .env.example (herdado do gate 8 da Wave 1), com guarda mutation-verified
- [x] Segurança (gate 8): aprovado (Wave 3) — se: nunca senha embutida; config parcial = ausente; placeholder recusado citando o nome sem ecoar o valor
- [ ] Comportamento (gate 9): pendente — FEAT-002-003 completa no fim da Wave 5
- [x] Performance (gate 10): aprovado (Wave 3) — pe: `count({ where: { role: 'ADMIN' } })`, não findMany; bootstrap 1×, fora do caminho quente

**Notas**: `seedAdmin(client, credentials?)` extraído para `prisma/seed-admin.ts` (injeção para testar sem rodar o seed de conteúdo). O seed de conteúdo (Direito Administrativo/Constitucional) preservado. Sem retry — passou nos 3 gates da rodada da Wave 3 na 1ª tentativa.
