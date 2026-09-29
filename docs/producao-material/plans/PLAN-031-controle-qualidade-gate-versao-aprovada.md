# PLAN-031: Controle de qualidade e gate de versão aprovada

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.1
**Autor**: scribe
**Data**: 2026-09-27

## Aderência a guidelines

**Decisões irreversíveis do slug tocadas**: nenhuma (INDEX.md §Decisões irreversíveis:
DEC-029-003 — snapshot JSON do conteúdo versionado — é **lida** por este PLAN
(`hasVersionedContentChanged`/`toVersionedContentFields` são reusadas sem alteração de
forma), nunca revertida ou redesenhada).
**Decisões irreversíveis de outros slugs em conflito**: infra-vercel: sem bloco de
decisões (`docs/infra-vercel/` não tem `INDEX.md` — nenhum arquivo a citar; nenhum outro
slug existe neste workspace).
**Exceções aos guidelines**: nenhuma.

## Cobertura

**SPEC referenciada**: SPEC-030
**Slice declarado**: cobertura total restante (Caso D — nenhum `--covers`/`--slice`, todos
os FRs/NFRs de SPEC-030 ainda não cobertos por nenhum PLAN)

**FRs cobertos**:
- FR-030-001
- FR-030-002
- FR-030-003
- FR-030-004
- FR-030-005
- FR-030-006
- FR-030-007
- FR-030-008
- FR-030-009
- FR-030-010
- FR-030-011
- FR-030-012
- FR-030-013
- FR-030-014
- FR-030-015
- FR-030-016
- FR-030-017
- FR-030-018

**NFRs cobertos**:
- NFR-030-001
- NFR-030-002
- NFR-030-003

## 1. Visão técnica

Esta fatia (F9) acrescenta um gate de decisão humana sobre o `ContentVersion` já
append-only de F8 (SPEC-028/PLAN-029): duas colunas novas (`approvedById`/`approvedAt`),
nunca uma tabela 1:1 separada (DEC-031-004), preenchidas por uma função de serviço nova
(`approveContentVersion`) que segue o MESMO padrão transacional de `closeContentVersion`
— lock de linha do `RawContent` pai antes de qualquer decisão (DEC herdada de
DEC-029-004) — e escreve por uma vez só, via `updateMany` condicionado a
`approvedById: null` (DEC-031-009), nunca por `update` incondicional: a combinação do
lock (serializa concorrência entre fechamentos e aprovações do mesmo Conteúdo bruto) com
a escrita condicional (fecha qualquer janela residual) resolve a idempotência exigida por
FR-030-017 por construção, sem depender de retry nem de `P2002`.

A segregação de funções (FR-030-004/A-030-002) compara o ator contra 3 identidades já
existentes no schema — `ContentVersion.authorId` (quem fechou), `RawContent.authorId`
(autor original) e `RawContent.lastEditedById` (último editor) —, este último lido **ao
vivo** no momento da aprovação, nunca copiado para dentro do `contentSnapshot`
(DEC-031-006): como FR-030-015 já recusa a aprovação sempre que o sinal de alteração
pós-fechamento estiver aceso, no único momento em que uma aprovação é de fato possível
`RawContent.lastEditedById` nunca reflete uma edição posterior ao fechamento da Versão —
ler o campo ao vivo é seguro por essa mesma regra de recusa, não por uma garantia própria
desta DEC.

O "sinal de alteração pós-fechamento" que já existia só para o conteúdo versionado por
campo (`hasVersionedContentChanged`, F8) ganha aqui uma extensão SEPARADA para a Tira
mnemônica (FR-030-012), combinada por OU lógico numa função nova,
`resolveAlterationSignal` (DEC-031-007): a Tira não tem coluna própria de "alterado
depois" — o sinal é obtido reusando o evento que `tira.service.ts` já emite a cada
mutação de Quadro (`ProductionStageEvent`, `stageType: 'TIRA_MNEMONICA'`), comparando o
mais recente desses eventos contra `ContentVersion.closedAt`. Esta função única passa a
ser o ponto de leitura do sinal combinado (conteúdo OU Tira) para os 3 consumidores desta
fatia: a leitura do histórico (FR-030-007b), o gate de aprovação (FR-030-015) e a
resolução do carimbo do PDF (FR-030-010/011/012, extensão de `publication.service.ts`).

O carimbo no PDF (F6/F8) ganha um 2º modo de desenho: quando a Versão vigente está
aprovada E sem sinal de alteração aceso (`approvedAndValid`), a 1ª linha do cabeçalho
(hoje sempre `DRAFT_LABEL`) passa a exibir a marca de alcance explícito ("Conteúdo
normativo e Tira mnemônica — Versão N aprovada") — as 3 linhas seguintes (Variante,
Gerado em, Versão/Data) continuam desenhadas exatamente como hoje, sem mudança de layout
nem de `MARGIN_TOP`.

No frontend, o painel de aprovação (2 confirmações + botão com 3 estados) entra como
extensão do `content-version-history.tsx` já existente (F8) — o mesmo componente já
possui a lista de Versões e sabe qual é a vigente; nenhuma mudança de wiring em
`content/[id]/page.tsx` é necessária.

## 2. Stack e dependências

Stack herdado sem reescolha: Node 22 · Express 5 · Prisma 7 · PostgreSQL (backend,
camadas schema Zod → service → routes); Next 16 · React 19 · Redux Toolkit/RTK Query
(frontend, Server Components por padrão). Nenhuma dependência nova: a comparação de
conteúdo (`hasVersionedContentChanged`) e o sinal da Tira (`resolveAlterationSignal`) são
consultas/comparações em memória sobre tabelas já existentes (`ContentVersion`,
`ProductionStageEvent`), sem biblioteca nova em `package.json`. `pdf-lib` (DEC-025-001) é
só estendido.

## 3. Componentes

### COMP-031-001: Migração — colunas `approvedById`/`approvedAt` + valor `APROVACAO_VERSAO`
**Responsabilidade**: `ContentVersion` ganha `approvedById String?` (FK para `User`,
relação nomeada `ContentVersionApprover` — distinta de `author`, `onDelete: Restrict`
mesmo padrão de `authorId`) e `approvedAt DateTime?` — ambas nullable (uma Versão nasce
sempre não aprovada, FR-030-006 satisfeito estruturalmente: nenhuma escrita de
`closeContentVersion` toca essas 2 colunas). Acrescenta `APROVACAO_VERSAO` ao enum
`ProductionStageType` (migração aditiva, mesmo protocolo de `VERSAO_EDITORIAL`/
`MATERIAL_REFORCO`: valor só referenciado pelo código depois de aplicada; `vercel-build`
roda `prisma migrate deploy` a cada deploy do backend). Migração 100% aditiva (2
`ADD COLUMN`, 1 `ADD CONSTRAINT`, 1 `ALTER TYPE ... ADD VALUE`, sem `DROP`/`ALTER`
destrutivo) — mesmo protocolo de aplicação de F3/F5/F7/F8 (autorização do Diretor para
dev/teste, exigida pelo CLAUDE.md do workspace antes de qualquer execução).
**Realiza**: FR-030-001, FR-030-006, FR-030-007, FR-030-009, NFR-030-001
**Interface pública**: colunas `approvedById`/`approvedAt` em `ContentVersion` (Prisma
Client gerado); enum `ProductionStageType` com o valor novo.
**Dependências**: nenhuma

### COMP-031-002: `content-versions.schema.ts` — schemas de aprovação
**Responsabilidade**: `approveContentVersionSchema` — exatamente 2 campos,
`legalCheckConfirmed: z.literal(true, ...)` e `pedagogicalCheckConfirmed: z.literal(true,
...)` — qualquer valor diferente de `true` (`false`, ausente, string) falha o `parse`
com 422, ANTES de qualquer leitura do service (A-030-004: ato único atômico, sem estado
parcial persistido — FR-030-002 é satisfeito estruturalmente pelo schema, o service nunca
recebe confirmação parcial). `approveContentVersionParamsSchema` — `id` (uuid, reusa o
padrão de `rawContentIdParamSchema`) + `number` (`z.coerce.number().int().positive()`) —
o duplo travamento explícito de FR-030-014 exige o número como parte da URL, não do
corpo.
**Realiza**: FR-030-001, FR-030-002, FR-030-014
**Interface pública**: `approveContentVersionSchema` (Zod), tipo inferido
`ApproveContentVersionInput`; `approveContentVersionParamsSchema` (Zod), tipo inferido
`ApproveContentVersionParams`.
**Dependências**: nenhuma

### COMP-031-003: `content-versions.service.ts` — `resolveAlterationSignal` (função com I/O)
**Responsabilidade**: combina, por OU lógico, o sinal de alteração de CONTEÚDO
(`hasVersionedContentChanged`, reusada sem alteração de `versioned-content-diff.ts`) com
um sinal NOVO de alteração da TIRA — `tx.productionStageEvent.findFirst({ where:
{ rawContentId, stageType: 'TIRA_MNEMONICA' }, orderBy: { sequence: 'desc' }, select:
{ occurredAt: true } })` comparado contra `version.closedAt` (`occurredAt > closedAt` ⇒
Tira alterada depois do fechamento). Ordena por `sequence` (não por `occurredAt`) — mesmo
critério de desempate determinístico já usado por `listProductionStageEvents`
(AC-009-008) — e `stageType: 'TIRA_MNEMONICA'` já é emitido por `tira.service.ts` em todo
CRUD/reordenação de Quadro (DEC-031-007): nenhuma mudança em `tira.service.ts`. Short-
circuit: se o conteúdo já mudou, nem consulta o evento de Tira (custo evitado quando
desnecessário). Único ponto de manutenção do "sinal combinado" — os 3 consumidores desta
fatia (leitura do histórico, gate de aprovação, carimbo do PDF) chamam esta função,
nenhum monta a combinação por conta própria.
**Realiza**: FR-030-012, FR-030-015
**Interface pública**: `resolveAlterationSignal(rawContentId: string, current:
VersionedContentFields, version: Pick<ContentVersionRecord, 'contentSnapshot' |
'closedAt'>, db: Pick<typeof prisma, 'productionStageEvent'>): Promise<boolean>`
**Dependências**: nenhuma

### COMP-031-004: `content-versions.service.ts` — `approveContentVersion`
**Responsabilidade**: orquestra a aprovação dentro de uma `$transaction`, nesta ordem: (1)
`tx.$queryRaw` `SELECT ... FOR UPDATE` trava a linha do `RawContent` pai — mesma chamada
de `closeContentVersion`, DEC herdada de DEC-029-004 — serializando qualquer combinação
concorrente de fechamentos e aprovações do mesmo `rawContentId`; (2)
`assertRawContentReachable` (FR-030-018); (3) leitura de detalhe do `RawContent`
(`authorId`, `lastEditedById` + os 5 campos versionados) e (4) da `RuleBreakdown` (os 6
campos versionados) — mesma allowlist de `closeContentVersion`, reaproveitada via
`toVersionedContentFields`; (5) busca a Versão vigente (`orderBy: { number: 'desc' },
take: 1`) — inexistente ⇒ `NotFoundError` "Não há Versão para aprovar." (FR-030-003); (6)
`vigente.number !== number` (path) ⇒ `ConflictError` "O número informado não é mais o da
Versão vigente." (FR-030-014/AC-030-015); (7) `vigente.approvedById !== null` ⇒
`ConflictError` "Esta Versão já foi aprovada." (FR-030-017, checagem antecipada — a
garantia real está no passo 11); (8) segregação de funções: `actor.id` ∈
{`vigente.authorId`, `rawContent.authorId`, `rawContent.lastEditedById`} ⇒
`ForbiddenError` com mensagem GENÉRICA ("Você não tem permissão para aprovar esta
Versão.", nunca revelando qual das 3 identidades bateu, NFR-030-002) (FR-030-004); (9)
fonte normativa — lida do `contentSnapshot` da Versão vigente, não do `RawContent` ao
vivo (é o dado JÁ VERSIONADO daquela Versão que se avalia, A-005-008/FR-030-013) —
`sourceType`/`sourceCitation` nulos ⇒ `ConflictError` "Falta fonte normativa registrada
nesta Versão."; (10) `resolveAlterationSignal` (COMP-031-003) — `true` ⇒ `ConflictError`
"O conteúdo ou a Tira mnemônica foram alterados após o fechamento desta Versão."
(FR-030-015/AC-030-016); (11) `tx.contentVersion.updateMany({ where: { id: vigente.id,
approvedById: null }, data: { approvedById: actor.id, approvedAt: now } })` — a condição
`approvedById: null` no `where` é a garantia REAL de exatamente 1 escrita
(DEC-031-009); `result.count !== 1` ⇒ `ConflictError` de novo (fecha a janela residual
entre os passos 7 e 11 dentro da MESMA transação); (12)
`recordProductionStageEvent(tx, { stageType: 'APROVACAO_VERSAO', transitionType:
'CONCLUSAO', ... })` — sempre `CONCLUSAO` direto, nunca via `decideStageTransition`
(DEC-031-008) — ÚLTIMA chamada do corpo. Qualquer falha nos passos 1-11 propaga sem
gravar nada (fail-secure, NFR-030-001/002).
**Realiza**: FR-030-001, FR-030-002, FR-030-003, FR-030-004, FR-030-005, FR-030-006, FR-030-009, FR-030-013, FR-030-014, FR-030-015, FR-030-017, FR-030-018, NFR-030-001, NFR-030-002
**Interface pública**: `approveContentVersion(rawContentId: string, number: number,
input: ApproveContentVersionInput, actor: ContentActor, db = prisma):
Promise<ContentVersionDetail>`
**Dependências**: COMP-031-001, COMP-031-002, COMP-031-003

### COMP-031-005: `content-versions.service.ts` — `listContentVersions` estendida
**Responsabilidade**: `CONTENT_VERSION_DETAIL_SELECT`/`ContentVersionDetail` ganham
`approvedById`/`approvedAt` (colunas novas, leitura direta) e um campo COMPUTADO (não
persistido) `validApprovalForExport: boolean` — `true` só para a entrada cujo `number`
é o vigente (o maior do array já ordenado), com `approvedById !== null` e
`resolveAlterationSignal` (COMP-031-003) `false`; `false` para toda entrada não-vigente,
mesmo que ela própria tenha sido aprovada no passado (a aprovação não se propaga,
FR-030-006, e uma Versão superada nunca é a que sai impressa) — satisfaz FR-030-007(a) e
(b) na mesma resposta. Otimização: só computa `resolveAlterationSignal` (que paga até 3
leituras extras — `RawContent`, `RuleBreakdown`, `ProductionStageEvent` condicional)
quando a Versão vigente JÁ está aprovada (`approvedById !== null`); senão
`validApprovalForExport` já é `false` por construção, sem custo extra. Custo total segue
dependendo só de `N` (Versões daquele Conteúdo bruto) mais um número CONSTANTE de
leituras adicionais — nunca proporcional ao acervo (NFR-030-003/AC-030-013).
**Realiza**: FR-030-007, NFR-030-003
**Interface pública**: `listContentVersions(rawContentId: string, actor: ContentActor,
db = prisma): Promise<ContentVersionDetail[]>` (mesma assinatura; `ContentVersionDetail`
estendida)
**Dependências**: COMP-031-001, COMP-031-003

### COMP-031-006: `content-versions.routes.ts` — `POST /contents/:id/versions/:number/approve`
**Responsabilidade**: rota nova, `verifyOrigin` como 1º handler + `requireRole('POST',
'/contents/:id/versions/:number/approve', 'ADMIN')` — **sem** `'EDITOR'` na lista
(FR-030-016, deny-by-default: EDITOR cai fora por omissão, mesmo padrão de
`route-authz-matrix`) — chamando `approveContentVersion`. Responde `200` (atualiza um
recurso já existente, não cria um novo — ao contrário do `201` de `POST
/contents/:id/versions`, que cria uma Versão nova). Nenhuma rota
`PATCH`/`PUT`/`DELETE` sobre Versão ou sobre aprovação existe neste módulo nem em
nenhum outro — a ausência de caminho de escrita além deste é o que garante, também na
camada HTTP, que nenhuma ação reverte uma aprovação já registrada (FR-030-005/AC-030-005).
**Realiza**: FR-030-005, FR-030-016
**Interface pública**: rota montada em `contentVersionsRoutes` (mesmo `Router` das 2
rotas existentes).
**Dependências**: COMP-031-002, COMP-031-004

### COMP-031-007: Extensão de `publication.service.ts` — `resolveVersionStampForPdf`
**Responsabilidade**: troca a chamada direta a `hasVersionedContentChanged` pela chamada
a `resolveAlterationSignal` (COMP-031-003) — o campo `alteredAfterClosure` de
`VersionStampForPdf` passa a refletir conteúdo OU Tira (extensão de FR-028-011 por
FR-030-012), sem mudar o nome do campo (o consumidor em `pdf-composer.ts` já lê esse
booleano, comportamento existente preservado). Acrescenta o campo novo
`approvedAndValid: boolean` — `latest.approvedById !== null && !alteredAfterClosure` —
`null` (nenhuma Versão fechada) continua devolvendo `null` inteiro (FR-030-011,
comportamento herdado de F8/AC-030-021, intocado).
**Realiza**: FR-030-010, FR-030-011, FR-030-012
**Interface pública**: `VersionStampForPdf` estendida com `approvedAndValid: boolean`;
assinatura de `resolveVersionStampForPdf` inalterada.
**Dependências**: COMP-031-003

### COMP-031-008: Extensão de `pdf-composer.ts` — carimbo de aprovação no cabeçalho
**Responsabilidade**: a 1ª linha do cabeçalho (hoje sempre `DRAFT_LABEL`, desenhada por
`drawDraftHeader`) passa a ser escolhida por uma função nova, `resolveHeaderLabel(version:
VersionStampForPdf | null): string` — `version?.approvedAndValid === true` ⇒ "Conteúdo
normativo e Tira mnemônica — Versão {N} aprovada" (FR-030-010, declarando o alcance
explícito, RISK-030-002); qualquer outro caso (nunca aprovada, superada sem aprovação
própria, ou sinal de alteração aceso) ⇒ `DRAFT_LABEL` inalterado (FR-030-011). As 3
linhas seguintes (Variante, Gerado em, Versão/Data — esta última via `versionStampText`,
já Tira-aware por herdar `alteredAfterClosure` de COMP-031-007) continuam desenhadas sem
mudança de posição nem de `MARGIN_TOP`/`CONTENT_TOP_Y` — mudança puramente de TEXTO da 1ª
linha, nunca de layout.
**Realiza**: FR-030-010, FR-030-011
**Interface pública**: `resolveHeaderLabel` (nova, interna); `drawDraftHeader` sem
mudança de assinatura.
**Dependências**: COMP-031-007

### COMP-031-009: Tipos espelhados — `ContentVersion` estendido (backend + frontend)
**Responsabilidade**: `interface ContentVersion` em `mnemonicos-backend/src/domain/
types.ts` e em `mnemonicos-frontend/src/types/domain.ts` ganham `approvedById: string |
null`, `approvedAt: string | null` (frontend) / `Date | null` (backend) e
`validApprovalForExport: boolean` — os 3 campos que `listContentVersions`/
`closeContentVersion`/`approveContentVersion` agora devolvem em toda resposta
(`closeContentVersion` sempre `approvedById: null, approvedAt: null,
validApprovalForExport: false` — uma Versão recém-fechada nunca está aprovada;
`approveContentVersion`, em caso de sucesso, sempre `validApprovalForExport: true` — a
própria aprovação só se completa quando o sinal de alteração está apagado, A-030-008).
`APROVACAO_VERSAO` (valor do enum `ProductionStageType`) fica **backend-only**, sem
espelho — mesmo padrão de `VERSAO_EDITORIAL`/DEC-010-006.
**Realiza**: FR-030-007, NFR-030-001
**Interface pública**: `interface ContentVersion { id; rawContentId; number;
legislativeClosureDate; authorId; closedAt; approvedById; approvedAt;
validApprovalForExport }`
**Dependências**: COMP-031-001

### COMP-031-010: `store/api.ts` — mutation `approveContentVersion`
**Responsabilidade**: `approveContentVersion` (mutation, `invalidatesTags:
['ContentVersion']` — mesma tag de `closeContentVersion`/`listContentVersions`, sem
invalidar `'RawContent'`: aprovar não toca nenhum campo do `RawContent`, o carimbo de
última alteração de SPEC-005 segue intocado por este ato).
**Realiza**: FR-030-001, FR-030-008
**Interface pública**: `useApproveContentVersionMutation`; `ApproveContentVersionArgs {
rawContentId: string; number: number; legalCheckConfirmed: boolean;
pedagogicalCheckConfirmed: boolean }`
**Dependências**: COMP-031-006, COMP-031-009

