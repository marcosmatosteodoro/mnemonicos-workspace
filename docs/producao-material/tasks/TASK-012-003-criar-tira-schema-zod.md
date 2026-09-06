# TASK-012-003: Criar `tira.schema.ts` — validação Zod de Quadro

**Slug**: producao-material
**Pertence a**: PLAN-012
**Realiza (FRs)**: FR-011-003, FR-011-004, FR-011-006
**Componente**: COMP-012-003 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

```yaml
override-erros: task-criterio-sem-ac
override-justificativa: >-
  Item do Inclui sem AC vinculado — oráculo é o contrato do próprio schema
  (contrato do /keelson:tasks, Etapa 3: "Sem AC, o oráculo é o contrato do
  próprio item"). Mesmo padrão de TASKs chore/schema aprovadas do slug
  (TASK-006-004, TASK-006-007 — Done, sem nenhuma menção a AC). O check
  mecânico task-criterio-sem-ac não distingue esse caso legítimo; registrado
  como pendência de processo (lição candidata ao agile-coach).
override-aprovador: Tech Lead (autônomo, /keelson:auto)
```

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico, estratégia `unica`)
**Padrão de commit**: Conventional Commits (`feat:`)
**Framework de teste**: Jest 30 + ts-jest (`npm --prefix mnemonicos-backend test`)

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-012-008

## Contexto

Fronteira de validação de entrada do módulo `tira/` (padrão em camadas `schema → service →
routes`, mesmo padrão de `contents.schema.ts`). Os 4 schemas cobrem as 3 mutações de Quadro
(adicionar, editar texto, reordenar) e o param `:frameId` das rotas — nenhuma rota nem
service entra nesta TASK (COMP-012-004/COMP-012-006 são tasks à parte). O `:id`
(`rawContentId`) da rota é resolvido reusando `rawContentIdParamSchema` de
`contents.schema.ts` (confirmado por leitura: `mnemonicos-backend/src/modules/contents/
contents.schema.ts:103-107`, `{ id: z.uuid('Identificador de conteúdo bruto inválido.') }`)
— esta TASK não recria esse parâmetro.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/tira/tira.schema.ts` (novo arquivo):
  - `addMnemonicFrameSchema` — `text` (`z.string().trim().min(1, ...)`, mensagem pt-BR),
    `position` (`z.number().int().min(1, ...)`, mensagem pt-BR).
  - `updateMnemonicFrameSchema` — `text` (mesma regra de `addMnemonicFrameSchema`).
  - `reorderMnemonicFramesSchema` — `order` (`z.array(z.uuid(...), ...).min(1, ...)`,
    array completo de ids de Quadro na sequência final desejada — mesma semântica do §4
    F-5 do PLAN).
  - `mnemonicFrameIdParamSchema` — `frameId` (`z.uuid('Identificador de quadro
    inválido.')`).
  - Nenhuma declaração local do parâmetro `:id` — o consumidor real
    (`tira.routes.ts`, COMP-012-006) importa `rawContentIdParamSchema` direto de
    `contents.schema`, quando existir; `tira.schema.ts` não precisa importar nem
    reexportar um símbolo que ele mesmo não consome (achado A1 do code-reviewer,
    convergência da Wave 1 — endereço especulativo removido).
  - Tipos-união inferidos (`z.infer<typeof ...>`) para cada schema, no mesmo padrão de
    `CreateRawContentInput`/`SaveRuleBreakdownInput`.
- `mnemonicos-backend/tests/unit/tira.schema.test.ts` (novo): caso válido e caso inválido
  (com mensagem pt-BR asserida) para cada um dos 4 schemas.

### Não inclui

- Qualquer rota (`tira.routes.ts`, COMP-012-006) ou service (`tira.service.ts`,
  COMP-012-004) — schemas só validam forma de entrada, sem I/O.
- Redeclaração de `rawContentIdParamSchema` — reusado por import.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Criar `tira.schema.ts` importando `rawContentIdParamSchema` de `../contents/
   contents.schema` (comentário declarando o reuso, mesmo estilo de `contents.schema.ts`).
2. Declarar os 4 schemas Zod com mensagens pt-BR (molde de `contents.schema.ts`:
   `z.string().trim().min(1, 'Informe ...')`, `z.uuid('Identificador ... inválido.')`).
3. Exportar os 4 tipos inferidos.
4. Escrever `tira.schema.test.ts` com 1 caso válido + 1 caso inválido (mensagem pt-BR) por
   schema (8 casos no total).

## Critérios de pronto

- [ ] `addMnemonicFrameSchema` aceita `{ text: 'CONCEITO reescrito', position: 1 }` e
      rejeita `{ text: '', position: 0 }` com mensagem em português para os dois campos —
      item do Inclui sem AC, oráculo é o contrato do próprio schema. Verificação
      executável: `npm --prefix mnemonicos-backend test -- tira.schema` →
      `Tests: ≥2 passed` (caso válido + caso inválido deste schema), com o caso inválido
      asserindo `result.error.issues.some(i => /informe|texto/i.test(i.message))` e
      `/posição|position/i.test(...)` — mensagens em pt-BR, nunca em inglês. Fixada antes
      do código.
- [ ] `updateMnemonicFrameSchema` aceita `{ text: 'Ação revisada' }` e rejeita
      `{ text: '' }` com mensagem pt-BR — mesma verificação executável acima, arquivo
      `tira.schema`, caso próprio deste schema.
- [ ] `reorderMnemonicFramesSchema` aceita `{ order: ['<uuid1>', '<uuid2>'] }` (≥1 item) e
      rejeita `{ order: [] }` com mensagem pt-BR sobre lista mínima, e rejeita
      `{ order: ['nao-e-uuid'] }` com mensagem pt-BR sobre formato de identificador —
      mesma verificação executável, 2 casos inválidos distintos (lista vazia × item mal
      formado) além do caso válido.
- [ ] `mnemonicFrameIdParamSchema` aceita um UUID v7 válido e rejeita
      `{ frameId: 'nao-e-uuid' }` com mensagem pt-BR (`'Identificador de quadro
      inválido.'` ou equivalente) — mesma verificação executável.
- [x] `tira.schema.ts` NÃO redeclara nem reexporta o parâmetro `:id` (condição do
      domínio, não endereço de import — corrigido na convergência da Wave 1, achado
      R1: a metade que exigia grep de import virou insatisfazível quando A1 removeu o
      único consumidor) — verificação executável: `grep -cE "^export const
      \w*[Ii]d[Pp]aram[Ss]chema" mnemonicos-backend/src/modules/tira/tira.schema.ts`
      → `1` (só `mnemonicFrameIdParamSchema`); controle positivo do mesmo grep em
      `contents.schema.ts` → `1` (o padrão bate onde deve). Falsificável: redeclarar
      `{ id: z.uuid(...) }` local faria o grep casar `2`, vermelho. Confirmado
      cumprido pelo `code-reviewer` na convergência (commit `24f7cf3`).
- [ ] Todo texto de mensagem de validação está em português do Brasil (NFR-011-005, parte)
      — verificação executável: `grep -oE "'[^']*'" mnemonicos-backend/src/modules/tira/
      tira.schema.ts | grep -vE "informe|inválid|obrigat|posição|sequência|identificador"`
      → sem resultado além de valores não-mensagem (nomes de campo/regex) — leitura manual
      confirma ausência de mensagem em inglês.
- [ ] Sem warnings/lints novos (`npm --prefix mnemonicos-backend run lint` → exit 0).
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem (Zod 4 — `z.uuid()`/
      `z.string()` no formato de topo, não `.email()`/`.uuid()` encadeado do legado).
- [ ] Code review aprovado.

## Riscos específicos

- Nenhuma lição ativa de `guidelines/project/lessons.md` nomeia `tira.schema.ts` ou o
  padrão que ele encarna (confirmado por leitura — a lição sobre `z.coerce.boolean()` não
  se aplica, nenhum campo booleano nesta TASK).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-06T19:10:02-0300
**Data conclusão**: 2026-09-06T19:35:45-0300
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 24f7cf3 (implementação inicial `19e5834`, retry de convergência `24f7cf3`)
**Jira**: KAN-53
**Implementado por**: developer
**Revisado por**: code-reviewer (REPROVADO na 1ª rodada — achados A1/A2; CONVERGIU no re-review delta-scoped)
**Tentativas**: 2 (1 retry, roteado pelos achados A1/A2 do code-reviewer)
**Cobertura final**: n/a (item do Inclui sem AC — oráculo é o contrato do próprio item; override `task-criterio-sem-ac` registrado no topo da TASK)
**Arquivos modificados**:
  - mnemonicos-backend/src/modules/tira/tira.schema.ts
  - mnemonicos-backend/tests/unit/tira.schema.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (10/10, mesma contagem antes/depois do retry)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (convergiu após retry — export especulativo removido, regra `text` deduplicada em `frameTextSchema`)
- [x] ACs verificados (n/a — sem AC numerado)
- [x] Segurança (gate 8): n/a — refactor puro de schema, sem I/O/authz/cripto (nota do security-engineer na Wave 1: nenhuma superfície nova)
- [x] Comportamento (gate 9): n/a — schema de validação, sem efeito observável

**Notas**: achados A1 (export especulativo de `rawContentIdParamSchema`) e A2 (duplicação da regra `text`) corrigidos no retry; critério de pronto #5 e o Escopo>Inclui desta TASK foram emendados na convergência (achado R1 do code-reviewer) para descrever a condição do domínio em vez do endereço de import que a própria correção invalidou.

**Notas**:
