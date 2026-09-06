# SPEC-013: Suporte a PWA no mnemonicos-frontend

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.2
**Autor**: keelson (scribe)
**Data**: 2026-09-06
**Brief**: BRIEF-013
**Jira Story**: KAN-64

## 1. Contexto e objetivo

### 1.1 Problema

O `mnemonicos-frontend` é a fábrica interna de produção do material mnemônico — uso por
EDITOR/ADMIN, hoje predominantemente desktop (MAP.md, "Acervo"/"Identidade e autorização").
O estudante nunca usa este software: o que ele compra é o PDF gerado por uma fatia futura
(F6), nunca a aplicação em si. Hoje o `mnemonicos-frontend` não tem `manifest.json`, ícones
declarados, service worker nem qualquer critério de instalabilidade — é uma aplicação web
comum, sem a opção de ser adicionada como aplicativo independente à tela inicial/dock de um
dispositivo. O pedido nasce sem gatilho de produto identificado (A-013-001): o Diretor
confirmou que quer a capacidade disponível por completude/boa prática técnica, não para
resolver um problema de uso reportado.

### 1.2 Outcome esperado

O `mnemonicos-frontend` passa a satisfazer os critérios de instalabilidade do navegador —
manifesto de aplicação válido, conjunto de ícones nos tamanhos exigidos pelos contextos do
sistema operacional, service worker registrado — e pode ser instalado por um EDITOR/ADMIN
diretamente do navegador, sem loja de aplicativos, passando a abrir como aplicativo
independente (ícone próprio, sem a interface de navegação do navegador). A capacidade se
aplica ao sistema inteiro: não existe hoje um segmento público distinto do grupo de rotas
`(interno)` (MAP.md), então não há recorte de PWA por sub-área. O service worker cobre só o
ciclo de vida do app-shell (assets estáticos) — nenhuma resposta de API nem HTML
autenticado/dinâmico é cacheada (NFR-013-001/002), preservando o comportamento hoje existente
de sessão e dado sempre vindos da rede. Navegação (documento HTML de qualquer rota) vai
sempre à rede, nunca ao cache do service worker (NFR-013-005) — o app-shell cacheável é só o
conjunto de assets estáticos.

### 1.3 Métrica de sucesso

Sem caso de uso de produto identificado (A-013-001), esta fatia não carrega uma métrica de
valor de negócio — carregaria uma aposta sem gatilho, o que a Etapa 1 deste comando trata
como premissa aberta, não como racional forte. A régua desta fatia é de completude técnica:
o `mnemonicos-frontend` passa nos critérios de instalabilidade padrão de navegador (manifest
válido, ícones nos tamanhos exigidos, service worker registrado, servido em contexto seguro).

**(a) Instalabilidade — conformidade, apurada por inspeção manual**: verificação direta em
Chrome/Edge DevTools > Application > Manifest (a seção de instalabilidade do painel confirma
manifesto válido e ícones nos tamanhos exigidos) + confirmação de que o service worker
aparece **ativo** em Application > Service Workers. Nota de correção desta versão: a
categoria "PWA"/"Installability" do Lighthouse foi **removida a partir da v12** — a
ferramenta não existe mais nesse formato; a fonte de medição passa a ser a inspeção direta
no painel Application do navegador, não um relatório automatizado de auditoria. Sem prazo de
produto associado — revisitar com uma métrica de valor real caso um caso de uso real de
instalação apareça (A-013-001, `Reabrir se:`).

**(b) Observacional (não é conformidade)** — mesmo molde de apuração humana usado no item
(b) da §1.3 de SPEC-005/SPEC-011 (apurado por consulta/inspeção humana, não instrumentação):
nº de EDITOR/ADMIN com o app efetivamente instalado + nº de aberturas em
`display-mode: standalone`, apurado por consulta humana direta aos usuários da fábrica, numa
janela de **90 dias a partir do 1º deploy na origem de produção** nomeada em A-013-006.
Valor de partida = 0. Nenhuma telemetria/instrumentação nova é criada nesta fatia — analytics
de uso exigiria mudança no `mnemonicos-backend`, fora de escopo (§4.2). Resultado 0 ao fim da
janela fecha A-013-001 com fato (nenhum EDITOR/ADMIN instalou nem abriu em modo standalone em
90 dias confirma, na prática, a ausência de caso de uso — não só na origem da premissa).

