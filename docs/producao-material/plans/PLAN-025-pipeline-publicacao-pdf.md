# PLAN-025: Pipeline de publicação — PDF (rascunho)

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.1
**Autor**: keelson (scribe)
**Data**: 2026-09-14

## Aderência a guidelines

**Ficha/perfil de linguagem**: backend `node-22.md` (Node 22 + TypeScript 6, Express 5,
Prisma 7, Zod 4, Jest 30) ativo; frontend `next-16.md` (Next 16, React 19, RTK Query,
Tailwind 4) ativo.
**Stack vigente herdado**: Express 5 + Prisma 7 (`@prisma/adapter-pg`) + Zod 4 no backend;
Next 16 (App Router) + React 19 + Redux Toolkit/RTK Query + Tailwind 4 no frontend; Jest 30
+ `supertest` para integração; Postgres real (`mnemonicos_test`) para teste com banco.
Única peça de stack nova é a dependência declarada em DEC-025-001 (`pdf-lib`).
**Padrão arquitetural seguido**: módulo novo por domínio, schema→service→routes (backend,
mesmo padrão de `tira`/`contents`/`visual-associations`) — `publication` importa de
`contents.service`, `tira.service` e `visual-associations.service` (nunca o inverso, mesma
direção de dependência de módulo do perfil, precedente DEC-023-009); reusa componentes
client já existentes no frontend (`ContentForm`, `MnemonicStripBoard`) via um componente
reusável novo.
**Decisões irreversíveis do slug tocadas**: nenhuma (`INDEX.md` atual: "nenhuma — as 12 DECs
de PLAN-003 são todas reversíveis").
**Decisões irreversíveis de outros slugs em conflito**: nenhuma — `{docsRoot}` só tem o
slug `producao-material` (confirmado por `docs/*/INDEX.md`).
**Exceções aos guidelines**: nenhuma.

## Cobertura

**SPEC referenciada**: SPEC-024
**Slice declarado**: cobertura total restante — Caso D (nenhum `--covers`/`--slice`
declarado), SPEC-024 sem PLAN anterior.

**FRs cobertos**:
- FR-024-001
- FR-024-002
- FR-024-003
- FR-024-004
- FR-024-005
- FR-024-006
- FR-024-007
- FR-024-008
- FR-024-009
- FR-024-010
- FR-024-011
- FR-024-012
- FR-024-013
- FR-024-014
- FR-024-015
- FR-024-016

**NFRs cobertos**:
- NFR-024-001
- NFR-024-002
- NFR-024-003
- NFR-024-004

**Cobertura agregada do slug**:
- Total na SPEC: 16 FRs + 4 NFRs
- Cobertos por planos anteriores: 0 FRs + 0 NFRs (SPEC-024 não tem PLAN anterior)
- Cobertos por este: 16 FRs + 4 NFRs
- Gap restante: 0
- Funcionalidades cobertas: SPEC-024 não declara FEATs (mesmo padrão de SPEC-009/SPEC-019)

## 1. Visão técnica

F6 introduz uma superfície nova no backend — módulo próprio `publication`
(`src/modules/publication/`, schema→service→routes) — que ORQUESTRA três módulos já
entregues sem alterar o contrato público de nenhum deles: lê o Conteúdo bruto e a Quebra da
regra (F2, `contents.service.ts`), lê ou auto-gera a Tira mnemônica (F4, `tira.service.ts`,
`openMnemonicStrip`) e lê o binário de cada Associação visual vinculada (F5,
`visual-associations.service.ts`, `getVisualAssociationBinary`) — greenfield total de PDF
confirmado pelo `code-scout` (nenhuma dependência de PDF/HTML-to-PDF/headless browser em
nenhum dos dois repos hoje).

O motor de composição é `pdf-lib` (DEC-025-001) — biblioteca pura JS/TS, sem processo
externo nem dependência nativa/WASM, que desenha por coordenada (texto/imagem) em vez de
interpretar um template/HTML. Essa escolha não é só de conveniência: **elimina por
construção** as duas superfícies que NFR-024-001/002 pedem para mitigar (SSRF — nenhum
processo/rede envolvido na renderização; injeção — não existe camada de marcação
interpretável entre o texto do usuário e a página, `drawText` desenha a string literal) e
respeita o teto DURO de `mnemonicos-backend/vercel.json` (`maxDuration: 15`/`memory: 1024`)
sem o cold-start de um motor baseado em browser headless.

**Premissa desta execução, marcada `[assumido]`** (A-025-001, evidência: conflito entre um
AC da SPEC e o mecanismo real herdado, achado próprio deste PLAN): AC-024-018 exige alcance
de exportação "comum a EDITOR/ADMIN, herdado de F4/F5, sem restrição adicional por
autoria" — mas o mecanismo REAL herdado (`assertRawContentReachable`, usado também dentro de
`openMnemonicStrip`) restringe EDITOR à PRÓPRIA autoria em F2/F4/F5, sem exceção nenhuma
hoje (ADMIN irrestrito). Este PLAN resolve a tensão assim (DEC-025-007): a LEITURA de
material já existente (Quebra salva, Tira já aberta, binário de Associação visual) usa uma
guarda nova, comum a todo EDITOR/ADMIN (sem checagem de autoria) — satisfaz AC-024-018 para
exportar "resumo" e "tira" já aberta de Conteúdo bruto de qualquer autor; a AUTO-GERAÇÃO da
Tira (FR-024-006, quando ainda não existe) continua delegada a `openMnemonicStrip`
**sem nenhuma mudança na guarda dele** — logo, exportar "tira" ainda não aberta de um
Conteúdo bruto de OUTRO autor recusa com o MESMO comportamento herdado de
`assertStripPrerequisites`/`assertRawContentReachable`: **404, `NotFoundError`,
"Conteúdo bruto não encontrado."** (não 409/`ConflictError` — corrigido após medição real
na implementação de TASK-025-008, Wave 3; o texto anterior desta seção presumia um
código de status que a guarda de F4 nunca usou), até que o autor ou um ADMIN a abram.
Este caso específico (auto-geração + não-autor) não é testado literalmente por nenhum AC
da SPEC — sinalizado em `duvidas` deste sumário.

## 2. Stack e dependências

- **Backend (herdado, sem mudança)**: Express 5, Prisma 7 (`@prisma/adapter-pg`), Zod 4,
  Jest 30 + `supertest`, `pino`/`pino-http`, `helmet`.
- **Backend (dependência nova)**: `pdf-lib` (DEC-025-001) — sem dependência nativa/WASM,
  API de baixo nível (`PDFDocument.create()`, `addPage()`, `drawText()`, `embedJpg()`/
  `embedPng()`). Entra sujeita a `/keelson:audit`/gate 8 (TRISK-025-002).
- **Backend (nativo, sem dependência nova)**: `setTimeout`/`Promise.race` para o teto de
  duração interno (DEC-025-002) — nenhuma lib de timeout.
- **Frontend**: nenhuma dependência nova — `Blob`/`URL.createObjectURL` nativos do browser
  para o download (DEC-025-006); RTK Query já cobre a chamada HTTP.
- **Variáveis de ambiente novas** (backend, `src/config/env.ts`, mesmo padrão de
  `VISUAL_ASSOCIATIONS_MAX_FILE_SIZE_BYTES`): `PUBLICATION_PDF_TIMEOUT_MS` (default `12000`
  — 3 s de folga sob o teto duro de 15000 ms do `vercel.json`, DEC-025-002). Entra em
  `.env.example` e em `tests/setup-env.ts` com valor fictício.

