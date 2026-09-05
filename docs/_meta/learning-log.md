# Ledger de aprendizado do processo

> Mantido pelo agent `agile-coach`. Não editar manualmente (exceto revisão humana de uma entrada).
> Só erro de PROCESSO entra aqui; lições de código/projeto → `guidelines/project/`.
> Entradas nunca são apagadas; no máximo marcadas `estado: destilada`.

## LRN-001: higiene da árvore na rodada de gates não é prova mecânica
data: 2026-08-31
atualizado: 2026-09-05
gatilho: retry
origem: PLAN-003 (slug producao-material, épico MNEMORA STUDIO F1) — Waves 4, 5, 6, 7; reincidência em PLAN-006 (mesmo slug), Wave 2, retry de TASK-006-005
causa_raiz: instrucao_ausente — gates paralelos sobre worktree compartilhado deixaram rastro (sonda `zz-*.test.*`, `npm install`/`ci` mexendo lockfile e podando deps, worktree órfão `.review-wt` com `.env` real, mutante de elevação de privilégio vivo, alteração estagiada invertendo oráculo); a decisão 4.134 (`guidelines/core/CODE-REVIEW.md` §Orquestração) só barra concorrência entre gates que **também mutam** e trata restauração como disciplina em prosa. A resposta parcial já incorporada na doutrina instalada (decisão 4.290 — "3ª camada da família 4.134/4.276": captura `git rev-parse HEAD` + `git status --porcelain` na largada de cada gate e reconfere antes do veredito) só enxerga **estado rastreado por git** — `node_modules`/cache de build são gitignored e ficam cegos a essa prova. Reincidência (PLAN-006 Wave 2): worktree isolada linkou `node_modules` por **junção NTFS** (Windows, vínculo FÍSICO, não lógico) para evitar `npm install`; processos node/esbuild remanescentes de rodada anterior mantinham handle aberto sobre arquivo nativo dentro do `node_modules` REAL (alvo da junção) e, ao remover a junção/limpar a worktree, corromperam a árvore PRINCIPAL — nada detectou porque git não vê `node_modules`. Recuperado com `npm ci` só depois de a suíte ser revalidada manualmente; nenhum mecanismo do processo exigia essa revalidação. Segundo sintoma da MESMA ambiguidade, na mesma rodada: o `code-reviewer` do re-review de delta rodou os próprios mutantes de verificação **na árvore principal** (não em worktree), justificando "não havia gate concorrente" — leitura literal possível do texto atual ("roda em `git worktree` isolada — nunca a mesma árvore de **outro gate concorrente** que também mute"), que lê a cláusula de não-concorrência como a condição que aciona o isolamento, não como reforço de um mandato já incondicional. Mitigado por disciplina em prosa (`git checkout --` + `git status --porcelain` a cada mutante) — a mesma classe de mitigação que a 4.290 já tentou tornar mecânica, agora reaparecendo por uma leitura textual diferente.
artefato_patchado: proposta_doutrina (não aplicado) — `guidelines/core/CODE-REVIEW.md` §"Orquestração da rodada", extensão da família 4.134/4.276/4.290
patch: consolida lições 1–3 do ciclo (Wave 4-7 de PLAN-003); estende 4.134 para "nunca concorrente com QUALQUER gate que leia a árvore ou a saída do runner", e adiciona prova mecânica (3 medições `git rev-parse --short HEAD` · `git status --porcelain` · `git diff HEAD` na abertura e no fecho, divergência = achado bloqueante) + reversão canônica `git restore --source=HEAD --staged --worktree -- <path>` (nunca `git checkout -- <path>`). **Escada de promoção (decisão 4.149, reincidencia ≥ 2):** reformulação de texto não basta de novo — adiciona 4ª camada com check mecânico: (a) reescreve a frase-gatilho para remover a ambiguidade — gate mutante roda em worktree isolada **sempre**, independente de concorrência (a cláusula "nunca a mesma árvore de outro gate concorrente" deixa de ser lida como condição de acionamento); (b) worktree isolada NUNCA compartilha `node_modules`/cache por link físico (junção/symlink) com a árvore principal — instalação própria (`npm ci`) na worktree, ainda que mais lenta; (c) fecho de rodada que usou worktree isolada (ou, por exceção declarada e revisada, mutação direta na árvore principal) não reporta Done sem antes rodar `quality.test` completo na árvore PRINCIPAL pós-limpeza, resultado colado no report — nunca presumir que a limpeza/disciplina preservou a árvore principal sem essa prova
reincidencia: 2
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
