# TASK-025-008: publication.service.ts — orquestração da exportação (exportPublication)

**Slug**: producao-material
**Pertence a**: PLAN-025
**Realiza (FRs)**: FR-024-002, FR-024-003, FR-024-004, FR-024-006, FR-024-008, FR-024-009, FR-024-010, FR-024-011, FR-024-015
**Componente**: COMP-025-005 (principal)
**Wave**: 3
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: In Progress

## Dependências

- **Depende de**: TASK-025-001, TASK-025-003, TASK-025-005, TASK-025-007
- **Bloqueia**: TASK-025-009

## Contexto

Função central `exportPublication` (COMP-025-005) — orquestra a guarda nova de alcance
(DEC-025-007), a leitura de baixo nível da Quebra, `buildSummaryPdf`/`buildStripPdf`
(TASK-025-007) sob teto de duração (DEC-025-002), e a gravação transacional do evento
genérico + log dedicado por Variante (DEC-025-005), só depois do `Buffer` pronto. Ver
PLAN-025 §3 (COMP-025-005) e §6 (DEC-025-002/DEC-025-005/DEC-025-007).

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/publication/publication.service.ts` (novo arquivo):
  `exportPublication(rawContentId: string, input: ExportPublicationInput, actor:
  ContentActor, db?: PublicationClient): Promise<PublicationResult>` — texto exato da
  Interface pública de COMP-025-005 no PLAN-025 §3, ordem exata dos passos 1-7 abaixo,
  dentro de `$transaction` interativa (mesmo padrão de fail-secure de
  `openMnemonicStrip`/`createRawContent`).
- Passo 1: `assertRawContentExportable(rawContentId, db)` — guarda NOVA (DEC-025-007),
  função própria deste arquivo (nunca acrescentada a `contents.service.ts`): reusa
  `ACTIVE_RAW_CONTENT_WHERE` (símbolo exportado já existente, importado de
  `contents.service.ts`) + `db.rawContent.findFirst({ where: { id: rawContentId,
  ...ACTIVE_RAW_CONTENT_WHERE } })` — SEM `scopeWhere`/checagem de autoria (é a
  diferença deliberada de `assertRawContentReachable`); `null` → `NotFoundError('Conteúdo
  bruto não encontrado.')` — MESMA mensagem de `assertRawContentReachable`, para não
  abrir um oráculo de distinção entre os dois mecanismos.
- Passo 2: `tx.ruleBreakdown.findUnique({ where: { rawContentId }, select: {...} })` —
  leitura de BAIXO NÍVEL, direto no `db`/`tx` — NUNCA `getRuleBreakdown`
  (`contents.service.ts`, exportado); `null` → `NotFoundError('Quebra da regra não
  encontrada.')`, MESMA mensagem de `getRuleBreakdown`, sem herdar a guarda de autoria
  dele (DEC-025-007 explica o motivo: o passo 1 já resolveu o alcance sem autoria).
- Passo 3 (Variante `RESUMO`): `buildSummaryPdf(breakdown, meta)` (`pdf-composer.ts`,
  TASK-025-007) direto sobre a Quebra lida no passo 2.
- Passo 4 (Variante `TIRA`): resolve os Quadros por 2 caminhos reais, distintos por
  necessidade de DEC-025-007 (não é 1 chamada incondicional a `openMnemonicStrip`,
  correção pós-retry do gate 1/code-reviewer da Wave 3) — (a) Tira JÁ aberta: leitura de
  BAIXO NÍVEL própria deste arquivo (`mnemonicStrip.findUnique` a partir do
  `ruleBreakdownId` já confirmado no passo 2), SEM a guarda de autoria de
  `openMnemonicStrip` — satisfaz AC-024-018 (EDITOR B lê "tira" já aberta de EDITOR A);
  (b) Tira AINDA não existe (`null`): delega a `openMnemonicStrip(rawContentId, actor,
  db, { suppressOpeningEvent: true })` (`tira.service.ts`, TASK-025-005) —
  get-or-generate idempotente reusado sem duplicar lógica, aí sim sujeito à guarda de
  autoria ORIGINAL dele (intencional, DEC-025-007: auto-geração por não-autor recusa).
  Para cada `MnemonicFrameDetail` resultante (de qualquer um dos 2 caminhos) com
  `visualAssociationId !== null`: `getVisualAssociationBinary(visualAssociationId, db)`
  (`visual-associations.service.ts`, já existente) + `detectImageSignature(imageData)`
  (`image-signature.ts`, já existente) — formato `'PNG'`/`'JPEG'` →
  `StripFrameForPdf.image = { buffer, format }`; formato `'WEBP'`, `null` (não
  detectado) ou `getVisualAssociationBinary` devolvendo `null` →
  `StripFrameForPdf.image = null` (é AQUI, neste arquivo, que o mapeamento
  `WEBP`/indetectável → `null` acontece — `pdf-composer.ts`, TASK-025-007, só recebe
  `'PNG'|'JPEG'` ou `null`); chama `buildStripPdf(frames, meta, onImageSkipped)`
  (`pdf-composer.ts`) passando um callback `onImageSkipped: (info: ImageSkippedInfo) =>
  void` que faz `logger.warn({ rawContentId, frameIndex: info.frameIndex, format:
  info.format, reason: info.reason }, 'Imagem de Quadro descartada da exportação')`
  (`src/lib/logger.ts`, já existente) — **[furo no plano corrigido em voo, achado do
  security-engineer no gate 8 de TASK-025-007]**: `buildStripPdf` ganhou esse 3º
  parâmetro opcional na Wave 2 (teto de pixels/APNG/decode-failed) especificamente para
  ter um consumidor que logue o motivo — sem isso, uma imagem recusada por segurança
  (bomb de pixels, APNG, PNG malformado) some do PDF em silêncio total, mesmo com o
  mecanismo de observabilidade já existindo. NUNCA logar `buffer`/bytes da imagem nem
  texto do usuário — só metadado (índice, formato, motivo enum).
- Passo 5: `withDeadline(promise, env.PUBLICATION_PDF_TIMEOUT_MS)` (função nova,
  `Promise.race` entre a composição — passos 3/4 — e um temporizador) — o temporizador
  vencendo lança `new GenerationTimeoutError()` (`http/errors.ts`, TASK-025-003,
  importada, NUNCA redefinida aqui).
- Passo 6: sucesso → MESMA `$transaction` grava `recordProductionStageEvent(tx, {
  rawContentId, stageType: 'PUBLICACAO_PDF', actorId: actor.id, now })`
  (`production-events.service.ts`, já existente; valor de enum novo de TASK-025-001) E
  `tx.publicationEvent.create({ data: { rawContentId, variant, occurredAt: now } })`
  (model novo de TASK-025-001) — só DEPOIS do `Buffer` do PDF já pronto em memória
  (passos 3/4/5 resolvidos com sucesso; nunca antes).
- Passo 7: `filename = \`${rawContentId}-${variant.toLowerCase()}-rascunho.pdf\`` — só
  caracteres ASCII seguros (uuid + literal), sem input do usuário no nome.
- Variável de ambiente nova `PUBLICATION_PDF_TIMEOUT_MS` (default `12000`) em
  `src/config/env.ts` (`z.coerce.number().int().positive().default(12000)`, mesmo padrão
  de `VISUAL_ASSOCIATIONS_MAX_FILE_SIZE_BYTES`), `.env.example` (comentário + valor
  default) e `tests/setup-env.ts` (valor fixo determinístico, mesmo padrão das demais
  chaves).
- Fail-secure: qualquer exceção nos passos 1-5 propaga sem gravar nada — o passo 6 só
  roda depois de (5) resolver com sucesso, na MESMA `$transaction`.

### Não inclui

- Superfície HTTP (`publication.routes.ts`, TASK-025-009).
- Consulta de leitura da métrica exposta em tela (fora de escopo da SPEC, F10).
- Qualquer mudança em `contents.service.ts`, `tira.service.ts` (além do consumo já
  entregue por TASK-025-005), `visual-associations.service.ts`,
  `production-events.service.ts` ou `http/errors.ts` — todos consumidos como já
  exportados, nenhum reescrito aqui.

## Critérios de pronto

- [ ] **AC-024-001** (FR-024-002, gate 1) — Conteúdo bruto SEM Quebra da regra salva,
      `exportPublication` em qualquer Variante → rejeita com `NotFoundError('Quebra da
      regra não encontrada.')`, NENHUM `Buffer` retornado, NENHUM evento gravado
      (`productionStageEvent`/`publicationEvent` count `0` para o `rawContentId`).
      Verificação executável: `npm --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=publication.service.integration.test.ts` (novo arquivo, molde
      `tira.service.integration.test.ts`) → `OK (N tests)`. Fixada antes do código.
- [ ] **AC-024-004** (FR-024-006, gate 1) — Conteúdo bruto com Quebra salva, Tira AINDA
      não aberta, Variante `TIRA`: `exportPublication` gera a Tira automaticamente (via
      `openMnemonicStrip(..., { suppressOpeningEvent: true })`) e compõe o PDF a partir
      dela — NÃO recusa, NÃO exige passo manual anterior; `Buffer` não-vazio devolvido.
      Mesmo comando.
- [ ] Quadro vinculado a uma Associação visual que `buildStripPdf` recusa (via
      `onImageSkipped` — teto de pixels/APNG/PNG malformado, achado de segurança de
      TASK-025-007) — item do Inclui sem AC formal (a garantia de "nunca derruba a
      exportação" já é AC-024-004/FR-024-014, provada em TASK-025-007; este critério
      prova só o CONSUMO do callback): `logger.warn` é chamado exatamente 1 vez por
      Quadro recusado, com `rawContentId`/`frameIndex`/`format`/`reason` e SEM o buffer da
      imagem nem texto do Quadro no payload de log (grep no corpo do log estruturado
      confirma ausência de `Buffer`/texto do Quadro). Mesmo comando.
- [ ] **AC-024-008** (FR-024-009, gate 1) — falha do motor de composição como um todo
      (`buildStripPdf`/`buildSummaryPdf` mockado para rejeitar) em qualquer passo:
      `exportPublication` propaga a exceção, NENHUM `Buffer` é devolvido, NENHUM evento
      gravado (mesma asserção de contagem do item AC-024-001) — distinto de FR-024-014
      (falha isolada de 1 Quadro, que NÃO propaga, já provada em TASK-025-007). Mesmo
      comando.
- [ ] **AC-024-012** (FR-024-010, gate 1) — exportação concluída com sucesso:
      `productionStageEvent` grava 1 linha `stageType: 'PUBLICACAO_PDF'` para o
      `rawContentId`, E `publicationEvent` grava 1 linha com `variant` correto —
      consulta `GROUP BY variant` sobre `publicationEvent.occurredAt` no período do
      teste devolve a contagem esperada (prova a apurabilidade da métrica de SPEC-024
      §1.3, sem exigir tela). Mesmo comando.
- [ ] **AC-024-013** (FR-024-011, gate 1) — 2 chamadas sucessivas de `exportPublication`
      para o MESMO `rawContentId`/Variante: cada uma gera o documento do ZERO (nenhuma
      cópia persistida é reusada — `publicationEvent` acumula 2 linhas, nunca reaproveita
      a 1ª; nenhuma tabela nova além de `publicationEvent`/`productionStageEvent` é
      escrita). Mesmo comando.
- [ ] **AC-024-017** (FR-024-015, gate 1) — `PUBLICATION_PDF_TIMEOUT_MS` mockado para um
      valor muito pequeno (ou a promise de composição mockada para nunca resolver dentro
      da janela): `exportPublication` rejeita com `GenerationTimeoutError` (503,
      `GENERATION_TIMEOUT`, `http/errors.ts`, TASK-025-003) — mesmo canal de falha de
      AC-024-008 (nenhum evento gravado). Mesmo comando.
- [ ] **AC-024-018** (NFR-024-003, gate 1) — EDITOR B (diferente do autor original)
      exporta "resumo" de um Conteúdo bruto JÁ com Quebra salva de EDITOR A, e "tira" de
      um Conteúdo bruto de EDITOR A cuja Tira JÁ está aberta (histórico não-vazio):
      `exportPublication` permite normalmente nos 2 casos (`assertRawContentExportable`
      SEM checagem de autoria). O caso "Tira AINDA não aberta de outro autor" (auto-geração
      + não-autor) segue a guarda ORIGINAL de `openMnemonicStrip` (recusa 409,
      `ConflictError`, mensagem de "abra a tira antes") — comportamento intencional do
      PLAN (DEC-025-007), NÃO testado como sucesso aqui (sinalizado em `duvidas` do
      sumário desta redação, mesmo apontamento do PLAN §1/A-025-001). Mesmo comando.
- [ ] **AC-024-019** (NFR-024-003, gate 1) — 2 sub-casos com a MESMA mensagem
      (`NotFoundError('Conteúdo bruto não encontrado.')`, ordem de guarda — lição
      "[Testes] Árvore de decisão com precedência: a guarda de alcance (passo 1) roda
      SEMPRE primeiro, nunca depois de guarda que revele estado do dado", este mesmo
      arquivo): (a) Conteúdo bruto soft-deleted (`deletedAt` preenchido) exportado por
      QUALQUER EDITOR/ADMIN; (b) Conteúdo bruto soft-deleted E de OUTRO autor ao mesmo
      tempo (par de guardas coincidindo) — mutante que reordena a guarda de alcance para
      depois da de soft-delete faz o par (b) vazar um oráculo distinto (mensagem
      diferente do caso "não existe"), reprovando. Mesmo comando.
- [ ] **AC-024-003** (parte publication.service — a composição em si é provada por
      `pdf-composer.ts`/TASK-025-007; esta TASK prova o MAPEAMENTO de binário real para
      `StripFrameForPdf.image`, Passo 4) — Tira com 3 Quadros: 1 vinculado a uma
      `VisualAssociation` PNG real (fixture do módulo `visual-associations`), 1 vinculado
      a uma `VisualAssociation` `WEBP` real, 1 sem vínculo. `exportPublication` na
      Variante `TIRA` chama `getVisualAssociationBinary` só para os 2 Quadros vinculados;
      o Quadro PNG chega a `buildStripPdf` com `image: { buffer, format: 'PNG' }`
      (asserção sobre o `Buffer` recebido pelo composer, via spy/captura — não string);
      o Quadro `WEBP` e o Quadro sem vínculo chegam ambos com `image: null` — mutante que
      remove a checagem de `format === 'WEBP'` (deixando o buffer WEBP passar adiante)
      faz este caso reprovar. Verificação executável: `npm --prefix mnemonicos-backend
      run test:integration -- --testPathPatterns=publication.service.integration.test.ts`
      → `OK (N tests)`. Fixada antes do código (achado do `qa`, Etapa 3.5 — Passo 4 é
      Inclui explícito desta TASK e parte do comportamento que AC-024-003 promete; sem
      este critério, nenhuma das 13 TASKs exercitava a leitura real de binário).
- [ ] `filename` para `RESUMO` e para `TIRA` segue o formato exato
      \`${rawContentId}-${variant.toLowerCase()}-rascunho.pdf\` — 2 casos, um por
      Variante — item do Inclui sem AC isolado (A-024-007 do PLAN). Mesmo comando.
- [ ] `PUBLICATION_PDF_TIMEOUT_MS` validado pelo `envSchema` real (`config/env.ts`) —
      teste de fronteira (mesmo padrão de `env.test.ts`, que já roda
      `envSchema.safeParse` contra o `.env.example` versionado): `.env.example` com a
      chave nova ainda passa `envSchema.safeParse(...).success === true`. Verificação
      executável: `npm --prefix mnemonicos-backend test -- env` → `OK (N tests)`.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npm --prefix mnemonicos-backend run lint` → exit 0.

## Riscos específicos

- TRISK-025-001 (`ALTER TYPE` pode exigir commit intermediário) — mitigado em
  TASK-025-001; esta TASK só consome o valor `PUBLICACAO_PDF` já migrado (dependência
  declarada).
- A auto-geração de Tira "não-autor" (não testada como sucesso, AC-024-018 parcial) é
  achado do PLAN (A-025-001/DEC-025-007) — `Reabrir se`: o Diretor/PO confirmar o
  comportamento alternativo, conforme já registrado no PLAN §6.
- TRISK-025-005 (`Promise.race` garante a resposta HTTP dentro do teto, não libera CPU
  imediatamente — Node não preempta código síncrono do `pdf-lib` já em andamento) —
  aceito pelo PLAN, medição real fica para gate 10.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
**Jira**: KAN-115

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
