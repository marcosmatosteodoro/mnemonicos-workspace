# TASK-023-011: Vínculo de associação visual a Quadro (link/unlink)

**Slug**: producao-material
**Pertence a**: PLAN-023
**Realiza (FRs)**: FR-022-013, FR-022-014, FR-022-015, FR-022-016, FR-022-018, FR-022-019, FR-022-020, FR-022-021, FR-022-023, FR-022-024
**Funcionalidade**: FEAT-022-003 (primária)
**Componente**: COMP-023-008 (principal), COMP-023-009
**Wave**: 4
**Fatia sensível (princípio 8)**: security-engineer focado (reuso de guarda de alcance por autoria + regra de negócio central: idempotência/substituição)
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch do EPICO MNEMORA STUDIO, Estrategia unica -- decisao 4.126: F5 e uma fatia do epico, nunca abre branch propria; a sessao ja fez o sync de largada nela)

**Padrão de commit**: Conventional Commits (`commit.convention: "conventional"`) — `feat:`.
**Framework de teste**: Jest 30 + ts-jest + `supertest` — `tests/integration/*.integration.test.ts` (Postgres real, `jest.integration.config.ts`, `--runInBand`); estende os arquivos já existentes de PLAN-012 (`tira.service.integration.test.ts`/`tira.routes.integration.test.ts`).

## Dependências

- **Depende de**: TASK-023-004, TASK-023-008
- **Bloqueia**: TASK-023-017

## Contexto

Estende `tira.service.ts`/`tira.routes.ts` (F4, PLAN-012) com o vínculo/desvínculo de uma
associação visual a um Quadro específico — o vínculo mora na árvore de recursos do Quadro
(DEC-023-009), reusando `assertRawContentReachable`/`findStripId`
(`tira.service.ts:119-134`/`:353-375`, MAP.md §F4) sem alteração. Cardinalidade N:1
(FK `MnemonicFrame.visualAssociationId`, DEC-023-001): idempotente se a mesma associação já
está vinculada, substituição com confirmação explícita da UI (já dada) se há outra, 1º
vínculo caso contrário — cada caminho de escrita real emite `VisualAssociationLinkEvent`
(reuso, DEC-023-011) e `ProductionStageEvent` (`ASSOCIACAO_VISUAL`, DEC-023-005) na MESMA
`$transaction`. `MnemonicFrameDetail` ganha o campo flat `visualAssociationId`.

## Escopo

### Inclui

- `linkVisualAssociationToFrame(rawContentId, frameId, visualAssociationId, actor, db?)` em
  `tira.service.ts` — dentro de `db.$transaction`: (1) `assertRawContentReachable` — 1ª
  chamada, sempre; (2) `findStripId` — localiza `stripId` a partir do `rawContentId` da URL
  (nunca aceito cru de outro lugar); (3) confirma que `visualAssociationId` existe (leitura
  comum a todo EDITOR/ADMIN, FR-022-023 — sem escopo de autoria da associação aqui, é ela
  quem é comum, não o Quadro; import direto de `visual-associations.service.ts`, DEC-023-009
  — nunca o inverso); (4) guarda de pertencimento **e** escrita no MESMO `updateMany`
  (`where: { id: frameId, stripId }`, mesmo padrão anti-confused-deputy de
  `updateMnemonicFrameText`/`removeMnemonicFrame`); (5) idempotência (FR-022-021, 2ª
  cláusula): MESMO `visualAssociationId` já vinculado → no-op, sem escrita nem evento; (6)
  caso contrário (1º vínculo ou substituição): grava `visualAssociationId`, registra
  `VisualAssociationLinkEvent` (`wasReuse` = havia OUTRO Quadro, além deste, já apontando
  para a mesma associação ANTES desta escrita, sob o MESMO filtro de exclusão de soft-delete
  de FR-022-019) e chama `recordProductionStageEvent(tx, { rawContentId, stageType:
  'ASSOCIACAO_VISUAL', actorId: actor.id, now: new Date() })`.
- `unlinkVisualAssociationFromFrame(rawContentId, frameId, actor, db?)` — mesmos passos
  1-4; Quadro já sem vínculo → no-op (sem evento); caso contrário, grava
  `visualAssociationId: null` e emite `ProductionStageEvent` (mesma regra do passo 6 acima,
  SEM `VisualAssociationLinkEvent` — a métrica de reuso é sobre CRIAÇÃO de vínculo, nunca
  sobre remoção).
- Extensão de `MnemonicStripClient` (tipo existente, `tira.service.ts`) com as chaves
  `visualAssociation` e `visualAssociationLinkEvent`.
