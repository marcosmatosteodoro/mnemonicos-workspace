# SPEC-034: Botão de sessão e tema dark/light no header do app

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.3
**Autor**: scribe
**Data**: 2026-09-29
**Jira Story**: KAN-77
**Brief**: BRIEF-034

## 1. Contexto e objetivo

### 1.1 Problema
Hoje o header (`SiteHeader`) só mostra logo e, fora de produção, um indicador de status de
API (`ApiStatus`, KAN-71 já o escondeu em produção). Não existe nenhum controle visível de
sessão no header — o usuário não tem como saber, olhando o topo da tela, se está
autenticado, nem como sair sem procurar uma ação em outro lugar. Tema visual também não
tem nenhum mecanismo de escolha do usuário: é 100% `prefers-color-scheme` do dispositivo,
sem override manual nem persistência. A paleta noturna em tons de roxo/rosa/mauve, com
contraste AA já medido, existe hoje só em `/login` (SPEC-030/PLAN-031) — o resto do app usa
uma paleta diferente nos dois temas.

### 1.2 Outcome esperado
O header passa a exibir, na mesma área hoje ocupada pelo indicador de API, dois controles
sempre visíveis (inclusive em produção): um controle de autenticação que reflete o estado
de sessão corrente ("Entrar" sem sessão, "Sair" com sessão, reaproveitando o comportamento
de login/logout já existente) e um alternador de tema claro/escuro. O tema por padrão segue
a preferência do dispositivo até o usuário escolher manualmente; a partir da escolha, ela
persiste e prevalece sobre o dispositivo em navegações e recargas seguintes. Os dois temas
do aplicativo inteiro (fora de `/login`) passam a usar a mesma família de cores e o mesmo
piso de contraste AA já validado no login, sem a ilustração decorativa daquela tela.

### 1.3 Métrica de sucesso
Sem meta de negócio numérica — o card (KAN-77) não define uma. A régua de sucesso é
conformidade comportamental e visual: todos os critérios de aceitação desta SPEC verificados
por teste automatizado (gate 1) e por execução real do app nos dois temas, em múltiplas
rotas (gate 9); a paleta aplicada e o contraste AA aprovados pelo gate 11 (design). `Reabrir
se:` o Diretor quiser associar esta entrega a uma métrica de produto no futuro (ex.: adoção
da troca manual de tema).

**Juiz do outcome estético**: como em SPEC-030 §1.3, a conformidade visual da paleta
unificada e dos dois controles novos também passa por aceite binário do Diretor sobre um
conjunto de capturas de tela — no mínimo 1 rota pública, 1 rota interna e a home, em tema
claro e em tema escuro cada — anexadas ao relatório de Entrega. Este juízo não bloqueia o
ciclo.

**Fonte de medição**: — (não aplicável; critério é conformidade verificada por gate, não
instrumentação de evento)

## 2. Personas e jobs-to-be-done
- **Colaborador interno autenticado** (papel EDITOR ou ADMIN), em qualquer tela do app:
  "quero ver meu estado de sessão de relance e poder sair em um clique, de qualquer lugar,
  sem procurar uma tela dedicada de logout."
- **Visitante sem sessão ativa**, em qualquer rota pública ou ao tentar acessar uma rota
  interna: "quero um caminho visível e direto para entrar, sem procurar o link."
- **Qualquer usuário do app**, em sessão prolongada de uso (turno noturno ou diurno):
  "quero escolher o tema claro ou escuro conforme meu ambiente, e que o app lembre da minha
  escolha nas próximas visitas, sem eu ter que refazê-la."

Para quem isto **não** é: consumidores diretos da API/integrações (não há interface) e o
papel STUDENT dormente sem acesso à área interna — os dois controles vivem na interface
visual do app, não no contrato HTTP.

## 3. Glossário (Ubiquitous Language)

