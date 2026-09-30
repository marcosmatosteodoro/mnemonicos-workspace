---
area: Testes
estado: ativa
validade: indeterminada
confirmada: 1
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.test.tsx
tags: [teste, mutacao, fake]
---
## [Testes] Fake de rede espelha as recusas do schema da rota; seleção sobre coleção tem fixture com ≥2 itens

**Erro:** no teste do painel de aprovação (TASK-033-007, PLAN-033), o fake da mutation
aceitava qualquer corpo, e todo fixture tinha uma Versão só. Três mutantes passaram verdes
com o componente montado: enviar os 2 checks como `false`, trocar `at(-1)` por `at(0)` e fixar
`number: 1`.
**Causa:** os mutantes prescritos cobriam invalidação de cache e extrator, mas não o contrato
de entrada da rota (`z.literal(true)`) nem o predicado de seleção da entidade (vigente =
última). Com um fake mais permissivo que o backend e um fixture de cardinalidade 1, os dois
eixos não se distinguem.
**Solução:** o fake de endpoint num teste de componente devolve 422 quando o corpo viola o
schema Zod real da rota. Um predicado de seleção sobre coleção (`at(-1)`, `find`, "vigente")
ganha ao menos 1 fixture com 2 ou mais itens, em que o alvo difere do 1º elemento.

**Reincidência (retry R-1 da Entrega da F9, 2026-09-29):** a linha de validade saiu de um bloco
que lia `currentVersion` (restrição estrutural) para dentro do `versions.map`, filtrada por
`version.id === currentVersion?.id`. Nenhum teste montava uma Versão NÃO vigente aprovada, e o
mutante que troca o filtro por `true` sobreviveu. Todo refactor que troca "renderizar a partir do
sujeito" por "renderizar por item com filtro" ganha 1 caso com ≥2 itens, em que o não-alvo satisfaz
as outras condições do ramo, com contagem exata ou ausência.
