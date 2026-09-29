---
area: Segurança
estado: ativa
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/content-versions/**
  - mnemonicos-backend/src/modules/contents/contents.service.ts
  - mnemonicos-backend/src/modules/production-events/**
tags: [seguranca, concorrencia]
---
## [Segurança] Guarda de ordem entre transações concorrentes ordena por valor atribuído depois do lock

**Erro:** a correção de um bypass de segregação (PLAN-033) trocou "identidade lida ao
vivo" por "`lastEditedAt` > `closedAt`", mas os dois timestamps são `new Date()` da
aplicação: o `now` de `updateRawContent` é calculado ANTES de o UPDATE esperar o
`FOR UPDATE` do fechamento. Uma edição concorrente commitava depois do fechamento com
`lastEditedAt < closedAt` e o bypass voltava. O gate 8 provou com interleaving forçado.
**Causa:** ordem de commit ≠ ordem de relógio de aplicação, e a prova cobria só o fluxo
sequencial.
**Solução:** guarda que decide "aconteceu depois de X" entre duas transações concorrentes
ordena por algo atribuído DEPOIS do lock — `sequence`/autoincrement no INSERT, ou `now`
calculado só após o `FOR UPDATE` —, nunca por relógio capturado antes da escrita
bloqueante. A prova inclui 1 interleaving forçado (Proxy com espera dentro da transação que
segura o lock; `jest.spyOn` não intercepta métodos de `tx`) além do sequencial, com
controle positivo da pré-condição medida. Referência: `approveContentVersion` compara
`ProductionStageEvent.sequence` de `CONTEUDO_BRUTO` contra o último `VERSAO_EDITORIAL`.
