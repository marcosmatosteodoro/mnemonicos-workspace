# TASK-065-002: Atalho do seletor vazio para a Biblioteca visual, com volta segura

**Slug**: producao-material
**Pertence a**: PLAN-065
**Realiza (FRs)**: FR-064-025, FR-064-026
**Funcionalidade**: FEAT-064-004 (primária)
**Componente**: COMP-065-017 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-065-017

## Contexto

O EDITOR que abre o seletor "Vincular associação visual" com a Biblioteca visual vazia ganha um link de 1 clique até `/visual-library?returnTo=<tira>`, e lá um "Voltar para a tira" que só existe quando o `returnTo` passa por uma lista de permissão no servidor (open redirect, TRISK-065-007, CWE-601). Território e decisões: PLAN-065 COMP-065-017 e DEC-065-009; memo e `MAP.md` do slug (seção Biblioteca visual, F5).

**Raiz de execução**: os comandos rodam a partir de `Mnemonico/kan237/`, que contém `mnemonicos-backend/` e `mnemonicos-frontend/` (worktrees da branch do épico) e `docs/` (symlink para o workspace); os paths `mnemonicos-backend/…`, `mnemonicos-frontend/…` e `docs/…` desta TASK resolvem a partir dela.

## Escopo

### Inclui
- `mnemonicos-frontend/src/lib/safe-return-to.ts`: `parseSafeReturnTo(value: string | string[] | undefined): string | null` — só aceita `^/content/<uuid>/tira$`; rejeita `//`, `https://`, `\`, `javascript:`, vazio, array, query, fragmento e comprimento acima do limite (constante nomeada, valor não menor que o caminho válido). `mnemonicos-frontend/src/lib/safe-return-to.test.ts`.
- `mnemonicos-frontend/src/components/visual-association-picker.tsx`: no estado vazio sem filtro, link "Ir para a Biblioteca visual"; o destino é montado com `usePathname()` validado pelo MESMO `parseSafeReturnTo` (sem plumbing de prop pelo board, nenhuma edição em `mnemonic-strip-board.tsx`); sem pathname válido, o link vai à Biblioteca sem `returnTo`. A mensagem de vazio existente (visual-association-picker.tsx:16-17) é mantida.
- `mnemonicos-frontend/src/components/visual-association-list-states.tsx`: slot opcional `emptyAction?: ReactNode`, renderizado no estado vazio sem filtro. O board da Biblioteca (consumidor irmão) não passa o slot e continua igual.
- `mnemonicos-frontend/src/app/(interno)/visual-library/page.tsx`: Server Component lê `searchParams` (Promise no Next 16), valida com `parseSafeReturnTo` e renderiza "Voltar para a tira" na LINHA DO CABEÇALHO, ao lado do h1, no padrão de `content/[id]/tira/page.tsx:27-34` (`flex flex-wrap items-center justify-between gap-4`; link `link-hover text-sm font-medium text-link`) — só com valor validado; sem `returnTo` válido o cabeçalho fica só com o h1, igual ao commit-pai. (Retry pós-gate: achado médio do gate 11 da wave 1 + A1 do gate 1.)
- `mnemonicos-frontend/src/components/visual-library-board.tsx`: deixa de renderizar o link de volta e de receber `backHref` (a renderização vai para a página, Server Component — o valor nunca atravessa para o componente cliente); o estado vazio e o restante do board ficam como estão.
- `mnemonicos-frontend/src/components/visual-library-board.test.tsx` (retry): os casos da página (link de volta só com valor validado, no cabeçalho) moram neste arquivo; remover os casos que exercitavam a prop `backHref` do board (substituídos pelos da página).
- Testes: `mnemonicos-frontend/src/components/visual-association-picker.test.tsx` e `mnemonicos-frontend/src/components/visual-library-board.test.tsx` (casos novos; os casos da página, que é um Server Component `async`, entram neste segundo arquivo montando o elemento devolvido por `VisualLibraryPage`).

### Não inclui
- Cadastro de associação sobre a tira, sem sair do contexto (fora de escopo da SPEC-064, §4.2).
- Aviso de resolução no envio de imagem (TASK-065-010) e seção do Guia de uso (TASK-065-017).
- O indicador "N de M quadros com imagem" (TASK-065-003): é a mesma tela da tira, mas outro arquivo e outro comportamento.
- Qualquer edição de `mnemonic-strip-board.tsx`, `store/api.ts` ou `globals.css`.

## Critérios de pronto

- [ ] AC-064-020 é provado SÓ no gate 9, pelo Roteiro abaixo (aceitação que o servidor real decide: a página valida o `returnTo` no Server Component); os testes montados a seguir provam os elementos do Inclui, não o AC, e o Roteiro não os duplica.
- [ ] `parseSafeReturnTo` aceita só o padrão e é guard de navegação que devolve valor (lições `guard-de-destino-de-navega-o-valida-por-resolu-o-entrada-e-sa-da-com-prova-de-ponto-fixo`, TRISK-065-007) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/lib/safe-return-to.test.ts` → `OK (N tests)`, N > 0, com: aceita `/content/018f4d4a-1b1e-7c3a-8b1a-000000000001/tira` (uuid v7 do repo) e um uuid v4, devolvendo a própria string; devolve `null` para `//evil.example`, `//content/018f4d4a-1b1e-7c3a-8b1a-000000000001/tira`, `https://evil.example/content/018f4d4a-1b1e-7c3a-8b1a-000000000001/tira`, `/\evil.example`, `javascript:alert(1)`, string vazia, `undefined`, array `['/content/018f4d4a-1b1e-7c3a-8b1a-000000000001/tira']`, o caminho válido com `?x=1`, com `#frag`, com `/` final, com `\n` ou `\t` no fim e no meio, `/content/nao-e-uuid/tira` e uma string de 10 000 caracteres que começa com um caminho válido; uma asserção por eixo da regra (um caso por condição) e uma por caso simétrico aceito. Mutantes em worktree (`git -C mnemonicos-frontend worktree add <TMP>/mnemonicos-frontend HEAD`; a árvore principal nunca é editada), um por condição: remover o teste de tipo (array) → vermelho; remover o limite de comprimento → vermelho; afrouxar a regex para aceitar `//` → vermelho; afrouxar para aceitar query → vermelho.
- [ ] Ponto-fixo e idempotência do guard (mesma lição) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/lib/safe-return-to.test.ts` → `OK (N tests)`, N > 0; o arquivo cobre: para todo candidato aceito, `new URL(parseSafeReturnTo(x), origem).origin === origem` com pelo menos 2 origens distintas (`http://localhost:3000` e `https://app.exemplo.test`) e `parseSafeReturnTo(parseSafeReturnTo(x)) === parseSafeReturnTo(x)`. Falha se o guard devolver valor que, resolvido pelo parser WHATWG do consumidor, sai da origem.
- [ ] Inventário de produtores e consumidor do parâmetro `returnTo` (lição `par-metro-que-carrega-destino-estado-entre-telas-exige-invent-rio-de-todos-os-produtores-e-do-consumidor`) — verificação executável: `git -C mnemonicos-frontend grep -n 'returnTo' -- src ':!*.test.*' | grep -vE ':[0-9]+:\s*(//|\*|/\*)' | cut -d: -f1 | sort -u` → lista que contém `src/app/(interno)/visual-library/page.tsx` (único consumidor) e `src/components/visual-association-picker.tsx` (único produtor, o link do seletor vazio) e que não contém nenhum arquivo além desses dois e de `src/lib/safe-return-to.ts` (o guard, que só entra se o literal aparecer nele fora de comentário). Nenhum outro redirecionamento escreve o parâmetro. Falha se um produtor ou consumidor novo escapar do guard. (Controle positivo: o comando, rodado com o padrão `parseSafeReturnTo` em vez de `returnTo`, acha o picker, a página e o guard (o board deixou de validar no retry pós-gate), provando que o universo `src` é lido.)
- [ ] O seletor vazio oferece o link, com o destino validado, e só nesse estado — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/visual-association-picker.test.tsx` → `OK (N tests)`, N > 0, com `next/navigation` mockado (`usePathname`): (1) vazio sem filtro e pathname `/content/018f4d4a-1b1e-7c3a-8b1a-000000000001/tira` → a mensagem de visual-association-picker.tsx:16-17 continua visível E `getByRole('link', { name: 'Ir para a Biblioteca visual' })` tem `href` exatamente `/visual-library?returnTo=%2Fcontent%2F018f4d4a-1b1e-7c3a-8b1a-000000000001%2Ftira`; (2) pathname `null`, `/content` e `//evil.example/content/018f4d4a-1b1e-7c3a-8b1a-000000000001/tira` → `href` exatamente `/visual-library`, sem `returnTo`; (3) vazio COM filtro (mensagem `visualAssociationsEmptyMessageFiltered`), lista com itens, carregando e erro → nenhum link `Ir para a Biblioteca visual` (controle positivo no mesmo arquivo: o caso (1) acha o link). `getAllByRole('link', { name: 'Ir para a Biblioteca visual' })` tem `length` 1 no estado vazio (lição `item-de-lista-que-renderiza-a-mesma-entidade-em-2-componentes-nascidos-na-mesma-wave-herda-a-corre-o-de-acessibilidade-j-aplicada-no-irm-o-can-nico-n-o-s-a-estrutura`: picker e Biblioteca renderizam a mesma entidade, e o nome acessível do atalho é único). O estado vazio orienta o próximo passo: o link aparece junto da mensagem existente, não a substitui (estado vazio, régua de estados do `core/DESIGN.md`). Mutante em worktree: renderizar o slot também no vazio com filtro → o caso (3) sai vermelho.
- [ ] O atalho não depende de papel (lição `leitura-exigida-para-todo-papel-fica-fora-da-guarda-de-papel-da-acao`) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/visual-association-picker.test.tsx` → `OK (N tests)`, N > 0; o arquivo cobre: o caso (1) roda com `makeStore()` limpo, sem resposta de sessão (`/auth/me`) no fake de rede, e o link está presente; a Biblioteca visual é de alcance EDITOR e ADMIN (MAP.md, entrada F5, leitura comum), então nenhum ramo de papel envolve o link nem o "Voltar para a tira".
- [ ] O slot `emptyAction` só aparece onde é passado — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/visual-library-board.test.tsx` → `OK (N tests)`, N > 0, com o acervo vazio sem filtro: a mensagem de vazio do board continua e `queryByRole('link', { name: 'Ir para a Biblioteca visual' })` é `null` (o board não passa o slot; controle positivo é o caso (1) do seletor). Mutante em worktree: default não vazio em `emptyAction` de `visual-association-list-states.tsx` → este caso sai vermelho.
- [ ] A página só renderiza o link de volta com valor validado (TRISK-065-007, DEC-065-009; achado A1 do gate 1 da wave 1) — verificação executável: `npm --prefix mnemonicos-frontend test -- src/components/visual-library-board.test.tsx` → `OK (N tests)`, N > 0 (os casos da página moram nesse arquivo, onde já estavam; alinhado pelo Tech Lead após o re-gate); o teste chama `await VisualLibraryPage({ searchParams: Promise.resolve({ returnTo }) })`, renderiza o resultado e afirma: para TODO valor que o guard rejeita (condição; ilustração não-exaustiva: `//evil.example`, `https://evil.example/content/<uuid>/tira`, `javascript:alert(1)`, `/content/<uuid>/tira?x=1`, o array `[TIRA, "//evil.example"]`, ausente) não existe link de nome "Voltar para a tira" — `queryByRole("link", { name: "Voltar para a tira" })` → `null`; para o válido existe exatamente 1, com `href` = TIRA, e ele está no mesmo contêiner do h1 "Biblioteca visual" (ordem do DOM: h1 antes do link) — asserção própria: `links[0].parentElement` é o `parentElement` do heading de nível 1 e `heading.compareDocumentPosition(link) & Node.DOCUMENT_POSITION_FOLLOWING`; mutantes de posição (link movido para depois do board; h1 depois do link) ficam vermelhos (achado B1 do re-gate). Par de provas: o mutante `const backHref = returnTo as string | undefined;` em page.tsx (no worktree) deixa vermelho ao menos um caso hostil; o caso válido segue verde com o guard intacto. `visual-library-board.test.tsx` perde os casos de `backHref` (a prop não existe mais) — listados no Inclui deste retry.
- [ ] Os links usam o vocabulário visual já existente, sem utilitário novo (lição `utility-escrito-m-o-no-tailwind-4-nunca-referencia-var-tw-a-custom-property-s-existe-quando-um-utilit-rio-nativo-a-registra`) — verificação executável: `git -C mnemonicos-frontend diff --name-only <SHA-pai-da-TASK>..HEAD -- src/app/globals.css` → vazio (o arquivo existe no commit-pai); o link do seletor usa `link-hover text-sm text-link` (como content-form.tsx:496) e o "Voltar para a tira" do cabeçalho usa `link-hover text-sm font-medium text-link` (padrão de content/[id]/tira/page.tsx:27-34, retry pós-gate 11); `npm --prefix mnemonicos-frontend test -- src/lib/no-underline.test.ts` → `OK (N tests)` (varredura de `src/` sem a classe `underline`).
- [ ] O estado do RTK Query do seletor segue provado no componente montado (lição `predicado-de-decis-o-de-ui-a-partir-de-estado-de-rtk-query-s-se-prova-no-componente-montado`) — verificação executável: os casos acima montam `VisualAssociationPicker` contra a `api` real (`makeStore()` + `fetch` mockado), sem mockar `useListVisualAssociationsQuery`; `npm --prefix mnemonicos-frontend test -- src/components/mnemonic-strip-board.test.tsx` → `OK (N tests)` com o mesmo número de testes passando do baseline capturado antes de começar (a suíte monta o seletor dentro do board e o `usePathname` sem provider devolve `null`, então o link sai sem `returnTo` e nada mais muda).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git -C mnemonicos-frontend diff --name-only main...HEAD`), produção e teste — verificação executável: `npm --prefix mnemonicos-frontend run lint`, `npm --prefix mnemonicos-frontend run typecheck` e `npm --prefix mnemonicos-frontend run format:check` → exit 0.

## Roteiro do gate 9 (fixado ANTES do código)

Handoffs anteriores lidos (`docs/producao-material/handoffs/`): HANDOFF-PLAN-046 e HANDOFF-PLAN-049 registraram o exercício autenticado como não realizado por `permissao_ambiente` (o login por `context.request` com a senha do realm foi negado pelo classificador). Não vira passo por herança: a receita `context.request` não é repetida; o exercício autenticado usa o caminho que aqueles registros apontaram — login manual do Diretor na janela do navegador ou autorização por regra de permissão para ler o realm. Nada mudou no ambiente desde aquele registro; sem uma das duas saídas, o gate sai `pendente_handoff` com este Roteiro.

**Ambiente**
- Postgres dedicado do épico no ar (127.0.0.1:5433, container `mnemonicos-db-kan237`; o `.env` do worktree do backend já aponta para ele). Backend e frontend são os dos worktrees `kan237/mnemonicos-backend` (`npm --prefix mnemonicos-backend run dev`) e `kan237/mnemonicos-frontend` (`npm --prefix mnemonicos-frontend run dev`), cada um em porta livre (backend 3333 ou 3334…, frontend 3000 ou 3001…), com `BACKEND_API_URL` do frontend apontado para o backend subido. A origem do frontend entra em `CORS_ORIGINS` do `.env` do backend do worktree (senão o login falha calado); isso é alteração de ambiente do Diretor e vai declarada no relatório de fecho. As URLs abaixo usam 3000 para o frontend; troque pela porta real.
- Rotas: `http://localhost:3000/login`, `http://localhost:3000/content/<id>/tira` e `http://localhost:3000/visual-library`.

**Sujeito**: EDITOR, realm `editor` de `keelson.local.json` (login pelo formulário de `/login`; a senha não é gravada em arquivo, log nem relatório). Nenhuma conta nova é criada. O Conteúdo da pré-condição é criado por esse EDITOR.

**Pré-condição com receita** (montar):
1. Biblioteca vazia: `npm --prefix mnemonicos-backend run db:psql` e `SELECT count(*) FROM visual_associations;` → `0` (acervo de dev medido sem associações pelo memo do slug). Se a contagem não for 0, não apagar nada: interceptar só `GET /api/v1/visual-associations` com `route.fulfill` devolvendo o envelope que o seletor lê (`{"data": []}`, conferido contra uma resposta real no painel de rede antes). A interceptação cobre apenas o estado vazio; a validação do `returnTo` acontece no Server Component real do Next, que não é interceptado em nenhum passo.
2. Conteúdo com Tira de pelo menos 1 Quadro, criado pelo EDITOR pelas telas existentes: `/content/new` (campos obrigatórios do formulário) → Quebra da regra em `/content/<id>/breakdown` → link para a Tira. Anotar o `<id>` da URL `/content/<id>/tira`.

**Restauro** (ao fim): remover pelo botão de remoção da tela do Conteúdo o Conteúdo criado e confirmar que `SELECT count(*) FROM visual_associations;` segue `0`; desfazer a interceptação de rede, se usada.

**Passos** (um por AC e por exemplo nomeado):
0. Identidade do servidor (antes de qualquer outro passo): provar que os servidores servidos são os do épico: o cwd do processo do backend e o do frontend (`readlink /proc/<pid>/cwd`) é `kan237/mnemonicos-backend` e `kan237/mnemonicos-frontend`, e `git -C mnemonicos-backend branch --show-current` (a partir de `Mnemonico/kan237/`) e o equivalente do frontend devolvem a branch do épico. Servidor de outra árvore invalida o Roteiro inteiro.
1. AC-064-020, parte "link em 1 clique": logado como `editor`, abrir `http://localhost:3000/content/<id>/tira` e clicar "Vincular associação visual" no 1º Quadro. Esperado: o seletor mostra a mensagem de vazio ("Nenhuma associação visual no acervo ainda…") e o link "Ir para a Biblioteca visual"; um clique nele leva a `http://localhost:3000/visual-library?returnTo=%2Fcontent%2F<id>%2Ftira`, com o título "Biblioteca visual".
2. AC-064-020, parte "consegue voltar": nessa página, clicar "Voltar para a tira". Esperado: a URL passa a ser `http://localhost:3000/content/<id>/tira`, a mesma Tira com os mesmos Quadros.
3. `returnTo` hostil digitado na barra (cada exemplo é um cenário; TRISK-065-007): abrir, um por vez, `http://localhost:3000/visual-library?returnTo=//evil.example`, `http://localhost:3000/visual-library?returnTo=https://evil.example/content/<id>/tira`, `http://localhost:3000/visual-library?returnTo=javascript:alert(1)`, `http://localhost:3000/visual-library?returnTo=/content/<id>/tira%3Fx%3D1` e `http://localhost:3000/visual-library?returnTo=/content/<id>/tira&returnTo=//evil.example`. Esperado em cada um: a Biblioteca abre na própria URL digitada (sem redirecionamento automático), não há "Voltar para a tira" e o DOM não tem nenhum `<a>` cujo `href` contenha `evil.example` ou comece por `javascript:` (conferido por snapshot do DOM, que é onde o Server Component entrega o `href`).
4. `returnTo` válido digitado direto (o link de volta não depende do seletor): abrir `http://localhost:3000/visual-library?returnTo=/content/<id>/tira`. Esperado: "Voltar para a tira" presente, com o mesmo destino do passo 2.

## Riscos específicos

- Open redirect (CWE-601): o valor cru nunca vai a `href`, e a lista de permissão é o padrão fechado; o gate 8 revisa o guard. O controle é a prova de ponto-fixo e a revalidação no board.
- `usePathname()` devolve `null` fora do app router (testes e SSR sem contexto): o link cai para `/visual-library` sem `returnTo`, comportamento declarado e testado.
- `searchParams` é uma Promise no Next 16 e `returnTo` pode chegar como `string | string[]`: a página é `async` e o guard rejeita array.
- Lições casadas por caminho e sem objeto nesta TASK: `mensagem-de-recusa-recuperavel-diz-o-proximo-passo-com-o-nome-da-acao-da-tela` (nenhum texto de recusa novo; o link e o vazio já orientam o próximo passo) e `campo-calculado-de-outro-recurso-invalida-a-tag-do-endpoint-que-o-exibe` (nenhum campo calculado exibido).
- Gate 8 (open redirect). Gate 9 só para AC-064-020, conforme o Roteiro.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-10-18T02:48:17-0300
**Data conclusão**: 2026-10-18T08:15:38-03:00
**Commit SHA**: ad563b2
**Jira**: KAN-262

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 1, delta do retry incluso)
- [x] Comportamento (gate 9): consolidado (FEAT-064-004)
<!-- Branch, tentativas, arquivos, revisores e narrativa (retries, escalações) vivem no
ledger da sessão e no commit da closure (4.76) — não se repetem aqui (4.409). -->
