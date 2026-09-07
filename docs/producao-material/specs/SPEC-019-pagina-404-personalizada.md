# SPEC-019: Página 404 personalizada com volta à home

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.1
**Autor**: keelson (scribe)
**Data**: 2026-09-07
**Jira**: KAN-76
**Brief**: BRIEF-019

## 1. Contexto e objetivo

### 1.1 Problema

Hoje, qualquer rota inexistente da aplicação cai na página de erro 404 genérica do
framework (confirmado: não existe `not-found.tsx` em `mnemonicos-frontend/src/app/`) —
sem nenhum elemento da identidade visual do produto (paleta, tipografia, componentes de
marca) e sem oferecer ao usuário um caminho de volta. O usuário que chega
numa URL inexistente (link quebrado, digitação incorreta, rota removida) fica numa tela
que quebra a percepção de qualidade do produto e não indica como retomar o uso.

### 1.2 Outcome esperado

Toda rota inexistente da aplicação passa a exibir uma página 404 com a identidade visual
do produto (não a página padrão do framework), contendo um link ou botão que leva de
volta à página inicial pública (`/`) — clicável e funcional, não apenas cosmético.

### 1.3 Métrica de sucesso

**A-019-003** [assumido] [evidência: crença] Esta é uma entrega pontual de consistência
visual e navegação, sem meta de negócio numérica associada — o BRIEF-019 não define uma.
A régua de sucesso é de conformidade comportamental: toda rota inexistente exibe a página
404 personalizada (nunca o 404 genérico do framework) e o link/botão de volta navega para
`/`, verificado por teste automatizado no fecho do ciclo. `Reabrir se:` o Diretor quiser
associar esta capacidade a uma métrica de produto (ex.: taxa de abandono após 404).

**Fonte de medição**: instrumentação — suíte de teste automatizado cobrindo os ACs desta
SPEC (rota inexistente → conteúdo/identidade da página 404; clique no link de volta →
navegação para `/`), rodada no fecho do ciclo; dono: Tech Lead/QA.

**Não-regressão**: o guard de sessão de SPEC-002 continua redirecionando prefixo interno
sem cookie `mnemo_access` para `/login?next=<path>` (suíte `proxy.test.ts` permanece
verde, incluindo o caso de `INTERNAL_HOME` como caminho guardado); o matcher de
`proxy.ts:56` e o guard de open-redirect de `/login?next=` (BRIEF-014/KAN-75) não são
alterados por esta entrega.

## 2. Personas e jobs-to-be-done

Como qualquer visitante da aplicação — anônimo na área pública ou membro da equipe interna
(EDITOR/ADMIN) dentro da área interna —, ao acessar uma URL que não existe (link quebrado,
digitação incorreta, rota removida ou renomeada), quero ver uma página que reconheça
visualmente o produto e me ofereça um caminho claro e imediato de volta, para não ficar
preso numa tela de erro técnica sem identidade nem saída.

**Anti-persona** (decisão 4.98): não é para quem enfrenta uma falha de execução do
servidor (500) — esse fluxo tem natureza diferente (erro, não ausência de rota) e está
fora de escopo (§4.2).

## 3. Glossário (Ubiquitous Language)

| Termo | Definição | Origem |
|-------|-----------|--------|
| Página 404 (personalizada) | Tela exibida quando o usuário acessa uma rota inexistente, com a identidade visual da aplicação (paleta, tipografia, componentes de marca) e um link/botão de volta — em contraste com a página de erro genérica do framework | BRIEF-019 |
| Rota inexistente | Qualquer URL solicitada na aplicação que não corresponde a nenhuma rota definida, em nenhuma área (pública ou interna) | BRIEF-019 |
| Home pública | A página inicial da aplicação em `/`, destino fixo do link/botão de volta desta SPEC, independente de sessão ou área de origem | BRIEF-019 |

## 4. Escopo

### 4.1 In-scope

- Exibição de uma página 404 com a identidade visual da aplicação (não a página padrão do
  framework) para qualquer rota inexistente, em qualquer área da aplicação (pública ou
  interna), sem diferenciação de layout por segmento.
- Link ou botão, visível na página 404, com rótulo em português indicando volta à página
  inicial.
- Navegação funcional: acionar o link/botão leva o usuário à home pública (`/`).
- Resposta com o código de status HTTP apropriado (404) para a rota inexistente.

### 4.2 Out-of-scope

- Página de erro genérica para falha de execução do servidor (500 / cenário de exceção não
  tratada) — natureza diferente (erro vs. ausência de rota); quem lê "página de erro
  personalizada" poderia assumir as duas, mas o card (KAN-76) e o BRIEF-019 tratam só de
  rota inexistente.
- Página 404 diferenciada por segmento de rota (ex.: uma versão para a área pública e
  outra para a área interna) — a mesma página serve qualquer rota inexistente (A-019-001).
- Telemetria ou analytics de acesso a rota inexistente (contagem, log de URLs não
  encontradas) — fora do pedido do card.
- Diferenciação do destino do link de volta por estado de sessão (usuário autenticado vs.
  anônimo) ou pela última rota conhecida — o destino é sempre a home pública `/`
  (A-019-002), nunca "voltar para onde eu estava".
- Sugestão de rota parecida ou redirecionamento automático (ex.: "você quis dizer X?",
  redirect 301 para uma rota renomeada) — a página apenas informa a ausência e oferece a
  volta manual à home.
- Rotas inexistentes de API do backend (`mnemonicos-backend`) — respostas de erro de API
  seguem contrato próprio, fora do escopo desta SPEC (que cobre a interface do usuário no
  frontend).
- Página 404 exibida para rota inexistente sob prefixo guardado (`/studio/**`,
  `/content/**`) quando o usuário não tem sessão — SPEC-002 prevalece: o guard redireciona
  para `/login?next=<path>` antes de qualquer checagem de existência de rota, preservando
  a barreira deny-by-default já entregue (decisão do PO, E-019-01). A 404 personalizada
  desta SPEC cobre: toda rota inexistente da área pública; e rota inexistente sob prefixo
  interno **com sessão ativa**.
- Recurso existente removido/inalcançável (ex.: Conteúdo bruto com soft-delete de
  SPEC-005) — a rota `/content/[id]` existe; o comportamento de erro é da própria tela
  (`ContentForm`), não desta SPEC. Estender a 404 personalizada para esse caso é pedido
  novo, fora deste documento.

## 5. Requisitos funcionais (EARS)

- **FR-019-001** [MUST] Quando o usuário acessa uma URL que não corresponde a nenhuma
  rota existente da aplicação, o sistema DEVE exibir uma página 404 com a identidade
  visual da aplicação (não a página de erro padrão do framework).
- **FR-019-002** [MUST] O sistema DEVE exibir, na página 404, um link ou botão visível com
  rótulo indicando volta à página inicial.
- **FR-019-003** [MUST] Quando o usuário aciona o link/botão de volta na página 404, o
  sistema DEVE navegar para a home pública (`/`).
  > **Nota (três estados de UI, decisão 4.67)**: esta é uma ação de navegação local (sem
  > submissão de dados, sem chamada de rede que produza resultado incerto) — não há
  > estado "em andamento" a aguardar nem falha de negócio possível (o destino é uma rota
  > fixa, sempre existente, `/`). O par observável exigido é o de clique → navegação,
  > coberto explicitamente por AC-019-003/AC-019-005.
- **FR-019-004** [MUST] O sistema DEVE exibir a página 404 personalizada para qualquer
  rota inexistente da aplicação, em qualquer rota inexistente da área pública, e em rota
  inexistente da área interna quando o usuário tem sessão ativa (ver §4.2 para o caso sem
  sessão, onde o guard de SPEC-002 prevalece).

> **Nota sobre par de leitura (decisão 4.225)**: esta SPEC não introduz nenhum campo ou
> estado persistível novo — é uma tela de erro sem escrita em banco de dados ou chamada a
> API/backend (BRIEF-019, "sem chamada a API/backend"). Não há par de leitura a declarar.

## 6. Requisitos não-funcionais

- **NFR-019-001** [MUST] A página 404 DEVE manter consistência visual (paleta, tipografia,
  componentes de marca) com as demais páginas da aplicação, de forma que o usuário
  reconheça imediatamente que ainda está dentro do produto. As marcas observáveis mínimas
  estão enumeradas em AC-019-001.
- **NFR-019-002** [MUST] O texto exibido na página 404 (mensagem e rótulo do link/botão de
  volta) DEVE estar em português do Brasil, consistente com o restante da interface.
- **NFR-019-003** [MUST] Quando a página 404 é exibida, o sistema DEVE responder com o
  código de status HTTP 404, para não induzir motores de busca ou ferramentas de
  monitoramento a tratar a rota inexistente como válida.
- **NFR-019-004** [MUST] (a11y) O link/botão de volta DEVE ser operável por teclado
  (alcançável pela ordem de tabulação, ativável por Enter), seguindo o mesmo padrão de
  acessibilidade dos demais controles de navegação da aplicação.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-019-001** (cobre FR-019-001, FR-019-004, NFR-019-001)
  Dado uma rota que não corresponde a nenhuma página da aplicação, quando o usuário acessa
  essa URL a partir da área pública, ou a partir da área interna com sessão ativa, então o
  sistema exibe a página 404 com a identidade visual da aplicação (não a página padrão do
  framework), com estas marcas observáveis: (1) mesmo cabeçalho/marca das páginas
  públicas; (2) tokens de tema (paleta/tipografia) da aplicação, não o estilo default do
  framework; (3) todo texto em português do Brasil; (4) o link/botão de volta segue o
  mesmo padrão visual e de foco dos demais controles de navegação.

- **AC-019-001b** (cobre FR-019-004)
  Dado uma rota inexistente sob prefixo guardado (`/studio/**`, `/content/**`), quando o
  usuário sem sessão ativa acessa essa URL, então o sistema redireciona para
  `/login?next=<path>` (comportamento de SPEC-002, não alterado por esta SPEC) — a página
  404 personalizada não se aplica a este cenário.

- **AC-019-002** (cobre FR-019-002, NFR-019-002)
  Dado a página 404 exibida, quando o usuário observa a tela, então há um link ou botão
  visível, com rótulo em português do Brasil, indicando volta à página inicial.

- **AC-019-003** (cobre FR-019-003)
  Dado a página 404 exibida, quando o usuário clica no link/botão de volta, então o
  sistema navega para a home pública (`/`).

- **AC-019-004** (cobre NFR-019-003)
  Dado uma rota inexistente, quando a resposta HTTP dessa requisição é inspecionada,
  então o código de status retornado é 404.

- **AC-019-005** (cobre FR-019-003, NFR-019-004)
  Dado a página 404 exibida, quando o usuário navega até o link/botão de volta somente
  pelo teclado (Tab) e o aciona (Enter), então o sistema navega para a home pública (`/`)
  da mesma forma que ao clicar com o mouse.

## 8. Premissas e decisões prévias

- **A-019-001** [confirmado] [evidência: documento — leitura de escopo do card KAN-76,
  registrada em BRIEF-019] A página 404 é tratada no nível da aplicação inteira, cobrindo
  qualquer rota — pública ou dentro da área interna — sem diferenciação de layout por
  área/segmento (BRIEF-019).
- **A-019-002** [confirmado] [evidência: documento — AC(2) literal do card KAN-76 /
  BRIEF-019] O link/botão de volta aponta sempre para a home pública (`/`), independente
  do estado de sessão do usuário ou da rota de origem (BRIEF-019).
- **A-019-003** [confirmado] [evidência: documento — BRIEF-019 não define meta numérica]
  Sem meta de negócio numérica associada a esta entrega — ver §1.3; critério de sucesso é
  funcional/binário, verificado por teste automatizado.
- **A-019-004** [assumido] [evidência: crença] Rota inexistente sob prefixo interno sem
  sessão segue para `/login?next=<path>` (SPEC-002 prevalece), nunca para a 404
  personalizada desta SPEC — decisão do `po` (E-019-01), escalada ao Diretor na Entrega do
  ciclo; default: manter esta precedência.

## 9. Riscos e questões abertas

- **RISK-019-001** Rotas com segmento dinâmico malformado ou erro de parsing de parâmetro
  podem, a depender do mecanismo de roteamento escolhido no `/keelson:plan`, seguir um
  caminho de erro diferente do "rota não encontrada" padrão. Mitigação: qualquer rota não
  reconhecida deve cair na mesma página 404 (FR-019-004); revisitar se algum caso-limite
  escapar dela nos testes do PLAN.
- **Q-019-001** Rotas inexistentes de API (backend) seguem contrato próprio de erro e
  ficam fora desta SPEC (§4.2). Se o Diretor quiser, no futuro, uma resposta de erro
  visualmente identificada também para chamadas diretas de API feitas pelo navegador, é
  pedido novo, fora deste documento.
- **RISK-019-002** A home pública (`/`) hoje não oferece link de volta à área interna
  (`/studio`) — o CTA sensível a sessão de BRIEF-015/KAN-74 está implementado mas ainda não
  mergeado no `main` do frontend. Enquanto isso, um EDITOR/ADMIN que chega à 404 e aciona o
  link de volta chega a uma home sem caminho direto ao `/studio` (2 cliques via `/login`,
  não 1). Mitigação: nenhuma ação desta SPEC; o merge de KAN-74 fecha a lacuna por conta
  própria (decisão do `po`, sugestão S-01, não-bloqueante).

## 10. Fora deste documento

Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