**Fonte de medição**: (a) externa — inspeção manual no painel Application do Chrome/Edge
DevTools (Manifest + Service Workers), rodada no fecho do ciclo; dono: Tech Lead/QA.
(b) observacional — consulta humana direta aos usuários da fábrica, janela de 90 dias a
partir do 1º deploy na origem de produção (A-013-006); dono: Tech Lead/Diretor.

## 2. Personas e jobs-to-be-done

Como EDITOR ou ADMIN da fábrica, quero poder adicionar o `mnemonicos-frontend` à tela
inicial/dock do meu dispositivo e abri-lo como aplicativo independente, para ter acesso mais
rápido à ferramenta de produção — sem que isso dependa de um caso de uso de produto
específico já identificado hoje (A-013-001); a premissa fica revisitável se um caso de uso
real de instalação/uso mobile aparecer (ex.: EDITOR revisando conteúdo em tablet).

**Anti-persona** (decisão 4.98): não é para o estudante — ele nunca usa este software (MAP.md,
"Resumo"); compra apenas o PDF gerado por uma fatia futura. Instalabilidade aqui não tem
nenhuma relação com a experiência do estudante, em nenhuma fatia do produto.

## 3. Glossário (Ubiquitous Language)

| Termo | Definição | Origem |
|-------|-----------|--------|
| App instalado | Instância do `mnemonicos-frontend` adicionada pelo usuário à tela inicial/dock do dispositivo via mecanismo do navegador, executando em janela própria (modo standalone), sem a barra de navegação do navegador | BRIEF-013 |
| App-shell | Conjunto de assets estáticos (JS, CSS, ícones, manifesto de aplicação) que compõem a casca do app, cacheável pelo service worker independentemente de qualquer dado de sessão ou de conteúdo. **Nunca inclui documento HTML/navegação**: app-shell é só o estático — qualquer requisição de navegação (documento HTML de qualquer rota) vai sempre à rede, nunca ao cache (NFR-013-005) | BRIEF-013 |
| Modo standalone | Modo de exibição do app instalado sem a barra de endereço/navegação do navegador, declarado no manifesto de aplicação | BRIEF-013 |
| Instalabilidade | Conjunto de critérios do navegador (manifesto de aplicação válido, ícones nos tamanhos exigidos, service worker registrado, contexto seguro) que habilitam o prompt nativo de instalação/"Adicionar à tela inicial" | BRIEF-013 |
| Service worker | Script registrado pelo navegador que intercepta requisições do app instalado para controlar cache e ciclo de vida de atualização do app-shell — nesta fatia, restrito a assets estáticos (NFR-013-001), nunca respondendo navegação a partir do cache (NFR-013-005) | BRIEF-013 |

## 4. Escopo

### 4.1 In-scope

- Manifesto de aplicação (nome, ícones, cor de tema, modo de exibição standalone) do
  `mnemonicos-frontend`.
- Conjunto de ícones nos tamanhos padrão que os contextos de exibição do sistema
  operacional/navegador exigem (tela inicial, launcher, splash).
- Registro de um service worker responsável pelo ciclo de vida do app-shell (ativação e
  atualização), sem participar do tratamento de requisições de dados/API.
- Instalabilidade via critérios do navegador — prompt nativo de instalação/"Adicionar à tela
  inicial" — sem controle de instalação custom (banner/botão) dentro do app nesta fatia.
- Cache do service worker restrito aos assets estáticos do app-shell (JS/CSS/ícones/manifesto)
  — nunca resposta de API nem HTML autenticado/dinâmico, e nunca navegação/documento de
  nenhuma rota (NFR-013-001/002/005).
- Atualização do app instalado refletindo um novo deploy do app-shell numa reabertura
  subsequente, sem exigir desinstalação/reinstalação manual (NFR-013-003) — sem troca de
  versão sob uma aba/janela já aberta (NFR-013-003, cláusula nova).
- Um caminho de recuperação/kill-switch executável por deploy do frontend, que devolve um
  cliente já instalado ao comportamento sem service worker (NFR-013-006).
- Aplica-se ao `mnemonicos-frontend` inteiro — todas as rotas hoje existentes, inclusive o
  grupo `(interno)`; não há hoje um segmento público distinto dele (MAP.md) para recortar a
  PWA numa sub-área.
- Nome/short_name, cor de tema e ícones seguem a identidade visual já existente do produto
  (tokens `--link`/`--danger` e paleta de `globals.css` — INDEX.md), sem novo trabalho de
  design de marca (A-013-002).

### 4.2 Out-of-scope

- Funcionamento offline de dados/API — cache de requests de API, fila de sincronização em
  background. Quem lê "service worker registrado" assumiria cache de dados junto; não é o
  caso: o cache fica restrito ao app-shell estático, nunca a navegação (NFR-013-001/002/005).
- Push notifications — mecanismo tecnicamente adjacente ao service worker, explicitamente
  fora desta fatia (BRIEF-013).
- Qualquer mudança no `mnemonicos-backend` — esta fatia é só frontend (BRIEF-013). A métrica
  observacional da §1.3(b) é apurada por consulta humana, não por instrumentação/analytics
  (que exigiria backend).
- Controle de instalação custom no app (banner/botão "Instalar" próprio, com os três estados
  de UI que essa ação exigiria) — quem lê "app instalável" poderia assumir um controle
  próprio na interface; nesta fatia a instalação depende inteiramente do mecanismo nativo do
  navegador/sistema operacional (ver nota em FR-013-002).
- Distribuição via loja de aplicativos (Play Store/App Store) ou splash screen nativo de um
  app empacotado — quem lê "ícone instalável" poderia assumir a experiência completa de app
  nativo de loja; aqui a instalação é sempre via navegador, nunca via loja.
- Segmento ou rota específica com comportamento de PWA diferenciado do resto do sistema — a
  capacidade é do sistema inteiro (§4.1), não de uma sub-área isolada.
- Refinamento de design de marca dos ícones/cores (nova arte, variações, ícone maskable
  dedicado) — os ícones nascem de um asset simples baseado na identidade visual atual,
  refinamento fica para quando houver pedido de design (A-013-002).
- Caso de uso de produto específico que justifique a instalabilidade (ex.: fluxo dedicado
  para EDITOR revisar em tablet) — não identificado nesta fatia (A-013-001); se aparecer,
  entra como revisão desta SPEC ou SPEC nova.
- Escolha de técnica (Workbox × service worker artesanal) e mecanismo exato do
  caminho de recuperação/kill-switch (NFR-013-006 é só o resultado exigido) — decisão de
  `/keelson:plan`, agnóstica de stack nesta SPEC.

## 5. Requisitos funcionais (EARS)

- **FR-013-001** [MUST] O sistema deve ser instalável como aplicativo independente
  diretamente do navegador, sem exigir loja de aplicativos, satisfazendo os critérios de
  instalabilidade do navegador (manifesto de aplicação válido, ícones nos tamanhos exigidos,
  service worker registrado, contexto seguro).
- **FR-013-002** [MUST] Quando o usuário aciona a instalação pelo mecanismo nativo do
  navegador/sistema operacional (prompt de instalação ou "Adicionar à tela inicial") e
  confirma, o sistema deve ser adicionado como app instalado, com ícone próprio, e abrir em
  modo standalone (sem a interface de navegação do navegador) nas aberturas seguintes.
  > **Nota (três estados de UI, decisão 4.67)**: a instalação é acionada e conduzida
  > inteiramente pelo mecanismo nativo do navegador/sistema operacional — o
  > `mnemonicos-frontend` **não** expõe, nesta fatia, um botão ou controle de instalação
  > próprio na interface (§4.2). Os três estados desta ação (em andamento/sucesso/falha) são
  > geridos pela interface do navegador, fora da superfície do sistema — não há estado
  > observável adicional a especificar aqui. Um controle de instalação custom dentro do app
  > é fora de escopo (§4.2) e, se adicionado numa fatia futura, precisará dos três estados
  > como qualquer outra ação de UI iniciada pelo usuário.
- **FR-013-003** [MUST] O sistema deve exibir, no app instalado (ícone da tela
  inicial/dock, splash do sistema operacional, nome do app), um nome e um ícone consistentes
  com a identidade visual atual do produto (A-013-002).
- **FR-013-004** [MUST] O sistema deve declarar um conjunto de ícones nos tamanhos que os
  critérios de instalabilidade do navegador e os contextos de exibição do sistema operacional
  exigem (tela inicial, launcher, splash).
- **FR-013-005** [MUST] O sistema deve registrar um service worker responsável pelo ciclo de
  vida do app-shell instalado (ativação e atualização), sem participar do tratamento de
  requisições de dados/API (NFR-013-001).
- **FR-013-006** [MUST] Quando uma nova versão do app-shell for publicada, o sistema deve
  assegurar que uma reabertura subsequente do app instalado sirva a versão atualizada, sem
  exigir desinstalação/reinstalação manual pelo usuário, e sem trocar de versão sob uma
  aba/janela já aberta (par de leitura: a versão do app-shell ativa reaparece na reabertura
  seguinte, nunca sob cliente ativo — mesmo requisito de NFR-013-003).

> **Nota sobre par de leitura (decisão 4.225)**: esta SPEC não introduz nenhum campo ou
> estado persistível de domínio novo (não há mudança no `mnemonicos-backend`, nem model, nem
> coluna). O que se persiste é infraestrutura de navegador (manifesto, cache do service
> worker, versão do app-shell instalado) — seu par de leitura está coberto por FR-013-002
> (o app abre em modo standalone nas aberturas seguintes) e FR-013-006 (a versão atualizada
> reaparece na reabertura), não por um FR/AC de domínio.

## 6. Requisitos não-funcionais

- **NFR-013-001** [MUST] Se o service worker interceptar uma requisição para uma rota de
  API ou para HTML autenticado/dinâmico, então o sistema não deve armazená-la no cache do
  app instalado — o cache do service worker fica restrito aos assets estáticos do app-shell
  (JS, CSS, ícones, manifesto de aplicação).
- **NFR-013-002** [MUST] Quando o usuário fizer logout ou trocar de conta no app instalado,
  o sistema deve garantir que o cache do service worker não contenha nenhuma resposta
  associada à sessão anterior — **consequência direta de NFR-013-001**: se dado de sessão
  ou conteúdo de outro usuário nunca entra no cache do service worker, não há o que limpar no
  logout (NFR-013-001 já garante o resultado; este item existe para deixar a garantia
  observável no momento do logout, não para introduzir uma segunda regra independente).
  **Nota**: o Cache Storage do navegador é escopado por **ORIGEM**, não por usuário —
  "trocar de conta numa máquina compartilhada" **não** é resolvido por limpeza de cache de
  origem; este NFR não promete isso.
- **NFR-013-003** [MUST] Quando uma nova versão do app-shell for publicada, o sistema deve
  evitar que o app instalado fique preso indefinidamente numa versão desatualizada —
  refletir a versão nova numa reabertura subsequente é suficiente, sem exigir passo manual de
  desinstalação/reinstalação. **Nenhuma troca de versão do app-shell ocorre sob uma
  aba/janela já aberta** — a ativação da versão nova acontece só na reabertura seguinte,
  nunca sob cliente ativo.
- **NFR-013-004** [MUST] O sistema deve ser servido sob conexão segura (HTTPS ou
  `localhost`) onde for implantado — pré-requisito de instalabilidade do navegador,
  já implícito na sessão autenticada existente (SPEC-002, cookies seguros); nenhuma mudança
  de infraestrutura nova além do que já é exigido para autenticação é assumida por esta SPEC.
- **NFR-013-005** [MUST] Se o service worker interceptar uma requisição de
  navegação/documento (qualquer rota da aplicação), então o sistema não deve respondê-la a
  partir do cache — toda navegação vai sempre à rede, sem fallback de navegação
  (`navigateFallback`) nem página offline.
- **NFR-013-006** [MUST] Existe um caminho que devolve o app instalado ao comportamento sem
  service worker para clientes já instalados, executável por um único deploy do frontend,
  sem exigir do usuário desinstalar o app ou limpar cache manualmente.
