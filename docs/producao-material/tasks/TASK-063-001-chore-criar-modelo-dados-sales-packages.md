# TASK-063-001: Criar o modelo de dados (migração aditiva `add_sales_packages`) e espelhar os tipos de domínio

**Slug**: producao-material
**Pertence a**: PLAN-063
**Realiza (FRs)**: nenhuma
**Componente**: COMP-063-002 (principal)
**Wave**: 1
**Tamanho estimado**: medium
**Tipo**: chore
**Status**: Done

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-063-003, TASK-063-004, TASK-063-007

## Contexto

Cria as quatro tabelas do domínio de Pacotes de PDF (migração aditiva `add_sales_packages`, DEC-063-004 do PLAN-063) e espelha à mão os tipos de domínio nos dois repositórios, mais o helper de paridade de interface que as TASKs de DTO (003, 004, 007, 008, 010) reusam. A migração foi **autorizada pelo Diretor para bancos locais de dev e de teste**; em produção, o `vercel-build` roda `prisma migrate deploy` no deploy, que é ato do Diretor e fica fora desta TASK. Território e decisões vigentes: memo `thoughts/local/sessions/20261018-005950-6ee912dc/exploration-producao-material.md` e `docs/producao-material/MAP.md`.

## Escopo

### Inclui
- `mnemonicos-backend/prisma/schema.prisma`:
  - modelos `LibraryPdf` (`@@map("library_pdfs")`), `SalesPackage` (`sales_packages`), `SalesPackageItem` (`sales_package_items`) e `SalesPackageExport` (`sales_package_exports`), mais o enum `ExportStatus` com os valores `PENDING` e `COMPLETED`;
  - relações reversas em `User`, nomeadas como a de `VisualAssociationAuthor` (schema.prisma:139 e 466);
  - FKs de autoria (`authorId` de `LibraryPdf` e de `SalesPackage`, mais `replacedById` e `exportedById`) com `onDelete: Restrict`, a política vigente de autoria (DEC-063-004, Consequências);
  - `LibraryPdf.disciplineId` com `SetNull` e `SalesPackage.disciplineId` com a mesma política, por simetria;
  - `SalesPackageItem`: `packageId` Cascade, `pdfId` Restrict, `@@unique([packageId, pdfId])` e `@@unique([packageId, position])`;
  - `SalesPackageExport`: `packageId` `SetNull`, `packageName` e `items Json`;
  - `sizeBytes Int`, `sha256 @db.Char(64)`, `legislativeClosureDate @db.Date`, `storageKey @unique`, `referencePriceCents Int`;
  - índices do PLAN-063 §5: `LibraryPdf(createdAt)`, `SalesPackage(createdAt)` e `SalesPackageExport(packageId, status, completedAt)`.
- `mnemonicos-backend/prisma/migrations/<AAAAMMDDHHMMSS>_add_sales_packages/migration.sql`, gerado por `prisma migrate dev` com timestamp posterior a `20261004120000_add_user_removed_at`.
- `mnemonicos-backend/src/domain/types.ts` e `mnemonicos-frontend/src/types/domain.ts`: `EXPORT_STATUSES` (`as const`), `ExportStatus` e `ExportItemSnapshot` (`position`, `title`, `version`, `legislativeClosureDate`, `sizeBytes`, `sha256`, `storageKey`), idênticos nos dois lados, com `position ≥ 1` documentado no docblock e `legislativeClosureDate` como string `AAAA-MM-DD`.
- `mnemonicos-backend/tests/unit/domain-types-parity.test.ts`: casos novos de `EXPORT_STATUSES` (backend × frontend × `enum ExportStatus` do schema.prisma) e dos campos de `ExportItemSnapshot`. Os extratores `extractConstArray` e `extractPrismaEnum` já existem no arquivo e são reusados.
- `mnemonicos-backend/tests/integration/sales-packages.model.integration.test.ts` (molde: `visual-associations.model.integration.test.ts`).
- `mnemonicos-backend/tests/support/interface-parity.ts` (novo; dono único): `readSourceFile(path)` e `extractInterfaceFields(source, interfaceName)`. Decisão: **extrair para este arquivo**, porque o extrator já está copiado em quatro testes de contrato (`tira-`, `contents-`, `visual-associations-` e `strategic-panel-frontend-contract.test.ts`) e as TASKs de DTO não devem redigitá-lo.
- `mnemonicos-backend/tests/unit/interface-parity.test.ts`: controles positivo e negativo do extrator.

### Não inclui
- Rota, service ou DTO de API: cada TASK de capacidade declara os seus.
- `mnemonicos-backend/tests/integration/db.ts`: o `resetDb` deriva as tabelas de `pg_tables` (db.ts:40-52), então tabela nova entra sozinha.
- CHECK de preço ≥ 0 no banco: a validação é Zod + service na TASK-063-007, sem SQL manual na migração.
- Reescrever as quatro cópias antigas de `extractInterfaceFields` (escopo mínimo).
- Executar a migração em produção.
**Inclui — herdado dos gates da wave 1 (retry, 2026-10-18):**
- `mnemonicos-backend/prisma/schema.prisma` (`@@index([pdfId])` em `SalesPackageItem`) + migração NOVA `mnemonicos-backend/prisma/migrations/<YYYYMMDDHHMMSS>_add_sales_package_item_pdf_index/migration.sql` (só `CREATE INDEX`) — gate 10; **autorizada pelo Diretor em 2026-10-18** para os bancos locais de dev e teste. A migração `20261018052625_add_sales_packages` NÃO é editada.
- `mnemonicos-backend/tests/support/interface-parity.ts` (+ `tests/unit/interface-parity.test.ts`) — paridade passa a comparar NOME e TEXTO DE TIPO de cada campo (decisão do Tech Lead, achado fora de escopo do gate 1).
- `mnemonicos-frontend/src/types/domain.ts` (docblock que aponta para si mesmo) e `mnemonicos-backend/tests/integration/sales-packages.model.integration.test.ts:8` (proveniência).

## Critérios de pronto

- [ ] O schema é válido e o client gerado expõe os quatro modelos — verificação executável: `npm --prefix mnemonicos-backend exec prisma validate` → exit 0 com a mensagem "is valid"; `npm --prefix mnemonicos-backend run db:generate` → exit 0. Falha se um modelo, relação nomeada ou enum estiver malformado.
- [ ] A migração é aditiva, nova e posterior a `20261004120000` — verificação executável: `git -C mnemonicos-backend diff --name-only <SHA-pai-da-TASK>..HEAD -- prisma/migrations` → lista exatamente um arquivo, `prisma/migrations/<AAAAMMDDHHMMSS>_add_sales_packages/migration.sql`, com o timestamp numericamente maior que `20261004120000`.
- [ ] Nenhuma instrução destrutiva na migração — verificação executável: `git -C mnemonicos-backend grep -ch -E '^CREATE TABLE' -- prisma/migrations/*_add_sales_packages/migration.sql` → `4` (controle positivo: prova que o glob resolve e que as quatro tabelas nascem); `git -C mnemonicos-backend grep -n -E '^[^-].*DROP' -- prisma/migrations/*_add_sales_packages/migration.sql` → saída vazia (a linha começa em caractere que não é comentário SQL). Critério de ausência conferido contra o commit-pai: o arquivo não existe lá, então a ocorrência só aparece se a TASK a introduzir.
- [ ] Pré-condição da integração: banco de teste sem outro runner — verificação executável: antes de cada execução de integração, `docker compose -f mnemonicos-backend/docker-compose.yml exec -T postgres psql -U postgres -d postgres -tAc "SELECT count(*) FROM pg_stat_activity WHERE datname = 'mnemonicos_test' AND pid <> pg_backend_pid()"` → `0` e nenhum processo `node`/`jest` órfão (lição `su-te-de-integra-o-com-ddl-truncate-em-banco-compartilhado-exige-exclusividade-real-entre-execu-es-concorrentes-n-o-s-runinband`: `--runInBand` não impede um segundo processo de truncar o mesmo `mnemonicos_test`). Resultado diferente de `0` invalida o verde ou o vermelho da execução seguinte.
- [ ] O modelo se comporta como a DEC-063-004 promete — verificação executável: `npm --prefix mnemonicos-backend run test:integration -- tests/integration/sales-packages.model.integration.test.ts` → `Tests: N passed`, 0 failed, N > 0, com estes casos, cada um com valores distintos entre as linhas semeadas:
  - P2002 em `(packageId, pdfId)` (com `position` diferente), em `(packageId, position)` (com PDFs diferentes) e em `storageKey` duplicada de `LibraryPdf`; cada caso confere que a restrição violada é a esperada (nome da restrição na mensagem ou em `meta`, conferido no baseline contra o erro real);
  - Restrict de `LibraryPdf` com Item: o oráculo primário é o par **rejeição + linhas sobrevivem** (o `LibraryPdf` e o Item seguem legíveis); `err.code` nunca é a asserção primária, porque `onDelete: Restrict` levanta SQLSTATE 23001 e o adapter-pg o devolve como `P2039`, não `P2003` (`guidelines/project/backend/node-22.md:858`; precedente `visual-associations.model.integration.test.ts:70-100`);
  - Restrict das FKs de autoria: uma prova por FK (`LibraryPdf.authorId`, `LibraryPdf.replacedById`, `SalesPackage.authorId`, `SalesPackageExport.exportedById`), cada uma apagando o `User` referenciado e provando rejeição + linha sobrevivente;
  - Cascade: apagar o `SalesPackage` apaga seus Itens (contagem de Itens 0) e mantém os dois `LibraryPdf` referenciados;
  - SetNull do Export: apagar o `SalesPackage` deixa o `SalesPackageExport` com `packageId` nulo, `packageName` e `items` iguais aos semeados (dois Itens com `position` 1 e 2, `title`/`version`/`sha256` distintos), nos status `PENDING` e `COMPLETED`;
  - SetNull de `disciplineId`: apagar a `Discipline` deixa o `LibraryPdf` com `disciplineId` nulo;
  - `sha256 @db.Char(64)`: valor de 64 caracteres persiste íntegro; valor de 65 caracteres é rejeitado;
  - `items Json` volta igual ao semeado (os sete campos de `ExportItemSnapshot`, `position` ≥ 1).
- [ ] `legislativeClosureDate` não sofre deslocamento de fuso — verificação executável: `TZ=America/Sao_Paulo npm --prefix mnemonicos-backend run test:integration -- tests/integration/sales-packages.model.integration.test.ts` e `TZ=Pacific/Auckland npm --prefix mnemonicos-backend run test:integration -- tests/integration/sales-packages.model.integration.test.ts` → ambos `N passed`, 0 failed; o caso de round-trip grava `'2026-10-18'` e `'2026-12-31'` e relê `'2026-10-18'` e `'2026-12-31'` (inclusive por `SELECT "legislativeClosureDate"::text` via `$queryRaw`). Falha se a escrita ou a leitura passar por conversão em hora local.
- [ ] Os enums e a forma espelhada estão idênticos nos dois repositórios — verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/domain-types-parity.test.ts` → `N passed`, N > 0, com `EXPORT_STATUSES` igual a `['PENDING', 'COMPLETED']` nas três fontes (valor literal um a um, não só "contém") e `ExportItemSnapshot` com exatamente `['position', 'title', 'version', 'legislativeClosureDate', 'sizeBytes', 'sha256', 'storageKey']` nos dois lados, lidos pelo teste (lição `coment-rio-que-afirma-paridade-entre-os-dois-repos-s-vale-se-o-teste-ler-as-duas-fontes`: o teste lê as duas fontes, nunca um fixture montado de um lado só).
- [ ] Mutantes de paridade e de política de FK, em worktrees — verificação executável: monte um par de worktrees com os mesmos nomes de pasta dos repos, `git -C mnemonicos-backend worktree add <TMP>/mnemonicos-backend HEAD` e `git -C mnemonicos-frontend worktree add <TMP>/mnemonicos-frontend HEAD`, com `node_modules` ligado por symlink (os testes leem `../mnemonicos-frontend` pelo `__dirname`, então os nomes de pasta precisam bater); nunca edite a árvore principal. (a) acrescentar `'FAILED'` a `EXPORT_STATUSES` só no worktree do frontend → `npm --prefix <TMP>/mnemonicos-backend test -- tests/unit/domain-types-parity.test.ts` sai vermelho; (b) renomear `sha256` para `digest` em `ExportItemSnapshot` só no backend → o mesmo comando sai vermelho; (c) trocar `ON DELETE RESTRICT` por `ON DELETE CASCADE` na FK `pdfId` de `sales_package_items` no `migration.sql` do worktree do backend → `npm --prefix <TMP>/mnemonicos-backend run test:integration -- tests/integration/sales-packages.model.integration.test.ts` sai vermelho. O global-setup só roda `migrate deploy` num `mnemonicos_test` persistente — e esse banco é **compartilhado** com outra sessão (KAN-237), então ele nunca é dropado nem recriado (ajuste do Tech Lead, 2026-10-18, após o classificador negar o `DROP DATABASE`): o mutante (c) roda num **banco descartável próprio**. No worktree do backend (harness de mutação, nunca a árvore principal), troque o nome-alvo `mnemonicos_test` por `mnemonicos_test_mut063` em `tests/integration/db-url.ts` (default e guarda fail-closed) e em `tests/integration/global-setup.ts` (`TEST_DB_NAME`), aplique o mutante RESTRICT→CASCADE no `migration.sql` do worktree e rode `npm --prefix <TMP>/mnemonicos-backend run test:integration -- tests/integration/sales-packages.model.integration.test.ts` → exija o vermelho no caso "apagar um LibraryPdf com Item é rejeitado" (o global-setup cria `mnemonicos_test_mut063` do zero a partir do `migration.sql` mutado). Controle positivo: no mesmo worktree, com o `migration.sql` original e o alvo `mnemonicos_test_mut063b`, o mesmo comando sai verde. Ao final, `docker compose -f mnemonicos-backend/docker-compose.yml exec -T postgres psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS mnemonicos_test_mut063"` (e `_mut063b`) — se o harness negar o drop desses bancos descartáveis, deixe-os e declare no report (limpeza vira pendência do Diretor); o `mnemonicos_test` compartilhado não é tocado em nenhum passo. Remova os worktrees ao final.
- [ ] O helper de paridade tem controle positivo e negativo obrigatórios — verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/interface-parity.test.ts` → `N passed`, N > 0, com estes casos (lição `extrator-textual-de-c-digo-para-prova-estrutural-precisa-de-controle-positivo-obrigat-rio-e-o-conserto-precisa-varrer-a-classe-ast-n-o-s-a-inst-ncia-que-quebrou`): (1) interface existente devolve a lista exata de campos, com valores não vazios; (2) interface ausente lança; (3) interface com campo extra num lado é detectada por diferença de conjuntos; (4) interface com campo de tipo objeto inline aninhado **lança** com mensagem que cita o contrato flat, em vez de devolver o corpo errado; (5) `readSourceFile` lança para caminho inexistente. Mutante em worktree: `extractInterfaceFields` devolvendo `[]` → o caso (1) sai vermelho; remover a checagem de aninhamento → o caso (4) sai vermelho.
- [ ] Nenhum export especulativo no helper — verificação executável: `git -C mnemonicos-backend grep -ch -E '^export ' -- tests/support/interface-parity.ts` → `2` (`readSourceFile` e `extractInterfaceFields`; lição `lista-de-interface-p-blica-do-plan-contrato-m-nimo-n-o-gabarito-de-transcri-o`: os símbolos do manifesto são contrato mínimo, e o arquivo é comparado com o irmão canônico `visual-associations-frontend-contract.test.ts` antes do commit).
- [ ] O extrator não é redefinido por nenhum arquivo novo ou alterado em `tests/` (lição `corre-o-de-duplica-o-dry-introduz-nova-re-deriva-o-do-can-nico-no-mesmo-diff`) — verificação executável: `cd mnemonicos-backend && git diff --name-only --diff-filter=AM <SHA-pai-da-TASK>..HEAD -- tests | xargs grep -l -E '^(export )?function extractInterfaceFields'` → exatamente `tests/support/interface-parity.ts`, e nenhum outro (condição sobre o universo real do diff, controle positivo incluso).
- [ ] As quatro cópias antigas do extrator ficam intocadas (escopo mínimo) — verificação executável: `git -C mnemonicos-backend diff --name-only <SHA-pai-da-TASK>..HEAD -- tests/unit/tira-frontend-contract.test.ts tests/unit/contents-frontend-contract.test.ts tests/unit/visual-associations-frontend-contract.test.ts tests/unit/strategic-panel-frontend-contract.test.ts` → saída vazia; o range ancora no commit-pai e os quatro arquivos existem lá (conferido por Glob na fixação), então o vazio é possível e é prova de escopo, não de comportamento.
- [ ] Os dois repos compilam e passam format — verificação executável: `npm --prefix mnemonicos-backend run typecheck` e `npm --prefix mnemonicos-frontend run typecheck` → exit 0 (o `tsconfig.json` do backend inclui `tests/**/*.ts` e `prisma/**/*.ts`, então os arquivos novos estão no alcance); `npm --prefix mnemonicos-backend run format:check` e `npm --prefix mnemonicos-frontend run format:check` → exit 0 (lição `entrega-roda-format-check-nos-arquivos-tocados-alem-de-lint-e-jest`, em observação, aplicada como critério).
- [ ] Sem regressão nas suítes completas — verificação executável: `npm --prefix mnemonicos-backend test` e `npm --prefix mnemonicos-backend run test:integration` → `0 failed` em ambos e contagem de testes passando ≥ o baseline capturado pelo developer antes de começar (a matriz de autorização de rotas segue em 53 pares: esta TASK não cria rota).
- [ ] Sem warnings/lints novos em todos os arquivos do diff, produção e teste — verificação executável: `npm --prefix mnemonicos-backend run lint` e `npm --prefix mnemonicos-frontend run lint` → exit 0, 0 warnings (o `eslint .` cobre `tests/` e `prisma/`).
### Critérios herdados dos gates da wave 1 (retry)
- [ ] **Índice em `sales_package_items.pdfId` (gate 10)** — `@@index([pdfId])` em `SalesPackageItem`; migração nova gerada por `npm --prefix mnemonicos-backend exec prisma migrate dev -- --name add_sales_package_item_pdf_index` (autorizada). Verificação: `git -C mnemonicos-backend diff --name-only <SHA-pai-do-retry>..HEAD -- prisma/migrations` lista exatamente 1 arquivo novo `…_add_sales_package_item_pdf_index/migration.sql`; `grep -c '^CREATE INDEX' <esse arquivo>` → `1` e `grep -cE '^(DROP|ALTER)' <esse arquivo>` → `0`; a migração `20261018052625_add_sales_packages/migration.sql` sem diff (`git -C mnemonicos-backend diff --quiet <SHA-pai-do-retry>..HEAD -- prisma/migrations/20261018052625_add_sales_packages` exit 0); teste de integração (em `sales-packages.model.integration.test.ts`) consulta `pg_indexes` e acha um índice em `sales_package_items` cuja `indexdef` cobre só `("pdfId")` → verde; mutante (em worktree, banco descartável próprio como no item (c)) sem o `CREATE INDEX` → esse caso reprova.
- [ ] **Paridade por nome E tipo (CONDIÇÃO: todo par de interfaces espelhadas comparado pelo helper confere o texto de tipo normalizado de cada campo)** — `extractInterfaceFields` (ou função irmã no mesmo arquivo, mantendo o teto de exports declarado na TASK ou atualizando-o aqui) devolve `nome: tipo` normalizado (espaços colapsados, `;`/`,` finais removidos). Verificação: `tests/unit/interface-parity.test.ts` ganha o caso "mesmos nomes, tipo diferente (`sizeBytes: number` × `sizeBytes: string`) → divergência reportada" e o caso "Date × string → divergência"; `domain-types-parity.test.ts` segue verde com o par real `ExportItemSnapshot`. Mutante (em worktree): comparação voltando a só-nome → os 2 casos novos reprovam.
- [ ] **Higiene** — docblock do espelho FE (`src/types/domain.ts`, ~:539) aponta para `mnemonicos-backend/src/domain/types.ts` (convenção do arquivo); `sales-packages.model.integration.test.ts:8` sem `TASK-063-001 /` (mantém DEC-063-004).
- [ ] **Commit do retry** cita no corpo os gates e achados que fecha (gate 10 índice; gate 1 paridade por tipo; gate 7 comentários).

## Riscos específicos

- A migração altera banco: a autorização do Diretor cobre só bancos locais de dev e de teste. Qualquer outro alvo (preview, produção) exige nova pergunta antes de executar.
- `onDelete: Restrict` não gera `P2003` neste driver (SQLSTATE 23001 → `P2039`); critério que fixe `P2003` reprovaria código correto.
- O banco `mnemonicos_test` tem nome fixo e é compartilhado por qualquer runner da máquina; verde ou vermelho de integração só vale com a pré-condição de exclusividade conferida.
- O extrator textual assume interface flat; um DTO com objeto inline aninhado precisa virar interface nomeada própria (regra repetida nas TASKs 003, 004, 007, 008 e 010).

---

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 2026-10-18T02:19:39-0300
**Data conclusão**: 2026-10-18T08:12:11-03:00
**Commit SHA**: 09ac538 (BE) · 28170c9 (FE)
**Jira**: KAN-248

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 1; delta do retry aprovado)
- [x] Comportamento (gate 9): n/a — chore de fundação sem efeito observável (FEAT-061-001 verificada no fecho da TASK-063-006)
