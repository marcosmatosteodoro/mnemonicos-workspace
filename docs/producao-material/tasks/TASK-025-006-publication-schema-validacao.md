# TASK-025-006: publication.schema.ts — validação Zod do corpo/param

**Slug**: producao-material
**Pertence a**: PLAN-025
**Realiza (FRs)**: nenhuma
**Componente**: COMP-025-001 (principal)
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: TASK-025-002
- **Bloqueia**: TASK-025-009

## Contexto

Fronteira Zod de `POST /contents/:id/publication` (COMP-025-001) — schema do param `:id`
e do corpo `{ variant }`, reusando `PUBLICATION_VARIANTS` de `domain/types.ts`
(TASK-025-002) em vez de redeclarar o vocabulário. Consumido por `publication.routes.ts`
(TASK-025-009), fora desta lista.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/publication/publication.schema.ts` (novo arquivo,
  módulo `publication` — schema→service→routes, mesmo padrão de
  `visual-associations.schema.ts`/`contents.schema.ts`):
  ```ts
  export const exportPublicationParamsSchema = z.object({
    id: z.uuid('Identificador de conteúdo bruto inválido.'),
  });

  export const exportPublicationBodySchema = z.object({
    variant: z.enum(PUBLICATION_VARIANTS),
  });
  export type ExportPublicationBodyInput = z.infer<typeof exportPublicationBodySchema>;
  ```
  `PUBLICATION_VARIANTS` importado de `../../domain/types` (TASK-025-002) — nunca
  redeclarado como array literal `['TIRA','RESUMO']` neste arquivo (lição [Código] DRY).
  `z.uuid(<mensagem>)` é o mesmo padrão já em uso em
  `visual-associations.schema.ts:47` (`visualAssociationIdParamSchema`), confirmado por
  leitura direta.
- `mnemonicos-backend/tests/unit/publication.schema.test.ts` (novo).

### Não inclui

- Consumo do schema nas rotas (`publication.routes.ts`, TASK-025-009).
- Declaração de `PUBLICATION_VARIANTS`/`PublicationVariant` (TASK-025-002, já entregue
  como dependência).

## Critérios de pronto

- [ ] Contrato do próprio item (sem AC — schema de validação sem FR/AC dedicado nesta
      wave, mesmo padrão de `visual-associations.schema.ts`/TASK-023-003):
      `exportPublicationParamsSchema.safeParse({ id: 'não-é-uuid' })` reprova com a
      mensagem `'Identificador de conteúdo bruto inválido.'`; `safeParse({ id: '<uuid
      válido>' })` aprova. Verificação executável: `npm --prefix mnemonicos-backend
      test -- publication.schema` → `OK (N tests)`. Fixada antes do código.
- [ ] `exportPublicationBodySchema.safeParse({ variant: 'RESUMO' })` e `{ variant: 'TIRA'
      }` aprovam; `{ variant: 'tira' }` (minúsculo), `{ variant: 'PDF' }` e `{}`
      (ausente) reprovam — mesmo comando.
- [ ] `PUBLICATION_VARIANTS` REUSADO, nunca redeclarado (lição [Código] DRY, mesma lição
      de TASK-025-002): verificação estrutural (condição, item b da régua de contorno)
      — `grep -n "z.enum(PUBLICATION_VARIANTS)"
      mnemonicos-backend/src/modules/publication/publication.schema.ts` → 1 ocorrência;
      `grep -c "'TIRA'" mnemonicos-backend/src/modules/publication/publication.schema.ts`
      → `0` (nenhum literal `'TIRA'`/`'RESUMO'` solto no arquivo, só via
      `PUBLICATION_VARIANTS` importado) — universo de busca = arquivo inteiro.
      Falsificável: redigitar `z.enum(['TIRA','RESUMO'])` no lugar do import casaria o 2º
      grep.
- [ ] `ExportPublicationBodyInput` (`z.infer`) exercitado com valor não-nulo (`{ variant:
      'TIRA' }` tipado, sem erro de compilação) — item do Inclui sem AC isolado, oráculo
      é o contrato do próprio item.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npm --prefix mnemonicos-backend run lint` → exit 0.

## Riscos específicos

- n/a — schema puro sem I/O, sem superfície de segurança própria (a barreira de
  autorização e origem é da rota, TASK-025-009).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-14T16:20:46-0300
**Data conclusão**: 2026-09-14T16:23:42-0300
**Commit SHA**: 11584fe (schema) · f7d2511 (achado F4, dedup de rawContentIdParamSchema)
**Jira**: KAN-113

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (Wave 2, 1 achado próprio — F4/DRY — fechado no retry consolidado)
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 2)
- [x] Comportamento (gate 9): consolidado (DoD, Etapa 4) — SPEC-024 sem FEATs
