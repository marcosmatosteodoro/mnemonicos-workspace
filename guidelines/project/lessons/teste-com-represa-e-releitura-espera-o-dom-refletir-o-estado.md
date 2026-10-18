---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.test.tsx
  - mnemonicos-frontend/tests/support/**
tags: [flake, rtk-query, releitura, act, mutacao]
---
## [Testes] Teste com represa e releitura espera o DOM refletir o estado antes de afirmar ou agir

**Erro:** no PLAN-063 (TASK-063-011, KAN-258, 2026-10-18) dois casos de `sales-package-items.test.tsx`
eram intermitentes (3/15 e "sempre com 30 ms de latência"): a asserção síncrona `toBeDisabled` rodava com o
GET da releitura já pendente na store mas antes do render com `isFetching`; e a 2ª ação de uma sequência
caía enquanto a releitura da 1ª ainda travava os botões (clique no-op). O vermelho sob mutante foi lido
como "acoplamento"/"prova por acaso" sem rodar a base repetidas vezes.
**Causa:** o lock derivado de `isFetching` muda o DOM um microtask depois da store; a mutação valida uma
rodada só por mutante e nada separa morte por mutante de flake.
**Solução:** (a) asserção sobre trava/lock só depois de `await waitFor(...)` no próprio estado travado;
(b) a 2ª ação de uma sequência só depois de esperar o DOM refletir a releitura da 1ª; (c) antes de atribuir
a um mutante uma morte fora do eixo dele, rodar a base ≥10 vezes no mesmo arquivo. Referência:
`mnemonicos-frontend/src/components/sales-package-items.test.tsx` ("a trava cobre a releitura").
