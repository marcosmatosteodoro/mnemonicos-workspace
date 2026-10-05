---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/**/*.test.tsx
tags: [teste, varredura-estatica, regex, falsificabilidade, mutacao]
---
## [Testes] Teste de varredura estática afirma que achou alvos e é provado por mutação antes do commit

**Erro:** no KAN-228, o teste que varre os `.tsx` atrás de `RequiredMark` solto em label `flex-col` foi commitado com um byte de controle (0x08) no lugar de `\b` no regex. O padrão nunca casava e o teste passava sempre; lint, prettier e tsc não acusam. O code-reviewer pegou por mutação.
**Causa:** o escape `\b` virou backspace ao gravar o arquivo, e a varredura não afirmava que encontrou alvos, então o verde vazio passou.
**Solução:** todo teste de varredura estática (regex sobre fonte) afirma `expect(scanned).toBeGreaterThan(0)` além do zero de ofensores, e é provado com uma mutação (reintroduzir o defeito, ver vermelho, restaurar) antes do commit. Confira `git grep -nP '[\x00-\x08\x0B\x0C\x0E-\x1F]' -- src` vazio. Referência: `src/components/required-mark.test.tsx` (KAN-228).
