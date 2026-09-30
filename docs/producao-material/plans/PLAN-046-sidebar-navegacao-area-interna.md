# PLAN-046: Sidebar de navegação da área interna

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.3
**Autor**: scribe (redação delegada pelo Tech Lead; triagem técnica do Tech Lead)
**Data**: 2026-09-30

## Aderência a guidelines

**Decisões irreversíveis do slug tocadas**: nenhuma. A única decisão irreversível do INDEX é DEC-029-003 (snapshot de `ContentVersion`), sem vizinhança com esta entrega (só frontend, sem banco). A DEC-003-011 / COMP-003-022 (guarda só onde a sessão é pressuposta, `proxy.ts` e `INTERNAL_ROUTE_PREFIXES` como fonte do matcher) é reversível e **preservada literalmente** (DEC-046-012).
**Decisões irreversíveis de outros slugs em conflito**: nenhuma — `infra-vercel` não tem bloco de decisões (sem `INDEX.md`).
**Exceções aos guidelines**: nenhuma. O trabalho segue `guidelines/project/frontend/` (precedência sobre `next-16.md`): Server Components por padrão e `'use client'` só onde há estado/evento; estado do servidor em RTK Query; tokens no `@theme`/`:root` de `globals.css`; identificadores em inglês, texto de UI em pt-BR.

## Cobertura

**SPEC referenciada**: SPEC-044
**Slice declarado**: cobertura total (Caso D — 100% da SPEC-044: FR-044-001..027 e NFR-044-001..004)

**FRs cobertos**:
- FR-044-001
- FR-044-002
- FR-044-003
- FR-044-004
- FR-044-005
- FR-044-006
- FR-044-007
- FR-044-008
- FR-044-009
- FR-044-010
- FR-044-011
- FR-044-012
- FR-044-013
- FR-044-014
- FR-044-015
- FR-044-016
- FR-044-017
- FR-044-018
- FR-044-019
- FR-044-020
- FR-044-021
- FR-044-022
- FR-044-023
- FR-044-024
- FR-044-025
- FR-044-026
- FR-044-027

**NFRs cobertos**:
- NFR-044-001
- NFR-044-002
- NFR-044-003
- NFR-044-004

## 1. Visão técnica

Só frontend (`mnemonicos-frontend`, branch `feat/producao-material-sidebar-navegacao`); backend, `proxy.ts`, `internal-routes.ts` (só importado), a guarda, `auth-control.tsx` e `api.ts` ficam com **diff vazio**. Jira: KAN-178 (História raiz). A sidebar é exibição, não autorização (NFR-044-002, perfil §6.3): nenhuma rota nem dado depende dela.

Cinco peças cooperam:

1. **Lista declarada** (`src/lib/internal-nav.ts`, DEC-046-002): itens `{ label, href }` (Painel `/studio`, Conteúdos `/content`, Biblioteca visual `/visual-library`, nessa ordem) e a regra pura de seção atual (igual ou prefixo em fronteira de segmento). Separada de `INTERNAL_ROUTE_PREFIXES`; um teste a amarra às rotas reais.
2. **Sidebar** (`InternalSidebar`, client, DEC-046-005/006): um único `<nav>` com rótulo, links e `aria-current="page"` no item da seção. A partir do breakpoint `xl` (1280px) é coluna fixa ao lado do conteúdo; abaixo, o mesmo `<nav>` vira menu recolhível (disclosure não modal) aberto por um botão na casca, fechado por padrão. Visibilidade por CSS (sem hook de media query); fechamento por item/Esc/toque fora/troca de rota/cruzar o breakpoint.
3. **Casca** (`InternalShell`, DEC-046-001): a sidebar e o botão existem **só no ramo "pronto"** — carregando, sem sessão e sem permissão herdam a ausência por construção (FR-005/023).
4. **Container e largura** (`PageContainer`, DEC-046-003/004): o container sai do `<main>` raiz e passa a ser declarado por quem o usa; páginas públicas recebem exatamente as classes de hoje, e a área interna pronta recebe um container único mais largo (`max-w-7xl`), com a conta nas 5 larguras de referência registrada na DEC-046-004.
5. **Logo por sessão** (`SiteLogo`, client, DEC-046-007/008): lê `useMeSilentQuery` (a mesma assinatura do `AuthControl` — 0 GET extra) e `roleSatisfies(role, INTERNAL_MIN_ROLE)`; `/studio` só com sessão ativa e papel com acesso, `/` em todo outro caso (neutro, indeterminado, falha, STUDENT). No clique, sem pista de sessão (logout em outra aba) → `/`, sem rede.

Mais a **Volta ao conteúdo** na Tira (COMP-046-006) e a suíte de emendas/provas (COMP-046-007).

**Emenda à SPEC-040 e HANDOFF-PLAN-041**: o comportamento do logo com sessão muda (antes fixo em `/`, SPEC-044 A-044-002). O HANDOFF-PLAN-041 segue aberto; os roteiros V6/V8 continuam válidos porque exercitam o link da 404 e a volta pelo histórico, que seguem em `/`; o que muda é que, com sessão EDITOR/ADMIN, o logo não leva mais à Home pública (testes que fixam o logo em `/` com sessão são reescritos; os de 404/voltar do login seguem — R3).

**Gates**: gate 9 (comportamento verificado) com `/studio` etc. reais e conta EDITOR/ADMIN; o estado "sem permissão" (AC-044-006) é provado por teste automatizado — não há conta sem o papel (A-044-006/010) — e a prova em tela fica em handoff. Gate 11 (design/UX) aplica: disclosure, foco, desalinhamento com header/footer (DEC-046-003). Gate 10 (performance) **n/a**: nenhuma consulta nova, nenhum endpoint, nenhuma lista; o único listener novo vive só com o menu aberto.

## 2. Stack e dependências

Stack vigente, sem reescolha e **sem dependência nova**: Next 16 (App Router), React 19, Tailwind 4 (tokens no `@theme`/`:root` de `globals.css`), RTK Query (`src/store/api.ts`, só leitura via `useMeSilentQuery`), Jest 29 + Testing Library + jsdom. Tudo no repositório `mnemonicos-frontend`; **nenhuma mudança no backend**.

Reúso (perfil §9): `INTERNAL_HOME`, `INTERNAL_MIN_ROLE`, `roleSatisfies`, `INTERNAL_ROUTE_PREFIXES` (`src/lib/internal-routes.ts`); `useMeSilentQuery` (`api.ts`); `hasSessionHint` (`src/lib/session-hint.ts`); padrão de foco visível de `src/app/login/page.tsx:80`; utilitários `surface-card`/`text-muted`/`text-link` e tokens `--surface`/`--surface-raised`/`--link`/`--border-subtle` de `globals.css`; pares de contraste de `src/app/night-palette-tokens.ts`; moldes de teste `site-header.test.tsx`, `internal-shell.test.tsx`, `auth-control.integration.test.tsx`, `home-session-gate.integration.test.tsx` (G17), `tests/support/match-media.ts` (a estender, não copiar).

