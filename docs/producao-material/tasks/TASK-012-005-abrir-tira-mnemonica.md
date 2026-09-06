# TASK-012-005: Abrir a Tira mnemônica — geração idempotente e leitura

**Slug**: producao-material
**Pertence a**: PLAN-012
**Realiza (FRs)**: FR-011-001, FR-011-002, FR-011-007, FR-011-008
**Componente**: COMP-012-004 (principal)
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico, estratégia `unica`)
**Padrão de commit**: Conventional Commits (`feat:`)
**Framework de teste**: Jest 30 + ts-jest (unit: `npm --prefix mnemonicos-backend test`; integração: `npm --prefix mnemonicos-backend run test:integration`)

## Dependências

- **Depende de**: TASK-012-001, TASK-012-002
- **Bloqueia**: TASK-012-006, TASK-012-011

## Contexto

Núcleo do módulo `tira.service.ts` (novo, greenfield): `buildInitialFrames` (regra pura de
geração inicial a partir dos Blocos não-vazios da Quebra, ordem canônica) e
`openMnemonicStrip` (get-or-generate idempotente — cria a Tira + Quadros na 1ª abertura,
devolve a existente na reabertura, sem gerar 2×). Reusa, sem redesenho:
`assertRawContentReachable` (TASK-012-002, alcance por autoria herdado de F2 — NFR-011-001/
NFR-011-006) e `recordProductionStageEvent` (COMP-010-002 de PLAN-010 — emite só
**abertura** no instante da geração, nunca conclusão junto, DEC-012-006). Geração
idempotente sob concorrência (AC-011-025) reusa o precedente de `saveRuleBreakdown`/
DEC-010-007: `create` direto + captura de violação de unicidade de `ruleBreakdownId`
(DEC-012-008) — sem `findFirst`+`create` (check-then-act), que reabriria a janela de
corrida que este AC prova fechada. Toda mutação roda dentro de `$transaction` (fail-secure,
NFR-011-003, AC-011-015).

Esta TASK cobre a abertura/reabertura **simples** (sem mutações humanas prévias de
Quadro) — FR-011-007/AC-011-012 completo (reordem persistida após CRUD) só fecha quando as
tasks de CRUD/reordenação (fora desta lista) existirem; aqui, "reabertura" é só o caminho
de leitura da Tira recém-gerada, sem edição.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/tira/tira.service.ts` (novo arquivo):
  - `export interface MnemonicFrameDetail { id: string; text: string; position: number;
    originBlock: string | null; }`
  - `export interface MnemonicStripDetail { id: string; frames: MnemonicFrameDetail[]; }`
    (`frames` ordenados por `position asc`).
  - `export function buildInitialFrames(breakdown: Pick<RuleBreakdownDetail, 'concept' |
    'action' | 'object' | 'condition' | 'exception'>): Array<{ text: string; position:
    number; originBlock: string }>` — pura, sem I/O: 1 item por Bloco não-vazio, ordem
    CONCEITO → AÇÃO → OBJETO → CONDIÇÃO → EXCEÇÃO, posições 1..N sem lacuna,
    `originBlock` = nome do campo de origem (`'concept'`, `'action'`, etc.).
  - `export async function openMnemonicStrip(rawContentId: string, actor: ContentActor,
    db?: MnemonicStripClient): Promise<MnemonicStripDetail>` — dentro de `$transaction`:
    1. `assertRawContentReachable(rawContentId, actor, tx)` (import de
       `../contents/contents.service`, TASK-012-002).
    2. `tx.ruleBreakdown.findUnique({ where: { rawContentId } })` — `null` → `ConflictError`
       (409) orientando em pt-BR a concluir a Quebra da regra primeiro (AC-011-023, parte).
    3. `try { tx.mnemonicStrip.create({ data: { ruleBreakdownId, frames: { create:
       buildInitialFrames(breakdown) } } }) }` — sucesso → `recordProductionStageEvent(tx,
       { rawContentId, stageType: 'TIRA_MNEMONICA', actorId: actor.id, now })` (decide
       ABERTURA, 0 eventos existentes para o par).
    4. `catch` violação de unicidade em `ruleBreakdownId` → lê e devolve a Tira já criada
       pela transação vencedora, **sem** chamar `recordProductionStageEvent` de novo.
    5. Reabertura de Tira já existente (sem passar pelo `catch` — `findUnique` direto
       antes de tentar `create`) → devolve os Quadros na ordem de `position` persistida.
  - Import de `ContentActor`/`assertRawContentReachable` de `../contents/contents.service`
    (TASK-012-002) e de `recordProductionStageEvent` de `../production-events/
    production-events.service` (COMP-010-002, sem alteração).
- `mnemonicos-backend/tests/unit/tira.rule.test.ts` (novo) — `buildInitialFrames`: 5 Blocos
  preenchidos, CONDIÇÃO/EXCEÇÃO vazios, ordem canônica, posições contíguas.
- `mnemonicos-backend/tests/integration/tira.service.integration.test.ts` (novo, molde
  `contents.service.integration.test.ts`) — `openMnemonicStrip` sobre Postgres real:
  geração inicial, reabertura simples, concorrência real, guarda de alcance, soft-delete
  do pai, fail-secure. Reusa `tests/support/production-events-fixtures.ts`
  (`createUser`/`createTopic`/`createRawContent`) — não recria fixture equivalente.

### Não inclui

- `addMnemonicFrame`/`updateMnemonicFrameText`/`removeMnemonicFrame`/
  `reorderMnemonicFrames` — tasks seguintes (fora desta lista).
- Qualquer rota HTTP (`tira.routes.ts`) — TASK-012-006, fora desta lista.
- A faceta HTTP 409 de "Quebra da regra não salva" (AC-011-023) — aqui só a regra/service
  recusa via `ConflictError`; o mapeamento para status HTTP é da TASK de rotas.
- AC-011-012 completo (reabertura após CRUD/reordenação) — só a reabertura simples (sem
  mutação prévia) é provada aqui; o caminho completo fecha quando as tasks de CRUD
  existirem.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. `buildInitialFrames`: função pura, mapeia os 5 campos de `RuleBreakdownDetail` (exceto
   `essence`) na ordem canônica, filtra vazios, atribui posição sequencial 1..N.
2. `openMnemonicStrip`: guarda de alcance primeiro (mesma régua de
   `saveRuleBreakdown`/`getRuleBreakdown`), depois checagem de Quebra salva, depois
   `create`+catch de violação única, depois `recordProductionStageEvent` só no ramo de
   sucesso da criação.
3. Tipo injetável do cliente Prisma (`MnemonicStripClient`) no mesmo padrão de
   `RawContentClient`/`RuleBreakdownClient` de `contents.service.ts` — cobre
   `rawContent`/`ruleBreakdown`/`mnemonicStrip`/`$transaction`.
4. Leitura de `frames` (relação de lista) com `select` explícito e `orderBy: { position:
   'asc' }` — medir round-trips reais contra o Postgres de teste antes de fixar a
   estratégia (`relationLoadStrategy`), não presumir que o `join` default sempre vence
   para relação 1-N (lição [Performance], ressalva 2).
5. Testes: unit de `buildInitialFrames` primeiro (mais barato), depois integração.

## Critérios de pronto

- [ ] Testes cobrem AC-011-001, AC-011-002 (geração a partir dos Blocos não-vazios,
      ordem canônica) — verificação executável: `npm --prefix mnemonicos-backend test --
      tira.rule` → `Tests: ≥2 passed` — caso com os 5 Blocos preenchidos gera 5 itens nas
      posições 1..5 na ordem `['concept','action','object','condition','exception']`; caso
      com CONDIÇÃO/EXCEÇÃO vazios (`''`/`undefined`) gera exatamente 3 itens
      (`concept`/`action`/`object`), posições 1..3, sem lacuna. Falsificável: trocar a
      ordem de 2 blocos ou incluir um Bloco vazio como Quadro reprova a asserção de
      sequência/tamanho do array. Fixada antes do código.
- [ ] Testes cobrem AC-011-003 (reabertura não regenera) — verificação executável:
      `npm --prefix mnemonicos-backend run test:integration -- tira.service` →
      `Tests: ≥1 passed` — 2 chamadas sequenciais de `openMnemonicStrip` para o mesmo
      `rawContentId` devolvem o MESMO `id` de `MnemonicStripDetail`, e
      `testPrisma.mnemonicStrip.count({ where: { ruleBreakdownId } })` === `1` após as 2
      chamadas (contagem, não "não vazio" — item (g) da régua de contorno).
- [ ] Testes cobrem AC-011-013, AC-011-021 (só abertura emitida na geração; etapa
      permanece ABERTA sem conclusão indefinidamente) — verificação executável: mesmo
      comando acima, caso que chama `openMnemonicStrip` 1×, depois consulta
      `testPrisma.productionStageEvent.findMany({ where: { rawContentId, stageType:
      'TIRA_MNEMONICA' } })` e afirma **exatamente 1** linha, com
      `transitionType === 'ABERTURA'` (contagem, não "existe ao menos uma abertura");
      reabrir a Tira uma 2ª vez (sem mutação de Quadro) mantém a MESMA contagem (1),
      nenhum evento novo.
- [ ] Testes cobrem AC-011-023 (parte — regra pura recusa sem Quebra salva) — verificação
      executável: mesmo comando, caso que chama `openMnemonicStrip` para um
      `rawContentId` alcançável mas SEM `RuleBreakdown` associada → lança `ConflictError`
      com mensagem em pt-BR orientando a concluir a Quebra da regra primeiro (asserção de
      `instanceof ConflictError` **e** de igualdade literal da mensagem — nunca só
      `instanceof`); e `testPrisma.mnemonicStrip.count({ where: { ... } })` === `0` após a
      tentativa (nenhuma criação parcial).
- [ ] Testes cobrem AC-011-025 (concorrência real, fronteira exata da invariante — 2
      chamadas, não N, lição ativa [Testes] "Prova de corrida/exclusão nasce na fronteira
      da invariante") — verificação executável: mesmo comando, caso que dispara
      `Promise.all([openMnemonicStrip(id, actor, prisma), openMnemonicStrip(id, actor,
      prisma)])` para o MESMO `rawContentId` sem Tira prévia, e depois afirma
      `testPrisma.mnemonicStrip.count({ where: { ruleBreakdownId } })` === `1` **e**
      `testPrisma.productionStageEvent.count({ where: { rawContentId, stageType:
      'TIRA_MNEMONICA', transitionType: 'ABERTURA' } })` === `1` — as duas contagens
      exatas (nunca `>= 1`), rodado pelo comando do arquivo inteiro (nunca `-t` isolado,
      mesma lição). Falsificável: um `findFirst`+`create` (check-then-act) no lugar de
      `create`+catch produziria 2 linhas sob corrida real — o teste reprova esse mutante.
      A árvore de decisão com precedência do serviço tem 3 ramos distinguíveis, cada um
      com prova própria: (i) 1ª chamada, `create` sucede → ABERTURA; (ii) 2ª chamada,
      `create` falha por violação única → lê a Tira da vencedora, sem 2º evento; (iii)
      reabertura simples posterior (sem tentar `create` — `findUnique` resolve antes) →
      mesmos dados, nenhuma tentativa de escrita.
- [ ] Testes cobrem AC-011-020 (parte — PROVA COMPORTAMENTAL COMPLETA: soft-delete do
      `RawContent` pai torna a Tira inalcançável) e NFR-011-006 — verificação executável:
      mesmo comando, caso que gera a Tira, depois marca `deletedAt` no `RawContent` de
      origem (via `testPrisma.rawContent.update`) e chama `openMnemonicStrip` de novo
      (reabertura) → lança `NotFoundError` com a mensagem literal `'Conteúdo bruto foi
      removido.'` (igualdade exata, mensagem confirmada por leitura direta de
      `contents.service.ts:380`) — nenhuma linha de `mnemonic_strips`/`mnemonic_frames` é
      apagada (dado preservado, só inalcançável).
- [ ] Testes cobrem AC-011-022 (parte — PROVA COMPORTAMENTAL COMPLETA: EDITOR A não
      alcança Tira de EDITOR B, mesma mensagem para inexistente/fora-de-alcance/removido)
      e NFR-011-001 — verificação executável: mesmo comando, caso com 2 EDITORES
      distintos (`createUser('EDITOR')` ×2) — EDITOR B chama `openMnemonicStrip` sobre o
      `rawContentId` de conteúdo autorado por EDITOR A → lança `NotFoundError` com a
      mensagem literal `'Conteúdo bruto não encontrado.'`; a MESMA mensagem literal (não
      só `instanceof AppError`) é asserida para um `rawContentId` aleatório inexistente,
      confirmando que os dois casos são indistinguíveis pelo oráculo (mesma régua do
      corolário de segurança da lição ativa "Árvore de decisão com precedência").
      Fechamento contável (item (c) da régua de contorno): **1 método** desta TASK toca
      tabela escopada por autoria herdada (`mnemonicStrip`/`mnemonicFrame`, via a cadeia
      `RawContent → RuleBreakdown → MnemonicStrip`) — `openMnemonicStrip` — **1 prova**
      (este caso, par EDITOR-dono × EDITOR-não-dono com mensagem idêntica).
- [ ] Testes cobrem AC-011-015 (parte — fail-secure da geração) e NFR-011-003 —
      verificação executável: mesmo comando, caso que espiona/mocka
      `recordProductionStageEvent` (namespace import, mesmo padrão de TASK-010-003 em
      `contents.service.integration.test.ts`) para rejeitar dentro da transação de
      `openMnemonicStrip` → a chamada inteira rejeita, **e**
      `testPrisma.mnemonicStrip.count({ where: { ruleBreakdownId } })` === `0` depois (nem
      a Tira nem os Quadros persistem — nenhum estado meio-salvo). Falsificável: um
      `openMnemonicStrip` que não envolvesse `create`+emissão na MESMA `$transaction`
      deixaria a Tira persistida mesmo com a emissão falhando — o teste reprova esse
      mutante.
