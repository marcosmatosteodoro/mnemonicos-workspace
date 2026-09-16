# TASK-027-003: Registro de Contraste — CRUD completo (schema→service→routes→frontend)

**Slug**: producao-material
**Pertence a**: PLAN-027
**Realiza (FRs)**: FR-026-001, FR-026-002, FR-026-003, FR-026-004, FR-026-005, FR-026-006, FR-026-007, FR-026-024, FR-026-029
**Funcionalidade**: FEAT-026-001 (primária), FEAT-026-005, FEAT-026-006
**Componente**: COMP-027-002 (principal), COMP-027-001, COMP-027-003, COMP-027-004, COMP-027-005
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-027-001, TASK-027-002
- **Bloqueia**: TASK-027-004, TASK-027-006

## Contexto

Primeiro CRUD completo de Contraste (confundível + distinção) vinculado a um Conteúdo
bruto titular: EDITOR/ADMIN registra, lista, edita e remove Contrastes, cada mutação
emitindo `MATERIAL_REFORCO` na mesma transação (TASK-027-001 já trouxe o model
`Contrast` e o valor novo do enum; TASK-027-002 já trouxe o diálogo de confirmação
compartilhado). A inclusão do Contraste no PDF exportado é TASK-027-006.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/contrasts/contrasts.schema.ts` (novo):
  `createContrastSchema` (`confusableText`/`distinctionText`, `z.string().trim().min(1)`),
  `updateContrastSchema` (mesmos 2 campos), `contrastIdParamSchema` (`{ id, contrastId }`,
  uuid). Tipos derivados: `CreateContrastInput`, `UpdateContrastInput`.
- `mnemonicos-backend/src/modules/contrasts/contrasts.service.ts` (novo):
  - `createContrast(rawContentId, input, actor, db?)` — dentro de `db.$transaction`: (1)
    `assertRawContentReachable(rawContentId, actor, tx)` PRIMEIRO (importado de
    `contents.service.ts`); (2) `tx.contrast.create({ data: { rawContentId, authorId:
    actor.id, ...input } })` — `authorId` SEMPRE de `actor.id`, nunca de `input` (mesmo
    padrão de `createVisualAssociation`, DEC-023-012); (3)
    `recordProductionStageEvent(tx, { rawContentId, stageType: 'MATERIAL_REFORCO', actorId:
    actor.id, now })`.
  - `listContrasts(rawContentId, actor, db?)` — `assertRawContentReachable` PRIMEIRO, depois
    `db.contrast.findMany({ where: { rawContentId }, orderBy: { createdAt: 'asc' } })` —
    leitura comum a EDITOR/ADMIN dentro do alcance do `RawContent` pai (DEC-027-005): nenhum
    filtro adicional por `authorId` do Contraste.
  - `updateContrast(rawContentId, contrastId, input, actor, db?)` — dentro de
    `db.$transaction`: (1) `assertRawContentReachable` PRIMEIRO; (2) lê o Contraste por
    `{ id: contrastId, rawContentId }` (guarda de pertencimento — `contrastId` que não
    pertence ao `rawContentId` da URL é `NotFoundError`, nunca aceito cru, mesmo raciocínio
    de `updateMnemonicFrameText`/`frameId`); (3) `actor.role === 'ADMIN' || row.authorId ===
    actor.id` — senão `ForbiddenError` (molde de `assertVisualAssociationWritable`, F5); (4)
    `tx.contrast.update({ where: { id: contrastId }, data: input })`; (5)
    `recordProductionStageEvent` (mesmo `stageType`/argumentos acima).
  - `removeContrast(rawContentId, contrastId, actor, db?)` — mesma ordem de guardas de
    `updateContrast` ((1)-(3)); (4) `tx.contrast.delete({ where: { id: contrastId } })` —
    DELETE físico do Contraste (nunca do `RawContent` titular); (5)
    `recordProductionStageEvent`.
  - `ContrastClient = Pick<typeof prisma, 'contrast' | '$transaction'>` (mesmo padrão de
    `RawContentClient`/`VisualAssociationClient`).
- `mnemonicos-backend/src/modules/contrasts/contrasts.routes.ts` (novo): `POST
  /contents/:id/contrasts`, `GET /contents/:id/contrasts`, `PATCH
  /contents/:id/contrasts/:contrastId`, `DELETE /contents/:id/contrasts/:contrastId` —
  `verifyOrigin` como 1º handler nas 3 mutações (`POST`/`PATCH`/`DELETE`);
  `requireRole('<MÉTODO>', '<caminho completo>', 'EDITOR', 'ADMIN')` nas 4, na avaliação da
  montagem (nunca dentro do handler) — mesma topologia de `contents.routes.ts`; `actorOf(req)`
  próprio do módulo (mesmo padrão de `contents.routes.ts:58-61`).
- `mnemonicos-backend/src/http/routes.ts`: `import { contrastsRoutes } from
  '../modules/contrasts/contrasts.routes'` + `apiRoutes.use(contrastsRoutes)` (árvore plana,
  ao lado de `contentsRoutes`/`tiraRoutes`).
- `mnemonicos-frontend/src/components/contrast-form.tsx` (novo): `'use client'`, named
  export `ContrastForm({ rawContentId, contrast? }: ContrastFormProps)` — 2 campos
  (Confundível, distinção), 3 estados observáveis (`isSubmitting`/`submitSuccess`/
  `submitError`, molde de `content-form.tsx`) via `useCreateContrastMutation`/
  `useUpdateContrastMutation`.
- `mnemonicos-frontend/src/components/contrast-list.tsx` (novo): `'use client'`, named
  export `ContrastList({ rawContentId }: ContrastListProps)` —
  `useListContrastsQuery(rawContentId, { refetchOnMountOrArgChange: true })` (mesma
  convenção de `mnemonic-strip-board.tsx`); botão remover por item abre
  `ConfirmRemoveDialog` (TASK-027-002, interface pública `{ open, itemLabel, onConfirm,
  onClose }`) — item só sai da lista após o `DELETE` suceder (nenhum estado otimista).
- `mnemonicos-frontend/src/store/api.ts`: `TAG_TYPES` (linha 138-147) ganha `'Contrast'`;
  `useCreateContrastMutation`/`useListContrastsQuery`/`useUpdateContrastMutation`/
  `useRemoveContrastMutation` — `invalidatesTags: ['Contrast']` nas mutações,
  `providesTags: ['Contrast']` na query.
- `mnemonicos-backend/src/domain/types.ts` + `mnemonicos-frontend/src/types/domain.ts`:
  `export interface Contrast { id: string; rawContentId: string; authorId: string;
  confusableText: string; distinctionText: string; createdAt: Date; updatedAt: Date }`
  (PLAN §5) — idêntica nos dois arquivos.
- `mnemonicos-backend/tests/unit/contents-frontend-contract.test.ts` (estende — molde/
  exemplar de convenção do próprio arquivo, `describe` novo, mesmo padrão de
  `tira-frontend-contract.test.ts`): bloco de paridade `Contrast`, comparando os campos do
  backend (`domain/types.ts`) com os do frontend (`types/domain.ts`).

### Não inclui

- Inclusão de Contraste no PDF exportado (FR-026-026/FR-026-028,
  `buildSupplementaryPagesPdf`/`composePublicationBuffer`) — TASK-027-006.
- `ConfirmRemoveDialog` em si (`confirm-remove-dialog.tsx`) — já entregue por TASK-027-002,
  só consumida aqui pela interface pública congelada.
- Pegadinha elaborada, Flashcard — módulos/extensões próprios (TASK-027-005/004).
- Migração Prisma, model `Contrast`, valor `MATERIAL_REFORCO` do enum — TASK-027-001.

## Critérios de pronto

- [ ] **Guarda composta — prova estrutural** (molde `tira.service.guard-order.test.ts`):
      `mnemonicos-backend/tests/unit/contrasts.service.guard-order.test.ts` (novo) confirma
      por leitura textual que `assertRawContentReachable` é a 1ª chamada dentro do corpo de
      CADA uma das 4 funções (`createContrast`, `listContrasts`, `updateContrast`,
      `removeContrast`), e que `updateContrast`/`removeContrast` avaliam `actor.role ===
      'ADMIN' || row.authorId === actor.id` só DEPOIS de ler a linha e ANTES de qualquer
      `update`/`delete`. Verificação executável: `npm --prefix mnemonicos-backend test --
      contrasts.service.guard-order.test.ts` → `OK (4 tests)`.
- [ ] **Guarda composta — mutação contável, prova comportamental própria por método**
      (decisão 4.139/4.232; lição ativa "[Segurança] Guarda reusada continua exigindo prova
      comportamental própria por novo método de escrita" — os 4 métodos novos tocam a tabela
      `contrasts`, 4 provas, nenhuma herdada): fixture com 2 EDITORES (A e B), cada um com um
      `RawContent` próprio e 1 Contraste; para CADA uma das 4 funções — `createContrast` (B
      tenta criar em `rawContentId` de A), `listContrasts` (B tenta listar do `rawContentId`
      de A), `updateContrast` (B tenta editar o Contraste de A usando o `rawContentId`/
      `contrastId` corretos de A), `removeContrast` (idem, remover) — a chamada com o ator B
      é rejeitada com `NotFoundError('Conteúdo bruto não encontrado.')` (mesma mensagem de
      `assertRawContentReachable`, nunca 403 que distinga "não é seu"), e o estado da vítima
      (Contraste e `RawContent` de A) permanece INTOCADO, confirmado por leitura direta
      subsequente. Um 5º caso, específico de `updateContrast`/`removeContrast`: EDITOR C que
      alcança o MESMO `RawContent` de A mas não é o autor do Contraste (ex.: um 2º Contraste
      no `RawContent` de A criado por outro ator) tenta editar/remover o Contraste de A →
      `ForbiddenError` (403), linha intocada; ADMIN, no mesmo cenário, edita/remove com
      sucesso. Verificação executável: `npm --prefix mnemonicos-backend run test:integration
      -- --testPathPatterns=contrasts.service.integration.test.ts` → `OK (N tests)`.
- [ ] Testes cobrem AC-026-001 (FR-026-001, FR-026-002, FR-026-005): backend —
      `createContrast` com Confundível+distinção preenchidos persiste a linha com
      `authorId = actor.id`; `listContrasts` devolve o Contraste criado, ordenado por
      `createdAt asc`. Frontend — `ContrastForm` montado (`makeStore()` + `fetch` mockado):
      ao submeter, o controle de salvar fica desabilitado durante a chamada (indicador
      visível, resposta represada por interceptação — decisão 4.319) e, em sucesso,
      confirmação visível; `ContrastList` montado confirma nova chamada de
      `useListContrastsQuery` ao remontar (`refetchOnMountOrArgChange`). Verificação
      executável: `npm --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=contrasts.service.integration.test.ts` → `OK (N tests)`; `npx jest
      --runTestsByPath src/components/contrast-form.test.tsx
      src/components/contrast-list.test.tsx` (cwd `mnemonicos-frontend`; arquivos novos —
      molde/exemplar de convenção: `mnemonic-strip-board.test.tsx`, que já roda com o mesmo
      padrão de comando trocando o caminho) → `PASS`.
- [ ] Testes cobrem AC-026-002 (FR-026-003): `ContrastForm` montado, mutação mockada
      rejeitada (erro do sistema) → controle de salvar reabilitado, campos preenchidos
      preservados (nenhum reset), mensagem de falha visível (`role="alert"`). Mesmo comando
      acima (frontend) → `PASS`, cenário nomeado.
- [ ] Testes cobrem AC-026-003 (FR-026-004, FR-026-007) e NFR-026-004 (preservação sem
      exclusão física): `RawContent` titular soft-deleted → `createContrast` recusa com
      `NotFoundError('Conteúdo bruto foi removido.')`, nenhuma linha criada (contagem
      antes/depois); Contraste JÁ EXISTENTE de um `RawContent` soft-deleted →
      `listContrasts`/`updateContrast`/`removeContrast` sobre esse `rawContentId` também
      recusam (mesma guarda), e uma leitura DIRETA (`prisma.contrast.findUnique`, fora do
      service) confirma que a linha do Contraste PERMANECE no banco — preservada para expurgo
      futuro, nunca excluída fisicamente pela remoção do pai. Mesmo comando acima (backend) →
      `OK (N tests)`.
- [ ] Testes cobrem AC-026-004 (FR-026-006): Contraste registrado por um EDITOR, autor (ou
      ADMIN) aciona remover → `removeContrast` exclui a linha (`findUnique` subsequente
      devolve `null`) sem afetar o `RawContent` titular (leitura direta confirma o
      `RawContent` intacto). Mesmo comando acima (backend) → `OK (N tests)`.
- [ ] Testes cobrem AC-026-018 (parte — efeito real de Contraste: item some da lista, chamada
      de rede real): `ContrastList` montado, ação remover confirmada no
      `ConfirmRemoveDialog` → indicador "em andamento" visível durante o `DELETE` (resposta
      represada, interceptação de rede); ao resolver com sucesso, o item some da lista
      renderizada e uma mensagem de confirmação aparece. Verificação executável: `npx jest
      --runTestsByPath src/components/contrast-list.test.tsx` (cwd `mnemonicos-frontend`) →
      `PASS`, cenário nomeado.
- [ ] Testes cobrem AC-026-019 (parte — efeito real: item permanece, reabilitado): mesmo
      fluxo acima com a resposta represada resolvida em falha → o item PERMANECE na lista
      renderizada, a ação de remover é reabilitada, mensagem de falha visível. Mesmo comando
      acima (frontend) → `PASS`, cenário nomeado.
- [ ] Testes cobrem AC-026-015 (parte — rotas de Contraste negam STUDENT) e NFR-026-001:
      sessão STUDENT → `403` nas 4 rotas (`POST`/`GET`/`PATCH`/`DELETE`); sem sessão → `401`
      nas 4. Verificação executável:
      `mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts` continua
      verde com as 4 chaves novas montadas (`collectRoutes`, sem asserção fixa a alterar —
      confirma o crescimento do total de pares); comando: `npm --prefix mnemonicos-backend
      run test:integration -- --testPathPatterns=route-authz-matrix.integration.test.ts` →
      `OK (N tests)`.
- [ ] Testes cobrem AC-026-016 (parte — campo vazio de Contraste recusado) e NFR-026-002:
      `POST`/`PATCH` com `confusableText`/`distinctionText` vazio (3 casos: cada campo vazio
      isoladamente, os dois vazios) → `422` (Zod), motivo informado, nenhuma linha
      criada/alterada (contagem antes/depois). Mesmo comando acima
      (`contrasts.routes.integration.test.ts`, camada HTTP onde o Zod valida) → `OK
      (N tests)`.
- [ ] Testes cobrem AC-026-023 (FR-026-029, NFR-026-005, parte — Contraste):
      `jest.spyOn(productionEventsService, 'recordProductionStageEvent')
      .mockRejectedValueOnce(...)` durante `createContrast`/`updateContrast`/`removeContrast`
      (3 testes) — cada chamada propaga o erro, a transação inteira é revertida (nenhuma
      linha criada/alterada/removida — contagem antes/depois idêntica) e a rota devolve erro
      genérico (500 sem detalhe do driver). Mesmo comando acima (backend) → `OK (N tests)`.
- [ ] **Comparação com o molde canônico** (decisão 4.307; lição ativa "[Código] Lista de
      Interface pública do PLAN é contrato mínimo, não gabarito de transcrição"): antes de
      commitar, `contrasts.schema.ts`/`contrasts.service.ts` são conferidos contra a FORMA
      REAL de `contents.schema.ts`/`contents.service.ts` (nomeação de schema, `ContrastClient`
      análogo a `RawContentClient`) e de `visual-associations.service.ts`
      (`assertVisualAssociationWritable`, guarda de escrita autor-ou-ADMIN) — nunca contra a
      lembrança do nome; divergência de forma sem justificativa própria na TASK é achado do
      code-reviewer.
- [ ] **Integração do diálogo de confirmação** (lição ativa "[Design] Diálogo in-place em
      ramo condicional exige grep de todos os setters do estado que decide o ramo, não só de
      quem o fecha"): `grep -nE "set[A-Z][A-Za-z]*\(" src/components/contrast-list.tsx` (cwd
      `mnemonicos-frontend`) e leitura de CADA ocorrência que afeta o estado que decide se
      `ConfirmRemoveDialog` está aberto — confirma que nenhum caminho (sucesso, falha,
      cancelar, nova ação disparada durante a remoção em andamento) deixa o diálogo aberto
      sobre um item já removido/inexistente nem fecha sem devolver o foco ao gatilho.
- [ ] **Paridade cross-repo `Contrast`**: `contents-frontend-contract.test.ts` (estendido,
      `describe` novo) confirma que os campos de `Contrast` (backend, `domain/types.ts`) e
      `Contrast` (frontend, `types/domain.ts`) são EXATAMENTE `id`/`rawContentId`/`authorId`/
      `confusableText`/`distinctionText`/`createdAt`/`updatedAt`, nos dois lados. Verificação
      executável: `npm --prefix mnemonicos-backend test -- contents-frontend-contract.test.ts`
      → `OK (N tests)`.
- [ ] `TAG_TYPES` (`mnemonicos-frontend/src/store/api.ts`) contém `'Contrast'` — `grep -n
      "'Contrast'" src/store/api.ts` (cwd `mnemonicos-frontend`) → ao menos 2 ocorrências
      (declaração em `TAG_TYPES` + uso em `invalidatesTags`/`providesTags`).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`), produção e teste — `npm --prefix mnemonicos-backend run lint` → exit 0;
      `npx eslint src/components/contrast-form.tsx src/components/contrast-list.tsx
      src/components/contrast-form.test.tsx src/components/contrast-list.test.tsx
      src/store/api.ts` (cwd `mnemonicos-frontend`) → 0 problemas.
