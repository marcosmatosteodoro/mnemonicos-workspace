---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/app/**/*.tsx
  - mnemonicos-frontend/src/components/**/*.tsx
  - mnemonicos-backend/src/modules/**/*.routes.ts
  - mnemonicos-backend/src/modules/**/*.service.ts
tags: [mutacao, equivalencia, defesa-em-profundidade, server-component, validacao]
---
## [Testes] Validação repetida em duas camadas tem uma prova por camada — mutante só é equivalente se a saída da camada mutada não muda

**Erro:** no PLAN-065 (TASK-065-002, KAN-262, 2026-10-18), o `returnTo` da Biblioteca visual era
validado no Server Component da página e revalidado no board cliente. O mutante "a página repassa o
valor cru" foi declarado equivalente porque o DOM final ficava igual. O code-reviewer o reexecutou:
a diferença era observável na fronteira página→board (a prop do elemento devolvido). A validação no
servidor que a DEC-065-009 exige ficou sem prova nenhuma.
**Causa:** equivalência julgada pelo oráculo final (DOM), não pela saída da camada mutada. Em defesa
em profundidade, a camada seguinte mascara a falha da anterior em qualquer teste ponta a ponta.
**Solução:** cada camada que valida tem prova observada na própria saída — o elemento/prop que o
Server Component devolve, o argumento que a rota repassa ao service. Um mutante só é equivalente se
nenhuma saída da camada mutada muda, nunca porque a camada seguinte o neutraliza. Alternativa que
dispensa a segunda prova: tirar a segunda camada (no caso, a página passou a renderizar o link e o
valor deixou de atravessar para o componente cliente).
