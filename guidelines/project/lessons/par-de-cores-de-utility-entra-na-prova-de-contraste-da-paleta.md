---
area: Design
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/src/app/globals.css
  - mnemonicos-frontend/src/app/night-palette-tokens.ts
tags: [design, contraste, tokens, paleta]
---
## [Design] Utility que compõe duas cores de token registra o par na prova de contraste da paleta

**Erro:** em PLAN-035 (TASK-035-008), o merge da paleta unificada (PR #18 do frontend) foi dado
como compatível porque os nomes dos tokens sobreviveram; o par `bar-fill`/`bar-track` da barra de
"Conclusão por Módulo" caiu para 1,25:1 no tema escuro sem nenhum teste acusar — `--border-subtle`
mudou de valor e o trilho usava esse papel de BORDA como preenchimento.
**Causa:** o par nunca entrou em `NIGHT_PALETTE_ROLE_VS_SURFACE_PAIRS`; só os pares listados ali
são provados.
**Solução:** todo utilitário que compõe duas cores de token (preenchimento sobre trilho, selo sobre
fundo) registra o par em `src/app/night-palette-tokens.ts` com o piso 3:1 ou 4,5:1 conforme o
caso; após remapear a paleta, "compatível" = pares provados no teste, não nomes presentes. Não usar
papel de borda (`--border-subtle`) como preenchimento de área — variável semântica por tema
(ex.: `--progress-fill`, molde de `--link`/`--danger`).
