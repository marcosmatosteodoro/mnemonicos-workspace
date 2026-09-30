---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/**/*.test.tsx
tags: [teste, mutacao, espiao, next-link, navegacao]
---
## [Testes] Espião de `useRouter().push` não observa a navegação de `next/link`

**Erro:** em BRIEF-039/KAN-177 (gate 1), `page-back-link.test.tsx` provava "o link continua acionável
durante o login" com `userEvent.click(link)` mais `expect(pushMock).not.toHaveBeenCalled()`. O
`pushMock` é o `useRouter().push` do mock de `next/navigation`, e o `next/link` nunca o chama. A
asserção não podia falhar: o mutante "onClick que chama `preventDefault` durante isLoading" passou
por este teste e só morreu por outro arquivo.
**Causa:** é a mesma classe da lição legada "Espião de ausência (`not.toHaveBeenCalled`) num client
Prisma que não é o mesmo objeto recebido pelo código sob teste nunca falsifica"
(`guidelines/project/lessons.md`), cuja validade está redigida só para o Prisma. O frontend não a
reconheceu.
**Solução:** asserção de ausência só sobre um espião que o código sob teste de fato invoca. Para
provar que um clique em link não é bloqueado, use o evento, não um espião do roteador:
`const ev = createEvent.click(link); fireEvent(link, ev); expect(ev.defaultPrevented).toBe(false)`.
Rode o mutante "preventDefault no clique" e confirme que ele fica vermelho NESTE teste.
**Validade da receita:** `defaultPrevented === false` só vale enquanto o render de teste **não**
monta `AppRouterContext`. Sem roteador, o `next/link` sai cedo sem prevenir
(`node_modules/next/dist/client/app-dir/link.js`, `if (!router) return`). Em produção, e em teste
que monte o roteador, o próprio `Link` previne o default para navegar no cliente. Nesse arranjo,
prove a navegação pelo roteador montado, não por `defaultPrevented`.
