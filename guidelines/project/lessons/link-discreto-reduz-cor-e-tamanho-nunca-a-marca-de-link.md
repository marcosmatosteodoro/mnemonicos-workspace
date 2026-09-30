---
area: Design
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/app/**/*.tsx
  - mnemonicos-frontend/src/components/**/*.tsx
tags: [design, link, afordancia, acessibilidade, toque]
---
## [Design] Link "discreto" reduz cor e tamanho, nunca a marca de link

**Erro:** em BRIEF-039/KAN-177 (gate 11), o link "Voltar para o início" de `/login` saiu com cor
secundária (`text-muted`) e sublinhado só no hover. Parado, ficava idêntico, pixel a pixel, ao status
"Entrando…" logo acima (mesma cor computada, tamanho e alinhamento). No celular, alvo explícito do
card, não existe hover, então a afordância era zero.
**Causa:** "discreto, sem aparência de botão" virou "sem nenhuma marca de link". O padrão canônico
do produto (sublinhado em repouso em todos os `<Link>`, ex.: `src/app/not-found.tsx:15`,
`src/components/content-list.tsx:96`) foi trocado por hover-only.
**Solução:** link discreto baixa cor e tamanho, mas mantém `underline` em repouso. Hover-only não
conta como afordância (WCAG 1.4.1: não pode depender só de cor). Se o link fica ao lado de texto não
interativo com o mesmo token, confira em tela que os dois se distinguem sem cor, e trave com
`toHaveClass('underline')` no teste.
