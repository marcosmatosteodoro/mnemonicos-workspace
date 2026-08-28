# TASK-003-012: Seed do primeiro ADMIN a partir de `env`

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: FR-002-021
**Funcionalidade**: FEAT-002-003 (primária)
**Componente**: COMP-003-018
**Wave**: 3
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 + ts-jest — integração em `mnemonicos-backend/tests/integration/` sobre Prisma real (Postgres do `docker-compose`). Gates: `npm --prefix mnemonicos-backend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: TASK-003-002, TASK-003-003
- **Bloqueia**: nenhuma

## Contexto

COMP-003-018 / DEC-003-008 / FR-002-021 / AC-002-023 / A-002-010. `prisma/seed.ts` hoje não cria usuário. Esta task faz o `main()` criar **exatamente um** ADMIN inicial a partir de `env.SEED_ADMIN_EMAIL` + `env.SEED_ADMIN_PASSWORD`, de forma idempotente (guarda `count(User, role=ADMIN) === 0`), e terminar sem criar quando as credenciais de bootstrap não estão configuradas (inclusive config parcial) — **nunca** senha embutida no código. Fatia sensível (bootstrap de permissão) → `security-engineer`.

## Escopo

### Inclui
- `mnemonicos-backend/prisma/seed.ts` — no `main()` (antes ou depois do seed de conteúdo): se `env.SEED_ADMIN_EMAIL` **e** `env.SEED_ADMIN_PASSWORD` presentes **e** `count(User, role=ADMIN) === 0` → `prisma.user.create` com `role: 'ADMIN'`, `passwordHash` de `hashPassword`. Config parcial (só uma das duas) → tratada como ausente. Ausentes → `console.log` informativo e segue sem criar. Nenhuma senha embutida.
- `mnemonicos-backend/tests/integration/seed.test.ts` — exercita a rotina de seed do ADMIN isolada (`seedAdmin()` ou equivalente exportado).

### Não inclui
- Criação de contas por rota (TASK-003-010).
- O seed de conteúdo existente (Direito Administrativo/Constitucional — mantido).
- As chaves `SEED_ADMIN_*` no `.env.example` (TASK-003-001).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Extrair a rotina de seed do ADMIN em função testável.
2. Guarda: só cria se as **duas** vars presentes **e** `count(ADMIN) === 0`.
3. `hashPassword(env.SEED_ADMIN_PASSWORD)` — nunca literal.
4. Teste de integração cobrindo os quatro cenários: env completa, rerun idempotente, env ausente, env parcial.

## Critérios de pronto

- [ ] Testes cobrem AC-002-023 (com env → exatamente 1 ADMIN; sem env → nenhum ADMIN, sem senha embutida) — verificação executável: `npm --prefix mnemonicos-backend test -- seed` → (a) env setada + base sem ADMIN → após a rotina, `count(User, role=ADMIN) === 1` e `verifyPassword(env.SEED_ADMIN_PASSWORD, hash)` → `true`; (b) rodar de novo → ainda `=== 1` (idempotência); (c) env ausente → `count(User, role=ADMIN) === 0` (uma senha embutida como fallback faria este caso falhar com 1 ADMIN criado); (d) config **parcial** (só `SEED_ADMIN_EMAIL` **ou** só `SEED_ADMIN_PASSWORD`) → tratada como ausente: **nenhum** ADMIN criado, nenhuma senha default (`Tests: ≥1 passed` para o caso parcial). `Tests: ≥4 passed` no total. Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md`, §6.4 — bootstrap sem segredo embutido; README do repo vence em conflito).
- [ ] Code review aprovado.

## Riscos específicos

- Em CI/dev sem as vars, nenhum ADMIN é criado — comportamento esperado; o primeiro acesso do ambiente exige as vars no `env` e um rerun do seed.
- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-backend/prisma/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-22
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
