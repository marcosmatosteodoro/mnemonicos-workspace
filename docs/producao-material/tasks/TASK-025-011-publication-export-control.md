# TASK-025-011: Componente client reusável `publication-export-control.tsx`

**Slug**: producao-material
**Pertence a**: PLAN-025
**Realiza (FRs)**: FR-024-007, FR-024-008, FR-024-012
**Componente**: COMP-025-011 (principal)
**Wave**: 6
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-025-010
- **Bloqueia**: TASK-025-012, TASK-025-013

## Contexto

`PublicationExportControl` é o único componente que sabe disparar `exportPublication`
(TASK-025-010) e reagir aos 3 estados observáveis por ação (em andamento, sucesso, falha) —
as duas telas de enxerto (TASK-025-012/013) só o instanciam, nunca duplicam lógica de
download. Cobertura: FR-024-007/FR-024-012 aqui são a base do próprio controle (o
acionamento a partir de cada tela específica é das TASKs de enxerto); FR-024-008 aqui é o
consumo do `filename` já extraído por TASK-025-010 no nome do arquivo baixado.

## Escopo

### Inclui

- `mnemonicos-frontend/src/components/publication-export-control.tsx`: `'use client'`; 2
  controles — um por Variante (`PUBLICATION_VARIANT_LABELS`, TASK-025-002); prop
  `rawContentId: string`.
- 3 estados observáveis por controle/Variante acionada (FR-024-007/AC-024-006):
  - **Em andamento**: o controle daquela Variante fica desabilitado, com indicador visível
    (`role="status"`, mesmo padrão `aria-live="polite"` já usado no repo).
  - **Sucesso**: `URL.createObjectURL(blob)` → `<a download={filename} href={url}>` clicado
    programaticamente → `URL.revokeObjectURL(url)` chamado depois do clique.
  - **Falha**: mensagem de erro visível (`role="alert"`), sem apagar qual Variante estava
    sendo exportada (a Variante que falhou continua identificável no controle — nenhum
    reset que a esqueça, AC-024-006).
- Cor semântica da mensagem de falha via token do tema (`text-danger`/`--danger` de
  `globals.css`), nunca `text-red-*` literal (lição ativa "[Design] Cor semântica de texto
  vem de token do tema").

### Não inclui

- Os 2 pontos de enxerto nas telas (`content-form.tsx` — TASK-025-012;
  `mnemonic-strip-board.tsx` — TASK-025-013).

## Critérios de pronto

- [ ] **Testes cobrem AC-024-006** (3 estados observáveis por ação de exportação) —
      verificação executável: novo `mnemonicos-frontend/src/components/publication-export-control.test.tsx`
      (`@jest-environment <rootDir>/test/jsdom-fetch-env.js`, componente MONTADO contra
      `makeStore()` + `Provider` + `fetch` mockado — lição ativa "[Testes] Predicado de
      decisão de UI a partir de estado de RTK Query só se prova no componente montado"),
      comando `npx jest --runTestsByPath src/components/publication-export-control.test.tsx`
      (cwd `mnemonicos-frontend`) → `PASS`. Cenários, um por estado: (a) resposta represada
      (técnica de interceptação de rede, decisão 4.319) → o controle da Variante acionada
      fica desabilitado com o indicador visível; (b) resposta resolvida com `Response`
      `application/pdf` + `Content-Disposition` → o download é disparado (ver critério de
      `revokeObjectURL` abaixo); (c) resposta de erro (`application/json`, status ≥400) → a
      mensagem de erro aparece com `role="alert"`, e a Variante acionada continua
      identificável no controle (nenhum estado que a apague).
- [ ] `URL.revokeObjectURL` é chamado **depois** do clique programático no `<a download>`
      (sem vazar memória do `blob`) — mesmo arquivo/comando acima → `PASS`. Verificação: spy
      em `URL.createObjectURL`/`URL.revokeObjectURL` (jsdom não implementa nativamente —
      instalar o spy/stub no próprio arquivo de teste antes de montar o componente); ordem
      de chamada confirmada (`createObjectURL` → clique → `revokeObjectURL`).
- [ ] Cor semântica: `grep -nE "text-(red|green|blue|yellow|orange|purple|pink)-[0-9]"
      src/components/publication-export-control.tsx` (cwd `mnemonicos-frontend`) → esperado
      vazio.
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git diff --name-only
      main...HEAD`) — verificação executável: `npx eslint
      src/components/publication-export-control.tsx
      src/components/publication-export-control.test.tsx` (cwd `mnemonicos-frontend`) → 0
      problemas.

## Riscos específicos

- `jest-environment-jsdom` não implementa `URL.createObjectURL`/`URL.revokeObjectURL`
  nativamente — o teste precisa instalar o spy/stub antes de montar o componente (mesma
  classe de ajuste que `test/jsdom-fetch-env.js` já faz para `fetch`/`Request`/`Response`,
  mas por spy local ao arquivo de teste desta TASK, não pelo ambiente compartilhado — os
  demais componentes que usam `jsdom-fetch-env.js` não precisam de `createObjectURL`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-118

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
<!-- Branch, tentativas, arquivos, revisores e narrativa (retries, escalações) vivem no
ledger da sessão e no commit da closure (4.76) — não se repetem aqui (4.409). -->
