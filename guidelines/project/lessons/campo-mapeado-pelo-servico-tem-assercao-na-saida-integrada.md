---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 1
contestada: 0
paths:
  - mnemonicos-backend/src/modules/**/*.service.ts
  - mnemonicos-backend/tests/integration/**
tags: [costura, mutacao, integracao, compositor, serializador]
---
## [Testes] Campo que o serviço mapeia de uma leitura para um compositor/serializador tem asserção na saída integrada

**Erro:** no PLAN-065 (TASK-065-006, KAN-266, 2026-10-18), a capa do PDF final foi provada no
compositor (unitário) e o loader isolado (integração); a costura em `exportFinalPublication` que
passa `disciplineName`/`topicName` ao compositor ficou sem oráculo — trocar os dois campos sobreviveu
à suíte inteira (code-reviewer, gate 1 da wave 2).
**Causa:** prova por partes: cada metade tem teste, e a ponta integrada só afirmava o rodapé.
**Solução:** todo campo que um serviço mapeia de uma leitura para um compositor ou serializador ganha
1 asserção na saída da ponta integrada (PDF extraído, payload HTTP). Critério de aceite: o mutante
que troca ou omite o campo na costura fica vermelho.

**Reincidência (confirmada 1):** wave 7 do PLAN-065 (TASK-065-012, 2026-10-18), no caminho de publicar — apontada pelo code-reviewer.