- [ ] Leitura de `MnemonicStripDetail.frames` (relação de lista `MnemonicStrip.frames`)
      tem a contagem de round-trips FIXADA em teste, não presumida — lição ativa
      [Performance] "`include`/`select` aninhado de relação não é 1 statement por
      padrão" (ressalva 2: relação de LISTA nem sempre é resolvida por `join` mesmo com
      `relationJoins` ativo globalmente). Verificação executável: teste de integração com
      `prisma.$on('query', ...)` (ou contagem equivalente via log de eventos) contando as
      queries disparadas por uma chamada de `openMnemonicStrip` em reabertura simples
      (Tira com 5 Quadros) — a contagem é registrada explicitamente no teste (ex.:
      `expect(queryCount).toBe(<N medido>)`) e a estratégia escolhida
      (`relationLoadStrategy`) fica declarada em comentário no `findUnique`/`create` que
      devolve `frames`. Falsificável: a ausência desta asserção deixaria uma consulta
      N+1 (uma ida por Quadro) passar despercebida.
- [ ] Sem warnings/lints novos (`npm --prefix mnemonicos-backend run lint` → exit 0, sobre
      todos os arquivos do diff, produção e teste).
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem (`node-22.md` — Prisma 7
      driver adapter, `$transaction` interativa, `select` explícito).
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-012-002 (reindexação em 2 fases) não se aplica a esta TASK — `buildInitialFrames`
  escreve posições 1..N de uma vez, sem reindexação; a primitiva de 2 fases entra nas
  tasks de CRUD/reordenação seguintes.
- TRISK-012-005 (`GET` idempotente com efeito colateral) é herdado por esta TASK — a
  idempotência real vem da constraint `@unique(ruleBreakdownId)` (DEC-012-008), provada
  pelo critério de concorrência acima.
- Fatia com superfície sensível (guarda de alcance por autoria, OWASP A01) — mesmo sem
  marcação formal de "fatia sensível" no PLAN, `security-engineer` (gate 8) revisa o
  diff completo desta TASK dado o reuso de `assertRawContentReachable`.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-06T20:15:14-0300
**Data conclusão**: 2026-09-06T20:48:07-0300
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: da27117 (implementação inicial `a21e483`, retry de convergência `da27117`)
**Jira**: KAN-55
**Implementado por**: developer
**Revisado por**: code-reviewer (REPROVADO na 1ª rodada — achado A1 bloqueante + A2/A3 carona; CONVERGIU no re-review delta-scoped) · security-engineer (gate 8 aprovado, Wave 2) · performance-engineer (gate 10 aprovado, Wave 2 — N+1 confirmado ausente por sonda real)
**Tentativas**: 2 (1 retry, roteado pelo achado A1 do code-reviewer)
**Cobertura final**: n/a (item do Inclui sem AC próprio — prova pelos ACs abaixo)
**Arquivos modificados**:
  - mnemonicos-backend/src/modules/tira/tira.service.ts
  - mnemonicos-backend/tests/unit/tira.rule.test.ts
  - mnemonicos-backend/tests/integration/tira.service.integration.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (3/3 unit + 8/8 integração, mesma contagem antes/depois do retry)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (convergiu após retry — tipo `RuleBreakdownBlocks` local removido em favor de `RuleBreakdownDetail` canônico)
- [x] ACs verificados (AC-011-001, AC-011-002, AC-011-003, AC-011-013, AC-011-015, AC-011-020, AC-011-021, AC-011-022, AC-011-023, AC-011-025)
- [x] Segurança (gate 8): aprovado — guard de alcance confirmado como 1ª chamada por mutation testing (mutante M4 morto); fail-secure confirmado (mutante M2 morto); sem oráculo de enumeração no ramo de corrida
- [x] Comportamento (gate 9): n/a — regra de negócio backend, sem tela; a faceta observável fica com TASK-012-012 (gate 9 do DoD)

**Notas**: achado A1 (tipo `RuleBreakdownBlocks` duplicando `RuleBreakdownDetail` canônico de `contents.service.ts`) corrigido no retry — 2ª reincidência da lição "[Código] Interface pública do PLAN é contrato mínimo" (promovida de em-observação para ativa em `guidelines/project/lessons.md`). Mutation testing do code-reviewer (4 mutantes independentes: corrida real, fail-secure, N+1, ordem do guard) confirmou que os testes falsificam de fato, não são verde vazio.

**Notas**:
