# SPEC-009: Instrumentação de etapas da fábrica

**Slug**: producao-material
**Jira**: KAN-6
**Jira Story**: KAN-45
**Status**: Approved
**Versão**: 0.2
**Autor**: keelson (scribe)
**Data**: 2026-09-06
**Brief**: BRIEF-009

## 1. Contexto e objetivo

### 1.1 Problema

A fábrica MNEMORA STUDIO opera hoje duas estações reais com tela (Conteúdo bruto e Quebra
da regra — F2, SPEC-005/PLAN-006, entregues) sem qualquer registro de quando cada etapa foi
aberta, concluída ou reaberta. A premissa A-011 (herdada do BRIEF-001, épico MNEMORA
STUDIO) exige que o tempo de produção por página seja instrumentado por etapa — incluindo
retrabalho, revisão e exportação — desde o primeiro módulo, não apenas quando o painel
(F10) existir. Sem um mecanismo de captura hoje, cada conteúdo produzido antes da
instrumentação existir perde o próprio histórico de produção de forma irrecuperável: não
há como reconstruir retroativamente quando uma etapa foi concluída ou reaberta depois do
fato.

### 1.2 Outcome esperado

Cada transição de etapa de produção (abertura, conclusão, retrabalho) das duas estações
existentes passa a gerar um evento append-only e imutável, associado ao conteúdo e ao autor
da mutação que a originou — pronto para as fatias futuras (tira, biblioteca visual,
publicação, versionamento, QC) emitirem eventos do mesmo tipo sem redesenho do mecanismo.
Ao fim desta fatia, todo conteúdo produzido a partir da entrega tem seu histórico de etapa
decomponível — a métrica de negócio (tempo de produção por página) poderá ser calculada
sobre esses dados quando F10 (painel) e F6 (denominador "página") existirem.

**Verificação (gate 9)**: 2026-09-06 — APROVADO (comportamento funcional). Exercitado com execução real contra Postgres de dev (`mnemonicos-db`, container saudável; branch `feat/producao-material-mnemora-studio`, HEAD `c50448e`, `git status` limpo antes e depois do exercício, sem mudança concorrente): (1) `createRawContent` real (não mock) gerou exatamente 3 `ProductionStageEvent` na ordem `sequence` esperada — ABERTURA/CONTEUDO_BRUTO, CONCLUSAO/CONTEUDO_BRUTO, ABERTURA/QUEBRA_DA_REGRA — todos atribuídos ao autor da criação (AC-009-001, AC-009-002, AC-009-008); (2) `updateRawContent` sobre o mesmo Conteúdo bruto gerou 1 evento de RETRABALHO de CONTEUDO_BRUTO — nunca uma 2ª CONCLUSAO (AC-009-004); (3) `saveRuleBreakdown` chamado 2× gerou CONCLUSAO na 1ª chamada e RETRABALHO na 2ª para QUEBRA_DA_REGRA (AC-009-003, AC-009-005); (4) `softDeleteRawContent` marcou `deletedAt` e a contagem de eventos permaneceu em 6 antes e depois — nenhum evento novo, nenhum apagado, todos recuperáveis via `findMany` com os 5 campos de auditoria intactos (AC-009-007, FR-009-008, FR-009-009); (5) superfície HTTP de F2 (`POST`/`GET`/`PATCH`/`DELETE` de `/contents` via `createApp()` + supertest real) devolveu os mesmos status (201/200/200/204) e exatamente os mesmos campos de payload de antes da instrumentação — nenhum campo de evento vazado (AC-009-009/NFR-009-005). 9/9 checks do exercício de mecanismo + 7/7 checks do exercício HTTP, todos aprovados. AC-009-006 (imutabilidade estrutural) e AC-009-010 (fail-secure transacional) não foram re-exercitados ao vivo neste gate — permanecem provados pela suíte automatizada (tripwire estrutural + mock de falha forçada) já rodada nas waves anteriores; não fazem sentido como exercício ao vivo sem sabotar o processo (Charter Art. 8). Dados de fixture (usuário, disciplina, tema, Conteúdo bruto, sessão) criados e removidos ao final — banco de dev restaurado ao estado anterior, confirmado por contagem residual = 0. Sem UI nesta fatia (A-009-004/NFR-009-005) — `gates.screenVerify` não se aplica; item (b) da medição observacional da §1.3 (razão de eventos por criação/salvamento na janela de Entrega) fica para a inspeção humana do relatório de Entrega, como já declarado.

