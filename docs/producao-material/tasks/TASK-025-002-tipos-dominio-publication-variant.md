# TASK-025-002: Estender tipos de domínio — `PublicationVariant` (backend + frontend) e rede de paridade cross-repo

**Slug**: producao-material
**Pertence a**: PLAN-025
**Realiza (FRs)**: nenhuma
**Componente**: COMP-025-009 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Todo

```yaml
override-erros: task-criterio-sem-ac
override-justificativa: >-
  Dependência pura de tipo (COMP-025-009), sem FR realizado diretamente
  (ac_gate vazio no manifesto de decomposição) — consumida por TASK-025-006/
  007/010. Oráculo é o contrato do próprio item (regra 4.286): rede de
  paridade cross-repo é o critério falsificável. Mesmo padrão de TASK-006-004/
  TASK-012-004/TASK-023-005/TASK-023-017 (chore de tipos/paridade, Done, sem
  AC numerado).
override-aprovador: Tech Lead (autônomo, /keelson:auto)
```

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-025-006, TASK-025-007, TASK-025-010

## Contexto

Estende `mnemonicos-backend/src/domain/types.ts` e `mnemonicos-frontend/src/types/domain.ts`
com `PublicationVariant` (COMP-025-009) — dependência pura de tipo consumida por
TASK-025-006 (schema Zod), TASK-025-007 (composer) e TASK-025-010 (RTK Query), sem
comportamento observável por si só. O molde do backend é `PROOF_RADAR_CLASSES`/
`NORMATIVE_SOURCE_TYPES` (`export const X = [...] as const`); PLAN-025 §3/COMP-025-009
declara o lado frontend como só `export type PublicationVariant = 'TIRA' | 'RESUMO'` +
`PUBLICATION_VARIANT_LABELS` (sem um 2º array `PUBLICATION_VARIANTS` espelhado — diferente
do molde de `ProofRadarClass`, que tem o array nos dois lados). A rede de paridade
(`domain-types-parity.test.ts`, lido integralmente antes da extensão) precisa por isso de
um extrator novo, comparando o array do backend contra as chaves do mapa de rótulos do
frontend — mesma disciplina textual (sem AST) dos extratores já existentes no arquivo
(`extractConstArray`/`extractPrismaEnum`).

## Escopo

### Inclui

- `mnemonicos-backend/src/domain/types.ts`: `export const PUBLICATION_VARIANTS = ['TIRA',
  'RESUMO'] as const;` + `export type PublicationVariant =
  (typeof PUBLICATION_VARIANTS)[number];` — mesmo molde de `PROOF_RADAR_CLASSES`/
  `NORMATIVE_SOURCE_TYPES` (já espelhados por `domain-types-parity.test.ts`).
- `mnemonicos-frontend/src/types/domain.ts`: `export type PublicationVariant = 'TIRA' |
  'RESUMO';` + `export const PUBLICATION_VARIANT_LABELS: Record<PublicationVariant,
  string> = { TIRA: 'Tira mnemônica', RESUMO: 'Resumo' };` — rótulo pt-BR só no mapa,
  nunca literal solto em JSX.
- `mnemonicos-backend/tests/unit/domain-types-parity.test.ts` (arquivo existente, lido
  integralmente antes da extensão): novo `it(...)` comparando
  `extractConstArray(backendSource, 'PUBLICATION_VARIANTS').sort()` contra as chaves de
  `PUBLICATION_VARIANT_LABELS` extraídas textualmente do arquivo do frontend (nova função
  `extractRecordKeys(source, constName)`, mesmo mecanismo sem AST dos extratores já
  existentes) — o teste LÊ os dois arquivos como texto, nunca transcreve os valores.

### Não inclui

- Uso do tipo em schema Zod (TASK-025-006), RTK Query (TASK-025-010) ou componente
  (TASK-025-011).

## Critérios de pronto

- [ ] `PUBLICATION_VARIANT_LABELS` (frontend) tem exatamente as 2 chaves de
      `PUBLICATION_VARIANTS` (backend), valor não-nulo cada — item do Inclui sem AC,
      oráculo do próprio item (regra 4.286), verificado pela extensão de
      `domain-types-parity.test.ts`. Verificação executável: baseline `npm --prefix
      mnemonicos-backend test -- domain-types-parity` ANTES da extensão (contagem atual de
      casos do arquivo); depois de acrescentar o novo `it(...)` → contagem +1, todos verdes
      (`OK (N+1 tests)`). Falsificável (mutante): renomear uma chave de
      `PUBLICATION_VARIANT_LABELS` no frontend (ex.: `RESUMO` → `SUMARIO`) sem tocar o
      backend → o novo caso fica vermelho; o mesmo mutante do lado backend
      (`PUBLICATION_VARIANTS`) também derruba o caso.
- [ ] `PUBLICATION_VARIANTS` (backend) tem exatamente os 2 valores `['RESUMO', 'TIRA']`
      (ordenados) — mesmo caso do critério acima cobre esta faceta (`expect([
      ...PUBLICATION_VARIANTS].sort()).toEqual(...)`, mesmo padrão das asserções de
      `USER_ROLES`/`PROOF_RADAR_CLASSES` já existentes no arquivo, linhas 99/112).
- [ ] Nenhum array literal `['TIRA', 'RESUMO']`/`['RESUMO', 'TIRA']` duplicado fora da
      declaração de `PUBLICATION_VARIANTS` nos arquivos tocados por esta TASK (lição
      [Código] DRY) — verificação executável: `grep -n "'TIRA'" mnemonicos-backend/src/domain/types.ts
      mnemonicos-frontend/src/types/domain.ts` → só a ocorrência da própria declaração de
      `PUBLICATION_VARIANTS` (backend) e as 2 chaves do objeto `PUBLICATION_VARIANT_LABELS`
      (frontend, chave de objeto — não é um 2º array). Falsificável: um 3º array literal
      `['TIRA','RESUMO']` redigitado em qualquer arquivo do diff reprova.
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff, produção e teste — `git
      diff --name-only main...HEAD`).

## Riscos específicos

- Lição ativa "[Testes] O teste de paridade PRECISA ler o arquivo do outro repositório,
  nunca comparar o array contra ele mesmo" (reincidência 5x já registrada neste projeto) —
  o novo `it(...)` desta TASK usa o mesmo mecanismo de leitura textual dos dois arquivos
  reais, nunca um fixture local que se autoconfirma.
- Assimetria de molde entre `PublicationVariant` (frontend só com `type` + mapa de
  rótulos) e `ProofRadarClass`/`NormativeSourceType` (array espelhado nos dois lados) —
  o extrator novo (`extractRecordKeys`) precisa ler as CHAVES de um objeto `Record<...>`,
  não um array — confirmar contra `PROOF_RADAR_CLASS_LABELS`
  (`mnemonicos-frontend/src/types/domain.ts:80`) como o molde de forma do objeto antes de
  escrever o extrator.

---

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-109

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a>
