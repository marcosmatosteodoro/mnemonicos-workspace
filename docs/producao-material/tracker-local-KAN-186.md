# Tracker local — KAN-186 (BRIEF-045 avulso · logout "Saindo" com spinner)

**RECONCILIADO em 2026-09-30 19:35** (o Diretor devolveu o acesso ao Jira e avisou o merge do PR #25).
O KAN-186 está em `41` Concluído (status `10007`), medido no retorno da transição. Este arquivo fica
como registro histórico do período sem conector.

## Estado conhecido do card

| Key | Tipo | Pai | Último estado MEDIDO | Quando / como |
|---|---|---|---|---|
| **KAN-186** | História (`10009`), criado como Tarefa (`10008`) e com o tipo trocado fora do conector durante o período sem acesso | nenhum (sem épico) | `41` Concluído (status `10007`) | 2026-09-30 19:35, retorno de `transitionJiraIssue` (antes: `21` medido por `getJiraIssue` na reconciliação) |

O card foi criado nesta demanda (17:27), com o link `Relates` para o KAN-185. É o único card do
BRIEF-045: não há subtask.

## Fatos a refletir no card

- **BRIEF-045:** o botão "Sair" do header vira "Saindo" com o `Spinner`, desabilitado, sem o
  texto solto "Saindo…". Commit `0edec2a` na branch `feat/producao-material-logout-botao-saindo`
  (mnemonicos-frontend), **PR #25 aberto** (https://github.com/marcosmatosteodoro/mnemonicos-frontend/pull/25).
- Gates:
  - 1–7: aprovados no re-gate, depois de 1 retry (o teste de ordem spinner×texto era vazio);
  - 8: aprovado, 0 achados;
  - 9: verificado, 7/7 passos em app real com `auth/me` e logout interceptados;
  - 11: aprovado, medido em Chromium;
  - 10: n/a;
  - aceitação do PO: ACEITA.
- Suíte 905/905. Lint, typecheck e build OK.

## Fila de operações pendentes (aplicar de cima para baixo)

1. `getJiraIssue KAN-186`: medir o status atual. Se não for `21`, alguém moveu o card: pare e
   confira com o Diretor antes de transicionar.
2. Comentário de fim de desenvolvimento (o que o `finish-dev` teria feito): branch
   `feat/producao-material-logout-botao-saindo`, commit `0edec2a`, PR #25 e o resumo dos gates
   acima.
3. Transição **`31` Em análise** (finish-dev). É o teto: **nunca `41`** sem o aviso de merge do
   Diretor.
4. Se até a reconciliação o Diretor tiver avisado o merge do PR #25: transição `41` Concluído,
   com um comentário do merge (SHA). Não há épico pai nem filhos a consultar.
5. `getJiraIssue KAN-186` pós-transição: confirmar o status e anotar aqui.

## Log (mais recente no topo)

- 2026-09-30 19:35: **Reconciliado.** O PR #25 foi mergeado pelo Diretor (merge `8633200`, 2026-09-30T22:34:45Z). A medição inicial deu `21` Em andamento, sem `parent` nem subtasks. Comentário `10260` (fim de dev, PR #25 mergeado e gates). Transição `41` direta, porque o `31` foi pulado: a conexão caiu antes do finish-dev e o merge já tinha sido avisado. O retorno confirmou `Concluído` e mostrou o tipo agora como História (`10009`). Não há épico a consultar.
- 2026-09-30 17:43: acesso ao Jira retirado pelo Diretor. Ficaram pendentes o `finish-dev`
  (KAN-186 → `31`) e o comentário de branch/PR #25.
- 2026-09-30 17:28: KAN-186 `11` → `21` Em andamento (medido no retorno do conector).
- 2026-09-30 17:27: KAN-186 criado (Tarefa `10008`), com o link `Relates` para o KAN-185.
