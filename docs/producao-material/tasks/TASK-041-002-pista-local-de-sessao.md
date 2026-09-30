# TASK-041-002: Gravar e apagar a pista local de sessão em login, logout e `me`

**Slug**: producao-material
**Pertence a**: PLAN-041
**Realiza (FRs)**: FR-040-010
**Componente**: COMP-041-002 (principal)
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: TASK-041-001
- **Bloqueia**: TASK-041-003

## Contexto

O navegador passa a guardar uma marca não-sensível de "houve sessão aqui" (`localStorage`), gravada quando o login conclui ou a sessão é confirmada pela área interna (`me` com `data`, **só o login e o `me` com sucesso gravam** — uma conta sem acesso, que recebe 403, não grava) e apagada quando o logout conclui — sem mudar nada do que login e logout fazem hoje. A pista só decidirá, na TASK-041-003, **se há conferência** (nunca acesso): sem pista, a conferência não chama o backend (o cabeçalho segue chamando `GET /auth/me` em `/` para todo visitante, `useMeSilentQuery`). Território e decisões: DEC-041-002 do PLAN-041, memo de exploração (item 5: pós-login `router.push(next ?? INTERNAL_HOME)`) e `MAP.md` do slug.

## Escopo

### Inclui
- `mnemonicos-frontend/src/lib/session-hint.ts` (novo) — `SESSION_HINT_KEY` (`'mnemonicos:session-hint'`, exportada para o bootstrap e os testes), `hasSessionHint(): boolean`, `setSessionHint(): void`, `clearSessionHint(): void`; valor gravado **fixo e não-sensível**, o literal `'1'` (sem identificador, e-mail nem papel); qualquer exceção — acesso à propriedade `localStorage` (`SecurityError`), `getItem`/`setItem`/`removeItem` lançando, modo privado — resolve para "sem pista" e **nunca propaga**. Nome do arquivo conferido contra o perfil §3 (util em `src/lib/`, `kebab-case`; sem prefixo de design system).
- `mnemonicos-frontend/src/lib/session-hint.test.ts` (novo; molde de estrutura: `src/lib/theme-bootstrap.test.ts`).
- `mnemonicos-frontend/src/store/api.ts` — `login.onQueryStarted`: `setSessionHint()` **só após** `await queryFulfilled` (sucesso); `logout.onQueryStarted`: `clearSessionHint()` **só após** sucesso. Ramos de falha (`catch`), `justLoggedOut`, `resetApiState` e o restante dos dois endpoints ficam como estão.
- `mnemonicos-frontend/src/components/internal-shell.tsx` — quando `useMeQuery` resolve com sessão (`data` presente, qualquer papel), `setSessionHint()` num efeito (cobre sessões anteriores ao deploy que passem pela área interna); sem `data`/com erro não grava. A renderização e o redirecionamento do `InternalShell` não mudam.
- `mnemonicos-frontend/src/components/session-hint.integration.test.tsx` (novo; molde: `src/components/auth-control.integration.test.tsx` — `@jest-environment <rootDir>/test/jsdom-fetch-env.js`, `makeStore()` real, `fetch` espionado por pathname, `next/navigation` mockado, timers falsos auto-avançados, `__resetAuthGuards()` no `beforeEach`).

### Não inclui
- `homeSessionCheck`, `silentRefresh` e qualquer leitura da pista por conferência — TASK-041-001 e TASK-041-003; o uso de `hasSessionHint`/`setSessionHint`/`clearSessionHint` a partir do **resultado** da conferência (`access`/`no-session`) é da TASK-041-003.
- Bootstrap inline do `<html>`, CSS, `HomeSessionGate`, `page.tsx` — TASK-041-003.
- `src/components/login-form.tsx`, `src/components/auth-control.tsx`, `src/proxy.ts` e `mnemonicos-backend/**` (login e logout mudam só pelos `onQueryStarted` do store; nenhum componente de login/logout é editado).

## Critérios de pronto

Convenção dos comandos: executados na raiz do repositório `mnemonicos-frontend` (o worktree da branch; `npm test` = `jest`), caminhos relativos a ela (`mnemonicos-frontend/src/x` do Inclui = `src/x`). Base de comparação = commit-base `b729a76`. Fixação: comandos **executados** pelo Tech Lead em b729a76 (`thoughts/local/sessions/20260930-132831-a408a37d/fixacao-TASK-041.md`, Tech Lead, 2026-09-30); o developer reconfirma a baseline **antes do primeiro edit** e registra aqui a saída literal.

- [ ] **Baseline capturada antes do código (não-regressão de login/logout/`InternalShell`)** — `npm test -- src/components/login-form.test.tsx src/components/internal-shell.test.tsx src/components/auth-control.integration.test.tsx src/store/api.test.ts` no commit-base → `Test Suites: 4 passed, 4 total`, `Tests: 115 passed, 115 total`, 0 failed (igualdade medida em b729a76 — `fixacao-TASK-041.md`: `login-form` + `internal-shell` = 37, mais `auth-control.integration` + `api.test` = 78). Fecho: o mesmo comando depois do código → **115 passed, 115 total**, 0 failed. Falha quando um dos `onQueryStarted` ou o `InternalShell` muda comportamento além da pista.
- [ ] **`session-hint.ts` — contrato do item (sem AC)** — `npm test -- src/lib/session-hint.test.ts` → `Tests: 9 passed, 9 total`; um caso por linha: **S1** `SESSION_HINT_KEY` é o literal `'mnemonicos:session-hint'` (valor do PLAN-041 §5) · **S2** `hasSessionHint()` é `false` sem pista · **S3** `setSessionHint()` → `hasSessionHint()` é `true` · **S4** `clearSessionHint()` → `false` · **S5** `localStorage.getItem(SESSION_HINT_KEY) === '1'` após `setSessionHint()` (igualdade com o literal fixado; nenhum dado de pessoa: a função não recebe argumento) · **S6** `localStorage.getItem` lançando → `hasSessionHint()` devolve `false` sem propagar · **S7** `localStorage.setItem` lançando → `setSessionHint()` não propaga e `hasSessionHint()` segue `false` · **S8** `localStorage.removeItem` lançando → `clearSessionHint()` não propaga · **S9** o **acesso à propriedade** `window.localStorage` lançando (`SecurityError` no getter, eixo distinto do método) → `hasSessionHint()` `false`, `setSessionHint()` e `clearSessionHint()` sem propagar. Um mutante por sujeito (remover o `try/catch` de cada uma das 3 funções → S6/S9, S7/S9 e S8/S9 reprovam respectivamente): **M1**, **M2**, **M3**.
- [ ] **Fiação no store e no `InternalShell`, com store real** (oráculo montado — lição `predicado-de-decis-o-de-ui-a-partir-de-estado-de-rtk-query-s-se-prova-no-componente-montado`, que vale para o efeito do `InternalShell` montado contra a `api` real) — `npm test -- src/components/session-hint.integration.test.tsx` → `Tests: 12 passed, 12 total`; **W1** `login` 200 → pista presente · **W2** `login` 401 → pista **ausente** · **W3** pista presente + `logout` 204 → pista apagada · **W4** pista presente + `logout` 500 → pista **preservada** · **W5** `InternalShell` montado, `me` 200 EDITOR → pista presente · **W6** `InternalShell` montado, `me` 401 + refresh 401 → pista ausente · **W7** `InternalShell` montado, `me` **403** (STUDENT real, `requireRole`; sessão sem papel de acesso, que a lição `leitura-exigida-para-todo-papel-fica-fora-da-guarda-de-papel-da-acao` manda não ficar atrás de guarda de papel) → pista **ausente** (só o login e o `me` com sucesso gravam) e o comportamento de hoje preservado: `useMeQuery` com 403 → `isError` → `router.replace('/login')` e render `null` (`internal-shell.tsx:35-55`; a mensagem de permissão só aparece com `data`, W12) · **W8** `localStorage.setItem` lançando → `login.initiate` resolve com o usuário e o cache é zerado como hoje (sem propagar) · **W9** `localStorage.removeItem` lançando → `logout` 204 conclui, `resetApiState` acontece e a navegação segue (caso de AC-040-024 abaixo) · **W10** login pela UI — ver critério de AC-040-024 · **W11** logout pela UI — idem · **W12** `InternalShell` montado, `me` 200 STUDENT (**defesa em profundidade**, declarado: o backend real responde 403, W7) → pista presente (o efeito grava para qualquer papel com `data`). Mutantes (cada um deve deixar o arquivo **vermelho** pelo comando acima): **M4** `setSessionHint()` do `login` fora do sucesso (antes do `await queryFulfilled`) → W2 · **M5** remover `setSessionHint()` do `login` → W1 · **M6** `clearSessionHint()` do `logout` fora do sucesso → W4 · **M7** remover `clearSessionHint()` do `logout` → W3 · **M8** `setSessionHint()` do `InternalShell` incondicional (mesmo sem `data`) → W6 (e W7) · **M9** remover o efeito do `InternalShell` → W5 · **M10** `setSessionHint()` do `InternalShell` só para papel de acesso → W12.
- [ ] **AC-040-024 e FR-040-010 (login e logout inalterados, valor observável completo — nunca "o teste não muda")** — `npm test -- src/components/session-hint.integration.test.tsx` → **W10** `LoginForm` real sobre a store real: login 200 sem `next` → `router.push` chamado 1× com `INTERNAL_HOME` (`'/studio'`) e com `next="/studio/equipe"` → chamado 1× com `'/studio/equipe'`, nunca `INTERNAL_HOME` nesse caso; **W11** `AuthControl` real sobre a store real: logout 204 → `router.push('/login')` exato, 0 `reauth.redirect`, 0 `POST /auth/refresh`; **W8/W9** provam que falha de storage não altera nenhum desses desfechos. Prova pré-existente lida no eixo do predicado: `login-form.test.tsx:119,132,193` afirmam o destino do `push` (INTERNAL_HOME / `next`) com a mutation **mockada** — provam o componente, não a costura com o store real; o caso W10 fecha a costura. Diff de escopo: `git diff --stat b729a76 HEAD -- src/components/login-form.tsx src/proxy.ts` → saída **vazia** (ausência; no commit-pai também vazia — o alvo não-vazio do diff da TASK é coberto pelos critérios anteriores).
- [ ] Mutantes: **11 mutantes declarados (M1–M10 + Mutante A), 11 provas** (Mutante A — remover `resetApiState` do `logout.onQueryStarted` → W9 — acrescentado no retry dos gates da Wave 2) — aplicados ao arquivo real **em worktree descartável** (`git worktree add ../wt-mut-041-002 HEAD`, `node_modules` ligado ao do worktree principal, nunca `npm install`/`npm ci`), cada um rodado pelo comando do critério correspondente (arquivo inteiro, nunca `-t`) com controle negativo (sem mutante, mesmo comando → verde, mesma contagem) antes da rodada; ao fim `git worktree remove` e `git status --porcelain` da árvore da TASK **vazio** (o symlink `node_modules` do worktree está em `info/exclude`) (lição `sonda-de-investiga-o-n-o-nasce-em-tests-contagem-de-teste-declara-a-rvore`).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (produção e teste) — `npx eslint --max-warnings=0 $(git diff --name-only --diff-filter=d b729a76...HEAD | grep -E '\.(ts|tsx)$')` → exit 0; `npm run typecheck` → exit 0; `npx prettier --check $(git diff --name-only --diff-filter=d b729a76...HEAD)` → exit 0; `npm run lint` → exit 0.

## Riscos específicos

- **Sobreposição de arquivo (resolvida por ordem)**: edita `src/store/api.ts` em região disjunta da TASK-041-001 (`login`/`logout` `onQueryStarted` aqui; `baseQueryWithReauth`/novo endpoint lá). Sem dependência semântica, mas depende da 001 por ordem (T1): W1 = 001, W2 = 002 — nada de execução paralela no mesmo arquivo.
- **Dono das chamadas por resultado de conferência**: o PLAN-041 cita a gravação em `access` e a limpeza em `no-session` tanto no COMP-041-002 quanto no COMP-041-004; nesta decomposição ficam **na TASK-041-003** (quem consome o resultado), para manter esta TASK e a TASK-041-001 independentes. Registrado em `duvidas` do scribe.
- A pista é sinal de UX, nunca de autorização (DEC-041-002): nenhuma decisão de acesso passa por ela.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-30T15:20:08-0300
**Data conclusão**: 2026-09-30T15:32:14-0300
**Commit SHA**: ccb7fea
**Jira**: — (sub-task não criada: acesso ao Jira retirado pelo Diretor; pendente de reconciliação)

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado — security-engineer (Wave 2)
- [x] Comportamento (gate 9): consolidado (DoD, Etapa 4) — SPEC-040 sem FEATs; login/logout reais no Roteiro da TASK-041-003
<!-- Branch, tentativas, arquivos, revisores e narrativa (retries, escalações) vivem no
ledger da sessão e no commit da closure (4.76) — não se repetem aqui (4.409). -->
