# TASK-006-001: Migrar o schema Prisma — enums e models de Conteúdo bruto e Quebra da regra

**Slug**: producao-material
**Pertence a**: PLAN-006
**Realiza (FRs)**: FR-005-001, FR-005-010, FR-005-013, FR-005-014, FR-005-015
**Funcionalidade**: FEAT-005-001 (primária), FEAT-005-002
**Componente**: COMP-006-001 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — `git.branchStrategy: unica`; não criar branch por task; a closure commita TASK a TASK)
**Padrão de commit**: Conventional Commits (`feat:` para esta TASK — modelo de dados novo)
**Framework de teste**: Jest — unit em `mnemonicos-backend/tests/unit/`; integração em `mnemonicos-backend/tests/integration/` (Docker Postgres `mnemonicos_test` via `npm --prefix mnemonicos-backend run db:up`; `npm --prefix mnemonicos-backend run test:integration`, `--experimental-vm-modules --runInBand`). `global-setup.ts:47-61` aplica a migração nova sozinho (`prisma migrate deploy`) no banco descartável; `db.ts:39-53` (`resetDb()` via `pg_tables`) trunca a tabela nova sozinho.

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-006-004, TASK-006-005, TASK-006-006

## Contexto

F2 acrescenta a primeira estação da linha de produção. O `schema.prisma` (`mnemonicos-backend/prisma/schema.prisma`, Prisma 7 — `id String @default(uuid(7))`, `@@map` snake_case, `previewFeatures=["relationJoins"]`) hoje não tem enum de radar de prova nem de fonte normativa, nem model de Conteúdo bruto ou Quebra da regra. Esta TASK entrega **só a estrutura de dados**: dois enums, dois models e as relações reversas, mais o arquivo de migração aditiva versionado. `Mnemonic.source` (texto livre legado) **não é tocado** (NFR-005-007 / A-005-010). Os ACs comportamentais dos FRs realizados (AC-005-001/-014/-019/-020/-036…) são enforçados nas camadas de schema Zod / service / rota / tela (TASK-006-006, TASK-006-009, TASK-006-011, TASK-006-013, TASK-006-014) — o único AC verificável na camada de schema é **AC-005-032** (preservação de `mnemonics.source`). Gates: g1; g8 (migração é superfície sensível); g9/g10/g11 n/a.

## Escopo

### Inclui

- `mnemonicos-backend/prisma/schema.prisma`:
  - `enum ProofRadarClass { ALTA MEDIA DETALHE EXCECAO PEGADINHA }`
  - `enum NormativeSourceType { CF CTN LEI LEI_COMPLEMENTAR SUMULA ATO_NORMATIVO }`
  - `model RawContent` (`@@map("raw_contents")`) com as colunas, tipos e nullability da §5 do PLAN-006 (`topicId`, `authorId`, `rawText`, `radarClass ProofRadarClass` NOT NULL, `sourceType NormativeSourceType?`, `sourceCitation String?`, `sourceUrl String?`, `lastEditedById String?`, `lastEditedAt DateTime?`, `deletedAt DateTime?`, `createdAt`, `updatedAt`, relação `breakdown RuleBreakdown?`), `@@index([authorId])`, `@@index([topicId])`, `@@index([deletedAt])`.
  - `model RuleBreakdown` (`@@map("rule_breakdowns")`) com `rawContentId String @unique`, `concept`/`action`/`object`/`essence` NOT NULL, `condition String?`, `exception String?`, `createdAt`, `updatedAt`.
  - `onDelete` conforme DEC-006-008: `Topic→RawContent` = `Restrict`; `author(User)→RawContent` = `Restrict`; `lastEditedBy(User)→RawContent` = `SetNull`; `RawContent→RuleBreakdown` = `Cascade`.
  - Relações reversas na mesma migração: `model User` ganha `rawContents RawContent[] @relation("RawContentAuthor")` e `editedRawContents RawContent[] @relation("RawContentLastEditor")`; `model Topic` ganha `rawContents RawContent[]`.
- Arquivo de migração versionado `prisma/migrations/<timestamp>_add_raw_content_and_rule_breakdown/migration.sql`, gerado por `prisma migrate dev --create-only` e commitado no diff da TASK — **aditivo puro**.
- Regeneração do client (`npm --prefix mnemonicos-backend run db:generate`).
- Teste de integração de estrutura em `mnemonicos-backend/tests/integration/`: `raw_contents`/`rule_breakdowns` existem com colunas, nullability e índices esperados; `mnemonics.source` presente e inalterado (oráculo de AC-005-032).

### Não inclui

- **Executar** a migração além do harness de integração (`mnemonicos_test`). A execução em dev/CI (`prisma migrate deploy` / `migrate dev` sem `--create-only`) **pende de confirmação do Diretor** (TRISK-006-001 / Q-005-003 / BRIEF-005 P-05) — o `/keelson:implement` para nesta wave e pergunta.
- Qualquer schema Zod, service, rota ou seed (TASK-006-002/006/011; a semente é TASK-006-005).
- `deletedAt` na `RuleBreakdown` — ela herda a inalcançabilidade do pai (DEC-006-001).
- Alteração de qualquer coluna de `mnemonics`, `Mnemonic.source` incluído.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Colar os 2 enums e os 2 models no `schema.prisma` conforme a §5 do PLAN-006 (`@@map` snake_case; `id String @default(uuid(7))`).
2. Adicionar as relações reversas em `model User` e `model Topic`.
3. `npm --prefix mnemonicos-backend run db:migrate -- --create-only --name add_raw_content_and_rule_breakdown` — gera o `migration.sql` **sem aplicar**. Revisar: statements só de `CREATE TYPE` / `CREATE TABLE` / `CREATE INDEX`; nenhum `ALTER TABLE "mnemonics"`, `DROP`, `TRUNCATE`.
4. `npm --prefix mnemonicos-backend run db:generate` para regenerar o client.
5. Escrever o teste de integração de estrutura (`information_schema.tables` / `information_schema.columns` / `pg_indexes`), incluindo a comparação do conjunto de colunas de `mnemonics` com o baseline capturado do commit-pai.
6. **Parar e pedir confirmação ao Diretor** antes de qualquer `migrate deploy`/`migrate dev` fora do banco `mnemonicos_test`.

## Critérios de pronto

- [ ] `schema.prisma` declara `enum ProofRadarClass` com exatamente `ALTA, MEDIA, DETALHE, EXCECAO, PEGADINHA` e `enum NormativeSourceType` com exatamente `CF, CTN, LEI, LEI_COMPLEMENTAR, SUMULA, ATO_NORMATIVO`; os models `RawContent`/`RuleBreakdown` têm as colunas, nullability, `@@index` e `onDelete` da §5 do PLAN-006 e DEC-006-008; as relações reversas existem em `User` e `Topic`. Verificação executável: `npm --prefix mnemonicos-backend run db:generate` → exit 0 (schema parseia e o client gera) e `npm --prefix mnemonicos-backend run typecheck` → exit 0. Falsificável: `radarClass` sem tipo NOT NULL, `rawContentId` sem `@unique` ou `onDelete` divergente → `prisma generate` ou `typecheck` reprova. Fixada antes do código.
- [ ] Testes cobrem **AC-005-032** — verificação executável: `npm --prefix mnemonicos-backend run test:integration -- raw-content-structure` → `PASS`, `Tests: ≥4 passed`, fixada antes do código. Sobre o Postgres descartável `mnemonicos_test` (migração aplicada por `global-setup.ts`):
  - (i) `information_schema.tables` → `raw_contents` e `rule_breakdowns` presentes;
  - (ii) `information_schema.columns` → em `raw_contents`, a coluna de `radarClass` é `NOT NULL` e as de `sourceType`/`sourceCitation`/`sourceUrl`/`lastEditedById`/`lastEditedAt`/`deletedAt` são `NULLABLE`; em `rule_breakdowns`, `concept`/`action`/`object`/`essence` `NOT NULL`, `condition`/`exception` `NULLABLE`, e a coluna de `rawContentId` tem índice `UNIQUE`;
  - (iii) `pg_indexes` → índices sobre `raw_contents` nas colunas de `authorId`, `topicId` e `deletedAt`;
  - (iv) **`mnemonics.source` presente e `NULLABLE`, e o conjunto de colunas de `mnemonics` é idêntico ao do commit-pai** — o teste lê `information_schema.columns` de `mnemonics` e compara com o conjunto literal capturado do HEAD atual (rodar a query contra o schema/DB do commit-pai **antes** de fixar e colar o conjunto esperado aqui; nomes de coluna conforme o Prisma gera a partir do `schema.prisma` real).
  Falsificável: remover `source` de `model Mnemonic` ou alterar/renomear qualquer coluna de `mnemonics` na migração → (iv) vermelho; `raw_contents` sem índice em `deletedAt` → (iii) vermelho; `rawContentId` sem `UNIQUE` → (ii) vermelho.
- [ ] Migração aditiva revisável no diff (critério herdado — "migração gerada e revisável no diff; execução confirmada com o Diretor antes de rodar"): a pasta `prisma/migrations/<timestamp>_add_raw_content_and_rule_breakdown/` entra no diff da TASK. Verificação executável: `git show --stat HEAD -- 'mnemonicos-backend/prisma/migrations/**'` lista a nova pasta; **checagem de ausência de statement destrutivo, com comentário SQL excluído do universo buscado** (contrato §273(b) — `grep` de estrutura exclui o comentário): `grep -vE '^\s*--' mnemonicos-backend/prisma/migrations/*_add_raw_content_and_rule_breakdown/migration.sql | grep -nE 'ALTER TABLE "mnemonics"|DROP TABLE|DROP COLUMN|TRUNCATE'` → **sem resultado** (rodar também contra o working tree antes do commit; o arquivo nasce nesta TASK, logo não existe no commit-pai). Falsificável: qualquer statement destrutivo (fora de comentário) ou toque em `mnemonics` → o 2º `grep` casa, vermelho.
- [ ] Execução confirmada com o Diretor antes de rodar (critério herdado): a geração usa `prisma migrate dev --create-only` (SQL gerado, **não aplicado**); nenhum `migrate deploy`/`migrate dev` roda contra dev/CI nesta TASK. O harness de integração (`global-setup.ts:47-61`, guarda fail-closed `db-url.ts:20-61`) aplica a migração **só** no banco descartável `mnemonicos_test`. A confirmação do Diretor (ou o estado `pendente`) é registrada no Histórico de execução.
- [ ] Lição ativa [Testes] "Sonda de investigação não nasce em `tests/**`; contagem de teste declara a árvore". Texto da lição (solução): *"sonda/probe de investigação não nasce em `tests/**` — vive no scratchpad da sessão e roda por caminho explícito; se precisar do harness, nasce já com nome fora do `testMatch`. Gate cujo mecanismo de prova escreve arquivo roda em `git worktree` isolada... Gate nunca roda `npm install`/`npm ci` nem edita `package*.json` na árvore principal... quem declara contagem de teste como evidência de gate declara junto a árvore de onde ela saiu — `git status --porcelain` vazio."* Item verificável: o teste de estrutura nasce como arquivo versionado em `mnemonicos-backend/tests/integration/` com nome dentro do `testMatch` (não `zz-*`); nenhuma sonda de inspeção de schema/DDL solta em `tests/**`; a closure declara a contagem da suíte de integração com `git status --porcelain mnemonicos-backend/` **vazio** (ou item a item); `testPathIgnorePatterns` cobre `zz-.*`. Verificação executável: `git status --porcelain mnemonicos-backend/` → vazio após o commit da TASK; `npm --prefix mnemonicos-backend run test:integration` → contagem declarada == observada.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline capturada no início da TASK); `npm --prefix mnemonicos-backend run typecheck` → exit 0.
- [ ] Padrão de commit respeitado (Conventional Commits — `feat:`).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md`: Prisma 7 com `@@map` snake_case, `id @default(uuid(7))`, migração aditiva revisável no diff; URL fora do `schema.prisma`; nenhuma migração roda silenciosamente).
- [ ] Code review aprovado.

## Riscos específicos

- **TRISK-006-001** — a execução da migração aditiva exige confirmação do Diretor; a TASK gera com `--create-only` e para. Nenhum comando que altere estrutura roda fora de `mnemonicos_test`.
  **Resolvido na largada do `/keelson:implement`** (Etapa 4 do `/keelson:auto`, antes do despacho desta TASK): o Diretor confirmou, via `AskUserQuestion`, a opção "Gerar e executar" — aplicar a migração aditiva **também** no banco de dev (`mnemonicos`), não só no `mnemonicos_test` do harness. Evento registrado no ledger da sessão (`intervencao`, `ts: 2026-09-01T13:27:23+0000`, origem `tech-lead`): *"Diretor confirmou (via AskUserQuestion na largada da Wave 1 do implement): migração Prisma aditiva de F2 = GERAR E EXECUTAR (arquivo versionado revisável + aplicar no banco de dev e mnemonicos_test)."* A autorização precede a execução (13:27:23 UTC vs. aplicação em `mnemonicos` às 13:33:16 UTC, conferida em `_prisma_migrations` pelo gate 1–7 da Wave 1). O texto original desta linha (acima) reflete o estado da TASK **no momento da decomposição**, antes da confirmação — a exclusão "fora de `mnemonicos_test`" ficou superada pela decisão do Diretor, registrada aqui para o leitor futuro não ler a divergência como violação.
- Nomes de coluna: o `schema.prisma` só mapeia o **nome da tabela** (`@@map`) — as colunas seguem o que o Prisma gera dos campos (camelCase, salvo `@map` explícito no schema real). Conferir o schema real antes de fixar os literais do teste de estrutura (item (ii)/(iv)).
- Repos symlinkados (lição [Exploração]): editar e verificar sempre pelo caminho dentro do link (`mnemonicos-backend/prisma/...`); ausência detectada por varredura não é fato.
- A suíte de integração não foi exercitada no sync de largada — rodar `npm --prefix mnemonicos-backend run db:up` antes de `test:integration`.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-01T10:27:21-03:00
**Data conclusão**: 2026-09-04T19:38:26-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: e847fd5 (impl) · 827e36e (retry gate 1-7) · ed12238 (carona gate 7)
**Jira**: KAN-29
**Implementado por**: developer
**Revisado por**: code-reviewer (gates 1-7) · security-engineer (gate 8)
**Tentativas**: 2 (1 code-review reprovou por achado de escopo já autorizado + 3 achados baratos; retry fechou os 4; re-review delta aprovou)
**Cobertura final**: n/a (migração + teste de estrutura; suíte do backend 166/166 unit, 146/146 integração pós-wave)
**Arquivos modificados**:
  - mnemonicos-backend/prisma/schema.prisma
  - mnemonicos-backend/prisma/migrations/20260901133222_add_raw_content_and_rule_breakdown/migration.sql
  - mnemonicos-backend/tests/integration/raw-content-structure.integration.test.ts
  - mnemonicos-backend/jest.integration.config.ts
  - mnemonicos-backend/jest.config.ts (retry — zz-.* simétrico)

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados: AC-005-032
- [x] Segurança (gate 8): aprovado — security-engineer, Wave 1 (migração 100% aditiva confirmada linha a linha contra DEC-006-008; 2 achados MEDIA não-bloqueantes registrados fora desta TASK)
- [ ] Comportamento (gate 9): n/a — sem efeito observável de tela nesta TASK (schema/migração); FEAT-005-001 ainda não completa

**Notas**: Migração aditiva executada com autorização do Diretor confirmada na largada do `/keelson:implement` (ver "Riscos específicos" acima — evento de ledger `intervencao`, `ts: 2026-09-01T13:27:23+0000`, anterior à aplicação em dev às 13:33:16 UTC). `licao_candidata` [projeto] (husky/lint-staged índice divergente) roteada e persistida em `guidelines/project/lessons.md` (lição "[Testes] `lint-staged` grava LF..." — confirmada 2, estendida com a distinção ` M` × `MM`). `licao_candidata` [processo] (ambiguidade de "confirmado pelo Diretor" em report; critério que proíbe efeito fora da árvore sem oráculo no alvo) roteada ao `agile-coach`.
