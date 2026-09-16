# PLAN-027: Contrastes, pegadinha elaborada, flashcards e protocolo impresso de revisão

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.1
**Autor**: scribe
**Data**: 2026-09-16

## Aderência a guidelines

**Decisões irreversíveis do slug tocadas**: nenhuma (`docs/producao-material/INDEX.md` §Decisões irreversíveis está vazio — as 12 DECs de PLAN-003 são todas reversíveis)
**Decisões irreversíveis de outros slugs em conflito**: nenhuma — infra-vercel: sem bloco de decisões (`docs/infra-vercel/INDEX.md` não existe)
**Exceções aos guidelines**: nenhuma

## Cobertura

**SPEC referenciada**: SPEC-026
**Slice declarado**: cobertura total restante (Caso D — nenhum `--covers`/`--slice`)

**FRs cobertos**:
- FR-026-001, FR-026-002, FR-026-003, FR-026-004, FR-026-005, FR-026-006, FR-026-007
- FR-026-008, FR-026-009, FR-026-010, FR-026-011, FR-026-012, FR-026-013
- FR-026-014, FR-026-015, FR-026-016, FR-026-017, FR-026-018, FR-026-019, FR-026-020
- FR-026-021, FR-026-022
- FR-026-023, FR-026-024, FR-026-025, FR-026-026, FR-026-027, FR-026-028, FR-026-029

**NFRs cobertos**:
- NFR-026-001, NFR-026-002, NFR-026-003, NFR-026-004, NFR-026-005

## 1. Visão técnica

Três registros novos e uma composição pura, todos pendurados no Conteúdo bruto (`RawContent`)
já existente desde F2, sem nenhuma tela/rota nova alcançável pelo STUDENT (NFR-026-001):

- **Contraste** e **Flashcard** (este renomeado `ProductionFlashcard` no schema — DEC-027-003)
  nascem como models Prisma N:1 diretos com `RawContent`, cada um com autoria própria
  (`authorId`), seguindo o único precedente estrutural disponível no slug para "filho N:1
  simples" (`MnemonicFrame`, um nível abaixo de `RawContent` — recon code-scout) e a
  convenção de `onDelete: Restrict` do próprio `RawContent.authorId`/`topicId` (DEC-027-001).
- **Pegadinha elaborada** não ganha tabela própria — é uma coluna nullable
  (`pegadinhaText`) direto em `RawContent`, escrita pela MESMA guarda de autoria de
  `updateRawContent` (DEC-027-002).
- **Protocolo impresso de revisão** continua sem persistência (A-026-006 da SPEC): uma
  função pura, `getReviewProtocolMarks()`, que devolve os 6 Marcos fixos — consumida só na
  composição do PDF.
- A leitura de Contraste/ProductionFlashcard/Pegadinha (fora da Exportação) reusa
  `assertRawContentReachable`/`scopeWhere` — o MESMO escopo de autoria que já restringe a
  leitura do `RawContent` pai para EDITOR (DEC-027-005) — nunca a leitura irrestrita que F5
  usa para `VisualAssociation` (que é uma biblioteca independente, não filha estrutural de
  `RawContent`).
- A Exportação (F6, `publication.service.ts`/`pdf-composer.ts`) ganha uma composição
  suplementar — Contraste(s) + Pegadinha + Flashcard(s) + Protocolo — que entra em AMBAS as
  Variantes (A-026-007), lida sob a MESMA guarda comum de `assertRawContentExportable`
  (DEC-025-007, já decidida em PLAN-025, não redecidida aqui) e desenhada por uma função
  nova em `pdf-composer.ts`, fundida ao PDF principal via `PDFDocument.copyPages`
  (DEC-027-006).
- Instrumentação: 1 valor aditivo no enum `ProductionStageType` (`MATERIAL_REFORCO`,
  DEC-027-004) compartilhado pelos 3 registros autorados — nunca pelo Protocolo, que não é
  autorado — emitido dentro da MESMA `$transaction` da 1ª mutação humana de cada um
  (NFR-026-005, mesmo mecanismo de F3/COMP-010-002, sem redesenho).
- Rotas novas em 2 módulos próprios (`contrasts/`, `flashcards/`), seguindo o padrão de
  `tira/`/`visual-associations/`; Pegadinha estende os arquivos existentes de `contents/`
  (DEC-027-007). Toda rota nova/estendida carrega `requireRole('EDITOR','ADMIN')` +
  `verifyOrigin` nas mutações (NFR-026-001, mesma topologia adversarial de
  `contents.routes.ts`/`tira.routes.ts`).
- Frontend: 5 componentes próprios (form+list de Contraste, form+list de Flashcard, campo
  único de Pegadinha) mais 1 diálogo de confirmação com foco gerenciado compartilhado entre
  os 3 (molde de `mnemonic-strip-board.tsx`) — sem componente genérico de CRUD (DEC-027-008).
  Telas continuam sob `(interno)/content/[id]`, sem rota nova — herdam a barreira de sessão
  de F1 por construção.

## 2. Stack e dependências

Nenhuma dependência nova. Reusa integralmente o stack já autorizado: Node 22 + Express 5 +
Prisma 7 no backend (camadas schema→service→routes do perfil `node-22.md` §4); Next 16 +
React 19 + RTK Query no frontend (Server Component na página, `'use client'` só nos
formulários/listas com estado, perfil `next-16.md` §4); `pdf-lib` (já presente desde
PLAN-025/DEC-025-001) para a composição suplementar do PDF — nenhuma lib de upload/mídia
nova, os 4 conceitos desta fatia são só texto.

## 3. Componentes

### COMP-027-001: `contrasts.schema.ts`
**Responsabilidade**: schemas Zod de Contraste — `createContrastSchema`
(`confusableText`/`distinctionText`, `.trim().min(1)`), `updateContrastSchema`,
`contrastIdParamSchema`.
**Realiza**: NFR-026-002
**Interface pública**: `CreateContrastInput`, `UpdateContrastInput` (tipos derivados dos schemas).
**Dependências**: nenhuma

### COMP-027-002: `contrasts.service.ts`
**Responsabilidade**: ciclo de vida de Contraste — `createContrast`, `listContrasts`
(ordenado por `createdAt asc`), `updateContrast`, `removeContrast` (DELETE físico da linha,
nunca do `RawContent` titular). Guarda composta em toda função: `assertRawContentReachable`
(1ª checagem, escopo de autoria do `RawContent` pai) seguida, em update/remove, de
`actor.role === 'ADMIN' || row.authorId === actor.id` (molde de
`assertVisualAssociationWritable`, F5). Create/update/remove rodam em `$transaction` com
`recordProductionStageEvent(tx, { rawContentId, stageType: 'MATERIAL_REFORCO', actorId, now })`
na 1ª mutação humana do Contraste (a MESMA função decide ABERTURA/CONCLUSAO/RETRABALHO,
DEC-010-005 — nenhum código novo decide isso aqui).
**Realiza**: FR-026-001, FR-026-004, FR-026-005, FR-026-006, FR-026-007, FR-026-024,
FR-026-029, NFR-026-004, NFR-026-005
**Interface pública**: `createContrast(rawContentId, input, actor, db?)`,
`listContrasts(rawContentId, actor, db?)`, `updateContrast(rawContentId, contrastId, input, actor, db?)`,
`removeContrast(rawContentId, contrastId, actor, db?)`.
**Dependências**: COMP-006-003 (`assertRawContentReachable`, `contents.service.ts`), COMP-010-002 (`recordProductionStageEvent`)

### COMP-027-003: `contrasts.routes.ts`
**Responsabilidade**: superfície HTTP — `POST /contents/:id/contrasts`,
`GET /contents/:id/contrasts`, `PATCH /contents/:id/contrasts/:contrastId`,
`DELETE /contents/:id/contrasts/:contrastId`. `verifyOrigin` como 1º handler nas 3 mutações;
`requireRole('<MÉTODO>', '<caminho>', 'EDITOR', 'ADMIN')` nas 4 rotas, na montagem (mesma
topologia de `contents.routes.ts`/`tira.routes.ts`).
**Realiza**: NFR-026-001
**Interface pública**: `contrastsRoutes: Router`.
**Dependências**: COMP-027-001, COMP-027-002

### COMP-027-004: `contrast-form.tsx`
**Responsabilidade**: formulário de criação/edição de Contraste (Confundível + distinção),
3 estados observáveis (`isSubmitting`/`submitSuccess`/`submitError`, molde de
`content-form.tsx`) via `useCreateContrastMutation`/`useUpdateContrastMutation`
(`store/api.ts`, `invalidatesTags: ['Contrast']`).
**Realiza**: FR-026-002, FR-026-003
**Interface pública**: `ContrastForm({ rawContentId, contrast? }: ContrastFormProps)`.
**Dependências**: nenhuma

### COMP-027-005: `contrast-list.tsx`
**Responsabilidade**: lista de Contrastes do Conteúdo bruto, via `useListContrastsQuery`
(refetch a cada visita — `refetchOnMountOrArgChange`, mesma convenção de
`mnemonic-strip-board.tsx`); botão remover por item abre COMP-027-015.
**Realiza**: FR-026-005
**Interface pública**: `ContrastList({ rawContentId }: ContrastListProps)`.
**Dependências**: COMP-027-015

### COMP-027-006: extensão de `contents.schema.ts` (Pegadinha)
**Responsabilidade**: `updatePegadinhaSchema` (`text: z.string().trim().min(1)`, campo
obrigatório — DELETE não usa body).
**Realiza**: NFR-026-002
**Interface pública**: `UpdatePegadinhaInput`.
**Dependências**: nenhuma

### COMP-027-007: extensão de `contents.service.ts` (Pegadinha)
**Responsabilidade**: `savePegadinhaText`/`removePegadinhaText` — `updateMany` com
`{ id, ...ACTIVE_RAW_CONTENT_WHERE, ...scopeWhere(actor) }` no `where` (MESMA guarda e MESMO
statement atômico de `updateRawContent`, nunca um `findFirst` de guarda seguido de `update`
por id isolado), dentro de `$transaction` com `recordProductionStageEvent` (`stageType:
'MATERIAL_REFORCO'`) na 1ª mutação humana. `RAW_CONTENT_DETAIL_SELECT`/`RawContentDetail`
ganham o campo `pegadinhaText`.
**Realiza**: FR-026-008, FR-026-011, FR-026-012, FR-026-013, FR-026-024, FR-026-029,
NFR-026-004, NFR-026-005
**Interface pública**: `savePegadinhaText(rawContentId, input, actor, db?)`,
`removePegadinhaText(rawContentId, actor, db?)`.
**Dependências**: COMP-006-003, COMP-010-002

### COMP-027-008: extensão de `contents.routes.ts` (Pegadinha)
**Responsabilidade**: `PATCH /contents/:id/pegadinha` (salvar/editar),
`DELETE /contents/:id/pegadinha` (apagar) — `verifyOrigin` 1º handler,
`requireRole('EDITOR','ADMIN')` nas 2. Leitura já vem embutida em `GET /contents/:id`
(sem rota própria).
**Realiza**: NFR-026-001
**Interface pública**: 2 handlers adicionados a `contentsRoutes`.
**Dependências**: COMP-027-006, COMP-027-007

### COMP-027-009: `pegadinha-field.tsx`
**Responsabilidade**: campo único de texto (sem lista) na tela do Conteúdo bruto, 3 estados
observáveis (salvar) via `useSavePegadinhaMutation`; ação "apagar" abre COMP-027-015 antes de
`useRemovePegadinhaMutation`.
**Realiza**: FR-026-009, FR-026-010
**Interface pública**: `PegadinhaField({ rawContentId, pegadinhaText }: PegadinhaFieldProps)`.
**Dependências**: COMP-027-015

### COMP-027-010: `flashcards.schema.ts`
**Responsabilidade**: schemas Zod de `ProductionFlashcard` — `createFlashcardSchema`
(`question`/`answer`, `.trim().min(1)`), `updateFlashcardSchema`, `flashcardIdParamSchema`.
**Realiza**: NFR-026-002
**Interface pública**: `CreateFlashcardInput`, `UpdateFlashcardInput`.
**Dependências**: nenhuma

### COMP-027-011: `flashcards.service.ts`
**Responsabilidade**: ciclo de vida de `ProductionFlashcard` — `createFlashcard`,
`listFlashcards` (ordenado por `createdAt asc` — FR-026-017/020), `updateFlashcard`,
`removeFlashcard`. Mesma guarda composta de COMP-027-002
(`assertRawContentReachable` + autor-ou-ADMIN do registro); mesma transação +
`recordProductionStageEvent` (`stageType: 'MATERIAL_REFORCO'`) na 1ª mutação humana.
**Realiza**: FR-026-014, FR-026-017, FR-026-018, FR-026-019, FR-026-024, FR-026-029,
NFR-026-004, NFR-026-005
**Interface pública**: `createFlashcard(rawContentId, input, actor, db?)`,
`listFlashcards(rawContentId, actor, db?)`, `updateFlashcard(rawContentId, flashcardId, input, actor, db?)`,
`removeFlashcard(rawContentId, flashcardId, actor, db?)`.
**Dependências**: COMP-006-003, COMP-010-002

### COMP-027-012: `flashcards.routes.ts`
**Responsabilidade**: superfície HTTP — `POST/GET /contents/:id/flashcards`,
`PATCH/DELETE /contents/:id/flashcards/:flashcardId`. Mesma topologia de COMP-027-003.
**Realiza**: NFR-026-001
**Interface pública**: `flashcardsRoutes: Router`.
**Dependências**: COMP-027-010, COMP-027-011

### COMP-027-013: `flashcard-form.tsx`
**Responsabilidade**: formulário de criação/edição de Flashcard (pergunta/resposta), 3
estados observáveis via `useCreateFlashcardMutation`/`useUpdateFlashcardMutation`
(`invalidatesTags: ['ProductionFlashcard']`).
**Realiza**: FR-026-015, FR-026-016
**Interface pública**: `FlashcardForm({ rawContentId, flashcard? }: FlashcardFormProps)`.
**Dependências**: nenhuma

### COMP-027-014: `flashcard-list.tsx`
**Responsabilidade**: lista de Flashcards do Conteúdo bruto, ordem de criação, via
`useListFlashcardsQuery` (refetch a cada visita); botão remover abre COMP-027-015.
**Realiza**: FR-026-017
**Interface pública**: `FlashcardList({ rawContentId }: FlashcardListProps)`.
**Dependências**: COMP-027-015

### COMP-027-015: `confirm-remove-dialog.tsx`
**Responsabilidade**: diálogo de confirmação com foco gerenciado (`role="alertdialog"`,
molde de `mnemonic-strip-board.tsx` — ref do botão de confirmação focado ao abrir, foco
devolvido ao gatilho ao fechar), compartilhado por Contraste/Pegadinha/Flashcard — 3 estados
observáveis do próprio ato de remover (em andamento/sucesso/falha) e reabilitação da ação em
caso de falha, sem remover o item da lista até o sucesso.
**Realiza**: FR-026-024, FR-026-025
**Interface pública**: `ConfirmRemoveDialog({ open, itemLabel, onConfirm, onClose }: ConfirmRemoveDialogProps)`.
**Dependências**: nenhuma

### COMP-027-016: `review-protocol.ts`
**Responsabilidade**: função pura no módulo `publication` — `getReviewProtocolMarks()`
devolve os 6 Marcos fixos (`R0`, `R24`, `R3`, `R7`, `R14`, `R30`) com rótulo textual completo
e espaço para data manual, na ordem canônica. Sem I/O, sem parâmetro de tempo (não há
cálculo — A-026-006/FR-026-022).
**Realiza**: FR-026-021, FR-026-022
**Interface pública**: `getReviewProtocolMarks(): ReviewProtocolMark[]`;
`interface ReviewProtocolMark { code: 'R0'|'R24'|'R3'|'R7'|'R14'|'R30'; label: string }`.
**Dependências**: nenhuma

### COMP-027-017: extensão de `pdf-composer.ts`
**Responsabilidade**: `buildSupplementaryPagesPdf(sections, meta)` — desenha, num
`PDFDocument` próprio, 1 seção por Contraste (Confundível + distinção), a Pegadinha
(quando presente), 1 seção por Flashcard (pergunta/resposta) e o Protocolo impresso
(sempre) — reusa `createPage`/`drawDraftHeader`/`measureWidthFor`/`wrapTextToLines` já
existentes no arquivo. Cada seção com 0 itens (Contraste/Pegadinha/Flashcard ausente) é
OMITIDA, nunca gera página vazia nem erro (FR-026-028/023).
**Realiza**: FR-026-021, FR-026-022, FR-026-026, FR-026-027, FR-026-020, FR-026-028,
FR-026-023
**Interface pública**: `buildSupplementaryPagesPdf(sections: SupplementarySections, meta: PublicationPdfMeta): Promise<Buffer>`;
`interface SupplementarySections { contrasts: ContrastForPdf[]; pegadinhaText: string | null; flashcards: FlashcardForPdf[]; protocol: ReviewProtocolMark[] }`.
**Dependências**: COMP-027-016; estende COMP-025-003 (`pdf-composer.ts`, PLAN-025)

### COMP-027-018: extensão de `publication.service.ts`
**Responsabilidade**: `composePublicationBuffer` passa a ler, via `Promise.all`
(NFR-026-003 — sem I/O de rede adicional, só 2 `findMany` locais a mais em paralelo com o
que já é lido): Contrastes e `ProductionFlashcard`s do `rawContentId` (sem `scopeWhere` —
mesma guarda comum de `assertRawContentExportable` já resolvida no passo 1 de
`exportPublication`, DEC-025-007, não redecidida aqui) e reusa `pegadinhaText` já presente
no `RawContent` lido; monta o `SupplementarySections`, chama
`getReviewProtocolMarks()`/`buildSupplementaryPagesPdf` (COMP-027-016/017) e funde o
resultado ao PDF principal (`buildStripPdf`/`buildSummaryPdf`) via `PDFDocument.copyPages`
antes do `.save()` final, para AMBAS as Variantes (A-026-007). `PublicationClient` ganha
`Pick<'contrast' | 'productionFlashcard'>`.
**Realiza**: FR-026-026, FR-026-027, FR-026-020, FR-026-028, FR-026-023, NFR-026-003
**Interface pública**: assinatura de `composePublicationBuffer`/`exportPublication`
intocada (extensão interna).
**Dependências**: COMP-027-017; estende COMP-025-005 (`publication.service.ts`, PLAN-025)

## 4. Fluxos principais

**Fluxo 1 — Registro de Contraste** (AC-026-001/002/003/004): EDITOR abre
`(interno)/content/[id]`, preenche Confundível + distinção em `ContrastForm`
(COMP-027-004) → `POST /contents/:id/contrasts` (COMP-027-003) → `createContrast`
(COMP-027-002): `assertRawContentReachable` recusa se o `RawContent` titular estiver
inalcançável/removido (404, AC-026-003) → dentro de `$transaction`: `contrast.create` +
`recordProductionStageEvent` (`MATERIAL_REFORCO`, ABERTURA) → sucesso invalida a tag
`'Contrast'` → `ContrastList` (COMP-027-005) refaz o fetch e mostra o novo item. Falha
(Zod 400 ou erro do sistema): `ContrastForm` reabilita o botão, preserva os campos, mostra
mensagem (AC-026-002).

**Fluxo 2 — Remoção com confirmação** (AC-026-004/018/019, mesmo padrão para Pegadinha e
Flashcard): botão remover abre `ConfirmRemoveDialog` (COMP-027-015, foco no botão
"Confirmar") → confirmado, indica operação em andamento → `DELETE
/contents/:id/contrasts/:contrastId` → `removeContrast`: guarda composta
(`assertRawContentReachable` + autor-ou-ADMIN do Contraste) + `delete` atômico → sucesso:
item some da lista, foco devolvido ao gatilho seguinte; falha: item permanece, ação
reabilitada, mensagem de erro (nenhum estado meio-removido).

**Fluxo 3 — Pegadinha elaborada** (AC-026-005/006/007): `PegadinhaField` (COMP-027-009) →
`PATCH /contents/:id/pegadinha` → `savePegadinhaText` (COMP-027-007): `updateMany` com
`scopeWhere(actor)` — `RawContent` titular soft-deleted ou fora do alcance → `count === 0`
→ 404 (mesma mensagem de `updateRawContent`, nunca distingue "não existe" de "não é seu");
sucesso → `recordProductionStageEvent` na mesma tx, campo exibido ao recarregar
`GET /contents/:id`.

**Fluxo 4 — Flashcard** (AC-026-008 a 011): mesma estrutura do Fluxo 1, via
`FlashcardForm`/`FlashcardList` (COMP-027-013/014) e `flashcards.service.ts`
(COMP-027-011) — lista sempre ordenada por `createdAt asc`.

**Fluxo 5 — Exportação com os 4 conceitos** (AC-026-012/013/014/017/020/021/022): EDITOR
aciona Exportação → `exportPublication` (COMP-025-005) → `assertRawContentExportable`
(guarda comum, sem autoria, DEC-025-007) → `composePublicationBuffer` (COMP-027-018
estendido): lê Contrastes + `ProductionFlashcard`s (`Promise.all`) + `pegadinhaText` (já no
`RawContent` lido) + `getReviewProtocolMarks()` (COMP-027-016) → monta o PDF principal
(`buildStripPdf`/`buildSummaryPdf`, intocados) e as páginas suplementares
(`buildSupplementaryPagesPdf`, COMP-027-017) só com as seções não vazias (sem Contraste →
omite, AC-026-022; sem Flashcard → omite, AC-026-017) → `copyPages` funde os 2
`PDFDocument`s → 1 `.save()` final. Protocolo sempre presente (não depende de registro
autorado, FR-026-021).

**Fluxo 6 — Instrumentação e fail-secure** (AC-026-023): 1ª mutação humana de
Contraste/Pegadinha/Flashcard chama `recordProductionStageEvent` na MESMA `$transaction` da
escrita de negócio — falha no evento (ex.: violação de constraint) propaga a exceção,
Prisma reverte a transação inteira (nenhum estado meio-salvo), a rota devolve erro
genérico ao EDITOR (NFR-026-005).

## 5. Modelo de dados

**Diff de `schema.prisma`** (aditivo — DEC-027-001/002/003/004):

```prisma
enum ProductionStageType {
  CONTEUDO_BRUTO
  QUEBRA_DA_REGRA
  TIRA_MNEMONICA
  ASSOCIACAO_VISUAL
  PUBLICACAO_PDF
  // NOVO (F7) — aditivo, sem redesenho do mecanismo (NFR-009-001/DEC-010-001).
  // Compartilhado pelos 3 registros autorados desta fatia (Contraste, Pegadinha
  // elaborada, Flashcard) — DEC-027-004: granularidade por REGISTRO, não por TIPO.
  MATERIAL_REFORCO
}

model RawContent {
  // ...campos existentes intocados...

  /// NOVO (F7): texto explicando por que este ponto é um erro comum de prova —
  /// acrescenta à Classe do radar de prova já persistida, não a redefine
  /// (A-026-005/DEC-027-002). null = sem Pegadinha elaborada registrada. Autoria
  /// segue `authorId` do próprio RawContent (não há autor próprio da Pegadinha).
  pegadinhaText String?

  contrasts            Contrast[]
  productionFlashcards ProductionFlashcard[]
}

/// Comparação entre o Conteúdo bruto titular e um instituto/regra confundível em
/// texto livre (DEC-027-001). Restrict nos dois FKs: a remoção do titular é
/// soft-delete (nunca DELETE físico), e apagar um autor com Contraste produzido
/// fica bloqueado até F8 definir expurgo — mesma razão de RawContent.authorId.
model Contrast {
  id String @id @default(uuid(7))

  rawContentId String
  rawContent   RawContent @relation(fields: [rawContentId], references: [id], onDelete: Restrict)

  authorId String
  author   User   @relation("ContrastAuthor", fields: [authorId], references: [id], onDelete: Restrict)

  confusableText   String
  distinctionText  String

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([rawContentId, createdAt(sort: Asc)])
  @@map("contrasts")
}

/// Par pergunta/resposta autorado pelo EDITOR (DEC-027-001), incluído na
/// Exportação. Nomeado `ProductionFlashcard` — já existe `model Flashcard`
/// (legado, ligado a Topic/Mnemonic/CardState/Review, dormente desde F2) e os
/// dois nomes colidiriam (DEC-027-003). Mesma razão de Restrict de `Contrast`.
model ProductionFlashcard {
  id String @id @default(uuid(7))

  rawContentId String
  rawContent   RawContent @relation(fields: [rawContentId], references: [id], onDelete: Restrict)

  authorId String
  author   User   @relation("ProductionFlashcardAuthor", fields: [authorId], references: [id], onDelete: Restrict)

  question String
  answer   String

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([rawContentId, createdAt(sort: Asc)])
  @@map("production_flashcards")
}

model User {
  // ...campos existentes intocados...

  contrasts            Contrast[]            @relation("ContrastAuthor")
  productionFlashcards ProductionFlashcard[] @relation("ProductionFlashcardAuthor")
}
```

**Migração aditiva** (padrão exato de
`prisma/migrations/20260913174134_add_visual_association/migration.sql`, F5 — 1 pasta nova
de migração, gerada e revisada pelo `developer` na implementação; **não aplicada por este
PLAN**):

```sql
-- AlterEnum
ALTER TYPE "ProductionStageType" ADD VALUE 'MATERIAL_REFORCO';

-- AlterTable
ALTER TABLE "raw_contents" ADD COLUMN     "pegadinhaText" TEXT;

-- CreateTable
CREATE TABLE "contrasts" (
    "id" TEXT NOT NULL,
    "rawContentId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "confusableText" TEXT NOT NULL,
    "distinctionText" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "contrasts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "production_flashcards" (
    "id" TEXT NOT NULL,
    "rawContentId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "question" TEXT NOT NULL,
    "answer" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "production_flashcards_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "contrasts_rawContentId_createdAt_idx" ON "contrasts"("rawContentId", "createdAt");

-- CreateIndex
CREATE INDEX "production_flashcards_rawContentId_createdAt_idx" ON "production_flashcards"("rawContentId", "createdAt");

-- AddForeignKey
ALTER TABLE "contrasts" ADD CONSTRAINT "contrasts_rawContentId_fkey" FOREIGN KEY ("rawContentId") REFERENCES "raw_contents"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contrasts" ADD CONSTRAINT "contrasts_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "production_flashcards" ADD CONSTRAINT "production_flashcards_rawContentId_fkey" FOREIGN KEY ("rawContentId") REFERENCES "raw_contents"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "production_flashcards" ADD CONSTRAINT "production_flashcards_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
```

**Tipos TS espelhados** (backend `src/domain/types.ts` → frontend `src/types/domain.ts`,
mesma régua de `RawContent`/`RuleBreakdown`):

```ts
// backend: PRODUCTION_STAGE_TYPES ganha 'MATERIAL_REFORCO' no array existente (sem espelho
// no frontend, mesma exceção de DEC-010-006 — sem consumidor de tela/rota nesta fatia).

export interface Contrast {
  id: string;
  rawContentId: string;
  authorId: string;
  confusableText: string;
  distinctionText: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface ProductionFlashcard {
  id: string;
  rawContentId: string;
  authorId: string;
  question: string;
  answer: string;
  createdAt: Date;
  updatedAt: Date;
}

// RawContent (backend e frontend) ganha: pegadinhaText: string | null;
```

`TAG_TYPES` (`mnemonicos-frontend/src/store/api.ts:138-147`) ganha `'Contrast'` e
`'ProductionFlashcard'`; mutações de Pegadinha usam `invalidatesTags: ['RawContent']`
(tag já existente, o campo é dela).

## 6. Decisões arquiteturais

### DEC-027-001: Modelo de dados de Contraste e Flashcard — N:1 direto com RawContent
**Contexto**: SPEC-026 introduz 3 registros ligados a um Conteúdo bruto: Contraste (2
campos de texto), Pegadinha elaborada (1 campo — tratada em DEC-027-002) e Flashcard (2
campos de texto com semântica diferente: pergunta/resposta). Não há precedente pronto de
N:1 direto com `RawContent` no schema — o mais próximo é `MnemonicFrame`, N:1 com
`MnemonicStrip`, um nível abaixo (recon code-scout).
**Decisão**: Contraste e Flashcard (renomeado `ProductionFlashcard`, DEC-027-003) nascem
como models Prisma próprios, cada um com FK simples `rawContentId`
(`onDelete: Restrict`, nunca Cascade — a remoção do Conteúdo bruto é soft-delete via
`deletedAt`, nunca `DELETE` físico) e `authorId` (`onDelete: Restrict`, mesma razão de
`RawContent.authorId`).
**Alternativas consideradas**:
- Tabela única polimórfica para os 3 registros, descartada porque mistura formas de dado
  muito diferentes (Contraste: `confusableText`+`distinctionText`; Flashcard:
  `question`+`answer`; Pegadinha: 1 campo) atrás de um schema genérico — perderia tipagem
  em cada leitura (toda consulta precisaria discriminar por um campo `kind` e tratar
  colunas irrelevantes como `NULL`), e a Pegadinha nem chega a entrar nela (DEC-027-002).
**Consequências**: 2 `CREATE TABLE` + FKs; services/rotas próprios por tipo (DEC-027-007);
leitura de exportação faz 2 `findMany` (Contraste, `ProductionFlashcard`) em vez de 1
`findMany` polimórfico filtrado por `kind`.
**Reabrir se**: nunca — o custo de tipagem perdida da tabela polimórfica não se paga em
nenhum volume razoável desta fatia.
**Irreversível**: não
**Aderência à ficha/perfil**: herdada

### DEC-027-002: Modelo de Pegadinha elaborada — coluna nullable em RawContent
**Contexto**: a Pegadinha elaborada é 1 único campo de texto por Conteúdo bruto
(RISK-026-004 já a trata como "o mesmo campo", não "o mesmo registro").
**Decisão**: coluna `pegadinhaText String?` direto em `RawContent`, sem tabela própria.
Escrita via `updateMany` com o MESMO `scopeWhere(actor)+ACTIVE_RAW_CONTENT_WHERE` de
`updateRawContent` — como consequência, "o autor do registro" de FR-026-012 é, na prática,
`RawContent.authorId` (não há autoria própria da Pegadinha); rota separada
(`PATCH/DELETE /contents/:id/pegadinha`) para não sobrecarregar `updateRawContentSchema`
com um campo de ciclo de vida diferente.
**Alternativas consideradas**:
- Tabela 1:1 própria (molde de `RuleBreakdown`), descartada nesta fatia por
  over-engineering para 1 campo de texto sem outros atributos — pagaria uma tabela, uma FK
  única, um service e uma rota inteiros por um único `String?`.
**Consequências**: `RAW_CONTENT_DETAIL_SELECT`/`RawContentDetail` (`contents.service.ts`)
ganham o campo; qualquer leitura de detalhe do Conteúdo bruto já devolve `pegadinhaText`
sem round-trip adicional.
**Reabrir se**: a Pegadinha elaborada ganhar campos adicionais no futuro (ex.: categoria do
erro, referência a jurisprudência) — aí a tabela própria se paga.
**Irreversível**: não
**Aderência à ficha/perfil**: herdada

### DEC-027-003: Novo model de Flashcard nomeado `ProductionFlashcard`, não `Flashcard`
**Contexto**: o schema já tem `model Flashcard` (`schema.prisma:222-243`) — cartão de
repetição espaçada ligado a `Topic`/`Mnemonic`, consumido por `CardState`/`Review` do
STUDENT, dormente desde F2 (RISK-011-001/A-005-013, sem consumidor na fábrica). É um
conceito estruturalmente e funcionalmente diferente do Flashcard de SPEC-026 (pergunta/
resposta autorado pelo EDITOR, ligado a `RawContent`, consumido só pela Exportação/F6,
nunca pelo STUDENT) que, por coincidência de vocabulário, usa o mesmo substantivo do
produto.
**Decisão**: o model novo chama-se `ProductionFlashcard` — mantém "Flashcard" na
Ubiquitous Language/UI (pt-BR) e nas rotas (`/contents/:id/flashcards`, string, sem colisão
de identificador), mas o identificador de código Prisma/TS é distinto do model legado.
**Alternativas consideradas**:
- Renomear o model legado `Flashcard` (ex.: `LegacyFlashcard`) para liberar o nome ao
  conceito novo, descartada: sai do escopo desta fatia — seria migração de rename tocando 3
  tabelas relacionadas (`Flashcard`, `CardState`, `Review` via FK) sem nenhum FR desta SPEC
  pedindo isso, e sem mapeamento de consumidor residual confirmado a essa distância.
**Consequências**: 2 conceitos chamados "Flashcard" na UI/vocabulário, distinguíveis só
pelo model por trás — módulo novo (`flashcards/`) próprio, o legado nunca teve
`.service.ts` dedicado hoje.
**Reabrir se**: o `Flashcard` legado for formalmente desativado/removido do schema
(RISK-011-001 fechado) — aí reavaliar unificação de nome.
**Irreversível**: não
**Aderência à ficha/perfil**: nova (nomenclatura de desambiguação sem precedente antes
deste achado)

### DEC-027-004: Novo valor do enum ProductionStageType — MATERIAL_REFORCO
**Contexto**: FR-026-029 exige 1 evento de etapa por 1ª mutação humana de QUALQUER um dos 3
registros (Contraste, Pegadinha, Flashcard) — não por tipo.
**Decisão**: 1 valor aditivo único, `MATERIAL_REFORCO`, usado pelos 3 services
(`contrasts.service.ts`, `contents.service.ts::savePegadinhaText`, `flashcards.service.ts`)
ao chamar `recordProductionStageEvent`.
**Alternativas consideradas**:
- 3 valores separados (`CONTRASTE`, `PEGADINHA_ELABORADA`, `FLASHCARD_REFORCO`),
  descartada: FR-026-029 pede granularidade por MUTAÇÃO (qualquer um dos 3), não por TIPO,
  e nenhum consumidor desta fatia precisa discriminar qual dos 3 disparou — 3 `ALTER TYPE`
  + 3 pontos de decisão sem nenhum leitor declarado é custo sem retorno.
- Literal `CONTRASTE_PEGADINHA_FLASHCARD`, descartada: nome longo que ata os 3 conceitos no
  próprio literal — um 4º conceito de reforço futuro obrigaria outro valor OU renomear
  este, quebrando o precedente dos demais valores do enum (cada um nomeia uma
  ETAPA/camada, não uma enumeração de registros).
