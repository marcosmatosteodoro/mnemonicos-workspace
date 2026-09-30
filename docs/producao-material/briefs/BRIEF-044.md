# BRIEF-044: Sidebar de navegação da área interna

**Slug**: producao-material
**Status**: Emitido
**Data**: 2026-09-30
**Largada**: 2026-09-30T17:26:28-0300
**SPEC**: SPEC-044
**Jira**: KAN-178

## Pedido como dito
"/keelson:auto --from=KAN-178 --slug=producao-material Sidebar de navegação da área interna
(Painel, Conteúdos, Biblioteca visual), montada uma vez na casca. A triagem de 2026-09-30
classificou como SPEC nova, e o KAN-180 já está mergeado.

- Sessão: o logo do header (com sessão vai para /studio, sem sessão para /) usa o sinal de
  sessão que o KAN-180 decidiu (BRIEF-040 / TASK-041-002). Não cria DEC de sessão nova.
- A sidebar só aparece na área logada com sessão válida. Nunca aparece na área não logada,
  em /login nem nos estados carregando, sem sessão e sem permissão.
- BRIEF-037 (container max-w-5xl duplicado): INCLUIR no escopo e fechar como absorvido.
  Verificar sem regressão também nas rotas públicas.
- Defaults que aceito, salvo se a SPEC achar motivo contra: no desktop a sidebar fica fixa
  e vira menu recolhível abaixo de md; o menu é disclosure não modal; a Tira ganha um link
  "Voltar ao conteúdo"; nenhum item é filtrado por papel.
- Gate 9: <há | não há> conta de teste sem o papel exigido para exercitar o estado "sem
  permissão"."

A última linha chegou sem preencher. O Tech Lead assumiu **"não há"** (ver Premissas) e o
Diretor pode corrigir na janela de veto.

Conversa na mesma sessão, antes da largada (Diretor → Tech Lead): "a side, só deve aparecer
na área logado, não aparece na não logada e nem na tela de login"; "Pode incluir" (sobre o
BRIEF-037); "vou fazer 180 primeiro".

Card KAN-178 (História, escrito pelo Diretor, fonte da demanda, modo `link`, sem card novo):

> **Sidebar de navegação da área interna (Painel, Conteúdos, Biblioteca visual)**
>
> ## Contexto
> A área logada do Studio não tem menu de navegação. O cabeçalho mostra só o logo
> "Mnemônicos", que leva à página **pública**, e o controle "Sair". O resto se alcança por
> links soltos dentro das páginas. Consequências hoje:
> * **Biblioteca visual** (`/visual-library`): nenhum link aponta para ela. Só se chega
>   digitando o endereço.
> * **Painel estratégico** (`/studio`): só se chega pelo login, que cai nele. Quem sai do
>   Painel não tem como voltar.
> * **Lista de conteúdos** (`/content`): o Painel não tem link para ela.
> * **Tira mnemônica** (`/content/[id]/tira`): só se chega pela Quebra da regra.
>
> O mockup de gestão previa navegação (Dashboard · Conteúdos · Tiras · Revisão · Biblioteca
> Visual · Exportações · Configurações), mas ela não virou requisito em nenhuma etapa do
> épico MNEMORA Studio.
>
> ## Pedido
> Criar uma **sidebar de navegação** para toda a área interna, montada uma única vez na
> casca da área logada, para que toda página interna ganhe o menu sem exigir alteração em
> cada tela.
>
> ## Itens do menu (primeira versão)
> * **Painel** → `/studio`
> * **Conteúdos** → `/content`, com "Novo conteúdo" (`/content/new`) acessível a partir da lista
> * **Biblioteca visual** → `/visual-library`
>
> As outras seções do mockup (Tiras, Revisão, Exportações, Configurações) ficam fora desta
> história. Hoje elas são seções dentro das páginas de conteúdo, não telas próprias. A
> estrutura deve permitir acrescentar itens depois sem reescrever o menu.
>
> ## Onde está
> * Casca da área interna: `mnemonicos-frontend/src/components/internal-shell.tsx` (sessão,
>   redirecionamento e permissão) e `src/app/(interno)/layout.tsx`.
> * Cabeçalho: `src/components/site-header.tsx` (logo → `/`) e `src/components/site-header-gate.tsx`.
> * Rotas protegidas: `src/proxy.ts` e `src/lib/internal-routes.ts`.
> * Relacionado: o brief avulso **BRIEF-036** (container `max-w-5xl` duplicado entre
>   `InternalShell` e o `<main>` do layout raiz) mexe no mesmo contêiner. Vale resolver
>   junto, porque a sidebar muda o layout da área interna.
>
> ## Critérios de aceite
> * Toda página da área interna (`/studio`, `/content`, `/content/new`, `/content/[id]`,
>   `/content/[id]/breakdown`, `/content/[id]/tira`, `/visual-library`) mostra a sidebar
>   com os 3 itens.
> * O item da seção atual fica destacado (inclusive nas subpáginas: `/content/[id]/tira`
>   destaca "Conteúdos") e marcado para leitor de tela (`aria-current="page"`).
> * A sidebar só aparece com sessão válida. Não aparece nos estados "carregando", "sem
>   sessão" (redireciona ao login) e "sem permissão", nem na página pública e no login.
> * **Celular**: a sidebar vira menu recolhível, aberto por um botão com rótulo acessível.
>   Ela fecha ao escolher um item, com Esc ou ao tocar fora, e não cobre o conteúdo quando
>   fechada.
> * **Teclado**: todos os itens são alcançáveis por Tab, com foco visível. No celular, o
>   foco volta ao botão ao fechar o menu.
> * Para quem está logado, o logo do cabeçalho passa a levar ao **Painel** (`/studio`), e o
>   controle "Sair" continua no lugar. Sem sessão, o logo segue levando à página pública.
> * A Tira mnemônica ganha um caminho de volta ao conteúdo, pela sidebar ("Conteúdos") ou
>   por link na própria página.
> * Visual coerente com a identidade atual (tokens da paleta em `globals.css`), com
>   contraste AA nos temas claro e escuro.
> * O conteúdo das páginas não fica mais estreito do que hoje no desktop, nem com rolagem
>   horizontal no celular.
> * A suíte do frontend passa, com testes para: presença dos 3 itens e destinos, destaque
>   da seção atual (inclusive subpágina), ausência nos estados sem sessão, sem permissão e
>   carregando, abrir e fechar no celular, e o logo por estado de sessão.

## Interpretação do PO
**Contexto**: a área logada não tem menu. Biblioteca visual só abre digitando o endereço,
quem sai do Painel não volta a ele, e a Tira não tem volta ao conteúdo. **Pedido**: um menu
lateral único para toda a área logada, com Painel, Conteúdos e Biblioteca visual, marcando
onde a pessoa está. No celular vira um menu que abre e fecha por botão. Só existe com sessão
válida: nunca na home pública, no login, nem enquanto a sessão carrega ou falta permissão.
Com sessão, o logo leva ao Painel. De quebra, o container duplicado (BRIEF-037) sai, e as
páginas não ficam mais estreitas do que hoje.

## Premissas decididas
- **O card é o contrato de ACs**: os 10 critérios do KAN-178 são a régua da SPEC. O
  "BRIEF-036" citado no card é o **BRIEF-037** (renumeração de 2026-09-30).
- **BRIEF-037 absorvido** (autorização do Diretor em 2026-09-30): largura e padding de
  container aplicados uma vez só na área interna; as rotas públicas (home, login, 404)
  mantêm largura e espaçamento atuais, provados em tela nos dois temas. O BRIEF-037 fecha
  como absorvido por esta SPEC.
- **Logo por sessão**: com sessão, o logo leva a `/studio`; sem sessão, a `/`. O sinal é o
  que o KAN-180 já estabeleceu (pista local `mnemonicos:session-hint`, `homeSessionCheck`/
  leitores de sessão existentes). Nenhuma DEC nova de *como saber que há sessão*; a DEC que
  sobra é qual leitor existente o header consome. Isto **emenda** a premissa do BRIEF-040
  ("logo continua apontando para `/`"), que o próprio BRIEF-040 deixou para o KAN-178.
- **Sidebar só no estado "pronto" da casca**: nunca em carregando, sem sessão ou sem
  permissão, nem fora de `(interno)`. É exibição, não autorização: a guarda segue no
  servidor e no `proxy.ts`, intocados.
- **"Sair" continua só no header**: a sidebar não ganha controle de logout (SPEC-036,
  controle único de logout).
- **Defaults aceitos pelo Diretor**, salvo motivo registrado na SPEC: no desktop a sidebar
  é fixa (não recolhível) e vira menu recolhível abaixo do breakpoint `md`; o menu do
  celular é disclosure não modal; a Tira ganha um link "Voltar ao conteúdo"; nenhum item é
  filtrado por papel.
- **"Novo conteúdo"** continua acessível a partir da lista `/content`, não vira item de menu.
- **Estrutura extensível**: os itens vêm de uma lista declarada, e acrescentar um item não
  reescreve o componente.
- **Gate 9 [assumido pelo Tech Lead]**: não há conta de teste sem o papel exigido. O AC de
  "sem permissão" fica provado por teste automatizado, e a verificação em tela dele fica
  pendente como handoff.

## Fora de escopo
- Itens Tiras, Revisão, Exportações e Configurações do mockup.
- Qualquer mudança em login, logout, guarda de rota (`proxy.ts`, `internal-routes.ts`) ou
  backend.
- Sidebar recolhível no desktop.
- Filtro de itens por papel.
- `/login` com sessão ativa redirecionando à área interna (fora de escopo também no KAN-180).

## Estimativa
Reutilizada do `estimator` rodado nesta sessão (2026-09-30, antes da largada), variante
**absorvendo o BRIEF-037**, que o Diretor autorizou:
- **Dimensão**: ~3 waves · ~7 tasks (~4 small · ~3 medium). W1 em paralelo: componente
  Sidebar (modelo extensível, destaque por prefixo, `aria-current`, foco, tokens AA), logo
  por sessão, volta da Tira e container único. W2: montagem na casca só no estado pronto,
  layout desktop aside + conteúdo, testes de ausência. W3: menu recolhível no celular.
  Pode subir a 7–8 tasks se a W3 for repartida por comportamento.
- **Por fase**: forja 0,25–1h · artefatos 1–2,5h · implementação 3,5–10h · gates 3,5–9,5h.
- **Total**: 8–23h (horas de ciclo, não prazo de calendário).
- **Confiança**: média. A superfície é delimitada e os análogos (PLAN-036, BRIEF-038) são
  próximos, mas interação mobile e a11y já geraram re-gate de design no slug, e o gate 9
  depende de login real.
- **Calibração**: sem base histórica (2 linhas válidas em `estimates.md`, mínimo 3);
  nenhum corretor aplicado.
- **Premissas da estimativa**: KAN-180 mergeado antes da largada (confirmado: PR #23);
  menu mobile disclosure não modal (modal com focus trap → +1 medium); sidebar fixa no
  desktop; gate 10 n/a; gates 9 e 11 cobrindo também as rotas públicas por causa do
  BRIEF-037.

## Cronologia
- Etapa 1 (SPEC) concluída: 2026-09-30T17:43:22-0300 · correções: 1 · classes: termo-fr-fora-glossario(1) · spec-fr-palavras(4) · spec-glossario-nao-usado(4) · spec-nfr-sem-numero(2) · spec-ears-nao-casa(1) · spec-must-ratio(1) · spec-sem-should-may(1) · janelas: redação 1min/363l
