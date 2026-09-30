# BRIEF-038: Remover o "Entrar" duplicado do corpo da página inicial pública

**Slug**: producao-material
**Tipo**: avulso
**Status**: Aberto
**Data**: 2026-09-30
**Largada**: 2026-09-30T12:52:10-0300
**Origem**: key do tracker (rota pull, KAN-176)
**Jira**: KAN-176

## Pedido como dito
> Na página inicial pública (sem sessão), aparecem dois botões **"Entrar"**: um no
> cabeçalho, à direita, e outro no corpo da página, logo abaixo do texto de apresentação
> ("Memorizar não é repetir: é codificar."). A duplicação é redundante: o do cabeçalho já
> cumpre a função.
>
> Remover o botão **"Entrar" do corpo da página**. O botão do cabeçalho continua como está.
>
> Critérios de aceite (do card):
> - Sem sessão, a página inicial mostra **um único** "Entrar", no cabeçalho.
> - O "Entrar" do cabeçalho continua levando ao login, e o controle de sessão do cabeçalho
>   ("Entrar"/"Sair") não muda.
> - O título, o texto de apresentação e a seção "Técnicas do acervo" continuam iguais, sem
>   espaço vazio no lugar do botão.
> - Vale nos temas claro e escuro, no desktop e no celular.
> - A suíte do frontend passa, com o teste da página inicial atualizado para a ausência do
>   link no corpo.

## Interpretação
Remover o `<Link href={INTERNAL_HOME}>Entrar</Link>` da seção de apresentação de
`mnemonicos-frontend/src/app/page.tsx` e trocar o teste de
`mnemonicos-frontend/src/app/page.test.tsx`, que hoje exige esse link (AC do KAN-74),
por um teste da ausência dele. Só frontend, sem contrato de API.

**Promessa substituída (decisão do Diretor, triagem de 2026-09-30):** esse link é a
entrega do KAN-74 (`BRIEF-015-home-entrypoint-logado-avulso.md`). O critério de aceite de
lá prometia a quem tem sessão um link direto de `/` para `/studio`. Com sessão, o
cabeçalho mostra só "Sair", então esse link era o único caminho de `/` até a área
interna. Perguntado sobre isso, o Diretor decidiu que **usuário com sessão não deve ver a
área não logada**. Entrar em `/` com sessão passa a levar direto a `/studio`, o que foi
aberto como **KAN-180** (ciclo próprio, muda a guarda de rota). Com isso, o AC do KAN-74
deixa de valer para a home, e o caminho do usuário logado até o estúdio passa a ser do
KAN-180.

## Fora de escopo
- Qualquer mudança em `SiteHeader`, `AuthControl`, `proxy.ts` ou no mecanismo de sessão.
- Redirecionar quem tem sessão para fora de `/`: isso é o KAN-180.
- Redesenho da página inicial além da remoção do botão.

## Critério de aceite
- Sem sessão, `/` mostra **um único** controle rotulado "Entrar", o do cabeçalho. O
  corpo da página não tem nenhum link ou botão "Entrar".
- O "Entrar" do cabeçalho continua levando a `/login`, e o `AuthControl`
  ("Entrar"/"Sair"/neutro) não muda: diff sem toque em `site-header.tsx` nem em
  `auth-control.tsx`.
- O título "Memorizar não é repetir: é codificar.", o parágrafo de apresentação e a seção
  "Técnicas do acervo" (4 cartões) continuam com o mesmo texto e na mesma ordem. Nenhum
  elemento vazio ou espaçador fica no lugar do botão: a seção de apresentação termina no
  parágrafo.
- Vale nos temas claro e escuro, em largura de celular (360px) e de desktop.
- `page.test.tsx` prova a ausência do link "Entrar" no corpo, com oráculo que falharia se
  o link voltasse. `npm --prefix mnemonicos-frontend test`, `lint` e `typecheck` passam.

## Ordem de merge (pendência do Diretor)
Mergear este brief **antes** do KAN-180 abre uma janela em que o usuário logado que clica
no logo do cabeçalho cai em `/` sem link para `/studio` (só digitando a URL). A decisão
do Diretor foi seguir com o KAN-176 mesmo assim. A ordem de merge fica com ele.

## TASKs
<nenhuma — o brief é a unidade de execução>

## Execução
- **Implementado por**: developer, em `mnemonicos-frontend` na branch
  `feat/producao-material-home-sem-entrar-duplicado` (de `origin/main` `f975939`). Mudou
  `src/app/page.tsx` (tira o `Link` e 2 imports órfãos) e `src/app/page.test.tsx` (âncora
  h1/h2 mais um `it` de ausência de link ou botão /entrar/i, com o h1 no mesmo render).
- **Revisado por**:
  - gates 1–7 (`code-reviewer`): REPROVADO no 1º passe. O `it` de ausência passava com
    `HomePage` retornando `null`, o que viola o §7 do `next-16.md`. Retry 1 levado ao
    developer, depois APROVADO no re-review. Mutantes M1 (link), M2 (botão) e M3 (`null`)
    morrem, conferidos pelo nome do teste vermelho.
  - gate 8 (`security-engineer`): APROVADO, sem achado. O link não era controle de acesso.
    O gitleaks não rodou porque não está instalado.
  - gate 9 (`qa`): VERIFICADO em tela real como anônimo. Os 4 itens do critério passam
    em claro e escuro, 360px e 1280px, com capturas em
    `thoughts/screen-verify/kan176-*.png`. Suíte com 725/725.
  - gate 10: n/a, sem superfície de custo.
  - gate 11 (`product-designer`): APROVADO, sem achado.
- **Lição**: `guidelines/project/lessons/assercao-de-ausencia-em-render-carrega-controle-positivo-no-mesmo-it.md`
  (em observação).
- **Commit**: `6ff6519` (mnemonicos-frontend, a pedido do Diretor), PR #20 → `main`, aberto em 2026-09-30. Merge é ato do Diretor.
