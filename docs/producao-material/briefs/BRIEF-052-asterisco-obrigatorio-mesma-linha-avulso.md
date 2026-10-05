# BRIEF-052: Asterisco de campo obrigatório na mesma linha do rótulo

**Slug**: producao-material
**Tipo**: avulso (bug)
**Status**: Aberto (card local, aguardando sync com o Jira)
**Data**: 2026-10-05
**Origem**: Diretor, em sessão, com print de `/content/new` (tema escuro). O acesso ao Jira está retirado.
**Jira**: KAN-228 (Tarefa, status medido: Backlog; sincronizado em 2026-10-05); link `Relates` → KAN-216

## Pedido como dito
"Todos os pontos da aplicação que estão com "*" estão qeubrando a linha como na imagem, isso ta
errado deveria ser texto * na mesma linha"

Print: em "Novo conteúdo bruto", os rótulos "Texto normativo" e "Disciplina" aparecem numa linha e
o `*` vermelho logo abaixo, numa linha própria, antes do campo.

## Interpretação
É uma regressão do KAN-216 (PR #39, `9c1e179`, já na `origin/main`), que introduziu o
`RequiredMark` (`src/components/required-mark.tsx`) depois do texto do rótulo. Em vários
formulários, o `<label>` envolve o controle e usa `className="flex flex-col gap-1 …"`. Nesse
layout, o texto do rótulo e o `<span>*</span>` viram **dois itens flex separados**, empilhados na
vertical. Resultado: `texto` / `*` / `campo`, em vez de `texto *` / `campo`.

Inventário na `origin/main` em 2026-10-05: 20 usos de `<RequiredMark />` em 11 arquivos
(`content-form`, `content-version-history`, `contrast-form`, `create-user-form`, `flashcard-form`,
`login-form`, `mnemonic-strip-board`, `password-field`, `pegadinha-field`, `rule-breakdown-form`,
`visual-library-board`). Quebram os usos dentro de label `flex-col`. Login, criar usuário e
`password-field` usam um `<label>` próprio, separado do controle, e já mostram `texto *` na mesma
linha.

O alvo é **todo** rótulo obrigatório da aplicação no formato `texto *` numa linha só, com o
controle embaixo.

## Premissas decididas
- **P-052-001** [assumido]: a correção agrupa o texto e o `*` num único item inline (por exemplo,
  `<span>Texto normativo<RequiredMark /></span>`, ou uma API do próprio `required-mark` que receba
  o texto). O layout `flex-col` dos labels fica como está, e o espaço entre texto e asterisco
  continua o `ml-0.5` atual. A forma exata fica com o developer, desde que seja um padrão único,
  e não um conserto diferente em cada tela.
- **P-052-002** [assumido]: a semântica do KAN-216 não muda. O `*` continua `aria-hidden`, fora do
  nome acessível; quem informa a obrigatoriedade é o `aria-required` do controle; a
  `RequiredLegend` fica intacta.
- **P-052-003** [assumido]: é um card novo com link para o KAN-216, sem reabrir o KAN-216, que já
  foi mergeado e fechado. O Diretor pode preferir reabrir.

## Fora de escopo
- Mudar quais campos são obrigatórios, a cor ou o glifo do asterisco, ou o texto da legenda.
- Refazer o layout dos formulários além do agrupamento rótulo + asterisco.

## Critério de aceite
- Em todos os usos de `RequiredMark` da aplicação, o `*` aparece **na mesma linha** do texto do
  rótulo, logo depois dele, e o controle continua abaixo. Vale nos temas claro e escuro, em 360,
  768 e 1280px. Um rótulo longo pode quebrar em 360px, mas o `*` acompanha a última palavra e
  nunca fica sozinho numa linha.
- Os usos que já estavam certos (login, criar usuário, `password-field`) continuam iguais.
- O nome acessível de cada controle continua só com o texto do rótulo, sem `*`, e o
  `aria-required="true"` continua no controle. As provas do KAN-216 seguem verdes.
- Há uma prova automatizada que pega a regressão: o texto e o `*` de um rótulo obrigatório são o
  mesmo item de layout, e não irmãos diretos num container `flex-col`. Ela precisa falhar se o
  `RequiredMark` voltar a ser filho direto de um label `flex-col`.
- `npm run validate` e `npm run build` limpos; nenhuma cor literal nova.

## Gates previstos
code-reviewer (régua avulsa) · product-designer (gate 11: markup e estilos em todas as telas com
formulário) · qa (gate 9: caminhar as telas com campo obrigatório nos 2 temas e 3 larguras) ·
security-engineer n/a (só markup e estilo, sem superfície sensível) · performance-engineer n/a.

## TASKs
<nenhuma — o brief é a unidade de execução>

## Execução
- 2026-10-05: implementado no frontend, branch `feat/producao-material-asterisco-mesma-linha`,
  commit `9f4c93c` (developer). `RequiredLabelText` em `required-mark.tsx` aplicado nos 17 usos
  em label `flex-col`; prova estática + de renderização em `required-mark.test.tsx`.
- Guideline frontend (§Campo obrigatório) corrigido; lição em
  `guidelines/project/lessons/elemento-inline-ao-lado-de-texto-e-verificado-no-layout-real-do-container.md`.
- Gates: product-designer aprovado (leitura de código; Playwright indisponível). qa (gate 9,
  360/768/1280px nos 2 temas) **não rodado — Playwright MCP falhou ao conectar**; fica ao Diretor
  na revisão do PR.
