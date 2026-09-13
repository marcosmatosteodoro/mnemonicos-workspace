# PLAN-023: Biblioteca visual reutilizável

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.2
**Autor**: keelson (scribe)
**Data**: 2026-09-13

## Aderência a guidelines

**Ficha/perfil de linguagem**: backend `node-22.md` (Node 22 + TypeScript 6, Express 5,
Prisma 7, Zod 4, Jest 30) ativo; frontend `next-16.md` (Next 16, React 19, RTK Query,
Tailwind 4) ativo.
**Stack vigente herdado**: Express 5 + Prisma 7 (`@prisma/adapter-pg`) + Zod 4 no backend;
Next 16 (App Router) + React 19 + Redux Toolkit/RTK Query + Tailwind 4 no frontend; Jest 30
+ `supertest` para integração; Postgres real (`mnemonicos_test`) para teste com banco.
Nenhuma peça de stack nova além da dependência declarada em DEC-023-003.
**Padrão arquitetural seguido**: módulo por domínio schema→service→routes (backend, mesmo
padrão de `tira`/`contents`/`production-events`); Server Component casca + Client Component
com estado (frontend, mesmo padrão de `(interno)/content` e `(interno)/content/[id]/tira`).
**Decisões irreversíveis do slug tocadas**: nenhuma.
**Decisões irreversíveis de outros slugs em conflito**: nenhuma — `infra-vercel`: sem bloco
de decisões (sem `INDEX.md`); nenhum outro slug existe em `{docsRoot}` além de
`producao-material` e `infra-vercel`.
**Exceções aos guidelines**: nenhuma.

## Cobertura

**SPEC referenciada**: SPEC-022
**Slice declarado**: cobertura total restante — Caso D (nenhum `--covers`/`--slice`
declarado), SPEC-022 sem PLAN anterior.

**FRs cobertos**:
- FR-022-001
- FR-022-002
- FR-022-003
- FR-022-004
- FR-022-005
- FR-022-006
- FR-022-007
- FR-022-008
- FR-022-009
- FR-022-010
- FR-022-011
- FR-022-012
- FR-022-013
- FR-022-014
- FR-022-015
- FR-022-016
- FR-022-017
- FR-022-018
- FR-022-019
- FR-022-020
- FR-022-021
- FR-022-022
- FR-022-023
- FR-022-024
- FR-022-025

**NFRs cobertos**:
- NFR-022-001
- NFR-022-002
- NFR-022-003
- NFR-022-004
- NFR-022-005
- NFR-022-006
- NFR-022-007

**Cobertura agregada do slug**:
- Total na SPEC: 25 FRs + 7 NFRs
- Cobertos por planos anteriores: 0 FRs + 0 NFRs (SPEC-022 não tem PLAN anterior)
- Cobertos por este: 25 FRs + 7 NFRs
- Gap restante: 0
- Funcionalidades cobertas: FEAT-022-001 (total), FEAT-022-002 (total), FEAT-022-003
  (total)

## 1. Visão técnica

A fatia F5 introduz duas superfícies novas no backend — um módulo próprio
`visual-associations` (acervo: CRUD, upload, busca por categoria, entrega do binário) e uma
extensão pontual do módulo `tira` já entregue por PLAN-012 (vincular/desvincular uma
associação visual a um Quadro específico, porque a URL do vínculo pertence à árvore de
recursos do Quadro: `/contents/:id/strip/frames/:frameId/visual-association`) — e duas no
frontend (tela nova `(interno)/visual-library` para navegação/busca/CRUD do acervo, e um
enxerto em `mnemonic-strip-board.tsx` para exibir/vincular/desvincular a partir da tela da
Tira). Tudo greenfield: nenhuma dependência de upload/multipart, rota de binário autenticado
ou env var de armazenamento existe hoje nos dois repos (reconhecimento do `code-scout`,
confiança alta).

Cardinalidade do vínculo é 1 associação por Quadro no máximo (FR-022-021) — modelada como FK
nullable `MnemonicFrame.visualAssociationId` (N:1), não uma tabela de junção N:N (DEC-023-001).
O binário é armazenado como coluna `Bytes` (bytea) no Postgres — mesma base de dados de todo
o domínio, sem infraestrutura nova (DEC-023-002) — com validação de assinatura de bytes
(magic number) antes de qualquer persistência (DEC-023-003); nenhum metadado do cliente
(nome original do arquivo, `Content-Type` declarado) é usado para nada além do parsing do
multer (DEC-023-012).
A entrega do binário é uma rota autenticada com stream, nunca `express.static` (DEC-023-004).
O vínculo reusa o mecanismo genérico de evento de etapa (`recordProductionStageEvent`/
`decideStageTransition`, F3/SPEC-009) com um valor novo aditivo em `ProductionStageType`
(DEC-023-005); a métrica de "uploads evitados" (SPEC-022 §1.3) exige um log dedicado por
vínculo (`VisualAssociationLinkEvent`, DEC-023-011), porque o payload mínimo do evento de
etapa genérico não carrega qual associação foi vinculada.

**Premissa desta execução, não resolvida pela SPEC — marcada `[assumido]`** (A-023-001,
evidência: consistência interna da SPEC): NFR-022-005/AC-022-023 usam a expressão "alcance
por autoria de FR-022-018" para descrever quem pode buscar o binário de uma imagem
diretamente — mas FR-022-018 é especificamente sobre a cadeia de autoria de um **Quadro**
(Frame→Strip→RuleBreakdown→RawContent), enquanto FR-022-023 estabelece, sem ambiguidade,
que leitura/busca/vínculo do acervo são **comuns a todo EDITOR/ADMIN, independente de quem
criou a associação** — e uma associação órfã (sem nenhum Quadro vinculado, A-022-006) não
tem cadeia de Quadro nenhuma para "alcançar". Este PLAN assume que NFR-022-005 reafirma a
MESMA barreira deny-by-default (sessão EDITOR/ADMIN válida, NFR-022-003) aplicada também à
rota do binário — não uma restrição adicional por autoria da associação em si. `Reabrir se`:
o Diretor/PO confirmar que a leitura do binário deveria, na prática, ficar restrita à mesma
autoria de FR-022-018 (o que tornaria associações órfãs sem Quadro algum inacessíveis por
imagem, contradizendo A-022-006).

## 2. Stack e dependências

- **Backend (herdado, sem mudança)**: Express 5, Prisma 7 (`@prisma/adapter-pg`), Zod 4,
  Jest 30 + `supertest`, `pino`/`pino-http`, `helmet`.
- **Backend (dependência nova)**: `multer` (parser multipart, `memoryStorage()` — nunca
  `diskStorage()` do próprio multer, porque o service só persiste o binário **depois** de
  validar a assinatura de bytes do buffer em memória, DEC-023-003). Biblioteca mais madura/
  auditada do ecossistema Express para este propósito; entra sujeita a `/keelson:audit`/
  gate 8 (TRISK-023-002).
- **Backend (nativo, sem dependência nova)**: nenhuma — a leitura/escrita do binário é uma
  coluna a mais no mesmo `PrismaClient` já usado por todo o módulo (DEC-023-002).
- **Frontend**: nenhuma dependência nova — `FormData`/`<input type="file">` nativos para o
  multipart do upload; RTK Query já cobre a chamada HTTP (nenhum cliente HTTP paralelo).
- **Variáveis de ambiente novas** (backend, lidas uma única vez em `src/config/env.ts`,
  seguindo o padrão de `env.ts` já existente): `VISUAL_ASSOCIATIONS_MAX_FILE_SIZE_BYTES`
  (default `5242880` = 5 MB, A-022-005). Entra em `.env.example` com valor de exemplo e em
  `tests/setup-env.ts` com valor fictício.

## 3. Componentes

### COMP-023-001: `visual-associations.schema.ts` — validação de entrada (Zod)
**Responsabilidade**: schemas dos campos de texto da associação visual (`category`,
`cognitiveDescription` — `z.string().trim().min(1, ...)`, mesmo padrão de `frameTextSchema`
em `tira.schema.ts`), do param `:id`, e da query de listagem/sugestão (`category?`, `page?`,
`perPage?`, `q?`). O arquivo enviado (multipart) **não** passa pelo Zod — é validado por
assinatura de bytes no service (COMP-023-002/COMP-023-005); o Zod cobre só os campos de
texto que acompanham o upload.
**Realiza**: FR-022-004
**Interface pública**:
```ts
export const createVisualAssociationBodySchema = z.object({
  category: z.string().trim().min(1, 'Informe a categoria.'),
  cognitiveDescription: z.string().trim().min(1, 'Informe a função cognitiva da imagem.'),
});
export type CreateVisualAssociationBodyInput = z.infer<typeof createVisualAssociationBodySchema>;

export const updateVisualAssociationBodySchema = createVisualAssociationBodySchema.partial();
export type UpdateVisualAssociationBodyInput = z.infer<typeof updateVisualAssociationBodySchema>;

export const visualAssociationIdParamSchema = z.object({ id: z.uuid('Identificador de associação visual inválido.') });

export const listVisualAssociationsQuerySchema = z.object({
  category: z.string().trim().min(1).optional(),
  page: z.coerce.number().int().min(1).default(1),
  perPage: z.coerce.number().int().min(1).max(100).default(20),
});
export type ListVisualAssociationsQuery = z.infer<typeof listVisualAssociationsQuerySchema>;

export const suggestCategoriesQuerySchema = z.object({ q: z.string().trim().min(1) });
```
**Dependências**: nenhuma

### COMP-023-002: `image-signature.ts` — assinatura de bytes (função pura)
**Responsabilidade**: detecta o formato raster real de um `Buffer` pelos primeiros bytes
(magic number) — PNG (`89 50 4E 47`), JPEG (`FF D8 FF`), WebP (`52 49 46 46` + offset 8
`57 45 42 50`); devolve `null` para qualquer outra coisa (inclusive SVG, cujo conteúdo textual
nunca casa nenhuma assinatura raster — NFR-022-002). Pura, sem I/O, sem `Buffer` de rede nem
disco: recebe o buffer já lido em memória e devolve o formato — testável sem mocks, mesmo
espírito de `buildInitialFrames`/`decideStageTransition`.
**Realiza**: FR-022-001, FR-022-002, NFR-022-001, NFR-022-002
**Interface pública**:
```ts
export type RasterImageFormat = 'PNG' | 'JPEG' | 'WEBP';

export function detectImageSignature(buffer: Buffer): RasterImageFormat | null;

/** Extensão de arquivo (com ponto) para o formato detectado — nunca a extensão do cliente. */
export function extensionForFormat(format: RasterImageFormat): '.png' | '.jpg' | '.webp';

/** `Content-Type` correspondente, para a rota de entrega do binário. */
export function mimeTypeForFormat(format: RasterImageFormat): 'image/png' | 'image/jpeg' | 'image/webp';
```
**Dependências**: nenhuma

### COMP-023-003: `visual-association-storage.ts` — camada de acesso ao binário no Postgres
**Responsabilidade**: Lê/escreve/apaga o binário como coluna `imageData Bytes` da própria
linha `VisualAssociation` no Postgres — não é mais um módulo de filesystem, é uma camada fina
sobre o Prisma que mantém a MESMA interface de função (para que uma troca futura para blob
storage externo toque só este arquivo, DEC-023-002). Escrita e leitura acontecem na MESMA
`$transaction` do service chamador — elimina a antiga preocupação de arquivo órfão fora da
transação.
**Realiza**: nenhum diretamente — camada de storage consumida por COMP-023-005
**Interface pública**:
```ts
export async function saveVisualAssociationImage(tx: PrismaClientOrTx, id: string, buffer: Buffer): Promise<void>;
export async function readVisualAssociationImage(db: PrismaClientOrTx, id: string): Promise<Buffer | null>;
```
(Remove-se `visualAssociationReadStream`/`deleteVisualAssociationFile` — apagar a imagem
agora é só apagar a LINHA inteira, feito por `removeVisualAssociation`, não uma função de
storage separada.)
**Dependências**: COMP-023-002

### COMP-023-004: Modelo de dados — `VisualAssociation`, FK em `MnemonicFrame`, enum aditivo, `VisualAssociationLinkEvent`
**Responsabilidade**: schema Prisma novo/estendido (detalhe completo em §5) — migração
100% aditiva (execução exige autorização do Diretor, DEC-023-007). `PRODUCTION_STAGE_TYPES`
(`domain/types.ts`) ganha `'ASSOCIACAO_VISUAL'` (DEC-023-005), sem espelho no frontend
(mesmo precedente de DEC-010-006 — `PRODUCTION_STAGE_TYPES` já não tem consumidor de tela
até F10). `domain-types-parity.test.ts` (existente, `mnemonicos-backend/tests/unit/
domain-types-parity.test.ts:142-166`) precisa do valor novo no array `PRODUCTION_STAGE_TYPES`
para continuar comparando o array contra o enum real do `schema.prisma` sem regressão.
**Realiza**: FR-022-014, FR-022-016, FR-022-020, FR-022-024

(A base de dados sustenta toda a fatia, mas o modelo/schema REALIZA diretamente só os FRs
sem lógica de aplicação própria — cardinalidade via FK, exposição do campo, cascata de
remoção via `onDelete`, e o enum aditivo; os demais FRs são realizados pelos componentes que
os consomem, listados no §7. Migração aditiva não altera nenhuma coluna existente de
`MnemonicFrame`/`ProductionStageEvent`.)
**Interface pública**: modelos Prisma (§5); `PRODUCTION_STAGE_TYPES` estendido em
`src/domain/types.ts`.
**Dependências**: nenhuma

### COMP-023-005: `visual-associations.service.ts` — regra de negócio central do acervo
**Responsabilidade**: CRUD completo (criar/editar in-place/remover), guarda de escrita
(`assertVisualAssociationWritable`, DEC-023-006), listagem paginada com filtro por
categoria normalizada (DEC-023-008/DEC-023-010), sugestão de categoria (FR-022-025),
contagem de vínculos ativos por associação (excluindo Quadros cujo Conteúdo bruto foi
soft-deleted, FR-022-019), identificação dos Quadros/Tiras alcançáveis por autoria quando a
remoção é recusada (FR-022-022), e a leitura do binário para a rota de entrega
(FR-022-016/NFR-022-005). Toda escrita (criar/editar/remover) roda numa `$transaction`
interativa — falha em qualquer passo não deixa arquivo órfão nem linha meio-salva
(fail-secure, mesmo padrão de `tira.service.ts`); a escrita do binário (`imageData`) acontece
DENTRO da mesma `$transaction` do `create`/`update` da linha — sem a antiga dança de ordem
entre arquivo e commit, porque não há mais arquivo fora do banco.
**Realiza**: FR-022-001, FR-022-002, FR-022-003, FR-022-004, FR-022-006, FR-022-007, FR-022-008, FR-022-009, FR-022-011, FR-022-012, FR-022-019, FR-022-022, FR-022-023, FR-022-025, NFR-022-001, NFR-022-004, NFR-022-007
**Interface pública**:
```ts
export interface VisualAssociationDetail {
  id: string;
  authorId: string;
  category: string;
  cognitiveDescription: string;
  mimeType: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface VisualAssociationSummary {
  id: string;
  category: string;
  linkCount: number; // exclui vínculos cujo Conteúdo bruto foi soft-deleted (FR-022-019)
  createdAt: Date;
}

/** Guarda pura (sem I/O): recebe a linha já lida. EDITOR só escreve a própria; ADMIN irrestrito. */
export function assertVisualAssociationWritable(association: Pick<VisualAssociationDetail, 'authorId'>, actor: ContentActor): void;

/** Trim + case-fold (NFR-022-007) — pura. */
export function normalizeCategoryKey(category: string): string;

/** Pura: filtra `existingCategories` por combinação normalizada com `query`, devolve a grafia original (FR-022-025). */
export function suggestCategories(existingCategories: readonly string[], query: string): string[];

export async function createVisualAssociation(
  input: CreateVisualAssociationBodyInput,
  file: { buffer: Buffer; sizeBytes: number },
  actor: ContentActor,
  db?: VisualAssociationClient,
): Promise<VisualAssociationDetail>;

export async function updateVisualAssociation(
  id: string,
  input: UpdateVisualAssociationBodyInput,
  file: { buffer: Buffer; sizeBytes: number } | undefined,
  actor: ContentActor,
  db?: VisualAssociationClient,
): Promise<VisualAssociationDetail>;

export async function removeVisualAssociation(id: string, actor: ContentActor, db?: VisualAssociationClient): Promise<void>;
// ConflictError com `details: { reachableLinks: Array<{ rawContentId: string; frameId: string }>; outOfReachCount: number }` quando há vínculo ativo (FR-022-008/FR-022-022).

export async function listVisualAssociations(query: ListVisualAssociationsQuery, db?: VisualAssociationClient): Promise<Paginated<VisualAssociationSummary>>;

export async function listVisualAssociationCategories(query: { q: string }, db?: VisualAssociationClient): Promise<string[]>;

export async function getVisualAssociationBinary(id: string, db?: VisualAssociationClient): Promise<{ imageData: Buffer; mimeType: string } | null>;
```
**Dependências**: COMP-023-001, COMP-023-002, COMP-023-003, COMP-023-004

### COMP-023-006: `visual-associations.routes.ts` — superfície HTTP do acervo
**Responsabilidade**: expõe as 6 rotas do módulo sob a barreira deny-by-default
(`requireRole`, mesmo padrão de `tira.routes.ts`/`contents.routes.ts`, árvore plana). O
parser multipart (`multer({ storage: multer.memoryStorage(), limits: { fileSize:
env.VISUAL_ASSOCIATIONS_MAX_FILE_SIZE_BYTES } })`) é instanciado uma única vez no topo do
módulo (não por requisição) e usado como middleware nas 2 rotas de escrita com arquivo;
`multer` recusa (antes do handler, `NFR-022-004`) qualquer corpo além do limite configurado
— **EMENDA em `src/http/middlewares/error-handler.ts`** (COMP-023-017) mapeia o erro do
`multer` (`MulterError`, código `LIMIT_FILE_SIZE`) para 413 com mensagem genérica, nunca
stack. `GET .../:id/image` é leitura pura (sem `verifyOrigin`, mesmo raciocínio de `GET
/contents/:id/strip` em `tira.routes.ts`) e lê `imageData`/`mimeType` da linha via
`getVisualAssociationBinary` e responde `res.type(mimeType).send(imageData)` — sem stream de
arquivo, é um `Buffer` já em memória — nunca `express.static` (DEC-023-004), porque
`express.static` não teria como checar sessão/papel por requisição.
**Realiza**: FR-022-003, FR-022-010, FR-022-011, FR-022-025, NFR-022-003, NFR-022-004, NFR-022-005
**Interface pública** (árvore plana; caminho completo em cada `requireRole`):
- `GET /visual-associations` → `requireRole('GET','/visual-associations','EDITOR','ADMIN')`
  — lista/busca por categoria, paginada (FR-022-010/FR-022-011).
- `GET /visual-associations/categories` → `requireRole('GET',
  '/visual-associations/categories','EDITOR','ADMIN')` — sugestão de categoria
  (FR-022-025).
- `POST /visual-associations` → `verifyOrigin` + `upload.single('image')` +
  `requireRole('POST','/visual-associations','EDITOR','ADMIN')` — cria (FR-022-001/002/003/
  004).
- `PATCH /visual-associations/:id` → `verifyOrigin` + `upload.single('image')` (arquivo
  opcional) + `requireRole('PATCH','/visual-associations/:id','EDITOR','ADMIN')` — edita
  in-place (FR-022-006); guarda de autoria dentro do service (FR-022-023).
- `DELETE /visual-associations/:id` → `verifyOrigin` + `requireRole('DELETE',
  '/visual-associations/:id','EDITOR','ADMIN')` — remove, recusa se vínculo ativo
  (FR-022-007/008).
- `GET /visual-associations/:id/image` → `requireRole('GET',
  '/visual-associations/:id/image','EDITOR','ADMIN')` — entrega do binário, sem
  `verifyOrigin` (leitura pura, NFR-022-005).
**Dependências**: COMP-023-005, COMP-023-001

### COMP-023-007: Extensão de `tira.schema.ts` — schema do vínculo
**Responsabilidade**: schema do corpo de `POST .../frames/:frameId/visual-association`
(mesmo arquivo de PLAN-012, `frameTextSchema` como molde de estilo).
**Realiza**: nenhum diretamente — schema de validação consumido por COMP-023-008
**Interface pública**:
```ts
export const linkVisualAssociationSchema = z.object({
  visualAssociationId: z.uuid('Identificador de associação visual inválido.'),
});
export type LinkVisualAssociationInput = z.infer<typeof linkVisualAssociationSchema>;
```
**Dependências**: COMP-012-003

### COMP-023-008: Extensão de `tira.service.ts` — vincular/desvincular associação visual ao Quadro
**Responsabilidade**: `linkVisualAssociationToFrame`/`unlinkVisualAssociationFromFrame`,
mesma ordem de guardas de `updateMnemonicFrameText`/`removeMnemonicFrame` (TASK-012-007):
1. `assertRawContentReachable` — 1ª chamada, sempre (NFR-011-001/006 herdado, FR-022-018).
2. `findStripId` — localiza o `stripId` a partir do `rawContentId` da URL (nunca aceito cru
   de outro lugar).
3. Confirma que `visualAssociationId` existe (leitura comum a todo EDITOR/ADMIN,
   FR-022-023 — sem escopo de autoria aqui, é a associação que é comum, não o Quadro).
4. Guarda de pertencimento **e** escrita no MESMO `updateMany` (`where: { id: frameId,
   stripId }`, mesmo padrão anti-confused-deputy das demais mutações de Quadro).
5. **Idempotência** (FR-022-021, 2ª cláusula): se o Quadro já aponta para o MESMO
   `visualAssociationId`, no-op — devolve a Tira sem escrever nem emitir evento (3º ramo da
   árvore de decisão, mesmo raciocínio da reabertura sem geração de `openMnemonicStrip`).
6. Caso contrário (1º vínculo do Quadro ou substituição — a confirmação explícita da
   substituição, FR-022-021 1ª cláusula, é UI: o cliente só chama esta rota depois que o
   EDITOR confirma no diálogo `role="alertdialog"` já usado por `mnemonic-strip-board.tsx`
   para remoção de Quadro): grava `visualAssociationId`, registra
   `VisualAssociationLinkEvent` (`wasReuse` = havia **outro** Quadro além deste já apontando
   para a mesma associação **antes** desta escrita, contagem feita sob o mesmo filtro que
   exclui Conteúdo bruto soft-deleted de FR-022-019 — DEC-023-011) e chama
   `recordProductionStageEvent(tx, { rawContentId, stageType: 'ASSOCIACAO_VISUAL', actorId:
   actor.id, now: new Date() })` — decide ABERTURA/CONCLUSAO/RETRABALHO pelo histórico já
   registrado para o par (`rawContentId`, `'ASSOCIACAO_VISUAL'`), satisfazendo FR-022-024
   (1ª mutação humana de vínculo emite; CRUD isolado do acervo — COMP-023-005 — nunca
   chama esta função, logo nunca emite).
7. `unlinkVisualAssociationFromFrame`: mesmo 1-4; se o Quadro já não tem vínculo, no-op (sem
   evento); caso contrário grava `visualAssociationId: null` e emite evento (mesma regra do
   passo 6, sem `VisualAssociationLinkEvent` — a métrica de reuso é sobre CRIAÇÃO de
   vínculo, não sobre remoção).
