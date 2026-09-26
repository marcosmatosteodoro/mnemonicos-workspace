# TASK-029-002: Fechamento de Versão editorial e histórico — backend completo

**Slug**: producao-material
**Pertence a**: PLAN-029
**Realiza (FRs)**: FR-028-001, FR-028-002, FR-028-003, FR-028-004, FR-028-005, FR-028-007
**Funcionalidade**: FEAT-028-001 (primária)
**Componente**: COMP-029-004 (principal), COMP-029-002, COMP-029-005, COMP-029-006, COMP-029-013
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-029-001
- **Bloqueia**: TASK-029-004

## Contexto

Fatia sensível (princípio 8: autorização + regra de negócio central + migração de dado já
aplicada na Wave 1): EDITOR/ADMIN fecha uma Versão editorial explícita de um Conteúdo bruto
já revisado (número sequencial, Data de fechamento legislativo declarada, autor e timestamp
técnico do fechamento, snapshot dos campos versionados), e qualquer EDITOR/ADMIN alcançável
lê o histórico completo, em ordem. Escrita estritamente append-only — nenhuma rota/função
permite editar ou apagar uma Versão já fechada (FR-028-004). Território e precedentes:
`docs/producao-material/MAP.md` (`assertRawContentReachable`/`scopeWhere`, guarda de
2 passos de `Contrast`, corrida TOCTOU de `removeVisualAssociation`) e PLAN-029 §3
(COMP-029-002/004/005/006), §6 (DEC-029-001/002/004/005/006).

