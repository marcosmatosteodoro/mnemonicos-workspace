# SPEC-028: Versionamento editorial e fechamento legislativo

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.2
**Autor**: scribe
**Data**: 2026-09-26
**Brief**: BRIEF-028
**Jira**: KAN-136

## 1. Contexto e objetivo

### 1.1 Problema

O Conteúdo bruto (F2) só carrega o "Carimbo de última alteração" — um par quem/quando
de estado atual, sem trilha histórica (SPEC-005 já previu esse gap: "trilha é F8").
Não existe nenhuma noção de versão nem de data de fechamento de legislação — o campo
mais próximo é `sourceCitation`/`sourceUrl` como texto livre, que não captura **até
quando** aquela regra foi verificada. O PDF que a fábrica emite (F6) estampa o rótulo
"Rascunho" em toda página, mas nenhuma versão nem data de verificação legislativa —
exatamente o que a TAP (§4.4) exige como controle de qualidade jurídica. Sem esse
registro, o gate de aprovação de F9 não teria o que aprovar, e uma mudança na
legislação depois da produção do material não deixa nenhum rastro de qual revisão
jurídica estava vigente quando o PDF foi emitido.

### 1.2 Outcome esperado

Um EDITOR (ou ADMIN) que revisou juridicamente um Conteúdo bruto consegue **fechar uma
Versão** dele de forma explícita, registrando a data até a qual verificou a
legislação; esse registro é permanente e não pode ser alterado depois. O Conteúdo
bruto passa a expor, para leitura, o histórico completo de Versões fechadas. Todo PDF
exportado (reuso do pipeline de F6) estampa, em toda página, a Versão vigente e a data
de fechamento legislativo dela — carimbo que atesta a verificação legislativa do
**conteúdo normativo** (texto normativo e fonte normativa), não de todo o material
impresso no PDF — ou uma marca explícita de ausência de versão, quando nenhuma foi
fechada ainda. O rótulo "Rascunho" de F6 continua existindo sem mudança.
Este outcome não implementa o gate de aprovação em si (F9): apenas cria o mecanismo de
versionamento e o dado (Versão + data) que F9 vai consumir para liberar ou não a
Exportação.

### 1.3 Métrica de sucesso

Em até 4 semanas após o lançamento desta fatia, pelo menos 80% das Exportações (PDF)
realizadas a partir de Conteúdo bruto com Quebra da regra salva carregam uma Versão
editorial fechada real (não a marca de ausência de versão) — sinal de adoção do
fechamento pelo time editorial, pré-requisito de dado para o gate de aprovação de F9.
O alvo (80%/4 semanas) é estimativa sem base histórica de adoção editorial no slug —
vira Veredito de métrica no ciclo seguinte, nunca meta garantida (A-028-009). Uma
Exportação que carrega a marca de "alterado após o fechamento" (FR-028-011) NÃO conta
como Versão fechada real para o numerador dos 80% — Versão fechada com sinal de
desatualização não é o mesmo que adoção limpa do fechamento (A-028-012).

**Fonte de medição**: instrumentação — consulta cruzando o evento de Publicação (F6,
`PublicationEvent`) com a existência de ao menos 1 Versão editorial fechada no
Conteúdo bruto na data da exportação.

## 2. Personas e jobs-to-be-done

**EDITOR (produção/autoria)** — "Como EDITOR, quero fechar uma Versão do Conteúdo
bruto que venho de revisar, registrando a data até a qual verifiquei a legislação,
para que essa data fique registrada de forma confiável, sem poder ser alterada
depois, e apareça no PDF que a fábrica emite."

**ADMIN** — "Como ADMIN, quero poder fechar uma Versão de qualquer Conteúdo bruto,
mesmo quando não sou o autor original, para que a ausência ou indisponibilidade do
autor não trave o fechamento de uma Versão que precisa existir."

**Anti-persona**: esta capacidade não é para o STUDENT — nenhuma tela, rota ou fluxo
desta SPEC é consumida por ele; ele é apenas o leitor final do PDF que carrega o
carimbo desta fatia, sem interagir com nenhum mecanismo aqui descrito.

## 3. Glossário (Ubiquitous Language)

