---
area: Testes
estado: ativa
validade: indeterminada
confirmada: 0
contestada: 0
tags: [teste, guarda]
---
## [Testes] Guarda nova que preempta a antiga migra a prova da antiga para um caminho de produção real

**Erro:** a guarda de edição pós-fechamento (PLAN-031) passou a recusar antes da guarda de
sinal de alteração sempre que a edição vinha por `updateRawContent`. O retry manteve o
teste antigo verde trocando o setup por escrita direta no Prisma — um estado que nenhum
escritor real produz — e o caminho real que ainda chegava à guarda antiga
(`saveRuleBreakdown`) ficou sem caso; o mutante "Quebra do snapshot em vez da ao vivo"
sobreviveu.
**Causa:** o teste foi ajustado para continuar verde, sem enumerar os escritores reais que
ainda alcançam a guarda antiga.
**Solução:** quando uma guarda nova preempta outra, a prova da antiga migra para um caminho
de produção remanescente (grep dos escritores do dado), nunca para escrita direta que
produz estado inalcançável. Escrita direta pode ficar, rotulada como prova de MECANISMO,
não do AC. Se não sobra caminho real, a guarda antiga vira código morto a declarar.
