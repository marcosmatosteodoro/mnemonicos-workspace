# TASK-033-006: Tipos espelhados e mutation de aprovação (`ContentVersion` estendida)

**Slug**: producao-material
**Pertence a**: PLAN-033
**Realiza (FRs)**: nenhuma
**Componente**: COMP-033-009 (principal), COMP-033-010, COMP-033-013
**Wave**: 4
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Done

## Dependências

- **Depende de**: TASK-033-003, TASK-033-004
- **Bloqueia**: TASK-033-007

## Contexto

Acrescenta a mutation RTK Query de aprovação (o espelho dos 3 campos novos de
`ContentVersion` — `approvedById`, `approvedAt`, `validApprovalForExport` — foi
entregue junto do backend que os cria, TASK-033-003/004, refino de 2026-09-27) — plumbing puro,
sem comportamento observável próprio (o painel que o consome é TASK-033-007). Depende das
2 TASKs de backend anteriores porque o formato de resposta real (`ContentVersionDetail`)
só está congelado depois delas (princípio 2 — costura só em contrato congelado).
Território e precedentes: `docs/producao-material/MAP.md`,
`mnemonicos-backend/src/domain/types.ts:203-210`,
`mnemonicos-frontend/src/types/domain.ts:318-325`,
`mnemonicos-frontend/src/store/api.ts:645-659` (padrão de
`listContentVersions`/`closeContentVersion` já existentes), e PLAN-033 §3
(COMP-033-009/010/013).

## Escopo

### Inclui

- `mnemonicos-frontend/src/store/api.ts`:
  - `export interface ApproveContentVersionArgs { rawContentId: string; number: number;
    legalCheckConfirmed: boolean; pedagogicalCheckConfirmed: boolean }` (ao lado de
    `CloseContentVersionArgs`).
  - `approveContentVersion: build.mutation<ContentVersion, ApproveContentVersionArgs>({
    query: ({ rawContentId, number, ...body }) => ({ url:
    \`/contents/${rawContentId}/versions/${number}/approve\`, method: 'POST', body }),
    invalidatesTags: ['ContentVersion'] })` — mesma tag de `closeContentVersion`/
    `listContentVersions`, **sem** invalidar `'RawContent'` (aprovar não toca nenhum
    campo do `RawContent`, o carimbo de última alteração de SPEC-005 segue intocado por
    este ato).
  - Export do hook: `useApproveContentVersionMutation` (bloco de exports já existente ao
    lado de `useCloseContentVersionMutation`).
- Espelho dos 3 campos (`approvedById`/`approvedAt`/`validApprovalForExport`) nos 2
  `domain.ts` e a paridade de `contents-frontend-contract.test.ts` **já chegam feitos**
  (refino pós-furo no plano, 2026-09-27: quem cria o campo no payload espelha no mesmo
  diff — TASK-033-003 para os 2 primeiros, TASK-033-004 para o computado). Esta TASK
  só CONFERE que o espelho está completo antes de acrescentar a mutation — ver critério.

### Não inclui

- Componente de painel de aprovação (`content-version-history.tsx`) — TASK-033-007.
- Qualquer mudança em `content-versions.service.ts`/`.routes.ts` — já entregues por
  TASK-033-003/004, das quais esta TASK só espelha o formato de resposta.

## Critérios de pronto

- [ ] **Paridade cross-repo `ContentVersion` já completa** (entregue por TASK-033-003/004,
      conferida aqui antes da mutation): `contents-frontend-contract.test.ts` confirma os
      3 campos nos DOIS lados e o mesmo conjunto em `ContentVersionDetail`. Verificação
      executável: `npm --prefix mnemonicos-backend test -- contents-frontend-contract.test.ts`
      → `OK (N tests)`; divergência encontrada aqui é furo das TASKs anteriores (reportar,
      não corrigir em silêncio).
- [ ] `TAG_TYPES` (`mnemonicos-frontend/src/store/api.ts`) já contém `'ContentVersion'`
      desde TASK-029-004 — sem alteração; item do Inclui sem AC isolado (mutation nova,
      oráculo é o contrato do próprio item): typecheck confirma que
      `useApproveContentVersionMutation` tem a assinatura `(ApproveContentVersionArgs) =>
      ...` — `npm --prefix mnemonicos-frontend run typecheck` → exit 0.
- [ ] `grep -n "approveContentVersion" src/store/api.ts` (cwd `mnemonicos-frontend`) → ao
      menos 2 ocorrências (declaração do endpoint + export do hook).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`), produção e teste — `npm --prefix mnemonicos-backend run lint &&
      npm --prefix mnemonicos-frontend run lint` → exit 0 nos 2.
- [ ] Aderência à stack/padrões da ficha e do perfil `next-16.md`/`node-22.md` —
      identificadores em inglês, `invalidatesTags` mínimo e correto (sem invalidar
      `'RawContent'`, A-032-011 análogo a A-028-001).
- [ ] Code review aprovado.

## Riscos específicos

- Gate 8 (security-engineer): **n/a** — plumbing de tipos/mutation sem lógica própria,
  sem superfície de autorização nova (a autorização real é a rota do backend, já
  revisada em TASK-033-003).
- Gate 9 (`gates.screenVerify`): **n/a** — nenhum componente de tela nesta TASK.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-29T21:42:00-0300 (despacho; developer não mediu o início — declarado)
**Data conclusão**: 2026-09-29T21:55:00-0300
**Commit SHA**: frontend 7c83015 (+ ebda177 — aplicação de fim de wave: âncora sem sustentação retirada do comentário)
**Jira**: KAN-157

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (wave 4, sem retry; desvio do critério de grep — case-sensitive não casa com `useApprove…` — declarado pelo developer e confirmado: autoria da TASK) — code-reviewer
- [x] ACs verificados
- [x] Segurança (gate 8): n/a — mutation de cliente para rota já revisada no gate 8 da TASK-033-003; autorização segue no servidor · Performance (gate 10) n/a (sem superfície de custo) · Design (gate 11) n/a (sem interface)
- [x] Comportamento (gate 9): consolidado FEAT-032-001 — carregador: Roteiro do gate 9 de TASK-033-007 (Wave 5), que exercita a mutation pelo painel contra a store real
