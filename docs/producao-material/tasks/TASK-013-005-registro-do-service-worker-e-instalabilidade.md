# TASK-013-005: Registro do service worker e verificação de instalabilidade

**Slug**: producao-material
**Pertence a**: PLAN-013
**Realiza (FRs)**: FR-013-001, FR-013-002, FR-013-005
**Componente**: COMP-013-004 (principal), COMP-013-003
**Wave**: 5
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-pwa-support` — **cwd obrigatório do
`developer`**: `C:/kwt/pwa` (worktree isolado). **NUNCA** rodar
`dev`/`test`/`lint`/`typecheck`/`build` em `mnemonicos-frontend/` da working tree
principal — outra sessão executa PLAN-012/F4 ali concorrentemente (RISK-013-005,
TRISK-013-002).
**Padrão de commit**: Conventional Commits (`feat:`).
**Framework de teste**: Jest 30 + Testing Library, `testEnvironment: 'jsdom'` — mock de
`navigator.serviceWorker.register`.

## Dependências

- **Depende de**: TASK-013-004
- **Bloqueia**: TASK-013-006

## Contexto

Com manifesto (TASK-013-002) e service worker completo (TASK-013-003/004) prontos, falta o
gatilho que registra `public/sw.js` no carregamento do app. Componente cliente mínimo
montado uma vez no `layout.tsx` (perfil §4: `'use client'` desce ao componente mais fundo
possível, efeito isolado em `useEffect`). Com esta TASK a cadeia de instalabilidade fica
completa — é o ponto em que AC-013-001/AC-013-002/AC-013-007 (prompt nativo, ícone/nome no
app instalado, contexto seguro) tornam-se exercitáveis de ponta a ponta, e fecham só por
gate 9 (nota SPEC-013 §7 — sem caminho automatizado equivalente).

## Escopo

### Inclui
- `mnemonicos-frontend/src/components/service-worker-registration.tsx` — `'use client'`,
  named export `ServiceWorkerRegistration`, efeito em `useEffect` chamando
  `navigator.serviceWorker.register('/sw.js')`, guardado por
  `'serviceWorker' in navigator` (não expõe nenhum controle de instalação custom,
  A-013-004).
- Montagem de `<ServiceWorkerRegistration />` em `mnemonicos-frontend/src/app/layout.tsx`,
  junto do restante do shell (`children` continuam renderizados normalmente — o componente
  não envolve nada, só monta o efeito).

### Não inclui
- Nenhum controle de UI de instalação (banner/botão) — A-013-004/SPEC-013 §4.2.
- Lógica de decisão do service worker (já fechada nas TASK-013-003/004) — este componente
  só chama `.register('/sw.js')`.
- Prova de instalabilidade na origem HTTPS real de produção — não confirmada em nenhum
  artefato do workspace (A-013-006); fecha em `localhost` nesta fatia (contexto seguro
  válido); origem real fica pendência de handoff ao deploy (PLAN §10, mesmo padrão de
  `pendente_handoff` de HANDOFF-PLAN-003).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Componente client mínimo: sem `children`, sem retorno visual (`return null`), só o
   `useEffect` de registro.
2. Montar no `layout.tsx` ao lado do restante do shell — não substituir nada existente.

## Critérios de pronto

- [ ] `ServiceWorkerRegistration` chama `navigator.serviceWorker.register('/sw.js')` dentro
      de `useEffect`, guardado por `'serviceWorker' in navigator`.
- [ ] Montado em `layout.tsx` sem alterar `metadata`/`viewport` existentes (`layout.tsx:13-27`).
- [ ] Testes cobrem AC-013-003 (SW registrado ao carregar a página) — verificação
      executável: `npx jest --runTestsByPath
      src/components/service-worker-registration.test.tsx` → `OK (N tests)`, componente
      **montado** (`render(<ServiceWorkerRegistration />)`), mock de
      `navigator.serviceWorker.register` confirmando a chamada com `'/sw.js'`; e um caso
      complementar com `'serviceWorker' in navigator` falso (ambiente sem suporte) — `register`
      **não** é chamado (guarda testada nos dois ramos); fixada antes do código.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`), produção e teste.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem — `'use client'` só neste
      componente novo, efeito isolado (perfil §4).
- [ ] Code review aprovado.

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente**: build de produção local (o service worker e o prompt de instalação real do
navegador não são confiáveis sob `next dev`/HMR) — dentro do worktree
(`C:/kwt/pwa`): `npm run build && npm run start` → app servido em
`http://localhost:3000`. Backend em `http://localhost:3333` (`npm run dev` em
`mnemonicos-backend/`, mesmo procedimento de `HANDOFF-PLAN-003`). `localhost` é contexto
seguro válido (AC-013-007) — a origem HTTPS de produção real não está confirmada
(A-013-006) e fica pendência de handoff ao deploy.

**Sujeito concreto**: realm `app` do `keelson.local.json` (`screenVerify.realms.app`) —
mesma credencial já usada em `HANDOFF-PLAN-003` (ADMIN `admin@mnemonicos.local`, ou o
EDITOR de teste criado por ele). Login não é pré-requisito técnico da instalabilidade (o
app inteiro é instalável, sem sessão inclusive — A-013-003), mas usar uma sessão real
confirma que a barra de navegação do navegador some também dentro da área `(interno)`.

**Pré-condição (receita)**: navegador Chrome ou Edge, **perfil sem o app já instalado**
(chrome://apps não deve listar "Mnemônicos" antes de começar — se listar, desinstalar
primeiro: botão direito no ícone → "Remover"). Abrir uma janela nova (não é preciso modo
anônimo — a instalação persiste por perfil de navegador, então restaurar ao fim é
obrigatório).

**Restaurar ao fim**: desinstalar o app (botão direito no ícone da área de trabalho/`chrome://apps`
→ "Remover Mnemônicos…") e fechar a janela de produção (`Ctrl+C` no `npm run start`).

- **Passo 1 (AC-013-007 — contexto seguro)**: com `http://localhost:3000` aberto, DevTools
  → aba "Security" → confirmar "This page is secure" (ou equivalente) e nenhum aviso de
  conteúdo misto. **Esperado**: contexto seguro confirmado — pré-condição sem a qual os
  passos seguintes não seriam nem oferecidos pelo navegador.
- **Passo 2 (AC-013-001 — prompt nativo de instalação)**: DevTools → Application →
  Manifest → confirmar "Installability" sem erros; na barra de endereço, clicar o ícone de
  instalação (⊕ ou "Instalar app") — ou, se o navegador não oferecer o ícone
  espontaneamente, usar o menu "⋮" → "Instalar Mnemônicos…" (equivalente a "Adicionar à
  tela inicial"). Confirmar a instalação no diálogo do navegador. **Esperado**: o app abre
  numa janela própria, **sem** barra de endereço/navegação do navegador (modo
  `standalone`), com o ícone do app instalado visível no dock/taskbar/`chrome://apps`.
- **Passo 3 (AC-013-002 — nome e ícone consistentes)**: com o app instalado (passo
  anterior), observar o ícone e o nome exibidos em `chrome://apps` (ou no dock/taskbar do
  SO) e na barra de título/splash da janela do app. **Esperado**: nome e ícone
  correspondem à identidade visual atual do produto (mesmos tokens/arquivos das
  TASK-013-001/002) — não o favicon genérico do navegador nem um ícone em branco.

## Riscos específicos

- **A-013-006**: origem HTTPS de produção não confirmada — o roteiro acima fecha em
  `localhost`; a prova na origem real é pendência de handoff (PLAN §10).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-07T03:41:09+0000
**Data conclusão**: 2026-09-07T04:25:51+0000
**Branch**: feat/producao-material-pwa-support
**Commit SHA**: 95b95a8
**Jira**: KAN-69
**Implementado por**: developer
**Revisado por**: code-reviewer, qa
**Tentativas**: 2
**Cobertura final**: 100% (componente novo); global ~91%
**Arquivos modificados**:
  - src/components/service-worker-registration.tsx
  - src/components/service-worker-registration.test.tsx
  - src/app/layout.tsx
  - src/app/layout.test.tsx

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (235/235, 22 suítes)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (rodada 2 — 1 achado bloqueante: montagem em `layout.tsx` sem prova de wiring, mutante sobrevivia; fechado com teste de wiring + mutante confirmado morto)
- [x] ACs verificados (AC-013-003 completo; AC-013-001/002 parcial, ver gate 9)
- [ ] Segurança (gate 8): n/a — task não toca NFR-013-001/002/005/006/007/008 diretamente (só chama `.register()`)
- [x] Comportamento (gate 9): **pendente_handoff** — AC-013-007 (contexto seguro) e a confirmação de que o SW registra/ativa de fato (residual do gate 1) VERIFICADOS via Playwright contra build de produção real. AC-013-001 (prompt nativo de instalação) e AC-013-002 (ícone/nome no app instalado) ficam pendentes — UI nativa do navegador fora do alcance de automação headless (causa `runtime_browser`, sondagem provada). `handoff_seed` guardado em `thoughts/local/sessions/20260906-202402-6346522c/handoff-seed-plan-013.md` para consolidação em `HANDOFF-PLAN-013.md` na Etapa 4 (após Wave 6).

**Notas**: Rodada 1 reprovada pelo code-reviewer: a linha que monta `<ServiceWorkerRegistration />` em `layout.tsx` não tinha nenhum teste que provasse sua existência (apagar linha+import deixava tudo verde) — reincidência da lição ativa "função + wiring" (lessons.md:190), agora em composition root de React. Retry: `layout.test.tsx` chama `RootLayout` diretamente e percorre a árvore de elementos procurando o componente, com mutante confirmado. Gate 9 rodou em build de produção real (porta 3001, worktree isolado) — a confirmação de que o SW efetivamente ativa fecha a limitação residual que o próprio code-reviewer declarou (o teste de wiring prova presença na árvore, não renderização real). Achado de processo roteado ao `agile-coach`: bug de encoding em `scripts/probe-env.sh` (não lê `keelson.local.json` com UTF-8 explícito no Windows, mascarando erro de parse como "credencial ausente").

**Notas**: 
