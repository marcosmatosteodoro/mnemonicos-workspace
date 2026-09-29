---
area: Segurança
estado: ativa
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/content-versions/**
  - mnemonicos-backend/src/modules/contents/contents.service.ts
tags: [seguranca, autorizacao]
---
## [Segurança] Regra de autorização que lê identidade de campo sobrescrevível prova as duas direções

**Erro:** a segregação de funções da aprovação de Versão (PLAN-033) lia o "último editor"
(`RawContent.lastEditedById`) ao vivo e dava a leitura como segura. `updateRawContent`
carimba esse campo em todo PATCH, inclusive `{}`, só de campo não versionado ou re-save
idêntico — nenhum deles acende o sinal de alteração —, então a identidade de quem editou
antes do fechamento era apagada e o produtor aprovava o próprio texto. Achado do gate 8
com sonda contra Postgres real.
**Causa:** a premissa "toda edição pós-fechamento acende o sinal" nunca foi falsificada, e
o teste só cobriu "o editor novo é bloqueado", não "o editor antigo continua bloqueado".
**Solução:** toda regra de autorização que lê identidade de um campo sobrescrevível
(`lastEditedById`, `updatedBy` e afins) prova as duas direções: o valor novo bloqueia E o
valor anterior continua bloqueado depois de uma escrita que não muda o dado protegido.
Se o valor anterior não puder ser reconstruído, a regra recusa (fail-secure) ou o valor é
congelado no ato que o torna relevante. Referência: `approveContentVersion` (guarda de
edição pós-fechamento) × `updateRawContent`.
