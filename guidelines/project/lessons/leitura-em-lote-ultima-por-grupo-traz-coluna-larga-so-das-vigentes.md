---
area: Performance
estado: em-observacao
validade: indeterminada
confirmada: 0
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
