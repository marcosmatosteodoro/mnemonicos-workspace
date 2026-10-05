---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.tsx
tags: [codigo-morto, ponto-de-uso, regressao, kan-234]
---
## [Testes] Corrigir um componente sem conferir que a tela o renderiza passa nos testes e não chega ao usuário

**Erro:** o KAN-223 pôs "Confirmar senha" no `ResetPasswordDialog`, que nenhuma tela montava desde o
KAN-220 (a redefinição foi para um formulário próprio em `/users/<id>/edit`). Os testes do KAN-223
provaram o diálogo e passaram; a tela real ficou sem o campo (KAN-234, 2026-10-05).
**Causa:** o ponto de uso em produção não foi conferido antes de mudar a ação, e os testes
montavam o componente direto, sem passar pela tela.
**Solução:** antes de alterar uma ação, ache quem a renderiza (`grep` pelo import fora de
`*.test.*`). Duas implementações da mesma ação: a sem uso sai no mesmo diff. Teste de componente
que nenhuma tela monta não conta como prova.
