# TASK-025-005: EMENDA tira.service.ts — supressão do evento de abertura + ordem canônica exportada

**Slug**: producao-material
**Pertence a**: PLAN-025
**Realiza (FRs)**: FR-024-006 (parcial — mecanismo apenas; o comportamento fim-a-fim de auto-geração é provado em TASK-025-008/AC-024-004), FR-024-013
**Componente**: COMP-025-007 (principal)
**Wave**: 1
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-025-008, TASK-025-013

## Contexto

`openMnemonicStrip` (COMP-012-004, `tira.service.ts`) ganha um parâmetro opcional para
suprimir o evento de abertura na criação automática, e o ramo de reabertura passa a
decidir a emissão de `ABERTURA` pelo histórico real do par `(rawContentId,
'TIRA_MNEMONICA')` em vez de simplesmente devolver a Tira — fecha FR-024-013 (a
auto-geração via exportação não emite `ABERTURA` no instante da criação; a 1ª interação
humana subsequente, sim). Ver PLAN-025 §3 (COMP-025-007) e §6 (DEC-025-003).

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/tira/tira.service.ts` (EMENDA, `openMnemonicStrip`,
  linhas 217-278 do arquivo atual): 4º parâmetro opcional `options?: {
  suppressOpeningEvent?: boolean }`, equivalente por default a `{ suppressOpeningEvent:
  false }` — nenhum chamador existente (`tira.routes.ts`, que chama sem `options`) muda
  de comportamento.
- Ramo de CRIAÇÃO (dentro do `$transaction`, quando `existing === null`): quando
  `options?.suppressOpeningEvent === true`, PULA a chamada a `recordProductionStageEvent`
  depois do `tx.mnemonicStrip.create` — 0 eventos gravados para o par `(rawContentId,
  'TIRA_MNEMONICA')` nesse instante; `options?.suppressOpeningEvent !== true` preserva a
  chamada exatamente como hoje.
- Ramo de REABERTURA (`existing !== null`, hoje só `return existing`): passa a consultar
  o histórico real de eventos `TIRA_MNEMONICA` do par e, só quando esse histórico está
  VAZIO, emitir `ABERTURA` agora (mesmo mecanismo de decisão de `decideStageTransition`,
  `production-events.service.ts`); histórico NÃO-vazio → nenhuma chamada extra, `return
  existing` como hoje nos dois casos.
- Extrai `CANONICAL_RULE_BREAKDOWN_ORDER: readonly Array<{ originBlock: 'concept' |
  'action' | 'object' | 'condition' | 'exception' }>` (constante exportada, texto exato
  da Interface pública de COMP-025-007 no PLAN-025 §3) de dentro de `buildInitialFrames`
  — a função passa a mapear `CANONICAL_RULE_BREAKDOWN_ORDER` para montar a lista `{
  originBlock, text }` (lookup de `breakdown[item.originBlock]`), sem o array `{
  originBlock, text }` duplicado à parte; mesmo comportamento observável (5 Blocos,
  mesma ordem, mesmo filtro dos Blocos vazios).

### Não inclui

- Qualquer chamador de `openMnemonicStrip` fora deste arquivo (TASK-025-008 passa `{
  suppressOpeningEvent: true }`; nenhum outro chamador muda).
- Auto-geração de Tira em si (`buildInitialFrames`, mesma regra de F4 — sem mudança de
  comportamento além da extração da constante acima).
- Reescrita de qualquer outra função de `tira.service.ts` (`getMnemonicStrip`,
  `addMnemonicFrame`, `updateMnemonicFrameText`, `removeMnemonicFrame`,
  `reorderMnemonicFrames`, `linkVisualAssociationToFrame`,
  `unlinkVisualAssociationFromFrame`) — EMENDA cirúrgica sobre um arquivo já entregue e
  aprovado em gate de segurança (F4/F5), nunca reescrita.

## Critérios de pronto

- [ ] **AC-024-015** (gate 1) — par de cenários no MESMO teste (lição [Testes] "Árvore de
      decisão com precedência: um caso por PAR de ramos que coincide" — o par
      `(suppressOpeningEvent=true na criação) × (histórico vazio na reabertura seguinte)`
      precisa de caso próprio): (1) `openMnemonicStrip(rawContentId, actor, testPrisma, {
      suppressOpeningEvent: true })` na 1ª abertura (ramo CRIAÇÃO) grava a Tira
      normalmente mas emite **0** eventos `TIRA_MNEMONICA` — asserção sobre
      `testPrisma.productionStageEvent.findMany({ where: { rawContentId, stageType:
      'TIRA_MNEMONICA' } })` → `length === 0`; (2) chamada SEGUINTE de `openMnemonicStrip`
      sobre o MESMO `rawContentId` (ramo REABERTURA, histórico ainda vazio) emite
      exatamente **1** evento `ABERTURA`. Mutante que reordena/funde os dois ramos
      (emitir já na criação, ou nunca emitir na reabertura) reprova este par. Verificação
      executável: `npm --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=tira.service.integration.test.ts` → `OK (N tests)`, incluindo o
      caso novo. Fixada antes do código.
- [ ] Ramo de REABERTURA com histórico JÁ não-vazio (fluxo humano normal — criação SEM
      `suppressOpeningEvent`, que já emitiu `ABERTURA` na hora): chamada seguinte de
      `openMnemonicStrip` (reabertura) NÃO emite evento extra — mesmo comportamento
      observável de hoje, caso de regressão. Mesmo comando.
- [ ] Assinatura retrocompatível (lição "[Código] Lista de 'Interface pública' do PLAN é
      contrato mínimo, não gabarito de transcrição — lição registrada NESTE MESMO
      ARQUIVO, reincidência 2× em PLAN-012"): chamador existente sem `options`
      (`tira.routes.ts`, `POST /contents/:id/strip`) continua idêntico — 1ª abertura
      emite `ABERTURA` imediatamente, sem supressão. Mesmo comando, caso de regressão
      explícito.
- [ ] Prova comportamental PRÓPRIA do novo comportamento condicional (lição "[Segurança]
      Guarda reusada continua exigindo prova comportamental própria por novo método de
      escrita" — `assertRawContentReachable` não muda de corpo, mas a emissão condicional
      na reabertura é NOVA e precisa de prova própria, não herdada): os 2 casos do 1º
      item acima SÃO essa prova — nenhum teste estrutural (assinatura/tipo) a substitui.
- [ ] `CANONICAL_RULE_BREAKDOWN_ORDER` exportada com os 5 `originBlock` na ordem
      CONCEITO→AÇÃO→OBJETO→CONDIÇÃO→EXCEÇÃO (`['concept','action','object','condition','exception']`)
      — teste unitário estendido em `tests/unit/tira.rule.test.ts` (já cobre
      `buildInitialFrames`) afirmando `CANONICAL_RULE_BREAKDOWN_ORDER.map(i =>
      i.originBlock)` igual a esse array. Verificação executável: `npm --prefix
      mnemonicos-backend test -- tira.rule` → `OK (N tests)`.
- [ ] `buildInitialFrames` sem o array `{ originBlock, text }` duplicado — verificação
      estrutural (condição): `grep -c "export const CANONICAL_RULE_BREAKDOWN_ORDER"
      mnemonicos-backend/src/modules/tira/tira.service.ts` → `1` (declaração única), e
      `grep -n "CANONICAL_RULE_BREAKDOWN_ORDER"
      mnemonicos-backend/src/modules/tira/tira.service.ts` → ao menos 2 ocorrências
      (declaração + uso dentro de `buildInitialFrames`) — universo de busca = arquivo
      inteiro. Falsificável: um 2º array `{ originBlock: 'concept', ... }` declarado à
      parte não incrementaria a 1ª contagem, mas a ausência de uso dentro da função
      deixaria a 2ª em 1.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`), produção e teste — `npm --prefix mnemonicos-backend run lint` →
      exit 0.

## Riscos específicos

- Alternativa descartada pelo PLAN (DEC-025-003): função paralela
  (`openMnemonicStripForExport`) duplicando `assertStripPrerequisites`/criação/
  concorrência — reincidência direta da lição [DRY] já 3× reincidente em F5/PLAN-023;
  esta TASK aplica a alternativa escolhida (parâmetro aditivo), nunca a descartada.
- Arquivo já entregue e aprovado em gate de segurança (F4/F5, EMENDA Wave 5/DEC-012-011,
  achado de CSRF fechado) — EMENDA cirúrgica: nenhuma linha fora do escopo listado acima
  é tocada.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-14T15:30:38-0300
**Data conclusão**: 2026-09-14T16:15:04-0300
**Commit SHA**: 85fcdbf (implementação) · 6f980e8 (retry, achados 1/2/3) · d08ea22 (carona, achados residuais)
**Jira**: KAN-112

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (1 retry — achados 1/2 bloqueantes fechados, delta re-revisado APROVADO)
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 1)
- [x] Comportamento (gate 9): consolidado (DoD, Etapa 4) — SPEC-024 sem FEATs
