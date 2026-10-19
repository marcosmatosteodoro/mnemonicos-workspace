---
area: Documentação
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - docs/GUIA-DE-USO.md
tags: [guia-de-uso, documentacao, oraculo-de-presenca, verdade-do-texto]
---
## [Documentação] Afirmação do guia sobre o que um modo contém ou em que tela algo aparece leva âncora no código do destino

**Erro:** no PLAN-065 (TASK-065-017, KAN-277, 2026-10-19), ao reorganizar o passo 6 do Guia de
uso em dois modos, uma frase que valia para o rascunho ("contrastes, pegadinha, flashcards,
protocolo de revisão") foi parar no PDF final. A ressalva "até existir uma versão aprovada" do
rótulo RASCUNHO caiu, e o guia passou a dizer que o PDF final existe "na tela do conteúdo ou da
Tira". Os 7 oráculos da TASK passaram e o code-reviewer reprovou pelo gate 7.
**Causa:** os oráculos de TASK de guia medem presença de rótulo, não a verdade da frase. Quem
escreveu conferiu os rótulos contra os componentes, mas não conferiu cada afirmação contra o
código do modo ou da tela de destino.
**Solução:** em TASK de guia, cada afirmação nova, ou movida entre modos e telas, leva uma âncora
`arquivo:linha` no código do destino (o compositor do modo: `final-pdf-composer.ts` × `pdf-composer.ts`;
o componente que monta a ação: quem passa `showFinalExport`). O report do developer traz a tabela
"afirmação → arquivo:linha", e o revisor a confere por leitura. Os oráculos de rótulo continuam,
mas só provam que o rótulo existe.
