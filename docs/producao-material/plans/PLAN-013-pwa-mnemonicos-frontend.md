# PLAN-013: Suporte a PWA no mnemonicos-frontend

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.2
**Autor**: keelson (scribe)
**Data**: 2026-09-06

## Aderência a guidelines

**Ficha/perfil de linguagem**: frontend — Next 16 (`guidelines/project/frontend/next-16.md`;
Next.js 16.3.2 App Router · React 19.2 · TypeScript 6 `strict` · Tailwind 4 · Jest 30 +
Testing Library, `jsdom`). Esta fatia é só frontend (SPEC-013 §4.2) — o perfil de backend
(`guidelines/project/backend/node-22.md`) não se aplica; nenhum arquivo em
`mnemonicos-backend/` é tocado.

**Stack vigente herdado**: App Router com Server Components como default; Metadata API
nativa (`export const metadata`/`generateMetadata`) já em uso em
`mnemonicos-frontend/src/app/layout.tsx:13-27` — `app/manifest.ts` é a mesma família de
convenção nativa do App Router (Next ≥13), não um plugin novo. Jest 30 + Testing Library +
`jsdom` (`jest.config.ts`), molde de teste existente em
`src/app/(interno)/studio/page.test.tsx`. Nenhuma dependência nova entra na árvore: o
service worker é artesanal (DEC-013-001), sem `serwist`/`next-pwa`.

**Padrão arquitetural seguido**: fronteira servidor/cliente do perfil (§4) — `app/manifest.ts`
é função pura, sem `'use client'`, sem estado; o único client component novo (registro do
service worker) desce a diretiva `'use client'` ao componente mais fundo possível e isola o
efeito colateral (registro de API de browser) em `useEffect` — uso legítimo de efeito por
este perfil (não é busca de dado nem derivação de estado, §4). A lógica de decisão do
service worker (é asset estático? é navegação? é a versão de kill-switch?) é extraída em
funções puras, seguindo o princípio de isolamento de efeito colateral do perfil (§4:
"injete o valor, não crie interface").

**Decisões irreversíveis do slug tocadas**: nenhuma (`docs/producao-material/INDEX.md`,
seção "Decisões irreversíveis" — vazia; as 12 DECs de PLAN-003 são todas reversíveis).

**Decisões irreversíveis de outros slugs em conflito**: nenhuma — `docs/infra-vercel/`: sem
bloco de decisões (sem `INDEX.md` nesse slug; único artefato ali é
`briefs/BRIEF-001-vercel-entrypoint-500-avulso.md`). Nenhum outro slug com `INDEX.md` existe
hoje no workspace.

**Exceções aos guidelines**:
1. **Execução em worktree isolado, não na working tree principal**: todo código deste PLAN
   nasce em `C:/kwt/pwa` (branch `feat/producao-material-pwa-support`, a partir de
   `origin/main`) — **não** em `mnemonicos-frontend/` da working tree principal, onde outra
   sessão executa PLAN-012/F4 (Tira mnemônica) concorrentemente (RISK-013-005, SPEC-013 §9).
   O `developer` do `/keelson:tasks`/`/keelson:implement` deste PLAN roda todo comando
   (`dev`, `test`, `lint`, `typecheck`, `build`) com cwd em `C:/kwt/pwa/mnemonicos-frontend`,
   nunca na árvore principal. Ordem de merge das duas branches é ato do Diretor
   (RISK-013-005).
2. **Pasta `public/` nasce nesta fatia**: `mnemonicos-frontend` hoje não tem `public/` além
   do que o App Router serve de `src/app/favicon.ico` — os ícones (COMP-013-002) e o
   `sw.js` (COMP-013-003) criam a pasta pela primeira vez.

## Cobertura

**SPEC referenciada**: SPEC-013
**Slice declarado**: cobertura total restante (Caso D — nenhum PLAN anterior cobre esta SPEC)

**FRs cobertos**:
- FR-013-001, FR-013-002, FR-013-003, FR-013-004, FR-013-005, FR-013-006

**NFRs cobertos**:
- NFR-013-001, NFR-013-002, NFR-013-003, NFR-013-004, NFR-013-005, NFR-013-006, NFR-013-007, NFR-013-008

**Cobertura agregada do slug**:
- Total na SPEC: 6 FRs + 8 NFRs = 14
- Cobertos por planos anteriores: 0
- Cobertos por este: 14
- Gap restante: 0

(SPEC-013 não declara FEATs — sem linha de funcionalidades cobertas.)

## 1. Visão técnica

Esta fatia adiciona os quatro elementos que os critérios de instalabilidade do navegador
exigem — manifesto de aplicação, ícones, service worker registrado e conexão segura (esta
última já herdada da infraestrutura existente, NFR-013-004) — ao `mnemonicos-frontend`
inteiro (todas as rotas, sem recorte de sub-área — A-013-003). Nenhuma mudança de domínio,
schema ou backend: o que se persiste é infraestrutura de navegador (manifesto, Cache
Storage, versão do service worker instalado), não dado de aplicação (nota "par de leitura",
SPEC-013 §5).

O desenho segue três eixos, cada um resolvido por uma decisão técnica desta execução
(§6) ou por resolução direta de uma questão aberta:

- **Manifesto + ícones** (COMP-013-001, COMP-013-002): satisfazem FR-013-001/003/004 e
  NFR-013-007 (postura de exposição). Resolução de **Q-013-001** (conjunto de tamanhos de
  ícone): o conjunto mínimo que os critérios de instalabilidade do Chrome/Edge exigem —
  **192×192 e 512×512, ambos `purpose: "any"`** — gerados como asset simples a partir da
  identidade visual atual (favicon + tokens `--color-ink-50/950`/`--color-brand-400/500/600`
  de `globals.css`, A-013-002). Ícone `maskable` dedicado fica fora desta fatia (já
  registrado em Out-of-scope da SPEC, §4.2) — não é uma decisão de arquitetura com
  alternativas (DEC), é o piso técnico do próprio critério de instalabilidade, sem opção
  concorrente real a descartar.
- **Service worker do app-shell** (COMP-013-003 + COMP-013-004): satisfaz FR-013-005/006 e
  NFR-013-001/002/003/005/006/007(parte)/008, pela técnica de DEC-013-001 (artesanal, sem
  biblioteca).
- **Caminho de recuperação** (dentro de COMP-013-003): satisfaz NFR-013-006, pelo padrão de
  DEC-013-002 (SW que se autodesregistra).

`start_url` do manifesto é a raiz (`/`) — neutra no sentido de NFR-013-007: não é uma rota
interna do grupo `(interno)`, funciona tanto para quem chega sem sessão (vê `/login`, via
guarda existente) quanto para quem já tem sessão ativa; não há `shortcuts` declarados
(NFR-013-007).

## 2. Stack e dependências

Nenhuma dependência nova. Reuso integral do que já existe em `mnemonicos-frontend`:

| Peça | Origem |
|---|---|
| Metadata API / `app/manifest.ts` | nativo do Next 16 App Router (Next ≥13) |
| Jest 30 + Testing Library + `jsdom` | `jest.config.ts` existente |
| Tokens de tema (`--color-ink-*`, `--color-brand-*`) | `globals.css` existente |
| TypeScript 6 `strict` | `tsconfig.json` existente |
| Service worker | vanilla JS (`public/sw.js`), sem lib — DEC-013-001 |

## 3. Componentes

### COMP-013-001: Manifesto de aplicação
**Responsabilidade**: declarar `name`/`short_name`, ícones, `theme_color`/`background_color`
(coerentes com `--color-ink-50`/`--color-ink-950` já usados em `layout.tsx:24-25`), `display:
"standalone"`, `start_url` neutro (`/`), sem `shortcuts` (NFR-013-007).
**Realiza**: FR-013-001 (parte), FR-013-002 (parte), FR-013-003, FR-013-004, NFR-013-007 (parte)
**Interface pública**: `export default function manifest(): MetadataRoute.Manifest` em
`mnemonicos-frontend/src/app/manifest.ts` (mesmo nível de `layout.tsx`) — o Next expõe
automaticamente em `/manifest.webmanifest`. Teste: `src/app/manifest.test.ts` (chamada
direta da função, sem necessidade de `jsdom`/render — molde de teste de função pura).
**Dependências**: COMP-013-002

### COMP-013-002: Conjunto de ícones estáticos
**Responsabilidade**: prover os arquivos de ícone nos dois tamanhos mínimos de
instalabilidade (192×192 e 512×512, `purpose: "any"` — resolução de Q-013-001, §1), asset
simples derivado da identidade visual atual, sem trabalho de design de marca novo
(A-013-002).
**Realiza**: FR-013-001 (parte), FR-013-003, FR-013-004
**Interface pública**: arquivos estáticos `mnemonicos-frontend/public/icons/icon-192.png`,
`mnemonicos-frontend/public/icons/icon-512.png` (a pasta `public/` nasce nesta fatia — não
existe hoje, MAP/memo de exploração).
**Dependências**: nenhuma

### COMP-013-003: Service worker do app-shell
**Responsabilidade**: registrar-se e assumir o controle das requisições de assets estáticos
do app-shell; no `install`, popular o cache com uma lista fixa de assets estáticos
(JS/CSS/ícones/manifesto); no `fetch`, servir do cache **somente** requisições de assets
estáticos já precacheados (controle positivo, NFR-013-001/AC-013-004/008) e **nunca**
responder navegação/documento a partir do cache — toda requisição de navegação vai sempre à
rede, sem `navigateFallback` nem página offline (NFR-013-005/AC-013-008); no `activate`,
limpar caches de versão anterior do app-shell sem trocar a versão ativa sob um cliente já
aberto (sem `skipWaiting()`/`clients.claim()` no fluxo normal de atualização — a versão nova
só assume na reabertura seguinte, NFR-013-003/FR-013-006); quando a versão de build corrente
é a versão de "kill" (DEC-013-002), o `activate` toma o caminho de recuperação: chama
`self.registration.unregister()`, limpa todos os caches via `caches.keys()`/
`caches.delete()`, e força os clientes abertos a recarregar uma vez via `clients.claim()` +
mensagem de reload (NFR-013-006/AC-013-009) — esta é a única exceção deliberada à regra de
"nunca trocar sob cliente ativo", pois é o próprio caminho de recuperação.
**Realiza**: FR-013-001 (parte), FR-013-005, FR-013-006, NFR-013-001, NFR-013-002 (consequência), NFR-013-003, NFR-013-005, NFR-013-006, NFR-013-007 (parte — lista de precache restrita a estáticos), NFR-013-008 (não participa de requisição de API/HTML autenticado; não altera login/renovação/logout)
**Interface pública**: `mnemonicos-frontend/public/sw.js` — script vanilla registrado em
`/sw.js`. A lógica de decisão é extraída em funções puras nomeadas e exportadas de um módulo
irmão testável em `jsdom` sem precisar de `ServiceWorkerGlobalScope` real — `isStaticAssetRequest(url)`,
`isNavigationRequest(request)`, `isKillVersion(currentVersion)` — o próprio `sw.js` só liga
essas funções aos eventos `install`/`fetch`/`activate`. Teste:
`mnemonicos-frontend/src/lib/service-worker-policy.test.ts` cobre as funções puras;
comportamento de ciclo de vida real (evento `install`/`activate`/`fetch` disparado pelo
navegador, Cache Storage real) fica fora do alcance de `jsdom` (TRISK-013-001) — fechado por
inspeção manual no painel Application (DevTools), gate 9/DoD item (a).
**Dependências**: COMP-013-001, COMP-013-002 (ambos entram na lista de precache)

### COMP-013-004: Registro do service worker
**Responsabilidade**: registrar `public/sw.js` no carregamento do app, num componente
cliente mínimo montado uma vez no layout raiz. Não expõe nenhum controle de instalação
custom (A-013-004/SPEC-013 §4.2) — a instalação é conduzida inteiramente pelo mecanismo
nativo do navegador.
**Realiza**: FR-013-001 (parte), FR-013-002 (parte), FR-013-005 (ato de registro), NFR-013-008
**Interface pública**: `'use client'`, named export `ServiceWorkerRegistration` em
`mnemonicos-frontend/src/components/service-worker-registration.tsx`, montado em
`src/app/layout.tsx` junto do restante do shell. Efeito colateral isolado em `useEffect`
(chamada a `navigator.serviceWorker.register('/sw.js')` na montagem — não é busca de dado).
Teste: `src/components/service-worker-registration.test.tsx` (mock de
`navigator.serviceWorker.register`, confirma a chamada com o caminho correto; guarda por
`'serviceWorker' in navigator` para não quebrar em ambiente sem suporte).
**Dependências**: COMP-013-003

## 4. Fluxos principais

**Fluxo de instalação** (AC-013-001/002): EDITOR/ADMIN acessa o app num navegador que
satisfaz os critérios de instalabilidade (manifesto válido + COMP-013-001, ícones nos
tamanhos exigidos + COMP-013-002, service worker registrado + COMP-013-003/004, contexto
seguro + NFR-013-004) → o navegador oferece o prompt nativo (ou o menu "Adicionar à tela
inicial") → ao confirmar, o app é adicionado com ícone próprio e abre em modo `standalone`
nas aberturas seguintes. Nenhum controle de UI custom do sistema participa (A-013-004).

**Fluxo de carregamento/registro** (AC-013-003): a página carrega → `ServiceWorkerRegistration`
(COMP-013-004) monta e chama `navigator.serviceWorker.register('/sw.js')` → o navegador
instala e ativa `public/sw.js` (COMP-013-003), que popula o cache com a lista fixa de
assets estáticos do app-shell.

**Fluxo de fetch** (AC-013-004/008): o service worker intercepta toda requisição da página →
se é asset estático já precacheado, serve do cache (controle positivo) → se é navegação
(documento HTML de qualquer rota) ou rota de API/HTML autenticado, **nunca** serve do cache
— vai sempre à rede (NFR-013-001/005).

**Fluxo de atualização** (AC-013-006/012): novo deploy publica um `public/sw.js` com lista de
precache atualizada → o navegador detecta o SW novo e o instala em segundo plano, mas **não**
ativa sob a aba/janela já aberta (sem `skipWaiting()`) → numa reabertura subsequente, o SW
novo assume e serve a versão atualizada; a aba viva (inclusive com formulário de EDITOR não
salvo) continua na versão antiga até ser fechada e reaberta.

**Fluxo de kill-switch** (AC-013-009): o time de engenharia publica um `public/sw.js` cuja
versão embutida é a versão de "kill" → na reabertura seguinte do app instalado, o `activate`
do SW novo desregistra a si mesmo, limpa todos os caches e força o(s) cliente(s) a recarregar
uma vez → o app volta a se comportar como se não houvesse service worker, sem exigir
desinstalação/reinstalação manual.

## 5. Modelo de dados

Não há modelo de dados novo — nenhuma mudança em `mnemonicos-backend` (SPEC-013 §4.2), nenhum
model/coluna/migração. O que esta fatia persiste é infraestrutura de navegador (manifesto
servido estaticamente, Cache Storage do service worker, versão do app-shell instalado) — seu
par de leitura está coberto por FR-013-002 (app abre em modo `standalone` nas aberturas
seguintes) e FR-013-006 (versão atualizada reaparece na reabertura), conforme a nota da
própria SPEC (§5, "par de leitura", decisão 4.225). Nenhuma superfície de API/schema é
verificada nesta fatia (item 9 da Etapa 4 do contrato — n/a, sem entidade nova).

## 6. Decisões arquiteturais

### DEC-013-001: Service worker artesanal (vanilla), sem biblioteca de precache
**Contexto**: FR-013-005 e NFR-013-005/006 exigem um service worker que cubra só o app-shell
estático, nunca participando de navegação/API, com um caminho de recuperação (kill-switch).
A SPEC deixa a escolha de tecnologia explicitamente para o `/keelson:plan` (§4.2: "Escolha de
técnica (Workbox × service worker artesanal)... decisão de `/keelson:plan`, agnóstica de
stack nesta SPEC").
**Decisão**: service worker artesanal (vanilla JS, sem biblioteca), registrado por um
pequeno script cliente (COMP-013-004), com a lógica de cache e o kill-switch escritos à mão
em `public/sw.js` (COMP-013-003).
**Alternativas consideradas**:
- `serwist`/`next-pwa` (bibliotecas de precache para Next), descartada porque o valor
  principal delas é precache + fallback de navegação configurável — exatamente o que
  NFR-013-005 proíbe (navegação nunca serve do cache). Usá-las significaria configurar
  contra o comportamento default da própria biblioteca, além de somar uma dependência nova
  (superfície de cadeia de suprimento, OWASP A03:2025 Software Supply Chain Failures) para
  um escopo de cache deliberadamente mínimo (só assets estáticos).
**Consequências**: poucas dezenas de linhas sob controle total do time, sem dependência
externa a atualizar/auditar; em troca, qualquer estratégia de invalidação mais sofisticada
(ex.: stale-while-revalidate por rota, geração automática da lista de precache a partir do
manifest de build) exige escrever manualmente o que a biblioteca daria de graça.
**Reabrir se**: o escopo de cache crescer para precisar de estratégias de invalidação mais
sofisticadas que justifiquem a dependência.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova (nenhuma DEC anterior do slug trata service worker).

### DEC-013-002: Kill-switch por autodesregistro do service worker
**Contexto**: NFR-013-006 exige um caminho de recuperação executável por um único deploy do
frontend, sem exigir do usuário desinstalar o app ou limpar cache manualmente — o projeto
não tem pipeline de CI/CD (RISK-006-009, INDEX.md), então o mecanismo precisa ser autocontido
no próprio artefato do service worker, sem depender de infraestrutura nova.
**Decisão**: padrão "SW que se autodesregistra" — o service worker (COMP-013-003) embute uma
versão de build; quando o Diretor precisa desativar, o deploy do frontend publica uma versão
do SW cujo `activate` chama `self.registration.unregister()`, limpa todos os caches via
`caches.keys()`/`caches.delete()`, e força os clientes abertos a recarregar uma vez via
`clients.claim()` + mensagem de reload. Único artefato a redeployar é o próprio
`public/sw.js` — sem endpoint novo, sem flag de config runtime.
**Alternativas consideradas**:
- Endpoint de feature-flag consultado pelo service worker, descartada porque exigiria
  mudança no `mnemonicos-backend` (fora de escopo do BRIEF-013, §4.2) e uma superfície de
  rede nova (mais uma rota a autenticar/autorizar e auditar, OWASP A01 Broken Access
  Control como superfície adicional) só para desligar uma feature de benefício zero — custo
  desproporcional ao propósito de um kill-switch.
**Consequências**: a recuperação depende de um segundo deploy manual do frontend
(TRISK-013-003, RISK-013-004/RISK-006-009 — sem pipeline de CI/CD) — mas sem endpoint novo,
sem estado de configuração runtime, sem superfície de rede adicional a proteger.
**Reabrir se**: nunca — mecanismo interno, sem consumidor externo a migrar.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova.

## 7. Mapeamento FR -> componente

| FR | Componente | AC cobertos |
|----|------------|-------------|
| FR-013-001 | COMP-013-001, COMP-013-002, COMP-013-003, COMP-013-004 | AC-013-001 |
| FR-013-002 | COMP-013-001, COMP-013-004 | AC-013-001 |
| FR-013-003 | COMP-013-001, COMP-013-002 | AC-013-002 |
| FR-013-004 | COMP-013-001, COMP-013-002 | AC-013-002 |
| FR-013-005 | COMP-013-003, COMP-013-004 | AC-013-003 |
| FR-013-006 | COMP-013-003 | AC-013-006, AC-013-012 |
| NFR-013-001 | COMP-013-003 | AC-013-004 |
| NFR-013-002 | COMP-013-003 | AC-013-005 |
| NFR-013-003 | COMP-013-003 | AC-013-006, AC-013-012 |
| NFR-013-004 | n/a | AC-013-007 |
| NFR-013-005 | COMP-013-003 | AC-013-008 |
| NFR-013-006 | COMP-013-003 | AC-013-009 |
| NFR-013-007 | COMP-013-001, COMP-013-003 | AC-013-010 |
| NFR-013-008 | COMP-013-003, COMP-013-004 | AC-013-011 |

> NFR-013-004 (contexto seguro/HTTPS): n/a nesta fatia — infraestrutura de deploy
> existente (HTTPS/`localhost`), ver A-013-006.

## 8. Riscos técnicos

- **TRISK-013-001** `jsdom`/Jest não simula `ServiceWorkerGlobalScope` nem Cache Storage
  real — a suíte automatizada prova a lógica de decisão extraída em funções puras
  (`isStaticAssetRequest`, `isNavigationRequest`, `isKillVersion`, COMP-013-003), não o ciclo
  de vida real do service worker no navegador (mesma limitação que a SPEC já reconhece para
  AC-013-001/002 quanto ao prompt de instalação e ao chrome do sistema operacional, §7).
  Mitigação: extrair a lógica de decisão em funções puras testáveis isoladamente
  (isolamento de efeito colateral, perfil §4); o ciclo de vida real (install/activate/fetch
  disparados pelo navegador, cache efetivamente populado/limpo) é confirmado por inspeção
  manual no painel Application do Chrome/Edge DevTools no fecho do ciclo (gate 9, DoD item
  (a)) — mesmo padrão já usado para AC-013-001/002.
- **TRISK-013-002** Ordem de merge com PLAN-012 (F4, mesma superfície `app/`/`layout.tsx` do
  `mnemonicos-frontend` — herdado de RISK-013-005, SPEC-013 §9). Mitigação: branches isoladas
  em worktrees distintas (`C:/kwt/pwa` vs. a working tree principal) evitam conflito durante
  o desenvolvimento; a ordem de merge/reconciliação de `layout.tsx` é ato do Diretor.
- **TRISK-013-003** O kill-switch (DEC-013-002) depende de um segundo deploy manual do
  frontend — o mecanismo funciona tecnicamente por si só, mas o tempo de resposta a um
  incidente real depende de ato humano, sem pipeline de CI/CD (RISK-006-009/RISK-013-004).
  Mitigação: aceito nesta fatia, mesma condição de RISK-013-004; revisitar quando o projeto
  ganhar pipeline de CI/CD.

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Aderência à ficha/perfil validada
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates) — ressalva: AC-013-001 e
      AC-013-002 fecham por caminhada manual em dispositivo real (gate 9/`screenVerify`,
      precedente `HANDOFF-PLAN-003`), não por teste automatizado — prompt de instalação e
      chrome do sistema operacional não são simuláveis (nota da própria SPEC, §7). Os
      demais ACs (003–012) são cobertos por teste automatizado das funções puras extraídas
      (COMP-013-003) e do componente de registro (COMP-013-004), complementado por inspeção
      manual no painel Application (DevTools) onde o comportamento depende do ciclo de vida
      real do service worker no navegador (TRISK-013-001).
- [ ] Métrica da SPEC operacional (§1.3, natureza mista) — este DoD cobre **só o item (a)**:
      conformidade externa apurada por inspeção manual no painel Application do Chrome/Edge
      DevTools (Manifest + Service Workers), rodada no fecho do ciclo (gate 9); dono
      Tech Lead/QA. O **item (b)** (observacional — nº de EDITOR/ADMIN com o app instalado e
      aberturas em `display-mode: standalone`, janela de 90 dias a partir do 1º deploy na
      origem de produção, A-013-006) **não** entra no DoD deste PLAN — é pendência de
      veredito de métrica registrada no INDEX, acompanhamento pós-Entrega (dono Tech
      Lead/Diretor).

## 10. Não coberto por este PLAN

- Item (b) da métrica §1.3 da SPEC (observacional, janela de 90 dias pós-1º deploy em
  produção) — pendência de veredito pós-Entrega, não é trabalho de implementação.
- Prova de instalabilidade (AC-013-001/002) na origem HTTPS real de produção — não
  confirmada em nenhum artefato do workspace hoje (A-013-006/E-01 SPEC-013); fecha em
  `localhost` nesta fatia, prova na origem real fica como pendência de handoff ao deploy
  (mesmo padrão `pendente_handoff` de `HANDOFF-PLAN-003`).
- Tudo já listado no Out-of-scope §4.2 da SPEC: funcionamento offline de dados/API, push
  notifications, qualquer mudança no `mnemonicos-backend`, controle de instalação custom
  (banner/botão próprio), distribuição via loja de aplicativos, segmento/rota com
  comportamento de PWA diferenciado do resto do sistema, refinamento de design de marca dos
  ícones/cores (incluindo ícone `maskable` dedicado).
