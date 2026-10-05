# BRIEF-060: CORS aceita os previews da Vercel (wildcard na allowlist)

**Slug**: producao-material
**Tipo**: avulso
**Status**: Entregue na branch feat/producao-material-cors-previews-vercel, sem commit (gates 6 e 8 aprovados)
**Data**: 2026-10-05
**Origem**: Diretor, em sessão. O acesso ao Jira está retirado — sem card.
**Jira**: n/a

## Pedido como dito
"[...] o cors origin, não consigo testar na vercel por conta disso, o endereço padrão hoje é
mnemonicos-frontend.vercel.app, mas os previews são coisas como
mnemonicos-frontend-mxhwmqf9f-mp-consultoria-projects.vercel.app. Seria interessante ajustar
isso, fazer algo como mnemonicos-frontend-*.vercel.app ou ficar no env"

## Decisão
`CORS_ORIGINS` continua sendo a única fonte, mas cada entrada pode ter **um `*` no lugar de um
rótulo de host** (ex.: `https://mnemonicos-frontend-*-mp-consultoria-projects.vercel.app`).
Sem env novo, sem mudar o comportamento de entradas literais.

## Critérios de aceite
- Função pura `isOriginAllowed(origin, allowlist)` em módulo próprio (`src/config/` ou
  `src/http/`), sem I/O, usada **nos dois pontos** que hoje fazem `includes`:
  `corsOptions` em `src/app.ts` e `verifyOrigin` em `src/modules/auth/auth.routes.ts`.
- Entrada literal: igualdade exata (como hoje).
- Entrada com `*`: o `*` casa **um ou mais** caracteres `[a-z0-9-]` (nunca `.`, `/`, `:`, `@`),
  ancorada no início e no fim, comparação case-insensitive no host. Todo o resto da entrada é
  literal (escapar regex). Entrada com mais de um `*` ou `*` fora do host é inválida →
  ignorada (nunca vira "libera tudo"); `*` sozinho nunca casa nada.
- Esquema precisa bater (`https://` ≠ `http://`).
- Testes: preview real do pedido passa; `evil.com`, `https://mnemonicos-frontend-x.vercel.app.evil.com`,
  `https://evil.com/mnemonicos-frontend-x-mp-consultoria-projects.vercel.app`, subdomínio com ponto
  (`a.b`) e esquema errado são rejeitados; `*` sozinho não libera.
- `.env.example` e README (tabela de env + seção CORS) documentam a sintaxe; **sem** valores reais.
- Superfície sensível (CORS/CSRF) → gate 8.

## Fora de escopo
Alterar `.env` real / config da Vercel (é ação do Diretor — declarar no fecho o valor sugerido).
