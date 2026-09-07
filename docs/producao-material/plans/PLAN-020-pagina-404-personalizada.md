# PLAN-020: Página 404 personalizada com volta à home

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.1
**Autor**: keelson (scribe)
**Data**: 2026-09-07

## Aderência a guidelines

**Ficha/perfil de linguagem**: frontend — Next 16 (`guidelines/project/frontend/next-16.md`;
Next.js 16.3.2 App Router · React 19.2 · TypeScript 6 `strict` · Tailwind 4 · Jest 30 +
Testing Library, `jsdom`). SPEC-019 §5 declara "sem chamada a API/backend" (nenhum par de
leitura novo) — o perfil de backend (`guidelines/project/backend/node-22.md`) não se aplica;
sem migração, sem endpoint, sem model Prisma.

**Stack vigente herdado**: convenção de arquivo especial do App Router `not-found.tsx`, já
documentada no próprio perfil como o par declarativo de `notFound()` ("404 semântico, não
redirect", perfil §4, tabela de convenções de arquivo); Server Component sem estado por
padrão (perfil §1/§4 — `'use client'` só onde há estado/evento, e esta tela não tem nenhum
dos dois); `next/link` já em uso no projeto para navegação interna
(`mnemonicos-frontend/src/components/site-header.tsx:1,11`); tokens `@theme` e utilities
`@layer base` de `mnemonicos-frontend/src/app/globals.css` (`--link:3-22/31/49`,
`text-link:73`, `text-muted:69`); Jest 30 + Testing Library + `jsdom`, mesmo padrão de teste
de Server Component do App Router já em uso (`render(await Componente(...))`,
`mnemonicos-frontend/src/app/login/page.test.tsx:16-18`).

**Padrão arquitetural seguido**: fronteira de erro declarativa por segmento do App Router
(perfil §4 — `not-found.tsx`); nenhum estado, efeito ou evento client-side é introduzido, logo
`'use client'` não se aplica a este componente.

**Decisões irreversíveis do slug tocadas**: nenhuma (`docs/producao-material/INDEX.md`,
seção "Decisões irreversíveis" — vazia; as 12 DECs de PLAN-003 são todas reversíveis).

**Decisões irreversíveis de outros slugs em conflito**: nenhuma — `docs/producao-material/
INDEX.md` é o único `INDEX.md` existente no workspace hoje (confirmado por glob
`docs/*/INDEX.md`).

**Exceções aos guidelines**: nenhuma.

## Cobertura

**SPEC referenciada**: SPEC-019
**Slice declarado**: cobertura total restante (Caso D — nenhum PLAN anterior cobre esta SPEC)

**FRs cobertos**:
- FR-019-001, FR-019-002, FR-019-003, FR-019-004

**NFRs cobertos**:
- NFR-019-001, NFR-019-002, NFR-019-003, NFR-019-004

**Cobertura agregada do slug**:
- Total na SPEC: 4 FRs + 4 NFRs = 8
- Cobertos por planos anteriores: 0
- Cobertos por este: 8
- Gap restante: 0

(SPEC-019 não declara FEATs — sem linha de funcionalidades cobertas.)

## 1. Visão técnica

Esta fatia cobre a SPEC inteira com uma única página estática,
`mnemonicos-frontend/src/app/not-found.tsx`, usando a convenção de arquivo especial do App
Router (`not-found.tsx`) em vez de uma rota "catch-all" ou de um boundary de erro custom
(DEC-020-001). Por viver na raiz de `src/app/`, o componente é acionado pelo Next para
**qualquer** segmento sem rota correspondente, público ou dentro de `(interno)` — nenhum
layout aninhado deste projeto declara seu próprio `not-found.tsx` (reconhecimento técnico:
glob não encontrou outro arquivo do tipo), então a mesma página cobre A-019-001 (sem
diferenciação de layout por segmento) sem nenhuma configuração adicional de roteamento.

O componente **herda automaticamente** o root layout (`layout.tsx:29-43`) — `<SiteHeader />`
(marca 1 de AC-019-001), `<Providers>` e o `<footer>` — sem precisar importar nada disso
diretamente. A responsabilidade de `NotFoundPage` (COMP-020-001) se resume a: título e
mensagem em pt-BR usando os tokens/utilities já existentes do tema (`text-muted`, marca 2 de
AC-019-001), e um `<Link href="/">` do `next/link` (não `<a>` cru — DEC-020-003) com rótulo em
pt-BR indicando volta à home (FR-019-002/FR-019-003).

Dois eixos do escopo **não geram código novo**, só prova de não-regressão:

- **Precedência guard×404 (AC-019-001b)** é comportamento já existente do `proxy.ts`
  (matcher intocado, `src/proxy.ts:56`) — este PLAN não cria lógica de exclusão dentro de
  `NotFoundPage`; a prova é a suíte `proxy.test.ts` continuar verde e nenhum arquivo deste
  PLAN tocar `src/proxy.ts` (DEC-020-002).
- **Status HTTP 404 (NFR-019-003/AC-019-004)** é produzido nativamente pelo framework ao usar
  a convenção `not-found.tsx` — mas como não há hoje harness de integração HTTP nem suíte E2E
  instalada (`quality.e2e: null` na ficha) que prove isso automaticamente, este PLAN acrescenta
  um teste de integração dedicado subindo um servidor real (DEC-020-004), em vez de aceitar a
  garantia documental do framework sem prova (Charter Art. 1: gerador ≠ avaliador).

**Estratégia de teste**: `mnemonicos-frontend/src/app/not-found.test.tsx` (novo, `jsdom`,
`render(NotFoundPage())` — sem `searchParams`/`params`, mais simples que o molde de
`login/page.test.tsx:16-18`) cobre AC-019-001 (marcas 2-4: tokens, pt-BR, padrão do
link/foco), AC-019-002 e AC-019-003 (o `href="/"` do link renderizado, via
`getByRole('link', { name: /.../ })`) e AC-019-005 (o elemento é um `<a>` nativo — alcançável
por Tab, ativável por Enter, sem `tabIndex` customizado a testar). Um teste de integração
dedicado (`@jest-environment node`, DEC-020-004) cobre AC-019-004 (status HTTP 404 real). A
suíte `proxy.test.ts` existente, sem nenhuma alteração, prova a não-regressão de AC-019-001b.

## 2. Stack e dependências

Nenhuma dependência nova. Reuso integral do que já existe em `mnemonicos-frontend`:

| Peça | Origem |
|---|---|
| Convenção de arquivo `not-found.tsx` | nativa do App Router (Next 16, DEC-020-001) |
| `next/link` | já em uso em `site-header.tsx:1,11` (DEC-020-003) |
| Tokens/utilities de tema (`text-muted`, `text-link`) | `globals.css` existente |
| Jest 30 + Testing Library + `jsdom` | `jest.config.ts` existente |
| `@jest-environment node` + `child_process`/`fetch` (Node embutido) | mesmo mecanismo de override já usado em `proxy.test.ts:2-3`, sem pacote novo (DEC-020-004) |

## 3. Componentes

### COMP-020-001: NotFoundPage
**Responsabilidade**: página 404 de identidade visual da aplicação, exibida pelo App Router
para qualquer segmento sem rota correspondente (público ou interno com sessão ativa). Renderiza
título e mensagem em pt-BR usando os tokens/utilities do tema (`text-muted`), sem estilo
inline fora do `@theme`, e um `<Link href="/">` com rótulo pt-BR de volta à home. Não recebe
`params`/`searchParams` (convenção do arquivo `not-found.tsx` no App Router não os propaga) e
não faz nenhuma leitura de sessão, cookie ou API — puramente apresentacional. Herda
automaticamente `<SiteHeader />`, `<Providers>` e `<footer>` do root layout
(`layout.tsx:29-43`), sem import próprio.
**Realiza**: FR-019-001, FR-019-002, FR-019-003, FR-019-004, NFR-019-001, NFR-019-002, NFR-019-003, NFR-019-004
**Interface pública**: `export default function NotFoundPage()` em
`mnemonicos-frontend/src/app/not-found.tsx` — export default é a exceção exigida pelo Next
para arquivo de convenção do App Router (mesma classe de `page`/`layout`/`error`, perfil §3),
sem props. Markup: contêiner centralizado com título (`<h1>`), parágrafo de mensagem
(`text-muted`) e `<Link href="/" className="text-link ...">` com texto "Voltar para o
início" (rótulo final sujeito a ajuste de redação do `product-designer`/`po`, sem impacto nos
ACs). Teste: `mnemonicos-frontend/src/app/not-found.test.tsx` (novo) + teste de integração
dedicado (DEC-020-004) para o status HTTP.
**Dependências**: nenhuma

## 4. Fluxos principais

**Fluxo de rota inexistente na área pública** (AC-019-001, AC-019-004): o usuário acessa uma
URL sem `page.tsx`/`route.ts` correspondente fora de `(interno)` → o Next não encontra
segmento e invoca o boundary `not-found.tsx` da raiz → `NotFoundPage` renderiza dentro do root
layout (cabeçalho/rodapé/providers herdados) → a resposta HTTP carrega status 404 (nativo da
convenção, DEC-020-004 prova).

**Fluxo de rota inexistente na área interna, com sessão ativa** (AC-019-001, FR-019-004): o
usuário autenticado acessa uma URL sob `(interno)` sem rota correspondente → o guard de
SPEC-002 (fora deste PLAN) não bloqueia (cookie presente) → o Next segue para o mesmo boundary
`not-found.tsx` da raiz (nenhum `not-found.tsx` aninhado sob `(interno)`) → mesma
`NotFoundPage`, sem diferenciação de layout (A-019-001).

**Fluxo de rota inexistente sob prefixo guardado, sem sessão** (AC-019-001b, não-regressão):
`proxy.ts` casa o prefixo (`/studio`, `/content` — `internal-routes.ts:14`) **antes** da
resolução de rota do Next (premissa técnica do reconhecimento — comportamento padrão
documentado do App Router: middleware roda no edge antes do roteamento de página) → sem
cookie `mnemo_access`, redireciona para `/login?next=<path>` sanitizado (`proxy.ts:27-38`) →
`NotFoundPage` nunca é alcançada neste caminho; nenhum código deste PLAN participa dele
(DEC-020-002).

**Fluxo de clique/teclado no link de volta** (AC-019-003, AC-019-005): o usuário aciona o
`<Link href="/">` — por clique do mouse, ou por Tab até focá-lo e Enter — e o Next navega
client-side para a home pública (`page.tsx:27-50`), sem submissão de dados nem estado
intermediário (nota de FR-019-003 na SPEC: par único clique→navegação, sem estado "em
andamento").

## 5. Modelo de dados

Não há modelo de dados novo — nenhuma mudança em `mnemonicos-backend`, nenhum model, coluna
ou migração. `NotFoundPage` não lê nem grava nenhum dado persistido (SPEC-019, nota "par de
leitura", §5). Item 9 da Etapa 4 do contrato de `/keelson:plan` (verificação de superfície de
API/schema): **n/a** — nenhuma entidade nova, nenhum endpoint novo.

## 6. Decisões arquiteturais

### DEC-020-001: Convenção nativa `not-found.tsx` do App Router, em vez de rota catch-all ou boundary de erro custom
**Contexto**: FR-019-001/FR-019-004 exigem uma página 404 com identidade visual para
qualquer rota inexistente, em qualquer área. `mnemonicos-frontend` não tem hoje
`src/app/not-found.tsx` nem `global-error.tsx` (reconhecimento técnico confirmado por glob).
**Decisão**: usar `src/app/not-found.tsx` (Server Component), a convenção oficial do Next
para 404 — herda layout automaticamente e produz status HTTP 404 nativo do framework, sem
código extra.
**Alternativas consideradas**:
- Rota catch-all (`src/app/[...not_found]/page.tsx`) retornando uma página customizada,
  descartada porque um `page.tsx` comum responde 200 por padrão — teria que chamar
  `notFound()` internamente para produzir o status correto, tornando-se uma reimplementação
  redundante da própria convenção `not-found.tsx`; e ainda correria por baixo do matcher do
  `proxy.ts` da mesma forma, sem resolver nada que a convenção nativa não resolva, só
  adicionando uma rota nova a manter.
- `error.tsx`/`global-error.tsx` como boundary para o cenário, descartada porque trata falha
  de execução do servidor (500) — natureza diferente de ausência de rota (§4.2/anti-persona
  da SPEC-019); usá-lo indevidamente confundiria a fronteira semântica que a própria SPEC
  exige manter separada.
**Consequências**: implementação mínima (um arquivo), sem rota nova no roteador, com o custo
de status HTTP delegado inteiramente à convenção do framework — a prova desse custo (ele de
fato produz 404) fica a cargo do teste de integração de DEC-020-004.
**Reabrir se**: nunca — é a convenção estável e documentada da versão pinada do Next (16.3.2)
para este caso; nenhuma condição de mundo prevista a invalida.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (perfil `next-16.md` §4 já lista `not-found.tsx` como
o par declarativo de `notFound()` a preferir).

### DEC-020-002: Precedência guard×404 delegada inteiramente ao `proxy.ts` existente, sem lógica nova
**Contexto**: AC-019-001b exige que uma rota inexistente sob prefixo guardado
(`/studio/**`, `/content/**`) sem sessão ative vá para `/login?next=<path>` (SPEC-002),
nunca para a 404 personalizada. Isso já é o comportamento do `proxy.ts` hoje (matcher
`['/studio','/studio/:path*','/content','/content/:path*']`, `src/proxy.ts:56`), que roda
antes da resolução de rota do Next (premissa técnica do reconhecimento).
**Decisão**: este PLAN não cria nenhuma verificação de sessão ou lógica de exclusão dentro de
`NotFoundPage`; a precedência é 100% delegada ao `proxy.ts` já entregue por SPEC-002. A prova
de correção é a suíte `proxy.test.ts` (incluindo `proxy.test.ts:121-131`, que confirma o
matcher não casar `/` nem `/login`) continuar verde, e nenhum arquivo deste PLAN tocar
`src/proxy.ts`.
**Alternativas consideradas**:
- Verificar sessão dentro de `NotFoundPage` e redirecionar manualmente quando a rota estiver
  sob prefixo guardado, descartada porque duplicaria a lógica de guard já centralizada no
  `proxy.ts` (fonte única de verdade do deny-by-default de SPEC-002) — um segundo lugar para
  manter a mesma regra é um segundo lugar para ela divergir e abrir um bypass não coberto pela
  suíte `route-authz-matrix`/`proxy.test.ts` existente.
**Consequências**: `NotFoundPage` fica desacoplada de sessão/autorização, mais simples e sem
superfície de segurança própria; em troca, este PLAN depende inteiramente da suíte de
`proxy.ts` permanecer verde como prova de não-regressão — nenhuma prova nova é escrita para
este comportamento, só a suíte existente é reexecutada.
**Reabrir se**: o `proxy.ts` mudar sua ordem de execução em relação à resolução de rota do
Next (ex.: uma versão futura do framework alterar essa premissa) — não esperado sob a versão
pinada atual (16.3.2).
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (deny-by-default de SPEC-002/`proxy.ts` é decisão de
outro slice do mesmo slug, não tocada aqui).

### DEC-020-003: Link de volta como `<Link href="/">` do `next/link`, não `<a>` cru
**Contexto**: FR-019-002/FR-019-003 exigem um link/botão visível que navegue para a home
pública ao ser acionado; AC-019-005 exige operação por teclado (Tab + Enter) equivalente ao
clique.
**Decisão**: usar `<Link href="/">` do `next/link` — mesmo padrão já em uso no projeto
(`site-header.tsx:1,11`), com foco/teclado grátis via o `<a>` semântico que `Link` renderiza,
sem precisar de `'use client'` (componente `Link` funciona dentro de Server Component).
**Alternativas consideradas**:
- `<a href="/">` cru, descartada porque perde o *prefetch* e a navegação client-side
  otimizada que `Link` oferece (custo concreto: navegação de volta força full page reload,
  jogando fora o benefício do App Router nesta rota) sem nenhum ganho compensatório — e a
  regra de lint `@next/next/no-html-link-for-pages` do perfil já bloqueia esse padrão para
  rota interna.
**Consequências**: nenhum código de acessibilidade extra necessário — o `<a>` renderizado por
`Link` já é focável pela ordem natural de tabulação e ativável por Enter, satisfazendo
AC-019-005 sem `tabIndex` nem handler de teclado customizado.
**Reabrir se**: nunca — é o padrão idiomático já estabelecido no projeto para qualquer link
de navegação interna.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (perfil §9, tabela "Prefira a plataforma ao helper
caseiro": `<a>` interno → `next/link`).

### DEC-020-004: Verificação do status HTTP 404 (AC-019-004) por teste de integração com servidor real, não por asserção `jsdom`
**Contexto**: `jsdom` (ambiente padrão de `jest.config.ts`) não executa um servidor Next
real nem expõe status de resposta HTTP — renderizar `NotFoundPage` num teste comum prova
conteúdo, não o código de status da resposta. Não há suíte E2E instalada
(`quality.e2e: null` na ficha) nem harness de integração HTTP no repositório hoje
(reconhecimento técnico, item 10).
**Decisão**: acrescentar um teste de integração dedicado, com override
`@jest-environment node` (mesmo mecanismo já usado em `proxy.test.ts:2-3`), que sobe um
servidor Next real a partir de um build de teste (`next build` seguido de `next start` num
processo filho, porta dinâmica) e faz uma requisição HTTP real a uma rota inexistente,
asserindo `response.status === 404`.
**Alternativas consideradas**:
- Confiar apenas na garantia documental do framework (a convenção `not-found.tsx` sempre
  produz 404) sem prova automatizada, descartada porque o DoD desta SPEC (§1.3, `Fonte de
  medição: instrumentação — suíte de teste automatizado cobrindo os ACs`) exige exatamente
  este AC coberto por prova — aceitar a documentação do framework sem verificação é suposição
  não falsificável, violando o princípio "gerador ≠ avaliador" (Charter Art. 1).
- Instalar uma suíte E2E completa (Playwright, via `/keelson:e2e-setup`) só para provar este
  AC, descartada nesta fatia por desproporção de custo (instalação e manutenção de uma suíte
  inteira para uma tela estática) — fica registrada como gatilho de reabertura abaixo.
**Consequências**: o TASK que implementa este teste orquestra `next build`/`next start`
dentro do próprio processo de teste, com timeout maior que o padrão do Jest e cuidado para
liberar a porta ao final (`afterAll`); é o único teste do slug com este padrão até hoje —
ver TRISK-020-001.
**Reabrir se**: o projeto instalar suíte E2E formal (Playwright) por outro motivo — quando
isso acontecer, este teste de integração ad hoc deve migrar para lá em vez de conviver com
dois mecanismos de prova de status HTTP.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova (nenhuma DEC anterior do slug trata verificação de status
HTTP via servidor real).

## 7. Mapeamento FR -> componente

| FR | Componente | AC cobertos |
|----|------------|-------------|
| FR-019-001 | COMP-020-001 | AC-019-001 |
| FR-019-002 | COMP-020-001 | AC-019-002 |
| FR-019-003 | COMP-020-001 | AC-019-003, AC-019-005 |
| FR-019-004 | COMP-020-001 | AC-019-001, AC-019-001b |
| NFR-019-001 | COMP-020-001 | AC-019-001 |
| NFR-019-002 | COMP-020-001 | AC-019-002 |
| NFR-019-003 | COMP-020-001 | AC-019-004 |
| NFR-019-004 | COMP-020-001 | AC-019-005 |

> AC-019-001b (não-regressão do guard de sessão, `proxy.ts` pré-existente — DEC-020-002)
> não introduz componente novo: nenhuma linha de FR/NFR própria, coberto pela mesma
> aresta FR-019-004 → COMP-020-001 acima (o comportamento já existe; este PLAN só o
> verifica por teste, sem tocar `proxy.ts`).

## 8. Riscos técnicos

- **TRISK-020-001** O teste de integração de DEC-020-004 (`next build`+`next start` reais)
  é mais lento e mais frágil (porta ocupada, tempo de subida do processo, timeout) do que os
  testes `jsdom` do resto da suíte, e é o primeiro do slug com este padrão. Mitigação: porta
  dinâmica (porta 0 ou faixa reservada só para teste), timeout generoso e dedicado (maior que
  o default do Jest), e `afterAll` garantindo o encerramento do processo filho mesmo em
  falha; escopo deste padrão restrito a este único teste até haver suíte E2E formal.
- **TRISK-020-002** (herdado de RISK-019-001 da SPEC) Rota com segmento dinâmico malformado
  ou erro de parsing de parâmetro poderia, em tese, seguir um caminho de erro diferente do
  "rota não encontrada" padrão. Mitigação: a convenção nativa `not-found.tsx` do App Router
  cobre por construção qualquer segmento não resolvido pelo roteador (inclusive `[slug]`/
  `[...all]` malformado) — nenhum caso-limite foi identificado no reconhecimento técnico que
  escape dela; se um caso-limite aparecer nos testes deste PLAN, revisitar RISK-019-001 na
  Entrega.

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs — FR-019-001 a FR-019-004.
- [ ] Todos os NFRs cobertos têm verificação — NFR-019-001 a NFR-019-004.
- [ ] Decisões DEC refletidas no código — DEC-020-001 a DEC-020-004.
- [ ] Aderência à ficha/perfil validada (guideline de projeto frontend + perfil `next-16.md`).
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates) — AC-019-001, AC-019-001b,
      AC-019-002 a AC-019-005, via `not-found.test.tsx` (novo) + teste de integração dedicado
      (DEC-020-004) + reexecução verde de `proxy.test.ts` (não-regressão, sem alteração).
- [ ] Métrica da SPEC operacional (§1.3: `Fonte de medição: instrumentação — suíte de teste
      automatizado cobrindo os ACs desta SPEC`, dono Tech Lead/QA) — mesma suíte do item
      anterior é a própria fonte de medição desta métrica de conformidade; não há evento de
      produto/telemetria a instrumentar (fora de escopo, §4.2 da SPEC — natureza de
      conformidade verde/vermelha, não contagem de uso). Item satisfeito quando a suíte cobre
      os ACs e roda verde no fecho do ciclo.

## 10. Não coberto por este PLAN

- Nenhum — cobertura total de SPEC-019 (4/4 FRs, 4/4 NFRs) neste PLAN.
- Fora do documento por já estar fora do escopo da própria SPEC (§4.2, não repetido aqui como
  gap deste PLAN): página de erro 500, diferenciação de 404 por segmento, telemetria de
  acesso a rota inexistente, destino do link variável por sessão, sugestão de rota parecida,
  404 de API do backend, e o caso de recurso removido com soft-delete (`ContentForm`,
  SPEC-005) — todos permanecem no estado descrito pela SPEC, sem mudança deste PLAN.
