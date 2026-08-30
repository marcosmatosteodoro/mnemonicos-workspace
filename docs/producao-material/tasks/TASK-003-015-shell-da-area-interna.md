# TASK-003-015: Shell da área interna

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: FR-002-013, FR-002-023
**Funcionalidade**: FEAT-002-002 (primária), FEAT-002-001
**Componente**: COMP-003-024, COMP-003-022
**Wave**: 7
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: In Progress
**Data início**: 2026-08-30T12:00:00-03:00

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 via `next/jest`, `testEnvironment: jsdom`, Testing Library — em `mnemonicos-frontend/`. Gate de tela: `gates.screenVerify` (Playwright MCP). Gates: `npm --prefix mnemonicos-frontend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: TASK-003-013
- **Bloqueia**: nenhuma

## Contexto

COMP-003-024 / DEC-003-011 / FR-002-013 / FR-002-023. Shell da área interna: resolve a sessão (`me`) e reflete os três estados de navegação protegida (carregando neutro / vista renderizada / redirect ou "sem permissão"), e hospeda o controle de logout com seus três estados observáveis. O backend é quem nega de fato (FR-002-012 — TASKs 003-007/011); o shell é apresentação.

**COMP-003-022 (EMENDA Wave 6)**: esta TASK cria o grupo de rotas `(interno)` — logo o `config.matcher` do `proxy.ts` (que TASK-003-013 deixou como *working set* `['/studio/:path*','/gestao/:path*']`) passa a ser **derivado** dos segmentos reais criados aqui, via símbolo compartilhado com o `layout.tsx`. O achado do gate 1/8 da Wave 6 era que `(interno)` não é endereçável por matcher e a lista à mão deriva em silêncio.

## Escopo

### Inclui
- `mnemonicos-frontend/src/app/(interno)/layout.tsx` — layout do grupo `(interno)`; compõe `InternalShell` (com uma prop `requiredRole`).
- `mnemonicos-frontend/src/app/(interno)/studio/page.tsx` — página de aterrissagem mínima da área interna (destino do `router.push` da tela de login — TASK-003-014 navega para `/studio`). Server Component simples; o conteúdo real do studio é fatia futura (F2+). Sem ela o sucesso do login cai em 404.
- `mnemonicos-frontend/src/components/internal-shell.tsx` — `'use client'`. Usa `useMeQuery`: *em andamento* → estado de carregamento neutro (nó `role="status"` com texto pt-BR); *sucesso* (sessão válida, papel suficiente) → renderiza `children`; *falha* sem sessão → redireciona para `/login`; *falha* com sessão e papel insuficiente → mensagem "Você não tem permissão para ver esta página." sem o conteúdo. Controle de logout: *em andamento* (desabilitado + progresso), *sucesso* (sessão encerrada no servidor via mutation `logout`, volta ao login), *falha* (mensagem genérica pt-BR, permanece na área interna).
- `mnemonicos-frontend/src/proxy.ts` (**EMENDA COMP-003-022 Wave 6**) — o `config.matcher` deixa de ser working set: passa a ser **derivado** dos segmentos de rota reais do grupo `(interno)` recém-criado (um símbolo compartilhado — ex.: `INTERNAL_ROUTE_PREFIXES` — exportado de um módulo que o `layout.tsx` também consome, nunca duas listas à mão). Nesta fatia o grupo tem `/studio`; se surgir outro segmento, entra no símbolo.
- `mnemonicos-frontend/src/components/internal-shell.test.tsx` · `mnemonicos-frontend/src/proxy.test.ts` (o teste do matcher passa a **enumerar** os segmentos de `src/app/(interno)/` e falhar se algum não estiver coberto por `config.matcher`; e afirmar que `/` — home pública — **não** é guardada).
- **`mnemonicos-frontend/src/store/api.ts` (carve-out — furo no plano: AC-002-027 × correção S1b da Wave 6)** — o `logout.onQueryStarted` foi endurecido na 2ª volta do S1b (Wave 6) com um `catch` que redireciona para `/login` em **qualquer** rejeição. Isso quebra AC-002-027/FR-002-023 (falha de logout → **permanece** na área interna e tenta de novo). Correção: o `catch` do `logout.onQueryStarted` **não força navegação** — o redirect da "sessão morta de vez" (401 + refresh também falhou) já vive no ramo `!renewed` do `baseQueryWithReauth`; falha transitória (500/rede, sessão ainda válida) → só `resetApiState()` (limpa o cache) e o `InternalShell` mostra "tente de novo". S1b intacto: `/auth/logout` continua fora de `PUBLIC_AUTH_PATHS` (não vira no-op) e a sessão morta continua expulsando a aba pelo `baseQueryWithReauth`.

### Não inclui
- A tela de login (TASK-003-014).
- A barreira real de autorização (é o backend — FR-002-012; TASKs 003-007, 003-011).
- Telas de gestão de equipe (fora — §4.2 da SPEC).
- O conteúdo real do studio (F2+) — `(interno)/studio/page.tsx` aqui é só aterrissagem.

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
- [ ] **[furo no plano — AC-002-027 × S1b]** Falha **transitória** de logout (500/rede) mantém o usuário na área interna — verificação executável: `npm --prefix mnemonicos-frontend test -- api` → com o `logout` mockado respondendo **500** (não 401), o `logout.onQueryStarted` **não** chama `reauth.redirect`/`window.location.assign`; `store.getState().api.queries` é zerado (`resetApiState`), a sessão `me` segue válida no mock. Mutante: `catch` do `logout.onQueryStarted` redireciona em qualquer rejeição → o caso 500 chama o redirect (vermelho). E o caminho "sessão morta de vez" (`logout` 401 + `refresh` 401) **continua** redirecionando para `/login` (pelo ramo `!renewed` do `baseQueryWithReauth` — teste `[retry S1b]` da TASK-003-013 segue verde). `Tests: ≥2 passed`. Fixada antes do código.
- [ ] **[EMENDA COMP-003-022 Wave 6]** `config.matcher` do `proxy.ts` é derivado do grupo `(interno)` real, e a home pública `/` não é guardada — verificação executável: `npm --prefix mnemonicos-frontend test -- proxy` → o teste **enumera** os segmentos de primeiro nível de `mnemonicos-frontend/src/app/(interno)/` (via `fs.readdirSync` ou lista literal derivada do símbolo compartilhado `INTERNAL_ROUTE_PREFIXES`) e afirma que **cada** um está coberto por `config.matcher` (aplicado com âncoras `^…$`); afirma que `/`, `/login`, `/_next/static/x` **não** casam. Mutante: adicionar um `(interno)/gestao/` (dir) sem tocar o símbolo → o teste de enumeração fica vermelho (segmento não coberto). Mutante: voltar o matcher a catch-all por exclusão → `matches('/')` vira `true` (vermelho). `Tests: ≥2 passed`. Fixada antes do código.
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
