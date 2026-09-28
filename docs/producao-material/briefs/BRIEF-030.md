# BRIEF-030: Redesenho visual da tela de login

**Slug**: producao-material
**Status**: Emitido
**Data**: 2026-09-28
**Largada**: 2026-09-28T15:01:54-0300
**SPEC**: SPEC-030
**Jira**: KAN-73

## Pedido como dito
"/keelson:auto KAN-73 — Redesenhar a tela de login (mnemonicos-frontend)

Card: KAN-73 (História, já existe — NÃO criar card novo). Anexo: imagem de referência visual.

Objetivo: A tela /login atual é um formulário cru (título "Entrar", dois campos e um botão
em `surface-card`) dentro do layout padrão. Redesenhar o visual usando a imagem anexa como
referência de COMPOSIÇÃO e ATMOSFERA — não de conteúdo nem de funcionalidades.

O que tirar da referência: card central vertical em duas metades — em cima, painel
ilustrado (dunas/montanhas em camadas, lua cheia, estrelas pequenas e estrelas cadentes
diagonais, céu em degradê roxo → rosa); embaixo, painel claro com o formulário. Fundo de
página em tela cheia que continua a mesma ilustração, maior e desfocada em profundidade,
com o card "flutuando" por cima com sombra suave. Campos em pílula (bem arredondados), com
ícone à esquerda e fundo preenchido em tom da paleta. Botão primário largo, em tom escuro
da paleta. Título curto e forte à esquerda.

O que NÃO copiar: "remember me", "forgot password" e "Create Account" (o backend só expõe
POST /auth/login e /auth/refresh — não há cadastro nem recuperação de senha; nenhum
controle sem função real); "Username" (o campo é E-mail; texto de interface em pt-BR); o
arquivo da imagem em si (Freepik) — a ilustração é autoral, em SVG inline, decorativa
(aria-hidden), sem imagem externa nem biblioteca nova.

Restrições do projeto: paleta da referência entra como tokens novos no @theme do
globals.css (nunca hex solto no JSX) e define os dois temas via prefers-color-scheme;
contraste AA (4.5:1 texto, 3:1 borda/ícone) nos dois temas, inclusive placeholder/label
sobre fundo em pílula. O layout raiz (src/app/layout.tsx) envolve toda página em
SiteHeader + `<main max-w-5xl py-10>` + footer — o fundo em tela cheia precisa escapar
disso sem alterar a aparência das outras rotas (decisão a registrar no PLAN, com
alternativas). Server Component por padrão — ilustração e moldura são server, só o
LoginForm continua 'use client'. Animação (estrelas cadentes/brilho), se houver, só CSS e
desligada sob prefers-reduced-motion. Responsivo a partir de 360px — painel ilustrado
encolhe no celular (faixa baixa), formulário ocupa a largura toda, sem scroll horizontal.

Comportamento que não pode mudar (contrato testado): LoginForm com method="post", submit
só liberado após hidratação (useSyncExternalStore), mensagem genérica "E-mail ou senha
inválidos." em role="alert" sem aria-invalid, aria-busy, status "Entrando…", redirecionamento
para `next` ou INTERNAL_HOME; page.tsx com o aviso "Sua sessão expirou. Entre novamente."
(role="status") e o guard de open-redirect do `next` via isSafeRelativePath; PasswordField
(mostrar/ocultar senha) reaproveitado e restilizado, não reescrito; continuam passando sem
afrouxar asserção: src/app/login/page.test.tsx, src/app/login/page.next-param.test.ts e
src/components/login-form.test.tsx.

Critérios de aceite propostos (o card ainda não tinha): (1) /login mostra o card em duas
metades sobre um fundo ilustrado em tela cheia, nos temas claro e escuro; (2) nenhum
controle sem função aparece; (3) todas as cores vêm de tokens do @theme, contraste AA
medido nos dois temas; (4) em 360px/768px/1280px não há scroll horizontal e o formulário
fica acima da dobra no celular; (5) com prefers-reduced-motion nada se move; (6) as outras
rotas mantêm header/footer/container sem mudança visual; (7) os comportamentos do contrato
testado continuam provados pelos testes existentes, e o login real funciona no navegador
(gate 9, screen-verify em localhost:3000).

Gates esperados: product-designer (gate 11), qa com verificação de tela, security-engineer
(o diff toca o formulário de login) e performance-engineer se o SVG pesar no bundle."

Card KAN-73 (Jira, lido no MCP): "A tela de login atual está com visual pouco
atrativo/genérico ('sem graça'). Precisa de um redesign visual (layout, cores,
componentes). Observação: o Diretor vai levantar referências visuais... a implementação
deve aguardar esse alinhamento. Critério de aceite: a definir." — a descrição textual da
referência visual trazida no pedido acima **é** esse alinhamento; a imagem em si não
chegou a esta sessão (anexo mencionado, não recebido) — a interpretação usa só o texto.

## Interpretação do PO
**Contexto**: `/login` hoje é um formulário cru dentro do `surface-card` padrão — sem
identidade visual própria — dentro do layout raiz que envolve toda página em
SiteHeader+main+footer (SPEC-002/SPEC-016 já cobrem o comportamento funcional do login e do
toggle de senha; nada disso muda aqui).
**Pedido**: redesenho puramente visual — card em duas metades (painel ilustrado + painel de
formulário) sobre um fundo em tela cheia com a mesma ilustração, ícones em pílula, paleta
nova como tokens de tema, responsivo e acessível — mantendo intocado o comportamento
testado do LoginForm/page.tsx e a aparência das demais rotas.
**Premissas decididas**: ilustração é SVG autoral inline (sem asset externo, sem lib nova);
o card em duas metades e o fundo em tela cheia precisam de uma forma de escapar do
`<main max-w-5xl py-10>` do layout raiz sem alterar as outras rotas — a alternativa
concreta (ex.: route group com layout próprio para `/login`) é decisão técnica do PLAN,
registrada com alternativas (DEC); paleta nova = tokens `@theme` novos, não substituição
dos tokens existentes de outras telas.
**Fora de escopo**: qualquer controle sem função real (lembrar-me, esqueci senha, criar
conta); mudança de copy além de pt-BR já vigente; qualquer alteração de comportamento do
LoginForm/page.tsx/PasswordField além de estilo; alteração de outras rotas.

## Premissas decididas
- **A-030-001** [assumido] [evidência: crença]: a ilustração (dunas, lua, estrelas,
  degradê roxo→rosa) é autoral, feita em SVG inline dentro de componentes Server, sem
  arquivo de imagem externo nem dependência nova — decisão do PLAN escolhe a técnica
  exata (gradient CSS via tokens + `<svg>` para formas/estrelas).
- **A-030-002** [assumido] [evidência: crença]: o mecanismo de fundo em tela cheia que
  escapa do `<main max-w-5xl py-10>` do layout raiz é uma decisão técnica (DEC) do PLAN —
  candidata natural: route group próprio para `/login` com layout dedicado — mas a escolha
  final e as alternativas descartadas ficam registradas lá, não aqui.
- **A-030-003** [assumido] [evidência: crença]: a paleta da referência (roxo/rosa/tons
  escuros) entra como tokens novos e aditivos no `@theme` de `globals.css`, sem renomear
  ou substituir tokens hoje usados por outras telas.

## Fora de escopo
- Cadastro, recuperação de senha, "lembrar-me" — não existem no backend.
- Qualquer mudança de comportamento do LoginForm, page.tsx ou PasswordField além de
  estilo/apresentação.
- Mudança visual de outras rotas (header, footer, container `max-w-5xl`).
- Upload/uso do arquivo de imagem de referência (Freepik) — a ilustração final é autoral.

## Estimativa

- **Base**: pedido e interpretação do PO, INDEX de producao-material com os pares de
  perfil visual de front: PLAN-018 (SPEC-016, 2 tasks small), PLAN-020 (SPEC-019, 2 tasks
  small) e PLAN-003 (SPEC-002, 16 tasks medium, só como referência de contrato), ficha e
  calibração. **Sem base histórica**: `estimates.md` tem 1 demanda fechada (o mínimo é 3),
  então sem corretor aplicado.
- **Dimensão**: ~3 waves · ~4 tasks (~2 small · ~2 medium)
  - W1 small: tokens de paleta aditivos no `@theme` (claro e escuro) e route group com
    layout próprio para `/login`, registrado em DEC com alternativas.
  - W2 medium, em paralelo: ilustração SVG autoral como Server Component (céu, dunas,
    lua, estrelas, estrelas cadentes em CSS com `prefers-reduced-motion`).
  - W2 medium, em paralelo: restyle do LoginForm e do PasswordField (pílula, ícones,
    botão primário), sem tocar o comportamento.
  - W3 small: montagem do card em duas metades sobre o fundo em tela cheia desfocado,
    responsivo em 360/768/1280, medição de contraste AA nos dois temas e checagem de que
    as outras rotas não mudaram.
- **Por fase**: forja 0–0,5h · artefatos 1–2,5h · implementação 3–12h · gates 2–6h
- **Total**: 6–21h (horas de ciclo, não prazo de calendário)
- **Confiança**: média — escopo técnico bem delimitado (sem backend, sem schema,
  contrato congelado por testes), mas o aceite é estético; gate 11 tende a pedir re-gate,
  e a imagem de referência não chegou a esta sessão.
- **Premissas**: route group cabe sem mexer em `layout.tsx`; mover `src/app/login/` só
  troca o caminho dos 3 testes existentes (sem alterar asserção); SVG simples fecha o
  gate 10 rápido; gate 8 roda como revisão confirmatória (diff toca formulário, não
  lógica); margem de 1 rodada extra do product-designer (contraste AA de placeholder/label
  sobre pílula, ponto mais provável de retrabalho).
- **Lacunas**: imagem de referência não recebida — o aceite visual julga contra a
  descrição textual do BRIEF, declarado na aceitação (default do estimator, sem
  escalação — não muda escopo nem critério verificável); credencial de seed para o gate 9
  no navegador — tentativa com o seed de `HANDOFF-PLAN-003.md`, `pendente_handoff`
  declarado se não houver.

## Cronologia
- Largada: 2026-09-28T15:01:54-0300
- SPEC: 2026-09-28T15:22:10-0300 · correções: 2 (pacote de 17 ajustes pelo veredito do PO
  — APROVAR sobre a crítica do product-analyst: header/footer preservados, motivo noturno
  fixo nos 2 temas, cobertura brief→SPEC de título/preenchimento de pílula/tom
  escuro/tokens-only, aria-busy/aria-invalid, juiz de outcome estético por capturas na
  Entrega; + 1 correção mecânica pontual: FR-030-013 fora dos padrões EARS e sem AC que o
  cobrisse) · classes: spec-ac-fora-gwt(12, falso-positivo de acentuação em ferramenta —
  mesma classe de BRIEF-019/020, roteada ao agile-coach), spec-nfr-sem-numero(5-6,
  falso-positivo — check só lê a 1ª linha do bloco multi-linha "campo", roteada ao
  agile-coach), spec-glossario-nao-usado(5, aceito — paráfrase em vez de termo literal),
  spec-must-ratio(1, aceito — redesenho onde todo requisito é mandatório),
  spec-sem-should-may(1, aceito), fr-sem-ac(1, real — corrigido), spec-ears-nao-casa(1,
  real — corrigido)
