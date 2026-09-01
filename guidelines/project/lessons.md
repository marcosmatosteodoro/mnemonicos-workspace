# Lições do projeto

> Registradas pelo ciclo keelson após erro real (code review, retry, correção humana).
> Formato: uma lição por bloco, deduplicada — lição equivalente existente é atualizada,
> não duplicada.
>
> Uma lição só nasce de **erro que aconteceu aqui**. Não se importa lição de outro
> projeto: doutrina portável vira regra em `README.md`/perfil, não lição.

<!-- Adicionar lições abaixo desta linha -->

## [Arquitetura] Barreira que nega com base num registro exige o registro completo antes da 1ª requisição

**Erro:** o deny-by-default (`ROUTE_ROLES`) era populado por efeito colateral **dentro do
handler de request** de `requireRole`, mas quem consulta o registro (`requireAuth`) roda
**antes** dele na cadeia Express. O registro nunca era escrito: `requireAuth` negava todo
caminho não declarado e o deny-by-default degenerava em **deny-tudo** (ADMIN válido →
`403 403 403`). 30 asserções verdes não acusaram — toda montagem de teste pré-declarava o
caminho à mão. Pego no gate 8 + gate 5/7 da Wave 4 (PLAN-003).
**Causa:** auto-registro por efeito colateral de middleware foi tratado como equivalente a
registro na montagem. Numa cadeia Express a ordem de execução, do ponto de vista de quem
**consome** o registro, é o inverso da ordem de declaração: o guard mais externo decide
antes que o mais interno tenha existido uma vez.
**Solução:** (1) declaração é ato de **montagem** — `requireRole(method, path, ...roles)`
declara na avaliação da chamada, nunca dentro do handler; registro **selado** após o boot.
(2) O caminho feliz de **MONTAGEM** é oráculo distinto do caminho feliz de REQUEST: toda
TASK que introduz registro/efeito-colateral consumido por um middleware **anterior** na
cadeia ganha um teste que monta a app real (sem popular o registro à mão) e prova o 200
legítimo — o mutante que move a escrita para o handler o mata.
**Validade:** geral (qualquer registro consultado por um passo anterior na cadeia).
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0

## [Segurança] "Declarado" não é "autorizado"; prova de gate de autz exige topologia adversarial

**Erro:** o deny-by-default foi implementado como "o caminho está no registro?"
(`rolesForPath(path) === undefined`) em vez de "este papel pode este método neste
caminho?"; `requireAuth` nunca comparava `req.auth.role` com o conjunto. Rota declarada
`ADMIN` montada sem o guard + sessão EDITOR → passava. A prova do AC usava um caminho
isolado — a topologia em que o bug não aparece. Gate 8 da Wave 4 (PLAN-003).
**Causa:** registro de presença confundido com decisão de autorização; o teste do AC
construiu a topologia mais simples possível, sem rota irmã, sem 2º método, sem rota
declarada porém desguarnecida.
**Solução:** (1) toda leitura de permissão devolve o **conjunto** de papéis e o guarda
compara o papel da sessão contra ele — "declarado" nunca implica "autorizado"; a leitura
que devolve "nenhuma permissão exigida" **falha fechada**. (2) Prova de gate de autz exige
a topologia adversarial mínima: rota irmã estática sem guarda ao lado de uma rota com
`:param`; segundo método HTTP no mesmo caminho; rota declarada porém sem o middleware de
papel; e o registro não ganha chave após o boot.
**Validade:** geral (autorização por rota/ação).
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0

## [Segurança] Chave de decisão de autz que ganha uma dimensão: todos os leitores ganham, inclusive a allowlist de exceção

**Erro:** ao endurecer o `ROUTE_ROLES` acrescentando a dimensão "método HTTP" à chave
(`"<MÉTODO> <caminho>"`), a dimensão foi propagada ao registro e ao leitor (`rolesForPath`),
mas **não** à lista de exceção (`PUBLIC_PATH_ALLOWLIST` / `isPublicPath`), que continuou
comparando só o caminho — os 4 caminhos públicos dispensam sessão em **qualquer** verbo.
Hoje inerte (não há rota não-POST em `/auth/login`/`/auth/refresh` nem não-GET em
`/health*`), por isso nota do gate 8 da Wave 4, não achado.
**Causa:** a exceção é a superfície mais **larga** da barreira e é a mais fácil de esquecer
quando a chave da barreira evolui.
**Solução:** quando a chave de uma decisão de autorização ganha uma dimensão, **todos** os
leitores dessa decisão ganham a mesma dimensão — inclusive a allowlist de exceção.
Concretamente: chavear `PUBLIC_PATH_ALLOWLIST` por `"<MÉTODO> <caminho>"` e a suíte de
conformidade (COMP-003-019 / TASK-003-011) afirmar que cada entrada corresponde a
exatamente uma rota montada naquele método.
**Validade:** geral.
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0

## [Testes] Retry que reescreve arquivo de teste por mudança de assinatura entrega o inventário antes/depois dos `it()`

**Erro:** o retry que mudou a assinatura de `requireRole` reescreveu os dois arquivos de
teste e perdeu, sem que nada acusasse, o único caso que provava o ramo de omissão da chave
`userAgent` no evento de auditoria — **enquanto** o delta duplicava esse mesmo ramo para um
segundo arquivo. O mutante que neutraliza o ramo morria no commit pai e **sobreviveu** no
delta (regressão de prova). Pego no re-review do gate 1 da Wave 4.
**Causa:** mudança de assinatura força reescrita ampla do arquivo de teste; a atenção vai
para os casos **novos** exigidos pelo achado, a suíte fica maior e mais verde, e a
subtração some. Contagem crescente lê-se como cobertura crescente; nenhuma leitura do diff
acusa um caso que simplesmente não foi reescrito.
**Solução:** retry que reescreve arquivo de teste por mudança de assinatura entrega o
**inventário antes/depois** dos nomes de `it(...)` (`git show <pai>:<arquivo>` vs. HEAD), e
cada nome ausente é classificado: renomeado (com o substituto citado), removido de
propósito (com o motivo) ou **perdido** (então volta). Regra de fecho: para todo ramo
condicional que sobreviva ao retry, o mutante que o neutraliza tem de morrer **no delta E
no commit pai** — morrer só no pai é regressão de prova.
**Validade:** geral (qualquer retry que reescreva suíte por mudança de contrato).
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0

## [Testes] `lint-staged` grava LF com `core.autocrlf=true` → sujeira falsa pós-commit

**Erro:** o hook de pre-commit (`prettier --write` + `eslint --fix` via lint-staged) grava
os arquivos com fim-de-linha **LF**, mas o checkout usa `core.autocrlf=true`; logo após o
commit os arquivos reaparecem como ` M` em `git status --porcelain` (conteúdo idêntico,
`git diff` vazio), exigindo `git checkout --` para reconciliar. Verificações de "árvore
limpa pós-commit" na closure veem sujeira falsa.
**Causa:** desalinhamento entre `endOfLine` do prettier / `.gitattributes` / `core.autocrlf`.
**Solução:** alinhar — `endOfLine: 'lf'` no prettier + `* text=auto eol=lf` em
`.gitattributes` para os globs de código, ou `core.autocrlf=input` no ambiente. Enquanto
não alinhado: a closure roda `git checkout --` nos arquivos recém-commitados antes de
aferir a árvore.
**Validade:** projeto (toolchain do `mnemonicos-backend`/`-frontend`).
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0

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
precisar do harness, nasce já com nome fora do `testMatch`. Gate cujo mecanismo de prova
**escreve arquivo** (sonda, probe, mutante, fixture temporária) roda em **`git worktree`
isolada** (decisão 4.134) — e a worktree isolada **não junta `node_modules` por junction**:
`npm ci`/`npm install` dentro dela opera no diretório físico compartilhado e poda deps
(nesta base, `@babel/core` transitivo do `jest-snapshot`, quebrando `test:integration`
para todos). O pacote de contexto da rodada **declara isso no despacho** — não como
disciplina de limpar depois, que não cobre a janela de leitura. **Gate nunca roda
`npm install`/`npm ci` nem edita `package*.json` na árvore principal**; dep de
instrumentação ausente → reporta o bloqueio, não conserta. (2) quem declara contagem de
teste como evidência de gate declara junto a árvore de onde ela saiu — `git status
--porcelain` vazio (ou o resto, item a item). Contagem sem estado de árvore declarado não é
evidência reproduzível.
**Validade:** geral.
**Estado:** ativa
**Contadores:** confirmada 4 · contestada 0
**Reincidência:** Wave 3 (`zz-perf-probe`, gate 10), Wave 4 (`zz-sec-probe`, gate 8), Wave 5
(2×: `performance-engineer` fez `npm install` + `@babel/core` no `package.json` da árvore
principal; e um gate da re-review rodou `npm ci` em worktree com `node_modules` junctionado,
podando `@babel/core` — `test:integration` quebrou nas duas), Wave 6 (`tests/zz-probe.test.ts`
apareceu e sumiu na árvore principal do backend **durante o re-review da própria wave que
registrou a lição** — a sonda sondava o achado sob revisão; + um worktree órfão `.review-wt`
de outra sessão com cópia do `.env` real, podado pelo `security-engineer`). Os revisores são
despachados com "worktree isolada" explícito e a reincidência continua: a regra tem de ser
**mecânica** no template de despacho (worktree já criada + comando literal; `git status
--porcelain` colado no report como campo do YAML; `testPathIgnorePatterns: ['zz-.*']` nas
configs Jest) — roteada ao `agile-coach`.

## [Testes] Asserção de invariante executada na carga do módulo exige DOIS testes: função + wiring

**Erro:** `assertDenyByDefault(apiRoutes)` (o passo que a DEC-003-005 EMENDA chama de
"fechamento pleno" — falha o boot se uma rota não-pública não tiver declaração exata) foi
provado só como **função** — dois testes a chamavam à mão sobre a árvore. Apagar a **única
linha** que a arma no boot (`assertDenyByDefault(apiRoutes);` no fim de `routes.ts`) deixava
a suíte 21/21 verde. Pego no re-review do gate 1 da Wave 6.
**Causa:** guarda que age por **efeito colateral na carga do módulo** não tem quem a chame no
teste. O teste que chama a função a mão prova a REGRA e dá sensação de cobertura; a
**existência da chamada de produção** fica sem oráculo. O contraste denuncia: o irmão
`sealRouteRoles()`, uma linha abaixo, tinha teste de wiring (`declareRouteRoles` pós-boot
lança) porque seu efeito é observável por uma API; o de `assertDenyByDefault` só por
ausência de exceção.
**Solução:** `assertX(...)` no topo de um arquivo de montagem exige **dois** testes: (a) a
função reprova a topologia ruim e aceita a boa; (b) o módulo de produção, **reimportado**
sob a topologia ruim (`jest.isolateModules`/`isolateModulesAsync` + `jest.doMock`, ou
`expect(() => createApp()).toThrow()`), **lança**. Critério de aceite = o mutante: comentar
a linha de chamada deixa **esse** teste vermelho. Complementa — não substitui — a lição
"[Arquitetura] Barreira que nega com base num registro exige o registro completo antes da 1ª
requisição": aquela cobre QUANDO o registro é populado, esta cobre SE a guarda foi armada.
Referência: `mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts`
(o wiring de `sealRouteRoles`, e o `[retry CR1]` de `assertDenyByDefault`).
**Validade:** geral (qualquer invariante armada na carga do módulo).
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0

## [Segurança] Guard de navegação (proxy/middleware) enumera o que GUARDA, nunca o que dispensa

