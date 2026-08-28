# Backlog de revisão humana — `next-16.md`

Roteiro de verificação das afirmações `⚠️ não confirmado` do perfil
`guidelines/project/frontend/next-16.md` (gerado, `reviewed: false`) — lido só no fluxo de
revisão de perfil, nunca em runtime de implementer/reviewer.

Alvo confirmado no `package.json`: **next 16.3.2 · react 19.2.8 · typescript ^6.0.3 ·
tailwindcss ^4.3.3 · @reduxjs/toolkit ^2.12.0 · jest ^30.4.2**. Ao promover o perfil,
preencha `reviewed: true` e acrescente `reviewer: <nome>` no cabeçalho.

## Itens marcados no perfil (16)

- **§5** — Confirmar que, em produção, o Next substitui a mensagem de erro lançado no
  servidor (Server Component / Route Handler) por um `digest`, mantendo a mensagem real
  apenas no log do servidor. Fonte: doc de *Error Handling* do App Router na 16.x. Se o
  comportamento depender de configuração, o perfil precisa dizer qual.
- **§6.1** — Confirmar como o `fetchBaseQuery` do RTK Query 2 serializa o campo `params`
  (qual encoder, e se valor contendo `&`, `=`, `#` ou espaço é escapado integralmente).
  Fonte: doc do `fetchBaseQuery` + `paramsSerializer`. Se o default for frouxo, a regra
  passa a ser `paramsSerializer` explícito.
- **§6.2** — Confirmar o comportamento do React 19 diante de `href="javascript:…"`:
  bloqueio com erro, remoção silenciosa, ou apenas aviso em desenvolvimento. Fonte:
  changelog do React 19 / doc de atributos de DOM. A regra de allowlist de protocolo fica
  de pé em qualquer caso — o que muda é se ela é a única defesa.
- **§6.2** — Confirmar o mecanismo suportado de **CSP com nonce** no Next 16: onde o nonce
  é gerado (`proxy.ts`), como é propagado para os scripts inline do framework e se
  `strict-dynamic` é necessário. Fonte: guia *Content Security Policy* do Next 16. Sem
  isso, escrever a policy produz CSP decorativa (`unsafe-inline`).
- **§6.3** — Confirmar a afirmação "**`layout.tsx` não re-executa** a cada navegação de
  filho" na 16.x (interação com o Router Cache e com `cacheComponents`), e a conclusão
  derivada: checagem de acesso não pertence ao layout. Fonte: doc de *Layouts and Pages* +
  guia *Authentication* (padrão DAL). É a afirmação com maior custo se estiver errada.
- **§6.3** — Confirmar se **16.3.2 está na faixa corrigida** do advisory de bypass de
  middleware por header interno forjado (`x-middleware-subrequest`, GHSA de 2025) e se a
  renomeação para `proxy.ts` (runtime Node) altera a classe de risco. Fonte: GitHub
  Security Advisories do `vercel/next.js` + `npm audit` sobre o lock atual.
- **§6.4** — Confirmar que `import 'server-only'` faz o **build falhar** (não apenas erro
  em runtime) quando o módulo entra no grafo cliente no Next 16, e se o pacote continua
  sendo o mecanismo canônico. Fonte: guia *Data Security* / *Server and Client Components*.
- **§6.4** — Confirmar o desenho de criptografia de closure de Server Action: chave gerada
  por build, necessidade de `NEXT_SERVER_ACTIONS_ENCRYPTION_KEY` em deploy
  multi-instância, e o que a plataforma de deploy (Vercel) já provê. Fonte: guia
  *Data Security* + doc de `serverActions`. Registrar a conclusão como decisão de infra.
- **§6.4** — Confirmar o **default de `productionBrowserSourceMaps`** no Next 16 (se
  source maps do browser são publicados em produção sem opt-in). Fonte: referência de
  `next.config.js`. Se forem publicados, decidir explicitamente e registrar.
