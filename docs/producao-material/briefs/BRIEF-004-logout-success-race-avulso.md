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

## TASKs

nenhuma — o brief é a unidade de execução.

## Execução

- **Implementado por**: developer (branch `fix/producao-material-logout-success-race` a partir de `origin/main`)
- **Revisado por**: code-reviewer (régua avulsa, gates 1–7 sobre o diff) · security-engineer
  (gate 8 — toca `baseQueryWithReauth` / redirect / fluxo de sessão) · qa (gate 9 —
  comportamento observável de logout; reexercitar V5 e, se houver como, V6 da caminhada de tela)
- **Commit**: pendente — commit e PR/merge são atos do Diretor
