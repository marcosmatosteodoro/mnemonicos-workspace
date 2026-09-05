# TASK-006-011: `contents.routes.ts` — 7 rotas sob a barreira + tripwire 12→19 + `contents.integration.test.ts`

**Slug**: producao-material
**Pertence a**: PLAN-006
**Realiza (FRs)**: FR-005-001, FR-005-006, FR-005-008, FR-005-016
**Funcionalidade**: FEAT-005-001 (primária), FEAT-005-002
**Componente**: COMP-006-004 (principal), COMP-006-005, COMP-006-006
**Wave**: 4
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — `git.branchStrategy: unica`; não criar branch por task; a closure commita TASK a TASK)
**Padrão de commit**: Conventional Commits (`feat:` para esta TASK)
**Framework de teste**: Jest + supertest — integração em `mnemonicos-backend/tests/integration/` (Postgres via Docker — `npm --prefix mnemonicos-backend run db:up`; `npm --prefix mnemonicos-backend run test:integration`, `--experimental-vm-modules`, `--runInBand`, `maxWorkers: 1`). Fixture de sessão: `seedSession(role)` (`route-authz-matrix.integration.test.ts`, devolve cookie em claro). `global-setup.ts` aplica a migração de F2 (T001) sozinho; `resetDb()` trunca as tabelas novas via `pg_tables`.

## Dependências

- **Depende de**: TASK-006-006, TASK-006-008, TASK-006-009
- **Bloqueia**: TASK-006-012, TASK-006-013, TASK-006-014

## Contexto

COMP-006-004 (principal), COMP-006-005, COMP-006-006 / FR-005-001, FR-005-006 (FEAT-005-001), FR-005-008 (FEAT-005-001), FR-005-016 (FEAT-005-002) / NFR-005-001, NFR-005-006. **Fatia sensível** (endpoint novo + authz — g8 obrigatório): expõe as 7 rotas de Conteúdo bruto e Quebra da regra sob a barreira **deny-by-default** de F1, **sem reconstruí-la**. `contents.routes.ts` — árvore **plana**, `requireRole('<MÉTODO>','<caminho completo>','EDITOR','ADMIN')` **na montagem**, `verifyOrigin` como **1º handler** nas mutações; montagem em `src/http/routes.ts` **depois** de `apiRoutes.use(requireAuth)` (bloco 3, ~`:45`), import no topo (`:3-6`); `assertDenyByDefault(apiRoutes)` + `sealRouteRoles()` (`:179-180`) permanecem armados. A lista fixa (tripwire) da suíte `route-authz-matrix` sobe de **12 para 19** pares (TRISK-006-002). `contents.integration.test.ts` (supertest, `seedSession(role)`) prova o comportamento ponta-a-ponta. A regra de negócio já está em T006/T008/T009 — a rota **só expõe**, **sem Prisma**. Gates: g1 · **g8**; g9/g10/g11 n/a.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/contents/contents.routes.ts` (novo) — Router Express, árvore plana; as 7 rotas, cada uma com `requireRole('<MÉTODO>','<caminho completo>','EDITOR','ADMIN')` **na avaliação da montagem** (nunca dentro do handler); `verifyOrigin` como **1º handler** em `POST`/`PATCH`/`DELETE`/`PUT`:
  - `GET /contents` → `requireRole('GET','/contents','EDITOR','ADMIN')` → `listRawContents` (T008), devolve `Paginated<RawContentSummary>`.
  - `POST /contents` → `verifyOrigin` + `requireRole('POST','/contents','EDITOR','ADMIN')` → `createRawContent` (T006); corpo por `createRawContentSchema` → 422.
  - `GET /contents/:id` → `requireRole('GET','/contents/:id','EDITOR','ADMIN')` → `getRawContent` (T006).
  - `PATCH /contents/:id` → `verifyOrigin` + `requireRole('PATCH','/contents/:id','EDITOR','ADMIN')` → `updateRawContent` (T006); corpo por `updateRawContentSchema` → 422.
  - `DELETE /contents/:id` → `verifyOrigin` + `requireRole('DELETE','/contents/:id','EDITOR','ADMIN')` → `softDeleteRawContent` (T006).
  - `GET /contents/:id/breakdown` → `requireRole('GET','/contents/:id/breakdown','EDITOR','ADMIN')` → `getRuleBreakdown` (T009).
  - `PUT /contents/:id/breakdown` → `verifyOrigin` + `requireRole('PUT','/contents/:id/breakdown','EDITOR','ADMIN')` → `saveRuleBreakdown` (T009); corpo por `saveRuleBreakdownSchema` → 422.
  - handlers `async` **sem `try/catch`** (Express 5 encaminha rejeição ao error handler); erro previsto = `AppError`; **nada de Prisma na rota**.
- `mnemonicos-backend/src/http/routes.ts` — `import { contentsRoutes } from '../modules/contents/contents.routes'` no topo; `apiRoutes.use(contentsRoutes)` no **bloco protegido** (depois de `apiRoutes.use(requireAuth)`), antes de `assertDenyByDefault(apiRoutes)` / `sealRouteRoles()` (que permanecem).
- `mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts` — a lista fixa `expect(ROUTES.map(key).sort()).toEqual([...])` sobe de **12** para **19** pares (os 7 novos, ordenados); a asserção de censo dos laços (`collectRoutes`) segue automática; a asserção de `verifyOrigin` por referência de função cobre as 4 mutações novas.
- `mnemonicos-backend/tests/integration/contents.integration.test.ts` (novo) — supertest sobre a app real, fixture `seedSession(role)`: CRUD de `RawContent`; remoção reversível + inalcançabilidade por id direto e pela Quebra; upsert 1:1 + Quebra órfã inalcançável; alcance EDITOR × ADMIN (leitura **e** escrita); 401 (sem sessão) e 403 (STUDENT) nas 7 rotas; recusa de Quebra sobre conteúdo inexistente/removido. Oráculos falsificáveis (quebram com o service trocado por `return null`).

### Não inclui

- Regra de negócio nova no service — já em T006/T008/T009; aqui a rota **só expõe**.
- Prisma direto na rota.
- Telas `(interno)/content/**` e endpoints/hooks RTK Query — TASK-006-010 e Wave 5.
- Alteração da **forma** da chave `"<MÉTODO> <caminho>"` do `ROUTE_ROLES` ou de `PUBLIC_PATH_ALLOWLIST` / `isPublicPath` — só entram 7 pares no formato vigente.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `contents.routes.ts` — `const router = Router()`; para cada rota, `router.<verbo>('<caminho>', ...[verifyOrigin,] requireRole('<MÉTODO>','<caminho completo>','EDITOR','ADMIN'), async (req, res) => { ... })`. Validar corpo pelos schemas Zod de T006/T009; chamar só o service; `res.status(...).json(...)`.
2. `src/http/routes.ts` — import no topo; `apiRoutes.use(contentsRoutes)` no bloco protegido; conferir que `assertDenyByDefault(apiRoutes)` e `sealRouteRoles()` seguem por último.
3. `route-authz-matrix.integration.test.ts` — atualizar **só** a lista literal do `toEqual([...])` de 12 para 19 (7 pares novos, ordenados); nada mais na asserção de censo.
4. `contents.integration.test.ts` — supertest sobre a app real (montada sem popular `ROUTE_ROLES` à mão); `seedSession('EDITOR'|'ADMIN'|'STUDENT')`; cobrir CRUD, soft-delete + inalcançabilidade, upsert 1:1, alcance, 401/403, topologia adversarial.
5. Rodar a suíte de integração **inteira**: `npm --prefix mnemonicos-backend run test:integration` (Docker Postgres no ar).

## Critérios de pronto

- [ ] Testes cobrem **AC-005-026** (+ g8) — as 7 rotas sob a barreira deny-by-default: sem sessão → recusada; papel STUDENT → recusada; papel EDITOR ou ADMIN → aceita; todas no censo. O comando alcança os **outros consumidores** de `src/http/routes.ts` / `route-authz-matrix` (arquivos compartilhados por todas as rotas — `--filter` estreito é insuficiente): `npm --prefix mnemonicos-backend run test:integration` (suíte de integração **inteira**) → `contents.integration.test.ts` prova, para **cada uma** das 7 rotas: `seedSession` ausente → **401**; `seedSession('STUDENT')` → **403**; `seedSession('EDITOR')` e `seedSession('ADMIN')` → **2xx**. `Tests: N passed`. Falsificável: montar qualquer das 7 sem `requireRole` → `assertDenyByDefault(apiRoutes)` derruba o boot da app de teste (suíte vermelha); incluir `'STUDENT'` num `requireRole` → o caso 403 de STUDENT falha. Rodada contra o HEAD (pós-T009): tripwire com 12 pares, suíte de integração verde (conjunto não-vazio), sem `contents.routes.ts`. Fixada antes do código.

- [ ] **Tripwire 12 → 19 / métrica §1.3 da SPEC** — `route-authz-matrix` verde no CI, **19 pares**, **0 rota não-declarada**. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- route-authz-matrix.integration.test.ts` → a asserção `expect(ROUTES.map(key).sort()).toEqual([...])` tem **exatamente 19** entradas, incluindo os 7 pares novos, **literais**, conferidos contra os `requireRole(...)` de `contents.routes.ts` (o teste deriva `ROUTES` de `collectRoutes(apiRoutes)` — âncora **estrutural**, não grep de prosa): `GET /contents` · `POST /contents` · `GET /contents/:id` · `PATCH /contents/:id` · `DELETE /contents/:id` · `GET /contents/:id/breakdown` · `PUT /contents/:id/breakdown`. `Tests: N passed`; nenhuma rota do censo dos laços sem par correspondente na lista. Falsificável: adicionar um par à lista sem montar a rota → `ROUTES.map(key)` não o contém, `toEqual` falha; montar a rota e não atualizar a lista → `toEqual` falha (TRISK-006-002). Fixada antes do código.

- [ ] **[Testes] `EMENDA pós gate 1-7` — `verifyOrigin` provado por POSIÇÃO, não por pertencimento**: a asserção original (`route.handlers.includes(verifyOrigin)`) prova só que `verifyOrigin` está EM ALGUM LUGAR da cadeia — não que é o **1º handler**, nem que está **ausente** dos GETs. Fortalecer a MESMA asserção da matriz, **repo-wide** (toda rota não-pública, não só as 4 de `/contents` desta TASK — a condição, não a lista de instâncias): (a) para toda rota não-pública de MUTAÇÃO (`POST`/`PATCH`/`PUT`/`DELETE`), `route.handlers[0] === verifyOrigin`; (b) para toda rota não-pública que NÃO é mutação (`GET`), `!route.handlers.includes(verifyOrigin)`. Já passa em HEAD (nenhuma rota do repo viola) — é fortalecimento de prova, não mudança de comportamento. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- route-authz-matrix.integration.test.ts` → `Tests: N passed`. Mutantes (rodam pelo comando, arquivo inteiro — nunca `-t`): mover `verifyOrigin` para a 2ª posição em qualquer mutação não-pública → `handlers[0] !== verifyOrigin` → vermelho; acrescentar `verifyOrigin` a um GET não-público → `includes` vira `true` → vermelho. Ambos devem morrer (não sobreviveram no re-review anterior — retry corrige). Fixada antes do código (retry).

- [ ] **[Arquitetura] "Barreira que nega com base num registro exige o registro completo antes da 1ª requisição"**. Texto da lição (solução): *"(1) declaração é ato de montagem — `requireRole(method, path, ...roles)` declara na avaliação da chamada, nunca dentro do handler; registro selado após o boot. (2) O caminho feliz de MONTAGEM é oráculo distinto do caminho feliz de REQUEST: toda TASK que introduz registro/efeito-colateral consumido por um middleware anterior na cadeia ganha um teste que monta a app real (sem popular o registro à mão) e prova o 200 legítimo — o mutante que move a escrita para o handler o mata."* Item verificável: `contents.integration.test.ts` monta a app **real** (sem popular `ROUTE_ROLES` à mão) e prova `GET /contents` → **200** com `seedSession('EDITOR')` **e** com `seedSession('ADMIN')`. Verificação executável: `npm --prefix mnemonicos-backend run test:integration` → o mutante que move a declaração de papéis de qualquer rota `/contents` para **dentro do handler** faz o EDITOR/ADMIN legítimo receber 403 → caso vermelho. Fixada antes do código.

- [ ] **[Segurança] "'Declarado' não é 'autorizado'; prova de gate de autz exige topologia adversarial"**. Texto da lição (solução 2): *"toda leitura de permissão devolve o conjunto de papéis e o guarda compara o papel da sessão contra ele — 'declarado' nunca implica 'autorizado'; a leitura que devolve 'nenhuma permissão exigida' falha fechada. Prova de gate de autz exige a topologia adversarial mínima: rota irmã estática sem guarda ao lado de uma rota com `:param`; segundo método HTTP no mesmo caminho; rota declarada porém sem o middleware de papel; e o registro não ganha chave após o boot."* Item verificável — a suíte cobre, sobre as 7 rotas: (i) **rota irmã estática × rota com `:id`** — `GET /contents` ao lado de `GET /contents/:id`: STUDENT recusado em ambas, sessão sem papel não "vaza" pela estática; (ii) **2º método no mesmo caminho** — `GET` e `POST` em `/contents`; `GET` e `PUT` em `/contents/:id/breakdown`, cada par com sua própria chave `"<MÉTODO> <caminho>"`; (iii) **rota declarada sem o middleware de papel** — caso que monta `/contents` sem `requireRole` → boot da app de teste **lança** (via `assertDenyByDefault`); (iv) **o registro não ganha chave após o boot** — `requireRole`/`declareRouteRoles` chamado após `sealRouteRoles()` → **lança**; (v) STUDENT recusado nas 7. Verificação executável: `npm --prefix mnemonicos-backend run test:integration` → `Tests: N passed`; o mutante que troca a leitura de permissão por "o caminho está no registro?" (sem comparar o papel da sessão) → os casos de STUDENT passam a 2xx (vermelho). Fixada antes do código.

- [ ] **[Testes] "Asserção de invariante executada na carga do módulo exige DOIS testes: função + wiring"** — `assertDenyByDefault(apiRoutes)`. Texto da lição (solução): *"`assertX(...)` no topo de um arquivo de montagem exige dois testes: (a) a função reprova a topologia ruim e aceita a boa; (b) o módulo de produção, reimportado sob a topologia ruim (`jest.isolateModules`/`isolateModulesAsync` + `jest.doMock`, ou `expect(() => createApp()).toThrow()`), lança. Critério de aceite = o mutante: comentar a linha de chamada deixa esse teste vermelho."* Item verificável: com as 7 rotas de `/contents` montadas, existem os **dois** testes para `assertDenyByDefault`: (a) a função **reprova** uma árvore com uma rota `/contents` sem declaração e **aceita** a árvore com as 7 declaradas; (b) a app de produção **reimportada** com uma rota `/contents` sem `requireRole` **lança** na carga. Aceite: comentar `assertDenyByDefault(apiRoutes);` em `routes.ts` → o teste (b) fica **vermelho**. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- route-authz-matrix.integration.test.ts` → `Tests: N passed`. Fixada antes do código.

- [ ] **[Testes] "Retry que reescreve arquivo de teste … entrega o inventário antes/depois dos `it()`"** — a atualização do tripwire mexe em `route-authz-matrix.integration.test.ts`. Texto da lição (solução): *"retry que reescreve arquivo de teste … entrega o inventário antes/depois dos nomes de `it(...)` (`git show <pai>:<arquivo>` vs. HEAD), e cada nome ausente é classificado: renomeado (com o substituto citado), removido de propósito (com o motivo) ou perdido (então volta). Regra de fecho: para todo ramo condicional que sobreviva ao retry, o mutante que o neutraliza tem de morrer no delta E no commit pai."* Item verificável: se a atualização de 12→19 for aplicada por reescrita ampla do arquivo, a closure registra o inventário de `it(...)`/`test(...)` antes (`git show <commit-pai>:mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts`) e depois (HEAD); **nenhum** caso pré-existente de F1 perdido (censo dos laços, `verifyOrigin` por referência, wiring de `sealRouteRoles`/`assertDenyByDefault`) — cada nome ausente classificado; para todo ramo que sobrevive, o mutante que o neutraliza morre **no delta E no commit-pai**. Verificação executável: o diff de nomes de `it()` colado na closure; `npm --prefix mnemonicos-backend run test:integration -- route-authz-matrix.integration.test.ts` verde. Fixada antes do código.

- [ ] **[Segurança] "Chave de decisão de autz que ganha uma dimensão: todos os leitores ganham, inclusive a allowlist de exceção"** → **n/a**. Motivo: a chave `"<MÉTODO> <caminho>"` do `ROUTE_ROLES` **não muda de forma** nesta TASK — entram 7 pares novos no formato vigente; `PUBLIC_PATH_ALLOWLIST` / `isPublicPath` **não são tocados** (as 7 rotas são protegidas, nenhuma pública). Verificação executável: `git diff <commit-pai>..HEAD -- mnemonicos-backend/src | grep -nE "^[+-].*(PUBLIC_PATH_ALLOWLIST|isPublicPath)"` → **sem resultado**.

- [ ] Testes cobrem **AC-005-016** (faceta HTTP) — `GET /contents` devolve, por item, ao menos a citação do dispositivo (`sourceCitation`). Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.integration.test.ts` → item semeado com `sourceCitation` → o corpo de `GET /contents` traz `sourceCitation` no item. Falsificável: a rota/serviço não projeta `sourceCitation` → caso vermelho (a regra é de T008; aqui a faceta é o transporte HTTP). Fixada antes do código.

- [ ] Testes cobrem **AC-005-031** e **AC-005-037** (facetas HTTP) — conteúdo removido: `GET /contents/:id` → **404** e `GET /contents/:id/breakdown` → **404**; `GET /contents` não lista o item; nenhuma Quebra órfã acessível pela superfície HTTP. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.integration.test.ts` → cria `RawContent` + `PUT .../breakdown`, `DELETE /contents/:id`, então `GET /contents/:id` → 404 e `GET /contents/:id/breakdown` → 404 (a linha em `rule_breakdowns` segue no banco — assertar via `testPrisma` — mas inalcançável). Oráculo falsificável (manifesto): trocar o service por `return null` → os casos de CRUD/detalhe quebram. Falsificável: rota de detalhe/breakdown que não propaga a recusa do service (T006/T009) → 200 (vermelho). Fixada antes do código.

- [ ] Alcance EDITOR × ADMIN pela superfície HTTP (faceta de **AC-005-026** / NFR-005-001) — EDITOR A: `GET /contents` → só os próprios; `GET /contents/:idDeB` → 404; `PATCH /contents/:idDeB` → 404; `PUT /contents/:idDeB/breakdown` → 404 (IDOR de escrita pelo transporte). ADMIN → alcança todos. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.integration.test.ts` → `Tests: N passed`. Falsificável: rota que ignora o `actor` ao chamar o service → EDITOR A alcança item de B (vermelho). O fechamento **contável** do predicado de escopo vive em T006/T008/T009 (regra no service); aqui a prova é de que o transporte **passa o `actor`** — o confronto número×código é do gate 8, com o código na mão. Fixada antes do código.

- [ ] **Reconciliação agregada dos métodos de escopo do `contents.service`** (achado do qa — fecho da linha de service T006/T008/T009). A suíte de integração de `contents` confere que **todo método de `contents.service.ts` que referencia a tabela `raw_contents` tem prova de mutação de escopo** — o total esperado é **7 metodos, 7 provas** (4 de T006: `createRawContent`/`getRawContent`/`updateRawContent`/`softDeleteRawContent` + 1 de T008: `listRawContents` + 2 de T009: `getRuleBreakdown`/`saveRuleBreakdown`). Comando: enumerar (via AST, ou `grep -nE "^export (async )?function [A-Za-z]+" mnemonicos-backend/src/modules/contents/contents.service.ts` — nomes de método exportados — cruzado com os que referenciam `rawContent`/`raw_contents`) e cruzar com a contagem de testes de mutação **nomeados** na suíte; **nº de métodos == nº de provas**, e cada mutante nomeado morre pelo comando do critério (suíte/arquivo inteiro, nunca `-t` isolado). Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- contents.service.integration.test.ts` → o inventário de casos declara "7 metodos, 7 provas". Falsificável: um método de leitura novo sem predicado, fora de `listRawContents`, sem prova de mutação → contagem desbalanceada (7 metodos, 6 provas) → vermelho. Fixada antes do código.

- [ ] **[Testes] "Sonda de investigação não nasce em `tests/**`; contagem de teste declara a árvore"**. Texto da lição (solução): *"(1) sonda/probe de investigação não nasce em `tests/**` … Gate cujo mecanismo de prova escreve arquivo roda em `git worktree` isolada (decisão 4.134) — e a worktree isolada não junta `node_modules` por junction: `npm ci`/`npm install` dentro dela … poda deps (`@babel/core` transitivo …, quebrando `test:integration`). O pacote de contexto da rodada declara isso no despacho … Gate nunca roda `npm install`/`npm ci` nem edita `package*.json` na árvore principal. (2) quem declara contagem de teste como evidência de gate declara junto a árvore de onde ela saiu — `git status --porcelain` vazio."* Item verificável (fatia sensível — g1 + **g8**): os gates rodam em `git worktree` isolada **declarada no despacho** (worktree já criada + comando literal; **sem** `node_modules` junctionado); nenhuma sonda/probe em `mnemonicos-backend/tests/**`; `testPathIgnorePatterns` cobre `zz-.*`; **nenhum `npm install`/`npm ci` nem edição de `package*.json` na árvore principal**; o report da closure cola `git status --porcelain` (vazio) ao lado de `Tests: N passed`.

- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 e `npm --prefix mnemonicos-backend run typecheck` → exit 0 (baseline capturada no início da TASK: exploração — be `jest` 165/165, typecheck/lint limpos).

- [ ] Padrão de commit respeitado (Conventional Commits — `feat:`).

- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md` + `guidelines/project/backend/`): camadas schema → service → **routes**; **nada de Prisma na rota** (handlers chamam só o service de T006/T008/T009); `requireRole` na **montagem** (nunca no handler); `verifyOrigin` como 1º handler nas mutações; montagem **depois** de `requireAuth`; erro previsto = `AppError`; handler `async` sem `try/catch` (Express 5); árvore de rotas **plana** (sem `.use('/prefixo', sub)`).

- [ ] Code review aprovado.

## Riscos específicos

- **Fatia sensível — g8 obrigatório** (endpoint novo + authz): a topologia adversarial (crit. da lição [Segurança]), o `verifyOrigin` por referência e o fechamento contável de escopo de T006/T008/T009 (reconciliado em "7 metodos, 7 provas") são os pontos de confronto do `security-engineer` com o código na mão.
- **TRISK-006-002**: a lista fixa de 12→19 pode mascarar regressão se reescrita sem cuidado — por isso o inventário de `it()` (lição [Testes]) e o censo automático dos laços (`collectRoutes`).
- **Barreira real, não populada à mão**: os testes que provam o 200 legítimo montam a app real; popular `ROUTE_ROLES` à mão mascara o defeito da lição [Arquitetura].
- Integração exige Docker Postgres no ar (`npm --prefix mnemonicos-backend run db:up`); banco `mnemonicos_test` separado; `global-setup.ts` aplica a migração de F2 (T001) sozinho; `resetDb()` trunca `raw_contents`/`rule_breakdowns` via `pg_tables`.
- **Worktree isolada sem `node_modules` junctionado**: nunca `npm ci` dentro dela (poda `@babel/core` transitivo → `test:integration` quebra para todos).
- Repos symlinkados (lição [Exploração]): editar e verificar sempre pelo caminho **dentro** do link.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-05T11:09:14-03:00
**Data conclusão**: 2026-09-05T12:06:21-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 774b540 (impl) · 00a1e1e (retry — verifyOrigin por posição, test-only)
**Jira**: KAN-39
**Implementado por**: developer
**Revisado por**: code-reviewer (gates 1-7) · security-engineer (gate 8)
**Tentativas**: 2 (1ª passada aprovada no gate 8 direto e reprovada só no gate 1-7: o critério de `verifyOrigin` prometia posição/exclusão, mas a asserção só provava pertencimento — 2 mutantes sobreviventes, código de produção já correto. Retry test-only fortaleceu a asserção repo-wide (não só as 4 rotas de `/contents`); re-review aprovou com 5 mutantes reexecutados ao vivo, incluindo 2 de controle fora do escopo de `/contents` que confirmaram o alcance repo-wide)
**Cobertura final**: n/a (AC-005-026, AC-005-016 faceta HTTP, AC-005-031/037 facetas HTTP)
**Arquivos modificados**:
  - mnemonicos-backend/src/modules/contents/contents.routes.ts (novo)
  - mnemonicos-backend/src/modules/contents/contents.schema.ts
  - mnemonicos-backend/src/http/routes.ts
  - mnemonicos-backend/tests/integration/contents.integration.test.ts (novo)
  - mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts
  - mnemonicos-backend/tests/integration/contents.service.integration.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados: AC-005-026, AC-005-016, AC-005-031, AC-005-037
- [x] Segurança (gate 8): aprovado — varredura completa por 13 categorias OWASP, 0 achados; 4 mutantes adversariais reexecutados ao vivo
- [ ] Comportamento (gate 9): n/a — sem tela nesta TASK (superfície HTTP pura); FEAT-005-001/002 ainda não completas (Wave 5 pendente)

**Notas**: Fatia sensível confirmada com o código na mão: `requireRole` na montagem (nunca no handler) das 7 rotas, `verifyOrigin` como 1º handler nas 4 mutações (agora provado por posição, não só pertencimento), tripwire `route-authz-matrix` com exatamente 19 pares literais, árvore plana, zero Prisma na rota, reconciliação "7 métodos, 7 provas" do `contents.service.ts` confirmada. **Achado de segurança relevante, PRÉ-EXISTENTE (F1, não introduzido por esta wave)**: o re-review descobriu que `POST /auth/refresh` pode perder `verifyOrigin` sem nenhuma suíte acusar — a asserção repo-wide fortalecida filtra por rotas não-públicas (eixo de autorização), e as 2 rotas POST públicas (`/auth/login`, `/auth/refresh`) ficam fora dela; `/auth/login` tem prova comportamental própria (Origin estranha → 403), `/auth/refresh` não tem. É rota que emite cookies a partir de outro cookie — alvo clássico de CSRF. Registrado como risco ativo no INDEX do slug para decisão do Diretor (fora do escopo desta TASK/wave, per 4.88 + teto de retry 4.187). 2 remoções de comentário Art. 7 aplicadas pelo Tech Lead antes do fecho (narrativa de processo em nomes de teste). Dívida declarada (não desta wave): 28 ocorrências pré-existentes da mesma classe de rótulo em 7 arquivos do backend.
