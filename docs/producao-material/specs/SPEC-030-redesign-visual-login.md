# SPEC-030: Redesenho visual da tela de login

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.2
**Autor**: scribe
**Data**: 2026-09-30
**Jira Story**: KAN-73
**Brief**: BRIEF-030
**Emenda v0.2**: BRIEF-039 (Jira KAN-177) — `/login` sem cabeçalho nem rodapé do app e com link discreto "Voltar para o início"

## 1. Contexto e objetivo

### 1.1 Problema
A tela `/login` hoje é um formulário genérico dentro do `surface-card` padrão do layout
raiz — título "Entrar", dois campos e um botão, sem identidade visual própria. O card
KAN-73 registra a observação do Diretor: o visual está "pouco atrativo/genérico" ("sem
graça"). A tela é o primeiro contato do colaborador interno com a fábrica de produção a
cada sessão, e não comunica cuidado visual algum hoje.

### 1.2 Outcome esperado
`/login` passa a ter identidade visual própria: um card central em duas metades (painel
ilustrado decorativo + painel de formulário) flutuando sobre um fundo de página em tela
cheia que estende a mesma atmosfera visual, com campos em formato de pílula — mantendo
intocados o comportamento de autenticação já provado (SPEC-002/SPEC-016) e a aparência de
todas as demais rotas do aplicativo.

### 1.3 Métrica de sucesso
**A-030-005** [assumido] [evidência: crença] Esta é uma entrega pontual de identidade
visual, sem meta de negócio numérica associada — o BRIEF-030 não define uma. A régua de
sucesso é de conformidade comportamental e visual: todos os critérios de aceitação desta
SPEC (composição do card, ausência de controles sem função, contraste AA nos dois temas,
responsividade sem rolagem horizontal, `prefers-reduced-motion`, não-regressão de outras
rotas e do contrato testado do login) verificados por teste automatizado e por execução
real no navegador (gate 9) no fecho do ciclo. `Reabrir se:` o Diretor quiser associar esta
entrega a uma métrica de produto (ex.: taxa de sucesso de login, tempo até autenticar) no
futuro.

**Juiz do outcome estético**: além dos ACs (conformidade comportamental/visual), o
Diretor exerce aceite binário sobre um conjunto de 6 capturas de `/login` (tema claro e
escuro × 360px/768px/1280px) anexadas ao relatório de Entrega — não bloqueia o ciclo; é
exercido no merge.

**Fonte de medição**: instrumentação — suíte de teste automatizado cobrindo os ACs desta
SPEC + verificação de tela (gate 9, `screen-verify`) no fecho do ciclo; dono: Tech
Lead/QA/product-designer. O aceite estético das capturas (acima) tem dono próprio: o
Diretor, exercido no merge.

**Verificação (gate 9)**: 2026-09-30 (v0.2, BRIEF-039) — qa, roteiro fixado em TASK-031-007, execução real no navegador (worktree `wt-login-voltar`, branch `feat/producao-material-login-sem-rodape-voltar`, frontend :3000 + backend :3333, login real de ADMIN): AC-030-001 (`/login`, `?next=/studio`, `?sessao=expirada` sem cabeçalho e rodapé, claro/escuro × 360/768/1280), AC-030-006 (`/` e `/studio` com cabeçalho e rodapé), AC-030-015 (link sublinhado, Tab botão → link com foco visível, Enter envia, clique durante "Entrando…" vai a `/` e o sucesso leva a `/studio`, sem pageerror) VERIFICADOS; AC-030-005 por teste (inventário fechado do cartão). Capturas em `thoughts/screen-verify/gate9-login-voltar-r2/` (360/1280 da versão final; 768px na rodada 1, `gate9-login-voltar/`, antes do sublinhado em repouso). Registro anterior (v0.1): 2026-09-29 — qa, roteiro fixado em TASK-031-004 (§"Roteiro do gate 9"), consolidado contra o DoD do PLAN-031 (SPEC-030 sem FEATs). 11 passos executados por execução real no navegador (branch `feat/producao-material-login-redesign`, HEAD `55dbf61`, frontend :3000 + backend :3333); 6 capturas (claro/escuro × 360/768/1280px) anexadas à Entrega. AC-030-012 (login real) parcial — ver report do QA.

## 2. Personas e jobs-to-be-done
- **Colaborador interno** (papel EDITOR ou ADMIN) que acessa `/login` em qualquer
  dispositivo (desktop ou mobile) para retomar a sessão de trabalho na fábrica de produção
  de material mnemônico. Job-to-be-done: "quero entrar rápido no meu ambiente de trabalho,
  numa tela que pareça cuidada, sem nenhum controle confuso ou sem função."

<!-- Anti-persona (decisão 4.98): --> Para quem isto **não** é: o estudante final (papel
STUDENT, dormente) — `/login` atende aos papéis internos da fábrica, não aos compradores
do PDF.

## 3. Glossário (Ubiquitous Language)

| Termo | Definição | Origem |
|-------|-----------|--------|
| Sessão autenticada | Vínculo entre uma requisição e uma conta interna ativa, estabelecido por login e válido enquanto não expira nem é revogado | SPEC-002 |
| Credencial de acesso | Prova de sessão de vida curta em cookie inacessível a script, conferida a cada requisição | SPEC-002 |
| Campo de senha (componente) | Componente de entrada reutilizável que encapsula um `<input>` de senha e o toggle de visibilidade associado | SPEC-016 |
| Toggle de visibilidade de senha | Controle que alterna a exibição do valor de um campo de senha entre oculto e texto plano, sem alterar o valor digitado | SPEC-016 |
| Mensagem genérica de autenticação | Texto único de erro de login ("E-mail ou senha inválidos.") em `role="alert"`, que não distingue e-mail inexistente de senha errada | SPEC-002 |
| Card em duas metades | Unidade visual central de `/login`: um painel ilustrado no topo e um painel de formulário na base, percebidos como um único bloco flutuante sobre o fundo da página | BRIEF-030 |
| Painel ilustrado | Metade superior do card, com ilustração autoral decorativa (motivo noturno: montanhas/dunas em camadas, lua cheia, estrelas, estrelas cadentes, céu em degradê), sem função interativa nem conteúdo lido por tecnologia assistiva | BRIEF-030 |
| Fundo em tela cheia (do login) | Camada de fundo da página `/login`, atrás do card, que estende a mesma atmosfera visual do painel ilustrado em escala maior e com profundidade/desfoque | BRIEF-030 |
| Campo em pílula | Estilo visual de campo de formulário com bordas totalmente arredondadas e um indicador visual (ícone) à esquerda do valor digitado | BRIEF-030 |
| Link de volta ao início | Link discreto "Voltar para o início" que leva a `/`, posicionado no cartão de `/login` fora do `<form>`, após o botão de envio; não é controle do formulário | BRIEF-039 |

## 4. Escopo

### 4.1 In-scope
- Recomposição visual de `/login`: card em duas metades (painel ilustrado + painel de
  formulário) sobre um fundo de página em tela cheia com a mesma atmosfera, card percebido
  flutuando (sombra).
- Conteúdo decorativo do painel ilustrado (motivo noturno: montanhas/dunas, lua cheia,
  estrelas, estrelas cadentes, céu em degradê), autoral, sem leitura por tecnologia
  assistiva.
- Estilo de campo em pílula com ícone indicador à esquerda, nos campos de e-mail e senha.
- Botão de envio de largura total/larga.
- Rótulo "E-mail" (não "Username"); texto de interface em pt-BR (já vigente).
- Ausência de qualquer controle sem função real (no backend ou de navegação) — lembrar-me,
  esqueci a senha, criar conta.
- `/login` sem cabeçalho e sem rodapé do aplicativo, com link discreto "Voltar para o
  início" (→ `/`) fora do `<form>`, abaixo do botão de envio (emenda v0.2, BRIEF-039).
- Paleta nova (tons da referência) com contraste AA (4,5:1 texto; 3:1 borda/ícone) nos
  temas claro e escuro, incluindo placeholder/rótulo sobre o fundo preenchido da pílula.
- Responsividade sem rolagem horizontal em 360px, 768px e 1280px; no menor breakpoint, o
  painel ilustrado ocupa faixa baixa e o formulário fica acima da dobra.
- Animação decorativa (se houver) puramente visual, suprimida sob `prefers-reduced-motion:
  reduce`.
- Não-regressão: aparência das demais rotas (header, footer, contêiner) e comportamento já
  testado de `LoginForm`/`page.tsx`/`PasswordField`.
- Verificação de login real no navegador após o redesenho (gate 9).

### 4.2 Out-of-scope
- Cadastro, recuperação de senha, "lembrar-me" — não existem no backend (o vizinho
  simétrico do item "ausência de controle sem função" acima).
- Qualquer mudança de comportamento/lógica do `LoginForm`, `page.tsx` ou `PasswordField`
  além de estilo/apresentação — o comportamento é o vizinho simétrico da não-regressão
  in-scope.
- Mudança visual de outras rotas (header, footer, contêiner `max-w-5xl`) — vizinho
  simétrico da não-regressão de outras rotas in-scope.
- Upload/uso do arquivo de imagem de referência (Freepik) como asset final da aplicação —
  a ilustração entregue é autoral; a imagem serve só de referência de composição/atmosfera
  para esta SPEC.
- O mecanismo técnico exato de como o fundo em tela cheia escapa do layout raiz (ex.: route
  group dedicado) — decisão técnica (DEC com alternativas) do `/keelson:plan` (A-030-002).
- A técnica exata da ilustração (gradiente CSS, formas SVG, ou combinação) — decisão
  técnica do `/keelson:plan` (A-030-001).
- Aplicação da paleta nova a outras telas do aplicativo — os tokens novos são aditivos,
  não substituem os tokens hoje usados por outras telas (A-030-003).

## 5. Requisitos funcionais (EARS)

- **FR-030-001** [MUST] O sistema deve apresentar, na rota `/login`, um card central
  composto por duas metades observáveis: um painel ilustrado no topo e um painel de
  formulário na base.
- **FR-030-002** [MUST] O sistema deve apresentar, atrás do card, um fundo de página em
  tela cheia que estende a mesma atmosfera visual do painel ilustrado (mesma paleta e
  motivo), em escala maior e com profundidade/desfoque, de forma que o card seja percebido
  flutuando sobre ele (sombra).
- **FR-030-003** [MUST] O painel ilustrado deve exibir um motivo noturno decorativo
  (montanhas/dunas em camadas, lua cheia, estrelas, estrelas cadentes, céu em degradê),
  tratado como puramente decorativo — nenhum elemento do painel ilustrado ou do fundo em
  tela cheia é anunciado como conteúdo a tecnologia assistiva, em ambos os temas (claro e
  escuro); a troca de tema altera os tons (tokens), nunca o motivo.
- **FR-030-004** [MUST] Os campos de e-mail e senha devem ter aparência de pílula (bordas
  totalmente arredondadas) com fundo preenchido em tom da paleta nova, com um indicador
  visual (ícone) à esquerda do valor digitado.
- **FR-030-005** [MUST] O botão de envio do formulário deve ocupar a largura total (ou
  próxima da largura total) do painel de formulário, em tom escuro da paleta nova.
- **FR-030-006** [MUST] O rótulo do campo de identificação deve ser "E-mail" — nunca
  "Username" ou outro termo em inglês.
- **FR-030-007** [MUST] O sistema deve exibir, em `/login`, somente controles com função
  real já implementada no backend (campo de e-mail, campo de senha com alternância de
  visibilidade, submissão) e o link de volta ao início (FR-030-015, navegação, fora do
  formulário) — nenhum controle de "lembrar-me", "esqueci a senha" ou "criar conta" aparece.
- **FR-030-008** [MUST] Se o redesenho de `/login` for aplicado, então as demais rotas do
  aplicativo devem manter cabeçalho, rodapé e contêiner sem nenhuma mudança visual
  observável em relação ao estado anterior.
- **FR-030-009** [MUST] O sistema deve apresentar `/login` sem rolagem horizontal nas
  larguras de viewport de 360px, 768px e 1280px.
- **FR-030-010** [MUST] Enquanto a largura da viewport estiver no menor breakpoint
  suportado (360px), o painel ilustrado deve ocupar uma faixa baixa da tela (não
  dominante) e o painel de formulário deve ficar acima da dobra.
- **FR-030-011** [MUST] Onde o painel ilustrado ou o fundo em tela cheia incluir um
  elemento animado (ex.: estrelas cadentes, brilho), o sistema deve garantir que ele seja
  puramente visual/decorativo, sem efeito funcional sobre o formulário.
- **FR-030-012** [MUST] Enquanto o usuário tiver a preferência `prefers-reduced-motion:
  reduce` ativa, o sistema deve suprimir toda animação decorativa da tela de login.
- **FR-030-013** [MUST] O sistema deve apresentar `/login`, com qualquer query string
  (ex.: `?next=…`, `?sessao=expirada`), sem o cabeçalho e sem o rodapé do aplicativo.
- **FR-030-014** [MUST] O painel de formulário deve abrir com um título curto e de
  destaque, alinhado à esquerda.
- **FR-030-015** [MUST] O sistema deve apresentar, em `/login`, um link "Voltar para o
  início" que leva a `/`, com texto pequeno em cor secundária, sem fundo nem borda de
  botão, posicionado após o botão de envio (fora do formulário) e depois dele na ordem de
  foco, sem interferir no envio do formulário.
- **FR-030-016** [MUST] Enquanto o login estiver em andamento, o link de volta ao início
  deve permanecer acionável.

## 6. Requisitos não-funcionais
- **NFR-030-001** [MUST] O sistema deve manter, nos temas claro e escuro, contraste mínimo
  de 4,5:1 entre texto e fundo e de 3:1 entre borda/ícone de campo e fundo adjacente em
  `/login` — incluindo o texto de placeholder e de rótulo sobre o fundo preenchido do
  campo em pílula.
- **NFR-030-002** [MUST] Não-regressão do `LoginForm`: o sistema deve manter, após o
  redesenho, `method="post"` no formulário, o gate de hidratação que libera o envio só após
  montagem no cliente, a mensagem genérica de erro em `role="alert"`, o status "Entrando…"
  durante o envio, e o redirecionamento para `next` (quando presente e seguro) ou
  `INTERNAL_HOME` no sucesso — sem alteração de lógica, só de estilo (fato ancorado:
  `mnemonicos-frontend/src/components/login-form.tsx:1-113`), incluindo `aria-busy` no
  formulário durante o envio e a ausência de `aria-invalid` nos campos quando a mensagem
  genérica de erro está visível.
- **NFR-030-003** [MUST] Não-regressão de `page.tsx`: o sistema deve manter, após o
  redesenho, o aviso de sessão expirada em `role="status"` e o guard de open-redirect do
  parâmetro `next` via `isSafeRelativePath` (fato ancorado:
  `mnemonicos-frontend/src/app/login/page.tsx:16-41`).
- **NFR-030-004** [MUST] Não-regressão do `PasswordField`: o sistema deve manter, após o
  redesenho, o comportamento funcional de alternância mostrar/ocultar senha idêntico ao
  atual — o componente é reestilizado, nunca reescrito (fato ancorado:
  `mnemonicos-frontend/src/components/password-field.tsx:60-99`).
- **NFR-030-005** [MUST] Os testes automatizados existentes devem continuar passando após
  o redesenho, sem afrouxamento de asserção: `mnemonicos-frontend/src/app/login/page.test.tsx`,
  `mnemonicos-frontend/src/app/login/page.next-param.test.ts`,
  `mnemonicos-frontend/src/components/login-form.test.tsx` e
  `mnemonicos-frontend/src/components/password-field.test.tsx`.
- **NFR-030-006** [MUST] Todas as cores da tela `/login` (card, ilustração, fundo, campos,
  botão, texto) devem vir de tokens do `@theme` de `globals.css`; nenhum valor de cor
  literal (hex/rgb/hsl) no JSX ou em classes arbitrárias dos componentes de login.

## 7. Critérios de aceitação (Given-When-Then)
- **AC-030-001** (cobre FR-030-001, FR-030-002, FR-030-013)
  Dado um visitante acessando `/login`, quando a página carrega, então ele observa um card
  central dividido em duas metades (painel ilustrado no topo, painel de formulário na
  base) sobre um fundo de página em tela cheia que estende a mesma atmosfera visual, com o
  card percebido flutuando (sombra), nos temas claro e escuro, sem cabeçalho e sem rodapé
  do aplicativo — inclusive em `/login?next=…` e `/login?sessao=expirada`.
- **AC-030-002** (cobre FR-030-003)
  Dado o painel ilustrado carregado, quando a página é percorrida por tecnologia
  assistiva, então nenhum elemento do painel ilustrado ou do fundo em tela cheia é
  anunciado como conteúdo.
- **AC-030-003** (cobre FR-030-004, FR-030-005)
  Dado o painel de formulário renderizado, quando ele é inspecionado, então os campos de
  e-mail e senha têm bordas totalmente arredondadas com fundo preenchido em tom da paleta
  nova e um ícone indicador à esquerda, e o botão de envio ocupa a largura total do painel
  em tom escuro da paleta nova.
- **AC-030-004** (cobre FR-030-006)
  Dado o painel de formulário renderizado, quando o rótulo do campo de identificação é
  lido, então o texto é "E-mail".
- **AC-030-005** (cobre FR-030-007)
  Dado o card redesenhado, quando ele é inspecionado por completo, então não há nenhum
  controle de "lembrar-me", "esqueci a senha", "criar conta" ou qualquer outro controle
  sem função real (no backend ou de navegação). Inventário: o `<form>` contém exatamente 4
  controles (e-mail, senha, toggle de visibilidade, botão de envio) e o cartão contém
  esses 4 mais o link de volta ao início, fora do `<form>`.
- **AC-030-006** (cobre FR-030-008)
  Dado o redesenho de `/login` aplicado, quando outra rota do aplicativo é acessada (ex.:
  home pública ou uma tela da área interna), então cabeçalho, rodapé e contêiner
  permanecem visualmente idênticos ao estado anterior ao redesenho.
- **AC-030-007** (cobre FR-030-009)
  Dado `/login` redesenhado, quando a viewport está em 360px, 768px ou 1280px de largura,
  então não há rolagem horizontal em nenhuma das três.
- **AC-030-008** (cobre FR-030-010)
  Dado `/login` em viewport de 360px, quando a página é renderizada, então o painel
  ilustrado ocupa uma faixa baixa (não dominante) da tela e o painel de formulário aparece
  acima da dobra.
- **AC-030-009** (cobre FR-030-011, FR-030-012)
  Dado um usuário com `prefers-reduced-motion: reduce` ativo, quando a página `/login`
  carrega, então nenhuma animação decorativa (estrelas cadentes, brilho) ocorre, e o
  formulário permanece funcional.
- **AC-030-010** (cobre NFR-030-001)
  Dado os temas claro e escuro de `/login`, quando o contraste de texto, bordas e ícones
  de campo — incluindo placeholder e rótulo sobre o fundo preenchido da pílula — é medido,
  então todos atingem no mínimo 4,5:1 (texto) e 3:1 (borda/ícone).
- **AC-030-011** (cobre NFR-030-002, NFR-030-003, NFR-030-004, NFR-030-005)
  Dado o redesenho aplicado, quando os testes automatizados
  `mnemonicos-frontend/src/app/login/page.test.tsx`,
  `mnemonicos-frontend/src/app/login/page.next-param.test.ts`,
  `mnemonicos-frontend/src/components/login-form.test.tsx` e
  `mnemonicos-frontend/src/components/password-field.test.tsx` são executados, então todos
  passam sem alteração de asserção, incluindo `aria-busy` durante o envio e a ausência de
  `aria-invalid` nos campos em erro. Na emenda v0.2, `layout.test.tsx`,
  `app-chrome-gate.test.tsx` e o arquivo novo `login/page-back-link.test.tsx` (com o form real,
  que `page.test.tsx` mocka) ganham asserções (ausência de cabeçalho/rodapé em `/login`,
  presença nas demais rotas, link e seu destino) e nenhuma asserção existente é
  afrouxada; a prova do link é do AC-030-015.
- **AC-030-012** (cobre NFR-030-002)
  Dado um colaborador interno com credencial válida na tela de login redesenhada, quando
  ele submete e-mail e senha corretos (com `next` seguro presente, e também sem `next`),
  então o sistema autentica e redireciona corretamente em cada ramo, comprovado por
  execução real no navegador.
- **AC-030-013** (cobre FR-030-014)
  Dado o painel de formulário renderizado, quando ele é inspecionado, então exibe um
  título curto e de destaque, alinhado à esquerda.
- **AC-030-014** (cobre NFR-030-006)
  Dado o código de `/login` (componentes e estilos), quando inspecionado, então nenhuma
  cor literal (hex/rgb/hsl) aparece fora dos tokens `@theme`.
- **AC-030-015** (cobre FR-030-013, FR-030-015, FR-030-016, NFR-030-001, NFR-030-006)
  Dado `/login` (com e sem query string, ex.: `?next=…`), quando a página carrega, então
  não há cabeçalho nem rodapé do aplicativo, e abaixo do botão "Entrar" há um link com o
  texto "Voltar para o início" cujo destino é `/`; o link é discreto (texto pequeno, cor
  secundária, sem fundo nem borda de botão), tem contraste AA nos temas claro e escuro e
  foco de teclado visível, vem depois do botão na ordem de tabulação, e Enter nos campos
  continua enviando o formulário. Quando o login está em andamento ("Entrando…") e o
  usuário clica no link, então o navegador vai para `/` sem erro e sem travar (não se
  afirma que permanece em `/` após a resposta: no sucesso, o `LoginForm` leva à área
  interna — P-039-004). O cartão não desalinha em 360px, 768px e 1280px, e a cor do link
  vem de token do `@theme`.

## 8. Premissas e decisões prévias
- **A-030-001** [assumido] [evidência: crença] A ilustração do painel ilustrado e do
  fundo em tela cheia (dunas/montanhas, lua, estrelas, degradê) é autoral, produzida em
  SVG e/ou CSS inline, puramente decorativa, sem arquivo de imagem externo nem
  dependência nova — a técnica exata (gradiente CSS vs. formas SVG vs. combinação) é
  decisão do `/keelson:plan`. `Reabrir se:` a técnica escolhida no PLAN não conseguir
  cobrir FR-030-003/FR-030-011 sem asset externo.
- **A-030-002** [assumido] [evidência: crença] O mecanismo pelo qual o fundo em tela
  cheia escapa do `<main max-w-5xl py-10>` do layout raiz
  (`mnemonicos-frontend/src/app/layout.tsx:31-44`) sem alterar as outras rotas é uma
  decisão técnica (DEC com alternativas) do `/keelson:plan` — candidata natural: route
  group próprio para `/login` (nenhuma rota deste app usa hoje um route group para uma
  única página pública; `(interno)/` é o único precedente, e serve a área logada
  inteira). Esta SPEC só exige o requisito observável de FR-030-008/AC-030-006.
- **A-030-003** [assumido] [evidência: crença] A paleta nova (tons da referência) entra
  como tokens aditivos no `@theme` de `globals.css`, sem renomear ou substituir os tokens
  hoje usados por outras telas (`--color-ink-*`, `--color-brand-*`, `--color-recall-*`,
  `--surface`, `--surface-raised`, `--border-subtle`, `--text-strong`, `--text-muted`,
  `--link`, `--danger`). `Reabrir se:` o Diretor quiser adotar a paleta como identidade do
  produto em outras telas — brief próprio.
- **A-030-004** [assumido] [evidência: crença] A imagem de referência anexada ao pedido
  original não chegou a esta sessão (anexo mencionado, não recebido — card KAN-73 também
  não a traz). O aceite visual desta SPEC julga contra a descrição textual do "Pedido como
  dito" e da "Interpretação do PO" registradas no BRIEF-030, não contra a imagem. Default
  herdado da Estimativa do BRIEF-030 (§Lacunas), aplicado sem escalação — não muda escopo
  nem critério verificável. `Reabrir se:` o Diretor anexar a imagem antes da Entrega e
  quiser julgar o resultado visual contra ela diretamente; ou se as capturas anexadas à
  Entrega (§1.3) divergirem da imagem que o Diretor tem em mãos.
- **A-030-005** [assumido] [evidência: crença] Entrega pontual de identidade visual sem
  meta de negócio numérica no BRIEF-030 — a régua de sucesso (§1.3) é de conformidade
  comportamental/visual (os ACs desta SPEC), não uma métrica de produto numérica com
  prazo. `Reabrir se:` o Diretor quiser associar esta entrega a uma métrica de produto no
  futuro.
- **A-030-006** [assumido] [evidência: crença] O motivo noturno (dunas/montanhas, lua,
  estrelas, céu roxo→rosa) é fixo nos dois temas — claro e escuro trocam tons/tokens,
  nunca o conteúdo da cena; no tema claro, o painel de formulário é claro (conforme a
  composição pedida no BRIEF-030). `Reabrir se:` o Diretor pedir uma variante diurna do
  motivo.

## 9. Riscos e questões abertas
- **RISK-030-001** O contraste AA de placeholder/rótulo sobre o fundo preenchido da
  pílula (NFR-030-001) é o ponto mais provável de retrabalho no gate de design, segundo a
  Estimativa do BRIEF-030 (§Confiança). Mitigação: medir contraste nos dois temas antes de
  fechar a wave que toca os campos; o PLAN deve reservar margem para uma rodada extra do
  `product-designer`.
- **RISK-030-002** O peso do SVG/CSS autoral da ilustração no bundle de `/login` pode
  acionar o gate de performance (BRIEF-030 cita `performance-engineer` entre os gates
  esperados "se o SVG pesar no bundle"). Mitigação: o PLAN deve manter a ilustração simples
  (poucos paths, sem geometria pesada) e o `performance-engineer` avalia na
  implementação.
- **Q-030-001** A alternativa técnica concreta para o fundo em tela cheia escapar do
  layout raiz sem alterar outras rotas (ex.: route group dedicado a `/login`) ainda não
  está decidida — cabe ao `/keelson:plan` registrar com alternativas descartadas (DEC),
  condição já prevista em A-030-002.
- **RISK-030-003** Cobertura por roteiro de verificação (gates 9/11), não por AC: trânsito
  guard → `/login?next=` → login → `next`; foco de teclado visível (ordem e-mail → senha →
  toggle → botão → link "Voltar para o início", indicador ≥3:1, nenhum elemento decorativo focável); robustez da
  ilustração (SVG ausente/degradado não quebra o formulário); autofill do navegador sobre
  o campo em pílula; `forced-colors`; aviso de sessão expirada visível acima da dobra em
  360px. Decisão do PO: cobertos pelo roteiro de implementação, não por AC formal nesta
  SPEC.

## 10. Fora deste documento
Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
