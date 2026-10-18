# TASK-065-007: Imagem em destaque no PDF final, Quadro sem imagem e teto de tamanho

**Slug**: producao-material
**Pertence a**: PLAN-065
**Realiza (FRs)**: FR-064-009, FR-064-013, FR-064-029
**Funcionalidade**: FEAT-064-002 (primária)
**Componente**: COMP-065-003 (principal), COMP-065-002, COMP-065-005, COMP-065-006
**Wave**: 3
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-065-006
- **Bloqueia**: TASK-065-008, TASK-065-009, TASK-065-010, TASK-065-012

## Contexto

O PDF final da 006 sai só com texto; esta TASK faz cada Quadro com Associação visual PNG/JPEG sair com a imagem dominante na página (sem recodificar), classifica o Quadro sem imagem e o de imagem que não entrou, calcula a cobertura N de M e recusa PDF acima do teto de tamanho. Território e decisões vigentes: memo de exploração e MAP do slug; DEC-065-002, DEC-065-005, DEC-065-010 e TRISK-065-005 no PLAN-065.

Ambiente de execução: os comandos rodam a partir da raiz `Mnemonico/kan237/` (contém `mnemonicos-backend/` e `mnemonicos-frontend/`, worktrees da branch do épico, e `docs/`, symlink para o workspace). Antes da suíte de integração: `source env-kan237.sh` (exporta `TEST_DATABASE_URL`, Postgres dedicado 127.0.0.1:5433, e `KAN237_DB_CONTAINER`); nunca aceitar reset em banco compartilhado. Exclusividade do banco: `docker exec "${KAN237_DB_CONTAINER:-mnemonicos-db}" psql -U postgres -d postgres -tAc "SELECT count(*) FROM pg_stat_activity WHERE datname = 'mnemonicos_test' AND pid <> pg_backend_pid()"` → `0`.

## Escopo

### Inclui
- mnemonicos-backend/src/modules/publication/final-image.ts (novo): `prepareFrameImage` e `PreparedImageResult`, sem ramo WEBP (WEBP cai em `failed`/`unsupported` até a TASK-065-008); detecção pelo conteúdo (`detectImageSignature`), nunca pelo `mimeType` armazenado.
- mnemonicos-backend/src/modules/publication/strip-coverage.ts (novo): `computeStripCoverage`, `RECOMMENDED_LONG_SIDE_PX` (2000), `ExportWarning`, `ExportWarningKind`, `StripCoverage`.
- mnemonicos-backend/src/modules/publication/final-pdf-composer.ts: caixa de imagem `FINAL_LAYOUT.IMAGE_BOX_WIDTH_PT` x `IMAGE_BOX_HEIGHT_PT` (480 x 400 pt) centralizada, só reduz, proporção preservada; texto abaixo da imagem; sem imagem o texto começa no topo; `FinalStripFrame.binary` e `FinalPdfResult.coverage`.
- mnemonicos-backend/src/modules/publication/publication.service.ts: `loadFinalExportInput` lê os binários Quadro a Quadro via `getVisualAssociationBinary`; `assertFinalPdfWithinCap` aplicado na exportação final.
- mnemonicos-backend/src/http/errors.ts (`FinalPdfTooLargeError`, 422 `FINAL_PDF_TOO_LARGE`, `details` `{ byteSize, maxBytes, heaviestFrames }`, `heaviestFrames` com até 3 posições em ordem decrescente de bytes de imagem), mnemonicos-backend/src/config/env.ts, mnemonicos-backend/.env.example, mnemonicos-backend/tests/setup-env.ts (`PUBLICATION_FINAL_PDF_MAX_BYTES`, default 4000000), mnemonicos-backend/src/domain/types.ts (código `FINAL_PDF_TOO_LARGE`).
- Testes: mnemonicos-backend/tests/unit/final-image.test.ts, mnemonicos-backend/tests/unit/strip-coverage.test.ts (inclui o drift-guard da resolução recomendada), mnemonicos-backend/tests/unit/final-pdf-composer.test.ts (edição declarada: os fixtures da 006 ganham `binary: null`; as asserções da 006 permanecem), mnemonicos-backend/tests/unit/env.test.ts (default e rejeição; reusa `loadEnvModule()`), mnemonicos-backend/tests/unit/image-signature.test.ts (extração mecânica de `jpegHeaderWithDimensions`), mnemonicos-backend/tests/support/jpeg-fixtures.ts (novo, dono do helper), mnemonicos-backend/tests/integration/publication.final-images.integration.test.ts.
- mnemonicos-frontend/src/types/domain.ts: espelho do código `FINAL_PDF_TOO_LARGE`, no mesmo diff.