### COMP-031-011: `content-version-history.tsx` — painel de aprovação (extensão)
**Responsabilidade**: acrescenta, dentro do MESMO componente (nenhuma mudança de wiring
em `content/[id]/page.tsx`), um bloco de aprovação visível só quando `useMeQuery().data
?.role === 'ADMIN'` (best-effort de UX — a autorização REAL é a rota do backend,
`requireRole`, FR-030-016) e só quando existe uma Versão vigente (`versions.at(-1)`) sem
`approvedById`. Consome `useGetRawContentQuery({ id: rawContentId })` (mesmo padrão de
dedup de `ContentSupplementaryPanel`, sem round-trip extra) para conhecer
`authorId`/`lastEditedById` do `RawContent` e desabilitar o botão, com motivo textual
("Você não pode aprovar uma Versão que você mesmo produziu."), quando `me.id` coincide
com qualquer uma das 3 identidades produtoras — a MESMA régua de FR-030-004, replicada no
cliente só para UX (a recusa que vale de fato é a do backend, AC-030-004). 2 checkboxes
("Checagem jurídica confirmada" / "Checagem pedagógica confirmada", FR-030-001/002); o
botão "Aprovar Versão" só habilita com as 2 marcadas E o ator não-produtor, com os 3
estados observáveis de FR-030-008 (desabilitado/`aria-busy` durante o envio; sucesso —
"Versão aprovada." — ou falha com a mensagem do backend, mesmo padrão de extração de erro
já usado pelo formulário de fechamento no mesmo arquivo). Versão vigente já aprovada:
mostra "Aprovada por {approvedById} em {approvedAt}" (ou "válida para a próxima
Exportação: sim/não", refletindo `validApprovalForExport`) em vez do formulário
(FR-030-007).
**Realiza**: FR-030-007, FR-030-008
**Interface pública**: `<ContentVersionHistory rawContentId={string} />` (assinatura
inalterada)
**Dependências**: COMP-031-009, COMP-031-010

### COMP-031-012: `route-authz-matrix.integration.test.ts` — tripwire +1
**Responsabilidade**: a rota nova (`POST /contents/:id/versions/:number/approve`) entra
no censo de `collectRoutes(apiRoutes)` automaticamente (a suíte deriva do array montado,
não de contagem hardcoded) — confirma 401 sem sessão, 403 para EDITOR (papel insuficiente
— a lista de papéis declarados é só `'ADMIN'`), 403/401 nunca 200 para ator sem sessão ou
com papel não-declarado.
**Realiza**: FR-030-016, NFR-030-002
**Interface pública**: nenhuma (suíte de teste)
**Dependências**: COMP-031-006

### COMP-031-013: `contents-frontend-contract.test.ts` — paridade `ContentVersion` estendida
**Responsabilidade**: o bloco `describe('paridade cross-repo — ContentVersion')` já
existente (F8) passa a comparar os 3 campos novos (`approvedById`, `approvedAt`,
`validApprovalForExport`) nos dois lados (`domain/types.ts` × `types/domain.ts`) e contra
o tipo de retorno real de `listContentVersions`/`approveContentVersion`
(`ContentVersionDetail`) — mesmo par duplo já aplicado a `Contrast`/`ContrastDetail`.
**Realiza**: FR-030-007, NFR-030-001
**Interface pública**: nenhuma (suíte de teste)
**Dependências**: COMP-031-009

## 4. Fluxos principais

**Fluxo 1 — Aprovação (feliz, AC-030-001/007/008)**: ADMIN elegível marca as 2 checkboxes
e aciona "Aprovar Versão" → `POST /contents/:id/versions/:number/approve` (`{
legalCheckConfirmed: true, pedagogicalCheckConfirmed: true }`) → `verifyOrigin` →
`requireRole` (só ADMIN) → Zod (recusa qualquer confirmação não-`true`) →
`approveContentVersion`: lock do `RawContent` pai → alcance → leitura RawContent/
RuleBreakdown → Versão vigente existe e `number` bate → não aprovada ainda → ator não é
produtor → fonte normativa presente no snapshot → sem sinal de alteração (conteúdo nem
Tira) → `updateMany` grava `approvedById`/`approvedAt` (1 linha) → evento
`APROVACAO_VERSAO`/`CONCLUSAO` → commit → 200 → UI mostra sucesso, a Versão aparece como
aprovada no histórico (`invalidatesTags`).

**Fluxo 2 — Recusa por segregação de funções (AC-030-004/023)**: o próprio ADMIN que
fechou a Versão (ou o autor original, ou quem editou por último o Conteúdo bruto antes do
fechamento) tenta aprovar → todos os passos anteriores passam → passo 8 identifica
`actor.id` numa das 3 identidades → `ForbiddenError` genérico, sem revelar qual identidade
bateu nem outro dado do Conteúdo bruto (NFR-030-002) → nenhuma escrita, rollback.

**Fluxo 3 — Recusa por sinal de alteração pós-fechamento (AC-030-016/024)**: Versão
vigente aprovável, mas um campo versionado OU a Tira mnemônica foi alterado depois do
fechamento dela → `resolveAlterationSignal` retorna `true` → `ConflictError`, nenhuma
escrita — a mesma checagem, chamada pela leitura (Fluxo 4) e pela exportação (Fluxo 5),
já teria mostrado esse estado ao ADMIN antes do clique.

**Fluxo 4 — Leitura do histórico com estado de aprovação (AC-030-001/007/020)**: `GET
/contents/:id/versions` → `requireRole` (sem `verifyOrigin`) → `listContentVersions`:
alcance comum → `findMany` ordenado → para a Versão vigente já aprovada,
`resolveAlterationSignal` recalcula o sinal ATUAL (pode ter mudado desde a aprovação) →
`validApprovalForExport` reflete se a PRÓXIMA Exportação sairia aprovada ou rascunho, sem
alterar o fato histórico da aprovação em si (FR-030-005).

**Fluxo 5 — Exportação com/sem Versão aprovada válida (AC-030-009/010/011/012/021/024)**:
`exportPublication` (F6/F8) → `resolveVersionStampForPdf` (estendida, COMP-031-007) →
`approvedAndValid` → COMP-031-008 desenha a marca de alcance explícito no lugar de
"RASCUNHO" quando `true`; em qualquer outro caso (nunca aprovada, Versão superada sem
aprovação própria — FR-030-006 —, ou sinal de alteração aceso — conteúdo ou Tira),
desenha "RASCUNHO" como hoje, com a marca de alteração posterior quando aplicável
(comportamento herdado de F8, intocado quando não há Versão nenhuma — AC-030-021).

## 5. Modelo de dados

```prisma
model ContentVersion {
  id String @id @default(uuid(7))

  rawContentId String
  rawContent   RawContent @relation(fields: [rawContentId], references: [id], onDelete: Restrict)

  number Int

  legislativeClosureDate DateTime

  authorId String
  author   User   @relation(fields: [authorId], references: [id], onDelete: Restrict)

  closedAt DateTime @default(now())

  contentSnapshot Json

  /// NOVO (F9, DEC-031-004): estado de aprovação — colunas na MESMA linha, não uma
  /// tabela 1:1 separada. `null` = ainda não aprovada (estado inicial de toda Versão
  /// recém-fechada, FR-030-006). Nunca sobrescrito depois de setado uma vez
  /// (FR-030-005) — a garantia é o `updateMany` condicional em `approveContentVersion`,
  /// não a ausência de coluna de update (ao contrário de `updatedAt`/`deletedAt`, que
  /// este model nunca teve).
  approvedById String?
  approver     User?     @relation("ContentVersionApprover", fields: [approvedById], references: [id], onDelete: Restrict)
  approvedAt   DateTime?

  @@unique([rawContentId, number])
  @@map("content_versions")
}
```

Enum `ProductionStageType` ganha `APROVACAO_VERSAO` (migração aditiva). Migração 100%
aditiva (2 `ADD COLUMN` nullable, 1 `ADD CONSTRAINT` de FK, 1 `ALTER TYPE ... ADD VALUE`,
sem `DROP`/`ALTER` destrutivo) — mesmo protocolo de aplicação de F3/F5/F7/F8 (autorização
do Diretor para dev/teste antes de qualquer execução, regra incondicional do CLAUDE.md do
workspace; produção via `vercel-build` + `prisma migrate deploy` a cada deploy). Nenhuma
mudança em `RawContent`, `RuleBreakdown`, `MnemonicStrip` ou `MnemonicFrame`.

## 6. Decisões arquiteturais

### Decisões herdadas
- **DEC-031-001** [herdada] Lock de linha do `RawContent` pai (`SELECT ... FOR UPDATE`)
  como 1ª chamada de `approveContentVersion`, antes de qualquer decisão — mesmo padrão de
  `closeContentVersion` — fonte: precedente de código (`content-versions.service.ts`,
  DEC-029-004/PLAN-029 §6), aplicado por instrução explícita desta execução.
- **DEC-031-002** [herdada] A rota de aprovação é restrita ao papel ADMIN, sem `'EDITOR'`
  na lista de `requireRole` (deny-by-default) — fonte: SPEC-030 A-030-005/FR-030-016.
- **DEC-031-003** [herdada] Segregação de funções por comparação de exatamente 3
  identidades produtoras (quem fechou, autor original do Conteúdo bruto, último editor
  antes do fechamento) — fonte: SPEC-030 A-030-002/FR-030-004.

### DEC-031-004: Aprovação como colunas novas em `ContentVersion`, não tabela 1:1 separada

**Contexto**: FR-030-001 exige registrar quem aprovou e quando; a relação entre uma
Versão e sua aprovação é estritamente 1:1 opcional (`null` até ser aprovada, nunca depois
desfeita — FR-030-005) e nunca cresce em granularidade nesta fatia (A-030-004: ato único
atômico, sem confirmações separadas por ator/momento).

**Decisão**: `approvedById`/`approvedAt` são colunas nullable na PRÓPRIA linha de
`ContentVersion`, não uma tabela `ContentVersionApproval` separada.

**Alternativas consideradas**:
- Tabela 1:1 separada (`ContentVersionApproval`), descartada porque acrescenta 1 `JOIN` a
  TODA leitura de estado de aprovação (FR-030-007/NFR-030-003) sem ganho real: a relação
  é estritamente 1:1 opcional, nunca miúda o suficiente (não existe hoje nem se prevê
  granularidade por item de checklist) para justificar uma tabela própria — o custo do
  join extra não muda a ordem de grandeza da consulta, só a complexidade de manutenção.

**Consequências**: leitura de "está aprovada" é 1 `SELECT` só (mesmo já feito hoje por
`listContentVersions`), sem join adicional; se o checklist crescer (item por item,
múltiplos atores), migrar para tabela própria exige mover dado já existente (2 colunas →
1 linha por combinação), migração reversível.

**Reabrir se**: a aprovação ganhar campos que cresçam de verdade (auditoria detalhada por
item de checklist, múltiplos atores/momentos) — A-030-004 já nomeia essa condição como
"Reabrir se" da própria SPEC.

**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-031-005: Checklist (2 confirmações) não persiste como colunas próprias

**Contexto**: FR-030-001/002 exigem as 2 confirmações (jurídica/pedagógica) para
aprovar, mas nunca um estado de aprovação PARCIAL (A-030-004).

**Decisão**: nenhuma coluna `legalCheckConfirmed`/`pedagogicalCheckConfirmed` é gravada —
a existência de `approvedById`/`approvedAt` não-nulos já É, por construção, a prova de
que as 2 confirmações ocorreram (o `parse` do Zod recusa qualquer confirmação
diferente de `true` antes do service rodar, COMP-031-002).

**Alternativas consideradas**:
- 2 colunas boolean persistidas, descartada porque, dado que o schema NUNCA aceita
  `false` chegando ao service, essas 2 colunas sempre valeriam `true` quando
  `approvedById` não é nulo — redundância pura, sem informação nova que a ausência/
  presença de `approvedById` já não comunique.

**Consequências**: nenhuma auditoria granular de QUAL confirmação foi dada — só o fato
agregado "foi aprovada" (aceito, A-030-004 é premissa explícita da SPEC, não lacuna desta
fatia).

**Reabrir se**: o produto pedir granularidade futura (aprovação parcial, 1 confirmação
por vez) — A-030-004 já nomeia essa condição como "Reabrir se" da própria SPEC.

**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-031-006: Segregação de funções lê `RawContent.lastEditedById` AO VIVO

**Contexto**: FR-030-004 exige recusar quando o ator é o último editor do Conteúdo bruto
antes do fechamento da Versão. `RawContent.lastEditedById` é um carimbo SEM trilha
histórica (SPEC-005) — sempre reflete a edição mais recente, não necessariamente a mais
recente ANTES do fechamento.

**Decisão**: ler `RawContent.lastEditedById` diretamente (ao vivo), sem copiá-lo para
dentro do `contentSnapshot` no momento do fechamento. Isto é seguro porque FR-030-015 já
recusa a aprovação enquanto o sinal de alteração pós-fechamento estiver aceso — qualquer
edição do `RawContent` DEPOIS do fechamento liga esse sinal e bloqueia a aprovação por
outro motivo antes mesmo de chegar à checagem de segregação. Logo, no único momento em
que uma aprovação é de fato possível, `lastEditedById` necessariamente reflete uma edição
anterior ou igual ao fechamento — nunca posterior.

**Alternativas consideradas**:
- Copiar `authorId`/`lastEditedById` para dentro do `contentSnapshot` no fechamento,
  descartada porque contaminaria a allowlist de `versioned-content-diff.ts` (hoje só
  campos de CONTEÚDO comparável) com campos de IDENTIDADE, que servem a um propósito
  diferente (segregação de funções, não detecção de mudança de texto) — inflaria o
  snapshot sem necessidade, dado que o campo ao vivo já é seguro pela ordenação acima.

**Consequências**: nenhuma leitura adicional além da já feita em `assertRawContentReachable`/
detalhe do `RawContent` — sem custo extra. A segurança desta decisão depende
estruturalmente de FR-030-015 continuar recusando toda aprovação com sinal aceso; se essa
regra mudar, esta DEC precisa ser reavaliada junto.

**Reabrir se**: FR-030-015 for relaxado a ponto de permitir aprovação com sinal de
alteração aceso.

**Emenda (2026-09-27, furo no plano achado pelo gate 8 da Wave 2 — premissa refutada)**:
a premissa "qualquer edição do `RawContent` depois do fechamento liga o sinal" é falsa.
`updateRawContent` carimba `lastEditedById`/`lastEditedAt` em todo PATCH, inclusive `{}`,
só de campo não versionado (`topicId`) ou re-save com os mesmos valores — nenhum deles
acende `hasVersionedContentChanged`, e a identidade do último editor de antes do
fechamento é sobrescrita (bypass provado contra Postgres real). A leitura ao vivo
continua, mas com uma guarda adicional fail-secure, conforme o desempate que o próprio
FR-030-004 prescreve ("na dúvida sobre qual identidade se aplica, recusa"):
`approveContentVersion` recusa quando `rawContent.lastEditedAt !== null &&
rawContent.lastEditedAt > vigente.closedAt` — o último editor pré-fechamento deixou de
ser conhecido, e a saída é fechar uma nova Versão. Alternativa descartada agora: congelar
`lastEditedById` do instante do fechamento numa coluna própria de `ContentVersion` — exige
migração e aval do Diretor; é a condição de reabertura abaixo.
**Reabrir se (emenda)**: o bloqueio por edição sem mudança versionada depois do
fechamento virar atrito real no piloto — aí congelar a identidade no fechamento (coluna
nova, migração aditiva).

**Emenda 2 (2026-09-27, re-verificação do gate 8 da Wave 2 — vetor concorrente)**: a
comparação `lastEditedAt > closedAt` ordena por relógio de aplicação, e o `now` de
`updateRawContent` é calculado ANTES de o UPDATE esperar o `FOR UPDATE` do fechamento —
uma edição concorrente commita depois do fechamento com `lastEditedAt < closedAt`
(provado com interleaving forçado). A guarda passa a ordenar pelo banco: recusa quando
existe `ProductionStageEvent` `stageType: 'CONTEUDO_BRUTO'` do `rawContentId` com
`sequence` maior que a do último `VERSAO_EDITORIAL` dele (`sequence` é autoincrement
atribuído no INSERT, depois do lock; `updateRawContent` emite `CONTEUDO_BRUTO` em toda
chamada, inclusive PATCH `{}`, e `closeContentVersion` emite `VERSAO_EDITORIAL` antes do
commit). Sem relógio, sem migração, sem tocar `contents.service.ts`. Alternativa
descartada: tomar o lock em `updateRawContent` antes de calcular `now` — mexe no módulo
de F2 e deixa resíduo de diferença de relógio entre instâncias serverless.

**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-031-007: Sinal de alteração da Tira reusa `ProductionStageEvent` existente, sem índice novo

**Contexto**: FR-030-012 estende o sinal de alteração pós-fechamento (antes só de
conteúdo, F8) para também cobrir a Tira mnemônica — que não tem coluna própria de
"alterado depois do fechamento X".

**Decisão**: o sinal da Tira é obtido consultando `MAX` (por `sequence`, não por
`occurredAt` — mesmo desempate determinístico de AC-009-008) do
`ProductionStageEvent` com `stageType: 'TIRA_MNEMONICA'` para aquele `rawContentId`, já
emitido por `tira.service.ts` em todo CRUD/reordenação de Quadro, e comparando seu
`occurredAt` contra `ContentVersion.closedAt`. Nenhum índice composto novo
(`rawContentId, stageType, sequence`) é criado nesta fatia — o índice existente
(`@@index([rawContentId, sequence])`) já restringe a busca ao conjunto de eventos daquele
Conteúdo bruto (pequeno e limitado, nunca proporcional ao acervo), satisfazendo
NFR-030-003 sem migração adicional.

**Alternativas consideradas**:
- `touch` de `MnemonicStrip.updatedAt` a cada mutação de Quadro, descartada porque exige
  tocar `tira.service.ts` (módulo estável desde F4, já testado) em múltiplos pontos
  (linhas 287/315/525/586/654/739) só para replicar um sinal que o evento de etapa já
  carrega — risco de regressão num módulo que esta fatia não precisa abrir.
- Índice composto `(rawContentId, stageType, sequence)` novo desde já, descartada por
  falta de medição real que justifique a migração adicional — o volume de eventos por
  Conteúdo bruto é pequeno (dezenas, não milhares) e o índice existente já limita a busca
  a esse conjunto.

**Consequências**: `resolveAlterationSignal` paga até 1 leitura extra de
`ProductionStageEvent` por chamada (só quando o conteúdo não mudou — short-circuit) —
custo O(1) por Conteúdo bruto, nunca por acervo.

**Reabrir se**: medição real (gate 10) mostrar essa consulta cara demais sem o índice
composto — aí a migração é aditiva (`CREATE INDEX`), sem perda de dado.

**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-031-008: Evento de aprovação sempre `CONCLUSAO` direto

**Contexto**: `recordProductionStageEvent` decide ABERTURA/CONCLUSAO/RETRABALHO a partir
de histórico de edição em estágios com ciclo (Conteúdo bruto, Quebra da regra) — a
aprovação de Versão, como o próprio fechamento dela (DEC-029-005), é um ato atômico sem
esse ciclo: nunca há "reabrir uma aprovação" (FR-030-005).

**Decisão**: o ato de aprovação emite `stageType: 'APROVACAO_VERSAO'` sempre como
`transitionType: 'CONCLUSAO'` direto, via o parâmetro de override já existente em
`ProductionStageEventInput.transitionType` — nunca por `decideStageTransition`.

**Alternativas consideradas**:
- Reusar `decideStageTransition` genericamente, descartada pelo MESMO motivo de
  DEC-029-005: pressupõe um ciclo "abrir→editar→concluir" que a aprovação nunca terá
  (uma 2ª tentativa é recusada antes de qualquer evento, nunca vira RETRABALHO).

**Consequências**: o histórico de eventos de `APROVACAO_VERSAO` sempre mostra só
`CONCLUSAO` — consistente com o ato atômico exigido por FR-030-005/017.

**Reabrir se**: nunca — a terminalidade da aprovação (FR-030-005) é premissa da própria
SPEC, não uma condição de mundo que possa mudar sem reabrir a SPEC primeiro.

**Irreversível**: não
**Aderência à ficha/perfil**: nova

### DEC-031-009: Idempotência via `updateMany` condicionado a `approvedById: null`

**Contexto**: FR-030-017 exige exatamente 1 registro de aprovação mesmo sob tentativas
concorrentes/simultâneas sobre a mesma Versão. O lock de linha do `RawContent` pai
(DEC-031-001 herdada) já serializa as transações concorrentes, mas depender só da ORDEM
de execução dentro da transação (ler `approvedById`, decidir, escrever por `update`
incondicional) deixa a garantia real presa à disciplina de manter a checagem (passo 7)
sempre antes da escrita (passo 11) — qualquer refatoração futura que separe os dois passos
reabriria a janela.

**Decisão**: a escrita em si usa `tx.contentVersion.updateMany({ where: { id:
vigente.id, approvedById: null }, data: { approvedById, approvedAt } })` — a condição
`approvedById: null` no PRÓPRIO `where` da escrita é a garantia atômica (o banco só
aplica a 1ª chamada que encontrar a linha ainda não-aprovada); `result.count !== 1` é
tratado como "já aprovada", nunca como sucesso silencioso. Mesma técnica de guarda
composta já usada para a Pegadinha elaborada em F7 (`updateMany` composto, mais seguro
que o padrão leitura-então-escrita em 2 passos).

**Alternativas consideradas**:
- Confiar só na checagem de leitura do passo 7 + `update` incondicional, descartada
  porque depende inteiramente da ordem de código nunca mudar — sem uma 2ª camada que
  torne a condição parte da PRÓPRIA operação de escrita, uma refatoração futura que
  separasse leitura e escrita (ex.: mover a leitura para fora da transação) reabriria a
  corrida sem nenhum teste apontar a regressão até uma corrida real acontecer.

**Consequências**: 2 camadas de defesa contra a mesma corrida (lock de linha + escrita
condicional) — custo desprezível (a condição extra no `where` não muda o plano de
consulta, é a mesma linha já identificada por `id`).

**Reabrir se**: nunca — é defesa em profundidade sobre uma garantia (FR-030-017) que não
muda.

**Irreversível**: não
**Aderência à ficha/perfil**: nova

## 8. Riscos técnicos

- **TRISK-031-001** Corrida entre `approveContentVersion` e `closeContentVersion` no
  mesmo `RawContent` (ex.: um ADMIN aprova a Versão 3 enquanto outro fecha a Versão 4)
  (mitigação: ambas tomam `SELECT ... FOR UPDATE` na mesma linha do `RawContent` pai,
  antes de qualquer decisão — serializam por construção, DEC-031-001 herdada).
- **TRISK-031-002** `resolveAlterationSignal` acrescenta até 3 leituras extras
  (`RawContent` atual, `RuleBreakdown` atual, `ProductionStageEvent` condicional) a cada
  chamada de `listContentVersions`/`approveContentVersion`/`exportPublication` (mitigação:
  custo O(1) por chamada, independente de `N` Versões ou do tamanho do acervo —
  NFR-030-003 preservado; short-circuit evita a 3ª leitura quando o conteúdo já mudou;
  revisitar só se medição real mostrar impacto perceptível em volume alto).
- **TRISK-031-003** `onDelete: Restrict` na FK `approvedById → User` bloqueia
  hard-delete de um ADMIN que já aprovou alguma Versão, enquanto essa Versão existir —
  mesmo padrão de toda FK de autoria do slug (mitigação: aceito nesta fatia, herda
  RISK-028-005; fica para a fatia futura que definir expurgo).
- **TRISK-031-004** Acoplamento novo entre `content-versions.service.ts` (dono de
  `resolveAlterationSignal`, que agora também lê `ProductionStageEvent` do módulo `tira`)
  e o conceito de `stageType: 'TIRA_MNEMONICA'` — nenhum import de função de
  `tira.service.ts` é necessário (só o valor do enum, já compartilhado), então a
  dependência é só sobre o CONTRATO do evento, não sobre o módulo (mitigação:
  dependência unidirecional, sem ciclo).
- **TRISK-031-005** RISK-030-005 (contas ADMIN fantoche criadas para contornar a
  segregação de funções) segue sem controle técnico nesta fatia — herdado, sem
  mitigação nova (mitigação: aceito, mesma régua de RISK-030-001/RISK-002-001; controle
  detectivo fica para fatia futura se o piloto reportar o padrão).

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs
- [ ] Todos os NFRs cobertos têm verificação
- [ ] Decisões DEC refletidas no código
- [ ] Aderência à ficha/perfil validada
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates)
- [ ] Métrica da SPEC operacional (§1.3, `Fonte de medição: instrumentação`): consulta
  cruzando `ProductionStageEvent` (`stageType: 'APROVACAO_VERSAO'`, novo nesta fatia,
  COMP-031-001) por `rawContentId`/`occurredAt` com o total de Versões vigentes fechadas
  do acervo ativo (`ContentVersion` mais recente por `rawContentId`, join com
  `RawContent.deletedAt IS NULL`) — o numerador exclui aprovações cuja Versão foi
  invalidada por alteração pós-fechamento, recalculando retroativamente o sinal
  combinado (conteúdo OU Tira) a partir do log de `ProductionStageEvent`
  (`CONTEUDO_BRUTO`/`QUEBRA_DA_REGRA`/`TIRA_MNEMONICA`, todos já append-only desde F3/F4)
  ocorrido ENTRE o `closedAt` da Versão aprovada e o momento da consulta — mesmo padrão
  retroativo já usado pelo DoD de PLAN-029 (a comparação contra `contentSnapshot` só
  reflete o estado ATUAL, não o estado num instante passado). A métrica-guarda invariante
  — (a) 0 aprovações onde `approvedById` coincide com `ContentVersion.authorId`/
  `RawContent.authorId`/`RawContent.lastEditedById` (consulta direta, sem retroatividade:
  as 4 colunas convivem na mesma linha ou em join de 1 salto); (b) 0 `PublicationEvent`
  com o carimbo de aprovação estampado sobre sinal de alteração aceso (cruzando
  `PublicationEvent.occurredAt` com o mesmo sinal retroativo acima) — roda sobre tabelas
  já existentes ao fim deste PLAN (nenhuma instrumentação além do valor de enum de
  COMP-031-001). Dono: time de engenharia.

