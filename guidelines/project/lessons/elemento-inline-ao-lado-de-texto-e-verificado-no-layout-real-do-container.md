---
area: Design
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.tsx
tags: [layout, flex, inline, rotulo, required-mark]
---
## [Design] Elemento inline ao lado de um texto é verificado no layout real do container (flex/grid)

**Erro:** o KAN-216 introduziu `RequiredMark` como irmão do texto dentro de `<label className="flex flex-col">`, e o asterisco caiu numa linha própria em 11 telas (KAN-228). O exemplo do guideline frontend prescrevia o mesmo markup quebrado.
**Causa:** o componente inline foi especificado e documentado sem considerar o container: em flex/grid, cada nó de texto ou span solto vira um item próprio.
**Solução:** em label `flex-col` que envolve o controle, o rótulo obrigatório é sempre `RequiredLabelText`; `RequiredMark` solto só em `<label htmlFor>` separado. Regra geral: elemento inline que acompanha texto se confere dentro do layout real do container, não isolado.
