# TASK-036-002: Paleta unificada — papéis de UI do app na paleta noturna

**Slug**: producao-material
**Pertence a**: PLAN-036
**Realiza (FRs)**: FR-036-013
**Funcionalidade**: FEAT-036-002 (primária)
**Componente**: COMP-036-005 (principal)
**Wave**: 1
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-036-003, TASK-036-004

## Contexto

Hoje `--surface`/`--surface-raised`/`--border-subtle` usam a paleta `--color-ink-*`
genérica fora de `/login` (`globals.css:63-79`). Esta TASK migra os três papéis para a
paleta noturna já validada em `/login` (SPEC-030/PLAN-031), nas três camadas de seletor
que DEC-036-002 introduz, e estende `night-palette-tokens.ts` com os pares de contraste
que essa migração passa a exigir por nome semântico (DEC-036-003/004; memo — PLAN-036 §3
COMP-036-005, §6 DEC-036-002/003/004).

## Escopo

### Inclui
- `mnemonicos-frontend/src/app/globals.css`:
  - No `:root` de `@layer base` (`globals.css:63-73`, tema claro): `--surface: var(--color-ink-50)`
    → `--surface: var(--color-night-panel-bg)`; `--surface-raised: #ffffff` → `--surface-raised:
    var(--color-night-pill-bg)`; `--border-subtle: var(--color-ink-200)` → `--border-subtle:
    var(--color-night-pill-border)`. `--text-strong`, `--text-muted`, `--link`, `--danger`
    permanecem com o valor exato de hoje (DEC-036-003).
  - Reestruturar `@media (prefers-color-scheme: dark) { :root { ... } }` (`globals.css:75-132`)
    para `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { ... } }`,
    mantendo todo o conteúdo interno — `--surface`/`--surface-raised`/`--border-subtle`
    remapeados para os mesmos três tokens noturnos, usando os valores hex do tema escuro que
    já vivem nesse bloco (`--color-night-panel-bg`/`--color-night-pill-bg`/
    `--color-night-pill-border`, hoje redeclarados em `globals.css:99-130`).
  - Acrescentar `:root[data-theme="dark"] { ... }` (mesmo nível de `@layer base`, fora do
    `@media`) com os valores EXATOS do bloco `:not([data-theme="light"])` acima — inclusive
    `--surface`/`--surface-raised`/`--border-subtle` e os `--color-night-*` redeclarados
    (cópia literal, não um subconjunto; DEC-036-002). A leitura/gravação de `data-theme` em
    si é wiring de TASK-036-003/004, fora desta TASK.
- `mnemonicos-frontend/src/app/night-palette-tokens.ts`:
  - Novo export `NIGHT_PALETTE_SURFACE_ROLE_PAIRS: readonly NightPalettePanelLabelPair[]`
    (reusa a interface já existente `NightPalettePanelLabelPair`, `night-palette-tokens.ts:95-102`
    — `labelToken`/`background`/`minRatio`, resolução por indireção `var()`) com 2 entradas:
    (a) `--text-strong` vs `--color-night-panel-bg` — os MESMOS tokens que
    `NIGHT_PALETTE_PANEL_LABEL_PAIR` já mede (`night-palette-tokens.ts:111-116`; ~17,04:1 no
    tema claro, ~18,65:1 no escuro, comentado em `globals.css:51-55`/`125-129`) — nome distinto
    (ex.: `'texto do app (--text-strong) sobre --surface unificado'`) porque agora a alegação é
    sobre o app inteiro (AC-036-012), não só o painel de `/login`; (b) `--border-subtle` vs
    `--color-night-panel-bg` — par NOVO (a `NIGHT_PALETTE_CONTRAST_PAIRS` já mede
    `--color-night-pill-border` vs `--color-night-pill-bg`/`--color-night-panel-bg` por TOKEN,
    `night-palette-tokens.ts:52-57`/`78-82`, ~4,20:1 e ~4,70:1 no claro, ~5,13:1 e ~6,14:1 no
    escuro — mas nenhuma entrada hoje resolve a indireção `--border-subtle` por NOME
    semântico).
  - Exportar o contrato congelado que TASK-036-003/004 consomem: `THEME_STORAGE_KEY: string`
    (ex. `'mnemonicos:theme'`) e `export type ThemeName = 'light' | 'dark'` — símbolos NOVOS,
    declarados só aqui; as duas TASKs seguintes importam, nunca redeclaram (princípio 2 da
    decomposição, `commands/tasks.md` Etapa 1).

### Não inclui
- Script de bootstrap (TASK-036-003); `ThemeToggle` (TASK-036-004).
- Medição de `--link`/`--danger`/acento da paleta como *distinguibilidade decorativa* entre
  si (sem piso numérico declarado na SPEC) — fica para o gate 9/11, é a parte qualitativa de
  NFR-036-005/AC-036-018. O contraste AA NUMÉRICO de `--link`/`--danger` contra o novo
  `--surface` (NFR-036-003, que já se aplica a qualquer texto, incluindo esses dois) ENTRA
  nesta TASK (ver Critérios de pronto).
- Qualquer alteração de VALOR de `--text-strong`/`--text-muted`/`--danger`/`--link`
  (DEC-036-003).

## Critérios de pronto

- [ ] `--text-strong` vs `--surface` (novo valor) ≥ 4,5:1 e `--border-subtle` vs `--surface`
      ≥ 3:1, nos dois temas — cobre AC-036-012, NFR-036-003. Verificação executável:
      `npm --prefix mnemonicos-frontend test -- src/app/globals-theme-contrast.test.ts` →
      `PASS`, com um novo bloco `describe.each` no mesmo arquivo, no MESMO padrão já usado
      para `NIGHT_PALETTE_PANEL_LABEL_PAIR` (`globals-theme-contrast.test.ts:39-64`): tema
      claro resolve a indireção de `--text-strong`/`--border-subtle` em `baseRootBlock` e o
      hex em `themeBlock`, e a indireção de `--surface` em `baseRootBlock` com o hex também em
      `themeBlock`; tema escuro resolve as duas indireções em `darkBlock` com o hex também em
      `darkBlock` (`['tema escuro', darkBlock, darkBlock]`, já usado ali) — consumindo
      `NIGHT_PALETTE_SURFACE_ROLE_PAIRS` por nome (`findMeasuredPair`-like, nunca hex solto).
      Evidência da fixação (cálculo manual pela mesma fórmula de `theme-css-parser.ts:97-153`,
      a conferir na execução real): texto ~17,04:1 (claro) / ~18,65:1 (escuro); borda ~4,70:1
      (claro) / ~6,14:1 (escuro) — ambos acima do piso. Mutante: reverter `--border-subtle`
      para `var(--color-ink-200)` no `:root` claro faz a razão cair para bem abaixo de 3:1
      (`--color-ink-200` e `--color-night-panel-bg` são tons muito próximos em luminância) —
      reprova.
- [ ] Os três tokens (`--surface`, `--surface-raised`, `--border-subtle`) têm o MESMO valor
      em `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { ... } }` e
      em `:root[data-theme="dark"] { ... }` (DEC-036-002, prevenção da divergência que a
      própria decisão registra como risco). Verificação executável: `npm --prefix
      mnemonicos-frontend test -- src/app/globals-theme-contrast.test.ts -t "seletores
      escuros"` → `PASS`, com um teste que usa `extractCssBlock` (já genérico,
      `theme-css-parser.ts:18-36`, sem alteração no parser) com os marcadores literais
      `':root:not([data-theme=\"light\"])'` e `':root[data-theme=\"dark\"]'` e compara
      `readCssHexValue` dos 3 tokens entre os dois blocos. Mutante: mudar só o valor de
      `--surface` dentro de `:root[data-theme="dark"]` reprova a comparação.
- [ ] `THEME_STORAGE_KEY`/`ThemeName` exportados de `night-palette-tokens.ts` com valor
      exercitado (contrato sem AC próprio, fechamento "de trás para frente" — regra de
      cobertura, `commands/tasks.md` Etapa 3): mesmo arquivo de teste, caso que importa os
      dois símbolos e afirma `typeof THEME_STORAGE_KEY === 'string' && THEME_STORAGE_KEY.length
      > 0`.
- [ ] `--link` e `--danger` (valores atuais, intocados por DEC-036-003) mantêm ≥4,5:1 contra
      o novo `--surface` (`--color-night-panel-bg`) nos dois temas — cobre a fração numérica
      de AC-036-018/NFR-036-005 que NFR-036-003 já exige para qualquer texto. Verificação
      executável: mesmo arquivo `globals-theme-contrast.test.ts`, 2 novos pares (`--link` vs
      `--surface`, `--danger` vs `--surface`) no mesmo `describe.each` dos demais. Fixe o
      valor esperado calculando com a mesma fórmula de `theme-css-parser.ts:97-153` contra os
      hex REAIS de `--color-brand-400`/`--color-brand-600`/`--color-red-400`/
      `--color-red-700` (já declarados em `globals.css`) vs `--color-night-panel-bg` nos dois
      temas, ANTES de escrever o teste — se algum par não fechar 4,5:1, registre como achado
      real (não invente o número, meça e relate ao Tech Lead antes de prosseguir).
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff.

## Riscos específicos

- TRISK-036-002 (contraste de `--link`/`--danger` contra o novo `--surface`): a fração
  NUMÉRICA (NFR-036-003) passa a ser medida nesta TASK (ver Critérios de pronto); a fração
  qualitativa de distinguibilidade do acento (NFR-036-005) permanece para o gate 9/11, por
  decisão explícita de DEC-036-003.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-30T01:22:00-0300
**Data conclusão**: 2026-09-30T02:09:23-0300
**Commit SHA**: 53587b3
**Jira**: KAN-160

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (44/44 no arquivo; 658/658 na suíte)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (wave 1 — 1 retry, re-review do delta aprovado)
- [x] ACs verificados (AC-036-012, AC-036-018)
- [x] Segurança (gate 8): aprovado (wave 1) — security-engineer
- [ ] Comportamento (gate 9): n/a — FEAT-036-002 ainda não completou (aguarda TASK-036-003/004)
- [x] Design (gate 11): aprovado (wave 1) — product-designer, 1 retry (regressão real em technique-card.tsx corrigida)
