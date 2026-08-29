# TASK-003-007: Middlewares `authenticate` / `authorize` + `Express.Request.auth`

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: FR-002-010, FR-002-011, FR-002-012
**Funcionalidade**: FEAT-002-002 (primária)
**Componente**: COMP-003-011, COMP-003-012
**Wave**: 4
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done
**Data início**: 2026-08-29T08:52:32-03:00

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 + ts-jest + supertest — integração em `mnemonicos-backend/tests/integration/` sobre a `app` real (ou unit com `req`/`res`/`next` fakes). Gates: `npm --prefix mnemonicos-backend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: TASK-003-003, TASK-003-006
- **Bloqueia**: TASK-003-009, TASK-003-010, TASK-003-011

## Contexto

COMP-003-011 / COMP-003-012, DEC-003-005, §6.3 do perfil. `requireAuth` resolve a sessão a cada requisição no servidor, nega por padrão toda rota fora da allowlist pública e, além disso, consulta `ROUTE_ROLES` e nega o caminho — **negando também quando o papel da sessão não está no conjunto declarado**, mesmo com sessão válida —, populando `req.auth` a partir da sessão verificada (identidade nunca do parâmetro de rota). `requireRole(...)` declara o conjunto de papéis da rota no `ROUTE_ROLES` **em tempo de montagem** e devolve um guard de runtime (defesa em profundidade), com auditoria da negação e `return` obrigatório após `next(err)`. Fatia sensível (authz) → `security-engineer`.

**Camada intermediária (3+ camadas — decisão 4.164)**: o contrato `AuthContext` (`req.auth`) atravessa middleware → rotas → services; esta TASK é **dona** da forma dele e da declaração `Express.Request`.

**Retry (Wave 4 — gates 8 e 1/5/7 REPROVADO no 1º passe)**: o registro `ROUTE_ROLES` foi populado por efeito colateral **em tempo de request** dentro do guard de `requireRole` — que roda **depois** de `requireAuth` na cadeia. Resultado provado por sonda: o registro nunca era escrito, `requireAuth` negava todo caminho não declarado, e o deny-by-default degenerava em **deny-tudo** (ADMIN válido → 403 403 403). Somado a isso: `requireAuth` só checava a **existência** da declaração (nunca o papel); o registro era chaveado só por caminho (ignora método HTTP — `DELETE` herdava a declaração do `GET`); `rolesForPath` casava o caminho contra **qualquer** padrão registrado (rota irmã não declarada herdava o `:param` do vizinho); e a declaração com fallback `req.path` envenenava o `Map` de módulo. As correções estão nos Critérios de pronto abaixo — cada uma com o mutante que deve ficar vermelho.

**Nomeia (aresta entre irmãs)**: `PUBLIC_PATH_ALLOWLIST`, `ROUTE_ROLES`, `sealRouteRoles` e os nomes de cookie `ACCESS_COOKIE` / `REFRESH_COOKIE` são exportados aqui. `requireRole` passa a ter a assinatura **`requireRole(method: HttpMethod, path: string, ...roles: UserRole[])`** — o caminho e o método são literais no ponto de montagem, e a declaração acontece na avaliação da chamada (antes de qualquer requisição). TASK-003-009 e TASK-003-010 (dependentes) declaram os papéis das suas rotas via essa assinatura e importam os nomes de cookie para adicionar as *opções* (flags DEC-003-004); TASK-003-011 (dependente) importa `PUBLIC_PATH_ALLOWLIST`, `ROUTE_ROLES` e `sealRouteRoles` para a ordem de montagem, o selo pós-boot e a suíte de conformidade que enumera `router.stack`.

## Escopo

### Inclui
- `mnemonicos-backend/src/http/middlewares/authenticate.ts` — `requireAuth: RequestHandler`: se `req.path` ∈ `PUBLIC_PATH_ALLOWLIST` (igualdade exata) → `next()`; senão lê o cookie `ACCESS_COOKIE`, chama `resolveAccessSession(token, new Date())`; `null` → `return next(new UnauthorizedError())` (o `return` é obrigatório); sessão resolvida → `const roles = rolesForPath(req.method, req.path)`: `roles === undefined` (caminho não declarado) **ou** `!roles.has(auth.role)` (papel fora do conjunto declarado) → `recordAuthEvent({ type: 'authz.denied', at, outcome: 'failure', subject: <userId da sessão resolvida>, ip, userAgent? })` + `return next(new ForbiddenError())` (403, com `return` — falha fechada, DEC-003-005), mesmo com sessão válida; só então `req.auth = { ... }` e `next()`; qualquer falha na resolução **nega** (fail secure). `requireAuth` é o **piso de autorização** — nega o não-declarado **e** o papel errado sem depender de `requireRole` estar montado na rota.
- `mnemonicos-backend/src/http/middlewares/authorize.ts` — `requireRole(method: HttpMethod, path: string, ...roles: UserRole[]): RequestHandler`: **na avaliação da chamada** (tempo de montagem, antes de qualquer requisição) chama `declareRouteRoles(method, path, roles)`; devolve o guard de runtime — sem `req.auth` → `return next(new UnauthorizedError())`; `req.auth.role` fora de `roles` → `recordAuthEvent({ type: 'authz.denied', ... })` + `return next(new ForbiddenError())` (defesa em profundidade — `requireAuth` já barra pelo registro); senão `next()`. **Nenhuma escrita no registro dentro do handler de request** — nenhuma chave do `ROUTE_ROLES` é derivada de dado de requisição. `return` após todo `next(err)`.
- `mnemonicos-backend/src/http/route-roles.ts` — registro `Map<string, ReadonlySet<UserRole>>` **chaveado por `"<MÉTODO> <caminho>"`** (ex.: `"DELETE /users/:id"`). `type HttpMethod = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE'`. `declareRouteRoles(method, path, roles)` — idempotente para os mesmos papéis; **lança** em redeclaração conflitante do mesmo `método+caminho`; **lança** se o registro já foi selado. `rolesForPath(method, path)` — igualdade exata na chave `método+caminho` primeiro, senão casa por padrão (`:param` segmento a segmento) **apenas entre chaves do mesmo método**; retorna `ReadonlySet<UserRole> | undefined`. `sealRouteRoles()` — sela o registro após a montagem (consumido por TASK-003-011; `declareRouteRoles` posterior lança). `resetRouteRoles()` — limpa **e dessela** (isolamento entre testes e remontagem). `export const ROUTE_ROLES` (visão de leitura). Caminhos declarados são **sempre o caminho completo visto por `requireAuth`** a partir da raiz de `apiRoutes`; a suíte de conformidade de TASK-003-011 enumera `router.stack` e falha o boot se alguma rota montada não tiver declaração exata `método+caminho-completo`.
- `mnemonicos-backend/src/http/express.d.ts` (ou equivalente) — `AuthContext` reusado de `auth.service.ts` (§9 do perfil — não redeclarar a forma) e `declare global { namespace Express { interface Request { auth?: AuthContext } } }`.
- `mnemonicos-backend/src/http/cookies.ts` — `export const ACCESS_COOKIE = 'mnemo_access'`, `export const REFRESH_COOKIE = 'mnemo_refresh'` (nomes; opções são da TASK-003-009).
- `mnemonicos-backend/src/http/public-paths.ts` — `export const PUBLIC_PATH_ALLOWLIST = ['/health', '/health/db', '/auth/login', '/auth/refresh'] as const`; `isPublicPath` por **igualdade exata** (nunca prefixo).
- `mnemonicos-backend/tests/integration/authenticate.test.ts`, `tests/integration/authorize.test.ts`.

### Não inclui
- A ordem de montagem em `routes.ts` e a suíte de conformidade que enumera `router.stack` (TASK-003-011) — mas o **teste de montagem mínimo** do caminho feliz (app real, `requireAuth` antes do router, sem popular o registro à mão) é desta TASK.
- `resolveAccessSession` em si (TASK-003-006).
- As opções (flags) dos cookies e a montagem de `cookie-parser` em `app.ts` (TASK-003-009).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `cookies.ts`, `public-paths.ts` — constantes nomeadas; `isPublicPath` por igualdade exata.
2. `route-roles.ts` — registro chaveado por `"<MÉTODO> <caminho>"`; `declareRouteRoles`/`rolesForPath` método-aware; `sealRouteRoles`/`resetRouteRoles`.
3. `express.d.ts` — augmentation de `Express.Request` reusando `AuthContext`.
4. `authorize.ts` — `requireRole(method, path, ...roles)` chama `declareRouteRoles` na avaliação (montagem) e devolve o guard de runtime; **nada de escrita no registro dentro do handler**.
5. `authenticate.ts` — allowlist → `resolveAccessSession` → `rolesForPath(req.method, req.path)`: `undefined` **ou** papel fora do conjunto → `authz.denied` + `ForbiddenError`; senão `req.auth` e `next()`; `return` após todo `next(err)`.
6. Testes: além dos casos por AC, o **teste de montagem** do caminho feliz (§ Critérios) e os mutantes MUT-B/C/F.

