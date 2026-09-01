# TASK-006-005: Trocar a semente para Obrigação Tributária + EDITOR de dev

**Slug**: producao-material
**Pertence a**: PLAN-006
**Realiza (FRs)**: nenhuma
**Componente**: COMP-006-010 (principal)
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: chore
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — `git.branchStrategy: unica`; não criar branch por task; a closure commita TASK a TASK)
**Padrão de commit**: Conventional Commits (`chore:` para esta TASK — carga de exemplo e semente de dev)
**Framework de teste**: Jest — integração em `mnemonicos-backend/tests/integration/` (Docker Postgres `mnemonicos_test` via `npm --prefix mnemonicos-backend run db:up`; `npm --prefix mnemonicos-backend run test:integration`). Semente executada por `tsx prisma/seed.ts` (`npm --prefix mnemonicos-backend run db:seed`). O padrão do repo para testar o bootstrap sem rodar a carga inteira é `tests/integration/seed-admin.integration.test.ts`: chama `seedAdmin(client, { email, password })` com **credenciais explícitas como argumento** e **nunca** roda `main()`.

## Dependências

- **Depende de**: TASK-006-001
- **Bloqueia**: nenhuma

## Contexto

`mnemonicos-backend/prisma/seed.ts` hoje semeia Direito Administrativo + Constitucional (`DISCIPLINES` `:33-106`), com upsert disciplina → tema → mnemônico (chave natural `(topic,hook)`) → flashcard (`:146-194`); `seedAdmin(prisma)` (`:130`) roda antes de `main()` e devolve um `AdminSeedOutcome` (`created`/`exists`/`partial`/`not-configured`), **sem abortar** quando as credenciais estão ausentes. F2 troca a carga de exemplo para **Obrigação Tributária (Direito Tributário)** — não coexiste com o material antigo (NFR-005-003 / A-005-011) — com uma lista nomeada de temas, ≥1 `RawContent` com `radarClass` e fonte normativa estruturada mais a sua `RuleBreakdown` completa (`authorId` = ADMIN semeado por `seedAdmin`).

⚠️ **O harness de integração omite `SEED_ADMIN_*` de propósito** — `mnemonicos-backend/tests/setup-env.ts:14`: *"As `.optional()` (SEED_ADMIN_EMAIL / SEED_ADMIN_PASSWORD) ficam ausentes de propósito."* Logo, rodar `prisma/seed.ts` `main()` sob o harness **não cria ADMIN** (`seedAdmin` devolve `not-configured`, não aborta), e sem ADMIN não há `authorId` para o `RawContent` semeado (coluna `NOT NULL`, FK `Restrict` — TASK-006-001). Por isso a verificação de AC-005-027 desta TASK roda **as funções puras** (`seedAdmin` com credenciais explícitas → `seedMaterial(client, { authorId })`), nunca `main()` — igual ao padrão de `seed-admin.integration.test.ts`.

Também semeia um **EDITOR de dev** como função testável `seedDevEditor(client, { email, password })` — env-gated no chamador (`SEED_EDITOR_EMAIL`/`SEED_EDITOR_PASSWORD`), no padrão de `seedAdmin` —, para ser sujeito concreto do gate 9 das telas (resolução 2 do manifesto). `Mnemonic.source` legado não é tocado (NFR-005-007 / A-005-010 — provado em TASK-006-001 / AC-005-032); a semente de F2 não cria `Mnemonic`/`Flashcard` novo. Gates: g1; g8 (semente grava `authorId` + credencial de EDITOR — superfície de dados/segredo); g9/g10/g11 n/a.

## Escopo

### Inclui

- **`prisma/seed.ts` — o seed de material vira função testável**:
  - Extrair `seedMaterial(client, { authorId })` (ou nome equivalente) que faz o laço **disciplina → tema → `RawContent` (`radarClass` + fonte estruturada obrigatórios) → `RuleBreakdown` completa**, recebendo o `authorId` do dono. Chave natural para idempotência: `RawContent` por `(topicId, rawText)`; `RuleBreakdown` por `rawContentId`.
  - `DISCIPLINES` (ou o dado que `seedMaterial` consome) reescrito para **Direito Tributário** com a lista nomeada de temas de Obrigação Tributária — as 6 do PLAN §3 COMP-006-010: `"Obrigação Tributária Principal e Acessória"`, `"Fato Gerador"`, `"Sujeito Ativo e Passivo"`, `"Solidariedade Tributária"`, `"Responsabilidade Tributária"`, `"Domicílio Tributário"`.
  - Tipos locais `RawContentSeed` / `RuleBreakdownSeed` (`concept`/`action`/`object`/`essence` não-vazios).
  - `main()` passa a: `seedAdmin(prisma)` → obter o id do ADMIN semeado (via consulta pelo e-mail retornado, ou `count(role=ADMIN)`); se o desfecho for `not-configured`/`partial` → **pular** o material com log claro (não aborta); senão → `seedMaterial(prisma, { authorId: adminId })`.
  - Remoção do material de Direito Administrativo/Constitucional (disciplinas, temas e mnemônicos correspondentes — não coexiste).
- **O bloco do EDITOR de dev vira função testável** `seedDevEditor(client, { email, password })` — espelha `seedAdmin`: cria **um** `User` com `role = EDITOR`; idempotente. Env-gated **no chamador** (`main()` só chama quando `SEED_EDITOR_EMAIL` **e** `SEED_EDITOR_PASSWORD` estão preenchidos e não são placeholder); ausência de qualquer um → **no-op com log**, `seed` conclui exit 0 (diferente do ADMIN, que aborta no placeholder). Placeholders `SEED_EDITOR_EMAIL=` / `SEED_EDITOR_PASSWORD=` no `mnemonicos-backend/.env.example` (uma linha cada).
- **`keelson.local.example.json`** (raiz do workspace): acrescentar um realm `editor` (ou documentar no realm `app`) com a forma da credencial do EDITOR de dev (`loginPath: "/login"`, `username`/`password` apontando a convenção `SEED_EDITOR_*`), **como molde** — o arquivo real `keelson.local.json` (gitignored) é populado pelo Diretor/dev, igual ao `.env`.
- Teste de integração novo `mnemonicos-backend/tests/integration/seed-material.integration.test.ts` (roda as funções puras, nunca `main()`).

### Não inclui

- Qualquer schema Zod / service / rota / tela (TASK-006-006/011/012/013/014).
- `Mnemonic` novo ou alteração de `Mnemonic.source` (NFR-005-007) — o laço de F2 é disciplina → tema → `RawContent` → `RuleBreakdown`, sem criar mnemônico/flashcard; a **coluna** `Mnemonic.source` é preservada (provada em TASK-006-001 / AC-005-032). As linhas de exemplo antigas (Direito Administrativo/Constitucional) somem junto com o material substituído (A-005-011).
- Segundo `RawContent` além do mínimo (≥1 basta).
- O arquivo real `keelson.local.json` (gitignored) — só o `keelson.local.example.json` (molde) entra no diff.
- Rodar `main()` sob o harness de integração (o harness omite `SEED_ADMIN_*` — a verificação usa as funções puras).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Extrair `seedMaterial(client, { authorId })` de `main()` — o laço disciplina → tema → `RawContent` → `RuleBreakdown`, com `authorId` recebido por parâmetro. Reescrever o dado para Direito Tributário + os 6 temas nomeados.
2. `main()`: `seedAdmin(prisma)` → obter `adminId` (consulta pelo e-mail do desfecho `created`, ou `findFirst({ where: { role: 'ADMIN' } })`); desfecho sem ADMIN → log claro e **pula** `seedMaterial`.
3. Extrair `seedDevEditor(client, { email, password })` no padrão de `seedAdmin` (idempotente por `count`/`findUnique` do e-mail); `main()` só a chama com as duas envs preenchidas. `.env.example` ganha os dois placeholders.
4. Retirar do dado de `seedMaterial` qualquer disciplina/tema de Direito Administrativo/Constitucional; garantir que a semente **substitui** (nenhuma linha antiga remanescente).
5. `keelson.local.example.json` — realm `editor` (molde) com `loginPath`/`username`/`password` apontando `SEED_EDITOR_*`.
6. Escrever `seed-material.integration.test.ts`: `seedAdmin(testPrisma, { email, password })` com credenciais explícitas → `seedMaterial(testPrisma, { authorId: admin.id })` → asserções (i)–(iv); + os 2 casos de `seedDevEditor`.

## Critérios de pronto

- [ ] Testes cobrem **AC-005-027** — a verificação roda **as funções puras**, nunca `main()` (o harness omite `SEED_ADMIN_*` — `tests/setup-env.ts:14`). Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- seed` → novo `tests/integration/seed-material.integration.test.ts`, `PASS`, `Tests: ≥4 passed`, fixada antes do código. Sobre `mnemonicos_test` (migração de TASK-006-001 aplicada por `global-setup.ts`), o teste cria um ADMIN via `seedAdmin(testPrisma, { email, password })` (credenciais **explícitas**, padrão de `seed-admin.integration.test.ts`), chama `seedMaterial(testPrisma, { authorId: admin.id })` e então assere:
  - (i) **≥1 linha** em `raw_contents` com `authorId === admin.id`, `radarClass` ∈ `PROOF_RADAR_CLASSES`, `sourceType` **e** `sourceCitation` preenchidos, e a `RuleBreakdown` vinculada com os **4** campos obrigatórios (`concept`/`action`/`object`/`essence`) não-vazios;
  - (ii) a disciplina semeada é **"Direito Tributário"** e o conjunto de temas semeados == a lista literal `["Obrigação Tributária Principal e Acessória","Fato Gerador","Sujeito Ativo e Passivo","Solidariedade Tributária","Responsabilidade Tributária","Domicílio Tributário"]` (PLAN §3 COMP-006-010) — asserção sobre a lista literal (igualdade de conjunto);
  - (iii) para **cada** um dos 6 temas semeados, `seedMaterial` (ou um `createRawContent`-equivalente) consegue inserir um `RawContent` (`radarClass` válido, `authorId = admin.id`) — prova a via de registro em **cada** tema;
  - (iv) `SELECT count(*) FROM disciplines WHERE name IN ('Direito Administrativo','Direito Constitucional')` → **0** após `seedMaterial`, e nenhum `topics`/`mnemonics` remanescente dessas disciplinas (a semente **substitui**, A-005-011).
  Falsificável: `seedMaterial` criar `RawContent` sem `radarClass` → (i) vermelho; deixar material antigo → (iv) vermelho; deixar um tema de fora → (ii) vermelho.
- [ ] Invariante da métrica §1.3 — **nenhum** caminho de escrita da semente cria `RawContent` sem `radarClass`. Verificação executável: (a) `npm --prefix mnemonicos-backend run typecheck` → exit 0 — o tipo gerado do Prisma para `rawContent.create`/`upsert` exige `radarClass` (coluna `NOT NULL` sem default, TASK-006-001), logo omitir não compila; (b) o teste de `seedMaterial` assere `SELECT count(*) FROM raw_contents WHERE "radarClass" IS NULL` → **0**. Falsificável: introduzir um caminho de escrita com `radarClass` opcional/derivado tardio → typecheck vermelho. Fixada antes do código.
- [ ] `seedDevEditor` env-gated no padrão de `seedAdmin` — verificação executável: `npm --prefix mnemonicos-backend run test:integration -- seed` inclui **2 casos**: `seedDevEditor(testPrisma, { email: 'editor.dev@example.com', password: 'editor-dev-secret-1234' })` → **1 linha** em `users` com `role = 'EDITOR'` e o e-mail dado; chamado **sem args / com credencial ausente** (`{ email: undefined, password: undefined }`) → **nenhuma** linha `EDITOR` criada e **sem lançar**. `Tests: ≥2 passed`. Falsificável: criar o EDITOR incondicionalmente → o caso "ausente" acha um EDITOR, vermelho; lançar quando o EDITOR falta → o mesmo caso não conclui, vermelho. Fixada antes do código.
- [ ] `SEED_EDITOR_*` só como placeholder no `.env.example` (segredo nunca commitado) — verificação executável (padrão ancorado em início de linha — contrato §273(b); **checagem de conteúdo textual** — as duas variáveis DEVEM constar como placeholder): `grep -nE "^SEED_EDITOR_(EMAIL|PASSWORD)=" mnemonicos-backend/.env.example` → **2 linhas**, ambas com valor vazio ou placeholder óbvio (nunca um segredo real). Falsificável: omitir uma das linhas → `grep` incompleto, vermelho; valor que pareça credencial real → revisão reprova.
- [ ] `Mnemonic` / `Mnemonic.source` intocados (NFR-005-007) — `git diff main...HEAD -- mnemonicos-backend/prisma/schema.prisma` sem alteração em `model Mnemonic`; a semente de F2 **não escreve** `Mnemonic`/`Flashcard`: **checagem estrutural com comentário excluído do universo buscado** (contrato §273(b)) — `grep -vE '^\s*//' mnemonicos-backend/prisma/seed.ts | grep -nE "\.(mnemonic|flashcard)\.(create|update|upsert|delete|createMany)"` → **sem resultado** após a TASK. Baseline (commit-pai): esse `grep` casa em `seed.ts:146-194` — é o material que a TASK remove (arquivo-alvo do Inclui, não código intocável). Falsificável: manter/reintroduzir o upsert de mnemônico/flashcard → `grep` casa, vermelho. Fixada antes do código.
- [ ] Lição ativa [Testes] "Sonda de investigação não nasce em `tests/**`; contagem de teste declara a árvore". Texto da lição (solução): *"sonda/probe de investigação não nasce em `tests/**` — vive no scratchpad da sessão e roda por caminho explícito; se precisar do harness, nasce já com nome fora do `testMatch`. Gate cujo mecanismo de prova escreve arquivo roda em `git worktree` isolada... Gate nunca roda `npm install`/`npm ci` nem edita `package*.json` na árvore principal... quem declara contagem de teste como evidência de gate declara junto a árvore de onde ela saiu — `git status --porcelain` vazio."* Item verificável: o teste da semente nasce como `mnemonicos-backend/tests/integration/seed-material.integration.test.ts` versionado, nome dentro do `testMatch` (não `zz-*`); nenhuma sonda de inspeção de banco solta em `tests/**`; a closure declara a contagem da suíte de integração com `git status --porcelain mnemonicos-backend/` **vazio**; `testPathIgnorePatterns` cobre `zz-.*`. Verificação executável: `git status --porcelain mnemonicos-backend/` → vazio após o commit; `npm --prefix mnemonicos-backend run test:integration` → contagem declarada == observada.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline capturada); `npm --prefix mnemonicos-backend run typecheck` → exit 0.
- [ ] Padrão de commit respeitado (Conventional Commits — `chore:`).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md`: semente via `tsx prisma/seed.ts`; lógica de bootstrap isolada como função pura exercitável contra o Postgres real, no padrão de `seed-admin.ts`; chave natural para idempotência; segredo nunca commitado — `.env.example` só placeholders; `seedAdmin` roda antes).
- [ ] Code review aprovado.

## Riscos específicos

- **O harness de integração omite `SEED_ADMIN_*` de propósito** (`tests/setup-env.ts:14`): `main()` sob o harness não cria ADMIN e `seedMaterial` ficaria sem `authorId` — por isso a verificação roda `seedAdmin(client, { email, password })` com credenciais explícitas + `seedMaterial(client, { authorId })`, nunca `main()` (padrão de `seed-admin.integration.test.ts`).
- Segredo do EDITOR de dev nunca é commitado: só placeholders no `.env.example`; ausência = nenhum EDITOR (diferente do ADMIN, que aborta no placeholder). O `keelson.local.json` real é gitignored — só o `.example` (molde) entra.
- Idempotência: chave natural `RawContent` `(topicId, rawText)` / `RuleBreakdown` `rawContentId` — re-seed não duplica; `seedDevEditor` idempotente por e-mail.
- Depende da migração de TASK-006-001 aplicada no banco de teste (o `global-setup.ts` aplica sozinho).
- Repos symlinkados (lição [Exploração]): editar/verificar pelo caminho dentro do link.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-33
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
