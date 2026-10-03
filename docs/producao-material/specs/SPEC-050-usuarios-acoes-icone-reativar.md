# SPEC-050: Usuários — ações em ícone e reativação de conta

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.2
**Autor**: scribe (Claude) via /keelson:specify, a partir do BRIEF-050
**Data**: 2026-10-01
**Brief**: BRIEF-050
**Jira Story**: KAN-219

## 1. Contexto e objetivo

### 1.1 Problema
A tela de Usuários (SPEC-048) já lista, cria, desativa e redefine senha de contas internas, mas a coluna "Ações" só tem dois botões de texto ("Desativar" e "Redefinir senha") e não existe caminho nenhum — nem rota de backend, nem tela — para reativar uma conta desativada; hoje a própria tela avisa que "a reativação não está disponível nesta tela". Além disso, o épico de gestão de usuários v2 (KAN-218) vai adicionar "Editar" e "Excluir permanentemente" na mesma linha, e a coluna atual, com botões de texto, não tem espaço para crescer.

### 1.2 Outcome esperado
Um ADMIN consegue reativar uma conta desativada direto na tela de Usuários — a Situação volta a "Ativa" e a pessoa volta a conseguir entrar — e a coluna "Ações" passa a apresentar cada ação como um controle compacto, sem rótulo de texto permanente na linha, que fica disponível ou indisponível conforme a Situação da conta e tem nome acessível identificando a pessoa e a ação. Um EDITOR que tentar reativar diretamente no servidor é recusado, e a reativação deixa rastro de quem a fez e em qual conta.

### 1.3 Métrica de sucesso
Nos 30 dias seguintes ao **deploy em produção** (não ao merge), toda reativação de conta passa a acontecer pela tela — medida pela contagem de eventos no log da ação de reativar (NFR-050-001): cada reativação pela tela gera exatamente um evento de log; reativação por acesso direto ao banco, se ainda ocorrer, não gera esse evento e fica visível como divergência. Se nenhuma reativação ocorrer no período, o veredito é **"inconclusivo"**, nunca sucesso.

**Fonte de medição**: instrumentação — o log da ação de reativar (NFR-050-001) é o evento que o sistema emite; a contagem no período sai desse log.

## 2. Personas e jobs-to-be-done
- **ADMIN (Diretor/gestor da equipe)**: "quando uma conta foi desativada por engano, ou a pessoa volta para a equipe, quero reativá-la pela própria tela, sem precisar de acesso técnico ao banco."
- **EDITOR**: persona de contraste — não gerencia contas; se tentar reativar diretamente no servidor, é recusado (herdado de SPEC-048).
- **Anti-persona**: quem precisa editar dados da conta ou excluí-la permanentemente — fora desta SPEC, cards próprios do épico KAN-218; e as personas já fora da SPEC-048 (estudante, visitante, cadastro público).

## 3. Glossário (Ubiquitous Language)
Termos herdados do glossário consolidado do INDEX e da SPEC-048 (Tela Usuários, Conta interna, Situação (da conta), Último ADMIN ativo, Busca de contas, Confirmação (de ação sobre conta), Ação sobre a própria conta) valem com a definição de lá; o fluxo de reativar **herda** o termo "Confirmação (de ação sobre conta)" existente, não cria um novo. Termos novos desta SPEC:

| Termo | Definição | Origem |
|-------|-----------|--------|
| Ativar | Ação oposta de "Desativar": move a Situação da conta de "Desativada" para "Ativa", liberando a pessoa para autenticar de novo. Mesmo par de estado de "Situação (da conta)" (INDEX/SPEC-048) | BRIEF-050 (card KAN-219) |
| Controle de ação (coluna Ações) | O elemento interativo da coluna "Ações" na linha de uma conta: visualmente compacto, sem rótulo de texto permanente ao lado, que fica disponível ou indisponível conforme a Situação da conta e tem nome acessível identificando a pessoa-alvo e a ação (ex.: "Desativar Evelin Ferreira", "Ativar Evelin Ferreira") | BRIEF-050 (card KAN-219: "botões de ícone") |

## 4. Escopo

