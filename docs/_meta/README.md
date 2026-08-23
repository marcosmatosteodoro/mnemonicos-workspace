# `docs/_meta` — metadados do fluxo SDD

Aqui vive o que é **configuração do processo**, não artefato de demanda. Hoje só há este
documento; o mapa do tracker nasce quando o tracker for ligado.

## Pendência conhecida: perfis de linguagem

`profile.backend.file` e `profile.frontend.file` apontam para o fallback embarcado do
plugin (`plugin:backend/none.md`, `plugin:frontend/none.md`). Os perfis próprios deste
projeto — `guidelines/project/backend/node-22.md` e
`guidelines/project/frontend/next-16.md` — são gerados pelo `/keelson:init` rodado **numa
sessão aberta na raiz do workspace**, via agent `staff-engineer`. Enquanto não existirem,
o rigor vem só de `guidelines/project/`.

## Ligar o Jira — o que falta

O projeto está definido: **`KAN`** em `mp-consultoria.atlassian.net`, board `2`
(informado pelo Diretor em 2026-08-23). Site, `cloudId`, `projectKey`, `boardId` e
`mapFile` já estão na ficha; o restante e os comandos de medição estão em
[jira.KAN.md](jira.KAN.md).

`jira.enabled` segue **`false`** porque os ids de `issueType` ainda são `null`. O sync é
*best-effort* e **não bloqueia** o ciclo: config incompleta não dá erro visível, ela falha
em silêncio a cada gancho. Ligar antes de medir é como não ligar, só que sem perceber.

O que impede medir daqui: o conector MCP Atlassian **desta** máquina tem grant apenas para
`autoavaliar.atlassian.net` (corporativo). Uma tentativa de leitura em `mp-consultoria`
devolve `Cloud id ... isn't explicitly granted by the user` — foi essa resposta que
resolveu o `cloudId`, mas nenhum dado do projeto foi lido. O OAuth na conta certa (`/mcp`)
é pré-requisito, e acontece na máquina dedicada.

🔴 **Nunca** preencha `site`/`cloudId` com `autoavaliar.atlassian.net` /
`c58a7785-1d06-4c7a-a5ed-d2734bbb1b69`. É o Jira corporativo de outro produto; o keelson
criaria os épicos e histórias deste projeto no board `NOVA`. Se você está vendo esses
valores nesta ficha, alguém copiou config de outro workspace.

Com os ids medidos e `jira.enabled: true`, `git.branchNaming` pode virar `"tracker-key"`
(branch nomeada pela key). Com `enabled: false` essa combinação é reprovada pelo self-check
do `/keelson:init`.

## O mapa do tracker é config, nunca ledger

Regra herdada do `b2b-workspace`, onde custou 877 linhas de contaminação para ser escrita.
Vale desde o primeiro dia aqui, justamente para não repetir:

- **Entra no mapa**: mapeamento de tipos · campos e estratégia · etapas/colunas e
  status-alvo · fases · trilho do board · **ids de transição medidos** · validators e
  post-functions descobertos · réguas de escrita no quadro.
  Critério: *a frase caberia numa instrução ao protocolo?*
- **NÃO entra**: registro de execução — árvore de issues por SPEC, tabela TASK→key,
  contagem de cards por estado, narrativa de rodada de gancho.
  Critério: *a frase conta o que aconteceu com cards específicos numa data?* Então é ledger.
- **Onde o ledger vai**: as keys pertencem aos **artefatos SDD** (linha `**Jira**:` das
  TASKs, `**Jira**:`/`**Jira Story**:` no cabeçalho das SPECs) e ao **INDEX** do slug; o
  estado vivo dos cards pertence ao **Jira**; a narrativa da rodada vai no **relatório de
  fecho** da sessão. Três registros do mesmo fato é o que produz contradição.
- **Achado de config descoberto durante execução** (um validator invisível, um id que
  mudou, uma post-function que não dispara) **sobe para o mapa como regra** — sem a
  narrativa do card em que foi visto. A medição justifica a régua; ela não é a régua.

## Épico → histórias → subtarefas

O fluxo de decomposição não depende do Jira: é do keelson e roda com o tracker desligado.

- `/keelson:specify-epic` — demanda grande vira BRIEF épico com a fila de demandas
  independentes e priorizadas. Cada uma segue **seu próprio ciclo SDD**.
- `/keelson:auto` (ou `/keelson:specify` → `plan` → `tasks` → `implement`) — cada demanda
  da fila vira SPEC (FRs em EARS, ACs em Given-When-Then), PLAN (componentes, DECs) e
  TASKs atômicas em waves.
- `/keelson:continue` — retoma um slug de onde parou: fila do épico, wave interrompida ou
  próxima fatia, derivado dos artefatos commitados.

Com `jira.enabled: true`, o mesmo fluxo **espelha** essa árvore no quadro: Épico ←
Histórias ← Subtarefas, pelos ids de `issueType`. Sem o tracker, a árvore existe só em
`docs/` — e o trabalho não para por isso.

Estratégia de branch do épico: `git.branchStrategy: "unica"` na ficha (todas as fatias
empilhadas na branch do épico, um PR ao final). O default é proposto na confirmação do
épico e pode ser sobrescrito épico a épico; o que vale para leitura é sempre o que ficou
gravado no BRIEF.
