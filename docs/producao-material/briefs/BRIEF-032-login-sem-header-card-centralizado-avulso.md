# BRIEF-032: Remover header de `/login` e centralizar o card na tela

**Slug**: producao-material
**Tipo**: avulso
**Status**: Concluído
**Data**: 2026-09-29
**Largada**: 2026-09-29T15:41:42-0300
**Origem**: Diretor (pedido em sessão, feedback direto sobre a branch de PLAN-031 já entregue)
**Jira**: KAN-73

## Pedido como dito
"Ficou muito bom, quero alguma mudanças
1 Não quero o header na tela de login, então vc tira a parte de cima toda
2 quero o card do login centralizado no meio e no centro da tela, atualmente ele ta no
meio e em cima"

## Interpretação
Dois ajustes visuais em `/login` (`mnemonicos-frontend`), sem tocar comportamento: (1)
`SiteHeader` — hoje montado incondicionalmente em `src/app/layout.tsx` para toda rota —
não aparece em `/login`, e só em `/login`; as demais rotas continuam com o header
intacto. (2) O card (`src/app/login/page.tsx`) sai da posição atual (centralizado só no
eixo horizontal, colado ao topo por causa do `py-10` de `<main>`) para centralizado nos
dois eixos, relativo à janela do navegador — mesmo resultado visual em qualquer altura de
tela, não só quando o conteúdo é curto o bastante para "sobrar" no topo.

## Premissas decididas
- **P-032-001** [assumido]: o rodapé (`<footer>` do layout raiz) não foi mencionado no
  pedido ("a parte de cima") — permanece montado; se a nova centralização do card fizer o
  rodapé aparecer de forma estranha (sobreposto, cortado, alcançável só por scroll), é
  achado para o `product-designer`/`qa` registrarem, não uma remoção silenciosa por conta
  própria.
- **P-032-002** [assumido]: a técnica para tirar o header só de `/login`, sem duplicar o
  root layout inteiro em route group, é decisão técnica do developer — mesma classe de
  decisão que DEC-031-001 (fundo em tela cheia via `position: fixed` dentro da árvore
  normal, sem route group, porque este projeto só tem 1 root layout — achado do
  `code-scout`, `docs/producao-material/plans/PLAN-031-redesign-visual-login.md`
  DEC-031-001). Caminho sugerido, não prescritivo: um componente client pequeno que
  decide renderizar (ou não) `<SiteHeader />` a partir do pathname atual
  (`usePathname()` de `next/navigation`), montado sempre por `RootLayout` — mantém
  `RootLayout` como Server Component puro e testável do jeito que
  `src/app/layout.test.tsx` já testa hoje (chama `RootLayout({children: null})` direto,
  sem `render`/jsdom — qualquer solução tem que preservar isso).

## Fora de escopo
- Qualquer mudança de comportamento de `LoginForm`/`PasswordField`/guard de
  `next`/mensagens (contrato intocado desde PLAN-031).
- Header/footer de qualquer outra rota.
- Reabrir a discussão de route group (já decidida e descartada em DEC-031-001).

## Critério de aceite
- `/login` não renderiza `<SiteHeader />` (nem o link do nome do produto, nem o
  `ApiStatus`) em nenhum dos 2 temas nem nas 3 larguras já usadas no ciclo anterior
  (360/768/1280px) — confirmado por captura real, não só por leitura de código.
- Todas as OUTRAS rotas continuam renderizando `<SiteHeader />` exatamente como antes
  (checagem de não-regressão — pelo menos `/` e mais uma rota interna).
- O card de login fica visualmente centralizado nos eixos horizontal E vertical da
  janela, nas 3 larguras (360/768/1280px), nos 2 temas — sem scroll vertical/horizontal
  desnecessário (a menos que o conteúdo do card genuinamente não caiba na altura da
  janela, caso em que scroll é aceitável).
- `627/627` testes do frontend continuam verdes; `src/app/layout.test.tsx` continua
  provando que `RootLayout` monta `ServiceWorkerRegistration` do jeito atual (chamada
  direta, sem `render`) — se a solução escolhida quebrar esse padrão de teste, o
  developer adapta o teste para continuar provando a mesma garantia pelo mesmo
  mecanismo (função pura), não remove a garantia.
- Nenhuma cor literal nova (hex/rgb/hsl) fora dos tokens já existentes em
  `globals.css`/`night-palette-tokens.ts`.
- Lint/typecheck limpos.

## TASKs
<nenhuma — o brief é a unidade de execução>

## Execução
- **Implementado por**: developer — `SiteHeaderGate` novo (`src/components/site-header-gate.tsx`,
  client, `usePathname()`, oculta `SiteHeader` só em `/login`) montado sempre por
  `RootLayout`; wrapper do card em `login/page.tsx` migrado para
  `fixed inset-0 flex items-center-safe justify-center overflow-y-auto` (reaproveita a
  técnica de `position: fixed` de DEC-031-001, sem z-index negativo).
- **Revisado por**:
  - code-reviewer (régua avulsa): APROVADO — 3 achados não-bloqueantes (parêntese falso
    sobre exceção de teste, mutante sobrevivente em `layout.test.tsx`, prosa
    desatualizada em `login-night-backdrop.tsx`), todos aplicados na mesma rodada
    (decisão 4.249).
  - product-designer (gate 11): 1ª rodada REPROVOU — achado real (`items-center` cortava
    o topo do card em janela baixa, ~740×360, sem scroll alcançável). Corrigido com
    `items-center-safe`. Re-review do delta: APROVADO — medição real confirma o topo em
    coordenada ≥0 nas mesmas janelas, sem regressão nas demais. 1 sugestão não-bloqueante
    (comentário de `SCRIM_GRADIENT_TOP` citando `site-header.tsx` como fonte de medida)
    aplicada inline.
  - qa (screen-verify): VERIFICADO — header ausente em `/login` (5 larguras × 2 temas,
    `getByRole('banner')` = 0), header presente em `/` e `/studio` autenticado (= 1, sem
    regressão), card centralizado com delta 0px nas larguras canônicas, topo alcançável
    em janela baixa, sem scroll horizontal, login real (sucesso e falha) exercitado
    ponta a ponta contra o backend real sem regressão. Nenhum achado, nenhum handoff.
  - Achado 2 do product-designer (rodapé sobreposto pelo card em janelas muito baixas,
    <~575-580px de altura) — fora do pedido literal ("a parte de cima"), levado ao
    Diretor (`AskUserQuestion`): decidiu **manter o rodapé e aceitar a sobreposição
    rara**. Registrado, não é achado pendente.
  - Testes: 634/634 → 635/635 (baseline PLAN-031 627 + 1 teste novo líquido desta
    demanda, contando os que a rodada de retry adicionou/consolidou). Lint/typecheck
    limpos.
  - Lição nova roteada (`alvo: projeto`, verificada presente): `guidelines/project/lessons.md`
    — "Centralizar com `items-center` num container `fixed`/tela cheia corta o topo do
    conteúdo que transborda, sem scroll alcançável".
- **Commit**: pendente — commit é ato do Diretor
