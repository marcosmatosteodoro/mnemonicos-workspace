---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/tests/integration/**
  - mnemonicos-backend/src/modules/**/*.service.ts
tags: [escopo, set-based, raw-sql, mutacao, raio-de-dano]
---
## [Testes] Prova de escopo por agregado pai cobre a escrita BEM-SUCEDIDA de cada método que escreve

**Erro:** no PLAN-063 (TASK-063-008, KAN-255, 2026-10-18) o retry trocou a escrita por linha
(`packageId` + `pdfId`, com `count`) por `UPDATE … WHERE "packageId" = $1` por conjunto. O caso
"escopo por Pacote" (2 Pacotes) só exercitava a RECUSA de reordenar/remover em A; o mutante que
apaga o predicado `packageId` da fase 1 (`WHERE true` — todo Pacote do sistema fica com posições
negativas) sobreviveu à suíte inteira.
**Causa:** a recusa curto-circuita antes da escrita, então um caso de escopo que só passa por recusa
não discrimina o predicado da escrita. A troca para escrita por conjunto ampliou o raio de dano de
um predicado esquecido, e o critério de escopo não foi revisto junto.
**Solução:** com fixture de 2 pais, cada método que escreve tem um caso de SUCESSO no pai A que afirma
o pai B intacto depois da escrita, com posições/linhas comparadas por valor. Quando a escrita passa a
ser por conjunto (SQL cru, `updateMany`), o mutante "predicado do pai removido" é obrigatório para cada
statement. Referência: `mnemonicos-backend/tests/integration/sales-packages.service.integration.test.ts`
(caso "escopo por Pacote").
