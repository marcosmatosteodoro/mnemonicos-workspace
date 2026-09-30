# TASK-033-007: Painel de aprovação de Versão — frontend completo

**Slug**: producao-material
**Pertence a**: PLAN-033
**Realiza (FRs)**: FR-032-007, FR-032-008
**Funcionalidade**: FEAT-032-001 (primária)
**Componente**: COMP-033-011
**Wave**: 5
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-033-006
- **Bloqueia**: nenhuma

## Contexto

Acrescenta, dentro do MESMO componente `ContentVersionHistory` (F8 — form de fechamento +
lista do histórico, sem edição/remoção), um bloco de aprovação: 2 confirmações
(checkboxes) + botão "Aprovar Versão" com os 3 estados de FR-032-008, visível só para
ADMIN e só quando existe Versão vigente sem `approvedById`. A autorização REAL é a rota do
backend (`requireRole`, TASK-033-003); a ocultação/desabilitação aqui é best-effort de UX,
nunca a garantia (a MESMA régua de FR-032-004, replicada no cliente). Nenhuma mudança de
wiring em `content/[id]/page.tsx` — o slot `supplementary` já monta este componente desde
TASK-029-004. Território e precedentes: `docs/producao-material/MAP.md`,
`mnemonicos-frontend/src/components/content-version-history.tsx` (arquivo INTEIRO —
extensão, não arquivo novo), `content-supplementary-panel.tsx` (padrão de dedup de
`useGetRawContentQuery`), e PLAN-033 §1, §3 (COMP-033-011), §4 Fluxo 1/2.

**Gate 9 ativo** (`gates.screenVerify.enabled: true`) — roteiro fixado abaixo, ANTES do
código. Nenhum handoff anterior do slug (`docs/producao-material/handoffs/`) cobre este
fluxo (HANDOFF-PLAN-003/013/025 tratam de login/PWA/publicação, nenhum de aprovação de
Versão) — roteiro escrito do zero, sem herança de "não-exercitável".

## Escopo

### Inclui

- `mnemonicos-frontend/src/components/content-version-history.tsx` (estende):
  - Novos hooks: `useApproveContentVersionMutation` (de `@/store/api`), `useMeQuery` (de
    `@/store/api`, mesmo padrão de `internal-shell.tsx`), `useGetRawContentQuery` (de
    `@/store/api`, **sem** `refetchOnMountOrArgChange` — lição ativa "[Performance]
    `refetchOnMountOrArgChange` num subscriber SECUNDÁRIO da mesma chave de cache gera GET
    redundante": este componente NÃO é o primeiro subscriber dessa chave —
    `content-form.tsx` já é, mesmo padrão de dedup de `content-supplementary-panel.tsx`).
  - Estado novo: `legalCheckConfirmed`/`pedagogicalCheckConfirmed` (boolean, `useState`),
    `approveError`/`approveSuccess` (mesmo padrão de `submitError`/`submitSuccess` já
    existente para o form de fechamento).
  - Deriva (SEM extrair como função pura fora do componente — lição ativa "[Testes]
    Predicado de decisão de UI a partir de estado de RTK Query só se prova no componente
    montado": o predicado usa o resultado de 2 hooks de RTK Query, e só o componente
    MONTADO exercita o ciclo real de subscrição): `currentVersion = versions?.at(-1) ??
    null`; `isAdmin = me?.role === 'ADMIN'`; `isProducer = currentVersion !== null &&
    me !== undefined && (me.id === currentVersion.authorId || me.id ===
    rawContent?.authorId || me.id === rawContent?.lastEditedById)`.
  - Bloco de aprovação, renderizado **entre** a lista de histórico e o form de "Fechar
    versão" já existentes (a lista já mostra o estado da Versão vigente — o bloco de
    aprovação é uma AÇÃO sobre esse mesmo estado, contextualmente mais próxima da lista
    que do form de criação de uma Versão nova; mesma lógica de ordenação já corrigida
    neste arquivo por achado do `product-designer` em TASK-029-004, "lista antes de
    formulário de criação"):
    - `isAdmin && currentVersion !== null && currentVersion.approvedById === null`: form
      com 2 `<input type="checkbox">` ("Checagem jurídica confirmada"/"Checagem
      pedagógica confirmada"), mensagem de negação (`role="alert"`,
      `'Você não pode aprovar uma Versão que você mesmo produziu.'`) quando `isProducer`,
      botão "Aprovar Versão" (`disabled` quando `isApproving || isProducer ||
      !legalCheckConfirmed || !pedagogicalCheckConfirmed`, `aria-busy={isApproving}`),
      indicador "Aprovando…" durante o envio, mensagem de sucesso ("Versão aprovada.") ou
      falha (extração de erro do backend, MESMO padrão de 2 elos já usado pelo form de
      fechamento no mesmo arquivo: `extractBackendErrorMessage(err) ??
      GENERIC_APPROVE_ERROR` — nunca uma 3ª forma de extração).
    - `isAdmin && currentVersion !== null && currentVersion.approvedById !== null`:
      substitui o form por texto — `'Aprovada por {approvedById} em {approvedAt
      formatado}'` + `'Válida para a próxima Exportação: sim'`/`'não'` (refletindo
      `validApprovalForExport`).
    - `!isAdmin`: nenhum dos 2 blocos renderiza (EDITOR não vê o painel — best-effort de
      UX, FR-032-016 é a garantia real).
  - `handleApprove(event)`: `event.preventDefault()`, limpa `approveError`/
    `approveSuccess`, chama `approveContentVersion({ rawContentId, number:
    currentVersion.number, legalCheckConfirmed, pedagogicalCheckConfirmed }).unwrap()` —
    sucesso seta `approveSuccess: true` (o `invalidatesTags: ['ContentVersion']` da
    mutation já refaz `listContentVersions`, a lista/o bloco reflete o novo estado sem
    reload); falha cai no mesmo `catch`/extração de erro do form de fechamento
    (`isClientError`/`extractBackendErrorMessage`, funções já existentes no arquivo,
    reusadas sem duplicação).
