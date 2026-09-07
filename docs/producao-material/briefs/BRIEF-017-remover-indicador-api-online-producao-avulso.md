# BRIEF-017: Remover indicador "API online" do topo da tela em produção

**Slug**: producao-material
**Tipo**: avulso
**Status**: Concluído (aguarda PR)
**Data**: 2026-09-07
**Largada**: 2026-09-07T00:00:00-0300
**Origem**: key do tracker (rota pull, KAN-71)
**Jira**: KAN-71

## Pedido como dito
"Com worktree analise o KAN-71 e implemente. E atualize o jira até revisão (a história) e
termine me mandando o link do pr (sub pode ir até done normal)."

Descrição do card: hoje a UI exibe um indicador "API online" no topo da tela. Esse
indicador não deve aparecer em ambiente de produção — parece ser um elemento de debug/dev
que vazou para prod.

## Interpretação
`ApiStatus` (`mnemonicos-frontend/src/components/api-status.tsx`) é um indicador cliente de
conectividade com o backend (`useGetHealthQuery`), renderizado incondicionalmente pelo
`SiteHeader` (`src/components/site-header.tsx`) em toda página. É puramente um elemento de
debug — não há caso de uso de produto para o usuário final vê-lo. Correção: `SiteHeader`
passa a renderizar `ApiStatus` condicionalmente, mantendo-o fora de produção (dev/staging)
como o AC do card autoriza. Mudança só de frontend, sem contrato novo de API, sem campo/
dado novo atravessando camada.

**Severidade**: baixa — vazamento de elemento de debug para produção, sem risco de dado
sensível (o indicador não expõe nada além de "online"/"offline").
**Impacto**: qualquer usuário final em produção vê um indicador irrelevante para o produto.
**Desde**: card KAN-71 (Jira).
**Evidência**: descrição e critério de aceite do card KAN-71.

## Premissas decididas
- Detecção de ambiente via `process.env.NODE_ENV === 'production'` (padrão Next.js,
  disponível em Server e Client Components sem exigir `NEXT_PUBLIC_*` novo).
- Em dev/staging o indicador continua aparecendo (comportamento fica a critério de quem
  implementa, conforme o AC do card) — mantém valor de debug local.

## Fora de escopo
- Remover ou alterar `ApiStatus`/`useGetHealthQuery` em si.
- Qualquer mudança de contrato do endpoint de health-check no backend.

## Critério de aceite
- Dado ambiente de produção, quando a tela carrega, então o indicador "API online" não é
  exibido (AC do card KAN-71).

## TASKs
<nenhuma — o brief é a unidade de execução>

## Execução
- **Implementado por**: developer, em worktree próprio (`C:/kwt/kan71-api-status-indicator`,
  branch `feat/remover-indicador-api-online-producao`, a partir de `origin/main`).
- **Revisado por**: code-reviewer — aprovado com ressalvas não-bloqueantes (DRY de
  `process.env.NODE_ENV` repetido, defasagens do perfil next-16 §3/§7 roteadas como itens
  de perfil, não de código).
- **Commit**: `7af078e` — `fix(frontend): ocultar indicador API online em producao`. Push
  feito (`origin/feat/remover-indicador-api-online-producao`).
- **PR**: não aberto automaticamente — o token do `gh` (fine-grained PAT) não tem escopo
  para o repo privado `mnemonicos-frontend` (API devolve 404 mesmo sem autenticação,
  confirmando visibilidade privada; push via SSH funciona porque usa a chave, não o PAT).
  Link para abrir com 1 clique:
  https://github.com/marcosmatosteodoro/mnemonicos-frontend/pull/new/feat/remover-indicador-api-online-producao
- **Testes**: `tests/components/site-header.test.tsx` novo (2 casos); suíte completa
  24/24 arquivos · 237/237 testes verdes; lint/typecheck limpos; `next build` confirma
  ausência do indicador no HTML/RSC servido em produção (controle positivo no mesmo
  artefato).
- **Jira**: KAN-71 (História) → **Em análise** (id 31, trilho do board — só fecha após
  revisão própria, mesmo com a subtask pronta). Subtask **KAN-78** criada e movida direto
  para **Concluído** (id 41 — "sub pode ir até done normal", autorizado pelo Diretor).
  Comentário com o link do PR postado em KAN-71.
