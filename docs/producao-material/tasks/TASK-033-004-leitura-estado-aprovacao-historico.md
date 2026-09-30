# TASK-033-004: Leitura do estado de aprovação no histórico de Versões

**Slug**: producao-material
**Pertence a**: PLAN-033
**Realiza (FRs)**: FR-032-006, FR-032-007
**Funcionalidade**: FEAT-032-001 (primária)
**Componente**: COMP-033-005, COMP-033-009, COMP-033-013
**Wave**: 3
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: TASK-033-003
- **Bloqueia**: TASK-033-006

## Contexto

Estende `listContentVersions` (F8, já existente) para expor, junto de cada Versão do
histórico, se ela foi aprovada (e por quem/quando) e um campo COMPUTADO —
`validApprovalForExport` — que reflete se a PRÓXIMA Exportação sairia com o carimbo
"Versão aprovada" ou "Rascunho" (considerando o sinal de alteração combinado,
TASK-033-002), sem alterar o fato histórico da aprovação em si (FR-032-005). Sequenciada
depois de TASK-033-003 por **colisão de escrita no MESMO arquivo**
(`content-versions.service.ts`) — princípio 2, nunca por dependência funcional real (esta
TASK só precisa das colunas da Wave 1 + `resolveAlterationSignal` da Wave 1, mas o arquivo
já foi editado por TASK-033-003 na Wave 2; sequenciar evita o risco de 2 diffs paralelos no
mesmo arquivo). Território e precedentes: `docs/producao-material/MAP.md` e PLAN-033 §1,
§3 (COMP-033-005), §4 Fluxo 4.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/content-versions/content-versions.service.ts` (estende):
  - `ContentVersionDetail` ganha o campo COMPUTADO `validApprovalForExport: boolean` (não
    persistido, não faz parte de nenhum `select` Prisma).
  - `listContentVersions` — troca o `select` de `CONTENT_VERSION_DETAIL_SELECT` por
    `{ ...CONTENT_VERSION_DETAIL_SELECT, contentSnapshot: true }` (leitura interna, NUNCA
    devolvida ao chamador); identifica a Versão vigente (a de MAIOR `number` — o array já
    vem ordenado ASC, então é o ÚLTIMO item); `validApprovalForExport` só é computado
    (pagando a leitura extra) quando a vigente JÁ está aprovada
    (`vigente.approvedById !== null`) — otimização documentada no PLAN: senão, é `false`
    por construção, sem custo extra. Quando computado: lê `RawContent`/`RuleBreakdown`
    ATUAIS (mesmos `select`s já existentes, `RAW_CONTENT_VERSIONED_SELECT`/
    `RULE_BREAKDOWN_VERSIONED_SELECT`), monta `current` via `toVersionedContentFields`, e
    chama `resolveAlterationSignal(rawContentId, current, vigente, db)` — `true` (alterado)
    ⇒ `validApprovalForExport: false`; `false` ⇒ `true`. Toda entrada QUE NÃO é a vigente
    recebe `validApprovalForExport: false` incondicionalmente (FR-032-006 — a aprovação
    nunca se propaga, e uma Versão superada nunca é a que sai impressa), mesmo que ela
    própria tenha sido aprovada no passado.
  - `approveContentVersion` (TASK-033-003, mesmo arquivo): o objeto retornado em caso de
    sucesso ganha `validApprovalForExport: true` — sem recomputar
    `resolveAlterationSignal` (o passo 10 da própria função já confirmou o sinal
    `false` na mesma transação; recomputar seria uma 2ª leitura redundante do mesmo
    fato). `closeContentVersion` (F8, intocado no CORPO): o `select` já devolve
    `approvedById: null`/`approvedAt: null` automaticamente (colunas novas, Wave 1); o
    objeto construído por essa função precisa ganhar literalmente
    `validApprovalForExport: false` (uma Versão recém-fechada nunca está aprovada) — ÚNICA
    linha tocada nessa função.
- `mnemonicos-backend/tests/integration/content-versions.service.integration.test.ts`
  (estende): novos blocos:
  - AC-032-001 (parte LEITURA): após uma aprovação bem-sucedida (fixture com
    `sourceType`/`sourceCitation` setados, ADMIN elegível), `listContentVersions` devolve
    a entrada com `approvedById`/`approvedAt` idênticos aos gravados e
    `validApprovalForExport: true`.
  - AC-032-006 (FR-032-006): Versão 1 aprovada, EDITOR fecha a Versão 2 (sem aprová-la) →
    `listContentVersions` devolve as 2: Versão 1 com `approvedById` preenchido MAS
    `validApprovalForExport: false` (não é mais a vigente); Versão 2 com `approvedById:
    null` e `validApprovalForExport: false`.
  - AC-032-020 (FR-032-007): Versão vigente aprovada, depois um campo versionado do
    `RawContent` é alterado (`updateRawContent`, importado de `contents.service.ts`) →
    `listContentVersions` continua devolvendo `approvedById`/`approvedAt` preenchidos
    (fato histórico intacto), mas `validApprovalForExport: false` (a PRÓXIMA Exportação
    sairia como Rascunho).
  - **NFR-032-003/AC-032-013 — custo CONSTANTE, independente de N** (estende o `describe`
    já existente no arquivo, `'listContentVersions — custo fixo de round-trips...'`, sem
    duplicar o caso já coberto — Versão vigente NÃO aprovada continua em exatamente 2
    statements, regressão confirmada pelo mesmo teste já existente, sem alteração): 2 casos
    NOVOS via `withQueryProbe`, ambos com a Versão vigente APROVADA e SEM alteração
    posterior — (a) `RawContent` com 3 Versões fechadas, a última aprovada → EXATAMENTE 5
    statements (`assertRawContentReachable` + `findMany` + `rawContent.findUniqueOrThrow`
    + `ruleBreakdown.findUniqueOrThrow` + `productionStageEvent.findFirst` dentro de
    `resolveAlterationSignal`); (b) MESMO cenário com 8 Versões fechadas → EXATAMENTE 5
    statements também (nunca 10, nunca proporcional a N) — os 2 casos, lado a lado,
    provam que o custo NÃO cresce com N. 3º caso: Versão vigente aprovada mas com sinal de
    alteração de CONTEÚDO aceso (short-circuit de `resolveAlterationSignal`, TASK-033-002)
    → EXATAMENTE 4 statements (pula a leitura de `productionStageEvent`).
- **Herdado do gate 8 da Wave 1 (security-engineer, notas N1/N2/N6 — decisão 4.140)**,
  mesma suíte `content-versions.service.integration.test.ts`:
  - (N1) `resolveAlterationSignal` recebe só a Versão VIGENTE (a de maior `number` do
    array já filtrado pelo `rawContentId` do chamador) e o `current` lido do MESMO
    `rawContentId` — nunca uma Versão de outro Conteúdo bruto. Caso: 2 Conteúdos brutos
    com Versões aprovadas, alterar o conteúdo só de B → `listContentVersions(A)` devolve
    `validApprovalForExport: true` para a vigente de A e `listContentVersions(B)` devolve
    `false` (o sinal não vaza entre Conteúdos brutos).
  - (N2) Fail-secure da leitura: `productionStageEvent.findFirst` rejeitando durante o
    cálculo de `validApprovalForExport` → a chamada rejeita (erro propaga), nunca devolve
    `validApprovalForExport: true` nem cai para um default silencioso.
  - (N6) O estado de aprovação exposto usa `select` explícito de `approvedById`/`approvedAt`
    — nunca `include: { approver: true }` (User carrega `passwordHash`).
  - Fixture: usar o builder de `VersionedContentFields` que TASK-033-003 cria em
    `tests/support/` (nunca uma 3ª cópia local).
- **Espelho de `validApprovalForExport` no mesmo diff** (refino pós-furo no plano de
  TASK-033-003, 2026-09-27 — quem cria o campo no payload HTTP espelha, regra do
  CLAUDE.md do workspace): `mnemonicos-backend/src/domain/types.ts` e
  `mnemonicos-frontend/src/types/domain.ts` — `interface ContentVersion` ganha
  `validApprovalForExport: boolean`; o `describe` de paridade `ContentVersion` de
  `tests/unit/contents-frontend-contract.test.ts` passa a listar o campo nos 2 lados.
  Frontend: fixture/objeto `ContentVersion` que o typecheck acusar ganha o campo
  (`false`).

### Não inclui

- Extensão de `publication.service.ts`/`pdf-composer.ts` — TASK-033-005 (embora leia o
  MESMO sinal combinado via `resolveAlterationSignal`, o consumidor do carimbo do PDF é
  uma função à parte, `resolveVersionStampForPdf`).
- Rota/schema/segregação de funções de aprovação — já entregues por TASK-033-003, da qual
  esta TASK só consome `resolveAlterationSignal`/as colunas novas.
- `store/api.ts` (mutation de aprovação) e painel de aprovação — TASK-033-006/007.

## Critérios de pronto

- [ ] Testes cobrem AC-032-001 (parte leitura — o DADO devolvido pelo service; a faceta de
      RENDERIZAÇÃO na tela é do gate 1 da TASK-033-007), AC-032-006, AC-032-020 (parte
      leitura — mesma régua; renderização é TASK-033-007), AC-032-013 — verificação
      executável: `npm --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=content-versions.service.integration.test.ts` → `OK (N tests)`.
- [ ] `approveContentVersion` devolve `validApprovalForExport: true` em toda aprovação
      bem-sucedida — coberto pelo mesmo teste de AC-032-001 (parte escrita, TASK-033-003)
      reexecutado após esta extensão, sem regressão: mesmo comando acima → `OK (N tests)`.
- [ ] `closeContentVersion` devolve `validApprovalForExport: false` em toda Versão recém-
      fechada — teste de regressão sobre o cenário já existente de AC-028-001 (TASK-029-002):
      mesmo comando acima → `OK (N tests)`.
- [ ] **Comparação com o molde canônico** (decisão 4.307): o `select` estendido
      (`{ ...CONTENT_VERSION_DETAIL_SELECT, contentSnapshot: true }`) segue EXATAMENTE o
      padrão já usado por `approveContentVersion` (TASK-033-003, mesmo arquivo) para a
      leitura da Versão vigente — nunca uma 2ª forma de compor o `select`.
- [ ] Heranças N1/N2 do gate 8 W1 (ver Inclui): caso "sinal não vaza entre Conteúdos
      brutos" e caso "`findFirst` rejeitando → chamada rejeita" — mesmo comando da suíte
      acima → `OK (N tests)`, os 2 casos nomeados no relatório do Jest. Mutante (em
      `git worktree add`): envolver a chamada de `resolveAlterationSignal` em
      `.catch(() => false)` → o caso N2 fica vermelho.
- [ ] Herança N6: `grep -rn "include: { approver" mnemonicos-backend/src | grep -vE
      ':\s*(//|\*)' | grep -v generated` (raiz do workspace) → 0 ocorrências.
- [ ] Espelho de `validApprovalForExport` (ver Inclui): `npm --prefix mnemonicos-backend
      test -- contents-frontend-contract.test.ts` → verde; `npm --prefix
      mnemonicos-frontend run typecheck && npm --prefix mnemonicos-frontend test` → exit 0
      / sem vermelho novo contra a baseline do frontend.
- [ ] Fixture: `grep -rln "BASE_FIELDS\|const BASE = " mnemonicos-backend/tests` não
      ganha nenhum arquivo novo desta TASK (a fixture vem do builder de `tests/support/`).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npm --prefix mnemonicos-backend run lint` → exit 0.
- [ ] Aderência à stack/padrões da ficha e do perfil `node-22.md` — `select` explícito,
      função de leitura sem I/O condicional além do documentado, sem estado de módulo.
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-033-002 (PLAN §8) — esta TASK é quem MEDE o custo real (critério NFR-032-003
  acima); se a medição real mostrar impacto perceptível em volume alto, revisitar
  DEC-033-007 (índice composto).
- Gate 8 (security-engineer): **n/a** — leitura estendida de rota já revisada
  (`GET /contents/:id/versions`, TASK-029-002), sem superfície de autorização nova; a
  única escrita tocada (`approveContentVersion`/`closeContentVersion`, 1 campo literal
  cada) já foi revisada em TASK-033-003/TASK-029-002.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-29T20:55:00-0300 (despacho; developer não capturou o início — declarado)
**Data conclusão**: 2026-09-29T21:40:00-0300
**Commit SHA**: 923f60e (+ e1d8426 — retry 1 dos gates 1/7; eba5603 — aplicação de fim de wave; frontend d19ecfd)
**Jira**: KAN-155

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (wave 3, após 1 retry: F1 caso por par de ramos + F2 chaves exatas do payload; F2 no teste HTTP de rotas, extensão só-de-teste declarada pelo Tech Lead) — code-reviewer
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 3, 0 vulnerabilidade; lacuna de prova do não-vazamento de `contentSnapshot` fechada no retry) — security-engineer · Performance (gate 10): aprovado, 2 sugestões não-bloqueantes (Entrega) — performance-engineer
- [x] Comportamento (gate 9): consolidado FEAT-032-001 — carregador: Roteiro do gate 9 de TASK-033-007 (Wave 5), que renderiza o estado de aprovação e `validApprovalForExport` na tela
