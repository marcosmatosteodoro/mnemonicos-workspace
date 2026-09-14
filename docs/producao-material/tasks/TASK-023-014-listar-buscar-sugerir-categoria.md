# TASK-023-014: Listar, buscar e sugerir categoria da biblioteca visual (backend)

**Slug**: producao-material
**Pertence a**: PLAN-023
**Realiza (FRs)**: FR-022-010, FR-022-011, FR-022-012, FR-022-019, FR-022-025
**Funcionalidade**: FEAT-022-002 (primária), FEAT-022-003
**Componente**: COMP-023-005 (principal), COMP-023-006
**Wave**: 5
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch do EPICO MNEMORA STUDIO, Estrategia unica -- decisao 4.126: F5 e uma fatia do epico, nunca abre branch propria; a sessao ja fez o sync de largada nela)

**Padrão de commit**: Conventional Commits (`commit.convention: "conventional"`) — `feat:`.
**Framework de teste**: Jest 30 + ts-jest + `supertest` — `tests/integration/
visual-associations.routes.integration.test.ts` (Postgres real, `jest.integration.config.ts`,
`--runInBand`, arquivo já iniciado por TASK-023-008/010 — esta TASK ESTENDE, não recria) para
o transporte HTTP; `tests/unit/visual-associations.service.test.ts` (novo, Jest padrão) para
as funções puras `suggestCategories`/`normalizeCategoryKey`.

## Dependências

- **Depende de**: TASK-023-008, TASK-023-010
- **Bloqueia**: TASK-023-016, TASK-023-017

*(Nota: a dependência de TASK-023-008/010 é de sequenciamento por MESMO arquivo —
`visual-associations.service.ts`/`.routes.ts` — não dependência funcional; ver Contexto.)*

## Contexto

TASK-023-008 e TASK-023-010 já entregam o CRUD de escrita completo (criar/editar/remover)
em `visual-associations.service.ts`/`.routes.ts`. Esta TASK ACRESCENTA, aos MESMOS arquivos,
as funções de leitura em massa: listagem paginada com filtro por categoria normalizada
(DEC-023-008/DEC-023-010), sugestão de categoria (FR-022-025) e a contagem de vínculos
(`linkCount`) por associação — reusando a MESMA condição de exclusão de soft-delete
(`RawContent.deletedAt`) já usada pela trava de remoção (TASK-023-010, FR-022-019).
`route-authz-matrix.integration.test.ts` cresce de 30 para 32 pares (as 2 chaves novas
montadas nesta TASK — `GET /visual-associations`, `GET /visual-associations/categories` —
entram automaticamente, a suíte deriva `ROUTES`/`NON_PUBLIC` de `collectRoutes(apiRoutes)`,
nunca hard-coded, `route-authz-matrix.integration.test.ts:64-76` lido nesta redação).
`FR-022-019` (contagem exclui soft-deleted) pertence a FEAT-022-003 na SPEC (não a
FEAT-022-002) — daí a Funcionalidade desta TASK ser transversal (correção do Tech Lead na
consolidação da rodada: o manifesto original havia omitido essa 2ª FEAT).

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/visual-associations/visual-associations.service.ts`
  (EMENDA):
  - `normalizeCategoryKey(category: string): string` — pura, sem I/O: `category.trim()
    .toLowerCase()` (DEC-023-008, NFR-022-007).
  - `suggestCategories(existingCategories: readonly string[], query: string): string[]` —
    pura: filtra `existingCategories` cuja `normalizeCategoryKey` inclui
    `normalizeCategoryKey(query)`, devolvendo a GRAFIA ORIGINAL (nunca a normalizada) das
    categorias combinadas, sem duplicatas (FR-022-025).
  - `listVisualAssociations(query: ListVisualAssociationsQuery, db?):
    Promise<Paginated<VisualAssociationSummary>>` — paginação `page`/`perPage` (default
    1/20, teto 100, DEC-023-010, mesmo padrão de `listRawContents`,
    `contents.service.ts:310-330` lido nesta redação); filtro `category` normalizado (trim
    do valor de entrada + `mode: 'insensitive'` do Prisma, DEC-023-008); cada item com
    `linkCount` — contagem de `MnemonicFrame` cujo `visualAssociationId` é o da associação,
    EXCLUINDO os cuja cadeia `frame.strip.ruleBreakdown.rawContent.deletedAt` está
    preenchida (MESMA exclusão de FR-022-019 usada pela trava de remoção, TASK-023-010 —
    não reimplementar o filtro divergente).
  - `listVisualAssociationCategories(query: { q: string }, db?): Promise<string[]>` —
    categorias distintas do acervo (`DISTINCT category` ou agregação equivalente em
    aplicação) filtradas por `suggestCategories` sobre o `q` informado.
- `mnemonicos-backend/src/modules/visual-associations/visual-associations.routes.ts`
  (EMENDA — estende a base de TASK-023-006/008):
  - `GET /visual-associations` → `requireRole('GET', '/visual-associations', 'EDITOR',
    'ADMIN')` — parseia `listVisualAssociationsQuerySchema` (já existente, TASK-023-003),
    chama `listVisualAssociations`.
  - `GET /visual-associations/categories` → `requireRole('GET',
    '/visual-associations/categories', 'EDITOR', 'ADMIN')` — parseia
    `suggestCategoriesQuerySchema` (já existente, TASK-023-003), chama
    `listVisualAssociationCategories`.
- `mnemonicos-backend/tests/integration/visual-associations.routes.integration.test.ts`
  (ESTENDE o arquivo de TASK-023-008/010): casos de listagem/filtro/paginação/sugestão —
  ver Critérios de pronto.
- `mnemonicos-backend/tests/unit/visual-associations.service.test.ts` (novo): casos de
  `normalizeCategoryKey`/`suggestCategories` isolados, sem I/O.
- `route-authz-matrix.integration.test.ts`: nenhuma alteração de asserção fixa — as 2 chaves
  novas montadas nesta TASK entram automaticamente ao montar as rotas, confirmando o
  crescimento de 30 para 32 pares (TRISK-023-006).

### Não inclui

- Renderização da lista na UI (`visual-library-board.tsx`) — TASK-023-012, consumidor
  destes endpoints.
- Upload/edição/remoção (`createVisualAssociation`/`updateVisualAssociation`/
  `removeVisualAssociation`) — TASK-023-008/010, já entregues.
- A entrega do binário da imagem (`GET .../:id/image`) — TASK-023-016.
- A contagem de vínculos usada pela TRAVA de remoção (FR-022-008) em si — já implementada
  por TASK-023-010; esta TASK reusa a MESMA condição de exclusão, mas para a contagem
  EXIBIDA (FR-022-012), superfície de leitura diferente (nenhuma recusa de operação aqui).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. `normalizeCategoryKey`/`suggestCategories` primeiro, puras e testadas isoladamente —
   sem tocar o service de I/O ainda.
2. Ao implementar o `include`/`select` aninhado da contagem (`frames` → `strip` →
   `ruleBreakdown` → `rawContent.deletedAt`), medir a contagem de round-trips ao Postgres em
   teste ANTES de fechar — lição ativa citada abaixo (TRISK-023-005, PLAN §8).
3. Reusar a MESMA forma de filtro de soft-delete que TASK-023-010 já implementou para a
   trava de remoção — grep do padrão exato usado lá antes de escrever um novo aqui.
4. As 2 rotas seguem o padrão plano já estabelecido em `visual-associations.routes.ts`
   (TASK-023-006/008/010): `requireRole` na montagem, nunca dentro do handler.

## Critérios de pronto

- [ ] **`select` explícito na listagem (achado do `security-engineer`, gate 8 da Wave 1)**:
      `listVisualAssociations` usa `select` excluindo `imageData` — cada linha da listagem
      pode ter até 5 MB no binário; arrastar isso por padrão em uma consulta paginada é o
      tipo de custo que este `select` explícito evita por construção. Teste: resposta de
      `GET /visual-associations` não contém a chave `imageData` em nenhum item.
- [ ] Testes cobrem AC-022-009 (parte — correção do backend: miniatura/categoria/contagem
      corretos na resposta; a renderização em si é TASK-023-012/gate 9): `GET
      /visual-associations` com um acervo de 2+ associações, cada uma com N vínculos
      distintos → a resposta lista cada `VisualAssociationSummary` com `id`/`category`/
      `linkCount` corretos (contagem confrontada por leitura direta do banco no teste, não
      só pelo número devolvido).
- [ ] Testes cobrem AC-022-010 (cobre FR-022-011): `GET /visual-associations?category=X` →
      devolve SOMENTE as associações da categoria X; `category=Y` (outra) → devolve as de Y;
      sem `category` → devolve todas (paginadas).
- [ ] Testes cobrem AC-022-016 (parte — facet "contagem exibida", FR-022-019): associação
      com 1 vínculo ATIVO e 1 vínculo cujo `RawContent` de origem foi soft-deleted →
      `linkCount` conta SOMENTE o ativo (o soft-deleted não entra) — mesmo par de fixtures
      (1 ativo + 1 soft-deleted na MESMA associação) já usado por TASK-023-010 para a trava
      de remoção, reusado aqui para a contagem exibida (superfície de leitura diferente,
      mesma regra de exclusão).
- [ ] Testes cobrem AC-022-022 (cobre FR-022-025): `GET
      /visual-associations/categories?q=trib` com o acervo tendo "Tributário" e "Trabalhista"
      → devolve só "Tributário" (grafia original, não normalizada); `q` que não combina com
      nenhuma categoria → lista vazia.
- [ ] Testes cobrem AC-022-025 (cobre NFR-022-007): acervo com categorias "Tributário" e "
      tributario " (variação de capitalização/espaçamento) → `GET
      /visual-associations?category=Tributario` (sem acento, minúsculo) devolve AMBAS como
      a mesma categoria agrupada/filtrada, SEM alterar o texto original armazenado (uma
      leitura direta pelo `id` confirma o texto original intocado nas duas linhas).
- [ ] **Paginação (DEC-023-010, contrato do próprio item + AC-022-009/010)**: `GET
      /visual-associations` sem `page`/`perPage` usa os defaults (`page: 1, perPage: 20`);
      com um acervo de 25 associações, `page=2` devolve as 5 restantes; `perPage=101` é
      recusado (422, teto do schema já existente, TASK-023-003) — mesmo padrão de
      `listRawContentsQuerySchema`.
- [ ] **[Testes] Predicado de conjunto composto por `&&` exige um caso por EIXO
      discriminável** (`guidelines/project/lessons.md`) — a condição composta de
      `linkCount` combina 2 eixos: (i) o vínculo aponta para ESTA associação, (ii) o
      `RawContent` da cadeia NÃO está soft-deleted. Um caso por eixo, não só o caso feliz:
      (a) vínculo de OUTRA associação não entra na contagem desta; (b) vínculo desta
      associação cujo `RawContent` está soft-deleted não entra; (c) vínculo desta associação
      ativo entra. 3 casos mínimos, cada um isolando um eixo.
- [ ] **[Performance] `include`/`select` aninhado de relação não é 1 statement por padrão**
      (`guidelines/project/lessons.md`, TRISK-023-005 do PLAN §8) — a contagem de
      `linkCount` atravessa `frames` → `strip` → `ruleBreakdown` → `rawContent.deletedAt`:
      teste dedicado com a contagem de round-trips ao Postgres FIXADA (`log: [{ emit:
      'event', level: 'query' }]`, mesmo padrão citado pela lição) — o número medido entra
      no critério (não presumido 1 statement); se a contagem crescer com N associações
      listadas (N+1), documentar como achado para o gate 10, não bloqueante desta TASK a
      menos que o `TRISK-023-005` (PLAN) já preveja mitigação obrigatória aqui.
- [ ] `normalizeCategoryKey`/`suggestCategories` (funções puras, sem I/O): casos isolados —
      `normalizeCategoryKey(' Tributário ')` === `normalizeCategoryKey('tributário')`;
      `suggestCategories(['Tributário', 'Trabalhista'], 'trib')` devolve `['Tributário']`
      (grafia original); **decisão do Tech Lead na consolidação** (achado do `qa`
      pré-código — o critério original deixava a resposta em aberto): `suggestCategories(
      [...], '')` devolve **lista vazia**, nunca todas as categorias — a sugestão só
      existe em resposta a texto digitado (FR-022-025, "ao digitar"); query vazia sem
      sugestão nenhuma é o comportamento mais previsível e evita uma lista grande
      aparecendo antes de qualquer intenção do EDITOR (a fronteira HTTP real,
      `suggestCategoriesQuerySchema`, já barra `q` vazio antes de chegar aqui — este
      caso só existe no teste unitário da função pura). Teste: `suggestCategories([...],
      '')` → `[]` (asserção exata, não "vazio ou não-nulo").
- [ ] `route-authz-matrix.integration.test.ts` continua verde com as 2 chaves novas montadas
      (`GET /visual-associations`, `GET /visual-associations/categories`) — nenhuma
      asserção fixa a alterar (deriva de `collectRoutes`); confirma 401 sem sessão / 403
      papel insuficiente (STUDENT) nas 2 rotas novas — AC-022-014 (parte).
- [ ] Verificação executável (gate 1, todos os itens de teste acima): `npm --prefix
      mnemonicos-backend run test:integration --
      --testPathPatterns=visual-associations.routes.integration.test.ts` → `OK (N tests)`
      (estende o arquivo de TASK-023-008/010, molde/exemplar já em uso); `npm --prefix
      mnemonicos-backend test -- visual-associations.service.test.ts` → `OK (N tests)`
      (arquivo novo — molde/exemplar de convenção: qualquer teste puro de função sem I/O já
      existente no módulo `contents`, ex. funções puras de `contents.service.ts`); `npm
      --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=route-authz-matrix.integration.test.ts` → `OK (N tests)`.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`), produção e teste — `npm --prefix mnemonicos-backend run lint` → exit 0.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil `node-22.md` — camadas
      schema→service→routes, `requireRole` declarado na montagem.
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-023-004 (PLAN §8) — sugestão de categoria e normalização computadas em código de
  aplicação sobre todas as categorias distintas, sem agregação SQL — custo cresce com o nº
  de categorias distintas; aceitável no volume inicial (ferramenta interna), revisitar com
  Q-022-001 se o acervo crescer.
