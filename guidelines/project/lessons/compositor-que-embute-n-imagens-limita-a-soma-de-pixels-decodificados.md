---
area: Segurança
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/publication/**
tags: [decompression-bomb, memoria, pdf-lib, png, imagem]
---
## [Segurança] Compositor que embute N imagens externas limita a SOMA de pixels decodificados, não só o teto por imagem

**Erro:** no PLAN-065 (TASK-065-007, 2026-10-18), o teto de 20 M px por imagem foi tratado como limite
de memória do PDF; a TRISK-065-005 supunha "preparar e liberar Quadro a Quadro". Medido pelo
security-engineer (gate 8 da wave 3): 10 PNGs de 4472×4472 (logo abaixo do teto) → pico RSS 1004 MB
contra 1024 MB da função e `save()` de 13 s; o PDF saiu com 782 KB (o teto de bytes não segura o vetor).
**Causa:** `PDFDocument.embedPng` do pdf-lib decodifica na hora e guarda o raster RGBA (~4 B/px) até o
`save()`; JPEG é passthrough (DCT), PNG não. A memória cresce com a soma de pixels dos PNGs.
**Solução:** chamar `await image.embed()` logo após cada `embedPng`/`embedJpg` (o pdf-lib 1.17.1 zera o `embedder` e solta o raster — medido: 20 PNG de 4472×4472 com pico de 309 MB, contra 1004 MB com 10 sem o embed ansioso) e ceder o event loop; além disso, todo compositor que embute N imagens de origem externa limita também a soma de pixels
decodificados dos PNGs (ou reduz/converte antes do embed) e prova com N imagens no teto contra o
`memory` do `vercel.json`. Referência: `final-image.ts`, `pdf-composer.ts embedFrameImage`, MEDICAO-065.
