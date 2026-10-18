---
area: Design
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**
tags: [estado, rtk-query, lista, foco, edicao-inline, 404]
---
## [Design] Estado de UI guardado por id de item da lista se limpa quando o item some do dado

**Erro:** no PLAN-063 (TASK-063-006, KAN-253, 2026-10-18) o board do Acervo guardava `editingPdfId` e
derivava dele o bloqueio de todas as ações. Um 404 no salvar (PDF removido por outra pessoa) fazia o RTK
Query invalidar a lista também no erro (`isRejectedWithValue`); a linha em edição desmontava e o id ficava
preso — todas as ações do Acervo desabilitadas, sem texto, até recarregar a página.
**Causa:** estado de UI por id de item sem nenhum ponto que o limpe quando o item sai de `data`; e o teste
do 404 usava um fake que devolvia 404 mas mantinha o item na coleção — estado que o backend não produz.
**Solução:** todo estado de UI guardado por id de item de uma lista do servidor (edição embutida, lock,
seleção) se limpa — ou se deriva — da presença do item em `data`, devolve o foco a uma âncora estável e diz
o motivo (`role="alert"`). O fake de teste de um erro 404/409 reproduz o estado que o backend produz (remove
o item da coleção), nunca só o código HTTP. Referência: `mnemonicos-frontend/src/components/pdf-library-board.tsx`.
