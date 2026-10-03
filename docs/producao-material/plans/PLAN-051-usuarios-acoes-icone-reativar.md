# PLAN-051: Usuários — ações em ícone e reativação de conta

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.1
**Autor**: scribe (redação delegada pelo Tech Lead; reconhecimento técnico do `code-scout`, 2 rodadas)
**Data**: 2026-10-03

## Aderência a guidelines

**Decisões irreversíveis do slug tocadas**: nenhuma. A única decisão irreversível do INDEX é DEC-029-003 (snapshot de `ContentVersion`), sem vizinhança com esta entrega (gestão de contas, sem conteúdo versionado).
**Decisões irreversíveis de outros slugs em conflito**: nenhuma — `infra-vercel` não tem bloco de decisões (pasta sem `INDEX.md`).
**Exceções aos guidelines**: nenhuma. Backend segue `guidelines/project/backend/node-22.md` (camadas `schema → service → routes`, `AppError`/error handler central, Express 5 encaminha rejeição ao error handler); frontend segue `guidelines/project/frontend/next-16.md` (Server Components por padrão, `'use client'` só onde há estado/evento, estado de servidor em RTK Query, tokens no `@theme`/`globals.css`).

## Cobertura

**SPEC referenciada**: SPEC-050
**Slice declarado**: cobertura total (Caso D — 100% da SPEC-050: FR-050-001..014 e NFR-050-001..003; `graph.sh --format=tables` não tem linha para SPEC-050 — nenhum PLAN anterior cobre nenhum destes FRs/NFRs)

**FRs cobertos**:
- FR-050-001
- FR-050-002
- FR-050-003
- FR-050-004
- FR-050-005
- FR-050-006
- FR-050-007
- FR-050-008
- FR-050-009
- FR-050-010
- FR-050-011
- FR-050-012
- FR-050-013
- FR-050-014

**NFRs cobertos**:
- NFR-050-001
- NFR-050-002
- NFR-050-003

## 1. Visão técnica

Toca os dois repositórios. Jira: KAN-219 (modo link). A barreira real continua sendo o servidor (`requireRole('ADMIN')` a cada requisição, NFR-050-002) — a tela é conveniência, como em PLAN-049.

**Backend** (`mnemonicos-backend`): uma rota nova, espelhando exatamente o padrão das três mutações de conta já existentes (`disableUser`/`resetUserPassword`, `users.routes.ts`/`users.service.ts`) — mesma guarda (`verifyOrigin` + `requireRole('PATCH', '/users/:id/enable', 'ADMIN')`), mesmo formato de erro (`NotFoundError('Conta não encontrada.')`), sem transação `Serializable` (não há guarda de "último ADMIN" na reativação — direção oposta ao risco que essa guarda mitiga). Sem migração (A-050-002): `enableUser` só grava `disabledAt: null`, o mesmo campo que `disableUser` já marca. A guarda de login (A-050-007) foi **confirmada no código** pela 2ª rodada do `code-scout`: os 4 pontos (`login`, `resolveAccessSession`, `refresh`, `getSessionUser`) checam só `disabledAt !== null` em `auth.service.ts` — limpar o campo já basta para a pessoa voltar a autenticar (FR-050-004), sem tocar `auth.service.ts`. O log da reativação (NFR-050-001) estende o padrão existente de auditoria estruturada (`lib/audit.ts` + pino) com um tipo de evento novo, paralelo ao de auth (DEC-051-011) — sem tabela nova, sem migração.

**Frontend** (`mnemonicos-frontend`): a coluna "Ações" passa de dois botões de texto (`ROW_ACTIONS` em `users-list.tsx`) para **um** controle compacto por linha, ícone SVG inline + tooltip, que alterna entre "Desativar"/"Ativar" conforme a Situação — nunca os dois. A troca de forma (de "botão condicional, mapeado por ação" para "um único botão sempre presente, props computadas da Situação") é o que permite ao nó DOM sobreviver à transição de estado e ao foco pós-sucesso voltar ao controle da própria linha (AC-050-001; DEC-051-013). `ResetPasswordDialog` deixa de ser montado por `UsersList` (FR-050-012) mas continua existindo em `account-action-dialogs.tsx` — dívida/espera da página de edição (RISK-050-001), sem diff nela própria. Um componente novo, `EnableAccountDialog`, reusa `AccountConfirmDialog` como `DisableAccountDialog` já reusa (DEC-049-014 do PLAN-049, herdada). O anúncio de sucesso ("Conta ativada."/"Conta desativada.") usa a região `role="status" aria-live="polite"` que `UsersScreen`/`onNotice` já expõem — nenhum mecanismo novo. Os dois textos que hoje negam a reativação (`DISABLE_CONSEQUENCE` em `account-action-dialogs.tsx`, `DUPLICATE_HINT` em `create-user-form.tsx`) são revisados.

**Gates**: gate 8 (segurança) aplica — rota nova ADMIN-only, guarda de origem; gate 9 (comportamento verificado) com contas ADMIN/EDITOR/descartável reais, `pendente_handoff` se o ambiente faltar (RISK-050-004; lembrar a diretriz do Diretor de 2026-10-01 contra 2º ADMIN real, RISK-050-007); gate 10 n/a (SVG inline, sem dependência, sem endpoint pesado); gate 11 (design/UX) aplica — troca de texto por ícone tem histórico de re-gate de AA no slug (RISK-050-003).

## 2. Stack e dependências

Stack vigente, sem reescolha e **sem dependência nova** nos dois repositórios (DEC-051-010): backend Express 5 + Zod + Prisma 7 (sem migração) + pino (logger já existente); frontend Next 16 (App Router) + React 19 + Tailwind 4 (tokens em `@theme`/`globals.css`) + RTK Query (`@reduxjs/toolkit` ^2.12.0). Jest 29/30 + Testing Library nos dois lados.

Reúso: `requireRole`, `verifyOrigin`, `AppError`/error handler central, `isTransactionWriteConflict` (não usada aqui, mas o padrão de catch fica disponível se a guarda mudar), `userIdParamSchema` (backend); `AccountConfirmDialog`, `toUserMessage`/`getServerMessage` (`user-admin-errors.ts`), `onNotice`/`role="status"` de `UsersScreen`, `FOCUS_CLASS`/`surface-card`/`text-danger` e o padrão de ícone SVG local já usado em `password-field.tsx` (`EyeOpenIcon`/`EyeClosedIcon`/`LockIcon`, `aria-hidden="true"`, `fill="none" stroke="currentColor"`) — precedente direto para os ícones novos (frontend).

