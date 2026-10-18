# BRIEF-062: Texto de ajuda nos campos obrigatórios de "Criar associação visual"

**Slug**: producao-material
**Tipo**: avulso
**Status**: Concluído, PR #52 mergeado (KAN-238)
**Data**: 2026-10-18
**Origem**: Revisão de Produtos de 14/10/2026 (`thoughts/implementacoes/SITE MNEMÔNICO.pdf`, item 4),
registrada no card. Diretor, em sessão: "Implemente o jira KAN-238".
**Jira**: KAN-238 (Tarefa; Backlog → Tarefas pendentes `4` → Em andamento `6`, em 2026-10-18).
Link `Relates` → KAN-247. Formato WEBP no PDF: KAN-245 (Tarefas pendentes, sem decisão).

## Pedido como dito
"Quero que para cada asterisco desse apareça a explicação do que significa, de como fazer."
(Produtos, sobre o formulário "Criar associação visual" com os três campos obrigatórios em erro.)

## Interpretação
No formulário de criação da Biblioteca visual (`src/components/visual-library-board.tsx`), os
campos **Categoria\***, **Descrição da função cognitiva\*** e **Imagem\*** só têm rótulo e, depois
de um envio vazio, a mensagem de erro. O editor não sabe o que escrever, principalmente em
"função cognitiva", que é jargão do método. Também não sabe quais formatos de imagem a tela aceita.

Cada um dos três campos passa a ter um **texto de ajuda visível e permanente**, entre o rótulo e o
controle. A ajuda aparece antes de qualquer erro e continua lá quando o erro aparece. Ela está ligada
ao controle por `aria-describedby`, então o leitor de tela anuncia a ajuda ao focar o campo e, se
houver erro, anuncia a ajuda e depois o erro.

O padrão nasce reaproveitável: um componente de ajuda de campo, documentado no guideline de frontend
(§Campo obrigatório), para os demais formulários com asterisco adotarem quando forem tocados.

### Primeira versão do texto (sai da SPEC-022 e da TAP; Produtos valida)
- **Categoria**: "Agrupa imagens do mesmo tipo para você encontrá-las depois no filtro da
  biblioteca e reaproveitá-las em outras tiras. Use um nome curto e, se uma categoria sugerida
  servir, escolha-a. Ex.: Prazo, Competência, Sanção."
- **Descrição da função cognitiva**: "Explique por que esta imagem ajuda a lembrar a regra sem
  a dica na frente. Se tirar a imagem não fizer falta para lembrar, ela é só decoração. Ex.: \"A
  ampulheta quase vazia lembra que o prazo de recurso é curto: 5 dias.\""
- **Imagem**: "PNG, JPEG ou WebP, até 5 MB. Para a imagem sair no PDF da tira, use PNG ou JPEG:
  WebP ainda não aparece no PDF. Prefira uma cena ou um símbolo ligado à regra, não uma ilustração
  só decorativa."

O developer pode ajustar a redação para caber bem na tela. O sentido de cada frase não muda sem
passar por Produtos.

## Premissas decididas
- **P-062-001** [decidido em nome do Diretor, a confirmar]: **sem a legenda "\* campo
  obrigatório"**, embora o card peça. O Diretor ordenou no BRIEF-053 (P-053-006) que esse texto não
  aparecesse "em lugar nenhum", como padrão, e o `RequiredLegend` foi removido do código. Ordem
  explícita do Diretor vence pedido de Produtos até ele decidir o contrário. Reverter é só voltar
  com a legenda neste formulário.
- **P-062-002** [assumido]: a ajuda do campo Imagem descreve o comportamento **de hoje**: o upload
  aceita WebP, mas a imagem WebP não sai no PDF (RISK-025-006). Quando o KAN-245 decidir, esta frase
  muda junto.
- **P-062-003** [assumido]: a ajuda **não entra no nome acessível** do campo. O nome continua sendo
  só o rótulo ("Categoria", sem o "\*"), e a ajuda vai na descrição. Testes que buscam o campo por
  nome não mudam.
- **P-062-004** [assumido]: os números da ajuda (formatos e 5 MB) vêm de um ponto só no frontend,
  ao lado do `accept` do input, e batem com o backend (`VISUAL_ASSOCIATIONS_MAX_FILE_SIZE_BYTES`,
  default 5242880; formatos PNG/JPEG/WEBP por assinatura). Não existe endpoint de configuração
  para consultar, e criar um aqui está fora de escopo.
