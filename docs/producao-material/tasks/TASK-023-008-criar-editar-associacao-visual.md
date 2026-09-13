# TASK-023-008: Criar e editar associação visual (upload, CRUD write in-place, guarda de escrita)

**Slug**: producao-material
**Pertence a**: PLAN-023
**Realiza (FRs)**: FR-022-001, FR-022-002, FR-022-003, FR-022-004, FR-022-006, FR-022-009, FR-022-023
**Funcionalidade**: FEAT-022-001 (primária), FEAT-022-003
**Componente**: COMP-023-005 (principal), COMP-023-006, COMP-023-017
**Wave**: 3
**Fatia sensível (princípio 8)**: security-engineer focado (upload + assinatura de bytes + guarda de autoria)
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch do EPICO MNEMORA STUDIO, Estrategia unica -- decisao 4.126: F5 e uma fatia do epico, nunca abre branch propria; a sessao ja fez o sync de largada nela)

**Padrão de commit**: Conventional Commits (`commit.convention: "conventional"`) — `feat:`.
**Framework de teste**: Jest 30 + ts-jest + `supertest` — `tests/integration/*.integration.test.ts` (Postgres real, `jest.integration.config.ts`, `--runInBand`) para o transporte HTTP e a regra de negócio; `tests/unit/*.test.ts` (Jest padrão) para a prova estrutural de ordem de guarda.

## Dependências

- **Depende de**: TASK-023-001, TASK-023-002, TASK-023-003, TASK-023-006
- **Bloqueia**: TASK-023-010, TASK-023-011, TASK-023-014, TASK-023-017

## Contexto

Primeira fatia de ESCRITA do acervo `visual-associations`: cria `createVisualAssociation`/
`updateVisualAssociation` em `visual-associations.service.ts` e a guarda
`assertVisualAssociationWritable` (DEC-023-006, nasce aqui — chamada só por
`updateVisualAssociation` nesta TASK; `removeVisualAssociation`, TASK-023-010, é a 2ª
chamadora). Estende `visual-associations.routes.ts` (base de TASK-023-006) com `POST`/
`PATCH` sob `multer` (`memoryStorage()`, DEC-023-003 — nunca `diskStorage()`, porque o
service só persiste depois de `detectImageSignature` confirmar o formato). Fatia sensível:
upload é superfície greenfield nos dois repos (nenhuma dependência de multipart hoje), e a
EMENDA em `error-handler.ts` (COMP-023-017) mapeia o estouro de tamanho do `multer` para 413
sem stack.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/visual-associations/visual-associations.service.ts`:
  `createVisualAssociation(input, file, actor, db?)` — dentro de `db.$transaction`:
  `detectImageSignature(file.buffer)` (COMP-023-002) → `null` → `BadRequestError` sem
  persistir nada (FR-022-002); formato válido → `create` da linha com `imageData`/
  `mimeType` no MESMO INSERT, `authorId: actor.id` SEMPRE — nunca lido de `input` (mesmo com
  campo espúrio `authorId`/`author` injetado no corpo, DEC-023-012).
- `updateVisualAssociation(id, input, file, actor, db?)` — dentro de `db.$transaction`:
  `assertVisualAssociationWritable` PRIMEIRO (autor ou ADMIN, senão `ForbiddenError`); sem
  arquivo novo, atualiza só os campos de texto enviados; com arquivo novo, repete
  `detectImageSignature` e grava `imageData`/`mimeType` novos no mesmo UPDATE (substituição
  atômica).
- `assertVisualAssociationWritable(association: Pick<VisualAssociationDetail, 'authorId'>,
  actor: ContentActor): void` — guarda pura, sem I/O (recebe a linha já lida): `throw new
  ForbiddenError(...)` se `actor.role !== 'ADMIN' && association.authorId !== actor.id`.
- `mnemonicos-backend/src/modules/visual-associations/visual-associations.routes.ts`
  (estende a base de TASK-023-006): `const upload = multer({ storage:
  multer.memoryStorage(), limits: { fileSize:
  env.VISUAL_ASSOCIATIONS_MAX_FILE_SIZE_BYTES, files: 1, fields: 2, fieldSize: 4096 } })`
  — **`files`/`fields`/`fieldSize` acrescentados por achado do `security-engineer` (gate 8
  da Wave 1, decisão 4.140)**: `NFR-022-004`/`env.VISUAL_ASSOCIATIONS_MAX_FILE_SIZE_BYTES`
  só cobrem o ARQUIVO — `category`/`cognitiveDescription` (schemas Zod sem `.max()`, mesma
  convenção do projeto) ficariam ilimitados no corpo multipart sem `fieldSize` explícito;
  4096 bytes por campo de texto é folga generosa sobre qualquer categoria/descrição real. —
  instanciado UMA ÚNICA VEZ no topo do módulo (nunca por requisição) — usado como
  middleware em `POST /visual-associations` (arquivo obrigatório) e `PATCH
  /visual-associations/:id` (arquivo opcional). `verifyOrigin`
  como 1º handler nas duas; `requireRole('POST'|'PATCH', '<caminho completo>', 'EDITOR',
  'ADMIN')` declarado na montagem (nunca dentro do handler).
- `VISUAL_ASSOCIATIONS_MAX_FILE_SIZE_BYTES` em `mnemonicos-backend/src/config/env.ts`
  (`z.coerce.number().int().positive().default(5242880)`, A-022-005) + entrada em
  `.env.example` (comentário + valor de exemplo, mesmo padrão das demais chaves do arquivo)
  + `tests/setup-env.ts` (valor fictício determinístico).
- EMENDA em `mnemonicos-backend/src/http/middlewares/error-handler.ts` (COMP-023-017):
  ramo novo, ao lado do `ZodError` já existente (`error-handler.ts:24-39`, ANTES do fallback
  genérico), que reconhece `MulterError` (`import { MulterError } from 'multer'`) — `code
  === 'LIMIT_FILE_SIZE'` → 413 com mensagem genérica pt-BR; qualquer outro código do multer
  → 400 genérico — nunca stack, nunca o nome do campo interno do multer.
- `mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts`: nenhuma
  alteração de asserção fixa é necessária — a suíte deriva `ROUTES`/`NON_PUBLIC` de
  `collectRoutes(apiRoutes)` (nunca hard-coded); as 2 chaves novas montadas nesta TASK (`POST
  /visual-associations`, `PATCH /visual-associations/:id`) entram automaticamente,
  confirmando o crescimento de 25 para 27 pares (TRISK-023-006).
- `npm audit`/gate 8 sobre a dependência nova `multer` (TRISK-023-002).

### Não inclui

- Remoção da associação visual (`removeVisualAssociation`, `DELETE
  /visual-associations/:id`) — TASK-023-010, 2ª chamadora de `assertVisualAssociationWritable`.
- Listagem/busca/sugestão de categoria (`listVisualAssociations`/
  `listVisualAssociationCategories`, `GET /visual-associations[/categories]`) — TASK-023-014.
- Entrega do binário (`getVisualAssociationBinary`, `GET .../:id/image`) — TASK-023-016.
- Vínculo/desvínculo a Quadro (`tira.service.ts`/`tira.routes.ts`) — TASK-023-011.
- Estados observáveis de UI (em andamento/sucesso/falha) do formulário de upload/edição —
  frontend, TASK-023-012 (gate 9 daquela TASK).
- AC-022-006 (parte — exibir a associação atualizada ao REABRIR a tela de gestão do
  acervo): faceta de UI, fecha em TASK-023-012/gate 9; esta TASK só prova a persistência
  (resposta do `PATCH` + leitura direta subsequente).
- AC-022-014 (parte — remoção recusada a STUDENT/anônimo): fica em TASK-023-010; a faceta
  de vincular/desvincular fica em TASK-023-011 (corrigido pelo Tech Lead na consolidação —
  facet adicionada explicitamente lá); esta TASK só prova a faceta de criar/editar.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Reaproveite `detectImageSignature`/`extensionForFormat`/`mimeTypeForFormat`
   (`image-signature.ts`, TASK-023-002) e a camada de storage (`saveVisualAssociationImage`,
   TASK-023-003) por chamada direta — nunca reimplemente a detecção de magic number nem a
   escrita do binário aqui.
2. Declare um tipo `VisualAssociationClient` injetável (mesmo padrão de
   `MnemonicStripClient`/`RawContentClient`), cobrindo `visualAssociation` e `$transaction`.
3. Toda a escrita (criação/edição, incluindo o binário) roda dentro da MESMA
   `$transaction` — sem a antiga dança de ordem entre arquivo e commit (não há mais arquivo
   fora do banco, DEC-023-002).
4. Para a EMENDA do `error-handler.ts`: o ramo novo entra na MESMA posição relativa do
   `ZodError` (antes do `if (err instanceof AppError)` genérico), porque `MulterError` não
   estende `AppError`.
5. `.env.example`: siga o formato de comentário + valor de exemplo já usado pelas demais
   variáveis do arquivo — nunca um valor real.

## Critérios de pronto

- [ ] **Limites de multipart além do arquivo (achado do `security-engineer`, gate 8 da Wave
      1)**: `grep -n "fieldSize\|files:\|fields:" mnemonicos-backend/src/modules/
      visual-associations/visual-associations.routes.ts` confirma os 3 limites configurados
      no `multer(...)` (estrutural, ancorado na chamada real — mutante: remover `fieldSize`
      faz este grep falhar). Teste comportamental: campo `category` com payload muito maior
      que 4096 bytes → multipart recusado (413/400 via a EMENDA do `error-handler.ts`),
      nunca aceito silenciosamente.
- [ ] **`select` explícito em toda leitura que devolve `VisualAssociationDetail` (achado do
      `security-engineer`, gate 8 da Wave 1)**: `createVisualAssociation`/
      `updateVisualAssociation` usam `select` (nunca deixam o Prisma devolver a linha
      inteira por default) excluindo `imageData` do payload de resposta — o binário nunca
      trafega na resposta JSON de criação/edição, só via `GET .../:id/image`
      (TASK-023-016). Teste: resposta de `POST`/`PATCH` não contém a chave `imageData`.
- [ ] Testes cobrem AC-022-001 (cobre FR-022-001, NFR-022-001): upload com assinatura de
      bytes PNG, JPEG e WebP válidas (3 fixtures REAIS, capturadas — nunca geradas a partir
      de prosa) → `201` com o `VisualAssociationDetail` criado, linha persistida com
      `imageData`/`mimeType` corretos para cada formato.
- [ ] Testes cobrem AC-022-002 (cobre FR-022-002, NFR-022-001, NFR-022-002): arquivo
      renomeado com extensão `.png` cujo conteúdo binário é um SVG real (texto/XML) — caso
      literal do AC — e um arquivo aleatório sem assinatura nenhuma (2 casos) → `400`,
      motivo informado, e NENHUMA linha criada (confirmado por contagem de linhas
      antes/depois no banco, não só pelo código HTTP).
- [ ] Testes cobrem AC-022-003 (cobre FR-022-003, NFR-022-004): arquivo raster válido acima
      do teto configurado (ambiente de teste com `VISUAL_ASSOCIATIONS_MAX_FILE_SIZE_BYTES`
      baixo, ou fixture maior que o default) em `POST` e em `PATCH` (multer usado nas duas
      rotas — 2 casos) → `413`, corpo de erro sem stack nem nome de campo interno do multer
      (asserção sobre as CHAVES do corpo, mesmo padrão de `ErrorBody`), nada
      persistido/alterado.
- [ ] Testes cobrem AC-022-004 (cobre FR-022-004): `POST` sem `category`, sem
      `cognitiveDescription`, e sem os dois (3 casos) → `422` (Zod), campos pendentes
      indicados, nenhuma linha criada.
- [ ] Testes cobrem AC-022-006 (parte — persistência via `PATCH`, sem criar nova entidade):
      editar categoria, descrição e substituir a imagem (3 variações) de uma associação
      existente → o `PATCH` responde com o MESMO `id`, e uma leitura direta subsequente
      (`findUnique`) confirma os campos atualizados; a faceta "exibir ao reabrir a tela de
      gestão do acervo" é UI e fecha em TASK-023-012/gate 9 — fora desta TASK.
- [ ] Contrato do próprio item (DEC-023-012, sem AC dedicado): `authorId` da linha criada é
      SEMPRE `actor.id`, mesmo quando o corpo do `POST` injeta um campo `authorId` (ou
      `author`) apontando para outro usuário — a injeção é ignorada, testado explicitamente.
- [ ] **Guarda de escrita — mutação contável (decisão 4.139/4.232, lição "[Segurança] Guarda
      reusada continua exigindo prova comportamental própria por novo método de escrita",
      `guidelines/project/lessons.md`)**: `assertVisualAssociationWritable` NASCE nesta
      TASK; N=1 método a chamá-la aqui (`updateVisualAssociation`) → 1 prova comportamental
      própria (TASK-023-010 soma a 2ª, para `removeVisualAssociation` — nunca herdada
      daqui). Fixture: associação criada por EDITOR A; EDITOR B (outro autor) tenta `PATCH`
      → `403` com a MESMA mensagem literal que qualquer outra recusa de escrita desta guarda
      usa, e a linha permanece INTOCADA (categoria/descrição/`mimeType` idênticos à leitura
      anterior); ADMIN, no mesmo cenário, edita com sucesso. Cobre AC-022-020 (parte).
- [ ] Testes cobrem AC-022-014 (parte — `POST`/`PATCH` recusados a STUDENT/anônimo): sessão
      STUDENT → `403`; sem sessão → `401`, nos dois endpoints.
- [ ] `route-authz-matrix.integration.test.ts` continua verde com as 2 chaves novas
      montadas (`POST /visual-associations`, `PATCH /visual-associations/:id`) — nenhuma
      asserção fixa a alterar (contagem deriva de `collectRoutes`, nunca hard-coded);
      confirma 401 sem sessão / 403 papel insuficiente nas 2 rotas novas.
- [ ] EMENDA do `error-handler.ts` (COMP-023-017, estrutural + comportamental): (a)
      estrutural — o ramo `MulterError` está ANTES do fallback genérico 500 e AO LADO do
      ramo `ZodError` (leitura ancorada na estrutura executável do `if`, nunca em docblock);
      (b) comportamental — `LIMIT_FILE_SIZE` → 413; qualquer outro código do multer (ex.:
      `LIMIT_UNEXPECTED_FILE`, nome de campo de arquivo errado) → 400 genérico; nenhum dos
      dois corpos de erro expõe `err.field`/stack/nome interno do multer.
- [ ] `.env.example`/`tests/setup-env.ts` contêm `VISUAL_ASSOCIATIONS_MAX_FILE_SIZE_BYTES`
      (grep ancorado no nome exato da chave, cada arquivo); `envSchema.safeParse` sem a
      chave definida usa o default `5242880`.
- [ ] `npm audit`/gate 8 sobre `multer` (TRISK-023-002): comando `npm --prefix
      mnemonicos-backend audit` → 0 vulnerabilidade não mitigada na dependência nova (achado
      pré-existente eventual documentado com severidade e mitigação, não bloqueante).
- [ ] Verificação executável (gate 1, todos os itens de teste acima): `npm --prefix
      mnemonicos-backend run test:integration --
      --testPathPatterns=visual-associations.routes.integration.test.ts` → `OK (N tests)`
      (arquivo novo — molde/exemplar de convenção: `tira.routes.integration.test.ts`, que já
      roda com o mesmo padrão de comando trocando o caminho); `npm --prefix
      mnemonicos-backend test --
      visual-associations.service.guard-order.test.ts` → `OK (1 test)` (prova estrutural de
      ordem da guarda, mesmo padrão de `tira.service.guard-order.test.ts`); `npm --prefix
      mnemonicos-backend run test:integration --
      --testPathPatterns=route-authz-matrix.integration.test.ts` → `OK (N tests)`.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`), produção e teste — `npm --prefix mnemonicos-backend run lint` → exit 0.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil `node-22.md` — camadas
      schema→service→routes, `memoryStorage()` nunca `diskStorage()` (DEC-023-003), toda
      escrita numa única `$transaction`.
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-023-001 (PLAN §8) — `ALTER TYPE` aditivo herdado da migração (TASK-023-001/004);
  sem impacto direto no código desta TASK.
- TRISK-023-002 (PLAN §8) — `multer` é dependência nova, supply chain de 1ª classe (A03);
  mitigado por `npm audit`/gate 8 nesta TASK e `memoryStorage()` (nunca `diskStorage()`).
- TRISK-023-006 (PLAN §8) — `route-authz-matrix` precisa alcançar as 2 chaves novas desta
  TASK; a suíte deriva a árvore da `app` montada (sem lista paralela a manter em dia), então
  basta montar as rotas corretamente.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-13T20:47:34+0000
**Data conclusão**: 2026-09-13T22:52:57+0000
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: a6a0407, ad13a0d, ddc56cb, c57c5f7
**Jira**: KAN-96
**Implementado por**: developer
**Revisado por**: code-reviewer (gate 1-7) · security-engineer (gate 8) · product-designer (gate 11, achados no picker do par frontend) — 3 rodadas: REPROVADO (rodada 1: teto de campo bypass via JSON, prova HTTP de spoof insuficiente, DRY de fixtures, ARIA do picker) → retry (ad13a0d/aa526d4) → REPROVADO (rodada 2: mutante M1 do update sem prova espelhada, reincidência DRY em env.test.ts) → Tech Lead aplicou degrau 1 da escada (achados mecânicos, sem ambiguidade de produto — ledger `20260913-222341-decisao-tech-lead.md`) → retry (ddc56cb) + fix residual do Tech Lead (c57c5f7) → APROVADO (verificação final, ledger `20260913-225257-gate-tech-lead.md`)
**Tentativas**: 3
**Cobertura final**: unit 272/272 · integration 312/312 (19 suites) — AC-022-001/002/003/004/006(parte)/014(parte)/020(parte) provados; DEC-023-012 provada nas duas escritas (create e update) no nível de service
**Arquivos modificados**:
  - mnemonicos-backend/.env.example
  - mnemonicos-backend/package.json / package-lock.json
  - mnemonicos-backend/src/config/env.ts
  - mnemonicos-backend/src/http/middlewares/error-handler.ts
  - mnemonicos-backend/src/http/routes.ts
  - mnemonicos-backend/src/modules/visual-associations/visual-association-storage.ts
  - mnemonicos-backend/src/modules/visual-associations/visual-associations.routes.ts
  - mnemonicos-backend/src/modules/visual-associations/visual-associations.schema.ts
  - mnemonicos-backend/src/modules/visual-associations/visual-associations.service.ts
  - mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts
  - mnemonicos-backend/tests/integration/visual-association-storage.integration.test.ts
  - mnemonicos-backend/tests/integration/visual-associations.model.integration.test.ts
  - mnemonicos-backend/tests/integration/visual-associations.routes.integration.test.ts
  - mnemonicos-backend/tests/integration/visual-associations.service.integration.test.ts
  - mnemonicos-backend/tests/support/visual-association-fixtures.ts
  - mnemonicos-backend/tests/setup-env.ts
  - mnemonicos-backend/tests/unit/env.test.ts
  - mnemonicos-backend/tests/unit/visual-associations.service.guard-order.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado
- [x] Comportamento (gate 9): consolidado FEAT-022-001 (write path provado ponta-a-ponta via HTTP; faceta de UI de "exibir ao reabrir" fecha em TASK-023-012)

**Notas**: Achado de DRY reincidente (2ª ocorrência de re-derivação de `loadEnvModule` no mesmo arquivo, sobrevivendo ao 1º retry) e achado de processo (comando de varredura não transcrito como critério do despacho) roteados: `guidelines/project/lessons.md:783` (contador atualizado para "confirmada 2") e `docs/_meta/learning-log.md` LRN-022 (PROPOSTA_PLUGIN).
