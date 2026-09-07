# PLAN-012: Tira mnemônica como sequência de quadros

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.1
**Autor**: keelson (scribe)
**Data**: 2026-09-06

## Aderência a guidelines

**Ficha/perfil de linguagem**: backend (`guidelines/project/backend/node-22.md`) + frontend
(`guidelines/project/frontend/next-16.md`) — única fatia desta SPEC com tela própria (F4).
**Stack vigente herdado**: Node 22 · TypeScript 6 · Prisma 7 (2 models novos + 1 valor
aditivo em enum existente, migração aditiva) · Zod 4 (schema novo) · Jest 30 (extensão de
suíte de paridade + suíte nova unit/integration, reuso de fixtures de F3) · Next 16 ·
React 19 · Redux Toolkit + RTK Query · Tailwind 4 (tokens `--link`/`--danger` já
existentes, nenhum token novo). Nenhuma dependência nova em `package.json` dos dois repos.
**Padrão arquitetural seguido**: módulo por domínio `schema → service → routes`
(precedente `contents/`, `mnemonicos-backend/src/modules/contents/`); mecanismo de
instrumentação de etapa reusado **sem redesenho** (`production-events.service.ts`,
COMP-010-002 de PLAN-010); guarda de alcance por autoria reusada por **export**, não
duplicada (`assertRawContentReachable`, `contents.service.ts:360-382`); Server Component
por padrão + `'use client'` só no componente com estado (precedente
`(interno)/content/[id]/breakdown/page.tsx` + `rule-breakdown-form.tsx`); estado de
servidor via RTK Query, nunca slice manual.
**Decisões irreversíveis do slug tocadas**: nenhuma (INDEX.md declara nenhuma DEC
irreversível até aqui — as 12 DECs de PLAN-003 são todas reversíveis; as 10 DECs deste
PLAN também nascem reversíveis, §6).
**Decisões irreversíveis de outros slugs em conflito**: nenhuma — nenhum outro slug deste
workspace tem `INDEX.md` com a seção "Decisões irreversíveis" hoje (`docs/infra-vercel/`
ainda não tem `INDEX.md`).
**Exceções aos guidelines**: nenhuma. `GET /contents/:id/strip` com efeito colateral de
geração (get-or-generate idempotente) não é desvio do padrão REST do projeto — mesmo
espírito do `PUT` idempotente de `saveRuleBreakdown` (upsert com efeito colateral de
criação, `contents.service.ts:459-494`); a escolha e o trade-off ficam documentados em
DEC-012-009, não como exceção silenciosa.

## Cobertura

**SPEC referenciada**: SPEC-011
**Slice declarado**: cobertura total (Caso D — nenhum PLAN anterior cobre SPEC-011, que é
nova; sem FEATs declaradas, A-011-010)

**FRs cobertos**:
- FR-011-001
- FR-011-002
- FR-011-003
- FR-011-004
- FR-011-005
- FR-011-006
- FR-011-007
- FR-011-008
- FR-011-009
- FR-011-010
- FR-011-011

**NFRs cobertos**:
- NFR-011-001
- NFR-011-002
- NFR-011-003
- NFR-011-004
- NFR-011-005
- NFR-011-006

**Cobertura agregada do slug**:
- Total na SPEC: 11 FRs + 6 NFRs
- Cobertos por planos anteriores: 0 (SPEC-011 é nova; nenhum PLAN a cobria antes)
- Cobertos por este: 11 FRs + 6 NFRs (100%)
- Gap restante: 0

## 1. Visão técnica

Esta fatia introduz a **Tira mnemônica** como duas entidades novas —
`MnemonicStrip` (1:1 com `RuleBreakdown`, mesmo padrão de `RuleBreakdown` 1:1
`RawContent` de F2) e `MnemonicFrame` (N:1 com `MnemonicStrip`, o Quadro) — e um módulo
backend em camadas (`tira.schema.ts` → `tira.service.ts` → `tira.routes.ts`) que reusa,
sem redesenho, dois mecanismos já provados do projeto: o guard de alcance por autoria de
F2 (`assertRawContentReachable`, agora exportado de `contents.service.ts` para reuso —
COMP-012-005) e o mecanismo de instrumentação de etapa de F3
(`recordProductionStageEvent`/`decideStageTransition`, `production-events.service.ts`) —
`TIRA_MNEMONICA` entra como valor aditivo do enum `ProductionStageType` já existente
(`schema.prisma:69-75`, que já previa a extensão em comentário).

O insight central de produto (correção do PO na SPEC) é que a fronteira
abertura/conclusão/retrabalho da nova etapa **não** coincide com a geração automática:
a geração emite só **abertura**; a **conclusão** só ocorre na 1ª mutação humana de Quadro
(criar, editar, remover ou reordenar) depois da geração; toda mutação humana seguinte
emite **retrabalho**. Como `decideStageTransition` já decide puramente a partir do
histórico do par (`rawContentId`, `stageType`) — sem saber "isto é geração ou mutação
humana" — nenhuma alteração no mecanismo de F3 é necessária: o `tira.service.ts` só
precisa chamar `recordProductionStageEvent` no ponto certo de cada fluxo (§4,
DEC-012-006).

Geração idempotente sob concorrência (AC-011-025, correção do PO) reusa o mesmo
precedente de `saveRuleBreakdown`: a constraint `ruleBreakdownId @unique` em
`MnemonicStrip` serializa duas tentativas concorrentes de "abrir pela 1ª vez" —
quem perde a corrida recebe uma violação de unicidade dentro da própria transação e
cai para o caminho de leitura, sem gerar uma 2ª Tira nem emitir uma 2ª abertura
(DEC-012-008, mesmo raciocínio de DEC-010-007).

A garantia de posição contígua e sem duplicidade sob falha parcial (NFR-011-002,
RISK-011-003) vem de uma única primitiva reusada pelas 3 mutações que reindexam Quadros
(adicionar, remover, reordenar): reindexação em **duas fases** dentro da mesma transação
interativa — desloca todas as posições afetadas para um intervalo temporário fora da
faixa 1..N, depois grava as posições finais — nunca a ordem "shift direto", que colidiria
com o índice único `@@unique([stripId, position])` (defesa em profundidade, DEC-012-002)
sempre que duas posições precisassem trocar de lugar na mesma operação (DEC-012-003).

Frontend: tela nova `(interno)/content/[id]/tira` segue **exatamente** o padrão de
`(interno)/content/[id]/breakdown` — Server Component puro resolvendo o `id` da rota,
client component com estado para CRUD + reordenação (controles simples de mover
posição, sem drag-and-drop — A-011-009) e os três estados observáveis por ação
(FR-011-011). Nenhum registro novo em `internal-routes.ts`/`proxy.ts` é necessário: o
segmento `/content/:path*` já cobre `/content/[id]/tira` (registrado em F2,
`COMP-006-012` de PLAN-006) — confirmado, não presumido.

## 2. Stack e dependências

- **Prisma 7**: 2 models novos (`MnemonicStrip`, `MnemonicFrame`) + 1 valor aditivo em
  enum existente (`ProductionStageType` ganha `TIRA_MNEMONICA`) + 1 relação reversa
  aditiva em `RuleBreakdown` (`strip MnemonicStrip?`) — migração aditiva (autorização do
  Diretor exigida antes de gerar/aplicar, protocolo do CLAUDE.md do workspace, mesma
  régua de PLAN-006/PLAN-010).
- **Zod 4**: `tira.schema.ts` novo (schemas de adicionar/editar/reordenar Quadro).
- **Jest 30 + ts-jest**: extensão de `tests/unit/domain-types-parity.test.ts` (cobertura
  do valor novo); teste novo `tests/unit/tira-frontend-contract.test.ts` (paridade
  cross-repo das interfaces de Tira/Quadro, molde `contents-frontend-contract.test.ts`);
  suíte unit (regra pura de geração inicial + reindexação) e integration (transação
  real, concorrência, os 3 gatilhos de evento) nova, reusando
  `tests/support/production-events-fixtures.ts` (`createUser`/`createTopic`/
  `createRawContent`).
