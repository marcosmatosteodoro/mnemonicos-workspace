# TASK-065-013: Exigir no servidor a confirmação de publicar incompleto e de republicar

**Slug**: producao-material
**Pertence a**: PLAN-065
**Realiza (FRs)**: FR-064-019, FR-064-030
**Funcionalidade**: FEAT-064-003 (primária)
**Componente**: COMP-065-010 (principal), COMP-065-011
**Wave**: 8
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-065-012
- **Bloqueia**: TASK-065-016

## Contexto

A publicação (TASK-065-012) passa a recusar, com 409 e nada gravado, a Tira com N < M quadros com imagem sem `acknowledgeIncomplete` e a Versão que já tem PDF publicado sem `acknowledgeRepublish`; as flags são só confirmações do cliente, e N/M são sempre os do PDF efetivamente composto no servidor. Contrato: PLAN-065 COMP-010/COMP-011 e §4 "Publicar"; território em `thoughts/local/sessions/20261018-011631-e87dd9d7/exploration-producao-material.md` e `docs/producao-material/MAP.md`. A tela que usa estes códigos é a TASK-065-016.

**Ambiente de execução**: os comandos rodam na raiz `Mnemonico/kan237/` (contém `mnemonicos-backend/` e `mnemonicos-frontend/`, worktrees da branch do épico, e `docs/`, symlink para o workspace); os paths `mnemonicos-backend/…`, `mnemonicos-frontend/…` e `docs/…` desta TASK resolvem a partir dela, e o teste de paridade (`resolve(__dirname,'../../../mnemonicos-frontend/…')`) alcança o frontend certo. Integração backend: antes, `source env-kan237.sh` (exporta `TEST_DATABASE_URL` para o Postgres dedicado em 127.0.0.1:5433 e `KAN237_DB_CONTAINER`); nunca aceitar reset em banco compartilhado. Pré-condição de exclusividade do banco: `docker exec "${KAN237_DB_CONTAINER:-mnemonicos-db}" psql -U postgres -d postgres -tAc "SELECT count(*) FROM pg_stat_activity WHERE datname = 'mnemonicos_test' AND pid <> pg_backend_pid()"` → `0`.

## Escopo

### Inclui
- `mnemonicos-backend/src/modules/publication/published-pdf.schema.ts` (novo): `publishFinalPdfBodySchema` (`z.object({ acknowledgeIncomplete: z.boolean().default(false), acknowledgeRepublish: z.boolean().default(false) }).strict()`); a flag só vale se for o booleano `true` (nada de coerção de string/número). Zod 4: `.strict()` rejeita chave extra (`mnemonicos-backend/package.json` declara `zod ^4.4.3`; os schemas vizinhos usam `z.object` sem `.strict()`, que descarta chave extra em silêncio — daí o `.strict()` explícito).
- `mnemonicos-backend/src/modules/publication/published-pdf.service.ts`: em `publishFinalPdf`, depois de compor o PDF (cobertura lida de `FinalPdfResult.coverage`, sem nenhuma recontagem própria) e antes de gravar: (1) `framesWithImage < framesTotal` e `acknowledgeIncomplete !== true` → `IncompleteCoverageAckRequiredError`; (2) a mesma Versão do mesmo Conteúdo já tem publicação (`findLatestForVersion`, TASK-065-004) e `acknowledgeRepublish !== true` → `RepublishAckRequiredError`. Precedência: (1) vence (2) quando faltam as duas. Nenhuma das duas recusas grava `published_pdfs`, `ProductionStageEvent` nem `PublicationEvent`.
- `mnemonicos-backend/src/modules/publication/published-pdf.routes.ts`: na rota `POST /contents/:id/publications`, `publishFinalPdfBodySchema.parse(req.body ?? {})` depois de `verifyOrigin` e `requireRole` (a ordem de guardas da 012 não muda); sem corpo e com `{}` valem igual (Express 5 não inicializa `req.body` quando não há corpo; `express.json` em `mnemonicos-backend/src/app.ts:62`). Repassa as duas flags ao serviço.
- `mnemonicos-backend/src/http/errors.ts`: `IncompleteCoverageAckRequiredError` e `RepublishAckRequiredError`, ambas estendendo `AppError(message, statusCode, code, details)` (`errors.ts:8`) com 409 e `details`; `ConflictError` (`errors.ts:41-45`) fixa o code `CONFLICT` e `UnprocessableEntityError` (`errors.ts:48-52`) não aceita `details`, por isso nenhuma serve. O `error-handler` já repassa `code` e `details` (`mnemonicos-backend/src/http/middlewares/error-handler.ts:64-80`).
- `mnemonicos-backend/src/domain/types.ts`: os dois códigos em `PUBLICATION_FINAL_ERROR_CODES` (objeto const criado na TASK-065-006 e ampliado na 007): `INCOMPLETE_COVERAGE_ACK_REQUIRED` e `REPUBLISH_ACK_REQUIRED`; as classes novas usam a constante, nunca a grafia solta.
- `mnemonicos-frontend/src/types/domain.ts`: espelho dos dois códigos e dos `details` tipados (`{ framesTotal, framesWithImage, warnings }` e `{ versionNumber, lastPublishedAt }`), no mesmo diff.
- `mnemonicos-backend/tests/integration/published-pdf.confirmations.integration.test.ts` (novo; molde de sessão/POST/fixtures: `tests/integration/published-pdf.publish.integration.test.ts` da 012; fixtures: `seedApprovedStrip` da 006, `seedPublishedPdf` da 004, `buildValidPng1x1` de `tests/support/png-fixtures.ts:42` e `pngHeaderWithDimensions` de `tests/support/png-fixtures.ts:65` para o Quadro com imagem que não entra).
- `mnemonicos-backend/tests/unit/published-pdf.schema.test.ts` (novo).
- `mnemonicos-backend/tests/unit/published-pdf-frontend-contract.test.ts` (EDIÇÃO: a 011 o criou para `PublicationListItem`; aqui acrescenta os dois códigos e os `details`, lendo as duas fontes).