- [ ] Aderência à stack/padrões da ficha e do perfil `node-22.md`/`next-16.md` — camadas
      schema→service→routes, toda escrita numa única `$transaction`, Client Component só
      onde há estado/evento, estado de servidor 100% via RTK Query.
- [ ] **Prova do eixo POSITIVO de DEC-027-005** (achado do `qa` pré-código — só o eixo
      negativo, "B não alcança RawContent de A", tinha prova; o eixo positivo que a
      própria DEC declara não tinha nenhuma): `RawContent` de A com 2 Contrastes,
      registrados por A e por um ADMIN — `listContrasts` chamado por A devolve AMBOS, sem
      filtro por `authorId` do Contraste. Falsificável: um filtro acidental por `authorId`
      adicionado a `listContrasts` no futuro (regressão plausível, já que
      `updateContrast`/`removeContrast` FAZEM checar autoria) faz este caso reprovar.
      Mesmo comando de `contrasts.service.integration.test.ts` acima → `OK (N tests)`.
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-027-002 (PLAN §8) — Contraste sem teto de volume nesta fatia; decisão de introduzir
  teto fica com quem fechar RISK-025-007, fora desta TASK.
- TRISK-027-004 (PLAN §8) — a guarda de leitura por autoria herdada de `RawContent`
  (DEC-027-005) diverge da leitura irrestrita de `VisualAssociation` (F5); `listContrasts`
  desta TASK segue DEC-027-005 à risca — não copiar o padrão de `listVisualAssociations`.

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
