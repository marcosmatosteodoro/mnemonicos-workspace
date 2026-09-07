# TASK-013-003: Service worker — precache do app-shell e política de fetch

**Slug**: producao-material
**Pertence a**: PLAN-013
**Realiza (FRs)**: FR-013-001, FR-013-005
**Componente**: COMP-013-003 (principal), COMP-013-001, COMP-013-002
**Wave**: 3
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-pwa-support` — **cwd obrigatório do
`developer`**: `C:/kwt/pwa` (worktree isolado). **NUNCA** rodar
`dev`/`test`/`lint`/`typecheck`/`build` em `mnemonicos-frontend/` da working tree
principal — outra sessão executa PLAN-012/F4 ali concorrentemente (RISK-013-005,
TRISK-013-002).
**Padrão de commit**: Conventional Commits (`feat:`).
**Framework de teste**: Jest 30 + `next/jest`, `testEnvironment: 'jsdom'` — a lógica de
decisão é extraída em funções puras testáveis sem `ServiceWorkerGlobalScope` real
(TRISK-013-001).

## Dependências

- **Depende de**: TASK-013-001, TASK-013-002
- **Bloqueia**: TASK-013-004

## Contexto

Nenhum service worker existe hoje (grep `workbox|next-pwa|serwist|service-worker` = 0
resultados, memo item 3). Esta TASK cria `public/sw.js` (vanilla, DEC-013-001 — sem
`serwist`/`next-pwa`) cobrindo só `install` (popular o cache com a lista fixa de assets
estáticos do app-shell: JS/CSS/ícones/manifesto) e `fetch` (servir do cache **somente**
asset estático já precacheado; **nunca** responder navegação a partir do cache). O
`activate`/atualização/kill-switch é da TASK-013-004, que depende desta (mesmo arquivo,
contrato ainda não fechado nesta wave — princípio 2).

## Escopo

### Inclui
- `mnemonicos-frontend/src/lib/service-worker-policy.ts` — módulo puro, exporta
  `isStaticAssetRequest(url: URL): boolean` e `isNavigationRequest(request: Request):
  boolean` (nomes do PLAN, COMP-013-003 — "Interface pública").
- `mnemonicos-frontend/public/sw.js` — script vanilla registrado em `/sw.js`; handlers
  `install` (popula o Cache Storage com a lista fixa de precache: os dois ícones de
  `public/icons/`, o `manifest.webmanifest`, e os assets JS/CSS do app-shell buildado) e
  `fetch` (liga `isStaticAssetRequest`/`isNavigationRequest` do módulo puro à decisão:
  estático precacheado → cache; navegação → sempre rede, sem `navigateFallback`).
- Lista de precache **restrita a estáticos** — nenhuma rota interna embarcada
  (NFR-013-007, parte).

### Não inclui
- `activate` (limpeza de versão anterior, kill-switch) — TASK-013-004.
- `isKillVersion` e qualquer lógica de versão — TASK-013-004.
- Registro do `sw.js` no app (`navigator.serviceWorker.register`) — TASK-013-005.
- Cache de resposta de API/HTML autenticado — proibido por NFR-013-001, nunca implementado
  (a exclusão é o próprio comportamento correto, não um gap).
- A cobertura de **AC-013-010** aqui é só a metade "precache restrito a estáticos"; a
  metade "manifesto: `start_url`/`shortcuts`" é da TASK-013-002.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Extrair a lógica de decisão em `service-worker-policy.ts` primeiro (testável em
   `jsdom`), depois ligar ao `sw.js` (só liga eventos às funções, sem lógica própria —
   COMP-013-003, "Interface pública").
2. `isStaticAssetRequest`: casa por extensão/prefixo de caminho conhecido
   (`/icons/`, `/_next/static/`, `/manifest.webmanifest`, extensões `.js`/`.css`), nunca
   por heurística de método (todo GET de asset estático).
3. `isNavigationRequest`: usa `request.mode === 'navigate'` (ou o header `Accept` com
   `text/html` como fallback) — nunca responde a partir do cache quando verdadeiro.

## Critérios de pronto

- [ ] `isStaticAssetRequest`/`isNavigationRequest` implementadas e exportadas de
      `src/lib/service-worker-policy.ts`.
- [ ] `sw.js` liga as duas funções aos eventos `install`/`fetch`, sem lógica de decisão
      própria fora delas — verificação executável (achado do `qa` pré-código: sem isso, os
      testes das funções puras isoladas não confirmam que `sw.js` de fato as chama, em vez
      de reimplementar lógica divergente inline): teste estrutural lendo `public/sw.js`
      como texto, confirmando as chamadas literais `isStaticAssetRequest(`/
      `isNavigationRequest(` dentro dos blocos dos listeners `addEventListener('install'`/
      `addEventListener('fetch'` — mesmo comando/arquivo de teste do critério seguinte.
- [ ] Testes cobrem AC-013-004 (nunca cacheia rota de API/HTML autenticado) —
      verificação executável: `npx jest --runTestsByPath
      src/lib/service-worker-policy.test.ts` → `OK (N tests)`, com casos:
      `isStaticAssetRequest(new URL('/api/v1/contents', origin))` → `false`;
      `isStaticAssetRequest(new URL('/icons/icon-192.png', origin))` → `true`; fixada
      antes do código.
- [ ] Testes cobrem AC-013-008 (controle positivo E negativo no mesmo teste) — mesmo
      comando acima: (a) `isStaticAssetRequest` de um asset JS/CSS já listado no precache
      → `true` (serve do cache); (b) `isNavigationRequest` de uma requisição para
      `/content` (`mode: 'navigate'`) → `true`, e `isStaticAssetRequest` da mesma
      requisição → `false` (nunca cache) — os dois predicados nunca podem ser `true` ao
      mesmo tempo para a mesma requisição (par de ramos que coincide, checado
      explicitamente num caso próprio).
- [ ] Teste cobre AC-013-010 (parte — precache restrito a estáticos): a lista fixa de
      precache do `install` (lida como constante do módulo/array literal em `sw.js`) não
      contém nenhuma string de rota interna (`/studio`, `/content`, `/gestao` etc.) —
      verificação executável: mesmo comando acima, teste que importa a constante de
      precache (se extraída para `service-worker-policy.ts`) ou lê `public/sw.js` como
      texto e confirma ausência dos prefixos de `src/lib/internal-routes.ts`
      (`INTERNAL_ROUTE_PREFIXES`, memo item 4) na lista declarada.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`), produção e teste.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem — `src/lib/**` só
      função pura, sem JSX/dependência de React (perfil §4); nenhuma dependência nova
      (DEC-013-001).
- [ ] Code review aprovado.

## Riscos específicos

- **TRISK-013-001**: `jsdom` não simula `ServiceWorkerGlobalScope`/Cache Storage real — a
  suíte acima prova a lógica de decisão pura, não o ciclo `install`/`fetch` disparado pelo
  navegador nem o cache efetivamente populado. Mitigação: inspeção manual no painel
  Application (DevTools), DoD item (a) do PLAN, no fecho do ciclo — não é um Roteiro de
  gate 9 desta TASK (nenhum AC desta TASK está atribuído a gate 9).
- **Dívida de estilo não-bloqueante (2 sugestões do code-reviewer, rodada 3)**: (a)
  `sw-parity.test.ts` ancora um exemplo em "`public/sw.js`, linha 50" — referência de linha
  cross-file frágil (TASK-013-004 edita esse arquivo e desloca a numeração); trocar por
  âncora simbólica ("o ramo `exactPaths`") quando a TASK-013-004 tocar o arquivo. (b)
  constante `ORIGIN` duplicada em 3 arquivos de teste (`service-worker-policy.test.ts`,
  `sw-execution.test.ts`, `sw-parity.test.ts`) — candidata a exportar de `sw-loader.ts`.
- **Convenção nova a fixar (achado `fora_de_escopo` do code-reviewer)**: `sw-loader.ts` é
  helper só-de-teste dentro de `src/lib/` (caminho de produção), sem marcador `.test.` —
  entra no `collectCoverageFrom` do Jest como se fosse fonte, e nada impede import
  acidental de código de produção. O repo não tinha exemplar análogo antes desta TASK;
  vale o Tech Lead fixar a convenção (`*.test-helper.ts` no glob de exclusão, ou pasta
  `__tests__/`) antes que TASK-013-004/005 a copiem.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-07T00:51:07+0000
**Data conclusão**: 2026-09-07T02:29:00+0000
**Branch**: feat/producao-material-pwa-support
**Commit SHA**: 6ba3efd
**Jira**: KAN-67
**Implementado por**: developer
**Revisado por**: code-reviewer, security-engineer
**Tentativas**: 3
**Cobertura final**: service-worker-policy.ts 100%; global do repo ~91% statements (piso 50%)
**Arquivos modificados**:
  - public/sw.js
  - src/lib/service-worker-policy.ts
  - src/lib/service-worker-policy.test.ts
  - src/lib/sw-execution.test.ts
  - src/lib/sw-loader.ts
  - src/lib/sw-parity.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (217/217, 20 suítes)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (rodada 3 — 2 reprovações reais: gate 8 achou ausência de checagem same-origin com API cross-origin credenciada; gate 1/7 achou que nenhum teste executava public/sw.js de verdade, depois que nenhum teste provava paridade de LÓGICA entre as 2 cópias, só de dados)
- [x] ACs verificados (AC-013-004, AC-013-008, AC-013-010 parte)
- [x] Segurança (gate 8): aprovado (rodada 2) — same-origin check confirmado antes de qualquer decisão de cache, extensão ancorada a prefixo, mutantes mortos
- [ ] Comportamento (gate 9): n/a — SPEC sem FEATs; nenhum AC desta TASK está atribuído a gate 9

**Notas**: 3 rodadas de gate. Rodada 1: security-engineer achou SW sem checagem de origem (API cross-origin credenciada podia ser cacheada por coincidência de extensão) + code-reviewer achou nenhum teste executando o `public/sw.js` real (só paridade de dados como texto) — retry consolidado fechou os dois. Rodada 2: mutante residual (`exactPaths` neutralizado) sobrevivia com suíte verde + comentário de paridade ainda overclaim — teto de retry (4.88) atingido, decisão autônoma do Tech Lead (degrau 1 da escada do `/keelson:auto`) por rodada dirigida em vez de escalar, já que o achado era estreito/mecânico e o próprio revisor prototipou o fix. Rodada 3: tabela de casos compartilhada (`sw-parity.test.ts`) dirigindo as 2 cópias reais ao mesmo caso — APROVADO. 2 lições roteadas em `guidelines/project/lessons.md:553` (reincidências desta mesma PLAN — Wave 2 estendeu para fronteira de arquivo intra-repo, Wave 3 estendeu para lógica/comportamento, não só dado).
