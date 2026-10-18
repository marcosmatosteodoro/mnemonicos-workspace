# SPEC-061: Pacotes de PDF para marketplace

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.3
**Autor**: scribe (sob o Tech Lead)
**Data**: 2026-10-18
**Jira**: KAN-236
**Brief**: BRIEF-061

## 1. Contexto e objetivo
### 1.1 Problema
Produtos quer vender pacotes de PDFs das tiras ilustradas, mas a venda acontece num marketplace externo (decisão do Diretor), que já cuida de pagamento, nota, reembolso e entrega ao comprador. Hoje o sistema não guarda PDFs diagramados fora dele nem permite agrupá-los em um produto para subir no marketplace: Produtos monta o pacote à mão, fora do sistema, sem registro de qual versão de cada PDF foi exportada nem de quando.

### 1.2 Outcome esperado
Dentro do sistema, Produtos (1) mantém um acervo de PDFs prontos, cada um com Título, Versão e Data de fechamento legislativo declarados; (2) monta Pacotes escolhendo PDFs do acervo, em ordem definida por ele; e (3) exporta o Pacote num arquivo único compactado só com os PDFs, pronto para subir no Marketplace, e baixa à parte a Ficha do pacote (texto, com o tamanho total) para o cadastro do produto. Cada exportação fica registrada com a composição congelada naquele momento. O sistema continua uma fábrica interna: não cobra, não tem comprador e o aluno não entra nele.

### 1.3 Métrica de sucesso
Produtos monta e exporta ao menos 1 Pacote sem sair do sistema em até 30 dias após o deploy.
**Fonte de medição**: instrumentação — registro de exportações de Pacote (cada exportação registra quem e quando; a consulta é a contagem de registros após a data do deploy).

## 2. Personas e jobs-to-be-done
- **Produtos** (equipe interna que já produz material, com papel EDITOR ou ADMIN): "quando termino de diagramar PDFs fora do sistema, quero guardá-los num acervo, agrupá-los em um pacote com nome, descrição e preço de referência e levar tudo num arquivo só ao marketplace, sabendo qual versão de cada PDF foi exportada."
- **Anti-persona**: o aluno/comprador. Ele compra e recebe no marketplace e não tem acesso ao sistema; o papel STUDENT segue sem acesso a estas funções.

## 3. Glossário (Ubiquitous Language)
| Termo | Definição |
|-------|-----------|
| Produtos | Equipe interna que monta material para venda; no sistema não é papel novo: usa os papéis EDITOR e ADMIN existentes |
| PDF do acervo | PDF pronto, diagramado fora do sistema, enviado por Produtos e guardado com seus metadados |
| Acervo de PDFs | Conjunto dos PDFs do acervo |
| Título (do PDF) | Nome de exibição do PDF do acervo (obrigatório) |
| Versão (do PDF enviado) | Texto curto informado à mão por Produtos (ex.: "v1"); não vem do carimbo do sistema — distinta da Versão editorial do Conteúdo bruto (SPEC-028) |
| Data de fechamento legislativo | Data até a qual a legislação refletida no PDF foi considerada (mesmo termo do INDEX); aqui informada à mão por Produtos, declarada e não verificada pelo sistema; distinta do ato "Fechar uma Versão" (SPEC-028). Rótulo na interface e na Ficha: "Data de fechamento legislativo (declarada)" |
| Prova/concurso | Texto livre opcional que indica a prova ou concurso a que o PDF ou o Pacote se destina; não há cadastro de prova |
| Disciplina | Disciplina do cadastro existente, opcional |
| Substituição | Troca do arquivo de um PDF do acervo mantendo o registro; o arquivo anterior deixa de estar disponível |
| Pacote | Produto montado por Produtos: nome, descrição, preço de referência, prova/concurso, disciplina e uma lista ordenada de PDFs do acervo |
| Item (do Pacote) | Referência a um PDF do acervo dentro de um Pacote, com posição |
| Preço de referência | Valor em reais, informativo, para Produtos cadastrar no marketplace; o sistema não cobra |
| Exportação de Pacote | Geração de um arquivo único compactado só com os PDFs do Pacote na ordem, cada um com nome prefixado pela posição; não contém Ficha nem preço; distinta da Exportação de PDF da Tira (SPEC-024) |
| Ficha do pacote | Documento em texto, fora do arquivo compactado, exibido na tela do Pacote e baixável à parte: nome, descrição, preço de referência, prova/concurso, disciplina, tamanho total do Pacote e a lista dos PDFs com Versão e Data de fechamento legislativo (declarada) |
| Tamanho total do Pacote | Soma dos tamanhos dos arquivos dos Itens do Pacote; exibido na tela do Pacote e na Ficha |
| Registro de exportação | Registro de cada Exportação de Pacote: quem, quando e a composição congelada naquele momento (nome do Pacote e, por Item, posição, Título, Versão, Data de fechamento legislativo declarada, tamanho e digest) |
| Digest | Identificador de integridade do arquivo que entrou no arquivo compactado, usado para identificar exatamente o que foi exportado |
| Marketplace | Plataforma externa de venda (ex.: Hotmart, Kiwify, Eduzz) onde Produtos sobe o arquivo exportado à mão |
| Tira | Tira mnemônica (INDEX); os PDFs do acervo costumam ser tiras ilustradas diagramadas fora do sistema |

