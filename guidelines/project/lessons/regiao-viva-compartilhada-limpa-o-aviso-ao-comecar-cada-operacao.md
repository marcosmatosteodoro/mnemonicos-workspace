---
area: Design
estado: ativa
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.tsx
tags: [acessibilidade, aria-live, leitor-de-tela, estado-de-sucesso]
---
## [Design] Região viva de aviso compartilhada limpa o texto ao COMEÇAR cada operação — a mesma ação repetida não é anunciada

**Erro:** na TASK-049-005 (PLAN-049, KAN-179, 2026-10-01) desativar uma conta grava
"Conta desativada." na região `role="status"` persistente do `UsersScreen`. Na segunda
desativação seguida o texto já está lá: `setNotice` recebe a mesma string, o React descarta o
update e, mesmo que re-renderizasse, o DOM não muda — o leitor de tela não anuncia nada. Pego
pelo `product-designer` (gate 11, re-review da Wave 3).
**Causa:** quem escreve na região só define o texto do sucesso e não a limpa no início da nova
operação. React e leitor de tela não reagem a valor idêntico.
**Solução:** toda operação que escreve na região de status da tela limpa o aviso ao começar
(abrir o diálogo, enviar o formulário) — padrão de referência: `setNotice('')` em
`handleToggleCreate` (`mnemonicos-frontend/src/components/users-screen.tsx`). O teste de
integração cobre DUAS execuções seguidas da mesma ação e lê o texto da região depois de um ciclo
vazio.
