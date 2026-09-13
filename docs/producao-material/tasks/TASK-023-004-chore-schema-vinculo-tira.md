# TASK-023-004: Estender `tira.schema.ts` — schema do vínculo de associação visual

**Slug**: producao-material
**Pertence a**: PLAN-023
**Realiza (FRs)**: nenhuma
**Componente**: COMP-023-007 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Todo

```yaml
override-erros: task-criterio-sem-ac
override-justificativa: >-
  Item do Inclui sem AC vinculado — oráculo é o contrato do próprio item
  (regra 4.286): COMP-023-007 é dependência pura, consumida por TASK-023-011
  (fora desta lista), sem FR realizado diretamente. Mesmo padrão de TASKs
  chore/schema aprovadas do slug (TASK-006-004, TASK-006-007, TASK-012-003,
  TASK-012-010 — todas Done, sem AC numerado). Registrado como pendência de
  processo (lição candidata ao agile-coach).
override-aprovador: Tech Lead (autônomo, /keelson:auto)
```

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch do EPICO MNEMORA STUDIO, Estrategia unica -- decisao 4.126: F5 e uma fatia do epico, nunca abre branch propria; a sessao ja fez o sync de largada nela)

**Padrão de commit**: Conventional Commits (`chore:` — schema de validação sem lógica de
negócio, dependência pura consumida só a partir de TASK-023-011).
**Framework de teste**: Jest 30 + ts-jest (`npm --prefix mnemonicos-backend test`).

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-023-011

## Contexto

Extensão pontual de `tira.schema.ts` (arquivo existente, COMP-012-003/TASK-012-003) com o
schema do corpo de `POST/DELETE .../frames/:frameId/visual-association` (COMP-023-007) —
`frameTextSchema`/`mnemonicFrameIdParamSchema`, já no arquivo, são o molde de estilo. Esta
TASK não realiza nenhum FR diretamente: é dependência pura consumida pela extensão de
`tira.service.ts`/`tira.routes.ts` em TASK-023-011, fora desta lista.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/tira/tira.schema.ts` (arquivo existente): acrescentar, ao
  final do arquivo,
  ```ts
  export const linkVisualAssociationSchema = z.object({
    visualAssociationId: z.uuid('Identificador de associação visual inválido.'),
  });
  export type LinkVisualAssociationInput = z.infer<typeof linkVisualAssociationSchema>;
  ```
  — mesmo molde de `mnemonicFrameIdParamSchema` já no arquivo (`z.uuid(...)` de topo,
  mensagem pt-BR, tipo inferido homônimo).
- `mnemonicos-backend/tests/unit/tira.schema.test.ts` (arquivo existente): 1 caso válido
  (UUID v7 real) + 1 caso inválido (`'nao-e-uuid'`) para `linkVisualAssociationSchema`.

### Não inclui

- Rota/service que consomem este schema (COMP-023-008/COMP-023-009, TASK-023-011, fora
  desta lista).
- Qualquer alteração nos 4 schemas já existentes de `tira.schema.ts`
  (`addMnemonicFrameSchema`/`updateMnemonicFrameSchema`/`reorderMnemonicFramesSchema`/
  `mnemonicFrameIdParamSchema`).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Acrescentar `linkVisualAssociationSchema` ao final de `tira.schema.ts`, comparando
   contra `mnemonicFrameIdParamSchema`/`frameTextSchema` (molde já no arquivo) antes de
   fechar — mesma lição ativa da TASK-023-003.
2. Acrescentar os 2 casos a `tira.schema.test.ts`, sem tocar os casos já existentes.

## Critérios de pronto

- [ ] `linkVisualAssociationSchema` aceita `{ visualAssociationId: '<uuid v7>' }` e rejeita
      `{ visualAssociationId: 'nao-e-uuid' }` com mensagem pt-BR (`'Identificador de
      associação visual inválido.'` ou equivalente) — item do Inclui sem AC, oráculo é o
      contrato do próprio schema (regra 4.286). Verificação executável: `npm --prefix
      mnemonicos-backend test -- tira.schema` → a contagem de testes do arquivo cresce em
      +2 (1 válido + 1 inválido), todos verdes. Fixada antes do código.
- [ ] Nenhum dos 4 schemas já existentes em `tira.schema.ts` é alterado — verificação
      executável: `git diff main...HEAD -- mnemonicos-backend/src/modules/tira/
      tira.schema.ts` mostra só linhas adicionadas (nenhuma linha removida/modificada
      dentro de `addMnemonicFrameSchema`/`updateMnemonicFrameSchema`/
      `reorderMnemonicFramesSchema`/`mnemonicFrameIdParamSchema`). Falsificável: qualquer
      linha removida dentro desses 4 blocos reprova este critério.
- [ ] Mensagem em português do Brasil.
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff, `git diff --name-only
      main...HEAD`).
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil (Zod 4 — `z.uuid()` de topo).
- [ ] Code review aprovado.

## Riscos específicos

- Lição ativa "comparar contra o irmão canônico já mergeado" (mesma da TASK-023-003) —
  `mnemonicFrameIdParamSchema`/`frameTextSchema` são o molde real, não a lembrança do nome.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Branch**:
**Commit SHA**:
**Jira**: KAN-92
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
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a>

**Notas**:
