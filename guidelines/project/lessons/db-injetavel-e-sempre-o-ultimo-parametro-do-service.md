---
area: Arquitetura
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/**/*.service.ts
  - mnemonicos-backend/src/modules/**/*.routes.ts
tags: [camadas, prisma, injecao-de-cliente, assinatura]
---
## [Arquitetura] O `db = prisma` injetável é sempre o ÚLTIMO parâmetro do service — entrada nova de domínio entra antes dele

**Erro:** no PLAN-065 (TASK-065-013, KAN-273, 2026-10-19), o parâmetro novo das confirmações foi
apensado depois de `db: PublicationClient = prisma` em `publishFinalPdf`. A rota passou a importar
`prisma` só para alcançar o 4º parâmetro, e o code-reviewer reprovou pelo gate 6: "nada de Prisma
direto na rota" (`guidelines/project/backend/README.md`) e `*.routes.ts` NÃO PODE conter Prisma
(node-22.md §4).
**Causa:** um parâmetro opcional novo depois do cliente injetável força o chamador HTTP a passar o
cliente.
**Solução:** no backend, `db = prisma` é sempre o último parâmetro, e entrada nova de domínio entra
antes dele. Exemplar: `exportPublication(rawContentId, input, actor, db = prisma)` em
`src/modules/publication/publication.service.ts`. Conferência: `rg -n "lib/prisma"
src/modules/*/*.routes.ts` só pode achar `health.routes.ts`.
