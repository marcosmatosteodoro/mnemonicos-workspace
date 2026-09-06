# PLAN-010: Instrumentação de etapas da fábrica

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.2
**Autor**: keelson (scribe)
**Data**: 2026-09-06

## Aderência a guidelines

**Ficha/perfil de linguagem**: backend (`guidelines/project/backend/node-22.md`) — sem
componente frontend nesta fatia (mecanismo sem rota, sem tela; A-009-004/A-009-005).
**Stack vigente herdado**: Node 22 · TypeScript 6 · Prisma 7 (model + 2 enums novos,
migração aditiva) · Jest 30 (extensão de suíte de integração existente). Nenhuma
dependência nova.
**Padrão arquitetural seguido**: módulo por domínio (`src/modules/<x>/`) com client Prisma
injetável (`Pick<typeof prisma, ...>`, mesmo padrão de `RawContentClient` em
`contents.service.ts`) e lógica pura recebendo `now: Date` por parâmetro (precedente
`scheduler.ts:43-46`, hoje não seguido em `contents.service.ts` — esta fatia o introduz ali
também, dentro da própria transação). Transação interativa `$transaction(async (tx) =>
{...})` reusa o único precedente do repo (`auth.service.ts:154-175`).
**Decisões irreversíveis do slug tocadas**: nenhuma (INDEX do slug declara nenhuma DEC
irreversível até aqui; as 6 DECs deste PLAN nascem reversíveis — §6).
**Decisões irreversíveis de outros slugs em conflito**: nenhuma — não existe outro slug
neste workspace além de `producao-material`.
**Exceções aos guidelines**: nenhuma. O módulo novo (`production-events/`) nasce **sem**
`.schema.ts` nem `.routes.ts` — não é desvio do padrão `schema → service → routes`, é a
ausência correta da camada HTTP para um mecanismo que a própria SPEC proíbe de expor
(FR-009-010, A-009-004): sem rota, não há fronteira de validação de entrada externa a
proteger com Zod.

## Cobertura

**SPEC referenciada**: SPEC-009
**Slice declarado**: cobertura total (Caso D — nenhum PLAN anterior cobre SPEC-009, que é
nova)

**FRs cobertos**:
- FR-009-001
- FR-009-002
- FR-009-003
- FR-009-004
- FR-009-005
- FR-009-006
- FR-009-007
- FR-009-008
- FR-009-009
- FR-009-010

**NFRs cobertos**:
- NFR-009-001
- NFR-009-002
- NFR-009-003
- NFR-009-004
- NFR-009-005

**Cobertura agregada do slug**:
- Total na SPEC: 10 FRs + 5 NFRs
- Cobertos por planos anteriores: 0 (SPEC-009 é nova; nenhum PLAN a cobria antes)
- Cobertos por este: 10 FRs + 5 NFRs (100%)
- Gap restante: 0

## 1. Visão técnica

Esta fatia introduz um **mecanismo genérico de evento de etapa de produção**,
append-only e imutável, chamado de dentro de `contents.service.ts` como efeito colateral
das mutações já existentes (criação/edição de Conteúdo bruto, salvamento da Quebra da
regra) — sem rota, sem tela, sem gatilho novo do usuário (A-009-004/A-009-005).

O insight que resolve a extensibilidade exigida por NFR-009-001 sem precisar de
conhecimento específico de cada etapa em cada ponto de chamada é uma **regra de decisão
única e genérica**, aplicada sempre da mesma forma para qualquer par
(`rawContentId`, `stageType`): olhando só os eventos **já registrados** daquele par dentro
da mesma transação —

- nenhum evento registrado ainda → **abertura**;
- já existe abertura mas nenhuma conclusão → **conclusão**;
- já existe conclusão → **retrabalho** (para sempre, a partir daí).

Essa regra única cobre as 5 emissões da SPEC sem nenhuma ramificação por etapa no
chamador:

- `createRawContent` chama a emissão **duas vezes** para `CONTEUDO_BRUTO` (a 1ª vê 0
  eventos → abertura; a 2ª, chamada em seguida na mesma transação, já vê a abertura →
  conclusão) e **uma vez** para `QUEBRA_DA_REGRA` (0 eventos → abertura) — 3 emissões,
  como o desenho da SPEC exige (FR-009-001/FR-009-002).
- `updateRawContent` chama a emissão **uma vez** para `CONTEUDO_BRUTO`: como a criação já
  gravou abertura+conclusão, a regra decide retrabalho sempre, sem o chamador precisar
  saber disso (FR-009-004, consistente com A-009-008 — "conclusão" de Conteúdo bruto
  coincide com a criação).
- `saveRuleBreakdown` chama a emissão **uma vez** para `QUEBRA_DA_REGRA`: a 1ª chamada vê
  só a abertura (gravada na criação do pai) → conclusão (FR-009-003); as chamadas
  seguintes já veem a conclusão → retrabalho (FR-009-005).
- `softDeleteRawContent` **não muda** — nenhuma chamada de emissão nova (FR-009-009); os
  eventos já emitidos sobrevivem por FK `Restrict` (FR-009-008).

Atomicidade (NFR-009-002/AC-009-010) vem de rodar a mutação de negócio e as emissões
**na mesma transação interativa do Prisma** (`$transaction(async (tx) => {...})`): uma
falha em qualquer emissão propaga a exceção para fora do callback e o Prisma reverte a
transação inteira — nenhum caminho novo de `try/catch` é necessário, o fail-secure vem do
próprio mecanismo de transação (Charter Art. 2, perfil §5).

Sem UI, sem rota e sem contrato de API novo (A-009-004/A-009-005), o espelho cross-repo de
tipos desta fatia fica **só do lado do backend** — decisão registrada em DEC-010-006.

## 2. Stack e dependências

- **Prisma 7**: 2 enums novos (`ProductionStageType`, `ProductionEventTransition`) + 1
  model novo (`ProductionStageEvent`) — migração aditiva (autorização do Diretor exigida
  antes de gerar/aplicar, protocolo do CLAUDE.md do workspace).
- **Jest 30 + ts-jest**: extensão de `tests/integration/contents.integration.test.ts`
  e/ou `tests/integration/contents.service.integration.test.ts` (harness existente,
  `resetDb()` — tabela nova entra sozinha na truncagem via `pg_tables`) + extensão de
  `tests/unit/domain-types-parity.test.ts`.
- Nenhuma dependência nova de `package.json` nos dois repos.
- Sem componente frontend: `mnemonicos-frontend/` não é tocado por este PLAN.

## 3. Componentes

### COMP-010-001: Modelagem de dados — evento de etapa de produção
**Responsabilidade**: model Prisma `ProductionStageEvent` (append-only, sem `updatedAt`
nem `deletedAt` — a imutabilidade é a ausência de caminho de update/delete no service,
não um campo de estado aqui) + enums `ProductionStageType` e `ProductionEventTransition`
+ migração aditiva (`prisma/migrations/`).
**Realiza**: FR-009-006, FR-009-007, FR-009-008, NFR-009-001, NFR-009-003, NFR-009-004
**Interface pública**: model `ProductionStageEvent` (campos `id`, `rawContentId`,
`stageType`, `transitionType`, `actorId`, `occurredAt`, `sequence`) via Prisma Client
gerado (`src/generated/prisma/client`); nenhuma rota HTTP, nenhum schema Zod.
**Dependências**: nenhuma

### COMP-010-002: `production-events.service.ts` — mecanismo de emissão e leitura
**Responsabilidade**: expõe a regra de decisão pura (abertura/conclusão/retrabalho a
partir do histórico de transições já registradas), a função de emissão transacional
(recebe o `tx` da transação do chamador, decide e grava 1 linha) e a função de leitura
interna ordenada por `sequence`. Módulo **sem** `.schema.ts` nem `.routes.ts` — nunca
chamado a partir de uma rota, só de outro `.service.ts` (DEC-010-004).
**Realiza**: FR-009-006, FR-009-007, FR-009-010, NFR-009-001, NFR-009-004
**Interface pública**:
```ts
// production-events.service.ts
export function decideStageTransition(
  existingTransitions: readonly ProductionEventTransition[],
): ProductionEventTransition;
// pura, sem I/O — separável e testável (DEC-010-005)

export interface ProductionStageEventInput {
  rawContentId: string;
  stageType: ProductionStageType;
  actorId: string;
  now: Date;
}

export async function recordProductionStageEvent(
  tx: Pick<typeof prisma, 'productionStageEvent'>,
  input: ProductionStageEventInput,
): Promise<void>;
// lê os eventos existentes de (rawContentId, stageType) DENTRO da mesma tx,
// decide via decideStageTransition e grava 1 linha (occurredAt = now injetado)

export interface ProductionStageEventRecord {
  id: string;
  rawContentId: string;
  stageType: ProductionStageType;
  transitionType: ProductionEventTransition;
  actorId: string;
  occurredAt: Date;
}

export async function listProductionStageEvents(
  rawContentId: string,
  db?: Pick<typeof prisma, 'productionStageEvent'>,
): Promise<ProductionStageEventRecord[]>;
// orderBy: sequence asc — leitura interna pura, sem cálculo/soma/duração (FR-009-010)
```
**Dependências**: COMP-010-001

### COMP-010-003: Integração transacional em `contents.service.ts`
**Responsabilidade**: envolve `createRawContent`, `updateRawContent` e
`saveRuleBreakdown` numa transação interativa (`prisma.$transaction(async (tx) => {...})`)
que executa a mutação de negócio e chama `recordProductionStageEvent` (COMP-010-002) nos
pontos exigidos por cada fluxo (§4). `softDeleteRawContent` permanece **inalterado** —
nenhuma chamada de emissão (FR-009-009).
**Realiza**: FR-009-001, FR-009-002, FR-009-003, FR-009-004, FR-009-005, FR-009-009, NFR-009-002, NFR-009-005
**Interface pública**: as assinaturas de `createRawContent(input, actorId, db?)`,
`updateRawContent(id, input, actor, db?)` e `saveRuleBreakdown(rawContentId, input,
actor, db?)` **não mudam** (parâmetros e tipo de retorno idênticos aos de F2) — nenhuma
resposta HTTP, rota ou contrato de `contents.routes.ts` é tocado (NFR-009-005/AC-009-009).
Muda só o tipo interno do parâmetro `db` (de `Pick<typeof prisma, 'rawContent'>` para
incluir `'$transaction'`), invisível a quem chama com o default `prisma`.
**Dependências**: COMP-010-002, COMP-010-001

### COMP-010-004: Espelho cross-repo backend (`src/domain/types.ts`)
**Responsabilidade**: `PRODUCTION_STAGE_TYPES`/`PRODUCTION_EVENT_TRANSITIONS` como
`as const` arrays + tipos derivados, espelhando os 2 enums Prisma de COMP-010-001 — **só
no backend** (DEC-010-006: sem espelho em `mnemonicos-frontend/src/types/domain.ts` nesta
fatia).
**Realiza**: NFR-009-001
**Interface pública**: `PRODUCTION_STAGE_TYPES: readonly string[]`, `type
ProductionStageType`; `PRODUCTION_EVENT_TRANSITIONS: readonly string[]`, `type
ProductionEventTransition`.
**Dependências**: COMP-010-001

### COMP-010-005: Rede de paridade — extensão de `domain-types-parity.test.ts`
**Responsabilidade**: adiciona blocos `it()` para os 2 enums novos. Como o espelho no
frontend foi adiado (DEC-010-006), estes blocos **não** são comparação cross-repo (não há
`PRODUCTION_STAGE_TYPES`/`PRODUCTION_EVENT_TRANSITIONS` do lado do frontend ainda) — são
autoconsistência backend-only: provam que `PRODUCTION_STAGE_TYPES`/
`PRODUCTION_EVENT_TRANSITIONS` exportados batem com o conjunto de valores esperado lido
como texto do próprio `src/domain/types.ts`, mesmo mecanismo de extração
(`extractConstArray`) já usado para os outros 3 enums, sem o segundo lado da comparação.
Comentário no teste aponta a condição de upgrade: quando o frontend espelhar (F10), os
blocos passam a comparar as duas fontes, como os enums de F2 já fazem.
**Realiza**: NFR-009-001 (suporte à rede de tipos)
**Interface pública**: n/a (arquivo de teste)
**Dependências**: COMP-010-004

### COMP-010-006: Suíte de teste dos 5 gatilhos + fail-secure
**Responsabilidade**: extensão de `contents.integration.test.ts` (faceta HTTP) e/ou
`contents.service.integration.test.ts` (faceta de regra pura) cobrindo os 5 gatilhos de
emissão (criação, edição de Conteúdo bruto; 1º salvamento e salvamentos subsequentes da
Quebra da regra; soft-delete sem emissão nova) como condição de pronto (RISK-009-002/
TRISK-010-003) — mais o teste de fail-secure (AC-009-010): forçar a emissão a lançar
dentro da transação (mock/spy sobre `recordProductionStageEvent` ou sobre o client de
evento) e provar que a mutação de negócio (criação/edição/salvamento) **também** não
persiste.
**Realiza**: FR-009-001, FR-009-002, FR-009-003, FR-009-004, FR-009-005, FR-009-009, FR-009-010, NFR-009-002, NFR-009-005
**Interface pública**: n/a (arquivo de teste)
**Dependências**: COMP-010-003

## 4. Fluxos principais

**Criação de Conteúdo bruto** (`createRawContent`, FR-009-001/FR-009-002) — dentro de
`prisma.$transaction(async (tx) => {...})`:
1. `tx.rawContent.create({...})` — grava o Conteúdo bruto (mesmos campos de F2).
2. `recordProductionStageEvent(tx, { rawContentId, stageType: 'CONTEUDO_BRUTO', actorId,
   now })` — 0 eventos existentes para esse par → decide **abertura**.
3. `recordProductionStageEvent(tx, { rawContentId, stageType: 'CONTEUDO_BRUTO', actorId,
   now })` — já existe a abertura do passo 2 → decide **conclusão**.
4. `recordProductionStageEvent(tx, { rawContentId, stageType: 'QUEBRA_DA_REGRA', actorId,
   now })` — 0 eventos para esse par → decide **abertura**.
`now = new Date()` computado uma única vez no início do callback (mesmo instante para as
3 emissões — `sequence` desempata a ordem, AC-009-008).

**Edição de Conteúdo bruto já existente** (`updateRawContent`, FR-009-004) — dentro da
transação:
1. `tx.rawContent.updateMany({...})` — guarda + escrita, mesmo predicado de alcance de F2.
2. `recordProductionStageEvent(tx, { rawContentId: id, stageType: 'CONTEUDO_BRUTO',
   actorId: actor.id, now })` — já existem abertura+conclusão (gravadas na criação) →
   decide **retrabalho**, sempre (A-009-008: a conclusão de Conteúdo bruto já ocorreu na
   criação, nunca se repete).

**Salvamento da Quebra da regra** (`saveRuleBreakdown`, FR-009-003/FR-009-005) — dentro
da transação:
1. `assertRawContentReachable` (guarda existente de F2, inalterada).
2. `tx.ruleBreakdown.upsert({...})` — mesmo upsert 1:1 de F2.
3. `recordProductionStageEvent(tx, { rawContentId, stageType: 'QUEBRA_DA_REGRA', actorId:
   actor.id, now })` — decide **conclusão** na 1ª chamada (só existe a abertura gravada na
   criação do pai) e **retrabalho** nas chamadas seguintes (já existe conclusão).

**Soft-delete de Conteúdo bruto** (`softDeleteRawContent`, FR-009-009) — **sem mudança**:
continua um único `updateMany` fora de qualquer transação nova, sem chamar
`recordProductionStageEvent`. Os eventos já emitidos permanecem por FK `Restrict` em
`ProductionStageEvent.rawContentId` — nunca apagados, nunca invalidados (FR-009-008).

**Leitura interna** (`listProductionStageEvents`, FR-009-010/AC-009-008/AC-009-006) — fora
de transação, client default `prisma`: `findMany({ where: { rawContentId }, orderBy: {
sequence: 'asc' } })`, sem `include`/agregação — devolve a lista determinística, na ordem
de emissão real, mesmo com `occurredAt` empatado.

## 5. Modelo de dados

```prisma
enum ProductionStageType {
  CONTEUDO_BRUTO
  QUEBRA_DA_REGRA
  // Fatias futuras (F4 tira, F5 biblioteca visual, F6 publicação, F8
  // versionamento, F9 QC) acrescentam valores aqui — migração aditiva, sem
  // redesenho do mecanismo (NFR-009-001, DEC-010-001).
}

enum ProductionEventTransition {
  ABERTURA
  CONCLUSAO
  RETRABALHO
}

/// Evento append-only e imutável de transição de etapa de produção (SPEC-009).
/// Nenhum caminho do código atualiza ou apaga uma linha desta tabela
/// (FR-009-007) — a garantia é a AUSÊNCIA de método de update/delete em
/// production-events.service.ts, não um campo de estado aqui (por isso não há
/// `updatedAt` nem `deletedAt`).
model ProductionStageEvent {
  id String @id @default(uuid(7))

  rawContentId String
  /// Restrict: mesmo padrão de `RawContent.authorId`/`RawContentAuthor` — um
  /// RawContent com eventos não pode ser hard-deletado; hoje só existe
  /// soft-delete (`RawContent.deletedAt`), e o evento sobrevive a ele
  /// (FR-009-008, NFR-009-003).
  rawContent   RawContent @relation(fields: [rawContentId], references: [id], onDelete: Restrict)

  stageType      ProductionStageType
  transitionType ProductionEventTransition

  actorId String
  /// Restrict: mesmo padrão de `RawContent.authorId` — o autor da mutação que
  /// originou o evento não pode ser hard-deletado enquanto o evento existir.
  actor   User   @relation(fields: [actorId], references: [id], onDelete: Restrict)

  occurredAt DateTime @default(now())

  /// Desempate determinístico para eventos registrados no mesmo instante
  /// (AC-009-008 — a criação de Conteúdo bruto sempre produz 3 emissões com o
  /// mesmo `now` injetado). Território greenfield: nenhum outro model do
  /// projeto tem sequência monotônica hoje (DEC-010-002).
  sequence BigInt @default(autoincrement())

  /// Cobre a leitura ordenada de FR-009-010/AC-009-008 (`findMany` por
  /// `rawContentId`, `orderBy: sequence asc`) — mesmo padrão de prova de
  /// índice por EXPLAIN já usado em `RawContent` (schema.prisma:295-307).
  @@index([rawContentId, sequence])
  @@map("production_stage_events")
}
```

**Alterações aditivas nos models existentes** (relação inversa, obrigatória no Prisma):
- `RawContent` ganha `productionStageEvents ProductionStageEvent[]`.
- `User` ganha `productionStageEvents ProductionStageEvent[]` (sem `@relation` nomeada —
  única relação deste tipo entre os dois models, ao contrário de
  `RawContentAuthor`/`RawContentLastEditor`, que precisam de nome por haver duas).

Migração: 1 arquivo aditivo (`CREATE TYPE` × 2 enums + `CREATE TABLE` + `CREATE INDEX` +
`ALTER TABLE ... ADD CONSTRAINT` para as 2 FKs) — nenhum `DROP`/`ALTER` sobre tabela
existente. Autorização do Diretor exigida antes de gerar/aplicar (protocolo do CLAUDE.md
do workspace, mesma régua de PLAN-006).

## 6. Decisões arquiteturais

### DEC-010-001: Enum Prisma fixo para tipo de etapa e tipo de transição
**Contexto**: NFR-009-001 exige que o mecanismo comporte tipos de etapa futuros (F4-F9)
sem alteração estrutural dedicada. Enum Prisma fixo parece colidir com essa exigência à
primeira vista (adicionar um valor exige migração), mas nenhum precedente do projeto
resolve o caso — é escolha deste PLAN (código-scout confirmou: `UserRole`,
`ProofRadarClass`, `NormativeSourceType` são todos `enum` Prisma fixo, migrados em pasta
própria).
**Decisão**: enum Prisma fixo (`ProductionStageType`, `ProductionEventTransition`),
consistente com os 3 enums de domínio já existentes.
**Alternativas consideradas**:
- `String` validada em Zod (sem migração para acrescentar etapa nova), descartada porque
  perde a integridade referencial do banco — um typo no valor de `stageType` só seria
  pego em runtime da aplicação, nunca em tempo de escrita — e quebra o padrão de paridade
  cross-repo já estabelecido (`domain-types-parity.test.ts`), que o projeto usa para todo
  enum de domínio; teria que virar um caso especial só para esta tabela.
**Consequências**: fatia futura que adiciona etapa nova (F4-F9) precisa de uma migração
aditiva pequena (`ALTER TYPE ... ADD VALUE`) — custo que NFR-009-001 já permite
explicitamente ("sem alteração ESTRUTURAL dedicada" ≠ "sem nenhuma migração").
**Reabrir se**: o ritmo de fatias futuras (F4-F9) se mostrar tão rápido que a migração
aditiva por fatia vira gargalo perceptível de ciclo.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (mesmo padrão dos 3 enums de F1/F2)

### DEC-010-002: Coluna `sequence` (BigInt autoincrement) para desempate determinístico
**Contexto**: AC-009-008 exige ordem determinística e estável mesmo quando dois ou mais
eventos são registrados no mesmo instante — caso que a própria criação de Conteúdo bruto
sempre produz (3 emissões com o mesmo `now: Date` injetado, computado uma única vez no
início da transação). Código-scout confirmou: nenhum model do projeto tem sequência
monotônica hoje — território greenfield.
**Decisão**: coluna `sequence BigInt @default(autoincrement())`, com `@@index([rawContentId,
sequence])` para a leitura ordenada.
**Alternativas consideradas**:
- Timestamp de maior precisão (`occurredAt` com microssegundos), descartada porque não
  resolve o problema real: o `occurredAt` de cada emissão vem do mesmo `now: Date`
  aplicacional passado explicitamente às 3 chamadas dentro da mesma transação (não de
  `now()` do Postgres) — aumentar a precisão da coluna não desempata valores que já
  nasceram idênticos por desenho.
- Contador incremental mantido em memória da aplicação, descartada porque não sobrevive a
  múltiplas instâncias do processo (o deploy tem `api/index.ts` serverless — cada
  instância reciclada perde o contador) e exigiria sincronização externa só para repetir
  o que o banco já oferece de graça via `autoincrement()`.
**Consequências**: toda leitura ordenada usa `orderBy: { sequence: 'asc' }`, nunca
`occurredAt`.
**Reabrir se**: nunca — a coluna é o mecanismo mais barato disponível (nenhuma
sincronização externa, nenhuma dependência de precisão de relógio) e o custo (1 coluna +
1 índice) é marginal frente ao volume da tabela.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova (primeira sequência monotônica do projeto)

### DEC-010-003: Emissão do evento na MESMA transação Prisma da mutação de negócio
**Contexto**: NFR-009-002/AC-009-010 exigem atomicidade entre o registro do evento e a
mutação de negócio que o origina — falha em um dos dois não pode deixar o outro
persistido. A SPEC (A-009-010) já decide o *requisito*; este PLAN decide o *mecanismo*.
**Decisão**: introduzir `prisma.$transaction(async (tx) => {...})` em `createRawContent`,
`updateRawContent` e `saveRuleBreakdown` (hoje sem transação — código-scout confirmou),
reusando o único precedente de transação-callback do repo (`auth.service.ts:154-175`).
**Alternativas consideradas**:
- Melhor esforço / *fire-and-forget* fora da transação (log de erro se a emissão falhar),
  descartada porque é exatamente o "sucesso parcial" que AC-009-010 proíbe — um evento
  perdido silenciosamente enquanto a mutação principal segue com sucesso viola o
  requisito, não só uma imperfeição de implementação.
- Padrão *outbox* (grava uma intenção de evento numa tabela separada, processa depois por
  um worker assíncrono), descartada porque introduz um processo novo (infraestrutura fora
  do escopo desta fatia — sem fila/worker no projeto hoje), atraso entre escrita e
  consistência, e complexidade operacional desproporcional ao volume de 2 estações
  quando a transação interativa já resolve com o padrão que o projeto já usa.
**Consequências**: as 3 funções mudam de "1 statement" para "transação interativa com
2-4 statements" — janela de conexão presa no pool um pouco mais longa (mitigado em
TRISK-010-001); nenhuma chamada de I/O externo entra dentro da transação (perfil §10:
"nunca faça HTTP de saída dentro dela").
**Reabrir se**: o custo de sempre exigir a mesma transação se mostrar caro na
implementação (medição real, não palpite — Charter Art. 8).
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (padrão de transação já em uso em `auth.service.ts`)

### DEC-010-004: Módulo `production-events/` dedicado, sem `.schema.ts` nem `.routes.ts`
**Contexto**: FR-009-010 proíbe expor rota/endpoint para o mecanismo nesta fatia; A-009-004
reforça que não há tela de consumo. O mecanismo precisa, ainda assim, servir fatias
futuras (F4-F9) sem redesenho (NFR-009-001).
**Decisão**: módulo novo `src/modules/production-events/production-events.service.ts` —
só a camada de serviço, chamado exclusivamente por outros `.service.ts` (hoje só
`contents.service.ts`).
**Alternativas consideradas**:
- Embutir as funções diretamente em `contents.service.ts` (sem módulo novo), descartada
  porque acopla o mecanismo — que precisa servir F4 (tira), F5 (biblioteca visual), F6
  (publicação), F8 (versionamento) e F9 (QC) amanhã — ao módulo específico de Conteúdo
  bruto/Quebra da regra: quando F4 precisar emitir seu primeiro evento de etapa, teria que
  importar de dentro do módulo de outro domínio, um acoplamento invertido que
  contradiz exatamente a extensibilidade que NFR-009-001 exige.
**Consequências**: um módulo a mais na árvore, sem HTTP — não aparece em nenhuma rota
montada, então nenhum teste de conformidade de rota (`route-authz-matrix`) precisa
conhecê-lo.
**Reabrir se**: uma fatia futura precisar expor consulta via HTTP (decisão de produto que
muda o escopo do mecanismo, não escolha unilateral deste PLAN).
**Irreversível**: nao
**Aderência à ficha/perfil**: nova (primeiro módulo do projeto sem schema/routes)

### DEC-010-005: Decisão da transição resolvida internamente pelo histórico, não passada pelo chamador
**Contexto**: cada um dos 3 fluxos de `contents.service.ts` precisa emitir o tipo certo de
transição (abertura/conclusão/retrabalho) sem duplicar, em cada ponto de chamada, o
conhecimento de "isto é a 1ª vez ou a enésima" para aquela etapa daquele conteúdo.
**Decisão**: `recordProductionStageEvent` decide internamente, consultando
`tx.productionStageEvent.findMany({ where: { rawContentId, stageType } })` dentro da
própria transação e aplicando a regra pura `decideStageTransition` (§1) sobre o histórico
lido.
**Alternativas consideradas**:
- Chamador passa `transitionType` explícito (ex.: `updateRawContent` sempre passa
  `'RETRABALHO'` a dedo), descartada porque exige que cada ponto de chamada, presente e
  futuro (F4-F9), replique a regra de negócio "quando é abertura, quando é conclusão,
  quando é retrabalho" — exatamente o conhecimento que este mecanismo deveria
  centralizar; drift entre pontos de chamada (um esquecer de tratar reabertura como
  retrabalho) vira bug silencioso sem nenhum teste genérico capaz de pegá-lo.
**Consequências**: 1 `SELECT` a mais por emissão (filtrado por `rawContentId, stageType`,
coberto pelo índice de COMP-010-001) — custo aceito, mensurável e barato frente ao ganho de
centralizar a regra.
**Reabrir se**: o custo do `SELECT` extra por emissão se mostrar caro em volume alto
(medição real via `EXPLAIN`/contagem de round-trips, Charter Art. 8 — não antes disso).
**Irreversível**: nao
**Aderência à ficha/perfil**: nova (regra de decisão pura, testável isoladamente — mesmo
espírito de `scheduler.ts`)

### DEC-010-006: Espelho cross-repo do enum adiado — sem mirror em `mnemonicos-frontend` nesta fatia
**Contexto**: o padrão do projeto (F2) é espelhar todo enum de domínio em
`mnemonicos-frontend/src/types/domain.ts` no mesmo diff do backend. Esta fatia não tem
nenhuma tela nem contrato de API que consuma os 2 enums novos (P-04/P-05 do brief,
FR-009-010 sem rota).
**Decisão**: espelhar só no backend (COMP-010-004); **não** criar
`PRODUCTION_STAGE_TYPES`/`PRODUCTION_EVENT_TRANSITIONS` em
`mnemonicos-frontend/src/types/domain.ts` nesta fatia — registrado explicitamente em §10
para não ser lido como esquecimento.
**Alternativas consideradas**:
- Espelhar já no frontend, mesmo sem consumidor, descartada por YAGNI: sem tela nem rota
  que o exija, o par ficaria como código morto que pode divergir silenciosamente do
  backend até o dia em que ganhar consumidor real — sem nenhum teste rodando contra ele
  hoje (o próprio `domain-types-parity.test.ts` só compara o que os dois lados já
  declaram; um par sem uso não tem pressão de manutenção).
**Consequências**: a rede de paridade cross-repo (COMP-010-005) nasce só backend
(autoconsistência, não comparação) até o dia em que o espelho frontend existir.
**Reabrir se**: F10 (painel) precisar consumir os tipos no frontend — nesse momento o
espelho entra no mesmo diff que introduzir o consumidor, e os blocos de teste de
COMP-010-005 sobem para comparação cross-repo real.
**Irreversível**: nao
**Aderência à ficha/perfil**: exceção documentada (o padrão de F2 era espelhar sempre;
aqui a ausência de consumidor muda o cálculo — YAGNI do Charter Art. 3)

## 7. Mapeamento FR -> componente

| FR | Componente | AC cobertos |
|----|------------|-------------|
| FR-009-001 | COMP-010-003, COMP-010-006 | AC-009-001 |
| FR-009-002 | COMP-010-003, COMP-010-006 | AC-009-002 |
| FR-009-003 | COMP-010-003, COMP-010-006 | AC-009-003 |
| FR-009-004 | COMP-010-003, COMP-010-006 | AC-009-004 |
| FR-009-005 | COMP-010-003, COMP-010-006 | AC-009-005 |
| FR-009-006 | COMP-010-001, COMP-010-002 | AC-009-006 |
| FR-009-007 | COMP-010-001, COMP-010-002 | AC-009-006 |
| FR-009-008 | COMP-010-001 | AC-009-007 |
| FR-009-009 | COMP-010-003, COMP-010-006 | AC-009-007 |
| FR-009-010 | COMP-010-002, COMP-010-006 | AC-009-008 |
| NFR-009-001 | COMP-010-001, COMP-010-002, COMP-010-004, COMP-010-005 | — |
| NFR-009-002 | COMP-010-003, COMP-010-006 | AC-009-010 |
| NFR-009-003 | COMP-010-001 | AC-009-006, AC-009-007 |
| NFR-009-004 | COMP-010-001, COMP-010-002 | — |
| NFR-009-005 | COMP-010-003, COMP-010-006 | AC-009-009 |

## 8. Riscos técnicos

- **TRISK-010-001** A transação interativa introduzida em `createRawContent`/
  `updateRawContent`/`saveRuleBreakdown` mantém uma conexão do pool presa por mais tempo
  que o statement único de F2 (perfil §10: "transação interativa mantém conexão presa —
  mantenha-a curta") (mitigação: nenhuma chamada de I/O externo dentro do callback; só
  Prisma sobre o mesmo `tx`; medir round-trips se o volume real justificar).
- **TRISK-010-002** A leitura interna (`listProductionStageEvents`) não pagina — FR-009-010
  proíbe agregação/cálculo, mas também não previu paginação; um conteúdo com muitíssimos
  retrabalhos leria todos os eventos de uma vez (mitigação: aceito nesta fatia — sem
  consumo real ainda; F10 decide se precisa paginar quando existir consumidor).
- **TRISK-010-003** (herdado de RISK-009-002) Sem painel nem consumo nesta fatia, um
  evento não emitido ou emitido com o tipo errado passaria despercebido até F10 expor os
  dados (mitigação: cobertura de teste dos 5 gatilhos + fail-secure é condição de pronto
  desta fatia — COMP-010-006, não opcional).
- **TRISK-010-004** A rede de paridade cross-repo (COMP-010-005) nasce autoconsistente
  (backend-only), não comparativa, por causa do adiamento do espelho frontend
  (DEC-010-006) — risco de a rede "esfriar" (não pegar drift real com o frontend) até o
  dia em que o espelho existir (mitigação: comentário explícito no teste apontando a
  condição de upgrade; DEC-010-006 registra o gatilho).

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Aderência à ficha/perfil validada
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates)
- [ ] Métrica da SPEC operacional (SPEC-009 §1.3 declara `Fonte de medição`):
  (a) externa — suíte de teste (COMP-010-006) prova os 5 gatilhos + tripwire de
  append-only (nenhum caminho de update/delete sobre evento já emitido), natureza
  conformidade, dono: time de engenharia; instrumentação entregue e provada (gate 9
  exibe o evento existindo); (b) observacional — nº de eventos emitidos vs. nº de
  Conteúdos brutos/Quebras produzidos pela tela na janela, com a razão esperada (3 eventos
  por criação de Conteúdo bruto, +1 por 1º salvamento de Quebra) apurada por inspeção
  humana no relatório de Entrega, dono e veredito registrados no INDEX (mesma natureza do
  item (b) de SPEC-005/§1.3).

## 10. Não coberto por este PLAN

- Painel/dashboard de produção e cálculo de "tempo de produção por página" — F10 (falta o
  denominador "página", que só F6 define).
- Qualquer tela ou rota HTTP de leitura/consulta dos eventos para EDITOR/ADMIN — o
  mecanismo escreve; não expõe superfície de consulta nesta fatia.
- **Espelho de `PRODUCTION_STAGE_TYPES`/`PRODUCTION_EVENT_TRANSITIONS` em
  `mnemonicos-frontend/src/types/domain.ts`** — adiado por decisão explícita (DEC-010-006,
  YAGNI): sem tela nem contrato de API que o exija nesta fatia. Registrado aqui para não
  ser lido como esquecimento; entra no mesmo diff que o primeiro consumidor real (F10).
- Instrumentação das etapas de revisão jurídica e exportação (F8/F9/F6) e das fatias de
  conteúdo ainda não construídas (tira — F4, biblioteca visual — F5, publicação — F6,
  versionamento — F8, QC — F9) — o mecanismo comporta os tipos futuros
  (`ProductionStageType` aditivo), mas nenhuma emissão para essas etapas nasce nesta fatia:
  as telas que as produziriam não existem hoje.
- Emissão de evento pela semente/importação em lote de conteúdo (`seed-material.ts`) —
  grava direto via Prisma, fora do service instrumentado (A-009-011); gap declarado na
  SPEC, não corrigido por este PLAN.
- Trilha do que mudou em cada edição (diff de campos, histórico de versão do texto) — F8
  (versionamento editorial); o payload do evento é mínimo por desenho (A-009-007/
  NFR-009-004).
- Paginação da leitura interna de eventos (`listProductionStageEvents`) — TRISK-010-002,
  fica para quando F10 precisar de um consumidor real.
