# BRIEF-051: "Conteúdos brutos" vira botão "Voltar" na criação e na edição de Conteúdo bruto

**Slug**: producao-material
**Tipo**: avulso
**Status**: Aberto (card local, aguardando sync com o Jira)
**Data**: 2026-10-05
**Origem**: Diretor, em sessão, com o acesso ao Jira retirado
**Jira**: pendente de sync. Sem acesso ao conector em 2026-10-05; tipo pretendido **Tarefa** (`issueType.standalone`, `10008`), card único

## Pedido como dito
"Em https://mnemonicos-frontend.vercel.app/content/new o botão que retorna a página anterior chamado de "Conteúdos brutos" pode e deve ser simplesmente Voltar
Na edição tbm, algo como https://mnemonicos-frontend.vercel.app/content/01a07bdd-38f8-70e9-8a42-2278fa573c31
Na edição é ainda pior que ta como link e deveria ser botão

Só um jira mesmo para isso tudo"

## Interpretação
Nas duas estações do Conteúdo bruto, a navegação de volta no cabeçalho da página muda de rótulo e
de aparência:

- `/content/new`: `src/app/(interno)/content/new/page.tsx`
- `/content/<id>`: `src/app/(interno)/content/[id]/page.tsx`

Na `origin/main` (conferido em 2026-10-05), as duas apontam para `href="/content"` com o texto
"Conteúdos brutos", mas com aparências diferentes:

- criação: já tem aparência de botão (`ACTION_LINK_CLASS`, de `src/lib/action-link-class.ts`);
- edição: ainda é link de texto (`text-sm font-medium text-link underline`). É o "ainda pior" do
  pedido.

Depois desta mudança:

1. o rótulo passa a ser **"Voltar"** nas duas;
2. a edição ganha a mesma aparência de botão da criação (`ACTION_LINK_CLASS`).

## Premissas decididas
- **P-051-001** [assumido]: o destino continua `/content` (a listagem), e não "a página anterior
  do histórico" (`router.back()`). Assim o destino não muda conforme a origem da navegação: quem
  abre a URL direto ou vem de outra aba também volta para a listagem. Além disso, a página segue
  como Server Component. Pode ser vetado pelo Diretor.
- **P-051-002** [assumido]: "deveria ser botão" se refere à **aparência**. A semântica continua de
  navegação, então o elemento continua sendo um `<a>`/`Link` com estilo de botão, e não um `<button>`
  com `onClick`. Isso preserva abrir em nova aba, o href visível e o papel `link` para leitor de tela.
- **P-051-003** [assumido]: o estilo de botão é o `ACTION_LINK_CLASS` que a criação já usa:
  `surface-card`, foco do produto, sem cor literal nova. As duas páginas ficam com a mesma classe.

## Fora de escopo
- As outras telas que também têm o link "Conteúdos brutos": `content/[id]/breakdown/page.tsx` e
  `content/[id]/tira/page.tsx`. A tira também tem "Voltar ao conteúdo". Só entram com novo pedido
  do Diretor.
- O link "Novo conteúdo bruto" da listagem `/content`.
- Qualquer mudança em `ContentForm` ou nos painéis da edição.

## Critério de aceite
- Em `/content/new` e em `/content/<id>`, o cabeçalho mostra um único controle de volta com o
  nome acessível **"Voltar"** e `href="/content"`. Nenhum dos dois cabeçalhos mostra mais o texto
  "Conteúdos brutos".
- O controle tem aparência de botão (borda/fundo e área de toque de botão, sem sublinhado),
  idêntica nas duas páginas, nos temas claro e escuro, em 360, 768 e 1280px.
- O foco por teclado continua visível. O controle continua acessível nos estados de carregando,
  erro e sucesso do formulário (cabeçalho da página, fora do `ContentForm`).
- Os testes que hoje provam o link "Conteúdos brutos" nessas duas páginas
  (`content-form.test.tsx`, bloco "navegação de volta") passam a provar o nome "Voltar", o
  `href` e a ausência do rótulo antigo. Os testes da Quebra e da Tira não mudam.
- `npm run validate` e `npm run build` limpos; nenhuma cor literal nova.

## Gates previstos
code-reviewer (régua avulsa) · product-designer (gate 11: markup, estilo e copy) · qa (gate 9:
comportamento observável na tela) · security-engineer n/a (sem superfície sensível) ·
performance-engineer n/a (sem superfície de custo).

## TASKs
<nenhuma — o brief é a unidade de execução>

## Execução
<a preencher na implementação>
