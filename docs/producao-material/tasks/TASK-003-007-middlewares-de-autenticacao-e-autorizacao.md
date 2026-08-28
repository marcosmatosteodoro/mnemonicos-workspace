# TASK-003-007: Middlewares `authenticate` / `authorize` + `Express.Request.auth`

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: FR-002-010, FR-002-011, FR-002-012
**Funcionalidade**: FEAT-002-002 (primária)
**Componente**: COMP-003-011, COMP-003-012
**Wave**: 4
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 + ts-jest + supertest — integração em `mnemonicos-backend/tests/integration/` sobre a `app` real (ou unit com `req`/`res`/`next` fakes). Gates: `npm --prefix mnemonicos-backend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: TASK-003-003, TASK-003-006
- **Bloqueia**: TASK-003-009, TASK-003-010, TASK-003-011

## Contexto

COMP-003-011 / COMP-003-012, DEC-003-005, §6.3 do perfil. `requireAuth` resolve a sessão a cada requisição no servidor, nega por padrão toda rota fora da allowlist pública e, além disso, consulta `ROUTE_ROLES` e nega o caminho que não declara papel (mesmo com sessão válida), populando `req.auth` a partir da sessão verificada (identidade nunca do parâmetro de rota). `requireRole(...roles)` restringe explicitamente por papel **e registra** o conjunto no `ROUTE_ROLES`, com auditoria da negação e `return` obrigatório após `next(err)`. Fatia sensível (authz) → `security-engineer`.

**Camada intermediária (3+ camadas — decisão 4.164)**: o contrato `AuthContext` (`req.auth`) atravessa middleware → rotas → services; esta TASK é **dona** da forma dele e da declaração `Express.Request`.

**Nomeia (aresta entre irmãs)**: `PUBLIC_PATH_ALLOWLIST`, `ROUTE_ROLES` e os nomes de cookie `ACCESS_COOKIE` / `REFRESH_COOKIE` são exportados aqui (`requireAuth` consulta a allowlist e o `ROUTE_ROLES`, e lê `mnemo_access`; `requireRole` popula `ROUTE_ROLES`); TASK-003-009 e TASK-003-010 (dependentes) declaram os papéis das suas rotas via `requireRole`, populando `ROUTE_ROLES`, e importam os nomes de cookie para adicionar as *opções* (flags DEC-003-004); TASK-003-011 (dependente) importa `PUBLIC_PATH_ALLOWLIST` e `ROUTE_ROLES` para a ordem de montagem e a suíte de conformidade.

## Escopo

### Inclui
- `mnemonicos-backend/src/http/middlewares/authenticate.ts` — `requireAuth: RequestHandler`: se `req.path` ∈ `PUBLIC_PATH_ALLOWLIST` → `next()`; senão lê o cookie `ACCESS_COOKIE`, chama `resolveAccessSession(token, new Date())`; `null` → `return next(new UnauthorizedError())` (o `return` é obrigatório); sessão resolvida mas o padrão de rota **ausente de `PUBLIC_PATH_ALLOWLIST` e de `ROUTE_ROLES`** → `return next(new ForbiddenError())` (403, com `return` — falha fechada, DEC-003-005), mesmo com sessão válida; sucesso → `req.auth = { userId, role, sessionId }` e `next()`; qualquer falha na resolução **nega** (fail secure).
- `mnemonicos-backend/src/http/middlewares/authorize.ts` — `requireRole(...roles: UserRole[]): RequestHandler`: no registro do router, **grava `roles` em `ROUTE_ROLES`** sob o caminho correspondente (forma canônica de declaração — consumida por `authenticate.ts`); em runtime: sem `req.auth` → `return next(new UnauthorizedError())`; `req.auth.role` fora de `roles` → `recordAuthEvent({ type: 'authz.denied', ... })` e `return next(new ForbiddenError())`; senão `next()`. Sempre com `return` após `next(err)`.
- `mnemonicos-backend/src/http/route-roles.ts` — `export const ROUTE_ROLES` (registro caminho→conjunto de papéis; `Map<string, readonly UserRole[]>` populado por `requireRole` no registro dos routers). Símbolo nomeado consumido por `authenticate.ts` (nega o não-declarado) e pelos routers das TASKs 003-009 / 003-010 via `requireRole`.
- `mnemonicos-backend/src/http/express.d.ts` (ou equivalente) — `interface AuthContext { userId: string; role: UserRole; sessionId: string }` e `declare global { namespace Express { interface Request { auth?: AuthContext } } }`.
- `mnemonicos-backend/src/http/cookies.ts` — `export const ACCESS_COOKIE = 'mnemo_access'`, `export const REFRESH_COOKIE = 'mnemo_refresh'` (nomes; opções são da TASK-003-009).
- `mnemonicos-backend/src/http/public-paths.ts` — `export const PUBLIC_PATH_ALLOWLIST = ['/health', '/health/db', '/auth/login', '/auth/refresh'] as const`.
- `mnemonicos-backend/tests/integration/authenticate.test.ts`, `tests/integration/authorize.test.ts`.

### Não inclui
- A ordem de montagem em `routes.ts` e a suíte de conformidade (TASK-003-011).
- `resolveAccessSession` em si (TASK-003-006).
- As opções (flags) dos cookies (TASK-003-009).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `cookies.ts`, `public-paths.ts` e `route-roles.ts` — as constantes/registros nomeados.
2. `express.d.ts` — `AuthContext` + augmentation de `Express.Request`.
3. `authenticate.ts` — allowlist → `resolveAccessSession` → consulta `ROUTE_ROLES` (não-declarado → `ForbiddenError`) → `req.auth` ou `return next(err)`.
4. `authorize.ts` — `requireRole` registra em `ROUTE_ROLES` e aplica a checagem, com auditoria e `return` após `next(err)`.

## Critérios de pronto

- [ ] Testes cobrem AC-002-010 (401 sem sessão, nenhum dado da rota; handler seguinte não roda) — verificação executável: `npm --prefix mnemonicos-backend test -- authenticate` → requisição sem `ACCESS_COOKIE` a caminho fora de `PUBLIC_PATH_ALLOWLIST` → `next` recebe `UnauthorizedError`, `req.auth` indefinido, o próximo handler não é chamado; a mutação que remove o `return` antes de `next(err)` é pega pela asserção de que o handler seguinte não roda. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-014 na camada de middleware (rota autenticada sem declaração de papel é negada — falha fechada) — verificação executável: `npm --prefix mnemonicos-backend test -- authenticate` → o teste monta uma rota de teste após `requireAuth` **sem** `requireRole` e faz uma requisição com **sessão de EDITOR válida** → **403** (asserção ancorada em `res.status` / erro `ForbiddenError`, não em texto); a mutação que faz o caminho ausente de `ROUTE_ROLES` cair em `next()` em vez de `ForbiddenError` deixa o teste vermelho. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-011 (403 EDITOR + auditoria; ADMIN passa) — verificação executável: `npm --prefix mnemonicos-backend test -- authorize` → fixture com **duas** identidades (`req.auth.role='EDITOR'` e `='ADMIN'`): EDITOR contra `requireRole('ADMIN')` → `ForbiddenError` no `next` + spy de `recordAuthEvent('authz.denied')` chamado 1×; ADMIN → `next()` sem argumento, auditoria não chamada; a mutação que inverte `roles.includes(role)` deixa os dois casos vermelhos. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-012 (checagem no servidor mesmo sem passar pelo cliente) — verificação executável: `npm --prefix mnemonicos-backend test -- authenticate` (supertest, chamada direta) → rota protegida sem cookie → 401; rota `requireRole('ADMIN')` com sessão de EDITOR → 403 — independente de qualquer guard de cliente. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-015 / NFR-002-002 (identidade da sessão, nunca do parâmetro) — verificação executável: `npm --prefix mnemonicos-backend test -- authenticate` → requisição com `?userId=<outro>` no query + cookie de sessão do usuário A → `req.auth.userId === A` (asserção **estrutural** sobre o objeto montado por `resolveAccessSession`), o parâmetro é ignorado. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] `requireRole` registra em `ROUTE_ROLES` (item do Inclui) — verificação executável: `npm --prefix mnemonicos-backend test -- authorize` → após registrar uma rota de teste com `requireRole('ADMIN')`, `ROUTE_ROLES` contém o caminho correspondente com `['ADMIN']`; a mutação que não grava em `ROUTE_ROLES` deixa o teste vermelho. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Contrato `AuthContext` + `Express.Request.auth` exercitados não-nulos (item do Inclui sem AC) — verificação executável: `npm --prefix mnemonicos-backend run typecheck` → exit 0 (baseline 0 erros no início da TASK) com um teste que lê `req.auth.userId`/`.role`/`.sessionId` tipados; `npm --prefix mnemonicos-backend test -- authenticate` afirma os três campos preenchidos após `requireAuth` com sessão válida. Fixada antes do código.
- [ ] `PUBLIC_PATH_ALLOWLIST` e os nomes de cookie exercitados (itens do Inclui sem AC) — verificação executável: `npm --prefix mnemonicos-backend test -- authenticate` → cada caminho de `PUBLIC_PATH_ALLOWLIST` passa por `requireAuth` sem cookie e sem 401; `ACCESS_COOKIE` é a chave lida (enviar outro nome de cookie → 401). `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md`, §6.3 — `return` após `next(err)`, autenticação antes do router protegido; README do repo vence em conflito).
- [ ] Code review aprovado.

## Riscos específicos

- Fail secure: qualquer erro na resolução de sessão nega, nunca abre (DEC-003-005). Caminho autenticado sem declaração em `ROUTE_ROLES` → 403, mesmo com sessão válida.
- `PUBLIC_PATH_ALLOWLIST`, `ROUTE_ROLES`, `ACCESS_COOKIE` e `REFRESH_COOKIE` são exportados desta TASK (`src/http/public-paths.ts`, `src/http/route-roles.ts`, `src/http/cookies.ts`) porque `requireAuth` é o consumidor mais cedo; TASK-003-009 (rotas/cookies), TASK-003-010 (users) e TASK-003-011 (montagem) dependem desta e importam os nomes / populam o registro — nunca grafia solta.
- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-backend/src/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-17
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
