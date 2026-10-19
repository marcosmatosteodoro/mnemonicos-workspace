---
area: Código
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/**/*.store.ts
  - mnemonicos-backend/src/modules/**/*.service.ts
tags: [prisma, tipagem, cast, injecao-de-cliente, pick]
---
## [Código] Porta que só lê um delegate tipa o cliente como `Pick<PrismaClient, '<delegate>'>`, nunca `PrismaClient | TransactionClient`

**Erro:** no PLAN-065 (TASK-065-011, KAN-271, 2026-10-18), o `PublishedPdfStore` tipou o cliente
injetável como `PrismaClient | PrismaTx`. O `getFinalPreview` recebe um recorte
`PublicationClient` (`Pick<…>`), e para chamar o store precisou de `db as StoreReadClient`
(`publication.service.ts:791`). O cast afirmava um `PrismaClient` inteiro onde só existia o
recorte: hoje é seguro, mas o compilador deixa de acusar quando o store passar a usar outro
delegate. O code-reviewer reprovou pelo node-22.md §1 (`as` para calar o compilador).
**Causa:** o tipo do cliente da porta era mais largo do que o uso real dela, enquanto os serviços
do módulo injetam recortes `Pick<…>`.
**Solução:** porta ou store que só usa um delegate tipa o cliente como
`Pick<PrismaClient, '<delegate>'>`. Esse tipo aceita a raiz, o `tx` de `$transaction` e qualquer
recorte maior, sem cast. Exemplar: `PublicationClient` em
`src/modules/publication/publication.service.ts`. Um `as` entre tipos de cliente Prisma é sinal de
que a porta está tipada larga demais: corrige-se a porta, não o chamador.