**Erro:** o `config.matcher` do `proxy.ts` foi escrito como catch-all por **exclusão**
(`/((?!login|_next/...).*)`) para alcançar o route group `(interno)` (que não aparece na
URL) — e com isso passou a exigir cookie na home pública `/` e em toda página pública
futura, sem que nenhum teste dissesse o que deve seguir **livre**. Depois, o retry inverteu
para enumeração explícita (`['/studio/:path*','/gestao/:path*']`), o que remove a proteção
da home mas troca "nega tudo por engano" por "libera tudo por engano": rota interna nova
fora dos dois prefixos nasce **sem** o redirect e nada falha. Pego nos gates 1/4/5 e 8 da
Wave 6.
**Causa:** deny-by-default é a regra certa na API e a regra **errada** no site público — e o
mesmo time acabara de aplicá-la no backend na mesma wave. Como `(grupo)` não é endereçável
por matcher, os dois extremos (exclusão / enumeração à mão) deixam o default frágil: cada
página nova — pública ou interna — depende de alguém lembrar de mexer na lista.
**Solução:** o matcher **enumera os prefixos internos**, e a lista é **derivada** de um
símbolo único compartilhado com o layout do grupo `(interno)` (não grafada à mão em dois
lugares). O teste do matcher afirma os **dois** lados: as rotas internas são guardadas **e**
`/` (e toda rota pública existente) **não** é; e enumera os segmentos de `src/app/(interno)/`
falhando se algum não estiver coberto — a mesma régua de `assertDenyByDefault`/
`route-authz-matrix` no backend. Rota nova sem asserção de "segue livre" (ou "é guardada",
conforme o lado) é regressão esperando acontecer. Referência: `mnemonicos-frontend/src/proxy.ts`
+ `src/proxy.test.ts`; consumidor da régua: TASK-003-015.
**Validade:** geral (proxy/middleware de Next; qualquer guard de borda por padrão).
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0

## [Segurança] Constante de segurança espelhada entre repos declara a fonte e tem teste de divergência

**Erro:** o retry do S1 (Wave 6) excluiu `/auth/login`, `/auth/refresh` **e `/auth/logout`**
da máquina de re-autenticação do frontend, citando `PUBLIC_PATH_ALLOWLIST` do backend como
"fonte canônica" — mas `POST /auth/logout` **não** está nessa allowlist, é rota protegida.
O espelho divergiu da fonte que ele próprio declara, e o logout virou **no-op silencioso**:
com o access expirado e o refresh vivo, "Sair" devolve 401, a guarda nova o engole sem
renovar, o handler de `logout` nunca roda, a família de refresh não é revogada e os cookies
não são limpos — a próxima requisição ressuscita a sessão. Pego no re-review do gate 8 da
Wave 6 (regressão aberta pelo próprio retry).
**Causa:** constante de segurança duplicada à mão entre `mnemonicos-backend` e
`mnemonicos-frontend` (como os tipos de domínio), sem prova que compare as duas listas; e a
correção suprimiu um caminho de código compartilhado (o refresh silencioso) sem enumerar
**todos** os chamadores desse caminho — corrigiu o login e mudou o logout junto, sem teste
para o 401 de logout.
**Solução:** toda constante de segurança espelhada entre os dois repos (allowlist de caminho
público, enums de papel, nomes de cookie) obedece a duas obrigações: (1) o espelho **declara
a fonte canônica** E tem teste que **falha quando diverge** dela — entrada a mais no espelho
é defeito, não conveniência (se um caminho entra por decisão do cliente e não da fonte, o
comentário diz isso explicitamente e o teste de divergência o exclui da comparação); (2) fix
que adiciona uma **guarda de curto-circuito** num despachante compartilhado (baseQuery,
middleware, interceptor) **enumera todos os chamadores afetados** e prova o caminho de erro
de cada um, não só o que motivou o achado. Referência: `mnemonicos-frontend/src/store/api.ts`
(`PUBLIC_AUTH_PATHS`) × `mnemonicos-backend/src/http/public-paths.ts` (`PUBLIC_PATH_ALLOWLIST`);
`guidelines/core/SECURITY.md` "Guarda no sink" / "Acesso por registro".
**Validade:** geral (constante/contrato espelhado entre repos).
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
**Contadores:** confirmada 2 · contestada 0
**Reincidência (gate 1 da Wave 5, `disableUser`):** `disableUser` foi reescrita no retry
com 3 guards em ordem declarada (`id == null → 404` · `disabledAt != null → no-op` ·
`role == 'ADMIN' && activeAdmins <= 1 → 409`); o par `disabledAt != null` × `último ADMIN
ativo` **coincide e é alcançável** (ADMIN já desativado + 1 ADMIN ativo restante) e ficou
sem caso — o mutante que troca a ordem sobreviveu. Corolário para quem escreve o card:
função com ≥3 guards em ordem declarada → o "Critério de pronto" **enumera os pares que
podem coincidir** (com o mutante de reordenação como aceite), nunca "um caso por ramo".

## [Testes] Prova de corrida/exclusão nasce na fronteira da invariante, e o mutante roda pelo comando do critério

**Erro:** o teste de exclusão mútua da guarda do último ADMIN semeou **3 ADMINs e
desativou os 3** em concorrência, afirmando `count(ativos) >= 1` no fim. O mutante
check-then-act (`count` fora da transação — perde 1 das 3 corridas) **passou** na suíte:
2 vitórias já bastam para `>= 1`. Pego no re-review do gate 1 da Wave 5 de PLAN-003; o
mesmo mutante **matava** o teste rodado isolado com `jest -t "..."`.
**Causa:** (1) fixture com folga — com N sujeitos e invariante `>= 1`, o teste tolera N−1
violações do mecanismo; a corrida foi dimensionada por quantidade, não pela **fronteira**
onde uma única vitória a mais já viola. (2) O mutante nomeado foi rodado com `-t` isolado
na fixação, e o oráculo de corrida depende do **contexto de execução** (ordem/paralelismo
das outras specs no arquivo) — mata isolado, sobrevive no arquivo inteiro.
**Solução:** prova de corrida/limite/cardinalidade-mínima nasce **na fronteira**: para
`count(ativos) >= 1`, o cenário é o **penúltimo** (exatamente 2 ativos, N concorrentes do
mesmo alvo) — mesmo raciocínio de "enumerar por DADO ativo" já registrado aqui. E o
mutante nomeado num "Critério de pronto" roda **pelo comando do critério** (arquivo/suíte
inteira), **nunca** `-t "..."` isolado — senão o critério aprova um oráculo que só mata
fora do contexto real (decisão 4.186). Âncora: `users.integration.test.ts` [retry S1].
**Validade:** geral (teste de concorrência/invariante).
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0

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

## [Testes] Valor de configuração lido por analisador de build só é provado por oráculo que passe pelo build

**Erro:** na Wave 7 de PLAN-003, `config.matcher` do `proxy.ts` passou a ser derivado por
`INTERNAL_ROUTE_PREFIXES.flatMap(...)` de um símbolo compartilhado. Cinco testes novos
ficaram verdes provando a derivação — e `next build` **abortou**
(`matcher needs to be a static string or array of static strings`): o Next lê `config` por
análise estática do AST e nunca executa o módulo. O guard de navegação não existia no app
buildado; a suíte verde era falso oráculo.
**Causa:** o teste elegeu como oráculo um **modelo** do consumidor (um `toRegExp` caseiro
sobre o valor obtido em runtime) em vez do consumidor. Jest executa o módulo; o Next não. É
a forma da lição "função + wiring" (abaixo) num eixo novo: valor lido em **tempo de
build**. E a EMENDA COMP-003-022 pediu "derivado de um símbolo" sem dizer em que momento a
derivação pode acontecer — o que tornava a expressão em runtime uma leitura literal do
critério.
**Solução:** valor que um analisador de build consome — `config` de
`proxy.ts`/`middleware.ts`, route segment config, `generateStaticParams` — só é provado por
um oráculo que passe pelo build:
- o **valor no arquivo é literal** (array de strings literais / objeto literal) — nenhuma
  chamada de função, spread ou template com expressão dentro do `config`;
- "derivado de um símbolo" = o **teste** assere a equivalência literal↔símbolo (oráculo de
  defasagem: mutar o literal sem tocar o símbolo → vermelho), **ou** um codegen versionado
  em build gera o literal;
- teste de **wiring** obrigatório: `extractExportedConstValue(parse('src/proxy.ts'), 'config')`
  devolve `value` e não `unsupported` — ou `quality.build` (`npm --prefix mnemonicos-frontend
  run build` → exit 0) no critério de pronto da TASK.
Referência: `mnemonicos-frontend/src/proxy.ts` + `src/proxy.test.ts`;
`guidelines/project/frontend/next-16.md` §6.3 e §11.
**Validade:** enquanto o frontend for Next App Router com Turbopack (config por AST estático).
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0

## [Testes] Predicado de decisão de UI a partir de estado de RTK Query só se prova no componente montado

**Erro:** o predicado que decide redirect/render do `InternalShell` (`computeMissingSession`)
foi extraído como **função pura** e provado sobre `api.endpoints.me.select()` da store. O
mutante (guarda `isUninitialized`/`isFetching` removida) morria nesse teste e **sobrevivia
no componente montado** — e um bug real de AC-002-027 (falha transitória de `logout` sem
feedback: `resetApiState()` no `finally` desmonta `LogoutControl` e destrói o `useState`
`hasFailed`) ficou **verde na suíte**.
**Causa:** o estado que o teste puro fixava (`isUninitialized: true` logo após
`resetApiState()`) só existe **sem subscritor montado**. Com o componente montado, o RTK
Query re-subscreve e re-busca `me` no mesmo flush — `isUninitialized` nunca é `true` em
produção. Testar o predicado isolado da store montada troca o consumidor real (o ciclo de
vida do hook: re-subscrição + refetch pós-reset é *parte do comportamento sob prova*) por
um modelo dele. É a lição "função + wiring" (acima) em tempo de render. Agravante: a
extração criou export de produção cuja única razão de existir era o teste mais fraco — o
que faz a substituição parecer rigor.
**Solução:**
- Predicado que decide render/navegação a partir de estado de RTK Query → oráculo que passa
  pelo **componente MONTADO** contra a `api` real (store real via `makeStore()` + `fetch`
  mockado). O teste da função pura **complementa**, nunca substitui. Critério de aceite: o
  mutante morre no teste **montado**.
- `resetApiState()` (login/logout) pode **desmontar a subárvore dentro de um único flush** —
  polling de 1ms não vê. Asserção de presença no DOM **não acusa**: o oráculo precisa de
  contador de montagem/efeito **ou** de asserção sobre estado local que a remontagem
  destruiria (`useState` de erro sobrevivendo).
- Harness: `fetch`/`Response`/`Request`/`Headers` em jsdom exigem um `testEnvironment`
  custom estendendo `jest-environment-jsdom` e injetando esses globais do realm Node —
  **sem dependência nova**.
Referência: `mnemonicos-frontend/src/components/internal-shell.tsx` +
`src/components/internal-shell.integration.test.tsx`.
**Validade:** enquanto o frontend usar RTK Query com componentes que ramificam em
`isLoading`/`isError`/`data`.
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0

## [Testes] Comentário que afirma paridade entre os dois repos só vale se o teste LER as duas fontes

