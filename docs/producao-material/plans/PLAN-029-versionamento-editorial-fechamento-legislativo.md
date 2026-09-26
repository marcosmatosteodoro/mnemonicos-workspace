# PLAN-029: Versionamento editorial e fechamento legislativo

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.2
**Autor**: scribe
**Data**: 2026-09-26

## Aderência a guidelines

**Decisões irreversíveis do slug tocadas**: nenhuma (INDEX.md §Decisões irreversíveis: "nenhuma — as 12 DECs de PLAN-003 são todas reversíveis").
**Decisões irreversíveis de outros slugs em conflito**: infra-vercel: sem bloco de decisões (`docs/infra-vercel/` não tem `INDEX.md` — nenhum arquivo a citar; nenhum outro slug existe neste workspace).
**Exceções aos guidelines**: nenhuma.

## Cobertura

**SPEC referenciada**: SPEC-028
**Slice declarado**: cobertura total restante (Caso D — nenhum `--covers`/`--slice`, todos os FRs/NFRs de SPEC-028 ainda não cobertos)

**FRs cobertos**:
- FR-028-001
- FR-028-002
- FR-028-003
- FR-028-004
- FR-028-005
- FR-028-006
- FR-028-007
- FR-028-008
- FR-028-009
- FR-028-010
- FR-028-011

**NFRs cobertos**:
- NFR-028-001
- NFR-028-002
- NFR-028-003

## 1. Visão técnica

Esta fatia (F8) acrescenta um registro append-only novo, `ContentVersion`, pendurado em
`RawContent` (N:1, mesma forma de `Contrast`/`ProductionFlashcard` de F7), e estende o
pipeline de exportação de PDF (F6) para estampar a Versão vigente em toda página.

O objeto versionado é recortado por **campo** (A-028-002 da SPEC), não por tabela: a
Versão editorial guarda um **snapshot JSON** dos campos versionados (`rawText`,
`radarClass`, `sourceType`, `sourceCitation`, `sourceUrl` de `RawContent` +
`concept`/`action`/`object`/`condition`/`exception`/`essence` de `RuleBreakdown`),
copiados integralmente no momento do fechamento em `contentSnapshot: Json`. A detecção de
"alterado após o fechamento" (FR-028-011) compara os campos ATUAIS de
`RawContent`/`RuleBreakdown` contra esse snapshot, campo a campo, por uma função pura sem
I/O (`hasVersionedContentChanged`) — sem necessidade de hash, nesta escala de dado. Esta é
a decisão arquitetural central desta fatia (DEC-029-003, irreversível) — resolve
RISK-028-001/A-028-004, deixados em aberto pela SPEC: capturar o texto agora preserva a
opção de reconstituí-lo depois (podar por retenção é reversível; não ter capturado, não
seria).

A escrita é estritamente append-only: nenhuma rota, nenhuma função de serviço e nenhum
campo do model `ContentVersion` permite `update`/`delete` — a imutabilidade é ausência de
caminho de escrita, não campo de estado (mesmo padrão de `ProductionStageEvent`, F3).
A concorrência de numeração (dois fechamentos simultâneos do mesmo `RawContent`) é
fechada por lock de linha do pai dentro da mesma transação (DEC-029-004, mesmo padrão de
`removeVisualAssociation`, F5).

No PDF (F6), a extensão é puramente aditiva: o cabeçalho de rascunho já desenhado em toda
página (`drawDraftHeader`) ganha uma linha a mais com a Versão vigente e a Data de
fechamento legislativo (ou a marca de ausência), coexistindo sem alterar o rótulo
"Rascunho" existente (FR-028-010).

No frontend, o histórico de Versões e o formulário de fechamento entram como um
componente novo, irmão de `ContentSupplementaryPanel` (F7) dentro do mesmo slot genérico
`supplementary` de `ContentForm` (DEC-029-007) — sem tocar a assinatura do formulário.

## 2. Stack e dependências

Stack herdado sem reescolha: Node 22 · Express 5 · Prisma 7 · PostgreSQL (backend, camadas
schema Zod → service → routes); Next 16 · React 19 · Redux Toolkit/RTK Query (frontend,
Server Components por padrão). Nenhuma dependência nova: a comparação de FR-028-011/
DEC-029-003 (`hasVersionedContentChanged`) é campo a campo em memória, sem biblioteca de
hash nem entrada nova em `package.json`. `pdf-lib` (motor de F6, DEC-025-001) é só
estendido, não trocado.

## 3. Componentes

### COMP-029-001: Migração — model `ContentVersion` + valor `VERSAO_EDITORIAL`
**Responsabilidade**: model Prisma novo `ContentVersion` (`id`, `rawContentId` → `RawContent`
`onDelete: Restrict` — mesmo padrão de `ProductionStageEvent`, bloqueia hard-delete do pai
enquanto houver Versão, RISK-028-005 citado; `number Int`; `legislativeClosureDate DateTime`;
`authorId` → `User` `onDelete: Restrict`; `closedAt DateTime @default(now())`;
`contentSnapshot Json`; `@@unique([rawContentId, number])` — cobre FR-028-001 (unicidade do
número) e NFR-028-003 (índice usado pela leitura ordenada); **sem** `updatedAt`/`deletedAt`,
por design (FR-028-004: a imutabilidade é ausência de coluna/caminho de update, não campo de
estado). Acrescenta `VERSAO_EDITORIAL` ao enum `ProductionStageType` (migração aditiva —
mesma mitigação já usada por `ASSOCIACAO_VISUAL`/`MATERIAL_REFORCO`: o valor só é referenciado
pelo código depois da migração aplicada; `vercel-build` roda `prisma migrate deploy` a cada
deploy do backend).
**Realiza**: FR-028-001, FR-028-004, FR-028-005, FR-028-007, NFR-028-001, NFR-028-003
**Interface pública**: model `ContentVersion` (Prisma Client gerado); enum
`ProductionStageType` com o valor novo.
**Dependências**: nenhuma

### COMP-029-002: `content-versions.schema.ts` (Zod)
**Responsabilidade**: schema de entrada do fechamento — `legislativeClosureDate` (data,
recusada se futura: `<= hoje`, comparação de DATA, não de timestamp — DEC-029-006); sem
campo de número, autor ou timestamp técnico no input (todos calculados/derivados no
service, nunca aceitos do cliente).
**Realiza**: FR-028-001
**Interface pública**: `closeContentVersionSchema` (Zod), tipo inferido
`CloseContentVersionInput`.
**Dependências**: nenhuma

### COMP-029-003: `content-versions.service.ts` — `hasVersionedContentChanged` (função pura)
**Responsabilidade**: função pura, sem I/O, que recebe os campos ATUAIS versionados de
`RawContent` (`rawText`, `radarClass`, `sourceType`, `sourceCitation`, `sourceUrl`) e de
`RuleBreakdown` (`concept`, `action`, `object`, `condition`, `exception`, `essence`) e o
`contentSnapshot` gravado na Versão vigente, e devolve `boolean` comparando campo a campo
(sem hash — comparação direta é exata e barata nesta escala de dado: textos curtos,
poucos fechamentos por Conteúdo bruto). Único ponto de manutenção quando o recorte de
A-028-002 mudar. Usada por COMP-029-004 (monta o snapshot no fechamento) e por
COMP-029-007 (compara na exportação).
**Realiza**: FR-028-001, FR-028-011
**Interface pública**: `hasVersionedContentChanged(current: VersionedContentFields,
snapshot: VersionedContentFields): boolean`
**Dependências**: nenhuma

### COMP-029-004: `content-versions.service.ts` — `closeContentVersion`
**Responsabilidade**: orquestra o fechamento dentro de uma `$transaction`: (1)
`tx.$queryRaw` `SELECT ... FOR UPDATE` trava a linha do `RawContent` pai antes de
qualquer decisão (DEC-029-004); (2) `assertRawContentReachable` (guarda de alcance,
DEC-029-001 herdada) + checagem explícita autor-ou-ADMIN pós-leitura (DEC-029-001); (3)
verifica que `RuleBreakdown` existe para aquele `rawContentId` — sem ela, recusa e
informa o motivo (FR-028-003); (4) calcula o próximo `number` sequencial (escopado ao
`rawContentId`, dentro da mesma linha travada); (5) monta o `contentSnapshot` copiando os
campos versionados atuais do par `RawContent`/`RuleBreakdown` lidos na mesma transação;
(6) `tx.contentVersion.create` com os 4 dados imutáveis + o snapshot; (7)
`recordProductionStageEvent(tx, { stageType:
'VERSAO_EDITORIAL', transitionType: 'CONCLUSAO', ... })` — sempre `CONCLUSAO` direto,
nunca via `decideStageTransition` (DEC-029-005). Qualquer falha em (2)-(6) propaga sem
gravar nada (fail-secure, NFR-028-001/002).
**Realiza**: FR-028-001, FR-028-002, FR-028-003, FR-028-004, FR-028-007, NFR-028-001,
NFR-028-002
**Interface pública**: `closeContentVersion(rawContentId: string, input:
CloseContentVersionInput, actor: ContentActor, db = prisma): Promise<ContentVersionDetail>`
**Dependências**: COMP-029-001, COMP-029-002, COMP-029-003

### COMP-029-005: `content-versions.service.ts` — `listContentVersions`
**Responsabilidade**: leitura do histórico completo de um `RawContent` — `
assertRawContentReachable` (DEC-029-002 herdada, mesma guarda comum de alcance, sem
restrição adicional por autoria de Versão) + `findMany` filtrado por `rawContentId`,
`orderBy: { number: 'asc' }` — o índice `@@unique([rawContentId, number])` (COMP-029-001)
garante que o custo depende só de `N` (Versões daquele `RawContent`), nunca do acervo
inteiro (NFR-028-003, AC-028-012).
**Realiza**: FR-028-005, NFR-028-003
**Interface pública**: `listContentVersions(rawContentId: string, actor: ContentActor, db =
prisma): Promise<ContentVersionDetail[]>`
**Dependências**: COMP-029-001

### COMP-029-006: `content-versions.routes.ts`
**Responsabilidade**: `POST /contents/:id/versions` (`verifyOrigin` como 1º handler +
`requireRole('EDITOR', 'ADMIN')`, montada em `apiRoutes`) chamando `closeContentVersion`;
`GET /contents/:id/versions` (`requireRole('EDITOR', 'ADMIN')`, sem `verifyOrigin` — regra
repo-wide de nunca exigi-lo em `GET`, mesmo raciocínio de DEC-012-011) chamando
`listContentVersions`. Handlers `async` sem `try/catch` (Express 5 encaminha rejeição ao
error handler central).
**Realiza**: FR-028-001, FR-028-002, FR-028-003, FR-028-005
**Interface pública**: `contentVersionsRoutes: Router`
**Dependências**: COMP-029-002, COMP-029-004, COMP-029-005

### COMP-029-007: Extensão de `publication.service.ts` — resolução da Versão vigente
**Responsabilidade**: dentro de `exportPublication`, busca a `ContentVersion` mais
recente (`orderBy: { number: 'desc' }, take: 1`) do `rawContentId` sendo exportado;
quando existe, chama `hasVersionedContentChanged` (COMP-029-003) comparando os campos
`RawContent`/`RuleBreakdown` **atuais** (já lidos nos passos existentes de
`exportPublication`) contra o `contentSnapshot` gravado na Versão — divergência
liga `alteredAfterClosure: true`, fail-secure (nunca falso negativo, A-028-012; falso
positivo tolerado quando o sinal for grosso demais para distinguir com precisão). Monta o
campo novo de `PublicationPdfMeta` (COMP-029-008) com `{ number, legislativeClosureDate,
alteredAfterClosure } | null` (`null` = nenhuma Versão fechada, FR-028-009). Requer
estender o `select` de `assertRawContentExportable` (hoje só `id`/`pegadinhaText`) para
incluir os campos versionados de `RawContent`.
**Realiza**: FR-028-008, FR-028-009, FR-028-011
**Interface pública**: função interna nova (ex. `resolveVersionStampForPdf`), sem rota
própria — chamada só por `exportPublication`.
**Dependências**: COMP-029-001, COMP-029-003

### COMP-029-008: Extensão de `pdf-composer.ts` — carimbo de Versão no cabeçalho
**Responsabilidade**: `PublicationPdfMeta` ganha o campo opcional
`version: VersionStampForPdf | null` (COMP-029-007). `drawDraftHeader`/`createPage`
(único ponto de desenho, chamado por `buildSummaryPdf`, `buildStripPdf` e
`drawSupplementarySection` — toda página nova) ganham uma 4ª linha: "Versão N — verificado
até DD/MM/AAAA" (FR-028-008) ou "sem versão" (FR-028-009) ou a mesma linha da Versão
vigente acrescida de "alterado após o fechamento da Versão N" (FR-028-011) — sempre ao
lado do rótulo "Rascunho" já existente, que segue desenhado sem alteração (FR-028-010).
A 4ª linha exige ampliar `MARGIN_TOP` (hoje 85, reservando 3 linhas) e recalibrar
`CONTENT_TOP_Y` na mesma constante — mudança centralizada, nunca duplicada nas 3 funções
de build (ver TRISK-029-003).
**Realiza**: FR-028-008, FR-028-009, FR-028-010, FR-028-011
**Interface pública**: `PublicationPdfMeta` estendida; `drawDraftHeader`/`createPage`
sem mudança de assinatura externa (mesmos chamadores).
**Dependências**: COMP-029-007

### COMP-029-009: Tipos espelhados — `ContentVersion` (backend + frontend)
**Responsabilidade**: interface `ContentVersion` em `mnemonicos-backend/src/domain/types.ts`
e em `mnemonicos-frontend/src/types/domain.ts` (mesmo par usado por `Contrast`/
`ProductionFlashcard`, F7) com os 4 dados imutáveis expostos para leitura (`id`, `number`,
`legislativeClosureDate`, `authorId`, `closedAt`) — **sem** `contentSnapshot` (dado interno
de verificação/histórico, nunca exposto à UI). `VERSAO_EDITORIAL` (valor do enum `ProductionStageType`)
fica **backend-only**, sem espelho — mesmo padrão de `PRODUCTION_STAGE_TYPES`
(DEC-010-006/YAGNI): nenhuma tela consome o enum de etapa diretamente.
**Realiza**: FR-028-005, FR-028-006, NFR-028-001
**Interface pública**: `interface ContentVersion { id; rawContentId; number;
legislativeClosureDate; authorId; closedAt }` (tipos de data como `string` no frontend,
`Date` no backend — mesma convenção já usada pelos outros espelhos deste slug).
**Dependências**: COMP-029-001

### COMP-029-010: `store/api.ts` — mutation e query de Versão
**Responsabilidade**: `closeContentVersion` (mutation, `invalidatesTags: ['ContentVersion']`)
e `listContentVersions` (query, `providesTags: ['ContentVersion']`) — mesmo par
mutation/query com tag dedicada já usado por `Contrast`/`ProductionFlashcard` (F7). Sem
invalidar `'RawContent'`: o fechamento não altera nenhum campo do `RawContent` (o "Carimbo
de última alteração" de SPEC-005 não é tocado por este ato, A-028-001).
**Realiza**: FR-028-001, FR-028-005, FR-028-006
**Interface pública**: `useCloseContentVersionMutation`, `useListContentVersionsQuery`
**Dependências**: COMP-029-006, COMP-029-009

### COMP-029-011: `content-version-history.tsx` (novo)
**Responsabilidade**: client component com formulário de fechamento (campo de Data de
fechamento legislativo, botão "Fechar versão" com os 3 estados observáveis de FR-028-006 —
em andamento/sucesso/falha, mesmo padrão de estado dos outros formulários do slug) e lista
do histórico (Versões em ordem, cada uma com número/data/autor/timestamp). Consome
`useListContentVersionsQuery`/`useCloseContentVersionMutation` (COMP-029-010).
**Realiza**: FR-028-006, FR-028-005
**Interface pública**: `<ContentVersionHistory rawContentId={string} />`
**Dependências**: COMP-029-009, COMP-029-010

### COMP-029-012: `content/[id]/page.tsx` — wiring do slot `supplementary`
**Responsabilidade**: passa `content-version-history` como **irmão** de
`ContentSupplementaryPanel` dentro do mesmo slot `supplementary?: ReactNode` de
`ContentForm` (via `<>...</>`), sem alterar a assinatura do slot (DEC-029-007) — fecha, já
na largada desta fatia, o mesmo tipo de furo que F7 só achou na convergência de fecho
(nenhuma TASK deixa o componente novo sem página que o monte).
**Realiza**: FR-028-005, FR-028-006
**Interface pública**: nenhuma (wiring de página, Server Component)
**Dependências**: COMP-029-011

### COMP-029-013: `route-authz-matrix.integration.test.ts` — tripwire +2
**Responsabilidade**: as 2 rotas novas (`POST`/`GET /contents/:id/versions`) entram no
censo de `collectRoutes(apiRoutes)` automaticamente (a suíte deriva do array montado, não
de uma contagem hardcoded) — confirma que as 2 seguem a barreira deny-by-default
(EDITOR/ADMIN, 401 sem sessão, 403 com papel insuficiente) igual a toda rota não-pública
do módulo.
**Realiza**: FR-028-002, NFR-028-002
**Interface pública**: nenhuma (suíte de teste)
**Dependências**: COMP-029-006

### COMP-029-014: `contents-frontend-contract.test.ts` — paridade `ContentVersion`
**Responsabilidade**: novo bloco `describe('paridade cross-repo — ContentVersion')`,
mesma forma dos blocos existentes de `Contrast`/`ProductionFlashcard` (`extractInterfaceFields`,
não os 3 extratores de `domain-types-parity.test.ts` — const array/enum Prisma/chaves de
Record não cobrem interface de campos; a comparação DECLARAÇÃO×DECLARAÇÃO de interface já
mora neste arquivo, não naquele, confirmado por leitura direta dos dois arquivos):
compara `domain/types.ts::ContentVersion` (backend) × `types/domain.ts::ContentVersion`
(frontend), e o tipo de retorno real do service (`ContentVersionDetail`,
`content-versions.service.ts`) × `types/domain.ts::ContentVersion` — mesmo par duplo já
aplicado a `Contrast`/`ContrastDetail`.
**Realiza**: FR-028-005, NFR-028-001
**Interface pública**: nenhuma (suíte de teste)
**Dependências**: COMP-029-009

## 4. Fluxos principais

**Fluxo 1 — Fechamento de Versão (feliz, AC-028-001/002)**: EDITOR/ADMIN aciona "Fechar
versão" na tela → `POST /contents/:id/versions` (`legislativeClosureDate`) →
`verifyOrigin` → `requireRole` → Zod (recusa data futura) → `closeContentVersion`:
`SELECT...FOR UPDATE` no `RawContent` pai → guarda de alcance + autor-ou-ADMIN →
`RuleBreakdown` existe → próximo `number` → monta `contentSnapshot` com os campos atuais →
`INSERT ContentVersion` → `recordProductionStageEvent` (`VERSAO_EDITORIAL`/`CONCLUSAO`) → commit
→ 201 → UI mostra sucesso e a Versão nova aparece no histórico (`invalidatesTags`).

**Fluxo 2 — Recusa (AC-028-003/004/005)**: EDITOR B (não-autor, não-ADMIN) tentando
fechar Versão do `RawContent` do EDITOR A é barrado já por `assertRawContentReachable`
(`scopeWhere` restringe o alcance de EDITOR ao próprio `authorId`) — mesma mensagem
genérica de "não encontrado" da leitura comum do slug, nunca 403 que revele existência
(NFR-028-002); `RawContent` sem `RuleBreakdown` salva ou soft-deleted é recusado com o
motivo específico (FR-028-003), sem `INSERT`, dentro da mesma transação (exceção antes do
`create` equivale a rollback).

**Fluxo 3 — Leitura do histórico (AC-028-001/002/012)**: `GET /contents/:id/versions` →
`requireRole` (sem `verifyOrigin`) → `listContentVersions`: guarda de alcance comum (sem
restrição por autoria de Versão) → `findMany` por `rawContentId`, `orderBy: { number:
'asc' }`, servido pelo índice único — custo depende só de `N`.

**Fluxo 4 — Exportação com/sem Versão vigente (AC-028-009/010/011/013)**:
`exportPublication` (F6) já lê `RawContent`+`RuleBreakdown` → COMP-029-007 busca a
`ContentVersion` mais recente do mesmo `rawContentId` → existe: compara o estado ATUAL do
par contra o `contentSnapshot` gravado (`hasVersionedContentChanged`) → `alteredAfterClosure` → COMP-029-008
desenha, em toda página, "Versão N — verificado até DD/MM/AAAA" (+ marca de alteração
quando aplicável) ao lado do rótulo "Rascunho" inalterado; não existe nenhuma Versão:
desenha "sem versão" no mesmo local.

## 5. Modelo de dados

```prisma
model ContentVersion {
  id String @id @default(uuid(7))

  rawContentId String
  rawContent   RawContent @relation(fields: [rawContentId], references: [id], onDelete: Restrict)

  number Int

  legislativeClosureDate DateTime

  authorId String
  author   User @relation(fields: [authorId], references: [id], onDelete: Restrict)

  closedAt DateTime @default(now())

  /// Copia integral dos campos versionados de RawContent + RuleBreakdown no momento do
  /// fechamento (DEC-029-003) — nunca exposto à UI.
  contentSnapshot Json

  @@unique([rawContentId, number])
  @@map("content_versions")
}
```

Sem `updatedAt`/`deletedAt` (FR-028-004) — mesma forma de `ProductionStageEvent` (F3):
imutabilidade é ausência de coluna e de caminho de escrita, não estado marcado. Enum
`ProductionStageType` ganha `VERSAO_EDITORIAL` (migração aditiva). Migração 100% aditiva
(1 `CREATE TABLE`, 1 `ADD VALUE`, sem `DROP`/`ALTER` destrutivo) — mesmo protocolo de
aplicação de F6/F7 (autorização do Diretor para dev; produção via `vercel-build` +
`prisma migrate deploy` a cada deploy).

## 6. Decisões arquiteturais

### Decisões herdadas
- **DEC-029-001** [herdada] Guarda de criação da Versão: `assertRawContentReachable`
  (guarda de alcance por autoria, exportada por `contents.service.ts`) + checagem
  explícita `actor.role === 'ADMIN' || rawContent.authorId === actor.id` pós-leitura, com
  `ForbiddenError` na recusa — fonte: precedente de código F7 (`contrasts.service.ts:131-173`) /
  SPEC-028 A-028-007.
- **DEC-029-002** [herdada] Leitura do histórico de Versões usa a MESMA guarda de alcance
  do `RawContent` pai (`assertRawContentReachable`), sem restrição adicional por autoria —
  fonte: precedente de código F7 (leitura comum de Contraste/Flashcard/Pegadinha,
  RISK-027-007).

### DEC-029-003: Versão editorial guarda SNAPSHOT dos campos versionados, não só hash

**Contexto**: SPEC-028 exclui do escopo a reprodução fiel do texto de uma Versão que não
seja a mais recente (§4.2) — mas isso é o que a SPEC NÃO EXIGE agora, não uma proibição
de guardar o dado. A escolha entre capturar o texto agora (podar depois se sobrar volume
demais — reversível) e não capturar (perder para sempre o texto de uma Versão cujo
Conteúdo bruto/Quebra da regra mudou depois — irreversível) é a decisão real desta DEC
(A-028-004 do SPEC-028 já apontava essa escolha como irreversível). FR-028-011 exige
detectar, de forma fail-secure, quando o texto foi alterado depois do fechamento da
Versão vigente.

**Decisão**: `ContentVersion` grava um campo `contentSnapshot: Json`, cópia integral dos
campos versionados no momento do fechamento — `rawText`, `radarClass`, `sourceType`,
`sourceCitation`, `sourceUrl` (de `RawContent`) e `concept`, `action`, `object`,
`condition`, `exception`, `essence` (de `RuleBreakdown`), serializados como objeto JSON
único. A detecção de FR-028-011 compara os campos ATUAIS de `RawContent`/`RuleBreakdown`
contra o `contentSnapshot` da Versão vigente, campo a campo (função pura
`hasVersionedContentChanged(current, snapshot)`, sem I/O) — sem necessidade de hash: a
comparação direta já é exata e simples nesta escala de dado (textos curtos, poucos
fechamentos esperados por Conteúdo bruto).

**Alternativas consideradas**:
- Hash SHA-256 sem cópia de texto (decisão original desta DEC, revertida): detecta
  MUDANÇA mas não preserva O QUE havia antes — se o texto mudar depois do fechamento,
  o conteúdo da Versão antiga desaparece para sempre, mesmo que uma decisão futura do
  Diretor precise dele. Descartada porque é a direção NÃO reversível: podar um snapshot
  já guardado é fácil (migração simples, decisão de retenção); reconstruir um texto que
  nunca foi copiado é impossível.
- Referência pura sem hash nem cópia, descartada pelo mesmo motivo, agravado (nem
  detecta mudança nem preserva texto).
- Campos separados (uma coluna por campo versionado) em vez de `Json` único, descartada
  por custo de manutenção (11 colunas novas vs. 1) sem ganho de consulta — nenhum
  requisito exige buscar por campo individual do snapshot.

**Consequências**: cada fechamento de Versão copia o texto vigente para a linha nova —
custo de armazenamento cresce com o número de fechamentos (aceito nesta fatia, A-028-011
permite fechamentos sucessivos sem exigir mudança real; RISK-029 novo abaixo nomeia o
crescimento sem teto). Ganho: nenhuma perda de informação histórica, mesmo que o volume
condicione uma poda futura — a poda é decisão reversível, a falta de captura não seria.
**Reabrir se**: volume real de armazenamento (medido) justificar poda — reter só as N
versões mais recentes com snapshot completo e as demais só com data/autor/número (sem
texto), ou migrar para hash-only a partir de um corte — ambas as direções são migrações
de REMOÇÃO de dado já existente, não de invenção de dado perdido.
**Irreversível**: sim
**Aderência à ficha/perfil**: nova

### DEC-029-004: Lock de linha do `RawContent` pai fecha a corrida de numeração
**Contexto**: FR-028-001 exige numeração sequencial correta por `RawContent` mesmo sob
fechamentos concorrentes (2 EDITORES/ADMIN fechando ao mesmo tempo o mesmo Conteúdo
bruto).
**Decisão**: dentro da mesma `$transaction` do fechamento, `tx.$queryRaw` `SELECT ... FOR
UPDATE` trava a linha do `RawContent` pai ANTES de calcular o próximo número e inserir a
Versão — mesmo padrão já usado por `removeVisualAssociation` (F5) para fechar corrida real
sob READ COMMITTED.
**Alternativas consideradas**:
- Confiar só na constraint `@@unique([rawContentId, number])` + retry em `P2002`,
  descartada porque reintroduz lógica de retry explícita sem necessidade, quando o lock de
  linha já serializa na largada.
**Consequências**: toda chamada de `closeContentVersion` paga 1 `SELECT FOR UPDATE` extra
(custo desprezível, já pago pelo precedente de F5); fechamentos concorrentes no mesmo
`RawContent` serializam (aceito, RISK-002-001).
**Reabrir se**: fechamentos concorrentes no mesmo Conteúdo bruto se tornarem frequentes o
bastante para o lock virar gargalo medido (hoje aceito, operação de poucas pessoas).
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-029-005: Evento de etapa sempre `CONCLUSAO` direto, sem `decideStageTransition`
**Contexto**: `recordProductionStageEvent`/`decideStageTransition` (F3) decidem
ABERTURA/CONCLUSAO/RETRABALHO a partir de histórico de EDIÇÃO em estágios de Conteúdo
bruto/Quebra da regra — Versão editorial não tem esse ciclo: cada fechamento já é um ato
atômico e definitivo (FR-028-004).
**Decisão**: o fechamento de Versão emite o evento (`stageType: 'VERSAO_EDITORIAL'`)
sempre como `transitionType: 'CONCLUSAO'` direto, chamando `recordProductionStageEvent`
diretamente — nunca via `decideStageTransition`.
**Alternativas consideradas**:
- Reusar `decideStageTransition` genericamente, descartada porque pressupõe um ciclo
  "abrir→editar→concluir" que Versão não tem, e forçaria a função pura existente a lidar
  com um caso que nunca terá ABERTURA nem RETRABALHO, sem necessidade.
**Consequências**: o histórico de eventos de `VERSAO_EDITORIAL` sempre mostra só
`CONCLUSAO` — consistente com o requisito de ato atômico (FR-028-004/007).
**Reabrir se**: uma fatia futura introduzir um estado de "rascunho de fechamento" em
progresso.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-029-006: Data de fechamento legislativo — recusa futura, sem monotonicidade
**Contexto**: FR-028-001 exige registrar a Data de fechamento legislativo declarada pelo
ator; A-028-011 permite fechamentos sucessivos sem exigir mudança real de texto, o que
inclui o cenário de corrigir um erro de digitação de data de um fechamento anterior.
**Decisão**: o schema Zod de entrada recusa datas FUTURAS (`<= hoje`, comparação de DATA,
não de timestamp) e **não** valida monotonicidade entre Versões sucessivas — uma Versão
nova pode declarar data de fechamento anterior à da Versão anterior.
**Alternativas consideradas**:
- Exigir monotonicidade crescente entre Versões, descartada porque nenhum requisito da
  SPEC pede isso e bloquearia uma correção legítima de data digitada errado numa Versão
  anterior.
**Consequências**: o histórico ordenado por `number` (FR-028-005) não implica ordem
cronológica das datas declaradas — quem lê o histórico precisa estar ciente disso.
**Reabrir se**: o piloto (PIL-001) reportar confusão real com datas não-monotônicas.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-029-007: Frontend — histórico/formulário de Versão como irmãos de `ContentSupplementaryPanel`
**Contexto**: `ContentForm` expõe um único slot genérico `supplementary?: ReactNode`
(`content-form.tsx:44-57/501`), hoje ocupado só por `ContentSupplementaryPanel` (F7); o
histórico de Versões e o formulário de fechamento são um concern diferente (conteúdo
normativo primário × material de reforço que ele não versiona, A-028-002).
**Decisão**: `content-version-history.tsx` é renderizado como IRMÃO de
`ContentSupplementaryPanel`, dentro do MESMO slot `supplementary` (via `<>...</>`), nunca
aninhado dentro de `ContentSupplementaryPanel`.
**Alternativas consideradas**:
- Aninhar como mais uma `<section>` dentro de `ContentSupplementaryPanel`, descartada
  porque misturaria, no mesmo componente, o versionamento do conteúdo primário com o
  material de reforço que ele não versiona — risco de confundir a leitura de escopo mais
  tarde.
**Consequências**: `content/[id]/page.tsx` passa um `Fragment` com os 2 componentes ao
slot; nenhuma mudança na assinatura de `ContentForm`.
**Reabrir se**: o produto decidir unificar a área "meta-informação do Conteúdo bruto" num
único painel.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

## 8. Riscos técnicos

- **TRISK-029-001** Sem teto de cadência entre fechamentos (herdado de RISK-028-003 da
  SPEC, A-028-011), o histórico pode acumular Versões sem mudança real de texto,
  poluindo o que a Versão vigente comunica ao leitor do PDF (mitigação: aceito nesta
  fatia, mesma postura de RISK-011-005/RISK-002-001; revisitar se o piloto PIL-001
  reportar ruído real).
- **TRISK-029-002** Acoplamento novo entre `content-versions.service.ts` (dono de
  `hasVersionedContentChanged`) e `publication.service.ts` (consumidor, FR-028-011)
  (mitigação: dependência unidirecional — `publication` importa de `content-versions`,
  nunca o contrário —, função pura sem I/O, sem ciclo de módulo).
- **TRISK-029-003** A 4ª linha do cabeçalho de rascunho (COMP-029-008) reduz a área útil
  de conteúdo por página (`CONTENT_TOP_Y` depende de `MARGIN_TOP`) e precisa da MESMA
  calibragem nas 3 funções de composição (`buildSummaryPdf`/`buildStripPdf`/
  `drawSupplementarySection`) (mitigação: mudança centralizada em `drawDraftHeader`/
  `createPage`, único ponto de desenho hoje chamado pelas 3 — provado por geração real
  de PDF nos 2 cenários, AC-028-009/010/013).
- **TRISK-029-004** Expurgo físico futuro de `RawContent`, em cascata, apagaria Versões
  editoriais, contradizendo o requisito de append-only (FR-028-004) — herdado de
  RISK-028-005 da SPEC (mitigação atual: `onDelete: Restrict` na FK `rawContentId` de
  `ContentVersion`, mesmo padrão de `ProductionStageEvent`, bloqueia hard-delete do pai
  enquanto houver Versão; não é solução definitiva — a fatia que definir expurgo
  precisa resolver o destino das Versões antes de agir).
- **TRISK-029-005** Leitura do histórico (`listContentVersions`, sem lock) concorrente com
  um `closeContentVersion` em andamento no mesmo `RawContent` — sob READ COMMITTED, a
  leitura só enxerga a nova Versão após o commit (nunca dado parcial), então não é uma
  corrida real; citado para registro (mesma postura de leitura comum sem lock de
  `listContrasts`/`listVisualAssociations`).
- **TRISK-029-006** Sem teto de retenção, o armazenamento de `ContentVersion.contentSnapshot`
  cresce sem limite com fechamentos sucessivos (A-028-011 não exige mudança real de texto
  entre eles) — aceito nesta fatia; revisitar se o piloto (PIL-001) ou medição real de
  armazenamento em produção justificar poda (ver Reabrir se de DEC-029-003).

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Aderência à ficha/perfil validada
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates)
- [ ] Métrica da SPEC operacional (§1.3, `Fonte de medição: instrumentação`): consulta
  cruzando `PublicationEvent` (F6, `rawContentId`/`occurredAt`) com a existência de
  `ContentVersion` do mesmo `rawContentId` fechada até a data da exportação
  (`ContentVersion.closedAt <= PublicationEvent.occurredAt`) — e, para excluir do
  numerador as exportações com a marca "alterado após o fechamento" (FR-028-011/A-028-012,
  §1.3), cruzando também `ProductionStageEvent` (`stageType` `CONTEUDO_BRUTO`/
  `QUEBRA_DA_REGRA`, já append-only desde F3) por `rawContentId`/`occurredAt` para
  detectar edição ocorrida ENTRE o `closedAt` da Versão vigente e o `occurredAt` da
  exportação (equivalente retroativo do sinal de alteração — a comparação contra o
  `contentSnapshot` só reflete o estado ATUAL, não o estado no momento de uma exportação
  passada, por isso a consulta retroativa usa o log de eventos, não o snapshot). As 3
  tabelas fonte já existem ao
  fim deste PLAN (nenhuma instrumentação nova além de `ContentVersion`, COMP-029-001) —
  consulta executável contra o schema real, mesmo padrão de F6/F7. Dono: time de
  engenharia.

## 10. Não coberto por este PLAN

- Gate de aprovação/QC jurídico e o que isso implica sobre liberar ou bloquear a
  Exportação (F9) — fora de escopo (SPEC-028 §4.2).
- Qualquer cálculo ou alerta de vencimento/expiração de legislação — a Data de fechamento
  legislativo é só a data declarada, sem prazo calculado (SPEC-028 §4.2).
- Edição ou remoção de uma Versão editorial já fechada, por qualquer papel incluindo
  ADMIN (SPEC-028 §4.2, FR-028-004).
- Reprodução fiel do texto (Conteúdo bruto/Quebra da regra) de uma Versão que não seja a
  mais recente fechada — decisão resolvida acima (DEC-029-003) como fora de escopo desta
  fatia (SPEC-028 §4.2).
- Versionamento de Contraste, Pegadinha elaborada ou Flashcard (F7) e de Tira mnemônica ou
  Associação visual (F4/F5) — SPEC-028 §4.2.
- Qualquer tela, rota ou fluxo consumido pelo papel STUDENT (SPEC-028 §4.2).
- Painel estratégico e métricas de tempo por página (F10); fila e calendário editorial
  (F11) (SPEC-028 §4.2).
- Expurgo ou migração do modelo `Mnemonic` legado dormente (RISK-011-001/RISK-005-004) —
  segue em aberto, não revisitado por esta fatia (SPEC-028 §4.2).
- Expurgo físico e restauração (rota ou UI) de Conteúdo bruto removido de forma reversível
  (SPEC-028 §4.2).
