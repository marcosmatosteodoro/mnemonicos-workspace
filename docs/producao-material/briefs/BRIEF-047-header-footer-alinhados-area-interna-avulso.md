# BRIEF-047: Header e footer alinhados à área interna

**Slug**: producao-material
**Tipo**: avulso
**Status**: Aberto
**Data**: 2026-09-30
**Largada**: 2026-09-30T20:58:32-0300
**Origem**: Diretor (resposta à pergunta estacionada da Entrega do KAN-178, 2026-09-30: "Brief avulso depois")

## Pedido como dito
> Pergunta da Entrega do KAN-178: "Nas rotas internas, acima de 1024px, o header e o footer (1024px)
> ficam até 128px deslocados para dentro em relação à sidebar e ao conteúdo (1280px). Como sigo?"
> Resposta do Diretor: "Brief avulso depois (Recomendado)" — manter a entrega do KAN-178 como está e
> alinhar header/footer só nas rotas internas, sem mexer nas páginas públicas.

## Interpretação
Depois do PLAN-046, a área interna pronta usa `PageContainer wide` (`max-w-7xl`, 1280px) e o header
(`src/components/site-header.tsx:9`) e o footer (`src/components/app-chrome-gate.tsx:38`) seguem em
`max-w-5xl` (1024px). Acima de 1024px nenhuma borda do header coincide com a sidebar ou com o conteúdo:
0–128px de desvio entre 1025 e 1279px e 128px de cada lado a partir de 1280px (aritmética do gate 11,
Wave 2 do PLAN-046; TRISK-046-005; DEC-046-003 "Reabrir se"). O ponto que decide já existe:
`app-chrome-gate.tsx` lê `usePathname()` e os prefixos internos vivem em `src/lib/internal-routes.ts`.
Na rota interna, header e footer passam a `max-w-7xl` com o mesmo `px-4 sm:px-6`; nas páginas públicas
nada muda. Decisão em aberto para quem executar: os estados carregando/sem permissão da casca usam
`PageContainer default` — aceitar o desvio invertido (header largo, mensagem estreita) ou passá-los a
`wide` também (revê a escolha "default nos não prontos" da DEC-046-003).

## Critério de aceite
- Nas rotas internas (`/studio`, `/content` e subpáginas, `/visual-library`), a borda esquerda do logo
  coincide com a da sidebar e a borda direita do controle de autenticação coincide com a do conteúdo,
  a 1280 e 1440px, nos dois temas; entre 1024 e 1279px, header, footer e conteúdo têm a mesma caixa
  (`vw − 48`).
- Home, `/login` e 404 mantêm header e footer em `max-w-5xl`, idênticos a antes.
- Os estados carregando e sem permissão da casca seguem a decisão registrada no próprio brief (default
  ou wide), com teste.
- Suíte do frontend verde; `layout.test.tsx`/`app-chrome-gate.test.tsx` provam a largura por rota com
  controle positivo; verificação em tela (gates 9/11) a 1024, 1280 e 1440, dois temas.

## TASKs
nenhuma — o brief é a unidade de execução

## Execução
- **Implementado por**: pendente — aguardando o Diretor autorizar a execução (sem card no quadro até lá)
- **Revisado por**: pendente
- **Commit**: pendente
