---
area: Ambiente
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/package.json
  - mnemonicos-backend/docker-compose.yml
tags: [worktree, docker-compose, sessao-paralela, ambiente-local, gate-9]
---
## [Ambiente] Em worktree do backend, o servidor sobe com `npm run dev:no-db`; `npm run dev` recria o Postgres da outra sessão

**Erro:** no PLAN-065 (gate 9 da FEAT-064-001, 2026-10-18), o briefing do Tech Lead mandou o QA
rodar `npm run dev` no worktree `kan237/mnemonicos-backend`. O script `dev` roda
`npm run db:up && …`, e `db:up` é `docker compose up -d --wait`. O nome do projeto compose é o
nome da pasta (`mnemonicos-backend`), o mesmo do repositório principal. O compose do worktree
recriou o container `mnemonicos-db`, que era o Postgres 127.0.0.1:5432 da sessão paralela,
tentou publicá-lo na porta do `.env` do worktree (5433, já ocupada pelo `mnemonicos-db-kan237`)
e o deixou em `Created`, parado. O volume `mnemonicos-db-data` continuou anexado.
**Causa:** um worktree com o mesmo nome de pasta herda o nome de projeto compose do repositório
principal, e o `predev` sobe o banco "do projeto". O briefing tratou `npm run dev` como neutro.
**Solução:** em worktree, o servidor do backend sobe com `npm run dev:no-db` (o banco dedicado já
está no ar) e nunca com `npm run dev`, `db:up`, `db:setup`, `db:down` nem `db:destroy`. Briefing que
manda subir servidor em worktree diz isso por extenso. Se o compose for mesmo necessário, ele roda
com um nome de projeto próprio (`docker compose -p <nome-do-worktree> …`). Container de outra sessão
derrubado é escalado ao humano: não se restaura por conta própria.
