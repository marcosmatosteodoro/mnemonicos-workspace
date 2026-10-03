# TASK-051-001: Reativar conta — rota, serviço e auditoria

**Slug**: producao-material
**Pertence a**: PLAN-051
**Realiza (FRs)**: FR-050-003, FR-050-004, FR-050-005, FR-050-006, FR-050-014
**Funcionalidade**: FEAT-050-001 (primária)
**Componente**: COMP-051-001 (principal), COMP-051-002, COMP-051-003, COMP-051-004, COMP-051-008
**Wave**: 1
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

Um ADMIN reativa uma conta desativada direto no servidor: `enableUser` limpa o mesmo campo
(`disabledAt`) que a desativação já marca, registra `user.reactivated` no log estruturado e a
rota nova devolve 200; um EDITOR é recusado antes de qualquer escrita. Território, código
existente e decisões vigentes vivem em `PLAN-051` (DEC-051-003/004/011/012) e no `MAP.md` do
slug — este contexto não os repete.

## Escopo

### Inclui
- `mnemonicos-backend/src/modules/users/users.service.ts` — nova função
  `enableUser(id: string, actorId: string): Promise<void>`, no mesmo estilo e posição de
  `disableUser` (linhas 130-169 hoje): lê o alvo (`select: { disabledAt: true }`); `null` →
  `NotFoundError('Conta não encontrada.')`; já ativa (`disabledAt === null`) → retorna sem
  gravar e **sem** chamar `recordUserAuditEvent`; senão `prisma.user.update({ where: { id },
  data: { disabledAt: null } })` seguido de `recordUserAuditEvent({ type: 'user.reactivated',
  at: now, actorId, targetId: id })`. Sem transação `Serializable` (TRISK-051-004/RISK-050-007,
  risco aceito).
- `mnemonicos-backend/src/modules/users/users.routes.ts` — nova rota
  `PATCH /users/:id/enable`, molde de `PATCH /users/:id/disable` (linhas 60-70 hoje):
  `verifyOrigin` + `requireRole('PATCH', '/users/:id/enable', 'ADMIN')` antes do handler;
  `userIdParamSchema.parse(req.params)` (reusado, sem schema novo); `await enableUser(id,
  req.auth.userId)`; `res.status(200).json({ id, status: 'active' as const })`. Comentário de
  cabeçalho do arquivo (hoje "3 mutações de estado", linha 32) atualizado para 4.
- `mnemonicos-backend/src/lib/audit.ts` — acrescenta, paralelo a `AuthAuditType`/
  `recordAuthEvent` (linhas 4-37 hoje), sem generalizá-los (DEC-051-011):
  `export type UserAuditType = 'user.reactivated';`,
  `export interface UserAuditEvent { type: UserAuditType; at: Date; actorId: string; targetId: string; }`,
  `export function recordUserAuditEvent(event: UserAuditEvent): void { logger.info({ audit: event }, \`user:${event.type}\`); }`.
  Nunca recebe senha nem token.
- `mnemonicos-backend/tests/unit/audit.test.ts` — novo `describe('recordUserAuditEvent', ...)`,
  molde do `describe('recordAuthEvent', ...)` existente (linhas 26-90): emite por `logger.info`
  sob a chave `audit`; inclui `at`/`actorId`/`targetId`/`type`; conjunto exato de chaves (sem
  campo extra); nenhuma chave de material sensível.
- `mnemonicos-backend/tests/integration/users.integration.test.ts` — novos casos de
  `PATCH /users/:id/enable` (molde das describes de `disableUser`, linhas 455-532 e 886-918);
  emenda de "as 4 rotas montadas são exatamente as de gestão" → 5 (linhas 349-361) e de "cada
  par método+caminho de gestão está em `ROUTE_ROLES` com exatamente `{ADMIN}`" (linhas 363-372),
  somando `['PATCH', '/users/:id/enable']`; soma um 4º caso ao describe
  `[retry S2] verifyOrigin nas 3 mutações de users/` (linhas 921-999), molde do caso de
  `PATCH /users/:id/disable` (linhas 953-973).
