# TASK-003-008: Freio de login por chave composta (`login-rate-limit.ts`)

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: FR-002-008
**Funcionalidade**: FEAT-002-001 (primária)
**Componente**: COMP-003-009
**Wave**: 3
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 + ts-jest + supertest — integração em `mnemonicos-backend/tests/integration/`. Gates: `npm --prefix mnemonicos-backend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: TASK-003-003, TASK-003-016
- **Bloqueia**: TASK-003-009

## Contexto

COMP-003-009 / DEC-003-006 / NFR-002-006 / A-002-020. Dois freios `express-rate-limit` dedicados a `POST /auth/login` — por conta e por origem — mais estritos que o limite global, **sem** bloqueio duro de conta, com evento de auditoria no disparo. `express-rate-limit` já está instalado (usado no limite global em `src/app.ts`) — reutilizado, não readicionado. Fatia sensível (defesa contra força bruta) → `security-engineer`.

## Escopo

### Inclui
- `mnemonicos-backend/src/modules/auth/login-rate-limit.ts` — `loginRateLimiters: RequestHandler[]`:
  - (a) por conta: `keyGenerator` = e-mail normalizado do corpo, limite estrito (default 5 / 15 min);
  - (b) por origem: `keyGenerator` = `req.ip`, limite frouxo (default 30 / 15 min);
  - ambos `skip: () => isTest`, `standardHeaders`, resposta 429 com `Retry-After`, `handler` que chama `recordAuthEvent({ type: 'login.throttled', ... })`. Sem `store` compartilhado (dívida conhecida — TRISK-003-001). Limiares default afináveis por `env`.
- `mnemonicos-backend/tests/integration/login-rate-limit.test.ts` (o `skip` de teste é desligado nesse arquivo para exercitar o freio).
- Meio de execução dos `*.integration.test.ts` desta TASK: o harness de TASK-003-016 — config `jest.integration.config.ts`, helper `tests/integration/db.ts` (`testPrisma` + `resetDb()` no `beforeEach`), comando `npm --prefix mnemonicos-backend run test:integration`.

### Não inclui
- Montar os limiters na rota `POST /auth/login` (TASK-003-009).
- `store` compartilhado multi-instância (TRISK-003-001 — fora do escopo de F1).
- O limite global da API (já em `src/app.ts`).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Duas instâncias `rateLimit` com os `keyGenerator` distintos e limiares de `env` (com default).
2. `handler` comum que emite `recordAuthEvent('login.throttled')` e responde 429 + `Retry-After`.
3. Teste de integração com fake timers para exercitar janela e reset.

## Critérios de pronto

- [ ] Testes cobrem AC-002-003 (limiar por conta e por origem; sem lockout; auditoria; contas legítimas seguem autenticando) — verificação executável: `npm --prefix mnemonicos-backend test -- login-rate-limit` → N+1 tentativas para a conta A da mesma origem → 429 + header `Retry-After` na que dispara; conta B legítima da **mesma** origem → 200 enquanto o limiar dela não estoura; conta A de **outra** origem (`X-Forwarded-For` distinto, `trust proxy: 1`) → 200; o spy de `recordAuthEvent` recebeu `login.throttled`. `Tests: ≥3 passed`. Fixada antes do código.
- [ ] Sem bloqueio duro de conta — verificação executável: `npm --prefix mnemonicos-backend test -- login-rate-limit` → disparado o limiar da conta A, ao avançar a janela (fake timers) A volta a poder tentar; nenhum estado "conta bloqueada" é persistido. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Mais estrito que o limite global — verificação executável: `npm --prefix mnemonicos-backend test -- login-rate-limit` afirma que o `max` por conta (5) é menor que o `max` global de `src/app.ts` e dispara antes dele numa sequência de tentativas. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md`, §6.3 — `trust proxy` numérico; README do repo vence em conflito).
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-003-001: contador em memória por instância (serverless) — proteção real multi-instância exige `store` compartilhado (dívida conhecida, fora do escopo). `trust proxy: 1` já posto — `req.ip` depende do nº real de proxies no deploy.
- Consequência aceita (A-002-020): quem compartilha a origem do escritório tem mais tentativas antes do freio de origem — o freio por conta permanece estrito.
- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-backend/src/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-08-29T01:40:00-03:00
**Data conclusão**: 2026-08-29T08:45:00-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: eee5969 · 928a750 (retry gate 7)
**Jira**: KAN-18
**Implementado por**: developer
**Revisado por**: code-reviewer (1–7) · security-engineer (8) · performance-engineer (10) — Wave 3, diff acumulado + delta do retry, re-review APROVADO nos três
**Tentativas**: 2
**Cobertura final**: n/a
**Arquivos modificados**:
  - mnemonicos-backend/src/modules/auth/login-rate-limit.ts
  - mnemonicos-backend/src/http/errors.ts (+ TooManyRequestsError 429)
  - mnemonicos-backend/src/app.ts (extração de `GLOBAL_RATE_LIMIT_MAX` — necessidade direta do AC, não escoteiro)
  - mnemonicos-backend/tests/integration/login-rate-limit.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando — unit 85/85 · integração 46/46
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado — re-review do delta APROVADO
- [x] ACs verificados — AC-002-003 (chave composta conta+origem, sem lockout duro, 2ª conta legítima da mesma origem autentica), NFR-002-006 (mais estrito que o global — oráculo lê a constante exportada de src/app.ts)
- [x] Segurança (gate 8): aprovado (Wave 3) — se: freio sem caminho de lockout permanente; MemoryStore sem vazamento (double-buffer + .clear())
- [ ] Comportamento (gate 9): pendente — FEAT-002-003 completa no fim da Wave 5
- [x] Performance (gate 10): aprovado (Wave 3) — pe: contador em memória sem crescimento sem bound (TRISK-003-001 segue como dívida multi-instância)

**Notas**: Dois limiters `express-rate-limit` (por e-mail normalizado, por `req.ip` com `ipKeyGenerator`), `skip: () => isTest`, factory `createLoginRateLimiters(overrides?)` para testabilidade. Retry pelo gate 7: envelope de erro 429 passa pela fronteira única (`next(new TooManyRequestsError())` → `errorHandler`); `GLOBAL_RATE_LIMIT_MAX` exportada de `src/app.ts` e importada no teste (era cópia manual). **Classificação corrigida**: a edição de `src/app.ts` é necessidade técnica direta do critério de pronto (que cita "o max global de src/app.ts"), não escoteiro cross-file.
