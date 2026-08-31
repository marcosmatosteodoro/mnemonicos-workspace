# TASK-003-015: Shell da área interna

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: FR-002-013, FR-002-023
**Funcionalidade**: FEAT-002-002 (primária), FEAT-002-001
**Componente**: COMP-003-024, COMP-003-022
**Wave**: 7
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done
**Data início**: 2026-08-30T12:00:00-03:00

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 via `next/jest`, `testEnvironment: jsdom`, Testing Library — em `mnemonicos-frontend/`. Gate de tela: `gates.screenVerify` (Playwright MCP). Gates: `npm --prefix mnemonicos-frontend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: TASK-003-013
- **Bloqueia**: nenhuma

## Contexto

COMP-003-024 / DEC-003-011 / FR-002-013 / FR-002-023. Shell da área interna: resolve a sessão (`me`) e reflete os três estados de navegação protegida (carregando neutro / vista renderizada / redirect ou "sem permissão"), e hospeda o controle de logout com seus três estados observáveis. O backend é quem nega de fato (FR-002-012 — TASKs 003-007/011); o shell é apresentação.

**COMP-003-022 (EMENDA Wave 6)**: esta TASK cria o grupo de rotas `(interno)` — logo o `config.matcher` do `proxy.ts` (que TASK-003-013 deixou como *working set* `['/studio/:path*','/gestao/:path*']`) passa a ser **derivado** dos segmentos reais criados aqui, via símbolo compartilhado com o `layout.tsx`. O achado do gate 1/8 da Wave 6 era que `(interno)` não é endereçável por matcher e a lista à mão deriva em silêncio.

## Escopo

### Inclui
- `mnemonicos-frontend/src/app/(interno)/layout.tsx` — layout do grupo `(interno)`; compõe `InternalShell` (com uma prop `requiredRole`).
- `mnemonicos-frontend/src/app/(interno)/studio/page.tsx` — página de aterrissagem mínima da área interna (destino do `router.push` da tela de login — TASK-003-014 navega para `/studio`). Server Component simples; o conteúdo real do studio é fatia futura (F2+). Sem ela o sucesso do login cai em 404.
- `mnemonicos-frontend/src/components/internal-shell.tsx` — `'use client'`. Usa `useMeQuery`: *em andamento* → estado de carregamento neutro (nó `role="status"` com texto pt-BR); *sucesso* (sessão válida, papel suficiente) → renderiza `children`; *falha* sem sessão → redireciona para `/login`; *falha* com sessão e papel insuficiente → mensagem "Você não tem permissão para ver esta página." sem o conteúdo. Controle de logout: *em andamento* (desabilitado + progresso), *sucesso* (sessão encerrada no servidor via mutation `logout`, volta ao login), *falha* (mensagem genérica pt-BR, permanece na área interna).
- `mnemonicos-frontend/src/proxy.ts` (**EMENDA COMP-003-022 Wave 6**) — o `config.matcher` deixa de ser working set: passa a ser **derivado** dos segmentos de rota reais do grupo `(interno)` recém-criado (um símbolo compartilhado — ex.: `INTERNAL_ROUTE_PREFIXES` — exportado de um módulo que o `layout.tsx` também consome, nunca duas listas à mão). Nesta fatia o grupo tem `/studio`; se surgir outro segmento, entra no símbolo.
- `mnemonicos-frontend/src/components/internal-shell.test.tsx` · `mnemonicos-frontend/src/proxy.test.ts` (o teste do matcher passa a **enumerar** os segmentos de `src/app/(interno)/` e falhar se algum não estiver coberto por `config.matcher`; e afirmar que `/` — home pública — **não** é guardada).
- **`mnemonicos-frontend/src/store/api.ts` (carve-out — furo no plano: AC-002-027 × correção S1b da Wave 6)** — o `logout.onQueryStarted` foi endurecido na 2ª volta do S1b (Wave 6) com um `catch` que redireciona para `/login` em **qualquer** rejeição. Isso quebra AC-002-027/FR-002-023 (falha de logout → **permanece** na área interna e tenta de novo). Correção: o `catch` do `logout.onQueryStarted` **não força navegação** — o redirect da "sessão morta de vez" (401 + refresh também falhou) já vive no ramo `!renewed` do `baseQueryWithReauth`; falha transitória (500/rede, sessão ainda válida) → só `resetApiState()` (limpa o cache) e o `InternalShell` mostra "tente de novo". S1b intacto: `/auth/logout` continua fora de `PUBLIC_AUTH_PATHS` (não vira no-op) e a sessão morta continua expulsando a aba pelo `baseQueryWithReauth`.

### Não inclui
- A tela de login (TASK-003-014).
- A barreira real de autorização (é o backend — FR-002-012; TASKs 003-007, 003-011).
- Telas de gestão de equipe (fora — §4.2 da SPEC).
- O conteúdo real do studio (F2+) — `(interno)/studio/page.tsx` aqui é só aterrissagem.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `layout.tsx` do grupo `(interno)` compõe `InternalShell`.
2. `InternalShell` — `useMeQuery`: `isLoading` → carregando neutro (`role="status"`); `isError`/sem sessão → `router.replace('/login')`; sessão + `requiredRole` acima do papel → "sem permissão"; senão `children`.
3. Controle de logout — `useLogoutMutation`; `disabled` + progresso; sucesso → `router.push('/login')`; falha → mensagem genérica, permanece.
4. Testes com mock de `useMeQuery`/`useLogoutMutation`.

## Critérios de pronto

- [ ] O `InternalShell` exibe um estado de carregamento neutro (sem `children`) enquanto `useMeQuery` resolve — verificação executável: `npm --prefix mnemonicos-frontend test -- internal-shell` → com `useMeQuery` mockado em `isLoading`, `getByRole('status')` traz texto pt-BR de carregando neutro (não 'qualquer nó') e `children` não é renderizado. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] O `InternalShell` renderiza `children` com sessão válida e papel suficiente, redireciona para `/login` sem sessão, e mostra "Você não tem permissão para ver esta página." com papel insuficiente — verificação executável: `npm --prefix mnemonicos-frontend test -- internal-shell` → 3 casos via mock de `useMeQuery`: sucesso + papel suficiente → `children` no DOM; erro / sem sessão → redirect para `/login` chamado; sucesso + `requiredRole` acima do papel → texto de "sem permissão" sem `children`. `Tests: ≥3 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-013 (ramo "sessão válida + papel insuficiente → sem permissão") no gate 1 — verificação executável: `npm --prefix mnemonicos-frontend test -- internal-shell` → com `useMeQuery` devolvendo um usuário EDITOR e o `InternalShell` numa vista-stub que exige `requiredRole="ADMIN"`, o DOM mostra "Você não tem permissão para ver esta página." e **não** renderiza `children`; F1 não embarca tela ADMIN-only, então este ramo é provado aqui (não no gate 9). `Tests: ≥1 passed`. Fixada antes do código.
- [ ] O controle de logout fica desabilitado com indicador de progresso enquanto a mutation `logout` está pendente; em sucesso navega para `/login`; em falha mostra mensagem genérica em pt-BR e permanece — verificação executável: `npm --prefix mnemonicos-frontend test -- internal-shell` → 3 casos via mock da mutation `logout`: `pending` → controle `disabled` + progresso; resolvida → navegação para `/login` chamada; rejeitada (500) → `findByText` da mensagem genérica pt-BR, sem navegação. `Tests: ≥3 passed`. Fixada antes do código.
- [ ] **[furo no plano — AC-002-027 × S1b]** Falha **transitória** de logout (500/rede) mantém o usuário na área interna — verificação executável: `npm --prefix mnemonicos-frontend test -- api` → com o `logout` mockado respondendo **500** (não 401), o `logout.onQueryStarted` **não** chama `reauth.redirect`/`window.location.assign`; `store.getState().api.queries` é zerado (`resetApiState`), a sessão `me` segue válida no mock. Mutante: `catch` do `logout.onQueryStarted` redireciona em qualquer rejeição → o caso 500 chama o redirect (vermelho). E o caminho "sessão morta de vez" (`logout` 401 + `refresh` 401) **continua** redirecionando para `/login` (pelo ramo `!renewed` do `baseQueryWithReauth` — teste `[retry S1b]` da TASK-003-013 segue verde). `Tests: ≥2 passed`. Fixada antes do código.
- [ ] **[EMENDA COMP-003-022 Wave 6 · retry Wave 7 A1/A2]** `config.matcher` do `proxy.ts` é um **array literal de strings literais** (`['/studio', '/studio/:path*']`) — nunca `.flatMap()`, spread ou template com expressão dentro do `config` (o Next lê `config` por AST estático e aborta o build em `CallExpression`). A derivação do símbolo compartilhado `INTERNAL_ROUTE_PREFIXES` acontece **no teste** (oráculo de defasagem), não no arquivo. Verificações executáveis:
  - `npm --prefix mnemonicos-frontend run build` → exit 0 (mutante: `config.matcher` como `INTERNAL_ROUTE_PREFIXES.flatMap(...)` → build **aborta** em `./src/proxy.ts` com `matcher needs to be a static string or array of static strings`). Baseline: hoje o build está **vermelho** por esse exato motivo — o critério fecha quando fica verde.
  - `npm --prefix mnemonicos-frontend test -- proxy` → **teste de wiring**: `extractExportedConstValue` de `next/dist/build/analysis/extract-const-value` sobre `src/proxy.ts` devolve `{ value: { matcher: [...] } }` e **não** `{ unsupported: ... }` (mutante: `.flatMap()` → `unsupported` → vermelho). Se o import do extractor for instável, o oráculo de wiring é o `run build` acima anexado ao critério.
  - `npm --prefix mnemonicos-frontend test -- proxy` → **teste de equivalência** literal↔símbolo: `config.matcher` é igual a `INTERNAL_ROUTE_PREFIXES.flatMap((p) => ['/' + p, '/' + p + '/:path*'])` computado no teste (mutante: mudar o literal em `proxy.ts` sem tocar o símbolo → vermelho). Mais os casos já existentes de enumeração do diretório real de `(interno)/` e de `/` não-guardada. `Tests: ≥4 passed`. Fixada antes do código.
- [ ] **[retry Wave 7 A3 — AC-002-013]** Cada linha de `SUFFICIENT_ROLES` que a produção exercita tem caso — `npm --prefix mnemonicos-frontend test -- internal-routes` → `roleSatisfies('STUDENT', 'EDITOR') === false`, `roleSatisfies('STUDENT', INTERNAL_MIN_ROLE) === false`, `roleSatisfies('EDITOR', 'EDITOR') === true`, `roleSatisfies('ADMIN', 'EDITOR') === true`, `roleSatisfies('EDITOR', 'ADMIN') === false`, `roleSatisfies('ADMIN', 'ADMIN') === true`. Mutante: `EDITOR: ['STUDENT', 'EDITOR', 'ADMIN']` em `internal-routes.ts` → o caso `roleSatisfies('STUDENT', 'EDITOR')` fica **vermelho** (hoje esse mutante sobrevive com 68/68 verde). Mais um caso em `internal-shell` — `useMeQuery` devolvendo STUDENT contra `requiredRole={INTERNAL_MIN_ROLE}` → "sem permissão", sem `children`, sem `replace`. `Tests: ≥1 passed` (internal-routes) + `≥1 passed` (internal-shell). Fixada antes do código.
- [ ] **[retry Wave 7 A4 — AC-002-027, 2ª volta]** Falha transitória de `logout` produz **feedback observável que sobrevive ao ciclo de vida do cache** — o oráculo é o **do critério**: `InternalShell` **MONTADO** contra a `api` real (store real via `makeStore()` + `fetch`/`Response`/`Request`/`Headers` do realm Node, injetados por um `testEnvironment` custom que estende `jest-environment-jsdom` — **sem dependência nova**), não função pura sobre `me.select()`. Cenário: `me` resolve EDITOR → clicar "Sair" → `logout` responde **500**. Asserções (todas): (a) a mensagem `Não foi possível sair agora. Tente novamente.` **está no DOM** após o `flush` e **permanece** (não é destruída por remontagem da subárvore); (b) `replaceMock` / `pushMock` **não** são chamados; (c) `me` segue com `data` (sessão não foi zerada). Design (EMENDA COMP-003-021 Wave 7): `logout.onQueryStarted` faz `resetApiState()` **só após sucesso**; falha transitória não reseta nem navega. Mutante 1: `resetApiState()` no `finally` (após sucesso **e** falha) → a subárvore desmonta, `hasFailed` some, asserção (a) **vermelha**. Mutante 2: `catch` do `logout.onQueryStarted` chama `reauth.redirect` → asserção (b) **vermelha**. Controle positivo (4.186): sem nenhum mutante, `logout` 200 → `pushMock('/login')` chamado e cache zerado (o instrumento distingue sucesso de falha). `grep -n "resetApiState" mnemonicos-frontend/src/store/api.ts` → a ocorrência em `logout` está dentro do `try`/após `await queryFulfilled`, nunca em `finally`. `Tests: ≥1 passed` (montado) + o caminho "sessão morta de vez" (`api.test.ts` `[retry S1b]`) segue verde. Fixada antes do código.
- [ ] **[retry Wave 7 A4 — gate 7]** `internal-shell.tsx` reflete a costura real: com `me` preservado na falha transitória, `computeMissingSession` e sua guarda `isUninitialized`/`isFetching` (postas na 1ª volta) **saem** — o predicado volta a inline `missingSession = isError || (!isLoading && !data)` e o export de produção some — **a menos que** o teste montado acima demonstre necessidade residual (então o docblock descreve o que a costura montada de fato faz, sem narrar a rodada — 4.88). Verificação: `grep -n "computeMissingSession" mnemonicos-frontend/src/` → sem resultado, ou (se mantido) o docblock não afirma causalidade que o teste montado contradiz.
- [ ] `npm --prefix mnemonicos-frontend run build` → exit 0 (gate `quality.build` da ficha — obrigatório em toda TASK que edita `proxy.ts` / route segment config; ver `next-16.md` §11).
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-frontend run lint` → exit 0 (baseline capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`next-16.md`, §1/§6.3 — esconder ≠ autorizar; README do repo vence em conflito).
- [ ] Code review aprovado.

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente**: app Next em `http://localhost:3000/` (raiz do grupo `(interno)`); API do backend em `http://localhost:3333/api/v1`; realm dev local (Postgres do `docker-compose`). Credenciais DEV vêm de `keelson.local.json` — o gate as injeta.

**Sujeito concreto**: EDITOR de teste `editor.gate@mnemonicos.local` e ADMIN semeado (`SEED_ADMIN_EMAIL`/`SEED_ADMIN_PASSWORD`), senhas fornecidas pelo gate.

**Pré-condição — montar**:
1. `env` do backend com `SEED_ADMIN_EMAIL`/`SEED_ADMIN_PASSWORD`; rodar o seed (`npm --prefix mnemonicos-backend run db:seed` ou `npx prisma db seed` em `mnemonicos-backend/`) → 1 ADMIN.
2. Autenticar como ADMIN e `POST /api/v1/users` `{ email: 'editor.gate@mnemonicos.local', name: 'Editor Gate', role: 'EDITOR', password: '<12+ chars>' }`.

**Pré-condição — restaurar** (ao fim): `DELETE FROM sessions WHERE "userId" IN (<id do EDITOR de teste>, <id do ADMIN de teste>);` e `DELETE FROM users WHERE email = 'editor.gate@mnemonicos.local';` no Postgres local — nunca todas as sessões do realm dev compartilhado.

**Passo (AC-002-013) — redirect e sucesso**: navegar a uma vista protegida do grupo `(interno)` — (a) em aba anônima, sem cookie `mnemo_access`: a navegação redireciona para `/login`; (b) logado como EDITOR: durante a resolução de `me`, um estado de carregamento neutro aparece; com sessão válida e papel suficiente, a vista renderiza. Este passo é o gate falsificável desses dois ramos de AC-002-013.

