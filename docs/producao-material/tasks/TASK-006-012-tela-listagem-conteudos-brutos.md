# TASK-006-012: Tela de listagem de Conteúdos brutos

**Slug**: producao-material
**Pertence a**: PLAN-006
**Realiza (FRs)**: FR-005-005, FR-005-012, FR-005-021, FR-005-022, FR-005-023, FR-005-024
**Funcionalidade**: FEAT-005-001 (primária), FEAT-005-002
**Componente**: COMP-006-013 (principal)
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

COMP-006-013 / FR-005-005, FR-005-012, FR-005-021, FR-005-023, FR-005-024 (FEAT-005-001) e FR-005-022 (FEAT-005-002) / NFR-005-002. Primeira tela da linha de produção: casca Server Component em `(interno)/content/page.tsx` mais um client component `ContentList` que consome `useListRawContentsQuery` (endpoint criado em TASK-006-010). Três estados observáveis da **listagem** (carregando / vazio com orientação em pt-BR / falha com opção de repetir), ordenação **vinda do backend** (mais recente primeiro — a tela não re-ordena), e por item: resumo do texto, disciplina, tema/assunto, rótulo pt-BR da classe do radar, ao menos a citação do dispositivo, indicador "tem Quebra da regra" e via de acesso à Quebra daquele conteúdo. O alcance por papel (EDITOR vê o que registrou; ADMIN vê tudo) e o filtro de remoção reversível são **do serviço** (TASK-006-008); aqui a tela apenas exibe a lista que recebe. A listagem é **read-only** — não há ação de salvar/enviar nesta tela (o "controle de envio desabilitado" de AC-005-005 é do formulário, TASK-006-013; aqui o único indicador assíncrono é o *spinner de `isLoading` da listagem*).

Gates previstos: g1 (Jest + Testing Library, componente montado contra a `api` real) · g9 (screenVerify — AC-005-033) · g11 (product-designer — a fatia toca superfície de interface); g8 e g10 são n/a (não toca autorização/sessão nem superfície de custo de consulta).

## Escopo

### Inclui

- `mnemonicos-frontend/src/app/(interno)/content/page.tsx` — Server Component (sem `'use client'`, exporta `metadata` com título pt-BR), no padrão de `(interno)/studio/page.tsx`; renderiza `<ContentList />`. Fica sob o `layout.tsx` do grupo `(interno)` já existente (`InternalShell`).
- `mnemonicos-frontend/src/components/content-list.tsx` — `'use client'` (`ContentList`). `useListRawContentsQuery()` de `src/store/api.ts`. Ramos: `isLoading` → indicador de progresso (`role="status"`, texto pt-BR), sem itens; `isError` → mensagem pt-BR + controle "Tentar novamente" que dispara `refetch`; `isSuccess` com lista vazia → mensagem pt-BR que orienta a próxima ação (primeira execução da fábrica ou remoção do último item); `isSuccess` com itens → a lista.
- Renderização de cada `RawContentSummary` **na ordem recebida do backend** (`createdAt desc` — sem `sort`/`filter` client-side): resumo do texto normativo, disciplina, tema/assunto, rótulo pt-BR da classe do radar (`PROOF_RADAR_CLASS_LABELS` de `src/types/domain.ts`), ao menos a citação do dispositivo (`sourceCitation`), indicador de que o Conteúdo bruto **tem Quebra da regra** (flag do `RawContentSummary` — nome definido em TASK-006-004/TASK-006-008) e via de acesso à Quebra da regra daquele conteúdo (navegação para `/content/<id>/breakdown`).
- `mnemonicos-frontend/src/components/content-list.test.tsx` — colocado; Testing Library; `ContentList` **montado** contra a `api` real (`makeStore()` + `fetch` mockado por cenário; `testEnvironment` `test/jsdom-fetch-env.js`).
- Todo texto de interface em pt-BR; vocabulário de domínio (classe do radar) sempre pelo mapa de `src/types/domain.ts`, nunca literal solto no JSX.

### Não inclui

- Filtro da listagem (por disciplina, tema/assunto ou classe do radar) — F10.
- Exibição da prioridade de apresentação Alta/Média/Baixa e o mapa/função que a deriva — F10 (DEC-006-009).
- Formulário de criação/edição/remoção de Conteúdo bruto e os três estados **da ação de salvar** (AC-005-005/-006/-007/-010) — TASK-006-013.
- Tela da Quebra da regra em si — TASK-006-014.
- Endpoints/hooks RTK Query (`useListRawContentsQuery` etc.) — TASK-006-010.
- Registro do segmento de rota `content` (`INTERNAL_ROUTE_PREFIXES` + `config.matcher` do `proxy.ts`) — TASK-006-003.
- Os mapas `PROOF_RADAR_CLASS_LABELS` / `NORMATIVE_SOURCE_TYPE_LABELS` — nascem em TASK-006-004.
- Alcance por papel e filtro `deletedAt: null` — são do serviço (TASK-006-008).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `(interno)/content/page.tsx` — Server Component com `export const metadata`; renderiza `<ContentList />`.
2. `content-list.tsx` (`'use client'`) — `useListRawContentsQuery()`; ramificar em `isLoading` / `isError` / `isSuccess`+vazio / `isSuccess`+itens; no erro, controle que chama `refetch()`.
3. Renderizar cada item de `data.data` na ordem recebida (sem `sort`); por item: resumo, disciplina, tema, `PROOF_RADAR_CLASS_LABELS[item.radarClass]`, citação do dispositivo, indicador "tem Quebra" e um `Link` para `/content/${item.id}/breakdown` como via de acesso.
4. Textos pt-BR; classe do radar sempre via o mapa de `domain.ts`.
5. `content-list.test.tsx` — montar com `makeStore()` + `fetch` mockado por cenário (`test/jsdom-fetch-env.js`).

## Critérios de pronto

- [ ] **[Design] `EMENDA R3 (pós 2ª rodada de gate 11/1-7)` — UMA SÓ ação primária de registro, em qualquer estado**: a rodada anterior duplicou o link "Novo conteúdo bruto" (cabeçalho `page.tsx:20` + `content-list.tsx:68` no vazio + `content-list.tsx:78` no ramo com itens) — 2 links simultâneos com 2 estilos diferentes na mesma tela. Condição, não endereço: **a tela `/content` oferece exatamente UMA ação primária "Novo conteúdo bruto", em qualquer estado (vazio, com itens, erro)**. Manter no cabeçalho de `page.tsx` (renderizado em todos os estados); remover os 2 links de `content-list.tsx` (vazio e com itens). Verificação executável — prova no nível COMPOSTO, um teste de componente isolado não falsifica isto: montar `ContentPage()` (ou o par `page.tsx`+`ContentList`) com store real, `fetch` mockado por estado, e `getAllByRole('link', { name: /novo conteúdo bruto/i })` tem `toHaveLength(1)` nos estados vazio e com-itens. Fixada antes do código.
- [ ] **[Design] `EMENDA R3` — contraste no tema escuro**: `text-brand-600` (introduzido na rodada anterior) mede 3.0-3.2:1 sobre os tons escuros do `@theme` (`globals.css`, bloco `prefers-color-scheme: dark`) — abaixo do piso 4.5:1. Usar `text-brand-600 dark:text-brand-400` (ou, preferencialmente, criar `@utility text-link` em `globals.css` com `--link: var(--color-brand-600)` em `:root` e `--link: var(--color-brand-400)` no bloco dark, aplicando a mesma classe aos 5 pontos de link de navegação da wave — listagem, cabeçalhos, formulário, Quebra — fechando junto a consistência visual entre as 3 telas).
- [ ] **[Design] `EMENDA pós gate 11` — via de edição por item**: cada item de `content-list.tsx` ganha um `Link` "Editar conteúdo bruto" → `/content/${item.id}` (mesmo `id` do item), ao lado do link da Quebra — hoje só existe navegação para a Quebra, não para editar. Verificação executável: `getByRole('link', { name: /editar conteúdo bruto/i })` dentro do item, com `href` == `/content/${item.id}`.
- [ ] **[Design] `EMENDA pós gate 11` — rótulo do link da Quebra deriva de `hasRuleBreakdown`**: hoje "Ver Quebra da regra" aparece em item sem Quebra também, prometendo algo que não existe. Alterar para "Ver Quebra da regra" quando `item.hasRuleBreakdown === true` e "Registrar Quebra da regra" quando `false` — mesmo `href`. Verificação executável: item com a flag `true` mostra o 1º rótulo, item com `false` mostra o 2º.
- [ ] **[Design] `EMENDA pós gate 11` — contraste AA**: `text-recall-600` do indicador "Tem Quebra da regra" (`content-list.tsx`) e `text-brand-500` do link da Quebra ficam abaixo de 4.5:1 no tema claro. Trocar o link para `text-brand-600` (6.03:1) e o indicador para `text-muted` (7.08:1 — o rótulo textual, não a cor, carrega a informação). Verificação: inspeção visual/grep dos tokens usados (sem oráculo automatizado de contraste nesta wave).
- [ ] **[Design] `EMENDA pós gate 11` — espaçamento consistente entre estados**: remover o `p-6` extra dos ramos de estado de `ContentList` (carregando/vazio/lista já vivem dentro do container acolchoado do shell — `p-6` duplica o recuo). As 3 trilhas (carregando/vazio/lista) devem alinhar à mesma margem esquerda.
- [ ] `(interno)/content/page.tsx` é Server Component e compõe o client component `ContentList` — verificação executável: `npm --prefix mnemonicos-frontend test -- content-list` monta `ContentList` (`render` com `Provider`/`makeStore()`) e tem ≥1 asserção de conteúdo (`Tests: ≥1 passed`); `grep -nE "^['\"]use client['\"]" "mnemonicos-frontend/src/app/(interno)/content/page.tsx"` → sem resultado (a diretiva vive só em `content-list.tsx`, arquivo novo desta branch — comando também sem resultado no commit-pai por o arquivo não existir lá). Fixada antes do código.
- [ ] Testes cobrem **AC-005-034** (faceta render da listagem — três estados observáveis: *carregando* / *vazio* / *falha*) — `ContentList` montado contra a `api` real expõe os três estados de `useListRawContentsQuery`: **carregando** (`role="status"` + texto pt-BR — o *spinner de `isLoading` da listagem*, nenhum item no DOM), **vazio** (`isSuccess`, `data.data.length === 0` → mensagem pt-BR que orienta a próxima ação), **falha** (`isError` → mensagem pt-BR + controle "Tentar novamente" que chama `refetch`). Verificação executável: `npm --prefix mnemonicos-frontend test -- content-list` → 3 casos, `fetch` mockado por estado (pending sem resolver / `200 {data:[],page:1,perPage:20,total:0}` / `500`); saída `Tests: 3 passed` (ou mais). Falsificável: remover o ramo `isError` → o caso de falha não acha o controle de repetir (vermelho); remover a guarda `isLoading` → o caso carregando acha item ou não acha `role="status"` (vermelho). Fixada antes do código.
- [ ] Testes cobrem **AC-005-018** (faceta render — a tela exibe a lista que recebeu, sem re-ordenar, filtrar ou ocultar) — `ContentList` montado; `fetch` mockado devolve `Paginated<RawContentSummary>` com N itens numa ordem dada → o DOM lista **exatamente** esses N itens, **na mesma ordem** do payload. Verificação executável: `npm --prefix mnemonicos-frontend test -- content-list` → payload de 3 itens já em `createdAt desc` (ordem fixada pelo backend, TASK-006-008); asserção sobre a sequência de textos/`role` de item no DOM == sequência do payload. Falsificável: inserir `.sort(...)` ou `.filter(...)` client-side → a ordem ou a contagem diverge do payload (vermelho). Fixada antes do código.
- [ ] Testes cobrem **AC-005-016** e **AC-005-025** — cada item exibe resumo do texto, disciplina, tema/assunto, rótulo pt-BR da classe do radar, **ao menos a citação do dispositivo** (`sourceCitation` — AC-005-016) e um indicador de que o Conteúdo bruto **tem Quebra da regra** (flag do `RawContentSummary` — AC-005-025). Verificação executável: `npm --prefix mnemonicos-frontend test -- content-list` → payload com um item com `sourceCitation` preenchida e a flag "tem Quebra" verdadeira e outro com a flag falsa → `getByText` da citação no 1º item; indicador "tem Quebra" presente no 1º e ausente no 2º. Falsificável: não renderizar a citação → 1º caso vermelho; fixar o indicador como sempre-presente → 2º caso vermelho. Fixada antes do código.
- [ ] Testes cobrem **AC-005-029** (faceta tela) — toda string visível da listagem está em pt-BR; o rótulo da classe do radar vem de `PROOF_RADAR_CLASS_LABELS`, nunca do valor cru. Verificação executável: `npm --prefix mnemonicos-frontend test -- content-list` → para um item com `radarClass: 'PEGADINHA'`, o DOM mostra `PROOF_RADAR_CLASS_LABELS.PEGADINHA` (valor pt-BR importado no teste do próprio mapa) e **não** a string `'PEGADINHA'`. Falsificável: renderizar `item.radarClass` cru → o teste acha `'PEGADINHA'` e não o rótulo (vermelho). Fixada antes do código.
- [ ] Item do Inclui **"ordenação vinda do backend — a tela não re-ordena"** (sem AC próprio) — coberto pela asserção de ordem do teste de AC-005-018 (ordem do DOM == ordem do payload) e por **checagem estrutural com comentário excluído do universo buscado (contrato §273(b))**: `grep -vE "^\s*(//|\*|/\*)" "mnemonicos-frontend/src/components/content-list.tsx" | grep -nE "\.(sort|reverse)\("` → **sem resultado** (arquivo novo desta branch; sem resultado também no commit-pai). Fixada antes do código.
- [ ] Item do Inclui **"via de acesso à Quebra da regra por item"** (sem AC no gate 1 — a caminhada ponta-a-ponta é AC-005-033 no gate 9) — cada item renderiza um controle de navegação para `/content/<id>/breakdown` com o `href` correto para aquele `id`. Verificação executável: `npm --prefix mnemonicos-frontend test -- content-list` → payload com item `id: "abc"` → `getByRole('link', { name: /quebra da regra/i })` dentro daquele item tem `href="/content/abc/breakdown"`. Falsificável: `href` omitido, com outra rota ou outro `id` → vermelho. Fixada antes do código.
- [ ] **Lição ativa [Testes] "Predicado de decisão de UI a partir de estado de RTK Query só se prova no componente montado"** aplicada a `content-list.tsx`. Texto da lição (solução): *"Predicado que decide render/navegação a partir de estado de RTK Query → oráculo que passa pelo componente MONTADO contra a `api` real (store real via `makeStore()` + `fetch` mockado). O teste da função pura complementa, nunca substitui. Critério de aceite: o mutante morre no teste montado. `resetApiState()` (login/logout) pode desmontar a subárvore dentro de um único flush — polling de 1ms não vê. Asserção de presença no DOM não acusa: o oráculo precisa de contador de montagem/efeito ou de asserção sobre estado local que a remontagem destruiria."* Item verificável: os ramos `isLoading` / `isError` / `isSuccess` / vazio de `ContentList` provam-se **no componente montado** contra a `api` real (`makeStore()` + `fetch` mockado via `test/jsdom-fetch-env.js`), não por função pura sobre `api.endpoints.listRawContents.select()`; teste de função pura só complementa. O mutante que remove a guarda de estado (renderizar a lista sem checar `isLoading`/`isError`) **morre no teste montado**. Se o controle "Tentar novamente" desencadeia `refetch`/remontagem, um **contador de montagem/efeito** cobre essa janela. Verificação executável: `npm --prefix mnemonicos-frontend test -- content-list` → os 3 casos de estado são montados (`render(<Provider store={makeStore()}>…)`), não `select()` sobre store sem subscritor; `Tests: ≥3 passed`. Fixada antes do código.
- [ ] `npm --prefix mnemonicos-frontend run build` → exit 0 — a rota `(interno)/content` compila (fronteira `'use client'` correta: `page.tsx` Server Component, `content-list.tsx` client; nenhum Server Component `async` marcado `'use client'`). Baseline: build verde hoje nos dois repos (exploração — fe jest 90/90, typecheck/lint/build limpos). Falsificável: marcar `content-list.tsx` como Server Component `async` usando hook de cliente → build aborta apontando `./src/components/content-list.tsx`. Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-frontend run lint` → exit 0 (baseline capturada no início da TASK) e `npm --prefix mnemonicos-frontend run typecheck` → exit 0.
- [ ] Padrão de commit respeitado (Conventional Commits — `feat:`).
- [ ] Aderência à stack/padrões da ficha e do perfil (`next-16.md`: Server Component por default e `'use client'` no componente mais fundo §4; estado de servidor só em RTK Query §6.5; `makeStore()` função, nunca singleton; rótulos pt-BR do mapa de `domain.ts` §3; teste por papel/texto; guidelines de projeto vencem o perfil em conflito).
- [ ] Code review aprovado.

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente**: frontend Next em `http://localhost:3000` (`next dev`, sem base path); rota da listagem `http://localhost:3000/content`; rota-alvo da navegação `http://localhost:3000/content/<id>/breakdown`. API backend em `http://localhost:3333/api/v1`. Realm `app` (dev local; Postgres do `mnemonicos-backend/docker-compose.yml`).

**Autenticação — pré-condição**: popular `keelson.local.json` (dev-local, **gitignored** — passo do Diretor/dev, como o `.env`) a partir de `keelson.local.example.json` — realm `app` (`loginPath: "/login"`) **+ realm `editor`** (molde acrescentado por TASK-006-005), com as credenciais do **EDITOR de dev** vindas de `SEED_EDITOR_EMAIL` / `SEED_EDITOR_PASSWORD`. O `mnemonicos-backend/.env` precisa de `SEED_EDITOR_*` **reais** e a semente (`db:seed`) **já rodada**. O gate injeta as credenciais do realm; **nunca chutar** (HANDOFF-PLAN-003, bloco `sonda`). O molde `keelson.local.example.json` (realm `editor`) e a função de seed `seedDevEditor` são entregues por **TASK-006-005**.

**Sujeito concreto**: o **EDITOR de dev** semeado por TASK-006-005 (env-gated `SEED_EDITOR_EMAIL` / `SEED_EDITOR_PASSWORD`; ausência = nenhum EDITOR criado); a credencial correspondente no realm `editor` de `keelson.local.json`. O ADMIN semeado (`SEED_ADMIN_EMAIL` / `SEED_ADMIN_PASSWORD`) fica disponível para montagem/restauração.

**Pré-condição — montar**:
1. `mnemonicos-backend/.env` com `SEED_ADMIN_EMAIL`/`SEED_ADMIN_PASSWORD` **e** `SEED_EDITOR_EMAIL`/`SEED_EDITOR_PASSWORD` preenchidos (não placeholders). `npm --prefix mnemonicos-backend run db:up` (Docker Postgres); `npm --prefix mnemonicos-backend run db:deploy` (aplica a migração de F2 — TASK-006-001) — **⚠️ execução de migração: confirmar com o Diretor antes (regra do projeto / TRISK-006-001)**; `npm --prefix mnemonicos-backend run db:seed` → carrega Direito Tributário / Obrigação Tributária, 1 ADMIN, 1 EDITOR de dev e ≥1 `RawContent` (autor = ADMIN) com `RuleBreakdown` completa.
2. Subir os apps: `npm --prefix mnemonicos-backend run dev` (:3333) e `npm --prefix mnemonicos-frontend run dev` (:3000); confirmar `NEXT_PUBLIC_API_BASE_URL` apontando para :3333.
3. O EDITOR de dev **só alcança os Conteúdos brutos que registrou** (alcance por autor — TASK-006-008); o `RawContent` semeado é do ADMIN. Logo, autenticado como o EDITOR de dev, registrar **um** Conteúdo bruto — pela tela `/content/new` (TASK-006-013) **ou** `POST http://localhost:3333/api/v1/contents` com a sessão do EDITOR (fallback, se a via de tela falhar) — com texto normativo, disciplina, tema semeado e classe do radar. Anotar o `id` retornado: é o item que a listagem exibirá e do qual o passo navega.

**Pré-condição — restaurar** (ao fim):
1. Obter o id do EDITOR de dev: `SELECT id FROM users WHERE email = '<SEED_EDITOR_EMAIL>'` (ou via `GET http://localhost:3333/api/v1/users` autenticado como ADMIN).
2. No Postgres local — `DELETE FROM rule_breakdowns WHERE "rawContentId" IN (SELECT id FROM raw_contents WHERE "authorId" = '<id do EDITOR de dev>');` · `DELETE FROM raw_contents WHERE "authorId" = '<id do EDITOR de dev>';` · `DELETE FROM sessions WHERE "userId" = '<id do EDITOR de dev>';` — **nunca** truncar todas as sessões do realm dev compartilhado. Alternativa: re-seed idempotente (resolução 2 do manifesto).

**Passo (AC-005-033) — navegação da listagem para a Quebra (o passo cruza a fronteira de rota)**:
1. Em `http://localhost:3000/login`, autenticar como o EDITOR de dev (`SEED_EDITOR_EMAIL` / `SEED_EDITOR_PASSWORD`).
2. Navegar para `http://localhost:3000/content`. A listagem renderiza o Conteúdo bruto registrado na pré-condição (mais recente primeiro), exibindo resumo do texto, disciplina, tema/assunto, rótulo pt-BR da classe do radar, ao menos a citação do dispositivo e o indicador "tem Quebra da regra".
3. Acionar, **naquele item**, a via de acesso à Quebra da regra.
4. **Esperado**: o navegador vai para `http://localhost:3000/content/<id>/breakdown` — o `<id>` exato daquele Conteúdo bruto — e a tela da Quebra da regra desse conteúdo é exibida (TASK-006-014). É o gate falsificável de AC-005-033: `href`/rota errados, `id` trocado ou 404 reprovam o passo.

**Nota (handoffs anteriores do slug)**: HANDOFF-PLAN-003 registra V6 (falha transitória de logout) como não-exercitável **por exigir 500 seletivo numa rota** — não é o caso desta navegação, que é trânsito de rota simples. As caminhadas V1–V5 de F1 (login, guard, redirect, logout de sucesso) foram **exercitadas com sucesso local em 2026-09-01** (Playwright, contra o código mergeado) — o ambiente de tela funciona; este passo é **tentado localmente**. Só se o ambiente de tela falhar na execução o gate 9 vira `pendente_handoff` (Etapa 4.6 do `/keelson:auto`; resolução 1 do manifesto).

## Riscos específicos

- Repos symlinkados (lição [Exploração]): editar e verificar sempre pelo caminho **dentro** do link (`mnemonicos-frontend/src/...`); ausência detectada por varredura não é fato.
- **Alcance por autor**: o EDITOR de dev só vê os Conteúdos brutos que registrou — o `RawContent` semeado é do ADMIN. A pré-condição do gate 9 **cria** o item como o EDITOR, senão a listagem fica vazia e não há o que acionar.
- Depende de TASK-006-010 (hook `useListRawContentsQuery` em `src/store/api.ts`), TASK-006-011 (rota `GET /contents` sob a barreira) e TASK-006-003 (segmento `content` em `INTERNAL_ROUTE_PREFIXES` + `config.matcher` do `proxy.ts`) — sem os três a rota não é guardada nem servida.
- `test/jsdom-fetch-env.js` (`testEnvironment` custom que estende `jest-environment-jsdom`, criado em F1/TASK-003-015) é o harness dos testes montados contra a `api` real — **sem dependência nova**.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-40
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
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa; AC-005-033 (rota /content → /content/<id>/breakdown); receita e restauração no Roteiro do gate 9 desta TASK; sujeito EDITOR de dev (SEED_EDITOR_*)>

**Notas**: 