### 1.3 Métrica de sucesso

Esta SPEC é infraestrutura de captura, não uma capacidade de produto com métrica de negócio
própria e prazo. O outcome verificável desta fatia é qualitativo e binário: toda transição
elegível das 2 estações (abertura/conclusão de Conteúdo bruto; abertura/conclusão/retrabalho
de Quebra da regra; retrabalho de Conteúdo bruto) emite exatamente 1 evento correspondente,
sem exceção e sem perda — e nenhum caminho do sistema edita ou apaga um evento já emitido.
A métrica de negócio que esta captura sustenta ("tempo de produção por página") pertence à
SPEC de F10 (painel), quando o denominador "página" existir (depende de F6) — não é
antecipada aqui.

**Fonte de medição**: (a) externa — suíte de teste que prova os 5 gatilhos de emissão
(criação de Conteúdo bruto, edição de Conteúdo bruto, 1º salvamento e salvamentos
subsequentes da Quebra da regra, soft-delete) mais o tripwire de append-only (nenhum
caminho de update/delete sobre um evento já emitido) — natureza conformidade
(verde/vermelha), executada pelo comando de qualidade local do projeto (`quality.test` da
ficha; não há pipeline de CI configurado nos 2 repos — RISK-006-009, INDEX); dono: time de
engenharia. (b) observacional — nº de eventos de etapa emitidos vs. nº de Conteúdos
brutos/Quebras da regra produzidos pela tela na janela, com a razão esperada declarada
(cada criação de Conteúdo bruto emite 3 eventos: abertura+conclusão de "Conteúdo bruto" e
abertura de "Quebra da regra"; cada 1º salvamento de Quebra soma 1 evento de conclusão) —
apurado por inspeção humana no relatório de Entrega, mesma natureza do item (b) da §1.3 de
SPEC-005. Prazo: Entrega de F3.

## 2. Personas e jobs-to-be-done

Como gestor/ADMIN da fábrica (consumidor futuro, via F10), preciso que o tempo gasto em
cada etapa de produção — incluindo retrabalho — esteja registrado desde o primeiro
conteúdo produzido, para que o cálculo de tempo por página (F10) tenha histórico completo
e não um buraco anterior à própria existência da instrumentação.

Anti-persona (herdada, reforçada nesta fatia — decisão 4.98): não é para o EDITOR/ADMIN
operarem ou consultarem hoje — não há tela nova nesta fatia (A-009-004); e não é, como em
todo o produto, para o estudante, que segue fora de qualquer superfície da fábrica.

## 3. Glossário (Ubiquitous Language)

| Termo | Definição | Origem |
|-------|-----------|--------|
| Evento de etapa de produção | Registro append-only e imutável de uma transição (abertura, conclusão ou retrabalho) de uma etapa de produção para um conteúdo, atribuído ao autor da mutação que a originou | BRIEF-009 |
| Etapa de produção | Estação do fluxo de fábrica que produz ou transforma o material; nesta fatia, as 2 com tela hoje (Conteúdo bruto, Quebra da regra) — fatias futuras (tira, biblioteca visual, publicação, versionamento, QC) adicionam novas etapas ao mesmo mecanismo | BRIEF-009 (herda A-011, BRIEF-001) |
| Abertura (de etapa) | Evento que marca o início observável de uma etapa para um conteúdo | BRIEF-009 |
| Conclusão (de etapa) | Evento que marca o 1º fechamento de uma etapa para um conteúdo — não se repete; a 2ª vez em diante é retrabalho | BRIEF-009 |
| Retrabalho | Evento que marca qualquer edição de uma etapa já concluída, após a conclusão ter sido registrada | BRIEF-009 |
| Conteúdo bruto | Texto normativo colado + disciplina + tema/assunto + classe do radar de prova; a primeira estação da linha de produção (reusado, não redefinido) | SPEC-005 |
| Quebra da regra | Decomposição do texto normativo bruto nos cinco blocos, mais a síntese da regra; 1:1 com o Conteúdo bruto (reusado, não redefinido) | SPEC-005 |

## 4. Escopo

### 4.1 In-scope

- Mecanismo genérico e extensível de evento de etapa de produção — append-only, nunca
  editado ou apagado.
- Emissão de evento de abertura e de conclusão da etapa "Conteúdo bruto" (evento único
  simultâneo, gerado na criação — A-009-008).
- Emissão de evento de abertura da etapa "Quebra da regra" (gerado na criação do Conteúdo
  bruto, antes de qualquer Quebra salva) e de evento de conclusão distinto (gerado no
  primeiro salvamento bem-sucedido da Quebra).
- Emissão de evento de retrabalho quando uma etapa já concluída é reaberta ou reeditada:
  edição de um Conteúdo bruto após sua conclusão já registrada; novo salvamento da Quebra
  da regra após sua conclusão já registrada.
- Persistência, em cada evento, de: o conteúdo a que se refere, o autor da mutação, o tipo
  de etapa, o tipo de transição e o instante do registro.
- Sobrevivência do evento à remoção reversível (soft-delete) do conteúdo a que se refere.
- Recuperabilidade interna dos eventos de um conteúdo, em ordem cronológica (par de leitura
  do mecanismo — sem expor rota, endpoint ou tela).

### 4.2 Out-of-scope

- Painel/dashboard de produção e cálculo de "tempo de produção por página" — quem lê
  "instrumentação" assumiria o painel junto; fica para F10 (falta o denominador "página",
  que só F6 define).
- Qualquer tela nova de leitura/consulta dos eventos para o EDITOR/ADMIN — o mecanismo
  escreve; não expõe superfície de consulta HTTP ou UI nesta fatia (A-009-004).
- Rota HTTP dedicada para emitir o evento manualmente, ou qualquer gatilho explícito do
  usuário na interface — a emissão é efeito colateral do fluxo que já muda o estado de
  Conteúdo bruto/Quebra da regra, nunca uma ação nova (A-009-005). Por não haver ação nova
  de UI, a regra dos três estados observáveis (decisão 4.67) não se aplica a esta SPEC.
- Instrumentação das etapas de revisão jurídica e exportação (F8/F9/F6) — essas telas
  ainda não existem; o mecanismo comporta os tipos depois, sem migração dedicada
  (A-009-006).
- Instrumentação de etapas de fatias de conteúdo ainda não construídas (tira — F4,
  biblioteca visual — F5, publicação — F6, versionamento — F8, QC — F9) — mesmo motivo:
  as telas que as produziriam não existem hoje.
- Emissão de evento pela remoção (soft-delete) de um Conteúdo bruto — a remoção não é uma
  transição do mecanismo de etapas (A-009-009); o histórico já emitido sobrevive
  (A-009-002), mas o ato de remover em si não gera evento novo.
- Qualquer contexto de auditoria de segurança no payload do evento (endereço IP,
  user-agent, diff de campos alterados) — payload mínimo de instrumentação (A-009-007);
  log de segurança pertence a outra capacidade (Auditoria de autenticação, já existente,
  SPEC-002).
- Trilha do que mudou em cada edição (diff de campos, histórico de versão do texto) — isso
  é F8 (versionamento editorial). F3 registra APENAS que uma transição ocorreu
  (abertura/conclusão/retrabalho), nunca o conteúdo antes/depois; A-009-007 já proíbe diff
  de campos no payload.
- Emissão de evento pela semente/importação em lote de conteúdo — grava direto no banco,
  fora do service instrumentado (A-009-011); gap declarado, não silencioso.

## 5. Requisitos funcionais (EARS)

- **FR-009-001** [MUST] Quando um Conteúdo bruto for criado, o sistema deve registrar um
  evento de abertura e um evento de conclusão da etapa "Conteúdo bruto" para aquele
  conteúdo, atribuídos ao autor da criação.
- **FR-009-002** [MUST] Quando um Conteúdo bruto for criado, o sistema deve registrar
  também um evento de abertura da etapa "Quebra da regra" para aquele conteúdo — a etapa
  se torna disponível a partir da existência do Conteúdo bruto, antes de qualquer Quebra
  salva.
- **FR-009-003** [MUST] Quando a Quebra da regra de um Conteúdo bruto for salva pela
  primeira vez, o sistema deve registrar um evento de conclusão da etapa "Quebra da regra"
  para aquele conteúdo.
- **FR-009-004** [MUST] Se um Conteúdo bruto já existente for editado depois de o evento de
  conclusão da etapa "Conteúdo bruto" já ter sido registrado, então o sistema deve
  registrar um evento de retrabalho da etapa "Conteúdo bruto" — nunca um novo evento de
  conclusão.
- **FR-009-005** [MUST] Se a Quebra da regra de um Conteúdo bruto for salva novamente
  depois de o evento de conclusão da etapa "Quebra da regra" já ter sido registrado, então
  o sistema deve registrar um evento de retrabalho da etapa "Quebra da regra" — nunca um
  novo evento de conclusão.
- **FR-009-006** [MUST] O sistema deve associar a cada evento de etapa de produção: o
  conteúdo a que se refere, o autor da mutação que o originou, o tipo de etapa (Conteúdo
  bruto | Quebra da regra), o tipo de transição (abertura | conclusão | retrabalho) e o
  instante do registro — sem contexto adicional.
- **FR-009-007** [MUST] O sistema deve manter todo evento de etapa de produção imutável
  após seu registro — nenhum fluxo do sistema pode editar ou apagar um evento já emitido.
- **FR-009-008** [MUST] Enquanto um Conteúdo bruto permanecer removido (soft-delete), os
  eventos de etapa já registrados para ele devem permanecer recuperáveis — a remoção não
  apaga nem invalida o histórico já emitido.
- **FR-009-009** [MUST] Se um Conteúdo bruto for removido (soft-delete), então o sistema
  não deve registrar nenhum evento de etapa relativo ao ato de remoção — remoção não é uma
  transição do mecanismo de etapas.
- **FR-009-010** [MUST] O sistema deve manter os eventos de etapa de um conteúdo
  recuperáveis, em ordem determinística de registro — capacidade de leitura interna pura
  (recuperar a lista de eventos de um conteúdo, ordem determinística, sem nenhum cálculo,
  soma, duração ou agregação), sem expor rota, endpoint ou tela nesta fatia.

## 6. Requisitos não-funcionais

- **NFR-009-001** [MUST] O mecanismo de evento de etapa de produção DEVE comportar tipos de
  etapa adicionais (tira, biblioteca visual, publicação, versionamento, QC) para fatias
  futuras sem exigir alteração estrutural dedicada a cada fatia nova.
- **NFR-009-002** [MUST] A emissão do evento de etapa DEVE ser atômica em relação à mutação
  de negócio que a origina — falha ao registrar o evento impede a mutação principal de ser
  considerada bem-sucedida, e vice-versa.
- **NFR-009-003** [MUST] Todo evento de etapa de produção, uma vez registrado, DEVE
  permanecer imutável e sobreviver à remoção reversível (soft-delete) do conteúdo a que se
  refere — nenhuma exclusão em cascata.
- **NFR-009-004** [SHOULD] O payload do evento de etapa de produção SHOULD conter somente
  os campos mínimos de auditoria (quem, quando, qual conteúdo, qual etapa, qual transição)
  — sem dado de contexto adicional que amplie a superfície de dado sensível.
- **NFR-009-005** [MUST] O mecanismo de evento de etapa de produção DEVE ser invisível à
  superfície de contrato já entregue de F2 — nenhuma resposta HTTP, rota ou comportamento
  de tela de Conteúdo bruto/Quebra da regra muda (novo campo, novo erro observável ao
  usuário, latência perceptível) em razão da instrumentação.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-009-001** (cobre FR-009-001)
  Dado um EDITOR criando um novo Conteúdo bruto com todos os campos obrigatórios
  preenchidos, quando a criação é concluída com sucesso, então o sistema registra um
  evento de abertura e um evento de conclusão da etapa "Conteúdo bruto" para aquele
  conteúdo, atribuídos ao autor da criação.

- **AC-009-002** (cobre FR-009-002)
  Dado um Conteúdo bruto recém-criado sem Quebra da regra salva, quando a criação é
  concluída, então o sistema registra um evento de abertura da etapa "Quebra da regra"
  para aquele conteúdo.

- **AC-009-003** (cobre FR-009-003)
  Dado um Conteúdo bruto sem Quebra da regra salva anteriormente, quando a Quebra é salva
  pela primeira vez, então o sistema registra um evento de conclusão da etapa "Quebra da
  regra" para aquele conteúdo.

- **AC-009-004** (cobre FR-009-004)
  Dado um Conteúdo bruto cuja etapa "Conteúdo bruto" já tem evento de conclusão
  registrado, quando o EDITOR ou ADMIN edita esse Conteúdo bruto, então o sistema registra
  um evento de retrabalho da etapa "Conteúdo bruto" e nenhum novo evento de conclusão é
  gravado.

- **AC-009-005** (cobre FR-009-005)
  Dado um Conteúdo bruto cuja Quebra da regra já tem evento de conclusão registrado,
  quando a Quebra é salva novamente (edição de qualquer bloco), então o sistema registra
  um evento de retrabalho da etapa "Quebra da regra" e nenhum novo evento de conclusão é
  gravado.

- **AC-009-006** (cobre FR-009-006, FR-009-007)
  Dado qualquer evento de etapa de produção já registrado, quando se tenta alterá-lo ou
  removê-lo por qualquer fluxo do sistema, então nenhuma operação disponível permite a
  alteração — o evento permanece com todos os campos (conteúdo, autor, etapa, transição,
  instante) intactos.

- **AC-009-007** (cobre FR-009-008, FR-009-009)
  Dado um Conteúdo bruto com eventos de etapa já registrados, quando esse conteúdo é
  removido (soft-delete), então os eventos já emitidos permanecem recuperáveis e nenhum
  evento novo de etapa é gravado em razão da remoção.

- **AC-009-008** (cobre FR-009-010)
  Dado um conjunto de eventos de etapa registrados para um mesmo conteúdo em momentos
  distintos, quando eles são recuperados por consulta interna, então retornam em ordem
  cronológica de registro com todos os campos persistidos — e, dado dois ou mais eventos
  registrados no mesmo instante (caso que esta própria SPEC produz sempre: FR-009-001 gera
  abertura e conclusão de "Conteúdo bruto" simultâneas, FR-009-002 acrescenta a abertura de
  "Quebra da regra" na mesma criação), quando eles são recuperados, então a ordem retornada
  é determinística e estável entre consultas repetidas, preservando a sequência de emissão
  (abertura "Conteúdo bruto" → conclusão "Conteúdo bruto" → abertura "Quebra da regra"),
  mesmo com timestamp idêntico — o mecanismo técnico do desempate (sequência monotônica,
  coluna de ordenação) é decisão do PLAN, não desta SPEC.

- **AC-009-009** (cobre NFR-009-005)
  Dado o fluxo de criação/edição de Conteúdo bruto e de salvamento da Quebra da regra já
  entregues em F2, quando a instrumentação de etapa é adicionada, então nenhuma resposta
  HTTP, campo de payload ou comportamento de tela observável pelo EDITOR/ADMIN muda em
  relação ao comportamento de F2.

