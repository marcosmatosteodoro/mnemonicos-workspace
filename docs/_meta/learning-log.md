# Ledger de aprendizado do processo

> Mantido pelo agent `agile-coach`. Não editar manualmente (exceto revisão humana de uma entrada).
> Só erro de PROCESSO entra aqui; lições de código/projeto → `guidelines/project/`.
> Entradas nunca são apagadas; no máximo marcadas `estado: destilada`.

## LRN-001: higiene da árvore na rodada de gates não é prova mecânica
data: 2026-08-31
gatilho: retry
origem: PLAN-003 (slug producao-material, épico MNEMORA STUDIO F1) — Waves 4, 5, 6, 7
causa_raiz: gates paralelos sobre worktree compartilhado deixaram rastro (sonda `zz-*.test.*`, `npm install`/`ci` mexendo lockfile e podando deps, worktree órfão `.review-wt` com `.env` real, mutante de elevação de privilégio vivo, alteração estagiada invertendo oráculo); a decisão 4.134 (`guidelines/core/CODE-REVIEW.md` §Orquestração) só barra concorrência entre gates que **também mutam** e trata restauração como disciplina em prosa, sem asserção `git diff HEAD` na abertura/fecho e sem os comandos exatos de reversão
artefato_patchado: proposta_doutrina (não aplicado) — `guidelines/core/CODE-REVIEW.md` §"Orquestração da rodada"
patch: consolida lições 1–3 do ciclo; estende 4.134 para "nunca concorrente com QUALQUER gate que leia a árvore ou a saída do runner", e adiciona prova mecânica (3 medições `git rev-parse --short HEAD` · `git status --porcelain` · `git diff HEAD` na abertura e no fecho, divergência = achado bloqueante) + reversão canônica `git restore --source=HEAD --staged --worktree -- <path>` (nunca `git checkout -- <path>`)
reincidencia: 1
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
