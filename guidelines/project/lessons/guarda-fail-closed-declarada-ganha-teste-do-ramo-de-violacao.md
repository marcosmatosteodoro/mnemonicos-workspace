---
area: Segurança
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/**/*.ts
tags: [seguranca, fail-closed, teste, mutacao]
---
## [Segurança] Guarda fail-closed declarada ganha teste do ramo de violação de contrato

**Erro:** em PLAN-035 (TASK-035-004, gate 8 da Wave 2), `resolveApprovalStatus` tratava
"Versão aprovada sem os campos atuais" como `concluded = false` (falha fechada, comentário
citando o Art. 2), mas nenhum teste passava por esse ramo — o mutante que o abre
(`concluded: true`) sobreviveu aos 21 testes.
**Causa:** os testes cobriam só os caminhos do contrato feliz, não a violação de contrato que
o próprio código trata como falha fechada.
**Solução:** toda guarda declarada fail-closed (comentário "falha fechada"/"Art. 2", mapa
parcial onde ausência é negação) ganha 1 teste do ramo de violação, afirmando o valor
restritivo, e o mutante que a abre morre.
