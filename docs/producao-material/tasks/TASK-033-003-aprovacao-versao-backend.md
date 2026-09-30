# TASK-033-003: Aprovação de Versão vigente — backend completo (segregação de funções + idempotência)

**Slug**: producao-material
**Pertence a**: PLAN-033
**Realiza (FRs)**: FR-032-001, FR-032-002, FR-032-003, FR-032-004, FR-032-005, FR-032-009, FR-032-013, FR-032-014, FR-032-015, FR-032-016, FR-032-017, FR-032-018
**Funcionalidade**: FEAT-032-001 (primária)
**Componente**: COMP-033-002 (principal), COMP-033-004, COMP-033-006, COMP-033-012, COMP-033-009, COMP-033-013
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: TASK-033-001, TASK-033-002
- **Bloqueia**: TASK-033-004, TASK-033-006

## Contexto

**Fatia sensível** (princípio 8: autorização nova + segregação de funções + regra de
negócio central + migração já aplicada na Wave 1): endpoint novo, ponta a ponta
(`POST /contents/:id/versions/:number/approve`), que registra a aprovação de uma Versão
editorial vigente — 2 confirmações de julgamento humano, duplo travamento anti-corrida
(número da Versão + sinal de alteração), segregação de funções por 3 identidades
produtoras lidas ao vivo, e idempotência garantida por `updateMany` condicionado
(DEC-033-009), nunca por disciplina de ordem de código. Segue o MESMO padrão transacional
de `closeContentVersion` (F8) — lock de linha do `RawContent` pai como 1ª chamada
(DEC-033-001 herdada de DEC-029-004). Território e precedentes:
`docs/producao-material/MAP.md`,
`mnemonicos-backend/src/modules/content-versions/content-versions.service.ts` (leitura
direta confirmada — `closeContentVersion`/`listContentVersions` já existentes, F8),
`content-versions.routes.ts`, e PLAN-033 §1, §3 (COMP-033-002/004/006/012), §4 Fluxo 1/2/3,
§6 (DEC-033-001/002/003/004/005/006/008/009).

**Prova do vertical slicing**: esta TASK, sozinha, prova via HTTP real (rota montada) o
fluxo completo de aprovação — o ponto de entrada (a rota) pertence a ela, nunca a uma
TASK de wiring posterior (princípio 4).

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/content-versions/content-versions.schema.ts` (estende):
  - `approveContentVersionSchema` — exatamente 2 campos, `legalCheckConfirmed:
    z.literal(true, 'Confirmação da checagem jurídica é obrigatória.')` e
    `pedagogicalCheckConfirmed: z.literal(true, 'Confirmação da checagem pedagógica é
    obrigatória.')` (mesma sintaxe de mensagem-string curta já usada por
    `closeContentVersionSchema`/`z.iso.date`) — qualquer valor diferente de `true`
    (`false`, ausente, string) falha o `parse` com 422, ANTES de qualquer leitura do
    service (A-032-004). Tipo inferido `ApproveContentVersionInput`.
  - `approveContentVersionParamsSchema` — `z.object({ id: z.uuid('Identificador de
    conteúdo bruto inválido.'), number: z.coerce.number('Número de Versão inválido.').int().positive() })`
    (reuso da MESMA mensagem de `rawContentIdParamSchema` para `id`, mas schema PRÓPRIO —
    nunca reexporta `rawContentIdParamSchema` isoladamente, porque o `:number` é parte do
    MESMO objeto de params desta rota, FR-032-014: o duplo travamento exige o número como
    parte da URL). Tipo inferido `ApproveContentVersionParams`.
- `mnemonicos-backend/src/modules/content-versions/content-versions.service.ts` (estende):
  - `RAW_CONTENT_VERSIONED_SELECT` ganha `lastEditedById: true` (extensão do `select`
    já existente, reusado por `closeContentVersion` sem efeito — o campo extra é
    ignorado por quem não o consome; nunca duplicar o objeto).
  - `CONTENT_VERSION_DETAIL_SELECT`/`ContentVersionDetail` ganham `approvedById: true`/
    `approvedById: string | null` e `approvedAt: true`/`approvedAt: Date | null` (colunas
    novas da Wave 1, leitura direta — **sem** `contentSnapshot`, que segue nunca exposto,
    DEC-029-003). `closeContentVersion` (F8, intocado no CORPO) passa a devolver esses 2
    campos automaticamente como `null` pelo próprio `select` — nenhuma linha de código
    daquela função muda.
  - Nova função:
    ```ts
    export async function approveContentVersion(
      rawContentId: string,
      number: number,
      input: ApproveContentVersionInput,
      actor: ContentActor,
      db: ContentVersionClient = prisma,
    ): Promise<ContentVersionDetail> {
      return db.$transaction(async (tx) => {
        // 1 (DEC-033-001 herdada): lock da linha do RawContent pai, 1ª chamada.
        const locked = await tx.$queryRaw<Array<{ id: string }>>`
          SELECT id FROM raw_contents WHERE id = ${rawContentId} FOR UPDATE
        `;
        if (locked[0] === undefined) {
          throw new NotFoundError('Conteúdo bruto não encontrado.');
        }

        // 2 (FR-032-018): alcance por autoria/soft-delete.
        await assertRawContentReachable(rawContentId, actor, tx);

        // 3: detalhe do RawContent (authorId, lastEditedById + 5 campos versionados).
        const rawContent = await tx.rawContent.findUniqueOrThrow({
          where: { id: rawContentId },
          select: RAW_CONTENT_VERSIONED_SELECT,
        });

        // 4: RuleBreakdown (6 campos versionados) — invariante herdada de F8/F2: uma
        // ContentVersion só existe se a RuleBreakdown existia no fechamento, e não há
        // rota de remoção de RuleBreakdown nesta fatia nem em nenhuma anterior.
        const ruleBreakdown = await tx.ruleBreakdown.findUniqueOrThrow({
          where: { rawContentId },
          select: RULE_BREAKDOWN_VERSIONED_SELECT,
        });

        // 5 (FR-032-003): Versão vigente.
        const vigente = await tx.contentVersion.findFirst({
          where: { rawContentId },
          orderBy: { number: 'desc' },
          select: { ...CONTENT_VERSION_DETAIL_SELECT, contentSnapshot: true },
        });
        if (vigente === null) {
          throw new NotFoundError('Não há Versão para aprovar.');
        }

        // 6 (FR-032-014/AC-032-015): duplo travamento — número informado.
        if (vigente.number !== number) {
          throw new ConflictError('O número informado não é mais o da Versão vigente.');
        }

        // 7 (FR-032-017, checagem antecipada — a garantia real é o passo 11).
        if (vigente.approvedById !== null) {
          throw new ConflictError('Esta Versão já foi aprovada.');
        }

        // 8 (FR-032-004/A-032-002, NFR-032-002 — mensagem genérica, nunca revela QUAL
        // identidade bateu): segregação de funções.
        const producerIds = new Set([vigente.authorId, rawContent.authorId, rawContent.lastEditedById]);
        if (producerIds.has(actor.id)) {
          throw new ForbiddenError('Você não tem permissão para aprovar esta Versão.');
        }

        // 9 (FR-032-013, herdado de A-005-008): fonte normativa lida do contentSnapshot
        // da Versão vigente — o dado JÁ VERSIONADO, nunca o RawContent ao vivo.
        const snapshot = vigente.contentSnapshot as unknown as VersionedContentFields;
        if (snapshot.sourceType === null || snapshot.sourceCitation === null) {
          throw new ConflictError('Falta fonte normativa registrada nesta Versão.');
        }

        // 10 (FR-032-015/AC-032-016): sinal de alteração combinado (conteúdo OU Tira).
        const current = toVersionedContentFields(rawContent, ruleBreakdown);
        const altered = await resolveAlterationSignal(rawContentId, current, vigente, tx);
        if (altered) {
          throw new ConflictError(
            'O conteúdo ou a Tira mnemônica foram alterados após o fechamento desta Versão.',
          );
        }

        // 11 (DEC-033-009): escrita condicional — a garantia REAL de exatamente 1.
        const now = new Date();
        const result = await tx.contentVersion.updateMany({
          where: { id: vigente.id, approvedById: null },
          data: { approvedById: actor.id, approvedAt: now },
        });
        if (result.count !== 1) {
          throw new ConflictError('Esta Versão já foi aprovada.');
        }

        // 12 (DEC-033-008): sempre CONCLUSAO direto — ÚLTIMA chamada do corpo.
        await recordProductionStageEvent(tx, {
          rawContentId,
          stageType: 'APROVACAO_VERSAO',
          transitionType: 'CONCLUSAO',
          actorId: actor.id,
          now,
        });

        return {
          id: vigente.id,
          rawContentId,
          number: vigente.number,
          legislativeClosureDate: vigente.legislativeClosureDate,
          authorId: vigente.authorId,
          closedAt: vigente.closedAt,
          approvedById: actor.id,
          approvedAt: now,
        };
      });
    }
    ```
    Import novo: `ConflictError`/`ForbiddenError` de `../../http/errors` (`ForbiddenError`
    já importado; acrescenta `ConflictError`), `resolveAlterationSignal` (TASK-033-002,
    mesmo arquivo — sem import cross-file) e `type ApproveContentVersionInput` de
    `./content-versions.schema`.
- `mnemonicos-backend/src/modules/content-versions/content-versions.routes.ts` (estende):
  `POST /contents/:id/versions/:number/approve` — `verifyOrigin` como 1º handler +
  `requireRole('POST', '/contents/:id/versions/:number/approve', 'ADMIN')` (**sem**
  `'EDITOR'` — FR-032-016, deny-by-default: nunca copiar a lista `'EDITOR', 'ADMIN'` das 2
  rotas irmãs por reflexo). `actorOf(req)` reusado (já existente no arquivo). Responde
  `200` (atualiza um recurso já existente, ao contrário do `201` de `POST
  /contents/:id/versions`, que cria uma Versão nova):
  ```ts
  contentVersionsRoutes.post(
    '/contents/:id/versions/:number/approve',
    verifyOrigin,
    requireRole('POST', '/contents/:id/versions/:number/approve', 'ADMIN'),
    async (req, res) => {
      const { id, number } = approveContentVersionParamsSchema.parse({
        id: req.params.id,
        number: req.params.number,
      });
      const input = approveContentVersionSchema.parse(req.body);
      const approved = await approveContentVersion(id, number, input, actorOf(req));
      res.status(200).json(approved);
    },
  );
  ```
- `mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts` (estende —
  molde `describe('TASK-029-002 — as 2 rotas de Versão editorial...')`, linhas 583-593):
  novo `describe('TASK-033-003 — a rota de aprovação sob a barreira (topologia
  adversarial)')` — lição ativa "[Segurança] 'Declarado' não é 'autorizado'; prova de gate
  de autz exige topologia adversarial": a rota nova compartilha o PREFIXO
  `/contents/:id/versions` com as 2 rotas irmãs já `{EDITOR, ADMIN}` — o risco adversarial
  específico é herdar essa declaração por cópia. Confirma (a)
  `REGISTRY.get('POST /contents/:id/versions/:number/approve')` é EXATAMENTE
  `new Set<UserRole>(['ADMIN'])` — nunca `{EDITOR, ADMIN}`; (b) com sessão de EDITOR → 403
  (a suíte genérica de `describe('AC-002-011 / AC-002-012...')`, linhas 234-256, já cobre
  isso automaticamente por derivar de `REGISTRY`/`isAdminOnly` — este teste é a
  confirmação ESPECÍFICA de que a rota entrou nesse conjunto, não uma duplicata); (c) sem
  sessão → 401 (mesma cobertura automática de `describe('AC-002-010...')`, confirmação
  específica); (d) com sessão de ADMIN elegível (não produtor) → NÃO 403 (chega ao
  service — pode devolver 200, 404 ou 409 dependendo do fixture, nunca 401/403), provando
  que ADMIN não é bloqueado pela barreira.
- `mnemonicos-backend/tests/unit/content-versions.service.guard-order.test.ts` (estende):
  novo `describe('approveContentVersion — ordem das guardas (TASK-033-003, estrutural)')`,
  mesmo `extractFunctionBody` já genérico do arquivo (âncora
  `'export async function approveContentVersion'`): (a) `tx.$queryRaw`/`FOR UPDATE` é a
  1ª chamada, ANTES de `assertRawContentReachable`; (b) `ruleBreakdown.findUniqueOrThrow(`
  ANTES de `contentVersion.findFirst(`; (c) `contentVersion.findFirst(` ANTES da 1ª
  comparação `producerIds.has(`; (d) `producerIds.has(` ANTES de
  `resolveAlterationSignal(`; (e) `resolveAlterationSignal(` ANTES de
  `contentVersion.updateMany(`; (f) `recordProductionStageEvent(` é a ÚLTIMA chamada,
  depois de `contentVersion.updateMany(`.
- `mnemonicos-backend/tests/unit/content-versions.schema.test.ts` (estende): novo
  `describe('approveContentVersionSchema')` — `legalCheckConfirmed`/
  `pedagogicalCheckConfirmed` com `false`, ausente ou string ⇒ `ZodError` (3 casos por
  campo — 6 no total); os 2 `true` ⇒ aceito. Novo `describe('approveContentVersionParamsSchema')`
  — `number` como string numérica (`'3'`, vindo de `req.params`) ⇒ coagido para `3`
  (number); `number: '0'`/`'-1'`/`'abc'` ⇒ `ZodError`; `id` não-uuid ⇒ `ZodError`.
- `mnemonicos-backend/tests/integration/content-versions.service.integration.test.ts`
  (estende — molde dos `describe` já existentes no mesmo arquivo): novos blocos, cada um
  com fixture PRÓPRIA (`createUser`/`createRawContent`/`seedRuleBreakdown` +
  `testPrisma.rawContent.update` para setar `sourceType`/`sourceCitation`, ausentes por
  padrão em `createRawContent` — necessário para que a aprovação passe a barreira de
  FR-032-013 nos cenários de sucesso):
  - AC-032-001 (parte ESCRITA — a parte de leitura no histórico é TASK-033-004):
    ADMIN elegível (não produtor) aprova com as 2 confirmações → `approvedById`/
    `approvedAt` gravados, `ProductionStageEvent` `APROVACAO_VERSAO`/`CONCLUSAO` emitido.
  - AC-032-002 (FR-032-002): 3 sub-casos (`legalCheckConfirmed: false`,
    `pedagogicalCheckConfirmed` ausente, os 2 `false`) via `approveContentVersionSchema.parse`
    direto (schema, não o service) — `ZodError`, nenhuma leitura do service acontece.
  - AC-032-003 (FR-032-003): `RawContent` sem nenhuma Versão fechada → `NotFoundError`
    'Não há Versão para aprovar.'.
  - AC-032-004 (FR-032-004, NFR-032-002) + AC-032-023 (FR-032-004) — **prova COMPORTAMENTAL
    própria** (lição ativa "[Segurança] Guarda reusada continua exigindo prova
    comportamental própria por novo método de escrita" — `approveContentVersion` é
    `approveContentVersion` é escrita NOVA sobre `content_versions`, mesmo reusando
    `assertRawContentReachable`): 3 sub-casos, 1 por identidade produtora (quem fechou =
    autor da Versão vigente; `RawContent.authorId`; `RawContent.lastEditedById`, setado
    via `updateRawContent` — importado de `contents.service.ts` — depois do fechamento) →
    `ForbiddenError` com a MESMA mensagem literal nos 3 (`'Você não tem permissão para
    aprovar esta Versão.'`), nenhuma das 3 revela qual identidade bateu, nenhum
    `approvedById` gravado.
  - AC-032-005 (FR-032-005) — **prova de ausência, universo = `src` inteiro** (lição
    ativa "[Testes] Prova de ausência por leitura de texto-fonte precisa declarar o
    universo lido": estende o mesmo grep de AC-028-006/TASK-029-002, universo já correto
    lá — só ACRESCENTA os 2 nomes de coluna novos ao padrão): `grep -rnE
    "contentVersion\.(update|updateMany|delete|deleteMany)" src | grep -vE ':\s*(//|\*)'`
    (cwd `mnemonicos-backend`) → EXATAMENTE 1 ocorrência (a `updateMany` desta própria
    TASK, passo 11) — nenhuma outra função em `src` grava/apaga um `ContentVersion`, e
    nenhuma tem `where` sem `approvedById: null` (leitura confirma o `where` completo da
    única ocorrência).
  - AC-032-006 — estrutural, sem teste PRÓPRIO nesta TASK (a Versão nova nasce com
    `approvedById: null` pela ausência de escrita em `closeContentVersion`, F8 intocado);
    o comportamento OBSERVÁVEL (leitura mostrando "não aprovada") é TASK-033-004.
  - AC-032-008 (FR-032-009): aprovação bem-sucedida grava exatamente 1
    `ProductionStageEvent` (`stageType: 'APROVACAO_VERSAO'`, `transitionType: 'CONCLUSAO'`
    — MESMA na 1ª chamada, nunca `decideStageTransition`, DEC-033-008).
  - AC-032-014 (FR-032-013): Versão vigente com `sourceType`/`sourceCitation` `null` no
    `contentSnapshot` (fechada ANTES de a fonte ser preenchida, ou nunca preenchida) →
    `ConflictError` 'Falta fonte normativa registrada nesta Versão.'.
  - AC-032-015 (FR-032-014) — corrida: fecha Versão 3, tenta aprovar informando
    `number: 3`, mas ANTES da chamada uma Versão 4 é fechada por outro ator (simulado
    sequencialmente, sem `Promise.all` — é uma corrida de ESTADO, não de concorrência real
    de escrita) → `ConflictError` 'O número informado não é mais o da Versão vigente.'.
  - AC-032-016 (FR-032-015): 2 sub-casos — conteúdo alterado após fechamento (campo
    versionado do `RawContent` mudado via `updateRawContent` depois do `closeContentVersion`)
    e Tira alterada após fechamento (evento `TIRA_MNEMONICA` emitido depois do fechamento,
    via `recordProductionStageEvent` direto no fixture ou via `tira.service.ts` real) →
    `ConflictError` nos 2, mesma mensagem.
  - AC-032-017 (FR-032-016): coberto pela topologia adversarial de
    `route-authz-matrix.integration.test.ts` acima — não duplicado aqui (nível de
    service não distingue papel do ator via HTTP, `requireRole` já barra antes de chegar
    ao service).
  - AC-032-018 (FR-032-017, NFR-032-001) — **prova de CONCORRÊNCIA REAL** (lição ativa
    "[Segurança] Corrida (TOCTOU) só se fecha com prova de CONCORRÊNCIA real contando
    linhas no fim"): 2 chamadas de `approveContentVersion` para a MESMA Versão vigente,
    por 2 ADMINs elegíveis DISTINTOS, disparadas de fato em paralelo (`Promise.all`, nunca
    sequenciais) → resultado esperado é exatamente 1 sucesso e 1 `ConflictError`
    ('Esta Versão já foi aprovada.'), NUNCA os 2 sucessos; ao final, exatamente 1 linha de
    `ContentVersion` com `approvedById` não-nulo e exatamente 1 `ProductionStageEvent`
    `APROVACAO_VERSAO` para aquele `rawContentId` (contagem, nunca `instanceof`/mensagem
    de erro como oráculo primário). 2º sub-caso, sequencial (NFR-032-001 "nunca
    sobrescrita"): após 1ª aprovação bem-sucedida por ADMIN A, uma 2ª tentativa por ADMIN
    B elegível → `ConflictError`, e `approvedById` da Versão permanece IGUAL a A (nunca
    sobrescrito para B).
  - AC-032-019 (FR-032-018): `RawContent` soft-deletado (`deletedAt` setado) com Versão
    fechada → `NotFoundError` (mesma mensagem/guarda de `assertRawContentReachable` já
    usada por qualquer outra operação).
  - **Precedência entre guardas — um caso por PAR de ramos que pode coincidir** (lição
    ativa "[Testes] Árvore de decisão com precedência: um caso por PAR de ramos que
    coincide" — os 7 guards sequenciais dos passos 5-10 formam exatamente essa árvore):
    (i) número mismatch (6) ∧ já aprovada (7): Versão vigente já aprovada, ator informa um
    número MAIS ANTIGO (não o vigente) → mensagem de NÚMERO (6 vence, nunca "já
    aprovada"); (ii) já aprovada (7) ∧ segregação (8): Versão vigente já aprovada POR
    OUTRO ator, o ator da 2ª tentativa é ele próprio um produtor → mensagem de "já foi
    aprovada" (7 vence, nunca a de permissão); (iii) segregação (8) ∧ fonte ausente (9):
    ator é produtor E a Versão não tem fonte normativa → mensagem de PERMISSÃO (8 vence,
    nunca a de fonte); (iv) fonte ausente (9) ∧ sinal de alteração (10): Versão sem fonte
    normativa E com sinal de alteração aceso → mensagem de FONTE (9 vence, nunca a de
    alteração). Cada caso nomeia no `it(...)` qual guard vence.
- `mnemonicos-backend/tests/integration/content-versions.routes.integration.test.ts`
  (estende — molde `describe('NFR-028-001/002...')` já existente no arquivo): novo
  `describe('POST /contents/:id/versions/:number/approve — camada HTTP')`: (a) fluxo feliz
  ponta a ponta (fixture com `sourceType`/`sourceCitation` setados) → `200`, corpo com
  `approvedById`/`approvedAt` preenchidos; (b) `verifyOrigin` recusa origem forjada
  (`Origin` diferente do allowlist) → `403`, mesmo padrão já provado para as rotas
  irmãs (topologia adversarial NÃO duplicada aqui — só confirma que o handler novo
  também passa por `verifyOrigin`, por leitura da ordem dos middlewares, mais 1 caso
  HTTP); (c) NFR-032-001/002 fail-secure na camada HTTP: `recordProductionStageEvent`
  rejeitando (`jest.spyOn` no MÓDULO `production-events.service`, nunca no client Prisma —
  mesmo padrão já usado pelo teste de `closeContentVersion` acima no arquivo) → `500`
  genérico, sem detalhe da exceção, e `approvedById` da Versão permanece `null` (rollback
  completo).
- **Herdado do gate 8 da Wave 1 (security-engineer, notas N1/N2/N6 — decisão 4.140)**:
  - (N1) `approveContentVersion` resolve a Versão vigente pelo PRÓPRIO `rawContentId` do
    path (`where: { rawContentId }`, `orderBy: { number: 'desc' }`) e passa a
    `resolveAlterationSignal` o `current` lido DENTRO da mesma `$transaction`, depois do
    `FOR UPDATE` — nunca uma Versão/leitura vinda de fora da transação. Caso de teste em
    `content-versions.service.integration.test.ts`: 2 Conteúdos brutos, cada um com
    Versão fechada; aprovar pelo `rawContentId` de A com o `number` da Versão de B (que
    não existe em A) → recusa de número (FR-032-014), `approvedById` das 2 Versões
    permanece `null`.
  - (N2) Fail-secure do sinal: `resolveAlterationSignal` rejeitando (o `productionStageEvent`
    do client injetado rejeita) → a aprovação NÃO é gravada (`approvedById` permanece
    `null`), o erro sobe — nenhum `catch → false`/`?? false` em torno da chamada. Caso de
    teste na mesma suíte de integração (injetar um `db` cujo `productionStageEvent.findFirst`
    rejeita dentro da transação, ou `jest.spyOn` no método do `tx` — nunca no client raiz,
    lição ativa sobre espionar o client Prisma errado numa transação).
  - (N6) Todo `select` que expõe o estado de aprovação lista `approvedById`/`approvedAt`
    explicitamente — nunca `include: { approver: true }` (User carrega `passwordHash`).
- **Guarda de edição pós-fechamento** (furo no plano do gate 8 da Wave 2, DEC-033-006
  emendada, 2026-09-27): `updateRawContent` carimba `lastEditedById`/`lastEditedAt` mesmo
  sem mudar campo versionado, apagando o último editor de antes do fechamento. No passo
  8, logo depois da comparação de identidades: `rawContent.lastEditedAt !== null &&
  rawContent.lastEditedAt > vigente.closedAt` ⇒ recusa (fail-secure — o último editor
  pré-fechamento deixou de ser conhecido), `ConflictError` com texto acionável que NÃO
  revela identidade: "O conteúdo foi editado depois do fechamento desta versão. É
  preciso fechar uma nova versão para aprovar." (`lastEditedAt` já é visível ao ADMIN
  pelo carimbo de última alteração, SPEC-005 — não é vazamento). `lastEditedAt` entra no
  `select` do passo 3.
  **Emenda 2 (re-verificação do gate 8 W2, vetor concorrente — DEC-033-006 emenda 2)**: a
  guarda ordena pelo BANCO, não por relógio — recusa (mesma mensagem) quando existe
  `ProductionStageEvent` `CONTEUDO_BRUTO` do `rawContentId` com `sequence` maior que a do
  último `VERSAO_EDITORIAL` dele; a comparação por `lastEditedAt`/`closedAt` sai.
  Nenhuma mudança em `contents.service.ts`.
- **Espelho de tipos no mesmo diff** (furo no plano achado nesta TASK, 2026-09-27 —
  ajuste localizado do Tech Lead: estender `ContentVersionDetail` com `approvedById`/
  `approvedAt` quebra `tests/unit/contents-frontend-contract.test.ts`, que compara o
  payload HTTP real com o tipo espelhado; o CLAUDE.md do workspace exige os 2 lados no
  mesmo diff): `mnemonicos-backend/src/domain/types.ts` e
  `mnemonicos-frontend/src/types/domain.ts` — `interface ContentVersion` ganha
  `approvedById: string | null` e `approvedAt` (`Date | null` no backend, `string |
  null` no frontend, mesma convenção de `closedAt`); o `describe` de paridade
  `ContentVersion` de `contents-frontend-contract.test.ts` passa a listar os 2 campos
  nos 2 lados. SEM `validApprovalForExport` (é de TASK-033-004). Frontend: qualquer
  fixture/objeto `ContentVersion` que o typecheck acusar ganha os 2 campos com `null`.
- **Fixture compartilhada** (fora de escopo do gate 7 da Wave 1 — a fixture de 11 campos de
  `VersionedContentFields` já existe duplicada em 2 testes e as TASK-033-003/004/005 vão
  precisar dela): criar um builder em `tests/support/` (siga o padrão de nomenclatura dos
  builders que já existem lá — confira por `ls mnemonicos-backend/tests/support` antes)
  e usá-lo nos testes novos desta TASK. Migrar os 2 testes existentes que duplicam a
  fixture é opcional (se tocados, suíte deles verde).

### Não inclui

- Leitura estendida de `listContentVersions` (`validApprovalForExport`) — TASK-033-004
  (embora esta TASK já extenda `CONTENT_VERSION_DETAIL_SELECT`/`ContentVersionDetail` com
  `approvedById`/`approvedAt`, o campo COMPUTADO `validApprovalForExport` nasce só em
  TASK-033-004, que também acrescenta esse campo ao retorno desta função — ver Escopo de
  TASK-033-004).
- Extensão de `publication.service.ts`/`pdf-composer.ts` — TASK-033-005.
- O campo computado `validApprovalForExport` e seu espelho nos 2 `domain.ts` —
  TASK-033-004 (quem o cria no payload espelha, no mesmo diff).
- `store/api.ts` (mutation de aprovação) e painel de aprovação — TASK-033-006/007.
- Qualquer rota `PATCH`/`PUT`/`DELETE` sobre Versão ou aprovação — proibido por
  FR-032-005 em toda a fatia (a ausência é o que a prova de AC-032-005 confirma).

## Critérios de pronto

- [ ] Testes cobrem AC-032-001 (parte escrita), AC-032-002, AC-032-003, AC-032-004,
      AC-032-005, AC-032-008, AC-032-014, AC-032-015, AC-032-016, AC-032-018, AC-032-019,
      AC-032-023 — verificação executável: `npm --prefix mnemonicos-backend run
      test:integration -- --testPathPatterns=content-versions.service.integration.test.ts`
      → `OK (N tests)`.
- [ ] AC-032-017 confirmado pela topologia adversarial (ver Inclui) — verificação
      executável: `npm --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=route-authz-matrix.integration.test.ts` → `OK (N tests)`.
- [ ] Testes cobrem a camada HTTP (fluxo feliz + `verifyOrigin` + fail-secure) —
      verificação executável: `npm --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=content-versions.routes.integration.test.ts` → `OK (N tests)`.
- [ ] Guarda estrutural (ordem do corpo de `approveContentVersion`) — verificação
      executável: `npm --prefix mnemonicos-backend test --
      content-versions.service.guard-order.test.ts` → `OK (N tests)`. Fixada antes do
      código.
- [ ] `approveContentVersionSchema`/`approveContentVersionParamsSchema` — verificação
      executável: `npm --prefix mnemonicos-backend test -- content-versions.schema.test.ts`
      → `OK (N tests)`. Fixada antes do código.
- [ ] Precedência entre guardas (4 pares, ver Inclui) — cobertos pelos mesmos testes de
      integração acima, nomeados individualmente no relatório do Jest.
- [ ] **Comparação com o molde canônico** (decisão 4.307; lição ativa "[Código] Lista de
      Interface pública do PLAN é contrato mínimo, não gabarito de transcrição"): antes de
      commitar, `approveContentVersion` é conferida contra a FORMA REAL de
      `closeContentVersion` (mesmo arquivo, acima) — mesmo padrão de lock, mesmo padrão de
      `ContentVersionClient`, nomes de `select` reusados (nunca duplicados) — e a
      declaração da rota nova contra `contentVersionsRoutes.post`/`.get` já existentes
      (mesmo `actorOf`, mesma ordem `verifyOrigin` → `requireRole`).
- [ ] `ROUTE_ROLES.get('POST /contents/:id/versions/:number/approve')` é EXATAMENTE
      `{ADMIN}` — supplementar à prova real (topologia adversarial de
      `route-authz-matrix.integration.test.ts`, AC-032-017 acima): `grep -n
      "requireRole('POST', '/contents/:id/versions/:number/approve'"
      mnemonicos-backend/src/modules/content-versions/content-versions.routes.ts | grep
      -vE ':\s*(//|\*)'` (a partir da raiz do workspace) → 1 ocorrência, sem `'EDITOR'`
      na mesma linha.
- [ ] Herança N1 do gate 8 W1 (Versão resolvida pelo `rawContentId` do path, `current`
      lido na mesma transação): caso "number de Versão de outro Conteúdo bruto" →
      recusa de número, 0 aprovações gravadas nas 2 Versões — mesmo comando da suíte
      `content-versions.service.integration.test.ts` acima → `OK (N tests)`, com o caso
      nomeado no relatório do Jest.
- [ ] Herança N2 do gate 8 W1 (fail-secure do sinal): `resolveAlterationSignal`
      rejeitando → aprovação não gravada, erro propaga — mesmo comando acima, caso
      nomeado. Mutante (em `git worktree add`, nunca na árvore principal): envolver a
      chamada em `.catch(() => false)` → o caso fica vermelho.
- [ ] Herança N6 do gate 8 W1: `grep -rn "approver" mnemonicos-backend/src | grep -vE
      ':\s*(//|\*)' | grep -v generated` (raiz do workspace) → 0 ocorrências de
      `include: { approver` em código de produção.
- [ ] Guarda de edição pós-fechamento (ver Inclui): caso de regressão do vetor do gate 8
      W2 — ADMIN W edita o texto normativo, ADMIN X fecha a Versão, um 3º ator faz
      `updateRawContent(id, {})` → W tenta aprovar → `ConflictError` com a mensagem
      acima, `approvedById` permanece `null` (motor real, suíte
      `content-versions.service.integration.test.ts` → `OK (N tests)`, caso nomeado).
      Vermelho antes da correção. Precedência (um caso por PAR adjacente que pode
      coincidir): identidade (8) ∧ edição pós-fechamento (8b) → vence 8 (403 genérico);
      8b ∧ fonte ausente (9) → vence 8b.
- [ ] Guarda 8b — vetor CONCORRENTE (emenda 2): interleaving forçado — `jest.spyOn` com
      espera (~400 ms) numa chamada DENTRO da transação de `closeContentVersion` (depois do
      lock), enquanto um 3º ator dispara `updateRawContent(id, {})` que fica bloqueado e
      commita depois do fechamento → W tenta aprovar → recusa, `approvedById` null (motor
      real, caso nomeado na suíte `content-versions.service.integration.test.ts`). Par:
      mutante que volta à comparação `lastEditedAt > closedAt` (em `git worktree add`) →
      este caso vermelho; o caso sequencial e o legítimo (fechada sem edição posterior →
      200) seguem verdes.
- [ ] Espelho de tipos (furo no plano, ver Inclui): `npm --prefix mnemonicos-backend test
      -- contents-frontend-contract.test.ts` → verde (hoje vermelho 8/9 com o diff desta
      TASK sem o espelho — é o vermelho que este item fecha); `npm --prefix
      mnemonicos-frontend run typecheck && npm --prefix mnemonicos-frontend test` → exit 0
      / sem vermelho novo contra a baseline do frontend.
- [ ] Fixture compartilhada: o builder de `VersionedContentFields` existe em
      `mnemonicos-backend/tests/support/` e é importado pelos testes novos desta TASK —
      `grep -rln "<nome do builder>" mnemonicos-backend/tests` → ≥ 1 arquivo de teste
      novo desta TASK (nome do builder é escolha do developer, registrado no report).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`), produção e teste — `npm --prefix mnemonicos-backend run lint` →
      exit 0.
- [ ] Aderência à stack/padrões da ficha e do perfil `node-22.md` — camadas
      schema→service→routes, toda escrita numa única `$transaction`, `select` explícito em
      toda leitura, `AppError`/subclasse para todo erro previsto, handler `async` sem
      `try/catch`.
- [ ] Segurança (gate 8): `security-engineer` revisa o diff completo — fatia sensível
      (autorização nova + segregação de funções + regra de negócio central).
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-033-001 (PLAN §8) — corrida entre `approveContentVersion` e `closeContentVersion`
  no mesmo `RawContent` (ex.: aprovar a Versão 3 enquanto outro fecha a Versão 4): as duas
  tomam `SELECT ... FOR UPDATE` na mesma linha do `RawContent` pai, serializando por
  construção (DEC-033-001 herdada) — não testado por concorrência real NESTA TASK (o
  fixture de AC-032-015 simula a corrida por ESTADO sequencial, suficiente para o AC; a
  concorrência real de ESCRITA entre os 2 verbos fica como risco aceito, mesma régua do
  PLAN).
- TRISK-033-005 (PLAN §8) — RISK-032-005 (contas ADMIN fantoche) segue sem controle
  técnico nesta TASK — herdado, sem mitigação nova.
- A checagem de segregação (passo 8) usa um `Set` com as 3 identidades — `null` (quando
  `rawContent.lastEditedById` nunca foi setado) nunca entra no `Set` como valor útil
  porque `actor.id` é sempre uma string não-nula; um `Set` contendo `null` não corresponde
  a nenhum `actor.id` real, então o comportamento é seguro por construção, sem checagem
  extra.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-27T19:24:02-0300
**Data conclusão**: 2026-09-27T21:58:16-0300
**Commit SHA**: 2e9998c (+ e9a1360, 563f350, 49489c9 — retries dos gates 1/7/8/11; frontend 053a6ab; âncoras renumeradas 5984073/94711c9)
**Jira**: KAN-154

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 2, após 2 retries: CWE-284 e CWE-367 fechados) — security-engineer
- [x] Comportamento (gate 9): consolidado FEAT-032-001 — carregador: Roteiro do gate 9 de TASK-033-007 (Wave 5), que exercita aprovação, recusa de autoaprovação e estados da UI ponta a ponta
