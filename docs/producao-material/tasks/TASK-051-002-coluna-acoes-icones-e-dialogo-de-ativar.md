# TASK-051-002: Coluna de Ações em ícones e diálogo de Ativar

**Slug**: producao-material
**Pertence a**: PLAN-051
**Realiza (FRs)**: FR-050-001, FR-050-002, FR-050-003, FR-050-007, FR-050-008, FR-050-009, FR-050-010, FR-050-011, FR-050-012, FR-050-013, FR-050-014
**Funcionalidade**: FEAT-050-001 (primária), FEAT-050-002
**Componente**: COMP-051-007 (principal), COMP-051-005, COMP-051-006, COMP-051-008
**Wave**: 1
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

## Contexto

Um ADMIN clica no controle "Ativar" (ícone, sempre presente) da linha de uma conta desativada
→ `EnableAccountDialog` abre, confirma → `adminEnableUser` chama o servidor → sucesso: a lista
se refaz, a Situação vira "Ativa" no **mesmo** nó de botão, que passa a mostrar "Desativar
{nome}" e recebe o foco. A coluna inteira "Ações" deixa de ser dois botões de texto
condicionais e passa a **um** controle compacto por linha (ícone + tooltip), sem "Redefinir
senha" na linha. Território, código existente e decisões vigentes vivem em `PLAN-051`
(DEC-051-010/013/014) e no `MAP.md` do slug — este contexto não os repete. O botão e o
diálogo que ele abre não são fronteiras independentes (princípio 2 da decomposição): nenhum
dos dois é útil entregue sozinho, por isso formam uma TASK só.

## Escopo

### Inclui
- `mnemonicos-frontend/src/store/api.ts` — `adminEnableUser: build.mutation<void, {id:
  string}>`, molde exato de `adminDisableUser` (linhas 896-899 hoje): `query: ({id}) =>
  ({url: \`/users/${encodeURIComponent(id)}/enable\`, method:'PATCH'})`,
  `invalidatesTags:['User']`.
- `mnemonicos-frontend/src/store/api.test.ts` — novo `it('adminEnableUser → PATCH
  /users/:id/enable', ...)` e `it('adminEnableUser codifica o id no segmento do path', ...)`,
  molde de `adminDisableUser` (linhas 340-361 hoje); soma `'adminEnableUser'` às 2 listas de
  nomes de endpoint do arquivo (próximo das linhas 146 e 210).
- `mnemonicos-frontend/src/components/account-action-dialogs.tsx` — novo componente
  `EnableAccountDialog({account, triggerRef, fallbackFocusRef, onClose, onNotice})`, molde de
  `DisableAccountDialog` (linhas 45-106 hoje) sem o ramo `isSelf` (A-050-005: reativar a
  própria conta não é cenário possível). Título "Ativar conta"; descrição com nome/e-mail da
  conta-alvo + "A conta volta a conseguir entrar com as credenciais existentes.";
  `confirmLabel="Confirmar ativação"`; `initialFocus="cancel"`. Confirmar →
  `useAdminEnableUserMutation()` + `unwrap()`; sucesso → `onNotice('Conta ativada.')` +
  `onClose()`, **sem** zerar `triggerRef.current` (DEC-051-013 — o nó do botão da linha
  persiste); falha → `setError(toUserMessage(failure))`, cobrindo 404 pela mesma função já
  usada por `DisableAccountDialog`. `DISABLE_CONSEQUENCE` (linhas 23-24 hoje) revisado para
  `'A pessoa será desconectada; a conta pode ser reativada depois pela mesma tela.'`;
  `DisableAccountDialog.confirm` perde a linha `triggerRef.current = null;` (linha 79 hoje) no
  ramo não-`isSelf`.
- `mnemonicos-frontend/src/components/create-user-form.tsx` — `DUPLICATE_HINT` (linhas 35-36
  hoje) revisado para `'Se essa pessoa já teve uma conta desativada, é possível reativá-la na
  tela de Usuários.'`.
- `mnemonicos-frontend/src/components/users-list.tsx` — a célula de Ações (hoje linhas
  145-161: `user.status === 'active' ? <div>{ROW_ACTIONS.map(...)}</div> : null`) deixa de
  depender da Situação para decidir **se** mostra algo e passa a sempre renderizar **1**
  `<button>`, na mesma posição da árvore. `ROW_ACTIONS` (linhas 12-15 hoje, 2 itens) é
  substituído por `ACTION_LABEL = {disable:'Desativar', enable:'Ativar'}` e uma função
  `actionFor(status): 'disable'|'enable'`; `aria-label` = `` `${ACTION_LABEL[kind]} ${user.name}` ``;
  o botão fica dentro de um elemento `span` (`className="group relative inline-flex"`) com um
  elemento `span` irmão de `role="tooltip"` (`opacity-0 group-hover:opacity-100
  group-focus-within:opacity-100`, mesmo texto do `aria-label`) posicionado absoluto. Dois ícones SVG
  inline novos, locais ao arquivo (molde de `EyeOpenIcon`/`EyeClosedIcon`/`LockIcon` em
  `password-field.tsx`): `ActivateIcon`/`DeactivateIcon`, `aria-hidden="true"`, `fill="none"
  stroke="currentColor"`. Botão com `FOCUS_CLASS` (linha 37-38 hoje) e tamanho fixo (`h-9 w-9
  rounded-full`). `ActiveDialog['kind']` (linha 33 hoje) estreita de `'disable'|'reset'` para
  `'disable'|'enable'`; o bloco `{dialog?.kind === 'reset' ? <ResetPasswordDialog .../> :
  null}` (linhas 191-200 hoje) é removido; entra `{dialog?.kind === 'enable' ?
  <EnableAccountDialog .../> : null}` no lugar. `openDialog` (linha 74 hoje) passa a receber
  `actionFor(user.status)` em vez do `action.kind` do `.map()` removido. `import {
  ResetPasswordDialog }` permanece (o componente continua existindo em
  `account-action-dialogs.tsx`, só não é mais montado daqui — remover o import não usado).
- `mnemonicos-frontend/src/components/users-list.integration.test.tsx` — emenda: as células
  de Ações (hoje linhas 96-106, texto `'DesativarRedefinir senha'`) passam a ter só
  `'Desativar'` (conta ativa) ou `'Ativar'` (conta desativada); nenhuma asserção de
  `getByText`/`getByRole('button', {name: /Redefinir senha/})` em linha nenhuma; cada linha tem
  exatamente 1 `getByRole('button')`; `aria-label` do botão e texto do `role="tooltip"` são
  idênticos; cabeçalho de colunas (linhas 289-295 hoje) inalterado. Caso novo de teclado
  (AC-050-010), molde de `password-field.test.tsx:106-123` (AC-016-004): `.focus()` direto no
  botão da linha + `user.keyboard('{Enter}')` abre a confirmação; fechar (Esc/Cancelar); de
  novo `.focus()` no mesmo botão + `user.keyboard(' ')` abre a confirmação — prova explícita,
  não mais "semântica nativa de `<button>`" implícita.
- `mnemonicos-frontend/src/components/users-list.disable.integration.test.tsx` — emenda do
  caso D5 (hoje linhas 286-309: "sucesso fecha, o foco vai ao título"): depois do sucesso de
  "Desativar", o foco volta ao **mesmo botão da linha**, agora rotulado "Ativar Zeca" — não
  mais ao heading "Contas". Os demais 11 casos (D1-D12, exceto D5) seguem sem alteração de
  asserção de resultado.
- `mnemonicos-frontend/src/components/create-user-form.integration.test.tsx` — emenda da
  asserção do texto de duplicidade de e-mail (hoje `const DUPLICATE_HINT = 'Se essa pessoa já
  teve uma conta desativada, a reativação ainda não está disponível por esta tela.'`, linhas
  35-36) para a nova redação.
- Novo: `mnemonicos-frontend/src/components/users-list.enable.integration.test.tsx`, molde
  integral de `users-list.disable.integration.test.tsx` (fake de rede próprio com handler
  `GET /users` + `PATCH /users/:id/enable`, fixture com conta ativa e desativada, UUID real nos
  ids — lição "fake de rede espelha o schema da rota", abaixo): abre confirmação com nome/
  e-mail e foco em "Cancelar"; Esc/Cancelar fecha sem PATCH e devolve foco ao botão "Ativar
  {nome}"; confirmar em voo trava os 2 botões sem duplo envio; sucesso fecha, anuncia "Conta
  ativada." e a linha mostra "Desativar {nome}" no mesmo nó (foco ali); conta já ativa
  (reenvio/corrida) não produz erro nem evento extra percebível; 404 mostra "Conta não
  encontrada." na confirmação e a lista é atualizada (molde D7c).

