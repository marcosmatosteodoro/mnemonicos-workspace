# TASK-029-001: Setup — schema Prisma, migração aditiva e smoke test do modelo `ContentVersion`

**Slug**: producao-material
**Pertence a**: PLAN-029
**Realiza (FRs)**: nenhuma
**Componente**: COMP-029-001
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Todo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-029-002, TASK-029-003

## Contexto

Habilita, no schema Prisma, o model append-only novo `ContentVersion` (pendurado em
`RawContent`, N:1, mesmo formato de `Contrast`/`ProductionFlashcard` de F7) e o valor
aditivo `VERSAO_EDITORIAL` do mecanismo de instrumentação de etapas — pré-requisito
estrutural das 2 TASKs de capacidade da Wave 2 (fechamento/histórico em TASK-029-002,
carimbo no PDF em TASK-029-003), setup-first (princípio 5). Território e precedentes:
`docs/producao-material/MAP.md` (seções "Acervo", "Contraste, pegadinha, flashcard e
protocolo impresso (F7 · PLAN-027)") e PLAN-029 §5/§6 (DEC-029-003, snapshot JSON — não
hash — irreversível, pendência declarada no INDEX aguardando confirmação do Diretor na
Entrega).

## Escopo

### Inclui

- `mnemonicos-backend/prisma/schema.prisma`:
  - `enum ProductionStageType`: novo valor aditivo `VERSAO_EDITORIAL`, com o comentário em
    linha própria ACIMA do valor (nunca colado a ele — mesma convenção de
    `ASSOCIACAO_VISUAL`/`PUBLICACAO_PDF`/`MATERIAL_REFORCO`, exigida por
    `extractPrismaEnum`/`domain-types-parity.test.ts`), mantendo os 6 valores existentes
    intocados e na mesma ordem.
  - `model RawContent`: relação nova `contentVersions ContentVersion[]` (sem coluna nova —
    `pegadinhaText`/demais campos já existem desde F5/F7, intocados).
  - `model ContentVersion` (novo), forma literal do PLAN-029 §5:
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
    **Sem** `updatedAt`/`deletedAt` (FR-028-004: a imutabilidade é ausência de coluna e de
    caminho de escrita, não campo de estado) — a relação `author` usa o relation name
    default (nenhum `@relation("...")` nomeado: `User` ainda não tem outra relação de
    autoria homônima que exija desambiguação, diferente de `RawContentAuthor`/
    `ContrastAuthor`/`ProductionFlashcardAuthor`, que coexistem entre si).
  - `model User`: relação reversa nova `contentVersions ContentVersion[]`.
- Migração Prisma nova via `prisma migrate dev --create-only` (a geração não aplica nada) —
  1 diretório novo em `prisma/migrations/`: `ALTER TYPE "ProductionStageType" ADD VALUE
  'VERSAO_EDITORIAL'`, `CREATE TABLE "content_versions"`, `CREATE UNIQUE INDEX` (o
  `@@unique([rawContentId, number])`), `ADD CONSTRAINT` (2× FK) — texto exato já no
  PLAN-029 §5, nenhum `DROP`/`ALTER` destrutivo. **Aplicar exige autorização do Diretor**
  (mesmo protocolo de TASK-023-001/TASK-025-001/TASK-027-001) — passo explícito do
  `/keelson:implement` (`AskUserQuestion`), nunca aplicado em produção por esta TASK.
- `mnemonicos-backend/tests/integration/content-version.model.integration.test.ts` (novo,
  molde `material-reforco.model.integration.test.ts`/
  `visual-associations.model.integration.test.ts`): monta a cadeia `Topic`/`User`/
  `RawContent` via `tests/support/production-events-fixtures.ts` (código existente, sem
  alteração), cria 1 `ContentVersion` via `testPrisma.contentVersion.create` vinculado a
  esse `RawContent`/autor com `number: 1`, `legislativeClosureDate` e `contentSnapshot`
  (objeto JSON arbitrário de teste, ex. `{ rawText: 'x', radarClass: 'ALTA', ... }` — a
  forma exata do snapshot é decidida por TASK-029-002, esta TASK só prova que a coluna
  `Json` aceita e devolve um objeto), lê de volta (`findUniqueOrThrow`) confirmando os 6
  campos próprios (`number`, `legislativeClosureDate`, `authorId`, `closedAt`,
  `contentSnapshot`, `rawContentId`); 2º caso: tenta criar uma 2ª `ContentVersion` com o
  MESMO `rawContentId` e `number: 1` — `@@unique` rejeita (par comportamental: rejeita **e**
  a 1ª linha sobrevive, `findUniqueOrThrow` resolve — nunca fixar `err.code` do Prisma como
  oráculo primário, lição ativa "[Dados/Persistência] FK `onDelete: Restrict` no Postgres
  não gera `P2003`" — mesma classe de cautela vale para violação de `@@unique`, que o
  Prisma mapeia como `P2002`, mas o oráculo estável aqui também é o par comportamental:
  rejeita + a 1ª linha intocada).

### Não inclui

- Interface TS `ContentVersion` em `mnemonicos-backend/src/domain/types.ts`/
  `mnemonicos-frontend/src/types/domain.ts` — nasce em TASK-029-004 (COMP-029-009).
- `content-versions.schema.ts`/`.service.ts`/`.routes.ts` — nascem em TASK-029-002.
- Qualquer extensão de `publication.service.ts`/`pdf-composer.ts` — TASK-029-003.
- Aplicação da migração em produção.

## Critérios de pronto

- [ ] Schema contém os elementos novos — item do Inclui sem AC isolado (chore habilitador,
      sem `Realiza (FRs)`), oráculo é o contrato do próprio schema. Verificação executável:
      `npm --prefix mnemonicos-backend run db:generate` → exit 0; leitura de
      `schema.prisma` confirmando o comentário do valor `VERSAO_EDITORIAL` em linha
      própria acima dele (nunca colado), `onDelete: Restrict` nos 2 FKs novas
      (`ContentVersion.rawContent`, `ContentVersion.author`), `@@unique([rawContentId,
      number])`, `@@map("content_versions")`, e a AUSÊNCIA literal de `updatedAt`/
      `deletedAt` no corpo do model `ContentVersion` (grep negativo dentro do bloco do
      model, universo = corpo do model entre `model ContentVersion {` e o `}` que o
      fecha — nunca o arquivo inteiro, para não colidir com `updatedAt`/`deletedAt` de
      OUTROS models legítimos). Fixada antes do código.
- [ ] Migração aditiva — verificação executável: leitura do `migration.sql` gerado
      confirmando só `ALTER TYPE ... ADD VALUE`/`CREATE TABLE`/`CREATE UNIQUE INDEX`/`ADD
      CONSTRAINT`. Falsificável: qualquer `DROP`/`ALTER COLUMN` presente no SQL gerado
      reprova o critério.
- [ ] Smoke test do modelo de dados — item do Inclui sem AC (chore habilitador), oráculo é
      o contrato do próprio schema: verificação executável: `npm --prefix
      mnemonicos-backend run test:integration -- --testPathPatterns=content-version.model`
      → `OK (N tests)`, incluindo (a) o caso que cria 1 `ContentVersion` vinculada a
      `RawContent`/`User` seedados e lê os 6 campos de volta via Prisma Client, e (b) o
      caso de unicidade (2ª `ContentVersion` do MESMO `rawContentId` com `number: 1`
      rejeitada, 1ª linha sobrevive — confirmado por `findUniqueOrThrow` bem-sucedido
      sobre a 1ª após a tentativa da 2ª falhar).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npm --prefix mnemonicos-backend run lint` → exit 0.

## Riscos específicos

- TRISK-029-004 (PLAN §8) — `onDelete: Restrict` na FK `rawContentId` de `ContentVersion`
  bloqueia hard-delete do `RawContent` pai enquanto houver Versão fechada; a fatia que
  definir expurgo físico (fora de escopo aqui) precisa resolver o destino das Versões
  antes de agir — nenhum código desta TASK tenta expurgo.
- `ALTER TYPE ... ADD VALUE` do Postgres não pode ser lido/escrito na MESMA transação em
  que é adicionado — mesma mitigação já aplicada em `ASSOCIACAO_VISUAL`/`PUBLICACAO_PDF`/
  `MATERIAL_REFORCO` (o valor só é referenciado pelo código depois da migração aplicada
  num deploy anterior); nenhum código desta TASK grava `VERSAO_EDITORIAL` na mesma
  transação da migração.
- Fatia sensível (migração, princípio 8): `security-engineer` (gate 8) revisa o diff
  completo, inclusive as 2 FKs `Restrict` novas.
- Autorização do Diretor para aplicar a migração é ato humano fora desta TASK — o
  `/keelson:implement` escala via `AskUserQuestion` antes do 1º passo que aplica.
- Lição ativa [Dados/Persistência] "FK `onDelete: Restrict` no Postgres não gera `P2003` —
  SQLSTATE `23001`, não `23503`" — se alguma TASK futura provar bloqueio de FK Restrict
  deste model, o oráculo é o par comportamental (rejeita + linha sobrevive), nunca fixar
  `err.code === 'P2003'`.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-142

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
