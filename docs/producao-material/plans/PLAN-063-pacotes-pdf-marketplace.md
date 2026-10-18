# PLAN-063: Pacotes de PDF para marketplace

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.1
**Autor**: scribe (redação delegada pelo Tech Lead; reconhecimento técnico do `code-scout`)
**Data**: 2026-10-18

## Aderência a guidelines

**Decisões irreversíveis do slug tocadas**: nenhuma. A única decisão irreversível do INDEX é DEC-029-003 (snapshot JSON de `ContentVersion` preservado). É **vizinha**, não tocada: o `items` Json do Registro de exportação (DEC-063-004) segue a mesma lógica — congelar a composição no momento do ato preserva a opção de reprodução histórica, e podar depois é reversível, não ter capturado não seria. Nada a quebrar.
**Decisões irreversíveis de outros slugs em conflito**: nenhuma — `infra-vercel` não tem bloco de decisões (`infra-vercel: sem bloco de decisões`; pasta sem `INDEX.md`). As restrições de plataforma (corpo ~4,5 MB, `maxDuration` 15 s, memória 1024 MB em `vercel.json`) são fatos de ambiente tratados em DEC-063-001..003.
**Exceções aos guidelines**: nenhuma. Backend segue `guidelines/project/backend/` (camadas schema Zod → service → routes, nada de Prisma na rota, `AppError`, lógica pura sem I/O recebendo `now` por parâmetro); frontend segue `guidelines/project/frontend/` (Server Components por padrão, `'use client'` só com estado/evento, estado do servidor em RTK Query, tokens no `@theme`). Dependências novas (`@aws-sdk/client-s3`, `@aws-sdk/s3-request-presigner`, `client-zip`) são decisão deste PLAN, sujeitas ao gate 8 (supply chain).

## Cobertura

**SPEC referenciada**: SPEC-061
**Slice declarado**: cobertura total restante (Caso D — nenhum PLAN anterior cobre FRs/NFRs da SPEC-061)

**FRs cobertos**:
- FR-061-001
- FR-061-002
- FR-061-003
- FR-061-004
- FR-061-005
- FR-061-006
- FR-061-007
- FR-061-008
- FR-061-009
- FR-061-010
- FR-061-011
- FR-061-012
- FR-061-013
- FR-061-014
- FR-061-015
- FR-061-016
- FR-061-017
- FR-061-018
- FR-061-019
- FR-061-020
- FR-061-021
- FR-061-022
- FR-061-023
- FR-061-024
- FR-061-025
- FR-061-026
- FR-061-027
- FR-061-028
- FR-061-029
- FR-061-030
- FR-061-031
- FR-061-032
- FR-061-033
- FR-061-034
- FR-061-035

**NFRs cobertos**:
- NFR-061-001
- NFR-061-002
- NFR-061-003
- NFR-061-004
- NFR-061-005
- NFR-061-006

## 1. Visão técnica

Toca os dois repositórios e **infraestrutura nova**. O fato que molda tudo (memo do `code-scout`, itens 2 e 11): o backend roda como função serverless da Vercel (`api/index.ts`, `vercel.json` memory 1024 / maxDuration 15) com teto de ~4,5 MB de corpo em requisição **e** resposta, e não existe storage de objetos, SDK nem filesystem utilizável. A SPEC pede PDFs de até 50 MB (A-061-002) e pacotes de centenas de MB (NFR-061-006). Logo, **nenhum byte de PDF atravessa a função**: o navegador envia e baixa direto do storage por URL pré-assinada, e o arquivo compactado é montado no navegador.

**Backend** (`mnemonicos-backend`): três módulos novos na árvore plana de `src/http/routes.ts`, no molde de `visual-associations` (schema → service → routes):
- `object-storage` — porta `ObjectStorage` (presign PUT com Content-Length assinado, presign GET 300 s, head, leitura por Range, leitura em stream, copy, delete) com adapter S3 e fake em memória nos testes (DEC-063-001, DEC-063-007).
- `pdf-library` — Acervo de PDFs, envio em 2 fases (DEC-063-002), assinatura `%PDF-` em função pura `detectPdfSignature` (mesmo princípio de `image-signature.ts`/DEC-023-012), substituição com chave nova, remoção serializada (DEC-063-006).
- `sales-packages` — Pacote, Itens, Ficha (função pura, DEC-063-009) e exportação em 2 fases (DEC-063-003): criação do Registro `PENDING` com composição congelada lida na mesma transação, e confirmação `COMPLETED`.

Uma migração **aditiva** (DEC-063-004) cria quatro tabelas; os tipos de domínio são espelhados à mão nos dois repositórios no mesmo diff. As rotas entram na barreira deny-by-default com `requireRole` EDITOR/ADMIN e `verifyOrigin` nas mutações (DEC-063-005). Storage ausente **não derruba o boot**: as rotas do acervo/exportação respondem 503 em pt-BR (DEC-063-007).

