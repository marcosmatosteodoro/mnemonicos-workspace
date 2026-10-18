---
area: Performance
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/**
tags: [event-loop, setimmediate, settimeout, teto, cpu-bound]
---
## [Performance] Ponto de cessão para um teto de `setTimeout` disparar usa `setTimeout(0)`, não `setImmediate`

**Erro:** no PLAN-065 (TASK-065-007, 2026-10-18), o laço de Quadros do PDF final cedia com
`await setImmediate`; o timer do prazo (`withDeadline`) ficou preso atrás de 2 Quadros CPU-bound, não
de 1 — bloqueio de até 12,3 s medido com 8 PNG 4000×3000 (performance-engineer, gate 10 da wave 3).
**Causa:** uma continuação que retoma após I/O (fase poll) e cede com `setImmediate` roda o próximo
trabalho na fase check da MESMA volta do event loop, antes da fase de timers.
**Solução:** quando o objetivo é deixar um teto de `setTimeout` disparar, ceder com
`await new Promise((r) => setTimeout(r, 0))` (passa pela fase de timers) ou checar o prazo
explicitamente antes de cada unidade CPU-bound. `setImmediate` só garante 1 unidade por fase de timers
depois da primeira volta. Prova: heartbeat de event loop no teste, maior fatia ≤ 1 unidade.
