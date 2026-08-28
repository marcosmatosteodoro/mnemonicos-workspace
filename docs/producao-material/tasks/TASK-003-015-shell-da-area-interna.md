# TASK-003-015: Shell da área interna

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: FR-002-013, FR-002-023
**Funcionalidade**: FEAT-002-002 (primária), FEAT-002-001
**Componente**: COMP-003-024
**Wave**: 7
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 via `next/jest`, `testEnvironment: jsdom`, Testing Library — em `mnemonicos-frontend/`. Gate de tela: `gates.screenVerify` (Playwright MCP). Gates: `npm --prefix mnemonicos-frontend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: TASK-003-013
- **Bloqueia**: nenhuma

## Contexto

COMP-003-024 / DEC-003-011 / FR-002-013 / FR-002-023. Shell da área interna: resolve a sessão (`me`) e reflete os três estados de navegação protegida (carregando neutro / vista renderizada / redirect ou "sem permissão"), e hospeda o controle de logout com seus três estados observáveis. O backend é quem nega de fato (FR-002-012 — TASKs 003-007/011); o shell é apresentação.

## Escopo

### Inclui
- `mnemonicos-frontend/src/app/(interno)/layout.tsx` — layout do grupo `(interno)`; compõe `InternalShell` (com uma prop `requiredRole`).
- `mnemonicos-frontend/src/components/internal-shell.tsx` — `'use client'`. Usa `useMeQuery`: *em andamento* → estado de carregamento neutro (nó `role="status"` com texto pt-BR); *sucesso* (sessão válida, papel suficiente) → renderiza `children`; *falha* sem sessão → redireciona para `/login`; *falha* com sessão e papel insuficiente → mensagem "Você não tem permissão para ver esta página." sem o conteúdo. Controle de logout: *em andamento* (desabilitado + progresso), *sucesso* (sessão encerrada no servidor via mutation `logout`, volta ao login), *falha* (mensagem genérica pt-BR, permanece na área interna).
- `mnemonicos-frontend/src/components/internal-shell.test.tsx`.

### Não inclui
- A tela de login (TASK-003-014).
- A barreira real de autorização (é o backend — FR-002-012; TASKs 003-007, 003-011).
- Telas de gestão de equipe (fora — §4.2 da SPEC).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `layout.tsx` do grupo `(interno)` compõe `InternalShell`.
2. `InternalShell` — `useMeQuery`: `isLoading` → carregando neutro (`role="status"`); `isError`/sem sessão → `router.replace('/login')`; sessão + `requiredRole` acima do papel → "sem permissão"; senão `children`.
3. Controle de logout — `useLogoutMutation`; `disabled` + progresso; sucesso → `router.push('/login')`; falha → mensagem genérica, permanece.
4. Testes com mock de `useMeQuery`/`useLogoutMutation`.

## Critérios de pronto

- [ ] O `InternalShell` exibe um estado de carregamento neutro (sem `children`) enquanto `useMeQuery` resolve — verificação executável: `npm --prefix mnemonicos-frontend test -- internal-shell` → com `useMeQuery` mockado em `isLoading`, `getByRole('status')` traz texto pt-BR de carregando neutro (não 'qualquer nó') e `children` não é renderizado. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] O `InternalShell` renderiza `children` com sessão válida e papel suficiente, redireciona para `/login` sem sessão, e mostra "Você não tem permissão para ver esta página." com papel insuficiente — verificação executável: `npm --prefix mnemonicos-frontend test -- internal-shell` → 3 casos via mock de `useMeQuery`: sucesso + papel suficiente → `children` no DOM; erro / sem sessão → redirect para `/login` chamado; sucesso + `requiredRole` acima do papel → texto de "sem permissão" sem `children`. `Tests: ≥3 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-013 (ramo "sessão válida + papel insuficiente → sem permissão") no gate 1 — verificação executável: `npm --prefix mnemonicos-frontend test -- internal-shell` → com `useMeQuery` devolvendo um usuário EDITOR e o `InternalShell` numa vista-stub que exige `requiredRole="ADMIN"`, o DOM mostra "Você não tem permissão para ver esta página." e **não** renderiza `children`; F1 não embarca tela ADMIN-only, então este ramo é provado aqui (não no gate 9). `Tests: ≥1 passed`. Fixada antes do código.
- [ ] O controle de logout fica desabilitado com indicador de progresso enquanto a mutation `logout` está pendente; em sucesso navega para `/login`; em falha mostra mensagem genérica em pt-BR e permanece — verificação executável: `npm --prefix mnemonicos-frontend test -- internal-shell` → 3 casos via mock da mutation `logout`: `pending` → controle `disabled` + progresso; resolvida → navegação para `/login` chamada; rejeitada (500) → `findByText` da mensagem genérica pt-BR, sem navegação. `Tests: ≥3 passed`. Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-frontend run lint` → exit 0 (baseline capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`next-16.md`, §1/§6.3 — esconder ≠ autorizar; README do repo vence em conflito).
- [ ] Code review aprovado.

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente**: app Next em `http://localhost:3000/` (raiz do grupo `(interno)`); API do backend em `http://localhost:3333/api/v1`; realm dev local (Postgres do `docker-compose`). Credenciais DEV vêm de `keelson.local.json` — o gate as injeta.

**Sujeito concreto**: EDITOR de teste `editor.gate@mnemonicos.local` e ADMIN semeado (`SEED_ADMIN_EMAIL`/`SEED_ADMIN_PASSWORD`), senhas fornecidas pelo gate.

**Pré-condição — montar**:
1. `env` do backend com `SEED_ADMIN_EMAIL`/`SEED_ADMIN_PASSWORD`; rodar o seed (`npm --prefix mnemonicos-backend run db:seed` ou `npx prisma db seed` em `mnemonicos-backend/`) → 1 ADMIN.
2. Autenticar como ADMIN e `POST /api/v1/users` `{ email: 'editor.gate@mnemonicos.local', name: 'Editor Gate', role: 'EDITOR', password: '<12+ chars>' }`.

**Pré-condição — restaurar** (ao fim): `DELETE FROM sessions WHERE "userId" IN (<id do EDITOR de teste>, <id do ADMIN de teste>);` e `DELETE FROM users WHERE email = 'editor.gate@mnemonicos.local';` no Postgres local — nunca todas as sessões do realm dev compartilhado.

**Passo (AC-002-013) — redirect e sucesso**: navegar a uma vista protegida do grupo `(interno)` — (a) em aba anônima, sem cookie `mnemo_access`: a navegação redireciona para `/login`; (b) logado como EDITOR: durante a resolução de `me`, um estado de carregamento neutro aparece; com sessão válida e papel suficiente, a vista renderiza. Este passo é o gate falsificável desses dois ramos de AC-002-013.

**Ramo "sessão válida + papel insuficiente → sem permissão"**: `n/a com motivo` — não há superfície ADMIN-only em F1; o ramo é coberto no **gate 1** (Testing Library com `useMeQuery` devolvendo EDITOR numa vista-stub que exige ADMIN — ver Critérios de pronto). Não há passo de gate 9 que hackeie `requiredRole` numa vista real.

**Passo (AC-002-027)**: logado como EDITOR na área interna, acionar o controle de logout — enquanto a requisição está pendente o controle fica desabilitado com indicador de progresso; em sucesso, a sessão é encerrada no servidor (verificar `sessions.revokedAt` preenchido para a família; reapresentar o cookie anterior a uma rota protegida → 401) e o usuário volta ao `/login`; simular falha (parar o backend ou mock de 500) → mensagem genérica em pt-BR e permanência na área interna. Este passo é o gate falsificável de AC-002-027.

## Riscos específicos

- O ramo "papel insuficiente" não tem superfície ponta-a-ponta em F1 (nenhuma tela ADMIN-only) — é coberto no gate 1 via vista-stub; o gate 9 registra o ramo como `n/a com motivo`. Sem prior handoff registrado para o slug.
- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-frontend/src/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-25
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
