# PLAN-006: Conteúdo bruto e Quebra da regra

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.1
**Autor**: time keelson (scribe)
**Data**: 2026-09-01

## Aderência a guidelines

**Ficha/perfil de linguagem**: backend `node-22` (`guidelines/project/backend/node-22.md`) + frontend `next-16` (`guidelines/project/frontend/next-16.md`); guidelines de projeto vencem o perfil em conflito.
**Stack vigente herdado**: Node 22 · TypeScript 6 (`strict`, CommonJS) · Express 5 · Prisma 7 (driver adapter `@prisma/adapter-pg`; URL fora do `schema.prisma`) · PostgreSQL · Jest + supertest (integração sobre Docker Postgres) — backend. Next 16 (App Router, Turbopack) · React 19 · TypeScript 6 (`strict`) · Tailwind 4 (tokens em `@theme`) · Redux Toolkit + RTK Query · Jest + Testing Library — frontend.
**Padrão arquitetural seguido**: backend — módulo em `src/modules/<nome>/` com camadas **schema** (Zod) → **service** (regra + Prisma, sem I/O de HTTP) → **routes** (HTTP); árvore de rotas **plana** em `src/http/routes.ts` montada **depois** de `requireAuth` (barreira deny-by-default de F1), um `requireRole('<MÉTODO>','<caminho>',...papéis)` por rota na montagem, `verifyOrigin` em toda mutação autenticada por cookie; erro previsto = `AppError`, handler `async` sem `try/catch`. Frontend — Server Component por default, `'use client'` só no pedaço interativo; estado de servidor em RTK Query (`src/store/api.ts`), nada replicado em slice; rótulos pt-BR sempre do mapa em `src/types/domain.ts`.
**Decisões irreversíveis do slug tocadas**: nenhuma — o INDEX de `producao-material` traz `## Decisões irreversíveis` vazio (as 12 DECs do PLAN-003 são todas reversíveis).
**Decisões irreversíveis de outros slugs em conflito**: nenhuma — `producao-material` é o único slug em `docs/` (só há `docs/_meta` além dele); não há outro `INDEX.md` a varrer.
**Exceções aos guidelines**: nenhuma.

## Cobertura

**SPEC referenciada**: SPEC-005
**Slice declarado**: cobertura total (Caso D) — todos os 24 FRs e 7 NFRs da SPEC-005. Nenhum PLAN anterior cobre qualquer requisito de SPEC-005.

**FRs cobertos**:
- FR-005-001
- FR-005-002
- FR-005-003
- FR-005-004
- FR-005-005
- FR-005-006
- FR-005-007
- FR-005-008
- FR-005-009
- FR-005-010
- FR-005-011
- FR-005-012
- FR-005-013
- FR-005-014
- FR-005-015
- FR-005-016
- FR-005-017
- FR-005-018
- FR-005-019
- FR-005-020
- FR-005-021
- FR-005-022
- FR-005-023
- FR-005-024

**NFRs cobertos**:
- NFR-005-001
- NFR-005-002
- NFR-005-003
- NFR-005-004
- NFR-005-005
- NFR-005-006
- NFR-005-007

**Cobertura agregada do slug**:
- Total na SPEC: 24 FRs + 7 NFRs
- Cobertos por planos anteriores: 0
- Cobertos por este: 24 FRs + 7 NFRs
- Gap restante: 0
- Funcionalidades cobertas: FEAT-005-001 (total), FEAT-005-002 (total)

## 1. Visão técnica

F2 acrescenta a **primeira estação da linha de produção** sobre a barreira de acesso entregue por F1, sem reconstruí-la. O desenho tem quatro frentes:

1. **Modelo de dados (migração Prisma aditiva).** Dois enums novos (`ProofRadarClass`, `NormativeSourceType`) e dois models novos (`RawContent`, `RuleBreakdown`). O `RawContent` carrega a classe obrigatória do radar de prova, a fonte normativa **embutida** em colunas opcionais, o carimbo de última alteração (quem/quando, sem trilha) e a marca de **remoção reversível** (`deletedAt`). A `RuleBreakdown` é **1:1** com o `RawContent` (FK `@unique`, `onDelete: Cascade`). `Mnemonic.source` (texto livre legado) **não é tocado**. A migração é aditiva; a execução (`prisma migrate dev`) gera arquivo versionado revisável e **só roda após confirmação do Diretor** (TRISK-006-001).

2. **Módulo backend `contents/`** no padrão schema→service→routes. O service concentra a regra de **alcance** (EDITOR vê o que registrou; ADMIN vê tudo), o filtro `deletedAt: null` em **todo** caminho de leitura, a **imutabilidade da autoria** na edição, o carimbo de última alteração e o **upsert 1:1** da Quebra. As 7 rotas novas montam depois de `requireAuth`, cada uma com `requireRole(...,'EDITOR','ADMIN')` e `verifyOrigin` nas mutações; entram automaticamente no censo da suíte `route-authz-matrix`, mas a **lista fixa (tripwire)** dessa suíte precisa subir de 12 para 19 pares no mesmo passo (TRISK-006-002).

3. **Espelho de tipos cross-repo (mesmo diff).** `PROOF_RADAR_CLASSES`, `NORMATIVE_SOURCE_TYPES` e as interfaces de `RawContent`/`RawContentSummary`/`RuleBreakdown` entram nos dois `types.ts` no mesmo conjunto de alterações; o frontend também recebe os mapas de rótulo pt-BR. O teste de paridade `domain-types-parity.test.ts` — hoje só sobre `USER_ROLES`/`SessionUser` — é estendido aos dois enums novos (DEC-006-005).

4. **Frontend: saneamento + telas.** `src/store/api.ts` perde `listMnemonics`/`listDueFlashcards` e seus hooks (nenhuma tela consome — censo formal na TASK antes de deletar), corrige `listDisciplines` para o envelope `Paginated<T>` real e ganha os endpoints RTK Query de conteúdo e quebra. Um **segmento de rota novo** `(interno)/content` é registrado nos dois pontos obrigatórios (`internal-routes.ts` + `config.matcher` do `proxy.ts`, travado por `proxy.test.ts`). Quatro páginas: listagem (com 3 estados e ordenação vinda do backend), formulário de criação/edição/remoção, e a tela da Quebra da regra.

