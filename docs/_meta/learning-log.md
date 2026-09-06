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