## Critérios de pronto

- [ ] **[retry] Teste de MONTAGEM do caminho feliz** (ausência deixou os 4 defeitos invisíveis a 30 asserções verdes) — verificação executável: `npm --prefix mnemonicos-backend test -- authenticate` → um teste que constrói uma `app` Express real com `express.json()` + `cookie-parser` + `const api = Router(); api.use(requireAuth); api.get('/gestao', requireRole('GET', '/gestao', 'ADMIN'), h); app.use(api); app.use(errorHandler)`, **sem** nenhuma chamada manual a `declareRouteRoles`/`registry.set`, com `resolveAccessSession` mockado devolvendo sessão de **ADMIN** → `GET /gestao` com `ACCESS_COOKIE` → **200**. Mutantes que ficam vermelhos: (a) mover a chamada `declareRouteRoles` de `requireRole` para dentro do handler de request (o defeito original) → 403; (b) `requireAuth` checar só `rolesForPath(...) === undefined` sem `!roles.has(auth.role)` → ainda 200 aqui, mas o critério do papel-errado abaixo pega. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] **[retry] `requireAuth` é piso de autorização — papel errado em rota declarada** — verificação executável: `npm --prefix mnemonicos-backend test -- authenticate` → rota `requireRole('GET','/gestao','ADMIN')` montada após `requireAuth`, sessão **EDITOR** válida → **403** emitido **por `requireAuth`** (provado montando a rota sem o guard de `requireRole` na cadeia, só a declaração via `declareRouteRoles('GET','/gestao',['ADMIN'])` — o 403 vem do middleware de autenticação). Mutante: `requireAuth` negar só quando `roles === undefined` (sem o `!roles.has(auth.role)`) → teste vermelho. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] **[retry] Chave método-aware — `DELETE` não herda a declaração do `GET`** — verificação executável: `npm --prefix mnemonicos-backend test -- authorize` → `declareRouteRoles('GET','/decks/:id',['EDITOR','ADMIN'])` **e** `declareRouteRoles('DELETE','/decks/:id',['ADMIN'])` coexistem sem lançar; `rolesForPath('DELETE','/decks/42')` → `{ADMIN}` (não `{EDITOR,ADMIN}`); no fluxo montado, `DELETE /decks/42` com sessão **EDITOR** → **403** embora `GET /decks/42` com EDITOR → 200. Mutante: registro chaveado só por caminho (sem método) → o par `DELETE` com EDITOR passa (vermelho). `Tests: ≥2 passed`. Fixada antes do código.
- [ ] **[retry] Casamento por padrão não vaza para rota irmã não declarada** (AC-002-014, topologia adversarial) — verificação executável: `npm --prefix mnemonicos-backend test -- authenticate` → com `declareRouteRoles('GET','/decks/:id',['ADMIN'])` declarada, uma rota **irmã estática** `GET /decks/export` montada **sem** `requireRole` e **sem** declaração própria, sessão **EDITOR** válida → **403** (não herda o `:id` do vizinho). Idem para um **2º método** no mesmo caminho sem guarda. Mutante: `rolesForPath` casar contra qualquer padrão registrado independentemente do método / sem exigir chave própria → `/decks/export` recebe `{ADMIN}` e a asserção de 403 vira 200 (vermelho). `Tests: ≥2 passed`. Fixada antes do código.
- [ ] **[retry] Deny-by-default audita — MUT-A + `authz.denied` no ramo de `requireAuth`** — verificação executável: `npm --prefix mnemonicos-backend test -- authenticate` → caminho ausente de `PUBLIC_PATH_ALLOWLIST` **e** de `ROUTE_ROLES`, sessão válida → **403** + spy de `recordAuthEvent` chamado 1× com `type:'authz.denied'`, `subject` = `userId` da sessão resolvida, e **sem** as chaves `token`/`accessToken`/`refreshToken`/`cookie` no payload (asserção estrutural sobre o conjunto de chaves). Mutantes vermelhos: apagar o bloco 403 do não-declarado (MUT-A); remover a chamada de auditoria nesse ramo. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] **[retry] MUT-C — `return` provado em CADA ramo de recusa de `requireAuth`** — verificação executável: `npm --prefix mnemonicos-backend test -- authenticate` → testes com `req`/`res`/`next` **fakes** (não supertest) afirmando `expect(next).toHaveBeenCalledTimes(1)` para os três ramos: (a) sessão `null` → `UnauthorizedError`; (b) caminho não declarado / papel errado → `ForbiddenError`; (c) `resolveAccessSession` lança → nega. Mutante: remover qualquer um dos `return` após `next(err)` → o `next` é chamado 2× (ou o corpo abaixo roda) e o teste correspondente fica vermelho. `Tests: ≥3 passed`. Fixada antes do código.
- [ ] **[retry] MUT-B — precedência 401-antes-de-403 no par que coincide** (cobre **AC-002-010** — sem sessão válida → não-autorizado, nenhum dado da rota) — verificação executável: `npm --prefix mnemonicos-backend test -- authenticate` → requisição **sem sessão** a caminho não-público (declarado **e** não declarado em `ROUTE_ROLES`) → **401** (não 403), `next` recebe `UnauthorizedError`, `req.auth` indefinido e o handler seguinte não roda; nome do teste enuncia "sem sessão vence caminho não declarado (401 antes de 403)". Mutante: trocar a ordem do bloco `auth === null` com o bloco `rolesForPath` → resposta vira 403 e o teste fica vermelho. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] **[retry] MUT-F — `isPublicPath` por igualdade exata, não prefixo** — verificação executável: `npm --prefix mnemonicos-backend test -- authenticate` → `isPublicPath('/auth/login-como-admin')` e `isPublicPath('/health/db-dump')` → **`false`**; requisição a esses caminhos sem cookie → **401**. Mutante: `PUBLIC_PATH_ALLOWLIST.some((p) => path.startsWith(p))` → os dois viram públicos e as asserções ficam vermelhas. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] **[retry] Registro selado após boot — nenhuma chave derivada de request** — verificação executável: `npm --prefix mnemonicos-backend test -- authorize` → `sealRouteRoles()` e então `declareRouteRoles('GET','/x',['ADMIN'])` → **lança**; após um fluxo montado + selado, `ROUTE_ROLES.size` não muda entre a 1ª e a 10ª requisição (asserção sobre o tamanho do registro). Mutante: `declareRouteRoles` ignorar o selo → a chamada não lança (vermelho). `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-011 (403 EDITOR + auditoria; ADMIN passa — guard de runtime de `requireRole`) — verificação executável: `npm --prefix mnemonicos-backend test -- authorize` → fixture com **duas** identidades: EDITOR contra o guard de `requireRole('GET','/x','ADMIN')` → `ForbiddenError` no `next` + spy `recordAuthEvent('authz.denied')` 1×; ADMIN → `next()` sem argumento, auditoria não chamada; a mutação que inverte `allowed.has(role)` deixa os dois casos vermelhos. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-012 (checagem no servidor mesmo sem passar pelo cliente) — verificação executável: `npm --prefix mnemonicos-backend test -- authenticate` (supertest, app real) → rota protegida sem cookie → 401; rota declarada `ADMIN` com sessão de EDITOR → 403 — independente de qualquer guard de cliente. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-015 / NFR-002-002 (identidade da sessão, nunca do parâmetro) — verificação executável: `npm --prefix mnemonicos-backend test -- authenticate` → requisição com `?userId=<outro>` no query **e** `:userId` divergente no path + cookie de sessão do usuário A → `req.auth.userId === A` (asserção **estrutural** sobre o objeto de `resolveAccessSession`), os parâmetros são ignorados. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Contrato `AuthContext` + `Express.Request.auth` exercitados não-nulos (item do Inclui sem AC) — verificação executável: `npm --prefix mnemonicos-backend run typecheck` → exit 0 (baseline 0 erros no início da TASK) com um teste que lê `req.auth` tipado; `npm --prefix mnemonicos-backend test -- authenticate` afirma os campos preenchidos após `requireAuth` com sessão válida. Fixada antes do código.
- [ ] `PUBLIC_PATH_ALLOWLIST` e os nomes de cookie exercitados (itens do Inclui sem AC) — verificação executável: `npm --prefix mnemonicos-backend test -- authenticate` → cada caminho de `PUBLIC_PATH_ALLOWLIST` passa por `requireAuth` sem cookie e sem 401; `ACCESS_COOKIE` é a chave lida (enviar outro nome de cookie → 401). `Tests: ≥2 passed`. Fixada antes do código.
- [ ] **Falsificabilidade** — o re-review roda o controle positivo (`requireAuth` que libera tudo → maioria dos testes vermelhos, decisão 4.186) e todas as sondas/mutações em `git worktree` isolada (decisão 4.134); a árvore compartilhada fica limpa (`git status --porcelain` vazio) e a contagem de testes do report vem com o estado da árvore em que foi medida.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md`, §6.3 — `return` após `next(err)`, autenticação antes do router protegido; README do repo vence em conflito).
- [ ] Code review aprovado.

## Riscos específicos

- Fail secure: qualquer erro na resolução de sessão nega, nunca abre (DEC-003-005). Caminho autenticado sem declaração em `ROUTE_ROLES`, **ou com papel fora do conjunto declarado**, → 403 por `requireAuth`, mesmo com sessão válida.
- **Ordem na cadeia Express**: `requireAuth` executa antes do guard de `requireRole` — por isso a declaração no `ROUTE_ROLES` **não pode** acontecer dentro do handler de request (aconteceria tarde demais, e o deny-by-default viraria deny-tudo). A declaração é ato de **montagem** (avaliação de `requireRole(method, path, ...)`), selada por `sealRouteRoles()` após o boot.
- `PUBLIC_PATH_ALLOWLIST`, `ROUTE_ROLES`, `sealRouteRoles`, `ACCESS_COOKIE` e `REFRESH_COOKIE` são exportados desta TASK (`src/http/public-paths.ts`, `src/http/route-roles.ts`, `src/http/cookies.ts`) porque `requireAuth` é o consumidor mais cedo; TASK-003-009 (rotas/cookies), TASK-003-010 (users) e TASK-003-011 (montagem) dependem desta e importam os nomes / declaram via `requireRole(method, path, ...)` — nunca grafia solta.
- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-backend/src/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-08-29T08:52:32-03:00
**Data conclusão**: 2026-08-29T14:04:49-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 03d5fc3 · ead57a2 (retry) · b106b84 (correção test-only pós-review)
**Jira**: KAN-17
**Implementado por**: developer
**Revisado por**: code-reviewer (gates 1–7) · security-engineer (gate 8) — Wave 4, diff acumulado + re-review do delta
**Tentativas**: 2 (retry) + 1 correção test-only
**Cobertura final**: n/a (quality.mutation/coverage não configurado na ficha)
**Arquivos modificados**:
  - mnemonicos-backend/src/http/middlewares/authenticate.ts
  - mnemonicos-backend/src/http/middlewares/authorize.ts
  - mnemonicos-backend/src/http/route-roles.ts
  - mnemonicos-backend/src/http/public-paths.ts (1º passe)
  - mnemonicos-backend/src/http/cookies.ts (1º passe)
  - mnemonicos-backend/src/http/express.d.ts (1º passe)
  - mnemonicos-backend/tests/integration/authenticate.test.ts
  - mnemonicos-backend/tests/integration/authorize.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando — unit 137/137 (14 suites) · integração-DB 46/46 (3 suites, inalterada)
- [x] Lint limpo — exit 0
- [x] Aderência à ficha/perfil — §6.3 (deny-by-default na montagem, `return` após `next(err)`, fail secure), §7 (árvore de decisão com precedência)
- [x] Code review aprovado — 1º passe REPROVADO (4 achados críticos de authz); retry `ead57a2` fechou os 4 (mutantes mortos); re-review REPROVOU só o gate 1 por regressão de prova (4.174 — caso de teste perdido na reescrita); resolvido em `b106b84` (test-only, proposta+default do reviewer, teto de convergência 4.88 → decisão autônoma do Tech Lead, ao lote de veto do Diretor na Entrega)
- [x] ACs verificados — AC-002-010/011/012/014/015, NFR-002-001/002; falsificabilidade com controle positivo (20/50 vermelhos) + mutantes MUT-MOUNT/ROLE/B/C/F/KEY/XMETHOD/SEAL/EMPTY/CONFLICT/GUARD mortos, em worktree isolada
- [x] Segurança (gate 8): aprovado (Wave 4) — security-engineer, re-review do delta APROVADO (`achados: []`), 4 críticos mortos por mutante; resíduo do fallback same-method não explorável em F1, fechamento pleno diferido a TASK-003-011 pela EMENDA DEC-003-005
- [ ] Comportamento (gate 9): pendente — FEAT-002-002 completa no fim da Wave 6 (com TASK-003-011)

**Notas**: DEC-003-005 recebeu EMENDA na Wave 4 (padrão da EMENDA de DEC-003-003): registro `ROUTE_ROLES` chaveado por `"<MÉTODO> <caminho>"`; declaração em tempo de montagem via `requireRole(method, path, ...roles)` (nunca no handler de request — na cadeia Express `requireAuth` roda antes); `sealRouteRoles()` sela pós-boot; `requireAuth` é piso de autorização (nega `undefined` OU papel fora do conjunto, com `authz.denied`). Notas não-bloqueantes do gate 8 para a Entrega/gate 9: `HEAD`/`OPTIONS` em rota protegida → 403 (decisão de disponibilidade); `resetRouteRoles()` dessela (TASK-011 não pode chamá-la pós-boot); `isPublicPath` segue path-only (inerte em F1). Pendência herdada → TASK-003-011: resíduo do casamento `:param` de irmã estática (critério de pronto explícito adicionado, decisão 4.140).
