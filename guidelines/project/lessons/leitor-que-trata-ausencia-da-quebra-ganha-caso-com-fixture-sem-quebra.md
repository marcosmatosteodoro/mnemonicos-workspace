---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/publication/**
  - mnemonicos-backend/tests/support/approvable-raw-content-fixtures.ts
tags: [fixture, precedencia, ramo-sem-teste]
---
## [Testes] Leitor que trata a ausência da Quebra da regra ganha caso com fixture SEM Quebra

**Erro:** no PLAN-065 (TASK-065-009, 2026-10-18), o preview do PDF final tratava "Conteúdo sem Quebra
da regra" com resposta própria (200 com `NO_APPROVED_VERSION`, enquanto a exportação devolve 404); o
mutante que troca o ramo por `throw NotFoundError` sobreviveu à suíte (code-reviewer, gate 1 da wave 4).
**Causa:** `seedApprovableRawContent`/`seedApprovedStrip` sempre semeiam a `RuleBreakdown`; quem só usa
os fixtures canônicos nunca exercita o estado "sem Quebra".
**Solução:** todo leitor que trata `ruleBreakdown.findUnique === null` com resposta própria ganha caso
com `createRawContent` SEM `seedRuleBreakdown`, afirmando a resposta literal. Referência:
`tests/support/approvable-raw-content-fixtures.ts:16` (sempre semeia).
