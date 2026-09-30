---
area: Arquitetura
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.tsx
  - mnemonicos-frontend/src/app/**/*.tsx
tags: [app-router, navegacao, remontagem, requisito, client-component]
---
## [Arquitetura] "A cada abertura da rota" no App Router não é "a cada montagem": navegar para a URL atual não remonta

**Erro:** no PLAN-041 (KAN-180, 2026-09-30), o FR-040-013 prometia uma conferência de sessão nova
"a cada abertura da página inicial (endereço, recarga, logo, …)", e o RISK-040-005 apontava a
recuperação de uma falha "pelo logo ou recarga". O `HomeSessionGate` confere na montagem (e em
`pageshow` restaurado do bfcache). Com a pessoa já em `/`, clicar no logo (`<Link href="/">`) é
navegação para a mesma URL. O App Router do Next 16 não remonta o segmento (a chave é o `stateKey`
em `layout-router.js`), então a conferência não se repete. Só a recarga recupera. A convergência de
fecho achou o gap; nenhum teste cobria o caso.
**Causa:** a régua "cada abertura re-confere" foi implementada como "cada montagem re-confere". As
duas coincidem para quem chega de outra rota e divergem quando a rota atual já é o destino.
**Solução:** requisito do tipo "a cada abertura da rota X" num client component do App Router ganha
um caso próprio para `Link`/`router.push` para a URL atual. Ou a TASK nomeia esse caso no Critério de
pronto (com o mecanismo que re-dispara), ou a SPEC o exclui explicitamente.
