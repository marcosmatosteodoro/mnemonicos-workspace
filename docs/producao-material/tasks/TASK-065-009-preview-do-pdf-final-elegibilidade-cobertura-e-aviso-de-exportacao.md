# TASK-065-009: Preview do PDF final: elegibilidade, cobertura N/M e Aviso de exportação

**Slug**: producao-material
**Pertence a**: PLAN-065
**Realiza (FRs)**: FR-064-013, FR-064-029
**Funcionalidade**: FEAT-064-002 (primária)
**Componente**: COMP-065-006 (principal), COMP-065-007
**Wave**: 4
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-065-007
- **Bloqueia**: TASK-065-011, TASK-065-014

## Contexto

Antes de exportar ou publicar, EDITOR e ADMIN consultam, por uma leitura sem efeito colateral, se o PDF final é permitido para o Conteúdo (e por quê não), quantos Quadros têm imagem (N de M) e a lista do Aviso de exportação por posição e categoria. A rota `GET /contents/:id/publication/final-preview` nasce aqui, com o leitor de serviço e a barreira de autorização; a tela é da TASK-065-014. Território: memo de exploração e MAP do slug; A-065-001 e TRISK-065-010 no PLAN-065.

Ambiente de execução: os comandos rodam a partir da raiz `Mnemonico/kan237/` (contém `mnemonicos-backend/` e `mnemonicos-frontend/`, worktrees da branch do épico, e `docs/`, symlink para o workspace); os testes de paridade resolvem `../../../mnemonicos-frontend/…` a partir dela. Antes da suíte de integração: `source env-kan237.sh` (exporta `TEST_DATABASE_URL`, Postgres dedicado 127.0.0.1:5433, e `KAN237_DB_CONTAINER`); nunca aceitar reset em banco compartilhado. Exclusividade do banco: `docker exec "${KAN237_DB_CONTAINER:-mnemonicos-db}" psql -U postgres -d postgres -tAc "SELECT count(*) FROM pg_stat_activity WHERE datname = 'mnemonicos_test' AND pid <> pg_backend_pid()"` → `0`.

## Escopo

### Inclui
- mnemonicos-backend/src/modules/publication/publication.service.ts: `getFinalPreview` e `FinalPreview` (sem `latestPublication`, que a TASK-065-011 acrescenta). Inelegível => `framesTotal` 0, `framesWithImage` 0, `warnings` `[]` e nenhuma leitura de binário; elegível sem Tira ou sem Quadros => `eligible: false` com `reason: 'NO_STRIP'`; precedência: sem Versão/alterada antes de `NO_STRIP`. Reusa `prepareFrameImage` (documento descartável) e `computeStripCoverage` da TASK-065-007; a Tira é lida sem autogerar (A-065-001).
- mnemonicos-backend/src/modules/publication/publication.routes.ts: `GET /contents/:id/publication/final-preview`, sem `verifyOrigin` (leitura), com `requireRole('GET', '/contents/:id/publication/final-preview', 'EDITOR', 'ADMIN')`.
- mnemonicos-backend/src/domain/types.ts: razão `NO_STRIP` do preview.
- mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts: rota nova na lista explícita de pares (hoje 53 pares, título e lista ao redor da linha 154; vira 54).
- mnemonicos-backend/tests/integration/publication.final-preview.integration.test.ts (novo).
- mnemonicos-backend/tests/unit/publication-final-frontend-contract.test.ts (novo; lê as duas fontes).
- mnemonicos-frontend/src/types/domain.ts: espelho de `FinalPreview`, `ExportWarning` e `ExportWarningKind`, no mesmo diff.

### Não inclui
- `latestPublication` no preview (TASK-065-011).
- Compor, salvar ou emitir evento a partir do preview; cliente RTK, tag `PublishedPdfPreview` e tela (TASK-065-014).
- Extrair `extractInterfaceFields` para `tests/support/`: decisão escrita, duplicar. Já existem 4 cópias locais (`tests/unit/tira-frontend-contract.test.ts:47`, `strategic-panel-frontend-contract.test.ts:140`, `contents-frontend-contract.test.ts:60`, `visual-associations-frontend-contract.test.ts:52`); a convenção vigente do repo é cópia local por arquivo de contrato, e extrair tocaria 4 arquivos fora do escopo.
- Páginas e geração de PDF; teto de tamanho.

## Critérios de pronto

- [ ] AC-064-011 (parte: o preview lista a posição e distingue `MISSING_IMAGE` de `IMAGE_NOT_EMBEDDABLE`; o PDF é da TASK-065-007 e a tela da TASK-065-014): Tira com um Quadro sem imagem (posição 2) e outro com imagem indecodificável (posição 3) devolve `warnings` `[{ position: 2, kind: 'MISSING_IMAGE' }, { position: 3, kind: 'IMAGE_NOT_EMBEDDABLE' }]` em valor literal, um a um, nunca "contém"; verificação executável: `npm --prefix mnemonicos-backend run test:integration -- tests/integration/publication.final-preview.integration.test.ts` → `0 failed` e `N passed` (N > 0); mutante que troca os dois `kind` entre si (em `git worktree add`, nunca na árvore principal) reprova
- [ ] AC-064-025 (parte: o preview lista o Quadro na categoria `BELOW_RECOMMENDED_RESOLUTION` sem bloquear; a exportação é da TASK-065-007 e a tela da TASK-065-014): Quadro com imagem de lado maior 1999 px aparece com `kind: 'BELOW_RECOMMENDED_RESOLUTION'`, conta em `framesWithImage` e `eligible` segue `true`; verificação executável: mesmo comando de integração → `0 failed`, com a fronteira 1999 avisa e 2000 não avisa em dois casos
- [ ] Sem efeito colateral (NFR-064-001, critério sem AC id): as contagens de `production_stage_events`, `publication_events` e `mnemonic_strips` antes e depois da chamada são iguais, inclusive para Conteúdo aprovado SEM Tira (não autogera: A-065-001; resposta `eligible: false` com `reason: 'NO_STRIP'`); verificação executável: mesmo comando de integração → `0 failed`; mutante que chama `openMnemonicStrip` no preview reprova pela contagem de `mnemonic_strips`
- [ ] Inelegível não lê binário: `framesTotal` 0, `framesWithImage` 0, `warnings` `[]` e `getVisualAssociationBinary` não é chamada; o espião é instalado no módulo que `publication.service.ts` realmente importa, com controle positivo no mesmo arquivo (o mesmo espião registra pelo menos 1 chamada com Versão elegível), para que a ausência não seja vazio verde; verificação executável: mesmo comando de integração → `0 failed`
- [ ] Razões e precedência, um caso por razão e por par (lição `rvore-de-decis-o-com-preced-ncia-um-caso-por-par-de-ramos-que-coincide`; o nome do teste enuncia quem vence): sem Versão aprovada → `NO_APPROVED_VERSION`; Versão alterada após o fechamento → `ALTERED_AFTER_CLOSURE`; alterada E não aprovada → `ALTERED_AFTER_CLOSURE` vence; sem Versão E sem Tira → `NO_APPROVED_VERSION` vence `NO_STRIP`; aprovada sem Tira → `NO_STRIP`; verificação executável: mesmo comando de integração → `0 failed`; mutante que inverte a ordem das duas últimas checagens reprova
- [ ] Equivalência preview × exportação (TRISK-065-010): no MESMO fixture com os 3 tipos de aviso (Quadro sem imagem, imagem indecodificável, imagem abaixo de 2000 px) e um Quadro ok, `warnings`, `framesTotal` e `framesWithImage` do preview são iguais ao `coverage` devolvido por `buildFinalStripPdf` para os mesmos Quadros; verificação executável: mesmo comando de integração → `0 failed`; mutante que classifica `BELOW` com outro limite só no preview reprova
- [ ] Chaves exatas do payload (lição `select-exposto-que-le-campo-interno-prova-as-chaves-do-payload`; forma fixada nesta TASK): elegível → `Object.keys(body).sort()` igual a `['eligible', 'framesTotal', 'framesWithImage', 'version', 'warnings']`; inelegível → `['eligible', 'framesTotal', 'framesWithImage', 'reason', 'warnings']`; `version` com chaves `['legislativeClosureDate', 'number']`, `legislativeClosureDate` como string; cada item de `warnings` com chaves `['kind', 'position']`; verificação executável: mesmo comando de integração → `0 failed`
- [ ] Autorização da rota GET (NFR-064-001, critério sem AC id), na app real montada, sem declarar a rota à mão no teste (lição `barreira-que-nega-com-base-num-registro-exige-o-registro-completo-antes-da-1-requisi-o`): sem sessão → 401; STUDENT → 403; EDITOR e ADMIN → 200; Conteúdo removido → 404 pelo método GET (lição `guarda-reusada-continua-exigindo-prova-comportamental-pr-pria-por-novo-m-todo-de-escrita`, prova comportamental própria do método novo); EDITOR B lê a Tira de Conteúdo de EDITOR A (alcance comum, sem restrição por autoria); verificação executável: mesmo comando de integração → `0 failed`; mutante que remove `requireRole(...)` da rota reprova o caso 403
- [ ] Topologia adversarial (lição `declarado-n-o-autorizado-prova-de-gate-de-autz-exige-topologia-adversarial`): na app real, `POST /contents/:id/publication/final-preview` (outro método no mesmo caminho) não responde 200 e não executa o handler do GET; a rota irmã `POST /contents/:id/publication` continua exigindo `verifyOrigin` como 1º handler; verificação executável: mesmo comando de integração → `0 failed`
- [ ] GET sem `verifyOrigin` é intencional (lição `asser-o-estrutural-repo-wide-que-filtra-por-allowlist-de-outro-controle-declara-por-que-a-exce-o-vale-ou-n-o-filtra`, tripwire por método): `GET /contents/:id/publication/final-preview` sem cabeçalho `Origin` responde 200 com sessão EDITOR, e o censo de `verifyOrigin` por método do `route-authz-matrix` continua exigindo `handlers[0] === verifyOrigin` só para POST/PATCH/PUT/DELETE; verificação executável: `npm --prefix mnemonicos-backend run test:integration -- tests/integration/route-authz-matrix.integration.test.ts` → `0 failed` e `N passed` (N > 0)
- [ ] Tripwire do censo de rotas atualizado: a lista explícita de `route-authz-matrix.integration.test.ts` ganha `'GET /contents/:id/publication/final-preview'`, a contagem do título passa de 53 para 54 (número conferido por Grep na fixação e reconferido no baseline do developer) e o título do caso registra a rota somada; verificação executável: mesmo comando de integração do critério anterior → `0 failed`; mutante que remove o registro da rota em `publication.routes.ts` reprova o censo
- [ ] Paridade backend × frontend dos tipos (lição `coment-rio-que-afirma-paridade-entre-os-dois-repos-s-vale-se-o-teste-ler-as-duas-fontes`): `tests/unit/publication-final-frontend-contract.test.ts` lê as duas fontes como texto, lança se o arquivo do frontend não existir (falha alto), compara por campo o texto de tipo normalizado de `FinalPreview` e `ExportWarning` e os conjuntos de literais de `ExportWarningKind` (`MISSING_IMAGE`, `IMAGE_NOT_EMBEDDABLE`, `BELOW_RECOMMENDED_RESOLUTION`) e da razão (`NO_APPROVED_VERSION`, `ALTERED_AFTER_CLOSURE`, `NO_STRIP`); a comparação é de paridade entre as duas fontes, sem lista literal total que a TASK-065-011 quebraria ao acrescentar `latestPublication` nos dois lados; controle positivo do extrator (ele acha `FinalPreview` e devolve campos não vazios) e negativo (interface inexistente lança); verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/publication-final-frontend-contract.test.ts` → `0 failed` e `N passed` (N > 0); mutantes em `mnemonicos-frontend/src/types/domain.ts` (renomear um campo de `FinalPreview`; retirar `BELOW_RECOMMENDED_RESOLUTION` da união) reprovam, cada um em worktree do frontend
- [ ] Espelho no frontend compila: `npm --prefix mnemonicos-frontend run typecheck` → saída 0
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git -C mnemonicos-backend diff --name-only main...HEAD` e `git -C mnemonicos-frontend diff --name-only main...HEAD`), produção e teste: `npm --prefix mnemonicos-backend run lint`, `npm --prefix mnemonicos-backend run typecheck` e `npm --prefix mnemonicos-backend run format:check` saem 0; `npm --prefix mnemonicos-frontend run lint` e `npm --prefix mnemonicos-frontend run format:check` saem 0

## Riscos específicos

- Gate 8 (rota nova de leitura, alcance comum) e gate 10 (o preview lê todos os binários de imagem da Tira a cada chamada; custo medido em tira real).
- A forma exata das chaves do payload é fixada aqui (elegível com `version`, inelegível com `reason`); o PLAN-065 só declara os campos como opcionais.
- `latestPublication` entra pela TASK-065-011 nos dois lados (serviço e espelho) e a TASK-065-011 atualiza `tests/unit/publication-final-frontend-contract.test.ts` (decisão D12); o contrato de chaves do preview fixado aqui é o ponto de partida dessa extensão.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
**Jira**: KAN-269

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