- **Next 16 + React 19 + RTK Query**: endpoints novos em `store/api.ts` (tag
  `'MnemonicStrip'`), tela nova em `(interno)/content/[id]/tira`, extensão de
  `types/domain.ts`. Tailwind 4: tokens `--link`/`--danger` já existentes reusados, nenhum
  token novo.
- Nenhuma dependência nova de `package.json` nos dois repos.

## 3. Componentes

### COMP-012-001: Modelagem de dados — Tira mnemônica e Quadro
**Responsabilidade**: acrescenta ao `schema.prisma` os models `MnemonicStrip` (1:1 com
`RuleBreakdown`, FK `ruleBreakdownId @unique`, `onDelete: Cascade`) e `MnemonicFrame`
(N:1 com `MnemonicStrip`, FK `stripId`, `onDelete: Cascade`, `@@unique([stripId,
position])` — defesa em profundidade, DEC-012-002), o valor aditivo `TIRA_MNEMONICA` no
enum `ProductionStageType` existente (`schema.prisma:69-75`) e a relação reversa aditiva
em `RuleBreakdown` (`strip MnemonicStrip?`). `Mnemonic` legado (`schema.prisma:180-204`)
permanece intocado (A-011-007, RISK-011-001).
**Realiza**: FR-011-001, FR-011-002, FR-011-003, FR-011-005, FR-011-006, FR-011-010, NFR-011-002, NFR-011-004, NFR-011-006
**Interface pública**: `model MnemonicStrip` (`@@map("mnemonic_strips")`), `model
MnemonicFrame` (`@@map("mnemonic_frames")`) conforme §5; `enum ProductionStageType`
estendido; arquivo de migração versionado no diff.
**Dependências**: nenhuma

### COMP-012-002: Espelho de tipos backend — `src/domain/types.ts`
**Responsabilidade**: `PRODUCTION_STAGE_TYPES` (`domain/types.ts:83`) ganha
`'TIRA_MNEMONICA'` — único ponto de manutenção para o teste de paridade cross-repo
(`domain-types-parity.test.ts:142-152`) continuar verde. Nenhuma interface nova entra
aqui (`MnemonicStrip`/`MnemonicFrame` ficam locais a `tira.service.ts`, mesma resolução
de `RawContentSummary`/`RuleBreakdownDetail` em `contents.service.ts`).
**Realiza**: NFR-011-004
**Interface pública**: `PRODUCTION_STAGE_TYPES: readonly ['CONTEUDO_BRUTO',
'QUEBRA_DA_REGRA', 'TIRA_MNEMONICA']`; `type ProductionStageType` (união derivada).
**Dependências**: COMP-012-001

### COMP-012-003: `tira.schema.ts` — validação de entrada (Zod)
**Responsabilidade**: schemas de adicionar Quadro (`text`, `position`), editar texto de
Quadro (`text`), reordenar Quadros (`order`: array completo de ids na sequência final
desejada) e param de Quadro (`frameId`, UUID). Reusa `rawContentIdParamSchema` de
`contents.schema.ts` para o `:id` da rota — não recria o parâmetro.
**Realiza**: FR-011-003, FR-011-004, FR-011-006, NFR-011-005
**Interface pública**:
- `addMnemonicFrameSchema` — `text` (string não-vazia), `position` (inteiro ≥ 1).
- `updateMnemonicFrameSchema` — `text` (string não-vazia).
- `reorderMnemonicFramesSchema` — `order` (array de UUIDs, ≥ 1 item).
- `mnemonicFrameIdParamSchema` — `frameId` (UUID).
**Dependências**: nenhuma

### COMP-012-004: `tira.service.ts` — regra de negócio central
**Responsabilidade**: get-or-generate idempotente da Tira (FR-011-001/002/008,
AC-011-025); regra pura de geração inicial a partir dos Blocos não-vazios da Quebra, na
ordem canônica (FR-011-001, AC-011-001/002); primitiva de reindexação atômica em duas
fases, reusada por adicionar/remover/reordenar (FR-011-003/005/006, NFR-011-002);
CRUD de Quadro com verificação de pertencimento ao `stripId` derivado do `rawContentId`
da rota (defesa contra substituição de id — mesma cautela de A01 de F2); integração com
`recordProductionStageEvent` (COMP-010-002 de PLAN-010, reusado sem redesenho) no ponto
certo de cada fluxo — abertura só na geração, conclusão na 1ª mutação humana, retrabalho
nas seguintes (FR-011-008/009, DEC-012-006); alcance por autoria herdado via
`assertRawContentReachable` (COMP-012-005) em toda função, cobrindo também
NFR-011-006 (soft-delete do `RawContent` de origem torna a cadeia inteira inalcançável).
Toda mutação roda dentro de `$transaction` (fail-secure, NFR-011-003, AC-011-015).
**Realiza**: FR-011-001, FR-011-002, FR-011-003, FR-011-004, FR-011-005, FR-011-006, FR-011-007, FR-011-008, FR-011-009, FR-011-010, NFR-011-001, NFR-011-002, NFR-011-003, NFR-011-006
**Interface pública**:
```ts
// tira.service.ts
export interface MnemonicFrameDetail {
  id: string;
  text: string;
  position: number;
  originBlock: string | null;
}

export interface MnemonicStripDetail {
  id: string;
  frames: MnemonicFrameDetail[]; // ordenados por position asc
}

export async function openMnemonicStrip(
  rawContentId: string,
  actor: ContentActor,
  db?: MnemonicStripClient,
): Promise<MnemonicStripDetail>;
// get-or-generate idempotente: cria a Tira + 1 Quadro por Bloco não-vazio na 1ª
// abertura (decide ABERTURA); reabertura devolve a Tira existente sem gerar de
// novo (FR-011-002) nem emitir evento novo. 409 (ConflictError) se a Quebra da
// regra do rawContentId ainda não foi salva (AC-011-023).

export async function addMnemonicFrame(
  rawContentId: string,
  input: AddMnemonicFrameInput,
  actor: ContentActor,
  db?: MnemonicStripClient,
): Promise<MnemonicStripDetail>;

export async function updateMnemonicFrameText(
  rawContentId: string,
  frameId: string,
  input: UpdateMnemonicFrameInput,
  actor: ContentActor,
  db?: MnemonicStripClient,
): Promise<MnemonicStripDetail>;

export async function removeMnemonicFrame(
  rawContentId: string,
  frameId: string,
  actor: ContentActor,
  db?: MnemonicStripClient,
): Promise<MnemonicStripDetail>;

export async function reorderMnemonicFrames(
  rawContentId: string,
  input: ReorderMnemonicFramesInput,
  actor: ContentActor,
  db?: MnemonicStripClient,
): Promise<MnemonicStripDetail>;

// pura, sem I/O — testável isoladamente (mesmo espírito de decideStageTransition)
export function buildInitialFrames(
  breakdown: Pick<RuleBreakdownDetail, 'concept' | 'action' | 'object' | 'condition' | 'exception'>,
): Array<{ text: string; position: number; originBlock: string }>;
```
**Dependências**: COMP-012-001, COMP-012-003, COMP-012-005, COMP-010-002

### COMP-012-005: EMENDA em `contents.service.ts` — export de `assertRawContentReachable`
**Responsabilidade**: promove `assertRawContentReachable` (hoje função privada,
`contents.service.ts:360-382`) a `export`, sem alterar sua lógica nem sua ordem de
guardas (inexistente → fora do alcance → soft-deleted). Único ponto de mudança em
arquivo já entregue por PLAN-006 — nenhuma outra função de `contents.service.ts` é
tocada.
**Realiza**: NFR-011-001, NFR-011-006
**Interface pública**: `export async function assertRawContentReachable(rawContentId:
string, actor: ContentActor, db: RawContentClient): Promise<void>` — assinatura
idêntica à atual, só a visibilidade muda.
**Dependências**: COMP-006-003

### COMP-012-006: `tira.routes.ts` — superfície HTTP sob a barreira deny-by-default
**Responsabilidade**: expõe as 6 rotas da Tira mnemônica (EMENDA DEC-012-011: geração
migrou de `GET` para `POST`, `GET` vira leitura pura — 5 rotas originais + 1 nova),
cada uma com declaração explícita de papéis na montagem (mesmo padrão de
`contents.routes.ts`), `verifyOrigin` como 1º handler nas 5 mutações (agora incluindo o
`POST` de geração); monta o router em `src/http/routes.ts` (`apiRoutes.use
(tiraRoutes)`, depois de `contentsRoutes`), árvore plana (nenhum `.use('/prefixo',
sub)`). `PUT /contents/:id/strip/frames/order` e `PATCH|DELETE
/contents/:id/strip/frames/:frameId` não colidem por serem métodos distintos — a
suíte `route-authz-matrix` precisa registrar as 6 chaves exatas, sem depender de
match de padrão entre a rota estática (`order`) e a rota `:frameId`.
**Realiza**: FR-011-001, FR-011-002, FR-011-003, FR-011-004, FR-011-005, FR-011-006, FR-011-007, NFR-011-001
**Interface pública** (árvore plana; caminho completo em cada `requireRole`):
- `GET /contents/:id/strip` → `requireRole('GET','/contents/:id/strip','EDITOR',
  'ADMIN')` — leitura pura (404 se ainda não aberta, 409 se a Quebra da regra ainda
  não foi salva); NUNCA gera (DEC-012-011).
- `POST /contents/:id/strip` → `verifyOrigin` + `requireRole('POST',
  '/contents/:id/strip','EDITOR','ADMIN')` — abre/gera a Tira, get-or-generate
  idempotente (FR-011-001/002/007/008; DEC-012-011, EMENDA Wave 5 — migrado de `GET`
  por achado de CSRF do security-engineer).
- `POST /contents/:id/strip/frames` → `verifyOrigin` + `requireRole('POST',
  '/contents/:id/strip/frames','EDITOR','ADMIN')` — adicionar Quadro (FR-011-003).
- `PATCH /contents/:id/strip/frames/:frameId` → `verifyOrigin` + `requireRole('PATCH',
  '/contents/:id/strip/frames/:frameId','EDITOR','ADMIN')` — editar texto (FR-011-004).
- `DELETE /contents/:id/strip/frames/:frameId` → `verifyOrigin` + `requireRole('DELETE',
  '/contents/:id/strip/frames/:frameId','EDITOR','ADMIN')` — remover (FR-011-005).
- `PUT /contents/:id/strip/frames/order` → `verifyOrigin` + `requireRole('PUT',
  '/contents/:id/strip/frames/order','EDITOR','ADMIN')` — reordenar (FR-011-006).
**Dependências**: COMP-012-003, COMP-012-004

### COMP-012-007: Extensão de `domain-types-parity.test.ts` — cobertura de `TIRA_MNEMONICA`
**Responsabilidade**: nenhuma mudança de asserção é necessária além do array já
estendido em COMP-012-002 — o bloco existente (`domain-types-parity.test.ts:142-152`)
já compara `PRODUCTION_STAGE_TYPES` contra o enum real do `schema.prisma` por extração
genérica; este componente é a **verificação** de que o teste continua verde com o valor
novo nos dois lados (schema + array), não uma reescrita do teste.
**Realiza**: NFR-011-004
**Interface pública**: n/a (confirmação sobre teste existente).
**Dependências**: COMP-012-002

### COMP-012-008: Rede de paridade cross-repo nova — `tira-frontend-contract.test.ts`
**Responsabilidade**: arquivo novo, molde `contents-frontend-contract.test.ts` (leitura
textual, sem AST): compara `MnemonicFrameDetail`/`MnemonicStripDetail`
(`tira.service.ts`, backend) contra `MnemonicFrame`/`MnemonicStrip` (`types/domain.ts`,
frontend) campo-a-campo, nomes canônicos vencendo do lado do backend.
**Realiza**: FR-011-001, FR-011-003, FR-011-004, FR-011-005, FR-011-006, FR-011-007
**Interface pública**: casos de teste; nenhum código de produção.
**Dependências**: COMP-012-004, COMP-012-009

### COMP-012-009: Extensão de `types/domain.ts` (frontend) — `MnemonicStrip`/`MnemonicFrame`
**Responsabilidade**: acrescenta as interfaces espelhando o formato REAL devolvido por
`tira.service.ts` (mesma resolução de `RawContentSummary`/`RuleBreakdown` — o contrato é
provado pela rede de paridade, COMP-012-008, não pela declaração em si).
**Realiza**: FR-011-001, FR-011-003, FR-011-004, FR-011-005, FR-011-006, FR-011-007
**Interface pública**:
```ts
export interface MnemonicFrame {
  id: string;
  text: string;
  position: number;
  originBlock: string | null;
}

export interface MnemonicStrip {
  id: string;
  frames: MnemonicFrame[];
}
```
**Dependências**: nenhuma

### COMP-012-010: Extensão de `store/api.ts` (RTK Query)
**Responsabilidade**: endpoints novos (get-or-generate + 4 mutações), tag
`'MnemonicStrip'` acrescentada a `TAG_TYPES`.
**Realiza**: FR-011-003, FR-011-004, FR-011-005, FR-011-006, FR-011-007
**Interface pública**:
- `openMnemonicStrip` (`GET /contents/:rawContentId/strip`, `providesTags:
  ['MnemonicStrip']`)
- `addMnemonicFrame`, `updateMnemonicFrame`, `removeMnemonicFrame`,
  `reorderMnemonicFrames` (mutations, `invalidatesTags: ['MnemonicStrip']`, cada uma
  devolve a `MnemonicStrip` inteira já reordenada — o cliente nunca mescla estado
  parcial)
**Dependências**: COMP-012-009

### COMP-012-011: Tela Server Component — `(interno)/content/[id]/tira/page.tsx`
**Responsabilidade**: casca Server Component, mesmo padrão de
`(interno)/content/[id]/breakdown/page.tsx` — só resolve `id` da rota e renderiza o
client component; nenhum `'use client'` aqui. Sem registro novo em
`internal-routes.ts`/`proxy.ts` (o segmento `/content/:path*` já cobre esta rota,
COMP-006-012 de PLAN-006).
**Realiza**: FR-011-001, FR-011-007
**Interface pública**: rota `/content/[id]/tira`.
**Dependências**: COMP-012-012

### COMP-012-012: Client component — quadro a quadro da Tira mnemônica
**Responsabilidade**: `'use client'`, usa `useOpenMnemonicStripQuery` +
`useAddMnemonicFrameMutation`/`useUpdateMnemonicFrameMutation`/
`useRemoveMnemonicFrameMutation`/`useReorderMnemonicFramesMutation`
(COMP-012-010). Lista de Quadros na ordem de posição; ação de adicionar Quadro (texto +
posição); edição de texto inline por Quadro; remoção com confirmação; reordenação por
controles simples (mover para cima/para baixo — A-011-009, sem drag-and-drop). Três
estados observáveis por ação (em andamento/sucesso/falha, FR-011-011), texto de
interface em pt-BR (NFR-011-005). Tira sem nenhum Quadro (após remover o último,
AC-011-024) mostra estado de "Tira vazia" com a ação de criar Quadro disponível — sem
disparar regeneração.
**Realiza**: FR-011-001, FR-011-003, FR-011-004, FR-011-005, FR-011-006, FR-011-007, FR-011-011, NFR-011-005
**Interface pública**: componente client `mnemonic-strip-board`.
**Dependências**: COMP-012-010

### COMP-012-013: Navegação entre Quebra da regra e Tira mnemônica
**Responsabilidade**: acrescenta, na tela existente `(interno)/content/[id]/breakdown`
(`rule-breakdown-form.tsx`), um link condicional para `/content/[id]/tira` — habilitado
só quando a Quebra da regra já foi salva com sucesso (o próprio
`useGetRuleBreakdownQuery`/`useSaveRuleBreakdownMutation` já em uso ali informa esse
estado); ausência de Quebra salva orienta em português a concluí-la primeiro
(AC-011-023), sem oferecer a ação de gerar a Tira.
**Realiza**: FR-011-001
**Interface pública**: link condicional em `rule-breakdown-form.tsx`; nenhuma rota nova.
**Dependências**: COMP-012-011

### COMP-012-014: Suíte de teste — regra pura, transação real e concorrência
**Responsabilidade**: unit (`buildInitialFrames` — geração a partir de Blocos
vazios/preenchidos, ordem canônica; reindexação em duas fases — casos de adicionar no
meio, remover do meio, reordenar completo); integration (transação real via
`tira.service.integration.test.ts`, molde `contents.service.integration.test.ts`):
geração idempotente sob concorrência real (`Promise.all`, AC-011-025), os 3 gatilhos de
evento (abertura só na geração, conclusão na 1ª mutação humana, retrabalho nas
seguintes), fail-secure (mock de falha na emissão reverte a mutação inteira,
AC-011-015), alcance por autoria (EDITOR não alcança Tira de outro EDITOR,
AC-011-022), soft-delete do `RawContent` de origem torna a cadeia inalcançável
(AC-011-020). Reusa `tests/support/production-events-fixtures.ts`
(`createUser`/`createTopic`/`createRawContent`) — não recria fixture equivalente.
**Realiza**: FR-011-001, FR-011-002, FR-011-003, FR-011-004, FR-011-005, FR-011-006, FR-011-007, FR-011-008, FR-011-009, FR-011-010, FR-011-011, NFR-011-001, NFR-011-002, NFR-011-003, NFR-011-006
**Interface pública**: n/a (arquivos de teste).
**Dependências**: COMP-012-004, COMP-012-006

## 4. Fluxos principais

**F-1 · Abrir a Tira mnemônica (geração idempotente sob concorrência)** —
`openMnemonicStrip`, dentro de `$transaction`:
1. `assertRawContentReachable(rawContentId, actor, tx)` — recusa se inexistente, fora do
   alcance ou soft-deleted (mesma mensagem "Conteúdo bruto não encontrado.").
2. `tx.ruleBreakdown.findUnique({ where: { rawContentId } })` — se `null`,
   `ConflictError` orientando a concluir a Quebra da regra primeiro (AC-011-023).
3. `try { tx.mnemonicStrip.create({ data: { ruleBreakdownId, frames: { create:
   buildInitialFrames(breakdown) } } }) }` — 1 Quadro por Bloco não-vazio, ordem
   canônica CONCEITO→AÇÃO→OBJETO→CONDIÇÃO→EXCEÇÃO, posições 1..N sem lacuna
   (AC-011-001/002).
4. Sucesso da criação → `recordProductionStageEvent(tx, { rawContentId, stageType:
   'TIRA_MNEMONICA', actorId, now })` — 0 eventos existentes para o par → decide
   **abertura** (FR-011-008/AC-011-013).
5. `catch` violação de unicidade em `ruleBreakdownId` (outra transação venceu a corrida)
   → lê e devolve a Tira já criada pela vencedora, **sem** chamar
   `recordProductionStageEvent` de novo (a vencedora já gravou a abertura) — garante
   exatamente 1 Tira e exatamente 1 evento de abertura por Quebra da regra, qualquer que
   seja a ordem de chegada (AC-011-025).
6. Reabertura de uma Tira já existente (sem passar pelo `catch`, `tx.mnemonicStrip.
   findUnique` direto) devolve os Quadros na ordem de `position` persistida
   (FR-011-007, AC-011-003, AC-011-012).

**F-2 · Adicionar Quadro** — `addMnemonicFrame`, dentro de `$transaction`:
1. `assertRawContentReachable` + localizar `stripId` via `ruleBreakdownId` do
   `rawContentId`.
2. Criar o novo Quadro com posição temporária fora da faixa 1..N.
3. `reassignPositions` (primitiva de 2 fases, §1) com a lista completa de ids na ordem
   final desejada (Quadros existentes + o novo, no índice pedido) — desloca os Quadros
   subsequentes sem lacuna nem duplicidade (FR-011-003, AC-011-004).
4. `recordProductionStageEvent(tx, {..., stageType: 'TIRA_MNEMONICA'})` — decide
   **conclusão** (1ª mutação humana) ou **retrabalho** (demais), conforme o histórico já
   registrado (FR-011-009).
5. Falha em qualquer passo reverte a transação inteira — nenhum Quadro parcial
   (AC-011-005).

**F-3 · Editar texto de Quadro** — `updateMnemonicFrameText`: guarda (pertencimento do
`frameId` ao `stripId` do `rawContentId`) + `update` do `text`, posição intocada
(FR-011-004, AC-011-006/007); mesma emissão de evento do passo 4 acima.

**F-4 · Remover Quadro** — `removeMnemonicFrame`, dentro de `$transaction`:
1. Guarda de pertencimento + `delete` do Quadro.
2. `reassignPositions` com os Quadros restantes ordenados pela posição atual — recompõe
   1..N-1 sem lacuna (FR-011-005, AC-011-008). Remover o último Quadro restante deixa a
   lista vazia — `reassignPositions` com lista vazia é no-op; a Tira mostra estado
   vazio, sem regeneração automática (AC-011-024, FR-011-002 preservado).
3. Emissão de evento (conclusão/retrabalho) como nos fluxos acima.

**F-5 · Reordenar Quadros** — `reorderMnemonicFrames`: valida que o `order` recebido é
exatamente o conjunto de ids do `stripId` (nem falta, nem sobra — 400/409 caso
contrário), chama `reassignPositions(tx, stripId, order)` direto (FR-011-006,
AC-011-010) e emite o evento. Falha no meio não persiste nenhuma posição nova
(NFR-011-002, AC-011-011).

**Reindexação atômica em duas fases** (`reassignPositions`, primitiva reusada por
F-2/F-4/F-5): dado `orderedFrameIds` (sequência final desejada), dentro da mesma
transação —
1. **Fase 1 (offset)**: desloca as posições atuais dos Quadros afetados para um
   intervalo temporário fora de 1..N (evita colisão do índice único enquanto os valores
   finais ainda não foram todos escritos).
2. **Fase 2 (final)**: grava, para cada id de `orderedFrameIds` na ordem dada, `position
   = índice + 1`.
Sem essa duas-fases, uma troca de posições entre dois Quadros na mesma operação
colidiria com `@@unique([stripId, position])` a meio caminho (DEC-012-003).

**F-6 · Alcance por autoria e soft-delete do pai** — toda função de `tira.service.ts`
abre com `assertRawContentReachable(rawContentId, actor, tx)`: EDITOR só alcança a Tira
de Conteúdo bruto de sua própria autoria (NFR-011-001, AC-011-022); soft-delete do
`RawContent` de origem torna a Tira e todos os Quadros inalcançáveis pela mesma cadeia
de guarda, sem campo `deletedAt` próprio em `MnemonicStrip`/`MnemonicFrame`
(NFR-011-006, AC-011-020).

**F-7 · Encerramento do legado `Mnemonic`** — nenhuma função nova lê ou escreve
`Mnemonic.hook`/`decoding` (FR-011-010, AC-011-016); confirmado pelo reconhecimento
técnico: não há consumidor de código ativo hoje em nenhum dos dois repos.

## 5. Modelo de dados

Migração **aditiva** ao `mnemonicos-backend/prisma/schema.prisma`. Tipos lidos do schema
real (`RuleBreakdown.rawContentId String @unique`, `schema.prisma:333-350`;
`ProductionStageType`, `schema.prisma:69-75`, já com comentário explícito de extensão
aditiva prevista).

```prisma
enum ProductionStageType {
  CONTEUDO_BRUTO
  QUEBRA_DA_REGRA
  TIRA_MNEMONICA
  // Fatias futuras (F5 biblioteca visual, F6 publicação, F8 versionamento, F9 QC)
  // acrescentam valores aqui — migração aditiva, sem redesenho do mecanismo
  // (NFR-009-001/DEC-010-001, agora também NFR-011-004).
}

/// Tira mnemônica — 1:1 com a Quebra da regra (FK `@unique`), mesmo padrão de
/// RuleBreakdown 1:1 RawContent (A-011-001, DEC-012-001). Sem `deletedAt`
/// própria — herda a inalcançabilidade do `RawContent` de origem pela cadeia
/// Strip → RuleBreakdown → RawContent (NFR-011-006).
model MnemonicStrip {
  id String @id @default(uuid(7))

  ruleBreakdownId String        @unique
  ruleBreakdown   RuleBreakdown @relation(fields: [ruleBreakdownId], references: [id], onDelete: Cascade)

  frames MnemonicFrame[]

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@map("mnemonic_strips")
}

/// Quadro — unidade atômica da Tira (N:1 com MnemonicStrip). `position`
/// contígua e única por Tira em qualquer estado observável (NFR-011-002,
/// DEC-012-002) — defesa em profundidade ao lado da transação que a escreve.
model MnemonicFrame {
  id String @id @default(uuid(7))

  stripId String
  strip   MnemonicStrip @relation(fields: [stripId], references: [id], onDelete: Cascade)

  text     String
  position Int

  /// Um dos 5 nomes de campo de RuleBreakdown ('concept'|'action'|'object'|
  /// 'condition'|'exception'), gravado só no instante da geração inicial; ou
  /// `null` para Quadro criado manualmente pelo EDITOR (FR-011-003).
  /// Informativo — nenhuma regra de negócio desta fatia lê este campo
  /// (A-011-011, DEC-012-004).
  originBlock String?

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@unique([stripId, position])
  @@map("mnemonic_frames")
}
```

Alteração aditiva no model existente (relação reversa, obrigatória no Prisma):

```prisma
model RuleBreakdown {
  // ...campos atuais (schema.prisma:333-350)...
  strip MnemonicStrip?
}
```

Notas:
- **`onDelete: Cascade`** nas duas FKs novas, mesmo padrão de `RawContent →
  RuleBreakdown` (só relevante sob eventual hard-delete futuro; a remoção do acervo
  desta fatia continua soft, herdada de F2 — DEC-012-001).
- **`originBlock`** é `String?` livre, não enum de banco (DEC-012-004) — sem
  consumidor de código que valide seu conteúdo nesta fatia.
- **`Mnemonic.hook`/`decoding`/`source`** (`schema.prisma:180-204`) **não são
  tocados** — nenhuma coluna alterada, nenhum dado migrado (FR-011-010, A-011-007,
  RISK-011-001).
- Migração: 2 `CREATE TABLE` (`mnemonic_strips`, `mnemonic_frames`), 1 `ALTER TYPE
  ProductionStageType ADD VALUE 'TIRA_MNEMONICA'`, `ADD CONSTRAINT` (2 FKs + 1 unique
  simples + 1 unique composto) + índices implícitos das FKs — nenhum `DROP`/`ALTER`
  destrutivo. Autorização do Diretor exigida antes de gerar/aplicar (protocolo do
  CLAUDE.md do workspace) — passo explícito da TASK de migração, não decidido aqui
  (DEC-012-010).

## 6. Decisões arquiteturais

### DEC-012-001: Modelos `MnemonicStrip` (1:1 `RuleBreakdown`) e `MnemonicFrame` (N:1 `MnemonicStrip`)
**Contexto**: A-011-001 já fixa que a Tira é 1:1 com a Quebra da regra; a SPEC exige
CRUD + reordenação livre de Quadros (FR-011-003/004/005/006) — a modelagem precisa
suportar consulta ordenada e escrita atômica de posição.
**Decisão**: dois models Prisma próprios, nomes em inglês, seguindo exatamente o padrão
já usado por `RuleBreakdown` 1:1 `RawContent` (FK `@unique`, `onDelete: Cascade` a
partir do pai).
**Alternativas consideradas**:
- Embutir os Quadros como coluna `Json` em `RuleBreakdown` (sem model novo), descartada
  porque uma coluna JSON não oferece índice único nativo sobre `position` nem consulta
  ordenada eficiente pelo Postgres — a garantia de "nunca duas posições iguais nem
  lacuna" (NFR-011-002) teria que ser inteiramente aplicacional, sem nenhuma barreira de
  banco (mesmo raciocínio que justifica DEC-012-002 abaixo).
**Consequências**: 2 tabelas novas + 1 relação reversa aditiva em `RuleBreakdown`.
**Reabrir se**: nunca — schema aditivo é sempre reversível por nova migração.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (mesmo padrão de `RuleBreakdown`/`RawContent`)

### DEC-012-002: Índice único de posição por Tira (`@@unique([stripId, position])`)
**Contexto**: NFR-011-002 exige que nenhuma falha deixe duas posições iguais ou uma
lacuna; a atomicidade transacional (DEC-012-003) já entrega essa garantia em teoria, mas
um bug de lógica na reindexação (ex.: off-by-one, ordem de escrita errada) poderia
persistir silenciosamente um estado inválido se nada no banco o impedisse.
**Decisão**: `@@unique([stripId, position])` em `MnemonicFrame`, como defesa em
profundidade ao lado da transação.
**Alternativas consideradas**:
- Sem índice único, confiando só na transação, descartada porque um bug de lógica no
  serviço (não na garantia teórica de atomicidade) produziria posição duplicada
  silenciosamente persistida — sem nenhuma barreira que o reprovasse em runtime; o
  índice transforma esse bug insidioso (dado corrompido sem erro) numa falha imediata e
  ruidosa (constraint violation, transação inteira revertida).
**Consequências**: toda escrita de posição precisa respeitar a reindexação em 2 fases
(DEC-012-003) — um `UPDATE` direto que tentasse trocar duas posições na mesma operação
falharia contra este índice, o que é o comportamento desejado (falha ruidosa > dado
corrompido silencioso).
**Reabrir se**: nunca — a garantia de banco é sempre mais barata que confiar
inteiramente na correção do código de reindexação, qualquer que seja o volume.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (mesmo padrão de defesa em profundidade de
`RuleBreakdown.rawContentId @unique`)

### DEC-012-003: Reindexação atômica em duas fases (offset temporário → posição final)
**Contexto**: RISK-011-003 exige que a garantia de atomicidade de NFR-011-002 seja
**real**, provada pelo gate de revisão — não apenas declarada. Um `UPDATE` direto que
troque a posição de dois ou mais Quadros na mesma operação (ex.: mover o Quadro 1 para
a posição 3, empurrando os demais) colide com `@@unique([stripId, position])`
(DEC-012-002) no meio do caminho, a menos que o índice fosse `DEFERRABLE INITIALLY
DEFERRED` (Postgres adia a checagem para o commit).
**Decisão**: reindexação em duas fases dentro da mesma `$transaction` — fase 1 desloca
as posições afetadas para um intervalo temporário fora de 1..N; fase 2 grava as
posições finais. Nenhuma colisão transitória, sem precisar de constraint `DEFERRABLE`.
**Alternativas consideradas**:
- `@@unique` com `DEFERRABLE INITIALLY DEFERRED` (editando manualmente o SQL da
  migração gerada), descartada porque o Prisma não expõe essa cláusula
  declarativamente no `schema.prisma` — exigiria um passo manual de edição do arquivo
  de migração gerado, fácil de esquecer ou perder numa migração futura que o
  regenere, fugindo do fluxo 100% declarativo que o projeto usa hoje para todo o
  resto do schema.
- Shift direto sem duas fases (confiando na ordem de escrita para nunca colidir),
  descartada: já é o cenário que RISK-011-003 nomeia como falha — qualquer reordenação
  que troque posições relativas (não só desloque em sequência) colide com
  DEC-012-002 sem o offset intermediário.
**Consequências**: cada reindexação custa até 2×N `UPDATE`s (N = nº de Quadros
afetados) em vez de N — custo aceito, registrado como TRISK-012-002 para medição real
no gate 10.
**Reabrir se**: o volume real de Quadros por Tira crescer a ponto do custo de 2×N
round-trips doer na prática (medição real, Charter Art. 8 — não palpite).
**Irreversível**: nao
**Aderência à ficha/perfil**: nova (primeira reindexação em duas fases do projeto)

### DEC-012-004: Carimbo de proveniência (`originBlock`) como `String?` livre, não enum de banco
**Contexto**: A-011-011 exige um metadado informativo (referência ao Bloco de origem)
gravado só na geração, sem nenhuma regra de negócio desta fatia que o leia ou dependa
dele.
**Decisão**: campo `originBlock String?` — texto livre, sem constraint de banco
sobre o conjunto de valores aceitos.
**Alternativas consideradas**:
- Enum Prisma dedicado (`RuleBreakdownField` com os 5 valores), descartada por YAGNI
  (mesmo raciocínio de DEC-010-006): nenhuma regra de negócio lê ou valida este campo
  hoje; um enum de banco adicionaria uma migração de tipo extra e mais uma entrada a
  manter na rede de paridade cross-repo (`domain-types-parity.test.ts`) sem nenhum
  consumidor que se beneficie da garantia de integridade referencial.
**Consequências**: nenhuma garantia de banco impede um valor fora dos 5 nomes esperados
de `RuleBreakdown` — aceitável porque nenhum código lê o campo para decidir algo.
**Reabrir se**: uma fatia futura (ex.: F9, revisão jurídica) precisar filtrar/agrupar
por bloco de origem com garantia de integridade referencial no banco — nesse momento a
migração para enum entra no mesmo diff do primeiro consumidor real.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova (primeiro campo informativo nullable sem enum do
projeto)

### DEC-012-005: `TIRA_MNEMONICA` como valor aditivo do enum `ProductionStageType` existente
**Contexto**: NFR-011-004 exige que o mecanismo de F3 comporte o novo tipo de etapa sem
alteração estrutural nem mudança de comportamento dos tipos já existentes;
`schema.prisma:69-75` já previa esta extensão em comentário desde PLAN-010.
**Decisão**: `ALTER TYPE ProductionStageType ADD VALUE 'TIRA_MNEMONICA'` (aditivo),
espelhado em `PRODUCTION_STAGE_TYPES` (`domain/types.ts:83`, COMP-012-002) — sem tocar
`ProductionEventTransition` nem o mecanismo de decisão/emissão.
**Alternativas consideradas**:
- Novo enum próprio para o tipo de etapa da Tira (fora de `ProductionStageType`),
  descartada: fragmentaria o mecanismo genérico de F3 (que já resolve
  abertura/conclusão/retrabalho para qualquer par `rawContentId`/`stageType`) em dois
  mecanismos paralelos, exatamente o redesenho que NFR-011-004 proíbe.
**Consequências**: `PRODUCTION_STAGE_TYPES` e o enum do Postgres precisam permanecer
sincronizados manualmente (mesmo custo já aceito em DEC-010-001).
**Reabrir se**: nunca — é a extensão que o mecanismo de F3 já foi desenhado para
suportar.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (mesmo padrão de DEC-010-001)

### DEC-012-006: Fronteira abertura/conclusão/retrabalho na 1ª mutação humana, não na geração
**Contexto**: a versão original do brief emitia abertura+conclusão no mesmo instante da
geração (mesmo padrão de "Conteúdo bruto" em F2); o PO corrigiu na SPEC (A-011-009/§1.3)
porque isso perderia o lead time real da etapa central do método — a Tira é o produto
do trabalho mnemônico, e medir do zero ao fim ignora o ajuste humano.
**Decisão**: `openMnemonicStrip` chama `recordProductionStageEvent` **uma vez**
(0 eventos existentes para o par → decide abertura); toda mutação humana subsequente de
Quadro (criar/editar/remover/reordenar) chama o mecanismo de novo, que decide conclusão
(1ª vez) ou retrabalho (demais vezes) puramente pelo histórico já registrado — nenhuma
alteração em `decideStageTransition`/`recordProductionStageEvent` (COMP-010-002).
**Alternativas consideradas**:
- Abertura + conclusão no mesmo instante da geração (padrão antigo de F2), descartada
  explicitamente pelo PO: perderia o lead time real da etapa (correção de mérito da
  SPEC, não escolha deste PLAN).
**Consequências**: a etapa "Tira mnemônica" pode ficar aberta indefinidamente sem
conclusão se nenhuma mutação humana ocorrer (AC-011-021) — comportamento esperado, não
um bug.
**Reabrir se**: nunca — decisão de produto já corrigida pelo PO (SPEC-011, resolução do
product-analyst), não uma escolha técnica deste PLAN a rever.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (reuso do mecanismo de F3 sem alteração)

### DEC-012-007: Reuso de `assertRawContentReachable` via export, sem duplicar o guard
**Contexto**: NFR-011-001 exige que o alcance da Tira/Quadro seja herdado do alcance do
`RawContent` de origem — a mesma ordem de guardas (inexistente → fora do alcance →
soft-deleted) que `contents.service.ts` já implementa e prova para `RuleBreakdown`.
**Decisão**: exportar `assertRawContentReachable` de `contents.service.ts`
(COMP-012-005) e importá-la em `tira.service.ts`, em vez de reescrever a mesma lógica.
**Alternativas consideradas**:
- Duplicar a função localmente em `tira.service.ts`, descartada: duas implementações
  do mesmo guard de segurança (OWASP A01) divergem silenciosamente se uma for corrigida
  e a outra esquecida — mesma classe de risco que RISK-006-006 já registra para
  paridade de tipos (declaração×declaração, sem garantia de sincronismo automático).
**Consequências**: `tira.service.ts` depende de `contents.service.ts` (COMP-006-003,
cross-plan) — acoplamento aceito, é o mesmo módulo que já é a fonte única do conceito de
"alcance de Conteúdo bruto" no projeto.
**Reabrir se**: nunca — divergir deste guard exigiria uma razão de negócio para a Tira
ter alcance diferente do Conteúdo bruto de origem, o que nenhuma SPEC prevê.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (mesmo padrão de `scopeWhere`, já exportado)

### DEC-012-008: Geração idempotente sob concorrência via `create` + captura de violação de unicidade
**Contexto**: AC-011-025 exige que 2 requisições concorrentes de 1ª abertura resultem em
exatamente 1 Tira persistida — corrida clássica de check-then-act se resolvida
ingenuamente.
**Decisão**: `tx.mnemonicStrip.create(...)` direto (sem checagem prévia); capturar a
violação de unicidade de `ruleBreakdownId` e, nesse caso, ler e devolver a Tira já
criada pela transação vencedora — mesmo precedente de `saveRuleBreakdown`/DEC-010-007
(a constraint `@unique` já entrega serialização de graça).
**Alternativas consideradas**:
- `findFirst` seguido de `create` se não existir (check-then-act), descartada: janela
  de corrida clássica entre a checagem e a escrita — exatamente o cenário que AC-011-025
  testa e reprovaria.
- Lock explícito (`SELECT ... FOR UPDATE` ou advisory lock) antes de checar, descartada:
  complexidade adicional (mais uma primitiva de banco a manter, mais uma retenção de
  lock por transação) para um ganho que a constraint `@unique` já entrega sem código
  novo.
**Consequências**: a transação perdedora paga o custo de 1 tentativa de escrita
descartada (violação de unicidade) antes de cair no caminho de leitura — custo aceito,
baixo volume concorrente esperado (mesma premissa de DEC-010-007).
**Reabrir se**: nunca — a constraint `@unique` é uma garantia do banco, não uma
heurística que perca validade com volume ou versão do Postgres.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (mesmo padrão de `saveRuleBreakdown`/DEC-010-007)

### DEC-012-009: Endpoint único GET (get-or-generate) para "abrir" a Tira
**Contexto**: FR-011-001/002 tratam "abrir a Tira mnemônica" como um único ato de
domínio (gera se não existe, exibe se já existe) — o cliente nunca precisa saber qual
dos dois casos está ocorrendo.
**Decisão**: `GET /contents/:id/strip` único, com efeito colateral de geração
idempotente na 1ª chamada — em vez de dois endpoints (`POST` para gerar + `GET` para
ler).
**Alternativas consideradas**:
- `POST /contents/:id/strip` explícito para gerar + `GET` separado para ler, descartada:
  duplicaria no cliente a lógica de "tentar ler, se 404 então gerar" (2 chamadas
  condicionais, com uma janela de corrida entre elas do lado do cliente); o próprio
  domínio já trata "abrir" como um ato atômico único, e side-effect em `GET` aqui é
  intencional — mesmo padrão já aceito no projeto para `PUT /contents/:id/breakdown`
  (upsert idempotente com efeito colateral de criação).
**Consequências**: um cliente HTTP ou cache intermediário que assuma `GET` sempre
"seguro" (sem efeito colateral) teria uma expectativa desalinhada — mitigado porque a
repetição da chamada é inofensiva por desenho (idempotência real via DEC-012-008), não
apenas por convenção.
**Reabrir se**: nunca — o par de FRs (011-001/011-002) trata a abertura como um ato
único de domínio; separar os endpoints seria uma mudança de modelagem de produto, não
de implementação.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova (primeiro `GET` idempotente com efeito colateral
explicitamente documentado como decisão, não só herdado por analogia)

<!-- EMENDA Wave 5 (furo no plano de TASK-012-008, achado do security-engineer, gate 8):
esta DEC previu só o risco de CACHE/expectativa de idempotência (Consequências acima),
não o de CSRF — o cookie de sessão é `sameSite: 'lax'` (acompanha navegação top-level),
e um `GET` que ESCREVE (cria Tira+Quadros+evento ABERTURA) fica sem a defesa de
`verifyOrigin` que o projeto já reserva para mutações, porque a regra repo-wide do
projeto (`route-authz-matrix.integration.test.ts`) proíbe `verifyOrigin` em qualquer
`GET`. Sonda provou: uma página atacante, navegando o browser da vítima para o `GET`
sem Origin/Referer, gera a Tira e grava o evento ABERTURA com o `actorId` da VÍTIMA —
forjando a atribuição de quem abriu, de onde sai a métrica CONCLUSAO/RETRABALHO
(DEC-012-006). Não é o risco que esta DEC descartou (não é ambiguidade de modelagem de
produto) — é uma superfície de ataque concreta que a DEC não previu. Superseded por
DEC-012-011, decisão do Diretor. -->

### DEC-012-011: Geração migra para `POST /contents/:id/strip`; `GET` vira leitura pura
**Contexto**: DEC-012-009 previu risco de cache/idempotência para o `GET` get-or-generate,
mas não previu CSRF — achado do `security-engineer` na Wave 5 (gate 8, TASK-012-008):
o cookie de sessão `sameSite: 'lax'` acompanha navegação top-level, e o `GET` que
escreve fica sem defesa (regra repo-wide do projeto proíbe `verifyOrigin` em `GET`).
Sonda provou exploração real (ver EMENDA acima).
**Decisão**: `GET /contents/:id/strip` passa a ser leitura pura — devolve a Tira
existente (200) ou recusa (404 se a Tira ainda não foi aberta; 409 se a Quebra da
regra ainda não foi salva, herdado de `openMnemonicStrip`), nunca gera. A geração
(idempotente, get-or-generate) migra para `POST /contents/:id/strip`, com
`verifyOrigin` — o browser sempre envia `Origin` em requisições `POST`, então a defesa
que o projeto já usa nas demais mutações passa a valer de fato aqui.
**Alternativas consideradas**:
- Manter o `GET` único e blindar com CSRF real (cookie `sameSite: 'strict'` ou token
  anti-CSRF dedicado), descartada: exigiria reescrever o invariante repo-wide "nenhum
  GET não-público tem `verifyOrigin`" para uma condição de duas metades (GET só lê ∧
  handler-que-grava tem defesa), abrindo uma exceção nova e permanente à regra mais
  simples que o projeto já tem — mais superfície para testar e mais fácil de violar de
  novo na próxima rota get-or-generate. A migração para POST reusa a defesa existente
  sem exceção.
**Consequências**: contrato HTTP muda — `tira.service.ts` ganha uma função de LEITURA
separada de `openMnemonicStrip` (que continua a ser a geração, agora só chamada pelo
`POST`); o frontend (TASK-012-010, RTK Query, já Done) precisa de um endpoint de
mutação novo para o `POST` e o endpoint de leitura existente passa a tratar 404 como
"ainda não aberta" (estado da UI antes do primeiro render dos Quadros) em vez de nunca
ocorrer — pendência explícita para TASK-012-010 (ajuste) e TASK-012-012 (tela, ainda
não implementada — já nasce com o contrato novo, sem retrabalho).
**Reabrir se**: nunca — a migração de GET-com-efeito para POST+GET-leitura é a forma
canônica do projeto para todo endpoint que grava; qualquer novo endpoint get-or-generate
futuro segue este padrão desde a largada, não o de DEC-012-009.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova (fecha a exceção que DEC-012-009 abria; alinha ao
invariante repo-wide de `verifyOrigin` só em mutação, sem exceção)

### DEC-012-010: Migração 100% aditiva — `Mnemonic` legado intocado nesta fatia
**Contexto**: FR-011-010/A-011-007 encerram o **uso** do modelo `Mnemonic` legado pela
fábrica, mas §4.2 da SPEC proíbe explicitamente qualquer remoção física (DROP/ALTER) —
decisão destrutiva não solicitada pelo Diretor.
**Decisão**: a migração desta fatia contém só `CREATE TABLE`/`CREATE TYPE`/`ADD
CONSTRAINT` aditivos; nenhuma coluna ou tabela existente é alterada ou removida.
**Alternativas consideradas**:
- Remover fisicamente `Mnemonic.hook`/`decoding`/`source` já nesta migração (já que
  "fica sem consumidor" após esta fatia), descartada: é decisão destrutiva fora do
  escopo solicitado (§4.2 da SPEC) — o risco de dado dormente duplicado é nomeado e
  aceito explicitamente (RISK-011-001), não corrigido por este PLAN.
**Consequências**: `Mnemonic.hook`/`decoding`/`source` permanecem no schema sem
consumidor de código após esta fatia — dado dormente duplicado até uma fatia futura (F8
ou limpeza de schema dedicada) decidir expurgar ou migrar.
**Reabrir se**: uma fatia futura decidir expurgar ou migrar o legado — decisão de
produto, não escolha unilateral de PLAN.
**Irreversível**: nao
**Aderência à ficha/perfil**: herdada (mesma régua de toda migração aditiva do
projeto — autorização do Diretor antes de gerar/aplicar)

## 7. Mapeamento FR -> componente

| FR | Componente | AC cobertos |
|----|------------|-------------|
| FR-011-001 | COMP-012-001, COMP-012-004, COMP-012-006, COMP-012-008, COMP-012-009, COMP-012-011, COMP-012-012, COMP-012-013, COMP-012-014 | AC-011-001, AC-011-002, AC-011-023 |
| FR-011-002 | COMP-012-001, COMP-012-004, COMP-012-006, COMP-012-014 | AC-011-003, AC-011-025 |
| FR-011-003 | COMP-012-001, COMP-012-003, COMP-012-004, COMP-012-006, COMP-012-008, COMP-012-009, COMP-012-010, COMP-012-012, COMP-012-014 | AC-011-004, AC-011-005 |
| FR-011-004 | COMP-012-003, COMP-012-004, COMP-012-006, COMP-012-008, COMP-012-009, COMP-012-010, COMP-012-012, COMP-012-014 | AC-011-006, AC-011-007 |
| FR-011-005 | COMP-012-001, COMP-012-004, COMP-012-006, COMP-012-008, COMP-012-009, COMP-012-010, COMP-012-012, COMP-012-014 | AC-011-008, AC-011-009, AC-011-024 |
| FR-011-006 | COMP-012-001, COMP-012-003, COMP-012-004, COMP-012-006, COMP-012-008, COMP-012-009, COMP-012-010, COMP-012-012, COMP-012-014 | AC-011-010, AC-011-011 |
| FR-011-007 | COMP-012-004, COMP-012-006, COMP-012-008, COMP-012-009, COMP-012-010, COMP-012-011, COMP-012-012, COMP-012-014 | AC-011-012 |
| FR-011-008 | COMP-012-004, COMP-012-014 | AC-011-013, AC-011-021 |
| FR-011-009 | COMP-012-004, COMP-012-014 | AC-011-014 |
| FR-011-010 | COMP-012-001, COMP-012-004, COMP-012-014 | AC-011-016 |
| FR-011-011 | COMP-012-012, COMP-012-014 | AC-011-004, AC-011-005, AC-011-006, AC-011-007, AC-011-008, AC-011-009, AC-011-010 |
| NFR-011-001 | COMP-012-004, COMP-012-005, COMP-012-006, COMP-012-014 | AC-011-017, AC-011-022 |
| NFR-011-002 | COMP-012-001, COMP-012-004, COMP-012-014 | AC-011-010, AC-011-011 |
| NFR-011-003 | COMP-012-004, COMP-012-014 | AC-011-015, AC-011-025 |
| NFR-011-004 | COMP-012-001, COMP-012-002, COMP-012-007 | AC-011-018 |
| NFR-011-005 | COMP-012-003, COMP-012-012 | AC-011-019 |
| NFR-011-006 | COMP-012-001, COMP-012-004, COMP-012-005, COMP-012-014 | AC-011-020 |

## 8. Riscos técnicos

- **TRISK-012-001** `ALTER TYPE ProductionStageType ADD VALUE 'TIRA_MNEMONICA'` dentro
  de uma migração transacional pode, dependendo da versão real do Postgres em uso,
  exigir que a transação da migração seja **commitada** antes que o valor novo possa ser
  usado numa mesma sessão — restrição histórica do Postgres para `ALTER TYPE ... ADD
  VALUE` que só foi parcialmente relaxada nas versões mais recentes. Mitigação: a TASK
  de migração aplica e testa a gravação de um `MnemonicStrip`/evento com
  `stageType: 'TIRA_MNEMONICA'` logo em seguida, antes de prosseguir; se o Postgres real
  recusar o uso na mesma sessão, dividir em 2 migrações sequenciais (1ª só o `ADD
  VALUE`, 2ª os models que o referenciam).
- **TRISK-012-002** A reindexação em duas fases (DEC-012-003) custa até 2×N `UPDATE`s
  por operação de adicionar/remover/reordenar (N = nº de Quadros afetados) — sem
  medição real ainda, e sem teto de Quadros por Tira (RISK-011-007 já aceita isso na
  SPEC). Mitigação: aceito nesta fatia (N esperado pequeno, dezenas no máximo);
  performance-engineer mede round-trips reais no gate 10 antes do fecho, mesmo padrão de
  medição de TRISK-010-001/006/007.
- **TRISK-012-003** Concorrência entre 2 EDITORES reordenando/mutando a mesma Tira ao
  mesmo tempo (RISK-011-005, já aceito na SPEC) — a reindexação em duas fases garante
  que **cada chamada isolada** seja atômica (NFR-011-002), mas não resolve
  last-write-wins entre duas chamadas concorrentes calculadas sobre estados diferentes.
  Mitigação: aceita nesta fatia (operação de 1 pessoa, RISK-002-001); revisitar se o
  piloto rodar com 2+ EDITORES simultâneos sobre a mesma Tira.
- **TRISK-012-004** O payload mínimo do evento de etapa (herdado de RISK-009-001 via
  RISK-011-004, já aceito na SPEC) não distingue qual ação de CRUD (criar, editar,
  remover, reordenar) gerou um retrabalho de "Tira mnemônica" — este PLAN não resolve
  isso, só herda a limitação. Mitigação: aceita, mesmo raciocínio de RISK-011-004.
- **TRISK-012-005** `GET /contents/:id/strip` com efeito colateral de geração
  (DEC-012-009) foge da expectativa estrita de idempotência "sem efeito" de um `GET`
  REST — um cliente HTTP ou cache intermediário que repita a chamada automaticamente
  (retry de rede) dispara uma tentativa de geração extra. Mitigação: a geração em si é
  idempotente por desenho (constraint `@unique` + captura de violação, DEC-012-008), e
  RTK Query (frontend) não faz retry automático de `query` por padrão — o risco é
  teórico para um cliente HTTP externo hipotético, não para a superfície real desta
  fatia.

## 9. Definition of Done deste PLAN

- [x] Todos os FRs cobertos têm implementação satisfazendo os ACs — 11/11 FRs, 25/25 ACs.
- [x] Todos os NFRs cobertos têm verificação — 6/6 NFRs, provados via os ACs que os cobrem
  (ver TASK-012-INDEX.md, "NFRs").
- [x] Decisões DEC refletidas no código — 11/11 DECs (DEC-012-001..010 originais +
  DEC-012-011, EMENDA Wave 5), todas reversíveis, nenhuma condição `Reabrir se:` satisfeita
  além da própria DEC-012-011 (que reabriu DEC-012-009).
- [x] Aderência à ficha/perfil validada — confirmada por todos os 7 code-reviews de wave.
- [x] Todos os ACs cobertos por teste (gate 1 dos quality gates) — 25/25, mais o gate 9
  consolidado abaixo.
- [x] Métrica da SPEC operacional (SPEC-011 §1.3 declara `Fonte de medição`): (a)
  instrumentação — os eventos de etapa "Tira mnemônica" (abertura, conclusão,
  retrabalho) emitidos por `openMnemonicStrip`/`addMnemonicFrame`/`updateMnemonicFrameText`/
  `removeMnemonicFrame` (COMP-012-004) e provados por 12+ testes de integração (COMP-012-014,
  gate 9 exibe o evento existindo, mesmos 3 gatilhos de FR-011-008/009) — **entregue**; (b)
  observacional — apuração por inspeção humana na Entrega (proporção de Tiras que alcançaram
  conclusão; nº de Quadros com carimbo de proveniência cujo texto diverge do Bloco de
  origem) — **pendente, ato da Entrega** (Etapa 5), mesmo molde de SPEC-005/§1.3 item (b) e
  SPEC-009/§1.3 item (b).

**Verificação (gate 9)**: VERIFICADO (2026-09-07) — SPEC-011 sem FEATs, consolidado 1×
contra esta DoD. Roteiro de 7 passos fixado em TASK-012-012 executado via Playwright contra
ambiente local real (`localhost:3000`/`3333`, branch `feat/producao-material-mnemora-studio`,
backend HEAD `3558605`, frontend HEAD `42c0a90`). Todos os ACs do roteiro confirmados:
AC-011-023, AC-011-001, AC-011-003, AC-011-004/005/006/007/008/009/010/011, AC-011-012,
AC-011-017, AC-011-024. Identidade do código provada por processo + marcador comportamental
DEC-012-011 (GET `/strip` devolveu 404 puro antes da 1ª abertura — comportamento só existe
pós-Wave-5). Estabilidade da árvore confirmada (HEAD/status idênticos abertura→fecho).
Fixture (`rawContentId` `01a07d14-cc3f-71ce-8f98-018ec90db72e`) restaurado ao fim.

## 10. Não coberto por este PLAN

- Nenhum FR/NFR de SPEC-011 fica de fora — cobertura total (Caso D, 11/11 FRs + 6/6
  NFRs).
- Herdado do Out-of-scope da SPEC (§4.2, não reaberto aqui): upload/associação de imagem
  por Quadro (F5); geração/exportação de PDF (F6); contraste, pegadinha ou flashcard
  derivado da Tira (F7); versionamento editorial e fechamento legislativo (F8); gate de
  aprovação/QC (F9); painel ou métrica agregada de tempo de produção por etapa (F10);
  remoção física do modelo `Mnemonic` legado (decisão destrutiva não solicitada,
  RISK-011-001); vínculo permanente entre Quadro e Bloco de origem após a geração
  (A-011-003); drag-and-drop (A-011-009); geração retroativa de Quadro para Bloco
  preenchido depois da geração inicial (coberto pelo CRUD livre, não por regeneração).
- Espelho de `PRODUCTION_STAGE_TYPES`/`PRODUCTION_EVENT_TRANSITIONS` como um todo no
  frontend — DEC-010-006 (PLAN-010) permanece válida e **não é reaberta** aqui: o
  frontend desta fatia só espelha `MnemonicStrip`/`MnemonicFrame` (COMP-012-009), nunca
  o enum de tipo de etapa em si (`ProductionStageType`), que continua sem consumidor de
  tela.
- Paginação de `listProductionStageEvents` (TRISK-010-002, PLAN-010) — inalterado por
  este PLAN.
- Qualquer tela ou rota de consumo agregado dos eventos de etapa — o mecanismo
  continua só escrevendo, mesma régua de PLAN-010.
