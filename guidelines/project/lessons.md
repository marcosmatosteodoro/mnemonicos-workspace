# Lições do projeto

> Registradas pelo ciclo keelson após erro real (code review, retry, correção humana).
> Formato: uma lição por bloco, deduplicada — lição equivalente existente é atualizada,
> não duplicada.
>
> Uma lição só nasce de **erro que aconteceu aqui**. Não se importa lição de outro
> projeto: doutrina portável vira regra em `README.md`/perfil, não lição.

<!-- Adicionar lições abaixo desta linha -->

## [Segurança] Flag de segurança booleana vinda de env nunca usa `z.coerce.boolean()`

**Erro:** `COOKIE_SECURE: z.coerce.boolean().default(isProduction)` em `src/config/env.ts`.
`z.coerce.boolean()` é `Boolean(input)`: `"false"` / `"0"` coagem para `true`, e `""`
(string vazia — não é `undefined`) coage para `false` **sem** o `.default()` se aplicar.
Em produção, `COOKIE_SECURE=""` no painel de deploy → cookie de sessão sem `secure`, em
silêncio (fail-open). Pego no gate 8 da Wave 1 de PLAN-003.
**Causa:** coerção aplicada por simetria com os campos numéricos vizinhos
(`z.coerce.number()`), onde é correta. Para boolean a coerção do JS não tem a semântica
esperada. O teste exercitou só o caminho do default (`delete process.env.X`), nunca o
caminho com valor fornecido — o defeito era invisível para a suíte.
**Solução:** booleano de env usa `z.enum(['true','false']).default(<'true'|'false'>).transform(v => v === 'true')`
— valor inválido derruba o boot (fail-fast do §6.4) em vez de virar `false` silencioso.
Todo campo de env que governa controle de segurança exige teste do caminho **com valor
fornecido** (incluindo string vazia), não só do default.
**Validade:** enquanto o backend validar env com Zod em `src/config/env.ts`.
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0

## [Exploração] Repos symlinkados não são atravessados por varredura ingênua

**Erro:** o `product-analyst`, na forja do BRIEF-001, afirmou que os diretórios de
`codePaths` "não existem no workspace" e que "os dois repositórios ainda não existem no
disco" — e construiu parte da crítica sobre isso. Os dois repos existem, com suíte verde e
schema Prisma completo, lidos pelo `code-scout` na mesma rodada.
**Causa:** `mnemonicos-backend` e `mnemonicos-frontend` são **symlinks** para fora do
workspace (ver `.gitignore`), e ferramenta de listagem/glob não segue symlink por padrão.
Quem lista a raiz vê dois links e conclui ausência.
**Solução:** para varrer código nestes repos, use o caminho **dentro** do link
(`mnemonicos-backend/src/...` direto no Read/Grep, que resolve o link) ou `find -L`. E,
sobretudo: **ausência detectada por varredura não é fato** neste workspace — antes de
afirmar que algo não existe, confirme com leitura direta do caminho. Quem passa contexto a
subagente que vai varrer código deve avisar que os repos são symlinks.
**Validade:** enquanto os dois repos entrarem no workspace por symlink (ver `.gitignore`).
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0
