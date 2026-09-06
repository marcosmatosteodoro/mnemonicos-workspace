# SPEC-011: Tira mnemônica como sequência de quadros

**Slug**: producao-material
**Jira**: KAN-6
**Jira Story**: KAN-50
**Status**: Approved
**Versão**: 0.1
**Autor**: keelson (scribe)
**Data**: 2026-09-06
**Brief**: BRIEF-011

## 1. Contexto e objetivo

### 1.1 Problema

Depois de F2 (Conteúdo bruto + Quebra da regra, SPEC-005/PLAN-006) e F3 (instrumentação de
etapas, SPEC-009/PLAN-010), o produto ainda não tem nenhuma representação estrutural da
Tira mnemônica — a peça central do método que reconstrói uma regra em sequência memorável.
O único artefato que hoje se aproxima disso é o modelo legado `Mnemonic.hook`/`decoding`,
texto único sem qualquer estrutura de sequência, que já ficou invisível às telas de produção
desde F2 (A-005-013, SPEC-005) mas continua no schema sem ser formalmente encerrado
(RISK-005-004, INDEX.md: "texto livre de fonte convivendo com a fonte estruturada até F4").
Sem a Tira mnemônica, o EDITOR não tem onde produzir, editar nem reordenar a sequência de
quadros de uma Quebra da regra já escrita — e a fábrica carrega uma duplicidade de
representação de fonte que a decisão de produto do épico (A-002) já definiu que deveria ser
resolvida por uma sequência ordenada de quadros, não por texto corrido.

### 1.2 Outcome esperado

Ao abrir a Tira mnemônica de uma Quebra da regra que ainda não tem Tira, o sistema gera
automaticamente a sequência inicial de Quadros a partir dos Blocos da quebra não-vazios, na
ordem canônica do método (CONCEITO → AÇÃO → OBJETO → CONDIÇÃO → EXCEÇÃO). A partir daí, o
EDITOR tem CRUD completo sobre os Quadros — criar, editar texto, remover — e pode reordená-los
livremente, com a garantia de que uma falha durante a reordenação nunca deixa a sequência de
posições corrompida (duas posições iguais ou uma posição faltando). Toda mutação da Tira —
inclusive a geração inicial — emite o evento de etapa "Tira mnemônica" (novo valor aditivo no
mecanismo de instrumentação de F3), na mesma operação atômica da mutação de negócio
(fail-secure: falha na emissão reverte a mutação inteira). Ao fim desta fatia, o modelo
`Mnemonic` legado deixa de ser lido ou escrito pela fábrica — o legado fica sem consumidor
algum, e RISK-005-004 (INDEX.md) é reclassificado (não baixado): de "duas representações
vivas da fonte" para "dado dormente duplicado", sucedido por RISK-011-001 (§9). A baixa ou
reclassificação formal no INDEX.md é ato do Tech Lead na Etapa 5, fora desta SPEC.

### 1.3 Métrica de sucesso

Esta SPEC não introduz uma métrica de produto separada — a régua central do épico ("tempo de
produção por página") já pertence a F3/F10, e não é antecipada aqui (mesma postura de
SPEC-009 §1.3). O efeito verificável desta fatia é qualitativo e binário: toda transição
elegível da nova etapa "Tira mnemônica" (abertura na geração inicial; conclusão na 1ª
mutação humana de Quadro depois da geração; retrabalho em qualquer mutação humana
subsequente) emite exatamente 1 evento correspondente, sem exceção e sem perda — abertura e
conclusão não são mais emitidas no mesmo instante (correção desta versão da SPEC: a geração
inicial emite só abertura; ver FR-011-008/FR-011-009). O tempo médio da etapa "Tira
mnemônica" — quando existir volume real de uso — poderá ser calculado sobre esses eventos por
F10 (painel), do mesmo modo que já vale para "Conteúdo bruto"/"Quebra da regra" desde F3.

**Fonte de medição**: (a) instrumentação — os eventos de etapa "Tira mnemônica" (abertura,
conclusão, retrabalho) emitidos pelos FR-011-008/FR-011-009 desta própria SPEC, através do
mesmo mecanismo `ProductionStageEvent` que F3 (SPEC-009) já implementou e provou; dono: time
de engenharia. A apuração do tempo médio da etapa fica para quando F10 (painel) existir ou
para uma inspeção humana equivalente à já feita na Entrega de F3 (§1.3, item b de SPEC-009).
(b) observacional, apurado por inspeção humana na Entrega desta fatia (mesmo molde de
SPEC-005 §1.3 item b / SPEC-009 §1.3 item b): (i) proporção de Tiras mnemônicas geradas que
alcançaram conclusão da etapa (ao menos 1 mutação humana de Quadro registrada) sobre o total
de Tiras geradas na janela; (ii) número de Quadros cujo texto difere do texto do Bloco da
quebra de origem no momento da apuração, medido só para os Quadros que nasceram com carimbo
de proveniência (A-011-011, §8) — Quadros criados manualmente pelo EDITOR depois da geração
(sem carimbo) ficam fora desta contagem. Dono: time de engenharia; prazo: Entrega.

## 2. Personas e jobs-to-be-done

Como EDITOR da fábrica, preciso transformar a Quebra da regra que já escrevi em uma
sequência de quadros memorável e editável, para produzir a Tira mnemônica de uma regra sem
reescrever do zero o que a Quebra já capturou — e poder ajustar o texto e a ordem de cada
quadro até a sequência ficar didaticamente correta.

Anti-persona (decisão 4.98, herdada e reforçada): não é para o estudante — segue fora de
qualquer superfície da fábrica, como em todo o produto; e não é, nesta fatia, para consumo
agregado ou relatório de tempo por etapa — isso é F10, que só lê os eventos que esta SPEC
emite.

## 3. Glossário (Ubiquitous Language)

| Termo | Definição | Origem |
|-------|-----------|--------|
| Tira mnemônica | Sequência ordenada de quadros que reconstrói uma regra (CONCEITO → AÇÃO → OBJETO → CONDIÇÃO/EXCEÇÃO) — entidade própria de F4 (reusado, não redefinido) | INDEX.md / BRIEF-001 |
| Quebra da regra | Decomposição do texto normativo bruto nos cinco blocos, mais a síntese da regra; 1:1 com o Conteúdo bruto (reusado, não redefinido) | INDEX.md / SPEC-005 |
| Bloco da quebra | Cada um dos cinco campos textuais independentes: CONCEITO, AÇÃO, OBJETO, CONDIÇÃO, EXCEÇÃO (CONDIÇÃO/EXCEÇÃO em branco = "não se aplica") (reusado, não redefinido) | INDEX.md / SPEC-005 |
| Conteúdo bruto | Texto normativo colado + disciplina + tema/assunto + classe do radar de prova; a primeira estação da linha de produção (reusado, não redefinido) | INDEX.md / SPEC-005 |
| Quadro | Unidade atômica da Tira mnemônica: um texto livre com uma posição/sequência inteira dentro da tira a que pertence — sem vínculo fixo e permanente com um Bloco da quebra de origem depois da geração inicial (A-011-003); carrega, desde a geração, um carimbo de proveniência nullable e informativo (referência ao Bloco de origem daquele Quadro específico — A-011-011), que nenhuma regra de negócio desta SPEC lê ou depende dele | Decisão do Diretor, largada desta SPEC (BRIEF-011) |
| Posição do quadro | Número de ordem de um Quadro dentro de sua Tira mnemônica — contígua, sem lacuna nem duplicidade em nenhum estado observável (NFR-011-002) | Decisão do Diretor, largada desta SPEC |
| Geração inicial (da Tira mnemônica) | Ato do sistema, disparado na primeira abertura da Tira mnemônica de uma Quebra da regra que ainda não tem Tira, que cria automaticamente um Quadro por Bloco da quebra não-vazio, na ordem canônica CONCEITO → AÇÃO → OBJETO → CONDIÇÃO → EXCEÇÃO | Decisão do Diretor, largada desta SPEC |
| Mnemônico legado | Modelo de dados anterior à Tira mnemônica (`Mnemonic.hook`/`Mnemonic.decoding`), texto livre sem estrutura de sequência; invisível às telas de produção desde F2 (A-005-013) e definitivamente desligado da fábrica nesta fatia | SPEC-005 (A-005-013) — mnemonicos-backend/prisma/schema.prisma:96-120 |

## 4. Escopo

### 4.1 In-scope

- Geração automática da Tira mnemônica ao abrir uma Quebra da regra que ainda não tem Tira
  — 1 Quadro por Bloco da quebra não-vazio, ordem canônica CONCEITO → AÇÃO → OBJETO →
  CONDIÇÃO → EXCEÇÃO.
- CRUD completo de Quadros após a geração inicial: criar Quadro novo, editar o texto de um
  Quadro, remover Quadro.
- Reordenação livre dos Quadros de uma Tira, atômica — nenhuma falha parcial deixa dois
  Quadros com a mesma posição nem uma lacuna na sequência.
- Persistência do texto e da posição de cada Quadro, com a Tira reaparecendo ordenada ao ser
  reaberta (par de leitura, decisão 4.225).
- Emissão do evento de etapa "Tira mnemônica" (novo valor aditivo no mecanismo de
  instrumentação de F3) para a geração inicial e para toda mutação subsequente de Quadro, na
  mesma operação atômica da mutação de negócio (fail-secure).