**Furo verificado pela cadeia do dado (princípio 6) e corrigido nesta TASK**: DEC-029-005
exige que o evento de etapa nasça sempre como `CONCLUSAO` direto, **nunca** via
`decideStageTransition` — mas `recordProductionStageEvent` (`production-events.service.ts`,
leitura direta confirmada) SEMPRE calcula a transição internamente por histórico
(`decideStageTransition`), sem parâmetro de override. Cumprir DEC-029-005 à risca exige
estender essa função compartilhada (Escopo > Inclui abaixo), não só chamá-la — sem a
extensão, a 1ª chamada de `VERSAO_EDITORIAL` seria decidida como `ABERTURA` (0 eventos
prévios do par), violando a DEC.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/production-events/production-events.service.ts`
  (estende): `ProductionStageEventInput` ganha campo opcional
  `transitionType?: ProductionEventTransition`; `recordProductionStageEvent` usa esse valor
  DIRETO quando informado — pulando inteiramente a leitura de histórico
  (`tx.productionStageEvent.findMany`) e `decideStageTransition` (DEC-029-005) — e preserva
  o comportamento existente (decisão automática ABERTURA/CONCLUSAO/RETRABALHO por
  histórico) quando o campo é omitido. Todos os chamadores existentes
  (`contents.service.ts`, `tira.service.ts`, `contrasts.service.ts`,
  `flashcards.service.ts`, `visual-associations.service.ts`, `publication.service.ts`)
  continuam sem alteração — parâmetro novo é opcional, retrocompatível.
- `mnemonicos-backend/src/modules/content-versions/content-versions.schema.ts` (novo):
  `closeContentVersionSchema` — `legislativeClosureDate: z.iso.date(...)` recusada se
  `> hoje` (comparação de string ISO `YYYY-MM-DD`, DEC-029-006 — nunca de timestamp: "hoje"
  é lido de `new Date().toISOString().slice(0, 10)` no momento do `parse`, sem parâmetro de
  `now` injetável — 1º Zod schema do projeto dependente de tempo; testável por
  `jest.useFakeTimers().setSystemTime(...)` no teste unitário, sem precisar alterar a
  assinatura do schema nem da rota). Sem campo de número, autor ou timestamp técnico no
  input (todos calculados/derivados no service). Tipo derivado: `CloseContentVersionInput`.
  Reusa `rawContentIdParamSchema` de `../contents/contents.schema.ts` para o `:id` da rota
  (nenhum `:versionId` na URL — esta fatia não expõe leitura/edição por Versão individual).
- `mnemonicos-backend/src/modules/content-versions/content-versions.service.ts` (novo):
  - `CONTENT_VERSION_DETAIL_SELECT`/`ContentVersionDetail` — exatamente os 6 dados
    imutáveis (`id`, `rawContentId`, `number`, `legislativeClosureDate`, `authorId`,
    `closedAt`), **nunca** `contentSnapshot` (dado interno de verificação, jamais exposto à
    API — DEC-029-003).
  - `type ContentVersionClient = Pick<typeof prisma, 'contentVersion' | 'rawContent' |
    'ruleBreakdown' | '$transaction'>` (mesmo padrão de `ContrastClient`).
  - `closeContentVersion(rawContentId, input, actor, db = prisma)` — dentro de
    `db.$transaction`, NESTA ORDEM (DEC-029-004/DEC-029-001):
    1. `tx.$queryRaw` `SELECT id FROM raw_contents WHERE id = ${rawContentId} FOR UPDATE`
       (molde `removeVisualAssociation`, `visual-associations.service.ts:340-342`) — 1º
       statement, ANTES de qualquer decisão; `undefined` (nenhuma linha) →
       `NotFoundError('Conteúdo bruto não encontrado.')`.
    2. `assertRawContentReachable(rawContentId, actor, tx)` (importado de
       `contents.service.ts`, reusado sem reescrita) — resolve inexistente/fora de
       alcance/soft-deleted na mesma ordem e mensagens já estabelecidas por F2.
    3. Lê os campos versionados atuais de `RawContent` (`authorId`, `rawText`,
       `radarClass`, `sourceType`, `sourceCitation`, `sourceUrl`) via `select` explícito —
       reaproveita a MESMA linha travada no passo 1 (nenhuma 3ª leitura de `RawContent`
       necessária além desta, que já é a leitura de detalhe); checagem explícita
       `actor.role === 'ADMIN' || rawContent.authorId === actor.id`, senão
       `ForbiddenError('Você não tem permissão para fechar uma versão deste conteúdo.')`
       (DEC-029-001 — defesa em profundidade: para EDITOR, `assertRawContentReachable`
       já teria barrado um `rawContentId` de outro autor com `NotFoundError` antes deste
       ponto; este 2º guard é o mesmo predicado, citado explicitamente pela DEC, e cobre
       ADMIN sempre passando).
    4. Lê `RuleBreakdown` do mesmo `rawContentId` (`select`: `concept`, `action`, `object`,
       `condition`, `exception`, `essence`) — `null` →
       `NotFoundError('Quebra da regra precisa existir antes do fechamento.')` (FR-028-003/
       AC-028-004), sem `INSERT` nenhum.
    5. Calcula o próximo `number`: `tx.contentVersion.findFirst({ where: { rawContentId },
       orderBy: { number: 'desc' }, select: { number: true } })` → `(último?.number ?? 0) +
       1` — dentro da MESMA transação, depois do lock do passo 1 (serializa fechamentos
       concorrentes do mesmo `rawContentId`, DEC-029-004).
    6. Monta `contentSnapshot` — objeto literal com os 5 campos de `RawContent` + 6 de
       `RuleBreakdown` lidos nos passos 3/4 (nenhuma leitura adicional).
    7. `tx.contentVersion.create({ data: { rawContentId, number, legislativeClosureDate:
       new Date(input.legislativeClosureDate), authorId: actor.id, contentSnapshot },
       select: CONTENT_VERSION_DETAIL_SELECT })`.
    8. `recordProductionStageEvent(tx, { rawContentId, stageType: 'VERSAO_EDITORIAL',
       transitionType: 'CONCLUSAO', actorId: actor.id, now: new Date() })` — usa o
       parâmetro novo do passo anterior (Inclui, item 1): sempre `CONCLUSAO` direto,
       nunca `decideStageTransition` (DEC-029-005).
    Qualquer falha nos passos 1-8 propaga sem gravar nada (fail-secure, NFR-028-001/002).
  - `listContentVersions(rawContentId, actor, db = prisma)` — `assertRawContentReachable`
    PRIMEIRO (DEC-029-002 herdada, mesma guarda comum de alcance, **sem** restrição
    adicional por `authorId` da Versão — um EDITOR que alcança o próprio `RawContent` vê
    TODAS as Versões nele, mesmo as fechadas por um ADMIN), depois `db.contentVersion.
    findMany({ where: { rawContentId }, orderBy: { number: 'asc' }, select:
    CONTENT_VERSION_DETAIL_SELECT })` — o índice `@@unique([rawContentId, number])`
    (TASK-029-001) garante que o custo depende só de `N` (NFR-028-003/AC-028-012).
- `mnemonicos-backend/src/modules/content-versions/content-versions.routes.ts` (novo):
  `POST /contents/:id/versions` (`verifyOrigin` + `requireRole('POST',
  '/contents/:id/versions', 'EDITOR', 'ADMIN')`) chamando `closeContentVersion`; `GET
  /contents/:id/versions` (`requireRole('GET', '/contents/:id/versions', 'EDITOR',
  'ADMIN')`, sem `verifyOrigin` — regra repo-wide de nunca exigi-lo em `GET`) chamando
  `listContentVersions`. `actorOf(req)` próprio do módulo (mesmo padrão de
  `contrasts.routes.ts:33-36`). Handlers `async` sem `try/catch`.
- `mnemonicos-backend/src/http/routes.ts`: `import { contentVersionsRoutes } from
  '../modules/content-versions/content-versions.routes'` + `apiRoutes.use(contentVersionsRoutes)`
  (árvore plana, ao lado de `contrastsRoutes`/`flashcardsRoutes`).
- `mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts` (estende —
  molde `describe('TASK-027-003 — as 4 rotas de Contraste...')`, linhas 452-508): novo
  `describe` com as 2 rotas de Versão, confirmando `ROUTE_ROLES` declarado `{EDITOR,
  ADMIN}` nas 2 e STUDENT recusado (403) nas 2 — a suíte deriva do array montado
  (`collectRoutes(apiRoutes)`), sem contagem hardcoded a alterar.

### Não inclui

- Carimbo de Versão no PDF exportado (`publication.service.ts`/`pdf-composer.ts`,
  `hasVersionedContentChanged`) — TASK-029-003.
- Tipos TS `ContentVersion` espelhados (backend/frontend), `store/api.ts`,
  `content-version-history.tsx`, wiring de tela — TASK-029-004.
- Migração Prisma, model `ContentVersion`, valor `VERSAO_EDITORIAL` do enum —
  TASK-029-001 (já entregue, esta TASK só consome).
- Qualquer rota/função de edição ou remoção de Versão — proibido por FR-028-004
  (AC-028-006): esta TASK expõe só `POST`/`GET`.

## Critérios de pronto

- [ ] **Guarda composta — prova estrutural** (molde `contrasts.service.guard-order.test.ts`,
      lição ativa "[Segurança] Guarda reusada continua exigindo prova comportamental
      própria por novo método de escrita" — prova estrutural é complemento de ORDEM, nunca
      substituto): `mnemonicos-backend/tests/unit/content-versions.service.guard-order.test.ts`
      (novo) confirma por leitura textual, dentro de `closeContentVersion`: (a) o
      `tx.$queryRaw` com `FOR UPDATE` é a 1ª chamada do corpo (universo = corpo da função,
      antes de qualquer outra chamada a `tx`/`assertRawContentReachable`); (b)
      `assertRawContentReachable(` aparece ANTES da leitura de detalhe de `RawContent` que
      alimenta a checagem `actor.role === 'ADMIN' ||`; (c) a leitura de `RuleBreakdown`
      acontece ANTES de `tx.contentVersion.findFirst`/`create`; (d)
      `recordProductionStageEvent(` é a ÚLTIMA chamada do corpo, depois de
      `tx.contentVersion.create`. Verificação executável: `npm --prefix mnemonicos-backend
      test -- content-versions.service.guard-order.test.ts` → `OK (4 tests)`.
- [ ] **Guarda composta — mutação contável, prova comportamental própria por método**
      (mesma lição — 2 métodos novos tocam a tabela `content_versions`, 2 provas, nenhuma
      herdada): fixture com 2 EDITORES (A e B), `RawContent` de A com Quebra da regra
      salva; para CADA um dos 2 métodos — `closeContentVersion` (B tenta fechar Versão no
      `rawContentId` de A) e `listContentVersions` (B tenta ler o histórico do
      `rawContentId` de A) — a chamada com o ator B é rejeitada com
      `NotFoundError('Conteúdo bruto não encontrado.')` (mesma mensagem de
      `assertRawContentReachable`), e nenhuma `ContentVersion` nova é criada (contagem
      antes/depois idêntica para `closeContentVersion`; para `listContentVersions`,
      nenhum item devolvido). Verificação executável: `npm --prefix mnemonicos-backend run
      test:integration -- --testPathPatterns=content-versions.service.integration.test.ts`
      → `OK (N tests)`.
- [ ] **Prova do eixo POSITIVO de DEC-029-002** (mesma régua do achado de `qa` em
      TASK-027-003 — só o eixo negativo não basta): `RawContent` de A com 2 Versões
      fechadas — 1 pelo próprio A, 1 por um ADMIN — `listContentVersions` chamado por A
      devolve AMBAS, em ordem de `number` asc, sem filtro por `authorId` da Versão.
      Falsificável: um filtro acidental por `authorId` da Versão adicionado no futuro faz
      este caso reprovar. Mesmo comando acima → `OK (N tests)`.
- [ ] Testes cobrem AC-028-001 (FR-028-001, FR-028-005 — parte backend): `RawContent` com
      Quebra da regra salva e nenhuma Versão fechada, autor fecha informando
      `legislativeClosureDate` → `closeContentVersion` devolve Versão `number: 1` com
      `authorId`/`closedAt`/a data informada; `listContentVersions` devolve essa Versão.
      Mesmo comando acima → `OK (N tests)`.
- [ ] Testes cobrem AC-028-002 (FR-028-001): `RawContent` com 2 Versões já fechadas, ADMIN
      fecha uma nova → `number: 3`, as 2 anteriores lidas diretamente permanecem
      INTOCADAS (mesmos `legislativeClosureDate`/`authorId`/`closedAt`/`contentSnapshot`
      de antes). Mesmo comando acima → `OK (N tests)`.
- [ ] Testes cobrem AC-028-003 (FR-028-002, NFR-028-001, NFR-028-002 — já coberto pela
      mutação contável acima) + confirmação de NÃO-VAZAMENTO: a mensagem de recusa de B
      é IGUAL, por igualdade literal, à recusa de um `rawContentId` aleatório inexistente
      (nunca distingue "existe mas não é seu" de "não existe"). Mesmo comando acima → `OK
      (N tests)`.
- [ ] Testes cobrem AC-028-004 (FR-028-003): `RawContent` alcançável SEM `RuleBreakdown`
      salva → `closeContentVersion` recusa com
      `NotFoundError('Quebra da regra precisa existir antes do fechamento.')`, nenhuma
      `ContentVersion` criada (contagem antes/depois). Mesmo comando acima → `OK (N
      tests)`.
- [ ] Testes cobrem AC-028-005 (FR-028-003): `RawContent` do próprio autor,
      soft-deleted (`deletedAt` setado) → `closeContentVersion` recusa com
      `NotFoundError('Conteúdo bruto foi removido.')` (mesma guarda/mensagem de
      `assertRawContentReachable` já usada por qualquer outra operação sobre um
      `RawContent` inalcançável), nenhuma `ContentVersion` criada. Mesmo comando acima →
      `OK (N tests)`.
- [ ] Testes cobrem AC-028-006 (FR-028-004) — **prova de ausência por leitura de
      texto-fonte, universo = SISTEMA INTEIRO** (lição ativa "[Testes] Prova de ausência
      por leitura de texto-fonte precisa declarar o universo lido, derivado do
      quantificador do critério" — AC-028-006/FR-028-004 dizem "nenhuma rota ou ação DO
      SISTEMA", quantificador total sobre `mnemonicos-backend/src` inteiro, não só os 2
      arquivos que esta TASK escreve — achado do `qa` em modo pré-código, escopo original
      corrigido): leitura de `content-versions.routes.ts` confirma que só `.post(`/`.get(`
      são chamados no Router (nenhum `.patch(`/`.put(`/`.delete(`). Verificação executável
      (grep recursivo sobre TODO `src/`, excluindo comentário — uma menção em
      docblock/`//` não deve fazer este critério falhar por engano nem mascarar uma
      chamada real, e uma chamada real em QUALQUER outro arquivo do backend, não só nos 2
      novos, precisa reprovar): `grep -rnE "contentVersion\.(update|updateMany|delete|
      deleteMany)" src | grep -vE ':\s*(//|\*)'` (cwd `mnemonicos-backend`) → 0
      ocorrências (exit 1 do grep, sem match) — cobre `content-versions.service.ts` e
      qualquer outro módulo presente ou futuro que toque o model.
- [ ] Testes cobrem AC-028-008 (FR-028-007) e DEC-029-005: fechamento de Versão registra o
      evento de etapa (`stageType: 'VERSAO_EDITORIAL'`) com `transitionType: 'CONCLUSAO'`
      MESMO na 1ª chamada do par (`listProductionStageEvents` confirma), sem exibir
      nenhuma tela nova a partir desse registro (nada nesta TASK monta rota de leitura de
      eventos). Falsificável: se `recordProductionStageEvent` ignorasse o override e
      decidisse por `decideStageTransition`, a 1ª chamada seria `ABERTURA` (0 eventos
      prévios do par) — o teste reprovaria. Mesmo comando acima → `OK (N tests)`.
- [ ] Testes cobrem a extensão de `production-events.service.ts` (Inclui, item 1) — novo
      bloco em `production-events.service.integration.test.ts` (molde linhas 27-56):
      confirma que `recordProductionStageEvent` com `transitionType` informado (a)
      NUNCA chama `tx.productionStageEvent.findMany` (spy/mock no `tx` injetado — sem
      histórico consultado) e (b) grava o `transitionType` EXATAMENTE como informado,
      inclusive quando a decisão automática produziria outro valor (fixture com histórico
      já contendo `CONCLUSAO`, override `ABERTURA` — o evento gravado é `ABERTURA`, não
      `RETRABALHO`). Comportamento existente (omitir o campo) segue coberto pelos testes
      já existentes no arquivo, sem alteração. Verificação executável: `npm --prefix
      mnemonicos-backend run test:integration --
      --testPathPatterns=production-events.service.integration.test.ts` → `OK (N tests)`.
- [ ] Testes cobrem NFR-028-001/002 (fail-secure, molde AC-026-023 de TASK-027-003):
      `jest.spyOn(productionEventsService, 'recordProductionStageEvent').mockRejectedValueOnce(...)`
      durante `closeContentVersion` — a transação inteira é revertida (nenhuma
      `ContentVersion` criada, contagem antes/depois idêntica) e a rota devolve erro
      genérico (500 sem detalhe do driver). Mesmo comando acima → `OK (N tests)`.
- [ ] **Corrida de numeração — prova de CONCORRÊNCIA REAL** (lição ativa "[Segurança]
      Corrida (TOCTOU) só se fecha com prova de CONCORRÊNCIA real contando linhas no fim;
      prova estrutural ou caso sequencial nunca fecha", DEC-029-004): 2 chamadas de
      `closeContentVersion` para o MESMO `rawContentId` disparadas de fato em paralelo
      (`Promise.all`, nunca sequenciais) — resultado esperado é exatamente 2
      `ContentVersion`s com `number` 1 e 2 (nunca as duas com `number: 1`, nunca erro de
      unicidade vazando ao chamador). Verificação executável: mesmo comando acima → `OK (N
      tests)`.
- [ ] **Data de fechamento legislativo — recusa futura, sem monotonicidade** (DEC-029-006):
      `mnemonicos-backend/tests/unit/content-versions.schema.test.ts` (novo), com
      `jest.useFakeTimers().setSystemTime(new Date('2026-09-26T23:00:00.000Z'))`: (a)
      `legislativeClosureDate: '2026-09-27'` (amanhã) → `parse` lança `ZodError`; (b)
      `'2026-09-26'` (hoje, MESMO dia — comparação de DATA, não de timestamp) → aceito;
      (c) `'2026-09-01'` (Versão anterior já fechada com data mais recente, ex.
      `'2026-09-15'`) → aceito, SEM checagem de monotonicidade (nenhuma leitura de Versão
      anterior no schema). Verificação executável: `npm --prefix mnemonicos-backend test --
      content-versions.schema.test.ts` → `OK (3 tests)`.
- [ ] **NFR-028-003/AC-028-012 (gate 10 — medição real via `withQueryProbe`,
      `tests/support/query-probe.ts` — mesma técnica de TRISK-010-001/TRISK-012-002,
      nunca EXPLAIN sobre seed sintético de volume: não há precedente disso no projeto —
      achado do `qa` em modo pré-código, a citação original a "mesma régua de
      `listRawContents`/F2" descrevia uma análise MANUAL registrada em comentário do
      schema, não um teste executável repetível)**: `listContentVersions` roda dentro de
      `withQueryProbe` contra um `RawContent` com N Versões fechadas (N pequeno, ex. 5,
      basta — o que se prova é ausência de N+1/varredura, não o plano do otimizador sob
      volume) — o array de queries devolvido tem EXATAMENTE 1 statement (nenhum round-trip
      por Versão, nenhuma consulta ao acervo inteiro). Falsificável: uma implementação que
      iterasse e buscasse cada Versão em loop reprovaria (>1 statement). Complementa (não
      substitui) a leitura estrutural: `grep -n "where: { rawContentId"
      src/modules/content-versions/content-versions.service.ts` confirma que o predicado é
      literalmente escopado por `rawContentId` (nunca uma consulta sem filtro seguida de
      filtro em memória).
- [ ] `ROUTE_ROLES` declara `{EDITOR, ADMIN}` para `POST /contents/:id/versions` e `GET
      /contents/:id/versions`; STUDENT recusado (403) nas 2 rotas — `route-authz-matrix`
      continua verde com as 2 chaves novas montadas (`collectRoutes`, sem asserção fixa a
      alterar). Verificação executável: `npm --prefix mnemonicos-backend run
      test:integration -- --testPathPatterns=route-authz-matrix.integration.test.ts` →
      `OK (N tests)`.
- [ ] **Comparação com o molde canônico** (decisão 4.307; lição ativa "[Código] Lista de
      Interface pública do PLAN é contrato mínimo, não gabarito de transcrição"): antes de
      commitar, `content-versions.schema.ts`/`content-versions.service.ts`/
      `content-versions.routes.ts` são conferidos contra a FORMA REAL de
      `contrasts.schema.ts`/`contrasts.service.ts`/`contrasts.routes.ts` (nomeação de
      client type análogo a `ContrastClient`, `actorOf` idêntico) e de
      `visual-associations.service.ts:340-342` (sintaxe exata do `$queryRaw ... FOR
      UPDATE`) — nunca contra a lembrança do nome; divergência de forma sem justificativa
      própria na TASK é achado do code-reviewer.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`), produção e teste — `npm --prefix mnemonicos-backend run lint` →
      exit 0.
- [ ] Aderência à stack/padrões da ficha e do perfil `node-22.md` — camadas
      schema→service→routes, toda escrita numa única `$transaction`, `select` explícito em
      toda leitura, `AppError`/subclasse para todo erro previsto.
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-029-002 (PLAN §8) — acoplamento novo entre `content-versions.service.ts` (dono de
  `hasVersionedContentChanged`, TASK-029-003) e `publication.service.ts` (consumidor);
  esta TASK não introduz esse acoplamento ainda (só a Wave 3 o faz), citado para registro.
- TRISK-029-005 (PLAN §8) — `listContentVersions` sem lock concorrente com um
  `closeContentVersion` em andamento no mesmo `RawContent`: sob READ COMMITTED, a leitura
  só enxerga a nova Versão após o commit (nunca dado parcial); aceito, mesma postura de
  `listContrasts`/`listVisualAssociations`.
- A checagem explícita `actor.role === 'ADMIN' || rawContent.authorId === actor.id`
  (passo 3 do Inclui) é, para EDITOR, redundante em teoria com o que
  `assertRawContentReachable` (passo 2) já impõe via `scopeWhere` — mas é literal de
  DEC-029-001 (Approved) e cobre defesa em profundidade caso `scopeWhere` mude no futuro;
  manter as duas, nunca remover uma por "parecer" duplicada.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-139

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
