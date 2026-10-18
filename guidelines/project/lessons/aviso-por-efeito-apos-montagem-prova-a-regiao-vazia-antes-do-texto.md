---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.test.tsx
  - mnemonicos-frontend/src/app/**/*.test.tsx
tags: [acessibilidade, aria-live, ordem, mutacao, falsificabilidade]
---
## [Testes] Aviso que entra "por efeito, depois da montagem" se prova com a região vazia ANTES do texto

**Erro:** no PLAN-063 (TASK-063-009, KAN-256, 2026-10-18) o critério exigia que "Pacote removido."
chegasse ao `role="status"` da lista por efeito, depois de a região estar montada vazia (README do
frontend, KAN-192: região inserida já com texto não é anunciada). O teste só afirmava o estado final
com `findByText`; o mutante que volta ao molde de `users-screen.tsx` (`useState(cond ? TEXTO : '')`,
texto já no primeiro render) passou verde.
**Causa:** a propriedade exigida é de ORDEM (vazio no 1º commit, texto depois), e uma asserção por
`findBy` só olha o fim. O molde existente no repositório faz justamente o contrário, então a
regressão mais provável era a invisível.
**Solução:** requisito "região já montada vazia" / "depois da montagem" tem 2 asserções no mesmo
`it`: logo após `render()`, sem `await`, a região existe e está vazia (`toBeEmptyDOMElement()`);
depois, o texto por `findBy`. Mutante obrigatório: inicializar o texto no render — ele tem de
reprovar. Referência: `mnemonicos-frontend/src/components/sales-package-list.test.tsx`.
