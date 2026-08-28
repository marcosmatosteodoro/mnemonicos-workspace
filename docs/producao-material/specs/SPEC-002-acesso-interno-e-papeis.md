# SPEC-002: Acesso interno e papéis de produção

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.1
**Autor**: time keelson (scribe)
**Data**: 2026-08-28
**Jira**: KAN-7
**Brief**: BRIEF-002

## 1. Contexto e objetivo

### 1.1 Problema

A fábrica interna de produção do material mnemônico (épico MNEMORA STUDIO) pressupõe uma
equipe interna com papéis distintos e uma barreira de autorização no servidor. Nenhum dos
dois existe hoje:

- Não há rota de login nem de logout. Só `health`, `health/db` e `disciplines` estão
  expostas; o modelo de usuário e o segredo de sessão existem na configuração, mas nada os
  liga a um fluxo de acesso.
- Não há autorização. Qualquer requisição alcança qualquer rota montada; não há noção de
  papel aplicada no servidor.
- Sem isso, o gate de **Versão aprovada** previsto para a fatia F9 (checagem jurídica e
  pedagógica antes da exportação) e a regra "revisor jurídico ≠ autor" (A-010, herdada do
  BRIEF-001) não têm base: não há como saber quem está agindo, nem separar quem produz de
  quem aprova.
- O frontend já assume o modelo de sessão desta fatia (credenciais em cookie, nada em
  armazenamento local), mas não há contraparte no servidor e o tipo de papel existe só de
  um lado dos dois repositórios.

### 1.2 Outcome esperado

A equipe interna da fábrica autentica-se e mantém sessão. Toda rota não-pública passa a
ser recusada por padrão e só é alcançada por quem tem sessão válida e o papel exigido. Um
ADMIN provisiona as contas internas (criar, listar, desativar, resetar senha) e o primeiro
ADMIN nasce do processo de carga inicial (seed), sem senha embutida. Logout e desativação
de conta encerram a sessão de verdade, no servidor. A partir daqui, as fatias seguintes
podem declarar rotas protegidas por papel sem reconstruir acesso.

### 1.3 Métrica de sucesso

- **Cobertura de barreira**: 100% das rotas não-públicas montadas recusam requisição sem
  sessão válida, e 100% das rotas restritas recusam papel insuficiente — aferido a cada
  execução de CI (contínuo) pela suíte de integração que enumera as rotas montadas e
  exercita cada uma sem sessão e com papel insuficiente.
- **Ausência de auto-registro**: 0 contas internas criáveis por caminho público — nenhuma
  rota de registro na superfície montada.

**Fonte de medição**: externa — a suíte de integração no CI (dono: time de engenharia) que
enumera as rotas montadas e exercita cada uma sem sessão e com papel insuficiente; é uma
métrica de conformidade, verde ou vermelha a cada execução. Os eventos de **Auditoria de
autenticação**/autorização são entregável desta fatia e insumo de investigação, **não** a
fonte desta métrica — a leitura deles (UI, exportação, retenção) está fora de escopo
(§4.2). A fatia F9 relê o número quando o gate de aprovação editorial passar a depender
dele.

## 2. Personas e jobs-to-be-done

- **EDITOR — produtor de conteúdo interno.** Escreve e estrutura o material mnemônico.
  *Job*: entrar na fábrica e alcançar as rotas de produção que o seu papel permite, sem
  poder tocar a gestão de contas.
- **ADMIN — gestor da plataforma interna.** *Job*: provisionar e desativar contas da
  equipe, resetar senha quando alguém perde acesso e — papel acumulado até a fatia F9
  decidir se separa — conduzir a revisão jurídica e a aprovação de versão. Precisa
  alcançar as rotas de gestão e de revisão.

**Anti-persona**: o estudante concursando — nenhum fluxo desta fatia é para ele; o papel
STUDENT segue dormente e sem rota que o exponha (A-002-015).

## 3. Glossário (Ubiquitous Language)

| Termo | Definição | Origem |
|-------|-----------|--------|
| **Versão aprovada** | Estado em que a checagem jurídica e a pedagógica passaram e o material está liberado para exportação — o gate da fatia F9 | INDEX / BRIEF-001 |
| **Sessão autenticada** | Vínculo entre uma requisição e uma conta interna ativa, estabelecido por login e válido enquanto não expira nem é revogado | SPEC-002 |
| **Credencial de acesso** | Prova de sessão de vida curta (~15 min), transportada em cookie inacessível a script, que o servidor confere a cada requisição | SPEC-002 |
| **Token de renovação** | Segredo de vida mais longa, persistido de forma revogável, que troca uma credencial de acesso expirada por uma nova sem novo login | SPEC-002 |
| **Rotação de token** | A cada renovação, o token de renovação usado é invalidado e um novo é emitido; apresentar um token já rotacionado é sinal de reuso | SPEC-002 |
| **Família de sessão** | O conjunto de tokens de renovação encadeados por rotação a partir de um mesmo login; revogada por inteiro quando há reuso ou logout | SPEC-002 |
| **Papel** | Atributo da conta que define o que ela alcança: `STUDENT` (dormente), `EDITOR` (produção/autoria), `ADMIN` (gestão de contas + revisão jurídica + aprovação de versão) — enum inalterado | Memo de exploração / BRIEF-002 |
| **Deny-by-default** | Postura em que uma rota é inacessível a menos que declare explicitamente os papéis que podem alcançá-la; ausência de declaração nega | BRIEF-002 |
| **Conta desativada** | Conta marcada como inativa de forma reversível, com marca temporal; não autentica e tem as sessões revogadas | SPEC-002 |
| **Provisionamento de conta** | Criação de conta interna por um ADMIN ou pelo seed — nunca por auto-registro | SPEC-002 |
| **Auditoria de autenticação** | Registro dos eventos de login, renovação, logout, bloqueio temporário e decisão de autorização, sem dado sensível | SPEC-002 |

## 4. Escopo

### 4.1 In-scope

1. Login e logout para contas internas; sessão autenticada de vida curta com renovação
   silenciosa por token rotacionado.
2. Autorização no servidor, **deny-by-default** por papel, em toda rota não-pública.
3. Gestão de contas internas restrita a ADMIN: criar, listar, desativar (reversível) e
   resetar senha.
4. Primeiro ADMIN criado pelo seed a partir de credenciais fornecidas por configuração de
   ambiente, sem senha padrão embutida.
5. Papéis `STUDENT` / `EDITOR` / `ADMIN` mantidos como estão; o papel é definido na criação
   da conta.
6. Frontend mínimo: formulário de login, controle de logout e guard de rota do lado do
   cliente — o bastante para exercitar o acesso, o encerramento de sessão e a barreira.
7. Paridade do conjunto de papéis e do formato do usuário de sessão entre
   `mnemonicos-frontend/src/types/domain.ts` e `mnemonicos-backend/src/domain/types.ts`.
8. Eventos de auditoria de autenticação/autorização sem dado sensível; limite de taxa
   dedicado à rota de login.
9. Conjunto público desta fatia **fechado**: `health`, `health/db`, a rota de login e a
   rota de renovação de sessão — e nenhuma outra; toda rota não listada nasce protegida
   (deny-by-default). `/disciplines` passa a exigir sessão válida (EDITOR ou ADMIN) nesta
   fatia; o contrato definitivo de `/disciplines` é da fatia F2.

### 4.2 Out-of-scope

- **Recuperação de senha self-service** (link por e-mail, "esqueci minha senha"): fora — o
  reset de senha por terceiro é ação de ADMIN sobre a conta. Trocar a própria senha de
  forma autenticada, informando a senha atual, **entra** — FR-002-024.
- **2FA / MFA e SSO / provedores de identidade externos**: fora.
- **"Lembrar-me" / sessão longa** além da janela de 7 dias do token de renovação: fora.
- **Exclusão definitiva de conta / apagamento de dados**: fora — a desativação é reversível.
- **Reativar conta desativada**: fora — de fatia posterior. "Reversível" nesta fatia
  significa que o dado é preservado (marca temporal de desativação, sem exclusão), não que
  exista uma operação de reativação. Desfazer uma desativação acidental no piloto exige
  intervenção direta no banco — contido por FR-002-019 (não se desativa o último ADMIN).
- **Alterar o papel de uma conta existente**: fora (o papel é fixado na criação; a mudança
  de papel é de fatia posterior) — ver A-002-013. A proteção do último ADMIN considera o
  rebaixamento apenas *se e quando* essa operação existir.
- **UI completa de gestão de equipe no frontend**: fora — só as telas mínimas de login,
  logout e guard entram; a gestão roda por rota de API.
- **Preservação de rascunho de conteúdo longo quando a sessão expira**: fora — F1 não tem
  formulário longo; é de F2/F4.
- **Rotas `/mnemonics` e `/flashcards/due`** já chamadas pelo frontend sem existir no
  servidor: fora — são da fatia F2.
- **Qualquer superfície voltada ao estudante** (login de estudante, vitrine pública,
  `CardState` por usuário, scheduler SM-2, `study-slice`, papel STUDENT ativo): fora,
  dormente por A-002-015.
- **Separar o papel de revisor jurídico do de ADMIN** e uma checagem de segregação de
  funções aplicada pelo sistema: fora — é decisão da fatia F9.
- **UI de trilha de auditoria / exportação para SIEM / política de retenção**: fora — esta
  fatia apenas emite os eventos.
- **Autogestão de perfil** (a própria conta muda e-mail ou nome por uma tela de
  configurações): fora. Trocar a própria senha de forma autenticada é a única autogestão
  desta fatia (FR-002-024).

## 5. Requisitos funcionais (EARS)

Há três fluxos entregáveis e testáveis de ponta a ponta de forma independente — a camada
FEAT é declarada. Cada FR pertence a exatamente uma FEAT.

### FEAT-002-001: Autenticação de sessão

> Do ponto de vista do QA: a equipe interna faz login, a sessão se mantém por renovação
> silenciosa com token rotacionado, e logout ou desativação encerram a sessão de verdade
> no servidor.

**Jira**: KAN-8

- **FR-002-001** [MUST] Quando uma conta interna ativa envia e-mail e senha corretos à
  rota de login, o sistema DEVE estabelecer uma sessão autenticada: emitir uma credencial
  de acesso de vida curta em cookie inacessível a script e um token de renovação persistido
  de forma revogável, e registrar um evento de auditoria de autenticação de sucesso.
- **FR-002-002** [MUST] Se as credenciais enviadas à rota de login são inválidas, então o
  sistema DEVE recusar com uma falha de autenticação genérica que não revela se o e-mail
  existe ou se a senha está errada, e DEVE registrar um evento de auditoria de falha sem
  senha nem valor de token.
- **FR-002-003** [MUST] Quando a credencial de acesso está expirada e o token de renovação
  apresentado é válido e ainda não rotacionado, o sistema DEVE emitir nova credencial de
  acesso e rotacionar o token de renovação, invalidando o token anterior.
- **FR-002-004** [MUST] Se um token de renovação já rotacionado é apresentado de novo,
  então o sistema DEVE revogar toda a família de sessão daquele usuário.
- **FR-002-005** [MUST] O token de renovação DEVE ter expiração absoluta de 7 dias.
  Quando um token de renovação é apresentado após esse prazo, o sistema DEVE recusar a
  renovação e exigir nova autenticação.
- **FR-002-006** [MUST] Quando o usuário solicita logout, o sistema DEVE revogar a sessão
  no servidor, invalidando a família do token de renovação, e limpar o cookie de sessão.
- **FR-002-007** [MUST] Enquanto uma sessão está revogada ou o usuário dono dela está
  desativado, o sistema DEVE rejeitar qualquer requisição que a apresente, mesmo que a
  credencial de acesso ainda não tenha expirado.
- **FR-002-008** [MUST] Se as tentativas de login excedem o limite de taxa dedicado —
  avaliado por chave composta de identificador da conta tentada **e** origem, com limiar
  estrito por conta e limiar mais frouxo por origem —, então o sistema DEVE atrasar ou
  recusar temporariamente as novas tentativas que dispararam o limiar, sem bloquear a
  conta de forma dura em nenhum dos casos, e DEVE registrar um evento de auditoria de
  bloqueio temporário. Valores e mecanismo são do PLAN.
- **FR-002-009** [MUST] Quando o usuário submete o formulário de login na interface mínima,
  o sistema DEVE refletir três estados observáveis: *em andamento* — o controle de
  submissão fica desabilitado e um indicador de progresso aparece; *sucesso* — o usuário é
  levado à área interna; *falha* — uma mensagem de erro genérica em pt-BR é exibida, o
  formulário volta a aceitar entrada e nenhum campo é apontado como a causa.
- **FR-002-023** [MUST] Quando o usuário aciona o controle de logout na interface mínima,
  o sistema DEVE refletir três estados observáveis: *em andamento* — o controle fica
  desabilitado e um indicador de progresso aparece; *sucesso* — a sessão é encerrada (a
  família do token de renovação é revogada no servidor, o cookie de sessão é limpo) e o
  usuário é levado de volta ao login; *falha* — uma mensagem genérica em pt-BR é exibida,
  o usuário permanece na área interna e pode tentar de novo.

### FEAT-002-002: Autorização por papel

> Do ponto de vista do QA: toda rota não-pública recusa quem não tem sessão; rotas
> restritas recusam quem não tem o papel; a decisão vale no servidor a cada requisição, e
> o guard de rota do cliente é só conveniência de navegação.

**Jira**: KAN-9

- **FR-002-010** [MUST] O sistema DEVE recusar por padrão toda rota não-pública: uma
  requisição sem sessão autenticada válida DEVE receber uma resposta de não-autorizado e
  nenhum dado específico da rota.
- **FR-002-011** [MUST] Quando uma requisição autenticada atinge uma rota restrita a um
  conjunto de papéis e o papel da sessão não está nesse conjunto, o sistema DEVE recusar
  com uma resposta de proibido e registrar um evento de auditoria de autorização.
- **FR-002-012** [MUST] O sistema DEVE decidir a autorização no servidor a cada
  requisição; o guard de rota do cliente é conveniência de navegação e NÃO PODE ser a
  única barreira.
- **FR-002-013** [MUST] Quando o usuário navega até uma vista interna protegida, o sistema
  DEVE refletir três estados observáveis: *em andamento* — enquanto a sessão é resolvida,
  um estado de carregamento neutro é exibido; *sucesso* — com sessão válida e papel
  suficiente, a vista é renderizada; *falha* — sem sessão válida o usuário é redirecionado
  ao login, e com sessão válida mas papel insuficiente uma mensagem "sem permissão" é
  exibida sem o conteúdo da vista.

### FEAT-002-003: Provisionamento de contas internas

> Do ponto de vista do QA: um ADMIN cria, lista, desativa e reseta senha de contas
> internas; não há auto-registro; o seed cria o primeiro ADMIN a partir de configuração de
> ambiente e nunca de uma senha embutida.

**Jira**: KAN-10

- **FR-002-014** [MUST] Quando um ADMIN autenticado envia uma nova conta interna com
  e-mail, nome, papel `EDITOR` ou `ADMIN` e senha inicial, o sistema DEVE criar a conta
  com o papel informado e registrá-la; o papel é definido na criação.
- **FR-002-015** [MUST] Se o e-mail informado na criação já pertence a uma conta, então o
  sistema DEVE recusar com uma resposta de conflito e NÃO PODE alterar a conta existente.
- **FR-002-016** [MUST] O sistema DEVE manter a superfície montada livre de qualquer
  caminho de auto-registro: uma conta interna DEVE ser criada apenas por um ADMIN
  autenticado ou pelo seed.
- **FR-002-017** [MUST] Quando um ADMIN autenticado solicita a lista de contas internas, o
  sistema DEVE retornar cada conta com e-mail, nome, papel e situação (ativa ou
  desativada), e NUNCA qualquer material de senha ou token.
- **FR-002-018** [MUST] Quando um ADMIN desativa uma conta, o sistema DEVE marcá-la como
  desativada de forma reversível, com marca temporal de desativação, revogar as sessões
  daquele usuário e, enquanto a conta estiver desativada, rejeitar a autenticação dele.
- **FR-002-019** [MUST] Se desativar uma conta — ou, quando essa operação existir, tirar
  dela o papel `ADMIN` — deixaria zero ADMINs ativos, então o sistema DEVE recusar a
  operação.
- **FR-002-020** [MUST] Quando um ADMIN reseta a senha de uma conta, o sistema DEVE
  definir a nova senha sujeita à política de senha interna e revogar as sessões ativas
  daquela conta.
- **FR-002-021** [MUST] Onde as credenciais de bootstrap do ADMIN são fornecidas por
  configuração de ambiente, o seed DEVE criar exatamente um ADMIN inicial a partir delas;
  onde essas credenciais não são fornecidas, o seed DEVE terminar sem criar ADMIN algum e
  NÃO PODE recorrer a senha padrão embutida.
- **FR-002-022** [MUST] O sistema DEVE recusar qualquer senha de conta interna com menos
  de 12 caracteres, tanto na criação quanto no reset.
- **FR-002-024** [MUST] Quando um usuário autenticado troca a própria senha informando a
  senha atual correta e uma nova senha conforme a política de 12 caracteres, o sistema
  DEVE atualizar a senha e revogar as demais sessões daquela conta. Se a senha atual
  informada está errada, então o sistema DEVE recusar sem alterar a senha.

## 6. Requisitos não-funcionais

- **NFR-002-001** [MUST] A postura de autorização DEVE ser deny-by-default: uma rota é
  inacessível a menos que declare explicitamente os papéis que podem alcançá-la; uma rota
  adicionada sem essa declaração DEVE falhar fechada (negar), nunca abrir.
- **NFR-002-002** [MUST] Toda rota que lê ou escreve dado pessoal — nesta fatia ou em
  fatias futuras — DEVE resolver a identidade alvo a partir da sessão autenticada, nunca
  de um parâmetro de rota ou de consulta.
- **NFR-002-003** [MUST] A senha de conta interna DEVE ser persistida apenas como saída de
  uma função de derivação de senha resistente a força bruta, com parâmetros de custo
  configuráveis; a senha em claro NUNCA é persistida nem registrada em log.
- **NFR-002-004** [MUST] O segredo de sessão, o valor da credencial de acesso e o valor do
  token de renovação NÃO PODEM aparecer em log nem em qualquer resposta da API.
- **NFR-002-005** [MUST] Os eventos de auditoria de autenticação e de autorização NÃO
  PODEM conter dado sensível (senha, valor de token, credencial completa); DEVEM conter o
  suficiente para investigar: marca temporal, resultado, referência ao sujeito e um
  indicador da origem.
- **NFR-002-006** [MUST] O limite de taxa da rota de login DEVE ser dedicado e mais
  estrito que o limite global da API, operado por chave composta — identificador da conta
  tentada **e** origem — com limiares distintos: estrito por conta (contém força bruta
  dirigida), calibrado por origem para não deter uma equipe interna atrás de um único IP
  de escritório. NÃO PODE impor bloqueio duro de conta em nenhum dos dois eixos. Valores e
  mecanismo são do PLAN.
- **NFR-002-007** [MUST] O conjunto de papéis e o formato do usuário de sessão DEVEM ser
  mantidos em sincronia entre `mnemonicos-frontend/src/types/domain.ts` e
  `mnemonicos-backend/src/domain/types.ts`: uma alteração em um lado entra no mesmo diff
  que o outro.
- **NFR-002-008** [MUST] O cookie de sessão DEVE ser inacessível a script, trafegar apenas
  sob canal seguro em produção e ter política de submissão same-site.
- **NFR-002-009** [MUST] Identificadores de código DEVEM ser em inglês e o texto de
  interface DEVE ser em pt-BR, nos dois repositórios.

## 7. Critérios de aceitação (Given-When-Then)

- **AC-002-001** (cobre FR-002-001, NFR-002-008) — Dado uma conta interna ativa, Quando
  ela envia e-mail e senha corretos à rota de login, Então a resposta estabelece uma
  sessão autenticada: um cookie de sessão inacessível a script é definido (apenas sob
  canal seguro em produção, com política same-site), um token de renovação é persistido de
  forma revogável e um evento de auditoria de sucesso é registrado.
- **AC-002-002** (cobre FR-002-002, NFR-002-005) — Dada a rota de login, Quando as
  credenciais estão erradas, Então a resposta é uma falha de autenticação genérica que não
  distingue e-mail inexistente de senha errada, e um evento de auditoria de falha é
  registrado sem senha e sem valor de token.
- **AC-002-003** (cobre FR-002-008, NFR-002-006) — Dada a rota de login, Quando as
  tentativas excedem o limiar da conta tentada e/ou o limiar da origem, Então novas
  tentativas que dispararam o limiar são recusadas ou atrasadas temporariamente sem que a
  conta seja bloqueada de forma dura, um evento de auditoria de bloqueio temporário é
  registrado, e uma conta legítima vinda de outra origem continua conseguindo autenticar;
  e uma segunda conta legítima vinda da mesma origem, com credenciais corretas, continua
  conseguindo autenticar enquanto o limiar dela não é excedido.
- **AC-002-004** (cobre FR-002-003) — Dada uma credencial de acesso expirada acompanhada
  de um token de renovação válido e ainda não rotacionado, Quando o cliente chama o
  caminho de renovação, Então uma nova credencial de acesso é emitida, o token de
  renovação é rotacionado e o token anterior deixa de funcionar.
- **AC-002-005** (cobre FR-002-004) — Dado um token de renovação que já foi rotacionado,
  Quando ele é apresentado outra vez, Então toda a família de sessão daquele usuário é
  revogada e qualquer renovação ou acesso subsequente com tokens dessa família falha.
- **AC-002-006** (cobre FR-002-005) — Dado um token de renovação com mais de 7 dias,
  Quando ele é apresentado, Então a renovação é recusada e o usuário precisa autenticar de
  novo.
- **AC-002-007** (cobre FR-002-006) — Dada uma sessão autenticada, Quando o usuário faz
  logout, Então a família do token de renovação é revogada no servidor e o cookie de
  sessão é limpo; reapresentar o cookie ou o token anteriores ao logout é rejeitado.
- **AC-002-008** (cobre FR-002-007) — Dado um usuário cuja conta foi desativada ou cuja
  sessão foi revogada, Quando uma requisição apresenta essa sessão, Então ela é rejeitada
  como não-autorizada mesmo que a credencial de acesso ainda não tenha expirado.
- **AC-002-009** (cobre FR-002-009, NFR-002-009) — Dada a tela de login, Quando o usuário
  submete o formulário, Então enquanto a requisição está pendente o controle de submissão
  fica desabilitado e um indicador de progresso aparece; em caso de sucesso o usuário
  chega à área interna; em caso de falha uma mensagem de erro genérica em pt-BR é exibida,
  o formulário volta a aceitar entrada e nenhum campo é apontado como a causa.
- **AC-002-010** (cobre FR-002-010) — Dada qualquer rota não-pública, Quando ela é chamada
  sem sessão válida, Então a resposta é um erro de não-autorizado e nenhum dado específico
  da rota é retornado.
- **AC-002-011** (cobre FR-002-011) — Dada uma rota restrita a ADMIN, Quando um EDITOR
  autenticado a chama, Então a resposta é um erro de proibido e um evento de auditoria de
  autorização é registrado; Quando um ADMIN autenticado a chama, Então a requisição
  prossegue.
- **AC-002-012** (cobre FR-002-012) — Dada uma rota que o guard de rota do cliente
  esconderia, Quando ela é chamada diretamente, sem passar pelo cliente, Então o servidor
  ainda aplica a checagem de sessão e de papel.
