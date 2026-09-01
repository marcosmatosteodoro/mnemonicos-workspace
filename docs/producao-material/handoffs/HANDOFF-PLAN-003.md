---
id: HANDOFF-PLAN-003
slug: producao-material
branch: feat/producao-material-mnemora-studio (mergeada em main — backend 25cdafd · frontend 834f117)
status: Concluído
criado: 2026-08-31T14:40:00-03:00
concluido: 2026-09-01 (Playwright, app local contra o código mergeado — V1–V5 OK · V6 n/a coberto por teste montado)
verificado_parcial: 2026-09-01 (1ª passagem — V1–V4 OK · V5 FALHOU → corrigido em BRIEF-004, mergeado · V6 não exercitável na tela)
origem: PLAN-003
commits: [9aabaf1, 3946b60, 0c54b96, f6cc4ed, e6d0c75]
motivo: credencial (resolvido em 2026-09-01 — ADMIN admin@mnemonicos.local semeado no DB de dev; apps subidos em :3000/:3333)
sonda: >-
  Realm `app` (mnemonicos-frontend) — `scripts/probe-env.sh` exit 1;
  `keelson.local.json` › `screenVerify.realms.app` com `loginPath` (linha 8),
  `username` (linha 9) e `password` (linha 10) todos `null`. Sem credencial não há
  como submeter o formulário de login real, obter o cookie `mnemo_access` nem montar
  o EDITOR de teste. Apps também não estavam de pé no ambiente do ciclo. Saída que
  resolve: `/keelson:init` (realm `app`) ou preencher `loginPath`/`username`/`password`
  no `keelson.local.json` — nunca chutar credencial.
achado_v5_resolvido: >-
  CORRIGIDO e MERGEADO — branch `fix/producao-material-logout-success-race` (BRIEF-004,
  commits 9f2225c·8f91d3b·635314c) mergeada em `main` via PR #2 (`f60659c`). Flag de
  módulo `justLoggedOut`: no logout de sucesso o `baseQueryWithReauth` devolve o 401
  seguinte sem `refresh` nem redirect de "sessão expirada", com os 3 oráculos da §6.3
  (ativação/supressão/expiração). Gates 1–9 APROVADO/CONVERGE. V5 reexercitado no browser
  contra o código mergeado (2026-09-01): "Sair" → `/login` exato, 0 `refresh`, sessão
  revogada. Handoff FECHADO.
achado_bloqueante_historico: >-
  V5 (logout de sucesso) — DIVERGIA de AC-002-027/FR-002-023 (ver `achado_v5_resolvido`).
  Clicar "Sair" numa sessão
  válida encerra a sessão no servidor (correto: `POST /auth/logout` → 204, `me` seguinte
  → 401) mas: (a) o usuário cai em `/login?sessao=expirada` com a mensagem "Sua sessão
  expirou. Entre novamente." — mensagem de EXPIRAÇÃO num logout DELIBERADO; (b) dispara
  uma tempestade de ~90 pares `GET /auth/me` 401 → `POST /auth/refresh` 401 antes de
  assentar. Causa: `LogoutControl` faz `router.push('/login')` após o sucesso, mas o
  `logout.onQueryStarted` dispara `resetApiState()`, o `useMeQuery` ainda montado no
  `InternalShell` durante a navegação re-busca `me` → 401 → `baseQueryWithReauth` tenta
  `refresh` → 401 → ramo `!renewed` → `redirect('/login?sessao=expirada')` +
  `resetApiState()` → laço. É o "logout success race" listado como não-bloqueante na
  Wave 7 (adiado, não corrigido); ao vivo é pior que cosmético. Fix sugerido: na
  navegação de logout de sucesso, desmontar/pausar o `useMeQuery` antes do
  `resetApiState()`, ou marcar "logout deliberado" para o `baseQueryWithReauth` não
  tratar o 401 imediatamente seguinte como sessão expirada. → developer + re-gate,
  fast-follow em `main`.
---

# Handoff de verificação de tela — Acesso interno e papéis de produção (F1)

## 1. Contexto da entrega

PLAN-003 entrega F1 do épico MNEMORA STUDIO: autenticação de sessão da equipe interna
(SPEC-002/FEAT-002-001), autorização por papel deny-by-default no servidor
(FEAT-002-002) e provisionamento de contas por ADMIN (FEAT-002-003). Este handoff cobre
as partes **de tela** de FEAT-002-001 e FEAT-002-002 que o `qa` não pôde exercitar sem
credencial: a tela de login (`/login`, TASK-003-014) e o shell da área interna
(`(interno)/` + logout, TASK-003-015). Backend: `mnemonicos-backend` (Express 5 · Prisma 7
· Postgres). Frontend: `mnemonicos-frontend` (Next 16.3.2 · RTK Query).

## 2. Já verificado (não repetir)

- **Testes** (`quality.test`): backend unit 165/165 (15 suítes) · backend integração
  133/133 (6 suítes, Postgres real) · frontend jest 86/86 (11 suítes). Lint e typecheck
  (`quality.lint` / `quality.typecheck`) limpos nos dois repos. `quality.build` verde nos
  dois (`ƒ Proxy (Middleware)` presente no build do frontend).
- **AC-002-028** (renovação silenciosa do cliente + mensagem de sessão expirada na tela
  de login) — APROVADO com execução real pelo `qa`.
- **AC-002-010/011/012/014** (deny-by-default no servidor) — APROVADOS sobre `createApp()`
  + Postgres real: suíte `route-authz-matrix` 28/28 (censo de 12 rotas; não-pública → 401
  sem payload; `{ADMIN}` → 403 EDITOR / 200 ADMIN; rota sem declaração → 403;
  `assertDenyByDefault` recusa topologia adversarial no boot).
- **AC-002-016..024** (provisionamento por ADMIN, FEAT-002-003) — APROVADOS na Wave 5
  (gate 9 registrado na SPEC).
- **Gate 1 das telas** (Testing Library, sem browser): três estados do `LoginForm`
  (pendente/sucesso-navega/falha-genérica-sem-campo); 4 ramos do `InternalShell`
  (carregando neutro / children / redirect sem sessão / "sem permissão" com papel
  insuficiente — mutante `EDITOR: ['STUDENT','EDITOR','ADMIN']` morto); três estados do
  controle de logout, incluindo a falha transitória (oráculo montado contra a `api` real:
  `logout` 500 → mensagem "Não foi possível sair agora. Tente novamente." permanece,
  sem navegação, cache preservado).
- **API exercitada sem tela**: login/rotação/reuso→revogação da família/expiração 7d/
  logout/freio de login por chave composta (FR-002-001..008) sobre a app montada.

## 3. Pré-requisitos de ambiente

- **Subir o backend**: em `mnemonicos-backend/` — `npm run db:up` (Docker Postgres, porta
  5432), `npm run db:deploy` (migrações), `npm run db:seed` (cria 1 ADMIN a partir de
  `SEED_ADMIN_EMAIL` / `SEED_ADMIN_PASSWORD` do `.env`), `npm run dev` (API em
  `http://localhost:3333/api/v1`). Ou `npm run db:setup` para os três primeiros.
- **Subir o frontend**: em `mnemonicos-frontend/` — `npm run dev` (Next em
  `http://localhost:3000`). Confirmar `NEXT_PUBLIC_API_BASE_URL` apontando para o backend.
- **Migrações/seeds pendentes DESTA branch**: a migração `add_session_and_user_disabled`
  (TASK-003-002) já está versionada; `npm run db:deploy` a aplica. Nenhuma outra.
- **Credenciais de tela**: preencher `keelson.local.json` › `screenVerify.realms.app`
  (`loginPath: "/login"`, `username`, `password`) OU rodar `/keelson:init` para o realm
  `app`. **Não chutar.**
- **Dados de teste**: o EDITOR de teste **cria-se** (não existe no seed). Autenticar como
  o ADMIN semeado (`POST /api/v1/auth/login`) e:
  `POST http://localhost:3333/api/v1/users` com
  `{ "email": "editor.gate@mnemonicos.local", "name": "Editor Gate", "role": "EDITOR", "password": "<12+ chars>" }`.
- **Restaurar ao fim**: `DELETE FROM sessions WHERE "userId" IN (<id EDITOR de teste>, <id ADMIN de teste>);`
  e `DELETE FROM users WHERE email = 'editor.gate@mnemonicos.local';` no Postgres local —
  **nunca** todas as sessões do realm dev compartilhado.
- **Atenção — clone obsoleto**: existe um clone antigo em `.../mnemonicos/mnemonicos-frontend`
  (sem `mnemonicos-workspace/` no caminho), branch `main` @ `214586e`, **sem esta wave**.
  Trabalhe sempre no caminho dentro do workspace (`.../mnemonicos-workspace/mnemonicos-frontend`,
  symlink) na branch `feat/producao-material-mnemora-studio`.

## 4. Roteiro de verificação (itens pendentes)

### V1 — Trânsito real à área interna no sucesso do login (AC-002-009 / FR-002-009)
- **Tela/rota**: `http://localhost:3000/login`
- **Realm**: `app`
- **Passos**:
  1. Abrir `/login` (aba anônima, sem cookie `mnemo_access`).
  2. Submeter e-mail + senha **corretos** do EDITOR de teste.
  3. Observar o estado *em andamento*: o botão "Entrar" desabilita e um indicador de
     progresso (`role="status"`, texto pt-BR "Entrando…") aparece enquanto a requisição
     está pendente.
  4. Aguardar o desfecho.
- **Esperado**: em sucesso, a navegação leva a `/studio` (aterrissagem da área interna),
  o shell interno renderiza (cabeçalho com o controle "Sair" + conteúdo), e o cookie
  `mnemo_access` está presente. Nenhuma mensagem de erro.
- **Risco se falhar**: o caminho feliz do login não entrega o usuário na área interna —
  a feature central de F1 fica sem porta de entrada pela UI.
- **Evidência**: ✅ **OK** (2026-09-01, Playwright, ADMIN `admin@mnemonicos.local`). `/login`
  renderiza form (E-mail/Senha/"Entrar"); submeter credenciais corretas → navega para
  `http://localhost:3000/studio`, título "Studio · Mnemônicos", shell renderiza (botão
  "Sair" + heading "Área interna · Studio" + placeholder "A produção de material chega
  numa próxima fatia."). Nenhuma mensagem de erro. Cookie `mnemo_access` httpOnly (não
  visível a JS — correto). O estado *em andamento* ("Entrando…") é sub-frame com esta
  latência local, não capturado no snapshot — coberto por teste de unidade (gate 1).

### V2 — Mensagem genérica de falha, sem apontar campo (AC-002-009 / FR-002-009)
- **Tela/rota**: `http://localhost:3000/login`
- **Realm**: `app`
- **Passos**:
  1. Em `/login`, submeter o e-mail do EDITOR com **senha errada**.
  2. Repetir com um e-mail **inexistente** e qualquer senha.
- **Esperado**: nos dois casos, a **mesma** mensagem genérica em pt-BR
  ("E-mail ou senha inválidos."), num `role="alert"`, **sem** complemento apontando
  "e-mail" ou "senha" como a causa; nenhum campo com `aria-invalid`; o formulário volta a
  aceitar entrada (inputs e botão habilitados). Não há navegação.
- **Risco se falhar**: enumeração de contas pela UI (distinguir "e-mail não existe" de
  "senha errada") — vazamento de quais e-mails são internos.
- **Evidência**: ✅ **OK** (2026-09-01, Playwright). Senha errada (`admin@mnemonicos.local`
  + `senha-errada-999`) → permanece em `/login`, `role="alert"` = exatamente
  "E-mail ou senha inválidos.", inputs mantêm valor e ficam editáveis, sem `aria-invalid`.
  E-mail inexistente (`ninguem-existe@nada.local`) → **mesma** string exata, mesmo
  comportamento. Não distingue os dois casos.

### V3 — Guard de navegação: rota interna sem sessão redireciona (AC-002-013 / FR-002-013)
- **Tela/rota**: `http://localhost:3000/studio`
- **Realm**: `app`
- **Passos**:
  1. Em aba anônima (sem cookie `mnemo_access`), navegar direto para `/studio`.
  2. Repetir para uma sub-rota, ex.: `/studio/qualquer-coisa`.
- **Esperado**: redireciona para `/login`, carregando o caminho pedido em `?next=`
  (relativo, percent-encoded). A home pública `/` **não** é guardada (navegar para `/`
  sem cookie → 200, sem redirect).
- **Risco se falhar**: ou a área interna fica acessível sem sessão (o guard não roda), ou
  o matcher guarda demais e a home pública redireciona para login (inverte o default do
  site).
- **Evidência**: ✅ **OK** (2026-09-01, Playwright, sem sessão). `/studio` →
  `/login?next=%2Fstudio`. `/studio/qualquer-sub-rota` → `/login?next=%2Fstudio%2Fqualquer-sub-rota`
  (relativo, percent-encoded). `/` → permanece em `/` (200, home renderiza — **não**
  guardada).

### V4 — Estados de navegação protegida com sessão válida (AC-002-013 / FR-002-013)
- **Tela/rota**: `http://localhost:3000/studio`
- **Realm**: `app`
- **Passos**:
  1. Logado como EDITOR (via V1), navegar para `/studio`.
  2. Observar a resolução da sessão (`GET /auth/me`).
- **Esperado**: durante a resolução de `me`, um estado de carregamento **neutro**
  (`role="status"`, texto pt-BR "Carregando…") aparece — **sem** piscar conteúdo
  protegido; com sessão válida e papel suficiente (EDITOR alcança a área interna), a vista
  renderiza. Não há redirect.
- **Risco se falhar**: flash de conteúdo protegido antes da checagem, ou a vista não
  renderiza para um papel legítimo.
- **Evidência**: ✅ **OK** (2026-09-01, Playwright, ADMIN — satisfaz o mínimo EDITOR).
  Logado, navegar a `/studio` → vista renderiza limpa, sem mensagem de erro nem de
  "sem permissão", sem redirect. O flash do estado "Carregando…" é sub-frame nesta
  latência local; o ramo de loading do `InternalShell` (não renderiza `children` até `me`
  resolver) é coberto por teste de unidade. Ramo "papel insuficiente" = `n/a` (F1 não tem
  tela ADMIN-only).

### V5 — Logout de sucesso: ida-e-volta UI → servidor (AC-002-027 / FR-002-023)
- **Tela/rota**: área interna (`/studio`), logado como EDITOR.
- **Realm**: `app`
- **Passos**:
  1. Acionar o controle "Sair".
  2. Observar o estado *em andamento* (botão desabilitado, `aria-busy`, indicador
     "Saindo…").
  3. Após o desfecho, no Postgres: `SELECT "revokedAt" FROM sessions WHERE "userId" = <id do EDITOR de teste>;`
  4. Reapresentar o cookie `mnemo_access` anterior a uma rota protegida (ex.:
     `GET /api/v1/auth/me` com o cookie salvo antes do logout).
- **Esperado**: em sucesso, o usuário volta a `/login`; `revokedAt` preenchido para a
  família da sessão; a reapresentação do cookie anterior → **401** (sessão revogada de
  verdade no servidor, não só no cliente). O cache do cliente é zerado (uma navegação
  seguinte à área interna redireciona para `/login`).
- **Risco se falhar**: logout "cosmético" — a sessão continua válida no servidor e o
  cookie roubado continua servindo.
- **Evidência**: ✅ **OK** (2026-09-01, Playwright, contra o código mergeado — `f60659c`, fix
  do BRIEF-004). Login como ADMIN → `/studio` → clicar "Sair" → URL final =
  `http://localhost:3000/login` **exata** (`sessao=expirada` ausente), **nenhuma**
  mensagem "Sua sessão expirou." na tela, `POST /auth/refresh` chamado **0×**
  (`/auth/logout` 1× · `/auth/me` 2×), `GET /auth/me` com o cookie anterior → **401**
  (sessão revogada no servidor). O bug da 1ª passagem (`/login?sessao=expirada` + laço de
  ~90 `me`/`refresh` 401) está corrigido pela flag `justLoggedOut`.
  _1ª passagem (2026-09-01, pré-fix): ❌ FALHOU — logout de sucesso caía em
  `/login?sessao=expirada` com "Sua sessão expirou." + tempestade de `me`/`refresh` 401.
  Corrigido em BRIEF-004 (`fix/producao-material-logout-success-race`, mergeado)._

### V6 — Logout com falha transitória: permanece na área interna (AC-002-027 / FR-002-023)
- **Tela/rota**: área interna (`/studio`), logado como EDITOR.
- **Realm**: `app`
- **Passos**:
  1. Forçar uma falha transitória de `POST /auth/logout` (parar o backend, ou um proxy
     que responda 500 nessa rota) **mantendo a sessão válida**.
  2. Acionar "Sair".
- **Esperado**: uma mensagem genérica em pt-BR ("Não foi possível sair agora. Tente
  novamente.", `role="alert"`) aparece **e permanece**; o usuário **permanece** na área
  interna (sem redirect para `/login`); o conteúdo protegido continua no DOM; um novo
  clique em "Sair" volta a tentar. (Regressão coberta por teste montado, mas confirmar na
  tela real que a mensagem não some por remontagem.)
- **Risco se falhar**: falha de logout expulsa o usuário sem feedback, ou o feedback
  aparece e some antes de ser lido.
- **Evidência**: **n/a — coberto por teste montado** (decisão do Diretor, 2026-09-01).
  Exige 500 seletivo só em `POST /auth/logout` mantendo `me` OK; sem proxy/mock entre
  :3000 e :3333 no ambiente, não exercitável na tela. Coberto por
  `mnemonicos-frontend/src/components/internal-shell.integration.test.tsx` — oráculo
  montado contra a `api` real: `logout` 500 → mensagem "Não foi possível sair agora.
  Tente novamente." **permanece** no DOM (não some por remontagem), **sem** navegação,
  `me` preservado na store; controle positivo (`logout` 204 → `/login`) ao lado. Mutante
  `resetApiState()` no `finally` → a mensagem some → vermelho.

> **Ramo "papel insuficiente → sem permissão"** de AC-002-013: `n/a` no gate 9 — F1 não
> embarca nenhuma tela ADMIN-only, então não há superfície ponta-a-ponta. Coberto no
> gate 1 (Testing Library: `useMeQuery` devolvendo EDITOR numa vista-stub que exige ADMIN
> → "Você não tem permissão para ver esta página." sem `children`). Não exercitar aqui.

## 5. Riscos e pontos de atenção

- **Gate de hidratação da tela de login**: o botão "Entrar" fica `disabled` até o React
  hidratar (`useSyncExternalStore`). Com JS desabilitado ele **permanece** desabilitado
  (fail-secure — não vaza credencial, mas o form fica inoperante). Confirmar que num
  browser normal a hidratação libera o botão rapidamente e não há "flash" de botão
  travado perceptível.
- **`<form method="post">`**: um submit nativo antes da hidratação deve ir por POST para
  `/login` (a própria rota), nunca GET com `email`/`password` na query string. Checar a
  aba Network num submit rápido.
- **Timing do redirect do guard**: o `InternalShell` dispara `router.replace('/login')`
  num `useEffect`; confirmar que não há flash do shell antes do redirect quando não há
  sessão.
- **`?next=` do proxy**: só caminhos relativos são anexados; `//host`, `/\host`,
  `https://…`, `javascript://…` devem ser descartados (sem `next=` no redirect). Vale
  testar `/studio/%2F%2Fevil.com` e `/studio?next=https://evil.com`.
- **Tema claro/escuro e estado de erro**: a `role="alert"` da falha de login/logout usa
  `text-red-500` — conferir contraste nos dois temas.
- **Cache por aba (RTK Query)**: após logout de sucesso, abrir a área interna noutra aba
  do mesmo browser deve exigir login (cache é por aba/store).

## 6. Protocolo de conclusão

1. Exercitar cada item V1–V6 e preencher a **Evidência** (✅/❌ + o que foi observado).
2. Divergência → corrigir na própria branch `feat/producao-material-mnemora-studio`
   (protocolo inline: escopo restrito + testes + gates) e re-exercitar o item.
3. Tudo ✅ → `status: Concluído` no front-matter; atualizar `docs/producao-material/INDEX.md`
   (remover o risco ativo "Verificação de tela pendente — HANDOFF-PLAN-003" + linha no
   Histórico recente); commit `chore(producao-material): close verification handoff HANDOFF-PLAN-003`;
   push.
4. Merge e deploy continuam decisão humana (do Diretor).
