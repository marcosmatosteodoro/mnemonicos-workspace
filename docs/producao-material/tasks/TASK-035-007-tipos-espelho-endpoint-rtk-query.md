# TASK-035-007: Espelho de tipos backend↔frontend, paridade cross-repo e endpoint RTK Query

**Slug**: producao-material
**Pertence a**: PLAN-035
**Realiza (FRs)**: FR-034-004, FR-034-017
**Funcionalidade**: FEAT-034-002 (primária)
**Componente**: COMP-035-017 (principal), COMP-035-018
**Wave**: 4
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: TASK-035-006
- **Bloqueia**: TASK-035-008

## Contexto

**Costura só em contrato congelado** (princípio 2): o formato de resposta de
`GET /strategic-panel` só está congelado depois da TASK-035-006 (allowlist +ProvaHTTP) —
esta TASK espelha esse contrato já fechado, nunca negocia forma em paralelo com o backend.
`ProductionStageType`/`ProductionEventTransition` (só backend desde F3, DEC-010-006: "F10
acrescenta") ganham o 1º consumidor real de tela. Território e precedentes:
`mnemonicos-backend/src/domain/types.ts:83-98` (`PRODUCTION_STAGE_TYPES`/
`PRODUCTION_EVENT_TRANSITIONS`), `mnemonicos-backend/tests/unit/domain-types-parity.test.ts:161-194`
(os 2 `it()` já existem, comentário "sem 2º lado no frontend ainda... F10 acrescenta" —
esta TASK torna esses 2 comentários obsoletos), `mnemonicos-backend/tests/unit/
visual-associations-frontend-contract.test.ts` (molde `extractInterfaceFields`,
DECLARAÇÃO×DECLARAÇÃO), `mnemonicos-frontend/src/store/api.ts` (padrão de endpoint RTK
Query já usado por `getRawContent`/etc.), e PLAN-035 §3 (COMP-035-017/018), §6
(DEC-035-019).

## Escopo

### Inclui

- `mnemonicos-frontend/src/types/domain.ts` (estende):
  - Espelho de `PRODUCTION_STAGE_TYPES`/`ProductionStageType` e
    `PRODUCTION_EVENT_TRANSITIONS`/`ProductionEventTransition` — mesmo formato
    `export const ... = [...] as const;` do backend (`domain-types-parity.test.ts`
    extrai por este padrão textual, decisão de forma não é livre).
  - `StrategicPanelResponse` e os subtipos do payload (`ContentMetricsResponse`,
    `StagePeriodResponse`, `ModuleAggregateResponse`, `BacklogItemResponse`, etc.) —
    NOMES e FORMA conferidos contra `toStrategicPanelResponse`/`StrategicPanelPayload`
    REAIS (TASK-035-006), nunca deduzidos da prosa desta TASK ou do PLAN (decisão 4.307 —
    lista de Interface pública é contrato mínimo, não gabarito).
- `mnemonicos-backend/tests/unit/domain-types-parity.test.ts` (estende — linhas 161-194):
  os 2 `it()` de `PRODUCTION_STAGE_TYPES`/`PRODUCTION_EVENT_TRANSITIONS` ganham a 2ª
  metade que hoje falta (comentário "sem 2º lado no frontend ainda" sai): `extractConstArray(frontendSource,
  'PRODUCTION_STAGE_TYPES')`/`'PRODUCTION_EVENT_TRANSITIONS')`, paridade nos dois
  sentidos (`toEqual` cruzado, mesmo padrão de `NORMATIVE_SOURCE_TYPES` linhas 140-159).
- `mnemonicos-backend/tests/unit/strategic-panel-frontend-contract.test.ts` (novo — molde
  EXATO `visual-associations-frontend-contract.test.ts`, `extractInterfaceFields`,
  DECLARAÇÃO×DECLARAÇÃO): compara `StrategicPanelResponse`/subtipos (frontend,
  `types/domain.ts`) contra os tipos REAIS de `strategic-panel.routes.ts`/
  `strategic-panel-calculations.ts` (backend) — mesmo limite conhecido documentado
  (RISK-006-006: DECLARAÇÃO×DECLARAÇÃO, não `select`×declaração).
- `mnemonicos-frontend/src/store/api.ts` (estende):
  ```ts
  getStrategicPanel: builder.query<StrategicPanelResponse, void>({
    query: () => '/strategic-panel',
    providesTags: ['StrategicPanel'],
    refetchOnMountOrArgChange: true, // DEC-035-019 — sem tag de invalidação cruzando módulos
  }),
  ```
  `'StrategicPanel'` acrescentado ao array de `tagTypes` do `createApi`. **Nenhuma**
  mutation de `RawContent`/`ContentVersion`/`PublicationEvent` passa a invalidar esta tag
  (DEC-035-019 — decisão consciente, revisitada se o refetch em toda montagem se mostrar
  caro/ruidoso em uso real medido; lição ativa "campo calculado de outro recurso invalida
  a tag do endpoint que o exibe" **não se aplica aqui** porque não há tag de invalidação
  cruzada a esquecer — o mecanismo escolhido é outro, deliberadamente).
- `mnemonicos-frontend/src/store/api.test.ts` (estende, ou arquivo próprio se o padrão do
  repo preferir — confira por `ls mnemonicos-frontend/src/store` antes): teste do
  endpoint MONTADO contra `makeStore()` + `fetch` mockado (lição ativa "predicado de
  decisão de UI a partir de estado RTK Query só se prova no componente montado" — aqui
  não há componente, mas o princípio vale: a store REAL, nunca `.select()` isolado)
  confirmando (a) a URL chamada é `/strategic-panel`; (b) `refetchOnMountOrArgChange` fixo
  — 2 `dispatch` sucessivos do MESMO endpoint (montagem simulada 2×) disparam 2
  `fetch`, nunca 1 (mutante: remover a opção faria o 2º ser servido do cache).

### Não inclui

- Qualquer tela consumindo `useGetStrategicPanelQuery` — TASK-035-008.
- Rótulos pt-BR de apresentação (prioridade, estados de tempo por etapa) — TASK-035-008
  (tipos e rótulos de apresentação, junto da tela que os usa).

## Critérios de pronto

- [ ] Paridade `PRODUCTION_STAGE_TYPES`/`PRODUCTION_EVENT_TRANSITIONS` — verificação
      executável: `npm --prefix mnemonicos-backend test -- domain-types-parity.test.ts`
      → `OK (N tests)`, os 2 `it()` estendidos passando com os 2 lados comparados.
      Fixada antes do código.
- [ ] Paridade `StrategicPanelResponse`/subtipos (AC-034-004 — parte contrato de dados:
      confirma que os campos numéricos do payload — tempo total, tempo por página —
      existem e tipam corretamente do lado frontend; o CÁLCULO desses valores é da
      TASK-035-004, provado lá) — verificação executável: `npm --prefix
      mnemonicos-backend test -- strategic-panel-frontend-contract.test.ts` → `OK (N
      tests)`. Mutante: renomear um campo só do frontend (ex.: `contentId` →
      `rawContentId`) faz a comparação reprovar — 1 mutante por subtipo comparado (item f:
      um mutante por sujeito, cada subtipo é seu próprio sujeito).
- [ ] Endpoint RTK Query montado (AC-034-014 — parte contrato de dados e estados do
      endpoint: o par `isLoading`/`isError`/`isSuccess`/`refetch` que a tela consome
      existe e se comporta corretamente na store; a RENDERIZAÇÃO dos 3 estados é do gate
      9/testes da TASK-035-008) — verificação executável: `npm --prefix
      mnemonicos-frontend test -- api.test.ts` (ou o arquivo escolhido, registrado no
      report) → `OK (N tests)`, incluindo o caso de `refetchOnMountOrArgChange` com 2
      `fetch` reais contados (nunca 1).
- [ ] `npm --prefix mnemonicos-backend run typecheck && npm --prefix mnemonicos-frontend
      run typecheck` → exit 0 nos 2.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`) — `npm --prefix mnemonicos-backend run lint &&
      npm --prefix mnemonicos-frontend run lint` → exit 0 nos 2.
- [ ] Code review aprovado.

## Riscos específicos

- DEC-035-019 (reabrir se): refetch em toda montagem se mostrar caro/ruidoso em uso real
  medido — sem mitigação de código nesta TASK além da declaração explícita da escolha.
- Limite conhecido herdado (RISK-006-006): a rede de paridade cross-repo desta TASK
  compara DECLARAÇÃO×DECLARAÇÃO, não `select` do Prisma × interface — uma chave nova no
  `toStrategicPanelResponse` (TASK-035-006) sem a mesma chave aqui não é acusada por este
  teste; revisitar se doer.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-30T07:23:13-0300
**Data conclusão**: 2026-09-30T08:05:58-0300
**Commit SHA**: backend 51c46bc (impl) · 1fd4550 (retry gates 1/7) · frontend 789cd92 (impl) · 81a8acd (retry gates 1/7)
**Jira**: KAN-174

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado — security-engineer (wave 4)
- [x] Comportamento (gate 9): consolidado FEAT-034-002 — carregador: roteiro do gate 9 da TASK-035-008 (renderização dos 3 estados e dos dados)
