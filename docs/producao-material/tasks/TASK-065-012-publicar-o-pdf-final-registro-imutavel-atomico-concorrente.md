# TASK-065-012: Publicar o PDF final (registro imutável, atômico, concorrente)

**Slug**: producao-material
**Pertence a**: PLAN-065
**Realiza (FRs)**: FR-064-016, FR-064-017, FR-064-018, FR-064-023, FR-064-024, FR-064-031, FR-064-032, FR-064-033
**Funcionalidade**: FEAT-064-003 (primária)
**Componente**: COMP-065-010 (principal), COMP-065-011
**Wave**: 7
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-065-004, TASK-065-007, TASK-065-011
- **Bloqueia**: TASK-065-013, TASK-065-015

## Contexto

EDITOR e ADMIN publicam o PDF final de um Conteúdo com Versão aprovada e válida: o sistema gera o documento, grava um registro novo e imutável (com quem, quando, Versão, N e M, bytes e sha256) e emite o evento de publicação na mesma transação, ou não grava nada. Duas publicações simultâneas nunca deixam registro parcial. As rotas de leitura e a tabela vêm das TASKs 065-011 e 065-004; as confirmações de cobertura incompleta e de republicar são da TASK-065-013. Território: memo de exploração e MAP do slug; TRISK-065-006, A-064-005 e DEC-065-018 no PLAN-065.

Ambiente de execução: os comandos rodam a partir da raiz `Mnemonico/kan237/` (contém `mnemonicos-backend/` e `mnemonicos-frontend/`, worktrees da branch do épico, e `docs/`, symlink para o workspace). Antes da suíte de integração: `source env-kan237.sh` (exporta `TEST_DATABASE_URL`, Postgres dedicado 127.0.0.1:5433, e `KAN237_DB_CONTAINER`); nunca aceitar reset em banco compartilhado. Exclusividade do banco: `docker exec "${KAN237_DB_CONTAINER:-mnemonicos-db}" psql -U postgres -d postgres -tAc "SELECT count(*) FROM pg_stat_activity WHERE datname = 'mnemonicos_test' AND pid <> pg_backend_pid()"` → `0`.

## Escopo

### Inclui
- mnemonicos-backend/src/modules/publication/published-pdf.service.ts: `publishFinalPdf` (acrescentado ao arquivo da TASK-065-011), na sequência `assertRawContentExportable` → elegibilidade → `loadFinalExportInput` → `buildFinalStripPdf` sob `withDeadline` → `assertFinalPdfWithinCap` → `$transaction` com re-verificação da elegibilidade (TRISK-065-006), `store.insert` e `recordPdfExportEvents`; assinatura na convenção do módulo (cliente `db` injetável e relógio `now` injetável, como `exportPublication(rawContentId, input, actor, db)` em `publication.service.ts:440`), não a literal do PLAN; N, M, `pageCount`, `byteSize` e sha256 vêm do PDF composto, nunca do pedido.
- mnemonicos-backend/src/modules/publication/published-pdf.routes.ts: `POST /contents/:id/publications` com `verifyOrigin` como primeiro handler, `requireRole('POST', '/contents/:id/publications', 'EDITOR', 'ADMIN')`, 201 com `PublicationListItem`, sem ler o corpo.
- mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts (censo de rotas) e mnemonicos-backend/tests/integration/published-pdf.publish.integration.test.ts (novo; reusa `seedApprovedStrip` e `countExportEvents` de `tests/support/final-export-fixtures.ts` e o helper `tests/support/failing-transaction-client.ts`, todos da TASK-065-006, e `seedPublishedPdf` da TASK-065-004).

### Não inclui
- As flags `acknowledgeIncomplete` e `acknowledgeRepublish` e seus 409 (TASK-065-013): nenhum critério desta TASK afirma o resultado de publicar sem flag uma Tira com N < M, nem de republicar a mesma Versão sem flag. Os fixtures desta TASK usam N = M (imagem abaixo de 2000 px conta em N).
- Leitura do corpo da requisição e seu schema (TASK-065-013); UI (TASK-065-015, TASK-065-016).
- Prova de teto de duração com carga CPU-bound real: `withDeadline` é reusado como na exportação; o custo em tira real é do gate 10 (lição `teto-de-dura-o-via-promise-race-settimeout-n-o-corta-trabalho-cpu-bound-s-ncrono-e-teste-que-prova-o-teto-com-dubl-settimeout-n-o-falsifica-nada`: teste de teto com dublê de timer não falsifica nada, então nenhum é escrito aqui).
- Excluir, despublicar ou substituir PDF publicado; novo `update`/`delete` sobre `published_pdfs`.
- Helper novo em `tests/support/`: o proxy de falha injetada na transação é o `tests/support/failing-transaction-client.ts` criado pela TASK-065-006 (esta TASK o cita; 012 depende dela transitivamente, 012 ← 007 ← 006).

## Critérios de pronto

- [ ] AC-064-013: publicar Conteúdo com Versão aprovada e válida responde 201 com `PublicationListItem` (chaves exatas `['byteSize', 'current', 'framesTotal', 'framesWithImage', 'id', 'publishedAt', 'publishedBy', 'versionNumber']`, lição `select-exposto-que-le-campo-interno-prova-as-chaves-do-payload`); o histórico (rota da TASK-065-011) passa a mostrar o registro com Versão, data, autor, N e M; dois downloads seguidos são idênticos entre si e idênticos ao `pdfData` lido direto do banco, e o sha256 dos bytes baixados é igual ao `sha256` gravado e ao `ETag` do download (o "sha256 da resposta" é o `ETag`); verificação executável: `npm --prefix mnemonicos-backend run test:integration -- tests/integration/published-pdf.publish.integration.test.ts` → `0 failed` e `N passed` (N > 0); mutante que grava o buffer de uma segunda composição (bytes diferentes do hash) reprova a igualdade com o sha256
- [ ] N e M gravados são os do PDF composto: Tira de 2 Quadros ilustrados grava `framesTotal` 2 e `framesWithImage` 2; Tira com um Quadro de imagem abaixo de 2000 px publica (201) e o Quadro conta em N (AC-064-025, parte publicação — a exportação e o preview são das TASKs 065-007 e 065-009, a tela da TASK-065-014); `byteSize` é o tamanho de `pdfData` e `pageCount` é o número de páginas do PDF; verificação executável: mesmo comando de integração → `0 failed`; mutante que grava `framesWithImage` de uma contagem separada do `coverage` reprova
- [ ] AC-064-014: Conteúdo sem Versão aprovada, e Conteúdo com Versão alterada depois do fechamento, recusam a publicação (409 `FINAL_EXPORT_NOT_ELIGIBLE` com a `reason` correspondente, mensagem e classe de erro iguais às da exportação final da TASK-065-006, lição `mensagem-de-recusa-recuperavel-diz-o-proximo-passo-com-o-nome-da-acao-da-tela`) com 0 linhas novas em `published_pdfs` e 0 eventos novos; verificação executável: mesmo comando de integração → `0 failed`; mutante que pula a elegibilidade reprova
- [ ] Versão 1 aprovada e Versão 2 fechada e NÃO aprovada: a publicação é recusada com 409 `FINAL_EXPORT_NOT_ELIGIBLE` e `reason` `NO_APPROVED_VERSION` (mesma `reason` da exportação final do mesmo Conteúdo, TASK-065-006), 0 linhas novas em `published_pdfs` e 0 eventos novos; verificação executável: mesmo comando de integração → `0 failed`; mutante que publica a Versão 1 aprovada quando a corrente é a 2 reprova
- [ ] AC-064-023 (parte publicação por chamada direta, sem a tela): o mesmo POST por EDITOR e por ADMIN, em Conteúdo sem Versão aprovada e válida, é recusado com o mesmo `code` e a mesma `reason` que a exportação final do mesmo Conteúdo recusa, um caso por papel; verificação executável: mesmo comando de integração → `0 failed`
- [ ] Precedência por par (lição `rvore-de-decis-o-com-preced-ncia-um-caso-por-par-de-ramos-que-coincide`; o nome do teste enuncia quem vence): Conteúdo removido E sem Versão aprovada → 404 vence; sem Versão aprovada E sem Tira → 409 `FINAL_EXPORT_NOT_ELIGIBLE` vence a recusa de Tira ausente; elegível com PDF acima do teto → 422 `FINAL_PDF_TOO_LARGE`, 0 linhas, 0 eventos (teto baixado por atribuição a `env.PUBLICATION_FINAL_PDF_MAX_BYTES` com restauração no `afterEach`, molde `tests/integration/publication.service.integration.test.ts:481`); verificação executável: mesmo comando de integração → `0 failed`; mutante que inverte a ordem de elegibilidade e teto reprova
- [ ] AC-064-015 (parte: Versão 2 publicada, o registro da Versão 1 inalterado; republicar a MESMA Versão com confirmação é da TASK-065-013): Versão 1 publicada, Versão 2 fechada e aprovada por um segundo ADMIN (pelos serviços `closeContentVersion` e `approveContentVersion`, ou por extensão do `seedApprovedStrip`) e publicada resultam em 2 registros; a linha da Versão 1 lida do banco antes e depois da publicação da Versão 2 é igual campo a campo, e os valores das duas publicações são distintos (`byteSize`, `sha256`, `versionNumber` diferentes), para que reescrita retroativa seja visível (lição `prova-de-escrita-que-nao-reescreve-registro-anterior-usa-valores-distintos`); verificação executável: mesmo comando de integração → `0 failed`; mutante que acrescenta `updateMany` sobre as linhas anteriores logo após o `insert` (em `git worktree add`, nunca na árvore principal) reprova
- [ ] AC-064-019 (parte servidor: a mensagem de falha na tela é da TASK-065-016) e atomicidade de escritas dependentes: falha injetada em `publicationEvent.create` DEPOIS do `insert` (proxy do cliente dentro da `$transaction`, pelo helper `tests/support/failing-transaction-client.ts` da TASK-065-006, sem espionar o cliente raiz) deixa 0 linhas em `published_pdfs` e 0 `ProductionStageEvent` novos, com resposta 500 genérica sem stack nem mensagem do driver; falha na geração (compositor lançando) deixa 0 linhas e 0 eventos; a listagem depois de cada falha segue sem o registro; verificação executável: mesmo comando de integração, arquivo inteiro e nunca `-t`, → `0 failed`; mutante que remove a `$transaction` de `publishFinalPdf` reprova pelo mesmo comando
- [ ] Re-verificação dentro da transação (TRISK-065-006): Versão alterada ENTRE a geração e o `insert` (doublê do módulo `final-pdf-composer` que altera o Conteúdo e chama o compositor real) → 409 `FINAL_EXPORT_NOT_ELIGIBLE` e 0 linhas; controle positivo no mesmo arquivo (sem a alteração a mesma sequência publica 201); verificação executável: mesmo comando de integração → `0 failed`; mutante que remove a re-verificação reprova
- [ ] AC-064-027: duas publicações simultâneas (`Promise.all` de 2 POST) da mesma Versão sem publicação prévia: cada resposta é 201 completo com registro baixável cujo sha256 bate com o dos bytes recebidos, ou 409 com `code`; nunca 500 nem registro parcial; o número de linhas de `published_pdfs` contado no fim é igual ao número de respostas 201 (lição `corrida-toctou-s-se-fecha-com-prova-de-concorr-ncia-real-contando-linhas-no-fim-prova-estrutural-ou-caso-sequencial-nunca-fecha`); `framesTotal` e `framesWithImage` de cada linha são os do PDF daquela publicação; verificação executável: mesmo comando de integração (arquivo inteiro, lição `prova-de-corrida-exclus-o-nasce-na-fronteira-da-invariante-e-o-mutante-roda-pelo-comando-do-crit-rio`) → `0 failed`
- [ ] AC-064-018 (parte publicar): sem sessão → 401 e STUDENT → 403 na app real montada, sem declarar a rota à mão no teste (lição `barreira-que-nega-com-base-num-registro-exige-o-registro-completo-antes-da-1-requisi-o`); `Origin` fora da allowlist → 403 "Origem não permitida." antes de qualquer leitura de Conteúdo; outro método no mesmo caminho (`PUT /contents/:id/publications`) não responde 2xx (lição `declarado-n-o-autorizado-prova-de-gate-de-autz-exige-topologia-adversarial`); verificação executável: mesmo comando de integração → `0 failed`; mutante que remove `requireRole(...)` da rota reprova o caso 403
- [ ] `verifyOrigin` como primeiro handler da rota POST nova (lição `asser-o-estrutural-repo-wide-que-filtra-por-allowlist-de-outro-controle-declara-por-que-a-exce-o-vale-ou-n-o-filtra`, tripwire por método) e censo atualizado: o caso repo-wide de `route-authz-matrix.integration.test.ts` ("toda rota POST/PATCH/PUT/DELETE ... tem verifyOrigin como 1º handler") passa sobre a rota nova, e a lista explícita ganha `'POST /contents/:id/publications'`, com a contagem do título passando de 56 (após a TASK-065-011) para 57 (hoje 53 no worktree, conferido por Grep na fixação); verificação executável: `npm --prefix mnemonicos-backend run test:integration -- tests/integration/route-authz-matrix.integration.test.ts` → `0 failed` e `N passed` (N > 0); mutante que tira `verifyOrigin` da rota reprova o caso repo-wide
- [ ] AC-064-028 (parte publicar): um Conteúdo por sujeito, ambos criados por EDITOR A: EDITOR B publica o Conteúdo X e ADMIN publica o Conteúdo Y (alcance comum, sem restrição por autoria), 201 em ambos, sem colisão com a regra de republicar da TASK-065-013; verificação executável: `npm --prefix mnemonicos-backend run test:integration -- tests/integration/published-pdf.publish.integration.test.ts` → `0 failed`
- [ ] AC-064-029 (parte publicar): Conteúdo removido (soft-delete) → 404 pelo método POST (prova comportamental própria do método novo, lição `guarda-reusada-continua-exigindo-prova-comportamental-pr-pria-por-novo-m-todo-de-escrita`) e a contagem de linhas de `published_pdfs` do Conteúdo, antes e depois, é igual (os registros já publicados seguem gravados); verificação executável: mesmo comando do critério anterior → `0 failed`
- [ ] `orThrow` e DRY (lições `orthrow-so-depois-da-guarda-que-torna-a-ausencia-impossivel` e `corre-o-de-duplica-o-dry-introduz-nova-re-deriva-o-do-can-nico-no-mesmo-diff`): `grep -cE '^[^*/]*publicationEvent\.create' mnemonicos-backend/src/modules/publication/published-pdf.service.ts` → `0` (o evento é escrito só por `recordPdfExportEvents`, importado de `publication.service.ts`); calibração com positivo conhecido: o mesmo `grep -cE` sobre `mnemonicos-backend/src/modules/publication/publication.service.ts` → `N` com N > 0 (o rascunho já grava o evento ali); `git -C mnemonicos-backend diff --name-status --diff-filter=A <commit-pai-da-TASK>..HEAD -- tests/support/` → saída sem linhas (nenhum helper novo de fixture, ancorado no commit-pai da TASK)
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git -C mnemonicos-backend diff --name-only main...HEAD`), produção e teste: `npm --prefix mnemonicos-backend run lint`, `npm --prefix mnemonicos-backend run typecheck` e `npm --prefix mnemonicos-backend run format:check` saem 0

## Riscos específicos

- Gate 8 (publicação grava no banco, atomicidade, concorrência, alcance) e gate 10 (tamanho, tempo e memória do PDF publicado, até 4.000.000 bytes, em tira real).
- A injeção de falha dentro da `$transaction` exige um proxy que embrulhe também o cliente da transação (o molde `tests/support/failing-tira-signal.ts` só intercepta `productionStageEvent.findFirst`); o proxy é o helper `tests/support/failing-transaction-client.ts`, criado pela TASK-065-006 e citado aqui.
- Duas publicações simultâneas da mesma Versão são aceitas por desenho (A-064-005 aceita dois registros); a checagem de "mesma Versão" não serializa e a confirmação de republicar é da TASK-065-013.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
**Jira**: KAN-272

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
