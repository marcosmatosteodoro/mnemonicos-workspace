# TASK-065-010: Aviso de resolução no envio de imagem (API e formulário)

**Slug**: producao-material
**Pertence a**: PLAN-065
**Realiza (FRs)**: FR-064-014, FR-064-015
**Funcionalidade**: FEAT-064-002 (primária)
**Componente**: COMP-065-012 (principal), COMP-065-018, COMP-065-013
**Wave**: 5
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-065-007, TASK-065-008
- **Bloqueia**: TASK-065-011, TASK-065-014, TASK-065-017

## Contexto

O envio de imagem à Biblioteca visual continua aceito em qualquer resolução, mas, quando o lado maior fica abaixo da Resolução recomendada (2000 px, caixa de 480 pt a 300 dpi), a resposta do envio traz um aviso e o formulário o exibe sem perder o item criado. Esta TASK atravessa a resposta de `POST /visual-associations`, o contrato nos dois repositórios e o formulário `VisualLibraryCreateForm`. Território: memo de exploração e MAP do slug; DEC-065-005 no PLAN-065.

Ambiente de execução: os comandos rodam a partir da raiz `Mnemonico/kan237/` (contém `mnemonicos-backend/` e `mnemonicos-frontend/`, worktrees da branch do épico, e `docs/`, symlink para o workspace); os testes de paridade resolvem `../../../mnemonicos-frontend/…` a partir dela. Antes da suíte de integração: `source env-kan237.sh` (exporta `TEST_DATABASE_URL`, Postgres dedicado 127.0.0.1:5433, e `KAN237_DB_CONTAINER`); nunca aceitar reset em banco compartilhado. Exclusividade do banco: `docker exec "${KAN237_DB_CONTAINER:-mnemonicos-db}" psql -U postgres -d postgres -tAc "SELECT count(*) FROM pg_stat_activity WHERE datname = 'mnemonicos_test' AND pid <> pg_backend_pid()"` → `0`.

## Escopo

### Inclui
- mnemonicos-backend/src/modules/visual-associations/upload-warnings.ts (novo): `computeUploadWarnings(buffer)` e `UploadWarning`; formato pela assinatura do conteúdo (`detectImageSignature`); PNG e JPEG por `readImageDimensions`, WEBP por `readWebpDimensions` (TASK-065-008); limite por `RECOMMENDED_LONG_SIDE_PX` importado de `strip-coverage.ts` (TASK-065-007).
- mnemonicos-backend/src/modules/visual-associations/visual-associations.routes.ts: o `201` de `POST /visual-associations` passa a devolver `{ ...created, warnings }` (ponto hoje em `res.status(201).json(created)`, linha 178); o service não é editado (o `201` existente é testado com `toMatchObject`, `tests/integration/visual-associations.routes.integration.test.ts:114`, então o campo aditivo não o quebra).
- Testes do backend: mnemonicos-backend/tests/unit/upload-warnings.test.ts, mnemonicos-backend/tests/integration/visual-associations.routes.integration.test.ts (casos novos), mnemonicos-backend/tests/unit/visual-associations-frontend-contract.test.ts (campo `warnings` e `UploadWarning` nas duas fontes).
- mnemonicos-frontend/src/types/domain.ts: `UploadWarning`.
- mnemonicos-frontend/src/store/api.ts: `createVisualAssociation` (hoje `build.mutation<VisualAssociation, FormData>`, linha 730) passa a ter retorno com `warnings`; mnemonicos-frontend/src/store/api.test.ts (caso novo).
- mnemonicos-frontend/src/components/visual-library-board.tsx (`VisualLibraryCreateForm`): aviso `role="status"` com o texto "Imagem com X × Y px; recomendado: lado maior de 2000 px para boa impressão"; o aviso sobrevive ao reset do formulário que hoje ocorre após o envio (linhas 674-680); sem aviso quando `warnings` é vazio; mnemonicos-frontend/src/components/visual-library-board.test.tsx (casos novos).

### Não inclui
- Coluna de dimensões no banco (DEC-065-005: as dimensões são calculadas no ato); recusa por resolução (nunca); aviso na tela da tira ou no seletor.
- Edição de `visual-associations.service.ts`; o picker `visual-association-picker.tsx` e a estrutura do item de lista da biblioteca.
- Aviso para o acervo antigo: é a 3a categoria do Aviso de exportação (TASK-065-009 e TASK-065-014).

## Critérios de pronto

- [ ] AC-064-012 (backend: aceita e avisa, valor único citado): envio de imagem com lado maior 1999 px responde 201 com `warnings` igual a `[{ code: 'BELOW_RECOMMENDED_RESOLUTION', recommendedLongSidePx: 2000, widthPx, heightPx }]` com chaves exatas `['code', 'heightPx', 'recommendedLongSidePx', 'widthPx']` (lição `select-exposto-que-le-campo-interno-prova-as-chaves-do-payload`) e a associação é criada; lado maior 2000 px responde 201 com `warnings` `[]` (fronteira: 1999 avisa e 2000 não); imagem muito pequena é aceita (nunca recusada por resolução); verificação executável: `npm --prefix mnemonicos-backend run test:integration -- tests/integration/visual-associations.routes.integration.test.ts` → `0 failed` e `N passed` (N > 0); mutante `<` trocado por `<=` (em `git worktree add`, nunca na árvore principal) reprova o caso 2000
- [ ] AC-064-012 (formatos, um teste por ramo — lição `extrator-com-cadeia-de-fallback-a-b-c-exige-1-teste-por-ramo-fixture-sempre-completo-nunca-exercita-o-2-3-fallback`): `computeUploadWarnings` cobre PNG e JPEG (via `readImageDimensions`) e WEBP (via `readWebpDimensions`, fixture `buildValidWebpNxN` de `tests/support/webp-fixtures.ts`), cada um com largura e altura distintas (para que trocar `widthPx` por `heightPx` reprove); dimensão ilegível (buffer só com a assinatura) devolve `[]` sem lançar, e no envio responde 201 com `warnings` `[]`; verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/upload-warnings.test.ts` → `0 failed` e `N passed` (N > 0, um caso nomeado por ramo); mutante que pula o ramo WEBP reprova o caso WEBP
- [ ] AC-064-012 (recusas continuam, FR-064-015): envio sem sessão responde 401 e por STUDENT responde 403; nos dois casos a contagem de linhas de `visual_associations` antes e depois é igual e o corpo não tem a chave `warnings`; verificação executável: mesmo comando de integração → `0 failed`; mutante que remove `requireRole(...)` da rota reprova o caso 403
- [ ] Limite sem re-literal (lição `corre-o-de-duplica-o-dry-introduz-nova-re-deriva-o-do-can-nico-no-mesmo-diff`): `grep -cE '^[^*/]*\b2000\b' mnemonicos-backend/src/modules/visual-associations/upload-warnings.ts` → `0`; calibração com positivo conhecido: `grep -cE '^[^*/]*\b2000\b' mnemonicos-backend/src/modules/publication/strip-coverage.ts` → `1` (a declaração de `RECOMMENDED_LONG_SIDE_PX`)
- [ ] O service não foi editado e o `201` existente segue verde: `git -C mnemonicos-backend diff --stat <commit-pai-da-TASK>..HEAD -- src/modules/visual-associations/visual-associations.service.ts` → saída sem linhas (ancorado no commit-pai da TASK); os casos de `201` anteriores do arquivo de integração passam sem reescrita de valor
- [ ] Paridade do contrato nos dois repositórios (lição `coment-rio-que-afirma-paridade-entre-os-dois-repos-s-vale-se-o-teste-ler-as-duas-fontes`): `tests/unit/visual-associations-frontend-contract.test.ts` lê as duas fontes e compara os campos de `UploadWarning` (backend `upload-warnings.ts` × frontend `src/types/domain.ts`) e o literal do campo `code` (`BELOW_RECOMMENDED_RESOLUTION`); verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/visual-associations-frontend-contract.test.ts` → `0 failed` e `N passed` (N > 0); mutante que renomeia `widthPx` em `domain.ts` (worktree do frontend) reprova
- [ ] Contrato de retorno da mutation (fonte: `mnemonicos-frontend/src/store/api.ts:730` hoje `build.mutation<VisualAssociation, FormData>`; `visual-library-board.tsx:674` hoje descarta o resultado de `.unwrap()`): `createVisualAssociation` resolve com a associação e `warnings`, e a lista de associações é refeita após o envio pela tag que o endpoint já invalida (aviso lido do retorno da própria mutation, nunca de campo calculado de outro recurso, lição `campo-calculado-de-outro-recurso-invalida-a-tag-do-endpoint-que-o-exibe`); verificação executável: `npm --prefix mnemonicos-frontend test -- src/store/api.test.ts` → `0 failed` e `N passed` (N > 0); mutante que remove a tag invalidada pelo endpoint reprova o caso da lista
- [ ] AC-064-012 (formulário: exibe o aviso e mantém o item): após envio com `warnings` de `[{ code: 'BELOW_RECOMMENDED_RESOLUTION', recommendedLongSidePx: 2000, widthPx: 1500, heightPx: 1000 }]` o formulário mostra, em elemento com `role="status"`, o texto "Imagem com 1500 × 1000 px; recomendado: lado maior de 2000 px para boa impressão" (largura antes da altura), a mensagem "Associação visual criada com sucesso." (`visual-library-board.tsx:37`) segue exibida e o aviso permanece depois do reset dos campos; envio seguinte com `warnings` `[]` faz o aviso sumir; sem aviso quando `warnings` é vazio; verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/visual-library-board.test.tsx` → `0 failed` e `N passed` (N > 0); mutante que descarta o aviso no reset reprova, e mutante que troca largura por altura no texto reprova
- [ ] Debounce da sugestão intocado e provado do jeito certo (lição `prova-de-debounce-digita-com-intervalo-menor-que-a-janela`): os casos novos que digitam no campo de categoria (a sugestão tem debounce em `visual-library-board.tsx:616-649`) usam `userEvent.setup({ delay: <janela menos 100 ms>, advanceTimers })` ou `fireEvent.change`, e os casos de debounce já existentes do arquivo seguem verdes; verificação executável: o mesmo comando do critério anterior → `0 failed`, com N maior ou igual ao do baseline capturado antes de começar
- [ ] Sem classe CSS nova e sem mexer no item de lista (lições `utility-escrito-m-o-no-tailwind-4-nunca-referencia-var-tw-a-custom-property-s-existe-quando-um-utilit-rio-nativo-a-registra` e `item-de-lista-que-renderiza-a-mesma-entidade-em-2-componentes-nascidos-na-mesma-wave-herda-a-corre-o-de-acessibilidade-j-aplicada-no-irm-o-can-nico-n-o-s-a-estrutura`): `git -C mnemonicos-frontend diff --stat <commit-pai-da-TASK>..HEAD -- src/app/globals.css src/components/visual-association-picker.tsx` → saída sem linhas; o aviso usa só classes utilitárias já presentes no arquivo do formulário
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git -C mnemonicos-backend diff --name-only main...HEAD` e `git -C mnemonicos-frontend diff --name-only main...HEAD`), produção e teste: `npm --prefix mnemonicos-backend run lint`, `npm --prefix mnemonicos-backend run typecheck`, `npm --prefix mnemonicos-backend run format:check`, `npm --prefix mnemonicos-frontend run lint`, `npm --prefix mnemonicos-frontend run typecheck` e `npm --prefix mnemonicos-frontend run format:check` saem 0

## Riscos específicos

- O resultado de `.unwrap()` em `visual-library-board.tsx:674` hoje é descartado; a TASK passa a consumi-lo, e o estado do aviso precisa sobreviver ao `reset` já existente sem vazar para o próximo envio.
- A suíte de integração roda em banco compartilhado, `--runInBand`; não executar duas suítes de integração em paralelo.
- Gate 9: consolidado FEAT-064-002 (provado no Roteiro da TASK-065-016, que envia B 800×600 e exige o aviso de resolução e A sem aviso).
- Overlap de `mnemonicos-frontend/src/types/domain.ts` com a TASK-065-011 (decisão D18): append em regiões distintas do arquivo; o implement serializa o par (evento `wave_sequencial`), e a TASK-065-011 passa a depender desta TASK.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
**Jira**: KAN-270

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
