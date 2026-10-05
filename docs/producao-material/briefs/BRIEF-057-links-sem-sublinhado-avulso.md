# BRIEF-057: Nenhum link sublinhado na aplicação

**Slug**: producao-material
**Tipo**: avulso
**Status**: Em revisão (PR aberto)
**Data**: 2026-10-05
**Origem**: Diretor, em sessão. O acesso ao Jira está retirado.
**Jira**: KAN-233 (Tarefa, status medido: Backlog; sincronizado em 2026-10-05)

## Pedido como dito
"Não quero link com a linha de baixo na aplicação tbm"

## Interpretação
É uma regra de toda a aplicação: **nenhum link exibe sublinhado**, nem em repouso nem no hover. Na
`origin/main`, em 2026-10-05, há 28 usos da classe `underline` em 12 arquivos (a contagem inicial, 29 em 13, incluía `content/[id]/page.tsx`, que não tinha):

- páginas `content/[id]`, `content/[id]/breakdown` e `content/[id]/tira`, e `not-found`;
- `content-form`, `contrast-list`, `flashcard-list`, `mnemonic-strip-board`,
  `rule-breakdown-form`, `strategic-panel-board`, `create-user-screen`, `user-edit-screen` e
  `visual-library-board`.

Todos saem.

A regra substitui a decisão anterior do produto (sublinhado como marca de link por default), que
já tinha sido contestada no BRIEF-042 (P-042-003). Vira doutrina escrita:

- `guidelines/project/frontend/`: regra "link sem sublinhado";
- a lição `guidelines/project/lessons/link-discreto-reduz-cor-e-tamanho-nunca-a-marca-de-link.md`
  é **reformulada**, porque a premissa dela ("sublinhado por default") deixa de valer por ordem do
  Diretor.

## Premissas decididas
- **P-057-001** [assumido]: sem o sublinhado, o link continua reconhecível pela **cor** (token
  `--link`, já medido ≥4.5:1 nos dois temas), pela **posição** (isolado, fora de parágrafo) e por
  uma marca **que não é cor** no hover e no foco: o foco visível que já existe, mais uma mudança de
  hover que não seja sublinhado. O product-designer escolhe essa mudança entre os padrões
  existentes.
- **P-057-002** [risco aceito pelo Diretor, registrado]: se houver link **dentro de texto
  corrido**, a WCAG 1.4.1 (uso de cor) exige que só a cor o distinga do texto em volta com
  contraste ≥3:1, mais uma marca não-cromática no hover e no foco. A implementação **mede** cada
  link desse tipo e declara o resultado. Se algum não alcançar 3:1, o caso vai ao Diretor; ele não
  volta a ter sublinhado por conta própria.
- **P-057-003** [assumido]: links que são, na prática, **ações** (por exemplo "Ver na listagem" e
  "Ir para a Quebra da regra") podem virar botão no padrão do BRIEF-054 nos cards em que forem
  tocados, como no BRIEF-055. Este card só tira o sublinhado e não converte links em botões.

## Fora de escopo
- Converter links em botões (BRIEF-054 e cards seguintes).
- Mudar cor, tamanho ou destino de qualquer link.

## Critério de aceite
- Nenhum link da aplicação mostra sublinhado, em repouso ou no hover, nos 2 temas. Não sobra
  nenhum `underline`/`hover:underline` em `src/` (só `no-underline`, se necessário).
- Uma **prova automatizada** impede a volta: um teste ou regra de lint que falha se uma classe
  `underline` aparecer em `src/`, com controle positivo.
- Todo link continua com foco visível por teclado e com uma mudança de hover que não é sublinhado
  (P-057-001).
- Os links em texto corrido, se houver, estão listados no fecho com o contraste medido contra o
  texto vizinho (P-057-002).
- A regra está em `guidelines/project/frontend/`, e a lição
  `link-discreto-reduz-cor-e-tamanho-nunca-a-marca-de-link` está reformulada, conferida presente
  no destino.
- Os testes que provavam `underline` (por exemplo os de navegação de volta) são trocados pela
  prova de ausência. `npm run validate` e `npm run build` limpos; nenhuma cor literal nova.

## Gates previstos
code-reviewer (régua avulsa) · product-designer (gate 11: marca de link sem sublinhado,
contraste) · qa (gate 9: caminhada pelas telas com link nos 2 temas, hover e foco) ·
security-engineer n/a · performance-engineer n/a.

## TASKs
<nenhuma — o brief é a unidade de execução>

## Execução
- 2026-10-05: implementado por developer-via-Tech Lead no worktree `.worktrees/fe-kan233`, PR
  https://github.com/marcosmatosteodoro/mnemonicos-frontend/pull/46. 28 `underline` removidos em 12
  arquivos; hover `link-hover` (fundo `color-mix(currentColor 8%)`); `no-underline.test.ts` (varredura
  com controle positivo); contraste do hover provado em `globals-theme-contrast.test.ts`.
- Gates: code-reviewer aprovado · product-designer reprovou 12% (4,31:1 sobre `--surface-raised`),
  corrigido para 8% com prova · qa (gate 9): **não rodado** (sem caminhada visual nos 2 temas) ·
  security/performance n/a.
- Links em texto corrido: nenhum (P-057-002 não se aplica). `visual-library-board` "Conteúdo vinculado N"
  ganhou `font-semibold` (não cromático).
- Doutrina: `guidelines/project/frontend/link-sem-sublinhado.md`; lição reformulada
  `link-discreto-reduz-cor-e-tamanho-nunca-a-marca-de-link`; lição nova
  `cor-de-estado-derivada-atras-do-texto-mede-contraste-nas-duas-superficies`.
- Jira KAN-233: Em andamento → Análise pendente.
