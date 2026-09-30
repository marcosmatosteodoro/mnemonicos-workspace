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

- 2026-09-30 17:45: corte do acesso ao Jira. Nenhuma operação pendente até aqui: o gancho
  `specify` rodou antes do corte, vinculou a SPEC-044 ao KAN-178 e não criou issue nem
  moveu status.
