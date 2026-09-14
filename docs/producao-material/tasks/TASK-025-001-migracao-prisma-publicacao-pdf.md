# TASK-025-001: Migrar schema Prisma — `PUBLICACAO_PDF` (aditivo), `PublicationVariant`, `publication_events`

**Slug**: producao-material
**Pertence a**: PLAN-025
**Realiza (FRs)**: FR-024-010
**Componente**: COMP-025-004 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Done

```yaml
override-erros: task-criterio-sem-ac
override-justificativa: >-
  Migração de schema sem AC atribuído nesta wave (ac_gate vazio no manifesto de
  decomposição de PLAN-025) — sustenta FR-024-010 só parcialmente (a tabela
  existe; a emissão do evento e o AC-024-012 que a cobre são provados em
  TASK-025-008, que grava e lê `PublicationEvent`). Oráculo é o contrato do
  próprio item (regra 4.286). Mesmo padrão de TASK-023-001/TASK-012-001
  (migrações Done do mesmo slug, sem AC numerado).
override-aprovador: Tech Lead (autônomo, /keelson:auto)
```

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-025-008

## Contexto

Introduz no schema Prisma o valor aditivo `PUBLICACAO_PDF` de `ProductionStageType`, o
enum `PublicationVariant` e o model `PublicationEvent` (PLAN-025 §5) — sustentação de
dados pura para a orquestração de exportação de TASK-025-008, sem nenhum comportamento
observável por si só. Fatia sensível (migração, princípio 8) e setup-first (princípio
5): TASK-025-008 depende dos models existirem antes de gravar. Precedente de sintaxe e
território em `MAP.md` do slug e no diff já mergeado de TASK-023-001 (mesma classe de
migração 100% aditiva).

## Escopo

### Inclui

- `mnemonicos-backend/prisma/schema.prisma`: `enum ProductionStageType` ganha o 5º valor
  aditivo `PUBLICACAO_PDF` (mantendo `CONTEUDO_BRUTO`/`QUEBRA_DA_REGRA`/`TIRA_MNEMONICA`/
  `ASSOCIACAO_VISUAL` intocados, na mesma ordem) — mesmo precedente de sintaxe de
  `mnemonicos-backend/prisma/migrations/20260913174134_add_visual_association/migration.sql:1-2`.
- novo `enum PublicationVariant { TIRA RESUMO }` e `model PublicationEvent { id String
  @id @default(uuid(7)); rawContentId String; variant PublicationVariant; occurredAt
  DateTime @default(now()); @@index([occurredAt]); @@map("publication_events") }` — texto
  exato de PLAN-025 §5.
- gerar o arquivo de migração (`prisma migrate dev --create-only` ou equivalente) — a
  geração não aplica nada, não exige autorização prévia; **NUNCA aplicar** (`prisma
  migrate dev` completo) sem autorização explícita do Diretor, registrada antes do passo
  (regra do `CLAUDE.md` do workspace) — passo de aplicação marcado como pendência humana
  no Contexto, nunca simulado.
- rodar `npx prisma generate` após o schema editado — não altera banco, só o client TS
  (necessário para TASK-025-008 referenciar `tx.publicationEvent`).
- **[Furo no plano corrigido em voo, 2026-09-14]** `mnemonicos-backend/src/domain/types.ts`:
  `ProductionStageType`/`PRODUCTION_STAGE_TYPES` ganham o mesmo 5º valor aditivo
  `PUBLICACAO_PDF` (mesmo padrão de `TASK-023-001`, que fez o equivalente para
  `ASSOCIACAO_VISUAL` no mesmo arquivo) + ajuste mínimo correspondente em
  `tests/unit/domain-types-parity.test.ts` — sem isso, `npm run typecheck` quebra de
  verdade (`production-events.service.ts:96`, tipo Prisma de 5 valores vs. domínio de 4).
  A decomposição de PLAN-025 não havia repetido este passo do precedente de F5; achado
  empírico do developer, resolvido como "auxiliar necessário" (mesmo escopo mínimo do
  precedente), registrado no INDEX.

