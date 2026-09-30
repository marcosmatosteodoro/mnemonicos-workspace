# SPEC-040: Sessão reconhecida abre a área logada

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.5
**Autor**: scribe (redação delegada pelo Tech Lead; contrato Diretor–PO, BRIEF-040)
**Data**: 2026-09-30
**Jira**: KAN-180
**Brief**: BRIEF-040

## 1. Contexto e objetivo

### 1.1 Problema
Quem já tem sessão reconhecida e abre a página inicial pública ("Home pública", SPEC-019) vê o conteúdo da área não logada, sem caminho direto para a área interna (a sequência de KAN-176 remove o "Entrar" do corpo dessa página). Para quem tem sessão, ficar na página pública não faz sentido: é um desvio que a pessoa precisa corrigir sozinha, e o logo do cabeçalho — que aponta para a página inicial — leva um EDITOR/ADMIN de dentro da área interna de volta a ela. Conferir apenas se a credencial de acesso (vida curta, ~15 min) ainda existe reconheceria só quem usou o app há pouco; quem entrou há dias e ainda pode renovar a sessão sem digitar senha seria tratado como anônimo.

### 1.2 Outcome esperado
Quem tem sessão reconhecida e abre a página inicial chega direto à página inicial da área interna, sem que a página inicial pública tenha aparecido. Quem não tem sessão reconhecida continua vendo a página inicial pública de hoje, sem ser empurrado para a tela de login nem receber aviso de sessão expirada. Login, logout e a guarda das rotas internas não mudam.

### 1.3 Métrica de sucesso
Indicador: 100% das visitas à página inicial com sessão reconhecida, papel com acesso à área interna **e pista de sessão no navegador** terminam na página inicial da área interna, com 0 exibições do conteúdo da página inicial pública (exceto a ida tardia após o teto da conferência, FR-040-012; exceção declarada: sessão reconhecida sem pista vê a página pública nessa abertura, A-040-014, AC-040-025); e 100% das visitas sem sessão reconhecida (ou com papel sem acesso) terminam na página inicial pública, com 0 idas à tela de login. Verificação: na entrega desta SPEC, pelos testes de comportamento dos ACs desta SPEC (AC-040-001 a AC-040-025; AC-040-014 informativo, não bloqueia). Não há número de produto nem baseline: o produto não tem fonte de medição de uso desta jornada e nenhuma foi inventada aqui.

Exigem execução em navegador real com serviço de sessão real (dublê não fecha): AC-040-002, AC-040-003, AC-040-009, AC-040-012, AC-040-013, AC-040-016, AC-040-017, AC-040-018, AC-040-019, AC-040-025. Pendência de execução real em qualquer um deles = entrega PARCIAL declarada, com handoff.

**Fonte de medição**: externa — suíte de testes de comportamento da própria entrega (gates de QA e de comportamento verificado); dono do número: Tech Lead do ciclo.

## 2. Personas e jobs-to-be-done
- **EDITOR / ADMIN (contas internas)**: "quando abro o endereço do app, o app instalado ou clico no logo, quero cair direto onde trabalho, sem passar por uma página pública que não me serve."
- **Visitante anônimo** (inclui quem nunca entrou e quem teve a sessão vencida ou revogada): "quando abro a página inicial, quero ver a página pública de sempre, sem ser jogado para o login nem ser avisado de nada."
- **Conta com papel sem acesso à área interna** (hoje o papel de estudante, dormente): "não me mande para uma área que não alcanço."

## 3. Glossário (Ubiquitous Language)
Termos herdados do glossário consolidado do INDEX: Sessão autenticada, Credencial de acesso, Token de renovação, Papel, Deny-by-default, Controle de autenticação (do header, SPEC-036). Neste documento, "página inicial pública" = Home pública (termo emendado abaixo).

| Termo | Definição | Origem |
|-------|-----------|--------|
| Sessão reconhecida | Sessão que o sistema aceita agora **ou** que se renova sem pedir senha de novo (quem entrou há dias e ainda está dentro da validade da renovação conta como reconhecida). Corresponde à "sessão ativa" do card KAN-180; não redefine "sessão ativa" da SPEC-036 (= sessão aceita agora) | BRIEF-040 / A-040-001 |
| Home pública | A página inicial da aplicação em `/`, exibida a quem não tem sessão reconhecida com papel com acesso à área interna. `/` segue destino fixo do link de volta da 404, e do logo quando não há sessão ativa com papel com acesso à área interna (SPEC-044); quem tem sessão reconhecida é levado dali à área interna (SPEC-040). Promessa mantida: `/` nunca exige sessão nem leva à tela de login | SPEC-019 · emendada por SPEC-040 e SPEC-044 |
| Renovação sem nova senha | Troca de uma credencial de acesso vencida por outra nova usando o token de renovação (SPEC-002), sem nova autenticação da pessoa | SPEC-002 |
| Conferência da sessão | Verificação, feita quando a página inicial é aberta, de se há sessão reconhecida e de qual é o papel da conta | SPEC-040 |
| Estado neutro | Aparência da página inicial enquanto a conferência da sessão está em andamento: sem o conteúdo da página inicial pública e sem "Entrar"/"Sair" (é o neutro do cabeçalho de FR-036-016) | SPEC-040 |
| Teto da conferência | Limite de 3 s, contado da abertura da página inicial, em qualquer ambiente (inclusive produção), para a conferência da sessão concluir; passado o teto, o estado neutro termina na página inicial pública | SPEC-040 / A-040-010 |
| Página inicial da área interna | Destino de entrada da área interna (o painel estratégico, SPEC-034), para onde vai quem tem sessão reconhecida e papel com acesso | SPEC-034 / SPEC-040 |
| Papel com acesso à área interna | Papel que a guarda de rotas internas admite (EDITOR e ADMIN; SPEC-002) | SPEC-002 |
| Área interna | Conjunto de rotas guardadas pela sessão (estúdio, conteúdo, biblioteca visual) | SPEC-002 |

## 4. Escopo

### 4.1 In-scope
- Conferência da sessão ao abrir a página inicial, com estado neutro enquanto dura e teto da conferência de 3 s.
- Redirecionamento direto à página inicial da área interna para sessão reconhecida com papel com acesso, sem a página pública aparecer.
- Reconhecer como sessão reconhecida também a que só se renova sem nova senha.
- Permanência na página inicial pública para: sem sessão reconhecida (nunca entrou, vencida, revogada, não renovável), falha da conferência, navegador sem script e papel sem acesso à área interna — sem ida ao login e sem aviso de sessão expirada.
- Ida à área interna sem prender a pessoa no "voltar" do navegador.
- Link de volta da 404 mantido apontando para a página inicial (quem tem sessão chega à área interna pelo redirecionamento). O destino do logo do cabeçalho segue a SPEC-044 (emenda v0.5).
- Abrir o app instalado equivale a abrir a página inicial (endereço de partida do app, SPEC-013): mesmo comportamento.
- Não-regressão explícita de login, logout, guarda das rotas internas e página inicial pública para o anônimo.
- Salvaguardas de segurança e de desempenho do fluxo (NFRs).

### 4.2 Out-of-scope
- **Tela de login e outras páginas públicas com sessão reconhecida**: seguem como hoje (sem redirecionamento); candidato a card próprio; evita colisão com KAN-177 (BRIEF-039), em andamento na mesma tela. Resposta a "e `/login` com sessão?": fora.
- **Mudança nas regras de sessão** (duração, renovação, revogação, endpoints de sessão): não muda. Resposta a "e se a sessão durasse mais?": fora.
- **Controle de autenticação do cabeçalho mostrar "Entrar" para sessão renovável em outras páginas públicas**: comportamento atual, não muda aqui.
- **Navegação/sidebar da área interna** (KAN-178, SPEC-044): fora desta SPEC. O destino do logo por estado de sessão, antes adiado aqui, passou à SPEC-044 (emenda v0.5); o link de volta da 404 continua fixo na página inicial.
- **Mensagem ou tela para o papel sem acesso**: esse papel só fica na página inicial pública, sem aviso. Resposta a "e o que o estudante vê?": nada novo.
- **Mudança no conteúdo da página inicial pública** (inclusive o "Entrar" do corpo, KAN-176): fora.
- **Observabilidade de produto** (contagem de visitas redirecionadas): não há instrumentação nova; a métrica é verificada por teste (§1.3).
- **Redirecionar sessão reconhecida em navegador sem pista de sessão**: fora — vê a página pública nessa abertura e se corrige na próxima passagem pela área interna ou pelo login (A-040-014). Resposta a "e na primeira vez depois do deploy?": página pública uma vez.
- **Ver a página inicial pública estando com sessão reconhecida** (ex.: ADMIN conferindo a vitrine): sem caminho; para vê-la, sair ou usar janela anônima. Resposta a "e se eu quiser ver a home logado?": fora (card KAN-180).
- **Nova conferência ao clicar no logo estando já na página inicial**: não é nova abertura da página e não confere a sessão de novo; quem ficou na página pública com sessão reconhecida (falha da conferência, login em outra aba) recupera pela recarga (RISK-040-005). Resposta a "e se eu clicar no logo depois de uma falha?": recarregue a página; o logo por estado de sessão é da SPEC-044 (KAN-178).

