# mnemonicos-workspace — guia para IA

Pasta de trabalho que reúne dois repositórios **separados** (cada um com seu próprio
`.git`, symlinkado aqui): [mnemonicos-backend](mnemonicos-backend) (Node 22 · Express 5 ·
Prisma 7 · PostgreSQL · API pura) e [mnemonicos-frontend](mnemonicos-frontend) (Next 16 ·
React 19 · Tailwind 4 · Redux Toolkit). Este workspace tem git próprio — versiona a ficha
keelson e os artefatos SDD compartilhados entre os dois; os repositórios symlinkados estão
no `.gitignore` daqui e continuam versionados de forma independente em seus próprios
`.git`, cada um com seu remote no **GitHub**.

## Contexto do projeto

- O produto é o **Projeto Material Mnemônico de Alta Retenção para Concursos**: acervo de
  ganchos mnemônicos por assunto, flashcards derivados deles e revisão espaçada. O objetivo
  do produto é converter **reconhecimento** (bater o olho e achar familiar) em **evocação**
  (lembrar sem a dica na frente) — é essa a régua de valor de qualquer feature.
- **Projeto novo, sem legado.** Não há sistema anterior a imitar: padrão estranho no código
  é defeito, não herança. Divergiu do guideline → corrija, não replique.
- **Banco de dados:** o schema é novo e ainda cresce, então `CREATE`/`ALTER`/migração é
  esperado — mas **toda migração exige perguntar ao usuário antes de executar**, e nunca
  rodar comando que altere estrutura ou dado silenciosamente. `prisma migrate dev` gera
  arquivo versionado: ele entra no diff da TASK, com a migração revisável.
- **Pedidos de feature em termos de UI** ("nova tela", "listagem de X") quase sempre têm
  contraparte no **mnemonicos-backend** (endpoint, modelo Prisma, migração). Antes de
  escopar como "só frontend", confirme se a origem do dado já existe.
- **Os tipos do domínio existem nos dois lados** e são mantidos em sincronia à mão:
  `mnemonicos-frontend/src/types/domain.ts` e `mnemonicos-backend/src/domain/types.ts`.
  Mudou um enum de um lado → o outro entra no mesmo diff, ou o contrato quebra em runtime
  sem o typecheck acusar.

## Padrão de codificação — regras críticas

Os CLAUDE.md dos dois repositórios **não são carregados** nas sessões deste workspace
(`claudeMdExcludes` em `.claude/settings.json`) — o padrão vive aqui. Antes de codar num
repo, leia o README do guideline correspondente:
[guidelines/project/backend/README.md](guidelines/project/backend/README.md) ·
[guidelines/project/frontend/README.md](guidelines/project/frontend/README.md).

- **Precedência**: em conflito, as guidelines de projeto (`guidelines/project/<role>/*.md`)
  **vencem** o perfil de linguagem (`node-22.md` / `next-16.md`).
- **Commit**: **Conventional Commits** (`commit.convention: "conventional"` na ficha) —
  `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`. Não há hook que prefixe nada;
  o tipo sai de quem comita. Não há automação de release (`releaseAutomation: null`), mas
  o histórico já é legível por uma — não invente tipo fora da lista.
- **Branch — este repo (workspace) fica sempre na `main`**: artefatos SDD, ficha,
  guidelines, MAP e briefs são consumidos por outros ciclos e sessões paralelas; escondê-los
  numa branch de feature é a origem dos conflitos em `docs/`. Commite **direto na `main`**
  aqui, e confira `git branch --show-current` antes.
- **Branch (repos de código) — a base é a `main`.** Os dois repos são novos e têm só `main`;
  não há `master`, `release` nem trilho de release. Branch nova sai de `origin/main`, PR
  para `main`. Nome: `feat/<slug>-<descrição-curta>` (`git.branchNaming: "slug"` na ficha).
  Quando o tracker entrar, ver *Tracker* abaixo antes de mudar para `tracker-key`.
- **Segredos**: nunca commitar (`.env*`) nem reproduzir valores de `.env` em respostas. Os
  dois repos têm `.env` no `.gitignore` e `.env.example` com placeholders — mantenha assim.
  Tudo prefixado `NEXT_PUBLIC_` vai para o bundle do browser e é **público**: chave, string
  de conexão e `JWT_SECRET` ficam **só** no backend.
- **Backend**: camadas por módulo — **schema** (Zod) → **service** (regra + Prisma) →
  **routes** (HTTP). Nada de Prisma direto na rota. Express 5 encaminha promise rejeitada
  ao error handler: handler `async` não precisa de `try/catch` nem wrapper. Erro previsto é
  `AppError` (ou subclasse); qualquer outra exceção devolve 500 genérico — stack, mensagem
  do driver e nome de tabela ficam só no log. Lógica de negócio pura fica em função sem I/O,
  recebendo `now` por parâmetro (ver `src/modules/review/scheduler.ts`).
- **Frontend**: Server Components por padrão, `'use client'` só onde há estado ou evento.
  Estado do **servidor** é RTK Query (`src/store/api.ts`) — não replicar em slice manual;
  estado só-do-cliente é slice (`src/store/study-slice.ts`). `makeStore()` é função, nunca
  singleton de módulo (no SSR um singleton vaza estado entre requests). Tailwind 4: os
  tokens vivem no `@theme` de `globals.css`, não em arquivo de config JS.
- **Identificadores de código em inglês; texto de interface em pt-BR.** Vale nos dois repos.
- **Escopo mínimo** nos dois repos: seguir as convenções do módulo tocado; sem refactor
  em massa sem pedido.

## Ambiente local — portas

Padrão: **frontend `3000`** (`next dev`) e **backend `3333`** (`PORT`, default em
`mnemonicos-backend/src/config/env.ts`). Porta ocupada **não é motivo para parar**: suba na
próxima livre (`3001`, `3334`, …) — sessão paralela nos dois repos é rotina aqui.

🔴 **Mudar a porta do frontend tem contrapartida obrigatória no backend.** `CORS_ORIGINS` é
allowlist explícita (`mnemonicos-backend/src/app.ts`) e a **mesma** lista governa a guarda
de `Origin`/`Referer` das rotas de sessão (`src/modules/auth/auth.routes.ts`). Frontend em
`3001` sem `http://localhost:3001` na allowlist → **o login falha calado**: sem erro na
tela, sem log óbvio, a sessão simplesmente não se estabelece. Já aconteceu e já custou um
gate 9 (lição registrada no INDEX de `producao-material`, 2026-09-07).

Ao subir fora do padrão, o ajuste é parte da mesma ação, não um passo seguinte:

- **frontend em porta nova** → acrescente a origem a `CORS_ORIGINS` no `.env` do backend;
- **backend em porta nova** → aponte `BACKEND_API_URL` no `.env` do frontend para ela (é o
  valor que o `rewrites()` do `next.config.ts` usa; não tem prefixo `NEXT_PUBLIC_` porque
  não pode ir para o bundle).

Os dois são `.env` **local, não versionado** — mexer neles é alteração de ambiente do
Diretor, então **declare no relatório de fecho** qual arquivo mudou e para quê. Nunca edite
`.env.example` para isso: ele é contrato de placeholders, não o seu ambiente.

## Tracker (Jira) — ligado e medido

O projeto é **`KAN`** em `mp-consultoria.atlassian.net`, board `2`. Site, `cloudId`,
`projectKey`, `boardId` e `mapFile` estão na ficha; o mapa é
[docs/_meta/jira.KAN.md](docs/_meta/jira.KAN.md).

`jira.enabled` está **`true`** desde 2026-08-27, com os quatro papéis preenchidos a partir
do `createmeta` real do projeto — `spec` → Epic (`10006`), `feature` → História (`10009`),
`task` → Subtask (`10007`), `standalone` → Tarefa (`10008`). A régua que autorizou ligar
continua valendo para toda medição futura: **ligar antes de medir é pior que deixar
desligado** — o sync é best-effort e não bloqueia o ciclo, então falha incompleta não
aparece, ela só não acontece. Id de tipo ou de transição que ainda não foi observado neste
board se mede antes de usar; não se herda de outro projeto nem se deduz da sequência.

🔴 **Não copie configuração de tracker de outro workspace para cá.** Os valores certos são
`mp-consultoria.atlassian.net` / `455dadeb-0906-4adf-9500-c9bfb2b979bd` / `KAN`. Ver
`autoavaliar.atlassian.net` ou `c58a7785-…` nesta ficha significa que alguém colou config
do `b2b-workspace` — e o keelson passaria a criar os épicos e histórias deste produto no
board `NOVA`, de outro produto.

`git.branchNaming` segue em `"slug"` por escolha, não por impedimento: com `jira.enabled:
true` o self-check do `/keelson:init` já aceitaria `"tracker-key"` — a troca é decisão do
Diretor, não consequência automática de ter ligado o sync.

### Trilho do card — quem move o quê

O sync do keelson tem **teto**: nenhum gancho automático passa da coluna de desenvolvimento
(§9 do protocolo, decisão 4.65 — uma Story já foi fechada indevidamente por régua
automática). Acima do teto quem decide é o Diretor; o Tech Lead executa a ordem, nunca a
antecipa. Ids medidos neste board — iguais para Epic, História, Tarefa e Subtask:
`11` Tarefas pendentes · `21` Em andamento · `31` Em análise · `41` Concluído.

| Momento | Quem dispara | Subtask | História | Epic |
| --- | --- | --- | --- | --- |
| TASK despachada | gancho do ciclo | `21` Em andamento | `21` Em andamento | intocado |
| TASK fechada | closure da TASK | `41` Concluído | — | intocado |
| Desenvolvimento terminado | `--phase finish-dev` | `41` Concluído | `31` **Em análise** | intocado |
| **Diretor mergeou** | **aviso do Diretor** | — | `41` **Concluído** | condicional, abaixo |

**Ao mergear, avise.** O Tech Lead não descobre merge sozinho, e o teto do §9 existe
justamente para ele não adivinhar: História parada em "Em análise" significa "esperando o
merge", não "esquecida". Recebido o aviso, o Tech Lead:

1. move a História mergeada para `41` (Concluído);
2. **consulta os filhos do épico** por JQL (`parent = <EPIC>`) — o estado vem do quadro,
   nunca da memória da sessão nem do que o `INDEX.md` diz;
3. se **todos** os filhos estiverem em `41`, move o épico para `41` também; se sobrar
   qualquer filho aberto, **o épico não se toca**.

O passo 2 não é formalidade. Épico com filho pendente é estado **correto**, não pendência
a limpar — fechar épico por impressão de que "acabou" é a mesma classe de erro que o teto
do §9 previne. Caso vivo: **KAN-106** tem a única História (KAN-107) em `41` e segue em
`21` **de propósito**, porque ainda receberá trabalho (decisão do Diretor, 2026-09-16).

Este trilho é doutrina **deste workspace**, executada pelo Tech Lead via conector MCP: o
protocolo do plugin não tem verbo de fase pós-merge (só `start-dev` e `finish-dev`), então
não espere que `/keelson:auto` ou `/keelson:integrate` fechem card — eles param no teto,
por contrato. Story em "Concluído" ao fim de um `/keelson:auto` é bug, não sucesso.

<!-- ============================================================= -->
<!-- keelson — bloco gerenciado. Gerado por /keelson:init.          -->
<!-- Edite keelson.config.json, não este bloco.                    -->
<!-- ============================================================= -->

## Keelson — padrão de qualidade e fluxo (spec-driven development)

### Fonte da verdade

- **Ficha do projeto:** `keelson.config.json` na raiz — paths de código, comandos de
  qualidade, perfil de linguagem e gates ativos — e, opcional, o tier de modelo por papel: a cada
  despacho de agent, `ficha.sh --get models.<agent>` vai em `model:` do spawn, vazio →
  frontmatter do agent (régua em `sdd-conventions.md`). **Antes de qualquer tarefa, leia a
  ficha** e use os valores dela; nunca assuma caminhos ou comandos fixos.
- **Raiz do plugin:** os caminhos `${CLAUDE_PLUGIN_ROOT}/…` deste bloco só expandem
  dentro de comando/agent/skill do keelson — no Bash desta sessão a variável pode chegar
  **vazia**. Vazia → invoque `/keelson:version` (ele expande e imprime `raiz:`) e use esse
  caminho; nunca `find` nem uma versão escolhida no cache (decisão 4.404).
- **Constituição de qualidade:** o `QUALITY-CHARTER` do plugin — artigos agnósticos
  de linguagem.
- **Perfil de linguagem ativo:** conforme `profile` da ficha — o backend e (se houver)
  o frontend; o campo `file` diz onde ele mora (prefixo `plugin:` → perfil embarcado do
  keelson; caminho relativo → perfil do projeto). Instancia o Charter na linguagem/versão
  deste projeto.
- **Guidelines específicos deste projeto:** `guidelines/project/` (têm precedência
  sobre os perfis do plugin no mesmo nome; caso contrário, somam).
- **Integração com Jira (opcional):** se a ficha tem `jira.enabled: true`, o ciclo espelha
  SPEC/funcionalidades/TASKs em issues via conector MCP Atlassian — config por ID no bloco
  `jira` e no mapa `jira.mapFile`. É **best-effort** (nunca bloqueia — mas sempre conta:
  o fecho do ciclo reconcilia o slug e o relatório de entrega traz a linha de estado do
  tracker) e **sem segredos**.

### Como trabalhar

- **Modo padrão = autônomo** (`/keelson:auto` — não precisa digitar o comando): pedido
  não-trivial em linguagem natural **sem declaração de intenção pontual** (bullet
  seguinte) entra no ciclo `specify → plan → tasks → implement`
  conduzido pelo **time** keelson (po, developer, code-reviewer, qa, security-engineer,
  performance-engineer, product-designer),
  sob o contrato Diretor–PO: o brief é emitido na largada (janela de veto — o fluxo
  segue sem esperar), o PO valida SPEC e entrega **contra o brief**, e a entrega fecha
  com o **relatório de aceitação do PO**. Você é o **Diretor**: veto, PR, merge para a
  branch principal e deploy são seus — a autonomia termina no push da branch. Aprovação etapa a etapa é
  opt-in (`/keelson:guided`). Rigor **proporcional a complexidade × risco** (ver Charter).
- **Mudança pontual = modo sob demanda** (decisão 4.75): ajuste localizado de código,
  sem decisão de produto, não precisa do ciclo. **Declaração de intenção pontual do
  Diretor** ("ajuste pontual", "sem ciclo", "mudança direta") **escolhe este modo como
  default de porta, sem re-julgar** (decisão 4.246; vale **fora de comando em
  execução** — inclusive logo após a entrega de um ciclo na mesma sessão, quando a
  sessão volta a ser livre; comando `/keelson:*` invocado segue o contrato do
  comando, 4.129): a promoção ao ciclo
  continua existindo só pela régua falsificável deste bullet (mudança de promessa ·
  decisão entre alternativas · o teste 4.205 abaixo) e é **declarada com motivo antes
  de seguir, nunca arbitrada em silêncio** (família 4.85). Neste modo, **a main
  session (Tech Lead) não escreve o código**: destila um briefing curto (o quê, onde, critério de aceite) —
  que **nasce em arquivo**, como **brief avulso** em
  `{docsRoot}/<slug>/briefs/BRIEF-MMM-<descricao>-avulso.md` (esqueleto no
  `index-contract.md` do plugin; decisão 4.86; mudança que cruza slugs → **um brief só**,
  no slug dominante — onde viveria a SPEC — com 1 linha de rastro no INDEX dos demais,
  decisão 4.87) —, delega ao `developer` e passa o diff
  pelo `code-reviewer` (régua avulsa); `security-engineer` quando o diff toca a
  superfície sensível (lista canônica na description do agent — gate 8; `sensitiveGlobs`
  da ficha é sinal de PATH, complementar — não substitui o match por TÓPICO),
  `performance-engineer` quando o diff toca superfície de custo (lista canônica na
  description do agent — gate 10), `product-designer` quando o diff toca superfície
  de interface (lista canônica na description do agent — gate 11) e `qa`
  quando há comportamento observável — mesmos gatilhos do ciclo, e o despacho nasce
  do **inventário derivado do diff, nunca de memória** (decisão 4.335 — a régua vive
  na seção *Orquestração da rodada*, abaixo). A orquestração da
  rodada — gates em paralelo sobre pacote de contexto único factual (4.89), correção
  que converge com teto de 1 retry e escalação ao Diretor (4.88) — tem **dono único**
  na seção *Orquestração da rodada* de
  `${CLAUDE_PLUGIN_ROOT}/guidelines/core/CODE-REVIEW.md`: siga-a no sob demanda como
  no ciclo. Invocar um agent
  **não puxa o ciclo**: cada um devolve a sua tarefa e para; a orquestração é sempre do
  Tech Lead, e — **regra deste modo, nunca do ciclo** — commit só a pedido do Diretor
  (no ciclo o commit por TASK é do time: o `developer` commita a implementação e a
  closure commita o fecho da task; decisão 4.91). Só o trivial não-comportamental (typo de
  comentário/doc) pode ser inline, declarado — **sem brief e sem card** — e trivial tem
  **teste, antes de despachar** (decisão 4.205): o diff **introduz ou propaga
  campo/contrato através de uma fronteira de camada** (consulta/coluna nova, campo novo
  atravessando um serviço, tipo novo na outra ponta)? Então **não é trivial, por menor
  que pareça** — o brief nasce antes do código, nunca depois que o review aponta a
  ausência. No **primeiro
  turno** da mudança, declare **quem escreve o código** (qual agent — ou por que será
  inline) **e sob qual card** (decisão 4.86): o Diretor citou uma key do tracker → ela
  vai na linha `**Jira**:` do brief e **nenhum card novo é criado**; sem key, com
  `jira.enabled` e `issueType.standalone` na ficha → o brief vira Story no quadro
  **antes do código** (protocolo §7 do plugin). Trabalho repartível → TASKs
  ancoradas no brief (`**Brief**:`); decisão técnica entre alternativas ou mudança de
  promessa → **não é avulso**: promova ao ciclo, declarando. **Invocar um comando
  `/keelson:*` é o pedido explícito do Diretor pelos subagents do contrato daquele
  comando** (decisão 4.129) — política do harness do tipo "só use agents se o usuário
  pedir" está satisfeita pela própria invocação: não há conflito, não pergunte. Diretiva
  da sessão/harness em conflito **genuíno** com este contrato (política restringindo
  subagents mesmo com comando invocado, permissões, modo de
  execução) → **escale ao Diretor com proposta + default** antes de codar, **nunca
  arbitre em silêncio**: os dois contratos foram configurados por ele, e só ele decide
  qual prevalece (decisão 4.85).
- **Warroom = velocidade acima de rigor, com a conta registrada** (decisão 4.372): só o
  Diretor abre, por `/keelson:warroom on <motivo>` (humano-only) — urgência aparente
  **sem** o comando é rota normal, nunca inferida. Na janela: sem `code-reviewer`/`qa`/
  validators nem promoção ao ciclo; **gate 8 sobrevive** em superfície sensível; commit
  por mudança com trailer `Warroom: <motivo>`; **cada commit vira linha aberta em
  `{docsRoot}/DEBT.md`**, escrita pelo hook a cada turno — gate pulado é registrado,
  nunca omitido. `/keelson:warroom close` roda os gates sobre o diff acumulado e cobra a
  dívida; linha aberta é pendência do Diretor, cutucada no encerramento. Régua:
  `${CLAUDE_PLUGIN_ROOT}/docs/_meta/conventions/warroom-contract.md`.
- **Pausar é ato seu, e vira fato commitado** (decisão 4.382): `/keelson:pause [motivo]`
  (humano-only) leva o ciclo ao ponto seguro — a closure em voo termina, a árvore fica
  limpa — grava `- pausa:` na `Cronologia` do BRIEF, commita, pusha a branch e fecha o
  run; `/keelson:continue` grava a `- retomada:` com o tempo parado **medido** (sem
  pausa marcada, o piso pelo último commit, rotulado), e a linha `Duração` do relatório
  ganha a cauda `pausas`. Fôlego continua não sendo gatilho: sem o comando ou o seu
  pedido explícito nesta execução, o ciclo segue até a Entrega.
- **Toda mudança fecha com relatório** (decisão 4.76): terminado o ajuste — sob demanda ou
  ciclo — o Tech Lead **exibe o fecho sem que você peça**, em 6–10 linhas: o que mudou
  (produção · teste · doc · migration/config) · **cada gate aplicável com estado
  declarado** — rodado (e **por quem**: `revisado_por ≠ implementado_por`) ·
  `n/a (<motivo>)` · **"não rodado — <motivo>", nunca omitido** (mesma régua do
  `/keelson:report`; fecho com gate pendente se declara **parcial** e não convida ao
  commit — decisão 4.85) · decisões tomadas em seu nome · o que ficou fora de
  escopo ou pendente · **toda `licao_candidata` devolvida por qualquer gate da rodada
  — inclusive retry — com destino registrado e verificado** (`alvo: projeto` →
  `guidelines/project/lessons/<slug>.md` · `alvo: processo` → `agile-coach`; a linha só se
  escreve com a lição conferida **presente** no destino —
  `bash "${CLAUDE_PLUGIN_ROOT}/scripts/lessons.sh" . show <id>` sai 0, decisão 4.376 —
  declarar "roteada" sem escrever no destino é a forma que reincidiu, decisão 4.333): aplicar a
  correção de código que o achado pede **não é** rotear a lição que ele carrega — são
  dois atos, e lição sem destino também declara o fecho **parcial** (decisão 4.204) ·
  estado do tracker (com `jira.enabled`) · e o que depende de você
  — **por modo** (decisão 4.91): no sob demanda, o commit é seu; no ciclo, a branch já
  chega commitada TASK a TASK (e pushada pelo `/keelson:auto`) — seus atos são revisão,
  PR e merge (decisão 4.41). O relatório é montado a partir do **ledger de sessão**
  (no `ledger/` da casa da sessão — `thoughts/local/sessions/<ts>-<sid8>/`; instalações
  antigas usam `thoughts/local/session-ledger/`), onde cada evento é escrito **quando
  acontece** — não se relê a sessão para produzi-lo, e o que o contexto comprimiu não se
  perde. Relatório perdido ou sessão retomada → `/keelson:report` reconstrói.
- **Varredura ampla → `code-scout`**: pergunta que exige varrer a codebase (entender
  um fluxo, mapear consumidores, "de onde vem este dado?") é delegada ao `code-scout`,
  que devolve conclusão ancorada em `arquivo:linha` — os arquivos lidos não entram no
  contexto da sessão. Lookup pontual (um grep) segue inline.
- **Slug com `MAP.md`** (`{docsRoot}/<slug>/MAP.md`): é o **primeiro insumo** de qualquer
  exploração daquele domínio — leia-o antes de varrer; âncora que vira decisão se confere
  (régua 4.58). Mudou o território numa entrega → o delta entra no MAP na closure
  (contrato: `map-contract.md` do plugin).
- **Definição de pronto (gates):** ACs cobertos por prova · testes passando · lint
  limpo · escopo respeitado · decisões respeitadas · aderência ao Charter + perfil ·
  code review · **segurança** e **comportamento verificado** (condicionais aos gates
  da ficha) · **performance** e **design/UX** (condicionais à superfície tocada —
  listas canônicas nas descriptions dos agents) · **aceitação do PO** contra o brief
  (rotas com brief/espelho).
- A prova de pronto é **externa e falsificável** (um teste que cobre o comportamento),
  nunca um autochecklist — **gerador ≠ avaliador**.

### Comandos

Comandos `/keelson:*` — veja as descriptions na listagem de skills da sessão.
Humanos-only (não aparecem na listagem): `/keelson:guided` (ciclo com checkpoints) ·
`/keelson:brief` (forjar documento de produto em BRIEF, pré-ciclo) ·
`/keelson:refine` (lapidar ideia) · `/keelson:audit` (auditoria de dependências) ·
`/keelson:review` (code review de um diff avulso, sem artefato SDD) ·
`/keelson:merge` (mesclar uma ou mais branches na branch de trabalho corrente, uma de
cada vez, com commit de merge próprio por branch — push, merge remoto, PR e deploy
continuam humanos) ·
`/keelson:warroom` (abrir/fechar janela sem gate bloqueante, dívida em `DEBT.md`) ·
`/keelson:verify-handoff` (fechar gate de tela remoto) ·
`/keelson:continue` (retomar um slug de onde parou — fila do épico, wave interrompida
ou próxima fatia, derivado dos artefatos commitados; grava a marca de retomada com o
tempo parado medido) ·
`/keelson:pause` (parar o ciclo num ponto seguro — closure commitada, marca de pausa
commitada e pushada no BRIEF, para o continue medir o tempo parado de qualquer máquina) ·
`/keelson:mutation-setup` (instalar e configurar o mutation testing — grava
`quality.mutation` na ficha após prova) ·
`/keelson:e2e-setup` (instalar e configurar a suíte E2E Playwright — grava
`quality.e2e` na ficha após prova) ·
`/keelson:update` (atualizar o plugin instalado — vale após reiniciar a sessão) ·
`/keelson:report` (refazer o relatório de fecho — sessão retomada ou report perdido) ·
`/keelson:postmortem` (postmortem de fim de sessão — relê as interações e produz a
mensagem ao mantenedor do plugin).

<!-- ============================================================= -->
<!-- fim do bloco keelson                                          -->
<!-- ============================================================= -->
