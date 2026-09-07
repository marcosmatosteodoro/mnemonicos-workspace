# TASK-012-008: Expor `tira.routes.ts` sob a barreira EDITOR/ADMIN

**Slug**: producao-material
**Pertence a**: PLAN-012
**Realiza (FRs)**: FR-011-001, FR-011-002, FR-011-003, FR-011-004, FR-011-005, FR-011-006, FR-011-007, FR-011-010
**Componente**: COMP-012-006 (principal)
**Wave**: 5
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: In Progress

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-tira-mnemonica` (`git.branchStrategy: "unica"` — uma única branch para todo o ciclo de PLAN-012; `git.branchNaming: "slug"`)
**Padrão de commit**: Conventional Commits (`commit.convention: "conventional"`) — ex.: `feat(producao-material): expor rotas da tira mnemônica sob a barreira`
**Framework de teste**: Jest 30 + Supertest, harness de integração (`mnemonicos-backend/tests/integration/`) — mesmo arquivo/harness de `route-authz-matrix.integration.test.ts`

## Dependências

- **Depende de**: TASK-012-003, TASK-012-007
- **Bloqueia**: TASK-012-012

## Contexto

`tira.schema.ts` (TASK-012-003) e `tira.service.ts` (TASK-012-007) já entregam a validação e a regra de negócio da Tira mnemônica. Falta expor as 6 rotas HTTP sob a mesma barreira deny-by-default de `/contents` (F1/F2) — árvore plana, `requireRole` declarado na montagem, `verifyOrigin` nas 5 mutações (EMENDA Wave 5/DEC-012-011: geração migrou de `GET` para `POST /contents/:id/strip`, ver acima) — e estender a suíte de conformidade `route-authz-matrix` (tripwire 19→25) e o grep de fechamento do legado `Mnemonic` (AC-011-016) aos 3 arquivos do módulo `tira/`.

**RETRY consolidado (1ª rodada REPROVADA nos 2 gates — code-reviewer e security-engineer)**:
1. **Achado de segurança (CSRF, EMENDA acima)** — geração migra de `GET` para `POST /contents/:id/strip`.
2. **Achado bloqueante compartilhado pelos 2 gates**: `tests/integration/route-authz-matrix.integration.test.ts:421` (bloco herdado `TASK-006-011`) trocou a população derivada (`route.path.startsWith('/contents')`) por enumeração fechada (`CONTENT_ROUTE_KEYS.includes(...)`) — vira tautológico, perde a função forçante que arrasta rota nova sob `/contents` para o varrimento STUDENT→403. Corrigir para `route.path.startsWith('/contents') && !route.path.startsWith('/contents/:id/strip')` (exclui explicitamente o subtree da Tira, que tem bloco próprio), mantendo o `toEqual` estrito.
3. **Achado bloqueante do code-reviewer (DRY)**: `tests/integration/tira.routes.integration.test.ts` duplica `BREAKDOWN_FIELDS`/`seedRuleBreakdown` já criados por `tira.service.integration.test.ts` (wave anterior do mesmo PLAN) — promover o par para `tests/support/production-events-fixtures.ts` e consumir nos dois arquivos.

## Escopo

### Inclui

- **EMENDA Wave 5 (furo no plano — achado de CSRF do security-engineer, gate 8;
  Diretor decidiu; ver DEC-012-011 no PLAN-012)**: `GET /contents/:id/strip` deixava
  de ser get-or-generate (o cookie de sessão `sameSite: 'lax'` acompanha navegação
  top-level, e o projeto proíbe `verifyOrigin` em `GET` — um `GET` que escreve fica
  sem defesa CSRF; sonda provou forjar `actorId` da vítima no evento ABERTURA). A
  geração migra para `POST /contents/:id/strip` (nova rota, com `verifyOrigin`); o
  `GET` vira leitura pura. `tira.service.ts` precisa de uma função de LEITURA
  separada de `openMnemonicStrip` (que continua a existir, agora só chamada pelo
  `POST`) — mesmas guardas (`assertRawContentReachable` 1ª chamada, 409 se a Quebra
  da regra não foi salva), mas 404 (`NotFoundError`) se a Tira ainda não existe, em
  vez de criar.
- `mnemonicos-backend/src/modules/tira/tira.routes.ts` — 6 rotas em árvore plana (nenhum `.use('/prefixo', sub)`), mesmo padrão de `contents.routes.ts`:
  - `GET /contents/:id/strip` → `requireRole('GET','/contents/:id/strip','EDITOR','ADMIN')` — leitura pura, NUNCA gera (sem `verifyOrigin`: é leitura de verdade agora).
  - `POST /contents/:id/strip` → `verifyOrigin` + `requireRole('POST','/contents/:id/strip','EDITOR','ADMIN')` — get-or-generate idempotente (a antiga responsabilidade do GET).
  - `POST /contents/:id/strip/frames` → `verifyOrigin` + `requireRole('POST','/contents/:id/strip/frames','EDITOR','ADMIN')`.
  - `PATCH /contents/:id/strip/frames/:frameId` → `verifyOrigin` + `requireRole('PATCH','/contents/:id/strip/frames/:frameId','EDITOR','ADMIN')`.
  - `DELETE /contents/:id/strip/frames/:frameId` → `verifyOrigin` + `requireRole('DELETE','/contents/:id/strip/frames/:frameId','EDITOR','ADMIN')`.
  - `PUT /contents/:id/strip/frames/order` → `verifyOrigin` + `requireRole('PUT','/contents/:id/strip/frames/order','EDITOR','ADMIN')`.
  Cada `requireRole` declarado **na chamada de montagem** (argumento posicional de `.get/.post/.patch/.delete/.put`), nunca dentro do corpo do handler.
- `actorOf(req)` local ao módulo, mesmo formato de `contents.routes.ts:58-61` (`{ id: req.auth.userId, role: req.auth.role }`), passado a cada função de `tira.service.ts`.
- Parse de params/body com os schemas de `tira.schema.ts` (mais `rawContentIdParamSchema` de `contents.schema.ts`, reusado para o `:id` — não recriado).
- Montagem em `mnemonicos-backend/src/http/routes.ts`: `apiRoutes.use(tiraRoutes)`, na linha imediatamente **depois** de `apiRoutes.use(contentsRoutes)`.
- Extensão de `mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts`: tripwire do censo (19→25) e bloco de topologia adversarial das 6 rotas novas (molde do bloco `describe('TASK-006-011 — as 7 rotas de /contents sob a barreira ...')`, linhas 384-421 do arquivo hoje) — **e a correção do achado bloqueante item 2 acima na MESMA passada** (a condição do filtro da linha 421 exclui o subtree da Tira, não o inclui por engano).
- Teste(s) de integração cobrindo AC-011-022 (parte, transporte do ator) e AC-011-023 (parte, mapeamento HTTP do 409) — pode viver no mesmo arquivo de topologia ou em `tira.routes.integration.test.ts` novo.
- Grep de fechamento (AC-011-016) sobre os 3 arquivos do módulo `tira/` (`tira.service.ts`, `tira.schema.ts`, `tira.routes.ts`).

### Não inclui

- Lógica de negócio de `tira.service.ts` (já entregue por TASK-012-005/006/007) — a rota só valida com Zod e delega ao service.
- Qualquer mudança em `contents.routes.ts`.
- A regra por trás do 409 de "Quebra da regra ainda não salva" (já implementada em `openMnemonicStrip`, PLAN-012 §4 F-1 passo 2, `ConflictError`) — esta TASK só confirma o mapeamento HTTP do erro já lançado pelo service.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Criar `tira.routes.ts` a partir da estrutura de `contents.routes.ts` (imports, `actorOf`, `Router()`, docblock explicando árvore plana + `verifyOrigin` por posição).
2. Declarar as 5 rotas na ordem do PLAN-012 §3/COMP-012-006, cada uma com `requireRole` na montagem e `verifyOrigin` como 1º handler nas 4 mutações.
3. Montar `tiraRoutes` em `routes.ts`, logo depois de `contentsRoutes`.
4. Estender o array do tripwire de censo (19→24) e adicionar o bloco de topologia adversarial das 5 rotas novas (molde: bloco `TASK-006-011`).
5. Adicionar os testes de integração de AC-011-022 (parte)/AC-011-023 (parte).
6. Rodar o grep de fechamento (AC-011-016) contra os 3 arquivos do módulo `tira/`.

## Critérios de pronto

- [ ] As 6 rotas de `tira.routes.ts` montadas em árvore plana, cada uma com `requireRole` declarado na chamada de montagem (nunca no handler) e `verifyOrigin` como 1º handler nas 5 mutações (`POST /contents/:id/strip`/`POST .../frames`/`PATCH`/`DELETE`/`PUT`), ausente na leitura (`GET`).
- [ ] **CSRF/DEC-012-011 (achado do security-engineer, gate 8 — bloqueante desta rodada)**: `POST /contents/:id/strip` (geração, antiga responsabilidade do `GET`) tem `verifyOrigin` como 1º handler. `GET /contents/:id/strip` vira leitura pura — teste de integração prova que uma chamada de `GET` **sobre uma Tira ainda não aberta** (Quebra da regra salva, Tira inexistente) devolve 404 e **não cria** `MnemonicStrip`/`MnemonicFrame`/evento de produção (consulta direta ao banco após a chamada confirma 0 linhas) — nem mesmo chamando duas vezes seguidas. Comando: `npm run test:integration` → suíte nomeada verde.
- [ ] **AC-011-017** — topologia adversarial completa (gate 1, integração): `route-authz-matrix.integration.test.ts` ganha o bloco `describe('TASK-012-008 — as 6 rotas da Tira sob a barreira (topologia adversarial)')` com estas asserções: (a) as 6 chaves — `GET /contents/:id/strip`, `POST /contents/:id/strip`, `POST /contents/:id/strip/frames`, `PATCH /contents/:id/strip/frames/:frameId`, `DELETE /contents/:id/strip/frames/:frameId`, `PUT /contents/:id/strip/frames/order` — declaradas como `{EDITOR, ADMIN}` em `ROUTE_ROLES` (`REGISTRY.get(key)` igual a `new Set(['EDITOR','ADMIN'])` para cada uma); (b) sessão STUDENT → 403 nas 6 (mesmo padrão do bloco `TASK-006-011`: `send(app, route.method, ...)` sobre cada rota concreta); (c) `ROUTE_ROLES.has('PUT /contents/:id/strip/frames/order')` **e** `ROUTE_ROLES.has('PATCH /contents/:id/strip/frames/:frameId')`/`ROUTE_ROLES.has('DELETE /contents/:id/strip/frames/:frameId')` **e** `ROUTE_ROLES.has('GET /contents/:id/strip')`/`ROUTE_ROLES.has('POST /contents/:id/strip')` são chaves independentes — nenhuma herda a declaração da vizinha (rota estática `order` ao lado da rota `:frameId`; `GET`/`POST` no mesmo caminho — 2º método no mesmo path, mesma topologia adversarial da lição ativa — ver Riscos específicos). Comando: `npm run test:integration` (dentro de `mnemonicos-backend/`) → esperado `PASS ... route-authz-matrix.integration.test.ts`, com o describe novo nomeado no relatório de execução (o nome do teste aparecendo, não só a contagem agregada — o alvo isolado precisa constar no relatório). A metade "sem sessão → 401" do AC não precisa de caso novo: o describe pré-existente `AC-002-010/NFR-002-001` deriva `NON_PUBLIC` dinamicamente de `collectRoutes(apiRoutes)` contra o app real, então as 6 rotas novas entram automaticamente no loop assim que montadas (achado do `qa`, Etapa 3.5 — confirmado por leitura, não é lacuna, só falta de menção explícita neste critério).
- [ ] **Tripwire `route-authz-matrix` (19→25, fechamento)** — o `it('a árvore montada é exatamente estes 19 pares...')` (`route-authz-matrix.integration.test.ts:154-178`) é editado para 25 pares, `.sort()`, comparado por igualdade estrita (`toEqual`, nunca `expect.arrayContaining`). Inventário ANTES (19, herdado, inalterado): `GET /health`, `GET /health/db`, `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`, `POST /auth/change-password`, `GET /auth/me`, `GET /users`, `POST /users`, `PATCH /users/:id/disable`, `POST /users/:id/reset-password`, `GET /disciplines`, `GET /contents`, `POST /contents`, `GET /contents/:id`, `PATCH /contents/:id`, `DELETE /contents/:id`, `GET /contents/:id/breakdown`, `PUT /contents/:id/breakdown`. Inventário DEPOIS (25 — os 19 acima **mais** os 6 novos): `GET /contents/:id/strip`, `POST /contents/:id/strip`, `POST /contents/:id/strip/frames`, `PATCH /contents/:id/strip/frames/:frameId`, `DELETE /contents/:id/strip/frames/:frameId`, `PUT /contents/:id/strip/frames/order`. Comando: `npm run test:integration` → o `it` (descrição atualizada para "...estes 25 pares...") verde.
- [ ] **Achado bloqueante — regressão de prova em `route-authz-matrix.integration.test.ts:421`** (compartilhado pelos 2 gates da 1ª rodada): trocar `NON_PUBLIC.filter((route) => CONTENT_ROUTE_KEYS.includes(key(route)))` por `NON_PUBLIC.filter((route) => route.path.startsWith('/contents') && !route.path.startsWith('/contents/:id/strip'))`, mantendo o `toEqual` estrito contra `CONTENT_ROUTE_KEYS.sort()`. Aceite (mutante já executado pelo code-reviewer, reproduzir): declarar uma rota nova hipotética `GET /contents/:id/export` com papéis incluindo `STUDENT` (buraco de autz) e atualizar o censo para 26 — o `it` de STUDENT→403 do bloco `TASK-006-011` deve ficar VERMELHO; removida a rota hipotética, suíte volta a 25/25 verde.
- [ ] **Achado bloqueante — DRY em `tira.routes.integration.test.ts`**: `BREAKDOWN_FIELDS`/`seedRuleBreakdown` (duplicados byte-a-byte de `tira.service.integration.test.ts`) são promovidos para `tests/support/production-events-fixtures.ts` e consumidos pelos DOIS arquivos de integração da Tira, sem alterar nenhuma asserção. Verificação: `grep -rn "BREAKDOWN_FIELDS\|seedRuleBreakdown" mnemonicos-backend/tests/` → só o helper (`production-events-fixtures.ts`) e os dois imports.
- [ ] **AC-011-022 (parte — faceta de transporte)**: teste de integração prova que `GET /api/v1/contents/:id/strip` autenticado como EDITOR B sobre um `rawContentId` de autoria de EDITOR A devolve **404** com a mensagem literal exata `"Conteúdo bruto não encontrado."` (igualdade de string sobre `res.body.error.message`, nunca só `res.status === 404` nem `instanceof AppError` — corolário de segurança da lição "árvore de decisão com precedência" já ativa neste projeto, que exige comparar a mensagem por igualdade literal entre as duas recusas de não-alcance). Mesmo caso, agora também para `POST /contents/:id/strip` (a geração). Comando: `npm run test:integration` → suíte nomeada verde.
- [ ] **Confused deputy no `:frameId`, faceta HTTP (achado do security-engineer, gate 8
      da Wave 1 — pendência herdada, decisão 4.140)**: teste de integração prova que
      `PATCH`/`DELETE /contents/:id/strip/frames/:frameId` recusam (404, mesma mensagem)
      quando `:frameId` pertence à Tira de um `rawContentId` **diferente** do `:id` da
      URL (mesmo quando ambos são do mesmo EDITOR autenticado) — a rota confia na
      amarração feita pelo service (TASK-012-007), este teste prova a faceta HTTP
      ponta-a-ponta. Comando: mesma suíte de integração acima, caso
      "rejeita :frameId fora da cadeia do :id da URL, mesmo autor".
- [ ] **AC-011-023 (parte — faceta HTTP)**: teste de integração prova que `GET /api/v1/contents/:id/strip` **e** `POST /api/v1/contents/:id/strip` sobre um `rawContentId` alcançável mas **sem** Quebra da regra salva devolvem **409** com `res.body.error.code === 'CONFLICT'` — status derivado automaticamente do `statusCode` de `ConflictError` (`mnemonicos-backend/src/http/errors.ts:41-45`) pelo `errorHandler`, sem mapeamento manual na rota (a guarda de 409 é comum às duas funções do service — leitura e geração — por herdarem a mesma ordem de checagem). Comando: `npm run test:integration` → suíte verde.
- [ ] **AC-011-016 (fechamento)** — grep estrutural ancorado sobre os 3 arquivos do módulo `tira/`:
  ```
  grep -nE '\b(Mnemonic|hook|decoding)\b' mnemonicos-backend/src/modules/tira/tira.service.ts mnemonicos-backend/src/modules/tira/tira.schema.ts mnemonicos-backend/src/modules/tira/tira.routes.ts | grep -vE ':[[:space:]]*(//|\*|/\*)'
  ```
  Esperado: saída vazia. Fixado contra o molde equivalente (decisão de ancoragem em arquivo-exemplar — os 3 arquivos-alvo desta wave ainda não existem): `grep -nE '\b(Mnemonic|hook|decoding)\b' mnemonicos-backend/src/modules/contents/contents.service.ts mnemonicos-backend/src/modules/contents/contents.routes.ts` → confirmado **vazio** nos dois, rodado nesta fixação (2026-09-06) — o padrão não falso-positiva em código real e equivalente do projeto.
- [ ] Sem warnings/lints novos sobre `git diff --name-only main...HEAD` (produção e teste).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`guidelines/project/backend/node-22.md`).
- [ ] Code review aprovado.
- [ ] Segurança (gate 8) aprovado — fatia sensível (endpoint novo + authz).

## Riscos específicos

- Fatia sensível (gate 8 obrigatório): qualquer sonda de investigação de segurança escrita pelo `security-engineer` roda em worktree isolada (lição ativa "Sonda de investigação não nasce em `tests/**`"), nunca commitada na árvore principal.
- **Pendência de contrato para TASK-012-010 (frontend RTK Query, já Done) e TASK-012-012 (tela, ainda não implementada)** — EMENDA Wave 5/DEC-012-011: o endpoint RTK Query de `store/api.ts` que hoje faz `GET /contents/:id/strip` esperando get-or-generate precisa de um endpoint de mutação novo (`POST /contents/:id/strip`) para a geração; o `GET` passa a poder devolver 404 ("Tira ainda não aberta") como estado normal, não erro. Fora do escopo desta TASK (só backend) — sinal explícito para o despacho de TASK-012-012 (Wave 6): a tela já nasce consumindo o contrato novo (chama `POST` na 1ª visita, `GET` depois), e o ajuste do endpoint RTK Query existente entra no mesmo diff da tela, já que TASK-012-010 está Done e não será reaberta só para isto.

**Lições ativas cruzadas** (`guidelines/project/lessons.md`) contra os arquivos-alvo (`tira.routes.ts`, `route-authz-matrix.integration.test.ts`) — mesma classe de defeito já registrada em F1/F2, reincidência esperada do mesmo padrão:

- **[Arquitetura] Barreira que nega com base num registro exige o registro completo antes da 1ª requisição** (Estado: ativa). Erro original: `ROUTE_ROLES` era populado por efeito colateral **dentro do handler** de `requireRole`, mas `requireAuth` — quem consulta o registro — roda **antes** dele na cadeia Express; o registro nunca era escrito, e o deny-by-default degenerava em deny-tudo. Solução: declaração é ato de **montagem** — `requireRole(method, path, ...roles)` declara na avaliação da chamada, nunca dentro do handler; o registro é selado após o boot. **Aplicação aqui**: os 5 `requireRole` de `tira.routes.ts` são argumento posicional da própria chamada de `.get/.post/.patch/.delete/.put` — nunca uma linha dentro do corpo do handler. O teste de wiring já existente (`assertDenyByDefault`, reimportação via `jest.isolateModulesAsync`) reprova a montagem se qualquer uma das 5 vier sem a declaração.
- **[Segurança] "Declarado" não é "autorizado"; prova de gate de autz exige topologia adversarial** (Estado: ativa). Solução: a prova de um gate de autorização exige a topologia adversarial mínima — rota irmã estática sem guarda ao lado de uma rota com `:param`; segundo método HTTP no mesmo caminho; rota declarada porém sem o middleware de papel. **Aplicação aqui**: a rota estática `PUT /contents/:id/strip/frames/order` ao lado da rota `:frameId` (`PATCH`/`DELETE /contents/:id/strip/frames/:frameId`) é exatamente essa topologia — o Critério de pronto acima exige as três chaves como entradas INDEPENDENTES em `ROUTE_ROLES`, nenhuma herdando a declaração da vizinha.
- **[Segurança] Chave de decisão de autz que ganha uma dimensão: todos os leitores ganham, inclusive a allowlist de exceção** (Estado: ativa). **Aplicação aqui: `n/a`, declarado** — a chave de `ROUTE_ROLES` já é `"<MÉTODO> <caminho>"` (2 dimensões) desde a EMENDA de PLAN-003; as 5 rotas novas usam a MESMA forma de chave, sem ganhar dimensão nova, e nenhuma delas é pública (não toca `PUBLIC_PATH_ALLOWLIST`) — nada a propagar a outros leitores.
- **[Testes] Asserção de invariante executada na carga do módulo exige DOIS testes: função + wiring** (Estado: ativa). **Aplicação aqui**: `assertDenyByDefault(apiRoutes)` já tem os dois testes (função + reimportação via `jest.isolateModulesAsync`) de PLAN-003/PLAN-006 — esta TASK não introduz uma invariante de carga de módulo nova, só mais rotas sob a existente. O teste do bullet "a árvore montada é exatamente estes 24 pares" (acima) já serve, ao mesmo tempo, de prova de que `assertDenyByDefault` aceita a árvore real com as 5 rotas novas — é o teste de wiring desta extensão.
- **[Testes] Retry que reescreve arquivo de teste por mudança de assinatura entrega o inventário antes/depois dos `it()`** (Estado: ativa). Solução: quando um arquivo de teste é reescrito, o inventário completo ANTES/DEPOIS dos casos entra na descrição do critério — nunca só "a contagem sobe". **Aplicação aqui** (mesmo princípio, aplicado à extensão do tripwire): o Critério de pronto acima lista o inventário completo dos 19 pares herdados e dos 24 pares finais — nunca só "o tripwire passa a 24".
- **[Testes] Sonda de investigação não nasce em `tests/**` sem isolamento** (Estado: ativa) — já citada acima; reforçada aqui por completude do cruzamento.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Branch**:
**Commit SHA**:
**Jira**: KAN-58
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
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a>

**Notas**:
