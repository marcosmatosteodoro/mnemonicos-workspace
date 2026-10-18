---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/tests/integration/**/*.routes.integration.test.ts
  - mnemonicos-backend/src/modules/**/*.service.ts
tags: [fr, campos-opcionais, fk, mutacao, persistencia]
---
## [Testes] FR com sujeitos opcionais prova cada sujeito gravado e relido, e cada guarda de FK recusando

**Erro:** no PLAN-063 (TASK-063-003, KAN-250, 2026-10-18) o FR-061-001 [MUST] tinha dois sujeitos
opcionais — Prova/concurso (texto livre) e Disciplina (FK do cadastro). Só o schema era testado: os
mutantes "examName sempre null", "disciplineId sempre null" e "guarda de disciplina no-op" sobreviveram
à suíte inteira.
**Causa:** os casos de ponta a ponta usavam só os campos obrigatórios; cobrir a validação do schema
deixou a persistência e a guarda de existência sem prova.
**Solução:** cada sujeito opcional de um FR tem 1 caso preenchido que é gravado e relido pela rota de
leitura; texto livre "só espaços" tem caso que grava `null`; toda guarda de FK de cadastro tem 1 caso de
recusa observável (status + mensagem + nada gravado). Mutante por sujeito confirma que cada caso morre
sozinho.
