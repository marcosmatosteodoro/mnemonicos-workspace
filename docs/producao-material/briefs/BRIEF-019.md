# BRIEF-019: Página 404 personalizada com volta à home

**Slug**: producao-material
**Status**: Aceito (com ressalvas — ver Cronologia/ENTREGA)
**Data**: 2026-09-07
**Largada**: 2026-09-07T14:26:32-0300
**SPEC**: SPEC-019
**Jira**: KAN-76

## Pedido como dito
"Com worktree analise o KAN-76 e implemente. E atualize o jira até revisão (a história) e
termine me mandando o link do pr (sub pode ir até done normal)."

Card KAN-76 (História, Jira): "Criar página 404 condizente com a aplicação, com volta para
a página inicial." Descrição do card: "Hoje uma rota inexistente provavelmente cai no 404
genérico do framework, sem identidade visual do produto. Criar uma página 404 customizada,
alinhada ao visual da aplicação, com um link/botão para voltar à página inicial."
Critérios de aceite do card: (1) Given uma rota que não existe, When o usuário acessa essa
URL, Then é exibida uma página 404 com o visual/identidade da aplicação (não a página
padrão do framework); (2) a página 404 contém um link/botão que leva de volta à página
inicial (`/`).

## Interpretação do PO
**Contexto**: o mnemonicos-frontend (Next 16) hoje serve o 404 genérico do framework para
qualquer rota inexistente — sem a identidade visual (tema/tokens Tailwind) do produto.
**Pedido**: uma página 404 própria, coerente com o visual da aplicação, exibida para
qualquer rota não encontrada, com um link/botão de volta para `/`.
**Premissas decididas**: aplica-se a rotas de nível de aplicação (Next `not-found.tsx`
global) — não há segmentação por área (pública vs. `(interno)`) pedida no card; o link de
volta aponta sempre para `/`, independente de sessão. Sem chamada a API/backend — é uma
tela estática client/server-side do Next, sem novo endpoint.
**Fora de escopo**: página de erro genérica (`error.tsx`, 500), páginas 404 específicas por
segmento/rota, telemetria/analytics de acesso a rota inexistente.

## Premissas decididas
- **A-019-001** [assumido] [evidência: crença]: 404 tratado no nível raiz da aplicação
  (`not-found.tsx` do App Router), cobrindo qualquer rota — pública ou dentro de
  `(interno)` — sem diferenciação de layout por grupo de rota.
- **A-019-002** [assumido] [evidência: crença]: o link de volta aponta sempre para `/`
  (home pública), não para a última rota conhecida nem para a home logada.

## Fora de escopo
- Página de erro genérica (500 / `error.tsx`).
- 404 customizado por segmento de rota (ex.: dentro de `(interno)`).
- Telemetria de rota inexistente acessada.

## Cronologia
- Largada: 2026-09-07T14:26:32-0300
- SPEC: 2026-09-07T14:41:00-0300 · correções: 1 (precedência guard×404, não-regressão, selos, marcas observáveis — po ESCALAR não-bloqueante, E-019-01, default seguido) · classes: spec-ac-fora-gwt(5, falso-positivo de acentuação em ferramenta), spec-must-ratio(1), spec-sem-should-may(1)
- PLAN: 2026-09-07T15:05:00-0300 · correções: 2 (4× `Irreversível: não`→`nao` — mesmo bug de acentuação da ferramenta de lint; §7 com linha malformada + NFRs ausentes do mapeamento) · classes: plan-dec-irreversivel-enum(4, falso-positivo de acentuação em ferramenta), nao-parseavel(1), realiza-vs-mapeamento(2), plan-dec-alternativa-unica(2, aceito — decisão de caminho único legítima)
- TASKS: 2026-09-07T15:15:00-0300 · correções: 1 (rename TASK-020-002 para incluir marcador `-chore-`; QA pré-código fechou 2 lacunas — ativação por Enter exercitada de fato, caso de segmento malformado) · classes: task-nome-tipo(1), task-criterio-grep-nao-ancorado(1, aceito — literal de paleta Tailwind é âncora legítima)
- IMPLEMENT: 2026-09-07T16:27:22-0300 · correções: TASK-020-001 1 retry (product-designer: `metadata.title` ausente + className do link) · TASK-020-002 4 rodadas de convergência, todas mecânicas (asserção fraca de corpo, cobertura de ramo com sessão, âncora de regex de porta, bind loopback, branch defasada de `origin/main`) · classes: sem decisão de arquitetura/produto pendente em nenhuma rodada
- ENTREGA: 2026-09-07T16:45:00-0300 · convergência de fecho: 1 gap `parcial` (AC-019-001
  marca 1 sem asserção automatizada) — fechado antes do push (commit `f10d509`); dedup:
  aplicada, 0 achados. PO (modo aceitação): `ACEITA_COM_RESSALVAS` — 2 ressalvas de
  handoff (não de produto): (1) PR não aberto automaticamente — token do `gh` sem acesso
  ao repo `mnemonicos-frontend` (confirmado: `gh api user/repos` lista
  `mnemonicos-backend`/`mnemonicos-workspace`, não `mnemonicos-frontend`); link manual de
  criação: https://github.com/marcosmatosteodoro/mnemonicos-frontend/pull/new/feat/pagina-404-personalizada
  (2) estado do Jira não estava no resumo passado ao PO — já corrigido: KAN-81/KAN-82
  transicionados para Concluído (id 41), KAN-76 para Em análise (id 31), via gancho
  `closure` do tracker-sync, antes desta rodada de aceitação. E-019-01 (precedência
  guard×404 para rota interna sem sessão) ratificada pelo PO como já decidido na
  aprovação da SPEC — sem nova escalação.
