# SPEC-032: Controle de qualidade e gate de versão aprovada

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.2
**Autor**: scribe
**Data**: 2026-09-27
**Brief**: BRIEF-032
**Jira**: KAN-149

## 1. Contexto e objetivo

### 1.1 Problema

F8 (SPEC-028) deu ao Conteúdo bruto um histórico append-only de Versões editoriais
(`ContentVersion`), mas o modelo não tem hoje nenhum campo de status ou de aprovação —
só `id`, `rawContentId`, `number`, `legislativeClosureDate`, `authorId`, `closedAt` e
`contentSnapshot` (`mnemonicos-backend/prisma/schema.prisma:593-614`). A única escrita
do módulo é `closeContentVersion` (fechamento); não existe `approve`/`reject` nem
qualquer verbo de decisão (`mnemonicos-backend/src/modules/content-versions/content-
versions.service.ts`). O PDF que a fábrica emite (F6) estampa incondicionalmente o
rótulo "RASCUNHO — documento gerado automaticamente, sujeito a revisão."
(`DRAFT_LABEL`, `mnemonicos-backend/src/modules/publication/pdf-composer.ts:108`) — não
existe hoje nenhum caminho para que um PDF saia marcado como material oficial.

RISK-002-001 (SPEC-002 §9) nomeia a pendência central: o papel `ADMIN` acumula
produção-adjacente, revisão jurídica e aprovação de versão; com uma operação de uma
pessoa, "revisor ≠ autor" não se cumpre por controle de sistema, e o gate de "Versão
aprovada" fica apoiado só em disciplina operacional — o defeito fail-open que o épico
nomeia como risco central desta fatia (BRIEF-2026-08-27, "Riscos por fatia" F9). A TAP
(§4.4, origem do projeto) exige controle de qualidade jurídica e pedagógica antes da
publicação; o mockup do BRIEF-001 menciona uma tela "Controle de Qualidade" com
"checklist de auditoria de 7 itens" — o BRIEF-032 (Interpretação do PO) nomeia os 7
itens explicitamente: fonte oficial, extração, estruturação, tira, checagem jurídica,
checagem pedagógica, publicação (mais o registro de fechamento de legislação,
legislação considerada, número de versão e histórico, já cobertos por F8) — não é,
portanto, um checklist sem conteúdo especificado; é um checklist que esta SPEC precisa
mapear e traduzir para o que o sistema pode verificar automaticamente e para o que
exige julgamento humano (ver §1.1.1).

### 1.1.1 Os 7 passos da TAP §4.4 mapeados ao que existe

Este mapeamento declara onde cada um dos 7 passos do BRIEF-032 é resolvido, para que a
leitura de "checklist de 7 itens" do mockup do BRIEF-001 não seja confundida nem com os
4 registros de fechamento que F8 já entrega (data de fechamento, legislação
considerada, número de versão, histórico), nem com as 2 confirmações de julgamento
humano que esta SPEC introduz:

| Passo (TAP §4.4) | Onde é resolvido |
| --- | --- |
| 1. Fonte oficial | Pré-condição automática: o sistema recusa a aprovação se a Versão vigente não tiver fonte normativa registrada (FR-032-013, nova — herda o compromisso A-005-008/SPEC-005). |
| 2. Extração | Coberta pela checagem jurídica (glossário §3): a confirmação atesta explicitamente que o texto normativo corresponde à fonte normativa citada, não só que "está correto". |
| 3. Estruturação | Já garantida por FR-028-003 (SPEC-028): não existe Versão fechada sem Quebra da regra salva; reforçada pela checagem pedagógica. |
| 4. Tira | Passa a integrar o escopo do gate (decisão do PO em nome do Diretor — ver §3, §4.1, RISK-032-002): coberta pela checagem pedagógica e pelo sinal de alteração pós-fechamento (FR-032-012). |
| 5. Checagem jurídica | Confirmação explícita no ato de aprovação (FR-032-001/FR-032-002). |
| 6. Checagem pedagógica | Confirmação explícita no ato de aprovação (FR-032-001/FR-032-002). |
| 7. Publicação | Efeito do próprio gate — o carimbo "Versão aprovada" no PDF (FR-032-010) —, não uma pré-condição a checar antes de aprovar. |

Os 4 registros que F8 (SPEC-028) já grava no fechamento — data de fechamento
legislativo, legislação considerada, número de versão, histórico — são um conjunto
diferente destes 7 passos do pipeline; já estavam resolvidos antes desta fatia e não
geram item de checklist novo aqui.

### 1.2 Outcome esperado

Um ADMIN que não seja nenhuma identidade produtora do conteúdo da Versão vigente
consegue avaliá-la — confirmando, num único ato, que a checagem jurídica (texto
normativo e fonte normativa corretos, e o texto normativo correspondente de fato à
fonte citada) e a checagem pedagógica (o material, incluindo a Tira mnemônica
vinculada, cumpre a função de recuperação) foram feitas — e aprová-la. O sistema
recusa essa aprovação, de forma fail-secure, sempre que o ator for qualquer identidade
registrada como produtora do conteúdo normativo da Versão (quem a fechou, o autor
original do Conteúdo bruto ou quem editou por último o Conteúdo bruto antes do
fechamento), e recusa aprovar quando qualquer uma das duas confirmações não é
verdadeira, quando falta fonte normativa registrada, quando o número de Versão
informado deixou de ser o vigente, ou quando o sinal de alteração pós-fechamento está
aceso. Uma vez aprovada, a aprovação é permanente: nenhum ator, nem ADMIN, reverte,
edita ou revoga uma aprovação já registrada — reavaliar exige fechar e aprovar uma
Versão nova.

A partir da aprovação, a Exportação (PDF) desse Conteúdo bruto passa a estampar, em
toda página, uma marca declarando explicitamente o alcance do carimbo (ex.: "Conteúdo
normativo e Tira mnemônica — Versão N aprovada", com o número e a Data de fechamento
legislativo) no lugar do rótulo "Rascunho" — mas só enquanto a Versão vigente for
exatamente a Versão aprovada e nenhum campo versionado (nem a Tira mnemônica vinculada)
tiver sido alterado depois do fechamento dela. Uma Versão nova fechada sem aprovação,
ou uma edição pós-fechamento da Versão aprovada (do conteúdo normativo ou da Tira
mnemônica), fazem o PDF voltar a sair como "Rascunho" — nunca aparentar aprovação que
não vale mais para o texto atualmente impresso. O carimbo de aprovação se refere ao
conteúdo normativo (texto normativo, fonte normativa, Classe do radar de prova, blocos
da Quebra da regra) já coberto pelo versionamento de F8, mais a Tira mnemônica
vinculada — que entra no escopo desta fatia (decisão do PO em nome do Diretor;
RISK-032-002) —, mas não ao restante do material de reforço (Contraste, Pegadinha
elaborada, Flashcard, Associação visual), que fica fora do escopo desta fatia.

### 1.3 Métrica de sucesso

Em até 4 semanas após o lançamento desta fatia, pelo menos 50% das Versões vigentes
fechadas (com Quebra da regra salva) do acervo ativo recebem uma aprovação registrada —
sinal de que o gate deixou de ser disciplina operacional (RISK-002-001) e passou a ser
efetivamente aplicado. Esta métrica só é medida a partir do momento em que existirem
2+ contas ADMIN de pessoas distintas ativas simultaneamente; antes disso, o período não
entra no cálculo — ausência de dado válido, não reprovação (mesma leitura de
RISK-032-001). O numerador exclui aprovações cuja Versão foi depois invalidada por
alteração pós-fechamento (mesma régua herdada de A-028-012/F8: uma aprovação com o
sinal de alteração aceso não conta como aprovação válida vigente para efeito de
adoção). O alvo é mais baixo que o 80%/4 semanas de F8 (A-028-009) porque a aprovação
exige um 2º ator distinto de toda identidade produtora do conteúdo (segregação de
funções, §3): a adoção depende de dotação de equipe (2+ ADMINs distintos, A-002-017),
não só de disciplina — se o piloto rodar com um único ADMIN, o numerador fica
estruturalmente em 0% por construção (RISK-032-001), o que não é falha de adoção. Sem
dado histórico de adoção; vira Veredito de métrica no ciclo seguinte.

**Métrica-guarda (invariante, válida desde o dia 1, independente de dotação de
equipe)**: (a) 0 aprovações registradas em que o aprovador coincide com qualquer
identidade produtora do conteúdo (segregação de funções, §3); (b) 0 PDFs exportados com
o carimbo "Versão aprovada" sobre um conteúdo com sinal de alteração pós-fechamento
aceso. As duas devem ser sempre verdadeiras — violação de qualquer uma é bug, não dado
de adoção.

**Fonte de medição**: instrumentação — consulta cruzando o evento de etapa de produção
do ato de aprovação (mesmo mecanismo de F3) com o total de Versões vigentes fechadas do
acervo, por Conteúdo bruto; a métrica-guarda cruza o mesmo evento com as identidades
produtoras do Conteúdo bruto (`RawContent.authorId`, `RawContent.lastEditedById`) e com
o sinal de alteração pós-fechamento (FR-032-012).

## 2. Personas e jobs-to-be-done

**ADMIN (revisor/aprovador)** — "Como ADMIN, quero confirmar a checagem jurídica e a
pedagógica de uma Versão vigente e aprová-la, quando eu não for nenhuma identidade que
produziu o conteúdo, para liberar a Exportação como material oficial em vez de
rascunho."

**EDITOR (autor da Versão)** — "Como EDITOR que fechei uma Versão, quero ver se ela foi
aprovada e por quem, para saber se o PDF que exporto sai marcado como oficial ou como
rascunho."

**Anti-persona**: o STUDENT segue sem nenhum papel nesta capacidade — nenhuma tela,
rota ou fluxo aqui descrito é consumido por ele; ele só lê o resultado (o PDF já
carimbado), sem interagir com o mecanismo de aprovação.

## 3. Glossário (Ubiquitous Language)

- **Checagem jurídica (confirmação)**: atestação, feita pelo ADMIN no próprio ato de
  aprovação, de que (a) o texto normativo e a fonte normativa da Versão vigente estão
  corretos e (b) o texto normativo corresponde de fato à fonte normativa citada — cobre
  explicitamente o passo "extração" da TAP §4.4 (ver §1.1.1), não só "está correto" —
  critério de controle de qualidade jurídica da TAP §4.4. (novo, SPEC-032)
- **Checagem pedagógica (confirmação)**: atestação, feita pelo ADMIN no mesmo ato, de
  que o material da Versão vigente — incluindo a Tira mnemônica vinculada — cumpre a
  função de recuperação (critério de "Necessidade" da TAP, já usado como critério de
  aprovação da Tira mnemônica em BRIEF-001 §8.2/SPEC-011). (novo, SPEC-032)
- **Segregação de funções (do ato de aprovação)**: regra aplicada pelo sistema, não por
  disciplina operacional, de que o ator que aprova uma Versão não pode ser nenhuma
  identidade registrada como produtora do conteúdo normativo dela — piso mínimo desta
  SPEC: quem fechou a Versão (`ContentVersion.authorId`), o autor original do Conteúdo
  bruto (`RawContent.authorId`) ou quem editou por último o Conteúdo bruto antes do
  fechamento (`RawContent.lastEditedById`). Resolve, para esta fatia, RISK-002-001/
  A-002-016 (SPEC-002 §9). Aplicar a segregação **por sistema** (em vez de disciplina
  operacional), fail-secure, é decisão do Diretor (AskUserQuestion, 2026-09-27); o piso
  de 3 identidades e a ausência de papel novo no enum de papéis são premissa do
  PO/Tech Lead aplicando essa diretriz de forma mais restritiva/fail-secure, não uma
  segunda pergunta ao Diretor (ver A-032-002). (novo, SPEC-032)
- **Conteúdo normativo (escopo da aprovação)**: o recorte já versionado por F8 — texto
  normativo, Classe do radar de prova, fonte normativa e os blocos/síntese da Quebra da
  regra —, mais a Tira mnemônica (Quadros) vinculada ao Conteúdo bruto, que a checagem
  jurídica/pedagógica e a aprovação avaliam; não inclui o restante do material de
  reforço (Contraste, Pegadinha elaborada, Flashcard, Associação visual), que permanece
  fora do versionamento e da aprovação (RISK-032-002). (novo, SPEC-032)

Termos reutilizados do glossário consolidado do INDEX, sem redefinição: **Versão
aprovada** (BRIEF-001 — "checagem jurídica e pedagógica passaram; material liberado
para exportação (gate)": esta SPEC é o gate que o termo já previa — mas, aqui, "Versão
aprovada" designa especificamente o carimbo oficial estampado no PDF, o efeito visível
do gate, não "libera a exportação": a Exportação já é sempre liberada desde F6 — sempre
sai um PDF, com "Rascunho" ou com o carimbo; o que esta fatia muda é só qual dos dois
aparece, ver A-032-011); **Versão editorial**, **Fechar uma Versão (ato)**, **Versão
vigente**, **Fechamento legislativo** (SPEC-028); **Conteúdo bruto**, **Quebra da
regra**, **Bloco da quebra** (SPEC-005); **Publicação**, **Variante do PDF**,
**Rascunho (PDF)**, **Exportação** (SPEC-024); **Papel**, **Deny-by-default**
(SPEC-002).

## 4. Escopo

### 4.1 In-scope

- Ato de aprovação da Versão vigente de um Conteúdo bruto, num único ato, condicionado
  a duas confirmações explícitas informadas nele mesmo: checagem jurídica e checagem
  pedagógica.
- Pré-condição automática de fonte normativa registrada (tipo do dispositivo e
  citação) antes de aceitar a aprovação — sem fonte normativa, o sistema recusa e
  informa a ausência (herda o compromisso A-005-008, SPEC-005).
- Segregação de funções aplicada pelo sistema, fail-secure: recusa da aprovação quando
  quem aprova é qualquer identidade registrada como produtora do conteúdo normativo da
  Versão vigente (quem fechou, o autor original do Conteúdo bruto, ou quem editou por
  último o Conteúdo bruto antes do fechamento).
- Duplo travamento do alvo da aprovação: o ato informa explicitamente o número da
  Versão sendo avaliada (o sistema recusa se esse número deixou de ser o da Versão
  vigente entre a abertura da tela e o clique), e a aprovação é recusada enquanto o
  sinal de alteração pós-fechamento estiver aceso para a Versão vigente.
- Restrição do ato de aprovação ao papel ADMIN, deny-by-default (o EDITOR continua
  podendo fechar Versões, como em F8, e ler o estado de aprovação, mas não aprovar).
- Terminalidade/append-only da aprovação — nenhuma reversão por edição; reavaliar
  exige fechar e aprovar uma Versão editorial nova; idempotência de uma 2ª tentativa de
  aprovação sobre a mesma Versão já aprovada (exatamente 1 registro, nunca dois).
- Regra de não-propagação: uma Versão nova fechada depois de uma Versão aprovada nasce
  não aprovada; a aprovação anterior não se transfere.
- Recusa de aprovação para Conteúdo bruto inalcançável (removido de forma reversível).
- Leitura do estado de aprovação (aprovada ou não; quando aprovada, por quem e quando;
  e se essa aprovação continua válida para o texto atualmente impresso) junto ao
  histórico de Versões editoriais já exposto por F8.
- Escopo do conteúdo normativo avaliado pela aprovação e estampado no carimbo passa a
  incluir a Tira mnemônica vinculada, além do texto normativo, fonte normativa, Classe
  do radar de prova e blocos da Quebra da regra já versionados por F8.
- Carimbo "Versão aprovada" no PDF exportado, declarando explicitamente esse alcance,
  substituindo o rótulo "Rascunho".
- Reversão do carimbo para "Rascunho" (com a marca de alteração posterior herdada de
  F8, estendida para também cobrir a Tira mnemônica) quando a Versão vigente aprovada é
  editada depois do fechamento, ou quando a Versão vigente passa a ser uma Versão nova
  ainda não aprovada.
- Registro do ato de aprovação como evento de etapa de produção (mesmo mecanismo
  append-only de F3), sem tela nova de consumo.

### 4.2 Out-of-scope

- Papel dedicado de "revisor jurídico" no enum de papéis — pareia com a restrição do
  ato de aprovação ao ADMIN acima: a segregação de funções desta fatia usa comparação
  de identidade, não um papel novo (RISK-002-001 aceitou esta alternativa como a mais
  simples e reversível).
- Checklist ou aprovação cobrindo o restante do material de reforço (Contraste,
  Pegadinha elaborada, Flashcard, Associação visual) — pareia com o carimbo no PDF
  acima: o carimbo e a checagem cobrem o conteúdo normativo já versionado por F8 mais a
  Tira mnemônica (decisão do PO em nome do Diretor, ver RISK-032-002); os demais 4
  tipos de material de reforço permanecem fora.
- Estado explícito de "reprovada"/rejeição persistido — pareia com o ato de aprovação
  acima: a ausência de aprovação já comunica "ainda não aprovada"; um ADMIN que
  discorda simplesmente não aprova (comunicação de motivo fica fora do sistema nesta
  fatia).
- Edição, revogação ou "reabertura" de uma aprovação já registrada, por qualquer
  papel, inclusive ADMIN — pareia com a terminalidade/append-only acima.
- Notificação, alerta ou fila de trabalho de Versões pendentes de aprovação — pareia
  com a leitura do estado acima: a leitura passiva do estado existe; empurrar ou
  enfileirar não.
- Cálculo ou alerta de vencimento/expiração de legislação — pareia com o carimbo no
  PDF acima, herdado do out-of-scope de F8 (a Data de fechamento legislativo segue
  sem prazo de validade calculado).
- Painel estratégico (F10) e fila/calendário editorial (F11) — pareia com o registro
  de evento de etapa acima: o evento é emitido, mas nenhum painel ou fila o consome
  nesta fatia.
- Reabertura do pipeline de composição do PDF (F6) além de acrescentar o carimbo de
  aprovação — pareia com o carimbo no PDF acima: nenhuma outra mudança na diagramação
  do documento.
- Controle técnico para detectar contas ADMIN fantoche criadas para contornar a
  segregação de funções — pareia com a segregação de funções acima: a comparação é por
  conta, não por pessoa (RISK-032-005); controle detectivo fica para fatia futura.
- Expurgo ou migração do modelo `Mnemonic` legado dormente (RISK-011-001/
  RISK-005-004) — segue sem solução, sem relação com esta fatia.

## 5. Requisitos funcionais (EARS)

### FEAT-032-001: Aprovação da Versão vigente com checklist de qualidade e segregação de funções

**Jira**: KAN-150

**Verificação (gate 9)**: 2026-09-29 — consolidado: (1) `qa`, execução real com browser contra backend/frontend locais (frontend `a4e828f` e, no delta do retry, `e68553d`; backend `eba5603`) — aprovação por ADMIN não-produtor com o envio represado (`aria-busy`/desabilitado), estado persistido após recarregar, negação de autoaprovação para o produtor, ramo "não" da validade após editar o conteúdo na mesma página, reset do estado ao fechar nova Versão, linha "Aprovada por…" por Versão para ADMIN e EDITOR (AC-032-001/007/020/023, parte UI); (2) ACs só-backend (AC-032-002 a 008 e 013 a 019) provados por integração com Postgres real e mutantes nos gates 1/8 de TASK-033-003/004 (565/565).

> Do ponto de vista do QA: um ADMIN que não é nenhuma identidade produtora do conteúdo
> normativo da Versão vigente confirma a checagem jurídica e a pedagógica e aprova; o
> sistema recusa quando falta confirmação, quando não há Versão para aprovar, quando
> falta fonte normativa registrada, quando o número informado não é mais o da Versão
> vigente, quando o sinal de alteração pós-fechamento está aceso, quando o aprovador é
> qualquer identidade produtora do conteúdo (quem fechou, autor original ou último
> editor), quando o ator não é ADMIN, quando o Conteúdo bruto está inalcançável, ou
> numa 2ª tentativa sobre a mesma Versão já aprovada; uma vez aprovada, a Versão nunca
> é desaprovada por edição, e o estado — inclusive se a aprovação continua válida para
> o texto atualmente impresso — aparece na leitura do histórico.

- **FR-032-001** [MUST] Quando um ADMIN aciona a aprovação da Versão vigente de um
  Conteúdo bruto informando a confirmação da checagem jurídica e da checagem
  pedagógica, e ambas as confirmações são verdadeiras, o sistema deve registrar essa
  Versão como aprovada, com o identificador de quem aprovou e o timestamp da aprovação.
- **FR-032-002** [MUST] Se a confirmação da checagem jurídica ou da checagem
  pedagógica não for informada como verdadeira, então o sistema deve recusar a
  aprovação e não deve registrar nenhum estado de aprovação parcial.
- **FR-032-003** [MUST] Se o Conteúdo bruto alvo não tiver nenhuma Versão editorial
  fechada, então o sistema deve recusar a aprovação e informar que não há Versão para
  aprovar.
- **FR-032-004** [MUST] Se o ator que aciona a aprovação for qualquer uma das
  identidades registradas como produtoras do conteúdo normativo da Versão vigente —
  quem fechou essa Versão (`ContentVersion.authorId`), o autor original do Conteúdo
  bruto (`RawContent.authorId`) ou quem editou por último o Conteúdo bruto antes do
  fechamento (`RawContent.lastEditedById`) —, então o sistema deve recusar a aprovação,
  independentemente do papel do ator, e não deve registrar nenhum estado de aprovação.
  Regra de desempate: fail-secure — na dúvida sobre qual identidade se aplica, o
  sistema recusa.
- **FR-032-005** [MUST] O sistema deve tratar a aprovação de uma Versão como terminal e
  append-only: uma vez aprovada, nenhum ator — inclusive ADMIN — pode alterar, revogar
  ou reverter essa aprovação; uma nova avaliação só é possível fechando uma Versão
  editorial nova e aprovando-a separadamente.
- **FR-032-006** [MUST] Quando uma Versão editorial mais recente é fechada depois de
  uma Versão anterior já aprovada, o sistema deve tratar a nova Versão vigente como não
  aprovada até que ela própria receba uma aprovação — a aprovação de uma Versão
  anterior nunca se propaga para uma Versão posterior.
- **FR-032-007** [MUST] O sistema deve expor, para leitura, junto ao histórico de
  Versões editoriais de um Conteúdo bruto (FR-028-005): (a) se cada Versão foi
  aprovada e, quando aprovada, por quem e quando; e (b) se a aprovação da Versão
  vigente continua válida para o texto atualmente impresso — ou seja, se a próxima
  Exportação sairia com o carimbo "Versão aprovada" ou com "Rascunho" (considerando o
  sinal de alteração pós-fechamento de FR-032-012).
- **FR-032-008** [MUST] Quando o ADMIN aciona a aprovação pela interface, o sistema
  deve indicar visivelmente que a ação está em andamento (controle desabilitado ou
  indicador equivalente) até a resposta, e ao concluir deve mostrar sucesso (a Versão
  passa a aparecer como aprovada) ou falha (mensagem do motivo da recusa) de forma
  observável.
- **FR-032-009** [MUST] O sistema deve registrar o ato de aprovação como evento de
  etapa de produção (mesmo mecanismo append-only introduzido em F3), sem exigir
  nenhuma tela nova de consumo nesta fatia.
- **FR-032-013** [MUST] Se a Versão vigente de um Conteúdo bruto não tiver fonte
  normativa registrada (tipo do dispositivo e citação — campos já versionados por F8,
  A-028-002), então o sistema deve recusar a aprovação, informando a ausência da fonte
  normativa. (herdado do compromisso A-005-008, SPEC-005 — a obrigatoriedade da fonte
  normativa entra no gate de "Versão aprovada", F9)
- **FR-032-014** [MUST] O ato de aprovação deve informar explicitamente o número da
  Versão que o ADMIN está revisando; se, no momento do processamento, esse número não
  for mais o da Versão vigente do Conteúdo bruto, o sistema deve recusar a aprovação.
- **FR-032-015** [MUST] O sistema deve recusar a aprovação enquanto o sinal de
  alteração pós-fechamento (mesmo sinal de FR-028-011) estiver aceso para a Versão
  vigente do Conteúdo bruto.
- **FR-032-016** [MUST] Se o ator que aciona a aprovação não tiver o papel ADMIN,
  então o sistema deve recusar a aprovação, independentemente de qualquer outra
  condição (deny-by-default, mesmo padrão de SPEC-002).
- **FR-032-017** [MUST] Se a Versão alvo já estiver aprovada, então o sistema deve
  recusar ou tratar de forma idempotente uma nova tentativa de aprovação sobre ela —
  inclusive concorrente/simultânea —, garantindo exatamente 1 registro de aprovação e
  exatamente 1 evento de etapa de produção para aquela Versão, nunca dois.
- **FR-032-018** [MUST] Se o Conteúdo bruto da Versão alvo estiver inalcançável
  (removido de forma reversível, mesma régua de FR-028-003), então o sistema deve
  recusar a aprovação.

### FEAT-032-002: Carimbo de Versão aprovada no PDF exportado

**Jira**: KAN-151

**Verificação (gate 9)**: 2026-09-29 — `qa`, execução real ponta a ponta contra o backend local (HEAD `5984073`, Postgres de dev): 6/6 ACs (AC-032-009/010/011/012/021/024) exercitados por HTTP, com aprovação por um 2º ADMIN e alteração da Tira pela rota real de Quadros; texto de cada PDF inspecionado por `pdftotext` nas 2 Variantes (a marca substitui "RASCUNHO" em toda página; 4ª linha de Versão/Data preservada).

> Do ponto de vista do QA: exportar o PDF de um Conteúdo bruto cuja Versão vigente
> está aprovada mostra a marca de alcance explícito ("Conteúdo normativo e Tira
> mnemônica — Versão N aprovada", ou equivalente) em vez de "Rascunho"; exportar quando
> a Versão vigente não está aprovada — nunca avaliada, superada por uma Versão nova sem
> aprovação, ou alterada (no conteúdo normativo ou na Tira mnemônica) depois do
> fechamento — mantém "Rascunho", nunca aparentando aprovação que não vale para o texto
> impresso.

- **FR-032-010** [MUST] Quando uma Exportação (PDF) é gerada para um Conteúdo bruto
  cuja Versão vigente está aprovada e nenhum campo versionado — incluindo a Tira
  mnemônica vinculada — foi alterado depois do fechamento dessa Versão, o sistema deve
  estampar, em toda página do documento, uma marca textual explícita declarando o
  alcance da aprovação — por exemplo, "Conteúdo normativo e Tira mnemônica — Versão N
  aprovada" (N = número da Versão) — junto com a Data de fechamento legislativo dela,
  no lugar do rótulo "Rascunho". A marca deve deixar explícito que o carimbo cobre o
  conteúdo normativo e a Tira mnemônica, não o restante do material de reforço
  (Contraste, Pegadinha elaborada, Flashcard, Associação visual).
- **FR-032-011** [MUST] Se a Versão vigente de um Conteúdo bruto não estiver aprovada —
  nunca avaliada, ou superada por uma Versão mais recente ainda não aprovada
  (FR-032-006) —, então a Exportação deve continuar estampando o rótulo "Rascunho"
  (comportamento herdado de F6/F8), sem nenhuma marca de aprovação.
- **FR-032-012** [MUST] Se um campo versionado do Conteúdo bruto ou da Quebra da regra,
  ou a Tira mnemônica (Quadros) vinculada ao Conteúdo bruto, for alterado depois do
  fechamento da Versão vigente aprovada (mesmo sinal de alteração de FR-028-011,
  estendido nesta fatia para também cobrir a Tira mnemônica), então a Exportação não
  deve estampar a marca de "Versão aprovada": deve voltar a estampar "Rascunho" com a
  marca de alteração posterior ao fechamento já prevista por FR-028-011. A aprovação
  registrada permanece intacta como fato histórico (FR-032-005), mas deixa de ser
  exibida como válida para o texto atualmente impresso. Regra fail-secure: nunca
  estampar "Versão aprovada" quando há sinal de alteração pós-fechamento (de qualquer
  campo versionado ou da Tira mnemônica), mesmo que o sinal seja impreciso demais para
  distinguir com precisão.

## 6. Requisitos não-funcionais

- **NFR-032-001** [MUST] O sistema deve registrar de forma auditável quem aprovou cada
  Versão editorial e quando, sem que essa autoria jamais seja sobrescrita ou removida.
- **NFR-032-002** [MUST] A recusa de aprovação por segregação de funções (FR-032-004)
  deve ser fail-secure: não deve vazar, na resposta ao ator recusado, nenhum dado do
  Conteúdo bruto além do necessário para informar a recusa, e nenhuma condição de erro
  ou exceção durante o ato de aprovação pode resultar em aprovação registrada por
  padrão.
- **NFR-032-003** [SHOULD] A leitura do estado de aprovação de um Conteúdo bruto
  (FR-032-007) deve depender apenas do número de Versões daquele Conteúdo bruto, sem
  exigir varredura de todo o acervo.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-032-001** (cobre FR-032-001, FR-032-007, NFR-032-001)
  Dado um Conteúdo bruto cuja Versão vigente foi fechada por um autor, e um ADMIN que
  não é nenhuma identidade produtora do conteúdo, quando o ADMIN aciona a aprovação
  confirmando a checagem jurídica e a pedagógica como verdadeiras, então a Versão
  vigente é registrada como aprovada com o identificador do ADMIN e o timestamp da
  aprovação, e essa informação passa a aparecer na leitura do histórico do Conteúdo
  bruto.

- **AC-032-002** (cobre FR-032-002)
  Dado o mesmo cenário do AC-032-001, quando o ADMIN aciona a aprovação sem confirmar a
  checagem pedagógica (ou a jurídica) como verdadeira, então o sistema recusa a
  aprovação e nenhum estado de aprovação é registrado.

- **AC-032-003** (cobre FR-032-003)
  Dado um Conteúdo bruto sem nenhuma Versão editorial fechada, quando um ADMIN tenta
  aprovar, então o sistema recusa e informa que não há Versão para aprovar.

- **AC-032-004** (cobre FR-032-004, NFR-032-002) — área sensível, caso de negação
  Dado um Conteúdo bruto cuja Versão vigente foi fechada pelo ADMIN X, quando o próprio
  ADMIN X aciona a aprovação dessa mesma Versão, então o sistema recusa a aprovação,
  não registra nenhum estado de aprovação, e a resposta da recusa não revela dado do
  Conteúdo bruto além do necessário para informar a negação.

- **AC-032-005** (cobre FR-032-005)
  Dado uma Versão editorial já aprovada, quando qualquer ator — inclusive um ADMIN —
  tenta alterar, revogar ou reverter essa aprovação, então o sistema recusa: nenhuma
  rota ou ação permite mutar uma aprovação já registrada.

- **AC-032-006** (cobre FR-032-006)
  Dado um Conteúdo bruto com a Versão 2 aprovada, quando o autor fecha a Versão 3,
  então a Versão vigente passa a ser a 3 e ela aparece como não aprovada até receber
  sua própria aprovação, mesmo a Versão 2 permanecendo aprovada no histórico.

- **AC-032-007** (cobre FR-032-008)
  Dado o ADMIN na tela de aprovação, quando ele aciona "aprovar versão", então o
  controle mostra estado em andamento (desabilitado) até a resposta, e ao concluir
  mostra sucesso (a Versão aparece como aprovada) ou falha (mensagem do motivo) de
  forma visível.

- **AC-032-008** (cobre FR-032-009)
  Dado um Conteúdo bruto elegível à aprovação, quando uma Versão é aprovada, então o
  sistema registra o evento de etapa de produção correspondente, sem exigir nenhuma
  tela nova de consumo.

- **AC-032-009** (cobre FR-032-010)
  Dado um Conteúdo bruto com a Versão 3 aprovada, nenhum campo versionado alterado
  depois do fechamento dela e a Tira mnemônica vinculada também sem alteração
  posterior, quando o EDITOR exporta o PDF (em qualquer Variante), então toda página do
  documento exibe a marca de alcance explícito (ex.: "Conteúdo normativo e Tira
  mnemônica — Versão 3 aprovada"), o número 3 e a data de fechamento legislativo, no
  lugar do rótulo "Rascunho".

- **AC-032-010** (cobre FR-032-011)
  Dado um Conteúdo bruto cuja Versão vigente nunca foi aprovada, quando o EDITOR
  exporta o PDF, então toda página continua exibindo o rótulo "Rascunho", sem nenhuma
  marca de aprovação.

- **AC-032-011** (cobre FR-032-011)
  Dado um Conteúdo bruto com a Versão 2 aprovada e uma Versão 3 fechada depois dela,
  sem aprovação da Versão 3, quando o EDITOR exporta o PDF, então toda página exibe
  "Rascunho" — referente à Versão vigente 3, não aprovada —, sem nenhuma marca de
  aprovação da Versão 2.

- **AC-032-012** (cobre FR-032-012) — fail-secure
  Dado um Conteúdo bruto com a Versão vigente aprovada e um campo versionado (ex.:
  texto normativo) alterado depois desse fechamento, quando o EDITOR exporta o PDF,
  então toda página exibe "Rascunho" com a marca de alteração posterior ao fechamento
  (herdada de FR-028-011), e nenhuma página exibe a marca de "Versão aprovada".

- **AC-032-013** (cobre NFR-032-003)
  Dado um Conteúdo bruto com N Versões editoriais, algumas aprovadas, dentro de um
  acervo com milhares de outros Conteúdos brutos, quando o estado de aprovação desse
  Conteúdo bruto é lido, então o tempo de resposta depende apenas de N, não do tamanho
  do acervo inteiro.

- **AC-032-014** (cobre FR-032-013)
  Dado uma Versão vigente fechada sem fonte normativa registrada (tipo do dispositivo e
  citação), quando um ADMIN tenta aprová-la, então o sistema recusa e informa que falta
  a fonte normativa.

- **AC-032-015** (cobre FR-032-014) — corrida, caso de negação
  Dado um ADMIN com a tela de aprovação aberta sobre a Versão 3 (vigente no momento da
  abertura), quando, antes do clique, uma Versão 4 é fechada por outro ator tornando-a
  a vigente, e então o ADMIN aciona a aprovação informando o número 3, então o sistema
  recusa a aprovação porque o número informado não é mais o da Versão vigente.

- **AC-032-016** (cobre FR-032-015) — corrida, caso de negação
  Dado uma Versão vigente com o sinal de alteração pós-fechamento aceso (um campo
  versionado ou a Tira mnemônica alterados depois do fechamento), quando um ADMIN
  elegível (não produtor do conteúdo) tenta aprová-la, então o sistema recusa a
  aprovação enquanto o sinal permanecer aceso.

- **AC-032-017** (cobre FR-032-016) — área sensível, caso de negação
  Dado um EDITOR (sem papel ADMIN), quando ele tenta acionar a aprovação de uma Versão,
  então o sistema recusa a aprovação (deny-by-default, mesmo padrão de SPEC-002).

- **AC-032-018** (cobre FR-032-017) — área sensível, caso de negação
  Dado uma Versão já aprovada, quando uma 2ª tentativa de aprovação sobre a mesma
  Versão ocorre (inclusive concorrente/simultânea), então o sistema recusa ou trata de
  forma idempotente, garantindo exatamente 1 registro de aprovação e 1 evento de etapa
  de produção para aquela Versão — nunca dois.

- **AC-032-019** (cobre FR-032-018) — área sensível, caso de negação
  Dado um Conteúdo bruto removido de forma reversível (inalcançável, mesma régua de
  FR-028-003), quando um ADMIN tenta aprovar uma Versão dele, então o sistema recusa a
  aprovação.

- **AC-032-020** (cobre FR-032-007)
  Dado um Conteúdo bruto com a Versão vigente aprovada e depois alterada (sinal de
  alteração pós-fechamento aceso), quando o estado de aprovação é lido, então a leitura
  indica que a próxima Exportação sairia como "Rascunho", não como "Versão aprovada",
  mesmo a aprovação permanecendo registrada como fato histórico.

- **AC-032-021** (cobre FR-032-011) — não-regressão de F8
  Dado um Conteúdo bruto sem nenhuma Versão fechada, quando o EDITOR exporta o PDF,
  então continua saindo a marca de ausência de versão (ex.: "sem versão") e o rótulo
  "Rascunho" — comportamento herdado de F8, intocado.

- **AC-032-023** (cobre FR-032-004) — área sensível, caso de negação
  Dado um Conteúdo bruto cujo texto normativo foi escrito pelo ADMIN Y
  (`RawContent.authorId`) e cujo fechamento da Versão vigente foi feito pelo ADMIN X
  (identidades diferentes), quando o ADMIN Y (autor do conteúdo, não quem fechou)
  aciona a aprovação dessa Versão, então o sistema recusa a aprovação e não registra
  nenhum estado de aprovação.

- **AC-032-024** (cobre FR-032-012) — fail-secure
  Dado um Conteúdo bruto com a Versão vigente aprovada e a Tira mnemônica vinculada
  alterada depois desse fechamento (nenhum outro campo alterado), quando o EDITOR
  exporta o PDF, então toda página exibe "Rascunho" com a marca de alteração posterior
  ao fechamento, e nenhuma página exibe a marca de "Versão aprovada".

## 8. Premissas e decisões prévias

- **A-032-001** [assumido] [evidência: premissa do PO/Tech Lead na largada, herdada de
  BRIEF-032] O checklist de qualidade é vinculado à Versão editorial (`ContentVersion`),
  não ao Conteúdo bruto mutável — mesma lógica append-only de F8 (DEC-029-003): mudar o
  conteúdo depois do fechamento não altera retroativamente uma aprovação já registrada.
- **A-032-002** [assumido] [evidência: decisão do Diretor (AskUserQuestion,
  2026-09-27) para "aplicar segregação de funções por sistema, fail-secure"; a
  identidade exata de "autor" — o piso de 3 identidades abaixo — é premissa do
  PO/Tech Lead aplicando essa diretriz de forma mais restritiva/fail-secure, não uma
  segunda pergunta ao Diretor] Segregação de funções por comparação de identidade,
  aplicada pelo sistema, fail-secure: o aprovador não pode ser nenhuma identidade
  registrada como produtora do conteúdo normativo da Versão vigente — piso mínimo desta
  SPEC: quem fechou a Versão (`ContentVersion.authorId`), o autor original do Conteúdo
  bruto (`RawContent.authorId`) e quem editou por último o Conteúdo bruto antes do
  fechamento (`RawContent.lastEditedById`). Nenhum papel novo no enum de papéis
  (premissa do PO/Tech Lead, não decisão literal do Diretor); resolve RISK-002-001/
  A-002-016 para esta fatia. Se existir dado mais granular de autoria por edição
  intermediária (ex.: eventos de F3), o PLAN pode ampliar a régua; na ausência, este
  piso de 3 identidades é a regra mínima exigida por esta SPEC, não opcional. Regra de
  desempate: fail-secure — na dúvida sobre identidade, recusa.
- **A-032-003** [assumido] [evidência: premissa do PO/Tech Lead na largada, herdada de
  BRIEF-032] A aprovação é terminal e append-only: uma vez aprovada, não há revogação
  por edição; reavaliar exige fechar uma Versão editorial nova e aprová-la
  separadamente — a aprovação antiga permanece histórico imutável.
- **A-032-004** [assumido] [evidência: crença] A aprovação (checklist + segregação de
  funções) é um único ato atômico: o ADMIN informa, no mesmo ato, a confirmação da
  checagem jurídica e da checagem pedagógica — não dois toggles independentes
  persistidos ao longo do tempo por atores/momentos diferentes. Simplificação
  deliberada: nenhum insumo (BRIEF-001/TAP) especifica um fluxo assíncrono de checklist
  com múltiplos atores por item, e um ato único evita estado de aprovação parcial sem
  dono. **Reabrir se**: o piloto (PIL-001) reportar necessidade real de separar a
  checagem jurídica e a pedagógica entre atores ou momentos diferentes.
- **A-032-005** [assumido] [evidência: crença] Só o papel ADMIN pode aprovar uma Versão
  — não o EDITOR —, refletindo a persona já declarada em SPEC-002 §2 ("ADMIN: gestão de
  contas + revisão jurídica + aprovação de versão"). O EDITOR continua podendo fechar
  Versões (herdado de F8) e ler o estado de aprovação, mas não aprovar (FR-032-016).
- **A-032-006** [assumido] [evidência: crença] O checklist desta fatia usa exatamente 2
  confirmações de julgamento humano — checagem jurídica e checagem pedagógica — que,
  somadas às pré-condições automáticas que o sistema já verifica (fonte normativa
  registrada, FR-032-013; existência de Versão fechada com Quebra da regra salva,
  FR-028-003) e ao próprio carimbo de aprovação (o efeito do gate, não uma
  pré-condição), cobrem os 7 passos da TAP §4.4 (fonte oficial, extração, estruturação,
  tira, checagem jurídica, checagem pedagógica, publicação) nomeados pelo BRIEF-032 —
  ver mapeamento em §1.1.1. Não é uma redução de escopo: é a tradução de "7 passos de
  pipeline" para "2 atos de julgamento humano + N pré-condições automáticas". As 4
  obrigações registradas por F8 (data de fechamento, legislação considerada, número de
  versão, histórico) são um conjunto diferente dos 7 passos do pipeline e já estavam
  satisfeitas antes desta fatia. **Reabrir se**: o Diretor quiser granularidade maior
  (ex.: um item por bloco da Quebra da regra).
- **A-032-007** [assumido] [evidência: crença] Não existe estado explícito de
  "reprovada"/rejeição persistido nesta fatia — a ausência de aprovação já comunica
  "ainda não aprovada"; um ADMIN que discorda simplesmente não aprova (comunicação do
  motivo fica fora do sistema). **Reabrir se**: o piloto reportar necessidade de
  rastrear reprovações explícitas.
- **A-032-008** [assumido] [evidência: crença] A aprovação usa duplo travamento
  explícito do alvo, não um alvo implícito: (a) o ato informa o número da Versão que o
  ADMIN está revisando, e o sistema recusa se esse número deixou de ser o da Versão
  vigente entre a abertura da tela e o clique (FR-032-014); (b) o sistema recusa a
  aprovação enquanto o sinal de alteração pós-fechamento (mesmo sinal de FR-028-011)
  estiver aceso para a Versão vigente (FR-032-015) — cobre a corrida em que a Versão
  vigente muda, ou é editada, entre a abertura da tela e o clique de aprovar.
- **A-032-009** [assumido] [evidência: crença] Meta de adoção da métrica §1.3: 50% das
  Versões vigentes fechadas recebendo aprovação em até 4 semanas — mais baixa que o 80%
  de F8 (A-028-009) porque a aprovação exige um 2º ator distinto de toda identidade
  produtora do conteúdo (RISK-002-001), tornando a adoção dependente de dotação de
  equipe, não só de disciplina. Medida apenas a partir do momento em que existirem 2+
  contas ADMIN de pessoas distintas ativas simultaneamente (ver métrica-guarda
  invariante em §1.3, que não depende dessa condição). Sem dado histórico; vira
  Veredito de métrica no ciclo seguinte.
- **A-032-010** [assumido] [evidência: crença] O ato de aprovação emite um evento de
  etapa de produção (mecanismo de F3), sem UI de consumo nesta fatia — mesma postura já
  adotada por F4/F5/F7/F8 ao introduzirem dado novo pendurado em Conteúdo bruto.
- **A-032-011** [assumido] [evidência: crença] FR-032-010 restringe FR-028-010
  (SPEC-028) ao caso em que a Versão vigente não está aprovada; AC-028-011 fica
  igualmente restrito a esse caso. Não é regressão de F8: F8 continua correto para
  Conteúdo sem aprovação — o rótulo "Rascunho" segue coexistindo com o carimbo de
  Versão/Data nesse caso; quando a Versão está aprovada e válida, FR-032-010 substitui
  esse rótulo pelo carimbo "Versão aprovada". Nota terminológica: o termo "Versão
  aprovada" reutilizado do glossário consolidado do INDEX (BRIEF-001 §3) significa
  aqui, especificamente, o carimbo oficial estampado no PDF — o efeito visível do gate
  desta SPEC —, não "libera a exportação": a Exportação já é sempre liberada desde F6;
  o que esta fatia muda é apenas o carimbo (Rascunho vs. Versão aprovada).

## 9. Riscos e questões abertas

- **RISK-032-001** Se a operação rodar com um único ADMIN (RISK-002-001 herdado),
  nenhuma aprovação é possível por construção — a segregação de funções recusa toda
  autoaprovação. A métrica de adoção (§1.3) fica estruturalmente em 0% até existirem
  2+ ADMINs distintos; não é falha de adoção, é ausência de dotação de equipe.
  *Mitigação*: nenhuma nesta fatia (é o resultado esperado do fail-secure); dotação de
  equipe é decisão do Diretor (A-002-017).
- **RISK-032-002** Contraste, Pegadinha elaborada, Flashcard e Associação visual ficam
  fora do gate — decisão do PO em nome do Diretor, degrau 1/2 da escada, reversível (o
  BRIEF-032 não os menciona); a Tira mnemônica, ao contrário, ENTRA no escopo do gate
  (decisão em nome do Diretor, degrau 2 — não-bloqueante, mas pendente de confirmação
  explícita na Entrega, já que o BRIEF a lista no checklist original). O carimbo no PDF
  declara seu próprio alcance explicitamente: "Conteúdo normativo e Tira mnemônica —
  Versão N aprovada" (ou texto equivalente), para que o leitor (inclusive o STUDENT,
  que só lê o PDF) não presuma que Contraste/Pegadinha/Flashcard/Associação visual
  também foram revisados. *Mitigação*: aceito nesta fatia; revisitar se o piloto
  reportar confusão real do leitor do PDF sobre o alcance do carimbo.
- **RISK-032-003** O ato único atômico (A-032-004) não impede que um único ADMIN
  confirme as duas checagens sem ter revisado de fato — o sistema garante que houve um
  clique explícito de confirmação, não que a revisão realmente ocorreu; a honestidade
  da confirmação segue em disciplina operacional, mesma classe de limitação fail-open
  que RISK-002-001 já nomeava para a revisão em si. *Mitigação*: nenhum mecanismo
  técnico detecta revisão real vs. confirmação apressada; aceito nesta fatia.
- **RISK-032-004** O modelo `Mnemonic` legado dormente (RISK-011-001/RISK-005-004)
  segue sem solução — não revisitado por esta fatia.
- **RISK-032-005** A segregação de funções compara CONTAS, não pessoas — com operação
  de 1 pessoa (RISK-032-001), o caminho natural para contornar o bloqueio é essa pessoa
  criar uma 2ª conta ADMIN e aprovar consigo mesma através dela. O sistema não distingue
  isso de uma segregação real feita por 2 pessoas de fato distintas. *Mitigação*:
  nenhum controle técnico detecta isso nesta fatia (controle detectivo — ex.: recusar
  se a conta aprovadora foi criada pela mesma identidade que produziu o conteúdo — fica
  para fatia futura, se o piloto reportar o padrão); aceito como risco residual, mesma
  régua de RISK-032-001/RISK-002-001. Decisão registrada, não escalação.
- **Q-032-001** A disposição visual do estado de aprovação na tela do Conteúdo bruto
  (junto ao bloco "Histórico de Versões" de F8, ou em bloco próprio) fica para o
  PLAN/telas decidirem — esta SPEC só exige que a leitura exista (FR-032-007), mesma
  régua de Q-028-001.

## 10. Fora deste documento

Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
