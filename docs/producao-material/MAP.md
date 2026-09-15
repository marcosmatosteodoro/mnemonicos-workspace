# MAP — producao-material

> Espelho do território de código deste slug (contrato: map-contract.md do keelson).
> Acelerador de exploração — régua 4.58: confira a âncora antes de decidir por ela.
> Checagem mecânica: scripts/map-check.sh (idade e âncoras; WARNING nunca bloqueia).

## Acervo (modelo de dados)

- [2026-08-27 · epico] `Mnemonic.hook`/`Mnemonic.decoding` são campos de texto único — a tira mnemônica como sequência ordenada de quadros não tem representação estrutural ainda; F4 substitui, não estende — mnemonicos-backend/prisma/schema.prisma:96-120
- [2026-08-27 · epico] Não existe modelo para radar de prova/priorização, contraste, pegadinha nem associação visual/imagem no schema atual — 4 das 10 camadas do método sem cobertura, nenhuma na forma que a TAP pede — mnemonicos-backend/prisma/schema.prisma:1-189
- [2026-09-06 · PLAN-006] **Corrige entrada acima**: seed trocado para Direito Tributário/Obrigação Tributária + EDITOR de dev (`seedMaterial`, `authorId` = ADMIN; distinto do `authorId` do EDITOR que a tela produz) — mnemonicos-backend/prisma/seed-material.ts:126-168
- [2026-09-06 · PLAN-006] `RawContent` (texto normativo + disciplina/tema + `radarClass`, soft-delete via `deletedAt`) e `RuleBreakdown` 1:1 (5 blocos + síntese, sem `deletedAt` própria — herda inalcançabilidade do pai) são o modelo novo da fábrica de F2 — mnemonicos-backend/prisma/schema.prisma:263-331
- [2026-09-06 · PLAN-006] Filtro `deletedAt: null` centralizado em `contents.service.ts` (não redeclarado por chamador) — todo caminho de leitura novo (listagem/detalhe/Quebra/censo) herda daqui, não reimplementa — mnemonicos-backend/src/modules/contents/contents.service.ts:1-408

## Identidade e autorização

- [2026-08-27 · epico] `User` com `passwordHash` Argon2id e `JWT_SECRET` validado no boot já existem no schema/config, mas nenhuma rota de login/registro os usa — F1 é quem primeiro os liga — mnemonicos-backend/prisma/schema.prisma:44-61
- [2026-08-27 · epico] `JWT_SECRET` é validado no boot em env.ts — mnemonicos-backend/src/config/env.ts:32-33
- [2026-08-27 · epico] `USER_ROLES` existe só no backend; frontend não tem os tipos correspondentes — fonte de dessincronia entre repos que F1/F2 precisam fechar — mnemonicos-backend/src/domain/types.ts:24-26
- [2026-08-31 · F1] Sessão completa (branch `feat/producao-material-mnemora-studio`, aguarda merge): tabela `Session` só com hashes, `familyId` agrupa a rotação, `revokedAt`; `auth.service.ts` faz login/refresh/rotação/reuso→revogação da família/logout/`getSessionUser`/`changeOwnPassword`; rotação é função pura recebendo `now` — mnemonicos-backend/src/modules/auth/auth.service.ts:1-200
- [2026-08-31 · F1] Rotação de sessão como lógica pura sem I/O, `now` por parâmetro — mnemonicos-backend/src/modules/auth/session-rotation.ts:1-90
- [2026-08-31 · F1] Barreira deny-by-default: `ROUTE_ROLES` indexado por `"<MÉTODO> <caminho>"` em `route-roles.ts`; `requireRole(method,path,...roles)` declara na montagem, `sealRouteRoles()` sela pós-boot, `requireAuth` é o piso (nega sessão indefinida OU papel fora do conjunto) — mnemonicos-backend/src/http/middlewares/authenticate.ts:1-120
- [2026-08-31 · F1] `assertDenyByDefault(apiRoutes)` no escopo do módulo derruba o boot em topologia adversarial; `PUBLIC_PATH_ALLOWLIST` são pares método+caminho (`isPublicPath` por igualdade exata) — mnemonicos-backend/src/http/public-paths.ts:1-60
- [2026-08-31 · F1] `route-authz-matrix.integration.test.ts` é a fonte de medição da métrica §1.3 da SPEC-002 (censo de 12 rotas, 28 asserções) — mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts:1-40
- [2026-08-31 · F1] `USER_ROLES`/`UserRole`/`SessionUser` agora espelhados no frontend, mantidos à mão em sincronia com o backend — mnemonicos-frontend/src/types/domain.ts:1-40
- [2026-08-31 · F1] Frontend de sessão: `baseQueryWithReauth` (401 → `POST /auth/refresh` 1× → repete; morta → `resetApiState()` + `/login?sessao=expirada`); `logout.onQueryStarted` reseta o cache só após sucesso — mnemonicos-frontend/src/store/api.ts:1-220
- [2026-08-31 · F1] Guard de navegação: `proxy.ts` `config.matcher` é array literal (o Next lê `config` por AST estático — sem `.flatMap`/spread); a equivalência com `INTERNAL_ROUTE_PREFIXES` vive no teste; `(interno)` é route group, nunca catch-all por exclusão — mnemonicos-frontend/src/proxy.ts:42-52
- [2026-08-31 · F1] `INTERNAL_ROUTE_PREFIXES` / `INTERNAL_MIN_ROLE` / `roleSatisfies` — fonte única do contrato de área interna — mnemonicos-frontend/src/lib/internal-routes.ts:1-40
- [2026-08-31 · F1] Telas mínimas de F1: `/login` (`LoginForm`, 3 estados, `<form method="post">`, gate de hidratação) e `(interno)/` (`InternalShell` resolve `me`, 3 estados de navegação protegida + logout com 3 estados). Apresentação, não fronteira — mnemonicos-frontend/src/components/internal-shell.tsx:1-125

