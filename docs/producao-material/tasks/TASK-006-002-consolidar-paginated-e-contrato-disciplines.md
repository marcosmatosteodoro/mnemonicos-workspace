# TASK-006-002: Consolidar `Paginated<T>` no domínio do backend e estender `GET /disciplines` com a lista de temas

**Slug**: producao-material
**Pertence a**: PLAN-006
**Realiza (FRs)**: FR-005-024
**Funcionalidade**: FEAT-005-001 (primária)
**Componente**: COMP-006-007 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done
**Data início**: 2026-09-04T22:02:12+0000

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — `git.branchStrategy: unica`; não criar branch por task; a closure commita TASK a TASK)
**Padrão de commit**: Conventional Commits (`feat:` para esta TASK — a parte 2 estende o contrato de `GET /disciplines`)
**Framework de teste**: Jest — unit em `mnemonicos-backend/tests/unit/`; integração em `mnemonicos-backend/tests/integration/` (Docker Postgres `mnemonicos_test` via `npm --prefix mnemonicos-backend run db:up`; `npm --prefix mnemonicos-backend run test:integration`). Client de teste com `log: [{ emit: 'event', level: 'query' }]` para a contagem de round-trips.

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-006-004, TASK-006-008, TASK-006-010

## Contexto

Duas partes numa fatia só. **(1)** `disciplines.service.ts:4-16` redefine `Paginated<T>` local (hoje `export interface Paginated<T>`) em vez de importar de `domain/types.ts`; o módulo `contents` (TASK-006-006/008) traria a 3ª cópia do mesmo envelope — esta TASK consolida o tipo em `mnemonicos-backend/src/domain/types.ts` (compartilhado, sem I/O — DEC-006-007) e `disciplines.service.ts` passa a **importar**. `DisciplineSummary` permanece **local** ao módulo `disciplines`; `RawContentSummary` não é criado aqui. **(2)** O formulário de Conteúdo bruto (TASK-006-013) precisa de uma fonte de opções de **disciplina e tema/assunto** (A-005-007 — pick-only do acervo semeado); hoje `GET /disciplines` só devolve `topicsCount`. Esta TASK estende `DisciplineSummary` com `topics: { id, name, slug }[]` (ordenados por `name`) e `listDisciplines` passa a trazê-los por `select` explícito da relação — **medindo `query` × `join`** (relação de lista, ressalva da lição [Performance]) e fixando a estratégia em teste. Estender `/disciplines` é a rota mínima: já montada, já `EDITOR`/`ADMIN`, sem tripwire novo. FR-005-024 (ordenação/estados da listagem de Conteúdo bruto) é realizado nominalmente aqui — o enforço é em TASK-006-008 (service) e TASK-006-012 (tela); o alinhamento do frontend ao envelope é TASK-006-010. Gates: g1; g10 (a parte 2 toca superfície de custo de consulta — `select` aninhado de relação de lista); g8/g9/g11 n/a.

## Escopo

### Inclui

**Parte 1 — consolidação de `Paginated<T>`**

- Mover `export type Paginated<T> = { data: T[]; page: number; perPage: number; total: number }` (equivalente ao `export interface Paginated<T>` atual) de `mnemonicos-backend/src/modules/disciplines/disciplines.service.ts` para `mnemonicos-backend/src/domain/types.ts` (junto dos tipos puros já lá); `disciplines.service.ts` passa a **importar** o tipo.
- `DisciplineSummary` permanece **local** ao módulo `disciplines` (não migra).
- Teste com valor **não-nulo** exercitando `Paginated<T>` importado de `domain/types.ts`.

**Parte 2 — estender `GET /disciplines` com a lista de temas**

- `DisciplineSummary` (em `disciplines.service.ts`) ganha `topics: { id: string; name: string; slug: string }[]` — a lista dos temas de cada disciplina, ordenada por `name`.
- `listDisciplines` passa a trazer os temas via `select` **explícito** da relação: `topics: { select: { id: true, name: true, slug: true }, orderBy: { name: 'asc' } }` (substituindo/somando ao `_count` atual conforme a estratégia escolhida) — **medir `query` × `join`** (lição [Performance] "`include`/`select` aninhado de relação não é 1 statement por padrão"; `relationJoins` é default global e para relação de lista `join` nem sempre vence) e **fixar a estratégia escolhida em teste** (contagem de round-trips com ≥1 disciplina com ≥2 temas semeados **antes** de contar).
- Teste de integração de `/disciplines` cobrindo a forma nova da resposta.

### Não inclui

- Filtro ou paginação de temas dentro de `/disciplines`.
- Endpoint de temas como recurso próprio (`/topics`, `/disciplines/:id/topics`).
- Qualquer consumo dos temas no frontend — TASK-006-004 (tipo `Discipline`), TASK-006-010 (`api.ts`), TASK-006-013 (select do formulário).
- Alinhamento do frontend ao envelope `Paginated<T>` (`listDisciplines` de `src/store/api.ts`) — TASK-006-010.
- `RawContentSummary` (nasce local ao módulo `contents` — TASK-006-006/008).
- Qualquer novo campo do envelope `Paginated<T>` ou mudança da forma da paginação de `/disciplines`.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Cortar a definição de `Paginated<T>` de `disciplines.service.ts` e colá-la em `src/domain/types.ts` (junto dos tipos puros já lá); em `disciplines.service.ts`, `import { Paginated } from '../../domain/types'` (conferir o caminho relativo real do módulo).
2. Escrever o teste unit de uso não-nulo do `Paginated<T>` importado.
3. Em `DisciplineSummary`, acrescentar `topics: { id: string; name: string; slug: string }[]`.
4. Em `listDisciplines`, acrescentar `topics: { select: { id: true, name: true, slug: true }, orderBy: { name: 'asc' } }` ao `select`; mapear cada `row.topics` no retorno. Medir a contagem de statements com `query` e com `join` (client instrumentado por `log`), escolher e **fixar** a estratégia, documentando qual no critério e no código.
5. Estender o teste de integração de `/disciplines`: chaves antigas do summary inalteradas + `topics` como array de `{id,name,slug}` ordenado por `name`; contagem de round-trips fixa.
6. Rodar a suíte **inteira** de `disciplines` (unit + integração), não um filtro estreito.

## Critérios de pronto

- [ ] `Paginated<T>` tem **uma única** definição, em `mnemonicos-backend/src/domain/types.ts`, e `disciplines.service.ts` a importa. Verificação executável (padrão ancorado em início de linha — contrato §273(b)): `grep -rnE "^export (type|interface) Paginated" mnemonicos-backend/src` → exatamente **1 linha**, em `src/domain/types.ts`; `grep -nE "^\s*(export\s+)?(type|interface)\s+Paginated" mnemonicos-backend/src/modules/disciplines/disciplines.service.ts` → **sem resultado** (nenhuma definição local; só linha(s) de `import`). Baseline (commit-pai): o 1º `grep` casa 1 linha em `disciplines.service.ts:4-16` — é a linha que **migra**. Falsificável: deixar cópia local → 2 ocorrências de `^export (type|interface) Paginated`, vermelho. Fixada antes do código.
- [ ] `Paginated<T>` exportado é exercitado por teste com valor **não-nulo** (item do Inclui sem AC — oráculo é o contrato do item): um teste unit em `mnemonicos-backend/tests/unit/` importa `Paginated` de `src/domain/types.ts` e tipa um valor concreto não-nulo (`const p: Paginated<{ id: string }> = { data: [{ id: 'x' }], page: 1, perPage: 20, total: 1 }`) com asserção sobre `p.data.length` e `p.total`. Verificação executável: `npm --prefix mnemonicos-backend test -- <arquivo>` → `Tests: ≥1 passed`; `npm --prefix mnemonicos-backend run typecheck` → exit 0. Falsificável: renomear um campo do envelope em `domain/types.ts` (`perPage` → `per_page`) → typecheck vermelho no consumidor e o objeto de teste não casa. Fixada antes do código.
- [ ] `DisciplineSummary` **não** migra para `domain/types.ts` — `grep -nE "^export (interface|type) DisciplineSummary" mnemonicos-backend/src/domain/types.ts` → **sem resultado** (padrão ancorado em declaração de export; também sem resultado no commit-pai — `DisciplineSummary` nunca esteve em `domain/types.ts`). Falsificável: mover `DisciplineSummary` junto → o `grep` casa, vermelho. Fixada antes do código.
- [ ] **Identidade parcial** (a parte que não muda comportamento) — a consolidação de `Paginated<T>` **não altera** a forma da resposta de `GET /disciplines` além da adição de `topics`. Verificação executável: teste de integração de `/disciplines` (sessão EDITOR) mostrando `data[0]` com as chaves antigas (`id`, `name`, `slug`, `topicsCount`) **inalteradas** + a chave `topics` nova como array; a suíte de `disciplines` **inteira** verde — `npm --prefix mnemonicos-backend run test:integration -- disciplines` → todos passam. Falsificável: renomear uma chave antiga do summary (`topicsCount` → `topics_count`) → vermelho. Fixada antes do código.
- [ ] Cobre **AC-005-004** (faceta "fonte do campo tema") — `GET /disciplines` (sessão EDITOR) → para as disciplinas semeadas com temas, cada `data[i].topics` é um array **não-vazio** de `{ id, name, slug }`, ordenado por `name`. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- disciplines` → fixture com ≥1 disciplina e ≥2 temas semeados → asserção sobre `data[i].topics` (array de `{id,name,slug}`, `name` em ordem ascendente). Falsificável: não incluir `topics` no `select` → `topics` ausente/`undefined` no summary → vermelho. (A recusa "tema ausente → sinaliza o campo" na tela é TASK-006-013; aqui a TASK entrega **a fonte de opções** sem a qual TASK-006-013 não é verificável.) Fixada antes do código.
- [ ] **Round-trips fixados** (lição [Performance] — relação de lista) — com `log: [{ emit: 'event', level: 'query' }]` no client de teste, o nº de eventos `query` de `listDisciplines` com N disciplinas × M temas == valor **fixado** e documentado (registrar no critério e no código se a estratégia é `query` ou `join`); semear os registros reais (≥1 disciplina com ≥2 temas) **antes** de contar. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- disciplines` → caso de contagem com 1 e com 2 disciplinas semeadas → o nº de `query` **não cresce** com o nº de disciplinas nem de temas (não é N+1). Falsificável: trocar a estratégia escolhida sem atualizar o valor fixado → a contagem muda → vermelho; resolver `topics` por consulta por disciplina (N+1) → a contagem cresce → vermelho. Fixada antes do código.
- [ ] Lição ativa [Performance] "`include`/`select` aninhado de relação não é 1 statement por padrão" transcrita como item verificável. Texto da lição (solução + ressalva): *"(1) `select` explícito, sempre — só os campos usados. (3) consulta em caminho por requisição tem a contagem de round-trips FIXADA EM TESTE (`log: [{ emit: 'event', level: 'query' }]` + asserção sobre o nº de eventos). Ressalva: `previewFeatures = ["relationJoins"]` torna `join` o DEFAULT global; para relação de lista, medir `query` × `join` e fixar a escolhida; `relationLoadStrategy:'query'` só emite o 2º SELECT quando a linha relacionada existe — semear o registro real antes de contar."* Aplicada a `listDisciplines` (relação `Discipline → Topic`, lista): `select` explícito de `topics` (só `id`/`name`/`slug`), sem `include` de relação não usada; estratégia medida e fixada. Verificação executável: `grep -nE "^\s*include:\s*\{" mnemonicos-backend/src/modules/disciplines/disciplines.service.ts` → **sem resultado** (nenhum `include` implícito); o caso de contagem de round-trips acima. Fixada antes do código.
- [ ] Não-regressão da consolidação + extensão: `npm --prefix mnemonicos-backend test` — suíte unit inteira verde (baseline 165/165); `npm --prefix mnemonicos-backend run test:integration -- disciplines` — suíte **inteira** de `disciplines` verde (contrato §273(d) — arquivo compartilhado `Paginated<T>` alcança os outros consumidores; não um `--filter` estreito de `contents`). `grep -rnE "^\s*(export\s+)?(type|interface)\s+Paginated" mnemonicos-backend/src` → exatamente 1 (em `domain/types.ts`) — nenhum import órfão. O teste de paridade `domain-types-parity.test.ts` (regex hard-coded sobre `USER_ROLES`) continua verde — `Paginated<T>` é tipo genérico, não constante `as const`, e não entra no extrator.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline capturada); `npm --prefix mnemonicos-backend run typecheck` → exit 0.
- [ ] Padrão de commit respeitado (Conventional Commits — `feat:`).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md`: `src/domain/types.ts` = tipos puros sem I/O; módulo mantém camadas schema→service→routes; `select` explícito no Prisma, nunca `include` implícito; guidelines de projeto vencem o perfil).
- [ ] Code review aprovado.

## Riscos específicos

- Arquivo compartilhado: `Paginated<T>` é consumido por `disciplines` hoje e por `contents` nas TASKs seguintes — a verde da TASK exige a suíte **inteira** de `disciplines`, não um filtro estreito (contrato §273(d)).
- `topics` é relação de **lista** (1-N de volume variável): `relationJoins` é default global e `join` nem sempre vence `query` — medir as duas e fixar a escolhida explicitamente (ressalva da lição [Performance]).
- `domain/types.ts` é lido pelo teste de paridade cross-repo (`domain-types-parity.test.ts`) e pelo espelho do frontend — adicionar um tipo genérico não deve quebrar o extrator, mas conferir o teste após a mudança.
- Repos symlinkados (lição [Exploração]): editar/verificar pelo caminho dentro do link.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-04T19:14:00-03:00
**Data conclusão**: 2026-09-04T19:42:14-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: a1725a0 (impl) · 827e36e (retry gate 1-7)
**Jira**: KAN-30
**Implementado por**: developer
**Revisado por**: code-reviewer (gates 1-7) · security-engineer (gate 8) · performance-engineer (gate 10)
**Tentativas**: 2 (1 code-review reprovou por 3 achados baratos + achado de escopo de TASK-006-001; retry fechou os 4; re-review delta aprovou)
**Cobertura final**: n/a (312 testes verdes pós-implementação; 14/14 no escopo `disciplines` pós-retry)
**Arquivos modificados**:
  - mnemonicos-backend/src/domain/types.ts
  - mnemonicos-backend/src/modules/disciplines/disciplines.service.ts
  - mnemonicos-backend/src/modules/users/users.service.ts (2º consumidor de Paginated<T>, ajuste dentro do Art. 6)
  - mnemonicos-backend/tests/integration/disciplines.integration.test.ts
  - mnemonicos-backend/tests/unit/domain-types-paginated.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados: AC-005-004 (faceta "fonte do campo tema")
- [x] Segurança (gate 8): aprovado — security-engineer, Wave 1
- [ ] Comportamento (gate 9): n/a — sem efeito observável de tela nesta TASK; FEAT-005-001 ainda não completa

**Notas**: `relationLoadStrategy: 'join'` medido (1 round-trip fixo, não escala com N) e fixado em teste. Retry provou a 2ª cláusula do deny-by-default (STUDENT→403) e consolidou o probe de queries duplicado; carona de gate 7 renomeou o título do caso de 401 que sobre-prometia (commit `ed12238`, riding com o fecho da wave). `licao_candidata` [projeto] roteada (mesma lição de T001, confirmada 2).
