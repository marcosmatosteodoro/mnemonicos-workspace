# TASK-006-008: Listar Conteúdos brutos com alcance, ordenação determinística e resumo

**Slug**: producao-material
**Pertence a**: PLAN-006
**Realiza (FRs)**: FR-005-005, FR-005-012, FR-005-021, FR-005-024
**Funcionalidade**: FEAT-005-001 (primária), FEAT-005-002
**Componente**: COMP-006-003 (principal), COMP-006-002
**Wave**: 3
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — `git.branchStrategy: unica`; não criar branch por task; a closure commita TASK a TASK)
**Padrão de commit**: Conventional Commits (`feat:` para esta TASK)
**Framework de teste**: Jest — unit em `mnemonicos-backend/tests/unit/`, integração em `mnemonicos-backend/tests/integration/` (supertest + Postgres via Docker — `npm --prefix mnemonicos-backend run db:up`; `npm --prefix mnemonicos-backend run test:integration`, `--experimental-vm-modules`, `--runInBand`, `maxWorkers: 1`). Fixture de sessão: `seedSession(role)` (`route-authz-matrix.integration.test.ts`). `global-setup.ts` aplica a migração de F2 (T001) sozinho; `resetDb()` trunca as tabelas novas via `pg_tables`.

## Dependências

- **Depende de**: TASK-006-006, TASK-006-002
- **Bloqueia**: TASK-006-011

## Contexto

COMP-006-003 / FR-005-005, FR-005-012, FR-005-024 (FEAT-005-001) e FR-005-021 (FEAT-005-002) / NFR-005-004. Segunda fatia do `contents.service` — o ciclo de vida do item (`createRawContent`/`getRawContent`/`updateRawContent`/`softDeleteRawContent`, o helper de alcance e o filtro `deletedAt: null` centralizado) nasce em **T006**. Aqui entram `listRawContents(query, actor)` → `Paginated<RawContentSummary>` e o `listRawContentsQuerySchema` (só `page`/`perPage`, **sem filtros** — F10 é dona da triagem, NFR-005-004). O alcance por papel (EDITOR vê o que registrou; ADMIN vê tudo) e o filtro `deletedAt: null` **reusam o helper de T006** — não são recriados. Ordenação `createdAt desc` determinística; `select` explícito no join `RawContent → Topic → Discipline`; a flag "tem Quebra da regra" é resolvida **sem** carregar a `RuleBreakdown` inteira. `RawContentSummary` fica **local ao módulo `contents`** (resolução 5 do manifesto — **não** entra em `mnemonicos-backend/src/domain/types.ts`). Gates: g1 · g8 (alcance por autor = autorização de dado / IDOR) · g10 (consulta com join + agregação de existência); g9/g11 n/a.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/contents/contents.schema.ts` (nasce em T006) — `listRawContentsQuerySchema` com **apenas** `page` e `perPage` (coerção numérica + defaults documentados); nenhum campo de filtro, sem `.passthrough()`.
- `mnemonicos-backend/src/modules/contents/contents.service.ts` (nasce em T006):
  - `type RawContentSummary` **local ao módulo** = resumo do texto normativo + nome da disciplina + nome do tema/assunto + `radarClass` + `sourceCitation` + flag "tem Quebra da regra".
  - `listRawContents(query, actor)` → `Paginated<RawContentSummary>` (importa `Paginated<T>` de `../../domain/types` — consolidado por T002; **não** redefine local). Ramo de alcance pelo helper de T006: `deletedAt: null` sempre; `authorId = actor.id` quando o ator é EDITOR; irrestrito (só `deletedAt: null`) quando ADMIN.
  - `orderBy: { createdAt: 'desc' }` determinístico; `skip`/`take` da paginação; `count` para `total` aplicando o **mesmo** predicado de escopo de `data`.
  - `select` explícito no join `RawContent → Topic → Discipline`; flag "tem Quebra" via projeção de existência (ex.: `breakdown: { select: { id: true } }`), sem carregar a `RuleBreakdown` inteira.
- `mnemonicos-backend/tests/integration/contents.service.integration.test.ts` (nasce em T006) — `describe('listRawContents')` com fixtures de 2 EDITORes + item soft-deleted + item com/sem `RuleBreakdown`, e um caso com o Prisma client instrumentado (`log: [{ emit: 'event', level: 'query' }]`) para a contagem de round-trips.
- `mnemonicos-backend/tests/unit/contents.schema.test.ts` (nasce em T006) — casos do `listRawContentsQuerySchema`.

### Não inclui

- Filtros por disciplina/tema/classe do radar — F10 (NFR-005-004 proíbe prometer filtros nesta fatia).
- Rota `GET /contents` e o censo da suíte `route-authz-matrix` — TASK-006-011.
- Render / estados de UI da listagem — TASK-006-012.
- `getRuleBreakdown`/`saveRuleBreakdown` e o `saveRuleBreakdownSchema` — TASK-006-009.
- `RawContentSummary` no `mnemonicos-backend/src/domain/types.ts` — resolução 5 do manifesto: fica local ao módulo.
- Derivação da prioridade de apresentação (DEC-006-009).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `contents.schema.ts` — `listRawContentsQuerySchema` = `z.object({ page: <coerção+default>, perPage: <coerção+default> })`; nada além.
2. `contents.service.ts` — `type RawContentSummary`; `listRawContents(query, actor)` montando o `where` a partir do helper de alcance de T006, `orderBy: { createdAt: 'desc' }`, `select` explícito de `topic.name` / `topic.discipline.name` e `breakdown: { select: { id: true } }`; `prisma.rawContent.count({ where })` para `total` com o **mesmo `where`** de `data`; devolver `{ data, page, perPage, total }` tipado `Paginated<RawContentSummary>`.
3. Estender `contents.service.integration.test.ts` com o `describe('listRawContents')`: fixtures de 2 EDITORes (A, B) com itens distintos, 1 item de A `deletedAt != null`, 1 item com `RuleBreakdown` e 1 sem; caso de contagem de round-trips com Prisma instrumentado.
4. Rodar `npm --prefix mnemonicos-backend run test:integration -- contents.service.integration.test.ts` e `npm --prefix mnemonicos-backend test -- contents.schema`.

## Critérios de pronto

- [ ] `listRawContentsQuerySchema` expõe **só** `page` e `perPage` (Inclui sem AC — contrato do próprio item; NFR-005-004) — verificação executável: `npm --prefix mnemonicos-backend test -- contents.schema` → o parse de `{ page: 2, perPage: 10, disciplineId: 'x', radarClass: 'ALTA' }` devolve **exatamente** `{ page: 2, perPage: 10 }` (chaves de filtro ausentes do resultado); a omissão de `page`/`perPage` aplica os defaults documentados. `Tests: ≥1 passed`. Rodada contra o HEAD (pós-T006): `contents.schema.test.ts` já tem os casos de `createRawContentSchema`/`updateRawContentSchema` (conjunto não-vazio) e **não** tem o `describe('listRawContentsQuerySchema')`. Falsificável: declarar um campo `disciplineId`/`radarClass` no schema, ou `.passthrough()` → a chave aparece no objeto parseado (vermelho). Fixada antes do código.

- [ ] Testes cobrem **AC-005-035** e **AC-005-001** (faceta listagem) — `listRawContents(query, actor)` devolve `Paginated<RawContentSummary>` (`{ data, page, perPage, total }`, com `Paginated<T>` importado de `mnemonicos-backend/src/domain/types.ts`) com ordenação `createdAt desc` determinística, e um item recém-criado consta na resposta com disciplina, tema/assunto e classe do radar. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service.integration.test.ts` → fixture com 3 `RawContent` do mesmo autor criados em `createdAt` distintos → `listRawContents({ page: 1, perPage: 20 }, actor)` retorna `data` do mais recente para o mais antigo; `Object.keys(resposta).sort()` == `['data','page','perPage','total']`; cada item traz nome da disciplina, nome do tema e `radarClass` não-nulos. `Tests: ≥1 passed`. Falsificável: trocar `orderBy` para `asc` ou removê-lo → a asserção de ordem falha; devolver `data` sem o envelope → a asserção de chaves falha. Fixada antes do código; rodada contra o HEAD (pós-T006) mostra a suíte de T006 verde (não-vazia) e sem o `describe('listRawContents')`.

- [ ] Testes cobrem **AC-005-018** (faceta service) + prova de escopo por DADO com fechamento **contável**. Fechamento: **`listRawContents` é o único método novo desta TASK que toca a tabela `raw_contents` (leitura) — 1 metodo, 1 prova** de mutação do predicado de escopo, mais 1 caso por ramo do alcance (EDITOR × ADMIN); os demais métodos que tocam `raw_contents` estão no Escopo de **T006** (`createRawContent`, `getRawContent`, `updateRawContent`, `softDeleteRawContent` — 4 metodos, 4 provas) e **T009** (`getRuleBreakdown`, `saveRuleBreakdown` — 2 metodos). Fixture: **2 EDITORes** (A e B) com `RawContent` distintos + **1** `RawContent` de A com `deletedAt != null`. `listRawContents({}, A)` → só os itens **ativos de A** (nenhum de B, não o soft-deleted); `listRawContents({}, ADMIN)` → todos os itens **ativos** de A e de B (não o soft-deleted). O nome do teste enuncia quem vence: `"ADMIN alcança itens de outro autor; EDITOR só os próprios"`. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service.integration.test.ts` → `Tests: ≥1 passed`. Mutantes (rodam pelo comando acima, **arquivo inteiro — nunca `-t` isolado**): neutralizar o predicado `authorId` no ramo EDITOR → A passa a ver itens de B (vermelho); neutralizar `deletedAt: null` (helper de T006) → algum ramo vê o item soft-deleted (vermelho). Fixture de 2 autores com o predicado neutralizado reprovando — fixada aqui, não deixada para o gate 8. Fixada antes do código.

- [ ] `listRawContents` calcula `total` (contagem para paginação) aplicando o **mesmo** predicado de escopo de `data` — `deletedAt: null` e o alcance do actor. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service.integration.test.ts` → fixture com **3** itens do EDITOR (1 soft-deleted) → `listRawContents({ page: 1, perPage: 10 }, editor)` → `data.length === 2` **e** `total === 2` (não 3). Falsificável: `prisma.rawContent.count()` sem `where` de escopo → `total === 3` → vermelho (paginação errada + vazamento da contagem de removidos). Fixada antes do código.

- [ ] Testes cobrem **AC-005-016** e **AC-005-025** (faceta service) — cada `RawContentSummary` traz ao menos `sourceCitation` e a flag "tem Quebra da regra", e a flag é resolvida **sem** carregar a `RuleBreakdown` inteira. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service.integration.test.ts` → fixture com item X (`sourceCitation` preenchida + `RuleBreakdown` gravada) e item Y (sem `RuleBreakdown`) → o summary de X traz `sourceCitation` == valor semeado e flag de quebra `true`; o summary de Y traz flag `false`. `Tests: ≥1 passed`. Falsificável: omitir `sourceCitation` do `select` → o caso de X falha; fixar a flag como constante `true` → o caso de Y falha. Fixada antes do código.

- [ ] **[Performance]** contagem de round-trips de `listRawContents` FIXADA EM TESTE (gate 10 — join + agregação de existência). Texto da lição (solução, item 3): *"Consulta em caminho por requisição … tem a contagem de round-trips FIXADA EM TESTE (`log: [{ emit: 'event', level: 'query' }]` + asserção sobre o nº de eventos) — asserção sobre o objeto devolvido não é prova de custo."* Ressalva do re-review: *"`previewFeatures = ["relationJoins"]` torna `join` o DEFAULT global … Para relação de lista, medir as duas e fixar a escolhida … o teste de contagem semeia o registro real antes de contar."* Item verificável: com `Topic`, `Discipline` e `RuleBreakdown` **reais** semeados, uma chamada de `listRawContents` emite **exatamente 2** eventos `query` (o `findMany` com o join `Topic → Discipline` e a projeção de existência de `breakdown` + o `count` do `total`); semear **3** itens → **ainda 2** (não cresce com o nº de itens). Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service.integration.test.ts` → caso com Prisma client instrumentado por `log` de query → `queryEvents.length === 2` com 1 e com 3 itens semeados. `Tests: ≥1 passed`. Falsificável: resolver a flag "tem Quebra" com uma consulta por item (N+1) → a contagem cresce com o nº de itens (vermelho); trocar `select` por `include: { topic: true }` → `Object.keys(summary)` traz `topic` cru (vermelho, ver critério seguinte). Fixada antes do código.

- [ ] `select` explícito — nenhum `include` implícito de relação em `listRawContents`. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service.integration.test.ts` → asserção `Object.keys(summary).sort()` == o conjunto documentado de `RawContentSummary` (resumo do texto, nome da disciplina, nome do tema, `radarClass`, `sourceCitation`, flag "tem Quebra") — chave crua de relação (`topic`, `author`, `breakdown`) no objeto reprova. Falsificável: `include: { topic: true, author: true }` → `Object.keys` traz `topic`/`author` (vermelho). Fixada antes do código.

- [ ] `RawContentSummary` **local ao módulo `contents`** (Inclui sem AC — contrato do próprio item): tipo do módulo exercitado com valor **não-nulo** em cada campo (resumo do texto, nome da disciplina, nome do tema, `radarClass`, `sourceCitation`, flag "tem Quebra") pelos casos acima; **não** entra em `mnemonicos-backend/src/domain/types.ts`. Verificação executável (padrão ancorado em declaração de export — contrato §273(b)): `grep -nE "^export (interface|type) RawContentSummary" "mnemonicos-backend/src/domain/types.ts"` → **sem resultado** (contra o HEAD e contra o commit-pai — o tipo nunca entra no domínio compartilhado do backend). Fixada antes do código.

- [ ] **[Testes] "Sonda de investigação não nasce em `tests/**`; contagem de teste declara a árvore"**: os gates desta TASK rodam em `git worktree` isolada **declarada no despacho** (worktree já criada + comando literal; **sem** `node_modules` junctionado — `npm ci` na worktree poda `@babel/core` transitivo e quebra `test:integration`); nenhuma sonda/probe em `mnemonicos-backend/tests/**` (vive no scratchpad, roda por caminho explícito, ou nasce fora do `testMatch`); `testPathIgnorePatterns` cobre `zz-.*`; **nenhum `npm install`/`npm ci` nem edição de `package*.json` na árvore principal**; o report da closure cola `git status --porcelain` (vazio) ao lado de `Tests: N passed`.

- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 e `npm --prefix mnemonicos-backend run typecheck` → exit 0 (baseline capturada no início da TASK: exploração — be `jest` 165/165, typecheck/lint limpos).

- [ ] Padrão de commit respeitado (Conventional Commits — `feat:`).

- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md` + `guidelines/project/backend/`): camadas schema → service (esta TASK não toca rota), erro previsto = `AppError`, `select` explícito no Prisma (nunca `include` implícito), `Paginated<T>` importado de `src/domain/types.ts` (T002) e nunca redefinido local; reusa o helper de alcance e o filtro `deletedAt: null` de T006, não os recria.

- [ ] Code review aprovado.

## Riscos específicos

- **Alcance por autor é predicado de segurança**: o gate 8 confere o número×código do fechamento contável com o código na mão — a fixture de 2 EDITORes + item soft-deleted e os mutantes de neutralização já nascem no gate 1 (não deixar para o gate 8 descobrir).
- **`relationJoins` é DEFAULT global** (Prisma 7, `previewFeatures`): para o join `Topic → Discipline` (relação para-um) a estratégia `join` resolve em 1 statement; a contagem fixada é 2 (dados + `count`). Se a projeção de existência da Quebra for feita por relação de lista, medir `query` × `join` e fixar a escolhida (ressalva da lição [Performance]).
- Integração exige Docker Postgres no ar (`npm --prefix mnemonicos-backend run db:up`); banco `mnemonicos_test` separado, `global-setup.ts` aplica a migração de F2 (T001) sozinho.
- Repos symlinkados (lição [Exploração]): editar e verificar sempre pelo caminho **dentro** do link (`mnemonicos-backend/src/...`); ausência detectada por varredura não é fato.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-36
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
