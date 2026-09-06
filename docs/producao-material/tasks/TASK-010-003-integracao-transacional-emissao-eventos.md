# TASK-010-003: Integração transacional da emissão de eventos em `contents.service.ts`

**Slug**: producao-material
**Pertence a**: PLAN-010
**Realiza (FRs)**: FR-009-001, FR-009-002, FR-009-003, FR-009-004, FR-009-005, FR-009-009
**Componente**: COMP-010-003 (principal), COMP-010-006
**Wave**: 3
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico, estratégia `unica`)
**Padrão de commit**: Conventional Commits (`feat:`)
**Framework de teste**: Jest 30 + ts-jest (unit: `npm --prefix mnemonicos-backend test`; integração: `npm --prefix mnemonicos-backend run test:integration`)

## Dependências

- **Depende de**: TASK-010-002
- **Bloqueia**: nenhuma

## Contexto

Fatia sensível (regra de negócio central + atomicidade fail-secure — princípio 8): envolve
`createRawContent`, `updateRawContent` e `saveRuleBreakdown` (hoje sem transação —
`contents.service.ts:85-102`, `:138-161`, `:385-408`) em `prisma.$transaction(async (tx) =>
{...})`, reusando o único precedente de transação-callback do repo (`auth.service.ts:154-175`).
`softDeleteRawContent` (`:176-187`) permanece **inalterada** — nenhuma emissão nova
(FR-009-009). A suíte desta TASK é a condição de pronto de TRISK-010-003/RISK-009-002: os 5
gatilhos de emissão + o tripwire de fail-secure (AC-009-010) não são opcionais.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/contents/contents.service.ts`:
  - `createRawContent` (`:85-102`): envolver em `prisma.$transaction(async (tx) => {...})`;
    computar `const now = new Date()` uma única vez no início do callback; `tx.rawContent.create`
    seguido de 3 chamadas a `recordProductionStageEvent(tx, { rawContentId, stageType, actorId, now })`
    — 2× `'CONTEUDO_BRUTO'` (abertura, depois conclusão — a regra de COMP-010-002 decide
    sozinha, sem o chamador dizer qual é qual) + 1× `'QUEBRA_DA_REGRA'` (abertura).
  - `updateRawContent` (`:138-161`): envolver em `prisma.$transaction`; `now` computado uma
    vez (substitui o `new Date()` inline de `:154`, reusado também no evento);
    `tx.rawContent.updateMany` seguido de 1 chamada a `recordProductionStageEvent(tx, {
    rawContentId: id, stageType: 'CONTEUDO_BRUTO', actorId: actor.id, now })`.
  - `saveRuleBreakdown` (`:385-408`): envolver em `prisma.$transaction`; `now` computado uma
    vez; `assertRawContentReachable` (guarda existente, inalterada) + `tx.ruleBreakdown.upsert`
    seguidos de 1 chamada a `recordProductionStageEvent(tx, { rawContentId, stageType:
    'QUEBRA_DA_REGRA', actorId: actor.id, now })`.
  - Assinaturas das 3 funções **inalteradas** (parâmetros e retorno idênticos a F2); muda só
    o tipo interno do parâmetro `db` (de `Pick<typeof prisma, 'rawContent'>`/
    `Pick<typeof prisma, 'rawContent' | 'ruleBreakdown'>` para incluir `'$transaction'`),
    invisível a quem chama com o default `prisma`.
- `softDeleteRawContent` (`:176-187`): **nenhuma mudança de código** — só entra na suíte
  desta TASK como o gatilho negativo (nenhuma emissão nova, FR-009-009).
- `mnemonicos-backend/tests/integration/contents.service.integration.test.ts` (existente):
  novo `describe()` cobrindo os 5 gatilhos + fail-secure — COMP-010-006, mesmo padrão de
  fixture já em uso no arquivo (`createUser`/`createTopic`/`testPrisma`, linhas 52-80).

### Não inclui

- `production-events.service.ts` — já entregue por TASK-010-002 (dependência, não tocada
  aqui além de ser chamada).
- Migração/model/tipos/rede de paridade — já entregues por TASK-010-001 (dependência).
- Qualquer mudança de resposta HTTP, rota ou comportamento de tela de Conteúdo
  bruto/Quebra da regra — proibido por NFR-009-005/AC-009-009.
- Espelho frontend dos enums — DEC-010-006, fora desta fatia.
- Paginação de `listProductionStageEvents` — TRISK-010-002, fora desta fatia.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Envolver as 3 funções em `prisma.$transaction(async (tx) => {...})`, uma de cada vez,
   confirmando que o `db` injetável (`db: RawContentClient`/`RuleBreakdownClient`) ganha
   `'$transaction'` no tipo — sem quebrar o default `prisma`.
2. Chamar `recordProductionStageEvent` nos pontos exatos do §4 de PLAN-010, sempre com o
   `tx` do callback (nunca abrir uma 2ª transação, nunca usar `prisma` fora do `tx`).
3. Estender a suíte de integração com os 5 gatilhos: criação (3 eventos), edição
   (retrabalho CB), 1º salvamento da Quebra (conclusão QR), salvamento subsequente
   (retrabalho QR), soft-delete (nenhum evento novo).
4. Escrever o teste de fail-secure: mockar/espiar `recordProductionStageEvent` (ou o client
   de evento) para lançar dentro da transação e confirmar que a mutação de negócio
   (`rawContent`/`ruleBreakdown`) **também** não persiste — nenhum estado meio-salvo.
5. Confirmar, por leitura do diff, que nenhuma resposta HTTP/rota de `contents.routes.ts` é
   tocada (NFR-009-005).

## Critérios de pronto

- [ ] Testes cobrem AC-009-001 (criação de Conteúdo bruto registra evento de abertura E de
      conclusão da etapa "Conteúdo bruto", atribuídos ao autor da criação) — verificação
      executável: `npm --prefix mnemonicos-backend run test:integration --
      contents.service` → suíte verde, caso que chama `createRawContent` e confirma, via
      `listProductionStageEvents`, exatamente 2 eventos `CONTEUDO_BRUTO` (`ABERTURA` e
      `CONCLUSAO`, `actorId` = ator da criação).
- [ ] Testes cobrem AC-009-002 (a mesma criação registra evento de abertura da etapa
      "Quebra da regra") — mesmo comando, caso que confirma 1 evento `QUEBRA_DA_REGRA`
      (`ABERTURA`) na mesma chamada de `createRawContent`.
- [ ] Testes cobrem AC-009-003 (1º salvamento da Quebra da regra registra conclusão da
      etapa "Quebra da regra") — mesmo comando, caso que chama `saveRuleBreakdown` pela 1ª
      vez sobre um Conteúdo bruto recém-criado e confirma o evento `QUEBRA_DA_REGRA`
      (`CONCLUSAO`) somado aos já existentes.
- [ ] Testes cobrem AC-009-004 (edição de Conteúdo bruto já concluído registra retrabalho,
      nunca uma 2ª conclusão) — mesmo comando, caso que chama `updateRawContent` sobre um
      Conteúdo já criado e confirma o evento `CONTEUDO_BRUTO` (`RETRABALHO`) — e afirma,
      por contagem, que só existe 1 evento `CONCLUSAO` de `CONTEUDO_BRUTO` no total (nunca
      2).
- [ ] Testes cobrem AC-009-005 (novo salvamento da Quebra da regra após conclusão registra
      retrabalho, nunca uma 2ª conclusão) — mesmo comando, caso que chama
      `saveRuleBreakdown` uma 2ª vez e confirma o evento `QUEBRA_DA_REGRA` (`RETRABALHO`) —
      e afirma, por contagem, só 1 evento `CONCLUSAO` de `QUEBRA_DA_REGRA` no total.
- [ ] Teste de concorrência real para AC-009-003/AC-009-005 (garante, sob concorrência
      real, a exclusividade da 1ª conclusão que os 2 testes sequenciais acima só provam sob
      serialização controlada pelo próprio teste) — verificação executável: mesmo comando
      de `contents.service`, caso que dispara 2 chamadas de `saveRuleBreakdown` **em
      paralelo** (`Promise.all`, nunca sequencial) sobre o mesmo `rawContentId` recém-criado
      (nenhuma Quebra da regra salva ainda, só o histórico de `ABERTURA`) e confirma, após
      ambas resolverem, via `listProductionStageEvents`, **exatamente 1** evento
      `QUEBRA_DA_REGRA` (`CONCLUSAO`) no total (nunca 2) — a garantia sendo provada é
      DEC-010-007 (serialização via lock de índice único de `RuleBreakdown.rawContentId`,
      propriedade emergente do schema de F2, sem lock explícito adicional nesta fatia).
- [ ] Testes cobrem AC-009-007 (parte — nenhum evento novo de etapa é gravado em razão da
      remoção; a faceta de sobrevivência via FK `Restrict` é da TASK-010-001) — mesmo
      comando, caso que cria um Conteúdo bruto (N eventos emitidos), chama
      `softDeleteRawContent`, e confirma por contagem que o nº de eventos não muda
      (`listProductionStageEvents` antes e depois do soft-delete devolve o mesmo array).
- [ ] Testes cobrem AC-009-009 (nenhuma resposta HTTP, campo de payload ou comportamento de
      tela observável muda em relação a F2) — verificação executável: `npm --prefix
      mnemonicos-backend run test:integration -- contents` → suíte de F2
      (`contents.integration.test.ts`) permanece 100% verde sem nenhuma alteração de
      asserção — baseline capturada na Entrega de PLAN-006 (INDEX: "backend integração
      213/213 (11 suítes)", 2026-09-06); esta TASK não segue verde por "sem alteração de
      asserção" (isso congelaria o artefato) — a prova é o **valor observável completo**:
      as respostas de `createRawContent`/`updateRawContent`/`saveRuleBreakdown` continuam
      exatamente `RawContentDetail`/`RuleBreakdownDetail` (mesmos campos, sem campo de
      evento vazado), medido pelas asserções já existentes no arquivo de F2, intocadas.
- [ ] Testes cobrem AC-009-010 (fail-secure: falha na emissão do evento reverte a mutação
      de negócio inteira, nenhum estado meio-salvo, erro genérico) — verificação
      executável: mesmo comando de `contents.service`, **3 casos**, mesma técnica de
      injeção de falha (mock/spy sobre `recordProductionStageEvent` ou sobre o client do
      evento, `productionStageEvent.create`/`findMany` lançando dentro do `$transaction`):
      (a) `createRawContent` com a emissão falhando → a exceção propaga ao chamador e
      `testPrisma.rawContent.count()` confirma **zero** linhas de `RawContent` novas
      persistidas pela chamada fracassada (nenhum sucesso parcial); (b) `updateRawContent`
      sobre um Conteúdo bruto já existente, com a emissão de `RETRABALHO` falhando dentro
      do mesmo `$transaction` → a exceção propaga e `tx.rawContent.updateMany` não
      persiste — `testPrisma.rawContent.findUnique` confirma que o Conteúdo bruto
      permanece exatamente no estado anterior à chamada (campos intactos, nenhuma escrita
      parcial); (c) `saveRuleBreakdown` com a emissão falhando → a exceção propaga e
      `testPrisma.ruleBreakdown.count()`/`.findUnique` confirma que nenhuma `RuleBreakdown`
      nova é criada (1º salvamento) nem atualizada (salvamento subsequente) pela chamada
      fracassada.
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff — produção e teste, `git
      diff --name-only main...HEAD`)
- [ ] Padrão de commit respeitado
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem
- [ ] Code review aprovado

## Riscos específicos

- TRISK-010-001 (herdado do PLAN): a transação interativa mantém conexão do pool presa mais
  tempo que o statement único de F2 — nenhuma chamada de I/O externo dentro do callback;
  medir round-trips se o volume real justificar (não medido nesta TASK, aceito no PLAN).
- Fatia sensível (regra de negócio central, atomicidade fail-secure): `security-engineer`
  (gate 8) revisa o diff completo, com foco no teste de fail-secure (AC-009-010) — mutante
  que remova a reversão da transação precisa morrer na suíte.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Branch**:
**Commit SHA**:
**Jira**: KAN-48
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
