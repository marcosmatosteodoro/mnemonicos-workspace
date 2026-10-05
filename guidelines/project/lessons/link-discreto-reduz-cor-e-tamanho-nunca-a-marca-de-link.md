---
area: Design
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 2
paths:
  - mnemonicos-frontend/src/app/**/*.tsx
  - mnemonicos-frontend/src/components/**/*.tsx
tags: [design, link, afordancia, acessibilidade, toque]
---
## [Design] Link "discreto" nunca fica indistinguível do texto não interativo vizinho

**Erro:** em BRIEF-039/KAN-177 (gate 11), o link "Voltar para o início" de `/login` saiu com cor
secundária (`text-muted`), sublinhado só no hover e alinhado à esquerda. Parado, ficava idêntico,
pixel a pixel, ao status "Entrando…" logo acima (mesma cor computada, tamanho e alinhamento). No
celular, alvo explícito do card, não existe hover, então a afordância era zero.
**Causa:** "discreto, sem aparência de botão" virou "igual ao texto vizinho em tudo". Nenhuma
propriedade além da cor separava o link do status.
**Solução:** link discreto pode baixar cor e tamanho, mas precisa de pelo menos uma marca que não
dependa só de cor (WCAG 1.4.1) e que o separe do texto não interativo vizinho. Hover-only não conta,
porque não existe no toque. Desde o KAN-233 (2026-10-05) o produto **não sublinha link** (ver
`guidelines/project/frontend/link-sem-sublinhado.md`): a separação vem da cor `text-link`, da posição: isolado e com alinhamento diferente do texto vizinho, como no
`/login` centralizado (BRIEF-042). Confira em tela que os dois se distinguem sem cor e trave a marca
escolhida no teste (a classe de sublinhado ou a de alinhamento). Quando a marca é só a posição,
meça a folga pela extensão do TEXTO (`Range.getBoundingClientRect`), não pela caixa (em `flex-col` a
caixa do vizinho estica a largura toda e mostra sobreposição falsa), e na menor largura suportada
(360px). No BRIEF-042, a folga era de 66px em 768/1280 e caía para 14px em 360.
**Reformulada em 2026-09-30 (contestada 1):** a versão anterior exigia o sublinhado em repouso. O
Diretor decidiu, no BRIEF-042, `/login` com o link centralizado e sem sublinhado. A regra de fundo
(não ficar indistinguível do vizinho) se mantém, e o sublinhado passa a ser o default, não a única
marca aceita.
**Reformulada em 2026-10-05 (contestada 2):** o Diretor tirou o sublinhado de toda a aplicação
(KAN-233). Aqui a premissa "sublinhado por default" deixa de valer; a regra de fundo permanece: o link
precisa de marca além do texto vizinho (cor `text-link` + posição + hover `link-hover`), e link em
texto corrido exige ≥3:1 contra o vizinho.
