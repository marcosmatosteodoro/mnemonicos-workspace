# TASK-003-004: Lógica pura de rotação de sessão (`session-rotation.ts`)

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: FR-002-003, FR-002-004, FR-002-005
**Funcionalidade**: FEAT-002-001 (primária)
**Componente**: COMP-003-006
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 + ts-jest — unit em `mnemonicos-backend/tests/unit/` (lógica pura, sem banco/relógio, recebe `now` por parâmetro — espelho de `src/modules/review/scheduler.ts`). Gates: `npm --prefix mnemonicos-backend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: TASK-003-002
- **Bloqueia**: TASK-003-006

## Contexto

COMP-003-006 / DEC-003-003 / TRISK-003-005. Função pura sem I/O que, dada a linha de sessão encontrada e `now`, decide o desfecho de uma renovação: rotacionar, responder idempotente na janela de graça, revogar a família por reuso, ou recusar por expiração absoluta. Isolá-la garante o teste unitário sem banco e sem relógio, mitigando a área de corrida da rotação concorrente (A-002-018). A persistência do desfecho (transação, `revokedAt WHERE familyId`) é da TASK-003-006.

## Escopo

### Inclui
- `mnemonicos-backend/src/modules/auth/session-rotation.ts` — `decideRefresh(session: SessionRow, now: Date, graceSeconds: number): RefreshDecision`, onde `RefreshDecision` é união discriminada: `{ kind: 'rotate' }` | `{ kind: 'replay-grace' }` | `{ kind: 'reuse' }` | `{ kind: 'expired' }`. `SessionRow` = a forma da linha lida (campos `rotatedAt`, `revokedAt`, `refreshExpiresAt` do `model Session` da TASK-003-002). Ordem de avaliação dos ramos: **expired → reuse → replay-grace → rotate**. Não toca banco, não lê relógio.
- `mnemonicos-backend/tests/unit/session-rotation.test.ts`.

### Não inclui
- Persistência da rotação / `prisma.$transaction` / revogação de família (TASK-003-006).
- Leitura/escrita de cookie (TASK-003-009).
- `hashToken` e a busca da linha por `refreshTokenHash` (TASKs 003-003, 003-006).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Definir `RefreshDecision` e o tipo estrutural `SessionRow` (só os campos consultados).
2. Implementar a árvore de decisão **nesta ordem de precedência** (ramos coincidentes seguem-na — expiração absoluta vence a graça): `refreshExpiresAt < now` → `expired`; `revokedAt != null` → `reuse`; `rotatedAt != null` e `now - rotatedAt <= graceSeconds` → `replay-grace`; `rotatedAt != null` e `now - rotatedAt > graceSeconds` → `reuse`; senão → `rotate`.
3. Cobrir cada ramo no teste unitário com `SessionRow` literais, mais os casos de ramos coincidentes.

## Critérios de pronto

- [ ] Testes cobrem AC-002-004, AC-002-006 e a decisão de concorrência de AC-002-026 — verificação executável: `npm --prefix mnemonicos-backend test -- session-rotation` → `Tests: ≥6 passed` cobrindo: válido não-rotacionado → `{kind:'rotate'}`; reapresentação com `rotatedAt` dentro de `graceSeconds` → `{kind:'replay-grace'}`; `rotatedAt` além de `graceSeconds` → `{kind:'reuse'}`; `revokedAt` setado → `{kind:'reuse'}`; `refreshExpiresAt < now` → `{kind:'expired'}`. Fixada antes do código.
- [ ] Testes cobrem AC-002-005 (gatilho de revogação de família por reuso) — verificação executável: `npm --prefix mnemonicos-backend test -- session-rotation` → os dois caminhos que produzem `{kind:'reuse'}` (`rotatedAt` além da graça **e** `revokedAt != null`) presentes como casos distintos; a mutação que faz `decideRefresh` ignorar `revokedAt` deixa um caso vermelho. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Precedência de ramos coincidentes fixada — verificação executável: `npm --prefix mnemonicos-backend test -- session-rotation` → token simultaneamente `refreshExpiresAt < now` **e** `rotatedAt` dentro da graça → `{kind:'expired'}` (expiração absoluta vence a graça); token `revokedAt != null` **e** expirado → `{kind:'reuse'}` **ou** `{kind:'expired'}` conforme a ordem documentada, e o teste fixa qual (ordem: expired → reuse → replay-grace → rotate). `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Função pura, `now` por parâmetro — verificação executável: assinatura `decideRefresh(session: SessionRow, now: Date, graceSeconds: number): RefreshDecision` conferida; a suíte roda em `tests/unit/` sem subir banco (`npm --prefix mnemonicos-backend test -- session-rotation` não abre conexão Prisma); revisão confirma ausência de `new Date()` / `Date.now()` / import de `prisma` no corpo. Fixada antes do código.
- [ ] `RefreshDecision` exercitado com valor não-nulo — verificação executável: `npm --prefix mnemonicos-backend run typecheck` → exit 0 (baseline 0 erros capturada no início da TASK); o teste afirma o `kind` de cada retorno. Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` → exit 0 (baseline capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md`, §4 — função sem I/O recebendo `now`; README do repo vence em conflito).
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-003-005: a janela de graça da rotação concorrente é área de corrida; esta função pura testável é a mitigação da decisão — a corrida real (transação + `@unique` como trava) é da TASK-003-006.
- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-backend/src/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-14
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