### Não inclui
- A tela de confirmação e o diálogo: TASK-065-016.
- Serializar publicações concorrentes: a checagem "mesma Versão" não é atômica por desenho (A-064-005 aceita dois registros), e o teste de concorrência da 012 segue valendo como está.
- Editar testes ou comportamento da 012 além do exigido: a 012 não afirma nada sobre republicar sem flag, então nenhum teste dela deve reprovar; se algum reprovar, o developer relata (o arquivo da 012 não está neste Inclui) e não o edita.
- Mudar a conta de N/M (vem de `FinalPdfResult.coverage`, TASK-065-006/007) ou o teto de tamanho (007/012).
- Atualizar `docs/GUIA-DE-USO.md`: TASK-065-017.

## Critérios de pronto

- [ ] Schema do corpo (FR-064-019, FR-064-030; sem AC próprio, contrato do item) — `npm --prefix mnemonicos-backend test -- tests/unit/published-pdf.schema.test.ts` → `OK (N tests)`, com um caso por eixo (L-conjunto): `{}` e corpo ausente → as duas flags `false`; `{ acknowledgeIncomplete: true }`, `{ acknowledgeRepublish: true }` e as duas `true` → valores exatos; `"true"`, `1` e `null` em cada flag → `ZodError`; chave extra (`framesWithImage: 99`, `framesTotal: 3`, `pdfData`) → `ZodError` por `unrecognized_keys`. Mutantes em `git worktree add`, pelo mesmo comando: remover `.strict()` → vermelho no caso da chave extra; trocar `z.boolean()` por `z.coerce.boolean()` → vermelho nos casos `"true"` e `1`.
- [ ] N/M são os do servidor, nunca do cliente — `npm --prefix mnemonicos-backend run test:integration -- tests/integration/published-pdf.confirmations.integration.test.ts` → `OK (N tests)`: `POST` com `{ framesWithImage: 99, framesTotal: 99 }` responde 422 `VALIDATION_ERROR` (o `ZodError` vira 422, não 400: `mnemonicos-backend/src/http/middlewares/error-handler.ts:26-38`) e grava 0 linhas; com corpo válido, a linha gravada de uma Tira de 3 Quadros (1 com PNG que entra, 1 sem imagem, 1 com PNG sem dados de imagem) tem `framesTotal` 3 e `framesWithImage` 1, e `framesWithImage` é igual ao número de XObjects de imagem do PDF gravado (contagem pelo mesmo método de `tests/integration/publication.final-images.integration.test.ts`, TASK-065-007). Flag `"true"` (string) → 422 `VALIDATION_ERROR` e 0 linhas.
- [ ] AC-064-026 (parte servidor; a tela é da TASK-065-016) — mesmo comando do critério anterior → `OK (N tests)`: Tira com N < M (3 Quadros: Quadro 1 com PNG válido, Quadro 2 sem imagem, Quadro 3 com PNG sem dados de imagem) e `POST` sem `acknowledgeIncomplete` → 409 com `code` igual a `PUBLICATION_FINAL_ERROR_CODES.INCOMPLETE_COVERAGE_ACK_REQUIRED` e `details` com chaves exatas `['framesTotal', 'framesWithImage', 'warnings']` (L-select) de valores `3`, `1` e `[{ position: 2, kind: 'MISSING_IMAGE' }, { position: 3, kind: 'IMAGE_NOT_EMBEDDABLE' }]` (cada aviso com chaves exatas `['kind', 'position']`). Com a recusa: contagens de `published_pdfs`, de `ProductionStageEvent` do tipo `PUBLICACAO_PDF` e de `PublicationEvent` iguais antes e depois.
- [ ] AC-064-026, matriz por eixo (L-conjunto, uma prova por condição da cadeia) — mesmo comando → `OK (N tests)`, nomes de teste que enunciam o eixo: N<M × sem flag → 409; N<M × `acknowledgeIncomplete: true` → 201 com a linha gravada com 1 de 3; N=M × sem flag → 201 (publica sem confirmação); N=M × `acknowledgeIncomplete: true` → 201 (a flag é inofensiva). Mutantes em worktree, pelo comando do critério (arquivo inteiro, nunca `-t`): remover a comparação `framesWithImage < framesTotal` → vermelho no caso N<M × sem flag; remover a leitura da flag → vermelho no caso N<M × sem flag (sempre publica) ou N=M (sempre recusa), conforme a forma do mutante; inverter a comparação → vermelho nos casos N=M.
- [ ] AC-064-015 (parte servidor; V1/V2 é da 012 e a tela é da 016) — mesmo comando → `OK (N tests)` (fixtures de republicar com Tira N=M: todos os Quadros com PNG válido, de modo que só a flag de republicar decide): Versão 1 já publicada (semeada por `seedPublishedPdf` com `publishedAt` fixo `2026-03-04T05:06:07.000Z`, sem ler o relógio) e `POST` sem `acknowledgeRepublish` → 409 com `code` igual a `PUBLICATION_FINAL_ERROR_CODES.REPUBLISH_ACK_REQUIRED` e `details` de chaves exatas `['lastPublishedAt', 'versionNumber']` de valores `'2026-03-04T05:06:07.000Z'` e `1`; nada gravado (mesmas três contagens). Com `acknowledgeRepublish: true` → 201: existem 2 registros da MESMA Versão, o registro anterior permanece com `id`, `sha256`, `byteSize`, `publishedAt` e `pdfData` idênticos aos de antes (valores distintos entre os dois registros: lição `prova-de-escrita-que-nao-reescreve-registro-anterior-usa-valores-distintos`), ambos baixam byte a byte o que foi gravado pela rota de download da TASK-065-011, e a lista (011) marca `current: true` só no mais recente.
- [ ] AC-064-015, o que é "mesma Versão" (L-conjunto: dois eixos) — mesmo comando → `OK (N tests)`: (fixtures com Tira N=M — todos os Quadros com PNG válido — nos casos (a) e (b)) (a) o Conteúdo tem a Versão 1 publicada e a Versão 2 aprovada e válida: `POST` sem flag → 201 (outra Versão não é republicação); (b) outro Conteúdo tem publicação da sua Versão 1 e este Conteúdo não tem nenhuma: `POST` sem flag → 201 (publicação de outro Conteúdo não conta). Mutante em worktree: o predicado de "já publicada" deixar de comparar a Versão (ou o Conteúdo) → vermelho no caso (a) (ou (b)).
- [ ] Precedência, um caso por par de ramos (L-precedencia, o nome do teste enuncia quem vence) — mesmo comando → `OK (N tests)`: Tira N<M ∧ Versão já publicada, sem nenhuma flag → `INCOMPLETE_COVERAGE_ACK_REQUIRED` vence `REPUBLISH_ACK_REQUIRED`; só `acknowledgeIncomplete: true` → `REPUBLISH_ACK_REQUIRED`; só `acknowledgeRepublish: true` → `INCOMPLETE_COVERAGE_ACK_REQUIRED`; as duas → 201. Conteúdo removido ∧ sem flags → 404 (o 404 de `assertRawContentExportable` vence as duas confirmações). Mutante em worktree: inverter a ordem das duas checagens → vermelho no teste "faltando as duas".
- [ ] `*OrThrow` só depois da guarda (lição `orthrow-so-depois-da-guarda-que-torna-a-ausencia-impossivel`) — mesmo comando → `OK (N tests)`: Conteúdo removido (soft delete) e Conteúdo sem Versão aprovada recusam com 404 e 409 `FINAL_EXPORT_NOT_ELIGIBLE` previstos (nunca 500 genérico), com e sem flags; o caso previsto "Versão inexistente" usa `find*` + `AppError`, não `*OrThrow`.
- [ ] Ordem das guardas inalterada — mesmo comando → `OK (N tests)`: sem sessão com corpo inválido → 401; STUDENT com corpo inválido (`{ framesWithImage: 99 }`) → 403 (a guarda de papel vem antes do schema); EDITOR com corpo inválido → 422. Mutante em worktree: mover o `parse` do corpo para antes de `requireRole` → vermelho no caso STUDENT.
- [ ] Mensagens de recusa dizem o próximo passo com o nome da ação da tela (lição `mensagem-de-recusa-recuperavel-diz-o-proximo-passo-com-o-nome-da-acao-da-tela`) e os `details` são seguros — mesmo comando → `OK (N tests)`: a `message` de cada 409 contém `Publicar PDF final`, diz o que fazer ("confirme" a publicação com quadros sem imagem / "confirme" que quer publicar outro PDF desta versão) e não contém `acknowledge`, ids nem termos técnicos; `details` sem `pdfData`, sem id de usuário e sem caminho.
- [ ] Classes e códigos (L-dry, nome por constante) — `npm --prefix mnemonicos-backend run typecheck` → saída 0, e `npm --prefix mnemonicos-backend run test:integration -- tests/integration/published-pdf.confirmations.integration.test.ts` → `OK (N tests)` asserta `error.code` com `PUBLICATION_FINAL_ERROR_CODES.<NOME>` importado de `src/domain/types.ts` (nenhuma grafia solta nos testes novos).
- [ ] Paridade com o frontend (L-paridade, o teste lê as duas fontes) — `npm --prefix mnemonicos-backend test -- tests/unit/published-pdf-frontend-contract.test.ts` → `OK (N tests)`: os dois códigos têm o mesmo valor em `mnemonicos-backend/src/domain/types.ts` e `mnemonicos-frontend/src/types/domain.ts`, e os `details` têm os mesmos nomes de campo nas duas fontes; falha alto se o arquivo do outro repositório não existir (molde: `tests/unit/domain-types-parity.test.ts`). Mutante em worktree: renomear um código só no frontend → vermelho.
- [ ] Não regressão da 012 — `npm --prefix mnemonicos-backend run test:integration -- tests/integration/published-pdf.publish.integration.test.ts` → mesmo `OK (N tests)` da baseline capturada antes de começar (nenhum teste da 012 editado ou removido: `git -C mnemonicos-backend diff <commit-pai>..HEAD -- tests/integration/published-pdf.publish.integration.test.ts` → saída vazia).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff, produção e teste — `npm --prefix mnemonicos-backend run lint`, `npm --prefix mnemonicos-backend run typecheck`, `npm --prefix mnemonicos-backend run format:check`, `npm --prefix mnemonicos-frontend run typecheck` e `npm --prefix mnemonicos-frontend run lint` → saída 0 nos cinco.

## Riscos específicos

- Rota nova de gravação com decisão no servidor (gate 8): o ponto é o cliente ser não confiável. As flags são confirmações, nunca números; o teste do corpo com `framesWithImage: 99` e o da flag em string são a prova.
- A checagem "já publicada" e a gravação não são atômicas entre si (A-064-005): duas republicações simultâneas da mesma Versão ainda podem gravar dois registros. É o comportamento aceito, não um defeito a "consertar" aqui.
- `tests/support/final-export-fixtures.ts` (006) e `tests/support/published-pdf-fixtures.ts` (004) são os únicos criadores de fixture; se faltar um parâmetro (por exemplo `publishedAt` fixo em `seedPublishedPdf`), o developer o acrescenta no arquivo dono, nunca num helper novo ao lado (lição `corre-o-de-duplica-o-dry-introduz-nova-re-deriva-o-do-can-nico-no-mesmo-diff`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
**Jira**: KAN-273

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