- **NFR-013-007** [MUST] O manifesto de aplicação usa `start_url` neutro (raiz ou tela de
  login) e não declara `shortcuts` apontando rotas internas; o precache do service worker é
  restrito a assets estáticos — nenhuma lista de rotas internas fica embarcada em arquivo
  servido sem sessão.
- **NFR-013-008** [MUST] O service worker ativo não deve alterar o comportamento hoje
  existente de login, renovação de sessão, guarda de rota e logout (SPEC-002).

## 7. Critérios de aceitação (Given-When-Then)

- **AC-013-001** (cobre FR-013-001, FR-013-002)
  Dado que o usuário (EDITOR ou ADMIN) acessa o `mnemonicos-frontend` por um navegador que
  suporta instalação de PWA, quando o navegador oferece o prompt nativo de instalação (ou o
  usuário aciona "Adicionar à tela inicial" pelo menu do navegador) e o usuário confirma,
  então o sistema é adicionado como aplicativo independente, com ícone próprio, e abre em
  modo standalone (sem barra de navegação do navegador) nas aberturas seguintes.

- **AC-013-002** (cobre FR-013-003, FR-013-004)
  Dado o app instalado, quando o usuário o abre a partir do ícone da tela inicial/dock, então
  o nome exibido e o ícone correspondem à identidade visual atual do produto, nos tamanhos
  que o sistema operacional/navegador exige para cada contexto (tela inicial, launcher,
  splash).

- **AC-013-003** (cobre FR-013-005)
  Dado o `mnemonicos-frontend` servido ao navegador, quando a página é carregada, então um
  service worker é registrado com sucesso e assume o controle das requisições subsequentes de
  assets estáticos do app-shell.

- **AC-013-004** (cobre NFR-013-001)
  Dado o service worker ativo, quando ele intercepta uma requisição para uma rota de API ou
  para HTML autenticado/dinâmico, então o sistema não armazena essa resposta em cache — só
  assets estáticos do app-shell (JS/CSS/ícones/manifesto) são cacheados.

- **AC-013-005** (cobre NFR-013-002)
  Dado um usuário autenticado com o app instalado e o service worker já tendo cacheado, em
  uso normal, os assets estáticos do app-shell (JS/CSS/ícones/manifesto), quando ele faz
  logout (ou troca de conta), então o cache do service worker **CONTÉM** os assets estáticos
  esperados do app-shell (controle positivo — o cache não está vazio) **E** não contém
  nenhuma resposta de rota de API nem de HTML autenticado associada à sessão anterior —
  inspecionável via ferramentas de desenvolvedor do navegador (Cache Storage).

- **AC-013-006** (cobre FR-013-006, NFR-013-003)
  Dado um app instalado com uma versão anterior do app-shell em cache, quando uma nova versão
  é publicada e o usuário reabre o aplicativo, então a versão atualizada é servida/ativada sem
  exigir desinstalação/reinstalação manual.

- **AC-013-007** (cobre NFR-013-004)
  Dado o ambiente onde o `mnemonicos-frontend` está implantado, quando o navegador avalia os
  critérios de instalabilidade, então a aplicação é servida sob conexão segura (HTTPS ou
  `localhost`), condição sem a qual o prompt de instalação não é oferecido pelo navegador.

- **AC-013-008** (cobre NFR-013-005)
  Dado o service worker ativo com os assets estáticos do app-shell já em cache, quando o
  navegador solicita (a) um asset estático do app-shell já cacheado (ex.: um arquivo JS/CSS)
  e (b) uma navegação para uma rota interna da aplicação (ex.: `/content`), então (a) é
  servido a partir do cache do service worker (controle positivo) e (b) é servido sempre a
  partir da rede, nunca do cache (controle negativo) — nenhum fallback de navegação nem
  página offline é retornado em (b).

- **AC-013-009** (cobre NFR-013-006)
  Dado um app instalado com um service worker ativo e problemático, quando o time de
  engenharia publica o deploy do caminho de recuperação, então, numa reabertura subsequente
  do app instalado, o cliente volta a se comportar como se não houvesse service worker — sem
  exigir do usuário desinstalar o app ou limpar cache manualmente.

