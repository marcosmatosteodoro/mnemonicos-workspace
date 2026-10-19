---
area: Código
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/store/api.ts
tags: [rtk-query, invalidatesTags, cache, 409, divergencia]
---
## [Código] Mutation cuja recusa prova divergência invalida pelo `code` — `error ? []` deixa o cache velho

**Erro:** no PLAN-065 (TASK-065-016, KAN-276, 2026-10-19), `publishFinalPdf` passou a invalidar
só no sucesso (`invalidatesTags: (_r, error) => error ? [] : [...]`). Depois de um 409 que prova
divergência (a cobertura mudou, outra aba publicou), o preview e a lista em cache ficavam velhos.
O diálogo reaberto mostrava "3 de 3" sem a caixa, repetia o POST sem confirmação, e o servidor
compunha o PDF de novo para devolver o mesmo 409, agora com um texto falso. O code-reviewer
provou isso por sonda.
**Causa:** a condição respondeu "a recusa gravou algo?" (não), quando a pergunta certa era "a
resposta prova que o servidor difere do cache?". Para os 409 de confirmação, prova. O RTK 2
também invalida em `isRejectedWithValue`, e por isso o array literal não serve.
**Solução:** em mutation cuja recusa carrega estado autoritativo (409 com `code`/`details` de
divergência), `invalidatesTags` decide pelo `code`: sucesso → as tags gravadas; recusa que prova
divergência → a tag do recurso divergente; 5xx, rede ou `code` desconhecido → `[]`. Um só
mecanismo, sem refetch manual paralelo. A prova é um caso por classe de `code` contando os GETs,
e o mutante `error ? []` tem de reprovar o caso de divergência.