### Não inclui
- WEBP: nenhum critério desta TASK trata WEBP; para provar falha usa-se buffer não-WEBP (PNG com IHDR sem IDAT, APNG com chunk `acTL`). A conversão é da TASK-065-008; `readWebpDimensions` também.
- Preview da exportação e rota GET (TASK-065-009); botão e Aviso de exportação na tela (TASK-065-014).
- Teto de tamanho na publicação: a TASK-065-012 aplica `assertFinalPdfWithinCap`; aqui só na exportação final.
- Redução de imagens acima da Resolução recomendada no modo final (TASK-065-008); o teto desta TASK é a rede de segurança que indica quais Quadros pesam mais.
- Páginas suplementares do rascunho (o PDF final não as inclui: capa e Quadros apenas); edição de `pdf-composer.ts` (DEC-065-022).
- Medição de custo de memória/tempo da leitura dos binários (TRISK-065-005): gate 10, não asserção desta TASK.

## Critérios de pronto

- [ ] `prepareFrameImage`, um teste por ramo e por razão, com fixture discriminante (lição `extrator-com-cadeia-de-fallback-a-b-c-exige-1-teste-por-ramo-fixture-sempre-completo-nunca-exercita-o-2-3-fallback`): `none` (entrada nula), `ok` PNG, `ok` JPEG, `failed`/`apng` (PNG com chunk `acTL`), `failed`/`decode-failed` (PNG com IHDR e sem IDAT, via `pngHeaderWithDimensions`), `failed`/`pixel-budget-exceeded` (`pngHeaderWithDimensions(5001, 4001)`, acima de `IMAGE_PIXEL_BUDGET_PX`); verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/final-image.test.ts` → `0 failed` e `N passed` (N > 0, preenchido no baseline do developer, com os 6 casos nomeados por ramo); mutante por ramo (remover cada ramo, em `git worktree add`, nunca na árvore principal) reprova o caso do ramo e nenhum outro
- [ ] `computeStripCoverage` conta N e M para as 3 categorias: Quadro `BELOW_RECOMMENDED_RESOLUTION` conta em N; `MISSING_IMAGE` e `IMAGE_NOT_EMBEDDABLE` não contam; `warnings` ordenados por `position` e depois por `kind`, e posições desordenadas na entrada saem ordenadas; cada item de `warnings` tem exatamente as chaves `['kind', 'position']` (lição `select-exposto-que-le-campo-interno-prova-as-chaves-do-payload`, `Object.keys(...).sort()`); verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/strip-coverage.test.ts` → `0 failed` e `N passed` (N > 0); mutante `BELOW` deixa de contar em N reprova
- [ ] Caixa de imagem do Quadro longo (resolução PO Q2 item (d), transferido da TASK-065-006): no fixture com um Quadro ilustrado de texto curto e outro ilustrado cujo texto ocupa mais de uma página, a matriz `cm` da imagem desenhada na 1ª página do Quadro longo tem a mesma largura e altura que a do Quadro curto (mesma imagem 2000×1333), e as páginas de continuação do Quadro longo não têm XObject de imagem; verificação executável: comando de integração desta TASK (`source env-kan237.sh` antes) → `0 failed`; o mutante que reduz a caixa proporcionalmente ao texto (no worktree) reprova a igualdade.
- [ ] Drift-guard da resolução recomendada: `Math.round(FINAL_LAYOUT.IMAGE_BOX_WIDTH_PT / 72 * 300) === RECOMMENDED_LONG_SIDE_PX` (480 pt a 300 dpi = 2000 px); verificação executável: confirmação isolada `npm --prefix mnemonicos-backend test -- tests/unit/strip-coverage.test.ts -t "drift"` → `1 passed` (nome do caso contendo "drift"); o mutante `IMAGE_BOX_WIDTH_PT = 500` no worktree roda pelo comando do arquivo inteiro (`npm --prefix mnemonicos-backend test -- tests/unit/strip-coverage.test.ts`, nunca `-t`) e reprova esse caso
- [ ] AC-064-008: exportação final de Tira com Quadros ilustrados (imagem PNG 2000x1333 e imagem JPEG) leva cada imagem à página do seu Quadro, na ordem da Tira, com o texto do Quadro abaixo da imagem (NFR-064-005: os bytes do stream do JPEG no PDF são idênticos aos do arquivo de origem; o PNG mantém as dimensões de origem, sem reamostrar; imagem acima da caixa só reduz, nunca amplia); verificação executável: `npm --prefix mnemonicos-backend run test:integration -- tests/integration/publication.final-images.integration.test.ts` → `0 failed` e `N passed` (N > 0), contando 1 XObject de imagem em cada página de Quadro ilustrado e comparando o stream do JPEG com o fixture; mutante que recodifica o JPEG (embute outro buffer) reprova a comparação
- [ ] AC-064-008 (tamanho desenhado, lido da matriz `cm` do content stream da página): imagem paisagem 2000x1333 → largura desenhada = largura da caixa (480 pt); retrato 1000x2000 → altura desenhada = altura da caixa (400 pt); pequena 300x200 → tamanho natural (não amplia); proporção largura/altura preservada nos três casos (tolerância de 0,01 pt); verificação executável: mesmo comando de integração → `0 failed`; mutante que amplia a imagem pequena até a caixa reprova o caso 300x200
- [ ] AC-064-011 (parte PDF — a lista do Aviso de exportação é da TASK-065-009 e a tela é da TASK-065-014): Quadro sem Associação visual e Quadro com imagem indecodificável saem só com texto e a exportação conclui (200, PDF); verificação executável: mesmo comando de integração, com 0 XObject de imagem na página do Quadro corrompido e o texto presente, e controle positivo na mesma suíte (a página do Quadro com imagem válida tem 1 XObject); vínculo cuja associação não tem binário (`getVisualAssociationBinary` devolve `null`) sai como Quadro sem imagem, nunca como 500 (lição `orthrow-so-depois-da-guarda-que-torna-a-ausencia-impossivel`); mutante que lança no ramo `failed` reprova
- [ ] AC-064-025 (parte — o preview é da TASK-065-009, a tela da TASK-065-014 e a publicação da TASK-065-012): exportação final de Tira com um Quadro de imagem de lado maior abaixo de 2000 px e outro de 2000 px conclui sem bloqueio, o PDF sai com as duas imagens e `coverage` classifica só o Quadro abaixo como `BELOW_RECOMMENDED_RESOLUTION` contando em N; verificação executável: mesmo comando de integração → `0 failed`; fronteira 1999 avisa e 2000 não avisa (dois casos de `computeStripCoverage`)
- [ ] Teto de tamanho (critério herdado de DEC-065-010, por extenso): PDF final acima de `PUBLICATION_FINAL_PDF_MAX_BYTES` é recusado com 422 `FINAL_PDF_TOO_LARGE`, `details` `{ byteSize, maxBytes, heaviestFrames }` (chaves exatas, `Object.keys(details).sort()`; `heaviestFrames` com no máximo 3 posições, em ordem decrescente de bytes de imagem; fixture com 4 Quadros de pesos distintos devolve as 3 posições mais pesadas na ordem), sem `ProductionStageEvent` e sem `PublicationEvent` (contagens iguais antes e depois; a contagem de `published_pdfs` também, quando aplicável); o teto é baixado no teste por atribuição a `env.PUBLICATION_FINAL_PDF_MAX_BYTES` com restauração no `afterEach` (molde: `tests/integration/publication.service.integration.test.ts:481`); a mensagem diz o próximo passo ("reduza o tamanho das imagens ... e exporte de novo", lição `mensagem-de-recusa-recuperavel-diz-o-proximo-passo-com-o-nome-da-acao-da-tela`); verificação executável: confirmação isolada `npm --prefix mnemonicos-backend run test:integration -- tests/integration/publication.final-images.integration.test.ts -t "FINAL_PDF_TOO_LARGE"` → `N passed` (N > 0); o mutante que remove a chamada de `assertFinalPdfWithinCap` em `publication.service.ts` (worktree) roda pelo comando do arquivo inteiro, sem `-t`, e reprova
- [ ] Endereço do teto (um arquivo por ação): `grep -cE '^PUBLICATION_FINAL_PDF_MAX_BYTES=4000000$' mnemonicos-backend/.env.example` → `1` (0 no commit-pai); `grep -cE '^process\.env\.PUBLICATION_FINAL_PDF_MAX_BYTES = ' mnemonicos-backend/tests/setup-env.ts` → `1` (0 no commit-pai); `grep -cE '^ +PUBLICATION_FINAL_PDF_MAX_BYTES: .*\.default\(4000000\)' mnemonicos-backend/src/config/env.ts` → `1` (0 no commit-pai)
- [ ] `env.ts`: default 4000000 e rejeição de valor não-positivo, reusando `loadEnvModule()` do topo do arquivo; verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/env.test.ts` → `0 failed` e `N passed` (N > 0); mutante `.positive()` removido reprova o caso de rejeição de 0
- [ ] Uma definição só de helper (lição `corre-o-de-duplica-o-dry-introduz-nova-re-deriva-o-do-can-nico-no-mesmo-diff`): `git -C mnemonicos-backend grep -nE '^(export )?function (jpegHeaderWithDimensions|pngHeaderWithDimensions)\(' -- tests/` → exatamente 2 linhas, em `tests/support/jpeg-fixtures.ts` e `tests/support/png-fixtures.ts` (no commit-pai a 1a linha está em `tests/unit/image-signature.test.ts`); nenhum arquivo novo ou alterado da TASK (`git -C mnemonicos-backend diff --name-only <commit-pai>..HEAD -- tests/`) redefine esses helpers; `npm --prefix mnemonicos-backend test -- tests/unit/image-signature.test.ts` → `0 failed` e `N passed`, com N igual ao do baseline capturado antes da extração (a extração é mecânica: nenhum `it(` some)
- [ ] Edição declarada de `tests/unit/final-pdf-composer.test.ts` (fixtures da 006 com `binary: null`): as asserções da 006 seguem verdes e os valores observáveis da 006 não são reescritos; verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/final-pdf-composer.test.ts` → `0 failed` e `N passed`, com N maior ou igual ao do baseline da 006
- [ ] Mirror do código no frontend (lição `coment-rio-que-afirma-paridade-entre-os-dois-repos-s-vale-se-o-teste-ler-as-duas-fontes`; a rede de paridade das CHAVES de `PUBLICATION_FINAL_ERROR_CODES` é `tests/unit/domain-types-parity.test.ts` estendido pela TASK-065-006 (D3) — além do critério estrutural abaixo, `npm --prefix mnemonicos-backend test -- tests/unit/domain-types-parity.test.ts` → `0 failed`): `grep -cE '^ +FINAL_PDF_TOO_LARGE:' mnemonicos-backend/src/domain/types.ts` → `1` e `grep -cE '^ +FINAL_PDF_TOO_LARGE:' mnemonicos-frontend/src/types/domain.ts` → `1` (0 nos dois no commit-pai); `npm --prefix mnemonicos-frontend run typecheck` → saída 0
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git -C mnemonicos-backend diff --name-only main...HEAD` e `git -C mnemonicos-frontend diff --name-only main...HEAD`), produção e teste: `npm --prefix mnemonicos-backend run lint`, `npm --prefix mnemonicos-backend run typecheck` e `npm --prefix mnemonicos-backend run format:check` saem 0

## Riscos específicos

- TRISK-065-005: Quadros processados e liberados um a um é decisão de projeto; o custo de memória e tempo com tira real é medido no gate 10, não assertado aqui.
- A suíte de integração roda em banco compartilhado (`--runInBand`, lição `su-te-de-integra-o-com-ddl-truncate-em-banco-compartilhado-exige-exclusividade-real-entre-execu-es-concorrentes-n-o-s-runinband`); não executar duas suítes de integração em paralelo.
- Paridade dos códigos de erro (decisão D3): a TASK-065-006 estende `domain-types-parity.test.ts` para comparar as CHAVES de `PUBLICATION_FINAL_ERROR_CODES` nas duas fontes, sem lista literal total; esta TASK acrescenta `FINAL_PDF_TOO_LARGE` nos dois lados e o teste segue verde sem edição.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
**Jira**: KAN-267

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
<!-- Branch, tentativas, arquivos, revisores e narrativa (retries, escalações) vivem no
ledger da sessão e no commit da closure (4.76) — não se repetem aqui (4.409). -->
