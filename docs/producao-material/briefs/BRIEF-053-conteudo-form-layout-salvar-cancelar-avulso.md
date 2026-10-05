# BRIEF-053: Formulário de Conteúdo bruto — layout em grade, "Salvar" e "Cancelar" à direita, sem legenda "campo obrigatório"

**Slug**: producao-material
**Tipo**: avulso
**Status**: Aberto (card local, aguardando sync com o Jira)
**Data**: 2026-10-05
**Origem**: Diretor, em sessão, sobre `/content/new` e `/content/<id>`. O acesso ao Jira está retirado.
**Jira**: KAN-229 (Tarefa, status medido: Backlog; sincronizado em 2026-10-05); link `Relates` → KAN-216

## Pedido como dito
"Outra coisa que quero é na página https://mnemonicos-frontend.vercel.app/content/new, tanto na
criação quanto na edição , pode tirar o texto "* campo obrigatório", e isso será padrão, não quero
esse texto em lugar nenhum
Mude o Registrar para salvar,  ao vc deixa em baixono canto direito o botão cancelar e salvar
Ajuste a disposição dos campos, os selects estão enormes e indo até o final,, coloque alguns do lado
um do outro, outra coisa acho que o texto "Fonte normativa" vc queria fazer como quebra de categoria
algo assim, tipo daqui pra baixo é isso, se for isso não ta claro, vc pode adicionar uma linha em
baixo e mudar o padrão desse texto, além disso o Texto normativo pode estar abaixo dos outros 3
selects

Acho que isso tudo é um jira só, tudo isso no edit e create orbviamente, espero que vc não tenha
duplicado o código para eles"

## Interpretação
Criação e edição já compartilham um único componente: `src/components/content-form.tsx`
(`ContentForm`, com `mode="create"` ou `mode="edit"`), conferido na `origin/main` em 2026-10-05. Não
há código duplicado. As mudanças abaixo entram nesse componente e valem para os dois modos ao mesmo
tempo; não pode surgir um ramo de layout por modo.

Situação atual na `origin/main`: todos os campos ficam numa coluna única de largura total, nesta
ordem:

1. Texto normativo
2. Disciplina
3. Tema/assunto
4. Classe do radar de prova
5. `<fieldset>` "Fonte normativa", com `<legend>` de `text-sm font-medium`, contendo Tipo do
   dispositivo, Citação do dispositivo e Link (opcional)
6. `<RequiredLegend />` ("* campo obrigatório")
7. botão "Registrar" (criação) ou "Salvar" (edição), à esquerda (`w-fit`)

Não existe botão Cancelar.

### 1. Legenda "* campo obrigatório" sai da aplicação inteira
O Diretor quer isso como padrão: "não quero esse texto em lugar nenhum". O `RequiredLegend` sai dos
7 formulários que o usam: `content-form`, `contrast-form`, `create-user-form`, `flashcard-form`,
`login-form`, `rule-breakdown-form` e `visual-library-board`. A exportação também sai de
`src/components/required-mark.tsx`, para ninguém voltar a usar. O asterisco ao lado do rótulo
(`RequiredMark`) e o `aria-required` dos controles **ficam**.

### 2. Botões: "Salvar" e "Cancelar", embaixo e à direita
- O envio passa a se chamar **"Salvar"** também na criação. Em processamento, mostra **"Salvando"**,
  e o `aria-label` vira "Salvar o conteúdo bruto" / "Salvando o conteúdo bruto". Somem o
  "Registrar" e o "Registrando" do botão.
- Entra um botão **"Cancelar"** ao lado do Salvar. Os dois ficam no rodapé do formulário, alinhados
  à direita, com Cancelar à esquerda de Salvar.

### 3. Disposição dos campos
Ordem nova:

1. **Disciplina · Tema/assunto · Classe do radar de prova**, lado a lado numa linha a partir da
   largura de tablet. Os selects deixam de ocupar a largura toda.
2. **Texto normativo**, abaixo dos 3 selects, com a largura do formulário.
3. **Fonte normativa** como cabeçalho de seção: texto com outro padrão (mais peso e tamanho que os
   rótulos de campo) e uma linha divisória embaixo, para deixar claro que "daqui pra baixo é a
   fonte".
4. Dentro da seção: **Tipo do dispositivo · Citação do dispositivo**, lado a lado; **Link
   (opcional)** abaixo deles.
5. Rodapé com Cancelar e Salvar à direita (item 2).

No celular (360px), tudo volta a ficar em coluna única, na mesma ordem.

## Premissas decididas
- **P-053-001** [assumido]: "Cancelar" volta para a listagem `/content` sem salvar, nos dois modos,
  sem diálogo de confirmação, como o "Voltar" do cabeçalho (BRIEF-051). Com o envio em andamento, o
  Cancelar fica desabilitado, para ninguém sair achando que o salvamento foi abortado. O Diretor pode
  pedir confirmação ao descartar alterações; aí isso entra como mudança separada.
- **P-053-002** [assumido]: pela semântica de navegação, o Cancelar é um link para `/content` com
  aparência de botão secundário (`ACTION_LINK_CLASS`, o mesmo padrão do BRIEF-051). O Salvar segue
  como o `BusyButton` de submit e ganha destaque de ação primária com o token de ênfase já existente,
  sem cor literal nova. Se o produto ainda não tiver estilo de botão primário, fica igual ao atual e
  a escolha é declarada para o gate 11.
- **P-053-003** [assumido]: "Fonte normativa" continua sendo `<fieldset>`/`<legend>`, porque a
  semântica de grupo dos campos do dispositivo está correta. Só mudam o visual (peso, tamanho e a
  linha embaixo) e o espaço acima do bloco.
- **P-053-004** [assumido]: as mensagens de estado do lado de fora do botão ficam como estão: o
  "Conteúdo bruto registrado." de sucesso na criação e o link "Registrar outro". O pedido era o
  rótulo do botão. Se o Diretor quiser "salvo" também nessas mensagens, é um ajuste a mais dentro
  deste card.
- **P-053-005** [assumido]: as mensagens de erro de cada campo continuam logo abaixo do respectivo
  controle, inclusive na linha de 3 selects. As mensagens de estado vazio ("sem disciplinas", "sem
  temas") e os estados de carregando/erro de disciplinas continuam visíveis perto dos selects.
- **P-053-006** [registrado]: tirar a legenda reverte parte do KAN-216, por ordem explícita do
  Diretor. O asterisco sozinho passa a sinalizar campo obrigatório.

## Relação com os outros cards locais
- **BRIEF-052** (asterisco na mesma linha) toca os mesmos labels de `content-form.tsx`. A forma
  final do rótulo precisa sair dele. Ordem sugerida: o 052 antes, ou os dois na mesma branch, para não
  gerar conflito no mesmo arquivo.
- **BRIEF-051** ("Voltar" no cabeçalho) mexe só nos `page.tsx` e não colide com este.

## Fora de escopo
- O painel suplementar, o histórico de versões e os links "Ir para a Quebra da regra" e "Ir para a
  Tira" da edição, que ficam abaixo do formulário.
- Qualquer outro formulário além da remoção do `RequiredLegend`.
- Validação, regras de obrigatoriedade e contrato com o backend.

## Critério de aceite
- O texto "campo obrigatório" não aparece em nenhuma tela. `RequiredLegend` não existe mais no
  código (`grep` sem resultado em `src/`). O `RequiredMark` e o `aria-required` continuam onde
  estavam.
- Em `/content/new` e `/content/<id>`, o botão de envio diz **"Salvar"** (e "Salvando" em
  processamento) e fica no rodapé, alinhado à direita, com **"Cancelar"** à esquerda dele.
  "Registrar" não aparece em nenhum botão do formulário.
- "Cancelar" leva a `/content` sem disparar nenhuma requisição de escrita, e fica desabilitado
  durante o envio.
- A partir de 768px, Disciplina, Tema/assunto e Classe do radar ficam lado a lado numa linha, e
  Texto normativo fica abaixo deles. Em 360px, os campos ficam em coluna única na ordem
  Disciplina → Tema/assunto → Classe → Texto normativo → Fonte normativa → botões.
- "Fonte normativa" aparece como título de seção, com linha divisória embaixo, visualmente distinto
  dos rótulos de campo. Tipo do dispositivo e Citação ficam lado a lado a partir de 768px, com Link
  abaixo.
- A ordem de tabulação segue a ordem visual nova.
- Criação e edição renderizam o mesmo markup de layout a partir de um único `ContentForm`; não há
  bifurcação de layout por `mode`.
- Validações, mensagens de erro por campo, os estados de carregando/erro/vazio de disciplinas e
  temas, e o fluxo de sucesso ("Ver na listagem" / "Registrar outro") continuam funcionando. Os
  testes existentes são atualizados para o rótulo novo, e entram provas do Cancelar e da ausência da
  legenda.
- Temas claro e escuro, 360/768/1280px. `npm run validate` e `npm run build` limpos; nenhuma cor
  literal nova.

## Gates previstos
code-reviewer (régua avulsa) · product-designer (gate 11: layout, hierarquia, copy e estados) · qa
(gate 9: criar e editar de ponta a ponta, Cancelar e as 3 larguras) · security-engineer n/a (sem
mudança de dado, auth ou endpoint) · performance-engineer n/a.

## TASKs
<nenhuma — o brief é a unidade de execução>

## Execução
<a preencher na implementação>