**Erro:** `mnemonicos-frontend/src/store/api.ts` comenta que `PUBLIC_AUTH_PATHS` é
"espelho literal de `PUBLIC_PATH_ALLOWLIST` do backend" e que "o teste de divergência fixa
a igualdade literal". O teste (`api.test.ts`) só faz
`expect(PUBLIC_AUTH_PATHS).toEqual(['/auth/login','/auth/refresh'])` — um snapshot do
frontend contra ele mesmo. Divergência real entre os repos não fica vermelha. (Achado da
convergência de fecho de PLAN-003; não bloqueou — nenhum FR/AC exige essa paridade e o
backend tem tripwire próprio em `route-authz-matrix`.)
**Causa:** espelhar uma constante do outro repo é barato; **provar** o espelho exige ler o
arquivo do outro repo. Quando o teste fica só no lado local, ele documenta a intenção em
vez de sustentá-la, e o comentário congela a crença de que a rede de proteção existe.
**Solução:** comentário que afirma paridade cross-repo → o teste **lê as duas fontes**. O
padrão de referência já está no repo: `mnemonicos-backend/tests/unit/domain-types-parity.test.ts`
resolve o caminho do outro repo e **lança** se o arquivo não existir (falha alto, nunca
verde vazio). Aplicar a qualquer literal duplicado por fronteira de repositório
(`PUBLIC_AUTH_PATHS` × `PUBLIC_PATH_ALLOWLIST`, nomes de cookie, chaves de serialização).
Alternativa aceitável quando a paridade não é requisito: suavizar o comentário para
descrever o que o teste de fato garante.
**Validade:** enquanto houver constantes espelhadas à mão entre `mnemonicos-backend` e `mnemonicos-frontend`.
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0

## [Segurança] Guarda de curto-circuito com estado de módulo + janela temporal exige três oráculos

**Erro:** o fix do V5 (BRIEF-004) adicionou uma flag de módulo `justLoggedOut` no
`baseQueryWithReauth` — setada no logout de sucesso, consultada para devolver o 401
seguinte sem `refresh`/redirect, limpa por `setTimeout(2000ms)`. Entrou com prova do
**efeito** (401 suprimido → `/login` sem `?sessao=expirada`) mas **sem** prova da
**condição de ativação** (só no ramo de sucesso): um mutante que movesse
`justLoggedOut = true` para o `catch`/`finally`/antes do `try` sobrevivia à suíte inteira
— o caso de logout 500 não espera redirect de qualquer jeito, e o caso de sessão morta já
tinha o `reauth.redirect` agendado pelo `setTimeout` do `baseQueryWithReauth` **antes** do
`queryFulfilled` rejeitar. A expiração da flag só era coberta por vazamento de estado de
módulo entre `it()` do mesmo arquivo, via `jest.runOnlyPendingTimers()` do `afterEach`.
**Causa:** o §6.3 do perfil mandava "enumerar todos os chamadores e provar o caminho de
erro de cada um" (lição da Wave 6), mas uma guarda com **estado temporal** tem três
propriedades independentes — quando **liga**, o que **suprime**, quando **desliga** — e só
a do meio tinha oráculo.
**Solução:** guarda com flag de módulo + janela temporal exige teste próprio para cada:
- **ativação**: o ramo que **não** deve ligar a flag (logout que falhou / erro de rede)
  mantém a expulsão intacta — mutante "flag no `catch`/`finally`/antes do `try`" fica
  vermelho. Concretamente: logout 500 → depois requisição autenticada 401 + refresh 401 →
  exigir `reauth.redirect('/login?sessao=expirada')` chamado.
- **supressão**: enquanto ativa, 401 devolvido sem `refresh` nem redirect (o oráculo que
  já existia).
- **expiração**: teste que **avança o timer** e confirma o retorno ao normal — nunca
  apoiado em ordem de `it()` nem no `runOnlyPendingTimers()` do `afterEach`, que mascara
  flag presa como falso **verde** (não falso vermelho).
Corolário: limpar a flag também no ramo de sucesso do evento oposto (aqui,
`login.onQueryStarted`) fecha a fragilidade de isolamento e um resíduo real (401
imediatamente pós-login dentro dos 2s seria engolido). Referência:
`mnemonicos-frontend/src/store/api.ts` (`justLoggedOut`) + `next-16.md` §6.3.
**Validade:** enquanto o `baseQueryWithReauth` usar flags de módulo para condicionar a re-auth.
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0
