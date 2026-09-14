# SPEC-024: Pipeline de publicação — PDF (rascunho)

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.1
**Autor**: keelson (scribe)
**Data**: 2026-09-14
**Brief**: BRIEF-024
**Jira**: KAN-106
**Jira Story**: KAN-107

## 1. Contexto e objetivo

### 1.1 Problema

Nenhuma geração ou exportação de PDF existe hoje nos dois repositórios — nem dependência,
nem rota, nem script (MAP.md, "Publicação (ausente)"). A TAP (BRIEF-001) é explícita: o
ativo do projeto é o método, mas **é o PDF que o estudante compra** (§4.2) — mesmo o
estudante não sendo usuário deste software (a fábrica entrega o PDF por outro canal). F4
entregou a Tira mnemônica como sequência estruturada de Quadros (`MnemonicStrip`/
`MnemonicFrame`) e F5 entregou a Biblioteca visual (`VisualAssociation`, vinculável por
Quadro) — mas nada hoje compõe esses insumos num documento. Cada Conteúdo bruto já
produzido, com Quebra da regra salva e eventualmente Tira e Associações visuais, fica
preso no sistema: não existe nenhum artefato exportável para revisão ou compartilhamento
fora da fábrica, mesmo em estágio de rascunho — antes de qualquer fechamento editorial
(F8) ou QC jurídico (F9), que só existirão em fatias futuras.

### 1.2 Outcome esperado

Um EDITOR ou ADMIN, a partir da tela do Conteúdo bruto ou da tela da Tira mnemônica,
aciona a exportação de um PDF para um Conteúdo bruto com Quebra da regra já salva, e
recebe um documento marcado visivelmente como **rascunho**, numa de duas variantes do
mesmo pedido: **tira** (diagramação dos Quadros em ordem, com a Associação visual
vinculada de cada Quadro quando existir) ou **resumo** (a Quebra da regra em texto
corrido, sem diagramação de Quadros — o braço de controle do A/B de retenção, A-012,
citado na decomposição do épico). Nenhuma das duas variantes espera o carimbo de versão
aprovada, que só existe depois de F8 (versionamento/fechamento legislativo) e F9 (QC
jurídico).

### 1.3 Métrica de sucesso

Esta fatia é infraestrutura de pipeline, não a régua central do épico ("tempo de produção
por página", que pertence a F3/F10) — mesma postura já adotada por SPEC-009 e SPEC-022
para fatias de mecanismo. O efeito verificável próprio desta fatia é a confiabilidade da
própria geração: a proporção de tentativas de exportação que terminam num PDF entregue com
sucesso (sem falha silenciosa nem documento parcial/corrompido devolvido como válido),
apurada por variante.

O denominador de "tentativas" não é integralmente instrumentado: só existe evento de etapa
em sucesso (FR-024-010) — registrar falha de renderização nessa mesma série corromperia sua
semântica, herdada de F3/SPEC-009: `ProductionStageEvent` é append-only e significa trabalho
editorial ocorrido, não uma tentativa técnica. A apuração desta métrica é por isso mista, de
duas fontes.

**Fonte de medição**: (a) instrumentada — contagem de exportações concluídas com sucesso,
por Variante, via o evento de etapa de produção (`ProductionStageType`, valor aditivo
`PUBLICACAO_PDF`, mesmo mecanismo de F3/SPEC-009 e F5/SPEC-022; FR-024-010); (b)
observacional — contagem de falhas de exportação da mesma janela, apurada manualmente na
Entrega do ciclo, lida do log de erro do backend (sem evento de etapa em falha). Meta
inicial: ao menos 95% de exportações concluídas com sucesso nos primeiros 30 dias corridos
após a entrega desta fatia, lida sobre essa apuração mista — sucessos instrumentados ÷
(sucessos instrumentados + falhas do log) — vira veredito de métrica no ciclo seguinte,
mesma régua das demais SPECs do slug (decisão 4.99).

## 2. Personas e jobs-to-be-done

Como EDITOR da fábrica, preciso exportar em PDF, a qualquer momento depois de salvar a
Quebra da regra, o material que já produzi — como Tira diagramada ou como resumo em texto
corrido —, para revisar ou compartilhar fora do sistema, sem esperar o fechamento
editorial que só existe em fatias futuras (F8/F9).

Anti-persona (decisão 4.98, herdada): não é para o estudante — a exportação é ferramenta
interna de produção, mesma postura de todo o slug; e não é para quem precisa do PDF com
carimbo de aprovação (versão fechada para venda/distribuição) — essa necessidade só é
atendida a partir de F8+F9.

## 3. Glossário (Ubiquitous Language)

| Termo | Definição | Origem |
|-------|-----------|--------|
| Tira mnemônica | (reusado, não redefinido) — sequência ordenada de Quadros que reconstrói uma regra | INDEX.md / SPEC-011 |
| Quadro | (reusado, não redefinido) — unidade atômica de texto com posição na Tira | INDEX.md / SPEC-011 |
| Conteúdo bruto | (reusado, não redefinido) — texto normativo + disciplina + tema/assunto + classe do radar de prova | INDEX.md / SPEC-005 |
| Quebra da regra | (reusado, não redefinido) — decomposição do texto normativo bruto nos cinco Blocos, mais a Síntese da regra essencial | INDEX.md / SPEC-005 |
| Associação visual | (reusado, não redefinido) — imagem a serviço da recuperação, reprovada se removê-la não perder função cognitiva | INDEX.md / BRIEF-001 |
| Biblioteca visual | (reusado, não redefinido) — acervo pesquisável e reutilizável de Associações visuais | INDEX.md / SPEC-022 |
| Versão aprovada | (reusado, não redefinido) — checagem jurídica e pedagógica passaram, material liberado; em contraste direto com o rascunho desta fatia | INDEX.md / BRIEF-001 |
| Publicação | Ato de gerar um documento PDF a partir de um Conteúdo bruto, numa das duas Variantes desta fatia, sempre marcado como rascunho | BRIEF-024 / BRIEF-2026-08-27-mnemora-studio-epic (F6) |
| Variante do PDF | Uma das duas composições possíveis do mesmo pedido de exportação: "tira" (Quadros em ordem, com Associação visual vinculada quando existir) ou "resumo" (texto corrido da Quebra da regra, sem diagramação de Quadros — braço de controle do A/B de retenção, A-012) | BRIEF-024 / BRIEF-2026-08-27-mnemora-studio-epic |
| Rascunho (PDF) | Rótulo textual visível estampado em todo PDF emitido por esta fatia, indicando que o documento não passou pelo carimbo de Versão aprovada (F8+F9) | BRIEF-024 / BRIEF-2026-08-27-mnemora-studio-epic |
| Exportação | Ação disparada pelo EDITOR ou ADMIN, na tela do Conteúdo bruto ou da Tira mnemônica, que aciona a Publicação e resulta no download do PDF gerado | BRIEF-024 |

## 4. Escopo

### 4.1 In-scope

- Endpoint de exportação no backend que gera um PDF sob demanda a partir de um Conteúdo
  bruto com Quebra da regra salva, acionável por EDITOR ou ADMIN.
- Duas Variantes nascidas do **mesmo** pedido de exportação (não são telas/fluxos
  separados): "tira" e "resumo".
- Variante "resumo": exige só a Quebra da regra salva; texto corrido, sem diagramação de
  Quadros.
- Variante "tira": exige a Tira mnemônica existir; se ainda não foi aberta, o próprio
  pedido de exportação a gera automaticamente (reusa a geração idempotente já existente de
  F4, `openMnemonicStrip`), sem exigir passo manual prévio nem tela dedicada.
- Rótulo textual de rascunho visível no próprio documento, em ambas as Variantes, e
  indicação clara da Variante no nome do arquivo resultante.
- Acionamento da exportação a partir da tela do Conteúdo bruto ou da tela da Tira
  mnemônica (`(interno)/content/[id]/tira`), com os três estados observáveis da ação (em
  andamento, sucesso, falha — decisão 4.67).
- Quadro sem Associação visual vinculada: a variante "tira" segue emitindo esse Quadro
  (só o texto), nunca bloqueando a exportação por isso.
- Postura de segurança do motor de geração, agnóstica da biblioteca concreta: sem
  conexão de rede a partir de conteúdo do usuário (mitiga SSRF, OWASP A01); todo texto do
  usuário tratado como dado, nunca como marcação/template executável (mitiga injeção,
  OWASP A05).
- Falha segura na geração: nenhum PDF parcial ou corrompido é disponibilizado para
  download como se fosse válido.
- Instrumentação: emissão de um evento de etapa de produção (valor aditivo do
  `ProductionStageType`, mesmo mecanismo de F3/F5) a cada exportação concluída com
  sucesso.

### 4.2 Out-of-scope

- Papel novo de "publicador" ou aprovador — quem lê "endpoint de exportação" poderia
  assumir um papel dedicado junto; esta fatia reusa a mesma barreira EDITOR/ADMIN de
  F1/F2/F4/F5, sem papel novo.
- Telas ou fluxos separados por Variante, ou uma tela dedicada de pré-requisito para abrir
  a Tira mnemônica antes de exportar — quem lê "duas Variantes" poderia assumir dois
  fluxos distintos; nascem do mesmo pedido, e a Tira é gerada automaticamente quando falta.
- Carimbo de Versão aprovada e o gate de QC jurídico (F9) — quem lê "PDF" poderia assumir
  um documento aprovado; esta fatia emite exclusivamente rascunho.
- Versionamento editorial e data de fechamento de legislação (F8) — quem lê "Publicação"
  poderia assumir controle de versão junto; fica para F8.
- Contrastes, pegadinhas e flashcards impressos (F7) — quem lê "PDF do material" poderia
  assumir essas camadas compostas junto; fora desta fatia.
- Reprocessamento de imagem (redimensionamento, recompressão) da Associação visual ao
  compor o PDF — quem lê "diagramação de imagem" poderia assumir ajuste do arquivo; esta
  fatia usa o binário exatamente como F5 o armazenou, e o ajuste de proporção/tamanho no
  leiaute da página é decisão de diagramação do PLAN, não alteração do arquivo.
- Persistência do PDF gerado como entidade própria e qualquer tela de histórico/listagem
  de exportações — quem lê "instrumentação" ou "Publicação" poderia assumir um
  repositório de PDFs gerados; esta fatia é geração sob demanda, entregue direto no
  download, sem cópia armazenada além do necessário para a resposta.
- Painel estratégico e tempo por página (F10) — quem lê a métrica de §1.3 poderia assumir
  a régua central do épico junto; não antecipada aqui.
- Fila de produção e calendário editorial (F11) — fora do MVP por decisão do Diretor.
- Geração automática de imagem por IA — fora do inventário original do PM, sem pedido do
  Diretor.
- Escolha do motor/biblioteca concreta de geração de PDF — decisão técnica do PLAN; esta
  SPEC define apenas o comportamento observável e a postura de segurança, agnóstica de
  tecnologia.
- Preview do PDF no navegador antes do download — quem lê "exportação" poderia assumir
  visualização embutida; esta fatia entrega só download direto (`Content-Disposition`),
  sem tela de preview.

## 5. Requisitos funcionais (EARS)

- **FR-024-001** [MUST] Quando um EDITOR ou ADMIN aciona a exportação de um Conteúdo
  bruto com Quebra da regra salva, o sistema deve gerar um documento PDF na Variante
  solicitada (tira ou resumo), com o rótulo visível de rascunho em toda página do
  documento e a data/hora de geração exibida em ao menos uma página.
- **FR-024-002** [MUST] Se o Conteúdo bruto não tem Quebra da regra salva, então o
  sistema deve recusar a exportação, em qualquer Variante, e informar que não há o que
  exportar. A recusa é exclusivamente pela ausência de Quebra da regra salva — Conteúdo
  bruto com Quebra salva mas Blocos majoritariamente vazios (ex.: só a Síntese preenchida)
  gera o PDF normalmente; julgamento de suficiência editorial do conteúdo fica fora desta
  fatia (F9).
- **FR-024-003** [MUST] Quando a Variante solicitada é "resumo", o sistema deve compor o
  PDF com o texto corrido derivado da Quebra da regra, sem diagramação de Quadros.
- **FR-024-004** [MUST] Quando a Variante solicitada é "tira", o sistema deve compor o
  PDF com os Quadros da Tira mnemônica em ordem, incluindo a Associação visual vinculada
  de cada Quadro quando existir.
- **FR-024-005** [MUST] Enquanto um Quadro da Tira mnemônica não tem Associação visual
  vinculada, o sistema deve emitir esse Quadro no PDF da Variante "tira" somente com o
  texto, sem bloquear a exportação por causa disso.
- **FR-024-006** [MUST] Quando a Variante "tira" é solicitada e a Tira mnemônica do
  Conteúdo bruto ainda não foi aberta, o sistema deve gerar a Tira mnemônica
  automaticamente (mesma geração idempotente de F4) antes de compor o PDF, em vez de
  recusar a exportação.
- **FR-024-007** [MUST] Quando um EDITOR ou ADMIN aciona a exportação, o sistema deve
  expor três estados observáveis: em andamento, sucesso e falha, cada um com indicação
  visível.
- **FR-024-008** [MUST] O sistema deve nomear o arquivo PDF resultante de forma que o
  nome indique claramente que é rascunho e qual Variante (tira ou resumo) ele representa.
- **FR-024-009** [MUST] Se a geração do documento PDF como um todo falhar (ex.: erro do
  motor de geração, timeout — FR-024-015), então o sistema deve descartar qualquer
  documento parcial e não deve disponibilizar nenhum arquivo para download — falha isolada
  de uma Associação visual vinculada não caracteriza essa falha (coberta por FR-024-014).
- **FR-024-010** [MUST] Quando uma exportação é concluída com sucesso, o sistema deve
  emitir um evento de etapa de produção (valor aditivo do `ProductionStageType`, mesmo
  mecanismo de F3/F5) registrando a Variante exportada.
- **FR-024-011** [MUST] O sistema NÃO deve persistir o documento PDF gerado como entidade
  própria nesta fatia — cada exportação é gerada sob demanda e entregue diretamente na
  resposta ao pedido, sem cópia mantida além do necessário para essa resposta.
- **FR-024-012** [MUST] O sistema deve permitir acionar a exportação, nas duas Variantes,
  a partir da tela do Conteúdo bruto ou da tela da Tira mnemônica, sem exigir navegação
  por uma tela dedicada de pré-requisito.
- **FR-024-013** [MUST] Quando a Variante "tira" gera a Tira mnemônica automaticamente
  (FR-024-006), o sistema NÃO deve emitir o evento de abertura da etapa de produção "Tira
  mnemônica" (`ProductionStageType.TIRA_MNEMONICA`, ABERTURA) nesse instante — a abertura
  da etapa só deve ser emitida na 1ª abertura humana da tela da Tira ou na 1ª mutação
  humana sobre ela, o que vier primeiro.
- **FR-024-014** [MUST] Quando uma Associação visual vinculada a um Quadro não pode ser
  decodificada/renderizada pelo motor de geração, o sistema deve emitir esse Quadro
  apenas com o texto (mesmo comportamento de Quadro sem Associação visual) e concluir a
  exportação com sucesso, em vez de descartar o documento inteiro.
- **FR-024-015** [MUST] Se a geração do PDF exceder um teto de duração (valor definido no
  PLAN), então o sistema deve encerrá-la e informar falha ao usuário pelo mesmo canal de
  FR-024-009/AC-024-008, nunca deixar a requisição sem resposta.
- **FR-024-016** [MUST] Quando a Variante "tira" é gerada, o sistema deve compor o PDF
  com 1 Quadro por página (RISK-011-007 — unidade destinada a uma página do PDF).

## 6. Requisitos não-funcionais

- **NFR-024-001** [MUST] O motor de geração de PDF NÃO PODE abrir conexão de rede a
  partir de conteúdo fornecido pelo usuário durante a renderização do documento,
  mitigando SSRF (OWASP A01).
- **NFR-024-002** [MUST] Todo texto fornecido pelo usuário (texto da Quebra da regra,
  texto de Quadro, categoria e função cognitiva da Associação visual) DEVE ser tratado
  como dado na composição do PDF, nunca interpretado como marcação ou template
  executável, mitigando injeção (OWASP A05).
- **NFR-024-003** [MUST] Toda rota e tela desta superfície DEVE exigir sessão autenticada
  com papel EDITOR ou ADMIN — nunca STUDENT nem acesso anônimo (deny-by-default, mesmo
  padrão herdado de SPEC-002).
- **NFR-024-004** [MUST] O sistema NÃO PODE recodificar, redimensionar ou recomprimir o
  binário da Associação visual ao compor o PDF — a imagem é usada como armazenada por F5;
  ajuste de proporção/tamanho de exibição na página é decisão de diagramação do PLAN, não
  alteração do arquivo.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-024-001** (cobre FR-024-002)
  Dado um Conteúdo bruto sem Quebra da regra salva, quando um EDITOR aciona a exportação
  em qualquer Variante, então o sistema recusa a exportação, informa que não há o que
  exportar e não gera nenhum arquivo.

- **AC-024-002** (cobre FR-024-003)
  Dado um Conteúdo bruto com Quebra da regra salva, quando o EDITOR aciona a exportação
  na Variante "resumo", então o sistema gera um PDF, marcado como rascunho, com o texto
  corrido derivado da Quebra da regra, sem diagramação de Quadros.

- **AC-024-003** (cobre FR-024-004, FR-024-005)
  Dada uma Tira mnemônica já aberta com Quadros em ordem, alguns com Associação visual
  vinculada e outros sem, quando o EDITOR aciona a exportação na Variante "tira", então o
  sistema gera um PDF com os Quadros na ordem da Tira, exibindo a Associação visual
  vinculada quando existir e emitindo somente o texto quando não existir, sem bloquear a
  exportação por causa de nenhum Quadro sem imagem.

- **AC-024-004** (cobre FR-024-006)
  Dado um Conteúdo bruto com Quebra da regra salva cuja Tira mnemônica ainda não foi
  aberta, quando o EDITOR aciona a exportação na Variante "tira", então o sistema gera a
  Tira mnemônica automaticamente e compõe o PDF a partir dela, sem recusar a exportação
  nem exigir nenhum passo manual anterior.

- **AC-024-005** (cobre FR-024-001)
  Dado qualquer PDF gerado por esta fatia, em qualquer Variante, quando o documento é
  aberto em qualquer página, então TODA página exibe um rótulo textual visível indicando
  que é rascunho e qual Variante representa, e ao menos uma página exibe a data/hora de
  geração do documento, rotulada explicitamente como tal e NUNCA como data de fechamento
  de legislação (que só existe em F8).

- **AC-024-006** (cobre FR-024-007)
  Dado um EDITOR acionando a exportação, então, enquanto a geração está em andamento, o
  controle de exportar fica desabilitado com indicador visível; ao concluir com sucesso,
  o sistema disponibiliza o arquivo para download de forma visível; e, se a operação
  falhar, o sistema informa o erro de forma visível, sem apagar a seleção de Variante já
  feita.

- **AC-024-007** (cobre FR-024-008)
  Dado um PDF gerado com sucesso, quando o EDITOR observa o nome do arquivo baixado,
  então o nome indica claramente que é rascunho e qual Variante (tira ou resumo) ele
  representa.

- **AC-024-008** (cobre FR-024-009)
  Dada uma falha na geração do documento como um todo (não uma falha isolada de uma
  Associação visual, coberta por FR-024-014), quando ela ocorre em qualquer etapa do
  processo, então o sistema não disponibiliza nenhum arquivo para download, descarta
  qualquer documento parcial e informa a falha ao usuário.

- **AC-024-009** (cobre NFR-024-003)
  Dado um usuário autenticado com papel STUDENT, ou uma requisição sem sessão válida,
  quando ele tenta acionar a exportação, então o sistema recusa a operação.

- **AC-024-010** (cobre NFR-024-001, NFR-024-002)
  Dado um Conteúdo bruto cujo texto da Quebra da regra, de um Quadro, ou a categoria/
  função cognitiva de uma Associação visual vinculada contém uma sequência que se
  pareceria com marcação ou diretiva de template, quando o PDF é gerado, então o sistema
  compõe o documento tratando esse texto literalmente como dado exibido, sem interpretá-lo
  como marcação executável, e sem que a geração abra qualquer conexão de rede a partir
  desse conteúdo.

- **AC-024-011** (cobre NFR-024-004)
  Dada uma Associação visual vinculada a um Quadro, quando o PDF da Variante "tira" é
  gerado, então o binário da imagem usado na composição é o mesmo armazenado por F5, sem
  recompressão ou re-encoding — qualquer ajuste de proporção/tamanho é só de exibição no
  leiaute da página, nunca alteração do arquivo.

- **AC-024-012** (cobre FR-024-010)
  Dada uma exportação concluída com sucesso, quando o evento de etapa é emitido, então
  ele registra a Variante exportada e fica apurável pela consulta que sustenta a métrica
  de §1.3 (mesmo mecanismo de leitura interna de F3), sem exigir exibição em nenhuma tela
  desta fatia.

- **AC-024-013** (cobre FR-024-011)
  Dada qualquer exportação concluída, quando a resposta ao pedido é enviada, então o
  sistema não mantém nenhuma cópia do PDF gerado além do necessário para essa resposta —
  uma nova exportação do mesmo Conteúdo bruto gera o documento novamente do zero.

- **AC-024-014** (cobre FR-024-012)
  Dado um Conteúdo bruto com Quebra da regra salva, quando o EDITOR está na tela do
  Conteúdo bruto ou na tela da Tira mnemônica, então ele encontra o controle de
  exportação, nas duas Variantes, sem precisar navegar para uma tela dedicada de
  pré-requisito.

- **AC-024-015** (cobre FR-024-013)
  Dado um Conteúdo bruto cuja Tira mnemônica ainda não existe, quando a exportação da
  Variante "tira" a gera automaticamente, então o sistema NÃO emite o evento de abertura
  da etapa de produção "Tira mnemônica" nesse instante — a abertura só é emitida na 1ª
  interação humana com a Tira (abrir a tela ou mutar um Quadro), o que vier primeiro.

- **AC-024-016** (cobre FR-024-014)
  Dado um Quadro com Associação visual vinculada cujo binário o motor de geração não
  consegue decodificar/renderizar, quando o PDF da Variante "tira" é gerado, então esse
  Quadro sai só com texto e a exportação conclui com sucesso, sem descartar o documento.

- **AC-024-017** (cobre FR-024-015)
  Dada uma geração que excede o teto de duração definido no PLAN, quando o teto é
  atingido, então o sistema informa falha ao usuário (mesmo comportamento observável de
  falha de FR-024-007), sem deixar a requisição pendente indefinidamente.

- **AC-024-018** (cobre NFR-024-003)
  Dado um EDITOR diferente do autor original do Conteúdo bruto, quando ele aciona a
  exportação de um Conteúdo bruto de outro EDITOR, então o sistema permite a exportação
  normalmente (alcance comum a EDITOR/ADMIN, herdado de F4/F5, sem restrição adicional
  por autoria).

- **AC-024-019** (cobre NFR-024-003)
  Dado um Conteúdo bruto removido (soft-delete, `deletedAt` preenchido), quando qualquer
  EDITOR ou ADMIN tenta exportá-lo, inclusive por id direto, então o sistema recusa como
  não-encontrado, mesmo comportamento de qualquer outro acesso a Conteúdo removido
  (SPEC-005).

- **AC-024-020** (cobre FR-024-016)
  Dada uma Tira mnemônica com N Quadros, quando o PDF da Variante "tira" é gerado, então
  o documento tem N páginas de conteúdo de Quadro, uma por Quadro, na ordem da Tira.

## 8. Premissas e decisões prévias

- **A-024-001** [assumido] [evidência: crença] Todo PDF emitido nesta fatia é sempre
  rascunho; o carimbo de Versão aprovada só existe a partir de F8 (versionamento) + F9
  (QC jurídico). Decisão já tomada na decomposição do épico (BRIEF-2026-08-27, confirmada
  pelo Diretor) e reafirmada no pedido desta fatia (BRIEF-024) — NÃO é aposta do time: é
  decisão já confirmada pelo Diretor (BRIEF-2026-08-27-mnemora-studio-epic.md, "Perguntas
  ao Diretor — respondidas na decomposição", itens 2 e 3, 2026-08-27).
- **A-024-002** [assumido] [evidência: crença] A postura de segurança do motor de
  geração (sem rede a partir de conteúdo do usuário — NFR-024-001; texto do usuário
  nunca interpolado como template — NFR-024-002) é requisito não-funcional agnóstico de
  biblioteca; a escolha do motor concreto é decisão técnica do PLAN. Fonte: BRIEF-024,
  que já nomeia um motor puro-JS sem browser headless como candidato a recomendar no
  PLAN (decisão final por DEC com alternativas).
- **A-024-003** [assumido] [evidência: crença] As duas Variantes nascem do mesmo pedido
  de exportação, não de telas/fluxos separados; "resumo" exige só a Quebra salva, "tira"
  exige a Tira mnemônica existir, gerada automaticamente se ainda não aberta (FR-024-006).
  Fonte: BRIEF-024 — NÃO é aposta do time: a existência da Variante "resumo" como saída
  de F6 já é decisão confirmada pelo Diretor (BRIEF-2026-08-27-mnemora-studio-epic.md,
  "Perguntas ao Diretor — respondidas na decomposição", item 3, 2026-08-27).
- **A-024-004** [assumido] [evidência: crença] Quadro sem Associação visual vinculada
  segue emitido na Variante "tira" só com o texto — a Associação visual é enriquecimento,
  nunca bloqueio de exportação. Fonte: BRIEF-024.
- **A-024-005** [assumido] [evidência: crença] Sem reprocessamento de imagem
  (redimensionamento/recompressão) nesta fatia — a Associação visual entra no PDF
  exatamente como F5 a armazenou; ajuste de proporção/tamanho no leiaute é decisão de
  diagramação do PLAN, não alteração do arquivo. Fonte: BRIEF-024.
- **A-024-006** [assumido] [evidência: crença] A Variante "resumo" compõe o texto corrido
  a partir dos mesmos Blocos não-vazios da Quebra da regra que alimentam a geração de
  Quadros em F4 (mesma seleção de conteúdo, ordem canônica CONCEITO → AÇÃO → OBJETO →
  CONDIÇÃO → EXCEÇÃO), mais a Síntese da regra essencial, em prosa corrida — isso
  maximiza a equivalência informacional entre as duas Variantes, isolando a variável de
  apresentação (Quadros estruturados × prosa corrida) que o braço de controle do A/B
  (A-012) precisa testar, em vez de introduzir uma segunda variável de conteúdo. `Reabrir
  se:` o Diretor decidir, ao responder E-01/SPEC-011 (INDEX, Riscos ativos), que o A/B
  deve comparar conteúdo diferente entre as duas pernas, não só apresentação.
- **A-024-007** [assumido] [evidência: crença] O nome do arquivo PDF inclui um indicador
  textual de "rascunho" e da Variante (ex.:
  `<identificador-do-conteudo>-<variante>-rascunho.pdf`); o formato exato do nome é
  detalhe técnico do PLAN — a exigência de que o nome comunique essas duas informações é
  desta SPEC (FR-024-008).
- **A-024-008** [assumido] [evidência: crença] O PDF gerado não é persistido como
  entidade própria nesta fatia: cada exportação é geração sob demanda, entregue direto na
  resposta ao pedido (FR-024-011). O par de leitura funcional desta decisão é a consulta
  que apura a métrica de §1.3 sobre o evento de etapa (FR-024-010), não uma tela que lista
  PDFs gerados.
- **A-024-009** [assumido] [evidência: crença] O evento de etapa emitido por esta fatia
  (FR-024-010) não tem par de leitura em tela — mesmo padrão já estabelecido por
  F3/SPEC-009 e F5/SPEC-022 (infraestrutura de captura para métrica futura, consumo em
  painel é F10); a apuração por consulta (AC-024-012) é seu par de leitura funcional.
- **A-024-010** [assumido] [evidência: crença] A meta inicial da métrica de §1.3 (ao
  menos 95% de exportações concluídas com sucesso em 30 dias) é estimativa sem medição
  prévia — o pipeline ainda não existe — e vira veredito de métrica no ciclo seguinte
  (decisão 4.99).

## 9. Riscos e questões abertas

- **RISK-024-001** Se, na prática, o texto corrido da Variante "resumo" (A-024-006) e os
  Quadros da Variante "tira" acabarem visualmente/informacionalmente quase idênticos
  (mesmo texto só reorganizado), o piloto do A/B (A-012) pode não isolar a variável de
  apresentação que pretende testar — mesma classe do risco já registrado em E-01/SPEC-011
  (INDEX, Riscos ativos: "risco de o A/B comparar tira × resumo textual quando as duas
  coisas podem ser o mesmo conteúdo empilhado"). Mitigação: A-024-006 declara a
  composição pretendida; a decisão final sobre o que o A/B efetivamente compara cabe ao
  Diretor, junto da resposta a E-01/SPEC-011.
- **RISK-024-002** O motor de PDF concreto escolhido no PLAN pode não sustentar, por
  padrão, a postura "sem rede / sem template executável" (NFR-024-001/002) com o mesmo
  nível de garantia entre bibliotecas candidatas — a escolha da biblioteca não elimina a
  necessidade de prova (gate de segurança), só facilita ou dificulta alcançá-la.
- **RISK-024-003** A geração automática da Tira mnemônica na exportação (FR-024-006) pode
  surpreender um EDITOR que só queria o "resumo" mas selecionou "tira" por engano — nenhuma
  tela de confirmação prévia nesta fatia (mesma economia de fricção já aplicada por F4 em
  `openMnemonicStrip`). Mitigado parcialmente pela correção de FR-024-013 — a auto-geração
  não distorce a métrica de tempo-por-etapa de F3/F10, ainda que possa surpreender o
  EDITOR na UI.
- **RISK-024-004** Sem teto de Quadros por Tira nem limite de tamanho de texto por Quadro
  (RISK-011-007, ainda aberto: "unidade destinada a uma página do PDF de F5/F6"), uma Tira
  com muitos Quadros ou um Conteúdo bruto com texto muito longo pode gerar um PDF de
  leiaute pobre ou de custo de geração alto — revisitável quando o PLAN escolher o motor e
  decidir se introduz algum teto.
- **RISK-024-005** A garantia de falha segura (FR-024-009 — nunca entregar PDF parcial ou
  corrompido) depende do motor escolhido suportar geração atômica da resposta — decisão e
  prova técnica ficam com o PLAN; esta SPEC só declara o comportamento observável exigido.
- **RISK-024-006** A escolha do motor de PDF no PLAN fixa, na prática, o padrão visual de
  todas as 10 camadas do método (nomeado como "irreversível na prática" pelo próprio
  épico, BRIEF-2026-08-27, Riscos por fatia F6); a DEC do PLAN que escolhe o motor deve
  apresentar essa consequência entre as alternativas avaliadas, não só a postura de
  segurança.
- **RISK-024-007** Herdado de RISK-022-003 (SPEC-022): o teto de 5 MB e a resolução da
  imagem armazenada por F5 podem não ser suficientes para impressão de qualidade a partir
  do PDF desta fatia (NFR-024-004 proíbe reprocessamento nesta fatia). `Reabrir se:` uma
  verificação real de impressão de um rascunho mostrar resolução insuficiente — reabre o
  teto de tamanho e a decisão de armazenamento de F5 (A-022-003/A-022-005), não esta SPEC.
- **Q-024-001** O teto de tamanho de TEXTO por Quadro (quanto texto cabe num Quadro antes
  de estourar a página) não é decidido nesta SPEC — fica para o PLAN avaliar junto da
  escolha do motor de geração; a regra "1 Quadro = 1 página" (herdada de RISK-011-007) já
  é desta SPEC (FR-024-016), não sobra mais ao PLAN. Esta definição de página NÃO fecha o
  denominador de "página" da régua de tempo-por-página de F10 — F10 decide isso
  separadamente.

**Nota**: a decisão de NÃO emitir o evento de abertura de etapa na auto-geração via
exportação (FR-024-013) foi aplicada como DEFAULT do `po` (escalação E-024-01,
proposta+default) — segue como decisão de trabalho até o Diretor confirmar ou pedir o
comportamento alternativo (emitir abertura na auto-geração) na Entrega desta fatia.

## 10. Fora deste documento

Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e
`/keelson:tasks`.
