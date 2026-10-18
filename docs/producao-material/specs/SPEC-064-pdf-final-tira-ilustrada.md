# SPEC-064: PDF final da tira ilustrada

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.2
**Autor**: keelson (scribe)
**Data**: 2026-10-18
**Jira**: KAN-237
**Brief**: BRIEF-064

## 1. Contexto e objetivo

### 1.1 Problema

O PDF que o sistema exporta hoje (SPEC-024) é um rascunho interno: estampa em toda página
o cabeçalho "RASCUNHO / Variante / Gerado em / Sem versão fechada", traz só o texto do
Quadro (a Associação visual não aparece em formato WEBP e falhas de imagem só vão para o
log), e é descartado depois do download. Produtos exportou a tira e recebeu esse arquivo:
"Não é isso que eu quero. Quero meus arquivos em PDF com as tiras ilustradas com o conteúdo
das provas." Falta o material de venda: a tira ilustrada, limpa, diagramada como material
de estudo, restrita a conteúdo com Versão aprovada e guardada para compor um pacote
futuro. Além disso, o caminho para ilustrar a tira (levar a Biblioteca visual ao Quadro)
não é descobrível: o seletor de associação visual vazio é um beco sem saída.

### 1.2 Outcome esperado

Um EDITOR ou ADMIN gera, para um Conteúdo bruto com Versão aprovada e válida, um **PDF
final** da Variante "tira": sem marcas internas, com capa, um Quadro por página com a
ilustração em destaque, numeração de página e fonte que cobre o português completo, e
rodapé "Versão N — legislação verificada até DD/MM/AAAA". O sistema avisa quando um Quadro
sai sem imagem. O EDITOR **publica** esse PDF: ele fica guardado, imutável por Versão
aprovada, com histórico e download byte a byte idêntico. O PDF de **rascunho continua
exatamente como é hoje**. O caminho para ilustrar a tira passa a ser descobrível.

### 1.3 Métrica de sucesso

Produtos publica ao menos 1 PDF final com 100% dos Quadros ilustrados (N=M) e amostra
impressa aprovada por Produtos (critério externo, A-064-004), em até 14 dias contados da
primeira Versão aprovada válida possível em produção (2 ADMINs reais, RISK-064-006); sem
essa condição, a medição é inconclusiva, não falha. Todos os PDFs finais publicados nesse
período saem sem nenhuma marca de rascunho.

**Fonte de medição**: instrumentação — consulta aos registros de publicação do PDF final
(NFR-064-002: quem, quando, qual versão, N e M); a aprovação da amostra impressa é externa —
dono do número: Produtos.

## 2. Personas e jobs-to-be-done

- **EDITOR**: "quando um conteúdo tem versão aprovada, quero gerar e guardar o PDF final da
  tira ilustrada, para que Produtos tenha o material de venda sem retrabalho".
- **ADMIN**: mesmos direitos de exportar e publicar; é quem aprova a versão (SPEC-032).
- **Produtos** (consumidor do material, fora do sistema): recebe o PDF final e avalia a
  amostra impressa.
- **Anti-persona**: STUDENT e visitante sem sessão — não exportam nem baixam PDF final.

## 3. Glossário (Ubiquitous Language)

Reutilizados do INDEX: Conteúdo bruto, Quebra da regra, Tira mnemônica, Quadro, Associação
visual, Biblioteca visual, Variante do PDF, Exportação, Versão editorial, Versão aprovada,
Fechamento legislativo, Papel.

