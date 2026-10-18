# TASK-063-001: Criar o modelo de dados (migração aditiva `add_sales_packages`) e espelhar os tipos de domínio

**Slug**: producao-material
**Pertence a**: PLAN-063
**Realiza (FRs)**: nenhuma
**Componente**: COMP-063-002 (principal)
**Wave**: 1
**Tamanho estimado**: medium
**Tipo**: chore
**Status**: Todo

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
- [ ] Mutantes de paridade e de política de FK, em worktrees — verificação executável: monte um par de worktrees com os mesmos nomes de pasta dos repos, `git -C mnemonicos-backend worktree add <TMP>/mnemonicos-backend HEAD` e `git -C mnemonicos-frontend worktree add <TMP>/mnemonicos-frontend HEAD`, com `node_modules` ligado por symlink (os testes leem `../mnemonicos-frontend` pelo `__dirname`, então os nomes de pasta precisam bater); nunca edite a árvore principal. (a) acrescentar `'FAILED'` a `EXPORT_STATUSES` só no worktree do frontend → `npm --prefix <TMP>/mnemonicos-backend test -- tests/unit/domain-types-parity.test.ts` sai vermelho; (b) renomear `sha256` para `digest` em `ExportItemSnapshot` só no backend → o mesmo comando sai vermelho; (c) trocar `ON DELETE RESTRICT` por `ON DELETE CASCADE` na FK `pdfId` de `sales_package_items` no `migration.sql` do worktree do backend → `npm --prefix <TMP>/mnemonicos-backend run test:integration -- tests/integration/sales-packages.model.integration.test.ts` sai vermelho. O global-setup só roda `migrate deploy` num `mnemonicos_test` persistente, então o mutante (c) sobreviveria a um banco já migrado: **antes** de rodar o mutante, com o banco exclusivo (pré-condição acima), execute `docker compose -f mnemonicos-backend/docker-compose.yml exec -T postgres psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS mnemonicos_test"` para o global-setup recriar o banco do `migration.sql` mutado, e exija o vermelho; **depois** do mutante, repita o `DROP DATABASE` (via `-d postgres`) e confirme que a execução seguinte, no `migration.sql` original, recria o banco limpo e sai verde. Remova os worktrees ao final.
- [ ] O helper de paridade tem controle positivo e negativo obrigatórios — verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/interface-parity.test.ts` → `N passed`, N > 0, com estes casos (lição `extrator-textual-de-c-digo-para-prova-estrutural-precisa-de-controle-positivo-obrigat-rio-e-o-conserto-precisa-varrer-a-classe-ast-n-o-s-a-inst-ncia-que-quebrou`): (1) interface existente devolve a lista exata de campos, com valores não vazios; (2) interface ausente lança; (3) interface com campo extra num lado é detectada por diferença de conjuntos; (4) interface com campo de tipo objeto inline aninhado **lança** com mensagem que cita o contrato flat, em vez de devolver o corpo errado; (5) `readSourceFile` lança para caminho inexistente. Mutante em worktree: `extractInterfaceFields` devolvendo `[]` → o caso (1) sai vermelho; remover a checagem de aninhamento → o caso (4) sai vermelho.
- [ ] Nenhum export especulativo no helper — verificação executável: `git -C mnemonicos-backend grep -ch -E '^export ' -- tests/support/interface-parity.ts` → `2` (`readSourceFile` e `extractInterfaceFields`; lição `lista-de-interface-p-blica-do-plan-contrato-m-nimo-n-o-gabarito-de-transcri-o`: os símbolos do manifesto são contrato mínimo, e o arquivo é comparado com o irmão canônico `visual-associations-frontend-contract.test.ts` antes do commit).
- [ ] O extrator não é redefinido por nenhum arquivo novo ou alterado em `tests/` (lição `corre-o-de-duplica-o-dry-introduz-nova-re-deriva-o-do-can-nico-no-mesmo-diff`) — verificação executável: `cd mnemonicos-backend && git diff --name-only --diff-filter=AM <SHA-pai-da-TASK>..HEAD -- tests | xargs grep -l -E '^(export )?function extractInterfaceFields'` → exatamente `tests/support/interface-parity.ts`, e nenhum outro (condição sobre o universo real do diff, controle positivo incluso).
- [ ] As quatro cópias antigas do extrator ficam intocadas (escopo mínimo) — verificação executável: `git -C mnemonicos-backend diff --name-only <SHA-pai-da-TASK>..HEAD -- tests/unit/tira-frontend-contract.test.ts tests/unit/contents-frontend-contract.test.ts tests/unit/visual-associations-frontend-contract.test.ts tests/unit/strategic-panel-frontend-contract.test.ts` → saída vazia; o range ancora no commit-pai e os quatro arquivos existem lá (conferido por Glob na fixação), então o vazio é possível e é prova de escopo, não de comportamento.
- [ ] Os dois repos compilam e passam format — verificação executável: `npm --prefix mnemonicos-backend run typecheck` e `npm --prefix mnemonicos-frontend run typecheck` → exit 0 (o `tsconfig.json` do backend inclui `tests/**/*.ts` e `prisma/**/*.ts`, então os arquivos novos estão no alcance); `npm --prefix mnemonicos-backend run format:check` e `npm --prefix mnemonicos-frontend run format:check` → exit 0 (lição `entrega-roda-format-check-nos-arquivos-tocados-alem-de-lint-e-jest`, em observação, aplicada como critério).
- [ ] Sem regressão nas suítes completas — verificação executável: `npm --prefix mnemonicos-backend test` e `npm --prefix mnemonicos-backend run test:integration` → `0 failed` em ambos e contagem de testes passando ≥ o baseline capturado pelo developer antes de começar (a matriz de autorização de rotas segue em 53 pares: esta TASK não cria rota).
- [ ] Sem warnings/lints novos em todos os arquivos do diff, produção e teste — verificação executável: `npm --prefix mnemonicos-backend run lint` e `npm --prefix mnemonicos-frontend run lint` → exit 0, 0 warnings (o `eslint .` cobre `tests/` e `prisma/`).

## Riscos específicos

- A migração altera banco: a autorização do Diretor cobre só bancos locais de dev e de teste. Qualquer outro alvo (preview, produção) exige nova pergunta antes de executar.
- `onDelete: Restrict` não gera `P2003` neste driver (SQLSTATE 23001 → `P2039`); critério que fixe `P2003` reprovaria código correto.
- O banco `mnemonicos_test` tem nome fixo e é compartilhado por qualquer runner da máquina; verde ou vermelho de integração só vale com a pré-condição de exclusividade conferida.
- O extrator textual assume interface flat; um DTO com objeto inline aninhado precisa virar interface nomeada própria (regra repetida nas TASKs 003, 004, 007, 008 e 010).

---

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
**Jira**: KAN-248

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
