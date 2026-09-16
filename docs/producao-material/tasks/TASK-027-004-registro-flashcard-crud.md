# TASK-027-004: Registro de Flashcard — CRUD completo (schema→service→routes→frontend)

**Slug**: producao-material
**Pertence a**: PLAN-027
**Realiza (FRs)**: FR-026-014, FR-026-015, FR-026-016, FR-026-017, FR-026-018, FR-026-019, FR-026-024, FR-026-029
**Funcionalidade**: FEAT-026-003 (primária), FEAT-026-005, FEAT-026-006
**Componente**: COMP-027-011 (principal), COMP-027-010, COMP-027-012, COMP-027-013, COMP-027-014
**Wave**: 3
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-027-001, TASK-027-002, TASK-027-003
- **Bloqueia**: TASK-027-005, TASK-027-006

## Contexto

CRUD completo de Flashcard (pergunta/resposta) vinculado a um Conteúdo bruto, mesma
forma estrutural de Contraste (par de textos, autoria própria, guarda composta) mas
model `ProductionFlashcard` — nome distinto do `Flashcard` legado (SRS/CardState/Review,
dormente desde F2, DEC-027-003) para não colidir identificador Prisma/TS apesar de os
dois usarem o mesmo substantivo de produto. A inclusão do Flashcard no PDF exportado é
TASK-027-006. Sequenciada depois de TASK-027-003 (não em paralelo, apesar de não haver
dependência de comportamento entre Contraste e Flashcard): as duas editam os MESMOS
arquivos compartilhados (`http/routes.ts`, `domain/types.ts`/`types/domain.ts`,
`store/api.ts`, `contents-frontend-contract.test.ts`) — achado mecânico do
`task-validator` (`task-wave-overlap-arquivo`, decisão 4.228/4.326): mesma wave
paralelizável colidiria a escrita.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/flashcards/flashcards.schema.ts` (novo):
  `createFlashcardSchema` (`question`/`answer`, `z.string().trim().min(1)`),
  `updateFlashcardSchema` (mesmos 2 campos), `flashcardIdParamSchema` (`{ id, flashcardId }`,
  uuid). Tipos derivados: `CreateFlashcardInput`, `UpdateFlashcardInput`.
- `mnemonicos-backend/src/modules/flashcards/flashcards.service.ts` (novo) — opera sobre o
  model `ProductionFlashcard` (**nunca** o model `Flashcard` legado, `schema.prisma:222-243`,
  ligado a `Topic`/`Mnemonic`/`CardState`/`Review`, dormente e sem consumidor na fábrica desde
  F2 — DEC-027-003):
  - `createFlashcard(rawContentId, input, actor, db?)` — dentro de `db.$transaction`: (1)
    `assertRawContentReachable(rawContentId, actor, tx)` PRIMEIRO; (2)
    `tx.productionFlashcard.create({ data: { rawContentId, authorId: actor.id, ...input } })`
    — `authorId` SEMPRE de `actor.id`, nunca de `input`; (3)
    `recordProductionStageEvent(tx, { rawContentId, stageType: 'MATERIAL_REFORCO', actorId:
    actor.id, now })`.
  - `listFlashcards(rawContentId, actor, db?)` — `assertRawContentReachable` PRIMEIRO, depois
    `db.productionFlashcard.findMany({ where: { rawContentId }, orderBy: { createdAt: 'asc'
    } })` (FR-026-017/FR-026-020) — leitura comum a EDITOR/ADMIN dentro do alcance do
    `RawContent` pai (DEC-027-005), sem filtro adicional por `authorId` do Flashcard.
  - `updateFlashcard(rawContentId, flashcardId, input, actor, db?)` — dentro de
    `db.$transaction`: (1) `assertRawContentReachable` PRIMEIRO; (2) lê o
    `ProductionFlashcard` por `{ id: flashcardId, rawContentId }` (guarda de pertencimento —
    `flashcardId` que não pertence ao `rawContentId` da URL é `NotFoundError`); (3)
    `actor.role === 'ADMIN' || row.authorId === actor.id` — senão `ForbiddenError` (mesmo
    molde de `contrasts.service.ts`/`assertVisualAssociationWritable`); (4)
    `tx.productionFlashcard.update({ where: { id: flashcardId }, data: input })`; (5)
    `recordProductionStageEvent` (mesmo `stageType`/argumentos acima).
  - `removeFlashcard(rawContentId, flashcardId, actor, db?)` — mesma ordem de guardas de
    `updateFlashcard` ((1)-(3)); (4) `tx.productionFlashcard.delete({ where: { id:
    flashcardId } })` — DELETE físico do Flashcard (nunca do `RawContent` titular); (5)
    `recordProductionStageEvent`.
  - `ProductionFlashcardClient = Pick<typeof prisma, 'productionFlashcard' | '$transaction'>`.
- `mnemonicos-backend/src/modules/flashcards/flashcards.routes.ts` (novo): `POST
  /contents/:id/flashcards`, `GET /contents/:id/flashcards`, `PATCH
  /contents/:id/flashcards/:flashcardId`, `DELETE /contents/:id/flashcards/:flashcardId` —
  `verifyOrigin` como 1º handler nas 3 mutações; `requireRole('<MÉTODO>', '<caminho
  completo>', 'EDITOR', 'ADMIN')` nas 4, na avaliação da montagem — mesma topologia de
  `contents.routes.ts`/`contrasts.routes.ts`.
- `mnemonicos-backend/src/http/routes.ts`: `import { flashcardsRoutes } from
  '../modules/flashcards/flashcards.routes'` + `apiRoutes.use(flashcardsRoutes)` (árvore
  plana).
- `mnemonicos-frontend/src/components/flashcard-form.tsx` (novo): `'use client'`, named
  export `FlashcardForm({ rawContentId, flashcard? }: FlashcardFormProps)` — 2 campos
  (pergunta, resposta), 3 estados observáveis via `useCreateFlashcardMutation`/
  `useUpdateFlashcardMutation`.
- `mnemonicos-frontend/src/components/flashcard-list.tsx` (novo): `'use client'`, named
  export `FlashcardList({ rawContentId }: FlashcardListProps)` —
  `useListFlashcardsQuery(rawContentId, { refetchOnMountOrArgChange: true })`, sempre ordem
  de criação (nenhuma reordenação, A-026-008); botão remover por item abre
  `ConfirmRemoveDialog` (TASK-027-002, interface pública `{ open, itemLabel, onConfirm,
  onClose }`) — item só sai da lista após o `DELETE` suceder.
- `mnemonicos-frontend/src/store/api.ts`: `TAG_TYPES` ganha `'ProductionFlashcard'`;
  `useCreateFlashcardMutation`/`useListFlashcardsQuery`/`useUpdateFlashcardMutation`/
  `useRemoveFlashcardMutation` — `invalidatesTags: ['ProductionFlashcard']` nas mutações,
  `providesTags: ['ProductionFlashcard']` na query.
- `mnemonicos-backend/src/domain/types.ts` + `mnemonicos-frontend/src/types/domain.ts`:
  `export interface ProductionFlashcard { id: string; rawContentId: string; authorId:
  string; question: string; answer: string; createdAt: Date; updatedAt: Date }` (PLAN §5) —
  idêntica nos dois arquivos; nome `ProductionFlashcard` nos dois lados, nunca `Flashcard`
  (colidiria com o tipo do model legado, se algum dia for espelhado).
- `mnemonicos-backend/tests/unit/contents-frontend-contract.test.ts` (estende — molde/
  exemplar de convenção do próprio arquivo, `describe` novo): bloco de paridade
  `ProductionFlashcard`, comparando os campos do backend com os do frontend.

### Não inclui

- Inclusão de Flashcard no PDF exportado (FR-026-020/FR-026-023,
  `buildSupplementaryPagesPdf`/`composePublicationBuffer`) — TASK-027-006.
- `ConfirmRemoveDialog` em si — já entregue por TASK-027-002.
- Contraste, Pegadinha elaborada — módulos/extensões próprios (TASK-027-003/005).
- Qualquer alteração ao model `Flashcard` legado (`schema.prisma:222-243` —
  SRS/CardState/Review) — é um conceito totalmente distinto, apenas com o mesmo nome de
  produto (DEC-027-003); nenhum arquivo relacionado a ele é tocado por esta TASK.
- Reordenação manual de Flashcards na lista (A-026-008) — fora de escopo da SPEC.
- Migração Prisma, model `ProductionFlashcard`, valor `MATERIAL_REFORCO` do enum —
  TASK-027-001.

## Critérios de pronto

- [ ] **Guarda composta — prova estrutural** (molde
      `contrasts.service.guard-order.test.ts`, TASK-027-003):
      `mnemonicos-backend/tests/unit/flashcards.service.guard-order.test.ts` (novo) confirma
      por leitura textual que `assertRawContentReachable` é a 1ª chamada dentro do corpo de
      CADA uma das 4 funções (`createFlashcard`, `listFlashcards`, `updateFlashcard`,
      `removeFlashcard`), e que `updateFlashcard`/`removeFlashcard` avaliam `actor.role ===
      'ADMIN' || row.authorId === actor.id` só DEPOIS de ler a linha e ANTES de qualquer
      `update`/`delete`. Verificação executável: `npm --prefix mnemonicos-backend test --
      flashcards.service.guard-order.test.ts` → `OK (4 tests)`.
- [ ] **Guarda composta — mutação contável, prova comportamental própria por método**
      (decisão 4.139/4.232; lição ativa "[Segurança] Guarda reusada continua exigindo prova
      comportamental própria por novo método de escrita" — os 4 métodos novos tocam a tabela
      `production_flashcards`, 4 provas, nenhuma herdada): fixture com 2 EDITORES (A e B),
      cada um com um `RawContent` próprio e 1 `ProductionFlashcard`; para CADA uma das 4
      funções — `createFlashcard` (B tenta criar em `rawContentId` de A), `listFlashcards`
      (B tenta listar do `rawContentId` de A), `updateFlashcard` (B tenta editar o Flashcard
      de A usando os ids corretos de A), `removeFlashcard` (idem, remover) — a chamada com o
      ator B é rejeitada com `NotFoundError('Conteúdo bruto não encontrado.')`, e o estado da
      vítima (Flashcard e `RawContent` de A) permanece INTOCADO, confirmado por leitura
      direta subsequente. Um 5º caso, específico de `updateFlashcard`/`removeFlashcard`:
      EDITOR C que alcança o MESMO `RawContent` de A mas não é o autor do Flashcard tenta
      editar/remover → `ForbiddenError` (403), linha intocada; ADMIN, no mesmo cenário,
      edita/remove com sucesso. Verificação executável: `npm --prefix mnemonicos-backend run
      test:integration -- --testPathPatterns=flashcards.service.integration.test.ts` → `OK
      (N tests)`.
- [ ] Testes cobrem AC-026-008 (FR-026-014, FR-026-015, FR-026-017): backend —
      `createFlashcard` com pergunta+resposta preenchidas persiste a linha com `authorId =
      actor.id`, sem limite superior declarado (FR-026-014); `listFlashcards` devolve o
      Flashcard criado, ordenado por `createdAt asc`. Frontend — `FlashcardForm` montado
      (`makeStore()` + `fetch` mockado): ao submeter, o controle de salvar fica desabilitado
      durante a chamada (resposta represada) e, em sucesso, confirmação visível e o item
      aparece na lista; `FlashcardList` montado confirma nova chamada de
      `useListFlashcardsQuery` ao remontar (`refetchOnMountOrArgChange`). Verificação
      executável: `npm --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=flashcards.service.integration.test.ts` → `OK (N tests)`; `npx jest
      --runTestsByPath src/components/flashcard-form.test.tsx
      src/components/flashcard-list.test.tsx` (cwd `mnemonicos-frontend`; arquivos novos —
      molde/exemplar de convenção: `mnemonic-strip-board.test.tsx`) → `PASS`.
- [ ] Testes cobrem AC-026-009 (FR-026-016): `FlashcardForm` montado, mutação mockada
      rejeitada → controle de salvar reabilitado, campos preenchidos preservados (nenhum
      reset), mensagem de falha visível (`role="alert"`). Mesmo comando acima (frontend) →
      `PASS`, cenário nomeado.
- [ ] Testes cobrem AC-026-010 (FR-026-018): Flashcard registrado por um EDITOR, autor (ou
      ADMIN) aciona remover → `removeFlashcard` exclui a linha (`findUnique` subsequente
      devolve `null`) sem afetar o `RawContent`. Mesmo comando acima (backend) → `OK
      (N tests)`.
- [ ] Testes cobrem AC-026-011 (FR-026-019) e NFR-026-004 (preservação sem exclusão física):
      `RawContent` soft-deleted → o Flashcard vinculado fica inalcançável via
      `listFlashcards`/`updateFlashcard`/`removeFlashcard` (mesma guarda), mas uma leitura
      DIRETA (`prisma.productionFlashcard.findUnique`, fora do service) confirma que a linha
      PERMANECE no banco — sem exclusão física. Mesmo comando acima (backend) → `OK
      (N tests)`.
- [ ] Testes cobrem AC-026-018 (parte — efeito real de Flashcard: item some da lista,
      chamada de rede real): `FlashcardList` montado, ação remover confirmada no
      `ConfirmRemoveDialog` → indicador "em andamento" visível durante o `DELETE` (resposta
      represada, interceptação de rede); sucesso → o item some da lista renderizada e
      mensagem de confirmação aparece. Verificação executável: `npx jest --runTestsByPath
      src/components/flashcard-list.test.tsx` (cwd `mnemonicos-frontend`) → `PASS`, cenário
      nomeado.
- [ ] Testes cobrem AC-026-019 (parte — efeito real: item permanece, reabilitado): mesmo
      fluxo acima com a resposta represada resolvida em falha → o item PERMANECE na lista,
      ação de remover reabilitada, mensagem de falha visível. Mesmo comando acima (frontend)
      → `PASS`, cenário nomeado.
- [ ] Testes cobrem AC-026-015 (parte — rotas de Flashcard negam STUDENT) e NFR-026-001:
      sessão STUDENT → `403` nas 4 rotas; sem sessão → `401` nas 4. Verificação executável:
      `route-authz-matrix.integration.test.ts` continua verde com as 4 chaves novas montadas
      (`collectRoutes`, sem asserção fixa a alterar); comando: `npm --prefix
      mnemonicos-backend run test:integration --
      --testPathPatterns=route-authz-matrix.integration.test.ts` → `OK (N tests)`.
- [ ] Testes cobrem AC-026-016 (parte — campo vazio de Flashcard recusado) e NFR-026-002:
      `POST`/`PATCH` com `question`/`answer` vazio (3 casos: cada campo isoladamente, os dois
      vazios) → `422` (Zod), motivo informado, nenhuma linha criada/alterada. Mesmo comando
      acima (`flashcards.routes.integration.test.ts`) → `OK (N tests)`.
- [ ] Testes cobrem AC-026-023 (FR-026-029, NFR-026-005, parte — Flashcard):
      `jest.spyOn(productionEventsService, 'recordProductionStageEvent')
      .mockRejectedValueOnce(...)` durante `createFlashcard`/`updateFlashcard`/
      `removeFlashcard` (3 testes) — cada chamada propaga o erro, a transação inteira é
      revertida (nenhuma linha criada/alterada/removida) e a rota devolve erro genérico (500
      sem detalhe do driver). Mesmo comando acima (backend) → `OK (N tests)`.
- [ ] **Comparação com o molde canônico** (decisão 4.307; lição ativa "[Código] Lista de
      Interface pública do PLAN é contrato mínimo, não gabarito de transcrição"): antes de
      commitar, `flashcards.schema.ts`/`flashcards.service.ts` são conferidos contra a FORMA
      REAL de `contrasts.schema.ts`/`contrasts.service.ts` (irmão nascido na MESMA wave,
      forma estrutural idêntica — par de textos, guarda composta, `$transaction`) e de
      `contents.schema.ts` (nomeação Zod) — nunca contra a lembrança do nome; divergência de
      forma sem justificativa própria na TASK é achado do code-reviewer.
- [ ] **Integração do diálogo de confirmação** (lição ativa "[Design] Diálogo in-place em
      ramo condicional exige grep de todos os setters do estado que decide o ramo, não só de
      quem o fecha"): `grep -nE "set[A-Z][A-Za-z]*\(" src/components/flashcard-list.tsx`
      (cwd `mnemonicos-frontend`) e leitura de CADA ocorrência que afeta o estado que decide
      se `ConfirmRemoveDialog` está aberto — confirma que nenhum caminho (sucesso, falha,
      cancelar, nova ação disparada durante a remoção em andamento) deixa o diálogo aberto
      sobre um item já removido/inexistente nem fecha sem devolver o foco ao gatilho.
- [ ] **Paridade cross-repo `ProductionFlashcard`**: `contents-frontend-contract.test.ts`
      (estendido, `describe` novo) confirma que os campos de `ProductionFlashcard` (backend,
      `domain/types.ts`) e `ProductionFlashcard` (frontend, `types/domain.ts`) são EXATAMENTE
      `id`/`rawContentId`/`authorId`/`question`/`answer`/`createdAt`/`updatedAt`, nos dois
      lados — nenhum dos dois nomeado `Flashcard` (mutante: renomear para `Flashcard` em
      qualquer lado faz esta comparação reprovar, DEC-027-003). Verificação executável: `npm
      --prefix mnemonicos-backend test -- contents-frontend-contract.test.ts` → `OK
      (N tests)`.
- [ ] `TAG_TYPES` (`mnemonicos-frontend/src/store/api.ts`) contém `'ProductionFlashcard'` —
      `grep -n "'ProductionFlashcard'" src/store/api.ts` (cwd `mnemonicos-frontend`) → ao
      menos 2 ocorrências.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`), produção e teste — `npm --prefix mnemonicos-backend run lint` → exit 0;
      `npx eslint src/components/flashcard-form.tsx src/components/flashcard-list.tsx
      src/components/flashcard-form.test.tsx src/components/flashcard-list.test.tsx
      src/store/api.ts` (cwd `mnemonicos-frontend`) → 0 problemas.
- [ ] Aderência à stack/padrões da ficha e do perfil `node-22.md`/`next-16.md` — camadas
      schema→service→routes, toda escrita numa única `$transaction`, Client Component só
      onde há estado/evento, estado de servidor 100% via RTK Query.
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-027-002 (PLAN §8) — Flashcard sem teto de volume nesta fatia (FR-026-014 sem limite
  superior); decisão de introduzir teto fica com quem fechar RISK-025-007, fora desta TASK.
- Nome de produto duplicado com o model `Flashcard` legado (DEC-027-003): qualquer import
  acidental de `prisma.flashcard` em vez de `prisma.productionFlashcard` compilaria (o
  legado ainda existe no schema) mas apontaria para a tabela errada — o teste de paridade
  cross-repo e a leitura do molde canônico (`contents.schema.ts`) são a rede contra esse
  engano, não uma checagem de tipo dedicada.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
**Jira**: 

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
<!-- Branch, tentativas, arquivos, revisores e narrativa (retries, escalações) vivem no
ledger da sessão e no commit da closure (4.76) — não se repetem aqui (4.409). -->
