---
area: Design
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.tsx
tags: [design, layout, brief]
---
## [Design] Critério de "linha única em N px" soma os botões contra o container útil, não o viewport

**Erro:** o BRIEF-055 (KAN-231) exigiu as quatro ações da barra numa linha só a partir de 768px. O
gate 11 mediu 740px de barra contra 720px de container útil (viewport menos o padding de
`PageContainer`) e o Remover caiu numa segunda linha.
**Causa:** o critério foi escrito pelo viewport, sem somar as larguras reais dos rótulos (padding +
borda + ícone + gap + texto em Geist 14px/500) contra a largura útil no breakpoint.
**Solução:** antes de fixar breakpoint de linha única num brief, some as larguras dos botões e
compare com `viewport − padding do PageContainer`. Se não couber, encurte o rótulo (padrão
`ActionButton`: rótulo curto, nome acessível completo) em vez de apertar padding.
