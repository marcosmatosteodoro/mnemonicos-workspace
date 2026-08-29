# TASK-003-016: Harness de teste de integração com banco (furo no plano)

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: nenhuma
**Componente**: COMP-003-025
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: chore
**Status**: Done
**Data início**: 2026-08-28T23:46:24+00:00

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`chore:`) — sem automação de release
**Framework de teste**: Jest 30 + ts-jest + supertest. Este é o arquivo que **habilita** a camada de integração com banco real.

## Dependências

- **Depende de**: TASK-003-002
- **Bloqueia**: TASK-003-006, TASK-003-008, TASK-003-009, TASK-003-010, TASK-003-011, TASK-003-012

## Contexto

**Furo no plano descoberto em TASK-003-002**: PLAN-003 (§9 DoD) e os "Critérios de pronto" das
TASKs 006/008/009/010/011/012 assumem testes de integração contra um Postgres real
(`prisma.$transaction`, erro de constraint `@unique` P2002, matriz de rotas com sessão, seed
idempotente, fixture de 2 instâncias para o predicado de escopo). Mas
`mnemonicos-backend/tests/setup-env.ts` declara explicitamente *"o suite não abre conexão real
com o banco"* — `DATABASE_URL` é fictício, não há `globalSetup`/migrate/teardown, e o único teste
em `tests/integration/` (`health.test.ts`) não toca o banco. Mockar Prisma em toda a camada de
serviço tornaria os testes de segurança (rotação em transação, P2002, IDOR por escopo)
não-falsificáveis — exatamente o que a régua de verificação executável do `/keelson:tasks` proíbe.
Esta TASK entrega a infra mínima para os testes `*.integration.test.ts` rodarem contra o
Postgres do `docker-compose` local, sem quebrar a suíte unitária existente.

## Escopo

### Inclui
- `mnemonicos-backend/jest.integration.config.ts` — config Jest separada: `preset: 'ts-jest'`,
  `testMatch: ['**/*.integration.test.ts']`, `setupFiles: ['<rootDir>/tests/setup-env.integration.ts']`,
  `globalSetup: '<rootDir>/tests/integration/global-setup.ts'`,
  `globalTeardown: '<rootDir>/tests/integration/global-teardown.ts'`, `maxWorkers: 1` (runInBand — o
  banco de teste é compartilhado), `clearMocks: true`, `moduleNameMapper` idêntico ao `jest.config.ts`.
- `mnemonicos-backend/tests/setup-env.integration.ts` — igual ao `setup-env.ts` **exceto**
  `DATABASE_URL`/`DIRECT_URL` apontando para um banco **`mnemonicos_test`** no mesmo Postgres local
  (`postgresql://postgres:postgres@127.0.0.1:5432/mnemonicos_test?schema=public`), lido de
  `TEST_DATABASE_URL` do ambiente com esse default.
- `mnemonicos-backend/tests/integration/global-setup.ts` — cria o banco `mnemonicos_test` se não
  existir (conexão ao `postgres`/db `postgres`, `CREATE DATABASE`), roda `prisma migrate deploy`
  (ou `prisma db push --skip-generate`) contra ele. Idempotente.
- `mnemonicos-backend/tests/integration/global-teardown.ts` — encerra pools abertos; **não** dropa o
  banco (reuso entre execuções acelera).
- `mnemonicos-backend/tests/integration/db.ts` — helper: exporta `testPrisma` (um `PrismaClient` com
  o adapter `@prisma/adapter-pg` apontando para `TEST_DATABASE_URL`) e
  `resetDb(): Promise<void>` que faz `TRUNCATE "sessions", "users", ... RESTART IDENTITY CASCADE`
  em **todas** as tabelas do schema (derivar a lista de `information_schema` ou listar
  explicitamente). Cada arquivo `*.integration.test.ts` chama `resetDb()` em `beforeEach`.
- `mnemonicos-backend/package.json` — script `"test:integration": "jest --config jest.integration.config.ts --runInBand"`; ajustar `"test:ci"` para rodar `test` **e** `test:integration`; `"validate"` idem.
- `mnemonicos-backend/tests/integration/harness.integration.test.ts` — teste-fumaça do próprio
  harness: `resetDb()` deixa `sessions` e `users` vazias; `testPrisma.user.create` + `resetDb()` →
  contagem 0; um `testPrisma.session.create` com `accessTokenHash` duplicado → erro P2002 (prova
  que o `@unique` da migração de TASK-003-002 está no banco de teste — fecha o `fora_de_escopo`
  daquela TASK).

### Não inclui
- Qualquer teste de serviço/rota de auth (é das TASKs 006+).
- Reescrever a config unitária: só o mínimo em `jest.config.ts` (um `testPathIgnorePatterns` excluindo `*.integration.test.ts`) e em `tsconfig.json` (incluir o config novo no `include`) — necessidade técnica direta do critério "a suíte unitária não roda os integration", sancionada pelo gate.
- CI/pipeline externo (só os scripts npm).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `setup-env.integration.ts` e a config separada; garantir que `testMatch` do config unitário
   **exclui** `*.integration.test.ts` (adicionar `testPathIgnorePatterns` se preciso).
2. `global-setup.ts`: `CREATE DATABASE` condicional + `migrate deploy` via `execSync` no diretório do repo.
3. `db.ts`: `testPrisma` + `resetDb()` por `TRUNCATE ... RESTART IDENTITY CASCADE`.
4. Smoke test do harness.
5. `npm run db:up` já deixou o Postgres no ar (TASK-003-002).

## Critérios de pronto

- [ ] A suíte unitária existente continua verde e **não** roda os `*.integration.test.ts` — verificação executável: `npm --prefix mnemonicos-backend test` → `Tests: 22 passed` (ou o total vigente), nenhum arquivo `*.integration.test.ts` no output. Fixada antes do código.
- [ ] `test:integration` sobe, migra e roda contra `mnemonicos_test` — verificação executável: `npm --prefix mnemonicos-backend run test:integration` → `Tests: ≥3 passed` (o smoke test), exit 0, e `mnemonicos_test` existe no Postgres local. Baseline: antes desta TASK o comando não existe. Fixada antes do código.
- [ ] `resetDb()` zera as tabelas entre testes — verificação executável: no `harness.integration.test.ts`, `testPrisma.user.create(...)` num teste e contagem `=== 0` no `beforeEach` do seguinte. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] O `@unique` de `Session` da migração está no banco de teste (fecha o gap de TASK-003-002) — verificação executável: inserir duas `session` com o mesmo `accessTokenHash` → a 2ª lança `PrismaClientKnownRequestError` código `P2002`. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline no início).
- [ ] Padrão de commit respeitado (Conventional Commits `chore:`).
- [ ] Aderência à stack/perfil (`node-22.md` §7 — runner canônico Jest 30 + ts-jest; `src/lib/prisma.ts` é o único lugar com `new PrismaClient` **de produção** — o `testPrisma` é infra de teste, vive em `tests/`, documentado como tal).
- [ ] Code review aprovado.

## Riscos específicos

- `global-setup.ts` roda `migrate deploy` — se a migração de TASK-003-002 não estiver commitada/presente, o banco de teste nasce sem `sessions`. Depende de TASK-003-002 (declarado).
- `prisma.config.ts` usa `DIRECT_URL` para migrate; o `global-setup` deve exportar `DIRECT_URL` = `TEST_DATABASE_URL` antes do `migrate deploy`.
- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-backend/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-08-28T20:46:00-03:00
**Data conclusão**: 2026-08-28T21:50:00-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 254e00c · f956aec (retry)
**Jira**: KAN-8 (sub-task não criada — conector Jira caído; reconciliar via /keelson:jira-sync)
**Implementado por**: developer
**Revisado por**: code-reviewer (gates 1–7) · security-engineer (gate 8) — Wave 2, diff acumulado + delta do retry, re-review APROVADO
**Tentativas**: 2
**Cobertura final**: n/a (infra de teste)
**Arquivos modificados**:
  - mnemonicos-backend/jest.config.ts
  - mnemonicos-backend/jest.integration.config.ts
  - mnemonicos-backend/tsconfig.json
  - mnemonicos-backend/package.json
  - mnemonicos-backend/tests/setup-env.integration.ts
  - mnemonicos-backend/tests/integration/{db-url,db,global-setup,global-teardown,harness.integration.test}.ts
  - mnemonicos-backend/tests/unit/db-url-guard.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando — unit 68/68 (10 suítes) · integração 5/5
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado — re-review do delta APROVADO
- [x] ACs verificados — sem AC (chore); critérios de infra provados por execução — suíte unitária não roda os *.integration.test.ts; test:integration verde contra mnemonicos_test; resetDb() isola; P2002 do @unique de Session (fecha o gap de TASK-003-002); guarda fail-closed do alvo do banco (7 casos)
- [x] Segurança (gate 8): aprovado (Wave 2) — security-engineer, re-review APROVADO
- [x] Comportamento (gate 9): n/a — infra de teste, sem efeito observável (qa)

**Notas**: Retry pelos gates 6/7/8 da Wave 2: `setup-env.integration.ts` deriva de `setup-env.ts` (import + override só das URLs); `db-url.ts` ganha `assertDisposableTestDatabase` (fail-closed na carga: recusa banco ≠ mnemonicos_test / host não-loopback, sem ecoar credencial); docblock do runner registra o porquê de `--experimental-vm-modules`. Não-bloqueante para as próximas: a chamada de carga da guarda não tem prova própria (posição é estrutural); a suíte unitária passa a carregar `db-url.ts` (fail-closed atinge `npm test` também). Fecha o gap do `@unique` de Session herdado de TASK-003-002.
