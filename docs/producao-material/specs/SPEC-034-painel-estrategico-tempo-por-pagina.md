# SPEC-034: Painel estratégico e tempo por página

**Slug**: producao-material
**Jira**: KAN-165
**Status**: Approved
**Versão**: 0.2
**Autor**: keelson (scribe)
**Data**: 2026-09-30
**Brief**: BRIEF-034

## 1. Contexto e objetivo

### 1.1 Problema

Desde F3, a fábrica grava um evento append-only por etapa de produção — eventos de etapa
de produção com 8 etapas (Conteúdo bruto, Quebra da regra, Tira mnemônica, Associação
visual, Material de reforço, Versão editorial, Aprovação da versão, Publicação PDF), cada
um com abertura/conclusão/retrabalho, ator e instante — e ninguém lê esses dados: não há
consumidor, rota nem tela. A TAP nomeia **tempo de produção por página** como a métrica
que decide se o modelo de fábrica escala para os módulos futuros, e não mede. F8/F9
acrescentaram Versão editorial e Aprovação, mas o retrato de conclusão por módulo e de
backlog também não existe em lugar nenhum além de inspeção manual do banco. A página
inicial da área interna segue como placeholder desde F1.

### 1.2 Outcome esperado

A fábrica passa a enxergar, num único Painel estratégico e a partir só do que ela já
mede sozinha (sem depender de venda, beta ou instrumento novo fora desta fatia): tempo
de produção por página por Conteúdo e por etapa, conclusão por módulo, correções após
revisão (retrabalho pós-fechamento de Versão) e o backlog de produção de Conteúdos ainda
sem Versão aprovada — permitindo decidir sobre a escala do modelo sem inspeção manual do
banco.

### 1.3 Métrica de sucesso

Em até 4 semanas após o deploy em produção, ao menos 1 Conteúdo do módulo piloto
(Obrigação Tributária) criado pelo fluxo instrumentado exibe tempo por página medido no
Painel, e o Painel exibe, por Módulo e para a fábrica, a cobertura (Conteúdos com
medida / Conteúdos ativos). Condição necessária, não suficiente, para a decisão de escala
(TAP §6.2, decisão 5 do épico); o limiar da decisão pertence a PIL-001.

**Fonte de medição**: instrumentação — o próprio Painel/consulta agregada sobre os
eventos de etapa de produção e sobre a contagem de páginas registrada na Exportação
(FEAT-034-001).

## 2. Personas e jobs-to-be-done

- **Gestor da fábrica (papel ADMIN)** — "Quando preciso decidir se o modelo de produção
  escala para novos módulos, quero ver o tempo de produção por página e o estado do
  backlog sem abrir o banco de dados, para decidir com o que a própria fábrica mede."
- **EDITOR de produção** — "Quando termino uma leva de Conteúdos, quero ver a conclusão
  do meu módulo e o que falta no backlog, para priorizar o que produzir a seguir."

Anti-persona (1 linha): o **estudante concursando** não é usuário deste Painel — se um
requisito só faz sentido para ele, está no slug ou na SPEC errada.

## 3. Glossário (Ubiquitous Language)