## 3. Componentes

### COMP-025-001: `publication.schema.ts` — validação de entrada (Zod)
**Responsabilidade**: schema do corpo de `POST /contents/:id/publication` (`variant`) e do
param `:id`. `variant` usa o MESMO vocabulário maiúsculo dos demais enums de domínio do
projeto (`ProofRadarClass`, `NormativeSourceType`) — `'TIRA' | 'RESUMO'` — nunca as palavras
em minúsculo da prosa da SPEC, mantendo o mesmo idioma de wire dos outros contratos
(rótulo pt-BR fica só na camada de apresentação do frontend, COMP-025-009).
**Realiza**: nenhum diretamente — schema de validação consumido por COMP-025-006
**Interface pública**:
```ts
export const exportPublicationParamsSchema = z.object({
  id: z.uuid('Identificador de conteúdo bruto inválido.'),
});

export const exportPublicationBodySchema = z.object({
  variant: z.enum(['TIRA', 'RESUMO']),
});
export type ExportPublicationBodyInput = z.infer<typeof exportPublicationBodySchema>;
```
**Dependências**: nenhuma

### COMP-025-002: `pdf-layout.ts` — medição e quebra de linha (função pura)
**Responsabilidade**: `pdf-lib` não faz *word-wrap* automático — esta função pura calcula,
a partir da largura de cada palavra (`font.widthOfTextAtSize`) e de uma largura máxima em
pontos, as linhas em que um texto livre deve ser quebrado para caber na página. Sem I/O
(recebe a fonte já embutida e os parâmetros de layout por argumento, mesmo espírito de
`buildInitialFrames`/`decideStageTransition`) — testável sem gerar PDF nenhum.
**Realiza**: nenhum diretamente — utilitário de composição consumido por COMP-025-003
**Interface pública**:
```ts
export function wrapTextToLines(
  text: string,
  maxWidthPt: number,
  measureWidth: (word: string) => number,
): string[];
```
**Dependências**: nenhuma

### COMP-025-003: `pdf-composer.ts` — composição do documento (motor `pdf-lib`)
**Responsabilidade**: as duas funções de composição — `buildSummaryPdf` (Variante "resumo",
FR-024-003/A-024-006: texto corrido na ordem canônica CONCEITO → AÇÃO → OBJETO → CONDIÇÃO →
EXCEÇÃO — Blocos vazios pulados, mesma regra de `buildInitialFrames` — mais a Síntese da
regra essencial ao final) e `buildStripPdf` (Variante "tira", FR-024-004/016: 1 página por
Quadro, na ordem da Tira). **Todo texto do usuário é desenhado com `page.drawText(...)`
literal** — nunca interpolado em template/marcação alguma (NFR-024-002 por construção, não
por disciplina de código: não existe camada de template neste desenho). Nenhuma chamada de
rede em nenhum caminho (NFR-024-001 por construção — `pdf-lib` não abre socket).

Rótulo de rascunho + data/hora de geração (FR-024-001/AC-024-005) desenhados em **toda**
página, inclusive as geradas pelo laço de Quadros — a função que desenha o rótulo roda por
página recém-criada, nunca só na primeira.

Imagem de Quadro (Variante "tira"): recebe o `Buffer` já lido do banco (F5, inalterado —
NFR-024-004, nunca recomprimido/redimensionado no arquivo) mais o formato já detectado por
`detectImageSignature` (COMP-023-002, reusado — nunca confia no `mimeType` armazenado,
mesma disciplina de DEC-023-012). `pdf-lib` só embute `PNG`/`JPEG` nativamente
(`embedPng`/`embedJpg`) — **não tem `embedWebp`**: um Quadro cuja Associação visual é
`WEBP`, ou cujo `embedPng`/`embedJpg` lança (buffer corrompido/irrenderizável), cai no
MESMO caminho de "Quadro sem imagem" (FR-024-005/FR-024-014) — só o texto, sem bloquear a
exportação. Achado técnico do PLAN (TRISK-025-006), não do product-analyst.

Falha segura por construção (FR-024-009/RISK-024-005): `pdf-lib` só devolve o `Buffer` final
via `PDFDocument.save()` **depois** de todo o documento estar montado em memória — não há
`stream` incremental que já tenha entregue bytes ao cliente antes de um erro no meio do
caminho (ao contrário de um motor baseado em `stream` tipo `pdfkit`, que escreveria
progressivamente). Qualquer exceção em qualquer etapa da composição propaga para
`publication.service.ts` SEM que `res.send()` tenha sido chamado — nenhum PDF parcial chega
a existir do lado do cliente.
**Realiza**: FR-024-001, FR-024-003, FR-024-004, FR-024-005, FR-024-009, FR-024-014,
FR-024-016, NFR-024-001, NFR-024-002, NFR-024-004
**Interface pública**:
```ts
export interface PublicationPdfMeta {
  variant: PublicationVariant; // 'TIRA' | 'RESUMO'
  generatedAt: Date;
}

export interface StripFrameForPdf {
  text: string;
  /** `null` = sem Associação visual vinculada, OU formato não suportado por `pdf-lib`
   * (ex.: WEBP), OU falha de decodificação — os 3 casos renderizam só o texto. */
  image: { buffer: Buffer; format: 'PNG' | 'JPEG' } | null;
}

export async function buildSummaryPdf(
  breakdown: Pick<RuleBreakdownDetail, 'concept' | 'action' | 'object' | 'condition' | 'exception' | 'essence'>,
  meta: PublicationPdfMeta,
): Promise<Buffer>;

export async function buildStripPdf(
  frames: readonly StripFrameForPdf[],
  meta: PublicationPdfMeta,
): Promise<Buffer>;
```
**Dependências**: COMP-025-002

### COMP-025-004: Modelo de dados — `ProductionStageType` aditivo, `PublicationEvent`, `PublicationVariant`
**Responsabilidade**: schema Prisma novo/estendido (detalhe completo em §5) — migração
100% aditiva (execução exige autorização do Diretor, mesmo padrão de DEC-023-007). Nenhuma
coluna/tabela/valor existente é removida ou alterada destrutivamente.
**Realiza**: FR-024-010 (parcial — a tabela sustenta a métrica por Variante; a emissão em si
é COMP-025-005)
**Interface pública**: modelos Prisma (§5); `PUBLICATION_VARIANTS`/`PublicationVariant` em
`src/domain/types.ts` (COMP-025-009).
**Dependências**: nenhuma

### COMP-025-005: `publication.service.ts` — orquestração da exportação
**Responsabilidade**: função central `exportPublication`, dentro da seguinte ordem:
1. `assertRawContentExportable(rawContentId, db)` — guarda NOVA (DEC-025-007), comum a
   EDITOR/ADMIN: existe + não soft-deleted (reusa `ACTIVE_RAW_CONTENT_WHERE`,
   `contents.service.ts`), **sem** checagem de autoria (NFR-024-003/AC-024-018).
2. `getRuleBreakdown(rawContentId, actor, db)` (F2, reusado sem reescrever) — `NotFoundError`
   se a Quebra ainda não foi salva → recusa a exportação em qualquer Variante
   (FR-024-002/AC-024-001). Nota: `getRuleBreakdown` chama `assertRawContentReachable`
   internamente (autoria); para não reintroduzir a restrição que o passo 1 acabou de evitar,
   este PLAN usa a leitura de baixo nível equivalente (`ruleBreakdown.findUnique`) direto no
   service de publicação em vez de `getRuleBreakdown`, preservando a MESMA mensagem de erro
   ("Quebra da regra não encontrada.") sem herdar a guarda de autoria de F2.
3. Variante `RESUMO`: `buildSummaryPdf` direto sobre a Quebra lida.
4. Variante `TIRA`: `openMnemonicStrip(rawContentId, actor, db, { suppressOpeningEvent: true })`
   (COMP-025-007) — get-or-generate idempotente reusado sem duplicar lógica; para cada
   `MnemonicFrameDetail` com `visualAssociationId`, `getVisualAssociationBinary` (F5, reusado)
   + `detectImageSignature` (F5, reusado) monta `StripFrameForPdf`; chama `buildStripPdf`.
5. Composição roda sob `withDeadline(promise, env.PUBLICATION_PDF_TIMEOUT_MS)`
   (DEC-025-002) — estoura o teto → `GenerationTimeoutError` (COMP-025-008), mesmo canal de
   falha de FR-024-009 (FR-024-015/AC-024-017).
6. Sucesso: MESMA `$transaction` grava `recordProductionStageEvent(tx, { rawContentId,
   stageType: 'PUBLICACAO_PDF', actorId: actor.id, now })` (mecanismo genérico de F3,
   reusado) **e** `tx.publicationEvent.create({ data: { rawContentId, variant, occurredAt:
   now } })` (log dedicado, DEC-025-005) — só depois do `Buffer` do PDF já estar pronto em
   memória (nunca antes: falha na composição não deixa evento nem log órfão, FR-024-009).
7. Nome do arquivo (FR-024-008/A-024-007):
   `` `${rawContentId}-${variant.toLowerCase()}-rascunho.pdf` `` — só caracteres ASCII
   seguros (uuid + literal), sem input do usuário no nome.

Fail-secure: qualquer exceção em qualquer passo (1-5) propaga sem gravar nada — os passos 6
(evento) só rodam depois de (5) resolver com sucesso.
**Realiza**: FR-024-002, FR-024-003, FR-024-004, FR-024-006, FR-024-008, FR-024-009,
FR-024-010, FR-024-011, FR-024-015, NFR-024-003
**Interface pública**:
```ts
export interface ExportPublicationInput {
  variant: PublicationVariant; // 'TIRA' | 'RESUMO'
}

export interface PublicationResult {
  buffer: Buffer;
  filename: string;
}

export async function exportPublication(
  rawContentId: string,
  input: ExportPublicationInput,
  actor: ContentActor,
  db?: PublicationClient,
): Promise<PublicationResult>;
```
`PublicationClient` = `Pick<typeof prisma, 'rawContent' | 'ruleBreakdown' | 'mnemonicStrip' |
'mnemonicFrame' | 'visualAssociation' | 'visualAssociationLinkEvent' |
'productionStageEvent' | 'publicationEvent' | '$transaction'>` — superconjunto do
`MnemonicStripClient` de `tira.service.ts` (precisa cobrir tudo que `openMnemonicStrip`
exige, mais `publicationEvent`).
**Dependências**: COMP-025-001, COMP-025-003, COMP-025-004, COMP-025-007

### COMP-025-006: `publication.routes.ts` — superfície HTTP da exportação
**Responsabilidade**: 1 rota, `POST /contents/:id/publication`, montada em `apiRoutes`
(EMENDA em `src/http/routes.ts`, mesmo padrão de linha das demais rotas do módulo).
`verifyOrigin` é o 1º handler (DEC-025-004 — a rota TEM efeito colateral real: pode
auto-gerar a Tira e sempre grava os 2 eventos em sucesso, mesmo devolvendo um binário como
resposta; mesma razão de DEC-012-011 que moveu a geração de Tira de `GET` para `POST`).
Resposta de sucesso: `res.type('application/pdf').set('Content-Disposition',
\`attachment; filename="${filename}"\`).send(buffer)` — `attachment`, não `inline`
(distingue de `visual-associations.routes.ts:153`, que serve imagem para exibição embutida).
Sem `try/catch`: Express 5 encaminha a rejeição ao `errorHandler` — `NotFoundError`/
`ConflictError`/`GenerationTimeoutError` do service viram 404/409/503 automaticamente.
**Realiza**: FR-024-007 (parcial — o handler HTTP é a base sobre a qual o frontend constrói
os 3 estados), FR-024-008, FR-024-009, FR-024-011, NFR-024-003
**Interface pública**:
- `POST /contents/:id/publication` → `verifyOrigin` + `requireRole('POST',
  '/contents/:id/publication', 'EDITOR', 'ADMIN')` — body: `ExportPublicationBodyInput`;
  resposta: binário `application/pdf` ou erro JSON padrão do `errorHandler`.
**Dependências**: COMP-025-005, COMP-025-001

### COMP-025-007: EMENDA em `tira.service.ts` — `openMnemonicStrip` com supressão de abertura + ordem canônica exportada
**Responsabilidade**: duas mudanças cirúrgicas no arquivo já entregue por F4/F5
(DEC-025-003):
1. `openMnemonicStrip` ganha um 4º parâmetro opcional, `options?: { suppressOpeningEvent?:
   boolean }` (default `{ suppressOpeningEvent: false }` — **nenhum chamador existente muda
   de comportamento**, só `publication.service.ts` passa `true`). Quando `true`, o ramo de
   CRIAÇÃO (Tira ainda não existia) grava a linha normalmente mas **pula** a chamada de
   `recordProductionStageEvent` (FR-024-013) — 0 eventos ficam registrados para o par
   `(rawContentId, 'TIRA_MNEMONICA')`.
2. O ramo de REABERTURA (Tira já existe, `existing !== null`) — hoje devolve a Tira sem
   checar nada — passa a rodar a MESMA decisão de `decideStageTransition` sobre o histórico
   real do par ANTES de devolver: histórico vazio (só acontece quando a criação anterior foi
   suprimida por `suppressOpeningEvent: true`) → emite `ABERTURA` agora; histórico não-vazio
   (fluxo humano normal, que sempre emitiu `ABERTURA` na criação) → não emite nada extra
   (comportamento idêntico ao atual). Isso generaliza `openMnemonicStrip` para SEMPRE
   refletir "emite conforme o histórico", tanto na criação quanto na reabertura, sem duplicar
   a lógica de decisão (reusa `decideStageTransition`, já importado).
3. Extrai a ordem canônica de `buildInitialFrames` para uma constante exportada
   (`CANONICAL_RULE_BREAKDOWN_ORDER`) — reusada por `pdf-composer.ts`/`publication.service.ts`
   (Variante "resumo", A-024-006) em vez de duplicar o array `['concept', 'action', 'object',
   'condition', 'exception']` num 2º arquivo (lição [DRY] já reincidente 3× em F5,
   PLAN-023).

Ver DEC-025-003 para a alternativa descartada (wrapper paralelo duplicando a lógica) e a
razão.
**Realiza**: FR-024-006, FR-024-013
**Interface pública** (assinatura alterada, retrocompatível):
```ts
export async function openMnemonicStrip(
  rawContentId: string,
  actor: ContentActor,
  db?: MnemonicStripClient,
  options?: { suppressOpeningEvent?: boolean },
): Promise<MnemonicStripDetail>;

export const CANONICAL_RULE_BREAKDOWN_ORDER: readonly Array<{
  originBlock: 'concept' | 'action' | 'object' | 'condition' | 'exception';
}>;
```
**Dependências**: nenhuma nova (arquivo já existente, F4/F5)

### COMP-025-008: EMENDA em `http/errors.ts` — `GenerationTimeoutError`
**Responsabilidade**: nova subclasse de `AppError` (503, `GENERATION_TIMEOUT`), mensagem
genérica pt-BR — usada quando `withDeadline` (COMP-025-005) estoura
`PUBLICATION_PDF_TIMEOUT_MS`. Nenhuma outra classe existente é tocada.
**Realiza**: FR-024-015
**Interface pública**:
```ts
export class GenerationTimeoutError extends AppError {
  constructor(message = 'A geração do documento demorou demais. Tente novamente.') {
    super(message, 503, 'GENERATION_TIMEOUT');
  }
}
```
**Dependências**: nenhuma

### COMP-025-009: Extensão de domain types — `PublicationVariant` (backend + frontend)
**Responsabilidade**: backend `src/domain/types.ts` ganha `PUBLICATION_VARIANTS`/
`PublicationVariant` (mesmo molde de `PRODUCTION_STAGE_TYPES`, mas ESTE tem consumidor de
tela — precisa de espelho no frontend, ao contrário de `PRODUCTION_STAGE_TYPES`/
DEC-010-006). Frontend `src/types/domain.ts` ganha o tipo espelhado + `
PUBLICATION_VARIANT_LABELS` (`{ TIRA: 'Tira mnemônica', RESUMO: 'Resumo' }`) — rótulo pt-BR
vem do mapa, nunca escrito solto no JSX (perfil frontend §"Texto e domínio").
**Realiza**: nenhum diretamente — tipos de domínio consumidos por COMP-025-001/010/011
**Interface pública**:
```ts
// backend, src/domain/types.ts
export const PUBLICATION_VARIANTS = ['TIRA', 'RESUMO'] as const;
export type PublicationVariant = (typeof PUBLICATION_VARIANTS)[number];

// frontend, src/types/domain.ts
export type PublicationVariant = 'TIRA' | 'RESUMO';
export const PUBLICATION_VARIANT_LABELS: Record<PublicationVariant, string> = {
  TIRA: 'Tira mnemônica',
  RESUMO: 'Resumo',
};
```
**Dependências**: nenhuma

### COMP-025-010: Extensão de `store/api.ts` (RTK Query) — `exportPublication`
**Responsabilidade**: mutation nova com `responseHandler` custom (DEC-025-006) — a resposta
de sucesso é binária (`application/pdf`), a de erro é JSON (mesmo formato do
`errorHandler` do backend). O `responseHandler` inspeciona `Content-Type` da resposta: começa
com `application/pdf` → `{ blob: await response.blob(), filename: <extraído de
Content-Disposition> }`; caso contrário → `response.json()` (erro), que o `fetchBaseQuery`
já encaminha para `error.data` do jeito de sempre.
**Realiza**: FR-024-007 (base da mutation que alimenta os 3 estados do componente), FR-024-008
**Interface pública**:
```ts
export interface ExportPublicationArgs {
  rawContentId: string;
  variant: PublicationVariant;
}
export interface ExportPublicationResult {
  blob: Blob;
  filename: string;
}
// endpoint: exportPublication (mutation), sem invalidatesTags (nenhum cache de leitura
// depende do resultado — a exportação não persiste nada consultável por esta tela).
```
**Dependências**: COMP-025-009

### COMP-025-011: Client component reusável — `publication-export-control.tsx`
**Responsabilidade**: `'use client'`; 2 controles (Variante "tira"/"resumo",
`PUBLICATION_VARIANT_LABELS`), 3 estados observáveis por ação (FR-024-007/AC-024-006): em
andamento (controle desabilitado + indicador visível), sucesso (dispara o download via
`URL.createObjectURL(blob)` + `<a download={filename}>` clicado programaticamente,
`URL.revokeObjectURL` depois), falha (mensagem de erro visível, `role="alert"`, sem apagar a
Variante selecionada — AC-024-006). Usado pelas duas telas (COMP-025-012/013), nunca duplica
lógica entre elas.
**Realiza**: FR-024-007, FR-024-008, FR-024-012
**Interface pública**: componente client `publication-export-control`, prop
`rawContentId: string`.
**Dependências**: COMP-025-010

### COMP-025-012: EMENDA em `content-form.tsx` — controle de exportação na tela do Conteúdo bruto
**Responsabilidade**: `<PublicationExportControl rawContentId={contentId} />` renderizado só
no modo `mode === 'edit'` (o modo `create` ainda não tem `contentId` — nada para exportar
antes de salvar), ao lado das ações existentes do formulário.
**Realiza**: FR-024-012
**Interface pública**: extensão do componente client `ContentForm` existente (COMP-006-014).
**Dependências**: COMP-025-011

### COMP-025-013: EMENDA em `mnemonic-strip-board.tsx` — controle de exportação + confirmação de abertura na 1ª visualização
**Responsabilidade**: duas mudanças no client component já entregue por F4/F5:
1. `<PublicationExportControl rawContentId={rawContentId} />` no cabeçalho do board, visível
   assim que `hasData` é `true` (FR-024-012).
2. O `useEffect` que dispara `useOpenMnemonicStripMutation` deixa de depender só de
   `isNotFound` — passa a disparar também quando `hasData` é `true` NA 1ª leitura
   bem-sucedida da montagem (mesma trava `openAttemptedRef`, sem repetir a cada
   re-render/refetch). Efeito prático (DEC-025-003, "abrir a tela" como gatilho de
   FR-024-013/AC-024-015): quando a Tira já existe por auto-geração via exportação (evento
   de abertura suprimido, COMP-025-007), a 1ª visita humana à tela chama
   `POST /contents/:id/strip` mesmo com a Tira já existindo — cai no ramo de REABERTURA de
   `openMnemonicStrip`, que agora (COMP-025-007, item 2) confirma a ABERTURA porque o
   histórico do par está vazio; quando a Tira NUNCA foi auto-gerada (fluxo 100% humano,
   igual a hoje), o histórico já tem `ABERTURA` da criação — a chamada extra é um no-op sem
   efeito observável, custo de 1 requisição `POST` idempotente a mais por carregamento de
   tela (aceitável, mesma ordem de grandeza do `GET` que já ocorre).
**Realiza**: FR-024-012, FR-024-013
**Interface pública**: extensão do componente client `mnemonic-strip-board` existente
(COMP-012-012).
**Dependências**: COMP-025-011, COMP-012-012

## 4. Fluxos principais

**F-1 Exportação "resumo".** `POST /contents/:id/publication` `{ variant: 'RESUMO' }` →
`assertRawContentExportable` → Quebra não encontrada → 404 (FR-024-002); Quebra encontrada →
`buildSummaryPdf` sob `withDeadline` → sucesso: `$transaction` grava
`ProductionStageEvent(PUBLICACAO_PDF)` + `PublicationEvent(variant: RESUMO)` → responde
`attachment`.

**F-2 Exportação "tira", já aberta.** `{ variant: 'TIRA' }` → Quebra encontrada →
`openMnemonicStrip(..., { suppressOpeningEvent: true })` encontra a Tira existente
(ramo de reabertura, sem novo evento de `TIRA_MNEMONICA` — histórico já tinha `ABERTURA` do
fluxo humano original) → para cada Quadro, resolve imagem (existe e decodifica → embutida;
sem Associação ou falha de decodificação/formato não suportado → só texto) →
`buildStripPdf` → mesma gravação de evento/log de F-1 (variant: TIRA).

**F-3 Exportação "tira", ainda não aberta (auto-geração sem evento).** `{ variant: 'TIRA' }`
→ Quebra encontrada → `openMnemonicStrip(..., { suppressOpeningEvent: true })` CRIA a Tira +
Quadros (mesma regra de F4, `buildInitialFrames`) SEM emitir `ABERTURA` de
`TIRA_MNEMONICA` (FR-024-013) → compõe o PDF a partir dos Quadros recém-criados (nenhum tem
Associação visual ainda, todos só-texto) → mesma gravação de evento/log de F-1.

**F-4 1ª interação humana confirma a abertura.** Depois de F-3, o EDITOR abre a tela da Tira
(`MnemonicStripBoard`) → `GET` traz a Tira já existente (`hasData`) → o `useEffect`
estendido (COMP-025-013) dispara `POST /contents/:id/strip` mesmo assim → ramo de
reabertura de `openMnemonicStrip` (COMP-025-007) vê histórico vazio para o par → emite
`ABERTURA` agora, atribuída ao EDITOR que abriu a tela. Se em vez disso o EDITOR MUTAR um
Quadro primeiro (sem nunca ter visitado a tela) — `addMnemonicFrame`/
`updateMnemonicFrameText`/etc. já decidem pelo histórico (mecanismo inalterado) — histórico
vazio → também emite `ABERTURA` nesse instante. Qualquer um dos dois, o que vier primeiro,
satisfaz FR-024-013/AC-024-015.

**F-5 Falha segura — erro do motor.** Qualquer exceção não tratada dentro de
`buildSummaryPdf`/`buildStripPdf` (ex.: caractere fora do WinAnsi de uma fonte padrão,
TRISK-025-007) propaga para `publication.service.ts` ANTES de qualquer gravação de evento —
`errorHandler` devolve erro JSON genérico, nenhum `res.send()` de binário acontece
(FR-024-009/AC-024-008).

**F-6 Teto de duração excedido.** `withDeadline` vence a corrida antes da composição
terminar → `GenerationTimeoutError` (503) propaga → mesma ausência de gravação de F-5 →
FR-024-015/AC-024-017.

## 5. Modelo de dados

Aditivo — nenhuma coluna, tabela ou valor de enum existente é removido ou alterado
destrutivamente. Migração exige autorização do Diretor antes de `prisma migrate dev`
(mesmo padrão de DEC-023-007, §9).

```prisma
enum ProductionStageType {
  CONTEUDO_BRUTO
  QUEBRA_DA_REGRA
  TIRA_MNEMONICA
  ASSOCIACAO_VISUAL
  PUBLICACAO_PDF // NOVO (F6) — aditivo, sem redesenho do mecanismo (NFR-009-001/DEC-010-001)
}

enum PublicationVariant {
  TIRA
  RESUMO
}

/// Log mínimo de instrumentação da métrica de §1.3(a) da SPEC-024 — mesmo padrão de
/// VisualAssociationLinkEvent (DEC-023-011): o ProductionStageEvent genérico (acima) não
/// carrega qual Variante foi exportada; esta tabela carrega. Sem relação/FK para
/// RawContent (deliberado, mesma razão de TRISK-023-007) — sobrevive à remoção reversível
/// do Conteúdo bruto, é indicador operacional, não trilha de auditoria formal. Uma linha
/// por exportação CONCLUÍDA COM SUCESSO (nunca por tentativa falha — a falha é apurada por
/// log de erro, fonte (b) de §1.3, fora desta tabela).
model PublicationEvent {
  id           String             @id @default(uuid(7))
  rawContentId String
  variant      PublicationVariant
  occurredAt   DateTime           @default(now())

  @@index([occurredAt])
  @@map("publication_events")
}
```

## 6. Decisões arquiteturais

### DEC-025-001: Motor de geração de PDF — `pdf-lib`
**Contexto**: A-024-002/A-022-003(SPEC) delegam a escolha do motor a este PLAN, exigindo
postura agnóstica de biblioteca (NFR-024-001/002) e citando o teto DURO de
`mnemonicos-backend/vercel.json` (`maxDuration: 15`/`memory: 1024`) como restrição real de
topologia serverless. RISK-024-006 da SPEC exige que a DEC apresente a consequência de que a
escolha do motor "fixa, na prática, o padrão visual de todas as 10 camadas do método", não
só a postura de segurança.
**Decisão**: `pdf-lib` — API de baixo nível por coordenada (texto/imagem), sem processo
externo, sem dependência nativa/WASM, sem camada de template/HTML.
**Alternativas consideradas**:
- `pdfkit`, descartada — perfil técnico próximo (também puro JS, também sem
  template/headless), mas API baseada em `stream` (escreve progressivamente): usar
  `pdfkit` direto sobre `res` arriscaria entregar bytes ao cliente ANTES de um erro no meio
  da composição, o que violaria FR-024-009 (nunca disponibilizar documento parcial) sem
  disciplina extra de buffer-then-send; `pdf-lib` só devolve o `Buffer` completo via `save()`
  depois de tudo montado, ganhando essa garantia de graça. Custo concreto de descartar
  `pdfkit`: nenhuma perda de capacidade real para esta fatia (nenhum recurso de fluxo de
  texto automático — que `pdfkit` oferece e `pdf-lib` não — é necessário aqui).
- `@react-pdf/renderer`, descartada preventivamente — depende de `yoga-layout`
  (tipicamente WASM), cujo custo de cold-start em function serverless não tem medição
  disponível nesta fatia; a página desta fatia (texto + imagem posicionados, sem layout
  flexbox) não precisa do modelo declarativo que essa lib oferece. Custo concreto: incerteza
  de cold-start contra um teto DURO de 15 s, sem necessidade que a justifique.
- Motor baseado em browser headless (Puppeteer/Playwright+Chromium), descartada — bundle de
  dezenas/centenas de MB e cold-start tipicamente na casa de segundos por si só competem
  diretamente com o teto de `memory: 1024`/`maxDuration: 15`, especialmente em cold start
  (function nova a cada invocação fria); introduziria também uma camada de
  template/HTML/CSS (e potencialmente rede para fontes/recursos) que NFR-024-001/002 pedem
  para evitar — motor sem HTML elimina essa classe de risco por construção, `pdf-lib` não
  precisa de disciplina de sanitização de template porque a camada nem existe.
**Consequências**: leiaute por coordenada explícita exige lógica própria de quebra de linha
(COMP-025-002, `pdf-lib` não faz *word-wrap*). RISK-024-006 se concretiza: o padrão visual
do PDF (fontes padrão embutidas, margens, tamanho de página) fica definido pelo código desta
fatia e é o ponto de partida das 10 camadas futuras do método — a interface pública de
`pdf-composer.ts` (funções que recebem dado estruturado e devolvem `Buffer`) isola a troca
de motor a um único arquivo, mas o padrão VISUAL em si não migra sozinho: trocar de motor
depois significa redesenhar a composição, não só trocar 1 import.
**Reabrir se**: medição real (gate 10) mostrar tempo de geração perto do teto de 15 s com
Tiras grandes (RISK-024-004/Q-024-001 — nesse caso, revisitar o teto de Quadros/texto por
Quadro ANTES de trocar de motor); ou se uma fatia futura (F7, contrastes/pegadinhas/
flashcards impressos) exigir leiaute rico demais para desenho por coordenada.
**Irreversível**: sim — RISK-024-006 da SPEC já nomeia esta escolha como "irreversível na
prática" pelo padrão visual que ela fixa para as 10 camadas do método; tecnicamente
trocável, mas o custo de trocar (redesenhar toda a composição visual, não só o import) é alto
o bastante para tratar como irreversível na prática, registrado no INDEX.
**Aderência à ficha/perfil**: nova

### DEC-025-002: Teto de duração interno com folga, antes do corte da função serverless
**Contexto**: `vercel.json` (`maxDuration: 15`) é o teto DURO da function — quando a Vercel
mata o processo por estourá-lo, a resposta HTTP não é controlada pelo handler da aplicação
(erro de infraestrutura, sem corpo JSON previsível pelo `errorHandler`); FR-024-015/
AC-024-017 exigem que o sistema "informe falha ao usuário... nunca deixe a requisição sem
resposta", pelo MESMO canal de falha de FR-024-009.
**Decisão**: teto interno explícito, com folga, abaixo do teto duro —
`PUBLICATION_PDF_TIMEOUT_MS` (default `12000`, 3 s de folga) — implementado com
`Promise.race` entre a composição do PDF e um temporizador; o temporizador vencendo lança
`GenerationTimeoutError` (COMP-025-008), que o `errorHandler` mapeia para 503 ANTES do corte
abrupto da Vercel.
**Alternativas consideradas**:
- Confiar só no timeout da própria function serverless (sem teto interno), descartada —
  quando a plataforma mata a function, a aplicação não controla a resposta; não é possível
  GARANTIR que o comportamento observável de falha do runtime coincida com o canal de falha
  que FR-024-009/015 exigem — o custo concreto é a impossibilidade de PROVAR a garantia por
  teste (o teste não consegue observar o comportamento do runtime da Vercel em CI local).
**Consequências**: uma constante de configuração nova e um wrapper de timeout na função de
composição; o `Promise.race` não interrompe de fato o trabalho síncrono de `pdf-lib` já em
andamento (Node não preempta código síncrono) — garante a RESPOSTA HTTP dentro do teto, não
a liberação imediata de CPU (TRISK-025-005).
**Reabrir se**: medição real (gate 10) mostrar que o teto interno escolhido corta gerações
legítimas de Tiras grandes antes do necessário — revisitar junto de Q-024-001 (teto de texto
por Quadro), não só alargar o número.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-025-003: FR-024-013 — supressão e restauração da abertura via parâmetro, não wrapper paralelo
**Contexto**: `openMnemonicStrip` (F4) SEMPRE emite `ABERTURA` de `TIRA_MNEMONICA` na 1ª
criação — FR-024-013 exige que a auto-geração via exportação NÃO emita esse evento nesse
instante, mas que a 1ª interação humana subsequente (visualizar a tela OU mutar um Quadro,
o que vier primeiro) o emita.
**Decisão**: parâmetro opcional `options?: { suppressOpeningEvent?: boolean }` em
`openMnemonicStrip` (default preserva 100% do comportamento atual para os chamadores
existentes) + o ramo de reabertura passa a decidir/emitir pelo MESMO mecanismo
(`decideStageTransition` sobre o histórico real) em vez de simplesmente devolver a Tira sem
checar nada; frontend confirma a abertura também quando a leitura (`GET`) já encontra a Tira
existente, não só quando ela ainda não existe (COMP-025-013).
**Alternativas consideradas**:
- Função paralela (`openMnemonicStripForExport`) duplicando toda a lógica de
  `assertStripPrerequisites`/criação/concorrência de `openMnemonicStrip`, descartada —
  reincidência direta da lição [DRY] já apontada 3× dentro de PLAN-023 (F5); custo concreto:
  2 implementações da MESMA regra de concorrência (corrida de `@unique(ruleBreakdownId)`,
  linhas 200-211 de `tira.service.ts`) divergindo com o tempo é exatamente o tipo de bug que
  só aparece sob concorrência real, difícil de pegar em teste.
- Modificar `getMnemonicStrip` (o `GET` de leitura pura) para emitir o evento quando detecta
  histórico vazio, descartada — reintroduziria a MESMA classe de vulnerabilidade que
  DEC-012-011 corrigiu (cookie `sameSite: 'lax'` acompanha navegação top-level; um `GET` com
  efeito colateral pode ser forjado por CSRF via link/imagem, sem `verifyOrigin` possível em
  `GET`). Custo concreto: reabriria um achado de segurança REAL já fechado por gate 8 em F4.
**Consequências**: `openMnemonicStrip` ganha uma responsabilidade a mais (decidir/emitir
também na reabertura) — mudança de comportamento OBSERVÁVEL só quando o histórico está vazio
(caso novo, introduzido por esta fatia); para todo chamador anterior a F6, o histórico nunca
estava vazio no momento da reabertura (a criação sempre emitiu), então o comportamento
observado por PLAN-012/PLAN-023 não muda.
**Reabrir se**: nunca — o parâmetro é aditivo e o ramo de reabertura generalizado é
estritamente mais correto (reflete o histórico real em vez de assumir que ele sempre existe).
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-025-004: Endpoint único, variant no corpo — `POST /contents/:id/publication`
**Contexto**: SPEC-024 é explícita (§4.1/§4.2): as duas Variantes nascem do MESMO pedido de
exportação, nunca de telas/fluxos/rotas separadas.
**Decisão**: 1 rota, `POST`, `variant` no corpo (`ExportPublicationBodyInput`) — nunca `GET`
(a rota tem efeito colateral real: pode auto-gerar a Tira e sempre grava 2 eventos em
sucesso), nunca 2 rotas por Variante.
**Alternativas consideradas**:
- 2 rotas por Variante (`/contents/:id/publication/tira`, `.../resumo`), descartada — o
  Out-of-scope da SPEC (§4.2) nomeia explicitamente "telas ou fluxos separados por
  Variante" como leitura errada do documento; a mesma lógica se estende ao desenho da rota.
- `GET` com `variant` na query string, descartada — mesma razão de DEC-012-011/DEC-025-003:
  um `GET` com efeito colateral (auto-geração + eventos) é superfície CSRF sob cookie
  `sameSite: 'lax'`, sem `verifyOrigin` possível nesse método.
**Consequências**: nenhuma — desenho direto, sem trade-off residual.
**Reabrir se**: nunca — decorre diretamente do texto da SPEC e do padrão de segurança já
estabelecido no slug.
**Irreversível**: não
**Aderência à ficha/perfil**: herdada (mesmo padrão POST-para-mutação-com-efeito-colateral
de DEC-012-011)

### DEC-025-005: Persistência do evento de publicação — evento genérico + log dedicado por Variante
**Contexto**: FR-024-010 exige "emitir um evento de etapa de produção (mesmo mecanismo de
F3/F5)... registrando a Variante exportada" — mas o `ProductionStageEvent` genérico (F3) é
deliberadamente mínimo (RISK-011-004/TRISK-012-004 já aceitam esse limite) e não tem campo
para Variante.
**Decisão**: reusa `recordProductionStageEvent`/`ProductionStageType.PUBLICACAO_PDF` (mesmo
mecanismo, satisfaz a exigência literal de reuso) PARA o sinal de etapa genérico, mais uma
tabela nova e mínima, `PublicationEvent { rawContentId, variant, occurredAt }`, escrita na
MESMA `$transaction`, para a métrica por Variante de §1.3(a) — mesmo padrão exato de
DEC-023-005/DEC-023-011 (F5, `VisualAssociationLinkEvent`).
**Alternativas consideradas**:
- Estender o payload do `ProductionStageEvent` genérico com um campo `variant`, descartada
  — acoplaria um campo específico desta fatia a um mecanismo COMPARTILHADO por 4 fatias (F2-
  F6), mesma razão de descarte já registrada em DEC-023-011; mudança que se propagaria para
  trás (schema de uma tabela usada por outras 3 fatias já entregues).
**Consequências**: mais uma tabela pequena, sem FK (TRISK-025-004, mesma razão de
TRISK-023-007); a razão exportação-por-Variante é calculável por 1 `GROUP BY variant` sobre
`occurredAt >= desde` — demonstrável no gate 9 sem UI nova (AC-024-012).
**Reabrir se**: nunca — se a métrica por Variante deixar de ser necessária, a tabela some
junto (não é referenciada por nenhuma regra de negócio, só por leitura).
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-025-006: Frontend — mutation RTK Query com `responseHandler` binário, não link direto
**Contexto**: FR-024-007 exige 3 estados observáveis (em andamento, sucesso, falha) por ação
de exportação; o precedente mais próximo do repo (`visual-association-list-states.tsx`) usa
um `<img src=URL>`/link direto para o binário de uma imagem — leitura idempotente, sem custo
perceptível, sem necessidade de indicador de progresso.
**Decisão**: mutation RTK Query (`exportPublication`) com `responseHandler` custom que
inspeciona `Content-Type` (binário → `blob`+`filename`; senão → `json`, erro) — os 3 estados
observáveis vêm de graça dos estados padrão de uma mutation (`isLoading`/`isSuccess`/
`isError`).
**Alternativas consideradas**:
- Link direto (`<a href="/contents/:id/publication?...">`) apontando para o endpoint,
  descartada — a geração de PDF não é uma leitura idempotente de baixo custo como a imagem
  da Biblioteca visual: pode auto-gerar a Tira, compor um documento potencialmente grande, e
  o teto de 15 s é real; um link cru de navegação não dá nenhum controle de estado
  "em andamento" ao componente (o browser só mostra sua própria UI de download nativa,
  inconsistente entre navegadores, sem o `role="alert"` de falha exigido por AC-024-006) —
  não satisfaz FR-024-007 literalmente. Também exigiria `GET`, já descartado por
  DEC-025-004.
**Consequências**: o componente gerencia manualmente o ciclo `createObjectURL`/clique
programático/`revokeObjectURL` (sem vazar memória do blob).
**Reabrir se**: nunca — decorre diretamente de FR-024-007 (3 estados observáveis), que um
link cru não pode satisfazer.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-025-007: Guarda de alcance da exportação — leitura comum a EDITOR/ADMIN; auto-geração de Tira permanece restrita à autoria herdada de F4
**Contexto**: AC-024-018 exige alcance de exportação "comum a EDITOR/ADMIN... herdado de
F4/F5, sem restrição adicional por autoria" — mas o mecanismo REAL herdado
(`assertRawContentReachable`, usado por `getRuleBreakdown`/`openMnemonicStrip`/toda mutação
de F4) restringe EDITOR à PRÓPRIA autoria em F2/F4/F5, sem exceção, hoje. A premissa do AC
parece assumir algo que o código real de F4/F5 não faz — achado deste PLAN, não do
product-analyst (marcado `[assumido]` em §1, A-025-001).
**Decisão**: nova guarda `assertRawContentExportable(rawContentId, db)` — existe + não
soft-deleted (reusa `ACTIVE_RAW_CONTENT_WHERE`), SEM checagem de autoria — usada para toda
LEITURA de material já existente na exportação (Quebra salva, Tira já aberta, binário de
Associação visual vinculada), satisfazendo AC-024-018 para "resumo" e "tira" já aberta de
Conteúdo bruto de qualquer autor. A AUTO-GERAÇÃO da Tira (FR-024-006, quando ainda não
existe) continua delegada a `openMnemonicStrip` **sem nenhuma mudança na guarda dele** —
um Conteúdo bruto de outro autor sem Tira ainda aberta recusa a exportação em "tira" com o
mesmo comportamento herdado de `assertStripPrerequisites`/`assertRawContentReachable`:
**404, `NotFoundError`, "Conteúdo bruto não encontrado."** (medido na implementação de
TASK-025-008 — não 409/`ConflictError`, como uma versão anterior desta DEC presumia) até
que o autor ou um ADMIN a abram.
**Alternativas consideradas**:
- Afrouxar `assertRawContentReachable`/a guarda de escrita de `openMnemonicStrip` para todo
  EDITOR (não só o autor), descartada — mudaria a superfície de segurança de autorização de
  3 fatias já entregues e com gate de segurança aprovado (F2/F4/F5) para satisfazer 1 AC de
  uma 4ª fatia, sem pedido equivalente registrado nas fatias originais; custo concreto:
  regressão de controle de acesso (A01) em superfície muito maior que esta fatia.
- "Elevar" o ator (tratar o EDITOR como ADMIN só para esta chamada) ao invocar
  `openMnemonicStrip`, descartada — falsificar o papel do ator é, por si, uma classe de bug
  de autorização: o evento de `ABERTURA` emitido carregaria `actorId` do EDITOR real mas
  teria passado por uma checagem que não reflete o papel dele de fato, abrindo precedente de
  "contornar guarda elevando o ator" reutilizável por qualquer chamador futuro.
**Consequências**: exportação de "resumo" e "tira" já aberta funciona para qualquer
EDITOR/ADMIN independente de autoria (AC-024-018 satisfeito nesses 2 casos); exportação de
"tira" AINDA NÃO aberta de Conteúdo bruto de outro autor recusa até a abertura por quem
alcança — comportamento não testado literalmente por nenhum AC declarado da SPEC (sinalizado
em `duvidas` do sumário deste scribe).
**Reabrir se**: o Diretor/PO confirmar que a auto-geração TAMBÉM precisa funcionar para
não-autor — nesse caso reabre a guarda de ESCRITA de `openMnemonicStrip`/F4 (mudança de
superfície de segurança fora do escopo cirúrgico desta fatia sozinha, precisaria de PLAN/
brief próprio revisando F4).
**Irreversível**: não
**Aderência à ficha/perfil**: nova

## 7. Mapeamento FR -> componente

| FR | Componente | AC cobertos |
|----|------------|-------------|
| FR-024-001 | COMP-025-003 | AC-024-005 |
| FR-024-002 | COMP-025-005 | AC-024-001 |
| FR-024-003 | COMP-025-003, COMP-025-005 | AC-024-002 |
| FR-024-004 | COMP-025-003, COMP-025-005 | AC-024-003 |
| FR-024-005 | COMP-025-003 | AC-024-003 |
| FR-024-006 | COMP-025-005, COMP-025-007 | AC-024-004 |
| FR-024-007 | COMP-025-006, COMP-025-010, COMP-025-011 | AC-024-006 |
| FR-024-008 | COMP-025-005, COMP-025-006, COMP-025-010 | AC-024-007 |
| FR-024-009 | COMP-025-003, COMP-025-005, COMP-025-006 | AC-024-008 |
| FR-024-010 | COMP-025-004, COMP-025-005 | AC-024-012 |
| FR-024-011 | COMP-025-005, COMP-025-006 | AC-024-013 |
| FR-024-012 | COMP-025-011, COMP-025-012, COMP-025-013 | AC-024-014 |
| FR-024-013 | COMP-025-007, COMP-025-013 | AC-024-015 |
| FR-024-014 | COMP-025-003 | AC-024-016 |
| FR-024-015 | COMP-025-005, COMP-025-008 | AC-024-017 |
| FR-024-016 | COMP-025-003 | AC-024-020 |
| NFR-024-001 | COMP-025-003 | AC-024-010 |
| NFR-024-002 | COMP-025-003 | AC-024-010 |
| NFR-024-003 | COMP-025-005, COMP-025-006 | AC-024-009, AC-024-018, AC-024-019 |
| NFR-024-004 | COMP-025-003 | AC-024-011 |

## 8. Riscos técnicos

- **TRISK-025-001** `ALTER TYPE "ProductionStageType" ADD VALUE 'PUBLICACAO_PDF'` dentro de
  migração transacional pode exigir commit intermediário antes de uso na mesma sessão,
  dependendo da versão real do Postgres (mesma classe de TRISK-012-001/TRISK-023-001)
  (mitigação: a TASK de migração aplica e testa a gravação com o valor novo logo em
  seguida; se recusado, dividir em 2 migrações sequenciais).
- **TRISK-025-002** `pdf-lib` é dependência nova — supply chain de primeira classe em npm
  (A03) (mitigação: `/keelson:audit` no gate 8 antes do merge).
- **TRISK-025-003** Sem teto de Quadros por Tira nem de tamanho de texto por Quadro
  (RISK-011-007/RISK-024-004 herdado, Q-024-001 explicitamente não resolvido por SPEC-024) —
  uma Tira grande com muitas imagens de até 5 MB cada (F5) pode se aproximar do teto
  combinado de 15 s/1024 MB (mitigação: aceito nesta fatia; medir tempo real de geração no
  gate 10; revisitar Q-024-001 se a medição mostrar risco real).
- **TRISK-025-004** `PublicationEvent` sem FK para `RawContent` (mesma decisão deliberada de
  DEC-023-011/TRISK-023-007) — sobrevive à remoção reversível do Conteúdo bruto (mitigação:
  aceitável, é indicador operacional, não trilha de auditoria formal).
- **TRISK-025-005** O teto de duração interno (`Promise.race`, DEC-025-002) garante a
  RESPOSTA HTTP dentro do prazo, mas não interrompe o trabalho síncrono de `pdf-lib` já em
  andamento (Node não preempta código síncrono) — a function pode seguir consumindo CPU nos
  bastidores até o corte duro da Vercel, mesmo depois da resposta de timeout já enviada
  (mitigação: aceito nesta fatia; medir tempo real de composição no gate 10).
- **TRISK-025-006** `pdf-lib` só embute `PNG`/`JPEG` nativamente — não tem `embedWebp`; uma
  Associação visual armazenada como `WEBP` (formato válido desde F5) nunca é embutida na
  Variante "tira", sempre cai no caminho de "só texto" (mitigação: comportamento correto sob
  FR-024-005/FR-024-014, mas vale nomear explicitamente para não ser lido como bug — WEBP
  vinculado é uma degradação SEMPRE, não uma falha ocasional).
- **TRISK-025-007** As fontes padrão do `pdf-lib` (Helvetica, WinAnsi/cp1252) cobrem os
  diacríticos do português (á, é, ã, ç etc.), mas não caractere fora de Latin-1 (ex.: emoji
  colado em texto livre) — nesse caso `drawText` lança, tratado como falha da geração
  inteira (FR-024-009, nunca corrompe silenciosamente) (mitigação: aceito nesta fatia, sem
  sanitização de charset; revisitar se ocorrência real for reportada).
- **TRISK-025-008** `route-authz-matrix.integration.test.ts` (hoje 33 pares) precisa crescer
  para a rota nova (+1, `POST /contents/:id/publication`) — se ficar de fora, nada acusa
  isso no boot, só a suíte (mesma lição de Waves anteriores sobre allowlist).

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs — 16/16 FRs
- [ ] Todos os NFRs cobertos têm verificação — 4/4 NFRs
- [ ] Decisões DEC refletidas no código — 7 DECs
- [ ] Aderência à ficha/perfil validada
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates)
- [ ] Métrica da SPEC operacional (§1.3, Fonte de medição mista) — (a) instrumentada:
  `PublicationEvent` grava `variant` em toda exportação concluída com sucesso, e uma
  consulta/teste demonstra a contagem por Variante sobre um período (gate 9 exibe o número
  existindo, sem UI nova exigida, AC-024-012); (b) observacional: apuração manual do log de
  erro do backend na Entrega do ciclo (ato humano, não código deste PLAN) — a razão mista
  (sucessos instrumentados ÷ (sucessos + falhas do log)) vira veredito de métrica no ciclo
  seguinte (decisão 4.99)
- [ ] Migração revisada e **autorizada pelo Diretor antes de `prisma migrate dev`** — 100%
  aditiva: `ALTER TYPE "ProductionStageType" ADD VALUE 'PUBLICACAO_PDF'`, `CREATE TYPE
  "PublicationVariant"`, `CREATE TABLE publication_events`
- [ ] `route-authz-matrix.integration.test.ts` estendido com o par novo (33 → 34,
  TRISK-025-008)
- [ ] `npm audit`/gate 8 sobre a dependência nova (`pdf-lib`) sem vulnerabilidade não
  mitigada
- [ ] Postura de segurança do motor provada, não só declarada: teste com um payload
  "hostil" (string de texto do usuário parecida com marcação/diretiva de template, AC-024-010)
  sai literal no PDF gerado, e nenhuma chamada de rede ocorre durante a composição
  (NFR-024-001/002)
- [ ] Extensão da rede de paridade cross-repo (mesmo padrão de `PROOF_RADAR_CLASSES`/
  `NORMATIVE_SOURCE_TYPES`) cobre `PublicationVariant` entre backend e frontend

## 10. Não coberto por este PLAN

Nenhum — cobertura total da SPEC-024 (16/16 FRs, 4/4 NFRs) por este PLAN (Caso D, único
PLAN da SPEC). Os itens explicitamente fora de escopo pertencem à SPEC-024 §4.2 (papel de
publicador dedicado, telas/fluxos separados por Variante, carimbo de Versão aprovada/QC
jurídico de F9, versionamento editorial de F8, contrastes/pegadinhas/flashcards impressos de
F7, reprocessamento de imagem, persistência do PDF gerado, painel estratégico de F10, fila de
produção de F11, geração automática de imagem por IA, preview no navegador) e não são
reabertos aqui.
