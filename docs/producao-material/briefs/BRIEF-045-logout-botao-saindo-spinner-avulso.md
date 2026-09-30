# BRIEF-045: botão "Sair" do header mostra "Saindo" com spinner durante o logout

**Slug**: producao-material
**Tipo**: avulso (decisão 4.86)
**Status**: Aceito (ACEITA, 2026-09-30; PR #25 aberto, aguardando revisão e merge do Diretor)
**Data**: 2026-09-30
**Largada**: 2026-09-30T17:27:52-0300
**Origem**: Diretor, em sessão ("Crie outro jira e implemente, deve ser feito o mesmo para sair"), logo após o merge do KAN-185
**Jira**: KAN-186 (Tarefa, criada nesta largada; `Relates` KAN-185)

## Pedido como dito
> Crie outro jira e implemente, deve ser feito o mesmo para sair

O card KAN-186 transcreve o pedido no formato do KAN-185: com o logout em andamento, o botão
"Sair" do header vira "Saindo" com o spinner e fica desabilitado, e o texto solto "Saindo…"
abaixo dele deixa de existir. Na falha, o botão volta a "Sair" com a mensagem de erro de hoje.

## Por que é avulso
A SPEC-036 (FR-036-004, AC-036-004/014) e a SPEC-002 (FR-002-023) prometem os três estados
observáveis do logout: **em andamento** (controle desabilitado + indicador de progresso),
sucesso e falha. Nenhuma delas fixa o texto "Saindo…" nem o lugar dele. O botão com spinner
continua cumprindo a promessa, então ela não muda. O padrão também já foi decidido no
KAN-185 (BRIEF-043, P-043-001..006): reuso do `Spinner`, região viva oculta e fim da
opacidade. Não há alternativa técnica a escolher, e por isso não há DEC.

## Critério de aceite
Os critérios do card KAN-186, com as premissas abaixo:
- **P-045-001** [assumido]: rótulo **"Saindo"**, sem reticências, com o `Spinner` do
  KAN-185 à esquerda. O par fica centralizado e o botão não muda de largura nem de altura.
  Largura fixa ou mínima, se precisar, é decisão técnica do developer, cobrada pelo gate 11.
- **P-045-002** [assumido]: o anúncio acessível fica numa região `role="status"`
  `sr-only`, **sempre montada**, vazia fora do logout e com "Saindo" só durante ele. Na falha
  ela se esvazia, e o erro segue só no `role="alert"`. O `aria-busy` fica no botão, como
  hoje. A região não pode ser descendente de nó com `aria-busy="true"`. É o mesmo padrão de
  P-043-001.
- **P-045-003** [assumido]: o botão "Sair" desabilitado deixa de usar `disabled:opacity-60`.
  Rótulo e spinner ficam nos tokens de texto já medidos para AA nos dois temas (NFR-036-003).
  Isso vale só para este botão.
- **P-045-004** [assumido]: o bloco do header não muda de altura durante o logout. O texto
  solto sai e a região oculta fica fora do fluxo. A mensagem de erro da falha continua
  aparecendo abaixo do botão, como hoje, porque isso é comportamento de falha e não de
  andamento.
- **P-045-005** [assumido]: a lógica do logout não muda (`handleLogout`, `router.push('/login')`,
  mensagem genérica, "Entrar" sem sessão, estado neutro enquanto a sessão não resolveu).
- nenhuma cor literal nova; lint, typecheck e suíte do frontend limpos.

## Fora de escopo
- Botão "Entrar" do header (navegação, sem estado de envio).
- Lógica de logout, sessão e `useMeSilentQuery`.
- Outros botões com `disabled:opacity-60` do app.

## Decomposição
nenhuma — o brief é a unidade de execução (um executor, um diff no mnemonicos-frontend).

## Estimativa
- **Base**: pedido (BRIEF-045/KAN-186, P-045-001..005, rota avulsa sem SPEC nem DEC) · análogo
  direto BRIEF-043/KAN-185 (mesmo padrão; ~15 min de implementação com gates numa parede de ~31
  min) · ficha (review, security e screenVerify ativos) · calibração: 5 demandas após a
  descontinuidade 4.437, nenhuma na rota avulsa. Corretor: as duas emendas de 1 componente
  fecharam abaixo do piso, então o piso fica perto da implementação do BRIEF-043 e o teto guarda
  gordura só para retry e gate 9.
- **Dimensão**: ~1 wave · ~0 tasks (brief como unidade de execução, porte de ~1 small).
- **Por fase**: forja 0–0,05 · artefatos 0–0,05 · implementação 0,1–0,35 · gates 0,15–0,6
- **Total**: 0,25–1,05h (horas de ciclo, não prazo de calendário)
- **Confiança**: média. O análogo é medido e tem o mesmo padrão. A incerteza está no gate 9
  (estado passageiro "Saindo" com sessão e redirecionamento para `/login`) e na falta de
  calibração da rota avulsa.
- **Premissas**: `Spinner` reusado sem mudar a API · tokens do botão "Sair" já atendem AA sem
  opacidade · região viva fora do `aria-busy` sem reestruturar o header · `handleLogout` intacto,
  sem backend · gates 1–7, 8, 9 e 11 em paralelo, 10 n/a, com margem para 1 retry e 2 rodadas do
  gate 9 · PR, merge e card fora da faixa.
- **Lacunas**: nenhuma

## Aceitação (PO)
**ACEITA** (2026-09-30), sem ressalvas que conflitem com o brief. P-045-001..005 foram entregues, com evidência por teste e pelos gates 9 e 11 em app real. Limite da prova: o logout real contra o backend não foi exercido (`auth/me` e logout interceptados). O brief exige `handleLogout` intacto, e o código confirma que ele não mudou.

## Pendências do Diretor
- Revisar e mergear o PR #25 (`feat/producao-material-logout-botao-saindo`, `0edec2a`).
- Jira sem acesso: a fila para reconciliar está em `docs/producao-material/tracker-local-KAN-186.md` (finish-dev → `31` e comentário do PR).
- Sugestões fora de escopo, para card futuro se quiser: "Entrar" sem `min-w` (larguras diferentes entre páginas); foco cai no `body` ao desabilitar (já acontecia antes, vale também para o login); duplo clique síncrono antes do re-render (já acontecia antes, revogação idempotente).

## Cronologia
- 2026-09-30T17:27:52-0300 — largada (rota avulsa).
- 2026-09-30T17:44:31-0300 — implementação, gates e entrega (gates 8, 9 e 11 de primeira; gates 1–7 com 1 retry e re-gate aprovado; aceitação ACEITA; commit `0edec2a`, PR #25; Jira em fila local por ordem do Diretor).
