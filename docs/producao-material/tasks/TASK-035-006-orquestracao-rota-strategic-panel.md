# TASK-035-006: Orquestração do Painel + rota `GET /strategic-panel` (allowlist, authz, custo constante)

**Slug**: producao-material
**Pertence a**: PLAN-035
**Realiza (FRs)**: FR-034-003, FR-034-015, FR-034-016, FR-034-020
**Funcionalidade**: FEAT-034-002 (primária, julgamento — a rota e a orquestração do módulo `strategic-panel` são o núcleo desta TASK; FR-034-003/020 entram por composição/wiring do FEAT-034-001, empate 2×2 no FR→FEAT posicional da SPEC §5), FEAT-034-001
**Componente**: COMP-035-012 (principal), COMP-035-013, COMP-035-014, COMP-035-016
**Wave**: 3
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-035-004, TASK-035-005
- **Bloqueia**: TASK-035-007

## Contexto

**Fatia sensível** (princípio 8: endpoint novo, autorização nova, custo de consulta
garantido por contrato NFR) — `buildStrategicPanel(now, db)` soma as 4 leituras em lote
(TASK-035-005) ao cálculo puro (TASK-035-004) e a rota `GET /strategic-panel`
(`EDITOR`/`ADMIN`) serializa por allowlist explícita campo a campo, nunca
`res.json(payload)` direto — a mesma classe de vazamento que já aconteceu neste slug em F9
(`contentSnapshot`, lição "select exposto que lê campo interno prova as chaves do
payload"). Território e precedentes:
`mnemonicos-backend/src/http/routes.ts` (montagem — linha 62,
`apiRoutes.use(contentVersionsRoutes)`, última rota; a nova entra depois),
`content-versions.routes.ts` (molde de `requireRole`/`verifyOrigin`/`actorOf`),
`tests/integration/route-authz-matrix.integration.test.ts` (censo de 47 pares, linha 154 —
a rota nova é o 48º), e PLAN-035 §1, §3 (COMP-035-012/013/014/016), §4 Fluxo 2/3, §6
(DEC-035-014/017/018).

**Prova do vertical slicing**: esta TASK, sozinha, prova via HTTP real (rota nova montada)
o comportamento observável completo do endpoint — autorização, forma do payload, custo
constante — sem esperar TASK de wiring posterior.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/strategic-panel/strategic-panel.service.ts` (estende —
  arquivo criado na TASK-035-005):
  ```ts
  export async function buildStrategicPanel(
    now: Date,
    db: StrategicPanelClient = prisma,
  ): Promise<StrategicPanelPayload> {
    const contents = await listActiveContentsForPanel(db);
    const rawContentIds = contents.map((c) => c.id);

    const [stageEvents, tiraPublications, latestVersions] = await Promise.all([
      listStageEventsForPanel(rawContentIds, db),
      listTiraPublicationEventsForPanel(rawContentIds, db),
      listLatestVersionsForPanel(rawContentIds, db),
    ]);

    const latestVersionByContent = groupLatestVersionByContent(latestVersions); // em memória
    const approvedIds = [...latestVersionByContent.entries()]
      .filter(([, v]) => v.approvedById !== null)
      .map(([id]) => id);
    const currentFieldsByContent = await listCurrentVersionedFieldsForApprovedContents(
      approvedIds,
      db,
    );

    const metrics = contents.map((content) =>
      computeContentMetrics(now, {
        content,
        stageEvents: stageEvents.filter((e) => e.rawContentId === content.id),
        tiraPublications: tiraPublications.filter((p) => p.rawContentId === content.id),
        latestVersion: latestVersionByContent.get(content.id) ?? null,
        currentVersionedFields: currentFieldsByContent.get(content.id),
      }),
    );

    return aggregateStrategicPanel(now, metrics);
  }
  ```
  Contagem fixa por chamada (DEC-035-014 v0.2, 7 statements): Conteúdos ativos; eventos de
  etapa `IN`; publicações Tira `IN`; versões vigentes `IN` só com chaves leves; e, para as
  vigentes APROVADAS, `listApprovedVersionSnapshots` (snapshot `id IN`) + 2 `IN` de dados
  atuais, no mesmo `Promise.all` (ajuste pós-gate 10 da Wave 2 — o `contentSnapshot` chega
  ao cálculo só para as vigentes aprovadas) — todo o
  cálculo roda em memória sobre o resultado, sem nova ida ao banco por Conteúdo. O
  agrupamento por `rawContentId` (`.filter`) é O(N²) no pior caso trivial deste volume de
  referência (200×50) — se o gate 10 medir custo de CPU relevante, a otimização (índice em
  memória via `Map`) é ajuste local, não mudança de contrato.
- `mnemonicos-backend/src/modules/strategic-panel/strategic-panel.routes.ts` (novo):
  ```ts
  strategicPanelRoutes.get(
    '/strategic-panel',
    requireRole('GET', '/strategic-panel', 'EDITOR', 'ADMIN'),
    async (_req, res) => {
      const payload = await buildStrategicPanel(new Date());
      res.json(toStrategicPanelResponse(payload)); // allowlist campo a campo, DEC-035-017
    },
  );
  ```
  Sem `verifyOrigin` (padrão do projeto para `GET`, mesmo de `content-versions.routes.ts`).
  `toStrategicPanelResponse` monta o JSON **campo a campo** a partir de
  `StrategicPanelPayload` (TASK-035-004) — nenhuma chave fora da lista fixada chega ao
  cliente; ao acrescentar um campo novo ao payload interno no futuro, esta função exige
  edição consciente (DEC-035-017, fricção deliberada). A lista de campos é conferida
  contra o tipo REAL `StrategicPanelPayload`/`ContentMetrics` (TASK-035-004) antes de
  fixada — nunca copiada às cegas do que este texto sugere (decisão 4.307: a forma abaixo
  é contrato mínimo, não gabarito):
  ```
  por Conteúdo: contentId, disciplineName, topicName, totalTimeMs, totalTimeReason,
  timePerPage, perStage (8 chaves, cada uma { status, ms, msPerPage }),
  reworkCountByStage, concluded, approvedButAltered, mostAdvancedStage, priority, ageMs
  agregados: byModule[], factory, moduleCompletion[], reworkTotals, backlog[]
  ```
  **Nenhuma chave** `actorId`/`authorId`/`lastEditedById` em nenhum nível (NFR-034-004) e
  **nenhum campo** de texto normativo (`rawText`/`concept`/`action`/.../`contentSnapshot`,
  NFR-034-003).
- `mnemonicos-backend/src/http/routes.ts`: `import { strategicPanelRoutes } from
  '../modules/strategic-panel/strategic-panel.routes';` + `apiRoutes.use(strategicPanelRoutes);`
  depois de `apiRoutes.use(contentVersionsRoutes);` (linha 62 — última posição, mesmo
  padrão incremental de toda fatia anterior).
- `mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts` (estende):
  1 linha nova no censo de 47→48 pares (`'GET /strategic-panel'`, linha 154 — tripwire
  atualizado); a topologia genérica (`describe('AC-002-010...')`/`describe('AC-002-011...')`)
  já cobre 401/403 por derivar de `REGISTRY` — sem `describe` extra específico (a rota não
  compartilha prefixo com nenhuma rota de papel diferente, então não há risco de herança
  por cópia como em TASK-033-003).
- `mnemonicos-backend/tests/integration/strategic-panel.query-count.integration.test.ts`
  (novo, COMP-035-014 — molde `withQueryProbe`,
  `content-versions.service.integration.test.ts:445-469`): `buildStrategicPanel` chamado
  com um volume de 10 Conteúdos (cada um com eventos de etapa REAIS, gerados via
  `createRawContent`/`recordProductionStageEvent`/fixtures de
  `production-events-fixtures.ts` — **nunca** seed direto do Prisma, RISK-034-004) e depois
  com 200 (mesmo padrão, gerado em loop) → **mesma contagem de statements** nos dois
  volumes (NFR-034-001). Falsificável: uma implementação com `findFirst` por Conteúdo em
  vez de `findMany IN` cresceria linearmente com N — o teste captura o número exato nos 2
  volumes e falha se divergirem.
- `mnemonicos-backend/tests/integration/strategic-panel.routes.integration.test.ts`
  (novo, COMP-035-016 — molde `content-versions.routes.integration.test.ts`,
  `Object.keys(...).sort()` contra a allowlist declarada):
  - AC-034-012/FR-034-015/016: 401 sem sessão; 403 com `STUDENT`; 200 com `EDITOR`/`ADMIN`.
  - AC-034-013/NFR-034-003/004 (lição ativa "select exposto que lê campo interno prova as
    chaves do payload"): `Object.keys` EXATAS do payload, por Conteúdo e agregado, contra
    a allowlist declarada acima — 0 campos de texto normativo, 0 chave
    `actorId`/`authorId`/`lastEditedById` em qualquer nível (checagem recursiva, não só o
    nível raiz — um objeto aninhado com `authorId` também reprova).

### Não inclui

- `useGetStrategicPanelQuery`/tipos espelhados no frontend — TASK-035-007.
- Qualquer tela — TASK-035-008.
- Otimização de custo além do número fixo de consultas (cache/pré-agregação) —
  DEC-035-018, fora de escopo desta fatia.

## Critérios de pronto

- [ ] Testes cobrem AC-034-012, AC-034-013 — verificação executável: `npm --prefix
      mnemonicos-backend run test:integration --
      --testPathPatterns=strategic-panel.routes.integration.test.ts` → `OK (N tests)`.
      Fixada antes do código.
- [ ] NFR-034-001 (custo constante, 10 vs. 200) — verificação executável: `npm --prefix
      mnemonicos-backend run test:integration --
      --testPathPatterns=strategic-panel.query-count.integration.test.ts` → `OK (2
      tests)`, com a contagem de statements dos 2 volumes IMPRESSA no teste (comentário +
      valor capturado) — mesma contagem nos dois. Fixada antes do código.
- [ ] **Pendência herdada (gate 10 da Wave 1, performance-engineer) — sem N+1 por composição
      no predicado de F9**: nos 2 volumes, a fixture inclui Conteúdos com Versão vigente
      APROVADA e NÃO alterada (o ramo que, em `resolveAlterationSignal`, faria 1 `findFirst`
      de TIRA por Conteúdo) — nesses volumes a contagem de statements continua igual; e
      `buildStrategicPanel` nunca chama `resolveAlterationSignal` (1 função de orquestração no
      Escopo, 1 prova: `grep -n "resolveAlterationSignal"
      mnemonicos-backend/src/modules/strategic-panel/*.ts | grep -vE ':\s*(//|\*)'` → 0,
      calibrado contra `content-versions.service.ts` → ≥1). Mutante (em `git worktree add`)
      que chama `resolveAlterationSignal` por Conteúdo aprovado → contagem diverge entre os 2
      volumes e o teste de NFR-034-001 reprova.
- [ ] **Pendência herdada (gate 8 da Wave 2, security-engineer) — contrato do input de F9**:
      a orquestração só entrega `currentVersionedFields`/snapshot para Versão vigente com
      `approvedById !== null`; 1 caso (unit ou integração) com Versão NÃO aprovada cujos
      campos atuais coincidem com o snapshot → `concluded === false` (mutante que remove
      `|| approvedById === null` em `strategic-panel-calculations.ts` reprova — em
      `git worktree add`). E a lista recursiva de chaves PROIBIDAS do teste de payload
      (NFR-034-004) inclui `approvedById` junto de `actorId`/`authorId`/`lastEditedById`.
- [ ] Censo de rotas atualizado (47→48) — verificação executável: `npm --prefix
      mnemonicos-backend run test:integration --
      --testPathPatterns=route-authz-matrix.integration.test.ts` → `OK (N tests)`.
- [ ] **Item (a) — literal contra a fonte**: a allowlist de resposta (`toStrategicPanelResponse`)
      é conferida, campo a campo, contra os NOMES REAIS de `StrategicPanelPayload`/
      `ContentMetrics` (TASK-035-004) — nenhum campo inventado nem renomeado por
      conveniência; qualquer divergência de nome entre o payload interno e a allowlist é
      erro de digitação, não escolha de design.
- [ ] **Sem `res.json(payload)` direto** (DEC-035-017): `grep -n "res.json"
      mnemonicos-backend/src/modules/strategic-panel/strategic-panel.routes.ts | grep -vE
      ':\s*(//|\*)'` → a chamada usa `toStrategicPanelResponse(payload)`, nunca `payload`
      cru — mutante:
      trocar por `res.json(payload)` direto faz o teste de `Object.keys` EXATAS (acima)
      reprovar SE o payload interno tiver qualquer campo extra além da allowlist (a
      diferença de robustez entre as 2 formas só aparece quando o payload interno cresce —
      documentar esse limite no comentário do teste, mesmo padrão da lição "select exposto
      que lê campo interno prova as chaves do payload").
- [ ] `ROUTE_ROLES.get('GET /strategic-panel')` é EXATAMENTE `{EDITOR, ADMIN}` — `grep -n
      "requireRole('GET', '/strategic-panel'"
      mnemonicos-backend/src/modules/strategic-panel/strategic-panel.routes.ts | grep -vE
      ':\s*(//|\*)'` → 1 ocorrência, com os 2 papéis literais.
- [ ] Sem `verifyOrigin` na rota (correto para `GET`, DEC-035-017) — `grep -n
      "verifyOrigin" mnemonicos-backend/src/modules/strategic-panel/strategic-panel.routes.ts
      | grep -vE ':\s*(//|\*)'` → 0 ocorrências fora de comentário (ausência esperada,
      não esquecimento — o comentário no próprio arquivo que explica a ausência é
      esperado e não conta como ocorrência de uso).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`) — `npm --prefix mnemonicos-backend run lint`
      → exit 0.
- [ ] Aderência à ficha/perfil: camadas schema→service→routes (sem `.schema.ts` — rota
      sem parâmetro de entrada, nada para o Zod validar, mesmo padrão de rotas `GET` sem
      params do projeto).
- [ ] Segurança (gate 8): `security-engineer` revisa a allowlist de resposta e a ausência
      de `scopeWhere` herdada da TASK-035-005 sob a ótica do endpoint exposto.
- [ ] Performance (gate 10): `performance-engineer` mede p95 do endpoint no volume de
      referência (200 Conteúdos × 50 eventos, mesmo fixture do teste de custo constante) —
      NFR-034-002 (SHOULD, alvo 1.500 ms) é aderência de gate, não critério de gate 1
      (sem oráculo unitário determinístico para latência de rede/CPU); medição registrada
      no report do gate, correção (cache/índice/paginação) entra como ajuste se acima do
      alvo (DEC-035-018).
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-035-003 (PLAN §8) — as 2 consultas extras do predicado de F9 em lote crescem com
  a fração de Conteúdos aprovados, não com o total; medido pelo gate 10 no volume de
  referência.
- DEC-035-018 — sem cache/pré-computação nesta fatia; se o gate 10 medir acima do alvo, a
  correção é ajuste local, nunca reabertura desta DEC.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-173

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