Fail-secure: escrita do vínculo, do log de reuso e a emissão do evento na MESMA
`$transaction` — falha em qualquer passo não deixa vínculo nem log parcial.
**Realiza**: FR-022-013, FR-022-014, FR-022-015, FR-022-018, FR-022-021, FR-022-023, FR-022-024
**Interface pública**:
```ts
export async function linkVisualAssociationToFrame(
  rawContentId: string,
  frameId: string,
  visualAssociationId: string,
  actor: ContentActor,
  db: MnemonicStripClient = prisma,
): Promise<MnemonicStripDetail>;

export async function unlinkVisualAssociationFromFrame(
  rawContentId: string,
  frameId: string,
  actor: ContentActor,
  db: MnemonicStripClient = prisma,
): Promise<MnemonicStripDetail>;
```
`MnemonicStripClient` (tipo existente) ganha as chaves `visualAssociation` e
`visualAssociationLinkEvent`. `MnemonicFrameDetail` ganha o campo escalar
`visualAssociationId: string | null` (flat — mantém a extração textual de
`tira-frontend-contract.test.ts` funcionando sem mudança de mecanismo, COMP-023-011); a
imagem em si é resolvida pelo cliente via `GET /visual-associations/:id/image`, nunca
embutida no payload da Tira.
**Dependências**: COMP-012-004, COMP-012-005, COMP-023-004, COMP-023-005, COMP-023-007

### COMP-023-009: Extensão de `tira.routes.ts` — rotas de vínculo
**Responsabilidade**: 2 rotas novas, mesma árvore plana de PLAN-012 — cada uma com
`requireRole` próprio na montagem (nenhuma herda de vizinha).
**Realiza**: FR-022-013, FR-022-015, NFR-022-003
**Interface pública**:
- `POST /contents/:id/strip/frames/:frameId/visual-association` → `verifyOrigin` +
  `requireRole('POST','/contents/:id/strip/frames/:frameId/visual-association','EDITOR',
  'ADMIN')` — vincula (body: `LinkVisualAssociationInput`).
- `DELETE /contents/:id/strip/frames/:frameId/visual-association` → `verifyOrigin` +
  `requireRole('DELETE','/contents/:id/strip/frames/:frameId/visual-association','EDITOR',
  'ADMIN')` — desvincula.
**Dependências**: COMP-012-006, COMP-023-008

### COMP-023-010: Extensão de `types/domain.ts` (frontend)
**Responsabilidade**: acrescenta `visualAssociationId` a `MnemonicFrame` (campo flat, mesma
forma de `MnemonicFrameDetail`/COMP-023-008) e as interfaces novas espelhando
`VisualAssociationDetail`/`VisualAssociationSummary` (COMP-023-005), nomes canônicos vencendo
do lado do backend.
**Realiza**: FR-022-016
**Interface pública**:
```ts
export interface VisualAssociation {
  id: string;
  authorId: string;
  category: string;
  cognitiveDescription: string;
  mimeType: string;
  createdAt: string;
  updatedAt: string;
}

export interface VisualAssociationSummary {
  id: string;
  category: string;
  linkCount: number;
  createdAt: string;
}
```
(`MnemonicFrame` ganha `visualAssociationId: string | null` no arquivo já existente.)
**Dependências**: nenhuma

### COMP-023-011: Rede de paridade cross-repo nova — `visual-associations-frontend-contract.test.ts`
**Responsabilidade**: arquivo novo, molde de `tira-frontend-contract.test.ts` (leitura
textual, sem AST): compara `VisualAssociationDetail`/`VisualAssociationSummary`
(`visual-associations.service.ts`, backend) contra `VisualAssociation`/
`VisualAssociationSummary` (`types/domain.ts`, frontend) campo-a-campo. **Estende** também
`tira-frontend-contract.test.ts` existente para incluir `visualAssociationId` na comparação
de `MnemonicFrameDetail`/`MnemonicFrame` (o array de campos esperados em
`extractInterfaceFields(...)` cresce de 4 para 5 — mutante: renomear
`visualAssociationId` só de um lado precisa reprovar).
**Realiza**: nenhum diretamente — teste de paridade cross-repo; verifica NFR-022-006
(não-regressão da rede existente), não realiza FR de produto
**Interface pública**: casos de teste; nenhum código de produção.
**Dependências**: COMP-023-004, COMP-023-010

### COMP-023-012: Extensão de `store/api.ts` (RTK Query)
**Responsabilidade**: endpoints novos, tags `'VisualAssociation'`/`'VisualAssociationList'`
acrescentadas a `TAG_TYPES`. Upload/edição usam `FormData` no `query` (RTK Query aceita
`body: FormData` sem `Content-Type` manual — o browser define o boundary).
**Realiza**: nenhum diretamente — camada de wiring HTTP consumida pelos componentes de tela
(COMP-023-013/014/015/016, §7), que são quem realiza cada FR do ponto de vista do frontend
**Interface pública**:
- `listVisualAssociations` (query: `{ category?: string; page?: number; perPage?: number }`,
  `providesTags: ['VisualAssociationList']`)
- `suggestVisualAssociationCategories` (query: `{ q: string }`)
- `createVisualAssociation` (mutation, `FormData` — `image`, `category`,
  `cognitiveDescription`; `invalidatesTags: ['VisualAssociationList']`)
- `updateVisualAssociation` (mutation, `FormData` parcial; `invalidatesTags:
  ['VisualAssociationList']`)
- `removeVisualAssociation` (mutation; `invalidatesTags: ['VisualAssociationList']`)
- `linkVisualAssociationToFrame` / `unlinkVisualAssociationFromFrame` (mutations sobre
  `/contents/:rawContentId/strip/frames/:frameId/visual-association`,
  `invalidatesTags: ['MnemonicStrip']` — mesma tag de PLAN-012, a Tira inteira já vem
  reordenada/atualizada)
**Dependências**: COMP-023-010

### COMP-023-013: Tela Server Component — `(interno)/visual-library/page.tsx`
**Responsabilidade**: casca, mesmo padrão de `(interno)/content/page.tsx` — só compõe o
client component, `<h1>` + nenhum link de volta específico (a navegação principal já cobre
a rota).
**Realiza**: FR-022-010
**Interface pública**: rota `/visual-library`. **Correção da TASK (achado do redator,
confirmado por leitura direta do código real — a premissa abaixo estava errada)**:
`/visual-library` NÃO cai no prefixo hoje; `INTERNAL_ROUTE_PREFIXES`
(`internal-routes.ts:14`) e as 2 entradas de `config.matcher` (`proxy.ts:97`) precisam do
segmento novo, no mesmo diff desta TASK — extensão puramente aditiva do allowlist
deny-by-default, mesmo padrão de `'studio'`/`'content'`.
**Dependências**: COMP-023-014

### COMP-023-014: Client component — `visual-library-board.tsx`
**Responsabilidade**: `'use client'`; lista/filtra por categoria (`useListVisualAssociationsQuery`),
formulário de upload (`<input type="file">` + campos de categoria/descrição, sugestão de
categoria via `useSuggestVisualAssociationCategoriesQuery` — texto digitado dispara a
consulta com debounce simples), edição in-place, remoção (bloqueada com mensagem quando o
service recusa por vínculo ativo — exibe os Quadros/Tiras alcançáveis devolvidos em
`details.reachableLinks` + contagem de fora do alcance). Três estados observáveis por ação
(FR-022-005/FR-022-009), texto de interface em pt-BR.
**Realiza**: FR-022-005, FR-022-009, FR-022-010, FR-022-012, FR-022-025
**Interface pública**: componente client `visual-library-board`.
**Dependências**: COMP-023-012, COMP-023-015

### COMP-023-015: Client component reusável — `visual-association-picker.tsx`
**Responsabilidade**: `'use client'`; seletor embutido (usado por COMP-023-014 e
COMP-023-016) — busca/filtra por categoria a partir de `useListVisualAssociationsQuery`,
mostra miniatura via `next/image` (`unoptimized`, endpoint devolve o binário puro) com URL
`/api/v1/visual-associations/{id}/image` — o prefixo `/api/v1` é obrigatório (o
componente de imagem não passa pelo `baseUrl` do RTK Query, que já prefixa
internamente, `store/api.ts:155-158`) para o `rewrites()` de `next.config.ts`
encaminhar same-origin ao backend (DEC-021-001); `next/image` em vez de `<img>` cru
evita o warning `@next/next/no-img-element` (`eslint-config-next/core-web-vitals`) e
devolve o id escolhido via callback — não faz a chamada de vínculo em si (isso é
responsabilidade de quem o usa).
**Realiza**: FR-022-013
**Interface pública**: componente client `visual-association-picker`, prop
`onSelect(associationId: string): void`.
**Dependências**: COMP-023-012

### COMP-023-016: Enxerto em `mnemonic-strip-board.tsx`
**Responsabilidade**: por Quadro (ponto de enxerto: `mnemonic-strip-board.tsx:216,308-310`,
`code-scout`), exibe a miniatura da associação vinculada (se `frame.visualAssociationId !==
null`) com ação de desvincular, e abre `COMP-023-015` para vincular quando ausente.
Substituição (Quadro já vinculado a A, EDITOR escolhe B) reusa o diálogo de confirmação já
existente em `mnemonic-strip-board.tsx:395-426` (`role="alertdialog"`, foco programático) —
mesma UX de confirmação de remoção de Quadro, texto adaptado. Três estados observáveis por
ação de vincular/desvincular (FR-022-017).
**Realiza**: FR-022-013, FR-022-015, FR-022-016, FR-022-017
**Interface pública**: extensão do componente client `mnemonic-strip-board` existente
(COMP-012-012).
**Dependências**: COMP-012-012, COMP-023-012, COMP-023-015

### COMP-023-017: EMENDA em `src/http/middlewares/error-handler.ts`
**Responsabilidade**: novo ramo no `errorHandler` (ao lado do `ZodError` já existente,
`error-handler.ts:24-39`) que reconhece `MulterError` (`import { MulterError } from
'multer'`) e devolve 413 com mensagem genérica pt-BR quando `code === 'LIMIT_FILE_SIZE'`
(NFR-022-004), 400 genérico para os demais códigos do multer — nunca stack, nunca o nome do
campo interno do multer. Nenhuma outra branch do handler é tocada.
**Realiza**: NFR-022-004
**Interface pública**: n/a (alteração de middleware existente).
**Dependências**: nenhuma

## 4. Fluxos principais

**F-1 Upload e criação de associação visual.** `POST /visual-associations` (multipart) →
`multer` (memory storage, limite de tamanho) → Zod valida `category`/`cognitiveDescription`
→ `detectImageSignature(buffer)`; `null` → 400 sem persistir nada (FR-022-002); formato
válido → `$transaction`: `create` da linha com `imageData`/`mimeType` já no mesmo INSERT
(`authorId = actor.id`, nunca do input) → responde 201 com `VisualAssociationDetail`.

**F-2 Edição in-place, com ou sem troca de imagem.** `PATCH /visual-associations/:id` →
`assertVisualAssociationWritable` (autor ou ADMIN, senão 403) → sem arquivo novo: `update`
só dos campos de texto enviados; com arquivo novo: `detectImageSignature` → `update` da linha
com `imageData`/`mimeType` novos no mesmo UPDATE (substituição atômica, sem arquivo antigo
para apagar à parte).

**F-3 Remoção com trava de vínculo.** `DELETE /visual-associations/:id` →
`assertVisualAssociationWritable` → conta vínculos ativos (exclui Conteúdo bruto
soft-deleted, FR-022-019); 0 → `delete` da linha (o binário some junto, é a mesma linha); ≥1 → 409
`ConflictError` com `details.reachableLinks` (Quadros/Tiras que o `actor` alcança por
autoria — ADMIN vê todos) e `details.outOfReachCount` (o resto, sem identificar).

**F-4 Navegação/busca por categoria.** `GET /visual-associations?category=...` → filtro
normalizado (trim + case-fold, DEC-023-008) → cada item com `linkCount` (mesma exclusão de
FR-022-019). `GET /visual-associations/categories?q=...` → categorias distintas do acervo
que combinam com `q` (normalizado), grafia original preservada (FR-022-025).

**F-5 Vínculo de associação a um Quadro.** `POST /contents/:id/strip/frames/:frameId/
visual-association` → cadeia de alcance (FR-022-018) → existência da associação (leitura
comum) → idempotente (mesma associação já vinculada) → no-op; 1º vínculo do Quadro ou
substituição (cliente já confirmou no diálogo) → grava, registra
`VisualAssociationLinkEvent` (reuso ou não) e emite `ProductionStageEvent`
(`ASSOCIACAO_VISUAL`) na mesma transação.

**F-6 Desvínculo.** `DELETE .../visual-association` → mesma cadeia de alcance → grava
`visualAssociationId: null` (no-op se já nulo) → emite evento se houve mudança real.

**F-7 Remoção de Quadro com vínculo ativo (F4, sem mudança de código).** `removeMnemonicFrame`
(COMP-012-004, inalterado) apaga a linha do `MnemonicFrame` — o vínculo desaparece junto
(era um campo daquela linha), a `VisualAssociation` nunca é tocada: FR-022-020 é satisfeito
pela direção da FK (Frame → VisualAssociation), não por código novo.

**F-8 Entrega do binário.** `GET /visual-associations/:id/image` → sessão EDITOR/ADMIN
válida (A-023-001) → linha existe → lê `imageData`/`mimeType` da linha → `res.type(mimeType).
send(imageData)` — nenhum caminho de arquivo em nenhum momento (superfície de path traversal
não existe nesta fatia).

## 5. Modelo de dados

Aditivo — nenhuma coluna, tabela ou valor de enum existente é removido ou alterado
destrutivamente. Migração exige autorização do Diretor antes de `prisma migrate dev`
(DEC-023-007, §9).

```prisma
enum ProductionStageType {
  CONTEUDO_BRUTO
  QUEBRA_DA_REGRA
  TIRA_MNEMONICA
  ASSOCIACAO_VISUAL // NOVO (F5) — aditivo, sem redesenho do mecanismo (NFR-009-001/DEC-010-001)
}

model VisualAssociation {
  id String @id @default(uuid(7))

  authorId String
  /// Restrict: mesmo padrão de RawContent.authorId — autor com associação criada não pode
  /// ser hard-deletado enquanto ela existir (DEC-006-008).
  author   User   @relation("VisualAssociationAuthor", fields: [authorId], references: [id], onDelete: Restrict)

  category              String
  cognitiveDescription  String

  /// Binário da imagem, guardado na própria linha (bytea) — DEC-023-002. mimeType é
  /// sempre o detectado por assinatura de bytes (image-signature.ts), nunca o
  /// Content-Type declarado pelo cliente (NFR-022-001).
  imageData Bytes
  mimeType  String

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  frames MnemonicFrame[]

  @@map("visual_associations")
}

model MnemonicFrame {
  // ... campos existentes (id, stripId, strip, text, position, originBlock, createdAt, updatedAt) ...

  /// NOVO (F5): no máximo 1 associação visual por Quadro (FR-022-021). SetNull: remover a
  /// VisualAssociation exige trava de vínculo ativo (FR-022-008) — nunca chega a apagar
  /// um MnemonicFrame; a direção inversa (remover o Quadro) apaga a linha inteira e o
  /// vínculo some junto, sem tocar a VisualAssociation (FR-022-020).
  visualAssociationId String?
  visualAssociation   VisualAssociation? @relation(fields: [visualAssociationId], references: [id], onDelete: SetNull)

  @@unique([stripId, position])
  @@map("mnemonic_frames")
}

/// Log mínimo de instrumentação da métrica de §1.3 da SPEC-022 — não é trilha de auditoria
/// (RISK-022-004): sem relação/FK para visualAssociationId (deliberado, DEC-023-011), sobrevive
/// à remoção da associação e nunca bloqueia (FR-022-007/008 leem só MnemonicFrame, nunca este
/// log). Uma linha por vínculo REAL criado (nunca por idempotente, nunca por desvínculo).
model VisualAssociationLinkEvent {
  id                  String   @id @default(uuid(7))
  visualAssociationId String
  wasReuse            Boolean
  occurredAt          DateTime @default(now())

  @@index([occurredAt])
  @@map("visual_association_link_events")
}
```

## 6. Decisões arquiteturais

### DEC-023-001: Cardinalidade do vínculo Quadro↔Associação visual — FK N:1, não tabela de junção N:N
**Contexto**: SPEC-022 (FR-022-021, resolução R9 do `po`) fixa no máximo 1 associação visual
por Quadro; a mesma associação pode ilustrar vários Quadros.
**Decisão**: FK nullable `MnemonicFrame.visualAssociationId` — cardinalidade N:1
(muitos Quadros → 1 associação), 100% representável sem tabela intermediária.
**Alternativas consideradas**:
- Tabela de junção N:N (`FrameVisualAssociation`), descartada porque a SPEC fixa
  explicitamente no máximo 1 associação por Quadro — uma junção N:N introduziria a
  possibilidade estrutural de múltiplos vínculos simultâneos que o domínio proíbe, exigindo
  uma constraint adicional (`@@unique(frameId)` na junção) para reimpor via schema o que a
  FK simples já impõe de graça; complexidade sem necessidade presente.
**Consequências**: substituir o vínculo de um Quadro é um `UPDATE` de 1 linha, não um
`DELETE`+`INSERT` transacional numa tabela à parte.
**Reabrir se**: a SPEC relaxar para múltiplas associações simultâneas por Quadro (RISK-022
correspondente já cita isso como aditivo futuro).
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-023-002: Armazenamento do binário — coluna `Bytes` no Postgres, não filesystem nem blob externo
**Contexto**: A-022-003 (SPEC) delega esta escolha ao PLAN. A primeira redação deste PLAN
havia escolhido sistema de arquivos local — achado próprio do PLAN (TRISK-023-003) mostrou
que isso é INCOMPATÍVEL com a topologia real de deploy: o backend roda como function
serverless na Vercel (`api/index.ts`, mesma topologia de PLAN-021), cujo filesystem é
efêmero e por instância — um upload não sobreviveria de forma confiável até a próxima
leitura. Não é risco a aceitar e medir depois; é defeito conhecido de alta probabilidade.
**Decisão**: coluna `imageData Bytes` na própria linha de `VisualAssociation`, no MESMO
Postgres que hospeda todo o domínio — zero infraestrutura nova, sem o problema de
efemeridade (o banco é o backing store persistente e compartilhado entre instâncias, ao
contrário do filesystem local da function).
**Alternativas consideradas**:
- Sistema de arquivos local, descartada — incompatível com a topologia serverless real do
  backend (custo: feature que parece funcionar em dev/teste e falha silenciosamente em
  produção, TRISK-023-003 original).
- Blob externo (S3-like), descartada — exige infraestrutura/credencial nova não contratada
  para esta fatia (mesma razão original: provisionar conta, bucket, IAM e segredo novo
  antes de entregar a fatia).
**Consequências**: linhas maiores na tabela (até ~5 MB cada, A-022-005) — aceitável no
volume inicial de uma ferramenta interna; leitura do binário é 1 `SELECT` a mais, sem
stream de arquivo do SO.
**Reabrir se**: o volume real do acervo ou o custo de armazenamento em linha (medição real,
gate 10) justificar mover para blob externo — a interface de COMP-023-003 já isola essa
troca a um único arquivo.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-023-003: Upload multipart via `multer` (memory storage)
**Contexto**: greenfield confirmado pelo `code-scout` — nenhuma dependência de
upload/multipart hoje nos dois repos.
**Decisão**: `multer` com `memoryStorage()` (nunca `diskStorage()` do próprio multer) — o
service só persiste o binário (coluna `imageData`, DEC-023-002) depois de
`detectImageSignature` confirmar o formato.
**Alternativas consideradas**:
- Parser multipart artesanal (sem lib), descartado — reimplementar parsing de
  `multipart/form-data` com boundary, limites e encoding correto é superfície de bug e de
  segurança (parsing de protocolo é exatamente onde libs maduras têm vantagem de
  fuzzing/CVE tracking que um parser novo não tem).
- `multer` com `diskStorage()`, descartado — gravaria o arquivo do cliente no disco **antes**
  da validação de assinatura de bytes, abrindo uma janela em que um arquivo não-raster
  chega a tocar o filesystem antes de ser recusado.
