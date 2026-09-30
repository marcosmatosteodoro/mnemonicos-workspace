---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/**/*.test.tsx
tags: [teste, ordem, dom, oraculo, mutacao, frontend]
---
## [Testes] Ordem entre elemento e texto se prova por `childNodes`, nunca por `firstElementChild`

**Erro:** no BRIEF-045 (KAN-186, 2026-09-30), `src/components/auth-control.test.tsx`
afirmava "spinner à esquerda do rótulo" com `button.firstElementChild` igual a `svg`. O
mutante que põe o texto "Saindo" antes do `<Spinner/>` passou verde. O `code-reviewer`
pegou isso rodando o mutante.
**Causa:** `firstElementChild` e `children` só enxergam **elementos**. Quando o irmão é um
nó de texto, a ordem entre elemento e texto fica invisível, e a asserção passa por
construção, qualquer que seja a ordem.
**Solução:** ordem entre elemento e texto no mesmo contêiner se prova por `childNodes`, por
exemplo `Array.from(el.childNodes, (n) => n.nodeName.toLowerCase())` igual a
`['svg', '#text']`, ou pelo par `previousSibling`/`nextSibling`. Nunca se prova por
`firstElementChild`/`children`. O teste só fecha quando o mutante "inverter a ordem" é
executado e fica vermelho. Aplica ao DOM a regra "Oráculo tem de poder falhar" do
`frontend/next-16.md` §7.