- Encerramento do uso do modelo `Mnemonic` legado pela fábrica: nenhum fluxo desta
  superfície lê ou escreve em `hook`/`decoding`.
- Barreira de autorização EDITOR/ADMIN (nunca STUDENT) na tela e em toda mutação da Tira
  mnemônica, mesmo padrão das fatias anteriores.

### 4.2 Out-of-scope

- Upload ou associação de imagem por Quadro — quem lê "quadro de tira mnemônica" assumiria
  a camada visual junto; fica para F5 (biblioteca visual).
- Qualquer geração ou exportação de PDF — fica para F6.
- Contraste, pegadinha ou flashcard impresso derivado da Tira — fica para F7.
- Versionamento editorial e fechamento legislativo da Tira — fica para F8.
- Gate de aprovação/QC da versão que inclui a Tira — fica para F9.
- Painel ou métrica agregada de tempo de produção por etapa — esta SPEC só emite o evento
  bruto de etapa (FR-011-008/FR-011-009); o consumo agregado fica para F10.
- Remoção física (DROP de coluna/tabela ou migração de dados) do modelo `Mnemonic` legado —
  quem lê "encerramento do legado" poderia assumir a exclusão de dados junto; **não é o
  caso nesta fatia**: é decisão destrutiva não solicitada pelo Diretor. Risco nomeado:
  enquanto `Mnemonic.hook`/`decoding` permanecem no schema sem consumidor, há duplicidade de
  dado dormente (mesma natureza de RISK-005-001) até uma fatia futura decidir expurgar ou
  migrar (RISK-011-001).
- Vínculo permanente entre um Quadro e o Bloco da quebra que o originou, depois da geração
  inicial — quem lê "quadro nasce de um bloco" poderia assumir rastro fixo; não há
  (A-011-003): o EDITOR reescreve, reordena, cria e remove livremente, e a Tira perde de
  propósito o rastro para a origem.
- Drag-and-drop ou editor de texto rico para os Quadros — a forma exata dos controles de
  reordenação/edição na interface é decisão do PLAN e do `product-designer`; o brief presume
  controles simples, sem mecanismo novo de arrastar (A-011-009).
- Geração retroativa de Quadro para um Bloco da quebra que passou a ter conteúdo depois da
  geração inicial (ex.: CONDIÇÃO era "não se aplica" e o EDITOR a preencheu depois) — coberto
  pelo CRUD livre (FR-011-003): o EDITOR cria o Quadro manualmente se precisar; o sistema não
  re-executa a geração automática uma segunda vez (FR-011-002).

## 5. Requisitos funcionais (EARS)

- **FR-011-001** [MUST] Quando um EDITOR ou ADMIN abre a Tira mnemônica de uma Quebra da
  regra que ainda não tem Tira mnemônica associada, o sistema deve gerar automaticamente um
  Quadro para cada Bloco da quebra não-vazio (CONCEITO, AÇÃO, OBJETO e, quando presentes,
  CONDIÇÃO e EXCEÇÃO), na ordem canônica CONCEITO → AÇÃO → OBJETO → CONDIÇÃO → EXCEÇÃO, com
  o texto de cada Quadro igual ao texto do Bloco correspondente e a posição sequencial
  respectiva, sem lacunas.
- **FR-011-002** [MUST] O sistema deve manter no máximo uma Tira mnemônica por Quebra da
  regra — reabrir uma Tira mnemônica já gerada nunca dispara uma segunda geração automática.
- **FR-011-003** [MUST] Quando um EDITOR ou ADMIN adiciona um novo Quadro a uma Tira
  mnemônica existente, informando texto e posição, o sistema deve criar o Quadro na posição
  informada, deslocando a posição dos Quadros subsequentes para preservar uma sequência
  contígua, sem lacuna nem duplicidade de posição.
- **FR-011-004** [MUST] Quando um EDITOR ou ADMIN edita o texto de um Quadro existente, o
  sistema deve persistir o novo texto, preservando a posição do Quadro na sequência.
- **FR-011-005** [MUST] Quando um EDITOR ou ADMIN remove um Quadro de uma Tira mnemônica, o
  sistema deve excluir o Quadro e recompor a posição dos Quadros restantes para uma
  sequência contígua, sem lacunas.
- **FR-011-006** [MUST] Quando um EDITOR ou ADMIN reordena os Quadros de uma Tira mnemônica,
  o sistema deve persistir a nova sequência de posições solicitada, contígua e sem
  duplicidade.
- **FR-011-007** [MUST] Quando um EDITOR ou ADMIN reabre a Tira mnemônica de uma Quebra da
  regra que já tem Tira mnemônica gerada, o sistema deve exibir todos os Quadros existentes,
  com o texto atual de cada um, na ordem de posição persistida da última mutação bem-sucedida.
- **FR-011-008** [MUST] Quando a Tira mnemônica de uma Quebra da regra for gerada
  automaticamente pela primeira vez (FR-011-001), o sistema deve registrar somente um evento
  de abertura da etapa "Tira mnemônica" para aquele conteúdo, atribuído ao autor que disparou
  a geração — sem evento de conclusão nesse mesmo instante.
- **FR-011-009** [MUST] Quando a Tira mnemônica de uma Quebra da regra recebe a primeira
  mutação humana de Quadro (criação, edição, remoção ou reordenação) depois da geração
  inicial (FR-011-001), o sistema deve registrar um evento de conclusão da etapa "Tira
  mnemônica" para aquele conteúdo, atribuído ao autor da mutação; toda mutação humana de
  Quadro subsequente a essa — ou seja, depois de o evento de conclusão já ter sido
  registrado — deve registrar um evento de retrabalho da etapa "Tira mnemônica", nunca um
  novo evento de conclusão.
- **FR-011-010** [MUST] O sistema deve produzir e exibir a Tira mnemônica exclusivamente a
  partir da Quebra da regra (e, por herança, do Conteúdo bruto) — sem ler nem escrever no
  modelo de Mnemônico legado (`hook`/`decoding`) em nenhum momento desta superfície.
- **FR-011-011** [MUST] As ações de gerar a Tira mnemônica, adicionar Quadro, editar texto
  de Quadro, remover Quadro e reordenar a Tira mnemônica na interface DEVEM expor três
  estados observáveis ao usuário: em andamento (ação disparada, resultado pendente — controle
  desabilitado e/ou indicador visível), sucesso e falha, cada um com indicação visível.

## 6. Requisitos não-funcionais

- **NFR-011-001** [MUST] Toda rota e tela desta superfície DEVE exigir sessão autenticada
  com papel EDITOR ou ADMIN — nunca STUDENT nem acesso anônimo. O alcance de leitura e
  mutação da Tira mnemônica (e de seus Quadros) É HERDADO do alcance do Conteúdo bruto de
  origem (A-005-006, SPEC-005, F2): o EDITOR alcança só as Tiras mnemônicas cujo Conteúdo
  bruto seja de sua própria autoria; o ADMIN alcança todo o acervo, em leitura e escrita —
  mesmo padrão herdado de F2, não uma regra nova desta fatia.
- **NFR-011-002** [MUST] A reordenação dos Quadros de uma Tira mnemônica DEVE ser atômica:
  uma falha ocorrida no meio da operação NUNCA deve resultar em dois Quadros com a mesma
  posição nem em uma posição faltando na sequência — a operação conclui por inteiro, com
  todas as posições novas persistidas, ou não altera nenhuma posição existente.
- **NFR-011-003** [MUST] A emissão do evento de etapa "Tira mnemônica" DEVE ser atômica em
  relação à mutação de negócio que a origina (geração inicial ou qualquer CRUD/reordenação de
  Quadro) — falha ao registrar o evento impede a mutação de ser considerada bem-sucedida, e a
  mutação inteira DEVE ser revertida (fail-secure), nunca um sucesso parcial.
- **NFR-011-004** [MUST] O mecanismo de evento de etapa de produção (já existente desde F3)
  DEVE comportar o novo tipo de etapa "Tira mnemônica" como valor aditivo, sem exigir
  alteração estrutural do mecanismo nem mudança de comportamento dos eventos já emitidos para
  os tipos existentes ("Conteúdo bruto", "Quebra da regra").
- **NFR-011-005** [MUST] Identificadores de código desta superfície DEVEM estar em inglês;
  todo texto de interface exibido ao EDITOR/ADMIN (rótulos, mensagens de estado, confirmações
  e erros) DEVE estar em português do Brasil.
- **NFR-011-006** [MUST] A remoção reversível (soft-delete) da Quebra da regra (e, por
  herança, do Conteúdo bruto) de origem DEVE tornar a Tira mnemônica e todos os seus Quadros
  inalcançáveis, preservando os dados para eventual expurgo futuro — mesmo padrão do restante
  do acervo (NFR-005-006).

## 7. Critérios de aceitação (Given-When-Then)

- **AC-011-001** (cobre FR-011-001)
  Dada uma Quebra da regra existente sem Tira mnemônica ainda, com os cinco Blocos da quebra
  preenchidos, quando o EDITOR abre a Tira mnemônica pela primeira vez, então o sistema gera
  cinco Quadros, na ordem CONCEITO → AÇÃO → OBJETO → CONDIÇÃO → EXCEÇÃO, cada um com o texto
  do Bloco correspondente e posições sequenciais de 1 a 5, sem lacunas.

- **AC-011-002** (cobre FR-011-001)
  Dada uma Quebra da regra cujos Blocos CONDIÇÃO e EXCEÇÃO estão em branco ("não se
  aplica"), quando o EDITOR abre a Tira mnemônica pela primeira vez, então o sistema gera
  exatamente três Quadros (CONCEITO, AÇÃO, OBJETO), sem Quadro correspondente aos dois
  Blocos vazios.

- **AC-011-003** (cobre FR-011-002)
  Dada uma Quebra da regra cuja Tira mnemônica já foi gerada anteriormente, quando o EDITOR
  reabre a Tira mnemônica, então o sistema não gera uma segunda Tira — reexibe a mesma Tira
  já existente, com os Quadros no estado atual.

- **AC-011-004** (cobre FR-011-003, FR-011-011)
  Dada uma Tira mnemônica existente, quando o EDITOR aciona adicionar um novo Quadro com
  texto e posição informados, então, enquanto a operação está em andamento, o controle de
  adicionar fica desabilitado com indicador visível, e, ao concluir com sucesso, o novo
  Quadro aparece na Tira na posição informada, deslocando os Quadros seguintes sem lacuna
  nem duplicidade de posição.

- **AC-011-005** (cobre FR-011-003, FR-011-011)
  Dada uma tentativa de adicionar um Quadro que falha por qualquer motivo, quando a operação
  retorna falha, então o sistema informa o erro de forma visível ao EDITOR e a Tira
  mnemônica permanece exatamente como estava antes da tentativa — nenhum Quadro parcial é
  criado.

- **AC-011-006** (cobre FR-011-004, FR-011-011)
  Dado um Quadro existente, quando o EDITOR edita seu texto e confirma, então, enquanto a
  operação está em andamento, o controle de salvar fica desabilitado com indicador visível,
  e, ao concluir com sucesso, o novo texto é persistido e exibido, mantendo a mesma posição
  do Quadro.

- **AC-011-007** (cobre FR-011-004, FR-011-011)
  Dada uma tentativa de editar o texto de um Quadro que falha por qualquer motivo, quando a
  operação retorna falha, então o sistema informa o erro de forma visível e o texto do
  Quadro permanece o anterior à tentativa.

- **AC-011-008** (cobre FR-011-005, FR-011-011)
  Dada uma Tira mnemônica com três ou mais Quadros, quando o EDITOR remove um Quadro do
  meio da sequência e a operação conclui com sucesso, então o sistema exclui o Quadro e
  recompõe as posições dos Quadros seguintes para uma sequência contígua sem lacuna (ex.:
  posições 1, 2, 3, 4 — removendo a posição 2 — tornam-se 1, 2, 3).

- **AC-011-009** (cobre FR-011-005, FR-011-011)
  Dada uma tentativa de remover um Quadro que falha por qualquer motivo, quando a operação
  retorna falha, então o sistema informa o erro de forma visível e nenhum Quadro é removido
  nem reposicionado.

- **AC-011-010** (cobre FR-011-006, FR-011-011, NFR-011-002)
  Dada uma Tira mnemônica com Quadros em posições de 1 a N, quando o EDITOR reordena os
  Quadros e a operação conclui com sucesso, então, enquanto a operação está em andamento, os
  controles de reordenação ficam desabilitados com indicador visível, e a nova sequência de
  posições é persistida de 1 a N, sem posição repetida nem faltante.

- **AC-011-011** (cobre NFR-011-002)
  Dada uma reordenação de Quadros em andamento, quando uma falha ocorre no meio da operação,
  então nenhuma posição parcial é persistida — a Tira mnemônica permanece com a sequência de
  posições anterior à tentativa, íntegra, contígua e sem duplicidade, e o sistema informa o
  erro de forma visível.

- **AC-011-012** (cobre FR-011-007)
  Dada uma Tira mnemônica já gerada, com Quadros criados, editados, removidos e reordenados
  em sessões anteriores, quando o EDITOR ou ADMIN reabre a tela da Tira mnemônica, então
  todos os Quadros existentes reaparecem na ordem de posição persistida da última mutação
  bem-sucedida, com o texto atual de cada um.

- **AC-011-013** (cobre FR-011-008)
  Dada uma Quebra da regra sem Tira mnemônica, quando a geração automática (FR-011-001) é
  concluída com sucesso, então o sistema registra somente um evento de abertura da etapa
  "Tira mnemônica" para aquele conteúdo, atribuído ao autor que abriu a tela — nenhum evento
  de conclusão é registrado neste instante.

- **AC-011-014** (cobre FR-011-009)
  Dada uma Tira mnemônica recém-gerada automaticamente, sem nenhuma mutação humana de Quadro
  ainda, quando o EDITOR ou ADMIN cria, edita, remove ou reordena um Quadro dela com sucesso
  pela primeira vez, então o sistema registra um evento de conclusão da etapa "Tira
  mnemônica" para aquele conteúdo, atribuído ao autor da mutação; e quando uma segunda
  mutação humana de Quadro (de qualquer um dos quatro tipos) é feita com sucesso depois
  dessa primeira, então o sistema registra um evento de retrabalho da etapa "Tira mnemônica"
  — nunca um novo evento de conclusão.

- **AC-011-015** (cobre NFR-011-003)
  Dado que o registro do evento de etapa "Tira mnemônica" falha por qualquer motivo, quando
  uma mutação de Quadro (geração inicial, criação, edição, remoção ou reordenação) está em
  andamento, então a mutação inteira é revertida — nenhum estado meio-salvo — e o sistema
  informa um erro genérico ao usuário.

- **AC-011-016** (cobre FR-011-010)
  Dado um Conteúdo bruto com Quebra da regra e Tira mnemônica, quando a Tira mnemônica é
  gerada, exibida ou mutada por qualquer ação desta superfície, então nenhuma leitura nem
  escrita ocorre no modelo de Mnemônico legado (`Mnemonic.hook`/`decoding`) daquele
  conteúdo.

- **AC-011-017** (cobre NFR-011-001)
  Dado um usuário autenticado com papel STUDENT, ou uma requisição sem sessão válida, quando
  ele tenta acessar a tela ou disparar qualquer mutação da Tira mnemônica, então o sistema
  recusa o acesso.

- **AC-011-018** (cobre NFR-011-004)
  Dado o mecanismo de evento de etapa de produção já existente (com os tipos "Conteúdo
  bruto" e "Quebra da regra" de F3), quando o novo tipo "Tira mnemônica" é adicionado, então
  nenhum evento já emitido ou a emitir para os tipos existentes muda de comportamento — a
  extensão é aditiva.

- **AC-011-019** (cobre NFR-011-005)
  Dado qualquer texto exibido na tela da Tira mnemônica (rótulos, mensagens de estado,
  confirmações e erros), quando ele é apresentado ao EDITOR ou ADMIN, então está em
  português do Brasil.

- **AC-011-020** (cobre NFR-011-006)
  Dada uma Quebra da regra com Tira mnemônica já gerada, quando o Conteúdo bruto de origem é
  removido (soft-delete), então a Tira mnemônica e todos os seus Quadros ficam inalcançáveis
  (mesmo padrão do restante do acervo), com os dados preservados para eventual expurgo
  futuro.

- **AC-011-021** (cobre FR-011-008)
  Dada uma Tira mnemônica gerada automaticamente (FR-011-001) que nunca recebeu nenhuma
  mutação humana de Quadro, quando o EDITOR ou ADMIN reabre a tela a qualquer momento
  depois, então a etapa "Tira mnemônica" permanece com apenas o evento de abertura
  registrado — sem evento de conclusão nem de retrabalho —, e a etapa aparece como ABERTA
  (não concluída).

- **AC-011-022** (cobre NFR-011-001)
  Dado um EDITOR autenticado, quando ele tenta acessar ou mutar a Tira mnemônica (ou
  qualquer Quadro dela) de um Conteúdo bruto que não alcança (registrado por outro EDITOR),
  então o sistema recusa a operação com a mesma resposta que usa para um identificador
  inexistente ou removido — sem que a mensagem ou o código de retorno distingam "não existe"
  de "existe mas você não alcança" de "foi removido".

- **AC-011-023** (cobre FR-011-001)
  Dado um Conteúdo bruto cuja Quebra da regra ainda não foi salva, quando o EDITOR ou ADMIN
  abre a visão daquele Conteúdo bruto, então nenhuma ação de gerar a Tira mnemônica é
  oferecida na tela, e o sistema orienta, em português, a concluir a Quebra da regra
  primeiro.

- **AC-011-024** (cobre FR-011-005)
  Dada uma Tira mnemônica com um ou mais Quadros, quando o EDITOR remove o último Quadro
  restante e a operação conclui com sucesso, então a Tira passa a exibir um estado de Tira
  vazia, com a ação de criar um novo Quadro disponível, e o sistema não dispara nenhuma
  regeneração automática a partir da Quebra da regra.

- **AC-011-025** (cobre FR-011-002, NFR-011-003)
  Dada uma Quebra da regra sem Tira mnemônica ainda, quando duas requisições concorrentes de
  primeira abertura chegam ao sistema para essa mesma Quebra, então, ao final, existe
  exatamente uma Tira mnemônica persistida para ela — nunca duas — independentemente de qual
  requisição "vence".

## 8. Premissas e decisões prévias

- **A-011-001** [assumido] [evidência: crença] A Tira mnemônica é 1:1 com a Quebra da regra
  (e, por transitividade, com o Conteúdo bruto) — mesmo padrão de RuleBreakdown 1:1
  RawContent de F2 (mnemonicos-backend/prisma/schema.prisma:333-350). Origem: decisão do
  Diretor na largada desta SPEC. Reabrir se: uma fatia futura exigir Tira compartilhada
  entre múltiplas Quebras (não previsto pela TAP).
- **A-011-002** [assumido] [evidência: crença] Geração inicial: um Quadro por Bloco da
  quebra não-vazio, na ordem canônica CONCEITO → AÇÃO → OBJETO → CONDIÇÃO → EXCEÇÃO; Blocos
  nulos ("não se aplica") não geram Quadro. Origem: BRIEF-011 §Lacunas ("forma da derivação a
  partir da Quebra da regra... resolvida nesta largada — Etapa 1 do specify: quadros nascem
  pré-preenchidos a partir dos 5 blocos").
- **A-011-003** [assumido] [evidência: crença] Depois de gerada, a Tira é livre: não há
  vínculo fixo e permanente entre um Quadro e o Bloco da quebra que o originou — o EDITOR
  cria, edita, remove e reordena sem restrição herdada da geração inicial. Origem: decisão
  do Diretor na largada. Reabrir se: uma fatia futura precisar rastrear a proveniência de
  cada Quadro (ex.: auditoria de fidelidade ao texto normativo).
- **A-011-004** [assumido] [evidência: crença] O risco do épico ("ordenação de quadros sem
  transação quebra a tira silenciosamente", BRIEF-2026-08-27-mnemora-studio-epic.md §Riscos
  por fatia/F4) vira requisito não-funcional explícito desta SPEC (NFR-011-002), não fica
  implícito nem delegado ao PLAN decidir se vale a pena declarar.
- **A-011-005** [assumido] [evidência: observação] O valor novo de etapa "Tira mnemônica" é
  aditivo ao enum de tipo de etapa já existente (hoje com "Conteúdo bruto" e "Quebra da
  regra"), reusando o mecanismo de emissão/leitura de F3 sem redesenho —
  mnemonicos-backend/src/modules/production-events/production-events.service.ts:1-105;
  mnemonicos-backend/prisma/schema.prisma:69-75.
- **A-011-006** [assumido] [evidência: crença] Toda mutação de Tira (geração inicial e
  qualquer CRUD/reordenação de Quadro) emite o evento de etapa na mesma operação atômica da
  mutação de negócio; falha na emissão reverte a mutação inteira (fail-secure) — mesmo
  padrão de NFR-009-002/AC-009-010 de F3.
- **A-011-007** [assumido] [evidência: observação] O modelo `Mnemonic` legado
  (`hook`/`decoding`) fica dormente a partir desta fatia: a fábrica não lê nem escreve mais
  nele — mnemonicos-backend/prisma/schema.prisma:96-120. Já estava invisível nas telas de
  produção desde F2 (A-005-013, SPEC-005); esta fatia encerra a leitura/escrita residual — o
  legado fica sem consumidor algum, e RISK-005-004 (INDEX.md) é reclassificado (não baixado),
  de "duas representações vivas da fonte" para "dado dormente duplicado", sucedido por
  RISK-011-001 (§9). A baixa/reclassificação formal no INDEX.md é ato do Tech Lead na Etapa 5,
  fora desta SPEC. A remoção física dos dados/schema fica fora de escopo (decisão destrutiva
  não solicitada pelo Diretor — §4.2).
- **A-011-008** [assumido] [evidência: observação] Autorização: mesma barreira EDITOR/ADMIN
  das fatias anteriores (nunca STUDENT) — padrão `requireRole('EDITOR','ADMIN')` reusado por
  toda superfície de fábrica (mnemonicos-backend/src/modules/contents/contents.routes.ts:1-144).
- **A-011-009** [assumido] [evidência: crença] Reordenação por controles simples de
  interface (ex.: mover para cima/baixo, campo de posição), sem drag-and-drop novo — origem:
  estimativa do BRIEF-011 ("Premissas"). Reabrir se: o `product-designer` ou o PO julgarem
  drag-and-drop necessário para a usabilidade real da tela.
- **A-011-010** [assumido] [evidência: crença] Geração, CRUD e reordenação da Tira mnemônica
  compõem um único fluxo entregável, testável ponta a ponta pelo QA (EDITOR abre uma Quebra
  da regra existente → gera a Tira → edita/reordena/faz CRUD dos Quadros → os dados
  persistem e reaparecem ao reabrir) — por isso esta SPEC não declara FEATs. Origem: decisão
  do Diretor na largada desta SPEC (Etapa 1 do specify já resolvida).
- **A-011-011** [assumido] [evidência: crença] A geração inicial grava, em cada Quadro criado
  automaticamente, um carimbo de proveniência nullable (referência ao Bloco da quebra de
  origem daquele Quadro específico), gravado só no momento da geração — metadado informativo
  para uma fatia futura (ex.: F9, revisão jurídica), sem nenhuma regra de negócio desta SPEC
  que o leia ou dependa dele; não é garantia de fidelidade do texto atual, pois o EDITOR pode
  reescrever o Quadro livremente depois sem que o carimbo mude ou seja invalidado. Não
  contradiz A-011-003 (que nega vínculo funcional/permanente entre Quadro e Bloco, não a
  existência de um metadado informativo). Origem: pacote de correção desta SPEC (veredito do
  PO / crítica do product-analyst, contra BRIEF-011).

## 9. Riscos e questões abertas

- **RISK-011-001** Os campos `Mnemonic.hook`/`decoding`/`source` permanecem no schema sem
  consumidor após esta fatia — duplicidade de dado dormente até uma fatia futura decidir
  expurgar ou migrar (mesma natureza de RISK-005-001, INDEX.md). Mitigação: nomeado
  explicitamente no Out-of-scope (§4.2); revisitar quando F8 (versionamento) ou uma limpeza
  de schema for planejada.
- **RISK-011-002** Sem drag-and-drop (A-011-009), a usabilidade de reordenar Tiras com mais
  Quadros do que o teto inicial de 5 (o EDITOR pode criar Quadros novos via CRUD livre) pode
  ficar pobre com controles simples de mover para cima/baixo. Mitigação: aceito nesta fatia;
  revisitar se o piloto (PIL-001, INDEX.md) reportar atrito real na tela.
- **RISK-011-003** A garantia de atomicidade da reordenação (NFR-011-002) depende do
  mecanismo técnico que o PLAN escolher para implementá-la; se o PLAN optar por uma
  estratégia que não garanta atomicidade real (ex.: múltiplas escritas independentes sem
  reversão conjunta), o risco original do épico ("ordenação de quadros sem transação quebra
  a tira silenciosamente") reabre na prática, mesmo com o NFR declarado aqui. Mitigação: o
  gate de revisão de código do PLAN/TASKs deve provar a atomicidade, não apenas declará-la.
- **RISK-011-004** O payload mínimo do evento de etapa (herdado do desenho de F3,
  RISK-009-001, INDEX.md) não distingue qual ação de CRUD (criar, editar, remover ou
  reordenar) gerou um retrabalho de "Tira mnemônica" — se F10 precisar decompor por
  sub-causa, o dado já emitido não permite reconstrução retroativa. Mitigação: aceito nesta
  fatia pelo mesmo motivo de RISK-009-001; o gap só se soma para eventos futuros, sem
  completar o passado.
- **RISK-011-005** Conflito de intenção na reordenação: dois EDITORES reordenando a mesma
  Tira mnemônica ao mesmo tempo podem sofrer last-write-wins sobre um payload de nova
  sequência calculado contra um conjunto de Quadros que já mudou (foi criado, removido ou
  reordenado por outro) entre o carregamento da tela e o envio. Mitigação: aceito nesta
  fatia — operação de 1 pessoa (RISK-002-001, INDEX.md); revisitar se o piloto (PIL-001,
  INDEX.md) rodar com 2 ou mais EDITORES simultâneos sobre o mesmo acervo.
- **RISK-011-006** Assimetria de granularidade do retrabalho entre F2 (1 evento de
  retrabalho por salvamento de tela inteira da Quebra da regra) e F4 (1 evento de retrabalho
  por mutação atômica de Quadro): F10 não pode comparar CONTAGEM de eventos de retrabalho
  entre as duas etapas sem normalizar pela granularidade de cada uma. Mitigação: a DURAÇÃO
  (lead time) entre abertura e conclusão segue comparável entre etapas, independente da
  granularidade de retrabalho; F10 deve preferir essa métrica para comparação entre etapas.
- **RISK-011-007** Sem teto de quantidade de Quadros por Tira nem limite de tamanho de texto
  por Quadro nesta fatia — o Quadro é unidade destinada a uma página do PDF de F5/F6
  (futuro). Tiras produzidas sem essas restrições podem não ter forma de página quando F5/F6
  existirem. Mitigação: aceito nesta fatia; revisitável quando a paginação (F5/F6) existir e
  definir o teto real.
- **Q-011-001** Esta SPEC assume que nenhuma outra superfície do sistema (fora da fábrica)
  ainda lê o modelo `Mnemonic` legado — o scheduler/revisão espaçada segue dormente por
  decisão anterior do produto (MAP.md, "Revisão espaçada (dormente por A-005)"). Se essa
  premissa mudar (alguma tela do estudante voltar a depender de `Mnemonic`), a
  reclassificação de RISK-005-004 nesta fatia precisa ser revisitada antes de prosseguir
  para uma eventual remoção física futura.

## 10. Fora deste documento

Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e
`/keelson:tasks`.
