---
area: Testes
estado: ativa
validade: indeterminada
confirmada: 2
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

**Reincidência (2026-10-18, PLAN-063 TASK-063-011 retry, KAN-258):** o critério do retry nomeou UM exemplo
("409 de ordem pelo estado do fake, não por override") e o developer corrigiu só esse teste; no mesmo commit
nasceram 5 testes de recusa (404/409) por `fake.overrides.* = () => errorResponse(...)`, um com literal
inventado que só passava por comparação de substring. Corolário: recusa prevista (404/409) se provoca pelo
ESTADO do fake (mutar `fake.packages`/`fake.pdfs` depois de montar) e se afirma com a constante exportada pelo
fake; override só para o que nenhum estado produz (500, falha de rede, represa). O critério nomeia a CLASSE e
o grep que a fecha (`git grep -nE "overrides\.(…) = \(\) => errorResponse\((409|404)"` → vazio).
