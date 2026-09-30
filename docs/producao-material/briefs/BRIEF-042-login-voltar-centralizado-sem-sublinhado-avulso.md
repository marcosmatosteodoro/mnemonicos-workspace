# BRIEF-042: Link "Voltar para o início" do `/login` centralizado e sem sublinhado

**Slug**: producao-material
**Tipo**: avulso
**Status**: Concluído (PR #22 mergeado pelo Diretor, `05cc3e1`, 2026-09-30)
**Data**: 2026-09-30
**Largada**: 2026-09-30T13:56:36-0300
**Origem**: Diretor, em sessão, depois de mergear o PR #21 (BRIEF-039)
**Jira**: KAN-177 (ajuste da mesma entrega; sem card novo, e o acesso ao Jira está retirado)

## Pedido como dito
"Eu fiz merge, porém teve um pequeno detalhe que quero que vc mude
O texto Voltar para o início deve ficar centralizado e sem a linha de baixo, faça esses ajustes e depois abra PR"

## Interpretação
No cartão do `/login`, o link "Voltar para o início" (`src/app/login/page.tsx`) passa a ficar
centralizado na largura do painel, em vez de alinhado à esquerda (`self-start`), e perde o
sublinhado. O resto continua igual: texto, destino `/`, `text-sm`, `text-muted`, fora do `<form>`,
foco visível em `--link`, nunca desabilitado durante "Entrando…".

## Premissas decididas
- **P-042-001** [assumido]: "sem a linha de baixo" vale para todos os estados, repouso e hover.
  Nenhum `underline`/`hover:underline` permanece. O foco por teclado continua com o outline de 2px
  (é contorno, não linha de baixo), porque o foco visível é critério do KAN-177.
- **P-042-002** [assumido]: "centralizado" é centralização horizontal no painel do cartão. O
  título "Entrar" e o formulário continuam alinhados à esquerda (FR-030-014 não muda).
- **P-042-003** [decisão do Diretor, registrada]: esta ordem substitui a correção do gate 11 do
  BRIEF-039 (sublinhado em repouso como marca de link). A troca aceita é esta: parado, o link volta
  a depender de cor, tamanho e posição para ser reconhecido. A centralização o separa do
  "Entrando…", que fica à esquerda. A lição
  `link-discreto-reduz-cor-e-tamanho-nunca-a-marca-de-link` é contestada por esta decisão e
  precisa ser reformulada.

## Fora de escopo
- Qualquer outra mudança no cartão, no formulário ou nas mensagens.
- Área de toque maior (sugestão AAA, segue fora).

## Critério de aceite
- O link fica centralizado horizontalmente no painel do cartão, em 360/768/1280px, nos dois temas.
- Não há sublinhado em repouso nem no hover.
- O foco por teclado continua visível, e o link continua depois do botão na tabulação.
- Os testes seguem provando texto, `href="/"`, posição fora do form, inventário fechado do cartão,
  Enter envia e clique não prevenido. A asserção de `underline` é trocada pela prova de ausência
  de sublinhado e pela prova de centralização.
- `npm run validate` e `npm run build` limpos; nenhuma cor literal nova.

## TASKs
<nenhuma — o brief é a unidade de execução>

## Execução
- **Implementado por**: developer. Em `page.tsx`, `self-start` virou `self-center` e saíram `underline`/`underline-offset-4`; `page-back-link.test.tsx` ganhou as provas de ausência de sublinhado (com controle positivo) e de centralização. Commit `9b2e920`, branch `feat/producao-material-login-voltar-centralizado`, PR https://github.com/marcosmatosteodoro/mnemonicos-frontend/pull/22.
- **Revisado por**:
  - code-reviewer (régua avulsa): APROVADO. 6 mutantes mortos, validate 58/743.
  - product-designer: APROVADO. Centro 0px; sem sublinhado em repouso, hover, foco e "Entrando…". **Risco aceito (P-042-003)**: em 360px o texto do link começa 14px depois do fim do "Entrando…" (66px em 768/1280). Sugestão de hover por cor não aplicada (fora do pedido).
  - qa (screen-verify): VERIFICADO nas 6 combinações. Capturas em `thoughts/screen-verify/gate9-brief-042/`.
  - security-engineer: n/a (só classes de estilo).
- **Lição**: `link-discreto-reduz-cor-e-tamanho-nunca-a-marca-de-link` contestada (1) e reformulada: a marca de link vai além da cor, com sublinhado por default e posição isolada aceita. Ganhou a regra de medir a folga pela extensão do texto em 360px.