### Não inclui
- `account-confirm-dialog.tsx`, `password-field.tsx`, `users-screen.tsx` — mecanismos reusados
  (`busy`/efeito de foco, ícones de referência, região `role="status"`), sem diff.
- Realocação de "Redefinir senha" para a página de edição (RISK-050-001, fora desta entrega;
  `ResetPasswordDialog` continua existindo em `account-action-dialogs.tsx`).
- Biblioteca de ícones (DEC-051-010, fora — SVG próprio inline).
- `internal-routes.ts`/`internal-nav.ts`/`proxy.ts`/`internal-shell.tsx` (guarda ADMIN de
  `/users` já existe desde PLAN-049, sem diff).
- Backend (`PATCH /users/:id/enable`, log de auditoria, censo de rotas) — TASK-051-001.

## Critérios de pronto

- [ ] AC-050-001 (cobre FR-050-001, FR-050-002): confirmação abre com nome/e-mail e foco em
  "Cancelar"; em voo os 2 botões ficam desabilitados sem duplo envio; sucesso fecha a
  confirmação e a linha mostra "Ativa" sem recarregar, com o foco no mesmo botão da linha
  (agora "Desativar {nome}"); falha mostra a mensagem na confirmação sem mudar a Situação
  exibida; cancelar/Esc fecha sem PATCH e devolve o foco ao acionador — verificação:
  `(cd mnemonicos-frontend && npm test -- src/components/users-list.enable.integration.test.tsx)`
  → `Tests: N passed` (N ≥ 7, um por caso do molde D2/D3/D4/D5/D6/D7c/idempotência). Estado
  ANTES desta TASK (arquivo inexistente) faz o comando falhar por "no tests found" — prova que
  o comando acha o alvo.
- [ ] AC-050-001 (foco pós-"Desativar" no mesmo botão, não mais no título) — verificação:
  `(cd mnemonicos-frontend && npm test -- src/components/users-list.disable.integration.test.tsx -t "D5")`
  → `Tests: 1 passed`, `document.activeElement` é o botão `aria-label="Ativar Zeca"`. Mutante
  que reintroduz `triggerRef.current = null;` no `confirm` de `DisableAccountDialog` faz este
  teste reprovar (o foco cairia no título) — prova de resistência a contorno.
- [ ] AC-050-002 (parte tela — idempotência não produz erro visível): incluído no mesmo arquivo
  do critério acima (`users-list.enable.integration.test.tsx`, caso "conta já ativa/corrida").
- [ ] AC-050-006/AC-050-007 (textos revisados não afirmam indisponibilidade) — verificação:
  `(cd mnemonicos-frontend && npm test -- src/components/users-list.disable.integration.test.tsx -t "D2")`
  → `Tests: 1 passed`, asserção de que o texto de `DISABLE_CONSEQUENCE` **não contém** "não
  está disponível"; e
  `(cd mnemonicos-frontend && npm test -- src/components/create-user-form.integration.test.tsx -t "F8")`
  → `Tests: 1 passed`, mesma asserção para `DUPLICATE_HINT` (`-t "duplicad"` casaria as 4
  tests do describe "e-mail duplicado e erros por campo", não isola o alvo — fixado e
  corrigido nesta rodada: `-t "F8"` acha só o caso do 409/`DUPLICATE_HINT`). Os dois comandos
  falham contra o texto atual (que afirma indisponibilidade) — prova que o critério é
  falsificável.
- [ ] AC-050-008/AC-050-009/AC-050-011/AC-050-012 (1 controle por linha, `aria-label`+tooltip
  idênticos identificando pessoa e ação, sem "Redefinir senha", sem Editar/Excluir) —
  verificação: `(cd mnemonicos-frontend && npm test -- src/components/users-list.integration.test.tsx)`
  → `Tests: N passed`; cada linha tem exatamente 1 `getByRole('button')` dentro da célula de
  Ações, cujo `aria-label` é igual ao `textContent` do `role="tooltip"` irmão; nenhuma
  ocorrência de `/Redefinir senha/` em nenhuma célula; nenhum `getByRole('button', {name:
  /Editar|Excluir/})`. Asserção por valor literal no próprio slot, nunca
  `getAllByText(...).length>0` (lição ativa "tela que renderiza... prova cada campo com valor
  literal no slot", abaixo).
- [ ] AC-050-010 (teclado, foco visível — cobre FR-050-011, parte de NFR-050-003):
  operabilidade por Tab (alcançável) e Enter/Espaço (aciona) — caso explícito em
  `users-list.integration.test.tsx`, molde de `password-field.test.tsx:106-123` (AC-016-004):
  foco direto no botão da linha (`.focus()`, evitando wrap-around do Tab em jsdom) +
  `user.keyboard('{Enter}')` abre a confirmação; reabrir e fechar; foco de novo no botão +
  `user.keyboard(' ')` abre a confirmação de novo — a mesma ação do clique, não mais "semântica
  nativa de `<button>`" implícita como prova. Contraste AA nos 2 temas é faceta de **gate 9**
  (ver Roteiro abaixo) — não testável em unidade.
- [ ] AC-050-013 (parte tela — 404 exibido, Situação inalterada, lista atualizada): incluído em
  `users-list.enable.integration.test.tsx`, molde D7c (linhas 355-371 de
  `users-list.disable.integration.test.tsx`).
- [ ] AC-050-014 (Desativar sob o controle novo — AC-048-014/016/017/018, não-regressão de
  comportamento herdado, só o seletor muda de texto para ícone/aria-label) — verificação:
  `(cd mnemonicos-frontend && npm test -- src/components/users-list.disable.integration.test.tsx)`
  → `Tests: N passed` (N = total do arquivo, inalterado em contagem salvo D5), com os valores
  observáveis de D6/D7a/D7b/D7c/D8/D9 idênticos ao commit-pai (último ADMIN recusado, corrida
  409, 404, autodesativação leva ao login) — baseline capturada do estado atual do arquivo
  (seção acima) entra como evidência de não-regressão. Mutante: trocar o `aria-label` esperado
  de volta para o texto "Desativar" literal (sem `aria-label`) faz `button('Desativar Zeca')`
  deixar de casar — prova que o seletor migrado é exercitado de verdade, não herdado por
  coincidência.
- [ ] Região viva compartilhada limpa o aviso ao começar cada operação (lição ativa
  `regiao-viva-compartilhada-limpa-o-aviso-ao-comecar-cada-operacao`, paths:
  `mnemonicos-frontend/src/components/**/*.tsx`): `openDialog` (`users-list.tsx:80`, sem diff)
  já chama `onNotice('')` antes de abrir qualquer diálogo — critério herdado, verificado por 2
  reativações seguidas em `users-list.enable.integration.test.tsx` (molde do caso Q9 de
  `users-list.disable.integration.test.tsx`, linhas 216-237): a 2ª reativação (idempotente)
  ainda limpa e reanuncia "Conta ativada.", mesmo repetindo o texto da 1ª.
- [ ] Controle que dispara a troca de conteúdo fica montado durante o carregamento (lição ativa
  `controle-que-dispara-a-troca-de-conteudo-fica-montado-durante-o-carregamento`, paths:
  `mnemonicos-frontend/src/components/**/*.tsx`): o botão de ação nunca desmonta entre os 2
  status (é o próprio invariante de DEC-051-013) — verificado pelo mesmo teste do critério de
  AC-050-001 acima: o mesmo nó (`document.activeElement` estável) sobrevive à troca de
  `aria-label`/ícone.
- [ ] Campo calculado de outro recurso invalida a tag do endpoint que o exibe (lição ativa
  `campo-calculado-de-outro-recurso-invalida-a-tag-do-endpoint-que-o-exibe`, paths:
  `mnemonicos-frontend/src/store/api.ts`, `mnemonicos-frontend/src/components/**`):
  `adminEnableUser` carrega `invalidatesTags:['User']` (mesma tag de `providesTags` em
  `adminListUsers`) — coberto pelo teste de `api.test.ts` (mutation definida com a tag) e pela
  2ª chamada a `GET /users` observada em `users-list.enable.integration.test.tsx` depois do
  sucesso.
- [ ] Fake de rede espelha as recusas do schema da rota (lição ativa
  `fake-de-rede-espelha-o-schema-da-rota-e-selecao-sobre-colecao-tem-fixture-com-2`, paths:
  `mnemonicos-frontend/src/components/**/*.test.tsx`): o handler novo de
  `users-list.enable.integration.test.tsx` devolve 422 para id fora do formato UUID (mesma
  guarda de `UUID.test(id)` de `users-list.disable.integration.test.tsx:68`) em vez de aceitar
  qualquer corpo; a fixture tem ≥2 contas (ativa e desativada, ids distintos) para que o alvo
  reativado se distinga do não-alvo.
- [ ] Sem warnings/lints novos sobre todo o diff (`git diff --name-only main...HEAD`, produção
  e teste): `(cd mnemonicos-frontend && npm run lint && npm run typecheck)` → sem erro nem
  warning novo nos arquivos tocados por esta TASK.

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente**: `http://localhost:3000/internal/users` (ou a próxima porta livre, com o ajuste
correspondente em `CORS_ORIGINS`/`BACKEND_API_URL`, conforme o CLAUDE.md do workspace), realm
"Tela de Usuários".
**Sujeito**: conta ADMIN descartável fornecida pelo Diretor (nunca `admin2` real de dev —
TRISK-051-007); conta EDITOR descartável para o passo de recusa no servidor; ao menos 1 conta
descartável desativada e 1 ativa na lista.
**Pré-condição (montar)**: logar como o ADMIN descartável; confirmar que a lista tem 1 conta
ativa e 1 desativada (criar/desativar pela própria tela se faltar). **Restaurar**: ao fim,
desfazer qualquer ativação/desativação de teste para deixar as contas descartáveis no estado
anterior.

1. (AC-050-010, tema claro) Focar por Tab o controle "Ativar {nome}" de uma linha desativada —
   conferir contraste AA do ícone e do indicador de foco visível (ferramenta de contraste do
   navegador/axe), e que o `role="tooltip"` aparece ao focar com o mesmo texto do `aria-label`.
2. (AC-050-010, tema escuro) Repetir o passo 1 na mesma linha, alternando o tema pela tela —
   conferir contraste AA de novo.
3. (AC-050-009) Passar o ponteiro (hover, sem foco) sobre o controle "Desativar {nome}" de uma
   linha ativa — o tooltip aparece com o mesmo texto do `aria-label`.
4. (AC-050-001/TRISK-051-002) Confirmar "Ativar" na linha do passo 1 — conferir que o botão
   nunca sai da posição da linha durante o carregamento (sem flash de layout nem o controle
   desaparecendo) e que, ao concluir, o foco está no mesmo nó, agora rotulado "Desativar
   {nome}".
5. (TRISK-051-002, transição inversa) Repetir o fluxo — "Desativar" → "Ativar" → "Desativar" —
   na mesma linha, cobrindo as duas direções da troca de Situação sob o mesmo nó.
6. (AC-050-004/NFR-050-002) Como EDITOR (outra sessão/aba), chamar `PATCH /users/:id/enable`
   diretamente (ferramenta HTTP ou console) — confirmar 403 e que a tela do ADMIN (outra aba,
   sem recarregar) não reflete nenhuma mudança na conta-alvo.

## Riscos específicos

- TRISK-051-002 (foco estável depende da forma do botão nunca variar entre status) — mitigado
  pelo teste de transição Ativar↔Desativar e pelo passo 5 do roteiro acima; revisitar ao
  integrar KAN-218.
- TRISK-051-003 (tooltip CSS-only não aparece em touch sem teclado) — aceito, sem requisito de
  touch na SPEC.
- TRISK-051-008 (histórico de re-gate de acessibilidade no slug) — mitigado pelos passos 1-2 do
  roteiro acima, só com tokens já provados (`surface-card`/`FOCUS_CLASS`/`currentColor`).
- TRISK-051-009 (gate 9 sem ambiente disponível) — vira `pendente_handoff`, roteiro documentado
  acima para a retomada.
- Dependência de AMBIENTE (não de arquivo/código) do Roteiro do gate 9: os passos 4 e 6 exigem
  a rota `PATCH /users/:id/enable` (TASK-051-001) já implementada e no ar — mesma wave, sem
  dependência de arquivo/código (os campos `Depende de`/`Bloqueia` desta TASK e da
  TASK-051-001 continuam `nenhuma`), mas o gate 9 desta TASK só pode ser executado depois que
  TASK-051-001 estiver mergeada/implantada no ambiente de prova.

---

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-226

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