- **Versão editorial (do Conteúdo bruto)**: registro imutável, criado pelo ato de
  fechamento, contendo número sequencial, Data de fechamento legislativo, autor do
  fechamento e timestamp técnico do momento do registro — a trilha histórica que o
  "Carimbo de última alteração" (SPEC-005) já havia anunciado como pendente para F8.
  (novo, SPEC-028)
- **Fechar uma Versão (ato)**: ação explícita do EDITOR ou ADMIN autor sobre um
  Conteúdo bruto, disparando o registro de uma nova Versão editorial — nunca
  disparada automaticamente por uma edição do Conteúdo bruto ou da Quebra da regra.
  (novo, SPEC-028)
- **Versão vigente**: a Versão editorial mais recente fechada de um Conteúdo bruto —
  a que aparece estampada no PDF exportado dele. (novo, SPEC-028)

Termos reutilizados do glossário consolidado do INDEX (sem redefinição): **Fechamento
legislativo** (a data até a qual a legislação foi verificada para aquela Versão —
BRIEF-001; aqui é o dado central de cada Versão editorial); **Versão aprovada** (o
*gate* de aprovação em si é F9, fora desta SPEC — esta SPEC só cria a entidade
"Versão editorial" que F9 vai avaliar); **Carimbo de última alteração** (SPEC-005 — a
trilha histórica que ele previa como pendente é o que esta SPEC entrega); **Rascunho
(PDF)** (SPEC-024 — segue existindo sem alteração, coexistindo com o carimbo desta
fatia na mesma página); **Conteúdo bruto**, **Quebra da regra**, **Remoção reversível
(Conteúdo bruto)** e **Exportação** (todos de SPEC-005/SPEC-024).

## 4. Escopo

### 4.1 In-scope

- Ato explícito de fechar uma Versão editorial de um Conteúdo bruto, restrito ao
  autor do Conteúdo bruto ou a um ADMIN.
- Registro imutável, por Versão fechada, dos quatro dados: número sequencial (por
  Conteúdo bruto), Data de fechamento legislativo (declarada pelo ator, não o
  timestamp técnico), identificador do autor do fechamento e timestamp técnico do
  fechamento.
- Recusa de fechamento quando o Conteúdo bruto não tem Quebra da regra salva (o
  objeto versionado é o par) ou está inalcançável (removido de forma reversível).
- Exposição, para leitura, do histórico completo de Versões editoriais fechadas de um
  Conteúdo bruto, em ordem, com os quatro dados de cada uma.
- Carimbo, em toda página do PDF exportado, da Versão vigente e da Data de fechamento
  legislativo dela — ou marca textual explícita de ausência de versão, quando nenhuma
  Versão foi fechada.
- Coexistência do carimbo desta fatia com o rótulo "Rascunho" (F6) já existente, sem
  alterá-lo.
- Registro do fechamento de Versão como evento de etapa de produção (mecanismo
  existente desde F3), sem tela nova de consumo.

### 4.2 Out-of-scope

- Gate de aprovação/QC jurídico e o que isso implica sobre liberar ou bloquear a
  Exportação (F9) — pareia com o ato de fechar Versão acima: fechar uma Versão não
  aprova nada, só a registra.
- Qualquer cálculo ou alerta de vencimento/expiração de legislação (a Data de
  fechamento legislativo é só a data declarada de verificação, sem prazo de validade
  calculado) — pareia com o registro dos quatro dados imutáveis acima.
- Edição ou remoção de uma Versão editorial já fechada, por qualquer papel incluindo
  ADMIN — é o que torna o histórico append-only real; pareia com a exposição do
  histórico para leitura acima.
- Reprodução fiel do texto (Conteúdo bruto/Quebra da regra) de uma Versão que não
  seja a mais recente fechada — decisão entre snapshot imutável e referência mutável
  fica para o PLAN (A-028-004); pareia com o registro imutável dos quatro dados
  acima (que não inclui o texto em si).
- Versionamento de Contraste, Pegadinha elaborada ou Flashcard (F7, material de
  reforço) — pareia com "o objeto versionado é o par Conteúdo bruto + Quebra da
  regra".
- Versionamento de Tira mnemônica ou Associação visual (F4/F5, material derivado) —
  mesmo pareamento acima.
- Qualquer tela, rota ou fluxo consumido pelo papel STUDENT — pareia com a restrição
  de papéis do ato de fechamento.
- Painel estratégico e métricas de tempo por página (F10); fila e calendário
  editorial (F11) — nenhuma capacidade desta fatia os alimenta.
- Expurgo ou migração do modelo `Mnemonic` legado dormente (RISK-011-001 /
  RISK-005-004) — segue em aberto; não é revisitado por esta fatia apesar de ter
  sido apontado como um possível gatilho de revisão quando F8 fosse planejada.
- Expurgo físico e restauração (rota ou UI) de Conteúdo bruto removido de forma
  reversível — não entram nesta fatia; ficam para uma fatia de administração ou
  limpeza de schema dedicada, como ato do Diretor (encerra o `Reabrir se: F8...` de
  DEC-006-001/DEC-006-008 de PLAN-006 e RISK-005-004/RISK-011-001 do INDEX, sem
  resolvê-los, só declarando o destino).

## 5. Requisitos funcionais (EARS)

### FEAT-028-001: Fechamento de Versão editorial e histórico do Conteúdo bruto

**Jira**: KAN-137

> O EDITOR (autor) ou ADMIN abre um Conteúdo bruto já revisado, aciona o fechamento
> de uma nova Versão informando a Data de fechamento legislativo, e depois consulta o
> histórico de Versões fechadas daquele Conteúdo bruto — testável ponta a ponta por
> fechar, tentar fechar sem permissão/sem pré-requisito, e ler o histórico.

- **FR-028-001** [MUST] Quando um EDITOR ou ADMIN aciona o fechamento de uma nova
  Versão de um Conteúdo bruto, o sistema deve registrar uma Versão editorial contendo
  o próximo número sequencial daquele Conteúdo bruto, a Data de fechamento
  legislativo informada pelo ator, o identificador do autor do fechamento e o
  timestamp técnico do momento do registro.
- **FR-028-002** [MUST] Se o ator que aciona o fechamento não for o autor do Conteúdo
  bruto nem tiver o papel ADMIN, então o sistema deve recusar o fechamento e não deve
  criar nenhuma Versão editorial.
- **FR-028-003** [MUST] Se o Conteúdo bruto alvo estiver inalcançável (removido de
  forma reversível) ou não tiver Quebra da regra salva, então o sistema deve recusar
  o fechamento de Versão e informar o motivo da recusa.
- **FR-028-004** [MUST] O sistema deve tratar cada Versão editorial fechada como
  append-only: nenhum dos quatro dados registrados (número, Data de fechamento
  legislativo, autor do fechamento, timestamp técnico) pode ser alterado ou removido
  depois do fechamento, por nenhum papel, inclusive ADMIN.
- **FR-028-005** [MUST] O sistema deve expor, para leitura, a lista de Versões
  editoriais já fechadas de um Conteúdo bruto, em ordem do número mais antigo ao mais
  recente, com os quatro dados imutáveis de cada uma.
- **FR-028-006** [MUST] Quando o EDITOR ou ADMIN aciona o fechamento de Versão pela
  interface, o sistema deve indicar visivelmente que a ação está em andamento
  (controle desabilitado ou indicador equivalente) até a resposta, e ao concluir deve
  mostrar sucesso (a nova Versão passa a aparecer no histórico) ou falha (mensagem do
  motivo da recusa) de forma observável.
- **FR-028-007** [MUST] O sistema deve registrar o fechamento de uma Versão editorial
  como evento de etapa de produção (mesmo mecanismo append-only introduzido em F3),
  sem exigir nenhuma tela nova de consumo nesta fatia.

### FEAT-028-002: Carimbo de Versão e Data de fechamento legislativo no PDF exportado

**Jira**: KAN-138

> O EDITOR ou ADMIN exporta o PDF de um Conteúdo bruto (com ou sem Versão fechada) e
> confere, em toda página do documento, a Versão vigente e a data (ou a marca
> explícita de ausência de versão) ao lado do rótulo "Rascunho" já existente —
> testável ponta a ponta pela geração real do PDF nos dois cenários.

