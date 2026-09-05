# TASK-006-006: `contents.service` + `contents.schema` — ciclo de vida do Conteúdo bruto

**Slug**: producao-material
**Pertence a**: PLAN-006
**Realiza (FRs)**: FR-005-001, FR-005-002, FR-005-003, FR-005-006, FR-005-007, FR-005-008, FR-005-010, FR-005-011, FR-005-013
**Funcionalidade**: FEAT-005-001 (primária)
**Componente**: COMP-006-003 (principal), COMP-006-002
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — `git.branchStrategy: unica`; não criar branch por task; a closure commita TASK a TASK)
**Padrão de commit**: Conventional Commits (`feat:` para esta TASK)
**Framework de teste**: Jest — unit (schema Zod) em `mnemonicos-backend/tests/unit/`; service sobre Postgres real em `mnemonicos-backend/tests/integration/` (Docker `mnemonicos_test` via `npm --prefix mnemonicos-backend run db:up`; `npm --prefix mnemonicos-backend run test:integration`, `--runInBand`). Client de teste com `log: [{ emit: 'event', level: 'query' }]` para a contagem de round-trips.

## Dependências

- **Depende de**: TASK-006-001
- **Bloqueia**: TASK-006-008, TASK-006-009, TASK-006-011

## Contexto

Módulo backend `mnemonicos-backend/src/modules/contents/` no padrão schema (Zod) → service (regra + Prisma, sem I/O de HTTP) → routes. Esta TASK entrega `contents.schema.ts` (nasce aqui) e o **núcleo** do `contents.service.ts`: criar, reabrir, editar e remover (reversível) o Conteúdo bruto, com a regra de **alcance por papel** (EDITOR vê o que registrou; ADMIN irrestrito), o filtro `deletedAt: null` **centralizado**, a **imutabilidade da autoria** na edição e o carimbo de última alteração. `listRawContents` (TASK-006-008), a Quebra da regra (`getRuleBreakdown`/`saveRuleBreakdown` — TASK-006-009) e as rotas HTTP (TASK-006-011) ficam fora. O helper de alcance e o filtro de remoção reversível nascem aqui e são **reusados** pela listagem e pela Quebra. Gates: g1; g8 (alcance por autor = autorização de dado / IDOR); g10 (superfície de consulta — `select`/round-trips); g9/g11 n/a.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/contents/contents.schema.ts`:
  - `createRawContentSchema` — `topicId`, `rawText`, `radarClass` (∈ `ProofRadarClass`), `sourceType?` (∈ `NormativeSourceType`), `sourceCitation?`, `sourceUrl?`; refinamento: `sourceCitation` **obrigatória quando `sourceType` presente**.
  - `updateRawContentSchema` — mesmos campos aplicáveis, **sem `authorId`**; mesmo refinamento de fonte.
- `mnemonicos-backend/src/modules/contents/contents.service.ts`:
  - `createRawContent(input, actorId)` — grava `authorId = actorId` (nunca do `input`).
  - `getRawContent(id, actor)` — devolve quando ativo e no alcance; lança `AppError` **404** quando `id` inexistente, `deletedAt != null`, **ou** fora do alcance.
  - `updateRawContent(id, input, actor)` — persiste os novos valores sob as regras de obrigatoriedade do registro; `authorId` **intocado**; seta `lastEditedById = actor.id` e `lastEditedAt = now`.
  - `softDeleteRawContent(id, actor)` — seta `deletedAt = now` no item no alcance do actor; a `RuleBreakdown` vinculada **não** é apagada (DEC-006-001).
  - Filtro `deletedAt: null` **centralizado** (uma fonte) e helper de alcance reusável (`EDITOR`: `authorId = actor.id`; `ADMIN`: irrestrito).
  - `select` **explícito** nas consultas Prisma; sem `include` implícito de relação não consumida.
- Testes: unit do schema (`tests/unit/`) + service sobre Postgres real (`tests/integration/contents.service.integration.test.ts`).

### Não inclui

- `listRawContents` / `listRawContentsQuerySchema` (TASK-006-008).
- `getRuleBreakdown` / `saveRuleBreakdown` / `saveRuleBreakdownSchema` (TASK-006-009).
- Rotas HTTP, `verifyOrigin`, `requireRole`, montagem em `routes.ts`, tripwire da `route-authz-matrix` (TASK-006-011).
- Sinalização de campo pendente/inválido na UI (TASK-006-013) — aqui só o `safeParse` do schema recusa e nomeia o campo.
- Derivação da prioridade de apresentação (DEC-006-009).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `contents.schema.ts` — os dois schemas + o refinamento de fonte; `updateRawContentSchema` sem `authorId`.
2. `contents.service.ts` — `import { prisma } from '../../lib/prisma'`; um helper `scopeWhere(actor)` (EDITOR → `{ authorId: actor.id }`, ADMIN → `{}`) e uma constante/spread de `{ deletedAt: null }` usados por **todas** as leituras; `createRawContent`/`updateRawContent`/`softDeleteRawContent`; erro previsto = `AppError` 404.
3. `select` explícito só dos campos que cada retorno usa; se `getRawContent` precisar de campo de `topic` ou da existência da Quebra, medir `query` × `join` e fixar.
4. Testes: unit do schema; integração do service com fixture de 2 autores + 2 instâncias (uma ativa, uma soft-deleted).

## Critérios de pronto

- [ ] `contents.schema.ts` recusa e nomeia o campo — cobre **AC-005-002**, **AC-005-003**, **AC-005-004**, **AC-005-015**. Verificação executável: `npm --prefix mnemonicos-backend test -- contents.schema` → casos `safeParse`: `radarClass` ausente → falha, `radarClass` no `issues`; `radarClass` fora de `{ALTA,MEDIA,DETALHE,EXCECAO,PEGADINHA}` → falha; `rawText`/`topicId` ausentes → falha listando os campos; `sourceType` presente sem `sourceCitation` → falha em `sourceCitation`; `sourceType` fora do enum → falha; + 1 caminho feliz. `Tests: ≥6 passed`. Falsificável: tornar `radarClass` opcional → o caso AC-005-002 fica verde-sem-erro (vermelho); remover o refinamento → o caso "tipo sem citação" passa (vermelho). Fixada antes do código.
- [ ] `updateRawContentSchema` **não** aceita `authorId` — o valor nunca alcança `updateRawContent`. Verificação executável: `npm --prefix mnemonicos-backend test -- contents.schema` → caso que faz `updateRawContentSchema.parse({ ...válido, authorId: 'x' })` e assere `!('authorId' in parsed)` (schema `.strip()` ou rejeição); **checagem estrutural ancorada em campo (contrato §273(b))**: `grep -nE "^\s*authorId\s*:" mnemonicos-backend/src/modules/contents/contents.schema.ts` → **sem resultado** (nenhum shape do módulo declara `authorId` como campo — nem `create`, nem `update`; o `authorId` vem do `actorId` da sessão). Falsificável: incluir `authorId` no shape do update → o caso `.parse` vermelho e o `grep` casa. Fixada antes do código.
- [ ] `createRawContent(input, actorId)` grava `authorId = actorId` (nunca do `input`) e persiste os campos validados — cobre **AC-005-001** (faceta service). Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service` → `createRawContent(input, editorA.id)` (o `input` de teste **não** carrega `authorId`, ou carrega um id diferente) → linha em `raw_contents` com `authorId === editorA.id`, `radarClass` como no input. `Tests: ≥1 passed`. Falsificável: derivar `authorId` do `input` → asserção vermelha. Fixada antes do código.
- [ ] `updateRawContent(id, input, actor)` — persiste os novos valores, **não toca `authorId`**, seta `lastEditedById = actor.id` + `lastEditedAt ≈ now` — cobre **AC-005-009** (faceta service) e **AC-005-036** (ADMIN edita item de EDITOR: autoria original inalterada; carimbo passa a apontar o ADMIN). Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service` → semear `RawContent` com `authorId = editorA.id`; `updateRawContent(id, { rawText: 'novo' }, adminActor)` → relido: `authorId === editorA.id` (inalterado), `rawText === 'novo'`, `lastEditedById === admin.id`, `lastEditedAt` no minuto corrente. `Tests: ≥2 passed`. Falsificável: sobrescrever `authorId` com `actor.id` → `authorId === editorA.id` vermelho; não setar o carimbo → `lastEditedById` vermelho. Fixada antes do código.
- [ ] `getRawContent(id, actor)` — devolve o conteúdo (incl. `sourceType`/`sourceCitation`/`sourceUrl` como persistidos) quando ativo e no alcance; lança `AppError` **404** quando (a) `id` inexistente, (b) `deletedAt != null`, (c) fora do alcance (EDITOR pedindo item de outro autor) — cobre **AC-005-008** (reabrir mostra os campos persistidos, fonte normativa incluída), **AC-005-014** (faceta service — tipo/citação/link da fonte normativa aparecem como persistidos ao reabrir) e **AC-005-037** (removido → acesso por id direto recusado). Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service` → fixture de 2 autores (`editorA`, `editorB`) + 2 instâncias (uma ativa de `editorA` com fonte preenchida, uma soft-deleted de `editorA`): `getRawContent(ativoA, editorA)` → objeto com a fonte como persistida; `getRawContent('inexistente', editorA)` / `getRawContent(softDeletedA, editorA)` / `getRawContent(ativoA, editorB)` → cada um lança `AppError` 404. `Tests: ≥4 passed`. Falsificável: remover o filtro `deletedAt: null` → o caso (b) devolve o objeto (vermelho); alcance neutralizado → o caso (c) devolve o objeto (vermelho). Fixada antes do código.
- [ ] `softDeleteRawContent(id, actor)` — seta `deletedAt` no item no alcance; depois dele `getRawContent(id, actor)` lança 404, e a linha de `rule_breakdowns` (se semeada) **continua** no banco — cobre **AC-005-037** (faceta remoção → inacessível por id direto), **AC-005-013** (faceta service — a Quebra vinculada deixa de ser alcançável junto do pai; a recusa de `getRuleBreakdown` sobre pai soft-deleted é completada em TASK-006-009) e a faceta "e depois o remove … autoria inalterada" de **AC-005-036**. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service` → capturar `authorId`/`lastEditedById` da linha antes; `softDeleteRawContent(ativoA, editorA)` → `deletedAt` NOT NULL na linha; **`authorId` e `lastEditedById` da linha permanecem os de antes** (o soft-delete não é uma edição de autoria); `getRawContent(ativoA, editorA)` → 404; `SELECT` direto em `raw_contents`/`rule_breakdowns` ainda acha as linhas. `Tests: ≥3 passed`. Falsificável: `softDeleteRawContent` fazendo `DELETE` físico → o `SELECT` direto não acha a linha (vermelho — a remoção é reversível); `softDeleteRawContent` setando `lastEditedById = actor.id` → a asserção de autoria inalterada fica vermelha. Fixada antes do código.
- [ ] **Lição ativa [Segurança] "Guarda de estado de conta/sessão: enumerar por DADO, não por rota"** + contrato §273(c) (predicado de escopo na persistência). Texto da lição (solução): *"ao introduzir uma guarda de estado de conta/sessão, enumerar por dado, não por rota — toda função que lê o recurso escopado recebe a mesma guarda no mesmo diff, cada uma com prova de negação (fixture de 2 instâncias, mutação do filtro reprova)."* Critério de mutação **contável**: **todo método de `contents.service.ts` que toca a tabela `raw_contents` (leitura ou escrita, com ou sem predicado hoje) — `createRawContent`, `getRawContent`, `updateRawContent`, `softDeleteRawContent`: 4 metodos, 4 provas** de mutação do predicado de escopo (`deletedAt: null` e/ou `authorId` do helper de alcance). Fixture com **2 autores** (`editorA`, `editorB`) + **2 instâncias** (uma ativa, uma soft-deleted). Para cada método, neutralizar o predicado no método (`deletedAt: null` **ou** o alcance `authorId`) → a prova correspondente **reprova**; `createRawContent` (escrita sem predicado hoje) entra com o cenário "o `authorId` vem do `actorId` da sessão, nunca do `input`" — mutar para ler `authorId` do `input` reprova. Mais um caso por ramo EDITOR × ADMIN do alcance nos métodos de leitura/edição/remoção. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service` → o inventário de casos do arquivo declara **"4 metodos, 4 provas"** e cada mutação nomeada mata ao menos um caso, **rodada pelo comando do critério** (suíte/arquivo inteiro, nunca `-t` isolado). Fixada antes do código; o confronto número × código é do gate 8.
- [ ] **Lição ativa [Testes] "Árvore de decisão com precedência: um caso por PAR de ramos que coincide"**. Texto da lição (solução + corolário): *"toda árvore de decisão com precedência declarada ganha um caso por par de ramos que pode coincidir — não só um por ramo —, e o nome do teste enuncia quem vence; o mutante que troca a ordem daquele par morre. Função com ≥3 guards em ordem declarada → o Critério enumera os pares que podem coincidir, com o mutante de reordenação como aceite."* Aplicada a `getRawContent` e `updateRawContent` (3 guards em ordem: `id inexistente → 404` · `deletado → 404` · `fora do alcance → 404`): o par **`deletado ∧ fora do alcance`** coincide e é alcançável (item soft-deleted **de outro autor**, pedido por um EDITOR) e tem caso próprio, cujo nome enuncia qual guard responde. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service` → caso "item soft-deleted de outro autor → 404" para `getRawContent` e para `updateRawContent`; o **mutante que troca a ordem** dos dois guards **morre** pela suíte do critério (não `-t` isolado). Falsificável: sem esse caso, reordenar os guards mantém tudo verde. Fixada antes do código.
  **Furo no plano declarado no retry da Wave 2** (aceito pelo `code-reviewer`, mesma classe do "mesmo commit" de TASK-006-004): o desenho entregue usa `where` **conjuntivo** (`{ id, ...ACTIVE_RAW_CONTENT_WHERE, ...scopeWhere(actor) }`, sem colisão de chave) — a ordem do spread é semanticamente inerte, então "o mutante que troca a ordem dos dois guards morre" é estruturalmente inaplicável a este desenho (não há precedência a observar). A proteção substantiva continua provada: o fixture do par coincidente (soft-deleted de outro autor) permanece, e os 4 mutantes do critério contável acima (predicado `deletedAt`/`authorId`) sustentam peso. Os nomes dos casos foram corrigidos para "as duas negações valem, sem precedência a observar".
- [ ] **Lição ativa [Performance] "`include`/`select` aninhado de relação não é 1 statement por padrão"**. Texto da lição (solução + ressalva): *"(1) `select` explícito, sempre — só os campos usados. (3) consulta em caminho por requisição tem a contagem de round-trips FIXADA EM TESTE (`log: [{ emit: 'event', level: 'query' }]` + asserção sobre o nº de eventos) — asserção sobre o objeto devolvido não é prova de custo. Ressalva: `relationJoins` ligado torna `join` o default global; para relação de lista, medir `query` × `join` e fixar a escolhida; `relationLoadStrategy:'query'` só emite o 2º SELECT quando a linha relacionada existe — semear o registro real antes de contar."* Aplicada a `getRawContent`: `select` **explícito** só dos campos consumidos, sem `include` de relação não usada. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service` → um caso com client de teste `log: [{ emit:'event', level:'query' }]` que **semeia a linha real** e assere o nº de statements de `getRawContent`; **checagem estrutural ancorada em início de linha (contrato §273(b))**: `grep -nE "^\s*include:\s*\{" mnemonicos-backend/src/modules/contents/contents.service.ts` → **sem resultado** (nenhum `include` implícito de relação não consumida). Falsificável: trocar `select` explícito por `include: { topic: true, author: true }` → a contagem de round-trips sobe, caso vermelho, e o `grep` casa. Fixada antes do código.
- [ ] **Lição ativa [Testes] "Sonda de investigação não nasce em `tests/**`; contagem de teste declara a árvore"** — o teste de service nasce como `mnemonicos-backend/tests/integration/contents.service.integration.test.ts` versionado, nome no `testMatch` (não `zz-*`); o caso de medição de round-trips do critério acima é caso versionado, não sonda solta; nenhuma sonda de perf/N+1 em `tests/**`; a closure declara a contagem com `git status --porcelain mnemonicos-backend/` **vazio**; gate que escreve arquivo (mutação) roda em `git worktree` isolada, sem `npm ci`/`npm install` na árvore principal; `testPathIgnorePatterns` cobre `zz-.*`. Verificação executável: `git status --porcelain mnemonicos-backend/` → vazio após o commit; `npm --prefix mnemonicos-backend run test:integration` → contagem declarada == observada.
- [ ] `createRawContent` e `updateRawContent` aplicam o **mesmo** conjunto de obrigatoriedade (FR-005-007 faceta service) — o update reusa `createRawContentSchema` / o refinamento de fonte; provado por um caso de `updateRawContentSchema` que recusa `sourceType` sem `sourceCitation`. Verificação executável: `npm --prefix mnemonicos-backend test -- contents.schema` → caso do update; `Tests: ≥1 passed`.
- [ ] Camadas respeitadas (`node-22.md`): `contents.schema.ts` só Zod; `contents.service.ts` só regra + Prisma (`import { prisma } from '../../lib/prisma'`), sem I/O de HTTP, erro previsto = `AppError`. Verificação executável (padrão ancorado / comentário excluído — contrato §273(b)): `grep -nE "^\s*import .* from 'express'" mnemonicos-backend/src/modules/contents/contents.service.ts` → **sem resultado**; `grep -vE "^\s*(//|\*|/\*)" mnemonicos-backend/src/modules/contents/contents.service.ts | grep -nE "\breq\.|\bres\.|from 'express'"` → **sem resultado**. Falsificável: importar `express`/manipular `req`/`res` no service → algum `grep` casa, vermelho.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline capturada); `npm --prefix mnemonicos-backend run typecheck` → exit 0.
- [ ] Não-regressão: `npm --prefix mnemonicos-backend test` (unit, baseline 165/165) e `npm --prefix mnemonicos-backend run test:integration` — suítes inteiras verdes (rodar `db:up` antes; a integração não foi exercitada no sync).
- [ ] Padrão de commit respeitado (Conventional Commits — `feat:`).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md`: módulo `src/modules/contents/` com camadas schema→service→routes; Prisma só no service; Express 5 async sem try/catch nos consumidores; `select` explícito).
- [ ] Code review aprovado.

## Riscos específicos

- **TRISK-006-003** — a remoção reversível exige `deletedAt: null` em **todo** caminho de leitura; o filtro nasce **centralizado** aqui e é reusado por TASK-006-008/009. Um caminho que não passe pelo helper vaza conteúdo removido.
- **IDOR / alcance por autor** (lição [Segurança] "enumerar por DADO"): fixture de **2 autores** é o piso da prova — fixture de 1 autor deixa o predicado decorativo e a suíte segue verde com ele removido.
- Contagem de round-trips com `relationJoins` global: para relação de **lista**, `join` nem sempre vence `query` — medir as duas e fixar; `relationLoadStrategy:'query'` só emite o 2º SELECT com a relação existente (semear antes de contar).
- Integração precisa de Docker Postgres (`db:up`) + migração de TASK-006-001 aplicada (o `global-setup.ts` aplica sozinho).
- Repos symlinkados (lição [Exploração]): editar/verificar pelo caminho dentro do link.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-04T20:00:48-03:00
**Data conclusão**: 2026-09-05T00:52:10-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 96ba180 (impl) · f4fa5b7 (retry gate 1-7/8)
**Jira**: KAN-34
**Implementado por**: developer
**Revisado por**: code-reviewer (gates 1-7) · security-engineer (gate 8) · performance-engineer (gate 10)
**Tentativas**: 2 (1ª passada reprovou por reimplementação de enum de domínio + achados de segurança/performance na `contents.schema.ts`/`contents.service.ts`; retry fechou os 8 itens consolidados; re-review delta aprovou os 3 gates)
**Cobertura final**: n/a (190/190 unit, 174/174 integração pós-retry)
**Arquivos modificados**:
  - mnemonicos-backend/src/modules/contents/contents.schema.ts
  - mnemonicos-backend/src/modules/contents/contents.service.ts
  - mnemonicos-backend/tests/unit/contents.schema.test.ts
  - mnemonicos-backend/tests/integration/contents.service.integration.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados: AC-005-001/002/003/004/008/009/013/014/015/036/037
- [x] Segurança (gate 8): aprovado — Wave 2, após retry (IDOR/alcance por autor provado por mutação — 4 métodos, 4 provas; race condition fechada com `updateMany` atômico; `sourceUrl` com allowlist http(s))
- [ ] Comportamento (gate 9): n/a — sem efeito observável de tela nesta TASK (service puro); FEAT-005-001/002 ainda não completas

**Notas**: Fechamento contável "4 métodos, 4 provas" confirmado com o código na mão pelo gate 8 (mutantes mortos, não só número batendo). `updateRawContent`/`softDeleteRawContent` colapsados em `updateMany` atômico no retry, fechando check-then-act + reduzindo round-trips. `furo_no_plano` declarado e aceito: o critério original pedia mutante de reordenação de guards, estruturalmente inaplicável ao `where` conjuntivo entregue (mesma classe do "mesmo commit" de T004) — texto do critério atualizado na TASK. 3 sugestões não-bloqueantes com destino declarado: `.max(2048)` em `sourceUrl` sem AC/teste próprio (decisão registrada em nome do Diretor — limite defensivo, reversível); copy da mensagem de `sourceUrl` vazio mudou; `isProduction` duplicado em `seed-material.ts` em vez de importar de `env.ts` (lição [Código] registrada).
