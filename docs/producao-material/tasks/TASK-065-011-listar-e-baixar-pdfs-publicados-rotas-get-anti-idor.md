# TASK-065-011: Listar e baixar PDFs publicados (rotas GET, anti-IDOR)

**Slug**: producao-material
**Pertence a**: PLAN-065
**Realiza (FRs)**: FR-064-020, FR-064-021, FR-064-023, FR-064-032, FR-064-033
**Funcionalidade**: FEAT-064-003 (primária)
**Componente**: COMP-065-011 (principal), COMP-065-010
**Wave**: 6
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: TASK-065-004, TASK-065-009, TASK-065-010
- **Bloqueia**: TASK-065-012, TASK-065-014, TASK-065-015

## Contexto

EDITOR e ADMIN passam a ler o histórico de PDFs publicados de um Conteúdo (do mais recente ao mais antigo, com a marca "atual") e a baixar o arquivo exatamente como foi gravado, sem regerar. As duas rotas `GET` nascem aqui sobre os registros que a TASK-065-004 guarda; publicar é da TASK-065-012. O preview ganha a publicação mais recente da Versão corrente. Território: memo de exploração e MAP do slug; A-064-005 e DEC-065-012 no PLAN-065.

Ambiente de execução: os comandos rodam a partir da raiz `Mnemonico/kan237/` (contém `mnemonicos-backend/` e `mnemonicos-frontend/`, worktrees da branch do épico, e `docs/`, symlink para o workspace); os testes de paridade resolvem `../../../mnemonicos-frontend/…` a partir dela. Antes da suíte de integração: `source env-kan237.sh` (exporta `TEST_DATABASE_URL`, Postgres dedicado 127.0.0.1:5433, e `KAN237_DB_CONTAINER`); nunca aceitar reset em banco compartilhado. Exclusividade do banco: `docker exec "${KAN237_DB_CONTAINER:-mnemonicos-db}" psql -U postgres -d postgres -tAc "SELECT count(*) FROM pg_stat_activity WHERE datname = 'mnemonicos_test' AND pid <> pg_backend_pid()"` → `0`.

## Escopo

### Inclui
- mnemonicos-backend/src/modules/publication/published-pdf.service.ts (novo): `listPublications(rawContentId, db = prisma)` (cliente injetável — a prova de round-trips usa `withQueryProbe`), `getPublicationPdf` e `PublicationListItem`; leitura sempre pelo `PublishedPdfStore` (TASK-065-004), com `rawContentId` em toda leitura por id; Conteúdo removido => `NotFoundError`.
- mnemonicos-backend/src/modules/publication/published-pdf.routes.ts (novo): `GET /contents/:id/publications` e `GET /contents/:id/publications/:publicationId/pdf` (`Content-Type: application/pdf`, `Content-Disposition` de anexo com o nome `${id}-TIRA-v${N}-final.pdf`, `ETag` igual ao sha256 entre aspas, `Cache-Control: private`; params UUID; sem `verifyOrigin`, por serem leituras; `requireRole` EDITOR/ADMIN).
- mnemonicos-backend/src/http/routes.ts: registro das rotas novas (a rota `POST /contents/:id/publications` é da TASK-065-012).
- mnemonicos-backend/src/modules/publication/publication.service.ts: `getFinalPreview` ganha `latestPublication` (via `findLatestForVersion(rawContentId, versionNumber, db = prisma)`, que devolve `{ id, publishedAt, versionNumber } | null`, da Versão corrente).
- Testes: mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts (censo de rotas), mnemonicos-backend/tests/integration/published-pdf.routes.integration.test.ts (novo; semeia por `seedPublishedPdf` da TASK-065-004), mnemonicos-backend/tests/unit/published-pdf-frontend-contract.test.ts (novo), mnemonicos-backend/tests/unit/publication-final-frontend-contract.test.ts (edição declarada: o contrato do preview passa a cobrir `latestPublication` nas duas fontes; decisão D12).
- mnemonicos-frontend/src/types/domain.ts: espelho de `PublicationListItem` e de `latestPublication` em `FinalPreview` (campo que a TASK-065-009 deixou de fora), no mesmo diff.
- (retry do gate 7 da wave 6) mnemonicos-backend/src/modules/publication/publication.schema.ts: recebe o schema de params `{ id, publicationId }` das rotas novas (sai de `published-pdf.routes.ts`).
- (retry do gate 7 da wave 6, só tipo) mnemonicos-backend/src/modules/publication/published-pdf.store.ts: `StoreClient` passa a `Pick<PrismaClient, 'publishedPdf'>`; nenhuma consulta muda.

### Não inclui
- Publicar (TASK-065-012), confirmações de cobertura incompleta e de republicar (TASK-065-013), UI (TASK-065-015, TASK-065-016).
- Revalidação condicional 304: comportamento do Express, bytes inalterados.
- Compor ou regerar PDF em qualquer download.
- Medição de custo (tempo, memória) da listagem e do download em tira real: gate 10; aqui só a contagem de round-trips, por `db` injetável.

## Critérios de pronto

- [ ] AC-064-016 (inteiro na API): `GET /contents/:id/publications` devolve os registros do mais recente ao mais antigo, cada item com Versão, data, autor, N e M e `current`; `Object.keys(item).sort()` igual a `['byteSize', 'current', 'framesTotal', 'framesWithImage', 'id', 'publishedAt', 'publishedBy', 'versionNumber']` e `publishedBy` com chaves `['id', 'name']`, sem `pdfData` (lição `select-exposto-que-le-campo-interno-prova-as-chaves-do-payload`); Conteúdo sem publicação responde 200 com `[]`; verificação executável: `npm --prefix mnemonicos-backend run test:integration -- tests/integration/published-pdf.routes.integration.test.ts` → `0 failed` e `N passed` (N > 0); mutante que serializa o registro inteiro do store (`{ ...record }`) reprova pelas chaves
- [ ] `current` por regra, um teste por regra (lição `rvore-de-decis-o-com-preced-ncia-um-caso-por-par-de-ramos-que-coincide`; o nome do teste enuncia quem vence): `current` é o registro de maior `publishedAt`; dois registros com o MESMO `publishedAt` desempatam por maior `id` (ids explícitos no fixture, `publishedAt` igual); exatamente 1 item com `current: true`; verificação executável: mesmo comando de integração → `0 failed`; mutante que troca o desempate por menor `id` reprova
- [ ] AC-064-013 (parte: download byte a byte igual ao gravado e ETag igual ao sha256; a publicação é da TASK-065-012): o corpo de `GET /contents/:id/publications/:publicationId/pdf` é idêntico ao `pdfData` semeado (fixture com bytes que incluem `0x00` e `0xFF`, para que recodificação de texto reprove), dois downloads seguidos são idênticos entre si, e `ETag` é `"<sha256>"` recalculado pelo teste a partir do corpo recebido (não copiado do fixture); `Content-Type` `application/pdf`, `Cache-Control` `private` e `Content-Disposition` com `attachment` e o nome `${rawContentId}-TIRA-v${versionNumber}-final.pdf` do REGISTRO baixado (um registro da Versão 1 baixado quando a Versão 2 é a corrente sai com `-v1-`); verificação executável: mesmo comando de integração → `0 failed`; mutante que regera o PDF em vez de devolver `pdfData` reprova
- [ ] AC-064-018 (parte listar e baixar): sem sessão → 401 e STUDENT → 403 nas duas rotas, na app real montada sem declarar a rota à mão no teste (lição `barreira-que-nega-com-base-num-registro-exige-o-registro-completo-antes-da-1-requisi-o`); verificação executável: mesmo comando de integração → `0 failed`; mutante que remove `requireRole(...)` de cada rota (um por rota) reprova o caso 403 daquela rota
- [ ] AC-064-028 (parte listar e baixar): EDITOR B e ADMIN listam e baixam o registro de Conteúdo criado por EDITOR A (alcance comum, sem restrição por autoria), com `200` e mesmos bytes; verificação executável: mesmo comando de integração → `0 failed`
- [ ] AC-064-029 (parte listar e baixar): Conteúdo removido (soft-delete) → 404 em cada rota, verificado por método (lição `guarda-reusada-continua-exigindo-prova-comportamental-pr-pria-por-novo-m-todo-de-escrita`: prova comportamental própria para cada rota nova, mesmo com a guarda reusada), e a contagem de linhas de `published_pdfs` antes e depois é igual; verificação executável: mesmo comando de integração → `0 failed`
- [ ] Anti-IDOR discriminante: `publicationId` existente de OUTRO Conteúdo responde 404 com corpo idêntico (`toEqual`) ao de `publicationId` inexistente (nunca 403, nunca 200); `rawContentId` ou `publicationId` que não é UUID responde 422 `VALIDATION_ERROR` (erro de validação Zod, `error-handler.ts`, não 400); id inexistente responde 404 e não 500 (lição `orthrow-so-depois-da-guarda-que-torna-a-ausencia-impossivel`); a mensagem de 404 diz o próximo passo e não cita id ("PDF publicado não encontrado. Atualize a lista e tente de novo.", lição `mensagem-de-recusa-recuperavel-diz-o-proximo-passo-com-o-nome-da-acao-da-tela`); verificação executável: mesmo comando de integração → `0 failed`; mutante que remove o predicado `rawContentId` da leitura por id no store (em `git worktree add`, nunca na árvore principal) reprova o caso de outro Conteúdo
- [ ] Round-trips da listagem (lição `include-select-aninhado-de-rela-o-n-o-1-statement-por-padr-o`): `listPublications` chamada com o `db` injetável instrumentado por `withQueryProbe` (`tests/support/query-probe.ts`) executa um número fixo de statements, igual para 1 e para 5 registros publicados (sem N+1), valor literal registrado no baseline; verificação executável: `npm --prefix mnemonicos-backend run test:integration -- tests/integration/published-pdf.routes.integration.test.ts` → `0 failed` e `N passed` (N > 0); mutante que busca o autor em laço por registro reprova a igualdade entre 1 e 5
- [ ] Topologia adversarial (lição `declarado-n-o-autorizado-prova-de-gate-de-autz-exige-topologia-adversarial`): na app real, outro método no mesmo caminho (`DELETE /contents/:id/publications/:publicationId/pdf` e `PATCH /contents/:id/publications`) não responde 2xx e não altera nenhuma linha de `published_pdfs`; a rota estática `GET /contents/:id/publications` não é capturada pela rota com `:publicationId`; verificação executável: mesmo comando de integração → `0 failed`
- [ ] GET sem `verifyOrigin` é intencional (lição `asser-o-estrutural-repo-wide-que-filtra-por-allowlist-de-outro-controle-declara-por-que-a-exce-o-vale-ou-n-o-filtra`, tripwire por método): as duas rotas respondem 200 com sessão EDITOR sem cabeçalho `Origin`, e o censo de `verifyOrigin` por método do `route-authz-matrix` segue exigindo `handlers[0] === verifyOrigin` apenas para os métodos que mutam estado; verificação executável: `npm --prefix mnemonicos-backend run test:integration -- tests/integration/route-authz-matrix.integration.test.ts` → `0 failed` e `N passed` (N > 0)
- [ ] Tripwire do censo atualizado e wiring provado (lição `asser-o-de-invariante-executada-na-carga-do-m-dulo-exige-dois-testes-fun-o-wiring`): a lista explícita de `route-authz-matrix.integration.test.ts` ganha `'GET /contents/:id/publications'` e `'GET /contents/:id/publications/:publicationId/pdf'`, a contagem do título passa de 54 (após a TASK-065-009; a TASK-065-010 não muda o censo) para 56 (conferido por Grep na fixação: hoje 53 no worktree); verificação executável: mesmo comando do critério anterior → `0 failed`; mutante que remove o registro das rotas em `src/http/routes.ts` reprova o censo e o teste de rota
- [ ] Preview com a publicação da Versão corrente: `getFinalPreview` devolve `latestPublication` com chaves exatas `['id', 'publishedAt', 'versionNumber']` quando a Versão corrente tem publicação, e omite a chave quando só uma Versão anterior foi publicada (par discriminante: Versão 1 publicada e Versão 2 corrente sem publicação; mutante que retira o filtro por Versão no `findLatestForVersion` reprova); os casos novos moram em `published-pdf.routes.integration.test.ts` (o arquivo de preview da TASK-065-009 não é editado aqui); verificação executável: `npm --prefix mnemonicos-backend run test:integration -- tests/integration/published-pdf.routes.integration.test.ts` (arquivo inteiro, nunca `-t`, lição `prova-de-corrida-exclus-o-nasce-na-fronteira-da-invariante-e-o-mutante-roda-pelo-comando-do-crit-rio`) → `0 failed` e `N passed` com os casos de `latestPublication` nomeados, e `npm --prefix mnemonicos-backend run test:integration -- tests/integration/publication.final-preview.integration.test.ts` → `0 failed`, com N igual ao do baseline (não-regressão das chaves exatas do preview sem publicação)
- [ ] Paridade backend × frontend (lição `coment-rio-que-afirma-paridade-entre-os-dois-repos-s-vale-se-o-teste-ler-as-duas-fontes`): `tests/unit/published-pdf-frontend-contract.test.ts` lê as duas fontes como texto, lança se o arquivo do frontend não existir, compara por campo o texto de tipo normalizado de `PublicationListItem` (incluindo `publishedBy`) e confere `latestPublication` em `FinalPreview` nos dois lados; controle positivo do extrator (acha `PublicationListItem`, campos não vazios) e negativo (interface inexistente lança); a cópia local de `extractInterfaceFields` segue a decisão registrada na TASK-065-009 (duplicar, convenção do repo); verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/published-pdf-frontend-contract.test.ts` → `0 failed` e `N passed` (N > 0); mutante que renomeia `byteSize` em `mnemonicos-frontend/src/types/domain.ts` (worktree do frontend) reprova; `npm --prefix mnemonicos-backend test -- tests/unit/publication-final-frontend-contract.test.ts` → `0 failed` (a paridade da TASK-065-009 segue verde com `latestPublication` nos dois lados)
- [ ] Espelho no frontend compila: `npm --prefix mnemonicos-frontend run typecheck` → saída 0
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git -C mnemonicos-backend diff --name-only main...HEAD` e `git -C mnemonicos-frontend diff --name-only main...HEAD`), produção e teste: `npm --prefix mnemonicos-backend run lint`, `npm --prefix mnemonicos-backend run typecheck` e `npm --prefix mnemonicos-backend run format:check` saem 0; `npm --prefix mnemonicos-frontend run lint` e `npm --prefix mnemonicos-frontend run format:check` saem 0

