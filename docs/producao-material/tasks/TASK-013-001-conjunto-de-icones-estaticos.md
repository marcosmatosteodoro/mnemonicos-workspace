# TASK-013-001: Criar conjunto de ícones estáticos do app-shell

**Slug**: producao-material
**Pertence a**: PLAN-013
**Realiza (FRs)**: FR-013-001, FR-013-003, FR-013-004
**Componente**: COMP-013-002 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-pwa-support` (já criada a partir de
`origin/main` pelo PLAN-013) — **cwd obrigatório do `developer`**:
`C:/kwt/pwa/mnemonicos-frontend` (worktree isolado). **NUNCA** rodar `dev`/`test`/`lint`/
`typecheck`/`build` em `mnemonicos-frontend/` da working tree principal — outra sessão
executa PLAN-012/F4 ali concorrentemente (RISK-013-005, TRISK-013-002).
**Padrão de commit**: Conventional Commits (`feat:`).
**Framework de teste**: Jest 30 + `next/jest` (`jest.config.ts`), `testEnvironment: 'jsdom'`
— este arquivo em particular não precisa de `jsdom` (leitura de bytes de arquivo).

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-013-002, TASK-013-003

## Contexto

O `mnemonicos-frontend` não tem `public/` hoje (só `src/app/favicon.ico` — memo de
exploração, item 6). Esta TASK cria a pasta `public/icons/` e os dois arquivos de ícone
que os critérios de instalabilidade do Chrome/Edge exigem como piso mínimo (Q-013-001,
resolvida no PLAN §1): 192×192 e 512×512, ambos `purpose: "any"`, derivados da identidade
visual atual (A-013-002) — sem trabalho de design de marca novo. O manifesto
(TASK-013-002) referencia estes dois arquivos.

## Escopo

### Inclui
- `mnemonicos-frontend/public/icons/icon-192.png` — PNG 192×192 px, `purpose: "any"`.
- `mnemonicos-frontend/public/icons/icon-512.png` — PNG 512×512 px, `purpose: "any"`.
- A pasta `public/` nasce nesta fatia (PLAN §"Exceções aos guidelines", item 2) — primeira
  vez que o projeto tem asset estático fora de `src/app/`.

### Não inclui
- Ícone `maskable` dedicado (Out-of-scope SPEC-013 §4.2 — já registrado, não é decisão
  desta execução).
- Qualquer novo trabalho de design de marca (nova arte, variações) — A-013-002.
- `app/manifest.ts` referenciando estes ícones — TASK-013-002.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Gerar (ou derivar) os dois PNGs a partir da identidade visual atual (favicon existente
   e/ou tokens `--color-ink-50/950`/`--color-brand-400/500/600` de `globals.css:4-15`) —
   sem biblioteca nova na árvore (nenhuma dependência nova é assumida por este PLAN, §2).
2. Gravar em `public/icons/icon-192.png` e `public/icons/icon-512.png`.
3. Escrever o teste de dimensão lendo os bytes crus do PNG (chunk `IHDR`: largura no byte
   offset 16–19, altura no offset 20–23, big-endian uint32) — sem depender de biblioteca de
   imagem.

## Critérios de pronto

- [ ] AC-013-002 (parte — dimensão/existência dos dois ícones nos tamanhos exigidos; a
      faceta "nome e ícone consistentes no app instalado, exibidos pelo SO" fecha por
      gate 9 na TASK-013-005, que depende desta).
- [ ] `public/icons/icon-192.png` existe e mede exatamente 192×192 px.
- [ ] `public/icons/icon-512.png` existe e mede exatamente 512×512 px.
- [ ] Teste cobre a dimensão dos dois arquivos (contrato do próprio item, sem AC associado
      — item 6 do Escopo > Inclui) — verificação executável:
      `npx jest --runTestsByPath tests/assets/app-icons.test.ts` → `OK (2 tests)`, um teste
      por arquivo, cada um lendo os bytes do `IHDR` e comparando com a dimensão exigida;
      fixada antes do código (arquivo-alvo ainda não existe — comando roda contra os PNGs
      assim que gravados, mesma rodada do commit).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`), produção e teste.
- [ ] Padrão de commit respeitado (Conventional Commits, `feat:`).
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem (`next-16.md`) — nenhuma
      dependência nova adicionada ao `package.json`.
- [ ] Code review aprovado.

## Riscos específicos

- Nenhum ícone `maskable` nesta fatia — Android pode recortar o ícone de forma menos
  previsível sem essa variante (aceito, Out-of-scope SPEC-013 §4.2).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-65
**Implementado por**: 
**Revisado por**: 
**Tentativas**: 
**Cobertura final**: 
**Arquivos modificados**:
  - 

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>

**Notas**: 