| Termo | Definição | Origem |
|-------|-----------|--------|
| Controle de autenticação (do header) | Botão sempre visível no header que alterna entre "Entrar" (sem sessão) e "Sair" (com sessão), consumindo o estado de sessão já existente — não redefine login/logout | BRIEF-034 |
| Alternador de tema | Controle sempre visível no header que permite ao usuário trocar manualmente entre tema claro e escuro | BRIEF-034 |
| Escolha de tema salva | Preferência de tema definida manualmente pelo usuário, que passa a prevalecer sobre a preferência de esquema de cores do dispositivo nas visitas seguintes | BRIEF-034 |
| Preferência de esquema de cores do dispositivo | Sinal do sistema operacional/navegador indicando se o ambiente do usuário está configurado para tema claro ou escuro (equivalente a `prefers-color-scheme`) | BRIEF-034 |
| Paleta unificada (do app) | Família de cores (tons de roxo/rosa/mauve) e piso de contraste AA já validados em `/login` (SPEC-030), estendidos aos dois temas do restante do aplicativo, sem a ilustração decorativa daquela tela | BRIEF-034 |
| Sessão autenticada | Vínculo entre uma requisição e uma conta interna ativa, estabelecido por login e válido enquanto não expira nem é revogado | SPEC-002 |

## 4. Escopo

### 4.1 In-scope
- Controle de autenticação no header, refletindo o estado de sessão corrente ("Entrar" /
  "Sair"), reutilizando o comportamento de login/logout já existente (SPEC-002/SPEC-016).
- Alternador de tema claro/escuro no header, com troca síncrona e imediata.
- Default do tema: segue a preferência de esquema de cores do dispositivo até haver escolha
  manual salva; sem preferência detectável, o default é o tema claro.
- Persistência observável da escolha manual de tema: sobrevive a reload e a navegação entre
  rotas, e prevalece sobre a preferência do dispositivo a partir da escolha.
- Paleta unificada: os dois temas do app inteiro, fora de `/login`, passam a usar a mesma
  família de cores (roxo/rosa/mauve) e o mesmo piso de contraste AA (4,5:1 texto, 3:1
  borda/ícone) já validados em `/login`, sem a ilustração decorativa daquela tela.
- Presença dos dois controles novos em toda rota em que o header aparece hoje, incluindo
  ambiente de produção.
- A escolha manual de tema é por navegador/dispositivo, independente de sessão ou conta —
  sobrevive a login e a logout.

### 4.2 Out-of-scope
- Qualquer mudança ao comportamento/lógica de login ou logout em si (fluxo, validação,
  mensagens, estados observáveis, endpoint, mutation, expiração de sessão) — já coberto e
  provado por SPEC-002/SPEC-016; esta SPEC apenas consome o estado de sessão existente.
  Relocar o único ponto de acionamento visível do logout, retirando o controle duplicado da
  área interna (FR-034-014), está dentro do escopo — o que fica fora é o mecanismo de
  logout em si. Vizinho simétrico do controle de autenticação in-scope.
- Mecanismo técnico exato de persistência da escolha de tema (ex.: `localStorage`, cookie
  lido no servidor) — decisão técnica da fase de `/keelson:plan`. Vizinho simétrico da
  persistência observável in-scope.
- Mapeamento de qual token de paleta (`--color-night-*` ou extensão) cobre qual papel de UI
  (fundo, texto, borda, superfície de card) nos dois temas — decisão técnica da fase de
  `/keelson:plan`. Vizinho simétrico da paleta unificada in-scope.
- Forma visual exata dos dois controles (ícone, texto ou combinação) — decisão de
  design/PLAN; esta SPEC só exige o comportamento e o rótulo acessível observáveis.
- Reprodução da ilustração decorativa de `/login` (dunas, lua, estrelas, céu em degradê)
  fora daquela tela — o restante do app permanece com layout simples, sem elemento gráfico
  extra. Vizinho simétrico da paleta unificada in-scope.
- Qualquer alteração ao desenho já entregue da tela `/login` (SPEC-030/PLAN-031): o header
  não é exibido ali, então ela não recebe os dois controles novos e mantém a composição
  própria já aprovada.
- Remoção ou alteração do indicador de status de API (`ApiStatus`, dev-only, KAN-71) — ele
  convive com os dois controles novos, sem mudança.
- Métrica de produto numérica de adoção/uso dos controles — o card não define nenhuma.

## 5. Requisitos funcionais (EARS)

### FEAT-034-001: Controle de sessão no header

**Jira**: KAN-77

> Do ponto de vista do QA: um visitante sem sessão vê "Entrar" e, ao clicar, é levado à
> tela de entrada; um colaborador autenticado vê "Sair" e, ao clicar, dispara o logout já
> existente — em qualquer rota onde o header apareça.

- **FR-034-001** [MUST] Enquanto o usuário não tiver sessão ativa, o sistema deve exibir,
  na área do header reservada aos controles de sessão e tema, um controle de autenticação
  rotulado "Entrar".
- **FR-034-002** [MUST] Enquanto o usuário tiver sessão ativa, o sistema deve exibir, no
  mesmo local, um controle de autenticação rotulado "Sair".
- **FR-034-003** [MUST] Quando o usuário aciona o controle de autenticação estando sem
  sessão ativa, o sistema deve levá-lo imediatamente à tela de entrada existente — ação de
  navegação simples, sem estado de carregamento assíncrono próprio (o carregamento
  observável, se houver, é o da própria tela de destino).
- **FR-034-004** [MUST] Quando o usuário aciona o controle de autenticação estando com
  sessão ativa, o sistema deve disparar a ação de logout já existente, herdando os três
  estados observáveis já definidos para ela (em andamento, sucesso, falha — SPEC-002/
  SPEC-016). Este controle é o único ponto de acionamento de logout do aplicativo — a área
  interna não mantém um controle de logout próprio e separado.
- **FR-034-005** [MUST] O sistema deve exibir o controle de autenticação em toda rota em
  que o header do aplicativo é exibido hoje, incluindo ambiente de produção.
- **FR-034-006** [MUST] Se o controle de autenticação for acionado sem sessão ativa, então
  o sistema deve tratá-lo exclusivamente como navegação para a tela de entrada — nunca
  disparando a ação de logout a partir desse acionamento.
- **FR-034-014** [MUST] Quando a área interna (rotas que hoje usam o shell protegido) é
  exibida com sessão ativa, o sistema deve exibir um único controle de logout — o do header
  — sem um segundo controle de logout dedicado à área interna.
- **FR-034-015** [MUST] O sistema deve verificar a ausência de sessão ativa para fins de
  rotulagem do controle de autenticação sem nenhum efeito colateral visível ao visitante —
  nem redirecionamento, nem aviso de sessão expirada, nem qualquer navegação forçada.
- **FR-034-016** [MUST] Enquanto o sistema ainda está resolvendo se há sessão ativa, o
  controle de autenticação deve exibir um estado neutro, distinto de "Entrar" e de "Sair",
  sem acionar nenhuma ação até a resolução terminar.

### FEAT-034-002: Tema dark/light com paleta unificada

**Jira**: KAN-77

> Do ponto de vista do QA: sem escolha salva, o tema segue o dispositivo (ou cai em claro,
> sem preferência detectável); ao clicar no alternador, o tema muda na hora; a escolha
> sobrevive a reload e navegação; em qualquer tema, fora de `/login`, as cores vêm da
> mesma família roxo/rosa/mauve do login, com o mesmo contraste AA, sem a ilustração.

- **FR-034-007** [MUST] Quando o usuário não tiver uma escolha de tema salva, o sistema
  deve aplicar o tema conforme a preferência de esquema de cores do dispositivo.
- **FR-034-008** [MUST] Se o dispositivo não expuser nenhuma preferência de esquema de
  cores detectável e não houver escolha de tema salva, então o sistema deve aplicar o tema
  claro como default.
