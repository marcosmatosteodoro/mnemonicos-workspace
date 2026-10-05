# Link sem sublinhado (KAN-233)

**Nenhum link da aplicação exibe sublinhado**, nem em repouso nem no hover. Ordem do Diretor
(2026-10-05); substitui o "sublinhado por default" anterior.

## Regra

- Proibida a classe `underline` (e `hover:underline`) em `src/`. Prova: `src/lib/no-underline.test.ts`
  varre `src/` e falha se ela voltar (tem controle positivo do detector).
- Marca de hover: utilitário `link-hover` (`globals.css`) — fundo translúcido derivado de
  `currentColor`, segue o tema, sem cor literal. Todo link ou botão-com-cara-de-link leva
  `link-hover`.
- Foco por teclado: outline visível de cada componente (`FOCUS_CLASS`), não muda.
- Link reconhecível por cor (`text-link`, ≥4.5:1 nos dois temas) e por posição (isolado, fora de
  parágrafo).
- **Link dentro de texto corrido** (hoje não há nenhum): WCAG 1.4.1 exige contraste ≥3:1 contra o
  texto vizinho além da marca de hover/foco. Meça e declare; se não alcançar, vai ao Diretor — não
  volta o sublinhado por conta própria.
