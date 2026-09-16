# TASK-027-001: Setup — schema Prisma, migração aditiva e smoke test do modelo de dados

**Slug**: producao-material
**Pertence a**: PLAN-027
**Realiza (FRs)**: nenhuma
**Componente**: nenhuma
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Todo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-027-003, TASK-027-004, TASK-027-005

## Contexto

Habilita, no schema Prisma, os 2 models N:1 diretos com `RawContent` (Contraste e
`ProductionFlashcard`) e a coluna `pegadinhaText`, mais o valor aditivo `MATERIAL_REFORCO`
do mecanismo de instrumentação de etapas (compartilhado pelos 3 registros autorados,
DEC-027-004) — pré-requisito estrutural das 3 TASKs de capacidade (003 Contraste, 004
Flashcard, 005 Pegadinha), setup-first (princípio 5). Território e precedentes: MAP.md do
slug e memo de exploração (`exploration-producao-material.md`, seção "Reconhecimento
técnico (code-scout) — PLAN de SPEC-026 / F7", itens 1 e 9).

## Escopo

### Inclui

- `mnemonicos-backend/prisma/schema.prisma`:
  - `enum ProductionStageType`: novo valor aditivo `MATERIAL_REFORCO`, com o comentário em
    linha própria ACIMA do valor (nunca colado a ele — mesma convenção de
    `ASSOCIACAO_VISUAL`/`PUBLICACAO_PDF`, exigida por `extractPrismaEnum`/teste de
    paridade), mantendo os 5 valores existentes intocados e na mesma ordem.
  - `model RawContent`: campo novo `pegadinhaText String?` (null = sem Pegadinha elaborada
    registrada), com o comentário `///` do PLAN-027 §5 (DEC-027-002); relações novas
    `contrasts Contrast[]` e `productionFlashcards ProductionFlashcard[]`.
  - `model Contrast` (novo): `id` uuid7, `rawContentId String` + `rawContent RawContent
    @relation(fields: [rawContentId], references: [id], onDelete: Restrict)`, `authorId
    String` + `author User @relation("ContrastAuthor", fields: [authorId], references:
    [id], onDelete: Restrict)`, `confusableText String`, `distinctionText String`,
    `createdAt`/`updatedAt`, `@@index([rawContentId, createdAt(sort: Asc)])`,
    `@@map("contrasts")` — forma literal do PLAN-027 §5.
  - `model ProductionFlashcard` (novo): mesma forma de `Contrast` — campos `question
    String`/`answer String`, `author User @relation("ProductionFlashcardAuthor", ...)`,
    `@@map("production_flashcards")` — forma literal do PLAN-027 §5 (DEC-027-003: nome
    distinto do `model Flashcard` legado, dormente desde F2, para não colidir).
  - `model User`: relações reversas novas `contrasts Contrast[] @relation("ContrastAuthor")`
    e `productionFlashcards ProductionFlashcard[]
    @relation("ProductionFlashcardAuthor")`.
- Migração Prisma nova via `prisma migrate dev --create-only` (a geração não aplica nada) —
  1 diretório novo em `prisma/migrations/`: `ALTER TYPE "ProductionStageType" ADD VALUE
  'MATERIAL_REFORCO'`, `ALTER TABLE "raw_contents" ADD COLUMN "pegadinhaText"`, `CREATE
  TABLE "contrasts"`, `CREATE TABLE "production_flashcards"`, `CREATE INDEX` (2×), `ADD
  CONSTRAINT` (4× FK) — texto exato já no PLAN-027 §5, nenhum `DROP`/`ALTER` destrutivo.
  **Aplicar exige autorização do Diretor** (mesmo protocolo de TASK-023-001/TASK-025-001) —
  passo explícito do `/keelson:implement` (`AskUserQuestion`), nunca aplicado em produção
  por esta TASK.
- `mnemonicos-backend/tests/integration/material-reforco.model.integration.test.ts` (novo,
  molde `visual-associations.model.integration.test.ts`/
  `production-events.model.integration.test.ts`): monta a cadeia `Topic`/`User`/`RawContent`
  via `tests/support/production-events-fixtures.ts` (código existente, sem alteração),
  cria 1 `Contrast` e 1 `ProductionFlashcard` via `testPrisma.contrast.create`/
  `testPrisma.productionFlashcard.create` vinculados a esse `RawContent`/autor, lê ambos de
  volta (`findUniqueOrThrow`), e lê `pegadinhaText` do `RawContent` seedado direto via
  `testPrisma.rawContent.findUniqueOrThrow` — valor `null` nesta wave (nenhum service ainda
  escreve nele, TRISK-027-003), oráculo é o contrato do próprio schema (chave nova
  exercitada com valor não-nulo onde aplicável, mesmo sem consumidor de serviço ainda).

### Não inclui

- Interfaces TS `Contrast`/`ProductionFlashcard` em `mnemonicos-backend/src/domain/types.ts`/
  `mnemonicos-frontend/src/types/domain.ts` — nascem nas TASKs de capacidade (003/004).
- Campo `pegadinhaText` em `RAW_CONTENT_DETAIL_SELECT`/`RawContentDetail`
  (`contents.service.ts`) — nasce em TASK-027-005.
- Qualquer service, rota ou componente de UI.
- Aplicação da migração em produção.

## Critérios de pronto

- [ ] Schema contém os elementos novos — item do Inclui sem AC isolado (chore habilitador,
      sem `Realiza (FRs)`), oráculo é o contrato do próprio schema. Verificação executável:
      `npm --prefix mnemonicos-backend run db:generate` → exit 0; leitura de
      `schema.prisma` confirmando o comentário do valor `MATERIAL_REFORCO` em linha
      própria acima dele (nunca colado), `onDelete: Restrict` nos 4 FKs novos
      (`Contrast.rawContent`, `Contrast.author`, `ProductionFlashcard.rawContent`,
      `ProductionFlashcard.author`), `@@index([rawContentId, createdAt(sort: Asc)])` nos 2
      models novos, e `@@map("contrasts")`/`@@map("production_flashcards")`. Fixada antes
      do código.
- [ ] Migração aditiva — verificação executável: leitura do `migration.sql` gerado
      confirmando só `ALTER TYPE ... ADD VALUE`/`ALTER TABLE ... ADD COLUMN`/`CREATE
      TABLE`/`CREATE INDEX`/`ADD CONSTRAINT`. Falsificável: qualquer `DROP`/`ALTER COLUMN`
      presente no SQL gerado reprova o critério.
- [ ] Smoke test do modelo de dados — item do Inclui sem AC (chore habilitador), oráculo é
      o contrato do próprio schema: cada model/coluna/valor de enum novo exercitado com
      valor não-nulo, exceto `pegadinhaText` que nasce sempre `null` nesta wave por não ter
      consumidor de escrita ainda. Verificação executável: `npm --prefix
      mnemonicos-backend run test:integration -- material-reforco.model` → `OK (N tests)`,
      incluindo o caso que cria 1 `Contrast` + 1 `ProductionFlashcard` vinculados a
      `RawContent`/`User` seedados e lê `pegadinhaText` (`null`) de volta via Prisma
      Client. Falsificável: se o `@@map`/alguma FK estivesse errado, o `create` rejeitaria
      com erro do Postgres.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npm --prefix mnemonicos-backend run lint` → exit 0.

## Riscos específicos

- TRISK-027-001: `ALTER TYPE ... ADD VALUE` do Postgres não pode ser lido/escrito na MESMA
  transação em que é adicionado — mitigação já aplicada em `ASSOCIACAO_VISUAL`/
  `PUBLICACAO_PDF` (o valor só é referenciado pelo código depois que a migração já aplicou
  num deploy anterior); nenhum código desta TASK grava `MATERIAL_REFORCO` na mesma
  transação da migração.
- TRISK-027-003: `pegadinhaText` embutido em `RawContent` passa a ser carregado por
  qualquer SELECT genérico que não use `select` explícito — mitigação (adicionar o campo
  a `RAW_CONTENT_DETAIL_SELECT`) fica com TASK-027-005, único ponto que precisa ler o
  campo.
- Fatia sensível (migração, princípio 8): `security-engineer` (gate 8) revisa o diff
  completo, inclusive as 4 FKs `Restrict` novas.
- Autorização do Diretor para aplicar a migração é ato humano fora desta TASK — o
  `/keelson:implement` escala via `AskUserQuestion` antes do 1º passo que aplica.
- Lição ativa [Dados/Persistência] "FK `onDelete: Restrict` no Postgres não gera `P2003` —
  SQLSTATE `23001`, não `23503`" — se alguma TASK futura provar bloqueio de FK Restrict
  destes 2 models, o oráculo é o par comportamental (rejeita + linha sobrevive), nunca
  fixar `err.code === 'P2003'`.

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
