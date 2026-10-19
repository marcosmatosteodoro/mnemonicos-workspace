---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/**/*.store.ts
  - mnemonicos-backend/src/modules/**/*.service.ts
  - mnemonicos-backend/tests/integration/**
tags: [ordenacao, mutacao, retry, criterio-como-hoje, current]
---
## [Testes] Leitura nova que decide "o mais recente"/"o atual" prova a ordem com ≥ 2 registros — "provado como hoje" herda a lacuna

**Erro:** no PLAN-065 (TASK-065-012, KAN-272, 2026-10-18), o retry trocou o cálculo de `current`,
que vinha de `list()[0]`, por uma consulta nova, `findNewestId`. O critério escrito pelo Tech Lead
dizia "com o `current` provado como hoje". Só que hoje só existia prova para o caso de 1 registro.
O mutante que inverte o `orderBy` da consulta nova passou 73/73, e o 201 da 2ª publicação podia
dizer `current: false` sem nada acusar.
**Causa:** quando uma derivação é substituída por uma consulta própria, a prova antiga (que
discriminava a ordem por outra tabela ou caminho) não vem junto. Um critério "como hoje" herda a
lacuna em vez de exigir o caso que discrimina a ordem.
**Solução:** toda leitura nova que decide "o atual" ou "o mais recente" ganha um caso com pelo menos
2 registros, que afirma na saída qual deles é o atual (ex.: o `current` do 201 da 2ª publicação e o
`current: false` do anterior no histórico). O mutante que inverte a ordem só nessa leitura tem de
ficar vermelho. O critério de retry nunca diz "como hoje" para uma leitura que o próprio retry criou.
