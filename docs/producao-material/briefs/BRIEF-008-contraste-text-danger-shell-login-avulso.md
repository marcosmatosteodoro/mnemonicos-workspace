# BRIEF-008: Aplicar `text-danger` em `internal-shell.tsx`/`login-form.tsx` (contraste AA)

**Slug**: producao-material
**Tipo**: avulso
**Status**: Aberto
**Data**: 2026-09-05
**Largada**: 2026-09-05T19:47:09-03:00
**Origem**: Diretor (pedido em sessão — AskUserQuestion, escolha "Corrigir agora")
**Jira**: KAN-44

## Pedido como dito

Gates 1-7 e 11 da Wave 5 de PLAN-006 convergiram no mesmo achado residual: `internal-shell.tsx`
(linhas 62 e 118) e `login-form.tsx` (linha 86) — arquivos de F1/PLAN-003, já mergeados/Done —
usam `text-red-500`, medido em 3.55:1 (sobre `--surface` #f6f7f9) e 3.81:1 (sobre
`--surface-raised` #ffffff) no tema claro: abaixo do piso AA (4.5:1). É o mesmo defeito que a
Wave 5 acabou de corrigir nos próprios arquivos, criando o token `--danger`/`@utility
text-danger` em `globals.css` (medido 5.99-6.72:1 nos dois temas, já compilando de fato no CSS
final). O Diretor escolheu "Corrigir agora" em vez de registrar como dívida para a Entrega.

## Interpretação

Trocar as 3 ocorrências de `text-red-500` por `text-danger` — o token já existe, já foi medido
e provado nesta mesma sessão (Wave 5, commit `b990e41`). Mudança puramente de token de cor,
sem novo campo/contrato, sem mudança de comportamento além da cor do texto — mesma classe de
correção já aplicada 3× nesta wave (T012/T013/T014).

## Critério de aceite

- `mnemonicos-frontend/src/components/internal-shell.tsx:62` e `:118` — `text-red-500` →
  `text-danger`, preservando as demais classes (`p-6 text-sm` em `:62`; `text-sm` em `:118`).
- `mnemonicos-frontend/src/components/login-form.tsx:86` — idem.
- Nenhuma outra classe/comportamento alterado; suíte completa do frontend continua 166/166
  (ou mais, se o autocheck do developer achar caso a acrescentar), typecheck/lint/build limpos.
- Contraste resultante ≥4.5:1 nos dois temas — já medido para `--danger` (5.99-6.72:1); não
  precisa remedir, só confirmar que a classe aplicada é a correta.

## TASKs

nenhuma — o brief é a unidade de execução (2 arquivos, troca mecânica de classe).

## Execução

- **Implementado por**: developer
- **Revisado por**: product-designer (gate 11 — confirma o contraste e a ausência de
  regressão visual); code-reviewer dispensável (troca de classe de cor, sem lógica nova) —
  se o developer tocar qualquer coisa além da classe, promover para gate 1-7 também.
- **Commit**: pendente — Tech Lead commita, mesma prática já em uso nesta sessão.
