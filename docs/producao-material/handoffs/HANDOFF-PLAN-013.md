---
id: HANDOFF-PLAN-013
slug: producao-material
branch: feat/producao-material-pwa-support (worktree C:/kwt/pwa, não pushada)
status: Pendente
criado: 2026-09-07T04:56:00+0000
origem: PLAN-013
commits: [56daad8, efd08ad, c9ab136, 65ac716, d7268a5, 6ba3efd, d126661, 50f1d8f, 5bfad14, 95b95a8]
motivo: runtime_browser (AC-013-001/002 — UI nativa de instalação fora do alcance de Playwright headless) + app_fora_do_ar (AC-013-005/011 — ciclo login/logout bloqueado por CORS_ORIGINS de origem única do backend, com a porta 3000 ocupada por sessão paralela)
sonda: >-
  TASK-013-005: Playwright MCP (Chromium `--headless --isolated`) contra build de
  produção real (`npm run build && npm run start`, porta 3001, worktree `C:/kwt/pwa`,
  HEAD `95b95a8`). `beforeinstallprompt` nunca disparou apesar de manifest válido + SW
  ativo + contexto seguro confirmados — UA confirma `HeadlessChrome`; prompt de
  instalação/`chrome://apps`/janela standalone são UI nativa do browser/SO, fora do DOM
  da página e não expostos à API de automação headless.
  TASK-013-006: build de produção subiu OK em `:3001` (porta `:3000` ocupada por outra
  sessão), mas `mnemonicos-backend/.env` tem `CORS_ORIGINS` fixo em
  `http://localhost:3000` (origem única) — toda chamada do browser a partir de `:3001`
  é bloqueada por CORS. Sintoma observado: submeter login trava indefinidamente em
  "Entrando…", sem mensagem de erro (nem sucesso nem falha) — confirmado via Postgres
  que nenhuma sessão nova foi criada (a chamada nunca completou). Tentativa de mitigação
  (proxy só-de-harness reescrevendo Origin) negada 2× pelo classificador do harness
  (`permissao_ambiente`) — não repetida. Backend compartilhado com outra sessão e
  `node_modules` do checkout principal incompleto (instalação em andamento) — não
  tocado.
achado_verificado_v3: >-
  AC-013-011, guarda de rota para acesso anônimo (Passo 3) — VERIFICADO, idêntico a
  HANDOFF-PLAN-003 V3: `/studio` → `/login?next=%2Fstudio`; sub-rota idem
  percent-encoded; `/` permanece livre (200, sem redirect).
achado_verificado_cache_positivo: >-
  AC-013-005, controle positivo — Cache Storage do app-shell (`mnemonicos-app-shell`)
  confirmado com 9 entradas (ícones, manifest.webmanifest, chunks JS/CSS), nenhuma
  entrada de `/api/...` ou HTML, ANTES de qualquer login.
achado_verificado_sw_ativo: >-
  Residual do code-reviewer (TASK-013-005, gate 1) — o teste de wiring prova só
  presença do componente na árvore de `RootLayout`, não renderização real. FECHADO
  pelo qa: `navigator.serviceWorker.getRegistrations()` contra a build real confirma 1
  registration com `active.state === 'activated'`, `scriptURL=/sw.js`.
---

# Handoff de verificação de tela — Suporte a PWA no mnemonicos-frontend

## 1. Contexto da entrega

PLAN-013 entrega suporte a PWA no `mnemonicos-frontend` (SPEC-013, demanda avulsa fora
do épico MNEMORA STUDIO, brief BRIEF-013): manifesto de aplicação, ícones, service
worker restrito a assets estáticos do app-shell (nunca navegação/API), kill-switch por
autodesregistro e registro no app. Este handoff cobre as partes que dependem de UI
nativa do navegador/SO ou de um ciclo de login real que o ambiente desta sessão não
permitiu exercitar — build de produção do frontend em `C:/kwt/pwa` (worktree isolado,
HEAD `95b95a8`), backend `mnemonicos-backend` (Express 5 · Prisma 7 · Postgres).

## 2. Já verificado (não repetir)

- **Testes** (`quality.test`): 235/235 (22 suítes) no worktree do frontend ao final da
  Wave 5; suíte de sessão pré-existente (`internal-shell.integration.test.tsx`,
  `login/page.test.tsx`) confirmada 9/9 sem alteração de casos na Wave 6 (baseline).
  Lint e typecheck limpos em todas as 6 waves.
- **AC-013-003** (SW registrado ao carregar a página) — coberto por teste de
  componente + teste de wiring (`layout.test.tsx`), e confirmado ao vivo: ver
  `achado_verificado_sw_ativo` acima.
- **AC-013-007** (contexto seguro) — VERIFICADO ao vivo: `window.isSecureContext` true
  em `http://localhost:3001` (build de produção).
- **AC-013-011, guarda de rota** (Passo 3) — ver `achado_verificado_v3` acima.
- **AC-013-005, controle positivo** — ver `achado_verificado_cache_positivo` acima.
- **Gate 8 (segurança)**: aprovado em todas as waves que tocaram cache/origem (Wave 3
  — same-origin + allowlist de path; Wave 4 — kill-switch sem vetor remoto; Wave 6 —
  revisão focada do Cache Storage confirmando garantia estrutural de NFR-013-001).
- **Gate 1-7 (code-review)**: aprovado em todas as 6 TASKs, com 2 retries reais (Wave 2
  — paridade de cor/postura de rotas; Wave 3 — cobertura estrutural + paridade de
  lógica) e 1 rodada dirigida (Wave 4, teto de retry — universo de leitura + prova de
  efeito do ramo normal + `new Function()`).

## 3. Pré-requisitos de ambiente

- **Subir o frontend (build de produção)**: em `C:/kwt/pwa` (worktree isolado, branch
  `feat/producao-material-pwa-support`) — `npm run build && npm run start`. Usar a
  porta `3000` sempre que possível (o backend de dev só aceita essa origem via
  `CORS_ORIGINS`, ver risco abaixo); se ocupada por outra sessão, aguardar liberar ou
  ajustar `CORS_ORIGINS` do backend antes de usar porta alternativa.
- **Subir o backend**: em `mnemonicos-backend/` — `npm run dev` (API em
  `http://localhost:3333/api/v1`). Confirmar `CORS_ORIGINS` no `.env` inclui a origem
  real do frontend.
- **Credenciais de tela**: `keelson.local.json` › `screenVerify.realms.app`
  (ADMIN semeado) e realm `editor` — EDITOR de teste `editor@mnemonicos.local` já
  existe (confirmado via `GET /api/v1/users`).
- **Navegador REAL, não headless**: os itens V-instalação exigem Chrome/Edge de
  verdade — Playwright headless não expõe a UI nativa (prompt de instalação,
  `chrome://apps`).
- **Perfil de navegador sem o app já instalado**: `chrome://apps` não deve listar
  "Mnemônicos" antes de começar — remover antes se listar.
- **Atenção — `CORS_ORIGINS` de origem única**: `mnemonicos-backend/.env` aceita hoje
  só `http://localhost:3000`. Ver lição registrada em
  `guidelines/project/lessons.md` ("[Config] CORS_ORIGINS de origem única...").
- **Restaurar ao fim de cada item de login real**: `DELETE FROM sessions WHERE
  "userId" IN (<id EDITOR de teste>);` no Postgres local; desregistrar o SW e limpar
  Cache Storage no navegador; desinstalar o app se instalado (`chrome://apps` → botão
  direito → Remover).

## 4. Roteiro de verificação (itens pendentes)

### V1 — Instalação via prompt nativo do navegador (AC-013-001)
- **Tela/rota**: `http://localhost:3000` (build de produção, porta livre)
- **Realm**: `app`
- **Passos**:
  1. Abrir a URL numa janela nova do navegador (Chrome ou Edge real).
  2. DevTools → Application → Manifest → confirmar "Installability" sem erros.
  3. Clicar o ícone de instalação (⊕) na barra de endereço, ou menu ⋮ → "Instalar
     Mnemônicos…".
  4. Confirmar a instalação no diálogo nativo do navegador.
- **Esperado**: o app abre em janela própria, sem barra de endereço/navegação do
  navegador (modo `standalone`), com ícone próprio visível no dock/taskbar/
  `chrome://apps`.
- **Risco se falhar**: instalabilidade é a promessa central da FEAT (FR-013-001/002) —
  pré-requisitos técnicos (manifest válido, SW ativo, contexto seguro) já confirmados
  neste handoff; falha aqui seria de UI nativa do browser/SO, não do código do produto.
- **Evidência**: _(preencher ao exercitar)_

### V2 — Nome e ícone consistentes no app instalado (AC-013-002)
- **Tela/rota**: `chrome://apps`, dock/taskbar do SO, título/splash da janela instalada
- **Realm**: `app`
- **Pré-condição**: V1 concluído (app instalado).
- **Passos**:
  1. Com o app instalado, observar o ícone e o nome em `chrome://apps` (ou dock/taskbar
     do SO).
  2. Observar a barra de título/splash da janela `standalone` do app.
- **Esperado**: nome e ícone correspondem à identidade visual atual do produto (mesmos
  tokens/arquivos de TASK-013-001/002) — não favicon genérico nem ícone em branco
  (lembrete: os ícones atuais são placeholder de cor sólida `--color-brand-500`,
  documentado em TASK-013-001 — comportamento esperado, não regressão).
