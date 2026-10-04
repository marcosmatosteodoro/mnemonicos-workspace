# BRIEF-050: Usuários — ações da linha em ícones e reativação de conta

**Slug**: producao-material
**Status**: Aceito
**Data**: 2026-10-01
**Largada**: 2026-10-01T16:48:32-0300
**SPEC**: SPEC-050
**Jira**: KAN-219

## Pedido como dito
"implemente KAN-219"

Card KAN-219 (História, sob o épico KAN-218 "Gestão de usuários v2: ações por ícone,
reativar, editar, excluir permanentemente e página de nova conta"), descrição lida via
conector em 2026-10-01:

> **Primeiro do épico KAN-218**: define a coluna "Ações" que os cards de editar e excluir
> usam.
>
> ## Hoje
> - `mnemonicos-frontend/src/components/users-list.tsx`: coluna "Ações" com dois botões de
>   texto, **Desativar** e **Redefinir senha**.
> - **Não existe reativar**: nem rota no backend, nem tela. O diálogo de desativar avisa "a
>   reativação não está disponível nesta tela".
>
> ## Alvo
> **Linha da tabela**
> - "Ações" passa a ter só **botões de ícone**:
>     - **Ativar/Desativar**: um único ícone que alterna conforme a situação. Conta ativa
>       mostra a ação "Desativar"; conta desativada mostra "Ativar".
>     - **Editar**: abre a página de edição (card próprio do épico). Até lá, o ícone pode
>       ficar fora.
>     - **Excluir**: só em conta **desativada** (card próprio do épico).
> - **Redefinir senha sai da linha** e vai para a página de edição.
> - Cada ícone tem nome acessível com a pessoa ("Desativar Evelin Ferreira…", "Ativar…",
>   "Editar…") e tooltip com o mesmo texto.
> - A confirmação de desativar continua (diálogo atual). Ativar também confirma, com
>   diálogo curto.
>
> **Reativar (backend + frontend)**
> - Rota nova `PATCH /users/:id/enable` (ADMIN, `verifyOrigin`), que faz
>   `disabledAt = null`. Sem migração.
> - Idempotente: reativar conta já ativa não é erro.
> - Ajustar os textos que hoje dizem que a reativação não existe: o diálogo de desativar e
>   a dica do 409 "Já existe uma conta com este e-mail" no criar conta.
> - Log da ação: quem reativou e qual conta.
>
> ## Aceite
> - Linha de conta ativa: ícones Desativar + Editar. Linha de conta desativada: ícones
>   Ativar + Editar + Excluir.
> - Nenhum botão de texto "Redefinir senha" na linha.
> - Reativar: a pessoa volta a conseguir entrar; Situação muda para "Ativa"; EDITOR recebe
>   403 na rota.
> - Ícones operáveis por teclado, com foco visível e nome acessível. Testes de componente e
>   de rota.
>
> ## Decidir no ciclo
> Origem dos ícones (SVG próprio ou biblioteca; mesma decisão do KAN-213).

## Interpretação do PO
**Contexto**: a tela de gestão de usuários (SPEC-048/PLAN-049, KAN-179) já lista, cria,
desativa e redefine senha de contas internas. "Reativar conta desativada" ficou fora de
escopo daquela entrega porque o backend não tinha a operação (registrado no próprio
BRIEF-048) — esta História fecha essa lacuna e, ao mesmo tempo, troca a coluna "Ações" de
botões de texto por ícones, abrindo espaço visual para os cards futuros do épico (Editar,
Excluir permanentemente) que ainda não existem.
**Pedido**: (1) nova rota de backend `PATCH /users/:id/enable` (ADMIN, `verifyOrigin`,
idempotente, sem migração) que reativa conta desativada; (2) coluna "Ações" da tabela de
usuários passa a usar ícones — Ativar/Desativar (alterna por situação, com confirmação) e
placeholder para Editar (fica fora até a página de edição existir); "Redefinir senha" sai
da linha; (3) ajustar os dois textos que hoje dizem que reativar não está disponível.
**Premissas decididas**: abaixo.
**Fora de escopo**: abaixo.

## Premissas decididas
- **"Editar" e "Excluir" não entram nesta fatia**: o próprio card diz que são "card próprio
  do épico". O ícone de Editar fica fora da linha até a página de edição existir (o card
  autoriza: "Até lá, o ícone pode ficar fora"). "Excluir" nem o esqueleto do ícone entra.
- **"Redefinir senha" some da linha sem realocação nesta fatia**: o card manda a ação para
  "a página de edição", que ainda não existe (é outro card do épico). Resultado desta
  História: a ação deixa de estar acessível por tela até a página de edição ser entregue —
  risco aceito, registrado no INDEX como pendência do épico, não lacuna desta entrega.
- **Origem dos ícones**: decisão técnica reversível (DEC), resolvida no PLAN a partir da
  exploração técnica real do projeto — o card já avisa que biblioteca nova passa por
  auditoria de dependência antes de entrar.
- **Rota de reativar espelha `disable`**: mesmo módulo (`users.routes.ts`/
  `users.service.ts`/schema Zod), mesma guarda (`requireRole('ADMIN')` + `verifyOrigin`),
  sem migração (`disabledAt = null` na coluna já existente).
- **Log da reativação** estende o padrão de log de ação administrativa já usado por
  desativar/redefinir senha, sem tabela de auditoria nova.
- **Dois textos a ajustar** (do card): o diálogo de desativar que hoje avisa "a reativação
  não está disponível nesta tela" e a dica do 409 "Já existe uma conta com este e-mail" no
  formulário de criar conta.
- **Gate 9**: tentado com contas reais (ADMIN, EDITOR, conta descartável
  desativada/reativada), mesmo padrão do PLAN-049; sem ambiente, vira `pendente_handoff`.

## Fora de escopo
- Página de edição de conta e a ação "Excluir permanentemente" — cards próprios do épico
  KAN-218, ainda não escritos.
- Realocar "Redefinir senha" para algum outro lugar nesta fatia — ela só é retirada da
  linha; volta quando a página de edição existir.
- Mudar o papel de uma conta (fora de escopo também do BRIEF-048 original).
- Cadastro público e contas de estudante.

## Estimativa
- **Base**: pedido (BRIEF-050 / card KAN-219 com aceite detalhado) · reconhecimento do
  code-scout (`thoughts/local/sessions/20261001-195044-56c31d51/exploration-producao-material.md`,
  confiança alta) · precedente direto BRIEF-048/KAN-179 (mesmo módulo, mesma guarda de
  rota, mesmo `AccountConfirmDialog`; Cronologia: specify 0,3h · plan 0,2h · tasks 0,7h ·
  implementação ~2,4h · entrega 0,3h) · calibração em `guidelines/project/estimates.md` (8
  demandas fechadas, 7 depois da descontinuidade 4.437 — em 6 das 7 o realizado ficou
  abaixo do piso).
- **Dimensão**: ~3 waves · ~4 tasks (~2 small · ~2 medium), faixa de 3–5 tasks. Fatias
  prováveis: (W1) rota `PATCH /users/:id/enable` (service, schema, guarda ADMIN +
  `verifyOrigin`, log, censo de rotas 48→49, testes de rota — medium) · (W1) origem dos
  ícones, SVG próprio ou biblioteca (small) · (W2) mutation `adminEnableUser` +
  `EnableAccountDialog` + revisão dos 2 textos (small) · (W3) coluna "Ações" em ícones
  (alternância Ativar/Desativar, nome acessível, tooltip, remoção de "Redefinir senha" da
  linha, testes de componente — medium).
- **Por fase**: forja 0–0,25h · artefatos 0,75–1,5h · implementação 1–3h · gates 0,5–1,5h
- **Total**: 2,25–6,25h (horas de ciclo, não prazo de calendário)
- **Confiança**: média — terreno aberto e análogo quase idêntico, mas origem dos ícones
  ainda em aberto e interface com histórico de re-gate no gate 11.
- **Premissas**: forja restante é só o que surgir no specify (BRIEF já fechado) · gates:
  review sempre, gate 8 (rota muda estado de acesso da conta), qa (comportamento
  observável), gate 11 (ícones/foco/tooltip/contraste AA) — performance só se a DEC
  escolher biblioteca com peso de bundle · gate 9 tentado com contas reais, sem ambiente
  vira `pendente_handoff` · reativar não exige migração, só `disabledAt = null` + log já
  padronizado · login/sessão bloqueiam só por `disabledAt`.
- **Lacunas**: origem dos ícones (se virar biblioteca nova, soma auditoria de dependência,
  +0,25–0,75h) · se o login tiver outro guard além de `disabledAt` (não confirmado pelo
  code-scout), a fatia de backend cresce · partição por elemento irmão (LRN-039) pode levar
  a dimensão ao teto da faixa (5 tasks) sem mudar a ordem de grandeza.

## Cronologia
- specify: 2026-10-01T17:10:37-0300 · correções: 1 · classes: spec-emenda-nao-declarada(1) · spec-escopo-sem-necessidade(1) · spec-conflito-diretriz-anterior(1) · spec-metrica-nao-falseavel(1) · spec-cenario-faltante(4)
- plan: 2026-10-03T10:03:02-0300 · correções: 1 · classes: plan-citacao-id-inexistente(1)
- tasks: 2026-10-03T10:31:51-0300 · correções: 1 · classes: task-criterio-alvo-nao-isolado(1)
- implement: 2026-10-03T18:16:00-0300
- entrega: 2026-10-03T21:41:54-0300 · po: ACEITA_COM_RESSALVAS (gate rodado fora de ordem —
  depois do push, falha do Tech Lead, declarada; ressalvas: 2 testes pré-existentes
  corrigidos fora do pedido original — home-session-gate/next-build-lock — e diretriz
  RISK-050-007 a lembrar na Entrega)
