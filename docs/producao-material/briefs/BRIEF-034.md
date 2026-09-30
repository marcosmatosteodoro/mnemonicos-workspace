# BRIEF-034: Botão Entrar/Sair e troca de tema dark/light no topo da tela

**Slug**: producao-material
**Status**: Aceito (com ressalvas — gate 9 parcial, ver HANDOFF-PLAN-035.md; escalação da remoção do "Sair" da área interna CONFIRMADA pelo Diretor na Entrega)
**Data**: 2026-09-29
**Largada**: 2026-09-29T22:34:23-0300
**SPEC**: SPEC-034
**Jira**: KAN-77

## Cronologia
- Etapa 1 (SPEC) concluída: 2026-09-29T22:59:36-0300 — correções: 1, janelas: redação 1min/327l
- Etapa 2 (PLAN) concluída: 2026-09-29T23:21:17-0300 — correções: 1 (2 achados mecânicos do plan-validator corrigidos inline pelo Tech Lead, sem re-despacho ao scribe)
- Etapa 3 (TASKs) concluída: 2026-09-29T23:54:26-0300 — correções: 1 (3 achados mecânicos do task-validator corrigidos inline pelo Tech Lead: campo Realiza(FRs) com NFR misturado, shorthand de AC invisível ao parser, gap de teste de wiring em layout.tsx)
- Etapa 3.5 (verificabilidade pré-código, qa) concluída: 2026-09-30T00:02:16-0300 — correções: 1 (4 achados reais do qa: AC-034-017 2ª cláusula sem exercício, NFR-034-005/AC-034-018 não-falseável, robustez de localStorage sem especificação, pré-condição implícita no roteiro do gate 9)
- Etapa 4 (implement) concluída: 2026-09-30T07:44:41-0300 — 3 waves, 6/6 TASKs Done, convergência de fecho CONVERGIU, PO aceitação ACEITA_COM_RESSALVAS
- Entrega concluída: 2026-09-30T07:58:48-0300 — branch pushada, Diretor confirmou a escalação pendente (remoção do "Sair" duplicado mantida)

## Pedido como dito
"/keelson:auto KAN-77 — Botão Entrar/Sair + troca de tema dark/light usando a paleta do login (mnemonicos-frontend)

Card: KAN-77 (História, já existe no Jira — NÃO criar card novo). A descrição do card no
Jira já foi atualizada e é a fonte da verdade — leia ela inteira antes de tudo (getJiraIssue
KAN-77, projeto KAN). Resumo do que ela diz, para não depender só da leitura do tracker:

1. No topo da tela, na mesma área onde hoje fica o indicador "API online" (ver KAN-71 —
   remoção desse indicador em produção), adicionar dois controles:
   a. Botão de autenticação: "Entrar" quando não autenticado, "Sair" quando autenticado.
   b. Troca de tema: alterna entre dark e light.
2. Comportamento do tema: default light, mas respeita `prefers-color-scheme` do dispositivo
   quando não há preferência salva pelo usuário; depois que o usuário escolhe manualmente,
   essa escolha persiste e prevalece sobre a preferência do SO nas próximas visitas.
3. Paleta de cores dos temas (dark/light) — PEDIDO NOVO do Diretor: a paleta dos dois temas
   do app INTEIRO (não só do login) passa a ser baseada na paleta introduzida no redesign
   visual de `/login` (KAN-73, PLAN-031, já mergeado em `main`) — tons de roxo/rosa/mauve
   sobre fundo noturno escuro que o Diretor aprovou. O resultado tem que ser MINIMALISTA:
   reaproveita as CORES e o contraste AA já validado (4,5:1 texto, 3:1 borda/ícone) — não a
   composição decorativa (SEM ilustração de dunas/lua/estrelas fora de `/login`; o resto do
   app continua com layout simples, sem elemento gráfico extra). Fonte de cor: tokens
   `--color-night-*` de `mnemonicos-frontend/src/app/night-palette-tokens.ts` e o `@theme`
   de `globals.css` (introduzidos em PLAN-031) — hoje só usados em `/login`; decidir e
   registrar em DEC do PLAN como esses tokens (ou uma extensão deles) mapeiam para os
   papéis de UI do resto do app (fundo, texto, borda, superfície de card, etc., nos dois
   temas) é o cerne desta demanda, não um detalhe de implementação.

Critérios de aceite (do card, não inventar além disso):
- Sem preferência salva: usa `prefers-color-scheme` do dispositivo; sem preferência
  detectável, cai em light.
- Escolha manual do usuário persiste entre navegações/reloads e prevalece sobre o SO.
- Autenticado → botão "Sair"; não autenticado → botão "Entrar", ambos na área hoje ocupada
  pelo indicador de API (KAN-71).
- Temas dark/light do app inteiro (fora de `/login`) usam a mesma família de cores
  (roxo/rosa/mauve) do login, com contraste AA mantido, sem replicar a ilustração
  decorativa do login.

Relacionado: KAN-71 (remoção do indicador de API — a área liberada é onde os controles
entram) · KAN-73/PLAN-031 (origem da paleta — branch já mergeada em `main`, ver
`mnemonicos-frontend/src/app/night-palette-tokens.ts`, `globals.css` e
`docs/producao-material/plans/PLAN-031-redesign-visual-login.md` para o histórico da
decisão de paleta e das regras de contraste já usadas).

Server Components por padrão, `'use client'` só onde há estado ou evento (o toggle de tema
e o botão de auth precisam de client). Persistência da escolha de tema: decisão técnica do
PLAN (localStorage é o caminho óbvio, mas registre a alternativa). Identificadores em
inglês, texto de interface em pt-BR.

Gates esperados: product-designer (gate 11, toca paleta/tokens do app inteiro — superfície
grande), qa com verificação de tela (os dois temas, várias rotas, não só login)."

## Interpretação do PO

**Contexto**: `SiteHeader` só mostra hoje o indicador `ApiStatus` (dev-only, KAN-71 já
escondeu em produção). Tema é 100% `prefers-color-scheme`, sem override manual nem
persistência — não existe hoje nenhum mecanismo de escolha do usuário. A paleta noturna
roxo/rosa/mauve (`--color-night-*`, `night-palette-tokens.ts`) existe só em `/login`
(PLAN-031/KAN-73, já mergeada em `main`).

**Pedido**: na área do indicador de API, dois controles novos e sempre visíveis (não
dev-only): botão Entrar/Sair conforme sessão, e alternador de tema dark/light. Tema
default light, mas obedece o SO quando não há escolha salva; escolha manual persiste e
vence o SO depois. A paleta dos dois temas do app inteiro passa a usar a família de cores
do login (reaproveitando cor + contraste AA já medido), sem a ilustração decorativa —
mapear os tokens `--color-night-*` (ou extensão deles) para os papéis de UI do app
(fundo/texto/borda/superfície) é a decisão técnica central, registrada em DEC do PLAN.

**Premissas decididas** [assumido]:
- Persistência da escolha de tema via `localStorage` (mecanismo óbvio e reversível;
  alternativa — cookie legível por SSR para evitar flash — registrada no PLAN como DEC
  com as duas opções).
- Botão de auth usa a sessão já existente (`useMeQuery`/`useLogoutMutation`,
  `SessionUser`): "Entrar" leva a `/login`, "Sair" dispara o logout já provado
  (SPEC-002/SPEC-016) — nenhum comportamento de autenticação novo.
- Os dois controles novos passam a existir em toda a app (inclusive produção); o
  `ApiStatus` existente (dev-only) convive na mesma área do `SiteHeader`, sem remoção —
  o card não pede isso.

**Fora de escopo**: ilustração decorativa (dunas/lua/estrelas) fora de `/login`; qualquer
mudança de comportamento de login/logout já provado; métrica de produto numérica (o card
não declara nenhuma).
