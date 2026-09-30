---
area: Design
estado: ativa
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**
tags: [autorizacao-de-ui, papel, leitura]
---
## [Design] Leitura exigida para todo papel fica fora da guarda de papel da ação

**Erro:** no painel de aprovação (TASK-033-007, PLAN-033), a linha "Válida para a próxima
exportação" (FR-032-007(b), leitura sem restrição de papel) foi renderizada dentro do bloco
condicional da ação, que é restrita a ADMIN. O EDITOR via "Aprovada por…" na Versão vigente e não
via que o PDF sairia como rascunho. A persona EDITOR da SPEC pede exatamente essa informação.
Achado na aceitação do PO e na convergência de fecho, depois de 5 gates aprovarem a TASK.
**Causa:** o componente agrupou num único ramo `isAdmin` o estado de LEITURA e o controle de
AÇÃO. O FR de leitura não diz papel, e a guarda da ação o engoliu sem que ninguém decidisse isso.
O teste "EDITOR não vê o painel" acabou fixando a ausência.
**Solução:** num componente que mistura leitura e ação sobre o mesmo recurso, a guarda de papel
envolve só o controle de ação. Todo campo que a SPEC manda expor para leitura renderiza fora do
ramo de papel, e cada persona da SPEC ganha 1 teste montado com o próprio papel, afirmando a
presença do campo lido.
