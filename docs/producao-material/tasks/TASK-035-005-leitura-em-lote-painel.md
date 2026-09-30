# TASK-035-005: Leitura em lote de dados do Painel (Conteúdos, eventos de etapa, Publicações Tira, versões)

**Slug**: producao-material
**Pertence a**: PLAN-035
**Realiza (FRs)**: FR-034-014
**Funcionalidade**: FEAT-034-002 (primária)
**Componente**: COMP-035-004 (principal), COMP-035-005, COMP-035-006, COMP-035-007
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-035-001
- **Bloqueia**: TASK-035-006

## Contexto

4 leituras em lote, cada uma **1** `findMany`/consulta de contagem fixa (`IN (...)`, nunca
1 por Conteúdo — NFR-034-001), que alimentam o cálculo puro (TASK-035-004): Conteúdos
ativos (com o mesmo filtro de remoção reversível de F2), eventos de etapa sem `actorId`
(NFR-034-004), Publicações da Variante Tira com `pageCount` (TASK-035-001), e a Versão
vigente + dados atuais só dos Conteúdos com Versão aprovada. Território e precedentes:
`mnemonicos-backend/src/modules/contents/contents.service.ts` (leitura direta confirmada
— `ACTIVE_RAW_CONTENT_WHERE`, linha 48; `RAW_CONTENT_SUMMARY_SELECT`, linhas 349-356;
`listRawContents`, linhas 387-412), `production-events.service.ts` (`listProductionStageEvents`,
linhas 104-113, molde de `select` sem `include`), e PLAN-035 §1, §3 (COMP-035-004/005/006/007),
§6 (DEC-035-013).

**Prova do vertical slicing**: cada função é testável isoladamente contra o Postgres real
(fixtures via `production-events-fixtures.ts`) — a orquestração que as compõe (TASK-035-006)
não reabre a lógica de filtro/select, só as chama.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/content-versions/content-versions.service.ts` — **ajuste por furo no
  plano (Tech Lead, 2026-09-30)**: acrescentar `export` às declarações já existentes de
  `RAW_CONTENT_VERSIONED_SELECT` (:108) e `RULE_BREAKDOWN_VERSIONED_SELECT` (:119) — só a
  palavra `export`, sem mudar valor, nome nem consumidores (aditivo; F9 intocado).
- `mnemonicos-backend/src/modules/strategic-panel/strategic-panel.service.ts` (novo
  módulo — schema→service→routes; esta TASK só a camada de leitura, sem `.routes.ts`
  ainda, que é TASK-035-006):
  - `listActiveContentsForPanel(db): Promise<PanelContentRow[]>` — 1 `findMany` de
    `RawContent` com `ACTIVE_RAW_CONTENT_WHERE` (importado de `../contents/contents.service`,
    reuso, nunca redeclarado — DEC-006-001) e **sem** `scopeWhere(actor)` (leitura
    factory-wide, DEC-035-013). `select` explícito: `id`, `radarClass`, `topic: { select:
    { name: true, discipline: { select: { name: true } } } }` — nunca
    `rawText`/`sourceCitation`/`pegadinhaText` (NFR-034-003), mesmo molde de
    `RAW_CONTENT_SUMMARY_SELECT` (`contents.service.ts:349-356`), com `select` PRÓPRIO
    (não reexportado — este módulo não precisa de `sourceCitation`/`breakdown`, que
    `RAW_CONTENT_SUMMARY_SELECT` inclui e o Painel não usa).
  - `listStageEventsForPanel(rawContentIds: string[], db): Promise<PanelStageEventRow[]>`
    — 1 `findMany` de `ProductionStageEvent` com `rawContentId: { in: rawContentIds }`,
    `orderBy: { sequence: 'asc' }`, `select` explícito **sem `actorId`**
    (`stageType`, `transitionType`, `sequence`, `occurredAt`, `rawContentId` — NFR-034-004:
    o Painel não agrega por pessoa, então o dado nem entra em memória) e sem `include`.
  - `listTiraPublicationEventsForPanel(rawContentIds: string[], db):
    Promise<PanelPublicationEventRow[]>` — 1 `findMany` de `PublicationEvent` com
    `rawContentId: { in: rawContentIds }`, `variant: 'TIRA'`, `select: { rawContentId,
    occurredAt, pageCount }` (`pageCount`, coluna nova da TASK-035-001).
  - `listLatestVersionsForPanel(rawContentIds: string[], db):
    Promise<PanelVersionRow[]>` — 1 `findMany` de `ContentVersion`
    `rawContentId: { in: rawContentIds }`, `orderBy: { number: 'asc' }`, `select:
    { rawContentId, closedAt, approvedById, contentSnapshot: true }`; o chamador agrupa em
    memória por `rawContentId` (última entrada = vigente) — nunca 1 `findFirst` por
    Conteúdo.
  - `listCurrentVersionedFieldsForApprovedContents(rawContentIds: string[], db):
    Promise<Map<string, VersionedContentFields>>` — só para os Conteúdos cuja Versão
    vigente tem `approvedById !== null` (o chamador, TASK-035-006, resolve esse subconjunto
    e passa aqui): 2 `findMany` `IN (...)` (`RawContent`/`RuleBreakdown` com o `select`
    versionado de `versioned-content-diff.ts` — reuso das constantes
    `RAW_CONTENT_VERSIONED_SELECT`/`RULE_BREAKDOWN_VERSIONED_SELECT` já exportadas por
    `content-versions.service.ts`, nunca duplicadas), agrupados em `Map` por
    `rawContentId` via `toVersionedContentFields` (F9, reuso).
- `mnemonicos-backend/tests/integration/strategic-panel.service.integration.test.ts`
  (novo — molde `content-versions.service.integration.test.ts`, fixtures via
  `production-events-fixtures.ts`):
  - AC-034-011 (FR-034-014): 2 Conteúdos, 1 soft-deletado (`softDeleteRawContent` real, de
    `contents.service.ts`) → `listActiveContentsForPanel` devolve só o ativo.
  - Prova de DEC-035-013 (sem AC associado): 2 Conteúdos ATIVOS com `authorId` DIFERENTE
    entre si → uma única chamada de `listActiveContentsForPanel` devolve os 2 (igualdade
    de conjunto entre os Conteúdos dos dois autores, independente de quem é o autor — a
    função nem recebe `actor`/`authorId` como parâmetro de filtro).
  - NFR-034-004 (parte mecanismo — a prova de PAYLOAD HTTP é da TASK-035-006): leitura de
    `listStageEventsForPanel` NUNCA inclui `actorId` — estrutural (item b, decisão 4.161):
    `Object.keys(row)` de cada linha devolvida não contém `'actorId'` (checagem sobre o
    OBJETO REAL devolvido, nunca grep do código-fonte).
  - NFR-034-003 (parte mecanismo): `Object.keys(row)` de `listActiveContentsForPanel` não
    contém `'rawText'`/`'sourceCitation'`/`'pegadinhaText'`.
  - `listTiraPublicationEventsForPanel`: 2 Conteúdos, cada um com Exportações TIRA e
    RESUMO → devolve só as TIRA, com `pageCount` (incluindo `null` quando a Exportação é
    anterior à TASK-035-001 — fixture cria o `PublicationEvent` direto no Prisma sem
    `pageCount`).
  - `listLatestVersionsForPanel`: Conteúdo com 3 Versões fechadas → devolve as 3, o
    chamador agrupa (`.at(-1)` por `rawContentId`) — teste confirma `orderBy: number asc`
    (a última do array é a de maior `number`).
  - `listCurrentVersionedFieldsForApprovedContents`: 2 Conteúdos aprovados + 1 não
    aprovado no `rawContentIds` de entrada → `Map` resultante tem exatamente 2 chaves
    (nunca inclui o não aprovado, mesmo que citado no array de entrada — o filtro é do
    CHAMADOR, mas esta função aceita qualquer lista e só busca o que existe; o teste
    confirma que passar o id do não-aprovado não lança nem inclui campos vazios).
- `mnemonicos-backend/tests/unit/strategic-panel.service.query-shape.test.ts` (novo,
  estrutural — item b): para cada uma das 4 funções, confirma por leitura do `select`
  declarado (não da resposta em runtime) que nenhuma delas usa `include` (só `select`
  aninhado) — `grep -c "include:" mnemonicos-backend/src/modules/strategic-panel/
  strategic-panel.service.ts` → 0.

### Não inclui

- `buildStrategicPanel` (orquestração que soma as 4 leituras + chama o cálculo puro) e a
  rota HTTP — TASK-035-006.
- Prova de consultas constantes (10 vs. 200 Conteúdos) — TASK-035-006 (exige o conjunto
  completo, orquestrado).
- `.schema.ts`/`.routes.ts` do módulo `strategic-panel` — sem parâmetro de entrada
  validável nesta camada (rota é `GET` sem params), então `.schema.ts` só nasce se
  necessário na TASK-035-006.

## Critérios de pronto

- [ ] **Ajuste pós-gate 10 da Wave 2 (performance-engineer) — coluna larga fora do histórico**:
      `listLatestVersionsForPanel` deixa de selecionar `contentSnapshot` (só `id`,
      `rawContentId`, `number`, `closedAt`, `approvedById`); nova
      `listApprovedVersionSnapshots(versionIds, db)` — 1 `findMany` `id: { in }`,
      `select: { id, contentSnapshot }`. Prova: query-count por função atualizado (1 statement
      para a nova) e 1 caso com Conteúdo de 3 Versões (a vigente NÃO aprovada) asserindo que a
      leitura de versões não devolve `contentSnapshot` (chaves exatas) — verificação:
      `npm --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=strategic-panel.service.integration.test.ts` → `OK (N tests)`.
- [ ] **Achado do gate 1 da Wave 2 (code-reviewer) — eixo PERTENCIMENTO em toda leitura em lote**:
      toda função que filtra por `IN (ids)` (6 leituras no Escopo, 6 provas; lista não
      exaustiva: eventos de etapa, publicações Tira, versões, snapshots, RawContent e
      RuleBreakdown dos aprovados) tem fixture com a linha correspondente de um Conteúdo
      FORA do array de entrada e asserção de que ela não volta; mutante (em
      `git worktree add`) que remove o `IN` de cada uma → o teste daquela função reprova.
- [ ] **Ajuste por furo no plano — export das constantes de select versionado**: as 2
      declarações passam a `export const` sem outra mudança — verificação executável:
      `grep -nE '^export const (RAW_CONTENT_VERSIONED_SELECT|RULE_BREAKDOWN_VERSIONED_SELECT)'
      mnemonicos-backend/src/modules/content-versions/content-versions.service.ts` → 2 linhas
      (calibrado contra o commit-pai cb5e834 → 0 linhas); `git diff cb5e834 --
      mnemonicos-backend/src/modules/content-versions/content-versions.service.ts` mostra só
      as 2 linhas com `export` acrescentado; suíte de F9
      (`npm --prefix mnemonicos-backend test -- content-versions` e
      `npm --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=content-versions.service.integration.test.ts`) com a mesma contagem
      verde de antes.
- [ ] Testes cobrem AC-034-011, NFR-034-004 (parte), NFR-034-003 (parte) — verificação
      executável: `npm --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=strategic-panel.service.integration.test.ts` → `OK (N tests)`.
      Fixada antes do código.
- [ ] **Prova de DEC-035-013 (sem AC associado) — fechamento contável do predicado de
      escopo** (decisão 4.139/4.232): o predicado `ACTIVE_RAW_CONTENT_WHERE` **sem**
      `scopeWhere` (leitura factory-wide deliberada) é a exceção documentada — o teste
      novo (ver Escopo > Inclui) cria 2 Conteúdos ATIVOS de autores (`authorId`)
      DIFERENTES e confirma, numa única chamada de `listActiveContentsForPanel`, que o
      retorno inclui os Conteúdos dos dois autores (igualdade de conjunto, independente
      do autor) — verificação executável: `npm --prefix mnemonicos-backend run
      test:integration -- --testPathPatterns=strategic-panel.service.integration.test.ts`
      → `OK (N tests)`, com o teste de 2 autores presente no relatório de execução.
      Complemento (não substitui a prova acima): a ASSINATURA confirma que a função nem
      recebe `actor`/`authorId` como parâmetro — `grep -nE "^export (async )?function
      listActiveContentsForPanel|^export const listActiveContentsForPanel"
      mnemonicos-backend/src/modules/strategic-panel/strategic-panel.service.ts | head -1`
      (âncora em início de linha — a declaração, não uma menção em docblock/import)
      confirma a assinatura de 1 parâmetro (`db`).
- [ ] Nenhuma das 4 funções usa `include` — verificação executável: `npm --prefix
      mnemonicos-backend test -- strategic-panel.service.query-shape.test.ts` → `OK (1
      test)`.
- [ ] **Item (d) — consumidores por varredura**: `RAW_CONTENT_VERSIONED_SELECT`/
      `RULE_BREAKDOWN_VERSIONED_SELECT` são IMPORTADOS de `content-versions.service.ts`,
      nunca redeclarados — `grep -n "RAW_CONTENT_VERSIONED_SELECT\|RULE_BREAKDOWN_VERSIONED_SELECT"
      mnemonicos-backend/src/modules/strategic-panel/strategic-panel.service.ts | grep -vE
      ':\s*(//|\*)' | wc -l` → ≥ 2 ocorrências de IMPORT fora de comentário (não de
      `const ... = {`); `grep -c "^const RAW_CONTENT_VERSIONED_SELECT\|^const RULE_BREAKDOWN_VERSIONED_SELECT"
      mnemonicos-backend/src/modules/strategic-panel/strategic-panel.service.ts` → 0
      (nenhuma redeclaração local, já ancorado em início de linha).
- [ ] 4 `findMany`, cada um 1 statement — fixado por `withQueryProbe`
      (`tests/support/query-probe.ts`, molde `content-versions.service.integration.test.ts:445-469`):
      cada função chamada isoladamente contra um fixture de 5 Conteúdos produz
      exatamente 1 statement (2 para `listCurrentVersionedFieldsForApprovedContents`,
      que soma `RawContent`+`RuleBreakdown`) — verificação executável: mesmo comando do
      1º item acima, describe `'query-count por função'`.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`) — `npm --prefix mnemonicos-backend run lint`
      → exit 0.
- [ ] Segurança (gate 8): `security-engineer` revisa a ausência deliberada de
      `scopeWhere` (DEC-035-013) contra NFR-034-003/004 — confirma que a leitura
      factory-wide não abre superfície de dado por-pessoa em nenhuma das 4 funções.
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-035-001 (PLAN §8, herdado de RISK-034-005/TRISK-010-002) — `listStageEventsForPanel`
  não pagina; aceito nesta fatia sob o volume de referência medido no gate 10 da
  TASK-035-006. `Reabrir se`: volume real justificar paginação/particionamento (decisão de
  PLAN futuro).
- DEC-035-013 (leitura factory-wide) é decisão de produto explícita — qualquer regressão
  futura que reintroduza `scopeWhere` aqui quebraria a Conclusão por Módulo/agregados de
  fábrica (persona "conclusão do meu módulo" se refere ao Tema, não à autoria).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-172

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