Arquivos tocados (inventário):

Backend (relativos a `mnemonicos-backend/`) — alterados: `src/modules/users/users.service.ts` (nova função `enableUser`), `src/modules/users/users.routes.ts` (nova rota), `src/lib/audit.ts` (tipo e função de evento de auditoria de usuário, paralelos aos de auth), `tests/unit/audit.test.ts` (novo describe para `recordUserAuditEvent`), `tests/integration/users.integration.test.ts` (novos casos de `PATCH /users/:id/enable`; emenda das asserções de "4 rotas montadas" e `ROUTE_ROLES` para 5), `tests/integration/route-authz-matrix.integration.test.ts` (array 48→49 + comentário do título). Nenhum arquivo de produção novo — reúso total dos módulos existentes. Sem migração Prisma, sem diff em `schema.prisma`, `.env*` nem `domain/types.ts`.

Frontend (relativos a `mnemonicos-frontend/`) — alterados: `src/store/api.ts` (mutation `adminEnableUser`), `src/components/users-list.tsx` (coluna de Ações: ícones, tooltip, controle único por linha, foco estável, wiring de `EnableAccountDialog`, remoção do botão "Redefinir senha"), `src/components/account-action-dialogs.tsx` (`EnableAccountDialog` novo; `DISABLE_CONSEQUENCE` revisado; remoção de `triggerRef.current = null` em `DisableAccountDialog.confirm`), `src/components/create-user-form.tsx` (`DUPLICATE_HINT` revisado), `src/components/users-list.disable.integration.test.tsx` (asserções de foco pós-sucesso), `src/components/users-list.integration.test.tsx` (estrutura da coluna sem "Redefinir senha", ícone em vez de texto), `src/components/create-user-form.integration.test.tsx` (texto do 409), `src/store/api.test.ts` (URL de `adminEnableUser`). Novo: `src/components/users-list.enable.integration.test.tsx` (molde de `users-list.disable.integration.test.tsx`). **Fora do diff**: `account-confirm-dialog.tsx`, `password-field.tsx`, `users-screen.tsx` (mecanismo de `onNotice` já existe), `internal-routes.ts`/`internal-nav.ts`/`proxy.ts`/`internal-shell.tsx` (guarda ADMIN de `/users` já existe desde PLAN-049), `confirm-remove-dialog.tsx`, `login-form.tsx`, `globals.css`, `night-palette-tokens.ts`, `.env*`, qualquer migração.

## 3. Componentes

### COMP-051-001: `enableUser` — reativação idempotente com log
**Responsabilidade**: `src/modules/users/users.service.ts` (backend) — nova função `enableUser(id: string, actorId: string): Promise<void>`, no mesmo arquivo e estilo de `disableUser`/`resetUserPassword`. Lê o alvo (`select: { disabledAt: true }`); `null` → `NotFoundError('Conta não encontrada.')` (FR-050-014). Já ativa (`disabledAt === null`) → retorna sem gravar e **sem emitir evento** (FR-050-003/FR-050-006, idempotência — espelha o guard "já desativada" de `disableUser:144`). Senão: `prisma.user.update({ where: { id }, data: { disabledAt: null } })` seguido de `recordUserAuditEvent({ type: 'user.reactivated', at: now, actorId, targetId: id })` (COMP-051-003). Sem transação `Serializable`: não há contagem de ADMIN nem condição de corrida que a SPEC peça bloquear nesta direção (A-050-007/RISK-050-007 — reativar ADMIN produz 2º ADMIN ativo é risco de produto, não de dado, mitigado por diretriz operacional, TRISK-051-007). A guarda de login (FR-050-004) não precisa de código aqui: `auth.service.ts` já checa só `disabledAt !== null` nos 4 pontos confirmados pelo `code-scout` (login, `resolveAccessSession`, `refresh`, `getSessionUser`) — limpar o campo já é suficiente. Testes (`tests/integration/users.integration.test.ts`, molde das describes de `disableUser` já existentes): `enableUser(id inexistente)` → `NotFoundError`; conta desativada → `disabledAt` vira `null`, exatamente 1 evento de log (espião de `logger.info`); conta já ativa → resolve, `disabledAt` permanece `null`, **nenhuma** chamada a `logger.info` com `audit.type === 'user.reactivated'`; depois de reativar, login real com a senha existente passa (prova de AC-050-003, mesma massa de `users.integration.test.ts`).
**Realiza**: FR-050-003, FR-050-004, FR-050-006, FR-050-014
**Interface pública**: `enableUser(id, actorId): Promise<void>`
**Dependências**: COMP-051-003

### COMP-051-002: `PATCH /users/:id/enable` — rota e guarda
**Responsabilidade**: `src/modules/users/users.routes.ts` — nova rota, mesmo padrão método-aware das demais (`requireRole('PATCH', '/users/:id/enable', 'ADMIN')` + `verifyOrigin` antes do handler, comentário de cabeçalho do arquivo atualizado para 4 mutações de estado). Handler: `userIdParamSchema.parse(req.params)` (reusado, sem schema novo), `await enableUser(id, req.auth.userId)`, `res.status(200).json({ id, status: 'active' as const })` (espelha o 200 de `disable`). `req.auth.userId` é o `actorId` — mesmo contrato de `req.auth` que `authenticate.ts` já popula (`AuthContext.userId`). Sem `try/catch` (Express 5 encaminha a rejeição ao error handler). Testes: `users.integration.test.ts` — sem sessão → 401; EDITOR → 403, `disabledAt` inalterado (AC-050-004/NFR-050-002); ADMIN → 200, `disabledAt` vira `null`; `Origin`/`Referer` fora de `CORS_ORIGINS` → 403 sem efeito (mesma prova de `verifyOrigin` que as outras 3 mutações já têm); id não-UUID → 422.
**Realiza**: FR-050-005, NFR-050-002
**Interface pública**: rota `PATCH /users/:id/enable`, resposta `200 {id, status: 'active'}`
**Dependências**: COMP-051-001

### COMP-051-003: Log de auditoria de ação de usuário — tipo paralelo ao de auth
**Responsabilidade**: `src/lib/audit.ts` — acrescenta, no mesmo arquivo (reusa o import de `logger` e o `redact` de 1 nível já documentado), um tipo e uma função **paralelos** a `AuthAuditType`/`recordAuthEvent`, sem generalizá-los (DEC-051-011): `export type UserAuditType = 'user.reactivated';`, `export interface UserAuditEvent { type: UserAuditType; at: Date; actorId: string; targetId: string; }` (objeto plano de 1 nível, mesma restrição do `redact`), `export function recordUserAuditEvent(event: UserAuditEvent): void { logger.info({ audit: event }, \`user:${event.type}\`); }`. Nunca recebe senha nem token. Testes: `tests/unit/audit.test.ts` — novo `describe('recordUserAuditEvent', ...)` no molde do existente para `recordAuthEvent`: emite por `logger.info` sob a chave `audit`; inclui `at`/`actorId`/`targetId`/`type`; conjunto exato de chaves (sem campo extra); nenhuma chave de material sensível.
**Realiza**: NFR-050-001
**Interface pública**: `UserAuditType`, `UserAuditEvent`, `recordUserAuditEvent(event)`
**Dependências**: nenhuma

### COMP-051-004: Emendas ao censo de rotas e à não-regressão de autorização
**Responsabilidade**: mantém a não-regressão das suítes de contrato do backend (RISK-050-005). `tests/integration/route-authz-matrix.integration.test.ts` — acrescenta `'PATCH /users/:id/enable'` ao array literal (48→49 pares) e atualiza o comentário do título ("...49 pares método+caminho... TASK-???/KAN-219 somou PATCH /users/:id/enable, 48→49"); acrescenta o mapeamento de path parametrizado (`/users/:id/enable` → `/users/<uuid>/enable`) nos testes 401/403 que precisarem da forma concreta. `tests/integration/users.integration.test.ts` — emenda as duas asserções estruturais existentes: "as N rotas montadas são exatamente as de gestão" (4→5) e "cada par método+caminho de gestão está em `ROUTE_ROLES` com exatamente `{ADMIN}`" (acrescenta o par novo); roda sem edição o teste "todo handler de rota é precedido por um guard `requireRole` que nega sem `req.auth`" (cobre a rota nova por generalização de enumeração, sem caso hardcoded). Nenhum FR próprio além da não-regressão — mitiga RISK-050-005 (tripwire por desenho, não defeito).
**Realiza**: FR-050-005
**Interface pública**: nenhuma (suíte de teste)
**Dependências**: COMP-051-002

### COMP-051-005: Mutation `adminEnableUser`
**Responsabilidade**: `src/store/api.ts` — endpoint novo, molde exato de `adminDisableUser` (`store/api.ts:896-899`): `adminEnableUser: build.mutation<void, { id: string }>({ query: ({ id }) => ({ url: \`/users/${encodeURIComponent(id)}/enable\`, method: 'PATCH' }), invalidatesTags: ['User'] })`. Sem segredo no argumento (só `id`) — usa o hook normal gerado (`useAdminEnableUserMutation`), sem `track:false` (DEC-049-010 do PLAN-049 não se aplica: nada aqui é senha). `invalidatesTags: ['User']` refaz a lista ativa após o sucesso, mesmo padrão das outras 3 mutations de conta. Testes: `src/store/api.test.ts` — `adminEnableUser` monta `PATCH /users/<id>/enable` com o `id` codificado por `encodeURIComponent` (mesma prova já existente para `adminDisableUser`/`adminResetPassword`).
**Realiza**: FR-050-002, FR-050-003
**Interface pública**: `useAdminEnableUserMutation()` (hook gerado), `AdminEnableUserArgs = { id: string }` (inline no `build.mutation`, sem tipo exportado — mesmo padrão de `adminDisableUser`)
**Dependências**: COMP-051-002

### COMP-051-006: `EnableAccountDialog` e revisão dos dois textos
**Responsabilidade**: `src/components/account-action-dialogs.tsx` — novo componente `EnableAccountDialog({ account, triggerRef, fallbackFocusRef, onClose, onNotice })` sobre `AccountConfirmDialog`, molde de `DisableAccountDialog` sem a ramificação `isSelf` (A-050-005: reativar a própria conta não é cenário possível — só conta desativada oferece "Ativar", e quem está logado está numa conta ativa). Título "Ativar conta"; descrição com nome e e-mail da conta-alvo + "A conta volta a conseguir entrar com as credenciais existentes." (FR-050-001); `confirmLabel="Confirmar ativação"`; `initialFocus="cancel"` (mesmo padrão de `DisableAccountDialog`, foco dentro da confirmação). Confirmar → `useAdminEnableUserMutation()` + `unwrap()` (COMP-051-005); em voo os botões ficam desabilitados com indicador (herdado de `AccountConfirmDialog`, sem diff nele); sucesso → `onNotice('Conta ativada.')` + `onClose()`, **sem** `triggerRef.current = null` (DEC-051-013 — o nó do botão da linha persiste e recebe o foco ao desmontar, agora mostrando "Desativar {nome}"); falha → `setError(toUserMessage(failure))` na própria confirmação, Situação exibida inalterada — cobre 404 "Conta não encontrada." (FR-050-014) pela mesma função já usada por `DisableAccountDialog`, sem ramo novo (404 é 4xx com mensagem do servidor, `toUserMessage` já repassa). `DisableAccountDialog.confirm` perde a linha `triggerRef.current = null;` no ramo não-`isSelf` (mesma razão: o botão da linha agora sempre existe, por isso o foco pode voltar a ele em vez do título — DEC-051-013). Textos revisados (FR-050-007/008/AC-050-006/007, emendas (a)/(b) da SPEC-050 §8): `DISABLE_CONSEQUENCE` → `'A pessoa será desconectada; a conta pode ser reativada depois pela mesma tela.'` (mantém a desconexão, troca a afirmação de indisponibilidade); `DUPLICATE_HINT` (`create-user-form.tsx`) → `'Se essa pessoa já teve uma conta desativada, é possível reativá-la na tela de Usuários.'`. As duas redações são rascunho funcional — o texto final cabe ao product-designer no gate 11 (mesmo tratamento que PLAN-049 deu à ajuda do papel ADMIN, A-048-015), desde que não voltem a afirmar indisponibilidade. Testes: `users-list.enable.integration.test.tsx` (novo, molde de `users-list.disable.integration.test.tsx`) — abre confirmação com nome/e-mail, foco inicial, Esc cancela e devolve foco, confirmar em voo trava botões, sucesso fecha e anuncia "Conta ativada.", conta já ativa (corrida/reenvio) não produz erro, 404 mostra mensagem e lista é refeita; `users-list.disable.integration.test.tsx` emendado — depois do sucesso de "Desativar", o foco volta ao **mesmo botão da linha** (agora "Ativar {nome}"), não mais ao título da tela; `create-user-form.integration.test.tsx` emendado — a asserção do texto do 409 usa a nova redação de `DUPLICATE_HINT`.
**Realiza**: FR-050-001, FR-050-002, FR-050-007, FR-050-008, FR-050-014
**Interface pública**: `<EnableAccountDialog account triggerRef fallbackFocusRef onClose onNotice />`
**Dependências**: COMP-051-005

