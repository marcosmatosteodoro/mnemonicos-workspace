# Índice de tarefas do PLAN-035

**Total de tasks**: 8
**Tamanho dominante**: medium (6 medium, 2 small)

## Ordem de execução (waves)

### Wave 1 (setup-first, paralelizável — 3 TASKs sem dependência entre si: migração de
schema, refactor de F9 e util de frontend tocam arquivos distintos)
- [x] TASK-035-001 ✅ Done
- [x] TASK-035-002 ✅ Done
- [x] TASK-035-003 ✅ Done

### Wave 2 (depende de Wave 1 — as 2 TASKs abaixo NÃO dependem uma da outra: TASK-035-004
depende só de TASK-035-002 [`isVersionAltered`]; TASK-035-005 depende só de TASK-035-001
[coluna `pageCount`] — arquivos distintos, `strategic-panel-calculations.ts` vs.
`strategic-panel.service.ts`, paralelizáveis)
- [x] TASK-035-004 ✅ Done
- [ ] TASK-035-005 ⏸ Todo

### Wave 3 (depende de TASK-035-004 E TASK-035-005 — `buildStrategicPanel` soma as 2 leituras
em lote ao cálculo puro; a rota HTTP e a prova de custo constante só existem depois das duas)
- [ ] TASK-035-006 ⏸ Todo

### Wave 4 (depende de TASK-035-006 — o formato de `StrategicPanelResponse` só está
congelado depois da allowlist + prova HTTP da TASK-035-006, princípio 2)
- [ ] TASK-035-007 ⏸ Todo

### Wave 5 (depende de TASK-035-007 E TASK-035-003 — a tela consome o endpoint RTK Query
e o util de duração; única TASK de tela do PLAN, decisão deliberada de não fatiar por
seção — as ACs de FR-034-017/033/034 descrevem o Painel como comportamento holístico)
- [ ] TASK-035-008 ⏸ Todo
<!-- Status agregado e as tabelas de cobertura (FR, AC, funcionalidade) NÃO se escrevem
(4.409): `graph.sh <slug> --format=tables --plan MMM` as deriva das TASKs. O checklist
de waves acima é afirmação de despacho e inventário do fecho de wave (4.92) — fica. -->