## 4. Escopo
### 4.1 In-scope
- Acervo de PDFs: enviar, listar, baixar, editar metadados, substituir o arquivo e remover (EDITOR e ADMIN; substituir e remover só pelo autor do registro ou ADMIN), com estados vazios e aviso de que o sistema não atesta revisão jurídica.
- Validação do PDF pelo conteúdo e limite de tamanho por arquivo.
- Pacotes: cadastrar, editar, remover; escolher PDFs do acervo como itens, adicionar, remover e reordenar.
- Exportação do Pacote em arquivo único compactado só com os PDFs; Ficha do pacote na tela e baixável à parte, com o tamanho total do Pacote; registro de cada exportação (quem, quando, composição congelada), com a última exportação e sua composição visíveis.
- Acesso restrito à equipe interna autenticada, com endereço de download de curta duração.
- Atualização do Guia de uso na entrega.

### 4.2 Out-of-scope
- Checkout, pagamento e pedido (KAN-242) e área do aluno/login de aluno (KAN-243): substituídos pelo marketplace; o sistema não tem comprador e o papel STUDENT segue dormente. (Vizinho de "Preço de referência" e do "Pacote".)
- Integração por API com o marketplace (publicar o produto, receber venda por webhook): a exportação é um arquivo que Produtos sobe à mão. (Vizinho da Exportação de Pacote.)
- PDF gerado pelo sistema como Item do Pacote (KAN-237/KAN-246): fatia posterior. (Vizinho do Acervo de PDFs.)
- Histórico de versões anteriores do arquivo substituído: só o arquivo atual fica disponível. (Vizinho da Substituição.)
- Aprovação jurídica do PDF enviado pelo sistema (ver A-061-001). (Vizinho da Versão informada à mão.)
- Marca d'água com dados do comprador e proteção contra compartilhamento: o sistema não conhece o comprador. (Vizinho do download.)
- Edição do PDF dentro do sistema. (Vizinho do "editar metadados".)
- Pré-visualização do PDF no navegador: o PDF é baixado, não visualizado na tela. (Vizinho da lista do Acervo.)
- Status de publicação do Pacote (rascunho/publicado): o sistema não sabe se o produto está à venda. (Vizinho do Pacote e da última exportação.)
- Envio de vários arquivos de uma vez: um arquivo por envio. (Vizinho do envio.)
- Papel novo "Produtos": usa EDITOR e ADMIN. (Vizinho do controle de acesso.)
- Guardar ou re-baixar o arquivo compactado de exportações anteriores: só o registro de exportação com a composição congelada fica; o arquivo não. (Vizinho da Exportação de Pacote.)
- Validação do limite de arquivo de cada Marketplace: Produtos confere pelo tamanho total exibido; o sistema não conhece esses limites. (Vizinho do tamanho total do Pacote.)

## 5. Requisitos funcionais (EARS)

### FEAT-061-001: Acervo de PDFs prontos
> Produtos envia um PDF pronto com seus metadados, vê o PDF na lista do acervo, baixa, edita os metadados, substitui o arquivo e remove; arquivos que não são PDF ou acima do limite são recusados e quem não é EDITOR/ADMIN não acessa nada.

**Jira**: KAN-241

- **FR-061-001** [MUST] Quando um usuário com papel EDITOR ou ADMIN envia um PDF informando Título, Versão e Data de fechamento legislativo (obrigatórios), e opcionalmente Prova/concurso (texto livre) e Disciplina (do cadastro existente), o sistema deve guardar o PDF no Acervo de PDFs registrando o autor e a data do envio.
- **FR-061-002** [MUST] Se o arquivo enviado não tiver o conteúdo de um PDF válido (verificação pela assinatura de PDF no conteúdo, nunca pela extensão ou pelo tipo declarado), então o sistema deve recusar o envio ou a substituição com mensagem clara, mesmo que o arquivo tenha extensão .pdf.
- **FR-061-003** [MUST] Se o arquivo enviado exceder o tamanho máximo por arquivo (50 MB, configurável), então o sistema deve recusar o envio ou a substituição com mensagem clara que informe o limite.
- **FR-061-004** [MUST] Se o envio faltar Título, Versão ou Data de fechamento legislativo, então o sistema deve recusar o envio indicando os campos obrigatórios ausentes.
- **FR-061-005** [MUST] Quando o usuário abre o Acervo de PDFs, o sistema deve listar os PDFs com título, versão, data de fechamento legislativo, tamanho, autor do envio, data do envio e, se houver, autor e data da última substituição.
- **FR-061-006** [MUST] Quando o usuário aciona o download de um PDF do acervo, o sistema deve entregar o arquivo atual.
- **FR-061-007** [MUST] Quando o usuário edita os metadados de um PDF (Título, Versão, Data de fechamento legislativo, Prova/concurso, Disciplina) e salva, o sistema deve gravar as alterações e exibi-las na lista do acervo, sem alterar o arquivo.
- **FR-061-008** [MUST] Quando o usuário substitui o arquivo de um PDF do Acervo de PDFs por outro PDF válido, o sistema deve exibir Versão e Data de fechamento legislativo atuais, editáveis na mesma ação, e pedir confirmação de que o arquivo anterior deixa de existir; confirmada, deve manter o registro, tornar o novo arquivo o atual, deixar de disponibilizar o anterior e registrar autor e data da substituição, exibidos na lista.
- **FR-061-009** [MUST] Quando o usuário remove um PDF do acervo que não pertence a nenhum Pacote, o sistema deve remover o registro e o arquivo.
- **FR-061-010** [MUST] Se o usuário tenta remover um PDF que pertence a um ou mais Pacotes, então o sistema deve recusar a remoção com mensagem que nomeie os Pacotes que o contêm; o mesmo vale se remoção e inclusão em Pacote chegam ao mesmo tempo, e o PDF nunca é removido enquanto pertence a um Pacote.
- **FR-061-011** [MUST] Se o solicitante é um usuário com papel STUDENT ou um visitante sem sessão, então o sistema deve recusar qualquer ação do acervo (listar, enviar, baixar, editar, substituir, remover) e não deve expor nenhum PDF.
- **FR-061-012** [MUST] Quando o usuário envia, substitui ou remove um PDF, o sistema deve mostrar os três estados da ação: em andamento (a ação é desabilitada contra repetição e há indicador de progresso até o resultado), sucesso (confirmação e lista atualizada) e falha (mensagem de erro clara, sem perder o que o usuário preencheu).
- **FR-061-023** [MUST] Se um EDITOR que não é o autor do registro tenta substituir o arquivo ou remover um PDF do Acervo de PDFs, então o sistema deve recusar com mensagem clara e manter o arquivo intacto; ADMIN e o autor podem, e listar, baixar e editar metadados seguem permitidos a qualquer EDITOR ou ADMIN.
- **FR-061-024** [SHOULD] Quando o Acervo de PDFs não tem nenhum PDF, o sistema deve mostrar estado vazio com mensagem clara e a ação para enviar o primeiro PDF.
- **FR-061-025** [SHOULD] Quando o usuário abre o Acervo de PDFs, o sistema deve ordenar a lista por data de envio, do mais recente ao mais antigo (paginação: decisão do plano, conforme o volume).
- **FR-061-026** [MUST] Enquanto o usuário está no Acervo de PDFs, o sistema deve informar de forma visível que não atesta a revisão jurídica do PDF enviado e que o conteúdo é responsabilidade de Produtos.

### FEAT-061-002: Pacotes e exportação para marketplace
> Produtos cadastra um Pacote, escolhe e ordena PDFs do acervo, edita e remove o Pacote e exporta um arquivo único compactado só com os PDFs e baixa a Ficha do pacote à parte; a última exportação e sua composição aparecem no Pacote.

**Jira**: KAN-240

- **FR-061-013** [MUST] Quando um usuário com papel EDITOR ou ADMIN cadastra um Pacote informando Nome e Preço de referência em reais igual ou maior que zero (obrigatórios), e opcionalmente Descrição, Prova/concurso (texto livre) e Disciplina, o sistema deve gravar o Pacote e exibi-lo na lista de Pacotes com esses dados.
- **FR-061-014** [MUST] Se o cadastro ou a edição do Pacote vier sem Nome ou com Preço de referência vazio ou negativo, então o sistema deve recusar e indicar o campo inválido.
- **FR-061-015** [MUST] Quando o usuário adiciona um PDF do acervo a um Pacote, remove um Item ou reordena os Itens, o sistema deve gravar a ordem definida e exibi-la na tela do Pacote; um mesmo PDF não deve aparecer duas vezes no mesmo Pacote.
- **FR-061-016** [MUST] Quando o usuário edita os dados do Pacote e salva, o sistema deve gravar as alterações e exibi-las na lista e na tela do Pacote.
- **FR-061-017** [MUST] Quando o usuário remove um Pacote, o sistema deve pedir confirmação (se já exportado, informando a data da última exportação e que o registro dela fica guardado) e, confirmada, remover o Pacote e seus Itens, manter os PDFs no Acervo de PDFs e manter os registros de exportação dele, com nome do Pacote e composição congelada.
- **FR-061-018** [MUST] Quando o usuário exporta um Pacote com ao menos um Item, o sistema deve gerar um único arquivo compactado contendo só os PDFs do Pacote na ordem definida, cada um com o nome prefixado pela posição (ex.: "01 - <Título>.pdf"), usando o arquivo atual de cada PDF, e entregar o download ao usuário.
- **FR-061-019** [MUST] Se o usuário tenta exportar um Pacote sem Itens, então o sistema deve recusar a exportação com mensagem clara.
- **FR-061-020** [MUST] Quando uma exportação de Pacote é concluída, o sistema deve registrar quem exportou, quando e a composição congelada naquele momento (nome do Pacote e, por Item, posição, Título, Versão, Data de fechamento legislativo declarada, tamanho e identificador de integridade (digest) do arquivo que entrou no compactado), e exibir a última exportação (autor e data) na lista e a composição dela na tela do Pacote.
- **FR-061-021** [MUST] Se o solicitante é um usuário com papel STUDENT ou um visitante sem sessão, então o sistema deve recusar qualquer ação de Pacotes (listar, cadastrar, editar, remover, ordenar Itens, exportar) e não deve expor Pacote nem arquivo exportado.
- **FR-061-022** [MUST] Quando o usuário salva, remove ou exporta um Pacote, o sistema deve mostrar os três estados da ação: em andamento (a ação é desabilitada contra repetição e há indicador até o resultado, inclusive durante a geração do arquivo), sucesso (confirmação; na exportação, o download inicia) e falha (mensagem de erro clara, sem perder o que o usuário preencheu).
- **FR-061-027** [MUST] Se um EDITOR que não é o autor do Pacote tenta removê-lo, então o sistema deve recusar com mensagem clara e manter o Pacote e seus Itens; ADMIN e o autor podem, e listar, editar, compor, ordenar Itens e exportar seguem permitidos a qualquer EDITOR ou ADMIN.
- **FR-061-028** [MUST] Quando o usuário abre a tela do Pacote, o sistema deve exibir a Ficha do pacote e permitir baixá-la à parte como arquivo de texto, com o tamanho total do Pacote.
- **FR-061-029** [MUST] Quando o usuário abre a tela do Pacote ou a Ficha, o sistema deve exibir o tamanho total do Pacote (soma dos tamanhos dos Itens).
- **FR-061-030** [MUST] Quando uma exportação lê o arquivo de cada Item, o sistema deve levar uma versão inteira (anterior ou nova, nunca mistura), mesmo com substituição simultânea, e o registro congelado deve descrever exatamente o arquivo que entrou.
- **FR-061-031** [SHOULD] Quando a lista de Pacotes está vazia, o Pacote não tem Itens ou o seletor de PDFs encontra o Acervo de PDFs vazio, o sistema deve mostrar estado vazio com mensagem clara e a próxima ação.
- **FR-061-032** [SHOULD] Quando o usuário busca por Título no seletor de PDFs do Pacote, o sistema deve filtrar os PDFs do Acervo de PDFs pelo Título digitado.
- **FR-061-033** [SHOULD] Quando o usuário abre a lista de Pacotes, o sistema deve ordená-la por data de criação, do mais recente ao mais antigo (paginação: decisão do plano, conforme o volume).
- **FR-061-034** [MUST] Quando um arquivo é nomeado dentro do compactado, o sistema deve trocar por '-' os caracteres proibidos ('/', '\', ':', '*', '?', '"', '<', '>', '|' e de controle), manter acentos e cortar nome longo demais; o prefixo de posição evita nomes repetidos.
- **FR-061-035** [MUST] O sistema deve informar na Ficha do pacote que não atesta revisão jurídica do PDF enviado e deve rotular a data como "Data de fechamento legislativo (declarada)".

## 6. Requisitos não-funcionais
- **NFR-061-001** [MUST] O PDF do acervo e o arquivo de exportação não devem ficar em endereço público permanente: o endereço de download só deve ser emitido a usuário interno autenticado com papel EDITOR ou ADMIN e deve expirar em até 5 minutos.
- **NFR-061-002** [MUST] O sistema deve registrar e exibir autor e data do envio, da substituição e de cada exportação de Pacote (quem fez o quê, quando), de modo que o registro de exportações sustente a métrica da §1.3.
- **NFR-061-003** [SHOULD] O Guia de uso (docs/GUIA-DE-USO.md) deve ser atualizado na mesma entrega para descrever o Acervo de PDFs, os Pacotes, a exportação e o aviso de que o sistema não atesta revisão jurídica de PDF enviado, com a data de "Última atualização".
- **NFR-061-004** [MUST] Os textos de interface devem estar em pt-BR, com mensagens de recusa que digam ao usuário o que corrigir.
- **NFR-061-005** [MUST] A matriz de autorização de rotas deve mudar apenas pelas rotas novas desta SPEC; a Exportação de PDF da Tira (SPEC-024) deve continuar igual; o menu interno deve ganhar "Acervo de PDFs" e "Pacotes" só para EDITOR e ADMIN, sem tirar nem reordenar entradas existentes.
- **NFR-061-006** [MUST] A exportação deve ter teto cumulativo configurável por Pacote (valor definido no plano, medido contra o ambiente); acima dele, o sistema deve recusá-la com mensagem que informe o total e o teto.

## 7. Critérios de aceitação (Given-When-Then)
- **AC-061-001** (cobre FR-061-001, FR-061-005)
  Dado um usuário EDITOR no Acervo de PDFs, quando ele envia um PDF válido com Título "Tira Direito Penal", Versão "v1" e Data de fechamento legislativo preenchidos, então o PDF aparece na lista com título, versão, data de fechamento, tamanho, seu nome como autor do envio e a data do envio.
- **AC-061-002** (cobre FR-061-002)
  Dado um arquivo de texto renomeado para "material.pdf", quando o usuário tenta enviá-lo, então o sistema recusa o envio com mensagem clara de que o arquivo não é um PDF válido e nada entra no acervo.
- **AC-061-003** (cobre FR-061-003)
  Dado um PDF válido acima de 50 MB, quando o usuário tenta enviá-lo, então o sistema recusa com mensagem clara que informa o limite e nada entra no acervo.
- **AC-061-004** (cobre FR-061-004)
  Dado um envio sem Versão, quando o usuário confirma, então o sistema recusa e indica que a Versão é obrigatória.
- **AC-061-005** (cobre FR-061-006)
  Dado um PDF no acervo, quando o usuário aciona o download, então recebe o arquivo atual desse PDF.
- **AC-061-006** (cobre FR-061-007)
  Dado um PDF no acervo, quando o usuário altera a Versão para "v2" e salva, então a lista mostra "v2" para esse PDF e, ao recarregar a tela, o valor persiste.
- **AC-061-007** (cobre FR-061-008)
  Dado um PDF no acervo, quando o usuário o substitui por outro PDF válido, então o registro e os metadados permanecem, o download entrega o novo arquivo, o arquivo anterior deixa de estar disponível e a lista mostra o autor e a data da substituição.
- **AC-061-008** (cobre FR-061-008, FR-061-002)
  Dado um PDF no acervo, quando o usuário tenta substituí-lo por um arquivo que não é PDF, então o sistema recusa com mensagem clara e o arquivo atual permanece inalterado.
- **AC-061-009** (cobre FR-061-009)
  Dado um PDF que não pertence a nenhum Pacote, quando o usuário o remove, então ele some da lista do acervo e não pode mais ser baixado.
- **AC-061-010** (cobre FR-061-010)
  Dado um PDF que pertence aos Pacotes "Pacote A" e "Pacote B", quando o usuário tenta removê-lo, então o sistema recusa com mensagem que nomeia "Pacote A" e "Pacote B" e o PDF permanece no acervo.
- **AC-061-011** (cobre FR-061-011)
  Dado um usuário com papel STUDENT, quando ele tenta listar, enviar ou baixar um PDF do acervo, então o sistema recusa a ação e não exibe nenhum PDF.
- **AC-061-012** (cobre FR-061-011)
  Dado um visitante sem sessão, quando ele tenta acessar o acervo ou baixar um PDF, então o sistema recusa e exige autenticação, sem entregar o arquivo.
- **AC-061-013** (cobre FR-061-012)
  Dado um envio em curso, quando o usuário aguarda o resultado, então a ação fica desabilitada com indicador de progresso; ao concluir com sucesso aparece a confirmação e o PDF na lista; ao falhar aparece mensagem de erro clara e os campos preenchidos permanecem.
- **AC-061-014** (cobre FR-061-012, FR-061-009)
  Dado um PDF removível, quando o usuário confirma a remoção, então a ação mostra o estado em andamento, o sucesso retira o PDF da lista e uma falha exibe mensagem de erro sem retirá-lo.
- **AC-061-015** (cobre FR-061-013, FR-061-016)
  Dado um usuário ADMIN, quando ele cadastra um Pacote com Nome, Preço de referência R$ 49,90, Prova/concurso e Disciplina e depois altera a Descrição, então a lista e a tela do Pacote mostram os dados gravados e persistem após recarregar.
- **AC-061-016** (cobre FR-061-014)
  Dado um cadastro de Pacote, quando o usuário informa Preço de referência vazio ou negativo (ou deixa o Nome vazio), então o sistema recusa e indica o campo inválido.
- **AC-061-017** (cobre FR-061-015)
  Dado um Pacote e três PDFs do acervo, quando o usuário os adiciona, move o terceiro para a primeira posição e remove o segundo, então a tela do Pacote mostra os Itens na ordem resultante e, ao recarregar, a ordem persiste.
- **AC-061-018** (cobre FR-061-015)
  Dado um Pacote que já contém um PDF, quando o usuário tenta adicioná-lo de novo, então o sistema recusa a duplicidade e a lista de Itens não muda.
- **AC-061-019** (cobre FR-061-017)
  Dado um Pacote com Itens, quando o usuário o remove, então o Pacote some da lista e os PDFs continuam no acervo.
- **AC-061-020** (cobre FR-061-018, FR-061-020)
  Dado um Pacote com os PDFs "Tira A" (v2) e "Tira B" (v1) nessa ordem, quando o usuário exporta, então o download traz um único arquivo compactado só com "01 - Tira A.pdf" e "02 - Tira B.pdf"; a lista de Pacotes passa a mostrar a última exportação com autor e data; e a tela do Pacote mostra a composição congelada dela (nome do Pacote e, por Item, posição, Título, Versão, Data de fechamento legislativo declarada, tamanho e digest).
- **AC-061-021** (cobre FR-061-018)
  Dado um Pacote cujo PDF foi substituído, quando o usuário exporta, então o arquivo compactado traz o arquivo atual desse PDF, não o anterior.
- **AC-061-022** (cobre FR-061-019)
  Dado um Pacote sem Itens, quando o usuário aciona a exportação, então o sistema recusa com mensagem clara de que o Pacote não tem PDFs e nenhuma exportação é registrada.
- **AC-061-023** (cobre FR-061-021)
  Dado um usuário STUDENT, quando ele tenta listar, cadastrar ou exportar Pacotes, então o sistema recusa a ação e não expõe Pacote nem arquivo exportado.
- **AC-061-024** (cobre FR-061-021)
  Dado um visitante sem sessão, quando ele tenta acessar Pacotes ou o arquivo de uma exportação, então o sistema recusa e exige autenticação.
- **AC-061-025** (cobre FR-061-022)
  Dado um Pacote em exportação, quando o arquivo está sendo gerado, então o botão fica desabilitado com indicador; ao concluir o download inicia; ao falhar aparece mensagem de erro clara e nenhuma exportação é registrada. Salvar e remover Pacote seguem os mesmos três estados.
- **AC-061-026** (cobre NFR-061-001)
  Dado um PDF do acervo ou um Pacote a exportar, quando um usuário autenticado com papel EDITOR ou ADMIN pede o download, então recebe um endereço que expira em até 5 minutos e que, usado depois disso, é recusado; e quando o pedido vem de usuário STUDENT ou de visitante sem sessão, nenhum endereço é emitido.
- **AC-061-027** (cobre NFR-061-002)
  Dado um PDF enviado, substituído e incluído em um Pacote exportado, quando Produtos consulta o acervo e o Pacote, então vê o autor e a data do envio, o autor e a data da substituição e o autor e a data da última exportação.
- **AC-061-028** (cobre NFR-061-003)
  Dado o fim da entrega, quando se confere o Guia de uso, então ele descreve o Acervo de PDFs, os Pacotes e a exportação, diz que o sistema não atesta revisão jurídica de PDF enviado e traz a data de "Última atualização" da entrega.
- **AC-061-029** (cobre NFR-061-004)
  Dado qualquer recusa ou mensagem de erro das ações desta SPEC, quando ela é exibida, então o texto está em pt-BR e diz o que corrigir.
- **AC-061-030** (cobre FR-061-020)
  Dado um Pacote exportado com o PDF "Tira A" na Versão "v1", quando o PDF é depois substituído e a Versão editada para "v2", então a tela do Pacote ainda mostra, na exportação anterior, a Versão "v1" e o digest antigos.
- **AC-061-031** (cobre FR-061-018)
  Dado um Pacote exportado, quando se abre o arquivo compactado, então ele contém apenas os PDFs prefixados pela posição e nenhuma Ficha nem preço de referência.
- **AC-061-032** (cobre FR-061-028, FR-061-029)
  Dado um Pacote com Itens, quando o usuário abre a tela do Pacote e baixa a Ficha, então vê o tamanho total (soma dos Itens) na tela e recebe um arquivo de texto com nome, descrição, preço de referência, prova, disciplina, tamanho total e a lista dos PDFs com Versão e "Data de fechamento legislativo (declarada)".
- **AC-061-033** (cobre NFR-061-006)
  Dado um Pacote cuja soma dos Itens ultrapassa o teto de exportação, quando o usuário exporta, então o sistema recusa com mensagem que informa o total e o teto e nenhuma exportação é registrada.
- **AC-061-034** (cobre FR-061-017)
  Dado um Pacote já exportado, quando o usuário o remove, então a contagem de exportações da §1.3 não muda e o registro mantém o nome do Pacote e a composição congelada.
- **AC-061-035** (cobre FR-061-023)
  Dado um PDF enviado por um EDITOR, quando outro EDITOR tenta substituir o arquivo ou removê-lo, então o sistema recusa com mensagem clara e o arquivo permanece intacto.
- **AC-061-036** (cobre FR-061-027)
  Dado um Pacote criado por um EDITOR, quando outro EDITOR tenta removê-lo, então o sistema recusa com mensagem clara e o Pacote e seus Itens permanecem.
- **AC-061-037** (cobre FR-061-023)
  Dado um PDF enviado por um EDITOR, quando outro EDITOR o lista, baixa e edita os metadados e um ADMIN o substitui, então todas as ações são aceitas.
- **AC-061-038** (cobre FR-061-010)
  Dado um PDF que não pertence a nenhum Pacote, quando a remoção dele e a inclusão dele em um Pacote chegam ao mesmo tempo, então a remoção conclui e a inclusão é recusada com mensagem de que o PDF não existe mais, ou a inclusão conclui e a remoção é recusada nomeando o Pacote; nunca fica Item sem arquivo.
- **AC-061-039** (cobre FR-061-030)
  Dado uma exportação em curso e a substituição simultânea de um PDF do Pacote, quando ambas terminam, então ou o arquivo compactado traz inteira a versão desse PDF que a composição congelada registrou, com Versão e digest do registro descrevendo exatamente o arquivo que entrou, ou a exportação falha sem ser registrada e a mensagem orienta exportar de novo; nunca há mistura de versões.
- **AC-061-040** (cobre FR-061-013)
  Dado um cadastro de Pacote com Nome preenchido, quando o usuário informa Preço de referência R$ 0,00, então o sistema aceita e grava o Pacote.
- **AC-061-041** (cobre FR-061-024)
  Dado um Acervo de PDFs sem nenhum PDF, quando o usuário o abre, então vê estado vazio com mensagem clara e a ação para enviar o primeiro PDF.
- **AC-061-042** (cobre FR-061-031)
  Dado nenhum Pacote cadastrado, um Pacote sem Itens e um seletor de PDFs com o Acervo de PDFs vazio, quando o usuário abre cada tela, então cada uma mostra estado vazio com mensagem clara e a próxima ação.
- **AC-061-043** (cobre FR-061-032)
  Dado um Acervo de PDFs com vários PDFs, quando o usuário digita parte de um Título no seletor de PDFs do Pacote, então o seletor mostra apenas os PDFs cujo Título corresponde.
- **AC-061-044** (cobre FR-061-025)
  Dado dois PDFs enviados em datas diferentes, quando o usuário abre o Acervo de PDFs, então o enviado por último aparece primeiro.
- **AC-061-045** (cobre FR-061-033)
  Dado dois Pacotes criados em datas diferentes, quando o usuário abre a lista de Pacotes, então o criado por último aparece primeiro.
- **AC-061-046** (cobre FR-061-034)
  Dado um Pacote cujo primeiro Item tem o Título "Penal: art. 121/122", quando o usuário exporta, então o arquivo compactado traz "01 - Penal- art. 121-122.pdf".
- **AC-061-047** (cobre FR-061-008)
  Dado um PDF no Acervo de PDFs, quando o usuário inicia a substituição, então vê Versão e Data de fechamento legislativo atuais preenchidas e editáveis na mesma ação e uma confirmação de que o arquivo anterior deixa de existir; sem confirmar, nada muda.
- **AC-061-048** (cobre FR-061-017)
  Dado um Pacote já exportado, quando o usuário aciona a remoção, então o sistema pede confirmação com a data da última exportação e a informação de que o registro dela fica guardado.
- **AC-061-049** (cobre FR-061-026)
  Dado um usuário EDITOR no Acervo de PDFs, quando a tela é exibida, então ela informa de forma visível que o sistema não atesta a revisão jurídica do PDF enviado.
- **AC-061-050** (cobre FR-061-035)
  Dado um Pacote com Itens, quando o usuário baixa a Ficha do pacote, então ela informa que o sistema não atesta revisão jurídica do PDF enviado e rotula a data como "Data de fechamento legislativo (declarada)".
- **AC-061-051** (cobre NFR-061-005)
  Dado o conjunto de rotas anterior a esta SPEC, quando se compara a matriz de autorização após a entrega, então ela difere apenas pelas rotas novas do Acervo de PDFs e dos Pacotes.
- **AC-061-052** (cobre NFR-061-005)
  Dado uma Tira, quando o usuário usa a Exportação de PDF da Tira (SPEC-024), então o comportamento e o arquivo permanecem iguais aos anteriores a esta entrega.
- **AC-061-053** (cobre NFR-061-005)
  Dado o menu interno, quando um EDITOR ou ADMIN o abre, então vê "Acervo de PDFs" e "Pacotes" sem que nenhuma entrada existente tenha sido removida ou reordenada; STUDENT e visitante não os veem.

## 8. Premissas e decisões prévias
- **A-061-001** [confirmar] [evidência: crença] — pendente do Diretor (Entrega) — O PDF enviado NÃO passa pela aprovação jurídica do sistema (gate de versão aprovada, SPEC-032): Produtos responde pelo conteúdo e declara a Versão à mão; o Pacote não exige versão aprovada. Default: sem aprovação no sistema e sem gate jurídico; a Ficha do pacote, a interface do Acervo de PDFs e o Guia de uso dizem que o sistema não atesta revisão jurídica (FR-061-026, FR-061-035, NFR-061-003). (O card KAN-240 previa "pacote só publica com versão aprovada", válido para PDF gerado pelo sistema, que está fora desta SPEC.)
- **A-061-002** [assumido] [evidência: crença] O tamanho máximo por arquivo é 50 MB, configurável. Default razoável para PDF diagramado com imagens; ajustável se Produtos tiver PDFs maiores.
- **A-061-003** [assumido] [evidência: crença] O endereço de download expira em até 5 minutos. Default de curta duração suficiente para iniciar o download sem deixar o arquivo acessível.
- **A-061-004** [assumido] [evidência: crença] Atos destrutivos (substituir arquivo, remover PDF, remover Pacote) só pelo autor do registro ou ADMIN; atos reversíveis (listar, baixar, editar metadados, compor e ordenar Itens, editar Pacote, exportar) por qualquer EDITOR ou ADMIN. Protege o trabalho de um colega contra perda irreversível sem travar o uso diário da equipe.
- **A-061-005** [assumido] [evidência: crença] Preço de referência é um valor em reais com duas casas decimais, igual ou maior que zero (R$ 0,00 aceito), apenas informativo; moeda única (BRL).
- **A-061-006** [assumido] [evidência: entrevistas] (decisão do Diretor na última chamada, BRIEF-061) A venda, o pagamento, a nota, o reembolso e a entrega ao aluno ficam no marketplace (decisão do Diretor, BRIEF-061); contingência sem efeito nesta entrega: se um dia a venda vier para este site, o gateway é o Mercado Pago e o aluno acessa por conta criada na compra com link mágico.
- **A-061-007** [assumido] [evidência: entrevistas] (decisão do Diretor na última chamada, BRIEF-061) A ordem de entrega é o acervo (FEAT-061-001) antes de Pacotes e exportação (FEAT-061-002), na mesma branch do épico.
- **A-061-008** [assumido] [evidência: entrevistas] (resolução do PO sobre a antiga Q-061-001) A remoção de PDF que pertence a Pacote fica recusada; Produtos retira o PDF dos Pacotes antes (FR-061-010), o que atende ao fluxo real.

## 9. Riscos e questões abertas
- **RISK-061-001** Sem aprovação jurídica do PDF enviado (A-061-001), um PDF com conteúdo desatualizado pode ser exportado e vendido; a mitigação é a Versão e a Data de fechamento legislativo declaradas e exibidas na Ficha do pacote.
- **RISK-061-002** Versão e Data de fechamento informadas à mão podem divergir do conteúdo real do PDF; o sistema não consegue verificar.
- **RISK-061-003** PDFs grandes e exportações com muitos itens podem ser lentos ou exceder limites de tempo e tamanho do ambiente de execução; a entrega deve tratar isso no plano.
- **RISK-061-004** Substituição sem histórico: o arquivo anterior some, e um PDF substituído por engano não é recuperável pelo sistema.
- **RISK-061-005** Um arquivo com assinatura PDF válida e conteúdo corrompido entra no Acervo de PDFs, pois a validação é pela assinatura; a mitigação é Produtos baixar e conferir o arquivo, e o digest registrado identifica o arquivo exportado.

## 10. Fora deste documento
Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