| Termo | Definição | Origem |
|-------|-----------|--------|
| Modo de exportação | Escolha, no pedido de Exportação, entre "rascunho" (comportamento da SPEC-024, inalterado) e "final" (esta SPEC) | BRIEF-064 / KAN-244 |
| PDF final | Documento da Variante "tira" gerado no modo final: sem marcas internas, diagramado como material de estudo, com rodapé de versão | BRIEF-064 |
| Versão aprovada e válida | Versão editorial de maior número do Conteúdo bruto com aprovação registrada e sem alteração depois do fechamento — regra já existente (SPEC-028/SPEC-032), não redefinida aqui | SPEC-032 |
| Publicar (PDF final) | Ato do EDITOR/ADMIN que grava o PDF final ligado ao Conteúdo bruto e à Versão aprovada, de forma imutável | KAN-246 |
| PDF publicado | O arquivo gravado pela publicação; cada publicação grava um registro novo e imutável, nunca sobrescrito, mesmo da mesma Versão; os anteriores permanecem no histórico | KAN-246 |
| PDF publicado atual | O registro mais recente (maior data de publicação) entre os PDFs publicados do Conteúdo bruto; marcado "atual" na lista; âncora para KAN-236 | BRIEF-064 |
| Histórico de PDFs publicados | Lista, por Conteúdo bruto, de todos os PDFs publicados, cada um com versão, data e autor da publicação | KAN-246 |
| Capa | Primeira página do PDF final, com a Disciplina, o Tópico, a Versão e a data de fechamento legislativo (sem campo novo) | KAN-245 |
| Aviso de exportação | Mensagem visível ao usuário, ao fim da exportação final, listando Quadros por categoria: "sem imagem", "imagem que não entrou" e (informativa) "imagem abaixo da resolução recomendada" | KAN-245 |
| Resolução recomendada | Valor único, fixado pelo product-designer junto com o layout (caixa de imagem a 300 dpi), registrado no PLAN/TASK; abaixo dele o upload é aceito, com aviso que o cita | KAN-245 |
| Indicador de cobertura da tira | Texto "N de M quadros com imagem" na tela da Tira mnemônica | KAN-247 |

## 4. Escopo

### 4.1 In-scope

- Modo de exportação "final" para a Variante "tira", recusado pelo sistema sem Versão
  aprovada e válida (FEAT-064-001).
- Emenda por supersessão, só para o modo final (§8, A-064-001): AC-024-005 (rótulo de
  rascunho), FR-024-008 (nome), FR-024-011 (não persistir), NFR-024-004 (com A-064-003),
  FR-032-010/AC-032-009 (marca de alcance) e FR-028-010 (carimbo Versão/Data, substituído por
  rodapé + capa).
- Diagramação da tira ilustrada: capa, Quadros com ilustração em destaque, numeração,
  fonte pt-BR, imagem WEBP no PDF final, aviso de Quadros sem imagem, aviso de resolução no
  upload (FEAT-064-002).
- Publicação do PDF final: gravação imutável a cada publicação (registro novo, mesmo da
  mesma Versão, com confirmação), confirmação com "N de M quadros com imagem", histórico,
  lista por conteúdo com marca "atual" e download byte a byte igual (FEAT-064-003).
- Descobribilidade: atalho de 1 clique do estado vazio do seletor à Biblioteca visual com
  volta, indicador "N de M quadros com imagem" e seção no Guia de uso (FEAT-064-004).

### 4.2 Out-of-scope

- Concurso na capa do PDF final (`Reabrir se:` Produtos reprovar a amostra por falta do
  concurso).
- Montar pacote e exportar para marketplace (KAN-236). Este épico só deixa o PDF publicado
  disponível; nenhum consumidor dele é entregue aqui.
- Storage de objetos externo.
- Editar o PDF dentro do sistema; marca d'água; dados do comprador.
- PDF final da Variante "resumo": o modo final cobre só a "tira" (A-064-002); o "resumo"
  segue só rascunho.
- Alterar o PDF de rascunho: permanece idêntico (SPEC-024 intacta para ele).
- Cadastro de associação visual em painel sobre a tira, sem sair do contexto (entrega mínima:
  atalho de 1 clique e volta).
- Redefinir a regra de aprovação/fechamento de versão (SPEC-028/SPEC-032).
- Acesso do STUDENT ao PDF final, publicado ou não.
- Excluir, despublicar ou substituir um PDF publicado.

## 5. Requisitos funcionais (EARS)

### FEAT-064-001: Exportação em modo final, sem marcas, só com versão aprovada

> O QA exporta o PDF da tira nos dois modos: o rascunho sai como hoje; o final sai limpo
> para conteúdo com versão aprovada e válida e é recusado pelo sistema nos demais casos.

**Jira Story**: KAN-244

- **FR-064-001** [MUST] Quando um EDITOR ou ADMIN aciona a Exportação da Variante "tira" no
  Modo de exportação "final" de um Conteúdo bruto com Versão aprovada e válida, o sistema deve gerar o PDF
  final sem nenhuma marca de rascunho, sem a Variante estampada e sem "Gerado em".
- **FR-064-002** [MUST] Se o Conteúdo bruto não tem Versão aprovada, ou a Versão de maior
  número foi alterada depois do fechamento, então o sistema deve recusar a Exportação no
  modo final no próprio sistema (não apenas na tela), sem gerar arquivo, com mensagem que
  explica o motivo (sem versão aprovada ou alterado após o fechamento).
- **FR-064-003** [MUST] Quando a Exportação é pedida no Modo de exportação "rascunho", o
  sistema deve entregar um rascunho idêntico ao atual (SPEC-024 + carimbo SPEC-028 + marca
  SPEC-032), inclusive o rótulo de rascunho em toda página e o nome de arquivo indicando
  rascunho.
- **FR-064-004** [MUST] O sistema deve estampar no PDF final um rodapé discreto "Versão N —
  legislação verificada até DD/MM/AAAA", com N e a data vindos da Versão aprovada, e deve
  nomear o arquivo final sem a palavra "rascunho".
- **FR-064-005** [MUST] Se a Exportação no modo final é pedida para a Variante "resumo",
  então o sistema deve recusá-la informando que o modo final cobre só a Variante "tira".
- **FR-064-006** [MUST] Quando um EDITOR ou ADMIN aciona a exportação final na interface, a
  tela deve expor os três estados: em andamento (controle desabilitado com indicador),
  sucesso (arquivo disponível para download) e falha (erro visível, incluindo o motivo da
  recusa de FR-064-002, sem perder a seleção feita).
- **FR-064-007** [MUST] Se um usuário sem papel EDITOR ou ADMIN, ou sem sessão válida,
  aciona a Exportação no modo final, então o sistema deve recusar a operação.

### FEAT-064-002: Diagramação da tira ilustrada

> O QA abre o PDF final e confere capa, ilustração em destaque, numeração, acentos e
> aspas, imagens WEBP, e os avisos de Quadro sem imagem e de resolução no upload.

**Jira Story**: KAN-245

- **FR-064-008** [MUST] O sistema deve compor o PDF final com uma Capa que identifica a
  Disciplina, o Tópico, a Versão e a data de fechamento legislativo, sem exigir campo novo
  no Conteúdo bruto.
- **FR-064-009** [MUST] O sistema deve compor cada Quadro do PDF final, na ordem da Tira
  mnemônica, com a Associação visual vinculada em destaque (a imagem é o elemento dominante
  da página) e o texto do Quadro.
- **FR-064-010** [MUST] O sistema deve numerar as páginas do PDF final.
- **FR-064-011** [MUST] O sistema deve compor o PDF final com fonte embutida que cobre o
  português completo — acentos, travessão e aspas curvas — sem falhar nem substituir
  caracteres por símbolos.
- **FR-064-012** [MUST] Quando a Associação visual de um Quadro é uma imagem enviada em
  WEBP, inclusive WEBP já existente no acervo, o sistema deve exibi-la no PDF final: toda
  imagem vinculada aparece (Q-064-001).
- **FR-064-013** [MUST] Quando a Exportação final conclui com Quadros sem Associação visual
  ou com imagem que não pôde entrar no PDF, o sistema deve emitir esses Quadros só com o
  texto, concluir a exportação e exibir ao usuário o Aviso de exportação que lista esses
  Quadros (posição) e distingue "sem imagem" de "imagem que não entrou".
- **FR-064-014** [SHOULD] Quando um EDITOR envia uma imagem para a Biblioteca visual com
  resolução abaixo da Resolução recomendada (valor único fixado com o layout), o sistema
  deve aceitar o envio e exibir um aviso que cita esse valor.
- **FR-064-015** [MUST] Se o envio de imagem é feito sem sessão válida ou por papel sem
  direito de enviar, então o sistema deve manter a recusa existente (SPEC-022), sem que o
  aviso de resolução abra exceção.
- **FR-064-029** [SHOULD] Quando a Exportação final inclui Quadro cuja imagem vinculada está
  abaixo da Resolução recomendada, o sistema deve incluir no Aviso de exportação uma 3ª
  categoria informativa, "imagem abaixo da resolução recomendada" (cobre o acervo antigo),
  sem bloquear a exportação nem a publicação.

### FEAT-064-003: Publicar o PDF final

> O QA publica o PDF final de uma versão aprovada, vê o histórico, baixa o arquivo e
> confirma que é idêntico a cada download; aprova nova versão e confirma que há novo arquivo.

**Jira Story**: KAN-246

- **FR-064-016** [MUST] Quando um EDITOR ou ADMIN aciona "Publicar PDF final" para um
  Conteúdo bruto com Versão aprovada e válida, o sistema deve gerar o PDF final e gravá-lo
  ligado ao Conteúdo bruto e a essa Versão aprovada, registrando quem publicou, quando, e
  N e M do Indicador de cobertura da tira no momento da publicação.
- **FR-064-017** [MUST] Se o Conteúdo bruto não tem Versão aprovada, ou foi alterado depois
  do fechamento, então o sistema deve recusar a publicação no próprio sistema, sem gravar
  arquivo, com mensagem que explica o motivo.
- **FR-064-018** [MUST] O sistema NÃO deve sobrescrever nem alterar um PDF publicado. Quando
  uma publicação é feita (de nova Versão ou da mesma), o sistema deve gravar um registro
  novo e manter os anteriores intactos no histórico (A-064-005).
- **FR-064-019** [MUST] Se já existe PDF publicado para a mesma Versão aprovada do Conteúdo
  bruto, então o sistema deve exigir confirmação explícita antes de nova publicação
  ("esta Versão já tem PDF publicado em <data>; publicar outro?") e, sem confirmação, não
  gravar (A-064-005).
- **FR-064-020** [MUST] O sistema deve oferecer o Histórico de PDFs publicados por Conteúdo
  bruto, cada um com Versão, data de publicação, quem publicou e N de M, do mais recente ao
  mais antigo, marcando como "atual" o PDF publicado atual (registro mais recente).
- **FR-064-021** [MUST] Quando um EDITOR ou ADMIN baixa um PDF publicado, o sistema deve
  entregar o arquivo gravado, byte a byte idêntico em todo download, sem regerar o
  documento.
- **FR-064-022** [MUST] Quando um EDITOR ou ADMIN aciona "Publicar PDF final" ou o download
  de um PDF publicado na interface, a tela deve expor os três estados de cada ação: em
  andamento (controle desabilitado com indicador), sucesso (PDF aparece no histórico /
  arquivo baixado) e falha (erro visível com o motivo).
- **FR-064-023** [MUST] Se um usuário sem papel EDITOR ou ADMIN, ou sem sessão válida,
  tenta publicar, listar ou baixar um PDF publicado, então o sistema deve recusar a
  operação.
- **FR-064-024** [MUST] Se a geração ou a gravação do PDF final falha na publicação, então
  o sistema deve descartar qualquer resultado parcial, não deixar PDF publicado incompleto
  no histórico e informar a falha ao usuário.
- **FR-064-030** [MUST] Quando um EDITOR ou ADMIN aciona "Publicar PDF final", o sistema
  deve mostrar, antes de gravar, "N de M quadros com imagem" e a lista do Aviso de
  exportação; se N < M, então deve exigir confirmação explícita para gravar, e cancelar
  não grava nada.
- **FR-064-031** [MUST] Quando duas publicações do mesmo Conteúdo bruto ocorrem ao mesmo
  tempo, o sistema deve produzir, para cada uma, um registro completo e baixável, ou recusar
  uma delas com motivo, nunca deixando registro parcial, corrompido ou erro genérico.
- **FR-064-032** [MUST] Quando um EDITOR ou ADMIN publica, lista ou baixa PDF final, o
  sistema deve aplicar o alcance da exportação atual (AC-024-018, comum a EDITOR e ADMIN,
  sem restrição por autoria).
- **FR-064-033** [MUST] Se o Conteúdo bruto foi removido, então o sistema deve responder
  não-encontrado (AC-024-019) para publicar, listar e baixar, e os PDFs já publicados devem
  permanecer gravados (NFR-064-003).

### FEAT-064-004: Descobrir o caminho para ilustrar a tira

> O QA, na tela da tira, vê quantos Quadros têm imagem, chega à Biblioteca visual em 1 clique
> a partir do seletor vazio, volta ao Quadro e encontra a explicação no Guia de uso.

**Jira Story**: KAN-247

- **FR-064-025** [MUST] Enquanto a Biblioteca visual está vazia, o estado vazio do seletor
  "Vincular associação visual" deve oferecer um link que leva à Biblioteca visual em 1
  clique.
- **FR-064-026** [SHOULD] Quando o EDITOR chega à Biblioteca visual por esse link, o sistema
  deve oferecer um caminho de volta ao Quadro/tira de origem.
- **FR-064-027** [MUST] Enquanto o EDITOR está na tela da Tira mnemônica, o sistema deve
  exibir o Indicador de cobertura da tira "N de M quadros com imagem", atualizado quando um
  vínculo é criado ou removido.
- **FR-064-028** [MUST] O Guia de uso (`docs/GUIA-DE-USO.md`) deve conter a seção "Como
  ilustrar uma tira e gerar o PDF", cobrindo ilustrar, exportar rascunho e final e
  publicar, distinguindo os modos (no rascunho a imagem WEBP segue sem aparecer; no final
  aparece), citando a Resolução recomendada e atualizando a data de "Última atualização".

## 6. Requisitos não-funcionais

- **NFR-064-001** [MUST] A recusa por falta de Versão aprovada e válida DEVE ser imposta
  pelo sistema para o modo final e para a publicação, independentemente da tela
  (deny-by-default, SPEC-002; a tela apenas espelha).
- **NFR-064-002** [MUST] A publicação DEVE registrar quem publicou, quando, qual Versão
  aprovada e N e M (quadros com imagem / total), de forma consultável (par de leitura em
  FR-064-020).
- **NFR-064-003** [MUST] O PDF publicado DEVE ser imutável: nenhum fluxo do sistema o
  altera ou remove depois de gravado (integridade verificável por AC-064-013).
- **NFR-064-004** [MUST] A geração do PDF final DEVE manter as garantias de NFR-024-001 (sem
  conexão de rede a partir de conteúdo do usuário) e NFR-024-002 (texto do usuário tratado
  como dado), e a falha segura de FR-024-009/FR-024-015.
- **NFR-064-005** [SHOULD] O PDF final DEVE ser legível em impressão (imagens usadas sem
  perda adicional além da conversão estritamente necessária de WEBP, A-064-003).

## 7. Critérios de aceitação (Given-When-Then)

- **AC-064-001** (cobre FR-064-001, FR-064-004)
  Dado um Conteúdo bruto com Versão aprovada e válida, quando o EDITOR exporta a tira no
  modo final, então o PDF não contém "RASCUNHO", "Variante" nem "Gerado em", exibe o
  rodapé "Versão N — legislação verificada até DD/MM/AAAA" e o arquivo baixado não tem
  "rascunho" no nome.

- **AC-064-002** (cobre FR-064-002)
  Dado um Conteúdo bruto sem Versão aprovada, ou alterado depois do fechamento, quando o
  EDITOR (ou uma chamada direta ao sistema, sem passar pela tela) pede a exportação final,
  então o sistema recusa, não gera arquivo e informa o motivo.

- **AC-064-003** (cobre FR-064-003)
  Dado qualquer Conteúdo bruto exportável, quando o EDITOR exporta no Modo de exportação
  rascunho, então o PDF é idêntico ao atual (SPEC-024 + carimbo SPEC-028 + marca SPEC-032),
  com o nome do arquivo e o rótulo de rascunho em toda página; e, dado um conteúdo sem
  aprovação, o rascunho mostra RASCUNHO; dado um conteúdo aprovado, mostra a marca
  "Conteúdo normativo e Tira mnemônica — Versão N aprovada".

- **AC-064-004** (cobre FR-064-005)
  Dado um Conteúdo bruto com Versão aprovada e válida, quando o EDITOR pede o modo final na
  Variante "resumo", então o sistema recusa e informa que o modo final cobre só a "tira".

- **AC-064-005** (cobre FR-064-006)
  Dado o EDITOR na interface, quando aciona a exportação final, então o controle fica
  desabilitado com indicador enquanto gera, o arquivo fica disponível ao concluir e, na
  falha ou recusa, o erro com o motivo aparece sem perder a seleção.

- **AC-064-006** (cobre FR-064-007)
  Dado um usuário STUDENT, ou uma requisição sem sessão válida, quando tenta exportar no
  modo final, então o sistema recusa a operação.

- **AC-064-007** (cobre FR-064-008, FR-064-010)
  Dado um PDF final, quando é aberto, então a primeira página é a capa com o Conteúdo, a
  prova e a Versão, e as páginas são numeradas.

- **AC-064-008** (cobre FR-064-009, NFR-064-005)
  Dado uma Tira com Quadros ilustrados, quando o PDF final é aberto, então cada Quadro
  aparece na ordem da Tira, com a imagem em destaque e o texto do Quadro.

- **AC-064-009** (cobre FR-064-011)
  Dado um Quadro cujo texto contém acentos, travessão e aspas curvas, quando o PDF final é
  gerado, então a geração conclui e o texto aparece íntegro no documento.

- **AC-064-010** (cobre FR-064-012)
  Dado um Quadro vinculado a uma imagem WEBP (nova ou já existente no acervo), quando o PDF final é gerado, então
  a imagem aparece na página do Quadro.

- **AC-064-011** (cobre FR-064-013)
  Dado uma Tira com um Quadro sem imagem e outro com imagem indecodificável, quando a
  exportação final conclui, então o PDF sai com esses Quadros só com texto e a tela exibe
  um aviso listando a posição de cada um, distinguindo "sem imagem" de "imagem que não
  entrou".

- **AC-064-012** (cobre FR-064-014, FR-064-015)
  Dado o envio de uma imagem abaixo da Resolução recomendada, quando o EDITOR conclui o
  envio, então a imagem é aceita e um aviso cita o valor único da Resolução recomendada
  (registrado no PLAN/TASK); e, dado um
  envio sem sessão válida ou por papel sem direito, quando é tentado, então continua
  recusado.

- **AC-064-013** (cobre FR-064-016, FR-064-021, NFR-064-002, NFR-064-003)
  Dado um Conteúdo bruto com Versão aprovada e válida, quando o EDITOR publica o PDF final
  e depois o baixa duas vezes, então o PDF fica no Histórico de PDFs publicados com Versão,
  data, autor, N e M, e os dois arquivos baixados são byte a byte idênticos ao gravado.

- **AC-064-014** (cobre FR-064-017)
  Dado um Conteúdo bruto sem Versão aprovada, ou alterado depois do fechamento, quando o
  EDITOR (ou chamada direta ao sistema) tenta publicar, então o sistema recusa, não grava
  arquivo e informa o motivo.

- **AC-064-015** (cobre FR-064-018, FR-064-019)
  Dado um Conteúdo com PDF publicado da Versão 1, quando a Versão 2 é aprovada e publicada,
  então existem dois PDFs no histórico e o da Versão 1 permanece inalterado; e, quando se
  publica de novo a mesma Versão, então o sistema pede confirmação ("esta Versão já tem PDF
  publicado em <data>; publicar outro?"), sem confirmação não grava, e com confirmação
  existem dois registros da mesma Versão, ambos baixáveis byte a byte, o mais recente
  marcado "atual".

- **AC-064-016** (cobre FR-064-020)
  Dado um Conteúdo bruto com PDFs publicados, quando o EDITOR abre a lista, então vê cada
  PDF com Versão, data e quem publicou, do mais recente ao mais antigo.

- **AC-064-017** (cobre FR-064-022)
  Dado o EDITOR na interface, quando publica ou baixa um PDF publicado, então cada ação
  mostra em andamento (controle desabilitado com indicador), sucesso e falha com o motivo.

- **AC-064-018** (cobre FR-064-023)
  Dado um usuário STUDENT, ou uma requisição sem sessão válida, quando tenta publicar,
  listar ou baixar um PDF publicado, então o sistema recusa a operação.

- **AC-064-019** (cobre FR-064-024)
  Dado uma falha na geração ou na gravação durante a publicação, quando ela ocorre, então o
  histórico não ganha nenhum PDF incompleto e a tela informa a falha.

- **AC-064-020** (cobre FR-064-025, FR-064-026)
  Dado a Biblioteca visual vazia, quando o EDITOR abre o seletor "Vincular associação
  visual" num Quadro, então vê um link que leva à Biblioteca visual em 1 clique e, lá,
  consegue voltar ao Quadro/tira de origem.

- **AC-064-021** (cobre FR-064-027)
  Dado uma Tira de M Quadros com N vinculados, quando o EDITOR abre a tela da tira, então
  vê "N de M quadros com imagem", e o valor muda ao vincular ou desvincular uma imagem.

- **AC-064-022** (cobre FR-064-028)
  Dado a entrega concluída, quando se lê `docs/GUIA-DE-USO.md`, então existe a seção "Como
  ilustrar uma tira e gerar o PDF", que distingue os modos (WEBP sem aparecer no rascunho,
  aparecendo no final), e a data de "Última atualização" foi atualizada.

