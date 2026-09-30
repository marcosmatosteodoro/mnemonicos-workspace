# Índice de tarefas do PLAN-033

**Total de tasks**: 7
**Tamanho dominante**: small (4 small, 3 medium)

## Ordem de execução (waves)

### Wave 1 (setup-first, paralelizável)
- [x] TASK-033-001 ✅ Done
- [x] TASK-033-002 ✅ Done

### Wave 2 (depende de Wave 1 — as 2 TASKs abaixo NÃO dependem uma da outra, arquivos
distintos: `content-versions.*` vs. `publication.service.ts`/`pdf-composer.ts`,
paralelizáveis)
- [x] TASK-033-003 ✅ Done
- [x] TASK-033-005 ✅ Done

### Wave 3 (depende de TASK-033-003 — mesmo arquivo `content-versions.service.ts`,
sequenciada por colisão de escrita, princípio 2, nunca por dependência funcional real)
- [x] TASK-033-004 ✅ Done

### Wave 4 (depende de TASK-033-003 E TASK-033-004 — o formato de resposta
`ContentVersionDetail` só está congelado depois das duas)
- [x] TASK-033-006 ✅ Done

### Wave 5 (depende de TASK-033-006)
- [ ] TASK-033-007 ⏸ Todo
<!-- Status agregado e as tabelas de cobertura (FR, AC, funcionalidade) NÃO se escrevem
(4.409): `graph.sh <slug> --format=tables --plan MMM` as deriva das TASKs. O checklist
de waves acima é afirmação de despacho e inventário do fecho de wave (4.92) — fica. -->
