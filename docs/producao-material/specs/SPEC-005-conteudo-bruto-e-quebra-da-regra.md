# SPEC-005: Conteúdo bruto e quebra da regra

**Slug**: producao-material
**Jira**: KAN-6
**Status**: Approved
**Versão**: 0.2
**Autor**: time keelson (scribe)
**Data**: 2026-09-01
**Brief**: BRIEF-005

## 1. Contexto e objetivo

### 1.1 Problema

A fábrica interna (fatia F1 do épico MNEMORA STUDIO) já tem acesso, sessão e papéis de
produção, mas **não tem a primeira estação da linha**. Hoje o EDITOR não tem onde
registrar o texto normativo bruto que precisa transformar em estrutura reutilizável: a
única representação próxima é um campo de texto livre para "fonte" acoplado à entidade de
mnemônico, não há lugar para a classificação por risco de prova, e a decomposição da
regra nos blocos que o método pede não existe como dado. Além disso, a interface já
dispara chamadas de listagem que o servidor não atende — inclusive uma que só faz sentido
para o estudante, que não é usuário deste software.

### 1.2 Outcome esperado

Um EDITOR cola um texto normativo bruto, atribui a disciplina e o tema/assunto, classifica
o item por uma das classes do **radar de prova**, aponta a **fonte normativa** de forma
estruturada e decompõe a regra nos cinco blocos mais a síntese — e tudo isso fica
persistido e reaparece ao recarregar e na listagem. É a matéria-prima de que as fatias
seguintes derivam os artefatos que convertem **reconhecimento em evocação** (tira,
flashcards); esta fatia entrega a **estrutura**, ainda não o artefato de estudo.

### 1.3 Métrica de sucesso

**Primária (produto)** — até a Entrega de F2: o número de Conteúdos brutos de Obrigação
Tributária com **Quebra da regra completa** produzidos **pela tela** (não pela semente),
mais a razão `registrados : com-quebra`. É apurada por **observação humana** e registrada
no relatório de Entrega — **não** é instrumentação de evento; a instrumentação de tempo por
etapa da fábrica segue sendo de F3.

**(a) Conformidade de rotas — não-regressão**: 100% das rotas da superfície nova constam do
censo da suíte de conformidade de rotas herdada de F1, com **0 rota não-declarada**.

**(b) Invariante (não é métrica)**: todo Conteúdo bruto persistido tem uma classe do radar
de prova atribuída — **sem nenhum caminho de escrita** (interface, semente ou correção) que
crie um Conteúdo bruto sem classe. É um invariante do sistema, **provado** por AC-005-002 /
AC-005-003 e pela semente (AC-005-027); não um número a medir.

**Fonte de medição**: para (a), externa — a suíte de conformidade de rotas herdada de F1 (a
mesma que é fonte da métrica §1.3 da SPEC-002), executada no CI; dono: time de engenharia;
natureza **conformidade** (verde/vermelha), não instrumentação de evento de negócio. A
métrica **primária** é **observacional**: apurada por inspeção humana no relatório de
Entrega. Prazo: Entrega de F2.

## 2. Personas e jobs-to-be-done

- **EDITOR** (ator primário) — produtor de conteúdo interno. JTBD: *"registrar um texto
  normativo bruto e transformá-lo numa estrutura reutilizável (blocos + síntese + fonte
  estruturada + classe de risco) de que eu possa derivar artefatos mnemônicos depois."*
- **ADMIN** — também produz nesta superfície (superconjunto do EDITOR aqui) e já tem a
  gestão de contas de F1. Mesmo JTBD do EDITOR nesta fatia.
- **Anti-persona**: o **estudante concursando** não acessa esta superfície. Requisito que
  só faz sentido para ele está na fatia errada (herda a anti-persona do BRIEF-001).

## 3. Glossário (Ubiquitous Language)

| Termo | Definição | Proveniência |
|-------|-----------|--------------|
| **Fábrica** | Ferramenta interna de produção do material mnemônico; o estudante nunca entra nela | BRIEF-001 (A-001) |
| **Conteúdo bruto** | O texto normativo colado por um EDITOR mais a sua metadação de classificação: disciplina, tema/assunto e classe do radar de prova; é a primeira estação da linha de produção | BRIEF-005 §Pedido (1); tela "Novo Conteúdo" (BRIEF-001, origem `telas-sugeridas-1-studio.png`) |
| **Disciplina** | Área do direito a que o Conteúdo bruto pertence (ex.: Direito Tributário) | Entidade `Discipline` já existente — MAP.md (`schema.prisma`); BRIEF-005 |
| **Tema/assunto** | Subdivisão da disciplina a que o Conteúdo bruto pertence (ex.: Obrigação Tributária) | Entidade `Topic` já existente — MAP.md (`schema.prisma`); BRIEF-005 |
| **Radar de prova** | Classificação do conteúdo por risco de prova | BRIEF-001 (TAP §3.2 camada 1). ⚠️ RDR-001: as telas sugeridas usam três prioridades (Alta/Média/Baixa); o mapeamento entre as cinco classes da TAP e as três do mockup foi **selado por A-005-001** |
| **Classe do radar de prova** | Uma de: `ALTA`, `MEDIA`, `DETALHE`, `EXCECAO`, `PEGADINHA` — o vocabulário do método e o dado persistido no Conteúdo bruto | BRIEF-005 P-01 / A-005-001 (TAP §3.2 camada 1) |
| **Prioridade de apresentação** | Rótulo derivado (não persistido): `ALTA` → "Alta", `MEDIA` → "Média", `DETALHE`/`EXCECAO`/`PEGADINHA` → "Baixa" — rótulo aplicado quando houver um eixo de prioridade real (fatia F10); **não exibido em F2** | A-005-001 (derivação das três prioridades das telas sugeridas) |
| **Quebra da regra** | Decomposição do texto normativo bruto nos cinco blocos (CONCEITO · AÇÃO · OBJETO · CONDIÇÃO · EXCEÇÃO), mais a síntese da regra essencial em linguagem tecnicamente correta e reduzida ao núcleo | BRIEF-001 (TAP §3.2 camadas 2–3 e §3.3; tela "Quebra da Regra") |
| **Bloco da quebra** | Cada um dos cinco campos textuais independentes da Quebra da regra: CONCEITO, AÇÃO, OBJETO, CONDIÇÃO, EXCEÇÃO | BRIEF-001 (glossário) / BRIEF-005 P-03 |
| **Síntese da regra essencial** | A regra reduzida ao seu núcleo, em linguagem tecnicamente correta | BRIEF-001 (TAP §3.3) |
| **Fonte normativa** | O dispositivo oficial que sustenta a regra: CF, CTN, lei, lei complementar, súmula, ato normativo — nesta fatia deixa de ser texto livre e passa a referência estruturada | BRIEF-001 (TAP §4.3); INDEX consolidado |
| **Tipo do dispositivo** | O gênero da fonte normativa: CF, CTN, lei, lei complementar, súmula, ato normativo | BRIEF-001 (enumeração do glossário) / BRIEF-005 §Pedido (3) |
| **Citação do dispositivo** | O apontador textual do dispositivo dentro da fonte (ex.: "CTN, art. 113") | BRIEF-005 §Pedido (3) |
| **Tira mnemônica** | Sequência **ordenada** de quadros que reconstrói uma regra — **fora desta fatia (F4)**; citada aqui só para distingui-la da Quebra da regra | BRIEF-001; INDEX consolidado |
| **Papel** | Atributo da conta: STUDENT (dormente), EDITOR (produção/autoria), ADMIN (gestão + revisão + aprovação) | SPEC-002 (INDEX consolidado) |
| **Deny-by-default** | Postura em que uma rota é inacessível a menos que declare explicitamente os papéis que a alcançam; ausência de declaração nega | SPEC-002 (INDEX consolidado) |

## 4. Escopo

### 4.1 In-scope

1. **Registro de Conteúdo bruto** pelo EDITOR: texto normativo colado + disciplina +
   tema/assunto + classe do radar de prova (obrigatória).
2. **Listar, editar e remover** os Conteúdos brutos que o EDITOR **alcança** (por autoria);
   o ADMIN alcança **todos, em leitura e escrita**. A **autoria** ("quem registrou") é
   preservada em qualquer edição — inclusive quando um ADMIN altera item alheio
   (A-005-006 revisada).
3. **Quebra da regra** a partir de um Conteúdo bruto: preencher os cinco blocos + a
   síntese; rever e alterar; a quebra é **1:1** com o conteúdo.
4. **Fonte normativa estruturada** no Conteúdo bruto: tipo do dispositivo + citação do
   dispositivo + link opcional — substitui a fonte em texto livre.
5. **Autorização**: toda a superfície nova (rotas e telas) exige sessão com papel EDITOR
   ou ADMIN; recusada por padrão sem isso — reusa a barreira de F1.
6. **Semente de conteúdo de exemplo** passa a ser de Obrigação Tributária (Direito
   Tributário), substituindo o material de Direito Administrativo/Constitucional hoje
   carregado.
7. **Saneamento do contrato de leitura já chamado pela interface**: a listagem de Conteúdo
   bruto passa a ter contrato real e estável; a chamada de consulta de flashcards devidos
   (consumo do estudante) é removida da interface. A listagem tem **estados observáveis**
   (carregando, vazio, falha de carregamento) e **ordenação determinística** (mais recente
   primeiro), sem filtros nesta fatia.
8. **Navegação até a Quebra da regra**: a partir da listagem — ou da visão de um Conteúdo
   bruto — o EDITOR alcança a Quebra da regra daquele conteúdo.

### 4.2 Out-of-scope

- **Tira mnemônica como sequência ordenada de quadros** — F4. (In-scope 3 introduz
  "blocos"; a tira como storyboard numerado é F4, que *substitui, não estende*.)
- **Biblioteca / associação visual** — F5. (In-scope 3 estrutura a regra; "e a imagem que
  ajuda a lembrar?" → F5.)
- **Geração / exportação de PDF** — F6. (In-scope 1 registra o insumo; "e a saída
  publicável?" → F6.)
- **Contraste e pegadinha como entidade comparativa lado-a-lado** — F7. (Aqui `PEGADINHA`
  é apenas uma classe do radar; pegadinha como entidade em modo comparação é F7.)
- **Versionamento editorial / histórico / fechamento legislativo como trilha** — F8.
  (In-scope 4 dá a fonte estruturada; "e o histórico de versão / a data de fechamento da
  legislação?" → F8. Nesta fatia a fonte normativa é referência estruturada **sem** trilha
  de versão.)
- **Instrumentação de tempo por etapa da fábrica** — F3. (In-scope 1 e 3 são etapas da
  linha; "e a medição de horas/página?" → F3.)
- **Qualquer tela ou rota voltada ao estudante; consulta de flashcards devidos** —
  anti-persona. (In-scope 7 saneia a interface; "e as telas do estudante?" → fora.)
- **Painel / dashboard de produção** — F10. (In-scope 2 lista itens; "e a produção em
  números?" → F10.)
- **Exibição da prioridade de apresentação (Alta/Média/Baixa)** — F10, a fatia que terá um
  eixo de prioridade real. O mapeamento das cinco classes do radar → três prioridades
  continua **selado em A-005-001** (rótulo derivado, não persistido); só a **exibição** é
  adiada. RDR-001 permanece resolvido. (In-scope 7 fala em listagem; "e o selo
  Alta/Média/Baixa na tela?" → F10.)
- **Rascunho / salvar Quebra da regra incompleta** — F2 exige completude mínima (CONCEITO,
  AÇÃO, OBJETO, síntese); salvar parcial é aditivo futuro (ver A-005-012 e o "Reabrir se"
  de F3). (In-scope 3 preenche os blocos; "e salvar pela metade?" → fora.)
- **Filtro da listagem** (por disciplina, tema/assunto ou classe do radar) — F10 define o
  eixo de triagem; F2 documenta a **forma e a ordenação** da resposta, sem filtros.
  (In-scope 7 dá contrato à listagem; "e filtrar por disciplina?" → F10.)
- **Expurgo definitivo / restauração via UI** de Conteúdo bruto removido — F8 ou
  administração. F2 faz **remoção reversível com marca temporal** (os dados ficam
  preservados), sem tela de restauração. (In-scope 2 remove itens; "e desfazer / apagar de
  vez?" → fora.)
- **Extração automática / NLP / IA da regra essencial** — A-005-002. (In-scope 3 fala em
  "preencher"; "é automático?" → não, é o EDITOR preenchendo campos estruturados.)
- **Reconstrução de autenticação, sessão ou barreira de papéis** — entregue em F1.
  (In-scope 5 exige papel; "e o login / a rotação de sessão / os papéis?" → reusa F1.)
- **Cadastro de nova disciplina ou tema/assunto pela tela de produção** — assume-se
  seleção do acervo já semeado (A-005-007). (In-scope 1 exige disciplina e tema; "e se não
  existir a disciplina?" → fora desta fatia.)
- **Migração do texto livre de fonte hoje existente na entidade de mnemônico** — o campo
  antigo é **preservado** até F4 consumir a nova fonte estruturada (A-005-010). (In-scope
  4 substitui a forma da fonte; "e os dados antigos?" → permanecem, F4 encerra.)

## 5. Requisitos funcionais (EARS)

### FEAT-005-001: Conteúdo bruto — registro, classificação e fonte normativa

**Jira**: KAN-27

> QA: um EDITOR autenticado registra um texto normativo bruto com disciplina, tema/assunto,
> classe do radar de prova e fonte normativa estruturada; recarrega e revê; lista, edita e
> remove os itens que registrou. Testável de ponta a ponta sem depender da Quebra da regra.

- **FR-005-001** [MUST] Quando um EDITOR submete um novo Conteúdo bruto com texto
  normativo, disciplina, tema/assunto e classe do radar de prova válidos, o sistema DEVE
  persistir o item e associá-lo ao EDITOR que o registrou.
- **FR-005-002** [MUST] Se a submissão de um Conteúdo bruto não traz classe do radar de
  prova, ou traz um valor fora do conjunto {`ALTA`, `MEDIA`, `DETALHE`, `EXCECAO`,
  `PEGADINHA`}, então o sistema DEVE recusar a persistência, sinalizar o campo de classe
  como pendente/inválido e não criar o item.
- **FR-005-003** [MUST] Se o texto normativo, a disciplina ou o tema/assunto estão
  ausentes na submissão de um Conteúdo bruto, então o sistema DEVE recusar a persistência
  e sinalizar quais desses campos faltam; a recusa **não descarta** o que já foi digitado
  nos demais campos.
- **FR-005-004** [MUST] As ações de **registrar** e **editar** um Conteúdo bruto na
  interface DEVEM expor três estados observáveis: *em andamento* (controle de envio
  desabilitado, indicador de progresso visível), *sucesso* (confirmação exibida e o item
  aparece/atualiza na listagem) e *falha* (mensagem de erro em pt-BR, dados digitados
  preservados no formulário, nada persistido).
- **FR-005-005** [MUST] O sistema DEVE listar os Conteúdos brutos que o EDITOR registrou
  (o ADMIN vê todos), exibindo para cada item o texto (ou um resumo), a disciplina, o
  tema/assunto e a classe do radar de prova.
- **FR-005-006** [MUST] Quando um EDITOR reabre um Conteúdo bruto que registrou, o sistema
  DEVE exibir texto normativo, disciplina, tema/assunto, classe do radar de prova e fonte
  normativa exatamente como persistidos.
- **FR-005-007** [MUST] Quando um EDITOR salva alterações em um Conteúdo bruto que
  **alcança** (A-005-006), o sistema DEVE persistir os novos valores sob as mesmas regras
  de obrigatoriedade do registro (FR-005-002, FR-005-003). A autoria ("quem registrou") é
  **imutável** — nunca sobrescrita por quem edita.
- **FR-005-008** [MUST] Quando um EDITOR remove um Conteúdo bruto que **alcança**
  (A-005-006), o sistema DEVE aplicar **remoção reversível com marca temporal**: o Conteúdo
  bruto e a Quebra da regra a ele vinculada saem da listagem e **deixam de ser
  alcançáveis** — inclusive por identificador direto e pela superfície de Quebra da regra —,
  e os dados são preservados para eventual expurgo futuro (F8). Não há UI de restauração em
  F2. A autoria ("quem registrou") permanece inalterada.
- **FR-005-009** [MUST] A ação de remover um Conteúdo bruto DEVE pedir confirmação
  explícita antes de executar e expor os três estados observáveis: *em andamento*
  (controle desabilitado), *sucesso* (o item some da listagem) e *falha* (o item
  permanece, mensagem de erro em pt-BR).
- **FR-005-010** [MUST] Quando um EDITOR informa a fonte normativa de um Conteúdo bruto, o
  sistema DEVE registrá-la de forma estruturada com tipo do dispositivo (`CF`, `CTN`,
  `lei`, `lei complementar`, `súmula`, `ato normativo`), citação do dispositivo e link
  opcional.
- **FR-005-011** [MUST] Se o tipo do dispositivo informado está fora do conjunto
  conhecido, ou a citação do dispositivo está ausente quando há tipo informado, então o
  sistema DEVE recusar o salvamento e sinalizar o campo inválido.
- **FR-005-012** [MUST] O sistema DEVE exibir a fonte normativa estruturada (tipo,
  citação, link) ao reabrir o Conteúdo bruto, e DEVE exibir ao menos a citação do
  dispositivo na listagem.
- **FR-005-013** [MUST] O sistema DEVE registrar, em cada Conteúdo bruto, **quem fez a
  última alteração e quando** — um par de campos de estado atual, **sem trilha histórica**
  (a trilha é de F8). A autoria original ("quem registrou") permanece inalterada.
<!-- FR-005-022/023/024 seguem numeração de alocação; por conteúdo, FR-005-022 (navegação
para a Quebra) pertence a FEAT-005-002 e FR-005-023/024 (estados e ordenação da listagem)
a esta FEAT — daí a sequência não-contígua. -->
- **FR-005-023** [MUST] A listagem de Conteúdos brutos DEVE expor três estados
  observáveis: *carregando* (indicador enquanto os dados chegam), *vazio* (mensagem em
  pt-BR que orienta a próxima ação — primeira execução da fábrica ou remoção do último
  item) e *falha de carregamento* (mensagem em pt-BR com opção de repetir).
- **FR-005-024** [MUST] A listagem de Conteúdos brutos DEVE ter ordenação determinística
  (mais recente primeiro) e forma de resposta estável, documentada nesta fatia; sem
  filtros nesta fatia.

### FEAT-005-002: Quebra da regra — decomposição estruturada 1:1

**Jira**: KAN-28

> QA: a partir de um Conteúdo bruto existente, um EDITOR preenche os cinco blocos e a
> síntese da regra essencial, recarrega e revê, altera e salva. A quebra é 1:1 com o
> conteúdo. Testável de ponta a ponta sobre um Conteúdo bruto já registrado.

- **FR-005-014** [MUST] Quando um EDITOR salva a Quebra da regra de um Conteúdo bruto, o
  sistema DEVE persistir os cinco blocos (CONCEITO, AÇÃO, OBJETO, CONDIÇÃO, EXCEÇÃO) como
  campos textuais independentes e a síntese da regra essencial, vinculados a esse Conteúdo
  bruto.
- **FR-005-015** [MUST] O sistema DEVE manter no máximo uma Quebra da regra por Conteúdo
  bruto; um novo salvamento de Quebra da regra para um conteúdo que já a tem DEVE
  **atualizar** a existente, não criar outra.
- **FR-005-016** [MUST] Se o Conteúdo bruto alvo não existe ou foi removido, então o
  sistema DEVE recusar a criação ou a edição da Quebra da regra.
- **FR-005-017** [MUST] Se CONCEITO, AÇÃO, OBJETO ou a síntese da regra essencial estão
  ausentes ao salvar a Quebra da regra, então o sistema DEVE recusar e sinalizar os campos
  pendentes; CONDIÇÃO e EXCEÇÃO PODEM ficar vazios (A-005-009). A recusa **não descarta** o
  que já foi digitado nos demais blocos.
- **FR-005-018** [MUST] A ação de salvar a Quebra da regra na interface DEVE expor três
  estados observáveis: *em andamento* (envio desabilitado, indicador visível), *sucesso*
  (confirmação exibida) e *falha* (mensagem de erro em pt-BR, texto digitado preservado).
  Uma recusa de validação **não descarta** o que foi digitado — os blocos preenchidos
  permanecem na interface.
- **FR-005-019** [MUST] Quando um EDITOR reabre a Quebra da regra de um Conteúdo bruto, o
  sistema DEVE exibir os cinco blocos e a síntese exatamente como persistidos.
- **FR-005-020** [MUST] Quando um EDITOR salva alterações na Quebra da regra, o sistema
  DEVE persistir os novos valores sob as mesmas regras de obrigatoriedade de FR-005-017;
  uma recusa de validação **não descarta** o que foi digitado.
- **FR-005-021** [SHOULD] O sistema DEVE indicar, na listagem de Conteúdos brutos ou na
  visão de um conteúdo, se o Conteúdo bruto já tem Quebra da regra.
- **FR-005-022** [MUST] O sistema DEVE oferecer, a partir da listagem de Conteúdos brutos e
  da visão de um Conteúdo bruto, uma via de acesso pela qual o EDITOR alcança a Quebra da
  regra daquele conteúdo.

## 6. Requisitos não-funcionais

- **NFR-005-001** [MUST] Toda rota e tela da superfície de Conteúdo bruto e de Quebra da
  regra DEVE exigir sessão autenticada com papel EDITOR ou ADMIN; ausência de sessão ou
  papel insuficiente DEVE ser recusada por padrão (**deny-by-default**), reusando a
  barreira de F1 — declaração explícita dos papéis na montagem e verificação no servidor.
  A superfície nova DEVE entrar no censo da suíte de conformidade de rotas sem exceção.
- **NFR-005-002** [MUST] Identificadores de código em inglês; **todo** texto de interface
  (rótulos, mensagens, erros de validação) em pt-BR.
- **NFR-005-003** [MUST] A carga de exemplo do sistema DEVE ser de Obrigação Tributária
  (Direito Tributário), substituindo o material de Direito Administrativo/Constitucional
  hoje carregado (não coexiste); DEVE incluir ao menos um Conteúdo bruto com classe do
  radar de prova e fonte normativa estruturada, e a sua Quebra da regra.
- **NFR-005-004** [MUST] A listagem de Conteúdo bruto consumida pela interface DEVE ter
  **contrato definido e estável** — a forma da resposta e a **ordenação** (mais recente
  primeiro) documentadas nesta fatia, **sem** prometer filtros. As chamadas da interface a
  consumos fora desta fatia (consulta de flashcards devidos do estudante) DEVEM ser
  removidas.
- **NFR-005-005** [MUST] As representações de domínio compartilhadas entre cliente e
  servidor introduzidas por esta fatia (classe do radar de prova, tipo do dispositivo,
  formas de Conteúdo bruto e de Quebra da regra) DEVEM ter o mesmo conjunto de valores nas
  duas pontas, no mesmo conjunto de alterações.
- **NFR-005-006** [MUST] A remoção de um Conteúdo bruto DEVE tornar **inalcançável,
  atomicamente**, a Quebra da regra vinculada — nenhuma Quebra da regra permanece
  alcançável após a remoção do seu Conteúdo bruto —, **preservando os dados** para eventual
  expurgo futuro (F8). Sem Quebra da regra órfã alcançável.
- **NFR-005-007** [MUST] O texto livre de fonte hoje existente na entidade de mnemônico
  DEVE ser preservado por esta fatia — não migrado, não apagado, não convertido; sua
  substituição pela fonte estruturada é responsabilidade de F4.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-005-001** (cobre FR-005-001, FR-005-005) — Dado um EDITOR autenticado, Quando ele
  submete um Conteúdo bruto com texto normativo, disciplina, tema/assunto e classe do
  radar de prova válidos, Então o sistema persiste o item, associa-o ao EDITOR e o item
  passa a constar na listagem dele com disciplina, tema/assunto e classe do radar de
  prova.
- **AC-005-002** (cobre FR-005-002) — Dado um EDITOR preenchendo um Conteúdo bruto sem
  selecionar a classe do radar de prova, Quando ele tenta salvar, Então o sistema recusa,
  sinaliza o campo de classe como pendente e nenhum item é criado.
- **AC-005-003** (cobre FR-005-002) — Dada uma submissão de Conteúdo bruto cuja classe do
  radar de prova não é uma de {`ALTA`, `MEDIA`, `DETALHE`, `EXCECAO`, `PEGADINHA`}, Quando
  o sistema a processa, Então recusa a persistência e nenhum item é criado.
- **AC-005-004** (cobre FR-005-003) — Dado um EDITOR que deixou o texto normativo, a
  disciplina ou o tema/assunto em branco, Quando tenta salvar, Então o sistema recusa e
  lista quais desses campos faltam.
- **AC-005-005** (cobre FR-005-004) — Dado um EDITOR que disparou o salvamento de um
  Conteúdo bruto (registro ou edição), Quando o resultado ainda está pendente, Então o
  controle de envio fica desabilitado e um indicador de progresso fica visível.
- **AC-005-006** (cobre FR-005-004) — Dado um salvamento de Conteúdo bruto que conclui com
  sucesso, Quando o sistema responde, Então a interface mostra confirmação e o item
  aparece (registro) ou reflete os novos valores (edição) na listagem.
- **AC-005-007** (cobre FR-005-004) — Dado um salvamento de Conteúdo bruto que falha,
  Quando o sistema responde, Então a interface mostra mensagem de erro em pt-BR, os dados
  digitados permanecem no formulário e nada é persistido.
- **AC-005-008** (cobre FR-005-006) — Dado um Conteúdo bruto já salvo, Quando o EDITOR o
  reabre após recarregar a tela, Então texto normativo, disciplina, tema/assunto, classe
  do radar de prova e fonte normativa aparecem exatamente como persistidos.
- **AC-005-009** (cobre FR-005-007, FR-005-006) — Dado um EDITOR que altera campos de um
  Conteúdo bruto que alcança e salva, Quando ele recarrega e reabre o item, Então os
  novos valores estão persistidos e visíveis.
- **AC-005-010** (cobre FR-005-004, FR-005-007) — Dado um EDITOR editando um Conteúdo
  bruto, Quando o salvamento da edição falha, Então os três estados observáveis se aplicam
  como no registro (em andamento, sucesso, falha) e a falha preserva o que foi digitado.
- **AC-005-011** (cobre FR-005-008, FR-005-009) — Dado um EDITOR que aciona a remoção de um
  Conteúdo bruto que alcança, Quando ele confirma no pedido explícito de confirmação,
  Então — com o controle desabilitado enquanto a remoção está em curso — o item sai da
  listagem e deixa de ser alcançável ao concluir.
- **AC-005-012** (cobre FR-005-009) — Dada uma remoção de Conteúdo bruto que falha, Quando
  o sistema responde, Então o item permanece na listagem e a interface mostra mensagem de
  erro em pt-BR.
- **AC-005-013** (cobre FR-005-008) — Dado um Conteúdo bruto que tem Quebra da regra
  vinculada, Quando o EDITOR o remove, Então a Quebra da regra vinculada sai junto e não
  fica alcançável.
- **AC-005-014** (cobre FR-005-010, FR-005-012) — Dado um EDITOR que informa a fonte
  normativa com tipo do dispositivo (ex.: `CTN`), citação ("CTN, art. 113") e link, Quando
  salva e reabre o Conteúdo bruto, Então tipo, citação e link aparecem como persistidos.
- **AC-005-015** (cobre FR-005-011) — Dada uma fonte normativa com tipo do dispositivo
  fora do conjunto conhecido, ou com citação ausente quando há tipo informado, Quando o
  EDITOR tenta salvar, Então o sistema recusa e sinaliza o campo inválido.
- **AC-005-016** (cobre FR-005-012) — Dados Conteúdos brutos com fonte normativa
  informada, Quando o EDITOR abre a listagem, Então cada item exibe ao menos a citação do
  dispositivo.
<!-- AC-005-017 removido no pacote de ajustes do PO: a exibição da prioridade de
apresentação saiu de F2 (ver §4.2, item "Exibição da prioridade de apresentação"). O vão
de numeração é mantido de propósito — os ACs seguintes não são renumerados. -->
- **AC-005-018** (cobre FR-005-005) — Dados dois EDITORes com Conteúdos brutos distintos e
  um ADMIN, Quando cada um abre a listagem, Então cada EDITOR vê os itens que registrou e
  o ADMIN vê todos. *(premissa A-005-006)*
- **AC-005-019** (cobre FR-005-014, FR-005-019) — Dado um Conteúdo bruto existente, Quando
  o EDITOR preenche os cinco blocos (CONCEITO, AÇÃO, OBJETO, CONDIÇÃO, EXCEÇÃO) e a síntese
  da regra essencial e salva, Então, ao recarregar e reabrir a Quebra da regra, os cinco
  blocos e a síntese aparecem como persistidos e vinculados a esse conteúdo.
- **AC-005-020** (cobre FR-005-015) — Dado um Conteúdo bruto que já tem Quebra da regra,
  Quando um novo salvamento de Quebra da regra é feito para o mesmo conteúdo, Então a
  quebra existente é atualizada e nenhuma segunda quebra é criada.
- **AC-005-021** (cobre FR-005-016) — Dado um identificador de Conteúdo bruto que não
  existe ou foi removido, Quando se tenta criar ou editar a Quebra da regra para ele,
  Então o sistema recusa a operação.
- **AC-005-022** (cobre FR-005-017) — Dado um EDITOR salvando a Quebra da regra sem
  CONCEITO, AÇÃO, OBJETO ou síntese, Quando tenta salvar, Então o sistema recusa e lista
  os campos pendentes; Dado que CONDIÇÃO e EXCEÇÃO ficaram vazios enquanto os demais estão
  preenchidos, Quando salva, Então o salvamento é aceito — CONDIÇÃO e EXCEÇÃO em branco são
  aceitos como "não se aplica a esta regra", nunca como "inacabado" (A-005-012).
- **AC-005-023** (cobre FR-005-018) — Dado um EDITOR que dispara o salvamento da Quebra da
  regra, Quando o resultado está pendente, conclui ou falha, Então a interface expõe
  respectivamente o estado em andamento (envio desabilitado, indicador), o sucesso
  (confirmação) e a falha (mensagem em pt-BR, texto digitado preservado).
- **AC-005-024** (cobre FR-005-020, FR-005-019) — Dada uma Quebra da regra já salva, Quando
  o EDITOR altera blocos ou a síntese, salva e recarrega, Então os novos valores estão
  persistidos.
- **AC-005-025** (cobre FR-005-021) — Dado um Conteúdo bruto sem Quebra da regra, Quando o
  EDITOR salva a quebra dele, Então a listagem (ou a visão do conteúdo) passa a indicar
  que ele tem Quebra da regra.
- **AC-005-026** (cobre NFR-005-001) — Dada uma requisição sem sessão, Quando ela alcança
  qualquer rota da superfície de Conteúdo bruto ou de Quebra da regra, Então é recusada;
  Dada uma sessão com papel STUDENT, Então também é recusada; Dada uma sessão com papel
  EDITOR ou ADMIN, Então é aceita; e todas as rotas novas constam do censo da suíte de
  conformidade de rotas.
- **AC-005-027** (cobre NFR-005-003) — Dado o sistema após a carga de exemplo, Quando se
  inspeciona o material carregado, Então (i) ele é de Obrigação Tributária (Direito
  Tributário) e inclui ao menos um Conteúdo bruto com classe do radar de prova e fonte
  normativa estruturada mais a sua Quebra da regra; (ii) os temas/assuntos semeados formam
  uma **lista nomeada** conhecida; (iii) o EDITOR consegue registrar um Conteúdo bruto em
  **cada** um dos temas/assuntos semeados; e (iv) não há material de Direito
  Administrativo/Constitucional remanescente da carga.
- **AC-005-028** (cobre NFR-005-004) — Dada a interface em execução, Quando ela carrega as
  telas de produção, Então não emite nenhuma chamada de consulta de flashcards devidos, e
  a listagem de Conteúdo bruto responde no contrato definido nesta fatia (forma e
  ordenação, sem filtros).
- **AC-005-029** (cobre NFR-005-002) — Dada qualquer recusa de validação desta superfície
  (ex.: classe do radar de prova ausente), Quando a mensagem é exibida, Então está em
  pt-BR, e os rótulos das telas estão em pt-BR.
- **AC-005-030** (cobre NFR-005-005) — Dadas as enumerações novas (classe do radar de
  prova, tipo do dispositivo), Quando se comparam as duas pontas da aplicação, Então o
  conjunto de valores é idêntico.
- **AC-005-031** (cobre NFR-005-006) — Dado um Conteúdo bruto com Quebra da regra, Quando
  ele é removido, Então não resta nenhuma Quebra da regra órfã acessível ou consultável.
- **AC-005-032** (cobre NFR-005-007) — Dados mnemônicos com texto livre de fonte
  pré-existente, Quando esta fatia é aplicada, Então esse texto continua legível e não é
  apagado nem convertido.
- **AC-005-033** (cobre FR-005-022) — Dado um Conteúdo bruto na listagem, Quando o EDITOR
  aciona a via de acesso à Quebra da regra, Então a tela da Quebra da regra daquele
  conteúdo é exibida (prova de ponta a ponta da via de entrada).
- **AC-005-034** (cobre FR-005-023) — Dado o carregamento da listagem de Conteúdos brutos,
  Quando os dados ainda não chegaram / não há itens / o carregamento falha, Então a
  interface mostra respectivamente o indicador de *carregando*, a mensagem de *vazio*
  orientando a próxima ação, e a mensagem de *falha* em pt-BR com opção de repetir.
- **AC-005-035** (cobre FR-005-024) — Dados vários Conteúdos brutos criados em momentos
  distintos, Quando o EDITOR abre a listagem, Então eles aparecem do mais recente para o
  mais antigo e a forma da resposta é a documentada nesta fatia.
- **AC-005-036** (cobre FR-005-007, FR-005-008, FR-005-013) — Dado um Conteúdo bruto
  registrado por um EDITOR, Quando um ADMIN o edita e depois o remove, Então a operação é
  aceita, a autoria original (o EDITOR que registrou) permanece inalterada, e o carimbo de
  última alteração passa a apontar o ADMIN e o instante da alteração.
- **AC-005-037** (cobre FR-005-008, NFR-005-006) — Dado um Conteúdo bruto removido, Quando
  se tenta acessá-lo por identificador direto ou abrir a Quebra da regra dele, Então ambos
  são recusados (não encontrado / inacessível).

## 8. Premissas e decisões prévias

- **A-005-001** [assumido] [evidência: crença] — O radar de prova é persistido como as
  **cinco classes da TAP** (`ALTA`, `MEDIA`, `DETALHE`, `EXCECAO`, `PEGADINHA` — §3.2
  camada 1). As três prioridades das telas sugeridas (Alta/Média/Baixa) são **derivação de
  apresentação** (`ALTA` → Alta, `MEDIA` → Média, `DETALHE`/`EXCECAO`/`PEGADINHA` →
  Baixa), não uma segunda dimensão persistida. Resolve RDR-001. Origem: BRIEF-005 P-01.
  **Reabrir se:** F7, F10 ou F11 precisarem priorizar a *natureza* do conteúdo
  (`PEGADINHA`/`EXCECAO`) acima do *grau* (`ALTA`/`MEDIA`/`DETALHE`) — hoje o enum único
  não carrega as duas dimensões.
- **A-005-002** [assumido] [evidência: crença] — A produção intelectual é humana: nesta
  fatia **não há** extração automática, NLP ou IA. "Extrair regra essencial" da tela é o
  EDITOR preenchendo campos estruturados; a fábrica dá a estrutura, valida e persiste.
  Herda A-007 (BRIEF-001). Origem: BRIEF-005 P-02.
- **A-005-003** [assumido] [evidência: crença] — A Quebra da regra é **1:1** com o
  Conteúdo bruto; cada bloco é um campo textual, mais a síntese da regra. A tira mnemônica
  como sequência ordenada de quadros é F4 e está fora. Origem: BRIEF-005 P-03.
- **A-005-004** [assumido] [evidência: crença] — A consulta de flashcards devidos (consumo
  do estudante) sai do produto; a chamada correspondente da interface é removida. A
  superfície de listagem de conteúdo/mnemônicos da interface é realinhada ao contrato real
  que F2 entrega. Origem: BRIEF-005 P-04.
- **A-005-005** [assumido] [evidência: crença] — A barreira de autorização de F1
  (deny-by-default no servidor, papéis EDITOR/ADMIN para produção) é **reusada**, não
  reconstruída; as camadas de estado de card, revisão espaçada, scheduler e vitrine seguem
  dormentes (A-005 do BRIEF-001). Origem: BRIEF-005 P-06.
- **A-005-006** [assumido] [evidência: crença] — Escopo de autoria e alcance: cada EDITOR
  gerencia (lista, edita, remove) os Conteúdos brutos que **alcança**; o ADMIN alcança
  **todos, em leitura e escrita**. A **autoria** ("quem registrou") é imutável e não é
  sobrescrita por quem edita; o estado de última alteração (quem/quando) é registrado à
  parte (FR-005-013). Default: alcance por autor para o EDITOR, alcance total para o ADMIN
  — revisitável em F9/F10 quando o gate de revisão e o painel definirem a visibilidade da
  fábrica inteira. A operação de 1–2 pessoas (RISK-002-001) torna a diferença pequena
  nesta fatia. **Reabrir se:** F9/F10 definirem visibilidade da fábrica inteira ao EDITOR.
- **A-005-007** [assumido] [evidência: crença] — Disciplina e tema/assunto são
  selecionados de registros **já existentes** (semeados); o cadastro de nova
  disciplina/tema pela tela de produção fica fora desta fatia. Default: reaproveitar o
  acervo de disciplinas/temas. **Reabrir se:** E-01 (Q-005-004) for respondida permitindo
  cadastro de tema pelo EDITOR.
- **A-005-008** [assumido] [evidência: crença] — A fonte normativa é **opcional** no
  registro do Conteúdo bruto nesta fatia; quando informada, é estruturada (tipo + citação;
  link opcional). A obrigatoriedade entra no gate de "Versão aprovada" (F9). Default: não
  bloquear o registro inicial — o EDITOR pode colar o texto antes de fixar o dispositivo.
- **A-005-009** [assumido] [evidência: crença] — Obrigatoriedade dos blocos da Quebra da
  regra: CONCEITO, AÇÃO, OBJETO e a síntese são obrigatórios; CONDIÇÃO e EXCEÇÃO são
  opcionais (nem toda regra tem condição ou exceção — o próprio glossário da TAP escreve
  "CONDIÇÃO/EXCEÇÃO" como um par variável). Default declarado.
- **A-005-010** [assumido] [evidência: crença] — O texto livre de fonte hoje existente na
  entidade de mnemônico é **preservado** por esta fatia (nem migrado, nem apagado); sua
  substituição pela fonte estruturada acontece quando F4 consumir a nova referência.
  Origem: BRIEF-005 P-05. **Reabrir se:** F4 consumir a fonte estruturada.
- **A-005-011** [assumido] [evidência: crença] — A carga de exemplo passa a conter
  Obrigação Tributária (Direito Tributário) e **substitui** o material de Direito
  Administrativo/Constitucional hoje carregado (não coexiste). Origem: BRIEF-005 §Pedido
  (6) / A-003 do BRIEF-001.
- **A-005-012** [assumido] [evidência: crença] — Semântica do vazio na Quebra da regra:
  uma Quebra da regra salva com CONCEITO, AÇÃO, OBJETO e síntese da regra essencial é
  **completa** por definição de F2; CONDIÇÃO e EXCEÇÃO em branco significam **"não se
  aplica a esta regra"**, nunca "inacabado". F4 não omite quadro por inferência sobre
  campo vazio; F9 é dona de um eventual estado explícito de completude. **Reabrir se:** F3
  medir interrupção/retrabalho como custo relevante de horas/página (aí entra rascunho /
  salvar incompleto).
- **A-005-013** [assumido] [evidência: crença] — Após F2, o **mnemônico legado**
  (`hook` / `decoding` / `source` em texto livre) **não é conceito visível na fábrica**:
  nenhuma tela de produção o lê ou escreve; seus dados ficam preservados (NFR-005-007) até
  F4 decidir consumi-los e encerrar a duplicidade. A **tira mnemônica de F4 nasce do
  Conteúdo bruto**, não do mnemônico legado. A listagem que a interface passa a consumir é
  a de Conteúdo bruto. Origem: BRIEF-005 P-04 / P-05; MAP.md ("F4 substitui, não
  estende"); BRIEF-001 A-005 (dormência).

## 9. Riscos e questões abertas

- **RISK-005-001** — Colapso de três classes do radar numa só prioridade de apresentação
  (RDR-001 resolvido por A-005-001): `DETALHE`, `EXCECAO` e `PEGADINHA` mapeiam todas para
  "Baixa". Se a fila (F11) ou o painel (F10) precisarem priorizar "pegadinha recorrente"
  acima de "detalhe", o mapa de três prioridades não carrega essa informação — a classe
  persistida (cinco valores) carrega, a derivação não. **Resíduo registrado**: o custo
  real de reverter o mapeamento **não é só migração de schema** — é a **reclassificação
  manual de todo o acervo já produzido**, que é trabalho humano (A-007), não script.
  Mitigação: a classe das cinco fica **persistida** desde F2 (a informação não se perde e
  a prioridade pode ser remapeada sem migração); a **exibição** da prioridade está adiada
  para F10 (§4.2); `Reabrir se` registrado em A-005-001.
- **RISK-005-002** — Contrato de listagem adiantado na interface: a interface já chamava
  rotas de listagem inexistentes, uma delas com forma divergente (lista simples × resposta
  paginada). Fechar o contrato de Conteúdo bruto sem alinhar a forma da resposta repete o
  defeito. Mitigação: NFR-005-004 + AC-005-028. Origem: BRIEF-épico (risco F2) / MAP.md.
- **RISK-005-003** — Dessincronia de vocabulário de domínio entre as duas pontas: enums e
  formas novos mantidos à mão nos dois lados; divergência quebra em runtime sem o
  verificador de tipos acusar. Mitigação: NFR-005-005 + AC-005-030; mudança nas duas
  pontas no mesmo conjunto de alterações. Origem: CLAUDE.md / BRIEF-épico (risco F2).
- **RISK-005-004** — Texto livre de fonte convivendo com a fonte estruturada até F4:
  durante a janela F2→F4 há duas representações da fonte (livre na entidade de mnemônico,
  estruturada no Conteúdo bruto); um leitor do modelo pode tomar uma pela outra. Mitigação:
  A-005-010 registra a razão; **A-005-013** torna o legado **não-visível na fábrica** após
  F2 (nenhuma tela de produção o lê ou escreve); F4 consome a fonte estruturada e encerra
  a duplicidade.
- **RISK-005-005** — Radar obrigatório sem via de escape: se qualquer caminho de escrita
  (semente, importação futura, correção administrativa) criar um Conteúdo bruto sem classe,
  a métrica §1.3 quebra silenciosamente. Mitigação: FR-005-002 no servidor + AC-005-002; a
  semente (NFR-005-003) também classifica.
- **Q-005-001** — O veredito da métrica §1.3 da SPEC-002 (**MET-002-001**) segue pendente:
  a fonte (suíte de conformidade de rotas verde) prova conformidade deny-by-default, não um
  número de negócio. Esta fatia constrói **sobre a conformidade** (provada), não sobre
  valor não provado — não bloqueia a SPEC. Repasse ao Diretor no início e na Entrega deste
  ciclo (decisão 4.99); na Entrega, segue ao Diretor **junto de E-01** (Q-005-004 —
  cadastro de tema).
- **Q-005-002** — Nomes de rota e forma dos payloads da superfície nova **não** são
  decididos aqui (SPEC agnóstica); ficam para o `/keelson:plan`. O BRIEF-005 P-04 antecipa
  candidatos, mas a decisão é do PLAN.
- **Q-005-003** — A migração de dados (aditiva) e a sua execução dependem de confirmação do
  Diretor quando a wave de schema for alcançada (regra do projeto / BRIEF-005 P-05). Não é
  decisão desta SPEC.
- **Q-005-004 (E-01)** — O EDITOR pode criar um tema/assunto novo dentro de uma disciplina
  existente, ou só escolhe entre os semeados? **Proposta (recomendada)**: permitir criação
  mínima de tema na própria tela "Novo Conteúdo" — só criar, dentro de disciplina já
  existente, sem gestão. **Default sem resposta**: segue A-005-007 como está, com
  AC-005-027 reforçado (registro em cada tema semeado). Prazo natural: confirmação da
  migração (Q-005-003 / BRIEF-005 P-05). Não bloqueia a SPEC.

## 10. Fora deste documento

Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e
`/keelson:tasks`.