- **AC-064-023** (cobre NFR-064-001)
  Dado uma chamada direta ao sistema (sem a tela) para exportação final ou publicação de
  conteúdo sem Versão aprovada e válida, quando é feita por EDITOR ou ADMIN, então é
  recusada igual à da tela.

- **AC-064-024** (cobre NFR-064-004)
  Dado um Conteúdo cujo texto de Quadro parece marcação ou template, quando o PDF final é
  gerado, então o texto aparece literalmente, sem conexão de rede aberta a partir dele.

- **AC-064-025** (cobre FR-064-029)
  Dado uma Tira com um Quadro cuja imagem está abaixo da Resolução recomendada, quando a
  exportação final conclui, então o Aviso de exportação lista esse Quadro na categoria
  informativa "imagem abaixo da resolução recomendada" e a exportação e a publicação não são
  bloqueadas.

- **AC-064-026** (cobre FR-064-030)
  Dado uma Tira com N < M, quando o EDITOR aciona "Publicar PDF final", então a tela mostra
  "N de M quadros com imagem" e a lista do aviso antes de gravar, exige confirmação
  explícita, e ao cancelar nada é gravado.

- **AC-064-027** (cobre FR-064-031)
  Dado duas publicações simultâneas do mesmo Conteúdo bruto, quando ambas concluem, então
  cada uma produziu um registro completo e baixável byte a byte, ou uma foi recusada com
  motivo; nunca há registro parcial, corrompido ou erro genérico.

- **AC-064-028** (cobre FR-064-032)
  Dado um Conteúdo bruto criado por outro usuário, quando um EDITOR ou ADMIN publica, lista
  ou baixa o PDF final, então a operação é permitida, igual ao alcance da exportação atual
  (AC-024-018), sem restrição por autoria.

- **AC-064-029** (cobre FR-064-033, NFR-064-003)
  Dado um Conteúdo bruto removido, quando se tenta publicar, listar ou baixar PDF final,
  então o sistema responde não-encontrado (AC-024-019) e os registros já publicados
  permanecem gravados.

## 8. Premissas e decisões prévias

- **A-064-001** [assumido] [evidência: entrevistas] **Emenda por supersessão, só no modo
  final** (decidido pelo Diretor no BRIEF-064). SPEC-024, SPEC-028 e SPEC-032 permanecem
  intactas para o rascunho. No modo final são supersedidos: AC-024-005 (rótulo de rascunho
  em toda página, "Gerado em"), por FR-064-001/FR-064-004; FR-024-008 (nome com "rascunho"),
  por FR-064-004; FR-024-011 (não persistir), pois o PDF final publicado persiste
  (FEAT-064-003); NFR-024-004 (não recodificar imagem), com A-064-003 (no modo final o
  requisito funcional é FR-064-012); FR-032-010/AC-032-009 (marca de alcance); e FR-028-010
  (carimbo Versão/Data), substituído por rodapé + capa. FR-024-005/FR-024-014 (Quadro sem
  imagem/imagem que falha) seguem valendo, agora com aviso visível (FR-064-013).
- **A-064-002** [assumido] [evidência: crença] O modo final cobre só a Variante "tira" (o
  pedido é a tira ilustrada); a "resumo" segue só rascunho. Risco: Produtos querer o
  resumo final.
- **A-064-003** [assumido] [evidência: crença] Conversão de WEBP na geração, se o PLAN a
  escolher, é aceitável como exceção ao NFR-024-004 só no modo final; o PLAN registra a
  decisão e o impacto em qualidade.
