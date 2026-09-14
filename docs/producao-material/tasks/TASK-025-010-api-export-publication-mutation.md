# TASK-025-010: Mutation `exportPublication` na store (RTK Query, `responseHandler` binário)

**Slug**: producao-material
**Pertence a**: PLAN-025
**Realiza (FRs)**: FR-024-007, FR-024-008
**Componente**: COMP-025-010 (principal)
**Wave**: 5
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

```yaml
override-erros: task-criterio-sem-ac
override-justificativa: >-
  Mutation de wiring sem AC atribuído nesta wave (ac_gate vazio no manifesto de
  decomposição de PLAN-025, COMP-025-010) — realiza FR-024-007/FR-024-008 só
  parcialmente (base da mutation; o comportamento observável dos 3 estados é
  provado no componente montado, TASK-025-011/AC-024-006). Oráculo é o contrato
  do próprio item (responseHandler binário/erro), não um AC da SPEC — mesmo
  padrão calibrado por TASK-023-007 (estender RTK Query visual-associations,
  Done, também sem AC próprio).
override-aprovador: Tech Lead (Etapa 3.5 do /keelson:auto)
```

## Dependências

- **Depende de**: TASK-025-009, TASK-025-002
- **Bloqueia**: TASK-025-011

## Contexto

`exportPublication` é a mutation RTK Query que alimenta os 3 estados observáveis do
componente de exportação (TASK-025-011) — DEC-025-006: a resposta de sucesso é binária
(`application/pdf`), a de erro é JSON, e um `responseHandler` custom decide qual caminho
seguir a partir do `Content-Type` da resposta. Cobertura parcial: FR-024-007 aqui é só a
base da mutation (os 3 estados observáveis nascem de graça de `isLoading`/`isSuccess`/
`isError`, consumidos no componente da TASK-025-011); FR-024-008 aqui é a extração do
`filename` do header `Content-Disposition`.

## Escopo

### Inclui

- `mnemonicos-frontend/src/store/api.ts`: endpoint `exportPublication` — mutation
  `build.mutation<ExportPublicationResult, ExportPublicationArgs>` com `query: ({
  rawContentId, variant }) => ({ url: `/contents/${rawContentId}/publication`, method:
  'POST', body: { variant } })`.
- `responseHandler` custom (assinatura `(response: Response) => Promise<unknown>`, mesmo
  contrato de `fetchBaseQuery`): inspeciona `response.headers.get('content-type')` —
  começa com `application/pdf` → `{ blob: await response.blob(), filename: <extraído de
  Content-Disposition> }`; caso contrário → `response.json()` (erro), que o `fetchBaseQuery`
  já encaminha para `error.data` do jeito de sempre.
- `ExportPublicationArgs { rawContentId: string; variant: PublicationVariant }` e
  `ExportPublicationResult { blob: Blob; filename: string }` (interfaces exportadas, mesmo
  padrão de `UpdateVisualAssociationArgs`/`LinkVisualAssociationToFrameArgs`).
- Sem `invalidatesTags` (nenhum cache de leitura desta store depende do resultado de uma
  exportação).
- Export do hook `useExportPublicationMutation` no bloco de exports nomeados ao final do
  arquivo.

### Não inclui

- O componente consumidor (`publication-export-control.tsx`, TASK-025-011).

## Critérios de pronto

- [ ] `responseHandler` com `Content-Type: application/pdf` devolve `{ blob, filename }`
      correto — verificação executável: `npx jest --runTestsByPath src/store/api.test.ts`
      (cwd `mnemonicos-frontend`) → `PASS`. Cenário: `store.dispatch(
      api.endpoints.exportPublication.initiate({ rawContentId: 'rc-1', variant: 'TIRA' })
      )` contra um `fetch` mockado (mesmo mecanismo `route`/`handler` já usado no restante de
      `api.test.ts`, `@jest-environment node`) devolvendo `Response` com
      `content-type: application/pdf` e `content-disposition: attachment;
      filename="rc-1-tira-rascunho.pdf"` → `result.data.filename === 'rc-1-tira-rascunho.pdf'`
      e `result.data.blob instanceof Blob`.
- [ ] `responseHandler` com `Content-Type: application/json` devolve o erro no formato que
      `error.data` já espera — mesmo comando acima → `PASS`. Cenário: a mesma mutation contra
      uma `Response` de erro (`content-type: application/json`, status 409, corpo `{ error: {
      code: 'CONFLICT', message: '...' } }`) → `result.error.data` igual ao corpo JSON, mesmo
      formato que as demais mutations desta store já expõem em `error.data`.
- [ ] `POST /contents/:id/publication` recebe exatamente `{ variant }` no corpo — nenhum
      campo `rawContentId`/interno vazando (mesmo padrão de
      `linkVisualAssociationToFrame`) — mesmo comando acima → `PASS`, corpo da requisição
      interceptada confrontado.
- [ ] Exercitado via `store.dispatch(api.endpoints.exportPublication.initiate(...))` com
      `makeStore()` real e `fetch` mockado (lição ativa "[Testes] Predicado de decisão de UI
      a partir de estado de RTK Query só se prova no componente montado" — aqui aplicada ao
      próprio endpoint: teste via store real, nunca seletor isolado nem `jest.mock('../store/api')`
      nem stub do `fetch` nativo fora do mecanismo `route`/`handler` já estabelecido no
      arquivo, lição ativa "[Testes] jsdom sem Request/Response/fetch...").
- [ ] Regressão: `api.test.ts` já existente continua verde após o acréscimo — verificação
      executável: mesmo comando `npx jest --runTestsByPath src/store/api.test.ts` (cwd
      `mnemonicos-frontend`) → `PASS`, todos os casos pré-existentes + os novos desta TASK.
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git diff --name-only
      main...HEAD`) — verificação executável: `npx eslint src/store/api.ts src/store/api.test.ts`
      (cwd `mnemonicos-frontend`) → 0 problemas.

## Riscos específicos

- `fetchBaseQuery` não tem `responseHandler` custom hoje em nenhum endpoint da store
  (confirmado por leitura de `store/api.ts:191-195`, memo de reconhecimento do slug) —
  primeiro consumidor de resposta binária do repo; o `responseHandler` precisa distinguir
  `Content-Type` ANTES de decidir `.blob()`/`.json()`, e um erro de rede genuíno (sem
  resposta HTTP) não pode ser confundido com um 4xx/5xx JSON — cobrir os dois casos de
  falha (HTTP com corpo de erro × falha de rede) no mesmo teste, não só o feliz.
- Extração de `filename` do header `Content-Disposition` depende de parsing de string
  (`attachment; filename="..."`) — nenhuma lib de parsing de header está no projeto;
  regex ingênua que não trata aspas/escaping produz `filename` incorreto silenciosamente.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-117

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
<!-- Branch, tentativas, arquivos, revisores e narrativa (retries, escalações) vivem no
ledger da sessão e no commit da closure (4.76) — não se repetem aqui (4.409). -->
