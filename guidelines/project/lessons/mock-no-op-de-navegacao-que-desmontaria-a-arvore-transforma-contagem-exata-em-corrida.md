---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/**/*.integration.test.tsx
  - mnemonicos-frontend/src/store/api.ts
tags: [teste, mock, navegacao, reauth, flaky, contagem]
---
## [Testes] Mock no-op de navegação que desmontaria a árvore transforma contagem exata em corrida

**Erro:** na TASK-041-002 (PLAN-041, KAN-180, 2026-09-30), o caso W6 de
`src/components/session-hint.integration.test.tsx` afirmava `reauth.redirect` chamado
**exatamente 1×** dentro de `waitFor`, com `me` sempre 401 e o redirect mockado como no-op.
Passava com o arquivo inteiro e falhava isolado (`-t W6`: 20 chamadas) ou sob carga
(22 chamadas). O `code-reviewer` achou isso rodando o filtro ampliado 4× e o caso isolado 3×.
**Causa:** o espião no-op substitui uma navegação (`window.location.assign`) que, em
produção, desmonta a árvore. Sem ela, o `InternalShell` continua montado, o
`resetApiState` adiado re-dispara o `me` e o ciclo 401 → refresh 401 → redirect se repete
(`src/store/api.ts:500-512`). A contagem cresce com o tempo decorrido, e a asserção de
contagem exata vira corrida.
**Solução:** ao mockar `reauth.redirect` (ou qualquer navegação que desmontaria a árvore)
num teste com componente montado, escolha uma de duas saídas. (a) O mock encerra o laço:
desmonta a árvore, ou a fonte do 401 responde só uma vez (molde
`auth-control.integration.test.tsx:239-257`). (b) A asserção não é de contagem exata: por
exemplo, `toHaveBeenCalled()` com todas as chamadas no destino esperado. Todo teste novo
com componente montado e reauth roda também isolado (`-t <caso>`) e repetido antes de ser
declarado verde.
