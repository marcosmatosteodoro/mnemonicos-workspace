# BRIEF-011: Tira mnemônica como sequência de quadros

**Slug**: producao-material
**Status**: Emitido
**Data**: 2026-09-06
**Largada**: 2026-09-06T19:11:51+0000 (UTC — tzdata America/Sao_Paulo indisponível neste ambiente; ambiente Windows, mesma limitação de sessões anteriores)
**SPEC**: SPEC-011
**Epico**: docs/producao-material/briefs/BRIEF-2026-08-27-mnemora-studio-epic.md
**Jira**: KAN-6

## Pedido como dito

> Continuar com a fatia 4 do épico MNEMORA STUDIO: "Tira mnemônica como sequência de
> quadros" — confirmado pelo Diretor via `/keelson:continue producao-material`, seguindo
> a fila do BRIEF épico (F4, depende de F2, entregue).

## Interpretação do PO

**Contexto**: F2 entregou Conteúdo bruto + Quebra da regra (`RawContent`/`RuleBreakdown`
1:1, 5 blocos). O modelo legado `Mnemonic.hook`/`decoding` (texto único) não tem
representação estrutural de sequência — F4 **substitui, não estende** (MAP.md). A-002
(`[assumido]` `[evidência: crença]`, contestada pelo product-analyst, decidida pelo
Diretor na forja) define a tira como **sequência ordenada de quadros**, não texto corrido.

**Pedido**: modelar e produzir a Tira mnemônica — sequência ordenada de quadros derivada
da Quebra da regra de um Conteúdo bruto — com CRUD e reordenação na tela `(interno)`,
instrumentação de etapa (valor novo no `ProductionStageType`, aditivo) e o encerramento do
`Mnemonic` legado na fábrica (RISK-005-004: texto livre convivendo com fonte estruturada
até F4).

**Premissas decididas**: A-002 mantida como está (decisão do Diretor na forja do
BRIEF-001); risco declarado do épico ("ordenação de quadros sem transação quebra a tira
silenciosamente") é tratado como requisito não-funcional da SPEC, não delegado ao PLAN.

**Fora de escopo**: biblioteca visual/upload de imagem (F5), motor de publicação PDF
(F6), contrastes/pegadinhas/flashcards impressos (F7), versionamento editorial e
fechamento legislativo (F8), gate de qualidade/aprovação (F9), painel estratégico (F10).

## Estimativa — Tira mnemônica como sequência de quadros, F4 (2026-09-06)

- **Base**: pedido (BRIEF-011) · INDEX + MAP de `producao-material` · fila e riscos do BRIEF épico MNEMORA STUDIO · ficha (gates `security`+`review`+`screenVerify`, `mutation`/`e2e` nulos) — sem base histórica (`guidelines/project/estimates.md` não existe)
- **Dimensão**: ~4–5 waves · ~9–12 tasks (~3–4 small · ~6–8 medium)
- **Por fase**: forja 0–2h · artefatos 5–10h · implementação 16–40h · gates 12–30h
- **Total**: 33–82h (horas de ciclo, não prazo de calendário)
- **Confiança**: média — território mapeado e capacidades nomeadas, mas faixa de gates larga por precedente do próprio slug (Wave 5 de PLAN-006 levou 4 rodadas) e sem CI (RISK-006-009)
- **Premissas**: reordenação por controles simples, sem drag-and-drop novo · encerrar o `Mnemonic` legado é desligar da fábrica, não `DROP` de schema nem migração de acervo · valor novo de `ProductionStageType` é aditivo, reusando `production-events.service.ts` sem mecanismo novo · uma tela `(interno)` para CRUD+reordenação
- **Lacunas**: forma da derivação a partir da Quebra da regra (resolvida nesta largada — Etapa 1 do specify: quadros nascem pré-preenchidos a partir dos 5 blocos) · forma do encerramento do `Mnemonic` legado (resolvida nesta largada — desligar da fábrica, sem remoção de schema; remoção física fica para fatia futura)

## Cronologia

- specify: 2026-09-06T19:46:48+0000 · correções: 1 · classes: spec-ac-fora-gwt(25) · spec-ears-nao-casa(1) · spec-must-ratio(1) · spec-sem-should-may(1)

