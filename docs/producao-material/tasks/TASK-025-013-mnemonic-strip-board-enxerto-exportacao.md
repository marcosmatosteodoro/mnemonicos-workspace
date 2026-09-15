# TASK-025-013: EMENDA `mnemonic-strip-board.tsx` — enxerto do controle de exportação + confirmação de abertura na 1ª visualização

**Slug**: producao-material
**Pertence a**: PLAN-025
**Realiza (FRs)**: FR-024-012, FR-024-013
**Componente**: COMP-025-013 (principal)
**Wave**: 7
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: TASK-025-011, TASK-025-005
- **Bloqueia**: nenhuma

## Contexto

`MnemonicStripBoard` (`mnemonicos-frontend/src/components/mnemonic-strip-board.tsx`,
COMP-012-011/012, lido integralmente nesta redação) já existe: `useGetMnemonicStripQuery`
primeiro; em 404 (`isNotFound`), o componente dispara `useOpenMnemonicStripMutation`
automaticamente, travado por `openAttemptedRef` (uma vez por montagem). Esta EMENDA soma o
controle de exportação ao cabeçalho e generaliza o gatilho de abertura para também disparar
quando a Tira **já existe** (`hasData === true`) — efeito prático (DEC-025-003): quando a
Tira foi auto-gerada por uma exportação anterior (evento de abertura suprimido,
TASK-025-005), a 1ª visita humana à tela é quem confirma a `ABERTURA`. Cobertura parcial:
FR-024-013 aqui é só o **gatilho frontend** — a decisão de emitir/não emitir o evento já é
provada em `tira.service.ts` (TASK-025-005); esta TASK só garante que a 1ª visita humana
dispara o `POST` que aciona essa decisão. **AC-024-014 é coberto por 2 TASKs em paralelo**
(TASK-025-012 e TASK-025-013, nenhuma depende da outra): esta TASK prova a faceta da tela da
Tira mnemônica; a faceta da tela do Conteúdo bruto é da TASK-025-012.

## Escopo

### Inclui

- `mnemonicos-frontend/src/components/mnemonic-strip-board.tsx` (EMENDA — arquivo
  existente): `<PublicationExportControl rawContentId={rawContentId} />` no cabeçalho do
  board, visível assim que `hasData === true`.
- O `useEffect` que dispara `useOpenMnemonicStripMutation` (hoje só reage a `isNotFound`)
  passa a disparar também quando `hasData === true` **na 1ª leitura bem-sucedida da
  montagem** — mesma trava `openAttemptedRef` (nunca repete a cada re-render/refetch),
  disparando independente de qualquer diálogo `role="alertdialog"` estar aberto (o efeito
  não é condicionado por `confirmingRemoveFrameId`/`confirmingReplaceFrameId`/
  `isAnyDialogOpen` — fire-and-forget, mesma régua de FR-024-013).
- `mnemonicos-frontend/src/components/mnemonic-strip-board.test.tsx` (EMENDA — arquivo
  existente, harness `fetchSpy`/`jsonResponse` já estabelecido): novos casos cobrindo o
  disparo único do `POST` na 1ª leitura com `hasData === true` e a presença do controle de
  exportação (ver Critérios de pronto).

### Não inclui

- A lógica de decisão de abertura em si (já em `tira.service.ts`, TASK-025-005) — este
  enxerto só garante que a 1ª visita humana dispara o `POST` que aciona essa lógica.
- O componente `PublicationExportControl` em si (TASK-025-011).

## Critérios de pronto

- [ ] **Testes cobrem AC-024-014 (parte mnemonic-strip-board — a faceta da tela do Conteúdo
      bruto é da TASK-025-012)** — verificação executável: `npx jest --runTestsByPath
      src/components/mnemonic-strip-board.test.tsx` (cwd `mnemonicos-frontend`) → `PASS`.
      Cenário: `MnemonicStripBoard` montado com a Tira já aberta (`GET /strip` → 200) → o
      controle de exportação (`PublicationExportControl`) está presente no cabeçalho,
      recebendo o mesmo `rawContentId`.
- [ ] No 1º render com `hasData === true`, `POST /contents/:id/strip` é disparado
      **exatamente 1 vez** (`openAttemptedRef` trava reentrância em re-render/refetch) —
      mesmo arquivo/comando acima → `PASS`. Verificação: `fetchSpy` (já usado no arquivo)
      contado por `method === 'POST' && pathname === STRIP_PATH`; montar o componente com
      `GET /strip` → 200 (Tira já aberta), aguardar `waitFor`, disparar um refetch adicional
      da mesma query (ex.: `updateBehavior`/`addBehavior` acionando `invalidatesTags:
      ['MnemonicStrip']`, mesmo mecanismo já exercitado por outros casos do arquivo) →
      contagem de `POST STRIP_PATH` permanece 1 após o refetch.
- [ ] O disparo do `POST` na 1ª visita **não interfere** no diálogo de confirmação de
      remoção já existente (lição ativa "[Design] Diálogo in-place em ramo condicional exige
      grep de TODOS os setters do estado que decide o ramo") — verificação executável: `grep
      -n "setEditingFrameId\|setConfirmingRemoveFrameId\|setConfirmingReplaceFrameId"
      src/components/mnemonic-strip-board.tsx` (cwd `mnemonicos-frontend`) confirma que
      nenhum desses setters é tocado dentro do novo `useEffect` (o efeito só chama
      `openMnemonicStrip` e seta `openAttemptedRef.current`); mais um teste comportamental —
      com a Tira já aberta (`hasData === true`, `POST` de abertura em voo/represado) e a
      confirmação de remoção de um Quadro aberta (`role="alertdialog"`) ao mesmo tempo, o
      diálogo permanece com foco/estado intactos (nenhum 2º `role="alertdialog"` aberto pelo
      efeito de abertura, mesma régua de `isAnyDialogOpen`).
- [ ] `hasData` e `isNotFound` permanecem mutuamente exclusivos sobre o MESMO resultado de
      `useGetMnemonicStripQuery` (lição ativa "RISK-011-008: `mnemonic-strip-board.tsx` pode
      ter a forma 'data em cache + `isNotFound` derivado só de `error`'; conferir que vêm de
      um único estado discriminado") — mesmo arquivo/comando acima → `PASS`. Verificação:
      `GET /strip` → 404 produz `isNotFound === true` e `hasData === false`; `GET /strip` →
      200 produz `hasData === true` e `isNotFound === false` — nunca os dois `true` ao mesmo
      tempo, no mesmo render.
- [ ] Regressão: a suíte `mnemonic-strip-board.test.tsx` já existente continua verde após o
      enxerto — mesmo comando acima → `PASS`, todos os casos pré-existentes (abertura via
      404, CRUD de Quadro, vínculo/desvínculo, diálogos de confirmação) + os novos desta
      TASK.
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git diff --name-only
      main...HEAD`) — verificação executável: `npx eslint
      src/components/mnemonic-strip-board.tsx src/components/mnemonic-strip-board.test.tsx`
      (cwd `mnemonicos-frontend`) → 0 problemas.

## Riscos específicos

- Mesma classe de defeito já registrada na lição ativa do próprio arquivo (diálogo
  `role="alertdialog"` reusado/estado em ramo condicional) — mitigado pelo grep exaustivo
  exigido no Critério de pronto acima, feito ANTES de tocar o `useEffect`.
- O `POST /contents/:id/strip` extra na 1ª visita, quando a Tira já tinha `ABERTURA`
  registrada pelo fluxo humano original, é um no-op sem efeito observável (custo de 1
  requisição idempotente a mais por carregamento de tela) — aceito pelo PLAN (§3,
  COMP-025-013), não é defeito desta TASK.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-14T21:15:00-0300
**Data conclusão**: 2026-09-14T23:10:00-0300
**Commit SHA**: 9a70284 (implementação) · 242899e (retry — gates 1-7/11: posição, PDF vazio anunciado como sucesso, mutualidade hasData/isNotFound, teste falsificável) · a55a2c9 (retry — gate 1-7: narrativa de rodada removida dos testes)
**Jira**: KAN-120

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (Wave 7 — 2 retries: 1 comportamental/design, 1 textual; ambos convergidos)
- [x] ACs verificados
- [x] Segurança (gate 8): n/a — sem superfície sensível (composição client + derivação de estado de query, nenhum auth/injeção nova)
- [x] Comportamento (gate 9): **verificado** — V2 de `HANDOFF-PLAN-025.md` exercitado com ambiente real: gating por Tira vazia/não-vazia confirmado nos 2 sentidos, download real, e exatamente 1 evento `ABERTURA` gravado mesmo com auto-geração fora do fluxo da UI seguida de 2 visitas humanas (FR-024-013/DEC-025-003 provado em produção real). RISK-011-008 deixou de ser hipótese (confirmado por probe real, corrigido nesta TASK). 1 achado não-bloqueante de follow-up: feedback de exportação em voo se perde se o bloco desmontar (3 gatilhos: remoção do último Quadro, refetch 404, erro de leitura) — estado vive local em `PublicationExportControl` (COMP-025-010), fora de escopo desta TASK.
<!-- Branch, tentativas, arquivos, revisores e narrativa (retries, escalações) vivem no
ledger da sessão e no commit da closure (4.76) — não se repetem aqui (4.409). -->