**Frontend** (`mnemonicos-frontend`): duas telas internas novas — `(interno)/pdf-library` e `(interno)/packages` (+ `packages/[id]`) — registradas em `INTERNAL_ROUTE_PREFIXES`, no matcher de `proxy.ts` e em `INTERNAL_NAV_ITEMS` (com ícones), sem reordenar entradas existentes (NFR-061-005). Molde visual: `visual-library-board.tsx`. O upload com progresso usa `XMLHttpRequest` direto à URL pré-assinada (fora do `baseQuery` do RTK Query); as chamadas à API continuam em `src/store/api.ts`. A exportação baixa os objetos por URL pré-assinada, compacta com `client-zip` (modo store, streaming) e dispara o download; só então confirma (DEC-063-003).

**Pendências externas** (Diretor): provisionar conta/bucket e credenciais do storage, configurar CORS do bucket (PUT/GET das origens do frontend) e as envs no ambiente de deploy. Até lá, o deploy segue vivo e o acervo responde 503 explicável.

**Gates**: gate 8 (segurança) aplica — superfície nova de upload/download, credenciais de storage, URL assinada, dependência nova; gate 9 (comportamento verificado) com MinIO local e, se o ambiente faltar, `pendente_handoff` para o bucket real; gate 10 (performance) aplica — SHA-256 por streaming dentro de `maxDuration`, compactação no navegador; gate 11 (design/UX) aplica — duas telas e fluxo de 3 estados.

## 2. Stack e dependências

Stack vigente herdada, sem reescolha: Node 22 · Express 5 · Zod · Prisma 7 · PostgreSQL · Jest (unit + integração com Postgres real) no backend; Next 16 · React 19 · Tailwind 4 · Redux Toolkit/RTK Query · Jest 30 + RTL no frontend.

Dependências **novas**:
- Backend: `@aws-sdk/client-s3` e `@aws-sdk/s3-request-presigner` (adapter S3 da porta `ObjectStorage`; provedor-agnóstico — Cloudflare R2 recomendado ao Diretor por não cobrar egress; AWS S3 e MinIO servem).
- Frontend: `client-zip` (montagem do arquivo compactado no navegador, modo store, streaming). Sem dependência de ZIP no backend.
- Infra de desenvolvimento: serviço MinIO no `docker-compose` do backend; `.env.example` com placeholders das envs de storage (nunca valores reais; nada `NEXT_PUBLIC_`).

Reúso: `requireRole`, `verifyOrigin`, `AppError`/error handler central, padrão de autor-ou-ADMIN de F5/F7/F8, correção de TOCTOU por `SELECT ... FOR UPDATE` de F5, reindexação em 2 fases da Tira (DEC-012-003), `image-signature.ts` como molde, `visual-library-board.tsx`, o padrão de `triggerDownload` de `publication-export-control.tsx` (função privada ali — duplicada em `src/lib/trigger-download.ts` pela TASK-063-011, sem tocar o componente da Tira: NFR-061-005), `internal-routes.ts`/`internal-nav.ts`/`proxy.ts`.

Arquivos tocados (inventário, relativos a cada repositório):
- Backend: `prisma/schema.prisma` + migração `YYYYMMDDHHMMSS_add_sales_packages`; `src/domain/types.ts`; `src/config/env.ts`; `src/http/routes.ts`; `src/http/middlewares/error-handler.ts` (somente se o 503 de storage ausente pedir tipo de erro; preferir `AppError`); `src/modules/{object-storage,pdf-library,sales-packages}/`; `vercel.json` (`maxDuration` da função única `api/index.ts`, que vale para todas as rotas); `docker-compose.yml`; `.env.example`; `tests/` (unit, integração, fake de storage em `tests/support`); `tests/integration/route-authz-matrix.integration.test.ts` (53 → 53+N).
- Frontend: `src/types/domain.ts`; `src/store/api.ts`; `src/lib/internal-routes.ts`, `src/lib/internal-nav.ts`, `src/components/internal-nav-icons.tsx`, `src/proxy.ts`; `src/app/(interno)/pdf-library/`, `src/app/(interno)/packages/` e `packages/[id]/`; componentes novos; `package.json`.
- Workspace: `docs/GUIA-DE-USO.md`.

## 3. Componentes

### COMP-063-001: Armazenamento de objetos (porta, adapters, configuração)
**Responsabilidade**: Porta `ObjectStorage` e seus adapters. Adapter S3 (presign PUT com `Content-Length` assinado, presign GET com expiração de 300 s, HEAD, leitura por Range, leitura em stream, copy, delete); fake em memória para testes; leitura e validação das envs (`OBJECT_STORAGE_*`, `PDF_LIBRARY_MAX_FILE_SIZE_BYTES`, `SALES_PACKAGE_MAX_EXPORT_BYTES`) em `env.ts`; storage ausente não derruba o boot e produz 503 pt-BR "armazenamento de arquivos não configurado" nas rotas dependentes. Chaves de objeto aleatórias e não derivadas de Título.
**Realiza**: NFR-061-001
**Interface pública**: `ObjectStorage` (`presignPut`, `presignGet`, `head`, `readRange`, `readStream`, `copy`, `delete`); `getObjectStorage()` que devolve a porta ou lança `AppError` 503 quando não configurado; constantes de expiração.
**Dependências**: nenhuma

### COMP-063-002: Modelo de dados e tipos de domínio espelhados
**Responsabilidade**: Migração aditiva com `LibraryPdf`, `SalesPackage`, `SalesPackageItem`, `SalesPackageExport` e enum de status da exportação; atualização dos tipos de domínio nos dois repositórios no mesmo diff (`mnemonicos-backend/src/domain/types.ts` e `mnemonicos-frontend/src/types/domain.ts`). Registra autor e data de envio, substituição e exportação. A migração só é executada com autorização prévia do Diretor.
**Realiza**: NFR-061-002
**Interface pública**: modelos Prisma e tipos TypeScript (`LibraryPdf`, `SalesPackage`, `SalesPackageItem`, `SalesPackageExport`, `ExportItemSnapshot`, `ExportStatus`).
**Dependências**: nenhuma

### COMP-063-003: Acervo de PDFs (backend)
**Responsabilidade**: Schemas Zod, service e rotas do acervo. Envio em 2 fases (intenção que valida metadados e tamanho e devolve URL de PUT para `pending/<userId>/<uuid>`; confirmação que lê os primeiros bytes pela função pura `detectPdfSignature`, confere tamanho real por HEAD, calcula SHA-256 por streaming, copia `pending/` para a chave definitiva e grava o registro; inválido apaga o objeto e responde 400). Listagem ordenada por criação desc com teto de leitura, URL de download de 300 s, edição de metadados, substituição com o mesmo fluxo e chave nova (apaga o objeto antigo após o commit), remoção com `FOR UPDATE` e mensagem que nomeia os Pacotes. Regra autor-ou-ADMIN em substituir e remover.
**Realiza**: FR-061-001, FR-061-002, FR-061-003, FR-061-004, FR-061-005, FR-061-006, FR-061-007, FR-061-008, FR-061-009, FR-061-010, FR-061-011, FR-061-023, FR-061-025, NFR-061-001, NFR-061-004
**Interface pública**: rotas `GET /pdf-library`, `POST /pdf-library/uploads`, `POST /pdf-library/uploads/confirm`, `GET /pdf-library/:id/download`, `PATCH /pdf-library/:id`, `POST /pdf-library/:id/replacement`, `POST /pdf-library/:id/replacement/confirm`, `DELETE /pdf-library/:id`; função pura `detectPdfSignature(bytes)`.
**Dependências**: COMP-063-001, COMP-063-002

### COMP-063-004: Pacotes e Ficha (backend)
**Responsabilidade**: Schemas, service e rotas de Pacote: cadastrar, listar (criação desc, teto de leitura, com última exportação `COMPLETED`), detalhar (Itens, tamanho total, composição da última exportação), editar, remover (autor-ou-ADMIN; mantém os registros de exportação), adicionar/remover/reordenar Itens (`FOR UPDATE` do PDF, duplicidade recusada, reindexação em 2 fases) e Ficha em texto UTF-8 por função pura (`buildDatasheet`), servida por GET. Preço em centavos inteiros ≥ 0.
**Realiza**: FR-061-013, FR-061-014, FR-061-015, FR-061-016, FR-061-017, FR-061-021, FR-061-027, FR-061-028, FR-061-029, FR-061-033, FR-061-035, NFR-061-004
**Interface pública**: rotas `GET/POST /sales-packages`, `GET/PATCH/DELETE /sales-packages/:id`, `POST /sales-packages/:id/items`, `DELETE /sales-packages/:id/items/:pdfId`, `PUT /sales-packages/:id/items/order`, `GET /sales-packages/:id/datasheet`; função pura `buildDatasheet(pkg, items)`.
**Dependências**: COMP-063-002, COMP-063-003

### COMP-063-005: Exportação de Pacote em 2 fases (backend)
**Responsabilidade**: `POST /sales-packages/:id/exports` recusa Pacote sem Itens e total acima do teto (mensagem com total e teto), lê o estado dos Itens na mesma transação, cria o Registro `PENDING` com a composição congelada (posição, Título, Versão, data declarada, tamanho, sha256, chave do objeto) e devolve nomes saneados (função pura `sanitizeEntryName`) e URLs GET de 300 s; `POST .../exports/:exportId/complete` marca `COMPLETED` (exige o próprio autor do registro `PENDING`). Só `COMPLETED` conta na métrica, na "última exportação" e na tela.
**Realiza**: FR-061-018, FR-061-019, FR-061-020, FR-061-030, FR-061-034, NFR-061-001, NFR-061-002, NFR-061-006
**Interface pública**: rotas `POST /sales-packages/:id/exports` e `POST /sales-packages/:id/exports/:exportId/complete`; função pura `sanitizeEntryName(position, title)`.
**Dependências**: COMP-063-001, COMP-063-002, COMP-063-004

### COMP-063-006: Acervo de PDFs (frontend)
**Responsabilidade**: Tela `(interno)/pdf-library`: lista (título, versão, data declarada, tamanho, autor/data de envio e de substituição), estado vazio com ação de enviar, formulário de envio/edição/substituição (Versão e data atuais editáveis e confirmação de que o arquivo anterior deixa de existir), remoção com confirmação, aviso jurídico visível, três estados da ação com progresso de upload por `XMLHttpRequest` para a URL pré-assinada, download por URL de curta duração. Endpoints no RTK Query (`src/store/api.ts`); mensagens em pt-BR que dizem o que corrigir.
**Realiza**: FR-061-005, FR-061-006, FR-061-008, FR-061-012, FR-061-024, FR-061-026, NFR-061-004
**Interface pública**: página `/pdf-library`; hooks RTK Query do acervo; componente de upload com progresso.
**Dependências**: COMP-063-003, COMP-063-007

### COMP-063-007: Navegação e rotas internas (frontend)
**Responsabilidade**: Registrar `/pdf-library` e `/packages` em `INTERNAL_ROUTE_PREFIXES`, no matcher de `proxy.ts` (array literal testado) e em `INTERNAL_NAV_ITEMS` com ícones, só para EDITOR/ADMIN, sem remover nem reordenar entradas existentes. STUDENT e visitante não veem os itens e são barrados no proxy.
**Realiza**: FR-061-011, FR-061-021, NFR-061-005
**Interface pública**: constantes de rota e itens de menu; ícones em `internal-nav-icons.tsx`.
**Dependências**: nenhuma

### COMP-063-008: Pacotes e exportação client-side (frontend)
**Responsabilidade**: Telas `(interno)/packages` (lista com última exportação, estado vazio) e `packages/[id]` (dados do Pacote, Itens com seletor, busca por Título no cliente e reordenação, estado vazio, Ficha na tela com download, tamanho total, remoção com confirmação que informa a última exportação, exportação com os três estados, última exportação e sua composição congelada). Exportação: obtém snapshot e URLs, baixa cada objeto, compacta com `client-zip` em modo store, dispara o download e só então confirma; falha em qualquer etapa não confirma e orienta a exportar de novo.
**Realiza**: FR-061-013, FR-061-015, FR-061-016, FR-061-017, FR-061-018, FR-061-019, FR-061-020, FR-061-022, FR-061-028, FR-061-029, FR-061-031, FR-061-032, FR-061-033, FR-061-035, NFR-061-004, NFR-061-006
**Interface pública**: páginas `/packages` e `/packages/[id]`; hooks RTK Query de Pacote e exportação; função `exportPackageArchive(snapshot)`.
**Dependências**: COMP-063-004, COMP-063-005, COMP-063-007

### COMP-063-009: Documentação e ambiente local
**Responsabilidade**: `docs/GUIA-DE-USO.md` com Acervo de PDFs, Pacotes, exportação e aviso de que o sistema não atesta revisão jurídica, com a data de "Última atualização"; `.env.example` do backend com placeholders; serviço MinIO no `docker-compose`; registro da pendência de CORS do bucket e da configuração de envs no deploy.
**Realiza**: NFR-061-003
**Interface pública**: guia de uso, `.env.example`, `docker-compose.yml`.
**Dependências**: COMP-063-006, COMP-063-008

## 4. Fluxos principais

**Envio de PDF (DEC-063-002)**
1. Navegador `POST /pdf-library/uploads` com metadados e tamanho declarado; o servidor valida (Título, Versão, data obrigatórios; tamanho ≤ máximo) e devolve URL de PUT com `Content-Length` assinado para `pending/<userId>/<uuid>`.
2. Navegador faz `PUT` direto ao storage (progresso por `XMLHttpRequest`).
3. Navegador `POST /pdf-library/uploads/confirm` com a chave: o servidor lê os primeiros bytes (Range), confere `%PDF-` e o tamanho (HEAD), calcula o SHA-256 por streaming. Inválido: apaga o objeto, 400 pt-BR. Válido: copia para chave definitiva, apaga `pending/`, grava `LibraryPdf` com o autor e `createdAt`.

**Substituição**: mesmo fluxo com chave nova; no commit, `storageKey`, `sizeBytes`, `sha256`, `replacedById` e `replacedAt` mudam (metadados editáveis na mesma ação); o objeto antigo é apagado depois do commit. Só autor ou ADMIN.

**Remoção de PDF**: `$transaction` com `SELECT ... FOR UPDATE` da linha do PDF; se há Itens, recusa nomeando os Pacotes; senão apaga o registro e, após o commit, o objeto. A FK Restrict é a defesa em profundidade.

