# TASK-003-005: Tipos de domínio espelhados nos dois repos

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: nenhuma
**Componente**: COMP-003-017, COMP-003-020
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done
**Data início**: 2026-08-28T16:05:00-03:00

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: backend Jest 30 + ts-jest (`mnemonicos-backend/tests/unit/`); frontend Jest 30 via `next/jest` + Testing Library (`mnemonicos-frontend/`). Gates: `npm --prefix mnemonicos-backend test` / `run typecheck` e `npm --prefix mnemonicos-frontend test` / `run typecheck`.

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-003-006, TASK-003-013

## Contexto

NFR-002-007 / AC-002-025 / DEC-003-010 / COMP-003-017 + COMP-003-020: `USER_ROLES` existe só no backend (MAP — `mnemonicos-backend/src/domain/types.ts`) e o frontend não tem os tipos correspondentes — fonte de dessincronia entre os repos. Esta task fecha a paridade do conjunto de papéis e do formato do usuário de sessão, no **mesmo diff** (regra do CLAUDE.md: mudou um lado, o outro entra junto ou o contrato quebra em runtime sem o typecheck acusar).

**Nomeia (aresta entre irmãs)**: a interface `SessionUser` — TASKs 003-006, 003-009, 003-010, 003-013, 003-014 e 003-015 consomem esse símbolo por nome (corpo de resposta de `POST /auth/login`, `GET /auth/me`, `POST /users`).

## Escopo

### Inclui
- `mnemonicos-backend/src/domain/types.ts` — mantém `USER_ROLES` (`['STUDENT','EDITOR','ADMIN'] as const`) e `UserRole` já existentes; acrescenta `export interface SessionUser { id: string; name: string; email: string; role: UserRole }`.
- `mnemonicos-frontend/src/types/domain.ts` — acrescenta `export const USER_ROLES = ['STUDENT','EDITOR','ADMIN'] as const;`, `export type UserRole = (typeof USER_ROLES)[number];` e `export interface SessionUser { id: string; name: string; email: string; role: UserRole }`.
- `mnemonicos-backend/tests/unit/domain-types-parity.test.ts` — lê `mnemonicos-backend/src/domain/types.ts` e `mnemonicos-frontend/src/types/domain.ts` pelo caminho relativo e afirma: `USER_ROLES` idênticos **e** o conjunto de nomes de campos de `SessionUser` idêntico entre os dois arquivos (regex sobre a declaração da interface).

### Não inclui
- Rótulo pt-BR de papel (nenhuma tela lista papéis nesta fatia; se entrar, vem de mapa em `domain.ts` — regra do README frontend).
- Consumo de `SessionUser` em endpoints/telas (TASKs 003-006, 003-009, 003-013+).
- Tipos `CardState`/`Review` do frontend (dormentes por A-002-015).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Backend: acrescentar a interface `SessionUser` logo após `USER_ROLES`/`UserRole`.
2. Frontend: acrescentar `USER_ROLES`, `UserRole` e `SessionUser` idênticos, no mesmo commit.
3. Adicionar `tests/unit/domain-types-parity.test.ts` comparando os dois arquivos: `USER_ROLES` iguais e conjunto de nomes de campos de `SessionUser` igual (regex sobre a declaração da interface).

## Critérios de pronto

- [ ] Testes cobrem AC-002-025 / NFR-002-007 (mesmo conjunto de valores de papel **e** mesma forma de `SessionUser` nos dois repos) — verificação executável: `npm --prefix mnemonicos-backend test -- domain-types` → (a) um caso que lê `USER_ROLES` de `mnemonicos-backend/src/domain/types.ts` e de `mnemonicos-frontend/src/types/domain.ts` e afirma arrays iguais (`['STUDENT','EDITOR','ADMIN']`); (b) um caso que extrai os nomes dos campos de `SessionUser` de cada arquivo (regex sobre a declaração da interface) e afirma conjuntos iguais — um campo a mais de um lado deixa o teste vermelho. `Tests: ≥2 passed`. Fixada antes do código.
- [ ] `SessionUser` idêntico nos dois repos e exercitado não-nulo — verificação executável: `npm --prefix mnemonicos-backend run typecheck` **e** `npm --prefix mnemonicos-frontend run typecheck` → exit 0 (baseline 0 erros nos dois, capturada no início da TASK); um teste em cada repo constrói um `SessionUser` literal com os 4 campos `{id,name,email,role}`. Fixada antes do código.
- [ ] A alteração entra num diff só (NFR-002-007) — verificação executável: `git diff --name-only main...HEAD` contém **ambos** `mnemonicos-backend/src/domain/types.ts` e `mnemonicos-frontend/src/types/domain.ts`. Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` e `npm --prefix mnemonicos-frontend run lint` → exit 0 (baseline capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md` / `next-16.md`; READMEs dos repos vencem em conflito).
- [ ] Code review aprovado.

## Riscos específicos

- Os tipos do domínio são mantidos em sincronia **à mão** — o teste de paridade é a única rede; mantê-lo sensível ao conjunto de valores **e** ao conjunto de campos de `SessionUser`, não só ao arquivo existir.
- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-backend/src/...`, `mnemonicos-frontend/src/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-08-28T16:05:00-03:00
**Data conclusão**: 2026-08-28T20:37:00-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 7506770 · 46a1d5f (be) · 9c02a63 · e783f1e (fe)
**Jira**: KAN-15
**Implementado por**: developer
**Revisado por**: code-reviewer (gates 1–7) · security-engineer (gate 8) — Wave 1, sobre o diff acumulado + delta do retry
**Tentativas**: 2
**Cobertura final**: n/a
**Arquivos modificados**:
  - mnemonicos-backend/src/domain/types.ts
  - mnemonicos-backend/tests/unit/domain-types-parity.test.ts
  - mnemonicos-frontend/src/types/domain.ts
  - mnemonicos-frontend/tests/types/domain.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando — backend 30/30 · frontend 9/9
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado — code-reviewer, re-review do delta APROVADO
- [x] ACs verificados — AC-002-025 (paridade de papéis entre os repos) — teste de paridade no backend + teste no repo frontend que falha sozinho se o espelho divergir (USER_ROLES via jest, forma de SessionUser via tsc)
- [x] Segurança (gate 8): aprovado (Wave 1) — security-engineer: projeção SessionUser fail-closed (sem passwordHash/token/disabledAt no bundle)
- [x] Comportamento (gate 9): n/a — tipos de domínio, sem efeito observável (qa)

**Notas**: Retry pelo gate 1/6 da Wave 1: o espelho não tinha rede na suíte do próprio repo frontend → `mnemonicos-frontend/tests/types/domain.test.ts` novo (falsificável sem checkout do backend); `domain-types-parity.test.ts` do backend troca ENOENT cru por erro explicativo. Docblock do teste frontend nomeia o typecheck como oráculo da forma de SessionUser (ajuste menor pendente, não-bloqueante).
