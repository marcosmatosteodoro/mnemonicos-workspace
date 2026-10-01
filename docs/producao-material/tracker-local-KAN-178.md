# Tracker local — KAN-178 (SPEC-044 / BRIEF-044)

**RECONCILIADO em 2026-10-01 10:24** (pós-merge) — acesso ao conector restabelecido (aviso do
Diretor); as operações do trilho pós-merge foram aplicadas no quadro `KAN` pelo `tracker-sync`
(§12): KAN-178 `31` Em análise → `41` Concluído, comentário de merge (id 10263) e sub-tarefas
KAN-187..191 conferidas em `41`. Detalhe no log abaixo.

**RECONCILIADO em 2026-09-30 19:36** (acesso ao conector Atlassian restabelecido, aviso do
Diretor) — todas as estruturas abaixo foram criadas/transicionadas no quadro `KAN` pelo
gancho de reconciliação (§12) do `tracker-sync`. Este arquivo fica como registro histórico
do período sem conector (corte às 17:45); as keys gravadas nos artefatos SDD (`**Jira**:`
da SPEC, campo `Jira:` da closure das TASKs) são agora a fonte viva — não este arquivo.

## Estruturas criadas — estado aplicado

| Artefato | Tipo Jira | Key | Pai | Estado aplicado |
|---|---|---|---|---|
| SPEC-044 — Sidebar de navegação da área interna | História (`10009`) | **KAN-178** | — (sem épico) | `11` → `21` Em andamento (teto do §9) + comentário de reconciliação |
| TASK-046-001 — Container de largura único (PageContainer) | Subtask (`10007`) | **KAN-187** | KAN-178 | `41` Concluído |
| TASK-046-002 — Logo do header por sessão | Subtask (`10007`) | **KAN-188** | KAN-178 | `41` Concluído |
| TASK-046-003 — Volta ao conteúdo na Tira | Subtask (`10007`) | **KAN-189** | KAN-178 | `41` Concluído |
| TASK-046-004 — Sidebar fixa com seção atual | Subtask (`10007`) | **KAN-190** | KAN-178 | `41` Concluído |
| TASK-046-005 — Menu recolhível abaixo de xl | Subtask (`10007`) | **KAN-191** | KAN-178 | `21` Em andamento (em re-review; closure vem depois) |

## Estado medido antes do corte (histórico)

| Artefato | Tipo Jira | Key | Pai | Estado |
|---|---|---|---|---|
| SPEC-044 — Sidebar de navegação da área interna | História (`10009`), raiz em modo `link` | **KAN-178** | — (sem épico) | `11` Tarefas pendentes, vinculada pelo gancho `specify` às 17:3x (antes do corte) |

## Log de operações pendentes (mais recente no topo)

- 2026-09-30 21:05 (trilho pós-merge, aviso do Diretor) — aplicado em 2026-10-01 10:24:
  1. **KAN-178** (História): `31` Em análise → `41` **Concluído** (conferir que está em `31` antes; não-regressão). **Medido: estava em `31` Em análise; transição `41` aplicada, retorno "Concluído".**
  2. Comentário no **KAN-178**: "Mergeado — mnemonicos-frontend PR #26 (`5bce413`, 2026-10-01T00:04:35Z), branch `feat/producao-material-sidebar-navegacao`. Verificação de tela com login segue em `docs/producao-material/handoffs/HANDOFF-PLAN-046.md` (V1–V7). Alinhamento de header/footer em BRIEF-047 (avulso, sem card)."
  3. Filhos de épico: **n/a** — KAN-178 não tem épico-pai (projeção compacta, como KAN-180/KAN-77); não há épico a consultar nem a fechar. **Medido: campo parent ausente em KAN-178 — confirmado.**
  4. Sub-tarefas KAN-187..191: já em `41` Concluído (sem operação). **Medido: os cinco em Concluído.**
  Comentário 2 aplicado: id 10263 (sem comentário igual prévio).

- 2026-09-30 19:16 (Wave 2 do PLAN-046): sub-tarefa de TASK-046-004 `21` no despacho (18:54) e `41` Concluído na closure (commits 761ccc0, 54b99bf, 581bfeb).

- 2026-09-30 18:58 (Wave 1 do PLAN-046): História **KAN-178** `11` → `21` Em andamento (1ª TASK despachada às 18:29, gancho `despacho`); sub-tarefas de TASK-046-001, 002 e 003 (a criar, ver abaixo) `21` no despacho e `41` Concluído na closure (commits de produção 9b60fc2+1915183, 7b26119+8c60101, d448ca5+583049a). Teto do §9: a História fica em `21` até o `--phase finish-dev`.

- 2026-09-30 (Etapa 3, gancho `tasks`): **criar 5 sub-tarefas** (`10007`) sob KAN-178, uma por TASK, e gravar a key no campo `Jira:` da closure de cada uma:
  - TASK-046-001 — Container de largura único (PageContainer) · wave 1
  - TASK-046-002 — Logo do header por sessão · wave 1
  - TASK-046-003 — Volta ao conteúdo na Tira · wave 1
  - TASK-046-004 — Sidebar fixa com seção atual · wave 2
  - TASK-046-005 — Menu recolhível abaixo de xl · wave 3
  Estado inicial: `11` Tarefas pendentes. As transições de despacho (`21`) e de fecho (`41`) entram nesta lista conforme o implement andar.

- 2026-09-30 17:45: corte do acesso ao Jira. Nenhuma operação pendente até aqui: o gancho
  `specify` rodou antes do corte, vinculou a SPEC-044 ao KAN-178 e não criou issue nem
  moveu status.
