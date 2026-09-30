# BRIEF-039: `/login` sem rodapé e com link discreto de volta à página inicial

**Slug**: producao-material
**Tipo**: emenda (SPEC-030, rota emenda do `/keelson:auto` — decisão 4.398)
**Status**: Aceito
**Data**: 2026-09-30
**Largada**: 2026-09-30T13:11:16-0300
**Origem**: Diretor, card KAN-177 (rota pull `--from=KAN-177`); triagem 1b em 2026-09-30 12:58
**Jira**: KAN-177
**SPEC emendada**: SPEC-030 (v0.1 → v0.2)

## Pedido como dito
Card KAN-177, "Tela de login: remover o rodapé e incluir link discreto "Voltar" abaixo do botão Entrar":

> **Contexto.** Na tela de login (`/login`), aparece no pé da página o texto de rodapé **"Projeto
> Material Mnemônico de Alta Retenção para Concursos"**. Ele destoa da composição da tela, que é o
> cartão ilustrado sobre o fundo noturno. Além disso, a tela não tem um caminho para voltar à área
> pública sem usar o botão Voltar do navegador.
>
> **Pedido.** 1. **Remover o texto de rodapé só na tela de login.** Nas demais páginas o rodapé
> continua. 2. **Incluir, abaixo do botão "Entrar" do formulário, um link "Voltar"** que leva à
> página inicial pública (`/`). Deve ser um link discreto, sem aparência de botão, para não
> competir com a ação principal ("Entrar").
>
> **Onde está.** O rodapé vem do layout raiz, compartilhado por todas as páginas:
> `mnemonicos-frontend/src/app/layout.tsx` (`<footer>`). O cabeçalho já é escondido no `/login` por
> `src/components/site-header-gate.tsx` (lista de rotas `HIDDEN_ROUTES`). O rodapé deve seguir o
> mesmo padrão, sem virar uma segunda regra solta. O formulário fica em
> `src/components/login-form.tsx` (botão "Entrar") e `src/app/login/page.tsx` (cartão). Testes
> relacionados: `src/app/layout.test.tsx`, `src/app/login/page.test.tsx`,
> `src/components/login-form*.test.tsx`.
>
> **Critérios de aceite.** Em `/login`, o texto "Projeto Material Mnemônico de Alta Retenção para
> Concursos" não aparece. Nas outras páginas (inicial, área interna), o rodapé continua aparecendo
> como hoje. Abaixo do botão "Entrar" há um link com o texto **"Voltar"** (ou "Voltar para o
> início") que leva a `/`. O link é discreto: texto pequeno, na cor secundária, sem fundo nem borda
> de botão. O contraste é legível nos temas claro e escuro (WCAG AA para texto) e o foco de teclado
> fica visível. O link não interfere no envio do formulário: Enter continua enviando o login, e o
> link fica depois do botão na ordem de tabulação. Enquanto o login está em andamento, o link
> continua funcionando sem quebrar o formulário. Funciona no desktop e no celular, sem desalinhar o
> cartão. A suíte do frontend passa, com testes para a ausência do rodapé no `/login`, a presença
> dele nas outras rotas e o destino do link.

## Interpretação do PO
- **Contexto**: o `/login` já perdeu o cabeçalho (BRIEF-032/KAN-73) e ficou só o cartão sobre o
  fundo noturno; o rodapé que sobrou destoa, e quem chega ali não tem como voltar ao início sem o
  botão do navegador.
- **Pedido**: tirar o rodapé **só** no `/login`, pela mesma regra que já tira o cabeçalho (uma
  lista de rotas, não duas); pôr abaixo do botão "Entrar" um link discreto que leva a `/`.
- **Premissas decididas**: ver abaixo.
- **Fora de escopo**: cabeçalho/rodapé das outras rotas; comportamento do login; o que acontece a
  quem já tem sessão (KAN-180).

## Premissas decididas
- **P-039-001** [assumido]: a lista de rotas que esconde o cabeçalho passa a governar também o
  rodapé: **uma fonte só** para "rotas sem moldura do app". Nome e forma do componente são decisão
  técnica do developer. O que não pode é nascer uma segunda lista ou um `if (pathname === '/login')`
  solto. `RootLayout` continua Server Component testável sem `render` (restrição já cobrada em
  BRIEF-032).
- **P-039-002** [assumido]: texto do link **"Voltar para o início"**, e não só "Voltar". O card
  aceita as duas formas. O link leva a `/`, não à página anterior do histórico. "Voltar" sozinho
  sugere o botão do navegador, e o propósito do link deve ser claro pelo próprio texto (WCAG 2.4.4).
  É reversível: é só trocar a copy.
- **P-039-003** [assumido]: o link fica **fora** do `LoginForm`, no cartão (`login/page.tsx`), logo
  depois do formulário, e não dentro do `<form>`. Assim o contrato do `LoginForm`
  (SPEC-002/SPEC-016) fica intocado, e o Enter dentro dos campos continua enviando o formulário.
  Pela ordem do DOM, o link fica depois do botão (e do status "Entrando…") na tabulação.
  **Endurecido pelo PO**: o link fica **obrigatoriamente** fora do `<form>`. Dentro dele, quebraria
  as asserções de inventário fechado do form (`login-form.test.tsx`: 4 controles, nenhum link),
  que AC-030-011/NFR-030-005 exigem sem alteração. Pôr dentro exigiria nova emenda.
- **P-039-004** [assumido]: o link **não** é desabilitado durante "Entrando…". Clicar nele no meio
  do login navega para `/` sem cancelar a requisição. **Desfecho real, corrigido pelo PO a partir do
  código**: `handleSubmit` segue depois do `await` e chama `router.push(next ?? INTERNAL_HOME)`
  mesmo com o form desmontado. Se o login der certo, a pessoa é levada de `/` para a área interna
  (ou para `next`) logo em seguida. Se falhar, fica em `/`, sem sessão. O desfecho foi aceito como
  está: é o resultado do login que ela mesma enviou e vai na direção do KAN-180. Mudá-lo exigiria
  mexer no `LoginForm`, o que está fora de escopo. O AC novo prova que o clique navega para `/` sem
  erro e sem travar, e não afirma que a pessoa "permanece em `/`".
- **P-039-005** [assumido]: a regra vale para o caminho `/login` com qualquer query
  (`?next=…`, `?sessao=expirada`), porque o critério é o caminho, não a URL inteira.

## Emenda proposta à SPEC-030
- **FR-030-013** hoje: "manter, em `/login`, o cabeçalho e o rodapé do aplicativo presentes e
  funcionais (navegação preservada)". Essa promessa já não vale para o cabeçalho, que o BRIEF-032
  tirou sem emendar a SPEC. Nova redação: em `/login`, o sistema **não** exibe cabeçalho nem rodapé
  do aplicativo, e a navegação de volta à página inicial pública é garantida por um link discreto
  abaixo do botão de envio.
- **FR novo (link de volta)**: link "Voltar para o início" → `/`, texto pequeno em cor secundária,
  sem aparência de botão, depois do botão de envio na ordem de foco, sem interferir no envio,
  funcional durante o login em andamento.
- **AC-030-001** tem a cláusula "com o cabeçalho e o rodapé do aplicativo presentes e navegáveis"
  substituída pela ausência dos dois em `/login`.
- **AC novo** cobre o FR novo: destino, discrição, contraste AA nos dois temas, foco visível, ordem
  de tabulação, Enter envia, clique durante o login em andamento, 360/768/1280px.
- A não-regressão das **outras** rotas (cabeçalho, rodapé e contêiner intactos) já está escrita e
  continua como está.
- A linha `**Verificação (gate 9)**` da SPEC é reaberta pela emenda e datada de novo na entrega.

## Fora de escopo
- Cabeçalho, rodapé ou contêiner de qualquer outra rota.
- Texto do rodapé (continua igual onde aparece).
- Comportamento de `LoginForm`/`PasswordField`, guarda de `next`, mensagens de erro e de sessão
  expirada.
- Redirecionar para a área interna quem já tem sessão (KAN-180, demanda própria).
- Cancelar a requisição de login quando o usuário sai da tela.

## Critério de aceite
Os critérios do card (transcritos em "Pedido como dito"), com a copy de P-039-002, e mais:
- nenhuma cor literal nova fora dos tokens de `globals.css`;
- lint e typecheck limpos;
- SPEC-030 emendada para v0.2, com lint de artefato e grafo do slug limpos.

## Estimativa
- **Base**: pedido (BRIEF-039/KAN-177, premissas P-039-001..005) · INDEX de producao-material
  (análogos BRIEF-032/KAN-73 e BRIEF-038/KAN-176, nenhum com duração medida no INDEX) · ficha
  (review, security e screenVerify ativos) · calibração: sem base histórica (só 2 demandas fechadas
  após a descontinuidade 4.437, nenhuma na rota emenda/inline; corretor não aplicado).
- **Dimensão**: ~1 wave · ~0 tasks (execução inline pelo brief, 1 diff no mnemonicos-frontend;
  esforço equivalente a ~1 small).
- **Por fase**: forja 0–0,25 · artefatos 0,25–0,75 · implementação 0,5–1,5 · gates 0,5–2
- **Total**: 1,25–4,5h (horas de ciclo, não prazo de calendário)
- **Confiança**: média. Escopo e superfícies nomeados no card; a incerteza está nos gates visuais
  (o gate 11 já precisou de rodada extra em `/login` no BRIEF-032 e no PLAN-031) e na falta de base
  para a rota emenda.
- **Premissas**: BRIEF já emitido, resta a validação do PO · emenda da SPEC-030 pelo scribe + lint
  e grafo, sem PLAN/TASKs · `SiteHeaderGate` vira fonte única sem quebrar o teste de `RootLayout`
  por chamada direta (senão, teto da faixa de implementação) · gate 8 n/a por tópico, com o motivo
  declarado para o casamento de PATH · gates em paralelo com margem para 1 retry do gate 11 ·
  backend local disponível para o qa · PR e card fora da faixa.
- **Lacunas**: nenhuma

## Aceitação (PO)
**ACEITA_COM_RESSALVAS** (2026-09-30). Nada na entrega contraria o brief. Ressalvas fechadas antes do commit: (1) lint de artefato da SPEC-030 e da TASK-031-007 com 0 ERROR e `graph.sh --check` com exit 0; (2) a prova de 768px vem da rodada 1 do gate 9 (`gate9-login-voltar/`), antes do sublinhado em repouso, que não muda a altura da linha; (3) a linha do gate 9 da SPEC corrigida para AC-030-006, e o AC-030-011 cita `page-back-link.test.tsx`.

## Pendências do Diretor
- Destino do scrim do `LoginNightBackdrop` (manter por composição ou remover): em `/login`, nenhum texto do app senta mais sobre o backdrop. Os pares `NIGHT_BACKDROP_SCRIM_PAIRS` ficaram como guarda caso a moldura volte.
- Área de toque AAA maior no link (sugestão do product-designer, fora do pedido; o AA passa pela exceção de espaçamento).

## Cronologia
- 2026-09-30T13:11:16-0300 — largada (rota emenda).
- 2026-09-30T13:18:42-0300 — emenda SPEC-030 v0.2 (PO APROVAR; scribe `modo: edits`; correções 1: TASK-031-007 para o `ac-sem-task`).
- 2026-09-30T13:43:09-0300 — implementação e gates (1 retry consolidado dos gates 1–7 e 11; gate 9 em 2 rodadas); commit `f35c4f3`.
- 2026-09-30T13:44:20-0300 — entrega (aceitação ACEITA_COM_RESSALVAS; push e PR).