| Termo | Definição | Origem |
|-------|-----------|--------|
| Painel estratégico | Tela de leitura agregada, interna a EDITOR/ADMIN, que mostra tempo por página, conclusão por módulo, correções após revisão e backlog de produção — a partir só do que a fábrica mede sozinha (F3/F8/F9), sem venda nem métrica de beta | BRIEF-034 |
| Página (da Exportação) | Número de páginas reais do documento PDF emitido por uma Exportação, incluindo as páginas suplementares de Contraste/Pegadinha/Flashcard/Protocolo (Variante Tira); registrado no momento da Exportação, nunca recomputado depois | BRIEF-034 |
| Sem medida | Estado de um dado numérico que a fábrica ainda não capturou (Exportação anterior a esta capacidade, ou Conteúdo sem Exportação Tira com página registrada após o fechamento de Versão) — nunca representado como zero nem como valor estimado; variante "sem medida — início da produção não registrado" quando o Conteúdo foi criado fora do fluxo instrumentado (sem evento de criação registrado) | BRIEF-034 |
| Tempo de produção por página | A métrica-régua da fábrica (TAP §6.2): tempo total de produção de um Conteúdo — do início registrado da produção até a primeira Exportação da Variante Tira ocorrida depois do primeiro fechamento de Versão desse Conteúdo — dividido pelo número de Páginas dessa mesma Exportação | BRIEF-001 → SPEC-034 |
| Tempo por etapa | Lead time de calendário de uma etapa de produção de um Conteúdo, do primeiro ao último evento daquela etapa registrado para o Conteúdo, incluindo o tempo ocupado por eventuais correções após revisão; calculado só quando a etapa tem abertura e conclusão registradas — abertura sem conclusão aparece como "em aberto" (sem número), etapa sem nenhum evento como "não percorrida", e evento sem abertura correspondente (ex.: Tira auto-gerada na Exportação) como "sem duração medida", nunca zero. A etapa "Conteúdo bruto" é registrada instantaneamente na criação do Conteúdo (abertura e conclusão simultâneas); sua duração reflete só o retrabalho posterior, se houver | SPEC-009 (E-02) → SPEC-034 |
| Correções após revisão | Evento de retrabalho de uma etapa de conteúdo (Conteúdo bruto, Quebra da regra, Tira mnemônica, Associação visual, Material de reforço) ocorrido, por ordem de sequência, depois do primeiro fechamento de Versão do mesmo Conteúdo | BRIEF-034 |
| Módulo | Um Tema do acervo, agrupado por Disciplina — a unidade de conclusão que o Painel relata (a TAP chama de "módulo" o que o acervo estruturado representa como Tema) | BRIEF-034 |
| Concluído | Estado de um Conteúdo cuja Versão vigente está aprovada e válida para exportação — a mesma regra única de "aprovada e válida para exportação" de F9. Conteúdo ativo que não está Concluído compõe o Backlog de produção | F9 → SPEC-034 |
| Conclusão por módulo | Para um Módulo: número de Conteúdos ativos e número deles Concluídos | BRIEF-034 |
| Backlog de produção | Lista de Conteúdos ativos que não estão Concluídos, cada um com a etapa mais avançada alcançada, a prioridade de apresentação e a idade desde o início registrado da produção; um Conteúdo com Versão aprovada e alterada depois aparece com o marcador "aprovada, alterada depois — aguarda nova aprovação" | BRIEF-034 |
| Etapa mais avançada | A etapa do fluxo canônico de produção (Conteúdo bruto → Quebra da regra → Tira → Associação visual → Material de reforço → Versão editorial → Aprovação) mais adiante já alcançada por um Conteúdo, usada para posicionar seu item no backlog — a Publicação fica fora deste cálculo porque a Exportação de rascunho pode ocorrer em qualquer ponto após a Quebra da regra (F6) | BRIEF-034 |

## 4. Escopo

### 4.1 In-scope

- Registro do número de Páginas em toda Exportação (ambas as Variantes), a partir desta
  fatia.
- Tempo por página e tempo por etapa, por Conteúdo, a partir dos eventos já capturados
  desde F3.
- Agregados de tempo por página da fábrica inteira e por Módulo (média, mediana, n e
  cobertura sobre o total de ativos do recorte).
- Conclusão por Módulo (Conteúdos ativos × Conteúdos Concluídos).
- Correções após revisão: contagem por etapa, por Conteúdo e total da fábrica, mais o
  indicador geral de quantos Conteúdos têm ao menos uma correção.
- Backlog de produção: Conteúdos ativos que não estão Concluídos, cada um com etapa mais
  avançada, prioridade de apresentação, idade e o marcador de "aprovada, alterada depois"
  quando aplicável — ordenado por prioridade e depois pelo mais antigo.
- Leitura restrita a EDITOR e ADMIN, agregada no servidor.
- Três estados observáveis de carregamento do Painel (carregando/sucesso/falha com nova
  tentativa), um estado vazio global e o estado vazio por seção quando ela não tem dado
  próprio.
- O Painel como página inicial da área interna, substituindo o placeholder atual dessa
  página.

### 4.2 Out-of-scope

- "Mais vendidos" e "próximos lançamentos" (venda e métricas do beta) — Q-12 do épico
  segue sem resposta; entram, se entrarem, como dado importado rotulado como tal, nunca
  nesta fatia.
- Ação "devolver para correção" com motivo gravado — as correções após revisão desta
  fatia só leem retrabalho já existente, não criam ação nova.
- Filtro por período/intervalo de datas nas métricas ou no backlog — o Painel mostra o
  retrato corrente; recorte temporal fica para fatia futura, se demandado.
- Exportação do próprio Painel (CSV/PDF) — a tela mostra números/tabelas/barras simples;
  levar o retrato para fora do sistema não está nesta fatia.
- Gráficos com biblioteca nova — o produto não tem biblioteca de gráficos hoje; a
  apresentação usa números, tabelas e barras simples com o que já existe.
- Esforço (horas efetivamente trabalhadas) como métrica de tempo — o Painel mede lead
  time de calendário (A-034-003), nunca esforço.
- Recomputar página de Exportações antigas — Exportações anteriores a esta capacidade
  permanecem "sem medida" para sempre; reexportar não converte em medida um Conteúdo
  cuja primeira Exportação Tira pós-fechamento é anterior a esta capacidade.
- Reescrever o seed para gerar eventos históricos — o Painel em ambiente semeado direto
  (sem interação real pela tela) mostra o retrato vazio/parcial que os dados sustentam,
  nunca um histórico fabricado.
- Menu global de navegação da área interna — vizinho nomeado, fora desta fatia; o Painel
  vira a home, mas a navegação para as demais telas internas não muda aqui.
- Fila de produção e calendário editorial (F11) — fatia seguinte do épico, fora do MVP;
  o backlog aqui é retrato de conclusão, não agenda.
- Definir o limiar numérico que decide a escala do modelo de fábrica — cabe a PIL-001;
  esta fatia só fornece o número medido (RISK-034-006).

## 5. Requisitos funcionais (EARS)

### FEAT-034-001: Registro de páginas na Exportação
**Jira**: KAN-166
**Verificação (gate 9)**: 2026-09-30 — VERIFICADO pelo `qa`: AC-034-001/002/003/019/022/024 provados via HTTP real + banco de DEV real (backend `b769ffe`, login EDITOR), 3 Conteúdos descartáveis criados e removidos pelas rotas; `pageCount` gravado = páginas do PDF baixado; referência = 1ª Exportação Tira após o fechamento (3 exportações, as 2 não-referência deliberadamente iguais); Resumo nunca substitui a Tira.

> A Exportação de um Conteúdo (qualquer Variante) passa a registrar o número de páginas
> do documento PDF emitido — dado que o Painel (FEAT-034-002) consome para calcular
> tempo por página. Fluxo que o QA testa de ponta a ponta: acionar a Exportação e
> confirmar que a contagem de páginas fica registrada e reaparece na leitura.

- **FR-034-001** [MUST] Quando a Exportação gerar o documento PDF, em qualquer Variante,
  o sistema deve registrar o número de páginas do documento emitido.
- **FR-034-002** [MUST] Se a Exportação for anterior à existência desta capacidade,
  então o sistema deve reportar o número de páginas dela como "sem medida" — nunca como
  zero, nunca como um valor estimado.
- **FR-034-003** [MUST] Quando o Painel calcular o tempo por página de um Conteúdo, o
  sistema deve usar a primeira Exportação da Variante Tira ocorrida depois do primeiro
  fechamento de Versão desse Conteúdo.
- **FR-034-020** [MUST] O sistema deve calcular o tempo total do Conteúdo do início
  registrado da produção até essa Exportação, e usar as páginas dessa mesma Exportação
  no tempo por página.
- **FR-034-021** [MUST] Se essa Exportação não tiver contagem de páginas registrada,
  então o sistema deve reportar o Conteúdo como "sem medida"; reexportações posteriores
  não substituem essa condição.
- **FR-034-019** [MUST] Se a contagem de páginas falhar durante a Exportação, então o
  sistema deve entregar o documento e registrar a Exportação normalmente, com a
  contagem "sem medida".

### FEAT-034-002: Painel estratégico
**Jira**: KAN-167

> Tela de leitura agregada, interna a EDITOR/ADMIN, que reúne tempo por página, conclusão
> por módulo, correções após revisão e backlog. Fluxo que o QA testa de ponta a ponta:
> abrir a home da área interna autenticado como EDITOR/ADMIN e conferir as quatro seções
> contra o estado real dos dados; abrir sem sessão ou papel elegível e confirmar a recusa.

- **FR-034-004** [MUST] O sistema deve exibir, para cada Conteúdo com Exportação Tira
  medida, o tempo total de produção desse Conteúdo.
- **FR-034-005** [MUST] O sistema deve exibir, para cada Conteúdo com Exportação Tira
  medida, o tempo por página, calculado dividindo o tempo total de produção pelo número
  de páginas da Exportação usada no cálculo (FR-034-003).
- **FR-034-006** [MUST] O sistema deve exibir, para cada Conteúdo, o tempo por etapa de
  cada etapa de produção com abertura e conclusão registradas, do primeiro ao último
  evento da etapa, incluindo o intervalo de correções após revisão.
- **FR-034-022** [MUST] Se uma etapa de um Conteúdo tiver abertura sem conclusão
  registrada, então o sistema deve exibi-la como "em aberto", sem número.
- **FR-034-023** [MUST] Se uma etapa de um Conteúdo não tiver nenhum evento registrado,
  então o sistema deve exibi-la como "não percorrida".
- **FR-034-024** [MUST] Se uma etapa de um Conteúdo tiver um evento registrado sem
  abertura correspondente, então o sistema deve exibi-la como "sem duração medida",
  nunca como zero.
- **FR-034-025** [SHOULD] Enquanto um Conteúdo tiver tempo por página medido
  (FR-034-003), o sistema deve exibir também o tempo por etapa por página, dividindo o
  tempo de cada etapa pelas mesmas páginas.
- **FR-034-007** [MUST] Se um Conteúdo ativo não tiver nenhuma Exportação da Variante
  Tira com página medida, então o sistema deve reportá-lo como "sem medida" nas métricas
  de tempo por página — nunca com o valor zero nem estimado.
- **FR-034-026** [MUST] Se a criação de um Conteúdo não estiver registrada entre os
  eventos de etapa, então o sistema deve reportar seu tempo total, tempo por página e
  idade como "sem medida — início da produção não registrado".
- **FR-034-008** [MUST] O sistema deve exibir, para a fábrica e cada Módulo, a média, a
  mediana e o n do tempo por página entre Conteúdos com medida, e o total de Conteúdos
  ativos do recorte (cobertura).
- **FR-034-009** [MUST] O sistema deve exibir, para cada Módulo, a Conclusão por módulo:
  o número de Conteúdos ativos e o número deles Concluídos.
- **FR-034-010** [MUST] O sistema deve identificar como Correção após revisão todo evento
  de retrabalho de uma etapa de conteúdo (Conteúdo bruto, Quebra da regra, Tira
  mnemônica, Associação visual, Material de reforço) ocorrido, por ordem de sequência,
  depois do primeiro fechamento de Versão do mesmo Conteúdo.
- **FR-034-011** [MUST] O sistema deve exibir as correções após revisão contadas por
  etapa, por Conteúdo e para a fábrica, sem somar etapas diferentes num único número.
- **FR-034-031** [MUST] O sistema deve exibir, como indicador geral, quantos Conteúdos
  têm ao menos uma correção após revisão.
- **FR-034-032** [SHOULD] O sistema deve exibir, junto às correções após revisão, a
  legenda "edições feitas depois do fechamento de uma Versão".
- **FR-034-012** [MUST] O sistema deve listar, no backlog, todo Conteúdo ativo que não
  esteja Concluído (FR-034-009).
- **FR-034-027** [MUST] O sistema deve exibir, para cada item do backlog, a etapa mais
  avançada alcançada, a prioridade de apresentação e a idade desde o início registrado
  da produção.
- **FR-034-028** [MUST] Se um Conteúdo do backlog tiver Versão aprovada e alterada
  depois da aprovação, então o sistema deve exibi-lo com o marcador "aprovada, alterada
  depois — aguarda nova aprovação".
- **FR-034-029** [MUST] Se um Conteúdo ativo do backlog não tiver nenhum evento de
  etapa registrado, então o sistema deve exibi-lo com etapa "sem registro" e idade "sem
  medida".
- **FR-034-013** [MUST] O sistema deve ordenar o backlog primeiro por prioridade de
  apresentação (Alta, depois Média, depois Baixa) e, dentro da mesma prioridade, do
  Conteúdo mais antigo para o mais novo.
- **FR-034-030** [MUST] Enquanto dois Conteúdos do backlog tiverem a mesma prioridade,
  o sistema deve posicionar o de idade "sem medida" depois do que tem idade numérica.
- **FR-034-014** [MUST] Se um Conteúdo bruto estiver removido (soft-delete), então o
  sistema deve excluí-lo de toda métrica do Painel e do backlog.
- **FR-034-015** [MUST] O sistema deve restringir a leitura do Painel estratégico aos
  papéis EDITOR e ADMIN.
- **FR-034-016** [MUST] Se um ator sem sessão autenticada, ou autenticado com papel
  diferente de EDITOR/ADMIN, tentar acessar o Painel estratégico, então o sistema deve
  recusar o acesso e não expor nenhum dado do Painel.
- **FR-034-017** [MUST] Quando o Painel estratégico carregar, o sistema deve apresentar
  os estados carregando, sucesso e falha com ação de tentar novamente.
- **FR-034-033** [MUST] Se a carga suceder sem nenhum Conteúdo ativo, então o sistema
  deve apresentar um estado vazio global, distinto do estado de sucesso com dado.
- **FR-034-034** [MUST] Enquanto o Painel carregar com sucesso e existirem Conteúdos
  ativos, o sistema deve apresentar, em cada seção sem dado próprio, o estado vazio
  dessa seção, sem ocultar as demais.
