# BRIEF-019: Página 404 personalizada com volta à home

**Slug**: producao-material
**Status**: Emitido
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
