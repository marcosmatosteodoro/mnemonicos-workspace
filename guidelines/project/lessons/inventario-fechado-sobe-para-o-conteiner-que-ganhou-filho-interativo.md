---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/**/*.test.tsx
tags: [teste, mutacao, inventario, acessibilidade]
---
## [Testes] Inventário fechado sobe para o contêiner que ganhou filho interativo

**Erro:** em BRIEF-039/KAN-177 (gate 1), `login/page.tsx` ganhou um link fora do `<form>`, e o
inventário fechado do AC-030-005 continuou só no form (`login-form.test.tsx:489-495`). O mutante "um
`<button>` extra depois do link no cartão" passava verde, justamente no espaço que o diff abriu e
onde um "Esqueci a senha" cairia naturalmente.
**Causa:** o inventário fechado estava ancorado no componente que, antes da mudança, era o contêiner
inteiro. Quando o contêiner cresceu, a contagem não subiu junto.
**Solução:** quando um diff acrescenta filho interativo a um contêiner cujo AC declara inventário
fechado ("contém exatamente"), a contagem fechada vai para o novo contêiner no mesmo diff (por
papel mais `input, button, a, select, textarea`), e o mutante "controle extra DEPOIS do elemento
novo" é executado antes de declarar o AC coberto.
