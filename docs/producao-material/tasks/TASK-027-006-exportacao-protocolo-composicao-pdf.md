# TASK-027-006: Exportação — Protocolo impresso e composição suplementar no PDF

**Slug**: producao-material
**Pertence a**: PLAN-027
**Realiza (FRs)**: FR-026-020, FR-026-021, FR-026-022, FR-026-023, FR-026-026, FR-026-027, FR-026-028
**Funcionalidade**: FEAT-026-001 (primária), FEAT-026-002, FEAT-026-003, FEAT-026-004
**Componente**: COMP-027-018 (principal), COMP-027-016, COMP-027-017
**Wave**: 5
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-027-003, TASK-027-004, TASK-027-005
- **Bloqueia**: nenhuma

## Contexto

Composição suplementar do documento gerado pela Exportação (F6) — Contraste(s) + Pegadinha
elaborada + Flashcard(s) + Protocolo impresso de revisão (6 Marcos fixos), sempre nas 2
Variantes (A-026-007) — fundida ao PDF principal via `PDFDocument.copyPages` (DEC-027-006),
reusando o motor existente de `pdf-composer.ts`/`publication.service.ts` (F6). Depende das
3 TASKs de capacidade (003/004/005) por ler os registros que elas persistem. Território:
memo de exploração (`exploration-producao-material.md`, seção "Reconhecimento técnico
(code-scout)", item 6) e PLAN-027 §4, Fluxo 5.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/publication/review-protocol.ts` (novo):
  `getReviewProtocolMarks(): ReviewProtocolMark[]` — função pura, sem I/O, sem parâmetro
  de tempo, devolve os 6 Marcos fixos na ordem canônica `R0`, `R24`, `R3`, `R7`, `R14`,
  `R30`, cada um com `label` textual completo com espaço para preenchimento manual de data
  (forma literal de AC-026-013, ex.: "☐ Revisão R0 — data: ___"); `interface
  ReviewProtocolMark { code: 'R0' | 'R24' | 'R3' | 'R7' | 'R14' | 'R30'; label: string }` —
  interface pública exata de COMP-027-016.
- `mnemonicos-backend/src/modules/publication/pdf-composer.ts` (extensão):
  `buildSupplementaryPagesPdf(sections: SupplementarySections, meta:
  PublicationPdfMeta): Promise<Buffer>` — `interface SupplementarySections { contrasts:
  ContrastForPdf[]; pegadinhaText: string | null; flashcards: FlashcardForPdf[]; protocol:
  ReviewProtocolMark[] }` (interface pública exata de COMP-027-017); desenha, num
  `PDFDocument` PRÓPRIO (não o principal), 1 seção por Contraste (Confundível +
  distinção), a Pegadinha (só quando `pegadinhaText !== null`), 1 seção por Flashcard
  (pergunta/resposta) e o Protocolo (sempre, mesmo com as demais seções vazias) — reusa
  `createPage`/`drawDraftHeader`/`measureWidthFor`/`wrapTextToLines` já existentes no
  arquivo (mesmo cabeçalho de rascunho + Variante das demais páginas — `meta.variant`/
  `meta.generatedAt` idênticos aos da composição principal). Seção com 0 itens (sem
  Contraste, sem Pegadinha ou sem Flashcard) é OMITIDA — nenhuma página vazia, nenhum erro
  (FR-026-028/023).
- `mnemonicos-backend/src/modules/publication/publication.service.ts` (extensão):
  `composePublicationBuffer` passa a ler, via `Promise.all` (NFR-026-003 — sem I/O de rede
  adicional, só 2 `findMany` locais a mais em paralelo com o que já é lido), os
  Contrastes e `ProductionFlashcard`s do `rawContentId` (sem `scopeWhere` — mesma guarda
  comum de `assertRawContentExportable`, já resolvida no passo 1 de `exportPublication`,
  DEC-025-007, não redecidida aqui) e reusa `pegadinhaText` já presente no `RawContent`
  lido; monta o `SupplementarySections` e chama `getReviewProtocolMarks()`/
  `buildSupplementaryPagesPdf` (COMP-027-016/017); funde o `PDFDocument` suplementar ao
  principal via `PDFDocument.copyPages` (carregar de volta os 2 `Buffer`s com
  `PDFDocument.load`, copiar as páginas do suplementar para o documento principal e
  `.save()` de novo) antes do retorno final da função — para AMBAS as Variantes (`RESUMO`
  e `TIRA`, A-026-007). `PublicationClient` (tipo já existente neste arquivo) ganha
  `Pick<'contrast' | 'productionFlashcard'>` no seu conjunto de modelos.

### Não inclui

- Qualquer alteração ao CRUD de Contraste/Pegadinha/Flashcard — já entregue por
  TASK-027-003/004/005, das quais esta TASK só lê.
- Mudança de layout interno de `buildStripPdf`/`buildSummaryPdf` além da chamada de fusão
  — nenhuma linha de desenho de página das 2 Variantes existentes muda.
- Teto de duração NOVO ou alteração de `PUBLICATION_PDF_TIMEOUT_MS` (`config/env.ts`, já
  existente de F6) — NFR-026-003 é medido contra o teto JÁ existente, nunca um teto novo.

## Critérios de pronto

- [ ] **AC-026-012** (FR-026-020, gate 1) — Dado um Conteúdo bruto com 2 Flashcards
      registrados e Quebra da regra salva, quando o EDITOR aciona a Exportação em
      qualquer Variante, então o documento exportado contém os 2 Flashcards, na ordem de
      criação. Verificação executável: `npm --prefix mnemonicos-backend run
      test:integration -- --testPathPatterns=publication.service.integration.test.ts`
      (arquivo existente, F6, estendido) → `OK (N tests)`, incluindo o caso que cria 2
      `ProductionFlashcard`s em sequência, exporta nas 2 Variantes e confere — via
      `PDFDocument.load(buffer).getPages()`/extração de texto, mesmo padrão de
      `pdf-composer.test.ts` — que a pergunta/resposta do 1º Flashcard aparece ANTES da do
      2º. Fixada antes do código. Falsificável: `findMany` sem `orderBy: { createdAt:
      'asc' }` faz o mutante reprovar.
- [ ] **AC-026-013** (FR-026-021, gate 1) — Dado um Conteúdo bruto com Quebra da regra
      salva, quando o EDITOR aciona a Exportação, então o documento exportado contém o
      Protocolo impresso com os 6 Marcos `R0, R24, R3, R7, R14, R30` na ordem fixa, cada
      um como rótulo textual com espaço para data manual, em AMBAS as Variantes. Mesmo
      comando — caso próprio confere, nas 2 Variantes, que os 6 `label`s de
      `getReviewProtocolMarks()` aparecem no PDF final NA MESMA ORDEM. Falsificável:
      reordenar 2 Marcos em `getReviewProtocolMarks()` faz este caso reprovar (asserção de
      ordem, não só de conjunto).
- [ ] **AC-026-014** (FR-026-022, gate 1) — Dado o Protocolo impresso gerado num documento
      exportado, quando comparado ao scheduler SM-2 existente, então o sistema não
      apresenta nenhuma data calculada nem estado de conclusão — apenas os 6 rótulos
      textuais fixos. Verificação executável: `npm --prefix mnemonicos-backend test --
      review-protocol` (novo arquivo `tests/unit/review-protocol.test.ts`) → `OK (N
      tests)`. Caso próprio chama `getReviewProtocolMarks()` sem nenhum parâmetro de tempo
      (assinatura `(): ReviewProtocolMark[]`, sem `now`/`Date`) e confere que nenhum
      `label` contém dígito de data calculada (regex sobre o texto literal de cada
      `label`) — o rótulo de exemplo do PLAN ("☐ Revisão R0 — data: ___") não tem dígitos,
      e o teste confirma que o `label` real também não tem. Fixada antes do código.
- [ ] **AC-026-017** (FR-026-023, gate 1) — Dado um Conteúdo bruto com Quebra da regra
      salva e nenhum Flashcard registrado, quando o EDITOR aciona a Exportação em
      qualquer Variante, então o documento é gerado sem seção de Flashcards e sem erro,
      contendo o Protocolo impresso normalmente. Mesmo comando de AC-026-012 — caso
      próprio exporta um Conteúdo bruto com Quebra salva e 0 Flashcards/Contrastes/
      Pegadinha, confirma resolução com sucesso (sem exceção, `Buffer` não-vazio), que
      nenhum texto de Flashcard aparece nas páginas, e que os 6 Marcos do Protocolo
      aparecem. Falsificável: `buildSupplementaryPagesPdf` gerando página vazia para a
      seção de Flashcards ausente faz a contagem de páginas do suplementar divergir do
      esperado (Protocolo sempre soma 1 página; as demais, 0).
- [ ] **AC-026-020** (FR-026-026, gate 1) — Dado um Conteúdo bruto com 2 Contrastes
      registrados e Quebra da regra salva, quando o EDITOR aciona a Exportação em
      qualquer Variante, então o documento exportado contém os 2 Contrastes (Confundível +
      distinção). Mesmo comando — caso próprio cria 2 `Contrast`s, exporta e confere que o
      Confundível e a distinção de AMBOS aparecem no texto das páginas do suplementar.
- [ ] **AC-026-021** (FR-026-027, gate 1) — Dado um Conteúdo bruto com Pegadinha elaborada
      registrada e Quebra da regra salva, quando o EDITOR aciona a Exportação em qualquer
      Variante, então o documento exportado contém o texto da Pegadinha elaborada. Mesmo
      comando — caso próprio salva `pegadinhaText` (via `savePegadinhaText`, já entregue
      por TASK-027-005), exporta e confere que o texto aparece no suplementar.
- [ ] **AC-026-022** (FR-026-028, gate 1) — Dado um Conteúdo bruto com Quebra da regra
      salva e sem Contraste registrado (ou sem Pegadinha elaborada), quando o EDITOR
      aciona a Exportação em qualquer Variante, então o documento é gerado sem a seção
      correspondente e sem erro. Mesmo comando — 2 sub-casos (sem Contraste; sem
      Pegadinha), cada um com asserção PRÓPRIA de ausência do texto da seção omitida
      (nunca uma única asserção agregada para os 2 sub-casos) e de resolução com sucesso.
- [ ] NFR-026-003 (sem AC próprio, gate 10 — TRISK-027-005) — o sistema deve manter a
      geração do Protocolo e a inclusão de Flashcards dentro do teto de duração JÁ
      existente da Exportação (`PUBLICATION_PDF_TIMEOUT_MS`, F6), sem I/O de rede
      adicional. Prova de gate 10 (medição, fora do gate 1): medir a duração de
      `composePublicationBuffer` ANTES desta TASK (baseline, Conteúdo bruto com Tira
      grande real) e DEPOIS (mesma carga + N Contrastes/Flashcards reais, com carga
      SÍNCRONA real — nunca `setTimeout`/temporizador mockado, lição ativa abaixo); se a
      duração aumentar, rodar o controle negativo (medir sem a fusão de páginas) antes de
      arquivar o achado como dívida pré-existente. Registrado em **Riscos específicos**
      da closure — não bloqueia o merge por si só (SHOULD).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npm --prefix mnemonicos-backend run lint` → exit 0.

## Riscos específicos

- TRISK-027-005: merge de 2 `PDFDocument`s (principal + suplementar) via `copyPages`
  introduz custo de composição adicional — pode tensionar NFR-026-003 em Tiras grandes;
  medir com teste de performance na implementação (mesma régua de DEC-025-002).
- Lição ativa [Performance] "Teto de duração via `Promise.race`+`setTimeout` não corta
  trabalho CPU-bound síncrono — e teste que prova o teto com dublê de `setTimeout` não
  falsifica nada" — `buildSupplementaryPagesPdf` soma trabalho síncrono (novo
  `PDFDocument` + `copyPages`) sob o teto existente; a prova de NFR-026-003/TRISK-027-005
  exige carga real, nunca dublê de timer.
- Lição ativa [Código] "Lista de Interface pública do PLAN é contrato mínimo, não gabarito
  de transcrição" — `buildSupplementaryPagesPdf` é função nova em arquivo existente:
  comparar contra `buildStripPdf`/`buildSummaryPdf` antes de escrever.
- Lição ativa [Testes] "Sintoma novo só vira dívida conhecida depois de reproduzido sem o
  diff" — se a medição de NFR-026-003 revelar aumento de duração, distinguir "introduzido
  por este diff" com controle negativo (medir sem a fusão) antes de arquivar como dívida
  pré-existente.

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
