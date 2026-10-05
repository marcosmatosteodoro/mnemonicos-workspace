---
area: Design
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.tsx
tags: [design, foco, acessibilidade, layout]
---
## [Design] Contêiner de controles com `overflow-*` corta o anel de foco e cria rolagem de 1px

**Erro:** o `tablist` do KAN-232 usou `overflow-x-auto` "para caber em 328px". O gate 11 mediu
scrollHeight 38 > clientHeight 37: com a barra clássica do Windows aparece rolagem vertical ao lado
das abas, e o anel de foco (`outline-offset-2` + 2px) saía cortado.
**Causa:** `overflow-x` diferente de `visible` força `overflow-y: auto`; o outline com offset e a
margem negativa dos filhos (`-mb-px`) passam a contar como transbordo.
**Solução:** contêiner que recebe controles com `FOCUS_CLASS` não leva `overflow-*`. Antes de pôr
rolagem, some as larguras dos itens contra o container útil (3 abas ≈ 256px cabem em 328px). Se
precisar rolar, dê padding ≥ offset + largura do outline e não use margem negativa nos filhos.
Referência: `src/components/content-edit-tabs.tsx`, `src/lib/action-link-class.ts`.
