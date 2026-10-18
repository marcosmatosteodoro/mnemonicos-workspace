# TASK-065-008: WEBP aparece no PDF final (conversão para PNG com sharp)

**Slug**: producao-material
**Pertence a**: PLAN-065
**Realiza (FRs)**: FR-064-012
**Funcionalidade**: FEAT-064-002 (primária)
**Componente**: COMP-065-003 (principal)
**Wave**: 4
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-065-007, TASK-065-005
- **Bloqueia**: TASK-065-010

## Contexto

Quadro vinculado a imagem WEBP, nova ou já existente no acervo, passa a aparecer no PDF final: o preparo de imagem converte o WEBP com `sharp` — opaco em JPEG q85, com alfa em PNG (emenda da DEC-065-004 após a MEDICAO-065) — e segue o mesmo embedding das demais imagens; o rascunho continua sem exibir WEBP. A decisão de conversão e o custo medido estão em DEC-065-004 do PLAN-065 e em `docs/producao-material/medicoes/MEDICAO-065-sharp-pdf.md` (TASK-065-005). A TASK também reduz, só no modo final, imagem PNG/JPEG de lado maior acima da Resolução recomendada até ela (DEC-065-010, escolha adotada), para a tira caber no teto de tamanho; a imagem da Biblioteca visual não é alterada.

Ambiente de execução: os comandos rodam a partir da raiz `Mnemonico/kan237/` (contém `mnemonicos-backend/` e `mnemonicos-frontend/`, worktrees da branch do épico, e `docs/`, symlink para o workspace). Antes da suíte de integração: `source env-kan237.sh` (exporta `TEST_DATABASE_URL`, Postgres dedicado 127.0.0.1:5433, e `KAN237_DB_CONTAINER`); nunca aceitar reset em banco compartilhado. Exclusividade do banco: `docker exec "${KAN237_DB_CONTAINER:-mnemonicos-db}" psql -U postgres -d postgres -tAc "SELECT count(*) FROM pg_stat_activity WHERE datname = 'mnemonicos_test' AND pid <> pg_backend_pid()"` → `0`. O `sharp` só existe no worktree (instalado na TASK-065-005): comandos `node -e "require('sharp')…"` rodam com cwd `mnemonicos-backend` do kan237.

## Escopo

### Inclui
- mnemonicos-backend/src/modules/publication/final-image.ts: ramo WEBP em `prepareFrameImage` (`sharp(buf, { limitInputPixels, animated: false, failOn: <valor explícito registrado no baseline> })`, primeiro quadro, resultado `ok` com `convertedFrom: 'WEBP'`; saída JPEG q85 4:2:0 se `metadata().hasAlpha === false`, PNG sem perda se `true`), redução de PNG/JPEG de lado maior acima de `RECOMMENDED_LONG_SIDE_PX` (importada de `strip-coverage.ts`, sem novo literal 2000) no modo final e `readWebpDimensions` (devolve `{ width, height }` ou `null` sem lançar); orçamento de pixels pela constante `IMAGE_PIXEL_BUDGET_PX`; parâmetros de cache e concorrência do `sharp` iguais aos registrados na TASK-065-005.
- mnemonicos-backend/tests/unit/final-image-webp.test.ts (novo; não edita o teste da TASK-065-007).
- mnemonicos-backend/tests/integration/publication.final-webp.integration.test.ts (novo).
- mnemonicos-backend/tests/integration/publication.final-reduction.integration.test.ts (novo; fixtures JPEG e PNG 4000x3000 e 2000x1500 gerados com `sharp` no próprio teste).
- mnemonicos-backend/tests/support/webp-fixtures.ts (novo): `buildValidWebpNxN(w, h)`, gerado com `sharp`, dono do helper (a TASK-065-010 o reusa).

### Não inclui
- Rascunho: `pdf-composer.ts` continua pulando WEBP; isso é provado aqui, não alterado.
- Aviso de resolução no upload (TASK-065-010).
- Edição dos testes da TASK-065-007 (`tests/unit/final-image.test.ts` fica como está).
- Prova de `sharp` na Vercel (deploy de preview, gate 10, TRISK-065-002).

## Critérios de pronto

- [ ] AC-064-010: Quadro vinculado a WEBP válido (`buildValidWebpNxN(2000, 1333)`) sai no PDF final com a imagem na página do Quadro; `prepareFrameImage` devolve `status: 'ok'` com `convertedFrom: 'WEBP'`; verificação executável: `npm --prefix mnemonicos-backend run test:integration -- tests/integration/publication.final-webp.integration.test.ts` → `0 failed` e `N passed` (N > 0), com 1 XObject de imagem na página desse Quadro (mesma contagem de XObject usada pela TASK-065-007); controle negativo no mesmo arquivo: o MESMO conteúdo exportado como rascunho tem 0 XObject de imagem (o rascunho segue sem exibir WEBP); mutante que remove o ramo WEBP em `final-image.ts` (em `git worktree add`, nunca na árvore principal) reprova o caso do PDF final e o caso `ok`
- [ ] Saída da conversão pelo canal alfa (emenda DEC-065-004, pendência herdada da MEDICAO-065): WEBP opaco 2000×1333 fotográfico → imagem embutida no PDF final com filtro `DCTDecode` (JPEG), mesmas dimensões, e o PDF de 1 Quadro ≤ 1 000 000 bytes; WEBP com alfa → `FlateDecode` com `SMask` (PNG com transparência preservada); imagem PNG/JPEG 4000×3000 opaca reduzida → `DCTDecode`; PNG 4000×3000 com alfa reduzido → `FlateDecode` + `SMask`; verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/final-image-webp.test.ts` → `0 failed`; par de provas: o mutante que força PNG para todo WEBP reprova o caso opaco (filtro e teto de bytes); o mutante que força JPEG reprova o caso com alfa (SMask ausente).
- [ ] NFR-064-005 (critério sem AC id; vale para WEBP COM ALFA → PNG, sem perda): os pixels do PNG convertido são os da decodificação do WEBP de origem, sem reamostrar nem girar; fixture com gradiente não uniforme (cor sólida não discrimina); verificação executável: confirmação isolada `npm --prefix mnemonicos-backend test -- tests/unit/final-image-webp.test.ts -t "pixels"` → `N passed` (N > 0), comparando `sharp(png).raw().toBuffer()` com `sharp(webp).raw().toBuffer()` byte a byte; o mutante que aplica `resize` ao converter roda pelo comando do arquivo inteiro (`npm --prefix mnemonicos-backend test -- tests/unit/final-image-webp.test.ts`, sem `-t`) e reprova
- [ ] `readWebpDimensions` devolve largura e altura exatas, com dois valores distintos (`buildValidWebpNxN(640, 480)` → `{ width: 640, height: 480 }`, para que trocar largura por altura reprove) e devolve `null`, sem lançar, para WEBP ilegível (`WEBP_FIXTURE_BUFFER`, só a assinatura de 12 bytes); verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/final-image-webp.test.ts` → `0 failed` e `N passed` (N > 0), com os casos de `readWebpDimensions` nomeados; confirmação isolada com `-t "readWebpDimensions"` → `N passed` (N > 0); mutante que troca largura por altura roda pelo arquivo inteiro e reprova
- [ ] Um teste por ramo (lição `extrator-com-cadeia-de-fallback-a-b-c-exige-1-teste-por-ramo-fixture-sempre-completo-nunca-exercita-o-2-3-fallback`): WEBP sólido 5001x4001 → `failed` com razão `pixel-budget-exceeded`; WEBP com RIFF corrompido (`WEBP_FIXTURE_BUFFER` e um WEBP válido truncado) → `failed` com razão `decode-failed`; nenhum dos dois lança; verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/final-image-webp.test.ts` → `0 failed` e `N passed` (N > 0); na integração, Quadro com WEBP corrompido conclui a exportação com 0 XObject na página e texto presente (controle positivo: o Quadro com WEBP válido tem 1)
- [ ] Redução no modo final: no fixture com um Quadro de imagem JPEG 4000×3000 e outro PNG 4000×3000, a imagem embutida no PDF final tem lado maior = `RECOMMENDED_LONG_SIDE_PX` (proporção preservada, ±1 px). No Quadro com imagem PNG/JPEG de 2000×1500, o fluxo de imagem embutido é byte a byte igual ao original (hash igual). O registro da imagem na Biblioteca visual tem o mesmo hash antes e depois da exportação. O rascunho do mesmo fixture embute os originais sem redução. Verificação executável: `npm --prefix mnemonicos-backend run test:integration -- tests/integration/publication.final-reduction.integration.test.ts` → `0 failed` e `N passed` (N > 0). Um mutante que reduz também a imagem de 2000 px reprova o caso do hash (mutante em `git worktree add`, nunca na árvore principal)
- [ ] WEBP animado e corte literal (QA): WEBP animado de 3 quadros com dimensões distintas por quadro sai com 1 XObject de imagem e com as dimensões do 1º quadro; o WEBP válido truncado é cortado em um byte literal (N bytes, registrado no baseline e verificado: o corte ainda mantém a assinatura RIFF/WEBP e falha na decodificação com `decode-failed`); `failOn` está explícito na chamada do `sharp` (`grep -cE '^[^*/]*failOn:' mnemonicos-backend/src/modules/publication/final-image.ts` → `1`); verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/final-image-webp.test.ts` → `0 failed` e `N passed` (N > 0); mutante que remove `animated: false` reprova o caso animado
- [ ] Não-regressão da integração de imagens da TASK-065-007 após a redução (W5 da revalidação): `source env-kan237.sh && npm --prefix mnemonicos-backend run test:integration -- tests/integration/publication.final-images.integration.test.ts` → `0 failed`, `N passed` com N igual ao baseline capturado antes de começar (os JPEG/PNG dos fixtures da 007 de lado maior ≤ `RECOMMENDED_LONG_SIDE_PX` seguem byte-idênticos; fixture da 007 acima do limiar é ajustado nesta TASK com o motivo registrado).
- [ ] PNG e JPEG de até `RECOMMENDED_LONG_SIDE_PX` seguem sem recodificar (regressão da TASK-065-007, o mesmo teste de pass-through reexecutado): `npm --prefix mnemonicos-backend test -- tests/unit/final-image.test.ts` → `0 failed` e `N passed`, com N igual ao do baseline capturado antes de começar; mutante que passa todo formato pelo `sharp` reprova o teste de pass-through do JPEG
- [ ] Orçamento de pixels pela constante canônica, sem re-literal (lição `corre-o-de-duplica-o-dry-introduz-nova-re-deriva-o-do-can-nico-no-mesmo-diff`): `grep -cE '^[^*/]*20_000_000' mnemonicos-backend/src/modules/publication/final-image.ts` → `0`; calibração com positivo conhecido: `grep -cE '^[^*/]*20_000_000' mnemonicos-backend/src/modules/visual-associations/image-signature.ts` → `1` (a declaração de `IMAGE_PIXEL_BUDGET_PX`)
- [ ] Uma definição só do fixture de WEBP: `git -C mnemonicos-backend grep -nE '^(export )?(async )?function buildValidWebpNxN\(' -- tests/` → exatamente 1 linha, em `tests/support/webp-fixtures.ts`; nenhum teste novo da TASK redefine `buildValidWebpNxN`
- [ ] Cache e concorrência do `sharp` iguais aos da decisão escrita em `docs/producao-material/medicoes/MEDICAO-065-sharp-pdf.md` (linhas ancoradas `^| sharp-cache |` e `^| sharp-concurrency |`, lidas no baseline do developer; ausentes lá → o developer devolve a dúvida em vez de escolher valor; `sharp.cache()` também é comparado com o valor registrado): confirmação isolada `npm --prefix mnemonicos-backend test -- tests/unit/final-image-webp.test.ts -t "concurrency"` → `N passed` (N > 0), comparando `sharp.concurrency()` com o valor registrado; o mutante com outro valor roda pelo comando do arquivo inteiro, sem `-t`, e reprova
- [ ] O rascunho não foi alterado: `git -C mnemonicos-backend diff --stat <commit-pai-da-TASK>..HEAD -- src/modules/publication/pdf-composer.ts` → saída sem linhas (ancorado no commit-pai da TASK, não na `main`); `npm --prefix mnemonicos-backend test -- tests/unit/pdf-composer.test.ts` → `0 failed` e `N passed` com N igual ao do baseline
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git -C mnemonicos-backend diff --name-only main...HEAD`), produção e teste: `npm --prefix mnemonicos-backend run lint`, `npm --prefix mnemonicos-backend run typecheck` e `npm --prefix mnemonicos-backend run format:check` saem 0

- [ ] (pendência herdada do gate 10 da wave 2 — lacuna da MEDICAO-065) Medir no caminho ADOTADO (decode JPEG/WEBP até `IMAGE_PIXEL_BUDGET_PX` → resize a `RECOMMENDED_LONG_SIDE_PX` → JPEG q85, conversões em sequência): pico de RSS e tempo para M = 8 imagens de 20 Mpx (WEBP 5000×4000 e JPEG 5000×4000), e acrescentar as linhas `^| rss-caminho-jpeg |` e `^| tempo-caminho-jpeg-m8 |` ao `docs/producao-material/medicoes/MEDICAO-065-sharp-pdf.md`; a linha `m-maximo` obsoleta (PNG) é marcada como tal; verificação: `grep -cE "^\| (rss-caminho-jpeg|tempo-caminho-jpeg-m8) \|" docs/producao-material/medicoes/MEDICAO-065-sharp-pdf.md` → `2`; tempo M=8 sob `PUBLICATION_PDF_TIMEOUT_MS` (12 s) e RSS sob 1024 MB, senão a TASK devolve o número e reabre DEC-065-004/010.

## Riscos específicos

- Gate 8 (supply chain de `sharp`/libvips) e gate 10 (tempo e memória de conversão em tira real): a medição local é da TASK-065-005; o comportamento do binário na Vercel só se prova em deploy de preview.
- `WEBP_FIXTURE_BUFFER` (`tests/support/visual-association-fixtures.ts:29`) tem só a assinatura RIFF/WEBP de 12 bytes e não decodifica; serve ao caso de WEBP ilegível, nunca ao caso de sucesso.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
**Jira**: KAN-268

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
