---
area: Performance
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/lib/**
  - mnemonicos-backend/src/modules/**/*.service.ts
tags: [presigned-url, ttl, volume, streaming, rede]
---
## [Performance] URL de curta validade emitida em lote para consumo proporcional ao volume dimensiona o TTL contra teto ÷ vazão

**Erro:** no PLAN-063 (TASK-063-012, KAN-259, 2026-10-18) o plano de exportação emitia todas as URLs de
download (300 s) de uma vez e o navegador as consumia num laço sequencial (`await fetch` → `await blob()`),
cujo tempo cresce com o volume (teto 500 MiB): em conexão modesta o último pedido chega vencido (403) e a
exportação grande nunca conclui (medido com TTL escalado: o 9º de 10 pedidos venceu). E cada PDF virava um
Blob inteiro antes do ZIP: pico ≈ 2× o Pacote.
**Causa:** o TTL (NFR/AC) e o teto de volume foram fixados em TASKs separadas sem relacionar TTL × teto ÷
vazão mínima; "baixa cada url na ordem do plano" foi lido como série — a ordem do conteúdo não implica ordem
dos pedidos.
**Solução:** URL de curta validade emitida em lote declara a vazão mínima suportada e prova TTL ≥ teto ÷
vazão; senão os pedidos saem todos dentro da janela (disparo antecipado, respeitando o limite de conexões do
navegador) ou há re-assinatura. Montagem de arquivo grande passa `Response` em streaming (async generator)
ao compositor, nunca Blob por item. Referência: `mnemonicos-frontend/src/lib/export-package-archive.ts`;
`core/PERFORMANCE.md` §Frontend/Rede e §Grandes volumes.