**Verificação (gate 9)**: 2026-09-26 — APROVADO (comportamento funcional). Exercitado com execução real, sem UI (backend puro, `gates.screenVerify` não se aplica a esta FEAT): branch `feat/producao-material-mnemora-studio`, HEAD `d2d5a66` — `git status` limpo antes e depois do exercício, sem mudança concorrente; servidor real (`tsx watch src/server.ts`) contra Postgres de dev (`mnemonicos-db`, container saudável) — health check confirmou o processo de pé. Fluxo ponta a ponta pela superfície HTTP real (login do EDITOR de dev via `POST /auth/login`, sem mock): (1) criado um `RawContent` novo + Quebra da regra salva (`POST /contents`, `PUT /contents/:id/breakdown`); (2) exportado o PDF (`POST /contents/:id/publication`, Variantes RESUMO e TIRA) **sem** nenhuma Versão fechada → todas as páginas (2/2 e 4/4) trazem "Sem versão fechada." + "RASCUNHO" coexistindo (AC-028-010/FR-028-009, AC-028-011/FR-028-010); (3) fechada a Versão 1 (`POST /contents/:id/versions`, `legislativeClosureDate: 2026-09-01`) e reexportado (ambas Variantes, sem alterar o conteúdo) → todas as páginas trazem "Versão 1 — verificado até 01/09/2026" + "RASCUNHO", sem a marca de alteração (AC-028-009/FR-028-008, caso simétrico de AC-028-013); (4) editada a Quebra da regra (`concept`) **depois** do fechamento e reexportado → todas as páginas passam a trazer "Versão 1 — verificado até 01/09/2026 — alterado após o fechamento da Versão 1" (AC-028-013/FR-028-011, fail-secure A-028-012); (5) fechada uma 2ª Versão (number 2, `legislativeClosureDate: 2026-09-15`) sem editar depois → o carimbo atualiza para "Versão 2 — verificado até 15/09/2026" sem marca de alteração, confirmando que o número/data não são fixos e a marca reseta ao fechar de novo. Extração de texto por página com o mesmo mecanismo de `tests/support/pdf-text.ts` (`decodedPageTexts`/`hexOfAscii`, quantificador "toda página" — nunca só `getPage(0)`). Testes de integração do recorte: `publication.service.integration.test.ts` 37/38 (a suíte inteira dos cenários TASK-029-003 — describe "carimbo de Versão editorial no cabeçalho de rascunho" — 100% verde; a única falha, `GenerationTimeoutError` de AC-024-017/F6, é teste CPU-bound sensível a timing de máquina, sem relação com FEAT-028-002 — registrado em `fora_de_escopo`, não bloqueia este gate); `npm run typecheck` limpo. Dados de exercício (Conteúdo + 2 Versões) permanecem no banco de dev como resíduo declarado (não removidos), sem afetar nenhum teste automatizado (bancos de teste/dev são instâncias separadas).

- **FR-028-008** [MUST] Quando uma Exportação (PDF) é gerada para um Conteúdo bruto
  que tem ao menos uma Versão editorial fechada, o sistema deve estampar, em toda
  página do documento, o número da Versão vigente e a Data de fechamento legislativo
  dela — carimbo que atesta a verificação legislativa do **conteúdo normativo** (texto
  normativo e fonte normativa) daquele Conteúdo bruto, não de todo o material impresso
  no PDF nem do material de reforço nele contido.
- **FR-028-009** [MUST] Se o Conteúdo bruto não tiver nenhuma Versão editorial
  fechada, então a Exportação deve estampar, no mesmo local, uma marca textual
  explícita indicando a ausência de Versão fechada do conteúdo normativo (ex.: "sem
  versão"), em vez do número e da data.
- **FR-028-010** [MUST] O sistema deve manter o rótulo "Rascunho" (existente desde
  F6) estampado em toda página da Exportação sem alteração, coexistindo com o
  carimbo de Versão/Data (ou a marca de ausência) desta fatia na mesma página.
- **FR-028-011** [MUST] Se um campo versionado do Conteúdo bruto (texto normativo,
  Classe do radar de prova, fonte normativa) ou da Quebra da regra for alterado
  depois do fechamento da Versão vigente, então o sistema não deve estampar, na
  Exportação (PDF), a Versão vigente e a Data de fechamento legislativo dela como se
  o texto impresso tivesse sido verificado sem alteração — deve estampar a Versão
  vigente, a Data de fechamento legislativo dela e uma marca textual explícita de
  alteração posterior ao fechamento (ex.: "alterado após o fechamento da Versão N"),
  na mesma página, ao lado do rótulo "Rascunho". Regra fail-secure: deixar de acender
  essa marca quando houve alteração (falso negativo) é proibido; acender a marca por
  excesso de cautela quando o sinal de alteração for grosso demais para distinguir
  com precisão (falso positivo) é aceitável (A-028-012).

## 6. Requisitos não-funcionais

- **NFR-028-001** [MUST] O sistema deve registrar de forma auditável quem fechou cada
  Versão editorial e quando, sem que essa autoria jamais seja sobrescrita ou
  removida.
- **NFR-028-002** [MUST] A recusa de fechamento por falta de autorização (FR-028-002)
  deve ser fail-secure: não deve vazar, na resposta ao ator recusado, nenhum dado do
  Conteúdo bruto além do necessário para informar a recusa.
- **NFR-028-003** [SHOULD] A leitura do histórico de Versões de um Conteúdo bruto
  (FR-028-005) deve depender apenas do número de Versões daquele Conteúdo bruto, sem
  exigir varredura de todo o acervo.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-028-001** (cobre FR-028-001, FR-028-005)
  Dado um Conteúdo bruto com Quebra da regra salva e nenhuma Versão fechada, quando o
  autor aciona o fechamento de Versão informando a Data de fechamento legislativo,
  então o sistema registra a Versão número 1 com autor, timestamp técnico e a data
  informada, e essa Versão passa a aparecer no histórico do Conteúdo bruto.

- **AC-028-002** (cobre FR-028-001)
  Dado um Conteúdo bruto com 2 Versões editoriais já fechadas, quando o ADMIN fecha
  uma nova Versão desse Conteúdo bruto, então o sistema registra a Versão número 3,
  preservando as duas anteriores inalteradas no histórico.

- **AC-028-003** (cobre FR-028-002, NFR-028-001, NFR-028-002)
  Dado um Conteúdo bruto cujo autor é o EDITOR A, quando o EDITOR B — sem papel ADMIN
  — tenta fechar uma Versão desse Conteúdo bruto, então o sistema recusa a ação, não
  cria nenhuma Versão nova e a resposta da recusa não revela dado do Conteúdo bruto
  além do necessário para informar que a ação foi negada.

- **AC-028-004** (cobre FR-028-003)
  Dado um Conteúdo bruto sem Quebra da regra salva, quando o autor tenta fechar uma
  Versão, então o sistema recusa e informa que a Quebra da regra precisa existir
  antes do fechamento.

- **AC-028-005** (cobre FR-028-003)
  Dado um Conteúdo bruto removido de forma reversível (inalcançável), quando o autor
  tenta fechar uma Versão desse Conteúdo bruto, então o sistema recusa o fechamento
  da mesma forma que recusa qualquer outra operação sobre um Conteúdo bruto
  inalcançável.

- **AC-028-006** (cobre FR-028-004)
  Dado um Conteúdo bruto com 1 Versão editorial fechada, quando qualquer ator —
  inclusive um ADMIN — tenta alterar ou remover essa Versão, então o sistema recusa:
  nenhuma rota ou ação do sistema permite editar ou apagar uma Versão já fechada.

- **AC-028-007** (cobre FR-028-006)
  Dado o EDITOR na tela do Conteúdo bruto, quando ele aciona "fechar versão", então o
  controle mostra estado em andamento (desabilitado) até a resposta, e ao concluir
  mostra sucesso (a Versão nova visível no histórico) ou falha (mensagem do motivo)
  de forma visível.

- **AC-028-008** (cobre FR-028-007)
  Dado um Conteúdo bruto elegível ao fechamento, quando uma Versão editorial é
  fechada, então o sistema registra o evento de etapa de produção correspondente,
  sem exibir nenhuma tela nova a partir desse registro.

- **AC-028-009** (cobre FR-028-008)
  Dado um Conteúdo bruto com a Versão 3 fechada em 2026-09-01 e nenhum campo
  versionado alterado depois desse fechamento, quando o EDITOR exporta o PDF (em
  qualquer Variante), então toda página do documento exibe "Versão 3" e a data
  2026-09-01 — carimbo referente à verificação do conteúdo normativo — ao lado do
  rótulo "Rascunho" existente.

- **AC-028-010** (cobre FR-028-009)
  Dado um Conteúdo bruto sem nenhuma Versão editorial fechada, quando o EDITOR
  exporta o PDF, então toda página exibe a marca explícita de ausência de versão
  (ex.: "sem versão"), no mesmo local onde o número e a data apareceriam.

- **AC-028-011** (cobre FR-028-010)
  Dado qualquer Conteúdo bruto, com ou sem Versão fechada, quando o PDF é exportado,
  então o rótulo "Rascunho" continua aparecendo em toda página, sem que o carimbo de
  Versão/Data (ou a marca de ausência) o substitua.

- **AC-028-012** (cobre NFR-028-003)
  Dado um Conteúdo bruto com N Versões editoriais fechadas dentro de um acervo com
  milhares de outros Conteúdos brutos, quando o histórico de Versões desse Conteúdo
  bruto é lido, então o tempo de resposta depende apenas de N, não do tamanho do
  acervo inteiro.

- **AC-028-013** (cobre FR-028-011)
  Dado um Conteúdo bruto com Versão 3 fechada em 2026-09-01 e a Quebra da regra
  editada depois desse fechamento, quando o EDITOR exporta o PDF, então toda página
  exibe "Versão 3", a data 2026-09-01 e a marca de alteração posterior ao fechamento,
  ao lado do rótulo "Rascunho" existente.

## 8. Premissas e decisões prévias

- **A-028-001** [assumido] [evidência: crença] O gatilho do fechamento de Versão é um
  ato explícito do EDITOR/ADMIN autor ("fechar uma nova Versão"), nunca disparado
  automaticamente a cada edição do Conteúdo bruto ou da Quebra da regra.
- **A-028-002** [assumido] [evidência: crença] O objeto versionado por esta fatia é
  recortado por **campo**, não por tabela. Do Conteúdo bruto, os campos versionados
  são: texto normativo (`rawText`), Classe do radar de prova e fonte normativa
  (tipo/citação/URL do dispositivo). Da Quebra da regra, os campos versionados são os
  5 blocos e a síntese. A Pegadinha elaborada — coluna do próprio Conteúdo bruto no
  código, mas fora do recorte de produto desta fatia — NÃO é campo versionado, mesmo
  residindo na mesma linha de dado dos campos acima. Contraste/Flashcard (F7, tabelas
  próprias) e Tira mnemônica/Associação visual (F4/F5) também ficam fora do
  versionamento, como já previa a versão anterior desta premissa.
- **A-028-003** [assumido] [evidência: crença] Fechar uma Versão exige que a Quebra
  da regra do Conteúdo bruto já esteja salva (o par completo) — sem Quebra da regra,
  o fechamento é recusado (FR-028-003).
- **A-028-004** [assumido] [evidência: crença] A escolha entre snapshot imutável do
  texto (Conteúdo bruto + Quebra da regra) por Versão e referência mutável com só o
  registro de fechamento é decisão arquitetural irreversível que fica para o PLAN,
  com alternativas explícitas — esta SPEC descreve apenas o que não pode mudar depois
  do fechamento (número, Data de fechamento legislativo, autor, timestamp técnico) e
  não decide entre as duas formas. **Reabrir se**: o PLAN identificar que uma das
  formas é tecnicamente inviável dentro da topologia serverless já usada por F6.
- **A-028-005** [assumido] [evidência: crença] Sem backfill: Conteúdo bruto
  pré-existente não recebe Versão inicial automática; permanece "sem Versão fechada"
  até o 1º fechamento manual.
- **A-028-006** [assumido] [evidência: crença] A numeração da Versão é sequencial e
  escopada ao Conteúdo bruto (cada Conteúdo bruto tem sua própria sequência
  1, 2, 3, ...), não uma sequência global do acervo.
- **A-028-007** [assumido] [evidência: crença] A autorização para fechar uma Versão
  segue o mesmo padrão autor-ou-ADMIN já usado por F2/F4/F5/F7 — nenhum papel novo,
  nenhuma exceção.
- **A-028-008** [assumido] [evidência: crença] O carimbo de Versão/Data de
  fechamento legislativo no PDF exportado reusa o mesmo ponto onde o rótulo
  "Rascunho" (F6/SPEC-024) já é estampado em toda página; os dois carimbos coexistem
  sem que um substitua o outro nesta fatia — o rótulo "Rascunho" só deixa de existir
  quando o gate de aprovação de F9 existir (fora desta SPEC).
- **A-028-009** [assumido] [evidência: crença] Meta de adoção da métrica §1.3: default
  declarado de 80% das Exportações em até 4 semanas após o lançamento carregando
  Versão fechada real — sem dado histórico de adoção editorial no slug para calibrar
  melhor; vira Veredito de métrica no ciclo seguinte. Exportação com a marca de
  "alterado após o fechamento" (FR-028-011) não conta como Versão fechada real para
  esse numerador.
- **A-028-010** [assumido] [evidência: crença] O fechamento de Versão emite um evento
  de etapa de produção (mecanismo existente de F3), sem UI de consumo nesta fatia —
  mesma postura adotada por F4/F5/F7 ao introduzirem dado novo pendurado em Conteúdo
  bruto.
- **A-028-011** [assumido] [evidência: crença] Não há restrição de cadência entre
  fechamentos: um autor pode fechar Versões sucessivas sem exigência de mudança real
  de texto entre elas — mesma postura permissiva de operação de 1 pessoa já aceita em
  RISK-002-001/RISK-011-005.
- **A-028-012** [assumido] [evidência: decisão em nome do Diretor, veredito do po
  sobre SPEC-028] Carimbo pós-edição (FR-028-011): quando um campo versionado do
  Conteúdo bruto ou da Quebra da regra é alterado depois do fechamento da Versão
  vigente, o carimbo do PDF nunca pode implicar que o texto impresso foi verificado
  sem alteração — a marca de "alterado após o fechamento" acende sempre que houver
  esse sinal (falso negativo proibido); acender por excesso de cautela quando o sinal
  for grosso demais para distinguir com precisão é aceitável (falso positivo
  tolerado).

## 9. Riscos e questões abertas

- **RISK-028-001** A decisão entre snapshot imutável e referência mutável
  (A-028-004) ainda não foi tomada — muda a forma como o histórico realmente
  preserva (ou não) o texto de Versões anteriores; decisão arquitetural irreversível,
  cabe ao PLAN com alternativas explícitas.
- **RISK-028-002** O modelo `Mnemonic` legado dormente (RISK-011-001 / RISK-005-004)
  segue sem solução — apesar de ter sido apontado como possível gatilho de revisão
  quando F8 fosse planejada, esta fatia não o expurga nem o migra; permanece dado
  dormente duplicado no schema.
- **RISK-028-003** Sem teto de cadência entre fechamentos (A-028-011), o histórico
  pode acumular Versões sem mudança real de texto, poluindo o que a Versão vigente
  comunica ao leitor do PDF — aceito nesta fatia; revisitar se o piloto (PIL-001)
  reportar ruído real.
- **RISK-028-004** A "Versão aprovada" que F9 vai avaliar recai sobre um PDF que
  também imprime material de reforço (Contraste, Pegadinha elaborada, Flashcard,
  Tira mnemônica, Associação visual) não coberto pelo versionamento desta fatia —
  decidir se o gate de aprovação de F9 cobre ou não esse material de reforço é
  assunto de F9, não desta SPEC.
- **RISK-028-005** Um expurgo físico futuro de Conteúdo bruto, em cascata, apagaria
  as Versões editoriais dele — o que contradiz o requisito de append-only desta
  fatia (FR-028-004); a fatia que definir expurgo precisa resolver o destino das
  Versões antes de agir (nenhum mecanismo futuro pode remover uma Versão, direta ou
  indiretamente).
- **Q-028-001** Como a leitura do histórico de Versões (FR-028-005) convive, na
  mesma tela, com o "Carimbo de última alteração" (SPEC-005) já existente — mostrar
  os dois lado a lado, substituir um pelo outro, ou hierarquizar — fica para o
  PLAN/telas decidirem a disposição concreta; esta SPEC só exige que a leitura exista
  (FR-028-005), não a disposição visual.

## 10. Fora deste documento

Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
