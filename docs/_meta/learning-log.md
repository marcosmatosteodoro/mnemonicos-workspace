# Ledger de aprendizado do processo

> Mantido pelo agent `agile-coach`. Não editar manualmente (exceto revisão humana de uma entrada).
> Só erro de PROCESSO entra aqui; lições de código/projeto → `guidelines/project/`.
> Entradas nunca são apagadas; no máximo marcadas `estado: destilada`.

## LRN-001: higiene da árvore na rodada de gates não é prova mecânica
data: 2026-08-31
atualizado: 2026-09-06
gatilho: retry
origem: PLAN-003 (slug producao-material, épico MNEMORA STUDIO F1) — Waves 4, 5, 6, 7; reincidência em PLAN-006 (mesmo slug), Wave 2, retry de TASK-006-005; 3ª reincidência em BRIEF-007 (mesmo slug), gate 1-7 do code-reviewer — TRUNCATE concorrente de `mnemonicos_test` por dois runners simultâneos (2 rodadas, 84 e depois 48 falhas de FK lidas quase como regressão real); eixo novo do MESMO buraco: nem git-tracked, nem `node_modules` — banco de teste externo compartilhado por nome fixo. **4ª reincidência em PLAN-010 (mesmo slug), Wave 3** — rodada de 3 gates (`code-reviewer`/`security-engineer`/`performance-engineer`) despachada em paralelo sobre a MESMA árvore principal, sem worktree própria provisionada por gate antes do despacho: `security-engineer` se autoisolou corretamente (sem achado); `code-reviewer` leu o mesmo arquivo em 3 conteúdos diferentes durante a janela de revisão (2 mutantes do `performance-engineer` vivos na árvore principal — um com a emissão reordenada, outro com `$transaction` removido) e só não emitiu veredito falso porque ancorou por `git hash-object` **fora da doutrina** — a reconferência oficial (`git status --porcelain`) é CEGA a essa divergência: imprime a mesma linha " M arquivo.ts" para o código certo e para cada mutante; `performance-engineer` mediu contra `mnemonicos_test` (banco compartilhado por TODA a suíte de integração do projeto) e sofreu TRUNCATE concorrente de outro processo no meio de suas transações de medição — só chegou a números confiáveis depois de criar banco descartável próprio (`mnemonicos_perfgate`) e derrubá-lo ao fim; e **o Tech Lead (orquestrador) piorou o incidente**: de posse só do relatório já concluído do `security-engineer` (que mencionou arquivos `zz-*.ts` órfãos, "sem segredo, pode remover"), removeu esses arquivos da árvore principal sem confirmar que o `performance-engineer` — AINDA EM VOO na mesma rodada — os usava como sonda de medição; quase destruiu uma medição em andamento (autoria própria — o orquestrador tratou "concluído" de UM gate como "seguro para agir", ignorando os demais participantes da mesma rodada).
causa_raiz: instrucao_ausente — gates paralelos sobre worktree compartilhado deixaram rastro (sonda `zz-*.test.*`, `npm install`/`ci` mexendo lockfile e podando deps, worktree órfão `.review-wt` com `.env` real, mutante de elevação de privilégio vivo, alteração estagiada invertendo oráculo); a decisão 4.134 (`guidelines/core/CODE-REVIEW.md` §Orquestração) só barra concorrência entre gates que **também mutam** e trata restauração como disciplina em prosa. A resposta parcial já incorporada na doutrina instalada (decisão 4.290 — "3ª camada da família 4.134/4.276": captura `git rev-parse HEAD` + `git status --porcelain` na largada de cada gate e reconfere antes do veredito) só enxerga **estado rastreado por git** — `node_modules`/cache de build são gitignored e ficam cegos a essa prova. Reincidência (PLAN-006 Wave 2): worktree isolada linkou `node_modules` por **junção NTFS** (Windows, vínculo FÍSICO, não lógico) para evitar `npm install`; processos node/esbuild remanescentes de rodada anterior mantinham handle aberto sobre arquivo nativo dentro do `node_modules` REAL (alvo da junção) e, ao remover a junção/limpar a worktree, corromperam a árvore PRINCIPAL — nada detectou porque git não vê `node_modules`. Recuperado com `npm ci` só depois de a suíte ser revalidada manualmente; nenhum mecanismo do processo exigia essa revalidação. Segundo sintoma da MESMA ambiguidade, na mesma rodada: o `code-reviewer` do re-review de delta rodou os próprios mutantes de verificação **na árvore principal** (não em worktree), justificando "não havia gate concorrente" — leitura literal possível do texto atual ("roda em `git worktree` isolada — nunca a mesma árvore de **outro gate concorrente** que também mute"), que lê a cláusula de não-concorrência como a condição que aciona o isolamento, não como reforço de um mandato já incondicional. Mitigado por disciplina em prosa (`git checkout --` + `git status --porcelain` a cada mutante) — a mesma classe de mitigação que a 4.290 já tentou tornar mecânica, agora reaparecendo por uma leitura textual diferente. 3ª reincidência (BRIEF-007): a mesma lacuna — "a doutrina de exclusividade só enxerga UM tipo de estado compartilhado" — reaparece num eixo que não é filesystem: `jest.integration.config.ts` serializa com `maxWorkers: 1` só DENTRO do processo; `resetDb()` faz `TRUNCATE CASCADE` num banco (`mnemonicos_test`) de nome fixo, sem lock nem namespace por execução — dois gates da mesma rodada (default paralelo do keelson, decisão 4.89) truncam um ao outro e o sintoma imita regressão de produto. Nada na família 4.134/4.276/4.290 cobria recurso mutável compartilhado que não é git nem `node_modules`. **4ª reincidência (PLAN-010): três eixos novos da MESMA lacuna sistêmica — a rodada isola o gate que MUTA, mas nunca isolou o LEITOR nem o ORQUESTRADOR.** (i) A reconferência oficial (4.290: HEAD + `git status --porcelain`) é cega a CONTEÚDO — porcelain não distingue QUAL modificação está no arquivo, só QUE há uma; um `code-reviewer` disciplinado escapou por ancorar em hash fora do texto vigente, não por causa dele. (ii) A generalização de "recurso mutável compartilhado" (item (d), já identificada e ainda `proposta_doutrina (não aplicado)`) segue sem mecanismo específico — sem ele, nada NOMEIA que o gate 10 (performance) está proibido de usar o banco de teste da suíte; a generalização em prosa não é regra viva enquanto ninguém a aplica, e o mesmo buraco cobrou a 4ª rodada de medição perdida. (iii) A doutrina cobre COMMIT do orquestrador durante veredito em voo ("SHA sob revisão como âncora parada... nenhum commit novo entra na working tree") mas nunca cobriu EDIÇÃO/REMOÇÃO avulsa fora de commit, baseada em achado de UM gate já concluído, enquanto OUTRO gate da mesma rodada segue em voo — gap de instrução ao orquestrador, não ao gate.
artefato_patchado: proposta_doutrina (não aplicado) — `guidelines/core/CODE-REVIEW.md` §"Orquestração da rodada", extensão da família 4.134/4.276/4.290
patch: consolida lições 1–3 do ciclo (Wave 4-7 de PLAN-003); estende 4.134 para "nunca concorrente com QUALQUER gate que leia a árvore ou a saída do runner", e adiciona prova mecânica (3 medições `git rev-parse --short HEAD` · `git status --porcelain` · `git diff HEAD` na abertura e no fecho, divergência = achado bloqueante) + reversão canônica `git restore --source=HEAD --staged --worktree -- <path>` (nunca `git checkout -- <path>`). **Escada de promoção (decisão 4.149, reincidencia ≥ 2):** reformulação de texto não basta de novo — adiciona 4ª camada com check mecânico: (a) reescreve a frase-gatilho para remover a ambiguidade — gate mutante roda em worktree isolada **sempre**, independente de concorrência (a cláusula "nunca a mesma árvore de outro gate concorrente" deixa de ser lida como condição de acionamento); (b) worktree isolada NUNCA compartilha `node_modules`/cache por link físico (junção/symlink) com a árvore principal — instalação própria (`npm ci`) na worktree, ainda que mais lenta; (c) fecho de rodada que usou worktree isolada (ou, por exceção declarada e revisada, mutação direta na árvore principal) não reporta Done sem antes rodar `quality.test` completo na árvore PRINCIPAL pós-limpeza, resultado colado no report — nunca presumir que a limpeza/disciplina preservou a árvore principal sem essa prova. **3ª reincidência — generaliza o escopo, não só o mecanismo:** (d) a cláusula de exclusividade da 4.134 deixa de enumerar "árvore git"/"saída do runner" como a lista fechada de recurso protegido — passa a "qualquer recurso mutável compartilhado por processo concorrente da mesma rodada ou de outra sessão: árvore git, `node_modules`/cache, banco/schema de teste, porta, fila, arquivo de lock nomeado"; (e) gate que observa resultado vermelho não-determinístico (contagem de falha muda entre execuções idênticas do mesmo commit) confirma ausência de runner concorrente sobre o MESMO recurso ANTES de emitir veredito de regressão — nunca reprova por achado que não se repete de forma estável. **4ª reincidência — 3 camadas mecânicas novas, escada mantida (texto sozinho já falhou 3 vezes seguidas):** (f) a reconferência de âncora de cada gate deixa de aceitar só `git rev-parse HEAD` + `git status --porcelain` — soma `git hash-object` por arquivo do diff, capturado na largada e reconferido antes do veredito e a cada leitura relevante do mesmo arquivo dentro da janela; porcelain sozinho é insuficiente por desenho (mesma linha para conteúdos distintos sob "modificado"), hash é o mínimo que discrimina — divergência de hash descarta o veredito e re-roda, mesma régua da divergência de HEAD/porcelain. (g) regra NOMEADA para o gate 10 (performance), não mais só a generalização em prosa do item (d): a sonda do `performance-engineer` NUNCA mede contra o banco de teste usado por qualquer outro runner da suíte (nome/URL conhecidos pela ficha/config do projeto) — provisiona banco descartável próprio (nome derivado de PID/timestamp da rodada), migra, mede, derruba ao fim; o nome do banco descartável entra na "superfície de escrita" declarada no despacho, mesmo tratamento do worktree (decisão 4.302) — a linha do despacho e o report do gate 10 nomeiam o banco usado, e o orquestrador confere mecanicamente que não é o nome compartilhado antes de aceitar o veredito. (h) a cláusula "SHA sob revisão como âncora parada" passa a cobrir toda mutação do ORQUESTRADOR na árvore — não só commit: nenhuma remoção/edição avulsa de arquivo (inclusive "órfão"/"seguro para remover" apontado por um gate já concluído) enquanto QUALQUER gate despachado na mesma rodada segue em voo; antes de agir sobre um achado desse tipo, o orquestrador confere a lista de gates ainda pendentes da rodada — vazia é a única condição que autoriza a ação.
reincidencia: 4
estado: ativa

