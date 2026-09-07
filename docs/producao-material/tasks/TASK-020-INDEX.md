# Índice de tarefas do PLAN-020

**Total de tasks**: 2
**Tamanho dominante**: small
**Convenções aplicadas**: derivadas da ficha (`keelson.config.json`) e do perfil
`guidelines/project/frontend/next-16.md` — Conventional Commits, Server Component sem
`'use client'` (nenhum estado/efeito/evento), Jest 30 + Testing Library (`jsdom` default
para o unitário; override `@jest-environment node` para o de integração, mesmo mecanismo
de `src/proxy.test.ts`), branch única `feat/pagina-404-personalizada` (já criada,
sem worktree dedicado).

## Status agregado

- Todo: 2
- In Progress: 0
- Done: 0
- Blocked: 0

## Ordem de execução (waves)

### Wave 1 (paralelizável)
- [ ] TASK-020-001 ⏸ Todo — Criar a página 404 personalizada (`not-found.tsx`) e seu
      teste unitário
- [ ] TASK-020-002 ⏸ Todo — Provar o status HTTP 404 real e a não-regressão do guard de
      sessão (`proxy.ts`)

> As duas TASKs são independentes por desenho: TASK-020-002 verifica um comportamento
> nativo do App Router (status 404 para qualquer rota sem correspondência, com ou sem um
> `not-found.tsx` customizado) e a não-regressão de `proxy.ts` (arquivo de outro slice,
> intocado por este PLAN) — nenhuma das duas prova depende do conteúdo criado pela outra.

## Cobertura de FRs

| FR | TASKs |
|----|-------|
| FR-019-001 | TASK-020-001 |
| FR-019-002 | TASK-020-001 |
| FR-019-003 | TASK-020-001 |
| FR-019-004 | TASK-020-001 |

**NFRs** (não são aresta formal do grafo de TASK — campo `Realiza (FRs)` é FR-only;
provados via os ACs que os cobrem, tabela abaixo): NFR-019-001 → AC-019-001
(TASK-020-001) · NFR-019-002 → AC-019-001/002 (TASK-020-001) · NFR-019-003 → AC-019-004
(TASK-020-002) · NFR-019-004 → AC-019-005 (TASK-020-001).

## Cobertura de ACs

| AC | TASKs |
|----|-------|
| AC-019-001 | TASK-020-001 |
| AC-019-001b | TASK-020-002 (não-regressão — reexecução de `proxy.test.ts`, sem código novo) |
| AC-019-002 | TASK-020-001 |
| AC-019-003 | TASK-020-001 |
| AC-019-004 | TASK-020-002 |
| AC-019-005 | TASK-020-001 |

Cobertura total: 6/6 ACs, 4/4 FRs, 4/4 NFRs de SPEC-019 — sem FEATs (SPEC-019 não declara
FEATs §5), sem decomposição parcial (`--only` não usado). Todos os ACs fecham por gate 1
(teste automatizado) — `gates.screenVerify` está ativo na ficha, mas nenhum AC desta SPEC
foi atribuído a esse gate (PLAN §1, "Estratégia de teste": DEC-020-004 escolhe prova
automatizada de servidor real em vez de garantia documental do framework ou caminhada de
tela).
