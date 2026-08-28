# TASK-003-010: Gestão de contas por ADMIN (módulo `users/`)

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: FR-002-014, FR-002-015, FR-002-016, FR-002-017, FR-002-018, FR-002-019, FR-002-020, FR-002-022
**Funcionalidade**: FEAT-002-003 (primária)
**Componente**: COMP-003-014, COMP-003-013, COMP-003-015
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

COMP-003-013/014/015, DEC-003-007, §4 (fluxo de gestão) do PLAN. Módulo `src/modules/users/` inteiro sob `requireRole('ADMIN')`: criar (papel fixado na criação, `EDITOR` ou `ADMIN`), listar (sem material de senha/token), desativar (marca temporal reversível + revoga sessões + guarda do último ADMIN) e resetar senha (+ revoga sessões). Recusa senha < 12 na criação e no reset; recusa o papel `STUDENT`; nenhuma rota de auto-registro. Fatia sensível (gestão de contas) → `security-engineer`.

## Escopo

### Inclui
- `mnemonicos-backend/src/modules/users/users.schema.ts` — `createUserSchema` (`email` `z.email()` normalizado; `name` `z.string().trim().min(1)`; `role` `z.enum(['EDITOR','ADMIN'])` — `STUDENT` recusado; `password` `z.string().min(12)`), `resetPasswordSchema` (`password` `z.string().min(12)`), `userIdParamSchema` (`id` `z.uuid()`), `listUsersQuerySchema` (paginação, `.extend()` do padrão de `disciplines.schema.ts`).
- `mnemonicos-backend/src/modules/users/users.service.ts` — `createInternalUser(input): Promise<SessionUser>` (`hashPassword`; `data` campo a campo; violação de unique → `ConflictError`, sem alterar a conta existente); `listInternalUsers(query): Promise<Paginated<UserListItem>>` (`select` explícito `id,email,name,role,disabledAt` → `status: 'active'|'disabled'`; **nunca** `passwordHash` nem `sessions`); `disableUser(id)` (alvo ADMIN e `count(role=ADMIN, disabledAt=null) <= 1` → `ConflictError`; senão `disabledAt = now` **e** `revokeAllSessions(id)` em transação); `resetUserPassword(id, password)` (`hashPassword`; grava; `revokeAllSessions(id)`). Toda resposta é montada campo a campo (`select` explícito), nunca a entidade Prisma crua; nenhuma função devolve `passwordHash` ou valor de token.
- `mnemonicos-backend/src/modules/users/users.routes.ts` — `usersRoutes: Router` com `usersRoutes.use(requireRole('ADMIN'))` no topo: `GET /users`, `POST /users`, `PATCH /users/:id/disable`, `POST /users/:id/reset-password`. Sem rota de registro público. Sem `try/catch`.
- `mnemonicos-backend/tests/integration/users.test.ts`.
- Meio de execução dos `*.integration.test.ts` desta TASK: o harness de TASK-003-016 — config `jest.integration.config.ts`, helper `tests/integration/db.ts` (`testPrisma` + `resetDb()` no `beforeEach`), comando `npm --prefix mnemonicos-backend run test:integration`.

### Não inclui
- A montagem de `usersRoutes` em `routes.ts` e a suíte de conformidade (TASK-003-011).
- Alterar papel de conta existente / reativar conta desativada (fora — §4.2 da SPEC).
- O seed do 1º ADMIN (TASK-003-012).
- UI de gestão de equipe (fora — §4.2).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `users.schema.ts` — os quatro schemas Zod, `role` restrito a `EDITOR`/`ADMIN`.
2. `users.service.ts` — as quatro operações; `select` explícito na listagem e na resposta de criação; guarda do último ADMIN antes de `disableUser`; desativação + `revokeAllSessions` em `prisma.$transaction`.
3. `users.routes.ts` — `requireRole('ADMIN')` no topo do router; nenhum caminho de registro.
4. Testes de integração com fixtures de 2 contas / 2 sessões onde o escopo importa.

## Critérios de pronto

- [ ] Testes cobrem AC-002-016 (cria com papel `EDITOR`/`ADMIN` e senha ≥ 12; < 12 recusa) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → criação válida → 201 e `user.role` == enviado; `password` com 11 chars → 400, `count(User)` inalterado. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-017 (e-mail duplicado → 409, conta existente inalterada) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → snapshot da linha antes/depois idêntico; violação de unique → `ConflictError`/409; nenhum `update`. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-018 (nenhuma capacidade de auto-registro) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → asserção **estrutural** sobre a pilha de `usersRoutes`: todo handler que cria `User` está precedido por `requireRole('ADMIN')`; `POST /users` sem sessão → 401, com sessão EDITOR → 403; não há rota pública que crie usuário. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-019 (lista com `id,email,name,role,status` e **nunca** `passwordHash`/`sessions`) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → asserção **estrutural** sobre o conjunto exato de chaves de cada item; a mutação que troca o `select` explícito por objeto cru / `include` deixa o teste vermelho. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-020 (desativa com marca temporal + revoga sessões do alvo + bloqueia login) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → fixture com **dois** usuários com sessão ativa; desativar o alvo → `disabledAt != null`, todas as sessões do alvo `revokedAt != null`, sessões do outro usuário **intactas**, `login` do alvo → `UnauthorizedError`. `Tests: ≥3 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-021 (recusa desativar o último ADMIN ativo) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → fixture com exatamente 1 ADMIN ativo + N EDITORs → `disableUser(adminId)` → 409 e `disabledAt` do ADMIN permanece `null`; fixture com 2 ADMINs ativos → desativar um → 200 (os dois ramos de `count(role=ADMIN, disabledAt=null) <= 1` exercitados). `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-022 (reset define nova senha conforme política + revoga sessões da conta) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → após reset: `login` com a nova senha → sucesso; sessões anteriores daquela conta → `revokedAt != null`; sessões de outra conta intactas; senha < 12 → 400. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Testes cobrem FR-002-022 (recusa de papel `STUDENT` na criação) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → `POST /users` com `role: 'STUDENT'` → 400 (`createUserSchema`), sem criação. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-024 / NFR-002-004 (nenhum segredo em log ou resposta na criação/reset) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → (a) espião do transport do `logger` durante `POST /users` e `POST /users/:id/reset-password` falha se algum registro contém a senha da fixture ou valor de token; (b) asserção **estrutural** de que a resposta de `POST /users` e de `GET /users` não tem as chaves `passwordHash`/`accessToken`/`refreshToken`. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] `userIdParamSchema` / `listUsersQuerySchema` exercitados (itens do Inclui sem AC) — verificação executável: `npm --prefix mnemonicos-backend test -- users` → `PATCH /users/nao-uuid/disable` → 400; `GET /users?page=...` respeita a paginação do padrão de `disciplines.schema.ts`. `Tests: ≥1 passed`. Fixada antes do código.
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
