---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 1
contestada: 0
paths:
  - mnemonicos-frontend/src/**/*.test.tsx
tags: [teste, ausencia, oraculo, mutacao, frontend]
---
## [Testes] Asserção de ausência em render carrega controle positivo no mesmo `it`

**Erro:** no BRIEF-038 (KAN-176, 2026-09-30), o teste "não tem link nem botão 'Entrar' no
corpo" de `src/app/page.test.tsx` usava `queryByRole(...)` com `not.toBeInTheDocument()`
num `it` próprio. A âncora de presença (h1/h2) ficava num `it` irmão, com outro render. Com
`HomePage` retornando `null`, o `it` de ausência continuava verde e só o `it` da âncora
falhava. O `code-reviewer` achou isso rodando o mutante M3.
**Causa:** o controle de não-vacuidade ficou num caso separado, em vez de ir na mesma
execução. O único mutante verificado foi o da regressão (reinserir o elemento), nunca o do
corpo vazio.
**Solução:** todo `it` que prova ausência (`queryBy*` com `not.toBeInTheDocument()` ou
`toBeNull()`) inclui, no mesmo render, um `getBy*` de conteúdo que precisa existir. O teste
só fecha quando dois mutantes morrem: reintroduzir o elemento e fazer o componente retornar
`null`. Isso aplica a regra "Oráculo tem de poder falhar" do `frontend/next-16.md` §7 à
ausência. Se reincidir, avaliar se vira linha explícita no §7 em vez de lição avulsa.
