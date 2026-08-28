# PLAN-003: Acesso interno e papéis de produção

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.1
**Autor**: time keelson (scribe)
**Data**: 2026-08-28

## Aderência a guidelines

**Ficha/perfil de linguagem**: backend `guidelines/project/backend/node-22.md` (Node 22 · Express 5 · Prisma 7 · Zod 4 · Jest 30/ts-jest · supertest) e frontend `guidelines/project/frontend/next-16.md` (Next 16.3.2 · React 19 · RTK Query · Tailwind 4 · Jest 30 + Testing Library). Em conflito, os `README.md` de cada repo vencem o perfil; o perfil vence o Charter no específico da stack.
**Stack vigente herdado**: Node 22 LTS / TypeScript 6 (CJS); Express 5; Prisma 7 com `@prisma/adapter-pg` (runtime) e `prisma.config.ts` (migrate); Zod 4; pino; `express-rate-limit` (já instalado); Jest 30 + ts-jest + supertest. Frontend: Next 16 App Router / Turbopack, React 19, Redux Toolkit 2 + RTK Query, Tailwind 4 no `@theme`.
**Padrão arquitetural seguido**: backend — módulo por domínio com fronteiras por papel (`*.schema.ts` Zod → `*.service.ts` regra + Prisma → `*.routes.ts` HTTP), lógica pura sem I/O recebendo `now` (§4 do perfil, espelho de `src/modules/review/scheduler.ts`), erro tipado `AppError`/subclasses com fronteira de conversão única no `error-handler.ts` (§5), autorização deny-by-default na montagem e identidade sempre da sessão (§6.3), segredo só de `src/config/env.ts` via Zod (§6.4), sessão em cookie `httpOnly` (§6.5). Frontend — Server Components por padrão, `'use client'` na folha, `makeStore()` função, esconder ≠ autorizar (§6.3), token só em cookie `httpOnly` do backend (§6.5).
**Decisões irreversíveis do slug tocadas**: nenhuma — o INDEX de `producao-material` não registra nenhuma DEC irreversível anterior (não há PLAN anterior).
**Exceções aos guidelines**: nenhuma. DEC-003-002 (token opaco em vez de JWT) não é exceção: o perfil §6.5 reconhece explicitamente que "o desenho de rotação/revogação apropriado ao serverless ainda não existe neste projeto e precisa ser especificado antes da primeira rota autenticada" — esta DEC o especifica, mantendo o princípio "revogação exige estado no servidor".

## Cobertura

**SPEC referenciada**: SPEC-002
**Slice declarado**: cobertura total restante — F1 do épico MNEMORA STUDIO (BRIEF-002), único PLAN da SPEC-002.

**FRs cobertos**:
- FR-002-001
- FR-002-002
- FR-002-003
- FR-002-004
- FR-002-005
- FR-002-006
- FR-002-007
- FR-002-008
- FR-002-009
- FR-002-010
- FR-002-011
- FR-002-012
- FR-002-013
- FR-002-014
- FR-002-015
- FR-002-016
- FR-002-017
- FR-002-018
- FR-002-019
- FR-002-020
- FR-002-021
- FR-002-022
- FR-002-023
- FR-002-024

**NFRs cobertos**:
- NFR-002-001
- NFR-002-002
- NFR-002-003
- NFR-002-004
- NFR-002-005
- NFR-002-006
- NFR-002-007
- NFR-002-008
- NFR-002-009

**Cobertura agregada do slug**:
- Total na SPEC: 24 FRs + 9 NFRs
- Cobertos por planos anteriores: 0
- Cobertos por este: 24 FRs + 9 NFRs
- Gap restante: 0
- Funcionalidades cobertas: FEAT-002-001 (total), FEAT-002-002 (total), FEAT-002-003 (total)

## 1. Visão técnica

F1 liga, pela primeira vez, o modelo `User` e o segredo de sessão que já existem no schema/config a um fluxo de acesso. Três blocos:

1. **Autenticação de sessão (FEAT-002-001).** Módulo `src/modules/auth/`. A credencial de acesso é um **token opaco** de 256 bits em cookie `httpOnly` (`mnemo_access`); um **token de renovação** opaco (cookie `mnemo_refresh`, escopado a `/api/v1/auth`) troca a credencial expirada por uma nova com rotação por família. Ambos são persistidos apenas como hash SHA-256 com pepper numa tabela nova `Session`. A decisão de rotacionar / responder idempotente (janela de graça) / revogar a família (reuso) é uma **função pura sem I/O que recebe `now`** (`session-rotation.ts`), espelhando `scheduler.ts`. Login tem freio de taxa dedicado por chave composta (conta + origem). Todos os eventos (sucesso, falha, bloqueio temporário, decisão de autorização) passam por um emissor de auditoria estruturado sem dado sensível.

2. **Autorização deny-by-default (FEAT-002-002).** `requireAuth` é montado em `apiRoutes` **antes** de qualquer router de módulo, com uma allowlist pública curta por caminho exato (`/health`, `/health/db`, `/auth/login`, `/auth/refresh`). Todo o resto — inclusive `/disciplines` (A-002-019) — exige sessão válida resolvida a cada requisição (consulta indexada por hash de token, confere expiração/revogação e `disabledAt IS NULL`). Resolvida a sessão, o servidor consulta um **registro central de papéis por rota** (`ROUTE_ROLES`): caminho não declarado (nem público) → 403, **mesmo com sessão válida**. Toda rota não-pública declara seu conjunto de papéis via `requireRole(...)` — `requireRole('ADMIN')` nos routers de gestão, `requireRole('EDITOR','ADMIN')` nas rotas apenas autenticadas (`/disciplines`, `/auth/me`, `/auth/logout`, `/auth/change-password`); `STUDENT` fica fora de toda declaração (A-002-015). Uma suíte de integração enumera as rotas montadas e prova 401 sem sessão / 403 com papel insuficiente ou não-declarado para cada uma — é a **fonte de medição** da métrica §1.3.

3. **Provisionamento de contas (FEAT-002-003).** Módulo `src/modules/users/` sob `requireRole('ADMIN')`: criar (papel fixado na criação, `EDITOR` ou `ADMIN`), listar (sem material de senha/token), desativar (marca temporal reversível + revoga sessões + bloqueia autenticação; recusa se zerar ADMINs ativos) e resetar senha (+ revoga sessões). O primeiro ADMIN nasce do `prisma/seed.ts`, a partir de `SEED_ADMIN_EMAIL`/`SEED_ADMIN_PASSWORD`, sem senha embutida.

**Schema.** Migração aditiva `add_session_and_user_disabled`: `User.disabledAt DateTime?` e `model Session`. O enum `UserRole { STUDENT EDITOR ADMIN }` **não muda** (decisão do Diretor).

**Frontend mínimo.** `src/types/domain.ts` ganha `USER_ROLES`/`UserRole`/`SessionUser` espelhados do backend (mesmo diff — NFR-002-007). `src/store/api.ts` ganha um `baseQuery` com re-autenticação silenciosa (401 → `POST /auth/refresh` uma vez → repete; falhou → `resetApiState()` + `/login`) e os endpoints de auth/gestão. `src/proxy.ts` (ex-`middleware.ts` no Next 16) redireciona `/(interno)/*` para `/login` quando falta o cookie `mnemo_access` — conveniência de navegação, não fronteira. Tela de login e shell interno com os três estados observáveis, mensagens genéricas em pt-BR.

## 2. Stack e dependências

**Herdado, sem reescolha:** Node 22 / Express 5 / Prisma 7 / Zod 4 / pino / Jest 30 + ts-jest + supertest (backend); Next 16 / React 19 / RTK Query / Tailwind 4 / Jest 30 + Testing Library (frontend). Comandos de gate pela ficha (`quality.test/lint/typecheck/build`, prefixo por repo). `gates.security: true`. `gates.screenVerify` ligado (Playwright MCP) — fecha a mudança de tela.

**Dependências novas (backend):**

| Pacote | Papel | Notas de cadeia de suprimento (§8 do perfil; TRISK-003-004) |
|--------|-------|------------------------------------------------------------|
| `@node-rs/argon2` | Argon2id para hash de senha (DEC-003-001) | binário pré-compilado por plataforma (napi-rs), **sem** toolchain C / node-gyp — `npm ci` limpo no dev (Windows) e no CI. Pin exato; conferir downloads, última publicação e ausência de `postinstall` de compilação antes de adicionar. |
| `cookie-parser` | parse de `Cookie` (Express 5 não traz no core) — DEC-003-004 | pacote mínimo e estável; pin com caret. Sem assinatura de cookie (o token já é imprevisível e validado no servidor). |
| `@types/cookie-parser` | tipos (devDependency) | acompanha `cookie-parser`. |

`express-rate-limit` **já está instalado** (usado no limite global em `src/app.ts`) — reutilizado, não readicionado. Nenhuma dependência nova no frontend: o `baseQuery` com re-auth é um wrapper próprio sobre `fetchBaseQuery`, e o guard usa o `proxy.ts` nativo do Next 16.

**DoD de dependências:** `npm ci` reproduzível; `npm audit --omit=dev --audit-level=high` limpo no backend após as deps novas; `/keelson:audit` sobre o diff de F1 (RISK-002-003).

## 3. Componentes

### COMP-003-001: Extensão de `src/config/env.ts`
**Responsabilidade**: declarar e validar (Zod, no boot — *fail fast*) as novas variáveis de ambiente da fatia; nenhuma se torna segredo em log. É insumo de configuração para os componentes de auth, seed e cookie — não decide regra de negócio.
**Realiza**: nenhum
**Interface pública**: acrescenta ao `envSchema` — `COOKIE_SECURE` (`z.coerce.boolean()` com default = `isProduction`), `SEED_ADMIN_EMAIL` (`z.string().email().optional()`), `SEED_ADMIN_PASSWORD` (`z.string().min(12).optional()`), `AUTH_ACCESS_TTL_MINUTES` (`z.coerce.number().int().positive().default(15)`), `AUTH_REFRESH_TTL_DAYS` (`z.coerce.number().int().positive().default(7)`), `AUTH_REFRESH_GRACE_SECONDS` (`z.coerce.number().int().nonnegative().default(10)`), `ARGON2_MEMORY_KIB` (`.default(19456)`), `ARGON2_TIME_COST` (`.default(2)`), `ARGON2_PARALLELISM` (`.default(1)`). `.env.example` ganha cada chave com placeholder e comentário. `JWT_SECRET` permanece (vira pepper — DEC-003-002); `JWT_EXPIRES_IN` fica como config morta (TRISK-003-006). Acrescenta `SEED_ADMIN_PASSWORD` ao `redact.paths` de `src/lib/logger.ts` (defesa em profundidade).
**Dependências**: nenhuma

### COMP-003-002: Schema Prisma + migração `add_session_and_user_disabled`
**Responsabilidade**: acrescentar `User.disabledAt` e o `model Session`; gerar o arquivo de migração versionado (revisável, entra no diff da TASK). Provê a camada de dados revogável — a regra que a consome vive nos services/middlewares.
**Realiza**: nenhum
**Interface pública**: ver §5. `prisma migrate dev --name add_session_and_user_disabled` roda contra o Postgres do `docker-compose` local (autorização do Diretor — A-002-004); `prisma generate` depois. Enum `UserRole` intocado.
**Dependências**: nenhuma

### COMP-003-003: `src/lib/password.ts`
**Responsabilidade**: derivação e verificação de senha com Argon2id, parâmetros de custo lidos de `env`; nenhuma senha em claro atravessa log. É o ponto onde a resistência a força bruta da política de senha é realizada.
**Realiza**: NFR-002-003
**Interface pública**: `hashPassword(plain: string): Promise<string>` (async, nunca `*Sync` — §10 do perfil, event loop), `verifyPassword(plain: string, hash: string): Promise<boolean>`. Usa `@node-rs/argon2` com `memoryCost`/`timeCost`/`parallelism` de `env`. `verifyPassword` devolve `false` em hash malformado — nunca lança para o chamador decidir "libera".
**Dependências**: COMP-003-001

### COMP-003-004: `src/lib/tokens.ts`
**Responsabilidade**: gerar tokens opacos de alta entropia e compará-los em tempo constante via hash com pepper — o valor em claro nunca é persistido (RISK-002-002). Infra criptográfica consumida pelo service de sessão.
**Realiza**: nenhum
**Interface pública**: `generateToken(): string` (`crypto.randomBytes(32)` → base64url), `hashToken(token: string): string` (`sha256(token + env.JWT_SECRET)` — pepper; SHA-256 basta, token já é alta entropia), `tokensMatch(token: string, storedHash: string): boolean` (`crypto.timingSafeEqual` sobre os buffers de hash de mesmo tamanho). `Math.random()` proibido.
**Dependências**: COMP-003-001

### COMP-003-005: `src/lib/audit.ts`
**Responsabilidade**: emitir eventos de auditoria de autenticação/autorização estruturados, sem dado sensível, com o suficiente para investigar. É o componente que realiza a política de conteúdo dos eventos de auditoria.
**Realiza**: NFR-002-005
**Interface pública**: `recordAuthEvent(event: AuthAuditEvent): void`, onde `AuthAuditEvent` é união discriminada por `type` (`'login.success' | 'login.failure' | 'login.throttled' | 'token.refresh' | 'token.reuse' | 'logout' | 'authz.denied'`) com campos `at: Date`, `outcome`, `subject` (userId quando conhecido, senão e-mail normalizado tentado), `ip: string`, `userAgent?: string`. Escreve via `logger.info({ audit: event }, ...)`. **Nunca** inclui senha, valor de credencial ou de token — o payload é montado campo a campo, nunca o `req.body` cru.
**Dependências**: nenhuma

### COMP-003-006: `src/modules/auth/session-rotation.ts`
**Responsabilidade**: lógica pura sem I/O que, dada a linha de sessão encontrada e `now`, decide o desfecho de uma renovação — rotacionar, responder idempotente na janela de graça, revogar a família por reuso, ou recusar por expiração absoluta. Espelho de `src/modules/review/scheduler.ts`, testável em `tests/unit/`.
**Realiza**: FR-002-003, FR-002-004, FR-002-005
**Interface pública**: `decideRefresh(session: SessionRow, now: Date, graceSeconds: number): RefreshDecision`, onde `RefreshDecision` é união discriminada: `{ kind: 'rotate' }` | `{ kind: 'replay-grace' }` (reapresentação dentro da graça → reemitir cookies do sucessor) | `{ kind: 'reuse' }` (token já rotacionado além da graça, ou `revokedAt` setado → revogar família) | `{ kind: 'expired' }` (`refreshExpiresAt < now`). Ordem de avaliação dos ramos: **expired → reuse → replay-grace → rotate** (ramos coincidentes seguem essa precedência — expiração absoluta vence a graça). Não toca banco, não lê relógio.
**Dependências**: nenhuma

### COMP-003-007: `src/modules/auth/auth.schema.ts`
**Responsabilidade**: schemas Zod das entradas de auth na fronteira HTTP (login e troca da própria senha), com mensagens em pt-BR. Fronteira de validação consumida pelo router de auth.
**Realiza**: nenhum
**Interface pública**: `loginSchema` (`email` `z.email()` normalizado para minúsculas/trim, `password` `z.string().min(1)`), `changePasswordSchema` (`currentPassword` `z.string().min(1)`, `newPassword` `z.string().min(12)`). Consumo pelo tipo `z.infer`, nunca `req.body` direto.
**Dependências**: nenhuma

### COMP-003-008: `src/modules/auth/auth.service.ts`
**Responsabilidade**: regra + Prisma de toda a sessão — estabelecer login com auditoria, recusar credencial inválida com falha genérica, resolver a sessão a cada requisição rejeitando revogada/conta desativada, renovar, revogar no logout, trocar a própria senha; nunca persistir token em claro; nunca devolver `passwordHash` ou valor de token em resposta.
**Realiza**: FR-002-001, FR-002-002, FR-002-006, FR-002-007, FR-002-024, NFR-002-004
**Interface pública** (funções, não classe — §4 do perfil):
- `login(input: { email; password; ip; userAgent? }): Promise<IssuedSession>` — resolve `User` por e-mail; `verifyPassword`; recusa com `UnauthorizedError` genérico se usuário inexistente **ou** senha errada **ou** `disabledAt != null` (mensagem única — enumeração de contas); em sucesso cria 1 `Session` (`familyId` novo, access+refresh) e registra auditoria de sucesso; em falha, auditoria de falha sem senha/token.
- `resolveAccessSession(accessToken: string, now: Date): Promise<AuthContext | null>` — busca por `accessTokenHash` (índice único), confere `accessExpiresAt`, `revokedAt IS NULL`, junta `User`, confere `user.disabledAt IS NULL`; devolve `{ userId, role, sessionId }` ou `null`. É o que o middleware chama a cada requisição.
- `refresh(refreshToken: string, now: Date): Promise<IssuedSession>` — acha a linha por `refreshTokenHash`; delega a `decideRefresh` (COMP-003-006); em `rotate` marca `rotatedAt = now` na linha atual e cria sucessora no mesmo `familyId` **em transação** (`prisma.$transaction`); em `replay-grace` reemite os cookies do sucessor já criado (idempotente); em `reuse` faz `revokedAt = now WHERE familyId` e lança `UnauthorizedError`; em `expired` lança `UnauthorizedError`. Token ausente ou linha não encontrada → `UnauthorizedError` genérico (mesma `message` do login inválido), nunca exceção não tratada.
- `logout(refreshToken: string): Promise<void>` — `revokedAt = now WHERE familyId`; auditoria. Token ausente → no-op silencioso (a rota limpa os cookies).
- `changeOwnPassword(userId, input): Promise<void>` — `verifyPassword` da senha atual (erro → `UnauthorizedError`, sem alterar); `hashPassword` da nova; `revokedAt = now WHERE userId AND id != sessionAtual` (revoga as demais). `newPassword` igual à atual (e ≥ 12) é aceita — F1 não promete política de reuso de senha.
- `revokeAllSessions(userId): Promise<void>` — usado por desativação e reset de senha (COMP-003-014).
Nenhuma função devolve `passwordHash` nem valor de token.
**Dependências**: COMP-003-002, COMP-003-003, COMP-003-004, COMP-003-005, COMP-003-006, COMP-003-017

### COMP-003-009: `src/modules/auth/login-rate-limit.ts`
**Responsabilidade**: dois freios `express-rate-limit` dedicados a `POST /auth/login` — por conta e por origem — mais estritos que o global, sem bloqueio duro de conta, com evento de auditoria no disparo. Realiza o freio dedicado de login por chave composta.
**Realiza**: FR-002-008, NFR-002-006
**Interface pública**: `loginRateLimiters: RequestHandler[]` — (a) por conta: `keyGenerator` = e-mail normalizado do corpo, limite estrito (default 5 / 15 min); (b) por origem: `keyGenerator` = `req.ip`, limite frouxo (default 30 / 15 min). Ambos `skip: () => isTest`, `standardHeaders`, resposta 429 com `Retry-After`, `handler` que chama `recordAuthEvent({ type: 'login.throttled', ... })`. Sem `store` compartilhado (dívida conhecida — TRISK-003-001). Limiares default afináveis por `env` se o uso real mostrar erro.
**Dependências**: COMP-003-005

### COMP-003-010: `src/modules/auth/auth.routes.ts`
**Responsabilidade**: superfície HTTP de auth; escrever/limpar os cookies de sessão com as flags exigidas (inacessível a script, `secure` em produção, same-site); verificação de `Origin`/`Host` nas rotas POST que mudam estado.
**Realiza**: NFR-002-008
**Interface pública**: `authRoutes: Router` —
- `POST /auth/login` (público; precedido por `loginRateLimiters`) → `login`; em sucesso `res.cookie('mnemo_access', ...)` e `res.cookie('mnemo_refresh', ...)` com as flags da DEC-003-004; corpo de resposta = `SessionUser` (sem token).
- `POST /auth/refresh` (público) → lê `mnemo_refresh` do cookie, `refresh`; reemite os dois cookies.
- `POST /auth/logout` (protegido; `requireRole('EDITOR','ADMIN')`) → `logout`; `res.clearCookie` dos dois.
- `POST /auth/change-password` (protegido; `requireRole('EDITOR','ADMIN')`) → `changeOwnPassword` (usa `req.auth`).
- `GET /auth/me` (protegido; `requireRole('EDITOR','ADMIN')`) → devolve `SessionUser` da sessão corrente.
Sem `try/catch` (Express 5 encaminha rejeição). Middleware local de verificação de `Origin`/`Host` nas rotas POST (Route Handlers não herdam proteção CSRF).
**Dependências**: COMP-003-001, COMP-003-007, COMP-003-008, COMP-003-009

### COMP-003-011: `src/http/middlewares/authenticate.ts`
**Responsabilidade**: `requireAuth` — resolve a sessão a cada requisição no servidor, nega por padrão toda rota fora da allowlist pública e, além disso, consulta `ROUTE_ROLES` e nega o caminho que não declara papel (ausente de `PUBLIC_PATH_ALLOWLIST` **e** de `ROUTE_ROLES` → `ForbiddenError`, com `return`), mesmo para sessão válida; popula `req.auth` a partir da sessão verificada (identidade nunca do parâmetro de rota).
**Realiza**: FR-002-010, FR-002-012, NFR-002-002
**Interface pública**: `requireAuth: RequestHandler` — se `req.path` ∈ `PUBLIC_PATH_ALLOWLIST` (`/health`, `/health/db`, `/auth/login`, `/auth/refresh`) → `next()`; senão lê `mnemo_access`, chama `resolveAccessSession(token, new Date())`; `null` → `return next(new UnauthorizedError())` (o `return` é obrigatório — §6.3); sessão resolvida mas o padrão de rota **ausente de `ROUTE_ROLES`** → `return next(new ForbiddenError())` (falha fechada — DEC-003-005, mesmo com sessão válida); sucesso → popula `req.auth = { userId, role, sessionId }` e `next()`. Falha na resolução nega (fail secure). Tipo `AuthContext` acrescentado à declaração de `Express.Request` (`src/http/express.d.ts` ou equivalente).
**Dependências**: COMP-003-005, COMP-003-008

### COMP-003-012: `src/http/middlewares/authorize.ts`
**Responsabilidade**: `requireRole(...roles)` — restrição explícita por papel numa rota autenticada **e forma canônica de declaração**: registra o conjunto de papéis do caminho em `ROUTE_ROLES` (consultado por COMP-003-011 para negar o não-declarado) além de aplicar a checagem 403, com auditoria da negação e `return` obrigatório após `next(err)`.
**Realiza**: FR-002-011
**Interface pública**: `requireRole(...roles: UserRole[]): RequestHandler` — no registro do router, grava `roles` em `ROUTE_ROLES` sob o caminho correspondente; em runtime: sem `req.auth` → `return next(new UnauthorizedError())`; `req.auth.role` fora de `roles` → `recordAuthEvent({ type: 'authz.denied', ... })` e `return next(new ForbiddenError())`; senão `next()`. Sempre com `return` após `next(err)`.
**Dependências**: COMP-003-005

### COMP-003-013: `src/modules/users/users.schema.ts`
**Responsabilidade**: schemas Zod da gestão de contas; realiza a recusa de senha com menos de 12 caracteres tanto na criação quanto no reset, e a recusa do papel `STUDENT` na criação.
**Realiza**: FR-002-022
**Interface pública**: `createUserSchema` (`email` `z.email()` normalizado, `name` `z.string().trim().min(1)`, `role` `z.enum(['EDITOR','ADMIN'])` — `STUDENT` recusado, A-002-015, `password` `z.string().min(12)`), `resetPasswordSchema` (`password` `z.string().min(12)`), `userIdParamSchema` (`id` `z.uuid()`), `listUsersQuerySchema` (paginação, `.extend()` do padrão de `disciplines.schema.ts`).
**Dependências**: nenhuma

### COMP-003-014: `src/modules/users/users.service.ts`
**Responsabilidade**: regra + Prisma da gestão de contas internas — criar com papel fixado, recusar e-mail duplicado sem alterar a conta existente, listar sem material de senha/token, desativar de forma reversível com marca temporal e revogação de sessões, recusar a operação que zeraria os ADMINs ativos, resetar senha com revogação de sessões.
**Realiza**: FR-002-014, FR-002-015, FR-002-017, FR-002-018, FR-002-019, FR-002-020
**Interface pública**:
- `createInternalUser(input): Promise<SessionUser>` — `hashPassword`; `prisma.user.create` com `data` montado campo a campo; e-mail duplicado (violação de unique) → `ConflictError`, sem alterar a conta existente. A resposta é montada campo a campo (`select` explícito), nunca a entidade Prisma crua.
- `listInternalUsers(query): Promise<Paginated<UserListItem>>` — `select` explícito: `id`, `email`, `name`, `role`, `disabledAt` → mapeado para `status: 'active' | 'disabled'`. **Nunca** `passwordHash` nem relação `sessions`.
- `disableUser(id): Promise<void>` — se alvo é ADMIN e `count(role=ADMIN, disabledAt=null) <= 1` → `ConflictError` (último ADMIN, FR-002-019); senão `disabledAt = now` **e** `revokeAllSessions(id)` em transação.
- `resetUserPassword(id, password): Promise<void>` — `hashPassword`; grava; `revokeAllSessions(id)`.
**Dependências**: COMP-003-002, COMP-003-003, COMP-003-008, COMP-003-017

### COMP-003-015: `src/modules/users/users.routes.ts`
**Responsabilidade**: superfície HTTP da gestão, inteira sob `requireRole('ADMIN')`; mantém a superfície montada livre de qualquer caminho de auto-registro (nenhuma rota de registro público).
**Realiza**: FR-002-016
**Interface pública**: `usersRoutes: Router` com `usersRoutes.use(requireRole('ADMIN'))` no topo — `GET /users` (lista), `POST /users` (cria), `PATCH /users/:id/disable`, `POST /users/:id/reset-password`. Sem rota de registro público na superfície montada (FR-002-016 / AC-002-018). Sem `try/catch`.
**Dependências**: COMP-003-012, COMP-003-013, COMP-003-014

### COMP-003-016: Montagem em `src/http/routes.ts`
**Responsabilidade**: a ordem de montagem que realiza o deny-by-default — `requireAuth` montado antes dos routers protegidos e depois das rotas públicas — **e** a garantia de que todo router não-público aplica `requireRole(...)` (declara seus papéis em `ROUTE_ROLES`), de modo que uma rota adicionada sem declaração nasça negada (falha fechada). A realização de NFR-002-001 é **conjunta**: COMP-003-012 registra a declaração, COMP-003-011 nega o caminho não-declarado, COMP-003-016 garante que nenhum router não-público fica sem `requireRole`.
**Realiza**: NFR-002-001
**Interface pública**: `apiRoutes` passa a montar, nesta ordem — `healthRoutes` (público); as rotas públicas de `authRoutes` (`/auth/login`, `/auth/refresh`); `apiRoutes.use(requireAuth)`; então `authRoutes` protegidas com `requireRole('EDITOR','ADMIN')` (`/auth/logout`, `/auth/change-password`, `/auth/me`), `usersRoutes` com `requireRole('ADMIN')`, `disciplinesRoutes` com `requireRole('EDITOR','ADMIN')`. `/disciplines` passa a exigir sessão **e** declaração de papel (A-002-019; SPEC §4.1.9). Ordem conferida em `createApp()` — `app.use(auth)` depois de `app.use(API_PREFIX, apiRoutes)` não protegeria nada (§6.3).
**Dependências**: COMP-003-010, COMP-003-011, COMP-003-015

### COMP-003-017: Extensão de `src/domain/types.ts` (backend)
**Responsabilidade**: contrato de papel e de usuário de sessão, fonte da verdade a ser espelhada no frontend no mesmo diff.
**Realiza**: NFR-002-007
**Interface pública**: `USER_ROLES` já existe (`['STUDENT','EDITOR','ADMIN'] as const`) — mantido. Acrescenta `export interface SessionUser { id: string; name: string; email: string; role: UserRole }`. É o corpo de resposta de `POST /auth/login`, `GET /auth/me` e `POST /users`.
**Dependências**: nenhuma

### COMP-003-018: Extensão de `prisma/seed.ts`
**Responsabilidade**: criar exatamente um ADMIN inicial a partir de `env`, sem senha embutida, de forma idempotente; terminar sem criar quando as credenciais de bootstrap não estão configuradas.
**Realiza**: FR-002-021
**Interface pública**: no `main()`, antes ou depois do seed de conteúdo — se `env.SEED_ADMIN_EMAIL` **e** `env.SEED_ADMIN_PASSWORD` presentes **e** `count(User, role=ADMIN) === 0` → `prisma.user.create` com `role: 'ADMIN'`, `passwordHash` de `hashPassword`. Config parcial (só uma das duas) é tratada como ausente. Ausentes → `console.log` informativo e segue sem criar. **Nunca** senha embutida no código.
**Dependências**: COMP-003-001, COMP-003-002, COMP-003-003

### COMP-003-019: `tests/integration/route-authz-matrix.test.ts` (suíte de conformidade)
**Responsabilidade**: enumerar as rotas montadas na `app` real e provar, para cada não-pública, 401 sem sessão e 403 com papel insuficiente ou não-declarado — a suíte que serve de **fonte de medição** da métrica §1.3 (conformidade, verde/vermelha a cada CI). Verificação, não realização de requisito.
**Realiza**: nenhum
**Interface pública**: teste `supertest` sobre `app`; deriva a lista de rotas da pilha do router (`apiRoutes.stack` — Express 5 removeu `app._router`); para cada caminho ∉ `PUBLIC_PATH_ALLOWLIST`: espera 401 sem cookie; para os caminhos `requireRole('ADMIN')`: espera 403 com sessão de `EDITOR`. Um caso adicional monta uma rota fictícia **depois** de `requireAuth` e **sem** `requireRole` e prova que ela nasce negada — **403 com sessão válida de EDITOR** (não só 401 sem cookie), falha fechada por ausência de declaração em `ROUTE_ROLES` (AC-002-014). Snapshot: `PUBLIC_PATH_ALLOWLIST` é exatamente os quatro caminhos previstos. Oráculo capaz de falhar: remover `requireAuth` da montagem **ou** remover a declaração de papel de uma rota real (ex.: `/disciplines` de `ROUTE_ROLES`) torna o teste vermelho.
**Dependências**: COMP-003-016

### COMP-003-020: Extensão de `mnemonicos-frontend/src/types/domain.ts`
**Responsabilidade**: espelho exato do conjunto de papéis e do formato de usuário de sessão do backend (COMP-003-017), entregue no mesmo diff. Apoio de contrato consumido pelo store do frontend.
**Realiza**: nenhum
**Interface pública**: `export const USER_ROLES = ['STUDENT','EDITOR','ADMIN'] as const;` + `export type UserRole = (typeof USER_ROLES)[number];` + `export interface SessionUser { id: string; name: string; email: string; role: UserRole }`. Sem rótulo pt-BR de papel obrigatório nesta fatia (nenhuma tela lista papéis); se entrar, vem de mapa em `domain.ts` (regra do README frontend).
**Dependências**: nenhuma

### COMP-003-021: Extensão de `src/store/api.ts` (RTK Query)
**Responsabilidade**: re-autenticação silenciosa e endpoints de auth/gestão; limpar o cache do usuário anterior no logout/falha de sessão. Camada de acesso à API consumida pelas telas — não é a fronteira de decisão de nenhum requisito.
**Realiza**: nenhum
**Interface pública**: `baseQueryWithReauth` envolvendo `fetchBaseQuery` (mantém `credentials: 'include'`) — em 401, dispara **uma** vez `POST /auth/refresh`; sucesso → repete a requisição original; falha → `dispatch(api.util.resetApiState())` e redireciona para `/login?${SESSION_EXPIRED_PARAM}=expirada` (via `window.location` ou callback injetado). Exporta `export const SESSION_EXPIRED_PARAM = 'sessao'` (valor `expirada`) — símbolo consumido pela tela de login. Endpoints novos: `login` (mutation), `logout` (mutation), `changePassword` (mutation), `me` (query — fonte da sessão corrente), `adminListUsers` (query), `adminCreateUser`, `adminDisableUser`, `adminResetPassword` (mutations). `tagTypes` ganha `'SessionUser'` e `'User'`. Nenhum token tocado — tudo em cookie `httpOnly`.
**Dependências**: COMP-003-020

### COMP-003-022: `mnemonicos-frontend/src/proxy.ts` (guard de rota — conveniência)
**Responsabilidade**: redirecionar navegação para `/(interno)/*` quando falta o cookie `mnemo_access` — conveniência de navegação, **não** fronteira (§6.3). Não decide papel nem acesso a dado; a barreira real é o backend.
**Realiza**: nenhum
**Interface pública**: `export function proxy(request)` + `config.matcher` cobrindo o grupo `(interno)`. Sem cookie → `NextResponse.redirect('/login?next=<path relativo validado>')`; o `next` é validado como caminho relativo (guarda de open-redirect — §6.6). Nota: no Next 16 o arquivo é `proxy.ts` com `export function proxy` (o `middleware.ts` foi renomeado — perfil §1/§11); se a minor instalada ainda exigir `middleware.ts`, o nome acompanha o framework e a lógica é idêntica.
**Dependências**: nenhuma

### COMP-003-023: `src/app/login/page.tsx` + `src/components/login-form.tsx`
**Responsabilidade**: tela de login com os três estados observáveis (em andamento / sucesso / falha) e mensagem de erro genérica em pt-BR que não aponta campo; identificadores de código em inglês, texto de interface em pt-BR.
**Realiza**: FR-002-009, NFR-002-009
**Interface pública**: `page.tsx` (Server Component) compõe o `LoginForm` (`'use client'` — tem estado e evento) e, quando `SESSION_EXPIRED_PARAM` está presente nos search params, renderiza uma mensagem genérica pt-BR de sessão expirada num nó `role="status"`. Estados do form: *em andamento* (controle de submissão desabilitado + indicador de progresso em nó `role="status"` ou `aria-busy` no form), *sucesso* (navega para a área interna), *falha* (mensagem genérica pt-BR — "E-mail ou senha inválidos.", sem distinguir; formulário volta a aceitar entrada; nenhum campo apontado). Consome a mutation `login` de COMP-003-021 via `.unwrap()`.
**Dependências**: COMP-003-021

### COMP-003-024: `src/app/(interno)/layout.tsx` + `src/components/internal-shell.tsx`
**Responsabilidade**: shell da área interna — resolve a sessão (`me`) e reflete os três estados de navegação protegida (carregando neutro / vista renderizada / redirect ou "sem permissão"), e hospeda o controle de logout com seus três estados observáveis.
**Realiza**: FR-002-013, FR-002-023
**Interface pública**: `layout.tsx` do grupo `(interno)` compõe `InternalShell` (`'use client'`). Usa `useMeQuery`: *em andamento* → estado de carregamento neutro (nó `role="status"`); *sucesso* (sessão válida, papel suficiente) → renderiza `children`; *falha* sem sessão → redireciona para `/login`; *falha* com sessão e papel insuficiente → mensagem "sem permissão" sem o conteúdo. Controle de logout: *em andamento* (desabilitado + progresso), *sucesso* (sessão encerrada no servidor via mutation `logout`, volta ao login), *falha* (mensagem genérica pt-BR, permanece na área interna). O backend é quem nega de fato (FR-002-012).
**Dependências**: COMP-003-021, COMP-003-022

