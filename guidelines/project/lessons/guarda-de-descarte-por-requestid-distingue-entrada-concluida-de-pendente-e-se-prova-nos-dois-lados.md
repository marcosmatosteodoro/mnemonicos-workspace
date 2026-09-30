---
area: Código
estado: em-observacao
validade: indeterminada
confirmada: 1
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.tsx
  - mnemonicos-frontend/src/components/home-session-gate.tsx
tags: [rtk-query, strictmode, guarda, remontagem, mutacao]
---
## [Código] Guarda de descarte por `requestId` distingue entrada concluída de pendente e se prova nos dois lados

**Erro:** na TASK-041-003 (PLAN-041, KAN-180, 2026-09-30), o `HomeSessionGate` ganhou uma
guarda para não reaproveitar o resultado de uma montagem anterior: o `requestId` da entrada
do RTK Query capturado na montagem era marcado como "velho". A guarda descartava também a
entrada ainda **pendente**. Sob `reactStrictMode: true` (`next.config.ts:10`, ou seja, todo
`next dev`) e na remontagem com a requisição em voo, a home nunca decidia, e a sessão aceita
caía na página pública depois do teto. O `code-reviewer` reproduziu os dois casos em
worktree própria.
**Causa:** o RTK Query não inicia requisição nova enquanto há uma pendente na mesma chave (o
`condition` do `buildThunks` retorna `false` antes de olhar o `forceRefetch`), então o
pendente é o único resultado que vai chegar. A prova cobriu só o lado "reage demais"
(resultado concluído reaproveitado, mutante K35) e nunca montou o componente sob
`<StrictMode>`.
**Solução:** guarda de descarte por `requestId` descarta só entrada **concluída** antes da
montagem (`fulfilled`/`rejected`) e aceita a pendente. Toda guarda de descarte se prova nos
dois lados: reaproveitou resultado velho **e** descartou resultado atual. Componente com
efeito e ref de guarda, num projeto com `reactStrictMode: true`, ganha um caso montado
dentro de `<StrictMode>`.

**Reincidência na correção (mesma TASK, re-review):** a guarda corrigida virou `status === 'fulfilled' || status === 'rejected'`, e só o `fulfilled` ganhou caso; o mutante que tira o `rejected` sobreviveu (a marca saía antes do `access`). O lado "concluído" é uma disjunção: **um caso por status aceito no predicado**, cada um com o mutante que retira só aquele status.
