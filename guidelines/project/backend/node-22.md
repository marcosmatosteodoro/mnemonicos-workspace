---
lang: node
version: "22"
charter: 0.5.1
generated-by: staff-engineer
reviewed: false
---

# Node 22 + TypeScript 6 — Perfil de linguagem (backend)

> Instância do `QUALITY-CHARTER.md` (v0.5.1) para a stack de backend deste projeto:
> **Node 22 LTS · TypeScript 6 · Express 5 · Prisma 7 · PostgreSQL · Zod 4 · Jest 30 ·
> ESLint 9**.
>
> ⚠️ **`reviewed: false`** — perfil **gerado** (`staff-engineer`), não curado. Toda
> afirmação de segurança que não pôde ser confirmada com alta confiança carrega a tag
> inline `⚠️ não confirmado`; o roteiro de conferência humana mora no companheiro
> [`_review/node-22.md`](_review/node-22.md).
>
> **Precedência:** este perfil cobre o **idiomático geral** da stack. As decisões
> **específicas deste serviço** (camadas `schema → service → routes`, `AppError` vs 500
> genérico, autorização por `userId` de sessão, protocolo de migração) moram em
> [`README.md`](README.md) — e **em conflito, o README vence este perfil**.

---

## 1. Identidade & versão

O alvo é **Node.js 22 LTS** ("Jod"; `engines.node: ">=22.0.0"`, `.nvmrc` = `22`) com
**TypeScript 6** em `strict`, emitindo **CommonJS** (`module: nodenext` + ausência de
`"type": "module"` no `package.json` ⇒ o resolver trata `.ts` como CJS).

**Recursos desta versão que se DEVE preferir:**

| Recurso | Uso | Desde |
|---------|-----|-------|
| `node:crypto` → `randomUUID()`, `timingSafeEqual()`, `scrypt()` | Identificadores e comparação/derivação sem dependência externa | ≤20 |
| `fetch` global (undici) + `AbortSignal.timeout(ms)` | HTTP client de saída **sempre com timeout** | 18 |
| `require(esm)` habilitado por padrão | Consumir lib ESM-only de código CJS (grafo sem top-level `await`) | 22.12 |
| `fs.glob` / `fs.globSync` | Varredura de arquivos sem `glob`/`fast-glob` | 22 |
| `--env-file=.env` / `process.loadEnvFile()` | Carregar env em script pontual sem `dotenv` | 22 (`--env-file-if-exists` em 22.9) |
| `node --watch`, `node --run <script>` | Watch e execução de script sem nodemon/npm-run-all | 22 |
| `node:test` + `node:assert` | Runner nativo (**não é** o runner deste projeto — ver §7) | 20 (estável) |
| `structuredClone`, `Array.prototype.at`, `Array.fromAsync`, `Object.groupBy` | Substituem lodash em quase todo caso | ≤22 |
| `util.styleText` | Cor em CLI sem `chalk` | 22 |
| `AsyncLocalStorage` (`node:async_hooks`) | Contexto por request (request-id, usuário) sem passar parâmetro por 6 camadas | ≤20 |

**Do TypeScript 6** (última release baseada em JS, ponte para o compilador nativo 7.0):
os defaults mudaram — `target: es2025`, `module: esnext`, `types: []`, `rootDir` = pasta do
`tsconfig`. Este projeto **fixa** `target: ES2023`, `module: nodenext` e
`types: ["node","jest"]`, então os defaults novos não mordem. Ficaram **deprecados** (e
somem no TS 7): `target: es5`, `moduleResolution: node`/`classic`, `--baseUrl`,
`--outFile`, `--esModuleInterop false`, `--downlevelIteration`, `namespace`/`module` legado
e `import ... assert`. Nada disso **DEVE** aparecer em código novo.

**Construções que NÃO DEVEM mais aparecer:**

- `require()`/`module.exports` escritos à mão em `.ts` — use `import`/`export`; o emit CJS
  é problema do compilador, não do autor.
- `any` explícito ou implícito (`strict` + `recommendedTypeChecked` reprovam), `as` para
  calar o compilador, `@ts-ignore` (se inevitável, `@ts-expect-error` **com motivo**).
- `enum` do TypeScript em código novo — prefira `as const` + união de literais, ou o enum
  gerado pelo Prisma quando o valor vem do banco.
- `namespace`, decorators experimentais, `Promise` construída à mão em volta de callback
  (use `node:util.promisify` ou a API `fs/promises`).
- `child_process.exec`, `new Function`, `eval`, `vm` com entrada externa.
- Callbacks aninhados / `.then().catch()` encadeado — `async/await` é o padrão da base.
- `moment`, `lodash`, `uuid`, `node-fetch`, `dotenv` em script novo: a stdlib do 22 cobre.

---

## 2. Estilo, formatação & lint → Charter Art. 5, 7

**Formatação é do Prettier, não do gosto de ninguém.** Config versionada em
`.prettierrc.json` (`singleQuote`, `semi`, `trailingComma: all`, `printWidth: 100`,
`tabWidth: 2`, `endOfLine: lf`) + `.editorconfig`. Discussão de estilo em review é ruído:
`prettier --write` decide.

**Lint é o ESLint 9 em flat config** (`eslint.config.mjs`, ESM, na raiz do
`mnemonicos-backend`):

- base `@eslint/js` `recommended` + **`typescript-eslint` `recommendedTypeChecked`** (lint
  *type-aware*: exige `parserOptions.projectService`);
- `eslint-config-prettier/flat` **por último** — desliga o que conflita com o formatter;
- `ignores` global no primeiro objeto: `dist/`, `coverage/`, `src/generated/` (código do
  Prisma), `prisma/migrations/`.

**É erro (bloqueia):** tudo. Neste projeto não há regra em `warn` — `lint-staged` roda
`eslint --fix --max-warnings=0`, então aviso reprova igual. Destaques:

| Regra | Por quê |
|-------|---------|
| `no-console` (permite `warn`/`error`) | log estruturado passa pelo `pino` (§5); `console.log` não tem redação nem nível |
| `@typescript-eslint/consistent-type-imports` | `import type` some no emit — evita import de runtime só por tipo (e ciclos) |
| `@typescript-eslint/no-unused-vars` (`^_` isento) | parâmetro deliberadamente ignorado se declara `_next` |
| `@typescript-eslint/return-await: in-try-catch` | `return promise` dentro de `try` **escapa** o `catch`; o `await` mantém o frame |
| `eqeqeq: smart` | `==` só contra `null` (cobre `undefined`) |
| `no-floating-promises` (via `recommendedTypeChecked`) | promise sem `await`/`void` é erro silencioso — a classe de bug mais comum em Node |

**Comandos:** `npm run lint` (= `eslint .` — flat config descobre os arquivos, **não** use
`--ext`) e `npm run format:check` (= `prettier --check .`).

**Armadilha comum (type-aware lint):** arquivo `.ts` novo **fora** do `include` do
`tsconfig.json` faz o `projectService` falhar com *"was not found by the project service"* —
o lint quebra sem que exista erro de código. Arquivo novo na raiz (script, config) → ou
entra no `include`, ou entra em `allowDefaultProject`.

**Armadilha comum (gate):** rodar `eslint --fix` / `prettier --write` **no gate**. O gate
**reprova**; quem corrige é o autor (ou o hook do husky no commit). Gate que conserta
esconde que a entrega saiu fora do padrão.

---

## 3. Nomenclatura & idioma → Charter Art. 5

| Símbolo | Convenção | Exemplo |
|---------|-----------|---------|
| Tipo / interface / classe / enum gerado | `PascalCase`, **sem** prefixo `I` | `DisciplineSummary`, `AppError` |
| Função / método / variável / propriedade | `camelCase` | `listDisciplines`, `scheduleNext` |
| Constante de módulo (valor fixo) | `UPPER_SNAKE_CASE` | `API_PREFIX`, `MIN_EASE_FACTOR` |
| Arquivo | `kebab-case` + **sufixo de papel** | `disciplines.service.ts`, `error-handler.ts` |
| Teste | `<alvo>.test.ts` | `scheduler.test.ts` |
| Schema Zod | `<coisa>Schema` + tipo `z.infer` homônimo | `listDisciplinesQuerySchema` / `ListDisciplinesQuery` |

**Sufixos de papel são contrato de leitura**, não decoração: `.schema.ts` (fronteira de
validação), `.service.ts` (regra + I/O), `.routes.ts` (HTTP), `.test.ts` (prova). O nome do
arquivo já responde "posso importar Prisma aqui?".

**Nome revela efeito colateral (Art. 5):** `listDisciplines()` lê; `scheduleNext()` é pura;
função que grava se chama `create*`/`update*`/`save*`. Uma função chamada `getUser()` que
também emite evento ou grava log de auditoria **é violação** — renomeie ou separe.

**Booleano** se nomeia como predicado: `isProduction`, `hasSession`, `shouldRetry` — nunca
`flag`, `status`, `check`.

**Idioma** (vale nos dois repos):

- **identificadores em inglês** — é a norma do ecossistema (stdlib, Express, Prisma, Zod);
- **texto que o usuário lê em pt-BR** — `message` de `AppError`, mensagens de Zod
  (`'deve ter ao menos 32 caracteres'`);
- **comentários em pt-BR**, consistente com a base atual. Não misture idioma dentro do
  mesmo arquivo.

**Comentário e JSDoc (Art. 7):** em TypeScript a assinatura **já carrega o tipo** — então
JSDoc obedece ao teste único: *apagá-lo perde informação que o código não devolve?*

- **Perde → DEVE existir.** O invariante que o tipo não expressa
  (`/** Detalhes seguros para exposição. Nunca dados sensíveis. */` sobre
  `details?: unknown` — o tipo diz `unknown`, a regra diz *seguro*); o porquê de uma
  decisão com âncora (`DEC-03`, `FR-07`); a armadilha e sua condição de remoção (o
  comentário do `moduleNameMapper` no `jest.config.ts`); o caminho tentado que falhou.
- **Não perde → NÃO DEVE existir.** `@param query A query` sobre `query: ListQuery`,
  `@returns` que repete o tipo de retorno, cabeçalho ritual por arquivo/função.

**Nunca** use `@ts-expect-error` sem uma linha dizendo o porquê e o que o removeria.

---

## 4. Estrutura & arquitetura → Charter Art. 4, 7

O idiomático em Node/Express de porte médio é **módulo por domínio + fronteiras por
papel**, não camadas globais anêmicas. A dependência anda em **uma direção**:

```
routes (HTTP)  →  service (regra + I/O)  →  lib/ (prisma, logger)
     ↑                    ↑
  schema (Zod)      domain/types.ts (contrato compartilhado com o front)
```

| Unidade | PODE conter | NÃO PODE conter |
|---------|-------------|-----------------|
| `src/modules/<x>/*.schema.ts` | Zod, tipos derivados | Prisma, HTTP, regra de negócio |
| `src/modules/<x>/*.service.ts` | regra de negócio, Prisma, transação | `req`/`res`, `status`, header |
| `src/modules/<x>/*.routes.ts` | `Router`, parse do schema, chamada ao service, `res.json` | Prisma, SQL, cálculo de domínio |
| `src/lib/*` | conexões e clientes de infraestrutura (singleton) | regra de negócio |
| `src/http/*` | erros, middlewares, montagem de rotas | regra de negócio, Prisma |
| `src/config/env.ts` | leitura+validação de env, uma única vez | qualquer outra coisa |

> A ordem e os nomes acima são **do projeto** e estão normatizados no
> [`README.md`](README.md) — aqui interessa a **propriedade idiomática**: o handler HTTP
> não conhece o banco, e a regra de negócio não conhece o HTTP.

**Duas portas de entrada, uma app.** `createApp()` monta tudo; `src/server.ts` (processo
longo) e `api/index.ts` (function serverless) só embrulham. Consequência idiomática: **nada
de estado de módulo mutável** que dependa do modelo de execução — em serverless o processo
é reciclado a qualquer momento, e um `Map` de cache em variável de módulo é cache que às
vezes existe. Exceção legítima e única: o **client de conexão** cacheado em `globalThis`
(`src/lib/prisma.ts`), justamente para *não* abrir pool novo por reavaliação de módulo.

**Isolamento de efeito colateral (Art. 4) — a forma idiomática em TS é o parâmetro, não a
interface.** Não crie `IClock`/`IRepository` por antecipação: injete o valor.

```ts
// ✅ pura: o teste fixa o tempo passando `now`
export function scheduleNext(state: CardSchedule, grade: Grade, now: Date): CardSchedule

// ❌ lê o relógio por dentro: teste vira refém de `jest.useFakeTimers`
export function scheduleNext(state: CardSchedule, grade: Grade): CardSchedule
```

Interface/porta só entra quando existe **variante real** ou uma fronteira de processo a
trocar (Art. 4: indireção se justifica por dor presente).

**Agrupamento de parâmetros.** A partir de ~4 parâmetros, ou quando dois têm o mesmo tipo
(`(page: number, perPage: number)` — trocar a ordem compila e mente), agrupe num **objeto
nomeado pelo domínio**, tipado, e prefira o tipo derivado do Zod:
`listDisciplines(query: ListDisciplinesQuery)`. Objeto de opções também elimina o
`(a, b, undefined, true)` ilegível.

**Condicionais (Art. 7):** *guard clause* com `return` cedo em vez de `if/else` aninhado;
`switch` exaustivo sobre união de literais + `never` no default para o compilador garantir
que nenhuma variante ficou de fora:

```ts
function assertNever(value: never): never {
  throw new Error(`variante não tratada: ${String(value)}`);
}
```

`noFallthroughCasesInSwitch` (ligado) impede o fallthrough acidental.

**Padrões: a construção idiomática vem antes do padrão clássico.**

| Padrão clássico | Forma idiomática em TS/Node |
|---|---|
| Strategy / State | objeto `as const` mapeando literal → função, ou união discriminada + `switch` exaustivo — antes de hierarquia de classes |
| Factory | função `createX()` / `fromRow()` exportada; classe-fábrica só com variantes reais |
| Singleton | módulo é singleton por natureza (cache do ESM/CJS) — `src/lib/prisma.ts`; **não** escreva classe `getInstance()` |
| Observer | `EventEmitter` do `node:events` ou o `$on`/`$extends` do Prisma — nunca implementação manual |
| Builder | objeto de opções + `satisfies` resolve |
| Decorator | *client extension* do Prisma (`$extends`) / middleware do Express |
| Repository | o Prisma Client **já é** o repositório; embrulhar cada `findMany` numa classe é indireção sem dor |

**Armadilhas nesta stack:** classe de serviço só para agrupar funções sem estado (módulo
com funções exportadas basta, e é testável sem instanciar); *service locator* / container
DI por antecipação; herança para reuso (composição); `export default` (dificulta
refactor/renomeio automático — a base usa named exports); import circular entre
`service` ↔ `routes` (em CJS ele **não** estoura: devolve `undefined` em runtime).

---

## 5. Gestão de erro → Charter Art. 2, 7

**Exceção para o excepcional; valor de retorno para o esperado.** "Não encontrado" numa
busca opcional é `null` no tipo de retorno; violação de regra é `throw` de erro tipado.

**Erro tipado, nunca `throw new Error('...')` cru** na regra de negócio: a hierarquia
`AppError` (`src/http/errors.ts`) carrega `statusCode`, `code` e `details` — é o que
permite ao handler central decidir sem inspecionar mensagem. `throw 'string'` é proibido
(perde stack; `no-throw-literal`).

**Em `catch`, a variável é `unknown`** (`strict` liga `useUnknownInCatchVariables`) — o
único caminho legítimo é **narrowing**:

```ts
try {
  await doWork();
} catch (error) {
  if (error instanceof AppError) throw error;          // já é seguro para o cliente
  throw new BadRequestError('Falha ao processar.', { cause: error }); // preserva a origem
}
```

Use `Error.cause` (nativo desde Node 16) para encadear sem perder a raiz — e **não**
concatene a mensagem original na mensagem nova, ou o detalhe interno viaja para a resposta.

**Nunca engolir:**

- `catch {}` vazio, `catch (e) { /* ignore */ }`, `.catch(() => null)` sem comentário do
  porquê — é o bug que ninguém vê;
- promise sem `await` (`no-floating-promises` reprova); *fire and forget* deliberado se
  declara com `void promise.catch(logIt)`;
- `process.on('unhandledRejection')` / `'uncaughtException'` que **continua rodando**. Em
  Node 22 rejeição não tratada **encerra o processo** — esse é o comportamento correto:
  o estado já é inconsistente. Handler existe para **logar e sair** (`process.exit(1)`),
  deixando o supervisor reiniciar.

**Fail secure (Art. 2):** no `catch`, o default é **negar**. Falha ao verificar token,
permissão ou pertencimento **não** libera. `try { return checkPermission() } catch { return true }`
é vulnerabilidade, não robustez.

**Fronteira de conversão: uma só.** O error handler do Express (4 argumentos, registrado
**por último**) traduz erro → resposta. Erro previsto vira resposta detalhada; **qualquer
outra coisa vira 500 genérico**, com stack, mensagem do driver e nome de tabela **só no
log** (o desenho concreto está no [`README.md`](README.md)).

**Express 5 encaminha promise rejeitada de handler `async` ao error handler** — handler
`async` não precisa de `try/catch` nem de wrapper `asyncHandler`. Isso **não** vale para
rejeição fora do ciclo do request (callback de `EventEmitter`, `setTimeout`, worker): ali o
`catch` é seu.

**O que logar (pino):** `logger.error({ err, path, method }, 'mensagem')` — objeto
primeiro, mensagem depois (o serializer `err` do pino desmonta stack e `cause`).
**Nunca** logue `req.body` cru, header `authorization`, cookie, senha, token ou URL de
banco — a lista de `redact` do `src/lib/logger.ts` é o piso, não a garantia (§6.4).

**Armadilha comum — vazamento no sink de resposta:** sanear a mensagem no log e devolver
`error.message` cru no JSON. A mensagem do `pg`/Prisma cita host, usuário, banco e coluna.
O saneamento acontece **em cada sink**, independentemente — e um `success: false` com HTTP
200 e a mensagem do driver dentro é o mesmo vazamento com outra roupa.

---

## 6. Segurança mapeada à linguagem → Charter Art. 2 `[CRÍTICA]`

> Cada subseção é um item da **Régua do Art. 2** traduzido para "como se faz e como se erra
> nesta stack". Achado aqui é **rejeição imediata** no review.
>
> Tag `⚠️ não confirmado` = afirmação que este perfil **infere** e que o revisor humano
> precisa validar (roteiro em [`_review/node-22.md`](_review/node-22.md)).

### 6.1 Injeção → sempre parametrizar

**SQL: o Prisma Client é o caminho.** Toda operação do client (`findMany`, `where`,
`create`, `update`) é parametrizada pelo driver — não há concatenação de entrada. Entrada
externa **NÃO DEVE** chegar ao banco por outro caminho.

```ts
// ✅ parametrizado pelo client
await prisma.discipline.findMany({ where: { name: { contains: search, mode: 'insensitive' } } });

// ✅ raw com template tag: os valores viram placeholders, não texto de SQL
await prisma.$queryRaw`SELECT id FROM disciplines WHERE slug = ${slug}`;

// ❌ NUNCA: *Unsafe recebe SQL montado — é SQL Injection por construção
await prisma.$queryRawUnsafe(`SELECT id FROM disciplines WHERE slug = '${slug}'`);
```

- `$queryRaw`/`$executeRaw` com **template tag** interpolam os valores como parâmetros do
  driver `pg` (`$1`, `$2`), não como texto — inclusive sob o driver adapter do Prisma 7.
  ⚠️ não confirmado
