# TASK-012-006: Reindexar posições em duas fases e reordenar Quadros

**Slug**: producao-material
**Pertence a**: PLAN-012
**Realiza (FRs)**: FR-011-006, FR-011-009
**Componente**: COMP-012-004 (principal)
**Wave**: 3
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-<descrição-curta>` (`git.branchNaming: "slug"`) — mesma branch única de todo PLAN-012 (`git.branchStrategy: "unica"`), sem branch própria por TASK.
**Padrão de commit**: Conventional Commits (`commit.convention: "conventional"`) — `feat:`.
**Framework de teste**: Jest 30 + ts-jest — `tests/integration/*.integration.test.ts` (Postgres real, `jest.integration.config.ts`, `--experimental-vm-modules`, mesmo harness de F2/F3) e `tests/unit/*.test.ts` (leitura textual, sem DB).

## Dependências

- **Depende de**: TASK-012-005
- **Bloqueia**: TASK-012-007

## Contexto

A Tira mnemônica precisa garantir que nenhuma falha parcial de reordenação deixe duas
posições de Quadro iguais ou uma faltando (NFR-011-002) — RISK-011-003 (INDEX.md) exige
que essa atomicidade seja **provada**, não só declarada, no gate de revisão. Esta TASK
entrega a primitiva de reindexação em 2 fases (DEC-012-003, defesa em profundidade ao lado
do índice único `@@unique([stripId,position])` de DEC-012-002) e `reorderMnemonicFrames`,
que a consome; TASK-012-007 vai **reusar** a mesma primitiva para adicionar/remover
Quadros, sem recriá-la. A chamada de reorder também é um dos 4 gatilhos que decide
conclusão/retrabalho da etapa "Tira mnemônica" (DEC-012-006 — correção do PO: a geração
emite só abertura, nunca conclusão no mesmo instante).

## Escopo

### Inclui

- `reassignPositions(tx, stripId, orderedFrameIds)` — primitiva **exportada** de
  `tira.service.ts`, 2 fases dentro do MESMO `tx` recebido do chamador (nunca abre
  transação própria, mesmo padrão de `recordProductionStageEvent`):
  - **Fase 1 (offset)**: desloca a posição atual de TODOS os ids de `orderedFrameIds`
    para um intervalo temporário fora de 1..N (ex.: negativo, ou `10000 + índice`) — evita
    colisão do índice único enquanto os valores finais ainda não foram todos escritos.
  - **Fase 2 (final)**: grava, para cada id de `orderedFrameIds` **na ordem dada**,
    `position = índice + 1`.
- `reorderMnemonicFrames(rawContentId, input, actor, db?)` — dentro de `db.$transaction`:
  1. `assertRawContentReachable(rawContentId, actor, tx)` (importado de
     `../contents/contents.service.ts`, export promovido por TASK-012-005/COMP-012-005) —
     **1ª chamada**, antes de qualquer leitura/escrita de `mnemonic_frames`.
  2. Localiza `stripId` a partir do `rawContentId` (via `ruleBreakdown.rawContentId` →
     `mnemonicStrip.ruleBreakdownId`).
  3. Valida que `input.order` é **exatamente** o conjunto de ids de Quadros existentes da
     Tira (nem falta, nem sobra) — 400/409 caso contrário (`AppError`/`ConflictError`,
     conforme o padrão de erro já usado por `tira.schema.ts`/COMP-012-003).
  4. Chama `reassignPositions(tx, stripId, input.order)`.
  5. Chama `recordProductionStageEvent(tx, { rawContentId, stageType: 'TIRA_MNEMONICA',
     actorId: actor.id, now })` — decide CONCLUSAO (1ª mutação humana) ou RETRABALHO
     (demais), puramente pelo histórico já registrado (DEC-012-006), sem este código saber
     qual é qual.
  6. Devolve `MnemonicStripDetail` (frames ordenados por `position asc`).

### Não inclui

- `addMnemonicFrame`/`updateMnemonicFrameText`/`removeMnemonicFrame` — TASK-012-007, que
  **importa/reusa** `reassignPositions` definida aqui; não recriar a primitiva.
- Qualquer rota HTTP (`tira.routes.ts` é COMP-012-006/TASK-012-008, fora desta TASK).
- A faceta de UI dos 3 estados observáveis (em andamento/sucesso/falha) e os controles de
  reordenação — frontend, TASK-012-012.
- `buildInitialFrames`/`openMnemonicStrip`/guarda de alcance comportamental completa
  (EDITOR não alcança Tira de outro EDITOR; soft-delete do `RawContent` de origem torna a
  cadeia inalcançável) — já entregues e provados por TASK-012-005; esta TASK só confirma
  estruturalmente que `reorderMnemonicFrames` reusa a mesma guarda, sem reprovar o
  comportamento.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios
prevalecem; nunca siga um passo que enfraqueça um critério.

1. Em `tira.service.ts` (criado por TASK-012-005), acrescente `reassignPositions` como
   função exportada, recebendo o `tx` já aberto pelo chamador — nunca `prisma` direto.
2. Implemente `reorderMnemonicFrames` seguindo a ordem de passos do Escopo > Inclui acima.
3. Garanta que a Fase 1 desloque **todos** os ids de `orderedFrameIds`, mesmo os que já
   estão na posição final correta — não pule nenhum por "otimização": pular um id cuja
   posição de destino coincide com a de outro Quadro ainda não deslocado é exatamente o
   cenário que colide com `@@unique([stripId,position])` a meio caminho (DEC-012-003).

## Critérios de pronto

- [ ] Reindexação correta em qualquer permutação, **inclusive troca genuína de posição
      entre 2 Quadros** (não apenas deslocamento sequencial) — cobre AC-011-010. Fixture:
      Tira com 5 Quadros em posições 1..5; reordenar invertendo a sequência completa
      (nova ordem 5,4,3,2,1) — cenário em que a posição nova de um Quadro é a posição
      ANTIGA de outro, o par que um "shift direto" sem 2 fases colidiria contra
      `@@unique([stripId,position])` (lição "[Testes] Árvore de decisão com precedência:
      um caso por PAR de ramos que coincide" — aqui aplicada à precedência Fase 1 → Fase
      2: sem ela, o par de posições que troca de lugar é exatamente o caso que expõe a
      falta de offset). Verificação executável: `npm --prefix mnemonicos-backend run
      test:integration -- --testPathPattern=tira.service.integration.test.ts` → `OK (N
      tests)`, incluindo o teste "reorder inverte a sequência completa: posições finais
      1..5 sem lacuna nem duplicidade, inclusive com swap genuíno".
- [ ] Testes cobrem AC-011-011 (atomicidade REAL, RISK-011-003): teste de integração
      injeta, DENTRO da mesma transação real usada por `reassignPositions`, uma falha
      depois que a Fase 1 (offset) já escreveu no banco e antes que a Fase 2 (posições
      finais) complete — ex.: `jest.spyOn` sobre a chamada Prisma que a Fase 2 usa,
      rejeitando numa invocação intermediária (nem a 1ª nem a última do laço da Fase 2,
      para garantir que parte da Fase 2 já rodou quando a falha ocorre). O teste
      **prova que o spy de fato interceptou a chamada real** (`expect(spy).toHaveBeenCalled()`
      ou contagem ≥ 1) — sem essa asserção, um spy que não intercepte o cliente
      transacional deixaria o teste passar vazio, sem provar nada (nunca simulação fora
      da transação). Lendo com `testPrisma` (sem spy) DEPOIS da falha, confirma que as
      posições de TODOS os Quadros da Tira permanecem IDÊNTICAS às de antes da chamada —
      nem posição temporária da Fase 1 nem posição final parcial da Fase 2 sobrevive.
      Comando: mesmo arquivo/comando acima → `OK (N tests)`, incluindo "falha real entre
      Fase 1 e Fase 2 não deixa nenhuma posição parcial persistida (AC-011-011)".
- [ ] Testes cobrem AC-011-014 (parte — via reorder): Tira recém-gerada, sem mutação
      humana ainda → 1ª chamada de `reorderMnemonicFrames` bem-sucedida registra evento
      CONCLUSAO; 2ª chamada de reorder bem-sucedida (sobre o mesmo `rawContentId`)
      registra RETRABALHO, nunca uma 2ª CONCLUSAO — reusa `recordProductionStageEvent`/
      `decideStageTransition` sem alteração, prova por leitura de `productionStageEvent`
      real via `testPrisma`. Comando acima → `OK (N tests)`.
- [ ] Testes cobrem AC-011-015 (parte — fail-secure do reorder): `jest.spyOn
      (productionEventsService, 'recordProductionStageEvent').mockRejectedValueOnce(...)`
      (mesma técnica de `contents.service.integration.test.ts`, "Fail-secure" describe)
      durante um `reorderMnemonicFrames` — a chamada propaga o erro e as posições dos
      Quadros permanecem EXATAMENTE as de antes da tentativa, nenhuma posição nova
      persiste (nem sequer as temporárias da Fase 1). Comando acima → `OK (N tests)`.
- [ ] Contrato do item (sem AC numerado dedicado — FR-011-006 exige sequência sem falta
      nem sobra): `reorderMnemonicFrames` REJEITA (400/409) quando `input.order` não é
      exatamente o conjunto de ids de Quadros existentes da Tira — teste de **mutação
      contável** (decisão 4.139/4.232): 2 Tiras distintas A e B (`RawContent`s
      diferentes, cada uma com Quadros); chamar `reorderMnemonicFrames` no `rawContentId`
      de A com um `order` que inclui 1 id de Quadro de B → rejeitado, e as posições de A
      **e** de B permanecem intocadas (nenhum vazamento de escrita cross-tenant). 1
      método nesta TASK toca esse predicado (`reorderMnemonicFrames`) → 1 prova. Caso de
      borda adicional (achado do `qa`, Etapa 3.5): `order` com 1 id **duplicado** e outro
      id existente **ausente** (mesmo tamanho do conjunto real, conjunto errado) →
      rejeitado (400/409), posições intocadas — cenário distinto do "id de outra Tira"
      acima (aqui todos os ids pertencem à Tira certa, só a multiplicidade está errada).
- [ ] Testes cobrem AC-011-020, AC-011-022 (parte — estrutural): `assertRawContentReachable`
      é a 1ª chamada dentro do corpo de `reorderMnemonicFrames` — teste de leitura
      textual (mesmo mecanismo de `extractInterfaceFields` de
      `contents-frontend-contract.test.ts`, sem AST): extrai o corpo da função por regex
      ancorada em `export async function reorderMnemonicFrames`, remove linhas de
      comentário (`//`, `*`) e assere que a 1ª linha executável contém
      `assertRawContentReachable(` — nunca grep solto no arquivo inteiro (casaria
      docblock). Arquivo `mnemonicos-backend/tests/unit/tira.service.guard-order.test.ts`
      (estende o arquivo homônimo já criado por TASK-012-005, se existir sob esse nome —
      mesma convenção de nome; ver `premissas_marcadas`). Comando: `npm --prefix
      mnemonicos-backend test -- tira.service.guard-order.test.ts` → `OK (N tests)`. A
      prova COMPORTAMENTAL completa de alcance (EDITOR não alcança Tira de outro EDITOR;
      soft-delete torna inalcançável) já foi feita em TASK-012-005 — não duplicar aqui.
- [ ] Testes cobrem NFR-011-002 e a lição "[Performance] `include`/`select` aninhado de
      relação não é 1 statement por padrão": `reorderMnemonicFrames` devolve
      `MnemonicStripDetail` com round-trips fixados em teste via `withQueryProbe` (mesmo
      helper de `contents.service.integration.test.ts`) — nº de queries **estável**, não
      cresce com o nº de Quadros (semear 3 e depois 5 Quadros na Tira, mesma contagem de
      eventos `query`). Comando acima → `OK (N tests)`.
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git diff --name-only
      main...HEAD`, produção e teste) — `npm --prefix mnemonicos-backend run lint` →
      exit 0.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil `node-22.md`.
- [ ] Code review aprovado.

## Riscos específicos

- RISK-011-003 (INDEX.md) — mitigado pela prova de atomicidade real desta TASK
  (AC-011-011); o gate de revisão de código confirma o mutante, não só a declaração.
- TRISK-012-002 (INDEX.md) — custo de até 2×N `UPDATE`s por reindexação aceito nesta
  fatia; medição real de round-trips fica para o gate 10 do fecho do PLAN, não bloqueia
  esta TASK.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Branch**:
**Commit SHA**:
**Jira**: KAN-56
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
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a>

**Notas**:
