# TASK-023-010: Remover associação visual com trava de vínculo

**Slug**: producao-material
**Pertence a**: PLAN-023
**Realiza (FRs)**: FR-022-007, FR-022-008, FR-022-019, FR-022-022, FR-022-023
**Funcionalidade**: FEAT-022-003 (primária), FEAT-022-001
**Componente**: COMP-023-005 (principal), COMP-023-006
**Wave**: 4
**Fatia sensível (princípio 8)**: security-engineer focado (guarda de autoria reusada + identificação de alcance)
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch do EPICO MNEMORA STUDIO, Estrategia unica -- decisao 4.126: F5 e uma fatia do epico, nunca abre branch propria; a sessao ja fez o sync de largada nela)

**Padrão de commit**: Conventional Commits (`commit.convention: "conventional"`) — `feat:`.
**Framework de teste**: Jest 30 + ts-jest + `supertest` — `tests/integration/*.integration.test.ts` (Postgres real, `jest.integration.config.ts`, `--runInBand`).

## Dependências

- **Depende de**: TASK-023-008
- **Bloqueia**: TASK-023-014, TASK-023-017

## Contexto

FEAT-022-003 é a primária por contagem (3 FRs desta TASK — 019/022/023 — contra 2 de
FEAT-022-001 — 007/008). Fecha o CRUD do acervo com a remoção: `removeVisualAssociation` conta vínculos ATIVOS
(excluindo Quadros cujo Conteúdo bruto de origem foi soft-deleted, FR-022-019) e recusa com
409 quando há 1+, identificando ao `actor` os Quadros/Tiras que ele alcança por autoria
(FR-022-022, cadeia Frame→Strip→RuleBreakdown→RawContent — MAP.md §F4). Reusa
`assertVisualAssociationWritable` (TASK-023-008) como 2ª chamadora — a lição ativa do slug
exige prova comportamental PRÓPRIA aqui, não herdada da prova de `update`.

## Escopo

### Inclui

- `removeVisualAssociation(id, actor, db?)` — **achado do `security-engineer` no gate 8 da
  Wave 1, incorporado como critério desta TASK (decisão 4.140 — TOCTOU em READ COMMITTED)**:
  contar vínculos e DEPOIS deletar em passos separados não trava a leitura — um vínculo
  criado entre a contagem e o `delete` seria anulado silenciosamente pelo `SetNull`,
  furando FR-022-008. A trava fecha na ESCRITA, atômica, dentro de `db.$transaction`: (1)
  `assertVisualAssociationWritable` primeiro (autor ou ADMIN, senão `ForbiddenError` — 2ª
  chamadora da guarda); (2) `db.visualAssociation.deleteMany({ where: { id, frames: {
  none: { strip: { ruleBreakdown: { rawContent: { deletedAt: null } } } } } } })` — a
  condição `frames: none` só casa (permite o delete) quando NENHUM `MnemonicFrame`
  vinculado tem cadeia até um `RawContent` ainda ativo (não soft-deleted, FR-022-019); a
  decisão de bloquear ou não é feita pelo PRÓPRIO banco, na mesma operação que apagaria a
  linha — sem janela entre ler e escrever. (3) `result.count === 1` → sucesso (o binário
  some junto, é a mesma linha); `result.count === 0` → a linha existe mas tem vínculo
  ativo (já confirmado que existe e é escrita pelo `actor`, passos anteriores) — SÓ ENTÃO
  uma leitura separada (fora da decisão de segurança, só para montar a mensagem) monta
  `ConflictError` 409 com `details: { reachableLinks: Array<{ rawContentId: string;
  frameId: string }>; outOfReachCount: number }` — `reachableLinks` só os vínculos cujo
  `RawContent` o `actor` alcança por autoria (ADMIN vê todos), `outOfReachCount` o resto,
  SEM identificar.
- `DELETE /visual-associations/:id` em `visual-associations.routes.ts` — `verifyOrigin` +
  `requireRole('DELETE', '/visual-associations/:id', 'EDITOR', 'ADMIN')`.
- `route-authz-matrix.integration.test.ts`: a chave nova (`DELETE
  /visual-associations/:id`) entra automaticamente ao montar a rota (suíte deriva de
  `collectRoutes`, nunca hard-coded) — confirma o crescimento de 27 para 28 pares
  (TRISK-023-006).

### Não inclui

- Listagem/contagem exibida na biblioteca (`linkCount` de `VisualAssociationSummary`,
  FR-022-012) — TASK-023-014; esta TASK só usa a MESMA regra de exclusão de soft-delete
  (FR-022-019) para a trava, sem expor a contagem em nenhuma rota de leitura.
- Criação/edição da associação visual (TASK-023-008) — inclusive a 1ª prova comportamental
  de `assertVisualAssociationWritable`, já entregue lá.
- Vínculo/desvínculo a Quadro (TASK-023-011).
- A métrica de "uploads evitados" (§1.3 da SPEC) — só lê `VisualAssociationLinkEvent`,
  escrito por TASK-023-011; esta TASK não grava nem lê essa tabela.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. A contagem de vínculos ativos e o cálculo de `reachableLinks`/`outOfReachCount` reusam a
   MESMA condição de exclusão (`RawContent.deletedAt`) — não duplique o filtro em dois
   lugares divergentes.
2. Resolva **primeiro** o alcance por autoria do `actor` sobre cada vínculo (para decidir se
   ele entra em `reachableLinks` ou é só contado em `outOfReachCount`), e só DEPOIS decida se
   o vínculo é soft-deleted/ativo — nunca a ordem inversa (o corolário da lição de precedência
   abaixo).
3. `assertVisualAssociationWritable` é reusada por chamada direta (import de
   `visual-associations.service.ts`) — nunca recriada nem duplicada nesta TASK.

## Critérios de pronto

- [ ] **Fechamento da corrida TOCTOU (achado do `security-engineer`, gate 8 da Wave 1)**:
      prova ESTRUTURAL de que a decisão de bloquear é feita por `deleteMany` com `where`
      condicional (nunca por um `count`/leitura separada seguida de `delete` incondicional)
      — `grep -n "deleteMany" mnemonicos-backend/src/modules/visual-associations/
      visual-associations.service.ts` confirma a chamada, e o mesmo trecho contém
      `frames:\s*{\s*none` no `where` (mutante: substituir a condição por um `count` prévio
      + `delete` faz este grep estrutural falhar — nunca por comparação de string solta,
      ancorado na chamada real do Prisma). Teste comportamental complementar: mock/spy que
      confirma 1 única operação de escrita no banco para a decisão (não 2 chamadas
      count-então-delete).
- [ ] Testes cobrem AC-022-007 (cobre FR-022-007): associação SEM nenhum vínculo → `DELETE`
      exclui a linha (confirmado por `findUnique` subsequente devolvendo `null`).
- [ ] Testes cobrem AC-022-008 (cobre FR-022-008): associação com 1 ou mais vínculos ATIVOS
      → `409`, informa a existência de vínculos ativos, e a linha da associação PERMANECE
      (confirmado por `findUnique` subsequente).
- [ ] Testes cobrem AC-022-016 (parte — faceta "trava de remoção" da exclusão de
      soft-delete; as facetas "contagem exibida" e "métrica" fecham em TASK-023-014 e
      TASK-023-011, respectivamente): associação cujo ÚNICO vínculo aponta para um Quadro
      de um Conteúdo bruto soft-deleted → `DELETE` TEM SUCESSO (o vínculo não conta como
      ativo); associação com 1 vínculo soft-deleted E 1 vínculo ainda alcançável → `DELETE`
      recusado (409), a contagem reflete só o vínculo ativo.
- [ ] Testes cobrem AC-022-019 (cobre FR-022-022): associação vinculada a Quadros de Tiras
      de DIFERENTES autores → EDITOR que aciona a remoção recebe, em
      `details.reachableLinks`, só os vínculos cujo `RawContent` ele alcança por autoria, e
      `details.outOfReachCount` reflete o resto SEM identificar `rawContentId`/`frameId`
      nenhum deles; ADMIN, no mesmo cenário, recebe todos os vínculos identificados em
      `reachableLinks` (`outOfReachCount: 0`).
- [ ] **Corolário de ordem (decisão do PLAN, DEC-023-006 aplicada)**: ao montar
      `reachableLinks`/`outOfReachCount`, a checagem de alcance por autoria roda SEMPRE
      antes de qualquer exposição que revele se um Quadro fora do alcance está
      soft-deleted ou ativo — teste dedicado: vínculo fora do alcance do EDITOR cujo
      Conteúdo bruto está soft-deleted não aparece em `reachableLinks` nem é distinguível de
      um vínculo fora do alcance ainda ativo, em `outOfReachCount` (a MESMA contagem
      agregada, nunca uma pista sobre o estado do dado que ele não alcança).
- [ ] **Guarda de escrita — mutação contável (decisão 4.139/4.232, lição "[Segurança] Guarda
      reusada continua exigindo prova comportamental própria por novo método de escrita",
      `guidelines/project/lessons.md`)**: `removeVisualAssociation` é o 2º método a chamar
      `assertVisualAssociationWritable` (TASK-023-008 entregou o 1º, para `update`, com prova
      PRÓPRIA — não repetida aqui); fechamento contável desta guarda fica em N=2 métodos, 2
      provas — nenhuma herdada. Fixture PRÓPRIA desta TASK: associação sem vínculo ativo
      (para isolar a guarda de escrita da trava de vínculo) criada por EDITOR A; EDITOR B
      (outro autor) tenta `DELETE` → `403` com a MESMA mensagem literal que `update` usa para
      a mesma guarda, e a linha permanece INTOCADA (confirmado por `findUnique`); ADMIN, no
      mesmo cenário, remove com sucesso. Cobre AC-022-020 (parte).
- [ ] Testes cobrem AC-022-014 (parte — `DELETE` recusado a STUDENT/anônimo): sessão STUDENT
      → `403`; sem sessão → `401`.
- [ ] **[Testes] Árvore de decisão com precedência: um caso por PAR de ramos que coincide**
      (`guidelines/project/lessons.md`) — cenário com um vínculo ATIVO e um vínculo
      SOFT-DELETED SIMULTANEAMENTE na MESMA associação (2 Quadros distintos apontando para
      ela): o mutante que inverte a ordem de avaliação (contar o soft-deleted como ativo, ou
      vice-versa) reprova neste caso — coberto pelo cenário de AC-022-016 (parte) acima,
      citado aqui como o par que fecha a lição (não um caso adicional).
- [ ] `route-authz-matrix.integration.test.ts` continua verde com a chave nova montada
      (`DELETE /visual-associations/:id`) — nenhuma asserção fixa a alterar; confirma 401
      sem sessão / 403 papel insuficiente na rota nova.
- [ ] Verificação executável (gate 1, todos os itens de teste acima): `npm --prefix
      mnemonicos-backend run test:integration --
      --testPathPatterns=visual-associations.routes.integration.test.ts` → `OK (N tests)`
      (estende o arquivo de TASK-023-008); `npm --prefix mnemonicos-backend test --
      visual-associations.service.guard-order.test.ts` → `OK (2 tests)` (estende a prova
      estrutural — `update` e `remove`, ambas com `assertVisualAssociationWritable` como 1ª
      chamada); `npm --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=route-authz-matrix.integration.test.ts` → `OK (N tests)`.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`), produção e teste — `npm --prefix mnemonicos-backend run lint` → exit 0.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil `node-22.md` — remoção dentro de
      `$transaction`, mensagens de recusa fail-secure (nunca vazam existência de dado fora
      do alcance).
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-023-005 (PLAN §8, herdado) — a contagem de vínculos ativos exige filtro aninhado
  (`frames` → `strip` → `ruleBreakdown` → `rawContent.deletedAt`) por associação avaliada;
  sem medição real ainda (gate 10 mede round-trips reais fora desta TASK, junto com
  TASK-023-011/014).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-13T22:56:03+0000
**Data conclusão**: 2026-09-14T11:05:00+0000
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: b0e05ee (implementação), b547887 (retry — fecha corrida TOCTOU real com `SELECT ... FOR UPDATE`)
**Jira**: KAN-98
**Implementado por**: developer
**Revisado por**: code-reviewer (gates 1-7) · security-engineer (gate 8) — 2 rodadas: rodada 1 REPROVADA (gate 1-7: prova comportamental do TOCTOU nunca escrita, só grep estrutural; gate 8: vulnerabilidade REAL — `deleteMany` condicional não fecha a corrida sob READ COMMITTED, confirmado por execução de concorrência real contra Postgres) → retry (`b547887`: `SELECT ... FOR UPDATE` como 1º statement, parametrizado, + teste de concorrência real) → rodada 2 APROVADA nos dois gates, com prova de mutação executada pelos próprios revisores (mutante que remove o `FOR UPDATE` reprova 4/4; SQL confirmado parametrizado contra payload hostil)
**Tentativas**: 2
**Cobertura final**: integration 342/342 (backend) — corrida real provada com `Promise.all` concorrente contra Postgres de teste, invariante "vínculo ativo nunca anulado em silêncio" confirmada
**Arquivos modificados**:
  - mnemonicos-backend/src/modules/visual-associations/visual-associations.service.ts
  - mnemonicos-backend/src/modules/visual-associations/visual-associations.routes.ts
  - mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts
  - mnemonicos-backend/tests/integration/visual-associations.routes.integration.test.ts
  - mnemonicos-backend/tests/unit/visual-associations.service.guard-order.test.ts
  - mnemonicos-backend/tests/integration/tira.service.integration.test.ts (teste de concorrência real)

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (2ª rodada, após fechar corrida TOCTOU real)
- [x] Comportamento (gate 9): consolidado FEAT-022-001 (verificado via HTTP real, ver SPEC-022 §FEAT-022-001)

**Notas**: A trava de vínculo por `deleteMany` condicional (achado da Wave 1) não fechava a corrida de verdade sob READ COMMITTED — o predicado é avaliado no snapshot do statement e não reavaliado após espera de lock; um vinculador concorrente que commitasse durante a espera do DELETE tinha o vínculo anulado em silêncio pelo `ON DELETE SET NULL`. Fechado travando a linha pai (`SELECT ... FOR UPDATE`) antes de qualquer decisão. Lição candidata roteada (`guidelines/project/lessons.md`/`docs/_meta/learning-log.md`): corrida só se fecha com prova de concorrência real contando linhas no fim — prova estrutural/sequencial nunca fecha corrida.
