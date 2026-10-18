---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/tests/unit/env.test.ts
  - mnemonicos-backend/tests/unit/**/*.test.ts
  - mnemonicos-backend/src/config/env.ts
tags: [env, dotenv, jest, isolateModules, ambiente]
---
## [Testes] Teste de "env ausente" sob `jest.isolateModules` neutraliza o `dotenv/config`

**Erro:** no PLAN-063 (TASK-063-002, KAN-249, 2026-10-18) os testes de "storage ausente" apagavam as
chaves `OBJECT_STORAGE_*` de `process.env` e recarregavam `src/config/env` sob `jest.isolateModules`.
Passavam só em máquina cujo `.env` não tinha as chaves: com `cp .env.example .env`, 2 testes ficavam
vermelhos.
**Causa:** o `require` sob `isolateModules` re-executa `import 'dotenv/config'`, e o dotenv só deixa de
sobrescrever chave DEFINIDA. O `delete` torna a chave indefinida e o `.env` local volta a preenchê-la.
**Solução:** módulo que importa `dotenv/config`, carregado sob `isolateModules` num teste de ausência,
leva `jest.doMock('dotenv/config', () => ({}))` dentro do bloco (ou usa chave `= ''` quando o schema é
`optionalEmptyString`). A prova de ausência roda também numa git worktree com `cp .env.example .env`.
Âncora: `guidelines/project/backend/node-22.md` §7 ("nenhum teste lê .env").
