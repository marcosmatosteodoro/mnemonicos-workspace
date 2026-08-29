# Lições do projeto

> Registradas pelo ciclo keelson após erro real (code review, retry, correção humana).
> Formato: uma lição por bloco, deduplicada — lição equivalente existente é atualizada,
> não duplicada.
>
> Uma lição só nasce de **erro que aconteceu aqui**. Não se importa lição de outro
> projeto: doutrina portável vira regra em `README.md`/perfil, não lição.

<!-- Adicionar lições abaixo desta linha -->

## [Testes] Sonda de investigação não nasce em `tests/**`; contagem de teste declara a árvore

**Erro:** um gate rodou uma sonda de perf (`tests/integration/zz-perf-probe.integration.test.ts`,
com `console.log` e um `expect(x).toBeTruthy()` tautológico) para investigar o custo de
consulta, deixou-a **untracked** no working tree, e o `testMatch` do
`jest.integration.config.ts` a recolheu: a corrida dava 47 testes, não os 46 declarados no
report da wave. Pego no re-review do gate 7 da Wave 3.
**Causa:** a sonda nasceu dentro de `tests/integration/` (o diretório que a config recolhe)
e ficou como untracked. Untracked não aparece em `git diff`, não entra em review, não vai
ao PR — **mas roda**. "46/46 limpo" fica indistinguível de "47/47 com um `toBeTruthy()`
junto"; sonda vermelha ou lenta seria atribuída ao código sob revisão.
**Solução:** (1) sonda/probe de investigação (perf, N+1, comportamento de driver) **não
nasce em `tests/**`** — vive no scratchpad da sessão e roda por caminho explícito; se
precisar do harness, nasce já com nome fora do `testMatch`. (2) quem declara contagem de
teste como evidência de gate declara junto a árvore de onde ela saiu — `git status
--porcelain` vazio (ou o resto, item a item). Contagem sem estado de árvore declarado não é
evidência reproduzível.
**Validade:** geral.
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0

## [Performance] `include`/`select` aninhado de relação não é 1 statement por padrão

**Erro:** `resolveAccessSession` (`src/modules/auth/auth.service.ts`) usava
`findUnique({ where: { accessTokenHash }, include: { user: true } })` — escrito como se
fosse uma consulta. Medido contra o Postgres real: **2 idas ao banco por requisição
autenticada** (SELECT em `sessions` + SELECT em `users`), no caminho mais quente do
sistema, dobrando o custo que DEC-003-002/TRISK-003-003 aceitaram como "uma consulta".
Ainda carregava `passwordHash` + 14 colunas não usadas. Pego no gate 10 da Wave 3 de PLAN-003.
**Causa:** o §10 do perfil ensinava o `select` aninhado como a correção do N+1 ("✅ uma
query") — e a afirmação é falsa por padrão: o Prisma resolve o aninhamento, mas em
statements separados, a menos que `relationJoins` esteja em `previewFeatures`. O teste de
integração reforçou o ponto cego por afirmar a **forma do objeto devolvido**, nunca a
contagem de idas ao banco (passa verde com 2 round-trips e 20 colunas).
**Solução:** (1) `select` explícito, sempre — só os campos usados. (2) Para 1 ida:
`previewFeatures = ["relationJoins"]` no `generator` + `relationLoadStrategy: 'join'`.
(3) Consulta em caminho **por requisição** (middleware de auth, resolvedor de contexto)
tem a contagem de round-trips FIXADA EM TESTE (`log: [{ emit: 'event', level: 'query' }]`
+ asserção sobre o nº de eventos) — asserção sobre o objeto devolvido não é prova de custo.
Âncora: `src/modules/auth/auth.service.ts` (`resolveAccessSession`, `refresh`). O §10 do
perfil foi corrigido.
**Ressalva (re-review do gate 10):** `previewFeatures = ["relationJoins"]` torna `join` o
**DEFAULT global** de toda consulta com relação — não é opt-in por consulta. Para relação
de **lista** (1-N de volume variável), o `LATERAL JOIN + JSONB_BUILD_OBJECT` nem sempre
vence as 2 idas da estratégia `query`: ao introduzir `select`/`include` de lista, medir as
duas e fixar a escolhida explicitamente. E `relationLoadStrategy: 'query'` só emite 2
SELECTs quando a linha relacionada **existe** — o teste de contagem semeia o registro real
antes de contar, senão a asserção `=== 1` vira verde permanente.
**Validade:** enquanto o backend usar Prisma 7 com `relationJoins` ligado.
**Estado:** ativa
**Contadores:** confirmada 1 · contestada 0

## [Segurança] Guarda de estado de conta/sessão: enumerar por DADO, não por rota

**Erro:** a checagem de `User.disabledAt` entrou em `auth.service.login` e em
`resolveAccessSession`, mas ficou de fora de `auth.service.refresh` — que também **emite
credencial**. Conta desativada, sessão não-revogada, dentro do prazo absoluto do refresh:
renovava indefinidamente (200 + família viva). Pego no gate 8 da Wave 3 de PLAN-003.
FR-002-007 é literal: "rejeitar **qualquer** requisição que a apresente".
**Causa:** o AC foi lido como "o middleware de autenticação rejeita" e a prova foi ancorada
só no resolvedor; a superfície que **emite** credencial (renovação) não foi enumerada. O
compensador imaginado — a desativação revogar as sessões (`revokeAllSessions`) — ainda não
existia no código (mora numa TASK futura). Compensador que mora numa TASK futura **não conta
como controle presente**.
**Solução:** ao introduzir uma guarda de estado de conta/sessão, enumerar por **dado**, não
por rota — toda função que lê `User`/`Session` para autenticar, renovar ou emitir credencial
recebe a mesma guarda **no mesmo diff**, cada uma com prova de negação (fixture de 2
instâncias, mutação do filtro reprova). Consumidores de sessão de `auth.service`:
`login`, `resolveAccessSession`, `refresh`, `changeOwnPassword` — é o checklist de qualquer
novo predicado de negação.
**Validade:** enquanto `auth.service.ts` for a fronteira de autenticação.
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0

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
**Segundo eixo (gate 7 da Wave 3):** quando a decisão com precedência é **consumida em outra
camada** que ata um EFEITO a cada ramo (persistência, auditoria), a regra do par coincidente
vale **de novo na camada consumidora** — fixture que satisfaça os dois predicados ao mesmo
tempo e asserção sobre o **efeito** (linhas revogadas, evento auditado), não só sobre a
exceção. Sinal de que o par existe: o consumidor volta a ler, dentro de um `case`, os mesmos
campos que a função pura já examinou (`session.rotatedAt`/`session.revokedAt`) — predicado
duplicado é par não provado. Alternativa que elimina a classe: devolver o par no próprio tipo
da decisão (`{ kind: 'expired'; reused: boolean }`). Reincidiu em `auth.service.ts` (par
`expired ∧ reuse`): apagar o bloco de revogação+auditoria deixava as duas suítes verdes.
**Validade:** geral (padrão de teste).
**Estado:** ativa
**Contadores:** confirmada 1 · contestada 0

## [Testes] Sintoma novo só vira "dívida conhecida" depois de reproduzido sem o diff

**Erro:** o aviso "Jest did not exit one second after the test run" foi atribuído no report
de wave à dívida do harness (TASK-003-016). Três execuções isoladas mostraram que ele nasce
em `tests/integration/auth.service.integration.test.ts` — o único arquivo da wave que
exercita código de produção usando o singleton `src/lib/prisma.ts`, cujo `afterAll` só chama
`closeTestDb()` (o `testPrisma`), nunca o client da aplicação. Pego no gate 7 da Wave 3.
**Causa:** o sintoma foi assumido pré-existente sem controle negativo. "Conhecido" ficou
indistinguível de "introduzido agora", e um vazamento real de recurso ia ser arquivado como
dívida de outra task — ninguém o pagaria.
**Solução:** atribuir sintoma a dívida pré-existente exige **controle negativo** — rodar só
as suítes anteriores ao diff e mostrar o sintoma **ausente**. Corolário: suíte de integração
que exercita um `service` de produção fecha **todos** os pools que abriu (`await
prisma.$disconnect()` do client de `src/lib/prisma.ts` no `afterAll`, ao lado do `closeTestDb()`).
**Validade:** enquanto houver camada de integração que toque código de produção com o client singleton.
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
