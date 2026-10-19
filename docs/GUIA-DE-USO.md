# Guia de uso — Material Mnemônico de Alta Retenção

> **Documento vivo, escrito para o editor.** Explica como trabalhar na aplicação, sem
> detalhes técnicos (setup, portas, configuração ficam nos READMEs dos repositórios; a única
> exceção é a seção [Armazenamento de arquivos](#armazenamento-de-arquivos)).
> Toda mudança que altere tela, fluxo, papel, mensagem visível ou o jeito de trabalhar
> atualiza este guia no mesmo ciclo (ver [Como manter](#como-manter-este-guia)).
>
> Versão online (manter igual): https://claude.ai/code/artifact/23d88ef4-3e31-45a0-8749-229080ea2543
>
> Última atualização: 2026-10-19

## O que é, e o que ainda não é

Hoje a aplicação é uma ferramenta interna de produção de material: editores e
administradores transformam um texto normativo em uma Tira mnemônica e exportam PDFs. Ela
também guarda PDFs prontos num Acervo de PDFs e os reúne em Pacotes, que são exportados para
venda em marketplace. O objetivo do produto é converter reconhecimento (achar familiar) em evocação (lembrar sem a
dica).

Você ainda não encontra nesta versão: tela de estudo e revisão para estudantes, cadastro de
disciplinas e temas (já vêm cadastrados), "esqueci a senha" e a opção de desfazer a remoção
de um conteúdo. A revisão espaçada é um protocolo impresso no PDF (R0, R24, R3, R7, R14 e
R30), com caixa para marcar e "data: ___" para preencher à mão.

## Como entrar e se orientar

1. Entre com seu e-mail e sua senha. Se a conta for nova, quem criou a conta (um
   administrador) passa os dados.
2. Se aparecer "Sua sessão expirou. Entre novamente.", basta entrar de novo; o sistema leva
   você de volta à tela em que estava.
3. No menu lateral ficam, nesta ordem, Painel, Conteúdos, Biblioteca visual, Usuários (só
   para administradores), Acervo de PDFs e Pacotes. Em tela pequena, use o botão Menu.
4. No topo ficam o botão de tema claro/escuro e o Sair.

Editor vê e edita só os conteúdos que ele mesmo criou. Administrador vê tudo, cuida das
contas e aprova versões.

## Produzindo um material, passo a passo

A ordem de trabalho é: registrar o conteúdo, quebrar a regra, montar a Tira, completar o
reforço, exportar o PDF e fechar a versão para aprovação.

### 1. Registre o conteúdo bruto

Em Conteúdos, clique em Novo conteúdo bruto e preencha:

- **Texto normativo**: o trecho exato da lei, súmula ou ato que você vai trabalhar.
- **Disciplina e Tema**: escolha a disciplina primeiro; o tema só libera depois.
- **Classe do radar de prova**: o quanto isso cai em prova (Alta, Média, Detalhe, Exceção ou
  Pegadinha). Ela define a prioridade no Painel.
- **Fonte normativa** (opcional): tipo do dispositivo, citação (obrigatória se você escolheu
  o tipo) e link. Preencha sempre que puder: sem fonte, a versão não poderá ser aprovada
  depois.

Clique em Registrar. Para mudar algo depois, abra o conteúdo pela lista (Editar conteúdo
bruto).

### 2. Faça a Quebra da regra

No conteúdo, vá em Ir para a Quebra da regra e decomponha o texto:

- Conceito, Ação e Objeto são obrigatórios.
- Condição e Exceção são opcionais: deixe vazio se a regra não tem.
- Síntese da regra essencial: a regra inteira numa frase, obrigatória.

Salve. Sem a Quebra salva, a Tira não é gerada.

### 3. Ajuste a Tira mnemônica

Depois da Quebra, clique em Ir para a Tira mnemônica. Ela já vem pronta: um quadro para cada
parte preenchida (conceito, ação, objeto, condição, exceção). Agora você trabalha a
evocação:

- Edite o texto de cada quadro para ficar curto e fácil de lembrar.
- Reordene com Mover para cima e Mover para baixo; remova o que não ajuda; adicione quadros
  novos na posição que quiser.
- Em cada quadro, vincule uma associação visual (imagem da Biblioteca visual). Para trocar, o
  sistema pede confirmação; Desvincular tira a imagem.

### 4. Cuide da Biblioteca visual

Aqui ficam as imagens reutilizáveis. Para criar uma associação visual, informe a categoria,
descreva a função cognitiva (por que essa imagem ajuda a lembrar) e envie a imagem (PNG,
JPEG ou WebP, até 5 MB). Abaixo do nome de cada campo há uma explicação curta, com exemplo,
do que preencher. Use o filtro por categoria para achar o que já existe antes de criar
outra. Uma imagem que já está em uso numa Tira não pode ser removida.

- **Categoria**: um nome curto que agrupa imagens do mesmo tipo (ex.: Prazo, Competência,
  Sanção). Se aparecer uma categoria sugerida que sirva, escolha-a: é ela que o filtro usa.
- **Descrição da função cognitiva**: por que esta imagem ajuda a lembrar a regra sem a dica
  na frente. Se tirar a imagem não fizer falta para lembrar, ela é só decoração.
- **Imagem**: PNG, JPEG ou WebP. O WebP é aceito na biblioteca; no rascunho não aparece, no PDF
  final aparece. Se a imagem tiver o lado maior abaixo de 2000 px, o envio mostra um aviso de
  Resolução recomendada (“Imagem com L × A px; recomendado: lado maior de 2000 px para boa
  impressão”), só informativo (ver
  [Como ilustrar uma tira e gerar o PDF](#como-ilustrar-uma-tira-e-gerar-o-pdf)).

### 5. Complete o material de reforço

Na tela do conteúdo, abaixo do formulário:

- **Contrastes**: registre o que costuma ser confundido e como distinguir.
- **Pegadinha**: o erro mais comum de prova, escrito em um texto único.
- **Flashcards**: pares de Pergunta e Resposta, para evocação ativa.

Dica: evite setas e símbolos especiais (como → ou ≠) nesses campos, porque podem impedir a
geração do PDF. Escreva "leva a" ou "diferente de".

### 6. Exporte o PDF

Há dois modos de exportar:

- **Modo rascunho**, nas telas do conteúdo e da Tira: Exportar Tira mnemônica (um quadro por
  página) ou Exportar Resumo. O PDF traz a Tira, os contrastes, a pegadinha, os flashcards e o
  protocolo de revisão. Ele sai marcado como RASCUNHO até existir uma versão aprovada.
- **Modo PDF final**, só na tela da Tira, abaixo dos quadros: Exportar PDF final. Exige uma
  versão aprovada (ver o passo 7). O PDF tem uma capa com Disciplina, Tópico, Versão e a data
  até a qual a legislação foi verificada, um quadro por página com a imagem, e rodapé com a
  Versão e essa data. Contrastes, pegadinha, flashcards e protocolo de revisão não entram nele.

Se a Tira não tem quadros, o sistema pede para adicionar ao menos um. Para ilustrar a Tira e
publicar o PDF final, veja [Como ilustrar uma tira e gerar o PDF](#como-ilustrar-uma-tira-e-gerar-o-pdf).

### 7. Feche a versão e peça a aprovação

1. Quando o material estiver pronto, vá em Histórico de versões, informe a Data de
   fechamento legislativo (até quando a lei foi conferida) e clique em Fechar versão.
2. Avise um administrador. Ele faz as checagens jurídica e pedagógica e aprova. Quem produziu
   o material não pode aprová-lo.
3. Aprovada, a versão passa a sair no PDF como "Versão N aprovada", no lugar de rascunho.
4. Se você editar o conteúdo ou a Tira depois de fechar, a aprovação deixa de valer. Feche
   uma nova versão e peça nova aprovação.

## Vendendo pacotes de PDF, passo a passo

O Acervo de PDFs guarda os PDFs prontos; um Pacote reúne alguns deles, em ordem, com um preço
de referência, e é exportado como um arquivo compactado para o marketplace. O sistema guarda
e entrega o arquivo como foi enviado, sem olhar o conteúdo.
O sistema não atesta a revisão jurídica do PDF enviado;
o conteúdo é responsabilidade de Produtos.

### 1. Envie os PDFs ao Acervo

Em Acervo de PDFs, preencha o formulário de envio e clique em Enviar PDF:

- **Título**, **Versão** e **Data de fechamento legislativo** são obrigatórios (esta é a data
  declarada por quem envia, até quando a lei foi conferida). **Prova/concurso** e
  **Disciplina** são opcionais.
- **Arquivo PDF**: só PDF, não vazio e dentro do limite de tamanho (50 MB, salvo ajuste de quem
  instala). Durante o envio o botão mostra "Enviando" e há uma barra de progresso.
- Com o acervo vazio, a lista mostra "Nenhum PDF no acervo ainda." e o botão Enviar o primeiro
  PDF leva ao formulário.

Cada PDF da lista tem Baixar. Só o autor do PDF ou um administrador vê Editar, Substituir e
Remover:

- **Editar** muda Título, Versão, Data de fechamento legislativo e os opcionais, sem trocar o
  arquivo (Salvar alterações).
- **Substituir** troca o arquivo (Confirmar substituição). O arquivo anterior deixa de existir.
- **Remover** pede Confirmar remoção; o arquivo deixa de existir e não pode ser recuperado. Um
  PDF que está em um Pacote não é removido: tire-o do Pacote primeiro.

### 2. Monte o Pacote

1. Em Pacotes, clique em Cadastrar Pacote e informe o **Nome** e o **Preço de referência
   (R$)** (em reais, como 49,90). Descrição, Prova/concurso e Disciplina são opcionais. Clique
   em Salvar Pacote.
2. Abra o Pacote (Abrir). Em PDFs do Pacote, clique em Adicionar PDF: o seletor lista o Acervo,
   com busca por título (Buscar PDF por Título); o PDF que já está no Pacote aparece como "Já
   no Pacote".
3. Cada PDF no Pacote é um Item. Reordene com Mover para cima e Mover para baixo; tire um Item
   com Remover do Pacote (o PDF continua no Acervo).
4. Para mudar nome, preço ou descrição use Editar. Para apagar o Pacote use Remover e
   Confirmar remoção: os PDFs dos Itens continuam no Acervo e o registro das exportações já
   feitas fica guardado. Só o autor do Pacote ou um administrador remove o Pacote; editar e
   compor fica aberto a qualquer editor.

### 3. Baixe a Ficha e exporte

- A **Ficha do Pacote** resume o Pacote: nome, descrição, preço de referência, prova, disciplina, **Tamanho total** e,
  por Item, posição, título, versão, Data de fechamento legislativo (declarada) e tamanho.
  Baixar Ficha (.txt) salva o arquivo `ficha-<nome>.txt`.
- **Exportar Pacote** gera um arquivo compactado só com os PDFs, com nomes prefixados pela
  posição (por exemplo `01 - Título.pdf`). O botão mostra "Exportando" enquanto trabalha e o
  arquivo baixado se chama `pacote-<código da exportação>.zip`. Pacote sem PDFs, ou com tamanho
  total acima do teto de exportação, não exporta.
- A exportação só conta depois que o download termina. Em Última exportação aparecem quem
  exportou, quando e os PDFs incluídos (ou "Ainda não exportado").
- Se algo falha, a tela diz para exportar de novo. Se aparecer "O arquivo baixado não vale;
  exporte de novo.", apague o arquivo baixado e clique em Exportar Pacote outra vez.

## Como ilustrar uma tira e gerar o PDF

### Ilustrar a tira

1. Na Tira mnemônica, escolha a associação visual de cada quadro no seletor. Se o seletor
   estiver vazio, use o link "Ir para a Biblioteca visual", cadastre a imagem e volte pelo link
   "Voltar para a tira".
2. Acompanhe o indicador "N de M quadros com imagem": ele diz quantos quadros já têm imagem.
3. Ao enviar uma imagem, o ideal é que o lado maior tenha 2000 px. Abaixo disso o formulário
   mostra “Imagem com L × A px; recomendado: lado maior de 2000 px para boa impressão”
   (Resolução recomendada); é só informativo e o envio continua.
4. O PDF final ajusta as imagens maiores que 2000 px no próprio PDF. A imagem guardada na
   Biblioteca visual não muda.

### Rascunho ou PDF final

- O **rascunho** (Exportar Tira mnemônica, nas telas do conteúdo e da Tira) não exige versão
  aprovada e sai marcado como RASCUNHO até existir uma versão aprovada. Nele, imagens WebP
  seguem sem aparecer.
- O **PDF final** (Exportar PDF final, só na tela da Tira, abaixo dos quadros) exige uma versão
  aprovada e válida, e nele o WebP aparece. Com o botão desabilitado, leia o motivo logo abaixo
  dele:
  - se for a versão (não aprovada, ou alterada depois do fechamento), abra "Histórico de
    Versões": feche a versão (se ainda não fechou) e peça a um administrador que não a produziu
    para aprová-la; se o conteúdo ou a Tira foram alterados depois do fechamento, feche e
    aprove uma nova versão;
  - se a Tira não tem quadros, adicione ao menos um;
  - se a tela disser que não foi possível verificar ou carregar, clique em “Tentar novamente”.
- Se o PDF ficar grande demais, reduza o tamanho das imagens dos quadros e exporte de novo.

### Ler o Aviso de exportação

O "Aviso de exportação" lista os quadros com problema, um por linha. Na tela da Tira aparece
depois de "Exportar PDF final"; antes de publicar, aparece dentro da janela de publicar, com a
nota "Verificação prévia — a exportação confirma as imagens":

- **Sem imagem**: o quadro não tem imagem. Vincule uma pelo seletor.
- **Imagem que não entrou no PDF**: use "Trocar associação visual" no quadro.
- **Imagem abaixo da resolução recomendada**: só informativo; o PDF sai normalmente.

### Publicar e baixar

1. Na tela da Tira, com a versão aprovada, clique em "Publicar PDF final" e, na janela, em
   "Confirmar publicação".
2. Se faltam imagens (quadros sem imagem ou com imagem que não entrou), a janela pede para
   marcar que você quer publicar mesmo assim.
3. Se a versão já tem PDF publicado, a janela mostra a data e pergunta se quer publicar outro.
4. O painel "PDFs publicados" (também na tela da Tira) lista o que já foi publicado; o mais recente traz a marca
   “atual”. Use “Baixar” para salvar o PDF.
5. Se publicar ou baixar falhar, tente de novo. Se a janela avisar que a cobertura de imagens
   mudou ou que a versão ganhou um PDF enquanto ela estava aberta, confira o resumo e confirme
   de novo. Se a publicação disser que não é possível agora, confira em "Histórico de Versões"
   se há uma versão aprovada.

## Acompanhando o trabalho no Painel

O Painel mostra a fábrica inteira, e só tem dados depois que existem conteúdos. Use-o para
decidir o que fazer a seguir:

- **Backlog de produção**: o que ainda falta, por prioridade (Alta, Média, Baixa). Comece
  pelo topo; o link Ver Conteúdo abre o item.
- **Tempo por página e por etapa**: onde o tempo está indo, por conteúdo, com média e mediana
  por módulo.
- **Conclusão por Módulo**: quanto de cada disciplina e tema já está concluído.
- **Correções após revisão**: quanto retrabalho houve depois de uma versão fechada.

## Para administradores

- **Aprovar uma versão**: abra o conteúdo, vá em Histórico de versões, marque Checagem
  jurídica confirmada e Checagem pedagógica confirmada e clique em Aprovar versão. Só marque
  depois de conferir de fato.
- **Criar conta**: em Usuários, clique em Nova conta, informe nome, e-mail, papel (Editor ou
  Administrador) e uma senha de pelo menos 12 caracteres.
- **Editar ou redefinir senha**: na lista, use Editar. Redefinir a senha encerra as sessões
  da pessoa.
- **Desativar** quando alguém sai do projeto (a conta pode ser reativada). **Excluir** só
  vale para conta desativada, é irreversível e permite transferir os conteúdos da pessoa para
  outra conta.
- Sempre precisa restar um administrador ativo: o sistema não deixa desativar ou rebaixar o
  último.

## Quando algo não funciona

| O que aparece | O que fazer |
| --- | --- |
| "Conclua a Quebra da regra antes de gerar a Tira mnemônica." | Volte à Quebra, preencha os campos obrigatórios e salve |
| "Esta Tira mnemônica não tem Quadros para exportar." | Adicione ao menos um quadro à Tira |
| Não consigo remover uma associação visual | Ela está em uso: desvincule dos quadros primeiro |
| "Você não pode aprovar uma versão que você mesmo produziu." | Peça a outro administrador |
| Não consigo aprovar: "O conteúdo foi editado depois do fechamento" | Feche uma nova versão e aprove essa |
| Não consigo aprovar: versão sem fonte normativa | Preencha a Fonte normativa do conteúdo e feche nova versão |
| Não vejo um conteúdo de colega | Editor só vê os próprios; peça a um administrador |
| "Você não tem permissão para ver esta página." | A tela é de administrador |
| "Armazenamento de arquivos não configurado neste ambiente. Avise o administrador para configurá-lo." | Falta provisionar o armazenamento; veja [Armazenamento de arquivos](#armazenamento-de-arquivos) |
| "Não foi possível enviar o arquivo ao armazenamento. Verifique a conexão e use "Enviar PDF" para tentar de novo; se persistir, avise a equipe técnica (a origem do site pode não estar liberada no armazenamento)." | Confira a conexão e tente de novo; se persistir, avise a equipe técnica (o CORS do bucket pode não liberar o site — ver Pendências do Diretor). Ao substituir, a mesma mensagem cita "Confirmar substituição" |
| "Não foi possível gerar o arquivo. Clique em "Exportar Pacote" para exportar de novo." | Exporte de novo; se persistir, avise a equipe técnica (o CORS do bucket pode não liberar o site — ver Pendências do Diretor) |
| "O arquivo baixado não vale; exporte de novo." | Apague o arquivo baixado e clique em Exportar Pacote outra vez |

## Armazenamento de arquivos

Esta seção é para quem instala e mantém o ambiente. Os PDFs do Acervo ficam num armazenamento
de arquivos compatível com S3; o navegador envia e baixa o arquivo direto nele, por endereço
temporário assinado.

### Ambiente local

No `mnemonicos-backend`, `npm run db:up` sobe o Postgres e o MinIO locais juntos. As variáveis
ficam no `.env` do backend (o `.env.example` traz os placeholders; nunca coloque credencial
real no guia nem no repositório):

| Variável | Para que serve |
| --- | --- |
| OBJECT_STORAGE_ENDPOINT | Endereço do armazenamento (opcional; o MinIO local exige, o S3 da AWS dispensa) |
| OBJECT_STORAGE_REGION | Região do bucket |
| OBJECT_STORAGE_BUCKET | Nome do bucket |
| OBJECT_STORAGE_ACCESS_KEY_ID | Identificador da credencial de acesso |
| OBJECT_STORAGE_SECRET_ACCESS_KEY | Segredo da credencial de acesso (nunca versionar) |
| PDF_LIBRARY_MAX_FILE_SIZE_BYTES | Teto do PDF enviado ao Acervo, em bytes (padrão 52428800, 50 MB) |
| SALES_PACKAGE_MAX_EXPORT_BYTES | Teto do arquivo de exportação de um Pacote, em bytes (padrão 524288000, 500 MB) |

Sem região, bucket e as duas credenciais, as telas que usam arquivos mostram a mensagem de
armazenamento não configurado (ver "Quando algo não funciona").

### Pendências do Diretor

O que falta provisionar fora do código:

1. **Conta, bucket e credenciais** do armazenamento de produção.
2. **CORS do bucket**: como o navegador envia (PUT) e baixa (GET) direto no bucket, ele precisa
   liberar esses métodos para o site. Localmente o `docker-compose.yml` do backend libera
   `http://localhost:3000` e `http://localhost:3001`; em produção as origens são as do frontend
   publicado, em lista explícita, nunca curinga. Sem isso o envio e a substituição falham com a
   mensagem de origem não liberada, e a exportação do Pacote falha com "Não foi possível gerar
   o arquivo".
3. **Variáveis no deploy**: as cinco `OBJECT_STORAGE_*` (e, se quiser mudar os tetos, as duas
   de tamanho) no ambiente do backend publicado.
4. **Regra de lifecycle do bucket** para o prefixo `pending/`: envios que começaram e não
   foram confirmados ficam lá; recomenda-se expirá-los automaticamente.

## Glossário

| Termo | Significado |
| --- | --- |
| Conteúdo bruto | Texto normativo de partida |
| Radar de prova | O quanto o tema cai em prova: Alta, Média, Detalhe, Exceção, Pegadinha |
| Quebra da regra | Decomposição em conceito, ação, objeto, condição e exceção |
| Tira mnemônica | Sequência de quadros para memorizar a regra |
| Associação visual | Imagem da biblioteca ligada a um quadro |
| Contraste | Par de coisas confundíveis e como distingui-las |
| Pegadinha | Erro comum de prova |
| Versão | Foto fechada e numerada do material, que pode ser aprovada |
| Módulo | Disciplina e tema |
| Acervo de PDFs | Coleção de PDFs prontos, com título, versão e data de fechamento legislativo |
| Pacote | Conjunto ordenado de PDFs do Acervo, com preço de referência, exportado para venda |
| Item | Um PDF dentro de um Pacote, em uma posição |
| Ficha do pacote | Resumo em texto (.txt) do Pacote e de seus Itens, com o tamanho total |
| Exportação | Geração do arquivo compactado do Pacote; só vale depois que o download termina |
| Data de fechamento legislativo (declarada) | Data informada por quem envia o PDF; o sistema não a confere |

## Como manter este guia

- Mudou tela, fluxo, papel, texto visível ou jeito de trabalhar? Atualize a seção
  correspondente e a data de "Última atualização" **no mesmo ciclo** da mudança.
- Mantenha o doc online igual a este arquivo.
- Funcionalidade nova entra no lugar certo e sai da lista "ainda não é".
- Escreva do ponto de vista de quem usa: o que clicar, o que esperar, o que fazer quando
  falha. Nada de setup, porta, configuração ou nome de arquivo, exceto na seção
  Armazenamento de arquivos, a única que fala de ambiente.
- Descreva só o que existe no código; na dúvida, confira no código, não na memória.
- Este arquivo vive no workspace, na `main`.
