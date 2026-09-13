# TASK-023-012: `visual-library-board.tsx` — client component de CRUD do acervo

**Slug**: producao-material
**Pertence a**: PLAN-023
**Realiza (FRs)**: FR-022-005, FR-022-006, FR-022-009, FR-022-010, FR-022-011, FR-022-012, FR-022-022, FR-022-025
**Funcionalidade**: FEAT-022-001 (primária), FEAT-022-002, FEAT-022-003
**Componente**: COMP-023-014 (principal)
**Wave**: 4
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch do EPICO MNEMORA STUDIO, Estrategia unica -- decisao 4.126: F5 e uma fatia do epico, nunca abre branch propria; a sessao ja fez o sync de largada nela)

**Padrão de commit**: Conventional Commits (`commit.convention: "conventional"`) — `feat:`,
ex.: `feat(producao-material): board de gestao do acervo de associacoes visuais`.
**Framework de teste**: Jest 30 (`next/jest`) + Testing Library (`@testing-library/react`,
`@testing-library/user-event`), componente montado contra `makeStore()` + `Provider` + `fetch`
mockado (harness `test/jsdom-fetch-env.js`) — mesmo padrão de
`internal-shell.integration.test.tsx`/`mnemonic-strip-board.tsx` (`TASK-012-012`, lição
ativa citada abaixo).

## Dependências

- **Depende de**: TASK-023-007, TASK-023-009
- **Bloqueia**: TASK-023-015

## Contexto

TASK-023-007 entrega os endpoints RTK Query do acervo (`useListVisualAssociationsQuery`,
`useSuggestVisualAssociationCategoriesQuery`, `useCreateVisualAssociationMutation`,
`useUpdateVisualAssociationMutation`, `useRemoveVisualAssociationMutation`, PLAN §3
COMP-023-012) e TASK-023-009 entrega `visual-association-picker.tsx` (COMP-023-015,
já pronto — dependência declarada pelo PLAN para COMP-023-014, embora este board não precise
abrir o picker para o próprio CRUD: a tela É o acervo). Falta a tela de gestão em si —
client component que lista/filtra por categoria, faz upload (1º multipart do frontend,
`code-scout`: nenhum `<input type="file">`/`FormData` existe hoje em
`mnemonicos-frontend/src/`), sugere categoria ao digitar, edita in-place e remove (com
mensagem de bloqueio usando `reachableLinks`/`outOfReachCount` devolvidos pelo backend —
TASK-023-010). Molde estrutural mais próximo: `mnemonic-strip-board.tsx`
(`mnemonicos-frontend/src/components/mnemonic-strip-board.tsx:1-505`) — 3 estados por ação,
tokens de cor semântica, componente montado contra `api` real nos testes.

## Escopo

### Inclui