- [ ] Exigências do gate 8 da wave 1 para as rotas de leitura (pendência herdada): (a) sessão ausente → 401 e papel sem direito (STUDENT) → 403 nas duas rotas GET; (b) Conteúdo removido (soft-delete) → 404 nas duas, e o binário não é servido; (c) download com `Content-Type` literal `application/pdf` (asserção de igualdade, não `toMatch`) e `Content-Disposition: attachment`; verificação executável: comando de integração desta TASK → `0 failed`; mutante que remove a checagem de remoção na leitura deixa (b) vermelho.
- [ ] Todo campo que o serviço MAPEIA (não copia) tem asserção de VALOR na saída integrada (pendência herdada, lição `campo-mapeado-pelo-servico-tem-assercao-na-saida-integrada`, wave 3 desta sessão): na resposta de `GET /contents/:id/publications`, `publishedBy.id` e `publishedBy.name` são iguais aos do usuário semeado como publicador (dois publicadores distintos no fixture, cada item com o seu), `framesTotal`/`framesWithImage`/`byteSize`/`versionNumber` iguais aos do registro semeado (valores distintos entre registros) e `publishedAt` igual ao ISO do registro; verificação executável: comando de integração desta TASK → `0 failed`; mutante que mapeia `publishedBy.name` a partir de outro campo (ex.: `email`) e mutante que troca `framesWithImage` por `framesTotal` reprovam (2 mutantes, 2 vermelhos).

- [ ] (retry R1, gates 5/6 da wave 6) Schema fora da rota (DEC-065-011, guidelines/project/backend/README.md "Camadas"): o schema de params das duas rotas vive em `src/modules/publication/publication.schema.ts`, derivado de `rawContentIdParamSchema` por `.extend({ publicationId: z.uuid('Identificador de PDF publicado inválido.') })` (node-22 §9), e `published-pdf.routes.ts` não importa `zod`; verificação executável: `grep -c "from 'zod'" mnemonicos-backend/src/modules/publication/published-pdf.routes.ts` → `0` (controle positivo: o mesmo grep no commit 6fbef62 → `1`) e `grep -lE "from 'zod'" mnemonicos-backend/src/modules/*/*.routes.ts` → vazio; os 3 casos 422 de `published-pdf.routes.integration.test.ts` seguem verdes (`0 failed`).
- [ ] (retry R2, gate 6 da wave 6) Sem cast entre tipos de cliente Prisma (node-22 §1; lição `porta-que-le-um-delegate-tipa-o-cliente-como-pick-do-delegate`): `StoreClient` em `published-pdf.store.ts` é `Pick<PrismaClient, 'publishedPdf'>`, `publication.service.ts` passa `db` direto ao store, `StoreReadClient` e o comentário do workaround somem, e imports que ficarem sem uso saem; verificação executável: `grep -nE "as (StoreReadClient|PrismaClient|PrismaTx)\b|StoreReadClient" mnemonicos-backend/src/modules/publication/*.ts` → vazio (controle positivo no commit 6fbef62 → ≥ 2 linhas) e `npm --prefix mnemonicos-backend run typecheck` → saída 0; suítes do store e das rotas → `0 failed`.
- [ ] (retry, carona do gate 8/7 da wave 6) Escopo por Conteúdo provado na ponta integrada: em `published-pdf.routes.integration.test.ts`, um caso com 2 Conteúdos X e Y, ambos com a Versão 1 publicada (registros distintos): o `latestPublication` do preview de X tem o `id` do registro de X, e `GET /contents/X/publications` não contém o `id` do registro de Y; verificação executável: comando de integração desta TASK (arquivo inteiro) → `0 failed`; mutante (em worktree) que tira `rawContentId` do `where` de `findLatestForVersion` reprova esse caso, e mutante que tira `rawContentId` do `where` do `list` também reprova (2 mutantes, 2 vermelhos NESTE arquivo, não só na suíte do store).
- [ ] (retry, régua do mutante de autorização) A prova "mutante que remove `requireRole` reprova o caso 403" é cumprida pelo mutante que AMPLIA os papéis (`'STUDENT'` acrescentado ao `requireRole` de cada rota, um por rota): remover a guarda morre no boot (`assertDenyByDefault`) e não executa o caso; verificação executável: os 2 mutantes de ampliação, em worktree, deixam vermelho o caso 403 da própria rota em `published-pdf.routes.integration.test.ts`.