- **FR-034-018** [MUST] O sistema deve apresentar o Painel estratégico como a página
  inicial da área interna, substituindo o placeholder existente ali.

## 6. Requisitos não-funcionais

- **NFR-034-001** [MUST] O número de consultas ao armazenamento para montar o Painel
  deve ser constante — a mesma contagem medida com 10 e com 200 Conteúdos, independente
  do total de Conteúdos da fábrica.
- **NFR-034-002** [SHOULD] O tempo de resposta do Painel deve ficar, em p95, abaixo de
  1.500 ms para um volume de referência de 200 Conteúdos com 50 eventos de etapa cada
  (A-034-010 — alvo assumido, sem SLA de produto declarado até aqui).
- **NFR-034-003** [MUST] O Painel não deve retornar, em nenhuma resposta ao cliente,
  nenhum campo de texto normativo (Conteúdo bruto, Quebra da regra ou similar) — 0
  campos de texto normativo, conferido por lista fechada de chaves permitidas na
  resposta.
- **NFR-034-004** [MUST] O Painel não deve exibir nenhuma métrica agrupada por
  autor/editor individual em nenhuma resposta — 0 métricas agrupadas por pessoa; só
  agregados por Conteúdo, por Módulo e pela fábrica inteira.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-034-001** (cobre FR-034-001)
  Dado um Conteúdo bruto com Quebra da regra salva, quando o EDITOR ou ADMIN aciona a
  Exportação em qualquer Variante, então o sistema registra, junto ao evento de
  Publicação, o número de páginas do documento PDF emitido.

- **AC-034-002** (cobre FR-034-002)
  Dado uma Exportação realizada antes desta capacidade existir, quando alguma leitura
  exibir essa Exportação, então o número de páginas aparece como "sem medida", nunca como
  zero nem como um valor estimado.

- **AC-034-003** (cobre FR-034-003, FR-034-020)
  Dado um Conteúdo com três Exportações da Variante Tira medidas — uma antes do
  fechamento de Versão, a primeira ocorrida depois do fechamento, e outra semanas depois
  —, quando o Painel calcular o tempo por página desse Conteúdo, então o sistema usa o
  número de páginas da Exportação do meio (a primeira ocorrida depois do fechamento),
  ignorando as demais.

- **AC-034-004** (cobre FR-034-004, FR-034-005, FR-034-020)
  Dado um Conteúdo com o início registrado da produção e a primeira Exportação da
  Variante Tira ocorrida depois do fechamento de Versão desse Conteúdo com página
  medida, quando o Painel exibir esse Conteúdo, então o sistema mostra o tempo total de
  produção (do início registrado até essa Exportação) e o tempo por página (o tempo
  total dividido pelas páginas dessa Exportação).

- **AC-034-005** (cobre FR-034-006, FR-034-025)
  Dado um Conteúdo com eventos de abertura, retrabalho e conclusão registrados para a
  etapa "Quebra da regra", e tempo por página medido para o Conteúdo, quando o Painel
  calcular o tempo por etapa dessa etapa, então o sistema soma o intervalo do primeiro
  ao último evento da etapa, incluindo o intervalo ocupado pelo retrabalho, e mostra
  também o tempo da etapa dividido pelas páginas medidas do Conteúdo.

- **AC-034-006** (cobre FR-034-007)
  Dado um Conteúdo ativo sem nenhuma Exportação da Variante Tira com página medida,
  quando o Painel calcular o tempo por página, então o sistema reporta esse Conteúdo como
  "sem medida", nunca com tempo por página igual a zero nem estimado.

- **AC-034-007** (cobre FR-034-008)
  Dado um conjunto de Conteúdos com tempo por página medido dentro de um Módulo, quando o
  Painel exibir o agregado desse Módulo, então o sistema mostra a média, a mediana, a
  quantidade de Conteúdos considerados (n) e o total de Conteúdos ativos do mesmo Módulo
  (a cobertura).

- **AC-034-008** (cobre FR-034-009)
  Dado um Módulo com Conteúdos ativos, alguns Concluídos e outros não, quando o Painel
  exibir a conclusão desse Módulo, então o sistema mostra o número de Conteúdos ativos e
  o número deles Concluídos.

- **AC-034-009** (cobre FR-034-010, FR-034-011, FR-034-031, FR-034-032)
  Dado um Conteúdo com um evento de retrabalho da etapa "Conteúdo bruto" registrado
  depois, por ordem de sequência, do primeiro fechamento de Versão desse mesmo Conteúdo,
  quando o Painel contar as correções após revisão, então esse evento entra na contagem
  da etapa "Conteúdo bruto" exibida para o Conteúdo e no total da fábrica dessa etapa —
  sem somar com outras etapas —, acompanhada da legenda "edições feitas depois do
  fechamento de uma Versão", e esse Conteúdo passa a contar no indicador geral de
  Conteúdos com ao menos uma correção; um evento de retrabalho anterior ao fechamento não
  entra em nenhuma contagem.

- **AC-034-010** (cobre FR-034-012, FR-034-013, FR-034-027)
  Dado três Conteúdos ativos que não estão Concluídos, com prioridades de apresentação
  Alta, Média e Baixa e idades diferentes desde o início registrado da produção, quando o
  Painel exibir o backlog, então os três aparecem, cada um com a etapa mais avançada
  alcançada e a idade, ordenados primeiro por prioridade (Alta, depois Média, depois
  Baixa) e, dentro da mesma prioridade, do mais antigo para o mais novo.

- **AC-034-011** (cobre FR-034-014)
  Dado um Conteúdo bruto removido (soft-delete) que teria Versão pendente de aprovação,
  quando o Painel calcular qualquer métrica ou montar o backlog, então esse Conteúdo não
  aparece em nenhum dos dois.

- **AC-034-012** (cobre FR-034-015, FR-034-016)
  Dado um ator sem sessão autenticada, ou autenticado com um papel diferente de
  EDITOR/ADMIN, quando ele tenta acessar o Painel estratégico, então o sistema recusa o
  acesso e não expõe nenhum dado do Painel.

- **AC-034-013** (cobre NFR-034-003, NFR-034-004)
  Dado um EDITOR autenticado no Painel, quando ele visualiza qualquer métrica ou item do
  backlog, então o sistema mostra só identificação mínima do Conteúdo (disciplina, tema,
  título/identificador) — nunca texto do Conteúdo bruto, da Quebra da regra ou de campo
  normativo, nem uma métrica atribuída a um autor/editor individual.

- **AC-034-014** (cobre FR-034-017)
  Dado o Painel estratégico acionado, quando a consulta ainda não retornou, então o
  sistema mostra o estado "carregando"; quando a consulta retorna com dado, então mostra
  o estado de sucesso com as métricas; quando a consulta falha, então mostra o estado de
  falha com uma ação de tentar novamente.

- **AC-034-015** (cobre FR-034-033)
  Dado nenhum Conteúdo ativo cadastrado na fábrica, quando o Painel carregar com sucesso,
  então o sistema mostra um estado vazio global, distinto do estado de sucesso com dado.

- **AC-034-016** (cobre FR-034-018)
  Dado um EDITOR ou ADMIN autenticado, quando ele acessa a home da área interna, então o
  sistema exibe o Painel estratégico no lugar do placeholder anterior.

- **AC-034-017** (cobre FR-034-034)
  Dado Conteúdos ativos e nenhum com tempo por página medido, quando o Painel carregar,
  então Conclusão por módulo e Backlog de produção aparecem com dado e a seção de tempo
  por página mostra "sem medida" com cobertura 0 de N.

- **AC-034-018** (cobre FR-034-009, FR-034-012, FR-034-028)
  Dado um Módulo com Conteúdos concluídos, sem aprovação e aprovados-e-alterados, quando
  o Painel exibir, então ativos = concluídos + itens do backlog daquele Módulo, e o
  aprovado-e-alterado aparece no backlog com o marcador.

- **AC-034-019** (cobre FR-034-021)
  Dado um Conteúdo cuja primeira Exportação da Variante Tira ocorrida depois do
  fechamento de Versão não tem contagem de páginas registrada, e uma reexportação
  posterior com contagem medida, quando o Painel calcular o tempo por página, então o
  sistema reporta "sem medida", pois a reexportação não substitui a Exportação de
  referência.

- **AC-034-020** (cobre FR-034-026, FR-034-029, FR-034-030)
  Dado um Conteúdo criado fora do fluxo instrumentado (sem evento de criação registrado)
  e ainda ativo, e outro Conteúdo ativo no backlog com idade numérica na mesma
  prioridade, quando o Painel calcular suas métricas ou montar o backlog, então o
  primeiro Conteúdo tem tempo total, tempo por página e idade reportados como "sem
  medida — início da produção não registrado", aparece no backlog com etapa "sem
  registro", e é posicionado depois do Conteúdo com idade numérica dentro da mesma
  prioridade.

- **AC-034-021** (cobre FR-034-022, FR-034-023, FR-034-024)
  Dado uma etapa de um Conteúdo com abertura sem conclusão registrada, uma etapa sem
  nenhum evento e uma etapa com evento sem abertura correspondente, quando o Painel
  calcular o tempo por etapa, então o sistema mostra, respectivamente, "em aberto", "não
  percorrida" e "sem duração medida" — nunca zero.

- **AC-034-022** (cobre FR-034-019)
  Dado a contagem de páginas forçada a falhar durante a Exportação, em qualquer
  Variante, quando o EDITOR ou ADMIN aciona a Exportação, então o sistema entrega o
  documento PDF normalmente e registra a Exportação com a contagem "sem medida".

- **AC-034-023** (cobre FR-034-017)
  Dado login bem-sucedido de EDITOR/ADMIN, quando a carga do Painel falhar, então a home
  da área interna mostra o estado de falha com tentar novamente, nunca uma página de
  erro.

- **AC-034-024** (cobre FR-034-003)
  Dado um Conteúdo com Exportações só da Variante Resumo (medidas), quando o Painel
  calcular o tempo por página, então reporta "sem medida" — a contagem do Resumo nunca
  substitui a da Tira.

## 8. Premissas e decisões prévias

- **A-034-001** [assumido] [evidência: entrevistas] Página = número de páginas reais do
  PDF exportado na Variante Tira (inclui as páginas suplementares de
  Contraste/Pegadinha/Flashcard/Protocolo) — decisão do Diretor, última chamada
  2026-09-30. Exportações anteriores a esta capacidade aparecem como "sem medida", nunca
  zero nem estimadas (FR-034-002).
- **A-034-002** [assumido] [evidência: entrevistas] "Correções após revisão" = eventos de
  retrabalho das etapas de conteúdo (Conteúdo bruto, Quebra da regra, Tira mnemônica,
  Associação visual, Material de reforço) ocorridos, por ordem de sequência, depois do
  primeiro fechamento de Versão do mesmo Conteúdo — decisão do Diretor, 2026-09-30. Sem
  ação nova de "devolver para correção" nesta fatia.
- **A-034-003** [assumido] [evidência: entrevistas] Tempo é lead time de calendário, não
  esforço — régua E-02 de SPEC-009/F3, confirmada pelo Diretor em 2026-09-06. A fórmula
  exata foi delegada a esta SPEC pelo BRIEF (A-034-011).
- **A-034-004** [assumido] [evidência: entrevistas] Migração aditiva (contagem de
  páginas opcional por Exportação) autorizada pelo Diretor para dev/teste em 2026-09-30;
  produção segue pelo deploy, ato do Diretor.
- **A-034-005** [assumido] [evidência: entrevistas] O Painel é leitura interna (EDITOR e
  ADMIN), agregada no servidor; o estudante nunca o vê (anti-persona) — decisão do
  Diretor no BRIEF-034.
- **A-034-006** [assumido] [evidência: crença] Resposta completa a Q-009-002 de
  SPEC-009: abertura órfã (evento de abertura sem conclusão) em Conteúdo ativo é trabalho
  em andamento — exibida como "em aberto" na métrica de tempo por etapa e contada como
  etapa alcançada no backlog; Conteúdo removido (soft-delete) fica fora de toda métrica e
  do backlog (FR-034-014).
- **A-034-007** [assumido] [evidência: crença] Módulo = Tema, agrupado por Disciplina —
  a TAP chama de "módulo" (ex.: "Obrigação Tributária") o que o acervo estruturado
  representa como Tema; conclusão por Módulo usa a mesma regra única de "aprovada e
  válida para exportação" de F9 (define o estado Concluído, §3).
- **A-034-008** [assumido] [evidência: crença] Backlog de produção = Conteúdo ativo que
  não está Concluído (Versão vigente aprovada e válida para exportação, mesma regra de
  F9); Conteúdo com Versão aprovada e alterada depois aparece no backlog com o marcador
  "aprovada, alterada depois — aguarda nova aprovação". Cada item mostra a etapa mais
  avançada alcançada (ordem fixa: Conteúdo bruto → Quebra da regra → Tira → Associação
  visual → Material de reforço → Versão editorial → Aprovação — a Publicação fica fora
  do cálculo, pois a exportação de rascunho pode ocorrer em qualquer ponto após a
  Quebra, F6), a prioridade de apresentação e a idade desde o início registrado da
  produção; ordenado por prioridade e, dentro dela, pelo mais antigo primeiro, com idade
  "sem medida" depois das idades numéricas.
- **A-034-009** [assumido] [evidência: crença] O Painel nunca exibe métrica
  individualizada por autor/editor — só agregados por Conteúdo, Módulo e fábrica; nenhuma
  fonte pediu quebra por pessoa, e expor produtividade individual sem demanda explícita é
  risco desnecessário (NFR-034-004).
