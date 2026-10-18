---
area: Performance
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/publication/**
tags: [pdf-lib, event-loop, deflate, png, teto, n+1]
---
## [Performance] No pdf-lib, `await image.embed()` logo após `embedPng`/`embedJpg`, dentro do laço que cede — o deflate não fica para o `save()`

**Erro:** no PLAN-065 (TASK-065-007, 2026-10-18), o embedding de PNG no PDF final deixou a compressão
do raster para o `doc.save()` monolítico; o `setImmediate` por Quadro e o teto de 12 s não cobriam o
custo dominante — 8 PNG 4000×3000 levaram 18–20 s (> 15 s da Vercel), com o event loop parado por
11–12 s (performance-engineer, gate 10 da wave 3). No mesmo diff: teto de bytes só verificado depois de
compor tudo e um `findUnique` de binário por Quadro (N+1).
**Causa:** `embedPng` só decodifica; o deflate (pako) roda no `save()` para todas as imagens de uma vez.
O ponto de cessão ficou antes do trabalho pesado, não em volta dele.
**Solução:** `await image.embed()` (API pública `PDFImage.embed`) dentro do laço que cede — move o deflate
para o Quadro e libera o raster; somar o tamanho de cada stream embutido e recusar assim que passar do
teto; carregar binários em lote (`findMany` + `Map`). Teste de teto com PNG grande real, nunca dublê de
timer. Referência: `final-image.ts`, `publication.service.ts` (`loadFinalExportInput`), node-22 §10.
