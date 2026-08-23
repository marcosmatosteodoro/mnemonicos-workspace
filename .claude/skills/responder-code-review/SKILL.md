---
name: responder-code-review
description: Responde comentários de revisor humano num Pull Request do GitHub, no registro da casa — curto, objetivo, sem markdown pesado, uma ideia por parágrafo, com a medição que sustenta e o 🤖 de autoria. Ative ao responder apontamentos de code review, ao redigir resposta a revisor, ou quando uma resposta já postada estiver longa/floreada e precisar ser enxugada.
---

# Responder code review no registro da casa

Regra medida, não gosto. A calibração veio do workspace `b2b-workspace` (2026-08-13,
PR 2087): as respostas produzidas por IA tinham **média de 1550 caracteres e 14 de 15
usavam negrito/tabela/cerca de código**; os comentários dos revisores humanos do mesmo
PR tinham **mediana de ~100 caracteres e 1 de 12 usava qualquer markdown**. Depois da
reescrita: média **694**, zero com markdown pesado — e a informação não se perdeu.

**Esta medição é herdada, não medida aqui.** Assim que houver revisor humano recorrente
nos PRs de `mnemonicos-*`, refaça a medição (o bloco *Antes de fechar* traz o comando) e
substitua os números acima pelos do time real. Até lá, a régua vale como default: enxuto
é mais próximo do registro humano do que floreado, em qualquer time.

## O registro da casa

- **Frases curtas.** Uma ideia por parágrafo, parágrafos separados por linha em branco.
- **Sem negrito, sem tabela, sem cerca de código, sem cabeçalho.** Identificador vai cru
  (`scheduleNext`, `disciplines.service.ts:31`), não em backtick nem em bloco.
- **Sem preâmbulo e sem elogio.** Não abra com "Baita achado", "Boa observação", "Você
  está certo, e...". Se o apontamento procede, diga que procede e mostre o número.
- **Sem meta-narrativa da própria resposta.** Nada de "respondo os três", "detalhando o
  ponto", "complemento com".
- **Enumeração só quando há mais de um assunto** na mesma thread. Aí `1.` `2.` `3.` simples.
- **Registro direto, sem agressividade**: "Entendo que...", "Preciso entender...",
  "Realmente é necessário...?".

## O que a resposta precisa ter

Enxugar não é apagar conteúdo. Cada resposta mantém:

1. **Veredito na primeira linha** — procede e foi corrigido / procede e não foi feito /
   não procede, com o motivo.
2. **O commit**, quando houve correção. SHA curto, cru.
3. **A medição que sustenta**, com número. "0 de 645 registros têm o campo preenchido"
   vale mais que três parágrafos de raciocínio. Se você não mediu, não afirme.
4. **A âncora** em `arquivo:linha` para o que você está alegando.
5. **O que ficou de fora**, e a issue/card onde foi registrado.
6. 🤖 **no início**, sempre — o Diretor exige saber o que foi respondido por IA.

## O que nunca entra

- **Apontamento recusado se responde com medição, nunca com opinião.** "Mantive porque é
  o padrão" só vale acompanhado dos exemplares: `health.routes.ts:12-18` e
  `disciplines.routes.ts:10-16`.
- **Nunca dar por feito o que não foi feito.** Pendência aberta se declara aberta, na
  própria resposta. O revisor vai ler a thread, não o board.
- **Nunca prometer o que depende de decisão do Diretor.** Diga que está registrado e por
  que você não decidiu.
- **Nunca reproduzir segredo.** Token, `DATABASE_URL` e cURL com `Authorization`
  aparecem em comentário de PR com frequência; ao citar o relato do revisor, cite o
  sintoma, jamais o cabeçalho ou o valor.

## Mecânica (GitHub, via `gh`)

Requer o GitHub CLI autenticado (`gh auth status`). O `start.sh` do workspace instala e
avisa se faltar. `OWNER/REPO` é `marcosmatosteodoro/mnemonicos-backend` ou
`.../mnemonicos-frontend` — o workspace não tem PRs próprios, os PRs são dos dois repos.

**GitHub tem duas famílias de comentário, e elas não se misturam** — errar a família é o
erro mais comum aqui:

- **Review comment**: ancorado numa linha do diff. É o que o revisor usa para apontar
  código, e é onde quase toda resposta vai.
- **Issue comment**: a conversa geral do PR, sem âncora de linha. Não aceita resposta
  aninhada — só outro comentário de topo.

Ler os apontamentos, com os ids que você vai precisar:

```bash
# review comments (ancorados no diff), já com a thread a que pertencem
gh api --paginate "repos/$OWNER/$REPO/pulls/$PR/comments" \
  --jq '.[] | {id, in_reply_to_id, user: .user.login, path, line, body}'

# conversa geral do PR
gh api --paginate "repos/$OWNER/$REPO/issues/$PR/comments" \
  --jq '.[] | {id, user: .user.login, body}'
```

Responder **na thread** do revisor (não como comentário novo de topo):

```bash
gh api --method POST "repos/$OWNER/$REPO/pulls/$PR/comments/$COMMENT_ID/replies" \
  -f body="$(cat resposta.md)"
```

`$COMMENT_ID` é o id do comentário **raiz** da thread — o que tem `in_reply_to_id: null`.
Responder ao id de uma resposta intermediária funciona, mas o GitHub reancora tudo na
raiz mesmo assim.

**Editar** uma resposta já postada — é assim que se enxuga sem poluir a thread com uma
segunda mensagem:

```bash
# review comment
gh api --method PATCH "repos/$OWNER/$REPO/pulls/comments/$COMMENT_ID" \
  -f body="$(cat resposta.md)"

# issue comment (conversa geral)
gh api --method PATCH "repos/$OWNER/$REPO/issues/comments/$COMMENT_ID" \
  -f body="$(cat resposta.md)"
```

Note os caminhos diferentes: review comment é `pulls/comments/{id}`, **sem** o número do
PR; issue comment é `issues/comments/{id}`. Trocar um pelo outro devolve 404.

Marcar a thread como resolvida exige **GraphQL** — a REST não expõe resolução:

```bash
# descobrir os threadId (base64, não é o id numérico do REST)
gh api graphql -f owner="$OWNER" -f repo="$REPO" -F pr="$PR" -f query='
  query($owner:String!,$repo:String!,$pr:Int!){
    repository(owner:$owner,name:$repo){
      pullRequest(number:$pr){
        reviewThreads(first:100){ nodes { id isResolved comments(first:1){ nodes { body } } } }
      }}}'

gh api graphql -f threadId="$THREAD_ID" -f query='
  mutation($threadId:ID!){ resolveReviewThread(input:{threadId:$threadId}){ thread { isResolved } } }'
```

Resolva **só** a thread que você de fato endereçou. Fechar thread que você não resolveu
é o equivalente a dar por feito o que não foi feito.

Sempre escreva o corpo num arquivo e passe com `-f body="$(cat …)"`. Corpo inline em
shell come as quebras de linha, e a resposta chega com os parágrafos colados.

## Antes de fechar

Confira por medição, não por impressão:

```bash
gh api --paginate "repos/$OWNER/$REPO/pulls/$PR/comments" > comments.json

# tamanho das suas respostas
jq -r '[.[] | select(.body|test("^🤖")) | .body|length]
       | "n=\(length) menor=\(min) maior=\(max) media=\((add/length)|floor)"' comments.json

# markdown pesado — tem de ser 0
jq -r '[.[] | select(.body|test("^🤖")) | select(.body|test("\\*\\*|^\\||```"))] | length' comments.json
```

E confira que **nenhum apontamento de revisor ficou sem resposta**: as raízes de thread
(`in_reply_to_id == null`) que não são suas e não aparecem como `in_reply_to_id` de
nenhuma resposta sua.

```bash
jq -r --arg me "$(gh api user --jq .login)" '
  ([.[] | select(.in_reply_to_id != null) | .in_reply_to_id] | unique) as $respondidos
  | [.[] | select(.in_reply_to_id == null) | select(.user.login != $me)
         | select((.id | IN($respondidos[])) | not) | {id, path, line}]' comments.json
```

Resultado tem de ser `[]`. Aviso de bot ou de CI ("PR extensa demais", check falhou)
**não** é apontamento e não recebe resposta.