- **A-034-010** [assumido] [evidência: crença] Alvo de desempenho p95 de 1.500 ms para o
  volume de referência de 200 Conteúdos × 50 eventos cada (NFR-034-002) — nenhuma fonte
  declarou um número; escolhido como piso razoável de painel interno sem SLA de produto
  explícito. O PLAN decide o mecanismo que o sustenta.
- **A-034-011** [assumido] [evidência: crença] Fórmula exata do tempo, resposta a
  Q-009-001/Q-009-002 de SPEC-009: tempo por etapa, do primeiro ao último evento
  registrado da etapa (retrabalho incluso no numerador), calculado só quando a etapa tem
  abertura e conclusão registradas — sem isso, "em aberto"/"não percorrida"/"sem duração
  medida" (nunca zero); tempo total do Conteúdo, do início registrado da produção
  (criação do "Conteúdo bruto") até a primeira Exportação da Variante Tira ocorrida
  depois do primeiro fechamento de Versão; tempo por página = tempo total ÷ páginas
  dessa mesma Exportação; agregado da fábrica e por Módulo = média e mediana sobre os
  Conteúdos com medida, com a contagem n exibida. Alternativas rejeitadas: janela =
  primeira Exportação Tira medida a qualquer momento (conflita com rascunho/prévia de
  F6); janela = Exportação pós-aprovação (a segregação de FR-032-004 exige 2 pessoas,
  adiando demais); janela = última Exportação (infla o tempo); tempo de etapa contado do
  fim da etapa anterior (rejeitado — cada etapa mede seu próprio intervalo registrado,
  não o intervalo entre etapas).
- **A-034-012** [assumido] [evidência: crença] Gatilho "Reabrir se" de A-005-001
  avaliado: F10 exibe a derivação selada (ALTA→Alta, MEDIA→Média,
  DETALHE/EXCECAO/PEGADINHA→Baixa) conforme o BRIEF (Pedido item 4); não disparou.
- **A-034-013** [assumido] [evidência: crença] Rótulo mantido "correções após revisão",
  com legenda na tela: "edições feitas depois do fechamento de uma Versão" (FR-034-032).
- **A-034-014** [assumido] [evidência: crença] Janela de verificação da métrica de
  sucesso (§1.3): até 4 semanas após o deploy em produção — nenhuma fonte declarou este
  prazo; escolhido como piso razoável para observar o primeiro Conteúdo real do módulo
  piloto passar pelo fluxo completo.

## 9. Riscos e questões abertas

- **RISK-034-001** Lead time de calendário não é esforço: um Conteúdo parado (aguardando
  revisão humana, disponibilidade de um segundo ADMIN, ou qualquer bloqueio externo)
  infla o tempo por etapa e o tempo por página sem que mais trabalho tenha sido de fato
  investido — leitura do número como "produtividade individual" é o mau uso a evitar.
- **RISK-034-002** (herdado de RISK-011-006) A granularidade de retrabalho não é
  comparável entre etapas de origens diferentes (F2: ~1 evento por salvamento de tela;
  F4: ~1 evento por mutação atômica de Quadro) — o Painel deve expor só duração (lead
  time, comparável) por etapa; a **contagem** de correções após revisão não deve ser lida
  como proxy comparável de esforço entre etapas diferentes. Mitigado: FR-034-011 exige a
  contagem separada por etapa, sem soma entre etapas diferentes num único número.
- **RISK-034-003** Conteúdos cuja primeira Exportação da Variante Tira posterior ao
  fechamento de Versão ocorreu antes desta capacidade existir ficam "sem medida"
  permanentemente — reexportações seguintes não convertem essa condição, mesmo que
  tragam contagem de páginas (FR-034-021). A métrica de tempo por página nasce com
  cobertura parcial (n pequeno) até que Conteúdos novos completem o fluxo real depois
  desta capacidade.
- **RISK-034-004** Em ambiente de desenvolvimento semeado direto via Prisma (sem
  interação real pela tela), não existem eventos de etapa — o Painel aparece vazio ou com
  n=0 até que haja produção real através das rotas; não é defeito do Painel, é reflexo
  fiel do dado.
- **RISK-034-005** (herdado de TRISK-010-002) A leitura interna de eventos de etapa não
  pagina hoje — o Painel é o primeiro consumidor real desse dado; se o volume de eventos
  crescer, a consulta agregada pode exigir paginação/particionamento que esta SPEC não
  resolve — decisão do PLAN quando o volume justificar.
- **RISK-034-006** O Painel fornece o número, não o critério; o limiar que decide a
  escala segue em PIL-001 e não é decidido nesta SPEC.

## 10. Fora deste documento

Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e
`/keelson:tasks`.
