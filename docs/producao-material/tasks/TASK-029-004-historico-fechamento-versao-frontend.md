# TASK-029-004: Histórico e fechamento de Versão editorial — frontend completo

**Slug**: producao-material
**Pertence a**: PLAN-029
**Realiza (FRs)**: FR-028-006
**Funcionalidade**: FEAT-028-001 (primária)
**Componente**: COMP-029-009, COMP-029-010, COMP-029-011 (principal), COMP-029-012, COMP-029-014
**Wave**: 3
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-029-002, TASK-029-003
- **Bloqueia**: nenhuma

## Contexto

Formulário de fechamento (Data de fechamento legislativo + botão "Fechar versão", 3 estados
observáveis) e lista do histórico de Versões, alcançáveis na tela do Conteúdo bruto — irmãos
de `ContentSupplementaryPanel` (F7) dentro do MESMO slot `supplementary` de `ContentForm`
(DEC-029-007), sem tocar a assinatura do slot. **Depende das DUAS tasks da Wave 2** (ajuste
desta TASK à sugestão de waves do Tech Lead — princípio 2/costura só em contrato
congelado): o contrato de rota de TASK-029-002 precisa estar congelado (decisão 4.300), **e**
o roteiro do gate 9 desta TASK inclui exportar o PDF e conferir o carimbo de Versão
(TASK-029-003) — sem as duas, o último passo do roteiro não é executável. Território e
precedentes: `docs/producao-material/MAP.md` (seção "Contraste, pegadinha, flashcard e
protocolo impresso (F7 · PLAN-027)" — `content-form.tsx:44-57/501` slot `supplementary`,
`content-supplementary-panel.tsx` como wrapper que reusa a MESMA chave de cache,
`fetch-error.ts` para distinguir 404) e PLAN-029 §3 (COMP-029-009/010/011/012/014), §6
(DEC-029-007).

## Escopo

### Inclui

- `mnemonicos-backend/src/domain/types.ts` + `mnemonicos-frontend/src/types/domain.ts`:
  `export interface ContentVersion { id: string; rawContentId: string; number: number;
  legislativeClosureDate: Date /* string no frontend */; authorId: string; closedAt: Date
  /* string no frontend */ }` (COMP-029-009) — só os 4 dados imutáveis expostos para
  leitura, **sem** `contentSnapshot` (dado interno, nunca exposto à UI, DEC-029-003).
  `VERSAO_EDITORIAL` (valor do enum `ProductionStageType`) fica backend-only, sem espelho
  (mesmo padrão de `PRODUCTION_STAGE_TYPES`/DEC-010-006 — nenhuma tela consome o enum de
  etapa diretamente).
- `mnemonicos-backend/tests/unit/contents-frontend-contract.test.ts` (estende — molde
  `describe('paridade cross-repo — Contrast (TASK-027-003)')`, linhas 128-190): novo
  `describe('paridade cross-repo — ContentVersion (TASK-029-004)')`, com a MESMA constante
  nova `BACKEND_CONTENT_VERSIONS_SERVICE` (`resolve(__dirname,
  '../../src/modules/content-versions/content-versions.service.ts')`), comparando (a)
  `ContentVersion` (backend `domain/types.ts`) × `ContentVersion` (frontend
  `types/domain.ts`) e (b) `ContentVersionDetail` (payload HTTP real,
  `content-versions.service.ts`, TASK-029-002) × `ContentVersion` (frontend) — mesmo par
  duplo já aplicado a `Contrast`/`ContrastDetail`.
- `mnemonicos-frontend/src/store/api.ts`: `TAG_TYPES` ganha `'ContentVersion'`;
  `listContentVersions: build.query<ContentVersion[], string>` (`query: (rawContentId) =>
  \`/contents/${rawContentId}/versions\``, `providesTags: ['ContentVersion']`) e
  `closeContentVersion: build.mutation<ContentVersion, CloseContentVersionArgs>` (`query:
  ({ rawContentId, ...body }) => ({ url: \`/contents/${rawContentId}/versions\`, method:
  'POST', body })`, `invalidatesTags: ['ContentVersion']` — **sem** invalidar
  `'RawContent'`: o fechamento não altera nenhum campo do `RawContent`, A-028-001). `type
  CloseContentVersionArgs = { rawContentId: string; legislativeClosureDate: string }`.
