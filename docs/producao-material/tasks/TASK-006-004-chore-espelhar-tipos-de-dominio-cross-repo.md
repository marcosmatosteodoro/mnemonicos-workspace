# TASK-006-004: Espelhar os tipos de domínio cross-repo — enums, interfaces e rótulos pt-BR (mesmo diff)

**Slug**: producao-material
**Pertence a**: PLAN-006
**Realiza (FRs)**: nenhuma
**Componente**: COMP-006-008 (principal)
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: chore
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — `git.branchStrategy: unica`; não criar branch por task; a closure commita TASK a TASK)
**Padrão de commit**: Conventional Commits (`chore:` para esta TASK — espelho de tipos de domínio, sem código de produção com lógica)
**Framework de teste**: Jest nos dois repos — `mnemonicos-backend/tests/unit/` (Jest) e `mnemonicos-frontend/tests/` (Jest via `next/jest`). Gates: `npm --prefix mnemonicos-backend run typecheck` / `run lint` / `test` **e** `npm --prefix mnemonicos-frontend run typecheck` / `run lint` / `test`.

## Dependências

- **Depende de**: TASK-006-001, TASK-006-002
- **Bloqueia**: TASK-006-007, TASK-006-010

## Contexto

Os tipos de domínio são mantidos à mão nos dois repos, no mesmo diff (CLAUDE.md): backend `mnemonicos-backend/src/domain/types.ts:8-39` (existe para a lógica pura compilar sem codegen), frontend `mnemonicos-frontend/src/types/domain.ts:7-101` (+ `*_LABELS` pt-BR + interfaces). F2 introduz dois enums novos (`ProofRadarClass` 5 valores, `NormativeSourceType` 6 valores) e as interfaces de Conteúdo bruto e Quebra da regra. Esta TASK espelha esses tipos nas duas pontas com o **mesmo conjunto de valores**, mais os mapas de rótulo pt-BR no frontend, e o comentário de fonte canônica apontando o teste de divergência. A **rede de divergência** propriamente dita (`domain-types-parity.test.ts` estendido) é TASK-006-007, mesmo PLAN, wave 3 — TRISK-006-004 registra a janela. `RawContentSummary` é **assimétrico por decisão** (resolução 5 do manifesto): backend o mantém local ao módulo `contents` (nasce em TASK-006-006/008); frontend o define aqui, para tipar a resposta RTK Query. Sem AC próprio de gate — o oráculo é o contrato do item (typecheck dos dois repos + uso não-nulo) e o teste de T007. Gates: g1 (typecheck dos dois repos); g8 (constante espelhada); g9/g10/g11 n/a.

## Escopo

### Inclui

- `mnemonicos-backend/src/domain/types.ts`:
  - `PROOF_RADAR_CLASSES` = `['ALTA','MEDIA','DETALHE','EXCECAO','PEGADINHA'] as const` (5); `NORMATIVE_SOURCE_TYPES` = `['CF','CTN','LEI','LEI_COMPLEMENTAR','SUMULA','ATO_NORMATIVO'] as const` (6); os tipos-união derivados (`type ProofRadarClass = typeof PROOF_RADAR_CLASSES[number]` etc., no padrão de `USER_ROLES`).
  - `interface RawContent` e `interface RuleBreakdown`.
  - **NÃO** `RawContentSummary` (resolução 5 — é local ao módulo `contents` no backend).
  - Comentário declarando a fonte canônica (`prisma/schema.prisma`, enums `ProofRadarClass`/`NormativeSourceType`) e apontando `mnemonicos-backend/tests/unit/domain-types-parity.test.ts` (estendido em TASK-006-007).
- `mnemonicos-frontend/src/types/domain.ts`:
  - Os **mesmos** `PROOF_RADAR_CLASSES` / `NORMATIVE_SOURCE_TYPES` (valores idênticos, mesma ordem) + tipos-união.
  - `interface RawContent`, `interface RawContentSummary`, `interface RuleBreakdown`.
  - `interface Discipline` ganha `topics?: { id: string; name: string; slug: string }[]` — espelha a extensão de `GET /disciplines` de TASK-006-002 (parte 2); o `?` cobre a janela até T002 mergear e o consumo em `listDisciplines` (TASK-006-010) / `content-form` (TASK-006-013).
  - `PROOF_RADAR_CLASS_LABELS` (`Record<ProofRadarClass, string>`, pt-BR) e `NORMATIVE_SOURCE_TYPE_LABELS` (`Record<NormativeSourceType, string>`, pt-BR).
  - Comentário de fonte canônica + ponteiro para o teste de divergência, como no backend.
- Os **dois** arquivos de tipos no **mesmo commit**.
- Teste(s) de uso não-nulo de cada interface/constante nova, nos dois repos.

### Não inclui

- `PROOF_RADAR_CLASS_PRIORITY` / função de prioridade de apresentação (DEC-006-009 — nasce em F10 junto do consumidor).
- O teste de paridade `domain-types-parity.test.ts` estendido (TASK-006-007) e a paridade das **interfaces** (DEC-006-005 restringe a rede aos 2 enums — resolução 4).
- Consumo dos tipos/mapas em `src/store/api.ts` (TASK-006-010) ou nas telas (TASK-006-012/013/014).
- `RawContentSummary` em `mnemonicos-backend/src/domain/types.ts` (lapso do PLAN — resolução 5).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Backend `src/domain/types.ts` — acrescentar os 2 arrays `as const` + tipos-união + `interface RawContent`/`RuleBreakdown` no padrão de `USER_ROLES`/`SessionUser`; comentário de fonte canônica.
2. Frontend `src/types/domain.ts` — os mesmos arrays + tipos-união + `interface RawContent`/`RawContentSummary`/`RuleBreakdown`; `PROOF_RADAR_CLASS_LABELS` e `NORMATIVE_SOURCE_TYPE_LABELS` como `Record<…, string>` pt-BR (uma entrada por membro do enum); comentário de fonte canônica.
3. Testes de uso não-nulo nos dois repos (objetos concretos das interfaces; `Object.keys` dos mapas == membros do enum).
4. Commitar os dois arquivos juntos (`git add` das duas pontas antes do commit).

## Critérios de pronto

- [ ] `mnemonicos-backend/src/domain/types.ts` exporta `PROOF_RADAR_CLASSES` (`['ALTA','MEDIA','DETALHE','EXCECAO','PEGADINHA'] as const`), `NORMATIVE_SOURCE_TYPES` (`['CF','CTN','LEI','LEI_COMPLEMENTAR','SUMULA','ATO_NORMATIVO'] as const`), os tipos-união derivados, e `interface RawContent` / `interface RuleBreakdown`; **não** exporta `RawContentSummary`. Verificação executável (padrão ancorado em declaração de export — contrato §273(b)): `grep -nE "^export const (PROOF_RADAR_CLASSES|NORMATIVE_SOURCE_TYPES)\b|^export interface (RawContent|RuleBreakdown)\b" mnemonicos-backend/src/domain/types.ts` → **4 linhas**; `grep -nE "^export (interface|type) RawContentSummary" mnemonicos-backend/src/domain/types.ts` → **sem resultado** (também sem resultado no commit-pai — o símbolo nunca existiu no backend). Falsificável: adicionar `export interface RawContentSummary` ao backend → o 2º `grep` casa, vermelho. Fixada antes do código.
- [ ] `mnemonicos-frontend/src/types/domain.ts` exporta os **mesmos** `PROOF_RADAR_CLASSES` / `NORMATIVE_SOURCE_TYPES` (valores e ordem idênticos ao backend), `interface RawContent` / `RawContentSummary` / `RuleBreakdown`, e os mapas `PROOF_RADAR_CLASS_LABELS` (`Record<ProofRadarClass, string>`) e `NORMATIVE_SOURCE_TYPE_LABELS` (`Record<NormativeSourceType, string>`) em pt-BR, cada mapa com **uma entrada por membro** do enum (chave faltante ou a mais → typecheck vermelho). Verificação executável: `npm --prefix mnemonicos-frontend run typecheck` → exit 0; um teste em `mnemonicos-frontend/tests/types/` importa os dois mapas e assere `Object.keys(PROOF_RADAR_CLASS_LABELS).sort()` == `[...PROOF_RADAR_CLASSES].sort()` e idem para o de fonte → `Tests: ≥1 passed`. Falsificável: omitir a chave `PEGADINHA` do mapa → typecheck e teste vermelhos. Fixada antes do código.
- [ ] Cada interface/constante nova é exercitada por **uso não-nulo** (item do Inclui sem AC — oráculo é o contrato do item): teste(s) que constroem valores concretos de `RawContent` e `RuleBreakdown` (backend e frontend) e de `RawContentSummary` (frontend), com todos os campos preenchidos e asserção sobre ≥1 campo; `radarClass` recebe um membro de `PROOF_RADAR_CLASSES`. Verificação executável: `npm --prefix mnemonicos-backend test -- <arquivo>` e `npm --prefix mnemonicos-frontend test -- <arquivo>` → `Tests: ≥1 passed` cada; `npm --prefix mnemonicos-backend run typecheck` **e** `npm --prefix mnemonicos-frontend run typecheck` → exit 0 (os dois repos). Falsificável: divergir o tipo de um campo entre a interface e o objeto de teste → typecheck vermelho. Fixada antes do código.
- [ ] Lição ativa [Segurança] "Constante de segurança espelhada entre repos declara a fonte e tem teste de divergência". Texto da lição (solução, obrigação 1): *"o espelho declara a fonte canônica E tem teste que falha quando diverge dela — entrada a mais no espelho é defeito, não conveniência (se um caminho entra por decisão do cliente e não da fonte, o comentário diz isso explicitamente e o teste de divergência o exclui da comparação)."* Item verificável (**checagem de conteúdo textual** — o comentário DEVE conter as duas referências; o `grep` casa a linha de comentário de propósito): cada um dos dois `types.ts` carrega, junto de `PROOF_RADAR_CLASSES` e `NORMATIVE_SOURCE_TYPES`, um comentário que (i) declara a fonte canônica (`mnemonicos-backend/prisma/schema.prisma`, enums `ProofRadarClass`/`NormativeSourceType`) e (ii) aponta o teste de divergência `mnemonicos-backend/tests/unit/domain-types-parity.test.ts`. O **teste de divergência propriamente dito** é estendido a esses enums em **TASK-006-007** (mesmo PLAN, wave 3 — TRISK-006-004 registra a janela). Verificação executável: `grep -nE "schema\.prisma|domain-types-parity" mnemonicos-backend/src/domain/types.ts mnemonicos-frontend/src/types/domain.ts` → ao menos uma âncora de fonte **e** uma de teste em **cada** arquivo. Falsificável: comentário ausente num lado → `grep` incompleto, vermelho. Fixada antes do código.
- [ ] Lição ativa [Testes] "Comentário que afirma paridade entre os dois repos só vale se o teste LER as duas fontes": nenhum comentário adicionado por esta TASK **afirma** que a paridade já é testada aqui — os comentários dizem que a fonte canônica é `schema.prisma` e que `domain-types-parity.test.ts` (estendido em T007) lê as duas fontes. Verificação: revisão do texto dos comentários (o `grep` acima lista as linhas) — nenhuma frase do tipo "paridade fixada pelo teste" sem que T007 já exista.
- [ ] CLAUDE.md / NFR-005-005 — os **dois** arquivos de tipos entram no **mesmo commit**. Verificação executável: na closure, `git show --stat <SHA da TASK>` lista `mnemonicos-backend/src/domain/types.ts` **e** `mnemonicos-frontend/src/types/domain.ts` no mesmo commit; `git log -1 --format=%H -- mnemonicos-backend/src/domain/types.ts` == `git log -1 --format=%H -- mnemonicos-frontend/src/types/domain.ts`. Falsificável: espelho num commit, fonte noutro → SHAs distintos, vermelho.
- [ ] `PROOF_RADAR_CLASS_PRIORITY` / função de prioridade de apresentação **não** entram (DEC-006-009) — verificação executável (padrão ancorado em declaração de símbolo — contrato §273(b)): `grep -nE "^\s*export (const|function|type) [A-Za-z_]*(PRIORITY|Priority)" mnemonicos-frontend/src/types/domain.ts` → **sem resultado** (também sem resultado no commit-pai; padrão ancorado em início de linha, contrato §273(b)). Falsificável: adicionar o mapa/função de prioridade → o `grep` casa, vermelho. Fixada antes do código.
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-backend run lint` **e** `npm --prefix mnemonicos-frontend run lint` → exit 0 (baselines capturadas).
- [ ] Padrão de commit respeitado (Conventional Commits — `chore:`).
- [ ] Aderência à stack/padrões da ficha e do perfil (`node-22.md` / `next-16.md` §3: enums `as const` com tipo-união derivado; rótulos pt-BR **só** no frontend; identificadores en; guidelines de projeto vencem o perfil).
- [ ] Code review aprovado.

## Riscos específicos

- Janela TASK-006-004 → TASK-006-007 sem rede de divergência ativa (TRISK-006-004, aceito no PLAN): o typecheck dos dois repos + o teste de T007 (mesma entrega) fecham o modo de falha.
- `domain-types-parity.test.ts` tem regex/AST hard-coded escrita para `USER_ROLES` — pode não casar o formato dos enums novos; o ajuste do extrator é de TASK-006-007, não desta TASK.
- `RawContentSummary` é assimétrico entre os repos **por decisão** (resolução 5): backend local ao módulo `contents`, frontend em `domain.ts`. Não é defeito de espelho.
- Repos symlinkados (lição [Exploração]): editar e verificar sempre pelo caminho dentro do link nos dois repos; ausência detectada por varredura não é fato.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-32
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
