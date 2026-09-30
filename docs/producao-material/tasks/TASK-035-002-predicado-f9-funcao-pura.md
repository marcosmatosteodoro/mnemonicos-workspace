# TASK-035-002: Predicado único de F9 extraído para função pura (`isVersionAltered`)

**Slug**: producao-material
**Pertence a**: PLAN-035
**Realiza (FRs)**: nenhuma
**Componente**: COMP-035-008
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: refactor
**Status**: Done

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-035-004

## Contexto

Extração sem mudança de comportamento (DEC-035-015): `resolveAlterationSignal` (F9,
`content-versions.service.ts`) já é o único ponto de decisão de "alterado pós-fechamento"
para 3 usos (`approveContentVersion`, `listContentVersions`, `resolveVersionStampForPdf`);
o Painel (TASK-035-004) precisa da MESMA decisão para N Conteúdos de uma vez, em memória,
sobre dados já lidos em lote — vira o 4º uso da mesma regra, nunca uma cópia (MAP F9:
"mudar a regra é mudar os 3 usos juntos", o Painel se torna o 4º). Território e
precedentes: `docs/producao-material/MAP.md` §"Controle de qualidade e gate de Versão
aprovada (F9 · PLAN-033)`,
`mnemonicos-backend/src/modules/content-versions/content-versions.service.ts` (leitura
direta confirmada — `resolveAlterationSignal`, linhas 291-308) e
`versioned-content-diff.ts` (`hasVersionedContentChanged`, `toVersionedContentFields`), e
PLAN-035 §3 (COMP-035-008), §6 (DEC-035-015).

**Lição ativa cruzada** (`guarda-de-ordem-entre-transacoes-concorrentes-ordena-por-valor-atribuido-depois-do-lock`,
paths incluem `content-versions/**`): esta extração NÃO introduz nenhuma guarda nova nem
muda o eixo de ordenação — a comparação continua sendo `sequence` (via
`ProductionStageEvent.findFirst` ordenado por `sequence desc`), nunca `lastEditedAt`/
relógio de aplicação. O critério abaixo confirma que a extração preserva esse eixo.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/content-versions/version-alteration.ts` (novo arquivo,
  sem I/O):
  ```ts
  import type { VersionedContentFields } from './versioned-content-diff';
  import { hasVersionedContentChanged } from './versioned-content-diff';

  /**
   * Predicado único de "alterado pós-fechamento" (COMP-035-008, DEC-035-015) — combina
   * CONTEÚDO (`hasVersionedContentChanged`, curto-circuito) com TIRA (comparação de
   * `sequence`, resolvida pelo CHAMADOR — esta função só recebe o instante já escolhido,
   * nunca decide a query). Comportamento idêntico ao antigo corpo de
   * `resolveAlterationSignal` (F9) — mesmos 2 predicados, mesma ordem de curto-circuito.
   */
  export function isVersionAltered(
    current: VersionedContentFields,
    version: { contentSnapshot: unknown; closedAt: Date },
    latestTiraOccurredAt: Date | null,
  ): boolean {
    if (hasVersionedContentChanged(current, version.contentSnapshot as VersionedContentFields)) {
      return true;
    }
    return latestTiraOccurredAt !== null && latestTiraOccurredAt > version.closedAt;
  }
  ```
- `mnemonicos-backend/src/modules/content-versions/content-versions.service.ts`:
  `resolveAlterationSignal` (linhas 291-308) passa a só LER (o `findFirst` de
  `TIRA_MNEMONICA` por `sequence desc`, intocado) e delegar a decisão:
  ```ts
  export async function resolveAlterationSignal(
    rawContentId: string,
    current: VersionedContentFields,
    version: { contentSnapshot: unknown; closedAt: Date },
    db: Pick<typeof prisma, 'productionStageEvent'>,
  ): Promise<boolean> {
    const latestTiraEvent = await db.productionStageEvent.findFirst({
      where: { rawContentId, stageType: 'TIRA_MNEMONICA' },
      orderBy: { sequence: 'desc' },
      select: { occurredAt: true },
    });
    return isVersionAltered(current, version, latestTiraEvent?.occurredAt ?? null);
  }
  ```
  Import novo: `isVersionAltered` de `./version-alteration`. Assinatura pública de
  `resolveAlterationSignal` (parâmetros, retorno) **não muda** — os 3 chamadores
  existentes (`approveContentVersion`, `listContentVersions`,
  `resolveVersionStampForPdf` em `publication.service.ts`) continuam intocados.
- `mnemonicos-backend/tests/unit/version-alteration.test.ts` (novo): testes puros, sem
  banco — 1 cenário por combinação: (a) conteúdo alterado, Tira nunca reexportada
  (`latestTiraOccurredAt: null`) → `true` (curto-circuito, nunca consulta o 2º predicado);
  (b) conteúdo intacto, `latestTiraOccurredAt` depois de `closedAt` → `true`; (c) conteúdo
  intacto, `latestTiraOccurredAt` antes de `closedAt` → `false`; (d) conteúdo intacto,
  `latestTiraOccurredAt: null` → `false`; (e) fronteira — `latestTiraOccurredAt ===
  closedAt` (mesmo instante) → `false` (comparação estrita `>`, nunca `>=`, mesmo
  comportamento do corpo original).
- `mnemonicos-backend/tests/integration/content-versions.service.integration.test.ts`
  (não editado — suíte de regressão): os testes de F9 já existentes que exercitam
  `resolveAlterationSignal`/`approveContentVersion`/`listContentVersions` continuam verdes
  **sem alteração de asserção** (não-regressão, decisão 4.282) — a extração é comportamento
  idêntico, não um comportamento novo a testar de novo.

### Não inclui

- Qualquer uso do Painel sobre `isVersionAltered` — TASK-035-004 (o Painel chama a função
  por Conteúdo, em memória, sobre dados já lidos em lote pela TASK-035-005).
- Mudança de comportamento de `approveContentVersion`/`listContentVersions`/
  `resolveVersionStampForPdf` — nenhuma linha do corpo desses 3 muda.

## Critérios de pronto

- [ ] `isVersionAltered` cobre os 5 cenários (a-e) — verificação executável: `npm --prefix
      mnemonicos-backend test -- version-alteration.test.ts` → `OK (5 tests)`. Fixada
      antes do código.
- [ ] **Comportamento observável idêntico** (identidade do refactor — decisão 4.300/4.307,
      a extração não muda NADA que os 3 chamadores de F9 já em produção observam): a
      suíte de F9 completa — unidade + integração — roda ANTES do código e a contagem/
      resultado são capturados como baseline: `npm --prefix mnemonicos-backend test --
      content-versions.service.guard-order.test.ts && npm --prefix mnemonicos-backend run
      test:integration -- --testPathPatterns=content-versions.service.integration.test.ts`
      → baseline anotado (ex.: `OK (M tests)` unit + `OK (N tests)` integration). Rodada
      de novo DEPOIS do código: mesma contagem, 100% verde nos dois momentos — qualquer
      teste vermelho ou contagem divergente é a extração vazando comportamento, não
      "detalhe de refactor". Mutante de identidade: em `git worktree add` (nunca na árvore
      principal), trocar `latestTiraOccurredAt > version.closedAt` por `>=` dentro de
      `version-alteration.ts` derruba ao menos 1 teste da suíte de F9 acima (o cenário (e)
      do teste unitário de `isVersionAltered` + a suíte de integração que exercita
      `resolveAlterationSignal`/`approveContentVersion`/`listContentVersions`) — prova que
      o comportamento externo de F9 depende de fato do predicado extraído, nunca
      decorativo.
- [ ] **Não-regressão de F9** (decisão 4.282 — não se prova por "asserção não muda", mas
      pelo mutante): a suíte de F9 (`content-versions.service.integration.test.ts` +
      `content-versions.service.guard-order.test.ts`) continua 100% verde, e um mutante
      que troque a comparação `latestTiraOccurredAt > version.closedAt` por `>=` dentro de
      `version-alteration.ts` (aplicado em `git worktree add`, nunca na árvore principal)
      derruba o cenário (e) do teste unitário acima — prova que a extração preserva o
      eixo estrito. Verificação executável: `npm --prefix mnemonicos-backend run
      test:integration -- --testPathPatterns=content-versions.service.integration.test.ts`
      → `OK (N tests)`, mesma contagem de testes do commit-pai (`git diff --stat
      main...HEAD -- mnemonicos-backend/tests/integration/content-versions.service.integration.test.ts`
      → vazio, nenhuma linha de teste tocada).
- [ ] Assinatura pública de `resolveAlterationSignal` intocada — verificação: `grep -n
      "^export async function resolveAlterationSignal" mnemonicos-backend/src/modules/
      content-versions/content-versions.service.ts` (raiz do workspace, âncora em início
      de linha) confere os 4 parâmetros na mesma ordem/tipo do commit-pai
      (`git show main:mnemonicos-backend/src/modules/content-versions/content-versions.service.ts
      | grep -n "^export async function resolveAlterationSignal"`).
- [ ] Eixo de ordenação preservado (lição cruzada acima): `grep -n "orderBy.*sequence"
      mnemonicos-backend/src/modules/content-versions/content-versions.service.ts | grep
      -vE ':\s*(//|\*)'` → ao menos 1 ocorrência fora de comentário, dentro de
      `resolveAlterationSignal` — nenhuma comparação por `lastEditedAt`/`new Date()` foi
      introduzida no lugar.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`) — `npm --prefix mnemonicos-backend run lint`
      → exit 0.
- [ ] Code review aprovado (foco: comparação linha a linha do corpo extraído contra o
      original, decisão 4.307).

## Riscos específicos

- Reabrir se (herdado de DEC-035-015): uma mudança futura em `isVersionAltered` sem
  atualizar os 4 usos (3 de F9 + o Painel, TASK-035-004) reintroduz a duplicação que esta
  TASK elimina — nenhuma mitigação de código além do comentário no próprio arquivo
  apontando os 4 consumidores.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-30T03:36:39-0300
**Data conclusão**: 2026-09-30T03:45:01-0300
**Commit SHA**: b0bc835 (impl) · 6b9d0ba (remoção de comentário, gate 7)
**Jira**: KAN-169

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado — security-engineer (wave 1)
- [x] Comportamento (gate 9): n/a — refactor sem efeito observável (suíte F9 idêntica antes/depois)
