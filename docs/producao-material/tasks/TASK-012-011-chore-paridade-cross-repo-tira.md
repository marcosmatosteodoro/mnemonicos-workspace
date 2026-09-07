# TASK-012-011: Criar `tira-frontend-contract.test.ts` — paridade cross-repo

**Slug**: producao-material
**Pertence a**: PLAN-012
**Realiza (FRs)**: FR-011-001, FR-011-003, FR-011-004, FR-011-005, FR-011-006, FR-011-007
**Componente**: COMP-012-008 (principal)
**Wave**: 3
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Done

```yaml
override-erros: task-criterio-sem-ac
override-justificativa: >-
  Item do Inclui sem AC vinculado — oráculo é o contrato do próprio item
  (contrato do /keelson:tasks, Etapa 3: "Sem AC, o oráculo é o contrato do
  próprio item"): teste de paridade cross-repo puro, molde exato do
  `contents-frontend-contract.test.ts` (também sem AC próprio). Mesmo padrão
  de TASKs chore/infra aprovadas do slug sem menção a AC (TASK-006-004,
  TASK-006-007 — Done). O check mecânico task-criterio-sem-ac não distingue
  esse caso legítimo; registrado como pendência de processo (lição
  candidata ao agile-coach).
override-aprovador: Tech Lead (autônomo, /keelson:auto)
```

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-<descrição-curta>` (`git.branchNaming: "slug"`) — mesma branch única de todo PLAN-012.
**Padrão de commit**: Conventional Commits (`commit.convention: "conventional"`) — `test:`.
**Framework de teste**: Jest 30 + ts-jest — `tests/unit/*.test.ts` (leitura textual dos dois repos, sem DB, sem AST).

## Dependências

- **Depende de**: TASK-012-005, TASK-012-009
- **Bloqueia**: nenhuma

## Contexto

Rede de paridade cross-repo nova, análoga a `domain-types-parity.test.ts` e a
`contents-frontend-contract.test.ts` (o molde direto desta TASK): compara
`MnemonicFrameDetail`/`MnemonicStripDetail` (backend, `tira.service.ts`, entregues por
TASK-012-005/006/007) contra `MnemonicFrame`/`MnemonicStrip` (frontend, `types/domain.ts`,
entregues por TASK-012-009) campo a campo, nomes do backend vencendo em caso de
divergência. Teste puro de paridade — nenhum código de produção, nenhum AC numerado
próprio (o oráculo é o contrato das duas interfaces já fixado pelo PLAN §3/§5).

**Lição aplicada literalmente** (`guidelines/project/lessons.md`, "[Testes] Comentário
que afirma paridade entre os dois repos só vale se o teste LER as duas fontes",
`Estado: ativa`): *"espelhar uma constante do outro repo é barato; **provar** o espelho
exige ler o arquivo do outro repo. Quando o teste fica só no lado local, ele documenta a
intenção em vez de sustentá-la (...) Solução: comentário que afirma paridade cross-repo →
o teste **lê as duas fontes**. O padrão de referência já está no repo:
`mnemonicos-backend/tests/unit/domain-types-parity.test.ts` resolve o caminho do outro
repo e **lança** se o arquivo não existir (falha alto, nunca verde vazio)."* — esta TASK
é a aplicação direta dessa lição às interfaces novas de Quadro/Tira: o teste nunca compara
o frontend contra ele mesmo.

## Escopo

### Inclui

- Arquivo novo `mnemonicos-backend/tests/unit/tira-frontend-contract.test.ts`, seguindo
  **exatamente** o molde de `mnemonicos-backend/tests/unit/contents-frontend-contract.test.ts`
  (lido linha a linha para esta TASK — confirmado, não presumido): as duas funções
  `readSourceFile` (lança `Error` se o caminho não existir, citando que o checkout irmão
  pode estar ausente) e `extractInterfaceFields` (regex `export interface <Nome> \{
  ([\s\S]*?)\n\}`, filtra linhas de comentário, extrai o nome do campo por
  `/^(\w+)\??\s*:/`) são **duplicadas** no arquivo novo, mesmo padrão auto-contido já
  usado pelo molde (que por sua vez generaliza `extractSessionUserFields` de
  `domain-types-parity.test.ts` — cada arquivo de contrato cross-repo é self-contained
  nesta base, não há módulo compartilhado a importar).
- `BACKEND_SERVICE = resolve(__dirname, '../../src/modules/tira/tira.service.ts')`
  (caminho por convenção de módulo — ver `premissas_marcadas`) e `FRONTEND_TYPES =
  resolve(__dirname, '../../../mnemonicos-frontend/src/types/domain.ts')` (idêntico ao
  já usado pelo molde — repos symlinkados no workspace, resolvido pelo caminho relativo a
  partir daqui, mesma nota de "[Exploração] Repos symlinkados não são atravessados por
  varredura ingênua").
- Caso 1: `MnemonicFrameDetail` (backend) × `MnemonicFrame` (frontend) — mesmo conjunto
  de campos: `['id', 'text', 'position', 'originBlock']`.
- Caso 2: `MnemonicStripDetail` (backend) × `MnemonicStrip` (frontend) — mesmo conjunto
  de campos: `['id', 'frames']`.

### Não inclui

- Qualquer código de produção (nem backend, nem frontend).
- Extensão de `domain-types-parity.test.ts` (COMP-012-007, TASK própria fora desta
  lista) — esta TASK cobre só as INTERFACES de Quadro/Tira, não o enum
  `ProductionStageType`.
- Verificação de `select`×declaração (limite conhecido, já documentado na lição citada
  acima e em RISK-006-006, INDEX.md: o teste compara DECLARAÇÃO×DECLARAÇÃO, não
  `select` do Prisma × interface — não resolvido por esta TASK).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios
prevalecem; nunca siga um passo que enfraqueça um critério.

1. Copie a estrutura de `contents-frontend-contract.test.ts` (imports, `readSourceFile`,
   `extractInterfaceFields`, `describe`/`it`), trocando os caminhos e os nomes de
   interface para os de Quadro/Tira.
2. Ajuste os arrays esperados de campos para os dois casos do Escopo > Inclui.
3. Se o diretório real do módulo backend divergir de `src/modules/tira/` (ver
   `premissas_marcadas`), ajuste `BACKEND_SERVICE` para o caminho real — o teste deve
   **lançar** (nunca verde vazio) se o caminho estiver errado, então o erro de
   `readSourceFile` acusa a divergência na 1ª execução.

## Critérios de pronto

- [ ] Arquivo novo `mnemonicos-backend/tests/unit/tira-frontend-contract.test.ts`
      **lê as duas fontes reais** via `readSourceFile` (lança se o arquivo não existir —
      nunca verde vazio) — nunca um fixture que se autoconfirma a partir de um dos
      lados (aplicação direta da lição citada em Contexto).
- [ ] `MnemonicFrameDetail` (backend) × `MnemonicFrame` (frontend): mesmo conjunto de
      campos, `['id','text','position','originBlock'].sort()` dos dois lados.
- [ ] `MnemonicStripDetail` (backend) × `MnemonicStrip` (frontend): mesmo conjunto de
      campos, `['id','frames'].sort()` dos dois lados.
- [ ] Mutante de defasagem (nos dois casos): renomear um campo só de um lado (ex.:
      frontend `originBlock` → `sourceBlock`, ou backend `frames` → `mnemonicFrames`)
      faz a suíte reprovar — confirmado na fixação antes de fechar a TASK (mesmo padrão
      dos comentários "Mutante:" já presentes no molde, linhas 82-85/96-98/108-110 de
      `contents-frontend-contract.test.ts`).
- [ ] Verificação executável: `npm --prefix mnemonicos-backend test --
      tira-frontend-contract.test.ts` → `OK (2 tests)`, executado na fixação contra os
      arquivos reais dos dois repos (nunca contra um fixture presumido de memória).
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npm --prefix mnemonicos-backend run lint` → exit 0.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil `node-22.md`.
- [ ] Code review aprovado.

## Riscos específicos

- RISK-006-006 (INDEX.md) — este teste prova DECLARAÇÃO×DECLARAÇÃO, não `select`×
  declaração; uma chave nova no `select` do Prisma sem a mesma chave na interface do
  frontend passa pelo typecheck e por este teste — limite conhecido, não fechado por
  esta TASK (mesma ressalva já registrada para `contents-frontend-contract.test.ts`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-06T21:32:48-0300
**Data conclusão**: 2026-09-06T21:39:01-0300
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 4557a51
**Jira**: KAN-61
**Implementado por**: developer
**Revisado por**: code-reviewer (aprovado sem achados, Wave 3)
**Tentativas**: 1
**Cobertura final**: n/a (item do Inclui sem AC — oráculo é o contrato do próprio item)
**Arquivos modificados**:
  - mnemonicos-backend/tests/unit/tira-frontend-contract.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (2/2)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados (n/a — sem AC numerado)
- [x] Segurança (gate 8): n/a — teste puro de paridade, sem código de produção
- [x] Comportamento (gate 9): n/a — chore de teste, sem efeito observável

**Notas**:
