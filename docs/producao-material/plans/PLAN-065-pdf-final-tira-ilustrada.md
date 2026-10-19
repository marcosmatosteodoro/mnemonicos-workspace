# PLAN-065: PDF final da tira ilustrada

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.2
**Autor**: scribe (redação delegada pelo Tech Lead; reconhecimento técnico do `code-scout`)
**Data**: 2026-10-18
**Jira**: KAN-237

## Aderência a guidelines

**Decisões irreversíveis do slug tocadas**: nenhuma. A única decisão irreversível do INDEX é DEC-029-003 (snapshot JSON de `ContentVersion`). É **vizinha**, não tocada: este PLAN só **lê** `ContentVersion` (número, `legislativeClosureDate`, aprovação) e acrescenta uma tabela nova que a referencia por FK; nenhuma coluna de `ContentVersion` muda e o snapshot segue gravado a cada fechamento.
**Decisões irreversíveis de outros slugs em conflito**: nenhuma — `infra-vercel: sem bloco de decisões` (pasta `docs/infra-vercel` sem `INDEX.md`). As restrições de plataforma (função única em `api/index.ts`, `vercel.json` memory 1024 / maxDuration 15, corpo de resposta ~4,5 MB) são fatos de ambiente tratados em DEC-065-003, DEC-065-004 e DEC-065-010.
**Exceções aos guidelines**: (1) `require('@pdf-lib/fontkit')` dentro de `embedFinalFonts` (perfil node-22 §1 lista `require` manual entre as construções a evitar) — o runner unitário (`jest` sem `--experimental-vm-modules`) recusa `import()` dinâmico e a carga sob demanda é exigida pelo gate 10 (cold start); aprovador: Tech Lead, gate 6 da wave 2; **remover quando** o runner unitário rodar com `--experimental-vm-modules` (como o de integração), voltando a `await import()`. (2) A **supersessão de NFR-024-004** (não recodificar imagem) só no modo final, já autorizada pela SPEC (A-064-001/A-064-003) e registrada em DEC-065-004. Dependências novas (`@pdf-lib/fontkit`, `sharp`, fonte Noto Sans) passam pelo gate 8 (supply chain) e gate 10 (tamanho/tempo).

## Cobertura

**SPEC referenciada**: SPEC-064
**Slice declarado**: cobertura total restante (Caso D — nenhum PLAN anterior cobre FRs/NFRs da SPEC-064)

**FRs cobertos**:
- FR-064-001
- FR-064-002
- FR-064-003
- FR-064-004
- FR-064-005
- FR-064-006
- FR-064-007
- FR-064-008
- FR-064-009
- FR-064-010
- FR-064-011
- FR-064-012
- FR-064-013
- FR-064-014
- FR-064-015
- FR-064-016
- FR-064-017
- FR-064-018
- FR-064-019
- FR-064-020
- FR-064-021
- FR-064-022
- FR-064-023
- FR-064-024
- FR-064-025
- FR-064-026
- FR-064-027
- FR-064-028
- FR-064-029
- FR-064-030
- FR-064-031
- FR-064-032
- FR-064-033

**NFRs cobertos**:
- NFR-064-001
- NFR-064-002
- NFR-064-003
- NFR-064-004
- NFR-064-005

## 1. Visão técnica

A entrega acrescenta ao módulo `publication` (backend) um **modo de exportação final** e um **fluxo de publicação com persistência**, e ao frontend o controle, o painel de histórico e a descobribilidade da Biblioteca visual. Quatro frentes, alinhadas às Stories do épico:

1. **Modo final (KAN-244)** — o corpo de `POST /contents/:id/publication` ganha `mode?: 'DRAFT' | 'FINAL'` (default `DRAFT`). Ausente ou `DRAFT` percorre exatamente o caminho de hoje (rascunho byte a byte inalterado, `pdf-composer.ts` sem edição). `FINAL` só aceita Variante `TIRA` (422 para `RESUMO`) e exige Versão aprovada e válida, reusando `resolveVersionStampForPdf`/`approvedAndValid`; sem isso, recusa 409 com `code` próprio, no servidor. Um `GET /contents/:id/publication/final-preview` devolve elegibilidade, cobertura N/M e avisos, sem efeito colateral.
2. **Diagramação (KAN-245)** — compositor novo e separado (`final-pdf-composer.ts`): capa, um Quadro por página com imagem dominante, rodapé de versão e numeração, fonte Noto Sans embutida via `@pdf-lib/fontkit`, WEBP convertido para PNG com `sharp`. Aviso de resolução no upload (`warnings` na resposta de `POST /visual-associations`).
3. **Publicação (KAN-246)** — tabela nova `published_pdfs` (aditiva), atrás de uma interface `PublishedPdfStore`; três rotas (`POST`/`GET /contents/:id/publications`, `GET …/:publicationId/pdf`); flags `acknowledgeIncomplete`/`acknowledgeRepublish` impostas no servidor.
4. **Descobribilidade (KAN-247)** — indicador "N de M quadros com imagem" derivado no cliente, link do estado vazio do seletor para `/visual-library?returnTo=…` com volta validada contra open redirect, seção no Guia de uso.

**Desenho sobre o reconhecimento do `code-scout`** (memo `exploration-producao-material.md`): a função é única (`api/index.ts` importa `../src` direto, sem `dist`; `tsconfig.build.json` só compila `.ts`), com `maxDuration` 15 s e memória 1024 MB; `@node-rs/argon2` já prova binário nativo em produção; a Associação visual não tem largura/altura no banco (`VisualAssociation.imageData` Bytes sem dimensões); vincular/desvincular imagem emite só `ASSOCIACAO_VISUAL`, que o sinal de alteração pós-fechamento não lê (`TIRA_MNEMONICA`), logo trocar imagem **não** invalida a aprovação (A-064-009, confirmado por leitura em `tira.service.ts` e `content-versions.service.ts`). Acervo de dev medido: 0 associações (0 WEBP); produção não medível — por isso WEBP precisa aparecer no final (Q-064-001), não ser recusado no upload.

**Premissas desta execução**:

- **A-065-001** [assumido] [evidência: crença] O modo final, o preview e a publicação **não autogeram a Tira**: leem a Tira existente sem `openMnemonicStrip` (um `GET` de preview não pode ter efeito colateral, e o rascunho continua autogerando como hoje). Tira inexistente ou sem Quadros → `NothingToExportError` (409, herdado). Risco: Conteúdo aprovado sem Tira aberta não consegue exportar o final até a tira ser aberta; improvável, pois a Tira participa do fechamento da Versão. `Reabrir se:` o gate 9 mostrar Versão aprovada sem Tira.
- **A-065-002** [assumido] [evidência: crença] A numeração "página X de Y" aparece em **toda** página, inclusive a capa (a capa é a página 1), e Y conta a capa. Risco: preferência de Produtos por capa sem número; ajuste de layout barato, decidido no gate 11.
- **A-065-003** [assumido] [evidência: crença] Teto do PDF final = 4.000.000 bytes (margem sob o corpo de resposta ~4,5 MB da Vercel; DEC-065-010). Risco: tira real com imagens grandes passa do teto e a publicação é recusada com motivo; mitigação e condição de reabertura em DEC-065-010/TRISK-065-001.

**Sequência de entrega sugerida (para `/keelson:tasks`)**: KAN-244 (COMP-065-001, -006, -007 e tipos) → KAN-245 (COMP-065-002 a -005, -012, -018) → KAN-246 (COMP-065-008 a -011, -015) ; KAN-247 (COMP-065-016, -017, -019) independente das demais. COMP-065-006 depende do compositor final (COMP-065-005): a divisão em ondas decide como o modo final fica exercitável antes da diagramação completa.

## 2. Stack e dependências

- **Herdado, sem mudança**: Node 22, Express 5, Prisma 7 (`@prisma/adapter-pg`), Postgres, Zod 4, `pdf-lib` ^1.17.1, `multer`, Jest 30 + `supertest`; frontend Next 16, React 19, RTK Query, Tailwind 4, Jest + Testing Library.
- **Backend — dependências novas** (gate 8 e gate 10):
  - `@pdf-lib/fontkit` — registra fonte TrueType customizada no `pdf-lib` (`doc.registerFontkit`, `embedFont(bytes, { subset: true })`). Puro JS. Observação de supply chain: a série 1.1.x não recebe release há anos (o próprio `pdf-lib` também); versão fixada exata no `package.json` (perfil node-22 §8).
  - `sharp` — converte WEBP em PNG e lê dimensões de WEBP. Binário nativo (prebuilt via pacotes opcionais `@img/sharp-*`, sem `postinstall` de compilação), precedente `@node-rs/argon2`. A libvips embarcada é LGPL-3 (binário dinâmico por pacote, não linkado ao nosso código): conferir licença no gate 8.
- **Backend — assets novos**: Noto Sans Regular e Bold (licença SIL OFL 1.1), versionados como módulos `.ts` gerados em base64 (DEC-065-003), com `OFL.txt` e nota de origem no repositório.
- **Variável de ambiente nova** (`src/config/env.ts`, `.env.example`, `tests/setup-env.ts`): `PUBLICATION_FINAL_PDF_MAX_BYTES` (default `4000000`, DEC-065-010).
- **Frontend**: nenhuma dependência nova. `useSearchParams` não é usado; o `returnTo` é lido pelo Server Component via `searchParams` (DEC-065-009).
- **Banco**: uma tabela nova aditiva (§5), migração via `prisma migrate dev` com arquivo versionado no diff da TASK; a execução nos bancos locais dev e test é autorizada pelo Diretor (só CREATE TABLE/índices/FK novos).

## 3. Componentes

### COMP-065-001: Elegibilidade do modo final e schema de exportação (`publication.schema.ts` + `final-eligibility.ts`)
**Responsabilidade**: (a) emenda do schema Zod do corpo de `POST /contents/:id/publication` com `mode: z.enum(['DRAFT','FINAL']).default('DRAFT')`, mantendo `variant`; (b) função pura `evaluateFinalEligibility(variant, versionStamp)` que decide, sem I/O, entre elegível e as recusas: `RESUMO` → `FinalModeTiraOnlyError` (422, `code: FINAL_MODE_TIRA_ONLY`); sem Versão ou sem aprovação → 409 `FINAL_EXPORT_NOT_ELIGIBLE` com `reason: NO_APPROVED_VERSION`; Versão de maior número alterada após o fechamento → 409 `FINAL_EXPORT_NOT_ELIGIBLE` com `reason: ALTERED_AFTER_CLOSURE`. A regra de "aprovada e válida" é a existente (`approvedAndValid`), não redefinida. Os tipos `PublicationMode` e os `code`s entram em `src/domain/types.ts` (espelho no frontend, COMP-065-013). Reusada por exportação final, preview e publicação (COMP-065-010), para uma única fonte da recusa.
**Realiza**: FR-064-002, FR-064-005, NFR-064-001
**Interface pública**:
```ts
export const PUBLICATION_MODES = ['DRAFT', 'FINAL'] as const;
export type PublicationMode = (typeof PUBLICATION_MODES)[number];

export type FinalIneligibleReason = 'NO_APPROVED_VERSION' | 'ALTERED_AFTER_CLOSURE';
export type FinalEligibility =
  | { eligible: true; version: { id: string; number: number; legislativeClosureDate: Date } }
  | { eligible: false; reason: FinalIneligibleReason };

export function evaluateFinalEligibility(
  variant: PublicationVariant,
  stamp: VersionStampForPdf | null,
): FinalEligibility; // lança FinalModeTiraOnlyError quando variant !== 'TIRA'
```
**Dependências**: nenhuma

### COMP-065-002: Cobertura da tira e Aviso de exportação (`strip-coverage.ts`, função pura)
**Responsabilidade**: dado o resultado da preparação de imagem por Quadro (COMP-065-003), calcula `framesTotal` (M), `framesWithImage` (N) e a lista de `warnings[{position, kind}]` com `kind ∈ MISSING_IMAGE | IMAGE_NOT_EMBEDDABLE | BELOW_RECOMMENDED_RESOLUTION`. Um Quadro com imagem que entrou **e** abaixo da resolução conta em N e gera o aviso informativo; `MISSING_IMAGE` e `IMAGE_NOT_EMBEDDABLE` não contam em N. Exporta a constante `RECOMMENDED_LONG_SIDE_PX = 2000` (DEC-065-005), consumida também pelo aviso de upload (COMP-065-012). Sem I/O: a mesma função alimenta preview, composição e publicação.
**Realiza**: FR-064-013, FR-064-029, FR-064-030
**Interface pública**:
```ts
export const RECOMMENDED_LONG_SIDE_PX = 2000;
export type ExportWarningKind = 'MISSING_IMAGE' | 'IMAGE_NOT_EMBEDDABLE' | 'BELOW_RECOMMENDED_RESOLUTION';
export interface ExportWarning { position: number; kind: ExportWarningKind }
export interface StripCoverage { framesTotal: number; framesWithImage: number; warnings: ExportWarning[] }

export function computeStripCoverage(
  frames: readonly { position: number; image: PreparedImageResult }[],
): StripCoverage; // warnings ordenados por position, depois por kind
```
**Dependências**: COMP-065-003

### COMP-065-003: Preparo de imagem para o PDF final (`final-image.ts`)
**Responsabilidade**: por Quadro, transforma o binário vinculado em imagem embutível ou em motivo de falha, **sem confiar no `mimeType` armazenado** (usa `detectImageSignature`). PNG/JPEG passam **sem recodificar**, com dimensões de `readImageDimensions`; WEBP é convertido com `sharp` (`animated: false`, primeiro quadro; `limitInputPixels` = orçamento herdado de 20 M px; `failOn: 'error'`) — opaco → JPEG q85, com alfa → PNG (emenda da DEC-065-004) — e imagens acima de `RECOMMENDED_LONG_SIDE_PX` são reduzidas no modo final; as dimensões de WEBP vêm de `readWebpDimensions` (cabeçalho, `image-signature.ts`); APNG, estouro do orçamento de pixels e falha de decodificação/embedding viram `IMAGE_NOT_EMBEDDABLE` (nunca exceção que derrube a exportação). `inspectHeader` é a fonte única das recusas por cabeçalho; `prepareFrameImage(doc, input)` embute no `PDFDocument` real com `await image.embed()` ansioso (o deflate sai do `save()`); o **preview** NÃO chama `prepareFrameImage` — classifica só pelo cabeçalho (`classifyImageByHeader`, emenda da DEC-065-006) e a cobertura autoritativa pós-exportação vem de `X-Final-Pdf-Coverage` (TRISK-065-010). Binários carregados em lotes (`streamFinalFrames`) e a mesma Associação reusa o mesmo `PDFImage` (TRISK-065-005). Nenhuma chamada de rede.
**Realiza**: FR-064-012, NFR-064-005
**Interface pública**:
```ts
export type PreparedImageResult =
  | { status: 'none' }                                                    // Quadro sem Associação visual
  | { status: 'failed'; reason: 'apng' | 'decode-failed' | 'pixel-budget-exceeded' | 'unsupported' }
  | { status: 'ok'; embedded: PDFImage; widthPx: number; heightPx: number; convertedFrom?: 'WEBP' };

export async function prepareFrameImage(
  doc: PDFDocument,
  input: { buffer: Buffer } | null,
): Promise<PreparedImageResult>;

export function readWebpDimensions(buffer: Buffer): { width: number; height: number } | null; // leitura de cabeçalho VP8/VP8L/VP8X (image-signature.ts), usado no upload, no preview e na exportação
```
**Dependências**: nenhuma

### COMP-065-004: Fonte embutida (`final-pdf-font.ts` + módulos de fonte + OFL)
**Responsabilidade**: carrega Noto Sans Regular e Bold a partir de módulos `.ts` com o binário em base64 (gerados por script versionado, a partir de uma fonte pré-reduzida a Basic Latin, Latin-1, Latin Extended-A e pontuação geral — travessão, aspas curvas, reticências, euro), registra o `fontkit` no documento e embute com `subset: true`. Função pura `sanitizeForFont(text, font)` troca por `?` apenas caracteres sem glifo (fora do português; acentos, `—`, `“ ”`, `‘ ’` nunca são trocados). Inclui `OFL.txt` e nota de origem/versão da fonte no repositório. Texto do usuário só chega à página como string literal via `drawText` (NFR-024-002 por construção).
**Realiza**: FR-064-011
**Interface pública**:
```ts
export interface FinalFonts { regular: PDFFont; bold: PDFFont; hasGlyph(char: string): boolean }
export async function embedFinalFonts(doc: PDFDocument): Promise<FinalFonts>; // registerFontkit + embedFont(subset)
export function sanitizeForFont(text: string, hasGlyph: (c: string) => boolean): string;
```
**Dependências**: nenhuma

### COMP-065-005: Compositor do PDF final (`final-pdf-composer.ts`)
**Responsabilidade**: `buildFinalStripPdf` — módulo próprio; `pdf-composer.ts` do rascunho **não é editado**. Layout (proposta sob gate 11, A-064-004; página A4 como no rascunho): **capa** (página 1) com Disciplina, Tópico, "Versão N" e "Legislação verificada até DD/MM/AAAA", sem "RASCUNHO", sem Variante, sem "Gerado em"; **um Quadro por página**, na ordem da Tira: caixa de imagem de **480 × 400 pt** centralizada no topo da área útil (largura útil de 480 pt, margem lateral ≈ 57,6 pt; escala só para reduzir, nunca amplia; proporção preservada), texto do Quadro abaixo em Noto Sans Regular (corpo ≈ 14 pt, quebra de linha por `wrapTextToLines`, PLAN-025), número do Quadro em Bold; **rodapé** em toda página de Quadro: "Versão N — legislação verificada até DD/MM/AAAA" (data em UTC, mesma função de formatação do rascunho) e "página X de Y" (A-065-002). Quadro sem imagem ou com imagem que não entrou sai só com o texto, na mesma diagramação, sem lacuna quebrada. A numeração é desenhada depois de todas as páginas existirem (Y conhecido). Falha segura herdada: o `Buffer` só nasce em `save()` com o documento completo. Devolve também a cobertura (COMP-065-002) calculada com as mesmas imagens que desenhou.
**Realiza**: FR-064-001, FR-064-004, FR-064-008, FR-064-009, FR-064-010, NFR-064-004
**Interface pública**:
```ts
export interface FinalStripFrame { position: number; text: string; binary: { buffer: Buffer } | null }
export interface FinalPdfMeta {
  disciplineName: string;
  topicName: string;
  version: { number: number; legislativeClosureDate: Date };
}
export interface FinalPdfResult { buffer: Buffer; pageCount: number; coverage: StripCoverage }

export async function buildFinalStripPdf(
  frames: readonly FinalStripFrame[],
  meta: FinalPdfMeta,
): Promise<FinalPdfResult>;
```
**Dependências**: COMP-065-002, COMP-065-003, COMP-065-004

### COMP-065-006: Serviço de exportação — modo final e preview (emenda em `publication.service.ts`)
**Responsabilidade**: `exportPublication` passa a receber `mode`. `DRAFT` (ou ausente) → caminho atual inalterado, nome `${id}-${variant}-rascunho.pdf`. `FINAL` → `assertRawContentExportable` → `resolveVersionStampForPdf` → `evaluateFinalEligibility` (recusa antes de gerar qualquer byte) → leitura das Quadros **sem autogerar a Tira** (A-065-001) e dos binários de imagem → disciplina/tópico do Conteúdo → `buildFinalStripPdf` sob `withDeadline` (herdado, 12 s) → verificação do teto de tamanho (DEC-065-010) → mesma `$transaction` de eventos do rascunho (`PUBLICACAO_PDF` + `PublicationEvent`) → nome `${id}-TIRA-v${N}-final.pdf`. Novo `getFinalPreview(rawContentId)`: leitura sem efeito colateral que devolve `{ eligible, reason?, version?, framesTotal, framesWithImage, warnings, latestPublication? }`, usando `prepareFrameImage` com documento descartável e `computeStripCoverage` (sem compor nem salvar). Extrai o carregamento de Quadros+binários+metadados como função interna `loadFinalExportInput` reusada pela publicação (COMP-065-010).
**Realiza**: FR-064-001, FR-064-003, FR-064-004, FR-064-013, NFR-064-001
**Interface pública**:
```ts
export async function exportPublication(input: {
  rawContentId: string; variant: PublicationVariant; mode: PublicationMode; actor: SessionUser;
}): Promise<{ buffer: Buffer; filename: string; contentType: 'application/pdf' }>;

export interface FinalPreview {
  eligible: boolean;
  reason?: FinalIneligibleReason | 'NO_STRIP';
  version?: { number: number; legislativeClosureDate: string };
  framesTotal: number; framesWithImage: number; warnings: ExportWarning[];
  latestPublication?: { id: string; versionNumber: number; publishedAt: string };
}
export async function getFinalPreview(rawContentId: string): Promise<FinalPreview>;

export async function loadFinalExportInput(rawContentId: string): Promise<FinalExportInput>; // interno ao módulo
```
**Dependências**: COMP-065-001, COMP-065-002, COMP-065-003, COMP-065-005

### COMP-065-007: Rotas de exportação — modo final e preview (emenda em `publication.routes.ts`)
**Responsabilidade**: `POST /contents/:id/publication` passa o `mode` validado ao serviço (resposta `application/pdf` attachment com o nome devolvido pelo serviço); nova `GET /contents/:id/publication/final-preview` (sem `verifyOrigin`, por ser leitura), ambas atrás de `requireRole` EDITOR/ADMIN; sem sessão → 401, STUDENT → 403, conteúdo removido → 404. Registro na barreira deny-by-default e atualização do tripwire `route-authz-matrix` (contagem confirmada na TASK). Ordem de guardas inalterada: `verifyOrigin` (mutação) → `requireRole` → schema → serviço.
**Realiza**: FR-064-007, NFR-064-001
**Interface pública**: `POST /contents/:id/publication` body `{ variant, mode? }`; `GET /contents/:id/publication/final-preview` → `FinalPreview` (COMP-065-006). Erros: `{ error: { code, ... } }` pelo `error-handler` existente.
**Dependências**: COMP-065-001, COMP-065-006

### COMP-065-008: Modelo de dados — `PublishedPdf` + migração aditiva
**Responsabilidade**: model Prisma `PublishedPdf` (detalhe em §5) e migração `prisma/migrations/<ts>_add_published_pdf/migration.sql` contendo só `CREATE TABLE`, índices e FKs novos. Nenhuma tabela/coluna existente é alterada. A migração entra no diff da TASK; aplicar nos bancos locais dev e test é autorizado pelo Diretor (a TASK confirma antes de executar `migrate dev`).
**Realiza**: NFR-064-002, NFR-064-003
**Interface pública**: model Prisma (§5); relações inversas `RawContent.publishedPdfs`, `ContentVersion.publishedPdfs`, `User.publishedPdfs`.
**Dependências**: nenhuma

### COMP-065-009: `PublishedPdfStore` — porta e implementação Prisma
**Responsabilidade**: interface do módulo que isola onde os bytes moram (hoje Postgres; troca barata se o Diretor unificar com o storage S3 do KAN-236 — SPEC-061/PLAN-063, citados em prosa). **Só expõe `insert`, `list`, `getBytes` e `findLatestForVersion`: nenhum `update`/`delete`** (imutabilidade por construção, NFR-064-003; provada por teste estrutural e comportamental). `list` seleciona explicitamente as colunas sem `pdfData`. O `insert` aceita um `tx` Prisma para participar da `$transaction` do serviço. Toda leitura por `id` exige também `rawContentId` (previne IDOR: publicação de outro conteúdo → não encontrada).
**Realiza**: FR-064-018, FR-064-021, NFR-064-003
**Interface pública**:
```ts
export interface PublishedPdfRecord {
  id: string; rawContentId: string; contentVersionId: string; versionNumber: number;
  byteSize: number; sha256: string; pageCount: number;
  framesTotal: number; framesWithImage: number;
  publishedById: string; publishedByName: string; publishedAt: Date;
}
export interface PublishedPdfStore {
  insert(tx: PrismaTx, data: NewPublishedPdf): Promise<PublishedPdfRecord>;
  list(rawContentId: string): Promise<PublishedPdfRecord[]>; // publishedAt desc, id desc; sem bytes
  getBytes(rawContentId: string, publicationId: string): Promise<{ record: PublishedPdfRecord; pdfData: Buffer } | null>;
  findLatestForVersion(tx: PrismaTx, rawContentId: string, contentVersionId: string): Promise<{ publishedAt: Date } | null>;
}
export const prismaPublishedPdfStore: PublishedPdfStore;
```
**Dependências**: COMP-065-008

### COMP-065-010: Serviço de publicação (`published-pdf.service.ts`)
**Responsabilidade**: `publishFinalPdf`: `assertRawContentExportable` → elegibilidade (COMP-065-001) → `loadFinalExportInput` → `buildFinalStripPdf` sob `withDeadline` → teto de tamanho (DEC-065-010) → **regras no servidor** sobre a cobertura **do PDF efetivamente composto**: se N < M e `acknowledgeIncomplete !== true` → 409 `INCOMPLETE_COVERAGE_ACK_REQUIRED` com `details {framesTotal, framesWithImage, warnings}`; se a mesma Versão já tem publicação e `acknowledgeRepublish !== true` → 409 `REPUBLISH_ACK_REQUIRED` com `details {versionNumber, lastPublishedAt}` → `$transaction` única com **re-verificação** de elegibilidade (a Versão pode ter sido alterada durante a geração), `store.insert` (sha256, tamanho, `pageCount`, N, M, `publishedById`, `publishedAt = now`) e evento `PUBLICACAO_PDF`. Geração/gravação falhou → a transação reverte, nada fica no histórico (FR-064-024). Duas publicações simultâneas são dois `INSERT` independentes e completos (sem lock); a checagem de "mesma Versão" não serializa por desenho (A-064-005 aceita dois registros). `listPublications` marca `current` no registro de maior `publishedAt` (desempate por `id`). `getPublicationPdf` devolve os bytes gravados, sem regerar. Conteúdo removido → `NotFoundError` nas três.
**Realiza**: FR-064-016, FR-064-017, FR-064-018, FR-064-019, FR-064-020, FR-064-021, FR-064-024, FR-064-030, FR-064-031, FR-064-033, NFR-064-001, NFR-064-002
**Interface pública**:
```ts
export async function publishFinalPdf(input: {
  rawContentId: string; actor: SessionUser; now: Date;
  acknowledgeIncomplete: boolean; acknowledgeRepublish: boolean;
}): Promise<PublicationListItem>;

export interface PublicationListItem {
  id: string; versionNumber: number; publishedAt: string;
  publishedBy: { id: string; name: string };
  framesTotal: number; framesWithImage: number; byteSize: number; current: boolean;
}
export async function listPublications(rawContentId: string): Promise<PublicationListItem[]>;
export async function getPublicationPdf(rawContentId: string, publicationId: string):
  Promise<{ buffer: Buffer; sha256: string; filename: string }>;
```
**Dependências**: COMP-065-001, COMP-065-002, COMP-065-005, COMP-065-006, COMP-065-009

### COMP-065-011: Rotas de publicação (`published-pdf.routes.ts` + schema Zod)
**Responsabilidade**: `POST /contents/:id/publications` (`verifyOrigin` + `requireRole` EDITOR/ADMIN; corpo Zod `{ acknowledgeIncomplete?: boolean, acknowledgeRepublish?: boolean }`, default `false`; 201 com `PublicationListItem`); `GET /contents/:id/publications` (lista, sem bytes); `GET /contents/:id/publications/:publicationId/pdf` (`Content-Type: application/pdf`, `Content-Disposition: attachment`, `ETag: "<sha256>"`, `Cache-Control: private`; bytes gravados como estão). Params validados como UUID. Alcance comum a EDITOR/ADMIN, sem restrição por autoria (AC-024-018); `publicationId` de outro conteúdo → 404; sem sessão → 401; STUDENT → 403. Registro na barreira deny-by-default e no tripwire `route-authz-matrix` (as 3 rotas novas, mais a de preview do COMP-065-007).
**Realiza**: FR-064-023, FR-064-032, FR-064-033
**Interface pública**: as três rotas acima; corpo/erros descritos; `code`s de 409 listados no COMP-065-010.
**Dependências**: COMP-065-010

### COMP-065-012: Aviso de resolução no upload (emenda em `visual-associations`)
**Responsabilidade**: ao criar a Associação visual, lê as dimensões (`readImageDimensions` para PNG/JPEG; `readWebpDimensions` para WEBP) e, se o lado maior for menor que `RECOMMENDED_LONG_SIDE_PX` (2000 px), a resposta de `POST /visual-associations` ganha `warnings: [{ code: 'BELOW_RECOMMENDED_RESOLUTION', recommendedLongSidePx: 2000, widthPx, heightPx }]`. O envio **nunca** é recusado por resolução; dimensão ilegível não gera aviso nem erro. Guardas de sessão/papel/origem do upload permanecem exatamente as existentes (SPEC-022): o aviso não abre exceção. `warnings` é `[]` quando não há aviso. Sem coluna nova de dimensões (as dimensões são calculadas no ato; o acervo antigo é coberto pelo preview, FR-064-029).
**Realiza**: FR-064-014, FR-064-015
**Interface pública**: `POST /visual-associations` → `201 { …associação, warnings: UploadWarning[] }` (campo aditivo; clientes antigos o ignoram).
**Dependências**: COMP-065-002, COMP-065-003

### COMP-065-013: RTK Query e tipos espelhados (`store/api.ts`, `types/domain.ts`)
**Responsabilidade**: espelho no frontend de `PublicationMode`, `FinalPreview`, `ExportWarning`, `PublicationListItem`, `UploadWarning` e dos `code`s de erro (no mesmo diff do backend). `exportPublication` aceita `mode`. Endpoints novos: `getFinalPreview` (query, tag `PublishedPdfPreview`), `listPublications` (query, tag `PublishedPdfList`), `publishFinalPdf` (mutation que **invalida** `PublishedPdfList` e `PublishedPdfPreview`), `downloadPublicationPdf` (binário por `responseHandler`, mesmo padrão de `publicationResponseHandler`). A criação de Associação visual passa a expor `warnings` ao chamador. Erros 409 de confirmação chegam à tela com `code` e `details` tipados.
**Realiza**: FR-064-006, FR-064-022
**Interface pública**: hooks `useGetFinalPreviewQuery`, `useListPublicationsQuery`, `usePublishFinalPdfMutation`, `useLazyDownloadPublicationPdfQuery` (ou mutation equivalente, escolha da TASK pelo padrão do `exportPublication`).
**Dependências**: COMP-065-007, COMP-065-011, COMP-065-012

### COMP-065-014: `PublicationExportControl` — ação "Exportar PDF final" e Aviso de exportação
**Responsabilidade**: na variante "tira", o controle ganha o botão "Exportar PDF final" ao lado do rascunho. Desabilitado, com explicação visível, quando o preview traz `eligible: false` (sem versão aprovada / alterado após o fechamento / sem tira). Os três estados (em andamento com indicador e controle desabilitado; sucesso com download; falha com o motivo da recusa, sem perder a seleção). Ao concluir, renova o preview e exibe o **Aviso de exportação** (lista de Quadros por posição, distinguindo "sem imagem", "imagem que não entrou" e a informativa "imagem abaixo da resolução recomendada (2000 px)"). "Resumo" não oferece o modo final. O rascunho segue idêntico. Texto de UI em pt-BR.
**Realiza**: FR-064-006, FR-064-013
**Interface pública**: props existentes `{ rawContentId, leadingActions?, trailingActions?, belowBar? }` + `showFinalExport?: boolean` (ligado só no enxerto da tela da tira).
**Dependências**: COMP-065-013

### COMP-065-015: Painel "PDFs publicados" e diálogo de confirmação (`published-pdfs-panel.tsx`)
**Responsabilidade**: na tela da tira, lista os PDFs publicados (Versão, data, autor, "N de M quadros com imagem", marca "atual", ação "Baixar") do mais recente ao mais antigo, e o botão "Publicar PDF final". Ao acionar, abre diálogo (`role="alertdialog"`, padrão do board) com "N de M quadros com imagem" e o Aviso de exportação do preview; N < M exige marcar/confirmar explicitamente; se a Versão já tem publicação, mostra "esta Versão já tem PDF publicado em <data>; publicar outro?" e envia `acknowledgeRepublish`. Cancelar não chama o servidor. Se o servidor devolver 409 de confirmação (cobertura recalculada), o diálogo reabre com os detalhes autoritativos. Três estados em publicar e em baixar (indicador/desabilitado, sucesso, erro com motivo). A regra é do servidor; a tela só espelha.
**Realiza**: FR-064-019, FR-064-020, FR-064-022, FR-064-030
**Interface pública**: `<PublishedPdfsPanel rawContentId={string} />` (client component).
**Dependências**: COMP-065-013, COMP-065-014

### COMP-065-016: Indicador de cobertura da tira (enxerto em `mnemonic-strip-board.tsx`)
**Responsabilidade**: função pura `countFramesWithImage(frames)` (N = quadros com `visualAssociationId`, M = total) e texto "N de M quadros com imagem" acima do controle de exportação, derivado dos frames já em cache da query `MnemonicStrip`; atualiza ao vincular/desvincular porque as mutações existentes já invalidam a tag. Monta o `PublishedPdfsPanel` no mesmo ponto. Sem requisição nova.
**Realiza**: FR-064-027
**Interface pública**: `countFramesWithImage(frames: readonly { visualAssociationId: string | null }[]): { withImage: number; total: number }`
**Dependências**: COMP-065-015

