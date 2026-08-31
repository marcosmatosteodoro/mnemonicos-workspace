# TASK-003-014: Tela de login

**Slug**: producao-material
**Pertence a**: PLAN-003
**Realiza (FRs)**: FR-002-009
**Funcionalidade**: FEAT-002-001 (primária)
**Componente**: COMP-003-023
**Wave**: 7
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done
**Data início**: 2026-08-30T11:51:49-03:00

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — estratégia `unica`; não criar branch por task)
**Padrão de commit**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`) — sem automação de release
**Framework de teste**: Jest 30 via `next/jest`, `testEnvironment: jsdom`, Testing Library — em `mnemonicos-frontend/`. Gate de tela: `gates.screenVerify` (Playwright MCP). Gates: `npm --prefix mnemonicos-frontend test` / `run lint` / `run typecheck`.

## Dependências

- **Depende de**: TASK-003-013
- **Bloqueia**: nenhuma

## Contexto

COMP-003-023 / DEC-003-011 / FR-002-009 / NFR-002-009. Formulário de login com os três estados observáveis (em andamento / sucesso / falha) e mensagem de erro genérica em pt-BR que não aponta campo. Identificadores de código em inglês, texto de interface em pt-BR. `page.tsx` é Server Component; `login-form.tsx` é `'use client'` (tem estado e evento) e consome a mutation `login` de COMP-003-021 via `.unwrap()`. A página lê `SESSION_EXPIRED_PARAM` (TASK-003-013) e mostra uma mensagem de sessão expirada quando presente.

## Escopo

### Inclui
- `mnemonicos-frontend/src/app/login/page.tsx` — Server Component; compõe o `LoginForm`; lê `SESSION_EXPIRED_PARAM` (importado de `src/store/api.ts` — TASK-003-013) dos search params e, quando presente (`?sessao=expirada`), renderiza uma mensagem genérica em pt-BR ("Sua sessão expirou. Entre novamente.") num nó com `role="status"`; ausente o parâmetro, a mensagem não aparece.
- `mnemonicos-frontend/src/components/login-form.tsx` — `'use client'`. Estados: *em andamento* (controle de submissão desabilitado + indicador de progresso num nó com `role="status"` ou `aria-busy="true"` no form, com texto pt-BR), *sucesso* (navega para a área interna), *falha* (mensagem genérica pt-BR "E-mail ou senha inválidos.", sem distinguir; formulário volta a aceitar entrada; nenhum campo apontado).
- `mnemonicos-frontend/src/components/login-form.test.tsx` (Testing Library: comportamento em 401); `mnemonicos-frontend/src/app/login/page.test.tsx` (mensagem de sessão expirada com/sem o parâmetro).

### Não inclui
- Shell interno / controle de logout (TASK-003-015).
- `baseQueryWithReauth` (TASK-003-013).
- Validação de força de senha no cliente (a política é do servidor — FR-002-022).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os 'Critérios de pronto', os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `page.tsx` mínimo, compõe `LoginForm`; lê os search params e renderiza a mensagem de sessão expirada num `role="status"` quando `SESSION_EXPIRED_PARAM` presente.
2. `LoginForm` — `useLoginMutation`; `disabled` + progresso (`role="status"` / `aria-busy`) enquanto `isLoading`; `catch` do `.unwrap()` → estado de falha com a mensagem genérica.
3. Em sucesso, `router.push` para a área interna.
4. Teste com mock da mutation retornando 401.

## Critérios de pronto

- [ ] O `LoginForm` desabilita o controle de submissão e mostra indicador de progresso enquanto a mutation `login` está pendente — verificação executável: `npm --prefix mnemonicos-frontend test -- login-form` → com a mutation `login` mockada em estado `pending`, `getByRole('button')` está `disabled` e `getByRole('status')` (ou o form com `aria-busy="true"`) traz texto pt-BR de progresso — não 'qualquer nó'. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] O `LoginForm` renderiza a mensagem genérica em pt-BR sem apontar campo quando a mutation `login` rejeita — verificação executável: `npm --prefix mnemonicos-frontend test -- login-form` → após a mutation mockada rejeitar com 401, `findByText('E-mail ou senha inválidos.')` aparece, nenhum campo com `aria-invalid`, e os inputs voltam a aceitar entrada (não ficam `disabled`). `Tests: ≥2 passed`. Fixada antes do código.
- [ ] Testes cobrem AC-002-028 (mensagem de sessão expirada na tela de login) — verificação executável: `npm --prefix mnemonicos-frontend test -- login` → renderizando `/login?sessao=expirada`, há um `role="status"` com o texto pt-BR de sessão expirada ("Sua sessão expirou. Entre novamente."); sem o parâmetro, `queryByRole('status')` para essa mensagem é nulo. `Tests: ≥1 passed`. Fixada antes do código.
- [ ] Identificadores de código em inglês e texto de interface em pt-BR (NFR-002-009) — verificação executável: `npm --prefix mnemonicos-frontend run lint` → exit 0 (baseline capturada no início da TASK); o teste de componente afirma o texto pt-BR exato exibido na falha ("E-mail ou senha inválidos."). `Tests: ≥1 passed`. Fixada antes do código.
- [ ] **[retry Wave 7 — gate 8 ACHADO 2]** O `<form>` tem `method="post"` e o controle de submit fica desabilitado até a hidratação — verificação executável: `npm --prefix mnemonicos-frontend test -- login-form` → o `<form>` renderizado tem atributo `method="post"` (mutante: remover `method` → um submit nativo pré-hidratação vira `GET /login?email=…&password=…`, vazando credencial na URL — asserção fica vermelha); e o botão de submit está `disabled` no primeiro render antes de os efeitos rodarem (flag de hidratação: `disabled={isLoading || !hydrated}`). `Tests: ≥1 passed`. Fixada antes do código.
- [ ] **[retry Wave 7 — gate 7 A5]** O destino do `router.push` em sucesso é o símbolo canônico `INTERNAL_HOME` importado de `@/lib/internal-routes` — não um literal `'/studio'` local — verificação executável: `npm --prefix mnemonicos-frontend test -- login-form` → a asserção de sucesso é `expect(pushMock).toHaveBeenCalledWith(INTERNAL_HOME)` com `INTERNAL_HOME` importado do módulo canônico (mutante: renomear o segmento em `INTERNAL_ROUTE_PREFIXES` → `proxy.test.ts` **e** `login-form.test.tsx` ficam vermelhos juntos, nunca verde com o login empurrando para 404). `grep -n "INTERNAL_HOME\s*=\s*'" mnemonicos-frontend/src/components/login-form.tsx` → sem resultado (a constante não é redefinida no componente). `Tests: ≥1 passed`. Fixada antes do código.
- [ ] `npm --prefix mnemonicos-frontend run build` → exit 0 (gate `quality.build` da ficha).
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-frontend run lint` → exit 0 (baseline capturada no início da TASK).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`next-16.md`, §1 — Server/Client Components; identificadores/interface; README do repo vence em conflito).
- [ ] Code review aprovado.

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente**: app Next em `http://localhost:3000/login`; API do backend em `http://localhost:3333/api/v1`; realm dev local (Postgres do `docker-compose`). Credenciais DEV vêm de `keelson.local.json` — o gate as injeta; não escrever segredo aqui.

**Sujeito concreto**: EDITOR de teste `editor.gate@mnemonicos.local` (senha de 12+ caracteres definida na criação, fornecida pelo gate). O ADMIN semeado (`SEED_ADMIN_EMAIL`/`SEED_ADMIN_PASSWORD`) é usado só para criar o EDITOR.

**Pré-condição — montar**:
1. Garantir `SEED_ADMIN_EMAIL` e `SEED_ADMIN_PASSWORD` no `env` do backend; rodar o seed (`npm --prefix mnemonicos-backend run db:seed` ou `npx prisma db seed` em `mnemonicos-backend/`) → 1 ADMIN.
2. Autenticar como ADMIN (`POST http://localhost:3333/api/v1/auth/login`) e criar o EDITOR: `POST http://localhost:3333/api/v1/users` com `{ email: 'editor.gate@mnemonicos.local', name: 'Editor Gate', role: 'EDITOR', password: '<12+ chars>' }`.

**Pré-condição — restaurar** (ao fim): `DELETE FROM sessions WHERE "userId" IN (<id do EDITOR de teste>, <id do ADMIN de teste>);` e `DELETE FROM users WHERE email = 'editor.gate@mnemonicos.local';` no Postgres local — nunca todas as sessões do realm dev compartilhado.

**Passo (AC-002-009)**: abrir `http://localhost:3000/login`; submeter e-mail + senha corretos do EDITOR — enquanto a requisição está pendente o botão de submit fica desabilitado e há indicador de progresso; em sucesso a navegação leva à área interna (`/(interno)`). Repetir com a senha errada — uma mensagem genérica em pt-BR ("E-mail ou senha inválidos.") é exibida, nenhum campo é apontado como a causa, e o formulário volta a aceitar entrada. Este passo é o gate falsificável de AC-002-009 (o trânsito à área interna em sucesso não é exercitável só com Testing Library).

## Riscos específicos

- Mensagem de erro genérica: não distinguir e-mail inexistente de senha errada (espelha AC-002-002 no backend).
- Repos symlinkados (lição de exploração): editar/verificar pelo caminho dentro do link (`mnemonicos-frontend/src/...`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-08-30T11:51:49-03:00
**Data conclusão**: 2026-08-31T10:22:38-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 9aabaf1 (implementação) · f6cc4ed (retry Wave 7 — FIX5 `INTERNAL_HOME` derivado do símbolo; FIX6 `<form method="post">` + gate de hidratação)
**Jira**: KAN-24
**Implementado por**: developer
**Revisado por**: code-reviewer (gates 1–7) · security-engineer (gate 8) — `revisado_por ≠ implementado_por`
**Tentativas**: 2 (implementação + 1 retry consolidado da rodada de gates da Wave 7)
**Cobertura final**: n/a (não coletada; piso do projeto 50% mantido — suíte frontend 68→86)
**Arquivos modificados**:
  - mnemonicos-frontend/src/app/login/page.tsx
  - mnemonicos-frontend/src/app/login/page.test.tsx
  - mnemonicos-frontend/src/components/login-form.tsx
  - mnemonicos-frontend/src/components/login-form.test.tsx

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando — frontend jest 86/86 (11 suítes); lint/typecheck/build exit 0
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado — code-reviewer, re-review da Wave 7 (2ª volta): FIX5/FIX6 fechados com mutante morto (`INTERNAL_HOME` rename cruza `proxy.test.ts` + `login-form.test.tsx`; remover `method="post"` → vermelho; `disabled` sem `!hydrated` → vermelho)
- [x] ACs verificados — AC-002-009 (três estados do form, gate 1) · AC-002-028 (mensagem de sessão expirada) · gate 8 ACHADO 2 fechado (`<form method="post">` — sem vazamento de credencial em GET pré-hidratação)
- [x] Segurança (gate 8): aprovado (Wave 7, 2ª volta) — security-engineer; ACHADO 2 (MEDIA, `<form>` sem `method=`) FECHADO, verificado por `renderToStaticMarkup`
- [ ] Comportamento (gate 9): pendente_handoff (FEAT-002-001) — qa; trânsito real à área interna no sucesso de login não exercitável (causa: `credencial` — `keelson.local.json` realm `app` com `loginPath`/`username`/`password` nulos + apps fora do ar). Seed consolidada em HANDOFF-PLAN-003.md. O que o qa exercitou (gate 1 do form; AC-002-028 com execução real) APROVADO.

**Notas**: FR-002-009 / NFR-002-009 satisfeitos. O destino pós-login (`INTERNAL_HOME`) é derivado do símbolo canônico `INTERNAL_ROUTE_PREFIXES` (`internal-routes.ts`), não um literal duplicado. Rodada de gates da Wave 7 rodou 1× sobre o diff acumulado das duas TASKs (4.90); os achados de A5/gate8-ACHADO2 desta TASK foram roteados aqui e fechados no retry `f6cc4ed`.
