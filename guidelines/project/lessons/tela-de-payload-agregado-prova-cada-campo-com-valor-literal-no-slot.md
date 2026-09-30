---
area: Testes
estado: ativa
validade: indeterminada
confirmada: 1
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.test.tsx
  - mnemonicos-frontend/src/components/**/*.tsx
tags: [teste, mutacao, frontend, exibicao]
---
## [Testes] Tela que renderiza um tipo `*Response` agregado prova cada campo com valor literal no próprio slot

**Erro:** em PLAN-035 (TASK-035-008, gate 1 da Wave 5), a tela do Painel estratégico foi
entregue com asserções de presença (nome do item, `getAllByText(...).length > 0`): 12 de 13
mutantes de exibição sobreviveram (métrica medida virando "Sem medida", "Sem medida" virando
"0", contagens zeradas, rótulo e link removidos), e um campo do contrato (`reworkCountByStage`)
ficou sem consumidor sem nada acusar.
**Causa:** a prova foi organizada por estado da tela (carregando/sucesso/vazio), não por campo
do contrato; presença global na árvore não liga o valor ao slot, e campo não lido não gera erro
de tipo.
**Solução:** (1) para cada campo do tipo, grep no componente — campo que realiza FR da TASK sem
consumidor é achado; (2) cada campo exibido tem ≥1 asserção de valor LITERAL dentro de
`within(<seção/item>)`, nunca `getAllByText(...).length > 0` nem esperado calculado pelo
formatador de produção; (3) todo ramo "sem medida"/condicional tem fixture própria e asserção
no slot, incluindo a ausência do "0" e do marcador. Fechamento: mutante por campo (valor →
rótulo vazio, número → "0") rodado em worktree.

**Reincidência (2026-09-30, mesma TASK, retry 1):** o retry declarou os mutantes "valor→'0'" mortos,
mas 2 slots sem medida (total e média/mediana de um Módulo sem medida) seguiam sem asserção
literal no próprio slot — regex ancorada só no sufixo e linha de fixture que nenhuma asserção lia.
Corolário: o revisor entrega o patch literal de cada mutante e o re-gate roda os mesmos patches.
