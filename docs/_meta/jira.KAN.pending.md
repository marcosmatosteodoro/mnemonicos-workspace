# Jira KAN — transições do ciclo F1 (delta keelson → board) · CONCLUÍDO

> **Estado (2026-09-01)**: **todas as transições de F1 aplicadas.** PLAN-003 mergeado
> (backend `25cdafd` · frontend `834f117`, PR #1 nos dois repos); Entrega fechada;
> PLAN-003 Status → Done.
>
> - **Sub-tasks KAN-11..KAN-26 → Concluído** ✅ (aplicadas)
> - **Stories KAN-8 / KAN-9 / KAN-10 → Concluído** ✅ (aplicadas — `Done` da Story =
>   merge + Entrega, agora feito)
> - **Épico KAN-7 → "Em andamento"** — **mantido de propósito**: F1 é 1 de 11 fatias do
>   épico MNEMORA STUDIO; o Épico fecha quando a última fatia entregar.
>
> **IDs de transição do workflow global do board** (valem para os 3 tipos):
> `11` → Tarefas pendentes · `21` → Em andamento · `31` → Em análise (In Review)
> · `41` → Concluído. → alimentar `docs/_meta/jira.KAN.md` seção "Trilho do board".
>
> Site: `mp-consultoria.atlassian.net` · projeto `KAN` · board `2`.
> Última atualização: **2026-09-01** (F1 mergeada; Jira reconciliado).

---

## Estado final no board

| Key | Item | Status Jira |
|-----|------|-------------|
| KAN-7 | Épico — Acesso interno e papéis de produção | **Em andamento** (mantido — épico multi-fatia) |
| KAN-8 | Story — Autenticação de sessão (FEAT-002-001) | **Concluído** ✅ |
| KAN-9 | Story — Autorização por papel (FEAT-002-002) | **Concluído** ✅ |
| KAN-10 | Story — Provisionamento de contas internas (FEAT-002-003) | **Concluído** ✅ |
| KAN-11..KAN-26 | Sub-tasks — TASK-003-001..016 | **Concluído** ✅ (16/16) |

## Notas de reconciliação

- O mapa `docs/_meta/jira.KAN.md` segue com *Etapas/Colunas* e *Trilho do board* a
  preencher — os IDs de transição medidos acima podem fechar essa lacuna e habilitar
  `transition: auto` numa próxima iteração.
- Gate 9 de KAN-8/KAN-9 foi `pendente_handoff` (tela, causa: credencial) na Entrega —
  ver `docs/producao-material/handoffs/HANDOFF-PLAN-003.md`. A verificação de tela é
  independente do status Jira (que reflete merge + Entrega).
- KAN-24 nasceu sob KAN-8 e KAN-25 sob KAN-9 no gancho `tasks`; parentesco aceitável,
  nenhum re-parent feito (§4 do protocolo proíbe).