### Não inclui

- Aplicação real da migração em nenhum banco (dev/teste/produção) — ato do Diretor.
- Emissão do evento (TASK-025-008) e consulta de métrica (TASK-025-008).

## Critérios de pronto

- [ ] Schema válido — item do Inclui sem AC, oráculo é o contrato do próprio item (regra
      4.286). Verificação executável: baseline `npx prisma validate --schema=mnemonicos-backend/prisma/schema.prisma`
      rodado ANTES da edição (estado atual do schema) → exit 0; o MESMO comando rodado
      DEPOIS de acrescentar o valor de enum/enum novo/model novo → exit 0. Fixada antes do
      código. Falsificável: um erro de sintaxe no bloco novo (chave não fechada, tipo
      inexistente) faz o comando pós-edição sair não-zero.
- [ ] Migração 100% aditiva — verificação executável: `prisma migrate dev --create-only`
      gera o arquivo de migração; `grep -inE "DROP |ALTER (TABLE|TYPE)[^;]*DROP|ALTER COLUMN"
      <caminho-do-migration.sql-gerado>` → 0 ocorrências (grep sem match = critério passa).
      Falsificável (prova de que o padrão não é vazio por má-âncora): o MESMO grep rodado
      contra uma string de controle (`printf 'DROP TABLE foo;\n' | grep -inE "DROP |ALTER
      (TABLE|TYPE)[^;]*DROP|ALTER COLUMN"`) CASA a linha de controle (exit 0) — confirma que
      o padrão realmente pegaria um `DROP` se existisse no arquivo gerado.
- [ ] `PublicationVariant`/`PublicationEvent` existem no client Prisma gerado, exercitados
      com valor não-nulo — item do Inclui sem AC, oráculo do próprio item (regra 4.286),
      sem depender de aplicar a migração (`prisma generate` só lê `schema.prisma`, nunca o
      banco). Verificação executável: baseline `npm --prefix mnemonicos-backend run
      typecheck` ANTES desta TASK, contra um arquivo de teste type-only novo (ex.:
      `mnemonicos-backend/tests/unit/publication-event-prisma-types.test-d.ts` ou
      equivalente do perfil) que referencia `Prisma.PublicationVariant.TIRA` e o shape
      `{ rawContentId: string; variant: PublicationVariant; occurredAt: Date }` de
      `PublicationEvent` → falha (tipo inexistente); depois de `npx prisma generate` com o
      schema editado → o MESMO comando → exit 0. Falsificável: renomear `variant` para
      outro nome no schema faz esse arquivo de teste voltar a falhar a compilação.
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff, produção e teste — `git
      diff --name-only main...HEAD`).

## Riscos específicos

- Aplicação da migração exige autorização explícita do Diretor antes de `prisma migrate
  dev` (sem `--create-only`) — ato humano fora desta TASK; nenhum passo desta TASK simula
  ou pressupõe aplicação real em nenhum ambiente.
- TRISK-025-001 (`ALTER TYPE ... ADD VALUE` pode exigir commit intermediário antes de uso
  na mesma sessão) — a mitigação prescrita no PLAN (aplicar e testar a gravação logo em
  seguida; se recusado, dividir em 2 migrações) só é executável no momento em que a
  migração for de fato aplicada, fora do escopo desta TASK (Não inclui) — registrar para
  quem aplicar (Diretor, ou o passo que antecede TASK-025-008) não perder a mitigação de
  vista.
- Fatia sensível (migração, princípio 8): `security-engineer` (gate 8) revisa o diff
  completo desta TASK, ainda que pequeno.

---

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 2026-09-14T14:53:59-0300
**Data conclusão**: 2026-09-14T15:12:51-0300
**Commit SHA**: 696d6c3
**Jira**: KAN-108

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 1)
- [x] Comportamento (gate 9): consolidado (DoD, Etapa 4) — SPEC-024 sem FEATs
