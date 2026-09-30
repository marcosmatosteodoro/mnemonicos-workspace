# PLAN-041: Home com sessão reconhecida abre a área interna

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.3
**Autor**: scribe (redação delegada pelo Tech Lead; triagem técnica DEC-041-001..005 do Tech Lead)
**Data**: 2026-09-30

## Aderência a guidelines

**Decisões irreversíveis do slug tocadas**: nenhuma. O INDEX do slug tem uma única decisão irreversível (DEC-029-003, snapshot de `ContentVersion`), sem relação com esta entrega. A DEC-003-011 / COMP-003-022 (guarda só onde a sessão é pressuposta; `/` fora do matcher do `proxy.ts`) é reversível e é **preservada literalmente** (DEC-041-001, DEC-041-006): o RISK-040-002 da SPEC se resolve por preservação, não por reabertura.
**Decisões irreversíveis de outros slugs em conflito**: nenhuma — sem outros slugs (`docs/` tem só `producao-material`).
**Exceções aos guidelines**: nenhuma. O trabalho segue `guidelines/project/frontend/` (precedência sobre o perfil `next-16.md`): estado do servidor em RTK Query, `'use client'` só onde há estado/efeito, script inline no molde de `src/lib/theme-bootstrap.ts`, sem mudança de backend.

## Cobertura

**SPEC referenciada**: SPEC-040
**Slice declarado**: cobertura total (Caso D — todos os FRs e NFRs da SPEC-040, 100%)

**FRs cobertos**:
- FR-040-001
- FR-040-002
- FR-040-003
- FR-040-004
- FR-040-005
- FR-040-006
- FR-040-007
- FR-040-008
- FR-040-009
- FR-040-010
- FR-040-011
- FR-040-012
- FR-040-013
- FR-040-014
- FR-040-015
- FR-040-016
- FR-040-017

**NFRs cobertos**:
- NFR-040-001
- NFR-040-002
- NFR-040-003
- NFR-040-004
- NFR-040-005
- NFR-040-006

## 1. Visão técnica

A decisão "sessão reconhecida → área interna" é tomada **no navegador, na própria página inicial** (`/`), por um componente cliente (`HomeSessionGate`), com o `proxy.ts` **intocado** e `/` continuando estática no servidor (DEC-041-001). O cookie de renovação só trafega em `/api/v1/auth/*` (path restrito), então nem o proxy nem um Server Component enxergam "sessão renovável"; só o navegador, chamando o backend, consegue reconhecer quem entrou há dias (AC-040-003).

Quatro peças cooperam:

1. **Pista local de sessão** (`session-hint`, DEC-041-002): marca não-sensível em `localStorage` ("houve sessão neste navegador"). Decide **apenas se há conferência**; nunca decide acesso. Sem pista → nenhuma chamada ao backend e Home pública imediata — é o que mantém o anônimo sem estado neutro, sem 401 em `/auth/refresh` e sem ruído no log de segurança (NFR-040-003, AC-040-013) sem tocar o backend.
2. **Estado neutro sem flash** (DEC-041-003): com pista presente, um script inline síncrono, renderizado pela própria página inicial, marca o `<html>` (`data-home-session="checking"`) antes da pintura e agenda o fim do teto de 3 s; CSS aditivo esconde o conteúdo da home e o `AuthControl` enquanto a marca existe. Sem script, a marca nunca existe: Home pública, com título e metadata intactos (FR-014/016).
3. **Conferência** (`homeSessionCheck`, DEC-041-004): endpoint RTK Query com `queryFn` que lê `/auth/me` cru; em 401 renova em silêncio pela função **extraída de `baseQueryWithReauth`** (mesmo `refreshInFlight`, sem `resetApiState` nem `reauth.redirect`) e relê `/auth/me`. Papel é avaliado por `roleSatisfies(INTERNAL_MIN_ROLE)` (fonte única, `internal-routes.ts`). Resultado é um de: `access`, `no-access` (papel insuficiente), `no-session`, `failed`.
4. **Navegação** (DEC-041-005): `router.replace(INTERNAL_HOME)` — também na ida tardia após o teto, só se a pessoa ainda está em `/`; `pageshow` com `persisted` e remontagem disparam nova conferência (FR-013).

Decisão do componente (máquina de estados, detalhada no §4): sem pista → pública; com pista → neutro até `access` (replace), ou até `no-access`/`no-session`/`failed`/teto (pública). Só `no-session` apaga a pista; `access` a (re)grava.

Reúso declarado: o `homeSessionCheck` e a renovação silenciosa extraída são o ponto de reúso para o KAN-178 (navegação/logo por estado de sessão).

## 2. Stack e dependências

Stack vigente, sem reescolha e **sem dependência nova**: Next 16 (App Router), React 19, Redux Toolkit / RTK Query (`src/store/api.ts`), Tailwind 4 (tokens no `@theme` de `globals.css`), Jest + Testing Library + jsdom (`test/jsdom-fetch-env.js`). Tudo no repositório `mnemonicos-frontend`; **nenhuma mudança no backend** (BRIEF-040, Q-040-003 não se ativa: AC-040-013 é satisfeito no cliente).

Reúso (§9 do perfil): `INTERNAL_HOME`, `INTERNAL_MIN_ROLE`, `roleSatisfies` de `src/lib/internal-routes.ts`; `rawBaseQuery` e `refreshInFlight` de `src/store/api.ts`; molde de script inline `src/lib/theme-bootstrap.ts` (+ `theme-bootstrap.test.ts`); molde de teste de store `src/components/auth-control.integration.test.tsx`; molde de teste HTTP real `src/app/not-found.integration.test.ts`.

## 3. Componentes

### COMP-041-001: Renovação silenciosa extraída e endpoint `homeSessionCheck`
**Responsabilidade**: em `src/store/api.ts`, (a) extrair o closure de renovação de `baseQueryWithReauth` (`api.ts:412-425`) para uma função de módulo `silentRefresh(bqApi, extraOptions)` que compartilha o mesmo `refreshInFlight`, sem `resetApiState` nem `reauth.redirect`; `baseQueryWithReauth` passa a chamá-la sem mudar comportamento; (b) novo endpoint `homeSessionCheck` (`queryFn`, `keepUnusedDataFor: 0`, refetch a cada montagem/`initiate` via `forceRefetch: () => true`) que classifica: `/auth/me` cru → 200 com papel que satisfaz `roleSatisfies(INTERNAL_MIN_ROLE)` = `access`; 200 com papel insuficiente ou 403 = `no-access` (não renova); 401 → `silentRefresh` → `/auth/me` de novo (200 com papel → `access`/`no-access`; 401 → `no-session`); renovação 401 = `no-session`; rede/timeout/5xx em qualquer ponto = `failed`; resposta de forma inesperada = `failed` (fail secure). Re-busca `meSilent` (`initiate` com `forceRefetch`) nas condições fechadas da DEC-041-004 (só com entrada prévia `fulfilled`/`rejected`, após qualquer conclusão exceto `failed`) para o cabeçalho não ficar com "Entrar" ou "Sair" velho. Não loga nem devolve token, cookie ou corpo de erro — só o resultado classificado.
**Realiza**: FR-040-004, FR-040-005, FR-040-006, FR-040-007, FR-040-013, NFR-040-001, NFR-040-002, NFR-040-005
**Interface pública**: `useHomeSessionCheckQuery` / `api.endpoints.homeSessionCheck` (resultado `{ status: 'access' | 'no-access' | 'no-session' | 'failed' }`); `silentRefresh` (interno ao módulo, exposto só se o KAN-178 exigir). Refactor de `baseQueryWithReauth` coberto pelos testes existentes verdes antes e depois.
**Dependências**: COMP-041-002

### COMP-041-002: Pista local de sessão
**Responsabilidade**: `src/lib/session-hint.ts` — funções puras de I/O de storage: `hasSessionHint()`, `setSessionHint()`, `clearSessionHint()` sobre a chave `mnemonicos:session-hint` com valor fixo não-sensível (sem identificador, e-mail ou papel); qualquer exceção (storage bloqueado, `SecurityError`, modo privado) = "sem pista", sem propagar. Chamadas de gravação/limpeza: `setSessionHint` em `login` (após sucesso, `onQueryStarted`), em `me` ok (`InternalShell`; cobre sessões anteriores ao deploy) e em `homeSessionCheck` = `access`; `clearSessionHint` em `logout` (após sucesso) e em `homeSessionCheck` = `no-session`. Nenhuma dessas chamadas muda o comportamento observável de login/logout além de gravar/apagar a pista.
**Realiza**: FR-040-010, FR-040-017, NFR-040-003, NFR-040-005
**Interface pública**: `hasSessionHint(): boolean`, `setSessionHint(): void`, `clearSessionHint(): void`, `SESSION_HINT_KEY` (constante exportada para o script de bootstrap e testes). Teste próprio `session-hint.test.ts` (inclui storage que lança).
**Dependências**: nenhuma

### COMP-041-003: Bootstrap do estado neutro
**Responsabilidade**: (a) `src/lib/home-session-bootstrap.ts` — `getHomeSessionBootstrapScript()` devolve o texto do `<script>` inline síncrono (molde de `theme-bootstrap.ts`): com pista em `localStorage` (mesma `SESSION_HINT_KEY`), seta `data-home-session="checking"` no `<html>` e **grava em `window[HOME_SESSION_CEILING_GLOBAL]` o registro do teto `{ id, startedAt }`** (`id` do timer, `startedAt = performance.now()`) e agenda `setTimeout` de 3 s (`HOME_SESSION_CEILING_MS`) que remove o atributo, independente de hidratação; qualquer exceção = sem marca e sem registro; teste próprio (`home-session-bootstrap.test.ts`) executando o texto em jsdom (com/sem pista, storage que lança, remoção aos 3 s); (b) CSS aditivo no **fim** de `globals.css`: enquanto `html[data-home-session="checking"]`, esconde o conteúdo da home (`[data-home-content]`) e o controle de autenticação do cabeçalho (`[data-auth-control]`) — sem alterar regras existentes; (c) mudança mínima no `AuthControl`: atributo estável `data-auth-control` no(s) nó(s) raiz(ens) renderizado(s). O script NÃO vai em `layout.tsx` (colisão com KAN-177).
**Realiza**: FR-040-002, FR-040-014, FR-040-016
**Interface pública**: `getHomeSessionBootstrapScript(): string`, `HOME_SESSION_CEILING_MS`, `HOME_SESSION_ATTR`, `HOME_SESSION_CEILING_GLOBAL` (`'__mnemonicosHomeSessionCeiling'`, nome da propriedade de `window` que guarda o registro do teto `{ id, startedAt }` exposto pelo script; o símbolo é o contrato); seletor CSS `html[data-home-session="checking"]`.
**Dependências**: COMP-041-002

### COMP-041-004: `HomeSessionGate`
**Responsabilidade**: componente cliente (`'use client'`, `src/components/home-session-gate.tsx`) montado em `src/app/page.tsx` (que segue Server Component síncrono, estático e com título/metadata e conteúdo inalterados; o conteúdo recebe `data-home-content`; o `<script>` do COMP-041-003 é renderizado pela página antes do conteúdo). Orquestra: (1) em `useLayoutEffect`, se há pista, garante a marca (cobre navegação client-side até `/` — logo, 404 — em que o script inline não reexecuta) e inicia a conferência; sem pista, não chama nada; (2) consome `homeSessionCheck`: `access` → regrava a pista, cancela o timer de teto (o do componente e o do script, pelo id do registro) e `router.replace(INTERNAL_HOME)` (também após o teto, FR-012, apenas se `window.location.pathname === '/'`) — a marca **permanece** até a desmontagem (cleanup) e nunca é removida antes de o `replace` concluir, para o conteúdo público não reaparecer durante a navegação; `no-access`/`no-session`/`failed` → remove a marca (pública); `no-session` apaga a pista; (3) **teto ÚNICO contado da abertura**: na montagem pós-hidratação o componente consome o registro do script (lê e apaga a propriedade de `window`) — teto já expirado → não re-marca e não reabre o neutro (a conferência segue e a ida tardia vale); teto vigente → re-marca, cancela o timer do script e agenda só o restante; **sem registro** (navegação client-side, em que o script não reexecuta) o teto conta da montagem e nenhum timer velho do script pode remover a marca dessa navegação; a conferência pode concluir depois do teto e então aplicar a ida tardia; (4) `pageshow` com `event.persisted` (bfcache) e remontagem na volta disparam nova conferência; nunca usa resultado de montagem anterior (`keepUnusedDataFor: 0` + refetch); (5) cleanup de timers/listeners na desmontagem; nenhuma conferência em prefetch (nada executa antes da montagem efetiva do componente em `/`). Logo (`site-header.tsx`) e link da 404 (`not-found.tsx`) permanecem apontando para `/`.
**Realiza**: FR-040-001, FR-040-003, FR-040-005, FR-040-006, FR-040-007, FR-040-008, FR-040-009, FR-040-011, FR-040-012, FR-040-013, FR-040-017, NFR-040-004, NFR-040-006
**Interface pública**: `<HomeSessionGate />` (sem props). Teste de integração `home-session-gate.integration.test.tsx` no molde de `auth-control.integration.test.tsx` (store real via `makeStore()`, `fetch` espionado por pathname, `next/navigation` mockado, timers falsos para o teto).
**Dependências**: COMP-041-001, COMP-041-002, COMP-041-003

### COMP-041-005: Prova HTTP real da home pública e da guarda
**Responsabilidade**: `src/app/home.integration.test.ts` (molde `src/app/not-found.integration.test.ts`: `next build` + `next start`, helpers locais, `redirect: 'manual'`): `GET /` sem script e sem cookie devolve 200 com o conteúdo público, título e descrição de antes (AC-040-021/022), sem marca `data-home-session` no HTML servido; `GET` de rota interna sem cookie segue 307 a `/login?next=…` (AC-040-011); `proxy` segue sem casar `/` — `src/proxy.test.ts` (`matches('/')` falso, matcher derivado dos prefixos, extrator AST, "home pública não é guardada") roda **sem edição** e verde, e `proxy.ts` tem diff vazio; manifesto mantém `start_url` em `/` (AC-040-023).
**Realiza**: FR-040-014, FR-040-015, FR-040-016, NFR-040-002
**Interface pública**: nenhuma (suíte de teste).
**Dependências**: COMP-041-004

## 4. Fluxos principais

**F1 — Anônimo que nunca entrou** (AC-040-004/013/021): abre `/` → HTML estático → script inline não acha pista → sem marca → Home pública imediata; `HomeSessionGate` monta, não acha pista, não chama o backend. Zero chamadas a `/auth/me` e `/auth/refresh` originadas da home.

**F2 — Sessão aceita agora** (AC-040-002): pista presente → script marca `checking` antes da pintura → gate confere: `/auth/me` 200 com EDITOR/ADMIN → `access` → cancela os timers de teto e `router.replace('/studio')`; a marca **permanece** até o componente desmontar (nunca sai antes de o `replace` concluir). A home pública nunca foi visível.

**F3 — Sessão renovável** (AC-040-003/012): `/auth/me` 401 → `silentRefresh` (serializada em `refreshInFlight` com qualquer renovação da aba) → `/auth/me` 200 → `access` → ida. Renovação 401 → `no-session` → apaga pista → pública, sem login nem aviso.

**F4 — Papel sem acesso** (AC-040-008): `/auth/me` 200 com STUDENT → `no-access` → pública; nada de renovação extra nem tela de recusa; a pista permanece (há sessão).

**F5 — Falha / teto** (AC-040-007/015/016): rede ou 5xx → `failed` → pública. Conferência pendurada → **teto único contado da abertura** (script e componente compartilham um só relógio, sem reabrir o neutro na hidratação): aos 3 s da abertura a marca cai e a home pública aparece; se a conferência concluir `access` depois e a pessoa ainda estiver em `/`, `router.replace` (ida tardia).

**F6 — Voltar / bfcache / logo** (AC-040-009/017/018/019): `replace` tira `/` do histórico, então "voltar" da área interna não retorna a `/`; ao voltar a `/` por histórico ou bfcache (`pageshow` persisted), nova conferência decide de novo. Logout na aba B → logo na aba A → `/auth/me` 401 → renovação 401 → `no-session` → pública, sem `/login?sessao=expirada` (o caminho usa `rawBaseQuery`, não `baseQueryWithReauth`).

**F7 — Login e logout** (AC-040-024): login grava a pista após sucesso e segue para `next ?? INTERNAL_HOME` como hoje; logout apaga a pista após sucesso e vai a `/login` como hoje.

## 5. Modelo de dados

Sem mudança de banco, API ou migração. Único estado novo persistente é a **pista local** em `localStorage` do navegador: chave `mnemonicos:session-hint`, valor literal fixo não-sensível (não identifica pessoa, papel nem sessão), escopo por origem, sem expiração própria (a conferência a apaga ao concluir "sem sessão"). Estado novo em memória: resultado de `homeSessionCheck` no cache RTK Query da aba (`keepUnusedDataFor: 0`) e a marca `data-home-session` no `<html>`.

## 6. Decisões arquiteturais

### Decisões herdadas
- **DEC-041-006** [herdada] `proxy.ts` e a guarda das rotas internas permanecem inalterados; `/` segue fora do matcher — fonte: INDEX do slug DEC-003-011 / COMP-003-022 (PLAN-003) e SPEC-002; SPEC-040 FR-040-015
- **DEC-041-007** [herdada] `INTERNAL_HOME`, `INTERNAL_MIN_ROLE` e `roleSatisfies` de `src/lib/internal-routes.ts` são a fonte única de destino e de papel com acesso — fonte: perfil §9 (reúso) e SPEC-040 A-040-003/A-040-009
- **DEC-041-008** [herdada] Os dois leitores de sessão coexistem (`me` com reauth e `meSilent` sem efeito colateral); `homeSessionCheck` é o terceiro, sem efeito colateral de expulsão — fonte: INDEX DEC-035-005 (PLAN-035)
- **DEC-041-009** [herdada] Teto da conferência de 3 s e meta de 1 s em ambiente local — fonte: SPEC-040 A-040-010 / A-040-005 (NFR-040-004, FR-040-011)
- **DEC-041-010** [herdada] `'use client'` só onde há estado/efeito; `makeStore()` é função, nunca singleton; estado do servidor é RTK Query — fonte: perfil §6.3/§6.5 e CLAUDE.md do workspace
- **DEC-041-011** [herdada] Identificadores de código em inglês, texto de interface em pt-BR — fonte: CLAUDE.md do workspace
- **DEC-041-012** [herdada] Sem mudança de backend (regras, endpoints e cookies de sessão intactos) — fonte: BRIEF-040 / SPEC-040 §4.2

### DEC-041-001: Decidir no navegador, na própria página inicial, com `proxy.ts` intocado
**Contexto**: a SPEC exige reconhecer sessão renovável (AC-040-003), nunca levar anônimo a `/login` (FR-040-005/AC-040-006), não disparar conferência por prefetch do logo (NFR-040-006) e manter a guarda intacta (FR-040-015, RISK-040-002). Fatos medidos: `mnemo_access` tem `path: '/'` e vive ~15 min; `mnemo_refresh` tem `path: '/api/v1/auth'` e vive ~7 dias, portanto não chega a `/`.
**Decisão**: a decisão é tomada por um componente cliente (`HomeSessionGate`) montado na página inicial, que consulta o backend; `proxy.ts` não é tocado e `/` continua estática.
**Alternativas consideradas**:
- Proxy redirecionando `/` por presença do cookie de acesso, descartada porque: não vê o cookie de renovação, então quem entrou há mais de 15 min cai em anônimo (falha AC-040-003); cookie presente porém inválido levaria a `/studio` e daí a `/login` (viola FR-040-005/AC-040-006); o prefetch do logo passaria pelo proxy (viola NFR-040-006); quebra `proxy.test.ts:252-263` e `:286-292` e reabre DEC-003-011/COMP-003-022.
- Página dinâmica no servidor (`cookies()` + fetch ao backend), descartada porque: o cookie de renovação também não chega em `/`; renovar no servidor exige repassar o `Set-Cookie` rotacionado à resposta; e tira `/` do estático, impondo cold start a toda visita anônima.
- A mais simples — apenas ler `useMeSilentQuery` no cliente, descartada porque: `meSilent` nunca renova, então quem tem só o cookie de renovação é tratado como anônimo (falha AC-040-003).
**Consequências**: COMP-003-022/DEC-003-011 preservados literalmente (RISK-040-002 resolvido por preservação). A decisão depende de JavaScript e do backend acessível; sem script ou com falha → Home pública (FR-040-014/006). Aparece um estado neutro curto para quem tem pista (DEC-041-003).
**Reabrir se**: o backend passar a expor um sinal de sessão legível em `/` (ex.: cookie de sinal no path `/`), ou o p95 medido da conferência estourar o teto de 3 s.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-041-002: Pista local de sessão decide só se há conferência
**Contexto**: sem sinal de sessão legível em `/`, toda visita anônima pagaria estado neutro e duas chamadas (`me` 401 → `refresh` 401), e cada `POST /auth/refresh` anônimo grava falha no log de eventos de autenticação (A-040-006), violando NFR-040-003/AC-040-013 — com backend fora de escopo.
**Decisão**: chave `mnemonicos:session-hint` em `localStorage`, valor fixo não-sensível. Gravada no login com sucesso, em `me` ok e em `homeSessionCheck` = `access` (cobre sessões anteriores ao deploy que passem pela área interna); apagada no logout com sucesso e quando a conferência conclui `no-session`. **Sem pista → nenhuma conferência, nenhuma chamada ao backend, Home pública imediata, sem estado neutro.** A pista nunca decide acesso nem leva à área interna: só liga a conferência (NFR-040-002). Storage bloqueado ou exceção → sem pista.
**Alternativas consideradas**:
- Sempre conferir (sem pista), descartada porque: todo anônimo paga o estado neutro e duas chamadas com cold start, e cada visita gera falha em `/auth/refresh` no log de segurança — viola NFR-040-003/AC-040-013 sem mudança de backend, que é fora de escopo.
- Cookie não-httpOnly de sinal emitido pelo backend, descartada porque: exige mudança de backend (fora de escopo do BRIEF-040, dispararia Q-040-003 de volta ao PO).
**Consequências**: sessão válida sem pista (anterior ao deploy, storage limpo ou modo privado) vê a Home pública nessa abertura até passar pela área interna, que regrava a pista (TRISK-041-002). A pista é sinal de UX, nunca de autorização; a guarda real segue no servidor.
**Reabrir se**: o backend ganhar sinal próprio de sessão legível em `/`, ou a "sessão sem pista" for observada como problema real.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-041-003: Estado neutro por script inline da própria página, com teto de 3 s
**Contexto**: FR-040-002/003 exigem que a Home pública não apareça para quem será levado à área interna; FR-040-014/016 exigem Home pública íntegra sem script e para robôs; o KAN-177/BRIEF-039, em andamento, altera `layout.tsx`.
**Decisão**: a página inicial renderiza um `<script>` inline síncrono (texto de função pura em `src/lib/home-session-bootstrap.ts`, molde de `theme-bootstrap.ts`) que, com pista, marca o `<html>` com `data-home-session="checking"` e agenda a remoção da marca aos 3 s, independente de hidratação. CSS aditivo no fim de `globals.css` esconde `[data-home-content]` e `[data-auth-control]` enquanto a marca existe. Em navegação client-side até `/` (logo, 404), o componente põe a marca em `useLayoutEffect`, antes da pintura. Sem script, a marca nunca existe.
**Alternativas consideradas**:
- Script no `<head>` do `layout.tsx`, descartada porque: colide com o KAN-177 (mesmo arquivo em mudança) e executaria em toda rota, não só em `/`.
- SSR neutro por padrão (conteúdo escondido no HTML servido), descartada porque: entrega HTML vazio a quem não executa script e a robôs/prévias de link — viola FR-040-014/016 e AC-040-021/022.
- Esconder só após a hidratação, descartada porque: o conteúdo público piscaria antes da decisão — viola FR-040-003/AC-040-002.
**Consequências**: HTML servido permanece o da Home pública (título, descrição, conteúdo). A marca é mutação do `<html>` fora do React (TRISK-041-006). `globals.css` recebe só bloco aditivo no fim.
**Reabrir se**: o KAN-177 mergear e o layout ganhar um ponto de bootstrap comum, ou a marca vazar para outras rotas.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-041-004: Conferência como endpoint RTK Query com renovação silenciosa extraída
**Contexto**: a conferência precisa renovar sem expulsar (anônimo nunca vai a `/login?sessao=expirada`, FR-040-005) e sem criar renovação concorrente fora da serialização (NFR-040-001/RISK-040-001: reuso de refresh fora da graça revoga a família inteira). A renovação hoje é um closure privado em `baseQueryWithReauth` (`api.ts:412-425`).
**Decisão**: endpoint `homeSessionCheck` (`queryFn`) classificando `access | no-access | no-session | failed` (COMP-041-001). Renovação silenciosa = função extraída de `baseQueryWithReauth`, compartilhando o mesmo `refreshInFlight`, sem `resetApiState` nem `reauth.redirect`; `baseQueryWithReauth` passa a chamá-la sem mudar comportamento (refactor com suíte de `api` verde antes e depois). `keepUnusedDataFor: 0` e refetch a cada montagem (FR-040-013). **Classificação fechada** (nenhum status tem destino implícito): `/auth/me` 2xx com papel suficiente = `access`; 2xx com papel insuficiente ou 403 = `no-access`; 401 → renovação; qualquer outro status ou falha de rede = `failed`. `/auth/refresh`: 2xx → novo `/auth/me`; 401 = `no-session`; qualquer outro (403 de `verifyOrigin`, 429, 5xx) ou falha de rede = `failed`. **Re-busca do `meSilent`**: só se ele já tem entrada no cache com status `fulfilled` ou `rejected` (não `uninitialized` nem `pending` — `pending` não gera GET extra, pois o `buildThunks` do RTK 2.x retorna antes do `forceRefetch`), após **qualquer conclusão exceto `failed`** (`access`, `no-access`, `no-session`); renovação seguida de `failed` **não** re-busca. **Sem timeout novo** (decisão declarada): o teto de 3 s do componente encerra o neutro e a conclusão tardia segue FR-040-012.
**Alternativas consideradas**:
- Reusar `me` (com `baseQueryWithReauth`), descartada porque: anônimo com renovação morta seria enviado a `/login?sessao=expirada` e o cache seria resetado — viola FR-040-005.
- `fetch` direto no componente, descartada porque: fura o padrão do projeto (estado do servidor é RTK Query, perfil §6.5) e duplica a renovação fora da serialização de `refreshInFlight`, com risco de revogar a família (RISK-040-001).
**Consequências**: um único ponto de renovação por aba, serializado com qualquer outra; o refactor de `api.ts` exige rodar os testes existentes de reauth antes e depois. Ponto de reúso para o KAN-178. A renovação concorrente **entre abas** (cookie compartilhado, estado de módulo por aba) depende da graça do backend (TRISK-041-005).
**Reabrir se**: surgir outro consumidor do sinal de sessão (KAN-178) que peça forma diferente.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-041-005: Navegação por `replace`, com nova conferência em volta e bfcache
**Contexto**: FR-040-008 proíbe laço no "voltar"; FR-040-013/AC-040-019 exigem conferência atual ao voltar a `/` por histórico.
**Decisão**: `router.replace(INTERNAL_HOME)` na ida (inclusive tardia, FR-040-012, só se a pessoa ainda está em `/`); `pageshow` com `persisted` (bfcache) e a remontagem do componente na navegação de volta disparam nova conferência.
**Alternativas consideradas**:
- `router.push(INTERNAL_HOME)`, descartada porque deixa `/` no histórico: o "voltar" da área interna reabre `/`, que redireciona de novo (laço — viola AC-040-009).
- `<meta http-equiv="refresh">` servido na página, descartada porque é decidido no HTML estático, antes e independente da conferência: redirecionaria também o anônimo (viola FR-040-005) e o visitante sem script (viola FR-040-014).
**Consequências**: o histórico não guarda `/` após a ida; quem volta à home por histórico é reconferido.
**Reabrir se**: o App Router mudar a semântica de restauração de página/bfcache.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

## 8. Riscos técnicos

- **TRISK-041-001** Colisão com o KAN-177/BRIEF-039, que altera `layout.tsx` e `globals.css` na mesma tela (mitigação: não tocar `layout.tsx`; script renderizado pela página; CSS aditivo só no fim de `globals.css`; rebase/merge após o KAN-177 e reexecutar a suíte).
- **TRISK-041-002** Sessão válida sem pista (anterior ao deploy, storage limpo, modo privado) vê a Home pública nessa abertura (DEC-041-002) (mitigação: a pista é regravada ao passar pela área interna; risco declarado ao PO; reabrir a DEC se observado como problema real).
- **TRISK-041-003** Backend indisponível neste ambiente: os ACs de execução real (AC-040-002/003/009/012/016/017/018/019) não fecham aqui (mitigação: handoff de verificação no precedente HANDOFF-PLAN-036; entrega PARCIAL declarada, gate de comportamento verificado pendente).
- **TRISK-041-004** O p95 da conferência em produção com serviço frio (cold start) não é mensurável neste ambiente (A-040-010) (mitigação: item de DoD pós-deploy medido pelo Diretor; p95 > 3 s volta ao PO, o teto não se troca em silêncio).
- **TRISK-041-005** Renovação concorrente entre abas fora da janela de graça revoga a família de sessão (`AUTH_REFRESH_GRACE_SECONDS` do backend; o `refreshInFlight` só serializa dentro da aba) (mitigação: conferir só com pista e só na abertura efetiva de `/`, sem prefetch; nenhuma renovação extra fora dessa abertura; risco residual aceito e registrado, fora do alcance sem mudança de backend).
- **TRISK-041-006** A marca `data-home-session` no `<html>` é posta fora do React e pode gerar aviso/divergência de hidratação, ou vazar para outras rotas na navegação client-side (mitigação: o componente remove a marca na desmontagem e ao concluir não-`access`; no `access` ela permanece até desmontar; teste de integração cobre remoção; o `<html>` de `layout.tsx:33` não tem `suppressHydrationWarning`, mas o precedente DEC-035-001 (`theme-bootstrap.ts`, `data-theme` posto no `<html>` antes da hidratação, em produção desde o PLAN-036) mostra atributo `data-*` pré-hidratação sem quebra — segue-se o precedente sem tocar `layout.tsx`; o gate 9 confere o console sem aviso de hidratação em `/`, e se aparecer a marca migra para um elemento da própria página, com o seletor do cabeçalho reavaliado).

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Aderência à ficha/perfil validada
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates)
- [ ] Refactor de `baseQueryWithReauth` (renovação extraída) com os testes de reauth existentes verdes antes e depois; `proxy.ts` e `proxy.test.ts` com diff vazio
- [ ] Métrica da SPEC operacional (§1.3, fonte de medição externa): suíte de testes de comportamento dos ACs AC-040-001 a AC-040-024 executada e verde nos gates de QA e de comportamento verificado (dono do número: Tech Lead do ciclo); ACs que exigem navegador e serviço de sessão reais (AC-040-002/003/009/012/016/017/018/019) fechados em execução real ou declarados em handoff, com a entrega PARCIAL enquanto pendentes
- [ ] Medição pós-deploy do p95 da conferência completa (`/auth/me` + renovação + `/auth/me`) em produção com serviço frio, pelo Diretor, registrada no INDEX (A-040-010); p95 acima de 3 s volta ao PO

## 10. Não coberto por este PLAN

- Nenhum FR/NFR da SPEC-040 fica de fora (cobertura 100%).
- Fora de escopo herdado da SPEC (§4.2): `/login` e outras páginas públicas com sessão reconhecida (Q-040-001), mensagem ao papel sem acesso (Q-040-002), navegação/logo por estado de sessão (KAN-178), mudanças de regra de sessão e de backend, instrumentação de produto.