- `mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts` — acrescenta
  `'PATCH /users/:id/enable'` ao array literal de 48 pares (linhas 154-203+) e atualiza o
  comentário do título ("...48 pares... 47→48" → "...49 pares... TASK-051-001/KAN-219 somou
  PATCH /users/:id/enable, 48→49"); `concrete()` (linhas 88-94) já generaliza qualquer segmento
  `:param` para um UUID, sem edição própria.

### Não inclui
- Qualquer mudança em `auth.service.ts`/mecanismo de sessão (A-050-007 confirmada pelo
  `code-scout`: os 4 pontos — `login`, `resolveAccessSession`, `refresh`, `getSessionUser` —
  checam só `disabledAt !== null`; limpar o campo já basta).
- Migração Prisma, diff em `schema.prisma` ou `domain/types.ts` (A-050-002).
- Transação `Serializable`/guarda de "último ADMIN" na reativação (TRISK-051-004/RISK-050-007,
  risco aceito — direção oposta à de `disableUser`).
- Evento de auditoria para `createInternalUser`/`disableUser`/`resetUserPassword`
  (RISK-048-008 continua aberto para as outras 3 ações).
- Exibição do 404 "Conta não encontrada." na tela e refetch da lista — faceta de frontend do
  AC-050-013, da TASK-051-002.

## Critérios de pronto

- [ ] AC-050-002 (idempotência — cobre FR-050-003): reativar uma conta já ativa não produz
  erro, `disabledAt` permanece `null`, e **nenhum** evento novo de auditoria é registrado —
  verificação: `(cd mnemonicos-backend && npm run test:integration -- tests/integration/users.integration.test.ts -t "AC-050-002")`
  → `Tests: 1 passed`. Estado que faz o comando falhar: `enableUser` gravando/chamando
  `recordUserAuditEvent` mesmo quando `target.disabledAt === null` (idêntico ao guard de
  `disableUser:144`, espelhado na direção oposta).
- [ ] AC-050-003 (login real após reativação — cobre FR-050-004): conta desativada, reativada
  com sucesso, autentica com a senha existente — verificação:
  `(cd mnemonicos-backend && npm run test:integration -- tests/integration/users.integration.test.ts -t "AC-050-003")`
  → `Tests: 1 passed`, no molde de `login(...)` real (linha 486 do arquivo) chamado depois de
  `enableUser`. Falha hoje por ausência de `enableUser` — prova que o comando acha o alvo.
  Mesmo caso (ou um irmão no mesmo describe, casado pelo mesmo `-t "AC-050-003"`) também chama
  `GET /users` depois de `enableUser` ter sucesso e verifica que a conta-alvo volta com
  `status: 'active'` (`status` deriva de `disabledAt`, comportamento herdado de SPEC-048, sem
  diff nesta entrega — molde de asserção de listagem em `users.integration.test.ts:426-431`):
  cobre a 2ª cláusula Given-When-Then do AC ("a linha dessa conta na tela Usuários mostra a
  Situação 'Ativa' na próxima vez que a lista é carregada"), que a cláusula de login por si só
  não exercita.
- [ ] AC-050-004 (EDITOR recusado no servidor — cobre FR-050-005, NFR-050-002): sem sessão →
  401; EDITOR → 403 e `disabledAt` inalterado; `Origin` fora de `CORS_ORIGINS` → 403 sem efeito
  (molde linhas 953-973); ADMIN → 200 e `disabledAt` vira `null` — verificação:
  `(cd mnemonicos-backend && npm run test:integration -- tests/integration/users.integration.test.ts -t "AC-050-004")`
  → `Tests: 1 passed`.
- [ ] AC-050-005 (log da reativação — cobre FR-050-006, NFR-050-001): reativação com sucesso →
  `recordUserAuditEvent` chamado exatamente 1x com `{type:'user.reactivated', at, actorId,
  targetId}`; idempotência (AC-050-002) → 0 chamadas — verificação:
  `(cd mnemonicos-backend && npm run test:integration -- tests/integration/users.integration.test.ts -t "AC-050-005")`
  → `Tests: 1 passed`; e
  `(cd mnemonicos-backend && npm test -- tests/unit/audit.test.ts -t "user.reactivated")`
  → `Tests: 1 passed`, conjunto exato de chaves `{at, actorId, targetId, type}`, nenhuma chave
  de senha/token (lição ativa abaixo).
- [ ] AC-050-013 (parte backend — a faceta de exibição na tela é da TASK-051-002): id
  inexistente → 404 com `{error:{message:'Conta não encontrada.'}}` — verificação:
  `(cd mnemonicos-backend && npm run test:integration -- tests/integration/users.integration.test.ts -t "AC-050-013")`
  → `Tests: 1 passed`.
- [ ] Censo de rotas atualizado (RISK-050-005, tripwire de não-regressão): array com 49 pares
  incluindo `'PATCH /users/:id/enable'` — verificação:
  `(cd mnemonicos-backend && npm run test:integration -- tests/integration/route-authz-matrix.integration.test.ts -t "censo das rotas montadas")`
  → `Tests: 1 passed`. O mesmo comando contra o estado ANTES desta TASK (48 pares, sem o par
  novo) falha — prova que o tripwire é real (o par novo não está na árvore montada hoje).
- [ ] `*OrThrow` só depois da guarda que torna a ausência impossível (lição ativa
  `orthrow-so-depois-da-guarda-que-torna-a-ausencia-impossivel`, paths:
  `mnemonicos-backend/src/modules/**/*.service.ts`): `enableUser` usa `find*` comum (nunca
  `findUniqueOrThrow`) para ler o alvo e só lança `NotFoundError` depois de confirmar
  `target === null` — nenhuma leitura de campo do alvo antes dessa checagem. Verificação: leitura
  do diff na revisão (gate 6); indiretamente coberto pelo teste do AC-050-013 acima (um
  `findUniqueOrThrow` vazaria P2025 como 500 em vez de 404, e o teste reprovaria).
- [ ] `select` de leitura exposta que lê campo interno prova as chaves do payload (lição ativa
  `select-exposto-que-le-campo-interno-prova-as-chaves-do-payload`, paths:
  `mnemonicos-backend/src/modules/**/*.service.ts`): a resposta de `PATCH /users/:id/enable`
  (`{id, status:'active'}`) não expõe `disabledAt` cru nem qualquer campo além desses dois —
  coberto pela mesma suíte do AC-050-004 (asserção de chaves exatas do `res.body`, molde da
  listagem em `users.integration.test.ts:426-431`).
- [ ] Sem warnings/lints novos sobre todo o diff (`git diff --name-only main...HEAD`, produção
  e teste): `(cd mnemonicos-backend && npm run lint && npm run typecheck)` → sem erro nem
  warning novo nos arquivos tocados por esta TASK.

## Riscos específicos

- TRISK-051-004 (corrida de duplo clique sem `Serializable`) — aceito sem bloqueio; a mitigação
  real (botão travado em voo) é da TASK-051-002.
- TRISK-051-005 (censo de rotas é tripwire manual) — mitigado pelo critério dedicado acima.
- TRISK-051-006 (`UserAuditType` fechado em só `'user.reactivated'`) — aceito, DEC-051-011.
- TRISK-051-007 (reativar ADMIN produz 2º ADMIN ativo) — diretriz operacional do Diretor, sem
  guarda de código nesta TASK; gate 9 da TASK-051-002 só com conta descartável.

---

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 2026-10-03T10:44:27-0300
**Data conclusão**: 2026-10-03T10:58:05-0300
**Commit SHA**: b33945e
**Jira**: KAN-225

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (577/577, 8 novos)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (wave 1, implementado_por: developer, revisado_por: code-reviewer)
- [x] ACs verificados (AC-050-002, 003, 004, 005, 013)
- [x] Segurança (gate 8): aprovado (wave 1) — security-engineer, sem achados
- [x] Comportamento (gate 9): consolidado (FEAT-050-001)
