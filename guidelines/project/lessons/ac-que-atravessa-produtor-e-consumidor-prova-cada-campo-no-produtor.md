---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/**/*-calculations.ts
  - mnemonicos-backend/tests/unit/**/*.test.ts
tags: [teste, mutacao, funcao-pura, estatistica]
---
## [Testes] AC que atravessa produtor → consumidor prova cada campo lido no PRODUTOR

**Erro:** em PLAN-035 (TASK-035-004, gate 1 da Wave 2), os campos derivados por
`computeContentMetrics` (`concluded`, `approvedButAltered`, `mostAdvancedStage`, `ageMs`)
ficaram sem prova: os testes dos ACs "parte cálculo" injetavam esses campos à mão no tipo
intermediário (`ContentMetrics`) e só exercitavam `aggregateStrategicPanel` — 16 de 17
mutantes do produtor sobreviveram. A fixture estatística (100/200/300) tinha média = mediana.
**Causa:** o AC atravessa duas funções puras encadeadas, e o fixture do tipo intermediário
satisfaz a leitura do AC provando só o consumidor.
**Solução:** cada campo que o consumidor lê tem ≥1 caso no produtor com asserção de valor, ou
um caso ponta a ponta (produtor → consumidor). Fixture do tipo intermediário prova só o
consumidor. Agregado estatístico usa fixture em que as estatísticas divergem (média ≠
mediana; n par e ímpar) e ≥2 grupos quando o AC diz "cada <grupo>".
