# BRIEF-015: Rota raiz (`/`) sem ponto de entrada para a área logada

**Slug**: producao-material
**Tipo**: avulso
**Status**: Aberto
**Data**: 2026-09-07
**Largada**: 2026-09-07T00:00:00-0300
**Origem**: key do tracker (rota pull, KAN-74)
**Jira**: KAN-74

## Pedido como dito
Adicionar na página raiz (`/`) um ponto de entrada para a área logada. Hoje a rota
raiz não oferece nenhum link/CTA para chegar à área logada do sistema — não há
caminho visível de `/` até o app.

## Interpretação
`mnemonicos-frontend/src/app/page.tsx` é hoje um Server Component estático (lista de
técnicas do acervo) sem qualquer link para `/login` ou para a área interna. O
`SiteHeader` (`src/components/site-header.tsx`) também não tem CTA de acesso. O
mecanismo de sessão já existe e é consumido do lado do cliente em
`InternalShell` (`src/components/internal-shell.tsx`) via `useMeQuery()` — mesmo
padrão será reaproveitado num componente cliente novo, renderizado a partir da
página raiz (Server Component), que decide o destino do CTA pelo estado da sessão:
`/login` (sem sessão) ou `INTERNAL_HOME` (`/studio`, `src/lib/internal-routes.ts`)
quando já autenticado. Mudança só de frontend, sem contrato novo de API.

**Severidade**: informativo — funcionalidade nova, não regressão.
**Impacto**: qualquer usuário que chegue à rota raiz sem outro caminho já conhecido
para o app.
**Desde**: card KAN-74 (Jira).
**Evidência**: descrição e critério de aceite do card KAN-74.

## Premissas decididas
**SUPERSEDIDAS** pela decisão em "Caminho tomado" abaixo (reprovadas nos gates 1-7 e
11 — ver essa seção para a decisão vigente). Mantidas aqui só como registro do
caminho descartado:
- ~~CTA implementado como componente cliente (`'use client'`), reaproveitando
  `useMeQuery()` do `store/api.ts` — mesmo dado que `InternalShell` já consome, sem
  chamada de API nova.~~ Falso na rota pública: `/auth/me` não está em
  `PUBLIC_AUTH_PATHS`, e o 401 do anônimo expulsava-o para `/login?sessao=expirada`.
- ~~Enquanto a sessão resolve (`isLoading`) ou em erro, o CTA aponta para `/login`
  (fallback seguro — nunca aponta para a área interna sem confirmação de sessão).~~
- Destino autenticado é `INTERNAL_HOME` (constante já existente), nunca um literal
  solto — mesma régua já aplicada em `login-form.tsx`/`internal-shell.tsx`. **Esta
  premissa sobrevive** na versão final.

## Fora de escopo
- Qualquer mudança em `InternalShell`, `proxy.ts` ou no mecanismo de sessão/cookies.
- Redesenho do `SiteHeader` ou da página raiz além do CTA pedido.

## Critério de aceite
- Dado um usuário acessa a rota raiz (`/`), quando a página carrega, então há um
  elemento visível (botão/link) que leva à área logada — para `/login` se não
  autenticado, ou direto para a área interna (`INTERNAL_HOME`) se já autenticado
  (AC do card KAN-74).

## TASKs
<nenhuma — o brief é a unidade de execução>

## Caminho tomado (decisão em nome do Diretor — degrau 1, retry 1)
1ª implementação (commit `c1f965a`) usava componente cliente com `useMeQuery()` para
decidir o destino do CTA. `code-reviewer` e `product-designer` (rodada paralela)
REPROVARAM: `GET /auth/me` não está em `PUBLIC_AUTH_PATHS`, então o 401 do visitante
anônimo atravessa `baseQueryWithReauth` e expulsa TODO visitante anônimo da home
pública para `/login?sessao=expirada` — regressão nova, prova por execução
(`code-reviewer`, mutante + probe). Achados adicionais: sem teste de wiring da home
(A2), oráculo mockando o hook em vez da store real (A3), duplicação de test helper
(A4).

Correção adotada: eliminar a checagem de sessão no cliente — `<Link
href={INTERNAL_HOME}>` incondicional. `proxy.ts` já redireciona quem navega para
`/studio` sem o cookie de acesso para `/login?next=/studio` (matcher cobre
`/studio`/`/studio/:path*`); autenticado cai direto no app, anônimo é desviado pelo
guard que já existe — sem chamada de API nova, sem tocar sessão/cookies (permanece
fora de escopo), sem encolher o AC. Resolve A1 e, por remover o componente cliente
com RTK Query, torna A2/A3/A4 sem objeto (nenhuma branch de sessão para testar ou
duplicar) — só resta cobrir o wiring da home com o link estático (equivalente a A2,
mais simples).

## Execução
- **Implementado por**: developer
- **Revisado por**: code-reviewer (APROVADO, retry 1) · product-designer (APROVADO,
  retry 1) — gate 8 (security-engineer) e gate 9 (qa) despachados na sequência
- **Commit**: `c1f965a` (1ª versão, REPROVADA nos gates) · `529e081` (correção,
  APROVADA) — push feito pelo Tech Lead nesta rodada (autorizado pelo Diretor).
