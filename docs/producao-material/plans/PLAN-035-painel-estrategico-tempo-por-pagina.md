# PLAN-035: Painel estratégico e tempo por página

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.2
**Autor**: keelson (scribe)
**Data**: 2026-09-30

## Aderência a guidelines

**Decisões irreversíveis do slug tocadas**: nenhuma — `DEC-029-003` (`ContentVersion.contentSnapshot`
como snapshot JSON) é **lida** por este PLAN (predicado de F9 em lote), nunca alterada; a
forma do campo não muda.
**Decisões irreversíveis de outros slugs em conflito**: `{docsRoot}/infra-vercel/INDEX.md` —
sem bloco de decisões (o slug não tem `INDEX.md`); nenhuma outra.
**Exceções aos guidelines**: nenhuma.

## Cobertura

**SPEC referenciada**: SPEC-034
**Slice declarado**: cobertura total (Caso D — todos os FRs/NFRs de SPEC-034)

**FRs cobertos**:
- FR-034-001
- FR-034-002
- FR-034-003
- FR-034-004
- FR-034-005
- FR-034-006
- FR-034-007
- FR-034-008
- FR-034-009
- FR-034-010
- FR-034-011
- FR-034-012
- FR-034-013
- FR-034-014
- FR-034-015
- FR-034-016
- FR-034-017
- FR-034-018
- FR-034-019
- FR-034-020
- FR-034-021
- FR-034-022
- FR-034-023
- FR-034-024
- FR-034-025
- FR-034-026
- FR-034-027
- FR-034-028
- FR-034-029
- FR-034-030
- FR-034-031
- FR-034-032
- FR-034-033
- FR-034-034

**NFRs cobertos**:
- NFR-034-001
- NFR-034-002
- NFR-034-003
- NFR-034-004

## 1. Visão técnica

Duas fatias independentes, uma que **alimenta** dado novo e outra que **lê** tudo que a
fábrica já mede desde F3/F6/F8/F9:

1. **Registro de páginas na Exportação** (FEAT-034-001) — `PublicationEvent` ganha a única
   coluna nova deste PLAN (`pageCount Int?`, migração aditiva). A contagem é capturada no
   ponto em que o PDF final (principal + suplementar já fundidos, A-034-001) existe em
   memória — `mergeSupplementaryPages` (`publication.service.ts`) — e gravada, na mesma
   `$transaction` de sempre, ao lado do evento de etapa `PUBLICACAO_PDF`. Falha na
   contagem não falha a Exportação (FR-034-019): vira `pageCount: null`, log estruturado
   sem texto de conteúdo, documento entregue normalmente — outra classe de falha da
   composição do PDF em si (ex.: teto de duração, imagem irrenderável) continua propagando
   como hoje, sem relação com este ponto.

2. **Painel estratégico** (FEAT-034-002) — módulo novo `strategic-panel` (backend) que
   **não introduz nenhum model** — lê `RawContent`/`Topic`/`Discipline` (ativos),
   `ProductionStageEvent` (todas as 8 etapas, sem `actorId` — NFR-034-004), `PublicationEvent`
   (Variante Tira, com `pageCount`) e `ContentVersion` (vigente por Conteúdo), sempre em
   **consultas de contagem fixa** (`IN (...)`, nunca 1 por Conteúdo — NFR-034-001), e entrega
   tudo a uma **função pura** que recebe `now` e devolve o payload inteiro calculado em
   memória: tempo total/por página/por etapa/por etapa por página, agregados por Módulo e
   fábrica, conclusão por Módulo, correções após revisão, backlog com prioridade e
   ordenação. A correlação entre a Exportação medida e o evento de etapa que a gerou (para
   saber **quando**, em termos de `sequence`, ela aconteceu) usa a identidade
   `(rawContentId, occurredAt)` — os dois nascem com o mesmo `now`, na mesma transação,
   desde F6 — nunca uma coluna de ordenação própria em `PublicationEvent` (DEC-035-011).

O predicado "aprovada e válida para exportação" de F9 (`resolveAlterationSignal`,
`content-versions.service.ts`) é extraído para uma função pura reusável em lote, sem mudar
seu comportamento unitário — MAP F9 é explícito: mudar a regra é mudar os 3 usos juntos, e
o Painel se torna o 4º.

No frontend, o placeholder de `(interno)/studio` vira a casca do Painel: Server Component +
1 client component consumindo um endpoint RTK Query novo, 3 estados + vazio global + vazio
por seção, sem biblioteca de gráfico (números/tabelas/barras em CSS com os tokens já
existentes).

## 2. Stack e dependências

Stack vigente herdado, sem dependência nova: Prisma 7 (migração aditiva), Express 5,
`pdf-lib` (já em uso, só o método `getPageCount()` que já existe nunca foi chamado), RTK
Query, Tailwind 4 (tokens existentes).

## 3. Componentes

### COMP-035-001: Migração `PublicationEvent.pageCount`
**Responsabilidade**: Coluna nova `pageCount Int?` em `PublicationEvent`
(`prisma/schema.prisma`) — `null` = sem medida (Exportação anterior a esta capacidade, ou
falha de contagem). Migração aditiva única, sem `sequence` nova nesta tabela (DEC-035-011).
**Realiza**: FR-034-001
**Interface pública**: coluna de schema, sem função.
**Dependências**: nenhuma

### COMP-035-002: Contagem de páginas fail-safe na composição
**Responsabilidade**: `countPagesForExport(doc: PDFDocument): number | null` —
`mnemonicos-backend/src/modules/publication/publication.service.ts`, chamada dentro de
`mergeSupplementaryPages` **depois** de `copyPages`/`addPage` (documento final já fundido,
inclui páginas suplementares — A-034-001) e **antes** de `.save()`. Envolve só a chamada de
`primaryDoc.getPageCount()` em `try/catch` — falha vira `logger.warn({ rawContentId },
'Falha ao contar páginas na Exportação')` (sem texto de conteúdo) + `null`; nunca aborta a
composição. `mergeSupplementaryPages` passa a devolver `{ buffer: Buffer; pageCount: number
| null }` em vez de só `Buffer` — `composeVariantBuffer`/`composePublicationBuffer`
propagam a tupla até `exportPublication`.
**Realiza**: FR-034-001, FR-034-019
**Interface pública**: `countPagesForExport(doc): number | null`; assinatura nova de
`mergeSupplementaryPages`/`composePublicationBuffer` (retorno `{ buffer, pageCount }`).
**Dependências**: COMP-035-001

### COMP-035-003: Registro da contagem no evento de Publicação
**Responsabilidade**: `exportPublication` grava `pageCount` no `tx.publicationEvent.create`
existente (mesma `$transaction` do evento de etapa `PUBLICACAO_PDF`, mesmo `now` — a
correlação de DEC-035-011 depende de nada mudar aqui além do campo novo). Exportação
anterior a esta capacidade permanece com `pageCount: null` para sempre — nenhuma
reexportação futura recomputa uma linha antiga (FR-034-021, FR-034-002).
**Realiza**: FR-034-001, FR-034-002, FR-034-021
**Interface pública**: sem mudança de assinatura pública de `exportPublication`.
**Dependências**: COMP-035-002

### COMP-035-004: Leitura de Conteúdos ativos para o Painel
**Responsabilidade**: `listActiveContentsForPanel(db): Promise<PanelContentRow[]>` — novo
módulo `mnemonicos-backend/src/modules/strategic-panel/strategic-panel.service.ts`. 1
`findMany` de `RawContent` com `ACTIVE_RAW_CONTENT_WHERE` (reusado de `contents.service.ts`,
DEC-006-001) e **sem** `scopeWhere(actor)` — leitura factory-wide (DEC-035-013). `select`
explícito: `id`, `radarClass`, `topic: { select: { name: true, discipline: { select: {
name: true } } } }` — nunca `rawText`/`sourceCitation`/`pegadinhaText` (NFR-034-003).
**Realiza**: FR-034-014
**Interface pública**: `listActiveContentsForPanel(db): Promise<PanelContentRow[]>`
**Dependências**: nenhuma

### COMP-035-005: Leitura em lote de eventos de etapa
**Responsabilidade**: `listStageEventsForPanel(rawContentIds, db): Promise<PanelStageEventRow[]>`
— 1 `findMany` de `ProductionStageEvent` com `rawContentId: { in: rawContentIds }`,
`orderBy: { sequence: 'asc' }`, `select` explícito **sem `actorId`** (NFR-034-004 — o
Painel não agrega por pessoa, então o dado nem entra em memória) e sem `include`.
**Realiza**: FR-034-006, NFR-034-004
**Interface pública**: `listStageEventsForPanel(rawContentIds: string[], db): Promise<PanelStageEventRow[]>`
**Dependências**: COMP-035-004

### COMP-035-006: Leitura em lote de Publicações (Variante Tira)
**Responsabilidade**: `listTiraPublicationEventsForPanel(rawContentIds, db)` — 1 `findMany`
de `PublicationEvent` com `rawContentId: { in: ... }`, `variant: 'TIRA'`, `select: {
rawContentId, occurredAt, pageCount }`.
**Realiza**: FR-034-003
**Interface pública**: `listTiraPublicationEventsForPanel(rawContentIds: string[], db): Promise<PanelPublicationEventRow[]>`
**Dependências**: COMP-035-004

### COMP-035-007: Leitura em lote da Versão vigente e dados atuais para F9
**Responsabilidade**: (a) `listLatestVersionsForPanel(rawContentIds, db)` — 1 `findMany` de
`ContentVersion` `rawContentId: { in: ... }`, `orderBy: { number: 'asc' }`, agrupado em
memória por `rawContentId` (última entrada = vigente) — nunca 1 `findFirst` por Conteúdo;
`select` só com chaves leves (`id`, `rawContentId`, `number`, `closedAt`, `approvedById`),
**sem** `contentSnapshot` (ajuste pós-gate 10 da Wave 2: histórico append-only ilimitado não
trafega). (a2) `listApprovedVersionSnapshots(versionIds, db)` — 1 `findMany` de
`ContentVersion` `id: { in: <vigentes aprovadas> }`, `select: { id, contentSnapshot }`, no
mesmo `Promise.all` do subconjunto aprovado.
(b) `listCurrentVersionedFieldsForApprovedContents(rawContentIds, db)` — só para os
Conteúdos cuja Versão vigente tem `approvedById !== null`: 2 `findMany` `IN (...)`
(`RawContent`/`RuleBreakdown` com o `select` versionado de `versioned-content-diff.ts`),
nunca 1 par por Conteúdo.
**Realiza**: FR-034-009
**Interface pública**: `listLatestVersionsForPanel(...)`, `listCurrentVersionedFieldsForApprovedContents(...)`
**Dependências**: COMP-035-004

### COMP-035-008: Predicado único de F9 extraído para função pura
**Responsabilidade**: `isVersionAltered(current: VersionedContentFields, version: {
contentSnapshot: unknown; closedAt: Date }, latestTiraOccurredAt: Date | null): boolean` —
novo arquivo `mnemonicos-backend/src/modules/content-versions/version-alteration.ts`, sem
I/O. Combina `hasVersionedContentChanged` (curto-circuito) com a comparação
`latestTiraOccurredAt > closedAt` que hoje vive dentro de `resolveAlterationSignal`.
`resolveAlterationSignal` (`content-versions.service.ts`) passa a só fazer a leitura (1
`findFirst` de `TIRA_MNEMONICA` por `sequence desc`) e delegar a decisão a esta função —
comportamento unitário idêntico (mesmos testes de F9 seguem verdes). O Painel chama a
mesma função por Conteúdo, em memória, sobre os dados já lidos em lote (COMP-035-005/007) —
sem I/O adicional por Conteúdo.
**Realiza**: FR-034-009
**Interface pública**: `isVersionAltered(current, version, latestTiraOccurredAt): boolean`
**Dependências**: COMP-035-007

### COMP-035-009: Prioridade de apresentação (função pura)
**Responsabilidade**: `derivePresentationPriority(radarClass: ProofRadarClass): 'ALTA' |
'MEDIA' | 'BAIXA'` — novo arquivo `mnemonicos-backend/src/domain/presentation-priority.ts`.
Implementa a derivação já comentada no schema (`schema.prisma:48-50`, DEC-006-009) que
nenhum PLAN anterior tinha codificado: `ALTA→ALTA`, `MEDIA→MEDIA`,
`DETALHE|EXCECAO|PEGADINHA→BAIXA`.
**Realiza**: FR-034-027
**Interface pública**: `derivePresentationPriority(radarClass): PresentationPriority`
**Dependências**: nenhuma

### COMP-035-010: Cálculo de métricas por Conteúdo (função pura)
**Responsabilidade**: `computeContentMetrics(now, content, stageEvents, publicationEvents,
latestVersion, currentFields?): ContentMetrics` — novo arquivo
`mnemonicos-backend/src/modules/strategic-panel/strategic-panel-calculations.ts`, sem I/O.
Por Conteúdo: (1) início registrado = 1º evento `CONTEUDO_BRUTO` (`sequence` mínima) —
ausente → tudo "sem medida — início da produção não registrado" (FR-034-026); (2) Export
de referência = entre os eventos `PUBLICACAO_PDF` com `sequence` maior que o do 1º
`VERSAO_EDITORIAL`, o de menor `sequence` cujo `PublicationEvent` correlato
(`rawContentId`+`occurredAt` idênticos) tem `variant: TIRA` (FR-034-003/020); sem essa
correlação ou sem `pageCount` nela → "sem medida" (FR-034-002/007/021/024); (3) tempo total
= `occurredAt` da Exportação de referência − início registrado; tempo por página = tempo
total ÷ `pageCount` dessa Exportação (FR-034-004/005); (4) por etapa (das 8), do 1º ao
último evento da etapa: "em aberto" (só `ABERTURA`), "não percorrida" (0 eventos), "sem
duração medida" (evento sem abertura correspondente), ou o intervalo medido incluindo
retrabalho (FR-034-006/022/023/024); tempo por etapa por página quando há tempo por página
medido (FR-034-025); (5) correções após revisão: eventos `RETRABALHO` das 5 etapas de
conteúdo com `sequence` maior que a do 1º `VERSAO_EDITORIAL`, contados por etapa
(FR-034-010/031); (6) `Concluído` = `latestVersion.approvedById !== null &&
!isVersionAltered(...)` (COMP-035-008); marcador "aprovada, alterada depois" quando
aprovada e alterada (FR-034-028); (7) etapa mais avançada (ordem fixa, Publicação
excluída) e idade = now − início registrado, ou "sem registro"/"sem medida" sem eventos
(FR-034-027/029).
**Realiza**: FR-034-004, FR-034-005, FR-034-006, FR-034-007, FR-034-010, FR-034-011, FR-034-020, FR-034-021, FR-034-022, FR-034-023, FR-034-024, FR-034-025, FR-034-026, FR-034-028, FR-034-029, FR-034-031
**Interface pública**: `computeContentMetrics(now: Date, input: ContentMetricsInput): ContentMetrics`
**Dependências**: COMP-035-008, COMP-035-009

### COMP-035-011: Agregação por Módulo/fábrica e backlog (função pura)
**Responsabilidade**: `aggregateStrategicPanel(now, metricsByContent[]): StrategicPanelPayload`
— mesmo arquivo de COMP-035-010. Agrupa por Módulo (Tema) e pela fábrica inteira: média,
mediana, `n` (Conteúdos com tempo por página medido) e cobertura (`n` / ativos do recorte)
(FR-034-008); Conclusão por Módulo = ativos × Concluídos (FR-034-009); correções após
revisão totalizadas por etapa por Conteúdo e por fábrica, sem somar etapas
(FR-034-011/031), com a legenda fixa (FR-034-032); backlog = Conteúdos ativos não
Concluídos, ordenado por prioridade (Alta→Média→Baixa) e, dentro dela, do mais antigo para
o mais novo, com idade "sem medida" sempre depois de idade numérica na mesma prioridade
(FR-034-012/013/030).
**Realiza**: FR-034-008, FR-034-009, FR-034-012, FR-034-013, FR-034-027, FR-034-030, FR-034-032
**Interface pública**: `aggregateStrategicPanel(now: Date, metrics: ContentMetrics[]): StrategicPanelPayload`
**Dependências**: COMP-035-010

### COMP-035-012: Orquestração do Painel
**Responsabilidade**: `buildStrategicPanel(now, db): Promise<StrategicPanelPayload>` — chama
COMP-035-004/005/006/007 (número fixo de consultas, ver DEC-035-014), monta os
`Map`s de correlação em memória e entrega a COMP-035-010/011. Único ponto que soma I/O ao
cálculo puro.
**Realiza**: FR-034-003, FR-034-020, NFR-034-002
**Interface pública**: `buildStrategicPanel(now: Date, db = prisma): Promise<StrategicPanelPayload>`
**Dependências**: COMP-035-004, COMP-035-005, COMP-035-006, COMP-035-007, COMP-035-010,
COMP-035-011

### COMP-035-013: Rota `GET /strategic-panel`
**Responsabilidade**: `mnemonicos-backend/src/modules/strategic-panel/strategic-panel.routes.ts`
— `requireRole('EDITOR', 'ADMIN')`, sem `verifyOrigin` (padrão do projeto para `GET`), sem
`.schema.ts` (rota sem parâmetro de entrada — nada para o Zod validar). Handler `async`
chama `buildStrategicPanel(new Date())` e monta a resposta **campo a campo por allowlist
explícita** (nunca `res.json(payload)` direto do retorno da função pura — DEC-035-017):
nenhuma chave fora da lista fixada chega ao cliente. Montada em
`mnemonicos-backend/src/http/routes.ts` (após `contentVersionsRoutes`) — entra no censo de
`route-authz-matrix`.
**Realiza**: FR-034-015, FR-034-016
**Interface pública**: `GET /strategic-panel` → `StrategicPanelResponse`
**Dependências**: COMP-035-012

### COMP-035-014: Prova de consultas constantes
**Responsabilidade**: `mnemonicos-backend/tests/integration/strategic-panel.query-count.integration.test.ts`
— `withQueryProbe` (`tests/support/query-probe.ts`) chamando `buildStrategicPanel` com um
volume de 10 Conteúdos e depois com 200 (cada um com eventos de etapa reais, gerados via
`recordProductionStageEvent`/fixtures, nunca via seed direto do Prisma — RISK-034-004),
asserindo a **mesma contagem de statements** nos dois volumes (NFR-034-001).
**Realiza**: NFR-034-001
**Interface pública**: suíte de teste, sem export.
**Dependências**: COMP-035-012

### COMP-035-015: Testes unitários das funções de cálculo, por FR
**Responsabilidade**: `mnemonicos-backend/tests/unit/strategic-panel-calculations.test.ts`
— 1 cenário por FR/AC de FEAT-034-002 sobre `computeContentMetrics`/`aggregateStrategicPanel`
(sem banco), incluindo os 4 estados de tempo por etapa (medido/em aberto/não
percorrida/sem duração medida — FR-034-022/023/024), a ordenação do backlog
(FR-034-013/030) e o marcador de F9 alterado/aprovado (FR-034-028).
**Realiza**: FR-034-022, FR-034-023, FR-034-024
**Interface pública**: suíte de teste, sem export.
**Dependências**: COMP-035-010, COMP-035-011

### COMP-035-016: Teste HTTP de payload, autorização e ausência de agrupamento por pessoa
**Responsabilidade**: `mnemonicos-backend/tests/integration/strategic-panel.routes.integration.test.ts`
— `supertest` sobre a rota real: (a) `Object.keys` exatas do payload por Conteúdo/agregado
contra a allowlist declarada (molde: `content-versions.routes.integration.test.ts`,
lição "select exposto... prova as chaves do payload") — prova NFR-034-003 (0 campos de
texto normativo) e NFR-034-004 (0 chave por autor/editor, nenhuma delas
`actorId`/`authorId`/`lastEditedById`); (b) 401 sem sessão, 403 com `STUDENT` (FR-034-015/016).
**Realiza**: NFR-034-003, NFR-034-004, FR-034-015, FR-034-016
**Interface pública**: suíte de teste, sem export.
**Dependências**: COMP-035-013

### COMP-035-017: Espelho de tipos backend↔frontend e teste de paridade/contrato
**Responsabilidade**: (a) `PRODUCTION_STAGE_TYPES`/`PRODUCTION_EVENT_TRANSITIONS` (já
existentes só no backend, DEC-010-006) ganham o espelho em
`mnemonicos-frontend/src/types/domain.ts` — 1º consumidor real de tela; (b) interfaces do
payload do Painel (`StrategicPanelResponse` e subtipos) declaradas nos dois lados; (c)
`mnemonicos-backend/tests/unit/domain-types-parity.test.ts:161-194` estendido para comparar
os 2 lados (hoje só backend×schema, comentário "F10 acrescenta"); (d) novo
`mnemonicos-backend/tests/unit/strategic-panel-frontend-contract.test.ts` (molde:
`visual-associations-frontend-contract.test.ts`, `extractInterfaceFields`,
DECLARAÇÃO×DECLARAÇÃO) para as interfaces do painel.
**Realiza**: FR-034-004
**Interface pública**: tipos exportados de `domain.ts`/`domain/types.ts`; suítes de teste.
**Dependências**: COMP-035-011

### COMP-035-018: Endpoint RTK Query `getStrategicPanel`
**Responsabilidade**: `mnemonicos-frontend/src/store/api.ts` — `getStrategicPanel: builder.query<
StrategicPanelResponse, void>({ query: () => '/strategic-panel', providesTags:
['StrategicPanel'], forceRefetch: () => true })` (DEC-035-019 — refetch a cada visita em vez
de tag de invalidação cruzando os módulos que a SPEC agrega; `refetchOnMountOrArgChange` não é
opção por endpoint no RTK Query — TS2353 —, ajuste da Wave 4).
**Realiza**: FR-034-017
**Interface pública**: `useGetStrategicPanelQuery()`
**Dependências**: COMP-035-017

### COMP-035-019: Util de formatação de duração pt-BR
**Responsabilidade**: `mnemonicos-frontend/src/lib/format-duration.ts` —
`formatDurationPtBr(ms: number): string` (ex.: "3 dias e 4 horas") + teste dedicado
(`tests/lib/format-duration.test.ts` ou co-localizado conforme §7 do perfil). Único ponto
de formatação de tempo do Painel — nenhuma seção reimplementa `Intl`/cálculo de duração.
**Realiza**: FR-034-006
**Interface pública**: `formatDurationPtBr(ms: number): string`
**Dependências**: nenhuma

### COMP-035-020: Casca do Painel e 3 estados
**Responsabilidade**: `mnemonicos-frontend/src/app/(interno)/studio/page.tsx` deixa de ser
placeholder e vira casca Server Component (título, `metadata`) que monta
`strategic-panel-board.tsx` (`'use client'`, molde de 3 estados de
`content-list.tsx:32-77`: carregando/erro+retry/sucesso) + estado vazio global
(FR-034-033, nenhum Conteúdo ativo). `INTERNAL_HOME` permanece `/studio` (sem mudança em
`internal-routes.ts`/`proxy.ts`) — a falha do Painel é um retorno do client component
(estado de falha com "Tentar novamente"), nunca um `error.tsx` de segmento, para não
regredir o destino pós-login (AC-034-023, DEC-035-020).
**Realiza**: FR-034-017, FR-034-018, FR-034-033
**Interface pública**: `StudioPage` (Server Component), `StrategicPanelBoard` (client).
**Dependências**: COMP-035-018

### COMP-035-021: Seções do Painel e vazio por seção
**Responsabilidade**: dentro de `strategic-panel-board.tsx` (ou componentes filhos
co-localizados): (a) tempo por página/por etapa por Conteúdo, com "sem medida"/"em
aberto"/"não percorrida"/"sem duração medida" tratados como texto, nunca zero; (b)
agregados por Módulo e fábrica (média/mediana/n/cobertura) em tabela; (c) conclusão por
Módulo (barra simples em CSS com os tokens existentes); (d) correções após revisão por
etapa, com a legenda fixa (FR-034-032) e o indicador geral (FR-034-031); (e) backlog
ordenado, cada item com etapa mais avançada, prioridade (rótulo pt-BR), idade e o
marcador "aprovada, alterada depois — aguarda nova aprovação" quando aplicável, com link
`/content/:id` (FR-034-027/028). Cada seção sem dado próprio mostra o vazio DELA
(FR-034-034), sem ocultar as demais quando o Painel como um todo tem sucesso.
**Realiza**: FR-034-004, FR-034-005, FR-034-006, FR-034-025, FR-034-008, FR-034-009, FR-034-010, FR-034-011, FR-034-012, FR-034-013, FR-034-027, FR-034-028, FR-034-029, FR-034-030, FR-034-031, FR-034-032, FR-034-034
**Interface pública**: componentes React internos ao slot do Painel, sem rota própria.
**Dependências**: COMP-035-019, COMP-035-020

### COMP-035-022: Tipos e rótulos de apresentação do frontend
**Responsabilidade**: `mnemonicos-frontend/src/types/domain.ts` — mapas de rótulo pt-BR
(`PRESENTATION_PRIORITY_LABELS`: Alta/Média/Baixa; rótulos dos 4 estados de tempo por
etapa; texto do marcador de F9) seguindo o padrão já usado por
`PROOF_RADAR_CLASS_LABELS`/`PUBLICATION_VARIANT_LABELS` — nunca string solta no JSX.
**Realiza**: FR-034-022, FR-034-023, FR-034-024, FR-034-028
**Interface pública**: `PRESENTATION_PRIORITY_LABELS`, demais mapas de rótulo.
**Dependências**: COMP-035-009, COMP-035-017

## 4. Fluxos principais

**Fluxo 1 — Exportação registra páginas** (FEAT-034-001): `POST /contents/:id/publication`
→ `exportPublication` (inalterado nos passos 1-5) → `composePublicationBuffer` →
`mergeSupplementaryPages` funde principal+suplementar → `countPagesForExport` (COMP-035-002,
fail-safe) → mesma `$transaction` grava `ProductionStageEvent{PUBLICACAO_PDF}` e
`PublicationEvent{variant, pageCount, occurredAt: now}` com o mesmo `now` → documento
entregue ao cliente independente do resultado da contagem.

**Fluxo 2 — Leitura do Painel** (FEAT-034-002): `GET /strategic-panel` (EDITOR/ADMIN) →
`buildStrategicPanel(now)` dispara as consultas de contagem fixa (DEC-035-014) em paralelo onde
independentes (Conteúdos ativos; eventos de etapa `IN`; publicações Tira `IN`; versões
vigentes `IN`; dados atuais só dos aprovados `IN`) → `computeContentMetrics` por Conteúdo
(em memória) → `aggregateStrategicPanel` (Módulo/fábrica/backlog) → rota serializa por
allowlist → resposta.

**Fluxo 3 — Correlação Exportação × evento de etapa** (núcleo de FR-034-003/020): para um
Conteúdo, entre os `ProductionStageEvent{PUBLICACAO_PDF}` com `sequence` maior que o do 1º
`VERSAO_EDITORIAL`, cada um é casado por igualdade exata de `(rawContentId, occurredAt)`
com um `PublicationEvent`; dos casados com `variant: TIRA`, o de menor `sequence` é a
Exportação de referência — sua `pageCount` (se houver) e seu `occurredAt` alimentam tempo
total/por página. Nenhuma consulta nova por Conteúdo: a correlação roda inteira em memória
sobre os 2 conjuntos já lidos em lote (COMP-035-005/006).

**Fluxo 4 — Backlog e prioridade**: para cada Conteúdo ativo não Concluído (COMP-035-008),
`derivePresentationPriority(radarClass)` decide o balde (Alta/Média/Baixa);
`aggregateStrategicPanel` ordena por balde e, dentro dele, por idade crescente, com "sem
medida" sempre ao final do mesmo balde.

**Fluxo 5 — Tela**: `useGetStrategicPanelQuery()` → 3 estados (carregando/erro+retry/sucesso)
→ sucesso sem Conteúdo ativo → vazio global; sucesso com Conteúdos mas uma seção sem dado
próprio (ex.: nenhum com tempo por página medido) → vazio só daquela seção, demais
renderizam.

## 5. Modelo de dados

Nenhum model novo. Única mudança de schema: `PublicationEvent.pageCount Int?` (migração
aditiva, autorizada para dev/teste por A-034-004; produção segue pelo deploy). Todo o
resto do Painel é leitura agregada sobre `RawContent`, `Topic`, `Discipline`,
`ProductionStageEvent`, `PublicationEvent` e `ContentVersion` já existentes.

## 6. Decisões arquiteturais

### Decisões herdadas
- **DEC-035-001** [herdada] Migração aditiva de `pageCount` autorizada para dev/teste pelo
  Diretor; produção segue pelo deploy — fonte: SPEC-034 A-034-004.
- **DEC-035-002** [herdada] Tempo é lead time de calendário, nunca esforço — fonte: SPEC-034
  A-034-003 (SPEC-009 E-02).
- **DEC-035-003** [herdada] Fórmula exata de tempo total/por etapa/por página, incluindo os
  4 estados sem número — fonte: SPEC-034 A-034-011.
- **DEC-035-004** [herdada] Painel é leitura interna EDITOR/ADMIN, agregada no servidor —
  fonte: SPEC-034 A-034-005.
- **DEC-035-005** [herdada] Painel nunca exibe métrica individualizada por autor/editor —
  fonte: SPEC-034 A-034-009/NFR-034-004.
