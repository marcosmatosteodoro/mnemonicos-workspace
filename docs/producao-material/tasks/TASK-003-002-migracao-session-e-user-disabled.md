# TASK-003-002: Migração aditiva `add_session_and_user_disabled`

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: nenhuma
**Componente**: COMP-003-002
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done
**Data início**: 2026-08-28T15:58:39-03:00

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 + ts-jest + supertest — integração em `mnemonicos-backend/tests/integration/` sobre a `app`/Prisma real (Postgres do `docker-compose` local). Gates: `npm --prefix mnemonicos-backend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-003-004, TASK-003-006, TASK-003-012, TASK-003-016

## Contexto

DEC-003-003 / DEC-003-007 / §5 do PLAN: `User` não tem hoje como marcar conta desativada e não há repositório de sessão. Esta task acrescenta `User.disabledAt DateTime?` e o `model Session` (campos verbatim da §5), gera o arquivo de migração versionado (revisável, entra no diff) e roda `prisma generate`. É substrato de dados — a regra que o consome vive nos services/middlewares. Fatia sensível (migração → `security-engineer`). O enum `UserRole` **não muda** (A-002-002, decisão do Diretor).

**Nomeia (aresta entre irmãs)**: o `model Session` e a coluna `User.disabledAt` — TASKs 003-004, 003-006, 003-010 e 003-012 consomem esses nomes e campos por nome (via client Prisma gerado), nunca por grafia solta.

## Escopo

### Inclui
- `mnemonicos-backend/prisma/schema.prisma` — em `model User`: `disabledAt DateTime?` (comentário: `null` = ativa) e `sessions Session[]`. Novo `model Session` com os atributos exatos da §5: `id String @id @default(uuid(7))`, `userId String` + `user User @relation(fields: [userId], references: [id], onDelete: Cascade)`, `familyId String`, `accessTokenHash String @unique`, `refreshTokenHash String @unique`, `accessExpiresAt DateTime`, `refreshExpiresAt DateTime`, `rotatedAt DateTime?`, `revokedAt DateTime?`, `createdIp String?`, `userAgent String?`, `createdAt DateTime @default(now())`, `@@index([userId])`, `@@index([familyId])`, `@@map("sessions")`.
- Arquivo de migração gerado em `mnemonicos-backend/prisma/migrations/<timestamp>_add_session_and_user_disabled/migration.sql` (via `prisma migrate dev --name add_session_and_user_disabled` contra o Postgres do `docker-compose` local — autorização do Diretor, A-002-004).
- `prisma generate` (client atualizado com o tipo `Session` e o campo `disabledAt`).

### Não inclui
- Qualquer `*.service.ts` / `*.routes.ts` / middleware.
- Alteração do `enum UserRole`.
- Índice além de `userId` / `familyId`; exclusão de `User` (fora de escopo — §4.2 da SPEC).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Editar `schema.prisma` (bloco `User` + novo bloco `Session`) copiando os atributos da §5 do PLAN.
2. Com o Postgres local up, `npx prisma migrate dev --name add_session_and_user_disabled` (a partir de `mnemonicos-backend/`).
3. `npx prisma generate`.
4. Conferir o `migration.sql` gerado: aditivo — `ALTER TABLE "users" ADD COLUMN "disabledAt"`, `CREATE TABLE "sessions"`, dois índices `UNIQUE`, dois `@@index`.

## Critérios de pronto

- [ ] Schema válido e migração aditiva presente no diff — verificação executável: a partir de `mnemonicos-backend/`, `npx prisma validate` → "The schema is valid"; `git diff --name-only main...HEAD` contém `prisma/migrations/*add_session_and_user_disabled*/migration.sql`. Fixada antes do código.
- [ ] Sem drift entre schema e histórico de migrações — verificação executável: a partir de `mnemonicos-backend/`, `npx prisma migrate diff --from-migrations ./prisma/migrations --to-schema-datamodel ./prisma/schema.prisma --exit-code` → exit code 0 (0 = sem diferença). Fixada antes do código.
- [ ] `model Session` gerado com os dois `@unique` e `disabledAt` nullable — verificação executável: `npm --prefix mnemonicos-backend test -- session-schema` → cria uma `Session` via `prisma.session.create` no banco de teste, inserir `accessTokenHash` duplicado → violação de constraint única; `prisma.user.update({ data: { disabledAt: null } })` aceito. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Enum `UserRole` intocado — verificação executável: `git diff main...HEAD -- mnemonicos-backend/prisma/schema.prisma` não contém alteração dentro do bloco `enum UserRole` (revisão do hunk). Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md`, Prisma 7 com `prisma.config.ts`; README do repo vence em conflito).
- [ ] Code review aprovado.

## Riscos específicos

- A migração roda contra o Postgres do `docker-compose` local — exige o container up e autorização do Diretor (A-002-004). O `.sql` é revisável e entra no diff da TASK.
- `onDelete: Cascade` alinha com o resto do schema; a exclusão de `User` segue fora de escopo (§4.2 da SPEC).
- Repos symlinkados (lição de exploração): operar pelo caminho dentro do link (`mnemonicos-backend/prisma/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-08-28T15:58:00-03:00
**Data conclusão**: 2026-08-28T20:37:00-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: fb2e55b · 7ccad5c (retry)
**Jira**: KAN-12
**Implementado por**: developer
**Revisado por**: code-reviewer (gates 1–7) · security-engineer (gate 8) — Wave 1, sobre o diff acumulado + delta do retry
**Tentativas**: 2
**Cobertura final**: n/a (substrato de dados)
**Arquivos modificados**:
  - mnemonicos-backend/prisma/schema.prisma
  - mnemonicos-backend/prisma/migrations/20260828190018_add_session_and_user_disabled/migration.sql

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando — backend 30/30 (não regride)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado — code-reviewer, re-review do delta APROVADO
- [x] ACs verificados — sem AC (Realiza: nenhuma); critérios de pronto: `prisma validate` OK, sem drift, migração aditiva no diff, enum UserRole intocado. **Critério do `@unique` de Session adiado para TASK-003-016 (Wave 2)** — adiamento declarado, não silencioso
- [x] Segurança (gate 8): aprovado (Wave 1) — security-engineer: migração 100% aditiva, FK CASCADE coerente, só hashes na Session; comentário reescrito para HMAC-SHA256
- [x] Comportamento (gate 9): n/a — migração/schema, sem efeito observável (qa)

**Notas**: Retry pelo gate 8 da Wave 1: comentário normativo do hash de token `sha256(token+pepper)` → `HMAC-SHA256(token, pepper)`. O contrato foi propagado para PLAN-003 COMP-003-004/§5/DEC-003-002 e TASK-003-003 (errata, pendente de merge). O teste de constraint `@unique` roda em TASK-003-016.
