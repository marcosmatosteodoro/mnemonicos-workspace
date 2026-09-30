# BRIEF-040: Quem tem sessão e abre `/` vai direto para a área logada

**Slug**: producao-material
**Status**: Emitido
**Data**: 2026-09-30
**Largada**: 2026-09-30T13:27:10-0300
**SPEC**: SPEC-040
**Jira**: KAN-180

## Pedido como dito
"/keelson:auto --from=KAN-180 --slug=producao-material"

Card KAN-180 (História, escrito pelo Diretor, fonte da demanda — modo `link`, sem card novo):

> **Usuário com sessão ativa que entra na aplicação vai direto para a área logada (não vê a home pública)**
>
> ## Contexto
> Hoje quem tem sessão ativa consegue abrir a página inicial pública (`/`) e ver o conteúdo da área não logada. A guarda de navegação (`mnemonicos-frontend/src/proxy.ts`) só roda nas rotas internas (`/studio`, `/content`, `/visual-library`), então `/` é servida igual para todos. O logo do cabeçalho também aponta para `/`: um EDITOR/ADMIN que clica nele dentro do estúdio cai na home pública.
>
> Para quem tem sessão, entrar na área não logada não faz sentido.
>
> Levantado na triagem do KAN-176, por decisão do Diretor (2026-09-30).
>
> ## Pedido
> Quando alguém **com sessão ativa** entra na aplicação, vai direto para a área logada (`/studio`, a constante `INTERNAL_HOME`) e não vê a home pública.
>
> ## Critérios de aceite
> * Com sessão ativa, abrir `/` leva direto para a área logada, sem mostrar a home pública.
> * Sem sessão, `/` continua mostrando a home pública como hoje.
> * O visitante anônimo nunca é mandado para `/login` só por ter aberto `/`.
> * Nada muda no login, no logout nem na guarda das rotas internas.
>
> ## Pontos a decidir no ciclo (SPEC/PLAN)
> * **Como saber que há sessão:** hoje o `proxy.ts` só olha se o cookie de acesso **existe**, sem conferir se ainda vale. Com um cookie vencido, a pessoa seria mandada para `/studio` e dali para `/login?sessao=expirada`, e nunca veria a home pública. Isso é aceitável ou exige outra estratégia?
> * **Outras rotas públicas com sessão:** além de `/`, `/login` (e futuras páginas públicas) também devem mandar o usuário logado para a área interna?
> * **Papel sem acesso à área interna:** `STUDENT` está dormente hoje. Se voltar a ter conta ativa, uma sessão `STUDENT` não pode ser mandada para uma área que ela não alcança.
> * **Contratos afetados:** a promessa de guarda de rota da SPEC-002 (DEC-003-011 / COMP-003-022: o guard só roda onde a sessão é pressuposta) e o link de volta da 404 (SPEC-019, destino `/`).
>
> ## Relacionados
> * KAN-176: remove o "Entrar" do corpo da home. Depende desta História para o usuário logado não ficar sem caminho de `/` até `/studio`.
> * KAN-74 / BRIEF-015: criou o "Entrar" do corpo como atalho para a área logada.

Conversa na mesma sessão, antes da largada (Tech Lead → Diretor, sem resposta explícita; o
Diretor disparou o `/keelson:auto` em seguida — vale a janela de veto): o cookie de acesso
vive 15 min e o de renovação (7 dias) só trafega em `/api/v1/auth`, então "cookie de
acesso existe" só reconhece quem usou a app nos últimos 15 min. Recomendação apresentada:
**caminho B** — a home lê a sessão no navegador, com renovação silenciosa, e redireciona.

## Interpretação do PO
**Contexto**: desde o KAN-176, quem tem sessão e abre `/` vê a home pública e não tem
link para o estúdio. **Pedido**: com sessão válida — inclusive a de quem entrou há dias e
ainda pode renovar sem digitar senha —, abrir `/` leva direto a `/studio`, sem a home
pública aparecer. Sem sessão, a home de hoje, e ninguém é empurrado para `/login` por
abrir `/`. Login, logout e a guarda das rotas internas não mudam.

## Premissas decididas
- **"Sessão ativa" = sessão que o servidor aceita agora ou que renova em silêncio**, não
  a mera presença do cookie de acesso (que vence em 15 min). A estratégia técnica é DEC
  do PLAN; a direção recomendada ao Diretor foi o caminho B (leitura de sessão no
  navegador com renovação silenciosa + redirecionamento), sem mudança no backend.
- **Enquanto a sessão está sendo conferida, `/` não mostra a home pública** para quem vai
  ser redirecionado; o anônimo pode ver um instante de estado neutro antes da home — é o
  custo aceito do caminho B.
- **Sessão que não renova (vencida/revogada) = anônimo**: fica na home pública, sem ida a
  `/login` e sem mensagem de sessão expirada.
- **Papel sem acesso à área interna (`STUDENT`) fica na home pública** — nunca é mandado
  para uma área que não alcança.
- **Logo do cabeçalho e link da 404 continuam apontando para `/`**: o redirecionamento de
  `/` leva quem tem sessão ao estúdio sem mudar esses links.

## Fora de escopo
- `/login` (e outras páginas públicas) com sessão ativa — segue como hoje; candidato a
  card próprio. Evita colisão com o KAN-177 (BRIEF-039), em andamento na mesma tela.
- Mudança no backend (cookies, TTLs, endpoints de sessão).
- Sidebar e destino do logo por estado de sessão na área interna (KAN-178).

## Estimativa
Reutilizada do `estimator` rodado nesta sessão (2026-09-30, antes da largada):
- **Dimensão**: ~2 waves · ~3 tasks (~2 small · ~1 medium), faixa 2–5 tasks.
- **Por fase**: forja 0,3–1h · artefatos 1–3h · implementação 2–7h (variante com
  validação de sessão: 4–11h) · gates 2–6h.
- **Total**: 5–17h (variante com validação de sessão: 8–25h) — horas de agente em sessão
  contínua, não prazo de calendário.
- **Confiança**: média — estrutura delimitada por precedentes (PLAN-020, PLAN-021); a
  escolha da estratégia de sessão move o mix e o gate 10.
- **Calibração**: sem base histórica (2 linhas válidas em `estimates.md`, mínimo 3);
  nenhum corretor aplicado.
- **Nota da largada**: o fato apurado depois (cookie de acesso de 15 min, renovação
  invisível em `/`) desloca a expectativa para a **variante com validação de sessão**.

## Cronologia
- Etapa 1 (SPEC) concluída: 2026-09-30T13:44:08-0300 · correções: 1 · classes: spec-fr-palavras(8) · spec-nfr-sem-numero(3) · spec-glossario-nao-usado(3) · spec-must-ratio(1) · spec-sem-should-may(1) · spec-ears-nao-casa(1) · janelas: redação 1min/173l
- Etapa 2 (PLAN) concluída: 2026-09-30T13:50:13-0300 · correções: 1 · classes: plan-dec-alternativa-unica(1)
- Etapa 3 (TASKs) concluída: 2026-09-30T14:09:44-0300 · correções: 0 · classes: task-criterio-grep-nao-ancorado(4) · task-wave-overlap-arquivo(1) · task-nome-tipo(1)
- Etapa 3.5 (verificabilidade pré-código, qa + task-validator + po) concluída: 2026-09-30T14:49:03-0300 · correções: 2 · classes: criterio-contagem-divergente(2) · criterio-contradiz-inclui(2) · task-wave-overlap-arquivo(1) · roteiro-sujeito-inexistente(1) · criterio-contradiz-plan(1) · plan-desatualizado(1) · contagem-dependente-de-ordem(1) · contagem-base-ambigua(1) · regra-ambigua(1) · caso-precondicao-inalcancavel(1) · criterio-inexequivel-ambiente(1)
