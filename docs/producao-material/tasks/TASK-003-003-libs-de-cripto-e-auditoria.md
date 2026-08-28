# TASK-003-003: Libs de cripto e auditoria (`password`, `tokens`, `audit`)

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: nenhuma
**Componente**: COMP-003-003, COMP-003-004, COMP-003-005
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 + ts-jest — unit em `mnemonicos-backend/tests/unit/`. Gates: `npm --prefix mnemonicos-backend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: TASK-003-001
- **Bloqueia**: TASK-003-006, TASK-003-007, TASK-003-008, TASK-003-010, TASK-003-012

## Contexto

DEC-003-001 (Argon2id via `@node-rs/argon2`), DEC-003-002 (`JWT_SECRET` vira pepper do hash de token), COMP-003-003/004/005. Três helpers de infra: derivação/verificação de senha, geração/comparação de token opaco em tempo constante, e o emissor de auditoria estruturado sem dado sensível. Fatia sensível → `security-engineer` + `/keelson:audit` sobre as dependências novas (RISK-002-003 / TRISK-003-004).

**Nomeia (aresta entre irmãs)**: as assinaturas `hashPassword` / `verifyPassword` (`password.ts`), `generateToken` / `hashToken` / `tokensMatch` (`tokens.ts`), `recordAuthEvent` + o tipo `AuthAuditEvent` (`audit.ts`) — TASKs 003-006, 003-007, 003-008, 003-010 e 003-012 consomem por esses nomes.

## Escopo

### Inclui
- `mnemonicos-backend/src/lib/password.ts` — `hashPassword(plain: string): Promise<string>`, `verifyPassword(plain: string, hash: string): Promise<boolean>`. Sempre assíncrono (nunca API `*Sync` — §10 do perfil); `memoryCost`/`timeCost`/`parallelism` lidos de `env`; `verifyPassword` devolve `false` em hash malformado — **nunca lança**.
- `mnemonicos-backend/src/lib/tokens.ts` — `generateToken(): string` (`crypto.randomBytes(32)` → base64url), `hashToken(token: string): string` = `crypto.createHmac('sha256', env.JWT_SECRET).update(token).digest('base64url')` (**HMAC-SHA256**, nunca `sha256(token + pepper)` — errata do gate da Wave 1), `tokensMatch(token: string, storedHash: string): boolean` (`crypto.timingSafeEqual` sobre buffers de hash de mesmo tamanho). `Math.random()` proibido.
- `mnemonicos-backend/src/lib/audit.ts` — `recordAuthEvent(event: AuthAuditEvent): void`; `AuthAuditEvent` união discriminada por `type` (`'login.success' | 'login.failure' | 'login.throttled' | 'token.refresh' | 'token.reuse' | 'logout' | 'authz.denied'`) com `at: Date`, `outcome`, `subject`, `ip: string`, `userAgent?: string`; escreve via `logger.info({ audit: event }, ...)`; payload montado campo a campo, nunca `req.body` cru. **O evento é objeto plano de um nível** (o `redact` do pino só cobre um nível de aninhamento — gate 8 da Wave 1): nada de sub-objeto dentro de `event`.
- `mnemonicos-backend/package.json` + `package-lock.json` — `+@node-rs/argon2` (pin exato), `+cookie-parser` (caret), `+@types/cookie-parser` (devDependency).
- `mnemonicos-backend/tests/unit/password.test.ts`, `tests/unit/tokens.test.ts`, `tests/unit/audit.test.ts`.

### Não inclui
- Montagem de `cookie-parser` em `app.ts` (TASK-003-009).
- Uso de `hashToken` na resolução de sessão / rotação (TASKs 003-004, 003-006).
- Reuso do `express-rate-limit` já instalado (TASK-003-008).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Antes de adicionar `@node-rs/argon2`: conferir downloads, última publicação e ausência de `postinstall` de compilação; pin exato.
2. `password.ts` — wrapper assíncrono sobre `@node-rs/argon2` com custo de `env`; `verifyPassword` em `try/catch` devolvendo `false`.
3. `tokens.ts` — `randomBytes` → base64url; `hashToken` = `crypto.createHmac('sha256', env.JWT_SECRET)` (HMAC, nunca concatenação); `tokensMatch` via `timingSafeEqual`.
4. `audit.ts` — construir o objeto de evento campo a campo e emitir por `logger.info`.

## Critérios de pronto

- [ ] Testes cobrem AC-002-024 (camada de derivação — a senha só existe como saída de função resistente a força bruta, com parâmetros de custo configuráveis) — verificação executável: `npm --prefix mnemonicos-backend test -- password` → `hashPassword('senhaDe12chars!')` devolve string com prefixo `$argon2id$`; `verifyPassword(plain, hash)` → `true`; `verifyPassword('outra', hash)` → `false`; `verifyPassword('x', 'nao-e-hash')` → `false` **sem lançar**; nenhuma chamada a API `*Sync`. `Tests: ≥4 passed`. Fixada antes do código.
- [ ] Parâmetros de custo vêm de `env` — verificação executável: `npm --prefix mnemonicos-backend test -- password` → com `ARGON2_MEMORY_KIB`/`ARGON2_TIME_COST`/`ARGON2_PARALLELISM` do `setup-env`, o hash gerado decodifica com `m=`/`t=`/`p=` correspondentes. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Testes cobrem `generateToken`/`hashToken`/`tokensMatch` (contrato do item — sem AC) — verificação executável: `npm --prefix mnemonicos-backend test -- tokens` → `generateToken()` devolve 43 chars base64url (32 bytes) e dois valores consecutivos distintos; `hashToken(t)` é determinístico, **igual ao `crypto.createHmac('sha256', JWT_SECRET).update(t).digest('base64url')` calculado independentemente no teste** (a mutação para `sha256(t + JWT_SECRET)` deixa vermelho), e muda quando `env.JWT_SECRET` muda; `tokensMatch(t, hashToken(t))` → `true`, `tokensMatch('x', hashToken(t))` → `false`. `Tests: ≥4 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-002 / AC-002-024 (camada de auditoria — o evento de falha de autenticação e toda linha emitida pelo emissor não carregam senha nem valor de token) — verificação executável: `npm --prefix mnemonicos-backend test -- audit` → para cada `type` da união, o evento sai por `logger.info` com `at`/`outcome`/`subject`/`ip`; asserção **estrutural** de que o objeto emitido não possui as chaves `password`/`token`/`accessToken`/`refreshToken` (sobre o conjunto de chaves, não substring de prosa). `Tests: ≥3 passed`. Fixada antes do código.
- [ ] Dependências novas com pin e auditoria limpa — verificação executável: `npm --prefix mnemonicos-backend ci` reproduzível (exit 0); `npm --prefix mnemonicos-backend audit --omit=dev --audit-level=high` → `found 0 vulnerabilities`; `@node-rs/argon2` sem `postinstall` de compilação (conferido em `npm view @node-rs/argon2` / `package-lock.json`). Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md`, §6.4/§10; README do repo vence em conflito).
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-003-004 / RISK-002-003: dependências novas entram na árvore. `@node-rs/argon2` é binário napi-rs pré-compilado por plataforma (sem node-gyp) — `npm ci` limpo no dev (Windows) e no CI; pin exato; `/keelson:audit` sobre o diff de F1.
- `JWT_SECRET` passa a ser a chave do HMAC em `hashToken` (DEC-003-002) — **não** é assinatura JWT, e **não** é `sha256(token + JWT_SECRET)`.
- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-backend/src/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-13
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