- `mode: 'insensitive'` é traduzido pelo Prisma para comparação case-insensitive
  parametrizada no Postgres (`ILIKE`), sem interpolação da entrada — vale reconfirmar sob o
  compilador TS/WASM do Prisma 7, que substituiu o engine Rust. ⚠️ não confirmado
- **`$queryRawUnsafe` / `$executeRawUnsafe` são proibidos com dado de usuário.** Se
  precisarem existir, o argumento é literal do código.
- **Identificador não se parametriza.** Nome de coluna em `orderBy`, direção `asc`/`desc`,
  nome de tabela → **allowlist** (`as const` + validação Zod `z.enum`), nunca a string do
  cliente. Erro clássico: `orderBy: { [req.query.sort]: 'asc' }`.
- **`Prisma.sql` / `Prisma.join`** para montar cláusula dinâmica preservando os
  placeholders — nunca `+` de string.

**Command injection:** `child_process.exec`/`execSync` passam pelo shell — proibidos com
qualquer dado externo. Use `execFile`/`spawn` com **array de argumentos** (sem `shell: true`).
`eval`, `new Function`, `vm.runInNewContext` e `require(variável)` com entrada externa:
proibidos.

**Path traversal:** `path.resolve(base, userInput)` **não** protege — `../../etc/passwd`
resolve para fora. O padrão é resolver e **verificar o prefixo**:

```ts
const target = path.resolve(BASE_DIR, path.basename(userInput));
if (!target.startsWith(BASE_DIR + path.sep)) throw new ForbiddenError();
```

**Validação é a primeira parametrização.** Toda entrada (`body`, `query`, `params`,
header) atravessa um **schema Zod** na fronteira, e o resto do código consome o tipo
derivado (`z.infer`) — nunca `req.body` direto. Zod 4 **descarta chaves desconhecidas por
padrão** (`z.object`), o que já mitiga *mass assignment*; use `z.strictObject()` quando
chave extra deve ser **erro** (`.strict()`/`.passthrough()` são legado no Zod 4). Nunca
passe um objeto do cliente inteiro para `prisma.x.create({ data })`: monte o `data` campo a
campo a partir do resultado do parse.

### 6.2 Saída / escaping → escapar no destino

Esta API **só emite JSON** — não há template HTML, então o vetor de XSS refletido é
pequeno, mas não nulo:

- `res.json()` serializa com `JSON.stringify` e envia
  `Content-Type: application/json; charset=utf-8`. **Nunca** troque para `res.send()` com
  string montada, nem para `text/html`, com dado de usuário dentro — aí o escaping passa a
  ser seu problema.
- **XSS armazenado é responsabilidade compartilhada:** o texto do mnemônico chega, é
  guardado e volta cru no JSON. O escaping acontece no **consumidor** (React escapa por
  padrão; `dangerouslySetInnerHTML` é o furo). O backend **não** "limpa HTML" com regex —
  sanitização de HTML, se algum dia for preciso renderizar rich text, é biblioteca dedicada
  no ponto de renderização.
- **Cabeçalhos:** `helmet()` está montado em `createApp()` e cobre `X-Content-Type-Options:
  nosniff`, `X-Frame-Options`, HSTS, `Referrer-Policy` e CSP; `x-powered-by` é desligado
  explicitamente. A composição exata dos defaults do helmet 8 (em especial se a CSP vem
  ligada e com qual policy) precisa ser conferida contra o CHANGELOG da major
  instalada. ⚠️ não confirmado
- **Header/redirect com entrada externa:** `res.set()`/`res.redirect()` com string do
  cliente permite *response splitting* e *open redirect*. Redirect só para destino de
  allowlist.
- **Prototype pollution:** `express.json()` desserializa objeto vindo do cliente; chave
  `__proto__`/`constructor` num payload é um vetor conhecido em Node. A crença é que o
  `body-parser` embutido no Express 5 já neutralize `__proto__`, mas isso **precisa ser
  confirmado** — o mitigador que **não** depende disso é o parse Zod na fronteira (o objeto
  que a aplicação usa é o **produzido** pelo Zod, não o do cliente) e nunca fazer
  merge recursivo de objeto do cliente. ⚠️ não confirmado

### 6.3 Autorização → negar por padrão

- **A identidade vem da sessão/token verificado no servidor, nunca do parâmetro da rota.**
  `GET /users/:userId/reviews` **não** autoriza nada: o filtro é `where: { userId: <do
  token> }`. Confiar no `:userId` da URL é IDOR.
- **Deny-by-default na montagem:** o middleware de autenticação/autorização entra **antes**
  do router protegido, e a rota pública é a **exceção declarada**. Rota nova nasce
  protegida; nunca o inverso.
- **Ordem de middleware é semântica em Express.** `app.use(auth)` registrado **depois** de
  `app.use(API_PREFIX, apiRoutes)` não protege nada — e não falha visivelmente. Confira a
  ordem em `createApp()` a cada rota nova.
- **`next(err)` vs `return`:** em middleware de guarda, `next(new ForbiddenError())` **sem
  `return`** continua executando o corpo abaixo. O `return` é obrigatório.
- **Fail secure:** exceção na checagem nega (ver §5). `if (user?.role === 'ADMIN')` com
  `user` `undefined` nega — mas `?? true` como default em qualquer leitor de permissão é
  bug de segurança.
- **CORS não é autorização.** A allowlist de `CORS_ORIGINS` só instrui o **browser**; curl
  ignora. Toda rota continua precisando de checagem própria.
- **Rate limit e `trust proxy`:** `express-rate-limit` **reprova** `trust proxy: true`
  (`ERR_ERL_PERMISSIVE_TRUST_PROXY`) porque `X-Forwarded-For` forjado tornaria `req.ip`
  controlado pelo atacante — logo, o valor **numérico** (`app.set('trust proxy', 1)`) é o
  caminho. Que `1` seja o número correto de proxies confiáveis na plataforma de deploy
  (Vercel) precisa ser verificado no ambiente real: errar o número recoloca o bypass. E o
  contador em memória é **por instância** em serverless — proteção real exige store
  compartilhado. ⚠️ não confirmado
- **Prova (Art. 1):** todo gate de autorização exige teste de integração provando **401/403
  sem credencial** e **403 com credencial de outro dono** — não só o 200 do caminho felized.

### 6.4 Segredos & configuração → fora do código, fora do log

- Segredo vem **só de variável de ambiente**, lido **uma vez** em `src/config/env.ts` e
  validado por Zod na inicialização: **o processo não sobe** com env inválida (*fail fast*).
  O erro cita **nomes** de variável, jamais valores.
- `process.env.X` espalhado pelo código é proibido: importa-se `env` do módulo de config.
  Assim o typecheck garante que a variável existe e o valor já veio coagido/validado.