- **A-064-004** [assumido] [evidência: entrevistas] O layout (capa, Quadro com ilustração em
  destaque, numeração, fonte) é proposto pelo time (decidido pelo Diretor no BRIEF-064),
  sem referência de Produtos, revisado pelo gate de design. A amostra impressa aprovada por Produtos é critério externo,
  pendência de Produtos, não verificável por AC automatizado.
- **A-064-005** [assumido] [evidência: crença] Cada publicação grava um registro novo e
  imutável, mesmo da mesma Versão aprovada; os anteriores ficam intactos. Republicar exige
  confirmação (FR-064-019). "PDF publicado atual" é o registro mais recente (maior data); a
  lista o marca "atual" (âncora para KAN-236). `Reabrir se:` Produtos exigir um único PDF
  por Versão.
- **A-064-006** [assumido] [evidência: entrevistas] (decidido pelo Diretor no BRIEF-064) "Versão aprovada e válida" é a regra
  existente (Versão de maior número com aprovação, sem alteração após o fechamento); nenhuma
  regra nova de aprovação é criada. O PDF final é gerado a partir da versão vigente no
  momento do pedido.
- **A-064-007** [assumido] [evidência: entrevistas] (decidido pelo Diretor no BRIEF-064) Papéis: os mesmos da exportação atual,
  EDITOR e ADMIN (NFR-024-003).
- **A-064-008** [assumido] [evidência: entrevistas] (decidido pelo Diretor no BRIEF-064) O
  PDF publicado fica no mesmo banco de dados, como bytes; migração só aditiva (tabela nova),
  autorizada pelo Diretor.
- **A-064-009** [assumido] [evidência: entrevistas] (decidido pelo Diretor no BRIEF-064) A
  imagem não faz parte da Versão aprovada (SPEC-032/RISK-032-002; no código, o vínculo emite
  só ASSOCIACAO_VISUAL em tira.service.ts e o sinal de alteração lê só TIRA_MNEMONICA em
  content-versions.service.ts). Exportar e publicar usam a imagem vinculada no momento; a
  publicação congela os bytes (FR-064-021). `Reabrir se:` Produtos exigir imagem dentro da
  aprovação.
- **A-064-010** [assumido] [evidência: entrevistas] (decidido pelo Diretor no BRIEF-064) Um
  PDF por Conteúdo bruto. `Reabrir se:` Produtos pedir PDF que agregue vários Conteúdos
  (composição de Pacote, KAN-236).

## 9. Riscos e questões abertas

- **RISK-064-001** Sem referência visual de Produtos, o layout pode ser rejeitado na
  amostra impressa (A-064-004). `Reabrir se:` Produtos reprovar a amostra.
- **RISK-064-002** Herdado de RISK-024-004: sem teto de Quadros por Tira, a geração do PDF
  final (mais pesada, com imagem) pode estourar o teto de duração e falhar.
  `Reabrir se:` publicação falhar por tempo em tira real.
- **RISK-064-003** Herdado de RISK-024-007 / RISK-022-003: o limite de 5 MB e a resolução
  das imagens enviadas determinam a qualidade de impressão; o aviso de resolução (FR-064-014)
  informa, não impede. `Reabrir se:` Produtos recusar imagens de baixa resolução.
- **RISK-064-004** O PDF publicado no banco aumenta o armazenamento a cada versão aprovada.
  `Reabrir se:` o volume de PDFs publicados pressionar o banco (storage externo, fora de
  escopo).
- **RISK-064-006** Herdado de RISK-032-001 / RISK-048-009 / RISK-032-006: a aprovação exige
  2 ADMINs reais; sem isso não há Versão aprovada válida e a métrica §1.3 é inconclusiva,
  não falha. O gate 9 usa conta descartável. `Reabrir se:` a produção seguir sem 2 ADMINs
  reais ao fim dos 14 dias.
- **Q-064-001** Como o PLAN cumpre a FR-064-012: toda imagem vinculada, inclusive WEBP já
  existente no acervo, aparece no PDF final; recusar WEBP novo no upload só basta sozinho se
  o PLAN medir zero WEBP no acervo (A-064-003).
- **Q-064-002** O conserto do RISK-032-006 entra neste épico? Default: fora, em brief
  separado; dependência declarada (RISK-064-006). Escalação E-1 do PO.

## 10. Fora deste documento
Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
