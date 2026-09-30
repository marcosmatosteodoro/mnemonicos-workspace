# BRIEF-037: Container duplicado na área interna (InternalShell dentro do main do root layout)

**Slug**: producao-material
**Tipo**: avulso
**Status**: Aberto
**Data**: 2026-09-30
**Largada**: 2026-09-30T10:48:47-0300
**Origem**: Diretor (pedido em sessão — resposta à pergunta estacionada da Entrega de F10, 2026-09-30: "Brief avulso para depois")

## Pedido como dito
> "Brief avulso para depois" — sobre o achado estacionado na Entrega de F10 (PLAN-035):
> `max-w-5xl` duplicado no `InternalShell`.

## Interpretação
Toda página interna renderiza `InternalShell`
(`mnemonicos-frontend/src/components/internal-shell.tsx:67`: `mx-auto w-full max-w-5xl flex-1
px-4 py-8 sm:px-6`) dentro do `<main>` do root layout (`src/app/layout.tsx:41`: `mx-auto w-full
max-w-5xl flex-1 px-4 py-10 sm:px-6`) — largura máxima e padding horizontal/vertical aplicados
duas vezes, estreitando o conteúdo da área interna e somando espaçamento vertical. Achado
visual fora do escopo de F10; registrado para execução posterior, sem código agora.

## Critério de aceite
- A área interna (`/studio` e demais rotas de `(interno)`) aplica largura máxima e padding de
  container **uma única vez** — verificável no DOM renderizado (um só ancestral com
  `max-w-5xl` até o conteúdo da página).
- Páginas públicas (login, layout raiz) mantêm a largura e o espaçamento atuais — sem
  regressão visual nas rotas fora de `(interno)`.
- Suíte do frontend verde e verificação em tela (gate 9/11) nas duas famílias de rota.

## TASKs
nenhuma — o brief é a unidade de execução

## Execução
- **Implementado por**: pendente — aguardando o Diretor autorizar a execução (sem card no quadro até lá)
- **Revisado por**: pendente
- **Commit**: pendente
