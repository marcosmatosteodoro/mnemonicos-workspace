---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/tests/integration/**/*.integration.test.ts
  - mnemonicos-backend/src/modules/**/*.service.ts
tags: [teste, append-only, mutacao, grep]
---
## [Testes] Prova de "escrita nova não reescreve o registro anterior" usa valores DISTINTOS nas duas escritas

**Erro:** em PLAN-035 (TASK-035-001, gate 1 da Wave 1), a prova de que uma reexportação
nunca reescreve o `pageCount` de uma exportação anterior (FR-034-021) usou duas exportações
do mesmo conteúdo — os dois `pageCount` saíam iguais, e o mutante que faz `updateMany` sobre
as linhas antigas logo após o `create` **sobreviveu** (5/5 verdes). O oráculo grep que
acompanhava o critério (`grep -rn "publicationEvent\.(update|updateMany)"`, sem `-E`) era
BRE: parênteses e `|` viravam literais e o grep dava 0 sempre.
**Causa:** o fixture repetiu o mesmo valor nas duas escritas, então "A intocado" e "A
reescrito com o mesmo valor" são indistinguíveis; e o oráculo de ausência nunca foi rodado
contra um positivo conhecido.
**Solução:** prova de "escrita B não altera o registro A" exige valores **diferentes** em A e
B (ex.: A forçado a `null` pela falha controlada, B medido) e um mutante de UPDATE retroativo
**morto** (rodado em `git worktree add`). Oráculo grep com alternância usa `-E` e é calibrado
contra 1 positivo conhecido antes de valer como prova de ausência — ver também a lição
"Prova de ausência por leitura de texto-fonte precisa declarar o universo lido"
(`guidelines/project/lessons.md`).