### 4.1 In-scope
- Reativar conta desativada: rota nova no servidor (ADMIN, mesma guarda de origem das demais mutações de conta), idempotente (reativar conta já ativa não é erro), sem migração de schema.
- Confirmação curta antes de reativar, identificando a conta-alvo, com os três estados observáveis da ação (em andamento, sucesso, falha).
- Log da reativação: quem (ator) reativou qual conta (alvo), consultável depois do fato.
- Atualização dos dois textos que hoje afirmam que a reativação não está disponível nesta tela (diálogo de "Desativar" e orientação de e-mail duplicado ao criar conta), para não contradizerem a capacidade nova.
- Coluna "Ações" passa a controles compactos: "Desativar"/"Ativar" alternando conforme a Situação, nunca os dois ao mesmo tempo na mesma linha, cada um com nome acessível e tooltip que identificam a pessoa e a ação, operável por teclado com foco visível.
- Remoção do botão de texto "Redefinir senha" da linha, sem realocação nesta entrega (ver RISK-050-001).
- Ausência, nesta entrega, de qualquer controle de "Editar" ou "Excluir" na linha.

### 4.2 Out-of-scope
- **Editar conta** (ação e página de edição): fora — card próprio do épico KAN-218; o controle de Editar pode nem aparecer na linha nesta entrega (o card autoriza).
- **Excluir permanentemente**: fora — card próprio do épico KAN-218; nem o esqueleto do controle entra nesta entrega.
- **Realocar "Redefinir senha" para a futura página de edição**: fora — ela só sai da linha nesta entrega; a realocação é outro card, quando a página de edição existir. Tratado como risco aceito (RISK-050-001), não como lacuna desta entrega.
- **Mudar o papel de uma conta**: fora (herdado de SPEC-002 §4.2 / SPEC-048 §4.2).
- **Origem técnica do controle visual** (SVG próprio ou biblioteca de ícones): decisão técnica reversível, fora desta SPEC — resolvida no `/keelson:plan` a partir da exploração técnica real do projeto.
- **Trilha de auditoria completa / tabela de auditoria nova**: fora — o log desta SPEC (NFR-050-001) é mitigação pontual só para a ação de reativar; RISK-048-008 continua aberto para criar, desativar e redefinir senha (ver RISK-050-002).
- **Cadastro público, auto-registro e contas de estudante**: fora (herdado de SPEC-002 §4.2 / SPEC-048 §4.2).

## 5. Requisitos funcionais (EARS)

### FEAT-050-001: Reativar conta desativada
> Do ponto de vista do QA: a partir de uma conta desativada, o ADMIN aciona "Ativar", confirma, a Situação muda para "Ativa" e a pessoa volta a autenticar; um EDITOR acionando a mesma rota diretamente no servidor é recusado; o log registra quem reativou e qual conta; os dois textos que diziam que reativar não existe foram atualizados.

**Verificação (gate 9)**: 2026-10-03 — ambiente local (backend 3333 + frontend 3000, Postgres
em container), sessões ADMIN/EDITOR reais via Playwright + curl direto no backend; roteiro
completo da TASK-051-002 executado (contraste AA claro/escuro, tooltip hover/focus, nó DOM e
foco estáveis nas 2 direções de transição Ativar↔Desativar, EDITOR recusado 403 no proxy e no
backend direto). VERIFICADO.

- **FR-050-001** [MUST] Quando o ADMIN aciona "Ativar" numa conta desativada, o sistema DEVE abrir uma confirmação curta que mostra o nome e o e-mail da conta-alvo e diz que a conta volta a autenticar, move o foco para dentro dela e devolve o foco ao acionador ao cancelar; cancelar NÃO DEVE alterar a conta.
- **FR-050-002** [MUST] Quando o ADMIN confirma a reativação, o sistema DEVE refletir três estados observáveis: *em andamento* — os botões da confirmação ficam desabilitados, com indicador, sem duplo envio; *sucesso* — a confirmação fecha e a linha passa a mostrar a Situação "Ativa" em seguida, sem recarregar a página; *falha* — a mensagem em pt-BR fica visível na confirmação e a Situação exibida não muda.
- **FR-050-003** [MUST] O sistema DEVE permitir reativar uma conta que já está ativa sem produzir erro (idempotência): a Situação permanece "Ativa" e nenhuma mensagem de falha aparece.
- **FR-050-004** [MUST] Quando a conta é reativada com sucesso, o sistema DEVE permitir que a pessoa volte a autenticar com as credenciais existentes.
- **FR-050-005** [MUST] Se um solicitante sem papel ADMIN aciona a reativação diretamente no servidor, então o servidor DEVE recusá-la sem alterar a conta.
- **FR-050-006** [MUST] Quando a conta passa de "Desativada" para "Ativa" por uma reativação concluída com sucesso, o sistema DEVE registrar quem (conta autora) reativou, qual conta (alvo) foi reativada e o horário da ação; reativar uma conta já ativa (idempotência, FR-050-003) NÃO DEVE registrar evento novo.
- **FR-050-007** [MUST] O sistema DEVE substituir o texto da confirmação de "Desativar" que hoje afirma que a reativação não está disponível nesta tela por um texto que não contradiga a capacidade de reativar.
- **FR-050-008** [MUST] O sistema DEVE substituir a orientação exibida quando o e-mail informado já pertence a uma conta (hoje: "a reativação ainda não está disponível por esta tela") por um texto que não contradiga a capacidade de reativar.
- **FR-050-014** [MUST] Se o servidor responde "Conta não encontrada." à reativação, então o sistema DEVE mostrar a mensagem na confirmação, a Situação exibida NÃO DEVE mudar e o sistema DEVE atualizar a lista.

### FEAT-050-002: Coluna de Ações em controles compactos
A coluna muda para controles compactos agora para abrir espaço visual aos controles futuros de Editar e Excluir (KAN-218) sem reescrever a coluna outra vez.

> Do ponto de vista do QA: a coluna "Ações" mostra controles compactos que alternam conforme a Situação da conta, cada um com nome acessível e tooltip que identificam a pessoa e a ação; nenhum botão de texto "Redefinir senha" aparece na linha; nenhum controle de "Editar" ou "Excluir" aparece nesta entrega.

**Verificação (gate 9)**: 2026-10-03 — mesmo exercício acima; AC-050-008/009 (1 controle por
linha, tooltip ≡ aria-label) e AC-050-010 (contraste AA claro/escuro medido: ícone/foco/tooltip
todos ≥5:1, acima do piso) confirmados em tela real. VERIFICADO.

- **FR-050-009** [MUST] Enquanto uma conta está ativa, o sistema DEVE oferecer na linha um controle compacto de "Desativar"; enquanto está desativada, o sistema DEVE oferecer, no mesmo lugar, um controle compacto de "Ativar"; o sistema NÃO DEVE oferecer os dois controles ao mesmo tempo na mesma linha.
- **FR-050-010** [MUST] Cada controle de ação da linha DEVE ter nome acessível que identifica a pessoa-alvo e a ação (ex.: "Desativar Evelin Ferreira", "Ativar Evelin Ferreira") e DEVE exibir uma dica (tooltip) com o mesmo texto ao focar ou passar o ponteiro sobre ele.
- **FR-050-011** [MUST] Cada controle de ação da linha DEVE ser operável só por teclado (alcançável por Tab, acionável por Enter ou Espaço) e DEVE exibir foco visível.
- **FR-050-012** [MUST] O sistema NÃO DEVE exibir na linha nenhum botão de texto "Redefinir senha"; a ação de redefinir senha NÃO DEVE ter controle equivalente na linha nesta entrega.
- **FR-050-013** [MUST] O sistema NÃO DEVE exibir na linha nenhum controle de "Editar" nem de "Excluir" nesta entrega.

## 6. Requisitos não-funcionais
- **NFR-050-001** [MUST] O log da reativação DEVE identificar a conta autora da ação, a conta reativada e o horário da ação, e DEVE ser consultável depois do fato (auditoria verificável), sem exigir tabela de auditoria nova além do que o PLAN decidir como mecanismo de registro.
- **NFR-050-002** [MUST] A autorização da reativação DEVE ser decidida no servidor a cada requisição, deny-by-default; esconder ou desabilitar o controle na tela não conta como controle de acesso (herdado de NFR-048-002).
- **NFR-050-003** [MUST] Os controles compactos da coluna "Ações" DEVEM atender contraste AA nos temas claro e escuro, ser operáveis só por teclado e ter foco visível (estende NFR-048-003 aos novos controles).

