# TASK-033-005: Carimbo de Versão aprovada no PDF exportado

**Slug**: producao-material
**Pertence a**: PLAN-033
**Realiza (FRs)**: FR-032-010, FR-032-011, FR-032-012
**Funcionalidade**: FEAT-032-002 (primária)
**Componente**: COMP-033-007 (principal), COMP-033-008
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: TASK-033-001, TASK-033-002
- **Bloqueia**: nenhuma

## Contexto

Extensão puramente aditiva do pipeline de PDF (F6/F8): a 1ª linha do cabeçalho de
rascunho — hoje sempre `DRAFT_LABEL`, desenhada por `drawDraftHeader`/`createPage` (único
ponto de desenho, chamado por `buildSummaryPdf`/`buildStripPdf`/
`drawSupplementarySection`, toda página nova) — ganha um 2º modo de desenho: quando a
Versão vigente está aprovada E sem sinal de alteração aceso, exibe a marca de alcance
explícito no lugar de "RASCUNHO"; as 3 linhas seguintes (Variante, Gerado em, Versão/Data)
continuam desenhadas exatamente como hoje, sem mudança de layout nem de `MARGIN_TOP`. Esta
TASK roda EM PARALELO com TASK-033-003 (mesma wave): arquivos distintos
(`publication.service.ts`/`pdf-composer.ts` vs. `content-versions.service.ts`/
`.routes.ts`/`.schema.ts`), nenhuma colisão de escrita — as duas dependem só da Wave 1.
Território e precedentes: `docs/producao-material/MAP.md` (seção "Publicação — pipeline de
PDF"), `publication.service.ts:149-171` (`resolveVersionStampForPdf`, F8),
`pdf-composer.ts:104-195` (`DRAFT_LABEL`/`drawDraftHeader`/`versionStampText`, F8), e
PLAN-033 §1, §3 (COMP-033-007/008), §4 Fluxo 5.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/publication/publication.service.ts` (estende):
  - Import: troca `hasVersionedContentChanged` (não mais chamada diretamente neste
    arquivo) por `resolveAlterationSignal` de
    `'../content-versions/content-versions.service'` (cross-module, mesmo padrão já
    usado para `openMnemonicStrip` de `'../tira/tira.service'`); mantém
    `toVersionedContentFields`/`type VersionedContentFields` de `'../content-versions/versioned-content-diff'`
    (ainda usados por `assertRawContentExportable`/o call site).
  - `resolveVersionStampForPdf`: assinatura do `db` passa de
    `Pick<PublicationClient, 'contentVersion'>` para
    `Pick<PublicationClient, 'contentVersion' | 'productionStageEvent'>` (o Pick já
    existe em `PublicationClient`, nenhuma mudança de tipo em `PublicationClient` em si);
    o `select` da leitura de `latest` ganha `closedAt: true` e `approvedById: true`
    (novos, exigidos por `resolveAlterationSignal`/pelo cálculo de `approvedAndValid`); a
    chamada a `hasVersionedContentChanged(current, latest.contentSnapshot as ...)` é
    substituída por `await resolveAlterationSignal(rawContentId, current, latest, db)` —
    o campo `alteredAfterClosure` de `VersionStampForPdf` passa a refletir CONTEÚDO OU
    TIRA (extensão de FR-028-011 por FR-032-012), sem mudar o NOME do campo (o consumidor
    em `pdf-composer.ts` já lê esse booleano, comportamento existente preservado); ganha o
    campo novo `approvedAndValid: latest.approvedById !== null && !alteredAfterClosure`.
- `mnemonicos-backend/src/modules/publication/pdf-composer.ts` (estende):
  - `interface VersionStampForPdf` ganha `approvedAndValid: boolean`.
  - Nova função `resolveHeaderLabel(version: VersionStampForPdf | null): string` —
    `version?.approvedAndValid === true` ⇒ `` `Conteúdo normativo e Tira mnemônica —
    Versão ${version.number} aprovada` `` (FR-032-010, forma literal do PLAN §1/§3);
    qualquer outro caso (`version === null`, `approvedById === null`,
    `alteredAfterClosure === true`) ⇒ `DRAFT_LABEL` inalterado (FR-032-011).
  - `drawDraftHeader`: a 1ª linha (`page.drawText(DRAFT_LABEL, ...)`) passa a
    `page.drawText(resolveHeaderLabel(meta.version), ...)` — as 3 linhas seguintes
    (`VARIANT_LINE_Y`/`GENERATED_AT_LINE_Y`/`VERSION_LINE_Y`, via `versionStampText`, já
    Tira-aware por herdar `alteredAfterClosure`) continuam desenhadas SEM MUDANÇA de
    posição nem de `MARGIN_TOP`/`CONTENT_TOP_Y` — mudança puramente de TEXTO da 1ª linha,
    nunca de layout.
- `mnemonicos-backend/tests/unit/pdf-composer.test.ts` (estende): novo `describe('resolveHeaderLabel')`
  — (a) `version: null` ⇒ `DRAFT_LABEL`; (b) `{ approvedAndValid: false, ... }` ⇒
  `DRAFT_LABEL`; (c) `{ approvedAndValid: true, number: 5, ... }` ⇒ `'Conteúdo normativo e
  Tira mnemônica — Versão 5 aprovada'`. Função pura, sem I/O.
- `mnemonicos-backend/tests/integration/publication.service.integration.test.ts` (estende
  — molde `describe('exportPublication — carimbo de Versão editorial...')`, linhas
  986-1163): novos casos, `it.each(['RESUMO', 'TIRA'])`, cada um setando
  `sourceType`/`sourceCitation` no `RawContent` antes de fechar a Versão (ausentes por
  padrão em `createRawContent`, exigidos por FR-032-013 para a aprovação passar):
  - AC-032-009 (FR-032-010): Versão fechada + aprovada (via `approveContentVersion`,
    TASK-033-003, ADMIN elegível distinto do autor) e SEM alteração posterior → TODAS as
    páginas trazem o hex de `'Conteúdo normativo e Tira mnemônica — Versão 3 aprovada'`
    (número/data conforme o fixture) e a linha 4 (`versionStampText`) continua mostrando
    `'Versão 3 — verificado até <data>'`, inalterada; NENHUMA página traz o hex de
    `'RASCUNHO'` (substituição, não coexistência — ao contrário da linha de Versão/Data,
    que nunca muda).
  - AC-032-011 (FR-032-011): Versão 2 aprovada, Versão 3 fechada depois SEM aprovação
    própria → TODAS as páginas trazem `'RASCUNHO'` (a vigente é a 3, não aprovada — a
    aprovação da 2 não se propaga, FR-032-006), NENHUMA página traz o hex de `'aprovada'`.
  - AC-032-012 (FR-032-012) — fail-secure: Versão aprovada, um campo versionado do
    `RawContent` (ex.: `rawText`) alterado DEPOIS via `updateRawContent` (importado de
    `contents.service.ts`) → TODAS as páginas voltam a `'RASCUNHO'` com a marca de
    alteração posterior (`'alterado após o fechamento da Versão N'`, herdada de F8),
    NENHUMA página traz `'aprovada'`.
  - AC-032-024 (FR-032-012) — fail-secure, eixo TIRA: Versão aprovada, NENHUM campo
    versionado de `RawContent`/`RuleBreakdown` alterado, mas um `ProductionStageEvent`
    `stageType: 'TIRA_MNEMONICA'` é registrado com `occurredAt` DEPOIS de `closedAt`
    (inserção direta via `testPrisma.productionStageEvent.create`, mesmo padrão de
    fixture do PLAN — a correção do valor via a superfície REAL de `tira.service.ts` já
    está coberta pelo teste unitário de `resolveAlterationSignal`, TASK-033-002; este caso
    prova só a FIAÇÃO ponta a ponta) → TODAS as páginas voltam a `'RASCUNHO'` com a marca
    de alteração posterior, NENHUMA página traz `'aprovada'`.
  - **Não-regressão explícita** (reuso por CITAÇÃO, sem duplicar teste — os 2 cenários
    JÁ EXISTENTES no arquivo continuam provando os 2 ACs novos abaixo, porque o código sob
    teste é o MESMO caminho): AC-032-010 (Versão nunca aprovada — o teste existente de
    AC-028-009, "3 Versões fechadas, nenhuma aprovada", já prova `approvedAndValid: false`
    por construção, `latest.approvedById === null`) e AC-032-021 (nenhuma Versão fechada —
    o teste existente de AC-028-010, `latest === null`, nunca alcança o cálculo de
    `approvedAndValid`). Comentário adicionado nos 2 blocos existentes citando os IDs
    novos, sem alterar asserção.
  - **Herdado do gate 8 da Wave 1 (security-engineer, notas N2/N3 — decisão 4.140)**:
    (N3) o carimbo recalcula o sinal combinado NA HORA da exportação e nunca estampa
    "aprovada" só porque `approvedById !== null` — já provado pelo caso AC-032-024 acima
    (aprovada + evento de Tira posterior ao fechamento → RASCUNHO); o critério abaixo
    torna isso explícito com mutante. (N2) `productionStageEvent.findFirst` rejeitando
    durante `resolveVersionStampForPdf` → a Exportação falha (erro propaga, sem PDF) —
    nunca um PDF com "aprovada" nem um `catch → false` silencioso que estamparia
    RASCUNHO escondendo a falha. Caso novo na mesma suíte.
  - Fixture: usar o builder de `VersionedContentFields` que TASK-033-003 cria em
    `tests/support/` quando o teste precisar dos 11 campos (nunca uma 3ª cópia local).

### Não inclui

- Aprovação em si (`approveContentVersion`/schema/rota) — TASK-033-003, da qual esta TASK
  só consome (chama `approveContentVersion` nos fixtures de teste, nunca reimplementa a
  regra).
- `resolveAlterationSignal` em si — TASK-033-002, da qual esta TASK só consome.
- Mudança de layout interno de `buildStripPdf`/`buildSummaryPdf`/`drawSupplementarySection`
  além da troca de TEXTO da 1ª linha — nenhuma outra linha de desenho muda.
- Tipos TS `ContentVersion` espelhados, `store/api.ts`, painel de aprovação — TASK-033-006/007
  (o campo `approvedAndValid`/`VersionStampForPdf` é estrutura INTERNA do backend, nunca
  espelhada ao frontend — só `validApprovalForExport`, de `ContentVersionDetail`, o é).

## Critérios de pronto

- [ ] `resolveHeaderLabel` — verificação executável: `npm --prefix mnemonicos-backend
      test -- pdf-composer.test.ts` → `OK (N tests)`. Fixada antes do código.
- [ ] Testes cobrem AC-032-009, AC-032-011, AC-032-012, AC-032-024 — verificação
      executável: `npm --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=publication.service.integration.test.ts` → `OK (N tests)`.
- [ ] Testes existentes (AC-028-009/AC-028-010, agora também AC-032-010/AC-032-021)
      continuam verdes sem alteração de asserção — mesmo comando acima → `OK (N tests)`,
      contagem de testes do arquivo NÃO diminui.
- [ ] **Substituição, não coexistência** (achado de correção verificado pela cadeia do
      dado — o carimbo de Versão/Data, F8, SEMPRE coexistiu com "RASCUNHO"; o carimbo de
      aprovação, F9, SUBSTITUI "RASCUNHO"): o teste de AC-032-009 confirma
      explicitamente a AUSÊNCIA do hex de `'RASCUNHO'` em toda página quando aprovada e
      válida — nunca assumido, sempre testado (universo = todas as páginas, mesmo
      quantificador das demais provas de "toda página" desta suíte).
- [ ] Herança N3 do gate 8 W1: mutante (em `git worktree add`, nunca na árvore
      principal) que troca `approvedAndValid` por `latest.approvedById !== null` (ignora o
      sinal) → o caso AC-032-024 fica vermelho. Mesmo comando da suíte acima.
- [ ] Herança N2 do gate 8 W1: `findFirst` rejeitando → `exportPublication` rejeita,
      nenhum PDF devolvido — caso nomeado, mesmo comando da suíte acima → `OK (N tests)`.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npm --prefix mnemonicos-backend run lint` → exit 0.
- [ ] Aderência à stack/padrões da ficha e do perfil `node-22.md` — função pura sem I/O
      (`resolveHeaderLabel`), `select` explícito, dependência unidirecional
      (`publication.service.ts` importa de `content-versions.service.ts`, nunca o
      contrário).
- [ ] Segurança (gate 8): `security-engineer` revisa o diff — superfície tocada é
      composição de PDF a partir de dado já autorizado (sem rota/endpoint novo, sem
      mudança de autorização); confirmar que nenhum texto de usuário passa a ser
      interpolado sem o tratamento WinAnsi já existente (TRISK-027-006, herdado, fora de
      escopo desta TASK).
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-033-002 (PLAN §8) — `resolveAlterationSignal` acrescenta até 3 leituras extras
  por Exportação (mitigado pelo short-circuit já implementado em TASK-033-002; a medição
  de custo fica com TASK-033-004, que mede o mesmo caminho em `listContentVersions`).
- TRISK-033-004 (PLAN §8) — `publication.service.ts` importa `resolveAlterationSignal` de
  `content-versions.service.ts` (dependência unidirecional nova, sem ciclo — o módulo
  `content-versions` nunca importa de `publication`).
- Herdado de F8 (intocado): `contentSnapshot` como `Json` não tem validação de schema em
  runtime — o cast em `resolveAlterationSignal` (TASK-033-002) mascara um snapshot
  malformado em silêncio; aceito, mesmo registro de risco de TASK-029-003.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-27T19:58:11-0300
**Data conclusão**: 2026-09-27T21:06:53-0300
**Commit SHA**: 8160cd1 (+ 8d01262, 08e6452 — retry dos gates 1/7; âncoras renumeradas 5984073)
**Jira**: KAN-156

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 2) — security-engineer
- [x] Comportamento (gate 9): verificado (FEAT-032-002) — qa, 2026-09-29, 6/6 ACs por execução real + pdftotext (linha na SPEC-032)
