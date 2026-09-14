# TASK-025-004: Criar `pdf-layout.ts` — `wrapTextToLines` (função pura de quebra de linha)

**Slug**: producao-material
**Pertence a**: PLAN-025
**Realiza (FRs)**: nenhuma
**Componente**: COMP-025-002 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

```yaml
override-erros: task-criterio-sem-ac
override-justificativa: >-
  Utilitário puro de composição (COMP-025-002), sem FR realizado diretamente
  nesta wave (ac_gate vazio no manifesto de decomposição de PLAN-025) —
  consumido só por TASK-025-007 (pdf-composer.ts), que realiza os FRs de
  composição. Oráculo é o contrato do próprio item (regra 4.286): função pura
  exercitada com os 4 casos de fronteira do próprio algoritmo de quebra de
  linha. Mesmo padrão de TASK-025-003 (peça sem AC direto nesta wave,
  consumida por TASK posterior).
override-aprovador: Tech Lead (autônomo, /keelson:auto)
```

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-025-007

## Contexto

Função pura nova, `wrapTextToLines` (`pdf-layout.ts`, COMP-025-002), que calcula, a partir
de uma largura máxima em pontos e de uma função de medição injetada pelo chamador, as
linhas em que um texto livre deve ser quebrado para caber na página — sem I/O nem import
de `pdf-lib`, mesmo espírito de `buildInitialFrames`
(`mnemonicos-backend/src/modules/tira/tira.service.ts:47`) e `decideStageTransition`
(`mnemonicos-backend/src/modules/production-events/production-events.service.ts:23`),
funções puras já existentes no acervo. Consumida por `pdf-composer.ts` (TASK-025-007, fora
desta lista), que injeta a medição real via `font.widthOfTextAtSize` do `pdf-lib`.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/publication/pdf-layout.ts` (novo): `export function
  wrapTextToLines(text: string, maxWidthPt: number, measureWidth: (word: string) =>
  number): string[]` — sem I/O, sem import de `pdf-lib`.
- `mnemonicos-backend/tests/unit/pdf-layout.test.ts` (novo).

### Não inclui

- Qualquer chamada a `font.widthOfTextAtSize` do `pdf-lib` (fica no composer,
  TASK-025-007).

## Critérios de pronto

- [ ] Texto que cabe numa linha não quebra — item do Inclui sem AC, oráculo é o contrato
      do próprio item (regra 4.286). Verificação executável: `npm --prefix
      mnemonicos-backend test -- pdf-layout` → caso `wrapTextToLines('abc def', 1000, () =>
      10)` devolve `['abc def']` (1 elemento). Fixada antes do código. Falsificável:
      qualquer implementação que quebre a linha mesmo cabendo (ex.: por contagem de
      palavras em vez de largura acumulada) reprova este caso.
- [ ] Palavra isolada maior que `maxWidthPt` fica em linha própria, sem quebrar a palavra
      — verificação executável: mesmo comando, caso com `measureWidth` que devolve, para a
      palavra `'palavragigante'` sozinha, um valor `> maxWidthPt` → a linha resultante
      contém a palavra inteira intacta (a concatenação das linhas devolvidas reconstrói o
      texto original sem perda de caractere). Falsificável: um wrap que corta a palavra no
      meio (por caractere em vez de por palavra) reprova — a reconstrução por concatenação
      não bate com o texto original.
- [ ] Texto com N palavras quebra exatamente nas fronteiras que ultrapassam
      `maxWidthPt` — fixture com `measureWidth` determinístico (`(w) => w.length * 10 +
      10`, incluindo o espaço). Verificação executável: mesmo comando, caso
      `wrapTextToLines('um dois tres quatro', 45, (w) => w.length * 10 + 10)` →
      comparação `toEqual` linha a linha contra o array calculado à mão a partir da
      fixture. Falsificável: deslocar a quebra em 1 palavra (mutante) reprova a asserção
      de igualdade exata.
- [ ] String vazia devolve array vazio ou `['']` (decidido e testado nesta TASK) —
      verificação executável: `wrapTextToLines('', 1000, () => 0)` → asserção contra o
      valor único decidido no próprio teste (o developer escolhe um dos dois formatos e a
      suíte fixa esse valor). Falsificável: qualquer terceiro valor (`undefined`, `null`,
      `[' ']`) reprova.
- [ ] Sem import de `pdf-lib` — verificação executável: `grep -n "pdf-lib"
      mnemonicos-backend/src/modules/publication/pdf-layout.ts` → 0 ocorrências.
      Falsificável: qualquer `import ... from 'pdf-lib'` no arquivo reprova este critério.
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff, produção e teste — `git
      diff --name-only main...HEAD`).

## Riscos específicos

- Contrato de `measureWidth` (injetado pelo chamador) é a única fronteira entre esta
  função e `pdf-lib` — qualquer teste que importe `pdf-lib` diretamente nesta TASK
  contradiria o próprio "Não inclui" e a garantia de testabilidade sem gerar PDF nenhum.

---

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 2026-09-14T15:24:35-0300
**Data conclusão**: 2026-09-14T15:29:13-0300
**Commit SHA**: abba640
**Jira**: KAN-111

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 1)
- [x] Comportamento (gate 9): consolidado (DoD, Etapa 4) — SPEC-024 sem FEATs
