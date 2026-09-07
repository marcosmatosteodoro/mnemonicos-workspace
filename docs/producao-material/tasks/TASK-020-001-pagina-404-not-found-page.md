# TASK-020-001: Criar a página 404 personalizada (`not-found.tsx`) e seu teste unitário

**Slug**: producao-material
**Pertence a**: PLAN-020
**Realiza (FRs)**: FR-019-001, FR-019-002, FR-019-003, FR-019-004
**Componente**: COMP-020-001 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/pagina-404-personalizada` (já criada a partir de `origin/main` —
não recriar).
**Padrão de commit**: Conventional Commits (`feat:`).
**Framework de teste**: Jest 30 + Testing Library (`@testing-library/react`), `jsdom`
(`testEnvironment` default de `jest.config.ts` — sem override, componente síncrono sem
`next/server` no grafo de import) — molde: `mnemonicos-frontend/src/app/login/page.test.tsx`
(Server Component renderizado direto, `render(await Componente(...))`), simplificado aqui
porque `NotFoundPage` não é `async` e não recebe `searchParams`/`params`.

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

`mnemonicos-frontend/src/app/` não tem hoje `not-found.tsx` (reconhecimento técnico do
PLAN, confirmado por glob) — qualquer rota inexistente cai na página de erro genérica do
framework. Esta TASK cria a convenção nativa do App Router (`not-found.tsx`, DEC-020-001),
um Server Component sem estado, que o Next invoca automaticamente para qualquer segmento
sem rota correspondente e que herda `<SiteHeader />`/`<Providers>`/`<footer>` do root
layout (`layout.tsx:29-43`) sem nenhum import próprio — o teste desta TASK renderiza só o
componente (`NotFoundPage()`), não a árvore do layout. `not-found.tsx` importa
apenas `next/link` (nenhum import de `next/server`, `next/navigation` ou módulo que
puxe `Request`/`Response` — checado antes de fixar os critérios, então o `jsdom` default
basta, sem a lição "`jsdom` sem `Request`/`Response`/`fetch`" de `lessons.md`).

## Escopo

### Inclui

- `mnemonicos-frontend/src/app/not-found.tsx` (novo) — `export default function
  NotFoundPage()`, Server Component sem `'use client'` (nenhum estado/efeito/evento —
  perfil `next-16.md` §4), sem `params`/`searchParams` (convenção do arquivo não os
  propaga). Markup: contêiner centralizado com `<h1>` (título), `<p className="text-muted">`
  (mensagem, tokens do tema — nunca literal de paleta, guideline de projeto/`lessons.md`
  "Cor semântica de texto vem de token do tema"), e `<Link href="/"
  className="text-link ...">` (DEC-020-003, mesmo padrão de `site-header.tsx:1,11`) com
  rótulo em pt-BR indicando volta à página inicial (ex.: "Voltar para o início" — redação
  final sujeita a ajuste do `product-designer`/`po`, PLAN §3, sem impacto nos ACs). Todo
  texto visível em português do Brasil (NFR-019-002).
- `mnemonicos-frontend/src/app/not-found.test.tsx` (novo) — Testing Library, molde
  simplificado de `login/page.test.tsx`. Cobre AC-019-001 (marcas 2-4), AC-019-002,
  AC-019-003 e AC-019-005.

### Não inclui

- Qualquer edição em `src/proxy.ts` ou `src/proxy.test.ts` — a precedência guard×404 é
  100% delegada ao `proxy.ts` já existente (DEC-020-002); nenhuma verificação de sessão
  entra em `NotFoundPage`.
- O teste de integração do status HTTP 404 real (DEC-020-004, AC-019-004,
  NFR-019-003) e a reexecução de `proxy.test.ts` como não-regressão (AC-019-001b) —
  TASK-020-002 (Wave 1, paralela a esta, independente).
- Marca (1) de AC-019-001 ("mesmo cabeçalho/marca das páginas públicas") como asserção de
  render completo: é garantida estruturalmente pelo Next (arquivo na raiz de `src/app/`,
  sem layout próprio, herda `layout.tsx` automaticamente) — esta TASK só confirma, no
  próprio teste, que `NotFoundPage` NÃO reimplementa/duplica um cabeçalho próprio (ver
  Critérios de pronto); não renderiza a árvore do `RootLayout`/`SiteHeader`.
- Qualquer mudança em `globals.css`/tokens `@theme` — os tokens `--link`/`--danger`/
  `text-muted`/`text-link` já existem e são só consumidos.
- Rótulo final do link como decisão fechada de copy — texto funcional em pt-BR entra, mas
  redação fina é ajuste de `product-designer`/`po`, sem reabrir esta TASK.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Criar `not-found.tsx` com a assinatura `export default function NotFoundPage()` (PLAN
   §3, COMP-020-001, "Interface pública") — sem `'use client'`.
2. Markup: um `<div>`/`<section>` contêiner (sem `<header>`/`role="banner"` próprio — evita
   duplicar a marca herdada do layout), `<h1>` com o título, `<p className="text-muted">`
   com a mensagem, e `<Link href="/" className="text-link ...">` com o rótulo de volta —
   nenhuma classe de cor literal da paleta Tailwind (`text-red-*`, `text-blue-*` etc.),
   só os tokens `text-muted`/`text-link` já existentes em `globals.css`.
3. `not-found.test.tsx`: `render(NotFoundPage())` (sem `await` — componente síncrono, ao
   contrário do molde `login/page.test.tsx`). Casos:
   - AC-019-001 (marcas 2-4): o texto do título/mensagem está em pt-BR
     (`screen.getByText(/.../)`, sem termo em inglês); o link usa a classe `text-link`
     (`getByRole('link', ...).className` contém `text-link`); nenhum `role="banner"` é
     renderizado por `NotFoundPage` (`screen.queryByRole('banner')` é `null` — mutante:
     adicionar um `<header>` próprio dentro do componente faz este caso falhar).
   - AC-019-002: há um `getByRole('link', { name: /.../ })` visível com rótulo pt-BR
     indicando volta à home.
   - AC-019-003: o link renderizado tem `href="/"` (`getByRole('link', {...}).getAttribute
     ('href')` ou a prop resolvida do `next/link`).
   - AC-019-005: o link é um `<a>` nativo (o que `Link` renderiza) — alcançável pela ordem
     natural de tabulação (verificação: ausência de `tabIndex` explícito no elemento, e
     `document.activeElement` após `userEvent.tab()` a partir do topo do documento de
     teste é o próprio link — mesma técnica de `password-field.test.tsx`) **e** ativável
     por Enter de fato exercitado (não só presumido pela semântica do `<a>`):
     `userEvent.tab()` até focar o link, depois `userEvent.keyboard('{Enter}')` (ou
     `fireEvent.keyDown(link, { key: 'Enter', code: 'Enter' })`) e assert de ausência de
     qualquer `preventDefault`/handler customizado interceptando — como não há
     `onClick`/`onKeyDown` no componente, a prova é a ausência de handler que impeça a
     navegação nativa do `<a>`, não a navegação em si (jsdom não navega de verdade).
4. Sem chamada de rede/mock de `fetch`, sem `console.*` — página puramente apresentacional
   (SPEC-019, nota de "par de leitura").

## Critérios de pronto

- [ ] `NotFoundPage` exibe título e mensagem inteiramente em português do Brasil, usando
      `text-muted` (token do tema) para a mensagem — nenhuma classe de cor literal da
      paleta Tailwind (`text-red-*`, `text-blue-*`, `text-gray-*` etc.) no arquivo —
      AC-019-001 (marcas 2-3), NFR-019-002 (`lessons.md`, "Cor semântica de texto vem de
      token do tema, nunca de literal da paleta") — verificação executável:
      `grep -nE "text-(red|blue|green|gray|slate|zinc|neutral|stone|amber|yellow|lime|emerald|teal|cyan|sky|indigo|violet|purple|fuchsia|pink|rose)-[0-9]" src/app/not-found.tsx`
      (cwd `mnemonicos-frontend`) → nenhuma ocorrência (grep vazio esperado; padrão
      ancorado por nome de cor da paleta utilitária do Tailwind — o mesmo padrão casa
      `text-red-500`, o literal que a lição documenta como o defeito real corrigido em
      `internal-shell.tsx`/`login-form.tsx` pelo commit `b990e41`; rodar o mesmo grep
      contra `git show b990e41~1:mnemonicos-frontend/src/components/internal-shell.tsx`
      confirma que o predicado de fato casaria o literal proibido antes da correção — o
      predicado exclui e se fixa com um dado que ele rejeita, decisão 4.93).
- [ ] `NotFoundPage` não renderiza `role="banner"`/`<header>` próprio (a marca do
      cabeçalho é herdada do layout, nunca duplicada aqui) — AC-019-001 (marca 1,
      estrutural + prova de não-duplicação nesta TASK).
- [ ] Há um `<Link href="/">` visível, com classe `text-link` e rótulo pt-BR indicando
      volta à página inicial — AC-019-001 (marca 4), AC-019-002.
- [ ] Clicar/acionar o link (via `userEvent.click` e via `userEvent.tab()` +
      `userEvent.keyboard('{Enter}')`, ambos exercitados de fato, não presumidos pela
      semântica do `<a>`) resolve para `href="/"` sem nenhum handler/`preventDefault`
      interceptando — AC-019-003, AC-019-005.
- [ ] AC-019-001 marca (1) — "mesmo cabeçalho/marca das páginas públicas" — **não** é
      provada por render completo nesta TASK (garantia estrutural do App Router, ver
      "Riscos específicos"); o que esta TASK prova é só a não-duplicação (ausência de
      `role="banner"` próprio, critério acima). Marcas (2-4) fecham por teste completo.
- [ ] Testes cobrem AC-019-001 (marcas 2-4 por teste completo; marca 1 por garantia
      estrutural + não-duplicação, ver acima), AC-019-002, AC-019-003, AC-019-005 —
      verificação executável: `npx jest --runTestsByPath src/app/not-found.test.tsx`
      (cwd `mnemonicos-frontend`) → `PASS`, mínimo 6 casos (1 por marca/AC listado, mais
      o caso de Enter explícito, controle positivo de render + controle de ausência de
      `role="banner"`) — fixada
      antes do código (arquivo-alvo ainda não existe; mesmo padrão de invocação
      `npx jest --runTestsByPath <arquivo>` já comprovado nesta base para arquivo-alvo
      recém-criado — TASK-018-001 registrou `PASS ... Tests: 8 passed, 8 total` executando
      exatamente esse comando contra `password-field.test.tsx` no mesmo dia de fixação —
      molde da invocação).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`), produção e teste —
      `npx eslint src/app/not-found.tsx src/app/not-found.test.tsx` (cwd
      `mnemonicos-frontend`) → 0 problemas.
- [ ] Padrão de commit respeitado (Conventional Commits, `feat:`).
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem (`next-16.md`) —
      Server Component sem `'use client'` (nenhum estado/efeito/evento), `next/link` em
      vez de `<a>` cru (DEC-020-003, regra de lint `@next/next/no-html-link-for-pages`),
      cor semântica só por token do `@theme` (`text-muted`/`text-link`), nenhuma
      dependência nova em `package.json`.
- [ ] Code review aprovado.

## Riscos específicos

- Marca (1) de AC-019-001 ("mesmo cabeçalho/marca das páginas públicas") não é exercitada
  por render completo nesta TASK (o teste renderiza só `NotFoundPage()`, não o
  `RootLayout`) — garantia estrutural do App Router (arquivo na raiz de `src/app/`, sem
  layout próprio) já confirmada pelo reconhecimento técnico do PLAN (glob sem outro
  `not-found.tsx` na árvore); esta TASK prova apenas a não-duplicação (ausência de
  `role="banner"` próprio). Residual aceito nesta fatia — nenhuma caminhada de tela
  (gate 9) exigida, pois nenhum AC desta SPEC foi atribuído a esse gate (PLAN §1,
  "Estratégia de teste": todos os ACs fecham por gate 1).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Branch**:
**Commit SHA**:
**Jira**: KAN-81
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
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>

**Notas**:
