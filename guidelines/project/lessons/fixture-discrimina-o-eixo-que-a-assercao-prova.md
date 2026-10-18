---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/tests/**
  - mnemonicos-frontend/src/**/*.test.ts
  - mnemonicos-frontend/src/**/*.test.tsx
tags: [fixture, mutacao, falsificabilidade, encoding]
---
## [Testes] A fixture discrimina o eixo que a asserção diz provar

**Erro:** no PLAN-063 (2026-10-18) dois testes passavam com o código errado porque a fixture não variava
o eixo afirmado. (1) TASK-063-004: a substituição afirmava `sizeBytes` do arquivo novo com
`minimalPdfBytes()`, que varia o conteúdo mas não o comprimento — o mutante que não gravava `sizeBytes`
sobreviveu. (2) TASK-063-005: o teste de `encodeURIComponent` no path usava id `a b`, e o próprio `fetch`
já codifica o espaço — o teste passava sem o encode.
**Causa:** a fixture escolhida provava um eixo (digest; formato do id) e era lida como prova de outro
(tamanho; codificação feita pelo código).
**Solução:** para cada campo afirmado, a fixture tem ANTES ≠ DEPOIS nesse campo e o teste afirma a
desigualdade (ex.: `minimalPdfBytes(row.sizeBytes + 512)`); teste de encoding de segmento usa caractere
que o runtime não codifica sozinho (`/`, `?`, `#`) e espera a forma codificada (`%2F`…). Antes de aceitar,
confirmar que o teste falha sem o código sob prova (mutante).
