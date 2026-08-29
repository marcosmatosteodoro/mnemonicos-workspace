# TASK-003-009: Rotas de auth + cookies de sessão + `cookie-parser`

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: nenhuma
**Componente**: COMP-003-010
**Wave**: 5
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 + ts-jest + supertest — integração em `mnemonicos-backend/tests/integration/` sobre a `app` real. Gates: `npm --prefix mnemonicos-backend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: TASK-003-006, TASK-003-008, TASK-003-001, TASK-003-007, TASK-003-016
- **Bloqueia**: TASK-003-011, TASK-003-013

## Contexto

COMP-003-010 / DEC-003-004 / §4 do PLAN. Superfície HTTP de auth: escrever/limpar os cookies de sessão com as flags exigidas (inacessível a script, `secure` em produção, same-site), e verificar `Origin`/`Host` nas rotas POST que mudam estado (Route Handlers não herdam proteção CSRF). As rotas protegidas declaram seu papel (`{EDITOR, ADMIN}`) via `requireRole` — a leitura B do deny-by-default (DEC-003-005) exige declaração explícita, e essa declaração é dona desta TASK (define `auth.routes.ts`), não só da montagem em TASK-003-011. Fatia sensível (endpoints novos + cookies + declaração de papel) → `security-engineer`.

**EMENDA DEC-003-005 (Wave 4 — vinculante)**: `requireRole` passou a ter a assinatura **`requireRole(method: HttpMethod, path: string, ...roles: UserRole[])`** e a declarar em `ROUTE_ROLES` **na avaliação da chamada** (tempo de montagem), com chave `"<MÉTODO> <caminho>"`. Toda aplicação de `requireRole` nesta TASK usa a assinatura nova, com o **método** e o **caminho completo visto por `requireAuth`** (a partir da raiz de `apiRoutes`: `/auth/logout`, `/auth/change-password`, `/auth/me`) — nunca a grafia relativa nem a assinatura antiga `requireRole('EDITOR','ADMIN')`. `sealRouteRoles()` é chamado por TASK-003-011 na montagem, não aqui.

**Consome (aresta)**: `ACCESS_COOKIE` / `REFRESH_COOKIE` (nomes — TASK-003-007) por nome; `requireRole(method, path, ...roles)` e `ROUTE_ROLES` (TASK-003-007, assinatura da EMENDA Wave 4); `loginRateLimiters` (TASK-003-008); `login`/`refresh`/`logout`/`changeOwnPassword` de `auth.service` (TASK-003-006). **Nomeia**: `accessCookieOptions()` / `refreshCookieOptions()` (opções da DEC-003-004), consumidas pelo `logout` e por fatias futuras; **`getSessionUser`** em `auth.service.ts` (furo no plano da Wave 5 — nasce neste diff, EMENDA em PLAN COMP-003-008).

## Escopo

### Inclui
- As rotas `POST /auth/refresh` e `POST /auth/logout` (e `POST /auth/login`) passam ao service um `ctx` de origem `{ ip: req.ip, userAgent: req.get('user-agent') }` — o `refresh`/`logout` de TASK-003-006 exigem esse `ctx` para o indicador de origem obrigatório dos eventos de auditoria (NFR-002-005 × `audit.ts` selado na Wave 2).
- `mnemonicos-backend/src/modules/auth/auth.routes.ts` — `authRoutes: Router`:
  - `POST /auth/login` (público; precedido por `loginRateLimiters`) → `login`; sucesso → `res.cookie(ACCESS_COOKIE, ...)` e `res.cookie(REFRESH_COOKIE, ...)`; corpo = `SessionUser` (sem token).
  - `POST /auth/refresh` (público) → lê `REFRESH_COOKIE` do cookie, `refresh`; reemite os dois cookies.
  - `POST /auth/logout` (protegido; `requireRole('POST', '/auth/logout', 'EDITOR', 'ADMIN')`) → `logout`; `res.clearCookie` dos dois.
  - `POST /auth/change-password` (protegido; `requireRole('POST', '/auth/change-password', 'EDITOR', 'ADMIN')`) → `changeOwnPassword` (usa `req.auth`).
  - `GET /auth/me` (protegido; `requireRole('GET', '/auth/me', 'EDITOR', 'ADMIN')`) → `getSessionUser(req.auth.userId)` → `SessionUser` da sessão corrente; `null` → 401.
- `mnemonicos-backend/src/modules/auth/auth.service.ts` — **acrescenta** `getSessionUser(userId: string): Promise<SessionUser | null>` (**furo no plano da Wave 5** — `req.auth`/`resolveAccessSession` não carregam `name`/`email`, e o caminho quente não deve carregar; EMENDA em PLAN COMP-003-008/010). `where: { id: userId, disabledAt: null }` — a cláusula **é** a guarda de conta desativada (checklist "Consumidores de sessão do auth.service", README §72–76); `select` **explícito** `{ id, name, email, role }`; **nunca** `passwordHash` nem valor de token. **Não** altera `resolveAccessSession` nem `AuthContext` (lição de perf do gate 10 da Wave 3 — o caminho por requisição segue trim).
  - As rotas protegidas aplicam `requireRole(<método>, <caminho>, 'EDITOR', 'ADMIN')` (importado de TASK-003-007, assinatura da EMENDA Wave 4), declarando `"POST /auth/logout"`, `"POST /auth/change-password"` e `"GET /auth/me"` em `ROUTE_ROLES` **em tempo de montagem**; as públicas (`/auth/login`, `/auth/refresh`) **não** recebem `requireRole` e entram em `PUBLIC_PATH_ALLOWLIST` (item já previsto em TASK-003-007).
  - Middleware local de verificação de `Origin`/`Host` nas rotas POST que mudam estado. Sem `try/catch` (Express 5 encaminha a rejeição).
- `ACCESS_COOKIE` / `REFRESH_COOKIE` importados de `mnemonicos-backend/src/http/cookies.ts` (TASK-003-007) — nomes **consumidos, nunca redefinidos** aqui.
- Opções de cookie da DEC-003-004 (definidas nesta TASK): `mnemo_access` (`path '/'`, `httpOnly`, `sameSite: 'lax'`, `secure: env.COOKIE_SECURE`, `maxAge` = `AUTH_ACCESS_TTL_MINUTES`); `mnemo_refresh` (`path '/api/v1/auth'`, demais flags iguais, `maxAge` = `AUTH_REFRESH_TTL_DAYS`). Sem assinatura de cookie.
- `mnemonicos-backend/src/app.ts` — montar `cookie-parser` antes de `apiRoutes`, **sem segredo** (`cookieParser()` — o projeto usa token opaco + HMAC no banco, DEC-003-002; cookie assinado criaria um 2º mecanismo de integridade e ativaria o `cookie-signature@1.0.6` transitivo, que compara com `==`). A dependência `cookie-parser` foi adicionada em TASK-003-003; aqui ela é montada.
- `mnemonicos-backend/tests/integration/auth.routes.test.ts`.
- Meio de execução dos `*.integration.test.ts` desta TASK: o harness de TASK-003-016 — config `jest.integration.config.ts`, helper `tests/integration/db.ts` (`testPrisma` + `resetDb()` no `beforeEach`), comando `npm --prefix mnemonicos-backend run test:integration`.

### Não inclui
- A regra de sessão (`login`/`refresh`/`logout`/`changeOwnPassword`/`resolveAccessSession`/`decideRefresh` — TASK-003-006) — **exceto** o leitor fino `getSessionUser`, que `GET /auth/me` exige e nasce aqui (furo no plano da Wave 5, EMENDA no PLAN).
- A ordem de `requireAuth` na montagem de `apiRoutes` e a suíte de conformidade (TASK-003-011).
- Os middlewares `requireAuth` / `requireRole` em si (TASK-003-007).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `app.ts` — `app.use(cookieParser())` (sem segredo) antes de `apiRoutes`.
2. `auth.service.ts` — acrescenta `getSessionUser(userId)` (`where: { id, disabledAt: null }`, `select` explícito `{id,name,email,role}`), sem tocar `resolveAccessSession`/`AuthContext`.
3. `auth.routes.ts` — os 5 endpoints; `requireRole(<método>, <caminho completo>, 'EDITOR', 'ADMIN')` (assinatura da EMENDA Wave 4) nas três protegidas; `GET /auth/me` → `getSessionUser(req.auth.userId)`; builders `accessCookieOptions()` / `refreshCookieOptions()` a partir de `env`.
3. Middleware local de `Origin`/`Host` contra `CORS_ORIGINS` nas rotas POST.
4. Testes de integração sobre a `app` real, asserção estrutural sobre cada `Set-Cookie` e sobre `ROUTE_ROLES`.

## Critérios de pronto

- [ ] Testes cobrem AC-002-001 (login estabelece sessão: cookie + refresh persistido + auditoria de sucesso) — verificação executável: `npm --prefix mnemonicos-backend test -- auth.routes` → `POST /auth/login` com credenciais corretas → asserção **estrutural** sobre os atributos de cada `Set-Cookie` (`HttpOnly`; `Secure` presente sse `env.COOKIE_SECURE`; `SameSite=Lax`; `mnemo_refresh` com `Path=/api/v1/auth`; `Max-Age` = TTL respectivo), ausência das chaves `accessToken`/`refreshToken` no JSON (corpo = `SessionUser`), uma linha `Session` nova cujo `refreshTokenHash` != valor em claro, e `recordAuthEvent('login.success')` chamado. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Rotas de auth protegidas declaram papel (AC-002-014 na superfície de auth) — verificação executável: `npm --prefix mnemonicos-backend test -- auth.routes` (ou `route-authz-matrix`) → `ROUTE_ROLES` contém as **chaves método-aware** `"POST /auth/logout"`, `"POST /auth/change-password"`, `"GET /auth/me"` com `['EDITOR','ADMIN']` (igualdade de chave, não `rolesForPath` com fallback); `GET /auth/me` com sessão de EDITOR válida → 200 (não 403); sem sessão → 401; sessão de EDITOR em `GET /auth/me` **passa** mas um método não declarado no mesmo caminho (`DELETE /auth/me`) → 403. A mutação que remove `requireRole` de uma dessas rotas deixa o teste da matriz de conformidade vermelho (rota não declarada → 403). `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Nomes de cookie consistentes entre login e logout (item do Inclui sem AC) — verificação executável: `npm --prefix mnemonicos-backend test -- auth.routes` → `POST /auth/login` define `ACCESS_COOKIE`/`REFRESH_COOKIE` e `POST /auth/logout` remove **os mesmos nomes** (`clearCookie`), com a reapresentação do cookie anterior → 401. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] `POST /auth/refresh` reemite os dois cookies; `POST /auth/logout` limpa os dois — verificação executável: `npm --prefix mnemonicos-backend test -- auth.routes` → refresh válido → 2 `Set-Cookie`; logout → 2 `Set-Cookie` com `Max-Age=0` / `Expires` no passado. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Verificação de `Origin`/`Host` nas rotas POST de auth — verificação executável: `npm --prefix mnemonicos-backend test -- auth.routes` → `POST /auth/login` com `Origin` fora de `CORS_ORIGINS` → 403; com `Origin` da allowlist → segue; **sem** `Origin` **e sem** `Referer` → segue (F1 assume mesmo site). `Tests: ≥2 passed`. Fixada antes do código.
- [ ] **[retry F4]** `verifyOrigin` — o ramo de `Referer` malformado é decisão deliberada, não um `catch` que engole — verificação executável: `npm --prefix mnemonicos-backend test -- auth.routes` → `POST /auth/login` com header `Referer` que não parseia como URL (ex.: `Referer: :::nao-url:::`) e **sem** `Origin` → **segue** (tratado como origem ausente), e o teste **nomeia** essa decisão ("Referer malformado ≡ origem ausente → segue"). A mutação que troca o `catch`/fallback por `next(new ForbiddenError())` deixa o teste vermelho (prova que "seguir" é a escolha, não acidente). `Tests: ≥1 passed`. Fixada antes do código.
- [ ] `cookie-parser` montado antes de `apiRoutes` — verificação executável: `npm --prefix mnemonicos-backend test -- auth.routes` → requisição com header `Cookie: mnemo_refresh=...` → o handler de `refresh` enxerga `req.cookies.mnemo_refresh` (não `undefined`; 200/401 conforme validade). `Tests: ≥1 passed`. Fixada antes do código.
- [ ] `GET /auth/me` devolve `SessionUser` sem token — verificação executável: `npm --prefix mnemonicos-backend test -- auth.routes` → chaves exatas `{id,name,email,role}` (asserção sobre o conjunto de chaves), sem `passwordHash`/`accessToken`/`refreshToken`. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] `getSessionUser` — leitura fina com guarda de conta desativada (furo no plano da Wave 5) — verificação executável: `npm --prefix mnemonicos-backend test -- auth` → fixture com **duas** contas, uma ativa e uma com `disabledAt != null`: `getSessionUser(ativa.id)` → `{id,name,email,role}` (conjunto exato, sem `passwordHash`); `getSessionUser(desativada.id)` → `null`; a mutação que remove `disabledAt: null` do `where` faz o segundo caso devolver o usuário (vermelho); a mutação que troca o `select` explícito por entidade crua / `include` expõe `passwordHash` (vermelho). `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md`, §5 — sem `try/catch` no handler; §6.5 — flags de cookie; README do repo vence em conflito).
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-003-002: cookie cross-domain (`SameSite=None` + anti-CSRF) não desenhado — F1 assume mesmo site (dev local + `CORS_ORIGINS`); a verificação de `Origin`/`Host` nas rotas POST é a mitigação agora.
- Os nomes `ACCESS_COOKIE`/`REFRESH_COOKIE`, `requireRole` (assinatura `(method, path, ...roles)` da EMENDA Wave 4) e `ROUTE_ROLES` são importados de `src/http/` (TASK-003-007, dependência declarada) — esta TASK adiciona só as *opções* de cookie (flags DEC-003-004) e **aplica** `requireRole` nas rotas protegidas, nunca redefine os nomes nem o registro.
- `HEAD`/`OPTIONS` numa rota protegida → 403 (`rolesForPath` só casa o método declarado) — nota do gate 8 da Wave 4; se um cliente HTTP legítimo precisar de preflight numa rota de auth, é decisão de disponibilidade a escalar, não a contornar abrindo a checagem.
- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-backend/src/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-19
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
