---
area: Segurança
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/config/origin-allowlist.ts
  - mnemonicos-backend/.env.example
tags: [seguranca, cors, csrf, vercel]
---
## [Segurança] Curinga de CORS/CSRF só sob domínio que o time controla

**Erro:** em BRIEF-060, o padrão `https://mnemonicos-frontend-*-mp-consultoria-projects.vercel.app`
foi recomendado como se o sufixo com o slug do time garantisse posse do host. O gate 8 mostrou
que não: qualquer conta Vercel cria um projeto ou time cujo nome casa o padrão.
**Causa:** em plataforma multi-tenant o nome do subdomínio é escolhido pelo tenant; sufixo textual
não prova propriedade, e um `*` que aceita `-` absorve qualquer prefixo de slug.
**Solução:** entrada com `*` em `CORS_ORIGINS` só sob domínio controlado pelo time, ou só no escopo
Preview da Vercel com backend/banco isolados; Production fica só com literais. O validador exige
texto literal no mesmo rótulo do `*`, para não liberar TLD nem plataforma inteira.
