# TASK-063-005: Tela do Acervo de PDFs: listar, enviar com progresso e baixar (com menu, prefixo e proxy)

**Slug**: producao-material
**Pertence a**: PLAN-063
**Realiza (FRs)**: FR-061-001, FR-061-002, FR-061-003, FR-061-005, FR-061-006, FR-061-012, FR-061-024, FR-061-026
**Funcionalidade**: FEAT-061-001 (primária)
**Componente**: COMP-063-006 (principal), COMP-063-007
**Wave**: 3
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-063-003
- **Bloqueia**: TASK-063-006

## Contexto

EDITOR e ADMIN passam a ter a rota `/pdf-library`, no menu, no prefixo interno e no `proxy.ts`, onde listam o Acervo, enviam um PDF (intenção no servidor, `PUT` direto ao storage com progresso, confirmação) e baixam o arquivo atual por endereço de 300 s. Território e molde: memo do `code-scout` (itens 6 e 11) e PLAN-063 §1 e §4; contrato servidor→tela: DTOs da TASK-063-003 e `mnemonicos-backend/src/http/middlewares/error-handler.ts:26-40,64-80`. O Guia de uso não é tocado aqui: guia: TASK-063-013.

## Escopo

### Inclui
- `mnemonicos-frontend/src/app/(interno)/pdf-library/page.tsx` (novo): casca Server Component com título "Acervo de PDFs" e `metadata`, molde `visual-library/page.tsx`.
- `mnemonicos-frontend/src/components/pdf-library-board.tsx` e `mnemonicos-frontend/src/components/pdf-upload-form.tsx` (novos, `'use client'`). Reusa o que já existe, sem criar equivalente: `BusyButton`/`BusyAnnouncement`/`LoadingArea` de `progress-indicator.tsx`, `RequiredLabelText` de `required-mark.tsx`, `isFetchBaseQueryError` de `src/lib/fetch-error.ts`, `useMeQuery` e `useListDisciplinesQuery` de `src/store/api.ts` (campo opcional "Disciplina"). O formulário pede Título, Versão e Data de fechamento legislativo (obrigatórios) e Prova/concurso e Disciplina (opcionais), mais o arquivo.
- `mnemonicos-frontend/src/lib/upload-to-storage.ts` (novo): `uploadToStorage`, `PUT` por `XMLHttpRequest` com progresso e `abort`; reusado pela TASK-063-006.
- `mnemonicos-frontend/src/lib/format-library.ts` (novo): `formatFileSize`, `formatDateOnly` (UTC, pt-BR) e `formatDateTime`. Decisão: duplicar — o formatter de `content-version-history.tsx:41` é privado ao componente e não se toca nele.
- `mnemonicos-frontend/src/store/api.ts`: tags `LibraryPdf` e `LibraryPdfList` em `TAG_TYPES`; endpoints `listLibraryPdfs`, `createPdfUploadIntent`, `confirmPdfUpload`, `getPdfDownloadLink` e seus hooks. O `PUT` ao storage fica FORA do `baseQuery`.
- `mnemonicos-frontend/src/lib/internal-routes.ts`: `'pdf-library'` ao fim de `INTERNAL_ROUTE_PREFIXES` (`internal-routes.ts:14`).
- `mnemonicos-frontend/src/lib/internal-nav.ts`: item `{ label: 'Acervo de PDFs', href: '/pdf-library', icon: 'pdf' }` ao FIM da lista (depois de "Usuários" para ADMIN) e `'pdf'` em `InternalNavIconName`.
- `mnemonicos-frontend/src/components/internal-nav-icons.tsx`: ícone `pdf`.
- `mnemonicos-frontend/src/proxy.ts`: `'/pdf-library'` e `'/pdf-library/:path*'` no matcher literal (`proxy.ts:97-106`).
- `mnemonicos-frontend/tests/support/fake-xhr.ts` (novo; dono único): `installFakeXhr()` / `FakeXMLHttpRequest` com progresso, `abort` e falha de rede; reusado pela TASK-063-006.
- Testes novos: `mnemonicos-frontend/src/components/pdf-library-board.test.tsx`, `mnemonicos-frontend/src/components/pdf-upload-form.test.tsx` e `mnemonicos-frontend/src/lib/upload-to-storage.test.ts`.
- Testes existentes cuja asserção exata muda (declarados):
  - `mnemonicos-frontend/src/lib/internal-nav.test.ts` (`EXPECTED_ITEMS` :9-13; contagens 3→4 para EDITOR e 4→5 para ADMIN em :51-52; C1b dos ícones);
  - `mnemonicos-frontend/src/lib/internal-routes.test.ts` (:53, lista de prefixos);
  - `mnemonicos-frontend/src/proxy.test.ts` (matcher e enumeração do diretório `(interno)`);
  - `mnemonicos-frontend/src/components/internal-sidebar.test.tsx` (`EXPECTED` :18-22, `ROUTES_TO_SECTION` :23-31 e o caso SB-default :83-91);
  - `mnemonicos-frontend/src/components/internal-shell.test.tsx` (`BASE_LINKS` :282-286, H5 :290 e `ALL` :349);
  - `mnemonicos-frontend/src/components/internal-shell.role-route.integration.test.tsx` (I2 :109 e :118).

### Não inclui
- Editar, substituir e remover PDF: TASK-063-006.
- Rotas `/packages` e o item "Pacotes": TASK-063-009.
- AC-061-008 (substituir por arquivo que não é PDF) e AC-061-014 (remoção: 3 estados da tela): TASK-063-006.
- `publication-export-control.tsx` e `content-version-history.tsx` (o formatter e o `triggerDownload` privados não se tocam; o `triggerDownload` compartilhado nasce na TASK-063-011).
- Alterar `visual-library-board.tsx` (molde só lido).
- Atualizar `docs/GUIA-DE-USO.md`: TASK-063-013.
- Busca ou filtro com debounce: esta TASK não tem campo de busca (busca sem debounce; a busca por Título é da TASK-063-011).
- Formatter de moeda (BRL): nasce na TASK-063-009 no mesmo `format-library.ts`.
- FR-061-011 (recusa de STUDENT e visitante): é do servidor (TASK-063-003); a tela só herda a barreira da casca interna.

## Critérios de pronto

- [ ] Lista (FR-061-005, FR-061-006), sem AC próprio: `PdfLibraryBoard` renderiza, por valor literal de uma fixture de `LibraryPdfSummary` com valores distintos por campo, Título, Versão, Data de fechamento legislativo em `dd/mm/aaaa`, tamanho (`formatFileSize`), nome do autor (`authorName`, nunca o `authorId`), data do envio e, só quando `replacedByName` existe, autor e data da substituição — verificação executável: `TZ=America/Sao_Paulo npm --prefix mnemonicos-frontend test -- src/components/pdf-library-board.test.tsx` → `Tests: N passed, 0 failed` (N > 0), incluindo `legislativeClosureDate: '2026-10-18'` exibido "18/10/2026" (jamais "17/10/2026") e `createdAt: '2026-10-18T15:30:00.000Z'` exibido "18/10/2026 12:30". Mutante em `git worktree add`: retirar `timeZone: 'UTC'` de `formatDateOnly` → o mesmo comando fica vermelho. Fixados por valor literal: `formatFileSize(1536)` = "1,5 KB", `formatFileSize(2621440)` = "2,5 MB", `formatFileSize(52428800)` = "50,0 MB".
- [ ] Download (FR-061-006), sem AC próprio: "Baixar" pede o endereço por `useLazyGetPdfDownloadLinkQuery` SEM reaproveitar cache (o endereço vale 300 s) e aciona um `<a>` com `href` igual ao endereço devolvido e atributo `download`; o teste espia `HTMLAnchorElement.prototype.click` e lê o `href` — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-library-board.test.tsx` → clicar "Baixar" duas vezes no mesmo PDF gera 2 requisições `GET /api/v1/pdf-library/<id>/download` no fake de rede e 2 cliques no `<a>`. Mutante em worktree: passar `preferCacheValue` verdadeiro ao `trigger` → só 1 requisição → vermelho.
- [ ] AC-061-013 (os 3 estados do envio; o progresso vem do `FakeXMLHttpRequest`) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-upload-form.test.tsx` → `Tests: N passed, 0 failed` (N > 0), com um caso por estado. Em andamento: após `loaded=512`, `total=1024` emitidos pelo fake, o botão "Enviar PDF" vira "Enviando" desabilitado (`BusyButton`, `aria-busy`) e existe elemento com papel `progressbar` cujo `aria-valuenow` é 50. Sucesso: a mensagem "PDF enviado com sucesso." e a lista JÁ MONTADA passa a conter o PDF novo, porque `confirmPdfUpload` invalida `LibraryPdfList` (tag do campo calculado de outro recurso, lição `campo-calculado-de-outro-recurso-invalida-a-tag-do-endpoint-que-o-exibe`). Falha: a mensagem do servidor é exibida e Título, Versão, Data, Prova/concurso e o nome do arquivo selecionado permanecem. Mutante em worktree: retirar `invalidatesTags` de `confirmPdfUpload` → o caso de sucesso fica vermelho.
- [ ] AC-061-013, anti-duplo-envio (lição `prova-de-corrida-exclus-o-nasce-na-fronteira-da-invariante-e-o-mutante-roda-pelo-comando-do-crit-rio`) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-upload-form.test.tsx` → com o envio em voo, pressionar Enter dentro do campo "Título" mantém 1 `POST /api/v1/pdf-library/uploads` e 1 `PUT` no fake; o canal aberto é o `submit` do formulário, não o botão. Mutante em worktree, pelo mesmo comando: remover o retorno antecipado do `onSubmit` enquanto ocupado (deixando só o `disabled` do botão) → o caso "Enter em voo" fica vermelho.
- [ ] AC-061-041 (estado vazio; régua de estados do `core/DESIGN.md`) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-library-board.test.tsx` → com a lista vazia a tela mostra a mensagem literal "Nenhum PDF no acervo ainda." e a ação "Enviar o primeiro PDF", cujo clique move o foco para o campo "Título" (`document.activeElement`). Os estados vizinhos NÃO mostram a mensagem de vazio: carregando mostra `LoadingArea` ("Carregando o acervo de PDFs"); erro do servidor (resposta 503 com o envelope de `error-handler.ts:64-80`) mostra a mensagem do servidor em `role="alert"` e a ação "Tentar novamente"; sem permissão (403 do servidor) mostra a mensagem do servidor em `role="alert"`, sem lista. Prova no componente montado contra a `api` real com `fetch` falso (lição `predicado-de-decis-o-de-ui-a-partir-de-estado-de-rtk-query-s-se-prova-no-componente-montado`); o controle é o erro, que não pode cair no vazio.
- [ ] Lista de tamanho não limitado (teto de leitura 200 da TASK-063-003; régua do `core/DESIGN.md`) e nome acessível único (lição `item-de-lista-que-renderiza-a-mesma-entidade-em-2-componentes-nascidos-na-mesma-wave-herda-a-corre-o-de-acessibilidade-j-aplicada-no-irm-o-can-nico-n-o-s-a-estrutura`) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-library-board.test.tsx` → a contagem visível ("2 PDFs no acervo" para a fixture de 2), o contêiner da lista com altura máxima e rolagem vertical (`classTokens` de `tests/support/class-tokens.ts` contém `max-h-` e `overflow-y-auto`) e, com 2 PDFs de MESMO Título e MESMA Versão, os botões `Baixar ...` têm 2 nomes acessíveis distintos (conjunto de tamanho 2; o nome inclui "item n de N"). Mutante em worktree: nome acessível só com Título e Versão → vermelho.
- [ ] Leitura fora do ramo de papel (lição `leitura-exigida-para-todo-papel-fica-fora-da-guarda-de-papel-da-acao`) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-library-board.test.tsx` → montada com `/auth/me` devolvendo EDITOR e depois ADMIN, a mesma lista e o botão "Baixar" aparecem nos dois papéis (2 casos); nenhum ramo desta tela lê o papel (a decisão por papel de Substituir e Remover nasce na TASK-063-006).
- [ ] AC-061-044 (parte tela: o PDF enviado por último aparece primeiro) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-library-board.test.tsx` → caso RTL em que o `fetch` falso devolve dois PDFs na ordem do servidor (o enviado por último primeiro); a tela os renderiza na ordem recebida do servidor, sem reordenar (nomes acessíveis "item 1 de 2" e "item 2 de 2" na ordem recebida). Mutante em worktree: ordenar no cliente por Título → vermelho.
- [ ] Uma só leitura fria (lição `refetchonmountorargchange-num-subscriber-secund-rio-gera-get-redundante-em-s-rie-na-carga-fria-n-o-s-na-revisita`) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-library-board.test.tsx` → ao montar a tela contra o `fetch` falso, `GET /api/v1/pdf-library` é chamado exatamente 1 vez após o carregamento terminar.
- [ ] AC-061-049 (aviso jurídico visível) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-library-board.test.tsx` → existe `role="note"` com o texto literal [proposto] "O sistema não atesta a revisão jurídica do PDF enviado; o conteúdo é responsabilidade de Produtos.", presente nos 4 estados da lista (carregando, erro, vazio, com itens), isto é, renderizado fora de qualquer ramo condicional. Mutante em worktree: mover o aviso para dentro do ramo "com itens" → os casos vazio e erro ficam vermelhos.
- [ ] AC-061-053 (parte Acervo; a parte Pacotes é da TASK-063-009) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/lib/internal-nav.test.ts src/components/internal-sidebar.test.tsx src/components/internal-shell.test.tsx src/components/internal-shell.role-route.integration.test.tsx` → `Tests: N passed, 0 failed` (N > 0). Por valor e pela ordem do DOM: EDITOR vê `['Painel','Conteúdos','Biblioteca visual','Acervo de PDFs']` e ADMIN `['Painel','Conteúdos','Biblioteca visual','Usuários','Acervo de PDFs']`, o item com `href` "/pdf-library" e ícone `pdf`; STUDENT vê `[]`; os 4 itens existentes mantêm posição e ordem relativa. Mutante em worktree: inserir o item novo antes de "Usuários" → o caso ADMIN fica vermelho; trocar o `href` → o caso EDITOR fica vermelho.
- [ ] Prefixo, proxy e ícone (consumidores por varredura, item d) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/lib/internal-routes.test.ts src/proxy.test.ts src/lib/internal-nav.test.ts` → `Tests: N passed, 0 failed` (N > 0): `INTERNAL_ROUTE_PREFIXES` é `['studio','content','visual-library','users','pdf-library']`; `requiredRoleForPath('/pdf-library')` e `requiredRoleForPath('/pdf-library/x')` são `'EDITOR'`; `matches('/pdf-library')` e `matches('/pdf-library/abc')` são verdadeiros e `matches('/pdf-libraryteca')` é falso; C7b encontra `page.tsx` real em `(interno)/pdf-library`; C1b acha o desenho `pdf` em `internal-nav-icons.tsx`. Mutantes em worktree: retirar `'/pdf-library/:path*'` do matcher → `proxy.test.ts` vermelho; remover `pdf` de `PATHS` → `npm --prefix mnemonicos-frontend run typecheck` falha (`Record<InternalNavIconName, ...>` exaustivo; `tsconfig.json` inclui `**/*.tsx`). Varredura dos consumidores do símbolo: `git grep -lE 'INTERNAL_NAV_ITEMS|navItemsForRole|INTERNAL_ROUTE_PREFIXES' -- mnemonicos-frontend/src` lista 13 arquivos na fixação: 5 de produção, 4 testes com asserção exata (no Inclui) e 4 testes que só leem o símbolo (`service-worker-policy.test.ts`, `manifest.test.ts`, `home.integration.test.ts` e `login-form.test.tsx`, que rodam no critério seguinte); os dois testes de casca (`internal-shell.test.tsx` e `internal-shell.role-route.integration.test.tsx`) leem os rótulos, não o símbolo, e também estão no Inclui.
- [ ] AC-061-012 (faceta de tela: visitante sem sessão em `/pdf-library` é levado ao login) — prefixo novo guardado no build real e leitores do símbolo — verificação executável: `npm --prefix mnemonicos-frontend test -- src/app/home.integration.test.ts -t 'H7: GET /pdf-library sem cookie'` → `Tests: 1 passed` (redireciona para `/login` com `next=/pdf-library`; o `next build` roda de verdade, então o `page.tsx` novo compila); e `npm --prefix mnemonicos-frontend test` (suíte inteira, baseline capturada antes de começar) → sem falhas novas, o que cobre `service-worker-policy.test.ts`, `manifest.test.ts` e `login-form.test.tsx`.
- [ ] AC-061-029 (parte tela: mensagens do servidor e da rede, em pt-BR, sem jargão) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-upload-form.test.tsx` → quatro casos. (1) Falha de rede no `PUT` (o fake dispara erro): a mensagem literal [proposto] "Não foi possível enviar o arquivo ao armazenamento. Verifique a conexão e use "Enviar PDF" para tentar de novo; se persistir, avise a equipe técnica (a origem do site pode não estar liberada no armazenamento)." (pista de CORS do TRISK-063-002; nomeia a ação real da tela, lição `mensagem-de-recusa-recuperavel-diz-o-proximo-passo-com-o-nome-da-acao-da-tela`). (2) AC-061-004 (envio sem Versão: a Versão é indicada como obrigatória) — resposta de validação do servidor no formato de `error-handler.ts:26-40` com `details: [{ path: 'version', message: ... }]`: a mensagem aparece junto ao campo "Versão", e o texto "VALIDATION_ERROR" não aparece na tela. (3) Recusa do servidor no envelope de `error-handler.ts:64-80` (ex.: código `BAD_REQUEST` na confirmação): a `message` do servidor é exibida em `role="alert"`. (4) Campo obrigatório vazio é recusado no cliente ("Informe o Título.", "Informe a Versão.", "Informe a Data de fechamento legislativo.", "Selecione um arquivo PDF.") sem nenhuma requisição.
- [ ] Contrato do `uploadToStorage` e do dublê (sem AC) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/lib/upload-to-storage.test.ts` → `Tests: N passed, 0 failed` (N > 0): resolve no sucesso 2xx; rejeita em erro de rede com `kind: 'network'` e em status fora de 2xx com `kind: 'http'`; `abort` rejeita com `kind: 'aborted'`; o progresso reportado é 0–100 (`loaded=512`, `total=1024` → 50); o corpo enviado é o próprio `File`, sem `FormData`. É o controle positivo do dublê: o `FakeXMLHttpRequest` dispara progresso, `abort` e falha de rede, e um fake que nunca emite progresso deixa o caso de progresso vermelho.
- [ ] `fetch` não carrega bytes de PDF (DEC-063-002), sem AC — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/pdf-upload-form.test.tsx` → no caso de sucesso, nenhuma chamada de `fetch` tem como URL o endereço pré-assinado (só o `XMLHttpRequest` falso a recebe) e o corpo do `POST /api/v1/pdf-library/uploads/confirm` não contém o arquivo.
- [ ] Sem `@utility` nem `var(--tw-*)` escritos à mão (lição `utility-escrito-m-o-no-tailwind-4-nunca-referencia-var-tw-a-custom-property-s-existe-quando-um-utilit-rio-nativo-a-registra`) — verificação executável: `git diff --unified=0 BASE_SHA..HEAD -- mnemonicos-frontend/src | grep -E '^\+.*var\(--tw-'` → saída vazia (`BASE_SHA` = commit-pai da TASK capturado no baseline do developer, não a branch default; as classes novas são utilitários nativos).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only main...HEAD`, lista não vazia que inclui os arquivos do Inclui), produção e teste — `npm --prefix mnemonicos-frontend run lint`, `npm --prefix mnemonicos-frontend run typecheck` e `npm --prefix mnemonicos-frontend run format:check` → saída 0 nos três.

## Roteiro do gate 9 (fixado ANTES do código)

Carregador real, com MinIO local e o servidor decidindo a aceitação (item k). ACs MUST de tela que o RTL prova ficam no gate 1; aqui só o que depende do servidor e do storage reais.

**Ambiente** (declarado aqui e citado pelas TASKs 006, 009, 011 e 012):
- Postgres e MinIO de pé: `npm --prefix mnemonicos-backend run db:up`.
- Migração aplicada: `npm --prefix mnemonicos-backend run db:deploy` (autorizada pelo Diretor para bancos locais de dev e de teste).
- `.env` local do backend com `OBJECT_STORAGE_*` copiado do `.env.example` (TASK-063-002) e `CORS_ORIGINS` contendo `http://localhost:3000`. É alteração de ambiente do Diretor: declarar no relatório de fecho qual arquivo mudou e para quê.
- Backend em `http://localhost:3333` (`npm --prefix mnemonicos-backend run dev`) e frontend em `http://localhost:3000` (`npm --prefix mnemonicos-frontend run dev`). Se o frontend subir em outra porta, a origem entra em `CORS_ORIGINS` do backend e no CORS do MinIO (lição do `CLAUDE.md`: o login falha calado sem isso).
- URL do passo: `http://localhost:3000/pdf-library`; realm `editor` (`keelson.local.json`).

**Sujeito concreto**: EDITOR do realm `editor`, com `username` e `password` no nível do realm em `keelson.local.json`. Passo 0 = login digitado no formulário `http://localhost:3000/login`, sem ecoar a senha em log ou relatório. Os handoffs 046 e 049 registram que o login por script (receita de credencial lida no navegador) foi negado pelo classificador do harness; este Roteiro NÃO herda aquele gesto. O que mudou desde aqueles registros é só a disponibilidade do MinIO local (TASK-063-002), que viabiliza o `PUT` real. Login negado ou formulário inalcançável → a TASK fecha `pendente_handoff`, com este Roteiro como handoff.

**Probe e ambiente**: o probe `probe-env.sh --realm editor` hoje devolve `credencial_placeholder` (o formato do realm em `keelson.local.json` é ambiente do Diretor: não editar nem ler valores). Probe com falha ou login negado → `pendente_handoff` com este Roteiro como seed (caminho padrão); alternativa: o Diretor loga manualmente num perfil de browser persistente. O ambiente sobe por `quality.boot`; o MinIO só existe após a TASK-063-002.

**Pré-condição com receita** (montar):
1. Acervo sem PDFs ao começar: contagem `0` em `npm --prefix mnemonicos-backend run db:psql` com `SELECT count(*) FROM library_pdfs;` (a TASK-063-011 exige o Acervo vazio no passo 0 dela).
2. Fixtures na hora, em diretório temporário `d` (`d=$(mktemp -d)`):
   - PDF válido: `printf '%%PDF-1.4\n1 0 obj\n<< /Type /Catalog >>\nendobj\ntrailer\n<< /Root 1 0 R >>\n%%%%EOF\n' > "$d/tira-direito-penal.pdf"`.
   - Texto renomeado: `printf 'isto nao e um pdf\n' > "$d/material.pdf"`.
   - PDF de 51 MiB (acima do teto de 50 MB, com a assinatura certa): `{ printf '%%PDF-1.4\n'; head -c 53477376 /dev/zero; } > "$d/grande.pdf"`.
3. Digest de referência do válido: `sha256sum "$d/tira-direito-penal.pdf"`.

**Restauro** (ao fim): a remoção por tela só nasce na TASK-063-006, então o restauro é por SQL no `db:psql`: `DELETE FROM library_pdfs WHERE title = 'Tira Direito Penal 063-005';` e conferir `SELECT count(*) FROM library_pdfs;` = 0. Os objetos do bucket local ficam órfãos (aceito: MinIO local descartável; `npm --prefix mnemonicos-backend run db:destroy` zera tudo).

**Passos** (um por AC e por exemplo nomeado):
1. AC-061-001 e AC-061-027 (parte tela; a parte backend é da TASK-063-003): em `/pdf-library`, enviar `tira-direito-penal.pdf` com Título "Tira Direito Penal 063-005", Versão "v1" e Data de fechamento legislativo 01/10/2026. Esperado: a linha aparece na lista com o título, "v1", "01/10/2026", o tamanho do arquivo, o nome do EDITOR como autor (o mesmo que `GET /api/v1/auth/me` devolve, visto no painel de rede) e a data do envio de agora; o painel de rede mostra `POST /api/v1/pdf-library/uploads`, o `PUT` ao host de `OBJECT_STORAGE_ENDPOINT` e `POST /api/v1/pdf-library/uploads/confirm`.
2. AC-061-002 (parte tela; o servidor decide): enviar `material.pdf` (texto renomeado) com os três campos preenchidos. Esperado: a mensagem de recusa do servidor aparece em `role="alert"` (o `POST .../uploads/confirm` responde recusa no painel de rede, observável porque é chamada do próprio navegador), a lista continua com 1 linha e `SELECT count(*) FROM library_pdfs;` segue 1.
3. AC-061-003 (parte tela; o servidor decide): enviar `grande.pdf` (51 MiB). Esperado: recusa informando o limite de 50 MB, sem nenhum `PUT` ao storage no painel de rede (a recusa vem da intenção) e a lista inalterada.
4. AC-061-005 (parte tela): clicar "Baixar" na linha de "Tira Direito Penal 063-005". Esperado: o painel de rede mostra `GET .../download` à API e depois o `GET` ao host de `OBJECT_STORAGE_ENDPOINT` (com CORS, sem erro); o arquivo baixado tem o mesmo `sha256sum` do passo 3 da receita. A captura do download é por `page.waitForEvent('download')` seguido de `download.saveAs('<scratchpad>/tira-baixada.pdf')`, via `browser_run_code_unsafe`, e o `sha256sum` roda nesse caminho (`sha256sum <scratchpad>/tira-baixada.pdf`), não numa "pasta de downloads".
5. AC-061-013 (progresso e falha reais; o servidor e o storage decidem): gerar na receita um PDF válido grande (~40 MiB: `{ printf '%%PDF-1.4\n'; head -c 41943040 /dev/zero; } > "$d/grande-valido.pdf"`) e enviá-lo com os três campos preenchidos, com o `PUT` atrasado por `page.route` (via `browser_run_code_unsafe`). Esperado: durante o `PUT` existe `progressbar` com `aria-valuenow` crescente e o botão "Enviar PDF" fica desabilitado. Depois, num segundo envio, `route.abort` no `PUT`: aparece a mensagem de falha e os campos preenchidos são preservados, sem linha nova na lista.

## Riscos específicos

- CORS do bucket mal configurado faz o `PUT` e o `GET` falharem calados no navegador (TRISK-063-002); por isso a mensagem de rede cita a possível causa e o Roteiro roda contra o MinIO com CORS do compose.
- O endereço de download expira em 300 s: reaproveitar resposta em cache entregaria endereço vencido (critério do `preferCacheValue`).
- `home.integration.test.ts` roda `next build` de verdade: uma `page.tsx` que não compila derruba esse teste, não só a tela.
- Os nomes dos campos de `PdfUploadIntent` e `PdfDownloadLink` vêm da TASK-063-003 (`mnemonicos-frontend/src/types/domain.ts`); o developer os lê lá antes de codar, sem redigitar de memória.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
**Jira**: KAN-252

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
