---
area: Design
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/app/globals.css
  - mnemonicos-frontend/src/app/globals-theme-contrast.test.ts
tags: [design, contraste, hover, color-mix, acessibilidade]
---
## [Design] Cor de estado derivada atrás do texto entra na prova de contraste nas duas superfícies

**Erro:** em BRIEF-057/KAN-233 (gate 11), o hover `link-hover` (fundo `color-mix(currentColor 12%)`)
levou o texto a 4,31:1 (link) e 4,36:1 (danger) sobre `--surface-raised` no tema claro, abaixo do
piso AA de 4,5:1.
**Causa:** o contraste dos tokens era medido só em repouso e sobre uma superfície; estados derivados
(hover, `color-mix`, opacidade) não eram medidos sobre todas as superfícies onde o componente aparece.
**Solução:** toda cor de estado derivada que fica atrás ou na frente de texto entra em
`globals-theme-contrast.test.ts` com `mixOverSrgb`, em `{--surface, --surface-raised}` × 2 temas, piso
4,5:1, com controle negativo. O teste lê o percentual do próprio CSS, então mexer nele reprova.
