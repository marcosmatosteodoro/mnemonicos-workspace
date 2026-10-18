---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.test.tsx
tags: [reentrada, duplo-clique, act, ref, mutacao]
---
## [Testes] Trava de reentrada por ref se prova com os dois gatilhos dentro do MESMO `act`

**Erro:** no PLAN-063 (TASK-063-012, KAN-259, 2026-10-18) o teste de "dois cliques" usava `fireEvent.click`
consecutivos; o mutante que remove a guarda síncrona `if (inFlightRef.current) return;` sobreviveu e foi
declarado "defesa em profundidade que o teste não separa". Não era: com `act(() => { b.click(); b.click(); })`
o mutante faz 2 chamadas (3/3 vermelho) e a base fica verde (10/10).
**Causa:** cada `fireEvent` roda no próprio `act`, que commita o render — o 2º clique já encontra o botão
desabilitado, e o teste prova o `disabled`, não a ref. Em produção, dois dispatches na mesma tarefa chegam
antes do commit.
**Solução:** trava de reentrada por ref despacha os dois gatilhos dentro de UM `act` e afirma 1 chamada; fecha
com o mutante que remove só a ref (o `disabled` mantido). "O teste não separa" não é veredito de equivalência
sem tentar o despacho em lote. Referência: `mnemonicos-frontend/src/components/sales-package-items.test.tsx`
("a trava não depende do botão já estar desabilitado").