- **Risco se falhar**: quebra de identidade de marca no ponto de maior visibilidade
  (ícone permanente no SO do usuário).
- **Evidência**: _(preencher ao exercitar)_

### V3 — Ciclo completo de sessão com SW ativo (AC-013-011, reexercita V1/V2/V4/V5 de HANDOFF-PLAN-003)
- **Tela/rota**: `http://localhost:3000/login` e área interna
- **Realm**: `editor`
- **Pré-condição**: backend com `CORS_ORIGINS` aceitando a origem usada pelo frontend.
- **Passos**:
  1. Login com credenciais corretas do EDITOR de teste — observar estado "Entrando…" e
     o desfecho (navegação a `/studio`).
  2. Login com senha errada + e-mail inexistente — observar mensagem genérica.
  3. Sessão válida, aguardar/forçar expiração do access token (~15 min), recarregar
     `/studio` — observar renovação silenciosa.
  4. Logout — verificar `revokedAt` no Postgres e reapresentar o cookie antigo em
     `GET /auth/me` (esperado 401).
- **Esperado**: resultado idêntico a `HANDOFF-PLAN-003` V1/V2/V4/V5 (URLs, mensagens e
  comportamento exatos), agora com o service worker ativo — nenhuma regressão
  introduzida por TASK-013-005 (registro do SW) ou pela política de cache
  (TASK-013-003).
- **Risco se falhar**: recorrência da classe "logout success race" (BRIEF-004) —
  superfície de autenticação com histórico de bug real nesta exata área.
- **Evidência**: _(preencher ao exercitar)_

### V4 — Cache não retém sessão após logout, ciclo completo (AC-013-005)
- **Tela/rota**: `/content` ou `/studio`, área interna
- **Realm**: `editor`
- **Pré-condição**: V3 executável (backend/CORS ok). Controle positivo do cache
  (app-shell populado, sem entradas de API/HTML) já confirmado neste handoff, sem
  login.
- **Passos**:
  1. Logar como EDITOR, navegar por `/content` e `/studio` gerando ao menos uma
     chamada de API autenticada.
  2. Acionar "Sair".
  3. DevTools → Application → Cache Storage: inspecionar CADA entrada de cada cache
     aberto.
- **Esperado**: cache do app-shell permanece populado (mesmas entradas do controle
  positivo); nenhuma entrada com chave de rota `/api/v1/...` ou de documento HTML
  autenticado, nem da sessão que acabou de encerrar nem de nenhuma anterior.
- **Risco se falhar**: vazamento de resposta de API/sessão pelo Cache Storage do
  service worker — cache é escopado por ORIGEM, não por usuário (NFR-013-002); risco de
  dado sensível acessível ao próximo usuário do mesmo browser. (Nota: garantia já
  confirmada **estruturalmente** pelo `security-engineer` na Wave 6 — este item é
  confirmação observacional, não é a única rede de proteção.)
- **Evidência**: _(preencher ao exercitar)_

## 5. Riscos e pontos de atenção

- **`CORS_ORIGINS` de origem única** no backend (`.env`) — ver lição registrada;
  qualquer verificação futura que precise de porta alternativa para o frontend trava
  do mesmo jeito enganoso (UI presa sem erro visível) até essa config ser revista ou o
  roteiro nomear a dependência antes de sugerir porta alternativa.
- **Suporte desigual entre navegadores** (A-013-005/RISK-013-002) — Safari tem suporte
  parcial ao manifesto/instalação; aceito nesta fatia, não é achado deste handoff.
- **Origem HTTPS de produção não confirmada** (A-013-006, E-01 da aprovação da SPEC) —
  este handoff fecha em `localhost`; a prova na origem real de produção é pendência
  separada, a resolver quando a origem for nomeada pelo Diretor.
- **Placeholder de ícone** (documentado em TASK-013-001) — V2 vai mostrar um quadrado
  de cor sólida, não uma marca gráfica; comportamento esperado, não regressão.

## 6. Protocolo de conclusão

1. Exercitar V1–V4 e preencher a **Evidência** (✅/❌ + o que foi observado).
2. Divergência → corrigir na branch `feat/producao-material-pwa-support` (protocolo
   inline: escopo restrito + testes + gates) e re-exercitar o item.
3. Tudo ✅ → `status: Concluído` no front-matter; atualizar `docs/producao-material/INDEX.md`
   (remover o risco ativo "Verificação de tela pendente — HANDOFF-PLAN-013" + linha no
   Histórico recente); commit `chore(producao-material): close verification handoff HANDOFF-PLAN-013`.
4. Merge e deploy continuam decisão humana (do Diretor) — inclusive a ordem de merge
   com a branch de PLAN-012/F4 (RISK-013-005).
