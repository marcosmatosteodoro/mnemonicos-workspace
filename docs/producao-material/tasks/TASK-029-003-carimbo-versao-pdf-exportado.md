# TASK-029-003: Carimbo de Versão e Data de fechamento legislativo no PDF exportado

**Slug**: producao-material
**Pertence a**: PLAN-029
**Realiza (FRs)**: FR-028-008, FR-028-009, FR-028-010, FR-028-011
**Funcionalidade**: FEAT-028-002 (primária)
**Componente**: COMP-029-003, COMP-029-007 (principal), COMP-029-008
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-029-001
- **Bloqueia**: TASK-029-004

## Contexto

Extensão puramente aditiva do pipeline de PDF (F6): o cabeçalho de rascunho, já desenhado
em toda página por `drawDraftHeader`/`createPage` (único ponto de desenho, chamado por
`buildSummaryPdf`, `buildStripPdf` e `drawSupplementarySection` — toda página nova), ganha
uma 4ª linha com a Versão vigente e a Data de fechamento legislativo, ou a marca de
ausência, ou a marca de alteração posterior — sempre ao lado do rótulo "Rascunho"
existente, sem alterá-lo. Território e precedentes: `docs/producao-material/MAP.md`
(seção "Publicação — pipeline de PDF (F6 · PLAN-025)" — `exportPublication` linha 239,
`assertRawContentExportable` linhas 78-89, `createPage`/`drawDraftHeader`
`pdf-composer.ts:108-145`, `MARGIN_TOP`/`CONTENT_TOP_Y` linhas 76-79) e PLAN-029 §3
(COMP-029-003/007/008), §4 Fluxo 4.

**Organização de arquivo — decisão desta TASK** (evita colisão de escrita com
TASK-029-002 na MESMA wave, lição "colisão de escrita em arquivo compartilhado",
`task-wave-overlap-arquivo`/4.228; as duas TASKs da Wave 2 não dependem uma da outra):
`hasVersionedContentChanged` (COMP-029-003) nasce num arquivo PRÓPRIO,
`versioned-content-diff.ts`, não em `content-versions.service.ts` (que só TASK-029-002
toca). `VersionStampForPdf` (o tipo do carimbo) nasce em `pdf-composer.ts`, ao lado de
`PublicationPdfMeta` (mesmo padrão de `StripFrameForPdf`/`ContrastForPdf`).

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/content-versions/versioned-content-diff.ts` (novo):
  `interface VersionedContentFields { rawText: string; radarClass: ProofRadarClass;
  sourceType: NormativeSourceType | null; sourceCitation: string | null; sourceUrl: string
  | null; concept: string; action: string; object: string; condition: string | null;
  exception: string | null; essence: string }` (os 5 campos versionados de `RawContent` +
  6 de `RuleBreakdown`, A-028-002/DEC-029-003) e `hasVersionedContentChanged(current:
  VersionedContentFields, snapshot: VersionedContentFields): boolean` — função PURA, sem
  I/O, compara campo a campo (`===` estrito por campo; `true` se qualquer um diferir).
  Único ponto de manutenção quando o recorte de A-028-002 mudar.
- `mnemonicos-backend/src/modules/publication/pdf-composer.ts` (estende):
  - `interface VersionStampForPdf { number: number; legislativeClosureDate: Date;
    alteredAfterClosure: boolean }` (exportada, ao lado de `PublicationPdfMeta`).
  - `PublicationPdfMeta` ganha o campo `version: VersionStampForPdf | null` (`null` =
    nenhuma Versão fechada, FR-028-009).
  - `MARGIN_TOP` passa de `85` para `100` (reserva 4 linhas em vez de 3) — `CONTENT_TOP_Y`
    é DERIVADO da mesma constante (`PAGE_HEIGHT - MARGIN_TOP`, linha 79 já existente),
    recalibrado automaticamente, sem duplicar o cálculo (TRISK-029-003).
  - Nova constante `VERSION_LINE_Y = PAGE_HEIGHT - 75` (mesmo espaçamento de 15pt das 3
    linhas existentes: `LABEL_LINE_Y`/`VARIANT_LINE_Y`/`GENERATED_AT_LINE_Y` em `-30`/
    `-45`/`-60`).
  - `formatLegislativeClosureDate(date: Date): string` — formata `DD/MM/AAAA` a partir dos
    componentes **UTC** do `Date` (`getUTCDate`/`getUTCMonth`/`getUTCFullYear`), **nunca**
    `Intl.DateTimeFormat` sem `timeZone: 'UTC'` explícito nem os getters locais
    (`getDate`/`getMonth`): `legislativeClosureDate` é construído a partir de uma string
    ISO `YYYY-MM-DD` sem componente de hora (meia-noite UTC, TASK-029-002) — formatar pelo
    fuso LOCAL do servidor pode exibir o dia ANTERIOR (ex.: servidor em
    `America/Sao_Paulo`, UTC-3: meia-noite UTC de 01/09 vira 21h de 31/08 local).
  - `drawDraftHeader` ganha a 4ª linha, desenhada sempre (mesmo padrão das 3 já
    existentes — nunca condicionalmente omitida), na MESMA página, ao lado do rótulo
    "Rascunho" (que segue desenhado sem alteração, FR-028-010):
    - `meta.version === null` → `'Sem versão fechada.'` (FR-028-009 — literal desta TASK;
      a SPEC cita "sem versão" só como exemplo, não como texto obrigatório).
    - `meta.version !== null && !meta.version.alteredAfterClosure` →
      `` `Versão ${meta.version.number} — verificado até
      ${formatLegislativeClosureDate(meta.version.legislativeClosureDate)}` `` (FR-028-008,
      forma literal já no PLAN §3 COMP-029-008).
    - `meta.version !== null && meta.version.alteredAfterClosure` → a MESMA linha acima
      acrescida de `` ` — alterado após o fechamento da Versão
      ${meta.version.number}` `` (FR-028-011, forma literal do exemplo de SPEC-028
      FR-028-011/AC-028-013).
- `mnemonicos-backend/src/modules/publication/publication.service.ts` (estende):
  - `assertRawContentExportable`: `select` ganha os 5 campos versionados de `RawContent`
    (`rawText`, `radarClass`, `sourceType`, `sourceCitation`, `sourceUrl`); a função passa
    a devolver `{ pegadinhaText, rawText, radarClass, sourceType, sourceCitation,
    sourceUrl }` (mesmo round-trip da guarda, sem I/O adicional — já documentado como
    padrão pelo próprio comentário existente da função para `pegadinhaText`, F7).
  - `PublicationClient` ganha `'contentVersion'` no `Pick`.
  - Nova função `resolveVersionStampForPdf(rawContentId, current: VersionedContentFields,
    db: Pick<PublicationClient, 'contentVersion'>): Promise<VersionStampForPdf | null>` —
    busca `db.contentVersion.findFirst({ where: { rawContentId }, orderBy: { number:
    'desc' }, select: { number: true, legislativeClosureDate: true, contentSnapshot: true
    } })`; `null` → devolve `null` (FR-028-009); senão, `hasVersionedContentChanged(current,
    latest.contentSnapshot as VersionedContentFields)` (o cast é seguro: `contentSnapshot`
    só é gravado por `closeContentVersion`, TASK-029-002, sempre na mesma forma) decide
    `alteredAfterClosure` — fail-secure (A-028-012): falso negativo proibido, falso
    positivo tolerado quando o sinal for grosso demais para distinguir (comparação exata
    campo a campo nunca produz falso positivo nesta forma, então este fail-secure é
    satisfeito por construção).
  - `exportPublication`: chama `resolveVersionStampForPdf` logo após ler `breakdown` (tem
    os 6 campos de `RuleBreakdown` já selecionados por `RULE_BREAKDOWN_FOR_PUBLICATION_SELECT`,
    reusados sem nova consulta) e antes de montar `meta` — `meta.version` recebe o
    resultado.

### Não inclui

- Fechamento de Versão em si (`closeContentVersion`/`listContentVersions`/rotas) —
  TASK-029-002, da qual esta TASK só lê (`contentVersion.findFirst`).
- Mudança de layout interno de `buildStripPdf`/`buildSummaryPdf`/`drawSupplementarySection`
  além da recalibragem centralizada de `MARGIN_TOP`/`CONTENT_TOP_Y` e da chamada de
  `drawDraftHeader` — nenhuma outra linha de desenho muda.
- Tipos TS `ContentVersion` espelhados, `store/api.ts`, tela de histórico/fechamento —
  TASK-029-004.
- Extensão de `tests/support/pdf-text.ts` com uma nova função `decodedPageTexts` (ver
  Critérios de pronto abaixo) é a ÚNICA mudança em arquivo de suporte de teste
  compartilhado — nada mais em `tests/support/` muda.

## Critérios de pronto

- [ ] **Suporte de teste — extração de texto POR PÁGINA** (pré-requisito mecânico dos
      critérios "toda página" abaixo — a função `decodedPageContent` já existe em
      `tests/support/pdf-text.ts:64-83` mas não é exportada): exportar
      `decodedPageTexts(doc: PDFDocument): string[]` (mapeia `decodedPageContent` para
      cada índice de página, devolvendo 1 string por página — nunca concatenado como
      `decodedDocumentText`, que já existe e continua sendo usado pelos testes que não
      precisam da granularidade por página). Verificação executável: `npm --prefix
      mnemonicos-backend test -- pdf-text` (se houver suíte própria) OU confirmado
      indiretamente pelos testes abaixo que a consomem.
- [ ] `hasVersionedContentChanged` — função pura (COMP-029-003), teste unitário novo
      `mnemonicos-backend/tests/unit/versioned-content-diff.test.ts`: (a) mesmos 11 campos
      → `false`; (b) QUALQUER um dos 11 campos divergente (1 teste por campo — 11 casos,
      fechamento contável por CAMPO, não por "1 teste representativo") → `true`. Sem I/O
      (nenhum import de Prisma/banco no arquivo). Verificação executável: `npm --prefix
      mnemonicos-backend test -- versioned-content-diff.test.ts` → `OK (12 tests)`.
- [ ] **Formatação de data imune a fuso** (achado de correção verificado pela cadeia do
      dado, ver Contexto): `mnemonicos-backend/tests/unit/pdf-composer.test.ts` (estende)
      — `formatLegislativeClosureDate(new Date('2026-09-01T00:00:00.000Z'))` devolve
      `'01/09/2026'` com `process.env.TZ = 'America/Sao_Paulo'` (UTC-3) setado ANTES da
      chamada. Falsificável: uma implementação por fuso LOCAL devolveria `'31/08/2026'`
      sob esse TZ — o teste reprovaria. Verificação executável: `npm --prefix
      mnemonicos-backend test -- pdf-composer.test.ts` → `OK (N tests)`.
- [ ] Testes cobrem AC-028-009 (FR-028-008) — **quantificador "toda página"** (lição ativa
      "[Testes] Prova de ausência por leitura de texto-fonte precisa declarar o universo
      lido, derivado do quantificador do critério" — aqui o quantificador é de PRESENÇA,
      mesmo raciocínio simétrico: "toda página" exige ler TODAS, nunca só `getPage(0)`):
      `RawContent` com Quebra da regra salva e 1 `ContentVersion` fechada (`number: 3`,
      `legislativeClosureDate: 2026-09-01`), Conteúdo/Quebra intactos desde o fechamento
      → `exportPublication` (ambas Variantes) → `decodedPageTexts(doc)` tem
      `doc.getPageCount() >= 2` (Protocolo suplementar sempre soma 1+ página além da
      principal) e **TODAS** as páginas (`.every(...)`) contêm o hex de `'Versão 3 —
      verificado até 01/09/2026'`. Verificação executável: `npm --prefix
      mnemonicos-backend run test:integration --
      --testPathPatterns=publication.service.integration.test.ts` → `OK (N tests)`.
      Fixada antes do código.
- [ ] Testes cobrem AC-028-010 (FR-028-009): `RawContent` com Quebra da regra salva, SEM
      nenhuma `ContentVersion` fechada → **todas** as páginas contêm o hex de `'Sem versão
      fechada.'`, em vez de número/data. Mesmo comando acima → `OK (N tests)`.
- [ ] Testes cobrem AC-028-011 (FR-028-010): nos 2 casos acima (com e sem Versão), **todas**
      as páginas continuam contendo o hex do `DRAFT_LABEL` ("RASCUNHO — documento gerado
      automaticamente..."), coexistindo com a linha nova — nenhum teste aceita a
      substituição do rótulo. Mesmo comando acima → `OK (N tests)`.
- [ ] Testes cobrem AC-028-013 (FR-028-011): `RawContent` com `ContentVersion` `number: 3`
      fechada em `2026-09-01`, e a Quebra da regra EDITADA depois desse fechamento (ex.:
      `saveRuleBreakdown` chamado de novo alterando `concept`, entre o fechamento e a
      exportação) → **todas** as páginas contêm o hex de `'Versão 3 — verificado até
      01/09/2026 — alterado após o fechamento da Versão 3'`. Falsificável (fail-secure,
      A-028-012): se `resolveVersionStampForPdf` comparasse contra o snapshot errado ou
      ignorasse a divergência, este caso reprovaria (falso negativo é o que NFR-028
      proíbe). Mesmo comando acima → `OK (N tests)`.
- [ ] Testes cobrem o caso SIMÉTRICO de AC-028-013 (nenhum campo versionado alterado após
      o fechamento — controle negativo do mutante acima): mesmo cenário de AC-028-009, a
      marca de alteração NUNCA aparece (`decodedPageTexts` sem o hex de `'alterado após o
      fechamento'` em NENHUMA página). Mesmo comando acima → `OK (N tests)`.
- [ ] `resolveVersionStampForPdf` busca a Versão mais recente por `orderBy: { number:
      'desc' }, take: 1` (não a mais antiga nem por `closedAt`) — cenário com 3 Versões
      fechadas em ordem, a exportação estampa a de MAIOR `number`, mesmo que
      `legislativeClosureDate` das 3 não seja monotônica (DEC-029-006 — histórico de
      datas não implica ordem cronológica). Mesmo comando acima → `OK (N tests)`.
- [ ] **Comparação com o molde canônico** (decisão 4.307): `versioned-content-diff.ts` é
      conferido contra a assinatura EXATA do `VersionedContentFields`/`contentSnapshot`
      que TASK-029-002 grava (mesmos 11 nomes de campo, mesma nulabilidade) — divergência
      de nome entre os dois módulos (ex.: `sourceType` vs `source_type`) quebraria a
      comparação em silêncio (Json não tem typecheck cruzado); conferir por leitura direta
      do `contentSnapshot` montado em `content-versions.service.ts` (TASK-029-002, mesma
      wave — ambos os arquivos existem lado a lado ao fim da Wave 2), não da lembrança do
      PLAN.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npm --prefix mnemonicos-backend run lint` → exit 0.
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-029-002 (PLAN §8) — acoplamento novo entre `content-versions`
  (`versioned-content-diff.ts`, `VersionedContentFields`) e `publication.service.ts`
  (consumidor): dependência unidirecional (publication importa de content-versions, nunca
  o contrário), função pura sem I/O, sem ciclo de módulo — mitigação já aplicada nesta
  TASK.
- TRISK-029-003 (PLAN §8) — a 4ª linha do cabeçalho reduz a área útil de conteúdo por
  página (`CONTENT_TOP_Y` depende de `MARGIN_TOP`); a recalibragem é centralizada em
  `drawDraftHeader`/`createPage` (único ponto de desenho, chamado pelas 3 funções de
  composição) — provada pela geração real do PDF nos cenários AC-028-009/010/013 acima
  (nunca só leitura estática do código).
- **`contentSnapshot` como `Json` não tem validação de schema em runtime** — se um
  fechamento futuro (fora desta TASK) gravar um snapshot malformado, o cast `as
  VersionedContentFields` em `resolveVersionStampForPdf` mascara o problema em silêncio
  (campo `undefined` comparado como string, `hasVersionedContentChanged` pode devolver
  `false` por engano — falso negativo, o que A-028-012 proíbe). Aceito nesta fatia porque
  o ÚNICO ponto de escrita (`closeContentVersion`, TASK-029-002) é interno e controlado;
  registrar como pendência se um 2º ponto de escrita de `ContentVersion` for introduzido
  no futuro sem validação de forma.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-140

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