## 7. Critérios de aceitação (Given-When-Then)

### Reativar conta desativada
- **AC-050-001** (cobre FR-050-001, FR-050-002)
  Dado uma conta desativada, quando o ADMIN aciona "Ativar", então abre uma confirmação que mostra o nome e o e-mail da conta-alvo e diz que a conta volta a autenticar, com o foco dentro dela; quando ele confirma, então enquanto a resposta não chega os botões ficam desabilitados com indicador e não há duplo envio, com sucesso a confirmação fecha e a linha passa a mostrar a Situação "Ativa" em seguida sem recarregar a página, e com falha a mensagem em pt-BR fica visível na confirmação e a Situação exibida não muda; quando ele cancela ou aperta Esc, então a confirmação fecha, o foco volta ao acionador e a conta não muda. Com sucesso, tanto para "Ativar" quanto para "Desativar" sob o controle compacto (FR-050-009), o foco volta para o controle de ação da mesma linha — que agora mostra o nome acessível da ação inversa ("Ativar X" depois de desativar, "Desativar X" depois de reativar) — e a mudança de Situação é anunciada (mecanismo de anúncio decidido no PLAN/product-designer, gate 11); exceção: a autodesativação da própria conta continua levando ao login (FR-048-018, não muda).
- **AC-050-002** (cobre FR-050-003)
  Dado uma conta já ativa, quando a reativação é acionada para ela mesmo assim (ex.: reenvio, corrida de dois cliques), então o sistema não produz erro, a Situação permanece "Ativa", nenhuma mensagem de falha aparece e nenhum evento novo de reativação é registrado.
- **AC-050-003** (cobre FR-050-004)
  Dado uma conta desativada reativada com sucesso, quando a pessoa tenta entrar com as credenciais existentes, então ela consegue autenticar, e a linha dessa conta na tela Usuários mostra a Situação "Ativa" na próxima vez que a lista é carregada.
- **AC-050-004** (cobre FR-050-005, NFR-050-002)
  Dado um solicitante com papel EDITOR autenticado, quando ele aciona diretamente no servidor a reativação, então o servidor recusa como proibido, nenhuma conta é alterada e a tela do ADMIN continua funcionando.
- **AC-050-005** (cobre FR-050-006, NFR-050-001)
  Dado uma conta desativada reativada com sucesso (passando de "Desativada" para "Ativa"), quando o log da ação é consultado, então ele identifica a conta que reativou, a conta reativada e o horário da ação; dado uma conta já ativa reativada de novo (idempotência, FR-050-003), quando o log é consultado, então nenhum evento novo de reativação aparece.
- **AC-050-006** (cobre FR-050-007)
  Dado a confirmação de "Desativar" aberta, quando o ADMIN lê a consequência exibida, então o texto não afirma que a reativação não está disponível nesta tela.
- **AC-050-007** (cobre FR-050-008)
  Dado uma tentativa de criar conta com e-mail já pertencente a outra conta, quando o sistema mostra a orientação junto ao campo e-mail, então o texto não afirma que a reativação ainda não está disponível por esta tela.
- **AC-050-013** (cobre FR-050-014)
  Dado o servidor respondendo "Conta não encontrada." à reativação, quando o ADMIN confirma, então a confirmação mostra essa mensagem, a Situação exibida não muda e a lista é atualizada.

### Coluna de Ações em controles compactos
- **AC-050-008** (cobre FR-050-009)
  Dado uma conta ativa e uma desativada na lista, quando o ADMIN olha a coluna "Ações", então a conta ativa mostra o controle "Desativar" e a desativada mostra o controle "Ativar", nunca os dois ao mesmo tempo na mesma linha.
- **AC-050-009** (cobre FR-050-010)
  Dado a linha da conta de uma pessoa (ex.: Evelin Ferreira), quando o ADMIN foca ou passa o ponteiro sobre o controle de ação dessa linha, então o nome acessível e a dica (tooltip) identificam a pessoa e a ação (ex.: "Desativar Evelin Ferreira" ou "Ativar Evelin Ferreira"), com o mesmo texto nos dois.
