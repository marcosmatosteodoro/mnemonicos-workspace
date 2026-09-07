# TASK-013-006: Verificação de não-regressão de sessão com service worker ativo

**Slug**: producao-material
**Pertence a**: PLAN-013
**Realiza (FRs)**: nenhuma
**Componente**: COMP-013-003 (principal), COMP-013-004
**Wave**: 6
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-pwa-support` — **cwd obrigatório do
`developer`**: `C:/kwt/pwa` (worktree isolado). **NUNCA** rodar
`dev`/`test`/`lint`/`typecheck`/`build` em `mnemonicos-frontend/` da working tree
principal — outra sessão executa PLAN-012/F4 ali concorrentemente (RISK-013-005,
TRISK-013-002).
**Padrão de commit**: Conventional Commits (`chore:` — task de verificação, sem código de
produção novo esperado; se o roteiro achar divergência, a correção nasce como `fix:` no
mesmo diff, protocolo inline).
**Framework de teste**: gate 9 (`screenVerify`) — Cache Storage real e ciclo de sessão real
não são simuláveis em `jsdom` (TRISK-013-001; NFR-013-002 nota: "Cache Storage é escopado
por ORIGEM, não por usuário").

## Dependências

- **Depende de**: TASK-013-005
- **Bloqueia**: nenhuma

## Contexto

**Fatia sensível** (princípio 8 da Etapa 1): NFR-013-002 (cache não retém sessão anterior
no logout) e NFR-013-008 (SW não altera login/renovação/guarda/logout) tocam a superfície
de autenticação já sensível do slug — histórico do "logout success race" (BRIEF-004,
HANDOFF-PLAN-003 V5) mostra que esta é exatamente a área onde uma mudança aparentemente
não-relacionada (aqui, registrar um service worker no `layout.tsx`) já quebrou o fluxo de
logout antes. Esta TASK isola a verificação numa task própria, com revisão focada
(`security-engineer`), em vez de misturá-la ao resto do SW. NFR-013-001 (nunca cachear
API/HTML autenticado) já é garantido estruturalmente pelas funções puras da TASK-013-003 —
NFR-013-002 é, por design, consequência direta dela (SPEC-013 §6): esta TASK **confirma**
a consequência no ciclo real, não introduz um mecanismo novo de limpeza de cache.

## Escopo

### Inclui
- Verificação (gate 9) de que o Cache Storage do service worker, num ciclo completo de
  login → uso → logout, nunca contém resposta de rota de API/HTML autenticado, e que os
  assets estáticos do app-shell permanecem cacheados (controle positivo) — AC-013-005.
- Verificação (gate 9) de que a caminhada completa de sessão de SPEC-002 (login com três
  estados, guarda de rota, renovação silenciosa, logout de sucesso) se comporta
  **exatamente** como já provado em `HANDOFF-PLAN-003`, agora com o service worker
  registrado e ativo — AC-013-011.
- Se o roteiro achar divergência: correção no código da TASK que a introduziu (mais
  provável: `service-worker-registration.tsx`/`layout.tsx`, TASK-013-005, ou a política de
  cache, TASK-013-003), no mesmo diff desta TASK, com teste de regressão antes de
  reexercitar o roteiro.

### Não inclui
- Nenhum mecanismo novo de limpeza de cache no logout — se NFR-013-001 já garante o
  resultado (SPEC-013 §6), introduzir um `caches.delete()` no fluxo de logout seria escopo
  não pedido (a menos que o roteiro ache uma resposta de API/sessão de fato cacheada, caso
  em que a correção é o **fetch handler** da TASK-013-003, não um novo hook de logout).
- Repetir os itens V1–V6 já **fechados** em `HANDOFF-PLAN-003` como prova nova desta TASK —
  eles são reexercitados aqui só como controle de não-regressão (mesmo resultado esperado),
  não reabertos como achado novo desta fatia.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Antes do roteiro, confirmar que a suíte de testes de SPEC-002 (login/logout/guarda/
   renovação — `mnemonicos-frontend`) segue verde sem alteração de asserção, como baseline
   de não-regressão automatizada (complementar ao gate 9, nunca substituto dele).
2. Exercitar o roteiro do gate 9 abaixo.

## Critérios de pronto

- [ ] Baseline de não-regressão automatizada: a suíte de testes de sessão existente
      (login/logout/guarda/renovação, `SPEC-002`) permanece verde após a adição do
      `ServiceWorkerRegistration` ao `layout.tsx` — verificação executável: `npx jest
      --runTestsByPath src/components/internal-shell.integration.test.tsx
      src/app/login/page.test.tsx` → `OK (N tests)`, mesma contagem de casos que antes da
      TASK-013-005 (baseline capturada antes de começar esta TASK, dentro do próprio
      critério — nenhum caso removido/alterado). Este critério **não** reivindica cobrir
      AC-013-005/AC-013-011 (que fecham só por gate 9, abaixo) — é evidência complementar
      de que o registro do SW não alterou a suíte já existente.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`), produção e teste.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem.
- [ ] Code review aprovado.
- [ ] Revisão de segurança focada (`security-engineer`) sobre o Cache Storage do gate 9 —
      fatia sensível (princípio 8, superfície de autenticação).

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente**: build de produção local — dentro do worktree
(`C:/kwt/pwa`): `npm run build && npm run start` →
`http://localhost:3000`. Backend em `http://localhost:3333` (`npm run dev` em
`mnemonicos-backend/`). `localhost` como contexto seguro (mesma nota da TASK-013-005).

**Sujeito concreto**: realm `app` do `keelson.local.json` — ADMIN `admin@mnemonicos.local`
e o EDITOR de teste (criar via `POST http://localhost:3333/api/v1/users` autenticado como
o ADMIN semeado, mesma receita de `HANDOFF-PLAN-003` §3, se ainda não existir).

**Pré-condição (receita)**: app instalado OU aberto normalmente no navegador (a instalação
via TASK-013-005 não é pré-requisito da sessão — só do service worker estar ativo); antes
de começar, abrir `http://localhost:3000`, aguardar o carregamento completo (o `install`
do SW deve ter rodado — confirmar em DevTools → Application → Service Workers: status
"activated and is running") e DevTools → Application → Cache Storage: confirmar que existe
um cache do app-shell **populado** (ícones, manifesto, JS/CSS) antes de prosseguir —
controle positivo inicial.

**Restaurar ao fim**: `DELETE FROM sessions WHERE "userId" IN (<id EDITOR de teste>, <id
ADMIN de teste>);` no Postgres local (mesma receita de `HANDOFF-PLAN-003`); Application →
Clear storage (ou desregistrar o SW manualmente) para não deixar o cache/realm sujo para a
próxima sessão de verificação. Fechar `npm run start`.

- **Passo 1 (AC-013-005 — cache não retém sessão após logout)**: logado como o EDITOR de
  teste, navegar pela área interna normalmente (ex.: `/content`, `/studio`) gerando ao
  menos uma chamada de API autenticada (`GET /auth/me`, listagem de conteúdo). Em seguida
  acionar "Sair" (logout de sucesso). **Esperado**: (a) DevTools → Application → Cache
  Storage **ainda contém** as entradas do app-shell (ícones/manifesto/JS/CSS) — controle
  positivo, o cache não foi zerado por engano; (b) inspecionando cada entrada do(s)
  cache(s) abertos, **nenhuma** tem como chave uma URL de rota de API (`/api/v1/...`) ou de
  documento HTML autenticado — nem da sessão que acabou de encerrar, nem de nenhuma
  anterior.
- **Passo 2 (AC-013-011 — três estados do login)**: reexercitar `HANDOFF-PLAN-003` V1
  (login com credenciais corretas: estado "em andamento" + navegação ao sucesso) e V2
  (mensagem genérica de falha, senha errada e e-mail inexistente), agora com o service
  worker ativo. **Esperado**: resultado **idêntico** ao registrado em V1/V2 — mesma URL de
  destino, mesma mensagem de erro exata, mesmo comportamento dos inputs.
- **Passo 3 (AC-013-011 — guarda de rota recusando acesso anônimo)**: reexercitar
  `HANDOFF-PLAN-003` V3 (sem cookie, navegar direto a `/studio` e a uma sub-rota; navegar a
  `/` sem cookie). **Esperado**: idêntico a V3 — redirect a `/login?next=...` nas rotas
  internas, `/` permanece livre (200, sem redirect).
- **Passo 4 (AC-013-011 — renovação silenciosa de sessão)**: com sessão válida, aguardar a
  credencial de acesso expirar (~15 min, ou provocar via ajuste de horário/expiração no
  ambiente de teste) e realizar uma ação que exija sessão (ex.: recarregar `/studio`).
  **Esperado**: a renovação ocorre silenciosamente (novo `POST /auth/refresh` seguido de
  sucesso) sem expulsar o usuário nem exibir mensagem de sessão expirada — mesmo
  comportamento de AC-002-028 (já aprovado antes desta fatia).
- **Passo 5 (AC-013-011 — logout de sucesso exato)**: reexercitar `HANDOFF-PLAN-003` V5
  (acionar "Sair", observar estado "em andamento", conferir `revokedAt` no Postgres,
  reapresentar o cookie antigo). **Esperado**: idêntico a V5 — URL final
  `http://localhost:3000/login` **exata** (sem `?sessao=expirada`), nenhuma mensagem de
  "sessão expirou", cookie antigo reapresentado → 401, sem laço de `refresh`.

## Riscos específicos

- Histórico direto: `HANDOFF-PLAN-003` V5 documenta o "logout success race" (BRIEF-004) —
  um bug real nesta exata superfície, introduzido por uma mudança aparentemente
  não-relacionada ao logout. O Passo 5 deste roteiro é a defesa direta contra recorrência
  dessa classe ao introduzir o service worker.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-07T04:29:34+0000
**Data conclusão**: 2026-09-07T04:54:00+0000
**Branch**: feat/producao-material-pwa-support
**Commit SHA**: — (nenhum — chore de verificação, sem código de produção; baseline confirmado sem divergência)
**Jira**: KAN-70
**Implementado por**: developer (baseline), qa (roteiro), security-engineer (revisão focada)
**Revisado por**: security-engineer
**Tentativas**: 1
**Cobertura final**: n/a
**Arquivos modificados**:
  - (nenhum)

**Quality gates**:
- [x] Implementação completa (baseline automatizada confirmada, sem divergência)
- [x] Testes passando (9/9 herdados, sem alteração)
- [x] Lint limpo (n/a — sem código novo)
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (n/a — sem diff a revisar; revisão de segurança cobriu o mecanismo)
- [x] ACs verificados (parcial — ver gate 9)
- [x] Segurança (gate 8): aprovado — revisão focada do Cache Storage (critério próprio da TASK): garantia de NFR-013-001 é estrutural (2 pontos de escrita, 2 camadas independentes — origem + allowlist de path), nenhuma lacuna nova exposta pela integração das 5 waves, NFR-013-002 não sobre-promete
- [x] Comportamento (gate 9): **pendente_handoff** — AC-013-011 (guarda de rota, V3) VERIFICADO idêntico a `HANDOFF-PLAN-003`; AC-013-005 controle positivo confirmado (cache do app-shell populado, sem API/HTML pré-login). Ciclo completo login→uso→logout (V1/V2/V4/V5) bloqueado por ambiente (`CORS_ORIGINS` do backend fixo em `:3000`, porta ocupada por sessão paralela) — `handoff_seed` consolidado em `thoughts/local/sessions/20260906-202402-6346522c/handoff-seed-plan-013.md` para `HANDOFF-PLAN-013.md`.

**Notas**: Baseline automatizada (developer): suíte de sessão (9/9) confirmada verde sem alteração — `internal-shell.integration.test.tsx` monta `InternalShell` isolado, não exercita o SW real (limitação já prevista, TRISK-013-001). Gate 9 (qa): identidade do ambiente verificada antes de exercitar (porta 3000 pertencia a processo de outra sessão, não tocado; build própria subiu em `:3001`); nenhum efeito colateral no backend compartilhado, sessão nova do EDITOR não foi criada (tentativa via UI nunca completou por CORS). Nova lição registrada em `guidelines/project/lessons.md` ("[Config] CORS_ORIGINS de origem única quebra silenciosamente o padrão de porta alternativa entre sessões paralelas", estado `em-observacao`).