## Riscos específicos

- Gate 8 (IDOR: leitura por id sem escopo de Conteúdo) e gate 10 (o download carrega o PDF inteiro, até 4.000.000 bytes, em memória por requisição).
- O desempate por `id` exige que `seedPublishedPdf` (TASK-065-004) aceite `id` e `publishedAt` explícitos; helper local novo é proibido (lição `corre-o-de-duplica-o-dry-introduz-nova-re-deriva-o-do-can-nico-no-mesmo-diff`).
- `findLatestForVersion` na interface do PLAN devolve só `{ publishedAt }`, e `latestPublication` precisa também de `id`: a TASK-065-004 devolve `{ id, publishedAt, versionNumber } | null` e aceita cliente raiz ou `tx` (decisão D1); o preview a chama sem transação.
- Overlap de `mnemonicos-frontend/src/types/domain.ts` com a TASK-065-010 (decisão D18): resolvido pela dependência desta TASK em 010 (waves distintas, append em regiões distintas). O `list` do store aceita `db` opcional, o que permite a sonda de queries.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-10-18T21:29:53-0300
**Data conclusão**: 2026-10-18T22:27:53-0300
**Commit SHA**: c140131 (backend) · e439900 (frontend)
**Jira**: KAN-271

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 6, 0 achados)
- [x] Comportamento (gate 9): consolidado (FEAT-064-003)
<!-- Branch, tentativas, arquivos, revisores e narrativa (retries, escalações) vivem no
ledger da sessão e no commit da closure (4.76) — não se repetem aqui (4.409). -->
