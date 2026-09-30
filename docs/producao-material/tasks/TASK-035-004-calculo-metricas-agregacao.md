# TASK-035-004: Cálculo de métricas por Conteúdo, prioridade de apresentação e agregação (funções puras)

**Slug**: producao-material
**Pertence a**: PLAN-035
**Realiza (FRs)**: FR-034-003, FR-034-004, FR-034-005, FR-034-006, FR-034-007, FR-034-008, FR-034-009, FR-034-010, FR-034-011, FR-034-012, FR-034-013, FR-034-020, FR-034-021, FR-034-022, FR-034-023, FR-034-024, FR-034-025, FR-034-026, FR-034-027, FR-034-028, FR-034-029, FR-034-030, FR-034-031, FR-034-032
**Funcionalidade**: FEAT-034-002 (primária, 21 FRs realizados), FEAT-034-001 (FR-034-003/020/021, mapa FR→FEAT posicional da SPEC §5 — estes 3 IDs caem sob o heading FEAT-034-001 embora a lógica pertença ao cálculo do Painel)
**Componente**: COMP-035-010 (principal), COMP-035-009, COMP-035-011, COMP-035-015
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-035-002
- **Bloqueia**: TASK-035-006

## Contexto

Núcleo de regra de negócio do Painel (princípio 8: regra de negócio central) — 2 funções
puras, sem I/O, que recebem tudo que a leitura em lote (TASK-035-005) já entregou em
memória e devolvem o payload inteiro calculado: tempo total/por página/por etapa/por etapa
por página, agregados por Módulo e fábrica, conclusão por Módulo, correções após revisão,
backlog com prioridade e ordenação. Território e precedentes:
`docs/producao-material/MAP.md`, `mnemonicos-backend/prisma/schema.prisma:48-50`
(`ProofRadarClass`, comentário DEC-006-009 nunca antes codificado), e PLAN-035 §1, §3
(COMP-035-009/010/011), §4 Fluxo 3/4, §6 (DEC-035-002/003/006/007/008/015/016).

**Prova do vertical slicing**: sem I/O, esta TASK prova sozinha, por teste unitário com
fixtures em memória (nenhum Postgres), cada FR/AC de FEAT-034-002 que a camada de cálculo
enforça — a leitura real (TASK-035-005) e a orquestração/rota (TASK-035-006) reusam estas
funções sem reabrir a regra.

## Escopo

### Inclui

- `mnemonicos-backend/src/domain/presentation-priority.ts` (novo, sem I/O):
  ```ts
  import type { ProofRadarClass } from './types';

  export type PresentationPriority = 'ALTA' | 'MEDIA' | 'BAIXA';

  /** Deriva a prioridade de apresentação do backlog (DEC-035-006, schema.prisma:48-50). */
  export function derivePresentationPriority(radarClass: ProofRadarClass): PresentationPriority {
    switch (radarClass) {
      case 'ALTA':
        return 'ALTA';
      case 'MEDIA':
        return 'MEDIA';
      case 'DETALHE':
      case 'EXCECAO':
      case 'PEGADINHA':
        return 'BAIXA';
    }
  }
  ```
- `mnemonicos-backend/src/modules/strategic-panel/strategic-panel-calculations.ts` (novo,
  sem I/O — importa `isVersionAltered` de `../content-versions/version-alteration.ts`,
  TASK-035-002, e `derivePresentationPriority` acima):
  - Tipos de entrada (nomes definitivos ficam a cargo do developer; a FORMA abaixo é
    contrato mínimo, decisão 4.307 — não copiar como gabarito, conferir contra os tipos
    reais que TASK-035-005 exporta antes de duplicar campo):
    ```ts
    export interface ContentMetricsInput {
      content: { id: string; radarClass: ProofRadarClass; disciplineName: string; topicName: string };
      /** Todos os eventos de etapa do Conteúdo, ordenados por `sequence asc` (as 8 etapas). */
      stageEvents: Array<{ stageType: ProductionStageType; transitionType: ProductionEventTransition; sequence: bigint; occurredAt: Date }>;
      /** Só Variante TIRA, ordenados por `occurredAt`/correlação já resolvida pelo chamador. */
      tiraPublications: Array<{ occurredAt: Date; pageCount: number | null }>;
      latestVersion: { closedAt: Date; approvedById: string | null; contentSnapshot: unknown } | null;
      /** Só presente quando `latestVersion.approvedById !== null` (TASK-035-005, 2º `IN`). */
      currentVersionedFields?: VersionedContentFields;
    }

    export interface ContentMetrics {
      contentId: string;
      disciplineName: string;
      topicName: string;
      /** `null` = "sem medida" (nunca 0). `reason` distingue os 2 motivos do FR-034-026/007. */
      totalTime: { ms: number; pageCount: number } | { reason: 'sem-medida' | 'sem-registro' };
      timePerPage: number | null;
      perStage: Record<ProductionStageType, StagePeriod>;
      reworkCountByStage: Partial<Record<ContentStageType, number>>;
      concluded: boolean;
      approvedButAltered: boolean;
      mostAdvancedStage: ProductionStageType | 'sem-registro';
      priority: PresentationPriority;
      ageMs: number | null;
    }

    export type StagePeriod =
      | { status: 'medido'; ms: number; msPerPage: number | null }
      | { status: 'em-aberto' | 'nao-percorrida' | 'sem-duracao-medida' };
    ```
  - `computeContentMetrics(now: Date, input: ContentMetricsInput): ContentMetrics` — por
    Conteúdo: (1) início registrado = 1º evento `CONTEUDO_BRUTO` por `sequence` mínima —
    ausente → tudo "sem registro" (FR-034-026/029); (2) Exportação de referência = entre
    os `PUBLICACAO_PDF` com `sequence` maior que a do 1º `VERSAO_EDITORIAL`, o de menor
    `sequence` cuja correlação (já resolvida pelo chamador em `tiraPublications`) existe —
    sem essa correlação ou sem `pageCount` nela → "sem medida" (FR-034-002/007/021/024);
    (3) tempo total = `occurredAt` da Exportação de referência − início registrado; tempo
    por página = tempo total ÷ `pageCount` (FR-034-004/005); (4) por etapa (das 8), do 1º
    ao último evento da etapa: "em aberto" (só `ABERTURA`), "não percorrida" (0 eventos),
    "sem duração medida" (evento sem abertura correspondente), ou o intervalo medido
    incluindo retrabalho (FR-034-006/022/023/024); tempo por etapa por página quando há
    tempo por página medido (FR-034-025); (5) correções após revisão: eventos `RETRABALHO`
    das 5 etapas de conteúdo com `sequence` maior que a do 1º `VERSAO_EDITORIAL`, contados
    por etapa (FR-034-010/031); (6) `concluded` = `latestVersion !== null &&
    latestVersion.approvedById !== null && !isVersionAltered(currentVersionedFields,
    latestVersion, latestTiraOccurredAt)` (COMP-035-008/TASK-035-002); `approvedButAltered`
    quando aprovada E alterada (FR-034-028); (7) `mostAdvancedStage` (ordem fixa,
    Publicação excluída, DEC-035-008) e `ageMs` = `now − início registrado`, ou
    `'sem-registro'`/`null` sem eventos (FR-034-027/029); `priority` via
    `derivePresentationPriority(content.radarClass)`.
  - `aggregateStrategicPanel(now: Date, metrics: ContentMetrics[]): StrategicPanelPayload`
    — agrupa por Módulo (`disciplineName`+`topicName`) e pela fábrica inteira: média,
    mediana, `n` (Conteúdos com tempo por página medido) e cobertura (`n` / ativos do
    recorte, FR-034-008); Conclusão por Módulo = ativos × Concluídos (FR-034-009);
    correções após revisão totalizadas por etapa por Conteúdo e por fábrica, sem somar
    etapas (FR-034-011/031); backlog = Conteúdos ativos não Concluídos, ordenado por
    prioridade (Alta→Média→Baixa) e, dentro dela, do mais antigo para o mais novo, com
    idade "sem medida" sempre depois de idade numérica na mesma prioridade
    (FR-034-012/013/030).
- `mnemonicos-backend/tests/unit/strategic-panel-calculations.test.ts` (novo) — 1 cenário
  por FR/AC, sem banco (fixtures de `stageEvents`/`tiraPublications` montadas à mão, sem
  os builders de `tests/support/` que dependem do Prisma):
  - AC-034-003/AC-034-024 (FR-034-003/020): 3 Exportações Tira (antes do fechamento, a 1ª
    depois, semanas depois) → usa a do MEIO; Exportações só da Variante Resumo (medidas)
    → "sem medida" — o predicado de correlação já filtra por Variante no chamador
    (TASK-035-005), então este teste usa `tiraPublications` vazio para o caso Resumo.
  - AC-034-004 (FR-034-004/005/020): início + Exportação de referência com `pageCount` →
    tempo total e tempo por página calculados por valor exato (não só "não nulo").
  - AC-034-005 (FR-034-006/025): etapa com abertura+retrabalho+conclusão → soma o
    intervalo INTEIRO (1º ao último evento, retrabalho incluso) + tempo por etapa por
    página.
  - AC-034-006 (FR-034-007): Conteúdo ativo sem Exportação Tira medida → `timePerPage:
    null`, nunca 0.
  - AC-034-007 (FR-034-008): média/mediana/n/cobertura de um Módulo com mix de
    medidos/não-medidos.
  - AC-034-008 parte cálculo (FR-034-009): Módulo com Concluídos e não-Concluídos →
    `ativos`/`concluidos` corretos; a legenda/exibição é da TASK-035-008.
  - AC-034-009 parte cálculo (FR-034-010/011/031): retrabalho de "Conteúdo bruto" com
    `sequence` MAIOR que o 1º `VERSAO_EDITORIAL` entra na contagem da etapa e no total da
    fábrica; retrabalho ANTERIOR ao fechamento não entra em nenhuma contagem (par
    coincidente — 2 casos, um por lado da fronteira de `sequence`).
  - AC-034-010/AC-034-020 (FR-034-012/013/027/030): 3 Conteúdos com prioridades
    Alta/Média/Baixa e idades diferentes → ordenação correta; 2 Conteúdos mesma
    prioridade, um com idade numérica e outro "sem medida" → o "sem medida" vem depois.
  - AC-034-011 **não** é desta TASK (soft-delete é filtro de leitura, TASK-035-005) — a
    função pura recebe só o que já foi filtrado; nenhum teste aqui monta um Conteúdo
    soft-deletado.
  - AC-034-018 parte cálculo (FR-034-009/012/028): Módulo com concluídos, sem aprovação e
    aprovados-e-alterados → `ativos = concluidos + itens do backlog`; o
    aprovado-e-alterado tem `approvedButAltered: true` e aparece no backlog (não em
    `concluded`).
  - AC-034-019 (FR-034-021): Exportação de referência sem `pageCount` + reexportação
    posterior COM `pageCount` → "sem medida" (a reexportação não é a de referência,
    `tiraPublications` do fixture inclui as 2, a de referência é a de menor `sequence`
    pós-fechamento).
  - AC-034-020 parte cálculo (FR-034-026/029/030): Conteúdo sem evento `CONTEUDO_BRUTO`
    (criado fora do fluxo instrumentado) → tudo "sem registro"/"sem medida" nomeado
    (nunca um valor numérico), etapa "sem registro" no backlog.
  - AC-034-021 (FR-034-022/023/024): 3 sub-casos na MESMA etapa de 3 Conteúdos distintos
    — abertura sem conclusão → `'em-aberto'`; 0 eventos → `'nao-percorrida'`; evento sem
    abertura correspondente → `'sem-duracao-medida'`. Nenhum dos 3 é `0`.
  - Predicado de conjunto/composto (lição ativa "Árvore de decisão com precedência: um
    caso por PAR de ramos que coincide" + "Predicado de conjunto composto por && exige um
    caso por EIXO"): backlog com 2 Conteúdos de MESMA prioridade — um mutante que troque
    o comparador de idade (`<` por `>`) tem de reprovar um caso próprio (não coberto pelo
    caso de prioridades diferentes, que nunca exercita o desempate).
- `mnemonicos-backend/tests/unit/presentation-priority.test.ts` (novo): as 5 classes de
  `ProofRadarClass` → 3 baldes, 1 caso por classe (`ALTA→ALTA`, `MEDIA→MEDIA`,
  `DETALHE|EXCECAO|PEGADINHA→BAIXA` — 3 casos para o balde BAIXA, não 1, decisão 4.286: o
  Given-When-Then de A-034-012 nomeia as 3 classes de origem).

### Não inclui

- Qualquer leitura de banco (`findMany`/`select`) — TASK-035-005.
- Orquestração (`buildStrategicPanel`), rota HTTP, prova de consultas constantes —
  TASK-035-006.
- Exibição na tela (legenda, marcador "aprovada, alterada depois", rótulos pt-BR dos
  estados) — TASK-035-008/009 do frontend.
- Filtro de soft-delete (AC-034-011) — já resolvido na leitura, TASK-035-005.

## Critérios de pronto

- [ ] Testes cobrem AC-034-003, AC-034-004, AC-034-005, AC-034-006, AC-034-007,
      AC-034-008 (parte cálculo), AC-034-009 (parte cálculo), AC-034-010, AC-034-018
      (parte cálculo), AC-034-019, AC-034-020, AC-034-021, AC-034-024 — verificação
      executável: `npm --prefix mnemonicos-backend test --
      strategic-panel-calculations.test.ts` → `OK (N tests)`. Fixada antes do código.
- [ ] `derivePresentationPriority` cobre as 5 classes (3 casos no balde BAIXA) —
      verificação executável: `npm --prefix mnemonicos-backend test --
      presentation-priority.test.ts` → `OK (5 tests)`.
- [ ] **Item (c) — fechamento contável do par coincidente**: contagem de correções após
      revisão (retrabalho antes/depois do fechamento) tem os 2 casos do PAR nomeados no
      relatório do Jest — mutante que troque `sequence > closureSequence` por `>=` (em
      `git worktree add`) reprova o caso "retrabalho no MESMO `sequence` do fechamento",
      se esse ramo existir; caso contrário, documentar por que `sequence` nunca colide
      (herda a garantia de `ProductionStageEvent.sequence` ser globalmente monotônica,
      autoincrement).
- [ ] **Item (g) — distinção do backlog por valor, não só por não-vazio**: o caso de
      desempate de idade dentro da mesma prioridade usa 2 valores de idade DISTINTOS e
      asserta a ORDEM exata do array resultante (`[maisAntigo, maisNovo]`), nunca só
      `toHaveLength(2)`.
- [ ] Nenhum caminho de `computeContentMetrics`/`aggregateStrategicPanel` retorna `0`
      para um cenário "sem medida"/"sem registro"/"em aberto"/"não percorrida"/"sem
      duração medida" — grep de ausência sobre o arquivo de produção: `grep -nE "return
      0|: 0[,}]" mnemonicos-backend/src/modules/strategic-panel/
      strategic-panel-calculations.ts | grep -vE ':\s*(//|\*)' | grep -v "n: 0\|ativos:
      0\|concluidos: 0"` (a 1ª exclusão descarta comentário/docblock que mencione a forma
      textual sem ser código real; contagens agregadas legitimamente podem ser 0 —
      `n`/`ativos`/`concluidos` de um recorte vazio; valores de TEMPO/IDADE individuais
      nunca podem) → 0 ocorrências fora da allowlist.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`) — `npm --prefix mnemonicos-backend run lint`
      → exit 0.
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-035-003 (PLAN §8) — esta TASK só calcula; o custo de I/O que alimenta o cálculo
  (2 consultas `IN` extras só para aprovados) é medido na TASK-035-006 (gate 10).
- Comportamento idêntico depende de TASK-035-002 já ter congelado `isVersionAltered` —
  qualquer mudança de assinatura nela exige revisitar esta TASK antes do merge (nenhuma
  cópia local do predicado é aceitável, DEC-035-015).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-171

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
