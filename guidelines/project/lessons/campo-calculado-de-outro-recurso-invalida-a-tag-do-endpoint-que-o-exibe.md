---
area: Design
estado: ativa
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/store/api.ts
  - mnemonicos-frontend/src/components/**
tags: [rtk-query, cache, estado-de-ui]
---
## [Design] Campo calculado a partir de outro recurso invalida a tag do endpoint que o exibe

**Erro:** `validApprovalForExport` vem em `listContentVersions` (tag `ContentVersion`), mas o
backend o calcula a partir do `RawContent`. Em `/content/:id`, `updateRawContent` invalidava
só `RawContent`: o ADMIN aprovava, corrigia o texto na mesma página e a tela seguia
afirmando "Válida para a próxima exportação: sim" até recarregar. É o oposto do que o
AC-032-020 manda exibir. Achado no gate 11 da TASK-033-007 (PLAN-033).
**Causa:** a tag segue o dono do endpoint, não os dados de que o campo calculado depende. O
comentário "sem invalidar RawContent" cobriu uma direção e não a oposta.
**Solução:** ao exibir um campo que o servidor calcula a partir de outro recurso, liste por
grep as mutations desse recurso que rodam na MESMA rota sem remontar e inclua nelas a tag do
endpoint exibidor. Prova: teste montado que dispara a mutation e confere o valor novo;
fechamento é o mutante que tira a tag.
