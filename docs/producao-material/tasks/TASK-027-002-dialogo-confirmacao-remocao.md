# TASK-027-002: Diálogo de confirmação de remoção com foco gerenciado (compartilhado)

**Slug**: producao-material
**Pertence a**: PLAN-027
**Realiza (FRs)**: FR-026-024, FR-026-025
**Funcionalidade**: FEAT-026-005 (primária)
**Componente**: COMP-027-015 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-027-003, TASK-027-004, TASK-027-005

## Contexto

Mecanismo de confirmação com foco gerenciado compartilhado por Contraste/Pegadinha/
Flashcard (DEC-027-008) — só o diálogo é extraído como componente comum; cada consumidor
(TASK-027-003/004/005) integra a própria mutation de remoção por cima dele. Molde:
`mnemonic-strip-board.tsx` (diálogo de remoção de Quadro, F4) e `content-form.tsx`
(diálogo de remoção de Conteúdo bruto) — ver memo de exploração
(`exploration-producao-material.md`, seção "Reconhecimento técnico (code-scout)", item 4).

## Escopo

### Inclui

- `mnemonicos-frontend/src/components/confirm-remove-dialog.tsx` (novo):
  `ConfirmRemoveDialog({ open, itemLabel, onConfirm, onClose }: ConfirmRemoveDialogProps)`
  — `role="alertdialog"` com `aria-label`/`aria-describedby` (mesma forma de
  `mnemonic-strip-board.tsx:637-644`/`content-form.tsx:484-491`, mensagem incluindo
  `itemLabel`), 3 estados internos do próprio ato de remover (`isRemoving`/
  `removeSucceeded`/`removeError`, molde `isSubmitting`/`submitSuccess`/`submitError` de
  `content-form.tsx`) — clicar "Confirmar" chama `onConfirm()` (assíncrono, injetado pelo
  consumidor), com `disabled`/`aria-busy` no botão de confirmação enquanto `isRemoving`;
  sucesso chama `onClose()`; falha mantém o diálogo aberto, reabilita o botão de
  confirmação e exibe mensagem de erro (`role="alert"`) — o item nunca é dado como
  removido antes de `onConfirm()` resolver com sucesso (quem tira o item da lista real é o
  consumidor, via tag RTK Query invalidada, fora desta TASK).
  - Foco programático (molde `mnemonic-strip-board.tsx:151-181`/
    `content-form.tsx:130-145`): `useEffect` reagindo a `open` — botão "Confirmar"
    focado ao abrir (`open: true`); ao fechar (`open: false`), foco devolvido ao elemento
    que estava focado antes da abertura (o gatilho, capturado pelo consumidor antes de
    setar `open: true`, mesmo mecanismo de `wasConfirmingDeleteRef`/
    `previousConfirmingFrameIdRef` dos moldes).
- `mnemonicos-frontend/src/components/confirm-remove-dialog.test.tsx` (novo): componente
  MONTADO isoladamente (`@testing-library/react`), `onConfirm` mockado (`jest.fn()`)
  resolvendo e rejeitando em casos distintos — asserção dos 3 estados internos
  (`role="status"` durante `isRemoving`, `onClose` chamado só no sucesso, `role="alert"` +
  botão reabilitado na falha) e da gestão de foco (botão "Confirmar" focado ao montar com
  `open: true`; ao transicionar para `open: false`, foco devolvido ao elemento
  previamente focado — `document.activeElement` conferido antes/depois).

### Não inclui

- Wiring com `useRemoveContrastMutation`/`useRemovePegadinhaMutation`/
  `useRemoveFlashcardMutation` — cada consumidor (TASK-027-003/004/005) integra a própria
  mutation por cima do diálogo.
- Comportamento de gatilho concorrente (abrir a confirmação de um item enquanto a de OUTRO
  item já está aberta) — cada consumidor confere os próprios setters do estado que decide
  qual item confirma (lição ativa abaixo).
- Remoção do item da lista exibida — efeito de `invalidatesTags` da mutation de cada
  consumidor, fora desta TASK.

## Critérios de pronto

- [ ] **AC-026-018** (parte — mecanismo compartilhado: pede confirmação, indica andamento,
      fecha com sucesso; FR-026-024, gate 1) — `ConfirmRemoveDialog` montado com `open:
      true`, `onConfirm` mockado resolvendo: durante a chamada, o botão "Confirmar" fica
      `disabled`/`aria-busy="true"` e um elemento `role="status"` indica operação em
      andamento; ao resolver, `onClose` é chamado exatamente 1 vez. Verificação
      executável: `npm --prefix mnemonicos-frontend test -- confirm-remove-dialog` → `OK
      (N tests)`. Fixada antes do código.
- [ ] **AC-026-019** (parte — mecanismo compartilhado: falha reabilita, mantém aberto,
      mensagem; FR-026-025, gate 1) — mesmo componente, `onConfirm` mockado rejeitando: o
      diálogo permanece montado (`onClose` NUNCA chamado), o botão "Confirmar" volta a
      `disabled={false}`, e um elemento `role="alert"` exibe mensagem de falha. Mesmo
      comando.
- [ ] Foco gerenciado — item do Inclui sem AC isolado (herdado do molde
      `mnemonic-strip-board.tsx`/`content-form.tsx`, DEC-027-008): ao montar com `open:
      true`, o botão "Confirmar" recebe foco (`document.activeElement` aponta para ele);
      ao transicionar `open: true → false`, o foco é devolvido ao elemento previamente
      focado antes da abertura. Mesmo comando. Falsificável: remover o `useEffect` de
      foco faz `document.activeElement` permanecer no `<body>` nos 2 momentos.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npm --prefix mnemonicos-frontend run lint` → exit 0.

## Riscos específicos

- Lição ativa [Design] "Diálogo in-place em ramo condicional exige grep de todos os
  setters do estado que decide o ramo, não só de quem o fecha" — a régua vale para CADA
  consumidor (TASK-027-003/004/005) ao cabear o próprio estado de "item em confirmação";
  esta TASK não tem esse estado (`open` chega como prop controlada pelo consumidor).
- Lição ativa [Design] "Predicado que impede 2º diálogo/confirmação simultâneo mira só o
  gatilho que o abriria — nunca o contêiner que hospeda feedback de ação assíncrona
  não-relacionada" — mesma régua, repassada aos consumidores na integração.

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
