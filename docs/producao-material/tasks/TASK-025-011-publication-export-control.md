# TASK-025-011: Componente client reusável `publication-export-control.tsx`

**Slug**: producao-material
**Pertence a**: PLAN-025
**Realiza (FRs)**: FR-024-007, FR-024-008, FR-024-012
**Componente**: COMP-025-011 (principal)
**Wave**: 6
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

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
- [ ] **[Pendência herdada de TASK-025-010, gate 1]** `filename === ''` (o backend nunca
      emite `Content-Disposition` sem filename, mas o parser de TASK-025-010 devolve `''`
      se o header vier ausente por algum motivo) — este componente é o PRIMEIRO consumidor
      real do campo `filename`. Decida e teste explicitamente: `<a download={filename}>`
      com `filename=''` faz o browser escolher o nome do arquivo (comportamento nativo,
      não um bug) — se isso for aceitável, um teste próprio confirma que o componente não
      quebra/trava nesse caso (mesmo spy de `createObjectURL`, `filename` vazio passado ao
      `download`); se não for aceitável, trate como caso de falha (mesmo `role="alert"` do
      critério acima) antes de disparar o download.

## Riscos específicos

- `jest-environment-jsdom` não implementa `URL.createObjectURL`/`URL.revokeObjectURL`
  nativamente — o teste precisa instalar o spy/stub antes de montar o componente (mesma
  classe de ajuste que `test/jsdom-fetch-env.js` já faz para `fetch`/`Request`/`Response`,
  mas por spy local ao arquivo de teste desta TASK, não pelo ambiente compartilhado — os
  demais componentes que usam `jsdom-fetch-env.js` não precisam de `createObjectURL`).
- **[Pendência herdada de TASK-025-010]** guardar o `Blob` no cache da mutation RTK Query
  dispara `console.error` do `serializableStateInvariantMiddleware` ("non-serializable
  value") a cada exportação — ruído de dev conhecido (DEC-025-006: mutation com blob como
  `data`), não falha teste nem build. NÃO tente silenciar mexendo em
  `src/store/index.ts`/`getDefaultMiddleware` (fora do escopo desta TASK, afeta a store
  inteira) — se o ruído incomodar nos seus próprios testes, use `unwrap()` no trigger da
  mutation (`const { blob, filename } = await exportPublication(args).unwrap()`) para
  consumir o resultado diretamente sem depender de ler `data` do cache/seletor — isso não
  elimina o warning (o RTK ainda grava no cache internamente), só evita que o SEU código
  dependa da leitura via seletor. Aceitar o console.error como conhecido é a decisão
  padrão; não é bloqueante.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-14T20:46:47-0300
**Data conclusão**: 2026-09-14T21:12:55-0300
**Commit SHA**: db1a3e4 (implementação) · a66e7da (retry — gate 11: estado de sucesso in-page)
**Jira**: KAN-118

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (Wave 6)
- [x] ACs verificados
- [x] Segurança (gate 8): n/a — sem superfície sensível (componente client puro, sem auth/injeção nova)
- [x] Comportamento (gate 9): pendente_handoff — `qa` tentou exercitar de verdade (app real, login EDITOR real, Conteúdo bruto+Quebra real criados): achou 2 bloqueios reais, não ambientais — (1) migração `20260914175940_add_publicacao_pdf_publication_event` não aplicada no Postgres de dev (POST /contents/:id/publication → 500 nas 2 Variantes; autorização de aplicação é ato do Diretor, não decidida por mim); (2) o componente ainda não está enxertado em nenhuma tela (TASK-025-012/013, Wave 7, ainda não implementadas). **Consolidado na Etapa 4 (DoD)**: com os 2 enxertos da Wave 7 no ar, `qa` tentou de novo e achou (1) ainda pendente + (2) NOVO — pool de compilação do Turbopack do frontend quebrado (RISK-025-005, fix commitado `3115fec`, processo precisa reiniciar). Roteiro de re-verificação em `docs/producao-material/handoffs/HANDOFF-PLAN-025.md`.
<!-- Branch, tentativas, arquivos, revisores e narrativa (retries, escalações) vivem no
ledger da sessão e no commit da closure (4.76) — não se repetem aqui (4.409). -->