## LRN-002: `/keelson:tasks` não propaga `quality.build` (nem oráculo de valor lido em build/AST) para os Critérios de pronto
data: 2026-08-31
gatilho: gate_reprovado
origem: PLAN-003 — Waves 5–7 (frontend); `config.matcher` como expressão `.flatMap()` passou uma rodada inteira de gates com Jest verde, só o gate 8 pegou que `next build` abortava (Next lê `config` por AST estático)
causa_raiz: a lista fixa de "Critérios de pronto" do template de TASK não inclui `quality.build` quando a ficha o declara, e o critério herdado (EMENDA COMP-003-022) citou o sintoma ("`config.matcher` derivado de símbolo compartilhado") sem nomear o mecanismo que lê o valor (build/AST) nem um oráculo que passe por ele — leitura literal em runtime foi razoável e a suíte de unidade não cobre o caminho
artefato_patchado: proposta_plugin (modo consumidor) — `commands/tasks.md`, template "Critérios de pronto" + seção "verificação executável"
patch: consolida lições 4–5; critério de lint passa a exigir também `quality.build` da ficha quando declarado, sobre a fatia; critério cujo oráculo é valor resolvido em build/análise estática (não em runtime de teste) nomeia o comando de build, não só o runner de unidade
reincidencia: 0
estado: ativa

## LRN-003: TASK/EMENDA que remove ou inverte comportamento já testado não nomeia qual asserção migra
data: 2026-08-31
gatilho: verificacao_falhou
origem: PLAN-003 — Wave 7; reescrita de teste por mudança de assinatura perdeu o caso `userAgent`-omission (regressão de prova, decisão 4.174); inversão de oráculo por EMENDA (cache zerado → preservado) exigiu auditoria manual nos dois sentidos
causa_raiz: a decisão 4.174 vive só no lado do avaliador (`guidelines/core/CODE-REVIEW.md` §Convergência do re-gate); nada no lado do gerador (`commands/tasks.md`) obriga a TASK/EMENDA a declarar "asserção X do estado antigo migra para / é substituída por Y + fixture discriminante preservado" — a reescrita do teste decide sozinha e a suíte segue verde provando menos
artefato_patchado: proposta_plugin (modo consumidor) — `commands/tasks.md`, seção "Mapeamento de cada AC"
patch: TASK/EMENDA que remove, inverte ou troca o ramo de comportamento já coberto por teste carrega critério explícito nomeando a asserção que migra/é substituída, complemento gerador da 4.174
reincidencia: 0
estado: ativa

## LRN-004: briefing de despacho de gate citou ID de DEC inexistente (de memória)
data: 2026-08-31
gatilho: correcao_humana
origem: PLAN-003 — briefing citou `DEC-003-067`; o PLAN vai de DEC-003-001 a 012
causa_raiz: o "Briefing destilado para os gates dedicados" (`commands/implement.md` §3.3) lista "DECs que tocam o escopo" sem instruir a derivar os IDs do PLAN lido na abertura da wave — Tech Lead preencheu de memória (mesma classe da 4.92/4.124: conferir contra o artefato, nunca a lembrança)
artefato_patchado: proposta_plugin (modo consumidor) — `commands/implement.md` §3.3, linha do briefing destilado
patch: "DECs que tocam o escopo" passa a "DECs que tocam o escopo (IDs conferidos contra o PLAN lido na abertura da wave — nunca de memória)" — edição in-line, saldo 0
reincidencia: 0
estado: ativa

## LRN-005: Ambiguidade de "confirmado pelo Diretor" no report do developer
data: 2026-09-04
gatilho: gate_reprovado
origem: PLAN-006 (slug producao-material), Wave 1, TASK-006-001 — reprovação do code-reviewer no gate "escopo respeitado"
causa_raiz: instrucao_ausente — o contrato de report do `developer` (etapa 8) não distinguia "confirmar uma propriedade do artefato" (o SQL é aditivo) de "autorizar uma ação" (executá-lo); a frase "confirmado pelo Diretor" cobre os dois atos sem desambiguar, e o `code-reviewer` não tem acesso ao ledger de sessão onde a autorização real vive
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor)
patch: proposta de nova regra na etapa 8 de `agents/developer.md` exigindo que toda menção a "confirmado/autorizado pelo Diretor" declare O QUÊ foi confirmado (propriedade · autorização de execução · ambas)
reincidencia: 0
estado: ativa

## LRN-006: Critério de TASK que proíbe efeito fora da árvore de código sem oráculo mecânico
data: 2026-09-04
gatilho: gate_reprovado
origem: PLAN-006 (slug producao-material), Wave 1, TASK-006-001 — o "Não inclui"/risco (TRISK-006-001) proibia executar a migração fora do banco de teste descartável, mas nada na TASK media isso contra o estado real do banco; só apareceu porque o `code-reviewer`, por iniciativa própria, consultou `_prisma_migrations`
causa_raiz: instrucao_ausente — o catálogo de "resistir a contorno" de `commands/tasks.md` (etapa 3, fixação de critérios) cobre grep/estrutura/mutação/round-trip mas não a classe "critério proíbe efeito colateral fora da árvore de código (banco, fila externa, sistema de terceiros)"; nasce como promessa em prosa, não como oráculo executável sobre o alvo
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor)
patch: proposta de item novo no catálogo de fixação de `commands/tasks.md` exigindo que critério desse tipo nasça com o comando/query que lê o estado real do alvo externo, com o resultado esperado entrando no report do developer
reincidencia: 0
estado: ativa

## LRN-007: rótulo de retry (EMENDA/gate/Wave) na TASK migra para o código quando o despacho não diz que não deve
data: 2026-09-05
gatilho: gate_reprovado
origem: PLAN-006 (slug producao-material), Wave 3 — re-review do retry consolidado (gate 1-7) achou "EMENDA pós gate N (Wave 3)"/"retry Wave 3" em 19 pontos de código de produção, docblocks e nomes de teste; removido manualmente pelo Tech Lead (commits `6eccd54`/`e789c6d`) antes do fecho
causa_raiz: instrucao_ausente — o despacho do retry edita os Critérios de pronto da TASK rotulando-os "EMENDA pós gate N (Wave N)" para o próprio Tech Lead localizar o item, mas nada no despacho diz ao developer que esse rótulo identifica o critério no artefato e NÃO é para entrar no código — a âncora durável em comentário é sempre o AC/DEC/FR (Art. 7). `guidelines/core/CODE-REVIEW.md` §Convergência ("Narrativa de correção não entra no código") já cobre o lado do avaliador; o lado do gerador (`commands/implement.md` §3.3, ponto em que o rótulo nasce) não repete a distinção, e leitura literal do texto recebido foi razoável
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor)
patch: proposta de 2 frases em `commands/implement.md` §3.3 (parágrafo "Falha em qualquer gate"), logo após "narrativa de correção fica no report — nunca em comentário": (1) o rótulo do despacho (EMENDA/gate N/retry Wave M) serve só para localizar o critério na TASK e nunca migra para comentário/docblock/nome de teste — a âncora durável ali é o AC/DEC/FR (Art. 7); (2) o report do developer inclui grep de fechamento sobre o próprio delta antes de reportar Done
reincidencia: 0
estado: ativa

## LRN-008: contrato de BRIEF avulso não força reconciliar premissa refutada pela própria execução
data: 2026-09-05
gatilho: gate_reprovado
origem: BRIEF-007 (slug producao-material) — a investigação REFUTOU a premissa que originou o brief (não havia vulnerabilidade em produção: `verifyOrigin` já estava em `POST /auth/refresh` desde F1, commit `d2560a9`), mas o brief e o assunto do commit seguiram afirmando a premissa refutada até o Tech Lead reconciliar só o INDEX; pego pelo `code-reviewer` no gate 1-7
causa_raiz: instrucao_ausente — o contrato do BRIEF avulso (`docs/_meta/conventions/index-contract.md`, "Variação avulsa") trata "Pedido como dito"/"Interpretação" como registro fixado na abertura e não tem seção nem passo que force reconciliar quando a execução descobre que o diagnóstico estava errado; os Critérios de aceite ficam "satisfeitos" pelo estado final, então nada mecânico acusa e a premissa falsa sobrevive no artefato e no assunto do commit
artefato_patchado: proposta_doutrina (não aplicado) — `docs/_meta/conventions/index-contract.md`, esqueleto do BRIEF avulso ("Variação avulsa")
patch: brief cuja execução refuta a premissa do "Pedido como dito" ganha seção `## Resultado` (o "Pedido como dito" permanece intacto — é o registro do que foi dito) declarando: a premissa refutada, desde quando estava certo (com o SHA), e quais Critérios de aceite já eram satisfeitos antes do diff; regra companheira: o assunto do commit descreve o que o diff FAZ, nunca o que o brief supunha — `test:` quando nenhuma linha de produção muda, nunca `fix:`. Referência: BRIEF-007 (workspace `18a29e8`) + backend `9b2ddef` (amend `fix:`→`test:`)
reincidencia: 0
estado: ativa

## LRN-009: item (h) de `tasks.md` (molde citado como exemplar) só confronta contra `lessons.md`, não contra a doutrina já instituída pelo perfil
data: 2026-09-06
gatilho: gate_reprovado
origem: PLAN-010 (slug producao-material), Wave 2, TASK-010-002 — o gate 1-7 do `code-reviewer` reprovou a 1ª rodada por `createUser`/`createTopic`/`createRawContent` copiados byte-a-byte do irmão da wave anterior; a TASK mandava, em "Escopo > Inclui", "usar o padrão de fixture de `contents.service.integration.test.ts` (createUser/createTopic/testPrisma direto)" — o developer cumpriu à risca e produziu a cópia que o gate reprova, custando 1 retry
causa_raiz: instrucao_ausente — o item (h) da Etapa 3 (`commands/tasks.md`, decisão 4.307) já obriga confrontar arquivo citado como molde/exemplar contra toda lição `Estado: ativa` de `lessons.md` antes de virar instrução de cópia, mas não estende a mesma confrontação à doutrina **já instituída pelo perfil de linguagem** (não uma lição emergente): a TASK citou um ENDEREÇO (arquivo de teste com fixture local) onde a cláusula "Fixtures compartilhadas" do perfil (`guidelines/project/backend/node-22.md` §7, Art. 3) pede uma CONDIÇÃO (helper único exportado em `tests/support/`) — o artefato instruiu exatamente o que o gate reprova, sem que nada no gerador confrontasse o molde contra essa cláusula
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor)
patch: proposta de extensão do item (h) em `commands/tasks.md` (Etapa 3, "resistir a contorno") — molde citado como padrão também se confronta, antes de virar instrução de cópia, contra a doutrina de teste já instituída pelo perfil de linguagem ativo (não só contra `lessons.md`); molde cujo conteúdo diverge dessa doutrina (ex.: fixture local em vez do helper canônico de `tests/support/`) não sustenta "seguir o padrão de X" — o item passa a citar/mandar criar o helper canônico, nunca aponta a função local como molde de cópia
reincidencia: 1
estado: ativa

**Atualização 2026-09-06 (reincidência 1, achada pelo code-reviewer em modo convergência de fecho)**:
a Wave 3 (TASK-010-003) duplicou o MESMO padrão de novo — `contents.service.integration.test.ts`
usa fixtures locais pré-existentes (não o helper `tests/support/production-events-fixtures.ts`
criado no retry da Wave 2) porque o Escopo>Inclui de TASK-010-003 já estava escrito citando
"fixture já em uso no arquivo" ANTES de a lição existir. Causa adicional: rotear a lição corrige
o artefato de processo (`tasks.md`) para o PRÓXIMO ciclo, mas não toca as TASKs já escritas das
waves seguintes do MESMO PLAN — o developer da wave seguinte segue a instrução à risca e reverte
na prática o que o retry anterior consolidou. Extensão do patch proposto: quando um retry produz
`licao_candidata` sobre a INSTRUÇÃO de uma TASK (molde citado, padrão a seguir), o fecho da wave
(régua do `/keelson:implement`, §3.6 item 7 "Refino das waves seguintes") confronta as TASKs
PENDENTES do mesmo PLAN contra a mesma condição antes do despacho da próxima wave — e corrige o
Escopo>Inclui delas, citando o artefato novo em vez do molde superado. Não bloqueou a Entrega
(dedup registrado como pendência de consolidação, não gap) — mas é a mesma causa-raiz, 2ª vez
no mesmo PLAN.

## LRN-010: esqueleto de brief avulso não pede declarar oráculo quando o critério central só é verificável pós-deploy
data: 2026-09-06
gatilho: gate_reprovado
origem: BRIEF-010 (slug producao-material) — mudança avulsa no `mnemonicos-backend`
(`vercel-build` passa a rodar `prisma migrate deploy`); o `code-reviewer` (gate 1-7) achou que a
rodada local (lint, typecheck, 217 testes) fechou verde sem exercitar a mudança, porque o
critério central ("o build passa a aplicar as migrações") só tem oráculo no deploy real contra
um Postgres — que o próprio brief proíbe tocar durante a execução
causa_raiz: instrucao_ausente — o esqueleto de "Variação avulsa" (`docs/_meta/conventions/index-contract.md`)
pede só "<observável e verificável>" no Critério de aceite, sem distinguir o caso em que o único
oráculo é o efeito do deploy (config lida em build/runtime de produção, script de infra, env do
painel); quem preenche o brief (Tech Lead) segue o esqueleto à risca e não é levado a declarar
essa lacuna nem a nomear a verificação pós-deploy — gates verdes locais provam ausência de
regressão, e essa concordância foi confundida com verificação até o gate 1-7 apontar
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor) —
`docs/_meta/conventions/index-contract.md`, esqueleto "Variação avulsa" § Critério de aceite
patch: proposta de expansão do comentário-placeholder do bullet "## Critério de aceite" — quando
o oráculo central só existe pós-deploy, o brief nomeia ali a verificação observável que o fecha;
sem ela, o fecho da rodada não reporta Done, reporta PARCIAL
reincidencia: 0
estado: ativa

## LRN-011: esqueleto de brief avulso não tem seção formal para "risco aceito", e a captura em prosa livre omite custo de recuperação
data: 2026-09-06
gatilho: gate_reprovado
origem: BRIEF-010 (slug producao-material) — o `security-engineer` (gate 8) achou que o risco
aceito declarado pelo Diretor ("migração quebrada derruba o build — fail secure, o deployment
anterior segue servindo") registrou só a consequência otimista, omitindo que o estado FAILED em
`_prisma_migrations` (P3009, confirmado contra o engine instalado) trava TODOS os deploys
seguintes — inclusive hotfix de segurança — até `prisma migrate resolve --rolled-back` rodar à
mão contra produção
causa_raiz: instrucao_ausente — o esqueleto de "Variação avulsa" (`docs/_meta/conventions/index-contract.md`)
não tem seção "Riscos aceitos": quem precisa registrar um risco aceito pelo Diretor improvisa
formato livre (como o BRIEF-010 fez), e prosa livre captura o evento sem forçar o custo de
recuperação nem quem pode executá-lo — risco "aceito" sem esses dois campos não é risco aceito,
é risco não medido
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor) —
`docs/_meta/conventions/index-contract.md`, esqueleto "Variação avulsa" (nova seção)
patch: proposta de seção opcional "## Riscos aceitos" no esqueleto — cada item com 3 campos:
consequência · custo de recuperação (comando/runbook + onde está documentado) · quem pode
executar; sem os três campos, o risco não está aceito
reincidencia: 0
estado: ativa

## LRN-012: critério composto por dois oráculos (grep de presença + grep de ausência) vira estruturalmente insatisfazível quando a correção do gate remove o artefato do oráculo de presença
data: 2026-09-06
gatilho: verificacao_falhou
origem: PLAN-012 (slug producao-material), Wave 1, TASK-012-003 — o code-reviewer (achado A1) determinou que o import citado pelo critério (item 5, "reuso de `rawContentIdParamSchema`") era re-export especulativo sem consumidor real e mandou REMOVÊ-LO; a metade do critério que checava "presença do import" ficou insatisfazível por desenho (o import não deve mais existir), enquanto a condição de domínio real ("não redeclara o parâmetro `:id`", 2º grep) seguia satisfeita — quase virou checkbox verde sobre critério de fato quebrado, só pego na convergência
causa_raiz: instrucao_ausente — o catálogo "resistir a contorno" (Etapa 3, `commands/tasks.md`, decisão 4.107 + família) não tem item cobrindo critério composto por 2+ sub-oráculos onde um deles verifica a PRESENÇA de um artefato de implementação (import/chamada específica) como proxy de conveniência para o invariante de domínio, em vez do invariante em si; a decisão 4.321 ("condição, nunca endereço") já cobre "arquivo nomeado de memória" (item citado na linha do critério de lint) e "consumidor citado de memória" (item d), mas nenhum item do catálogo nomeia a composição de sub-oráculos heterogêneos (um address-based, outro domain-based) nem o red flag de que correção legítima do próprio review pode invalidar o primeiro sem tocar o segundo
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor)
patch: proposta de item novo (j) no catálogo de "resistir a contorno" de `commands/tasks.md` (Etapa 3, mesmo parágrafo dos itens a–i): critério composto por 2+ sub-oráculos nomeia, para CADA sub-oráculo, o invariante de domínio que ele prova — nunca "existe o artefato X" como proxy; sub-oráculo cuja satisfação depende de artefato de implementação contingente é red flag na fixação, resolvido nomeando a condição que o artefato hoje satisfaz, nunca a presença dele
reincidencia: 0
estado: ativa

## LRN-013: Etapa 1 de `commands/auto.md` justapõe dois enums homônimos-na-forma (`edits|reescrita` do pacote de correção × `mecânico|julgamento` da revalidação) sem marcar que pertencem a réguas diferentes
data: 2026-09-06
gatilho: verificacao_falhou
origem: SPEC-013 (slug producao-material) — ao despachar o pacote de correção ao `scribe`, o Tech Lead declarou `modo: julgamento` (vocabulário de `validator-protocol.md` §4.5, revalidação) no campo que exige `modo: edits|reescrita` (vocabulário de `graph-contract.md` §4.1, pacote de correção); o `scribe` (`agents/scribe.md` passo 4) tratou o rótulo como fora do enum, re-derivou `reescrita` corretamente e declarou a divergência com motivo em `modo_aplicado` — nenhum dano, mas é a classe de ambiguidade de instrução que a Etapa 4.5 pede para rotear
causa_raiz: instrucao_ambigua — `commands/auto.md`, Etapa 1 (linha do "pacote de correção", em torno da l.77 da v0.156.0), descreve as duas réguas no MESMO parágrafo, em sequência direta: primeiro o `modo:` do pacote de correção (`graph-contract.md` §4.1), depois "a revalidação que se segue obedece `validator-protocol.md` §4.5: ramo mecânico ... para julgamento" — os rótulos "mecânico"/"julgamento" aparecem span da fôlego de uma frase de distância do `modo:` que na verdade é `edits|reescrita`, sem nada no texto que avise "são enums diferentes, não confunda o vocabulário de um com o do outro"; leitura corrida do parágrafo é o bastante para transpor o rótulo errado. `agents/scribe.md` passo 4 já é explícito (nomeia o enum certo) — o ponto de leitura que falhou é o do orquestrador (`auto.md`), não o do scribe.
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor)
patch: proposta de inserção in-line em `commands/auto.md` Etapa 1, logo após a citação de `graph-contract.md` §4.1: parêntese nomeando o enum (`edits|reescrita`, sobre a FORMA da edição) e alertando para não confundir com o `mecânico|julgamento` da frase seguinte (revalidação, régua distinta) — saldo 0 (mesma linha, mais caracteres)
reincidencia: 0
estado: ativa

## LRN-014: `parselist()` de `scripts/graph.sh` fatia a lista por vírgula ANTES de remover a anotação parentética — vírgula interna ao parêntese quebra o campo inteiro e produz falso-positivo em cascata
data: 2026-09-06
gatilho: verificacao_falhou
origem: PLAN-013 (slug producao-material), validação do PLAN — o `scribe` escreveu, no campo `Realiza` de COMP-013-003, anotação legítima e tolerada por desenho (comentário nas l.106-107 da própria função) `NFR-013-008 (não participa de requisição de API/HTML autenticado, logo não pode alterar login/renovação/logout)`; a vírgula dentro do parêntese fragmentou o token no `split(val, arr, ",")` (l.103) antes de `sub(/[ \t]*\([^)]*\)$/, "", t)` (l.108) — que só casa parêntese fechando no FIM do token — ter chance de agir; nenhum fragmento bateu `^(FR|NFR)-[0-9]+-[0-9]+$`, `parselist` devolveu 0 (`TN=0`), o campo inteiro virou `nao-parseavel` e o check `realiza-vs-mapeamento`, sem nenhum ID reconhecido no campo, reportou TODOS os FR/NFR do componente como "só na §7" — divergência total falsa mascarando conteúdo correto. Diagnosticado pelo Tech Lead comparando com bug irmão já remediado (ad hoc, sem entrada neste ledger) em PLAN-010: lista "NFRs cobertos" quebrada por continuação de linha sem bullet própria — mesma função, mesma fragilidade de tokenização, dois sintomas de formatação-livre diferentes
causa_raiz: verificador_furado — o check mecânico (`parselist`, dono de `realiza-vs-mapeamento` e de todo check que lê campo de lista de ID) tem ordem de operação errada: split ingênuo por vírgula antes de reconhecer a anotação parentética que a própria função já tolera por contrato: nenhuma instrução ao `scribe` preveniria isso sem proibir prosa livre legítima dentro do parêntese (o que o comentário da l.106-107 explicitamente autoriza) — o defeito é do parser, não do texto gerado
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor) — `scripts/graph.sh`, função `parselist()` (l.97-115)
patch: proposta de função auxiliar `splitlist(val, arr)` que tokeniza respeitando profundidade de parênteses (incrementa em `(`, decrementa em `)`, só separa em `,` quando profundidade 0) substituindo `n = split(val, arr, ",")` (l.103) por `n = splitlist(val, arr)`; o restante de `parselist` (trim, remoção de anotação, validação por `typere`) fica intacto — saldo líquido ~+10 linhas (função nova pequena)
reincidencia: 0
estado: ativa

## LRN-015: fechamento contável de predicado de CONJUNTO instanciado por "método que toca", não por eixo discriminável do próprio predicado
data: 2026-09-06
gatilho: gate_reprovado
origem: PLAN-012 (slug producao-material), Wave 3, TASK-012-006 — o code-reviewer achou (bloqueante) que o critério de pronto de `isExactFrameSet` (`mnemonicos-backend/src/modules/tira/tira.service.ts:266-279` — conjunto: `order` tem exatamente os ids da Tira, nem falta nem sobra nem duplicidade) fechou contando "1 método nesta TASK → 1 prova" em vez dos eixos do próprio predicado; a TASK enumerava 2 casos concretos (id de outra Tira; duplicata) e o developer entregou exatamente esses 2 — o 3º eixo (cardinalidade: id faltando, subconjunto estrito sem duplicata) ficou sem prova. Confirmado por mutação real (manual — `quality.mutation` é `null` nesta ficha, sem ferramenta instalada): remover `order.length === existingIds.size` do código deixa a suíte inteira verde, embora o serviço passe a aceitar reordenação parcial silenciosamente
causa_raiz: instrucao_ausente — o item (c) do catálogo "resistir a contorno" (`commands/tasks.md`, Etapa 3, decisões 4.139/4.232) já nomeia fechamento contável, mas só para predicado de **escopo** (tenant/dono/agregado pai), com denominador "quem toca a tabela escopada"; nenhum item do catálogo nomeia a classe irmã — predicado de **conjunto** (`&&` de condições de cardinalidade/multiplicidade/pertencimento, sempre três por construção), cujo fechamento certo é por EIXO do predicado, não por método/chamada que o toca. Como a TASK já trazia 2 casos nomeados e concretos, a lista parecia exaustiva — o developer a cumpriu à risca e nada no gerador acusou o eixo ausente. Lição-irmã de projeto já registrada em `guidelines/project/lessons.md` ("[Testes] Predicado de conjunto composto por && exige um caso por EIXO discriminável") cobre o developer; esta entrada cobre o gerador da TASK (`/keelson:tasks`), que é quem deveria ter fixado o 3º caso antes do código
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor) — `commands/tasks.md`, catálogo "resistir a contorno" (Etapa 3, mesmo parágrafo dos itens a–i, linha ~273 da v0.156.0)
patch: proposta de item novo no catálogo (letra a atribuir pelo mantenedor — item (j) já está em disputa com a proposta pendente de LRN-012; esta pode ficar (j) ou (k) conforme a ordem de aplicação): AC cujo predicado de aceite é um predicado de CONJUNTO (a coleção é exatamente um conjunto-alvo) fecha por fechamento contável sobre os EIXOS do próprio predicado — cardinalidade (falta elemento), multiplicidade (duplicidade), pertencimento (elemento estranho), sempre três por construção — nunca por "N métodos que tocam → N provas" (isso mede superfície de chamada, não exaustão do predicado); lista de casos concretos no Escopo nunca substitui a checagem dos três eixos, ainda que pareça exaustiva
reincidencia: 0
estado: ativa

## LRN-016: `probe-env.sh` mascara falha de leitura/encoding de `keelson.local.json` como `credencial_ausente`
data: 2026-09-07
gatilho: verificacao_falhou
origem: PLAN-013 (slug producao-material), TASK-013-005, gate 9 — o `qa` (modo screen-verify) achou que `scripts/probe-env.sh` abre `keelson.local.json` com `open(path)` sem `encoding='utf-8'` explícito; no Windows isso cai no encoding padrão do console (cp1252), que não decodifica o conteúdo pt-BR acentuado do arquivo — o `UnicodeDecodeError` cai no `except Exception` genérico e o script devolve `causa=credencial_ausente`, indistinguível de "arquivo realmente ausente/vazio"
causa_raiz: verificador_furado — o script (o próprio verificador do gate 9) tem bug de implementação em dois pontos: (1) abre o arquivo sem encoding explícito, dependente do locale do SO; (2) o branch `except Exception` colapsa QUALQUER falha de leitura (encoding, JSON malformado, permissão) na mesma causa nomeada de "credencial ausente" — nenhuma instrução ao gerador preveniria isso, o defeito é do parser/leitor, não de texto ambíguo
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor) — `scripts/probe-env.sh`, leitor Python embutido (~l.68-124) + comentário de cabeçalho (~l.19)
patch: abrir com `encoding="utf-8"` explícito; separar `UnicodeDecodeError` do `except Exception` genérico, imprimindo tag `ENCODING` distinta de `PARSE`; novo branch `ENCODING)` no `case "$kind"` devolvendo `causa=arquivo_ilegivel` (não `credencial_ausente`); comentário de cabeçalho (l.19) ganha o novo valor no enum de causa — saldo líquido ~+7 linhas
reincidencia: 0
estado: ativa

## LRN-017: `probe-env.sh` não distingue realm público por contrato de credencial pendente de preencher — ambos batem em campo vazio
data: 2026-09-07
gatilho: verificacao_falhou
origem: BRIEF-015 (slug producao-material, brief avulso) — o `qa` (gate 9) sondou o realm `app` de `keelson.local.json` (workspace mnemonicos), declarado "Hoje é pública" na própria `description`, com `username`/`password` `null` por desenho (ainda sem tela de login); `probe-env.sh` devolveu `causa=credencial_placeholder` e bloqueou a sondagem mecânica de um fluxo cujo AC não exige login — o `qa` contornou manualmente com `curl`/Playwright MCP direto, o que o AC de fato pedia (visitante anônimo)
causa_raiz: verificador_furado — a função `flag()` do leitor Python embutido (~l.94-103) e o `bad`-check em bash (~l.136-139) tratam TODO campo `username`/`password` vazio como a mesma coisa: não existe, no schema nem no script, um jeito de um realm declarar "não tenho autenticação por contrato" distinto de "tenho autenticação, mas a credencial ainda não foi preenchida" — os dois estados colapsam em `causa=credencial_placeholder`; nenhuma instrução ao gerador de `keelson.local.json` preveniria isso, o defeito é de esquema/leitor (mesmo artefato de LRN-014 — `probe-env.sh` —, mas bug distinto: LRN-014 é sobre exceção de leitura/encoding ANTES do parse do realm; este é sobre a semântica de um realm já parseado com sucesso, código diferente do mesmo script)
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor) — `scripts/probe-env.sh` (leitor Python ~l.94-103 + bad-check bash ~l.136-143), `templates/keelson.local.example.json`, `docs/wiki/Ficha-do-projeto.md` (tabela de campos, ~l.251-258)
patch: proposta de campo opcional `"auth": false` no realm (marcador explícito de "sem autenticação por contrato"); o leitor Python passa a computar `uflag`/`pflag` como `"semauth"` quando `auth is False`, sem chamar `flag()` sobre `login.username`/`login.password`; o bad-check em bash trata `"semauth"` como equivalente a `"ok"` (não bloqueia); default (`auth` ausente) preserva o comportamento atual — falha fechada, nunca assume público sem marcador explícito; template e wiki documentam o novo campo. Saldo líquido estimado: ~+9 linhas em `probe-env.sh` (dentro do orçamento ≤10), +3 no template, +1 na tabela do wiki
reincidencia: 0
estado: ativa

## LRN-018: item (c) do catálogo "resistir a contorno" de `commands/tasks.md` já exige fechamento contável para predicado de escopo, mas não proíbe nomeadamente "estrutural"/"já provado — não duplicar" como resposta
data: 2026-09-07
gatilho: gate_reprovado
origem: PLAN-012 (slug producao-material), Wave 4, TASK-012-007 — o "Critério de pronto" prescreveu, para AC-011-020/AC-011-022 nas 3 novas funções de escrita (`addMnemonicFrame`/`updateMnemonicFrameText`/`removeMnemonicFrame`), prova apenas ESTRUTURAL do alcance por autoria — "(parte — estrutural)" + "a prova comportamental completa já foi feita em TASK-012-005 — não duplicar" —, exatamente a justificativa que a lição ativa de `guidelines/project/lessons.md` ("[Segurança] Guarda reusada continua exigindo prova comportamental própria por novo método de escrita", nascida na wave ANTERIOR do MESMO PLAN) já refuta. O developer cumpriu o card à risca e entregou 3 pontos de escrita com alcance por autoria não falsificável — achado do `security-engineer` (gate 8), 1 retry inteiro
causa_raiz: instrucao_ausente — o item (c) da Etapa 3 (`commands/tasks.md`, decisões 4.139/4.232) já obriga fechamento CONTÁVEL de predicado de escopo ("N métodos no Escopo, N provas", denominador = quem toca a tabela) e já proíbe "lista de instâncias", mas nunca nomeia — nem proíbe explicitamente — o par de frases que vira a evasão real: "estrutural (parte)" e "já provado em TASK anterior — não duplicar" como fechamento válido para o predicado de ALCANCE POR AUTORIA especificamente; a TASK espelhou o critério da TASK anterior (que a lição já tinha corrigido) e nada no gerador confrontou essa herança contra a lição `ativa` antes de fixar o card — mesma classe do parágrafo "cruze o Escopo>Inclui contra lessons.md" (linha ~278), que existe mas não impediu a 2ª ocorrência dentro do próprio `lessons.md` do projeto
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor) — `commands/tasks.md`, item (c) do catálogo "resistir a contorno" (Etapa 3, mesmo parágrafo dos itens a–i)
patch: proposta de extensão in-line do item (c), logo antes do ponto-e-vírgula que abre o item (d): "; e esse fechamento nunca aceita \"estrutural\" nem \"já provado em TASK anterior — não duplicar\" como resposta — método NOVO que toca o dado escopado soma ao numerador mesmo quando reusa guarda de outro módulo, e numerador congelado no denominador de uma TASK anterior é o critério quebrado, não a exceção" — saldo 0 (mesma linha lógica, só mais texto)
reincidencia: 0
estado: ativa

## LRN-020: item (d) do catálogo "resistir a contorno" de `commands/tasks.md` cobre o comando de verificação da própria TASK, mas não a fixação de "Escopo > Não inclui" que declara consumidor cross-repo como trabalho de wave futura
data: 2026-09-13
gatilho: gate_reprovado
origem: PLAN-023 (slug producao-material), Wave 1, TASK-023-005 (decomposição de `/keelson:tasks`, rota fan-out) — o "Escopo > Não inclui" declarou a extensão de `mnemonicos-backend/tests/unit/tira-frontend-contract.test.ts` como trabalho futuro de TASK-023-017 (wave posterior), mas esse teste já existia (mergeado desde TASK-012-011), já lia as duas fontes (`tira.service.ts` e `mnemonicos-frontend/src/types/domain.ts`) e já guardava exatamente o campo alterado (`MnemonicFrame`/`MnemonicFrameDetail`) — a suíte do backend ficou vermelha ao fim da Wave 1 por um commit do frontend, invisível a cada developer (cada um só roda a suíte do próprio repo); só o gate 1-7 (code-reviewer) sobre o diff acumulado da wave achou. Corrigido por retry (commit `84b1f08`, campo trazido ao backend na mesma wave)
causa_raiz: instrucao_ausente — item (d) da Etapa 3 (`commands/tasks.md`, decisões 4.162/4.369) já obriga varredura por grep dos consumidores conhecidos de um símbolo/arquivo compartilhado alterado, mas só para o COMANDO DE VERIFICAÇÃO da própria TASK que altera o símbolo; nenhuma cláusula estende a mesma varredura ao momento de FIXAR "Escopo > Não inclui" — decidir que uma rede de paridade é trabalho de wave futura sem primeiro grepar se algum teste de contrato/paridade JÁ EXISTENTE lê o símbolo hoje. A pergunta feita foi "qual TASK escreve o teste de paridade deste campo novo?"; a que faltou foi "qual teste já existente passa a ler este campo no instante em que ele nasce?"
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor) — `commands/tasks.md`, item (d) do catálogo "resistir a contorno" (Etapa 3, mesmo parágrafo dos itens a–i)
patch: proposta de extensão in-line do item (d), logo após a citação da decisão 4.369 ("5 consumidores redigidos de memória contra 16 achados pela varredura"): "; a mesma varredura vale ao FIXAR 'Escopo > Não inclui' — antes de declarar um teste de paridade/contrato (`*-contract.test.ts`, `*-parity.test.ts`, ou equivalente do perfil) como trabalho de wave futura, `grep -rln` pelo símbolo/interface alterado sobre os testes de contrato já existentes: todo teste que JÁ lê o símbolo entra na MESMA TASK e MESMA wave — nunca é adiado por suposição de que ainda não existe cobertura" — saldo líquido ~+3 linhas (mesmo parágrafo, dentro do orçamento ≤10)
reincidencia: 0
estado: ativa

## LRN-019: régua-mãe "condição, nunca instância" (4.321/4.109 de `CODE-REVIEW.md`) não nomeia "elemento composto por um componente" (árvore de render/JSX) como classe sujeita a fechamento contável
data: 2026-09-07
gatilho: gate_reprovado
origem: PLAN-012 (slug producao-material), Wave 6, TASK-012-012, 2ª re-review do code-reviewer — o achado 1 foi escrito como INSTÂNCIA ("o `<div>` do cabeçalho de `page.tsx` sem teste", o mutante específico recém-rodado) em vez de CONDIÇÃO ("todo elemento que o Server Component compõe tem ≥1 asserção que morre se ele sair", quantificador já presente na EMENDA/DEC-012-011). O developer cumpriu a instância à risca (1 teste, só o cabeçalho); um 2º elemento composto (`<MnemonicStripBoard/>`) ficou sem prova, mutante que remove a composição sobrevive à suíte inteira. Na 3ª rodada o próprio code-reviewer identificou isso como achado SEU, não do developer: "a régua não é do developer: é de quem escreve o achado". Efeito colateral: o achado citava um exemplar (`rule-breakdown-form.test.tsx:410-425`) como molde de correção — molde que já continha a 2ª asserção que fecharia o buraco — e nem o retry nem o re-review conferiram o molde INTEIRO contra a cópia
causa_raiz: instrucao_ausente — a "régua-mãe" (`guidelines/core/CODE-REVIEW.md`, decisão 4.321) já exige achado por condição de domínio, nunca instância, "em qualquer ponto do ciclo" — e a decisão 4.109 (mesmo arquivo) já cobre fechamento contável para requisito MUST multi-sujeito ("N chamadores, N respostas") — mas nenhuma das duas nomeia explicitamente a classe irmã "elemento que um componente COMPÕE" (árvore de render/JSX, agregação visual): o achado nasceu do mutante que o revisor tinha acabado de rodar, não do quantificador do requisito de origem, porque nada na régua aponta esse eixo como instância do mesmo padrão — e nada cobre a obrigação companheira de conferir um molde citado por INTEIRO, não só nomeá-lo
artefato_patchado: proposta_doutrina (não aplicado) — `guidelines/core/CODE-REVIEW.md`, extensão da família 4.321/4.109 (inserção após a l.585 da v0.156.0, antes de "A mesma enumeração-na-fonte...")
patch: proposta de parágrafo novo: achado de ausência de prova sobre elemento que um componente COMPÕE (árvore de render/JSX, agregação visual) segue o mesmo "condição, nunca instância" por eixo próprio — nomeia a condição do domínio ("todo elemento que o componente compõe tem ≥1 asserção que morre se sair"), nunca o elemento específico revelado pelo mutante; fechamento contável (N elementos compostos, lidos do PRÓPRIO componente — não do mutante — → N asserções mortais); lista de elementos hoje sem prova é ilustração não-exaustiva. E quando o achado cita um exemplar/molde como referência de correção, retry e re-review conferem o molde INTEIRO contra a cópia entregue — molde citado e parcialmente copiado é ponto cego comum a quem escreve e a quem revisa o retry. Saldo estimado: +1 parágrafo (~4-6 linhas conforme wrap do arquivo, dentro do orçamento ≤10)
reincidencia: 0
estado: ativa

## LRN-021: `scripts/artifact-lint.sh` compara `tolower()` contra literal UTF-8 embutido ("então"/"não"/`\303\243`) sob `LC_ALL=C` — em gawk/Windows, `tolower()` corrompe byte ≥0x80 e a comparação nunca casa
data: 2026-09-13
gatilho: validator_error
origem: ciclo `/keelson:auto` de F5 (slug producao-material), ambiente Windows — validação de SPEC-022 (14 ACs) e PLAN-023 (12 DECs); ambos os falsos positivos confirmados por teste isolado (`awk 'BEGIN{print tolower("então")}'` corrompe) e por leitura manual do conteúdo real
causa_raiz: verificador_furado — o script exporta `LC_ALL=C` (l.28, comentário l.25: "Bash 3.2 + awk POSIX, sem dependências novas") e depois, em 2 checks, chama `tolower()` sobre texto pt-BR ANTES de comparar contra um literal UTF-8 embutido no próprio script: (1) `spec-ac-fora-gwt` monta `acbuf = tolower(line)` (bloco SPEC, l.173/176) e o `flushac()` (l.254) busca `"ent\303\243o"` — bytes intactos — dentro de `acbuf` já corrompido; (2) `plan-dec-irreversivel-enum` (bloco PLAN, l.338) faz `lv = tolower(v); gsub(/\303\243/, "a", lv)` — a ORDEM inverte o que o comentário `# ã→a` promete: o gsub normalizador roda DEPOIS do tolower já ter corrompido o byte, nunca casa. Neste ambiente (gawk + Windows, build cujo `tolower()` corrompe byte ≥0x80 sob locale C), os dois checks reprovam qualquer SPEC/PLAN com "então"/"não"/"ação" nas seções verificadas — nenhuma instrução ao gerador (SPEC/PLAN bem formados) preveniria; o defeito é do parser. Varredura adicional (pedida pelo relato) achou o MESMO padrão em mais 2 sítios do bloco TASK, ainda não sintomáticos porque o texto de teste não bateu neles ainda: os 2 checks da família 4.215 ("--group" sem negação / com negação, l.539 e l.558) fazem `lline = tolower(line)` e depois checam `index(lline, "não")` — mesmo padrão tolower-antes-do-literal-UTF-8, mesma corrupção esperada em texto pt-BR com "não" acentuado. Mesma classe de LRN-014/016/017 (verificador_furado em script do plugin — `graph.sh`/`probe-env.sh`), causa distinta: aqui é corrupção de byte por `tolower()` sob `LC_ALL=C`, não tokenização ingênua nem exceção de encoding não distinguida
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor) — `scripts/artifact-lint.sh`, blocos awk SPEC (l.173, l.176 — check `spec-ac-fora-gwt`/`flushac`), PLAN (l.338 — check `plan-dec-irreversivel-enum`) e TASK (l.539, l.558 — checks 4.215 "--group")
patch: proposta de função `lc_safe(s)` (lowercase ASCII-only — só rebaixa byte no intervalo 'A'-'Z', nunca toca byte ≥0x80, então nunca corrompe sequência UTF-8 multibyte) duplicada nos 3 blocos awk logo após cada `function trim(s) {...}` (mesmo padrão de duplicação que o arquivo já usa para `trim`/`emit` — os 3 blocos são programas awk independentes); os 5 call-sites (l.173, l.176, l.338, l.539, l.558) trocam `tolower(...)` por `lc_safe(...)`, sem mais nenhuma mudança de lógica — saldo líquido ~+3 linhas (1 linha de função por bloco; as 5 substituições de token são saldo 0)
reincidencia: 0
estado: ativa

## LRN-022: despacho do retry (`commands/implement.md` §3.3) transcreve o COMANDO de varredura citado no achado original como ilustração, não como critério de pronto — só o endereço nomeado fecha
data: 2026-09-13
gatilho: gate_reprovado
origem: PLAN-023 (slug producao-material), Wave 3, TASK-023-008 — 2 manifestações na mesma rodada de retry: (1) o achado de DRY (gate 7) citou a redução de 2 fixtures duplicadas de `VisualAssociation`; o despacho fechou a 1ª re-derivação de `loadEnvModule` em `env.test.ts` (o endereço ilustrado no achado) e a 2ª, no MESMO arquivo, sobreviveu ao retry — só caiu no re-review seguinte; (2) a varredura de comentários da mesma rodada fechou os 6 endereços citados e um 7º da mesma classe (`routes.ts:18`) permaneceu, também só achado no re-review. Fechado por verificação final do code-reviewer (APROVADO) após as 2 rodadas de REPROVADO
causa_raiz: instrucao_ausente — a régua já existente em `commands/implement.md` §3.3 ("Cada item do despacho do retry nasce com o PAR de provas", decisão 4.302) e a lição companheira de projeto (`guidelines/project/lessons.md`, "[Código] Correção de duplicação (DRY)...", "varrer o próprio delta pela mesma condição antes de despachar/commitar") já apontam a disciplina certa, mas nenhuma das duas é VERIFICÁVEL no momento do despacho: quando o achado cita exemplos concretos como ilustração de uma classe, o despacho os transcreve como se fossem a lista fechada, e o revisor só descobre a sobra no re-review seguinte — o comando de varredura que provaria exaustão nunca vira critério de pronto do item despachado
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor) — `commands/implement.md` §3.3, parágrafo "Falha em qualquer gate" (linha da decisão 4.302, "Cada item do despacho do retry nasce com o PAR de provas")
patch: proposta de extensão in-line, logo após a frase da decisão 4.302 ("...deixa a regressão do lado benigno nascer exatamente no conserto."): achado que nomeia uma CLASSE (grep/padrão a variar) leva o COMANDO de varredura para o despacho como critério de pronto, não como ilustração; o developer devolve, no campo `verificacao` do report, a linha `varredura: <comando> → <saída>` (vazia, ou cada hit remanescente justificado) ao lado do diff, e o revisor re-executa o mesmo comando no re-review antes de aprovar — saldo líquido ~+6 linhas (dentro do orçamento ≤10)
reincidencia: 0
estado: ativa

## LRN-023: "Achado só-texto não reabre o ciclo" dispensa gates 1/2/9 pela ORIGEM do achado (rotulado mecânico/degrau 1), não por conferência mecânica do delta entregue
data: 2026-09-14
gatilho: gate_reprovado
origem: PLAN-023 (slug producao-material), Wave 4 — um retry foi tratado como "mecânico"
(degrau 1) pela origem do achado que o motivou e dispensou os gates 1/2 (cobertura + prova),
mas o delta efetivamente entregue introduzia função/predicado/branch novo, não só texto; o
revisor propôs regra de bolso (`git diff <sha>..<sha> | grep -c '^+.*function '` > 0 implica
delta não-mecânico) para a rodada seguinte
causa_raiz: instrucao_ausente — o bullet "Achado só-texto não reabre o ciclo"
(`guidelines/core/CODE-REVIEW.md`, Gate 7/Convergência do re-gate, ~l.489-492 da v0.156.0)
dispensa gates 1/2/9 quando o delta da correção é "inerte" (comentário/docblock/doc), mas
nada no texto exige CONFERIR MECANICAMENTE o delta entregue antes de dispensar — a
classificação observada nasceu da origem do achado (rotulado mecânico), não de uma conferência
sobre o que o retry de fato mudou; é a mesma classe de risco já nomeada alhures no arquivo
("quem está no meio dos retries tem exatamente o incentivo de classificar o restante como
'mecânico' para não escalar", ~l.448), mas aplicada aqui à dispensa de gates, não à escalação
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor) —
`guidelines/core/CODE-REVIEW.md`, bullet "Achado só-texto não reabre o ciclo" (~l.489-492 da v0.156.0)
patch: proposta de inserção in-line — dispensa de gates 1/2/9 por "achado só-texto" exige
conferência mecânica do delta ANTES de aplicar (nunca da origem/rótulo do achado): diff do
delta entregue, restrito aos arquivos do achado, sem linha `^+` que declare função/predicado/
branch novo (proxy: `grep -c '^+.*\(function\|=>\|if \|switch\)'`); delta que falha a
conferência não é só-texto — gates 1/2 (cobertura + prova) se aplicam como em qualquer TASK
normal, mesmo quando o achado que motivou a correção foi classificado mecânico — saldo
líquido ~+4 linhas
reincidencia: 0
estado: ativa

## LRN-024: inventário Art. 7 (narrativa de processo/proveniência) fecha por ocorrências pontuais vistas na rodada, não pela CLASSE inteira no delta acumulado da wave
data: 2026-09-14
gatilho: gate_reprovado
origem: PLAN-023 (slug producao-material), Wave 4 — o inventário de comentários com narrativa
de processo/proveniência (Art. 7) fechou com uma lista pontual de ocorrências vistas na
rodada; parte da mesma classe (grep amplo por `code-reviewer|re-review|Wave [0-9]|achado|
gate [0-9]`) não fazia parte do delta desta wave (pré-existente) e parte fazia — sem separar
os dois por `git blame`, o resíduo real da wave ficou fora da lista e migrou para a rodada de
fecho seguinte
causa_raiz: instrucao_ausente — o bullet "Comentários (Art. 7)" (`guidelines/core/CODE-REVIEW.md`,
Gate 7, l.188-196 da v0.156.0) já exige inventário CONTÁVEL dos comentários que o diff
introduz/altera (decisão 4.250, escada 4.149), mas não instrui a varredura pela CLASSE
inteira sobre o delta ACUMULADO da wave, nem a separar por `git blame` o que a wave introduziu
do que é pré-existente — sem essa varredura ampla, o revisor lista só as ocorrências que viu
na rodada, e o resíduo da mesma classe migra para o fecho seguinte; a mesma falha geral já
está nomeada em "Achado de classe fecha com a varredura como entregável" (decisão 4.173,
~l.453-460), mas nunca aplicada nomeadamente a este bullet
artefato_patchado: proposta_plugin (não aplicado — modo consumidor; ver mensagem_mantenedor) —
`guidelines/core/CODE-REVIEW.md`, bullet "Comentários (Art. 7)" (Gate 7, l.188-196 da v0.156.0)
patch: proposta de extensão in-line, logo após "decisão 4.250, escada 4.149": inventário de
narrativa de processo/proveniência varre a CLASSE inteira sobre o delta ACUMULADO da wave
(não só o diff da rodada), por grep amplo (`code-reviewer|re-review|Wave [0-9]|achado|
gate [0-9]`, ou equivalente do domínio do artefato) separando por `git blame` o que a wave
introduziu do que é pré-existente (fora de escopo do achado); lista de ocorrências pontuais
sem essa varredura não fecha o achado — mesma régua da decisão 4.173, aplicada nomeadamente
a este bullet — saldo líquido ~+5 linhas
reincidencia: 0
estado: ativa
