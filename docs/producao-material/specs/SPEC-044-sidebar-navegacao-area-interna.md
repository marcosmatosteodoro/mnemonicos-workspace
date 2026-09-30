# SPEC-044: Sidebar de navegação da área interna

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.2
**Autor**: scribe (por delegação do Tech Lead)
**Data**: 2026-09-30
**Jira**: KAN-178
**Brief**: BRIEF-044

## 1. Contexto e objetivo
### 1.1 Problema
A área interna não tem menu de navegação. O cabeçalho mostra só o logo e o controle de autenticação, e o resto se alcança por links soltos dentro das páginas. Consequências hoje: a Biblioteca visual (`/visual-library`) não tem link apontando para ela (só se chega digitando o endereço); o Painel estratégico (`/studio`) só se alcança pelo login, e quem sai dele não tem como voltar; o Painel não leva à lista de conteúdos (`/content`); a Tira mnemônica (`/content/[id]/tira`) só se alcança pela Quebra da regra e não tem volta ao conteúdo. Além disso, o logo do cabeçalho leva sempre à Home pública, mesmo para quem está logado, e o container de largura da área interna está aplicado em duplicidade (BRIEF-037, absorvido por esta SPEC).

### 1.2 Outcome esperado
Quem está logado alcança Painel, Conteúdos e Biblioteca visual a partir de qualquer página interna, sabe em qual seção está, e volta ao Painel pelo logo. No celular o menu ocupa espaço só quando aberto. A sidebar nunca aparece fora do estado pronto da área interna. O container de largura passa a ser aplicado uma vez só, sem alterar as páginas públicas, e o conteúdo interno nunca fica mais estreito que hoje em nenhuma largura de tela.

### 1.3 Métrica de sucesso
Toda rota interna do escopo (Painel, Conteúdos e Biblioteca visual) é alcançável em no máximo 2 interações (cliques ou toques) a partir de qualquer outra página interna, e a Biblioteca visual é alcançável sem digitar endereço — verificado no ciclo de entrega, por testes automatizados e caminhada em tela do gate 9 (desktop e celular). Não-regressão: 0 falhas nas suítes da SPEC-040 e da SPEC-036 com as emendas aplicadas, e largura útil do conteúdo interno ≥ a medida antes da mudança nas 5 larguras de referência (360, 768, 1024, 1280 e 1440px).
**Fonte de medição**: externa — testes automatizados da suíte do frontend + caminhada em tela do gate 9 (dono: Tech Lead); sem instrumentação nova.

## 2. Personas e jobs-to-be-done
- **Pessoa da produção logada (qualquer papel com acesso à área interna)**: "quando estou numa página interna, quero ir a outra seção e saber onde estou, sem digitar endereço nem voltar pelo login".
- **Pessoa da produção no celular**: "quero o menu à mão sem que ele ocupe a tela enquanto leio ou edito".
- **Anti-persona**: visitante sem sessão — a sidebar não é para ele (a Home pública e o login não a mostram).

## 3. Glossário (Ubiquitous Language)
| Termo | Definição |
|-------|-----------|
| área interna | Conjunto de rotas protegidas do Studio (grupo de rotas interno): `/studio`, `/content`, `/content/new`, `/content/[id]`, `/content/[id]/breakdown`, `/content/[id]/tira`, `/visual-library` |
| Casca da área interna | Componente que envolve toda página interna e resolve os estados de sessão e permissão (SPEC-002) |
| Estado pronto (da casca) | Sessão ativa e papel suficiente: a vista é renderizada. Os demais estados são carregando, sem sessão (redireciona ao login) e sem permissão |
| Sidebar | Menu lateral de navegação da área interna, com os itens Painel (`/studio`), Conteúdos (`/content`) e Biblioteca visual (`/visual-library`), nessa ordem |
| Item de menu | Entrada da sidebar, definida por rótulo e destino numa lista declarada |
| Conteúdos (item) | Item da sidebar que leva à mesma lista (`/content`) que o link "Conteúdos brutos" das páginas; os dois rótulos coexistem e renomear é fora de escopo |
| Seção atual | Item de menu cujo destino é a rota aberta ou prefixo dela em fronteira de segmento; `/content/new`, `/content/[id]`, `/content/[id]/breakdown` e `/content/[id]/tira` pertencem a Conteúdos |
| Controle de autenticação (do header) | Botão do header que alterna "Entrar"/"Sair"; único ponto de logout do app (SPEC-036) |
| Logo do header | Logo do cabeçalho do app, link cujo destino é `/studio` ou `/` conforme as regras desta SPEC |
| Home pública | Página inicial em `/` (termo do INDEX, SPEC-019/SPEC-040): destino fixo do link da 404, e do logo quando não há sessão ativa com papel com acesso à área interna |
| Páginas públicas | Home pública, login e página 404 |
| Sessão ativa | Sessão que o sistema aceita agora (SPEC-036); a sessão só renovável não é ativa |
| Papel com acesso à área interna | Papel que a guarda de rotas internas admite: EDITOR e ADMIN (SPEC-040) |
| Breakpoint da sidebar fixa | Menor largura de viewport em que a sidebar fixa cabe sem estreitar a largura útil do conteúdo abaixo da de antes desta entrega; medido e fixado pelo PLAN (esperado ~1280px) |
| Menu recolhível | Forma da sidebar abaixo do breakpoint da sidebar fixa: fechada por padrão, aberta por botão; disclosure não modal |
| Container de largura | Envoltório que limita a largura máxima e define o espaçamento lateral do conteúdo da página |
| Volta ao conteúdo | Link "Voltar ao conteúdo" na página da Tira mnemônica, que leva à página do conteúdo (`/content/[id]`) |

## 4. Escopo
### 4.1 In-scope
- Sidebar com os itens Painel, Conteúdos e Biblioteca visual, montada uma vez na casca, só no estado pronto.
- Lista declarada e extensível de itens.
- Destaque da seção atual, inclusive em subpáginas, com `aria-current="page"`.
- Menu recolhível abaixo do breakpoint da sidebar fixa (abrir por botão; fechar ao escolher item, Esc, toque fora ou mudança de rota; foco volta ao botão).
- Logo do header por sessão: vai a `/studio` só com sessão ativa e papel com acesso à área interna; em qualquer outro caso vai a `/`. Emenda a SPEC-040 (ver A-044-002).
- Volta ao conteúdo na Tira, ao lado do link existente "Conteúdos brutos".
- Container de largura único na área interna (BRIEF-037 absorvido), com páginas públicas sem regressão e largura útil do conteúdo nunca menor que a de antes.
- Transição ao deixar o estado pronto durante o uso: sidebar e botão somem.
- Contraste AA nos dois temas e foco visível.

### 4.2 Out-of-scope
- Itens Tiras, Revisão, Exportações e Configurações do mockup (hoje são seções dentro das páginas de conteúdo). Quem esperava "Tiras" como item: fora.
- "Novo conteúdo" como item de menu: continua acessível pela lista `/content`.
- Renomear "Conteúdos brutos" nas páginas ou o item "Conteúdos" da sidebar: fora; os dois rótulos levam à mesma lista.
- Logout na sidebar: "Sair" continua só no header (SPEC-036).
- Qualquer mudança em login, logout, guarda de rota, autorização ou backend; a sidebar é exibição, não autorização.
- Nova decisão de como saber que há sessão: reutiliza-se o sinal do KAN-180.
- Sidebar recolhível em largura de sidebar fixa.
- Filtro de itens por papel (ver RISK-044-005).
- `/login` com sessão ativa redirecionando à área interna (também fora no KAN-180).
- Sidebar nas páginas públicas.

## 5. Requisitos funcionais (EARS)
- **FR-044-001** [MUST] Enquanto a casca da área interna está no estado pronto, o sistema deve exibir a sidebar em toda página da área interna.
- **FR-044-002** [MUST] O sistema deve obter os itens da sidebar de uma lista declarada de rótulo e destino, de modo que acrescentar um item não exija reescrever o componente da sidebar.
- **FR-044-003** [MUST] Enquanto uma página interna está aberta, o sistema deve destacar o item de menu da seção atual e marcá-lo com `aria-current="page"`.
- **FR-044-004** [SHOULD] Se a rota aberta não pertence a nenhum item de menu, então o sistema deve exibir a sidebar sem item destacado nem `aria-current`.
- **FR-044-005** [MUST] Se a casca está nos estados carregando, sem sessão ou sem permissão, então o sistema não deve exibir a sidebar nem o botão do menu recolhível.
- **FR-044-006** [MUST] O sistema não deve exibir a sidebar nas páginas públicas.
- **FR-044-007** [MUST] Enquanto a largura da viewport está no breakpoint da sidebar fixa ou acima, o sistema deve exibir a sidebar fixa ao lado do conteúdo, sem controle de recolher.
- **FR-044-008** [MUST] Enquanto a largura está abaixo do breakpoint da sidebar fixa e a casca está no estado pronto, o sistema deve exibir um botão com rótulo acessível que abre e fecha o menu recolhível, anunciando expandido ou recolhido.
  Nota: a ação é local e instantânea; não há estado "em andamento" nem falha, e o estado de sucesso é o menu aberto ou fechado, visível.
- **FR-044-009** [MUST] Quando o menu recolhível aberto recebe a escolha de um item, a tecla Esc ou um toque fora dele, o sistema deve fechá-lo e devolver o foco ao botão do menu.
- **FR-044-010** [MUST] Enquanto o menu recolhível está fechado, o sistema não deve deixá-lo cobrir nem empurrar o conteúdo, nem expor seus itens à navegação por teclado.
- **FR-044-011** [MUST] O sistema deve tornar todos os itens da sidebar alcançáveis por Tab, em ordem, com indicador de foco visível.
- **FR-044-012** [MUST] Enquanto há sessão ativa com papel com acesso à área interna, o sistema deve apontar o logo do header para `/studio`; em qualquer outro caso, para `/`.
- **FR-044-013** [MUST] Enquanto a sessão ainda está sendo conferida (estado indeterminado), o sistema deve manter o logo do header apontando para `/`.
- **FR-044-014** [MUST] O sistema deve manter o logout apenas no controle de autenticação do header, sem controle de logout na sidebar.
- **FR-044-015** [MUST] Enquanto a página da Tira mnemônica está aberta, o sistema deve exibir a Volta ao conteúdo ao lado do link existente "Conteúdos brutos", que permanece apontando para `/content`.
- **FR-044-016** [MUST] O sistema deve manter "Novo conteúdo" (`/content/new`) acessível a partir da lista `/content`, sem ser item de menu.
- **FR-044-017** [MUST] O sistema deve aplicar o container de largura uma única vez na área interna, sem duplicidade entre a casca e o enquadramento comum do app.
- **FR-044-018** [MUST] O sistema deve manter as páginas públicas com a mesma largura e o mesmo espaçamento de antes desta entrega, nos dois temas.
- **FR-044-019** [MUST] O sistema deve exibir o conteúdo das páginas internas com largura útil maior ou igual à de antes desta entrega, em toda largura de tela.
- **FR-044-020** [MUST] Quando o logo do header é acionado numa aba cuja sessão foi encerrada em outra aba, o sistema deve levar à Home pública, sem tela de login e sem aviso de sessão expirada.
- **FR-044-021** [MUST] Quando a rota muda com o menu recolhível aberto, por qualquer meio, o sistema deve fechá-lo.
- **FR-044-022** [SHOULD] Quando a largura da viewport cruza o breakpoint da sidebar fixa com o menu recolhível aberto, o sistema deve deixá-lo fechado, com o botão anunciando recolhido.
- **FR-044-023** [MUST] Quando a casca deixa o estado pronto durante o uso, o sistema deve remover a sidebar e o botão do menu, inclusive com o menu aberto, e seguir ao login como hoje.
- **FR-044-024** [MUST] Enquanto o botão do menu recolhível está presente, o sistema deve manter o header sem rolagem horizontal a 360px, como em AC-036-019.
- **FR-044-025** [MUST] O sistema não deve apontar o logo do header para `/studio` enquanto o controle de autenticação do header mostra "Entrar" ou o estado neutro.
- **FR-044-026** [MUST] O sistema deve preservar os links soltos existentes entre páginas internas: Painel para Novo conteúdo, lista para Quebra, Quebra para Tira e Biblioteca para conteúdo.
- **FR-044-027** [MUST] O sistema deve exibir o conteúdo das páginas internas sem rolagem horizontal a 360px.

## 6. Requisitos não-funcionais
- **NFR-044-001** [MUST] A sidebar, o botão do menu, o destaque da seção atual e o foco visível devem atender contraste AA (texto 4,5:1; componentes de interface 3:1) nos temas claro e escuro, usando os tokens da paleta atual do app, com 0 cores fora dela.
- **NFR-044-002** [MUST] A sidebar é exibição, não autorização: nenhuma rota nem dado passa a ser acessível ou negado por causa dela; guarda de rota, autorização no servidor e backend permanecem inalterados, com 0 conferências ou renovações de sessão e 0 chamadas novas ao backend originadas pela sidebar ou pela resolução do destino do logo (não-regressão de AC-040-020).
- **NFR-044-003** [SHOULD] A sidebar deve ser navegável por tecnologia assistiva, com 1 região de navegação com rótulo e 100% dos itens como links.
- **NFR-044-004** [MUST] As suítes de comportamento da SPEC-040 e da SPEC-036, com as emendas desta SPEC aplicadas, devem passar com 0 falhas.

## 7. Critérios de aceitação (Given-When-Then)
- **AC-044-001** (cobre FR-044-001, FR-044-002)
  Dado um usuário com sessão ativa e papel suficiente, quando abre qualquer página da área interna (`/studio`, `/content`, `/content/new`, `/content/[id]`, `/content/[id]/breakdown`, `/content/[id]/tira`, `/visual-library`), então a sidebar mostra Painel, Conteúdos e Biblioteca visual, nessa ordem, com os destinos `/studio`, `/content` e `/visual-library`; e uma lista de itens com um item a mais resulta em mais um link na sidebar sem alterar o componente.
- **AC-044-002** (cobre FR-044-003)
  Dado um usuário na página `/content/[id]/tira`, quando a sidebar é exibida, então o item "Conteúdos" está destacado e tem `aria-current="page"`, e os demais itens não têm; o mesmo vale para `/content/new`, `/content/[id]` e `/content/[id]/breakdown`, e em `/studio` e `/visual-library` destaca-se Painel e Biblioteca visual, respectivamente.
- **AC-044-003** (cobre FR-044-004)
  Dado um usuário pronto numa rota interna que não casa com nenhum item da lista, quando a sidebar é exibida, então nenhum item está destacado nem com `aria-current`.
- **AC-044-004** (cobre FR-044-005)
  Dado uma casca no estado carregando, quando a página interna é aberta, então nem a sidebar nem o botão do menu aparecem.
- **AC-044-005** (cobre FR-044-005)
  Dado um visitante sem sessão, quando abre uma rota interna, então é redirecionado ao login e a sidebar nunca é exibida.
- **AC-044-006** (cobre FR-044-005, NFR-044-002)
  Dado um usuário com sessão ativa mas sem o papel exigido pela rota, quando abre a página, então a mensagem "sem permissão" é exibida sem o conteúdo da vista, sem a sidebar e sem o botão do menu, e a sidebar não altera o resultado da autorização.
- **AC-044-007** (cobre FR-044-006)
  Dado qualquer visitante ou usuário, quando abre a Home pública, o login ou a página 404 da raiz, então a sidebar e o botão do menu não aparecem.
- **AC-044-008** (cobre FR-044-007)
  Dado um usuário pronto numa viewport no breakpoint da sidebar fixa ou acima, quando abre uma página interna, então a sidebar está visível e fixa ao lado do conteúdo e não existe controle para recolhê-la.
- **AC-044-009** (cobre FR-044-008)
  Dado um usuário pronto numa viewport abaixo do breakpoint da sidebar fixa, quando abre uma página interna, então o menu está fechado e há um botão com rótulo acessível que anuncia "recolhido"; quando aciona o botão, então o menu abre e o botão anuncia "expandido".
- **AC-044-010** (cobre FR-044-009)
  Dado o menu recolhível aberto, quando o usuário escolhe um item, pressiona Esc ou toca fora do menu, então o menu fecha e o foco volta ao botão do menu.
- **AC-044-011** (cobre FR-044-010)
  Dado o menu recolhível fechado numa viewport abaixo do breakpoint da sidebar fixa, quando a página é exibida, então o conteúdo ocupa a largura disponível sem ser coberto nem empurrado, e os itens do menu não recebem foco por Tab.
- **AC-044-012** (cobre FR-044-011, NFR-044-001)
  Dado um usuário pronto navegando por teclado, quando pressiona Tab, então todos os itens da sidebar são alcançados em ordem, cada um com indicador de foco visível e contraste AA nos temas claro e escuro.
- **AC-044-013** (cobre FR-044-012, FR-044-013)
  Dado um usuário com sessão ativa e papel com acesso à área interna, quando o logo do header é acionado, então a navegação vai a `/studio`; e dado um visitante sem sessão, um usuário com papel sem acesso à área interna (STUDENT), uma conferência em andamento, uma conferência que falhou ou uma sessão só renovável, quando aciona o logo, então vai a `/`.
- **AC-044-014** (cobre FR-044-013)
  Dado a sessão ainda em conferência, quando o header é exibido, então o logo aponta para `/` e não para `/studio`; quando a conferência confirma sessão ativa com papel com acesso, então o logo passa a apontar para `/studio`.
- **AC-044-015** (cobre FR-044-014)
  Dado um usuário pronto, quando a sidebar é exibida, então ela não contém controle "Sair" e o controle "Sair" permanece no header.
- **AC-044-016** (cobre FR-044-015)
  Dado um usuário pronto na página `/content/[id]/tira`, quando a página é exibida, então há o link "Conteúdos brutos" para `/content` e o link "Voltar ao conteúdo" ao lado dele; e quando aciona "Voltar ao conteúdo", então a navegação vai a `/content/[id]` do mesmo conteúdo.
- **AC-044-017** (cobre FR-044-016)
  Dado um usuário pronto na lista `/content`, quando procura criar conteúdo, então a lista oferece o acesso a "Novo conteúdo" (`/content/new`), e a sidebar não o lista como item.
- **AC-044-018** (cobre FR-044-017, FR-044-019, FR-044-027)
  Dado qualquer página interna no estado pronto, quando o layout é renderizado nas larguras de referência 360, 768, 1024, 1280 e 1440px, então há um único container de largura, a largura útil do conteúdo em cada largura não é menor que a medida antes da mudança (container ainda duplicado; ~928px a partir de 1024px), e a 360px não há rolagem horizontal.
- **AC-044-019** (cobre FR-044-018)
  Dado a Home pública, o login e a página 404, quando renderizados nos temas claro e escuro, então largura e espaçamento do conteúdo são iguais aos de antes desta entrega, comprovados em tela.
- **AC-044-020** (cobre FR-044-020)
  Dado uma pessoa com a área interna aberta na aba A que fez logout na aba B, quando aciona o logo do header na aba A, então vai à Home pública, sem tela de login e sem aviso de sessão expirada (preserva AC-040-018).
- **AC-044-021** (cobre FR-044-021)
  Dado o menu recolhível aberto, quando a rota muda por voltar, avançar ou link na página, então o menu fecha.
- **AC-044-022** (cobre FR-044-022)
  Dado o menu recolhível aberto, quando a largura da viewport cruza o breakpoint da sidebar fixa, então o menu fica fechado e, ao voltar abaixo do breakpoint, o botão anuncia "recolhido".
- **AC-044-023** (cobre FR-044-023)
  Dado um usuário pronto, inclusive com o menu recolhível aberto, quando a sessão cai durante o uso, então a sidebar e o botão do menu somem e a pessoa segue ao login como hoje.
- **AC-044-024** (cobre FR-044-024)
  Dado o header a 360px com o botão do menu presente, os controles de sessão e tema e, em dev, o `ApiStatus`, quando a página é inspecionada, então AC-036-019 continua valendo: sem rolagem horizontal.
- **AC-044-025** (cobre FR-044-025)
  Dado qualquer estado da sessão, quando o header é exibido, então o logo nunca aponta para `/studio` enquanto o controle de autenticação do header mostra "Entrar" ou o estado neutro; e dado sessão só renovável na 404 ou no login, então o logo aponta para `/`, e a conferência da SPEC-040 leva à área interna quando há pista de sessão.
- **AC-044-026** (cobre FR-044-026, NFR-044-004)
  Dado as páginas internas, quando se percorrem Painel para Novo conteúdo, lista para Quebra, Quebra para Tira e Biblioteca para conteúdo, então os links continuam presentes e levam aos mesmos destinos de antes, e as suítes da SPEC-040 e da SPEC-036 passam com as emendas aplicadas.

## 8. Premissas e decisões prévias
- **A-044-001** [assumido] [evidência: anedota] O card KAN-178 é o contrato de ACs, e o "BRIEF-036" citado nele é o BRIEF-037 (renumeração de 2026-09-30). Fonte: BRIEF-044.
- **A-044-002** [assumido] [evidência: anedota] **Emenda à SPEC-040**: o card KAN-178, o BRIEF-040 (linha 75) e a SPEC-040 §4.2 adiaram o logo por sessão a este card. Esta SPEC emenda, da SPEC-040: FR-040-009 e AC-040-010 (passam a cobrir só o link de volta da 404, fixo em `/`), §4.1 e §4.2 (linhas sobre o logo), A-040-008 e A-040-012, e o termo do INDEX "Home pública" ("destino fixo do link da 404, e do logo quando não há sessão ativa com papel com acesso à área interna"). AC-040-018 e AC-040-020 continuam valendo (AC-044-020, NFR-044-002). O sinal de sessão é o do KAN-180; qual leitor o header consome é decisão do PLAN. Fonte: veredito do PO em nome do Diretor.
- **A-044-003** [assumido] [evidência: crença] Em sessão indeterminada (em conferência), o logo mantém o destino `/`: nunca leva à área interna sem sessão ativa, e a área interna, se a pessoa tiver sessão, segue acessível pelo login/redirecionamento já existente. Risco: por um instante, pessoa logada vê logo para `/` (com SPEC-040, a Home pública reconhece a sessão e abre a área logada).
- **A-044-004** [assumido] [evidência: anedota] BRIEF-037 absorvido por autorização do Diretor em 2026-09-30: container aplicado uma vez só na área interna; o BRIEF-037 fecha como absorvido.
- **A-044-005** [assumido] [evidência: anedota] Defaults aceitos pelo Diretor: sidebar fixa no desktop; menu recolhível como disclosure não modal; Volta ao conteúdo na Tira com destino `/content/[id]`; nenhum item filtrado por papel. (O breakpoint do default, `md`, foi substituído: A-044-008.)
- **A-044-006** [assumido] [evidência: medido] O schema só tem o papel STUDENT como default e não há seed de conta sem o papel exigido pela área interna. O AC-044-006 ("sem permissão") é provado por teste automatizado; a prova em tela depende de conta (A-044-010).
- **A-044-007** [assumido] [evidência: crença] Seção atual por prefixo de rota: a rota pertence ao item cujo destino é igual à rota ou prefixo dela em fronteira de segmento; rota sem item correspondente fica sem destaque.
- **A-044-008** [assumido] [evidência: anedota] Decisão do PO em nome do Diretor, com motivo: o card promete largura, então (a) a largura útil do conteúdo interno é ≥ a de hoje em toda largura de tela (base medida antes da mudança, container ainda duplicado; ~928px a partir de 1024px); (b) larguras de referência 360, 768, 1024, 1280 e 1440px; (c) a sidebar é fixa só a partir do breakpoint da sidebar fixa, abaixo do qual há menu recolhível (fechado não cobre nem empurra); o PLAN mede e fixa o breakpoint (esperado ~1280px); (d) sem rolagem horizontal a 360px. Substitui o default `md` do Diretor, aceito "salvo motivo registrado na SPEC".
- **A-044-009** [assumido] [evidência: anedota] As duas faces da 404: erro de conteúdo inexistente dentro da área interna mostra a sidebar (estado pronto); a 404 da raiz não tem sidebar e volta pelo logo (regra de sessão, FR-044-012) ou pelo link da 404 (fixo em `/`).
- **A-044-010** [assumido] [evidência: crença] Suposição do Tech Lead, vetável pelo Diretor: não existe conta nenhuma sem o papel exigido, então a verificação em tela do estado "sem permissão" fica pendente como handoff. Se o Diretor indicar que há tal conta, a prova em tela entra no gate 9.

## 9. Riscos e questões abertas
- **RISK-044-001** Interação mobile e acessibilidade já geraram re-gate de design neste slug; o disclosure não modal exige cuidado com foco e Esc. Mitigação: ACs 009–012, AC-044-021, AC-044-022 e gate 11.
- **RISK-044-002** Mexer no container afeta as páginas públicas (BRIEF-037). Mitigação: AC-044-019 provado em tela nos dois temas.
- **RISK-044-003** O gate 9 do estado "sem permissão" depende de conta sem o papel; sem ela a prova em tela fica em handoff (A-044-006, A-044-010).
- **RISK-044-004** Pessoa logada com conferência de sessão falha vê o logo apontar para `/` (A-044-003); recuperação pelo login ou pela Home pública.
- **RISK-044-005** Sem filtro por papel, a exposição é nula hoje (todo item é aberto ao papel com acesso à área interna); o primeiro item de menu cuja rota exija papel mais restrito que o da área interna reabre o filtro por papel, hoje fora de escopo.
- **RISK-044-006** O breakpoint da sidebar fixa (~1280px esperado) é medido pelo PLAN; se a medição divergir muito, a fração de telas com menu recolhível muda. Mitigação: A-044-008 e AC-044-018 nas 5 larguras de referência.

## 10. Fora deste documento
Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