## 10. Não coberto por este PLAN

- Papel dedicado de "revisor jurídico" no enum de papéis (SPEC-030 §4.2).
- Checklist ou aprovação cobrindo Contraste, Pegadinha elaborada, Flashcard ou Associação
  visual — só o conteúdo normativo já versionado por F8 mais a Tira mnemônica entram no
  escopo do gate (SPEC-030 §4.2, RISK-030-002).
- Estado explícito de "reprovada"/rejeição persistido (SPEC-030 §4.2).
- Edição, revogação ou reabertura de uma aprovação já registrada, por qualquer papel,
  inclusive ADMIN (SPEC-030 §4.2, FR-030-005).
- Notificação, alerta ou fila de trabalho de Versões pendentes de aprovação (SPEC-030
  §4.2).
- Cálculo ou alerta de vencimento/expiração de legislação (herdado do out-of-scope de F8).
- Painel estratégico (F10) e fila/calendário editorial (F11) — o evento
  `APROVACAO_VERSAO` é emitido, mas nenhum painel ou fila o consome nesta fatia.
- Reabertura do pipeline de composição do PDF (F6) além de acrescentar o carimbo de
  aprovação — nenhuma outra mudança na diagramação do documento (SPEC-030 §4.2).
- Controle técnico para detectar contas ADMIN fantoche criadas para contornar a
  segregação de funções (RISK-030-005) — controle detectivo fica para fatia futura.
- Expurgo ou migração do modelo `Mnemonic` legado dormente (RISK-011-001/RISK-005-004) —
  segue sem solução, sem relação com esta fatia.
