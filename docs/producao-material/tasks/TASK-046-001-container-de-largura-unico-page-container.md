# TASK-046-001: Container de largura único — `PageContainer` e `<main>` raiz sem container

**Slug**: producao-material
**Pertence a**: PLAN-046
**Realiza (FRs)**: FR-044-017, FR-044-018, FR-044-019, FR-044-027
**Componente**: COMP-046-003 (principal), COMP-046-004
**Wave**: 1
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-046-004

## Contexto

O container de largura sai do `<main>` raiz e passa a ser declarado por quem o usa: Home, 404 e os estados não-prontos da casca recebem as classes exatas de hoje (`default`), e a área interna pronta recebe um container único mais largo (`wide`, `max-w-7xl`), sem a duplicidade entre o `<main>` e a casca. É o contrato de largura que a sidebar (TASK-046-004) consome. Território e decisões: PLAN-046 DEC-046-003/-004 e TRISK-046-002, memo de exploração (itens 1, 5, 6 e riscos R4/R6/R7) e `MAP.md` do slug — citados, não copiados.

## Escopo

### Inclui
- `src/components/page-container.tsx` (novo; Server Component, sem `'use client'`; molde de forma: `src/components/site-header.tsx`) — `PageContainer({ variant = 'default', children })`, com `variant: 'default' | 'wide'`, e as constantes exportadas `PAGE_CONTAINER_CLASS` (`mx-auto w-full max-w-5xl px-4 py-10 sm:px-6` — as classes de hoje do `<main>`, `layout.tsx:41`) e `PAGE_CONTAINER_WIDE_CLASS` (`mx-auto w-full max-w-7xl px-4 py-18 sm:px-6`; `py-18` = 4,5rem = `py-10` do `<main>` + `py-8` da casca de hoje). A docstring avisa que página pública nova precisa envolver-se em `PageContainer` (TRISK-046-002). Nome conferido: kebab-case sem prefixo reservado, como `internal-shell.tsx`/`site-header.tsx` (o perfil não tem seção de nomenclatura de componente além do padrão do diretório — declarado).
- `src/components/page-container.test.tsx` (novo).
- `src/app/layout.tsx` — **só** a classe do `<main>`: passa a `className="w-full flex-1"`. Nada mais muda (gate de `HIDDEN_ROUTES`, header/footer gates, script de tema, `Providers`).
- `src/app/layout.test.tsx` — acréscimo sobre o `<main>` (os asserts existentes seguem).
- `src/app/page.tsx` (Home) — o `<div data-home-content>` passa a ser envolvido por `<PageContainer>` `default`; o `<script>` do bootstrap e o `<HomeSessionGate />` ficam **fora** do container, na mesma ordem de hoje (script antes do conteúdo).
- `src/app/page.test.tsx` — acréscimo do wrapper.
- `src/app/not-found.tsx` (404 da raiz) — o conteúdo passa a ser envolvido por `<PageContainer>` `default`. `src/app/not-found.test.tsx` — acréscimo do wrapper.
- `src/components/internal-shell.tsx` — **só o enquadramento**: os estados carregando (`role="status"`) e sem permissão (`role="alert"`) continuam com a mesma marcação, agora dentro de `<PageContainer>` `default` (o `<main>` não tem mais container); o ramo pronto troca `div.flex.min-h-full.flex-col > div.mx-auto.max-w-5xl…` por `<PageContainer variant="wide">{children}</PageContainer>` (container único, sem sidebar ainda). A lógica de sessão/papel/pista (`useMeQuery`, `router.replace('/login')`, `setSessionHint`, `roleSatisfies`) **não muda**; o estado sem sessão segue devolvendo `null`.
- `src/components/internal-shell.test.tsx` — acréscimo da estrutura de container por estado.

### Não inclui
- Sidebar, grid `14rem | 1fr`, botão do menu e `usePathname` na casca: TASK-046-004 e TASK-046-005.
- `/login` (`src/app/login/page.tsx`): **não** ganha wrapper — seu conteúdo é `position: fixed; inset: 0` e não dependia do container.
- Header e footer (`site-header.tsx`, `app-chrome-gate.tsx`) continuam em `max-w-5xl`: o desalinhamento em ≥1280px é consequência declarada (DEC-046-003, TRISK-046-005), julgada no gate 11 — alargar é DEC nova.
- `globals.css` e `night-palette-tokens.ts` (sem token novo), `proxy.ts`, `internal-routes.ts`, `auth-control.tsx`, `api.ts`.
- A medida de largura **com sidebar** a 1280/1440px e o "sem rolagem horizontal" do layout final: TASK-046-004 (a estrutura "um único container" é provada aqui).
- Link "Voltar ao conteúdo" e qualquer mudança de página interna: TASK-046-003.

## Critérios de pronto

Convenção dos comandos: executados na raiz do repositório `mnemonicos-frontend` (branch `feat/producao-material-sidebar-navegacao`; `npm test` = `jest`), com caminhos relativos a ela; arquivo com `(interno)`/`[id]` no caminho só por `--runTestsByPath` (o argumento posicional do jest é regex e não casa parênteses literais). Commit-base = `f7760a2` (= `origin/main` na redação, lido de `.git/refs/remotes/origin/main`); ausência ancorada com `git diff origin/main...HEAD`. **Fixação**: a redação (scribe, sem shell) conferiu alvos por Read/Grep — as contagens de `it(` abaixo são **estáticas** (Grep em `f7760a2`), e os comandos são **executados pelo Tech Lead na fixação**, com a saída literal registrada aqui antes do despacho; o developer reconfirma as baselines antes do primeiro edit. Todo teste de gate 1 roda pelo comando do critério (arquivo inteiro, nunca `-t`). Mutante = `git worktree add ../wt-mut-046-001 HEAD` com `node_modules` ligado ao da árvore principal, nunca `npm install`/`npm ci`; ao fim `git worktree remove` e `git status --porcelain` vazio (lição `sonda-de-investiga-o-n-o-nasce-em-tests-contagem-de-teste-declara-a-rvore`); cada mutante com controle negativo (sem mutante, mesmo comando → verde, mesma contagem).

- [ ] **Baseline dos arquivos tocados, capturada antes do código** — `npm test -- --runTestsByPath src/app/layout.test.tsx src/app/page.test.tsx src/app/not-found.test.tsx src/components/internal-shell.test.tsx` no commit-base → `Tests: 26 passed, 26 total`, 0 failed (estático: 4 + 6 + 8 + 8). Fecho: o mesmo comando depois do código → `Tests: 33 passed, 33 total` (26 + 2 de `layout.test.tsx` + 1 de `page.test.tsx` + 1 de `not-found.test.tsx` + 3 de `internal-shell.test.tsx`), 0 failed. Valor observável preservado, declarado por arquivo: `page.test.tsx` mantém título `Memorizar não é repetir: é codificar.`, seção `Técnicas do acervo`, nenhum link/botão "Entrar", `<script>` = `getHomeSessionBootstrapScript()` e `[data-home-content]` único e posterior ao `<script>`; `not-found.test.tsx` mantém título, mensagem com `text-muted`, `href="/"` e o link sem `preventDefault`; mutante: trocar o texto do `<h1>` de `page.tsx` → `page.test.tsx` reprova.
- [ ] **`PageContainer` — contrato do item** — `npm test -- --runTestsByPath src/components/page-container.test.tsx` → `Tests: 5 passed, 5 total` (molde de execução: `src/components/site-header.test.tsx`, que roda com a mesma config): **PC1** sem prop, o elemento tem exatamente os tokens `mx-auto w-full max-w-5xl px-4 py-10 sm:px-6` (conjunto, por valor) · **PC2** `variant="wide"` tem exatamente `mx-auto w-full max-w-7xl px-4 py-18 sm:px-6` · **PC3** `PAGE_CONTAINER_CLASS` e `PAGE_CONTAINER_WIDE_CLASS` são iguais aos literais de PC1/PC2 **e diferentes entre si** (a distinção se afirma pelos dois valores, um a um) · **PC4** `children` renderiza dentro do elemento e a subárvore tem um único elemento com classe `max-w-*` · **PC5** `variant="default"` explícito equivale a sem prop. Mutantes, um por sujeito: **K1** trocar só o default (`max-w-5xl` → `max-w-4xl`) → PC1/PC3 reprovam; **K2** trocar só o wide (`py-18` → `py-10`) → PC2/PC3 reprovam. Fonte do literal conferida no commit-base: `git show f7760a2:src/app/layout.tsx | grep -nE "max-w-5xl" | grep -vE '^[0-9]+:\s*(//|\*|/\*)'` → uma linha (`41:`) com `mx-auto w-full max-w-5xl flex-1 px-4 py-10 sm:px-6`.
- [ ] **Server Component e aviso na docstring** — `grep -nE "^'use client'" src/components/page-container.tsx` → saída vazia; o comando roda também contra o molde `src/components/site-header.tsx` → vazio (Server Component) e contra `src/components/internal-shell.tsx` → `1:'use client';` (o predicado distingue); `grep -nE "^\s*\*.*página pública" src/components/page-container.tsx` → ao menos 1 linha (aviso da TRISK-046-002; padrão ancorado em início de linha de docblock — molde do padrão: `grep -nE "^\s*\*.*papel" src/components/internal-shell.tsx` → linhas, prova que o padrão alcança docblock).
- [ ] **`<main>` raiz sem container** — `npm test -- --runTestsByPath src/app/layout.test.tsx` → `Tests: 6 passed, 6 total`: **M1** o elemento `main` da árvore devolvida por `RootLayout({ children: null })` (achado pela travessia `findElementByType` já existente no arquivo) tem exatamente os tokens `w-full flex-1` (por valor) · **M2** nenhum dos tokens `mx-auto`, `max-w-5xl`, `max-w-7xl`, `px-4`, `py-10`, `py-18`, `sm:px-6` está no `className` do `main`. Universo declarado no teste (lição `prova-de-aus-ncia-por-leitura-de-texto-fonte-precisa-declarar-o-universo-lido-derivado-do-quantificador-do-crit-rio`): o critério diz "o `<main>` raiz não carrega container", então o universo é o `className` do elemento `main`, nunca o arquivo nem o `<body>`. Mutante **K3**: devolver `max-w-5xl px-4 py-10 sm:px-6 mx-auto` ao `<main>` → M1 e M2 reprovam. Os 4 testes existentes seguem verdes (valor observável: `SiteHeaderGate` montado e `SiteHeader` direto ausente; `SiteFooterGate` montado e nenhum `<footer>` fixo; `ServiceWorkerRegistration` montado; script de tema igual a `getThemeBootstrapScript()`).
- [ ] **Home e 404 recebem as classes de hoje (FR-044-018, estrutura)** — `npm test -- --runTestsByPath src/app/page.test.tsx src/app/not-found.test.tsx` → `Tests: 16 passed, 16 total` (7 + 9): **P5** o `[data-home-content]` tem um ancestral cujos tokens são exatamente os de `PAGE_CONTAINER_CLASS` (lidos da constante exportada), com controle positivo: os tokens de `PAGE_CONTAINER_WIDE_CLASS` são diferentes · **N9** o `<h1>` da 404 tem um ancestral com os mesmos tokens `default`. Mutantes: **K4** `variant="wide"` no wrapper da Home → P5 reprova; **K5** remover o `<PageContainer>` de `not-found.tsx` → N9 reprova.
- [ ] **Casca: estrutura de container por estado (AC-044-018, parte estrutura — "um único container"; as facetas de largura medida são o passo 2 do Roteiro desta TASK e o passo 3 da TASK-046-004)** — `npm test -- --runTestsByPath src/components/internal-shell.test.tsx` → `Tests: 11 passed, 11 total` (8 + 3): **S1** ramo pronto (EDITOR), dentro de um `<main className="w-full flex-1">` simulado: `main.querySelectorAll('[class*="max-w-"]')` tem exatamente 1 elemento e ele tem os tokens de `PAGE_CONTAINER_WIDE_CLASS`; nenhum `max-w-5xl` na subárvore; `children` está dentro dele · **S2** estado carregando: o `role="status"` está dentro de um elemento com os tokens `default` · **S3** STUDENT (sem permissão): o `role="alert"` com o texto exato `Você não tem permissão para ver esta página.` está dentro de um elemento com os tokens `default`. Mutantes: **K7** voltar `max-w-5xl` ao ramo pronto → S1 reprova; **K8** `wide` no estado carregando → S2 reprova; **K9** um segundo `PageContainer` aninhado no ramo pronto → S1 reprova (contagem 2).
- [ ] **A lógica de sessão/papel da casca não mudou (gate 8 — superfície sensível)** — `git diff -U0 origin/main...HEAD -- src/components/internal-shell.tsx | grep -E '^[+-][^+-]' | grep -E "useMeQuery|router\.replace|setSessionHint|roleSatisfies|requiredRole"` → saída vazia (ausência; vazia também no commit-pai). Alvo não-vazio: `git diff --stat origin/main...HEAD -- src/components/internal-shell.tsx` lista o arquivo. Mutante **K10** (worktree): trocar `requiredRole` por `'STUDENT'` na chamada de `roleSatisfies` → o comando lista a linha **e** `internal-shell.test.tsx` reprova (STUDENT deixa de ser barrado). Os testes de sessão existentes (`loading`, `EDITOR`/`ADMIN` alcançam, erro e sem sessão → `replace('/login')`, papel insuficiente, STUDENT) seguem entre os 8 baseline.
- [ ] **HTTP real sem regressão (TRISK-046-002, R4/R6)** — `npm test -- --runTestsByPath src/app/not-found.integration.test.ts src/app/home.integration.test.ts` → `Tests: 14 passed, 14 total` (fixação executada: 3 `not-found` + 11 `home`; o `it.each(INTERNAL_ROUTE_PREFIXES)` do H7 expande em 3): `next build` + `next start` reais com a trava `acquireNextBuildLock` (`test/next-build-lock`), **sem editar os dois arquivos** (`git diff --stat origin/main...HEAD -- src/app/not-found.integration.test.ts src/app/home.integration.test.ts` → vazio; alvo não-vazio: os dois rodam 14 casos). Não rodar em paralelo com `next dev`/`next build` do mesmo repo (`.next` compartilhado). Cobre: 404 real com `<title>` da rota e "Mnemônicos" no `<header>`; `/` estática, 200, `<html>` sem `data-home-session`, conteúdo visível.
- [ ] **Login intocado (AC-044-019 — login)** — `git diff --stat origin/main...HEAD -- src/app/login/` → saída vazia (ausência; vazia também no commit-pai `f7760a2`; alvo não-vazio: `git diff --stat origin/main...HEAD` lista os arquivos do Inclui). Mutante (worktree): acrescentar uma linha a `src/app/login/page.tsx` → o comando lista o arquivo.
- [ ] **Arquivos fora do diff (contrato congelado do PLAN)** — `git diff --stat origin/main...HEAD -- src/components/auth-control.tsx src/store/api.ts src/proxy.ts src/lib/internal-routes.ts src/components/app-chrome-gate.tsx src/app/globals.css src/app/night-palette-tokens.ts` → saída vazia (ausência; vazia também no commit-pai `f7760a2`; alvo não-vazio: `git diff --stat origin/main...HEAD` lista os arquivos do Inclui). Mutante **K11** (worktree): acrescentar uma linha a `src/components/auth-control.tsx` → o comando lista o arquivo. `git diff --name-only origin/main...HEAD | grep -vE '^(src|tests)/'` → saída vazia (nenhum `package.json`/config no diff). `mnemonicos-backend/**` é outro repositório e fica sem diff por construção.
- [ ] **Suíte inteira** — baseline: `npm test` no commit-base, registrada antes do primeiro edit (`Test Suites: N passed`, `Tests: M passed`, 0 failed); fecho: `npm test` → 0 failed, `Tests: M + 7 + 5 passed` (7 novos nos 4 arquivos + 5 de `page-container.test.tsx`), mesmas suítes mais 1.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (produção e teste) — `npx eslint --max-warnings=0 $(git diff --name-only --diff-filter=d origin/main...HEAD | grep -E '\.(ts|tsx)$')` → exit 0; `npm run typecheck` → exit 0; `npx prettier --check $(git diff --name-only --diff-filter=d origin/main...HEAD)` → exit 0; `npm run lint` → exit 0.

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente** (URLs digitáveis; `next dev`, a execução única deste roteiro):
- Frontend: `http://localhost:3000` (`npm --prefix mnemonicos-frontend run dev`, branch `feat/producao-material-sidebar-navegacao`). Porta fora de `3000`: acrescentar a origem a `CORS_ORIGINS` do `.env` do backend **antes** (lição `cors-origins-de-origem-nica-quebra-silenciosamente-o-padr-o-de-porta-alternativa-entre-sess-es-paralelas`, em observação — sem isso o login fica preso calado); `.env` é local/não versionado: declarar no relatório de fecho o que mudou; nunca editar `.env.example`.
- Backend (só o passo 2): `http://localhost:3333/api/v1` (`npm --prefix mnemonicos-backend run dev`), Postgres `mnemonicos-db`. **O que mudou desde os registros**: o HANDOFF-PLAN-036 registrou Docker Desktop fora do ar (`app_fora_do_ar`) — registro datado; o HANDOFF-PLAN-041 (2026-09-30) subiu o ambiente completo. Quem decide é a sonda: `GET http://localhost:3000/login` → 200 e `GET http://localhost:3333/api/v1/health` → 200, e **uma rota ainda não visitada** na sessão (`goto` de `/content` depois do login — lição `turbopack-root-ausente-…`, não só a home). Backend fora do ar → o passo 2 vira handoff `app_fora_do_ar` (não "verificado por herança") e a entrega fica PARCIAL nele.
- Navegador: Playwright (skill `screen-verify`), artefatos em `thoughts/screen-verify/`. Métricas lidas **na própria página** (`getBoundingClientRect`, `getComputedStyle`) — o layout é do cliente, o observador o alcança.
- Janela de medida: `window.innerWidth − document.documentElement.clientWidth` registrado por medida (esperado 0, barras de rolagem ocultas no headless); se ≠ 0, descontar dos valores esperados.

**Sujeito concreto**: passo 1 — visitante anônimo (contexto novo, sem cookies, `localStorage` vazio). Passo 2 — realm `admin1` (ADMIN) de `keelson.local.json › screenVerify.realms`; credenciais só lá, **nunca copiar valores** para TASK, log ou relatório. `admin2` está desativado no banco de dev (HANDOFF-PLAN-041 §3) — não usar.

**Receita de login** (passo 2; registrar qual caminho foi usado): (1) logar pela UI de `/login` se o ambiente permitir digitar no campo de senha; (2) se a digitação for negada (HANDOFF-PLAN-031, `permissao_ambiente`: a negativa não se repete), `POST http://localhost:3000/api/v1/auth/login` por `context.request` do Playwright (corpo com as credenciais lidas do arquivo, cabeçalho `Origin: http://localhost:3000` por causa do `verifyOrigin`), que **compartilha o cookie jar** do contexto — o prefixo vigente é `/api/v1` (rewrite de `next.config.ts`). Depois, `goto('http://localhost:3000/content')` uma vez (a pista de sessão é gravada pelo próprio app).

**Valores esperados** (aritmética das classes literais **de hoje**, `layout.tsx:41` e `internal-shell.tsx:77` em `f7760a2`, border-box; não é medida em tela — declarada como tal): conteúdo = `min(vw, 1024) − 2·pad` nas páginas públicas e `min(vw, 1280) − 2·pad` na área interna nova, com `pad` = 16 (vw < 640) ou 24 (≥ 640):

| vw | Pública (Home/404): largura · esquerda | Interna nova: largura | Interna de hoje (piso) |
|---|---|---|---|
| 360 | 328 · 16 | 328 | 296 |
| 768 | 720 · 24 | 720 | 672 |
| 1024 | 976 · 24 | 976 | 928 |
| 1280 | 976 · 152 | 1232 | 928 |
| 1440 | 976 · 232 | 1232 | 928 |

Topo: o elemento medido é o próprio container, cujo topo coincide com o fundo do `<header>`; o afastamento é o `paddingTop` dele — nas públicas 40px (`py-10`); na interna pronta, 72px (`py-18` = 40 + 32 de hoje). Leitura: `getComputedStyle(container).paddingTop`, ou `container.firstElementChild.getBoundingClientRect().top − header.getBoundingClientRect().bottom`.

**Passos (um por AC de gate 9)**:

1. **AC-044-019 — Home, login e 404 idênticas a antes, nos dois temas e nas 5 larguras** (visitante anônimo). Para cada tema (claro padrão; escuro por clique em "Mudar para tema escuro", confirmando `document.documentElement.dataset.theme === 'dark'`) e cada largura 360/768/1024/1280/1440 (altura 900): (a) Home `/`: a caixa `document.querySelector('[data-home-content]').parentElement` tem `clientWidth − paddingLeft − paddingRight` e `left` iguais à tabela (coluna Pública), `getComputedStyle(container).paddingTop` = 40px (equivale a `container.firstElementChild.getBoundingClientRect().top − header.getBoundingClientRect().bottom`; o topo do próprio container coincide com o fundo do `<header>`); (b) 404 `goto('/rota-inexistente-xyz')` (fora dos prefixos internos → a 404 personalizada): `document.querySelector('main > div')` com os mesmos valores; (c) login `/login`: o `div` com `position: fixed` tem rect igual à janela (`x=0, y=0, width=vw, height=vh`) e `getComputedStyle(...).position === 'fixed'`, sem `<header>`/`<footer>` (a moldura esconde `/login`). Esperado: todos os números da tabela; uma captura por tema nas larguras 360 e 1440 como evidência. **Falha que o passo reprova**: `<main>` ainda com container mais wrapper (largura menor por padding dobrado), ou `wide` usado nas públicas (1232 em vez de 976 a 1280/1440). Controle positivo: a mesma leitura a 1280 distingue 976 (pública) de 1232 (interna, passo 2).
2. **AC-044-018 (parte larguras da área interna, ainda sem sidebar; a estrutura "um único container" é o critério S1)** (realm `admin1`, login pela receita). Em `/content` (`document.querySelector('main > div')`, o `PageContainer` `wide`), nas 5 larguras: largura útil `clientWidth − paddingLeft − paddingRight` = coluna "Interna nova" e **≥ coluna "Interna de hoje"** em cada largura; `getComputedStyle(container).paddingTop` = 72px (ou `container.firstElementChild.getBoundingClientRect().top − header.getBoundingClientRect().bottom` = 72; o topo do container coincide com o fundo do `<header>`); a 360px `document.documentElement.scrollWidth <= window.innerWidth` (sem rolagem horizontal, FR-044-027). Esperado: 328/720/976/1232/1232, nenhum valor abaixo do piso. Observação: a largura com sidebar a 1280/1440 (984) é outra medida — TASK-046-004.

**Restauração**: fechar o contexto do Playwright; se sobrou sessão, clicar "Sair" ou `context.clearCookies()`; `localStorage.clear()` da origem; o tema volta ao padrão removendo `mnemonicos:theme`. Ao fim: encerrar o `next dev` e o backend que a execução subiu.

## Riscos específicos

- **TRISK-046-002 (alta)**: tirar o container do `<main>` raiz afeta Home/404 e cria contrato novo — página pública futura sem `PageContainer` sai sem margem (aviso na docstring; `layout.test.tsx` o documenta).
- Layout shift de largura no carregamento em ≥1024px (carregando em `default` → pronto em `wide`): consequência declarada (DEC-046-003 b), sem efeito sobre a promessa de largura; gate 11 julga.
- A troca de `div.flex.min-h-full` por `PageContainer wide` no ramo pronto pode alterar a altura mínima de páginas curtas — o passo 2 observa o topo e a largura, e o gate 11 observa o rodapé; divergência volta ao Tech Lead.
- Gates: gate 8 aplica (a casca é superfície de sessão/papel; a lógica fica sem diff — critério acima); gate 11 aplica (Home/404/área interna, dois temas, larguras); gate 10 **n/a** (nenhuma consulta, endpoint ou lista nova).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-30T18:29:02-0300
**Data conclusão**: 2026-09-30T18:49:46-03:00
**Commit SHA**: 9b60fc2, 1915183 (remoção de comentário, gate 7 Art. 7) (mnemonicos-frontend, branch feat/producao-material-sidebar-navegacao)
**Jira**: pendente — acesso ao Jira desligado pelo Diretor; sub-tarefa a criar sob KAN-178 (docs/producao-material/tracker-local-KAN-178.md)

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 1) — security-engineer
- [x] Comportamento (gate 9): consolidado (DoD, Etapa 4) — SPEC-044 sem FEATs; o Roteiro do gate 9 desta TASK é carregado pelo `qa` na Etapa 4 do PLAN-046
<!-- Branch, tentativas, arquivos, revisores e narrativa (retries, escalações) vivem no
ledger da sessão e no commit da closure (4.76) — não se repetem aqui (4.409). -->
