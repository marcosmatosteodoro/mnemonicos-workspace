# BRIEF-043: botão de login em envio mostra "Entrando" com spinner

**Slug**: producao-material
**Tipo**: emenda (SPEC-030, rota emenda do `/keelson:auto` — decisão 4.398)
**Status**: Aceito (ACEITA_COM_RESSALVAS, 2026-09-30; branch `feat/producao-material-login-botao-entrando` pushada, aguardando revisão e merge do Diretor)
**Data**: 2026-09-30
**Largada**: 2026-09-30T16:46:33-0300
**Origem**: Diretor, card KAN-185 (rota pull `--from=KAN-185`); triagem 1b em 2026-09-30 16:40
**Jira**: KAN-185
**SPEC emendada**: SPEC-030 (v0.2 → v0.3)

## Pedido como dito
Card KAN-185, "Tela de login: botão vira "Entrando" com spinner, no lugar do texto "Entrando…" abaixo":

> **Contexto.** Na tela de login (`/login`), ao enviar o formulário, o botão **"Entrar"** fica
> desabilitado e esmaecido, e aparece um texto solto **"Entrando…"** abaixo dele. O retorno visual
> fica fora do lugar onde a pessoa clicou e empurra o link "Voltar para o início" para baixo durante
> o envio.
>
> **Pedido.** Durante o envio do login: o próprio botão troca o rótulo **"Entrar" → "Entrando"** e
> mostra um **spinner** ao lado do texto; o texto solto "Entrando…" abaixo do botão **deixa de
> existir**. Terminado o envio, com erro ou falha de rede, o botão volta a "Entrar", sem spinner.
> Com sucesso, a navegação segue como hoje.
>
> **Onde está.** `mnemonicos-frontend/src/components/login-form.tsx`: botão `type="submit"`
> (`disabled={isLoading || !hydrated}`); bloco
> `{isLoading ? <span role="status" aria-live="polite">Entrando…</span> : null}`, a remover. Testes
> que hoje exigem o texto "Entrando…": `src/app/login/page-back-link.test.tsx` e os testes do
> `login-form`. Cores do botão: tokens `night-button-*` em `src/app/globals.css`. Não há componente
> de spinner no projeto hoje (nenhum `animate-spin` em `src/`), então ele nasce nesta história.
>
> **Critérios de aceite.** Com o login em andamento, o botão mostra **"Entrando"** e um spinner,
> fica desabilitado e não aceita clique nem Enter duplicado. O texto "Entrando…" abaixo do botão não
> aparece mais em nenhum estado. A largura e a altura do botão não mudam entre "Entrar" e
> "Entrando", e o link "Voltar para o início" não se desloca. Com erro de credencial ou de rede, o
> botão volta a "Entrar", sem spinner, e a mensagem de erro aparece como hoje. **Acessibilidade**:
> o estado de envio continua anunciado para leitor de tela (o botão com `aria-busy` e o rótulo
> "Entrando", ou uma região viva equivalente); o spinner é decorativo (`aria-hidden`); o contraste
> do rótulo e do spinner no botão desabilitado atende AA nos temas claro e escuro. Com
> `prefers-reduced-motion`, o spinner não gira (fica um indicador estático) e o rótulo "Entrando"
> continua. Funciona no desktop e no celular. A suíte do frontend passa, com testes para: rótulo e
> spinner durante o envio, ausência do texto solto, retorno a "Entrar" após erro, botão desabilitado
> durante o envio e o anúncio acessível.

## Interpretação do PO
- **Contexto**: o retorno de "enviando" do login aparece longe do clique, como texto solto abaixo do
  botão, e empurra o link "Voltar para o início" para baixo enquanto dura o envio.
- **Pedido**: o retorno passa a morar no próprio botão ("Entrando" + spinner). O texto solto some, e
  o layout do cartão fica parado entre os dois estados.
- **Premissas decididas**: ver abaixo.
- **Fora de escopo**: lógica do login, mensagens de erro, link de volta e outros botões com
  progresso do app.

## Premissas decididas
- **P-043-001** [assumido]: o anúncio acessível fica numa **região viva visualmente oculta**
  (`role="status"`), que passa a dizer "Entrando" durante o envio. O rótulo visível do botão também
  vira "Entrando", e o `aria-busy` do formulário continua (NFR-030-002). Das duas formas que o card
  aceita, esta é a que não depende do foco: com o botão desabilitado no meio do envio, a troca do
  rótulo sozinha nem sempre é lida pelo leitor de tela. O anúncio deve sair **uma vez**. Onde a
  região fica, para não ser silenciada pelo `aria-busy` do formulário, é decisão técnica do
  developer, cobrada pelo gate 11.
  **Endurecido pelo PO**: (a) a região é `sr-only`, **fora do fluxo**, e não gera o `gap-4` do
  form nem desloca o link; (b) fica **sempre montada**, vazia fora do envio, e só ganha o texto
  durante o envio; (c) depois da falha, ela se esvazia sem anunciar "Entrar", e o erro segue
  anunciado só pelo `role="alert"`; (d) como o aviso `?sessao=expirada` também é `role="status"`,
  os testes consultam a região pelo texto, não por `getByRole('status')` sem filtro.
- **P-043-002** [assumido]: o rótulo é **"Entrando"**, sem reticências (literal do card). O spinner
  fica **à esquerda** do texto, e o par fica centralizado no botão. É reversível: é só trocar a
  ordem.
- **P-043-003** [assumido]: o botão desabilitado **deixa de esmaecer por opacidade**. Hoje o
  `disabled:opacity-60` mistura o botão com o painel e derruba o par texto × fundo abaixo de 4,5:1
  **nos dois temas**. Medido pelo PO: no escuro, ~5,06:1 sem opacidade e ~3,3:1 com ela; no claro,
  ~14,16:1 sem opacidade e ~4,1:1 com ela. O estado de envio se distingue pelo
  rótulo, pelo spinner e pelo cursor. Rótulo e spinner usam os tokens `night-button-*` já medidos
  para AA. Se for preciso um token novo, ele nasce no `@theme`, sem cor literal (NFR-030-006).
  **Escopo (PO)**: vale só para o botão de envio de `/login`. O `disabled:opacity-60` dos outros
  botões do app não se toca.
- **P-043-004** [assumido]: o spinner é **SVG inline + CSS**, sem dependência nova (segue a
  DEC-031-002). Ele usa `currentColor` do texto do botão, é `aria-hidden` e fica fora da ordem de
  foco. Gira só quando o movimento é permitido; com `prefers-reduced-motion: reduce` ele fica
  parado, como indicador estático, e o rótulo "Entrando" continua. Nasce como **componente
  próprio** reutilizável, porque o card diz que "ele nasce nesta história". Nenhum outro botão do
  app passa a usá-lo agora. **Endurecido pelo PO**: API mínima, sem props de tamanho, variante ou
  cor.
- **P-043-005** [assumido]: "não aceita Enter duplicado" é provado por teste. Com o botão de envio
  desabilitado, o Enter num campo não reenvia o formulário. Se o teste mostrar que reenvia, entra
  uma guarda no `handleSubmit`. A lógica do login (mutação, `next`, `INTERNAL_HOME`, mensagem
  genérica) não muda. A guarda condicional, se entrar, é a única exceção nomeada na §4.2 da SPEC,
  restrita a ignorar envio com envio em andamento.
- **P-043-006** [assumido]: o botão já ocupa a largura toda (FR-030-005), então a troca de rótulo
  não muda a largura. A altura fica constante porque o spinner não passa da altura da linha do
  texto. O link "Voltar para o início" deixa de se deslocar porque o texto solto sai.
  **Endurecido pelo PO**: nenhum elemento novo entra no fluxo do form entre os estados.

## Emenda proposta à SPEC-030
- **NFR-030-002**: a cláusula "o status 'Entrando…' durante o envio" passa a ser "o estado de envio
  no próprio botão (rótulo 'Entrando' + indicador de progresso decorativo, botão desabilitado),
  anunciado a tecnologia assistiva". Continuam `aria-busy` no formulário, a guarda de hidratação,
  `method="post"`, `role="alert"` e o redirecionamento.
- **FR novo (botão em envio)**: enquanto o login estiver em andamento, o botão de envio mostra o
  rótulo "Entrando" com um indicador de progresso, fica desabilitado e não aceita novo envio. Não há
  texto de status visível fora do botão. Ao terminar com falha, volta a "Entrar", sem indicador. As
  dimensões do botão e a posição do link de volta não mudam.
- **FR-030-012** (movimento reduzido) passa a cobrir também o indicador de progresso do botão. Hoje
  ele fala só de animação **decorativa**. Com a preferência ativa, o indicador fica estático e o
  rótulo continua.
- **NFR-030-001** (contraste): o botão em qualquer estado desabilitado (envio e pré-hidratação)
  entra explicitamente no piso AA dos dois temas.
- **NFR-030-005** (achado do PO): recebe a mesma exceção nomeada de AC-030-011.
- **AC-030-011**: "sem alteração de asserção" ganha uma exceção nomeada. As asserções do texto
  "Entrando…" em `login-form.test.tsx` e `login/page-back-link.test.tsx` são **substituídas** pelas
  do estado no botão, e nenhuma outra asserção é afrouxada.
- **AC-030-015**: "Quando o login está em andamento ('Entrando…')" passa a "Quando o login está em
  andamento (botão em 'Entrando')".
- **AC novo** cobre o FR novo: rótulo e spinner durante o envio, ausência do texto solto em todos
  os estados, retorno a "Entrar" após falha de credencial e de rede, botão desabilitado sem
  reenvio por clique ou Enter, anúncio acessível único, spinner `aria-hidden`, contraste AA nos dois
  temas, spinner estático com movimento reduzido, dimensões constantes e link parado em 360, 768 e
  1280px.
- A linha `**Verificação (gate 9)**` da SPEC é reaberta pela emenda e datada de novo na entrega.

## Fora de escopo
- Lógica do login: mutação, `next`, `INTERNAL_HOME`, mensagem genérica e sessão expirada.
- Comportamento do link "Voltar para o início" (FR-030-016 continua como está).
- Outros botões com estado de progresso no app (logout do header, formulários internos). O spinner
  nasce reutilizável, mas nenhum deles passa a usá-lo agora.
- Paleta e tokens de outros papéis além do botão de envio de `/login`.

## Critério de aceite
Os critérios do card (transcritos em "Pedido como dito"), com as premissas P-043-001..006, e mais:
- nenhuma cor literal nova fora dos tokens de `globals.css`;
- lint e typecheck limpos;
- SPEC-030 emendada para v0.3, com lint de artefato e grafo do slug limpos.

## Estimativa
- **Base**: pedido (BRIEF-043/KAN-185, premissas P-043-001..006, emenda proposta à SPEC-030
  v0.2 → v0.3) · INDEX de producao-material (análogo direto BRIEF-039/KAN-177, rota emenda com
  execução inline registrada como TASK-031-007, Cronologia medida em 35 min de largada a entrega;
  BRIEF-042 só como referência) · ficha (review, security e screenVerify ativos) · calibração: 3
  demandas fechadas depois da descontinuidade 4.437 (PLAN-031, PLAN-035, BRIEF-039), só 1 na rota
  emenda. Corretor aplicado: gates rodam em paralelo, então os pisos saíram abaixo dos do BRIEF-039
  e a gordura vai só para o teto de gates.
- **Dimensão**: ~1 wave · ~1 task (~1 small · ~0 medium). É a TASK de registro TASK-031-008 sob o
  PLAN-031, com execução inline pelo brief e 1 diff no mnemonicos-frontend. Nasce um componente de
  spinner, entra uma região viva oculta, sai o `disabled:opacity-60` e há mais casos de teste.
- **Por fase**: forja 0–0,1 · artefatos 0,15–0,4 · implementação 0,25–0,9 · gates 0,25–1,1
- **Total**: 0,65–2,5h (horas de ciclo, não prazo de calendário)
- **Confiança**: média. Escopo e superfícies nomeados no card, com análogo medido no mesmo arquivo. A
  incerteza está nos gates 11 e 9: onde fica a região viva sem ser silenciada pelo `aria-busy`, o AA
  do botão desabilitado nos dois temas e a captura de um estado passageiro. A base da rota emenda é
  de uma demanda só.
- **Premissas**: falta a validação do PO · emenda da SPEC-030 v0.3 pelo scribe (`modo: edits`), com
  lint e grafo limpos · diff em `login-form.tsx`, componente novo de spinner, `globals.css` se
  precisar de token, e nos testes `login-form*.test.tsx` e `login/page-back-link.test.tsx`; sem
  backend · o botão desabilitado já barra o Enter duplicado (se precisar de guarda, a implementação
  vai para o teto) · os tokens `night-button-*` atendem AA sem opacidade (se precisar de token novo,
  a medição extra fica dentro do teto) · gates 1–7, 8, 9 e 11 em paralelo, 10 n/a, com margem para 1
  retry e 2 rodadas do gate 9 · backend local disponível para o qa · PR, merge e card fora da faixa.
- **Lacunas**: nenhuma

## Aceitação (PO)
**ACEITA_COM_RESSALVAS** (2026-09-30). Todos os itens do card e as premissas P-043-001..006 foram entregues, com evidência por teste e por gate. Ressalvas: (1) o gate 9 ficou parcial: o ramo de sucesso com ADMIN real não foi exercido em app real e está no V2 do `HANDOFF-PLAN-031`, antes do merge (o `handleSubmit` é idêntico ao do commit-pai e a navegação tem teste de unidade); (2) a linha `**Verificação (gate 9)**` da SPEC-030 foi datada de novo na closure, com o estado parcial; (3) as sugestões do gate 11 viraram pendências do Diretor, abaixo.

## Pendências do Diretor
- V2 do `HANDOFF-PLAN-031`: login de sucesso com ADMIN real, com e sem `next`, olhando o botão em "Entrando" (cerca de 2 min).
- Sinal visual de pré-hidratação: sem a opacidade, o botão desabilitado antes do JS carregar fica igual a "Entrar" (é consequência de P-043-003). Card futuro, se quiser.
- Foco depois do clique: quando o botão desabilita, o foco cai no `body`. Já acontecia antes desta entrega, então é candidato a card futuro.

## Cronologia
- 2026-09-30T16:46:33-0300 — largada (rota emenda).
- 2026-09-30T16:58:43-0300 — emenda SPEC-030 v0.3 (PO APROVAR sem escalação; scribe `modo: edits`; TASK-031-008 registrada) · correções: 2 · classes: task-ancora-dupla(1) · ref-quebrada(1) · pertence-vs-arquivo(1) · realiza-fora-cobertura(1) · fr-sem-comp(1)
- 2026-09-30T17:13:31-0300 — implementação e gates (gates 1–7, 8 e 11 aprovados; gate 9 parcial com handoff V2; 1 comentário corrigido e re-gateado, sem retry de código); commit `f8e8709`.
- 2026-09-30T17:17:16-0300 — entrega (aceitação ACEITA_COM_RESSALVAS; push da branch do frontend; KAN-185 em Em análise).
