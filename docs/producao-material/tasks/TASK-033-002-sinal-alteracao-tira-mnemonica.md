# TASK-033-002: Sinal de alteração pós-fechamento estendido à Tira mnemônica (`resolveAlterationSignal`)

**Slug**: producao-material
**Pertence a**: PLAN-033
**Realiza (FRs)**: nenhuma
**Componente**: COMP-033-003
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Done

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-033-003, TASK-033-005

## Contexto

Combina, por OU lógico, o sinal de alteração de CONTEÚDO já existente (`hasVersionedContentChanged`,
F8, `versioned-content-diff.ts`, intocado) com um sinal NOVO de alteração da Tira
mnemônica — reusando o `ProductionStageEvent` que `tira.service.ts` já emite em todo
CRUD/reordenação de Quadro (`stageType: 'TIRA_MNEMONICA'`, intocado), sem índice novo
(DEC-033-007). Função sem AC próprio — é o único ponto de manutenção do sinal combinado
para os 3 consumidores da fatia: a leitura do histórico (TASK-033-004), o gate de
aprovação (TASK-033-003) e o carimbo do PDF (TASK-033-005), nenhum dos quais monta a
combinação por conta própria. Contrato já congelado pelo PLAN (assinatura exata) —
princípio 2: a fusão entre CONTEÚDO e TIRA já foi negociada em PLAN §1/§6 (DEC-033-007),
então extrair esta função para uma TASK própria não é dividir um contrato ainda em
negociação. Território e precedentes: `docs/producao-material/MAP.md`,
`tira.service.ts:274/287-289` (emissão do evento, molde de leitura do par
`(rawContentId, 'TIRA_MNEMONICA')`) e PLAN-033 §1/§3 (COMP-033-003), §6 (DEC-033-007).

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/content-versions/content-versions.service.ts` (estende):
  - `import { hasVersionedContentChanged, type VersionedContentFields } from
    './versioned-content-diff';` (acrescenta ao import já existente de
    `toVersionedContentFields`).
  - `type ContentVersionClient` ganha `'productionStageEvent'` no `Pick` (ao lado de
    `'contentVersion' | 'rawContent' | 'ruleBreakdown' | '$transaction'`) — os 3
    consumidores (TASK-033-003/004) chamam `resolveAlterationSignal` passando o próprio
    `tx`/`db`, que precisa satisfazer estruturalmente o parâmetro dela.
  - Nova função:
    ```ts
    export async function resolveAlterationSignal(
      rawContentId: string,
      current: VersionedContentFields,
      version: Pick<{ contentSnapshot: unknown; closedAt: Date }, 'contentSnapshot' | 'closedAt'>,
      db: Pick<typeof prisma, 'productionStageEvent'>,
    ): Promise<boolean> {
      if (hasVersionedContentChanged(current, version.contentSnapshot as unknown as VersionedContentFields)) {
        return true;
      }

      const latestTiraEvent = await db.productionStageEvent.findFirst({
        where: { rawContentId, stageType: 'TIRA_MNEMONICA' },
        orderBy: { sequence: 'desc' },
        select: { occurredAt: true },
      });

      return latestTiraEvent !== null && latestTiraEvent.occurredAt > version.closedAt;
    }
    ```
    Short-circuit (TRISK-033-002): se o conteúdo já mudou, a função retorna sem consultar
    `productionStageEvent` — custo evitado quando desnecessário. `orderBy: { sequence:
    'desc' }` (nunca `occurredAt`) — mesmo critério de desempate determinístico já usado
    por `listProductionStageEvents` (AC-009-008); `stageType: 'TIRA_MNEMONICA'` é o valor
    já emitido por `tira.service.ts`, nenhuma mudança nesse módulo.

### Não inclui

- Qualquer mudança em `tira.service.ts` — o valor `stageType: 'TIRA_MNEMONICA'` já é
  emitido por esse módulo desde F4; esta TASK só lê o evento, nunca o escreve.
- Consumo de `resolveAlterationSignal` por `approveContentVersion`/`listContentVersions`/
  `resolveVersionStampForPdf` — TASK-033-003/004/005, respectivamente.
- Índice composto novo em `ProductionStageEvent` — DEC-033-007 aceita o índice existente
  (`@@index([rawContentId, sequence])`) para o volume desta fatia.

## Critérios de pronto

- [ ] Item do Inclui sem AC (função habilitadora, consumida por TASKs futuras) — oráculo é
      o contrato do próprio item: `mnemonicos-backend/tests/unit/content-versions.service.resolve-alteration-signal.test.ts`
      (novo), com um dublê de `db` (`{ productionStageEvent: { findFirst: jest.fn() } }`,
      NUNCA o client Prisma raiz — lição ativa "[Testes] Espião de ausência
      (`not.toHaveBeenCalled`) num client Prisma que não é o mesmo objeto recebido pelo
      código sob teste nunca falsifica": aqui o dublê É o próprio objeto que a função
      recebe como `db`, então a asserção sobre ele é válida por construção, ao contrário
      de espionar `testPrisma` à parte): (a) `current` divergente do `contentSnapshot` →
      `true`, e `db.productionStageEvent.findFirst` NUNCA chamado (short-circuit,
      `expect(db.productionStageEvent.findFirst).not.toHaveBeenCalled()`); (b) `current`
      igual ao snapshot, `findFirst` resolve `null` (nenhum evento de Tira) → `false`; (c)
      `current` igual ao snapshot, `findFirst` resolve `{ occurredAt: <depois de
      closedAt> }` → `true`; (d) `current` igual ao snapshot, `findFirst` resolve
      `{ occurredAt: <antes ou igual a closedAt> }` → `false`; (e) a chamada de
      `findFirst` no caso (b)/(c)/(d) usa `where: { rawContentId, stageType:
      'TIRA_MNEMONICA' }` e `orderBy: { sequence: 'desc' }` (asserção sobre os argumentos
      da chamada, não só o retorno). Verificação executável: `npm --prefix
      mnemonicos-backend test -- content-versions.service.resolve-alteration-signal.test.ts`
      → `OK (5 tests)`.
- [ ] `ContentVersionClient` (`content-versions.service.ts`) contém `'productionStageEvent'`
      no `Pick` — `grep -n "type ContentVersionClient" -A 4
      mnemonicos-backend/src/modules/content-versions/content-versions.service.ts | grep
      productionStageEvent` (a partir da raiz do workspace) → 1 ocorrência.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`), produção e teste — `npm --prefix mnemonicos-backend run lint` →
      exit 0.
- [ ] Aderência à stack/padrões da ficha e do perfil `node-22.md` — função de I/O
      injetável (`db` como parâmetro, mesmo padrão de `listContentVersions`), sem estado
      de módulo, sem leitura de relógio (o `now` implícito é `version.closedAt`, já
      passado pelo chamador).
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-033-002 (PLAN §8) — até 3 leituras extras por chamada nos consumidores
  (`RawContent`/`RuleBreakdown` atuais + `ProductionStageEvent` condicional); esta TASK
  não introduz o custo ainda (só as TASKs consumidoras o pagam) — citado para registro, a
  medição real fica com TASK-033-004 (NFR-032-003).
- TRISK-033-004 (PLAN §8) — acoplamento novo entre `content-versions.service.ts` (dono de
  `resolveAlterationSignal`, que agora também lê `ProductionStageEvent` do módulo `tira`) e
  o CONTRATO do evento `stageType: 'TIRA_MNEMONICA'` — nenhum import de função de
  `tira.service.ts`, só o valor do enum (já compartilhado); dependência unidirecional, sem
  ciclo.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-27T18:52:00-0300
**Data conclusão**: 2026-09-27T19:13:26-0300
**Commit SHA**: 9322b66 (+ d705d9f, f9d278a — retry e residual do gate 7)
**Jira**: —

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 1) — security-engineer
- [x] Comportamento (gate 9): n/a — função sem FR/AC próprio e sem ponto de entrada nesta TASK; o sinal é exercitado de ponta a ponta nas FEATs pelas TASK-033-003/004/005
