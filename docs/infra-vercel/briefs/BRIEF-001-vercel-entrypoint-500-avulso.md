# BRIEF-001 — Vercel: GET / responde 500 por entrypoint ambíguo (avulso)

**Jira**: KAN-49
**Modo**: sob demanda (ajuste pontual, config-only)
**Status**: Concluído

## O quê

`mnemonicos-backend/vercel.json` não desliga a detecção automática de
framework da Vercel. A Vercel varre a raiz do projeto (e `src/`) por um
arquivo `app`/`index`/`server` para autodetectar uma app Express. Ela casa
com `src/app.ts`, que só tem exports nomeados (`createApp`, `app`) — sem
`export default` nem `app.listen`. A rota `/` é servida por essa detecção
automática (que falha com 500) em vez de cair no rewrite `/(.*) -> /api`
que serve `api/index.ts` (o entrypoint pretendido, com `export default app`).

Só `/` quebra porque a ordem de resolução da Vercel é
redirects → filesystem/detecção → rewrites: `/` casa com a detecção e nunca
chega ao rewrite; qualquer outro caminho não casa com nada no filesystem e
cai no rewrite, sendo servido pela função boa (por isso `/api/v1/health`
responde 200 normalmente).

## Onde

`mnemonicos-backend/vercel.json` — acrescentar `"framework": null` no
objeto raiz. `functions` (api/index.ts) e `rewrites` permanecem como estão.
Nenhum arquivo em `src/` é alterado — não adicionar `export default` em
`src/app.ts` (resolveria o sintoma, mas publicaria a mesma app por dois
entrypoints e deixaria a armadilha viva para `src/server.ts`, que também
casa com a lista de detecção da Vercel).

## Critério de aceite

- `vercel.json` do backend contém `"framework": null`.
- Nenhum arquivo sob `src/` é tocado.
- Após redeploy (fora do escopo deste diff — ação do Diretor):
  `GET /` → 404 JSON do `notFoundHandler` (não mais 500); `GET /api/v1/health`
  → 200 inalterado.

## Execução
- **Commits**: `a5856cd` (`fix: desliga deteccao automatica de framework da Vercel`,
  2026-09-06T16:37:58-0300) + `d9b900d` (`fix: outputDirectory determinístico e doc da
  condição do framework null`, 2026-09-06T16:47:48-0300) — branch
  `fix/kan-49-vercel-entrypoint-500`, mergeada via PR #4 em `mnemonicos-backend`.
- **Verificado em produção** (2026-09-08, reconciliação de documentação desta sessão):
  `curl -o /dev/null -w '%{http_code}' https://mnemonicos-backend.vercel.app/` → `404`
  (era 500) — critério de aceite satisfeito.
- Documentação deste brief reconciliada em `mnemonicos-workspace` em 2026-09-08 (sessão
  de `/keelson:implement` de PLAN-021) — o código e o merge já existiam, só a doc nunca
  tinha sido registrada no workspace nem o slug `infra-vercel` tinha `INDEX.md`.