- **DEC-035-006** [herdada] Prioridade de apresentação ALTA/MEDIA/BAIXA a partir do
  `radarClass` (`ALTA→ALTA`, `MEDIA→MEDIA`, `DETALHE|EXCECAO|PEGADINHA→BAIXA`) — fonte:
  SPEC-034 A-034-012 (`schema.prisma` DEC-006-009).
- **DEC-035-007** [herdada] Concluído = a mesma regra única de "aprovada e válida para
  exportação" de F9 — fonte: SPEC-034 §3/A-034-007/A-034-008; `docs/producao-material/INDEX.md`
  §F9 ("mudar a regra é mudar os 3 juntos").
- **DEC-035-008** [herdada] Etapa mais avançada exclui a Publicação do cálculo (a Exportação
  de rascunho pode ocorrer em qualquer ponto após a Quebra) — fonte: SPEC-034 §3/A-034-008.
- **DEC-035-009** [herdada] Alvo de p95 de 1.500 ms para o volume de referência de 200
  Conteúdos × 50 eventos — fonte: SPEC-034 NFR-034-002/A-034-010 ("o PLAN decide o
  mecanismo que o sustenta" — mecanismo em DEC-035-014/018).
- **DEC-035-010** [herdada] Identificadores de código em inglês; texto de interface em
  pt-BR — fonte: CLAUDE.md do workspace.

### DEC-035-011: Schema mínimo e correlação da contagem de páginas
**Contexto**: o Painel precisa saber, para cada Conteúdo, qual Exportação da Variante Tira
foi a primeira ocorrida depois do 1º fechamento de Versão — isto é, ordenar Exportações no
tempo lógico da fábrica (`sequence`), não pelo relógio (`occurredAt`).
**Decisão**: `PublicationEvent` ganha só `pageCount Int?`. A ordem de uma Exportação vem do
`ProductionStageEvent{PUBLICACAO_PDF}` irmão, casado por igualdade exata de
`(rawContentId, occurredAt)` — os dois são gravados com o mesmo `now`, na mesma
`$transaction`, desde F6 (`publication.service.ts`).
**Alternativas consideradas**:
- FK `productionStageEventId` em `PublicationEvent`, descartada porque exige
  `recordProductionStageEvent` devolver o `id` criado e todos os ~13 chamadores existentes
  (F3 a F9) mudarem para capturar esse retorno — superfície ampla para servir só este 4º
  consumidor.
- `sequence BigInt @default(autoincrement())` própria em `PublicationEvent`, descartada
  porque sequências de tabelas diferentes não são comparáveis entre si — não resolveria a
  pergunta real ("depois de qual `VERSAO_EDITORIAL`?"), só adicionaria uma coluna/índice sem
  uso na decisão.
**Consequências**: a correlação depende de `occurredAt` nunca colidir entre 2 exportações do
mesmo Conteúdo — verdadeiro hoje (mesmo `now`, mesma transação, 1 escrita por chamada).
**Reabrir se**: colisão de `occurredAt` entre 2 exportações do mesmo Conteúdo for observada
em produção, ou o evento de etapa e o de publicação deixarem de nascer na mesma transação.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-035-012: Falha de contagem de páginas não falha a Exportação
**Contexto**: FR-034-019/AC-034-022 exigem que uma falha ao contar páginas não impeça a
entrega do documento — hoje `getPageCount()` nunca é chamado, não há precedente no código.
**Decisão**: `countPagesForExport` envolve só a chamada de contagem em `try/catch`; falha
loga (sem texto de conteúdo) e devolve `null`. A composição do PDF em si (passos anteriores
de `composePublicationBuffer`) continua propagando exceção normalmente — são duas classes
de falha distintas, nunca a mesma captura.
**Alternativas consideradas**:
- Deixar a exceção de contagem propagar como as demais, descartada porque contraria
  FR-034-019 explicitamente (o requisito nomeia esta falha como não-bloqueante).
- Reagendar/recontar a página em outro ponto do fluxo, descartada por complexidade sem
  requisito que a peça (RISK-034-003 já aceita cobertura parcial permanente).
**Consequências**: uma exceção real de `pdf-lib` na contagem nunca aparece como erro 500 ao
cliente da Exportação — só como `pageCount: null` e uma linha de log.
**Reabrir se**: nunca — é a exigência explícita do FR.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-035-013: Leitura do Painel é factory-wide, sem `scopeWhere` por autoria
**Contexto**: toda leitura de `contents.service.ts` aplica `scopeWhere(actor)` (EDITOR só
alcança a própria autoria). O Painel agrega por Módulo (Tema) e por fábrica inteira
(FR-034-008/009), não por autor.
**Decisão**: `listActiveContentsForPanel` usa só `ACTIVE_RAW_CONTENT_WHERE` — nenhum filtro
de `authorId`. Um EDITOR e um ADMIN veem exatamente o mesmo retrato.
**Alternativas consideradas**:
- Aplicar `scopeWhere(actor)` como as demais leituras do módulo `contents`, descartada
  porque quebraria a Conclusão por Módulo e os agregados de fábrica (teriam que contar só
  os Conteúdos de um autor, número incompleto e incomparável entre EDITORes — a persona
  "conclusão do meu módulo" da SPEC se refere ao Tema como unidade, não à própria autoria).
**Consequências**: nenhum dado por-pessoa é exposto de qualquer forma (NFR-034-004
reforça isso pelo lado do `select`, não só pela ausência de filtro).
**Reabrir se**: uma SPEC futura pedir isolar o Painel por autor.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-035-014: Número fixo de consultas do módulo `strategic-panel`
**Contexto**: NFR-034-001 exige contagem de consultas constante, independente do total de
Conteúdos.
**Decisão**: número fixo de consultas por chamada de `buildStrategicPanel` — 7 statements
(Conteúdos ativos; eventos de etapa `IN`; publicações Tira `IN`; versões vigentes `IN` só com
chaves leves; e, só para os Conteúdos com Versão vigente aprovada, snapshot `id IN` + 2 `IN`
de dados atuais — ajuste pós-gate 10 da Wave 2: a coluna larga `contentSnapshot` sai da
leitura do histórico) — todo o cálculo
(tempo, agregados, backlog, prioridade, ordenação) roda em memória sobre o resultado, sem
nova ida ao banco por Conteúdo.
**Alternativas consideradas**:
- 1 consulta por Conteúdo (padrão N+1), descartada por violar NFR-034-001 diretamente.
- `groupBy`/agregação SQL no Postgres para médias/medianas, descartada nesta fatia: o
  volume de referência (200 Conteúdos × 50 eventos) cabe em memória sem custo medido que
  justifique a complexidade adicional (Art. 8 — medir antes de otimizar).
**Consequências**: o custo de CPU/memória do cálculo cresce com N no processo Node, não no
Postgres — trade-off aceito no volume de referência, revisitado por TRISK-035-003 se medido.
**Reabrir se**: volume real de Conteúdos/eventos ultrapassar o que a memória/tempo de
transporte do processo suportam (mesma condição de RISK-034-005/TRISK-010-002).
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-035-015: Predicado único de F9 extraído para função pura reusada em lote
**Contexto**: `resolveAlterationSignal` (F9) já é o único ponto de decisão de "alterado
pós-fechamento" para 3 usos (`approveContentVersion`, `listContentVersions`,
`resolveVersionStampForPdf`). O Painel precisa da mesma decisão para N Conteúdos de uma vez.
**Decisão**: extrair a parte pura da regra (`isVersionAltered`) para
`version-alteration.ts`; `resolveAlterationSignal` passa a só ler (`findFirst`) e delegar.
O Painel chama a mesma função pura, por Conteúdo, sobre dados já lidos em lote — vira o 4º
uso da MESMA regra, não uma cópia.
**Alternativas consideradas**:
- Duplicar a regra dentro do módulo do Painel, descartada: MAP F9 nomeia explicitamente
  "mudar a regra é mudar os 3 juntos" — duplicar criaria um 4º lugar que pode divergir
  silenciosamente na próxima mudança de F9.