- **AC-009-010** (cobre NFR-009-002)
  Dado que o registro do evento de etapa falha por qualquer motivo, quando a mutação de
  negócio (criação/edição de Conteúdo bruto, salvamento da Quebra da regra) está em
  andamento, então a mutação inteira é revertida (nenhum estado meio-salvo) e o sistema
  informa um erro genérico — nunca um sucesso parcial em que o conteúdo mudou mas o evento
  não foi registrado, nem o inverso.

## 8. Premissas e decisões prévias

- **A-009-001** [assumido] [evidência: crença] "Etapa" nesta fatia = as 2 estações com tela
  hoje (Conteúdo bruto, Quebra da regra) — P-01, BRIEF-009. A forma técnica de extensão
  (enum ampliável, valor livre, tabela de tipos) é decisão do PLAN, não desta SPEC; aqui
  fica só a garantia funcional de que novas etapas não exigirão redesenho (NFR-009-001).
- **A-009-002** [assumido] [evidência: crença] O evento é append-only e sobrevive à
  remoção reversível (soft-delete) do conteúdo a que se refere — P-02, BRIEF-009. É dado
  de instrumentação, não estado de negócio do conteúdo: nunca é removido junto.
- **A-009-003** [assumido] [evidência: crença] Fronteira do retrabalho — P-03, BRIEF-009,
  concretizada nas 2 estações: em "Conteúdo bruto", qualquer atualização após a criação
  (que já é a própria conclusão, A-009-008) conta como retrabalho; em "Quebra da regra",
  qualquer novo salvamento após já existir conclusão registrada conta como retrabalho. Não
  distingue campo periférico de campo central da mutação.
- **A-009-004** [assumido] [evidência: crença] Sem UI de consumo nesta fatia — P-04,
  BRIEF-009: nenhuma tela nova de leitura ou relatório para EDITOR/ADMIN.
- **A-009-005** [assumido] [evidência: observação] A emissão do evento é efeito colateral do
  mesmo fluxo que já muda o estado de Conteúdo bruto/Quebra da regra — P-05, BRIEF-009
  (mnemonicos-backend/src/modules/contents/contents.service.ts:1-408). Nenhuma rota nem
  tela nova é introduzida para produzi-la; sem gatilho explícito do usuário.
- **A-009-006** [assumido] [evidência: crença] Revisão e exportação (fatias futuras
  F8/F9/F6) ficam fora do que é emitido nesta fatia — P-06, BRIEF-009. O mecanismo é
  desenhado para acomodá-las depois, sem migração dedicada.
- **A-009-007** [assumido] [evidência: crença] Payload do evento é mínimo: quem (autor da
  mutação), quando (instante do registro), qual conteúdo, qual etapa e qual transição —
  sem contexto adicional (endereço IP, user-agent, diff de campos). É auditoria mínima de
  instrumentação, não log de segurança.
- **A-009-008** [assumido] [evidência: observação] "Conclusão" da etapa "Conteúdo bruto"
  coincide com sua criação — evento único de abertura+conclusão simultânea: não há hoje
  botão de "concluir" nem rascunho parcial (`createRawContent` já exige todos os campos
  obrigatórios preenchidos —
  mnemonicos-backend/src/modules/contents/contents.service.ts:85-102). Já a etapa "Quebra
  da regra" tem abertura observável (criação do Conteúdo bruto sem Quebra ainda) e
  conclusão distinta (1º `upsert` bem-sucedido —
  mnemonicos-backend/src/modules/contents/contents.service.ts:385-408): dois eventos, não
  um.
- **A-009-009** [assumido] [evidência: observação] Remoção (soft-delete) de um Conteúdo bruto
  não é uma etapa nem retrabalho — está fora do fluxo de etapas
  (`softDeleteRawContent` — mnemonicos-backend/src/modules/contents/contents.service.ts:176-187).
  O dado de instrumentação já emitido sobrevive (A-009-002), mas o ato de remover em si não
  emite evento novo.
- **A-009-010** [assumido] [evidência: crença] A emissão do evento é atômica em relação à
  mutação de negócio que a origina (mesma unidade transacional): falha ao registrar o
  evento impede a mutação principal de ser considerada bem-sucedida — e a mutação é
  revertida por inteiro (fail-secure, AC-009-010), nunca um estado meio-salvo. Default
  escolhido porque A-011 exige completude do histórico desde o primeiro módulo — uma
  lacuna silenciosa (evento perdido, mutação principal com sucesso) violaria essa garantia.
  Reabrir se: o custo de sempre exigir a mesma transação se mostrar caro na implementação
  (o PLAN decide o mecanismo técnico).
- **A-009-011** [assumido] [evidência: observação] A semente de dados (Obrigação
  Tributária, já entregue em F2) grava `RawContent`/`RuleBreakdown` diretamente via Prisma
  em `mnemonicos-backend/prisma/seed-material.ts`, sem passar pelo service instrumentado
  (P-05, A-009-005) — logo não emite evento de etapa. Gap declarado, não silencioso: a
  série de instrumentação nasce vazia para o acervo semeado, só acumula a partir de
  produção real pela tela — mesma natureza do gap já registrado na §1.3 de SPEC-005
  ("produzidos pela tela, não pela semente").
- **A-009-012** [assumido] [evidência: crença] Default aplicado a uma escalação do PO
  (Diretor decide em lote na Entrega, mas o ciclo segue por este default): a série
  capturada por esta fatia mede **tempo de calendário (lead time) por etapa**, não esforço
  de produção — a etapa "Conteúdo bruto" tem duração estruturalmente zero
  (abertura+conclusão simultâneas, A-009-008) e o intervalo até a Quebra mistura fila com
  trabalho. Medir esforço exigiria marcador de início observável (tela nova), que P-04/P-05
  excluem nesta fatia. Reabrir se: o Diretor, na Entrega, decidir que esforço (não lead
  time) é o que A-011 exige — nesse caso abre fatia nova com tela de "iniciar etapa", esta
  SPEC permanece correta para o que capturou.

## 9. Riscos e questões abertas

- **RISK-009-001** O payload mínimo (A-009-007) pode se mostrar insuficiente quando F10
  precisar decompor retrabalho por sub-causa (ex.: qual campo mudou) — dado já emitido não
  guarda diff, e reconstrução retroativa não será possível. Mitigação: aceito nesta fatia
  como auditoria mínima, não log de mudança; se F10 precisar de granularidade maior, o gap
  só se soma para eventos futuros, sem completar o passado.
- **RISK-009-002** Sem painel nem consumo nesta fatia, um evento não emitido ou emitido
  com o tipo errado pode passar despercebido até F10 expor os dados. Mitigação: cobertura
  de teste dos 5 gatilhos (criação, edição de Conteúdo bruto, 1º salvamento e salvamentos
  subsequentes da Quebra, soft-delete) é condição de pronto desta fatia, não opcional.
- **Q-009-001** Quando F10 (painel) for especificado, a métrica de "tempo de produção por
  página" precisará decidir se o tempo de retrabalho conta no numerador do tempo de
  produção ou é reportado separadamente. Esta SPEC só garante que o dado existe; a fórmula
  fica para a SPEC de F10.
- **Q-009-002** Um conteúdo cuja etapa "Quebra da regra" abre mas nunca conclui (e pode ser
  removido antes de concluir) é sinal de backlog/WIP que F10 deve reportar, ou ruído a
  excluir da série? Nenhum dado se perde nos dois caminhos (a abertura órfã fica gravada; o
  `deletedAt` do Conteúdo bruto pai é consultável); a escolha é fórmula de painel, decidida
  quando F10 for especificada — não decidida aqui, por ser agregação (Pedido do brief a
  proíbe nesta fatia).

## 10. Fora deste documento

Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e
`/keelson:tasks`.
