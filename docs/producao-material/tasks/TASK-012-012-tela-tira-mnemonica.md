# TASK-012-012: Construir a tela da Tira mnemônica (quadro a quadro)

**Slug**: producao-material
**Pertence a**: PLAN-012
**Realiza (FRs)**: FR-011-001, FR-011-003, FR-011-004, FR-011-005, FR-011-006, FR-011-007, FR-011-010, FR-011-011
**Componente**: COMP-012-011 (principal), COMP-012-012
**Wave**: 6
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-tira-mnemonica` (`git.branchStrategy: "unica"`; `git.branchNaming: "slug"`)
**Padrão de commit**: Conventional Commits (`commit.convention: "conventional"`) — ex.: `feat(producao-material): tela da tira mnemonica quadro a quadro`
**Framework de teste**: Jest 30 + Testing Library (`@testing-library/react` + `@testing-library/user-event`), montado contra `makeStore()` + `fetch` mockado — mesmo harness de `rule-breakdown-form.test.tsx`/`internal-shell.integration.test.tsx`

## Dependências

- **Depende de**: TASK-012-008, TASK-012-010
- **Bloqueia**: TASK-012-013

## Contexto

Com a rota HTTP exposta (TASK-012-008) e os endpoints RTK Query prontos (TASK-012-010: `useOpenMnemonicStripQuery` + as 4 mutations de Quadro), falta a tela `(interno)/content/[id]/tira` — Server Component puro + client component com CRUD/reordenação, os 3 estados observáveis por ação (FR-011-011) e o estado de Tira vazia (AC-011-024). Segue **exatamente** o padrão de `(interno)/content/[id]/breakdown` (Server Component) e `rule-breakdown-form.tsx` (client component montado contra a `api` real).

## Escopo

### Inclui

- `mnemonicos-frontend/src/app/(interno)/content/[id]/tira/page.tsx` — Server Component puro, molde exato de `mnemonicos-frontend/src/app/(interno)/content/[id]/breakdown/page.tsx`: só resolve `params.id` e renderiza `<MnemonicStripBoard rawContentId={id} />`; sem `'use client'`.
- `mnemonicos-frontend/src/components/mnemonic-strip-board.tsx` — `'use client'`, usa `useOpenMnemonicStripQuery({ rawContentId })` (COMP-012-010) para a leitura/geração e `useAddMnemonicFrameMutation`/`useUpdateMnemonicFrameMutation`/`useRemoveMnemonicFrameMutation`/`useReorderMnemonicFramesMutation` para as 4 ações. Tipos `MnemonicStrip`/`MnemonicFrame` de `@/types/domain` (COMP-012-009). Lista de Quadros ordenada por `position`; controles simples de mover posição (para cima/para baixo — sem drag-and-drop, A-011-009); os 3 estados observáveis por ação (em andamento — controle desabilitado + indicador visível —, sucesso, falha); estado de "Tira vazia" com ação de criar Quadro disponível quando `frames.length === 0`, sem regeneração automática; cores de erro/sucesso usando os tokens `--danger`/`--link` do tema (`text-danger`/`text-link`), nunca classe literal de paleta.
- `mnemonicos-frontend/src/components/mnemonic-strip-board.test.tsx` — montado com `makeStore()` + `Provider` + `fetch` mockado (mesmo harness de `rule-breakdown-form.test.tsx`), nunca hook extraído isolado.

### Não inclui

- Link de navegação a partir da tela de Quebra da regra (`rule-breakdown-form.tsx`) — TASK-012-013.
- Qualquer registro novo em `internal-routes.ts`/`proxy.ts`: o matcher `/content/:path*` (`mnemonicos-frontend/src/proxy.ts:56`) já cobre `/content/[id]/tira` — confirmado por leitura direta, não presumido. A suíte existente `mnemonicos-frontend/src/proxy.test.ts` (não tocada por esta TASK) já falha se algum segmento de `(interno)` ficar descoberto pelo matcher.
- Drag-and-drop de reordenação (A-011-009) — fora de escopo da SPEC inteira, não só desta TASK.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Criar `page.tsx` copiando a estrutura de `breakdown/page.tsx` (Server Component, só `params.id`).
2. Criar `mnemonic-strip-board.tsx`: montar a query de abertura, renderizar a lista de Quadros ordenada por `position`, os controles de CRUD/reordenação e os 3 estados por ação.
3. Tratar `frames.length === 0` como estado de "Tira vazia" (sem chamar a query de abertura de novo).
4. Usar `text-danger`/`text-link` para as cores semânticas; nenhum literal de paleta.
5. Escrever `mnemonic-strip-board.test.tsx` montado contra `makeStore()` + `fetch` mockado, um `describe` por ação (adicionar/editar/remover/reordenar) com os 3 estados cada, mais o estado de Tira vazia.

## Critérios de pronto

- [ ] **AC-011-004/AC-011-005** (Adicionar Quadro, gate 1, componente montado): `describe('adicionar Quadro')` com 3 casos — (a) em andamento: após clicar "Adicionar Quadro", o botão fica `disabled` e um indicador `role="status"` com texto pt-BR ("Adicionando…") fica visível enquanto o `fetch` da mutação está pendente (resposta segurada por uma Promise não resolvida na fixação do teste); (b) sucesso: resposta 200 com o Quadro novo → ele aparece na posição informada, indicador de "em andamento" some; (c) falha: resposta não-2xx → `role="alert"` com mensagem pt-BR visível, nenhum Quadro novo renderizado, a Tira permanece como estava antes da tentativa.
- [ ] **AC-011-006/AC-011-007** (Editar texto, gate 1, componente montado): `describe('editar texto de Quadro')` com os mesmos 3 casos — indicador "Salvando…" em andamento; sucesso persiste e exibe o novo texto; falha mantém o texto anterior com `role="alert"` visível.
- [ ] **AC-011-008/AC-011-009** (Remover Quadro, gate 1, componente montado): `describe('remover Quadro')` com os mesmos 3 casos — indicador "Removendo…" em andamento; sucesso remove o Quadro e recompõe a lista; falha mantém o Quadro e a posição, com `role="alert"` visível.
- [ ] **AC-011-010/AC-011-011** (Reordenar, gate 1, componente montado): `describe('reordenar Quadros')` com os mesmos 3 casos — indicador "Reordenando…" (ou controles de mover desabilitados) em andamento; sucesso persiste a nova ordem; falha mantém a ordem anterior íntegra, com `role="alert"` visível.
- [ ] **AC-011-024** (Tira vazia, gate 1, componente montado): teste que remove (mocka sucesso) todos os Quadros um a um até `frames.length === 0` — a tela mostra o estado de "Tira vazia" com a ação de criar Quadro disponível, e nenhuma nova chamada à query de abertura (`useOpenMnemonicStripQuery`) é disparada (contagem de chamadas ao `fetch` para `GET .../strip` não cresce além da 1ª montagem).
- [ ] **AC-011-019** (pt-BR completo): todo rótulo/mensagem/indicador citado nos testes acima usa string literal em português do Brasil, conferida por igualdade exata (`getByText`/`getByRole(..., { name: '<string exata>' })`, nunca `expect.stringContaining` parcial) — nenhum texto em inglês na interface.
- [ ] **AC-011-016 (parte — grep frontend)**: grep estrutural ancorado sobre os 2 arquivos novos do frontend:
  ```
  grep -nE '\b(Mnemonic|MnemonicTechnique)\b' "mnemonicos-frontend/src/app/(interno)/content/[id]/tira/page.tsx" mnemonicos-frontend/src/components/mnemonic-strip-board.tsx | grep -vE ':[[:space:]]*(//|\*|/\*)'
  ```
  Esperado: saída vazia (note: `\bMnemonic\b` não casa `MnemonicStrip`/`MnemonicFrame` — limite de palavra não fecha entre "Mnemonic" e "Strip"/"Frame", que são o mesmo token; casa apenas o símbolo isolado `Mnemonic`/`MnemonicTechnique`). Fixado contra o molde (arquivos-alvo ainda não existem nesta wave): `grep -nE '\b(Mnemonic|MnemonicTechnique)\b' mnemonicos-frontend/src/components/rule-breakdown-form.tsx "mnemonicos-frontend/src/app/(interno)/content/[id]/breakdown/page.tsx"` → confirmado **vazio** nos dois, rodado nesta fixação (2026-09-06).
- [ ] **Cor semântica (lição [Design])**: `grep -nE 'text-(red|green|blue|yellow|orange|purple|pink)-[0-9]' mnemonicos-frontend/src/components/mnemonic-strip-board.tsx` → esperado vazio; `grep -c 'text-danger' mnemonicos-frontend/src/components/mnemonic-strip-board.tsx` → esperado `>= 1` (usado nos estados de falha).
- [ ] **Guard de navegação (n/a confirmado)**: `npm --prefix mnemonicos-frontend test -- proxy.test` → verde, sem alteração no arquivo (confirma que `/content/[id]/tira` já cai sob o prefixo coberto).
- [ ] Sem warnings/lints novos sobre `git diff --name-only main...HEAD` (produção e teste).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`guidelines/project/frontend/next-16.md`).
- [ ] Code review aprovado.

## Roteiro do gate 9 (fixado ANTES do código)

Nenhum handoff anterior do slug (`docs/producao-material/handoffs/` — só `HANDOFF-PLAN-003.md`, de F1, sem menção à Tira mnemônica) registra este fluxo como não-exercitável — roteiro novo, sem herança.

**Ambiente**: backend (`mnemonicos-backend/`) e frontend (`mnemonicos-frontend/`) de pé localmente — `npm run db:up && npm run db:deploy && npm run db:seed && npm run dev` (backend, API em `http://localhost:3333/api/v1`) e `npm run dev` (frontend, `http://localhost:3000`) — mesma receita de `HANDOFF-PLAN-003.md` §3. Tela alvo: `http://localhost:3000/content/<rawContentId>/tira`, onde `<rawContentId>` é o id criado na pré-condição abaixo.

**Sujeito concreto**: EDITOR autenticado com a credencial real do realm `editor` (`keelson.local.json` › `screenVerify.realms.editor`: `loginPath: "/login"`, `username: "editor@mnemonicos.local"`, `password: "Vi0ldzkax7Y6tQ53I1mx"` — já provisionado, nunca chutar).

**Pré-condição (montar)** — o acervo semeado por `seed-material.ts` é de autoria do **ADMIN** (`seed.ts:96`); como NFR-011-001 restringe o EDITOR à própria autoria, o fixture desta verificação é criado pelo próprio EDITOR de teste via API, sem tocar o acervo semeado:

1. Login como EDITOR para obter o cookie de sessão:
   ```
   curl -c /tmp/tira-gate9-cookies.txt -X POST http://localhost:3333/api/v1/auth/login \
     -H 'Content-Type: application/json' \
     -d '{"email":"editor@mnemonicos.local","password":"Vi0ldzkax7Y6tQ53I1mx"}'
   ```
2. Localizar o `topicId` do tema "Fato Gerador" (Direito Tributário, sem `RawContent` semeado — `mnemonicos-backend/prisma/seed-material.ts:87`):
   ```
   curl -b /tmp/tira-gate9-cookies.txt http://localhost:3333/api/v1/disciplines
   ```
   → localizar, na resposta, o `topics[].id` cujo `slug` é `"fato-gerador"`.
3. Criar o Conteúdo bruto como o próprio EDITOR (autoria própria garante o alcance):
   ```
   curl -b /tmp/tira-gate9-cookies.txt -X POST http://localhost:3333/api/v1/contents \
     -H 'Content-Type: application/json' \
     -d '{"topicId":"<uuid de Fato Gerador>","rawText":"Fixture do gate 9 — Tira mnemonica.","radarClass":"MEDIA"}'
   ```
   → anotar o `id` da resposta (`<rawContentId>`).
4. Salvar a Quebra da regra com os **5 blocos preenchidos** (necessário para AC-011-001 gerar 5 Quadros, não 3):
   ```
   curl -b /tmp/tira-gate9-cookies.txt -X PUT http://localhost:3333/api/v1/contents/<rawContentId>/breakdown \
     -H 'Content-Type: application/json' \
     -d '{"concept":"Fato gerador","action":"Identificar a situacao prevista em lei","object":"Ocorrencia que ensejaria a obrigacao tributaria","condition":"Quando a lei prever hipotese de incidencia distinta para o mesmo tributo","exception":"Situacoes de imunidade ou isencao expressamente previstas em lei","essence":"O fato gerador e a situacao definida em lei como necessaria e suficiente a obrigacao tributaria."}'
   ```

**Restaurar ao fim** (nunca apagar por papel/tabela inteira, só a linha do fixture criado aqui — `production_stage_events` tem FK `onDelete: Restrict` para `raw_contents` e precisa ser limpo primeiro; o resto cascateia por `onDelete: Cascade`):
```
npm run db:psql   # em mnemonicos-backend/
DELETE FROM production_stage_events WHERE "rawContentId" = '<rawContentId>';
DELETE FROM raw_contents WHERE id = '<rawContentId>';
```

**Passos (um por AC)**:

1. **AC-011-001**: login na UI (`http://localhost:3000/login`, credenciais do realm `editor`); navegar para `http://localhost:3000/content/<rawContentId>/tira`. Esperado: geração automática de **exatamente 5 Quadros**, ordem CONCEITO→AÇÃO→OBJETO→CONDIÇÃO→EXCEÇÃO, cada um com o texto do Bloco correspondente da fixture, posições 1 a 5 sem lacuna.
2. **AC-011-003**: recarregar a página (F5). Esperado: nenhuma segunda geração — os mesmos 5 Quadros reaparecem, mesmos textos/posições, sem duplicata.
3. **AC-011-004/AC-011-006/AC-011-008/AC-011-010** (os 3 estados via interceptação de rede, decisão 4.319): nas devtools do browser, usar a aba Network para segurar/atrasar a resposta de UMA mutação por vez (adicionar, editar, remover, reordenar) — "Block request URL" temporário ou throttling custom para atraso; durante a resposta pendente, observar o controle da ação correspondente desabilitado com indicador visível ("Adicionando…"/"Salvando…"/"Removendo…"/"Reordenando…"); liberar a resposta e confirmar o sucesso refletido no Quadro. Repetir para cada uma das 4 ações forçando uma resposta de erro (bloqueio permanente da URL ou parar o backend momentaneamente) e observar o estado de falha (mensagem de erro visível, pt-BR, dado local intacto).
4. **AC-011-012**: após as mutações do passo 3, recarregar a página (F5). Esperado: a ordem/posição dos Quadros reflete a última mutação bem-sucedida.
5. **AC-011-017**: em aba anônima (sem cookie de sessão), navegar direto para `http://localhost:3000/content/<rawContentId>/tira`. Esperado: redireciona para `/login?next=...` (guard de `proxy.ts`, mesmo mecanismo já provado para `/studio` em F1) — a barreira real (401/403) é confirmada no backend por TASK-012-008; este passo confirma o guard de navegação da tela.
6. **AC-011-024**: remover os 5 Quadros um a um pelos controles de remoção, até a Tira ficar vazia. Esperado: ao remover o último, a tela mostra o estado de "Tira vazia" com a ação de criar Quadro disponível, sem regeneração automática (nenhum Quadro novo aparece sozinho).

## Riscos específicos

- RISK-011-002 (INDEX.md): sem drag-and-drop, a usabilidade de reordenar Tiras com muitos Quadros pode ficar pobre com controles simples de mover para cima/baixo — aceito nesta fatia (A-011-009), revisitar se o piloto reportar atrito real.

**Lições ativas cruzadas** (`guidelines/project/lessons.md`) contra os arquivos-alvo (`mnemonic-strip-board.tsx`, `page.tsx`):

- **[Testes] Predicado de decisão de UI a partir de estado de RTK Query só se prova no componente montado** (Estado: ativa). Erro original: o predicado de render/redirect do `InternalShell` foi extraído como função pura e provado sobre `api.endpoints.me.select()` isolado da store — o mutante que removia a guarda `isUninitialized`/`isFetching` morria no teste isolado e sobrevivia no componente montado (bug real ficou verde na suíte). Solução: predicado que decide render/navegação a partir de estado de RTK Query → oráculo que passa pelo **componente MONTADO** contra a `api` real (`makeStore()` + `fetch` mockado); o teste da função pura complementa, nunca substitui; critério de aceite: o mutante morre no teste montado. **Aplicação aqui**: os 3 estados por ação (em andamento/sucesso/falha) e o estado de Tira vazia nascem de `isLoading`/`isError`/`data.frames` das 5 hooks de RTK Query — `mnemonic-strip-board.test.tsx` (Critérios de pronto acima) monta o componente real contra `makeStore()` com `fetch` interceptado por rota/método (mesmo padrão do `handler` de `rule-breakdown-form.test.tsx`), nunca mocka os hooks nem extrai o predicado de estado como função isolada.
- **[Design] Cor semântica de texto (erro/sucesso/link) vem de token do tema, nunca de literal da paleta** (Estado: ativa). Erro original: `text-red-500` direto da paleta Tailwind para mensagem de erro, contraste abaixo do piso AA — corrigido com o token `--danger`/`text-danger` (F2, BRIEF-008). Solução: cor semântica de texto vem sempre de token do `@theme`/`:root` de `globals.css`, nunca de literal da paleta em componente. **Aplicação aqui**: `mnemonic-strip-board.tsx` usa `text-danger` (falha) e `text-link` (ação de navegação/link, se houver) — nenhuma classe `text-red-*`/`text-green-*`/`text-blue-*` literal; conferido pelo critério de grep acima.
- **[Segurança] Guard de navegação (proxy/middleware) enumera o que GUARDA, nunca o que dispensa** (Estado: ativa). **Aplicação aqui: `n/a`, declarado e confirmado** — nenhuma mudança em `proxy.ts`/`internal-routes.ts` é necessária: o matcher já enumera o prefixo `/content` (`mnemonicos-frontend/src/proxy.ts:56`, lido diretamente nesta redação), e a tela nova (`/content/[id]/tira`) cai sob esse prefixo já coberto. A suíte `proxy.test.ts` (que enumera os segmentos de `src/app/(interno)/` falhando se algum não estiver coberto, mesma régua de `assertDenyByDefault`) não precisa de alteração — o Critério de pronto acima só exige rodá-la para confirmar que continua verde, sem tocar o arquivo.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Branch**:
**Commit SHA**:
**Jira**: KAN-62
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
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a>

**Notas**:
