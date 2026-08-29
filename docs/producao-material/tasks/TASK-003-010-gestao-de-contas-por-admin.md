# TASK-003-010: Gestão de contas por ADMIN (módulo `users/`)

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: FR-002-014, FR-002-015, FR-002-016, FR-002-017, FR-002-018, FR-002-019, FR-002-020, FR-002-022
**Funcionalidade**: FEAT-002-003 (primária)
**Componente**: COMP-003-014, COMP-003-013, COMP-003-015, COMP-003-008 (F5 — extração de `revokeAllSessionsOp`)
**Wave**: 5
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 + ts-jest + supertest — integração em `mnemonicos-backend/tests/integration/` sobre a `app` real. Gates: `npm --prefix mnemonicos-backend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: TASK-003-003, TASK-003-006, TASK-003-007, TASK-003-016
- **Bloqueia**: TASK-003-011, TASK-003-013

## Contexto

COMP-003-013/014/015, DEC-003-007, §4 (fluxo de gestão) do PLAN. Módulo `src/modules/users/` inteiro restrito a `ADMIN`: criar (papel fixado na criação, `EDITOR` ou `ADMIN`), listar (sem material de senha/token), desativar (marca temporal reversível + revoga sessões + guarda do último ADMIN) e resetar senha (+ revoga sessões). Recusa senha < 12 na criação e no reset; recusa o papel `STUDENT`; nenhuma rota de auto-registro. Fatia sensível (gestão de contas) → `security-engineer`.

**EMENDA DEC-003-005 (Wave 4 — vinculante)**: `requireRole` passou a ter a assinatura **`requireRole(method: HttpMethod, path: string, ...roles: UserRole[])`**, declarando em `ROUTE_ROLES` **na avaliação da chamada** (tempo de montagem) com chave `"<MÉTODO> <caminho>"`. O padrão anterior `usersRoutes.use(requireRole('ADMIN'))` (guard cego no topo do router) **não é mais viável** — foi um dos achados críticos do gate 8 da Wave 4 (declaração derivada de `req.path` relativo ao mount envenena o registro). Cada rota do módulo declara o próprio par método+caminho-completo: `requireRole('GET', '/users', 'ADMIN')`, `requireRole('POST', '/users', 'ADMIN')`, `requireRole('PATCH', '/users/:id/disable', 'ADMIN')`, `requireRole('POST', '/users/:id/reset-password', 'ADMIN')`. Caminho completo = o que `requireAuth` vê a partir da raiz de `apiRoutes` (árvore montada plana em TASK-003-011).

**Retry (Wave 5 — REPROVADO nos gates 8 e 1/4/7 no 1º passe `efaef57`)**. Correções vinculantes, cada uma com o mutante que deve ficar vermelho nos Critérios de pronto:
- **S1 (gate 8, ALTA)** — a guarda do último ADMIN é **check-then-act** (`count` fora da transação de escrita): 2 `disableUser` concorrentes com 2 ADMINs ativos → ambos passam → **0 ADMIN ativo, lockout irreversível** (reativação está fora de F1). Fecha **na escrita**: `count` **dentro** de `prisma.$transaction(async (tx) => {...}, { isolationLevel: 'Serializable' })`, `<= 1` → `ConflictError`, e a falha de serialização do Postgres (P2034) capturada → `ConflictError` (fail-closed). Alternativa aceitável: `UPDATE ... WHERE ... AND (SELECT count(*) ...) > 1` via `$executeRaw` (template tag) com `rowsAffected === 0` como a recusa.
- **S2 (gate 8, MEDIA)** — `verifyOrigin` ausente nas 3 mutações de `users/` (só `sameSite: 'lax'` protege). Aplicar `verifyOrigin` (importado de `auth.routes.ts` — COMP-003-010) em `POST /users`, `PATCH /users/:id/disable`, `POST /users/:id/reset-password`.
- **F1 (gate 1)** — `listInternalUsers` projeta à mão em `rows.map`, então o mutante `select` → `include: { sessions: true }` **sobrevive** (o critério da TASK exigia vermelho). A prova do não-vazamento vai **no ponto da consulta**.
- **F2 (gate 1 + gate 4)** — o filtro `search` (nome OU e-mail) não tinha teste **nem** requisito declarado. Agora é capacidade **declarada** (Inclui + EMENDA no PLAN COMP-003-013/014), com teste por sujeito.
- **F3 (gate 1)** — ramos de `disableUser`/`resetUserPassword` sem caso: id inexistente → 404; conta já desativada → no-op que **não** re-carimba o `disabledAt` original.
- **F5 (gate 7)** — `revokeAllSessions` (auth.service.ts, Wave 3) ficou sem consumidor de produção e o diff nasceu com a 2ª/3ª cópia do `session.updateMany` de revogação. Extrair **`revokeAllSessionsOp(userId, now)`** que componha em `$transaction`, consumido por `disableUser`, `resetUserPassword` **e** `changeOwnPassword`; `revokeAllSessions` vira o invólucro.

## Escopo

### Inclui
- `mnemonicos-backend/src/modules/users/users.schema.ts` — `createUserSchema` (`email` `z.email()` normalizado; `name` `z.string().trim().min(1)`; `role` `z.enum(['EDITOR','ADMIN'])` — `STUDENT` recusado; `password` `z.string().min(12).max(200)`), `resetPasswordSchema` (`password` `z.string().min(12).max(200)`), `userIdParamSchema` (`id` `z.uuid()`), `listUsersQuerySchema` (paginação a partir do padrão de `disciplines.schema.ts` + **`search` opcional** — string curta; EMENDA Wave 5).
- `mnemonicos-backend/src/modules/users/users.service.ts` — `createInternalUser(input): Promise<SessionUser>` (`hashPassword`; `data` campo a campo; violação de unique → `ConflictError`, sem alterar a conta existente); `listInternalUsers(query): Promise<Paginated<UserListItem>>` (`select` explícito `id,email,name,role,disabledAt` → `status: 'active'|'disabled'`; **nunca** `passwordHash` nem `sessions`; `query.search` → `where` com `OR: [{ name: { contains, mode: 'insensitive' } }, { email: { contains, mode: 'insensitive' } }]`); `disableUser(id)` (**S1** — `count` do último ADMIN **dentro** de `prisma.$transaction(..., { isolationLevel: 'Serializable' })`, `<= 1` → `ConflictError`, P2034 → `ConflictError`; senão `disabledAt = now` **e** `revokeAllSessionsOp(id, now)` na mesma transação; id inexistente → `NotFoundError`; conta já desativada → no-op sem re-carimbar `disabledAt`); `resetUserPassword(id, password)` (`hashPassword`; grava; `revokeAllSessionsOp(id, now)` em transação; id inexistente → `NotFoundError`). Toda resposta montada campo a campo (`select` explícito), nunca a entidade Prisma crua; nenhuma função devolve `passwordHash` ou valor de token.
- `mnemonicos-backend/src/modules/auth/auth.service.ts` — **acrescenta `revokeAllSessionsOp(userId: string, now: Date)`** (**F5** — retorna `Prisma.PrismaPromise` ou recebe o `tx`; o `session.updateMany({ where: { userId, revokedAt: null }, data: { revokedAt: now } })` vive **só aqui**). `revokeAllSessions` passa a ser o invólucro que chama `revokeAllSessionsOp` num `$transaction` de uma operação; `changeOwnPassword` passa a consumir `revokeAllSessionsOp` dentro da sua transação. Nenhum outro `session.updateMany` de revogação em `src/`.
- `mnemonicos-backend/src/modules/users/users.routes.ts` — `usersRoutes: Router` com as 4 rotas, **cada uma** com `requireRole(<método>, <caminho completo>, 'ADMIN')` (assinatura da EMENDA Wave 4 — nunca `usersRoutes.use(requireRole(...))` cego): `GET /users`, `POST /users`, `PATCH /users/:id/disable`, `POST /users/:id/reset-password`. As **3 mutações** (`POST /users`, `PATCH /users/:id/disable`, `POST /users/:id/reset-password`) aplicam **`verifyOrigin`** (importado de `auth.routes.ts`) antes do handler (**S2**). Sem rota de registro público. Sem `try/catch`.
- `mnemonicos-backend/tests/integration/users.integration.test.ts`.
- Meio de execução dos `*.integration.test.ts` desta TASK: o harness de TASK-003-016 — config `jest.integration.config.ts`, helper `tests/integration/db.ts` (`testPrisma` + `resetDb()` no `beforeEach`), comando `npm --prefix mnemonicos-backend run test:integration`.

### Não inclui
- A montagem de `usersRoutes` em `routes.ts`, a suíte de conformidade e a montagem de `verifyOrigin` 1× em `apiRoutes` (TASK-003-011) — aqui `verifyOrigin` é aplicado **por rota** nas 3 mutações.
- A regra de sessão de `auth.service.ts` — **exceto** a extração `revokeAllSessionsOp` e a troca dos 3 consumidores (`revokeAllSessions`, `changeOwnPassword`, e os novos usos) para consumi-la (**F5**, EMENDA no PLAN COMP-003-008/014).
- Alterar papel de conta existente / reativar conta desativada (fora — §4.2 da SPEC).
- O seed do 1º ADMIN (TASK-003-012).
- UI de gestão de equipe (fora — §4.2).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `auth.service.ts` — extrai `revokeAllSessionsOp(userId, now)`; `revokeAllSessions` e `changeOwnPassword` passam a consumi-la (**F5**).
2. `users.schema.ts` — os quatro schemas Zod, `role` restrito a `EDITOR`/`ADMIN`, `listUsersQuerySchema` + `search` opcional.
3. `users.service.ts` — as quatro operações; `select` explícito; `disableUser` fecha a guarda do último ADMIN **na escrita** (`$transaction` Serializable, P2034 → `ConflictError`) + `revokeAllSessionsOp` na mesma transação; `listInternalUsers` aplica `search` por nome/e-mail; ramos de 404 e no-op.
4. `users.routes.ts` — `requireRole(<método>, <caminho completo>, 'ADMIN')` por rota; `verifyOrigin` nas 3 mutações; nenhum caminho de registro.
5. Testes de integração: fixtures de 2 contas / 2 sessões onde o escopo importa; **N desativações concorrentes** contando linhas; mutantes nomeados nos Critérios rodados antes de marcar.

## Critérios de pronto

- [ ] Testes cobrem AC-002-016 (cria com papel `EDITOR`/`ADMIN` e senha ≥ 12; < 12 recusa) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → criação válida → 201 e `user.role` == enviado; `password` com 11 chars → **422** (`ZodError`→errorHandler), `count(User)` inalterado. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-017 (e-mail duplicado → 409, conta existente inalterada) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → snapshot da linha antes/depois idêntico; violação de unique → `ConflictError`/409; nenhum `update`. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-018 (nenhuma capacidade de auto-registro) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → asserção **estrutural** sobre a pilha de `usersRoutes`: todo handler que cria `User` está precedido por um `requireRole(<método>, <caminho>, 'ADMIN')` e a chave método-aware correspondente (`"POST /users"` etc.) está em `ROUTE_ROLES` com `['ADMIN']`; `POST /users` sem sessão → 401, com sessão EDITOR → 403; não há rota pública que crie usuário. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] **[retry F1]** Testes cobrem AC-002-019 / FR-002-017 **no ponto da consulta** (lista **nunca** traz `passwordHash`/`sessions`) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → (a) asserção **estrutural** sobre o conjunto exato de chaves de cada item da resposta (`{id,email,name,role,status}`); (b) asserção sobre o **objeto que `prisma.user.findMany` devolveu** dentro do serviço (chaves da linha lida == exatamente as 5 do `select`, sem `passwordHash`), semeando uma conta **com sessão**. Mutante `select: {...}` → `include: { sessions: true }` **e** mutante `select` → entidade crua (`...row`): **rodados na fixação**, os dois deixam o teste vermelho (o 1º passe: sobreviviam). Mesma prova para `createInternalUser`. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] **[retry F2]** Testes cobrem o filtro `search` de `listInternalUsers` (nome **ou** e-mail — capacidade declarada, EMENDA Wave 5) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → fixture com contas cujos nomes e e-mails divergem: `search` que casa **só por nome** → traz só essa; `search` que casa **só por e-mail** → traz só essa; `search` sem correspondência → lista vazia. Mutantes **rodados na fixação**: `where` sempre `{}` (filtro ignorado) e remover a cláusula `email` do `OR` — cada um deixa ao menos um caso vermelho. `Tests: ≥3 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-020 (desativa com marca temporal + revoga sessões do alvo + bloqueia login) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → fixture com **dois** usuários com sessão ativa; desativar o alvo → `disabledAt != null`, todas as sessões do alvo `revokedAt != null`, sessões do outro usuário **intactas**, `login` do alvo → `UnauthorizedError`. `Tests: ≥3 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-021 (recusa desativar o último ADMIN ativo — a REGRA) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → fixture com exatamente 1 ADMIN ativo + N EDITORs → `disableUser(adminId)` → 409 e `disabledAt` do ADMIN permanece `null`; fixture com 2 ADMINs ativos → desativar um → 200; fixture com 2 ADMINs, um já desativado → desativar o remanescente → 409 (enumera por **dado ativo**, não contagem bruta). Mutante `<= 1` → `< 1` deixa vermelho. `Tests: ≥3 passed`. Fixada antes do código.
- [ ] **[retry S1]** A guarda do último ADMIN fecha **na escrita** (não check-then-act) — verificação executável: `npm --prefix mnemonicos-backend run test:integration -- users` → teste de integração que dispara **N `disableUser` concorrentes** (`Promise.allSettled`) do **penúltimo** ADMIN contra o Postgres real, e ao fim conta linhas: `count(User where role='ADMIN' and disabledAt is null) >= 1` **sempre**; ao menos uma das chamadas rejeita com `ConflictError`. A implementação check-then-act do 1º passe (`count` fora da transação) faz `adminsAtivosRestantes` chegar a 0 → o teste fica vermelho. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] **[retry F3]** Ramos de `disableUser`/`resetUserPassword` cobertos — verificação executável: `npm --prefix mnemonicos-backend test -- users` → `disableUser(id inexistente)` → `NotFoundError`/404 (mutante que remove o guard → P2025 vaza como 500, vermelho); `disableUser` sobre conta **já desativada** → no-op que **não** altera o `disabledAt` original (mutante que remove o `if (target.disabledAt !== null) return` → re-carimba a marca, vermelho); `resetUserPassword(id inexistente)` → `NotFoundError`/404. `Tests: ≥3 passed`. Fixada antes do código.
- [ ] **[retry S2]** `verifyOrigin` nas 3 mutações de `users/` — verificação executável: `npm --prefix mnemonicos-backend test -- users` → `POST /users`, `PATCH /users/:id/disable`, `POST /users/:id/reset-password` com `Origin` fora de `CORS_ORIGINS` → **403**, sem efeito (nenhuma conta criada/alterada); com `Origin` da allowlist → segue. Mutante que remove `verifyOrigin` de qualquer uma das 3 deixa o caso `Origin` proibido dessa rota vermelho. `Tests: ≥3 passed`. Fixada antes do código.
- [ ] **[retry F5]** `revokeAllSessionsOp` é o único ponto de revogação em massa — verificação executável (oráculo primário = comportamento): `npm --prefix mnemonicos-backend test -- auth users` → `disableUser`, `resetUserPassword` e `changeOwnPassword` continuam revogando as sessões da conta (provas de AC-002-020/022/029 verdes); um teste unitário afirma que os **três** delegam a `revokeAllSessionsOp` (spy/mock de `revokeAllSessionsOp` chamado 1× por cada, com `userId` correto) — a mutação que faz qualquer um dos três voltar a um `updateMany` próprio deixa esse teste vermelho. Checagem de apoio (não é o oráculo): `rg -n "revokedAt:\s*now" mnemonicos-backend/src/` aponta só para dentro de `revokeAllSessionsOp` (`export function revokeAllSessionsOp` a envolve). `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-022 (reset define nova senha conforme política + revoga sessões da conta) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → sessões preexistentes aferidas **antes** do login; após reset: `login` com a nova senha → sucesso; sessões anteriores daquela conta → `revokedAt != null`; sessões de outra conta intactas; senha < 12 → **422**, `passwordHash` inalterado. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Testes cobrem FR-002-022 (recusa de papel `STUDENT` na criação) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → `POST /users` com `role: 'STUDENT'` → **422** (`createUserSchema`), sem criação. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-024 / NFR-002-004 (nenhum segredo em log ou resposta na criação/reset) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → (a) espião do transport do `logger` durante `POST /users` e `POST /users/:id/reset-password` falha se algum registro contém a senha da fixture ou valor de token; (b) asserção **estrutural** de que a resposta de `POST /users` e de `GET /users` não tem as chaves `passwordHash`/`accessToken`/`refreshToken`. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] `userIdParamSchema` / `listUsersQuerySchema` exercitados (itens do Inclui sem AC) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → `PATCH /users/nao-uuid/disable` → **422**; `GET /users?page=...` respeita a paginação do padrão de `disciplines.schema.ts`. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md`, §4/§5; README do repo vence em conflito).
- [ ] Code review aprovado.

## Riscos específicos

- A guarda do último ADMIN (FR-002-019) é a contenção de lockout administrativo — como a reativação está fora de escopo (§4.2), uma desativação acidental do penúltimo ADMIN só se desfaz por intervenção direta no banco.
- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-backend/src/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-20
**Implementado por**: 
**Revisado por**: 
**Tentativas**: 
**Cobertura final**: 
**Arquivos modificados**:
  - 

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): verificado | n/a — <qa ou motivo do n/a>

**Notas**: 