Além disso, a **semente** passa a ser de Obrigação Tributária (Direito Tributário) com uma lista nomeada de temas, ≥1 `RawContent` com classe e fonte estruturada mais a sua `RuleBreakdown` completa, e sem o material de Direito Administrativo/Constitucional (não coexiste).

## 2. Stack e dependências

- **Nenhuma dependência nova** (npm) em nenhum dos dois repos. Todo o desenho usa o que F1 já instalou.
- **Migração Prisma 7 aditiva**: 3ª pasta em `mnemonicos-backend/prisma/migrations/` (as duas atuais: `20260823161550_init`, `20260828190018_add_session_and_user_disabled`). Nome sugerido: `add_raw_content_and_rule_breakdown`. `id` com `@default(uuid(7))` (nativo no Prisma 7), `@@map` snake_case. `npm run db:migrate` = `prisma migrate dev` — **execução exige confirmar com o Diretor** (regra do projeto / Q-005-003 / BRIEF-005 P-05).
- **Testes de integração** rodam sobre o harness de F1 (`jest.integration.config.ts`, Docker Postgres via `npm run db:up`, banco `mnemonicos_test` separado). `global-setup.ts` aplica a migração nova sozinho (`prisma migrate deploy`); `resetDb()` trunca a tabela nova sozinho (varre `pg_tables`).
- **Frontend**: `jest.config.ts` (next/jest, jsdom, coverage mínimo 50%). Tailwind 4 sem config JS — tokens novos, se houver, em `@theme` de `globals.css`.

## 3. Componentes

### COMP-006-001: Migração Prisma — enums e models de Conteúdo bruto e Quebra da regra
**Responsabilidade**: acrescentar ao `schema.prisma` os enums `ProofRadarClass` e `NormativeSourceType`, os models `RawContent` e `RuleBreakdown` (com `@@map`, índices e `onDelete` conforme DEC-006-008), e as relações reversas em `User` e `Topic`. `Mnemonic.source` permanece intocado.
**Realiza**: FR-005-001, FR-005-010, FR-005-013, FR-005-014, FR-005-015, NFR-005-007
**Interface pública**: `enum ProofRadarClass { ALTA MEDIA DETALHE EXCECAO PEGADINHA }`; `enum NormativeSourceType { CF CTN LEI LEI_COMPLEMENTAR SUMULA ATO_NORMATIVO }`; `model RawContent` (`@@map("raw_contents")`) e `model RuleBreakdown` (`@@map("rule_breakdowns")`) conforme §5; arquivo de migração versionado no diff.
**Dependências**: nenhuma

### COMP-006-002: `contents.schema.ts` — validação de entrada (Zod)
**Responsabilidade**: definir os schemas Zod da superfície de conteúdo e quebra, incluindo o refinamento "citação obrigatória quando há tipo do dispositivo".
**Realiza**: FR-005-001, FR-005-002, FR-005-003, FR-005-010, FR-005-011, FR-005-014, FR-005-017
**Interface pública**:
- `createRawContentSchema` — `topicId`, `rawText`, `radarClass` (∈ `ProofRadarClass`), `sourceType?`, `sourceCitation?`, `sourceUrl?`; refinamento: `sourceCitation` obrigatória se `sourceType` presente.
- `updateRawContentSchema` — mesmos campos aplicáveis; **sem `authorId`**.
- `listRawContentsQuerySchema` — `page`, `perPage` (sem filtros — NFR-005-004).
- `saveRuleBreakdownSchema` — `concept`, `action`, `object`, `essence` obrigatórios; `condition?`, `exception?`.
**Dependências**: COMP-006-001

### COMP-006-003: `contents.service.ts` — regra de negócio e acesso a dados
**Responsabilidade**: alcance por papel, filtro de remoção reversível em todo caminho de leitura, imutabilidade da autoria, carimbo de última alteração, upsert 1:1 da Quebra e recusa quando o conteúdo não existe/foi removido. Sem I/O de HTTP.
**Realiza**: FR-005-001, FR-005-002, FR-005-003, FR-005-005, FR-005-006, FR-005-007, FR-005-008, FR-005-010, FR-005-012, FR-005-013, FR-005-014, FR-005-015, FR-005-016, FR-005-017, FR-005-019, FR-005-020, FR-005-021, FR-005-024, NFR-005-004, NFR-005-006
**Interface pública**:
- `createRawContent(input, actorId)` — grava `authorId = actorId`.
- `listRawContents(query, actor)` — EDITOR: `authorId = actor.id AND deletedAt = null`; ADMIN: `deletedAt = null`; ordenação `createdAt desc` determinística; devolve `Paginated<RawContentSummary>` (resumo do texto + disciplina + tema + classe + citação do dispositivo + flag "tem quebra").
- `getRawContent(id, actor)` — 404 (`AppError`) se deletado ou fora do alcance.
- `updateRawContent(id, input, actor)` — `authorId` intocado; seta `lastEditedById`/`lastEditedAt`.
- `softDeleteRawContent(id, actor)` — seta `deletedAt`; a Quebra vinculada segue no banco mas fica inalcançável (ver `getRuleBreakdown`).
- `getRuleBreakdown(rawContentId, actor)` / `saveRuleBreakdown(rawContentId, input, actor)` — upsert por `rawContentId`; recusa se o conteúdo não existe ou está soft-deleted.
- A derivação da prioridade de apresentação **não é** deste componente (é rótulo de frontend, e está fora de F2 — DEC-006-009).
**Dependências**: COMP-006-001, COMP-006-002

### COMP-006-004: `contents.routes.ts` — superfície HTTP sob a barreira deny-by-default
**Responsabilidade**: expor as 7 rotas, cada uma com declaração explícita de papéis na montagem, `verifyOrigin` nas mutações; montar o router em `src/http/routes.ts` **depois** de `requireAuth` (bloco protegido), import no topo.
**Realiza**: FR-005-001, FR-005-006, NFR-005-001
**Interface pública** (árvore plana; caminho completo em cada `requireRole`):
- `GET /contents` → `requireRole('GET','/contents','EDITOR','ADMIN')` — devolve `Paginated<RawContentSummary>`.
- `POST /contents` → `verifyOrigin` + `requireRole('POST','/contents','EDITOR','ADMIN')`.
- `GET /contents/:id` → `requireRole('GET','/contents/:id','EDITOR','ADMIN')`.
- `PATCH /contents/:id` → `verifyOrigin` + `requireRole('PATCH','/contents/:id','EDITOR','ADMIN')`.
- `DELETE /contents/:id` → `verifyOrigin` + `requireRole('DELETE','/contents/:id','EDITOR','ADMIN')` — remoção reversível.
- `GET /contents/:id/breakdown` → `requireRole('GET','/contents/:id/breakdown','EDITOR','ADMIN')`.
- `PUT /contents/:id/breakdown` → `verifyOrigin` + `requireRole('PUT','/contents/:id/breakdown','EDITOR','ADMIN')` — upsert 1:1.
**Dependências**: COMP-006-003

### COMP-006-005: Atualização do tripwire da suíte `route-authz-matrix`
**Responsabilidade**: atualizar a lista fixa de pares `<MÉTODO> <caminho>` da asserção de censo em `tests/integration/route-authz-matrix.integration.test.ts` de 12 para 19 (os 7 pares novos), mantendo a suíte verde. O censo dos laços é automático; só essa lista literal precisa da mão.
**Realiza**: NFR-005-001
**Interface pública**: a asserção `expect(ROUTES.map(key).sort()).toEqual([...19 pares...])` atualizada; nenhuma API de produção.
**Dependências**: COMP-006-004

### COMP-006-006: Teste de integração `contents.integration.test.ts`
**Responsabilidade**: exercitar a superfície nova sobre a app real (`supertest`): CRUD de `RawContent`, remoção reversível e inalcançabilidade por id direto, upsert 1:1 da Quebra e Quebra órfã inalcançável, alcance EDITOR × ADMIN, recusas 401/403 (sem sessão, papel STUDENT), recusa de Quebra sobre conteúdo inexistente/removido. Usa a fixture `seedSession(role)` do harness de F1.
**Realiza**: FR-005-008, FR-005-016, NFR-005-001, NFR-005-006
**Interface pública**: casos de teste; nenhum código de produção. Oráculos falsificáveis (devem quebrar com o service trocado por `return null`).
**Dependências**: COMP-006-004

### COMP-006-007: Consolidação de `Paginated<T>` no domínio e fecho do contrato `/disciplines`
**Responsabilidade**: mover `Paginated<T>` de `disciplines.service.ts` para `src/domain/types.ts` (compartilhado, sem I/O); `disciplines.service.ts` passa a importar; `DisciplineSummary` e `RawContentSummary` ficam locais aos módulos. Confirma o contrato: `GET /disciplines` **mantém** `Paginated<DisciplineSummary>` (envelope já padrão do backend) — o alinhamento é feito no frontend (COMP-006-011), não aqui.
**Realiza**: FR-005-024, NFR-005-004
**Interface pública**: `export type Paginated<T> = { data: T[]; page: number; perPage: number; total: number }` em `src/domain/types.ts`.
**Dependências**: nenhuma

### COMP-006-008: Espelho de tipos de domínio cross-repo (mesmo diff)
**Responsabilidade**: acrescentar, no mesmo conjunto de alterações, aos dois arquivos de tipos: `PROOF_RADAR_CLASSES` (5), `NORMATIVE_SOURCE_TYPES` (6) e as interfaces `RawContent` / `RawContentSummary` / `RuleBreakdown`. No frontend, também `PROOF_RADAR_CLASS_LABELS` e `NORMATIVE_SOURCE_TYPE_LABELS` (pt-BR). **Não** inclui mapa/função de prioridade de apresentação (DEC-006-009).
**Realiza**: NFR-005-002, NFR-005-005
**Interface pública**: constantes e interfaces exportadas em `mnemonicos-backend/src/domain/types.ts` e `mnemonicos-frontend/src/types/domain.ts`, com o mesmo conjunto de valores nos dois enums.
**Dependências**: COMP-006-001

### COMP-006-009: Rede de paridade cross-repo dos enums novos
**Responsabilidade**: estender `mnemonicos-backend/tests/unit/domain-types-parity.test.ts` para comparar **literalmente** `PROOF_RADAR_CLASSES` e `NORMATIVE_SOURCE_TYPES` entre os dois `types.ts` (mesmo mecanismo de leitura cross-repo já usado para `USER_ROLES`).
**Realiza**: NFR-005-005
**Interface pública**: casos de teste adicionais; nenhum código de produção.
**Dependências**: COMP-006-008

### COMP-006-010: Semente de Obrigação Tributária (Direito Tributário)
**Responsabilidade**: em `prisma/seed.ts`, trocar `DISCIPLINES` por **Direito Tributário** com uma lista nomeada de temas de Obrigação Tributária; estender os tipos locais de seed e o laço de upsert para semear ≥1 `RawContent` (com `radarClass` e fonte normativa estruturada) mais a sua `RuleBreakdown` completa (`authorId` = ADMIN semeado por `seedAdmin`, que roda antes); remover o material de Direito Administrativo/Constitucional. Chave natural do `RawContent` para idempotência: `(topicId, rawText)` (espelha o padrão `(topic, hook)` já usado).
**Realiza**: NFR-005-003, NFR-005-007
**Interface pública**: `DISCIPLINES` reescrito; tipos `RawContentSeed`/`RuleBreakdownSeed`; `main()` com o upsert estendido. Temas sugeridos: "Obrigação Tributária Principal e Acessória", "Fato Gerador", "Sujeito Ativo e Passivo", "Solidariedade Tributária", "Responsabilidade Tributária", "Domicílio Tributário".
**Dependências**: COMP-006-001

### COMP-006-011: Saneamento e extensão de `src/store/api.ts` (RTK Query)
**Responsabilidade**: remover `listMnemonics`, `listDueFlashcards` e os hooks `useListMnemonicsQuery`/`useListDueFlashcardsQuery` (censo formal antes de deletar); ajustar `TAG_TYPES` (retirar `Mnemonic`, `Flashcard`; adicionar `RawContent`, `RuleBreakdown`); corrigir `listDisciplines` para `Paginated<DisciplineSummary>`; adicionar os endpoints de conteúdo e quebra. Não tocar o bloco de sessão de F1.
**Realiza**: FR-005-005, FR-005-019, NFR-005-004
**Interface pública**:
- `listRawContents` (`GET /contents`, `Paginated<RawContentSummary>`, `providesTags:['RawContent']`)
- `getRawContent` (`providesTags:['RawContent']`)
- `createRawContent`, `updateRawContent`, `deleteRawContent` (mutations, `invalidatesTags:['RawContent']`)
- `getRuleBreakdown` (`providesTags:['RuleBreakdown']`)
- `saveRuleBreakdown` (`invalidatesTags:['RuleBreakdown','RawContent']`)
**Dependências**: COMP-006-007, COMP-006-008

### COMP-006-012: Registro do segmento de rota `content` na área interna
**Responsabilidade**: registrar o segmento novo nos dois pontos obrigatórios, no mesmo diff: `src/lib/internal-routes.ts` (`INTERNAL_ROUTE_PREFIXES` passa a `['studio', 'content']`) e `src/proxy.ts` (`config.matcher` — array literal de strings, lido por AST estático pelo Next — ganha `'/content'` e `'/content/:path*'`). `src/proxy.test.ts` trava a divergência diretório × símbolo × matcher.
**Realiza**: NFR-005-001
**Interface pública**: `INTERNAL_ROUTE_PREFIXES` e `config.matcher` atualizados; nenhuma API nova.
**Dependências**: nenhuma

### COMP-006-013: Tela de listagem de Conteúdos brutos — `(interno)/content/page.tsx`
**Responsabilidade**: casca Server Component; lista interativa em client component com `useListRawContentsQuery`. Três estados observáveis (carregando / vazio com orientação em pt-BR / falha com opção de repetir); ordenação vem do backend (mais recente primeiro); cada item exibe resumo do texto, disciplina, tema, classe do radar (rótulo do método), ao menos a citação do dispositivo, indicador "tem Quebra da regra" e via de acesso à Quebra daquele conteúdo.
**Realiza**: FR-005-005, FR-005-012, FR-005-021, FR-005-022, FR-005-023, FR-005-024, NFR-005-002
**Interface pública**: rota `/content`; componente client `content-list`.
**Dependências**: COMP-006-011, COMP-006-012

### COMP-006-014: Formulário de Conteúdo bruto — criação, edição e remoção
**Responsabilidade**: client component compartilhado entre `(interno)/content/new/page.tsx` (criação) e `(interno)/content/[id]/page.tsx` (detalhe/edição). Campos: texto normativo, disciplina, tema/assunto, classe do radar (select das 5), fonte normativa (tipo select + citação + link opcional). Três estados da ação (em andamento / sucesso / falha com dados preservados e mensagem pt-BR). Edição reabre com valores persistidos e aplica as mesmas regras de obrigatoriedade; a autoria não é enviada nem editável. Remoção com pedido de confirmação explícita + três estados; ao concluir, o item some da listagem. Via de acesso à Quebra a partir da visão do conteúdo.
**Realiza**: FR-005-003, FR-005-004, FR-005-006, FR-005-007, FR-005-009, FR-005-010, FR-005-012, FR-005-022, NFR-005-002
**Interface pública**: rotas `/content/new` e `/content/[id]`; componente client `content-form`.
**Dependências**: COMP-006-011, COMP-006-012

### COMP-006-015: Tela da Quebra da regra — `(interno)/content/[id]/breakdown/page.tsx`
**Responsabilidade**: client component com os cinco blocos (CONCEITO, AÇÃO, OBJETO, CONDIÇÃO, EXCEÇÃO) mais a síntese. Obrigatoriedade de CONCEITO, AÇÃO, OBJETO e síntese; CONDIÇÃO e EXCEÇÃO podem ficar vazios ("não se aplica", nunca "inacabado"). Três estados da ação; recusa de validação não descarta o que foi digitado. Reabre com os valores persistidos.
**Realiza**: FR-005-017, FR-005-018, FR-005-019, FR-005-020, NFR-005-002
**Interface pública**: rota `/content/[id]/breakdown`; componente client `rule-breakdown-form`.
**Dependências**: COMP-006-011, COMP-006-012

## 4. Fluxos principais

**F-1 · Registrar Conteúdo bruto.** EDITOR submete texto + disciplina + tema + classe do radar (e opcionalmente a fonte). `createRawContentSchema` valida (422 com campos inválidos se classe ausente/fora do conjunto, ou se texto/disciplina/tema faltam, ou se há tipo de dispositivo sem citação); `contents.service.createRawContent` grava com `authorId` = ator da sessão; a resposta traz o item, que passa a constar na listagem do EDITOR.

**F-2 · Listar com alcance.** `GET /contents` → `listRawContents(query, actor)`: EDITOR recebe só `authorId = actor.id AND deletedAt = null`; ADMIN recebe todos os não-removidos. Envelope `Paginated<RawContentSummary>`, ordenação `createdAt desc`. A tela expõe carregando / vazio / falha.

**F-3 · ADMIN edita e remove item alheio.** `PATCH /contents/:id` por ADMIN sobre item de outro EDITOR: `updateRawContent` grava os novos valores, **não toca `authorId`**, e seta `lastEditedById`/`lastEditedAt` para o ADMIN e o instante. `DELETE /contents/:id` em seguida aplica `deletedAt` (remoção reversível); a autoria original permanece.

**F-4 · Remoção reversível e inalcançabilidade da Quebra.** `softDeleteRawContent` marca `deletedAt`. A `RuleBreakdown` continua no banco, mas `getRuleBreakdown` recusa (404) porque o conteúdo-pai está soft-deleted; `getRawContent` por id direto também recusa. Nenhuma Quebra órfã fica alcançável. Os dados ficam preservados para expurgo futuro (F8) — sem UI de restauração em F2.

**F-5 · Upsert 1:1 da Quebra da regra.** `PUT /contents/:id/breakdown` → `saveRuleBreakdownSchema` valida os obrigatórios (CONCEITO, AÇÃO, OBJETO, síntese); `saveRuleBreakdown` faz upsert por `rawContentId` (`@unique`): primeira gravação cria, gravações seguintes atualizam a mesma linha. Recusa se o conteúdo não existe ou foi removido. A listagem passa a indicar "tem Quebra".

**F-6 · Saneamento do contrato fantasma + boot deny-by-default.** O frontend deixa de emitir `GET /mnemonics` e `GET /flashcards/due`; `listDisciplines` passa a esperar `Paginated<T>`. No backend, as 7 rotas novas montam depois de `requireAuth` com `requireRole(...,'EDITOR','ADMIN')`; `assertDenyByDefault` + `sealRouteRoles` derrubam o boot se alguma ficar sem a chave exata `"<MÉTODO> <caminho>"`. O tripwire da `route-authz-matrix` sobe para 19 pares.

## 5. Modelo de dados

Migração **aditiva** ao `mnemonicos-backend/prisma/schema.prisma`. Tipos lidos do schema real (Prisma 7: `id` `String @default(uuid(7))`, `@@map` snake_case; `Topic` tem `@@unique([disciplineId, slug])`; `User` tem `role UserRole` e `disabledAt`; `Mnemonic.source String?` **não é alterado**).

```prisma
enum ProofRadarClass {
  ALTA
  MEDIA
  DETALHE
  EXCECAO
  PEGADINHA
}

enum NormativeSourceType {
  CF
  CTN
  LEI
  LEI_COMPLEMENTAR
  SUMULA
  ATO_NORMATIVO
}

model RawContent {
  id             String               @id @default(uuid(7))
  topicId        String
  topic          Topic                @relation(fields: [topicId], references: [id], onDelete: Restrict)
  authorId       String
  author         User                 @relation("RawContentAuthor", fields: [authorId], references: [id], onDelete: Restrict)
  rawText        String
  radarClass     ProofRadarClass
  sourceType     NormativeSourceType?
  sourceCitation String?
  sourceUrl      String?
  lastEditedById String?
  lastEditedBy   User?                @relation("RawContentLastEditor", fields: [lastEditedById], references: [id], onDelete: SetNull)
  lastEditedAt   DateTime?
  deletedAt      DateTime?
  createdAt      DateTime             @default(now())
  updatedAt      DateTime             @updatedAt
  breakdown      RuleBreakdown?

  @@index([authorId])
  @@index([topicId])
  @@index([deletedAt])
  @@map("raw_contents")
}

model RuleBreakdown {
  id           String     @id @default(uuid(7))
  rawContentId String     @unique
  rawContent   RawContent @relation(fields: [rawContentId], references: [id], onDelete: Cascade)
  concept      String
  action       String
  object       String
  condition    String?
  exception    String?
  essence      String
  createdAt    DateTime   @default(now())
  updatedAt    DateTime   @updatedAt

  @@map("rule_breakdowns")
}
```

Relações reversas nas entidades existentes (mesma migração):

```prisma
model User {
  // ...campos atuais...
  rawContents       RawContent[] @relation("RawContentAuthor")
  editedRawContents RawContent[] @relation("RawContentLastEditor")
}

model Topic {
  // ...campos atuais...
  rawContents RawContent[]
}
```

Notas:
- **Remoção reversível**: `deletedAt = null` significa ativo. Não há `deletedAt` na `RuleBreakdown` — ela herda a inalcançabilidade do pai (DEC-006-001).
- **Fonte normativa embutida**: `sourceType`/`sourceCitation`/`sourceUrl` nullable; regra "citação obrigatória se há tipo" fica no schema Zod, não no banco (DEC-006-002).
- **`onDelete`** conforme DEC-006-008: `Topic→RawContent` = `Restrict`; `author→RawContent` = `Restrict`; `lastEditedBy→RawContent` = `SetNull`; `RawContent→RuleBreakdown` = `Cascade` (só relevante sob eventual hard-delete de F8).
- **Semente**: `RawContent` idempotente por `(topicId, rawText)`; `RuleBreakdown` por `rawContentId`.
- `Mnemonic.source` (texto livre legado) preservado — nenhuma coluna alterada, nada migrado (NFR-005-007 / A-005-010).

## 6. Decisões arquiteturais

### DEC-006-001: Remoção reversível (`deletedAt`) para Conteúdo bruto e Quebra da regra
**Contexto**: FR-005-008 pede remoção reversível com marca temporal, dados preservados para expurgo futuro (F8), sem UI de restauração em F2. AC-005-037 exige inalcançabilidade (por id direto e pela Quebra), não destruição.
**Decisão**: coluna `deletedAt DateTime?` em `RawContent` (null = ativo); todo caminho de leitura do service filtra `deletedAt: null`. A `RuleBreakdown` não ganha coluna própria — o service recusa `getRuleBreakdown` quando o conteúdo-pai está soft-deleted.
**Alternativas consideradas**:
- Remoção física (`DELETE` real de `RawContent` + cascade na Quebra), descartada porque destrói trabalho humano de produção (A-005-002 / A-007) sem rede numa operação de 1–2 pessoas; F8 não reconstrói o que foi apagado, e o requisito pede reversibilidade, não expurgo.
**Consequências**: toda query de leitura carrega o filtro (risco de esquecer um caminho — TRISK-006-003); índice `@@index([deletedAt])`; o expurgo real e a restauração ficam para F8.
**Reabrir se**: F8 (versionamento / administração) definir política de expurgo definitivo ou tela de restauração.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova

### DEC-006-002: Fonte normativa embutida em colunas do `RawContent`
**Contexto**: FR-005-010/011; A-005-008 torna a fonte **opcional** no registro desta fatia; sem demanda de reuso da mesma fonte entre conteúdos em F2.
**Decisão**: `sourceType NormativeSourceType?`, `sourceCitation String?`, `sourceUrl String?` como colunas do próprio `RawContent`; refinamento Zod exige a citação quando o tipo está presente.
**Alternativas consideradas**:
- Entidade `NormativeSource` própria reutilizável (FK a partir do `RawContent`), descartada porque acrescenta +1 model, +1 service, +1 rota e busca/seleção de fonte na tela **sem nenhuma demanda de reuso** em F2 — superfície de API e custo de manutenção crescem sem contrapartida, e a trilha de versão/fechamento legislativo (que motivaria a entidade) é de F8.
**Consequências**: reuso da mesma fonte entre conteúdos exigiria migração para promover a entidade; a fonte aqui é referência estruturada **sem** trilha de versão.
**Reabrir se**: F8/F9 exigirem reuso da mesma fonte normativa entre múltiplos conteúdos ou trilha de fechamento legislativo.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova

### DEC-006-003: Quebra da regra como model próprio 1:1 (`RuleBreakdown`, FK `@unique`)
**Contexto**: FR-005-014/015; A-005-003 fixa a Quebra como 1:1 com o Conteúdo bruto; F4 lerá a Quebra isoladamente.
**Decisão**: model `RuleBreakdown` com `rawContentId String @unique` (`onDelete: Cascade`); persistência por upsert em `rawContentId`.
**Alternativas consideradas**:
- Colunas da quebra na própria tabela `raw_contents`, descartada porque infla toda linha da listagem com 7 campos textuais longos, mistura duas responsabilidades (registro bruto × decomposição) numa entidade só, e obriga F4 a carregar o conteúdo inteiro para ler apenas a Quebra.
**Consequências**: um join a mais nas telas que mostram conteúdo + quebra juntos; a unicidade 1:1 é garantida pelo banco (`@unique`), não só pelo service.
**Reabrir se**: F4 precisar de N quebras/tiras por conteúdo — contradiz A-005-003 e exigiria revisão da SPEC.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova

### DEC-006-004: Rotas `/contents` (+ `/contents/:id/breakdown`) e envelope `Paginated<T>` nas listagens
**Contexto**: Q-005-002 delega os nomes de rota e a forma dos payloads ao PLAN; a superfície nova entra sob a barreira plana de F1; o backend já usa `Paginated<T>` em `disciplines`.
**Decisão**: recurso plano `/contents`, `/contents/:id`, `/contents/:id/breakdown` (`GET`/`PUT`); `GET /contents` e `GET /disciplines` respondem `Paginated<T>` (`{data,page,perPage,total}`).
**Alternativas consideradas**:
- `/raw-contents`, descartada por verbosidade sem ganho — na fábrica "conteúdo" já é o bruto.
- Recurso aninhado `/topics/:id/contents`, descartada porque o conteúdo **não** é subordinado navegacionalmente ao tema (a listagem de F2 é por autor, não por tema) e criaria dependência de uma rota de tema que não existe.
**Consequências**: listar conteúdo por tema como recurso REST aninhado, se pedido, será rota nova.
**Reabrir se**: F10 (painel / triagem) exigir listagem de conteúdo por tema como recurso aninhado.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (envelope `Paginated<T>` já existe em `disciplines`)

### DEC-006-005: Estender `domain-types-parity.test.ts` aos dois enums novos
**Contexto**: NFR-005-005 / RISK-005-003 / AC-005-030; hoje só `USER_ROLES` + `SessionUser` têm rede de divergência cross-repo; os demais enums não têm.
**Decisão**: estender o teste unitário de paridade para comparar **literalmente** `PROOF_RADAR_CLASSES` e `NORMATIVE_SOURCE_TYPES` entre `mnemonicos-backend/src/domain/types.ts` e `mnemonicos-frontend/src/types/domain.ts`.
**Alternativas consideradas**:
- Confiar só na disciplina de "mesmo diff" sem teste, descartada porque o modo de falha (enum divergente que quebra em runtime **sem** o typecheck acusar) já custou uma lição paga do projeto ("constante espelhada entre repos declara a fonte e tem teste de divergência"); repetir é reincidência conhecida.
**Consequências**: o teste lê os dois arquivos por caminho relativo cross-repo — padrão já presente no teste atual.
**Reabrir se**: nunca — é lição do projeto já paga; remover a rede reabre o modo de falha.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (o teste já existe; só amplia a cobertura)

### DEC-006-006: Segmento de rota `(interno)/content` (identificador en, rótulos pt-BR), registrado nos dois pontos
**Contexto**: telas novas sob a área interna de F1; CLAUDE.md exige identificadores de código em inglês e texto de interface em pt-BR; `INTERNAL_ROUTE_PREFIXES` e o `config.matcher` do `proxy.ts` são fonte dupla que um teste trava.
**Decisão**: segmento `content` (en); `INTERNAL_ROUTE_PREFIXES` passa a `['studio','content']`; `config.matcher` (array literal de strings, lido por AST estático pelo Next — sem `.flatMap`/spread) ganha `'/content'` e `'/content/:path*'`, no mesmo diff; `src/proxy.test.ts` trava a divergência diretório × símbolo × matcher.
**Alternativas consideradas**:
- Segmento em pt (`conteudos`), descartada porque a rota é identificador de código e a regra do projeto ("identificadores em inglês") vale para ela; os textos visíveis das telas seguem em pt-BR pelo mapa de `domain.ts`.
**Consequências**: qualquer tela nova sob `content/**` já entra na barreira do proxy pelo prefixo.
**Reabrir se**: a convenção de i18n de segmento de rota do projeto mudar.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (mesmo mecanismo de `studio` em F1)

### DEC-006-007: Consolidar `Paginated<T>` em `src/domain/types.ts`
**Contexto**: `disciplines.service.ts` redefine `Paginated<T>` local; o módulo `contents` traria a 3ª cópia do mesmo tipo.
**Decisão**: mover `Paginated<T>` para `src/domain/types.ts` (compartilhado, sem I/O); `DisciplineSummary` e `RawContentSummary` ficam locais aos seus módulos; `disciplines.service.ts` passa a importar.
**Alternativas consideradas**:
- Deixar `Paginated<T>` local em cada módulo, descartada porque a duplicação cresce a cada módulo de listagem (já seriam 3 cópias com `contents`) e a divergência silenciosa de um campo do envelope passa despercebida.
**Consequências**: um import a mais nos módulos de listagem; `domain/types.ts` ganha um tipo genérico além dos enums.
**Reabrir se**: nunca — consolidação de duplicação declarada.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada

### DEC-006-008: `onDelete` das relações novas
**Contexto**: relações `Topic→RawContent`, `author(User)→RawContent`, `lastEditedBy(User)→RawContent`, `RawContent→RuleBreakdown`; o sistema não faz hard-delete de `User` (F1 usa `disabledAt`).
**Decisão**: `Topic→RawContent` = `Restrict`; `author→RawContent` = `Restrict`; `lastEditedBy→RawContent` = `SetNull` (é carimbo, não vínculo forte); `RawContent→RuleBreakdown` = `Cascade` físico no banco (só age sob eventual hard-delete futuro — a remoção de produto de F2 é soft, DEC-006-001).
**Alternativas consideradas**:
- `Cascade` em `Topic→RawContent`, descartada porque uma correção num tema apagaria todo o conteúdo produzido sob ele — perda de trabalho humano irreparável em F2.
**Consequências**: hard-delete de `Topic` ou `User` com conteúdo vinculado fica bloqueado pelo banco até F8 definir expurgo. Migração aditiva; `onDelete` é alterável em migração posterior.
**Reabrir se**: política de expurgo de F8 exigir cascata a partir de tema ou autor.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova

### DEC-006-009: Não introduzir o mapa/função de prioridade de apresentação em F2
**Contexto**: A-005-001 define a derivação `ALTA→Alta / MEDIA→Média / DETALHE|EXCECAO|PEGADINHA→Baixa`; §4.2 da SPEC adia a **exibição** da prioridade para F10; o CLAUDE.md veta código sem consumidor (escopo mínimo).
**Decisão**: o frontend ganha `PROOF_RADAR_CLASS_LABELS` e `NORMATIVE_SOURCE_TYPE_LABELS` (pt-BR, com consumidor nas telas de F2), mas **não** ganha o mapa/função de prioridade de apresentação; as telas de F2 exibem as 5 classes com o rótulo do método.
**Alternativas consideradas**:
- Adicionar já a função pura de prioridade "disponível para F10", descartada porque entra código sem consumidor (viola o escopo mínimo do projeto) e F10 é a fatia que define o eixo de prioridade real — a derivação pode mudar de forma quando esse eixo existir.
**Consequências**: F10 adiciona a derivação junto do seu consumidor; A-005-001 permanece selado como premissa, não como código.
**Reabrir se**: F10 (ou F7) introduzir o eixo de prioridade de apresentação.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (regra de escopo mínimo do CLAUDE.md)

## 7. Mapeamento FR -> componente

| FR | Componente | AC cobertos |
|----|------------|-------------|
| FR-005-001 | COMP-006-002, COMP-006-003, COMP-006-004, COMP-006-001 | AC-005-001 |
| FR-005-002 | COMP-006-002, COMP-006-003 | AC-005-002, AC-005-003 |
| FR-005-003 | COMP-006-002, COMP-006-003, COMP-006-014 | AC-005-004 |
| FR-005-004 | COMP-006-014 | AC-005-005, AC-005-006, AC-005-007, AC-005-010 |
| FR-005-005 | COMP-006-003, COMP-006-013, COMP-006-011 | AC-005-001, AC-005-018 |
| FR-005-006 | COMP-006-003, COMP-006-004, COMP-006-014 | AC-005-008, AC-005-009 |
| FR-005-007 | COMP-006-003, COMP-006-014 | AC-005-009, AC-005-036 |
| FR-005-008 | COMP-006-003, COMP-006-006 | AC-005-011, AC-005-013, AC-005-037 |
| FR-005-009 | COMP-006-014 | AC-005-011, AC-005-012 |
| FR-005-010 | COMP-006-001, COMP-006-002, COMP-006-003, COMP-006-014 | AC-005-014 |
| FR-005-011 | COMP-006-002 | AC-005-015 |
| FR-005-012 | COMP-006-003, COMP-006-013, COMP-006-014 | AC-005-014, AC-005-016 |
| FR-005-013 | COMP-006-001, COMP-006-003 | AC-005-036 |
| FR-005-014 | COMP-006-001, COMP-006-002, COMP-006-003 | AC-005-019 |
| FR-005-015 | COMP-006-001, COMP-006-003 | AC-005-020 |
| FR-005-016 | COMP-006-003, COMP-006-006 | AC-005-021 |
| FR-005-017 | COMP-006-002, COMP-006-003, COMP-006-015 | AC-005-022 |
| FR-005-018 | COMP-006-015 | AC-005-023 |
| FR-005-019 | COMP-006-003, COMP-006-015, COMP-006-011 | AC-005-019, AC-005-024 |
| FR-005-020 | COMP-006-003, COMP-006-015 | AC-005-024 |
| FR-005-021 | COMP-006-003, COMP-006-013 | AC-005-025 |
| FR-005-022 | COMP-006-013, COMP-006-014 | AC-005-033 |
| FR-005-023 | COMP-006-013 | AC-005-034 |
| FR-005-024 | COMP-006-003, COMP-006-007, COMP-006-013 | AC-005-035, AC-005-028 |
| NFR-005-001 | COMP-006-004, COMP-006-005, COMP-006-006, COMP-006-012 | AC-005-026 |
| NFR-005-002 | COMP-006-008, COMP-006-013, COMP-006-014, COMP-006-015 | AC-005-029 |
| NFR-005-003 | COMP-006-010 | AC-005-027 |
| NFR-005-004 | COMP-006-003, COMP-006-007, COMP-006-011 | AC-005-028 |
| NFR-005-005 | COMP-006-008, COMP-006-009 | AC-005-030 |
| NFR-005-006 | COMP-006-003, COMP-006-006 | AC-005-031, AC-005-037 |
| NFR-005-007 | COMP-006-001, COMP-006-010 | AC-005-032 |

## 8. Riscos técnicos

- **TRISK-006-001** — A execução da migração aditiva exige confirmação do Diretor (regra do projeto / Q-005-003 / BRIEF-005 P-05). Mitigação: `prisma migrate dev` gera arquivo versionado que entra no diff da TASK de schema, revisável; a wave de schema **para e pergunta** antes de rodar; nenhum comando que altere estrutura roda silenciosamente.
- **TRISK-006-002** — O tripwire da suíte `route-authz-matrix` é uma lista fixa de 12 pares `<MÉTODO> <caminho>`; enquanto não subir para 19, a suíte fica vermelha, e se a TASK de rotas atualizar a lista sem cuidado pode mascarar uma regressão real. Mitigação: COMP-006-005 é item explícito e separado; a atualização da lista e a prova das 7 rotas novas (COMP-006-006) andam juntas; o censo dos laços continua automático.
- **TRISK-006-003** — Remoção reversível exige que **todo** caminho de leitura filtre `deletedAt = null` (listagem, detalhe por id, Quebra, censo). Um caminho esquecido vaza conteúdo removido e deixa Quebra órfã alcançável. Mitigação: o filtro vive centralizado no `contents.service.ts` (COMP-006-003); COMP-006-006 prova inalcançabilidade por id direto e da Quebra após remoção (AC-005-037, AC-005-031).
- **TRISK-006-004** — Os dois enums novos ficam sem rede de paridade cross-repo até DEC-006-005 entrar; divergência entre as pontas quebra em runtime sem o typecheck acusar (RISK-005-003). Mitigação: COMP-006-008 e COMP-006-009 estão neste mesmo PLAN e no mesmo conjunto de alterações; o teste estendido falha no CI se os conjuntos divergirem.

## 9. Definition of Done deste PLAN

- [x] Todos os 24 FRs cobertos têm implementação satisfazendo os ACs — `TASK-006-INDEX.md` "Cobertura de FRs": 24/24 FR-005-001..024 mapeados, 14/14 TASKs Done; "Cobertura de ACs": 33/33 AC-005-001..037 (exceto o vão intencional AC-005-017 — F10) com TASK própria, todas Done.
- [x] Todos os 7 NFRs cobertos têm verificação — `TASK-006-INDEX.md` "Cobertura de NFRs": NFR-005-001..007, todas as TASKs referenciadas Done; verificação por teste (gates 1-7) e, onde há efeito observável de tela, gate 9 (SPEC-005, FEAT-005-001/002, ambas ✅ 8/8, linhas `**Verificação (gate 9)**:` datadas).
- [x] Decisões DEC-006-001 a DEC-006-009 refletidas no código — confirmado por code-reviewer em toda rodada de gate das Waves 1-5 (soft-delete centralizado em `contents.service.ts`, `Paginated<T>` consolidado, rede de paridade cross-repo estendida aos 2 enums novos, sem mapa de prioridade de apresentação no código — DEC-006-009/F10); nenhuma reprovação de gate 5 (DECs respeitadas) sobreviveu ao fecho de nenhuma wave.
- [x] Aderência à ficha/perfil validada — confirmado por code-reviewer em toda rodada (schema→service→routes sem Prisma na rota, erro via `AppError`, rotas montadas sob `requireAuth`+`requireRole`/`verifyOrigin`, Server Component default com `'use client'` só onde há estado/evento, estado de servidor só em RTK Query, rótulos pt-BR do mapa de `domain.ts`, `config.matcher` como array literal); gate 6 aprovado em todas as waves.
- [x] Todos os ACs cobertos por teste (gate 1 dos quality gates) — incluindo `contents.integration.test.ts` e a paridade cross-repo estendida — reconfirmado agora, ao fecho: backend unitário 208/208 (19 suítes), backend integração 213/213 (11 suítes, inclui `contents.integration.test.ts`, `contents-frontend-contract.test.ts` e `domain-types-parity.test.ts`), frontend 166/166 (16 suítes) — `npm test`/`npm run test:integration` rodados nesta sessão de Entrega, todos verdes.
- [x] Migração Prisma aditiva revisável no diff da TASK de schema; execução confirmada com o Diretor antes de rodar (TRISK-006-001) — migração de TASK-006-001 e `20260905130131_add_raw_content_listing_indexes` (Wave 3) entraram no diff da respectiva TASK, revisáveis; autorização do Diretor colhida via AskUserQuestion antes de cada execução (ledger de sessão, eventos `decisao`).
- [x] Métrica da SPEC (§1.3 declara `Fonte de medição`) — **parcial, gap declarado em (a)**:
  - **(a)** 100% da superfície nova (7 rotas) no censo da suíte `route-authz-matrix`, tripwire atualizado de 12 para 19 pares, 0 rota não-declarada: **provado** (suíte integra o `npm run test:integration` verde acima). A cláusula "**verde no CI**" **não é satisfazível hoje**: nem `mnemonicos-backend` nem `mnemonicos-frontend` têm pipeline de CI configurado (nenhum `.github/workflows` nem equivalente em nenhum dos dois repos — condição pré-existente, não introduzida por este PLAN). Gap declarado, não escondido — carregado à Entrega e ao INDEX (RISK-006-009).
  - **(b)** invariante "todo `RawContent` persistido tem `radarClass`" — **provado** por AC-005-002/AC-005-003 (schema Zod + service recusam criação sem classe) e pela semente (AC-005-027, `seedMaterial` sempre atribui `radarClass`); nenhum caminho de escrita cria conteúdo sem classe.
  - **(c)** número **primário observacional** (Conteúdos brutos de Obrigação Tributária com Quebra da regra completa produzidos **pela tela**, mais a razão `registrados : com-quebra`) apurado por inspeção humana nesta Entrega: consulta direta ao Postgres de desenvolvimento, filtrando `RawContent.authorId` = EDITOR de dev (distinto do `authorId` = ADMIN usado por `seedMaterial`) e `deletedAt: null` → **0 registrados, 0 com Quebra completa**. Razão não computável com denominador 0. Estado esperado de pré-lançamento: as únicas interações reais com a tela até aqui foram as sessões do gate 9, que restauram os dados ao final por desenho do próprio Roteiro do gate 9 (TASK-006-012/013/014) — não há uso real de EDITOR ainda. Mesma natureza de MET-002-001/SPEC-002 (também pendente); a série passa a acumular com o primeiro uso real pós-Entrega. Fonte externa (suíte de conformidade herdada de F1, para (a)) + dono (time de engenharia) já registrados no INDEX.

## 10. Não coberto por este PLAN

- **Exibição da prioridade de apresentação** (Alta/Média/Baixa) e o mapa/função que a deriva — F10 (DEC-006-009; A-005-001 permanece selado como premissa).
- **Filtro da listagem** (por disciplina, tema/assunto ou classe do radar) — F10.
- **Tira mnemônica** como sequência ordenada de quadros — F4 (substitui, não estende, os "blocos" desta fatia).
- **Biblioteca / associação visual** — F5.
- **Geração / exportação de PDF** — F6.
- **Pegadinha como entidade comparativa lado-a-lado** — F7 (aqui `PEGADINHA` é só uma classe do radar).
- **Versionamento editorial / histórico / trilha de fonte / fechamento legislativo** — F8; nesta fatia a fonte normativa é referência estruturada sem trilha de versão, e o carimbo de última alteração é estado atual sem histórico.
- **Instrumentação de tempo por etapa da fábrica** — F3.
- **UI de restauração e expurgo definitivo** de Conteúdo bruto removido — F8 / administração.
- **Cadastro de nova disciplina ou tema/assunto pela tela de produção** — fora de F2 por A-005-007; E-01 (Q-005-004) segue pendente do Diretor, a decidir na Entrega junto de MET-002-001.
- **Migração / conversão do `Mnemonic.source` legado** — F4 consome a fonte estruturada e encerra a duplicidade.
- **Obrigatoriedade da fonte normativa** — entra no gate de "Versão aprovada" (F9); em F2 é opcional (A-005-008).
- **Rascunho / salvar Quebra da regra incompleta** — F2 exige completude mínima (CONCEITO, AÇÃO, OBJETO, síntese); salvar parcial é aditivo futuro (A-005-012).
