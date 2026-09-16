# SPEC-026: Contrastes, pegadinhas, flashcards e protocolos impressos

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.2
**Autor**: scribe
**Data**: 2026-09-16
**Brief**: BRIEF-026
**Jira**: KAN-121

## 1. Contexto e objetivo

### 1.1 Problema

Quatro camadas do método TAP ainda não têm representação estruturada na fábrica:
comparação entre institutos que costumam ser confundidos (contraste), o registro de
por que um ponto é um erro comum de prova (pegadinha elaborada), a fixação ativa por
pergunta/resposta (flashcard) e o cronograma impresso de revisão espaçada com marcos
fixos (protocolo). Hoje esse material, quando existe, é produzido manualmente fora do
sistema — sem reuso do pipeline de PDF já entregue (F6) e sem nenhum modelo de dados
que sustente autoria e edição estruturadas desses 4 conceitos.

### 1.2 Outcome esperado

O EDITOR (ou ADMIN), a partir de um Conteúdo bruto já cadastrado com Quebra da regra
salva, consegue registrar Contraste(s), a Pegadinha elaborada e Flashcards de
pergunta/resposta — e vê os 4 conceitos desta fatia (Contraste, Pegadinha elaborada,
Flashcards e o Protocolo impresso de revisão, com os 6 marcos fixos) incluídos no
documento gerado pela Exportação (F6), em ambas as Variantes — sem que nenhuma dessas
capacidades crie tela, rota ou fluxo consumido pelo papel STUDENT.

### 1.3 Métrica de sucesso

Pelo menos 50% dos Conteúdos brutos ativos (não removidos) com Quebra da regra salva
ganham 1 ou mais Flashcards registrados, medido 6 semanas após o lançamento desta
fatia.

**Fonte de medição**: instrumentação — consulta de contagem de Flashcards por
Conteúdo bruto ativo, cruzada com o total de Conteúdos brutos ativos com Quebra da
regra salva (mesma base de dados de F2/F4, sem evento de etapa novo dedicado a esta
métrica).

O alvo acima é estimativa sem medição prévia — vira Veredito de métrica no ciclo
seguinte, nunca meta garantida (A-026-010, §8). O Protocolo impresso não ganha métrica
própria por ser 100% por construção (sai em toda Exportação com Quebra da regra
salva, nada a medir); Contraste e Pegadinha elaborada também não têm sinal dedicado
nesta fatia — se o piloto (PIL-001) mostrar baixo uso desses 2 registros, é sinal para
revisão futura, não gap desta SPEC.

## 2. Personas e jobs-to-be-done

**EDITOR (produção/autoria)** — "Como EDITOR, quero registrar contrastes entre
institutos confundíveis, explicar por que um ponto é uma pegadinha de prova, criar
flashcards de pergunta/resposta e emitir o protocolo impresso de revisão de um
Conteúdo bruto, para que o PDF exportado reforce a evocação do concursando sem que eu
precise produzir esse material fora do sistema."

**ADMIN** — mesmas ações do EDITOR nesta fatia (papel superconjunto), mais a
capacidade de editar/remover registros de outro autor.

**Anti-persona**: esta capacidade não é para o STUDENT — nenhuma tela, rota ou fluxo
desta SPEC é consumida por ele; toda leitura e escrita de Contraste, Pegadinha
elaborada e Flashcard é EDITOR/ADMIN, mesma barreira de F1/F2.

## 3. Glossário (Ubiquitous Language)

- **Contraste**: comparação registrada pelo EDITOR entre um Conteúdo bruto titular e
  um instituto/regra confundível (texto livre), com uma explicação sucinta da
  distinção — reforça a discriminação na memória. (novo, SPEC-026)
- **Confundível**: o texto livre que descreve o instituto/regra com o qual o Conteúdo
  bruto titular costuma ser confundido, dentro de um Contraste. (novo, SPEC-026)
- **Pegadinha elaborada**: texto explicando por que um ponto de um Conteúdo bruto é um
  erro comum de prova — acrescenta a explicação à Classe do radar de prova já
  persistida (`RawContent.radarClass`, SPEC-005), não a redefine. (novo, SPEC-026)
- **Flashcard**: par pergunta/resposta (frente/verso) derivado de um Conteúdo
  bruto/Quebra da regra, autorado pelo EDITOR, incluído no documento da Exportação
  (F6). (novo, SPEC-026)
- **Protocolo impresso de revisão**: checklist textual, gerada no momento da
  Exportação, listando os 6 Marcos de revisão na ordem fixa, sem cálculo nem
  rastreamento de cumprimento pelo sistema. (novo, SPEC-026)
- **Marco de revisão**: cada um dos 6 rótulos fixos do Protocolo impresso — R0, R24
  (24h), R3 (3 dias), R7 (7 dias), R14 (14 dias), R30 (30 dias) — herdados da TAP,
  nunca calculados pelo scheduler SM-2 existente (dormente, A-005/MAP.md). (novo,
  SPEC-026)

Termos reutilizados do glossário consolidado do INDEX (sem redefinição): Conteúdo
bruto, Classe do radar de prova, Quebra da regra, Bloco da quebra, Publicação,
Variante do PDF, Rascunho (PDF), Exportação, Remoção reversível (Conteúdo bruto).

## 4. Escopo

### 4.1 In-scope

- Registro de Contraste (confundível em texto livre + explicação da distinção)
  vinculado a um Conteúdo bruto titular, com CRUD completo (criar, listar, editar,
  remover) pelo EDITOR/ADMIN.
- Registro do campo de Pegadinha elaborada vinculado a um Conteúdo bruto,
  independente da Classe do radar de prova atual desse Conteúdo bruto.
- CRUD de Flashcards (pergunta/resposta) vinculados a um Conteúdo bruto.
- Inclusão de Contraste(s), Pegadinha elaborada e Flashcards no documento gerado pela
  Exportação (F6), em ambas as Variantes (tira e resumo) — esses 3 registros mais o
  Protocolo impresso (abaixo) somam os 4 conceitos desta fatia que chegam ao
  documento exportado.
- Geração do texto do Protocolo impresso de revisão (6 Marcos fixos, ordem
  canônica) dentro do documento gerado pela Exportação, em ambas as Variantes.
- Confirmação antes de remover (ato destrutivo) e tratamento de falha na remoção de
  Contraste, Pegadinha elaborada e Flashcard.
- Emissão de evento de etapa de produção (mecanismo já existente desde F3) para a
  autoria de Contraste, Pegadinha elaborada e Flashcard desta fatia.
- Restrição de toda ação desta fatia (leitura e escrita) aos papéis EDITOR e ADMIN.

### 4.2 Out-of-scope

- Contraste entre 2 Conteúdos brutos do acervo (forma "titular + titular") — avaliada
  e descartada nesta fatia em favor de titular + texto livre (A-026-004); pareia com
  o registro de Contraste acima.
- Qualquer interação do STUDENT com Contraste, Pegadinha elaborada, Flashcard ou
  Protocolo impresso — marcar como revisado, progresso, ou mera leitura; pareia com a
  restrição de papéis acima.
- Rastreamento, cálculo ou disparo automático de datas de revisão pelo sistema
  (reuso do scheduler SM-2 existente) — pareia com a geração do Protocolo impresso.
- Geração automática (por IA) de Contraste, Pegadinha elaborada ou Flashcard a partir
  do texto bruto — pareia com os 3 registros manuais acima.
- Reordenação manual de Flashcards na lista exibida (a ordem segue a criação,
  A-026-008) — pareia com o CRUD de Flashcards.
- Carimbo de Versão aprovada / gate de QC jurídico sobre este material (F9) — o
  material entra no PDF ainda como Rascunho, sem novo gate de aprovação; pareia com a
  inclusão na Exportação.
- Trilha histórica (auditoria completa de edição/remoção) de Contraste, Pegadinha
  elaborada ou Flashcard (F8) — só a inalcançabilidade herdada do Conteúdo bruto pai
  se aplica nesta fatia; pareia com o CRUD dos 3 registros.

## 5. Requisitos funcionais (EARS)

### FEAT-026-001: Registro de contraste entre institutos confundíveis e sua inclusão na Exportação

**Jira**: KAN-122

> O EDITOR abre um Conteúdo bruto, registra um ou mais Contrastes (confundível +
> distinção), os revê, edita ou remove depois, e os vê incluídos no documento gerado
> pela Exportação — testável ponta a ponta por criar, ler, editar e remover um
> Contraste, e por exportar o Conteúdo bruto.

- **FR-026-001** [MUST] O sistema deve permitir que um usuário com papel EDITOR ou
  ADMIN registre um Contraste vinculado a um Conteúdo bruto titular, composto por um
  texto livre do Confundível e um texto de distinção sucinta.
- **FR-026-002** [MUST] Quando o EDITOR ou ADMIN aciona salvar um Contraste com os
  campos obrigatórios preenchidos, o sistema deve desabilitar o controle de salvar e
  indicar que a operação está em andamento, e, ao concluir com sucesso, persistir o
  Contraste e exibir confirmação.
- **FR-026-003** [MUST] Se a operação de salvar um Contraste falhar (validação ou
  erro do sistema), então o sistema deve reabilitar o controle de salvar, preservar
  os dados digitados e exibir mensagem de falha.
- **FR-026-004** [MUST] Se o Conteúdo bruto titular estiver inalcançável (removido)
  no momento do salvamento, então o sistema deve recusar a operação, informar o
  motivo e não criar o registro.
- **FR-026-005** [MUST] O sistema deve exibir, na tela do Conteúdo bruto (ou da sua
  Quebra da regra), a lista de Contrastes já registrados para aquele Conteúdo bruto,
  recarregada a cada visita.
- **FR-026-006** [MUST] O sistema deve permitir que o EDITOR autor de um Contraste
  (ou qualquer ADMIN) edite ou remova esse Contraste, sem excluir fisicamente o
  Conteúdo bruto titular.
- **FR-026-007** [MUST] Se um Conteúdo bruto titular for removido (soft-delete),
  então todo Contraste vinculado a ele deve ficar inalcançável junto — nunca exibido,
  nunca editável — preservado apenas para expurgo futuro (mesma régua de F2/F4).
- **FR-026-026** [MUST] Quando o EDITOR ou ADMIN aciona a Exportação de um Conteúdo
  bruto que tenha 1 ou mais Contrastes registrados, o sistema deve incluir todos eles
  (Confundível + distinção) no documento exportado, em ambas as Variantes (tira e
  resumo).
- **FR-026-028** [MUST] Quando a Exportação é acionada para um Conteúdo bruto sem
  Contraste registrado (ou sem Pegadinha elaborada), o sistema deve gerar o documento
  normalmente, omitindo a seção correspondente — mesma régua do FR-026-023 para
  Flashcards.

### FEAT-026-002: Registro da pegadinha elaborada e sua inclusão na Exportação

**Jira**: KAN-123

> O EDITOR abre um Conteúdo bruto e registra, edita ou remove o texto que explica por
> que aquele ponto é um erro comum de prova, e o vê incluído no documento gerado pela
> Exportação — testável ponta a ponta por criar, ler, editar e apagar esse texto, e
> por exportar o Conteúdo bruto.

- **FR-026-008** [MUST] O sistema deve permitir que um usuário com papel EDITOR ou
  ADMIN registre, para um Conteúdo bruto, um texto de Pegadinha elaborada explicando
  por que aquele ponto é um erro comum de prova, independente da Classe do radar de
  prova atual do Conteúdo bruto.
- **FR-026-009** [MUST] Quando o EDITOR ou ADMIN aciona salvar a Pegadinha elaborada,
  o sistema deve desabilitar o controle de salvar e indicar que a operação está em
  andamento, e, ao concluir com sucesso, persistir o texto e exibir confirmação.
- **FR-026-010** [MUST] Se a operação de salvar a Pegadinha elaborada falhar, então o
  sistema deve reabilitar o controle de salvar, preservar o texto digitado e exibir
  mensagem de falha.
- **FR-026-011** [MUST] O sistema deve exibir a Pegadinha elaborada já registrada na
  tela do Conteúdo bruto (ou da Quebra da regra), recarregada a cada visita.
- **FR-026-012** [MUST] O sistema deve permitir que o EDITOR autor (ou qualquer
  ADMIN) edite ou apague o texto da Pegadinha elaborada de um Conteúdo bruto a
  qualquer momento.
- **FR-026-013** [MUST] Se um Conteúdo bruto for removido (soft-delete), então sua
  Pegadinha elaborada deve ficar inalcançável junto (mesma régua de F2), sem exclusão
  física do texto.
- **FR-026-027** [MUST] Quando o EDITOR ou ADMIN aciona a Exportação de um Conteúdo
  bruto que tenha Pegadinha elaborada registrada, o sistema deve incluir o texto no
  documento exportado, em ambas as Variantes.

### FEAT-026-003: Autoria de flashcards e inclusão na exportação

**Jira**: KAN-124

> O EDITOR abre um Conteúdo bruto, registra um ou mais Flashcards (pergunta/resposta)
> e os vê incluídos no PDF gerado pela Exportação — testável ponta a ponta por criar
> um Flashcard e exportar o Conteúdo bruto.

- **FR-026-014** [MUST] O sistema deve permitir que um usuário com papel EDITOR ou
  ADMIN registre um Flashcard (par pergunta/resposta) vinculado a um Conteúdo bruto,
  sem limite superior declarado nesta fatia.
- **FR-026-015** [MUST] Quando o EDITOR ou ADMIN aciona salvar um Flashcard com
  pergunta e resposta preenchidas, o sistema deve desabilitar o controle de salvar e
  indicar que a operação está em andamento, e, ao concluir com sucesso, persistir o
  Flashcard, adicioná-lo à lista exibida e exibir confirmação.
- **FR-026-016** [MUST] Se a operação de salvar um Flashcard falhar, então o sistema
  deve reabilitar o controle de salvar, preservar os dados digitados e exibir
  mensagem de falha.
- **FR-026-017** [MUST] O sistema deve exibir, na tela do Conteúdo bruto, a lista de
  Flashcards já registrados para aquele Conteúdo bruto, na ordem de criação,
  recarregada a cada visita.
- **FR-026-018** [MUST] O sistema deve permitir que o EDITOR autor de um Flashcard
  (ou qualquer ADMIN) edite ou remova esse Flashcard.
- **FR-026-019** [MUST] Se um Conteúdo bruto for removido (soft-delete), então todo
  Flashcard vinculado a ele deve ficar inalcançável junto, sem exclusão física (mesma
  régua de F2/F4).
- **FR-026-020** [MUST] Quando o EDITOR ou ADMIN aciona a Exportação (Publicação, F6)
  de um Conteúdo bruto que tenha 1 ou mais Flashcards registrados, o sistema deve
  incluir todos eles, na ordem de criação, no documento exportado, em ambas as
  Variantes (tira e resumo).
- **FR-026-023** [MUST] Quando o EDITOR ou ADMIN aciona a Exportação de um Conteúdo
  bruto sem nenhum Flashcard registrado, o sistema deve gerar o documento
  normalmente, omitindo a seção de Flashcards, em ambas as Variantes — nunca recusar
  a Exportação por ausência de Flashcards (o Protocolo impresso, por não depender de
  material autorado, sempre sai).

### FEAT-026-004: Protocolo impresso de revisão na exportação

**Jira**: KAN-125

> O EDITOR aciona a Exportação de um Conteúdo bruto e o documento gerado inclui o
> Protocolo impresso de revisão com os 6 Marcos fixos — testável ponta a ponta pela
> geração do PDF, sem persistência própria (A-026-006).

- **FR-026-021** [MUST] Quando o EDITOR ou ADMIN aciona a Exportação (Publicação, F6)
  de um Conteúdo bruto com Quebra da regra salva, o sistema deve gerar, dentro do
  documento exportado — em ambas as Variantes (tira e resumo) — o Protocolo impresso
  de revisão contendo os 6 Marcos de revisão na ordem fixa R0, R24, R3, R7, R14, R30,
  cada um como rótulo textual com espaço para preenchimento manual de data (ex.:
  "☐ Revisão R0 — data: ___").
- **FR-026-022** [MUST] Se a geração do Protocolo impresso for acionada, então o
  sistema deve produzir apenas o texto estático dos 6 Marcos — nunca calcular a
  próxima data de revisão, nunca registrar ou rastrear se um Marco foi cumprido pelo
  estudante.

### FEAT-026-005: Confirmação e tratamento de falha na remoção de registros desta fatia

> O EDITOR aciona remover um Contraste, uma Pegadinha elaborada ou um Flashcard, o
> sistema pede confirmação antes de executar (ato destrutivo) e trata falha sem
> perder o registro — testável ponta a ponta pelo fluxo de confirmar, remover com
> sucesso e pela simulação de uma falha de remoção.

- **FR-026-024** [MUST] Quando o EDITOR ou ADMIN aciona remover um Contraste, uma
  Pegadinha elaborada ou um Flashcard, o sistema deve pedir confirmação antes de
  executar a remoção (ato destrutivo), indicar que a operação está em andamento após
  confirmada, e ao concluir com sucesso removê-lo da lista exibida e exibir
  confirmação — mesmo padrão de confirmação com foco gerenciado já entregue em F4
  (Tira mnemônica).
- **FR-026-025** [MUST] Se a operação de remover falhar, então o sistema deve manter
  o registro na lista exibida, reabilitar a ação e exibir mensagem de falha.

### FEAT-026-006: Instrumentação de etapa de produção para Contraste, Pegadinha elaborada e Flashcard

> A autoria de um Contraste, de uma Pegadinha elaborada ou de um Flashcard emite um
> evento de etapa de produção (mecanismo já existente desde F3) — testável ponta a
> ponta pela verificação do evento registrado após a 1ª mutação humana de cada
> registro.

- **FR-026-029** [MUST] O sistema deve registrar um evento de etapa de produção
  (mecanismo já existente desde F3) para a autoria de Contraste, Pegadinha elaborada
  e Flashcard desta fatia, como novo valor aditivo no mecanismo de instrumentação,
  emitido na mesma operação atômica da 1ª mutação humana de cada registro.

## 6. Requisitos não-funcionais

- **NFR-026-001** [MUST] O sistema deve restringir toda ação de leitura e escrita de
  Contraste, Pegadinha elaborada e Flashcard aos papéis EDITOR e ADMIN — nenhuma
  rota, tela ou fluxo desta fatia é alcançável pelo papel STUDENT.
- **NFR-026-002** [MUST] O sistema deve rejeitar a tentativa de salvar Contraste,
  Pegadinha elaborada ou Flashcard com campo obrigatório vazio (Confundível ou
  distinção; texto da pegadinha; pergunta ou resposta do Flashcard), informando o
  motivo da recusa antes de qualquer persistência.
- **NFR-026-003** [SHOULD] O sistema deve manter a geração do Protocolo impresso e a
  inclusão de Flashcards dentro do teto de duração já existente da Exportação (F6),
  sem introduzir I/O de rede adicional.
- **NFR-026-004** [MUST] O sistema deve preservar Contraste, Pegadinha elaborada e
  Flashcard associados a um Conteúdo bruto removido (soft-delete) sem exclusão
  física, para expurgo futuro (mesma régua de F2).
- **NFR-026-005** [MUST] A emissão do evento de etapa de produção para Contraste,
  Pegadinha elaborada e Flashcard (FR-026-029) deve ser atômica em relação à mutação
  de negócio que a origina (a 1ª mutação humana de cada registro): se o registro do
  evento falhar, a mutação inteira deve ser revertida (fail-secure) — nunca persistir
  sem o evento, nunca evento sem persistência, nunca um sucesso parcial.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-026-001** (cobre FR-026-001, FR-026-002, FR-026-005)
  Dado um Conteúdo bruto alcançável e um EDITOR autenticado, quando o EDITOR preenche
  o Confundível e a distinção e aciona salvar, então o sistema desabilita o controle
  de salvar durante a operação, persiste o Contraste com sucesso e o exibe na lista
  de Contrastes do Conteúdo bruto na próxima visita à tela.

- **AC-026-002** (cobre FR-026-003)
  Dado um EDITOR preenchendo um Contraste, quando o salvamento falha por erro do
  sistema, então o sistema reabilita o controle de salvar, mantém os campos
  preenchidos e exibe mensagem de falha ao EDITOR.

- **AC-026-003** (cobre FR-026-004, FR-026-007)
  Dado um Conteúdo bruto titular já removido (soft-delete), quando um EDITOR tenta
  salvar um Contraste vinculado a ele, então o sistema recusa a operação, informa o
  motivo e não cria o registro.

- **AC-026-004** (cobre FR-026-006)
  Dado um Contraste já registrado por um EDITOR, quando o autor (ou um ADMIN) aciona
  remover, então o sistema remove o Contraste da lista exibida sem afetar o Conteúdo
  bruto titular.

- **AC-026-005** (cobre FR-026-008, FR-026-009, FR-026-011)
  Dado um Conteúdo bruto de qualquer Classe do radar de prova, quando o EDITOR
  preenche e salva o texto de Pegadinha elaborada, então o sistema indica a operação
  em andamento, persiste o texto com sucesso e o exibe ao recarregar a tela do
  Conteúdo bruto.

- **AC-026-006** (cobre FR-026-010)
  Dado um EDITOR editando a Pegadinha elaborada, quando o salvamento falha, então o
  sistema reabilita o controle, preserva o texto digitado e exibe mensagem de falha.

- **AC-026-007** (cobre FR-026-012, FR-026-013)
  Dado um Conteúdo bruto com Pegadinha elaborada registrada, quando esse Conteúdo
  bruto é removido (soft-delete), então a Pegadinha elaborada deixa de ser exibida ou
  editável, sem exclusão física do texto.

