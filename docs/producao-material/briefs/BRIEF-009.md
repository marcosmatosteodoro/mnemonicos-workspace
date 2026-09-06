# BRIEF-009: Instrumentação de etapas da fábrica

**Slug**: producao-material
**Jira**: KAN-6
**Status**: Aceito
**Data**: 2026-09-06
**Largada**: 2026-09-06T01:38:27-03:00
**SPEC**: SPEC-009
**Epico**: docs/producao-material/briefs/BRIEF-2026-08-27-mnemora-studio-epic.md

## Pedido como dito

Fatia 3 da fila do BRIEF épico MNEMORA STUDIO (decomposição do `pm` confirmada pelo
Diretor em 2026-08-27), retomada via `/keelson:continue` em 2026-09-06:

> | 3 | Instrumentação de etapas da fábrica | producao-material | pendente |

Dependência: `F3 → F2` (entregue — SPEC-005/PLAN-006, mergeado PR #2 backend/#3
frontend, 2026-09-06).

Risco declarado da fatia (BRIEF épico, seção "Riscos por fatia"), verbatim:

> **F3**: se confundida com o painel (F10) e adiada, viola A-011 (instrumentação desde o
> primeiro conteúdo); "página" ainda sem denominador definido antes de F6 existir.

Herança do BRIEF-001 — A-011 (redação do parecer, incorporada): *"O tempo de produção por
página será instrumentado desde o primeiro módulo e decomposto por etapa, incluindo
retrabalho, revisão e exportação."* É requisito operacional da fábrica, não relatório
opcional. Decomposição do `pm`: medição separa-se em **captura cedo (F3)** e **painel
tarde (F10)** — F3 não é o painel.

## Interpretação do PO

**Contexto.** A fábrica hoje só tem duas estações reais com tela: Conteúdo bruto (F2) e
Quebra da regra (F2). `RawContent`/`RuleBreakdown` já têm `createdAt`/`updatedAt`, mas
isso não decompõe por etapa nem distingue produção de retrabalho — e A-011 exige as duas
coisas desde o primeiro conteúdo, não a partir de quando o painel existir.

**Pedido.** (1) Criar o mecanismo genérico de evento de etapa da produção (append-only,
nunca editado/apagado) pronto para as fatias futuras (F4 tira, F5 biblioteca, F6
publicação, F8 versionamento, F9 QC) emitirem sem redesenho de schema. (2) Instrumentar
as duas estações que já existem — abertura e conclusão de Conteúdo bruto e de Quebra da
regra — emitindo evento por transição. (3) Sinalizar **retrabalho**: reabertura de uma
etapa já concluída (ex.: EDITOR edita a Quebra depois de já tê-la salvo) é um evento
distinto, não uma 2ª conclusão. (4) **Não** computar "tempo por página" nem qualquer
agregação/painel — isso é F10, que só existe quando F6 definir o denominador "página".

**Premissas decididas.**
- **P-01 — "etapa" nesta fatia = as 2 estações com tela hoje.** Fatias futuras reusam o
  mesmo mecanismo (tipo de etapa extensível) sem migração de schema por fatia nova — a
  SPEC decide a forma (enum vs. string livre) via DEC. `[assumido]`
- **P-02 — evento é append-only**, sobrevive à remoção reversível do pai (soft-delete de
  `RawContent`) — é dado de auditoria/instrumentação, não estado de negócio; nunca some
  junto com o conteúdo. `[assumido]`
- **P-03 — retrabalho por reabertura.** Conclusão registrada 1x; qualquer edição
  subsequente à mesma etapa já concluída emite `retrabalho`, nunca uma 2ª `concluido`.
  `[assumido]`
- **P-04 — sem UI de consumo.** Nenhuma tela de leitura/relatório nesta fatia — dado é
  para instrumentação futura (F10), não para o EDITOR/ADMIN verem agora. `[assumido]`
- **P-05 — captura no service, não na rota nem no frontend** — consistente com "lógica de
  negócio pura fica em função sem I/O" onde aplicável; a emissão do evento é efeito
  colateral do mesmo service que já muda o estado (`contents.service.ts`), não uma camada
  nova de tela. `[assumido]`