Arquivos tocados (inventário): novos — `src/lib/internal-nav.ts`, `src/components/internal-sidebar.tsx`, `src/components/page-container.tsx`, `src/components/site-logo.tsx` (+ testes); alterados — `src/components/internal-shell.tsx`, `src/components/site-header.tsx`, `src/app/layout.tsx` (só a classe do `<main>`), `src/app/page.tsx`, `src/app/not-found.tsx`, `src/app/(interno)/content/[id]/tira/page.tsx`, `tests/support/match-media.ts` (estendido) e os testes existentes listados no COMP-046-007. **Fora do diff**: `auth-control.tsx`, `app-chrome-gate.tsx`, `api.ts`, `proxy.ts`, `internal-routes.ts`, `globals.css`, `night-palette-tokens.ts` (sem token novo, DEC-046-009).

## 3. Componentes

### COMP-046-001: Lista declarada de itens e regra de seção atual
**Responsabilidade**: `src/lib/internal-nav.ts` — `INTERNAL_NAV_ITEMS` (`readonly { label: string; href: string }[]`, ordem Painel, Conteúdos, Biblioteca visual; `href` derivados dos literais de rota, rótulos em pt-BR) e a função pura `findActiveNavItem(pathname, items)`: um item é a seção atual quando `pathname === href` ou `pathname.startsWith(href + '/')` (fronteira de segmento, nunca prefixo de texto: `/contentx` não casa `/content`); se mais de um casar, vence o de `href` mais longo; nenhum casa → `undefined` (sem destaque, FR-004). Sem I/O, sem React. Teste próprio cobre: as 3 rotas e as 4 subrotas de Conteúdos (AC-002), fronteira (`/content-x`, `/contents`), rota fora da lista (AC-003), item extra no array sem alterar código (AC-001), e a **amarração às rotas reais (R9)**: todo `href` da lista tem o 1º segmento em `INTERNAL_ROUTE_PREFIXES` e uma `page.tsx` correspondente em `src/app/(interno)/` (enumeração do diretório no molde de `proxy.test.ts`); inventário atual: cada prefixo de `INTERNAL_ROUTE_PREFIXES` tem item (quem criar rota interna sem item reabre o teste de propósito, e o faz declarando o motivo).
**Realiza**: FR-044-002, FR-044-003, FR-044-004
**Interface pública**: `INTERNAL_NAV_ITEMS`, `type InternalNavItem`, `findActiveNavItem(pathname: string, items?: readonly InternalNavItem[]): InternalNavItem | undefined`.
**Dependências**: nenhuma

### COMP-046-002: `InternalSidebar` (sidebar fixa e menu recolhível)
**Responsabilidade**: `src/components/internal-sidebar.tsx` (`'use client'`). Renderiza (a) o botão do menu — `type="button"`, texto visível "Menu", `aria-expanded`, `aria-controls` (id de `useId`), classe `xl:hidden` — e (b) `<nav aria-label="Navegação da área interna">` com `<ul>` de `<Link>` (100% links, nenhum "Sair", FR-014) vindos da prop `items` (default `INTERNAL_NAV_ITEMS`); o item da seção (`findActiveNavItem(usePathname(), items)`) recebe `aria-current="page"`, peso de fonte, `text-link` e barra à esquerda com `--link` (DEC-046-009); os demais não têm `aria-current`. **Visibilidade por CSS**: o painel (o `<nav>` e seu invólucro) fechado abaixo de `xl` é `hidden` (`display: none` — fora da ordem de Tab, sem cobrir nem empurrar, FR-010) e `xl:block` sempre; aberto abaixo de `xl` é `block` **no fluxo** (empurra o conteúdo para baixo; só o fechado é proibido de empurrar) com `surface-card`. **Estado**: `openPath: string | null` + `prevPathname` — quando `pathname` difere de `prevPathname` durante o render, zera `openPath` e atualiza `prevPathname` (ajuste de estado na mudança de prop, sem `useEffect`, FR-021); o menu está aberto **se e somente se** `openPath === pathname`, e A→B→A permanece fechado (DEC-046-006). **Fechamentos** (DEC-046-006): item clicado, `Escape`, `pointerdown` fora do painel e do botão, e `matchMedia('(min-width: 80rem)')` passando a casar — os três últimos via listeners registrados **só enquanto aberto** e removidos no cleanup; item, Esc e toque fora (os 3 meios de FR-044-009) devolvem o foco ao botão (`ref.focus()`); cruzar o breakpoint só fecha e o botão anuncia recolhido (o botão é `xl:hidden`, foco nele é no-op). Foco visível no padrão de `login/page.tsx:80` em botão e links. Cores só dos pares já provados (`--link`/`--text-strong`/`--text-muted`/`--border-subtle` sobre `--surface` e `--surface-raised`). Em `xl`+ o `<nav>` é a coluna de 14rem e não há controle de recolher (FR-007). Testes (RTL, mock de `next/navigation` com `usePathname`; matchMedia controlável): AC-001/002/003/008–012/015/021/022/024; ausências (`aria-current` nos demais, nenhum "Sair", botão ausente fora do pronto) com **controle positivo no mesmo `it`** (lição `assercao-de-ausencia-em-render-carrega-controle-positivo-no-mesmo-it`); fechado ⇒ painel com `hidden` e itens fora de `Tab` (`userEvent.tab`) com o controle positivo do aberto; foco de volta ao botão por cada um dos 3 meios de FR-044-009 (item, Esc, toque fora; cruzar o breakpoint só fecha); clique em link não bloqueado pelo handler de fechamento (evento `createEvent.click` + `defaultPrevented`, lição `espiao-de-useRouter-nao-observa-navegacao-de-next-link`, válido enquanto o render não monta `AppRouterContext`); inventário fechado do contêiner (lição `inventario-fechado-sobe-para-o-conteiner-que-ganhou-filho-interativo`): botão + N links, nenhum outro controle (`input, button, a, select, textarea`). Teste de fonte (molde de `globals-theme-contrast.test.ts`): as utilities de cor do componente são as do conjunto dos pares registrados em `night-palette-tokens.ts` (NFR-044-001) e o ajuste `xl` do painel coincide com o breakpoint da DEC-046-004.
**Realiza**: FR-044-002, FR-044-003, FR-044-004, FR-044-007, FR-044-008, FR-044-009, FR-044-010, FR-044-011, FR-044-014, FR-044-021, FR-044-022, FR-044-024, NFR-044-001, NFR-044-003
**Interface pública**: `<InternalSidebar items?: readonly InternalNavItem[] />`; sem outras props. `data-testid` só se o teste não achar por papel/nome.
**Dependências**: COMP-046-001

### COMP-046-003: `PageContainer` e remoção do container do `<main>` raiz
**Responsabilidade**: `src/components/page-container.tsx` (Server Component, só classes): `PageContainer({ variant = 'default' | 'wide', children })` com **classes literais constantes exportadas** — `default` = `mx-auto w-full max-w-5xl px-4 py-10 sm:px-6` (exatamente as de hoje do `<main>`), `wide` = `mx-auto w-full max-w-7xl px-4 py-18 sm:px-6` (`py-18` = 4,5rem = `py-10` do `<main>` + `py-8` da casca de hoje: o topo do conteúdo não muda). `src/app/layout.tsx`: o `<main>` passa a `className="w-full flex-1"` (perde `mx-auto max-w-5xl px-4 py-10 sm:px-6`); `src/app/page.tsx` (Home) e `src/app/not-found.tsx` (404 da raiz) passam a envolver o conteúdo em `<PageContainer>` (`default`); `/login` **não** ganha wrapper — seu conteúdo é `position: fixed; inset: 0` e não dependia do container. Header e footer mantêm os seus `max-w-5xl` (fora do diff). Testes: `layout.test.tsx` estendido (travessia da árvore, como hoje) — o `<main>` **não** tem `max-w-5xl`/`max-w-7xl`/`px-4`/`py-10` (mutante "container volta ao main" reprova); `page.test.tsx` e `not-found.test.tsx` — o conteúdo está dentro de um elemento com as classes `default` (constante compartilhada, controle positivo: `wide` é diferente); `not-found.integration.test.ts` segue verde (HTTP real, "Mnemônicos" no `<header>`, R4). Prova em tela (gate 9, nos dois temas, 360/768/1024/1280/1440): Home, login e 404 idênticas a antes (AC-044-019).
**Realiza**: FR-044-017, FR-044-018, FR-044-019, FR-044-027
**Interface pública**: `<PageContainer variant? children />`; constantes `PAGE_CONTAINER_CLASS`, `PAGE_CONTAINER_WIDE_CLASS`.
**Dependências**: nenhuma

### COMP-046-004: `InternalShell` com sidebar no estado pronto
**Responsabilidade**: `src/components/internal-shell.tsx` — a lógica de sessão/papel/pista (`useMeQuery`, `router.replace('/login')`, `setSessionHint`, `roleSatisfies`) **não muda**. Os estados carregando (`role="status"`), sem sessão (`null`) e sem permissão (`role="alert"`) continuam com a mesma marcação, agora dentro de `<PageContainer>` `default` (preserva o enquadramento de hoje: o `<main>` não tem mais container, DEC-046-003) e **sem** sidebar nem botão. O ramo pronto substitui `div.flex.min-h-full > div.mx-auto.max-w-5xl…` por `<PageContainer variant="wide">` contendo `<div className="flex flex-col gap-4 xl:grid xl:grid-cols-[14rem_minmax(0,1fr)] xl:gap-6">` com `<InternalSidebar />` e o `children` em `<div className="min-w-0">` (container único, FR-017; `min-w-0` impede que tabelas/ pré-formatado estourem o grid e causem rolagem horizontal a 360px, FR-027). Transição para fora do pronto (sessão cai, AC-023): o ramo pronto desmonta, levando sidebar e botão — inclusive com o menu aberto — e os listeners (cleanup); segue o `router.replace('/login')` de hoje. Testes (`internal-shell.test.tsx`, mock de `next/navigation` **com `usePathname`**, R1/R5): AC-004/005/006/023 (ausência de `nav` e do botão com controle positivo no pronto, mesmo `it`), AC-018 na parte de DOM (um único elemento com classe de container entre `<main>` simulado e o `children`; sem `max-w-5xl` aninhado), AC-006 "a sidebar não altera a autorização" (papel insuficiente → mensagem exata e nenhum conteúdo); `internal-shell` com `useMeQuery` real e sessão caindo com menu aberto (AC-023).
**Realiza**: FR-044-001, FR-044-005, FR-044-006, FR-044-017, FR-044-019, FR-044-023, FR-044-027, NFR-044-002
**Interface pública**: `<InternalShell requiredRole children />` (inalterada).
**Dependências**: COMP-046-002, COMP-046-003

### COMP-046-005: `SiteLogo` (destino do logo por sessão)
**Responsabilidade**: `src/components/site-logo.tsx` (`'use client'`), montado por `site-header.tsx` no lugar do `<Link href="/">` atual (o `<header>` segue com o texto `env.appName` dentro dele no SSR — R4). Lê `useMeSilentQuery()` (mesma assinatura e chave de cache do `AuthControl` → 0 GET extra, NFR-044-002/G17) e calcula o destino: `INTERNAL_HOME` **somente se** `!isLoading && !isUninitialized && data && roleSatisfies(data.role, INTERNAL_MIN_ROLE)`; em qualquer outro caso (carregando/indeterminado, sem sessão, `data.role` inesperado, STUDENT) `/`. Como `AuthControl` mostra "Sair" exatamente quando `data` existe e nada enquanto carrega, o logo nunca aponta para `/studio` com "Entrar" ou neutro (FR-025 por construção; teste de costura com os dois montados). SSR e primeira pintura: `href="/"`. `onClick` (clique simples, sem tecla modificadora): se o destino é `INTERNAL_HOME` **e** `!hasSessionHint()` (pista apagada — logout noutra aba), `preventDefault()` e `router.push('/')`; sem chamada de rede, sem listener novo, sem `homeSessionCheck` (DEC-046-008). Clique com Ctrl/Cmd/meio segue o `href`. Não toca `auth-control.tsx`. Testes: `site-logo.test.tsx`/`site-header.test.tsx` (mock de `@/store/api`: `data` ausente, carregando, `uninitialized`, STUDENT, EDITOR, ADMIN, `role` indefinido → `/`; EDITOR/ADMIN → `/studio`; AC-013/014/025), clique com pista ausente → `router.push('/')` e `href` intacto (AC-020; controle positivo: com pista → navegação por `href`, sem `push`), e `auth-control.integration.test.tsx`-molde com store real: logo + `AuthControl` montados, `/auth/me` chamado **uma vez** para os dois (G17). `home-session-gate.integration.test.tsx:556-563` segue com 0 conferências e 2 GET `/auth/me`; `site-header.test.tsx:90-93` (`getByRole('link')` singular) segue válido — o header continua com um só link.
**Realiza**: FR-044-012, FR-044-013, FR-044-020, FR-044-025, NFR-044-002
**Interface pública**: `<SiteLogo />` (sem props).
**Dependências**: nenhuma

### COMP-046-006: Volta ao conteúdo na Tira e links soltos preservados
**Responsabilidade**: `src/app/(interno)/content/[id]/tira/page.tsx` — o `<Link href="/content">Conteúdos brutos</Link>` (`:28`) passa a conviver, num `div` com `flex items-center gap-4`, **depois** de `<Link href={`/content/${id}`}>Voltar ao conteúdo</Link>` (ordem: "Voltar ao conteúdo" antes de "Conteúdos brutos", decisão do Tech Lead, gate 11 pode rever; sem `encodeURIComponent`, convenção do repo — ids são UUID; mesma classe `text-sm font-medium text-link underline`; foco visível pelo padrão do projeto). "Conteúdos brutos" segue apontando para `/content`. Os links soltos existentes (Painel→`/content/new`, lista→`/breakdown`, Quebra→Tira, Biblioteca→`/content/${id}`, "Novo conteúdo" em `content/page.tsx:20`) **não mudam de código**; ganham teste de regressão onde faltar (AC-016/017/026): a lista `/content` oferece "Novo conteúdo" → `/content/new` e a sidebar não o lista (inventário do COMP-046-001). Teste da página da Tira: os dois links lado a lado, destinos exatos, `id` do mesmo conteúdo (valor literal distinto de `content`).
**Realiza**: FR-044-015, FR-044-016, FR-044-026
**Interface pública**: nenhuma nova.
**Dependências**: nenhuma

