# TASK-023-005: Estender `types/domain.ts` (frontend) com `VisualAssociation`/`VisualAssociationSummary`

**Slug**: producao-material
**Pertence a**: PLAN-023
**Realiza (FRs)**: FR-022-016
**Funcionalidade**: FEAT-022-003 (primária)
**Componente**: COMP-023-010 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

```yaml
override-erros: task-criterio-sem-ac
override-justificativa: >-
  Item do Inclui sem AC isolado fechado nesta TASK: a exibição observável
  (AC-022-013) fecha em TASK-023-013/gate 9, fora desta lista. Aqui o oráculo
  é o contrato do próprio item (regra 4.286) — interface exercitada com valor
  não-nulo. Mesmo padrão de TASK-012-009 (Done, mesma classe de mudança —
  espelho de tipos no frontend, sem AC numerado).
override-aprovador: Tech Lead (autônomo, /keelson:auto)
```

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch do EPICO MNEMORA STUDIO, Estrategia unica -- decisao 4.126: F5 e uma fatia do epico, nunca abre branch propria; a sessao ja fez o sync de largada nela)

**Padrão de commit**: Conventional Commits (`feat:`).
**Framework de teste**: Jest via `next/jest` (`npm --prefix mnemonicos-frontend test`).

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-023-007, TASK-023-017

## Contexto

Espelha, no frontend, o formato que `visual-associations.service.ts` (backend, COMP-023-005,
fora desta lista) devolve — `VisualAssociationDetail`/`VisualAssociationSummary` — e
acrescenta `visualAssociationId` a `MnemonicFrame` (arquivo já existente,
`mnemonicos-frontend/src/types/domain.ts:204-209`, 4 campos hoje: `id`, `text`, `position`,
`originBlock`; o array cresce para 5). Mesma resolução já aplicada a
`MnemonicFrame`/`MnemonicStrip` em TASK-012-009: o contrato é provado pela rede de paridade
cross-repo (COMP-023-011, `visual-associations-frontend-contract.test.ts` +
`tira-frontend-contract.test.ts` estendido), não pela declaração em si — esta TASK não a
redige (fora desta lista, TASK-023-017).

## Escopo

### Inclui

- `mnemonicos-frontend/src/types/domain.ts`:
  - `interface MnemonicFrame` (linhas 204-209 atuais) ganha o 5º campo
    `visualAssociationId: string | null` — sem remover nem reordenar os 4 campos já
    existentes.
  - `interface VisualAssociation` nova:
    ```ts
    export interface VisualAssociation {
      id: string;
      authorId: string;
      category: string;
      cognitiveDescription: string;
      mimeType: string;
      createdAt: string;
      updatedAt: string;
    }
    ```
  - `interface VisualAssociationSummary` nova:
    ```ts
    export interface VisualAssociationSummary {
      id: string;
      category: string;
      linkCount: number;
      createdAt: string;
    }
    ```
    — datas como `string` (ISO), mesmo padrão de `RawContent`/`RuleBreakdown` já no
    arquivo.
  - Comentário de fonte (mesmo estilo de `MnemonicFrame`/`MnemonicStrip`, linhas 195-203):
    declara que o formato REAL vem de `VisualAssociationDetail`/`VisualAssociationSummary`
    em `mnemonicos-backend/src/modules/visual-associations/visual-associations.service.ts`
    e que a rede de paridade cross-repo é
    `mnemonicos-backend/tests/unit/visual-associations-frontend-contract.test.ts`
    (COMP-023-011, TASK-023-017, ainda a criar) — o comentário NÃO afirma que a paridade já
    é testada aqui (lição ativa "[Testes] Comentário que afirma paridade entre os dois
    repos só vale se o teste LER as duas fontes").
- `mnemonicos-frontend/tests/types/visual-association.test.ts` (novo): uso não-nulo —
  constrói um `VisualAssociation` e um `VisualAssociationSummary` literais acessando cada
  campo; e 2 objetos `MnemonicFrame` (1 com `visualAssociationId: null`, 1 com
  `visualAssociationId: '<uuid>'`).

### Não inclui

- A rede de paridade cross-repo real (`visual-associations-frontend-contract.test.ts` +
  extensão de `tira-frontend-contract.test.ts`) — TASK-023-017, fora desta lista.
- Consumo destes tipos em `src/store/api.ts` (TASK-023-007) ou em qualquer tela
  (COMP-023-013 a 016).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Acrescentar `visualAssociationId: string | null` a `interface MnemonicFrame`
   (`domain.ts:204-209`).
2. Acrescentar `interface VisualAssociation`/`VisualAssociationSummary`, no mesmo bloco de
   estilo de `RawContent`/`RuleBreakdown`/`MnemonicFrame` (docblock de fonte canônica).
3. Escrever `tests/types/visual-association.test.ts` com os 3 objetos literais.

## Critérios de pronto

- [ ] `mnemonicos-frontend/src/types/domain.ts` exporta `interface VisualAssociation`
      (`id`, `authorId`, `category`, `cognitiveDescription`, `mimeType`, `createdAt:
      string`, `updatedAt: string`) e `interface VisualAssociationSummary` (`id`,
      `category`, `linkCount: number`, `createdAt: string`) — item do Inclui sem AC
      isolado, oráculo é o contrato do próprio item (uso não-nulo). Verificação
      executável: `npm --prefix mnemonicos-frontend test -- visual-association` →
      `Tests: ≥1 passed` — o teste constrói os 2 objetos literais e afirma o valor de cada
      campo. Falsificável: omitir um campo da interface faz o objeto literal do teste
      falhar o typecheck. Fixada antes do código.
- [ ] `interface MnemonicFrame` ganha `visualAssociationId: string | null` como 5º campo,
      sem remover os 4 existentes — mesma verificação executável, 1 caso com
      `visualAssociationId: null` e 1 com `visualAssociationId: '<uuid>'`, cada um
      afirmando o valor dos 5 campos.
- [ ] `npm --prefix mnemonicos-frontend run typecheck` → exit 0.
- [ ] O comentário de fonte de `VisualAssociation`/`VisualAssociationSummary` declara (i)
      que o formato real vem de `mnemonicos-backend/src/modules/visual-associations/
      visual-associations.service.ts` (`VisualAssociationDetail`/`VisualAssociationSummary`)
      e (ii) aponta `mnemonicos-backend/tests/unit/
      visual-associations-frontend-contract.test.ts` como a rede de paridade cross-repo
      (ainda a criar) — sem afirmar que a paridade já é testada por esta TASK. Verificação
      executável (contrato §273(b)): `grep -nE "visual-associations\.service\.ts|
      visual-associations-frontend-contract" mnemonicos-frontend/src/types/domain.ts` → ao
      menos 1 âncora de fonte e 1 de teste. Falsificável: comentário ausente faz o `grep`
      vir vazio, vermelho.
- [ ] Sem warnings/lints novos (`npm --prefix mnemonicos-frontend run lint` → exit 0).
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil (`next-16.md` §3 — identificadores em
      inglês; sem texto de interface pt-BR aplicável aqui, arquivo de tipos puro).
- [ ] Code review aprovado.

## Riscos específicos

- A prova de paridade real cross-repo (o formato aqui bater com o que
  `visual-associations.service.ts` de fato devolve) é da TASK-023-017, fora desta lista —
  esta TASK não a redige; o formato declarado aqui é o congelado no PLAN §3, não
  verificado contra código real de serviço ainda.
- Lição ativa citada no PLAN §Lições (5ª reincidência, madura): nenhum comentário deste
  arquivo pode afirmar "espelho de X do backend" sem que exista teste que LEIA as duas
  fontes — esta TASK descreve a origem sem prometer a paridade.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Branch**:
**Commit SHA**:
**Jira**: KAN-93
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
