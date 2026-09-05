# TASK-006-007: Estender a rede de paridade cross-repo aos dois enums novos

**Slug**: producao-material
**Pertence a**: PLAN-006
**Realiza (FRs)**: nenhuma
**Componente**: COMP-006-009 (principal)
**Wave**: 3
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (épico estratégia única; a closure commita TASK a TASK)
**Padrão de commit**: Conventional Commits (`chore:` para esta TASK — extensão de rede de teste, sem código de produção)
**Framework de teste**: Jest — testes unitários em `mnemonicos-backend/tests/unit/`

## Dependências

- **Depende de**: TASK-006-004
- **Bloqueia**: nenhuma

## Contexto

F1 só tem rede de divergência cross-repo para `USER_ROLES` + `SessionUser`
(`mnemonicos-backend/tests/unit/domain-types-parity.test.ts`). F2 introduz dois enums de
domínio novos mantidos à mão nos dois lados — `PROOF_RADAR_CLASSES` e
`NORMATIVE_SOURCE_TYPES` (criados em T004). DEC-006-005 manda estender **o teste unitário
de paridade existente** a esses dois enums; as interfaces (`RawContent`/`RawContentSummary`/
`RuleBreakdown`) ficam sob "mesmo diff" + typecheck (resolução 4 do manifesto), fora desta
TASK. Modo de falha coberto: enum divergente que quebra em runtime sem o typecheck acusar
(RISK-005-003 / TRISK-006-004) — reincidência de lição já paga do projeto.

## Escopo

### Inclui

- Estender `mnemonicos-backend/tests/unit/domain-types-parity.test.ts` com casos para os
  dois enums novos, reusando o **mesmo mecanismo de leitura cross-repo** já aplicado a
  `USER_ROLES` (resolve o caminho relativo do outro repo e **lança** se o arquivo não
  existir — nunca passa verde vazio).
- Comparação **literal** do conjunto de valores de `PROOF_RADAR_CLASSES` (`ALTA`, `MEDIA`,
  `DETALHE`, `EXCECAO`, `PEGADINHA`) e de `NORMATIVE_SOURCE_TYPES` (`CF`, `CTN`, `LEI`,
  `LEI_COMPLEMENTAR`, `SUMULA`, `ATO_NORMATIVO`) entre
  `mnemonicos-backend/src/domain/types.ts` e `mnemonicos-frontend/src/types/domain.ts`,
  nos dois sentidos (nenhuma ponta com entrada a mais).
- Se `mnemonicos-frontend/tests/types/domain.test.ts` tiver caso equivalente (snapshot
  local do lado do frontend), alinhá-lo aos dois enums novos.

### Não inclui

- As constantes/interfaces de domínio em si — nascem em T004.
- Paridade das **interfaces** de conteúdo/quebra — DEC-006-005 restringe a rede aos 2 enums
  (resolução 4 do manifesto); interfaces sob typecheck + "mesmo diff".
- Mapa/função de prioridade de apresentação (DEC-006-009).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

- Ler o caso `USER_ROLES` já presente em `domain-types-parity.test.ts` e reusar o helper
  que resolve o caminho do arquivo do frontend a partir de `mnemonicos-backend/tests/unit/`
  e lança em ausência.
- Conferir **o formato real** que T004 gravou os enums (`as const` de array, união de
  literais, etc.) antes de fixar a extração — a regex/AST atual foi escrita para
  `USER_ROLES` e pode não casar o formato novo.
- Adicionar um bloco de teste por enum novo: extrair o conjunto das duas fontes e comparar
  os arrays ordenados.
- Rodar a suíte unit inteira do backend.

## Critérios de pronto

- [ ] `domain-types-parity.test.ts` tem casos novos que comparam **literalmente** o
  conjunto de `PROOF_RADAR_CLASSES` (5 valores: `ALTA`, `MEDIA`, `DETALHE`, `EXCECAO`,
  `PEGADINHA`) e de `NORMATIVE_SOURCE_TYPES` (6 valores: `CF`, `CTN`, `LEI`,
  `LEI_COMPLEMENTAR`, `SUMULA`, `ATO_NORMATIVO`) entre
  `mnemonicos-backend/src/domain/types.ts` e `mnemonicos-frontend/src/types/domain.ts`; a
  leitura do arquivo do outro repo é por caminho relativo cross-repo e **lança** se o
  arquivo não existir.
- [ ] Testes cobrem AC-005-030 — verificação executável:
  `npm --prefix mnemonicos-backend test -- domain-types-parity.test.ts` →
  `PASS` com `Tests: N passed` (N inclui os casos `PROOF_RADAR_CLASSES` e
  `NORMATIVE_SOURCE_TYPES` — saída não-vazia), fixada antes do código. Mutante: remover
  `PEGADINHA` de `PROOF_RADAR_CLASSES` **só** em
  `mnemonicos-frontend/src/types/domain.ts` → o comando falha (conjuntos divergentes →
  vermelho). Controle de leitura das duas fontes: renomear temporariamente
  `mnemonicos-frontend/src/types/domain.ts` → o teste **lança** erro de arquivo ausente,
  nunca fica verde.
- [ ] Lição ativa [Segurança] "Constante de segurança espelhada entre repos declara a
  fonte e tem teste de divergência": cada enum novo, nos dois `types.ts`, carrega
  comentário que **declara a fonte canônica** (`schema.prisma`) e aponta este teste;
  **entrada a mais numa ponta é defeito** — o caso de paridade compara os conjuntos nos
  dois sentidos, provado pelo mutante que adiciona um 7º valor só no frontend → vermelho.
- [ ] Lição ativa [Testes] "Comentário que afirma paridade entre os dois repos só vale se
  o teste LER as duas fontes": o caso novo lê `mnemonicos-frontend/src/types/domain.ts`
  por caminho relativo cross-repo a partir de `mnemonicos-backend/tests/unit/` e falha
  alto se o arquivo sumir (controle acima); nenhum snapshot do backend contra si mesmo.
- [ ] Lição ativa [Testes] "Retry que reescreve arquivo de teste por mudança de assinatura
  entrega o inventário antes/depois dos `it()`": se a extensão for aplicada por reescrita
  ampla do arquivo, a closure registra o inventário de `it(...)`/`test(...)` antes
  (`git show <commit-pai>:mnemonicos-backend/tests/unit/domain-types-parity.test.ts`) e
  depois (HEAD); nenhum caso pré-existente (`USER_ROLES`, `SessionUser`) perdido — cada
  nome ausente classificado (renomeado com substituto / removido com motivo / perdido →
  volta).
- [ ] Sem warnings/lints novos
- [ ] Padrão de commit respeitado
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem
- [ ] Code review aprovado

## Riscos específicos

- A regex/AST hard-coded do teste atual foi escrita para o formato de `USER_ROLES`; o
  formato dos enums novos gravado por T004 pode diferir e exigir ajuste do extrator —
  conferir o arquivo real antes de fixar.
- Caminho relativo cross-repo depende de os dois repos estarem lado a lado no workspace
  (symlinks — lição [Exploração]); o teste já assume isso para `USER_ROLES`.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-05T03:36:03-03:00
**Data conclusão**: 2026-09-05T04:47:41-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 2a8f815 (backend) · d2f2d44 (frontend)
**Jira**: KAN-35
**Implementado por**: developer
**Revisado por**: code-reviewer (gates 1-7, Wave 3 — aprovado direto, sem retry)
**Tentativas**: 1 (o sandbox do developer bloqueou a execução ao vivo de 2 mutantes da AC-005-030; o Tech Lead rodou os dois manualmente com a árvore quieta — remover `PEGADINHA` só no frontend → vermelho; renomear o arquivo do frontend → lança erro — e reverteu, árvore confirmada limpa; código-reviewer confirmou a forma no HEAD sem precisar re-executar)
**Cobertura final**: n/a (paridade cross-repo — 5 casos em `domain-types-parity.test.ts`, 4 em `mnemonicos-frontend/tests/types/domain.test.ts`)
**Arquivos modificados**:
  - mnemonicos-backend/tests/unit/domain-types-parity.test.ts
  - mnemonicos-frontend/tests/types/domain.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados: AC-005-030
- [x] Segurança (gate 8): n/a — wave coberta pelo gate 8 em T008/T009 (superfície sensível); T007 é rede de teste cross-repo, sem alcance/autorização
- [ ] Comportamento (gate 9): n/a — sem efeito observável de tela; FEAT-005-001/002 ainda não completas

**Notas**: `extractUserRoles(source)` generalizado para `extractConstArray(source, constName)`, reusado pelos 3 enums (inclusive `USER_ROLES`) em vez de triplicar a extração — escoteiro dentro do Art. 6. Único gap: o sandbox do developer impediu a prova ao vivo dos 2 mutantes da AC-005-030 na 1ª passada; fechado pelo Tech Lead antes do gate (ver Tentativas).
