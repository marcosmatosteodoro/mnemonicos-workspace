---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/tests/support/*.ts
  - mnemonicos-backend/tests/integration/**/*.integration.test.ts
tags: [teste, dry, helper, query-probe]
---
## [Testes] Helper de `tests/support` que não expõe o dado necessário se estende, nunca se copia

**Erro:** em PLAN-035 (TASK-035-005, gate 7 da re-revisão da Wave 2), o retry precisava
capturar os `params` das queries e montou à mão uma segunda sonda `PrismaClient`
(`$on('query')`) no arquivo de teste que já importava `withQueryProbe`.
**Causa:** o helper canônico devolvia só o SQL (`string[]`); a variante foi resolvida copiando
o corpo em vez de estender o helper.
**Solução:** quando um helper de `tests/support/` não expõe o dado de que o teste precisa,
estenda o próprio helper (retorno mais rico, ou uma função irmã no mesmo arquivo — ex.:
`withQueryEventProbe` ao lado de `withQueryProbe` em `tests/support/query-probe.ts`);
nunca recrie o corpo no arquivo de teste. As cópias locais anteriores à extração não são
precedente.
