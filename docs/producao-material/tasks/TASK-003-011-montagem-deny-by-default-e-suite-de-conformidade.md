# TASK-003-011: Montagem deny-by-default em `routes.ts` + suíte de conformidade

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: nenhuma
**Componente**: COMP-003-016, COMP-003-019
**Wave**: 6
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 + ts-jest + supertest — integração em `mnemonicos-backend/tests/integration/` sobre a `app` real. Gates: `npm --prefix mnemonicos-backend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: TASK-003-007, TASK-003-009, TASK-003-010
- **Bloqueia**: nenhuma

## Contexto

COMP-003-016 + COMP-003-019, DEC-003-005, §1.3 da SPEC (métrica de sucesso) e §9 da DoD do PLAN. É **a** barreira: `requireAuth` montado em `apiRoutes` **antes** de qualquer router de módulo e **depois** das rotas públicas, e todo router não-público declara seus papéis via `requireRole(...)` (populando `ROUTE_ROLES`), de modo que uma rota adicionada sem declaração nasça negada (falha fechada, 403 mesmo com sessão válida). Carrega o item de métrica: a suíte de conformidade que enumera as rotas montadas e prova 401/403 para cada não-pública — fonte de medição externa da §1.3.

**Consome (aresta)**: `PUBLIC_PATH_ALLOWLIST`, `ROUTE_ROLES` e `requireAuth`/`requireRole` (TASK-003-007); `authRoutes` (TASK-003-009); `usersRoutes` (TASK-003-010).

## Escopo

### Inclui
- `mnemonicos-backend/src/http/routes.ts` — `apiRoutes` monta nesta ordem: `healthRoutes` (público); rotas públicas de `authRoutes` (`/auth/login`, `/auth/refresh`); `apiRoutes.use(requireAuth)`; então `authRoutes` protegidas com `requireRole('EDITOR','ADMIN')` (`/auth/logout`, `/auth/change-password`, `/auth/me`), `usersRoutes` com `requireRole('ADMIN')`, `disciplinesRoutes` com `requireRole('EDITOR','ADMIN')`. `/disciplines` passa a exigir sessão **e** declaração de papel (A-002-019; SPEC §4.1.9). Ordem conferida em `createApp()`.
- `mnemonicos-backend/tests/integration/route-authz-matrix.test.ts` — deriva a lista de rotas de `apiRoutes.stack` (Express 5 removeu `app._router`); para cada caminho ∉ `PUBLIC_PATH_ALLOWLIST`: 401 sem cookie; para cada caminho sob `requireRole('ADMIN')`: 403 com sessão de `EDITOR`; o caso da rota fictícia montada **depois** de `requireAuth` e **sem** `requireRole` roda **com sessão de EDITOR** e espera **403** (não 401) — falha fechada por ausência de declaração em `ROUTE_ROLES` (AC-002-014). Assert de snapshot: `PUBLIC_PATH_ALLOWLIST` é **exatamente** `['/health','/health/db','/auth/login','/auth/refresh']` (crescer exige mudança deliberada). Assert global: nenhum handler montado que crie `User` (`prisma.user.create` ou o service de criação) está fora de um router com `requireRole('ADMIN')` registrado em `ROUTE_ROLES` (AC-002-018, além de `usersRoutes`). Oráculo capaz de falhar: remover `requireAuth` da montagem, ou remover a declaração de `/disciplines` de `ROUTE_ROLES`, torna o teste vermelho.

### Não inclui
- Os middlewares em si (TASK-003-007).
- As rotas de auth / users (TASKs 003-009, 003-010).
- Contrato definitivo de `/disciplines` (fatia F2).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Reordenar `routes.ts`: públicas → `apiRoutes.use(requireAuth)` → routers protegidos, cada um com `requireRole(...)`; `disciplinesRoutes` passa para depois do `requireAuth` com `requireRole('EDITOR','ADMIN')`.
2. Suíte de matriz: enumerar rotas de `apiRoutes.stack`, iterar, asserção 401/403 por rota; caso da rota fictícia sem declaração (403 com sessão de EDITOR); snapshot da allowlist; assert global de criação de `User`.

## Critérios de pronto

- [ ] Testes cobrem AC-002-014 (rota sem declaração de papel nasce negada — falha fechada) — verificação executável: `npm --prefix mnemonicos-backend test -- route-authz-matrix` → o teste monta uma rota fictícia em `apiRoutes` depois de `requireAuth` **sem** `requireRole`, atinge-a **com sessão de EDITOR** e afirma **403** (asserção em `res.status`, não em texto); a mutação que remove a checagem de `ROUTE_ROLES` em `authenticate.ts` (deixa o não-declarado passar) deixa o teste vermelho; remover a declaração de `/disciplines` de `ROUTE_ROLES` também. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-010 (matriz de conformidade — 401/403 por rota não-pública) — verificação executável: `npm --prefix mnemonicos-backend test -- route-authz-matrix` → a lista de rotas é **derivada de `apiRoutes.stack`** (Express 5 — `app._router` foi removido), não hard-coded; o guard `expect(rotasNaoPublicas.length).toBeGreaterThan(0)` continua obrigatório para não passar sobre lista vazia; cada rota ∉ `PUBLIC_PATH_ALLOWLIST` → 401 sem cookie, cada rota sob `requireRole('ADMIN')` → 403 com sessão de EDITOR. `Tests: <N rotas não-públicas> passed`, N ≥ nº de rotas não-públicas montadas. Fixada antes do código.
- [ ] `PUBLIC_PATH_ALLOWLIST` == exatamente os 4 caminhos previstos — verificação executável: `npm --prefix mnemonicos-backend test -- route-authz-matrix` → `expect([...PUBLIC_PATH_ALLOWLIST].sort()).toEqual(['/auth/login','/auth/refresh','/health','/health/db'])`. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Nenhuma rota cria `User` fora de `requireRole('ADMIN')` (AC-002-018) — verificação executável: `npm --prefix mnemonicos-backend test -- route-authz-matrix` → itera as rotas `POST` montadas em `apiRoutes.stack` e, para as que o handler chama `prisma.user.create` (ou o service de criação de conta), afirma que o caminho está em `ROUTE_ROLES` com `['ADMIN']`; `expect(rotasPost.length).toBeGreaterThan(0)`. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] `/disciplines` passa a exigir sessão (A-002-019) — verificação executável: `npm --prefix mnemonicos-backend test -- route-authz-matrix` → `GET /disciplines` sem cookie → 401; com sessão de EDITOR → não-401. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] A suíte é a fonte de medição da métrica §1.3 — verificação executável: `npm --prefix mnemonicos-backend test -- route-authz-matrix` verde no CI; dono (time de engenharia) e natureza (conformidade, não instrumentação de evento) a registrar no INDEX do slug. Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md`, §6.3 — ordem de middleware semântica; README do repo vence em conflito).
- [ ] Code review aprovado.

## Riscos específicos

- DEC-003-005: esta é a barreira — `app.use(auth)` **depois** de `app.use(API_PREFIX, apiRoutes)` não protegeria nada (§6.3). A allowlist precisa ficar curta e revisada; expor rota pública nova é ato deliberado (entrada em `PUBLIC_PATH_ALLOWLIST`); rota autenticada nova exige declaração em `ROUTE_ROLES` via `requireRole`.
- A suíte lê a pilha interna do router (`apiRoutes.stack` — Express 5 removeu `app._router`) — API não pública do Express; se a versão mudar a forma da pilha, a derivação da lista precisa acompanhar.
- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-backend/src/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-21
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