**Consequências**: dependência nova sujeita a `/keelson:audit`/gate 8 (TRISK-023-002).
**Reabrir se**: nunca — dependência madura, sem alternativa nativa do Node 22 para parsing
multipart robusto.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-023-004: Entrega do binário via rota autenticada com stream, nunca `express.static`
**Contexto**: NFR-022-005/AC-022-023 exigem a mesma barreira deny-by-default na entrega do
binário, não só na rota/tela de gestão.
**Decisão**: `GET /visual-associations/:id/image` sob `requireRole`, lê a linha
(`imageData`/`mimeType`) e responde `res.type(mimeType).send(imageData)`.
**Alternativas consideradas**:
- `express.static(STORAGE_DIR)`, descartada — serve qualquer arquivo do diretório sem
  checagem de sessão/papel por requisição; a única defesa seria esconder o caminho, o que
  não é controle de acesso (mesma régua do perfil frontend §6.3: "esconder não é
  autorizar").
**Consequências**: 1 rota HTTP a mais por imagem servida, sem cache de CDN/`express.static`
— aceitável para o volume esperado desta fatia (ferramenta interna).
**Reabrir se**: o volume de leitura de imagens justificar CDN/cache com token assinado de
vida curta.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-023-005: Evento de etapa reusa `recordProductionStageEvent`/`decideStageTransition`
**Contexto**: F3 (SPEC-009) já entrega um mecanismo genérico de evento de etapa, reusado por
F2 e F4; FR-022-024 exige emissão só na 1ª mutação humana de vínculo de um Conteúdo bruto,
nunca no CRUD isolado do acervo.
**Decisão**: valor novo aditivo `ASSOCIACAO_VISUAL` em `ProductionStageType`; `link`/`unlink`
chamam `recordProductionStageEvent` dentro da MESMA `$transaction` do vínculo, exceto quando
a operação é idempotente (nada muda) — mesma exceção que `openMnemonicStrip` já aplica à
reabertura sem geração.
**Alternativas consideradas**:
- Mecanismo de evento próprio para esta fatia, descartado — duplicaria a máquina de decisão
  ABERTURA/CONCLUSAO/RETRABALHO já testada e usada por 2 fatias anteriores, sem nenhum
  requisito novo que ela não cubra.
**Consequências**: o payload do evento continua mínimo (herda RISK-011-004/TRISK-012-004) —
não distingue qual associação foi vinculada; é por isso que a métrica de reuso precisa do
log dedicado (DEC-023-011), não deste mecanismo.
**Reabrir se**: nunca — mecanismo estável, sem sinal de que precise mudar.
**Irreversível**: não
**Aderência à ficha/perfil**: herdada

### DEC-023-006: Guarda de escrita vs. leitura do acervo
**Contexto**: FR-022-023 — escrita restrita ao autor (ADMIN irrestrito); leitura/busca/
vínculo comuns a todo EDITOR/ADMIN.
**Decisão**: `assertVisualAssociationWritable(association, actor)` — guarda pura (recebe a
linha já lida, sem I/O próprio), chamada só por `updateVisualAssociation`/
`removeVisualAssociation`; nenhuma chamada equivalente em `listVisualAssociations`/
`getVisualAssociationBinary`/`linkVisualAssociationToFrame` (leitura/vínculo não filtram por
autoria da associação).
**Alternativas consideradas**:
- Reusar o padrão de `scopeWhere`/`ACTIVE_RAW_CONTENT_WHERE` (mascarar como 404 uniforme,
  mesmo padrão de `assertRawContentReachable`), descartada — esse padrão existe para não
  vazar um oráculo de EXISTÊNCIA a quem não alcança o recurso; aqui a existência já é
  pública (leitura comum, FR-022-023), então recusar com 403 explícito não vaza nada que o
  ator já não soubesse.
**Consequências**: erro de escrita é 403 (`ForbiddenError`), não 404 — comportamento
observável distinto do padrão de `RawContent`, documentado para não ser "corrigido" por
engano numa rodada futura.
**Reabrir se**: nunca — decorre diretamente de FR-022-023 (leitura comum), que não tem
condição de mundo prevista para mudar nesta fatia.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-023-007: Migração 100% aditiva; execução exige autorização do Diretor
**Contexto**: CLAUDE.md do workspace — toda migração de schema exige perguntar ao Diretor
antes de executar.
**Decisão**: o diff de schema desta fatia (`VisualAssociation`, FK em `MnemonicFrame`,
`ASSOCIACAO_VISUAL`, `VisualAssociationLinkEvent`) é só `CREATE TABLE`/`ALTER TABLE ADD
COLUMN`/`ALTER TYPE ADD VALUE` — 0 `DROP`/`ALTER` destrutivo. A TASK de migração gera o
arquivo (`prisma migrate dev`) e **para antes de aplicar**, perguntando ao Diretor (mesmo
padrão de PLAN-006/TRISK-006-001).
**Alternativas consideradas**:
- "Gerar e aplicar" sem pergunta, descartada — viola a regra explícita do CLAUDE.md do
  workspace; nenhuma migração deste projeto é aplicada silenciosamente.
**Consequências**: a TASK de migração fica com um passo humano no meio — não é
automatizável dentro do ciclo autônomo.
**Reabrir se**: nunca — regra do workspace (CLAUDE.md), não desta fatia.
**Irreversível**: não
**Aderência à ficha/perfil**: herdada

### DEC-023-008: Normalização de categoria em código de aplicação, não em coluna/índice derivado
**Contexto**: NFR-022-007 (SHOULD) exige trim + case-fold na exibição/filtro, sem alterar o
texto livre armazenado (RISK-022-001).
**Decisão**: `normalizeCategoryKey` (pura, trim + `toLowerCase()`) usada em memória para
agrupar sugestões (FR-022-025) e comparar o filtro (`category` da query, normalizado, contra
`category` armazenado via `mode: 'insensitive'` do Prisma após `trim()` do valor de
entrada).
**Alternativas consideradas**:
- Coluna derivada/gerada (`categoryNormalized`) com índice funcional, descartada — exige
  migração adicional e uma 2ª cópia do dado sincronizada em toda escrita, para um SHOULD
  sobre um acervo cujo volume inicial (ferramenta interna) não paga esse custo agora.
**Consequências**: categoria armazenada com espaçamento interno irregular (raro) pode
escapar do agrupamento perfeito — gap residual aceito (não é o caso comum: trim cobre
bordas, `insensitive` cobre capitalização).
**Reabrir se**: o volume do acervo (Q-022-001) ou uma queixa real de fragmentação exigir
normalização garantida por índice.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-023-009: Rota de vínculo mora em `tira.routes.ts`, não em `visual-associations`
**Contexto**: o vínculo altera um `MnemonicFrame` específico (`/contents/:id/strip/
frames/:frameId/visual-association`), enquanto CRUD/leitura do acervo não pertence a nenhum
Conteúdo bruto.
**Decisão**: as 2 rotas de vínculo/desvínculo entram em `tira.routes.ts`/`tira.service.ts`
(módulo já dono da cadeia Frame→Strip→RuleBreakdown→RawContent); `visual-associations`
nunca resolve `rawContentId`/`frameId`.
**Alternativas consideradas**:
- Rota de vínculo dentro do módulo `visual-associations`, recebendo `rawContentId`/
  `frameId` como parâmetros soltos, descartada — duplicaria `findStripId`/
  `assertRawContentReachable` (ou importaria funções internas de outro módulo por trás do
  schema→service→routes, invertendo a direção de dependência que o perfil backend define,
  §4) e arriscaria a guarda de alcance divergir entre os dois módulos com o tempo.
**Consequências**: `tira.service.ts` importa de `visual-associations.service.ts` (para
confirmar existência da associação), nunca o inverso.
**Reabrir se**: nunca — decorre da topologia de recursos (Quadro é dono do vínculo), estável.
**Irreversível**: não
**Aderência à ficha/perfil**: herdada (mesma direção de dependência de módulo do perfil, §4)

### DEC-023-010: Paginação simples (page/perPage) na listagem da biblioteca
**Contexto**: Q-022-001 (SPEC) deixa para o PLAN avaliar se a listagem precisa de
paginação/ordenação.
**Decisão**: `page`/`perPage` (default 1/20, teto 100), mesmo padrão de `listRawContents`
(`contents.service.ts`).
**Alternativas consideradas**:
- Sem paginação (devolver o acervo inteiro), descartada — RISK-022-005 da SPEC já nomeia
  custo de banda real com N grande e arquivos de até 5 MB (A-022-005); sem paginação a
  listagem cresce sem teto.
- Paginação por cursor, descartada — complexidade extra (cursor opaco, ordenação estável)
  sem necessidade presente; o padrão offset já é o idiomático do resto do projeto
  (`listRawContents`).
**Consequências**: nenhuma mudança de contrato quando o acervo crescer — só o número de
páginas muda.
**Reabrir se**: o offset ficar caro (medição real do gate 10) com o acervo grande — aí
cursor.
**Irreversível**: não
**Aderência à ficha/perfil**: herdada

### DEC-023-011: Log dedicado `VisualAssociationLinkEvent` para a métrica de reuso
**Contexto**: SPEC-022 §1.3 (Fonte de medição: instrumentação) exige uma consulta que conte,
**na criação de cada vínculo**, se a associação vinculada é reuso de uma já existente ou
recém-criada no mesmo fluxo — sobre um período (ex.: 60 dias corridos, A-022-010).
**Decisão**: tabela nova, mínima (`visualAssociationId`, `wasReuse`, `occurredAt`), 1 linha
por vínculo REAL criado (nunca por operação idempotente nem por desvínculo), escrita na
MESMA `$transaction` de `linkVisualAssociationToFrame`.
**Alternativas consideradas**:
- Reconstituir do estado atual (`groupBy` sobre `MnemonicFrame.visualAssociationId`),
  descartada — só devolve a taxa de reuso **atual** (2ª métrica, secundária, já suficiente
  para ela); não recupera "no momento em que ESTE vínculo foi criado, a associação já tinha
  outro Quadro" depois que vínculos são desfeitos/refeitos — a métrica primária de §1.3 é
  sobre o FLUXO no tempo, não sobre a foto do estado hoje.
- Estender o payload do `ProductionStageEvent` genérico com `visualAssociationId`,
  descartada — o mecanismo (COMP de F3) é deliberadamente mínimo e compartilhado por 3
  fatias (RISK-011-004/TRISK-012-004 já aceitam esse limite); acoplar um campo específico
  desta fatia a um mecanismo genérico usado por outras é o tipo de mudança que se propaga
  para trás.
**Consequências**: mais uma tabela pequena, sem relação/FK para `VisualAssociation`
(DEC deliberada — TRISK-023-007); a razão exposta (`ratio = reuso/total no período`) é
calculável por uma consulta simples (`COUNT(*) FILTER (WHERE wasReuse) / COUNT(*)` sobre
`occurredAt >= desde`) — demonstrável no gate 9 sem UI nova.
**Reabrir se**: nunca — se a métrica virar SHOULD/dispensável no futuro, a tabela
some junto (não é referenciada por nenhuma regra de negócio, só por leitura).
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-023-012: Nenhum metadado do cliente (nome de arquivo, Content-Type declarado) é usado para nada
**Contexto**: perfil backend §6.6 ("upload: nome gerado pelo servidor, nunca `originalname`/
`mimetype` do cliente"). Com o binário guardado como `Bytes` no Postgres (DEC-023-002), não
existe mais path de arquivo em nenhum momento — path traversal não é superfície desta
fatia. O que resta é não confiar em metadado NÃO-VERIFICADO do multipart.
**Decisão**: `originalname` do multipart nunca é lido para nenhuma finalidade (nem exibição,
nem persistência, nem log); `mimeType` gravado e devolvido na resposta é SEMPRE o detectado
por assinatura de bytes (`image-signature.ts`), nunca o `Content-Type` declarado pelo
cliente.
**Alternativas consideradas**:
- Sanitizar e persistir o nome original do cliente para fins de exibição, descartada — sem
  requisito da SPEC para isso, e reabrir essa superfície sem necessidade reintroduziria uma
  classe de validação (encoding, caracteres de controle) que a ausência total do dado
  elimina de graça.
**Consequências**: o nome original do arquivo do usuário nunca aparece em lugar nenhum do
sistema (nem log); se um dia for preciso exibir "nome do arquivo enviado" na UI, isso vira
metadado novo a decidir.
**Reabrir se**: nunca — ausência do dado é estritamente mais simples e mais segura que
qualquer sanitização.
**Irreversível**: não
**Aderência à ficha/perfil**: herdada (perfil já recomenda não confiar em metadado do
cliente)

## 7. Mapeamento FR -> componente

| FR | Componente | AC cobertos |
|----|------------|-------------|
| FR-022-001 | COMP-023-002, COMP-023-005 | AC-022-001 |
| FR-022-002 | COMP-023-002, COMP-023-005 | AC-022-002 |
| FR-022-003 | COMP-023-005, COMP-023-006 | AC-022-003 |
| FR-022-004 | COMP-023-001, COMP-023-005 | AC-022-004 |
| FR-022-005 | COMP-023-014 | AC-022-005 |
| FR-022-006 | COMP-023-005 | AC-022-006 |
| FR-022-007 | COMP-023-005 | AC-022-007 |
| FR-022-008 | COMP-023-005 | AC-022-008 |
| FR-022-009 | COMP-023-005, COMP-023-014 | AC-022-006 |
| FR-022-010 | COMP-023-006, COMP-023-013, COMP-023-014 | AC-022-009 |
| FR-022-011 | COMP-023-005, COMP-023-006 | AC-022-010 |
| FR-022-012 | COMP-023-005, COMP-023-014 | AC-022-009 |
| FR-022-013 | COMP-023-008, COMP-023-009, COMP-023-015, COMP-023-016 | AC-022-011 |
| FR-022-014 | COMP-023-004, COMP-023-008 | AC-022-011 |
| FR-022-015 | COMP-023-008, COMP-023-009, COMP-023-016 | AC-022-012 |
| FR-022-016 | COMP-023-004, COMP-023-010, COMP-023-016 | AC-022-013 |
| FR-022-017 | COMP-023-016 | AC-022-011, AC-022-012 |
| FR-022-018 | COMP-023-008 | AC-022-015 |
| FR-022-019 | COMP-023-005 | AC-022-016 |
| FR-022-020 | COMP-023-004 | AC-022-017 |
| FR-022-021 | COMP-023-008 | AC-022-018 |
| FR-022-022 | COMP-023-005 | AC-022-019 |
| FR-022-023 | COMP-023-005, COMP-023-008 | AC-022-020 |
| FR-022-024 | COMP-023-008, COMP-023-004 | AC-022-021 |
| FR-022-025 | COMP-023-005, COMP-023-006, COMP-023-014 | AC-022-022 |
| NFR-022-001 | COMP-023-002, COMP-023-005 | AC-022-001, AC-022-002 |
| NFR-022-002 | COMP-023-002 | AC-022-002 |
| NFR-022-003 | COMP-023-006, COMP-023-009 | AC-022-014 |
| NFR-022-004 | COMP-023-005, COMP-023-006, COMP-023-017 | AC-022-003 |
| NFR-022-005 | COMP-023-006 | AC-022-023 |
| NFR-022-006 | (suíte existente PLAN-012, sem COMP novo) | AC-022-024 |
| NFR-022-007 | COMP-023-005 | AC-022-025 |

## 8. Riscos técnicos

- **TRISK-023-001** `ALTER TYPE "ProductionStageType" ADD VALUE 'ASSOCIACAO_VISUAL'` dentro
  de migração transacional pode exigir commit intermediário antes de uso na mesma sessão,
  dependendo da versão real do Postgres (mesmo risco de TRISK-012-001) (mitigação: TASK de
  migração aplica e testa a gravação com o valor novo logo em seguida; se recusado, dividir
  em 2 migrações sequenciais).
- **TRISK-023-002** `multer` é dependência nova — supply chain de primeira classe em npm
  (A03) (mitigação: `/keelson:audit` no gate 8 antes do merge; `memoryStorage()` nunca
  `diskStorage()`, service só grava após validar a assinatura de bytes).
- **TRISK-023-003** Linhas de até 5 MB (`imageData Bytes`) aumentam o tamanho da tabela
  `visual_associations` e do backup do banco em proporção ao acervo — sem impacto na
  correção funcional (ao contrário do risco original de storage em disco sob serverless,
  que este PLAN eliminou trocando para bytea, DEC-023-002) (mitigação: aceitável no volume
  inicial de ferramenta interna; medir round-trip de leitura no gate 10; revisitar junto
  com Q-022-001/RISK-022-005 se o acervo crescer muito).
- **TRISK-023-004** Sugestão de categoria (FR-022-025) e normalização (NFR-022-007)
  computadas em código de aplicação sobre todas as categorias distintas do acervo, sem
  agregação SQL — custo cresce com o nº de categorias distintas (mitigação: aceitável para o
  volume inicial de uma ferramenta interna; revisitar junto com Q-022-001 se o acervo
  crescer).
- **TRISK-023-005** Contagem de vínculos por associação (FR-022-012) e a checagem de reuso
  (`wasReuse`) exigem filtro aninhado (`frames` através de `strip→ruleBreakdown→
  rawContent.deletedAt`) por linha listada/vinculada — sem medição real ainda (mesma atenção
  de RISK-022-005 da SPEC; gate 10 mede round-trips reais).
- **TRISK-023-006** `route-authz-matrix.integration.test.ts` (tripwire, hoje 25 pares) precisa
  crescer para as 8 chaves novas desta fatia (6 de `visual-associations.routes.ts` + 2 de
  `tira.routes.ts`) — se qualquer uma ficar de fora, nada acusa isso no boot, só a suíte
  (mesma lição das Waves 4/6 de PLAN-003 sobre allowlist).
- **TRISK-023-007** `VisualAssociationLinkEvent` não tem FK para `VisualAssociation`
  (DEC-023-011) — linhas do log sobrevivem à remoção da associação, apontando para um id que
  deixou de existir (mitigação: aceitável — é indicador operacional, não trilha de auditoria
  formal; mesmo limite já nomeado por RISK-022-004 da SPEC).

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Aderência à ficha/perfil validada
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates)
- [ ] Métrica da SPEC operacional (§1.3, Fonte de medição: instrumentação) —
  `VisualAssociationLinkEvent` grava `wasReuse` em toda criação real de vínculo (nunca em
  idempotente/CRUD isolado do acervo, FR-022-024), e uma consulta/teste demonstra a razão
  reuso/total sobre um período (gate 9 exibe o número existindo, sem UI nova exigida)
- [ ] Migração revisada e **autorizada pelo Diretor antes de `prisma migrate dev`**
  (DEC-023-007) — 100% aditiva: `CREATE TABLE visual_associations`, `ALTER TABLE
  mnemonic_frames ADD COLUMN "visualAssociationId"` + FK `SetNull`, `ALTER TYPE
  "ProductionStageType" ADD VALUE 'ASSOCIACAO_VISUAL'`, `CREATE TABLE
  visual_association_link_events`; nenhuma execução presumida pelo TASK/implement sem essa
  autorização.
- [ ] `route-authz-matrix.integration.test.ts` estendido com as 8 chaves novas (25 → 33
  pares, TRISK-023-006)
- [ ] `visual-associations-frontend-contract.test.ts` (novo) e `tira-frontend-contract.test.ts`
  (estendido) provam paridade cross-repo das interfaces novas/alteradas (COMP-023-011)
- [ ] `domain-types-parity.test.ts` estendido para `ASSOCIACAO_VISUAL` em
  `PRODUCTION_STAGE_TYPES` sem regressão
- [ ] `npm audit`/gate 8 sobre a dependência nova (`multer`) sem vulnerabilidade não mitigada
- [ ] Leitura/escrita de `imageData` confirmada com o adapter real (`@prisma/adapter-pg`) em
  teste de integração com Postgres real (mesmo padrão dos demais módulos)

## 10. Não coberto por este PLAN

Nenhum — cobertura total da SPEC-022 (25/25 FRs, 7/7 NFRs) por este PLAN (Caso D, único PLAN
da SPEC). Os itens explicitamente fora de escopo pertencem à SPEC-022 §4.2 (motor de
publicação/PDF, IA generativa, SVG/vetor, edição de imagem, versionamento, segmentação
categoria/estilo, job de limpeza de órfãs) e não são reabertos aqui.