- **AC-026-008** (cobre FR-026-014, FR-026-015, FR-026-017)
  Dado um Conteúdo bruto alcançável, quando o EDITOR preenche pergunta e resposta de
  um Flashcard e aciona salvar, então o sistema indica a operação em andamento,
  persiste o Flashcard com sucesso e o exibe na lista de Flashcards do Conteúdo
  bruto, na ordem de criação, ao recarregar a tela.

- **AC-026-009** (cobre FR-026-016)
  Dado um EDITOR salvando um Flashcard, quando a operação falha, então o sistema
  reabilita o controle de salvar, preserva os dados digitados e exibe mensagem de
  falha.

- **AC-026-010** (cobre FR-026-018)
  Dado um Flashcard já registrado por um EDITOR, quando o autor (ou um ADMIN) aciona
  remover, então o sistema remove o Flashcard da lista exibida sem afetar o Conteúdo
  bruto.

- **AC-026-011** (cobre FR-026-019)
  Dado um Flashcard já registrado, quando o Conteúdo bruto ao qual ele pertence é
  removido (soft-delete), então o Flashcard fica inalcançável junto, sem exclusão
  física.

- **AC-026-012** (cobre FR-026-020)
  Dado um Conteúdo bruto com 2 Flashcards registrados e Quebra da regra salva, quando
  o EDITOR aciona a Exportação em qualquer Variante, então o documento exportado
  contém os 2 Flashcards, na ordem de criação.

- **AC-026-013** (cobre FR-026-021)
  Dado um Conteúdo bruto com Quebra da regra salva, quando o EDITOR aciona a
  Exportação, então o documento exportado contém o Protocolo impresso de revisão com
  os 6 Marcos R0, R24, R3, R7, R14, R30 na ordem fixa, cada um como rótulo textual
  com espaço para data manual, em ambas as Variantes.

- **AC-026-014** (cobre FR-026-022)
  Dado o Protocolo impresso gerado num documento exportado, quando comparado ao
  scheduler SM-2 existente, então o sistema não apresenta nenhuma data calculada nem
  estado de conclusão — apenas os 6 rótulos textuais fixos.

- **AC-026-015** (cobre NFR-026-001)
  Dado um usuário autenticado com papel STUDENT, quando ele tenta acessar qualquer
  rota ou tela de Contraste, Pegadinha elaborada ou Flashcard, então o sistema nega o
  acesso pela mesma barreira deny-by-default de EDITOR/ADMIN.

- **AC-026-016** (cobre NFR-026-002)
  Dado um EDITOR tentando salvar um Contraste, Pegadinha elaborada ou Flashcard com
  campo obrigatório vazio, quando ele aciona salvar, então o sistema recusa a
  operação antes de persistir e informa o campo pendente.

- **AC-026-017** (cobre FR-026-023)
  Dado um Conteúdo bruto com Quebra da regra salva e nenhum Flashcard registrado,
  quando o EDITOR aciona a Exportação em qualquer Variante, então o documento é
  gerado sem seção de Flashcards e sem erro, contendo o Protocolo impresso
  normalmente.

- **AC-026-018** (cobre FR-026-024)
  Dado um EDITOR ou ADMIN removendo um Contraste, uma Pegadinha elaborada ou um
  Flashcard, quando aciona remover, então o sistema pede confirmação antes de
  executar; confirmada a remoção, o sistema indica que a operação está em andamento
  e, ao concluir com sucesso, remove o registro da lista exibida e exibe
  confirmação.

- **AC-026-019** (cobre FR-026-025)
  Dado um EDITOR removendo um Contraste/Pegadinha/Flashcard, quando a remoção falha,
  então o sistema mantém o item na lista, reabilita a ação e exibe mensagem de
  falha.

- **AC-026-020** (cobre FR-026-026)
  Dado um Conteúdo bruto com 2 Contrastes registrados e Quebra da regra salva, quando
  o EDITOR aciona a Exportação em qualquer Variante, então o documento exportado
  contém os 2 Contrastes (Confundível + distinção).

- **AC-026-021** (cobre FR-026-027)
  Dado um Conteúdo bruto com Pegadinha elaborada registrada e Quebra da regra salva,
  quando o EDITOR aciona a Exportação em qualquer Variante, então o documento
  exportado contém o texto da Pegadinha elaborada.

- **AC-026-022** (cobre FR-026-028)
  Dado um Conteúdo bruto com Quebra da regra salva e sem Contraste registrado (ou
  sem Pegadinha elaborada), quando o EDITOR aciona a Exportação em qualquer
  Variante, então o documento é gerado sem a seção correspondente e sem erro.

- **AC-026-023** (cobre FR-026-029, NFR-026-005)
  Dado que o registro do evento de etapa de produção falha por qualquer motivo,
  quando a 1ª mutação humana de um Contraste, de uma Pegadinha elaborada ou de um
  Flashcard está em andamento, então a mutação inteira é revertida — nenhum estado
  meio-salvo — e o sistema informa um erro genérico ao usuário.

## 8. Premissas e decisões prévias

- **A-026-001** [assumido] [evidência: crença] Anti-persona vale à risca — Flashcard
  e Protocolo impresso são artefatos de autoria/exportação do EDITOR, nunca telas de
  estudo do STUDENT (herdado do BRIEF-026, risco já nomeado na decomposição do épico
  para F7). NÃO é aposta do time: é decisão já confirmada pelo Diretor (BRIEF-026
  §Premissas decididas; A-026-002 também nomeada como risco da fatia por `pm` em
  BRIEF-2026-08-27-mnemora-studio-epic.md).
- **A-026-002** [assumido] [evidência: crença] Os 6 Marcos fixos do Protocolo
  impresso não reusam o scheduler SM-2
  (`mnemonicos-backend/src/modules/review/scheduler.ts`) — texto estático, sem
  cálculo de datas nem estado de conclusão (herdado do BRIEF-026, ancorado em
  MAP.md § Revisão espaçada). NÃO é aposta do time: é decisão já confirmada pelo
  Diretor (BRIEF-026 §Premissas decididas; A-026-002 também nomeada como risco da
  fatia por `pm` em BRIEF-2026-08-27-mnemora-studio-epic.md).
- **A-026-003** [assumido] [evidência: medido] O Radar de prova
  (`RawContent.radarClass`, 5 classes incluindo `PEGADINHA`) já persiste a
  classificação e permanece fonte única — esta SPEC não redefine nem duplica a
  taxonomia (herdado do BRIEF-026, ancorado em SPEC-005 e MAP.md § Acervo). NÃO é
  aposta do time: é decisão já confirmada pelo Diretor (BRIEF-026 §Premissas
  decididas; A-026-002 também nomeada como risco da fatia por `pm` em
  BRIEF-2026-08-27-mnemora-studio-epic.md).
- **A-026-004** [assumido] [evidência: crença] Contraste vincula-se a exatamente 1
  Conteúdo bruto (titular) + 1 texto livre do Confundível — não a 2 Conteúdos brutos
  do acervo. Forma mais simples e não bloqueia o fluxo (o titular pode não ter par
  estruturado ainda cadastrado). Reabrir se: antes de F8 (versionamento editorial),
  ou ao 1º pedido real de Contraste entre 2 Conteúdos brutos estruturados do acervo —
  o que vier antes.
- **A-026-005** [assumido] [evidência: crença] A Pegadinha elaborada pode ser
  registrada em qualquer Conteúdo bruto, independente da Classe do radar de prova
  atual — evita estado inconsistente se o EDITOR reclassificar o Conteúdo bruto
  depois; não redefine quando a classe é `PEGADINHA`.
- **A-026-006** [assumido] [evidência: crença] O Protocolo impresso de revisão não é
  persistido como registro próprio — é texto gerado no momento da Exportação (F6), a
  partir de uma lista fixa dos 6 Marcos. Simplifica o modelo de dados e elimina o
  risco de o texto desalinhar do padrão da TAP. Reabrir se surgir necessidade de
  customizar os 6 Marcos por Conteúdo bruto.
- **A-026-007** [assumido] [evidência: crença] O Protocolo impresso e os Flashcards
  de um Conteúdo bruto são incluídos em ambas as Variantes do documento (tira e
  resumo) da Exportação, sempre que existirem — sem alternativa de opt-out nesta
  fatia. Não é preferência de diagramação: a Variante "resumo" é o braço de controle
  do A/B de retenção (A-012 do épico, BRIEF-001, herdada por
  BRIEF-2026-08-27-mnemora-studio-epic.md, item 3 das "Perguntas ao Diretor —
  respondidas") e precisa de recuperação ativa/revisão IGUAIS às da Variante "tira" —
  restringir o Protocolo impresso ou os Flashcards a uma só Variante quebraria esse
  experimento, introduzindo uma variável de confusão entre os braços. Reabrir esta
  decisão exige decisão consciente do Diretor de abrir mão do A/B, nunca preferência
  de diagramação (Q-026-001 fechada nesta versão — ver §9).
- **A-026-008** [assumido] [evidência: crença] A ordem de exibição dos Flashcards no
  documento exportado segue a ordem de criação — mais simples, sem UI de
  reordenação nesta fatia (mesma régua de simplicidade aplicada a Tira mnemônica
  antes da introdução de reordenação em F4).
- **A-026-009** [assumido] [evidência: crença] Leitura de Contraste, Pegadinha
  elaborada e Flashcard é comum a EDITOR/ADMIN (qualquer um vê, independente de quem
  criou); escrita (criar/editar/remover) é restrita ao autor do registro ou a
  qualquer ADMIN — herda a mesma regra de F5 (A-022-011, SPEC-022). Isso já é o que
  FR-026-006/012/018 declaram; esta premissa só torna explícita a herança.
- **A-026-010** [assumido] [evidência: crença] O alvo de 50% em 6 semanas (§1.3) é
  estimativa sem medição prévia (a capacidade ainda não existe) — vira Veredito de
  métrica no ciclo seguinte (decisão 4.99), não meta garantida.

## 9. Riscos e questões abertas

- **RISK-026-001** Se um Conteúdo bruto titular de um Contraste for soft-deleted, o
  Contraste (e o Confundível associado) fica inalcançável junto — herdado do padrão
  de F2/F4; o EDITOR perde acesso ao Contraste mesmo que o Confundível pudesse ainda
  fazer sentido de forma independente. Aceito nesta fatia; revisitar se o piloto
  reportar necessidade de reatribuir um Contraste a outro titular. Reverter A-026-004
  para vínculo estruturado (Contraste entre 2 Conteúdos brutos) exige re-vinculação
  MANUAL de todo Contraste já escrito com o Confundível em texto livre — mesma classe
  de custo de RISK-005-001 (reclassificação manual do acervo), não apenas migração de
  schema.
- ~~RISK-026-002~~ — RESOLVIDO nesta versão (pacote de correção, E-01): a inclusão de
  Contraste e Pegadinha elaborada no documento exportado deixou de ser hipótese —
  agora é comportamento confirmado (FR-026-026, FR-026-027). A mitigação antes
  cogitada (rótulo condicional no documento quando a Classe do radar de prova atual
  não é `PEGADINHA`) vira nota para o PLAN decidir como detalhe de diagramação, não
  risco aberto desta SPEC.
- **RISK-026-003** Sem persistência do Protocolo impresso (A-026-006), qualquer
  necessidade futura de customizar os 6 Marcos por Conteúdo bruto (ex.: pular um
  marco, adicionar um marco extra) exige retrofit de modelo de dados — aceito nesta
  fatia, a TAP não pede customização hoje.
- **RISK-026-004** Concorrência de 2 EDITORES editando a Pegadinha elaborada do mesmo
  Conteúdo bruto ao mesmo tempo (campo único) resolve por last-write-wins — aceito
  nesta fatia (operação de 1 pessoa, herda RISK-011-005 do mesmo slug); revisitar se
  o piloto rodar com 2+ editores simultâneos.
- **RISK-026-005** Flashcards sem limite superior (FR-026-014) somados a Contraste,
  Pegadinha elaborada e Protocolo impresso agora todos incluídos no documento
  exportado (FR-026-026/FR-026-027/FR-026-021) amplificam RISK-025-007 (herdado de
  F6/PLAN-025: Tira grande com imagens pode exceder o limite de corpo de resposta de
  function serverless da Vercel) — sem teto de volume nesta fatia. Decisão de
  introduzir teto fica com quem fechar RISK-025-007, antes do deploy em produção.
- ~~Q-026-001~~ — RESOLVIDA nesta versão (pacote de correção): o Protocolo impresso e
  os Flashcards entram sempre nas duas Variantes (tira e resumo) — não só faz sentido
  em ambas como é NECESSÁRIO manter (A-026-007): a Variante "resumo" é o braço de
  controle do A/B de retenção e exige recuperação ativa/revisão iguais às da
  Variante "tira". Reabrir exige decisão consciente do Diretor de abrir mão do A/B,
  nunca preferência de diagramação.

## 10. Fora deste documento

Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e
`/keelson:tasks`.
