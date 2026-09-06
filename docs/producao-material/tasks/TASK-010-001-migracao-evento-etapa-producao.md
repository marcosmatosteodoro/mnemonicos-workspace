# TASK-010-001: Migração aditiva do evento de etapa de produção + espelho de tipos + rede de paridade

**Slug**: producao-material
**Pertence a**: PLAN-010
**Realiza (FRs)**: FR-009-008
**Componente**: COMP-010-001 (principal), COMP-010-004, COMP-010-005
**Wave**: 1
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico, estratégia `unica`)
**Padrão de commit**: Conventional Commits (`feat:` para o model/migração/tipos, `test:` se o commit de teste for isolado)
**Framework de teste**: Jest 30 + ts-jest (unit: `npm --prefix mnemonicos-backend test`; integração: `npm --prefix mnemonicos-backend run test:integration`)

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-010-002

## Contexto

Fatia sensível (migração + regra de negócio central — princípio 8): introduz o model
append-only `ProductionStageEvent` e os 2 enums que sustentam toda a fatia F3
(`ProductionStageType`, `ProductionEventTransition`), aditivos sobre `RawContent`/`User`.
Território greenfield no projeto: nenhum outro model tem sequência monotônica hoje
(DEC-010-002) nem é append-only real (só INSERT, nunca UPDATE — memo de exploração,
"Precedente de modelagem append-only — NÃO existe"). Setup-first: as duas tasks seguintes
(TASK-010-002, TASK-010-003) dependem do model e dos tipos existirem. Autorização do
Diretor é exigida antes de gerar/aplicar a migração (protocolo do CLAUDE.md do workspace,
mesma régua de PLAN-006/TASK-006-001) — ato do Diretor, não desta TASK.

## Escopo

### Inclui

- `mnemonicos-backend/prisma/schema.prisma`: 2 enums novos —
  `enum ProductionStageType { CONTEUDO_BRUTO QUEBRA_DA_REGRA }` e
  `enum ProductionEventTransition { ABERTURA CONCLUSAO RETRABALHO }` — e o model
  `ProductionStageEvent` (campos `id`, `rawContentId`, `stageType`, `transitionType`,
  `actorId`, `occurredAt`, `sequence BigInt @default(autoincrement())`), com
  `rawContent RawContent @relation(..., onDelete: Restrict)` e
  `actor User @relation(..., onDelete: Restrict)`, `@@index([rawContentId, sequence])`,
  `@@map("production_stage_events")` — exatamente a forma do §5 de PLAN-010 (DEC-010-001,
  DEC-010-002). Sem `updatedAt`/`deletedAt` (a imutabilidade é ausência de caminho de
  update/delete no service da TASK-010-002, não um campo de estado aqui).
- `mnemonicos-backend/prisma/schema.prisma`: alterações aditivas de relação inversa —
  `RawContent.productionStageEvents ProductionStageEvent[]` e
  `User.productionStageEvents ProductionStageEvent[]` (sem `@relation` nomeada — única
  relação deste tipo entre os dois models).
- Migração aditiva gerada via `prisma migrate dev` (autorização do Diretor obtida antes de
  gerar/aplicar) — 1 arquivo em `mnemonicos-backend/prisma/migrations/`: `CREATE TYPE` × 2,
  `CREATE TABLE production_stage_events`, `CREATE INDEX`, 2 `ALTER TABLE ... ADD CONSTRAINT`
  (FK `Restrict`). Nenhum `DROP`/`ALTER` sobre tabela existente.
- `mnemonicos-backend/src/domain/types.ts`: `PRODUCTION_STAGE_TYPES = ['CONTEUDO_BRUTO',
  'QUEBRA_DA_REGRA'] as const` + `type ProductionStageType`;
  `PRODUCTION_EVENT_TRANSITIONS = ['ABERTURA', 'CONCLUSAO', 'RETRABALHO'] as const` + `type
  ProductionEventTransition` — mesmo padrão de `PROOF_RADAR_CLASSES`/`NORMATIVE_SOURCE_TYPES`
  (linhas 59-72 do arquivo), com docblock análogo declarando a fonte canônica
  (`schema.prisma`) e — diferente do padrão de F2 — que **não há** espelho em
  `mnemonicos-frontend/src/types/domain.ts` nesta fatia (DEC-010-006, YAGNI: sem
  consumidor). Só backend; `mnemonicos-frontend/` não é tocado por esta TASK.
- `mnemonicos-backend/tests/unit/domain-types-parity.test.ts`: 2 blocos `it()` novos para
  `PRODUCTION_STAGE_TYPES`/`PRODUCTION_EVENT_TRANSITIONS`, comparando **dois eixos reais**:
  `extractConstArray` (texto de `src/domain/types.ts`) contra uma nova `extractPrismaEnum`
  (texto do `enum` correspondente em `prisma/schema.prisma`) — fecha a paridade intra-repo
  schema↔tipos que o 3º Critério de pronto exige (achado do gate 1-7 na 1ª rodada: a versão
  anterior só comparava o símbolo importado com o texto do MESMO arquivo, tautologia que um
  valor novo no enum Prisma não derrubaria). **Sem** 2º lado no frontend ainda — os blocos
  não leem `mnemonicos-frontend/src/types/domain.ts` nem afirmam "nos dois repositórios"
  (DEC-010-006: comparação cross-repo entra quando o frontend espelhar, F10) — a lição ativa
  "[Testes] Comentário que afirma paridade entre os dois repos só vale se o teste LER as duas
  fontes" (`guidelines/project/lessons.md`) segue respeitada: o teste lê exatamente as fontes
  que o nome do `it()` promete, nem mais nem menos.
- `mnemonicos-backend/tests/integration/production-events.model.integration.test.ts`
  (novo): prova de constraint do model — FK `Restrict` de `rawContentId` (item sem AC — ver
  abaixo) e coluna `sequence` autoincrementando de forma monotônica e estável para eventos
  com `occurredAt` idêntico.

### Não inclui

- `production-events.service.ts` (regra de decisão, emissão, leitura) — TASK-010-002.
- Qualquer chamada de emissão a partir de `contents.service.ts` — TASK-010-003.
- Espelho de `PRODUCTION_STAGE_TYPES`/`PRODUCTION_EVENT_TRANSITIONS` em
  `mnemonicos-frontend/src/types/domain.ts` — adiado por DEC-010-006 (registrado, não
  esquecimento); entra no mesmo diff que o primeiro consumidor real (F10).
- Geração/aplicação da migração em ambiente além do banco de teste local sem autorização
  explícita do Diretor — o ato de rodar `prisma migrate dev`/`deploy` é do Diretor
  (protocolo do CLAUDE.md do workspace), esta TASK só descreve a forma esperada da migração.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Adicionar os 2 enums e o model `ProductionStageEvent` ao `schema.prisma`, seguindo a
   forma literal do §5 de PLAN-010 (comentários `///` incluídos — documentam a garantia de
   imutabilidade e o motivo de cada FK `Restrict`).
2. Adicionar as 2 relações inversas aditivas em `RawContent`/`User`.
3. Pedir autorização do Diretor (via `AskUserQuestion` no `/keelson:implement`) antes de
   `prisma migrate dev` — mesmo protocolo de TASK-006-001.
4. Estender `src/domain/types.ts` com os 2 arrays `as const` + tipos derivados, no mesmo
   bloco de comentário que já documenta `PROOF_RADAR_CLASSES`/`NORMATIVE_SOURCE_TYPES`.
5. Estender `domain-types-parity.test.ts` com os 2 blocos autoconsistentes.
6. Escrever `production-events.model.integration.test.ts` provando FK `Restrict` e
   `sequence` monotônico, usando o padrão de fixture de
   `contents.service.integration.test.ts` (`createUser`/`createTopic` via `testPrisma`
   direto — linhas 52-80 do arquivo).

## Critérios de pronto

- [ ] `schema.prisma` contém os 2 enums (`ProductionStageType`, `ProductionEventTransition`)
      e o model `ProductionStageEvent` com os 7 campos do §5 de PLAN-010, `@@index`
      cobrindo `[rawContentId, sequence]`, e as 2 relações inversas aditivas em
      `RawContent`/`User` — item do Inclui sem AC, oráculo é o contrato do próprio schema:
      verificação executável: `npm --prefix mnemonicos-backend run db:generate` → exit 0
      (o Prisma Client só gera se o schema for válido) e leitura do `schema.prisma`
      confirmando os 2 `onDelete: Restrict`.
- [ ] Migração aditiva aplicada no banco de teste, sem `DROP`/`ALTER` destrutivo sobre
      tabela existente — verificação executável: `npm --prefix mnemonicos-backend run
      db:deploy` (contra `mnemonicos_test`) → exit 0; leitura do arquivo SQL gerado em
      `prisma/migrations/` confirmando só `CREATE TYPE`/`CREATE TABLE`/`CREATE
      INDEX`/`ALTER TABLE ... ADD CONSTRAINT`.
- [ ] Testes cobrem AC-009-007 (parte — faceta de sobrevivência via FK `Restrict`: um
      `RawContent` com evento de etapa associado não pode ser hard-deletado; a faceta
      "nenhum evento novo é gravado na remoção" é da TASK-010-003) — verificação
      executável: `npm --prefix mnemonicos-backend run test:integration --
      production-events.model` → suíte verde, incluindo o caso que tenta
      `testPrisma.rawContent.delete({ where: { id } })` sobre um `RawContent` com
      `ProductionStageEvent` associado (inserido direto via `testPrisma`) e espera a
      exceção `Prisma.PrismaClientKnownRequestError` com `code === 'P2039'` (SQLSTATE
      `23001` restrict_violation — FK `Restrict` no Postgres é não-adiável, distinto de
      `23503` que o adapter-pg mapeia para `P2003`; achado na implementação, confirmado
      independentemente pelo gate 1-7 via sonda `pg` própria) e o `RawContent` sobrevive
      (`findUniqueOrThrow` resolve) — o mesmo mecanismo de baseline verde real já
      confirmado na Entrega de PLAN-006
      (INDEX: "backend integração 213/213 (11 suítes)", 2026-09-06) prova que o harness
      (`resetDb`/`closeTestDb`) está operante; a suíte nova soma a essa base sem reduzi-la.
- [ ] Testes cobrem AC-009-008 (parte — faceta de desempate determinístico no nível do
      schema: a coluna `sequence` desempata eventos com `occurredAt` idêntico; a faceta
      comportamental completa — decisão de transição + leitura ordenada — é da
      TASK-010-002) — verificação executável: mesmo comando acima, caso que insere
      3 linhas via `testPrisma.productionStageEvent.create` com o mesmo `occurredAt`
      explícito e confirma `sequence` estritamente crescente na ordem de inserção
      (`findMany({ orderBy: { sequence: 'asc' } })` devolve a mesma ordem de criação).
- [ ] `PRODUCTION_STAGE_TYPES`/`PRODUCTION_EVENT_TRANSITIONS` exportados por
      `src/domain/types.ts` têm exatamente os valores dos 2 enums do `schema.prisma` (item
      sem AC, contrato do próprio par tipo/schema) — verificação executável: `npm
      --prefix mnemonicos-backend test -- domain-types-parity` → suíte verde, incluindo os
      2 blocos novos de autoconsistência (nenhum deles lê
      `mnemonicos-frontend/src/types/domain.ts` nem afirma "nos dois repositórios" — grifado
      pela lição ativa citada no Escopo).
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff — produção e teste, `git
      diff --name-only main...HEAD`)
- [ ] Padrão de commit respeitado
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem
- [ ] Code review aprovado

## Riscos específicos

- Autorização do Diretor para gerar/aplicar a migração é um ato humano fora desta TASK —
  o `/keelson:implement` escala via `AskUserQuestion` antes do 1º passo que gera/aplica.
- Fatia sensível (migração + FK `Restrict` nova): `security-engineer` (gate 8) revisa o
  diff completo desta TASK, não só o model.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-06T02:53:30-03:00
**Data conclusão**: 2026-09-06T11:59:28-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: e378e63 (schema/tipos prep) · de721ef (migração aplicada + correção de testes)
**Jira**: KAN-46
**Implementado por**: developer + Tech Lead (correção de teste de FK pós-descoberta P2039, autorizada pelo achado do gate 1-7)
**Revisado por**: code-reviewer, security-engineer, performance-engineer
**Tentativas**: 2 (1ª rodada: reprovado por format:check; retry: aprovado)
**Cobertura final**: 210/210 unit (19 suítes) · 215/215 integração (12 suítes)
**Arquivos modificados**:
  - mnemonicos-backend/prisma/schema.prisma
  - mnemonicos-backend/prisma/migrations/20260906143159_add_production_stage_event/migration.sql
  - mnemonicos-backend/src/domain/types.ts
  - mnemonicos-backend/tests/unit/domain-types-parity.test.ts
  - mnemonicos-backend/tests/integration/production-events.model.integration.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado — security-engineer, 0 achados
- [x] Comportamento (gate 9): consolidado (DoD, Etapa 4) — SPEC-009 sem FEATs

**Notas**: Bloqueio ambiental (Docker Desktop indisponível nesta sessão) resolvido com
autorização do Diretor para reiniciar o Docker + autorização da migração. Achado real
durante a implementação: FK `onDelete: Restrict` no Postgres levanta SQLSTATE 23001, que
o adapter-pg não mapeia — chega como `P2039`, não `P2003` como o critério original
presumia; corrigido no teste e no critério da TASK, e registrado como lição em
`guidelines/project/lessons.md` (categoria `[Dados/Persistência]`) + gotcha em
`guidelines/project/backend/node-22.md` §11. Rede de paridade de tipos estendida para
fechar uma tautologia apontada pelo gate 1-7 (comparava só consigo mesma; agora lê
`schema.prisma` de verdade).
