# TASK-012-004: Estender `domain/types.ts` (backend) com `TIRA_MNEMONICA` e confirmar paridade

**Slug**: producao-material
**Pertence a**: PLAN-012
**Realiza (FRs)**: nenhuma
**Componente**: COMP-012-002 (principal), COMP-012-007
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico, estratégia `unica`)
**Padrão de commit**: Conventional Commits (`feat:` — estende capacidade do mecanismo de F3)
**Framework de teste**: Jest 30 + ts-jest (`npm --prefix mnemonicos-backend test`)

## Dependências

- **Depende de**: TASK-012-001
- **Bloqueia**: nenhuma

## Contexto

`PRODUCTION_STAGE_TYPES` (`src/domain/types.ts:83`) é o único ponto de manutenção para o
mecanismo de F3 (`recordProductionStageEvent`/`decideStageTransition`) reconhecer
`TIRA_MNEMONICA` sem redesenho (NFR-011-004, DEC-012-005) — a extensão é puramente aditiva:
nenhum evento já emitido para `CONTEUDO_BRUTO`/`QUEBRA_DA_REGRA` muda de comportamento
(AC-011-018). O par de paridade intra-repo é `domain-types-parity.test.ts`
(`mnemonicos-backend/tests/unit/domain-types-parity.test.ts:142-152`), que já compara
`PRODUCTION_STAGE_TYPES` contra o enum real do `schema.prisma` (que TASK-012-001 já
estendeu). **Divergência encontrada na leitura do arquivo real** (registrada em `duvidas`
do sumário desta redação): a linha 146 do teste fixa um literal hard-coded —
`expect(declaredStageTypes).toEqual(['CONTEUDO_BRUTO', 'QUEBRA_DA_REGRA'])` — que fica
**vermelho** assim que `'TIRA_MNEMONICA'` entra em `PRODUCTION_STAGE_TYPES`, distinto da
comparação de paridade real contra o schema (linha 149, `toEqual(schemaStageTypes)`, que
continua genérica e não precisa mudar). Esta TASK trata essa única linha como parte
necessária do Escopo (abaixo) — o restante do arquivo (extratores, os outros 2 blocos
`it()`, a comparação de paridade real) permanece intocado.

## Escopo

### Inclui

- `mnemonicos-backend/src/domain/types.ts:83`: `PRODUCTION_STAGE_TYPES` ganha o 3º valor,
  na mesma ordem do enum Prisma (que TASK-012-001 já estendeu):
  ```ts
  export const PRODUCTION_STAGE_TYPES = ['CONTEUDO_BRUTO', 'QUEBRA_DA_REGRA', 'TIRA_MNEMONICA'] as const;
  ```
- `mnemonicos-backend/tests/unit/domain-types-parity.test.ts` (linha ~146, dentro do bloco
  `it('expõe PRODUCTION_STAGE_TYPES em paridade...')`): atualizar **só** o literal
  hard-coded `toEqual([...])` para incluir `'TIRA_MNEMONICA'` — nenhuma outra linha do
  arquivo muda (os extratores `extractConstArray`/`extractPrismaEnum` e a comparação de
  paridade real da linha 149/151 continuam exatamente como estão, genéricos).

### Não inclui

- Qualquer mudança em `domain-types-parity.test.ts` além da atualização do literal
  hard-coded citada acima (extratores, nomes de `it()`, ordem dos blocos, os 2 outros
  enums comparados — `PROOF_RADAR_CLASSES`/`NORMATIVE_SOURCE_TYPES` — permanecem
  intocados).
- Espelho de `TIRA_MNEMONICA`/`PRODUCTION_STAGE_TYPES` em
  `mnemonicos-frontend/src/types/domain.ts` — DEC-010-006 permanece (SPEC-011 §10); o
  frontend desta fatia só espelha `MnemonicStrip`/`MnemonicFrame` (COMP-012-009,
  TASK-012-009), nunca o enum de tipo de etapa em si.
- Qualquer alteração em `recordProductionStageEvent`/`decideStageTransition`
  (`production-events.service.ts`) — o mecanismo de F3 já comporta o valor novo sem
  redesenho (DEC-012-005); nada muda lá.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Capturar a baseline: `npm --prefix mnemonicos-backend test -- domain-types-parity` no
   estado herdado de TASK-012-001 (schema já com `TIRA_MNEMONICA`, `domain/types.ts` ainda
   sem) — este comando deve estar **vermelho** neste ponto (linha 149, paridade real
   contra o schema, já divergente) — confirma que o critério de paridade é genuíno, não
   tautológico.
2. Adicionar `'TIRA_MNEMONICA'` a `PRODUCTION_STAGE_TYPES`.
3. Atualizar o literal da linha ~146 de `domain-types-parity.test.ts` para incluir
   `'TIRA_MNEMONICA'`.
4. Rodar o mesmo comando — deve voltar a verde, incluindo a asserção da linha 146 e a de
   paridade real da linha 149.

## Critérios de pronto

- [ ] **AC-011-018** (gate 1) — `PRODUCTION_STAGE_TYPES` contém exatamente
      `['CONTEUDO_BRUTO', 'QUEBRA_DA_REGRA', 'TIRA_MNEMONICA']`, em paridade real com o
      enum `ProductionStageType` do `schema.prisma` (que TASK-012-001 já estende) — nenhum
      evento já emitido ou a emitir para `CONTEUDO_BRUTO`/`QUEBRA_DA_REGRA` muda de
      comportamento (extensão puramente aditiva). Verificação executável: baseline
      capturada ANTES desta TASK tocar `domain/types.ts` — `npm --prefix
      mnemonicos-backend test -- domain-types-parity` no estado herdado de TASK-012-001
      → **vermelho** no bloco de `PRODUCTION_STAGE_TYPES` (schema já tem 3 valores,
      `domain/types.ts` ainda tem 2 — a linha 149, `toEqual(schemaStageTypes)`, é quem
      acusa; registrar a contagem total de testes do arquivo neste estado como baseline
      N). Depois de adicionar o 3º valor a `PRODUCTION_STAGE_TYPES` **e** atualizar o
      literal da linha ~146 → o MESMO comando → **verde**, com a MESMA contagem N de
      testes do arquivo (nenhum teste novo, nenhum removido — só o literal de uma
      asserção existente mudou de valor esperado). Falsificável: esquecer o passo 3
      (linha 146) deixa exatamente essa asserção vermelha mesmo com o schema e o array
      sincronizados — prova de que a linha 146 é uma checagem redundante, mas real, não
      tautológica. Fixada antes do código.
- [ ] `type ProductionStageType` (união derivada de `PRODUCTION_STAGE_TYPES`) continua
      compilando para todo consumidor existente (`production-events.service.ts`,
      `contents.service.ts`) sem exigir nenhuma mudança de assinatura — item do Inclui sem
      AC, oráculo é o contrato do próprio tipo. Verificação executável: `npm --prefix
      mnemonicos-backend run typecheck` → exit 0.
- [ ] Nenhuma outra linha de `domain-types-parity.test.ts` além do literal da linha ~146 é
      alterada — verificação executável: `git diff main...HEAD -- mnemonicos-backend/
      tests/unit/domain-types-parity.test.ts` mostra exatamente 1 linha modificada
      (`git diff --stat ...` → `1 file changed, 1 insertion(+), 1 deletion(-)`).
      Falsificável: qualquer segunda linha alterada no arquivo (ex.: reescrever o extrator,
      renomear o `it()`) reprova este critério — a mudança é estritamente o valor literal
      de uma asserção pré-existente.
- [ ] Sem warnings/lints novos (`npm --prefix mnemonicos-backend run lint` → exit 0).
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem.
- [ ] Code review aprovado.

## Riscos específicos

- **Achado de divergência (redação desta TASK, não do PLAN)**: o pacote de decomposição
  original presumia que `domain-types-parity.test.ts` permaneceria 100% intocado; a
  leitura direta do arquivo mostrou um literal hard-coded (linha ~146) que exige 1 linha
  de atualização para o teste continuar verdadeiro (não tautológico) com o valor novo.
  Reportado em `duvidas` do sumário de redação para confirmação do invocador — se a
  intenção original era vetar QUALQUER edição neste arquivo, o critério acima precisa ser
  revisto (o teste ficaria permanentemente vermelho, o que não pode ser o "pronto"
  pretendido por AC-011-018).
- Janela TASK-012-001 → TASK-012-004: entre as duas, o schema já tem `TIRA_MNEMONICA` mas
  `domain/types.ts` ainda não — `domain-types-parity.test.ts` fica vermelho nesse
  intervalo (esperado, não é regressão desta TASK).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-06T19:55:43-0300
**Data conclusão**: 2026-09-06T19:58:07-0300
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 9042e91
**Jira**: KAN-54
**Implementado por**: developer
**Revisado por**: code-reviewer (aprovado sem achados, Wave 2) · security-engineer (gate 8 aprovado, Wave 2)
**Tentativas**: 1
**Cobertura final**: n/a (item do Inclui sem AC próprio — prova por AC-011-018)
**Arquivos modificados**:
  - mnemonicos-backend/src/domain/types.ts
  - mnemonicos-backend/tests/unit/domain-types-parity.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (228/228, fechou o vermelho sancionado da Wave 1)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados (AC-011-018)
- [x] Segurança (gate 8): aprovado — mudança de tipo pura, sem I/O
- [x] Comportamento (gate 9): n/a — extensão de constante de domínio, sem efeito observável direto

**Notas**:
