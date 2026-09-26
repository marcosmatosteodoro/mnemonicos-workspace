# TASK-027-007: Integração à tela — Contraste, Flashcard e Pegadinha alcançáveis no Conteúdo bruto

**Slug**: producao-material
**Pertence a**: PLAN-027
**Realiza (FRs)**: FR-026-005, FR-026-011, FR-026-017, FR-026-004 (parte — mensagem de erro)
**Funcionalidade**: FEAT-026-001, FEAT-026-002, FEAT-026-003
**Componente**: novo — client wrapper de composição (sem número de COMP no PLAN original; furo no plano)
**Wave**: 6
**Tamanho estimado**: small
**Tipo**: feature (correção de furo no plano)
**Status**: Done

## Origem

Achada pela **convergência de fecho** (`code-reviewer`, modo convergência) na Entrega de
PLAN-027 (`/keelson:integrate`), 2026-09-26 — não por nenhum gate de wave. As TASKs
001-006 entregaram Contraste/Flashcard/Pegadinha como CRUD completo (schema→service→routes→
componente), com cada componente testado MONTADO ISOLADAMENTE (`makeStore()`+fetch
mockado ou HTTP real) — prova válida do componente em si, mas nenhuma TASK tocou a
página que o hospeda. `ContrastList`/`FlashcardList`/`PegadinhaField` existem e passam
em todos os testes, mas **nenhuma tela do produto os monta** — o EDITOR só alcança os 3
conceitos via chamada direta à API, nunca pela interface. PLAN-027 §10 ("Não coberto por
este PLAN") declarava cobertura total de SPEC-026 — este é um furo real de implementação,
não um item conscientemente adiado.

**Decisão do Diretor** (Entrega de PLAN-027, `/keelson:integrate`): corrigir agora, antes
de abrir o PR — não estacionar como risco aceito.

## Contexto

PLAN-027 §4 (Fluxos 1, 3, 4) já dizia, desde a origem: "EDITOR abre `(interno)/content/[id]`"
para os 3 fluxos — a página-alvo estava decidida, só nunca foi tocada por nenhuma TASK.
`content/[id]/page.tsx` é Server Component, monta só `ContentForm` (client component,
`mode="edit"`, busca `RawContent` via `useGetRawContentQuery`). O gap 2 (mensagem de erro
genérica em `ContrastForm`) é FR-026-004/AC-026-003 ("recusar a operação, **informar o
motivo**") — o backend já distingue (`assertRawContentReachable` recusa com 404 "Conteúdo
bruto não encontrado."), mas o `catch` do formulário reduz toda falha a uma mensagem
genérica de "tente novamente" — convidando a repetir uma operação que sempre vai falhar
quando o titular está inalcançável/removido.

## Escopo

### Inclui

- `mnemonicos-frontend/src/app/(interno)/content/[id]/page.tsx` (estende): monta
  `ContrastList`, `FlashcardList` e `PegadinhaField` na mesma página de `ContentForm`
  (Fluxos 1/3/4 do PLAN §4) — precisa de um client wrapper (novo componente, ex.
  `content-supplementary-panel.tsx` ou equivalente) porque `PegadinhaField` depende do
  `pegadinhaText` vindo de `useGetRawContentQuery` (refetch pós-mutação, JSDoc de
  `pegadinha-field.tsx:34-43`) — a página em si continua Server Component, só o wrapper é
  `'use client'`. Ordem de composição e se fica antes/depois de `ContentForm`: decisão do
  `product-designer` (gate 11), sem contrato prévio a seguir além da consistência visual
  com `mnemonic-strip-board.tsx` (que já enxerta Contraste/Flashcard/Pegadinha por Quadro em
  F4 — conferir se o mesmo padrão vale aqui ou se a composição é diferente por ser o nível
  do Conteúdo bruto, não do Quadro).
- `mnemonicos-frontend/src/components/contrast-form.tsx` (estende): distinguir o 404 do
  titular inalcançável/removido (via `isFetchBaseQueryError` + `status === 404`, precedente
  `rule-breakdown-form.tsx:81`/`mnemonic-strip-board.tsx:224`) e exibir o motivo real, sem
  convidar a tentar de novo (o título continua sendo um erro fatal para aquele Conteúdo,
  não transitório).
- Por consistência (não exigido pelos FRs deles, mas mesmo `catch` genérico): considerar o
  mesmo tratamento em `flashcard-form.tsx`/`pegadinha-field.tsx` — aplicar se barato no
  mesmo diff, declarar se não.

### Não inclui

- Qualquer mudança de CRUD/schema/service já entregue (TASK-027-001 a 006).
- Composição do PDF (TASK-027-006, já correta).
- Layout/design novo além do necessário para hospedar os 3 componentes na página existente.

## Critérios de pronto

- [ ] `ContrastList`, `FlashcardList`, `PegadinhaField` aparecem em `content/[id]/page.tsx`
      (ou página equivalente decidida) — grep confirma o import; teste de composição
      (wiring, mesmo padrão de `layout.tsx` para o SW em F-avulso PWA) que monta a página
      real (não os componentes isolados) e confirma a presença dos 3.
- [ ] `PegadinhaField` recebe `pegadinhaText` do `RawContent` lido pela página (não de um
      valor estático) — refetch pós-mutação funciona de ponta a ponta.
- [ ] `ContrastForm`: falha 404 do titular exibe o motivo real (mensagem distinta da falha
      genérica de sistema) — teste com `onConfirm`/mutação mockada devolvendo 404 vs. erro
      genérico, 2 mensagens diferentes.
- [ ] Gate 11 (product-designer) e gate 9 (qa, com `gates.screenVerify` — agora HÁ tela
      real para verificar em browser) aprovados.
- [ ] Suíte completa (unit + integration) verde, lint/typecheck limpos.

## Riscos específicos

- Este furo ficou pendente por 3 waves (registrado no INDEX desde a Wave 3) sem nunca ter
  virado bloqueio — lição de processo roteada ao `agile-coach` (ver ledger da sessão).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-26
**Data conclusão**: 2026-09-26
**Commit SHA**: 1cc4c5d (implementação) · 3280af7 (retry consolidado gates 1-7+11) · 3b91a8b (correção mecânica de prova, gate 1-7)
**Jira**: KAN-134

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (518/518, mnemonicos-frontend)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (reprovado em 1cc4c5d — A1-A4; retry 3280af7 resolveu a substância mas introduziu regressão de prova mecânica em 4 asserções; corrigido em 3b91a8b, aprovado)
- [x] ACs verificados
- [x] Segurança (gate 8): n/a — diff é composição de tela + tratamento de erro no frontend, sem superfície sensível nova (sem endpoint/auth/dado pessoal tocado)
- [x] Comportamento (gate 9): verificado — qa, 1ª verificação de tela REAL do PLAN-027 (browser, Postgres real, login EDITOR seed dev), FEAT-026-001/002/003 confirmadas ponta a ponta (registrar/persistir/remover via UI, 2 reloads completos)
- [x] Design (gate 11): reprovado em 1cc4c5d (achado alta: painel de Pegadinha falso-vazio em loading/erro do titular; achado médio: posição do bloco final de exportação; achado médio: nomes acessíveis duplicados) — aprovado no retry 3280af7 após correção
