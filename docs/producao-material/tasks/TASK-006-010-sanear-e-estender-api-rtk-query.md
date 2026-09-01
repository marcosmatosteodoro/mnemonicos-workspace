# TASK-006-010: Sanear e estender `src/store/api.ts` (RTK Query)

**Slug**: producao-material
**Pertence a**: PLAN-006
**Realiza (FRs)**: FR-005-005, FR-005-019
**Funcionalidade**: transversal (FEAT-005-001, FEAT-005-002)
**Componente**: COMP-006-011 (principal)
**Wave**: 3
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — `git.branchStrategy: unica`; não criar branch por task; a closure commita TASK a TASK)
**Padrão de commit**: Conventional Commits (`feat:` para esta TASK)
**Framework de teste**: Jest via `next/jest`, `testEnvironment: jsdom` (harness `mnemonicos-frontend/test/jsdom-fetch-env.js` — `testEnvironment` custom que estende `jest-environment-jsdom` e injeta `fetch`/`Response`/`Request`/`Headers` do realm Node; **sem dependência nova**, criado em F1/TASK-003-015), Testing Library. Em `mnemonicos-frontend/`. Gates: `npm --prefix mnemonicos-frontend test` / `run lint` / `run typecheck` / `run build`.

## Dependências

- **Depende de**: TASK-006-002, TASK-006-004
- **Bloqueia**: TASK-006-012, TASK-006-013, TASK-006-014

## Contexto

COMP-006-011 / FR-005-005 (FEAT-005-001) e FR-005-019 (FEAT-005-002) / NFR-005-004. Saneia e estende `mnemonicos-frontend/src/store/api.ts` (RTK Query): (1) **censo formal** — nenhuma tela consome `listMnemonics`/`listDueFlashcards` (2 greps ortogonais vazios na exploração; páginas hoje: `/`, `/login`, `(interno)/studio`) — e remoção dos dois endpoints + os hooks `useListMnemonicsQuery`/`useListDueFlashcardsQuery`; (2) `TAG_TYPES` perde `Mnemonic`/`Flashcard` e ganha `RawContent`/`RuleBreakdown`; (3) `listDisciplines` corrigido do tipo fantasma `Discipline[]` para o envelope `Paginated<T>` real do backend; (4) endpoints novos de Conteúdo bruto e Quebra da regra, com as tags do manifesto. O **bloco de sessão de F1** (`baseQueryWithReauth`, `login`/`logout`/`me`/`change-password`, admin `users`, `PUBLIC_AUTH_PATHS`, `justLoggedOut`) **não é tocado**. Sem telas nesta TASK (Wave 5). Gates: g1; g8/g9/g10/g11 n/a.

## Escopo

### Inclui

- **Censo formal** (registrado nesta TASK) dos consumidores de `listMnemonics` / `listDueFlashcards` / `useListMnemonicsQuery` / `useListDueFlashcardsQuery` — feito com grep ancorado contra o commit-pai **antes** da remoção; resultado transcrito na closure.
- `mnemonicos-frontend/src/store/api.ts`:
  - remover os endpoints `listMnemonics` e `listDueFlashcards` e os hooks correspondentes.
  - `TAG_TYPES` — retirar `'Mnemonic'` e `'Flashcard'`; adicionar `'RawContent'` e `'RuleBreakdown'`.
  - `listDisciplines` — tipar `Paginated<Discipline>` (envelope real do backend; `Paginated<T>` já existe em `src/types/domain.ts`; o item é a interface `Discipline` do frontend — o backend chama o item de `DisciplineSummary`, resolução 5 do manifesto mantém esse nome local ao backend), não `Discipline[]`.
  - endpoints novos, com as tags do manifesto:
    - `listRawContents` — `GET /contents`, resposta `Paginated<RawContentSummary>` (de `src/types/domain.ts`, T004), só `page`/`perPage`, `providesTags: ['RawContent']`.
    - `getRawContent` — `providesTags: ['RawContent']`.
    - `createRawContent` / `updateRawContent` / `deleteRawContent` — mutations, `invalidatesTags: ['RawContent']`.
    - `getRuleBreakdown` — `providesTags: ['RuleBreakdown']`.
    - `saveRuleBreakdown` — `invalidatesTags: ['RuleBreakdown', 'RawContent']`.
- `mnemonicos-frontend/src/store/api.test.ts` — remover os casos dos endpoints saneados (inventário `it()` antes/depois na closure); adicionar casos dos endpoints novos e da correção de `listDisciplines`.

### Não inclui

- Qualquer alteração no bloco de sessão de F1 (`baseQueryWithReauth`, `login`/`logout`/`me`/`change-password`, admin `users`, `PUBLIC_AUTH_PATHS`, `justLoggedOut`) — **não tocar**.
- As telas (`(interno)/content/**`) e seus componentes — Wave 5 (TASK-006-012/013/014).
- Os mapas `PROOF_RADAR_CLASS_LABELS` / `NORMATIVE_SOURCE_TYPE_LABELS` e as interfaces de domínio — nascem em TASK-006-004.
- A rede de paridade cross-repo dos enums — TASK-006-007.
- `Paginated<T>` em `src/domain/types.ts` do backend — TASK-006-002.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Censo: `grep -rnE "listMnemonics|listDueFlashcards|useListMnemonicsQuery|useListDueFlashcardsQuery" mnemonicos-frontend/src` contra o commit-pai; confirmar que só casa `api.ts` (definições + `TAG_TYPES` + bloco de hooks) — nada em `src/app/**` ou `src/components/**`. Transcrever o resultado na closure.
2. `api.ts` — remover os dois endpoints e hooks; ajustar `TAG_TYPES`; corrigir o tipo de `listDisciplines`; adicionar os 6 endpoints novos com `query`/`providesTags`/`invalidatesTags` do manifesto; importar `Paginated`, `RawContentSummary`, `Discipline` de `@/types/domain`.
3. `api.test.ts` — registrar inventário de `it()` antes; remover os casos dos endpoints saneados (motivo: AC-005-028); adicionar casos: URL de `listRawContents` sem filtro, forma `Paginated<RawContentSummary>`, `TAG_TYPES` novo, `listDisciplines` consumindo `.data`.
4. Rodar `npm --prefix mnemonicos-frontend test`, `run typecheck`, `run lint`, `run build`.

## Critérios de pronto

- [ ] **Censo formal** (Inclui sem AC — contrato do próprio item; pré-condição da remoção; **censo investigativo — deliberadamente amplo, casa inclusive comentário**) — verificação executável: `grep -rnE "listMnemonics|listDueFlashcards|useListMnemonicsQuery|useListDueFlashcardsQuery" mnemonicos-frontend/src` contra o **commit-pai** casa **somente** linhas de `mnemonicos-frontend/src/store/api.ts` (os dois endpoints, `TAG_TYPES`, o bloco de `export` de hooks) — **nenhuma** ocorrência em `mnemonicos-frontend/src/app/**` ou `mnemonicos-frontend/src/components/**`. O resultado do grep no pai é transcrito na closure (o censo). Após a TASK: o **oráculo forte** é `npm --prefix mnemonicos-frontend run typecheck` **e** `npm --prefix mnemonicos-frontend run build` → exit 0 (nenhuma referência pendente compilaria) **e** `npm --prefix mnemonicos-frontend test` verde; o mesmo `grep` → **sem resultado** (nenhuma menção textual remanescente). Falsificável: se o grep no pai casasse um consumidor fora de `api.ts`, o censo mudaria de "nenhuma tela consome" e a remoção seria quebra — a TASK pararia e escalaria. Fixada antes do código.

- [ ] Testes cobrem **AC-005-028** (faceta "a interface não emite consulta de flashcards devidos") — critério de **ausência**, roda **também contra o commit-pai** (contrato §273 / decisão 4.256). **Checagem de conteúdo textual declarada**: `grep -rnE "flashcards/due" mnemonicos-frontend/src` → **sem resultado** no HEAD da TASK; contra o commit-pai casa **exatamente** a(s) linha(s) de `api.ts` que esta TASK remove (a URL do endpoint `listDueFlashcards`), **nada** herdado-legítimo. **Checagem estrutural ancorada em declaração**: `grep -nE "^\s*listDueFlashcards\s*:" mnemonicos-frontend/src/store/api.ts` → **sem resultado** no HEAD (a chave do endpoint builder foi removida). O **oráculo forte**: `npm --prefix mnemonicos-frontend test` → suíte inteira **verde** + `run build` exit 0. Falsificável: deixar o endpoint ou a URL → o `grep` casa no HEAD (vermelho). Fixada antes do código.

- [ ] Testes cobrem **AC-005-028** (faceta "contrato de `listRawContents`") — o endpoint `listRawContents` tipa a resposta como `Paginated<RawContentSummary>` (de `src/types/domain.ts`, T004), consulta `GET /contents` **sem parâmetros de filtro** (só `page`/`perPage`), `providesTags: ['RawContent']`. Verificação executável: `npm --prefix mnemonicos-frontend test -- api` → com `fetch` mockado (`test/jsdom-fetch-env.js`), `makeStore().dispatch(api.endpoints.listRawContents.initiate({ page: 1, perPage: 20 }))` → a URL da requisição é `/contents?page=1&perPage=20` (nenhum `disciplineId`/`radarClass`/filtro); a resposta `{ data: [...], page, perPage, total }` é lida em `.data`. `Tests: ≥1 passed`. Falsificável: o endpoint envia um parâmetro de filtro → a asserção de URL falha; tipar como `RawContentSummary[]` (sem envelope) → `npm --prefix mnemonicos-frontend run typecheck` falha. Fixada antes do código.

- [ ] `TAG_TYPES` e endpoints novos (Inclui sem AC — contrato do próprio item): `TAG_TYPES` **não** contém `'Mnemonic'` nem `'Flashcard'`; **contém** `'RawContent'` e `'RuleBreakdown'`; `api.endpoints.<nome>` existe para cada um dos endpoints novos (`listRawContents`, `getRawContent`, `createRawContent`, `updateRawContent`, `deleteRawContent`, `getRuleBreakdown`, `saveRuleBreakdown`) com as `providesTags`/`invalidatesTags` do manifesto; `listMnemonics`/`listDueFlashcards` **não** existem. Verificação executável: `npm --prefix mnemonicos-frontend test -- api` → asserções sobre `Object.keys(api.endpoints)` e sobre as tags; **checagem estrutural ancorada em entrada de array (contrato §273(b))**: `grep -nE "^\s*'(Mnemonic|Flashcard)'" "mnemonicos-frontend/src/store/api.ts"` → **sem resultado** (as entradas de `TAG_TYPES` ficam uma por linha); `npm --prefix mnemonicos-frontend run typecheck` → exit 0. `Tests: ≥1 passed`. Falsificável: manter `'Mnemonic'` como entrada de `TAG_TYPES` → o `grep` casa (vermelho); `saveRuleBreakdown` sem `'RawContent'` em `invalidatesTags` → a asserção de tag falha. Fixada antes do código.

- [ ] `listDisciplines` corrigido para o envelope real (Inclui sem AC; NFR-005-004 — contrato estável) — tipa `Paginated<Discipline>`, não `Discipline[]`. Verificação executável: `npm --prefix mnemonicos-frontend test -- api` → `fetch` mockado devolve `{ data: [<disciplina>], page: 1, perPage: 20, total: 1 }` → o consumo lê `.data[0]`; `npm --prefix mnemonicos-frontend run typecheck` → exit 0. Falsificável: manter `Discipline[]` → o acesso a `.data` no teste ou no typecheck falha. Fixada antes do código.

- [ ] Não-regressão do saneamento — verificação executável: `npm --prefix mnemonicos-frontend test` → suíte **inteira** verde (baseline capturada no início da TASK: exploração — fe `jest` **90/90**); `npm --prefix mnemonicos-frontend run typecheck` e `npm --prefix mnemonicos-frontend run build` → exit 0 (baseline: limpos hoje nos dois repos) — o **oráculo forte** de que nenhum hook removido é referenciado; `grep -rnE "useListMnemonicsQuery|useListDueFlashcardsQuery" mnemonicos-frontend/src` → **sem resultado** (nenhuma menção textual remanescente). Fixada antes do código.

- [ ] **[Testes] "Retry que reescreve arquivo de teste … entrega o inventário antes/depois dos `it()`"** — `api.test.ts` perde os casos de `listMnemonics`/`listDueFlashcards`. Texto da lição (solução): *"… entrega o inventário antes/depois dos nomes de `it(...)` (`git show <pai>:<arquivo>` vs. HEAD), e cada nome ausente é classificado: renomeado (com o substituto citado), removido de propósito (com o motivo) ou perdido (então volta)."* Item verificável: a closure registra o inventário de `it(...)`/`test(...)` de `mnemonicos-frontend/src/store/api.test.ts` antes (`git show <commit-pai>:...`) e depois (HEAD); cada `it()` ausente classificado — os de `listMnemonics`/`listDueFlashcards` como **removido de propósito** (endpoint saneado — AC-005-028); **nenhum** caso do bloco de sessão/reauth perdido. Verificação executável: o diff de nomes de `it()` colado na closure; `npm --prefix mnemonicos-frontend test -- api` verde. Fixada antes do código.

- [ ] **Lições ativas que nomeiam `api.ts` — declaradas `n/a`** (cruzamento 4.138/4.233):
  - **[Segurança] "Guarda de curto-circuito com estado de módulo + janela temporal exige três oráculos"** → **n/a**: esta TASK **não toca** `baseQueryWithReauth` nem a flag `justLoggedOut` (bloco de sessão de F1 — ver "Não inclui").
  - **[Segurança] "Constante de segurança espelhada entre repos declara a fonte e tem teste de divergência"** → **n/a**: `PUBLIC_AUTH_PATHS` não é tocado; os enums/tipos espelhados de F2 e a sua rede nascem em T004/T007, não aqui.
  Verificação executável: `git diff <commit-pai>..HEAD -- mnemonicos-frontend/src/store/api.ts | grep -nE "^[+-].*(justLoggedOut|PUBLIC_AUTH_PATHS|baseQueryWithReauth)"` → **sem resultado** (nenhuma linha adicionada/removida tocando esses símbolos).

- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-frontend run lint` → exit 0 (baseline capturada no início da TASK).

- [ ] Padrão de commit respeitado (Conventional Commits — `feat:`).

- [ ] Aderência à stack/padrões da ficha e do perfil (`next-16.md` + `guidelines/project/frontend/`): estado de servidor **só** em RTK Query (`src/store/api.ts`), sem slice manual; `makeStore()` função, nunca singleton; **bloco de sessão de F1 intocado**; identificadores en (esta TASK não introduz texto de UI — só contrato de dados).

- [ ] Code review aprovado.

## Riscos específicos

- **Bloco de sessão de F1 é intocável**: `baseQueryWithReauth`/`justLoggedOut`/`PUBLIC_AUTH_PATHS`/admin `users` — o diff que os alcança é regressão; as lições [Segurança] de `api.ts` são declaradas `n/a` justamente por esse limite.
- **Censo antes de deletar**: se o grep do censo casar consumidor real fora de `api.ts`, a premissa "nenhuma tela consome" cai — parar e escalar, não remover.
- `listRawContents` responde `Paginated<RawContentSummary>`: o tipo `RawContentSummary` do frontend nasce em T004 — sem T004 mergeado, o typecheck quebra (dependência declarada).
- Repos symlinkados (lição [Exploração]): editar e verificar sempre pelo caminho **dentro** do link (`mnemonicos-frontend/src/...`); ausência detectada por varredura não é fato.
- `test/jsdom-fetch-env.js` (`testEnvironment` custom criado em F1/TASK-003-015) é o harness dos testes contra a `api` real — **sem dependência nova**.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-38
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
