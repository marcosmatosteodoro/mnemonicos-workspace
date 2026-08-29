# TASK-003-013: Store do frontend (`api.ts` com re-auth + `proxy.ts`)

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: FR-002-012
**Funcionalidade**: FEAT-002-002 (primária)
**Componente**: COMP-003-021, COMP-003-022
**Wave**: 6
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 via `next/jest`, `testEnvironment: jsdom`, Testing Library — em `mnemonicos-frontend/`. Gates: `npm --prefix mnemonicos-frontend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: TASK-003-005, TASK-003-009, TASK-003-010
- **Bloqueia**: TASK-003-014, TASK-003-015

## Contexto

COMP-003-021/022, DEC-003-010 (RTK Query com re-autenticação), DEC-003-011 (guard de rota como conveniência). `src/store/api.ts` ganha um `baseQuery` com re-autenticação silenciosa e os endpoints de auth/gestão; `src/proxy.ts` (ex-`middleware.ts` no Next 16) redireciona `/(interno)/*` sem o cookie `mnemo_access` — **conveniência de navegação, não fronteira** (§6.3: a barreira real é o backend — TASKs 003-007/011).

**Consome (aresta)**: `SessionUser` / `USER_ROLES` (TASK-003-005); os endpoints REST de auth (TASK-003-009) e de users (TASK-003-010). O nome do cookie `'mnemo_access'` é usado como literal no frontend (sem import cross-repo), com comentário apontando `mnemonicos-backend/src/http/cookies.ts` como fonte.

**Nomeia (aresta entre irmãs)**: `SESSION_EXPIRED_PARAM` (`= 'sessao'`, valor `expirada`) é exportado de `src/store/api.ts` e importado pela tela de login (TASK-003-014) para exibir a mensagem de sessão expirada — nunca grafia solta.

## Escopo

### Inclui
- O `baseQueryWithReauth` **serializa o refresh**: uma única promessa de `POST /auth/refresh` em voo por vez; requisições que recebem 401 durante um refresh em curso aguardam essa promessa em vez de disparar outro (emenda do gate 7 da Wave 3 — dois refresh concorrentes no servidor geram pontas de família divergentes; o cliente é quem evita a corrida).
- `mnemonicos-frontend/src/store/api.ts` — `baseQueryWithReauth` envolvendo `fetchBaseQuery` (mantém `credentials: 'include'`): em 401 dispara **uma** vez `POST /auth/refresh`; sucesso → repete a requisição original; falha → `dispatch(api.util.resetApiState())` e redireciona para `/login?${SESSION_EXPIRED_PARAM}=expirada` (via `window.location` ou callback injetado). Exporta `export const SESSION_EXPIRED_PARAM = 'sessao'` (valor `expirada`) — símbolo nomeado consumido pela tela de login (TASK-003-014). Endpoints novos: `login` (mutation), `logout` (mutation), `changePassword` (mutation), `me` (query — fonte da sessão corrente), `adminListUsers` (query), `adminCreateUser`, `adminDisableUser`, `adminResetPassword` (mutations). `tagTypes` ganha `'SessionUser'` e `'User'`. Nenhum token tocado — tudo em cookie `httpOnly`.
- `mnemonicos-frontend/src/proxy.ts` — `export function proxy(request)` + `config.matcher` cobrindo o grupo `(interno)`. Sem o cookie `mnemo_access` → `NextResponse.redirect('/login?next=<path relativo validado>')`; o `next` é validado como caminho relativo (guarda de open-redirect — §6.6). Se a minor instalada ainda exigir `middleware.ts`, o nome acompanha o framework e a lógica é idêntica.
- `mnemonicos-frontend/src/store/api.test.ts`, `mnemonicos-frontend/src/proxy.test.ts`.

### Não inclui
- As telas de login e shell (TASKs 003-014, 003-015).
- Decisão de papel no `proxy.ts` (é conveniência, não fronteira — §6.3 / FR-002-012).
- Slice manual guardando o usuário da sessão (proibido — `me` é a fonte; §4/§6.5 do perfil frontend).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `baseQueryWithReauth` — mutex/flag para garantir **uma** tentativa de refresh; no sucesso re-executa `args`; na falha `resetApiState()` + redirect para `/login?${SESSION_EXPIRED_PARAM}=expirada`.
2. Endpoints RTK Query + `tagTypes` `'SessionUser'`/`'User'`; exportar `SESSION_EXPIRED_PARAM`.
3. `proxy.ts` — checar presença do cookie; validar `next` como caminho relativo (`startsWith('/')` e não `//`).
4. Testes com mock de fetch/`msw`.

## Critérios de pronto

- [ ] Testes cobrem AC-002-028 (renovação silenciosa com repetição única; falha → `resetApiState` + `/login`) — verificação executável: `npm --prefix mnemonicos-frontend test -- api` → cenário A: resposta 401 → `POST /auth/refresh` 200 → retry → resultado ok, **exatamente uma** chamada a `/auth/refresh` (contador); cenário B: 401 → refresh 401 → **sem** retry, `api.util.resetApiState()` dispatchado, redirect chamado com `/login` incluindo `?${SESSION_EXPIRED_PARAM}=expirada` — a asserção verifica o parâmetro na URL de destino. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] `proxy.ts` redireciona sem cookie e valida `next` como caminho relativo (item do Inclui — FR-002-012, sem AC de tela aqui) — verificação executável: `npm --prefix mnemonicos-frontend test -- proxy` → sem cookie `mnemo_access` → `NextResponse.redirect` para `/login?next=/algum/caminho`; `next = 'https://evil.tld'` ou `'//evil.tld'` → descartado (redireciona para `/login` sem `next` ou com `next=/`). `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Endpoints e `tagTypes` definidos e exercitados não-nulos (itens do Inclui sem AC) — verificação executável: `npm --prefix mnemonicos-frontend test -- api` dispara cada hook (`login`/`logout`/`changePassword`/`me`/`adminListUsers`/`adminCreateUser`/`adminDisableUser`/`adminResetPassword`) contra um mock não-nulo e verifica a URL/método; `npm --prefix mnemonicos-frontend run typecheck` → exit 0 (baseline 0 no início da TASK); `tagTypes` contém `'SessionUser'` e `'User'`; `SESSION_EXPIRED_PARAM === 'sessao'`. `Tests: ≥8 passed`. Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-frontend run lint` → exit 0 (baseline capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`next-16.md`, §1/§6.3/§6.5/§6.6/§11; README do repo vence em conflito).
- [ ] Code review aprovado.

## Riscos específicos

- DEC-003-011: `proxy.ts` **não** é fronteira — o guard depende só da presença do cookie, não da validade (a validade é o backend que confere). Conferir se Next 16.3.2 está na faixa corrigida do advisory de bypass de middleware (`x-middleware-subrequest`).
- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-frontend/src/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-23
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