- **AC-013-010** (cobre NFR-013-007)
  Dado o manifesto de aplicação e a lista de precache do service worker, quando inspecionados
  sem sessão autenticada (ex.: aba anônima, DevTools > Application), então `start_url` aponta
  para a raiz ou para a tela de login, nenhum `shortcut` do manifesto aponta para uma rota
  interna, e o precache contém somente assets estáticos do app-shell — nenhuma lista de
  rotas internas fica embarcada em arquivo servido sem sessão.

- **AC-013-011** (cobre NFR-013-008)
  Dado o service worker ativo, quando o usuário percorre a caminhada completa — login com os
  três estados observáveis, trânsito à área interna, guarda de rota recusando um acesso
  anônimo, renovação silenciosa de sessão, e logout de sucesso (retorno a `/login` exato, sem
  mensagem de "sessão expirada", sem laço de refresh) —, então cada etapa se comporta
  exatamente como descrito em SPEC-002, sem nenhuma alteração introduzida pelo service
  worker.

- **AC-013-012** (cobre FR-013-006, NFR-013-003)
  Dado um app instalado com uma aba/janela já aberta — inclusive com um formulário de EDITOR
  preenchido e não salvo (ex.: Conteúdo bruto ou Quebra da regra) —, quando uma nova versão
  do app-shell é publicada, então a aba/janela viva continua funcionando na versão antiga,
  sem troca de versão sob o cliente ativo e sem perda do formulário não salvo; a versão nova
  só ativa numa reabertura subsequente do app.

> **Nota (verificação de tela, precedente HANDOFF-PLAN-003)**: AC-013-001 e AC-013-002
> (instalação pelo mecanismo nativo, ícone/nome no sistema operacional) só fecham por
> caminhada manual em dispositivo real (gate 9/screenVerify) — não têm caminho automatizado
> equivalente (prompt de instalação e chrome do sistema operacional não são simuláveis por
> teste de integração). Mesmo padrão do handoff de verificação de tela já usado em
> `HANDOFF-PLAN-003` (producao-material) para os itens de tela de F1.

## 8. Premissas e decisões prévias

- **A-013-001** [assumido] [evidência: observação] Não há caso de uso de produto específico
  identificado para a instalabilidade agora — o Diretor confirmou, em declaração direta
  citada em BRIEF-013, que a capacidade é pedida por completude/boa prática técnica, sem
  gatilho de negócio. `Reabrir se:` um caso de uso real de instalação/uso mobile aparecer
  (ex.: EDITOR revisando conteúdo em tablet) — nesse caso, a métrica de sucesso (§1.3) precisa
  ser redefinida com o Diretor.
- **A-013-002** [assumido] [evidência: observação] Nome do app, short_name, cor de tema e
  ícones seguem a identidade visual já existente do produto (tokens `--link`/`--danger` e
  paleta de `globals.css`, leitura de artefato confirmada em INDEX.md) — sem novo trabalho de
  design de marca nesta fatia; os ícones podem nascer de um asset simples baseado na
  identidade atual (gerar/placeholder documentado), refinamento de design fica para quando
  houver pedido explícito.
- **A-013-003** [assumido] [evidência: observação] O escopo do manifesto/service worker é o
  `mnemonicos-frontend` inteiro (todas as rotas), não um segmento específico — leitura de
  artefato (MAP.md) confirma que não existe hoje uma área pública distinta do grupo
  `(interno)`.
- **A-013-004** [assumido] [evidência: crença] Nesta fatia, a instalação depende apenas do
  mecanismo nativo do navegador/sistema operacional — nenhum controle de instalação custom
  (banner/botão) é implementado dentro do app. Se o produto quiser aumentar a taxa de
  instalação com um prompt custom no futuro, isso entra como escopo de uma revisão/SPEC
  futura, com os três estados de UI que a ação exigiria (decisão 4.67).
- **A-013-005** [assumido] [evidência: observação] Cobertura de navegador: aceita-se o
  suporte desigual entre navegadores (ex.: Chrome/Edge com suporte completo de instalação
  PWA; Safari com suporte parcial ao manifesto/instalação) sem workaround dedicado nesta
  fatia — comportamento público verificável de navegador, mesma postura de "aceito nesta
  fatia" já usada em riscos equivalentes do slug (INDEX.md, RISK-011-002).
- **A-013-006** [assumido] [evidência: observação] A origem HTTPS de produção do
  `mnemonicos-frontend` não está confirmada nos artefatos do workspace hoje (único deploy
  registrado é do backend, `docs/infra-vercel/briefs/BRIEF-001-vercel-entrypoint-500-avulso.md`;
  `.env.example` do frontend aponta `NEXT_PUBLIC_API_URL=http://localhost:3333`; sem
  `vercel.json` no frontend). `Reabrir se:` uma origem de produção for nomeada pelo Diretor
  — a prova de instalabilidade desta fatia (AC-013-001/AC-013-002) fecha em `localhost`
  (contexto seguro válido); a prova na origem real e o início da janela de 90 dias da
  métrica (§1.3) ficam como pendência de handoff ao deploy, mesmo padrão de
  `pendente_handoff` já usado em `HANDOFF-PLAN-003` (INDEX.md).

## 9. Riscos e questões abertas

- **RISK-013-001** Sem caso de uso de produto identificado (A-013-001), a capacidade pode
  nunca ser usada organicamente — investimento de instalabilidade sem sinal de necessidade
  real. Mitigação: revisitar quando um caso de uso real aparecer; não bloqueia esta SPEC.
- **RISK-013-002** Cobertura de navegador desigual (Safari com suporte parcial ao manifesto e
  à instalação) pode fazer a capacidade parecer incompleta nesse navegador nesta fatia.
  Mitigação: aceito nesta fatia (A-013-005); revisitar se uso real em Safari/iOS for
  reportado por um EDITOR/ADMIN.
- **RISK-013-003** Sem controle de instalação custom (A-013-004), a descoberta da
  instalabilidade depende inteiramente da heurística própria de cada navegador para oferecer
  o prompt nativo — a instalação pode nunca ser oferecida organicamente a um usuário casual.
  Mitigação: aceito nesta fatia, coerente com A-013-001 (sem gatilho de produto que
  justifique um controle custom); revisitar se a adoção real for baixa e um caso de uso
  aparecer.
- **RISK-013-004** A recuperação de um service worker quebrado (NFR-013-006) ainda depende de
  um deploy manual do Diretor — este projeto não tem pipeline de CI/CD (RISK-006-009,
  INDEX.md). Aceito e nomeado, não é blocker desta SPEC. Mitigação: aceito nesta fatia;
  revisitar quando o projeto ganhar pipeline de CI/CD — até lá o caminho de recuperação
  continua exigindo ato manual do Diretor.
- **RISK-013-005** Ordem de merge com PLAN-012 (F4, mesma superfície de `app/`/layout do
  frontend): a branch que mergear depois precisa reconciliar a sobreposição. Merge é ato do
  Diretor; não bloqueia o desenvolvimento (branches isoladas em worktrees distintas).
  Mitigação: nomeado para o Diretor decidir a ordem de merge; branches isoladas evitam
  conflito durante o desenvolvimento.
- **RISK-013-006** Sob uma aba viva, o navegador pode pedir um chunk que o servidor já purgou
  (condição pré-existente à PWA, agravada pela expectativa de continuidade que NFR-013-003
  cria) — o service worker mitiga mantendo o shell funcional, mas não elimina o caso de um
  asset específico faltar; se ocorrer, o usuário precisa recarregar. Mitigação: aceito nesta
  fatia; degradação já existente sem a PWA, não uma condição nova — se ocorrer, o usuário
  recarrega a aba.
- **Q-013-001** O conjunto exato de tamanhos/variações de ícone (incluindo eventual ícone
  "maskable"/adaptativo para Android) não é decidido nesta SPEC — fica para o `/keelson:plan`
  escolher o conjunto mínimo que satisfaz os critérios de instalabilidade do navegador
  (tecnologia/formato é fora do escopo de uma SPEC agnóstica de stack).

## 10. Fora deste documento

Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
