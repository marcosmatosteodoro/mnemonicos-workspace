# Tracker local — F9 (SPEC-032 / PLAN-033)

**RECONCILIADO em 2026-09-29 22:33** (acesso ao conector Atlassian restabelecido, aviso do
Diretor) — todas as estruturas abaixo foram criadas/transicionadas no quadro `KAN` pelo
gancho de reconciliação (§12) do `tracker-sync`. Este arquivo fica como registro histórico
do período sem conector; as keys gravadas nos artefatos SDD (`**Jira**:` da SPEC/FEATs,
campo `Jira:` da closure das TASKs) são agora a fonte viva — não este arquivo.

## Estruturas criadas — estado aplicado

| Artefato | Tipo Jira | Key | Pai | Estado aplicado |
|---|---|---|---|---|
| SPEC-032 — Controle de qualidade e gate de versão aprovada | Epic (`10006`) | **KAN-149** | — (relates to KAN-6, fatia 9) | intocado (roadmap) |
| FEAT-032-001 — Aprovação da Versão vigente com checklist e segregação de funções | História (`10009`) | **KAN-150** | KAN-149 | `21` Em andamento |
| FEAT-032-002 — Carimbo de Versão aprovada no PDF exportado | História (`10009`) | **KAN-151** | KAN-149 | `21` Em andamento + comentário "pronta p/ QA, gate 9 verificado" |
| TASK-033-001 — Migração de aprovação de Versão | Subtask (`10007`) | **KAN-152** | KAN-150 | `41` Concluído |
| TASK-033-002 — Sinal de alteração da Tira mnemônica | Subtask (`10007`) | **KAN-153** | KAN-150 | `41` Concluído |
| TASK-033-003 — Aprovação de Versão (backend) | Subtask (`10007`) | **KAN-154** | KAN-150 | `41` Concluído |
| TASK-033-004 — Leitura do estado de aprovação | Subtask (`10007`) | **KAN-155** | KAN-150 | `41` Concluído |
| TASK-033-005 — Carimbo de aprovação no PDF | Subtask (`10007`) | **KAN-156** | KAN-151 | `41` Concluído |
| TASK-033-006 — Tipos e mutation de aprovação (frontend) | Subtask (`10007`) | **KAN-157** | KAN-150 | `41` Concluído |
| TASK-033-007 — Painel de aprovação (frontend) | Subtask (`10007`) | **KAN-158** | KAN-150 | `21` Em andamento (Wave 5 em revisão) |

Teto do §9 respeitado: nenhuma História passou de `21` (Em andamento) — `31`/`41` ficam
para `--phase finish-dev` e para o ato do Diretor pós-merge, respectivamente. Epic
(KAN-149) intocado pelo ciclo, como sempre.

## Log de operações pendentes (mais recente no topo)

- 2026-09-29 23:35: Wave 5 fechada — KAN-158 (TASK-033-007) → `41`; finish-dev: KAN-150/KAN-151 → `31` Em análise (aplicado via conector, ver resumo do sync).

- 2026-09-29 22:33: **Reconciliação aplicada** (gancho §12, conector restabelecido) — Epic
  KAN-149 criado (link "relates to" com KAN-6, achado de config: Epic não tem campo
  `parent` neste projeto); Histórias KAN-150/KAN-151 criadas sob KAN-149 e movidas a `21`;
  KAN-151 recebeu o comentário do marco "pronta p/ QA" (FEAT-032-002, 6/6 ACs); 7 sub-tasks
  criadas (KAN-152..158) — KAN-152/153/154/155/156/157 → `41` Concluído, KAN-158 (TASK-033-007)
  → `21` Em andamento. Keys gravadas em SPEC-032 (cabeçalho + sob cada heading FEAT) e no
  campo `Jira:` da closure de cada TASK-033-*.

- 2026-09-29 21:56: Wave 4 fechada — TASK-033-006: despacho `21` e closure `41` Concluído.

- 2026-09-29 21:45: Wave 3 fechada — TASK-033-004: despacho `21` e closure `41` Concluído.

- 2026-09-29 20:50: Wave 2 fechada — TASK-033-003/005 → `41` Concluído. FEAT-032-002
  (carimbo no PDF) completa e com gate 9 verificado → comentar o marco "Funcionalidade pronta
  p/ QA" na História; a História segue no teto (`21`, depois `31` no finish-dev), nunca `41`
  pelo ciclo.

- 2026-09-29 20:31: retomada da Wave 2 — TASK-033-003/005 seguem em `21`; Histórias em `21`.
- 2026-09-27: Wave 1 fechada — TASK-033-001/002 → `41` Concluído (closure `723805a`).
- 2026-09-27: largada da F9 sem raiz no tracker — conector MCP Atlassian sem autenticação
  (degradação registrada no ledger da sessão `b1505f46`).
