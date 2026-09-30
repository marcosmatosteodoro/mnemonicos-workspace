---
area: Design
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.tsx
tags: [design, estados, vazio]
---
## [Design] Vazio de seção que agrupa métricas independentes não esconde a métrica irmã

**Erro:** em PLAN-035 (TASK-035-008, gate 11 da Wave 5), a seção "Tempo por página e por etapa"
sumia inteira atrás do vazio quando nenhum Conteúdo tinha tempo por página — escondendo o tempo
por etapa, que existia (fontes independentes no backend), justamente no estado do dia do
lançamento.
**Causa:** a TASK definiu o vazio da seção pela falta de uma das métricas, sem conferir no
produtor que as duas métricas têm fontes independentes.
**Solução:** em seção que agrupa métricas independentes, o vazio da seção só vale quando falta
TODO o dado próprio dela; a ausência de uma métrica vira nota inline e nunca oculta a irmã.
Conferir no produtor se as fontes são independentes antes de definir o gatilho.
