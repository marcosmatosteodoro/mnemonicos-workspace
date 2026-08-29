# TASK-003-006: Serviço de autenticação (`auth.service.ts` + `auth.schema.ts`)

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: FR-002-001, FR-002-002, FR-002-006, FR-002-007, FR-002-024
**Funcionalidade**: FEAT-002-001 (primária), FEAT-002-003
**Componente**: COMP-003-008, COMP-003-007
**Wave**: 3
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 + ts-jest + supertest — unit em `mnemonicos-backend/tests/unit/`, integração em `mnemonicos-backend/tests/integration/` sobre Prisma real (Postgres do `docker-compose`). Gates: `npm --prefix mnemonicos-backend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: TASK-003-002, TASK-003-003, TASK-003-004, TASK-003-005, TASK-003-016
- **Bloqueia**: TASK-003-007, TASK-003-009, TASK-003-010

## Contexto

COMP-003-008 / COMP-003-007, DEC-003-002 (token opaco com estado no servidor), DEC-003-003 (rotação por família), §4 do PLAN. Regra + Prisma de toda a sessão: estabelecer login com auditoria, recusar credencial inválida com falha genérica, resolver a sessão a cada requisição rejeitando revogada/conta desativada, renovar delegando a `decideRefresh`, revogar no logout, trocar a própria senha. Fatia sensível → `security-engineer`. Nunca persiste token em claro; nunca devolve `passwordHash` ou valor de token.

## Escopo

### Inclui
- `mnemonicos-backend/src/modules/auth/auth.service.ts` — funções (não classe — §4 do perfil):
  - `login(input: { email; password; ip; userAgent? }): Promise<IssuedSession>` — resolve `User` por e-mail; `verifyPassword`; recusa com `UnauthorizedError` **genérico** se usuário inexistente **ou** senha errada **ou** `disabledAt != null` (mensagem única); sucesso → cria 1 `Session` (`familyId` novo; access+refresh via `generateToken`, guardados como `hashToken`) + `recordAuthEvent('login.success')`; falha → `recordAuthEvent('login.failure')` sem senha/token.
  - `resolveAccessSession(accessToken: string, now: Date): Promise<AuthContext | null>` — busca por `accessTokenHash` (`@unique`), confere `accessExpiresAt > now`, `revokedAt IS NULL`, junta `User`, confere `user.disabledAt IS NULL`; devolve `{ userId, role, sessionId }` ou `null`.
  - `refresh(refreshToken: string, ctx: { ip: string; userAgent?: string }, now: Date): Promise<IssuedSession>` — **furo no plano da Wave 3, resolvido**: `refresh` recebe um `ctx` de origem porque `src/lib/audit.ts` (Wave 2, selado) fixou `ip: string` **obrigatório** em `AuthAuditEvent` e NFR-002-005 (MUST) exige indicador de origem em todo evento; a rota (TASK-003-009) passa `{ ip: req.ip, userAgent: req.get('user-agent') }`. Acha a linha por `refreshTokenHash`; delega a `decideRefresh` (COMP-003-006); `rotate` → `rotatedAt = now` na linha + sucessora no mesmo `familyId` **em `prisma.$transaction`** + `recordAuthEvent({ type: 'token.refresh', at: now, outcome: 'ok', subject: userId, ip: ctx.ip, userAgent: ctx.userAgent })`; `replay-grace` → reemite os cookies do sucessor já criado (idempotente); `reuse` → `revokedAt = now WHERE familyId` + `recordAuthEvent({ type: 'token.reuse', ip: ctx.ip, ... })` + `UnauthorizedError`; `expired` → `UnauthorizedError`, **e se `rotatedAt != null || revokedAt != null`** também `revokedAt = now WHERE familyId` + `recordAuthEvent({ type: 'token.reuse', ip: ctx.ip, ... })` (gate 8 da Wave 2). Token ausente (`undefined`) ou linha não encontrada → `UnauthorizedError` **genérico** (mesma `message` do caminho de credencial inválida), nunca exceção não tratada.
  - `logout(refreshToken: string, ctx: { ip: string; userAgent?: string }): Promise<void>` — `revokedAt = now WHERE familyId`; `recordAuthEvent({ type: 'logout', at: <now>, outcome: 'ok', subject: userId, ip: ctx.ip, userAgent: ctx.userAgent })`. `refreshToken` ausente (`undefined`) → **no-op silencioso** (a rota faz `clearCookie`). O `ctx` supre o `ip` obrigatório do evento (mesmo furo da Wave 3, ver `refresh`).
  - `changeOwnPassword(userId, input): Promise<void>` — `verifyPassword` da senha atual (erro → `UnauthorizedError`, sem alterar); `hashPassword` da nova; `revokedAt = now WHERE userId AND id != sessão corrente`. `newPassword` == senha atual (e ≥ 12) é **aceita** — F1 não promete política de reuso de senha (o hash muda por salt novo).
  - `revokeAllSessions(userId): Promise<void>` — usado por desativação e reset (TASK-003-010).
- `mnemonicos-backend/src/modules/auth/auth.schema.ts` — `loginSchema` (`email` `z.email()` normalizado minúsculas/trim; `password` `z.string().min(1).max(200)`), `changePasswordSchema` (`currentPassword` `z.string().min(1)`; `newPassword` `z.string().min(12).max(200)`). O `.max(200)` no `password`/`newPassword` **e** no `loginSchema.password` protege o KDF caro (Argon2id 19 MiB) de amplificação de DoS por corpo grande (gate 8 da Wave 2). Consumo por `z.infer`, nunca `req.body` direto.
- `mnemonicos-backend/tests/integration/auth.service.test.ts` (+ unit onde couber).
- Meio de execução dos `*.integration.test.ts` desta TASK: o harness de TASK-003-016 — config `jest.integration.config.ts`, helper `tests/integration/db.ts` (`testPrisma` + `resetDb()` no `beforeEach`), comando `npm --prefix mnemonicos-backend run test:integration`.

### Não inclui
- As rotas HTTP / cookies / verificação de `Origin`/`Host` (TASK-003-009).
- `requireAuth` / `requireRole` (TASK-003-007).
- Os freios de login (TASK-003-008).
- A suíte de conformidade de rotas (TASK-003-011).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `auth.schema.ts` — os dois schemas Zod com mensagens pt-BR.
2. `auth.service.ts` — implementar as 6 funções; montar os payloads de auditoria campo a campo; `refresh` inteiro dentro de `prisma.$transaction` no ramo `rotate`.
3. Testes de integração com fixtures de 2 usuários / 2 famílias onde o escopo importa.

## Critérios de pronto

- [ ] Testes cobrem AC-002-002 (falha genérica + auditoria sem segredo) — verificação executável: `npm --prefix mnemonicos-backend test -- auth.service` → e-mail inexistente, senha errada e conta com `disabledAt != null` produzem exceção com a **mesma** `message`; o spy de `recordAuthEvent` recebe `login.failure` cujo payload não contém a senha da fixture. `Tests: ≥3 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-004 (rotação sequencial na camada de serviço — reapresentar r1 fora da graça é reuso) — verificação executável: `npm --prefix mnemonicos-backend test -- auth.service` (integração) → `refresh(r1)` → `IssuedSession` novo; `resolveAccessSession(accessNovo, now)` → contexto; `refresh(r1)` de novo **após `AUTH_REFRESH_GRACE_SECONDS`** → `UnauthorizedError` **e** a família revogada (a linha de r1 tem `rotatedAt` setado fora da graça → `decideRefresh` devolve `reuse` → `revokedAt = now WHERE familyId`, consistente com AC-002-005); a mutação que ignora `rotatedAt` fora da graça deixa vermelho. `Tests: ≥2 passed`. Fixada antes do código. Difere do item AC-002-005 abaixo e da TASK-003-004: aqueles fixam o **gatilho puro** em `decideRefresh` e a revogação só-da-família com 2 famílias; este fixa a **rotação sequencial ponta-a-ponta na camada de serviço**, com persistência real e ordem access→resolve→re-refresh.
- [ ] Testes cobrem AC-002-006 (expiração absoluta do refresh na camada de serviço) — verificação executável: `npm --prefix mnemonicos-backend test -- auth.service` → `refresh` de um refresh token com `refreshExpiresAt` no passado → `UnauthorizedError`; a mutação que ignora `refreshExpiresAt` no serviço deixa vermelho. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-008 (sessão revogada / conta desativada rejeitada mesmo com credencial não expirada) — verificação executável: `npm --prefix mnemonicos-backend test -- auth.service` → fixture com **duas** sessões (uma ativa, uma com `revokedAt != null`) e **dois** usuários (um ativo, um com `disabledAt != null`), todas com `accessExpiresAt > now`: ativa+ativo → `AuthContext`; revogada+ativo → `null`; ativa+desativado → `null`; a mutação que remove `revokedAt: null` do `where` **ou** o filtro `user.disabledAt` deixa ao menos uma asserção vermelha (2 ramos → 2 mutações + caso neutro). `Tests: ≥3 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-005 (reuso revoga a família, e só ela) — verificação executável: `npm --prefix mnemonicos-backend test -- auth.service` (integração) → fixture com **duas** famílias de **dois** usuários; apresentar token já rotacionado da família A → todas as linhas de A `revokedAt != null`, todas as de B `revokedAt == null`; a mutação que troca o `where` de `familyId` por `id` deixa o teste vermelho. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-007 (logout revoga a família; reapresentação rejeitada) — verificação executável: `npm --prefix mnemonicos-backend test -- auth.service` → após `logout(refresh)`: `resolveAccessSession` do access anterior → `null`; `refresh` do refresh anterior → `UnauthorizedError`; segunda família intacta. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Testes cobrem o caminho de token ausente / linha não encontrada — verificação executável: `npm --prefix mnemonicos-backend test -- auth.service` → `refresh(undefined)` e `refresh('token-inexistente')` → `UnauthorizedError` genérico (a **mesma** `message` do caminho de credencial inválida), nunca exceção não tratada / 500; `logout(undefined)` → resolve sem erro (no-op silencioso). `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-026 (renovações concorrentes não revogam; token anterior fora da graça revoga) — verificação executável: `npm --prefix mnemonicos-backend test -- auth.service` (integração) → `Promise.all` de dois `refresh` com o mesmo refresh token → ambos resolvem `IssuedSession`, nenhuma linha da família com `revokedAt` (prova o caminho `replay-grace`); em seguida `refresh` do token original após `AUTH_REFRESH_GRACE_SECONDS` → `UnauthorizedError` e família revogada; e o duplo-rotate verdadeiramente simultâneo falha fechado pela unicidade: um teste insere manualmente uma 2ª linha `Session` com o mesmo `refreshTokenHash` de uma linha existente e afirma que o Prisma lança erro de constraint `@unique` (P2002). `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-029 (troca da própria senha) — verificação executável: `npm --prefix mnemonicos-backend test -- auth.service` → fixture com **duas** sessões do mesmo usuário + uma de outro usuário; senha atual correta → hash muda, `verifyPassword(newPassword, hash)` true, a **outra** sessão do usuário fica `revokedAt != null`, a sessão de outro usuário intacta; senha atual errada → hash inalterado + `UnauthorizedError`. `Tests: ≥3 passed`. Fixada antes do código.
- [ ] Testes cobrem `changeOwnPassword` com nova senha == senha atual — verificação executável: `npm --prefix mnemonicos-backend test -- auth.service` → `changeOwnPassword` com `newPassword` == senha atual (e ≥ 12) → **aceito** (F1 não promete política de reuso de senha); o hash muda (salt novo) e as demais sessões da conta são revogadas na mesma. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-024 / NFR-002-004 (nenhum segredo em log ou resposta) — verificação executável: `npm --prefix mnemonicos-backend test -- auth.service` → (a) espião do transport do `logger` durante `login` (sucesso e falha) e `changeOwnPassword` falha se algum registro contiver a senha em claro da fixture, o valor do access token ou do refresh token; (b) asserção **estrutural** de que os retornos de `login`/`changeOwnPassword`/`resolveAccessSession` não têm as chaves `passwordHash`/`accessToken`/`refreshToken`. `Tests: ≥3 passed`. Fixada antes do código.
- [ ] `revokeAllSessions(userId)` revoga só as sessões do usuário — verificação executável: `npm --prefix mnemonicos-backend test -- auth.service` → fixture 2 usuários × 2 sessões; `revokeAllSessions(A)` → 2 linhas de A `revokedAt != null`, 2 de B intactas; a mutação `where userId` → `id` deixa vermelho. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md`, §4/§5/§6.3–6.5; README do repo vence em conflito).
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-003-005: rotação concorrente é área de corrida — `refresh` no ramo `rotate` inteiro em `prisma.$transaction`, com o `@unique` dos hashes como trava; o teste de refresh concorrente é obrigatório (AC-002-026).
- RISK-002-002 / NFR-002-004: só hashes de token são persistidos; os payloads de auditoria e de resposta são montados campo a campo, nunca a partir de `req.body`.
- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-backend/src/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-16
**Implementado por**: 
**Revisado por**: 
**Tentativas**: 
**Cobertura final**: 
**Arquivos modificados**:
  - 

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): verificado | n/a — <qa ou motivo do n/a>

**Notas**: 
