# BRIEF-030: Controle de qualidade e gate de versão aprovada

**Slug**: producao-material
**Status**: Emitido
**Data**: 2026-09-27
**Largada**: 2026-09-27T09:14:48-0300
**SPEC**: SPEC-030
**Epico**: docs/producao-material/briefs/BRIEF-2026-08-27-mnemora-studio-epic.md

## Pedido como dito

> Fatia 9 da fila do épico MNEMORA STUDIO: "Controle de qualidade e gate de versão
> aprovada" — depende de F1 (acesso/papéis) e F8 (versionamento editorial), ambas
> entregues e mergeadas. Confirmado pelo Diretor via `/keelson:continue` como próxima
> elegível.

## Interpretação do PO

**Contexto**: F8 (SPEC-028) criou `ContentVersion` (fechamento imutável, append-only,
com `authorId`, `legislativeClosureDate`, `contentSnapshot`) — o PDF sai marcado como
*rascunho* até existir um carimbo oficial. RISK-002-001 (aberto desde F1/SPEC-002) já
nomeia a pendência que esta fatia resolve: "a fatia F9 decide se separa o papel de
revisor jurídico do ADMIN e adiciona uma checagem de segregação de funções aplicada
pelo sistema" — sem isso, o gate de "Versão aprovada" fica só em disciplina
operacional, o defeito fail-open que o próprio épico nomeia como risco central desta
fatia.

**Pedido**: dar à `ContentVersion` um estado de aprovação (rascunho → aprovada) —
o "carimbo oficial" que F6/F8 prometeram e ainda não existe — com (a) um checklist de
controle de qualidade jurídica/pedagógica que precisa estar satisfeito antes da
aprovação (TAP §4.4: fonte oficial, extração, estruturação, tira, checagem jurídica,
checagem pedagógica, publicação — mais o registro de fechamento de legislação,
legislação considerada, número de versão e histórico, já cobertos por F8) e (b) a
segregação de funções **aplicada pelo sistema**: quem aprova não pode ser quem fechou
a versão (`authorId`) — decisão confirmada pelo Diretor na última chamada
(AskUserQuestion, 2026-09-27): "Aplicar por sistema (recomendado)" — bloqueio
fail-secure, não disciplina operacional. Só a versão **aprovada** pode sair como PDF
oficial (F6 segue emitindo rascunho para o resto).

**Premissas decididas**:
- A-030-001 `[assumido]` O checklist de qualidade é um conjunto de itens verificáveis
  vinculados à `ContentVersion` (não ao `RawContent` mutável) — travados pelo mesmo
  motivo append-only de F8 (DEC-029-003): mudar o conteúdo depois do fechamento não
  pode alterar retroativamente um checklist já satisfeito.
- A-030-002 `[assumido]` Segregação de funções por sistema: `approvedById != authorId`
  da mesma `ContentVersion`. Não introduz papel novo no `UserRole` enum — reaproveita
  ADMIN/EDITOR existentes (RISK-002-001 apontava "separar o papel de revisor" como uma
  alternativa; a mais simples e reversível é checar identidade do ator, não criar
  papel) — mecanismo exato (rota/campo) é decisão do PLAN.
- A-030-003 `[assumido]` "Versão aprovada" é terminal e append-only na mesma lógica de
  F8: uma vez aprovada, não há reversão por edição — revogar exige nova versão
  (`ContentVersion` nova), nunca mutação da aprovada.

**Fora de escopo**: reabertura de F6 (pipeline de PDF já emite rascunho e variante
resumo); papel de revisor jurídico dedicado no `UserRole` (RISK-002-001 aceita a
alternativa mais simples); calendário/fila editorial (F11, fora do MVP); painel
estratégico (F10, fatia seguinte, parcialmente dependente desta).

## Fora de escopo
(ver acima)

## Estimativa

- **Base**: pedido (BRIEF-030 com A-030-001..003) · INDEX de producao-material
  (PLAN-029/F8 com 4 tasks e 3 waves, PLAN-027/F7 com 8/7, PLAN-025/F6 com 14;
  histórico de re-gates por wave) · MAP (território de `content-versions/` e
  `publication/`) · `model ContentVersion` no schema · ficha (security, review e
  screenVerify ativos; mutation/e2e nulos) · calibração: sem base histórica (1 demanda
  fechada em `estimates.md`, abaixo do mínimo de 3)
- **Dimensão**: ~4 waves · ~6 tasks (~2 small · ~4 medium)
- **Por fase**: forja 0–1h · artefatos 2–5h · implementação 8–30h · gates 5–14h
- **Total**: 15–50h (horas de ciclo, não prazo de calendário)
- **Confiança**: média. F8 já abriu quase todo o terreno (model, lock de linha, diff
  pós-fechamento, carimbo no PDF). A incerteza está na forma do checklist e na fonte
  do PDF oficial. Os gates de security e design pesam: em F7/F8 toda wave precisou de
  retry.
- **Premissas**: checklist com os 7 itens fixos da TAP §4.4 (enum, não configurável),
  persistido por `ContentVersion` e atestado no ato de aprovar, sem estado incremental
  por item · aprovador é ADMIN (glossário SPEC-002), segregação por identidade
  `approvedById != authorId`, sem papel novo, recusa fail-secure no servidor ·
  aprovação terminal, sem revogação (A-030-003), com a corrida de aprovação dupla
  fechada pelo lock que F8 já usa · PDF oficial só quando a versão vigente está
  aprovada e sem alteração depois do fechamento (reusa `versioned-content-diff`); nos
  outros casos sai rascunho, sem variante nova nem mudança estrutural no pipeline F6 ·
  1 migração aditiva (pergunta ao Diretor antes de executar) mais 1 valor aditivo no
  `ProductionStageType` · `domain.ts` e `types.ts` sincronizados no mesmo diff · rotas
  novas entram na `route-authz-matrix` · gates esperados: review, security (authz,
  segregação de funções, A01/A06/A08/A10), qa com screenVerify, design (UI de
  checklist e aprovação), performance leve ou n/a (o caminho do PDF só ganha um
  predicado)
- **Lacunas**: (1) Checklist incremental (item marcado por alguém numa data,
  desmarcável antes de aprovar) ou atestado único no ato de aprovar? Incremental soma
  ~1 medium e mais superfície de UI e de gate. Default: atestado único. (2) Quem
  aprova: só ADMIN, ou também EDITOR que não seja o autor? Muda a matriz de authz e os
  testes. Default: só ADMIN. (3) O PDF oficial mostra o conteúdo atual ou o
  `contentSnapshot` da versão aprovada? Com snapshot, parte do composer precisa ser
  reescrita (+1–2 medium). Default: conteúdo atual, oficial só sem alteração
  pós-fechamento. (4) Existem 2+ contas internas ativas para o qa percorrer o fluxo
  real de segregação? Hoje a operação é de 1 pessoa (risco F9 do épico, A-010). Se não
  houver, o gate 9 de aprovação fecha como `pendente_handoff`.

## Cronologia
- largada: 2026-09-27T09:14:48-0300
- specify: 2026-09-27T09:50:09-0300 · correções: 2 · classes: spec-out-of-scope-vazio(1, formato — numerado em vez de bullet) · spec-ac-fora-gwt(1) · spec-ears-nao-casa(1) · mérito: product-analyst REVISAR_ANTES_DE_APROVAR (3 achados ancorados) · po ESCALAR (1 escalação não-bloqueante, default aplicado) · pacote de correção do po aplicado pelo scribe em modo reescrita (v0.1→v0.2)
- plan: 2026-09-27T10:12:26-0300 · correções: 2 · classes: fr-sem-comp(2, campo Realiza quebrado em 3 linhas escondia FR-030-013/017/018) · nao-parseavel(1, campo Dependências com anotação extra) · cobertura 18/18 FRs + 3/3 NFRs, gap 0 · 5 WARNING plan-dec-alternativa-unica aceitos (mesmo padrão de PLAN-029)
- tasks: 2026-09-27T10:46:39-0300 · correções: 1 · classes: task-criterio-grep-nao-ancorado(1, endurecido com exclusão de comentário — resto aceito, precedente TASK-029-002 Done) · 7 TASKs/5 waves, graph.sh --check --stage=tasks --plan 031: 0 ERROR · qa pré-código: sem achados bloqueantes
- pausa: 2026-09-29T18:25:08-0300 · sessão b1505f46@auto-avaliar-Latitude-3550 · ponto: Wave 2 de PLAN-031 com codigo aprovado (gates 1-7/8/10/11); falta gate 9 da FEAT-030-002 (qa interrompido por limite de uso) e closure de TASK-031-003/005 · motivo: limite de uso atingido; Diretor pediu para salvar e parar
