---
area: Testes
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.tsx
  - mnemonicos-frontend/src/components/**/*.test.tsx
tags: [obrigatorio, aria-required, kan-216, kan-234]
---
## [Testes] AC de campo obrigatório se prova com `aria-required="true"`, não com a presença do rótulo

**Erro:** no KAN-234 o teste "ambas obrigatórias" só afirmava que os rótulos existiam, e os dois
`PasswordField` ficaram sem `required`. O code-reviewer pegou na 1ª rodada.
**Causa:** o nome do teste repetiu o texto do AC, mas a asserção não testava a propriedade que o AC
exige.
**Solução:** campo obrigatório passa `required` (padrão KAN-216, `required-mark.tsx`) e o teste
afirma `aria-required="true"` no controle. Busque por `requiredLabel(...)`, porque o "*" entra no
texto do `<label>`.
