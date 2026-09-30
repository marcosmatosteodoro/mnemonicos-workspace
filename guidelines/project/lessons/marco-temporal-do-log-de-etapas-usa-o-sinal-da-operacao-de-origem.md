---
area: Dados/Persistência
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/strategic-panel/*.ts
  - mnemonicos-backend/src/modules/production-events/*.ts
tags: [dados, eventos, append-only, metrica]
---
## [Dados/Persistência] Marco temporal derivado do log de etapas usa o sinal da operação de origem, nunca "o 1º evento do tipo"

**Erro:** em PLAN-035 (convergência de fecho), o Painel tomava o 1º evento `CONTEUDO_BRUTO` de
qualquer transição como "início da produção"; um Conteúdo semeado (sem evento de criação) ganhava
ABERTURA na 1ª edição pela tela e passava a ter início registrado nessa data — tempos e idade
"medidos" falsos, poluindo média/mediana/cobertura (a métrica de decisão de escala).
**Causa:** `decideStageTransition` grava ABERTURA para qualquer par sem histórico, seja criação,
seja 1ª edição de um registro nascido fora do fluxo — ter evento não prova que houve o evento de
origem.
**Solução:** todo marco temporal derivado do log de `ProductionStageEvent` (início, criação,
fechamento) se identifica pelo sinal que só a operação de origem grava — para a criação, ABERTURA
+ CONCLUSAO de `CONTEUDO_BRUTO` com o mesmo `occurredAt` (`contents.service.ts`). O teste inclui o
caso "registro semeado e depois editado".