- **FR-034-009** [MUST] O sistema deve exibir, no header, um alternador de tema com dois
  estados observáveis (claro / escuro), presente em toda rota em que o header aparece
  hoje, incluindo ambiente de produção.
- **FR-034-010** [MUST] Quando o usuário aciona o alternador de tema, o sistema deve trocar
  o tema aplicado de forma síncrona e imediata, refletindo visualmente qual dos dois temas
  está ativo — esta ação não tem estado "em andamento" observável (troca local, sem espera
  perceptível).
- **FR-034-011** [MUST] Quando o usuário escolhe um tema manualmente pelo alternador, o
  sistema deve reter essa escolha, de forma que ela prevaleça sobre a preferência de
  esquema de cores do dispositivo a partir de então.
- **FR-034-012** [MUST] Quando o usuário recarrega a página ou navega para outra rota após
  ter escolhido um tema manualmente, o sistema deve aplicar o tema salvo dessa escolha — e
  não a preferência do dispositivo, mesmo que ela seja diferente.
- **FR-034-013** [MUST] Enquanto o app exibe qualquer rota fora de `/login`, em qualquer um
  dos dois temas, o sistema deve usar a mesma família de cores (tons de roxo/rosa/mauve)
  introduzida no redesenho de `/login`, com o mesmo piso de contraste mínimo AA (4,5:1
  texto, 3:1 borda/ícone) já validado ali, sem incluir a ilustração decorativa daquela
  tela.

## 6. Requisitos não-funcionais
- **NFR-034-001** [MUST] O alternador de tema deve expor um rótulo acessível que reflita a
  ação disponível no estado atual (ex.: indicar para qual tema a ativação leva).
- **NFR-034-002** [MUST] O controle de autenticação deve expor um rótulo acessível
  coerente com seu estado atual ("Entrar" / "Sair").
- **NFR-034-003** [MUST] Em ambos os temas, em qualquer rota fora de `/login`, o contraste
  entre texto e fundo deve ser de no mínimo 4,5:1, e entre borda/ícone e fundo adjacente de
  no mínimo 3:1 — o mesmo piso já validado na paleta de origem.
- **NFR-034-004** [SHOULD] A aplicação do tema (default ou salvo) SHOULD ocorrer sem uma
  troca visível de cor perceptível ao usuário depois da primeira pintura da página (evitar
  o "flash" do tema incorreto).
- **NFR-034-005** [MUST] Nos dois temas, em qualquer rota fora de `/login`, as cores usadas
  para papéis semânticos já existentes (indicação de erro, link, foco) devem permanecer
  perceptivelmente distintas do tom de acento da paleta unificada — a extensão da paleta não
  pode fazer um estado de erro parecer decoração.

## 7. Critérios de aceitação (Given-When-Then)
- **AC-034-001** (cobre FR-034-001)
  Dado um visitante sem sessão ativa, quando ele carrega qualquer rota que exibe o header,
  então o sistema mostra o controle de autenticação rotulado "Entrar".
- **AC-034-002** (cobre FR-034-002)
  Dado um colaborador com sessão ativa, quando ele carrega qualquer rota que exibe o
  header, então o sistema mostra o controle de autenticação rotulado "Sair".
- **AC-034-003** (cobre FR-034-003)
  Dado um visitante sem sessão ativa, quando ele aciona o controle de autenticação, então o
  sistema o leva imediatamente à tela de entrada existente.
- **AC-034-004** (cobre FR-034-004)
  Dado um colaborador com sessão ativa, quando ele aciona o controle de autenticação, então
  o sistema dispara a ação de logout já existente, exibindo os três estados observáveis já
  definidos para ela (em andamento, sucesso, falha).
- **AC-034-005** (cobre FR-034-005)
  Dado qualquer rota do aplicativo em que o header seja exibido hoje, incluindo ambiente de
  produção, quando a página carrega, então o controle de autenticação está presente e
  visível.
- **AC-034-006** (cobre FR-034-006)
  Dado um visitante sem sessão ativa, quando ele aciona o controle de autenticação, então o
  sistema nunca dispara a ação de logout — apenas a navegação para a tela de entrada.
- **AC-034-014** (cobre FR-034-014)
  Dado o colaborador autenticado em qualquer rota da área interna, quando a página é
  inspecionada, então existe exatamente um controle de logout na tela (o do header), com os
  três estados observáveis (em andamento/sucesso/falha) e a mensagem genérica já provados
  por AC-002-027.
- **AC-034-015** (cobre FR-034-015)
  Dado um visitante sem sessão ativa numa rota pública, quando a página carrega e o sistema
  determina que não há sessão, então ele permanece na mesma rota, vê "Entrar" e não recebe
  nenhum aviso de sessão expirada nem é redirecionado.
- **AC-034-016** (cobre FR-034-016)
  Dado o carregamento inicial da página, quando o estado de sessão ainda não foi resolvido,
  então o controle de autenticação não mostra "Entrar" nem "Sair" e não aciona nenhuma ação
  se for clicado nesse intervalo.
- **AC-034-007** (cobre FR-034-009)
  Dado qualquer rota do aplicativo em que o header seja exibido hoje, incluindo ambiente de
  produção, quando a página carrega, então o alternador de tema está presente e visível,
  com os dois estados (claro/escuro) distinguíveis.
- **AC-034-008** (cobre FR-034-007)
  Dado um usuário sem escolha de tema salva, cujo dispositivo expõe preferência de esquema
  de cores escuro, quando ele acessa qualquer rota do aplicativo fora de `/login`, então o
  sistema aplica o tema escuro.
- **AC-034-009** (cobre FR-034-008)
  Dado um usuário sem escolha de tema salva e sem preferência de esquema de cores
  detectável no dispositivo, quando ele acessa qualquer rota do aplicativo fora de
  `/login`, então o sistema aplica o tema claro.
- **AC-034-010** (cobre FR-034-010)
  Dado o aplicativo carregado em um dos dois temas, quando o usuário aciona o alternador de
  tema, então o sistema troca imediatamente para o outro tema e o alternador reflete
  visualmente o novo estado, sem nenhum indicador de carregamento intermediário.
- **AC-034-011** (cobre FR-034-011, FR-034-012)
  Dado um usuário que escolheu manualmente o tema escuro num dispositivo cuja preferência
  de esquema de cores é clara, quando ele recarrega a página ou navega para outra rota,
  então o sistema aplica o tema escuro escolhido — não a preferência do dispositivo.
- **AC-034-012** (cobre FR-034-013, NFR-034-003)
  Dado o tema escuro ou o tema claro ativo em qualquer rota fora de `/login`, quando a
  página é renderizada, então as cores de fundo, texto, borda e superfície usam a mesma
  família de tons de roxo/rosa/mauve do login, com contraste mínimo de 4,5:1 (texto) e 3:1
  (borda/ícone), sem nenhum elemento gráfico decorativo equivalente à ilustração de
  `/login`.
- **AC-034-013** (cobre NFR-034-001, NFR-034-002)
  Dado o header renderizado em qualquer estado de sessão e de tema, quando os dois
  controles são inspecionados por tecnologia assistiva, então cada um expõe um rótulo
  acessível coerente com seu estado atual (Entrar/Sair; indicação do tema para o qual a
  troca leva).
- **AC-034-017** (cobre FR-034-011)
  Dado um visitante anônimo que escolhe manualmente o tema escuro e em seguida realiza
  login, quando a área autenticada carrega, então o tema continua escuro (a escolha
  sobrevive à transição de sessão). Dado um colaborador autenticado com essa mesma escolha,
  quando ele sai (logout), então o tema escuro continua aplicado após o logout.
