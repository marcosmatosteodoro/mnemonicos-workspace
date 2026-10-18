# TASK-065-003: Indicador "N de M quadros com imagem" na tela da tira

**Slug**: producao-material
**Pertence a**: PLAN-065
**Realiza (FRs)**: FR-064-027
**Funcionalidade**: FEAT-064-004 (primária)
**Componente**: COMP-065-016 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-065-017

## Contexto

Na tela da Tira mnemônica, o EDITOR ou ADMIN passa a ver "N de M quadros com imagem", calculado no cliente a partir dos Quadros já em cache da query `MnemonicStrip` e atualizado quando um vínculo de imagem é criado ou removido. É a mesma contagem que a publicação grava (N e M, TASK-065-012), mas aqui só leitura, sem requisição nova. Território e decisões: PLAN-065 COMP-065-016; `MAP.md` do slug (seção Biblioteca visual, invalidação das duas tags nas mutations de vínculo).

**Raiz de execução**: os comandos rodam a partir de `Mnemonico/kan237/`, que contém `mnemonicos-backend/` e `mnemonicos-frontend/` (worktrees da branch do épico) e `docs/` (symlink para o workspace); os paths `mnemonicos-backend/…`, `mnemonicos-frontend/…` e `docs/…` desta TASK resolvem a partir dela.

## Escopo

### Inclui
- `mnemonicos-frontend/src/lib/strip-coverage-count.ts`: `countFramesWithImage(frames: readonly { visualAssociationId: string | null }[]): { withImage: number; total: number }`, e `mnemonicos-frontend/src/lib/strip-coverage-count.test.ts`.
- `mnemonicos-frontend/src/components/mnemonic-strip-board.tsx`: o indicador, com o texto literal `N de M quadros com imagem` (sem pluralização), dentro do bloco condicionado a `frames.length > 0` (mnemonic-strip-board.tsx:862-866), imediatamente acima de `<PublicationExportControl>`; com `M = 0` o indicador não renderiza.
- `mnemonicos-frontend/src/components/mnemonic-strip-board.test.tsx`: casos novos (o arquivo já mocka `PublicationExportControl` com `data-testid="publication-export-control"`, linhas 19-23).

### Não inclui
- O painel "PDFs publicados" (TASK-065-015) e o botão de exportação final (TASK-065-014): a ordem do DOM que esta TASK fixa é indicador → controle de exportação, e o painel entra depois do controle.
- Qualquer requisição nova e qualquer edição de `store/api.ts`: o link e o desvínculo já invalidam `MnemonicStrip` (api.ts:748 e api.ts:758), e o teste montado abaixo prova isso (o mutante que tira a tag é aplicado em worktree, nunca no código).
- A seção do Guia de uso (TASK-065-017).

## Critérios de pronto

- [ ] AC-064-021 (o indicador mostra "N de M quadros com imagem" na tela da tira e o valor muda ao vincular ou desvincular) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/mnemonic-strip-board.test.tsx` → `OK (N tests)`, N > 0, com `MnemonicStripBoard` MONTADO contra a `api` real (`makeStore()` + `fetch` mockado, sem mockar `useGetMnemonicStripQuery`): Tira de 2 Quadros sem vínculo → texto `0 de 2 quadros com imagem`; vincular o 1º Quadro pelo seletor → `1 de 2 quadros com imagem` (sem recarregar a página); desvincular → `0 de 2 quadros com imagem`; com os 2 vinculados → `2 de 2 quadros com imagem`; adicionar um Quadro (a Tira vira 3) → o M do texto acompanha. Falha se o valor ficar estático depois da mutation. Mutante em worktree (`git -C mnemonicos-frontend worktree add <TMP>/mnemonicos-frontend HEAD`; a árvore principal nunca é editada): tirar `'MnemonicStrip'` de `invalidatesTags` de `linkVisualAssociationToFrame` e de `unlinkVisualAssociationFromFrame` em `src/store/api.ts` → o caso "vincular" e o caso "desvincular" saem vermelhos (lição `campo-calculado-de-outro-recurso-invalida-a-tag-do-endpoint-que-o-exibe`: o campo calculado depende da tag do recurso de que vem).
- [ ] `countFramesWithImage` conta pelo vínculo, não por outra coisa — verificação executável: `npm --prefix mnemonicos-frontend test -- src/lib/strip-coverage-count.test.ts` → `OK (N tests)`, N > 0, com `{ withImage, total }` literal para: 0 de 3 → `{ withImage: 0, total: 3 }`, 2 de 3 → `{ withImage: 2, total: 3 }`, 3 de 3 → `{ withImage: 3, total: 3 }`, 1 de 1 → `{ withImage: 1, total: 1 }` e lista vazia → `{ withImage: 0, total: 0 }`. Mutante em worktree: `visualAssociationId !== null` trocado por `true` → o caso 0 de 3 sai vermelho; trocado por `visualAssociationId !== undefined` → o mesmo caso 0 de 3 sai vermelho (os Quadros sem vínculo vêm com `null`, não `undefined`).
- [ ] M = 0 não renderiza o indicador e a ordem do DOM é indicador antes do controle (posição nomeada no FR, estado vazio da Tira: lições do `core/DESIGN.md`) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/mnemonic-strip-board.test.tsx` → `OK (N tests)`, N > 0; o arquivo cobre: (1) Tira vazia (o caso de AC-011-024, mnemonic-strip-board.test.tsx:678) → `queryByText(/quadros com imagem/)` é `null`, com o controle positivo no mesmo arquivo (a Tira de 2 Quadros acha o texto); (2) na Tira com Quadros, `indicador.compareDocumentPosition(getByTestId('publication-export-control'))` tem o bit `Node.DOCUMENT_POSITION_FOLLOWING` e os dois são irmãos dentro do mesmo bloco. Mutante em worktree: mover o indicador para depois do controle → o caso (2) sai vermelho.
- [ ] A leitura vale para EDITOR e ADMIN, sem ramo de papel (lição `leitura-exigida-para-todo-papel-fica-fora-da-guarda-de-papel-da-acao`) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/mnemonic-strip-board.test.tsx` → `OK (N tests)`, N > 0; o arquivo cobre: o indicador aparece com `makeStore()` limpo e sem nenhuma resposta de sessão (`/auth/me`) no fake de rede, ou seja, o render do indicador não consulta papel nem autoria (a leitura da Tira em si segue a guarda que o backend já impõe; esta TASK não a altera).
- [ ] O indicador não introduz utilitário novo nem sublinhado (lição `utility-escrito-m-o-no-tailwind-4-nunca-referencia-var-tw-a-custom-property-s-existe-quando-um-utilit-rio-nativo-a-registra`) — verificação executável: `git -C mnemonicos-frontend diff --name-only <SHA-pai-da-TASK>..HEAD -- src/app/globals.css src/store/api.ts` → vazio (os dois arquivos existem no commit-pai); a classe do texto é `text-sm text-muted`, como em visual-association-list-states.tsx:97; `npm --prefix mnemonicos-frontend test -- src/lib/no-underline.test.ts` → `OK (N tests)`.
- [ ] A suíte do board segue verde com o mesmo número de testes passando do baseline mais os casos novos — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/mnemonic-strip-board.test.tsx` → `OK (N tests)` com N ≥ baseline capturado pelo developer antes de começar.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git -C mnemonicos-frontend diff --name-only main...HEAD`), produção e teste — verificação executável: `npm --prefix mnemonicos-frontend run lint`, `npm --prefix mnemonicos-frontend run typecheck` e `npm --prefix mnemonicos-frontend run format:check` → exit 0.

## Riscos específicos

- O bloco do controle de exportação só existe com `frames.length > 0`: o indicador herda essa condição, e o "M = 0 não renderiza" é dupla garantia (condição do bloco e guarda do próprio indicador).
- A TASK-065-014 e a TASK-065-015 enxertam no mesmo bloco depois desta; a ordem indicador → controle → painel é contrato, e o teste de ordem da TASK-065-015 a reconfere.
- Lições casadas por caminho e sem objeto nesta TASK: `mensagem-de-recusa-recuperavel-diz-o-proximo-passo-com-o-nome-da-acao-da-tela` (nenhuma recusa nova) e `prova-de-debounce-digita-com-intervalo-menor-que-a-janela` (nenhum debounce); `entrega-roda-format-check-nos-arquivos-tocados-alem-de-lint-e-jest` (em observação) está coberta pelo `format:check` do último critério.
- Gate 9: consolidado FEAT-064-004 (sem Roteiro próprio; o comportamento é provado no gate 1 com o componente montado).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-10-18T02:51:34-0300
**Data conclusão**: 2026-10-18T02:52:47-03:00
**Commit SHA**: 2ef5641
**Jira**: KAN-263

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 1)
- [x] Comportamento (gate 9): consolidado (FEAT-064-004)
<!-- Branch, tentativas, arquivos, revisores e narrativa (retries, escalações) vivem no
ledger da sessão e no commit da closure (4.76) — não se repetem aqui (4.409). -->