### COMP-046-007: Emendas às suítes da SPEC-040/036 e provas de costura
**Responsabilidade**: manter NFR-044-004 (0 falhas nas suítes SPEC-040/036 com as emendas): (a) estender `tests/support/match-media.ts` com uma variante controlável (dispara `change`, expõe `matches` mutável) **sem alterar** `mockMatchMedia(matches)` existente (lição `helper-de-teste-que-nao-expoe-o-dado-se-estende-nunca-se-copia`); (b) `usePathname` é acrescentado aos 4 arquivos que montam `InternalShell` (`internal-shell.test.tsx`, `auth-control.integration.test.tsx`, `session-hint.integration.test.tsx`, `home-session-gate.integration.test.tsx`); os testes do header não precisam (o `SiteLogo` só usa `useRouter`); (c) a emenda de FR-040-009/AC-040-010 (A-044-002) entra como casos novos (TASK-046-002); não há teste existente a reescrever (só `site-header.test.tsx:87-93`, com `data: null`, que segue verdadeiro); os de 404 e de "Voltar para o início" do login ficam (R3); (d) G17 sem alteração de expectativa; (e) `layout.test.tsx` (R7): asserts de `:63-77` intactos, acréscimo do COMP-046-003; (f) rodar `proxy.test.ts`, `not-found.integration.test.ts` e `home.integration.test.ts` sem edição; `proxy.ts`, `internal-routes.ts`, `auth-control.tsx`, `api.ts` com diff vazio. Nenhum FR próprio: é a rede que prova os demais.
**Realiza**: NFR-044-004
**Interface pública**: nenhuma (suíte de teste).
**Dependências**: COMP-046-002, COMP-046-004, COMP-046-005, COMP-046-006

## 4. Fluxos principais

**F1 — Desktop (≥1280px), sessão pronta** (AC-001/002/008/012): `useMeQuery` confirma sessão e papel → ramo pronto monta `PageContainer wide` com grid `14rem | 1fr`; `<nav>` sempre visível, sem botão; `usePathname` → `findActiveNavItem` marca o item (`aria-current="page"`); Tab percorre os itens na ordem, com foco visível.

**F2 — Abaixo de 1280px** (AC-009/010/011/021/022): menu fechado (`hidden`), botão "Menu" `aria-expanded="false"`; acionar abre o painel no fluxo (`aria-expanded="true"`); item, Esc e `pointerdown` fora fecham e devolvem o foco ao botão; cruzar `min-width: 80rem` só fecha; troca de rota (voltar/avançar/link) fecha pelo reset de `openPath` quando `pathname` difere de `prevPathname` (A→B→A permanece fechado); ao voltar abaixo do breakpoint o botão anuncia "recolhido".

**F3 — Estados fora do pronto** (AC-004/005/006/023): carregando → `role="status"`; sem sessão → `router.replace('/login')` e `null`; sem permissão → `role="alert"`; sessão cai em uso → o ramo pronto desmonta (sidebar, botão e listeners saem, mesmo aberto) e segue ao login como hoje. Em todos, `PageContainer default`: enquadramento idêntico ao de hoje.

**F4 — Logo** (AC-013/014/025): SSR e indeterminado → `/`; `meSilent` resolve EDITOR/ADMIN → `/studio` e `AuthControl` mostra "Sair" na mesma renderização; visitante/STUDENT/falha → `/` e "Entrar"/neutro.

**F5 — Logout em outra aba** (AC-020): aba B faz logout e apaga a pista; na aba A (cache com `data`) o `href` ainda é `/studio`, mas o clique vê `hasSessionHint()` falso → `router.push('/')` → Home pública (SPEC-040 sem pista: sem conferência, sem login, sem aviso de sessão expirada). Zero chamadas de rede originadas pelo logo.

**F6 — Páginas públicas** (AC-007/019): Home, login e 404 não montam `InternalShell` nem sidebar; Home e 404 recebem `PageContainer default` (mesmas classes de antes), login segue `fixed inset-0`.

## 5. Modelo de dados

Sem mudança de banco, API, migração ou tipos de domínio. Estado novo: `openPath: string | null` em memória no `InternalSidebar` (não persistido). Dado novo: a lista declarada `INTERNAL_NAV_ITEMS` (constante de módulo, sem segredo). A pista `mnemonicos:session-hint` é apenas lida (`hasSessionHint`).

## 6. Decisões arquiteturais

### Decisões herdadas
- **DEC-046-010** [herdada] Stack vigente (Next 16 App Router, React 19, Tailwind 4 com tokens em `globals.css`, RTK Query, Jest 29 + Testing Library); Server Components por padrão e `'use client'` só onde há estado/evento; `makeStore()` função — fonte: perfil §4/§7 e README do guideline do frontend, CLAUDE.md do workspace
- **DEC-046-011** [herdada] Identificadores de código em inglês, texto de interface em pt-BR — fonte: CLAUDE.md do workspace
- **DEC-046-012** [herdada] `proxy.ts`, a guarda de rotas, `INTERNAL_ROUTE_PREFIXES` (fonte do matcher) e o backend permanecem inalterados; a sidebar é exibição, não autorização — fonte: INDEX DEC-003-011 / COMP-003-022 (PLAN-003), perfil §6.3, SPEC-044 NFR-044-002
- **DEC-046-013** [herdada] `me` e `meSilent` coexistem por finalidade (reauth/expulsão × leitura sem efeito colateral); o header consome `meSilent` — fonte: INDEX DEC-035-005 (PLAN-035)
- **DEC-046-014** [herdada] O logout vive só no `AuthControl` do header; a sidebar não tem "Sair" — fonte: INDEX DEC-035-006 (PLAN-035), SPEC-044 FR-044-014
- **DEC-046-015** [herdada] Sidebar fixa no desktop, menu recolhível como disclosure não modal, Volta ao conteúdo para `/content/[id]`, nenhum item filtrado por papel — fonte: SPEC-044 A-044-005
- **DEC-046-016** [herdada] Seção atual por igualdade ou prefixo em fronteira de segmento; rota sem item fica sem destaque — fonte: SPEC-044 A-044-007
- **DEC-046-017** [herdada] Sinal de "há sessão" é o do KAN-180 (`hasSessionHint` / `meSilent`); sem nova decisão de como saber que há sessão — fonte: SPEC-044 §4.2 e A-044-002, PLAN-041 DEC-041-002

### DEC-046-001: Sidebar montada no ramo "pronto" do `InternalShell`
**Contexto**: FR-005/023 exigem que a sidebar e o botão não existam em carregando, sem sessão e sem permissão, e sumam se a casca deixar o pronto em uso. O `InternalShell` já resolve os quatro estados (SPEC-002/PLAN-003) e é o único ponto que sabe deles.
**Decisão**: `InternalSidebar` é filha do ramo pronto de `InternalShell`; nenhum outro lugar a monta.
**Alternativas consideradas**:
- Montar no layout do grupo `(interno)/layout.tsx` ao lado do shell, descartada porque: o layout é Server Component e não conhece o estado da sessão — a sidebar apareceria em carregando/sem permissão (viola FR-005, AC-004/006) a menos que relesse `useMeQuery`, o que duplica a máquina de estados e abre uma segunda assinatura de sessão na área interna.
- `template.tsx` do grupo, descartada porque: remonta a cada navegação (perde o estado aberto/fechado e o foco) e continua sem conhecer a sessão.
- Montar no layout raiz por `usePathname`, descartada porque: acopla o enquadramento comum do app às rotas internas (mesma família da DEC-035-001: o que é da área interna mora na casca), e a sidebar apareceria antes do veredito de sessão.
**Consequências**: FR-005/023 valem por construção (o ramo não renderiza fora do pronto; a desmontagem leva os listeners). O teste da casca é o teste de ausência dos três estados. A sidebar re-renderiza a cada mudança de `useMeQuery`, sem custo relevante.
**Reabrir se**: a área interna ganhar um segundo layout (ex.: rotas internas com casca diferente) que precise da mesma sidebar.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-046-002: Lista de itens declarada, separada de `INTERNAL_ROUTE_PREFIXES`, amarrada por teste
**Contexto**: FR-002 exige acrescentar item sem reescrever o componente. `INTERNAL_ROUTE_PREFIXES` é a fonte do matcher do proxy (segmentos de 1º nível, sem rótulo, sem ordem de menu, sem sub-rotas); R9: lista e rotas reais podem divergir em silêncio.
**Decisão**: `INTERNAL_NAV_ITEMS` em `src/lib/internal-nav.ts` (rótulo + destino; a regra de seção é função pura que não conhece itens); `InternalSidebar` recebe os itens por prop com default. Um teste amarra a lista ao território: todo `href` tem 1º segmento em `INTERNAL_ROUTE_PREFIXES` e página real correspondente; o inventário atual exige um item por prefixo.
**Alternativas consideradas**:
- Derivar os itens de `INTERNAL_ROUTE_PREFIXES`, descartada porque: a lista do proxy não tem rótulo nem ordem, e `content/new`, `content/[id]`… são sub-rotas; acrescentar rótulos a ela mistura contrato de guarda com apresentação e expõe o matcher do proxy a edição por motivo de menu (DEC-003-011).
- Array literal dentro do componente (a mais simples), descartada porque: acrescentar item exige editar o componente (falha FR-002/AC-001) e o teste de amarração não teria um módulo próprio onde apontar.
**Consequências**: dois lugares a editar ao criar rota interna com item (prefixos e lista); o teste acusa o esquecimento nas duas direções relevantes (item → rota). Rota interna sem item é permitida (FR-004) e fica sem destaque.
**Reabrir se**: surgir item cujo acesso dependa de papel mais restrito (RISK-044-005) — a lista ganha o campo de papel e o filtro entra no escopo.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-046-003: Container sai do `<main>` raiz; quem o usa o declara (`PageContainer`)
**Contexto**: hoje o container (`mx-auto max-w-5xl px-4 py-10 sm:px-6`, `layout.tsx:41`) envolve toda página e a casca repete `max-w-5xl px-4 py-8 sm:px-6` (`internal-shell.tsx:77`): duplicidade (FR-017). Com sidebar de 14rem + gap de 1,5rem dentro de 1024px, o conteúdo a 1280px ficaria com 728px (< 928px de hoje, viola FR-019). A área interna precisa de um container mais largo que o do `<main>`, e as páginas públicas não podem mudar (FR-018). Login é `fixed inset-0` e não depende do container.
**Decisão**: o `<main>` raiz fica `w-full flex-1` (sem container). `PageContainer` (classes literais constantes) entrega `default` (as classes exatas de hoje do `<main>`) à Home, à 404 da raiz e aos estados não-prontos da casca, e `wide` (`max-w-7xl`, `py-18` = `py-10` + `py-8` de hoje) ao ramo pronto da casca. O container da casca é o único na área interna pronta. O desalinhamento com header e footer (ainda `max-w-5xl`) em ≥1280px é **consequência declarada**, a julgar no gate 11.
**Alternativas consideradas**:
- Manter o container no `<main>` e neutralizá-lo na área interna por seletor `:has([data-internal-shell])`/variante Tailwind, descartada porque: a duplicidade continua no código (dois containers, um anulando o outro), a prova só existe em navegador real (jsdom não avalia `:has` — AC-018 ficaria só no gate 9) e as páginas públicas seguem dependentes de uma exceção CSS global.
- Sidebar fora do container (na margem lateral), descartada porque: a margem a 1280px é (1280−1024)/2 = 128px, menor que os ~248px de sidebar + gap — só caberia a partir de ~1536px, e a faixa 1280–1535px (laptops) ficaria sem sidebar fixa, esvaziando o ganho da entrega.
- Só remover o container duplicado da casca e pôr a sidebar dentro de `max-w-5xl` (a mais simples), descartada porque: a 1280px o conteúdo mede 976−248 = 728px, abaixo dos 928px de hoje — viola FR-019/AC-018.
- Alargar o container de todas as páginas (inclusive públicas) para `max-w-7xl`, descartada porque: viola FR-018 (Home e 404 mudariam de largura e espaçamento).
**Consequências**: (a) mover a responsabilidade do container para as páginas é um contrato novo — **página pública futura** precisa envolver-se em `PageContainer`, senão sai sem margem; o teste do `<main>` (COMP-046-003) documenta isso; (b) o ramo pronto tem layout shift de largura no carregamento em ≥1024px (carregando em `default` → pronto em `wide`), sem efeito sobre a promessa de largura; (c) header/footer (1024px) ficam desalinhados do conteúdo de 1280px em ≥1280px; (d) `layout.tsx` muda só na classe do `<main>` (sem mexer no gate de `HIDDEN_ROUTES`). Risco alto declarado: TRISK-046-002.
**Reabrir se**: o gate 11 reprovar o desalinhamento com header/footer (então alargar o header/footer na área interna vira nova DEC), ou surgir terceira largura de container.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-046-004: Breakpoint da sidebar fixa em `xl` (1280px), sidebar de 14rem e container `max-w-7xl` — com a conta
**Contexto**: SPEC-044 A-044-008/FR-019 exigem largura útil do conteúdo ≥ a de hoje em 360, 768, 1024, 1280 e 1440px, e o PLAN mede e fixa o breakpoint. Hoje (medido por leitura das classes, `layout.tsx:41` + `internal-shell.tsx:77`, border-box): o `<main>` tem no máximo 1024px com `px-4` (<640px) ou `px-6` (≥640px), e a casca repete `max-w-5xl` + o mesmo padding dentro dele — conteúdo = vw − 64px até 640px, vw − 96px até 1024px, e 928px (= 1024 − 48 − 48) de 1024px em diante.
**Decisão**: breakpoint `xl` (80rem = 1280px); sidebar = coluna de 14rem (224px) + `gap-6` (24px); container da área interna pronta `max-w-7xl` (1280px) com `px-4 sm:px-6`. Conta (largura útil do conteúdo, sem barra de rolagem):