**Consequências**: 1 `ALTER TYPE ... ADD VALUE 'MATERIAL_REFORCO'` (migração aditiva); os 3
services compartilham o mesmo `stageType` — a distinção de QUAL dos 3 mutou fica só no
`rawContentId` + no dado em si, nunca no evento.
**Reabrir se**: nunca — recriar o enum (Postgres não suporta `DROP VALUE`) para desmembrar
em 3 exigiria migrar todo o histórico de eventos já emitidos com este valor; sem consumidor
que peça a granularidade, o custo não se paga.
**Irreversível**: não
**Aderência à ficha/perfil**: herdada (padrão de migração aditiva de enum,
NFR-009-001/DEC-010-001; mesmo tratamento de reversibilidade dado a `ASSOCIACAO_VISUAL`/
`PUBLICACAO_PDF` em PLAN-023/PLAN-025)

### DEC-027-005: Guarda de leitura de Contraste/ProductionFlashcard/Pegadinha reusa `assertRawContentReachable`
**Contexto**: A-026-009 diz que a leitura é "comum a EDITOR/ADMIN (qualquer um vê,
independente de quem criou)". O padrão de leitura irrestrita mais recente do slug é
`VisualAssociation` (biblioteca reutilizável, independente de autoria de `RawContent`) —
mas Contraste/Flashcard/Pegadinha são estruturalmente filhos de `RawContent`, cujo PRÓPRIO
acesso de leitura já é restrito por autoria para EDITOR (`getRawContent` usa
`scopeWhere(actor)` no `where`, confirmado por leitura direta de
`contents.service.ts:151-164` — não só na listagem).
**Decisão**: `GET /contents/:id/contrasts`, `GET /contents/:id/flashcards` e a leitura de
`pegadinhaText` (embutida em `GET /contents/:id`) reusam `assertRawContentReachable`/
`scopeWhere` — o MESMO escopo por autoria de `RawContent`. A-026-009 "leitura comum,
independente de quem criou" se resolve DENTRO desse escopo: um EDITOR que alcança seu
próprio `RawContent` vê TODOS os Contrastes/Flashcards nele (mesmo os que um ADMIN tenha
criado/editado), sem checagem adicional por `authorId` do registro filho na LEITURA — só na
ESCRITA (FR-026-006/012/018).
**Alternativas consideradas**:
- Leitura irrestrita (calcada em `VisualAssociation`), descartada: abriria enumeração de
  Contraste/Flashcard de um `RawContent` de OUTRO EDITOR sem passar pela guarda do pai —
  uma rota que só checasse "existe contraste com este rawContentId" vazaria a existência/
  conteúdo de Conteúdo bruto de outro autor por uma porta lateral, quebrando o alcance por
  autoria já estabelecido (F2) por um caminho que `route-authz-matrix` não necessariamente
  cobre por padrão de rota.
**Consequências**: `contrasts.service.ts`/`flashcards.service.ts` chamam
`assertRawContentReachable` (importado de `contents.service.ts`) como 1ª guarda em toda
função — mesmo padrão de `tira.service.ts` (F4).
**Reabrir se**: o alcance por autoria de `RawContent` for relaxado globalmente para EDITOR
(mudança fora do escopo desta fatia).
**Irreversível**: não
**Aderência à ficha/perfil**: herdada

### DEC-027-006: Composição no PDF por funções novas, com merge via `copyPages`
**Contexto**: `composePublicationBuffer` hoje delega a `buildStripPdf` OU
`buildSummaryPdf`, cada um criando e salvando seu próprio `PDFDocument`
(`pdf-composer.ts:181-280`). Os 4 conceitos novos entram em AMBAS as Variantes
(A-026-007), então não pertencem exclusivamente a nenhuma das duas funções existentes.
**Decisão**: função nova `buildSupplementaryPagesPdf` (paralela a `buildStripPdf`/
`buildSummaryPdf`) desenha Contraste(s)/Pegadinha/Flashcard(s)/Protocolo num `PDFDocument`
PRÓPRIO; `composePublicationBuffer` funde esse documento com o principal via
`PDFDocument.copyPages` antes do `.save()` final, só quando há pelo menos 1 seção não
vazia (Protocolo sempre conta como não vazio).
**Alternativas consideradas**:
- Seções embutidas dentro de `buildStripPdf`/`buildSummaryPdf`, descartada: acopla o
  layout dos 2 formatos de exportação a uma lógica IDÊNTICA nos dois (o conteúdo
  suplementar não muda por Variante) — mudar o texto/rótulo de uma seção suplementar
  exigiria tocar as 2 funções, cada uma crescendo além da sua responsabilidade única atual.
**Consequências**: duplica um pouco o setup de página (fonte, margens, cabeçalho de
rascunho) — mitigado reusando `createPage`/`drawDraftHeader`/`measureWidthFor`/
`wrapTextToLines` já existentes no arquivo; custo real é 1 `PDFDocument` + 1 `copyPages` a
mais por Exportação (medir contra NFR-026-003, TRISK-027-005).
**Reabrir se**: o conteúdo suplementar precisar DIVERGIR por Variante (ex.: Protocolo só na
Tira) — aí a duplicação por Variante embutida passaria a fazer mais sentido que o merge.
**Irreversível**: não
**Aderência à ficha/perfil**: herdada

### DEC-027-007: Módulos de rota próprios (`contrasts`, `flashcards`); Pegadinha estende `contents.*`
**Contexto**: Contraste e Flashcard são entidades filhas de primeira classe (CRUD completo,
autoria própria); Pegadinha é um campo do próprio `RawContent` (DEC-027-002).
**Decisão**: `contrasts.schema.ts`/`.service.ts`/`.routes.ts` e `flashcards.schema.ts`/
`.service.ts`/`.routes.ts` nascem como módulos Prisma/Express próprios (padrão de `tira/`,
`visual-associations/`); Pegadinha estende os arquivos `contents.*` existentes (1 schema, 1
função, 1 rota a mais cada).
**Alternativas consideradas**:
- Crescer `contents.routes.ts`/`.service.ts` com as 8 rotas/funções de Contraste+Flashcard
  também, descartada: o arquivo já concentra o ciclo de vida do PRÓPRIO `RawContent` (7
  rotas hoje) — somar 2 entidades filhas de CRUD completo inflaria um único arquivo além da
  responsabilidade única que `tira`/`visual-associations` já resolveram com módulo próprio;
  a convenção do perfil (`node-22.md` §4) é "módulo por domínio".
**Consequências**: 6 arquivos novos (2 módulos × 3 arquivos); 2 arquivos existentes ganham
1 schema+1 função+1 rota cada (Pegadinha).
**Reabrir se**: nunca — o critério (entidade com autoria própria vs. campo do pai) é
estável.
**Irreversível**: não
**Aderência à ficha/perfil**: herdada (`node-22.md` §4, tabela de camadas)

### DEC-027-008: Frontend — componentes próprios por tipo; só o diálogo de confirmação é compartilhado
**Contexto**: Contraste (`confusableText`/`distinctionText`) e Flashcard (`question`/
`answer`) têm a MESMA forma estrutural (par de textos, lista, CRUD completo, mesma
barreira de autoria); Pegadinha é campo único sem lista. O histórico do slug (MAP/
lessons.md) já registra reincidência de "padrão copiado sem contrato completo" como
regressão, não reúso.
**Decisão**: `contrast-form.tsx`/`contrast-list.tsx`, `flashcard-form.tsx`/
`flashcard-list.tsx` e `pegadinha-field.tsx` nascem como componentes PRÓPRIOS (sem
componente genérico de "lista com CRUD"); só o diálogo de confirmação com foco gerenciado
(`confirm-remove-dialog.tsx`, molde de `mnemonic-strip-board.tsx`) é extraído como
componente compartilhado entre os 3.
**Alternativas consideradas**:
- Componente genérico `SimpleCrudList<T>` parametrizado por campos, para Contraste+
  Flashcard (mesma forma), descartada: apesar da forma igual, mensagens de erro pt-BR,
  rótulos de campo e ACs são específicos por tipo (FR-026-002 vs FR-026-015 têm textos de
  UI diferentes) — abstrair cedo esconderia essa especificidade atrás de props genéricas,
  pagando complexidade de configuração maior que as ~40 linhas duplicadas que o componente
  próprio custa; o histórico do slug já mostra que reúso por cópia sem contrato completo
  virou regressão mais de uma vez.
**Consequências**: 4 componentes de formulário/lista com alguma duplicação estrutural
(states `isSubmitting`/`success`/`error`, molde de `content-form.tsx`); 1 componente de
diálogo compartilhado reduz a duplicação no ponto onde bugs de acessibilidade já ocorreram
no slug (foco programático, F4).
**Reabrir se**: um 3º ou 4º tipo de "material de reforço" com a MESMA forma exata (par de 2
textos) for adicionado em fatia futura — aí reavaliar extração, com 3+ instâncias reais em
mãos.
**Irreversível**: não
**Aderência à ficha/perfil**: herdada (`next-16.md` §4: children/composição antes de HOC/
abstração prematura)

## 8. Riscos técnicos

- **TRISK-027-001** `ALTER TYPE ... ADD VALUE` do Postgres não pode ser usado na MESMA
  transação em que o novo valor é lido/escrito — mesma restrição já mitigada em
  `ASSOCIACAO_VISUAL`/`PUBLICACAO_PDF` sem regressão (mitigação: o valor só é referenciado
  pelo código depois que a migração já foi aplicada num deploy anterior à implementação).
- **TRISK-027-002** Volume de Contraste/Flashcard sem teto nesta fatia (FR-026-014 sem
  limite superior) amplifica RISK-025-007 (herdado, já nomeado em RISK-026-005 da SPEC:
  Tira grande com imagens pode exceder o limite de corpo de resposta serverless da Vercel)
  — mitigação: decisão de introduzir teto fica com quem fechar RISK-025-007, fora deste
  PLAN.
- **TRISK-027-003** `pegadinhaText` embutido em `RawContent` significa que qualquer SELECT
  genérico da tabela que não use o `select` explícito (`RAW_CONTENT_DETAIL_SELECT`) passa a
  carregar 1 coluna a mais — mitigação: a prática do módulo já é `select` explícito em toda
  leitura (`contents.service.ts`); adicionar o campo ali é o único lugar a mudar.
- **TRISK-027-004** A guarda de leitura de Contraste/Flashcard/Pegadinha (autoria herdada,
  DEC-027-005) diverge da guarda de `VisualAssociation` (leitura irrestrita, F5) dentro do
  MESMO slug — risco de confusão em extensão futura que copie o padrão errado — mitigação:
  DEC-027-005 documenta explicitamente a distinção e o motivo.
- **TRISK-027-005** Merge de 2 `PDFDocument`s (principal + suplementar) via `copyPages`
  introduz custo de composição adicional — pode tensionar NFR-026-003 (teto de duração já
  existente da Exportação) em Tiras grandes — mitigação: medir com teste de performance na
  implementação, mesma régua de DEC-025-002 (teto de duração interno com folga).

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Aderência à ficha/perfil validada
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates)
- [ ] Métrica da SPEC operacional (§1.3, `Fonte de medição: instrumentação`): consulta de
      contagem de `ProductionFlashcard` por `RawContent` ativo (com `RuleBreakdown` salva)
      executável contra o schema novo — sem evento dedicado (a própria persistência de
      `ProductionFlashcard`, COMP-027-011, já torna a métrica medível por leitura direta,
      cruzada com o total de `RawContent` ativos com `RuleBreakdown`, base já existente
      desde F2/F4)

## 10. Não coberto por este PLAN

Nenhum — cobertura total de SPEC-026 (Caso D): todos os FR-026-001 a FR-026-029 e
NFR-026-001 a NFR-026-005 têm `**Realiza**` em pelo menos 1 COMP acima. O que fica de fora
é escopo da própria SPEC (§4.2 Out-of-scope: Contraste titular-titular, interação do
STUDENT, cálculo/disparo automático de revisão, geração por IA, reordenação de Flashcards,
gate de QC jurídico, trilha histórica) — nenhum requisito pendente para PLAN futuro dentro
desta fatia.