- **Booleano de env nunca usa `z.coerce.boolean()`** (= `Boolean(input)`: `"false"`/`"0"` → `true`,
  `""` → `false` sem aplicar o `.default()`). Use `z.enum(['true','false']).default(<…>).transform(v => v === 'true')`
  — valor inválido derruba o boot. Campo de env que governa controle de segurança exige teste
  do caminho **com valor fornecido** (inclusive string vazia), não só do default. (lição da Wave 1 de PLAN-003)
- `.env` **no `.gitignore`**; `.env.example` só com **placeholders**. Segredo nunca em
  fonte, em log, em mensagem de erro, em query string nem em comentário. Rotacione o valor
  que vazar — remover do histórico não desvaza.
- **Log:** o `redact` do pino é o piso. A semântica dos wildcards (`*.password` cobre
  **um** nível de aninhamento; caminho mais profundo exige entrada própria) precisa ser
  conferida na documentação da major do pino instalada, porque uma expectativa errada aqui
  produz vazamento silencioso — e o `err` serializado pode arrastar `err.config`/`err.cause`
  com credencial dentro. ⚠️ não confirmado
- **Senha:** hash com **Argon2id** (parâmetros OWASP atuais) ou bcrypt com custo ≥12.
  Node 22 **não** traz Argon2 no core — o built-in disponível é `crypto.scrypt`; Argon2id
  exige dependência (`argon2` nativo ou `@node-rs/argon2`). A escolha, e os parâmetros de
  memória/tempo, devem ser decididos com a documentação da lib e do OWASP na
  mão. ⚠️ não confirmado
- **Comparação de segredo** (token, HMAC, hash de API key) usa `crypto.timingSafeEqual`
  sobre buffers de **mesmo tamanho** (a função lança se diferirem — compare o hash, não o
  valor cru). `===` em string vaza tempo.
- **Aleatoriedade:** `crypto.randomUUID()` / `crypto.randomBytes()`. `Math.random()` **não
  é** criptográfico — nunca para token, senha temporária ou id de sessão.

### 6.5 Sessão & estado de autenticação

- **JWT em cookie `httpOnly`**, não em `localStorage` (XSS lê `localStorage`). Flags
  obrigatórias: `httpOnly: true`, `secure: true` (produção), `sameSite`, `path`, `maxAge`.
- Front em **domínio diferente** do backend + `credentials: true` no CORS costuma forçar
  `sameSite: 'none'`, que por sua vez **exige** `secure: true` — e `none` remove a proteção
  CSRF do cookie, exigindo token anti-CSRF ou verificação de `Origin` no servidor. A
  combinação válida para o par de domínios deste deploy precisa ser verificada em ambiente
  real antes de expor rota autenticada. ⚠️ não confirmado
- **Verificação de JWT:** algoritmo **explícito** na verificação (`algorithms: ['HS256']`)
  — aceitar o `alg` do header é a vulnerabilidade clássica (`alg: none`, confusão
  HS256/RS256); valide `exp`, `iss`, `aud`; segredo de `env.JWT_SECRET` (≥32 chars).
  **Nunca** decodifique sem verificar (`jwt.decode` ≠ `jwt.verify`) e nunca ponha PII ou
  dado sensível no payload — JWT é assinado, **não** cifrado.
- Access token curto (`JWT_EXPIRES_IN` = `15m`) + refresh token com **rotação e revogação**.
  Revogação exige estado no servidor (tabela/allowlist de refresh tokens): JWT é *stateless*
  e, por si, **não** dá logout do lado do servidor. O desenho de rotação/revogação
  apropriado ao serverless (onde não há memória compartilhada) ainda não existe neste
  projeto e precisa ser especificado antes da primeira rota autenticada. ⚠️ não confirmado
- **Auditoria:** login, falha de login e bloqueio se logam (usuário + resultado + IP), **sem
  senha e sem token**. Falha de autenticação responde **mensagem genérica** — distinguir
  "usuário não existe" de "senha errada" é enumeração de contas.

### 6.6 Chamadas de saída, upload e volume (síntese)

- **SSRF:** `fetch` global (undici) para URL derivada de entrada do usuário é SSRF —
  atinge `169.254.169.254` (metadata) e a rede interna. Regra: URL de saída sai de
  **allowlist de host**, esquema `https` obrigatório, `AbortSignal.timeout()` sempre. Não há
  guarda de SSRF embutida no `fetch`/undici do Node 22 (nem bloqueio de IP privado, e
  redirect é seguido por padrão) — validar a URL **antes** não impede o redirect para IP
  interno, então o controle precisa ser no host resolvido/`redirect: 'manual'`. ⚠️ não confirmado
- **Body limitado:** `express.json({ limit: '100kb' })` — limite explícito é defesa contra
  DoS por payload. Endpoint novo que precise de mais **declara** o seu.
- **Upload:** não existe hoje. Se entrar: allowlist de extensão **e** verificação do
  conteúdo real (magic bytes), nome gerado pelo servidor, armazenamento fora do webroot,
  limite de tamanho. Nunca confie em `originalname`/`mimetype` do cliente.
- **ReDoS:** regex sobre entrada de usuário com quantificador aninhado (`(a+)+`) trava o
  event loop **do processo inteiro** — Node é single-threaded. Regex de validação vem do
  Zod ou é simples e ancorada, com tamanho da entrada limitado antes.
- **Dependência:** `npm audit` no pipeline (§8) — supply chain é vetor de primeira classe
  em npm (typosquatting, script de `postinstall`).

---

## 7. Testes → Charter Art. 1, 9

**Runner canônico: Jest 30 + ts-jest** (`jest.config.ts`, `preset: 'ts-jest'`,
`testEnvironment: 'node'`, `testMatch: ['**/*.test.ts']`). Comando: `npm test`.

Organização (`roots`: `src` e `tests`):

| Tipo | Onde | Como |
|------|------|------|
| Unitário de regra pura | `tests/unit/<x>.test.ts` | sem mock, sem banco, sem relógio — a função recebe `now` |
| Integração de rota | `tests/integration/<x>.test.ts` | `supertest` sobre a `app` real (stack HTTP + middlewares de produção) |
| Integração com banco | `tests/*.integration.test.ts` (runner próprio, `--runInBand`, `resetDb()` por `beforeEach`) | Postgres **local** descartável (`mnemonicos_test`); nunca produção |
| Env de teste | `tests/setup-env.ts` (`setupFiles`) | valores **fictícios**; nenhum teste lê `.env`. O env de integração **deriva** deste (`import './setup-env'` + sobrepõe só as URLs) — nunca copia |

- **Árvore de decisão com precedência declarada** (DEC, comentário, ordem de `if`): teste
  **um caso por par de ramos que pode coincidir**, não só um por ramo — ordem de avaliação
  é comportamento do cruzamento, e o mutante que reordena sobrevive a "um caso por ramo".
  O nome do teste enuncia quem vence. (lição da Wave 2 de PLAN-003)
- **Infra de teste que faz DDL/`TRUNCATE`** valida o alvo **no módulo que resolve a conexão**
  (nome do banco == o descartável; host loopback) e **lança na carga** se divergir — nunca
  `expect()` dentro de um caso, que roda depois da primeira escrita. (lição da Wave 2 de PLAN-003)

**Convenções:**

- `describe('<unidade ou rota>')` + `it('<comportamento observável em pt-BR>')` — a frase
  descreve a **regra**, não o método: `it('devolve o cartão à mesma sessão quando o
  estudante erra')`, não `it('testa scheduleNext')`.
- **AAA**: arrange, act, assert, separados por linha em branco.
- `clearMocks: true` já está ligado — não acumule estado entre casos; sem estado global
  compartilhado entre `it`.
- Uma asserção **de comportamento** por caso (várias `expect` sobre o mesmo resultado são
  uma asserção só).

**Testar comportamento, não implementação.** Prove a regra (intervalos do agendador, piso
do ease factor, 422 do schema, 403 sem permissão, ausência de `x-powered-by`). **Não** teste
getter, "instanciou", nem o Prisma/Express — biblioteca de terceiro é premissa, não sujeito.

**O que mockar:** a **fronteira de processo** (banco, HTTP de saída, relógio quando não dá
para injetar). O que **não** mockar: a unidade sob teste, o Express (use `supertest` na app
real), a regra de negócio de outro módulo (então ela devia ser pura). Preferir **injetar** a
mockar: `scheduleNext(state, grade, now)` não precisa de `jest.useFakeTimers`.

**Oráculo tem de poder falhar (Art. 1):** teste que continua verde com a implementação
trocada por `return null` não é teste — é decoração. Ao escrever, quebre o código de
propósito e confirme o vermelho.

**Fixtures compartilhadas (Art. 3):** dado de teste que se repete vira **builder com
defaults + overrides** num helper (`tests/support/`), não `const user = {...}` copiado em
cinco arquivos — coluna nova no modelo quebraria as cinco cópias uma a uma.

**Cobertura:** `npm run test:ci` (`--coverage`) com piso global de 50% em
`coverageThreshold` (`src/server.ts`, `src/generated/**` e `index.ts` fora do
`collectCoverageFrom`). O piso é rede de segurança contra regressão de disciplina — **não**
é meta: 100% de linhas com asserção fraca não prova nada, e a régua real é o Art. 1.

**Teste que toca o banco:** não existe hoje (a suíte não abre conexão). Quando existir,
roda contra o **Postgres real** do `docker-compose.yml` em schema/base descartável, nunca
contra outro motor — dialeto, constraint e transação só falham no motor de verdade. Rodar
serialmente (`--runInBand`) ou com base por worker, e o setup/teardown por arquivo, nunca
por caso.

**Mutation testing (`quality.mutation`, opt-in):** a ferramenta canônica em TS/Node é o
**Stryker** (`@stryker-mutator/core` + `@stryker-mutator/jest-runner`), tipicamente
`npx stryker run --mutate <arquivos-do-diff>`. Hoje `quality.mutation` é `null` na ficha —
instalação via `/keelson:mutation-setup`.

---

## 8. Dependências → Charter Art. 2, 8

**Gerenciador: npm** (`package-lock.json` v3). O lock é **commitado** e é a fonte da
verdade da árvore instalada.

- **CI/produção usam `npm ci`** (instala exatamente o lock e falha se `package.json` e lock
  divergirem); `npm install` é para a máquina do dev; `npm update` só deliberadamente, em
  commit próprio.
- **Política de versão:** caret (`^`) para lib madura; o lock fixa o resolvido. Pin exato
  (`1.2.3`) para o que é sensível ou instável. `engines.node: ">=22.0.0"` é contrato —
  dependência que exige Node maior é rejeição.
- **Auditoria:** `npm audit` (consulta o endpoint de advisories do registry npm, alimentado
  pelo **GitHub Advisory Database**, que sincroniza com CVE/NVD). No pipeline:
  `npm audit --omit=dev --audit-level=high` reprova, **citando o GHSA/CVE**. `npm audit fix
  --force` **não** é correção automática aceitável: ele sobe major e muda comportamento.
  Auditoria completa via `/keelson:audit`.
- **Supply chain (A03):** antes de adicionar pacote, olhe downloads, última publicação,
  issues abertas, e se tem script de `install`/`postinstall`. Pacote de nome parecido com o
  popular é *typosquatting*. Pacote sem release há anos com CVE aberto é dívida, não
  economia. Confira **licença**.
- **`overrides`** (usado aqui para `deepmerge-ts`) é remendo de transitiva com data de
  validade: cada entrada **DEVE** ter comentário/registro do porquê e da condição de
  remoção — sem isso, ninguém remove nunca.
- **`postinstall: prisma generate`** é intencional: o client é **gerado**, não versionado
  como dependência — clone novo sem `generate` não compila.

**Antes de adicionar dependência, pergunte se a stdlib do Node 22 já resolve** (§1: uuid,
fetch, glob, dotenv, chalk, lodash, moment têm equivalente nativo). Dependência a menos é
CVE a menos.

**Armadilha comum:** rodar `npm install` (não `ci`) no deploy — resolve versões diferentes
das testadas e produz o bug "só em produção".

---

## 9. Reúso: o que já existe → Charter Art. 3

**Procure antes de criar.** Nesta base, o canônico mora em lugares fixos:

| Preciso de… | Já existe em |
|---|---|
| Conexão com o banco | `src/lib/prisma.ts` (**nunca** `new PrismaClient()` em outro arquivo — cada instância abre pool) |
| Log | `src/lib/logger.ts` (`console` é erro de lint) |
| Config / env | `src/config/env.ts` (`env`, `isProduction`, `isTest`) — nunca `process.env` solto |
| Erro de aplicação | `src/http/errors.ts` (`AppError` + subclasses por status) — não crie hierarquia paralela |
| Tradução erro → resposta | `src/http/middlewares/error-handler.ts` |
| Tipo de domínio | `src/domain/types.ts` — **espelhado** em `mnemonicos-frontend/src/types/domain.ts`; mudou um, o outro entra no mesmo diff |
| Validação de entrada | Zod, no `.schema.ts` do módulo. Regra repetida (paginação, slug) → schema base reusado/`.extend()`, não copiado |
| Tipo de linha do banco | tipos gerados em `src/generated/prisma/**` — não redeclare o shape à mão |
| Prefixo da API | `API_PREFIX` em `src/app.ts` |
| Env de teste | `tests/setup-env.ts` |

**Prefira stdlib e biblioteca instalada a helper caseiro:** `node:crypto`, `structuredClone`,
`Object.groupBy`, `Intl.DateTimeFormat`, `AbortSignal.timeout`, `node:util.parseArgs`; do
Prisma, `_count`/`include`/`select` em vez de agregar em JS; do Zod, `coerce`/`transform`/
`refine` em vez de parse manual.

**Como descobrir:** `grep`/`rg` pelo conceito nos `codePaths` da ficha
(`mnemonicos-backend/src`, `prisma`, `api`) antes de escrever; varredura mais ampla →
`code-scout`. O **guard determinístico** é o mecanismo preferido a "lembre de reusar": uma
regra `no-restricted-imports` no ESLint (proibir import direto do client gerado fora de
`src/lib/prisma.ts`, proibir `process.env` fora de `src/config/env.ts`) transforma
disciplina em falha de build. ⚠️ ainda não configurada — é uma melhoria conhecida.

**Régua:** ver Charter Art. 3 — a mudança não introduz segundo caminho para o que já
existia; conceito repetido é **extraído**, não copiado.

---

## 10. Performance & armadilhas → Charter Art. 8

**O custo patológico nº 1: N+1 de banco.**

```ts
// ❌ uma query POR item
for (const topic of topics) {
  topic.cards = await prisma.flashcard.findMany({ where: { topicId: topic.id } });
}

// ✅ uma query, o Prisma resolve o aninhamento
const topics = await prisma.topic.findMany({
  where: { disciplineId },
  select: { id: true, name: true, flashcards: { select: { id: true, front: true } } },
});
```

- **`select` explícito, sempre** — nunca traga o modelo inteiro "porque pode servir";
  coluna de texto longo (o corpo do mnemônico) numa listagem multiplica o tráfego.
- **`_count`** em vez de contar em JS; **`Promise.all`** para queries independentes (é o
  padrão em `listDisciplines`: `findMany` + `count` em paralelo).
- **Paginação obrigatória** em toda listagem de tamanho variável (`skip`/`take`, com `max`
  no schema Zod — aqui `perPage ≤ 100`). `skip` grande degrada: para rolagem infinita, use
  **cursor** (`cursor` + `take`).
- **Índice** nas colunas de `where`/`orderBy`/FK — declarado no `schema.prisma`
  (`@@index`), e a migração entra no diff.
- **Transação:** `prisma.$transaction` para invariante multi-tabela. `Promise.all` **não é**
  transação. Transação interativa (callback) mantém conexão presa: mantenha-a curta e
  **nunca** faça HTTP de saída dentro dela.

**O custo patológico nº 2: bloquear o event loop.** Node é single-threaded: uma operação
síncrona pesada trava **todos** os requests, não só o seu.

- Proibido em caminho de request: `fs.readFileSync`, `crypto.pbkdf2Sync`/`scryptSync`,
  `bcrypt.hashSync`, `JSON.parse` de payload enorme, loop O(n²) sobre coleção do cliente,
  regex catastrófica (§6.6). Use a versão assíncrona; CPU real vai para `worker_threads`
  ou fila.
- Trabalho longo (import de acervo, geração em lote, e-mail) **não** roda no request —
  ainda mais em serverless, onde a função morre no fim da resposta.

**Serverless muda a régua:** cold start, pool por instância (`max: 3` em produção, e
`DATABASE_URL` apontando para o pooler), nenhum cache em memória confiável, nenhum trabalho
depois do `res.json()`. Estado que precisa sobreviver vai para o banco.

**Ferramentas de medição (o Art. 8 exige medir, não palpitar):**

| Quero medir | Ferramenta |
|---|---|
| Plano/tempo de query | `EXPLAIN (ANALYZE, BUFFERS)` no Postgres real (`npm run db:psql`); `pg_stat_statements` |
| SQL que o Prisma emitiu | `log: [{ emit: 'event', level: 'query' }]` no client (dev), ou `DEBUG=prisma:query` |
| CPU do processo | `node --cpu-prof` (gera `.cpuprofile` para o DevTools); `0x`/`clinic flame` |
| Memória / leak | `node --heap-prof`, `--inspect` + heap snapshot no DevTools |
| Latência do event loop | `perf_hooks.monitorEventLoopDelay()` |
| Latência por rota | `pino-http` já loga `responseTime` — meça antes de otimizar |

**Régua:** ver Charter Art. 8 — sem query/round-trip dentro de laço sobre volume variável;
qualquer otimização não óbvia **cita a medição** que a justifica (no comentário ou na DEC).

---

## 11. Gotchas da versão → Charter Art. 1, 7

**Node 22**

- `module: nodenext` **sem** `"type": "module"` ⇒ emit **CommonJS**. Consequência: não
  existe `import.meta.dirname` no código de `src/` (use `__dirname`), e top-level `await`
  não compila. Adicionar `"type": "module"` no `package.json` é mudança de **arquitetura de
  módulos**, não ajuste de config.
- `require(esm)` (default desde 22.12) resolve lib ESM-only — mas **só** se o grafo for
  síncrono. Lib com top-level `await` continua exigindo `await import()`.
- Rejeição de promise não tratada **derruba o processo** (default desde o Node 15). É o
  comportamento desejado; não o desligue com `--unhandled-rejections=warn`.
- *Type stripping* nativo (`node file.ts`) só entra sem flag nas versões finais da linha 22
  — este projeto usa **`tsx`** para dev/seed. Não troque por execução nativa sem checar
  `node --version` no ambiente-alvo: o stripping não faz *typecheck* nem transforma
  `enum`/decorator.
- **Node 22 sai de manutenção em 2027**: planejar o salto para a próxima LTS é dívida
  agendada, não surpresa.

**TypeScript 6**

- `strict` + `noUncheckedIndexedAccess`: `array[0]` é `T | undefined`. Isso **não** é
  incômodo — é o bug que o compilador pegou. Trate; não `!`.
- `exactOptionalPropertyTypes` está **desligado** aqui: `{ a?: string }` aceita
  `{ a: undefined }`. Cuidado ao montar objeto de resposta — a base usa a forma
  `...(x === undefined ? {} : { x })` justamente para não emitir a chave.
- `isolatedModules` (ligado) exige `import type` para import só-de-tipo (o
  `consistent-type-imports` do ESLint automatiza).
- `catch (e)` dá `unknown`, não `any` — narrowing obrigatório (§5).
- Defaults novos do TS 6 (`target: es2025`, `module: esnext`, `types: []`) só valem para
  projeto **sem** config explícita; ainda assim, mudou `tsconfig`, rode `npm run typecheck`
  e `npm test` — `ts-jest` compila com o **mesmo** `tsconfig.json`, e o peer range de
  `ts-jest` em relação ao TypeScript 6 merece conferência a cada atualização.

**Express 5** (mordidas de quem vem do 4)

- **`path-to-regexp` v8:** `'*'` virou `'/*splat'` (wildcard **nomeado**); `:param?` virou
  `'{/:param}'`; regex dentro da string de rota não é mais aceita. Rota que "não casa mais"
  depois de um upgrade é isto.
- **`req.query` é somente-leitura** — middleware que "sanitizava" reatribuindo `req.query`
  quebra. A saída do parse Zod vira uma **variável nova** (ou `res.locals`), não uma
  mutação do request.
- `res.send(body, status)` e `res.json(body, status)` foram removidos →
  `res.status(422).json(body)`.
- `app.del` → `app.delete`; `req.param(name)` removido; `req.host` **inclui a porta**;
  `express.urlencoded` tem `extended: false` por padrão.
- **Promise rejeitada de handler `async` vai ao error handler** (§5) — a novidade mais útil
  da major, e a razão de `try/catch` em rota ser sinal de código redundante.
- O error handler continua sendo reconhecido pela **aridade 4** `(err, req, res, next)`:
  remover o `next` não usado transforma seu error handler num middleware comum, silenciosamente.
  Nomeie-o `_next`.

**Prisma 7** (a major que mais muda hábito)

- **Driver adapter obrigatório** (`@prisma/adapter-pg`); engine Rust foi removido (query
  compiler em TS/WASM). A **URL saiu do `schema.prisma`**: runtime usa `DATABASE_URL` via
  adapter (`src/lib/prisma.ts`), CLI/migrate usa `prisma.config.ts` com `DIRECT_URL` —
  porque `migrate` emite DDL que o pgbouncer não suporta.
- **O client é gerado no projeto** (`generator prisma-client`, `output` obrigatório →
  `src/generated/prisma`) e se importa **desse caminho**, não de `@prisma/client`. Por isso
  `src/generated/**` está fora do lint e da cobertura, e `postinstall` roda `prisma generate`.
- **`.env` não é mais carregado automaticamente** — daí o `import 'dotenv/config'` no topo
  de `prisma.config.ts` e de `src/config/env.ts`.
- O `pg` **não tem timeout de conexão por padrão** (o Prisma 6 tinha 5s): sem
  `connectionTimeoutMillis`/`max` explícitos no adapter, uma conexão ruim **espera para
  sempre**. Estão configurados — não os remova.
- **`$use` (middleware) foi removido** → *client extensions* (`$extends`).
- **`prisma generate` depois de mexer no `schema.prisma`**, sempre; e migração é `prisma
  migrate dev` (arquivo versionado, revisável, **com autorização do Diretor** — ver
  [`README.md`](README.md)).

**Zod 4**

- `.strict()`/`.passthrough()`/`.strip()` são legado → `z.strictObject()` /
  `z.looseObject()`; formatos de string subiram para o topo (`z.email()` em vez de
  `z.string().email()`); a entrada de `z.coerce.*` passou a ser `unknown` (mais permissiva
  no tipo — o cuidado com o que se coage é seu).
- `error.issues` é a lista canônica (é o que o error handler formata). `safeParse` na
  inicialização (para poder formatar e abortar), `parse` na rota (o `ZodError` sobe e o
  handler central devolve 422).

**Régua (Art. 1/7):** surpresa de versão que a base depende **DEVE** estar coberta por
teste (ex.: o teste que prova 403 para origem fora da allowlist, o que prova ausência de
`x-powered-by`) ou **comentada com o porquê** onde a escolha não é óbvia — como já fazem os
comentários de `jest.config.ts`, `prisma.config.ts` e `src/lib/prisma.ts`.

---

## 12. Ferramentas & comandos

Comandos **dentro de `mnemonicos-backend/`**:

| Papel | Comando idiomático | Ficha |
|-------|--------------------|-------|
| **test** | `npm test` (= `jest`); CI: `npm run test:ci` (`--ci --coverage`) | `quality.test` |
| **lint** | `npm run lint` (= `eslint .`) — formatação: `npm run format:check` | `quality.lint` |
| **typecheck** | `npm run typecheck` (= `tsc --noEmit`) | `quality.typecheck` |
| **build** | `npm run build` (= `prisma generate && tsc -p tsconfig.build.json`) | `quality.build` |
| **boot local** | `npm run dev` (sobe Postgres via `docker compose --wait`, então `tsx watch src/server.ts`); `npm run dev:no-db` sem banco | `quality.boot` |
| **tudo** | `npm run validate` (= `format:check && lint && typecheck && test`) | — |

Como este workspace agrega dois repositórios, a ficha embrulha cada comando com
`npm --prefix mnemonicos-backend …` (e encadeia o frontend). O que a ficha tem hoje:

```jsonc
{
  "profile": { "backend": { "lang": "node", "version": "22", "file": "guidelines/project/backend/node-22.md" } },
  "codePaths": { "backend": ["mnemonicos-backend/src", "mnemonicos-backend/prisma", "mnemonicos-backend/api"] },
  "quality": {
    "test": "npm --prefix mnemonicos-backend test && npm --prefix mnemonicos-frontend test",
    "lint": "npm --prefix mnemonicos-backend run lint && npm --prefix mnemonicos-frontend run lint",
    "typecheck": "npm --prefix mnemonicos-backend run typecheck && npm --prefix mnemonicos-frontend run typecheck",
    "build": "npm --prefix mnemonicos-backend run build && npm --prefix mnemonicos-frontend run build",
    "mutation": null,
    "e2e": null
  }
}
```

**Observações para quem mexer na ficha:**

- `quality.lint` roda **só** o ESLint. `format:check` entra pelo `validate` e pelo
  `lint-staged` (husky, `pre-commit`) — se o gate deve reprovar formatação, é
  `quality.lint` que precisa passar a encadear `format:check`.
- `quality.build` roda `prisma generate` antes do `tsc`: sem o client gerado, o typecheck
  falha em clone limpo. `npm run typecheck` isolado assume `postinstall` já executado.
- `quality.mutation` e `quality.e2e` são `null` — instaláveis por
  `/keelson:mutation-setup` (Stryker) e `/keelson:e2e-setup` (Playwright), que só gravam na
  ficha **após prova**.
- Comando de banco (`db:migrate`, `db:deploy`, `db:destroy`) **não** é comando de gate e
  **não** entra em `quality.*`: migração exige autorização humana explícita.