- `mnemonicos-frontend/src/components/content-version-history.tsx` (novo): `'use client'`,
  named export `ContentVersionHistory({ rawContentId }: ContentVersionHistoryProps)` —
  UM componente só (form + lista), não 2 irmãos: Versão é append-only, sem edição/remoção,
  então não existe o "efeito repartido entre 2 componentes irmãos" que a lição ativa
  "[Testes] Critério com efeito repartido entre 2 componentes irmãos" adverte (o único
  efeito — "a Versão nova aparece no histórico" — vive INTEIRO neste componente, provável
  num único arquivo de teste). Campo de Data de fechamento legislativo (`<input
  type="date">`) + botão "Fechar versão" com os 3 estados de FR-028-006 (molde
  `contrast-form.tsx`: `isSubmitting`/`submitSuccess`/`submitError`) via
  `useCloseContentVersionMutation`; abaixo, lista de histórico (`useListContentVersionsQuery(
  rawContentId, { refetchOnMountOrArgChange: true })` — decisão PRÓPRIA deste componente,
  não copiada às cegas: `listContentVersions` é uma chave de cache que NENHUM outro
  componente da árvore assina, então não há o risco de GET redundante em subscriber
  secundário que a lição "[Performance] `refetchOnMountOrArgChange` num subscriber
  SECUNDÁRIO..." adverte — este é o ÚNICO e PRIMEIRO subscriber da própria chave), cada
  item mostrando `number`/`legislativeClosureDate` (formatada)/`authorId` (identificador
  cru — FR-028-005 pede "identificador do autor", não nome; não há endpoint de
  nome/e-mail por id neste escopo)/`closedAt` (timestamp formatado), em ordem (a ordem já
  vem do backend, `orderBy: number asc`, nenhum `sort` no cliente). Estado vazio (`items.
  length === 0`): mensagem "Nenhuma versão fechada ainda.".
- `mnemonicos-frontend/src/app/(interno)/content/[id]/page.tsx` (estende): `supplementary`
  passa a ser um `Fragment` (`<>...</>`) com `ContentSupplementaryPanel` e
  `ContentVersionHistory` como IRMÃOS (DEC-029-007 — nunca aninhado dentro de
  `ContentSupplementaryPanel`), ambos recebendo `rawContentId={id}`.
- `mnemonicos-frontend/src/components/content-supplementary-panel.test.tsx` (estende —
  extensão MÍNIMA, só para não quebrar): o `handler` de fetch mockado ganha 1 stub para
  `GET /contents/:id/versions` (devolve `[]`) — a partir desta TASK, `ContentDetailPage`
  monta TAMBÉM `ContentVersionHistory`, que a suíte existente (monta a página real) precisa
  responder para não falhar por request não-mockado.

### Não inclui

- Qualquer alteração ao backend de fechamento/histórico (`content-versions.*`) — já
  entregue por TASK-029-002, da qual esta TASK só consome a rota.
- Qualquer alteração ao pipeline de PDF/carimbo — já entregue por TASK-029-003.
- Edição/remoção de Versão em qualquer camada — proibido por FR-028-004 em toda a fatia.

## Critérios de pronto

- [ ] **Paridade cross-repo `ContentVersion`**: `contents-frontend-contract.test.ts`
      (estendido) confirma que os campos de `ContentVersion` (backend) e `ContentVersion`
      (frontend) são EXATAMENTE `id`/`rawContentId`/`number`/`legislativeClosureDate`/
      `authorId`/`closedAt` nos dois lados, e que `ContentVersionDetail`
      (`content-versions.service.ts`) tem o MESMO conjunto de campos que `ContentVersion`
      do frontend. Verificação executável: `npm --prefix mnemonicos-backend test --
      contents-frontend-contract.test.ts` → `OK (N tests)`.
- [ ] Testes cobrem AC-028-001 (parte — histórico visível na tela, FR-028-005):
      `ContentVersionHistory` montado (`makeStore()` + `fetch` mockado devolvendo 1
      Versão) exibe `number`, a data formatada, o `authorId` e o timestamp formatado do
      item. Verificação executável: `npx jest --runTestsByPath
      src/components/content-version-history.test.tsx` (cwd `mnemonicos-frontend`) →
      `PASS`.
- [ ] Testes cobrem AC-028-007 (FR-028-006): `ContentVersionHistory` montado, resposta da
      mutation REPRESADA por interceptação de rede (decisão 4.319 — nunca
      `setTimeout`/temporizador mockado): ao submeter, o botão "Fechar versão" fica
      desabilitado (indicador visível) durante a chamada; em SUCESSO, indicador some,
      mensagem de confirmação visível e a Versão nova aparece na lista (mutante-alvo:
      remover `invalidatesTags: ['ContentVersion']` de `closeContentVersion` faz este
      caso reprovar — molde `flashcard-list.test.tsx`, lição ativa "[Testes] Critério com
      efeito repartido..." já neutralizada pelo design de componente único, mas o mutante
      de invalidação continua exigido); em FALHA (erro do sistema), botão reabilitado, o
      valor do campo de data PRESERVADO (nenhum reset), mensagem de falha visível
      (`role="alert"`). Mesmo comando acima → `PASS`, 2 cenários nomeados.
- [ ] **Prova de refetch ao remontar sobre cache QUENTE** (lição ativa "[Testes] Prova de
      'refetch ao remontar' que cria um store NOVO a cada montagem nunca exercita cache
      quente"): `content-version-history.test.tsx` monta `ContentVersionHistory` 2 VEZES
      no MESMO `store` (nunca 2 `makeStore()` distintos), com contagem exata de requests a
      `GET /contents/:id/versions` — 1 na 1ª montagem, +1 na 2ª (revisita) — antes de
      declarar o comportamento coberto. Mutante-alvo: remover
      `refetchOnMountOrArgChange: true` do hook faz a 2ª montagem NÃO gerar o 2º request
      (contagem fica em 1) — este teste reprova o mutante. Mesmo comando acima → `PASS`.
- [ ] **Wiring — composição real** (molde `content-supplementary-panel.test.tsx`, lição
      "[Design] Wrapper de composição que passa `prop ?? null`..." — não se aplica aqui
      por design, mas o teste de composição É exigido do mesmo jeito): grep confirma o
      import de `ContentVersionHistory` em `content/[id]/page.tsx`; teste que monta a
      PÁGINA real (`ContentDetailPage`, não o componente isolado) confirma a presença dos
      2 componentes (`ContentSupplementaryPanel` E `ContentVersionHistory`) como IRMÃOS no
      slot `supplementary` — nenhum aninhado dentro do outro (DEC-029-007). Verificação
      executável: `npx jest --runTestsByPath
      src/components/content-supplementary-panel.test.tsx` (cwd `mnemonicos-frontend`,
      suíte estendida) → `PASS`.
- [ ] `TAG_TYPES` (`mnemonicos-frontend/src/store/api.ts`) contém `'ContentVersion'` —
      `grep -n "'ContentVersion'" src/store/api.ts` (cwd `mnemonicos-frontend`) → ao menos
      2 ocorrências (declaração em `TAG_TYPES` + uso em `invalidatesTags`/`providesTags`).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`), produção e teste — `npm --prefix mnemonicos-backend run lint` →
      exit 0; `npx eslint src/components/content-version-history.tsx
      src/components/content-version-history.test.tsx
      src/app/\(interno\)/content/\[id\]/page.tsx src/store/api.ts` (cwd
      `mnemonicos-frontend`) → 0 problemas.
- [ ] Aderência à stack/padrões da ficha e do perfil `next-16.md` — Server Component
      default (`page.tsx` continua sem `'use client'`), estado de servidor 100% via RTK
      Query, identificadores em inglês/texto de interface em pt-BR.
- [ ] Gate 11 (product-designer) aprovado — posicionamento do formulário/histórico dentro
      do slot `supplementary`, consistência visual com `ContentSupplementaryPanel`
      (mesmos tokens `surface-card`/`text-link`/`text-danger`).
- [ ] Gate 9 (comportamento verificado, `gates.screenVerify`) aprovado — roteiro abaixo.
- [ ] Code review aprovado.

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente**: `http://localhost:3000` (frontend) com backend em `http://localhost:3333`
(`BACKEND_API_URL` apontando para ele, ou portas alternativas conforme a lição ativa
"[Config] `CORS_ORIGINS` de origem única quebra silenciosamente..." — se a porta padrão
estiver ocupada, ajuste `CORS_ORIGINS` do backend ANTES de trocar a porta do frontend).
Realm: `keelson.local.json` (login real da área interna).

**Sujeito concreto**: EDITOR do seed de desenvolvimento (`seedMaterial`), credencial do
realm local.

**Pré-condição com receita**: login como o EDITOR seed → `/content/new` → criar um NOVO
Conteúdo bruto descartável para este roteiro (texto normativo trivial, disciplina/tema do
seed, classe do radar qualquer) → salvar a Quebra da regra (os 4 campos obrigatórios) na
tela `/content/:id/breakdown` → voltar a `/content/:id`. **Restaurar ao fim**: usar o botão
"Remover" já existente em `ContentForm` (soft-delete reversível) sobre este Conteúdo bruto
descartável — a(s) Versão(ões) fechada(s) durante o roteiro PERMANECEM no banco por design
(FR-028-004, ato irreversível: não há "desfazer" um fechamento); a remoção do Conteúdo bruto
é só para não deixar o item de teste na listagem visível do time real, nunca para apagar a
Versão.

1. **AC-028-007/FR-028-006** — em `/content/:id`, no bloco "Histórico de Versões" (irmão do
   painel de Contraste/Pegadinha/Flashcard), preencher Data de fechamento legislativo com a
   data de hoje e clicar "Fechar versão": confirmar que o botão fica desabilitado/indicador
   visível até a resposta, e ao concluir mostra confirmação de sucesso.
2. **AC-028-001 (parte)/FR-028-005** — confirmar que a Versão nova (número 1, a data
   informada, o identificador do autor, o timestamp) aparece na lista de histórico sem
   precisar recarregar a página.
3. **Carimbo no PDF exportado (FR-028-008)** — clicar em "Exportar PDF" (qualquer
   Variante): confirmar, pelo painel de rede, que `POST /contents/:id/publication` responde
   com `Content-Type: application/pdf` e que o download é disparado (nome de arquivo no
   padrão `<id>-<variante>-rascunho.pdf`). Se o visualizador de PDF do ambiente headless
   permitir leitura de texto da página renderizada, confirmar visualmente a linha "Versão 1
   — verificado até <data de hoje>" ao lado do rótulo "Rascunho"; se não permitir, registrar
   este sub-passo como NÃO-exercitável nesta rodada (ferramenta, não AC) — a prova de
   CONTEÚDO do carimbo já está fechada por gate 1 em TASK-029-003 (AC-028-009/010/011/013),
   este passo confirma só que o FRONTEND alcança o fluxo depois de uma Versão fechada.

## Riscos específicos

- Nenhum consumidor de nome/e-mail do autor por `authorId` existe nesta fatia — o
  histórico exibe o identificador cru (UUID). Se o piloto (PIL-001) reportar confusão real
  de legibilidade, é candidato a fatia futura (fora de escopo aqui, SPEC-028 não pede
  resolução de nome).
- Gate 8 (security-engineer): **n/a** — diff é composição de tela + formulário + leitura,
  sem endpoint/rota/dado sensível novo tocado neste lado (o backend já foi revisado em
  TASK-029-002/003).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-141

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
