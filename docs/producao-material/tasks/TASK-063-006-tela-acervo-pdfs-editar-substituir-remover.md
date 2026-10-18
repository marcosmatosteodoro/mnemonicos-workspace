# TASK-063-006: Tela do Acervo de PDFs: editar metadados, substituir o arquivo e remover

**Slug**: producao-material
**Pertence a**: PLAN-063
**Realiza (FRs)**: FR-061-007, FR-061-008, FR-061-009, FR-061-010, FR-061-012, FR-061-023
**Funcionalidade**: FEAT-061-001 (primária)
**Componente**: COMP-063-006 (principal)
**Wave**: 4
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-063-004, TASK-063-005
- **Bloqueia**: TASK-063-009, TASK-063-013

## Contexto

Na tela do Acervo (TASK-063-005), qualquer EDITOR ou ADMIN edita os metadados de um PDF; só o autor ou um ADMIN vê Substituir (novo arquivo no lugar do atual, com Versão e Data editáveis e confirmação de que o anterior deixa de existir) e Remover (recusada pelo servidor, nomeando os Pacotes, quando o PDF tem Itens). Contrato servidor→tela: rotas e mensagens da TASK-063-004 e `mnemonicos-backend/src/http/middlewares/error-handler.ts:26-40,64-80`; território no memo do `code-scout` (itens 6 e 11) e PLAN-063 §4. O Guia de uso não é tocado aqui: guia: TASK-063-013.

## Escopo

### Inclui
- `mnemonicos-frontend/src/components/pdf-library-board.tsx` (alterado; criado na TASK-063-005): ações "Editar", "Substituir" e "Remover" por item. Substituir e Remover só aparecem para o autor (`authorId` igual ao `id` do `useMeQuery`) ou ADMIN; enquanto a sessão carrega ou falha, não aparecem (falha fechada). Dois estados decidem o ramo do JSX in-place e têm nome fixo para serem grepáveis: `editingPdfId` (setter `setEditingPdfId`) e `dialog` (setter `setDialog`); enquanto um diálogo está aberto ou uma operação está em voo, as ações dos demais itens ficam `disabled`.
- `mnemonicos-frontend/src/components/pdf-edit-form.tsx`, `mnemonicos-frontend/src/components/pdf-replace-dialog.tsx` e `mnemonicos-frontend/src/components/pdf-remove-dialog.tsx` (novos, `'use client'`). Reusam `BusyButton`/`BusyAnnouncement` de `progress-indicator.tsx`, `RequiredLabelText`, `isFetchBaseQueryError` e `useListDisciplinesQuery` (Grep: existem; nenhum equivalente novo).
- `mnemonicos-frontend/src/store/api.ts`: endpoints `updateLibraryPdf` (`PATCH /pdf-library/:id`), `createPdfReplacementIntent` (`POST /pdf-library/:id/replacement`), `confirmPdfReplacement` (`POST /pdf-library/:id/replacement/confirm`) e `removeLibraryPdf` (`DELETE /pdf-library/:id`), com hooks, e invalidação de `LibraryPdf` e `LibraryPdfList` (tags criadas na TASK-063-005). A intenção de substituição reusa o DTO `PdfUploadIntent` da TASK-063-003; nenhum DTO novo.
- Testes novos: `mnemonicos-frontend/src/components/pdf-edit-form.test.tsx`, `mnemonicos-frontend/src/components/pdf-replace-dialog.test.tsx`, `mnemonicos-frontend/src/components/pdf-remove-dialog.test.tsx` e `mnemonicos-frontend/src/components/pdf-library-board.personas.integration.test.tsx`.
- `mnemonicos-frontend/src/components/pdf-library-board.test.tsx` (alterado; criado na TASK-063-005).
- Reuso por import, nunca redefinição: `uploadToStorage`, `installFakeXhr` e `formatDateOnly` (donos na TASK-063-005).

### Não inclui
- Tags de `SalesPackage` nas mutations do acervo: a tag nasce na TASK-063-009, que acrescenta a invalidação aqui.
- Telas de Pacotes e menu "Pacotes".
- AC-061-013 (os 3 estados do envio de PDF novo): TASK-063-005.
- Backend (rotas e regras de autor-ou-ADMIN são da TASK-063-004).
- Corrida remoção × inclusão em Pacote (AC-061-038, TASK-063-008): aqui só a recusa que o servidor devolve.
- Atualizar `docs/GUIA-DE-USO.md`: TASK-063-013.
- Busca ou filtro com debounce: esta TASK não tem campo de busca (busca sem debounce).

## Critérios de pronto

- [ ] AC-061-006 (parte tela; a persistência é da TASK-063-004) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-edit-form.test.tsx src/components/pdf-library-board.test.tsx` → `Tests: N passed, 0 failed` (N > 0). O formulário abre preenchido com os 5 campos do PDF (Título, Versão, Data de fechamento legislativo, Prova/concurso, Disciplina), salvar com Versão "v2" chama `PATCH /api/v1/pdf-library/<id>` e, com o tabuleiro MONTADO contra a `api` real e o `fetch` falso, a lista já exibida passa a mostrar "v2" (a invalidação de `LibraryPdfList` é provada no componente montado, lição `campo-calculado-de-outro-recurso-invalida-a-tag-do-endpoint-que-o-exibe`). Mutante em `git worktree add`: retirar `invalidatesTags` de `updateLibraryPdf` → a lista continua com "v1" e o caso fica vermelho.
- [ ] AC-061-047 (substituição; a faceta do servidor é da TASK-063-004) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-replace-dialog.test.tsx` → `Tests: N passed, 0 failed` (N > 0): ao abrir, os campos Versão e Data de fechamento legislativo vêm preenchidos com os valores atuais do PDF (por valor literal, ex.: "v1" e 2026-10-01) e são editáveis; o texto de confirmação contém o literal [proposto] "O arquivo anterior deixa de existir e não poderá ser recuperado."; sem acionar "Confirmar substituição" o `fake` de rede registra 0 chamadas `POST` e o `FakeXMLHttpRequest` 0 `PUT`. Confirmada: `POST .../replacement`, depois o `PUT` com progresso (`progressbar` com `aria-valuenow` 50 após `loaded=512`, `total=1024`) e `POST .../replacement/confirm` com a Versão editada. Mutante em worktree: enviar a intenção ao escolher o arquivo, antes da confirmação → o caso "sem confirmar, nada é enviado" fica vermelho.
- [ ] AC-061-014 e AC-061-009 (parte tela: removido o PDF fora de qualquer Pacote, ele some da lista) (remoção: 3 estados) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-remove-dialog.test.tsx src/components/pdf-library-board.test.tsx` → `Tests: N passed, 0 failed` (N > 0). O diálogo de confirmação nomeia o PDF pelo Título, diz que o arquivo deixa de existir, tem o foco inicial em "Cancelar" e os botões "Confirmar remoção" e "Cancelar". Em andamento: "Confirmar remoção" vira "Removendo", desabilitado e com `aria-busy`. Sucesso: o PDF sai da lista já montada e a mensagem "PDF removido." é anunciada. Falha: a `message` do servidor aparece em `role="alert"` no próprio diálogo e o PDF PERMANECE na lista. Mutante em worktree: tirar `invalidatesTags` de `removeLibraryPdf` → o caso de sucesso fica vermelho.
- [ ] AC-061-035 e AC-061-037 (parte tela; personas autor, EDITOR não-autor e ADMIN; 2 ações restritas, métodos de escrita do FR-061-023: 2; provas: 2) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-library-board.personas.integration.test.tsx` → `Tests: N passed, 0 failed` (N > 0), 1 teste montado por papel, com `/auth/me` devolvendo a identidade de cada persona e a mesma fixture de PDF (autor = o EDITOR "ana"). Autor (EDITOR "ana"): vê Editar, Substituir, Remover e Baixar. EDITOR não-autor ("bia"): vê a lista, Baixar e Editar e NÃO vê Substituir nem Remover (a faceta de servidor "mensagem de recusa e arquivo intacto" é da TASK-063-004). ADMIN não-autor: vê as quatro ações e Substituir abre o diálogo. Lista e Baixar renderizam fora de qualquer ramo de papel (lição `leitura-exigida-para-todo-papel-fica-fora-da-guarda-de-papel-da-acao`); com `/auth/me` ainda carregando ou em erro, Substituir e Remover não aparecem e a lista aparece. Um mutante por ação, em worktree, cada um reprovando em asserção distinta: tornar Substituir sempre visível reprova o caso do não-autor em "sem Substituir"; tornar Remover sempre visível reprova o mesmo caso em "sem Remover".
- [ ] Contrato das 4 chamadas do Inclui (sem AC próprio; fonte: rotas da TASK-063-004) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-edit-form.test.tsx src/components/pdf-replace-dialog.test.tsx src/components/pdf-remove-dialog.test.tsx` → o `fake` de rede registra, por valor literal e nesta ordem de uso, `PATCH /api/v1/pdf-library/<id>`, `POST /api/v1/pdf-library/<id>/replacement`, `POST /api/v1/pdf-library/<id>/replacement/confirm` e `DELETE /api/v1/pdf-library/<id>`, com o corpo de metadados de `libraryPdfMetadataSchema` no PATCH e na confirmação; o `PUT` ao storage só passa por `uploadToStorage`, nunca por `fetch`.
- [ ] Anti-duplo-envio pelo canal aberto, 2 formulários (lição `prova-de-corrida-exclus-o-nasce-na-fronteira-da-invariante-e-o-mutante-roda-pelo-comando-do-crit-rio`) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-edit-form.test.tsx src/components/pdf-replace-dialog.test.tsx` → com a ação em voo, Enter dentro de um campo mantém 1 só `PATCH` no formulário de edição e 1 só `POST .../replacement` no diálogo de substituição. Mutante por formulário, em worktree: remover o retorno antecipado do `onSubmit` enquanto ocupado → o caso daquele formulário fica vermelho (2 formulários, 2 mutantes).
- [ ] Diálogo in-place: todos os setters dos estados que decidem o ramo (lição `di-logo-in-place-em-ramo-condicional-exige-grep-de-todos-os-setters-do-estado-que-decide-o-ramo-n-o-s-de-quem-o-fecha`) — verificação executável: `git grep -nE '^\s*(.*=> )?(setEditingPdfId|setDialog)\(' -- mnemonicos-frontend/src/components/pdf-library-board.tsx` → N linhas (N > 0, contado no fecho pelo developer), e `npm --prefix mnemonicos-frontend test -- src/components/pdf-library-board.test.tsx` → cada ocorrência tem um caso nomeado ou torna a ação concorrente `disabled`: com Remover aberto, Editar e Substituir de TODOS os itens ficam `disabled`; com a substituição em voo, nenhuma ação de outro item desmonta o diálogo, e ao fim (sucesso, falha ou cancelar) o foco volta ao botão que o abriu, nunca ao `<body>`. Mutante em worktree: tirar o `disabled` da ação "Editar" enquanto o diálogo de remoção está aberto → o caso fica vermelho (diálogo órfão).
- [ ] Modal centrado sem cortar o topo (lição `centralizar-com-items-center-num-container-fixed-tela-cheia-corta-o-topo-do-conte-do-que-transborda-sem-scroll-alcan-vel`) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-replace-dialog.test.tsx src/components/pdf-remove-dialog.test.tsx` → o contêiner `fixed` de cada diálogo tem, em `classTokens` (`tests/support/class-tokens.ts`), `items-center-safe` e `overflow-y-auto` e NÃO tem `items-center` puro; a medição em janela mais baixa que o diálogo (altura 360) é do gate 11, que o `product-designer` executa.
- [ ] Nome acessível único nas ações novas (lição `item-de-lista-que-renderiza-a-mesma-entidade-em-2-componentes-nascidos-na-mesma-wave-herda-a-corre-o-de-acessibilidade-j-aplicada-no-irm-o-can-nico-n-o-s-a-estrutura`) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-library-board.test.tsx` → com 2 PDFs de MESMO Título e MESMA Versão, os botões "Editar ...", "Substituir ..." e "Remover ..." têm, em cada família, 2 nomes acessíveis distintos (conjunto de tamanho 2; o nome inclui "item n de N", como o "Baixar" da TASK-063-005).
- [ ] AC-061-029 (parte tela: mensagens em pt-BR com o próximo passo) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-replace-dialog.test.tsx src/components/pdf-remove-dialog.test.tsx src/components/pdf-edit-form.test.tsx` → (1) AC-061-008 (parte tela: substituir por arquivo que não é PDF é recusado e o arquivo atual permanece) — recusa do servidor ao substituir por arquivo que não é PDF, no envelope de `error-handler.ts:64-80`: a `message` aparece em `role="alert"` e o diálogo mantém Versão, Data e o arquivo escolhidos; (2) validação do servidor no formato de `error-handler.ts:26-40` (`details: [{ path: 'title', message }]`) no formulário de edição: a mensagem aparece junto ao campo "Título" e o literal "VALIDATION_ERROR" não aparece; (3) conflito ao remover com a `message` do servidor nomeando "Pacote A" e "Pacote B": exibida por inteiro no diálogo, que continua aberto com "Cancelar" disponível; (4) a mensagem local de falha de rede no `PUT` nomeia a ação real: contém "Confirmar substituição" (lição `mensagem-de-recusa-recuperavel-diz-o-proximo-passo-com-o-nome-da-acao-da-tela`).
- [ ] Reuso sem redefinição, como condição sobre o universo real (decisão: extrair/reusar da TASK-063-005, nunca duplicar) — verificação executável: `git grep -nE '^\s*(export )?(async )?(function|const) (uploadToStorage|formatDateOnly|installFakeXhr)\b' -- mnemonicos-frontend/src mnemonicos-frontend/tests` → exatamente 3 linhas, uma por símbolo, em `src/lib/upload-to-storage.ts`, `src/lib/format-library.ts` e `tests/support/fake-xhr.ts` (nenhum arquivo novo ou alterado por esta TASK redefine os helpers).
- [ ] Sem `@utility` nem `var(--tw-*)` escritos à mão (lição `utility-escrito-m-o-no-tailwind-4-nunca-referencia-var-tw-a-custom-property-s-existe-quando-um-utilit-rio-nativo-a-registra`) — verificação executável: `git diff --unified=0 BASE_SHA..HEAD -- mnemonicos-frontend/src | grep -E '^\+.*var\(--tw-'` → saída vazia (`BASE_SHA` = commit-pai da TASK capturado no baseline do developer, não a branch default).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only main...HEAD`, lista não vazia que inclui os arquivos do Inclui), produção e teste — `npm --prefix mnemonicos-frontend run lint`, `npm --prefix mnemonicos-frontend run typecheck` e `npm --prefix mnemonicos-frontend run format:check` → saída 0 nos três; e a suíte inteira `npm --prefix mnemonicos-frontend test` sem falhas novas frente à baseline capturada antes de começar.

