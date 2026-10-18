---
area: Design
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/http/errors.ts
  - mnemonicos-frontend/src/components/**
tags: [copy, erro, limite, arredondamento]
---
## [Design] Copy de "X passou do limite Y" arredonda X para cima e Y para baixo na unidade exibida

**Erro:** no PLAN-065 (TASK-065-007, 2026-10-18), a recusa `FINAL_PDF_TOO_LARGE` mostrava "O PDF final
tem 4,0 MB e o limite é 4,0 MB" para PDFs entre 4 000 001 e 4 049 999 bytes — o usuário lê que está
dentro do limite (product-designer, gate 11 da wave 3). O texto do PO e o AC da TASK-065-014 fixavam
"1 casa decimal" sem caso de borda.
**Causa:** arredondamento comum aplicado igualmente ao valor e ao limite; a diferença real some
quando é menor que meia unidade de exibição, e o fixture do AC ficava longe da borda.
**Solução:** em mensagem que diz que X passou do limite Y, arredondar X para cima e Y para baixo
(`ceil`/`floor` na unidade exibida) — X exibido fica sempre ≥ uma unidade acima de Y. O AC da mensagem
traz o caso de borda (valor = limite + 1 unidade mínima) mostrando X > Y.
