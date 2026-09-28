# PLAN-031: Redesenho visual da tela de login

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.1
**Autor**: scribe
**Data**: 2026-09-28

## Aderência a guidelines

**Decisões irreversíveis do slug tocadas**: nenhuma — `DEC-029-003` (PLAN-029/F8) trata do
`contentSnapshot` JSON de `ContentVersion`, sem relação com UI/CSS; as 12 DECs de PLAN-003
seguem todas reversíveis (INDEX.md §Decisões irreversíveis). Nenhuma decisão irreversível do
slug toca superfície visual.
**Decisões irreversíveis de outros slugs em conflito**: nenhuma — `docs/infra-vercel/` não
tem `INDEX.md` (sem bloco de decisões a citar; ausência declarada, decisão 4.241).
Nenhum outro slug com `INDEX.md` existe neste `docsRoot` além de `producao-material`.
**Exceções aos guidelines**: nenhuma.

## Cobertura

**SPEC referenciada**: SPEC-030
**Slice declarado**: cobertura total restante — Caso D (nenhum PLAN anterior cobre nenhum
FR/NFR de SPEC-030).

**FRs cobertos**:
- FR-030-001
- FR-030-002
- FR-030-003
- FR-030-004
- FR-030-005
- FR-030-006
- FR-030-007
- FR-030-008
- FR-030-009
- FR-030-010
- FR-030-011
- FR-030-012
- FR-030-013
- FR-030-014

**NFRs cobertos**:
- NFR-030-001
- NFR-030-002
- NFR-030-003
- NFR-030-004
- NFR-030-005
- NFR-030-006

## 1. Visão técnica

O redesenho de `/login` é puramente visual: nenhum contrato de dados, endpoint ou lógica de
autenticação (SPEC-002/SPEC-016) muda. A árvore de `/login` continua filha do único root
layout do app (`mnemonicos-frontend/src/app/layout.tsx:30-44`) — decisão deliberada
(DEC-031-001) que evita a reestruturação de todo `src/app/` que um route group dedicado
exigiria, e que entrega FR-030-013 (header/footer presentes) e FR-030-008 (nenhuma outra rota
tocada) "de graça".

A composição visual nasce de cinco camadas independentes: (1) tokens de paleta noturna
aditivos no `@theme` de `globals.css`, base de contraste AA para todo o resto (DEC-031-003);
(2) um fundo em tela cheia (`LoginNightBackdrop`), elemento `position: fixed; inset: 0` com
`z-index` negativo renderizado dentro da árvore normal da página, pintando atrás de
`SiteHeader`/`<main>`/footer sem removê-los do DOM; (3) o painel ilustrado do card
(`LoginIllustratedPanel`), metade superior decorativa com o mesmo motivo noturno; (4) a
moldura do card (`page.tsx` reestruturado) que monta as duas metades, título, responsividade
e preserva o aviso de sessão expirada/guard de `next` já existentes; (5) o restyle dos dois
Client Components de comportamento provado (`LoginForm`, `PasswordField`), sem tocar em
lógica. A ilustração e a animação (estrela cadente) usam só SVG inline e CSS puro
(DEC-031-002) — sem asset externo, sem dependência nova, com `prefers-reduced-motion`
suprimindo a animação.

Os quatro testes que travam o contrato comportamental (`page.test.tsx`,
`page.next-param.test.ts`, `login-form.test.tsx`, `password-field.test.tsx`) continuam
válidos sem alteração de asserção: como `page.tsx` não muda de caminho (nenhum route group),
os dois testes que o importam via `@/app/login/page` não precisam de ajuste de import.

## 2. Stack e dependências

Stack herdada sem reescolha: Next 16 (App Router, Turbopack), React 19, TypeScript 6
(`strict`), Tailwind 4 (`@theme` em `globals.css`, sem `tailwind.config.js`). Nenhuma
dependência nova (A-030-001 da SPEC) — SVG inline, CSS puro (`@keyframes`, `filter: blur()`,
gradiente), sem lib de ilustração/animação/ícone adicional.

## 3. Componentes

### COMP-031-001: Tokens da paleta noturna
**Responsabilidade**: Definir, no bloco `@theme` de `globals.css`, os tokens de cor aditivos
para a paleta noturna (céu em degradê, montanhas/dunas, lua, estrelas, campo em pílula,
botão) usados pelo fundo em tela cheia, pelo painel ilustrado e pelos elementos de UI
reestilizados, nos temas claro e escuro, com contraste AA medido e comentado (mesmo padrão
das variáveis semânticas existentes, `globals.css:32-34`).
**Realiza**: NFR-030-001, NFR-030-006
**Interface pública**: variáveis CSS custom properties no `@theme` (ex.:
`--color-dusk-sky-from`/`--color-dusk-sky-to`, `--color-night-sky-from`/`--color-night-sky-to`,
`--color-dusk-panel`, `--color-dusk-pill-bg`, `--color-dusk-pill-icon`,
`--color-dusk-button`), redefinidas sob `@media (prefers-color-scheme: dark)`; nomes
definitivos e contagem exata a critério da implementação, desde que evitem colidir com
`--color-ink-*`/`--color-brand-*`/`--color-recall-*` existentes.
**Dependências**: nenhuma

### COMP-031-002: LoginNightBackdrop
**Responsabilidade**: Renderizar o fundo em tela cheia atrás do card de `/login`, estendendo
a mesma atmosfera do painel ilustrado em escala maior e com profundidade/desfoque
(`filter: blur()`), decorativo (`aria-hidden="true"`), incluindo estrelas cadentes animadas
(`@keyframes` CSS puro) suprimidas sob `prefers-reduced-motion: reduce`.
**Realiza**: FR-030-002, FR-030-003 (parte — fundo), FR-030-011 (parte — fundo), FR-030-012
(parte — fundo)
**Interface pública**: Server Component sem props (ou `className` opcional), filho direto de
`page.tsx`/COMP-031-004 dentro da árvore normal de `/login`; `position: fixed; inset: 0` via
utilitário Tailwind/`@utility` próprio, `z-index` negativo (DEC-031-001 — elemento posicionado
com `z-index` negativo pinta atrás de irmãos estáticos/não-posicionados, independente da ordem
no DOM).
**Dependências**: COMP-031-001

### COMP-031-003: LoginIllustratedPanel
**Responsabilidade**: Renderizar a metade superior do card (painel ilustrado) com o motivo
noturno decorativo (montanhas/dunas em camadas, lua cheia, estrelas, estrelas cadentes, céu em
degradê) via SVG inline (formas geométricas simples, sem geometria pesada) + gradiente CSS,
`aria-hidden="true"`.
**Realiza**: FR-030-001 (parte — painel ilustrado), FR-030-003 (parte — painel), FR-030-011
(parte — painel), FR-030-012 (parte — painel)
**Interface pública**: Server Component sem props, filho de COMP-031-004.
**Dependências**: COMP-031-001

### COMP-031-004: LoginCardFrame (page.tsx reestruturado)
**Responsabilidade**: Compor o card central em duas metades (painel ilustrado + painel de
formulário) com sombra/efeito de flutuação, título curto e de destaque alinhado à esquerda,
responsivo (sem rolagem horizontal em 360/768/1280px; em 360px, painel ilustrado em faixa
baixa e formulário acima da dobra); preservar o aviso de sessão expirada (`role="status"`) e o
guard de open-redirect via `isSafeRelativePath` já existentes em `page.tsx`
(`mnemonicos-frontend/src/app/login/page.tsx:16-41`). Por permanecer dentro da árvore normal
do root layout (sem route group — DEC-031-001), `SiteHeader`/footer continuam presentes e
funcionais de graça, e nenhuma outra rota é tocada.
**Realiza**: FR-030-001 (parte — montagem do card), FR-030-008, FR-030-009, FR-030-010, FR-030-013, FR-030-014, NFR-030-003, NFR-030-005 (parte — `page.test.tsx`/`page.next-param.test.ts`)
**Interface pública**: `mnemonicos-frontend/src/app/login/page.tsx` (Server Component, mesmo
caminho de arquivo — sem mover, preservando os imports `@/app/login/page` usados pelos 2
testes existentes); renderiza COMP-031-002, COMP-031-003, COMP-031-005.
**Dependências**: COMP-031-001, COMP-031-002, COMP-031-003, COMP-031-005

### COMP-031-005: LoginForm (restyle)
**Responsabilidade**: Reestilizar `login-form.tsx` (campo de e-mail em pílula com ícone à
esquerda, botão de largura total em tom escuro, rótulo "E-mail") sem alterar `method="post"`,
o gate de hidratação, a mensagem genérica de erro em `role="alert"`, o status "Entrando…", o
redirecionamento para `next`/`INTERNAL_HOME`, `aria-busy` durante o envio e a ausência de
`aria-invalid` em erro — mesma lógica, só estilo (fato ancorado:
`mnemonicos-frontend/src/components/login-form.tsx:1-113`). Confirma a ausência de qualquer
controle sem função real (lembrar-me, esqueci a senha, criar conta não existem hoje).
**Realiza**: FR-030-004 (parte — campo de e-mail), FR-030-005, FR-030-006, FR-030-007,
NFR-030-002, NFR-030-005 (parte — `login-form.test.tsx`)
**Interface pública**: `mnemonicos-frontend/src/components/login-form.tsx` (Client Component,
mesmas props/contrato).
**Dependências**: COMP-031-001, COMP-031-006

### COMP-031-006: PasswordField (restyle)
**Responsabilidade**: Reestilizar `password-field.tsx` (campo em pílula com ícone de toggle)
sem alterar o comportamento funcional de alternância mostrar/ocultar senha, mantendo o alvo de
toque 28×28 e o foco visível — mesmo componente, sem reescrita (fato ancorado:
`mnemonicos-frontend/src/components/password-field.tsx:60-99`).
**Realiza**: FR-030-004 (parte — campo de senha), NFR-030-004, NFR-030-005 (parte — `password-field.test.tsx`)
**Interface pública**: `mnemonicos-frontend/src/components/password-field.tsx` (Client
Component, mesmas props/contrato: `value`/`onChange`).
**Dependências**: COMP-031-001

## 4. Fluxos principais

**Renderização inicial de `/login`**: `page.tsx` (COMP-031-004) monta, dentro do `<main
max-w-5xl py-10>` do root layout, o `LoginNightBackdrop` (COMP-031-002, `position: fixed;
inset: 0`, `z-index` negativo) e o card central com `LoginIllustratedPanel` (COMP-031-003) na
metade superior e o painel de formulário (título + aviso de sessão expirada condicional +
`LoginForm`/COMP-031-005, que renderiza `PasswordField`/COMP-031-006) na metade inferior. Os
dois elementos decorativos (backdrop e painel ilustrado) carregam `aria-hidden="true"` e não
interceptam foco nem leitura por tecnologia assistiva.

**Troca de tema**: `prefers-color-scheme` redefine as variáveis do `@theme` (COMP-031-001);
nenhum componente decide cor por conta própria — o motivo (dunas, montanhas, lua, estrelas)
permanece o mesmo, só os tokens mudam (FR-030-003).

**Responsivo em 360px**: o mesmo DOM se reorganiza por CSS (sem JS condicional) — painel
ilustrado ocupa uma faixa baixa e o painel de formulário fica acima da dobra (COMP-031-004).

**`prefers-reduced-motion: reduce`**: `@media (prefers-reduced-motion: reduce) { animation:
none }` neutraliza o `@keyframes` das estrelas cadentes em COMP-031-002/003, sem afetar a
funcionalidade do formulário (FR-030-011/012).

**Submissão do formulário**: inalterada — `LoginForm` (COMP-031-005) mantém o fluxo já
provado de SPEC-002 (hidratação → POST → estado "Entrando…" → sucesso/erro →
redirecionamento), só com nova aparência.

## 5. Modelo de dados

Nenhum. Mudança puramente visual/frontend — sem model Prisma, migração, endpoint ou alteração
de contrato de API novos. NFR-030-002/003/004 preservam intocado o contrato de dados e
comportamento já existente de SPEC-002/SPEC-016; a mudança de comportamento de
`LoginForm`/`page.tsx`/`PasswordField` além de estilo está fora de escopo (SPEC-030 §4.2).

## 6. Decisões arquiteturais

### DEC-031-001: Fundo em tela cheia sem route group dedicado
**Contexto**: FR-030-002 exige um fundo de página em tela cheia atrás do card, mas o app tem
um único root layout (`mnemonicos-frontend/src/app/layout.tsx:30-44`) que monta
`SiteHeader`/`<main className="mx-auto w-full max-w-5xl ... py-10">`/footer para toda rota —
inclusive `/login`. FR-030-008/AC-030-006 exigem que nenhuma outra rota mude visualmente. A
SPEC (A-030-002) cita route group dedicado como "candidata natural", mas deixa a decisão
técnica para o PLAN.
**Decisão**: O fundo em tela cheia é um elemento (COMP-031-002, `LoginNightBackdrop`)
renderizado DENTRO da árvore normal de `/login`, filho de `page.tsx` (Server Component), com
`position: fixed; inset: 0` e `z-index` negativo o bastante para pintar atrás de
`SiteHeader`/`<main>`/footer — elemento posicionado com `z-index` negativo pinta atrás de
irmãos estáticos/não-posicionados, independente da ordem no DOM; `position: fixed` posiciona
relativo ao viewport (não ao `<main max-w-5xl>` pai), desde que nenhum ancestral
(`Providers`/`SiteHeader`/`<main>`) declare `transform`/`filter`/`perspective`/`contain` —
ponto a verificar visualmente na implementação (TRISK-031-003), não bloqueante para este PLAN.
`page.tsx` continua no mesmo caminho (`src/app/login/page.tsx`), sem mover — os 2 testes que o
importam via `@/app/login/page` (`page.test.tsx`, `page.next-param.test.ts`) não precisam de
ajuste de import.
**Alternativas consideradas**:
- Route group dedicado a `/login` (`(algumnome)/login/`) com `layout.tsx` próprio, descartada
  porque no App Router do Next um `layout.tsx` dentro de um route group é sempre ANINHADO
  dentro do root layout, nunca um substituto dele — o grupo `(interno)/` existente
  (`src/app/(interno)/layout.tsx:1-17`) prova isso: ele soma UI, não desliga a do root.
  Desligar `SiteHeader`/`<main max-w-5xl>`/footer de `/login` exigiria promover o grupo a um
  SEGUNDO ROOT layout, o que por sua vez exige mover TODAS as rotas soltas hoje (`login/`,
  `page.tsx` da home, `not-found.tsx`, `manifest.ts`) para um grupo irmão — reestruturação de
  todo o `src/app/`, alto risco concreto de regressão visual/funcional nas outras rotas (o
  oposto do que FR-030-008 pede), desproporcional a um redesenho visual de uma tela.
**Consequências**: Como a página continua dentro do root layout normal, `SiteHeader` e o
footer permanecem presentes e funcionais em `/login` de graça (FR-030-013 satisfeito sem
componente extra); nenhuma outra rota é tocada (FR-030-008); nenhum import de teste muda de
caminho. Em contrapartida, a implementação precisa confirmar visualmente (gate 9/11) que
nenhum ancestral do backdrop introduz um novo contexto de empilhamento que quebraria o
`position: fixed` relativo ao viewport (TRISK-031-003).
**Reabrir se**: o Diretor pedir a mesma atmosfera visual (fundo em tela cheia com moldura
própria) em outras rotas — aí o custo da reestruturação de root layouts passaria a se
justificar por servir mais de uma tela.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (Server Component como default —
`guidelines/project/frontend/README.md`, "Server Component é o default").

### DEC-031-002: Técnica da ilustração e do céu — SVG inline + CSS puro, sem asset externo
**Contexto**: FR-030-003/FR-030-011 exigem um motivo noturno decorativo (montanhas/dunas, lua
cheia, estrelas, estrelas cadentes, céu em degradê) no painel ilustrado e no fundo em tela
cheia, com animação suprimida sob `prefers-reduced-motion: reduce` (FR-030-012). A-030-001 da
SPEC já veta asset de imagem externo e dependência nova. RISK-030-002 (SPEC) alerta para o
peso do SVG no bundle de `/login`. O projeto tem só 1 precedente de SVG inline
(`password-field.tsx:16-53`, ícones pequenos, `'use client'`) e nenhum precedente de
ilustração grande, de SVG em Server Component, de `linear-gradient`/`bg-gradient-*` ou de
`prefers-reduced-motion`.
**Decisão**: Motivo noturno em SVG inline com formas geométricas simples (poucos
`<path>`/`<circle>`, sem geometria pesada) dentro de Server Components (COMP-031-002,
COMP-031-003); degradê do céu via CSS usando os tokens novos do `@theme` (COMP-031-001), não
hex solto; estrelas cadentes (se implementadas) via `@keyframes` CSS puro, com `@media
(prefers-reduced-motion: reduce) { animation: none }`; desfoque do fundo via `filter: blur()`
CSS puro. Sem lib nova.
**Alternativas consideradas**:
- Asset de imagem externo (PNG/JPG/SVG de arquivo), descartada porque vetada pelo
  BRIEF-030/A-030-001 (sem arquivo externo, sem dependência nova); custo concreto: perderia a
  garantia de "puramente autoral" exigida e criaria um asset a versionar/otimizar fora do
  controle de tokens.
- Lib de ilustração/animação (ex.: Lottie, `framer-motion`), descartada porque é dependência
  nova não autorizada pela SPEC/BRIEF; custo concreto: peso de bundle adicional sem precedente
  no projeto e superfície nova a manter, quando `@keyframes` CSS puro já resolve a única
  animação exigida (estrela cadente).
**Consequências**: Sem asset externo a versionar; peso do bundle fica sob controle direto da
implementação (poucos paths SVG) — mitigado em TRISK-031-002; `prefers-reduced-motion` nasce
como precedente novo no projeto, documentado aqui para reúso futuro; a técnica exige medição
real no gate 10 antes de fechar (risco herdado de RISK-030-002).
**Reabrir se**: o peso do SVG/blur medido no gate 10 exigir simplificação adicional ou trocar
de técnica.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova (sem dependência nova — adere ao vínculo "sem dependência
nova" do BRIEF-030/A-030-001; primeiro precedente de `prefers-reduced-motion`/SVG
grande/gradiente CSS no projeto).

### DEC-031-003: Paleta nova como tokens aditivos no `@theme` existente
**Contexto**: NFR-030-001/NFR-030-006 exigem que todas as cores de `/login` venham de tokens
`@theme`, com contraste AA nos dois temas, sem substituir os tokens hoje usados por outras
telas (A-030-003 da SPEC). O guideline de projeto proíbe `tailwind.config.js`
(`guidelines/project/frontend/README.md` — "Não existe `tailwind.config.js` e não se deve
criar um"; "Cor... novo entra como token no `@theme`"). O bloco `@theme` de `globals.css` já
guarda paleta `--color-ink-*`/`--color-brand-*`/`--color-recall-*` e variáveis semânticas
comentadas com a justificativa de contraste AA (`globals.css:32-34`).
**Decisão**: Tokens aditivos no mesmo bloco `@theme` de `globals.css` (COMP-031-001), sem
`tailwind.config.js` novo, comentados com a justificativa de contraste AA como já se faz nas
variáveis semânticas existentes; nomes a critério da implementação (ex.:
`--color-dusk-*`/`--color-night-*`), evitando colidir com
`--color-ink-*`/`--color-brand-*`/`--color-recall-*` existentes; redefinidos sob `@media
(prefers-color-scheme: dark)` seguindo o padrão das variáveis semânticas atuais.
**Alternativas consideradas**:
- `tailwind.config.js` novo com paleta própria, descartada porque contraria diretamente o
  guideline de projeto ("não existe `tailwind.config.js` e não se deve criar um"); custo
  concreto: reintroduziria uma segunda fonte de configuração de tema, quebrando o padrão
  "config vive no CSS" do resto do app.
- Substituir/renomear os tokens semânticos existentes (`--surface`, `--text-strong`, etc.)
  pela paleta nova, descartada porque A-030-003 da SPEC exige que a paleta nova não substitua
  os tokens hoje usados por outras telas; custo concreto: mudaria a aparência de toda rota que
  consome esses tokens, violando FR-030-008 (não-regressão das outras rotas).
**Consequências**: A paleta nova convive lado a lado com a paleta existente, sem migração;
contraste AA precisa ser medido e comentado para cada par claro/escuro antes de fechar a wave
que toca os campos (risco herdado de RISK-030-001, mitigação: rodada extra do
`product-designer` reservada).
**Reabrir se**: o Diretor quiser adotar a paleta como identidade do produto em outras telas —
brief próprio (condição já registrada em A-030-003 da SPEC).
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (`guidelines/project/frontend/README.md` — tokens no
`@theme`, sem config JS).

## 8. Riscos técnicos

- **TRISK-031-001** Contraste AA de placeholder/rótulo sobre o fundo preenchido da pílula
  (NFR-030-001, herdado de RISK-030-001 da SPEC) é o ponto mais provável de retrabalho no gate
  de design (mitigação: medir contraste nos dois temas antes de fechar a wave que toca os
  campos — COMP-031-005/006; reservar margem para uma rodada extra do `product-designer`).
- **TRISK-031-002** Peso do SVG/CSS autoral da ilustração (COMP-031-002/003) no bundle de
  `/login` pode acionar o gate de performance (herdado de RISK-030-002 da SPEC) (mitigação:
  manter a ilustração simples, poucos paths, sem geometria pesada — DEC-031-002;
  `performance-engineer` avalia na implementação).
- **TRISK-031-003** `position: fixed` do fundo em tela cheia (COMP-031-002) depende de nenhum
  ancestral (`Providers`/`SiteHeader`/`<main>`) declarar `transform`/`filter`/`perspective`/
  `contain` — se algum declarar, o backdrop deixa de posicionar relativo ao viewport e passa a
  vazar/cortar dentro do `<main max-w-5xl>` (mitigação: verificação visual na implementação,
  item de roteiro do gate 9/11 — DEC-031-001; não bloqueante para este PLAN).
- **TRISK-031-004** Cobertura por roteiro de verificação (gates 9/11), não por AC formal
  (herdado de RISK-030-003 da SPEC, decisão do PO): trânsito guard → `/login?next=` → login →
  `next`; foco de teclado visível (ordem e-mail → senha → toggle → botão, indicador ≥3:1,
  nenhum elemento decorativo focável — confirma `aria-hidden` de COMP-031-002/003); robustez da
  ilustração (SVG ausente/degradado não quebra o formulário); autofill do navegador sobre o
  campo em pílula (COMP-031-005/006); `forced-colors`; aviso de sessão expirada visível acima
  da dobra em 360px (COMP-031-004) (mitigação: roteiro de implementação do gate 9/11).

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Aderência à ficha/perfil validada
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates)
- [ ] Métrica da SPEC operacional (SPEC-030 §1.3, `Fonte de medição: instrumentação`): suíte
      de teste automatizado cobrindo os ACs desta SPEC + verificação de tela real (gate 9,
      `screen-verify`) executadas e aprovadas — infraestrutura já existe, nenhum componente
      novo necessário para instrumentar.
- [ ] Processo (não-código, ato do Tech Lead na Entrega, sem COMP correspondente): anexar 6
      capturas de `/login` (tema claro e escuro × 360px/768px/1280px) ao relatório de Entrega,
      para o aceite binário do Diretor sobre o "Juiz do outcome estético" (SPEC-030 §1.3) —
      não bloqueia o ciclo, é exercido no merge.

## 10. Não coberto por este PLAN

Nenhum — cobertura 100% dos FRs/NFRs de SPEC-030 (Caso D, nenhum PLAN anterior cobria
qualquer FR/NFR dela). Itens já fora do escopo da própria SPEC (cadastro/recuperação de
senha/"lembrar-me", mudança de comportamento de `LoginForm`/`page.tsx`/`PasswordField`,
mudança visual de outras rotas, upload do asset de referência, aplicação da paleta a outras
telas) seguem fora de escopo — SPEC-030 §4.2.