**Inclusão em Pacote**: mesma transação com `FOR UPDATE` do PDF; PDF inexistente → 404 "o PDF não existe mais"; duplicidade → recusa. Reordenação: reindexação em 2 fases (posições temporárias negativas, depois definitivas) sob a restrição `@@unique([packageId, position])`.

**Exportação (DEC-063-003)**
1. `POST /sales-packages/:id/exports`: recusa sem Itens ou acima do teto; na transação, lê Itens e PDFs, grava `SalesPackageExport` `PENDING` com `items` congelados e devolve nomes saneados e URLs GET (300 s).
2. Navegador baixa cada objeto, monta o arquivo com `client-zip` (store, streaming) e dispara o download.
3. `POST .../complete` marca `COMPLETED` e grava `completedAt`. Falha em qualquer ponto: nada é confirmado e o `PENDING` não conta.
Substituição simultânea (AC-061-039): cada substituição ganha chave nova e o snapshot aponta para a chave da época; se o objeto sumiu no meio, o download falha, a exportação não é confirmada e a mensagem orienta exportar de novo — nunca mistura.

**Ficha**: `GET /sales-packages/:id/datasheet` devolve texto UTF-8 gerado por função pura, com o aviso jurídico e o rótulo "Data de fechamento legislativo (declarada)".

## 5. Modelo de dados

Migração aditiva (nome `YYYYMMDDHHMMSS_add_sales_packages`, a gerar com `prisma migrate dev` somente após autorização do Diretor; o arquivo entra no diff da TASK):

- `LibraryPdf`: `id`, `title`, `version`, `legislativeClosureDate @db.Date`, `examName?`, `disciplineId?` (FK `SetNull`), `storageKey @unique`, `sizeBytes` (Int ou BigInt — escolher na TASK conforme o teto de 50 MB, que cabe em Int), `sha256 @db.Char(64)`, `authorId`, `createdAt`, `replacedById?`, `replacedAt?`, `updatedAt`.
- `SalesPackage`: `id`, `name`, `description?`, `referencePriceCents Int` (≥ 0, CHECK de integridade ou validação Zod + service), `examName?`, `disciplineId?`, `authorId`, `createdAt`, `updatedAt`.
- `SalesPackageItem`: `id`, `packageId` (FK `Cascade`), `pdfId` (FK `Restrict`), `position`, `@@unique([packageId, pdfId])`, `@@unique([packageId, position])`.
- `SalesPackageExport`: `id`, `packageId?` (FK `SetNull` — sobrevive à remoção do Pacote), `packageName` (snapshot), `exportedById`, `status` (enum `PENDING | COMPLETED`), `items Json` (snapshot: posição, Título, Versão, data declarada, tamanho, sha256, chave do objeto), `createdAt`, `completedAt?`.

O modelo chama-se `SalesPackage` e não `Package` porque `package` é palavra reservada em strict mode JS. Preço em centavos inteiros, nunca float. Índices: `LibraryPdf(createdAt)`, `SalesPackage(createdAt)`, `SalesPackageExport(packageId, status, completedAt)`.

## 6. Decisões arquiteturais

### Decisões herdadas
- **DEC-063-005** [herdada] Rotas novas registradas na barreira deny-by-default com `requireRole` EDITOR/ADMIN e `verifyOrigin` nas mutações, tripwire `route-authz-matrix` atualizado (53 → 53+N pares, N estimado em 19 e confirmado na TASK) e regra autor-ou-ADMIN para substituir/remover PDF e remover Pacote aplicada no service (mecanismo igual ao de F5/F7/F8) — fonte: SPEC A-061-004/NFR-061-005 e padrão vigente do slug (`src/http/routes.ts` deny-by-default). Os filtros de acesso compostos continuam todos valendo: papel EDITOR/ADMIN em toda rota, autor-ou-ADMIN nos atos destrutivos, sessão autenticada; nenhum é relaxado por este PLAN.

### DEC-063-001: Storage de objetos S3-compatível atrás de uma porta `ObjectStorage`
**Contexto**: A SPEC exige PDFs de até 50 MB (A-061-002) e URL de download de curta duração (NFR-061-001). O backend é serverless com corpo ~4,5 MB e `maxDuration` 15 s (RISK-025-007); não há storage nem filesystem (memo do `code-scout`, itens 2 e 7).
**Decisão**: Storage de objetos com API compatível com S3, provedor-agnóstico (Cloudflare R2 recomendado ao Diretor por não cobrar egress; AWS S3 e MinIO servem), acessado por uma porta `ObjectStorage` no backend: adapter S3 via `@aws-sdk/client-s3` + `@aws-sdk/s3-request-presigner`, fake em memória nos testes, MinIO no `docker-compose` para desenvolvimento local.
**Alternativas consideradas**:
- `bytea` no Postgres (padrão de F5), descartada porque o teto efetivo cai para ~4 MB pela função serverless (RISK-025-007) contra os 50 MB da A-061-002, e incha banco e backup a cada PDF e a cada substituição.
- Vercel Blob, descartada porque o acesso privado com URL de curta duração não é garantido nem padrão no SDK e amarra o produto ao provedor, sem como trocar sem reescrever.
- Filesystem, descartada porque não existe na função serverless: nada gravado sobrevive à invocação.
**Consequências**: Conta, bucket, credenciais e CORS são provisionados pelo Diretor (pendência externa); custo de egress depende do provedor (TRISK-063-004). A porta isola o provedor: trocar é trocar o adapter.
**Reabrir se**: o Diretor recusar conta em terceiro (cai para `bytea` com teto ~4 MB e replaneja) ou o provedor escolhido não suportar URL pré-assinada.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-063-002: Upload e download diretos navegador–storage por URL pré-assinada, envio em 2 fases
**Contexto**: O corpo da função serverless é limitado a ~4,5 MB; o PDF pode ter 50 MB. A validação de conteúdo (FR-061-002) e o digest (FR-061-020) precisam acontecer no servidor sobre o objeto real.
**Decisão**: Nenhum byte de PDF atravessa a função. (1) `POST` de intenção valida metadados e tamanho e devolve URL de PUT com `Content-Length` assinado igual ao tamanho declarado (≤ máximo) para chave aleatória `pending/<userId>/<uuid>`, vinculada ao autor da intenção; (2) o navegador faz `PUT` direto; (3) `POST` de confirmação (aceito só quando o prefixo `pending/<userId>/` da chave é o do usuário da sessão; outra chave → 404): o backend lê os primeiros bytes por Range para a assinatura `%PDF-` (função pura nova `detectPdfSignature`, mesmo princípio de `image-signature.ts`/DEC-023-012), confere o tamanho real por HEAD e calcula o SHA-256 por streaming do objeto. Inválido: apaga o objeto e responde 400. Válido: copia para a chave definitiva, apaga `pending/` e grava o registro (a cópia impede reuso da chave `pending/` após a confirmação). Substituição usa o mesmo fluxo com chave nova e apaga o objeto antigo após o commit. Download: `GET` autenticado devolve URL pré-assinada de 300 s.
**Alternativas consideradas**:
- Multipart pela função (molde F5), descartada porque o teto de ~4,5 MB do corpo recusaria qualquer PDF acima disso, ou seja, a maior parte dos PDFs diagramados com imagens.
- Confiar no `Content-Type`/extensão do PUT sem confirmação, descartada porque a SPEC veta validar por extensão ou tipo declarado (FR-061-002) e não geraria o digest.
**Consequências**: Intenção sem confirmação deixa órfão em `pending/` (TRISK-063-001). O bucket precisa de CORS liberando PUT/GET das origens do frontend (pendência do Diretor; TRISK-063-002). Confirmação lê até 50 MB: o `maxDuration` da função única `api/index.ts` (vale para todas as rotas; não há configuração por rota) é medido e, se preciso, elevado (TRISK-063-003).
**Reabrir se**: o provedor não aceitar `Content-Length` assinado no PUT, ou o SHA-256 de 50 MB não couber em `maxDuration` medido.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-063-003: Exportação montada no navegador a partir de URLs pré-assinadas, em 2 fases
**Contexto**: Pacotes têm centenas de MB (NFR-061-006); a função tem ~4,5 MB de corpo, `maxDuration` 15 s e 1024 MB de memória. O Registro de exportação só deve contar quando o download realmente ocorre (AC-061-025) e deve descrever exatamente o arquivo que entrou (FR-061-030), na mesma lógica de preservação de DEC-029-003.
**Decisão**: O arquivo compactado é montado **no navegador** com `client-zip` (modo store, sem recompressão, streaming) a partir de URLs GET pré-assinadas entregues junto com o snapshot. `POST` cria o Registro `PENDING` com a composição congelada (lida do banco na mesma transação) e devolve nomes saneados e URLs; o navegador baixa, compacta e dispara o download; ao concluir, `POST` de confirmação marca `COMPLETED`. Só `COMPLETED` conta na métrica, na "última exportação" e na tela. "Versão inteira, nunca mistura": cada arquivo substituído ganha chave nova; o snapshot aponta para a chave da época; se o objeto antigo sumiu no meio, o download falha e a exportação não é confirmada (mensagem: exporte de novo).
**Alternativas consideradas**:
- ZIP no servidor devolvido na resposta, descartada porque o corpo de ~4,5 MB e `maxDuration` de 15 s recusam qualquer Pacote realista.
- ZIP no servidor gravado no storage, descartada porque 15 s de `maxDuration` e 1024 MB de memória não comportam centenas de MB: teria de virar job/fila, fora do porte desta fatia.
- Confirmar a exportação já na criação, descartada porque uma falha de rede ou de objeto contaria como exportação feita e falsearia a métrica da §1.3 e a "última exportação".
**Consequências**: O limite real de tamanho é o do navegador (`SALES_PACKAGE_MAX_EXPORT_BYTES`, DEC-063-007). `PENDING` abandonado fica sem efeito. A janela entre substituir e apagar o objeto antigo exige que a exclusão do antigo ocorra após o commit; download cujo objeto sumiu falha e orienta nova tentativa.
**Reabrir se**: pacotes reais passarem do que o navegador comporta, ou surgir infraestrutura de job.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-063-004: Modelo de dados e migração aditiva
**Contexto**: O Pacote precisa sobreviver sem seus Itens mas o Registro de exportação precisa sobreviver ao Pacote (FR-061-017); PDFs com Item não podem ser removidos (FR-061-010); preço é monetário.
**Decisão**: Quatro tabelas novas, descritas na §5: `LibraryPdf`, `SalesPackage`, `SalesPackageItem` (FK `Cascade` no Pacote, `Restrict` no PDF, `@@unique([packageId, pdfId])` e `@@unique([packageId, position])`) e `SalesPackageExport` (`packageId` FK `SetNull`, `packageName` e `items Json` como snapshot). Preço em centavos inteiros. Nome `SalesPackage` porque `package` é reservada em strict mode.
**Alternativas consideradas**:
- Congelar a composição só por referência aos Itens vivos (sem snapshot Json), descartada porque substituir um arquivo ou editar a Versão alteraria o histórico e quebraria AC-061-030; o snapshot é o que sustenta o registro.
- Preço em `Decimal`/float, descartada porque float acumula erro e `Decimal` exige conversão em toda fronteira JSON, para um valor que é só informativo com 2 casas.
**Consequências**: Migração aditiva sem backfill. Remoção de usuário/autor não é tratada por esta fatia (segue a política já vigente para `authorId` nos demais módulos). A migração **exige autorização do Diretor antes de executar** (CLAUDE.md).
**Reabrir se**: surgir necessidade de histórico de arquivos substituídos (hoje fora de escopo, SPEC §4.2).
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-063-006: Concorrência por `SELECT ... FOR UPDATE` e reindexação em 2 fases
**Contexto**: FR-061-010 e AC-061-038 exigem que remoção de PDF e inclusão em Pacote simultâneas nunca deixem Item sem arquivo; a reordenação sob `@@unique([packageId, position])` colide em passos intermediários.
**Decisão**: Remoção de PDF e inclusão em Pacote são serializadas por `SELECT ... FOR UPDATE` da linha do `LibraryPdf` dentro de `$transaction` (mesma correção do TOCTOU de F5), com a FK `Restrict` como defesa em profundidade. Reordenação por reindexação em 2 fases (molde DEC-012-003 da Tira).
**Alternativas consideradas**:
- Apenas a FK `Restrict`, sem lock, descartada porque o erro de FK vira 500 e não a mensagem que nomeia o Pacote exigida por FR-061-010/AC-061-010, e a mensagem "o PDF não existe mais" da AC-061-038 não teria origem.
- Nível `Serializable` na transação, descartada porque exige retry de conflito de escrita em toda mutação do acervo, para um ganho que o lock de uma linha já dá.
**Consequências**: Dois lockers sobre a mesma linha esperam; volume esperado de dezenas de PDFs torna a contenção irrelevante.
**Reabrir se**: a contenção de lock aparecer em medição ou surgirem operações em lote sobre o acervo.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-063-007: Configuração por env e degradação sem storage
**Contexto**: O teto por arquivo é configurável (A-061-002) e o teto de exportação é "definido no plano, medido contra o ambiente" (NFR-061-006). O deploy atual não tem storage e precisa continuar vivo até o Diretor provisioná-lo.
**Decisão**: Envs `PDF_LIBRARY_MAX_FILE_SIZE_BYTES` (default 52428800), `SALES_PACKAGE_MAX_EXPORT_BYTES` (default 524288000, teto cumulativo medido contra o navegador) e `OBJECT_STORAGE_ENDPOINT/REGION/BUCKET/ACCESS_KEY_ID/SECRET_ACCESS_KEY`, só no backend (nunca `NEXT_PUBLIC_`; `.env.example` só com placeholders). Storage ausente **não derruba o boot**: as rotas do acervo e da exportação respondem 503 com a mensagem pt-BR "armazenamento de arquivos não configurado".
**Alternativas consideradas**:
- Falhar o boot quando faltar env de storage, descartada porque derrubaria todo o backend em produção (login, produção de conteúdo) por uma feature opcional ainda sem provisionamento.
- Teto de exportação fixo no código, descartada porque o valor depende de medição no ambiente real e exigiria deploy para ajustar.
**Consequências**: O teto de 500 MB é palpite inicial a medir (TRISK-063-005); as rotas respondem 503 até a configuração.
**Reabrir se**: a medição de pacote real no navegador mostrar que o default não cabe, ou o storage virar obrigatório do produto.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-063-008: Listas sem paginação, com teto de leitura e busca no cliente
**Contexto**: FR-061-025 e FR-061-033 deixam a paginação "decisão do plano, conforme o volume"; o volume esperado são dezenas de registros.
**Decisão**: Listas do acervo e de Pacotes sem paginação, ordenadas por criação desc e com teto de leitura de 200 registros; a busca por Título no seletor de PDFs (FR-061-032) é feita no cliente sobre a lista carregada.
**Alternativas consideradas**:
- Paginação e busca no servidor, descartada porque adiciona cursor, estado de página e endpoint de busca para dezenas de registros, sem benefício percebido hoje.
**Consequências**: Acima de 200 PDFs o seletor deixaria de enxergar os mais antigos — aceito pelo volume esperado.
**Reabrir se**: o acervo passar de ~150 PDFs.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-063-009: Saneamento de nome e Ficha como funções puras
**Contexto**: FR-061-034 exige substituir caracteres proibidos por '-', manter acentos e cortar nome longo; a Ficha (FR-061-028/035) é um texto determinístico a partir dos dados.
**Decisão**: `sanitizeEntryName` e `buildDatasheet` são funções puras no backend, sem I/O, testadas em unit; a Ficha é servida por GET (texto pequeno, cabe no corpo). O nome saneado chega ao navegador pronto no snapshot da exportação.
**Alternativas consideradas**:
- Sanear no navegador ao montar o compactado, descartada porque o teste de FR-061-034 passaria a depender de ambiente de browser e a regra teria uma cópia a manter no frontend.
**Consequências**: Regra única, testável; o frontend não conhece a regra de nome.
**Reabrir se**: a Ficha precisar de formato rico (PDF/planilha), hoje fora de escopo.
**Irreversível**: não
**Aderência à ficha/perfil**: nova

