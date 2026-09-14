# TASK-025-003: Emendar `http/errors.ts` — `GenerationTimeoutError`

**Slug**: producao-material
**Pertence a**: PLAN-025
**Realiza (FRs)**: FR-024-015
**Componente**: COMP-025-008 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

```yaml
override-erros: task-criterio-sem-ac
override-justificativa: >-
  Realiza FR-024-015 só como mecanismo (ac_gate vazio no manifesto de
  decomposição de PLAN-025) — o comportamento observável do AC-024-017 (falha
  informada ao usuário quando o teto de duração estoura) só se prova
  fim-a-fim em TASK-025-008, que efetivamente lança esta exceção via
  `withDeadline`. Oráculo desta TASK é o contrato do próprio item (regra
  4.286): a classe nova, exercitada com valor não-nulo. Mesmo padrão de
  TASK-025-004 (função pura sem AC direto nesta wave, consumida por TASK
  posterior).
override-aprovador: Tech Lead (autônomo, /keelson:auto)
```

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-025-008

## Contexto

Acrescenta `GenerationTimeoutError` (subclasse de `AppError`, 503/`GENERATION_TIMEOUT`) a
`mnemonicos-backend/src/http/errors.ts` — peça de infraestrutura consumida por
TASK-025-008 quando `withDeadline` estoura `PUBLICATION_PDF_TIMEOUT_MS` (PLAN-025 §6/
DEC-025-002). O molde real do arquivo (`TooManyRequestsError`/`ConflictError`,
`mnemonicos-backend/src/http/errors.ts:41-51`) já segue exatamente a forma
`constructor(message = '...') { super(message, STATUS, 'CODE'); }` — confirmado por
leitura direta antes desta redação.

## Escopo

### Inclui

- `mnemonicos-backend/src/http/errors.ts`: acrescentar, ao final do arquivo,
  ```ts
  export class GenerationTimeoutError extends AppError {
    constructor(message = 'A geração do documento demorou demais. Tente novamente.') {
      super(message, 503, 'GENERATION_TIMEOUT');
    }
  }
  ```
  — mesmo molde de `TooManyRequestsError`/`ConflictError`, já no arquivo.
- novo arquivo `mnemonicos-backend/tests/unit/errors.test.ts` — só o caso de
  `GenerationTimeoutError` (nenhuma outra classe de `errors.ts` ganha teste novo nesta
  TASK).

### Não inclui

- O wrapper `Promise.race`/`withDeadline` que lança esta exceção (TASK-025-008).

## Critérios de pronto

- [ ] `new GenerationTimeoutError()` tem `statusCode === 503`, `code ===
      'GENERATION_TIMEOUT'`, `message === 'A geração do documento demorou demais. Tente
      novamente.'` (default), e é `instanceof AppError` — item do Inclui sem AC, oráculo é
      o contrato do próprio item (regra 4.286), molde real conferido contra
      `TooManyRequestsError`/`ConflictError` antes de escrito. Verificação executável: `npm
      --prefix mnemonicos-backend test -- errors` (arquivo novo `tests/unit/errors.test.ts`)
      → `OK (4 tests)` (1 por asserção agrupada: statusCode, code, message default,
      instanceof). Fixada antes do código. Falsificável: trocar `503`→`500`,
      `'GENERATION_TIMEOUT'`→ outro código, alterar a mensagem default, ou não estender
      `AppError` reprova a asserção correspondente.
- [ ] Nenhuma outra classe de `errors.ts` é alterada — verificação executável: `git diff
      main...HEAD -- mnemonicos-backend/src/http/errors.ts` mostra só linhas adicionadas
      (0 remoções), e a única mudança estrutural é a classe nova ao final do arquivo.
      Falsificável: qualquer linha removida/alterada dentro de `AppError`/
      `BadRequestError`/`UnauthorizedError`/`ForbiddenError`/`NotFoundError`/
      `ConflictError`/`TooManyRequestsError` reprova este critério.
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff, produção e teste — `git
      diff --name-only main...HEAD`).

## Riscos específicos

- Peça de infraestrutura isolada — nenhum caminho de código real lança esta exceção antes
  de TASK-025-008; o gate 9/comportamento observável do AC-024-017 fica pendente dessa
  TASK posterior, não desta.

---

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 2026-09-14T15:20:19-0300
**Data conclusão**: 2026-09-14T15:22:57-0300
**Commit SHA**: 223d4d8
**Jira**: KAN-110

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 1)
- [x] Comportamento (gate 9): consolidado (DoD, Etapa 4) — SPEC-024 sem FEATs
