# SPEC-016: Toggle de mostrar/ocultar senha nos campos de senha

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.1
**Autor**: keelson (scribe)
**Data**: 2026-09-07
**Brief**: BRIEF-016

## 1. Contexto e objetivo

### 1.1 Problema

O `mnemonicos-frontend` tem hoje um único campo de senha real: o `LoginForm`
(`mnemonicos-frontend/src/components/login-form.tsx:75`, `type="password"`), sem nenhum
controle para o usuário conferir o que digitou antes de submeter. Erro de digitação no
campo de senha só se manifesta depois da submissão, como falha genérica de autenticação
(SPEC-002/AC-002-002) — sem contraparte de correção durante a digitação. KAN-72 pede um
comportamento padronizado de alternância de visibilidade ("ícone de olho") em **todos** os
campos de senha do sistema; hoje isso significa exatamente 1 campo (o do `LoginForm`) —
não existem ainda telas de cadastro ou troca de senha implementadas (BRIEF-016).

### 1.2 Outcome esperado

Um componente de campo de senha reutilizável passa a fornecer o toggle de visibilidade
(ícone de olho, operável por teclado, com rótulo acessível que reflete o estado atual) e
substitui o campo de senha nu do `LoginForm` — sem alterar nenhum comportamento do fluxo
de autenticação já existente (SPEC-002). O componente se torna o único caminho idiomático
para qualquer campo de senha futuro do sistema (cadastro, troca de senha), satisfazendo o
pedido de padronização sem exigir retrabalho quando essas telas existirem.

### 1.3 Métrica de sucesso

**A-016-001** [assumido] [evidência: crença] Esta é uma melhoria pontual de usabilidade e
acessibilidade, sem meta de negócio numérica associada — o BRIEF-016 não define uma. A
régua de sucesso desta fatia é de conformidade comportamental: o toggle funciona no único
campo de senha existente (`LoginForm`) sem regredir o fluxo de login hoje descrito em
SPEC-002 (FR-002-009/AC-002-009, AC-002-001/002), verificado por teste automatizado no
fecho do ciclo. `Reabrir se:` o Diretor quiser associar esta capacidade a uma métrica de
produto (ex.: taxa de erro de credencial por digitação incorreta).

**Fonte de medição**: instrumentação — suíte de teste automatizado do componente de campo
de senha (extensão de `login-form.test.tsx` e/ou teste próprio do novo componente)
cobrindo os ACs desta SPEC, rodada no fecho do ciclo; dono: Tech Lead/QA.

## 2. Personas e jobs-to-be-done

Como EDITOR ou ADMIN da fábrica, ao fazer login (e, no futuro, ao definir ou trocar uma
senha), quero poder alternar a visibilidade do que digito no campo de senha, para
conferir que digitei corretamente antes de submeter, reduzindo tentativas de login
recusadas por erro de digitação silencioso.

**Anti-persona** (decisão 4.98): não é para o estudante — ele nunca acessa nenhuma tela do
sistema com campo de senha (MAP.md, "Resumo"); a área interna é de uso exclusivo de
EDITOR/ADMIN.

## 3. Glossário (Ubiquitous Language)

| Termo | Definição | Origem |
|-------|-----------|--------|
| Toggle de visibilidade de senha | Controle (ícone de "olho") que alterna a exibição do valor de um campo de senha entre oculto (mascarado) e texto plano, sem alterar o valor digitado | BRIEF-016 |
| Campo de senha (componente) | Componente de entrada reutilizável que encapsula um `<input>` de senha e o toggle de visibilidade associado — usado pelo campo de senha do `LoginForm` hoje e por qualquer campo de senha futuro do sistema | BRIEF-016 |
| Rótulo acessível dinâmico (do toggle) | Texto acessível (ex.: `aria-label` ou equivalente) do controle de alternância, que muda conforme o estado atual do campo — "mostrar senha" quando oculto, "ocultar senha" quando visível | BRIEF-016 |

## 4. Escopo

### 4.1 In-scope

- Componente reutilizável de campo de senha com toggle de visibilidade (ícone de olho),
  operável por clique e por teclado, com rótulo acessível dinâmico.
- Aplicação do componente no campo de senha do `LoginForm` — único campo de senha
  existente hoje (`mnemonicos-frontend/src/components/login-form.tsx`).
- Estado inicial do campo de senha sempre oculto (mascarado), antes de qualquer
  alternância pelo usuário.
- Comportamento do controle de alternância: não submete o formulário ao ser acionado,
  preserva o valor digitado ao alternar, não desabilita nem limpa o campo.
- Acessibilidade do controle: navegável e ativável por teclado (Tab + Enter/Espaço),
  identificável por tecnologia assistiva, com rótulo acessível refletindo o estado atual.

### 4.2 Out-of-scope

- **Telas** de cadastro e troca de senha — não existem hoje no sistema (BRIEF-016); a
  **capacidade** já existe nos dois lados (`POST /auth/change-password`,
  `POST /users/:id/reset-password`, hooks `changePassword`/`adminResetPassword` em
  `mnemonicos-frontend/src/store/api.ts:406,430`, com testes de contrato) — só falta a
  tela que os consome (veredito PO/BRIEF-016). Quem lê "padronizar em todos os campos de
  senha" (KAN-72) poderia assumir a criação dessas telas; não é o caso: o componente nasce
  pronto para reuso quando essas telas forem criadas em uma fatia futura (Q-016-001), mas
  nenhuma tela nova é criada por esta SPEC. Decisão de fechar KAN-72 nesta entrega ou abrir
  card de follow-up para essas telas é escalação ao Diretor (Entrega, sem bloquear este PLAN).
- Política ou regra de força de senha (validação de complexidade, medidor de força,
  requisitos mínimos) — fora do pedido do card KAN-72.
- Qualquer alteração de comportamento do fluxo de autenticação (SPEC-002): submissão,
  validação de credenciais, os três estados observáveis do login (FR-002-009), limite de
  taxa, sessão. O toggle é puramente de apresentação sobre o mesmo `<input>` — quem lê
  "novo componente no LoginForm" poderia temer regressão de login; NFR-016-003 nomeia essa
  fronteira explicitamente.
- Qualquer novo estado de rede, log ou telemetria envolvendo o valor da senha — o toggle
  não introduz requisição, persistência nem instrumentação nova (NFR-016-002).
- Refinamento visual do ícone além do necessário para ficar reconhecível e consistente com
  a identidade visual já existente (tokens/paleta de `globals.css`) — mesma postura de
  "sem novo trabalho de design de marca" já usada em A-013-002 (INDEX.md) para este slug.

## 5. Requisitos funcionais (EARS)

- **FR-016-001** [MUST] O sistema DEVE exibir, em todo campo de senha, um controle (ícone
  de "olho") que permite ao usuário alternar a visibilidade do valor digitado entre oculto
  (mascarado) e texto plano.
- **FR-016-002** [MUST] O sistema DEVE iniciar todo campo de senha com o valor oculto
  (mascarado), antes de qualquer alternância pelo usuário.
- **FR-016-003** [MUST] Quando o usuário aciona o controle de alternância (clique ou
  ativação por teclado), o sistema DEVE alternar a exibição do valor do campo entre oculto
  e texto plano, preservando o valor digitado.
  > **Nota (três estados de UI, decisão 4.67)**: esta é uma ação de apresentação
  > instantânea e local (sem I/O, sem chamada de rede) — não há resultado pendente a
  > aguardar; o próprio estado do ícone/rótulo já é o feedback de sucesso, refletido de
  > imediato (FR-016-005). Não há estado "em andamento" observável nem estado de falha
  > possível: a alternância é síncrona e não depende de nenhum recurso externo.
- **FR-016-004** [MUST] Se o usuário aciona o controle de alternância, então o sistema NÃO
  DEVE submeter o formulário que contém o campo de senha.
- **FR-016-005** [MUST] O sistema DEVE fornecer ao controle de alternância um rótulo
  acessível (ex.: `aria-label` ou equivalente) que reflete o estado atual do campo —
  "mostrar senha" quando oculto, "ocultar senha" quando visível.
- **FR-016-006** [MUST] O sistema DEVE tornar o controle de alternância operável via
  teclado (navegável pela ordem de tabulação, ativável por Enter/Espaço), sem depender de
  mouse ou toque.
- **FR-016-007** [MUST] O comportamento de toggle de visibilidade DEVE ser fornecido por
  um único componente reutilizável, usado pelo campo de senha do `LoginForm` e por
  qualquer campo de senha futuro do sistema.

> **Nota sobre par de leitura (decisão 4.225)**: esta SPEC não introduz nenhum campo ou
> estado persistível de domínio novo (não há mudança no `mnemonicos-backend`, model ou
> coluna). O estado de visibilidade (oculto/texto plano) é efêmero — vive só na interação
> do componente de UI, sem persistência em armazenamento, sessão ou backend. Não há par de
> leitura a declarar.

## 6. Requisitos não-funcionais

- **NFR-016-001** [MUST] (a11y) O controle de alternância DEVE ser identificável por
  tecnologia assistiva (papel de botão, rótulo acessível dinâmico conforme FR-016-005) e
  alcançável pela ordem de tabulação natural do formulário.
- **NFR-016-002** [MUST] O sistema NÃO DEVE registrar, logar ou transmitir o valor da
  senha em nenhum novo canal (rede, log, telemetria, verificação ortográfica/autocorreção
  do navegador) em decorrência do toggle — a alternância é puramente de apresentação
  (atributo `type` do input), sem novo estado de rede; e o campo DEVE continuar
  identificável como credencial pelo gerenciador de senha do navegador (atributos
  equivalentes a `name="password"`/`autoComplete="current-password"`) em ambos os estados
  de visibilidade.
- **NFR-016-003** [MUST] O comportamento hoje existente do fluxo de login (SPEC-002:
  submissão com os três estados observáveis de FR-002-009/AC-002-009, validação de
  credenciais, mensagem de falha genérica de AC-002-002) NÃO DEVE regredir com a
  introdução do componente de campo de senha no `LoginForm`. A inclusão de um ponto de
  parada de tabulação adicional para o controle de alternância (FR-016-006) é consequência
  aceita da acessibilidade pedida pelo BRIEF-016 e NÃO constitui regressão deste NFR
  (resolução PO, veredito de SPEC-016).
- **NFR-016-004** [MUST] O controle de alternância DEVE ser um elemento cujo tipo não
  dispara submit de formulário (equivalente a `type="button"`), garantindo FR-016-004
  mesmo com o campo de senha dentro de um `<form>`.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-016-001** (cobre FR-016-002)
  Dado o campo de senha do `LoginForm` recém-renderizado (ou reaberto), quando o usuário
  observa seu estado inicial, então o valor está oculto (mascarado) — nenhuma alternância
  prévia é assumida.

- **AC-016-002** (cobre FR-016-001, FR-016-003)
  Dado o usuário com o campo de senha do `LoginForm` preenchido e oculto, quando ele
  clica no ícone de olho, então o valor passa a ser exibido em texto plano, sem alteração
  do valor digitado; e quando ele clica novamente, o valor volta a ficar oculto.

- **AC-016-003** (cobre FR-016-005)
  Dado o controle de alternância em cada um dos dois estados, quando seu rótulo acessível
  é inspecionado (ex.: via árvore de acessibilidade ou leitor de tela), então o rótulo é
  "mostrar senha" quando o campo está oculto e "ocultar senha" quando o campo está
  visível.

- **AC-016-004** (cobre FR-016-006, NFR-016-001)
  Dado o formulário de login, quando o usuário navega até o controle de alternância
  somente pelo teclado (Tab) e o aciona (Enter ou Espaço), então o campo de senha alterna
  sua visibilidade da mesma forma que ao clicar com o mouse, e o controle é identificável
  como tal por tecnologia assistiva.

- **AC-016-005** (cobre FR-016-004, NFR-016-004)
  Dado o formulário de login preenchido com e-mail e senha, quando o usuário aciona o
  controle de alternância de visibilidade, então o formulário NÃO é submetido (nenhuma
  chamada à rota de login ocorre) e o campo apenas alterna a visibilidade.

- **AC-016-006** (cobre FR-016-007)
  Dado o componente de campo de senha, quando ele é usado no `LoginForm`, então nenhum
  outro `<input type="password">` do sistema implementa lógica de alternância própria — o
  `LoginForm` consome o mesmo componente reutilizável.

- **AC-016-007** (cobre NFR-016-003)
  Dado o `LoginForm` com o componente de campo de senha aplicado, quando o usuário
  percorre o fluxo de login completo (submissão com os três estados observáveis de
  FR-002-009, sucesso, falha com mensagem genérica de AC-002-002), então o comportamento é
  idêntico ao descrito em SPEC-002, sem nenhuma alteração introduzida pelo toggle.

- **AC-016-008** (cobre NFR-016-002)
  Dado o toggle de visibilidade acionado, quando a rede, o log/console da aplicação e os
  atributos do campo são inspecionados, então nenhuma requisição nova é disparada, nenhum
  log ou console registra o valor da senha, e o campo mantém os atributos que o
  identificam como credencial para o gerenciador de senha do navegador (equivalentes a
  `name="password"`/`autoComplete="current-password"`) em ambos os estados de
  visibilidade.

- **AC-016-009** (cobre NFR-016-003)
  Dado o usuário que alternou o campo de senha para texto plano e submeteu o `LoginForm`
  com credencial inválida (falha genérica de AC-002-002), quando a mensagem de erro é
  exibida, então o campo de senha permanece com o valor visível em texto plano (o estado
  do toggle não é revertido pela submissão recusada).

- **AC-016-010** (cobre FR-016-006, NFR-016-001)
  Dado o usuário que navegou até o controle de alternância pelo teclado e o acionou
  (Enter ou Espaço), quando a alternância é concluída, então o foco permanece no próprio
  controle de alternância — o campo de senha não perde o valor nem é desmontado/remontado
  em decorrência da ação.

## 8. Premissas e decisões prévias

- **A-016-001** [assumido] [evidência: crença] Sem meta de negócio numérica associada ao
  toggle — ver §1.3.
- **A-016-002** [assumido] [evidência: observação] "Todos os campos de senha existentes"
  (KAN-72) resolve para 1 hoje: o campo de senha do `LoginForm`
  (`mnemonicos-frontend/src/components/login-form.tsx:75`). Não há **telas** de cadastro
  ou troca de senha implementadas — a **capacidade** de troca/reset de senha já existe na
  API e nos hooks RTK Query do frontend, sem consumidor de tela (ver §4.2). A reutilização
  em telas futuras é satisfeita pela existência do componente único como caminho
  idiomático, não por retrofitar telas que não existem.
- **A-016-003** [assumido] [evidência: crença] O valor da senha nunca é logado nem exposto
  fora do DOM — o toggle é puramente de apresentação (atributo `type` do input nativo),
  sem novo estado de rede (BRIEF-016, premissa 3; formalizado em NFR-016-002).
- **A-016-004** [assumido] [evidência: crença] O controle de alternância não é o botão de
  submit do formulário — precisa ser um elemento cujo tipo não dispara submit (equivalente
  a `type="button"`), para não disparar submit acidental (BRIEF-016, premissa 4;
  formalizado em NFR-016-004/FR-016-004).
- **A-016-005** [assumido] [evidência: crença] A posição exata do caret/cursor de texto
  dentro do campo, ao trocar `type` do input, não é objeto de AC — é comportamento
  best-effort do navegador; exigi-la seria além do pedido do BRIEF-016 (resolução PO,
  veredito de SPEC-016). O que a SPEC garante é a continuidade do foco no controle
  (AC-016-010) e a preservação do valor digitado (AC-016-002).
- **A-016-006** [assumido] [evidência: observação] Revelar um valor preenchido por
  autofill do navegador (não digitado pelo usuário) ao acionar o toggle é aceitável — é
  comportamento nativo de qualquer campo de senha com toggle, exige ação deliberada do
  dono da própria sessão, e o sistema é de uso interno restrito a EDITOR/ADMIN (§2).
  Nenhum AC trata esse caso separadamente (resolução PO, veredito de SPEC-016).

## 9. Riscos e questões abertas

- **RISK-016-001** Esta SPEC prova a acessibilidade do toggle por atributo (rótulo
  acessível dinâmico, ordem de tabulação) via teste automatizado — não por caminhada real
  com leitor de tela em dispositivo. Mitigação: aceito nesta fatia, mesma postura de
  conformidade automatizada já usada nas demais SPECs deste slug; revisitar se um
  EDITOR/ADMIN usuário de tecnologia assistiva reportar atrito real.
- **Q-016-001** Quando as telas de cadastro ou troca de senha forem criadas (fora do
  escopo desta SPEC), elas devem reusar o mesmo componente de campo de senha — fica
  registrado aqui como expectativa de design para a SPEC que as criar, sem AC verificável
  nesta SPEC (não há tela para testar hoje).

## 10. Fora deste documento

Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