- **§6.5** — Confirmar, para o par de domínios real (frontend na Vercel + host do
  backend), a combinação válida de `SameSite`/`Secure` com `credentials: 'include'` e a
  consequência de CSRF que `SameSite=None` traz. Verificação **em ambiente real**, antes da
  primeira rota autenticada; coordenar com o §6.5 do perfil de backend (`node-22.md`).
- **§6.5** — Confirmar a proteção CSRF nativa de **Server Actions** na 16.x (POST-only +
  comparação `Origin` vs `Host`/`X-Forwarded-Host`, papel de
  `serverActions.allowedOrigins`), o estado do reporte de falha por *case-sensitivity* nessa
  comparação, e — o ponto crítico — que **Route Handlers não herdam** essa proteção. Fonte:
  doc de `serverActions` + post *How to Think About Security in Next.js*.
- **§6.5** — Confirmar que `cookies()` é assíncrona no Next 16 e que **escrever** cookie só
  é permitido em Server Action ou Route Handler (erro durante o render de Server
  Component). Fonte: referência de `cookies()` na 16.x.
- **§6.6** — Confirmar o comportamento do `fetch` no runtime Node do Next 16 quanto a
  **seguir redirect por padrão** e à ausência de guarda contra IP privado/endpoint de
  metadados, para sustentar a regra de `redirect: 'manual'` + allowlist de host resolvido.
  Fonte: doc do `fetch` do Next + undici. Aplica-se quando o primeiro `route.ts`/Server
  Action nascer.
- **§6.6** — Confirmar a configuração de imagem no Next 16: se `images.qualities` passou a
  ser obrigatória/estrita, o formato exato de `remotePatterns`/`localPatterns` e o efeito de
  `dangerouslyAllowSVG`. Fonte: referência de `images` no `next.config.js` da 16.x +
  advisory de DoS no Image Optimizer. Hoje o projeto não configura `images` — decidir se é
  lacuna ou n/a (não há imagem remota).
- **§7** — Confirmar o estado do suporte a renderização de **Server Components `async`** em
  `@testing-library/react` 16.x sobre jsdom (hoje o perfil assume que não renderiza e manda
  cobrir por função pura + `screenVerify`). Fonte: release notes da RTL 16. Se houver
  suporte, o perfil ganha um caminho novo em §7.
- **§11** — Confirmar a **lista exata de utilitárias renomeadas e defaults alterados** no
  Tailwind 4 (família `shadow-*`, `outline-none`/`outline-hidden`, `ring` default, cor de
  borda `currentColor`) e a matriz mínima de browsers. Fonte: guia oficial de upgrade
  v3→v4. Relevante ao portar marcação vinda de fora do projeto.

## Pendências estruturais levantadas pelo perfil (não são tags, mas exigem decisão)

- **CSP ausente** (§6.2): `next.config.ts` envia `nosniff`, `X-Frame-Options`,
  `Referrer-Policy` e `Permissions-Policy`, mas **nenhuma** `Content-Security-Policy`. É a
  lacuna de defesa em profundidade mais visível — decidir se entra agora (depende do item de
  nonce acima) ou se vira dívida registrada.
- **`quality.lint` sem `--max-warnings=0`** (§2, §12): aviso do ESLint (ex.: `no-console`)
  passa pelo gate de qualidade e só é barrado no `pre-commit`. Decidir se o gate deve ser tão
  estrito quanto o hook, ou alinhar os dois.
- **Guards `no-restricted-imports` não configurados** (§9): `process.env` fora de
  `src/lib/env.ts` e `react-redux` cru fora de `src/store/hooks.ts` são hoje disciplina, não
  build. Decidir se viram regra de lint.
- **`tests/support/` ainda não existe** (§7): o perfil prescreve builders e
  `renderWithProviders` ali na primeira duplicação. Confirmar que o local é este antes de o
  segundo teste de componente nascer.
- **Companheiro do perfil-irmão ausente:** `guidelines/project/backend/_review/` está vazio,
  embora `node-22.md` referencie `_review/node-22.md`. Sinalizar ao `/keelson:init` — fora do
  escopo deste arquivo.