- Painel chamar `resolveAlterationSignal` (a função com I/O) em loop, 1 vez por Conteúdo,
  descartada por reintroduzir N+1 e violar NFR-034-001.
**Consequências**: `resolveAlterationSignal` muda de forma interna, mas seu comportamento
observável (assinatura, retorno) não muda — os testes de F9 existentes continuam
passando sem alteração.
**Reabrir se**: nunca — extração sem mudança de comportamento. O gatilho a vigiar é o
oposto: uma mudança futura em `isVersionAltered` sem atualizar os 4 usos.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-035-016: Identificação mínima do Conteúdo sem campo de título
**Contexto**: `RawContent` não tem coluna de título (só `rawText`, o texto normativo
completo). AC-034-013/NFR-034-003 exigem identificação mínima (disciplina, tema,
título/identificador) sem nenhum campo de texto normativo.
**Decisão**: o payload do Painel identifica o Conteúdo por `id` (existente, opaco) mais
`disciplineName`/`topicName` — nunca um recorte de `rawText`.
**Alternativas consideradas**:
- Recorte truncado de `rawText` (ex.: primeiros N caracteres), descartada: um recorte
  continua sendo o próprio texto normativo, só mais curto — não atende à letra de
  NFR-034-003 ("0 campos de texto normativo").
- Introduzir um campo `title`/`slug` novo em `RawContent`, descartada: exigiria FR e UI de
  preenchimento que SPEC-034 não pediu — fora do escopo desta fatia (migração nova só para
  isso não tem requisito que a sustente).
**Consequências**: a tela identifica o item por Disciplina/Tema + um identificador opaco
(`id`) — sem trecho legível do conteúdo em si; aceitável para o backlog/métricas, cuja
navegação (link para `/content/:id`) é onde o texto real é lido, sob a guarda normal.
**Reabrir se**: uma SPEC futura introduzir um campo de título dedicado em `RawContent`.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-035-017: Rota do Painel — `GET` sem `verifyOrigin`, resposta por allowlist
**Contexto**: o projeto reserva `verifyOrigin` para mutação (padrão `tira.service.ts`
DEC-012-011); o Painel é só leitura. `NFR-034-003`/lição "select exposto que passa a ler
campo interno prova as chaves do payload" pedem que a serialização nunca espalhe o
resultado da camada de domínio direto na resposta HTTP.
**Decisão**: `GET /strategic-panel`, `requireRole('EDITOR', 'ADMIN')`, sem `verifyOrigin`
(mesmo padrão de toda outra rota `GET` do projeto). O handler monta o JSON de resposta
campo a campo, por allowlist explícita, nunca `res.json(payload)` direto do retorno de
`buildStrategicPanel`.
**Alternativas consideradas**:
- `res.json(payload)` direto, descartada: a função pura pode ganhar um campo novo (ex.: um
  cálculo intermediário de depuração) sem que a rota decida conscientemente expô-lo —
  histórico recente do próprio slug (F9, `contentSnapshot`) mostra esse vazamento
  acontecer por exatamente este atalho.
**Consequências**: toda evolução do payload interno exige tocar a rota para expor um campo
novo — fricção deliberada, não custo residual.
**Reabrir se**: nunca — a allowlist campo a campo é a prova de NFR-034-003; afrouxá-la reabre o vazamento que o NFR proíbe.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-035-018: Mecanismo de sustentação do p95 — sem cache/pré-computação nesta fatia
**Contexto**: NFR-034-002 pede p95 < 1.500 ms no volume de referência; o SPEC delega ao
PLAN "o mecanismo que o sustenta" (A-034-010).
**Decisão**: nenhuma camada de cache/pré-agregação nesta fatia — a garantia vem só do
número fixo de consultas (DEC-035-014) e do cálculo em memória sobre o volume de
referência; gate 10 mede o p95 real contra esse volume antes da Entrega.
**Alternativas consideradas**:
- Cache do resultado (recomputar a cada N minutos), descartada: sem medição que mostre
  necessidade, e introduziria staleness que a SPEC não pediu (o Painel mostra "o retrato
  corrente", §4.2 out-of-scope de SPEC-034 nomeia filtro temporal como fora de escopo — um
  retrato desatualizado é um risco de produto diferente, não avaliado).
