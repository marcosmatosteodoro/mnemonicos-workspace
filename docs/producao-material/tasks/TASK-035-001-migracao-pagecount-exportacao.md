# TASK-035-001: Migração `pageCount` + contagem fail-safe + registro na Exportação

**Slug**: producao-material
**Pertence a**: PLAN-035
**Realiza (FRs)**: FR-034-001, FR-034-002, FR-034-019, FR-034-021
**Funcionalidade**: FEAT-034-001 (primária)
**Componente**: COMP-035-001 (principal), COMP-035-002, COMP-035-003
**Wave**: 1
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-035-005

## Contexto

**Fatia sensível** (princípio 8: migração de schema + mudança de assinatura numa função
já em produção, `mergeSupplementaryPages`/`composePublicationBuffer`) — a Exportação passa
a registrar o número de páginas do documento PDF final (principal + suplementar já
fundidos), contado no ponto em que esse documento existe em memória, sem nunca falhar a
entrega por causa da contagem. Território e precedentes:
`docs/producao-material/MAP.md` §"Publicação — pipeline de PDF (F6 · PLAN-025)",
`mnemonicos-backend/src/modules/publication/publication.service.ts` (leitura direta
confirmada — `mergeSupplementaryPages` linhas 354-371, `exportPublication` linhas 422-474),
e PLAN-035 §1, §3 (COMP-035-001/002/003), §4 Fluxo 1, §6 (DEC-035-011/012).

**Prova do vertical slicing**: esta TASK, sozinha, prova via HTTP real (rota já montada de
F6) que uma Exportação em qualquer Variante grava a contagem de páginas e que uma falha na
contagem não impede a entrega — o ponto de entrada (a rota `POST /contents/:id/publication`)
já existe e não muda; só o efeito colateral de gravação ganha um campo novo.

## Escopo

### Inclui

- `mnemonicos-backend/prisma/schema.prisma`:
  - `model PublicationEvent` (linhas 540-548) ganha, ao final, forma literal do PLAN-035 §5:
    ```prisma
    /// NOVO (F10, DEC-035-011): número de páginas do documento PDF FINAL (principal +
    /// suplementar já fundidos) desta Exportação. `null` = sem medida — Exportação
    /// anterior a esta capacidade, ou falha na contagem (FR-034-019). Nunca recomputado
    /// por reexportação futura (FR-034-002/021).
    pageCount Int?
    ```
    Nenhuma coluna/índice/relação nova além desta — sem `sequence` própria nesta tabela
    (DEC-035-011: a ordem de uma Exportação vem do `ProductionStageEvent` irmão, casado por
    `(rawContentId, occurredAt)` idênticos, já garantido desde F6).
- Migração Prisma nova via `prisma migrate dev --create-only` — 1 diretório novo em
  `prisma/migrations/`: só `ALTER TABLE "publication_events" ADD COLUMN "pageCount"
  INTEGER` (nullable, sem `DEFAULT`, sem `DROP`/`ALTER COLUMN` destrutivo). **Aplicar exige
  autorização do Diretor** (mesmo protocolo de TASK-029-001/TASK-033-001 — A-034-004 já
  autoriza para dev/teste; produção segue pelo deploy) — passo explícito do
  `/keelson:implement` (`AskUserQuestion`), nunca aplicado em produção por esta TASK.
- `mnemonicos-backend/src/modules/publication/publication.service.ts`:
  - Nova função pura de I/O mínima, logo acima de `mergeSupplementaryPages` (linha 354):
    ```ts
    /**
     * COMP-035-002: contagem fail-safe (FR-034-019/DEC-035-012) — só a chamada de
     * contagem em si entra no try/catch; falha loga (sem texto de conteúdo, só
     * `rawContentId`) e devolve `null`, nunca aborta a composição.
     */
    function countPagesForExport(doc: PDFDocument, rawContentId: string): number | null {
      try {
        return doc.getPageCount();
      } catch (error) {
        logger.warn({ rawContentId, err: error }, 'Falha ao contar páginas na Exportação');
        return null;
      }
    }
    ```
  - `mergeSupplementaryPages` (linhas 354-371) ganha o parâmetro `rawContentId: string` e
    passa a devolver `{ buffer: Buffer; pageCount: number | null }` — a contagem roda
    **depois** de `copyPages`/`addPage` (documento final já fundido, inclui as páginas
    suplementares — A-034-001) e **antes** de `.save()`:
    ```ts
    async function mergeSupplementaryPages(
      rawContentId: string,
      primaryBuffer: Buffer,
      supplementaryBuffer: Buffer,
    ): Promise<{ buffer: Buffer; pageCount: number | null }> {
      const primaryDoc = await PDFDocument.load(primaryBuffer);
      const supplementaryDoc = await PDFDocument.load(supplementaryBuffer);

      const copiedPages = await primaryDoc.copyPages(
        supplementaryDoc,
        supplementaryDoc.getPageIndices(),
      );
      for (const page of copiedPages) {
        primaryDoc.addPage(page);
      }

      const pageCount = countPagesForExport(primaryDoc, rawContentId);
      const bytes = await primaryDoc.save();
      return { buffer: Buffer.from(bytes), pageCount };
    }
    ```
  - `composePublicationBuffer` (linhas 382-399) propaga a tupla — assinatura de retorno
    passa de `Promise<Buffer>` para `Promise<{ buffer: Buffer; pageCount: number | null }>`;
    chama `mergeSupplementaryPages(rawContentId, primaryBuffer, supplementaryBuffer)` no
    lugar da chamada atual de 2 argumentos.
  - `exportPublication` (linhas 422-474): a variável `buffer` do passo 3/4 vira
    `{ buffer, pageCount }` (desestruturado de `withDeadline(composePublicationBuffer(...))`
    — `withDeadline` é genérica, `<T>`, não precisa mudar); o `tx.publicationEvent.create`
    do passo 6 ganha `pageCount` no `data`:
    ```ts
    await tx.publicationEvent.create({
      data: { rawContentId, variant: input.variant, occurredAt: now, pageCount },
    });
    ```
    `PublicationResult` (interface, linhas 43-46) e o `return { buffer, filename }` final
    não mudam — `pageCount` é gravado, nunca devolvido ao cliente HTTP desta rota
    (FR-034-021: quem lê a contagem é o Painel, F10, não a resposta da Exportação).
- `mnemonicos-backend/tests/integration/publication.service.integration.test.ts` (estende —
  molde dos `describe` já existentes no mesmo arquivo, ex. linha 315 "sucesso grava 1
  evento genérico..."):
  - `describe('exportPublication — grava pageCount do documento FINAL (principal + suplementar) em ambas as Variantes (AC-034-001, FR-034-001)')`:
    2 casos (`TIRA`, `RESUMO`) — após `exportPublication`, ler `testPrisma.publicationEvent`
    e confirmar `pageCount` igual ao `PDFDocument.load(result.buffer).then((d) =>
    d.getPageCount())` do documento REAL devolvido ao cliente (nunca um número fixo
    hard-coded — o documento suplementar varia com Contraste/Flashcard/Pegadinha do
    fixture).
  - `describe('exportPublication — falha na contagem não impede a entrega nem falha a Exportação (AC-034-022, FR-034-019)')`:
    `jest.spyOn(PDFDocument.prototype, 'getPageCount').mockImplementationOnce(() => { throw new Error('boom'); })`
    (mocka só a 1ª chamada — a de `countPagesForExport`; chamadas anteriores do próprio
    pipeline, se houver, usam a implementação real) → `exportPublication` resolve
    normalmente, `result.buffer` é um PDF válido (`PDFDocument.load` não lança),
    `PublicationEvent.pageCount` gravado é `null`. Controle negativo: sem o mock, o mesmo
    fluxo grava um `pageCount` numérico (já provado no describe acima).
  - `describe('exportPublication — reexportação da mesma Variante não altera pageCount de eventos anteriores (FR-034-002/021)')`:
    2 exportações sucessivas do mesmo `rawContentId`/Variante → 2 linhas de
    `PublicationEvent`, cada uma com seu próprio `pageCount` no momento em que foi criada
    (nenhum `UPDATE` retroativo — grep de ausência, ver Critérios).
- `mnemonicos-backend/tests/unit/publication-event-prisma-types.test-d.ts` (molde já
  existe — arquivo de tipos gerados): confirmar que `Prisma.PublicationEventCreateInput`
  aceita `pageCount` opcional (checagem de tipo, sem novo `it()` se o arquivo já é
  genérico; se for `.test-d.ts` de asserção estática, acrescentar 1 caso).

### Não inclui

- Qualquer leitura/agregação do `pageCount` fora desta gravação — módulo `strategic-panel`
  inteiro é TASK-035-005/006.
- Aplicação da migração em produção.
- Mudança de contrato HTTP de `POST /contents/:id/publication` (a rota continua devolvendo
  só o binário — `pageCount` nunca aparece na resposta desta rota).

## Critérios de pronto

- [ ] Schema contém a coluna nova — verificação executável:
      `npm --prefix mnemonicos-backend run db:generate` → exit 0; leitura confirmando
      nulabilidade e ausência de `@default`: `sed -n '/^model PublicationEvent {/,/^}/p'
      mnemonicos-backend/prisma/schema.prisma | grep -E '^\s*pageCount Int\?'` (a partir da
      raiz do workspace, âncora em início de linha — exclui o docblock `///` acima do
      campo, que não repete a forma literal `pageCount Int?`) → 1 ocorrência, fixada antes
      do código.
- [ ] Migração é só `ADD COLUMN` nullable — verificação: leitura do `migration.sql` gerado;
      falsificável — qualquer `DROP`/`ALTER COLUMN`/`NOT NULL` presente reprova o critério.
- [ ] Testes cobrem AC-034-001, AC-034-002, AC-034-019, AC-034-022 —
      verificação executável: `npm --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=publication.service.integration.test.ts` → `OK (N tests)`, com os
      3 novos `describe` acima nomeados no relatório do Jest.
      - AC-034-002 (Exportação anterior a esta capacidade → "sem medida"): fixture que
        cria um `PublicationEvent` **direto no Prisma** com `pageCount` ausente (simula um
        registro nascido antes da migração ter dado seu primeiro valor) e confirma leitura
        `pageCount: null` — nenhum código desta TASK reescreve linhas antigas.
- [ ] **Item (a) — literal contra a fonte**: a mensagem de log
      (`'Falha ao contar páginas na Exportação'`) e a chave `rawContentId` (nunca texto de
      `rawText`/`concept`/Contraste/Pegadinha) são conferidas por leitura do `logger.warn`
      no diff — nenhum outro campo do Conteúdo entra no objeto de log.
- [ ] **Item (b) — estrutura, não grep de texto**: o `try/catch` de `countPagesForExport`
      envolve **só** a chamada `doc.getPageCount()` — nunca a composição do PDF em si
      (passos anteriores de `composePublicationBuffer` continuam propagando exceção
      normalmente, DEC-035-012). Verificação: teste de "falha do motor de composição
      propaga e não grava nada" já existente no mesmo arquivo (linha 275, molde de
      F6) continua verde **sem** alteração de asserção — outra classe de falha (ex.:
      `buildStripPdf` rejeitando) não é capturada pelo `try/catch` novo.
- [ ] **Ausência de recomputo retroativo (FR-034-002/021)**: `grep -rn
      "publicationEvent\.(update|updateMany)" mnemonicos-backend/src | grep -vE
      ':\s*(//|\*)'` (raiz do workspace) → 0 ocorrências — nenhuma função do `src` altera
      um `PublicationEvent` já gravado.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`), produção e teste — `npm --prefix
      mnemonicos-backend run lint` → exit 0.
- [ ] `npm --prefix mnemonicos-backend run test:integration --
      --testPathPatterns=publication.routes.integration.test.ts` → `OK (N tests)` — a
      camada HTTP (binário, `Content-Disposition`) segue idêntica, sem `pageCount` na
      resposta.
- [ ] Aderência à stack/perfil `node-22.md`: mudança de assinatura interna
      (`mergeSupplementaryPages`/`composePublicationBuffer`) documentada em comentário no
      próprio código (por que ganhou parâmetro/retorno novo), `AppError` continua sendo o
      único canal de erro previsto (nenhum novo lançado por esta TASK).
- [ ] Segurança (gate 8): `security-engineer` revisa o diff — fatia sensível (migração +
      mudança de assinatura numa função de produção já usada por 2 Variantes).
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-035-002 (PLAN §8) — a correlação Exportação × evento de etapa (consumida por
  TASK-035-005) depende de `PublicationEvent.occurredAt` nunca colidir com o
  `ProductionStageEvent{PUBLICACAO_PDF}` irmão — nenhuma mudança desta TASK toca
  `occurredAt`/a ordem de gravação dentro da `$transaction` de `exportPublication`.
- `ALTER TABLE ... ADD COLUMN` nullable sem `DEFAULT` é seguro sob volume atual (poucas
  linhas) — sem lock prolongado esperado; não medido nesta TASK (Art. 8, sem dor
  demonstrável).
- Autorização do Diretor para aplicar a migração é ato humano fora desta TASK — o
  `/keelson:implement` escala via `AskUserQuestion` antes do 1º passo que aplica.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-168

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
