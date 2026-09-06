# TASK-010-002: Mecanismo de emissão e leitura de eventos de etapa (`production-events.service.ts`)

**Slug**: producao-material
**Pertence a**: PLAN-010
**Realiza (FRs)**: FR-009-006, FR-009-007, FR-009-010
**Componente**: COMP-010-002 (principal)
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico, estratégia `unica`)
**Padrão de commit**: Conventional Commits (`feat:`)
**Framework de teste**: Jest 30 + ts-jest (unit: `npm --prefix mnemonicos-backend test`; integração: `npm --prefix mnemonicos-backend run test:integration`)

## Dependências

- **Depende de**: TASK-010-001
- **Bloqueia**: TASK-010-003

## Contexto

Módulo novo `src/modules/production-events/`, **sem** `.schema.ts` nem `.routes.ts`
(DEC-010-004) — só camada de serviço, chamado exclusivamente por outro `.service.ts` (hoje
só `contents.service.ts`, na TASK-010-003). Centraliza a regra de decisão
abertura/conclusão/retrabalho (DEC-010-005) para que nenhum ponto de chamada precise
replicar esse conhecimento. `decideStageTransition` é pura e separável — testável sem I/O,
mesmo espírito de `scheduler.ts` (linhas 43-46, padrão "lógica pura recebendo `now`/estado
por parâmetro"). Esta TASK prova o mecanismo inteiro (regra, emissão transacional, leitura
ordenada) sozinha, simulando a sequência de chamadas que `contents.service.ts` fará na
TASK-010-003 — sem esperar por ela (vertical slicing).

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/production-events/production-events.service.ts` (novo):
  - `decideStageTransition(existingTransitions: readonly ProductionEventTransition[]):
    ProductionEventTransition` — pura, sem I/O: 0 eventos → `ABERTURA`; existe `ABERTURA`
    mas nenhuma `CONCLUSAO` → `CONCLUSAO`; existe `CONCLUSAO` → `RETRABALHO` (para sempre a
    partir daí, independente da ordem em que os tipos aparecem na lista de entrada).
  - `interface ProductionStageEventInput { rawContentId: string; stageType:
    ProductionStageType; actorId: string; now: Date }`.
  - `recordProductionStageEvent(tx: Pick<typeof prisma, 'productionStageEvent'>, input:
    ProductionStageEventInput): Promise<void>` — lê os eventos existentes de
    `(rawContentId, stageType)` **dentro** do `tx` recebido (nunca abre transação própria —
    quem chama já está numa), decide via `decideStageTransition` e grava 1 linha
    (`occurredAt = input.now`, nunca `new Date()`/`now()` do banco).
  - `interface ProductionStageEventRecord { id: string; rawContentId: string; stageType:
    ProductionStageType; transitionType: ProductionEventTransition; actorId: string;
    occurredAt: Date }`.
  - `listProductionStageEvents(rawContentId: string, db?: Pick<typeof prisma,
    'productionStageEvent'> = prisma): Promise<ProductionStageEventRecord[]>` —
    `findMany({ where: { rawContentId }, orderBy: { sequence: 'asc' } })`, sem
    `include`/agregação/cálculo (FR-009-010).
- `mnemonicos-backend/tests/unit/production-events.rule.test.ts` (novo): tabela de casos de
  `decideStageTransition`, sem banco.
- `mnemonicos-backend/tests/integration/production-events.service.integration.test.ts`
  (novo): `recordProductionStageEvent`/`listProductionStageEvents` contra o Postgres real,
  usando o padrão de fixture de `contents.service.integration.test.ts`
  (`createUser`/`createTopic`/`testPrisma` direto).

### Não inclui

- Qualquer chamada a `recordProductionStageEvent` a partir de `contents.service.ts` —
  TASK-010-003 (o módulo nasce sem consumidor real; esta TASK só prova o mecanismo em
  isolamento, orquestrando a mesma sequência de chamadas que o consumidor fará).
- Paginação de `listProductionStageEvents` — TRISK-010-002, fora desta fatia.
- Qualquer rota HTTP, schema Zod ou middleware para este módulo (FR-009-010 proíbe expor
  rota/endpoint nesta fatia).
- FK `Restrict`/coluna `sequence` do model — já entregues por TASK-010-001 (dependência).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Escrever `decideStageTransition` como função pura (switch/if sobre
   `existingTransitions.includes(...)`, nunca sobre posição/índice do array — AC-009-008
   exige indiferença à ordem de leitura).
2. Escrever `recordProductionStageEvent`: 1 `findMany` filtrado por `rawContentId,
   stageType` dentro do `tx`, decide, 1 `create`.
3. Escrever `listProductionStageEvents`: 1 `findMany` ordenado por `sequence asc`, `db`
   injetável com default `prisma` (mesmo padrão de `RawContentClient` em
   `contents.service.ts`).
4. Teste unitário da regra pura primeiro (tabela de casos).
5. Teste de integração: abrir o próprio `prisma.$transaction` no teste (harness, não
   produção) e chamar `recordProductionStageEvent` 3× com o mesmo `now`, simulando a
   sequência de `createRawContent` (abertura CB, conclusão CB, abertura QR) — depois ler
   com `listProductionStageEvents` e confirmar a ordem.

## Critérios de pronto

- [ ] `decideStageTransition` decide `ABERTURA` para histórico vazio, `CONCLUSAO` quando só
      há `ABERTURA`, e `RETRABALHO` quando há `CONCLUSAO` no histórico — inclusive quando a
      lista de entrada não está na ordem cronológica de emissão (ex.: `[CONCLUSAO,
      ABERTURA]` continua decidindo `RETRABALHO`) — verificação executável: `npm --prefix
      mnemonicos-backend test -- production-events.rule` → suíte verde (baseline: arquivo
      novo, comando roda contra o próprio arquivo assim que escrito, conjunto de casos
      não-vazio confirmado pelo relatório do Jest).
- [ ] Testes cobrem AC-009-006 (nenhuma operação de update/delete disponível sobre um
      evento de etapa já emitido por qualquer fluxo do sistema; o evento permanece com
      todos os 5 campos de auditoria intactos na releitura) — verificação executável: `npm
      --prefix mnemonicos-backend run test:integration -- production-events.service` →
      suíte verde, incluindo (a) o teste estrutural que falha se o texto-fonte de
      `production-events.service.ts` casar o padrão
      `/\.productionStageEvent\.(update|updateMany|delete|deleteMany|upsert)\s*\(/`
      (nenhuma chamada de mutação além de `.create(` sobre o model, ancorado na chamada real
      — não em docblock), e (b) um `recordProductionStageEvent` seguido de
      `listProductionStageEvents` afirmando `rawContentId`, `stageType`, `transitionType`,
      `actorId`, `occurredAt` todos presentes e iguais ao `input`.
- [ ] Testes cobrem AC-009-008 (ordem determinística e estável de eventos registrados no
      mesmo instante para o mesmo conteúdo, preservando a sequência de emissão real mesmo
      com `occurredAt` idêntico) — verificação executável: mesmo comando acima, caso que
      abre 1 `prisma.$transaction` de teste e chama `recordProductionStageEvent` 3× com o
      mesmo `rawContentId`/`now` (2× `stageType: 'CONTEUDO_BRUTO'`, 1× `'QUEBRA_DA_REGRA'`,
      na ordem do §4 de PLAN-010), depois `listProductionStageEvents` 2× (consultas
      repetidas) confirmando a mesma ordem `[ABERTURA-CB, CONCLUSAO-CB, ABERTURA-QR]` nas
      duas — baseline real já confirmada na Entrega de PLAN-006 (INDEX: "backend integração
      213/213 (11 suítes)", 2026-09-06) prova que o harness (`resetDb`/`closeTestDb`) está
      operante; a suíte nova soma a essa base sem reduzi-la.
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff — produção e teste, `git
      diff --name-only main...HEAD`)
- [ ] Padrão de commit respeitado
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem
- [ ] Code review aprovado

## Riscos específicos

- TRISK-010-001 (herdado do PLAN): a transação interativa que o teste de integração abre
  para simular o chamador não deve incluir I/O externo — só chamadas Prisma sobre o mesmo
  `tx`, mesma restrição que a TASK-010-003 vai seguir em produção.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Branch**:
**Commit SHA**:
**Jira**: KAN-47
**Implementado por**:
**Revisado por**:
**Tentativas**:
**Cobertura final**:
**Arquivos modificados**:
  -

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>

**Notas**:
