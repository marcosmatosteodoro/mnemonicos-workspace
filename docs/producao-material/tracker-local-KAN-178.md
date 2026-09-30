# Tracker local — KAN-178 (SPEC-044 / BRIEF-044)

**PENDENTE DE RECONCILIAÇÃO.** Em 2026-09-30, por volta de 17:45, o Diretor retirou o acesso
ao conector Atlassian por um tempo: "faça todas as atualizações locais, depois a gente passa
para o jira". A partir desse momento, os ganchos do ciclo não chamam o Jira. Cada operação
que o protocolo faria fica registrada abaixo, e o `tracker-sync` aplica tudo no gancho de
reconciliação (§12) quando o acesso voltar. Keys de sub-tarefa ainda não existem: os
artefatos SDD ficam com a linha `Jira:` pendente até lá.

## Estado medido antes do corte

| Artefato | Tipo Jira | Key | Pai | Estado |
|---|---|---|---|---|
| SPEC-044 — Sidebar de navegação da área interna | História (`10009`), raiz em modo `link` | **KAN-178** | — (sem épico) | `11` Tarefas pendentes, vinculada pelo gancho `specify` às 17:3x (antes do corte) |

## Log de operações pendentes (mais recente no topo)

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
