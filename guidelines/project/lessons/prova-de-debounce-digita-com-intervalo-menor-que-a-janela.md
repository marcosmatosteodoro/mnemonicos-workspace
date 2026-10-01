---
area: Testes
estado: ativa
validade: enquanto user-event agrupar teclas sem delay no mesmo tick
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/**/*.test.tsx
tags: [debounce, user-event, fake-timers, mutante]
---
## [Testes] Prova de debounce digita com intervalo entre teclas MENOR que a janela e afirma a sequência inteira de valores aplicados

**Erro:** na TASK-049-003 (PLAN-049, KAN-179, 2026-09-30) o teste D2 de
`users-screen.test.tsx` ("rajada de teclas gera uma única mudança") passava com o mutante que
não limpa o timer a cada tecla (`clearTimeout` removido em `users-screen.tsx`): 14/14 verdes.
Pego pelo `code-reviewer` (gate 1, Wave 2) com sonda em worktree isolada.
**Causa:** `userEvent.type` sem `delay` dispara todas as teclas no mesmo tick. Os timers de
todas vencem no mesmo `act`, o React junta as atualizações e o consumidor vê só o valor final,
com ou sem o reset do timer. O critério listava mutantes, mas nenhum mirava o reset.
**Solução:** a prova de debounce digita com intervalo entre teclas menor que a janela —
`userEvent.setup({ delay: <janela − 100>, advanceTimers: (ms) => act(() => void jest.advanceTimersByTime(ms)) })`
— e afirma a sequência INTEIRA de valores aplicados (ex.: só `'ana'`, nunca `'a'`/`'an'`). O
critério de pronto lista o mutante "sem clearTimeout no novo toque", rodado pelo comando do
critério (arquivo inteiro, nunca `-t`). Referência: `mnemonicos-frontend/src/components/users-screen.test.tsx`
(D2), commit `85d190f`.
