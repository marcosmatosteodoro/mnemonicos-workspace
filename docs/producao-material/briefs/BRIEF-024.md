# BRIEF-024: Pipeline de publicação — PDF (rascunho)

**Slug**: producao-material
**Status**: Emitido
**Data**: 2026-09-14
**Largada**: 2026-09-14T13:34:27-0300
**SPEC**: SPEC-024
**Epico**: docs/producao-material/briefs/BRIEF-2026-08-27-mnemora-studio-epic.md
**Jira**: KAN-106

## Pedido como dito

> Continuar com a fatia 6 do épico MNEMORA STUDIO: "Pipeline de publicação — PDF
> (rascunho)" — confirmado pelo Diretor via `/keelson:continue producao-material`,
> seguindo a fila do BRIEF épico (F6, depende de F4 e F5, ambas entregues e mergeadas
> em `main`).

## Interpretação do PO

**Contexto**: a TAP (BRIEF-001) é explícita em que o ativo do projeto não é o PDF, mas o
método — e ainda assim **é o PDF que o estudante compra** (§4.2); a fábrica é o que o
emite, com versão e data de fechamento de legislação estampadas pelo próprio pipeline
(§4.4). F4 entregou a Tira mnemônica (`MnemonicStrip`/`MnemonicFrame`, sequência ordenada
de Quadros); F5 entregou a Biblioteca visual (`VisualAssociation`, vinculável 1:N por
Quadro). O épico já decidiu, na decomposição do PM (2026-08-27): o pipeline v1 (F6) emite
PDF marcado como **rascunho** — o carimbo de versão aprovada só existe depois de F8
(versionamento/fechamento legislativo) + F9 (QC jurídico), nenhum dos dois nesta fatia; e
F6 também emite a variante **"resumo"** do braço de controle do A/B de retenção (A-012).

**Pedido**: construir o motor de publicação que consome, de um Conteúdo bruto com Quebra
da regra salva, os dois artefatos PDF marcados como rascunho: (1) a variante **tira** —
diagramação da Tira mnemônica (Quadros em ordem, com a Associação visual vinculada de
cada Quadro quando existir) e (2) a variante **resumo** — a Quebra da regra em texto
corrido, sem diagramação de quadros (braço de controle do A/B, A-012). Endpoint de
exportação no backend + acionamento na tela do Conteúdo/Tira.

**Premissas decididas**:
- PDF emitido nesta fatia é **sempre rascunho** — rótulo textual visível no próprio
  documento; nenhuma outra marca de aprovação/fechamento existe até F8+F9.
- Postura de segurança selada independente da biblioteca escolhida (o motor concreto é
  DEC técnica do PLAN): **sem** motor que abra rede durante a renderização a partir de
  conteúdo controlado pelo usuário (mitiga SSRF, A01) e **todo** texto do usuário
  (Quebra, Quadros, categoria/função cognitiva da imagem) é tratado como dado — nunca
  interpolado como template/HTML/markup renderizável (mitiga injeção, A05). Um motor
  puro-JS sem browser headless (ex.: geração declarativa/imperativa de PDF) resolve as
  duas condições ao mesmo tempo e evita a "escolha irreversível" que o épico temia —
  fica registrado como candidato a recomendar no PLAN, decisão final é do DEC com
  alternativas.
- As 2 variantes nascem do **mesmo** pedido de exportação (não são fluxos/telas
  separados) — um Conteúdo bruto com Quebra salva sempre pode gerar "resumo"; a
  variante "tira" exige a Tira mnemônica existir (reusa a geração idempotente de F4,
  `openMnemonicStrip`, se ainda não aberta — sem tela nova de pré-requisito).
- Sem imagem vinculada a um Quadro, a variante "tira" segue emitindo esse Quadro
  (só o texto) — Associação visual é enriquecimento, nunca bloqueio de exportação.
- Sem processamento server-side pesado da imagem (resize/recompressão) nesta fatia —
  a Associação visual entra no PDF como F5 a armazenou (`Bytes` raster já validado por
  assinatura de bytes); ajuste de proporção/tamanho no layout é decisão de diagramação
  do PLAN, não reprocessamento do arquivo.

**Fora de escopo**: versionamento editorial e data de fechamento de legislação (F8),
contrastes/pegadinhas/flashcards impressos (F7), QC jurídico e gate de versão aprovada
(F9), painel estratégico e tempo por página (F10 — captura de etapa já existe via F3),
fila de produção/calendário editorial (F11, fora do MVP por decisão do Diretor),
geração automática de imagem por IA — fora do inventário original do PM e sem pedido do
Diretor.

## Estimativa — Pipeline de publicação — PDF (rascunho) (2026-09-14)

- **Base**: pedido (BRIEF-024, 5 premissas já decididas + escopo fechado pelo épico) ·
  `MAP.md` de producao-material (§"Publicação (ausente)" — nenhuma geração/exportação de
  PDF existe nos dois repos: nem dependência, nem rota, nem script; §F5 como padrão de
  módulo mais recente com binário) · INDEX estruturais do mesmo épico (PLAN-003 16t/7w ·
  PLAN-006 14t/5w · PLAN-010 3t/3w · PLAN-012 13t/7w · **PLAN-023 17t/6w**, o par mais
  comparável) · ficha (`gates.security: true`, `screenVerify` ativo, `mutation`/`e2e`
  `null`) — **sem base histórica** de tempo: `guidelines/project/estimates.md` tem 1
  demanda fechada (mínimo 3), nenhum corretor aplicado.
- **Dimensão**: ~6 waves · ~13 tasks (~6 small · ~7 medium)
- **Por fase**: forja 1–2h · artefatos 4–10h · implementação 13–50h · gates 9–28h
- **Total**: 27–90h (horas de ciclo, não prazo de calendário)
- **Confiança**: média — estrutura ancorada em 5 fatias comparáveis do mesmo épico e sem
  entidade nova de CRUD (o desconto real desta fatia); faixa larga porque o motor de PDF
  é greenfield total nos dois repos, a escolha dele é DEC aberta do PLAN e o projeto não
  tem precedente de **oráculo de teste sobre binário PDF** — e o único par realizado
  fechou 4–10× abaixo do piso estimado (1 ponto não calibra).
- **Premissas**: motor puro-JS sem browser headless, como o BRIEF recomenda (headless em
  backend serverless custaria +1–2 waves de infra e alarga a faixa); 1 endpoint único de
  exportação com a variante como parâmetro, **síncrono** na resposta — sem fila/job nem
  persistência/versionamento do PDF gerado (isso é F8); 1 migração aditiva
  (`ALTER TYPE … ADD VALUE` de etapa de produção, padrão já repetido em F3/F4/F5, com o
  precedente de TRISK-012-001) e autorização do Diretor antes de aplicar; guarda de
  autoria (`assertRawContentReachable`), entrega autenticada de binário e geração
  idempotente `openMnemonicStrip` são reuso de F4/F5 — mas contam prova própria (a lição
  "guarda reusada exige prova própria" já reincidiu 2× no slug), não desconto integral;
  imagem entra como F5 a armazenou (`Bytes` raster, teto de 5 MB, sem reprocessamento);
  a tela de acionamento + download real caem no gate 9 `screenVerify` (risco de handoff
  remoto, como em PLAN-013); gate 8 com margem de re-gate (A03 dependência nova de
  renderização, A05 texto do usuário jamais interpolado como template, A01 authz do
  export + SSRF na renderização, A10 falha de render sem stack vazada nem PDF parcial).
- **Lacunas**: forma de entrega — download direto (`Content-Disposition`) vs. preview no
  navegador vs. ambos (preview = +1 superfície de tela e +gate 11) · regra de paginação da
  variante tira — 1 Quadro por página (barato, e era a intenção original de RISK-011-007)
  vs. fluxo de texto com quebra calculada (+1 wave) · oráculo de aceite do PDF — asserção
  sobre texto extraído basta, ou exige comparação visual/snapshot (snapshot = +1 wave de
  infra de teste) · tipografia/identidade — fonte padrão do motor vs. fonte de marca
  embutida (asset + licença) · forma do rótulo "rascunho" — linha em cabeçalho/rodapé vs.
  marca d'água em todas as páginas · resolução mínima da imagem para impressão: o teto de
  5 MB de F5 basta (RISK-022-003 previa exatamente esta reabertura em F6).

## Cronologia
- 2026-09-14T13:34:27-0300: largada via `/keelson:continue` → `/keelson:auto` — sync de
  largada na branch do épico (`feat/producao-material-mnemora-studio`) a confirmar na
  Etapa 0.5.
- 2026-09-14: SPEC-024 redigida pelo `scribe` — 12 FRs, 4 NFRs, 14 ACs, 10 premissas
  `[assumido]` (0 `[confirmar]`), 5 RISKs + 1 Q. Jira stub `KAN-106` criado e linkado a
  `KAN-6` (Relates); Story implícita `KAN-107` criada (SPEC sem FEATs, degrau (0) do §7.0).
- 2026-09-14: validador de forma 0 ERROR (warnings estilísticos, mesmo padrão tolerado em
  SPEC-022). `product-analyst`: `REVISAR_ANTES_DE_APROVAR` (métrica sem denominador,
  colisão da auto-geração da Tira com E-01/A-012 e com a série de etapa de F3/F10,
  comportamento indefinido para imagem irrenderizável/timeout, ACs de autorização
  faltando, RISK-011-007/RISK-022-003 não carregados). `po`: `ESCALAR` — 12 achados
  resolvidos pela leitura do BRIEF/épico (aplicados como correção consolidada à SPEC);
  **1 escalação genuína, E-024-01** (degrau 2 — segue pelo default, pergunta em lote na
  Entrega): a auto-geração da Tira mnemônica pela exportação deve, ou não, emitir o
  evento de abertura da etapa de produção "Tira mnemônica" (afeta a régua de tempo-por-
  etapa de F3/F10)? Default aplicado: **não** emite abertura na auto-geração via
  exportação (correção aditiva sobre FR-011-008/SPEC-011) — pergunta ao Diretor vai para
  a Entrega desta fatia. SPEC-024 promovida a `Approved` após a correção consolidada.
- 2026-09-14: PLAN-025 redigido pelo `scribe` (cobertura total: 16/16 FRs, 4/4 NFRs, Caso
  D). 13 COMPs, 7 DECs, 8 TRISKs. `plan-validator`: `graph.sh --check` sem `fr-sem-comp`
  real (3 achados `[parse]` são o mesmo padrão tolerado de PLAN-023, componentes de apoio
  com `Realiza` em prosa); `artifact-lint.sh` acusou ERROR `plan-dec-irreversivel-enum` em
  todas as 7 DECs — falso positivo confirmado: o mesmo script produz erro idêntico sobre
  PLAN-023, já `Approved`/entregue (bug de comparação de acentuação "nao" neste ambiente
  Windows) — não bloqueante, candidato a lição de processo na Etapa 4.5. 2 itens vão para
  a Entrega em lote (degrau 2 da escada): (1) DEC-025-001 (Irreversível: sim) — motor de
  PDF escolhido é `pdf-lib` (puro JS/TS, sem template/HTML, sem processo externo — postura
  de segurança por construção; compatível com o teto de 15s/1024MB de `vercel.json`); (2)
  DEC-025-007 — achado do PLAN (não do product-analyst): o mecanismo real herdado de F4
  (`assertRawContentReachable`) restringe a auto-geração da Tira à autoria original,
  tensionando com AC-024-018 (leitura "sem restrição adicional por autoria"); resolvido
  com guarda nova para leitura de material já existente (comum a EDITOR/ADMIN) mantendo a
  auto-geração restrita à autoria de F4 — EDITOR não-autor exportando "tira" de Conteúdo
  cuja Tira nunca foi aberta por ninguém fica recusado (409) até a abertura por quem
  alcança; não testado literalmente por nenhum AC da SPEC. PLAN-025 promovido a `Approved`.
