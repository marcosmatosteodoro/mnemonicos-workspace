# TASK-031-001: Migração — colunas de aprovação (`approvedById`/`approvedAt`) e valor `APROVACAO_VERSAO`

**Slug**: producao-material
**Pertence a**: PLAN-031
**Realiza (FRs)**: nenhuma
**Componente**: COMP-031-001
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Todo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-031-003, TASK-031-005

## Contexto

Habilita, no schema Prisma, o estado de aprovação de `ContentVersion` — 2 colunas nullable
na MESMA linha (DEC-031-004, nunca uma tabela 1:1 separada) e o valor aditivo
`APROVACAO_VERSAO` do mecanismo de instrumentação de etapas (F3) — pré-requisito estrutural
das TASKs de capacidade das Waves 2/3 (aprovação em TASK-031-003, carimbo no PDF em
TASK-031-005), setup-first (princípio 5). Toda Versão nasce sempre não aprovada
(`approvedById: null`) porque nenhuma escrita de `closeContentVersion` (F8, intocado) toca
essas 2 colunas — FR-030-006 (não-propagação) fica satisfeito estruturalmente por esta
TASK, mesmo sem AC próprio aqui (a leitura que prova o comportamento observável vive em
TASK-031-004). Território e precedentes: `docs/producao-material/MAP.md` e PLAN-031 §3
(COMP-031-001), §5 (modelo de dados), §6 (DEC-031-004).

## Escopo

### Inclui

- `mnemonicos-backend/prisma/schema.prisma`:
  - `enum ProductionStageType`: novo valor aditivo `APROVACAO_VERSAO`, comentário em linha
    própria ACIMA do valor (nunca colado a ele — mesma convenção de `VERSAO_EDITORIAL`/
    `MATERIAL_REFORCO`, exigida por `extractPrismaEnum`/`domain-types-parity.test.ts`),
    mantendo os 7 valores existentes intocados e na mesma ordem.
  - `model ContentVersion` ganha, ao final do model (depois de `contentSnapshot`), forma
    literal do PLAN-031 §5:
    ```prisma
    /// NOVO (F9, DEC-031-004): estado de aprovação — colunas na MESMA linha, não uma
    /// tabela 1:1 separada. `null` = ainda não aprovada (estado inicial de toda Versão
    /// recém-fechada, FR-030-006). Nunca sobrescrito depois de setado uma vez
    /// (FR-030-005) — a garantia é o `updateMany` condicional em `approveContentVersion`
    /// (TASK-031-003), não a ausência de coluna de update.
    approvedById String?
    approver     User?     @relation("ContentVersionApprover", fields: [approvedById], references: [id], onDelete: Restrict)
    approvedAt   DateTime?
    ```
    Ambas nullable — nenhuma migração de dado existente necessária. **Sem**
    `legalCheckConfirmed`/`pedagogicalCheckConfirmed` (DEC-031-005: a existência de
    `approvedById`/`approvedAt` não-nulos já É a prova de que as 2 confirmações
    ocorreram).
  - `model User`: relação reversa nova `contentVersionApprovals ContentVersion[]
    @relation("ContentVersionApprover")` — nome de relação explícito (distinto do
    `contentVersions ContentVersion[]` já existente, que é a relação `author`/default):
    `User` passa a ter 2 relações com `ContentVersion`, exigindo desambiguação nos dois
    lados (mesmo padrão de `RawContentAuthor`/`RawContentLastEditor`).
- Migração Prisma nova via `prisma migrate dev --create-only` (a geração não aplica nada) —
  1 diretório novo em `prisma/migrations/`: `ALTER TYPE "ProductionStageType" ADD VALUE
  'APROVACAO_VERSAO'`, 2× `ALTER TABLE "content_versions" ADD COLUMN` (`approvedById`
  nullable, `approvedAt` nullable), 1× `ADD CONSTRAINT` (FK `approvedById` → `users.id`,
  `ON DELETE RESTRICT`) — texto exato já no PLAN-031 §3/§5, nenhum `DROP`/`ALTER`
  destrutivo. **Aplicar exige autorização do Diretor** (mesmo protocolo de
  TASK-023-001/TASK-025-001/TASK-027-001/TASK-029-001) — passo explícito do
  `/keelson:implement` (`AskUserQuestion`), nunca aplicado em produção por esta TASK.
- `mnemonicos-backend/tests/integration/content-version-approval.model.integration.test.ts`
  (novo, molde `content-version.model.integration.test.ts` de TASK-029-001): monta a cadeia
  `Topic`/`User`(2, um autor e um aprovador)/`RawContent` via
  `tests/support/production-events-fixtures.ts` (existente, sem alteração), cria 1
  `ContentVersion` sem aprovação (`approvedById`/`approvedAt` ausentes do `data`) e lê de
  volta confirmando os 2 campos `null` por padrão (FR-030-006 estrutural); 2º caso:
  `testPrisma.contentVersion.update` setando `approvedById`/`approvedAt` para o 2º `User`
  e lê de volta confirmando os 2 valores persistidos e o relacionamento `approver`
  navegável (`include: { approver: true }`).

### Não inclui

- Interface TS `ContentVersion` estendida (backend/frontend) — TASK-031-006.
- `content-versions.schema.ts`/`.service.ts`/`.routes.ts` (`approveContentVersion`,
  `resolveAlterationSignal`, rota `/approve`) — TASK-031-002/003.
- Qualquer extensão de `publication.service.ts`/`pdf-composer.ts` — TASK-031-005.
- Aplicação da migração em produção.

## Critérios de pronto

- [ ] Schema contém os elementos novos — item do Inclui sem AC isolado (chore habilitador,
      sem `Realiza (FRs)`), oráculo é o contrato do próprio schema. Verificação executável:
      `npm --prefix mnemonicos-backend run db:generate` → exit 0; leitura de
      `schema.prisma` confirmando o comentário do valor `APROVACAO_VERSAO` em linha
      própria acima dele (nunca colado), `onDelete: Restrict` na FK nova
      (`ContentVersion.approver`), e a nulabilidade de `approvedById`/`approvedAt` —
      comando literal (universo = só o corpo do model, mesma técnica de TASK-029-001):
      `sed -n '/^model ContentVersion {/,/^}/p' mnemonicos-backend/prisma/schema.prisma |
      grep -E 'approvedById String\?|approvedAt   DateTime\?|onDelete: Restrict'` (a partir
      da raiz do workspace) → 3 ocorrências. Fixada antes do código.
- [ ] Migração aditiva — verificação executável: leitura do `migration.sql` gerado
      confirmando só `ALTER TYPE ... ADD VALUE`/`ALTER TABLE ... ADD COLUMN`/`ADD
      CONSTRAINT`. Falsificável: qualquer `DROP`/`ALTER COLUMN` presente no SQL gerado
      reprova o critério.
- [ ] Smoke test do modelo de dados — item do Inclui sem AC (chore habilitador), oráculo é
      o contrato do próprio schema: verificação executável: `npm --prefix
      mnemonicos-backend run test:integration --
      --testPathPatterns=content-version-approval.model` → `OK (N tests)`, incluindo (a) o
      caso "nasce não aprovada" (2 campos `null`) e (b) o caso de aprovação persistida com
      `approver` navegável pela relação nomeada.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npm --prefix mnemonicos-backend run lint` → exit 0.

## Riscos específicos

- TRISK-031-003 (PLAN §8) — `onDelete: Restrict` na FK `approvedById → User` bloqueia
  hard-delete de um ADMIN que já aprovou alguma Versão, enquanto essa Versão existir;
  aceito nesta fatia (herda RISK-028-005), fica para a fatia futura que definir expurgo.
  Nenhum código desta TASK tenta expurgo.
- `ALTER TYPE ... ADD VALUE` do Postgres não pode ser lido/escrito na MESMA transação em
  que é adicionado — mesma mitigação já aplicada em `VERSAO_EDITORIAL`/`MATERIAL_REFORCO`
  (o valor só é referenciado pelo código depois da migração aplicada num deploy anterior);
  nenhum código desta TASK grava `APROVACAO_VERSAO` na mesma transação da migração.
- Fatia sensível (migração, princípio 8): `security-engineer` (gate 8) revisa o diff
  completo, inclusive a FK `Restrict` nova.
- Autorização do Diretor para aplicar a migração é ato humano fora desta TASK — o
  `/keelson:implement` escala via `AskUserQuestion` antes do 1º passo que aplica.
- Lição ativa "[Dados/Persistência] FK `onDelete: Restrict` no Postgres não gera `P2003` —
  SQLSTATE `23001`, não `23503`" — se alguma TASK futura provar bloqueio desta FK, o
  oráculo é o par comportamental (rejeita + linha sobrevive), nunca fixar
  `err.code === 'P2003'`.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**:

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