**Ramo "sessão válida + papel insuficiente → sem permissão"**: `n/a com motivo` — não há superfície ADMIN-only em F1; o ramo é coberto no **gate 1** (Testing Library com `useMeQuery` devolvendo EDITOR numa vista-stub que exige ADMIN — ver Critérios de pronto). Não há passo de gate 9 que hackeie `requiredRole` numa vista real.

**Passo (AC-002-027)**: logado como EDITOR na área interna, acionar o controle de logout — enquanto a requisição está pendente o controle fica desabilitado com indicador de progresso; em sucesso, a sessão é encerrada no servidor (verificar `sessions.revokedAt` preenchido para a família; reapresentar o cookie anterior a uma rota protegida → 401) e o usuário volta ao `/login`; simular falha (parar o backend ou mock de 500) → mensagem genérica em pt-BR e permanência na área interna. Este passo é o gate falsificável de AC-002-027.

## Riscos específicos

- O ramo "papel insuficiente" não tem superfície ponta-a-ponta em F1 (nenhuma tela ADMIN-only) — é coberto no gate 1 via vista-stub; o gate 9 registra o ramo como `n/a com motivo`. Sem prior handoff registrado para o slug.
- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-frontend/src/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-08-30T12:00:00-03:00
**Data conclusão**: 2026-08-31T11:06:44-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 3946b60 (implementação) · 0c54b96 (furo AC-002-027 × S1b) · f6cc4ed (retry Wave 7 — `config.matcher` literal + wiring de build; cobertura `roleSatisfies`/AC-002-013) · e6d0c75 (rodada dirigida A4 — `logout` falho preserva cache e feedback)
**Jira**: KAN-25
**Implementado por**: developer
**Revisado por**: code-reviewer (gates 1–7) · security-engineer (gate 8) — `revisado_por ≠ implementado_por`
**Tentativas**: 4 (implementação + reconciliação do furo AC-002-027 + retry consolidado da Wave 7 + rodada dirigida A4 autorizada após teto 4.88)
**Cobertura final**: n/a (não coletada; piso do projeto 50% mantido — suíte frontend 68→86)
**Arquivos modificados**:
  - mnemonicos-frontend/src/app/(interno)/layout.tsx
  - mnemonicos-frontend/src/app/(interno)/studio/page.tsx · page.test.tsx
  - mnemonicos-frontend/src/components/internal-shell.tsx · internal-shell.test.tsx · internal-shell.integration.test.tsx
  - mnemonicos-frontend/src/lib/internal-routes.ts · internal-routes.test.ts
  - mnemonicos-frontend/src/proxy.ts · proxy.test.ts
  - mnemonicos-frontend/src/store/api.ts · api.test.ts (carve-out: furo AC-002-027 × S1b + EMENDA COMP-003-021 Wave 7)
  - mnemonicos-frontend/test/jsdom-fetch-env.js (novo — `testEnvironment` custom que estende `jest-environment-jsdom`, sem dependência nova)
  - mnemonicos-frontend/eslint.config.mjs (bloco `files: ['test/**/*.js']` — CJS do environment custom)

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando — frontend jest 86/86 (11 suítes); `quality.build` exit 0 (era vermelho — fechou no retry); lint/typecheck exit 0; caminho "sessão morta de vez" (`api.test.ts` S1b) 4/4 sem mudança de asserção
- [x] Lint limpo
- [x] Aderência à ficha/perfil — `next-16.md` §6.3/§11 (`config` por AST estático: array literal, derivação vive no teste + wiring por `extractExportedConstValue`); §6.5 (estado de servidor só em RTK Query; `makeStore()` função)
- [x] Code review aprovado — code-reviewer, re-review da rodada dirigida A4: A4 fechou com prova falsificável (3 mutantes mortos — `resetApiState` no `finally` → mensagem some; `catch` redireciona → asserção (b) vermelha; predicado neutralizado → 2 ramos vermelhos — com controle positivo verde). Regressão de prova 4.174 auditada executando nos dois sentidos: inversão declarada da EMENDA COMP-003-021 Wave 7, não enfraquecimento
- [x] ACs verificados — AC-002-013 (`roleSatisfies` por linha + 4 ramos do `InternalShell`, gate 1) · AC-002-027 (falha transitória de `logout` mantém o usuário na área interna **com feedback observável**, oráculo montado contra a `api` real) · EMENDA COMP-003-022 (`config.matcher` derivado do grupo `(interno)`, `/` não guardada)
- [x] Segurança (gate 8): aprovado (Wave 7 2ª volta + re-review da rodada dirigida A4) — security-engineer; ACHADO 1 (ALTA, `config.matcher` derrubava `next build`) FECHADO, verificado por build + manifesto compilado + probe HTTP real; `logout` falho preservar o cache não abre vazamento de outra identidade
- [ ] Comportamento (gate 9): pendente_handoff (FEAT-002-002 primária + FEAT-002-001) — qa; caminhada e2e de AC-002-013 (aba anônima → redirect; login EDITOR → carregando → vista) e ida-e-volta UI→servidor do logout de sucesso (AC-002-027, `sessions.revokedAt` + cookie antigo → 401) não exercitáveis (causa: `credencial`). Seed em HANDOFF-PLAN-003.md. Exercitado com execução real: AC-002-010/011/012/014 sobre `createApp()` + Postgres real (route-authz-matrix 28/28); partes de gate 1 de AC-002-013/027 APROVADAS

**Notas**: FR-002-013 / FR-002-023 satisfeitos. A rodada dirigida A4 (`e6d0c75`) foi autorizada pelo Tech Lead em nome do Diretor após o teto de convergência 4.88 (2ª volta do gate 1 no achado A4) — **veto na Entrega**. Design decidido: `logout.onQueryStarted` reseta o cache **só após sucesso** (idêntico a `login`), amendando a EMENDA COMP-003-021 Wave 7 (o "só `resetApiState()` na falha transitória" era o próprio defeito — apagava `me`, desmontava `LogoutControl`, matava a mensagem). `computeMissingSession` e a guarda `isUninitialized`/`isFetching` postas na 1ª volta foram removidas (tratavam o sintoma). 2 `licao_candidata` alvo:processo pendentes de agile-coach (Etapa 4.5): isolamento de escrita entre gates paralelos; `git diff HEAD` (não `git diff`) no contrato de higiene de gate.
