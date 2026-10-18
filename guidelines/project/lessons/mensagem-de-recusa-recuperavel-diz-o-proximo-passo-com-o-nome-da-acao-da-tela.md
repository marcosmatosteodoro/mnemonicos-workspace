---
area: Design
estado: ativa
validade: indeterminada
confirmada: 3
contestada: 0
paths:
  - mnemonicos-backend/src/modules/**/*.service.ts
  - mnemonicos-frontend/src/components/**
tags: [copy, erro]
---
## [Design] Mensagem de recusa recuperável diz o próximo passo com o nome da ação da tela

**Erro:** na aprovação de Versão (PLAN-033), "Falta fonte normativa registrada nesta
Versão." prendia o ADMIN num ciclo: ele registrava a fonte e recebia a mesma recusa, porque
a guarda lê o snapshot congelado da Versão — a única saída é fechar uma nova versão, e
nenhuma mensagem dizia isso. "O número informado não é mais o da Versão vigente." citava
um número que o usuário nunca digitou. Achado do gate 11.
**Causa:** a copy do `AppError` foi escrita do ponto de vista da guarda (qual condição
falhou), não de quem lê na tela — e a tela mostra a mensagem do backend como vier.
**Solução:** toda mensagem de `AppError` de guarda recuperável que a tela mostra como vier
diz o próximo passo com o nome da ação da tela (ex.: "feche uma nova versão", "Atualize a
página"); quando a guarda lê um snapshot imutável, o texto deixa claro que corrigir o dado
atual não basta. Sem termo técnico (parâmetro de rota, id). Minúscula "versão" como a copy
canônica da tela. Referência: mensagens de `approveContentVersion` e
`mnemonicos-frontend/src/components/content-version-history.tsx`.

**Extensão (gate 11 do retry R-1 da Entrega da F9, 2026-09-29):** o próximo passo tem de ser
POSSÍVEL para quem lê, conferido contra a guarda do backend que o decide, nos estados que o
próprio passo cria. "Feche uma nova versão para aprová-la", mostrado ao ADMIN, era falso: quem
fecha vira autor e a segregação de funções (`producerIds` em `approveContentVersion`) recusa a
autoaprovação. Se o passo não serve a todos os leitores da frase, use uma formulação impessoal e
verdadeira em todas as combinações ("Uma nova versão precisa ser fechada e aprovada por um ADMIN
que não a produziu").

**Confirmação (PLAN-063, TASK-063-004, 2026-10-18):** a mesma função de finalização servia o envio e a
substituição, e a recusa "não é PDF" da substituição mandava usar "Enviar PDF" — que cria um registro
NOVO em vez de substituir. A exceção nasceu de um critério que provava o reúso do código pela igualdade
do texto entre os dois fluxos. Regra: mensagem compartilhada por fluxos com ações diferentes recebe o
contexto (`refusalMessages(context)`) e cita a ação daquele fluxo; reúso se prova pela definição única e
pelo efeito no estado, nunca pela igualdade do texto exibido. Exceção de copy atribuída a um AC cita o
texto do AC.

**Confirmação (PLAN-063, TASK-063-007, 2026-10-18):** o 404 de Pacote dizia "Atualize a lista e tente de
novo" para um estado definitivo (remoção sem `deletedAt` nem restauro), e a mesma constante seria reusada
por Itens e exportação. Regra: em 404 de entidade com remoção definitiva, a mensagem constata o estado ("O
Pacote não existe mais; ele pode ter sido removido.") e manda para a lista — nunca "tente de novo". Antes de
escrever "tente de novo", confira no produtor se o estado é reversível. Recusa de limite cita o limite
("Informe um preço de referência de até R$ 21.474.836,47."), nunca uma regra que o valor já cumpre.