## Revisão espaçada (dormente por A-005)

- [2026-08-27 · epico] Scheduler é variante SM-2 com ease factor dinâmico e teto de 365 dias — incompatível por design com os 6 marcos fixos R0/R24/R3/R7/R14/R30 que a TAP pede (F7 não reusa, imprime como protocolo) — mnemonicos-backend/src/modules/review/scheduler.ts:43-93
- [2026-08-27 · epico] Comportamento do scheduler é provado em teste unitário — mnemonicos-backend/tests/unit/scheduler.test.ts:40-58

## Rotas e contrato de API

- [2026-08-27 · epico] Rotas montadas hoje: só `health`, `health/db` e `disciplines` — F1/F2 partem de uma superfície quase vazia — mnemonicos-backend/src/http/routes.ts:9-10
- [2026-08-31 · F1] `apiRoutes` monta em ordem: `healthRoutes` (público) → auth pública (`POST /auth/login`, `/auth/refresh`) → `requireAuth` → auth protegida (`/auth/logout`, `/auth/me`, `/auth/change-password`) → `usersRoutes` (`requireRole('ADMIN')`) → `disciplinesRoutes` (`requireRole('EDITOR','ADMIN')`); `verifyOrigin` em toda mutação autenticada por cookie — mnemonicos-backend/src/http/routes.ts:1-60
- [2026-09-06 · PLAN-006] `contentsRoutes` acrescenta 7 rotas sob a mesma barreira (`requireRole('EDITOR','ADMIN')`), tripwire de `route-authz-matrix` atualizado de 12 para 19 pares — mnemonicos-backend/src/modules/contents/contents.routes.ts:1-144
- [2026-09-06 · PLAN-006] Rede de paridade cross-repo cobre DECLARAÇÃO×DECLARAÇÃO (enums + interfaces), não `select`×declaração — chave nova só no `select` do Prisma sem a mesma chave no frontend passa pelo typecheck e pelos 2 testes (RISK-006-006, gap conhecido, não fechado nesta fatia) — mnemonicos-backend/tests/unit/contents-frontend-contract.test.ts:1-40
- [2026-08-27 · epico] Frontend já chama `/mnemonics` e `/flashcards/due`, que não existem no backend — contrato adiantado, quebra em runtime sem o typecheck acusar; F2 precisa fechar isso primeiro — mnemonicos-frontend/src/store/api.ts:28-35
- [2026-08-27 · epico] Tipos de domínio do frontend não têm `CardState`/`Review` — espelho do `USER_ROLES` ausente do lado do backend — mnemonicos-frontend/src/types/domain.ts:41-83

## Produção de conteúdo bruto e Quebra da regra (F2 · PLAN-006)

- [2026-09-06 · PLAN-006] Telas `(interno)/content` (listagem), `/content/new` (formulário) e `/content/[id]/breakdown` (Quebra da regra) — Server Component default, `'use client'` só onde há estado/evento — mnemonicos-frontend/src/app/(interno)/content/page.tsx:1-40
- [2026-09-06 · PLAN-006] Tokens de cor semântica `--link`/`--danger` (light/dark em `:root`/`@media (prefers-color-scheme: dark)`, expostos via `@utility text-link`/`@utility text-danger`) — padrão canônico do produto para texto de erro/sucesso/link, substitui literal de paleta Tailwind (`text-brand-500`/`text-red-500`, que falhava contraste AA num dos 2 temas) — mnemonicos-frontend/src/app/globals.css:31-78

## Instrumentação de etapas de produção (F3 · PLAN-010)

- [2026-09-06 · PLAN-010] `ProductionStageEvent` (append-only real — só `create`/`findMany`
  em todo o código escrito; sem `updatedAt`/`deletedAt`, a imutabilidade é ausência de
  caminho de update/delete, não campo de estado) + enums `ProductionStageType`
  (`CONTEUDO_BRUTO`, `QUEBRA_DA_REGRA` — extensível, F4-F9 acrescentam valor por migração
  aditiva) e `ProductionEventTransition` (`ABERTURA`/`CONCLUSAO`/`RETRABALHO`) — primeira
  tabela append-only real do projeto (antes greenfield) e primeira sequência monotônica
  (`sequence BigInt @default(autoincrement())`, desempata `occurredAt` idêntico) —
  mnemonicos-backend/prisma/schema.prisma:352-388.
- [2026-09-06 · PLAN-010] `production-events.service.ts` — módulo sem `.schema.ts` nem
  `.routes.ts` (nunca chamado por rota, só por outro `.service.ts`): `decideStageTransition`
  (regra pura, decide por histórico lido dentro da mesma tx — nenhum chamador sabe se é
  abertura/conclusão/retrabalho), `recordProductionStageEvent` (emissão, recebe o `tx` do
  chamador, nunca abre transação própria), `listProductionStageEvents` (leitura interna,
  sem rota) — mnemonicos-backend/src/modules/production-events/production-events.service.ts:1-105.
- [2026-09-06 · PLAN-010] `contents.service.ts` ganhou `prisma.$transaction` em
  `createRawContent`/`updateRawContent`/`saveRuleBreakdown` (antes 1 statement cada) —
  chama `recordProductionStageEvent` dentro do mesmo `tx`, fail-secure (falha na emissão
  reverte a mutação de negócio inteira). `softDeleteRawContent` não muda (nenhuma emissão
  na remoção) — mnemonicos-backend/src/modules/contents/contents.service.ts:78-490.
- [2026-09-06 · PLAN-010] Serialização do "1º salvamento" concorrente de
  `RuleBreakdown` (nunca 2 `CONCLUSAO` para o mesmo par) depende de propriedade EMERGENTE
  do lock de índice único de `RuleBreakdown.rawContentId` (de F2) — não de mecanismo desta
  fatia; provado por mutation testing (mutante que reordena emissão antes do upsert mata o
  teste de concorrência). Garantia é por-chamador: um 3º consumidor futuro (F4-F9) que
  emita antes de escrever sua própria linha reintroduz o risco — considerar índice único
  parcial `(rawContentId, stageType) WHERE transitionType='CONCLUSAO'` se isso acontecer.
- [2026-09-06 · PLAN-010] `tests/support/production-events-fixtures.ts` — primeiro helper
  de fixture compartilhado do projeto (perfil §7); `createUser`/`createTopic`/
  `createRawContent` usados pelos 2 arquivos de teste de `production-events`. Ainda
  convivem 6 cópias locais equivalentes em outros arquivos de teste (`auth.routes`,
  `auth.service`, `contents`, `contents.service`, `disciplines`, `users`) — consolidação
  pendente, fora do escopo desta fatia.

## Tira mnemônica como sequência de quadros (F4 · PLAN-012)

- [2026-09-07 · PLAN-012] **Corrige a entrada da linha 9 acima**: `MnemonicStrip` (1:1
  `RuleBreakdown`, `@@unique(ruleBreakdownId)`) + `MnemonicFrame` (N:1, posição indexada,
  `@@unique([stripId,position])` como defesa em profundidade contra duplicidade) substituem
  `Mnemonic.hook`/`Mnemonic.decoding` para o fluxo novo — o modelo legado permanece intacto no
  schema (migração 100% aditiva, DEC-012-010), sem consumidor de código — mnemonicos-backend/prisma/schema.prisma (models MnemonicStrip/MnemonicFrame).
- [2026-09-07 · PLAN-012] `tira.service.ts` — módulo em camadas (schema Zod → service com
  `$transaction` → routes), reusa `assertRawContentReachable` de `contents.service.ts` (F2,
  exportado por TASK-012-002) como guarda de alcance por autoria — nunca reescrita. Funções:
  `buildInitialFrames` (pura, deriva Quadros dos Blocos não-vazios da Quebra), `openMnemonicStrip`
  (get-or-generate idempotente, chamada só pelo `POST`, DEC-012-008 concorrência via P2002-catch-fora-da-transação),
  `getMnemonicStrip` (leitura pura, 404 se ainda não aberta — nasceu na EMENDA de Wave 6/DEC-012-011),
  `assertStripPrerequisites` (guarda comum extraída, chamada por ambas as funções de abertura),
  `reassignPositions`/`applyPositions` (primitiva de reindexação atômica em 2 fases, DEC-012-003 —
  offset para faixa negativa antes das posições finais, evita colisão de unique constraint),
  `reorderMnemonicFrames`/`addMnemonicFrame`/`updateMnemonicFrameText`/`removeMnemonicFrame` (CRUD,
  todos reusando a primitiva de reindexação) — mnemonicos-backend/src/modules/tira/tira.service.ts:1-250.
- [2026-09-07 · PLAN-012] **DEC-012-011 supersede DEC-012-009** (furo no plano, Wave 5): a geração
  da Tira nasceu como `GET /contents/:id/strip` get-or-generate — achado de CSRF do
  `security-engineer` (cookie de sessão `sameSite: 'lax'` acompanha navegação top-level, e a regra
  repo-wide do projeto proíbe `verifyOrigin` em `GET`) forçou a migração: `GET` virou leitura pura
  (404 se ainda não aberta), a geração migrou para `POST /contents/:id/strip` (com `verifyOrigin`).
  Qualquer novo endpoint get-or-generate futuro no projeto segue este padrão desde a largada, não o
  padrão antigo de `DEC-012-009` — mnemonicos-backend/src/modules/tira/tira.routes.ts:1-160.
- [2026-09-07 · PLAN-012] `tira.routes.ts` — 6 rotas em árvore plana sob a mesma barreira
  deny-by-default de `/contents` (tripwire `route-authz-matrix` 19→25): `GET`/`POST .../strip`,
  `POST/PATCH/DELETE .../strip/frames[/:frameId]`, `PUT .../strip/frames/order`. Confused deputy
  no `:frameId` (o `rawContentId` a autorizar é sempre resolvido pela CADEIA Frame→Strip→RuleBreakdown→RawContent,
  nunca aceito cru do path) — pendência herdada da Wave 1, fechada na faceta HTTP em TASK-012-008 —
  mnemonicos-backend/src/modules/tira/tira.routes.ts:1-160.
- [2026-09-07 · PLAN-012] Tela `(interno)/content/[id]/tira` — Server Component puro
  (`page.tsx`, cabeçalho canônico `h1`+`Link` de saída) + client component
  `mnemonic-strip-board.tsx` (CRUD/reordenação, 3 estados por ação, diálogo de confirmação de
  remoção com gestão de foco explícita — régua: todo setter de estado que decide o RAMO onde um
  diálogo condicional vive precisa de destino de foco, não só o setter que "parece dono" do
  diálogo). Link condicional de entrada em `rule-breakdown-form.tsx` (habilitado só com Quebra
  salva) — mnemonicos-frontend/src/components/mnemonic-strip-board.tsx:1-100.
- [2026-09-07 · PLAN-012] Lição recorrente nesta fatia (3 ocorrências, `lessons.md`): guarda de
  autoria reusada de outro módulo exige prova COMPORTAMENTAL própria por CADA novo método que lê
  ou escreve o dado escopado (leitura inclusive, não só escrita) — prova estrutural (leitura
  textual do fonte) é complemento de ORDEM, nunca substituto de alcance; fechamento contável
  reconferido a cada TASK que adiciona um método, nunca herdado do denominador da TASK anterior.

## Biblioteca visual reutilizável (F5 · PLAN-023)

- [2026-09-14 · PLAN-023] **Corrige a entrada da linha 10 acima**: `VisualAssociation`
  (imagem `Bytes`, categoria, descrição da função cognitiva, `authorId`) +
  `VisualAssociationLinkEvent` (log append-only de reuso, sem FK — sobrevive à remoção da
  associação, DEC-023-011) agora existem; `MnemonicFrame.visualAssociationId` (N:1,
  `onDelete: SetNull`) é o vínculo. `ASSOCIACAO_VISUAL` estende `ProductionStageType`
  (aditivo) — mnemonicos-backend/prisma/schema.prisma (models `VisualAssociation`/
  `VisualAssociationLinkEvent`).
- [2026-09-14 · PLAN-023] `visual-associations.service.ts` — módulo único cobrindo TODO o
  CRUD + leitura em massa do acervo (schema Zod → este service → routes): `create`/
  `updateVisualAssociation` (guarda `assertVisualAssociationWritable`, autor ou ADMIN),
  `removeVisualAssociation` (trava de vínculo ativo — ver corrida abaixo),
  `listVisualAssociations`/`listVisualAssociationCategories`/`normalizeCategoryKey`/
  `suggestCategories` (leitura comum a EDITOR/ADMIN, sem guarda de autoria — FR-022-023),
  `getVisualAssociationBinary` (leitura pura do binário) — todas com `select` explícito
  excluindo `imageData` exceto a última — mnemonicos-backend/src/modules/visual-associations/visual-associations.service.ts:1-180.
- [2026-09-14 · PLAN-023] **Corrida TOCTOU real sob READ COMMITTED**: `deleteMany` com
  `where` condicional sobre tabela FILHA (`frames: { none: ... } }`) NÃO é atômico contra
  escrita concorrente na tabela filha quando há FK `ON DELETE SET NULL` — o predicado é
  avaliado no snapshot do statement, não reavaliado após espera de lock. Fechado travando
  a linha PAI (`tx.$queryRaw` `SELECT ... FOR UPDATE`, parametrizado) como 1º statement da
  `$transaction`, antes de qualquer decisão — padrão a repetir em qualquer corrida futura
  da mesma forma (predicado sobre relação, nunca sobre a própria linha escrita) —
  mnemonicos-backend/src/modules/visual-associations/visual-associations.service.ts
  (`removeVisualAssociation`).
- [2026-09-14 · PLAN-023] **`Content-Type` de resposta binária nunca ecoa coluna livre**:
  `GET /visual-associations/:id/image` valida `mimeType` (coluna `String`, não enum de
  banco) contra `IMAGE_MIME_TYPE_ALLOWLIST` fechado antes do header — 1ª rota não-JSON do
  backend inteiro (`res.type(...).send(Buffer)`, nunca `express.static`/`sendFile`) —
  mnemonicos-backend/src/modules/visual-associations/visual-associations.routes.ts:70-160.
