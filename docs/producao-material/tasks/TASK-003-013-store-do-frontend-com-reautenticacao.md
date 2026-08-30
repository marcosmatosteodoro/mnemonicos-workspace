# TASK-003-013: Store do frontend (`api.ts` com re-auth + `proxy.ts`)

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: FR-002-012
**Funcionalidade**: FEAT-002-002 (primária)
**Componente**: COMP-003-021, COMP-003-022
**Wave**: 6
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: In Progress
**Data início**: 2026-08-30T04:33:36-03:00

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

**Retry (Wave 6 — REPROVADO nos gates 8 e 1/4/5 no 1º passe `0ce714a`)**. Correções vinculantes:
- **S1 (gate 8, ALTA)**: `baseQueryWithReauth` trata **qualquer** 401 como sessão expirada — inclusive o 401 de `POST /auth/login` (endpoint **público**; 401 = credencial inválida). Login com senha errada dispara `POST /auth/refresh` silencioso → em navegador compartilhado com `mnemo_refresh` vivo do usuário anterior, **emite cookies de sessão novos para ele**. A re-autenticação só tenta renovar em requisição que **pressupõe sessão estabelecida** — **exclui** os endpoints públicos de sessão (`/auth/login`, `/auth/refresh`, `/auth/logout`). A lista de exclusão é um **símbolo** (`PUBLIC_AUTH_PATHS` ou nome análogo em `api.ts`), com comentário apontando `mnemonicos-backend/src/http/public-paths.ts` como fonte canônica — nunca grafia solta.
- **S2 (gate 8, MEDIA)**: com S1, o ramo de "sessão expirada" (redirect `?sessao=expirada`) deixa de ser alcançável a partir do login; o `?sessao=expirada` fica **exclusivo** de 401 de requisição autenticada.
- **S3 (gate 8, MEDIA)**: `logout` só invalida `SessionUser`/`User` — o resto do cache RTK Query (`Discipline`, `Mnemonic`…) sobrevive na aba e é servido ao próximo usuário (viola §6.3 literal do perfil). `onQueryStarted` em `logout` **e** `login` → `await queryFulfilled; dispatch(api.util.resetApiState())`.
- **CR2 (gates 4+5)**: `config.matcher` é catch-all por **exclusão** — guarda a home pública `/` e toda página pública futura. Passa a **enumerar** os prefixos internos (`['/studio/:path*','/gestao/:path*']` — working set; confirmar contra `mnemonicos-frontend/src/app/(interno)/` e a SPEC §4; estendido por TASK-003-015). Alinha com DEC-003-011 (`/(interno)/*`).
- **CR3 (gate 1)**: o ramo `includes('://')` de `isSafeRelativePath` (`proxy.ts`) é inalcançável pelos fixtures atuais (morrem antes no `startsWith('/')`).

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

- [ ] Testes cobrem AC-002-028 (renovação silenciosa com repetição única; falha → `resetApiState` + `/login`) — verificação executável: `npm --prefix mnemonicos-frontend test -- api` → cenário A: resposta 401 → `POST /auth/refresh` 200 → retry → resultado ok, **exatamente uma** chamada a `/auth/refresh` (contador); cenário B: 401 → refresh 401 → **sem** retry, `api.util.resetApiState()` dispatchado, redirect chamado com `/login` incluindo `?${SESSION_EXPIRED_PARAM}=expirada` — a asserção verifica o parâmetro na URL de destino; **cenário C (serialização)**: 3 requisições recebem 401 concorrentemente → **exatamente 1** `POST /auth/refresh`, as 3 re-executadas depois. Mutante que remove o mutex → contador de `/auth/refresh` vira 3 (vermelho). `Tests: ≥3 passed`. Fixada antes do código.
- [ ] **[retry S1]** 401 de **endpoint público de sessão** não dispara re-autenticação — verificação executável: `npm --prefix mnemonicos-frontend test -- api` → `POST /auth/login` responde **401** → **nenhuma** chamada a `POST /auth/refresh` (contador `=== 0`) e a requisição de login **não** é repetida; o erro 401 é devolvido ao chamador (`.unwrap()` rejeita). Idem para `POST /auth/refresh` e `POST /auth/logout` recebendo 401. Mutante: remover a exclusão dos endpoints públicos da máquina de re-auth → o caso `POST /auth/login` 401 passa a chamar `/auth/refresh` (vermelho). A lista de exclusão é um símbolo (`PUBLIC_AUTH_PATHS` ou análogo), não grafia solta. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] **[retry S2]** feedback de credencial inválida não vira "sessão expirada" — verificação executável: `npm --prefix mnemonicos-frontend test -- api` → `POST /auth/login` 401 → `reauth.redirect` **não** é chamado, `api.util.resetApiState()` **não** é dispatchado; o `?${SESSION_EXPIRED_PARAM}=expirada` só aparece no redirect de 401 de requisição **autenticada** (ex.: `GET /users`). `Tests: ≥1 passed`. Fixada antes do código.
- [ ] **[retry S3]** `logout` e `login` limpam todo o cache do RTK Query — verificação executável: `npm --prefix mnemonicos-frontend test -- api` → após `POST /auth/logout` responder 200, `store.getState().api.queries` está **vazio** (não só as tags `SessionUser`/`User` — qualquer entrada, ex.: `listDisciplines`, some); idem após `login` 200. Mutante que remove o `dispatch(api.util.resetApiState())` do `onQueryStarted` → uma entrada de query semeada antes do logout **sobrevive** (vermelho). `Tests: ≥2 passed`. Fixada antes do código.
- [ ] **[retry CR2]** `proxy.ts` guarda o grupo interno **enumerado**, não o site por exclusão — verificação executável: `npm --prefix mnemonicos-frontend test -- proxy` → `config.matcher` (aplicado com âncoras `^…$` no teste) casa `/studio`, `/studio/x`, `/gestao`, `/gestao/x`; **não** casa `/` (home pública), `/login`, `/_next/static/x`, nem uma rota pública existente qualquer. Sem cookie numa rota **interna** → redirect; requisição a `/` → **segue** (não redireciona). Mutante: trocar o matcher por catch-all de exclusão → o caso `/` **não segue** (é guardado) — vermelho. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] **[retry CR3]** `isSafeRelativePath` — o ramo `://` tem caso próprio — verificação executável: `npm --prefix mnemonicos-frontend test -- proxy` → `next = '/x://y'` (começa com `/` **e** contém `://`) → **descartado**; e os casos `'https://evil.tld'`, `'//evil.tld'`, `'/\\evil'` seguem descartados. Mutante que remove **só** a linha `includes('://')` → o caso `'/x://y'` passa a ser aceito (vermelho). Se o time decidir que o ramo é inalcançável e removê-lo, o critério vira "nenhum caminho com `//` ou barra invertida no início escapa" e o mutante que remove a guarda de `//` fica vermelho. `Tests: ≥1 passed`. Fixada antes do código.
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
