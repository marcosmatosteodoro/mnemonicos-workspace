---
area: Design
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/app/(interno)/**/page.tsx
  - mnemonicos-frontend/src/components/**/*.tsx
tags: [layout, flex, responsivo, 360px, cabecalho-de-pagina, gate-11]
---
## [Design] Linha flex de título + ações ganhou item: some as larguras contra 328px antes de dispensar o `flex-wrap`

**Erro:** no PLAN-046 (KAN-178, 2026-09-30), a linha de cabeçalho da Tira
(`src/app/(interno)/content/[id]/tira/page.tsx`, `flex items-center justify-between gap-4`) ganhou
um segundo link ("Voltar ao conteúdo") sem `flex-wrap`. A 360px (328px úteis) título + gaps + dois
links somam ~447px; sem quebra, os itens encolhem e os dois rótulos quebram em duas linhas cada,
intercalados ("Voltar ao / Conteúdos" · "conteúdo / brutos"). Sem rolagem horizontal, o AC de
largura passava; o defeito era de composição. O `product-designer` reprovou no gate 11 da Wave 1.

**Causa:** o item foi acrescentado a uma linha sem folga, e ninguém somou as larguras de conteúdo
contra a menor largura de referência da SPEC. O PLAN prescreveu o `div` interno sem wrap. As
páginas irmãs (detalhe, Quebra, novo) cabem numa linha porque têm um link só.

**Solução:** ao pôr um item numa linha flex de título + ações, some as larguras de conteúdo
(título + gaps + itens) contra 328px (360 − `px-4` dos dois lados). Não coube → `flex-wrap` na
linha externa, no molde de `src/components/strategic-panel-board.tsx:182`
(`flex flex-wrap … justify-between`); nunca deixe a quebra por encolhimento partir rótulo de link.
Prove o token com `tests/support/class-tokens.ts` e o efeito em tela a 360px no gate 9.
