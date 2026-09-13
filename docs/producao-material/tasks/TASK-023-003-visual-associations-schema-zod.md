# TASK-023-003: Criar `visual-associations.schema.ts` — validação Zod

**Slug**: producao-material
**Pertence a**: PLAN-023
**Realiza (FRs)**: FR-022-004
**Funcionalidade**: FEAT-022-001 (primária)
**Componente**: COMP-023-001 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

```yaml
override-erros: task-criterio-sem-ac
override-justificativa: >-
  Item do Inclui sem AC vinculado — oráculo é o contrato do próprio schema
  (contrato do /keelson:tasks, Etapa 3: "Sem AC, o oráculo é o contrato do
  próprio item", regra 4.286). A recusa OBSERVÁVEL de AC-022-004 só se prova
  com a rota+service consumindo este schema (TASK-023-008, fora desta lista);
  aqui cada campo fecha por contrato próprio (não-nulo × faltante/vazio).
  Mesmo padrão de TASKs chore/schema aprovadas do slug (TASK-006-004,
  TASK-006-007, TASK-012-003, TASK-012-010 — todas Done, sem AC numerado). O
  check mecânico task-criterio-sem-ac não distingue esse caso legítimo;
  registrado como pendência de processo (lição candidata ao agile-coach).
override-aprovador: Tech Lead (autônomo, /keelson:auto)
```

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch do EPICO MNEMORA STUDIO, Estrategia unica -- decisao 4.126: F5 e uma fatia do epico, nunca abre branch propria; a sessao ja fez o sync de largada nela)

**Padrão de commit**: Conventional Commits (`feat:`).
**Framework de teste**: Jest 30 + ts-jest (`npm --prefix mnemonicos-backend test`).

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-023-008

## Contexto

Fronteira de validação de entrada do módulo `visual-associations/` (padrão em camadas
`schema → service → routes`, mesmo padrão de `contents.schema.ts`/`tira.schema.ts`). Os 5
schemas cobrem os campos de texto da associação (`category`/`cognitiveDescription`), o
param `:id`, a query de listagem (`category?`/`page?`/`perPage?`) e a de sugestão de
categoria (`q`) — o arquivo enviado (multipart) não passa pelo Zod, é validado por
assinatura de bytes no service (COMP-023-002/COMP-023-005, fora desta lista). Nenhuma rota
nem service entra nesta TASK.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/visual-associations/visual-associations.schema.ts` (novo
  arquivo):
  - `createVisualAssociationBodySchema` — `category` (`z.string().trim().min(1, 'Informe a
    categoria.')`), `cognitiveDescription` (`z.string().trim().min(1, 'Informe a função
    cognitiva da imagem.')`).
  - `updateVisualAssociationBodySchema` = `createVisualAssociationBodySchema.partial()`.
  - `visualAssociationIdParamSchema` — `id: z.uuid('Identificador de associação visual
    inválido.')`.
  - `listVisualAssociationsQuerySchema` — `category?: z.string().trim().min(1).optional()`,
    `page: z.coerce.number().int().min(1).default(1)`, `perPage: z.coerce.number().int()
    .min(1).max(100).default(20)` — mesmo padrão de `listRawContentsQuerySchema`
    (`contents.schema.ts:91-94`, irmão canônico já mergeado).
  - `suggestCategoriesQuerySchema` — `q: z.string().trim().min(1)`.
  - Tipos-união inferidos (`z.infer<typeof ...>`) para cada schema, mesmo padrão de
    `CreateRawContentInput`/`SaveRuleBreakdownInput`.
- `mnemonicos-backend/tests/unit/visual-associations.schema.test.ts` (novo): caso válido e
  caso inválido (campo ausente/vazio, mensagem pt-BR asserida) para cada um dos 5 schemas,
  mais os 2 casos extras de `listVisualAssociationsQuerySchema` (defaults e teto de
  `perPage`) descritos abaixo.

### Não inclui

- Validação do arquivo binário (assinatura de bytes) — `image-signature.ts`, TASK-023-002,
  fora do Zod.
- Consumo em rota/service (COMP-023-005/COMP-023-006, fora desta lista).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Criar `visual-associations.schema.ts`, autocontido (sem import de `contents.schema.ts` —
   os campos são próprios do domínio novo).
2. Comparar cada schema, linha a linha, contra `contents.schema.ts` e `tira.schema.ts`
   (irmãos canônicos já mergeados) antes de fechar — lição ativa citada no PLAN (§Lições):
   a lista de "Interface pública" do PLAN é contrato mínimo, não gabarito de transcrição
   cega.
3. Escrever os casos de `visual-associations.schema.test.ts` (2 por schema + 2 extras de
   paginação).

## Critérios de pronto

- [ ] `createVisualAssociationBodySchema` aceita `{ category: 'Tributário',
      cognitiveDescription: 'Ilustra o fato gerador.' }` e rejeita `{ category: '',
      cognitiveDescription: '' }` (e a ausência dos dois campos) com mensagem pt-BR — item
      do Inclui sem AC, oráculo é o contrato do próprio schema (regra 4.286). Verificação
      executável: `npm --prefix mnemonicos-backend test -- visual-associations.schema` →
      `Tests: ≥2 passed` para este schema. Fixada antes do código.
- [ ] `updateVisualAssociationBodySchema` aceita `{ category: 'Nova categoria' }` isolado
      (parcial) e rejeita `{ category: '' }` com a mesma mensagem de
      `createVisualAssociationBodySchema` — confirma o `.partial()` sem duplicar a regra.
- [ ] `visualAssociationIdParamSchema` aceita um UUID v7 válido e rejeita `{ id:
      'nao-e-uuid' }` com mensagem pt-BR.
- [ ] `listVisualAssociationsQuerySchema` aceita `{}` (defaults `page: 1`/`perPage: 20`),
      aceita `{ category: 'Tributário', page: '2', perPage: '50' }` coagindo string para
      número, e rejeita `{ perPage: '101' }` (teto 100) — mesmo padrão de
      `listRawContentsQuerySchema` (`contents.schema.ts:91-94`). Verificação executável:
      mesmo comando, 3 casos (default, coerção, teto).
- [ ] `suggestCategoriesQuerySchema` aceita `{ q: 'trib' }` e rejeita `{ q: '' }`/ausência
      com mensagem pt-BR.
- [ ] Todo texto de mensagem de validação está em português do Brasil — verificação por
      leitura manual do arquivo (mesma régua de TASK-012-003).
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff, `git diff --name-only
      main...HEAD`).
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil (Zod 4 — `z.uuid()`/`z.string()` no
      formato de topo, não `.email()`/`.uuid()` encadeado do legado).
- [ ] Code review aprovado.

## Riscos específicos

- Nenhuma lição ativa de `guidelines/project/lessons.md` nomeia
  `visual-associations.schema.ts` diretamente; a lição "[Testes] Comentário que afirma
  paridade..." não se aplica (nenhum comentário de espelho cross-repo neste arquivo).
- A comparação contra `contents.schema.ts`/`tira.schema.ts` (irmãos canônicos) é exigida no
  Escopo, não invenção de padrão novo — evitar reinventar mensagem/estilo já em uso.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-13T19:22:01+0000
**Data conclusão**: 2026-09-13T19:28:53+0000
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: d19c238
**Jira**: KAN-91
**Implementado por**: developer
**Revisado por**: code-reviewer (gate 1-7, wave 1)
**Tentativas**: 1
**Cobertura final**: n/a (268/268 verde)
**Arquivos modificados**:
  - mnemonicos-backend/src/modules/visual-associations/visual-associations.schema.ts
  - mnemonicos-backend/tests/unit/visual-associations.schema.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [ ] Segurança (gate 8): n/a — validação de forma (Zod), não superfície sensível isolada (a superfície de upload real é TASK-023-008)
- [ ] Comportamento (gate 9): n/a — schema sem efeito observável de tela

**Notas**: `z.string({ error: msg })` + `.min(1, msg)` (dois mecanismos, não redundantes —
confirmado por execução contra Zod 4.4.3 pelo code-reviewer) cobre ausência E vazio com
mensagem pt-BR; a "Interface pública" do PLAN era contrato mínimo, não transcrição.

**Notas**:
