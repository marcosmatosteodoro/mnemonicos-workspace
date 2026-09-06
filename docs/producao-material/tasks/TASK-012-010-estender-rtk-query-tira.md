# TASK-012-010: Estender `store/api.ts` com endpoints RTK Query da Tira

**Slug**: producao-material
**Pertence a**: PLAN-012
**Realiza (FRs)**: FR-011-003, FR-011-004, FR-011-005, FR-011-006, FR-011-007
**Componente**: COMP-012-010 (principal)
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

```yaml
override-erros: task-criterio-sem-ac
override-justificativa: >-
  Item do Inclui sem AC vinculado — oráculo é o contrato do próprio item
  (contrato do /keelson:tasks, Etapa 3: "Sem AC, o oráculo é o contrato do
  próprio item"): endpoint RTK Query puro de wiring (URL/método/tags),
  consumido e provado pela tela em TASK-012-012. Mesmo padrão de TASKs
  chore/infra aprovadas do slug sem menção a AC (TASK-006-004, TASK-006-007
  — Done). O check mecânico task-criterio-sem-ac não distingue esse caso
  legítimo; registrado como pendência de processo (lição candidata ao
  agile-coach).
override-aprovador: Tech Lead (autônomo, /keelson:auto)
```

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-<descrição-curta>` (`git.branchNaming: "slug"`) — mesma branch única de todo PLAN-012.
**Padrão de commit**: Conventional Commits (`commit.convention: "conventional"`) — `feat:`.
**Framework de teste**: Jest 30 + `jest-environment-jsdom`/`@jest-environment node` (mesmo padrão de `mnemonicos-frontend/src/store/api.test.ts` — `makeStore()` por teste, `fetch` mockado).

## Dependências

- **Depende de**: TASK-012-009
- **Bloqueia**: TASK-012-012

## Contexto

Estende `store/api.ts` com os 5 endpoints RTK Query da Tira mnemônica (get-or-generate +
4 mutações), seguindo **exatamente** o padrão já em uso para `RawContent`/`RuleBreakdown`
(`api.ts:247-277`): tag nova, `providesTags`/`invalidatesTags` simétricos,
`build.mutation`/`build.query` sem lógica própria além do `query()`. TASK-012-009 (fora
desta TASK, tratada como pré-requisito satisfeito) já acrescentou `MnemonicFrame`/
`MnemonicStrip` a `types/domain.ts` — esta TASK só consome esses tipos, nunca os declara.
Sem AC numerado próprio: o oráculo é o contrato do item (URL, método, tags de cada
endpoint).

## Escopo

### Inclui

- `TAG_TYPES` ganha `'MnemonicStrip'` (acrescentado ao array existente em `api.ts:76-82`).
- `openMnemonicStrip` — `build.query<MnemonicStrip, { rawContentId: string }>`, `query:
  ({ rawContentId }) => \`/contents/${rawContentId}/strip\``, `providesTags:
  ['MnemonicStrip']` (mesmo padrão de `getRuleBreakdown`, `api.ts:267-270`).
- `addMnemonicFrame` — `build.mutation<MnemonicStrip, { rawContentId: string; text:
  string; position: number }>`, `query: ({ rawContentId, ...body }) => ({ url:
  \`/contents/${rawContentId}/strip/frames\`, method: 'POST', body })`,
  `invalidatesTags: ['MnemonicStrip']`.
- `updateMnemonicFrame` — `build.mutation<MnemonicStrip, { rawContentId: string;
  frameId: string; text: string }>`, `query: ({ rawContentId, frameId, ...body }) => ({
  url: \`/contents/${rawContentId}/strip/frames/${frameId}\`, method: 'PATCH', body })`,
  `invalidatesTags: ['MnemonicStrip']`.
- `removeMnemonicFrame` — `build.mutation<MnemonicStrip, { rawContentId: string;
  frameId: string }>`, `query: ({ rawContentId, frameId }) => ({ url:
  \`/contents/${rawContentId}/strip/frames/${frameId}\`, method: 'DELETE' })`,
  `invalidatesTags: ['MnemonicStrip']`.
- `reorderMnemonicFrames` — `build.mutation<MnemonicStrip, { rawContentId: string;
  order: string[] }>`, `query: ({ rawContentId, order }) => ({ url:
  \`/contents/${rawContentId}/strip/frames/order\`, method: 'PUT', body: { order } })`,
  `invalidatesTags: ['MnemonicStrip']`.
- Export dos 5 hooks: `useOpenMnemonicStripQuery`, `useAddMnemonicFrameMutation`,
  `useUpdateMnemonicFrameMutation`, `useRemoveMnemonicFrameMutation`,
  `useReorderMnemonicFramesMutation` (bloco final de `api.ts:366-384`).

### Não inclui

- Qualquer tela/componente que consuma os hooks (TASK-012-012, fora desta TASK).
- Declaração das interfaces `MnemonicFrame`/`MnemonicStrip` (TASK-012-009 — esta TASK só
  importa de `@/types/domain`, nunca redeclara).
- Rede de paridade cross-repo (`tira-frontend-contract.test.ts`, TASK-012-011).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios
prevalecem; nunca siga um passo que enfraqueça um critério.

1. Importe `MnemonicFrame`/`MnemonicStrip` de `@/types/domain` no topo de `api.ts`, ao
   lado dos demais tipos de domínio já importados (`api.ts:5-15`).
2. Acrescente os 5 endpoints ao bloco `endpoints: (build) => ({ ... })`, na vizinhança dos
   endpoints de `RawContent`/`RuleBreakdown` (`api.ts:247-278`) — não misture com o bloco
   de auth/users mais abaixo.
3. Exporte os 5 hooks no bloco final, mesma ordem de declaração dos endpoints.

## Critérios de pronto

- [ ] `TAG_TYPES` inclui `'MnemonicStrip'` — `expect(TAG_TYPES).toEqual(
      expect.arrayContaining(['MnemonicStrip']))` (mesmo padrão do teste já existente
      para `RawContent`/`RuleBreakdown`, `api.test.ts:141-142`).
- [ ] `openMnemonicStrip` → `GET /contents/:rawContentId/strip` — teste dispara
      `api.endpoints.openMnemonicStrip.initiate({ rawContentId: 'rc-1' })` e afirma
      `hadCall('GET', '/api/v1/contents/rc-1/strip')` (mesmo padrão de
      `api.test.ts:344-348`, `getRuleBreakdown`).
- [ ] `addMnemonicFrame` → `POST /contents/:rawContentId/strip/frames`, corpo `{ text,
      position }` **sem** `rawContentId` — teste captura a `Request` real e confere
      `await call.clone().json()` (mesmo padrão de `api.test.ts:350-369`,
      `saveRuleBreakdown`, que exclui `rawContentId` do corpo).
- [ ] `updateMnemonicFrame` → `PATCH /contents/:rawContentId/strip/frames/:frameId`,
      corpo `{ text }` sem `rawContentId`/`frameId`.
- [ ] `removeMnemonicFrame` → `DELETE /contents/:rawContentId/strip/frames/:frameId`,
      sem corpo.
- [ ] `reorderMnemonicFrames` → `PUT /contents/:rawContentId/strip/frames/order`, corpo
      `{ order: [...] }`.
- [ ] As 4 mutações invalidam `'MnemonicStrip'`; `openMnemonicStrip` provê
      `'MnemonicStrip'` — teste dispara a mutação e confere que uma query
      `openMnemonicStrip` já assinada refaz o fetch (mesmo padrão de invalidação já
      usado para `RawContent`/`RuleBreakdown` no arquivo).
- [ ] Verificação executável (todos os itens acima, mesmo arquivo estendido): `npm
      --prefix mnemonicos-frontend test -- api.test.ts` → `OK (N tests)`, N ≥
      contagem atual + 6 (1 de `TAG_TYPES` + 5 de endpoint).
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npm --prefix mnemonicos-frontend run lint` → exit 0.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil `next-16.md`.
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-012-005 (INDEX.md) — `GET /contents/:id/strip` com efeito colateral de geração
  (DEC-012-009) foge da idempotência estrita de `GET` REST; mitigado por desenho no
  backend (DEC-012-008), e RTK Query `query` não faz retry automático por padrão — sem
  ação desta TASK além de não introduzir retry customizado no endpoint.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-06T20:18:29-0300
**Data conclusão**: 2026-09-06T20:21:48-0300
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 13d07a6
**Jira**: KAN-60
**Implementado por**: developer
**Revisado por**: code-reviewer (aprovado sem achados, Wave 2)
**Tentativas**: 1
**Cobertura final**: n/a (item do Inclui sem AC — oráculo é o contrato do próprio item; override registrado no topo da TASK)
**Arquivos modificados**:
  - mnemonicos-frontend/src/store/api.ts
  - mnemonicos-frontend/src/store/api.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (44/44)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados (n/a — sem AC numerado)
- [x] Segurança (gate 8): n/a — declaração de contrato RTK Query, sem lógica de servidor (confirmado pelo security-engineer, Wave 2)
- [x] Comportamento (gate 9): n/a — endpoints sem tela consumidora ainda (TASK-012-012)

**Notas**:
