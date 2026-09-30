---
area: Segurança
estado: ativa
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/**/*.service.ts
  - mnemonicos-backend/tests/integration/**/*.routes.integration.test.ts
tags: [seguranca, serializacao, teste]
---
## [Segurança] `select` de leitura exposta que passa a ler campo interno prova as chaves do payload

**Erro:** em `listContentVersions` (PLAN-033, TASK-033-004), o `findMany` passou a ler
`contentSnapshot` (dado interno, DEC-029-003) ao lado dos campos públicos. O não-vazamento
ficou garantido só pelo mapeamento campo a campo da resposta. Os testes de listagem
comparavam só ids. Um refactor para `{ ...version, validApprovalForExport }` vazaria o
snapshot com a suíte verde. Achado como lacuna de prova no gate 8.
**Causa:** o teste de contrato (`contents-frontend-contract.test.ts`) trava o TIPO, não o
payload em runtime. Tipo sem o campo não impede o objeto de carregá-lo.
**Solução:** quando um `select` de leitura exposta ganha um campo interno, o mesmo diff traz
uma asserção de chaves exatas no payload HTTP da rota consumidora: `Object.keys(...).sort()`
ou `toEqual` de forma completa (molde: `content-versions.routes.integration.test.ts`). Só
`not.toHaveProperty('<campo>')` já basta para o campo nomeado, mas não pega o próximo campo.
