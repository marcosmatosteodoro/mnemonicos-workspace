# TASK-025-014: Recusa de exportação da Variante "tira" com 0 Quadros

**Slug**: producao-material
**Pertence a**: PLAN-025
**Realiza (FRs)**: FR-024-017
**Componente**: COMP-025-005, COMP-025-008 (EMENDA)
**Wave**: 8
**Tamanho estimado**: small
**Tipo**: fix
**Status**: Done

## Dependências

- **Depende de**: TASK-025-005 (`publication.service.ts`), TASK-025-011 (`PublicationExportControl`)
- **Bloqueia**: nenhuma

## Contexto

**Nota de proveniência**: Wave retroativa — este achado surgiu na aceitação do `po`
(Etapa 5/Entrega), depois da Wave 7 já fechada; não estava na decomposição original de
`/keelson:tasks`.

Esta TASK nasce da aceitação do `po` de PLAN-025 contra BRIEF-024 (Etapa 5/Entrega),
ressalva **R-1**: `POST /contents/:id/publication` com `variant: 'TIRA'` sobre uma Tira
mnemônica com 0 Quadros devolvia 200 com um PDF sem conteúdo real (`buildStripPdf([])`
não lança, `pdf-lib` materializa 1 página em branco ao salvar) — e a UI anunciava
sucesso. A Wave 7 (TASK-025-013) já tinha corrigido o GATING de UI para isso na tela da
Tira mnemônica (`mnemonic-strip-board.tsx`, `frames.length > 0`), mas a tela do Conteúdo
bruto (`content-form.tsx`, TASK-025-012) oferece o controle incondicionalmente em modo
`edit`, e o BACKEND não recusava por conta própria em nenhum dos dois casos — é o
backend, não a UI, quem garante a invariante "nunca um PDF de Tira sem conteúdo real".

O `code-reviewer`, ao revisar o fix aplicado diretamente (commit `102c5528`, antes desta
TASK existir), reprovou por 3 eixos: (1) escopo — comportamento novo sem artefato-pai
commitado; (2) decisões — texto literal de FR-024-002/AC-024-020 contradizia a nova
recusa; (3) qualitativo — o único consumidor real (`PublicationExportControl`) traduzia
QUALQUER erro, inclusive este permanente, em "tente novamente". Esta TASK é a
retroatividade que fecha os 3: SPEC-024 emendada (FR-024-017/AC-024-021, commit
`b526443`), esta TASK documenta o trabalho como TASK sob PLAN-025 (fechando
`ac-sem-task`/`fr-sem-task` do `graph.sh --check`), e o retry do frontend discrimina a
mensagem.

## Escopo

### Inclui

- `mnemonicos-backend/src/http/errors.ts`: nova classe `NothingToExportError extends
  AppError` (409, `NOTHING_TO_EXPORT`).
- `mnemonicos-backend/src/modules/publication/publication.service.ts`: guarda em
  `composePublicationBuffer`, só para a Variante `TIRA`, logo após
  `resolveOrderedFramesForStrip` e antes de `buildStripPdf` — lista de Quadros vazia
  lança `NothingToExportError`. Variante `RESUMO` intocada (nunca fica vazia:
  `concept`/`action`/`object`/`essence` são `NOT NULL` + `.trim().min(1)` no Zod).
- `mnemonicos-backend/tests/integration/publication.service.integration.test.ts`: 2
  casos novos (Tira aberta e esvaziada via `mnemonicFrame.deleteMany`; Variante RESUMO
  no mesmo cenário continua funcionando).
- `mnemonicos-frontend/src/components/publication-export-control.tsx`: discrimina
  `error.data.error.code === 'NOTHING_TO_EXPORT'` no `catch` de `handleExport` — mostra
  mensagem orientada (não "tente novamente") para essa condição permanente; qualquer
  outro erro mantém a mensagem genérica já existente.
- `mnemonicos-frontend/src/components/publication-export-control.test.tsx`: casos novos
  provando a discriminação (código específico → mensagem sem "tente novamente"; outro
  erro → mensagem genérica preservada, regressão de TASK-025-011).

### Não inclui

- `content-form.tsx`/`mnemonic-strip-board.tsx` (gating de UI já existe onde existe,
  TASK-025-012/013) — esta TASK é só o backend + a mensagem do componente compartilhado.
- Qualquer mudança na Variante RESUMO.

## Critérios de pronto

- [x] **Testes cobrem AC-024-021**: `POST /contents/:id/publication` (`variant: 'TIRA'`)
      sobre uma Tira com 0 Quadros → 409 `NOTHING_TO_EXPORT`, nunca 200 com PDF sem
      conteúdo real — verificação executável: `npm run test:integration --
      tests/integration/publication.service.integration.test.ts` (cwd mnemonicos-backend)
      → PASS. Mutante "remover a guarda" faz o teste morrer (confirmado pelo
      code-reviewer via worktree isolada).
- [x] Variante RESUMO no MESMO cenário (Tira com 0 Quadros) continua funcionando
      normalmente — mesmo comando acima → PASS.
- [x] `PublicationExportControl` mostra mensagem ORIENTADA (não "tente novamente") para
      `NOTHING_TO_EXPORT`, e a mensagem genérica para qualquer outro erro — verificação
      executável: `npx jest --runTestsByPath src/components/publication-export-control.test.tsx`
      (cwd mnemonicos-frontend) → PASS.
- [x] Regressão: suítes completas dos 2 repos continuam verdes.
- [x] Sem warnings/lints novos nos arquivos do diff.

## Riscos específicos

- Nenhum novo além dos já catalogados em RISK-025-004 (feedback de exportação em voo
  perdido no desmonte) — esta TASK não toca esse caminho.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-15T02:30:00-0300
**Data conclusão**: 2026-09-15T03:20:00-0300
**Commit SHA**: 102c5528 (backend — guarda + NothingToExportError) · cf386bd0 (frontend — discrimina mensagem) · 5c406ab (retry textual — remove narrativa de rodada)
**Jira**: n/a (retrofit pós-Wave 7, sem sub-task própria — referenciado em KAN-106/KAN-107 no fecho da Entrega)

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (backend 750/750; frontend 446/446)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (rodada 2 — 1ª REPROVADA por 3 eixos: escopo/decisões/qualitativo, todos fechados via emenda de SPEC-024/PLAN-025 + discriminação de mensagem no frontend; 1 retry textual não-bloqueante depois)
- [x] ACs verificados (AC-024-020 ressalva N≥1, AC-024-021 nova)
- [x] Segurança (gate 8): n/a — validação de negócio, sem superfície sensível nova (auth/injeção/upload inalterados)
- [x] Comportamento (gate 9): **verificado** — V3 de `HANDOFF-PLAN-025.md` exercitado com ambiente real: falha sem Quebra da regra devolve 404 estruturado (`NOT_FOUND`) nas 2 Variantes, nunca 500 cru, `role="alert"` correto, sem regressão entre os 2 alertas
<!-- Branch, tentativas, arquivos, revisores e narrativa (retries, escalações) vivem no
ledger da sessão e no commit da closure (4.76) — não se repetem aqui (4.409). -->
