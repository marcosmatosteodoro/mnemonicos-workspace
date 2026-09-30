---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/store/api.ts
  - mnemonicos-frontend/src/**/*.ts
tags: [teste, refactor, mutacao, nao-regressao, tipo-de-retorno]
---
## [Testes] Refactor que alarga o tipo de retorno exige caso por valor novo em cada chamador antigo

**Erro:** na TASK-041-001 (PLAN-041, KAN-180, 2026-09-30), a renovação foi extraída de
`baseQueryWithReauth` para `silentRefresh`, e o retorno passou de `boolean` para a união
`'renewed' | 'rejected' | 'failed'`. O chamador antigo colapsa o valor com
`=== 'renewed'` (`src/store/api.ts:496`). O `code-reviewer` trocou a comparação por
`!== 'rejected'`, fazendo refresh 403/429/5xx/rede contar como renovado, e a suíte de
não-regressão inteira (78 casos antigos + 33 novos) continuou verde.
**Causa:** a prova de que "o refactor não muda comportamento" usou a suíte existente, que
só produz os valores que o tipo antigo distinguia (aqui, refresh 2xx e 401). Quando o tipo
de retorno fica mais largo, o chamador antigo ganha um ponto de decisão novo, e nenhum
teste antigo gera os valores novos.
**Solução:** refactor que alarga o tipo de retorno de uma função extraída (boolean → união,
opcional → enum) põe no Critério de pronto um caso **por valor novo em cada chamador
antigo**. O aceite é o mutante "colapso invertido no chamador" (`=== X` → `!== Y`), que tem
de reprovar pelo comando do critério. A baseline verde dos testes antigos prova só os
valores antigos, nunca os novos.