- **P-062-005** [assumido]: validação, mensagens de erro, envio e estados (enviando, sucesso,
  falha) não mudam.

## Fora de escopo
- O formulário de **edição** inline da associação ("Editar categoria" etc.) e os demais formulários
  com asterisco. Eles herdam o padrão quando forem tocados, sem um card só para isso.
- Mudar formatos aceitos, tamanho máximo ou o comportamento de WebP no PDF (KAN-245).
- Tooltip ou ícone "?": a ajuda é texto visível.

## Critério de aceite
- Os três campos obrigatórios de "Criar associação visual" mostram a ajuda visível desde a
  abertura da tela, sem erro nenhum, entre o rótulo e o controle.
- Com erro de campo vazio, a ajuda continua visível e a mensagem de erro aparece abaixo do campo,
  como hoje.
- O controle tem `aria-describedby` apontando para a ajuda e, com erro, para a ajuda e o erro,
  nessa ordem. O nome acessível do controle continua sendo só o rótulo.
- A ajuda vem de um componente de ajuda de campo, reaproveitável, documentado no guideline de
  frontend.
- Teste automatizado cobre: ajuda presente sem erro, `aria-describedby` com e sem erro, nome
  acessível sem a ajuda.
- `npm run lint`, `npm run typecheck`, `npm test` e `npm run build` limpos. Tela legível nos temas
  claro e escuro, em 360, 768 e 1280px.
- `docs/GUIA-DE-USO.md` atualizado, com a data de "Última atualização".

## Gates previstos
code-reviewer (régua avulsa) · product-designer (gate 11: markup, copy e hierarquia visual da
ajuda) · qa (gate 9: tela real, ajuda visível, erro coexistindo, `aria-describedby` medido,
3 larguras e 2 temas) · security-engineer: n/a se o diff for só copy e ARIA (o caminho casa com
`sensitiveGlobs`, mas não muda upload, validação nem envio; o estado se confirma no diff) ·
performance-engineer n/a (sem consulta, laço nem bundle novo relevante).

## TASKs
<nenhuma — o brief é a unidade de execução>

## Execução (2026-10-18)
- Branch `feat/kan-238-ajuda-campos-associacao-visual` (worktree `../wt-kan-238-ajuda-campos`, a partir
  de `origin/main` a40bc8e), commit `98d8278`, PR https://github.com/marcosmatosteodoro/mnemonicos-frontend/pull/52.
- Novo `FieldHint` (`src/components/field-hint.tsx`, `max-w-2xl text-xs text-muted`). Os três campos do form
  de criação usam `<label htmlFor>` + ajuda + controle, com `aria-describedby` ajuda→erro.
  `IMAGE_ACCEPT`/`IMAGE_MAX_SIZE_MB` são o ponto único, e o form de edição passou a usar a mesma constante, com o mesmo valor.
- Copy: versão enxuta do product-designer, com o mesmo sentido do brief. Produtos ainda valida.
- Gates: code-reviewer aprovado (retry único re-revisado); product-designer aprovado (contraste 6,39:1 no claro e
  5,44:1 no escuro); security-engineer aprovado, sem achados; **qa parcial**: 26/26 testes de componente
  passando, verificação na tela real não rodada, porque o login local foi bloqueado pelo classificador de permissões
  (credencial DEV) e o probe acusou placeholder no realm `editor`. Lição: LRN-067/LRN-068 com reincidência 1
  em `docs/_meta/learning-log.md`, e proposta ao plugin.
- Docs: `GUIA-DE-USO.md` (seção 4 + data) e o doc online sincronizado; guideline frontend §Campo obrigatório
  (bullet "Texto de ajuda" + legenda corrigida); `docs/_meta/jira.KAN.md` com os pares `4`/`6`/`7` medidos na Tarefa.
- Jira: KAN-238 Backlog `4` → Tarefas pendentes `6` → Em andamento `7` → Análise pendente (2026-10-18).
- Merge do Diretor: PR #52 em 2026-10-18 (`33a94d9`). KAN-238 Análise pendente `8` → Em análise `11` →
  Concluído. Sem épico pai.
