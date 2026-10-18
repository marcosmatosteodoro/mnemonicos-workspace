---
area: Design
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - docs/GUIA-DE-USO.md
tags: [guia, diagnostico, cors, copy, documentacao]
---
## [Design] Linha de diagnóstico do guia copia a mensagem da tela que faz o pedido — e confere COMO ela o faz

**Erro:** no PLAN-063 (TASK-063-013, KAN-260, 2026-10-18) o guia ligou a falha de CORS do bucket ao "Baixar"
do PDF — que abre o endereço assinado por navegação (`<a href>` + `click()`), sem preflight — e omitiu a
exportação do Pacote, cujo `fetch(entry.url)` é o GET que de fato depende de CORS e cuja falha mostra
"Não foi possível gerar o arquivo…". O usuário com o bucket mal configurado repetiria a exportação sem fim.
**Causa:** a linha foi escrita a partir do comentário de infraestrutura ("PUT/GET direto no bucket") e do
escopo da TASK ("envio ou download"), sem conferir qual tela faz cada pedido e por qual mecanismo.
**Solução:** ao documentar erro de infraestrutura no guia, localizar por grep o ponto da tela que emite o
pedido (`fetch`/XHR → sujeito a CORS; `href`/navegação → não) e copiar a mensagem LITERAL daquele ponto; uma
linha da tabela "Quando algo não funciona" só existe com a mensagem que a tela realmente mostra.
Referências: `mnemonicos-frontend/src/lib/export-package-archive.ts`, `src/components/pdf-library-board.tsx`.