- **AC-034-018** (cobre NFR-034-005)
  Dado uma mensagem de erro e um link renderizados lado a lado com um elemento no tom de
  acento da paleta unificada, em qualquer tema, quando comparados visualmente, então erro,
  link e acento permanecem distinguíveis entre si, não apenas cada um contra o fundo.
- **AC-034-019** (cobre FR-034-005, FR-034-009)
  Dado o header renderizado em largura de 360px com os controles de sessão e tema presentes
  (e `ApiStatus` quando em dev), quando a página é inspecionada, então não há rolagem
  horizontal.

## 8. Premissas e decisões prévias
- **A-034-001** [assumido] [evidência: crença] O controle de autenticação consome
  exclusivamente a sessão já existente (`useMeQuery`/ação de logout já implementadas);
  nenhum comportamento novo de login/logout é criado por esta SPEC — qualquer mudança ao
  fluxo de autenticação em si pertence a SPEC-002/SPEC-016.
- **A-034-002** [assumido] [evidência: crença] Os dois controles novos (autenticação e
  tema) existem em toda rota onde o header hoje aparece, incluindo produção; o indicador de
  status de API (dev-only) não é removido nem alterado por esta demanda.
- **A-034-003** [assumido] [evidência: crença] A tela `/login` (onde o header não é
  exibido) não recebe os dois controles novos; ela mantém a composição própria já entregue
  por SPEC-030/PLAN-031, servindo apenas de referência de paleta e contraste para esta
  SPEC. (confirmado em `site-header-gate.tsx`, `HIDDEN_ROUTES`; supersede o requisito de
  header-presente de FR-030-013/SPEC-030, alterado pelo brief avulso
  `BRIEF-032-login-sem-header-card-centralizado-avulso.md`, posterior à SPEC-030 — não
  confundir com o `BRIEF-032.md` de outra fatia do slug)
- **A-034-004** [assumido] [evidência: medido] Hoje `GET /auth/me` sem sessão (401) aciona,
  pelo mecanismo existente (`baseQueryWithReauth`), tentativa de renovação seguida de
  `resetApiState`+redirect para `/login?sessao=expirada` quando a renovação falha — o
  mecanismo de detecção de sessão para o controle de autenticação do header não pode reusar
  esse caminho sem adaptação; qual adaptação (endpoint alternativo, tratamento de erro
  dedicado, etc.) é decisão técnica do PLAN, mas o requisito de ausência de efeito colateral
  (FR-034-015) é desta SPEC.
- **A-034-005** [assumido] [evidência: crença] A escolha de tema não é vinculada à conta
  autenticada; outra conta no mesmo navegador herda a mesma escolha (comportamento aceitável
  para uma ferramenta interna, sem dado sensível envolvido).

## 9. Riscos e questões abertas
- **RISK-034-001** Sem um mecanismo de persistência definido nesta SPEC (decisão do PLAN),
  a estratégia escolhida pode causar uma troca visível do tema errado na primeira pintura
  da página (FOUC) se a leitura da escolha salva depender só do cliente. Mitigação:
  NFR-034-004 declara o comportamento esperado (SHOULD); a técnica cabe ao PLAN.
- **RISK-034-002** A paleta noturna hoje só foi validada (contraste AA) para os papéis de
  UI existentes em `/login` (fundo, campo em pílula, botão, texto). Estendê-la a todo o app
  pode expor papéis de UI ainda não medidos (estados de erro/sucesso, links, foco, hover)
  sem token equivalente já validado — o mapeamento e a verificação de contraste desses
  papéis novos são decisão e prova da fase de PLAN.
- **RISK-034-003** O mecanismo de detecção de sessão do header precisa conviver com o
  `baseQueryWithReauth` existente sem disparar sua rota de expulsão (renovação + redirect
  para `/login?sessao=expirada`) para visitantes anônimos — mitigação e mecanismo exato
  ficam com o PLAN.

## 10. Fora deste documento
Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
