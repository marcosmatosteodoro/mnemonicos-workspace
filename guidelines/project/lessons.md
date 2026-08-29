# Lições do projeto

> Registradas pelo ciclo keelson após erro real (code review, retry, correção humana).
> Formato: uma lição por bloco, deduplicada — lição equivalente existente é atualizada,
> não duplicada.
>
> Uma lição só nasce de **erro que aconteceu aqui**. Não se importa lição de outro
> projeto: doutrina portável vira regra em `README.md`/perfil, não lição.

<!-- Adicionar lições abaixo desta linha -->

## [Testes] Árvore de decisão com precedência: um caso por PAR de ramos que coincide

**Erro:** `session-rotation.ts` decide entre `expired → reuse → replay-grace → rotate`.
Os testes cobriam um caso por ramo, e o mutante que **inverte `reuse` e `replay-grace`**
sobreviveu à suíte inteira (controle positivo — mutante que ignora `revokedAt` — morreu).
Pego no gate 1 da Wave 2 de PLAN-003.
**Causa:** ordem de avaliação não é comportamento de ramo, é comportamento do **cruzamento**.
Sem um fixture que satisfaça os dois predicados ao mesmo tempo (aqui: `revokedAt != null`
**e** `rotatedAt` dentro da janela de graça), a árvore pode ser reordenada livremente sem
nenhum teste ficar vermelho. "Um caso por ramo" satisfaz a leitura do critério de pronto e
mesmo assim deixa o defeito invisível.
**Solução:** toda árvore de decisão com precedência declarada (DEC, comentário, "Implementação
sugerida") ganha **um caso por par de ramos que pode coincidir** — não só um por ramo —, e o
nome do teste enuncia quem vence. Fechamento verificável: o mutante que troca a ordem daquele
par morre. Vale para `session-rotation.ts` e para DEC-003-005 (deny-by-default por papel) na
TASK-003-011.
**Validade:** geral (padrão de teste).
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0

## [Testes] Infra de teste que faz DDL/TRUNCATE valida o alvo na carga do módulo, fail-closed

**Erro:** o harness de integração (`tests/integration/db.ts`) faz
`TRUNCATE ... RESTART IDENTITY CASCADE` em todas as tabelas do banco a que
`TEST_DATABASE_URL` apontar, e `global-setup.ts` faz `CREATE DATABASE` + `migrate deploy`.
A única verificação de que o alvo era o banco descartável (`current_database() === 'mnemonicos_test'`)
vivia num `it()` que roda **depois** do `beforeEach(resetDb)` — quando o TRUNCATE já rodou.
`npm run validate` passou a encadear `test:integration`. Pego nos gates 8 e 7 da Wave 2 de PLAN-003.
**Causa:** proteção colocada como asserção de teste (a posteriori) onde o padrão exige negar
por padrão **antes** da primeira escrita.
**Solução:** infra de teste que executa DDL ou TRUNCATE valida o alvo **no módulo que resolve
a conexão** (nome do banco == o descartável esperado; host loopback) e **lança na carga** se
divergir — nunca `expect()` dentro de um caso. A asserção de teste fica como 2ª linha, não a única.
**Validade:** enquanto houver camada de teste de integração com banco real (`*.integration.test.ts`).
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0

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
