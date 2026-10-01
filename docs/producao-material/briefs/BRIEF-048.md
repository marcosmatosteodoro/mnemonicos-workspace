# BRIEF-048: Tela de gestão de usuários (ADMIN)

**Slug**: producao-material
**Status**: Emitido
**Data**: 2026-09-30
**Largada**: 2026-09-30T21:07:04-0300
**SPEC**: SPEC-048
**Jira**: KAN-179

## Pedido como dito
"/keelson:auto --from=KAN-179 "vC ESTÁ SEM acesso ao jira no momento, consegue seguir assim?""

Card KAN-179 (História, sem épico-pai), lido via conector em 2026-09-30 16:41, antes de o
acesso cair: "Tela de gestão de usuários (ADMIN): listar, criar, desativar e redefinir senha".
Pede a tela "Usuários" na área interna, visível e acessível só para ADMIN, usando as 4
operações que já existem (`GET /users`, `POST /users`, `PATCH /users/:id/disable`,
`POST /users/:id/reset-password`) e os hooks já prontos em `src/store/api.ts`. Só frontend,
sem endpoint novo. Critérios de aceite do card: acesso (ADMIN entra; EDITOR vê "Você não tem
permissão para ver esta página." e não vê o item de menu; sem sessão vai ao login) · listar
(tabela nome/e-mail/papel/situação, paginada, busca, estados carregando/vazio/erro) · criar
(nome, e-mail, papel, senha ≥ 12 com mostrar/ocultar; erros por campo em pt-BR; e-mail
duplicado mostra a mensagem do servidor; botão desabilitado ao enviar; conta aparece sem
recarregar; formulário limpo; senha nunca reexibida nem guardada no navegador) · desativar
(confirmação dizendo que a pessoa será desconectada; recusa do último ADMIN sem quebrar a
tela; situação atualiza) · redefinir senha (mesma regra; confirmação de que as sessões serão
encerradas; sucesso sem exibir a senha) · geral (contraste AA claro/escuro, teclado e foco
visíveis, tabela com rolagem interna no celular; testes para cada um desses comportamentos).
Fora do card: mudar papel, reativar conta, cadastro público e contas de estudante.

## Interpretação do PO
**Contexto**: hoje uma conta interna só nasce pelo seed ou chamando a API na mão. O backend
de gestão de contas existe e foi provado desde a SPEC-002, mas a própria SPEC-002 deixou a
"UI completa de gestão de equipe" fora do escopo.
**Pedido**: uma tela "Usuários", só para ADMIN, em que o ADMIN lista, busca, cria, desativa e
redefine a senha das contas internas, sem tocar no backend.
**Premissas decididas**: abaixo.
**Fora de escopo**: abaixo.

## Premissas decididas
- **Acesso pela sidebar**: o KAN-178 já está na `main` (PR #26). "Usuários" entra como item da
  sidebar, exibido só para ADMIN. Isso revê, para este item, a premissa "nenhum item é filtrado
  por papel" do BRIEF-044/SPEC-044.
- **Rota** `/users` sob `(interno)`, registrada na fonte única `src/lib/internal-routes.ts`. A
  guarda de papel ADMIN vale só para essa sub-rota; o restante da área interna continua EDITOR.
  A autorização real continua sendo do backend.
- **Senha**: nunca reexibida e nunca deixada no estado do navegador depois do envio. Como o
  RTK Query guarda os argumentos da mutation, o PLAN decide o mecanismo e um teste lê o store
  para provar que ela não ficou. Senha nunca vai para log nem para armazenamento local.
- **Paginação e busca** usam o que o backend já oferece; só o hook do frontend ganha o
  parâmetro de página.
- **Componentes reaproveitados**: o campo de senha da SPEC-016 (Q-016-001) e a mensagem de
  "sem permissão" que já existe na casca.
- **Gate 9**: será tentado com contas reais (ADMIN, EDITOR e uma conta descartável para
  desativar/redefinir). Se o ambiente não permitir, fica `pendente_handoff` declarado.
- **Jira sem acesso**: o KAN-179 entra em modo link (nenhum card novo). As operações do
  tracker ficam em `docs/producao-material/tracker-local-KAN-179.md` até o acesso voltar,
  como no KAN-177.

## Fora de escopo
- Mudar o papel de uma conta existente e reativar conta desativada (o backend não tem as
  operações; viram outra história, com backend).
- Cadastro público e contas de estudante.
- Qualquer mudança de backend, endpoint ou migração.
- Alinhamento de header e footer na área interna (BRIEF-047, em curso noutra sessão).
- Troca da própria senha pelo usuário logado.

## Estimativa
- **Base**: card KAN-179 + triagem de 2026-09-30 16:41 · INDEX de `producao-material` ·
  calibração em `guidelines/project/estimates.md` (PLAN-031, PLAN-035, emenda BRIEF-039) e
  Cronologias de BRIEF-030, BRIEF-034, BRIEF-036 e BRIEF-040. Bloco reutilizado da estimativa
  feita nesta sessão (não re-estimado).
- **Dimensão**: ~4 waves · ~6 tasks (~2 small · ~4 medium), faixa de 5–7 tasks.
- **Por fase**: forja 0,3–1h · artefatos 1–2,5h · implementação 5–12h · gates 1–3h.
- **Total**: 7–18h (horas de ciclo, não prazo de calendário).
- **Confiança**: média. Terreno aberto (API, hooks, campo de senha e diálogo já existem),
  mas a área é sensível (senha e autorização) e tem histórico de re-gate de AA e de gate 9
  parcial.
- **Fatores de variância**: senha no estado do RTK Query (+1–2h, provável retry no gate 8) ·
  AA de tabela e diálogos nos dois temas (+1–2h) · gate 9 com contas reais e ação destrutiva
  · rebase com `api.ts` (risco reduzido: KAN-180 e KAN-178 já mergeados) · guarda de papel por
  sub-rota tocando superfície já provada (DEC-003-011) · partição por elemento irmão (LRN-039).

## Cronologia
- specify: 2026-09-30T21:23:34-0300 · correções: 1 · classes: spec-feat-fora-da-5(4) · id-duplicado(4)
- plan: 2026-09-30T21:35:11-0300 · correções: 0
- tasks: 2026-09-30T22:16:56-0300 · correções: 1 · classes: ac-sem-task(1) · janelas: redação 25min/577l
