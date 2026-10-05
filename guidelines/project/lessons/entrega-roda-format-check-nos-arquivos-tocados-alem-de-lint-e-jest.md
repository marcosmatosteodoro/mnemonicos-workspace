---
area: Config
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-frontend/**
tags: [config, prettier, crlf, windows]
---
## [Config] Antes de entregar, `prettier --check` nos arquivos tocados — não só eslint, tsc e jest

**Erro:** no KAN-231, `action-icons.tsx` ficou com terminação CRLF no worktree e quebrou o
`format:check` (e com ele o `npm run validate`), embora eslint, tsc e jest passassem.
**Causa:** `core.autocrlf=true` no Windows somado a edição que regrava em CRLF, enquanto
`.prettierrc.json` exige `endOfLine: lf`. O `format:check` do repo inteiro já falha no checkout
Windows por isso, então a falha real some no ruído.
**Solução:** rodar `npx prettier --check <arquivos tocados>` (e `--write` se preciso) antes do
commit; commitar por caminho explícito, nunca `git add -A`. Um `.gitattributes` com
`* text=auto eol=lf` no frontend resolveria na raiz — decisão do Diretor.
