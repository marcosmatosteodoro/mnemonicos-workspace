# BRIEF-059: Nova conta e Editar conta no padrão dos demais formulários

**Slug**: producao-material
**Tipo**: avulso
**Status**: Aberto (card local, aguardando sync com o Jira)
**Data**: 2026-10-05
**Origem**: Diretor, em sessão, com print de `/users/<id>/edit` (dados da conta no print não
reproduzidos aqui). O acesso ao Jira está retirado.
**Jira**: pendente de sync. Sem acesso ao conector em 2026-10-05; tipo pretendido **Tarefa** (`issueType.standalone`, `10008`), card único

## Pedido como dito
"O Editar e criar conta ta completamente fora do padrão do resto dos formulários"

## Interpretação
`/users/new` (`create-user-screen` + `create-user-form`) e `/users/<id>/edit`
(`user-edit-screen`) usam outro molde de página, diferente das telas de Conteúdo bruto, que são a
referência (conferido na `origin/main` em 2026-10-05):

| Aspecto | Conta (hoje) | Padrão dos formulários (Conteúdo bruto, com os cards 051/053/054/057) |
|---|---|---|
| Navegação de volta | link sublinhado "Voltar para Usuários" **acima** do título | botão **"Voltar"** à direita do título, na mesma linha (BRIEF-051) |
| Cabeçalho | título e subtítulo empilhados | linha `título ⟷ ação` (`flex justify-between`) |
| Corpo | formulário dentro de um cartão estreito (`max-w-md surface-card p-4`) colado à esquerda | formulário na largura da área de conteúdo, com os campos em grade (BRIEF-053) |
| Botões | Salvar · Cancelar **à esquerda** | Cancelar · Salvar no rodapé **à direita** (BRIEF-053) |
| Legenda | "* campo obrigatório" na Nova conta | sem legenda (BRIEF-053) |

A conta passa a seguir o mesmo molde:

- cabeçalho com o título à esquerda e "Voltar" à direita (o subtítulo nome · situação continua
  abaixo do título na edição);
- formulário sem o cartão estreito;
- Nome e E-mail lado a lado a partir de 768px, Papel ao lado ou abaixo, conforme a grade;
- Cancelar · Salvar no rodapé, à direita;
- na edição, "Redefinir senha" como **seção** no mesmo padrão de cabeçalho de seção do BRIEF-053
  (título com linha divisória), com Nova senha · Confirmar senha (BRIEF-058) lado a lado e o botão
  "Redefinir senha" à direita.

## Premissas decididas
- **P-059-001** [assumido]: a referência de "padrão do resto dos formulários" é o Conteúdo bruto
  **depois** dos BRIEF-051/053/054/057. Se este card vier antes deles, as peças de padrão nascem
  aqui (e lá são reaproveitadas), sem uma segunda implementação. Componente de cabeçalho de página
  e de rodapé de formulário compartilhados são o caminho natural; o developer decide, desde que
  haja um ponto só.
- **P-059-002** [assumido]: "Voltar" leva a `/users`, que é o destino atual de "Voltar para
  Usuários". O botão Cancelar também.
- **P-059-003** [assumido]: os dois blocos da edição continuam **independentes** (dados da conta ×
  redefinir senha), cada um com seu botão e sem salvar junto. Só o visual muda.
- **P-059-004** [assumido]: comportamento, validação, estados (carregando, erro, 404, 403) e regras
  de autoedição (`isSelf`) não mudam.

## Relação com os outros cards locais
- Depende de forma (não de código) dos BRIEF-051, 053, 054 e 057 (molde de referência) e conversa
  com o 058, que adiciona o "Confirmar senha" à seção. Ordem sugerida: o 058 antes (bug), e o 059
  depois de 053/054, ou na mesma branch deles.

## Fora de escopo
- A listagem `/users` e as ações das linhas (P-054-004, em aberto).
- Regras de papel, autoedição e o contrato com o backend.

## Critério de aceite
- `/users/new` e `/users/<id>/edit` têm o cabeçalho no mesmo molde das telas de Conteúdo bruto:
  título à esquerda e "Voltar" com aparência de botão à direita, sem link sublinhado.
- Formulário sem o cartão estreito e com a grade de campos do padrão; Cancelar · Salvar no rodapé à
  direita; sem a legenda "campo obrigatório".
- Na edição, "Redefinir senha" aparece como seção com cabeçalho e linha divisória, e o botão de
  ação fica à direita.
- Os mesmos componentes de molde (cabeçalho, rodapé, seção) são usados pela conta e pelo Conteúdo
  bruto, sem layout copiado.
- Os fluxos não regridem: criar conta, editar dados, redefinir senha, e os estados 404, 403, erro
  e carregando. Temas claro e escuro, 360/768/1280px. `npm run validate` e `npm run build` limpos.

## Gates previstos
code-reviewer (régua avulsa) · product-designer (gate 11) · qa (gate 9: criar e editar conta,
redefinir senha, nas 3 larguras) · security-engineer: só se o diff tocar lógica do formulário de
senha ou de papel (se for só layout, n/a declarado) · performance-engineer n/a.

## TASKs
<nenhuma — o brief é a unidade de execução>

## Execução
<a preencher na implementação>
