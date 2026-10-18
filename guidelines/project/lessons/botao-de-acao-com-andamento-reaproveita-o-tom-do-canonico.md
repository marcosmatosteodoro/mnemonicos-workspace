---
area: Design
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.tsx
tags: [botao, busy, action-button, tom-destrutivo, reuso]
---
## [Design] Botão de ação que ganha estado de andamento reaproveita o tom do canônico, não recompõe a classe à mão

**Erro:** no PLAN-063 (TASK-063-011, KAN-258, 2026-10-18) "Remover do Pacote" trocou `ActionButton`
por `BusyButton` para ganhar o gerúndio "Removendo"; a classe foi recomposta à mão e o botão destrutivo
perdeu o hover `--danger` — o "Remover" do Pacote na mesma tela reage em vermelho, o do Item em cor de
link. O mesmo recompor de ícone/classe já existe em `pdf-library-board.tsx`, `publication-export-control.tsx`
e `sales-package-pdf-picker.tsx`.
**Causa:** o `ActionButton` (canônico de botão de ação) não tem estado ocupado; cada ação assíncrona com
ícone remonta ícone, classe e tom sobre o `BusyButton`, e cada remontagem perde um pedaço do canônico.
**Solução:** botão de ação com andamento usa o tom exportado do canônico
(`mnemonicos-frontend/src/components/action-button.tsx` — a classe de perigo, hoje na linha ~34), nunca
uma classe reescrita; a prova é o hover/cor igual ao do gesto irmão na mesma tela. Reincidindo, o gatilho
é dar ao `ActionButton` uma prop `isBusy`/`busyLabel` que delega ao `BusyButton` (`progress-indicator.tsx`).
