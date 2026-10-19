---
area: Design
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.tsx
  - mnemonicos-frontend/src/app/**/*.tsx
tags: [tailwind-4, surface-card, tokens, preflight, consistencia]
---
## [Design] Bloco delimitado (caixa, painel, aviso) usa `surface-card`, nunca `border`/`rounded-*` crus

**Erro:** no PLAN-065 (TASK-065-014, KAN-274, 2026-10-18), o contêiner novo do Aviso de exportação
(`export-warnings-list.tsx`) saiu com `rounded-md border p-3`. No Tailwind 4, `border` sem cor herda
`currentColor` do preflight, então a borda sai na cor do texto: preta no tema claro, quase branca no
escuro. O raio também ficou menor que o do resto do produto. O product-designer reprovou com
severidade alta. `rounded-md` não tinha nenhum outro uso em `src/`, contra 93 de `surface-card`.
**Causa:** o §9 do `next-16.md` ("padrão visual recorrente → `@utility` do `globals.css`") não foi
aplicado, e nenhum critério nem teste olha a classe de contorno.
**Solução:** todo bloco delimitado usa `surface-card` (`@utility` em
`mnemonicos-frontend/src/app/globals.css`). `border`/`rounded-*` crus só entram com cor e raio de
token explícitos e com o motivo declarado. Conferência no diff:
`git grep -nE 'rounded-(sm|md|lg)|\bborder\b' -- src/components`, lendo cada ocorrência nova.
