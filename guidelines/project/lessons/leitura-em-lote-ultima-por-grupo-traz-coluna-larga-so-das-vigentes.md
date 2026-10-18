---
area: Performance
estado: em-observacao
validade: indeterminada
confirmada: 1
contestada: 0
paths:
  - mnemonicos-backend/src/modules/**/*.service.ts
tags: [performance, consulta, append-only, select]
---
## [Performance] Leitura em lote "mais recente por grupo" traz coluna larga só das linhas que a usam

**Erro:** em PLAN-035 (TASK-035-005, gate 10 da Wave 2), `listLatestVersionsForPanel` trazia
`contentSnapshot` (Json com a cópia integral dos campos versionados) de TODAS as Versões de
todos os Conteúdos — histórico append-only sem teto — para usar só o da vigente aprovada.
**Causa:** o PLAN tratou "evitar N+1" (1 `IN` em vez de `findFirst` por item) como o único
critério de custo; o `IN` resolveu a contagem, não o volume.
**Solução:** a 1ª consulta do lote traz só chaves e colunas estreitas; a coluna larga
(Json/texto) vai numa 2ª consulta `id IN (<linhas que realmente a usam>)`, mantendo a
contagem constante. Não usar `distinct` do Prisma sem `nativeDistinct` como atalho (deduplica
em memória depois de buscar tudo). Referência: core/PERFORMANCE.md "Traga só o necessário";
node-22.md §10 "select explícito".

**Refinamento (PLAN-063, TASK-063-007, KAN-254, 2026-10-18 — medido):** no Prisma 7 com `relationJoins`,
`distinct: ['packageId']` vira `SELECT DISTINCT ON` nativo (não deduplica em memória) — mas sobre um IN que
cobre o acervo inteiro ele ainda lê e ordena TODO o histórico do grupo: com 60 mil exportações, Seq Scan e
sort em disco, ~360 ms por GET, com a contagem de statements fixa em 2 escondendo o custo. Tirar a coluna
larga da projeção resolve a largura, não o volume. Regra: "mais recente por grupo" sobre tabela append-only
se lê com **top-1 por grupo apoiado em índice** — relação com `take: 1` + `orderBy` (vira `LEFT JOIN LATERAL
… LIMIT 1` com Index Scan Backward; medido 9–22 ms com 60k–180k linhas, plano constante) —, nunca com
`distinct`/DISTINCT ON sobre IN. O teste de custo semeia K > 1 linhas por grupo em dois volumes e afirma o SQL
sem `DISTINCT ON`. Referência: `mnemonicos-backend/src/modules/sales-packages/sales-packages.service.ts`
(`listSalesPackages`).
