---
area: Design
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.tsx
tags: [disclosure, menu, toque-fora, pointerdown, click, foco, layout-shift, gate-11]
---
## [Design] Painel que muda o layout ao fechar fecha por toque fora no `click`, nunca no `pointerdown`, e só devolve o foco se ele não foi para outro lugar

**Erro:** no PLAN-046 (KAN-178, 2026-09-30), o menu recolhível da área interna
(`src/components/internal-sidebar.tsx`) é um disclosure **no fluxo** (aberto, empurra o conteúdo) e
fechava por toque fora no `pointerdown`. Com o menu aberto, tocar num controle do conteúdo fechava o
painel no down; o conteúdo subia ~150px debaixo do dedo antes do `click`, e o toque se perdia (mouse:
click no ancestral comum) ou acionava outro controle (touch). Arrastar para rolar também fechava o
menu no meio do gesto. O `focus()` no pointerdown ainda perdia o foco no navegador real (o default do
mousedown num alvo não focável leva o foco ao body depois). O teste com `fireEvent.pointerDown` não
simulava esse default e passava. O `product-designer` reprovou no gate 11 da Wave 3.

**Causa:** o evento de "toque fora" foi escolhido sem compor com a decisão de manter o painel no
fluxo (DEC-046-005), e o oráculo do teste não reproduzia o comportamento padrão do navegador.

**Solução:** painel cujo fechamento desloca o layout escuta `click` no document (mesma exclusão de
painel e gatilho), nunca `pointerdown`/`mousedown`; devolve o foco ao gatilho só se
`document.activeElement` for `body`/nulo ou estiver no próprio componente — se o usuário já levou o
foco a um campo ou link, só fecha. O teste de toque fora usa `user.click` num alvo fora (user-event
simula o foco do mousedown), com o par: `pointerdown` fora não fecha; campo fora focado + Esc mantém
o foco no campo.
