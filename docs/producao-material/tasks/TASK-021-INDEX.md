# Índice de tarefas do PLAN-021

**Total de tasks**: 2
**Tamanho dominante**: small
**Convenções aplicadas**: branch única `feat/producao-material-rewrite-same-origin-cookie-sessao` (`git.branchNaming: slug`, `branchStrategy: unica`); Conventional Commits; Jest 30 + Testing Library (`next-16.md` §7).

## Status agregado

- Todo: 0
- In Progress: 0
- Done: 2
- Blocked: 0

## Ordem de execução (waves)

### Wave 1 (paralelizável)
- [x] TASK-021-001 ✅ Done

### Wave 2 (depende de Wave 1)
- [x] TASK-021-002 ✅ Done

## Cobertura de FRs

| FR | TASKs |
|----|-------|
| FR-002-001 | TASK-021-001, TASK-021-002 |

> NFR-002-008 é realizado pelas mesmas duas TASKs (ver "Critérios de pronto" de cada uma)
> mas não gera aresta `realiza` própria no grafo — o campo `Realiza (FRs)` da TASK só
> aceita FR (graph-contract.md, `realiza`: TASK → FR).

## Cobertura de ACs

| AC | TASKs |
|----|-------|
| AC-002-001 | TASK-021-001 (parte — rewrite/topologia de rede), TASK-021-002 (parte — baseUrl same-origin) |

## Cobertura por funcionalidade

| FEAT | TASKs (P = primária) | Done |
|------|----------------------|------|
| FEAT-002-001 | TASK-021-001 (P), TASK-021-002 (P) | 2/2 |

> Nota de cobertura: PLAN-021 é re-cobertura técnica (Caso B, `--slice`) de FR-002-001/NFR-002-008 já contabilizados em PLAN-003 (16/16 TASKs Done) — nenhum FR/AC novo nasce aqui. COMP-021-003 (remoção de `env.apiUrl`) não tem FR/AC próprio (limpeza de configuração morta) e foi absorvido por TASK-021-002 (ver Contexto da TASK).
> Resíduo fora do ciclo de TASKs: TRISK-021-001/002/003 fecham por verificação manual pós-deploy (DoD do PLAN, item de gate 9 do PLAN — nenhuma TASK carrega roteiro de gate 9 próprio, porque `gates.screenVerify` não alcança um comportamento cross-site tecnicamente irreproduzível localmente).