### COMP-051-007: Coluna de Ações em controle único por linha — ícones, tooltip, foco estável
**Responsabilidade**: `src/components/users-list.tsx` — a célula de "Ações" deixa de depender de `user.status === 'active'` para decidir **se** mostra algo (hoje: nada quando desativada) e passa a sempre renderizar **exatamente um** `<button>`, na mesma posição da árvore, com `aria-label`/ícone/`onClick` computados a partir de `user.status` (FR-050-009) — é essa mudança de forma (de "render condicional por ação, mapeado" para "um nó só, props dinâmicas") que dá ao botão uma identidade de DOM estável através da troca de Situação (DEC-051-013), permitindo ao `triggerRef` capturado no clique continuar válido depois do refetch. `ROW_ACTIONS` (hoje array de 2 itens) é substituído por um mapa `ACTION_LABEL = { disable: 'Desativar', enable: 'Ativar' }` e uma função `actionFor(status)` que devolve `'disable' | 'enable'`. `aria-label` = `` `${ACTION_LABEL[kind]} ${user.name}` `` (ex. "Desativar Evelin Ferreira"/"Ativar Evelin Ferreira", FR-050-010); o botão fica dentro de um `<span className="group relative inline-flex">` e um `<span role="tooltip" className="... opacity-0 group-hover:opacity-100 group-focus-within:opacity-100">{mesmo texto do aria-label}</span>` absoluto — tooltip por CSS puro, sem estado novo (DEC-051-014). Dois ícones SVG inline novos, locais ao arquivo (mesmo padrão de `EyeOpenIcon`/`EyeClosedIcon`/`LockIcon` em `password-field.tsx`): `ActivateIcon` (círculo + check) para "Ativar", `DeactivateIcon` (círculo + X) para "Desativar" — `aria-hidden="true"`, `fill="none" stroke="currentColor"`, herdam a cor do texto do botão (par já medido via `surface-card`, TRISK-051-008); formas exatas ajustáveis no gate 11 sem mudar a semântica. Botão com `FOCUS_CLASS` (foco visível herdado) e tamanho fixo (`h-9 w-9 rounded-full`), operável por Tab/Enter/Espaço (semântica nativa de `<button>`, FR-050-011). Nenhum botão de texto "Redefinir senha" aparece mais na linha (FR-050-012) — a célula não renderiza mais `ResetPasswordDialog`; nenhum controle de "Editar"/"Excluir" (FR-050-013, já verdade hoje, preservado). `ActiveDialog['kind']` estreita de `'disable' | 'reset'` para `'disable' | 'enable'`; o bloco `{dialog?.kind === 'reset' ? <ResetPasswordDialog .../> : null}` é removido de `UsersList` (o componente continua existindo em `account-action-dialogs.tsx`, só não é mais montado daqui) e um bloco `{dialog?.kind === 'enable' ? <EnableAccountDialog .../> : null}` entra no lugar (COMP-051-006). `openDialog` passa a receber `actionFor(user.status)` em vez de `action.kind` do `.map()`. Testes: `users-list.integration.test.tsx` emendado — a coluna tem exatamente 1 controle por linha (ativa → "Desativar", desativada → "Ativar"), nunca os dois; nenhum botão com texto visível "Redefinir senha"; `aria-label` e o texto do `role="tooltip"` são idênticos; Tab alcança o controle e Enter/Espaço o acionam; contraste do ícone e do tooltip nos dois temas é prova de gate 11 (AC-050-010/NFR-050-003); AC-050-014 (comportamento herdado de Desativar sob o controle novo — último ADMIN, corrida 409, 404, autodesativação) roda sem alteração de asserção de resultado, só do seletor do controle (ícone em vez de texto).
**Realiza**: FR-050-009, FR-050-010, FR-050-011, FR-050-012, FR-050-013, NFR-050-003
**Interface pública**: `<UsersList search page onPageChange onNotice titleRef />` (inalterada — a mudança é interna à célula de Ações)
**Dependências**: COMP-051-006

### COMP-051-008: Emendas às suítes de contrato e provas de costura
**Responsabilidade**: mantém a não-regressão do slug (molde de COMP-049-010 do PLAN-049). (a) emendados: `users-list.integration.test.tsx`, `users-list.disable.integration.test.tsx`, `create-user-form.integration.test.tsx` (COMP-051-006/007); `users.integration.test.ts`, `route-authz-matrix.integration.test.ts` (COMP-051-004); (b) novo: `users-list.enable.integration.test.tsx`, novo describe em `audit.test.ts` (b) rodados **sem edição**: `password-field.test.tsx`, `login-form.test.tsx`, `proxy.test.ts`, `internal-routes.test.ts`, `internal-nav.test.ts`, `internal-shell.test.tsx`, `internal-sidebar.test.tsx`, `globals-theme-contrast.test.ts` — nenhum deles é tocado por esta entrega (a guarda ADMIN de `/users` e a navegação já existem desde PLAN-049); (c) suíte inteira dos dois repositórios verde antes do fecho. Nenhum FR próprio além da não-regressão da coluna de Ações.
**Realiza**: FR-050-009
**Interface pública**: nenhuma (suíte de teste)
**Dependências**: COMP-051-004, COMP-051-005, COMP-051-006, COMP-051-007

## 4. Fluxos principais

**F1 — Ativar conta desativada** (AC-050-001/002/003/013): ADMIN clica no controle "Ativar" da linha → `EnableAccountDialog` abre com foco em "Cancelar", nome/e-mail da conta-alvo visíveis → confirma → em voo botões travados com indicador → sucesso: confirmação fecha, `onNotice('Conta ativada.')`, a lista se refaz por `invalidatesTags` e a Situação da linha passa a "Ativa" **no mesmo nó de botão** que recebe o foco, agora rotulado "Desativar {nome}"; conta já ativa (reenvio/corrida) → mesmo caminho, sem erro, sem evento de log novo; 404 → mensagem "Conta não encontrada." na confirmação, Situação exibida inalterada, lista atualizada pela invalidação; depois do sucesso, a pessoa reativada autentica com a senha existente (prova real no gate 9).

**F2 — EDITOR tenta reativar direto no servidor** (AC-050-004): sem papel ADMIN → `requireAuth`/`requireRole` recusam com 403, `disabledAt` não muda, a tela do ADMIN continua funcionando — nenhuma mudança na barreira existente.

**F3 — Log da reativação** (AC-050-005): reativação com sucesso → `enableUser` chama `recordUserAuditEvent({type:'user.reactivated', at, actorId, targetId})` → pino emite `{audit:{...}}` sob a chave `user:user.reactivated`, consultável no coletor de produção; idempotência (conta já ativa) não emite evento.

**F4 — Coluna de Ações em controles compactos** (AC-050-008..012/014): cada linha mostra exatamente um controle — ícone + `aria-label` + tooltip idênticos, identificando pessoa e ação —, alternando conforme a Situação; nenhum "Redefinir senha", nenhum "Editar"/"Excluir" na linha; o comportamento herdado de "Desativar" (último ADMIN, corrida 409, 404, autodesativação leva ao login) continua valendo sob o controle novo, só a forma do seletor muda (ícone, não texto).

**F5 — Textos revisados** (AC-050-006/007): a confirmação de "Desativar" e a dica de e-mail duplicado deixam de afirmar que a reativação não está disponível nesta tela.

## 5. Modelo de dados

Sem migração, sem mudança de schema, sem tipo de domínio novo nos dois lados (A-050-002): `enableUser` grava só `disabledAt: null` no mesmo campo que `disableUser` já preenche; `UserStatus`/`status: 'active'|'disabled'` já existem e não mudam. `UserAuditEvent` (COMP-051-003) é um objeto efêmero de log (pino) — nunca uma linha de banco; "consultável depois do fato" (NFR-050-001) depende do coletor de produção agregar/reter esse log, não de uma tabela (confirma RISK-048-008 continuar aberto para as outras 3 ações, e motiva o TRISK-051-001 abaixo). Estado novo em memória do cliente: nenhum — `EnableAccountDialog` segue exatamente o padrão de estado local (`busy`/`error`/`inFlight`) de `DisableAccountDialog`, sem campo de senha.

## 6. Decisões arquiteturais

### Decisões herdadas
- **DEC-051-001** [herdada] Stack vigente dos dois repositórios (Express 5 + Zod + Prisma 7 sem migração + pino; Next 16 + React 19 + Tailwind 4 + RTK Query), camadas `schema → service → routes` no backend, Server Components por padrão e `'use client'` só onde há estado/evento no frontend — fonte: perfil `node-22.md`/`next-16.md`, CLAUDE.md do workspace, PLAN-049 DEC-049-001
- **DEC-051-002** [herdada] Identificadores de código em inglês, texto de interface em pt-BR — fonte: CLAUDE.md do workspace, PLAN-049 DEC-049-002
- **DEC-051-003** [herdada] Guarda por rota via `requireRole(método, caminho, 'ADMIN')` + `verifyOrigin` nas mutações de estado, declarada em cada rota (nunca `.use()` cego no topo) — fonte: SPEC-050 A-050-001/A-050-006, `users.routes.ts` (PLAN-003 DEC-003-005)
- **DEC-051-004** [herdada] Sem migração de schema: a reativação só limpa o mesmo campo (`disabledAt`) que a desativação já preenche — fonte: SPEC-050 A-050-002
- **DEC-051-005** [herdada] Mensagens do servidor em 4xx exibidas como vêm; sem mensagem utilizável → genérica pt-BR sem eco do corpo; 404 → "Conta não encontrada." — fonte: SPEC-048 A-048-011, PLAN-049 DEC-049-004/DEC-049-016 (`user-admin-errors.ts`, sem diff)
- **DEC-051-006** [herdada] `AccountConfirmDialog` é o componente de confirmação reusado para a nova ação; o `ConfirmRemoveDialog` não é generalizado — fonte: PLAN-049 DEC-049-014
- **DEC-051-007** [herdada] Anúncio de sucesso pela região `role="status" aria-live="polite"` já exposta por `UsersScreen`/`onNotice` — fonte: PLAN-049 COMP-049-009 (`users-screen.tsx`), aplicado aqui para "Conta ativada."/mecanismo de anúncio que AC-050-001 deixa ao PLAN
- **DEC-051-008** [herdada] Autorização decidida no servidor a cada requisição, deny-by-default; a tela e o controle são conveniência de navegação, nunca o controle de acesso — fonte: SPEC-050 NFR-050-002, PLAN-049 DEC-049-003
- **DEC-051-009** [herdada] Reativar a própria conta não é um cenário possível nesta SPEC (só conta desativada oferece "Ativar"; quem está logado está, por definição, numa conta ativa) — fonte: SPEC-050 A-050-005

### DEC-051-010: Origem do controle visual — SVG próprio inline, sem biblioteca de ícones
**Contexto**: FR-050-009/010 exigem um controle compacto com ícone por ação; nenhuma biblioteca de ícones está instalada hoje (confirmado pelo `code-scout`: grep por `lucide|heroicons|react-icons|@radix-ui/react-icons|@tabler/icons|phosphor-icons` sem match em `package.json`, dependencies/devDependencies lidos por completo). O repositório já tem precedente de SVG inline para ilustração (`LoginIllustratedPanel`) e para ícone funcional pequeno com `aria-hidden="true"` (`EyeOpenIcon`/`EyeClosedIcon`/`LockIcon` em `password-field.tsx`). Esta entrega precisa só de 2 ícones (Ativar/Desativar).
**Decisão**: dois componentes SVG inline, locais a `users-list.tsx`, no mesmo padrão de `password-field.tsx` — `fill="none" stroke="currentColor"`, `aria-hidden="true"`, cor herdada do botão (par já medido via `surface-card`).
**Alternativas consideradas**:
- Biblioteca de ícones (ex. `lucide-react`), descartada porque: nenhuma está instalada hoje — adicionar uma soma auditoria de dependência (RISK-050-006) e peso de bundle para só 2 ícones nesta entrega, sem ganho sobre o padrão zero-dependência já em uso no repositório para o mesmo tipo de elemento (ícone funcional pequeno).
- Ícone via fonte de glifos (ex. `font-awesome` como `@font-face`), descartada porque: dependência de rede/arquivo de fonte para 2 glifos, sem precedente no repositório e sem controle fino de `currentColor` por tema sem CSS extra.
**Consequências**: zero dependência nova; os dois ícones ficam acoplados a `users-list.tsx` (sem arquivo de ícones compartilhado) — se o KAN-218 (Editar/Excluir) ou outras telas precisarem de mais ícones, um módulo compartilhado de ícones SVG passa a valer a pena.
**Reabrir se**: o KAN-213 (sidebar, ainda em Backlog) decidir por biblioteca de ícones antes desta entrega, ou o produto acumular ícones o bastante para SVG próprio inline virar manutenção redundante (duplicação de `viewBox`/paths entre arquivos).
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-051-011: Mecanismo de log da reativação — tipo de evento paralelo, sem generalizar `AuthAuditType`
**Contexto**: NFR-050-001/A-050-003 exigem um registro consultável (quem/qual conta/quando) sem tabela de auditoria nova. O `code-scout` (2ª rodada) confirmou: existe log estruturado via pino (`lib/logger.ts` + `lib/audit.ts`), mas `AuthAuditType`/`recordAuthEvent` são um enum **fechado** e uma função específicos de eventos de auth/sessão (login/refresh/logout/authz.denied) — sem tipo para ações sobre uma conta (reativar/desativar/redefinir senha). Sem tabela de auditoria no banco hoje (confirma RISK-048-008).
**Decisão**: estender `lib/audit.ts` com um tipo e uma função **paralelos**, não uma generalização de `AuthAuditType`/`recordAuthEvent`: `UserAuditType` (hoje só `'user.reactivated'`), `UserAuditEvent {type,at,actorId,targetId}`, `recordUserAuditEvent(event)` — mesmo mecanismo de emissão (`logger.info({audit:event}, ...)`), mesmo arquivo (reusa o import do `logger` e a restrição de 1 nível do `redact`). Sem tabela nova no Prisma, sem migração.
**Alternativas consideradas**:
- Generalizar `AuthAuditType`/`AuthAuditEvent` para aceitar também eventos de ação de usuário (acrescentar `'user.reactivated'` ao enum existente e um campo opcional `targetId`), descartada porque: o enum é hoje documentado e testado (`audit.test.ts`) como fechado a auth/sessão (`subject` = ator/tentativa de login, sem noção de "conta-alvo" distinta do sujeito) — forçar uma ação sobre conta no mesmo tipo mistura dois domínios semânticos (quem se autenticou vs. o que um ADMIN fez a outra conta) e exigiria reabrir/reinterpretar `subject` nos 7 casos existentes só para caber o campo `targetId`.
- Tabela de auditoria nova (model Prisma dedicado), descartada porque: a SPEC-050 já declara essa mitigação como pontual (RISK-050-002, não fecha RISK-048-008 para as outras 3 ações) — criar tabela só para "reativar" seria escopo maior que o card KAN-219 e exigiria migração (autorização do Diretor antes de rodar, por regra do projeto).
- Reusar `recordAuthEvent` emitindo `type: 'authz.denied'` ou outro valor já existente com o alvo em `subject`, descartada porque: perderia a distinção entre quem agiu e sobre quem agiu (NFR-050-001 exige os dois), e colidiria com o significado já testado de `authz.denied` (recusa de autorização, não ação bem-sucedida).
**Consequências**: terceiro padrão de log estruturado no mesmo arquivo (dívida de consolidação, mesma classe de DEC-049-014/DEC-049-016 do PLAN-049 — dois tipos paralelos em vez de um genérico); "consultável depois do fato" depende de onde o coletor de produção agrega esse log (TRISK-051-001, não resolvido pelo código). Se as outras 3 ações (criar/desativar/redefinir) ganharem auditoria no futuro, este enum paralelo ganha mais valores — sem migrar para tabela por si só.
**Reabrir se**: o Diretor autorizar a história de auditoria de backend candidata (RISK-048-008) — nesse momento a tabela nova cobre as 4 ações de uma vez e este log pontual (`UserAuditType`) é substituído, não apenas estendido.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-051-012: Nome da rota e da função de serviço — `PATCH /users/:id/enable` / `enableUser`
**Contexto**: A-050-001 espelha a rota de desativar, deixando o nome exato ao PLAN. O vocabulário já em uso no código é `status: 'active'|'disabled'` e `disableUser`/`disable` (rota, serviço, mutation, teste) — "ativar"/"desativar" é só o rótulo em pt-BR da UI (SPEC-050 glossário).
**Decisão**: `PATCH /users/:id/enable`, função `enableUser`, mutation `adminEnableUser` — simétrico a `disable`/`disableUser`/`adminDisableUser` em cada camada.
**Alternativas consideradas**:
- `/activate` / `activateUser`, descartada porque: introduz um terceiro verbo (`active` já é o valor do campo `status`) sem ganho sobre o par simétrico já em uso (`disable`/`enable`), e quebraria a leitura em espelho do censo de rotas (`route-authz-matrix.integration.test.ts`, que lista os pares em grupos por recurso).
- `/reactivate` / `reactivateUser`, descartada porque: mais longo sem diferença semântica relevante da operação inversa de `disable`, e nenhuma outra rota do módulo usa prefixo `re-`.
**Consequências**: nenhuma — é só nomenclatura; o par simétrico facilita achar as duas rotas juntas no código e no censo.
**Reabrir se**: nunca — escolha de nomenclatura sem custo de reversão que justifique revisitar.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-051-013: Foco pós-ação ancorado no nó estável da linha, não em `triggerRef.current = null`
**Contexto**: AC-050-001 exige que, após "Ativar" **e** depois de "Desativar", o foco volte ao controle de ação da **mesma linha**, que passa a mostrar o nome acessível da ação inversa — diferente do comportamento de PLAN-049 (`DisableAccountDialog.confirm`), que zera `triggerRef.current` e deixa o foco cair no título da tela, porque até esta entrega a célula de Ações ficava **vazia** para conta desativada (`user.status === 'active' ? <div>...</div> : null` em `users-list.tsx:146-160`) — o botão clicado literalmente deixava de existir. Esta SPEC muda isso: agora toda linha, ativa ou desativada, sempre oferece um controle (FR-050-009) — o botão nunca desaparece, só troca de rótulo/ícone.
**Decisão**: a célula renderiza **um único** `<button>`, na mesma posição da árvore em todo render (nunca `null`, nunca dentro de um `.map()` sobre uma lista de ações), com `aria-label`/ícone/`onClick` computados a partir de `user.status`. Como a forma da árvore React não muda entre "ativa" e "desativada" (mesmo tipo de nó, mesma posição), o reconciliador reaproveita o mesmo nó DOM através da transição de Situação — o `triggerRef` capturado em `event.currentTarget` no clique continua `.isConnected === true` depois do refetch, e o efeito de desmonte de `AccountConfirmDialog` (já existente, sem diff) devolve o foco a ele corretamente. `DisableAccountDialog.confirm` perde a linha `triggerRef.current = null` no ramo não-`isSelf`, pela mesma razão.
**Alternativas consideradas**:
- Manter a renderização condicional atual (`null` quando desativada) e, ao fechar o diálogo, localizar o novo botão por `querySelector`/atributo `data-user-id` depois que o refetch completar, descartada porque: depende do momento exato em que a invalidação resolve (não-determinístico — pode levar mais de um ciclo de render), exigindo um efeito extra que observe `currentData` e um estado de "foco pendente" a casar com o usuário certo — complexidade desproporcional ao que a estabilidade de forma já resolve de graça.
- Um `Map<string, HTMLButtonElement>` de refs por `account.id`, atualizado em cada render, em vez de depender da reconciliação por posição, descartada porque: exige popular/limpar o mapa a cada render da lista (ciclo de vida próprio, risco de referência obsoleta) para o mesmo resultado que a forma única por célula já garante sem código extra.
**Consequências**: a célula de Ações não pode mais variar sua **forma** por condição (só suas props) sem reabrir esta decisão — um controle futuro (Editar/Excluir, KAN-218) que precise aparecer/desaparecer condicionalmente na mesma célula muda esse invariante (TRISK-051-002). O ganho é local a `users-list.tsx`; não exige mudança em `AccountConfirmDialog` nem em `account-confirm-dialog.tsx`.
**Reabrir se**: a célula de Ações precisar voltar a variar de forma (não só de props) entre estados — ex. KAN-218 acrescentando um controle condicional na mesma célula — ou o teste de foco da transição Desativar→Ativar/Ativar→Desativar falhar por outro motivo.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-051-014: Tooltip por CSS (`group-hover`/`group-focus-within`), sem componente de biblioteca nem estado novo
**Contexto**: FR-050-010 exige uma dica visível "ao focar ou passar o ponteiro" com o mesmo texto do nome acessível. Não há componente de tooltip no repositório (grep por `Tooltip`/`title=` sem precedente de uso funcional). O atributo HTML nativo `title` não aparece de forma confiável ao foco por teclado na maioria dos navegadores — só ao `hover` com atraso do agente.
**Decisão**: um `<span role="tooltip">` posicionado por CSS (absoluto sobre um contêiner `group relative`), com `opacity-0` e `group-hover:opacity-100 group-focus-within:opacity-100` (Tailwind 4, sem `tailwind.config.js`) — mesmo texto do `aria-label` do botão. Sem estado React, sem biblioteca.
**Alternativas consideradas**:
- Atributo `title` nativo isoladamente, descartada porque: não aparece de forma confiável ao foco via teclado (só hover, com atraso do navegador) — não cumpre "ao focar **ou** passar o ponteiro" (FR-050-010) nos dois casos.
- Biblioteca de tooltip (ex. `@radix-ui/react-tooltip`), descartada porque: dependência nova para 1 elemento de UI, mesmo custo de descarte da DEC-051-010 (zero-dependência já é o padrão escolhido para este PLAN).
- Tooltip com estado React (`onMouseEnter`/`onFocus` alternando `useState`) por botão, descartada porque: multiplica estado por linha (até 20 linhas × 1 ação) para o mesmo resultado visual que `group-hover`/`group-focus-within` já entrega sem nenhum `useState`.
**Consequências**: o tooltip não aparece em dispositivos touch sem foco por teclado (sem suporte a long-press) — aceito, a SPEC não pede touch (TRISK-051-003); o nome acessível (`aria-label`) já cobre leitor de tela independente do tooltip visual.
**Reabrir se**: a tela precisar de tooltip com comportamento mais rico (atraso configurável, posicionamento inteligente de borda) que o CSS puro não cubra, ou um terceiro consumidor no repositório precisar do mesmo padrão (aí vale extrair um utilitário/componente compartilhado).
**Irreversível**: não
**Aderência à ficha/perfil**: nova

## 8. Riscos técnicos

- **TRISK-051-001** A métrica §1.3 da SPEC-050 (contagem de eventos de reativação em 30 dias) depende de o log de produção **reter/ser consultável** por esse período — não confirmável pelo código deste repositório (o coletor de produção está fora do diff) (severidade: média; mitigação: declarar no INDEX a fonte do número e o dono — mesma régua que PLAN-049 usou para métrica com `Fonte de medição` externa, adaptada aqui: fonte é o próprio log instrumentado, dono é quem opera o coletor; gate 9 prova que o evento existe e tem o formato certo, não que ele sobrevive 30 dias).
- **TRISK-051-002** O foco pós-ação estável (DEC-051-013) depende de a célula de Ações nunca variar de **forma** entre os dois status, só de props — um controle futuro condicional na mesma célula (Editar/Excluir, KAN-218) pode reabrir essa suposição (severidade: baixa-média; mitigação: teste cobre a transição Desativar→Ativar e Ativar→Desativar; revisitar ao integrar KAN-218).
- **TRISK-051-003** O tooltip CSS-only (DEC-051-014) não aparece em dispositivo touch sem foco por teclado (severidade: baixa; mitigação: `aria-label` cobre leitor de tela independentemente; sem requisito de touch na SPEC).
- **TRISK-051-004** Corrida de duplo clique em "Ativar" pode gerar 2 eventos de log se duas requisições lerem `disabledAt !== null` antes de qualquer `update` — `enableUser` não usa transação `Serializable` (ao contrário de `disableUser`, que a usa para a guarda do último ADMIN) (severidade: baixa; mitigação: a UI trava o botão em voo (`inFlight`/`busy`, mesmo padrão de `DisableAccountDialog`) — só uma chamada direta ao servidor, fora da tela, duplicaria; aceito sem bloqueio, a SPEC não pede serialização nesta direção, RISK-050-007; se necessário no futuro, aplicar o mesmo padrão `Serializable` de `disableUser`).
- **TRISK-051-005** O censo de autorização do backend (`route-authz-matrix.integration.test.ts` + as duas asserções estruturais de `users.integration.test.ts`) exige 3 emendas manuais e são tripwires por desenho — esquecer qualquer uma quebra a suíte, não é regressão real (RISK-050-005 da SPEC) (severidade: baixa — falha é ruidosa e local; mitigação: COMP-051-004 lista os 3 pontos exatos).
- **TRISK-051-006** `UserAuditType` fechado em só `'user.reactivated'` hoje é um padrão paralelo a `AuthAuditType` (DEC-051-011) — se RISK-048-008 for autorizado, alguém precisa migrar para a tabela nova, não apenas somar mais valores ao enum paralelo (severidade: baixa; mitigação: `Reabrir se` da DEC-051-011 registra a condição).
- **TRISK-051-007** Reativar uma conta ADMIN desativada produz um 2º ADMIN ativo — herda RISK-048-009/RISK-032-006 e a diretriz do Diretor de 2026-10-01 (nenhum 2º ADMIN real até RISK-032-006 entrar) (severidade: média — risco de produto, não de dado; mitigação: diretriz operacional, não controle de código; gate 9 só com conta ADMIN descartável, nunca `admin2` real de dev; a Entrega relembra a diretriz).
- **TRISK-051-008** Troca de botões de texto por controles de ícone tem histórico de re-gate de acessibilidade no slug (RISK-050-003, FEAT-048/gate 11) (severidade: alta; mitigação: só tokens/utilitários já provados (`surface-card`, `FOCUS_CLASS`, `currentColor`); contraste do ícone e do tooltip medidos nos dois temas no gate 11; teste de fonte no molde de `internal-sidebar.source.test.ts` confere que as cores usadas pertencem ao conjunto de pares de `night-palette-tokens.ts`).
- **TRISK-051-009** Gate 9 exige conta ADMIN, EDITOR e conta descartável desativada/reativada reais; sem ambiente disponível a entrega fica `pendente_handoff` (mesmo padrão de RISK-050-004/PLAN-049 TRISK-049-006) (severidade: média; mitigação: roteiro em handoff com contas fornecidas pelo Diretor, nunca credencial no repositório).

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Aderência à ficha/perfil validada
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates)
- [ ] Backend: rota nova somada ao censo de rotas (48→49 pares, comentário do título atualizado), `ROUTE_ROLES` e as asserções de 401/403/origem cobrindo `PATCH /users/:id/enable`; frontend: suíte emendada verde (`users-list.integration.test.tsx`, `users-list.disable.integration.test.tsx`, `create-user-form.integration.test.tsx`), `password-field.test.tsx`/`login-form.test.tsx`/`proxy.test.ts`/`internal-*.test.ts`/`globals-theme-contrast.test.ts` verdes sem edição
- [ ] Prova de que a reativação idempotente (conta já ativa) não registra evento novo e a reativação real registra exatamente um, com `actorId`/`targetId`/`at` (AC-050-002/005, NFR-050-001)
- [ ] Prova em tela (gate 9, dois temas, 360 px) de Ativar/Desativar pelo controle compacto — foco voltando ao mesmo controle da linha, anúncio de sucesso, tooltip e `aria-label` idênticos ao focar/passar o ponteiro — e EDITOR recusado ao chamar a rota direto no servidor (403); o que não rodar fica em handoff declarado (TRISK-051-009)
- [ ] Métrica da SPEC operacional (§1.3, `Fonte de medição`: instrumentação): o evento `user.reactivated` existe e é consultável no log (gate 9 exibe o evento existindo); veredito em 30 dias do **deploy em produção**, "inconclusivo" se nenhuma reativação ocorrer no período

## 10. Não coberto por este PLAN

- Nenhum FR/NFR da SPEC-050 fica de fora (cobertura 100%: FR-050-001..014 e NFR-050-001..003).
- Fora de escopo herdado da SPEC (§4.2): **Editar conta** e **Excluir permanentemente** (ação e esqueleto de controle — card próprio do épico KAN-218); **mudar o papel** de uma conta existente; **cadastro público**, auto-registro e contas de estudante.
- **Realocação de "Redefinir senha"** para a futura página de edição — fora nesta entrega (RISK-050-001, risco aceito e registrado como pendência do épico); a rota de servidor continua existindo, só a UI na linha é removida.
- **Trilha de auditoria completa / tabela de auditoria nova** para criar, desativar e redefinir senha — RISK-048-008/RISK-050-002 continuam abertos; o log desta entrega (`UserAuditType`) é mitigação pontual só para reativar.
- **Biblioteca de ícones** — decidida como fora de escopo por DEC-051-010 (SVG próprio inline).
- Escape de curingas (`%`/`_`) na busca de contas — fora desde PLAN-049 (RISK-048-010/TRISK-049-007), sem relação com esta entrega.
- Qualquer mudança em `auth.service.ts`/mecanismo de sessão — a guarda de login já cobre a reativação sem diff (confirmado pelo `code-scout`).
