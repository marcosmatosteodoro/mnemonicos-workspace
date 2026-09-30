# TASK-046-003: Volta ao conteúdo na Tira mnemônica e links soltos preservados

**Slug**: producao-material
**Pertence a**: PLAN-046
**Realiza (FRs)**: FR-044-015, FR-044-016, FR-044-026
**Componente**: COMP-046-006
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

Quem está na Tira mnemônica ganha o link "Voltar ao conteúdo", que leva à página do mesmo conteúdo (`/content/[id]`), ao lado do link existente "Conteúdos brutos" (que segue apontando para `/content`); os links soltos que já ligam as páginas internas e o acesso a "Novo conteúdo bruto" a partir da lista ficam preservados e provados. Território: PLAN-046 COMP-046-006, memo de exploração (item 4, links soltos com âncora de código) e `MAP.md` — citados, não copiados.

## Escopo

### Inclui
- `src/app/(interno)/content/[id]/tira/page.tsx` — o `<Link href="/content">Conteúdos brutos</Link>` (`:28`) passa a conviver com `<Link href={`/content/${id}`}>Voltar ao conteúdo</Link>` (sem `encodeURIComponent`: convenção do repo, os links `/content/${…}` não codificam e os ids são UUID) num `div` interno `flex items-center gap-4` que contém os dois links, **nessa ordem** — "Voltar ao conteúdo" **antes** de "Conteúdos brutos" (decisão do Tech Lead; gate 11 pode rever) —, dentro do `justify-between` existente; estrutura exata: `h1` + esse `div` interno (mesma classe `text-sm font-medium text-link underline`, o padrão do link de hoje; foco visível é o do `next/link` do projeto, sem classe nova, em cada link). "Conteúdos brutos" segue com `href="/content"`. O `<h1>` e o `MnemonicStripBoard` ficam como estão.
- `src/components/mnemonic-strip-board.test.tsx` — o `describe` existente "TiraPage — cabeçalho da página" (`:696-708`, que já monta `TiraPage` de verdade com `await TiraPage({ params })`) ganha os casos do link novo.
- `src/app/(interno)/content/page.test.tsx` — acréscimo do destino do link "Novo conteúdo bruto" (hoje os 3 casos só **contam** os links por nome, não leem o `href`).

### Não inclui
- Os links soltos existentes — Painel → `/content/new` (`strategic-panel-board.tsx`, só no estado vazio), lista → `/breakdown` (`content-list.tsx:99`), Quebra → Tira (`rule-breakdown-form.tsx:241`), Biblioteca → `/content/${id}` (`visual-library-board.tsx:568`) e "Novo conteúdo bruto" (`content/page.tsx:20`): **não mudam de código**; só ganham a prova citada abaixo.
- Renomear "Conteúdos brutos" ou acrescentar "Novo conteúdo" à sidebar (fora de escopo da SPEC).
- A parte "a sidebar não lista 'Novo conteúdo'" do AC-044-017: TASK-046-004 (inventário fechado da lista de itens).
- A faceta de suítes inteiras da SPEC-040/036 do AC-044-026: TASK-046-005 (última a fechar o ciclo).
- `encodeURIComponent` em qualquer link: não é usado (convenção do repo; ids são UUID).

## Critérios de pronto

Convenção dos comandos: executados na raiz do repositório `mnemonicos-frontend` (branch `feat/producao-material-sidebar-navegacao`; `npm test` = `jest`), caminhos relativos a ela; arquivo com `(interno)`/`[id]` no caminho só por `--runTestsByPath` entre aspas (o argumento posicional do jest é regex e não casa parênteses literais). Commit-base = `f7760a2` (= `origin/main` na redação, lido de `.git/refs/remotes/origin/main`); ausência ancorada com `git diff origin/main...HEAD`. **Fixação**: a redação (scribe, sem shell) conferiu alvos por Read/Grep — contagens de `it(` são **estáticas**; os comandos são **executados pelo Tech Lead na fixação**, com a saída literal registrada aqui antes do despacho; o developer reconfirma as baselines antes do primeiro edit. Teste de gate 1 roda pelo comando do critério (arquivo inteiro, nunca `-t`). Mutante = `git worktree add ../wt-mut-046-003 HEAD` com `node_modules` ligado ao da árvore principal, nunca `npm install`/`npm ci`; ao fim `git worktree remove` e `git status --porcelain` vazio (lição `sonda-de-investiga-o-n-o-nasce-em-tests-contagem-de-teste-declara-a-rvore`); cada mutante com controle negativo (sem mutante, mesmo comando → verde, mesma contagem).

- [ ] **Baseline dos arquivos de teste tocados, capturada antes do código** — `npm test -- --runTestsByPath src/components/mnemonic-strip-board.test.tsx "src/app/(interno)/content/page.test.tsx"` no commit-base → `Tests: 56 passed, 56 total`, 0 failed (estático: 53 + 3; confirmar na fixação). Fecho: o mesmo comando → `Tests: 60 passed, 60 total` (56 + 3 de `mnemonic-strip-board.test.tsx` + 1 de `content/page.test.tsx`), 0 failed. Valor observável preservado, declarado: o `<h1>` `Tira mnemônica` e o link `Conteúdos brutos` com `href="/content"` (`:697-707`), e os 3 casos de "uma só ação primária" de `ContentPage` + `ContentList` (1 link "Novo conteúdo bruto" em vazio, com itens e em erro).
- [ ] **Volta ao conteúdo na Tira (AC-044-016 — faceta de unidade; a faceta real é o passo 1 do Roteiro)** — `npm test -- --runTestsByPath src/components/mnemonic-strip-board.test.tsx` → `Tests: 57 passed, 57 total`, com 3 casos novos no `describe` do cabeçalho da `TiraPage` (monta `await TiraPage({ params: Promise.resolve({ id }) })` sob `<Provider store={makeStore()}>`, como o caso de `:697`): **V1** com `id = RAW_CONTENT_ID` (`'rc-1'`, `:31`), `getByRole('link', { name: 'Voltar ao conteúdo' })` tem `href` exatamente `/content/rc-1` **e** `getByRole('link', { name: 'Conteúdos brutos' })` segue com `href` exatamente `/content` (valor literal, um a um: `/content/rc-1` ≠ `/content`) · **V2** ordem e contiguidade ("ao lado"): os dois links têm o **mesmo pai** (o `div` interno `flex items-center gap-4`, filho do `justify-between` ao lado do `h1`), "Voltar ao conteúdo" vem **antes** de "Conteúdos brutos" e não há irmão entre eles (comparação por `parentElement` e `childNodes` do pai, não por `firstElementChild`; gate 11 pode rever a ordem) · **V3** com `id = 'rc-2'` o `href` do "Voltar ao conteúdo" é `/content/rc-2` (dois ids distintos provam que o destino vem da rota, não de constante). Mutantes: **K1** remover o link novo → V1/V2 reprovam; **K2** `href="/content"` no link novo → V1/V3 reprovam; **K3** `id` fixo `rc-1` no `href` → V3 reprova; **K4** "Conteúdos brutos" passa a `/content/${id}` → V1 reprova (o link existente não foi tocado).
- [ ] **"Novo conteúdo bruto" acessível a partir da lista (AC-044-017 — parte do acesso; a parte "a sidebar não o lista" é da TASK-046-004)** — `npm test -- --runTestsByPath "src/app/(interno)/content/page.test.tsx"` → `Tests: 4 passed, 4 total` (3 + 1): **A1** com a lista `ContentPage` + `ContentList` montada (mesmo `mount()` do arquivo, estado com itens), `getByRole('link', { name: /novo conteúdo bruto/i })` tem `href` exatamente `/content/new` (hoje os casos do arquivo contam o link, mas nenhum lê o destino — prova pré-existente lida no eixo do predicado: `getAllByRole('link', { name })` + `toHaveLength(1)` prova presença e unicidade, não o `href`). Mutante **K5** (worktree): trocar o `href` de `content/page.tsx:20` por `/content/newx` → A1 reprova (os 3 casos existentes seguem verdes — o teste novo é o que distingue); **K6**: remover o `<Link>` → A1 e os 3 existentes reprovam.
- [ ] **Links soltos preservados (AC-044-026 — parte dos links soltos; a parte das suítes inteiras da SPEC-040/036 é da TASK-046-005)** — sem editar código nem teste deles: `npm test -- --runTestsByPath src/components/strategic-panel-board.test.tsx src/components/content-list.test.tsx src/components/rule-breakdown-form.test.tsx src/components/visual-library-board.test.tsx` → 0 failed, contagem igual à baseline capturada antes do primeiro edit (fixação executada: **56** testes — 53 `it(` estáticos mais a expansão dos `it.each`, em `visual-library-board.test.tsx`). As provas pré-existentes, lidas no eixo do predicado (o `href` que cada asserção compara): Painel → `/content/new` — `strategic-panel-board.test.tsx:436-438` (estado vazio global; o Painel só oferece o link nesse estado, `strategic-panel-board.tsx:72-79`) e Painel → `/content/c-1` — `:424`; lista → Quebra — `content-list.test.tsx:161-172` (3 itens, `href` com o id de cada um: `/content/c-3|c-2|c-1/breakdown`) e lista → conteúdo — `:186-194`; Quebra → Tira — `rule-breakdown-form.test.tsx:352-358` (`/content/<CONTENT_ID>/tira`, só com Quebra salva) e Quebra → conteúdo — `:343-348`; Biblioteca → conteúdo — `visual-library-board.test.tsx:512-533` (`/content/rc-1` e `/content/rc-2`; `visual-library-board.tsx:568` é o único `Link` para `/content/${…}` do arquivo, e a asserção vive no estado de conflito de remoção). Código de produção dos links intocado: `git diff --stat origin/main...HEAD -- src/components/strategic-panel-board.tsx src/components/content-list.tsx src/components/rule-breakdown-form.tsx src/components/visual-library-board.tsx "src/app/(interno)/content/page.tsx"` → saída vazia (ausência; vazia também no commit-pai; alvo não-vazio: `git diff --stat origin/main...HEAD` lista `tira/page.tsx`). Mutante **K7** (worktree): trocar o `href` de `rule-breakdown-form.tsx:241` para `/content/${contentId}/tiras` → `rule-breakdown-form.test.tsx` reprova (prova que a rede pré-existente morre quando o link muda).
- [ ] **Linha de cabeçalho da Tira quebra sem partir rótulo a 360px (herdado do gate 11, Wave 1 — pai: AC-044-018 "no celular não há rolagem horizontal" + composição do COMP-046-006; lição `linha-flex-de-titulo-e-acoes-soma-larguras-contra-328px`)** — a linha externa de `src/app/(interno)/content/[id]/tira/page.tsx` é `flex flex-wrap items-center justify-between gap-4` (molde: `strategic-panel-board.tsx:182`); `npm test -- --runTestsByPath src/components/mnemonic-strip-board.test.tsx` → 0 failed, com caso novo que lê os tokens da linha externa pelo helper `tests/support/class-tokens.ts` e exige `flex-wrap` (e controle positivo: o `div` interno dos dois links segue com `flex items-center gap-4`). Mutante (worktree): remover `flex-wrap` da linha externa → o caso novo reprova; o controle segue verde. A prova em tela a 360px (h1 na linha 1, os dois links inteiros na linha 2) é do passo 1 do Roteiro do gate 9.
- [ ] **Arquivos fora do diff (contrato congelado do PLAN)** — `git diff --stat origin/main...HEAD -- src/components/auth-control.tsx src/store/api.ts src/proxy.ts src/lib/internal-routes.ts src/components/app-chrome-gate.tsx src/app/globals.css src/app/night-palette-tokens.ts` → saída vazia (ausência; vazia também no commit-pai `f7760a2`; alvo não-vazio: `git diff --stat origin/main...HEAD` lista os arquivos do Inclui). Mutante **K8** (worktree): acrescentar uma linha a `src/components/auth-control.tsx` → o comando lista o arquivo. `git diff --name-only origin/main...HEAD | grep -vE '^(src|tests)/'` → saída vazia (nenhum `package.json`/config).
- [ ] **Suíte inteira** — baseline: `npm test` no commit-base, registrada antes do primeiro edit (`Test Suites: N passed`, `Tests: M passed`, 0 failed); fecho: `npm test` → 0 failed, `Tests: M + 4 passed`, mesmas suítes.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (produção e teste) — `npx eslint --max-warnings=0 $(git diff --name-only --diff-filter=d origin/main...HEAD | grep -E '\.(ts|tsx)$')` → exit 0; `npm run typecheck` → exit 0; `npx prettier --check $(git diff --name-only --diff-filter=d origin/main...HEAD)` → exit 0; `npm run lint` → exit 0.

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente** (URLs digitáveis; `next dev`):
- Frontend: `http://localhost:3000` (`npm --prefix mnemonicos-frontend run dev`, branch `feat/producao-material-sidebar-navegacao`). Backend: `http://localhost:3333/api/v1` (`npm --prefix mnemonicos-backend run dev`), Postgres `mnemonicos-db`. Porta fora de `3000` exige a origem nova em `CORS_ORIGINS` do `.env` do backend **antes** (lição `cors-origins-de-origem-nica-quebra-silenciosamente-o-padr-o-de-porta-alternativa-entre-sess-es-paralelas`, em observação); ambos os `.env` são locais não versionados: declarar no fecho o que mudou.
- **O que mudou desde os registros**: o HANDOFF-PLAN-036 registrou Docker Desktop fora do ar (`app_fora_do_ar`) — registro datado; o HANDOFF-PLAN-041 (2026-09-30) subiu o ambiente completo. A sonda decide: `GET http://localhost:3000/login` → 200, `GET http://localhost:3333/api/v1/health` → 200 e uma rota ainda não visitada (a própria Tira, depois do login — lição `turbopack-root-ausente-…`). Falhou → handoff `app_fora_do_ar`, nunca "verificado por herança"; entrega PARCIAL nesta TASK.
- Navegador: Playwright (skill `screen-verify`), artefatos em `thoughts/screen-verify/`.

**Sujeito concreto**: realm `editor` (EDITOR) de `keelson.local.json › screenVerify.realms` — o HANDOFF-PLAN-041 §3 registra o realm `editor` = EDITOR do seed com login conferido por POST real (2026-09-30); credenciais só lá, **nunca copiar valores**. **Receita de login** (registrar qual caminho foi usado): (1) pela UI de `/login`; (2) se a digitação for negada (HANDOFF-PLAN-031, `permissao_ambiente`), `POST http://localhost:3000/api/v1/auth/login` por `context.request` (corpo lido do arquivo, `Origin: http://localhost:3000`), que compartilha o cookie jar; depois `goto('http://localhost:3000/studio')` uma vez para o app gravar a pista.

**Pré-condição**: o **id de conteúdo** é o UUID nulo `00000000-0000-4000-8000-000000000000` (inexistente) — a página da Tira renderiza o cabeçalho e os links independentemente do dado, e abrir a Tira de um conteúdo **real** dispararia a geração dos Quadros (`POST`), uma escrita no banco de dev que o roteiro não precisa e não faz. A prova é a URL e os links, não o dado. Nada a restaurar além do contexto.

**Passos (um por AC de gate 9)**:

1. **AC-044-016 (faceta real) — "Voltar ao conteúdo" leva ao mesmo conteúdo** (realm `editor`). Em `http://localhost:3000/content/00000000-0000-4000-8000-000000000000/tira`: os links "Conteúdos brutos" (`href` `/content`) e "Voltar ao conteúdo" estão visíveis **lado a lado** (mesma linha, medida a **1280 e 1440px**: os `getBoundingClientRect().top` diferem menos que a altura de uma linha); a **360px** só "sem sobreposição e sem rolagem horizontal" (os links podem quebrar de linha): os dois visíveis, sem sobreposição entre eles nem com o `<h1>`, e `document.documentElement.scrollWidth <= window.innerWidth` (FR-044-027 — se a linha estourar, o gate 11 decide entre `flex-wrap` e outro arranjo, volta ao Tech Lead); clicar "Voltar ao conteúdo". Esperado: URL final `http://localhost:3000/content/00000000-0000-4000-8000-000000000000` (o mesmo id), sem passar por `/login`; o erro inline de conteúdo inexistente dentro da casca é esperado e não reprova (a prova é a navegação).

**Restauração**: fechar o contexto do Playwright; `context.clearCookies()`; `localStorage.clear()` da origem; encerrar o `next dev` e o backend que a execução subiu.

## Riscos específicos

- **Linha do cabeçalho a 360px**: `h1` + dois links numa linha `flex` sem `flex-wrap` pode estourar a largura (FR-044-027) — o passo 1 mede a 360px; `flex-wrap` é ajuste permitido se a medida exigir (gate 11).
- **Ordem dos dois links** ("Voltar ao conteúdo" antes de "Conteúdos brutos") é decisão do Tech Lead, afirmada por V2; gate 11 pode rever.
- **Sem `encodeURIComponent`**: o `href` segue a convenção dos demais links do `src/` (`/content/${id}`; ids são UUID) — alinhado ao PLAN-046 v0.2.
- Gates: gate 8 **n/a** (link de navegação entre páginas internas já guardadas; sem sessão, papel, cookie ou dado de cliente novo); gate 11 aplica (link novo na página, 360px, foco visível); gate 10 **n/a** (nenhuma consulta ou lista nova).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-30T18:34:24-0300
**Data conclusão**: 2026-09-30T18:49:44-03:00
**Commit SHA**: d448ca5, 583049a (retry gate 11) (mnemonicos-frontend, branch feat/producao-material-sidebar-navegacao)
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
