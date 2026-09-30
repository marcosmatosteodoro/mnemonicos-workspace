---
area: Testes
estado: ativa
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.test.tsx
tags: [teste, mutacao, estado-de-ui]
---
## [Testes] Estado limpo em 2 caminhos tem 1 cenário por caminho

**Erro:** no painel de aprovação (TASK-033-007, PLAN-033), o reset das 2 caixas ficou em dois
handlers: o sucesso da aprovação e o sucesso do fechamento de nova Versão. O único teste fazia
"aprovar com sucesso → fechar", então passava pelos dois. Apagar qualquer um dos resets deixava a
suíte verde. O reset de `approveError` no fechamento não tinha asserção nenhuma.
**Causa:** um cenário que atravessa os dois caminhos prova só a união dos resets; cada um mascara
o outro. É a mesma família de "um caso por PAR de ramos que coincide" (`lessons.md`), agora em
escritores de estado.
**Solução:** estado limpo em mais de um caminho ganha um cenário por caminho, em que só aquele
reset roda. Aqui, falhar a aprovação e depois fechar. A alternativa é um único gatilho pela
identidade do assunto (reset na troca de `currentVersion.id`), provado uma vez. Fechamento: o
mutante que apaga cada reset morre sozinho.
