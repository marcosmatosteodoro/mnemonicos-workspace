---
area: Performance
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/store/api.ts
  - mnemonicos-frontend/src/components/**
tags: [rtk-query, cache, tags, refetch, presigned-url]
---
## [Performance] Endpoint cujo resultado nunca é lido do cache não declara `providesTags`

**Erro:** no PLAN-063 (TASK-063-005, KAN-252, 2026-10-18) `getPdfDownloadLink` (URL assinada de 300 s,
trigger lazy com `preferCacheValue=false`) ganhou `providesTags`, e `confirmPdfUpload` invalidava o tipo
inteiro: cada envio refazia 1 GET de download por linha já baixada (medido: 1 linha → +1, 5 → +5).
**Causa:** `useLazyQuery` mantém a assinatura do último argumento enquanto o componente está montado, e a
invalidação de tag refaz toda entrada com assinatura viva. Tag num endpoint "nunca do cache" vira gatilho
de rajada proporcional às linhas da lista.
**Solução:** endpoint cujo resultado nunca é servido do cache (URL assinada de vida curta, trigger lazy
sem `preferCacheValue`) não declara `providesTags`, e nenhuma mutation invalida o tipo dele. Prova: teste
montado contando os GETs do endpoint após a mutation, com N=1 e N≥3; o mutante que devolve a tag morre.
Referência: `mnemonicos-frontend/src/store/api.ts` (`getPdfDownloadLink`).
