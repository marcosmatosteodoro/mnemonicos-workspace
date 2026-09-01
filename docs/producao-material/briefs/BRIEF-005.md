# BRIEF-005: Conteúdo bruto, quebra da regra e fonte normativa

**Slug**: producao-material
**Jira**: KAN-6
**Status**: Emitido
**Data**: 2026-09-01
**Largada**: 2026-09-01T01:42:26-03:00
**SPEC**: SPEC-005
**Epico**: docs/producao-material/briefs/BRIEF-2026-08-27-mnemora-studio-epic.md

## Pedido como dito

Fatia 2 da fila do BRIEF épico MNEMORA STUDIO (decomposição do `pm` confirmada pelo
Diretor em 2026-08-27), retomada via `/keelson:continue` em 2026-09-01:

> | 2 | Conteúdo bruto, quebra da regra e fonte normativa | producao-material | pendente |

Dependência: `F2 → F1` (entregue — SPEC-002/PLAN-003, mergeado PR #1).

Risco declarado da fatia (BRIEF épico, seção "Riscos por fatia"), verbatim:

> **F2**: RDR-001 sem decisão (5 classes de radar da TAP × 3 prioridades do mockup) —
> resolver como premissa na SPEC; contrato de API fantasma (`/mnemonics`,
> `/flashcards/due`) já chamado pelo frontend sem existir no backend; tipos de domínio
> fora de sincronia entre os dois repos.

Herança do BRIEF-001 (fábrica interna) — telas do fluxo de produção relevantes a esta
fatia: **Novo Conteúdo** ("colar texto jurídico bruto → disciplina, tema, prioridade →
extrair regra essencial") e **Quebra da Regra** ("blocos CONCEITO → AÇÃO → OBJETO →
CONDIÇÃO → EXCEÇÃO, mais síntese — o modelo da §3.3"). Glossário do BRIEF-001: *Quebra da
regra*, *Radar de prova*, *Fonte normativa*, *Fechamento legislativo*.

## Interpretação do PO

**Contexto.** A fábrica já tem acesso e papéis (F1). Falta a primeira estação da linha de
produção: o EDITOR cola um texto normativo bruto e a fábrica o transforma em estrutura
reutilizável — a *quebra da regra* nos cinco blocos mais a síntese, e a *fonte normativa*
deixando de ser texto livre (`Mnemonic.source`) para virar referência estruturada. Hoje o
schema só tem `Mnemonic` com `hook`/`decoding`/`source` como texto único; o frontend já
chama `/mnemonics` e `/flashcards/due`, que não existem no backend; e os enums de domínio
estão fora de sincronia entre os dois repos.

**Pedido.** (1) Modelar o **conteúdo bruto** — texto jurídico colado + disciplina + tema
+ classe do radar de prova — como entidade da fábrica, com CRUD para o EDITOR/ADMIN
(tela "Novo Conteúdo"). (2) Modelar a **quebra da regra** vinculada ao conteúdo: os
cinco blocos (CONCEITO · AÇÃO · OBJETO · CONDIÇÃO · EXCEÇÃO) mais a síntese da regra
essencial (tela "Quebra da Regra"). (3) Modelar a **fonte normativa** como referência
estruturada (tipo do dispositivo + citação + link opcional), substituindo o `source`
texto livre. (4) Fechar o **contrato de API fantasma**: implementar as rotas reais desta
fatia e sanear as chamadas do frontend que não pertencem a F2. (5) **Sincronizar os
tipos de domínio** (novos enums/interfaces) nos dois repos, no mesmo diff. (6) **A-003**:
trocar o seed para **Obrigação Tributária** (Direito Tributário), o conteúdo do MVP.

**Premissas decididas.**
- **P-01 — RDR-001 resolvido como premissa selada.** O enum canônico do *radar de prova*
  são as **5 classes da TAP** (§3.2 camada 1): `ALTA`, `MEDIA`, `DETALHE`, `EXCECAO`,
  `PEGADINHA` — é o vocabulário do método e o dado persistido no conteúdo bruto. As 3
  prioridades do mockup (Alta / Média / Baixa) são **derivação de apresentação**
  (`ALTA→Alta`; `MEDIA→Média`; `DETALHE|EXCECAO|PEGADINHA→Baixa`), não uma segunda
  dimensão gravada. `[assumido]` `[evidência: crença]` — a SPEC sela; o `product-analyst`
  pode contestar o colapso das três em "Baixa".
- **P-02 — a fábrica estrutura, o humano escreve (A-007).** Nada de extração automática
  por IA/NLP nesta fatia: "extrair regra essencial" da tela é o EDITOR preenchendo os
  campos; a fábrica dá a estrutura, valida e persiste. `[assumido]`
- **P-03 — quebra da regra 1:1 com o conteúdo bruto**, cada bloco um campo de texto; a
  *tira mnemônica como sequência de quadros* é **F4** e não entra aqui (MAP: "F4
  substitui, não estende"). `[assumido]`
- **P-04 — `/flashcards/due` sai.** É consumo do estudante (anti-persona; camadas
  dormentes de A-005) — a chamada `listDueFlashcards` do frontend é removida. `/mnemonics`
  do frontend é realinhada ao contrato real que F2 entrega (nomes de rota definidos na
  SPEC/PLAN — provável `/contents` + `/contents/:id/breakdown`). `[assumido]`
- **P-05 — migração Prisma aditiva** (novos modelos/enums; `Mnemonic.source` texto livre
  preservado até F4 consumir a nova fonte, ou migrado no mesmo passo se a SPEC decidir).
  `prisma migrate dev` gera arquivo versionado revisável no diff da TASK; **a execução da
  migração exige confirmação do Diretor** (regra do projeto) — será perguntada quando a
  wave de schema for alcançada.
- **P-06 — barreira de F1 reusada.** Rotas novas sob `requireRole('EDITOR','ADMIN')`,
  árvore plana, `verifyOrigin` nas mutações, declaração em `ROUTE_ROLES` na montagem —
  sem reconstruir acesso. `CardState`/`Review`/scheduler/`study-slice` seguem dormentes.

**Fora de escopo.**
- Tira mnemônica como quadros ordenados (F4); biblioteca visual (F5); pipeline de PDF
  (F6); contraste/pegadinha como entidade lado-a-lado (F7 — mesmo que "pegadinha" seja
  classe do radar aqui); versionamento editorial e fechamento legislativo como histórico
  (F8 — nesta fatia a fonte normativa é só referência estruturada, sem trilha de versão).
- Instrumentação de tempo por etapa da fábrica (F3).
- Extração automática de regra / NLP / IA (P-02).
- Qualquer tela ou rota voltada ao estudante; `/flashcards/due` (P-04).
- Painel/dashboard de produção (F10).

## Estimativa

> Bloco do agent `estimator` na largada (2026-09-01). Best-effort, informa — não decide rota nem escopo.
> Sem calibração medida (`guidelines/project/estimates.md` não existe); F1 usada só como referência qualitativa.

- **Dimensão**: ~6–7 waves · ~13 tasks (~5 small · ~8 medium), dominante `medium`.
- **Fatias verticais prováveis**: schema+migração aditiva & espelho de tipos cross-repo · Zod+service de
  conteúdo bruto · service de quebra da regra + fonte normativa · rotas+montagem `requireRole`/`verifyOrigin`
  + extensão da `route-authz-matrix` · seed Obrigação Tributária + saneamento do contrato fantasma no `api.ts`
  · tela Novo Conteúdo · tela Quebra da Regra.
- **Por fase**: forja 0,5–1,5 h · artefatos 3–6 h · implementação 18–40 h · gates 10–22 h.
- **Total**: 32–70 h de ciclo (não prazo de calendário). **Confiança**: média — dispersão dominada pela
  taxa de retry do gate 8 (em F1 reprovou em 5 das 7 waves, 2× batendo o teto 4.88).
- **Lacunas apontadas** (resolvidas como default na SPEC, revisáveis): CRUD completo de conteúdo bruto
  (create/list/detail/update/delete) · `Mnemonic.source` texto livre **preservado** até F4 (sem backfill
  destrutivo) · fonte normativa **embutida** na referência por conteúdo (não entidade reutilizável) ·
  navegação à Quebra da Regra pela lista de conteúdos · gate 9 tentado **local** (ADMIN semeado desde
  2026-09-01) · MET-002-001 repassado ao Diretor na Entrega.

## Cronologia

- largada: 2026-09-01T01:42:26-03:00
- specify: 2026-09-01T02:30:00-03:00 · correções: 2 · classes: spec-fr-sem-deve(1) · janelas: redação 8min/436l · correção 7min/546l
