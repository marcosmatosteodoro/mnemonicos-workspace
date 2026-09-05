# TASK-006-014: Tela da Quebra da regra

**Slug**: producao-material
**Pertence a**: PLAN-006
**Realiza (FRs)**: FR-005-017, FR-005-018, FR-005-019, FR-005-020
**Funcionalidade**: FEAT-005-002 (primária)
**Componente**: COMP-006-015 (principal)
**Wave**: 5
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: In Progress
**Data início**: 2026-09-05T13:18:34-03:00

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — `git.branchStrategy: unica`; não criar branch por task; a closure commita TASK a TASK)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest via `next/jest`, `testEnvironment: jsdom` (harness `mnemonicos-frontend/test/jsdom-fetch-env.js` — `testEnvironment` custom que estende `jest-environment-jsdom` e injeta `fetch`/`Response`/`Request`/`Headers` do realm Node; **sem dependência nova**, criado em F1/TASK-003-015), Testing Library (consulta por papel/texto). Em `mnemonicos-frontend/`. Gates: `npm --prefix mnemonicos-frontend test` / `run lint` / `run typecheck` / `run build`. Gate de tela: `gates.screenVerify` (skill `screen-verify`, Playwright).

## Dependências

- **Depende de**: TASK-006-003, TASK-006-010, TASK-006-011
- **Bloqueia**: nenhuma

## Contexto

COMP-006-015 / FR-005-017, FR-005-018, FR-005-019, FR-005-020 (FEAT-005-002) / NFR-005-002. Última tela da linha de produção de F2: casca Server Component em `(interno)/content/[id]/breakdown/page.tsx` mais o client component `RuleBreakdownForm` com os **cinco blocos** (CONCEITO, AÇÃO, OBJETO, CONDIÇÃO, EXCEÇÃO) como campos textuais independentes mais a **síntese da regra essencial**. CONCEITO, AÇÃO, OBJETO e síntese são obrigatórios; CONDIÇÃO e EXCEÇÃO podem ficar vazios — "não se aplica a esta regra", nunca "inacabado" (A-005-012). A ação de salvar expõe três estados observáveis (em andamento / sucesso / falha com texto preservado); uma recusa de validação **não descarta** o que foi digitado; ao reabrir, os blocos e a síntese voltam como persistidos. O upsert 1:1, a recusa quando o Conteúdo bruto não existe ou foi removido e a obrigatoriedade no servidor são do backend (TASK-006-009); a barreira de rotas é TASK-006-011; o guard de navegação é TASK-006-003. Aqui a tela consome `useGetRuleBreakdownQuery` / `useSaveRuleBreakdownMutation` (TASK-006-010) e trata a faceta de UI.

Gates previstos: g1 (Jest + Testing Library, componente montado contra a `api` real) · g9 (screenVerify — AC-005-019) · g11 (product-designer — a fatia toca superfície de interface); g8 e g10 são n/a (não toca autorização/sessão nem superfície de custo de consulta).

## Escopo

### Inclui

- `mnemonicos-frontend/src/app/(interno)/content/[id]/breakdown/page.tsx` — Server Component (sem `'use client'`, exporta `metadata` com título pt-BR), no padrão de `(interno)/studio/page.tsx`; lê o `id` da rota (`params`) e renderiza `<RuleBreakdownForm contentId={id} />`. Fica sob o `layout.tsx` do grupo `(interno)` já existente (`InternalShell`).
- `mnemonicos-frontend/src/components/rule-breakdown-form.tsx` — `'use client'` (`RuleBreakdownForm`). `useGetRuleBreakdownQuery(contentId)` de `src/store/api.ts` para pré-preencher; `useSaveRuleBreakdownMutation` para gravar. Ramos do query: `isLoading` → indicador `role="status"` com texto pt-BR; `isError` → mensagem pt-BR + controle "Tentar novamente" que dispara `refetch`; sucesso (com Quebra existente ou não) → o formulário com os valores persistidos ou vazio.
- Seis campos textuais: os cinco blocos (CONCEITO, AÇÃO, OBJETO, CONDIÇÃO, EXCEÇÃO) e a síntese da regra essencial. Obrigatoriedade na faceta UI: CONCEITO, AÇÃO, OBJETO e síntese — ao tentar salvar sem um deles, o formulário lista os campos pendentes (mensagem pt-BR) e **não** dispara a mutation; CONDIÇÃO e EXCEÇÃO vazios são aceitos e o salvar prossegue — "não se aplica a esta regra", nunca "inacabado" (A-005-012).
- Três estados observáveis da ação salvar: *em andamento* (controle de envio `disabled`, indicador `role="status"` pt-BR), *sucesso* (confirmação exibida), *falha* (mensagem de erro pt-BR em `role="alert"`, texto digitado **preservado**). Uma recusa de validação (local ou do servidor) **não descarta** o que foi digitado — os blocos preenchidos permanecem na interface.
- Reabrir: ao recarregar/reabrir a tela, `useGetRuleBreakdownQuery` traz os cinco blocos e a síntese como persistidos, exibidos nos campos.
- Rótulos e textos de interface em pt-BR; os nomes dos blocos (CONCEITO, AÇÃO, OBJETO, CONDIÇÃO, EXCEÇÃO) e da síntese aparecem como rótulos pt-BR, nunca os identificadores crus (`concept`/`action`/`object`/`condition`/`exception`/`essence`).
- `mnemonicos-frontend/src/components/rule-breakdown-form.test.tsx` — colocado; Testing Library; `RuleBreakdownForm` **montado** contra a `api` real (`makeStore()` + `fetch` mockado por cenário; `testEnvironment` `test/jsdom-fetch-env.js`).

### Não inclui

- Rascunho / salvar Quebra da regra incompleta — fora de F2 (A-005-012); F2 exige completude mínima (CONCEITO, AÇÃO, OBJETO, síntese).
- Tira mnemônica como sequência ordenada de quadros — F4 (substitui, não estende, os "blocos" desta fatia).
- A regra de upsert 1:1, a recusa quando o Conteúdo bruto não existe/foi removido (AC-005-021 / AC-005-037) e a validação de obrigatoriedade no servidor — backend (TASK-006-009).
- Endpoints/hooks RTK Query (`useGetRuleBreakdownQuery`, `useSaveRuleBreakdownMutation`) — TASK-006-010.
- Registro do segmento de rota `content` (`INTERNAL_ROUTE_PREFIXES` + `config.matcher` do `proxy.ts`) — TASK-006-003.
- Rotas `GET`/`PUT /contents/:id/breakdown` sob a barreira deny-by-default — TASK-006-011.
- Indicador "tem Quebra da regra" na listagem — TASK-006-012.
- Via de acesso à Quebra a partir da listagem ou da visão do conteúdo — TASK-006-012 / TASK-006-013.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `(interno)/content/[id]/breakdown/page.tsx` — Server Component com `export const metadata`; renderiza `<RuleBreakdownForm contentId={id} />` com o `id` lido de `params`.
2. `rule-breakdown-form.tsx` (`'use client'`) — `useState` para os seis campos; `useGetRuleBreakdownQuery(contentId)`; popular o estado local uma vez quando os dados chegam; ramos `isLoading` / `isError` com render próprio.
3. Ao salvar: validação local (CONCEITO/AÇÃO/OBJETO/síntese não vazios) **antes** de `saveRuleBreakdown`; enquanto `isLoading` da mutation, desabilitar o envio e exibir o indicador; no `catch` do `.unwrap()`, manter o estado local e mostrar mensagem pt-BR; no sucesso, confirmação.
4. CONDIÇÃO e EXCEÇÃO ausentes não bloqueiam o salvar.
5. `rule-breakdown-form.test.tsx` — montar com `makeStore()` + `fetch` mockado por cenário (`test/jsdom-fetch-env.js`).

## Critérios de pronto

- [ ] **[Design] `EMENDA pós gate 11` — sucesso do salvar anunciado**: a mensagem "Quebra da regra salva com sucesso." vira `<p role="status" aria-live="polite" className="text-sm text-muted">` (mesmo padrão de `content-form.tsx:337-341`) — hoje é um `<p>` sem `role`, invisível a leitor de tela, e usa `text-green-600` cru em vez do token do tema.
- [ ] **[Design] `EMENDA pós gate 11` — via de volta ao Conteúdo bruto**: acrescentar `Link` para `/content/${contentId}` — a tela hoje só tem "voltar do navegador" como saída. **Rótulo por destino, não por histórico** ("Ir para o Conteúdo bruto", nunca "Voltar ao conteúdo" — a tela tem 2 entradas possíveis, listagem e formulário, e um rótulo de direção histórica seria falso numa delas).
- [ ] **[Design] `EMENDA pós gate 11` — obrigatório/opcional distinguíveis**: os 6 campos são renderizados idênticos hoje. Marcar visualmente os 4 obrigatórios (`REQUIRED_FIELDS`) OU anotar CONDIÇÃO/EXCEÇÃO com "(deixe vazio se não se aplica)" — a decisão de produto (A-005-012) já existe, só não chegou à tela.
- [ ] **[Design] `EMENDA pós gate 11` — validação perto do campo**: hoje a recusa sai só como lista agregada no rodapé; somar `aria-invalid`/`aria-describedby` no `<textarea>` de cada campo pendente (mesmo padrão que `content-form.tsx` está ganhando no seu próprio retry).
- [ ] **[Design] `EMENDA pós gate 11` — botão "Salvar" no mesmo padrão canônico**: remover o `text-sm` do botão de salvar — o canônico do produto (`login-form.tsx`, já seguido por `content-form.tsx`) é `surface-card px-4 py-2 font-medium disabled:opacity-60`, sem tamanho de texto reduzido.
- [ ] `content/[id]/breakdown/page.tsx` é Server Component e compõe o client component `RuleBreakdownForm` — verificação executável: `npm --prefix mnemonicos-frontend test -- rule-breakdown-form` monta `RuleBreakdownForm` (`render` com `Provider`/`makeStore()`) e tem ≥1 asserção de conteúdo (`Tests: ≥1 passed`); `grep -nE "^['\"]use client['\"]" "mnemonicos-frontend/src/app/(interno)/content/[id]/breakdown/page.tsx"` → sem resultado (a diretiva vive só em `rule-breakdown-form.tsx`, arquivo novo desta branch; comando também sem resultado no commit-pai por o arquivo não existir lá). Fixada antes do código.
- [ ] Testes cobrem **AC-005-023** (três estados observáveis de salvar a Quebra da regra) — `RuleBreakdownForm` montado contra a `api` real: (i) pendente → controle de envio `disabled` e indicador `role="status"` pt-BR visível; (ii) sucesso (mutation 2xx no `PUT /contents/:id/breakdown`) → confirmação exibida; (iii) falha (mutation 4xx/5xx) → mensagem de erro pt-BR (`role="alert"`) e os cinco blocos + a síntese digitados **permanecem** nos campos. Verificação executável: `npm --prefix mnemonicos-frontend test -- rule-breakdown-form` → cenários com `fetch` mockado por estado (pendente sem resolver / `200` / `500`); saída `Tests: ≥3 passed`. Falsificável: remover o `disabled` durante o pending → caso (i) acha o controle habilitado (vermelho); limpar os campos no `catch` → caso (iii) não acha o texto digitado (vermelho). Fixada antes do código.
- [ ] Testes cobrem **AC-005-022** (faceta UI) — Quando o EDITOR tenta salvar sem CONCEITO, AÇÃO, OBJETO ou a síntese, o formulário **lista os campos pendentes** (mensagem pt-BR) e **não** dispara a mutation; Quando CONCEITO, AÇÃO, OBJETO e síntese estão preenchidos e CONDIÇÃO e EXCEÇÃO ficaram **vazios**, o salvar **prossegue** (mutation disparada). Verificação executável: `npm --prefix mnemonicos-frontend test -- rule-breakdown-form` → cenário A: só CONDIÇÃO/EXCEÇÃO preenchidos, acionar salvar → asserção da lista de pendências e `fetch` **não** chamado para `/breakdown`; cenário B: os quatro obrigatórios preenchidos, CONDIÇÃO/EXCEÇÃO vazios, acionar salvar → `fetch` chamado com `condition`/`exception` vazios/ausentes no corpo. Falsificável: bloquear o salvar quando CONDIÇÃO/EXCEÇÃO estão vazios → cenário B não chama `fetch` (vermelho); aceitar o salvar sem os obrigatórios → cenário A chama `fetch` (vermelho). Fixada antes do código.
- [ ] Testes cobrem **AC-005-024** (faceta UI) — `RuleBreakdownForm` montado com `useGetRuleBreakdownQuery` mockado devolvendo uma `RuleBreakdown` persistida (os cinco blocos + `essence`) → todos os campos reabrem com esses valores exatos (`getByDisplayValue`); Quando o EDITOR altera um bloco e a síntese e aciona salvar, a mutation `PUT /contents/:id/breakdown` é chamada com **os valores alterados** no corpo. Verificação executável: `npm --prefix mnemonicos-frontend test -- rule-breakdown-form` → `getByDisplayValue` de cada bloco/síntese contra o payload do query; após editar e salvar, asserção sobre o corpo do `fetch` interceptado == valores novos. Falsificável: não popular o estado local a partir do query → `getByDisplayValue` inicial falha (vermelho); enviar o payload original em vez do editado → asserção do corpo falha (vermelho). A persistência ponta-a-ponta ("recarrega → valores persistidos") é AC-005-019, gate 9. Fixada antes do código.
- [ ] Testes cobrem **AC-005-029** (faceta tela) — toda string visível do formulário (rótulos dos cinco blocos e da síntese, botões, mensagens de validação e de erro) está em pt-BR; os nomes dos blocos aparecem como rótulos pt-BR, nunca os identificadores crus (`concept`/`action`/`object`/`condition`/`exception`/`essence`). Verificação executável: `npm --prefix mnemonicos-frontend test -- rule-breakdown-form` → `getByLabelText` de cada bloco pelo rótulo pt-BR; asserção de que `concept`/`action`/… **não** aparecem como texto visível. Falsificável: rotular um campo com o identificador cru → o teste acha `'concept'` e não o rótulo (vermelho). Fixada antes do código.
- [ ] **Lição ativa [Testes] "Predicado de decisão de UI a partir de estado de RTK Query só se prova no componente montado"** aplicada a `rule-breakdown-form.tsx`. Texto da lição (solução): *"Predicado que decide render/navegação a partir de estado de RTK Query → oráculo que passa pelo componente MONTADO contra a `api` real (store real via `makeStore()` + `fetch` mockado). O teste da função pura complementa, nunca substitui. Critério de aceite: o mutante morre no teste montado. `resetApiState()` (login/logout) pode desmontar a subárvore dentro de um único flush — polling de 1ms não vê. Asserção de presença no DOM não acusa: o oráculo precisa de contador de montagem/efeito ou de asserção sobre estado local que a remontagem destruiria."* Item verificável: os ramos de `RuleBreakdownForm` — `isLoading`/`isError` do `useGetRuleBreakdownQuery`; pendente/sucesso/falha do `useSaveRuleBreakdownMutation`; "a recusa de validação não descarta o digitado" — provam-se **no componente montado** contra a `api` real (`makeStore()` + `fetch` mockado via `test/jsdom-fetch-env.js`), nunca por função pura sobre `api.endpoints.*.select()`; teste de função pura só complementa. O oráculo de "não descarta o digitado" **não** se apoia só em presença no DOM: usa um **contador de montagem/efeito** OU asserção sobre o `useState` dos blocos que uma remontagem destruiria — cobrindo a janela em que uma invalidação de tag (`saveRuleBreakdown` invalida `RuleBreakdown` e `RawContent`) / `resetApiState` / refetch remontaria a subárvore. O mutante que remove a guarda de estado (submeter sem checar `isLoading`, ou resetar os blocos no `catch`/no refetch) **morre no teste montado**. Verificação executável: `npm --prefix mnemonicos-frontend test -- rule-breakdown-form` → os cenários montam `render(<Provider store={makeStore()}>…)`, não `select()` sobre store sem subscritor; `Tests: ≥1 passed` com contador de montagem/efeito no cenário de "não descarta". Fixada antes do código.
- [ ] `npm --prefix mnemonicos-frontend run build` → exit 0 — a rota `(interno)/content/[id]/breakdown` compila (fronteira `'use client'` correta: `page.tsx` Server Component, `rule-breakdown-form.tsx` client; nenhum Server Component `async` marcado `'use client'`). Baseline: build verde hoje nos dois repos (exploração — fe jest 90/90, typecheck/lint/build limpos). Falsificável: marcar `rule-breakdown-form.tsx` como Server Component `async` usando hook de cliente → build aborta apontando `./src/components/rule-breakdown-form.tsx`. Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-frontend run lint` → exit 0 (baseline capturada no início da TASK) e `npm --prefix mnemonicos-frontend run typecheck` → exit 0.
- [ ] Padrão de commit respeitado (Conventional Commits — `feat:`).
- [ ] Aderência à stack/padrões da ficha e do perfil (`next-16.md`: Server Component por default e `'use client'` no componente mais fundo §4; estado de servidor só em RTK Query §6.5; `makeStore()` função, nunca singleton; rótulos pt-BR do mapa de `domain.ts` §3; teste por papel/texto; guidelines de projeto vencem o perfil em conflito).
- [ ] Code review aprovado.

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente**: frontend Next em `http://localhost:3000` (`next dev`, sem base path); rota da Quebra da regra `http://localhost:3000/content/<id>/breakdown`. API backend em `http://localhost:3333/api/v1`. Realm `app` (dev local; Postgres do `mnemonicos-backend/docker-compose.yml`).

**Autenticação — pré-condição**: popular `keelson.local.json` (dev-local, **gitignored** — passo do Diretor/dev, como o `.env`) a partir de `keelson.local.example.json` — realm `app` (`loginPath: "/login"`) **+ realm `editor`** (molde acrescentado por TASK-006-005), com as credenciais do **EDITOR de dev** vindas de `SEED_EDITOR_EMAIL` / `SEED_EDITOR_PASSWORD`. O `mnemonicos-backend/.env` precisa de `SEED_EDITOR_*` **reais** e a semente (`db:seed`) **já rodada**. O gate injeta as credenciais do realm; **nunca chutar** (HANDOFF-PLAN-003, bloco `sonda`). O molde `keelson.local.example.json` (realm `editor`) e a função de seed `seedDevEditor` são entregues por **TASK-006-005**.

**Sujeito concreto**: o **EDITOR de dev** semeado por TASK-006-005 (env-gated `SEED_EDITOR_EMAIL` / `SEED_EDITOR_PASSWORD`; ausência = nenhum EDITOR criado); a credencial correspondente no realm `editor` de `keelson.local.json`. O ADMIN semeado (`SEED_ADMIN_EMAIL` / `SEED_ADMIN_PASSWORD`) fica disponível para montagem/restauração.

**Pré-condição — montar**:
1. `mnemonicos-backend/.env` com `SEED_ADMIN_EMAIL`/`SEED_ADMIN_PASSWORD` **e** `SEED_EDITOR_EMAIL`/`SEED_EDITOR_PASSWORD` preenchidos (não placeholders). `npm --prefix mnemonicos-backend run db:up` (Docker Postgres); `npm --prefix mnemonicos-backend run db:deploy` (aplica a migração de F2 — TASK-006-001) — **⚠️ execução de migração: confirmar com o Diretor antes (regra do projeto / TRISK-006-001)**; `npm --prefix mnemonicos-backend run db:seed` → carrega Direito Tributário / Obrigação Tributária, 1 ADMIN, 1 EDITOR de dev e ≥1 `RawContent` (autor = ADMIN) com `RuleBreakdown` completa.
2. Subir os apps: `npm --prefix mnemonicos-backend run dev` (:3333) e `npm --prefix mnemonicos-frontend run dev` (:3000); confirmar `NEXT_PUBLIC_API_BASE_URL` apontando para :3333.
3. O EDITOR de dev **só alcança os Conteúdos brutos que registrou** (alcance por autor — TASK-006-008); o `RawContent` semeado é do ADMIN. Logo, autenticado como o EDITOR de dev em `http://localhost:3000/login`, registrar **dois** Conteúdos brutos **sem Quebra da regra** — pela tela `http://localhost:3000/content/new` (TASK-006-013) **ou** `POST http://localhost:3333/api/v1/contents` com a sessão do EDITOR (fallback) — cada um com texto normativo, disciplina semeada, tema semeado e classe do radar. Anotar os `id`: um é o `<id>` sobre o qual a Quebra será criada no passo; o outro (`<id2>`) fica **sem Quebra** para a verificação de não-vazamento.

**Pré-condição — restaurar** (ao fim):
1. Obter o id do EDITOR de dev: `SELECT id FROM users WHERE email = '<SEED_EDITOR_EMAIL>'` (ou via `GET http://localhost:3333/api/v1/users` autenticado como ADMIN).
2. No Postgres local — `DELETE FROM rule_breakdowns WHERE "rawContentId" IN (SELECT id FROM raw_contents WHERE "authorId" = '<id do EDITOR de dev>');` · `DELETE FROM raw_contents WHERE "authorId" = '<id do EDITOR de dev>';` · `DELETE FROM sessions WHERE "userId" = '<id do EDITOR de dev>';` — **nunca** truncar todas as sessões do realm dev compartilhado. Alternativa: re-seed idempotente (resolução 2 do manifesto).

**Passo (AC-005-019) — preencher os cinco blocos + síntese → salvar → recarregar → reabrir**:
1. Em `http://localhost:3000/login`, autenticar como o EDITOR de dev (`SEED_EDITOR_EMAIL` / `SEED_EDITOR_PASSWORD`).
2. Navegar para `http://localhost:3000/content/<id>/breakdown` do Conteúdo bruto registrado na pré-condição. A tela da Quebra da regra abre com os cinco blocos e a síntese **vazios** (ainda não há Quebra).
3. Preencher os **cinco blocos** (CONCEITO, AÇÃO, OBJETO, CONDIÇÃO, EXCEÇÃO) e a **síntese da regra essencial** com valores distintos e reconhecíveis.
4. Acionar salvar. Observar o estado *em andamento* (envio desabilitado, indicador pt-BR) e depois a confirmação de sucesso.
5. **Recarregar** a página (abrir de novo `http://localhost:3000/content/<id>/breakdown`, reload do browser) e **reabrir** a Quebra da regra.
6. **Esperado**: os cinco blocos e a síntese aparecem exatamente com os valores digitados no passo 3, **persistidos e vinculados a esse Conteúdo bruto** (o mesmo `<id>`). **Confirmar que a Quebra pertence ao `<id>` correto** — via `GET http://localhost:3333/api/v1/contents/<id>/breakdown` retornando os **mesmos 6 valores** (os 5 blocos + a síntese) —, **e** que `GET http://localhost:3333/api/v1/contents/<id2>/breakdown` (o segundo `RawContent` do EDITOR, **sem** Quebra) **continua sem Quebra** (404 / vazio — não vazou para outro conteúdo). É o gate falsificável de AC-005-019: valores que não voltam, voltam truncados/trocados, ou vinculados a outro conteúdo reprovam o passo.

**Nota (handoffs anteriores do slug)**: HANDOFF-PLAN-003 registra V6 (falha transitória de logout) como não-exercitável **por exigir 500 seletivo numa rota** — não é o caso deste passo, que é preencher/salvar/recarregar sem forçar falha de rede. As caminhadas V1–V5 de F1 foram **exercitadas com sucesso local em 2026-09-01** (Playwright, contra o código mergeado) — o ambiente de tela funciona; este passo é **tentado localmente**. Só se o ambiente de tela falhar na execução o gate 9 vira `pendente_handoff` (Etapa 4.6 do `/keelson:auto`; resolução 1 do manifesto).

## Riscos específicos

- Repos symlinkados (lição [Exploração]): editar e verificar sempre pelo caminho **dentro** do link (`mnemonicos-frontend/src/...`); ausência detectada por varredura não é fato.
- **Alcance por autor**: o EDITOR de dev só alcança os Conteúdos brutos que registrou — o `RawContent` semeado é do ADMIN. A pré-condição do gate 9 **cria** o conteúdo como o EDITOR, senão `GET /contents/<id>/breakdown` recusa (404) e não há sobre o que preencher a Quebra.
- **Semântica do vazio** (A-005-012): CONDIÇÃO e EXCEÇÃO em branco são "não se aplica a esta regra", nunca "inacabado" — o formulário aceita salvar com esses dois vazios desde que CONCEITO, AÇÃO, OBJETO e síntese estejam preenchidos. Não confundir com bloqueio de rascunho.
- `test/jsdom-fetch-env.js` (`testEnvironment` custom que estende `jest-environment-jsdom`, criado em F1/TASK-003-015) é o harness dos testes montados contra a `api` real — **sem dependência nova**.
- Depende de TASK-006-010 (hooks `useGetRuleBreakdownQuery` / `useSaveRuleBreakdownMutation` em `src/store/api.ts`), TASK-006-011 (rotas `GET`/`PUT /contents/:id/breakdown` sob a barreira) e TASK-006-003 (segmento `content` em `INTERNAL_ROUTE_PREFIXES` + `config.matcher` do `proxy.ts`) — sem os três a rota não é guardada nem servida.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-42
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
- [ ] Segurança (gate 8): n/a — tela de frontend; não toca autorização, sessão nem superfície sensível (a barreira é backend — TASK-006-011; o guard de navegação é TASK-006-003)
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa; AC-005-019 (preencher os cinco blocos + síntese → salvar → recarregar → reabrir → persistidos e vinculados ao conteúdo); receita e restauração no Roteiro do gate 9 desta TASK; sujeito EDITOR de dev (SEED_EDITOR_*)>

**Notas**: 