## 5. Requisitos funcionais (EARS)
- **FR-040-001** [MUST] Quando alguém abre a página inicial num navegador que guarda pista de sessão, o sistema deve conferir se há sessão reconhecida e qual o papel da conta antes de decidir o que mostrar.
- **FR-040-002** [MUST] Enquanto a conferência da sessão está em andamento, o sistema deve mostrar o estado neutro, sem o conteúdo da página inicial pública e sem "Entrar" nem "Sair" no cabeçalho.
- **FR-040-003** [MUST] Quando a conferência conclui sessão reconhecida com papel com acesso à área interna, o sistema deve levar a pessoa direto à página inicial da área interna, sem exibir a página pública antes.
- **FR-040-004** [MUST] Quando a sessão não é aceita mas admite renovação sem nova senha, o sistema deve renová-la e tratá-la como sessão reconhecida (FR-040-003), sem tela de login nem aviso.
- **FR-040-005** [MUST] Se a conferência conclui que não há sessão reconhecida, então o sistema deve exibir a página inicial pública, sem tela de login nem aviso de sessão expirada.
- **FR-040-006** [MUST] Se a conferência da sessão falha (serviço indisponível ou erro de rede), então o sistema deve exibir a página inicial pública, sem tela de login nem aviso.
- **FR-040-007** [MUST] Se a conta tem sessão reconhecida mas papel sem acesso à área interna, então o sistema deve exibir a página inicial pública e nunca levá-la à área interna.
- **FR-040-008** [MUST] Quando o sistema leva a pessoa à área interna a partir da página inicial, o sistema deve substituir a entrada da página inicial no histórico, sem laço no "voltar" do navegador.
- **FR-040-009** [MUST] O link de volta da 404 deve continuar apontando, fixo, para a página inicial; com sessão reconhecida, chega à área interna pelo redirecionamento (FR-040-003). O destino do logo do cabeçalho segue a SPEC-044 (emenda v0.5).
- **FR-040-010** [MUST] O sistema deve manter inalterados o login e o logout.
- **FR-040-011** [MUST] Se a conferência não conclui dentro do teto da conferência, então o sistema deve encerrar o estado neutro e exibir a página inicial pública, sem tela de login nem aviso.
- **FR-040-012** [MUST] Quando a conferência conclui após o teto com sessão reconhecida e papel com acesso, e a pessoa segue na página inicial, o sistema deve levá-la à área interna (FR-040-008).
- **FR-040-013** [MUST] Quando a página inicial é aberta num navegador com pista de sessão (endereço, recarga, "voltar", "avançar", ou logo e link da 404 acionados a partir de outra página), o sistema deve fazer conferência atual da sessão, sem decidir por resultado guardado antes na aba.
- **FR-040-014** [MUST] Se o navegador não executa script, então o sistema deve exibir a página inicial pública; a visita é tratada como anônima.
- **FR-040-015** [MUST] O sistema deve manter inalterada a guarda das rotas internas: anônimo em rota interna vai à tela de login com retorno.
- **FR-040-016** [MUST] O sistema deve manter inalterados o conteúdo, o título e a descrição da página inicial pública exibidos ao anônimo.
- **FR-040-017** [MUST] Se o navegador não guarda pista de sessão, então o sistema deve exibir a página inicial pública sem estado neutro e sem conferência da sessão, mesmo havendo sessão reconhecida (exceção declarada, A-040-014).

Três estados (princípio 4.67), da visita à página inicial: *em andamento* — FR-040-002; *sucesso* — FR-040-003/FR-040-004 (área interna), FR-040-005/FR-040-007 (página pública), FR-040-017 (sem pista: página pública imediata) e FR-040-011/FR-040-012 (teto: página pública ao fim do teto, ida tardia à área interna quando a conferência conclui depois); *falha* — FR-040-006.

## 6. Requisitos não-funcionais
- **NFR-040-001** [MUST] A conferência da sessão feita pela página inicial não pode derrubar uma sessão válida (inclusive em renovação concorrente com outra aba ou outra requisição) nem encerrar a sessão em outras abas ou requisições.
- **NFR-040-002** [MUST] A conferência da sessão deve falhar de forma segura: nenhuma resposta ambígua, forjada, inválida ou de erro pode levar à área interna nem expor dado da área interna ou da conta (deny-by-default; o erro resolve para a página inicial pública).
- **NFR-040-003** [SHOULD] Visita anônima à página inicial não deve gerar registro de falha de autenticação que polua o monitoramento de segurança, sem suprimir o registro de tentativas com identificador de sessão forjado ou reutilizado (estratégia é do PLAN) [assumido, A-040-006] (satisfeito pelo serviço de sessão vigente, A-040-006; AC-040-013 prova não-regressão).
- **NFR-040-004** [SHOULD] O estado neutro deve durar o mínimo: a decisão (área interna ou página pública) sai em até 1 s em ambiente local com o serviço de sessão disponível [assumido, A-040-005]; informativo: medido e registrado na execução real em build de produção local; mediana acima de 1 s é achado ao PO (A-040-005), não reprova a entrega. O teto observável em qualquer ambiente é o de FR-040-011.
- **NFR-040-005** [MUST] A conferência da sessão não deve registrar nem exibir dado sensível (credenciais, tokens, identificador de sessão) em log, mensagem ou conteúdo da página.
- **NFR-040-006** [MUST] A conferência da sessão, e qualquer renovação que ela faça, só ocorre quando a página inicial é efetivamente aberta. O pré-carregamento de links que apontam para ela (logo, 404) não dispara conferência nem renovação.

## 7. Critérios de aceitação (Given-When-Then)
- **AC-040-001** (cobre FR-040-001, FR-040-002)
  Dado um visitante cuja conferência da sessão ainda não terminou, quando a página inicial é aberta, então a tela mostra o estado neutro, sem o conteúdo da página inicial pública e sem "Entrar" nem "Sair" no cabeçalho, até a decisão sair.
- **AC-040-002** (cobre FR-040-001, FR-040-003)
  Dado uma pessoa com sessão aceita agora e papel EDITOR ou ADMIN, quando ela abre a página inicial, então chega direto à página inicial da área interna e o conteúdo da página inicial pública nunca chegou a ser exibido.
- **AC-040-003** (cobre FR-040-004, FR-040-003)
  Dado uma pessoa que entrou há dias, cuja credencial de acesso venceu mas cujo token de renovação ainda vale, quando ela abre a página inicial, então a sessão é renovada sem pedir senha e ela chega direto à página inicial da área interna, sem tela de login e sem aviso.
- **AC-040-004** (cobre FR-040-005)
  Dado um visitante que nunca entrou, quando abre a página inicial, então vê a página inicial pública de hoje, sem ser levado à tela de login e sem aviso de sessão expirada.
- **AC-040-005** (cobre FR-040-005, NFR-040-002)
  Dado uma sessão vencida sem renovação possível, ou revogada (logout em outra aba, reuso de renovação, conta desativada), quando a pessoa abre a página inicial, então vê a página inicial pública, sem tela de login, sem aviso e sem acesso à área interna.
- **AC-040-006** (cobre FR-040-005, NFR-040-002, NFR-040-005)
  Dado um visitante com identificador de sessão forjado ou inválido, quando abre a página inicial, então vê a página inicial pública, sem acesso à área interna, sem tela de login e sem que o valor forjado apareça em conteúdo ou mensagem.
- **AC-040-007** (cobre FR-040-006, NFR-040-002)
  Dado que o serviço de sessão está indisponível ou a rede falha durante a conferência, quando a página inicial é aberta, então o estado neutro termina na página inicial pública, sem tela de login e sem aviso.
- **AC-040-008** (cobre FR-040-007, NFR-040-002)
  Dado uma conta com sessão reconhecida cujo papel não tem acesso à área interna, quando ela abre a página inicial, então permanece na página inicial pública e não é levada à área interna nem a nenhuma tela de recusa.
- **AC-040-009** (cobre FR-040-003, FR-040-008)
  Dado uma pessoa levada à área interna a partir da página inicial, quando ela aciona "voltar" do navegador, então não retorna à página inicial nem fica em laço entre a página inicial e a área interna.
- **AC-040-010** (cobre FR-040-009, FR-040-003)
  Dado uma pessoa com sessão reconhecida e papel com acesso na 404 ou dentro da área interna, quando clica no link de volta da 404, então chega à página inicial da área interna, e o link continua apontando para a página inicial. (O destino do logo do cabeçalho é coberto pela SPEC-044.)
- **AC-040-011** (cobre FR-040-015, FR-040-016)
  Dado um visitante anônimo, quando abre uma rota interna, então vai à tela de login com retorno, como antes; e a página inicial pública exibida a ele tem o mesmo conteúdo de antes.
- **AC-040-012** (cobre NFR-040-001)
  Dado uma sessão válida aberta em duas abas (ou com uma requisição concorrente em renovação), quando uma das abas abre a página inicial e a conferência ocorre, então a sessão continua válida na outra aba e na outra requisição, sem encerramento nem pedido de novo login.
- **AC-040-013** (cobre NFR-040-003)
  Dado um visitante sem sessão (sem pista, ou com pista mas sem sessão), quando abre a página inicial, então o serviço de sessão não registra nenhum evento de segurança novo durante a visita; e dado um visitante com identificador de sessão forjado, quando abre a página inicial, então os eventos registrados são os mesmos que esse identificador gera hoje numa requisição direta ao serviço de sessão.
- **AC-040-014** [informativo] (cobre NFR-040-004)
  Dado o ambiente local em build de produção com o serviço de sessão disponível e aquecido, quando a página inicial é aberta com pista e sessão reconhecida, ou sem pista, então o tempo até a decisão é medido e registrado, com alvo ≤ 1 s; acima do alvo é achado ao PO, não reprovação.
- **AC-040-015** (cobre FR-040-011, NFR-040-002)
  Dado um visitante com pista de sessão neste navegador e o serviço de sessão sem responder (pendurado ou lento), quando abre a página inicial, então em até 3 s o estado neutro termina na página inicial pública, sem tela de login e sem aviso.
- **AC-040-016** (cobre FR-040-012, FR-040-008)
  Dado uma pessoa com sessão reconhecida e papel com acesso cuja conferência só conclui depois de 3 s, quando ela abre a página inicial, então vê a página pública depois do teto e, quando a conferência conclui, é levada à página inicial da área interna, e o "voltar" não a devolve à página inicial.
- **AC-040-017** (cobre FR-040-013, FR-040-005)
  Dado uma pessoa que acabou de fazer logout, quando ela abre a página inicial na mesma aba, então vê a página inicial pública, sem ser levada à área interna, à tela de login ou a aviso de sessão expirada.
- **AC-040-018** (cobre FR-040-013, FR-040-005)
  Dado uma pessoa com a área interna aberta na aba A que fez logout na aba B, quando ela clica no logo do cabeçalho na aba A, então vê a página inicial pública, sem ser levada à tela de login e sem aviso de sessão expirada.
- **AC-040-019** (cobre FR-040-013, FR-040-003, FR-040-008)
  Dado um visitante que viu a página pública, entrou pela tela de login e chegou à área interna, quando aciona "voltar" do navegador até a página inicial, então é levado à página inicial da área interna, sem permanecer na página pública com a sessão reconhecida e sem laço entre as duas.
- **AC-040-020** (cobre NFR-040-006, NFR-040-001)
  Dado uma pessoa numa tela da área interna com o logo visível, quando a tela carrega e fica ociosa sem clique no logo, então nenhuma conferência nem renovação originada da página inicial acontece.
- **AC-040-021** (cobre FR-040-014)
  Dado um visitante com script desabilitado, quando abre a página inicial, então vê o conteúdo da página inicial pública de hoje.
- **AC-040-022** (cobre FR-040-016)
  Dado a página inicial obtida sem executar script (como faz um gerador de prévia de link), quando o documento é inspecionado, então título e descrição da página são os de antes desta SPEC.
- **AC-040-023** (cobre FR-040-003)
  Dado o app instalado, quando o manifesto é inspecionado, então o endereço de partida continua sendo a página inicial (o comportamento de chegada à área interna vem do AC-040-002).
- **AC-040-024** (cobre FR-040-010)
  Dado uma pessoa que entra pela tela de login, quando o login conclui, então vai ao destino de sempre; dado uma pessoa com sessão que faz logout, quando o logout conclui, então vai à tela de login, como antes.
- **AC-040-025** (cobre FR-040-017, FR-040-001)
  Dado uma pessoa com sessão reconhecida e papel com acesso cujo navegador não guarda pista de sessão, quando abre a página inicial, então vê a página inicial pública sem estado neutro e sem conferência; e, depois de passar pela área interna nesse navegador, a próxima abertura da página inicial a leva direto à área interna.

## 8. Premissas e decisões prévias
- **A-040-001** [assumido] [evidência: medido] "Sessão reconhecida" inclui a sessão que se renova sem nova senha, não só a que é aceita agora: a credencial de acesso vive ~15 min e o token de renovação ~7 dias (TTLs configuráveis; memo de exploração, fatos medidos: `auth.routes.ts:52-73`, `env.ts:65-66`). Default: valem os TTLs vigentes.
- **A-040-002** [assumido] [evidência: crença] Falha da conferência (serviço indisponível, erro de rede) resolve para a página inicial pública: a página é pública, então errar para ela não expõe nada; alternativa (manter estado neutro ou exibir erro) descartada por prender quem está anônimo. Derivado do critério 3 do card (na falha, pessoa e anônimo são indistinguíveis); fail secure.
- **A-040-003** [assumido] [evidência: medido] O papel sem acesso à área interna é hoje o de estudante, dormente (`internal-routes.ts:28,43-45`; glossário "Papel"). Fica na página inicial pública, sem aviso.
- **A-040-004** [assumido] [evidência: crença] A ida à área interna substitui a entrada no histórico (FR-040-008): é o comportamento esperado de um redirecionamento; default de indústria.
- **A-040-005** [assumido] [evidência: crença] Teto de 1 s para o estado neutro em ambiente local com o serviço de sessão disponível; sem baseline de produto. O PLAN mede e pode propor outro teto.
- **A-040-006** [assumido] [evidência: medido] O serviço de sessão **não** registra evento de segurança para a visita anônima: `POST /auth/refresh` sem token ou com token inexistente responde 401 sem evento (`auth.service.ts:311,326`); `GET /auth/me` sem sessão responde 401 sem evento (`authenticate.ts:58-61`); só se registram `login.*`, `token.refresh` (sucesso), `token.reuse`, `logout` e `authz.denied` (`lib/audit.ts`, linha `auth:<type>`). NFR-040-003 é satisfeito pelo serviço vigente; AC-040-013 é prova de não-regressão. (A v0.2 afirmava o contrário; corrigida na resolução pré-código, qa A1.)
- **A-040-007** [assumido] [evidência: crença] Enquanto a conferência dura, o anônimo também vê o estado neutro por um instante antes da página pública: custo aceito pelo Diretor na largada (BRIEF-040, "Premissas decididas"); não é tratado como defeito.
- **A-040-008** [assumido] [evidência: medido] Logo do cabeçalho (`site-header.tsx:13`) e link da 404 (`not-found.tsx:15`) apontam hoje para a página inicial. O link da 404 não muda (decisão do Diretor, BRIEF-040); o logo passa a seguir a SPEC-044 (emenda v0.5, KAN-178: o BRIEF-040 e o §4.2 original adiaram o logo por sessão a esse card).
- **A-040-009** [assumido] [evidência: crença] A "página inicial da área interna" é a entrada de sempre (o painel estratégico, SPEC-034); se o destino mudar, vale o destino vigente da área interna.
- **A-040-010** [assumido] [evidência: crença] Teto da conferência de 3 s escolhido pelo PO em nome do Diretor; o PLAN mede a latência da conferência completa em produção com serviço frio e registra; p95 medido acima do teto volta ao PO; não se troca em silêncio.
- **A-040-011** [assumido] [evidência: medido] Compatibilidade com SPEC-036: FR-036-001/002 e AC-036-002 inalterados; o neutro do cabeçalho na página inicial é o de FR-036-016; nenhuma emenda à SPEC-036.
- **A-040-012** [assumido] [evidência: medido] Emenda do termo "Home pública" (SPEC-019), com a nova redação do §3: a página inicial em `/` é exibida a quem não tem sessão reconhecida com papel com acesso; `/` segue destino fixo do link de volta da 404, e do logo quando não há sessão ativa com papel com acesso à área interna (SPEC-044, emenda v0.5). Promessa mantida: `/` nunca exige sessão nem leva à tela de login. Registro de versão: v0.5 — emenda pela SPEC-044 (KAN-178), veredito do PO em nome do Diretor.
- **A-040-013** [assumido] [evidência: medido] O endereço de partida do app instalado é a página inicial (NFR-013-007) e não muda.
- **A-040-014** [assumido] [evidência: crença] O navegador guarda uma **pista de sessão** (marca não-sensível de "houve sessão aqui", gravada no login e na área interna, apagada no logout e na conferência sem sessão) que decide **só se há conferência**, nunca acesso. Sem pista, a visita é tratada como anônima: Home pública imediata, sem estado neutro e sem conferência. Motivo: poupar o anônimo (público da vitrine) do estado neutro e de duas chamadas em série até o teto de 3 s — o BRIEF-040 aceitou "um instante" de neutro, não o teto. Exceção aceita: sessão reconhecida sem pista neste navegador (anterior a esta entrega, armazenamento limpo ou bloqueado) vê a página pública nessa abertura; com armazenamento limpo, corrige-se na próxima passagem pela área interna ou pelo login. Decisão do PO em nome do Diretor (resolução pré-código, 2026-09-30); reversível — a alternativa é conferir sempre (PLAN-041 DEC-041-002).

## 9. Riscos e questões abertas
- **RISK-040-001** Renovação concorrente: conferir a sessão a partir da página inicial pode competir com a renovação de outra aba/requisição; fora da janela de tolerância, o reuso de um token de renovação revoga a família inteira de sessão (SPEC-002) e derrubaria uma sessão válida. Mitigação: NFR-040-001 / AC-040-012; NFR-040-006 (sem conferência por pré-carregamento); a estratégia é decisão do PLAN.
- **RISK-040-002** Reabre a promessa de guarda de rota da SPEC-002 (DEC-003-011 / COMP-003-022: a guarda só roda onde a sessão é pressuposta) e testes que a protegem, pois a página inicial pública passa a consultar a sessão. FR-040-015 exige a guarda intacta; o PLAN deve dizer se preserva a promessa ou a reabre explicitamente.
- **RISK-040-003** Percepção de piscada: o anônimo vê um instante de estado neutro antes da página pública (A-040-007) e quem tem sessão pode perceber o intervalo até a área interna. Mitigação: NFR-040-004, teto de FR-040-011; pessoa com sessão sob serviço frio vê a página pública por um instante antes da ida tardia (FR-040-012).
- **RISK-040-004** Papel sem acesso preso na página pública: se o papel de estudante voltar a ter conta ativa, ele permanece na página pública sem mensagem (fora de escopo, §4.2); outras rotas continuam com o comportamento atual. Com pista, cada abertura da página inicial por esse papel gera um `authz.denied` a mais (o cabeçalho já gera um por página hoje); a pista é preservada em `no-access` (resolução pré-código). Reabrir junto com Q-040-002.
- **RISK-040-005** Pessoa com sessão reconhecida sob falha da conferência cai na página pública, possivelmente com "Entrar" no cabeçalho, e pode digitar a senha sem necessidade. Recuperação: recarga da página inicial (FR-040-013); clicar no logo estando já na página inicial não confere de novo (§4.2); lentidão tem a ida tardia (FR-040-012). Sem nova tentativa automática.
- **RISK-040-006** Exceção da pista (A-040-014): (i) na primeira abertura de `/` após o deploy, toda sessão existente vê a página pública até passar pela área interna; (ii) navegador com armazenamento local bloqueado nunca é redirecionado (a área interna segue alcançável por endereço e login). Mitigação: regravação da pista na área interna e no login; declarado no relatório de aceitação. Reabrir DEC-041-002 se observado como problema real.
- **Q-040-001** Fora de escopo, para card próprio: `/login` e futuras páginas públicas com sessão reconhecida devem também levar à área interna?
- **Q-040-002** Fora de escopo, para card próprio: o papel sem acesso à área interna deve receber alguma mensagem ou caminho quando voltar a ter conta ativa?
- **Q-040-003** Se o PLAN demonstrar que o AC-040-013 exige mudança no backend, volta ao PO (conflito com o fora de escopo do BRIEF-040).

## 10. Fora deste documento
Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
