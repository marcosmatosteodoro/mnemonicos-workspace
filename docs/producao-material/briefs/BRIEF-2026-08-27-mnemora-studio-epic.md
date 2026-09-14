# BRIEF épico: MNEMORA STUDIO — fábrica interna do material mnemônico

**Slug**: producao-material
**Status**: em execução
**Data**: 2026-08-27
**Origem**: docs/producao-material/briefs/BRIEF-001.md
**Branch**: feat/producao-material-mnemora-studio
**Estratégia**: unica
**Jira**: KAN-6

## Pedido épico (verbatim, herdado de BRIEF-001)

> A TAP formaliza um **método** de converter conteúdo jurídico denso em memória recuperável,
> e é explícita em que o ativo não é o PDF: *"O ativo principal do projeto não é o PDF. É o
> método replicável de converter conhecimento denso em memória recuperável"* (capa, diretriz
> central).
>
> Construir a **ferramenta interna de produção** do material mnemônico — o que a §6.2 chama
> de templates, biblioteca, padrões de tira e checklists, e o que a §4.4 chama de controle
> de qualidade jurídica com versão e data de fechamento de legislação. O que o estudante
> compra continua sendo o PDF (§4.2), e **é a fábrica que o emite**: o acervo estruturado
> entra e o PDF diagramado sai, com versão e data de fechamento de legislação (§4.4)
> estampadas pelo próprio pipeline. A régua de valor da fábrica é a métrica que a própria TAP
> nomeia e não mede: **tempo de produção por página**.
>
> Anti-persona: o **estudante concursando** não é usuário deste software. Se um requisito só
> faz sentido para ele, está no slug errado.

Texto completo, premissas seladas (A-001 a A-012), glossário, fatos do código e perguntas
pendentes (Q-11, Q-12): ver BRIEF-001.md (origem, acima).

## Decomposição do PM

O BRIEF original propunha 4 capacidades ("(1) precede (2); (3) e (4) em paralelo"). O `pm`
confirmou parcialmente e corrigiu: (1) não cabe numa fatia só (vira 4: conteúdo/quebra, tira,
biblioteca visual, contrastes+protocolos); (3) QC jurídico **não** é paralelo a (2) — o
pipeline v1 emite rascunho, o carimbo oficial vem do QC; (4) medição separa-se em captura
cedo (F3) e painel tarde (F10); e o inventário original não continha **acesso/papéis
internos** (pré-requisito do gate de aprovação) nem **fila/calendário editorial** (proposto
fora do MVP).

## Fila

| # | Fatia | Slug de destino | Estado |
|---|---|---|---|
| 1 | Acesso interno e papéis de produção | producao-material | entregue (BRIEF-002 · SPEC-002 · PLAN-003 Done 16/16; mergeado PR #1; HANDOFF-PLAN-003 fechado 2026-09-01) |
| 2 | Conteúdo bruto, quebra da regra e fonte normativa | producao-material | entregue (BRIEF-005 · SPEC-005 · PLAN-006 Done 14/14; mergeado PR #2 backend/#3 frontend 2026-09-06) |
| 3 | Instrumentação de etapas da fábrica | producao-material | entregue e mergeada (BRIEF-009 · SPEC-009 · PLAN-010 Done 3/3; PR #3 backend `6541d49`, 2026-09-06) |
| 4 | Tira mnemônica como sequência de quadros | producao-material | entregue (BRIEF-011 · SPEC-011 · PLAN-012 Done 13/13; PR #5 backend `9063f9e`/PR #9 frontend `179e7f5` mergeados em `main`; DoD (Etapa 4) + Entrega ACEITA_COM_RESSALVAS 2026-09-07, ressalva R-1 do PO aplicada) |
| 5 | Biblioteca visual reutilizável | producao-material | entregue e mergeada (BRIEF-022 · SPEC-022 · PLAN-023 Done 17/17; PR #6 backend `e316ab6`/PR #12 frontend `677b836` mergeados em `main` 2026-09-14) |
| 6 | Pipeline de publicação — PDF (rascunho) | producao-material | em ciclo (BRIEF-024.md) |
| 7 | Contrastes, pegadinhas, flashcards e protocolos impressos | producao-material | pendente |
| 8 | Versionamento editorial e fechamento legislativo | producao-material | pendente |
| 9 | Controle de qualidade e gate de versão aprovada | producao-material | pendente |
| 10 | Painel estratégico e tempo por página | producao-material | pendente |
| 11 | Fila de produção e calendário editorial *(fora do MVP — confirmado pelo Diretor)* | producao-material | pendente |

## Dependências por fatia

- F1 → nenhuma.
- F2 → F1.
- F3 → F2.
- F4 → F2.
- F5 → F4.
- F6 → F4, F5.
- F7 → F2, F6.
- F8 → F2, F6.
- F9 → F1, F8.
- F10 → F3 (essencial); F8, F9 (parcial).
- F11 → F2, F9. Fora do MVP por decisão do Diretor (2026-08-27) — reavaliar quando existir o
  2º/3º módulo (§7.2 da TAP: "a coleção só cresce depois de comprovada a demanda").

## Riscos por fatia

- **F1**: sem authz server-side (deny-by-default), o gate de F9 é decorativo; rotas de login
  novas exigem rate limit/expiração/rotação de sessão (A07); reinterpreta A-005 — `User`/auth
  acordam para o time interno, mas `CardState`/`Review`/scheduler/papel STUDENT continuam
  dormentes.
- **F2**: RDR-001 sem decisão (5 classes de radar da TAP × 3 prioridades do mockup) — resolver
  como premissa na SPEC; contrato de API fantasma (`/mnemonics`, `/flashcards/due`) já
  chamado pelo frontend sem existir no backend; tipos de domínio fora de sincronia entre os
  dois repos.
- **F3**: se confundida com o painel (F10) e adiada, viola A-011 (instrumentação desde o
  primeiro conteúdo); "página" ainda sem denominador definido antes de F6 existir.
- **F4**: A-002 é `[evidência: crença]`, contestada pelo product-analyst; ordenação de quadros
  sem transação quebra a tira silenciosamente.
- **F5**: upload de imagem exige validação server-side de tipo/tamanho, sem SVG cru (A02/A08);
  antecipa decisão de formato que o motor de PDF (F6) ainda vai exigir.
- **F6**: motor HTML→PDF com rede aberta ou sem escape de conteúdo é SSRF (A01) e injeção
  (A05) a partir do servidor; escolha do motor é irreversível na prática (muda o padrão
  visual das 10 camadas para dentro do deploy); emite também a variante "resumo" do braço de
  controle do A/B (A-012) por decisão do Diretor (2026-08-27).
- **F7**: risco de deslize para tela de estudo (viola a anti-persona); scheduler SM-2
  existente é incompatível por design com os marcos fixos R0/R24/R3/R7/R14/R30 — não reusar.
- **F8**: histórico editável destrói a própria função (A08 — precisa ser append-only);
  snapshot imutável × referência mutável é decisão arquitetural irreversível do PLAN.
- **F9**: fail-open no catch é o defeito clássico e aqui tem consequência jurídica; A-010
  (revisor ≠ autor) exige 2+ pessoas no time interno — inexequível com operação de 1 pessoa.
- **F10**: Q-12 em aberto (5 das 6 métricas da §5.4 sem instrumento) — nasce só com o que a
  fábrica mede sozinha (tempo/página por etapa, retrabalho, erros de revisão, backlog); venda
  e métricas do beta entram, se entrarem, como dado importado rotulado como tal.
- **F11**: nome R1/R7/R14/R24/R30 do calendário editorial colide em vocabulário (não em
  função) com a revisão espaçada do estudante — distinguir explicitamente se a fatia for
  retomada.

## Premissas e perguntas sem fatia de software (portfólio, não órfãs)

- **A-009** (retenção decisória × facilidade percebida diagnóstica) e **A-012** (exceto a
  variante "resumo" do braço de controle, que é saída de F6) vivem na operação do beta
  (formulário + planilha, A-004) — nenhuma fatia as implementa.
- **Q-11** (limiar de refutação e n mínimo do piloto) — já registrado como risco ativo
  PIL-001 no INDEX; não bloqueia nenhuma SPEC, bloqueia a conclusão do piloto e a decisão
  sobre os 16 módulos futuros (§7.2).

## Perguntas ao Diretor — respondidas na decomposição (2026-08-27)

1. F1 entra em primeiro e reinterpreta A-005 (só `User`/auth acordam; `CardState`, `Review`,
   scheduler e papel STUDENT seguem dormentes) — **confirmado**.
2. Pipeline v1 (F6) emite PDF marcado como rascunho; carimbo oficial só com F8+F9 —
   **confirmado**.
3. F6 também emite a variante "resumo" do braço de controle do A/B (A-012) —
   **confirmado**.
4. F11 (fila de produção + calendário editorial) fica fora do MVP — **confirmado**.
5. F10 nasce só com o que a fábrica mede sozinha; venda e métricas do beta ficam fora até
   Q-12 responder — **confirmado**.

## Cronologia

- 2026-08-27: decomposição via /keelson:specify-epic (agent `pm`), confirmada pelo Diretor.
- 2026-08-27: Diretor liga `jira.enabled: true`; `createmeta` do projeto KAN medido
  (Epic `10006`, Story `10009`, Subtask `10007`, Task `10008`) e gravado na ficha e em
  `docs/_meta/jira.KAN.md`; Epic-raiz criado — `KAN-6`.
- 2026-08-31: `/keelson:continue` — correção declarada da fila (princípio 2): F1 estava
  como `em ciclo (BRIEF-002.md)` mas os artefatos filhos mostram **entregue** — PLAN-003
  Done 16/16, PR #1 mergeado (backend `25cdafd` · frontend `834f117`), HANDOFF-PLAN-003
  fechado 2026-09-01, Stories KAN-8/9/10 Concluído. Próxima: F2.
- 2026-09-06: `/keelson:continue` — correção declarada da fila (princípio 2): F2 estava
  como `em ciclo (BRIEF-005.md)` mas os artefatos filhos mostram **entregue** — PLAN-006
  Done 14/14, PR #2 (backend `ac5c4f8`) e PR #3 (frontend `0bcbacd`) mergeados em `main`
  nos dois repos, DoD (Etapa 4) 6/6 verificada, gate 9 VERIFICADO. Próximas elegíveis: F3
  (depende só de F2) e F4 (depende de F2; A-002 contestada pelo product-analyst, atenção
  na largada).
- 2026-09-06: **F3 entregue e mergeada** (BRIEF-009/SPEC-009/PLAN-010, 3/3 TASKs Done) —
  mecanismo append-only de evento de etapa de produção, emissão transacional fail-secure
  integrada em `contents.service.ts`. 3 waves, 1 retry (dedup de fixture). Gates 1-7/8/10
  aprovados em todas as waves; gate 9 verificado ao vivo; convergência de fecho CONVERGIU.
  PO: ACEITA_COM_RESSALVAS. 2 escalações do PO (lead-time × esforço; fail-secure ×
  disponibilidade) respondidas pelo Diretor na Entrega — ambos os defaults confirmados,
  já implementados de fato. Branch `feat/producao-material-mnemora-studio` mergeada em
  `main` (backend, PR #3, `6541d49`) — frontend sem mudança nesta fatia. Migração aditiva
  aplicada em dev/teste e agora em `main`; aplicação em produção **automatizada em 2026-09-06**
  (BRIEF-010: o `vercel-build` do backend roda `prisma migrate deploy` a cada deploy,
  `2bb9dc0`) — deixa de ser ato manual do Diretor. RISK-006-009 segue aberto: sem CI,
  o DDL alcança produção sem teste automatizado antes. Próxima elegível: F4.
- 2026-09-06: **F4 largada** via `/keelson:continue` → `/keelson:auto` (BRIEF-011.md) —
  sync de largada dos dois repos de código com `main` (backend fast-forward `6541d49`;
  frontend já atualizado).
- 2026-09-13: `/keelson:continue` — correção declarada da fila (princípio 2): F4 estava
  como `em ciclo (BRIEF-011.md)` mas os artefatos filhos mostram **entregue** — PLAN-012
  Done 13/13, DoD (Etapa 4) fechada e Entrega ACEITA_COM_RESSALVAS 2026-09-07 (ressalva
  R-1 do PO aplicada: DEC-012-009 supersedida por DEC-012-011), PR #5 backend (`9063f9e`)
  e PR #9 frontend (`179e7f5`) mergeados em `main` nos dois repos. Pendência aberta pela
  Entrega (RISK-011-008, R-3 do PO): brief avulso para investigar `mnemonic-strip-board.tsx`
  (mesma forma "data em cache + 404" corrigida em `rule-breakdown-form.tsx`) — ainda não
  aberto, não bloqueia a fila. Próxima elegível: F5 (depende só de F4).
- 2026-09-14: **F5 entregue e mergeada** — PR #6 backend (`e316ab6`) e PR #12 frontend
  (`677b836`) mergeados em `main` nos dois repos (Diretor). Histórias KAN-86/87/88 e o
  Épico KAN-85 fechados no Jira pelo Diretor. Próxima elegível: F6 (depende de F5).
- 2026-09-13: **F5 largada** via `/keelson:continue` → `/keelson:auto` (BRIEF-022.md) —
  sync de largada dos dois repos de código com `main` (backend fast-forward `9063f9e`
  via PR #5; frontend fast-forward `8d661a5` via PR #11, branch trocada de
  `feat/producao-material-rewrite-same-origin-cookie-sessao`, que já estava mergeada).
- 2026-09-14: **F5 implementada por completo** — PLAN-023 Done 17/17 TASKs, 6/6 waves, DoD
  (Etapa 4) satisfeito, 3 FEATs de SPEC-022 VERIFICADAS por execução real (browser +
  HTTP). Convergência mais longa e mais séria do slug até aqui: 2 vulnerabilidades/defeitos
  reais encontrados e fechados com prova por mutação (corrida TOCTOU real na trava de
  remoção, Wave 4; filtro de categoria interpretando metacaractere LIKE do cliente, Wave
  5). Tech Lead aplicou degrau 1 da escada repetidamente para achados mecânicos sem
  ambiguidade de produto — nenhuma escalação genuína ao Diretor durante a implementação.
  Entrega: as 2 escalações do PO da fase SPEC (A-022-011 escrita restrita ao autor,
  A-022-012 instrumentação mínima de etapa) confirmadas pelo Diretor como decisão
  definitiva — ambas já eram o comportamento implementado, nenhuma mudança de código.
  Branches pushadas nos dois repos (backend `a7f445a`, frontend `f4ba4b6`) — merge/PR fica
  para `/keelson:integrate`, ainda não rodado. Pendências não-bloqueantes herdadas de
  waves anteriores do slug, não desta fatia: RISK-011-008 (brief avulso de
  `mnemonic-strip-board.tsx`, ainda não aberto) e o gap de `quality.test` não alcançar a
  suíte de integração (achado da Wave 2 de PLAN-023, estrutural, decisão de ficha para o
  Diretor). 15+ lições novas/estendidas roteadas a `guidelines/project/lessons.md` e
  `docs/_meta/learning-log.md` (LRN-020 a LRN-024, PROPOSTA_PLUGIN).
