# TASK-036-003: Script de bootstrap de tema (sem FOUC)

**Slug**: producao-material
**Pertence a**: PLAN-036
**Realiza (FRs)**: FR-036-007, FR-036-008, FR-036-012
**Funcionalidade**: FEAT-036-002 (primária)
**Componente**: COMP-036-003 (principal)
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: TASK-036-002 (consome `THEME_STORAGE_KEY`)
- **Bloqueia**: TASK-036-006

## Contexto

Os componentes React (`RootLayout`, `ThemeToggle`) só hidratam depois do HTML estático já
pintado — sem intervenção antes disso, a escolha de tema salva não aplica a tempo do
1º paint (RISK-036-001). Um script inline, gerado por função pura e embutido no `<head>`,
fecha essa janela antes da hidratação (DEC-036-001; memo — PLAN-036 §1, §6/DEC-036-001).

## Escopo

### Inclui
- `getThemeBootstrapScript(): string` — novo módulo
  `mnemonicos-frontend/src/lib/theme-bootstrap.ts` (mesmo papel de `src/lib/env.ts`: função
  pura, sem JSX). Devolve o texto do script inline: lê
  `localStorage[THEME_STORAGE_KEY]` (constante de `night-palette-tokens.ts`, TASK-036-002);
  se presente e for `'light'` ou `'dark'` (`ThemeName`), aplica
  `document.documentElement.dataset.theme = <valor>` de imediato; se ausente (ou valor
  inesperado), não seta o atributo — o CSS de `prefers-color-scheme` decide sozinho. Toda
  leitura de `localStorage` é envolvida em `try/catch` — qualquer exceção (modo privado,
  `SecurityError`, bloqueio de storage) é tratada exatamente como "ausente" (não seta
  `dataset.theme`, sem propagar erro, sem quebrar o restante do `<head>`).
- Wiring em `mnemonicos-frontend/src/app/layout.tsx`: `<script
  dangerouslySetInnerHTML={{ __html: getThemeBootstrapScript() }} />` como primeiro filho de
  um `<head>` explícito, antes do `<body>` (`layout.tsx:31-44`; `RootLayout` continua Server
  Component, sem `'use client'` adicional — DEC-036-007 herdada).

### Não inclui
- `ThemeToggle` (TASK-036-004) — só CONSOME a mesma constante `THEME_STORAGE_KEY`.
- Leitura de tema no servidor (SSR do valor correto) — fora de escopo, aceito como
  TRISK-036-001/FOUC residual (NFR-036-004 é SHOULD).
- **AC-036-008** (sem escolha salva, dispositivo prefere escuro → aplica escuro) e a
  faceta VISUAL de AC-036-009 (sem escolha salva e sem preferência detectável → aplica
  claro): a camada que de fato aplica esses dois casos é a cascata CSS de `@media
  (prefers-color-scheme: dark)` (TASK-036-002, mecanismo pré-existente e inalterado na
  condição de disparo — só os tokens internos mudam de valor) — o script desta TASK
  deliberadamente NÃO interfere nesses dois casos (critérios acima), mas não pode provar a
  cascata do `@media` em si (jsdom não avalia `prefers-color-scheme` de forma confiável, e
  os testes de `globals-theme-contrast.test.ts` leem valores declarados em bloco, não
  cascata aplicada). Os dois casos migram para o roteiro do gate 9 de TASK-036-006.

## Critérios de pronto

- [ ] `localStorage` vazio + sem preferência de esquema de cores detectável →
      `document.documentElement.dataset.theme` permanece `undefined` após executar o script
      (o CSS aplica o tema claro por default em conjunto com TASK-036-002) — cobre
      AC-036-009 (parcial: a aplicação visual final é do CSS, este critério prova só o
      script). Verificação executável: `npm --prefix mnemonicos-frontend test --
      src/lib/theme-bootstrap.test.ts` → `PASS`, com um caso que executa o texto de
      `getThemeBootstrapScript()` isoladamente (`new Function(script)()` num objeto `window`/
      `document`/`localStorage` de fixture — nunca na árvore de teste principal, `git
      worktree`/objeto isolado se necessário — nunca editando a árvore de trabalho
      destrutivamente) com `localStorage.getItem` mockado para devolver `null`, e afirma que
      o `dataset.theme` do `document` de fixture não foi setado.
- [ ] `localStorage[THEME_STORAGE_KEY] = 'dark'` → o atributo vira `'dark'` de imediato —
      cobre AC-036-011 (que cobre FR-036-011 E FR-036-012 na própria SPEC — "aplica o tema
      salvo dessa escolha" no reload/navegação; nota: AC-036-008 é o caso SEM escolha salva com o
      dispositivo preferindo escuro — não é este critério, ver exclusão abaixo). Mesmo
      arquivo, caso com `localStorage.getItem` mockado para devolver `'dark'`, afirmando
      `document.documentElement.dataset.theme === 'dark'` no objeto de fixture após a
      execução. Mutante: remover a atribuição de `dataset.theme` dentro do texto do script
      reprova as duas asserções.
- [ ] Valor inesperado em `localStorage[THEME_STORAGE_KEY]` (ex.: `'sepia'`, resíduo de uma
      chave antiga ou escrita externa) não seta `dataset.theme` — mesmo tratamento do caso
      "ausente" (contrato do próprio item, sem AC associado; fechamento "de trás para
      frente"). Mesmo arquivo, caso com `localStorage.getItem` devolvendo `'sepia'`.
- [ ] Wiring em `RootLayout` (contrato do próprio item do Inclui, sem AC associado — a
      montagem em composition root exige teste de WIRING, não só do componente isolado,
      lição já aplicada em PLAN-013/`layout.test.tsx`): o `<head>` que `RootLayout` devolve
      contém um `<script>` cujo `dangerouslySetInnerHTML.__html` é exatamente o retorno de
      `getThemeBootstrapScript()`. Verificação executável: `npm --prefix mnemonicos-frontend
      test -- src/app/layout.test.tsx` → `PASS`, novo caso no MESMO arquivo/padrão de
      `containsComponentType`/travessia de árvore de elementos já usado ali
      (`layout.test.tsx:16-28`, sem `render`/jsdom) que percorre `RootLayout({ children: null
      })` procurando um elemento `type === 'script'` com
      `props.dangerouslySetInnerHTML.__html === getThemeBootstrapScript()`. Mutante: remover
      o `<script>` do `<head>` (ou alterar seu conteúdo) reprova.
- [ ] `localStorage.getItem` lançando (mock que lança `SecurityError`) → script não propaga
      exceção, `dataset.theme` permanece não setado — mesmo arquivo de teste, caso com o
      mock de `localStorage` lançando no `getItem`. Mutante: remover o `try/catch` faz o
      teste estourar a exceção não capturada.
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff.

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente**: `http://localhost:3000` (ou a porta viva da sessão) — qualquer rota pública,
ex. `/`. **Sujeito**: nenhuma identidade necessária (comportamento independe de sessão).
**Pré-condição**: `localStorage` limpo para a origem (DevTools → Application → Local
Storage → limpar `mnemonicos:theme` ou equivalente) e o SO do ambiente de verificação
configurado para tema escuro; restaurar `localStorage` limpo e o SO no tema original ao
fim.

1. (NFR-036-004) Com `localStorage` limpo e o SO em dark, carregar `/` e observar a
   primeira pintura: o tema escuro deve estar aplicado sem troca de cor perceptível
   depois do primeiro paint (SHOULD — registrar como observação qualitativa, não bloqueia
   o gate).

## Riscos específicos

- TRISK-036-001 (FOUC residual em caminho de renderização atípico, ex. streaming com
  `<Suspense>` atrasando o `<head>`) — mitigado por o script ser síncrono, sem
  `async`/`defer`, primeiro filho do `<head>`; medição real no roteiro do gate 9 acima
  (NFR-036-004 é SHOULD, não bloqueia).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-30T02:27:36-0300
**Data conclusão**: 2026-09-30T02:41:57-0300
**Commit SHA**: 4c6dd19
**Jira**: KAN-161

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (663/663 na suíte após a task)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (wave 2)
- [x] ACs verificados (AC-036-009 parcial, AC-036-011)
- [x] Segurança (gate 8): aprovado (wave 2) — security-engineer, script inline sem interpolação de dado externo (sem XSS)
- [ ] Comportamento (gate 9): n/a — FEAT-036-002 ainda não completou (aguarda TASK-036-004)
- [x] Design (gate 11): aprovado (wave 2) — product-designer, teste de wiring do `<script>` no `<head>` confirmado não-decorativo
