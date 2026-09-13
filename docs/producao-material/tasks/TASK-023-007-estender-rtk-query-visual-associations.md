# TASK-023-007: Estender `store/api.ts` com endpoints RTK Query da Biblioteca visual

**Slug**: producao-material
**Pertence a**: PLAN-023
**Realiza (FRs)**: nenhuma
**Componente**: COMP-023-012 (principal)
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Done

```yaml
override-erros: task-criterio-sem-ac
override-justificativa: >-
  Item do Inclui sem AC vinculado — oráculo é o contrato do próprio item
  (regra 4.286): COMP-023-012 é camada de wiring HTTP pura, consumida pelos
  componentes de tela (COMP-023-013/014/015/016, fora desta lista), que são
  quem realiza cada FR do ponto de vista do frontend. Mesmo padrão de
  TASK-012-010 (Done, mesma classe de mudança — extensão de store/api.ts,
  sem AC numerado).
override-aprovador: Tech Lead (autônomo, /keelson:auto)
```

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch do EPICO MNEMORA STUDIO, Estrategia unica -- decisao 4.126: F5 e uma fatia do epico, nunca abre branch propria; a sessao ja fez o sync de largada nela)

**Padrão de commit**: Conventional Commits (`feat:`).
**Framework de teste**: Jest 30 + `jest-environment-jsdom`/`@jest-environment node` (mesmo
padrão de `mnemonicos-frontend/src/store/api.test.ts` — `makeStore()` por teste, `fetch`
mockado).

## Dependências

- **Depende de**: TASK-023-005
- **Bloqueia**: TASK-023-009, TASK-023-012, TASK-023-013

## Contexto

Estende `store/api.ts` com os 6 endpoints RTK Query da Biblioteca visual (listagem, sugestão
de categoria, criar/editar/remover associação, vincular/desvincular a um Quadro), seguindo
**exatamente** o padrão já em uso para `RawContent`/`MnemonicStrip` (`api.ts:290-377`): tags
novas, `providesTags`/`invalidatesTags` simétricos, `build.mutation`/`build.query` sem
lógica própria além do `query()`. TASK-023-005 (fora desta TASK, tratada como pré-requisito
satisfeito) já acrescentou `VisualAssociation`/`VisualAssociationSummary` a `types/
domain.ts` — esta TASK só consome esses tipos, nunca os declara. Upload/edição usam
`FormData` no `query` (RTK Query aceita `body: FormData` sem `Content-Type` manual — o
browser define o boundary). Sem AC numerado próprio: o oráculo é o contrato do item (URL,
método, tags de cada endpoint).

## Escopo

### Inclui

- `TAG_TYPES` (`api.ts:98-105`) ganha `'VisualAssociation'`/`'VisualAssociationList'`.
- `listVisualAssociations` — `build.query<Paginated<VisualAssociationSummary>, { category?:
  string; page?: number; perPage?: number }>`, `query: ({ category, page, perPage }) => ({
  url: '/visual-associations', params: { category, page, perPage } })`, `providesTags:
  ['VisualAssociationList']` (mesmo padrão de `listRawContents`, `api.ts:295-298`).
- `suggestVisualAssociationCategories` — `build.query<string[], { q: string }>`, `query:
  ({ q }) => ({ url: '/visual-associations/categories', params: { q } })`.
- `createVisualAssociation` — `build.mutation<VisualAssociation, FormData>`, `query:
  (body) => ({ url: '/visual-associations', method: 'POST', body })` — `body` já é o
  `FormData` montado pelo chamador (`image`/`category`/`cognitiveDescription`), sem
  `Content-Type` manual (lição ativa citada no Contexto), `invalidatesTags:
  ['VisualAssociationList']`.
- `updateVisualAssociation` — `build.mutation<VisualAssociation, { id: string; body:
  FormData }>`, `query: ({ id, body }) => ({ url: \`/visual-associations/${id}\`, method:
  'PATCH', body })`, `invalidatesTags: ['VisualAssociationList']`.
- `removeVisualAssociation` — `build.mutation<void, { id: string }>`, `query: ({ id }) =>
  ({ url: \`/visual-associations/${id}\`, method: 'DELETE' })`, `invalidatesTags:
  ['VisualAssociationList']`.
- `linkVisualAssociationToFrame` — `build.mutation<MnemonicStrip, { rawContentId: string;
  frameId: string; visualAssociationId: string }>`, `query: ({ rawContentId, frameId,
  ...body }) => ({ url: \`/contents/${rawContentId}/strip/frames/${frameId}/
  visual-association\`, method: 'POST', body })`, `invalidatesTags: ['MnemonicStrip']`
  (mesma tag de PLAN-012 — a Tira inteira já vem reordenada/atualizada).
- `unlinkVisualAssociationFromFrame` — `build.mutation<MnemonicStrip, { rawContentId:
  string; frameId: string }>`, `query: ({ rawContentId, frameId }) => ({ url:
  \`/contents/${rawContentId}/strip/frames/${frameId}/visual-association\`, method:
  'DELETE' })`, `invalidatesTags: ['MnemonicStrip']`.
- Export dos 7 hooks: `useListVisualAssociationsQuery`,
  `useSuggestVisualAssociationCategoriesQuery`, `useCreateVisualAssociationMutation`,
  `useUpdateVisualAssociationMutation`, `useRemoveVisualAssociationMutation`,
  `useLinkVisualAssociationToFrameMutation`, `useUnlinkVisualAssociationFromFrameMutation`
  (bloco final de `api.ts`, mesma vizinhança dos hooks de `MnemonicStrip`).

