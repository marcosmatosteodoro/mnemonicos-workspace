---
area: Segurança
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/tests/integration/**
  - mnemonicos-backend/src/modules/**/*.routes.ts
tags: [csrf, verifyorigin, cors, mutacao, prova-por-camada]
---
## [Segurança] Teste comportamental de `verifyOrigin` usa `Referer` hostil sem `Origin`, porque o `cors()` já recusa `Origin` fora da allowlist

**Erro:** no PLAN-065 (TASK-065-012, KAN-272, 2026-10-18), o caso "Origin fora da allowlist → 403
'Origem não permitida.'" de `published-pdf.publish.integration.test.ts` continuou verde depois que o
`verifyOrigin` foi removido da rota. O security-engineer mediu isso por mutante: só o caso repo-wide
de `route-authz-matrix` e uma sonda com `Referer` reprovaram.
**Causa:** o `cors()` de `src/app.ts` responde antes da rota e recusa, com o mesmo
`ForbiddenError('Origem não permitida.')`, toda requisição cujo `Origin` esteja fora da allowlist.
Um teste que manda `Origin` hostil não consegue dizer qual das duas camadas barrou o pedido
(mesma família de `validacao-repetida-em-duas-camadas-tem-uma-prova-por-camada`).
**Solução:** a prova comportamental do `verifyOrigin` numa rota de mutação manda `Referer` hostil
**sem** `Origin`, que é o vetor que só o `verifyOrigin` barra (ver `src/modules/auth/auth.routes.ts`).
A alternativa é declarar que a prova é o caso estrutural de `route-authz-matrix` ("1º handler"). O
critério só fecha quando o mutante que tira o `verifyOrigin` deixa vermelho um teste do próprio
arquivo da rota.