- **AC-050-010** (cobre FR-050-011, NFR-050-003)
  Dado a coluna "Ações" nos temas claro e escuro, quando se verifica o contraste dos controles e do foco, então atingem AA; dado uso só por teclado, quando se percorre a linha, então cada controle é alcançável por Tab, acionável por Enter ou Espaço e tem foco visível.
- **AC-050-011** (cobre FR-050-012)
  Dado qualquer linha da tabela, seja a conta ativa ou desativada, quando o ADMIN olha a coluna "Ações", então nenhum botão de texto "Redefinir senha" aparece.
- **AC-050-012** (cobre FR-050-013)
  Dado qualquer linha da tabela, quando o ADMIN olha a coluna "Ações", então nenhum controle de "Editar" nem de "Excluir" aparece.
- **AC-050-014** (cobre FR-050-009)
  Dado "Desativar" acionado pelo novo controle compacto, quando se confere o comportamento herdado de SPEC-048, então continua cumprindo AC-048-014 (recusa de último ADMIN ativo), AC-048-016 (corrida/409), AC-048-017 (404) e AC-048-018 (autodesativação leva ao login), agora sob o controle compacto em vez do botão de texto; AC-048-015 vale com a emenda de texto da subseção "Emendas à SPEC-048" (§8).

## 8. Premissas e decisões prévias
- **A-050-001** [assumido] [evidência: medido] A rota de reativar espelha a de desativar: mesmo módulo, mesma guarda de papel ADMIN e mesma verificação de origem da requisição que as demais mutações de conta já usam (memo de exploração: `users.routes.ts` — padrão de guarda aplicado a todas as mutações de conta). O PLAN decide o nome exato da rota e da função de serviço.
- **A-050-002** [assumido] [evidência: medido] Não há migração de schema: a reativação só volta ao valor nulo o mesmo campo que a desativação já marca (memo de exploração: `users.service.ts` — campo que a desativação preenche com a data; a reativação limpa esse mesmo campo).
- **A-050-003** [assumido] [evidência: crença] O mecanismo de log da reativação (onde e como o registro fica consultável — arquivo, tabela, serviço existente) é decisão técnica do PLAN; esta SPEC exige só o conteúdo verificável (quem, qual conta, quando — NFR-050-001), sem prescrever tabela de auditoria nova. O reconhecimento técnico não encontrou hoje evento de auditoria para desativar ou redefinir senha (RISK-048-008); esta SPEC não assume que tal padrão já exista para estender — cria o registro da ação nova.
- **A-050-004** [assumido] [evidência: crença] O texto final da confirmação de "Ativar" e os textos revisados de "Desativar" e do aviso de e-mail duplicado são redigidos no PLAN/implementação; esta SPEC só exige que não contradigam a existência da reativação (FR-050-001, FR-050-007, FR-050-008).
- **A-050-005** [assumido] [evidência: crença] A reativação da própria conta pelo ADMIN não é um cenário possível nesta SPEC: só uma conta desativada oferece "Ativar", e o ADMIN logado está, por definição, numa conta ativa — o caso "reativar a própria conta" não se aplica.
- **A-050-006** [assumido] [evidência: medido] A guarda de acesso à tela e à coluna "Ações" (ADMIN autenticado) já existe e não é reaberta por esta SPEC (herdada de FR-048-001/NFR-048-002); a ação nova herda a mesma guarda, sem controle de acesso adicional específico para "Ativar".
- **A-050-007** [assumido] [evidência: crença] A autenticação recusa conta desativada só pelo campo de desativação (`disabledAt` ou equivalente); o PLAN confirma isso no código antes de fatiar a implementação. Se existir outra guarda, ela entra na fatia de backend sem mudar o contrato desta SPEC. AC-050-003 (login real após reativação) é a prova que falsifica esta premissa. Sessões encerradas na desativação não voltam: a pessoa faz login de novo depois de reativada.

### Emendas à SPEC-048
Esta SPEC emenda a SPEC-048 só no que segue; tudo o mais da SPEC-048 permanece.
- (a) [assumido] [evidência: crença] FR-048-013/AC-048-012: a orientação fixa "a reativação ainda não está disponível por esta tela" passa a ser regida por FR-050-008/AC-050-007; o resto do FR (mensagem do servidor "Já existe uma conta com este e-mail." junto ao campo e-mail, não altera a conta existente) continua valendo.
- (b) [assumido] [evidência: crença] FR-048-015/AC-048-015: a cláusula "a reativação não está disponível nesta tela" passa a ser regida por FR-050-007/AC-050-006; o resto do FR (nome e e-mail da conta-alvo, desconexão da pessoa, foco dentro da confirmação) continua valendo.
- (c) [assumido] [evidência: crença] FR-048-014 continua valendo, agora atendido pelo controle compacto (FR-050-009): enquanto a conta está ativa, oferece "Desativar"; desativada, não.
- (d) [assumido] [evidência: crença] FEAT-048-004 (FR-048-019 a FR-048-024, AC-048-019 a AC-048-026): o ponto de entrada "Redefinir senha" na linha é retirado (FR-050-012); o comportamento continua especificado para quando for realocado (página de edição, fora desta SPEC); a UI fica sem caminho de tela até lá (RISK-050-001); A-048-003 continua valendo.

## 9. Riscos e questões abertas
- **RISK-050-001** "Redefinir senha" sai da linha sem realocação nesta entrega: a ação deixa de ter caminho de tela até a página de edição ser entregue (outro card do épico KAN-218). Isso inclui o sub-caso de uma pessoa reativada por esta SPEC que esqueceu a senha: a redefinição já exigia conta ativa (A-048-003) e agora, mesmo com a conta ativa de novo, a ação também saiu da linha — não há caminho de tela para redefinir a senha dela até a página de edição existir; é o mesmo risco aceito do brief, não um risco novo. *Mitigação*: nenhuma nesta entrega — risco aceito e registrado como pendência do épico; a rota de servidor de redefinir senha continua existindo (FR-048-019 a FR-048-024 intactas), só a UI na linha é removida.
- **RISK-050-002** OWASP A09 — criar, desativar e redefinir senha continuam sem trilha de autor (RISK-048-008, ainda aberto; decisão do Diretor: história de backend de auditoria candidata, sem card até autorização). *Mitigação*: esta SPEC mitiga só a ação nova (reativar) com NFR-050-001/AC-050-005; não fecha RISK-048-008 para as outras três ações.
- **RISK-050-003** Troca de botões de texto por controles compactos pode regressar acessibilidade (histórico de re-gate de AA no slug, FEAT-048 e gate 11). *Mitigação*: AC-050-009/AC-050-010; gate 11.
- **RISK-050-004** Gate 9 depende de contas reais (ADMIN, EDITOR, conta descartável desativada/reativada); sem ambiente disponível, vira `pendente_handoff` (mesmo padrão de PLAN-049).
- **RISK-050-005** O censo de rotas do backend (suíte de autorização) está travado em um número fixo de pares método+caminho comparado por igualdade estrita; a rota nova de reativar precisa entrar nesse censo e o comentário do título precisa ser atualizado manualmente — esquecer quebra a suíte por desenho (tripwire), não é regressão real.
- **RISK-050-006** A origem do controle visual (SVG próprio ou biblioteca de ícones) é decisão técnica do PLAN; se recair sobre biblioteca nova, soma auditoria de dependência antes de entrar e pode acionar o gate de performance pelo peso de bundle.
- **RISK-050-007** Reativar conta ADMIN desativada produz um 2º ADMIN ativo; herda RISK-048-009/RISK-032-006 e a decisão do Diretor de 2026-10-01 (nenhum 2º ADMIN real até o RISK-032-006 entrar). *Mitigação*: diretriz operacional do Diretor (não é controle de produto); gate 9 só com conta descartável (nunca com `admin2` real de dev); a Entrega relembra a diretriz.
- **Q-050-001** Existe necessidade de, no mesmo fluxo de reativar, também mudar o papel da conta ou prepará-la para edição? Herdado de Q-048-001, ainda sem resposta — fora desta SPEC se a resposta for sim (viraria outro card).

## 10. Fora deste documento
Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e `/keelson:tasks`.
