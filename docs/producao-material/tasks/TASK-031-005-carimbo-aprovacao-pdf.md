# TASK-031-005: Carimbo de Versão aprovada no PDF exportado

**Slug**: producao-material
**Pertence a**: PLAN-031
**Realiza (FRs)**: FR-030-010, FR-030-011, FR-030-012
**Funcionalidade**: FEAT-030-002 (primária)
**Componente**: COMP-031-007 (principal), COMP-031-008
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-031-001, TASK-031-002
- **Bloqueia**: nenhuma

## Contexto

Extensão puramente aditiva do pipeline de PDF (F6/F8): a 1ª linha do cabeçalho de
rascunho — hoje sempre `DRAFT_LABEL`, desenhada por `drawDraftHeader`/`createPage` (único
ponto de desenho, chamado por `buildSummaryPdf`/`buildStripPdf`/
`drawSupplementarySection`, toda página nova) — ganha um 2º modo de desenho: quando a
Versão vigente está aprovada E sem sinal de alteração aceso, exibe a marca de alcance
explícito no lugar de "RASCUNHO"; as 3 linhas seguintes (Variante, Gerado em, Versão/Data)
continuam desenhadas exatamente como hoje, sem mudança de layout nem de `MARGIN_TOP`. Esta
TASK roda EM PARALELO com TASK-031-003 (mesma wave): arquivos distintos
(`publication.service.ts`/`pdf-composer.ts` vs. `content-versions.service.ts`/
`.routes.ts`/`.schema.ts`), nenhuma colisão de escrita — as duas dependem só da Wave 1.
Território e precedentes: `docs/producao-material/MAP.md` (seção "Publicação — pipeline de
PDF"), `publication.service.ts:149-171` (`resolveVersionStampForPdf`, F8),
`pdf-composer.ts:104-195` (`DRAFT_LABEL`/`drawDraftHeader`/`versionStampText`, F8), e
PLAN-031 §1, §3 (COMP-031-007/008), §4 Fluxo 5.

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
    TIRA (extensão de FR-028-011 por FR-030-012), sem mudar o NOME do campo (o consumidor
    em `pdf-composer.ts` já lê esse booleano, comportamento existente preservado); ganha o
    campo novo `approvedAndValid: latest.approvedById !== null && !alteredAfterClosure`.
- `mnemonicos-backend/src/modules/publication/pdf-composer.ts` (estende):
  - `interface VersionStampForPdf` ganha `approvedAndValid: boolean`.
  - Nova função `resolveHeaderLabel(version: VersionStampForPdf | null): string` —
    `version?.approvedAndValid === true` ⇒ `` `Conteúdo normativo e Tira mnemônica —
    Versão ${version.number} aprovada` `` (FR-030-010, forma literal do PLAN §1/§3);
    qualquer outro caso (`version === null`, `approvedById === null`,
    `alteredAfterClosure === true`) ⇒ `DRAFT_LABEL` inalterado (FR-030-011).
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
  padrão em `createRawContent`, exigidos por FR-030-013 para a aprovação passar):
  - AC-030-009 (FR-030-010): Versão fechada + aprovada (via `approveContentVersion`,
    TASK-031-003, ADMIN elegível distinto do autor) e SEM alteração posterior → TODAS as
    páginas trazem o hex de `'Conteúdo normativo e Tira mnemônica — Versão 3 aprovada'`
    (número/data conforme o fixture) e a linha 4 (`versionStampText`) continua mostrando
    `'Versão 3 — verificado até <data>'`, inalterada; NENHUMA página traz o hex de
    `'RASCUNHO'` (substituição, não coexistência — ao contrário da linha de Versão/Data,
    que nunca muda).
  - AC-030-011 (FR-030-011): Versão 2 aprovada, Versão 3 fechada depois SEM aprovação
    própria → TODAS as páginas trazem `'RASCUNHO'` (a vigente é a 3, não aprovada — a
    aprovação da 2 não se propaga, FR-030-006), NENHUMA página traz o hex de `'aprovada'`.
  - AC-030-012 (FR-030-012) — fail-secure: Versão aprovada, um campo versionado do
    `RawContent` (ex.: `rawText`) alterado DEPOIS via `updateRawContent` (importado de
    `contents.service.ts`) → TODAS as páginas voltam a `'RASCUNHO'` com a marca de
    alteração posterior (`'alterado após o fechamento da Versão N'`, herdada de F8),
    NENHUMA página traz `'aprovada'`.
  - AC-030-024 (FR-030-012) — fail-secure, eixo TIRA: Versão aprovada, NENHUM campo
    versionado de `RawContent`/`RuleBreakdown` alterado, mas um `ProductionStageEvent`
    `stageType: 'TIRA_MNEMONICA'` é registrado com `occurredAt` DEPOIS de `closedAt`
    (inserção direta via `testPrisma.productionStageEvent.create`, mesmo padrão de
    fixture do PLAN — a correção do valor via a superfície REAL de `tira.service.ts` já
    está coberta pelo teste unitário de `resolveAlterationSignal`, TASK-031-002; este caso
    prova só a FIAÇÃO ponta a ponta) → TODAS as páginas voltam a `'RASCUNHO'` com a marca
    de alteração posterior, NENHUMA página traz `'aprovada'`.
  - **Não-regressão explícita** (reuso por CITAÇÃO, sem duplicar teste — os 2 cenários
    JÁ EXISTENTES no arquivo continuam provando os 2 ACs novos abaixo, porque o código sob
    teste é o MESMO caminho): AC-030-010 (Versão nunca aprovada — o teste existente de
    AC-028-009, "3 Versões fechadas, nenhuma aprovada", já prova `approvedAndValid: false`
    por construção, `latest.approvedById === null`) e AC-030-021 (nenhuma Versão fechada —
    o teste existente de AC-028-010, `latest === null`, nunca alcança o cálculo de
    `approvedAndValid`). Comentário adicionado nos 2 blocos existentes citando os IDs
    novos, sem alterar asserção.

### Não inclui

- Aprovação em si (`approveContentVersion`/schema/rota) — TASK-031-003, da qual esta TASK
  só consome (chama `approveContentVersion` nos fixtures de teste, nunca reimplementa a
  regra).
- `resolveAlterationSignal` em si — TASK-031-002, da qual esta TASK só consome.
- Mudança de layout interno de `buildStripPdf`/`buildSummaryPdf`/`drawSupplementarySection`
  além da troca de TEXTO da 1ª linha — nenhuma outra linha de desenho muda.
- Tipos TS `ContentVersion` espelhados, `store/api.ts`, painel de aprovação — TASK-031-006/007
  (o campo `approvedAndValid`/`VersionStampForPdf` é estrutura INTERNA do backend, nunca
  espelhada ao frontend — só `validApprovalForExport`, de `ContentVersionDetail`, o é).

## Critérios de pronto

- [ ] `resolveHeaderLabel` — verificação executável: `npm --prefix mnemonicos-backend
      test -- pdf-composer.test.ts` → `OK (N tests)`. Fixada antes do código.
- [ ] Testes cobrem AC-030-009, AC-030-011, AC-030-012, AC-030-024 — verificação
      executável: `npm --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=publication.service.integration.test.ts` → `OK (N tests)`.
- [ ] Testes existentes (AC-028-009/AC-028-010, agora também AC-030-010/AC-030-021)
      continuam verdes sem alteração de asserção — mesmo comando acima → `OK (N tests)`,
      contagem de testes do arquivo NÃO diminui.
- [ ] **Substituição, não coexistência** (achado de correção verificado pela cadeia do
      dado — o carimbo de Versão/Data, F8, SEMPRE coexistiu com "RASCUNHO"; o carimbo de
      aprovação, F9, SUBSTITUI "RASCUNHO"): o teste de AC-030-009 confirma
      explicitamente a AUSÊNCIA do hex de `'RASCUNHO'` em toda página quando aprovada e
      válida — nunca assumido, sempre testado (universo = todas as páginas, mesmo
      quantificador das demais provas de "toda página" desta suíte).
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

- TRISK-031-002 (PLAN §8) — `resolveAlterationSignal` acrescenta até 3 leituras extras
  por Exportação (mitigado pelo short-circuit já implementado em TASK-031-002; a medição
  de custo fica com TASK-031-004, que mede o mesmo caminho em `listContentVersions`).
- TRISK-031-004 (PLAN §8) — `publication.service.ts` importa `resolveAlterationSignal` de
  `content-versions.service.ts` (dependência unidirecional nova, sem ciclo — o módulo
  `content-versions` nunca importa de `publication`).
- Herdado de F8 (intocado): `contentSnapshot` como `Json` não tem validação de schema em
  runtime — o cast em `resolveAlterationSignal` (TASK-031-002) mascara um snapshot
  malformado em silêncio; aceito, mesmo registro de risco de TASK-029-003.

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
