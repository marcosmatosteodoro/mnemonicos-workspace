# Tracker local — KAN-179 (BRIEF-048 / SPEC-048, tela de gestão de usuários)

**PENDENTE DE RECONCILIAÇÃO.** O conector Atlassian está sem acesso ao site
`mp-consultoria.atlassian.net` (cloudId não concedido nesta sessão). O ciclo segue em modo
link, com o KAN-179 como card da demanda. Quando o acesso voltar, aplique a fila abaixo
**na ordem**, medindo o quadro antes de cada transição, e marque este arquivo como
**RECONCILIADO**, com data e o estado medido depois.

## Estado conhecido do card

| Key | Tipo | Pai | Último estado MEDIDO | Quando / como |
|---|---|---|---|---|
| **KAN-179** | História (`10009`) | nenhum (`getJiraIssue` sem `parent`) | `11` Tarefas pendentes (status `10004`) | 2026-09-30 16:41, `getJiraIssue` da triagem |

Nenhum card novo foi criado. A SPEC-048 vincula o KAN-179 em modo link. As Subtasks das
TASKs (`10007`) só nascem na reconciliação, se o Diretor quiser.

## Fila de operações pendentes (aplicar de cima para baixo)

1. `getJiraIssue KAN-179`: medir o status atual e confirmar que não há `parent`. Se o status
   não for `11`, alguém moveu o card: pare e confira com o Diretor antes de transicionar.
2. Comentário de vínculo: SPEC-048 / BRIEF-048 / PLAN-049 / TASK-049-001..006 em `docs/producao-material/`.
3. `start-dev`: KAN-179 → `21` Em andamento (o desenvolvimento começou em 2026-09-30 22:18).
4. `finish-dev` (teto do §9): KAN-179 → `31` **Em análise** — nunca `41` (concluir é ato do Diretor
   após o merge). Comentário de fim de desenvolvimento: branch `feat/producao-material-gestao-usuarios`
   (mnemonicos-frontend, 12 commits, HEAD 056bf21, pushada), suíte 91 suítes / 1303 testes verdes,
   gates 1–8/10/11 aprovados, gate 9 PARCIAL em `docs/producao-material/handoffs/HANDOFF-PLAN-049.md`.
5. Sub-tasks das 6 TASKs: opcionais — criar só se o Diretor pedir (o card é História sem épico).
6. Após o aviso de merge do Diretor: KAN-179 → `41` Concluído + comentário com o PR/merge; sem pai, não há épico a consultar.

## Log (mais recente no topo)

- 2026-10-01 01:05: Entrega do `/keelson:auto` — branch pushada, KAN-179 deveria estar em `31` (fila itens 3–4 pendentes; conector ainda sem acesso).
- 2026-09-30 21:07: largada do `/keelson:auto --from=KAN-179` sem acesso ao Jira. Arquivo
  criado.