### COMP-065-017: Atalho do seletor vazio e volta da Biblioteca visual
**Responsabilidade**: (a) no estado vazio de `visual-association-picker.tsx`, link "Ir para a Biblioteca visual" para `/visual-library?returnTo=<caminho da tira, codificado>`; (b) função pura `parseSafeReturnTo(value)` que só aceita o padrão `^/content/<uuid>/tira$` (sem esquema, sem `//`, sem `\`, sem query/fragmento, comprimento limitado) — qualquer outro valor devolve `null`; (c) `visual-library/page.tsx` (Server Component) lê `searchParams` (Promise no Next 16), valida com `parseSafeReturnTo` e repassa ao board apenas o `backHref` já validado; (d) o board mostra "Voltar para a tira" **somente** com `backHref` válido. Nunca redireciona automaticamente, nunca usa o valor cru em `href`.
**Realiza**: FR-064-025, FR-064-026
**Interface pública**: `parseSafeReturnTo(value: string | string[] | undefined): string | null`; `<VisualLibraryBoard backHref?: string />`.
**Dependências**: nenhuma

### COMP-065-018: Aviso de resolução na Biblioteca visual (frontend)
**Responsabilidade**: após o envio bem-sucedido no `VisualLibraryCreateForm`, se a resposta traz `warnings` com `BELOW_RECOMMENDED_RESOLUTION`, exibe aviso não bloqueante citando o valor ("Imagem com X × Y px; recomendado: lado maior de 2000 px para boa impressão") e mantém o item criado. Sem aviso quando `warnings` é vazio. Texto em pt-BR, `role="status"`.
**Realiza**: FR-064-014
**Interface pública**: sem API nova — comportamento do formulário; consome `UploadWarning` (COMP-065-013).
**Dependências**: COMP-065-013

### COMP-065-019: Guia de uso (`docs/GUIA-DE-USO.md` do workspace)
**Responsabilidade**: nova seção "Como ilustrar uma tira e gerar o PDF" (ilustrar via Biblioteca visual e seletor, indicador N de M, exportar rascunho × final, Aviso de exportação, Resolução recomendada de 2000 px no lado maior, publicar, histórico e "atual", confirmação de republicar); ajuste do §4 (WebP: no rascunho segue sem aparecer; no final aparece) e do §6 (modos de exportação); atualização da data de "Última atualização". Parte da closure da TASK, conforme o `CLAUDE.md` do workspace.
**Realiza**: FR-064-028
**Interface pública**: documento Markdown.
**Dependências**: nenhuma

## 4. Fluxos principais

**Exportar PDF final** — EDITOR/ADMIN abre a tira → a tela consulta o preview (`GET …/final-preview`): inelegível → botão desabilitado com o motivo; elegível → habilitado. Clique → `POST /contents/:id/publication {variant:'TIRA', mode:'FINAL'}` → `verifyOrigin` → `requireRole` → schema → `assertRawContentExportable` → versão (maior número) → `evaluateFinalEligibility` (recusa 409/422 antes de gerar) → carga de Quadros+binários → `prepareFrameImage` por Quadro (WEBP→PNG) → `buildFinalStripPdf` sob `withDeadline` → teto de tamanho → `$transaction` de eventos → resposta `application/pdf` attachment `…-final.pdf`. Ao concluir, a tela renova o preview e mostra o Aviso de exportação.

**Preview** — `GET …/final-preview`: mesma elegibilidade; classificação por **cabeçalho** (`classifyImageByHeader`, emenda da DEC-065-006) e a mesma `computeStripCoverage` — é **pré-checagem** (corpo corrompido só aparece na exportação); nada é composto, salvo ou emitido como evento. **A cobertura autoritativa vem da exportação**: o `POST` final devolve `{framesTotal, framesWithImage, warnings}` no cabeçalho de resposta `X-Final-Pdf-Coverage` (JSON), e o aviso pós-exportação da tela o lê.

**Publicar** — clique em "Publicar PDF final" → diálogo com N de M e Aviso (do preview) → confirmação (obrigatória se N < M; "republicar" se a Versão já tem PDF) → `POST …/publications {acknowledgeIncomplete, acknowledgeRepublish}` → elegibilidade → geração → o servidor aplica as regras dos flags sobre a cobertura do PDF composto (409 com `code` e `details` se faltar confirmação; nada é gravado) → `$transaction` (re-verifica elegibilidade, `INSERT` em `published_pdfs`, evento `PUBLICACAO_PDF`) → 201 com o item → a mutation invalida `PublishedPdfList`.

**Listar e baixar** — `GET …/publications` (sem bytes) → painel ordenado por `publishedAt` desc, `current` no primeiro; `GET …/publications/:publicationId/pdf` devolve `pdfData` exatamente como gravado (ETag = sha256). Cada download é idêntico ao anterior por não haver regeração.

**Upload com aviso** — `POST /visual-associations` (guardas inalteradas) → dimensões → `warnings` na resposta → o formulário exibe o aviso e mantém o item.

**Ilustrar a partir do seletor vazio** — estado vazio do seletor → link `/visual-library?returnTo=/content/<id>/tira` → a página (servidor) valida o `returnTo` → "Voltar para a tira" só para caminho interno válido → o indicador N de M atualiza após vincular (tag `MnemonicStrip`).

**Estratégia de prova** (testes obrigatórios por tipo): *unitário puro* — `evaluateFinalEligibility`, `computeStripCoverage` (as três categorias; contagem de N), `parseSafeReturnTo` (aceita só o padrão; rejeita `//`, `https://`, `\`, `javascript:`, vazio, array), `sanitizeForFont`, `countFramesWithImage`, texto de rodapé/capa, fonte com acentos/travessão/aspas curvas sem exceção. *Integração com Postgres real* — rascunho inalterado (testes existentes do rascunho seguem verdes sem alteração, comparação byte a byte do rascunho antes/depois); modo final sem marcas (`pdftotext`/texto decodificado: sem "RASCUNHO", "Variante", "Gerado em"; presença do rodapé e do nome sem "rascunho"); recusas 401/403/404/409/422; `WEBP_FIXTURE_BUFFER` aparece no PDF final (contagem de XObject de imagem) e **não** aparece no rascunho; publicar → listar → baixar duas vezes com `sha256` igual ao gravado; republicar sem/com flag; N < M sem/com flag; Versão nova mantém a antiga intacta; duas publicações concorrentes (dois registros completos ou recusa com motivo); conteúdo removido → 404 nas três e registros permanecem; `publicationId` de outro conteúdo → 404; falha na geração/gravação não deixa registro; texto de Quadro com aparência de marcação/template sai literal; teto de tamanho. *Frontend (Jest + RTL)* — botão final habilitado/desabilitado com explicação; três estados de exportar, publicar e baixar; diálogo de N < M e de republicar; cancelar não chama o servidor; link do estado vazio; "Voltar para a tira" só com `returnTo` válido; indicador N de M reage a vincular/desvincular; aviso de resolução. *Gate 9* — inspeção do PDF por `pdftotext`/extração de imagens e `screen-verify` das telas; conta ADMIN descartável (RISK-064-006).

## 5. Modelo de dados

Tabela nova `published_pdfs`, aditiva:

```prisma
model PublishedPdf {
  id               String         @id @default(uuid())
  rawContentId     String
  rawContent       RawContent     @relation(fields: [rawContentId], references: [id], onDelete: Restrict)
  contentVersionId String
  contentVersion   ContentVersion @relation(fields: [contentVersionId], references: [id], onDelete: Restrict)
  versionNumber    Int
  pdfData          Bytes
  byteSize         Int
  sha256           String
  pageCount        Int
  framesTotal      Int
  framesWithImage  Int
  publishedById    String
  publishedBy      User           @relation(fields: [publishedById], references: [id], onDelete: Restrict)
  publishedAt      DateTime       @default(now())

  @@index([rawContentId, publishedAt(sort: Desc)])
  @@map("published_pdfs")
}
```

(Tipos de `id`/`DateTime` seguem o padrão dos demais models do `schema.prisma`; a TASK confere.) Sem cascata de remoção física: Conteúdo bruto é soft-delete, e `Restrict` impede apagar fisicamente Conteúdo, Versão ou Usuário com PDF publicado. Nenhum `update`/`delete` no código sobre esta tabela. "PDF publicado atual" = maior `publishedAt`, desempate por maior `id`. A listagem nunca seleciona `pdfData`; só o download lê os bytes de uma linha. A métrica da SPEC §1.3 (quem, quando, versão, N, M) é a própria consulta a esta tabela (NFR-064-002). Nenhuma alteração em `PublicationEvent`, `ContentVersion` ou `VisualAssociation`.

## 6. Decisões arquiteturais

### Decisões herdadas
- **DEC-065-011** [herdada] Camadas schema (Zod) → service → routes, nada de Prisma na rota, erro previsto como `AppError`/subclasse, lógica pura sem I/O recebendo `now` por parâmetro — fonte: perfil node-22 §4/§5 e `guidelines/project/backend/README.md`.
- **DEC-065-012** [herdada] Rotas novas atrás de `requireRole` EDITOR/ADMIN, `verifyOrigin` nas mutações, registradas na barreira deny-by-default com o tripwire `route-authz-matrix` atualizado; papéis iguais aos da exportação atual — fonte: SPEC A-064-007/NFR-064-001 e padrão vigente do slug.
- **DEC-065-013** [herdada] Motor de PDF `pdf-lib`, texto do usuário desenhado como string literal por `drawText` (sem camada de template) e nenhuma chamada de rede — fonte: PLAN-025 DEC-025-001 / SPEC NFR-064-004.
- **DEC-065-014** [herdada] Teto de duração interno de 12 s por `withDeadline` (`PUBLICATION_PDF_TIMEOUT_MS`) com `GenerationTimeoutError` 503, sob o `maxDuration` de 15 s — fonte: PLAN-025 DEC-025-002.
- **DEC-065-015** [herdada] Alcance de leitura/exportação comum a EDITOR/ADMIN, sem restrição por autoria (`assertRawContentExportable`) — fonte: PLAN-025 DEC-025-007 / SPEC FR-064-032.
- **DEC-065-016** [herdada] A imagem não faz parte da Versão aprovada: exportar e publicar usam o vínculo do momento; a publicação congela os bytes — fonte: SPEC A-064-009.
- **DEC-065-017** [herdada] "Versão aprovada e válida" é a regra existente (`resolveVersionStampForPdf`/`approvedAndValid`), sem regra nova — fonte: SPEC A-064-006.
- **DEC-065-018** [herdada] PDF publicado em Postgres como bytes, migração só aditiva, executada somente com autorização do Diretor (`prisma migrate dev` gera arquivo versionado no diff) — fonte: SPEC A-064-008 e `CLAUDE.md` do workspace.
- **DEC-065-019** [herdada] Tipos de domínio espelhados à mão em `mnemonicos-backend/src/domain/types.ts` e `mnemonicos-frontend/src/types/domain.ts` no mesmo diff; identificadores em inglês, texto de interface em pt-BR — fonte: `CLAUDE.md` do workspace e READMEs de guideline.
- **DEC-065-020** [herdada] Estado do servidor em RTK Query (`store/api.ts`) com tags de invalidação; download binário por `responseHandler` + `Blob` — fonte: PLAN-025 DEC-025-006 e frontend README.
- **DEC-065-021** [herdada] Server Components por padrão, `'use client'` só com estado/evento, tokens no `@theme` — fonte: frontend README / next-16 §4.
- **DEC-065-022** [herdada] O PDF de rascunho permanece idêntico: `pdf-composer.ts` e a cadeia do rascunho não são editados, os testes existentes seguem verdes sem alteração — fonte: SPEC FR-064-003/AC-064-003.
- **DEC-065-023** [herdada] Orçamento de pixels de 20 M por imagem e recusa de APNG no embedding — fonte: PLAN-025 (`embedFrameImage`, TRISK-025-006).
- **DEC-065-024** [herdada] Testes Jest: unitário puro em `tests/unit`, integração com Postgres real (`mnemonicos_test`) e `supertest`; frontend com Testing Library — fonte: perfil node-22 §7 e next-16 §7.

### DEC-065-001: Modo de exportação como campo opcional `mode` na rota existente
**Contexto**: o rascunho e o final compartilham Variante, guardas (origem, papel, alcance), validação de Versão e o handler que devolve o binário. O rascunho não pode mudar (FR-064-003) e o final precisa de recusas próprias.
**Decisão**: `POST /contents/:id/publication` aceita `mode?: 'DRAFT' | 'FINAL'` (default `DRAFT`). Ausente = comportamento atual. `FINAL` + `RESUMO` → 422 `FINAL_MODE_TIRA_ONLY`; `FINAL` sem Versão aprovada e válida → 409 `FINAL_EXPORT_NOT_ELIGIBLE` com `reason`. Nome do arquivo final: `${id}-TIRA-v${N}-final.pdf` (sem "rascunho"). A recusa vive no serviço (NFR-064-001).
**Alternativas consideradas**:
- Rota nova `POST /contents/:id/publication/final`, descartada porque duplica a cadeia de guardas (`verifyOrigin`, `requireRole`, schema, `assertRawContentExportable`) e o handler de resposta binária; cada correção de segurança futura teria de ser repetida em dois lugares, e o tripwire `route-authz-matrix` ganharia um par a manter.
- Alterar o rascunho para aceitar o rótulo condicional (um compositor só), descartada porque cada flag no `pdf-composer.ts` arrisca quebrar o rascunho byte a byte e os testes existentes, que a SPEC manda manter intactos.
**Consequências**: um contrato de wire aditivo (clientes antigos continuam válidos); a lista de `code`s de erro cresce; o `PublicationEvent` não distingue modo (sem mudança de schema).
**Reabrir se**: o modo final ganhar parâmetros que não fazem sentido no rascunho (ex.: seleção de Quadros, Variante `RESUMO` final), tornando o corpo único ambíguo.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-065-002: Compositor final separado do rascunho, com layout proposto sob gate 11
**Contexto**: o rascunho tem cabeçalho de 4 linhas em toda página, Helvetica (WinAnsi) e caixa de imagem de 300 × 300 pt; o final exige capa, imagem dominante, fonte pt-BR, rodapé e numeração. O layout é proposta do time (A-064-004), revisada pelo `product-designer`.
**Decisão**: novo módulo `final-pdf-composer.ts` (`buildFinalStripPdf`); `pdf-composer.ts` intocado. Layout A4: capa na página 1; cada Quadro começa em página nova e, se o texto excede a página, continua em página(s) de continuação identificada(s) com o número do mesmo Quadro e sem imagem ("página X de Y" conta as páginas reais, com Y calculado após o layout; a quebra de linha parte também palavra sem espaço mais larga que a coluna, por caractere); o PDF final não inclui as páginas suplementares do rascunho (contrastes, flashcards, pegadinha), só capa e Quadros; caixa de imagem **480 × 400 pt** (a largura útil da página, margem lateral ≈ 57,6 pt), centralizada, só reduz, proporção preservada; texto do Quadro abaixo (Noto Sans Regular ≈ 14 pt); rodapé "Versão N — legislação verificada até DD/MM/AAAA" em toda página de Quadro e "página X de Y" em toda página; a capa leva só "página 1 de Y" (ela já traz Versão e data no corpo — emenda pós-gate 5/11 da wave 2, aceita pelo product-designer). Quebra de linha por caractere usa largura aditiva por code point com cache (pós-gate 10 da wave 2: medir o prefixo a cada caractere é O(n²)); a composição recebe um deadline e o checa a cada Quadro e antes do `save()`, sem deixar trabalho órfão depois do 503. Constantes de layout num único bloco no topo do módulo; o `product-designer` confirma ou ajusta no gate 11, e a Resolução recomendada (DEC-065-005) deriva da caixa.
**Alternativas consideradas**:
- Parametrizar o compositor existente por modo (cabeçalho e fonte condicionais), descartada porque acopla o final ao rascunho: cada ajuste de layout final toca o código que deve ficar byte a byte igual, e a prova de "rascunho idêntico" perde força.
- Gerar o final por HTML/headless browser, descartada porque quebra o teto de 15 s / 1024 MB da função e reabre a superfície de SSRF/injeção que DEC-025-001 eliminou.
**Consequências**: parte da lógica de quebra de linha (`wrapTextToLines`) e a formatação de data é reusada, não copiada; dois compositores a manter; layout sujeito a mudança sem afetar o rascunho.
**Reabrir se**: Produtos reprovar a amostra impressa (RISK-064-001) ou o gate 11 pedir mudança de caixa/hierarquia.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-065-003: Fonte Noto Sans embutida via `@pdf-lib/fontkit`, binário em módulo `.ts` base64
**Contexto**: Helvetica padrão só cobre WinAnsi e lança em texto fora dele (TRISK-025-007); o final exige acentos, travessão e aspas curvas (FR-064-011). Não há fonte no repositório. A função importa `../src` direto (sem `dist`), `tsc` não copia assets, e o *file tracing* da Vercel para arquivo não-TS não é verificável por leitura.
**Decisão**: dependência `@pdf-lib/fontkit` (versão fixada exata) e Noto Sans (SIL OFL 1.1) Regular e Bold, embutidas com `subset: true`. O binário é versionado como **módulo `.ts` gerado** (base64 de TTF pré-reduzido a Basic Latin, Latin-1, Latin Extended-A e pontuação geral) por script versionado, `OFL.txt` incluso. Por ser `import` normal, o binário entra no grafo de módulos que a Vercel já compila e empacota — sem depender de *file tracing*.
**Alternativas consideradas**:
- Ler o `.ttf` com `fs` em tempo de execução, descartada porque exige empacotamento de arquivo não-TS na função (`includeFiles`/*file tracing*), não verificável por leitura; se falhar, só se descobre em produção como erro 500 em toda exportação final.
- Manter Helvetica e trocar caracteres fora de WinAnsi, descartada porque contraria FR-064-011 (travessão e aspas curvas viram símbolos substitutos) e AC-064-009.
- Fonte completa sem redução, descartada porque ~1 MB por peso em base64 incha o bundle da função e o cold start sem ganho para português.
**Consequências**: dois módulos de fonte grandes e gerados no repositório (excluídos de lint/format); o `pdf-lib` embute só os glifos usados (`subset: true`), mantendo o PDF pequeno; caractere sem glifo vira `?` (via `sanitizeForFont`).
**Reabrir se**: o tamanho do bundle ou o cold start da função, medidos no gate 10, estourarem o orçamento; ou o build da Vercel rejeitar/engordar o módulo; ou Produtos pedir cobertura além de Latin.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-065-004: WEBP convertido para PNG com `sharp` na geração do PDF final
**Contexto**: o `pdf-lib` só embute PNG/JPEG; o rascunho pula WEBP (NFR-024-004 proíbe recodificar). O final precisa exibir todo vínculo (FR-064-012, Q-064-001), inclusive WEBP já existente no acervo, e a Resolução recomendada exige dimensões também de WEBP (hoje `readImageDimensions` só lê PNG/JPEG). Acervo de dev: 0 WEBP; produção não medível.
**Decisão**: dependência `sharp`: no modo final, WEBP é decodificado e reencodado em PNG (sem perda além da decodificação do WEBP de origem — NFR-064-005); `readWebpDimensions` (cabeçalho, `image-signature.ts`) fornece as dimensões de WEBP para o upload e o preview. Exceção ao NFR-024-004 **só no modo final** (A-064-003); o rascunho continua pulando WEBP. Falha de conversão → `IMAGE_NOT_EMBEDDABLE` (Quadro só com texto, aviso). Dependência nativa com precedente em produção (`@node-rs/argon2`).
**Emenda (2026-10-18, Tech Lead, após a medição da TASK-065-005 — MEDICAO-065)**: PNG de WEBP fotográfico ficou 21–39× maior (~7 MB por Quadro 2000×1333; um Quadro estoura o teto de DEC-065-010). A saída da conversão passa a depender do canal alfa: WEBP **opaco** → JPEG q85 (4:2:0, sem mozjpeg); WEBP **com alfa** → PNG sem perda. A mesma regra vale para a imagem PNG/JPEG reduzida por exceder `RECOMMENDED_LONG_SIDE_PX` (opaca → JPEG q85; com alfa → PNG). PNG/JPEG de até o limiar seguem com os bytes originais (NFR-024-004). Dentro do limite (iv) da resolução Q3 do PO ("sem perda visível na impressão do tamanho da caixa"), confirmado na amostra pelo gate 11. `sharp`: cache `{ memory: 50, files: 0, items: 100 }`, `concurrency(1)`, conversões em sequência (pico RSS 283 MB × 497 MB em paralelo).
**Alternativas consideradas**:
- Saída sempre PNG (decisão original), descartada pela medição: um Quadro fotográfico sozinho passa de 4 MB e a tira não cabe no teto de resposta.
- Decoder WASM (`@jsquash/webp`), descartada porque é ESM + WASM sob CJS/Jest/Vercel: exige carregamento assíncrono de `.wasm` (o mesmo problema de empacotamento de asset de DEC-065-003) e adaptações de módulo em duas toolchains.
- Recusar WEBP no upload, descartada porque não cobre WEBP já vinculado e FR-064-012 exige que apareça; só bastaria se o acervo de produção tivesse 0 WEBP, o que não é medível daqui.
- Ignorar WEBP também no final (status quo), descartada porque viola FR-064-012/AC-064-010.
**Consequências**: PNG de foto pode ficar bem maior que o WEBP lossy de origem (impacta o teto de resposta, DEC-065-010/TRISK-065-001); binário nativo na função (tamanho, cold start, memória — TRISK-065-002/-005); `sharp` entra no gate 8 (libvips LGPL) e no gate 10; no Jest/CI o binário da plataforma precisa instalar (`npm ci`).
**Reabrir se**: tamanho/cold start da função, medidos no gate 10, estourarem; ou o build da Vercel não empacotar o binário do `sharp`; ou os PNGs convertidos estourarem sistematicamente o teto de resposta (então avaliar JPEG de alta qualidade para WEBP lossy).
**Irreversível**: não
**Aderência à ficha/perfil**: exceção

### DEC-065-005: Resolução recomendada única de 2000 px no lado maior e aviso no upload
**Contexto**: FR-064-014/FR-064-029 pedem um valor único fixado com o layout (caixa a 300 dpi). A Associação visual não guarda dimensões.
**Decisão**: a caixa de imagem tem 480 pt de largura (DEC-065-002); 480 pt ÷ 72 × 300 dpi = **2000 px**. **Resolução recomendada = lado maior ≥ 2000 px** (`RECOMMENDED_LONG_SIDE_PX`, constante única). No upload, `POST /visual-associations` devolve `warnings[{ code: 'BELOW_RECOMMENDED_RESOLUTION', recommendedLongSidePx, widthPx, heightPx }]` sem bloquear; dimensões vêm de `readImageDimensions` (PNG/JPEG) e `readWebpDimensions` (WEBP), ambos por cabeçalho; o critério "abaixo da Resolução recomendada" é um predicado único exportado de `strip-coverage.ts` (`isBelowRecommendedResolution`), usado pelo upload e pela cobertura. Para o acervo antigo, o mesmo limiar gera a 3ª categoria do Aviso de exportação no preview. O `product-designer` confirma o valor no gate 11 e o valor muda num só lugar.
**Alternativas consideradas**:
- Calcular dimensões na hora só no PDF e não avisar no upload, descartada porque FR-064-014 exige o aviso no envio, onde o EDITOR ainda pode trocar a imagem.
- Persistir largura/altura em coluna nova de `visual_associations`, descartada porque exige migração em tabela existente e *backfill* do acervo, sem benefício que o cálculo no ato não dê (a SPEC pede só aviso informativo).
**Consequências**: o cálculo de dimensões repete-se a cada preview (custo de ler metadados, medido no gate 10); imagem retrato é limitada pela altura de 400 pt (≈ 1667 px) mas o critério permanece o lado maior, simples e único.
**Reabrir se**: o gate 11 alterar a caixa de imagem, ou Produtos recusar imagens aceitas pelo limiar (RISK-064-003).
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-065-006: Preview de exportação e confirmações impostas no servidor (`acknowledgeIncomplete`, `acknowledgeRepublish`)
**Contexto**: FR-064-030 e FR-064-019 exigem confirmação explícita antes de gravar quando N < M ou quando a Versão já tem publicação; FR-064-013 exige o Aviso. A tela não pode ser a única barreira (NFR-064-001, deny-by-default).
**Decisão**: `GET /contents/:id/publication/final-preview` (EDITOR/ADMIN; sem efeito colateral) devolve `{eligible, reason?, version{number, legislativeClosureDate}, framesTotal, framesWithImage, warnings[{position, kind}], latestPublication?}`, usando a mesma `prepareFrameImage` e a mesma `computeStripCoverage` da composição. Publicar exige no servidor `acknowledgeIncomplete: true` quando N < M e `acknowledgeRepublish: true` quando a Versão já tem publicação; falta de flag → 409 com `code` (`INCOMPLETE_COVERAGE_ACK_REQUIRED` / `REPUBLISH_ACK_REQUIRED`) e `details`, nada gravado. N/M gravados e comparados são os **do PDF composto no ato**, nunca do cliente.
**Emenda (2026-10-18, Tech Lead — "Reabrir se" disparado pelo gate 10 da wave 4)**: medido, o preview que prepara a imagem de todos os Quadros (sharp + decode pdf-lib + deflate do `embed()`) leva 15–58 s no pior caso realista (> 15 s da Vercel) e custa até 10× a exportação. O preview passa a **classificar pelo cabeçalho**, sem decodificar nem deflatar: formato pela assinatura, dimensões (`readImageDimensions`/`readWebpDimensions`), APNG, orçamento de pixels e Resolução recomendada → `none` / `ok` / `failed` (motivo detectável por cabeçalho) — custo O(cabeçalhos). Corrupção só no corpo da imagem é detectada na exportação (que segue avisando o Quadro); a identidade preview × exportação (TRISK-065-010) vale para as razões detectáveis por cabeçalho; o AC-064-011 não é reduzido: o aviso pós-exportação usa a cobertura autoritativa que a exportação final devolve em `X-Final-Pdf-Coverage` (correção pós-gate 1 da wave 4 — a 1ª redação desta emenda restringia a promessa do AC e foi corrigida). O preview herda o teto da exportação (`withDeadline` + cessão `setTimeout(0)` por Quadro + 503 declarado), guarda só a projeção `{status, widthPx, heightPx}` e memoiza por `visualAssociationId` (a exportação reusa o mesmo `PDFImage` para a mesma Associação em vários Quadros). Alternativas descartadas: manter a preparação completa com teto (descarte: o pior caso estoura 15 s mesmo sem `embed()`, medido) e persistir a classificação no banco (descarte: exige migração e invalidação no PATCH da Associação; reabrir se o cabeçalho deixar de bastar).
**Alternativas consideradas**:
- Confirmar só na tela (sem flags no corpo), descartada porque uma chamada direta ao sistema publicaria PDF incompleto ou duplicado sem aviso, contrariando AC-064-023.
- Devolver o aviso num cabeçalho da resposta do PDF, descartada porque exige expor e parsear cabeçalho no `responseHandler` binário já existente e não serve à confirmação *antes* de publicar.
**Consequências**: o preview lê os binários de todas as imagens da tira (custo de leitura/memória, TRISK-065-005); janela pequena entre preview e ato é absorvida pelo 409 autoritativo; GET de preview exige tripwire de autorização.
**Reabrir se**: o custo do preview, medido no gate 10, for alto em tiras reais (então cachear/limitar a pré-checagem), ou Produtos pedir confirmação por papel (ex.: só ADMIN republica).
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-065-007: Persistência do PDF publicado atrás de `PublishedPdfStore`, registro imutável por `INSERT` único
**Contexto**: FR-064-018/021/031 e NFR-064-003 pedem registro novo a cada publicação, imutável e baixável byte a byte; A-064-008 manda guardar no mesmo banco; o KAN-236 (SPEC-061/PLAN-063) pode vir a usar storage de objetos S3-compatível, e o Diretor pode querer unificar depois.
**Decisão**: tabela `published_pdfs` (§5) acessada só pela interface `PublishedPdfStore` (`insert`/`list`/`getBytes`/`findLatestForVersion`, sem `update`/`delete`), com implementação Prisma. Cada publicação é **um `INSERT` atômico** dentro de `$transaction` com o evento `PUBLICACAO_PDF` e a re-verificação de elegibilidade. Duas publicações simultâneas produzem dois registros completos, sem lock (FR-064-031 satisfeito por construção; A-064-005 aceita dois da mesma Versão). "Atual" = maior `publishedAt`, desempate por `id`. Hash `sha256` e `byteSize` gravados para verificar integridade.
**Alternativas consideradas**:
- Um único registro por (Conteúdo, Versão) com `upsert`, descartada porque sobrescreve e contraria FR-064-018 e A-064-005; perderia o histórico que o KAN-236 usará.
- Guardar o PDF direto no storage S3 do KAN-236 agora, descartada porque está fora do escopo (SPEC §4.2) e depende de infraestrutura e PLAN ainda não entregues; a interface própria deixa a troca barata.
- `SELECT … FOR UPDATE` para serializar publicações do mesmo Conteúdo, descartada porque a SPEC aceita dois registros completos e o lock acrescentaria espera e modo de falha sem benefício.
**Consequências**: o banco cresce a cada publicação (RISK-064-004, TRISK-065-008); consultas de lista nunca carregam `pdfData`; a imutabilidade depende de a interface não expor escrita além de `insert` (provada por teste); trocar o armazenamento exige só nova implementação da interface mais migração de dados.
**Reabrir se**: o volume de `pdfData` pressionar o banco, ou o Diretor unificar com o storage S3 do KAN-236, ou Produtos exigir um único PDF por Versão (A-064-005).
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-065-008: Migração aditiva da tabela `published_pdfs`
**Contexto**: A-064-008 autoriza só migração aditiva; `CLAUDE.md` exige perguntar antes de executar qualquer migração, e o Diretor autorizou a aplicação nos bancos locais dev e test para esta entrega.
**Decisão**: uma migração com `CREATE TABLE published_pdfs`, índice `(rawContentId, publishedAt DESC)` e três FKs (`Restrict`); nada de `ALTER`/`DROP` em tabelas existentes; `prisma migrate dev` gera o arquivo versionado no diff da TASK; reversão em caso de erro por `DROP TABLE published_pdfs` (ainda sem dados em produção).
**Alternativas consideradas**:
- Estender `PublicationEvent` com colunas de ator, versão e bytes, descartada porque altera tabela existente com semântica de log de exportação (rascunho incluído) e misturaria um log append-only de tentativas com um acervo de artefatos imutáveis.
**Consequências**: apenas leitura de `contents`, `content_versions` e `users` por FK; `Restrict` impede remoção física de entidades referenciadas.
**Reabrir se**: a migração falhar em dev/test por conflito de nome ou de histórico de migrações.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-065-009: Rotas de publicação, download com ETag e `returnTo` seguro na Biblioteca visual
**Contexto**: o histórico exige publicar/listar/baixar com alcance comum e proteção contra IDOR; o atalho do seletor exige volta à tira sem abrir redirecionamento aberto (gate 8).
**Decisão**: (backend) `POST /contents/:id/publications`, `GET /contents/:id/publications` e `GET /contents/:id/publications/:publicationId/pdf` (COMP-065-011): `publicationId` sempre resolvido junto de `rawContentId` (outro conteúdo → 404); download com bytes gravados, `Content-Type: application/pdf`, `attachment` e `ETag` (sha256). (frontend) `returnTo` só é aceito se casar `^/content/<uuid>/tira$`, validado no Server Component da página; a própria página renderiza "Voltar para a tira" na linha do cabeçalho só com valor validado (o valor não atravessa para o componente cliente — retry pós-gate da wave 1); o valor cru nunca vai a `href`/redirect.
**Alternativas consideradas**:
- `useSearchParams` num componente client, descartada porque exige `Suspense` e nenhum componente do projeto o usa; a validação no servidor evita enviar o valor cru ao cliente.
- Voltar por `router.back()`/histórico do navegador, descartada porque não funciona em aba nova ou após recarregar, e a SPEC pede caminho de volta confiável (FR-064-026).
- Aceitar qualquer caminho começando com `/`, descartada porque `//evil.com` e `/\evil.com` são interpretados como URL externa por navegadores (open redirect).
**Consequências**: o padrão de rota da tira (`/content/[id]/tira`) fica acoplado ao validador (teste cobre); URLs de download previsíveis, protegidas por sessão e papel.
**Reabrir se**: a rota da tira mudar de caminho, ou surgir outra origem legítima de retorno (ex.: volta a um Quadro específico).
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-065-010: Teto de tamanho do PDF final com recusa explícita
**Contexto**: a Vercel limita o corpo de resposta de função em ~4,5 MB (sem declaração no repositório), e imagens até 5 MB cada, mais PNG convertido de WEBP, podem passar disso numa tira de vários Quadros. Um PDF publicado que não pode ser baixado violaria FR-064-021; erro genérico da plataforma violaria FR-064-031.
**Decisão**: (1) **no modo final, reduzir as imagens de lado maior acima da Resolução recomendada (`RECOMMENDED_LONG_SIDE_PX`) até ela**, com proporção preservada, sem perda visível na impressão do tamanho da caixa; imagem igual ou abaixo da Resolução recomendada entra byte a byte (sem recodificar) e a imagem da Biblioteca visual não é alterada; o rascunho segue embutindo os originais. (2) O teto segue como rede de segurança: `PUBLICATION_FINAL_PDF_MAX_BYTES` (default 4.000.000, `env.ts`). Medido (MEDICAO-065): ~8 Quadros fotográficos (≈467 KB por Quadro reduzido) é o limite prático sob o teto. Excedido mesmo após a redução, a exportação final **e** a publicação são recusadas com 422 `FINAL_PDF_TOO_LARGE` (`details.byteSize`, `details.maxBytes` e `details.heaviestFrames`: até 3 posições de Quadro, em ordem decrescente de bytes de imagem), sem gravar. A recusa vale antes do `INSERT`: nunca se grava o que não se consegue baixar.
**Alternativas consideradas**:
- Sem teto (deixar a plataforma recusar), descartada porque o usuário recebe erro genérico de plataforma e, na publicação, pode-se gravar um PDF que nenhum download entrega.
- Só recusar acima do teto, sem reduzir imagens (decisão anterior, v0.1), descartada porque foto de 5 MB e 4000 px é o caso comum e recusaria tiras reais; a redução ao lado maior recomendado não perde nitidez visível na caixa de impressão (NFR-064-005, A-064-003).
- Servir o PDF por URL pré-assinada de storage externo, descartada porque storage externo está fora de escopo (SPEC §4.2); é a rota de saída caso o teto seja atingido (ver Reabrir se).
**Consequências**: a maioria das tiras com fotos grandes cabe sem ação do EDITOR; as que ainda passam do teto não publicam até as imagens serem reduzidas (a mensagem informa o tamanho, o teto e os Quadros mais pesados); a redução usa `sharp` (já presente por DEC-065-004) e a TASK-065-005 mede tamanho e tempo com o parâmetro adotado; valor do teto ajustável por env sem deploy de código.
**Reabrir se**: uma tira real de produção exceder o teto (então: storage externo com URL pré-assinada, alinhado ao KAN-236), ou a medição do gate 10 mostrar que o limite real da plataforma é diferente do assumido.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

## 8. Riscos técnicos

- **TRISK-065-001** (**alto** sem medição) Limite de corpo de resposta da função serverless (~4,5 MB): o PDF final com imagens (até 5 MB cada; PNG de WEBP pode inchar) pode exceder o limite no download e na exportação (mitigação: teto explícito com recusa e motivo, DEC-065-010; medir o tamanho de um PDF final real no gate 10 e registrar o número; subset de fonte e PNG apenas quando WEBP; saída estrutural = storage externo com URL pré-assinada, `Reabrir se:` da DEC-065-010).
- **TRISK-065-002** Binário nativo do `sharp` na função Vercel (tamanho do pacote, cold start, empacotamento) (mitigação: precedente `@node-rs/argon2`; prova empírica em deploy de preview e medição no gate 10; `Reabrir se:` de DEC-065-004; sem plano B de WASM por custo de toolchain).
- **TRISK-065-003** Módulos de fonte base64 aumentam o bundle e o tempo de parse da função (mitigação: fonte pré-reduzida a Latin + pontuação, só Regular e Bold, `subset: true` na geração; medir no gate 10).
- **TRISK-065-004** Tempo de geração sob o teto de 12 s com M Quadros, conversão WEBP e embedding, sem teto de Quadros por tira (RISK-064-002) (mitigação: `withDeadline` herdado devolve 503 com motivo, nada é gravado; processamento Quadro a Quadro; medir em tira de tamanho real no gate 10; `Reabrir se:` publicação falhar por tempo em tira real).
- **TRISK-065-005** Memória (1024 MB): binários de M imagens, raster decodificado do `sharp` (até 20 M px × 4 bytes) e preview que lê todas as imagens (mitigação: orçamento de 20 M px por imagem; preparar e liberar Quadro a Quadro; `sharp` com cache/concorrência reduzidos; medir no gate 10).
- **TRISK-065-006** Corrida entre a verificação de elegibilidade e a gravação (Versão alterada durante a geração) (mitigação: re-verificação dentro da `$transaction` do `INSERT`; teste de integração do cenário).
- **TRISK-065-007** Open redirect via `returnTo` (CWE-601) (mitigação: lista de permissão por padrão `^/content/<uuid>/tira$`, validação no servidor, valor cru nunca em `href`; testes unitários com `//`, `\`, `https://`, `javascript:`; revisão no gate 8).
- **TRISK-065-008** Crescimento do banco por `pdfData` a cada publicação (RISK-064-004) (mitigação: listas sem `pdfData`; interface `PublishedPdfStore` para trocar o armazenamento; registrar `byteSize` para medir; `Reabrir se:` DEC-065-007).
- **TRISK-065-009** Layout rejeitado pelo gate 11 ou pela amostra impressa de Produtos (RISK-064-001) (mitigação: constantes de layout num bloco só; compositor isolado do rascunho; ajustes de caixa propagam à Resolução recomendada por uma constante).
- **TRISK-065-010** Divergência entre o que o preview afirma e o que o PDF contém (mitigação, após a emenda da DEC-065-006: o preview é pré-checagem por cabeçalho — `inspectHeader` é a fonte única das recusas por cabeçalho nos dois caminhos — e o aviso **pós-exportação** vem da cobertura autoritativa da própria exportação, `X-Final-Pdf-Coverage`, nunca do preview refeito; AC-064-011 vale integralmente; o servidor reconfere a cobertura do PDF composto na publicação e responde 409 com detalhes autoritativos).
- **TRISK-065-011** Supply chain das dependências novas: `sharp`/libvips (LGPL-3), `@pdf-lib/fontkit` sem manutenção ativa, Noto Sans (OFL) (mitigação: versões fixadas, lock commitado, `npm audit --omit=dev --audit-level=high`, conferência de licença e de scripts de instalação no gate 8; `OFL.txt` no repositório).
- **TRISK-065-012** `sharp` no ambiente de testes/CI (binário de plataforma) quebrando o Jest fora da máquina de dev (mitigação: `npm ci` instala o pacote opcional da plataforma; teste de fumaça de WEBP→PNG na suíte de integração).
- **TRISK-065-013** Métrica §1.3 inconclusiva sem 2 ADMINs reais (RISK-064-006) (mitigação: gate 9 com conta descartável; fonte externa registrada no INDEX).

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Aderência à ficha/perfil validada
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates)
- [ ] Rascunho byte a byte inalterado: os testes existentes do rascunho passam sem alteração
- [ ] Migração `published_pdfs` aditiva, revisável no diff e aplicada em dev e test com autorização do Diretor
- [ ] Gate 8 (supply chain: `sharp`, `@pdf-lib/fontkit`, Noto Sans/OFL; `returnTo`) e gate 10 (tamanho do bundle, cold start, tempo, memória e tamanho do PDF final medidos) sem pendência
- [ ] Gate 11: layout, caixa de imagem e Resolução recomendada (2000 px) confirmados pelo `product-designer`
- [ ] `docs/GUIA-DE-USO.md` atualizado (seção nova, §4, §6 e data de "Última atualização")
- [ ] Métrica da SPEC operacional (§1.3, `Fonte de medição: instrumentação`): a tabela `published_pdfs` registra quem, quando, qual Versão, N e M, e a listagem (`GET …/publications`) os expõe — instrumentação entregue e provada no gate 9 (consulta exibindo o registro com esses campos); a aprovação da amostra impressa é fonte externa, dono Produtos, registrada no INDEX

## 10. Não coberto por este PLAN

- Concurso na capa do PDF final (`Reabrir se:` Produtos reprovar a amostra por falta do concurso).
- Montar pacote e exportar para marketplace (KAN-236, SPEC-061/PLAN-063): este PLAN só deixa o PDF publicado disponível; nenhum consumidor dele é entregue aqui.
- Storage de objetos externo (só como saída de DEC-065-007/DEC-065-010).
- PDF final da Variante "resumo" (A-064-002).
- Cadastro de associação visual em painel sobre a tira, sem sair do contexto.
- Redefinir a regra de aprovação/fechamento de versão; conserto do RISK-032-006 (Q-064-002, fora por default, brief separado).
- Acesso do STUDENT ao PDF final; excluir, despublicar ou substituir PDF publicado.
- Todos os FRs/NFRs da SPEC-064 estão cobertos por este PLAN; nada fica para PLANs futuros.
