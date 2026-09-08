# BRIEF-010: `vercel-build` aplica as migrações pendentes a cada deploy

**Slug**: producao-material
**Tipo**: avulso
**Status**: Concluído
**Data**: 2026-09-06
**Origem**: Diretor (pedido em sessão, durante a subida do backend para a Vercel)
**Jira**: **não criado — sync degradado.** O conector MCP Atlassian desta sessão está autorizado
só para `autoavaliar.atlassian.net`; `mp-consultoria.atlassian.net` (cloudId `455dadeb-…`,
projeto `KAN`) não está no grant, e abrir o card no site errado é exatamente o que o CLAUDE.md
proíbe. Reautorizar o conector e rodar `/keelson:jira-sync` fecha a lacuna.

## Pedido como dito

"Faça esse ajuste direto na main, quero que vercel-build seja suficiente para rodar tudo sempre
que atualizar mesmo se tiver novos dados, as migrações acho que estão versionadas, e deveriam
mesmo."

## Contexto

O deploy do backend na Vercel nunca aplicou migração. O `vercel-build` é `prisma generate` — e
só; o `postinstall` já roda `prisma generate` de qualquer forma, então o passo de build era
redundante e não tocava o banco. As 5 migrações versionadas em `prisma/migrations/` (de
`20260823161550_init` a `20260906143159_add_production_stage_event`) nunca chegaram ao Postgres
de produção. Sintoma na ponta: não é possível logar.

O Diretor já apontou o Build Command do projeto na Vercel para `npm run vercel-build`, então
mudar o script no repositório basta — não há segundo ajuste no dashboard.

Escopo decidido pelo Diretor (AskUserQuestion): **só migrações**, sem seed. O seed continua
manual, rodado da máquina do Diretor. Motivo: colocá-lo no build exigiria `SEED_ADMIN_EMAIL` e
`SEED_ADMIN_PASSWORD` permanentes nas env vars do projeto — a senha real do primeiro ADMIN
morando no ambiente de build de todo deploy, sem ganho equivalente.

## Interpretação

Uma linha do `package.json`. Migração versionada é o contrato: `migrate deploy` aplica só o que
está em `prisma/migrations/`, na ordem, sem gerar nada novo e sem prompt — é o comando desenhado
para CI, ao contrário de `migrate dev`.

## Critério de aceite

- `mnemonicos-backend/package.json`: `"vercel-build": "prisma generate && prisma migrate deploy"`.
- **Nada mais no `package.json` é tocado** — `postinstall`, `prepare`, `build` e `start` ficam
  como estão. Nenhum arquivo de `src/`, `prisma/schema.prisma` ou migração é alterado; nenhuma
  migração nova é gerada.
- `prisma migrate deploy` usa conexão direta: o `prisma.config.ts` já resolve
  `DIRECT_URL ?? DATABASE_URL`. Se `DIRECT_URL` não estiver nas env vars da Vercel, o build falha
  no pooler — **isso é ambiente, não código**; registre como pendência ao Diretor, não tente
  contornar no script.
- Se algum doc do repo (README ou similar) descreve o fluxo de deploy/migração, atualize no mesmo
  diff — doc que passa a mentir é defeito.
- Medições de regressão do backend verdes: `npm run lint`, `npm run typecheck`, `npm test`.
  (Integração exige Postgres local; não subindo, declare "não rodado" com o motivo.)
- **Nenhum comando que toque banco real** durante a execução desta task: nada de `migrate deploy`,
  `migrate dev`, `db push` ou seed apontados para qualquer banco. A validação do comando é o
  próximo deploy, ato do Diretor.

## Riscos aceitos (declarados pelo Diretor)

- DDL passa a rodar em produção a cada push, sem revisão no meio — a autorização por migração vira
  autorização permanente.
- Deploy de preview também roda o build: com Preview e Production apontando para o mesmo banco,
  todo push de branch migra a produção. Separar por ambiente fica como pendência.
- Migração quebrada derruba o build e nenhum deploy sai (fail secure — o deployment anterior segue
  servindo). **Custo de recuperação, medido pelo gate 8 contra o engine instalado (prisma 7.9.1)**:
  não é "um deploy falhou". A migração que falha grava linha FAILED em `_prisma_migrations` e todo
  `migrate deploy` seguinte aborta (P3009) — a esteira inteira trava, inclusive hotfix de
  segurança, até `prisma migrate resolve --rolled-back <migration>` rodar à mão contra produção
  com a `DIRECT_URL`. Break-glass: apontar o Build Command do painel para `npm run build` (que não
  migra) destrava o deploy sem tocar o banco. Runbook versionado no README nesta mesma entrega.
- **4º risco, levantado pelo gate 1-7 e não previsto na apresentação original ao Diretor**:
  cruzado com RISK-006-009 (nenhum dos 2 repos tem CI), o DDL passa a alcançar produção sem que
  nenhum teste automatizado tenha rodado antes. O fail secure protege o *deploy*, não o *schema*:
  migração sintaticamente válida e semanticamente errada é aplicada sem gate. E `migrate deploy`
  é forward-only — o Instant Rollback da Vercel devolve o código antigo sobre o schema novo.
  Vale para as próximas migrações; as 5 pendentes hoje já passaram por review nos PRs delas.
- **Segredo que a mudança passa a exigir, levantado pelo gate 8**: a `DIRECT_URL` — credencial de
  conexão DIRETA, com DDL/DML sobre o banco de produção — torna-se obrigatória e permanente no
  ambiente de build de todo deploy, legível por todos os install scripts da árvore npm. É a mesma
  classe de exposição que motivou tirar o seed do build, com credencial mais poderosa que a senha
  do primeiro ADMIN: com a `DIRECT_URL` cria-se o ADMIN, e qualquer outro. Não reverte a decisão,
  mas o Diretor decidiu sem essa metade do trade-off na mesa.

## Pendências roteadas (fora deste diff)

- **Fail-closed em `prisma.config.ts:17`** (gate 8, media): `DIRECT_URL ?? DATABASE_URL` é fallback
  silencioso e permissivo — sem `DIRECT_URL`, o Prisma tenta emitir DDL pelo pooler em vez de
  recusar. Na Vercel as env vars são escopadas por ambiente, então "presente em Production, ausente
  em Preview" é configuração normal e silenciosa. Correção sugerida: lançar quando `DIRECT_URL`
  faltar (fail fast do node-22.md §6.4, citando o NOME da variável, nunca o valor). É mudança de
  comportamento — decisão do Diretor, não cabe neste avulso.
- **Role de migração dedicado** (gate 8): a `DIRECT_URL` do build deveria usar role distinto do
  role de runtime da `DATABASE_URL`, com DDL no schema da aplicação e sem ser superusuário.
- **`npm audit`** (gate 8, pré-existentes, não introduzidos por este diff): `qs` via `express@5.2.1`
  e `body-parser@2.3.0` (GHSA-x5fp-wj9c-mxmx, GHSA-4mjr-xmp4-gh2g — alcançável em produção, o
  `npm audit fix` resolve sem breaking change) e `mysql2` via `prisma@7.9.1` (GHSA-3f6p-5ww8-9rcr,
  GHSA-rgwj-5xj2-c3m3 — inalcançável, o projeto é Postgres; sem correção não-breaking hoje).
- **Artefatos do workspace** que o push torna falsos: `INDEX.md:24` e
  `BRIEF-2026-08-27-mnemora-studio-epic.md:152` afirmam que a aplicação em produção é ato manual
  do Diretor. Atualizados na closure desta rodada.

## TASKs

nenhuma — o brief é a unidade de execução (1 arquivo, 1 script).

## Execução

- **Implementado por**: developer
- **Revisado por**: code-reviewer (gates 1-7) + security-engineer (gate 8)
- **Branch**: `main` — direto, por decisão explícita do Diretor ("faça esse ajuste direto na main")
- **Commit/push**: `2bb9dc0`, pushado para `origin/main` em 2026-09-06 (autorizado pelo Diretor
  via AskUserQuestion). O deploy disparado por ele é a verificação do critério central.
- **Gates**: code-reviewer (1-7) **APROVADO** sem retry · security-engineer (8) **APROVADO**,
  5 achados `media`, nenhum bloqueante · 1 retry doc-only no README (as 4 correções que os dois
  gates pediram) · qa (9) **não rodado** — o comportamento só é observável no deploy, e o brief
  proibia tocar banco; a verificação é do Diretor no log do build · performance (10) e
  design (11) **n/a** (nenhuma superfície de custo ou de interface tocada).
- **Fecho declarado PARCIAL** até o Diretor confirmar no log do build da Vercel as 5 migrações
  aplicadas (`20260823161550_init` … `20260906143159_add_production_stage_event`) e o login
  funcionando em produção — que é o sintoma de origem.
