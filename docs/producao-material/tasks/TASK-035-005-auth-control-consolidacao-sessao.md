# TASK-035-005: `AuthControl` — consolidação do controle único de sessão

**Slug**: producao-material
**Pertence a**: PLAN-035
**Realiza (FRs)**: FR-034-001, FR-034-002, FR-034-003, FR-034-004, FR-034-006, FR-034-014, FR-034-016
**Funcionalidade**: FEAT-034-001 (primária)
**Componente**: COMP-035-001 (principal), COMP-035-006
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-035-001 (consome `useMeSilentQuery`)
- **Bloqueia**: TASK-035-006

## Contexto

Hoje o único botão "Sair" vive dentro de `InternalShell` (`LogoutControl`,
`internal-shell.tsx:70-124`), com um `<header>` próprio que a área interna monta por
conta. `AuthControl` absorve esse comportamento — os mesmos três estados de AC-002-027 —
e passa a viver no header, alcançável de qualquer rota, decidindo entre "Entrar"/"Sair"/
neutro a partir de `useMeSilentQuery` (TASK-035-001), sem nunca disparar logout a partir de
um clique sem sessão (DEC-035-006; memo — PLAN-035 §3 COMP-035-001/006, §6 DEC-035-006).

## Escopo

### Inclui
- `mnemonicos-frontend/src/components/auth-control.tsx` (novo, `'use client'`): usa
  `useMeSilentQuery()` para saber se há sessão. Três estados: **neutro**
  (`isLoading`/`isUninitialized` — não é "Entrar" nem "Sair", nenhum clique aciona ação);
  **"Entrar"** (sem sessão — `useRouter().push('/login')`, sem estado assíncrono próprio);
  **"Sair"** (com sessão — MESMO comportamento de 3 estados hoje em
  `LogoutControl`/`internal-shell.tsx:84-124`: `useLogoutMutation()`, mesma mensagem
  `'Não foi possível sair agora. Tente novamente.'`, navegação `push('/login')` no sucesso —
  mova o componente/lógica, não duplique).
- Em `mnemonicos-frontend/src/components/internal-shell.tsx`: REMOVER o `<header
  className="flex items-center justify-end border-b px-4 py-3 sm:px-6">` e a função
  `LogoutControl` (linhas 68-124 hoje); `InternalShell` passa a renderizar só `<div
  className="mx-auto w-full max-w-5xl flex-1 px-4 py-8 sm:px-6">{children}</div>` dentro do
  `<div className="flex min-h-full flex-col">` que já envolve o corpo hoje.
- **Migração de prova** (lição ativa `guarda-nova-que-preempta-a-antiga-migra-a-prova-para-caminho-real`,
  `guidelines/project/lessons/guarda-nova-que-preempta-a-antiga-migra-a-prova-para-caminho-real.md`
  — `AuthControl` preempta `LogoutControl` como único consumidor de `useLogoutMutation()` no
  header/área interna): o describe `'InternalShell — controle de logout, três estados
  (FR-002-023 / AC-002-027)'` de `internal-shell.test.tsx:162-207` migra para um describe
  equivalente em `auth-control.test.tsx`, montando `AuthControl` (não mais
  `InternalShell`) com `useMeSilentQuery`/`useLogoutMutation` mockados — nunca fica em
  `internal-shell.test.tsx` testando um componente que não existe mais ali, nem vira mock
  que produz estado inalcançável. **Mesma migração para o arquivo inteiro**
  `internal-shell.integration.test.tsx` (6 casos, `internal-shell.integration.test.tsx:130-304`
  — todos montam `<InternalShell>` só para alcançar o botão "Sair" que agora não existe mais
  ali): vira `auth-control.integration.test.tsx`, montando `<AuthControl />` **e**
  `<InternalShell requiredRole="EDITOR">` **juntos**, sob o mesmo `<Provider store={store}>`
  (a composição real de uma rota interna: `SiteHeader`+`AuthControl` ao lado, `InternalShell`
  envolvendo o conteúdo) — a corrida que o caso `meIs401AfterLogout`
  (`internal-shell.integration.test.tsx:179-217`) prova depende do `useMeQuery` de
  `InternalShell` re-buscando `/auth/me` depois do logout disparado por `AuthControl`; montar
  só `AuthControl` isolado não reproduziria a corrida (os dois componentes agora são irmãos,
  não mais pai/filho — a prova precisa da MESMA vizinhança que a produção monta).

### Não inclui
- Montagem de `AuthControl` no `SiteHeader` (TASK-035-006, que o torna visível de fato).
- Comportamento de login/logout em si (`useLoginMutation`/`useLogoutMutation`, mensagens,
  `/auth/login`/`/auth/logout`) — intocado, SPEC-002/SPEC-016.

## Critérios de pronto

- [ ] Sem sessão (`useMeSilentQuery` retorna `{ data: null, isLoading: false }`) →
      renderiza "Entrar"; clique → navega para `/login`, NUNCA chama `useLogoutMutation` —
      cobre AC-034-001, AC-034-003, AC-034-006, NFR-034-002 e AC-034-013 (parte — rótulo do controle de
      autenticação; a parte do alternador é de TASK-035-004), pelo próprio `getByRole('button',
      { name: 'Entrar' })` usado na asserção. Verificação executável: `npm --prefix mnemonicos-frontend
      test -- src/components/auth-control.test.tsx` → `PASS`, mockando `@/store/api` (mesmo
      padrão de `internal-shell.test.tsx:12-15`) e afirmando, após o clique com
      `user-event`, `pushMock` chamado com `'/login'` e o mock de `useLogoutMutation`'s
      trigger NUNCA chamado. Mutante: fazer o clique disparar logout também reprova.
- [ ] Com sessão → renderiza "Sair" com os 3 estados (em andamento/sucesso/falha), mesma
      mensagem `'Não foi possível sair agora. Tente novamente.'`, navegação para `/login`
      no sucesso — cobre AC-034-002, AC-034-004, AC-034-014 (migração de AC-002-027). Mesmo arquivo,
      reaproveitando/adaptando literalmente os 3 casos de
      `internal-shell.test.tsx:172-206` (trigger de `useLogoutMutation` resolvendo/
      rejeitando, mesmas asserções de `aria-busy`/`role="status"`/mensagem).
- [ ] `useMeSilentQuery` ainda carregando/não iniciado (`isLoading: true` ou
      `isUninitialized: true`) → nem "Entrar" nem "Sair" renderizado, clique não aciona
      nada — cobre AC-034-016. Mesmo arquivo, caso com o mock retornando esse estado e
      afirmando ausência dos dois `role="button"` (`"Entrar"`/`"Sair"`) via `queryByRole`.
- [ ] `internal-shell.test.tsx` atualizado: SEM asserção de botão "Sair" dentro de
      `InternalShell` (ele não existe mais ali) — o describe `'InternalShell — controle de
      logout...'` (`internal-shell.test.tsx:162-207`) é removido do arquivo (migrado acima),
      e um teste negativo novo confirma `screen.queryByRole('button', { name: 'Sair' })` ===
      `null` ao montar `InternalShell` com sessão ativa. Verificação executável: `npm
      --prefix mnemonicos-frontend test -- src/components/internal-shell.test.tsx` → `PASS`,
      sem nenhum `it()` referenciando `useLogoutMutation`/mensagem de logout.
- [ ] Comportamento montado contra a `api` real (RTK Query real + `fetch` mockado) — o
      predicado de estado (neutro/Entrar/Sair) que `AuthControl` deriva de
      `useMeSilentQuery`/`useLogoutMutation` só se prova de verdade com o componente
      MONTADO contra a store real (lição ativa "Predicado de decisão de UI a partir de
      estado de RTK Query só se prova no componente montado",
      `guidelines/project/lessons.md:542-576`; molde:
      `internal-shell.integration.test.tsx`, ambiente `<rootDir>/test/jsdom-fetch-env.js`) —
      novo `auth-control.integration.test.tsx`, montando `<Provider store={makeStore()}>` com
      `<AuthControl />` e `<InternalShell requiredRole="EDITOR"><Protected /></InternalShell>`
      lado a lado (mesma vizinhança de produção), reproduzindo os 6 cenários de
      `internal-shell.integration.test.tsx:130-304` (logout 500 → mensagem persiste, sem
      navegação/reset; logout 204 → navega, sem mensagem; logout 204 + `me` 401 seguinte →
      sem laço de refresh, sem `?sessao=expirada`; logout 500 + 401 autenticado seguinte →
      ainda expulsa via refresh esgotado; login dentro da janela `justLoggedOut` limpa a
      flag; janela expira e a re-autenticação volta ao normal) — cobre AC-034-002, AC-034-004, AC-034-014 no
      caminho real, e a passagem do `me`/`InternalShell` continuando a funcionar do lado de
      `AuthControl`/`meSilent` sem side-effect cruzado. Verificação executável: `npm
      --prefix mnemonicos-frontend test -- src/components/auth-control.integration.test.tsx`
      → `PASS` (6+ casos). Mutante: qualquer um dos mutantes já documentados no arquivo
      original (`resetApiState()` fora do `finally`, `justLoggedOut` não expirando, etc.)
      continua reprovando no novo arquivo.
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff.

## Riscos específicos

- Nenhum específico desta TASK além dos já cobertos pelas TRISKs do PLAN.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**:

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