- [2026-09-14 · PLAN-023] **Filtro Prisma `mode: 'insensitive'` compila para `ILIKE`**: o
  valor do CLIENTE em `equals`/`contains` com `mode: 'insensitive'` é interpretado como
  PADRÃO LIKE (`%`/`_`/`\` viram curinga), não igualdade — `escapeLikeMetacharacters`
  escapa antes de montar o filtro; a mesma classe (não corrigida, fora do escopo deste
  PLAN) existe em `disciplines.service.ts`/`users.service.ts` —
  mnemonicos-backend/src/modules/visual-associations/visual-associations.service.ts
  (`listVisualAssociations`).
- [2026-09-14 · PLAN-023] Frontend: `visual-association-list-states.tsx` (módulo canônico
  compartilhado — casca de estados loading/erro+retry/vazio + `visualAssociationImageUrl`)
  consumido por `visual-association-picker.tsx` (seletor embutido), `visual-library-board.tsx`
  (CRUD completo da tela `/visual-library`, confirmação de remoção, validação de
  obrigatórios, `aria-label` único por item) e o enxerto em `mnemonic-strip-board.tsx`
  (vínculo/desvínculo/substituição por Quadro, reusa o `role="alertdialog"` de remoção
  para um 2º propósito — trava cruzada `isAnyDialogOpen` impede 2 diálogos simultâneos
  entre Quadros diferentes, mirando só os GATILHOS, nunca o bloco que hospeda feedback
  assíncrono de outro Quadro) — mnemonicos-frontend/src/components/visual-association-list-states.tsx:1-60.
- [2026-09-14 · PLAN-023] `/visual-library` — Server Component casca (`content/page.tsx` é
  o molde) + `INTERNAL_ROUTE_PREFIXES`/`config.matcher` (guard de navegação); ainda sem
  entrada de menu (mesma condição de `/content`, sem navegação principal no produto) —
  mnemonicos-frontend/src/app/(interno)/visual-library/page.tsx:1-20.
- [2026-09-14 · PLAN-023] Mutations `linkVisualAssociationToFrame`/
  `unlinkVisualAssociationFromFrame` invalidam AS DUAS tags RTK Query (`MnemonicStrip` E
  `VisualAssociationList`) — o mesmo `linkCount` é lido por 2 consumidores com tags
  distintas (picker embutido × board do acervo); mutation que altera campo lido por 2+
  queries precisa invalidar todas — mnemonicos-frontend/src/store/api.ts (linhas das 2
  mutações de vínculo).

## Publicação — pipeline de PDF (F6 · PLAN-025)

- [2026-09-14 · PLAN-025] **Corrige a entrada abaixo**: geração/exportação de PDF agora
  existe, motor `pdf-lib` (DEC-025-001, irreversível na prática — fixa o padrão visual das
  10 camadas do método), sem headless browser (compatível com `maxDuration:15`/`memory:1024`
  do Vercel serverless). Migração desta fatia:
  `mnemonicos-backend/prisma/migrations/20260914175940_add_publicacao_pdf_publication_event/migration.sql`
  — **ainda não aplicada no Postgres de DEV** (aplicada só no `mnemonicos_test`, via
  harness); autorização de aplicação em dev é ato do Diretor, pendente na Entrega.
- [2026-09-14 · PLAN-025] `publication.service.ts` — `exportPublication` (orquestração
  principal, linha 239) lê a Quebra da regra e lança `NotFoundError` se ausente
  (linhas 247-253); auto-gera a Tira via `openMnemonicStrip` quando ainda não existe
  (`resolveOrderedFramesForStrip`, linhas 164-181); grava, na MESMA `$transaction`, o
  evento genérico (`recordProductionStageEvent`) E o evento dedicado
  (`tx.publicationEvent.create`) nas linhas 262-273; teto de duração via `withDeadline`
  (linhas 98-109) lança `GenerationTimeoutError` (linha 101), invocado com
  `env.PUBLICATION_PDF_TIMEOUT_MS` (linhas 257-260). `assertRawContentExportable`
  (linhas 78-89) é a guarda NOVA para LEITURA de material existente — só existência +
  não soft-deleted, **sem** checagem de autoria — distinta da guarda de autoria
  (`assertRawContentReachable`/`assertStripPrerequisites`, F4) usada quando a Tira precisa
  ser auto-gerada — mnemonicos-backend/src/modules/publication/publication.service.ts:1-280.
- [2026-09-14 · PLAN-025] `pdf-composer.ts` — `buildStripPdf` (variante Tira, linha 233) e
  `buildSummaryPdf` (variante Resumo, linha 181). Imagem irrenderável degrada para
  texto-only em vez de falhar o documento inteiro: `embedFrameImage` (linhas 152-172)
  devolve `{ skipReason }`, consumido por `onImageSkipped` (linhas 253-271) — a página
  segue só com texto. Regra "1 Quadro = 1 página": `for (const [frameIndex, frame] of
  frames.entries())` seguido de `createPage` por iteração (linhas 242-243). Constantes de
  layout/medida (margens, fontes, caixa máxima de imagem) vivem AQUI (linhas 46-69), não
  em `pdf-layout.ts` (que só tem `wrapTextToLines`, quebra de texto pura) —
  mnemonicos-backend/src/modules/publication/pdf-composer.ts:1-280.
- [2026-09-14 · PLAN-025] Defesa contra decompression bomb via PNG, endurecida em 3
  rodadas de gate 8 na Wave 2 (achado→bypass→bypass→convergência num único parser
  estrutural): `walkPngChunks` (linhas 156-178, fail-closed em qualquer chunk
  inválido/truncado) é a base de `exceedsPixelBudget` (linhas 275-280, teto
  `IMAGE_PIXEL_BUDGET_PX` = 20M px, linha 272 — checado ANTES do decode, chamado por
  `embedFrameImage` em `pdf-composer.ts:162`) e de `hasAnimatedPngChunk` (linhas 304-308,
  detecção de APNG por TYPE de chunk `acTL`, nunca por substring) —
  mnemonicos-backend/src/modules/visual-associations/image-signature.ts:1-320. **Nota**:
  este teto protege só o pipeline de publicação (F6); a ADMISSÃO do upload em F5
  (`visual-associations.routes.ts`) segue sem teto de dimensão decodificada (RISK-025-001,
  fora de escopo desta fatia).
- [2026-09-14 · PLAN-025] `openMnemonicStrip` (F4, `tira.service.ts`) ganhou o parâmetro
  `options?: { suppressOpeningEvent?: boolean }` (assinatura linhas 247-251) — a supressão
  é decidida na linha 314 (`if (options?.suppressOpeningEvent !== true)`), usada pela
  auto-geração via exportação (FR-024-013) para NÃO emitir o evento de ABERTURA de F3
  quando a Tira nasce de uma exportação, não de interação humana real — a 1ª visita humana
  à tela da Tira confirma a ABERTURA depois, via `mnemonic-strip-board.tsx:236-241`
  (efeito generalizado de `isNotFound` para `isNotFound || hasData`, TASK-025-013) —
  mnemonicos-backend/src/modules/tira/tira.service.ts:247-320.
- [2026-09-14 · PLAN-025] `POST /contents/:id/publication` (`publication.routes.ts:55-69`,
  `requireRole('EDITOR','ADMIN')` + `verifyOrigin` como 1º handler) — montada em
  `mnemonicos-backend/src/http/routes.ts:55` (`apiRoutes.use(publicationRoutes)`), tripwire
  `route-authz-matrix` atualizado (achado da Wave 4: 1ª versão excluía a rota do censo em
  vez de enumerá-la, corrigido antes do merge) — mnemonicos-backend/src/modules/publication/publication.routes.ts:1-70.
- [2026-09-14 · PLAN-025] Frontend: `PublicationVariant` (`types/domain.ts:117`,
  `'TIRA' | 'RESUMO'`, labels linha 119) → mutation `exportPublication`
  (`store/api.ts:504-511`) com `responseHandler` custom (`publicationResponseHandler`,
  linhas 201-210 — 1º consumidor de resposta BINÁRIA da store: `Content-Type
  application/pdf` → `{ blob, filename }`, senão `.json()` do jeito de sempre) e
  `extractContentDispositionFilename` (linhas 187-191) → componente
  `PublicationExportControl` (`components/publication-export-control.tsx:1-125`, 1 botão
  por Variante, 3 estados observáveis, `triggerDownload` via blob nas linhas 115-124) →
  2 enxertos na mesma wave: `content-form.tsx:480` (depois do link da Quebra da regra,
  corrigido por retry de gate 11) e `mnemonic-strip-board.tsx:874` (depois do formulário
  de novo Quadro, condicionado a `frames.length > 0` — Tira vazia não oferece exportação,
  evita PDF de 0 páginas úteis anunciado como sucesso) — mnemonicos-frontend/src/store/api.ts:1-520.
- [2026-08-27 · epico] Nenhum versionamento editorial existe — sem data de fechamento de legislação, sem histórico de revisão, sem fonte normativa estruturada (só `source` como texto livre em `Mnemonic`) — mnemonicos-backend/prisma/schema.prisma:96-120

## Instalabilidade PWA (avulso · PLAN-013)

- [2026-09-07 · PLAN-013] `mnemonicos-frontend` ganhou manifesto (`app/manifest.ts`),
  ícones (`public/icons/icon-{192,512}.png`, placeholder de cor sólida documentado —
  A-013-002) e service worker artesanal (`public/sw.js`) que cacheia **só** o app-shell
  estático (JS/CSS/ícones/manifesto), com same-origin check antes de qualquer decisão
  de cache e kill-switch por autodesregistro (`isKillVersion`, sem endpoint novo) —
  mnemonicos-frontend/public/sw.js:1-196.
- [2026-09-07 · PLAN-013] Lógica de decisão do SW espelhada em
  `src/lib/service-worker-policy.ts` (funções puras testáveis) — a paridade entre a
  cópia servida crua e o espelho TS exige teste que EXECUTA as duas com o mesmo caso
  (`src/lib/sw-parity.test.ts`), nunca só leitura textual — mnemonicos-frontend/src/lib/service-worker-policy.ts:1-90.
- [2026-09-07 · PLAN-013] `public/` nasceu nesta fatia — não existia antes (só
  `src/app/favicon.ico`) — mnemonicos-frontend/public/icons/.
- [2026-09-07 · PLAN-013] Registro do SW em componente `'use client'` mínimo
  (`ServiceWorkerRegistration`, guardado por `'serviceWorker' in navigator`), montado em
  `layout.tsx` — a montagem em composition root de React exige teste de WIRING (importar
  `./layout` sob Jest e confirmar a presença na árvore), não só teste do componente
  isolado — mnemonicos-frontend/src/app/layout.tsx:1-40.
- [2026-09-07 · PLAN-013] `CORS_ORIGINS` do backend (`mnemonicos-backend/.env`) é
  allowlist de origem única (`http://localhost:3000`) — qualquer verificação de tela
  que precise de porta alternativa do frontend (padrão comum quando 2+ sessões disputam
  a porta 3000) trava silenciosamente o login sem erro visível, até essa config aceitar
  lista de origens — mnemonicos-backend/.env.
- [2026-09-07 · PLAN-013] Verificação de tela pendente: instalação nativa
  (`chrome://apps`, prompt do navegador) e ciclo completo login/logout com SW ativo —
  ver `docs/producao-material/handoffs/HANDOFF-PLAN-013.md`.

## Tamanho do código (linha de base do épico)

- [2026-08-27 · epico] 13 arquivos de produção + 3 de teste no backend, 12 + 2 no frontend, uma única página (`/`), nenhuma tela de estudo; `study-slice` existe e não é consumido por ninguém — contagem via ferramentas de busca, sem arquivo único âncora