- Tabela materializada/pré-agregação, descartada: complexidade de manutenção (job de
  refresh, invalidação) sem volume real que a justifique agora.
**Consequências**: se o gate 10 medir acima do alvo, a correção entra como ajuste
(cache/índice/paginação), não como reabertura de escopo desta DEC.
**Reabrir se**: gate 10 medir p95 acima do alvo no volume de referência, ou a fábrica se
aproximar do teto medido na Wave 3 (2026-09-30, gate 10): com agrupamento O(N+E), o p95 cruza
1.500 ms por volta de ~2.500 Conteúdos ativos (594 ms medidos em 1.000), e o corpo sem compressão
(~0,97 KiB por Conteúdo) chega ao limite de 4,5 MB de function da Vercel por volta de ~4.700
(RISK-025-007) — antes disso, paginação ou pré-agregação.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-035-019: RTK Query com `refetchOnMountOrArgChange`, sem tag de invalidação nova
**Contexto**: o Painel agrega dado de 4+ módulos (`contents`, `tira`/`production-events`,
`publication`, `content-versions`). Uma tag `StrategicPanel` invalidada por toda mutation
relevante exigiria que cada módulo futuro que mexe nesses dados se lembrasse de invalidar
um endpoint que não é o seu.
**Decisão**: `getStrategicPanel` refaz a leitura a cada visita à tela (implementado como
`forceRefetch: () => true` no endpoint — ajuste da Wave 4, a opção `refetchOnMountOrArgChange`
não existe por endpoint), sem depender de invalidação cruzada; exige 1 único subscriber por tela
(gate 10 da Wave 4: subscriber secundário que monta depois da resposta faz +1 GET).
**Alternativas consideradas**:
- Tag `StrategicPanel` invalidada por toda mutation de `RawContent`/`ContentVersion`/
  `PublicationEvent`, descartada: superfície de manutenção alta e frágil — mesma classe de
  risco da lição "campo calculado de outro recurso invalida a tag do endpoint que o
  exibe", aqui multiplicada por muitos recursos em vez de um só.
**Consequências**: toda montagem da tela dispara 1 GET novo — aceitável para uma home
visitada por navegação, não por polling.
**Reabrir se**: o refetch em toda montagem se mostrar caro/ruidoso em uso real medido.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-035-020: `INTERNAL_HOME` mantido; falha do Painel nunca vira boundary do Next
**Contexto**: AC-034-023 exige que uma falha na carga do Painel mostre o estado de falha
com "tentar novamente" **dentro** da home da área interna, nunca uma página de erro —
login/guard (`INTERNAL_HOME = '/studio'`) não podem regredir.
**Decisão**: `(interno)/studio/page.tsx` continua a rota-alvo do pós-login; vira casca
Server Component que sempre renderiza, delegando o estado de rede ao client component
(`strategic-panel-board.tsx`). Nenhum `error.tsx` de segmento é introduzido para este caso.
**Alternativas consideradas**:
- `error.tsx` do segmento `studio` capturando falha de rede do Painel, descartada: um
  error boundary do Next perde a ação de retry inline que FR-034-017/AC-034-023 exigem, e
  precisaria de `reset()` reimplementando o que o RTK Query já oferece via `refetch()`.
**Consequências**: nenhuma mudança em `internal-routes.ts`/`proxy.ts`/`login-form.tsx`.
**Reabrir se**: a página inicial da área interna deixar de ser o Painel (FR-034-018 revogado) ou o destino pós-login mudar de rota.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

## 8. Riscos técnicos

- **TRISK-035-001** Leitura de eventos de etapa não pagina (herdado de
  RISK-034-005/TRISK-010-002) — o Painel é o 1º consumidor real desse volume. (mitigação:
  aceito nesta fatia sob o volume de referência medido pelo gate 10; `Reabrir se`: volume
  real justificar paginação/particionamento, decisão de PLAN futuro)
- **TRISK-035-002** Correlação por `(rawContentId, occurredAt)` depende de os dois eventos
  nascerem sempre na mesma transação com o mesmo `now` (mesma condição de `Reabrir se` de
  DEC-035-011). (mitigação: nenhuma mudança nesta fatia toca `exportPublication` fora do
  campo `pageCount`; teste de integração cobre o caminho feliz e a ausência de correlação)
- **TRISK-035-003** O predicado de F9 em lote soma 2 consultas `IN` extras só para
  Conteúdos com Versão aprovada — cresce com a fração de Conteúdos aprovados, não com o
  total. (mitigação: medido pelo gate 10 no volume de referência; `Reabrir se`: a fração de
  aprovados dominar o custo total medido)
- **TRISK-035-004** Ambiente de gate 9 sem eventos reais (seed direto via Prisma não gera
  `ProductionStageEvent`, herdado de RISK-034-004) — o Painel aparece vazio/parcial até
  Conteúdos serem produzidos por rotas reais. (mitigação: roteiro de verificação de tela
  gera dado exercitando `POST`s reais antes de exercitar o Painel, nunca via seed)

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Aderência à ficha/perfil validada
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates)
- [ ] Métrica da SPEC operacional (§1.3, `Fonte de medição: instrumentação`): o próprio
  Painel exibindo tempo por página medido para ao menos 1 Conteúdo do módulo piloto
  (Obrigação Tributária) criado pelo fluxo instrumentado, e a cobertura (Conteúdos com
  medida / Conteúdos ativos) por Módulo e para a fábrica — gate 9 confirma o número
  existindo em tela real, com dado gerado por rotas reais (RISK-034-004/TRISK-035-004)

## 10. Não coberto por este PLAN

- Nenhum — este PLAN cobre a totalidade dos FRs/NFRs de SPEC-034 (Caso D).
