# BRIEF-034: Painel estratégico e tempo por página

**Slug**: producao-material
**Status**: Emitido
**Data**: 2026-09-30
**Largada**: 2026-09-30T01:35:37-0300
**SPEC**: SPEC-034
**Jira**: KAN-165
**Epico**: docs/producao-material/briefs/BRIEF-2026-08-27-mnemora-studio-epic.md

## Pedido como dito

> "Painel estratégico e tempo por página (épico: docs/producao-material/briefs/BRIEF-2026-08-27-mnemora-studio-epic.md)"
> — Fatia 10 da fila do épico MNEMORA STUDIO. Depende de F3 (instrumentação de etapas,
> essencial) e de F8/F9 (versionamento e aprovação, parcial) — todas entregues e mergeadas
> em `main`.

## Interpretação do PO

**Contexto**: desde F3 a fábrica grava um evento append-only por etapa de produção
(`ProductionStageEvent`: 8 etapas — Conteúdo bruto, Quebra da regra, Tira mnemônica,
Associação visual, Material de reforço, Versão editorial, Aprovação da versão, Publicação
PDF — com abertura/conclusão/retrabalho, ator e instante), e ninguém lê esses dados: não
há consumidor, rota nem tela. A TAP (§6.2) nomeia **tempo de produção por página** como a
métrica que decide se o modelo escala, e o épico (decisão 5, confirmada pelo Diretor em
2026-08-27) diz que F10 nasce **só com o que a fábrica mede sozinha**. A home interna
(`/studio`) ainda é um placeholder.

**Pedido**: um **Painel estratégico** interno que mostra, a partir dos dados que a
fábrica já grava (mais a contagem de páginas, que passa a ser gravada):
(1) **tempo por página** — tempo de produção (lead time de calendário, régua confirmada em
F3) por Conteúdo e por etapa, dividido pelas páginas do PDF exportado; (2) **conclusão por
módulo** (Disciplina/Tema) — quantos Conteúdos existem e quantos já têm Versão aprovada;
(3) **correções após revisão** — edições feitas depois do fechamento de uma Versão
(retrabalho), rotuladas como tal; (4) **backlog** — Conteúdos ativos ainda sem Versão
aprovada, com a etapa mais avançada alcançada e a prioridade de apresentação
(Alta/Média/Baixa, derivada do radar — exibição adiada para F10 desde SPEC-005).

**Premissas decididas**:
- A-034-001 `[assumido]` **Página = páginas reais do PDF exportado** (variante Tira,
  incluindo as páginas suplementares de contrastes/pegadinha/flashcards/protocolo) —
  **decidido pelo Diretor na última chamada (2026-09-30)**. A exportação passa a gravar o
  número de páginas numa coluna nova e opcional; exportações anteriores aparecem como
  "sem medida", nunca como zero nem estimadas.
- A-034-002 `[assumido]` **"Erros na revisão" = correções após o fechamento de uma
  Versão** (eventos de retrabalho posteriores ao fechamento), rotulados no painel como
  "correções após revisão" — **decidido pelo Diretor na última chamada (2026-09-30)**. Sem
  ação nova de "devolver para correção" nesta fatia.
- A-034-003 `[assumido]` Tempo é **lead time de calendário** por etapa, não esforço (régua
  E-02 de F3, confirmada pelo Diretor em 2026-09-06). Fórmula exata (retrabalho no
  numerador — Q-009-001; abertura órfã — Q-009-002) é decisão da SPEC.
- A-034-004 `[assumido]` Migração **aditiva** (coluna nullable) autorizada pelo Diretor
  para dev/teste na última chamada (2026-09-30); produção segue pelo `migrate deploy` do
  deploy, ato do Diretor.
- A-034-005 `[assumido]` O painel é leitura interna (EDITOR e ADMIN), agregada no servidor;
  o estudante nunca o vê (anti-persona).

**Fora de escopo**: "mais vendidos" e "próximos lançamentos" (venda e métricas do beta —
Q-12 sem resposta, decisão 5 do épico); ação "devolver para correção" com motivo gravado;
gráficos com biblioteca nova (nenhuma lib de gráfico no frontend — a apresentação usa o que
o produto já tem); fila de produção/calendário editorial (F11, fora do MVP); reescrita do
seed para gerar eventos históricos.

## Fora de escopo
(ver acima)

## Estimativa

- **Base**: pedido (BRIEF-034, A-034-001..005) · conclusão do code-scout (memo de
  exploração) · INDEX de producao-material (PLAN-010: 3 tasks · PLAN-029: 4 tasks/3 waves ·
  PLAN-033: 7 tasks/5 waves com retries de gate 8) · ficha (security/review/screenVerify
  ativos; mutation/e2e nulos) · calibração: **sem base histórica** (2 demandas fechadas em
  `estimates.md`, só PLAN-031 posterior à 4.437 — nenhum corretor aplicado)
- **Dimensão**: ~4 waves · ~8 tasks (~3 small · ~5 medium)
- **Por fase**: forja 0–0,5h · artefatos 1,5–4h · implementação 8–28h · gates 4–14h
- **Total**: 14–46h (horas de ciclo, não prazo de calendário)
- **Confiança**: média — terreno mapeado e premissas de produto fechadas, mas sem
  calibração válida e agregação é área nova (zero `groupBy`/`aggregate` no src).
- **Premissas**: `pageCount` nullable via `getPageCount()` antes do `.save()` (migração
  aditiva autorizada em dev/teste) · 4 capacidades em fatias verticais, painel em `/studio`
  sem nav nova · agregação no service, sem SQL bruto nem view; sem paginação no volume atual
  (gate 10 decide TRISK-010-002) · gates 8/9/10/11 ativos, margem de 1–2 retries de gate 8
  · gate 9 gera dado exercitando rotas (seed com zero eventos), parte pode fechar
  `pendente_handoff` · mapeamento radar→prioridade já fixado (DEC-006-009) · 1–2 rodadas de
  convergência de fecho.
- **Lacunas**: fórmula do tempo por etapa (Q-009-001/002 — decidida na SPEC) · filtros do
  painel (fora do pedido; +1 task se entrarem) · escopo de "correções após revisão" (todas
  as etapas × só Conteúdo bruto — RISK-011-006) · origem da `radarClass` (coluna do
  `RawContent` — confirmado pelo code-scout, schema.prisma:328).

## Cronologia
- largada: 2026-09-30T01:35:37-0300
- specify: 2026-09-30T02:19:38-0300 · correções: 1 · classes: spec-ears-nao-casa(1) · spec-porte-epico(1, WARNING aceito) · spec-tecnologia-julgamento(1, identificadores de código) · mérito: product-analyst REVISAR_ANTES_DE_APROVAR (13 riscos) · po APROVAR (R0–R13, 0 escalações) · pacote do po aplicado pelo scribe em modo reescrita (v0.1→v0.2) · janelas: redação 8min/495l
- plan: 2026-09-30T02:37:25-0300 · correções: 1 · classes: fr-sem-comp(5, campo Realiza multilinha) · comp-realiza-fora-cobertura(33, bullets de FRs cobertos multilinha) · plan-reabrir-nunca-sem-motivo(2) · cobertura 34/34 FRs + 4/4 NFRs, gap 0 · 4 WARNING plan-dec-alternativa-unica aceitos
- tasks: 2026-09-30T03:21:49-0300 · correções: 2 · classes: task-criterio-sem-ac(1) · task-refactor-sem-identidade(1) · task-criterio-grep-nao-ancorado(6, ancorados/aceitos) · qa pré-código: 3 mecânicos + 1 decisão de produto (po resolução: opção B, V7/V8) · 8 TASKs/5 waves, graph --check --stage=tasks: 0 ERROR · janelas: redação 21min/1728l · correção 9min/1728l
- pausa: 2026-09-30T09:21:23-0300 · sessão de142e84@auto-avaliar-Latitude-3550 · ponto: Wave 5 de PLAN-035 (TASK-035-008, tela do Painel) em retry 2: TASK-035-001..007 Done com closure; TASK-035-008 implementada (530ee37/75f93dc/afb8798) com gates 8/10 aprovados e gates 1/7/11 pendentes do retry 2 — WIP guardado em git stash do mnemonicos-frontend ('WIP TASK-035-008 retry 2'), pacote em thoughts/local/sessions/20260930-013601-de142e84/gates/w5-retry2.md; faltam gate 9 da FEAT-034-002 (qa, roteiro V1-V8), Etapa 4 (suíte completa, convergência, DoD, MAP) e Entrega · motivo: Diretor pediu parada para reiniciar o PC
- retomada: 2026-09-30T09:26:51-0300 · sessão de142e84@auto-avaliar-Latitude-3550 · parado desde 2026-09-30T09:21:23-0300 (marcada) · 0h05min
- implement: 2026-09-30T10:14:06-0300 · 8/8 TASKs Done em 5 waves · retries: W1 ×1 (001, 003), W2 ×1 consolidado + retry 2 (005, teto 4.88), W3 ×3 (006: gates 4/1/6, teto 4.88 no gate 1, gate 10 O(N·E), extrator textual), W4 ×1 (007), W5 ×2 + barra de contraste (008, teto 4.88 no gate 1) · 3 furos no plano (005 export; 006 bloco por Conteúdo; 008 FR-034-026) · 1 pausa (reinício do PC) · merge da main do frontend (nova identidade visual) antes do gate 9 de tela
