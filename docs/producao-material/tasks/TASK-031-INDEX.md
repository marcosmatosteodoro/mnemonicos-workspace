# Índice de tarefas do PLAN-031

**Total de tasks**: 7
**Tamanho dominante**: small (4 small, 3 medium)

## Ordem de execução (waves)

### Wave 1 (setup-first, paralelizável)
- [ ] TASK-031-001 ⏸ Todo
- [ ] TASK-031-002 ⏸ Todo

### Wave 2 (depende de Wave 1 — as 2 TASKs abaixo NÃO dependem uma da outra, arquivos
distintos: `content-versions.*` vs. `publication.service.ts`/`pdf-composer.ts`,
paralelizáveis)
- [ ] TASK-031-003 ⏸ Todo
- [ ] TASK-031-005 ⏸ Todo

### Wave 3 (depende de TASK-031-003 — mesmo arquivo `content-versions.service.ts`,
sequenciada por colisão de escrita, princípio 2, nunca por dependência funcional real)
- [ ] TASK-031-004 ⏸ Todo

### Wave 4 (depende de TASK-031-003 E TASK-031-004 — o formato de resposta
`ContentVersionDetail` só está congelado depois das duas)
- [ ] TASK-031-006 ⏸ Todo

### Wave 5 (depende de TASK-031-006)
- [ ] TASK-031-007 ⏸ Todo
<!-- Status agregado e as tabelas de cobertura (FR, AC, funcionalidade) NÃO se escrevem
(4.409): `graph.sh <slug> --format=tables --plan MMM` as deriva das TASKs. O checklist
de waves acima é afirmação de despacho e inventário do fecho de wave (4.92) — fica. -->