### Não inclui

- Qualquer componente/tela que consuma os hooks (COMP-023-013/014/015/016, fora desta
  lista).
- Declaração das interfaces `VisualAssociation`/`VisualAssociationSummary` (TASK-023-005 —
  esta TASK só importa de `@/types/domain`, nunca redeclara).
- A rota HTTP real do backend que estes endpoints chamam (COMP-023-006/COMP-023-009, fora
  desta lista) — o contrato de caminho/tag já está congelado no PLAN §3, esta TASK não
  depende do backend estar pronto (costura em contrato congelado, princípio 2).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Importar `VisualAssociation`/`VisualAssociationSummary` de `@/types/domain` no topo de
   `api.ts`, ao lado dos demais tipos de domínio já importados.
2. Acrescentar `'VisualAssociation'`/`'VisualAssociationList'` a `TAG_TYPES`.
3. Acrescentar os 6 endpoints ao bloco `endpoints: (build) => ({ ... })`, na vizinhança dos
   endpoints de `MnemonicStrip` (`api.ts:328-377`) — não misturar com o bloco de auth/users
   mais abaixo.
4. Exportar os 7 hooks no bloco final, mesma ordem de declaração dos endpoints.

## Critérios de pronto

- [ ] `TAG_TYPES` inclui `'VisualAssociation'`/`'VisualAssociationList'` — item do Inclui
      sem AC isolado, oráculo é o contrato do próprio item. Verificação executável:
      `expect(TAG_TYPES).toEqual(expect.arrayContaining(['VisualAssociation',
      'VisualAssociationList']))` (mesmo padrão do teste já existente para
      `RawContent`/`MnemonicStrip`).
- [ ] `listVisualAssociations` → `GET /visual-associations` com `params: { category, page,
      perPage }` — teste dispara `api.endpoints.listVisualAssociations.initiate(...)` e
      afirma a URL/params reais da chamada capturada (mesmo padrão de
      `api.test.ts`, `listRawContents`).
- [ ] `suggestVisualAssociationCategories` → `GET /visual-associations/categories?q=...`.
- [ ] `createVisualAssociation` → `POST /visual-associations`, corpo `FormData` — teste
      captura a `Request` real e confirma que o `body` é uma instância de `FormData`
      (`request.body instanceof FormData` ou equivalente para o ambiente de teste), sem
      nenhum header `Content-Type` setado manualmente na definição do endpoint (lição
      ativa: RTK Query aceita `body: FormData`, o browser define o boundary).
- [ ] `updateVisualAssociation` → `PATCH /visual-associations/:id`, corpo `FormData`.
- [ ] `removeVisualAssociation` → `DELETE /visual-associations/:id`, sem corpo.
- [ ] `linkVisualAssociationToFrame` → `POST /contents/:rawContentId/strip/frames/
      :frameId/visual-association`, corpo `{ visualAssociationId }` **sem**
      `rawContentId`/`frameId` — teste captura a `Request` real e confere `await
      call.clone().json()` (mesmo padrão de `api.test.ts`, `addMnemonicFrame`, que exclui
      `rawContentId` do corpo).
- [ ] `unlinkVisualAssociationFromFrame` → `DELETE` na mesma URL, sem corpo.
- [ ] As 4 mutações de acervo (`create`/`update`/`removeVisualAssociation`) invalidam
      `'VisualAssociationList'`; `listVisualAssociations` provê `'VisualAssociationList'`;
      as 2 mutações de vínculo invalidam `'MnemonicStrip'` — teste dispara cada mutação e
      confere que uma query já assinada refaz o fetch (mesmo padrão já usado para
      `RawContent`/`MnemonicStrip` no arquivo).
- [ ] Verificação executável agregada (todos os itens acima, mesmo arquivo estendido):
      `npm --prefix mnemonicos-frontend test -- api.test.ts` → `OK (N tests)`, N ≥
      contagem atual + 9 (2 de `TAG_TYPES` + 7 de endpoint).
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npm --prefix mnemonicos-frontend run lint` → exit 0.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil `next-16.md`.
- [ ] Code review aprovado.

## Riscos específicos

- DEC-023-009 (PLAN) — as 2 rotas de vínculo vivem em `tira.routes.ts`/`tira.service.ts` no
  backend, não em `visual-associations`; do lado do frontend a URL é a mesma
  independentemente de qual módulo backend a atende, sem impacto nesta TASK.
- Nenhuma lição ativa de `guidelines/project/lessons.md` nomeia diretamente os 6 endpoints
  novos além da já citada (FormData sem `Content-Type` manual).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-13T20:23:58+0000
**Data conclusão**: 2026-09-13T20:31:25+0000
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: a2164c2
**Jira**: KAN-95
**Implementado por**: developer
**Revisado por**: code-reviewer (gate 1-7, wave 2)
**Tentativas**: 1
**Cobertura final**: n/a (60/60 verde, suíte completa 380/380)
**Arquivos modificados**:
  - mnemonicos-frontend/src/store/api.ts
  - mnemonicos-frontend/src/store/api.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [ ] Segurança (gate 8): n/a — wiring de cliente HTTP, sem decisão de autorização
- [ ] Comportamento (gate 9): n/a — sem tela própria (consumido por TASK-023-009/012/013)

**Notas**: tag `'VisualAssociation'` (singular) em `TAG_TYPES` fica sem consumidor até
COMP-023-013/016 (carry-over declarado pelo code-reviewer, não cruft).

**Notas**:
