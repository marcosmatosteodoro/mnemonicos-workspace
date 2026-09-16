# TASK-027-005: Pegadinha elaborada — campo único (extensão de contents.*)

**Slug**: producao-material
**Pertence a**: PLAN-027
**Realiza (FRs)**: FR-026-008, FR-026-009, FR-026-010, FR-026-011, FR-026-012, FR-026-013, FR-026-024, FR-026-029
**Funcionalidade**: FEAT-026-002 (primária), FEAT-026-005, FEAT-026-006
**Componente**: COMP-027-007 (principal), COMP-027-006, COMP-027-008, COMP-027-009
**Wave**: 4
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-027-001, TASK-027-002, TASK-027-004
- **Bloqueia**: TASK-027-006

## Contexto

Pegadinha elaborada não ganha tabela própria (DEC-027-002): é a coluna nullable
`pegadinhaText` já trazida em `RawContent` por TASK-027-001, escrita pela MESMA guarda
de autoria de `updateRawContent` — "autor" aqui é sempre `RawContent.authorId`, sem
autoria própria da Pegadinha. Esta TASK estende `contents.schema.ts`/`.service.ts`/
`.routes.ts` (arquivos existentes de F2) em vez de criar um módulo novo. A inclusão da
Pegadinha no PDF exportado é TASK-027-006. Sequenciada depois de TASK-027-004 (que já
depende de TASK-027-003): as 3 TASKs de registro compartilham a escrita em
`domain/types.ts`/`types/domain.ts`, `store/api.ts` e `contents-frontend-contract.test.ts`
— achado mecânico do `task-validator` (`task-wave-overlap-arquivo`, decisão
4.228/4.326), mesma razão de TASK-027-004 depender de TASK-027-003.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/contents/contents.schema.ts` (estende):
  `updatePegadinhaSchema` (`text: z.string().trim().min(1)`, campo obrigatório — o `DELETE`
  não usa body). Tipo derivado: `UpdatePegadinhaInput`.
- `mnemonicos-backend/src/modules/contents/contents.service.ts` (estende):
  - `savePegadinhaText(rawContentId, input, actor, db?)` — dentro de `db.$transaction`:
    `tx.rawContent.updateMany({ where: { id: rawContentId, ...ACTIVE_RAW_CONTENT_WHERE,
    ...scopeWhere(actor) }, data: { pegadinhaText: input.text } })` — guarda e escrita no
    MESMO statement (mesmo padrão de `updateRawContent:195-207`, nunca um `findFirst` de
    guarda seguido de `update` por id isolado); `result.count === 0` →
    `NotFoundError('Conteúdo bruto não encontrado.')`; depois,
    `recordProductionStageEvent(tx, { rawContentId, stageType: 'MATERIAL_REFORCO', actorId:
    actor.id, now })`.
  - `removePegadinhaText(rawContentId, actor, db?)` — mesma estrutura: `updateMany` com o
    MESMO `where` acima, `data: { pegadinhaText: null }`; `count === 0` →
    `NotFoundError('Conteúdo bruto não encontrado.')`; `recordProductionStageEvent` na
    mesma tx.
  - `RAW_CONTENT_DETAIL_SELECT` (linha 49-62) ganha `pegadinhaText: true`; `RawContentDetail`
    (interface, linha 64-77) ganha `pegadinhaText: string | null`.
- `mnemonicos-backend/src/modules/contents/contents.routes.ts` (estende): `PATCH
  /contents/:id/pegadinha` (salvar/editar, body validado por `updatePegadinhaSchema`),
  `DELETE /contents/:id/pegadinha` (apagar, sem body) — `verifyOrigin` como 1º handler nas
  2, `requireRole('<MÉTODO>', '<caminho completo>', 'EDITOR', 'ADMIN')` nas 2, mesma
  topologia das demais rotas do arquivo. Leitura já embutida em `GET /contents/:id`
  (`getRawContent`, sem rota própria) — nenhuma rota nova de leitura.
- `mnemonicos-frontend/src/components/pegadinha-field.tsx` (novo): `'use client'`, named
  export `PegadinhaField({ rawContentId, pegadinhaText }: PegadinhaFieldProps)` — campo
  único de texto (sem lista), 3 estados observáveis (salvar) via
  `useSavePegadinhaMutation`; ação "apagar" abre `ConfirmRemoveDialog` (TASK-027-002,
  interface pública `{ open, itemLabel, onConfirm, onClose }`) antes de
  `useRemovePegadinhaMutation` — texto só sai da UI após o `DELETE` suceder.
- `mnemonicos-frontend/src/store/api.ts`: `useSavePegadinhaMutation`/
  `useRemovePegadinhaMutation` — `invalidatesTags: ['RawContent']` (tag JÁ EXISTENTE, o
  campo é dela — nenhuma tag nova, ao contrário de Contraste/Flashcard).
- `mnemonicos-backend/src/domain/types.ts` + `mnemonicos-frontend/src/types/domain.ts`:
  `RawContentDetail`/`RawContent` ganham `pegadinhaText: string | null`.
- `mnemonicos-backend/tests/unit/contents-frontend-contract.test.ts` (estende): o `describe`
  já existente "paridade cross-repo — RawContentSummary/RuleBreakdown/RawContent" tem sua
  lista hard-coded de campos de `RawContentDetail`/`RawContent` (linha ~104-107) ATUALIZADA
  para incluir `pegadinhaText` nos dois lados — sem essa atualização, o teste já existente
  fica vermelho com o campo novo (é o próprio molde citado no cabeçalho do arquivo se
  autoconfirmando errado).

### Não inclui

- Inclusão da Pegadinha no PDF exportado (FR-026-027,
  `buildSupplementaryPagesPdf`/`composePublicationBuffer`) — TASK-027-006.
- `ConfirmRemoveDialog` em si — já entregue por TASK-027-002.
- Contraste, Flashcard — módulos próprios (TASK-027-003/004).
- Qualquer mudança na Classe do radar de prova (`radarClass`) — a Pegadinha é independente
  dela (A-026-005), nenhum campo de `contents.schema.ts` além de `updatePegadinhaSchema` é
  tocado.
- Migração Prisma (coluna `pegadinhaText`, valor `MATERIAL_REFORCO` do enum) — TASK-027-001.

## Critérios de pronto

- [ ] **Guarda e escrita no mesmo statement — prova estrutural** (lição ativa "[Código] ao
      ESTENDER `contents.schema.ts`/`.service.ts`, comparar a forma da extensão contra o
      padrão já presente no PRÓPRIO arquivo"): `grep -n "updateMany" mnemonicos-backend/src/
      modules/contents/contents.service.ts` confirma que `savePegadinhaText`/
      `removePegadinhaText` usam `tx.rawContent.updateMany` com `where` contendo
      `ACTIVE_RAW_CONTENT_WHERE`/`scopeWhere(actor)` — EXATAMENTE o mesmo padrão de
      `updateRawContent` (linha 195-207) e `softDeleteRawContent` (linha 240-243) do mesmo
      arquivo — nunca um `findFirst` de guarda seguido de `update`/`delete` por id isolado.
- [ ] **Guarda — mutação contável, prova comportamental própria por método** (decisão
      4.139/4.232; lição ativa "[Segurança] `savePegadinhaText`/`removePegadinhaText` são 2
      métodos novos de escrita, mesmo reusando o padrão `updateMany` de `updateRawContent` —
      cada um exige prova comportamental própria"): fixture com 2 EDITORES (A e B), A com um
      `RawContent` próprio; para CADA uma das 2 funções — `savePegadinhaText` (B tenta
      salvar Pegadinha no `rawContentId` de A), `removePegadinhaText` (B tenta apagar a
      Pegadinha de A) — a chamada com o ator B devolve `count === 0` →
      `NotFoundError('Conteúdo bruto não encontrado.')`, e o `pegadinhaText` de A permanece
      INTOCADO (leitura direta subsequente confirma o valor anterior, nunca alterado nem
      apagado). ADMIN, no mesmo cenário, salva/apaga com sucesso. Verificação executável:
      `npm --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=contents.service.integration.test.ts` → `OK (N tests)`.
- [ ] Testes cobrem AC-026-005 (FR-026-008, FR-026-009, FR-026-011): backend —
      `savePegadinhaText` persiste o texto independente da `radarClass` atual do
      `RawContent` (2 casos: `RawContent` com `radarClass` diferente de `PEGADINHA` também
      aceita); `getRawContent` devolve `pegadinhaText` atualizado ao reler. Frontend —
      `PegadinhaField` montado (`makeStore()` + `fetch` mockado): ao submeter, o controle de
      salvar fica desabilitado durante a chamada (resposta represada) e, em sucesso,
      confirmação visível com o texto exibido. Verificação executável: `npm --prefix
      mnemonicos-backend run test:integration --
      --testPathPatterns=contents.service.integration.test.ts` → `OK (N tests)`; `npx jest
      --runTestsByPath src/components/pegadinha-field.test.tsx` (cwd `mnemonicos-frontend`;
      arquivo novo — molde/exemplar de convenção: `mnemonic-strip-board.test.tsx`) → `PASS`.
- [ ] Testes cobrem AC-026-006 (FR-026-010): `PegadinhaField` montado, mutação mockada
      rejeitada → controle de salvar reabilitado, texto digitado preservado (nenhum reset),
      mensagem de falha visível (`role="alert"`). Mesmo comando acima (frontend) → `PASS`,
      cenário nomeado.
- [ ] Testes cobrem AC-026-007 (FR-026-012, FR-026-013) e NFR-026-004 (preservação sem
      exclusão física): `RawContent` soft-deleted com Pegadinha registrada → `GET
      /contents/:id` (que embute a leitura) recusa (mesma guarda de `getRawContent`), e uma
      leitura DIRETA (`prisma.rawContent.findUnique`, fora do service) confirma que
      `pegadinhaText` PERMANECE com o valor gravado — sem exclusão física do texto. Mesmo
      comando acima (backend) → `OK (N tests)`.
- [ ] Testes cobrem AC-026-018 (parte — efeito real de Pegadinha: campo volta ao estado
      vazio, chamada de rede real): `PegadinhaField` montado com `pegadinhaText` preenchido,
      ação apagar confirmada no `ConfirmRemoveDialog` → indicador "em andamento" visível
      durante o `DELETE` (resposta represada, interceptação de rede); sucesso → o campo
      passa a exibir o estado "sem Pegadinha registrada" e mensagem de confirmação aparece.
      Verificação executável: `npx jest --runTestsByPath
      src/components/pegadinha-field.test.tsx` (cwd `mnemonicos-frontend`) → `PASS`, cenário
      nomeado.
- [ ] Testes cobrem AC-026-019 (parte — efeito real: texto permanece, reabilitado): mesmo
      fluxo acima com a resposta represada resolvida em falha → o texto PERMANECE exibido, a
      ação de apagar é reabilitada, mensagem de falha visível. Mesmo comando acima (frontend)
      → `PASS`, cenário nomeado.
- [ ] Testes cobrem AC-026-015 (parte — rotas de Pegadinha negam STUDENT) e NFR-026-001:
      sessão STUDENT → `403` nas 2 rotas (`PATCH`/`DELETE`); sem sessão → `401` nas 2.
      Verificação executável: `route-authz-matrix.integration.test.ts` continua verde com as
      2 chaves novas montadas (`collectRoutes`, sem asserção fixa a alterar); comando: `npm
      --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=route-authz-matrix.integration.test.ts` → `OK (N tests)`.
- [ ] Testes cobrem AC-026-016 (parte — campo vazio de Pegadinha recusado) e NFR-026-002:
      `PATCH /contents/:id/pegadinha` com `text` vazio → `422` (Zod), motivo informado,
      `pegadinhaText` do `RawContent` INTOCADO (contagem/valor antes e depois idênticos).
      Mesmo comando acima (`contents.routes.integration.test.ts`) → `OK (N tests)`.
- [ ] Testes cobrem AC-026-023 (FR-026-029, NFR-026-005, parte — Pegadinha):
      `jest.spyOn(productionEventsService, 'recordProductionStageEvent')
      .mockRejectedValueOnce(...)` durante `savePegadinhaText`/`removePegadinhaText` (2
      testes) — cada chamada propaga o erro, a transação inteira é revertida
      (`pegadinhaText` permanece com o valor anterior à tentativa) e a rota devolve erro
      genérico (500 sem detalhe do driver). Mesmo comando acima (backend) → `OK (N tests)`.
- [ ] **Integração do diálogo de confirmação** (lição ativa "[Design] Diálogo in-place em
      ramo condicional exige grep de todos os setters do estado que decide o ramo — aqui o
      ramo é 'pegadinha registrada vs. vazia', não uma lista"): `grep -nE
      "set[A-Z][A-Za-z]*\(" src/components/pegadinha-field.tsx` (cwd `mnemonicos-frontend`)
      e leitura de CADA ocorrência que afeta (a) qual dos 2 estados do campo (registrada/
      vazia) é exibido e (b) se `ConfirmRemoveDialog` está aberto — confirma que nenhum
      caminho (sucesso ao salvar, sucesso ao apagar, falha em qualquer uma, cancelar) deixa
      o componente exibindo o texto antigo depois de apagar com sucesso, nem o diálogo aberto
      sobre um estado que já mudou, nem fecha sem devolver o foco ao gatilho.
- [ ] **Paridade cross-repo `RawContentDetail`/`RawContent` com `pegadinhaText`**:
      `contents-frontend-contract.test.ts` (o `it` existente "RawContentDetail/RawContent:
      mesmo conjunto de campos", ATUALIZADO com `pegadinhaText` na lista esperada) confirma
      que os campos de `RawContentDetail` (backend) e `RawContent` (frontend) são idênticos
      nos dois lados, incluindo o campo novo. Verificação executável: `npm --prefix
      mnemonicos-backend test -- contents-frontend-contract.test.ts` → `OK (N tests)` (o
      teste já existente falharia sem esta atualização — mutante inverso: reverter só este
      `it` sem adicionar `pegadinhaText` à extração faz o teste ficar verde por engano;
      confirmar que o campo aparece na lista de asserção literal, não só no arquivo fonte).
- [ ] `RAW_CONTENT_DETAIL_SELECT` contém `pegadinhaText: true` — `grep -n "pegadinhaText"
      mnemonicos-backend/src/modules/contents/contents.service.ts` (cwd
      `mnemonicos-backend`) → ao menos 3 ocorrências (`select`, interface, uma das 2 funções
      novas).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`), produção e teste — `npm --prefix mnemonicos-backend run lint` → exit 0;
      `npx eslint src/components/pegadinha-field.tsx
      src/components/pegadinha-field.test.tsx src/store/api.ts` (cwd `mnemonicos-frontend`)
      → 0 problemas.
- [ ] Aderência à stack/padrões da ficha e do perfil `node-22.md`/`next-16.md` — extensão de
      arquivo existente segue a convenção já presente nele (schema→service→routes), toda
      escrita numa única `$transaction`, Client Component só onde há estado/evento.
- [ ] **`savePegadinhaText` contra `RawContent` já soft-deleted** (achado do `qa`
      pré-código — AC-026-007 só testava o caminho de LEITURA após a remoção, nunca a
      ESCRITA tentada sobre um `RawContent` já removido): `RawContent` soft-deleted antes
      da tentativa → `savePegadinhaText` recusa com `NotFoundError` (`count === 0` no
      `updateMany`), `pegadinhaText` permanece com o valor anterior (leitura direta
      confirma). Mesmo comando de `contents.service.integration.test.ts` acima → `OK (N
      tests)`.
- [ ] Code review aprovado.

## Riscos específicos

- RISK-026-004 (SPEC §9, herdado) — concorrência de 2 EDITORES editando a Pegadinha do
  MESMO Conteúdo bruto ao mesmo tempo resolve por last-write-wins; aceito nesta fatia, sem
  mudança nesta TASK.
- TRISK-027-003 (PLAN §8) — `pegadinhaText` embutido em `RawContent` significa que qualquer
  `SELECT` genérico da tabela que não use `RAW_CONTENT_DETAIL_SELECT` explícito passaria a
  carregar 1 coluna a mais; mitigado porque a prática do módulo já é `select` explícito em
  toda leitura (nenhum ponto novo a corrigir além do já listado no Inclui).

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