| Viewport | Hoje (conteúdo) | Novo container (caixa) | Sidebar + gap | Novo (conteúdo) | Δ |
|---|---|---|---|---|---|
| 360 | 360 − 32 − 32 = 296 | 360 − 32 = 328 | recolhível (0) | 328 | +32 |
| 768 | 768 − 48 − 48 = 672 | 768 − 48 = 720 | recolhível (0) | 720 | +48 |
| 1024 | 1024 − 48 − 48 = 928 | 1024 − 48 = 976 | recolhível (0) | 976 | +48 |
| 1280 | 928 | min(1280, 1280) − 48 = 1232 | 224 + 24 = 248 | 984 | +56 |
| 1440 | 928 | min(1440, 1280) − 48 = 1232 | 224 + 24 = 248 | 984 | +56 |

Menor largura com sidebar fixa = 1280px: a conta exige viewport ≥ 928 + 248 + 48 = 1224px, e `xl` é o primeiro breakpoint padrão do Tailwind acima disso. Folga no pior caso (1280px com barra de rolagem clássica de ~15px): 1265 − 48 − 248 = 969 ≥ 928 (+41px); a sidebar + gap só teria de crescer mais de ~289px para violar a promessa. Abaixo de 1280px o menu é recolhível e o conteúdo ocupa toda a caixa (≥ hoje estruturalmente: o novo container só perde os 48px/64px da duplicidade). A 360px: sem rolagem horizontal (FR-027) porque a caixa é 328px e o conteúdo tem `min-w-0`.
**Alternativas consideradas**:
- Sidebar fixa a partir de `lg` (1024px), o default `md`/`lg` do card, descartada porque: a 1024px o conteúdo mediria 1024 − 48 − 248 = 728px (< 928px) — viola FR-019 (é o motivo de A-044-008 ter substituído o `md`).
- Sidebar fixa só a partir de `2xl` (1536px), descartada porque: o conteúdo caberia folgadamente, mas 1280–1535px (faixa comum de laptop) ficaria com menu recolhível sem necessidade de largura.
- `max-w-6xl` (1152px) para o container, descartada porque: a 1280px o conteúdo mediria 1152 − 48 − 248 = 856px (< 928px).
- Valor arbitrário `max-w-[1224px]` (zero folga), descartada porque: valor mágico sem ganho: a 1280px com barra de rolagem o container já encolhe para o viewport e o piso de 928px só fecha com a folga de `max-w-7xl`.
**Consequências**: largura do conteúdo no desktop cresce (+56px); o breakpoint `xl` aparece em três lugares (grid da casca, visibilidade do painel, botão `xl:hidden`) e em uma constante de teste (`80rem` do `matchMedia` do COMP-046-002), provada coincidente por teste de fonte. Prova em tela nas 5 larguras no gate 9.
**Reabrir se**: a sidebar ganhar largura > ~289px (ou gap maior), o padding lateral mudar, ou a medição em tela nas 5 larguras divergir da conta.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-046-005: Menu recolhível como disclosure no fluxo, visibilidade por CSS, botão na casca
**Contexto**: FR-007..010 pedem sidebar fixa ≥ breakpoint e, abaixo, menu fechado por padrão que não cobre nem empurra nem expõe itens ao Tab. O SSR não conhece a largura da viewport; não há hook de breakpoint no projeto (só `matchMedia` de tema); o header a 360px já tem logo + (`ApiStatus` em dev) + tema + auth (AC-036-019).
**Decisão**: um só `<nav>` no DOM. Visibilidade por classes responsivas (`hidden xl:block` fechado; `block` aberto abaixo de `xl`; sempre visível em `xl`+), sem hook de media query. O painel aberto fica **no fluxo** (empurra o conteúdo; só o fechado é proibido de fazê-lo), `surface-card`. O botão "Menu" (`aria-expanded`, `aria-controls`, `xl:hidden`) fica **no topo da casca**, dentro do ramo pronto, e não no header.
**Alternativas consideradas**:
- Hook `useMediaQuery` que escolhe entre renderizar sidebar ou menu, descartada porque: o servidor não sabe a largura — SSR/hidratação com piscada ou divergência — e exige infra de `matchMedia` nova e mock em todos os testes da casca; CSS entrega o mesmo sem estado.
- Drawer modal (`<dialog>`/overlay com trap de foco e bloqueio de rolagem), descartada porque: a SPEC/A-044-005 fixa disclosure **não** modal; o modal traz trap de foco, scrim e scroll-lock (superfície de bug de foco que já gerou re-gate de design neste slug, RISK-044-001).
- Painel sobreposto (popover absoluto com `z-index`), descartada porque: cobre o conteúdo, exige camada/recorte e contraste sobre conteúdo arbitrário; o fluxo normal dispensa tudo isso.
- Botão no header, descartada porque: o header ganharia 4º/5º controle a 360px, e FR-024/AC-036-019 teriam de ser re-provados com `ApiStatus` em dev — risco sem ganho (mesma casca, mesmo estado "pronto").
**Consequências**: aberto, o menu empurra o conteúdo para baixo (aceito; gate 11 julga); fechado é `display: none` (fora de Tab e da árvore de acessibilidade, FR-010). O botão herda a ausência fora do pronto por construção (DEC-046-001). Teste por classes + comportamento (RTL não avalia media queries): o teste prova o estado `hidden`/`block` pelo atributo de classe e a ordem de Tab; o efeito real do breakpoint é provado em tela (gate 9/11).
**Reabrir se**: o gate 11 reprovar o painel empurrando o conteúdo (migrar para sobreposto, nova DEC), ou a SPEC passar a exigir modal.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-046-006: Fechamento por estado derivado da rota e listeners só enquanto aberto
**Contexto**: FR-009/021/022 pedem fechar por item, Esc, toque fora, troca de rota "por qualquer meio" (voltar/avançar incluídos) e cruzamento do breakpoint, com foco no botão; o CSS sozinho não fecha o estado ao cruzar `xl` (o menu reapareceria aberto ao voltar abaixo, contra AC-044-022).
**Decisão**: estado `openPath: string | null` + `prevPathname`; quando `pathname` difere de `prevPathname` durante o render, zera `openPath` e atualiza `prevPathname` (padrão de ajuste de estado na mudança de prop, sem `useEffect`, cobrindo voltar/avançar/link) — A→B→A permanece fechado; aberto ⇔ `openPath === pathname`. Listeners de `keydown` (Escape), `click` no document (alvo fora do painel e do botão — nunca `pointerdown`: com o painel no fluxo, fechar no down desloca o conteúdo antes do click e o toque se perde ou cai noutro alvo; ajuste pós-gate 11 da Wave 3) e `matchMedia('(min-width: 80rem)').change` são registrados por `useEffect` **apenas enquanto aberto** e removidos no cleanup; item clicado chama o mesmo fechamento. Todo fechamento por item, Esc ou toque fora (os 3 meios de FR-044-009) chama `buttonRef.current?.focus()`; o fechamento por cruzar o breakpoint não move foco (o botão é `xl:hidden`, foco nele é no-op).
**Alternativas consideradas**:
- `useEffect` que faz `setOpen(false)` ao mudar `pathname`, descartada porque: renderiza mais uma vez com o menu ainda aberto após a troca de rota (piscada) e deixa o estado "aberto" sobreviver a um render, o que o derivado evita de graça.
- Listeners permanentes (mesmo fechado), descartada porque: um listener global de `keydown`/`pointerdown` por aba sem função na maior parte do tempo (desktop nunca abre o menu) — e cada um precisa de guarda de "aberto" no handler.
- `<details>/<summary>` nativo (a mais simples), descartada porque: não fecha por Esc, toque fora nem troca de rota sem JS equivalente, e `aria-expanded` é controlado pelo navegador — sem o controle de foco de volta ao botão que FR-009 exige.
**Ajuste (2026-09-30, gate 11 da Wave 3 — furo no plano, Tech Lead)**: o foco volta ao botão só quando `document.activeElement` é `body`/nulo ou está no próprio componente (painel ou botão), nos 3 fechamentos (item, Esc, toque fora); se o usuário já levou o foco a outro controle (campo, link do conteúdo), o menu só fecha.
**Consequências**: `pointerdown` fora devolve o foco ao botão mesmo quando o toque foi em outro controle da página (o navegador então move o foco ao alvo tocado; aceito). Cruzar `xl` fecha via `change` do `matchMedia` (só enquanto aberto); o teste usa o `matchMedia` controlável do COMP-046-007. A troca de rota "por qualquer meio" fecha mesmo sem clique no menu (link na página, voltar), e o reset por `prevPathname` garante que voltar à rota em que o menu foi aberto (A→B→A) o mantém fechado.
**Reabrir se**: o App Router deixar de renderizar `usePathname` de forma síncrona com a troca de rota, ou o teste de foco em navegador real (gate 11) apontar foco perdido.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-046-007: O logo lê `meSilent` num client isolado (`SiteLogo`), sem reusar `homeSessionCheck`
**Contexto**: A-044-002 deixa ao PLAN qual leitor o header consome. FR-025 exige coerência com o que o `AuthControl` mostra; NFR-044-002 proíbe conferência/renovação/chamada nova originada pela resolução do destino (G17: `home-session-gate.integration.test.tsx:556-563`, 0 conferências, 2 GET `/auth/me`); `auth-control.tsx` não pode entrar no diff (BRIEF-045 o altera em outra sessão); o `<header>` precisa da marca "Mnemônicos" no SSR (R4, `not-found.integration.test.ts:120`).
**Decisão**: `SiteLogo` (`'use client'`, arquivo próprio importado por `site-header.tsx`) chama `useMeSilentQuery()` — mesma chave de cache do `AuthControl`, portanto **0 GET extra** — e decide o destino com `roleSatisfies(role, INTERNAL_MIN_ROLE)`; neutro/indeterminado/falha/STUDENT → `/`; SSR renderiza `href="/"` com o texto da marca.
**Alternativas consideradas**:
- Reusar `homeSessionCheck` (DEC-041-004 o cita como ponto de reúso do KAN-178), descartada porque: cada uso dispara `/auth/me` + possível `/auth/refresh` (renovação concorrente entre abas, TRISK-041-005) por montagem do header em toda página — viola NFR-044-002/G17 e multiplica o custo da SPEC-040 pelo app inteiro.
- Receber o destino por prop do `AuthControl`/alterar `auth-control.tsx`, descartada porque: força o diff em arquivo que outra sessão altera (TRISK-046-001) e acopla o logo ao controle de logout.
- Decidir no servidor por cookie, descartada porque: o cookie de renovação não chega ao `SiteHeader` (path restrito), e o cookie de acesso dura ~15 min — o destino erraria para quem só tem renovação (A-044-003 pede `/` nesse caso, mas o SSR dependeria de I/O novo sem ganho).
**Consequências**: a coerência logo×controle é por construção (mesma query); DEC-041-004 não ganha o consumidor que previa — o reúso do KAN-178 é `hasSessionHint` (DEC-046-008), não `homeSessionCheck`. O `SiteHeader` segue com um só `<a>`.
**Reabrir se**: o header precisar do papel além do destino do logo, ou o `AuthControl` mudar de leitor (DEC-035-005).
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-046-008: FR-044-020 (logout em outra aba) decidido no clique pela pista, sem rede
**Contexto**: na aba A, o cache de `meSilent` ainda tem `data` depois do logout na aba B; o `href` seria `/studio`, e `/studio` sem sessão cai em `/login?sessao=expirada` (`api.ts:809-810`) — FR-020/AC-020 exigem ir à Home pública, sem login nem aviso. A pista `mnemonicos:session-hint` é apagada no logout com sucesso (`api.ts:820`) e é o único sinal entre abas que não custa rede. Não há listener de `storage` no app.
**Decisão**: no clique simples do logo, se o destino é `INTERNAL_HOME` e `hasSessionHint()` é falso, `preventDefault()` + `router.push('/')`. Sem listener novo, sem refetch, sem `homeSessionCheck`.
**Alternativas consideradas**:
- Listener `storage` que atualiza o destino quando a pista some, descartada porque: é um listener permanente por aba com estado novo e teste de evento entre abas, e o `href` só muda depois do evento; o clique já resolve o caso com 1 leitura síncrona.
- Refetch de `meSilent` no foco da janela, descartada porque: um GET `/auth/me` a cada foco viola NFR-044-002/G17 (0 chamadas originadas pelo logo) e ainda deixaria a janela entre o logout e o foco.
- Conferência no clique por `homeSessionCheck`, descartada porque: rede + possível renovação por clique (TRISK-041-005) e o clique esperaria o teto de 3 s no pior caso.
**Consequências**: pista ausente com sessão viva (localStorage bloqueado/modo privado, ou storage limpo) faz o logo ir a `/` em vez de `/studio` — degradação declarada (TRISK-046-003), coerente com DEC-041-002/TRISK-041-002; clique com tecla modificadora ou botão do meio segue o `href` (nova aba → guarda → login, como hoje). A leitura do `localStorage` fica dentro do `try/catch` de `hasSessionHint` (exceção = sem pista).
**Reabrir se**: a degradação de storage bloqueado for observada como problema real, ou o backend expuser sinal de sessão entre abas.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-046-009: Destaque e foco reutilizam tokens existentes — sem token de cor novo
**Contexto**: NFR-044-001 exige AA nos dois temas "com os tokens da paleta atual, 0 cores fora dela"; a lição `par-de-cores-de-utility-entra-na-prova-de-contraste-da-paleta` exige que utility que compõe duas cores esteja em `night-palette-tokens.ts`.
**Decisão**: item ativo = `aria-current="page"` + peso de fonte + `text-link` (`--link`) + barra à esquerda `--link`; item inativo = `--text-strong`; hover = fundo `--surface-raised`; painel recolhível = `surface-card`; foco visível = `outline-(--link)` no padrão de `login/page.tsx:80`. Todos os pares já existem em `NIGHT_PALETTE_ROLE_VS_SURFACE_PAIRS` (`--link`/`--text-muted`/`--text-strong`/`--border-subtle` sobre `--surface` e `--surface-raised`), provados por `globals-theme-contrast.test.ts`. **`globals.css` e `night-palette-tokens.ts` ficam sem diff**; o teste de fonte do COMP-046-002 ata as classes do componente a pares registrados. O destaque não depende só de cor (peso + barra + `aria-current`).
**Alternativas consideradas**:
- Token novo `--nav-active` (e par no contrato), descartada porque: duplicaria `--link` sem valor novo e abriria uma terceira fonte de cor no `@theme`, além de tocar `globals.css` (sem necessidade).
- Destacar só pelo fundo `--surface-raised`, descartada porque: no tema escuro `--surface-raised` (#241834) contra `--surface` (#0a070f) mede ~1,1:1 — o destaque só por fundo seria invisível (e o critério 3:1 de componente não fecharia).
**Consequências**: mudança futura de `--link` ou `--surface-raised` é vigiada pelos testes de contraste existentes; se um token novo vier, entra no contrato no mesmo diff.
**Reabrir se**: o gate 11 pedir destaque mais forte que a paleta atual permite.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

## 8. Riscos técnicos

- **TRISK-046-001** Colisão com o BRIEF-045 (outra sessão altera `auth-control.tsx`) (severidade: média; mitigação: `auth-control.tsx` fora do diff deste PLAN — o logo é `SiteLogo` próprio e só importa `useMeSilentQuery`; `site-header.tsx` é tocado só na troca do `<Link>` do logo pelo `<SiteLogo />`; rebase/merge após o BRIEF-045 e reexecutar as suítes do header e de `auth-control.integration.test.tsx`; conferir `git diff --stat` antes do fecho).
- **TRISK-046-002** Tirar o container do `<main>` raiz afeta as páginas públicas e cria contrato novo para páginas futuras (severidade: **alta**; mitigação: `PageContainer default` com as classes exatas de hoje e constante compartilhada; `layout.test.tsx` prova o `<main>` sem container e `page`/`not-found` provam o wrapper (R6/R7); `not-found.integration.test.ts` e `home.integration.test.ts` verdes sem edição; prova em tela nos dois temas e nas 5 larguras para Home, login e 404 (AC-044-019, gate 9); aviso na docstring do `PageContainer` de que página pública nova precisa envolver-se).
- **TRISK-046-003** Pista ausente com sessão viva (storage bloqueado, modo privado, storage limpo) faz o logo ir a `/` em vez de `/studio` (DEC-046-008) (severidade: baixa; mitigação: a pista é regravada ao passar pela área interna (`InternalShell`) e no login; risco declarado ao PO na aceitação; reabrir a DEC se observado).
- **TRISK-046-004** Disclosure: foco, Esc, toque fora e cruzar o breakpoint já geraram re-gate de design neste slug (RISK-044-001) e o `matchMedia`/CSS responsivo não se provam em jsdom (severidade: **alta**; mitigação: testes por comportamento nos meios de fechamento (3 com foco de volta + cruzar o breakpoint, que só fecha) e na ordem de Tab com controle positivo; `matchMedia` controlável; o efeito dos breakpoints provado em tela no gate 9 (desktop e celular) e julgado no gate 11).
- **TRISK-046-005** Desalinhamento entre header/footer (1024px) e o conteúdo/sidebar (1280px) em ≥1280px (DEC-046-003) (severidade: média; mitigação: registrado como consequência a julgar no gate 11 com captura em 1280 e 1440; a reabertura alarga header/footer na área interna por DEC nova, sem tocar as páginas públicas).
- **TRISK-046-006** Testes existentes quebram por mock de `next/navigation` sem `usePathname`, `getByRole('link')` singular e testes de logo da SPEC-040 (R1/R2/R5) (severidade: média; mitigação: COMP-046-007 lista e corrige os mocks no mesmo diff; G17 sem mudança de expectativa; rodar a suíte inteira antes do fecho (NFR-044-004)).
- **TRISK-046-007** O estado "sem permissão" (AC-044-006) não tem prova em tela por falta de conta sem o papel (A-044-006/010), e o HANDOFF-PLAN-041 segue aberto com o logo alterado (severidade: média; mitigação: a prova é automatizada no COMP-046-004; a prova em tela fica em handoff com a entrega declarada PARCIAL nesse ponto; o handoff existente ganha nota de que o logo com sessão mudou e que V6/V8 seguem válidos).

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Aderência à ficha/perfil validada
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates)
- [ ] `backend`, `proxy.ts`, `internal-routes.ts`, `auth-control.tsx`, `api.ts`, `app-chrome-gate.tsx`, `globals.css` e `night-palette-tokens.ts` com diff vazio; `proxy.test.ts`, `not-found.integration.test.ts`, `home.integration.test.ts` e G17 verdes sem edição
- [ ] Conta de largura da DEC-046-004 conferida em tela nas 5 larguras (360/768/1024/1280/1440) nos dois temas, com Home, login e 404 idênticas a antes (AC-044-018/019, gate 9)
- [ ] Métrica da SPEC operacional (§1.3, fonte de medição externa): alcançabilidade em ≤2 interações de toda rota interna do escopo (Painel, Conteúdos, Biblioteca visual) provada por teste automatizado e por caminhada em tela do gate 9 (desktop e celular), 0 falhas nas suítes SPEC-040/036 com as emendas aplicadas, largura útil ≥ a de antes nas 5 larguras (dono do número: Tech Lead do ciclo); prova em tela do estado "sem permissão" em handoff (A-044-010)

## 10. Não coberto por este PLAN

- Nenhum FR/NFR da SPEC-044 fica de fora (cobertura 100%).
- Fora de escopo herdado da SPEC (§4.2): itens Tiras/Revisão/Exportações/Configurações, "Novo conteúdo" como item de menu, renomear "Conteúdos brutos", logout na sidebar, mudança de login/logout/guarda/autorização/backend, sidebar recolhível em largura fixa, filtro de itens por papel (RISK-044-005), `/login` com sessão ativa redirecionando, sidebar nas páginas públicas.
- Fora do diff por decisão deste PLAN: alargar header/footer (TRISK-046-005), token de cor novo (DEC-046-009), reúso de `homeSessionCheck` (DEC-046-007), a cópia duplicada `tests/components/site-header.test.tsx` só recebe o ajuste de mock (limpeza da duplicata é fora de escopo).