## 4. Fluxos principais

**Login.** `POST /auth/login` → `loginRateLimiters` (conta + origem) → `loginSchema.parse` → `auth.service.login`: acha `User` por e-mail, `verifyPassword`, confere `disabledAt IS NULL`; qualquer falha → `UnauthorizedError` genérico + auditoria de falha. Sucesso → cria `Session` (`familyId` novo; `accessToken`/`refreshToken` de `generateToken`, guardados como `hashToken`; `accessExpiresAt = now + AUTH_ACCESS_TTL_MINUTES`; `refreshExpiresAt = now + AUTH_REFRESH_TTL_DAYS`) + auditoria de sucesso; resposta seta `mnemo_access` e `mnemo_refresh` e devolve `SessionUser`.

**Requisição autenticada.** `requireAuth` (montado antes dos routers protegidos) → caminho na allowlist pública? segue. Senão lê `mnemo_access` → `resolveAccessSession`: consulta por `accessTokenHash`, confere `accessExpiresAt > now`, `revokedAt IS NULL`, `user.disabledAt IS NULL`. Falhou → 401 (mesmo com credencial não expirada, se a sessão foi revogada ou a conta desativada — FR-002-007). Sessão OK → o servidor consulta `ROUTE_ROLES` para o padrão do caminho: **ausente** (e não público) → 403 (falha fechada — DEC-003-005), mesmo com sessão válida. Presente → `req.auth` populado; `requireRole(...)` do router (`'ADMIN'` na gestão, `'EDITOR','ADMIN'` nas apenas autenticadas) decide o 403 + auditoria quando o papel não está no conjunto declarado.

**Renovação.** `POST /auth/refresh` → lê `mnemo_refresh` → acha linha por `refreshTokenHash` → `decideRefresh(session, now, AUTH_REFRESH_GRACE_SECONDS)`: `rotate` → transação: `rotatedAt = now` na linha atual + nova `Session` no mesmo `familyId`, reemite cookies; `replay-grace` → reemite os cookies do sucessor já criado (idempotente — renovações concorrentes do SPA não deslogam, AC-002-026); `reuse` → `revokedAt = now WHERE familyId` + 401; `expired` → 401 (exige novo login — FR-002-005).

**Logout.** `POST /auth/logout` (protegido) → `revokedAt = now WHERE familyId` + `clearCookie` dos dois + auditoria. Reapresentar cookie/token anteriores → rejeitado (AC-002-007).

**Gestão (ADMIN).** `POST /users` → `createUserSchema.parse` → `hashPassword` → `create` (e-mail duplicado → 409). `PATCH /users/:id/disable` → guarda do último ADMIN → `disabledAt = now` + `revokeAllSessions` (AC-002-020, AC-002-021). `POST /users/:id/reset-password` → `hashPassword` + grava + `revokeAllSessions` (AC-002-022). `POST /auth/change-password` (qualquer sessão) → confere senha atual → grava nova → revoga as demais sessões da conta (AC-002-029).

**Seed.** `prisma/seed.ts` → se `SEED_ADMIN_EMAIL` + `SEED_ADMIN_PASSWORD` e nenhum ADMIN existe → cria um; senão segue sem criar (AC-002-023).

**Frontend.** Navegação para `/(interno)/*` sem cookie `mnemo_access` → `proxy.ts` redireciona a `/login`. Dentro da área, `InternalShell` consulta `me`; 401 em qualquer chamada → `baseQueryWithReauth` tenta `refresh` uma vez e repete; refresh falhou → `resetApiState()` + `/login` com mensagem genérica (AC-002-028).

## 5. Modelo de dados

Migração aditiva `add_session_and_user_disabled` (Prisma 7; `prisma migrate dev`, arquivo versionado no diff da TASK, autorização do Diretor — A-002-004). Tipos lidos do `prisma/schema.prisma` real (mesmas convenções de `User`/`Discipline`: `id String @id @default(uuid(7))`, `DateTime @default(now())`, `@updatedAt`, `@unique`, `@@index`, `@@map`, relação `onDelete: Cascade`).

**`model User` — uma coluna nova:**

```prisma
model User {
  // ... campos atuais inalterados ...
  disabledAt DateTime?   // conta desativada de forma reversível (FR-002-018); null = ativa
  sessions   Session[]
  // ...
}
```

`enum UserRole { STUDENT EDITOR ADMIN }` — **inalterado** (decisão do Diretor; A-002-002).

**`model Session` — tabela nova:**

```prisma
model Session {
  id               String    @id @default(uuid(7))

  userId           String
  user             User      @relation(fields: [userId], references: [id], onDelete: Cascade)

  familyId         String    // agrupa a cadeia de rotação de um mesmo login (Família de sessão)

  accessTokenHash  String    @unique   // sha256(token + pepper) — nunca o token em claro
  refreshTokenHash String    @unique

  accessExpiresAt  DateTime
  refreshExpiresAt DateTime            // expiração absoluta de 7 dias (FR-002-005)
  rotatedAt        DateTime?           // setado quando este refresh foi trocado por um sucessor
  revokedAt        DateTime?           // setado por logout, reuso, troca de senha, desativação

  createdIp        String?
  userAgent        String?

  createdAt        DateTime  @default(now())

  @@index([userId])
  @@index([familyId])
  @@map("sessions")
}
```

**Notas de modelagem.** Hash = SHA-256 com pepper (token é alta entropia — KDF lento é desnecessário); comparação por `crypto.timingSafeEqual` sobre buffers de hash. Detecção de reuso: `rotatedAt != null` **e** `now - rotatedAt > AUTH_REFRESH_GRACE_SECONDS` → revoga `WHERE familyId`. Revogação em massa por usuário (`WHERE userId`) cobre desativação, reset e troca de senha. `onDelete: Cascade` alinha com o resto do schema, ainda que a exclusão de `User` esteja fora de escopo (§4.2 da SPEC).

## 6. Decisões arquiteturais

### DEC-003-001: Hash de senha — Argon2id via `@node-rs/argon2`
**Contexto**: NFR-002-003 exige função de derivação resistente a força bruta com parâmetros de custo configuráveis; o schema já documenta "Hash Argon2id" no campo `passwordHash`; o perfil §6.4 admite Argon2id ou bcrypt≥12 e nota que o Node 22 não traz Argon2 no core. O ambiente de dev é Windows e o CI roda `npm ci` limpo.
**Decisão**: `@node-rs/argon2` (binding napi-rs com binário pré-compilado), Argon2id, parâmetros OWASP como ponto de partida (`m = 19456 KiB`, `t = 2`, `p = 1`), lidos de `env` (`ARGON2_MEMORY_KIB`/`ARGON2_TIME_COST`/`ARGON2_PARALLELISM`) para afinação sem redeploy. Wrapper único em `src/lib/password.ts`, sempre assíncrono.
**Alternativas consideradas**:
- `argon2` (binding nativo node-gyp), descartada porque exige toolchain de compilação C no dev (Windows) e no CI, quebrando `npm ci` limpo e o build reproduzível.
- `bcrypt` custo ≥12, descartada porque tem teto de 72 bytes de senha e resistência a GPU inferior ao Argon2id, e contraria a indicação já registrada no schema/perfil (custo: divergência declarada + defesa mais fraca numa superfície crítica).
- `crypto.scrypt` (stdlib, zero dependência), descartada porque não expõe o eixo de paralelismo do Argon2id e a afinação de memória é mais manual; o ganho de "sem dependência" não compensa numa superfície sensível (custo: parâmetros de custo menos governáveis, contra NFR-002-003).
**Consequências**: uma dependência nativa a auditar (TRISK-003-004); hash carrega o identificador do algoritmo, permitindo re-hash transparente no próximo login. Parâmetros versionados como `env`, com `.env.example` documentado.
**Reabrir se**: `@node-rs/argon2` ficar >12 meses sem release com CVE aberto, ou o ambiente de deploy não suportar o binário pré-compilado.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova (escolha de biblioteca dentro do espaço autorizado pelo perfil §6.4)