- **P-06 — revisão e exportação (F8/F9/F6) ficam fora.** O mecanismo (1) é desenhado para
  acomodá-las depois; nenhum evento desses tipos é emitido nesta fatia porque as telas que
  os produziriam não existem ainda. `[assumido]`

**Fora de escopo.**
- Painel/dashboard de produção e cálculo de "tempo por página" (F10 — falta o
  denominador, que só F6 define).
- Tira mnemônica como quadros (F4); biblioteca visual (F5); pipeline de publicação/PDF
  (F6); versionamento editorial (F8); QC e gate de versão aprovada (F9).
- Qualquer tela nova para o EDITOR/ADMIN — instrumentação é infraestrutura silenciosa
  nesta fatia.
- Qualquer superfície voltada ao estudante.

## Estimativa

> Bloco do agent `estimator` na largada (2026-09-06). Best-effort, informa — não decide
> rota nem escopo. Sem calibração medida (`guidelines/project/estimates.md` não existe);
> F1 (PLAN-003, 16 tasks) e F2 (PLAN-006, 14 tasks/5 waves) usadas só como referência
> qualitativa.

- **Dimensão**: ~4–5 waves · ~8 tasks (~3 small · ~5 medium), dominante `medium`.
- **Fatias verticais prováveis**: model `ProductionStageEvent` append-only + enums +
  migração aditiva · núcleo de emissão (`production-events.service.ts`, decisão pura
  `abertura|conclusão|retrabalho` recebendo `now`) · instrumentação de Conteúdo bruto em
  `contents.service.ts` · instrumentação da Quebra da regra · tripwire de append-only
  (nenhum caminho de update/delete de evento) · prova de integração ponta a ponta ·
  (condicional) espelho cross-repo dos enums novos.
- **Total**: 20–48 h de ciclo. **Confiança**: média — backend-heavy, sem tela nova (P-04,
  P-05), mas dispersão dominada pela taxa histórica de retry dos gates 8/10 neste projeto.
- **Premissas que reduzem a dispersão**: P-05 já resolve a lacuna de maior efeito
  apontada pelo estimator ("gatilho de abertura é derivado da mutação existente, sem rota
  nova") — sem isso, +2 tasks e reativação dos gates 9/11.

## Cronologia

- 2026-09-06T02:05:40-03:00 — **Etapa 1 (SPEC) concluída.** `scribe` redigiu SPEC-009 (10
  FRs/4 NFRs/8 ACs/10 premissas). `spec-validator`: 0 ERROR (correções: 0; classes: 2
  WARNINGs ambientais — `spec-ac-fora-gwt` × 8, presente igualmente em SPECs já Approved
  do projeto — mais `spec-must-ratio`/`spec-sem-should-may`, estilo, não bloqueante).
  `product-analyst`: `REVISAR_ANTES_DE_APROVAR` (8 eixos de mérito). `po` (aprovação):
  `ESCALAR` 2 pontos (lead-time × esforço; atomicidade fail-secure × disponibilidade —
  registrados como E-02 no INDEX, ambos seguidos pelo default, parqueados para a Entrega),
  resolveu os demais 8 dentro do brief. Pacote de correção (11 edições) aplicado pelo
  `scribe`; revalidação mecânica limpa (0 ERROR). SPEC → **Approved** v0.2.
- 2026-09-06T02:25:59-03:00 — **Etapa 2 (PLAN) concluída.** `code-scout` (antecipado na
  Etapa 1) reusado sem re-despacho. `scribe` redigiu PLAN-010 (6 COMPs, 6 DECs — todas
  reversíveis). `plan-validator`: 0 ERROR após 1 volta de correção de forma (enum
  `Irreversível` em ASCII `nao`; listas `FRs/NFRs cobertos` reformatadas 1-por-linha; §7
  ganhou linhas de NFR além de FR — bug de parser em campo com quebra de linha,
  corrigido). `plan-dec-alternativa-unica` (4 DECs) calibrado como WARNING aceito, mesmo
  padrão de PLAN-006. PLAN → **Approved** v0.2.
