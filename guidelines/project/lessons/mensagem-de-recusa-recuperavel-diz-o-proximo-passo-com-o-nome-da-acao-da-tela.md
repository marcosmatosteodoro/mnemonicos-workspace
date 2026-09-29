---
area: Design
estado: ativa
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/**/*.service.ts
tags: [copy, erro]
---
## [Design] Mensagem de recusa recuperável diz o próximo passo com o nome da ação da tela

**Erro:** na aprovação de Versão (PLAN-031), "Falta fonte normativa registrada nesta
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
