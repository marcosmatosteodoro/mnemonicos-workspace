# BRIEF-013: Suporte a PWA no mnemonicos-frontend

**Slug**: producao-material
**Status**: Emitido
**Data**: 2026-09-06
**Largada**: 2026-09-06T21:57:36+0000
**SPEC**: SPEC-013
**Jira**: KAN-64

## Pedido como dito
"Crie uma história para adicionar PDW na aplicação deixe em TODO mesmo" — esclarecido em
seguida que "PDW" era "PWA (Progressive Web App)". A demanda ficou registrada como TODO no
histórico do INDEX.md (triagem `/keelson:triage`, classificada como Categoria 1 — Nova
SPEC). Questionado o racional de produto (a fábrica é uso interno EDITOR/ADMIN, desktop —
o estudante não usa este software), o Diretor respondeu: "Nenhum caso de uso específico, só
quero a capacidade disponível". Em seguida, autorizou: "pode seguir e implementar", com
"Sim, ciclo completo da PWA" confirmado explicitamente.

## Interpretação do PO
Contexto: o mnemonicos-frontend é a fábrica interna de produção do material mnemônico
(uso por EDITOR/ADMIN, desktop) — hoje sem manifest, service worker ou instalabilidade.
Pedido: adicionar suporte a PWA (manifest.json, ícones, service worker, app instalável) ao
mnemonicos-frontend. Premissas decididas: o Diretor confirmou que não há caso de uso de
produto específico agora — a capacidade é pedida por completude/boa prática técnica, sem
gatilho de produto, e entra na SPEC como premissa aberta (revisitável se um caso de uso
real de instalação/uso mobile aparecer — ex.: EDITOR revisando em tablet). Fora de escopo:
comportamento offline de dados (cache de API, fila de sincronização) e push notifications
— PWA aqui é instalabilidade/shell, não app offline-first.

## Premissas decididas

- A capacidade nasce sem gatilho de produto identificado — Diretor confirmou "nenhum caso
  de uso específico, só quero a capacidade disponível" (2026-09-06). Registrada como
  premissa aberta na SPEC, não como racional forte de FR de negócio.
- A fábrica é ferramenta interna de uso desktop por EDITOR/ADMIN; instalabilidade não
  resolve um problema de usuário hoje identificado — risco de produto nomeado, não
  bloqueante.

## Fora de escopo

- Funcionamento offline de dados/API (cache de requests, fila de sincronização em
  background)
- Push notifications
- Qualquer mudança no mnemonicos-backend

## Estimativa — PWA no mnemonicos-frontend (2026-09-06)

- **Base**: pedido · BRIEF-013 · SPEC-013 (6 FRs · 8 NFRs · 12 ACs) · INDEX de producao-material (terreno: PLAN-006 14 tasks/5 waves, PLAN-010 3 tasks/3 waves, PLAN-012 13 tasks) · ficha (`gates.security: true`, `gates.review: true`, `screenVerify` on, `quality.e2e: null`, `quality.mutation: null`) · **sem base histórica** (`guidelines/project/estimates.md` ausente — nenhum corretor aplicado)
- **Dimensão**: ~4 waves · ~7 tasks (~3 small · ~4 medium)
- **Por fase**: forja 1–2 h · artefatos 3–6 h · implementação 10–26 h · gates 4–10 h
- **Total**: 18–44 h (horas de ciclo, não prazo de calendário)
- **Confiança**: baixa — sem calibração histórica, área inteiramente nova no projeto (nenhuma capacidade PWA existente), técnica ainda não decidida ao estimar (Q-013-001, resolvida depois no PLAN-013 por service worker artesanal) e três ACs de ciclo de vida do service worker sem caminho de prova automatizado disponível hoje
- **Premissas**: fatia só-frontend, sem tocar `mnemonicos-backend` (§4.2) — nenhum custo de migração ou de sincronia de tipos cross-repo · ícones nascem de asset simples da identidade atual (A-013-002), sem trabalho de design de marca · forja e specify já consumidos (Cronologia abaixo: 1 rodada de correção de validators), restando ~14–36 h de `/keelson:plan` em diante · prova de AC-013-001/AC-013-002 fecha por handoff de tela (gate 9, precedente HANDOFF-PLAN-003), fora da faixa de horas do ciclo · **atualização pós-PLAN**: PLAN-013 decidiu service worker artesanal (não biblioteca) — empurra a implementação para o topo da faixa, conforme a nota original do estimator
- **Lacunas**: como AC-013-005/008/012 (cache no logout, navegação sempre à rede, aba viva na versão antiga) se provam com `quality.e2e: null` — Playwright ad hoc (precedente HANDOFF-PLAN-003), caminhada manual, ou instalar a suíte antes com `/keelson:e2e-setup`? · origem HTTPS de produção não confirmada (A-013-006, já escalada como E-01 na aprovação da SPEC) · sobreposição de superfície com PLAN-012 (RISK-013-005, mesmo `app/`/layout) — ordem de merge é ato do Diretor

## Cronologia

- Largada: 2026-09-06T21:57:36+0000
- specify: 2026-09-06T23:01:48+0000 · correções: 1 · classes: spec-ac-fora-gwt(12) · spec-must-ratio(1) · spec-sem-should-may(1)