- TRISK-023-005 (PLAN §8) — filtro aninhado da contagem de vínculos; medição obrigatória
  nesta TASK (Critério de pronto acima), gate 10 confirma o número em produção depois.
- TRISK-023-006 (PLAN §8) — `route-authz-matrix` precisa alcançar as 2 chaves novas; a
  suíte deriva a árvore montada automaticamente, então basta montar as rotas corretamente.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-13T23:10:17-0300
**Data conclusão**: 2026-09-14T10:29:57-0300
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 2939b2a, 273e7f6, 3fc9b9a (implementação), 976457e (retry — escapa metacaracteres LIKE, extrai withQueryProbe, mede EXPLAIN ANALYZE), f8e4a14 (nit Art.7)
**Jira**: KAN-102
**Implementado por**: developer
**Revisado por**: code-reviewer (gates 1-7) · security-engineer (gate 8, aprovado sem achados) — 2 rodadas: rodada 1 REPROVADA nos gates 1-7 (A2: filtro de categoria `equals`+`mode:'insensitive'` compila para `ILIKE` — valor do cliente interpretado como padrão LIKE, `?category=%` devolvia o acervo inteiro; A4: `withQueryProbe` duplicado, 4ª cópia) + 2 itens escalados e resolvidos pelo Tech Lead (A1: inconsistência SPEC↔SPEC em AC-022-025, corrigida na prosa; A3: medição EXPLAIN ANALYZE obrigatória, Seq Scan confirmado aceitável no volume atual, sem migração) → retry (`976457e`) → rodada 2 APROVADA, mutante do escape confirmado morto por execução própria do revisor
**Tentativas**: 2
**Cobertura final**: unit 286/286 · integration 364/364 (650 total) — listagem paginada, filtro por categoria (com prova de metacaractere LIKE), sugestão de categoria, `linkCount` medido em 2 round-trips fixos (não N+1)
**Arquivos modificados**:
  - mnemonicos-backend/src/modules/visual-associations/visual-associations.service.ts
  - mnemonicos-backend/src/modules/visual-associations/visual-associations.routes.ts
  - mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts
  - mnemonicos-backend/tests/integration/visual-associations.routes.integration.test.ts
  - mnemonicos-backend/tests/integration/visual-associations.service.integration.test.ts
  - mnemonicos-backend/tests/support/visual-association-fixtures.ts
  - mnemonicos-backend/tests/support/query-probe.ts (novo)
  - mnemonicos-backend/tests/unit/visual-associations.service.test.ts (novo)

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado
- [x] Comportamento (gate 9): consolidado FEAT-022-002 e FEAT-022-003 (VERIFICADO, ver SPEC-022)

**Notas**: Achado real (LIKE injection funcional, não SQL injection — parametrizado mas interpretado como padrão) fechado com escape de metacaracteres + prova por mutação. Mesma classe de bug pré-existente identificada em `disciplines.service.ts`/`users.service.ts` (fora do escopo deste PLAN, roteado como nota em `guidelines/project/lessons.md`). Perfil `node-22.md` §6.1 atualizado (removida marca "não confirmado"). `Seq Scan` em `visual_associations` sem índice — aceitável no volume atual (≤16ms/12k linhas), escalado como candidato a índice/migração futura (gate 10/Diretor).
