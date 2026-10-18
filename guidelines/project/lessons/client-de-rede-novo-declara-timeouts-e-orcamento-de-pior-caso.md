---
area: Performance
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/**/*.service.ts
  - mnemonicos-backend/src/modules/object-storage/**
  - mnemonicos-backend/src/lib/**
tags: [timeout, rede, serverless, maxDuration, sdk, orcamento]
---
## [Performance] Client de rede novo declara timeouts e orçamento de pior caso abaixo do `maxDuration`

**Erro:** no PLAN-063 (TASK-063-002, KAN-249, 2026-10-18) o `S3Client` do armazenamento de objetos
entrou sem `requestHandler` nem `maxAttempts`. Contra um servidor mudo o `HeadObject` ficou pendurado
mais de 20 s, acima do `maxDuration` de 15 s da função única `api/index.ts`. A 1ª correção (2000 +
3000 ms × 3 tentativas) foi justificada por medição de um só cenário (servidor mudo, 9,2 s), mas o
pior caso aritmético das próprias constantes era 15 000 ms + backoff.
**Causa:** os defaults do `@smithy/node-http-handler` não têm connection, request nem socket timeout,
e `requestTimeout` sem `throwOnRequestTimeout: true` só emite aviso. O precedente do Prisma
(`src/lib/prisma.ts`) não se transfere sozinho para um client novo. Medir um cenário exercita só o
`socketTimeout`, e o `connectionTimeout` e o backoff do pior caso ficam fora da prova.
**Solução:** todo client de rede novo do backend (SDK, fetch de saída) declara `connectionTimeout`,
`socketTimeout` (ou `requestTimeout` + `throwOnRequestTimeout`) e `maxAttempts` em constantes
exportadas, com a desigualdade `MAX_ATTEMPTS × (CONNECTION + SOCKET) + BACKOFF_MAX < maxDuration`
no docblock e um teste unitário que a asserta, mais um teste com servidor TCP mudo rejeitando dentro
do orçamento. `socketTimeout` mede inatividade: corpo em gotejamento precisa de prazo total da operação
(`AbortSignal.timeout` / `withDeadline` + `stream.destroy()`). Referência:
`mnemonicos-backend/src/modules/object-storage/object-storage.service.ts`.