## Roteiro do gate 9 (fixado ANTES do código)

Carregador real, MinIO local e o servidor decidindo a aceitação (item k).

**Ambiente, sujeito e Passo 0**: os da TASK-063-005 (Postgres e MinIO via `db:up`, migração via `db:deploy`, `.env` do backend com `OBJECT_STORAGE_*` e `CORS_ORIGINS`, backend em `http://localhost:3333`, frontend em `http://localhost:3000`; login pelo formulário `/login`, sem o gesto de credencial por script negado nos handoffs 046 e 049; negado → `pendente_handoff`). O probe `probe-env.sh --realm editor` hoje devolve `credencial_placeholder` (formato do realm em `keelson.local.json` é ambiente do Diretor: não editar nem ler valores): probe com falha ou login negado → `pendente_handoff` com este Roteiro como seed (caminho padrão); alternativa: o Diretor loga manualmente num perfil de browser persistente. O ambiente sobe por `quality.boot`; o MinIO só existe após a TASK-063-002. URL do passo: `http://localhost:3000/pdf-library`; realm `editor`, que é o autor do PDF montado abaixo (Substituir e Remover exigem autor ou ADMIN).

**Pré-condição com receita** (montar):
1. Acervo vazio (`SELECT count(*) FROM library_pdfs;` = 0 no `npm --prefix mnemonicos-backend run db:psql`) e nenhum Pacote chamado "Pacote A" ou "Pacote B" (`SELECT count(*) FROM sales_packages WHERE name IN ('Pacote A','Pacote B');` = 0).
2. Duas fixtures com conteúdo distinto, em `d=$(mktemp -d)`: `printf '%%PDF-1.4\n%% fixture A\n%%%%EOF\n' > "$d/tira-a.pdf"` e `printf '%%PDF-1.4\n%% fixture B diferente\n%%%%EOF\n' > "$d/tira-b.pdf"`; registrar `sha256sum "$d/tira-a.pdf" "$d/tira-b.pdf"` (os dois digests diferem).
3. Pela própria tela (fluxo da TASK-063-005), enviar `tira-a.pdf` como Título "Tira 063-006", Versão "v1", Data de fechamento legislativo 01/10/2026.

**Restauro** (ao fim, nesta ordem): `DELETE FROM sales_packages WHERE name IN ('Pacote A','Pacote B');` (os Itens saem em cascata) e depois remover o PDF "Tira 063-006" PELA TELA (agora com o botão Remover); conferir `SELECT count(*) FROM library_pdfs;` = 0 e `SELECT count(*) FROM sales_packages;` = 0 (a TASK-063-011 exige o Acervo vazio no passo 0 dela). Objetos órfãos no bucket local são aceitos.

**Passos** (um por AC e por exemplo nomeado):
1. AC-061-007 e AC-061-027 (parte tela; o servidor e o storage decidem): obter a URL antiga (URL_antiga, válida por 300 s) via `page.request` em `GET …/download` (rota `/api/v1/pdf-library/<id>/download`, via `browser_run_code_unsafe`), sem depender de copiar do painel de rede. Clicar "Substituir", escolher `tira-b.pdf`, manter Versão e Data pré-preenchidas, confirmar a frase de que o arquivo anterior deixa de existir. Esperado: a lista mostra o autor e a data da substituição; "Baixar" entrega um arquivo com o `sha256sum` de `tira-b.pdf` (e não o de `tira-a.pdf`), capturado por `page.waitForEvent('download')` seguido de `download.saveAs('<scratchpad>/tira-baixada.pdf')` (via `browser_run_code_unsafe`) e conferido por `sha256sum <scratchpad>/tira-baixada.pdf`; e, repetido o `curl` logo após a substituição, DENTRO de 300 s da obtenção da URL_antiga, `curl -s -o /dev/null -w '%{http_code}' '<URL_antiga>'` responde 404 (NoSuchKey). O oráculo 404 NoSuchKey vale só para o MinIO local: um S3 real pode devolver 403. O `curl` é o observador que alcança o efeito, que o backend produz no storage e o painel de rede do navegador não vê; passados os 300 s a resposta seria 403 por assinatura vencida, o que NÃO prova a remoção, então o passo se refaz.
2. AC-061-010 (parte tela; o servidor decide): montar os Pacotes por SQL no `db:psql`, gravando o que o produto gravaria (colunas conforme a migração da TASK-063-001; o invariante dessas linhas pertence às TASKs 007 e 008 e entra na reconciliação do pacote do gate 9): `INSERT INTO sales_packages (id, name, "referencePriceCents", "authorId", "updatedAt") SELECT gen_random_uuid()::text, v.n, 4990, p."authorId", now() FROM library_pdfs p, (VALUES ('Pacote A'), ('Pacote B')) AS v(n) WHERE p.title = 'Tira 063-006';` e `INSERT INTO sales_package_items (id, "packageId", "pdfId", "position") SELECT gen_random_uuid()::text, s.id, p.id, 1 FROM sales_packages s, library_pdfs p WHERE s.name IN ('Pacote A','Pacote B') AND p.title = 'Tira 063-006';`. Na tela, "Remover" e "Confirmar remoção" no PDF "Tira 063-006". Esperado: a mensagem do servidor nomeia "Pacote A" e "Pacote B" no diálogo, o PDF permanece na lista e `SELECT count(*) FROM library_pdfs WHERE title = 'Tira 063-006';` segue 1.

## Riscos específicos

- Um endereço de download copiado fica válido por 300 s; o passo 1 depende de substituir e checar dentro dessa janela.
- A receita de SQL depende dos nomes de coluna da migração da TASK-063-001 (Prisma sem `@map` de coluna: camelCase entre aspas, como `"authorId"` em `visual-associations.service.ts:341`); coluna que mudar lá quebra o passo 2, e o developer reconfere no `schema.prisma` antes de executar.
- A restrição de autor-ou-ADMIN é conveniência de tela; quem nega de fato é o servidor (TASK-063-004).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
**Jira**: KAN-253

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
