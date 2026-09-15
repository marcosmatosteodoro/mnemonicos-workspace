# BRIEF-024: Pipeline de publicação — PDF (rascunho)

**Slug**: producao-material
**Status**: Entregue e mergeada — RISK-025-007 aberto, recomendado resolver antes do deploy em produção
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
  cuja Tira nunca foi aberta por ninguém fica recusado (**404, `NotFoundError`** — texto
  original do PLAN dizia 409/ConflictError, corrigido na Wave 3 de TASK-025-008/PLAN-025
  para bater com o comportamento real) até a abertura por quem alcança; não testado
  literalmente por nenhum AC da SPEC. PLAN-025 promovido a `Approved`.
- 2026-09-14: TASKs decompostas via rota fan-out (decisão 4.310 — 13 TASKs previstas,
  1 `scribe` decompositor + 3 `scribe`s redatores em paralelo). `graph.sh --check` limpo
  após 2 correções mecânicas do Tech Lead (campos de aresta `Realiza (FRs)` com
  parênteses/NFR misturado em TASK-025-007/008, quebrando o parser — IDs limpos
  restauram a cobertura). `task-validator`: 2 seções "Riscos específicos" ausentes
  (TASK-025-010/012) e 1 override sem `override-aprovador` (TASK-025-010) corrigidos;
  3 ERRORs `task-criterio-sem-ac` mantidos como `OVERRIDDEN` (calibrados por exemplares
  Done do slug). Rodada consolidada da Etapa 3.5: `qa` (pré-código) achou 1 gap real —
  nenhuma TASK exercitava a leitura de binário real de Associação visual + mapeamento
  WEBP→null (Passo 4 de TASK-025-008, Inclui explícito sem critério correspondente) —
  corrigido com 1 critério novo (AC-024-003, parte publication.service) antes do
  despacho. Jira: 13 sub-tasks criadas sob KAN-107 (KAN-108..120, gancho tasks).
- 2026-09-14: **Waves 1-5 implementadas e fechadas** (10/13 TASKs Done). Wave 1: migração
  aditiva + módulo `publication` (schema/service/routes) + `domain/types.ts`. Wave 2:
  `pdf-composer.ts`/imagem — 3 rodadas reais de gate 8 (decompression bomb PNG →
  bypass por chunk decoy → bypass por IHDR duplicado → convergência num parser
  estrutural único, `walkPngChunks`); RISK-025-001/002 registrados. Wave 3: rota HTTP +
  `assertRawContentExportable` (DEC-025-007); achado de texto PLAN/TASK 409→404
  corrigido (`ec123d6`). Wave 4: barreira de autorização real
  (`requireRole('EDITOR','ADMIN')`+`verifyOrigin`), achado de `route-authz-matrix`
  (exclusão em vez de enumeração, corrigido). Wave 5: mutation `exportPublication`
  (RTK Query, 1º `responseHandler` binário do frontend), 1 retry (ramo morto de parsing
  sem emissor real, removido).
- 2026-09-14: **Wave 6 fechada** — `PublicationExportControl` (3 estados observáveis,
  AC-024-006), 1 retry (gate 11 — estado de sucesso in-page faltando). `qa` (gate 9,
  isolado) achou 2 bloqueios de ambiente: migração de dev não aplicada + componente
  ainda não enxertado em tela nenhuma.
- 2026-09-14/15: **Wave 7 fechada — PLAN-025 completo (13/13 TASKs Done)**: os 2
  enxertos (`content-form.tsx`/TASK-025-012, `mnemonic-strip-board.tsx`/TASK-025-013).
  TASK-025-012: 1 retry (gate 11, posicionamento). TASK-025-013: 2 retries (gate 1-7/11
  — posicionamento, PDF de Tira vazia anunciado como sucesso, RISK-011-008 confirmado e
  corrigido; depois retry textual, narrativa de rodada nos testes). **Etapa 4 (DoD)**:
  suítes completas 1x (backend 353+395, frontend 444, todas verdes); `qa` consolidou
  gate 9 com os 2 enxertos no ar — **PARCIAL**, 2 bloqueios de AMBIENTE (nenhum de
  código): migração de dev ainda pendente + achado NOVO (pool de compilação do
  Turbopack do frontend quebrado, RISK-025-005, fix já commitado `3115fec`, processo em
  execução precisa reiniciar). `HANDOFF-PLAN-025.md` criado com roteiro de
  re-verificação. MAP.md recebeu o delta de F6. 2 lições de processo roteadas ao
  `agile-coach` (LRN-027 `PROPOSTA_DOUTRINA` — handoff-protocol.md 5ª causa nomeada;
  LRN-028 `PROPOSTA_PLUGIN` — autocheck de narrativa-no-código não cobria nome de
  teste) + 2 lições de projeto estendidas (`lessons.md`).
- 2026-09-15: **Etapa 5 (Entrega) — aceitação do `po` contra este BRIEF:
  ACEITA_COM_RESSALVAS.** Todos os itens de premissa decidida e escopo negativo
  correspondidos. 1 ressalva de correspondência real (**R-1**): tela do Conteúdo bruto
  sem a mesma guarda de "Tira vazia" da tela da Tira (Wave 7) — nem UI nem backend
  recusavam. Corrigido via **TASK-025-014** (Wave 8 retroativa): `NothingToExportError`
  (409) no backend + mensagem discriminada no frontend. Gate 1-7 reprovou a 1ª rodada
  por 3 eixos (escopo sem artefato-pai, SPEC contradizendo o código, mensagem falsa ao
  usuário); todos fechados — SPEC-024 emendada (FR-024-017/AC-024-021, **17/17 FRs, 21
  ACs**), TASK-025-014 documentada, mensagem do frontend corrigida. Rodada 2: APROVADO.
  RISK-024-001 elevado (E-2 — decisão do A/B fica para o Diretor) e RISK-025-006
  registrado (E-3 — WEBP/imagem acima do teto nunca aparece no PDF, degradação
  silenciosa, já catalogado em TRISK-025-006). LRN-028 reincidiu (reincidência 1,
  mesma classe, TASK diferente) — mensagem ao mantenedor reforçada, diff inalterado.
  E-4 (audit `pdf-lib` + `npm audit fix` `qs`) fica para o Diretor (comando
  humano-only). Jira: comentário em KAN-107. Escalações em lote para a Entrega:
  migração de dev, reinício do servidor Turbopack, E-2 (A/B), E-4 (audit), 2
  mensagens ao mantenedor (LRN-027/028), staleness de `CLAUDE.md` (`jira.enabled:
  false` desatualizado, ficha real já `true`).
- 2026-09-15: **Gate 10 (performance) rodado** (gap identificado pelo Tech Lead —
  nunca tinha sido despachado, apesar do DoD do PLAN pedir) — REPROVOU com 2
  achados reais medidos: (1) teto de duração inoperante sob composição
  CPU-bound síncrona (timer atrasava 8318ms), **corrigido** (event-loop-yield,
  commits `16bb218`/`6a5af2b`, gate 1-7 aprovado com 2 mutantes reais) —
  resíduo de `doc.save()` sozinho ~3,1s, não eliminado; (2) **RISK-025-007,
  risco real de produção NÃO corrigido**: sem teto cumulativo de custo, Tira
  grande com imagens pode estourar tempo/memória, e o corpo de resposta já
  excede hoje o limite de function serverless da Vercel para Tiras acima de
  ~1 Quadro com imagem de 5MB — escalado ao Diretor, decisão de produto.
  TRISK-025-001 fechado por medição (migração aditiva confirmada sem
  lock/reescrita). Lição de código registrada (`lessons.md` + `node-22.md`
  §10).
- 2026-09-15: **Diretor autorizou e aplicou a migração + reiniciou o
  servidor de dev do frontend.** `qa` exercitou o roteiro completo
  (V1-V3) de `HANDOFF-PLAN-025.md` com ambiente real: **gate 9 VERIFICADO**
  — download real das 2 Variantes nas 2 telas (Conteúdo bruto e Tira),
  gating de Tira vazia confirmado, exatamente 1 evento `ABERTURA` mesmo com
  auto-geração fora do fluxo da UI, falha controlada sem Quebra da regra
  (404 estruturado, nunca 500 cru). `HANDOFF-PLAN-025.md` fechado
  (`status: Concluído`). RISK-025-005 selado. Pendente: RISK-025-007
  (decisão de produto) + E-2/E-4 antes do merge/deploy.
- 2026-09-15: **PRs mergeados pelo Diretor** — PR #7 backend (`5d6b4df`) e
  PR #13 frontend (`b54b6ef`) em `main`. Sync automático de KAN-107 travou
  (mapa `jira.KAN.md` sem Etapas/Colunas promovidas, teto = status atual —
  só comentário aplicado). **Confirmado manualmente com o Diretor que o
  trabalho está 100% concluído** (13/13 sub-tasks Concluído + merge real) —
  transição direta `KAN-107 → Concluído` (id 41) aplicada pelo Tech Lead via
  MCP Atlassian, fora do fluxo automático do `tracker-sync` (que preferiu
  não arriscar por falta de mapa). Epic KAN-106 não tocado (segue "Em
  andamento", correto — restam F7-F11 do épico).
