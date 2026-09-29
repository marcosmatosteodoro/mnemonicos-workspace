---
area: Código
estado: ativa
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/**/*.service.ts
tags: [erro-previsto, prisma]
---
## [Código] `*OrThrow` só depois da guarda que torna a ausência impossível

**Erro:** em `approveContentVersion` (PLAN-033), `ruleBreakdown.findUniqueOrThrow` foi
justificado pela invariante "se existe Versão, existe Quebra da regra", mas ficou ANTES da
guarda que estabelece a existência da Versão. O caso previsto "Conteúdo bruto sem Versão e
sem Quebra" virou P2025 → 500 genérico, em vez da recusa de FR-032-003. Provado por sonda
HTTP no gate 1.
**Causa:** invariante condicional usada fora do ramo em que vale; o código prescrito na
TASK foi transcrito na ordem da prosa.
**Solução:** `*OrThrow` só depois da guarda que torna a ausência impossível; antes dela, a
ausência é caso previsto → `find*` + `AppError`. Ao citar uma invariante "X ⇒ Y", confira
que X já foi provado naquele ponto do corpo. Erro previsto é `AppError` (CLAUDE.md do
workspace; perfil node-22 §5).
