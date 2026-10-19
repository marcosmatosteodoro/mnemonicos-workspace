---
area: Design
estado: em-observacao
validade: indeterminada
confirmada: 1
contestada: 0
paths:
  - mnemonicos-backend/src/modules/**/*.ts
  - mnemonicos-frontend/src/components/**
tags: [copy, erro, recusa, maquina-de-estado]
---
## [Design] Recusa cujo `reason` cobre vários estados de origem escolhe o texto pelo estado, não só pelo `reason`

**Erro:** no PLAN-065 (TASK-065-006, KAN-266, 2026-10-18), a recusa `NO_APPROVED_VERSION` do PDF
final dizia "Feche uma versão para ser aprovada" também quando a Versão já estava fechada aguardando
aprovação — seguir a instrução criava uma Versão nova à toa e invalidava a aprovação pendente
(product-designer, gate 11 da wave 2).
**Causa:** o texto foi escrito por motivo; dois estados do produtor (nunca fechou · fechada e
pendente — `closeContentVersion` nasce com `approvedById` nulo) caem no mesmo `reason`, e o passo
seguinte certo é diferente em cada um.
**Solução:** para cada `reason`, liste no teste os estados de origem que caem nele e afirme o texto
literal de cada um; quando o próximo passo diverge, a mensagem sai do estado de quem produz o dado
(carimbo/máquina de versão). Complementa a lição
`mensagem-de-recusa-recuperavel-diz-o-proximo-passo-com-o-nome-da-acao-da-tela`.

**Reincidência (confirmada 1):** wave 7 do PLAN-065 (TASK-065-012, 2026-10-18), no caminho de publicar — apontada pelo code-reviewer.
