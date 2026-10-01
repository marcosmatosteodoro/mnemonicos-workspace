# SPEC-048: Gestão de usuários (ADMIN)

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.2
**Autor**: scribe (Claude) via /keelson:specify, a partir do BRIEF-048
**Data**: 2026-09-30
**Jira**: KAN-179
**Brief**: BRIEF-048

## 1. Contexto e objetivo

### 1.1 Problema
Hoje uma conta interna só nasce pelo seed ou por chamada manual à API. O backend de gestão de
contas existe e foi provado desde a SPEC-002 (FEAT-002-003: criar, listar, desativar,
redefinir senha), mas a própria SPEC-002 deixou a "UI completa de gestão de equipe no
frontend" fora do escopo (SPEC-002 §4.2). Resultado: quem administra o produto não consegue
dar ou tirar acesso à equipe sem acesso técnico à infraestrutura.

### 1.2 Outcome esperado
Um ADMIN abre a tela "Usuários" na área interna e, sozinho, vê as contas internas, busca por
nome ou e-mail, cria uma conta, desativa uma conta e redefine a senha de uma conta — sem seed,
sem chamada manual de API e sem que a senha digitada fique visível ou guardada em qualquer
lugar do navegador depois do envio. Quem não é ADMIN não vê o item de menu e, se abrir o
endereço, é recusado.

### 1.3 Métrica de sucesso
Nos 30 dias seguintes ao **deploy em produção** (não ao merge), 100% das contas internas novas
são provisionadas pela tela (zero por seed ou chamada manual de API). A métrica mede só
provisionamento de conta nova: tentativas de recontratação de e-mail que já tem conta
(FR-048-013) ficam fora da conta. Se nenhuma conta nova for criada no período, o veredito é
**"inconclusivo"**, nunca sucesso. O sistema não ganha instrumentação nova (o backend não
muda); o veredito sai de declaração do Diretor, conferida contra a lista de contas.

**Fonte de medição**: externa — declaração do Diretor (dono do número) de quantas contas
internas foram criadas dentro e fora da tela no período; o sistema não distingue o canal de
criação (sem instrumentação nesta SPEC).

## 2. Personas e jobs-to-be-done
- **ADMIN (Diretor/gestor da equipe)**: "quando alguém entra ou sai da equipe de produção,
  quero dar ou cortar o acesso e trocar uma senha comprometida na própria ferramenta, sem
  depender de quem tem acesso ao banco".
- **EDITOR**: persona de contraste — não gerencia contas; não vê o item de menu e, se chegar
  ao endereço, recebe a recusa.
- **Anti-persona**: estudante e visitante (cadastro público e contas de estudante estão
  fora); e o usuário que quer trocar a **própria** senha (fluxo de perfil, fora).

## 3. Glossário (Ubiquitous Language)
Termos herdados do glossário consolidado do INDEX (Papel, Conta desativada, Provisionamento
de conta, Sessão autenticada, Casca da área interna, Sidebar, Item de menu, Campo de senha
(componente), Toggle de visibilidade de senha, Deny-by-default) valem com a definição de lá.
Termos novos desta SPEC:

| Termo | Definição | Origem |
|-------|-----------|--------|
| Tela Usuários | Tela da área interna, exclusiva do ADMIN, que lista contas internas e permite criar, desativar e redefinir senha | SPEC-048 (card KAN-179: "Tela de gestão de usuários") |
| Conta interna | Conta que a tela lista e gerencia. A tela lista o que o servidor devolve, sem filtro de papel (users.service.ts:66-73); hoje só existem contas EDITOR e ADMIN porque nenhum caminho cria STUDENT (createUserSchema recusa; A-002-015). A coluna Papel mostra o papel como vem do servidor | SPEC-002 (FR-002-014) |
| Situação (da conta) | Estado exibido na lista: "Ativa" ou "Desativada" (FR-002-017: "ativa ou desativada") — o rótulo "Situação" vem do card KAN-179; "Ativa" é escolha de A-048-010 | SPEC-048 |
| Último ADMIN ativo | A única conta ADMIN ativa restante; o servidor recusa desativá-la (FR-002-019) | SPEC-002 |
| Busca de contas | Filtro por trecho do nome ou do e-mail aplicado à lista; o termo é aparado (trim) e vazio após o trim equivale a "sem busca" | SPEC-048 |
| Confirmação (de ação sobre conta) | Passo explícito, antes de desativar ou redefinir senha, que identifica a conta-alvo (nome e e-mail), diz a consequência (desconexão da pessoa ou encerramento das sessões da conta) e exige decisão de confirmar ou cancelar | SPEC-048 |
| Ação sobre a própria conta | Desativar a conta com que o ADMIN está logado, ou redefinir a própria senha pela tela; encerra a sessão dele | SPEC-048 |

## 4. Escopo

### 4.1 In-scope
- Item "Usuários" na navegação da área interna, exibido só ao ADMIN, e a tela correspondente
  com guarda de papel ADMIN (recusa a EDITOR, login para quem não tem sessão).
- Lista paginada das contas internas (nome, e-mail, papel, situação) com busca por nome ou
  e-mail e estados carregando, vazio, "nenhum resultado" e erro.
- Criar conta interna (nome, e-mail, papel com ajuda sobre o que o ADMIN concede, senha com
  mostrar/ocultar) com erros por campo.
- Desativar conta (com confirmação que identifica a conta), incluindo a recusa do último ADMIN ativo.
- Redefinir a senha de uma conta (com confirmação que identifica a conta).
- Tratamento das ações sobre a própria conta (aviso na confirmação e volta ao login) e da
  sessão encerrada durante uma ação de conta.
- Senha nunca reexibida, nunca guardada no navegador nem retida no estado do cliente após o envio.
- Emenda à SPEC-044 na navegação (seção "Emendas à SPEC-044", §8).
- Acessibilidade AA nos dois temas, teclado, foco visível, foco gerenciado nas confirmações;
  tabela com rolagem interna no celular.

### 4.2 Out-of-scope
- **Mudar o papel de uma conta existente** e **reativar conta desativada**: fora — o backend
  não tem as operações (SPEC-002 §4.2; MAP.md:475); viram outra história, com backend.
- **Cadastro público / auto-registro e contas de estudante**: fora (FR-002-016).
- **Qualquer mudança de backend, endpoint ou migração**: fora — as quatro operações já existem.
- **Alinhamento de header e footer da área interna**: fora (BRIEF-047, noutra sessão).
- **Troca da própria senha pelo fluxo de perfil**: fora (FR-002-024 já cobre o backend; ver
  RISK-048-012). Redefinir a própria senha **por esta tela** é tratado em FR-048-024 e não
  substitui aquele fluxo.
- **Exclusão definitiva de conta**: fora (SPEC-002 §4.2; a desativação é reversível só no backend).
- **Exportação da lista**, **ordenação e filtros por papel/situação**, **escolha do tamanho da
  página**: fora.
- **Editar nome ou e-mail de conta existente**: fora (o backend não tem a operação).
- **Gerar senha automática, enviar convite ou e-mail**: fora — o ADMIN digita a senha inicial.
- **Trilha de auditoria** (visível na tela ou não): fora (SPEC-002 §4.2 já exclui a UI de
  trilha); não existe registro das operações de conta; ver RISK-048-008 e A-048-008.
- **Filtrar por papel os demais itens da sidebar**: fora — o filtro vale só para "Usuários"
  (A-048-004).

## 5. Requisitos funcionais (EARS)

### FEAT-048-001: Acesso e lista de contas
> Do ponto de vista do QA: ADMIN vê o item de menu, abre a tela, vê a lista paginada, busca e
> percorre os estados; EDITOR não vê o item e é recusado no endereço e no servidor; sem sessão vai ao login.

**Verificação (gate 9)**: 2026-09-30 — pendente: consolidado na rodada final do gate 9 (Roteiro da TASK-049-006, passo 0 + passos da lista), por decisão do PO na Etapa 3.5; ainda não exercitado em tela.

- **FR-048-001** [MUST] Enquanto a sessão tem papel ADMIN, o sistema DEVE exibir o item "Usuários" na navegação da área interna; enquanto a sessão tem papel EDITOR, o sistema NÃO DEVE exibir esse item; o sistema NÃO DEVE alterar os demais itens da navegação.
- **FR-048-002** [MUST] Quando um ADMIN abre a tela Usuários, o sistema DEVE exibir a lista das contas internas.
- **FR-048-003** [MUST] Se um EDITOR abre o endereço da tela Usuários, então o sistema DEVE exibir "Você não tem permissão para ver esta página." e NÃO DEVE exibir nem solicitar dado de conta algum.
- **FR-048-004** [MUST] Se uma pessoa sem sessão válida abre o endereço da tela Usuários, então o sistema DEVE levá-la ao login (FR-002-013).
- **FR-048-005** [MUST] Se um solicitante sem papel ADMIN aciona qualquer operação de conta (listar, criar, desativar, redefinir senha) diretamente no servidor, então o servidor DEVE recusá-la sem listar nem alterar conta alguma; a recusa do servidor é a barreira real e a tela é só conveniência de navegação (FR-002-011, FR-002-012).
- **FR-048-006** [MUST] O sistema DEVE exibir cada conta da lista com nome, e-mail, papel (como vem do servidor) e situação ("Ativa" ou "Desativada"), 20 contas por página, da conta mais nova para a mais antiga (A-048-014), e DEVE permitir ir à página anterior e à seguinte; a linha da conta com que o ADMIN está logado DEVE levar a marca "(você)".
- **FR-048-007** [MUST] Quando o ADMIN informa um trecho na busca, o sistema DEVE aparar o termo (trim) e listar só as contas cujo nome ou e-mail o contém, voltando à primeira página, sem recarregar a página; termo vazio após o trim DEVE ser tratado como "sem busca" (lista completa, sem enviar o parâmetro de busca); o campo DEVE aceitar no máximo 120 caracteres.
- **FR-048-008** [MUST] O sistema DEVE refletir três estados observáveis da lista: *em andamento* — um indicador de carregamento no lugar das linhas; *sucesso* — as contas, ou, sem linhas, a mensagem "Nenhuma conta cadastrada." quando não há busca e a mensagem distinta "Nenhum resultado para a busca." quando há busca; *falha* — uma mensagem de erro em pt-BR com a ação "Tentar novamente", sem expor detalhe técnico. O ramo "Nenhuma conta cadastrada." é defensivo (a conta do próprio ADMIN sempre existe) e é provado por teste com resposta vazia simulada, não em tela.
- **FR-048-025** [MUST] Se uma ação de conta (criar, desativar, redefinir senha) falha porque a sessão foi encerrada e não pôde ser renovada, então o sistema DEVE seguir o caminho de sessão encerrada da casca até o login (FR-002-013, FR-044-023) e a senha digitada NÃO PODE ficar retida em lugar nenhum (NFR-048-001).

### FEAT-048-002: Criar conta
> Do ponto de vista do QA: o ADMIN preenche o formulário, vê erros por campo, envia, vê a conta na lista sem recarregar e confirma que a senha não ficou em lugar nenhum.

**Verificação (gate 9)**: 2026-10-01 — pendente: consolidado na rodada final do gate 9 (Roteiro da TASK-049-006), por decisão do PO na Etapa 3.5; ainda não exercitado em tela.

- **FR-048-009** [MUST] Quando o ADMIN abre o formulário de criação, o sistema DEVE oferecer os campos nome, e-mail, papel (EDITOR ou ADMIN, com EDITOR pré-selecionado) e senha, com a senha no campo de senha com mostrar/ocultar; enquanto o papel ADMIN está escolhido, o sistema DEVE exibir junto ao campo papel um texto de ajuda de uma frase dizendo o que o papel concede (gerir contas, fazer a revisão jurídica e aprovar versão), sem diálogo adicional de confirmação (A-048-015).
- **FR-048-010** [MUST] Se o nome está vazio, o e-mail é inválido ou a senha tem menos de 12 caracteres, então o sistema DEVE mostrar a mensagem em pt-BR junto ao campo correspondente, sem enviar; quando o servidor recusa um campo, o sistema DEVE mostrar a mensagem do servidor junto a esse campo.
- **FR-048-011** [MUST] Quando o ADMIN envia o formulário de criação, o sistema DEVE refletir três estados observáveis: *em andamento* — o botão de envio fica desabilitado, com indicador, e um segundo envio não dispara; *sucesso* — o formulário é fechado ou limpo e uma confirmação é exibida; *falha* — uma mensagem em pt-BR, com erros por campo quando o servidor os informa, e o formulário permanece para nova tentativa.
- **FR-048-012** [MUST] Quando a criação tem sucesso, o sistema DEVE limpar a busca e voltar à primeira página, onde a conta criada aparece como primeira linha, com nome, e-mail, papel e situação "Ativa", sem recarregar a página.
- **FR-048-013** [MUST] Se o e-mail informado já pertence a uma conta, então o sistema DEVE mostrar a mensagem do servidor ("Já existe uma conta com este e-mail.") junto ao campo e-mail, DEVE mostrar logo abaixo a orientação fixa em pt-BR "Se essa pessoa já teve uma conta desativada, a reativação ainda não está disponível por esta tela." (genérica: a tela não consulta se a conta existente está desativada) e NÃO DEVE alterar a conta existente (FR-002-015); ver Q-048-001.

### FEAT-048-003: Desativar conta
> Do ponto de vista do QA: o ADMIN escolhe uma conta ativa, confirma sabendo que a pessoa será desconectada, vê a situação mudar; as recusas do servidor aparecem sem quebrar a tela.

**Verificação (gate 9)**: 2026-10-01 — pendente: consolidado na rodada final do gate 9 (Roteiro da TASK-049-006), por decisão do PO na Etapa 3.5; ainda não exercitado em tela.

- **FR-048-014** [MUST] Enquanto uma conta está ativa, o sistema DEVE oferecer a ação "Desativar" nela; enquanto está desativada, o sistema NÃO DEVE oferecer essa ação.
- **FR-048-015** [MUST] Quando o ADMIN aciona "Desativar", o sistema DEVE abrir uma confirmação que mostra o nome e o e-mail da conta-alvo, diz que a pessoa será desconectada e que "a reativação não está disponível nesta tela", move o foco para dentro dela e devolve o foco ao acionador ao cancelar; cancelar NÃO DEVE alterar a conta.
- **FR-048-016** [MUST] Quando o ADMIN confirma a desativação, o sistema DEVE refletir três estados observáveis: *em andamento* — os botões da confirmação ficam desabilitados, com indicador, sem duplo envio; *sucesso* — a confirmação fecha e a linha passa a mostrar a situação "Desativada" em seguida, sem recarregar a página; *falha* — a mensagem em pt-BR fica visível na confirmação e a lista permanece como estava.
- **FR-048-017** [MUST] Se o servidor recusa a desativação, então o sistema DEVE mostrar a mensagem correspondente sem quebrar a tela e sem mudar a situação exibida: último ADMIN ativo ("Não é possível desativar o último ADMIN ativo."), corrida ("Não foi possível desativar a conta agora. Tente novamente.", permitindo tentar de novo) ou conta não encontrada ("Conta não encontrada.", atualizando a lista).
- **FR-048-018** [MUST] Quando o ADMIN desativa a própria conta, o sistema DEVE avisar na confirmação que ele mesmo será desconectado e, com sucesso, DEVE levá-lo ao login (havendo outro ADMIN ativo; sem outro, vale FR-048-017).

### FEAT-048-004: Redefinir senha
> Do ponto de vista do QA: o ADMIN define nova senha para uma conta ativa, confirmando que as sessões dela serão encerradas; o sucesso não exibe a senha.

- **FR-048-019** [MUST] Enquanto uma conta está ativa, o sistema DEVE oferecer a ação "Redefinir senha" nela; enquanto está desativada, o sistema NÃO DEVE oferecê-la (A-048-003).
- **FR-048-020** [MUST] Quando o ADMIN aciona "Redefinir senha", o sistema DEVE abrir uma confirmação que mostra o nome e o e-mail da conta-alvo, com o campo de senha com mostrar/ocultar, que diz que as sessões da conta serão encerradas, move o foco para dentro dela e o devolve ao acionador ao cancelar; cancelar NÃO DEVE alterar a conta.
- **FR-048-021** [MUST] Se a nova senha tem menos de 12 caracteres, então o sistema DEVE mostrar a mensagem em pt-BR junto ao campo, sem enviar; quando o servidor recusa a senha, o sistema DEVE mostrar a mensagem do servidor junto ao campo.
- **FR-048-022** [MUST] Quando o ADMIN confirma a redefinição, o sistema DEVE refletir três estados observáveis: *em andamento* — botões desabilitados, com indicador, sem duplo envio; *sucesso* — a confirmação fecha e uma mensagem de sucesso é exibida sem mostrar a senha; *falha* — uma mensagem em pt-BR fica visível na confirmação, que permanece aberta.
- **FR-048-023** [MUST] Se o servidor responde "Conta não encontrada." à redefinição, então o sistema DEVE mostrar a mensagem e atualizar a lista.
- **FR-048-024** [MUST] Quando o ADMIN redefine a própria senha, o sistema DEVE avisar na confirmação que ele mesmo será desconectado e, com sucesso, DEVE levá-lo ao login.

## 6. Requisitos não-funcionais
- **NFR-048-001** [MUST] A senha digitada (criação e redefinição) NÃO PODE ser reexibida depois do envio, NÃO PODE ser gravada em armazenamento do navegador (local, de sessão, cookie acessível a script, endereço), NÃO PODE permanecer no estado do cliente depois do envio (incluindo o cache de requisições) e NÃO PODE aparecer em log do cliente.
- **NFR-048-002** [MUST] A autorização das operações de conta DEVE ser decidida no servidor a cada requisição, deny-by-default; esconder o item de menu ou bloquear a tela não conta como controle (FR-002-012).
- **NFR-048-003** [MUST] A tela, a lista, os formulários e as confirmações DEVEM atender contraste AA nos temas claro e escuro, ser operáveis só por teclado, ter foco visível e, nas confirmações, foco gerenciado (entra ao abrir, fica contido, volta ao acionador ao fechar, Esc cancela).
- **NFR-048-004** [MUST] No celular a tabela DEVE rolar dentro do próprio contêiner, sem criar rolagem horizontal da página.
- **NFR-048-005** [MUST] Hoje criar, desativar e redefinir senha NÃO geram evento de auditoria; só a recusa por papel gera (`authz.denied`, authorize.ts:52; audit.ts:3-11), e esta SPEC não muda isso (sem backend). Da parte do cliente: nenhuma senha ou token PODE aparecer em mensagem exibida e nenhum log do cliente PODE conter dado sensível (ver RISK-048-008).

## 7. Critérios de aceitação (Given-When-Then)

### Acesso e lista de contas
- **AC-048-001** (cobre FR-048-001, FR-048-002)
  Dado um ADMIN com sessão ativa, quando ele abre a área interna, então a navegação mostra o item "Usuários" e, ao acioná-lo, a lista de contas é exibida; dado um EDITOR com sessão ativa, quando ele abre a área interna, então o item "Usuários" não aparece.
- **AC-048-002** (cobre FR-048-003)
  Dado um EDITOR com sessão ativa, quando ele abre o endereço da tela Usuários, então vê "Você não tem permissão para ver esta página." e nenhuma conta é exibida nem solicitada.
- **AC-048-003** (cobre FR-048-004)
  Dado uma pessoa sem sessão válida, quando ela abre o endereço da tela Usuários, então é levada ao login.
- **AC-048-004** (cobre FR-048-005, NFR-048-002)
  Dado um solicitante com papel EDITOR autenticado, quando ele aciona diretamente no servidor cada uma das quatro operações de conta, então o servidor recusa cada uma como proibido, nenhuma conta é listada, criada, desativada nem tem senha alterada, e a tela do ADMIN continua funcionando.
- **AC-048-005** (cobre FR-048-006)
  Dado mais de 20 contas internas, quando o ADMIN abre a tela, então vê 20 linhas com nome, e-mail, papel e situação, da conta mais nova para a mais antiga, e ao ir à página seguinte vê as contas seguintes e consegue voltar à anterior; dado o ADMIN logado, quando a lista mostra a conta dele, então a linha dessa conta leva a marca "(você)" e nenhuma outra linha a leva.
- **AC-048-006** (cobre FR-048-007)
  Dado contas com nomes e e-mails variados, quando o ADMIN digita um trecho na busca, então só aparecem contas cujo nome ou e-mail contém o trecho, a lista volta à primeira página e a página não recarrega; dado um termo só de espaços, quando aplicado, então a lista completa aparece sem mensagem de erro e sem o parâmetro de busca enviado; dado o campo de busca, quando se tenta digitar o 121º caractere, então ele não entra.
- **AC-048-007** (cobre FR-048-008)
  Dado a lista em carregamento, quando a resposta ainda não chegou, então um indicador aparece no lugar das linhas; dado nenhuma conta e nenhuma busca, quando a lista carrega, então aparece "Nenhuma conta cadastrada." (ramo defensivo, provado por teste com resposta vazia simulada, não em tela); dado uma busca sem correspondência, quando a lista carrega, então aparece "Nenhum resultado para a busca." (distinta da anterior); dado falha na consulta, quando a resposta falha, então aparece a mensagem de erro com "Tentar novamente", que ao ser acionada consulta de novo.
- **AC-048-008** (cobre NFR-048-003, NFR-048-004, FR-048-006)
  Dado a tela Usuários nos temas claro e escuro, quando se verifica o contraste dos textos, controles e foco, então todos atingem AA; dado uso só por teclado, quando se percorre a tela, então todo controle é alcançável, acionável e tem foco visível; dado viewport de celular, quando a tabela é mais larga que a tela, então rola dentro do próprio contêiner e a página não rola na horizontal.
- **AC-048-027** (cobre FR-048-001)
  Dado um EDITOR, quando a navegação é exibida, então a sidebar mostra exatamente 3 itens, Painel, Conteúdos e Biblioteca visual, nessa ordem e com os destinos de AC-044-001; dado um ADMIN, quando a navegação é exibida, então mostra os mesmos 3 itens e "Usuários" em 4º; em ambos os casos a resolução dos itens não faz nenhuma chamada nova ao backend.
- **AC-048-028** (cobre FR-048-025, NFR-048-001)
  Dado uma ação de conta (criar, desativar ou redefinir senha) enviada quando a sessão já foi encerrada e não pôde ser renovada, quando o servidor recusa por falta de sessão, então o sistema segue o caminho de sessão encerrada da casca até o login e, após o redirecionamento, a senha digitada não está no estado do cliente (incluindo o cache de requisições), no armazenamento do navegador, no endereço nem em log, e o campo de senha está vazio.

### Criar conta
- **AC-048-009** (cobre FR-048-009, FR-048-010)
  Dado o formulário de criação aberto, quando o ADMIN vê os campos, então encontra nome, e-mail, papel (EDITOR ou ADMIN, com EDITOR pré-selecionado) e senha com mostrar/ocultar; dado o papel ADMIN escolhido, quando o campo muda, então um texto de ajuda de uma frase aparece junto ao campo dizendo que o papel concede gerir contas, fazer a revisão jurídica e aprovar versão, sem diálogo adicional, e com EDITOR escolhido o texto não aparece; dado nome vazio, e-mail inválido ou senha de 11 caracteres, quando ele tenta enviar, então cada campo mostra sua mensagem em pt-BR e nada é enviado.
- **AC-048-010** (cobre FR-048-011)
  Dado um formulário válido, quando o ADMIN envia, então enquanto a resposta não chega o botão fica desabilitado com indicador e um segundo clique não dispara novo envio; com sucesso, uma confirmação aparece; com falha do servidor, uma mensagem em pt-BR aparece e o formulário permanece.
- **AC-048-011** (cobre FR-048-012)
  Dado uma busca aplicada e o ADMIN em página posterior à primeira, quando a criação tem sucesso, então a busca é limpa, a lista volta à primeira página e a conta criada aparece como primeira linha, com situação "Ativa", sem recarregar a página, e o formulário está vazio ao reabri-lo.
- **AC-048-012** (cobre FR-048-013)
  Dado uma conta existente com o e-mail X, quando o ADMIN tenta criar outra conta com o e-mail X, então "Já existe uma conta com este e-mail." aparece junto ao campo e-mail, logo abaixo aparece "Se essa pessoa já teve uma conta desativada, a reativação ainda não está disponível por esta tela." e a conta existente permanece inalterada.
- **AC-048-013** (cobre NFR-048-001, FR-048-011)
  Dado uma criação enviada com sucesso ou recusada pelo servidor, quando ela termina, então a senha digitada não aparece na tela, nem no armazenamento do navegador, nem no endereço, nem no estado do cliente (incluindo o cache de requisições), nem em log; e o campo de senha do formulário está vazio.

### Desativar conta
- **AC-048-014** (cobre FR-048-014)
  Dado uma conta ativa e uma desativada na lista, quando o ADMIN olha as ações, então a conta ativa oferece "Desativar" e a desativada não.
- **AC-048-015** (cobre FR-048-015, NFR-048-003)
  Dado o ADMIN em uma conta ativa, quando aciona "Desativar", então abre uma confirmação que mostra o nome e o e-mail da conta-alvo, diz que a pessoa será desconectada e que "a reativação não está disponível nesta tela", com o foco dentro dela; quando cancela ou aperta Esc, então a confirmação fecha, o foco volta ao acionador e a conta não muda.
- **AC-048-016** (cobre FR-048-016)
  Dado a confirmação aberta, quando o ADMIN confirma, então enquanto a resposta não chega os botões ficam desabilitados com indicador e não há duplo envio; com sucesso, a confirmação fecha e a linha mostra "Desativada" em seguida, sem recarregar; com falha, a mensagem fica na confirmação e a lista permanece como estava.
- **AC-048-017** (cobre FR-048-017)
  Dado o servidor recusando por último ADMIN ativo, por corrida ou por conta não encontrada, quando o ADMIN confirma a desativação, então a mensagem correspondente aparece ("Não é possível desativar o último ADMIN ativo.", "Não foi possível desativar a conta agora. Tente novamente." com nova tentativa possível, "Conta não encontrada." com lista atualizada), a tela continua funcionando e a situação exibida não muda.
- **AC-048-018** (cobre FR-048-018)
  Dado um ADMIN com outro ADMIN ativo existente, quando ele desativa a própria conta, então a confirmação avisa que ele mesmo será desconectado e, com sucesso, ele é levado ao login; dado ele ser o único ADMIN ativo, quando confirma, então aparece "Não é possível desativar o último ADMIN ativo." e ele permanece logado na tela.

### Redefinir senha
- **AC-048-019** (cobre FR-048-019)
  Dado uma conta ativa e uma desativada, quando o ADMIN olha as ações, então a conta ativa oferece "Redefinir senha" e a desativada não.
- **AC-048-020** (cobre FR-048-020, NFR-048-003)
  Dado o ADMIN em uma conta ativa, quando aciona "Redefinir senha", então abre uma confirmação que mostra o nome e o e-mail da conta-alvo, com o campo de senha com mostrar/ocultar e o aviso de que as sessões da conta serão encerradas, com o foco dentro dela; quando cancela ou aperta Esc, então fecha, o foco volta ao acionador e a senha da conta não muda.
- **AC-048-021** (cobre FR-048-021)
  Dado a confirmação aberta, quando o ADMIN envia uma senha de 11 caracteres, então a mensagem em pt-BR aparece junto ao campo e nada é enviado; dado o servidor recusando a senha, quando ele envia, então a mensagem do servidor aparece junto ao campo.
- **AC-048-022** (cobre FR-048-022)
  Dado uma senha válida, quando o ADMIN confirma, então enquanto a resposta não chega os botões ficam desabilitados com indicador e não há duplo envio; com sucesso, a confirmação fecha e aparece uma mensagem de sucesso sem a senha; com falha, a mensagem fica na confirmação, que permanece aberta.
- **AC-048-023** (cobre FR-048-023)
  Dado a conta removida ou inexistente no servidor, quando o ADMIN confirma a redefinição, então "Conta não encontrada." aparece e a lista é atualizada.
- **AC-048-024** (cobre FR-048-024)
  Dado um ADMIN redefinindo a própria senha, quando a confirmação abre, então avisa que ele mesmo será desconectado e, com sucesso, ele é levado ao login e a nova senha entra.
- **AC-048-025** (cobre NFR-048-001, FR-048-022)
  Dado uma redefinição enviada com sucesso ou recusada, quando ela termina, então a senha digitada não aparece na tela, nem no armazenamento do navegador, nem no endereço, nem no estado do cliente (incluindo o cache de requisições), nem em log; e o campo de senha está vazio.
- **AC-048-026** (cobre NFR-048-005, FR-048-021)
  Dado uma falha de criação ou redefinição, quando a mensagem de erro é exibida, então ela não contém a senha nem token, e o cliente não grava nem registra por conta própria nenhum dado sensível da operação.

## 8. Premissas e decisões prévias
- **A-048-001** [assumido] [evidência: crença] O ADMIN pode desativar a **própria** conta (havendo outro ADMIN ativo), com aviso explícito na confirmação e volta ao login depois. Razoável porque o servidor permite (users.service.ts:151/156) e proibir na tela esconderia uma ação legítima (passar o cargo); o servidor continua recusando o último ADMIN ativo.
- **A-048-002** [assumido] [evidência: crença] O ADMIN pode redefinir a **própria** senha por esta tela, com aviso e volta ao login (o servidor revoga a sessão dele). Razoável por simetria com A-048-001; não substitui o fluxo de perfil (fora).
- **A-048-003** [assumido] [evidência: crença] "Redefinir senha" não é oferecida a conta desativada: ela não autentica (FR-002-018) e reativar está fora. Se o Diretor quiser preparar a senha antes de uma reativação futura, vira nova história.
- **A-048-004** [assumido] [evidência: medido] O item "Usuários" é o primeiro filtrado por papel na navegação (revê, só para ele, a premissa "nenhum item filtrado por papel" da SPEC-044; é o gatilho de reabertura previsto em RISK-044-005). A guarda ADMIN vale só para a rota de usuários; o resto da área interna continua EDITOR. O efeito na SPEC-044 está na subseção "Emendas à SPEC-044" abaixo. Âncoras: internal-nav.ts, internal-routes.ts (memo de exploração).
- **A-048-005** [assumido] [evidência: crença] A navegação entre páginas é "anterior/seguinte" e não depende de total de contas nem de número de páginas, pois a SPEC não afirma que a resposta traz total; o PLAN confere o payload (amostra capturada) e pode enriquecer.
- **A-048-006** [assumido] [evidência: crença] Depois de **falha** no envio de senha, o campo de senha é limpo e a pessoa redigita; os demais campos permanecem. Default conservador de NFR-048-001; falha de validação local (sem envio) mantém o que foi digitado.
- **A-048-007** [assumido] [evidência: crença] No formulário de criação, o papel vem pré-selecionado em EDITOR (menor privilégio) e STUDENT não é oferecido (FR-002-014: só EDITOR ou ADMIN).
- **A-048-008** [assumido] [evidência: medido] Criar, desativar e redefinir senha não geram evento de auditoria hoje: só a recusa por papel gera (`authz.denied`, authorize.ts:52; audit.ts:3-11) e o módulo users não audita. A SPEC-002 promete auditoria de autenticação e **autorização** (FR-002-011, NFR-002-005) e exclui a UI de trilha (§4.2); não promete evento de provisionamento. Esta SPEC não muda o backend (brief) e não inventa promessa nova: NFR-048-005 registra o fato e RISK-048-008 carrega a lacuna.
- **A-048-009** [assumido] [evidência: crença] Mudar o termo da busca volta à primeira página; a busca se aplica sem recarregar a página (o momento exato — ao digitar com pausa ou ao confirmar — é do PLAN).
- **A-048-010** [assumido] [evidência: crença] Rótulos de situação: "Ativa" e "Desativada" ("Desativada" vem do BRIEF-048; "Ativa" é o par natural).
- **A-048-011** [assumido] [evidência: medido] As mensagens de recusa do servidor (e-mail duplicado, último ADMIN, corrida, conta não encontrada, senha curta/longa) já estão em pt-BR e são exibidas como vêm (users.service.ts:50/141/151/165; users.schema.ts:25/31-32); erro sem mensagem utilizável cai em mensagem genérica em pt-BR.
- **A-048-012** [assumido] [evidência: crença] A tela vive no endereço `/users` sob a área interna, registrado na fonte única de rotas internas (BRIEF-048); a criação pode ser painel ou diálogo — o PLAN decide, mantendo FR-048-009 a 013.
- **A-048-013** [assumido] [evidência: crença] Após desativar ou redefinir a própria conta, "levado ao login" usa o mesmo caminho de sessão encerrada da SPEC-002 (FR-002-013); o texto exato da tela de login não muda.
- **A-048-014** [assumido] [evidência: medido] A lista vem ordenada da conta mais nova para a mais antiga (createdAt desc, users.service.ts:78) e sem filtro de papel (users.service.ts:66-73); a busca do servidor aceita termo de 1 a 120 caracteres após trim (disciplines.schema.ts:6, herdado em users.schema.ts:65). FR-048-006, FR-048-007 e FR-048-012 se apoiam nisso.
- **A-048-015** [assumido] [evidência: crença] O texto de ajuda do papel ADMIN (FR-048-009) reproduz só o que o glossário "Papel" do INDEX atribui ao ADMIN (gestão de contas + revisão jurídica + aprovação de versão), sem inventar poder; o redator final do rótulo é do PLAN/product-designer, mantendo uma frase. Decisão do PO em nome do Diretor; sem diálogo próprio de confirmação (RISK-048-009).

### Emendas à SPEC-044
Esta SPEC emenda a navegação da SPEC-044 só no que segue; tudo o mais da SPEC-044 permanece (A-048-004, RISK-048-005).
- (a) [assumido] [evidência: crença] AC-044-001 passa a valer para EDITOR com exatamente Painel, Conteúdos e Biblioteca visual, nessa ordem; para ADMIN, os mesmos 3 itens mais "Usuários" (/users) em 4º e último.
- (b) [assumido] [evidência: crença] Em /users, o item "Usuários" fica destacado como seção atual (FR-044-003).
- (c) [assumido] [evidência: crença] FR-044-005 fica inalterado: EDITOR em /users vê o estado "sem permissão" da casca, sem sidebar, como em qualquer rota sem permissão.
- (d) [assumido] [evidência: crença] NFR-044-002 continua: o filtro do item usa o papel da sessão já obtida pela casca, com 0 chamadas novas ao backend.
- (e) [assumido] [evidência: crença] NFR-044-004: as suítes de navegação e de rotas internas passam com a emenda aplicada.

## 9. Riscos e questões abertas
- **RISK-048-001** Senha ficar retida no estado do cliente (o cache de requisições guarda os argumentos da mutação) ou em log. *Mitigação*: NFR-048-001, AC-048-013, AC-048-025 e AC-048-028 provados por teste que lê o estado; o PLAN decide o mecanismo; gate 8 provável.
- **RISK-048-002** Confiar na tela como controle de acesso. *Mitigação*: FR-048-005/NFR-048-002 e AC-048-004 provam a recusa no servidor.
- **RISK-048-003** Ação destrutiva sobre a própria conta (autodesativação, autoredefinição) deixar o ADMIN preso ou sem ADMIN ativo. *Mitigação*: servidor recusa o último ADMIN (FR-002-019); AC-048-018 e AC-048-024.
- **RISK-048-004** Regressão de acessibilidade (tabela e confirmações nos dois temas, foco) — histórico de re-gate de AA no slug. *Mitigação*: AC-048-008/015/020; gate 11.
- **RISK-048-005** O filtro por papel só do item "Usuários" reabre a premissa da SPEC-044 (RISK-044-005) e toca superfície provada. *Mitigação*: A-048-004 e a subseção "Emendas à SPEC-044" (§8); AC-048-027; testes de navegação e de rotas internas atualizados no PLAN.
- **RISK-048-006** Gate 9 depende de contas reais (ADMIN, EDITOR, conta descartável) e de ação destrutiva; sem elas fica em handoff declarado.
- **RISK-048-007** A métrica de sucesso não tem instrumentação (o sistema não distingue o canal de criação); o veredito depende de declaração do Diretor, selo crença.
- **RISK-048-008** OWASP A09 — operações de conta não deixam trilha de autor; a lacuna já existia na API, a tela reduz o atrito de usá-la. *Mitigação*: história de backend de auditoria (escalação ao Diretor na Entrega).
- **RISK-048-009** A tela torna trivial criar uma 2ª conta ADMIN; isso destrava a aprovação (RISK-032-001) mas expõe RISK-032-005 (conta-fantoche para autoaprovação, sem controle técnico) e RISK-032-006 (saveRuleBreakdown não registra quem salva a Quebra da regra; INDEX: conserto "obrigatório antes de um 2º ADMIN real operar"). *Mitigação*: texto de ajuda no papel ADMIN (FR-048-009) + escalação ao Diretor na Entrega.
- **RISK-048-010** Um termo de busca com `%` ou `_` pode trazer mais contas do que as que contêm o texto literal (nunca menos, nem dado que o ADMIN já não veja) — limitação conhecida do backend (INDEX 1532-1538). O PLAN mede o comportamento real; o QA não usa esses caracteres na massa do AC-048-006; o cliente não escapa curingas; a correção real vai para a história de backend. Não vira requisito.
- **RISK-048-011** Se surgirem contas STUDENT (cadastro público, fora desta SPEC), elas aparecerão na lista, pois a tela não filtra papel (A-048-014). *Mitigação*: filtro vira história de backend.
- **RISK-048-012** OWASP A07 — a senha inicial/redefinida é escolhida pelo ADMIN e repassada por fora do sistema, e a pessoa não tem tela para trocá-la (o backend tem POST /auth/change-password, FR-002-024; a UI está fora pelo brief). *Mitigação*: história de UI de troca da própria senha, proposta na Entrega. Não vira requisito.
- **Q-048-001** Existe necessidade de reativar conta ou mudar papel logo depois? Se sim, é história com backend (fora desta SPEC). Ligada ao caso de e-mail já existente de conta desativada (FR-048-013): hoje a tela só orienta que a reativação não está disponível.

## 10. Fora deste documento
Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