- `mnemonicos-frontend/src/components/content-version-history.test.tsx` (novo ou estende,
  conforme o estado do arquivo ao chegar nesta TASK — TASK-029-004 já o criou): novos
  casos, `makeStore()` + `fetch` mockado (nunca 2 `makeStore()` por teste de revisita —
  lição ativa "[Testes] Prova de 'refetch ao remontar'..." já observada pelo arquivo
  existente):
  - Montado com `me.role: 'ADMIN'`, `RawContent`/Versão vigente de autoria de UM 3º ator
    (não-produtor) e `approvedById: null`: bloco de aprovação visível, botão desabilitado
    até as 2 checkboxes marcadas; marcar as 2 → botão habilitado; submeter (resposta
    REPRESADA por interceptação de rede, decisão 4.319 — nunca `setTimeout` mockado) →
    `aria-busy`/desabilitado durante o envio; em sucesso, mensagem de sucesso visível e o
    bloco passa a mostrar "Aprovada por…" (mutante-alvo: remover
    `invalidatesTags: ['ContentVersion']` de `approveContentVersion` faz este caso
    reprovar).
  - Montado com `me.id` IGUAL a `currentVersion.authorId` (produtor via quem fechou):
    botão SEMPRE desabilitado e mensagem de negação visível, mesmo com as 2 checkboxes
    marcadas — **prova no componente MONTADO** (lição ativa "[Testes] Predicado de
    decisão de UI a partir de estado de RTK Query só se prova no componente montado"),
    nunca uma função pura extraída testada isolada da store.
  - Montado com `me.id` IGUAL a `rawContent.authorId` (produtor via autor original,
    distinto de quem fechou) e MESMO cenário com `rawContent.lastEditedById` (produtor via
    último editor) — 2 casos, 1 por identidade (não um caso "representativo").
  - Montado com `me.role: 'EDITOR'`: bloco de aprovação AUSENTE do DOM (nem o form nem o
    texto "Aprovada por").
  - **Extrator de erro — 1 teste por elo da cadeia** (lição ativa "[Testes] Extrator com
    cadeia de fallback (`a ?? b ?? c`) exige 1 teste por ramo" — mesmo defeito já
    reincidiu neste ARQUIVO em TASK-029-004): (a) resposta 409 com
    `error.message` presente → mensagem do backend exibida; (b) resposta 4xx com corpo
    `{}` (sem `error`/`message`) → `GENERIC_APPROVE_ERROR` exibida — fixture
    DELIBERADAMENTE sem o campo, nunca o fixture "feliz" que já teria o 1º elo. Rodar o
    mutante (zerar o 2º elo) antes de declarar o critério coberto.
  - **`useGetRawContentQuery` sem `refetchOnMountOrArgChange`**: `grep -n
    "useGetRawContentQuery" src/components/content-version-history.tsx` (cwd
    `mnemonicos-frontend`) confirma a chamada SEM o 2º argumento de opções (ou com opções
    que NÃO incluem `refetchOnMountOrArgChange`).

### Não inclui

- Qualquer alteração ao backend (`content-versions.*`, `publication.*`) — já entregues
  por TASK-033-003/004/005, das quais esta TASK só consome.
- Qualquer mudança em `content/[id]/page.tsx` — o slot já monta o componente (DEC-029-007,
  TASK-029-004), sem alteração de wiring.
- Papel/tela dedicados de "revisor jurídico" — fora do escopo da SPEC (§4.2).

## Critérios de pronto

- [ ] Testes cobrem AC-032-007 (FR-032-008): 3 estados observáveis (desabilitado/
      `aria-busy` durante envio, sucesso, falha) — verificação executável: `npx jest
      --runTestsByPath src/components/content-version-history.test.tsx` (cwd
      `mnemonicos-frontend`) → `PASS`.
- [ ] Testes cobrem AC-032-023 (parte UI — negação de autoaprovação visível; a garantia
      REAL é backend, AC-032-023 já provada em TASK-033-003): 3 casos (quem fechou, autor
      original, último editor), botão sempre desabilitado + mensagem visível. Mesmo
      comando acima → `PASS`.
- [ ] Testes cobrem AC-032-001 (parte RENDERIZAÇÃO — o dado já é provado em
      TASK-033-004; este teste prova que o leitor real, o componente montado, exibe
      "Aprovada por…"/"em `<data>`" a partir da resposta real de `listContentVersions`) e
      AC-032-020 (parte renderização — mesma régua, "Válida para a próxima Exportação"
      refletindo `validApprovalForExport: false` quando o sinal de alteração está aceso).
      Mesmo comando acima → `PASS`.
- [ ] Extrator de erro — 1 teste por elo (ver Inclui) — mesmo comando acima → `PASS`.
- [ ] `useGetRawContentQuery` sem `refetchOnMountOrArgChange` (ver Inclui) —
      `grep -n "useGetRawContentQuery" src/components/content-version-history.tsx` (cwd
      `mnemonicos-frontend`) → 1 ocorrência, sem `refetchOnMountOrArgChange` na mesma
      chamada.
- [ ] EDITOR não vê o painel de aprovação — mesmo comando acima → `PASS`.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npx eslint src/components/content-version-history.tsx
      src/components/content-version-history.test.tsx` (cwd `mnemonicos-frontend`) → 0
      problemas.
- [ ] Aderência à stack/padrões da ficha e do perfil `next-16.md` — `'use client'`
      preservado (já existente), tokens `surface-card`/`text-danger`/`text-muted` já
      usados no arquivo, identificadores em inglês/texto de interface em pt-BR.
- [ ] Gate 11 (product-designer) aprovado — ordem do bloco novo (lista → aprovação →
      form de fechamento), consistência visual com o restante do componente.
- [ ] Gate 9 (comportamento verificado, `gates.screenVerify`) aprovado — roteiro abaixo.
- [ ] Code review aprovado.

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente**: `http://localhost:3000` (frontend) com backend em `http://localhost:3333`
(`BACKEND_API_URL` apontando para ele; se a porta padrão estiver ocupada, ajuste
`CORS_ORIGINS` do backend ANTES de trocar a porta do frontend — lição ativa "[Config]
`CORS_ORIGINS` de origem única quebra silenciosamente..."). Realm: `keelson.local.json`.

**Pré-requisito de ambiente — 2 contas ADMIN distintas** (nunca assumido: o seed
(`prisma/seed.ts`) só cria 1 ADMIN, a partir de `SEED_ADMIN_EMAIL`/`SEED_ADMIN_PASSWORD`;
`keelson.local.example.json` só declara os realms `app`/`editor`, nenhum `admin`): antes
deste roteiro, o Diretor/Tech Lead (a) loga como o ADMIN semeado (realm a acrescentar em
`keelson.local.json` como `admin1`, MESMOS valores de `SEED_ADMIN_EMAIL`/
`SEED_ADMIN_PASSWORD` do `.env` do backend) e (b) usa essa sessão para chamar `POST
/api/v1/users` (rota já existente desde F1, sem tela dedicada no frontend — INDEX do
slug) com `{ name, email, password, role: 'ADMIN' }`, criando uma 2ª conta ADMIN dedicada
a este roteiro (credencial anotada como realm `admin2` em `keelson.local.json`). Sem essa
2ª conta, o fluxo de APROVAÇÃO BEM-SUCEDIDA (passo 1 abaixo) não é exercitável — a
segregação de funções recusaria qualquer aprovador que seja o único ADMIN existente
(RISK-032-001/005).

**Sujeitos concretos**: `admin1` (ADMIN semeado — usado para fechar Versões, portanto
PRODUTOR delas) e `admin2` (ADMIN recém-criado no passo acima — não-produtor de nenhum
Conteúdo bruto deste roteiro, sujeito da aprovação bem-sucedida).

**Pré-condição com receita**: login como `admin1` (ou o EDITOR seed, indiferente para
este passo) → `/content/new` → criar um NOVO Conteúdo bruto descartável (texto normativo
trivial, disciplina/tema do seed) → salvar a Quebra da regra em `/content/:id/breakdown`
→ voltar a `/content/:id` e preencher/salvar a fonte normativa (tipo do dispositivo +
citação — FR-032-013 exige, sem ela a aprovação recusa) → no bloco "Histórico de
Versões", preencher Data de fechamento legislativo e clicar "Fechar versão" (form já
existente, F8). **Restaurar ao fim**: usar "Remover" em `ContentForm` sobre o Conteúdo
bruto descartável (soft-delete reversível) — a Versão fechada e a aprovação registrada
PERMANECEM no banco por design (FR-032-005, ato irreversível); se `admin2` foi criado só
para este roteiro num ambiente compartilhado, desativá-lo via `POST
/users/:id/disable` (rota já existente).

1. **AC-032-007 (estados da UI, FR-032-008), fluxo feliz** — login como `admin2` →
   `/content/:id`: confirmar que o bloco de aprovação aparece (2 checkboxes desmarcadas,
   botão "Aprovar Versão" desabilitado). Marcar as 2 checkboxes → botão habilita. Clicar
   "Aprovar Versão": usar o painel de rede para SEGURAR a resposta de `POST
   .../versions/:number/approve` (interceptação de rede, decisão 4.319 — nunca confiar na
   latência real do ambiente local) e confirmar que o botão fica desabilitado/`aria-busy`
   durante a espera; liberar a resposta e confirmar a mensagem de sucesso ("Versão
   aprovada.") e que o bloco passa a mostrar "Aprovada por `<id de admin2>` em `<data>`".
2. **FR-032-007 (leitura do estado)** — recarregar `/content/:id`: confirmar que o
   histórico de Versões mostra a Versão como aprovada (sem precisar reabrir o formulário)
   e que o texto "Válida para a próxima Exportação: sim" aparece (sinal de alteração
   apagado).
3. **AC-032-023 (parte UI — negação de autoaprovação visível)** — repetir a pré-condição
   num 2º Conteúdo bruto descartável, fechando a Versão como `admin1` → login como
   `admin1` (o próprio produtor) → `/content/:id`: confirmar que o bloco de aprovação
   aparece com o botão "Aprovar Versão" DESABILITADO e a mensagem "Você não pode aprovar
   uma Versão que você mesmo produziu." visível, mesmo marcando as 2 checkboxes — a
   garantia REAL (o backend recusaria de qualquer forma) já está provada por gate 1 em
   TASK-033-003; este passo confirma só que o FRONTEND não deixa o clique parecer
   possível.
4. **Restaurar**: aplicar a receita de restauração acima nos 2 Conteúdos brutos
   descartáveis usados neste roteiro.

## Riscos específicos

- Gate 8 (security-engineer): **n/a** — diff é composição de tela + formulário +
  leitura, sem endpoint/rota/dado sensível novo tocado neste lado (o backend já foi
  revisado em TASK-033-003).
- RISK-032-001/RISK-032-005 (herdados) — a necessidade de 2 contas ADMIN distintas para
  exercitar o fluxo de sucesso é o próprio sintoma do risco de produto que a SPEC nomeia;
  esta TASK não o mitiga, só o roteiro de gate 9 o torna visível/nomeado (nunca assumido).
- Nenhum consumidor de nome/e-mail do aprovador por `approvedById` existe nesta fatia — o
  painel exibe o identificador cru (UUID), mesma limitação já aceita para `authorId` em
  TASK-029-004.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-158

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