### DEC-003-002: Credencial de acesso é token opaco com estado no servidor — não JWT
**Contexto**: FR-002-007 exige rejeitar uma credencial ainda não expirada quando a sessão foi revogada ou a conta desativada. Isso força uma checagem de estado no servidor a cada requisição autenticada. O perfil §6.5 reconhece que "o desenho de rotação/revogação apropriado ao serverless ainda não existe neste projeto e precisa ser especificado".
**Decisão**: o cookie de acesso carrega 256 bits de `crypto.randomBytes` (sem conteúdo interpretável). O middleware resolve a sessão por `hashToken` numa consulta indexada (`accessTokenHash @unique`), confere expiração/revogação, junta o `User`, confere `disabledAt IS NULL` e popula `req.auth`. `JWT_SECRET` permanece na `env` como **pepper** do hash de token (`sha256(token + JWT_SECRET)`).
**Alternativas consideradas**:
- JWT HS256 assinado com `JWT_SECRET`, `algorithms: ['HS256']` explícito, descartada porque a consulta de sessão por requisição já é inevitável (FR-002-007): o JWT então acrescenta superfície (confusão de `alg`, verificação de `exp`/`iss`/`aud`) e a dependência `jsonwebtoken`/`jose` **sem** remover a ida ao banco (custo: mais código e mais CVE potencial por zero ganho de statelessness).
**Consequências**: uma consulta indexada por requisição autenticada (TRISK-003-003) — aceitável para equipe interna de dezenas de usuários. `JWT_EXPIRES_IN` deixa de ser usado (config morta — TRISK-003-006); remoção fora do escopo de F1. Logout e desativação passam a ser reais no servidor sem allowlist/denylist extra.
**Reabrir se**: o volume de requisições autenticadas tornar a consulta de sessão por requisição um gargalo **medido** (TRISK-003-003) — a saída então é cache de sessão, não JWT.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova (especifica o desenho de sessão que o perfil §6.5 declara inexistente, mantendo "revogação exige estado no servidor")

### DEC-003-003: `model Session` para access + refresh com rotação por família
**Contexto**: A-002-003/007/018 pedem credencial curta + token de renovação rotacionado, revogável, com detecção de reuso e tolerância a renovações concorrentes. RISK-002-002 alerta que o repositório de tokens é superfície sensível.
**Decisão**: uma tabela `Session` (campos na §5) guarda **apenas hashes** dos tokens. `familyId` agrupa a cadeia de rotação de um login. Fluxo: login cria 1 linha com `familyId` novo; refresh delega a `decideRefresh` (função pura) e, conforme o desfecho, rotaciona (em transação), responde idempotente (janela de graça) ou revoga a família (reuso/expiração); logout e operações de conta revogam por `familyId` ou por `userId`.
**Alternativas consideradas**:
- `RefreshToken` isolado + access token *stateless*, descartada junto com DEC-003-002 (custo: mantém o JWT e sua superfície sem eliminar a consulta).
- Persistir o token em claro, descartada porque um dump do banco = tomada de todas as sessões vivas (custo direto: RISK-002-002 concretizado).
- Sem `familyId`, revogar sessão a sessão, descartada porque não há como cortar toda a cadeia derivada de um refresh vazado num único gesto (custo: reuso detectado sem contenção da árvore de tokens).
**Consequências**: tabela aditiva, migração revisável. Rotação concorrente é área de corrida (TRISK-003-005) — mitigada por função pura testável + transação. Índices em `userId` e `familyId` para as revogações em massa.
**Reabrir se**: surgir necessidade de sessão compartilhável entre dispositivos com políticas distintas por dispositivo.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova

### DEC-003-004: Cookies de sessão
**Contexto**: NFR-002-008 exige cookie inacessível a script, canal seguro em produção e política same-site. O perfil §6.5 lista as flags obrigatórias e alerta para o caso cross-domain. Express 5 não parseia cookie no core.
**Decisão**: `mnemo_access` — `path '/'`, `httpOnly`, `sameSite: 'lax'`, `secure: env.COOKIE_SECURE`, `maxAge` = TTL do access. `mnemo_refresh` — `path '/api/v1/auth'`, `httpOnly`, `sameSite: 'lax'`, `secure`, `maxAge` = TTL do refresh. Parsing via `cookie-parser`. Sem assinatura de cookie (o token já é imprevisível e validado no servidor). Verificação própria de `Origin`/`Host` nas rotas POST de auth que mudam estado.
**Alternativas consideradas**:
- `sameSite: 'strict'`, descartada porque quebra o retorno de navegação de topo pós-login vindo de link externo (custo: usuário que clica num link para o app e cai deslogado).
- Um cookie único (sessão deslizante de 7 dias), descartada porque contraria A-002-003 (credencial curta + refresh rotacionado) e alarga a janela de um cookie de acesso vazado (custo: exposição de credencial de longa duração).
- Assinar os cookies (`cookie-parser` com secret), descartada porque não agrega sobre um valor de 256 bits já validado por hash no servidor (custo: complexidade e um segredo a mais sem ganho).
**Consequências**: F1 assume mesmo site (dev local + `CORS_ORIGINS`); cross-domain exigirá `SameSite=None` + `Secure` + token anti-CSRF (TRISK-003-002). `cookie-parser` entra na árvore (TRISK-003-004).
**Reabrir se**: frontend e backend forem servidos de domínios distintos em produção.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (aplica §6.5 e NFR-002-008); nomes e paths são específicos deste PLAN

### DEC-003-005: Deny-by-default na montagem — `requireAuth` + registro central de papéis por rota
**Contexto**: NFR-002-001 / AC-002-014 exigem que uma rota seja inacessível a menos que **declare explicitamente os papéis** que a alcançam; a ausência de declaração nega — inclusive para uma **sessão válida**, não só para o anônimo. O perfil §6.3 normatiza autenticação antes do router protegido e ordem de middleware semântica em Express.
**Decisão**: dois mecanismos combinados, aditivos.
1. `requireAuth` montado em `apiRoutes` **antes** dos routers de módulo, com `PUBLIC_PATH_ALLOWLIST` explícita por caminho exato (`/health`, `/health/db`, `/auth/login`, `/auth/refresh`) — nega o anônimo (inalterado).
2. Um **registro central de papéis por rota** — `ROUTE_ROLES`, ao lado de `PUBLIC_PATH_ALLOWLIST`. Após autenticar, `requireAuth` (ou um passo imediatamente posterior) resolve o padrão de rota correspondente e consulta `ROUTE_ROLES`; caminho **ausente de `PUBLIC_PATH_ALLOWLIST` e de `ROUTE_ROLES`** → `ForbiddenError` (falha fechada), **mesmo com sessão válida**.
`requireRole(...roles)` permanece como a forma de **declarar**: registra o conjunto de papéis do caminho em `ROUTE_ROLES` e aplica a checagem 403. Toda rota não-pública passa a aplicá-lo, inclusive as permissivas — `requireRole('EDITOR','ADMIN')` em `GET /disciplines` (SPEC §4.1.9), `GET /auth/me`, `POST /auth/logout` e `POST /auth/change-password`. `STUDENT` fica **fora** de toda declaração (A-002-015 — a dormência do papel é verificável, não acidental). `requireRole('ADMIN')` nos routers de gestão. A suíte COMP-003-019 é a prova de conformidade no CI.
**Alternativas consideradas**:
- Autenticação opt-in por rota (decorator por handler), descartada porque uma rota nova sem o decorator nasce **aberta** — exatamente o que NFR-002-001 proíbe (custo: falha aberta por omissão, a classe de bug mais cara aqui).
- Catch-all após os routers que nega o que não respondeu, descartada porque não alcança o handler que já rodou e respondeu sem `requireRole` (custo: a falha aberta por handler esquecido continua possível — o catch-all só pega quem não casou rota nenhuma, não quem casou e serviu sem checar papel).
**Consequências**: qualquer rota futura nasce negada até declarar seus papéis em `ROUTE_ROLES` (via `requireRole`) ou entrar em `PUBLIC_PATH_ALLOWLIST` — os dois são atos deliberados. Uma sessão válida sem papel declarado para o caminho recebe 403, não 200. `PUBLIC_PATH_ALLOWLIST` e `ROUTE_ROLES` precisam ser mantidos curtos e revisados; o registro é **por caminho**, não por método HTTP. A realização é **conjunta**: COMP-003-011 nega o não-declarado, COMP-003-012 registra, COMP-003-016 garante que todo router não-público declara.
**Reabrir se**: surgir uma classe legítima de rota pública que não caiba numa allowlist curta por caminho exato; ou surgir necessidade de papel por método HTTP na mesma rota (hoje o registro é por caminho).
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (aplica §6.3)

