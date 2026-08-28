# TASK-003-001: Declarar as novas variáveis de ambiente da fatia

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: nenhuma
**Componente**: COMP-003-001
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 + ts-jest + supertest — unit em `mnemonicos-backend/tests/unit/`, integração em `mnemonicos-backend/tests/integration/` sobre a `app` real; env fictícia em `mnemonicos-backend/tests/setup-env.ts`. Gates: `npm --prefix mnemonicos-backend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-003-003, TASK-003-009

## Contexto

DEC-003-009 / COMP-003-001: cookies, TTLs, parâmetros de Argon2id e credenciais de bootstrap do seed precisam ser configuráveis sem redeploy, e o perfil §6.4 veda constante de config/segredo no código e `process.env` espalhado. Esta task só declara e valida as chaves no `envSchema` (fail fast, só nomes no erro) e prepara as fixtures de teste; nenhum consumidor de regra é tocado aqui. `JWT_SECRET` permanece (vira pepper do hash de token — DEC-003-002); `JWT_EXPIRES_IN` fica como config morta (TRISK-003-006).

## Escopo

### Inclui
- `mnemonicos-backend/src/config/env.ts` — acrescenta ao `envSchema`, com os defaults de COMP-003-001 **salvo a errata do gate da Wave 1**: `COOKIE_SECURE` (`z.enum(['true','false']).default(NODE_ENV==='production'?'true':'false').transform(v => v === 'true')` — **nunca** `z.coerce.boolean()`, que é fail-open: perfil §6.4), `SEED_ADMIN_EMAIL` (`z.email().optional()` — Zod 4, §11), `SEED_ADMIN_PASSWORD` (`z.string().min(12).optional()`), `AUTH_ACCESS_TTL_MINUTES` (`z.coerce.number().int().positive().default(15)`), `AUTH_REFRESH_TTL_DAYS` (`.default(7)`), `AUTH_REFRESH_GRACE_SECONDS` (`z.coerce.number().int().nonnegative().default(10)`), `ARGON2_MEMORY_KIB` (`.default(19456)`), `ARGON2_TIME_COST` (`.default(2)`), `ARGON2_PARALLELISM` (`.default(1)`).
- `mnemonicos-backend/.env.example` — cada uma das 9 chaves com placeholder e comentário; nota de que `JWT_EXPIRES_IN` passa a ser config morta após a DEC-003-002 (TRISK-003-006).
- `mnemonicos-backend/tests/setup-env.ts` — valores fictícios para as chaves novas obrigatórias-por-default (as `.optional()` podem ficar ausentes).
- `mnemonicos-backend/src/lib/logger.ts` — `redact.paths` ganha `SEED_ADMIN_PASSWORD` **e as variantes de um nível** `*.JWT_SECRET`, `*.DATABASE_URL`, `*.SEED_ADMIN_PASSWORD`, `*.accessTokenHash`, `*.refreshTokenHash` (o wildcard do pino cobre só um nível — gate 8 da Wave 1).

### Não inclui
- Consumo das chaves (`password.ts`/`tokens.ts` — TASK-003-003; opções de cookie — TASK-003-009; seed — TASK-003-012).
- Remoção da chave `JWT_EXPIRES_IN` (fora do escopo de F1).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Adicionar as 9 chaves ao `envSchema` com os validadores/defaults de COMP-003-001; manter o erro de boot só com nomes.
2. Espelhar cada chave no `.env.example` com placeholder + comentário curto; anotar `JWT_EXPIRES_IN` como morta.
3. Preencher `tests/setup-env.ts` com valores fictícios para as obrigatórias-por-default.
4. Incluir `SEED_ADMIN_PASSWORD` em `redact.paths` do `logger.ts`.

## Critérios de pronto

- [ ] O `envSchema` valida as 9 chaves com os defaults de COMP-003-001 e o boot falha só com nomes quando uma obrigatória sem default falta — verificação executável: `npm --prefix mnemonicos-backend test -- env` → parse de env mínimo produz `AUTH_ACCESS_TTL_MINUTES===15`, `AUTH_REFRESH_TTL_DAYS===7`, `AUTH_REFRESH_GRACE_SECONDS===10`, `ARGON2_MEMORY_KIB===19456`, `ARGON2_TIME_COST===2`, `ARGON2_PARALLELISM===1`, `COOKIE_SECURE` booleano; `SEED_ADMIN_PASSWORD` com 11 chars → erro de validação Zod. `Tests: ≥3 passed`. Fixada antes do código.
- [ ] `SEED_ADMIN_PASSWORD` nunca sai em log — verificação executável: `npm --prefix mnemonicos-backend test -- logger` → um registro contendo `{ SEED_ADMIN_PASSWORD: '...' }` sai redigido (`[Redacted]`); remover a chave de `redact.paths` deixa o teste vermelho. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] `tests/setup-env.ts` cobre as novas obrigatórias-por-default — verificação executável: `npm --prefix mnemonicos-backend test` → a suíte inteira carrega sem erro de env no boot (baseline: suíte verde hoje — capturada no início da TASK; permanece verde). Fixada antes do código.
- [ ] `.env.example` lista as 9 chaves novas — verificação executável: `npm --prefix mnemonicos-backend test -- env` inclui um caso que lê `mnemonicos-backend/.env.example` e afirma presença de cada uma das 9 chaves adicionadas ao `envSchema`; a ausência de qualquer uma deixa o teste vermelho. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline sem warnings capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md`; README do repo vence em conflito).
- [ ] Code review aprovado.

## Riscos específicos

- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-backend/src/...`), não pela listagem da raiz do workspace.
- Nenhum valor real de `.env` entra no `.env.example` nem em teste — só placeholders.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-08-28T15:33:00-03:00
**Data conclusão**: 2026-08-28T20:37:00-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: b0c85e1 · 6c60682 (retry)
**Jira**: KAN-11
**Implementado por**: developer
**Revisado por**: code-reviewer (gates 1–7) · security-engineer (gate 8) — Wave 1, sobre o diff acumulado + delta do retry
**Tentativas**: 2
**Cobertura final**: n/a (chore de config)
**Arquivos modificados**:
  - mnemonicos-backend/src/config/env.ts
  - mnemonicos-backend/src/lib/logger.ts
  - mnemonicos-backend/tests/setup-env.ts
  - mnemonicos-backend/.env.example
  - mnemonicos-backend/tests/unit/env.test.ts
  - mnemonicos-backend/tests/unit/logger.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando — backend 30/30 (5 suítes)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado — code-reviewer, re-review do delta APROVADO
- [x] ACs verificados — cobertura por critério de pronto (chore, sem AC); crítérios executáveis de COOKIE_SECURE (4 ramos, inclusive '' e inválido sem eco) e redação aninhada do pino provados
- [x] Segurança (gate 8): aprovado (Wave 1) — security-engineer, re-review do delta APROVADO (achado alta COOKIE_SECURE fail-open resolvido)
- [x] Comportamento (gate 9): n/a — config de ambiente, sem efeito observável de comportamento (qa)

**Notas**: Retry pelo gate 8+6 da Wave 1: `z.coerce.boolean()` (fail-open) → `z.enum(['true','false']).transform(...)`; `z.email()` (Zod 4); `redact.paths` ganhou as variantes de um nível (`*.JWT_SECRET`/`*.DATABASE_URL`/`*.SEED_ADMIN_PASSWORD`/`*.accessTokenHash`/`*.refreshTokenHash`); casos de teste com valor fornecido e prova de redação aninhada. Lição registrada em guidelines/project/lessons.md + node-22.md §6.4 (pendente de merge). O `Escopo > Inclui` foi realinhado à errata do PLAN.
