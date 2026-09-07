# TASK-012-007: CRUD de Quadro — adicionar, editar e remover

**Slug**: producao-material
**Pertence a**: PLAN-012
**Realiza (FRs)**: FR-011-003, FR-011-004, FR-011-005, FR-011-007, FR-011-009
**Componente**: COMP-012-004 (principal)
**Wave**: 4
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-<descrição-curta>` (`git.branchNaming: "slug"`) — mesma branch única de todo PLAN-012.
**Padrão de commit**: Conventional Commits (`commit.convention: "conventional"`) — `feat:`.
**Framework de teste**: Jest 30 + ts-jest — `tests/integration/*.integration.test.ts` (Postgres real, `jest.integration.config.ts`, `--experimental-vm-modules`).

## Dependências

- **Depende de**: TASK-012-006
- **Bloqueia**: TASK-012-008

## Contexto

Completa o CRUD da Tira mnemônica: adicionar, editar texto e remover Quadro (FR-011-003/
004/005), reusando a primitiva de reindexação atômica `reassignPositions` entregue por
TASK-012-006 — sem reimplementar reindexação aqui. Cada mutação é mais um dos 4 gatilhos
que decide conclusão/retrabalho da etapa (DEC-012-006) e é mais uma superfície onde a
defesa contra substituição de id (A01 — `frameId` que não pertence ao `stripId` da rota)
precisa valer, mesma cautela já aplicada em `contents.service.ts` para `RawContent`/
`RuleBreakdown`. Remover o último Quadro restante deixa a Tira vazia sem regeneração
automática (AC-011-024, FR-011-002 preservado).

## Escopo

### Inclui

- `addMnemonicFrame(rawContentId, input, actor, db?)` — dentro de `db.$transaction`: (1)
  `assertRawContentReachable` como 1ª chamada; (2) localiza `stripId`; (3) lê os ids de
  Quadros existentes ordenados por `position asc`; (4) cria o novo Quadro com posição
  temporária fora de 1..N; (5) monta a lista completa de ids na ordem final desejada
  (existentes + o novo, no índice de `input.position`) e chama `reassignPositions(tx,
  stripId, <lista>)` (reusa a primitiva de TASK-012-006, chamada direta no mesmo arquivo —
  nunca recriada); (6) chama `recordProductionStageEvent`; devolve `MnemonicStripDetail`.
- `updateMnemonicFrameText(rawContentId, frameId, input, actor, db?)` — dentro de
  `db.$transaction`: (1) `assertRawContentReachable` como 1ª chamada; (2) localiza
  `stripId`; (3) guarda de pertencimento **e** escrita no MESMO `updateMany` (mesmo padrão
  de `updateRawContent`/`softDeleteRawContent` em `contents.service.ts:186-246` — nunca um
  `findFirst` de guarda seguido de `update` por id isolado, que abriria uma janela de
  corrida): `tx.mnemonicFrame.updateMany({ where: { id: frameId, stripId }, data: { text:
  input.text } })`; `count === 0` → `NotFoundError('Quadro não encontrado.')` (mesma
  mensagem única para "id inexistente" e "frameId de outra Tira" — nunca distinguir os
  dois, mesma razão de `assertRawContentReachable`); posição intocada; (4) chama
  `recordProductionStageEvent`; devolve `MnemonicStripDetail`.
- `removeMnemonicFrame(rawContentId, frameId, actor, db?)` — dentro de `db.$transaction`:
  (1) `assertRawContentReachable` como 1ª chamada; (2) localiza `stripId`; (3) guarda de
  pertencimento **e** exclusão no MESMO `deleteMany` (mesmo raciocínio acima):
  `tx.mnemonicFrame.deleteMany({ where: { id: frameId, stripId } })`; `count === 0` →
  `NotFoundError('Quadro não encontrado.')`; (4) lê os Quadros restantes ordenados por
  `position` atual e chama `reassignPositions(tx, stripId, <ids restantes>)` — com lista
  vazia (removeu o último Quadro), é no-op (AC-011-024); (5) chama
  `recordProductionStageEvent`; devolve `MnemonicStripDetail`.

### Não inclui

- `reassignPositions`/`reorderMnemonicFrames` (já entregues em TASK-012-006 — importar/
  reusar por chamada direta no mesmo arquivo, nunca recriar).
- Qualquer rota HTTP (`tira.routes.ts` é COMP-012-006/TASK-012-008).
- A faceta de UI dos 3 estados observáveis e o estado de "Tira vazia" — frontend,
  TASK-012-012.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios
prevalecem; nunca siga um passo que enfraqueça um critério.

1. Reaproveite o `MnemonicStripClient` e o helper de leitura de `stripId`/frames já
   criados por TASK-012-005/006 — não redeclare.
2. Escreva as 3 funções seguindo exatamente a ordem de passos do Escopo > Inclui.
3. Para `addMnemonicFrame`, cuidado com o índice de inserção: `input.position` é 1-based;
   o novo id entra no array de ids na posição `input.position - 1` (clamped a
   `[0, length]`).

## Critérios de pronto

- [ ] **Confused deputy no `:frameId` (achado do security-engineer, gate 8 da Wave 1 —
      pendência herdada, decisão 4.140)**: `updateMnemonicFrameText`/`removeMnemonicFrame`
      recebem `rawContentId` (do `:id` da rota) **e** `frameId` (do `:frameId`) — o
      `rawContentId` a autorizar (`assertRawContentReachable`) é sempre o resolvido a
      partir da CADEIA do próprio Frame (Frame → Strip → RuleBreakdown → RawContent),
      nunca aceito cru do parâmetro da URL sem essa amarração. Teste: EDITOR dono de
      `rawContentId` A tenta mutar um `frameId` que pertence à Tira de `rawContentId` B
      (do mesmo EDITOR ou de outro) usando a URL `/contents/A/strip/frames/<frameId-de-B>`
      → rejeitado (404, mesma mensagem de "não encontrado" — nunca sucesso nem 403
      distinguível). Comando: mesmo arquivo de integração acima, caso
      "rejeita frameId que não pertence à cadeia do rawContentId da URL".
- [ ] Testes cobrem AC-011-004, AC-011-005 (add): novo Quadro aparece na posição
      informada, deslocando os Quadros seguintes sem lacuna nem duplicidade (reusa
      `reassignPositions` de TASK-012-006 — a prova de atomicidade da primitiva em si
      não se repete aqui, só o uso correto pela nova função); falha simulada (ver
      AC-011-015 abaixo) não deixa Quadro parcial. Arquivo:
      `mnemonicos-backend/tests/integration/tira.service.integration.test.ts` (estende o
      arquivo de TASK-012-005/006). Comando: `npm --prefix mnemonicos-backend run
      test:integration -- --testPathPatterns=tira.service.integration.test.ts` → `OK (N
      tests)`.
- [ ] Testes cobrem AC-011-006, AC-011-007 (edit): novo texto persistido com posição
      intocada; tentativa que falha preserva o texto anterior — mesmo comando acima.
- [ ] Testes cobrem AC-011-008, AC-011-009 (remove): remover Quadro do meio (Tira com 4
      Quadros, remover a posição 2) recompõe 1,2,3 sem lacuna; tentativa que falha não
      remove nem reposiciona nenhum Quadro — mesmo comando acima.
- [ ] Testes cobrem AC-011-024 (completo): remover o ÚLTIMO Quadro restante → Tira fica
      com `frames: []`; reabrir a Tira em seguida (`openMnemonicStrip`, TASK-012-005) NÃO
      dispara nova geração automática (a Tira permanece vazia, não os 5 Quadros da
      geração inicial) — mesmo comando acima.
- [ ] Testes cobrem AC-011-012 (completo — round-trip de sessão): sequência real com as
      5 operações (`openMnemonicStrip` de TASK-012-005 → `addMnemonicFrame` →
      `updateMnemonicFrameText` → `removeMnemonicFrame` → `reorderMnemonicFrames` de
      TASK-012-006, nesta ordem, todas bem-sucedidas) sobre a MESMA Tira; ao final, uma
      nova chamada de `openMnemonicStrip` (reabertura, simulando fechar e reabrir a
      "sessão") devolve todos os Quadros restantes na ordem de posição persistida da
      última mutação bem-sucedida, com o texto atual de cada um. Mesmo comando acima →
      `OK (N tests)`, incluindo "round-trip completo: add+edit+remove+reorder sobrevivem
      à reabertura (AC-011-012)".
- [ ] Testes cobrem AC-011-014 (parte — via add/edit/remove), **um caso por sujeito**
      (FR-011-009 nomeia 4 sujeitos — reorder já coberto por TASK-012-006): Tira
      recém-gerada, sem mutação humana → 1ª chamada de `addMnemonicFrame` OU
      `updateMnemonicFrameText` OU `removeMnemonicFrame` (3 testes distintos, um por
      função) registra CONCLUSAO; a 2ª mutação humana subsequente (de qualquer um dos 4
      tipos) registra RETRABALHO, nunca uma 2ª CONCLUSAO. Mesmo comando acima → `OK (N
      tests)`.
- [ ] Testes cobrem AC-011-015 (parte — fail-secure), **um caso por função** (mesmo
      padrão de `contents.service.integration.test.ts`, describe "Fail-secure"):
      `jest.spyOn(productionEventsService, 'recordProductionStageEvent')
      .mockRejectedValueOnce(...)` durante `addMnemonicFrame`/`updateMnemonicFrameText`/
      `removeMnemonicFrame` (3 testes) — cada chamada propaga o erro e o estado da Tira
      (Quadros, textos, posições) permanece EXATAMENTE o de antes da tentativa. Mesmo
      comando acima → `OK (N tests)`.
- [ ] Testes cobrem a **guarda de pertencimento `frameId`→`stripId`** (defesa contra
      substituição de id, A01) com **mutação contável** (decisão 4.139/4.232 — mesma
      régua aplicada em TASK-012-006 ao array `order`): 2 Tiras distintas A e B (2
      `RawContent`s diferentes, cada uma com ao menos 1 Quadro); para CADA uma das 2
      funções que aceitam `frameId` (`updateMnemonicFrameText`, `removeMnemonicFrame`) —
      2 métodos no Escopo desta TASK que tocam esse predicado, 2 provas — chamar a
      função com o `rawContentId` de A e o `frameId` de um Quadro de B → rejeitada com
      `NotFoundError('Quadro não encontrado.')` (mesma mensagem de "id inexistente" —
      nunca distinguir), e os Quadros de A **e** de B permanecem intocados. Mesmo
      comando acima → `OK (N tests)`.
- [ ] Testes cobrem AC-011-020, AC-011-022 (parte — estrutural, mesma régua de
      TASK-012-006): `assertRawContentReachable` é a 1ª chamada dentro do corpo de CADA
      uma das 3 funções (`addMnemonicFrame`, `updateMnemonicFrameText`,
      `removeMnemonicFrame`) — mesmo teste de leitura textual (regex ancorada por
      função, comentários excluídos) do arquivo
      `mnemonicos-backend/tests/unit/tira.service.guard-order.test.ts`, estendido com as
      3 novas funções. Comando: `npm --prefix mnemonicos-backend test --
      tira.service.guard-order.test.ts` → `OK (N tests)`. A prova comportamental
      completa de alcance já foi feita em TASK-012-005 — não duplicar.
- [ ] Testes cobrem NFR-011-002 (consumo da primitiva) e a lição "[Performance]
      `include`/`select` aninhado de relação não é 1 statement por padrão": cada uma das
      3 funções devolve `MnemonicStripDetail` inteiro com round-trips fixados em teste
      via `withQueryProbe` — confirma **1 round-trip de leitura final** (o `findMany`/
      `select` que monta o `MnemonicStripDetail` devolvido), não N+1 por Quadro. Mesmo
      comando acima → `OK (N tests)`.
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npm --prefix mnemonicos-backend run lint` → exit 0.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil `node-22.md`.
- [ ] Code review aprovado.

## Riscos específicos

- RISK-011-005 (INDEX.md) — last-write-wins entre 2 EDITORES concorrentes mutando a
  mesma Tira não é resolvido por esta TASK (aceito na SPEC, operação de 1 pessoa); a
  atomicidade por CHAMADA isolada (esta TASK + TASK-012-006) não cobre 2 chamadas
  concorrentes calculadas sobre estados diferentes.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Branch**:
**Commit SHA**:
**Jira**: KAN-57
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