- ~~Extensão de `MnemonicFrameDetail` (campo escalar `visualAssociationId: string | null`) e
  de `MNEMONIC_STRIP_DETAIL_SELECT`~~ — **JÁ ENTREGUE na Wave 1** (retry sobre achado
  bloqueante do `code-reviewer`, commit `84b1f08` de TASK-023-005: campo + select já
  expostos em `tira.service.ts`, sempre `null` hoje — nenhuma escrita ainda). Esta TASK só
  precisa GRAVAR o valor real (link/unlink); a imagem em si nunca é embutida no payload (o
  cliente resolve via `GET /visual-associations/:id/image`, TASK-023-016). **Pendência
  herdada** (achado da rodada 2 do gate 1-7, fora_de_escopo): nenhum teste ainda prova o
  VALOR do campo no payload HTTP real (`getMnemonicStrip` devolvendo `visualAssociationId:
  null` sem vínculo / com o id quando vinculado) — a rede de paridade de tipos só compara
  declaração×declaração (RISK-006-006). Esta TASK fecha os DOIS ramos como parte de
  AC-022-013 (já no Critério de pronto abaixo).
- `POST /contents/:id/strip/frames/:frameId/visual-association` e `DELETE
  .../visual-association` em `tira.routes.ts` (COMP-023-009) — cada uma com `verifyOrigin` +
  `requireRole` PRÓPRIO na montagem (nenhuma herda de vizinha, mesma árvore plana das 6 rotas
  já existentes).
- `linkVisualAssociationSchema` (Zod, `visualAssociationId: z.uuid(...)`) em
  `tira.schema.ts` (TASK-023-007, já entregue — consumido aqui).
- Consulta/teste demonstrando a razão `wasReuse`/total sobre um período (DoD, métrica §1.3
  da SPEC) — sem UI nova exigida (`COUNT(*) FILTER (WHERE wasReuse) / COUNT(*)` sobre
  `occurredAt >= desde`).
- Rodar a suíte já existente de PLAN-012 (`tira.*`) e confirmar 0 regressão (AC-022-024,
  NFR-022-006).
- `route-authz-matrix.integration.test.ts`: as 2 chaves novas (`POST`/`DELETE
  .../visual-association`) entram automaticamente ao montar as rotas — confirma o
  crescimento de 28 para 30 pares (TRISK-023-006).

### Não inclui

- UI de vínculo/desvínculo (miniatura, diálogo de confirmação de substituição, 3 estados
  observáveis) — TASK-023-013, gate 9 daquela TASK.
- Rotas/CRUD do próprio acervo (`visual-associations.*`) — TASK-023-008/010/014/016.
- AC-022-017 (FR-022-020 — cascata: remover um Quadro vinculado remove o vínculo e
  preserva a associação) — provado pelo schema/migração (`onDelete: SetNull`, TASK-023-001),
  SEM código novo desta TASK; `removeMnemonicFrame` (COMP-012-004) permanece inalterado.
- Extensão de `types/domain.ts` (frontend) e da rede de paridade cross-repo
  (`tira-frontend-contract.test.ts`/`visual-associations-frontend-contract.test.ts`,
  COMP-023-010/011) — TASK própria fora desta.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Reaproveite `assertRawContentReachable`/`findStripId` por chamada direta — nunca
   reescreva nem duplique a guarda ou a localização do `stripId`.
2. A confirmação de existência da associação (passo 3) é uma leitura comum — não filtre por
   `authorId` da associação aqui; a escrita restrita ao autor da ASSOCIAÇÃO é regra de
   `visual-associations.service.ts` (TASK-023-008/010), nunca desta TASK.
3. Calcule `wasReuse` ANTES de gravar a nova linha do vínculo (a contagem de "outro Quadro
   além deste" precisa do estado anterior à escrita) — dentro da MESMA `$transaction`.
4. Para o teste de round-trips (lição de performance abaixo), use `withQueryProbe` (já
   declarado em `tira.service.integration.test.ts`) — não recrie o helper.

## Critérios de pronto

- [ ] Testes cobrem AC-022-011 (parte — vínculo efetivo e idempotência; a UI de 3 estados/
      seleção fecha em TASK-023-013/gate 9): Quadro sem vínculo → `linkVisualAssociationToFrame`
      com uma associação já vinculada a OUTRO Quadro → a MESMA associação passa a estar
      vinculada a AMBOS, sem duplicar linha no acervo (confirmado por contagem de linhas em
      `VisualAssociation` antes/depois — permanece 1).
- [ ] Testes cobrem AC-022-012 (parte — desvínculo efetivo): Quadro com vínculo →
      `unlinkVisualAssociationFromFrame` → `visualAssociationId` volta a `null`, a
      `VisualAssociation` NÃO é apagada do acervo (confirmado por `findUnique` na tabela do
      acervo).
- [ ] Testes cobrem AC-022-013 (parte — campo exposto no payload; exibição na tela é
      TASK-023-013/gate 9): `MnemonicStripDetail`/`MnemonicFrameDetail` devolvidos por
      `getMnemonicStrip` (e por qualquer leitura equivalente) incluem `visualAssociationId`
      com o valor correto (`null` sem vínculo, o `id` da associação com vínculo).
- [ ] Testes cobrem AC-022-015 (cobre FR-022-018, completo): EDITOR autenticado tentando
      vincular, desvincular OU consultar o vínculo (3 casos) de um Quadro cujo Conteúdo
      bruto de origem ele NÃO alcança (registrado por outro EDITOR) → recusado com a MESMA
      resposta que um `frameId`/`rawContentId` inexistente recebe (nunca distinguir "não
      existe" de "existe mas não alcança"); ADMIN, na mesma situação, realiza a operação
      normalmente.
- [ ] Testes cobrem AC-022-016 (parte — faceta "métrica"/`wasReuse`; as facetas "trava de
      remoção" e "contagem exibida" fecham em TASK-023-010/014): vínculo cujo Quadro tem
      Conteúdo bruto de origem soft-deleted NÃO conta como "outro Quadro" ao calcular
      `wasReuse` de um novo vínculo à mesma associação.
- [ ] Testes cobrem AC-022-018 (cobre FR-022-021, completo — substituição/idempotência no
      backend; a confirmação de UI é TASK-023-013/gate 9): Quadro já vinculado a A → vincular
      B → A é desvinculada, B passa a ser a ÚNICA associação vinculada (nunca as duas);
      Quadro já vinculado a B → vincular B novamente → no-op, SEM duplicar vínculo nem
      retornar erro, SEM emitir `VisualAssociationLinkEvent` nem `ProductionStageEvent` novo
      (confirmado por contagem de eventos antes/depois).
- [ ] **Guarda de alcance reusada — mutação contável (decisão 4.139/4.232, lição
      "[Segurança] Guarda reusada continua exigindo prova comportamental própria por novo
      método de escrita", `guidelines/project/lessons.md`)**: `linkVisualAssociationToFrame`
      e `unlinkVisualAssociationFromFrame` são 2 métodos NOVOS que chamam
      `assertRawContentReachable` (guarda herdada de F4, reusada SEM alteração) — N=2 → 2
      provas comportamentais próprias: EDITOR que não alcança o `rawContentId` → MESMA
      mensagem de "não encontrado" que um `frameId` inexistente recebe; ADMIN alcança.
      Mutante nomeado: trocar o `actor`/`rawContentId` por um valor de outro dono e confirmar
      que a suíte INTEIRA reprova — rodado pelo comando do critério (arquivo/suíte inteira,
      nunca `-t`/`--testNamePattern` isolado). Cobre AC-022-020 (parte — leitura/vínculo
      comuns a outro EDITOR, na direção contrária: EDITOR que ALCANÇA o Quadro consegue
      vincular/desvincular associação de QUALQUER autor).
- [ ] **[Testes] Árvore de decisão com precedência: um caso por PAR de ramos que coincide**
      (`guidelines/project/lessons.md`) — a árvore idempotente→substituição→1º-vínculo tem 3
      ramos; caso PRÓPRIO para o par que pode coincidir: Quadro já vinculado à MESMA
      associação B (ramo idempotente) NO MESMO INSTANTE em que outro Quadro do mesmo acervo
      também já aponta para B (vínculo concorrente pré-existente, que tornaria `wasReuse`
      verdadeiro se fosse um vínculo NOVO) — vincular B novamente ao primeiro Quadro
      permanece no-op (nenhuma escrita, nenhum evento, `wasReuse` NÃO recalculado nem
      gravado), mesmo com o vínculo concorrente presente; o mutante que reordena a checagem
      de idempotência para DEPOIS do cálculo de `wasReuse` reprova neste caso.
- [ ] **Mutação por guarda nova (FR-022-021/FR-022-018, fechamento contável explícito)**: N=2
      métodos × guarda de alcance = 2 provas (já contadas acima); N=2 métodos × idempotência
      = 2 provas adicionais (1 mutante por método que remove/inverte a checagem de
      idempotência, coberto por AC-022-018 para `link` e pelo caso "Quadro já sem vínculo" de
      AC-022-012 para `unlink`) — total mínimo de 4 pares contáveis nesta TASK (régua da
      decisão 4.232/`task-mutacao-sem-contagem`).
- [ ] Testes cobrem AC-022-021 (cobre FR-022-024, completo): Quadro SEM vínculo → 1º
      `linkVisualAssociationToFrame` → emite 1 `ProductionStageEvent`
      (`ASSOCIACAO_VISUAL`) para o `rawContentId` correspondente; CRUD isolado do acervo
      (criar/editar/remover associação visual, TASK-023-008/010, fora de uma ação de
      vínculo) → confirmado, por leitura do histórico de eventos, que NENHUM evento de etapa
      é emitido por essas operações.
- [ ] Consulta/teste da razão `wasReuse`/total (DoD, métrica §1.3 da SPEC — sem UI nova):
      fixture com N vínculos reais criados (mistura de reuso e não-reuso) sobre um período
      → a consulta/teste devolve a razão esperada, calculada sobre `VisualAssociationLinkEvent.occurredAt`.
- [ ] **Lição "[Performance] `include`/`select` aninhado de relação não é 1 statement por
      padrão" (`guidelines/project/lessons.md`, TRISK-023-005)**: `wasReuse` atravessa
      `frames → strip → ruleBreakdown → rawContent`; o round-trip de `link`/`unlink` é
      fixado em teste via `withQueryProbe` (já declarado em
      `tira.service.integration.test.ts`) — contagem ESTÁVEL, não cresce com o número de
      Quadros já vinculados à mesma associação.
- [ ] Testes cobrem AC-022-014 (parte — facet vincular/desvincular; as facets criar/editar
      e remover fecham em TASK-023-008/TASK-023-010): `route-authz-matrix.integration.test.ts`
      continua verde com as 2 chaves novas montadas (`POST`/`DELETE .../visual-association`)
      — nenhuma asserção fixa a alterar; confirma 401 sem sessão / 403 papel STUDENT nas 2
      rotas novas (NFR-022-003, parte).
- [ ] Testes cobrem AC-022-024 (cobre NFR-022-006, completo): a suíte já existente de
      PLAN-012 (`tira.service.integration.test.ts`, `tira.routes.integration.test.ts`,
      `tira.schema.test.ts`, `tira.rule.test.ts`, `tira.service.guard-order.test.ts`,
      `tira.service.apply-positions.test.ts`) roda depois desta implementação e todos os
      casos continuam passando SEM alteração de comportamento — comando: `npm --prefix
      mnemonicos-backend run test:integration -- --testPathPatterns=tira.*integration` e
      `npm --prefix mnemonicos-backend test -- tira\.` → `OK (N tests)` nas duas, sem
      regressão de contagem em relação à baseline pré-TASK.
- [ ] Verificação executável (gate 1, os itens de teste acima): `npm --prefix
      mnemonicos-backend run test:integration --
      --testPathPatterns=tira.service.integration.test.ts` → `OK (N tests)` (estende o
      arquivo de PLAN-012); `npm --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=tira.routes.integration.test.ts` → `OK (N tests)`; `npm --prefix
      mnemonicos-backend test -- tira.service.guard-order.test.ts` → `OK (N tests)` (estende
      a prova estrutural com `link`/`unlink`); `npm --prefix mnemonicos-backend run
      test:integration -- --testPathPatterns=route-authz-matrix.integration.test.ts` → `OK
      (N tests)`.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`), produção e teste — `npm --prefix mnemonicos-backend run lint` → exit 0.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil `node-22.md` — direção de dependência de
      módulo preservada (`tira.service.ts` importa de `visual-associations.service.ts`,
      NUNCA o inverso, DEC-023-009); toda a escrita (vínculo, log de reuso, evento de etapa)
      na MESMA `$transaction`.
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-023-005 (PLAN §8) — contagem de vínculos/checagem de reuso exige filtro aninhado
  por linha vinculada; mitigado nesta TASK por round-trip fixado em teste (`withQueryProbe`),
  medição real de custo fica para o gate 10.
- TRISK-023-006 (PLAN §8) — `route-authz-matrix` precisa alcançar as 2 chaves novas; a
  suíte deriva a árvore da `app` montada, sem lista paralela a manter em dia.
- RISK-011-005 (INDEX.md, herdado) — last-write-wins entre 2 EDITORES concorrentes mutando
  o mesmo Quadro não é resolvido por esta TASK (aceito na SPEC-011, operação de 1 pessoa);
  vale também para 2 vínculos concorrentes ao mesmo Quadro.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-99
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
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>

**Notas**: 
