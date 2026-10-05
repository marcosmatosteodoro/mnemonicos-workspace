# Guia de uso — Material Mnemônico de Alta Retenção

> **Documento vivo, escrito para o editor.** Explica como trabalhar na aplicação, sem
> detalhes técnicos (setup, portas, configuração ficam nos READMEs dos repositórios).
> Toda mudança que altere tela, fluxo, papel, mensagem visível ou o jeito de trabalhar
> atualiza este guia no mesmo ciclo (ver [Como manter](#como-manter-este-guia)).
>
> Versão online (manter igual): https://claude.ai/code/artifact/23d88ef4-3e31-45a0-8749-229080ea2543
>
> Última atualização: 2026-10-05

## O que é, e o que ainda não é

Hoje a aplicação é uma ferramenta interna de produção de material: editores e
administradores transformam um texto normativo em uma Tira mnemônica e exportam PDFs. O
objetivo do produto é converter reconhecimento (achar familiar) em evocação (lembrar sem a
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
3. No menu lateral ficam Painel, Conteúdos e Biblioteca visual (e Usuários, só para
   administradores). Em tela pequena, use o botão Menu.
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
JPEG ou WebP, até 5 MB). Use o filtro por categoria para achar o que já existe antes de criar
outra. Uma imagem que já está em uso numa Tira não pode ser removida.

### 5. Complete o material de reforço

Na tela do conteúdo, abaixo do formulário:

- **Contrastes**: registre o que costuma ser confundido e como distinguir.
- **Pegadinha**: o erro mais comum de prova, escrito em um texto único.
- **Flashcards**: pares de Pergunta e Resposta, para evocação ativa.

Dica: evite setas e símbolos especiais (como → ou ≠) nesses campos, porque podem impedir a
geração do PDF. Escreva "leva a" ou "diferente de".

### 6. Exporte o PDF

Na tela do conteúdo ou da Tira, escolha Exportar Tira mnemônica (um quadro por página) ou
Exportar Resumo. O PDF traz a Tira, os contrastes, a pegadinha, os flashcards e o protocolo
de revisão. Ele sai marcado como RASCUNHO até existir uma versão aprovada. Se a Tira não tem
quadros, o sistema pede para adicionar ao menos um.

### 7. Feche a versão e peça a aprovação

1. Quando o material estiver pronto, vá em Histórico de versões, informe a Data de
   fechamento legislativo (até quando a lei foi conferida) e clique em Fechar versão.
2. Avise um administrador. Ele faz as checagens jurídica e pedagógica e aprova. Quem produziu
   o material não pode aprová-lo.
3. Aprovada, a versão passa a sair no PDF como "Versão N aprovada", no lugar de rascunho.
4. Se você editar o conteúdo ou a Tira depois de fechar, a aprovação deixa de valer. Feche
   uma nova versão e peça nova aprovação.

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

## Como manter este guia

- Mudou tela, fluxo, papel, texto visível ou jeito de trabalhar? Atualize a seção
  correspondente e a data de "Última atualização" **no mesmo ciclo** da mudança.
- Mantenha o doc online igual a este arquivo.
- Funcionalidade nova entra no lugar certo e sai da lista "ainda não é".
- Escreva do ponto de vista de quem usa: o que clicar, o que esperar, o que fazer quando
  falha. Nada de setup, porta, configuração ou nome de arquivo.
- Descreva só o que existe no código; na dúvida, confira no código, não na memória.
- Este arquivo vive no workspace, na `main`.
