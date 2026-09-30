# TASK-041-004: Provar por HTTP real a home pública intacta, a guarda e o manifesto

**Slug**: producao-material
**Pertence a**: PLAN-041
**Realiza (FRs)**: FR-040-014, FR-040-015, FR-040-016
**Componente**: COMP-041-005 (principal)
**Wave**: 4
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Todo

## Dependências

- **Depende de**: TASK-041-003
- **Bloqueia**: nenhuma

## Contexto

Com a página inicial decidindo pela sessão no navegador, a promessa do lado do servidor precisa ficar presa por um oráculo que passe pelo **build real**: `/` segue estática e servida a quem não executa script (robô, prévia de link, script desabilitado) com o mesmo conteúdo, título e descrição de antes; a guarda de rotas internas continua devolvendo 307 a `/login?next=…` e nunca passa a cobrir `/`; o manifesto do app instalado continua partindo de `/`. Só teste e prova — nenhum arquivo de produção muda. Território: memo de exploração (itens 1, 3 e 6), `MAP.md` do slug e DEC-041-001/-006 do PLAN-041.

## Escopo

### Inclui
- `mnemonicos-frontend/src/app/home.integration.test.ts` (novo; molde: `src/app/not-found.integration.test.ts` — `@jest-environment node`, `next build` + `next start -p 0 -H 127.0.0.1` via `node <bin do next>`, `jest.setTimeout` dedicado, helpers locais de espera de porta; o `fetch` com `redirect: 'manual'` é **prescrição desta TASK** — o molde não o usa, só injeta o cookie `mnemo_access` em `not-found.integration.test.ts:127-131`). Nome e sufixo conferidos contra o molde irmão do mesmo diretório (`not-found.integration.test.ts`) e o perfil §3 (`<alvo>.test.ts`); sem prefixo de design system.
- **(Furo no plano, sancionado pelo Tech Lead em 2026-09-30, decisão 4.258)** `mnemonicos-frontend/test/next-build-lock.ts` (novo) — trava entre processos (criação atômica de diretório de lock em `os.tmpdir()`, chave derivada do `process.cwd()`; lock com dono por PID e recuperação de lock órfão de processo morto) adquirida no `beforeAll` **antes** do `next build` e liberada no `afterAll` **depois** de matar o `next start`, usada por **`src/app/home.integration.test.ts` e `src/app/not-found.integration.test.ts`** (este último só ganha acquire/release; asserções intocadas). Motivo: os dois arquivos fazem `next build` no mesmo `.next` e, com os workers paralelos default do Jest (comando `quality.test` da ficha), disputam o build — suíte completa medida vermelha e instável (3 e 11 falhas em 2 rodadas; baseline b729a76 verde).

### Não inclui
- Qualquer arquivo de produção (`src/app/page.tsx`, `layout.tsx`, `globals.css`, `proxy.ts`, `manifest.ts`, componentes e store) e `src/proxy.test.ts`/`src/app/manifest.test.ts` — **sem edição**: rodam como estão e são parte da prova.
- O comportamento no navegador (estado neutro, ida, teto, bfcache): TASK-041-003 (gate 1 e Roteiro do gate 9).
- Medição do p95 da conferência em produção (A-040-010): item de DoD pós-deploy do PLAN-041, do Diretor.

## Critérios de pronto

Convenção dos comandos: executados na raiz do repositório `mnemonicos-frontend` (o worktree da branch; `npm test` = `jest`), caminhos relativos a ela (`mnemonicos-frontend/src/x` do Inclui = `src/x`). Base de comparação = commit-base `b729a76`. Fixação: o molde `src/app/not-found.integration.test.ts` foi lido por inteiro (helpers, `-H 127.0.0.1`, cookie injetado nas linhas 127–131); as contagens de baseline foram **executadas** pelo Tech Lead em b729a76 (`thoughts/local/sessions/20260930-132831-a408a37d/fixacao-TASK-041.md`, Tech Lead, 2026-09-30): `npx jest src/proxy.test.ts` = 55 passed (a contagem por `it(` diverge por causa de `it.each`; vale a executada), proxy + manifest = 60, proxy + manifest + `not-found.integration` = 63. Literais de título/descrição foram conferidos contra `src/app/layout.tsx:16-21` do commit-base (não contra a prosa da SPEC/PLAN).

- [ ] **Baseline capturada antes do código** — `npm test -- src/proxy.test.ts src/app/manifest.test.ts src/app/not-found.integration.test.ts` no commit-base → `Test Suites: 3 passed, 3 total`, `Tests: 63 passed, 63 total`, 0 failed (55 + 5 + 3: 60 de proxy+manifest medidos pelo Tech Lead; a suíte HTTP real leva ~1–5 min por causa do `next build`). Fecho: o mesmo comando depois do código → o **mesmo** 63. O developer reconfirma antes do primeiro edit e prova que o molde roda neste worktree (sem `.env`, `node_modules` por symlink) **antes** de copiá-lo: se o build exigir variável de ambiente ausente, registrar e parar (vai a `duvidas` do implement, nunca se inventa valor).
- [ ] **Home pública servida sem script — AC-040-021, AC-040-022 e FR-040-016** — `npm test -- src/app/home.integration.test.ts` → `Tests: 11 passed, 11 total` (H1–H9 abaixo; H7 são 3 casos); **H1** `GET /` sem cookie (`redirect: 'manual'`) → status 200 **e** `Cache-Control` sem `no-store` nem `private` (página estática; o valor real de `GET /` é capturado no commit-base antes de fixar a asserção — amostra capturada, não suposta) · **H2** o HTML traz `<h1 …>Memorizar não é repetir: é codificar.</h1>` (regex estrutural sobre a tag, nunca `toContain` de texto solto — o mesmo texto aparece no payload RSC de qualquer rota; lição sobre `toContain` de corpo em teste HTTP do App Router: quem discrimina a rota resolvida é a tag/`<title>`) e o `<h2 …>Técnicas do acervo</h2>` · **H3** `<title>` exatamente `Mnemônicos — material de alta retenção para concursos` (valor de `layout.tsx:17` com `env.appName` = `Mnemônicos` por default de `src/lib/env.ts:6`; o teste deriva o título de `env.appName` importado, não de literal duplicado, e o valor concreto é o do commit-base) · **H4** `<meta name="description" content="Mnemônicos, flashcards e revisão espaçada para memorizar listas, prazos e classificações de concurso público.">` (texto de `layout.tsx:20-21`) · **H5** a tag de abertura `<html …>` **não** contém `data-home-session` (a marca só nasce por script; mutante de "SSR neutro" reprova) e o elemento com `data-home-content` não traz `hidden` nem `style` inline (conteúdo servido visível).
- [ ] **A decisão é do cliente, não do servidor (DEC-041-001) — FR-040-015 e AC-040-011** — mesmo comando → **H6** `GET /` **com** cookie `mnemo_access=qualquer-valor` → 200 (nunca 307: o `proxy` não casa `/`, mesmo com cookie de sessão presente); H6 **discrimina a alternativa descartada de DEC-041-001** (o servidor decidir pela sessão e redirecionar quem tem cookie para fora de `/`), que H1 sozinho não pega; **H7** `GET` de cada rota interna sem cookie, um caso por prefixo de `INTERNAL_ROUTE_PREFIXES` (`studio`, `content`, `visual-library` — lista lida de `src/lib/internal-routes.ts:14`, nunca re-grafada; **os itens não têm barra inicial**, então a rota pedida é `/${prefixo}`) → status **307** e, sobre o `Location` **real capturado no commit-base antes de fixar** (amostra, não suposta — pode vir absoluto ou relativo), `new URL(location, base).pathname === '/login'` **e** `new URL(location, base).searchParams.get('next') === '/' + prefixo` (o esperado prefixa `/`: `INTERNAL_ROUTE_PREFIXES` não traz barra inicial) (comparação por URL parseada, nunca por string codificada literal) (3 casos; eixo = prefixo, um mutante que tira um prefixo do matcher reprova exatamente o seu caso). AC-040-011 fecha por H7 (anônimo em rota interna vai ao login com retorno) + H1–H4 (a home pública exibida a ele tem o mesmo conteúdo de antes).
- [ ] **Manifesto — AC-040-023** — mesmo comando → **H8** `GET /manifest.webmanifest` → 200 e o JSON tem `start_url === '/'`; **H9** a resposta não declara `shortcuts` para rota interna (paridade com o que `manifest.test.ts` já fixa, agora contra o servidor real). `src/app/manifest.test.ts` segue verde **sem edição** (asserção existente `start_url` = `'/'` em `manifest.test.ts:55-58`, lida no eixo do predicado: compara o valor literal do objeto retornado, não o servidor — por isso o H8 existe).
- [ ] **Guarda intacta, com diff vazio ancorado no commit-base** — `git diff --stat b729a76 HEAD -- src/proxy.ts src/proxy.test.ts src/app/manifest.ts src/app/manifest.test.ts` → saída **vazia** (ausência; no commit-pai também vazia — a âncora é o commit-base e não `main...HEAD`, que não enxerga o arquivo novo); `npm test -- src/proxy.test.ts` → `Tests: 55 passed, 55 total` (medido em b729a76; inclui `it.each`: `matches('/')` falso, matcher derivado dos prefixos, extrator AST do Next, "home pública não é guardada"). Lição `guard-de-navega-o-proxy-middleware-enumera-o-que-guarda-nunca-o-que-dispensa`: os **dois lados** ficam afirmados — rotas internas guardadas (H7, `proxy.test.ts`) **e** `/` livre (H1, H6, `proxy.test.ts`); lição `valor-de-configura-o-lido-por-analisador-de-build-s-provado-por-or-culo-que-passe-pelo-build`: o oráculo aqui é o build real (`next build` no `beforeAll`), não um modelo do matcher. Mutante **D1** (aplicado em worktree descartável): incluir `'/'` em `config.matcher` de `src/proxy.ts` → `npm test -- src/proxy.test.ts` reprova **e** `npm test -- src/app/home.integration.test.ts` reprova **H1** (307 em vez de 200, sem cookie); **H6 não reprova D1** (com cookie o proxy deixa passar) — por isso H6 é a prova da outra alternativa, acima.
- [ ] **Mutantes do servidor** (cada um rodado pelo comando do critério correspondente — arquivo inteiro, nunca `-t` — com controle negativo, isto é, sem mutante o mesmo comando volta verde com o mesmo número de testes): **D2** `page.tsx` passa a render dinâmico (`cookies()` no corpo) → o servidor passa a responder `/` como dinâmica: a asserção de `Cache-Control` de **H1** reprova o mutante · **D3** o servidor marca `data-home-session="checking"` no `<html>` (SSR neutro, alternativa descartada na DEC-041-003) → H5 reprova · **D4** `page.tsx` some com o `<h1>` (conteúdo público removido) → H2 reprova · **D5** trocar o `<title>` default em `layout.tsx` → H3 reprova · **D6** trocar `description` → H4 reprova · **D7** `start_url` → `/studio` em `manifest.ts` → H8 e `manifest.test.ts` reprovam · **D8** remover `'/visual-library'` e `'/visual-library/:path*'` do `config.matcher` literal de `src/proxy.ts` (o matcher é literal à mão, `proxy.ts:97-104`) → o caso H7 de `/visual-library` reprova (200/404 em vez de 307) e `proxy.test.ts` também. **8 mutantes (D1–D8), 8 provas**; todos em `git worktree add ../wt-mut-041-004 HEAD` com `node_modules` ligado ao do worktree principal, nunca `npm install`/`npm ci`; ao fim `git worktree remove` e `git status --porcelain` da árvore da TASK **vazio** (o symlink `node_modules` do worktree está em `info/exclude`) (lição `sonda-de-investiga-o-n-o-nasce-em-tests-contagem-de-teste-declara-a-rvore`).
- [ ] **Servidor de teste sem exposição e processo limpo** — o `next start` sobe com `-p 0 -H 127.0.0.1` (o molde `not-found.integration.test.ts:77` tem o mesmo argumento — lido por inteiro na fixação) e o teste encerra o filho no `afterAll`; prova executável: `npm test -- src/app/home.integration.test.ts` → exit 0 **sem** a mensagem `Jest did not exit one second after the test run` na saída (filho órfão/handle aberto a acusaria) e `Tests: 11 passed`.
- [ ] **Suíte completa verde no modo default da ficha, sem `--runInBand` (furo no plano sancionado)** — `npx jest` (workers paralelos default) rodado **3× seguidas** → 3× `Tests: N passed, N total`, 0 failed (N = 856 medido com o arquivo novo); e `npx jest src/app/home.integration.test.ts` e `npx jest src/app/not-found.integration.test.ts` isolados → verdes. PAR DE PROVAS: mutante **D9** (remover o acquire/release da trava num dos dois arquivos) → `npx jest src/app/home.integration.test.ts src/app/not-found.integration.test.ts` (paralelo) volta a falhar em ao menos 1 de 3 rodadas; e **D10** (lock órfão: diretório de lock criado por PID inexistente antes da execução) → a suíte ainda conclui verde (recuperação do órfão). Contrato do helper (sem AC): teste unitário próprio `test/next-build-lock.test.ts` com acquire exclusivo (2ª aquisição espera até a 1ª liberar), release idempotente e recuperação de órfão.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (produção e teste) — `npx eslint --max-warnings=0 $(git diff --name-only --diff-filter=d b729a76...HEAD | grep -E '\.(ts|tsx)$')` → exit 0; `npm run typecheck` → exit 0; `npx prettier --check $(git diff --name-only --diff-filter=d b729a76...HEAD)` → exit 0; `npm run lint` → exit 0; `npm run build` → exit 0.

## Riscos específicos

- **`.next` compartilhado**: o teste roda `next build` no worktree; não subir `next dev` do mesmo worktree ao mesmo tempo (o Roteiro do gate 9 da TASK-041-003 já encerrou o dele).
- **Duração**: build real ~30 s a minutos; `jest.setTimeout` dedicado como no molde, sem alterar o timeout global de `jest.config.ts`.
- **Literais**: título e descrição vêm de `layout.tsx` do commit-base; se o KAN-177 (que altera `layout.tsx`) mergear antes e mudar esses valores, o teste reprova por divergência legítima — atualizar contra o `layout.tsx` então vigente, nunca relaxar a asserção.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
**Jira**: 

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
<!-- Branch, tentativas, arquivos, revisores e narrativa (retries, escalações) vivem no
ledger da sessão e no commit da closure (4.76) — não se repetem aqui (4.409). -->
