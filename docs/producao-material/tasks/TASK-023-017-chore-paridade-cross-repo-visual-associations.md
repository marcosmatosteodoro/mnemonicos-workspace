# TASK-023-017: Rede de paridade cross-repo — `visual-associations-frontend-contract.test.ts` (novo) + extensão de `tira-frontend-contract.test.ts`

**Slug**: producao-material
**Pertence a**: PLAN-023
**Realiza (FRs)**: nenhuma
**Componente**: COMP-023-011 (principal)
**Wave**: 6
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Todo

```yaml
override-erros: task-criterio-sem-ac
override-justificativa: >-
  Sem AC de produto (teste de paridade cross-repo puro — o contrato do próprio
  item, regra 4.286, é "mutante que renomeia o campo só de um lado reprova").
  Mesmo padrão de TASK-012-011 (chore de paridade cross-repo, Done) e de
  TASK-023-003/005/015 (schema/tipos/casca, mesma decomposição, sem AC
  numerado).
override-aprovador: Tech Lead (autônomo, /keelson:auto)
```

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch do EPICO MNEMORA STUDIO, Estrategia unica -- decisao 4.126: F5 e uma fatia do epico, nunca abre branch propria; a sessao ja fez o sync de largada nela)

**Padrão de commit**: Conventional Commits (`commit.convention: "conventional"`) — `chore:`
(arquivo de teste novo/estendido, nenhum código de produção).
**Framework de teste**: Jest 30 + ts-jest (`npm --prefix mnemonicos-backend test`) — leitura
textual dos dois repos (sem AST), mesmo mecanismo de `tira-frontend-contract.test.ts`/
`domain-types-parity.test.ts`.

## Dependências

- **Depende de**: TASK-023-005, TASK-023-008, TASK-023-010, TASK-023-011, TASK-023-014
- **Bloqueia**: nenhuma

## Contexto

`tira-frontend-contract.test.ts`
(`mnemonicos-backend/tests/unit/tira-frontend-contract.test.ts:1-87`, lido integralmente
nesta redação) é o molde exato: lê os dois arquivos como texto (`readSourceFile`,
`existsSync` + `throw` se o repo irmão faltar) e compara `extractInterfaceFields(...)`
campo-a-campo, sem AST, contra um array literal esperado — nunca um fixture que se
autoconfirma. Hoje ele compara `MnemonicFrameDetail`/`MnemonicFrame` (4 campos: `id`, `text`,
`position`, `originBlock`) e `MnemonicStripDetail`/`MnemonicStrip` (`id`, `frames`). Com
TASK-023-005 tendo acrescentado `visualAssociationId` a `MnemonicFrame` (frontend) e
TASK-023-008/010/011/014 tendo fechado `VisualAssociationDetail`/`VisualAssociationSummary`
(backend, `visual-associations.service.ts`), falta (1) estender esta comparação para 5
campos e (2) criar o arquivo NOVO que compara as interfaces do acervo.

## Escopo

### Inclui

- ~~`mnemonicos-backend/tests/unit/tira-frontend-contract.test.ts` (EMENDA — array 4→5
  campos)~~ — **JÁ ENTREGUE na Wave 1** (retry sobre achado bloqueante do `code-reviewer`,
  commit `84b1f08` de TASK-023-005 — a rede de paridade já compara os 5 campos, incluindo
  `visualAssociationId`, mutante de renomear já provado morto na rodada 2 do gate 1-7).
  Nada a fazer aqui além de confirmar que segue verde.
- `mnemonicos-backend/tests/unit/visual-associations-frontend-contract.test.ts` (novo) —
  MOLDE LITERAL de `tira-frontend-contract.test.ts` (mesmas funções `readSourceFile`/
  `extractInterfaceFields`, reaproveitadas por import ou reimplementadas idênticas se o
  arquivo original não as exportar — confirmar antes de escrever se `tira-frontend-
  contract.test.ts` exporta algo ou se cada arquivo de paridade tem sua própria cópia local,
  mesmo padrão de `domain-types-parity.test.ts`, que tem suas próprias funções): compara
  `VisualAssociationDetail`/`VisualAssociationSummary`
  (`mnemonicos-backend/src/modules/visual-associations/visual-associations.service.ts`) contra
  `VisualAssociation`/`VisualAssociationSummary`
  (`mnemonicos-frontend/src/types/domain.ts`, TASK-023-005) campo-a-campo:
  - `VisualAssociationDetail`/`VisualAssociation`: `id`, `authorId`, `category`,
    `cognitiveDescription`, `mimeType`, `createdAt`, `updatedAt` (7 campos).
  - `VisualAssociationSummary` (os dois lados, mesmo nome): `id`, `category`, `linkCount`,
    `createdAt` (4 campos).
  - Mutante: renomear `visualAssociationId`/qualquer campo do acervo só de um lado faz o
    teste correspondente reprovar.

### Não inclui

- Qualquer alteração de produto — só teste (chore).
- A declaração das interfaces em si (backend: TASK-023-008/010/014; frontend:
  TASK-023-005) — esta TASK só as LÊ e compara.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Ler `tira-frontend-contract.test.ts` por inteiro (já feito nesta redação) e copiar a
   MESMA estrutura (`readSourceFile`, `extractInterfaceFields`, `describe`/`it` por par de
   interfaces) para o arquivo novo — trocando só os caminhos e os nomes de interface.
2. Confirmar, por leitura direta do backend real (`visual-associations.service.ts`, já
   mergeado pelas TASKs anteriores desta wave), a lista EXATA de campos de
   `VisualAssociationDetail`/`VisualAssociationSummary` antes de fixar o array esperado —
   nunca copiar do PLAN de memória (o PLAN é a intenção original; o arquivo real, já
   implementado por TASK-023-008/010/014, é a fonte).
3. Conferir também se o valor de exemplo de qualquer fixture citado neste arquivo
   (`visualAssociationId`/`category`/`mimeType`) passaria no Zod real do backend
   (`visual-associations.schema.ts`, TASK-023-003) — lição "[Testes] Comentário que afirma
   paridade..." estendida: fixture de exemplo que não passaria no schema real é o mesmo
   defeito de um comentário que promete paridade sem ler as duas fontes.

## Critérios de pronto

- [ ] Contrato do próprio item (sem AC — override acima): `visual-associations-frontend-
      contract.test.ts` importa/lê os dois arquivos reais (nunca um fixture local que se
      autoconfirma) e falha com uma mensagem clara se o repo irmão
      (`mnemonicos-frontend`) não existir no workspace (mesmo padrão de `readSourceFile` já
      usado por `tira-frontend-contract.test.ts:28-37`).
- [ ] `VisualAssociationDetail`/`VisualAssociation`: mesmo conjunto de 7 campos (`id`,
      `authorId`, `category`, `cognitiveDescription`, `mimeType`, `createdAt`, `updatedAt`)
      nos dois repositórios — mutante: renomear `cognitiveDescription` só do frontend (ex.:
      `description`) faz este caso reprovar.
- [ ] `VisualAssociationSummary`: mesmo conjunto de 4 campos (`id`, `category`, `linkCount`,
      `createdAt`) nos dois repositórios — mutante: renomear `linkCount` só do backend faz
      este caso reprovar.
- [ ] `tira-frontend-contract.test.ts` (EMENDA): `MnemonicFrameDetail`/`MnemonicFrame`
      cresce de 4 para 5 campos (`+ visualAssociationId`) — mutante: renomear
      `visualAssociationId` só de um lado faz este caso reprovar (o mesmo mecanismo já
      documentado no arquivo, linhas 71-73, estendido ao campo novo).
- [ ] Valor de exemplo de qualquer fixture citado neste arquivo passaria no Zod real do
      backend (`visual-associations.schema.ts`) — confirmado por leitura cruzada, não
      presumido.
- [ ] Verificação executável (gate 1): `npm --prefix mnemonicos-backend test --
      visual-associations-frontend-contract` (arquivo novo — molde/exemplar de convenção:
      `tira-frontend-contract.test.ts`, que já roda com o mesmo padrão de comando trocando o
      caminho — comando roda contra o molde na fixação, decisão 4.342) → `OK (N tests)`;
      `npm --prefix mnemonicos-backend test -- tira-frontend-contract` (arquivo estendido) →
      `OK (N tests)`, incluindo o novo caso de `visualAssociationId`.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npm --prefix mnemonicos-backend run lint` → exit 0.
- [ ] Padrão de commit respeitado (`chore:`).
- [ ] Aderência à stack/padrões da ficha e do perfil `node-22.md`.
- [ ] Code review aprovado.

## Riscos específicos

- Lição ativa (5ª reincidência, madura) "[Testes] Comentário que afirma paridade entre os
  dois repos só vale se o teste LER as duas fontes" — esta TASK É a rede que fecha essa
  lição para o acervo visual; qualquer fixture/comentário que a viole dentro do arquivo novo
  reproduziria o mesmo defeito que a rede deveria impedir em outros lugares.
- Limite conhecido herdado (RISK-006-006/INDEX.md, citado por
  `tira-frontend-contract.test.ts:18-20`): este teste compara DECLARAÇÃO×DECLARAÇÃO, não
  `select` do Prisma × interface — uma chave nova no `select` de
  `visual-associations.service.ts` sem a mesma chave na interface do frontend não é acusada
  aqui; mesmo limite se aplica ao arquivo novo desta TASK.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-105
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
