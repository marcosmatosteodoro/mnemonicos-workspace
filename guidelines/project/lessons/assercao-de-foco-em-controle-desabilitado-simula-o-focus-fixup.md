---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.test.tsx
  - mnemonicos-frontend/src/components/**/*.tsx
tags: [acessibilidade, foco, jsdom, busy-button, teclado, falso-verde]
---
## [Testes] Asserção de foco em controle que fica `disabled` simula o *focus fixup* — o jsdom mantém o foco no botão desabilitado e aprova qualquer coisa

**Erro:** no PLAN-065 (TASK-065-015, KAN-275, 2026-10-19), o critério "o foco não vai ao `<body>`"
do download em voo passou no jsdom com `expect(document.activeElement).toBe(busy)`. No Chrome, o
foco cai no `<body>` no instante em que o `BusyButton` é desabilitado e continua lá quando o botão
volta. Quem usa teclado precisa percorrer a página desde o topo. O product-designer provou isso
com uma sonda no Chrome headless.
**Causa:** o jsdom não implementa o *focus fixup* do HTML: `document.activeElement` permanece no
elemento desabilitado. Toda asserção de foco num controle em voo passa sem provar nada.
**Solução:** quando a asserção de foco envolve um controle que fica `disabled` (BusyButton em voo,
confirmar de diálogo), o teste simula o fixup logo depois do clique — e `el.blur()` sozinho NÃO basta: o jsdom também ignora `blur()` em elemento desabilitado; o helper reabilita o controle por um instante, chama `blur()` e restaura o `disabled` (exemplar: `simulateFocusFixup` em `published-pdfs-panel.test.tsx`) — e prova o alvo
de foco de **cada desfecho** (sucesso e falha), que o componente nomeia depois do commit
(ref + `useEffect`; exemplar: `users-list.tsx`). A alternativa é verificar no navegador real
(gate 9, `document.activeElement`). A simples permanência do foco no botão desabilitado nunca vale
como prova. Ver também `controle-que-dispara-a-troca-de-conteudo-fica-montado-durante-o-carregamento`.
