---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.test.tsx
tags: [mutacao, listener, click-fora, flushSync, jsdom, ordem-de-dispatch]
---
## [Testes] Trocar o evento de um listener reexecuta todo mutante cujo sujeito é ele — e a exclusão do gatilho se prova na ordem de dispatch do navegador

**Erro:** no PLAN-046 (KAN-178, 2026-09-30), o fechamento por toque fora do menu recolhível
(`src/components/internal-sidebar.tsx`) passou de `pointerdown` para `click` no retry do gate 11.
O mutante que remove a exclusão do botão (K7) passou a sobreviver: a metade `fireEvent.pointerDown`
do teste R7 ficou vácua (não havia mais listener de pointerdown) e ninguém reexecutou K7 — o retry
reexecutou só os mutantes que o review citou. No navegador real, sem a exclusão, o click que abre o
menu registra o listener do document durante o próprio dispatch (checkpoint de microtask entre
listeners) e o menu fecha na hora: nunca abriria. O `code-reviewer` reprovou o re-review.

**Causa:** mutante é amarrado ao sujeito (o listener), não ao achado; trocar o evento do sujeito
muda o que cada prova antiga alcança. E o `fireEvent`/user-event do jsdom despacha numa pilha JS só,
sem o checkpoint de microtask que o navegador roda entre listeners — o commit do React e o efeito
que registra o listener nunca acontecem no meio do click de abertura.

**Solução:** ao trocar o evento de um listener, reexecute **todo** mutante da TASK cujo sujeito é
aquele listener, não só os citados. Listener de click-fora registrado por `useEffect` prova a
exclusão do gatilho com um listener no `document.body` que chama `flushSync(() => {})` durante o
click de abertura (desfeito em `try/finally`), afirmando que o menu segue aberto; a contraprova sem
o listener do body deixa o mutante vivo.