- **AC-002-013** (cobre FR-002-013) — Dado o shell interno, Quando o usuário navega até
  uma vista protegida, Então enquanto a sessão é resolvida um estado de carregamento
  neutro é exibido; com sessão válida e papel suficiente a vista é renderizada; sem sessão
  válida o usuário é redirecionado ao login; com sessão válida mas papel insuficiente uma
  mensagem "sem permissão" é exibida sem o conteúdo da vista.
- **AC-002-014** (cobre FR-002-010, NFR-002-001) — Dada uma rota recém-adicionada que não
  declara os papéis que podem alcançá-la, Quando ela é atingida, Então o acesso é negado
  (falha fechada), não liberado.
- **AC-002-015** (cobre FR-002-012, NFR-002-002) — Dada uma rota que lê dado pessoal
  (nesta fatia ou futura), Quando a requisição informa em um parâmetro de rota ou de
  consulta uma identidade diferente da identidade da sessão, Então a resposta reflete
  apenas os dados da identidade da sessão.
- **AC-002-016** (cobre FR-002-014, FR-002-022) — Dado um ADMIN autenticado, Quando ele
  cria uma conta com e-mail, nome, papel `EDITOR` ou `ADMIN` e senha de ao menos 12
  caracteres, Então a conta é criada com esse papel; Quando a senha tem menos de 12
  caracteres, Então a criação é recusada.
- **AC-002-017** (cobre FR-002-015) — Dado um e-mail já usado por uma conta, Quando um
  ADMIN tenta criar outra conta com o mesmo e-mail, Então a resposta é de conflito e a
  conta existente permanece inalterada.
- **AC-002-018** (cobre FR-002-016) — Dada a API publicada, Quando um cliente sem sessão
  de ADMIN tenta criar uma conta ou procura uma rota de auto-registro, Então nenhuma
  dessas capacidades está disponível (não-autorizado, proibido ou inexistente).
- **AC-002-019** (cobre FR-002-017) — Dadas contas internas existentes, Quando um ADMIN as
  lista, Então cada item mostra e-mail, nome, papel e situação (ativa ou desativada) e não
  contém hash de senha nem token.
- **AC-002-020** (cobre FR-002-018) — Dado um EDITOR ativo com sessão em uso, Quando um
  ADMIN desativa essa conta, Então ela é marcada como desativada com marca temporal, as
  sessões do EDITOR param de funcionar de imediato e ele não consegue mais fazer login
  enquanto a conta estiver desativada.
- **AC-002-021** (cobre FR-002-019) — Dado exatamente um ADMIN ativo, Quando um ADMIN
  tenta desativar esse último ADMIN ativo ou tirar dele o papel `ADMIN`, Então a operação
  é recusada.
- **AC-002-022** (cobre FR-002-020) — Dada uma conta com sessão em uso, Quando um ADMIN
  reseta a senha dela para um valor conforme a política, Então a nova senha autentica e as
  sessões anteriores daquela conta são revogadas.
- **AC-002-023** (cobre FR-002-021) — Dado um ambiente novo com credenciais de bootstrap
  do ADMIN configuradas, Quando o seed roda, Então existe exatamente um ADMIN com essas
  credenciais; Dado um ambiente sem essa configuração, Quando o seed roda, Então nenhum
  ADMIN é criado e não há senha padrão embutida.
- **AC-002-024** (cobre FR-002-014, FR-002-020, NFR-002-003, NFR-002-004) — Dada a criação
  de uma conta ou um reset de senha, Quando o registro persistido e os logs são
  inspecionados, Então a senha aparece apenas como saída de uma função de derivação
  resistente a força bruta com parâmetros de custo configuráveis — nunca em claro — e
  nenhuma linha de log ou resposta da API contém a senha, o valor da credencial de acesso
  ou o valor do token de renovação.
- **AC-002-025** (cobre NFR-002-007) — Dados os dois repositórios, Quando a lista de
  papéis de domínio é comparada, Então `mnemonicos-frontend/src/types/domain.ts` e
  `mnemonicos-backend/src/domain/types.ts` expõem o mesmo conjunto de valores de papel.
- **AC-002-026** (cobre FR-002-003, FR-002-004) — Dado uma sessão legítima válida, Quando
  duas renovações da mesma família de sessão chegam concorrentemente, Então ambas recebem
  credencial de acesso válida e a família NÃO é revogada; Dado o token de renovação
  anterior, Quando ele é apresentado após a janela de graça, Então a família é revogada.
- **AC-002-027** (cobre FR-002-023) — Dado um usuário autenticado na área interna, Quando
  ele aciona o logout, Então enquanto a requisição está pendente o controle fica
  desabilitado com indicador de progresso; em sucesso a família do token de renovação é
  revogada no servidor, o cookie de sessão é limpo e o usuário volta ao login; reapresentar
  o cookie ou o token anteriores ao logout é rejeitado.
- **AC-002-028** (cobre FR-002-003, FR-002-007) — Dado uma requisição autenticada em
  curso, Quando a credencial de acesso expira, Então o servidor recusa com não-autorizado,
  o cliente tenta a renovação silenciosa e repete a requisição uma vez; Quando a renovação
  falha (família revogada, conta desativada ou token além dos 7 dias), Então a requisição
  não é reenviada, uma mensagem genérica em pt-BR é exibida e o usuário é levado ao login.
- **AC-002-029** (cobre FR-002-024, NFR-002-003) — Dado um usuário autenticado, Quando ele
  troca a própria senha informando a senha atual correta e uma nova senha de ao menos 12
  caracteres, Então a nova senha passa a autenticar, as demais sessões da conta são
  revogadas e a senha é persistida apenas como saída da função de derivação resistente;
  Quando a senha atual informada está errada, Então a troca é recusada e a senha permanece
  inalterada.

## 8. Premissas e decisões prévias

- **A-002-001** [assumido] [evidência: crença] O escopo da fatia F1 é autenticação
  (login/logout, sessão) + autorização no servidor deny-by-default por papel + gestão de
  contas internas restrita a ADMIN (criar, listar, desativar, resetar senha); sem
  auto-registro; o seed cria o primeiro ADMIN. Decisão do Diretor (última chamada,
  2026-08-28).
- **A-002-002** [assumido] [evidência: crença] Os papéis seguem o enum atual
  `STUDENT` / `EDITOR` / `ADMIN`, sem alteração. STUDENT segue dormente; EDITOR =
  produção/autoria; ADMIN = gestão de contas + revisão jurídica + aprovação de versão
  (acumulado até a fatia F9 decidir se separa). Decisão do Diretor (2026-08-28).
- **A-002-003** [assumido] [evidência: crença] A sessão é uma credencial de acesso de vida
  curta (~15 min) em cookie inacessível a script mais um token de renovação com rotação,
  persistido de forma revogável; logout e desativação de conta invalidam a sessão no
  servidor. Decisão do Diretor (2026-08-28).
- **A-002-004** [assumido] [evidência: crença] A migração de banco é decisão de
  implementação — o ciclo roda a migração no banco local e o arquivo versionado entra no
  diff da TASK; não é assunto desta SPEC. Decisão do Diretor (2026-08-28).
- **A-002-005** [assumido] [evidência: crença] Limite de taxa dedicado à rota de login,
  mais estrito que o limite global da API; sem bloqueio duro de conta (evita negação de
  serviço por bloqueio); tentativas de login (sucesso, falha, bloqueio temporário)
  auditadas sem dado sensível. Default de indústria: throttling contém força bruta sem
  criar vetor de DoS por lockout.
- **A-002-006** [assumido] [evidência: crença] Política de senha para conta interna:
  mínimo de 12 caracteres. Default de indústria: comprimento como principal fator de força
  e 12 como piso corrente para contas com privilégio.
- **A-002-007** [assumido] [evidência: crença] Rotação do token de renovação com detecção
  de reuso: apresentar um token já rotacionado revoga toda a família de sessão daquele
  usuário. Default de indústria: boas práticas de refresh token para clientes públicos.
- **A-002-008** [assumido] [evidência: crença] Expiração absoluta do token de renovação: 7
  dias; enquanto válido, renova a credencial de acesso. Default de indústria: janela curta
  o bastante para limitar a exposição de um token roubado, longa o bastante para não
  forçar login diário.
- **A-002-009** [assumido] [evidência: crença] Cookie de sessão: inacessível a script,
  enviado só sob canal seguro em produção, com política de submissão same-site. Default de
  indústria: gestão de sessão OWASP.
- **A-002-010** [assumido] [evidência: crença] O primeiro ADMIN é criado pelo seed a
  partir de credenciais fornecidas por configuração de ambiente; sem senha padrão embutida
  — sem a configuração, o seed não cria admin. O `.env.example` ganha os campos com
  placeholder. Default de indústria: bootstrap sem segredo embutido.
- **A-002-011** [assumido] [evidência: crença] "Desativar usuário" é desativação
  reversível (marca temporal de desativação); usuário desativado não autentica e tem as
  sessões revogadas. Default de indústria: preserva trilha e histórico ante a exclusão.
- **A-002-012** [assumido] [evidência: crença] Proteção do último ADMIN: o sistema recusa
  desativar (ou, se e quando essa operação existir, rebaixar) o último ADMIN ativo.
  Default de indústria: previne lockout administrativo.
- **A-002-013** [assumido] [evidência: crença] Alterar o papel de um usuário existente
  fica fora do escopo de F1 — o papel é definido na criação; a mudança de papel é de fatia
  posterior (ver §4.2). Decisão do Diretor (2026-08-28).
- **A-002-014** [assumido] [evidência: crença] Toda futura leitura de dado pessoal filtra
  por identidade da sessão, nunca por parâmetro de rota (deny-by-default) — registrado como
  NFR-002-002 mesmo que os endpoints de dado pessoal sejam de fatias futuras. Decisão do
  Diretor (2026-08-28).
- **A-002-015** [assumido] [evidência: crença] Herdada de BRIEF-001 A-005: o código
  construído para o estudante (`User` + auth do estudante, `CardState`, `Review`, scheduler
  SM-2, `study-slice`, vitrine pública) segue dormente. F1 acorda apenas o caminho de
  autenticação da equipe interna; o papel STUDENT segue dormente, sem rota que o exponha.
- **A-002-016** [assumido] [evidência: crença] Herdada de BRIEF-001 A-010: revisor
  jurídico ≠ autor. Com o papel de revisão acumulado no ADMIN, a regra se cumpre no piloto
  com dois ADMINs distintos — ver RISK-002-001.
- **A-002-017** [assumido] [evidência: crença] O time interno do piloto tem ao menos duas
  pessoas, com contas ADMIN distintas (decisão do Diretor, 2026-08-28). Se o piloto rodar
  com uma pessoa, A-010 não se cumpre por controle de sistema nem em F1 nem em F9 — ver
  RISK-002-001.
- **A-002-018** [assumido] [evidência: crença] Renovações concorrentes da mesma sessão
  legítima não são reuso: a rotação tolera uma janela de graça curta (ou resposta
  idempotente) para o token imediatamente anterior; a apresentação fora dessa janela
  segue revogando a família (FR-002-004 intacto). Mecanismo e valores são do PLAN.
- **A-002-019** [assumido] [evidência: crença] O conjunto público desta fatia é fechado:
  `health`, `health/db`, login e renovação; todo o resto — inclusive `/disciplines` —
  exige sessão válida. Deriva da anti-persona e do deny-by-default do BRIEF-002;
  `/disciplines` não tem consumidor renderizado hoje (`mnemonicos-frontend/src/store/api.ts`
  apenas define e exporta o hook), então protegê-la não regride tela alguma. O contrato
  definitivo de `/disciplines` é da fatia F2.
- **A-002-020** [assumido] [evidência: crença] O freio de login usa chave composta (conta
  tentada + origem) com limiares distintos: por conta estrito, por origem frouxo o
  bastante para uma equipe atrás de um IP de escritório; sem bloqueio duro de conta.
  Honra o A07 do risco da fatia sem criar negação de serviço interna. Consequência aceita:
  quem compartilha a origem do escritório tem mais tentativas antes do freio de origem —
  aceitável em ferramenta interna, com o freio por conta permanecendo estrito.

## 9. Riscos e questões abertas

- **RISK-002-001** — A regra "revisor jurídico ≠ autor" (A-002-016) é inexequível com uma
  operação de uma pessoa: como o papel ADMIN acumula produção-adjacente, revisão e
  aprovação, o mesmo indivíduo poderia produzir e aprovar. Consequência nomeada: se o
  piloto rodar com uma pessoa, "revisor ≠ autor" não se cumpre por controle de sistema em
  F1 nem em F9, e o gate de "Versão aprovada" de F9 fica apoiado só em disciplina
  operacional. *Mitigação*: dois ADMINs distintos no piloto (A-002-017); a fatia F9 decide
  se separa o papel de revisor jurídico do ADMIN e adiciona uma checagem de segregação de
  funções aplicada pelo sistema.
- **RISK-002-002** — O token de renovação persistido é uma superfície de dado sensível: o
  vazamento do repositório de tokens permitiria continuar sessões. *Mitigação*: guardar só
  o necessário para validar e revogar, manter os valores não reversíveis onde viável,
  revogar a família inteira em caso de reuso e manter a expiração absoluta curta (7 dias).
- **RISK-002-003** — Dependências novas de criptografia/sessão entram na árvore
  (derivação de senha, assinatura/geração de token, leitura de cookie) — superfície de
  cadeia de suprimento. *Mitigação*: gate de auditoria de dependências sobre o diff de F1
  (`/keelson:audit`); fixar versão e revisar.

Nenhuma questão aberta bloqueante — a última chamada do Diretor (2026-08-28) resolveu o
que era de produto. Os riscos ativos do slug (PIL-001, RDR-001, no INDEX) não incidem
sobre esta fatia.

## 10. Fora deste documento

Arquitetura, stack, modelagem de dados (repositório de sessão, campos novos na conta de
usuário), escolha de bibliotecas de derivação de senha / token / cookie, forma exata dos
endpoints e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`. A migração de
banco é ato do ciclo de implementação — arquivo versionado no diff da TASK —, não deste
documento (A-002-004).
