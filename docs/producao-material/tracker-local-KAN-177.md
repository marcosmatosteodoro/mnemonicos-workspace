# Tracker local — KAN-177 (BRIEF-039 emenda SPEC-030 v0.2 · BRIEF-042 ajuste)

**PENDENTE DE RECONCILIAÇÃO.** O Diretor retirou temporariamente o acesso ao Jira em
2026-09-30, por volta das 13:26, e pediu que as informações fossem mantidas aqui até o acesso
voltar. Quando voltar, aplique a fila abaixo **na ordem**, medindo o quadro antes de cada
transição, e marque este arquivo como **RECONCILIADO**, com data e o estado medido depois.

## Estado conhecido do card

| Key | Tipo | Pai | Último estado MEDIDO | Quando / como |
|---|---|---|---|---|
| **KAN-177** | História (`10009`) | nenhum (sem épico; `getJiraIssue` sem `parent`) | `21` Em andamento (status `10005`) | 2026-09-30 13:16, retorno do `transitionJiraIssue` no despacho do developer |

Nenhum card novo foi criado. O BRIEF-039 (emenda) e o BRIEF-042 (ajuste pontual) usam o
KAN-177 em modo link.

## Fatos a refletir no card

- **BRIEF-039 / emenda SPEC-030 v0.2:** `/login` sem cabeçalho nem rodapé, e link "Voltar para
  o início" → `/`. Commit `f35c4f3`, **PR #21 mergeado** pelo Diretor em
  2026-09-30T16:52:51Z (merge `539575a`). Branch `feat/producao-material-login-sem-rodape-voltar`.
- **BRIEF-042 / ajuste:** link centralizado e sem sublinhado, por decisão do Diretor. Commit
  `9b2e920`, **PR #22 mergeado** pelo Diretor em 2026-09-30T17:09:31Z (merge `05cc3e1`). Branch
  `feat/producao-material-login-voltar-centralizado`.
- Gates dos dois: code-reviewer, product-designer e qa aprovados/verificados; segurança
  aprovada no #21 e n/a no #22.

## Fila de operações pendentes (aplicar de cima para baixo)

1. `getJiraIssue KAN-177`: medir o status atual e confirmar que não há `parent`. Se o status
   não for `21`, alguém moveu o card: pare e confira com o Diretor antes de transicionar.
2. Comentário de fim de desenvolvimento (o que o `finish-dev` teria feito): branch e PR #21
   (`f35c4f3`); branch e PR #22 (`9b2e920`); resumo dos gates.
3. Transição **`41` Concluído**, porque o Diretor avisou os dois merges e isso é ato pós-merge
   ordenado por ele. O `31` Em análise foi pulado porque a conexão caiu antes do fim do
   desenvolvimento. Registre isso no comentário da transição.
4. Comentário de merge: "Mergeado — PR #21 (`539575a`) e PR #22 (`05cc3e1`), frontend."
5. Épico: não se aplica (KAN-177 não tem pai). Não há filhos a consultar.
6. `getJiraIssue KAN-177` pós-transição: confirmar `Concluído` e anotar aqui.

## Log (mais recente no topo)

- 2026-09-30 14:12: Diretor avisou o merge do PR #22 e pediu para manter as informações do
  Jira atualizadas internamente até devolver o acesso. Arquivo criado.
- 2026-09-30 13:57: Diretor avisou o merge do PR #21. Operação pendente: KAN-177 → `41`.
- 2026-09-30 13:26: acesso ao Jira retirado. Ficaram pendentes o `finish-dev` (KAN-177 →
  `31`) e o comentário de branch/PR.
- 2026-09-30 13:16: KAN-177 `11` → `21` Em andamento (medido no retorno do conector).
