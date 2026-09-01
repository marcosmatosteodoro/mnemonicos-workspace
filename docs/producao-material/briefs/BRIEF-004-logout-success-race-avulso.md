# BRIEF-004: Logout de sucesso não deve mostrar "sessão expirou" nem entrar em laço

**Slug**: producao-material
**Tipo**: avulso
**Status**: Aberto
**Data**: 2026-08-31
**Largada**: 2026-08-31T21:47:21-03:00
**Origem**: Diretor (pedido em sessão — fast-follow do achado V5 da caminhada de tela do HANDOFF-PLAN-003)

## Pedido como dito

> prossiga [com o fast-follow do V5]

Achado V5 (caminhada de tela pós-merge de F1, Playwright, 2026-09-01, reproduzido 2×):
clicar **"Sair"** numa sessão válida encerra a sessão no servidor (correto — `POST /auth/logout`
→ 204, `me` seguinte → 401), mas na UI o usuário cai em **`/login?sessao=expirada`** com a
mensagem **"Sua sessão expirou. Entre novamente."** (mensagem de *expiração* num logout
*deliberado*), precedida de uma tempestade de ~90 pares `GET /auth/me` 401 →
`POST /auth/refresh` 401. É o "logout success race" listado como não-bloqueante na Wave 7.

## Interpretação

**O quê**: no logout **bem-sucedido**, o `LogoutControl` faz `router.push('/login')` e o
`logout.onQueryStarted` dispara `resetApiState()`; o `useMeQuery` ainda montado no
`InternalShell` durante a navegação re-busca `me` → 401 → `baseQueryWithReauth` tenta
`refresh` → 401 → ramo `!renewed` → `redirect('/login?sessao=expirada')` + `resetApiState()`
→ laço. Semanticamente, "eu fiz logout" ≠ "minha sessão expirou": o 401 do `me` logo após
um logout deliberado é **esperado e benigno**, não deve acionar a máquina de re-auth.

**Onde**: `mnemonicos-frontend/src/store/api.ts` (`logout` endpoint + `baseQueryWithReauth`),
possivelmente `src/components/internal-shell.tsx` (`LogoutControl`).

**Por que agora**: bug visível em **todo** logout bem-sucedido (mensagem enganosa + laço de
requisições); é o único item da caminhada de tela V1–V6 que falhou; bloqueia o fecho do
HANDOFF-PLAN-003 e o onboarding real da equipe.

**Design sugerido pelo Tech Lead** (não é escolha que mude promessa — a promessa
AC-002-027/FR-002-023 "logout de sucesso → volta ao `/login`" é fixa; é bug): flag de
módulo `justLoggedOut` no padrão do `refreshInFlight` já existente em `api.ts` — setada em
`logout.onQueryStarted` no **sucesso**, consultada pelo `baseQueryWithReauth`: 401 recebido
enquanto `justLoggedOut` está ativo → devolve o 401 **sem** `refresh` nem
`redirect('/login?sessao=expirada')`; a flag se limpa após um tick / na próxima
navegação. Alternativa aceitável: garantir que o `useMeQuery` seja desmontado/pausado
**antes** do `resetApiState()` no caminho de sucesso (navegar primeiro, resetar depois).
O developer escolhe a implementação; o critério de aceite é o comportamento observável.

## Critério de aceite

- [ ] **Logout de sucesso na UI** — logado em `/studio`, clicar "Sair": o usuário vai para
      **`/login`** (sem `?sessao=expirada`), **sem** a mensagem "Sua sessão expirou.". Verificável:
      teste montado (`internal-shell.integration.test.tsx` ou vizinho) com `<Provider store={makeStore()}>`
      + `fetch` mockado (`me` 200 → `logout` 204 → `me` seguinte 401), clicar "Sair" →
      `router.push` chamado com `'/login'` (string exata, **não** contendo `sessao=expirada`),
      e `reauth.redirect` **não** chamado. Mutante: reverter o fix (sem a flag / reset antes da
      navegação) → a asserção de `router.push('/login')` exato fica vermelha (recebe
      `/login?sessao=expirada`).
- [ ] **Sem laço de requisições** — no mesmo teste, contar as chamadas a `POST /auth/refresh`
      após o clique em "Sair": **0** (o 401 pós-logout não dispara `refresh`). Mutante: fix
      revertido → `refresh` é chamado ≥1× → vermelho.
- [ ] **Não regride a sessão morta de verdade** — o caminho "401 numa chamada normal +
      `refresh` 401" **continua** levando a `/login?sessao=expirada` (`api.test.ts` `[retry S1b]`
      e o caso "401+401 sessão morta" seguem verdes, sem mudança de asserção).
- [ ] **Não regride a falha transitória de logout** — `logout` 500 (sessão ainda válida) →
      mensagem "Não foi possível sair agora.", permanece na área interna, sem navegação
      (`internal-shell.integration.test.tsx` caso 500 segue verde).
- [ ] `npm --prefix mnemonicos-frontend test` / `run lint` / `run typecheck` / `run build` → tudo verde.
- [ ] Sem warnings/lints novos.

### Retry (rodada de gates — gate 8 MEDIA + code-reviewer não-bloqueantes)

- [ ] **[gate 8 — ativação da flag]** A flag `justLoggedOut` só é armada no logout de
      **sucesso** — provado por oráculo próprio: teste montado onde `logout` responde **500**
      (ou erro de rede) e, **na mesma execução**, uma requisição autenticada seguinte
      recebe 401 e o `refresh` também 401 → **exigir** `reauth.redirect('/login?sessao=expirada')`
      **chamado** (a expulsão da sessão morta continua acontecendo após um logout que
      falhou). **Mutante**: mover `justLoggedOut = true` para o `catch`, o `finally` ou
      para antes do `try` de `logout.onQueryStarted` → este teste fica **vermelho** (o
      redirect deixa de ser chamado). Os testes de logout 500 já existentes seguem verdes.
- [ ] **[code-reviewer #2 — limpar a flag no login]** `login.onQueryStarted`, ramo de
      sucesso: `justLoggedOut = false` (1 linha). Fecha o resíduo "401 imediatamente
      pós-login dentro dos 2s seria engolido sem tentar refresh" e a fragilidade de
      isolamento entre testes. Verificação: teste montado — logout de sucesso, depois
      `login` de sucesso dentro da janela, depois uma requisição autenticada 401 + refresh
      renovável → o retry acontece (a flag foi limpa pelo login). Mutante: sem a linha →
      o 401 pós-login é devolvido cru → vermelho.
- [ ] **[code-reviewer #1 — comentário]** Ajustar o comentário em `api.ts` que hoje
      superclama a obrigatoriedade da ordem "setar a flag antes do `resetApiState()`":
      trocar por algo como "setada antes do reset por defesa — o refetch do `me` é
      agendado pelo `dispatch` e não há garantia de que só rode no próximo tick". A ordem
      defensiva no código **permanece**.
- [ ] `[retry S1b]` e o caso "401+401 sessão morta" (`api.test.ts`) seguem verdes **sem
      mudança de asserção** após tudo acima.

### Addendum (autorizado pelo Diretor após teto 4.88 — 2026-08-31): 3º oráculo da §6.3

**Contexto**: `guidelines/project/frontend/next-16.md` §6.3:503-513 (seção CRÍTICA) —
"guarda de curto-circuito com estado de módulo + janela temporal exige **TRÊS** oráculos
distintos: (1) ativação · (2) supressão · (3) expiração". O retry cobriu (1) e (2); falta
(3). Régua: o oráculo (3) tem de **morrer com o mutante da expiração SOZINHO, no próprio
`it()`** — nunca por poluição colateral entre `it()` nem pelo `jest.runOnlyPendingTimers()`
do `afterEach` (que mascara flag presa como falso **verde**).

- [ ] **[§6.3 oráculo 3 — expiração]** `it()` próprio (em `internal-shell.integration.test.tsx`
      ou `api.test.ts`, com timers falsos): logout **204** (arma `justLoggedOut`) →
      `jest.advanceTimersByTime(JUST_LOGGED_OUT_GRACE_MS + 1)` → requisição autenticada
      (`GET /users`) recebe **401** com o `refresh` também **401** → **exigir**
      `reauth.redirect('/login?sessao=expirada')` chamado **1×** (a máquina de re-auth
      voltou ao normal após a janela). Variante no mesmo ou em `it()` irmão: mesma
      sequência com `refresh` **200** → exigir `POST /auth/refresh` **≥1×** e o retry
      bem-sucedido. **Mutante**: `justLoggedOut = false` → no-op dentro do `setTimeout`
      (`api.ts` ~:253, "a flag nunca expira") → **este `it()` fica vermelho SOZINHO**
      (não pelas falhas colaterais em `api.test.ts`). Confirme rodando o mutante e
      contando as falhas: só o `it()` novo.
- [ ] **[export]** `JUST_LOGGED_OUT_GRACE_MS` exportado de `src/store/api.ts` (hoje `const`
      privado) — o teste usa a constante, nunca o literal `2000`/`2001` solto.
- [ ] **[desacoplar do `afterEach`]** Um test-hook `__resetAuthGuards()` exportado de
      `src/store/api.ts` (zera `justLoggedOut` e `refreshInFlight`), chamado no `beforeEach`
      de `internal-shell.integration.test.tsx` **e** de `api.test.ts`. **Verificação**: com
      a linha `jest.runOnlyPendingTimers()` do `afterEach` de `internal-shell.integration.test.tsx`
      **comentada**, os `it()` do arquivo **seguem todos verdes** (o `it()` de ativação
      da 1ª rodada deixa de depender do drain do timer vazado).
- [ ] Não-regressão: `npx jest -t S1b` 4/4 sem mudança de asserção; teste 'a corrida do V5'
      verde; suíte completa verde; lint/typecheck/build verdes.

## TASKs

nenhuma — o brief é a unidade de execução.

## Execução

- **Implementado por**: developer (branch `fix/producao-material-logout-success-race` a partir de `origin/main`)
- **Revisado por**: code-reviewer (régua avulsa, gates 1–7 sobre o diff) · security-engineer
  (gate 8 — toca `baseQueryWithReauth` / redirect / fluxo de sessão) · qa (gate 9 —
  comportamento observável de logout; reexercitar V5 e, se houver como, V6 da caminhada de tela)
- **Commit**: pendente — commit e PR/merge são atos do Diretor
