# TASK-006-009: Quebra da regra no `contents.service` — upsert 1:1, obrigatoriedade e inalcançabilidade

**Slug**: producao-material
**Pertence a**: PLAN-006
**Realiza (FRs)**: FR-005-014, FR-005-015, FR-005-016, FR-005-017, FR-005-019, FR-005-020
**Funcionalidade**: FEAT-005-002 (primária)
**Componente**: COMP-006-003 (principal), COMP-006-002
**Wave**: 3
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — `git.branchStrategy: unica`; não criar branch por task; a closure commita TASK a TASK)
**Padrão de commit**: Conventional Commits (`feat:` para esta TASK)
**Framework de teste**: Jest — unit em `mnemonicos-backend/tests/unit/`, integração em `mnemonicos-backend/tests/integration/` (supertest + Postgres via Docker — `npm --prefix mnemonicos-backend run db:up`; `npm --prefix mnemonicos-backend run test:integration`, `--experimental-vm-modules`, `--runInBand`, `maxWorkers: 1`). Fixture de sessão: `seedSession(role)` (`route-authz-matrix.integration.test.ts`). `global-setup.ts` aplica a migração de F2 (T001) sozinho; `resetDb()` trunca as tabelas novas via `pg_tables`.

## Dependências

- **Depende de**: TASK-006-006
- **Bloqueia**: TASK-006-011

## Contexto

COMP-006-003 / FR-005-014, FR-005-015, FR-005-016, FR-005-017, FR-005-019, FR-005-020 (FEAT-005-002) / NFR-005-006. Terceira fatia do `contents.service` — a Quebra da regra. Entram `saveRuleBreakdownSchema` (Zod), `getRuleBreakdown(rawContentId, actor)` e `saveRuleBreakdown(rawContentId, input, actor)`. Upsert **1:1** por `rawContentId` (`@unique` do schema — T001): a 1ª gravação cria, as seguintes atualizam a mesma linha. Recusa (`AppError`) quando o `RawContent` pai **não existe**, está **soft-deleted** (`deletedAt != null`) ou está **fora do alcance** do ator — **reusando** o helper de alcance e o filtro `deletedAt: null` de T006. A `RuleBreakdown` não tem `deletedAt` próprio (DEC-006-001): herda a inalcançabilidade do pai (a linha fica no banco, mas `getRuleBreakdown` recusa). Gates: g1 · g8 (inalcançabilidade após remoção; alcance do pai — inclui **IDOR de escrita**); g9/g10/g11 n/a.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/contents/contents.schema.ts` (nasce em T006) — `saveRuleBreakdownSchema`: `concept`, `action`, `object`, `essence` **obrigatórios** (não-vazios); `condition?`, `exception?` opcionais (A-005-009 — vazio = "não se aplica").
- `mnemonicos-backend/src/modules/contents/contents.service.ts` (nasce em T006):
  - `getRuleBreakdown(rawContentId, actor)` — devolve os cinco blocos + `essence` do `rawContentId`; recusa (`AppError`) se o pai não existe / está soft-deleted / está fora do alcance (helper + filtro de T006).
  - `saveRuleBreakdown(rawContentId, input, actor)` — **upsert por `rawContentId`** (`@unique`); mesma recusa de pai; a 2ª gravação atualiza a linha existente (nunca cria outra).
- `mnemonicos-backend/tests/unit/contents.schema.test.ts` (nasce em T006) — casos do `saveRuleBreakdownSchema`.
- `mnemonicos-backend/tests/integration/contents.service.integration.test.ts` (nasce em T006) — `describe('getRuleBreakdown / saveRuleBreakdown')`: round-trip dos 6 campos, atualização in-place, prova de corrida na fronteira da unicidade, recusas de pai (inexistente / soft-deleted / fora do alcance), prova de escopo contável (leitura **e** escrita), par de ramos coincidente.

### Não inclui

- Rotas `GET`/`PUT /contents/:id/breakdown` e o censo da suíte `route-authz-matrix` — TASK-006-011.
- Tela da Quebra da regra / estados de UI / "não descarta o digitado" na interface — TASK-006-014.
- `deletedAt` próprio na `RuleBreakdown` — DEC-006-001 (herda a inalcançabilidade do pai).
- Tira mnemônica / blocos como sequência ordenada de quadros — F4.
- Endpoints RTK Query `getRuleBreakdown`/`saveRuleBreakdown` — TASK-006-010.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `contents.schema.ts` — `saveRuleBreakdownSchema` = `z.object({ concept, action, object, essence: <string não-vazia>, condition: <opcional>, exception: <opcional> })`.
2. `contents.service.ts`:
   - helper de pai (reusar o de T006): carrega o `RawContent` por id **com** o filtro `deletedAt: null` e o predicado de alcance (`authorId = actor.id` para EDITOR; irrestrito para ADMIN); ausência → `AppError`.
   - `getRuleBreakdown(rawContentId, actor)` — resolve o pai pelo helper, depois `prisma.ruleBreakdown.findUnique({ where: { rawContentId }, select: { … } })`.
   - `saveRuleBreakdown(rawContentId, input, actor)` — resolve o pai pelo helper, depois `prisma.ruleBreakdown.upsert({ where: { rawContentId }, create: { rawContentId, ...input }, update: { ...input } })`, apoiado no `@unique` de `rawContentId` (T001).
3. Estender `contents.service.integration.test.ts` com o `describe`: fixtures de pai ativo / pai soft-deleted / pai de outro autor; caso de corrida (`Promise.all` de 2 `saveRuleBreakdown` para o mesmo `rawContentId` sem Quebra prévia).
4. Rodar `npm --prefix mnemonicos-backend run test:integration -- contents.service.integration.test.ts` e `npm --prefix mnemonicos-backend test -- contents.schema`.

## Critérios de pronto

- [ ] `saveRuleBreakdownSchema` (Zod) — faceta de **AC-005-022**: `concept`, `action`, `object`, `essence` obrigatórios; `condition`/`exception` opcionais. Verificação executável: `npm --prefix mnemonicos-backend test -- contents.schema` → o parse de `{ concept, action, object, essence }` (sem `condition`/`exception`) é **aceito**; o parse faltando qualquer um de `concept`/`action`/`object`/`essence` é **rejeitado** e o erro **nomeia** o(s) campo(s) faltante(s). `Tests: ≥1 passed`. Rodada contra o HEAD (pós-T006): `contents.schema.test.ts` tem os casos de T006 (não-vazio) e não tem o `describe('saveRuleBreakdownSchema')`. Falsificável: tornar `essence` `.optional()` → o caso "falta `essence` → rejeitado" fica vermelho; exigir `condition` → o caso "sem `condition` → aceito" fica vermelho. Fixada antes do código.

- [ ] Testes cobrem **AC-005-019** e **AC-005-024** (faceta service) — `saveRuleBreakdown(rawContentId, input, actor)` persiste os cinco blocos (`concept`, `action`, `object`, `condition`, `exception`) + `essence` vinculados ao `rawContentId`; `getRuleBreakdown(rawContentId, actor)` os devolve **exatamente** como persistidos; um segundo `saveRuleBreakdown` com novos valores **atualiza** e o `getRuleBreakdown` seguinte reflete os novos. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service.integration.test.ts` → grava → lê (6 campos conferidos) → altera 2 blocos + `essence` → lê de novo (novos valores). `Tests: ≥1 passed`. Falsificável: `getRuleBreakdown` que não projeta `condition`/`exception` → asserção de round-trip falha. Fixada antes do código.

- [ ] Testes cobrem **AC-005-020** — no máximo **uma** `RuleBreakdown` por `RawContent`; a prova de unicidade nasce **na fronteira da invariante** e o mutante roda **pelo comando do critério**. Texto da lição [Testes] "Prova de corrida/exclusão nasce na fronteira da invariante, e o mutante roda pelo comando do critério": *"prova de corrida/limite/cardinalidade-mínima nasce na fronteira … E o mutante nomeado num 'Critério de pronto' roda pelo comando do critério (arquivo/suíte inteira), nunca `-t "..."` isolado."* Fronteira: um `RawContent` **sem** `RuleBreakdown` (onde uma segunda criação viola o `@unique`). Disparar **2** `saveRuleBreakdown(rawContentId, …)` concorrentes (`Promise.all`, inputs distintos) para o mesmo `rawContentId` → ao assentar, `prisma.ruleBreakdown.count({ where: { rawContentId } })` é **exatamente 1**, e o conteúdo persistido é um dos dois inputs. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service.integration.test.ts` → `Tests: ≥1 passed`; o mutante check-then-act (`findUnique` + `create` incondicional, sem apoiar no `@unique`/`upsert`) **morre** quando o arquivo inteiro roda pelo comando acima — **nunca** `-t` isolado. Falsificável: implementar como `create` sempre → `count === 2` (vermelho). Dependência: o critério de T001 mantém `rawContentId String @unique` — sem ele o mutante sobrevive. Fixada antes do código.

- [ ] Testes cobrem **AC-005-021**, **AC-005-013** (faceta Quebra), **AC-005-037** (faceta Quebra) e **AC-005-031** — `getRuleBreakdown` e `saveRuleBreakdown` **recusam** (`AppError`) quando o `RawContent` alvo (i) não existe, (ii) está soft-deleted (`deletedAt != null`) ou (iii) está fora do alcance do ator — reusando o helper e o filtro de T006; nenhuma `RuleBreakdown` órfã fica consultável após a remoção do pai. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service.integration.test.ts` → casos: id aleatório → `AppError`; `RawContent` com `RuleBreakdown` gravada, depois `softDeleteRawContent` (T006) → `getRuleBreakdown` do mesmo id → `AppError` (a linha em `rule_breakdowns` **continua no banco** — assertar via `testPrisma` direto — mas inalcançável pelo service); `RawContent` de EDITOR B com ator EDITOR A → `AppError` em ambas as funções. `Tests: ≥1 passed`. Falsificável: remover o guard de pai de `getRuleBreakdown` → a Quebra do conteúdo removido volta a ser devolvida (vermelho). Fixada antes do código.

- [ ] Prova de escopo por DADO com fechamento **contável** (gate 8 — alcance do pai; inalcançabilidade após remoção). Fechamento: **as 2 funções do Escopo desta TASK que tocam `raw_contents` (via o guard do pai) — `getRuleBreakdown` (leitura) e `saveRuleBreakdown` (escrita em `rule_breakdowns` condicionada ao pai) — têm, cada uma, cenário de segunda instância cuja mutação do predicado reprova: 2 funções, 2 provas** + 1 caso por ramo do predicado do pai (autor próprio / ADMIN irrestrito; pai ativo / pai soft-deleted). `saveRuleBreakdown` é **escrita**: a prova de que EDITOR A **não grava** a Quebra de um `RawContent` de EDITOR B é prova **exigida** (IDOR de escrita — decisão 4.232), não opcional. Fixture: `RawContent` de EDITOR B (ator = EDITOR A) e `RawContent` de A com `deletedAt != null`. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service.integration.test.ts` → como A sobre o conteúdo de B, `getRuleBreakdown`/`saveRuleBreakdown` → `AppError`; como ADMIN → alcança. Mutantes (rodam pelo comando, **arquivo inteiro — nunca `-t`**): neutralizar o predicado `authorId` do guard → A lê/grava a Quebra de B (vermelho); neutralizar `deletedAt: null` → A opera sobre o conteúdo soft-deleted (vermelho). Fixture de 2 autores com o predicado neutralizado reprovando — fixada aqui, não deixada para o gate 8. Fixada antes do código.

- [ ] **[Segurança/Testes] "Guarda de alcance nunca fica atrás de outra recusa — precedência corrigida no retry"** — `EMENDA pós gate 8/1-7 (Wave 3)`: a ordem original desta TASK (`inexistente → soft-deleted → fora do alcance`) foi implementada em `assertRawContentReachable` e **vazava existência**: um EDITOR A que possui o id de um `RawContent` de EDITOR B distinguia "não encontrado" (id aleatório ou item ativo de B) de "foi removido" (item de B soft-deleted) — oráculo de autoria via mensagem, achado convergente de code-reviewer (achado 2) e security-engineer (achado 1, decisivo sobre a dimensão de vazamento). **Ordem corrigida, obrigatória**: `inexistente → fora do alcance → soft-deleted`. Quem NÃO alcança o pai (id aleatório OU item de outro autor, removido ou não) recebe **sempre** a mesma mensagem literal ("Conteúdo bruto não encontrado."); "Conteúdo bruto foi removido." só chega a quem alcança (dono ou ADMIN) sobre item soft-deleted. Par coincidente (`soft-deleted ∧ fora do alcance`) — `RawContent` de EDITOR B **e** `deletedAt != null`, ator = EDITOR A — tem caso próprio nomeado por PAPEL (não por "quem vence"): `"não-dono sobre conteúdo removido de outro autor → recusa indistinguível de 'não encontrado'"` **e** um caso irmão `"dono sobre o próprio conteúdo removido → recusa por remoção"` (mensagem diferente, mesma função, ator distinto). O mutante que reordena de volta para `soft-deleted` antes de `fora do alcance` **morre** no comando do critério — e o mutante que troca a mensagem da recusa por alcance por um texto que nomeia autoria (ex.: "pertence a outro autor") também **morre** (as duas recusas de não-alcance são comparadas por igualdade de string entre si no mesmo caso, não só por tipo `AppError`). Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service.integration.test.ts` → `Tests: ≥1 passed`. Fixada antes do código (retry).

- [ ] **[Escopo] `EMENDA pós gate 1-7 (Wave 3)` — ramo "pai alcançável, sem Quebra ainda" declarado e testado**: `getRuleBreakdown(rawContentId, actor)` sobre um `RawContent` alcançável que NUNCA teve `saveRuleBreakdown` chamado hoje lança `AppError` 404 ("Quebra da regra não encontrada.") — esse é o caminho FELIZ de T014 abrir o editor de uma Quebra nova, e nenhum AC/critério desta TASK o declarava. Decisão (Tech Lead, reversível): manter o 404 é a forma correta — T014 trata 404 de `getRuleBreakdown` como "abrir formulário vazio", análogo ao padrão REST already usado no contrato. Adicionar teste explícito nomeando esse ramo: `"pai alcançável sem Quebra ainda → getRuleBreakdown recusa com 404, saveRuleBreakdown cria normalmente"`. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service.integration.test.ts` → `Tests: ≥1 passed`. Fixada antes do código (retry).

- [ ] **[Código] `EMENDA pós gate 1-7 (Wave 3)` — DRY: `withQueryProbe` duplicado**: `tests/integration/contents.service.integration.test.ts:569` reimplementa VERBATIM o helper de mesmo nome já presente no mesmo arquivo (nascido em T006, linha ~220). Içar um único `withQueryProbe` ao escopo do módulo/arquivo; remover a cópia. (Consolidação com as cópias de `disciplines.integration.test.ts`/`auth.service.integration.test.ts` fica fora de escopo — diff futuro, 4.88.) Verificação executável: `grep -c "function withQueryProbe" mnemonicos-backend/tests/integration/contents.service.integration.test.ts` → `1` (não 2). Fixada antes do código (retry).

- [ ] **[Testes] "Sonda de investigação não nasce em `tests/**`; contagem de teste declara a árvore"**: os gates desta TASK rodam em `git worktree` isolada **declarada no despacho** (worktree já criada + comando literal; **sem** `node_modules` junctionado — `npm ci` na worktree poda `@babel/core` e quebra `test:integration`); nenhuma sonda/probe em `mnemonicos-backend/tests/**`; `testPathIgnorePatterns` cobre `zz-.*`; **nenhum `npm install`/`npm ci` nem edição de `package*.json` na árvore principal**; o report da closure cola `git status --porcelain` (vazio) ao lado de `Tests: N passed`.

- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 e `npm --prefix mnemonicos-backend run typecheck` → exit 0 (baseline capturada no início da TASK: exploração — be `jest` 165/165, typecheck/lint limpos).

- [ ] Padrão de commit respeitado (Conventional Commits — `feat:`).

- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md` + `guidelines/project/backend/`): camadas schema → service (esta TASK não toca rota), erro previsto = `AppError`, `select` explícito no Prisma; **reusa** o helper de alcance e o filtro `deletedAt: null` de T006 (não os recria); a unicidade 1:1 apoia-se no `@unique` do banco (T001), não só no service.

- [ ] Code review aprovado.

## Riscos específicos

- **IDOR de escrita**: `saveRuleBreakdown` é gravação condicionada ao alcance do pai — a lição [Segurança] "enumerar por DADO, não por rota" + decisão 4.232 exigem a prova de negação da escrita, não só da leitura. Já no gate 1: fixture de 2 autores + mutante que neutraliza `authorId` reprovando.
- **`prisma.upsert` sob concorrência**: pode lançar `P2002` numa das duas corridas — isso é o fail-safe correto (o `@unique` segura a invariante). O teste de corrida assere `count === 1` **e** que o conteúdo é um dos inputs; a rejeição de uma corrida é aceitável, dois registros não.
- Integração exige Docker Postgres no ar (`npm --prefix mnemonicos-backend run db:up`); banco `mnemonicos_test` separado; `global-setup.ts` aplica a migração de F2 (T001) sozinho.
- Repos symlinkados (lição [Exploração]): editar e verificar sempre pelo caminho **dentro** do link.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-05T03:36:03-03:00
**Data conclusão**: 2026-09-05T10:25:46-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: e222aa7 (impl) · 8262cb7 (retry — reordenação de guards + docblock) · 6eccd54 (limpeza Art. 7 pós re-review)
**Jira**: KAN-37
**Implementado por**: developer
**Revisado por**: code-reviewer (gates 1-7) · security-engineer (gate 8)
**Tentativas**: 2 (1ª passada reprovada — o docblock de `assertRawContentReachable` afirmava convergência de mensagem que a ordem `inexistente → soft-deleted → fora do alcance` não cumpria: EDITOR A sobre conteúdo removido de EDITOR B recebia "foi removido" em vez do "não encontrado" genérico, vazando existência de conteúdo de outro autor (achado convergente code-reviewer + security-engineer, decisivo o veredito deste último); também `withQueryProbe` duplicado e ramo "pai alcançável sem Quebra ainda" sem teste. Retry reordenou para `inexistente → fora do alcance → soft-deleted`, unificou a mensagem de não-alcance, içou o helper e testou o ramo faltante; re-review aprovou os 2 gates com os mutantes de reordenação/mensagem reexecutados ao vivo)
**Cobertura final**: n/a (AC-005-013/019/020/021/022/024/031/037)
**Arquivos modificados**:
  - mnemonicos-backend/src/modules/contents/contents.schema.ts
  - mnemonicos-backend/src/modules/contents/contents.service.ts
  - mnemonicos-backend/tests/integration/contents.service.integration.test.ts
  - mnemonicos-backend/tests/unit/contents.schema.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados: AC-005-013, AC-005-019, AC-005-020, AC-005-021, AC-005-022, AC-005-024, AC-005-031, AC-005-037
- [x] Segurança (gate 8): aprovado — após retry (precedência de guards corrigida, mensagem de não-alcance indistinguível provada por igualdade literal entre as duas recusas, não só tipo `AppError`)
- [ ] Comportamento (gate 9): n/a — sem efeito observável de tela nesta TASK (service puro); FEAT-005-002 ainda não completa

**Notas**: Achado de segurança mais sério da Wave 3: a ordem original (mandada pelo texto original desta TASK) vazava um oráculo de autoria via mensagem — "existe (de outro autor) e foi removido" vs. "não existe". Corrigido para `inexistente → fora do alcance → soft-deleted`: não-dono recebe SEMPRE "Conteúdo bruto não encontrado.", independente do estado de soft-delete; "foi removido" só alcança dono/ADMIN. `getRuleBreakdown` sobre pai alcançável sem Quebra ainda mantém 404 por decisão do Tech Lead (reversível) — T014 trata como "abrir formulário vazio". `withQueryProbe` (duplicado verbatim desde T006) içado a definição única no módulo.
