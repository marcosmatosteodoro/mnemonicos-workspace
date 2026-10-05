# BRIEF-055: Edição de Conteúdo bruto — ações do rodapé numa barra alinhada

**Slug**: producao-material
**Tipo**: avulso
**Status**: Aberto (card local, aguardando sync com o Jira)
**Data**: 2026-10-05
**Origem**: Diretor, em sessão, sobre `/content/<id>`. O acesso ao Jira está retirado.
**Jira**: KAN-231 (Tarefa, status medido: Backlog; sincronizado em 2026-10-05)

## Pedido como dito
"Os botões de baixo
Ir para a Quebra da regra
Exportar Tira mnemônica
Exportar Resumo
Remover
poderiam estar alinhados de alguma forma"

## Interpretação
No fim da edição (`src/components/content-form.tsx`, bloco `isEdit && contentId`, depois do
painel suplementar e do histórico de versões), as quatro ações hoje ficam **empilhadas** numa
coluna (`flex flex-col gap-2`), cada uma com uma forma diferente:

- "Ir para a Quebra da regra": link de texto sublinhado;
- "Exportar Tira mnemônica" e "Exportar Resumo": botões `surface-card`, vindos de
  `PublicationExportControl`, também em coluna (`flex-col`);
- "Remover": botão `surface-card` com texto `text-danger`.

Depois desta mudança elas formam **uma barra de ações horizontal**:

- **à esquerda**, as ações de seguir/produzir: Ir para a Quebra da regra · Exportar Tira mnemônica ·
  Exportar Resumo;
- **à direita**, isolada, a ação destrutiva: Remover.

As quatro com a mesma aparência de botão e a mesma altura. Se o BRIEF-054 já estiver entregue, no
padrão ícone + rótulo dele.

## Premissas decididas
- **P-055-001** [assumido]: as mensagens de estado continuam **abaixo** da barra, e não dentro
  dela, para que a barra não mude de altura nem pule quando uma mensagem aparece. São elas: o
  progresso e o resultado de cada exportação (`role="status"`/`role="alert"`), o erro de remoção e
  a confirmação de remoção (`alertdialog`).
- **P-055-002** [assumido]: a confirmação de remoção continua como está: Confirmar remoção ·
  Cancelar, com o foco movido para ela. Ela aparece logo abaixo da barra, perto do Remover. Só a
  posição se ajusta.
- **P-055-003** [assumido]: em 360px a barra quebra linha (wrap) mantendo a ordem, e o Remover vai
  para a última linha, ainda separado das demais.
- **P-055-004** [assumido]: a barra fica onde está, no fim da página. Mudar de lugar é decisão do
  BRIEF-056 (reorganização da tela), que pode levar a barra para o topo. A barra deste card é a
  peça que o 056 reaproveita, não trabalho jogado fora.

## Fora de escopo
- O comportamento das ações: destinos, geração e download dos exports, regra de remoção.
- O "Ir para a Tira", que não aparece hoje no rodapé. Entra só se o Diretor pedir, ou no 056.
- Reorganizar o resto da tela (BRIEF-056).

## Critério de aceite
- A partir de 768px, as quatro ações aparecem numa linha só: as três de seguir/exportar à
  esquerda, o Remover à direita, todas com a mesma aparência e altura de botão. "Ir para a Quebra
  da regra" deixa de ser link sublinhado e passa a ter aparência de botão, mantendo `href` e
  papel de link.
- Em 360px, a barra quebra linha sem sobrepor nada e sem rolagem horizontal, e o Remover fica
  separado.
- As mensagens de exportação, a confirmação e o erro de remoção aparecem abaixo da barra, sem
  deslocar os botões. O foco vai para a confirmação ao abrir e volta ao Remover ao cancelar, como
  hoje.
- Os testes existentes do rodapé e do `PublicationExportControl` seguem verdes, ajustados só onde
  provavam layout. `npm run validate` e `npm run build` limpos; nenhuma cor literal nova.

## Gates previstos
code-reviewer (régua avulsa) · product-designer (gate 11) · qa (gate 9: exportar, remover com
confirmar e cancelar, nas 3 larguras e nos 2 temas) · security-engineer n/a · performance-engineer
n/a.

## TASKs
<nenhuma — o brief é a unidade de execução>

## Execução
<a preencher na implementação>
