---
area: Design
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/lib/**
  - mnemonicos-frontend/src/components/**
tags: [erro, copy, envelope, 500, fallback]
---
## [Design] Leitor de envelope de erro que aceita 5xx exclui o 500 genérico

**Erro:** no PLAN-063 (TASK-063-005, KAN-252, 2026-10-18) o helper que lia a mensagem do envelope de
erro foi alargado para "qualquer status", para exibir o 504 declarado da confirmação. Junto passou o 500
genérico do error-handler ("Erro interno."), e as 3 superfícies da tela (formulário, lista, download)
deixaram de mostrar o fallback acionável.
**Causa:** o helper foi escrito pelo caso que precisava incluir (5xx declarado), sem enumerar o caso que
o error-handler produz no mesmo intervalo (500 `INTERNAL_SERVER_ERROR`). A regra "o 500 não ecoa" vivia
só em testes de outro módulo.
**Solução:** um leitor de envelope só (`getEnvelopeMessage` em `src/lib/user-admin-errors.ts`) que devolve
`undefined` para status 500 / code `INTERNAL_SERVER_ERROR` e a `message` nos demais; um caso unit por
valor (500 → undefined; 504 declarado → message) e, em cada superfície que exibe mensagem, um caso
500 + "Erro interno." afirmando o fallback e a ausência do texto genérico.
