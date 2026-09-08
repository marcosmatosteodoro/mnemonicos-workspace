# PLAN-021: Rewrite same-origin do cookie de sessão em produção

**Slug**: producao-material
**Status**: Draft
**Versão**: 0.1
**Autor**: keelson (scribe)
**Data**: 2026-09-07

## Aderência a guidelines

**Ficha/perfil de linguagem**: frontend — Next 16 (`guidelines/project/frontend/next-16.md`;
Next.js 16.3.2 App Router, `next.config.ts` tipado, RTK Query `fetchBaseQuery`, Jest 30 +
Testing Library). Esta fatia é **só frontend** — nenhum arquivo de `mnemonicos-backend` muda
neste PLAN (Etapa 2 desta execução concluiu que `CORS_ORIGINS`/`verifyOrigin` não precisam de
ajuste, ver DEC-021-001 Consequências); o perfil backend (`guidelines/project/backend/
node-22.md` §6.3/6.5) é referenciado só para confirmar essa conclusão, não para alterar código
lá.

**Stack vigente herdado**: `next.config.ts` já existe com `headers()` (CSP-lite) — ganha
`rewrites()`, API nativa do Next, sem dependência nova (`node_modules/next/dist/docs/01-app/
03-api-reference/05-config/01-next-config-js/rewrites.md`, seção "Rewriting to an external
URL"). `fetchBaseQuery({ baseUrl, credentials: 'include' })` já em uso em
`mnemonicos-frontend/src/store/api.ts:137-141` — só o valor de `baseUrl` muda. `env.ts`
(`mnemonicos-frontend/src/lib/env.ts`) já documentado como módulo **só de variáveis
`NEXT_PUBLIC_*`** — a variável nova deste PLAN (`BACKEND_API_URL`) é server-only por design e
por isso é lida direto de `process.env` em `next.config.ts`, nunca passando por `env.ts`.

**Padrão arquitetural seguido**: "Backend for Frontend" / rewrite same-origin, documentado em
`node_modules/next/dist/docs/01-app/02-guides/backend-for-frontend.md` (seção "Proxying to a
backend" — cita `rewrites()` do `next.config.js` como uma das duas formas suportadas, ao lado
de um Route Handler manual). DEC-021-002 registra por que este PLAN escolhe `rewrites()` e não
a alternativa de Route Handler manual nem o arquivo `proxy.ts` (guard de navegação client-side
do KAN-75, `mnemonicos-frontend/src/proxy.ts` — mecanismo Next 16 renomeado de `middleware`
para `proxy`, `node_modules/next/dist/docs/.../file-conventions/proxy.md`; **só um arquivo
`proxy` é permitido por projeto**, confirmado na doc).

**Decisões irreversíveis do slug tocadas**: nenhuma (`docs/producao-material/INDEX.md`, seção
"Decisões irreversíveis" — vazia; as 12 DECs de PLAN-003 são todas reversíveis). Este PLAN
**reabre** DEC-003-004 (PLAN-003 §6, "Cookies de sessão") pela condição que ela mesma previu —
"frontend e backend forem servidos de domínios distintos em produção" — confirmada:
`mnemonicos-frontend` e `mnemonicos-backend` são dois sites Vercel distintos (`*.vercel.app`,
cada subdomínio é uma entrada própria na Public Suffix List, logo dois "sites" diferentes para
fins de `SameSite`). DEC-021-001 **substitui**, só para a topologia de produção, a estratégia
de *transporte* do cookie que DEC-003-004 assumia sob "mesmo site"; os atributos do cookie em
si (`httpOnly`, `sameSite: 'lax'`, `secure: env.COOKIE_SECURE`) e o `verifyOrigin` de
`auth.routes.ts` permanecem **intocados** — DEC-003-004 segue vigente para dev local, onde
`localhost:3000`/`localhost:3333` já são "mesmo site" por natureza.

**Decisões irreversíveis de outros slugs em conflito**: nenhuma — `docs/producao-material/
INDEX.md` é o único `INDEX.md` existente no workspace hoje (`docs/infra-vercel/` não tem
`INDEX.md`, único artefato ali é um brief avulso sobre o entrypoint serverless do backend,
sem relação com este PLAN).

**Exceções aos guidelines**: nenhuma.

## Cobertura

**SPEC referenciada**: SPEC-002
**Slice declarado**: re-cobertura técnica (Caso B, `--slice`) — este PLAN não adiciona FR novo.
Ele re-cobre a **estratégia técnica** de FR-002-001 (emissão de cookie de sessão) e
NFR-002-008 (cookie same-site) para a topologia real de produção — dois sites Vercel
distintos —, que PLAN-003 não endereçava (DEC-003-004 assumia mesmo site). Os demais
FRs/ACs de SPEC-002 (autorização, gestão de contas, logout, rotação, etc.) permanecem
cobertos por PLAN-003, intocados por este PLAN.

**FRs cobertos** (re-cobertura técnica — contrato observável não muda, só a estratégia de
rede que o realiza em produção; ver "Slice declarado" acima e DEC-021-001):
- FR-002-001

**NFRs cobertos** (idem — a cláusula "política de submissão same-site" passa a se cumprir de
fato em produção; os valores das flags do cookie não mudam):
- NFR-002-008

**Cobertura agregada do slug**:
- Total na SPEC: 24 FRs + 9 NFRs = 33
- Cobertos por planos anteriores: 33/33 (PLAN-003, 16/16 TASKs Done)
- Cobertos por este: 0 novos — re-cobertura técnica de FR-002-001 e NFR-002-008, já
  contabilizados em PLAN-003
- Gap restante: 0

(SPEC-002 declara FEATs — FR-002-001 pertence a FEAT-002-001, Autenticação de sessão; este
PLAN não muda a cobertura de FEAT, só a estratégia técnica de um FR dentro dela.)

## 1. Visão técnica

O problema é de rede, não de produto: `mnemonicos-frontend` e `mnemonicos-backend` são dois
sites `*.vercel.app` distintos em produção. `store/api.ts` (COMP-003, PLAN-003) chama o
backend com URL absoluta (`env.apiUrl`, `NEXT_PUBLIC_API_URL`) e `credentials: 'include'` —
uma chamada cross-origin **e cross-site** do ponto de vista do navegador. O cookie de sessão
emitido pelo backend (`mnemo_access`/`mnemo_refresh`, DEC-003-004) usa `sameSite: 'lax'`, que
exige "mesmo site"; sob dois sites `.vercel.app` distintos ele nunca é persistido pelo
navegador — confirmado por execução real com Playwright citada no briefing desta execução:
`POST /auth/login` responde 200 com o `SessionUser`, mas sem nenhum header `Set-Cookie`
observável e `document.cookie` vazio depois.

A correção (DEC-021-001) não muda nenhuma flag do cookie nem o mecanismo de `verifyOrigin`:
ela muda a **topologia de rede** para que a chamada deixe de ser cross-site do ponto de vista
do navegador. `next.config.ts` ganha um `rewrites()` (COMP-021-001) que mapeia
`/api/v1/:path*` para o backend real; `store/api.ts` passa a chamar sua **própria origem**
(`window.location.origin`, COMP-021-002) em vez do host absoluto do backend. Do ponto de vista
do navegador, toda chamada de API passa a ser same-origin ao `mnemonicos-frontend.vercel.app`
— o `Set-Cookie` da resposta (repassado pelo rewrite) é gravado sob o domínio do frontend, e
`sameSite: 'lax'` volta a funcionar sem mudança nenhuma no backend.

Dois eixos técnicos secundários, cada um com decisão própria (§6):

- **Como implementar o rewrite same-origin** (DEC-021-002): `rewrites()` nativo do
  `next.config.ts`, não um Route Handler manual nem o arquivo `proxy.ts` já existente (guard
  de navegação do KAN-75, mecanismo diferente e nome já ocupado — só 1 arquivo `proxy` é
  permitido por projeto).
- **Como resolver a URL base do RTK Query sem quebrar em Node** (DEC-021-003): `fetch`/
  `Request` do Node (usado nos testes Jest em `@jest-environment node`, `mnemonicos-frontend/
  src/store/api.test.ts:1-3`) **não aceita URL relativa** — `new Request('/api/v1/...')`
  lança fora de um contexto de browser. `resolveApiBaseUrl()` resolve para
  `window.location.origin + '/api/v1'` quando `window` existe (browser real) e cai num
  placeholder absoluto fora dele (SSR do próprio Client Component, testes) — nunca há fetch
  real desta store fora de interação do usuário no browser, então o placeholder nunca é
  de fato resolvido pela rede.

**Estratégia de teste**: nada nesta fatia pode provar, localmente, que o `Set-Cookie` chega
intacto através de dois sites `*.vercel.app` reais — não existe ambiente de staging
cross-site (TRISK-021-001/002, mesma classe de resíduo já registrada em
`HANDOFF-PLAN-013.md` para o ciclo login/logout com SW ativo). O que este PLAN prova
automaticamente: (a) `rewrites()` de `next.config.ts` produz a regra esperada, com e sem
`BACKEND_API_URL` configurada (`mnemonicos-frontend/next.config.test.ts`, novo); (b)
`resolveApiBaseUrl()` resolve para a origem do documento no browser
(`mnemonicos-frontend/src/store/api.browser-base-url.test.ts`, novo, `@jest-environment
jsdom`) e para o placeholder fora dele (extensão de `api.test.ts`, `@jest-environment node`);
(c) **não-regressão**: a suíte inteira de `api.test.ts` — incluindo os retries S1/S1b que
exercitam `isPublicAuthRequest` via dispatch real de login/refresh/logout com 401 mockado —
continua verde sem nenhuma alteração de asserção, porque `isPublicAuthRequest` compara
`args.url` (caminho relativo declarado em cada endpoint, ex. `/auth/login`) **antes** do
`baseUrl` ser aplicado (`joinUrls(baseUrl, url)`, `fetchBaseQuery.ts:295`) — a dedução do
code-scout sobre este ponto se confirma por leitura direta do código, não é mais dedução. O
resíduo real (Set-Cookie/verifyOrigin sob dois sites de verdade) fica para verificação manual
pós-deploy (gate 9, DoD item dedicado).

## 2. Stack e dependências

Nenhuma dependência nova. Reuso integral do que já existe:

| Peça | Origem |
|---|---|
| `rewrites()` em `next.config.ts` | API nativa do Next 16, sem pacote novo (`node_modules/next/dist/docs/.../rewrites.md`) |
| `fetchBaseQuery({ baseUrl, credentials: 'include' })` | já em uso em `store/api.ts` (PLAN-003) |
| `window.location.origin` | Web API nativa |
| Jest 30 + Testing Library, `jsdom` (default) e `@jest-environment node` (override pontual) | `jest.config.ts`/`api.test.ts` existentes |
| TypeScript 6 `strict` | `tsconfig.json` existente |

## 3. Componentes

### COMP-021-001: Rewrite same-origin em `next.config.ts`
**Responsabilidade**: mapear `/api/v1/:path*` (chamado pelo browser sob a própria origem do
`mnemonicos-frontend`) para o backend real (`mnemonicos-backend`), via `rewrites()` — a
requisição deixa de ser cross-site do ponto de vista do navegador; o hop real para o backend
acontece no roteador do Next, não mais no browser.
**Realiza**: FR-002-001, NFR-002-008
**Interface pública**: edição em `mnemonicos-frontend/next.config.ts`. Nova constante de
módulo `const backendApiUrl = process.env.BACKEND_API_URL ?? 'http://localhost:3333';`
(server-only — lida direto de `process.env`, nunca via `env.ts`, que é documentado como
"só `NEXT_PUBLIC_*`, este módulo é enviado ao browser"). Novo método `async rewrites()`:
```ts
async rewrites() {
  return [
    {
      source: '/api/v1/:path*',
      destination: `${backendApiUrl}/api/v1/:path*`,
    },
  ];
},
```
`headers()` existente (CSP-lite) permanece inalterado. Nova variável de ambiente
`BACKEND_API_URL` documentada em `mnemonicos-frontend/.env.example` (comentário: "URL real do
backend — server-only, nunca embutida no bundle do browser") e na tabela de variáveis do
`README.md` (seção "Deploy (Vercel)"), ao lado de `NEXT_PUBLIC_API_URL`/`NEXT_PUBLIC_APP_NAME`
(esta última removida por COMP-021-003).
Teste: `mnemonicos-frontend/next.config.test.ts` (novo) — `jest.resetModules()` +
reimport com `process.env.BACKEND_API_URL` definida e ausente, confirmando a regra exata
retornada por `rewrites()` nos dois casos (com valor configurado e caindo no default de dev
local) — mesmo padrão de "testar o caminho com valor fornecido, não só o default" do perfil
backend §6.4, aplicado aqui a uma env var de rede em vez de segurança.
**Dependências**: nenhuma

### COMP-021-002: `resolveApiBaseUrl()` e `baseUrl` same-origin em `store/api.ts`
**Responsabilidade**: resolver a base do RTK Query para a própria origem do documento no
browser (ativando o rewrite de COMP-021-001), com um fallback absoluto seguro fora do browser
(SSR do próprio Client Component, testes Jest em `@jest-environment node`) — sem isso,
`new Request('/api/v1/...')` (URL relativa) lança em qualquer ambiente sem `window`
(`fetchBaseQuery.ts:297`, `const request = new Request(url, config)`, chamado
independentemente de o `fetch` global estar mockado ou não).
**Realiza**: FR-002-001, NFR-002-008
**Interface pública**: edição em `mnemonicos-frontend/src/store/api.ts`. Remove o import
`import { env } from '@/lib/env';` (único uso no arquivo era `env.apiUrl`). Nova função
exportada:
```ts
export function resolveApiBaseUrl(): string {
  return typeof window === 'undefined'
    ? 'http://localhost/api/v1'
    : `${window.location.origin}/api/v1`;
}
```
`rawBaseQuery` passa a usar `baseUrl: resolveApiBaseUrl()` no lugar de
`` `${env.apiUrl}/api/v1` `` (linha 137-141 atual); `credentials: 'include'` inalterado.
`isPublicAuthRequest` (privada, não exportada) e `baseQueryWithReauth` **não mudam** —
operam sobre `args.url` (caminho relativo do endpoint), que independe do `baseUrl`.
Teste: `mnemonicos-frontend/src/store/api.browser-base-url.test.ts` (novo,
`@jest-environment jsdom`) — `resolveApiBaseUrl()` retorna `` `${window.location.origin}/api/v1` ``;
extensão de `mnemonicos-frontend/src/store/api.test.ts` (existente, `@jest-environment node`)
— novo caso confirmando `resolveApiBaseUrl()` cai no placeholder absoluto fora do browser, e
**nenhuma outra asserção da suíte muda** (não-regressão de `isPublicAuthRequest`/S1/S1b, ver
§1).
**Dependências**: COMP-021-001 <!-- sem o rewrite montado, uma chamada same-origin cairia em 404 — os dois componentes só funcionam juntos -->

### COMP-021-003: Remoção de `NEXT_PUBLIC_API_URL`/`env.apiUrl` (configuração morta)
**Responsabilidade**: `env.apiUrl` (`mnemonicos-frontend/src/lib/env.ts:6`) tinha
`store/api.ts` como único consumidor (confirmado por busca no repositório); após
COMP-021-002 esse consumo desaparece. Manter o campo seria configuração morta que expõe
desnecessariamente a URL do backend no bundle do browser (o prefixo `NEXT_PUBLIC_` a embute
por design) sem nenhum código lendo o valor.
**Realiza**: nenhuma <!-- limpeza decorrente de COMP-021-002, evita resíduo de configuração morta e a exposição pública desnecessária que ele carregava -->
**Interface pública**: edição em `mnemonicos-frontend/src/lib/env.ts` — remove o campo
`apiUrl` do objeto `env` (mantém `appName`). Edição em `mnemonicos-frontend/.env.example` —
remove `NEXT_PUBLIC_API_URL` (substituída por `BACKEND_API_URL`, COMP-021-001). Edição em
`mnemonicos-frontend/README.md` — linha 25 (`cp .env.example .env.local # ajuste
NEXT_PUBLIC_API_URL`) e a tabela de variáveis da seção "Deploy (Vercel)" (linhas 94-99)
atualizadas para citar `BACKEND_API_URL` no lugar de `NEXT_PUBLIC_API_URL`.
Teste: nenhum teste dedicado — a ausência de referência a `env.apiUrl`/`NEXT_PUBLIC_API_URL`
em `src/` é verificável por leitura (censo grep, mesmo padrão de saneamento usado em
PLAN-006/TASK-006-010); `env.ts` não tem suíte própria hoje e este PLAN não cria uma só para
a remoção de um campo.
**Dependências**: COMP-021-002

## 4. Fluxos principais

**Fluxo antes desta fatia (problema, AC-002-001/NFR-002-008 falhando em produção)**: browser
em `mnemonicos-frontend.vercel.app` → `fetch` direto para
`${NEXT_PUBLIC_API_URL}/api/v1/auth/login` (`mnemonicos-backend.vercel.app`, outro site na
Public Suffix List) → CORS permite (`Origin` do frontend está em `CORS_ORIGINS`) →
`verifyOrigin` permite pelo mesmo motivo → backend emite `Set-Cookie: mnemo_access=...;
SameSite=Lax` + `Set-Cookie: mnemo_refresh=...; SameSite=Lax` → o navegador trata a resposta
como cross-**site** (eTLD+1 diferente) e não persiste os cookies → próxima requisição chega
sem sessão.

**Fluxo depois desta fatia** (COMP-021-001 + COMP-021-002): browser →
`fetch` para a própria origem, `` `${window.location.origin}/api/v1/auth/login` `` (mesmo
domínio do documento) → o roteador do Next casa `/api/v1/:path*` (COMP-021-001) e encaminha a
requisição para `${BACKEND_API_URL}/api/v1/auth/login` como um hop de rede interno ao processo
do Next, não mais uma chamada do browser → backend processa exatamente como hoje
(`verifyOrigin`, `login`, `setSessionCookies`) e responde com os dois `Set-Cookie` → o
roteador do Next repassa a resposta (inclusive os dois `Set-Cookie`, TRISK-021-002) de volta
ao browser → do ponto de vista do navegador, a resposta inteira veio do próprio
`mnemonicos-frontend.vercel.app` — os cookies `SameSite=Lax` são gravados sob esse domínio sem
exceção, e a requisição seguinte já os envia de volta. AC-002-001/NFR-002-008 passam a se
cumprir em produção sem nenhuma mudança nas flags do cookie nem no `verifyOrigin`.

**Fluxo de dev local** (inalterado em espírito, mecanismo unificado com produção): frontend em
`http://localhost:3000`, backend em `http://localhost:3333` — hoje já funcionam por serem
"mesmo site" (mesmo host `localhost`, portas diferentes); depois desta fatia, o mesmo
`rewrites()` também está ativo em `next dev` (`BACKEND_API_URL` ausente → cai no default
`http://localhost:3333`), então o comportamento de rede em dev passa a espelhar exatamente o
de produção — uma chamada same-origin ao próprio `localhost:3000`, roteada pelo Next para o
backend local.

## 5. Modelo de dados

Não aplicável — nenhuma mudança em `mnemonicos-backend`, nenhum model/coluna/migração. Toda a
mudança é de configuração de rede (`next.config.ts`) e de resolução de URL no cliente
(`store/api.ts`) do lado do `mnemonicos-frontend`. Nenhuma superfície de API/schema nova é
introduzida (item 9 da Etapa 4 do contrato de `/keelson:plan` — n/a, sem entidade nova; os
endpoints de `auth.routes.ts` já existem e não mudam de contrato).

## 6. Decisões arquiteturais

### DEC-021-001: Proxy same-origin via rewrite (não `SameSite=None` + anti-CSRF)
**Contexto**: NFR-002-008 exige cookie same-site; DEC-003-004 (PLAN-003) implementou
`sameSite: 'lax'` assumindo mesmo site, com `Reabrir se: frontend e backend forem servidos de
domínios distintos em produção`. Essa condição se confirmou: `mnemonicos-frontend` e
`mnemonicos-backend` são dois sites Vercel distintos (`*.vercel.app`, cada subdomínio conta
como uma entrada própria na Public Suffix List — dois "sites" diferentes para fins de
`SameSite`, não apenas duas origens). Confirmado por execução real com Playwright: `POST
/auth/login` responde 200 com o `SessionUser`, mas sem nenhum header `Set-Cookie` observável
e `document.cookie` vazio depois.
**Decisão**: o frontend passa a expor as chamadas de API sob o próprio domínio via
`rewrites()` do `next.config.ts` (`/api/v1/:path*` → backend real, COMP-021-001), e
`store/api.ts` passa a usar uma base **same-origin** resolvida em runtime no browser
(COMP-021-002) em vez do host absoluto do backend. Do ponto de vista do navegador, toda
chamada de API passa a ser same-origin ao `mnemonicos-frontend.vercel.app` — o `Set-Cookie` da
resposta (repassado pelo rewrite) é gravado sob o domínio do frontend, e `sameSite: 'lax'`
volta a funcionar sem mudança nenhuma no backend. `CORS_ORIGINS`/`verifyOrigin`
(`mnemonicos-backend/src/app.ts:24-36`, `auth.routes.ts:86-93`) **não mudam**: o único
consumidor de `env.apiUrl` no repositório era `store/api.ts` (COMP-021-003 remove o campo
morto) — não há, hoje, nenhum caminho que ainda precise chamar o backend diretamente fora do
rewrite, então manter `CORS_ORIGINS` como está (incluindo o domínio de produção do frontend)
é suficiente: se o `Origin` do browser for de fato encaminhado pelo rewrite até o backend
(TRISK-021-001), ele já casa com a allowlist existente; se não for encaminhado, cai no ramo
"sem Origin = servidor-a-servidor", que já é fail-open por desenho de DEC-003-004
("Requisição sem nenhum dos dois (curl, servidor-a-servidor) não é vetor de CSRF de navegador
e segue"). Nenhuma das duas hipóteses exige mudar `CORS_ORIGINS`/`verifyOrigin` nesta rodada.
**Alternativas consideradas**:
- `SameSite=None` + `Secure` + token anti-CSRF novo (a alternativa que o comentário de
  DEC-003-004 já cogitava), descartada porque reabre a superfície de CSRF que
  `SameSite=Lax` fecha de graça hoje — exigiria implementar **e** manter uma defesa de token
  anti-CSRF nova (double-submit ou synchronizer token) em todas as rotas mutantes autenticadas
  por cookie (`POST /auth/logout`, `POST /auth/change-password`, `POST/PATCH /users/*`), mais
  testes de negação para cada uma, só para compensar uma fraqueza que o proxy same-origin
  evita de origem. Também mantém duas origens públicas para a mesma API (superfície maior,
  `CORS_ORIGINS` permanece necessário do mesmo jeito que hoje).
- Mover backend e frontend para o mesmo domínio via DNS/reverse proxy de infraestrutura
  (subpath, ex. `app.dominio.com` + `app.dominio.com/api`), descartada porque é decisão de
  infraestrutura fora do controle deste ciclo — não foi cogitada pelo Diretor e envolve DNS/
  certificado fora do escopo de um PLAN de frontend.
**Consequências**: nenhuma flag de cookie muda (`httpOnly`, `sameSite: 'lax'`, `secure`
permanecem exatamente como DEC-003-004 definiu); `verifyOrigin`/`CORS_ORIGINS` do backend
permanecem intocados nesta rodada (ver "Decisão" acima). O comportamento real de rede sob
dois sites Vercel distintos (encaminhamento de `Origin`/múltiplos `Set-Cookie` pelo rewrite)
não é verificável localmente — TRISK-021-001/002, resíduo de verificação manual pós-deploy.
**Reabrir se**: um consumidor externo (app mobile nativo, outro frontend) precisar chamar o
backend diretamente sem passar pelo rewrite — nesse caso a rota direta volta a existir e a
decisão precisa reconsiderar CORS/SameSite para esse caminho adicional, possivelmente
reabrindo a alternativa de `SameSite=None` + anti-CSRF só para esse consumidor.
**Irreversível**: não
**Aderência à ficha/perfil**: herdada (aplica NFR-002-008 e a postura de DEC-003-004);
substitui, só para a topologia de produção, a estratégia de *transporte* do cookie que
DEC-003-004 assumia sob "mesmo site" — as flags do cookie em si e `verifyOrigin` do PLAN-003
permanecem intocados.

### DEC-021-002: Mecanismo do rewrite — `rewrites()` de `next.config.ts`, não Route Handler manual nem `proxy.ts`
**Contexto**: `node_modules/next/dist/docs/01-app/02-guides/backend-for-frontend.md` (seção
"Proxying to a backend") documenta duas formas de proxyar para um backend: `rewrites()` do
`next.config.js`, ou um Route Handler manual (`app/api/[...slug]/route.ts` com
`new Request(proxyURL, request)` + `return fetch(proxyRequest)`). O código do exemplo da doc
retorna a `Response` do backend diretamente como resposta do Route Handler. O frontend já tem
um arquivo `proxy.ts` (`mnemonicos-frontend/src/proxy.ts`, mecanismo Next 16 renomeado de
`middleware` — `node_modules/next/dist/docs/.../file-conventions/proxy.md`) que é o guard de
navegação client-side do KAN-75 (redireciona para `/login` sem cookie de acesso,
`matcher: ['/studio', '/studio/:path*', '/content', '/content/:path*']`) — mecanismo
totalmente diferente do rewrite de rede desta fatia, apesar do nome parecido.
**Decisão**: `rewrites()` em `next.config.ts` (COMP-021-001) — proxy nativo da camada de
roteamento do Next, sem código de aplicação a manter.
**Alternativas consideradas**:
- Route Handler manual (`app/api/[...path]/route.ts`, `fetch(proxyRequest)`), descartada
  porque exigiria reconstruir manualmente a preservação de **múltiplos** `Set-Cookie` — este
  PLAN emite dois cookies por login (`mnemo_access` + `mnemo_refresh`, DEC-003-004) — e a
  `Headers` do Fetch API mescla múltiplos valores do mesmo nome de header (`Set-Cookie`
  incluso, salvo tratamento especial que nem toda API/runtime garante) ao ser lida via
  `.get()`/iterada de forma ingênua; `return fetch(proxyRequest)` direto arrisca corromper
  exatamente o dado que esta fatia existe para consertar. `rewrites()` evita esse código de
  aplicação por completo.
- Implementar o encaminhamento dentro de `proxy.ts` (reaproveitando o arquivo existente),
  descartada porque a doc confirma **"Only one `proxy` file is allowed per project"** — juntar
  o guard de navegação client-side do KAN-75 (leitura de cookie, redirect) com lógica de
  reescrita de rede de servidor no mesmo arquivo aumentaria o acoplamento e o raio de teste de
  `proxy.test.ts` (hoje escopado só ao guard) sem nenhum ganho sobre usar `rewrites()`
  dedicado.
**Consequências**: zero código de aplicação para manter o encaminhamento; a garantia de
preservação de headers (inclusive múltiplos `Set-Cookie`) fica delegada à implementação
interna do roteador do Next, não documentada em detalhe na doc bundled — TRISK-021-002.
**Reabrir se**: a verificação manual pós-deploy (TRISK-021-001/002) revelar que o rewrite
nativo não preserva `Origin`/`Set-Cookie` como esperado — nesse caso, um Route Handler manual
com reconstrução explícita de `Set-Cookie` (`headers.getSetCookie()` ou equivalente da runtime
de produção) vira a alternativa a implementar.
**Irreversível**: não
**Aderência à ficha/perfil**: nova (nenhuma DEC anterior do slug trata rewrite de rede).

### DEC-021-003: `resolveApiBaseUrl()` via `window.location.origin`, com fallback absoluto fora do browser
**Contexto**: `fetchBaseQuery` constrói `new Request(url, config)` (`fetchBaseQuery.ts:297`)
**antes** de chamar `fetchFn`/`fetch` — isso acontece mesmo com o `fetch` global mockado nos
testes (`jest.spyOn(globalThis, 'fetch')`, `api.test.ts:68`), porque o mock intercepta só a
chamada de `fetch`, não a construção do `Request` que a antecede. O Node (`undici`, usado nos
testes com `@jest-environment node`) não aceita URL relativa nesse construtor — lança
`TypeError` fora de um contexto de browser com `window`/`document.baseURI`. Um `baseUrl`
puramente relativo (`'/api/v1'`) quebraria toda a suíte `api.test.ts` existente.
**Decisão**: `resolveApiBaseUrl()` retorna `` `${window.location.origin}/api/v1` `` quando
`window` existe (todo uso real desta store — client component, interação do usuário) e um
placeholder absoluto fixo (`'http://localhost/api/v1'`) quando não existe (SSR do próprio
Client Component antes da hidratação, testes Jest em ambiente `node`) — placeholder nunca
resolvido de fato pela rede, porque nenhuma chamada desta store acontece fora de interação
client-side (mutations disparadas por evento de UI, não durante o render inicial).
**Alternativas consideradas**:
- `baseUrl: '/api/v1'` (string relativa pura), descartada porque quebra
  `new Request(url, config)` em qualquer ambiente sem `window` — toda a suíte `api.test.ts`
  (`@jest-environment node`) pararia de funcionar, não só os casos deste PLAN.
- Manter `baseUrl` absoluto apontando para `env.apiUrl`/`NEXT_PUBLIC_API_URL` (o host real do
  backend), descartada porque não resolve o problema original: a chamada continuaria
  cross-site do ponto de vista do navegador, exatamente a causa raiz que DEC-021-001 existe
  para eliminar.
**Consequências**: nenhuma mudança de asserção na suíte `api.test.ts` existente (pathname
continua `/api/v1/...` independentemente do host); dois casos de teste novos cobrem os dois
ramos (`api.browser-base-url.test.ts`, jsdom; extensão de `api.test.ts`, node).
**Reabrir se**: nunca — o comportamento de `new Request()` sobre URL relativa é uma
característica de plataforma (Fetch API/Node), não uma escolha de produto revisável.
**Irreversível**: não
**Aderência à ficha/perfil**: nova (nenhuma DEC anterior do slug trata resolução de `baseUrl`).

## 7. Mapeamento FR -> componente

| FR/NFR | Componente | AC cobertos |
|----|------------|-------------|
| FR-002-001 | COMP-021-001, COMP-021-002 | AC-002-001 |
| NFR-002-008 | COMP-021-001, COMP-021-002 | AC-002-001 |
| — | COMP-021-003 | — (limpeza de configuração morta, sem FR/NFR/AC próprio — ver §3) |

## 8. Riscos técnicos

- **TRISK-021-001** O encaminhamento do header `Origin`/`Referer` pelo `rewrites()` para uma
  URL externa não é documentado em detalhe em `node_modules/next/dist/docs` — se o Next não
  repassar o `Origin` original do browser até o backend (ou substituí-lo por um valor
  sintético), `verifyOrigin` (`auth.routes.ts:86-93`) perde a capacidade de distinguir uma
  requisição forjada cross-site de uma legítima vinda do rewrite. Duas hipóteses, nenhuma
  verificável sem um deploy real cross-site (mitigação: verificação manual pós-deploy, gate 9
  — uma requisição forjada de outra origem contra `POST /api/v1/auth/change-password`
  publicado, confirmando 403; e uma chamada legítima do próprio frontend, confirmando 200/204).
  Sem ambiente de staging cross-site (mesma classe de lacuna já registrada em
  `HANDOFF-PLAN-013.md`), este risco só fecha em produção real.
- **TRISK-021-002** A preservação de **múltiplos** `Set-Cookie` (`mnemo_access` +
  `mnemo_refresh`) através do `rewrites()` para URL externa não é documentada explicitamente
  na doc bundled — DEC-021-002 escolheu `rewrites()` justamente por ser o proxy nativo da
  camada de roteamento (menos risco que reconstruir a resposta à mão), mas isso não é uma
  garantia confirmada. Mitigação: verificação manual pós-deploy (gate 9) — inspecionar a aba
  de rede do navegador contra o domínio real do frontend após login, confirmando 2 headers
  `Set-Cookie` distintos (não um único valor mesclado por vírgula) e `document.cookie`
  refletindo a sessão.
- **TRISK-021-003** `BACKEND_API_URL` (env var nova, server-only) precisa ser configurada no
  painel Vercel do projeto **frontend** antes do deploy. Ausente, o rewrite cai no fallback de
  dev local (`http://localhost:3333`, COMP-021-001) — toda chamada de API em produção falha de
  forma visível (erro de rede/timeout), nunca silenciosamente. Mitigação: checklist de deploy
  do Diretor confirma a env var no ambiente de produção antes do merge; o fallback e o motivo
  dele ficam comentados no próprio `next.config.ts`.

## 9. Definition of Done deste PLAN

- [ ] FR-002-001 e NFR-002-008 re-cobertos: implementação satisfaz AC-002-001 sob a nova
      topologia (rewrite same-origin).
- [ ] Decisões DEC refletidas no código — DEC-021-001, DEC-021-002, DEC-021-003.
- [ ] Aderência à ficha/perfil validada (perfil frontend `next-16.md`; perfil backend
      `node-22.md` referenciado só para confirmar ausência de mudança necessária).
- [ ] Todos os ACs automatizáveis localmente cobertos por teste (gate 1) —
      `next.config.test.ts` (novo), `api.browser-base-url.test.ts` (novo),
      extensão de `api.test.ts` (existente) sem nenhuma asserção alterada nos casos já
      existentes (não-regressão de `isPublicAuthRequest`/S1/S1b).
- [ ] Métrica da SPEC operacional: não aplicável a este PLAN — a métrica §1.3 de SPEC-002 já
      opera desde PLAN-003 (`route-authz-matrix`, autorização) e este PLAN não a altera; nenhum
      evento/instrumentação novo é introduzido.
- [ ] Verificação manual pós-deploy (gate 9, residual — TRISK-021-001/002): em produção real,
      `POST /api/v1/auth/login` grava os dois cookies (`mnemo_access`/`mnemo_refresh`) sob o
      domínio do `mnemonicos-frontend`, `document.cookie` reflete a sessão, e uma requisição
      forjada de outra origem contra uma rota mutante autenticada por cookie continua
      recusada por `verifyOrigin`.

## 10. Não coberto por este PLAN

- Revisão do mecanismo `verifyOrigin`/CSRF em si (fora, salvo achado da triagem técnica desta
  execução) — nenhum achado obrigou mudança nesta rodada; TRISK-021-001 documenta o resíduo de
  verificação que pode reabrir essa revisão se o comportamento real de produção divergir do
  esperado.
- Qualquer mudança em `CORS_ORIGINS` do backend — a triagem concluiu que não é necessária
  (DEC-021-001 "Decisão"); reabrir se TRISK-021-001 confirmar a necessidade em produção real.
- Mover backend e frontend para o mesmo domínio via DNS/reverse proxy de infraestrutura —
  alternativa de infraestrutura não cogitada pelo Diretor, fora do controle deste ciclo
  (decisão de infra, ver DEC-021-001 "Alternativas consideradas").
- Confirmação da origem HTTPS real de produção do `mnemonicos-frontend` — pendência já aberta
  por SPEC-013 (E-01, `docs/producao-material/INDEX.md` linha da Entrega de PLAN-013); este
  PLAN não fecha essa pendência, só depende dela existir para a verificação manual do item de
  DoD.
- Prova automatizada do comportamento de rede sob dois sites `*.vercel.app` reais distintos
  (encaminhamento de `Origin`, preservação de múltiplos `Set-Cookie`) — tecnicamente
  impossível de reproduzir localmente ou em CI sem um segundo domínio `.vercel.app` publicado;
  fica para a verificação manual do item de DoD (gate 9).
- Autenticação de qualquer consumidor externo ao rewrite (app mobile nativo, outro frontend)
  — ver "Reabrir se" de DEC-021-001.