- `mnemonicos-frontend/src/components/visual-library-board.tsx` (novo) — `'use client'`,
  named export `VisualLibraryBoard` (sem props — a tela inteira do acervo, ao contrário do
  picker, que é embutido):
  - Filtro por categoria: `<input>` controlando o argumento `category` de
    `useListVisualAssociationsQuery` (estado do servidor via RTK Query — nenhum slice manual
    duplicando o que a query já resolve, `next-16.md`).
  - Listagem: cada associação renderizada com miniatura via `next/image` (`<Image
    src={`/api/v1/visual-associations/${id}/image`} width={48} height={48} unoptimized
    alt="" />` — mesmo componente/URL do picker, TASK-023-009: `unoptimized` porque o
    endpoint devolve o binário puro; `next/image` em vez de `<img>` cru para não disparar
    `@next/next/no-img-element` do `eslint-config-next/core-web-vitals`; URL com o
    prefixo `/api/v1` obrigatório, `rewrites()` de `next.config.ts:28`), categoria e
    `linkCount` (FR-022-012).
  - Formulário de criação: `<input type="file" accept="image/png,image/jpeg,image/webp">` +
    campos `category`/`cognitiveDescription` — submissão via `FormData` (RTK Query aceita
    `body: FormData` sem `Content-Type` manual, PLAN §3 COMP-023-012) chamando
    `useCreateVisualAssociationMutation`. Sugestão de categoria: o campo `category` do
    formulário dispara `useSuggestVisualAssociationCategoriesQuery({ q })` com um debounce
    simples (mesma técnica de segurar o disparo por um `setTimeout`/`useRef` já usada em
    outros formulários do frontend, se houver molde local; senão, implementação mínima
    própria, sem dependência nova) — FR-022-025.
  - Edição in-place: reusa o mesmo formulário (ou uma variação dele) para
    `useUpdateVisualAssociationMutation` (arquivo novo opcional — `PATCH` parcial).
  - Remoção: ação de remover chama `useRemoveVisualAssociationMutation`; em falha por 409
    (vínculo ativo), exibe `error.data.details.reachableLinks` (lista de
    `{ rawContentId, frameId }`) e `error.data.details.outOfReachCount` (TASK-023-010) —
    mensagem pt-BR, nunca genérica ("não foi possível remover" sem os dados devolvidos).
  - Três estados observáveis (em andamento/sucesso/falha) por AÇÃO (criar, editar, remover) —
    controle desabilitado + indicador `role="status"` durante a chamada, confirmação visível
    ao suceder, `role="alert"` ao falhar sem perder os dados já preenchidos no formulário
    (AC-022-005).
  - Cor semântica só por token do tema (`text-danger`/`text-link`/`text-muted`), nunca
    classe literal da paleta Tailwind (lição ativa citada abaixo).
- `mnemonicos-frontend/src/components/visual-library-board.test.tsx` (novo) — montado com
  `makeStore()` real + `fetch` mockado; contrato do próprio componente (ver Critérios de
  pronto — os ACs de negócio desta TASK fecham no gate 9, não aqui).

### Não inclui

- A rota `/visual-library` em si (Server Component casca) — TASK-023-015.
- O seletor embutido `visual-association-picker.tsx` em si — já pronto (TASK-023-009), não
  é consumido diretamente por este board (o board É a listagem completa, não um seletor).
- A chamada de vínculo/desvínculo a um Quadro — TASK-023-013 (enxerto em
  `mnemonic-strip-board.tsx`).
- Backend de listagem/busca/sugestão (`listVisualAssociations`/
  `listVisualAssociationCategories`/`suggestCategories`) — TASK-023-014.
- A entrega do binário da imagem (`GET .../:id/image`) — TASK-023-016; este board só
  consome a URL como `src` de `<img>`.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Reaproveitar os hooks de `store/api.ts` (TASK-023-007) — nenhuma chamada `fetch` direta
   fora do client RTK Query.
2. Montar o formulário de upload com `FormData` nativo (sem lib nova) — `category`/
   `cognitiveDescription` como campos de texto, `image` como o arquivo; RTK Query serializa
   automaticamente (PLAN §3, COMP-023-012).
3. Sugestão de categoria: debounce simples (ex.: `useRef` guardando o último `setTimeout`,
   limpo no próximo keystroke) — sem dependência nova; o RTK Query já deduplica por cache-key
   se a mesma `q` repetir.
4. Remoção: capturar o corpo de erro 409 (`error.data.details`) do resultado `unwrap()`
   rejeitado, exibindo `reachableLinks`/`outOfReachCount` — nunca só "erro genérico".
5. Cores semânticas: `text-danger` (falha), `text-link` (ações de navegação/edição),
   `text-muted` (indicador em andamento) — nenhum literal `text-red-*`/`text-green-*`.

## Critérios de pronto

- [ ] Contrato do próprio componente (sem AC de negócio fechado aqui — todos os ACs desta
      TASK fecham no "Roteiro do gate 9" abaixo, conforme o manifesto congelado desta
      decomposição): `VisualLibraryBoard` renderiza sem lançar exceção com uma resposta
      mockada de `useListVisualAssociationsQuery` contendo 0, 1 e N itens (3 casos) —
      exercitado no componente MONTADO (`makeStore()` + `fetch` mockado), nunca por
      predicado extraído isolado (lição "[Testes] Predicado de decisão de UI a partir de
      estado de RTK Query só se prova no componente montado", `guidelines/project/
      lessons.md` — mesma aplicação de TASK-012-012/TASK-023-009). Verificação executável:
      `npx jest --runTestsByPath src/components/visual-library-board.test.tsx` (cwd
      `mnemonicos-frontend`; molde/exemplar de convenção —
      `src/components/mnemonic-strip-board.test.tsx`, que já roda com o mesmo padrão de
      comando trocando o caminho — arquivo-alvo ainda não existe, comando roda contra o
      molde na fixação) → `PASS ... Tests: N passed, N total`.
- [ ] **Testes cobrem AC-022-005 (3 estados observáveis) em unidade — gate 1, não só gate 9**
      (correção do Tech Lead na consolidação: MUST testável em componente montado não pode
      fechar só no gate 9, que confirma mas não substitui o teste, régua do contrato de
      `/keelson:tasks`): componente MONTADO (`makeStore()` + `fetch` mockado com latência
      controlada/interceptada — nunca depender de timing real) exercitando a mutação de
      criação: (a) durante a requisição em voo, o controle de salvar fica desabilitado e um
      indicador visível aparece; (b) resposta de sucesso mockada → mensagem de confirmação
      visível; (c) resposta de erro mockada → mensagem de erro visível E os dados já
      preenchidos no formulário permanecem (nenhum reset). Verificação executável: `npx jest
      --runTestsByPath src/components/visual-library-board.test.tsx` (cwd
      `mnemonicos-frontend`) → `PASS`, com os 3 cenários nomeados no relatório de teste
      (`it.each` ou 3 `it` distintos, nunca 1 teste que só afirma "não lança exceção").
- [ ] **Testes cobrem AC-022-010 (filtro por categoria) em unidade — gate 1** (achado do
      `qa` pré-código: mesma generalização da correção acima — MUST testável não pode
      fechar só no gate 9): componente MONTADO com resposta mockada de 2+ categorias;
      alterar o valor do filtro e confirmar, via nova chamada mockada de
      `useListVisualAssociationsQuery` com o argumento `category` correspondente, que a
      lista renderizada mostra só os itens da categoria filtrada. Verificação executável:
      mesmo comando acima → `PASS`, cenário nomeado.
- [ ] **Testes cobrem AC-022-022 (sugestão de categoria ao digitar) em unidade — gate 1**
      (mesmo achado do `qa`): componente MONTADO, digitar no campo de categoria dispara
      `useSuggestVisualAssociationCategoriesQuery({ q })` (fetch mockado) e as sugestões
      mockadas aparecem na UI (lista/`datalist`) — mesmo padrão de mount+mock já usado nos
      demais critérios desta TASK. Verificação executável: mesmo comando → `PASS`, cenário
      nomeado.
- [ ] Cor semântica (lição "[Design] Cor semântica de texto vem de token do tema, nunca de
      literal da paleta"): `grep -nE "text-(red|green|blue|yellow|orange|purple|pink)-[0-9]"
      src/components/visual-library-board.tsx` (cwd `mnemonicos-frontend`) → esperado vazio;
      `grep -c "text-danger" src/components/visual-library-board.tsx` → esperado `>= 1`
      (usado no estado de falha).
- [ ] Formulário de upload usa `FormData` nativo — `grep -n "FormData" src/components/
      visual-library-board.tsx` → ao menos 1 ocorrência; nenhuma dependência nova em
      `package.json` (`git diff package.json` vazio, ou só `package-lock.json` sem entrada
      nova de produção).
- [ ] Todo texto visível (rótulos, mensagens de estado, mensagem de bloqueio de remoção) está
      em português do Brasil — verificação por leitura manual do arquivo, mesma régua de
      `TASK-012-003`/`TASK-023-003`.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npx eslint src/components/visual-library-board.tsx
      src/components/visual-library-board.test.tsx` (cwd `mnemonicos-frontend`) → 0
      problemas.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil `next-16.md` — Client Component só onde
      há estado/evento, estado de servidor 100% via RTK Query.
- [ ] Code review aprovado.

## Roteiro do gate 9 (fixado ANTES do código)

Nenhum handoff anterior do slug (`docs/producao-material/handoffs/` — `HANDOFF-PLAN-003.md`
e `HANDOFF-PLAN-013.md`, nenhum sobre a Biblioteca visual) registra qualquer cenário desta
TASK como não-exercitável — roteiro novo, sem herança.

**Ambiente**: backend (`mnemonicos-backend/`) e frontend (`mnemonicos-frontend/`) de pé
localmente — `npm run db:up && npm run db:deploy && npm run db:seed && npm run dev`
(backend, API em `http://localhost:3333/api/v1`) e `npm run dev` (frontend,
`http://localhost:3000`) — mesma receita de `HANDOFF-PLAN-003.md` §3. Tela alvo:
`http://localhost:3000/visual-library` (a rota em si nasce só em TASK-023-015 — este roteiro
pressupõe as duas TASKs já implementadas juntas, mesma prática de dependência
`Bloqueia`/`Depende de` desta wave; se `/visual-library` ainda não existir no momento da
verificação, execute este roteiro só após TASK-023-015 fechar).

**Sujeito concreto**: EDITOR de teste (realm `editor` de `keelson.local.json`:
`loginPath: "/login"`, `username: "editor@mnemonicos.local"`, senha conforme o arquivo —
já provisionado, nunca chutar) e o ADMIN semeado (`admin@mnemonicos.local`, senha via
`SEED_ADMIN_EMAIL`/`SEED_ADMIN_PASSWORD` do `.env` local do backend — nunca literal aqui;
**gap declarado**: `keelson.local.json` hoje só tem os realms `app`/`editor` —
`screenVerify.realms.admin` não existe; a pré-condição abaixo usa a sessão ADMIN só via
`curl`/API direta, não via login na UI, então o gap não bloqueia este roteiro, mas fica
registrado como pendência de configuração — ver `duvidas`).

**Pré-condição (montar)**: duas associações visuais de categorias diferentes, e um vínculo
que produza tanto `reachableLinks` quanto `outOfReachCount` > 0 para o EDITOR de teste (para
exercitar o passo de AC-022-019 abaixo):

1. Login como EDITOR para obter o cookie de sessão:
   ```
   curl -c /tmp/vlb-gate9-editor.txt -X POST http://localhost:3333/api/v1/auth/login \
     -H 'Content-Type: application/json' \
     -d '{"email":"editor@mnemonicos.local","password":"<senha do realm editor>"}'
   ```
2. Criar uma associação visual como o EDITOR (fixture PNG real de poucos bytes — usar a
   mesma amostra capturada citada por TASK-023-008, nunca gerada a partir de prosa):
   ```
   curl -b /tmp/vlb-gate9-editor.txt -X POST http://localhost:3333/api/v1/visual-associations \
     -F "image=@/caminho/para/fixture.png" -F "category=Fixture Gate 9" \
     -F "cognitiveDescription=Imagem de teste do roteiro de gate 9."
   ```
   → anotar `<associationId>`.
3. Vincular essa associação a um Quadro de um Conteúdo bruto de autoria do PRÓPRIO EDITOR
   (alcançável) — depende de TASK-023-011 (link) já implementada; se ainda não estiver,
   registrar como não-exercitável nesta rodada e revisitar (decisão 4.107 — não simular o
   mecanismo ausente).
4. Vincular a MESMA associação a um Quadro de um Conteúdo bruto de autoria do ADMIN semeado
   (fora do alcance do EDITOR) — login como ADMIN via `SEED_ADMIN_EMAIL`/`SEED_ADMIN_PASSWORD`
   e repetir o vínculo sobre um Quadro do acervo semeado (`seed-material.ts:87`, autoria
   ADMIN) — produz o vínculo que aparece só em `outOfReachCount` quando o EDITOR tenta
   remover.

**Restaurar ao fim**: `DELETE FROM visual_association_link_events WHERE
"visualAssociationId" = '<associationId>';` seguido de `UPDATE mnemonic_frames SET
"visualAssociationId" = NULL WHERE "visualAssociationId" = '<associationId>';` e `DELETE
FROM visual_associations WHERE id = '<associationId>';` (via `npm run db:psql` em
`mnemonicos-backend/`) — nunca apagar a tabela inteira.

**Passos (um por AC)**:

1. **AC-022-005**: na UI (`http://localhost:3000/visual-library`, logado como EDITOR),
   preencher o formulário de nova associação (imagem PNG válida + categoria + descrição) e
   submeter. Esperado: enquanto a chamada está em voo (usar a aba Network do browser para
   segurar a resposta — interceptação de rede, decisão 4.319), o controle de salvar fica
   desabilitado com indicador visível; ao liberar a resposta com sucesso, confirmação
   visível e o item aparece na listagem; repetir bloqueando a resposta com erro (ex.:
   parar o backend momentaneamente) — mensagem de falha visível, dados do formulário
   preservados.
2. **AC-022-006 (parte — exibição ao reabrir)**: editar a categoria da associação criada no
   passo 1 e salvar; recarregar a página (F5). Esperado: a categoria nova aparece na
   listagem, sem duplicar a associação.
3. **AC-022-009 (parte)**: com o acervo tendo ao menos 2 associações. Esperado: cada item
   lista miniatura (imagem carregada, sem quebra), categoria e `linkCount` correspondente ao
   número de Quadros vinculados.
4. **AC-022-010**: usar o filtro de categoria com um valor que combine só com uma das
   associações. Esperado: a listagem mostra só as associações daquela categoria.
5. **AC-022-019 (parte — exibição de reachableLinks/outOfReachCount)**: com a associação da
   pré-condição (vinculada a um Quadro alcançável pelo EDITOR e um fora do alcance), acionar
   remover. Esperado: a mensagem de recusa exibe ao menos 1 vínculo identificado (o
   alcançável) e uma contagem separada para o(s) fora do alcance, sem identificar
   `rawContentId`/`frameId` deste último.
6. **AC-022-022 (parte — sugestão ao digitar)**: no campo de categoria do formulário de
   criação, digitar um prefixo que combine com uma categoria já existente no acervo (ex.:
   "Fix" para "Fixture Gate 9"). Esperado: a categoria existente aparece como sugestão antes
   de submeter.

## Riscos específicos

- Primeiro upload multipart do frontend (`code-scout`, PLAN §1) — sem molde local de
  `<input type="file">`/`FormData` a copiar; o teste do componente (Critérios de pronto)
  cobre só o contrato de render, não o envio real do arquivo (isso é gate 9, passo 1, e o
  gate 1 de TASK-023-008 no backend).
- **Resolvido pelo Tech Lead na consolidação da rodada** (achados do redator, degrau 1 da
  escada — correções seguras e reversíveis, sem ambiguidade de produto): a URL da miniatura
  ganhou o prefixo `/api/v1` obrigatório e o componente passou de `<img>` cru para
  `next/image` (`unoptimized`) em TASK-023-009/012/013, eliminando o 404 previsto e o
  warning de lint `@next/next/no-img-element`.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-100
**Implementado por**: 
**Revisado por**: 
**Tentativas**: 
**Cobertura final**: 
**Arquivos modificados**:
  - 

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>

**Notas**: 
