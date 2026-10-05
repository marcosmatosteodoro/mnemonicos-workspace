# BRIEF-054: Padrão de botão da aplicação (ícone + rótulo curto), estreado na listagem de Conteúdos brutos

**Slug**: producao-material
**Tipo**: avulso
**Status**: Em revisão (PR aberto)
**Data**: 2026-10-05
**Origem**: Diretor, em sessão, com print de `/content` (tema escuro). O acesso ao Jira está retirado.
**Jira**: KAN-230 (Tarefa, status medido: Backlog; sincronizado em 2026-10-05)

## Pedido como dito
"Ainda me conteuodos, mude o padrão dos botões, pode ser novo editar e ver, tudo com ícone junto,
quero que esse seja o padrão de botões na aplicação"

Print: a listagem `/content` com o botão "Novo conteúdo bruto" no cabeçalho e, em cada cartão, os
botões "Editar conteúdo bruto" e "Ver Quebra da regra".

## Interpretação
Duas coisas num card só.

### 1. O padrão: botão = ícone + rótulo curto
Botão de ação na aplicação passa a ser **ícone à esquerda + rótulo curto** (um verbo, quando der),
sobre a aparência de botão que já existe (`ACTION_LINK_CLASS`, `src/lib/action-link-class.ts`). O
padrão tem **um** ponto de implementação reutilizável, um componente de ação com `icon` + `label`
que serve tanto para link de navegação quanto para `<button>`, e fica registrado como regra em
`guidelines/project/frontend/`. Assim as próximas telas nascem nele e o code-reviewer e o
product-designer passam a cobrá-lo.

Os ícones seguem o padrão atual do projeto: SVG inline em componente próprio (precedente:
`src/components/internal-nav-icons.tsx`), sem biblioteca nova, com `aria-hidden="true"`, cor por
`currentColor` e traço consistente com os ícones da navegação interna.

### 2. A primeira aplicação: listagem `/content`
Na `origin/main` em 2026-10-05:

| Onde | Hoje | Depois |
|---|---|---|
| Cabeçalho (`app/(interno)/content/page.tsx`) | "Novo conteúdo bruto" | ícone de **+** · **"Novo"** |
| Cartão (`components/content-list.tsx`) | "Editar conteúdo bruto" | ícone de **lápis** · **"Editar"** |
| Cartão, com Quebra | "Ver Quebra da regra" | ícone de **olho** · **"Ver"** |
| Cartão, sem Quebra | "Registrar Quebra da regra" | ícone de **+** · **"Criar"** (ver P-054-003) |

## Premissas decididas
- **P-054-001** [assumido]: o rótulo visível encurta, mas o **nome acessível continua completo**.
  Por exemplo, "Editar conteúdo bruto", "Ver Quebra da regra", e nos cartões identificando qual
  conteúdo, porque numa lista com vários cartões "Editar" sozinho é ambíguo para leitor de tela e
  para o comando de voz. O nome acessível precisa **começar** pelo rótulo visível (WCAG 2.5.3, label
  in name): por exemplo, "Editar conteúdo bruto" com o rótulo visível "Editar".
- **P-054-002** [assumido]: "padrão de botões na aplicação" vale como **regra daqui para frente**
  mais a listagem de Conteúdos brutos. A troca em todas as outras telas existentes é um inventário
  grande e tem um conflito em aberto (P-054-004), então fica como card seguinte, a confirmar com o
  Diretor. Os botões que os BRIEF-051 ("Voltar") e BRIEF-053 ("Salvar"/"Cancelar") criam já nascem
  no padrão, se este card entrar antes deles ou na mesma branch.
- **P-054-003** [assumido]: no cartão sem Quebra, o "Registrar Quebra da regra" vira **"Criar"**,
  e não "Registrar", seguindo o BRIEF-053, que tira "Registrar" dos botões. O nome acessível fica
  "Criar Quebra da regra". O Diretor só citou "novo, editar e ver", então esse é o caso dele não
  dito.
- **P-054-004** [em aberto, para o Diretor]: as ações da linha em `/users` (BRIEF-050, KAN-219)
  são **só ícone**, por decisão anterior. Se o padrão "ícone + texto" vale também para ações de
  linha de tabela, isso reverte o KAN-219. Este card **não mexe em `/users`**; a resposta vai para
  o card da troca em toda a aplicação.
- **P-054-005** [assumido]: o destaque e a hierarquia entre botões (primário × secundário) ficam
  como estão. Este card padroniza ícone + rótulo, não a cor nem o peso.

## Relação com os outros cards locais
- **BRIEF-051** ("Voltar") e **BRIEF-053** ("Salvar"/"Cancelar") criam botões que devem nascer no
  padrão. A ordem sugerida é o 054 antes, ou na mesma branch. Se vier depois, os dois ganham o
  ícone no próprio card.

## Fora de escopo
- A troca de botões nas outras telas: Quebra, Tira, edição, usuários, biblioteca visual, painéis
  etc. Fica para o próximo card (P-054-002).
- Mudar destinos, ordem dos botões ou o conteúdo do cartão: texto, metadados e o selo "Tem Quebra
  da regra".

## Critério de aceite
- Existe **um** componente de ação com ícone + rótulo, usado pelos 3 botões da listagem. Não há
  markup de ícone copiado em cada lugar.
- Em `/content`: o cabeçalho mostra "Novo" com ícone; cada cartão mostra "Editar" com ícone e
  "Ver" ou "Criar" com ícone, conforme o conteúdo tenha ou não Quebra da regra. Os `href` não
  mudam.
- Os ícones são decorativos (`aria-hidden`). O nome acessível de cada controle começa pelo rótulo
  visível e identifica a ação por completo. Nos cartões, ele distingue um conteúdo do outro.
- O ícone segue a cor do texto nos dois temas e em hover e foco; o foco por teclado continua
  visível; ícone e texto ficam alinhados na mesma linha em 360/768/1280px.
- A regra do padrão está escrita em `guidelines/project/frontend/` (quando usar, ícone à
  esquerda, rótulo curto, nome acessível completo, componente único) e aponta para o componente.
- Os testes da listagem são atualizados para os rótulos novos e provam o nome acessível completo
  e o ícone `aria-hidden`. `npm run validate` e `npm run build` limpos; nenhuma cor literal nova;
  nenhuma dependência nova.

## Gates previstos
code-reviewer (régua avulsa) · product-designer (gate 11: componente, ícones, copy e
acessibilidade) · qa (gate 9: listagem com conteúdo com e sem Quebra, nos 2 temas) ·
security-engineer n/a · performance-engineer n/a (SVG inline pequeno, sem dependência).

## TASKs
<nenhuma — o brief é a unidade de execução>

## Execução
- 2026-10-05: implementado pelo `developer` em `mnemonicos-frontend`, branch `feat/kan-230-botao-icone-rotulo` (commit `dc67f1c`). PR: https://github.com/marcosmatosteodoro/mnemonicos-frontend/pull/43
- Guideline nova: `guidelines/project/frontend/botoes-acao.md` (indexada no README do frontend), neste repo.
- Gates: code-reviewer aprovado · product-designer aprovado · qa parcial (comportamento provado por teste; verificação visual em temas e 360/768/1280px **não rodada**, Playwright MCP não conectou) · security-engineer e performance-engineer n/a.
- `npm run validate` falha só no `format:check` global (CRLF do checkout Windows, preexistente); lint, typecheck, jest (1341) e build limpos.
- Sugestões baixas não aplicadas: `type` do `<button>` sobrescrevível (decidir antes do BRIEF-053), cast de `rest`, envelope SVG duplicado com `internal-nav-icons.tsx`. Candidatos ao card de migração: `strategic-panel-board.tsx`, `content/new/page.tsx` e o "Tentar novamente".
- Card: KAN-230 em Análise pendente. Concluído só após aviso de merge do Diretor.