## 8. Riscos técnicos

- **TRISK-063-001** Objetos órfãos em `pending/` quando há intenção sem confirmação (mitigação: chave aleatória e prefixo separado; limpeza automática fora do porte desta fatia — recomendar ao Diretor uma regra de lifecycle do bucket para `pending/`).
- **TRISK-063-002** CORS do bucket mal configurado faz o upload e o download falharem calados no navegador, paralelo à lição de `CORS_ORIGINS` do CLAUDE.md (mitigação: TASK de documentação registra a configuração exata, o `docker-compose` com MinIO reproduz o CORS no desenvolvimento, e o front distingue erro de rede no PUT com mensagem que cita a possível causa).
- **TRISK-063-003** SHA-256 por streaming de 50 MB dentro de `maxDuration` 15 s na confirmação (mitigação: medir no gate 10; elevar o `maxDuration` da função única `api/index.ts` em `vercel.json` (vale para todas as rotas, dentro do teto do plano Vercel); reabrir DEC-063-002 se não couber). **Medido (TASK-063-002)**: SHA-256 em streaming de 50 MiB lido de um MinIO local = 441 ms (`computeSha256Hex(readStream)`, teste de integração contra o MinIO). Ambiente local ≠ Vercel: o número é piso do custo real (sem latência de rede até o bucket nem CPU limitada da função). Limiar de 10 000 ms não atingido (441 ms ≤ 10 000 ms) → `maxDuration` mantido em 15 s em `vercel.json` (arquivo inalterado). O teto do plano Vercel do Diretor é desconhecido; o gate 10 remede na função real.
- **TRISK-063-004** Custo de egress do provedor com download repetido de PDFs e exportações (mitigação: recomendação de provedor sem egress; URLs de curta duração evitam compartilhamento; acompanhar o consumo).
- **TRISK-063-005** Teto de exportação de 500 MB é palpite não medido contra o navegador real (mitigação: configurável por env; medir com pacote real no gate 9 antes de fixar o default).
- **TRISK-063-006** Confirmação de chave alheia (resolvido pelo Tech Lead, 2026-10-18): a chave `pending/<userId>/<uuid>` vincula a intenção ao autor e a confirmação só é aceita do mesmo usuário; o risco residual de chave adivinhável é mitigado pelo uuid aleatório.

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Aderência à ficha/perfil validada
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates)
- [ ] Migração aditiva revisada e executada somente após autorização do Diretor; tipos de domínio idênticos nos dois repositórios
- [ ] Matriz `route-authz-matrix` muda apenas pelas rotas novas e a Exportação de PDF da Tira permanece igual (NFR-061-005)
- [ ] GUIA-DE-USO atualizado, com a data de "Última atualização"
- [ ] Métrica da SPEC operacional: instrumentação entregue e provada (gate 9 exibe o Registro de exportação `COMPLETED` existindo e contável após a data do deploy; `PENDING` não conta)

## 10. Não coberto por este PLAN

- Nenhum FR/NFR da SPEC-061 fica de fora. Fora de escopo por decisão da SPEC (§4.2): checkout/pagamento, integração por API com o marketplace, PDF gerado pelo sistema como Item, histórico de arquivos substituídos, pré-visualização, status de publicação, envio em lote, papel novo e re-download de exportações anteriores.
- Fora do porte deste PLAN: limpeza automática de `pending/` (TRISK-063-001), job/fila para exportação no servidor (DEC-063-003) e paginação (DEC-063-008).
