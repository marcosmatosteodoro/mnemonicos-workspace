# TASK-012-001: Migrar schema — `MnemonicStrip`/`MnemonicFrame` + `TIRA_MNEMONICA` aditivo

**Slug**: producao-material
**Pertence a**: PLAN-012
**Realiza (FRs)**: nenhuma
**Componente**: COMP-012-001 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — `git.branchStrategy: unica`; não criar branch por task; a closure commita TASK a TASK)
**Padrão de commit**: Conventional Commits (`feat:` — schema/migração introduz capacidade nova, mesmo padrão de TASK-010-001)
**Framework de teste**: Jest 30 + ts-jest (`npm --prefix mnemonicos-backend test` / `npm --prefix mnemonicos-backend run test:integration`)

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-012-004, TASK-012-005

## Contexto

Fatia sensível (migração — princípio 8): acrescenta ao `schema.prisma` os 2 models novos da
Tira mnemônica (`MnemonicStrip` 1:1 `RuleBreakdown`, `MnemonicFrame` N:1) e o valor aditivo
`TIRA_MNEMONICA` no enum `ProductionStageType` já existente (`schema.prisma:69-75`, que já
previa esta extensão em comentário desde PLAN-010). Setup-first (princípio 5): TASK-012-004
(espelho de tipos backend) e TASK-012-005 (regra de negócio de abertura) dependem dos models
e do valor de enum existirem. Sem enforcement de comportamento — schema é fundação de
FR-011-001/002/003/005/006/010 e NFR-011-002/004/006, mas quem os realiza de fato são as
tasks de serviço seguintes (§7 do PLAN). **Migração exige autorização do Diretor antes de
gerar/aplicar** (protocolo do `CLAUDE.md` do workspace e `node-22.md` §11/12 — mesma régua já
seguida em TASK-006-001/TASK-010-001) — passo explícito do `/keelson:implement`
(`AskUserQuestion`), não decidido por esta TASK.

## Escopo

### Inclui

- `mnemonicos-backend/prisma/schema.prisma`:
  - `enum ProductionStageType` ganha o 3º valor aditivo `TIRA_MNEMONICA` (mantendo
    `CONTEUDO_BRUTO`/`QUEBRA_DA_REGRA` intocados, na mesma ordem):
    ```prisma
    enum ProductionStageType {
      CONTEUDO_BRUTO
      QUEBRA_DA_REGRA
      TIRA_MNEMONICA
    }
    ```
  - `model MnemonicStrip` novo — 1:1 com `RuleBreakdown` via `ruleBreakdownId String @unique`,
    `onDelete: Cascade`, relação `frames MnemonicFrame[]`, `createdAt`/`updatedAt`,
    `@@map("mnemonic_strips")` — forma literal do §5 de PLAN-012 (DEC-012-001).
  - `model MnemonicFrame` novo — N:1 com `MnemonicStrip` via `stripId String`,
    `onDelete: Cascade`, campos `text String`, `position Int`,
    `originBlock String?` (nullable, texto livre — DEC-012-004), `createdAt`/`updatedAt`,
    `@@unique([stripId, position])` (defesa em profundidade — DEC-012-002),
    `@@map("mnemonic_frames")` — forma literal do §5 de PLAN-012.
  - Relação reversa aditiva em `model RuleBreakdown` (`schema.prisma:333-350`):
    `strip MnemonicStrip?`.
  - `model Mnemonic` (`schema.prisma:180-204`) **não é tocado** — nenhuma linha alterada
    (A-011-007, RISK-011-001, DEC-012-010).
- Migração aditiva gerada via `prisma migrate dev` (autorização do Diretor obtida antes de
  gerar/aplicar) — 1 novo diretório em `mnemonicos-backend/prisma/migrations/` (nome
  derivado por timestamp na geração): 2 `CREATE TABLE` (`mnemonic_strips`,
  `mnemonic_frames`), 1 `ALTER TYPE "ProductionStageType" ADD VALUE 'TIRA_MNEMONICA'`,
  `ADD CONSTRAINT` (2 FKs `Cascade` + 1 unique simples `ruleBreakdownId` + 1 unique
  composto `[stripId, position]`) + índices implícitos das FKs. Nenhum `DROP`/`ALTER`
  destrutivo sobre tabela existente.
- 1 caso de teste novo (mitigação de TRISK-012-001 — `ALTER TYPE ... ADD VALUE` dentro de
  migração transacional pode exigir commit intermediário antes do uso na mesma sessão,
  dependendo da versão real do Postgres): acrescentado a
  `mnemonicos-backend/tests/integration/production-events.model.integration.test.ts`
  (molde já existente, TASK-010-001) — cria um `ProductionStageEvent` com
  `stageType: 'TIRA_MNEMONICA'` logo após a migração aplicar e lê o registro de volta na
  mesma sessão de teste.

### Não inclui

- Qualquer alteração em `Mnemonic.hook`/`decoding`/`source` (legado, A-011-007) — nem
  remoção física, nem migração de dado.
- Consumo dos models novos em código de serviço/rotas (`tira.service.ts`/`tira.routes.ts`)
  — TASK-012-005 e demais tasks de serviço, fora desta lista.
- Espelho de `TIRA_MNEMONICA` em `mnemonicos-backend/src/domain/types.ts`
  (`PRODUCTION_STAGE_TYPES`) — TASK-012-004, wave seguinte (depende desta).
- Divisão em 2 migrações sequenciais para contornar TRISK-012-001 — só se o caso de teste
  acima falhar de fato contra o Postgres real; se falhar, o achado é registrado em
  **Notas** da closure desta TASK, não decidido preventivamente aqui.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Acrescentar `TIRA_MNEMONICA` ao enum `ProductionStageType` (aditivo, mesma ordem).
2. Acrescentar os 2 models novos (`MnemonicStrip`, `MnemonicFrame`) com os comentários `///`
   que já documentam a intenção de cada campo no §5 de PLAN-012 (proveniência do
   `originBlock`, ausência de `deletedAt` própria herdando inalcançabilidade do pai).
3. Acrescentar a relação reversa `strip MnemonicStrip?` em `RuleBreakdown`.
4. Pedir autorização do Diretor (via `AskUserQuestion` no `/keelson:implement`) antes de
   `prisma migrate dev` — mesmo protocolo de TASK-006-001/TASK-010-001.
5. Após a migração aplicar contra `mnemonicos_test`, acrescentar o caso de
   `production-events.model.integration.test.ts` que grava e lê `stageType:
  'TIRA_MNEMONICA'` na mesma sessão — se o Postgres recusar, documentar o achado em
   Notas (TRISK-012-001 já prevê a mitigação de contingência no PLAN §8, não decidida
   preventivamente por esta TASK).

## Critérios de pronto

- [ ] `schema.prisma` contém os 2 models novos (`MnemonicStrip` com `ruleBreakdownId
      @unique`/`onDelete: Cascade`/`frames MnemonicFrame[]`; `MnemonicFrame` com `stripId`,
      `onDelete: Cascade`, `text`, `position`, `originBlock String?`,
      `@@unique([stripId, position])`), a relação reversa `strip MnemonicStrip?` em
      `RuleBreakdown`, e `TIRA_MNEMONICA` como 3º valor aditivo de `ProductionStageType`
      (sem remover nem reordenar `CONTEUDO_BRUTO`/`QUEBRA_DA_REGRA`) — item do Inclui sem
      AC, oráculo é o contrato do próprio schema. Verificação executável: `npm --prefix
      mnemonicos-backend run db:generate` → exit 0 (o Prisma Client só gera se o schema for
      válido); leitura do `schema.prisma` confirmando os 2 `@@map` e os 2 `onDelete:
      Cascade` novos. Fixada antes do código.
- [ ] Migração aditiva aplicada no banco de teste, sem `DROP`/`ALTER` destrutivo sobre
      tabela existente — autorização do Diretor obtida antes (fatia sensível). Verificação
      executável: `npm --prefix mnemonicos-backend run db:deploy` (contra
      `mnemonicos_test`) → exit 0; leitura do arquivo SQL gerado em
      `prisma/migrations/<novo diretório>/migration.sql` confirmando **só** `CREATE
      TABLE`/`ALTER TYPE ... ADD VALUE`/`ADD CONSTRAINT`/índice implícito de FK — nenhum
      `DROP`/`ALTER` sobre `raw_contents`/`rule_breakdowns`/`production_stage_events`/
      `mnemonics`. Falsificável: qualquer linha `DROP`/`ALTER COLUMN` no SQL gerado
      reprova o critério.
- [ ] Mitigação de TRISK-012-001 — `TIRA_MNEMONICA` gravável e legível no Postgres real na
      MESMA sessão em que a migração acabou de aplicar. Verificação executável: caso novo
      em `production-events.model.integration.test.ts` que, logo após `resetDb`/migração
      aplicada, executa `testPrisma.productionStageEvent.create({ data: { ...,
      stageType: 'TIRA_MNEMONICA', transitionType: 'ABERTURA' } })` e em seguida
      `findUniqueOrThrow` pelo mesmo `id` — comando: `npm --prefix mnemonicos-backend run
      test:integration -- production-events.model` → suíte verde, incluindo o caso novo
      (evidência de conjunto não-vazio: contagem de testes do arquivo cresce em +1 e todos
      passam). Falsificável: se o Postgres real recusar o valor novo na mesma sessão
      (restrição histórica de `ALTER TYPE ... ADD VALUE` não comitado), este caso fica
      vermelho — achado a registrar em **Notas** da closure (mitigação de contingência já
      nomeada em PLAN §8/TRISK-012-001: dividir em 2 migrações sequenciais), não decidido
      preventivamente por este critério.
- [ ] `model Mnemonic` (schema.prisma:180-204) permanece intocado (A-011-007,
      RISK-011-001, DEC-012-010) — verificação executável (ausência, contrato §273):
      `git diff main...HEAD -- mnemonicos-backend/prisma/schema.prisma | grep -c "model
      Mnemonic"` → `0`. Falsificável: qualquer alteração dentro do bloco do model legado
      (mesmo cosmética) faz o `grep` casar uma linha de contexto do diff unificado
      envolvendo o bloco, vermelho.
- [ ] Nenhuma FK `onDelete: Restrict` nova é introduzida por esta TASK — as 2 FKs novas
      (`MnemonicStrip.ruleBreakdown`, `MnemonicFrame.strip`) usam `Cascade`, mesmo padrão
      de `RuleBreakdown.rawContent` (schema.prisma:337) — confirmação cruzada contra a
      lição [Dados/Persistência] "FK `onDelete: Restrict` no Postgres não gera `P2003`"
      (não aplicável às 2 FKs desta TASK, mas confirmada por leitura, não presumida).
      Verificação executável: baseline capturada ANTES desta TASK tocar o arquivo —
      `grep -c "onDelete: Restrict" mnemonicos-backend/prisma/schema.prisma` no commit-pai
      → N; o MESMO comando depois do diff desta TASK → **o mesmo N** (nenhuma linha
      `Restrict` a mais). Falsificável: uma FK `Restrict` nova nesta TASK faz a contagem
      subir, vermelho.
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff — produção e teste, `git
      diff --name-only main...HEAD`).
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem (`node-22.md` §11/12 —
      migração com autorização do Diretor; Prisma 7 driver adapter).
- [ ] Code review aprovado.

## Riscos específicos

- Autorização do Diretor para gerar/aplicar a migração é um ato humano fora desta TASK — o
  `/keelson:implement` escala via `AskUserQuestion` antes do 1º passo que gera/aplica
  (mesmo protocolo de TASK-006-001/TASK-010-001).
- Fatia sensível (migração): `security-engineer` (gate 8) revisa o diff completo desta
  TASK, mesmo sem FK `Restrict` nova.
- TRISK-012-001: se o caso de teste de mitigação falhar contra o Postgres real, o achado
  vai para **Notas** da closure — a divisão em 2 migrações sequenciais (1ª só o `ADD
  VALUE`, 2ª os models que o referenciam) é a mitigação de contingência já nomeada no
  PLAN §8, não decidida preventivamente por este critério.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Branch**:
**Commit SHA**:
**Jira**: KAN-51
**Implementado por**:
**Revisado por**:
**Tentativas**:
**Cobertura final**:
**Arquivos modificados**:
  -

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>

**Notas**:
