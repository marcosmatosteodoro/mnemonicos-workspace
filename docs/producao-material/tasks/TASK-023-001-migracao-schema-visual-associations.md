# TASK-023-001: Migrar schema — `VisualAssociation`, FK em `MnemonicFrame`, `ASSOCIACAO_VISUAL` aditivo, `VisualAssociationLinkEvent`

**Slug**: producao-material
**Pertence a**: PLAN-023
**Realiza (FRs)**: FR-022-020
**Funcionalidade**: FEAT-022-003 (primária)
**Componente**: COMP-023-004 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch do EPICO MNEMORA STUDIO, Estrategia unica -- decisao 4.126: F5 e uma fatia do epico, nunca abre branch propria; a sessao ja fez o sync de largada nela)

**Padrão de commit**: Conventional Commits (`feat:` — schema/migração introduz capacidade nova, mesmo padrão de TASK-012-001/TASK-010-001).
**Framework de teste**: Jest 30 + ts-jest (`npm --prefix mnemonicos-backend test` / `npm --prefix mnemonicos-backend run test:integration`).

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-023-006, TASK-023-008

## Contexto

Fatia sensível (migração — princípio 8): acrescenta ao `schema.prisma` o model `VisualAssociation`
(F5), a FK nullable `MnemonicFrame.visualAssociationId` (`onDelete: SetNull`), o 4º valor
aditivo `ASSOCIACAO_VISUAL` em `ProductionStageType` (`schema.prisma:69-76` — o comentário
já anuncia "F5 biblioteca visual" desde PLAN-010) e o model `VisualAssociationLinkEvent` (log
de reuso, sem FK — DEC-023-011/TRISK-023-007). Setup-first (princípio 5): TASK-023-006
(storage do binário) e TASK-023-008 (vínculo, fora desta lista) dependem dos models e do
valor de enum existirem. Migração 100% aditiva — nenhuma coluna/tabela/valor de enum
existente é removida ou alterada (DEC-023-007). Gerar o arquivo de migração
(`--create-only`) não exige autorização prévia; **aplicar exige** (mesmo protocolo de
TASK-012-001/TASK-006-001) — passo explícito do `/keelson:implement` (`AskUserQuestion`),
não decidido por esta TASK.

## Escopo

### Inclui

- `mnemonicos-backend/prisma/schema.prisma`:
  - `enum ProductionStageType` (linhas 69-76) ganha o 4º valor aditivo `ASSOCIACAO_VISUAL`
    (mantendo `CONTEUDO_BRUTO`/`QUEBRA_DA_REGRA`/`TIRA_MNEMONICA` intocados, na mesma
    ordem).
  - `model VisualAssociation` novo — `authorId String` + `author User
    @relation("VisualAssociationAuthor", fields: [authorId], references: [id], onDelete:
    Restrict)` (mesmo padrão de `RawContent.authorId`/`RawContentAuthor`, DEC-006-008),
    `category String`, `cognitiveDescription String`, `imageData Bytes`, `mimeType String`,
    `createdAt`/`updatedAt`, `frames MnemonicFrame[]`, `@@map("visual_associations")` —
    forma literal do §5 de PLAN-023.
  - `model MnemonicFrame` (`schema.prisma:376-397`) ganha `visualAssociationId String?` +
    `visualAssociation VisualAssociation? @relation(fields: [visualAssociationId],
    references: [id], onDelete: SetNull)` — nenhum campo existente do model é removido ou
    reordenado.
  - `model User` (`schema.prisma:104-107`) ganha a relação reversa aditiva
    `visualAssociations VisualAssociation[] @relation("VisualAssociationAuthor")`, ao lado
    de `rawContents`/`editedRawContents`.
  - `model VisualAssociationLinkEvent` novo — `visualAssociationId String` (sem
    `@relation`/FK — DEC-023-011, sobrevive à remoção da associação, TRISK-023-007),
    `wasReuse Boolean`, `occurredAt DateTime @default(now())`, `@@index([occurredAt])`,
    `@@map("visual_association_link_events")` — forma literal do §5 de PLAN-023.
- `mnemonicos-backend/src/domain/types.ts:83` (`PRODUCTION_STAGE_TYPES`): ganha o 4º valor
  `'ASSOCIACAO_VISUAL'`, na mesma ordem do enum Prisma.
- `mnemonicos-backend/tests/unit/domain-types-parity.test.ts` (linha ~146, dentro do bloco
  `it('expõe PRODUCTION_STAGE_TYPES em paridade...')`): atualizar **só** o literal
  hard-coded `toEqual([...])` para incluir `'ASSOCIACAO_VISUAL'` — mesma classe de ajuste
  de TASK-012-004 (achado real, confirmado por leitura do arquivo: o literal da linha 146
  é hard-coded e fica vermelho assim que o array ganha o 4º valor); nenhuma outra linha do
  arquivo muda.
- Migração aditiva gerada via `prisma migrate dev --create-only` (a geração não aplica
  nada, não exige autorização prévia) — 1 novo diretório em `prisma/migrations/`:
  `CREATE TABLE visual_associations`, `ALTER TABLE mnemonic_frames ADD COLUMN
  "visualAssociationId"` + `ADD CONSTRAINT` (FK `SetNull`), `ALTER TYPE
  "ProductionStageType" ADD VALUE 'ASSOCIACAO_VISUAL'`, `CREATE TABLE
  visual_association_link_events`, `ADD CONSTRAINT` (FK `Restrict` de
  `VisualAssociation.authorId`) — nenhum `DROP`/`ALTER` destrutivo. **Aplicar exige
  autorização do Diretor** (DEC-023-007) — passo explícito do `/keelson:implement`
  (`AskUserQuestion`), **PARAR antes de aplicar** em dev/teste sem confirmação explícita.
- `mnemonicos-backend/tests/integration/visual-associations.model.integration.test.ts`
  (novo):
  - **AC-022-017** — monta a cadeia F2→F4 (`Topic`/`User`/`RawContent`/`RuleBreakdown` via
    `tests/support/production-events-fixtures.ts`; abre a Tira e adiciona 1 Quadro via
    `openMnemonicStrip`/`addMnemonicFrame`, código existente de `tira.service.ts`, sem
    alteração), cria 1 `VisualAssociation` direto via `testPrisma.visualAssociation.create`
    (autor próprio), vincula com `testPrisma.mnemonicFrame.update({ where: { id: frameId },
    data: { visualAssociationId } })` (schema puro — COMP-023-008 ainda não existe), chama
    `removeMnemonicFrame` (`tira.service.ts`, código existente e inalterado) e confirma via
    `testPrisma.visualAssociation.findUniqueOrThrow` que a linha sobrevive à remoção do
    Quadro.
  - `VisualAssociation.author` (`onDelete: Restrict`) — cria 1 `VisualAssociation`, tenta
    `testPrisma.user.delete({ where: { id: authorId } })` e afirma o **par
    comportamental** (a chamada rejeita **e** a linha `VisualAssociation` sobrevive,
    `findUniqueOrThrow` resolve) — nunca `err.code === 'P2003'` (lição ativa "[Dados/
    Persistência] FK `onDelete: Restrict` no Postgres não gera `P2003`" — o Postgres real
    levanta `23001`/`P2039` genérico para `Restrict`, não `23503`/`P2003`).
  - `VisualAssociationLinkEvent` — cria 1 linha via
    `testPrisma.visualAssociationLinkEvent.create` e lê de volta
    (`findUniqueOrThrow`); apaga a `VisualAssociation` referenciada e confirma que a linha
    do log sobrevive (ausência de FK, DEC-023-011/TRISK-023-007) — item do Inclui sem AC,
    oráculo é o contrato do próprio model.
- `mnemonicos-backend/tests/integration/production-events.model.integration.test.ts`
  (existente, molde já usado por TASK-012-001): 1 caso novo — mitigação de TRISK-023-001
  (`ALTER TYPE ... ADD VALUE` pode exigir commit intermediário) — cria um
  `ProductionStageEvent` com `stageType: 'ASSOCIACAO_VISUAL'` logo após a migração aplicar
  e lê o registro de volta na mesma sessão de teste.

### Não inclui

- Qualquer alteração em `Mnemonic`/`RawContent`/`RuleBreakdown`/`ProductionStageEvent` além
  da linha do enum aditivo — nenhum campo, FK ou índice já existente é tocado.
- Consumo dos models novos em código de serviço/rotas (`visual-associations.service.ts`,
  extensão de `tira.service.ts`) — TASK-023-005 em diante, fora desta lista.
- A camada de storage do binário (`saveVisualAssociationImage`/`readVisualAssociationImage`)
  — TASK-023-006, fora desta lista.
- Divisão em 2 migrações sequenciais para contornar TRISK-023-001 — só se o caso de teste
  de mitigação falhar de fato contra o Postgres real; se falhar, o achado vai para
  **Notas** da closure, não decidido preventivamente aqui.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Acrescentar `ASSOCIACAO_VISUAL` ao enum `ProductionStageType` (aditivo, mesma ordem).
2. Acrescentar `model VisualAssociation`, com os comentários `///` do §5 de PLAN-023 (FK
   `Restrict` do autor citando DEC-006-008; `imageData`/`mimeType` sempre por assinatura de
   bytes).
3. Acrescentar `visualAssociationId`/`visualAssociation` a `MnemonicFrame`, e a relação
   reversa `visualAssociations VisualAssociation[]` em `User`.
4. Acrescentar `model VisualAssociationLinkEvent`, sem `@relation`.
5. `prisma migrate dev --create-only` (sem aplicar) — ler o SQL gerado, confirmar 0
   `DROP`/`ALTER` destrutivo.
6. Pedir autorização do Diretor (`AskUserQuestion`) antes de aplicar contra
   `mnemonicos_test`.
7. Após a migração aplicar: acrescentar `'ASSOCIACAO_VISUAL'` a `PRODUCTION_STAGE_TYPES` e
   ao literal hard-coded de `domain-types-parity.test.ts` (linha ~146).
8. Escrever `visual-associations.model.integration.test.ts` (3 casos) e estender
   `production-events.model.integration.test.ts` (1 caso).

## Critérios de pronto

- [ ] O schema contém os 3 elementos novos (`VisualAssociation`, FK `SetNull` em
      `MnemonicFrame`, 4º valor do enum) e `VisualAssociationLinkEvent` — item do Inclui
      sem AC isolado (a faceta observável é AC-022-017, abaixo), oráculo é o contrato do
      próprio schema. Verificação executável: `npm --prefix mnemonicos-backend run
      db:generate` → exit 0; leitura do `schema.prisma` confirmando `@@map
      ("visual_associations")`, `onDelete: SetNull` em
      `MnemonicFrame.visualAssociation`, `onDelete: Restrict` em
      `VisualAssociation.author`, e ausência de `@relation` em
      `VisualAssociationLinkEvent`. Fixada antes do código.
- [ ] Migração aditiva — verificação executável: leitura do `migration.sql` gerado
      confirmando só `CREATE TABLE`/`ALTER TABLE ... ADD COLUMN`/`ALTER TYPE ... ADD
      VALUE`/`ADD CONSTRAINT`. Falsificável: qualquer `DROP`/`ALTER COLUMN` presente no SQL
      gerado reprova o critério.
- [ ] **AC-022-017** (FR-022-020, gate 1) — Quadro vinculado a uma `VisualAssociation`, ao
      ser removido via `removeMnemonicFrame` (código existente, F4, sem alteração),
      preserva a associação no acervo e a remoção do Quadro conclui sem bloqueio.
      Verificação executável: `npm --prefix mnemonicos-backend run test:integration --
      visual-associations.model` → `OK (≥3 tests)`, incluindo o caso que chama
      `removeMnemonicFrame` e confirma `testPrisma.visualAssociation.findUniqueOrThrow(...)`
      resolvendo depois da remoção. Falsificável: se a FK fosse `Cascade` em vez de
      `SetNull`, a associação seria apagada junto e o `findUniqueOrThrow` rejeitaria.
- [ ] `VisualAssociation.author` (`onDelete: Restrict`) recusa hard-delete do autor
      enquanto a associação existir — item do Inclui sem AC, oráculo é o **par
      comportamental** (lição ativa citada acima), nunca `err.code === 'P2003'`.
      Verificação executável: mesmo comando acima, caso próprio afirmando REJEIÇÃO da
      chamada **e** `findUniqueOrThrow` resolvendo a `VisualAssociation` depois.
      Falsificável: se a FK fosse `Cascade`/`SetNull`, o delete resolveria e a associação
      sumiria ou ficaria com `authorId` órfão.
- [ ] `VisualAssociationLinkEvent` sobrevive à remoção da `VisualAssociation` que
      referencia (DEC-023-011/TRISK-023-007) — item do Inclui sem AC, oráculo é o
      contrato do próprio model (uso não-nulo). Verificação executável: mesmo comando,
      caso próprio cria a linha, apaga a `VisualAssociation` referenciada, e confirma
      `testPrisma.visualAssociationLinkEvent.findUniqueOrThrow` ainda resolvendo.
- [ ] Mitigação de TRISK-023-001 — `ASSOCIACAO_VISUAL` gravável e legível no Postgres real
      na MESMA sessão em que a migração acabou de aplicar. Verificação executável: caso
      novo em `production-events.model.integration.test.ts` — comando: `npm --prefix
      mnemonicos-backend run test:integration -- production-events.model` → suíte verde,
      incluindo o caso novo (contagem de testes do arquivo cresce em +1). Falsificável: se
      o Postgres real recusar o valor novo na mesma sessão, este caso fica vermelho —
      achado a registrar em **Notas** da closure (mitigação de contingência já nomeada em
      PLAN §8/TRISK-023-001: dividir em 2 migrações sequenciais).
- [ ] `PRODUCTION_STAGE_TYPES` em paridade real com o schema — mesma régua de
      TASK-012-004: baseline capturada ANTES desta TASK tocar `domain/types.ts` — `npm
      --prefix mnemonicos-backend test -- domain-types-parity` no estado com o schema já
      migrado e `domain/types.ts` ainda com 3 valores → **vermelho** (linha 149, paridade
      real contra o schema); depois de adicionar o 4º valor a `PRODUCTION_STAGE_TYPES`
      **e** atualizar o literal da linha ~146 → o MESMO comando → **verde**, com a MESMA
      contagem de testes do arquivo (só o literal de uma asserção existente muda de valor
      esperado). Falsificável: esquecer a atualização da linha 146 deixa exatamente essa
      asserção vermelha mesmo com o schema e o array sincronizados.
- [ ] Nenhuma outra linha de `domain-types-parity.test.ts` além do literal da linha ~146 é
      alterada — verificação executável: `git diff main...HEAD -- mnemonicos-backend/
      tests/unit/domain-types-parity.test.ts` → `1 file changed, 1 insertion(+), 1
      deletion(-)`. Falsificável: qualquer segunda linha alterada reprova este critério.
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff — produção e teste, `git
      diff --name-only main...HEAD`).
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem (`node-22.md` — migração
      com autorização do Diretor; Prisma 7 `@prisma/adapter-pg`).
- [ ] Code review aprovado.

## Riscos específicos

- Autorização do Diretor para aplicar a migração é um ato humano fora desta TASK — o
  `/keelson:implement` escala via `AskUserQuestion` antes do 1º passo que aplica.
- Fatia sensível (migração): `security-engineer` (gate 8) revisa o diff completo desta
  TASK, inclusive a FK `Restrict` nova (`VisualAssociation.author`).
- TRISK-023-001: se o caso de mitigação falhar contra o Postgres real, o achado vai para
  **Notas** da closure — a divisão em 2 migrações sequenciais é a mitigação de
  contingência já nomeada no PLAN §8, não decidida preventivamente por este critério.
- Lição ativa "[Testes] Suíte de integração com DDL/TRUNCATE em banco compartilhado exige
  exclusividade real..." — esta é a 1ª TASK a exercitar o banco de teste nesta fatia;
  rodar isolado (sem gates concorrentes na mesma máquina) na fixação dos critérios acima.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-13T17:35:25+0000
**Data conclusão**: 2026-09-13T14:53:49-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: dcdf0bc
**Jira**: KAN-89
**Implementado por**: developer
**Revisado por**: code-reviewer (gate 1-7, wave 1) · security-engineer (gate 8, wave 1)
**Tentativas**: 1
**Cobertura final**: n/a (integração 287/287 verde, unit 255/255 verde)
**Arquivos modificados**:
  - mnemonicos-backend/prisma/schema.prisma
  - mnemonicos-backend/prisma/migrations/20260913174134_add_visual_association/migration.sql
  - mnemonicos-backend/src/domain/types.ts
  - mnemonicos-backend/tests/unit/domain-types-parity.test.ts
  - mnemonicos-backend/tests/integration/production-events.model.integration.test.ts
  - mnemonicos-backend/tests/integration/visual-associations.model.integration.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 1)
- [ ] Comportamento (gate 9): n/a — chore de schema, sem efeito observável de tela; AC-022-017 provado em gate 1 (teste de integração)

**Notas**: Migração gerada via `prisma migrate dev --create-only`, aplicada ao banco de TESTE
como efeito colateral do globalSetup da suíte de integração (incidente registrado no ledger
da sessão) e ao banco de DEV com autorização explícita do Diretor (AskUserQuestion,
2026-09-13) após disclosure do incidente — nenhuma aplicação silenciosa em produção; o
`vercel-build` já existente aplica no próximo deploy.
