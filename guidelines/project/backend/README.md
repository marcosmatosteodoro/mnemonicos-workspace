# mnemonicos-backend — guia de projeto (keelson)

Leia antes de codar no backend. Vale junto de
[../README.md](../README.md) (regras dos dois repos) e do perfil de linguagem
[node-22.md](node-22.md) — em conflito, **este arquivo vence o perfil**.

## O que o serviço é

API REST que serve o acervo (disciplinas → assuntos → mnemônicos → flashcards) e guarda o
estado de repetição espaçada de cada estudante. Node 22 · TypeScript 6 (`strict`, CommonJS)
· Express 5 · Prisma 7 · PostgreSQL. Roda como function serverless na Vercel
(`api/index.ts`) e como processo longo em host tradicional (`src/server.ts`) — **as duas
portas de entrada montam a mesma app**, então nada de estado de módulo que só funcione numa
delas.

## Camadas — a ordem não é negociável

**schema** (Zod, valida a entrada) → **service** (regra de negócio + Prisma) → **routes**
(HTTP). Nada de Prisma direto na rota. Um módulo é uma pasta em `src/modules/<nome>/` com
os arquivos sufixados pelo papel: `.schema.ts`, `.service.ts`, `.routes.ts`.

Lógica de negócio pura fica em função **sem I/O**, e recebe o que varia por parâmetro —
`src/modules/review/scheduler.ts` recebe `now: Date` justamente para ser testável sem
relógio nem banco. Função que lê o relógio por dentro é função que o teste não consegue
fixar.

## Erro

- Erro previsto → `AppError` ou subclasse (`src/http/errors.ts`). É o que vira resposta
  detalhada.
- `ZodError` → 422 com os campos inválidos.
- **Qualquer outra exceção → 500 genérico.** Stack, mensagem do driver e nome de tabela
  ficam **só** no log. Isso é fail secure, não preguiça: mensagem de driver vaza host,
  usuário e nome do banco.
- Express 5 encaminha promise rejeitada ao error handler — handler `async` **não** precisa
  de `try/catch` nem de wrapper. `try/catch` numa rota é sinal de que se está tratando algo
  que o handler central já trata.
- **Nunca liberar no `catch`.** Falha em verificação de permissão ou de token nega.

## Banco

- `prisma migrate dev` gera arquivo versionado em `prisma/migrations/` — ele **entra no
  diff da TASK**. Migração não revisável é migração que ninguém aprovou.
- **Toda migração exige perguntar ao Diretor antes de executar.** Vale também para comando
  que só *pareça* inofensivo.
- A partir do Prisma 7 a URL **não** vive no `schema.prisma`: runtime usa driver adapter
  (`@prisma/adapter-pg`, `DATABASE_URL`), migrate usa `prisma.config.ts` (`DIRECT_URL`).
  Os dois existem porque `migrate` emite DDL que o pgbouncer não suporta.
- Consulta sempre pelo Prisma, parametrizada. `$queryRaw` só com template tag (nunca
  concatenação), e só quando o client não dá conta.
- Banco de desenvolvimento é o `docker-compose.yml` do repo: `npm run dev` sobe o Postgres
  antes da aplicação; `npm run dev:no-db` sobe só a aplicação.

## Segurança — o que já está no lugar, e o que falta

No lugar: env validada na inicialização (o processo não sobe sem `DATABASE_URL`/`JWT_SECRET`
válidos, e o erro cita **nomes**, nunca valores) · CORS deny-by-default por allowlist ·
`helmet` · rate limit com `trust proxy` ajustado · corpo limitado a 100 kB · log com
redação (`authorization`, `cookie`, `password`, `token`, `DATABASE_URL`, `JWT_SECRET`).

**Falta, e é pré-requisito antes de expor dado de usuário:**

- Autenticação — hash **Argon2id** (ou bcrypt), emissão e verificação de JWT, refresh.
- **Autorização por recurso** — `CardState` e `Review` são dados pessoais. Toda consulta
  filtra por `userId` **da sessão**, nunca do parâmetro da rota. Deny-by-default: sem
  sessão, não lê.
- Auditoria de eventos de autenticação (sucesso, falha, bloqueio) — sem dado sensível.

Enquanto isso não existir, **nenhum endpoint que devolva dado por usuário entra em
produção**. Se uma TASK pedir isso, o gate de segurança reprova — e está certo.

## Testes

- Lógica pura → teste unitário em `tests/unit/`, sem mock de banco.
- Rota → teste de integração em `tests/integration/` com `supertest` sobre a app.
- Env dos testes vem de `tests/setup-env.ts`, com valores **fictícios**. Nenhum teste lê
  `.env`.
- O oráculo tem de poder falhar. Teste que passa com a implementação trocada por `return
  null` não é teste.

## Comandos

`npm run validate` = `format:check` + `lint` + `typecheck` + `test`. É o conjunto que o
gate roda; rode antes de despachar.