### DEC-003-006: Freio de login com chave composta (conta + origem)
**Contexto**: NFR-002-006 / A-002-020 exigem freio dedicado, mais estrito que o global, por chave composta, sem bloqueio duro de conta, calibrado para não deter uma equipe atrás de um IP de escritório. O perfil §6.3 alerta que `express-rate-limit` reprova `trust proxy: true` e que `trust proxy: 1` já está posto.
**Decisão**: duas instâncias `express-rate-limit` só em `POST /auth/login` — por conta (`keyGenerator` = e-mail normalizado, estrito, default 5 / 15 min) e por origem (`keyGenerator` = `req.ip`, frouxo, default 30 / 15 min), ambas `skip: () => isTest`, resposta 429 + `Retry-After`, **sem** bloqueio duro de conta, evento de auditoria no disparo (FR-002-008). Limiares default afináveis por `env` se o uso real mostrar erro.
**Alternativas consideradas**:
- Um freio único por IP, descartada porque o NAT do escritório = um IP = time inteiro barrado por um errante (custo: a negação de serviço interna que A-002-005 quer evitar).
- Um freio único por e-mail, descartada porque adivinhação distribuída por muitos e-mails de uma mesma origem passaria livre (custo: força bruta dirigida a várias contas de uma origem não é contida).
**Consequências**: contador em memória por instância (serverless — TRISK-003-001); proteção real exige store compartilhado (dívida conhecida). Quem compartilha a origem do escritório tem mais tentativas antes do freio de origem — aceito por A-002-020, com o freio por conta permanecendo estrito.
**Reabrir se**: os limiares default se mostrarem errados no uso real (então ajuste por `env`); ou o deploy passar a exigir proteção real multi-instância (então store compartilhado).
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (aplica §6.3, incluindo `trust proxy` numérico)

### DEC-003-007: Mudança de schema — `User.disabledAt DateTime?` + `model Session`
**Contexto**: `User` não tem hoje como marcar conta desativada; não há repositório de sessão. A-002-004 põe a migração no ciclo de implementação; A-002-011 pede a marca temporal de desativação.
**Decisão**: migração aditiva `add_session_and_user_disabled` — `User.disabledAt DateTime?` (nullable; null = ativa) e `model Session` (§5). Enum `UserRole` **inalterado**. Roda contra o Postgres do `docker-compose` local; arquivo versionado no diff da TASK.
**Alternativas consideradas**:
- `isActive Boolean @default(true)` no lugar de `disabledAt`, descartada porque perde o "quando" que a auditoria e A-002-011 pedem (custo: sem marca temporal, a trilha de desativação fica incompleta).
- Tabela de eventos de conta desde já, descartada porque F1 só precisa distinguir ativa/desativada com carimbo de tempo; motivos de desativação são fatia posterior (custo: modelagem antecipada sem requisito).
**Consequências**: colunas/tabela aditivas e nullable — sem risco de dado existente. `prisma generate` obrigatório após a mudança. Reativar conta continua fora de escopo (§4.2 da SPEC).
**Reabrir se**: precisar distinguir motivos de desativação (então uma tabela de eventos de conta).
**Irreversível**: nao
**Aderência à ficha/perfil**: nova

### DEC-003-008: Seed do primeiro ADMIN
**Contexto**: FR-002-021 / AC-002-023 / A-002-010 exigem primeiro ADMIN a partir de `env`, sem senha embutida; `prisma/seed.ts` hoje não cria usuário.
**Decisão**: `prisma/seed.ts` lê `env.SEED_ADMIN_EMAIL` + `env.SEED_ADMIN_PASSWORD`; se ambos presentes **e** não existe nenhum `User` com `role = ADMIN` → cria um (senha via `src/lib/password.ts`). Config parcial (só uma das duas) é tratada como ausente. Ausentes → loga e segue sem criar. `.env.example` ganha as duas chaves com placeholder e comentário. Nunca senha embutida no código.
**Alternativas consideradas**:
- Script `db:create-admin` interativo à parte, descartada porque `db:setup` (que roda `db:seed`) deixaria o ambiente sem nenhum acesso até alguém rodar o script manualmente (custo: bootstrap quebrado por omissão; o seed é o ponto natural).
**Consequências**: o seed continua idempotente (a guarda `count(ADMIN) === 0`); em CI/dev sem as vars, nenhum ADMIN é criado — comportamento esperado.
**Reabrir se**: precisar semear mais de um papel ou uma equipe inteira no bootstrap.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (aplica §6.4 — bootstrap sem segredo embutido)

### DEC-003-009: Novas variáveis em `src/config/env.ts` (Zod, no boot)
**Contexto**: cookies, TTLs, parâmetros de Argon2id e credenciais de seed precisam ser configuráveis sem redeploy; o perfil §6.4 veda constante de segredo/config no código e `process.env` espalhado.
**Decisão**: acrescentar ao `envSchema` as chaves listadas em COMP-003-001, todas com `default` defensável e validação Zod no boot (*fail fast*, só nomes no erro). Nenhuma vira segredo em log (o `redact` do pino cobre `authorization`/`cookie`/`password`/`token`; `SEED_ADMIN_PASSWORD` é acrescentado ao `redact.paths` por defesa em profundidade).
**Alternativas consideradas**:
- Constantes hardcoded no módulo de auth, descartada porque contraria §6.4 e impede ajuste sem deploy (custo: afinar o custo do Argon2id ou o TTL exigiria release).
**Consequências**: `.env.example` cresce; `tests/setup-env.ts` ganha valores fictícios para as novas chaves obrigatórias-por-default.
**Reabrir se**: nunca — enquanto o perfil §6.4 vedar config/segredo no código, a decisão não se reabre; muda apenas o conjunto de chaves. *(condição `Reabrir se:` preenchida pelo scribe — o insumo deixou em aberto; ver `premissas_marcadas`.)*
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (aplica §6.4)

### DEC-003-010: Frontend — RTK Query com re-autenticação, tipos espelhados
**Contexto**: AC-002-028 pede renovação silenciosa com repetição única e, na falha, mensagem genérica + ida ao login; NFR-002-007 / AC-002-025 pedem paridade de tipos entre os repos no mesmo diff. O perfil §6.3 exige `resetApiState()` após logout.
**Decisão**: `src/store/api.ts` ganha `baseQueryWithReauth` (401 → `POST /auth/refresh` **uma** vez → repete; falhou → `resetApiState()` + `/login?sessao=expirada`) e os endpoints `login`/`logout`/`changePassword`/`me`/`adminListUsers`/`adminCreateUser`/`adminDisableUser`/`adminResetPassword`. `me` (RTK Query) é a **fonte** da sessão corrente; `src/types/domain.ts` ganha `USER_ROLES`/`UserRole`/`SessionUser` espelhados do backend no mesmo diff.
**Alternativas consideradas**:
- Um slice do Redux guardando o usuário da sessão, descartada porque duplica estado de servidor — origem da tela mostrando dado velho (perfil §4/§6.5); e o estado do Redux é serializado para o cliente na hidratação (custo: dado de sessão exposto no payload + cache incoerente).
**Consequências**: nenhuma dependência nova; um slice só-cliente entra apenas se surgir flag efêmera de "resolvendo sessão". `tagTypes` cresce com `'SessionUser'`/`'User'`.
**Reabrir se**: o backend passar a exigir um dado de sessão que só um slice do cliente resolve (ex.: estado offline) — aí um slice efêmero entra ao lado do `me`, sem substituí-lo. *(condição `Reabrir se:` preenchida pelo scribe — o insumo deixou em aberto; ver `premissas_marcadas`.)*
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (aplica §6.3/§6.5 do perfil frontend)

### DEC-003-011: Frontend — proteção de rota como conveniência
**Contexto**: FR-002-012 exige que a decisão de autorização seja do servidor e que o guard do cliente não seja a única barreira; o perfil §6.3 é enfático ("esconder não é autorizar"; `layout.tsx`/`proxy.ts` não são fronteira).
**Decisão**: `src/proxy.ts` (ex-`middleware.ts` no Next 16) redireciona `/(interno)/*` para `/login?next=<path relativo validado>` quando falta o cookie `mnemo_access` — conveniência de navegação. O `next` é validado como caminho relativo (guarda de open-redirect). As páginas internas também consultam `me`, e o backend é quem nega de fato. Tela de login e controle de logout como client components com os três estados e mensagens genéricas pt-BR.
**Alternativas consideradas**:
- Só `useEffect` redirecionando, descartada porque há flash do shell protegido antes do redirect (custo: conteúdo interno pisca na tela de quem não deveria vê-lo).
- Decidir papel no `proxy.ts`, descartada porque contraria §6.3 e o próprio FR-002-012 (custo: fronteira de segurança numa camada historicamente contornável — `x-middleware-subrequest`).
**Consequências**: o guard depende só da presença do cookie, não da sua validade — a validade é o backend que confere. Conferir se 16.3.2 está na faixa corrigida do advisory de bypass de middleware do Next.
**Reabrir se**: o advisory de bypass de middleware do Next (`x-middleware-subrequest`) afetar a minor instalada (16.3.2).
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (aplica §6.3 do perfil frontend)

### DEC-003-012: Layout de módulos backend
**Contexto**: o perfil §4 normatiza módulo por domínio com fronteiras por papel; a SPEC tem três FEATs com contratos de teste distintos (autenticação vs. autorização vs. gestão de contas).
**Decisão**: `src/modules/auth/` (`auth.schema.ts`, `auth.service.ts`, `auth.routes.ts`, `session-rotation.ts` puro, `login-rate-limit.ts`) e `src/modules/users/` (`users.schema.ts`, `users.service.ts`, `users.routes.ts`); middlewares em `src/http/middlewares/authenticate.ts` e `authorize.ts`; helpers em `src/lib/password.ts`, `src/lib/tokens.ts`, `src/lib/audit.ts`. Montagem em `src/http/routes.ts` com `requireAuth` depois das rotas públicas e antes das protegidas.
**Alternativas consideradas**:
- Um módulo `iam` único, descartada porque mistura autenticação e gestão de contas — dois contratos de teste distintos por FEAT ficariam no mesmo arquivo, e a fronteira `schema → service → routes` perde nitidez (custo: unidade de QA por FEAT diluída, arquivo de service com duas responsabilidades).
**Consequências**: mais arquivos, cada um com um papel claro pelo sufixo; `session-rotation.ts` isolado como função pura garante o teste unitário sem banco (TRISK-003-005).
**Reabrir se**: autenticação e gestão de contas divergirem a ponto de precisarem compartilhar service (ex.: fluxo de convite que loga e cria conta no mesmo passo) — aí a fronteira entre `auth/` e `users/` é reavaliada. *(condição `Reabrir se:` preenchida pelo scribe — o insumo deixou em aberto; ver `premissas_marcadas`.)*
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (aplica §4)

## 7. Mapeamento FR -> componente

| FR | Componente | AC cobertos |
|----|------------|-------------|
| FR-002-001 | COMP-003-008 | AC-002-001 |
| FR-002-002 | COMP-003-008 | AC-002-002 |
| FR-002-003 | COMP-003-006 | AC-002-004, AC-002-026, AC-002-028 |
| FR-002-004 | COMP-003-006 | AC-002-005, AC-002-026 |
| FR-002-005 | COMP-003-006 | AC-002-006 |
| FR-002-006 | COMP-003-008 | AC-002-007 |
| FR-002-007 | COMP-003-008 | AC-002-008, AC-002-028 |
| FR-002-008 | COMP-003-009 | AC-002-003 |
| FR-002-009 | COMP-003-023 | AC-002-009 |
| FR-002-010 | COMP-003-011 | AC-002-010, AC-002-014 |
| FR-002-011 | COMP-003-012 | AC-002-011 |
| FR-002-012 | COMP-003-011 | AC-002-012, AC-002-015 |
| FR-002-013 | COMP-003-024 | AC-002-013 |
| FR-002-014 | COMP-003-014 | AC-002-016, AC-002-024 |
| FR-002-015 | COMP-003-014 | AC-002-017 |
| FR-002-016 | COMP-003-015 | AC-002-018 |
| FR-002-017 | COMP-003-014 | AC-002-019 |
| FR-002-018 | COMP-003-014 | AC-002-020 |
| FR-002-019 | COMP-003-014 | AC-002-021 |
| FR-002-020 | COMP-003-014 | AC-002-022, AC-002-024 |
| FR-002-021 | COMP-003-018 | AC-002-023 |
| FR-002-022 | COMP-003-013 | AC-002-016 |
| FR-002-023 | COMP-003-024 | AC-002-027 |
| FR-002-024 | COMP-003-008 | AC-002-029 |
| NFR-002-001 | COMP-003-016 | AC-002-014 |
| NFR-002-002 | COMP-003-011 | AC-002-015 |
| NFR-002-003 | COMP-003-003 | AC-002-024, AC-002-029 |
| NFR-002-004 | COMP-003-008 | AC-002-024 |
| NFR-002-005 | COMP-003-005 | AC-002-002, AC-002-024 |
| NFR-002-006 | COMP-003-009 | AC-002-003 |
| NFR-002-007 | COMP-003-017 | AC-002-025 |
| NFR-002-008 | COMP-003-010 | AC-002-001 |
| NFR-002-009 | COMP-003-023 | AC-002-009 |

## 8. Riscos técnicos

- **TRISK-003-001** — `trust proxy: 1` pode não ser o número correto de proxies na plataforma de deploy; errar recoloca o bypass do freio de login (`X-Forwarded-For` forjável) e falseia `req.ip` na auditoria. Mitigação: verificar no ambiente real e documentar; o contador em memória do `express-rate-limit` é por instância em serverless — proteção real exige store compartilhado (dívida conhecida, registrada aqui).
- **TRISK-003-002** — Cookie cross-domain (`SameSite=None` + anti-CSRF) não desenhado; F1 assume mesmo site (dev local, `CORS_ORIGINS`). Mitigação: verificação de `Origin`/`Host` nas rotas POST de auth agora; token anti-CSRF quando o deploy for cross-domain (é o `Reabrir se:` da DEC-003-004).
- **TRISK-003-003** — Uma consulta de sessão por requisição autenticada (design de token opaco). Mitigação: escala de equipe interna (dezenas de usuários), consulta indexada por `accessTokenHash @unique`; revisitar com cache de sessão se for **medido** como gargalo (é o `Reabrir se:` da DEC-003-002).
- **TRISK-003-004** — Dependências novas (`@node-rs/argon2`, `cookie-parser`) entram na árvore — cadeia de suprimento (RISK-002-003). Mitigação: `npm audit --omit=dev --audit-level=high` na DoD; pin de versão; `/keelson:audit` sobre o diff de F1.
- **TRISK-003-005** — Janela de graça da rotação concorrente (A-002-018) é área de corrida; implementação ingênua rotaciona duas vezes ou revoga uma família legítima. Mitigação: `session-rotation.ts` como função pura testável (`tests/unit/`) + rotação em `prisma.$transaction` com o `@unique` dos hashes como trava; teste de integração de refresh concorrente (AC-002-026).
- **TRISK-003-006** — `JWT_EXPIRES_IN` vira config morta (DEC-003-002 usa `AUTH_ACCESS_TTL_MINUTES`). Mitigação: nota nesta seção e no `.env.example`; remoção da chave fora do escopo de F1.

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos (24) têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos (9) têm verificação
- [ ] Decisões DEC-003-001..012 refletidas no código
- [ ] Aderência à ficha/perfil validada (backend `node-22.md`, frontend `next-16.md`; READMEs dos repos)
- [ ] Todos os 29 ACs cobertos por teste (gate 1 dos quality gates) — inclui prova de 401/403 sem/insuficiente credencial (§6.3 do perfil) e teste de refresh concorrente (AC-002-026)
- [ ] Métrica da SPEC (§1.3 declara `Fonte de medição`: externa): a **suíte de conformidade de rotas** (COMP-003-019) — teste de integração que enumera as rotas montadas e prova, para cada não-pública, 401 sem sessão e 403 com papel insuficiente — está verde no CI; dono (time de engenharia) e natureza (conformidade, não instrumentação de evento) registrados no INDEX
- [ ] Toda rota não-pública montada aparece em `ROUTE_ROLES` (ou em `PUBLIC_PATH_ALLOWLIST`); rota em nenhum dos dois → negada — provado pela suíte de conformidade (COMP-003-019)
- [ ] `npm audit --omit=dev --audit-level=high` limpo no backend após `@node-rs/argon2` e `cookie-parser`
- [ ] Migração `add_session_and_user_disabled` versionada e presente no diff da TASK, com `prisma generate` executado
- [ ] Tipos de papel e de usuário de sessão (`USER_ROLES` / `SessionUser`) espelhados em `mnemonicos-backend/src/domain/types.ts` e `mnemonicos-frontend/src/types/domain.ts` **no mesmo diff** (NFR-002-007 / AC-002-025)
- [ ] `gates.security` (ficha) satisfeito; `gates.screenVerify` fechado para a tela de login e o shell interno
- [ ] Nenhum valor de senha, credencial de acesso ou token de renovação em log ou em resposta da API (NFR-002-004 / AC-002-024) — verificado por teste

## 10. Não coberto por este PLAN

Nada da SPEC-002 fica de fora — cobertura total (24 FRs, 9 NFRs, 29 ACs). Explicitamente fora, por decisão da própria SPEC (§4.2) e portanto não planejado aqui:

- Recuperação de senha self-service, 2FA/MFA, SSO, "lembrar-me" além dos 7 dias.
- Reativação de conta desativada; alteração de papel de conta existente; exclusão definitiva de conta.
- UI completa de gestão de equipe (só as telas mínimas de login, logout e guard entram; a gestão roda por rota de API).
- Rotas `/mnemonics` e `/flashcards/due` já chamadas pelo frontend sem existir no backend — fatia F2.
- Contrato definitivo de `/disciplines` (F1 só a torna protegida — A-002-019); leitura da trilha de auditoria (UI, exportação, retenção) — insumo de investigação, não entregável de leitura nesta fatia.
- Separar o papel de revisor jurídico do de ADMIN e checagem de segregação de funções aplicada pelo sistema — fatia F9 (RISK-002-001).
- Remoção da chave `JWT_EXPIRES_IN` da `env` (config morta após DEC-003-002 — TRISK-003-006).
- Store compartilhado para o rate limit em deploy multi-instância (TRISK-003-001) e desenho de cookie cross-domain (TRISK-003-002).
