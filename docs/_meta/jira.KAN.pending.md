# Jira KAN — transições do ciclo (delta keelson → board)

> **Para que serve**: o `tracker-sync` do keelson roda em modo `transition: comment` — ele
> comenta o marco em cada issue, mas **não move os cards**. Este arquivo é o delta
> keelson → Jira: a coluna-alvo de cada issue segundo o estado real dos artefatos SDD.
>
> **Estado (2026-08-31)**: o Diretor autorizou o assistente a aplicar as transições.
> **Sub-tasks KAN-11..KAN-26 → Concluído: aplicadas** (11–23 e 26 já estavam; 24 e 25
> movidas pelo assistente). **KAN-8/KAN-9 → "Em análise": barradas pelo classifier de
> permissão** — pendentes de aplicação manual pelo Diretor (ou liberar a permissão).
> KAN-10 já estava em "Em análise". KAN-7 (Épico) intocado.
>
> **IDs de transição medidos nesta sessão** (workflow global do board, valem para os 3
> tipos): `11` → Tarefas pendentes · `21` → Em andamento · `31` → Em análise (In Review)
> · `41` → Concluído. (Alimenta `docs/_meta/jira.KAN.md`, seção "Trilho do board".)
>
> **Teto de autorização desta sessão** (decisão do Diretor, 2026-08-29):
> - **Sub-tasks** de TASK `Done` → **Done**.
> - **Stories** (KAN-8/9/10) → avançam **até a coluna de code review / review**, nunca `Done`
>   (Done de Story = merge da branch + Entrega, ato do Diretor).
> - **Épico** KAN-7 → intocado.
>
> Site: `mp-consultoria.atlassian.net` · projeto `KAN` · board `2`.
> Última atualização deste arquivo: **2026-08-31T14:45 -03** (Wave 7 fechada; PLAN-003 completo 16/16; Entrega de F1 em preparação — aguarda veto do Diretor + merge).

---

## Épico

| Key | Item | Estado keelson | Ação no Jira |
|-----|------|----------------|--------------|
| KAN-7 | SPEC-002 — Acesso interno e papéis de produção (fatia F1) | Implementação concluída (PLAN-003, 16/16 TASKs); Entrega em preparação | **nenhuma** — segue em andamento até o merge das 2 branches de código + Entrega (ato do Diretor) |

## Stories (FEATs)

| Key | FEAT | TASKs (Done / total) | Estado real | Coluna-alvo no Jira | ☐ aplicado |
|-----|------|----------------------|-------------|---------------------|:---:|
| KAN-8 | FEAT-002-001 — Autenticação de sessão | **5 / 5 ✅** (004, 006, 008, 014, 015 ✔) + harness KAN-26 ✔ | **completa** — telas de login entregues; gate 9 pendente_handoff (tela, causa: credencial); falta o merge | **Em análise** (In Review — teto AI, não `Concluído`) | ⛔ classifier |
| KAN-9 | FEAT-002-002 — Autorização deny-by-default | **3 / 3 ✅** (007, 013, 015 ✔) | **completa** — barreira + store + shell entregues; gate 9 pendente_handoff (tela, causa: credencial); falta o merge | **Em análise** (In Review — teto AI, não `Concluído`) | ⛔ classifier |
| KAN-10 | FEAT-002-003 — Provisionamento de contas por ADMIN | **3 / 3 ✅** (006, 010, 012 ✔) | **completa** — TASK-011 montou as rotas; gate 9 APROVADO; falta só o merge | **Em análise** (já estava lá) | ✅ (já) |

> **As 3 Stories prontas para review.** KAN-10 já está em "Em análise". **KAN-8 e KAN-9
> ficaram pendentes**: a transição `Em andamento → Em análise` foi **barrada pelo classifier
> de permissão do Claude Code** (as sub-tasks passaram; as Histórias, não). Mover as duas à
> mão, ou liberar a permissão e pedir para o assistente refazer. `Concluído` da Story é
> merge + Entrega (ato do Diretor).

## Sub-tasks (TASKs do PLAN-003)

| Key | TASK | Parent | Estado keelson | Coluna-alvo no Jira | ☐ aplicado |
|-----|------|--------|----------------|---------------------|:---:|
| KAN-11 | TASK-003-001 — env vars e fixtures de teste (chore) | KAN-8 | ✅ Done (`6c60682`) | **Done** | ✅ |
| KAN-12 | TASK-003-002 — migração `add_session_and_user_disabled` | KAN-8 | ✅ Done (`f956aec`/`254e00c`) | **Done** | ✅ |
| KAN-13 | TASK-003-003 — libs de cripto e auditoria | KAN-8 | ✅ Done (`98b5256`) | **Done** | ✅ |
| KAN-14 | TASK-003-004 — lógica pura de rotação de sessão | KAN-8 | ✅ Done (`5f7cb73`) | **Done** | ✅ |
| KAN-15 | TASK-003-005 — tipos de domínio espelhados | KAN-8 | ✅ Done (`46a1d5f`/`e783f1e`) | **Done** | ✅ |
| KAN-16 | TASK-003-006 — serviço de autenticação | KAN-8 | ✅ Done (`036031b`) | **Done** | ✅ |
| KAN-17 | TASK-003-007 — middlewares authenticate/authorize + ROUTE_ROLES | KAN-9 | ✅ Done (`03d5fc3` · `ead57a2` · `b106b84`) | **Done** | ✅ |
| KAN-18 | TASK-003-008 — freio de login por chave composta | KAN-8 | ✅ Done (`928a750`) | **Done** | ✅ |
| KAN-19 | TASK-003-009 — rotas de auth + cookies + cookie-parser | KAN-8 | ✅ Done (`d2560a9` · `27ef0dd` · `89c67e2`) | **Done** | ✅ |
| KAN-20 | TASK-003-010 — gestão de contas por ADMIN (módulo `users/`) | KAN-10 | ✅ Done (`efaef57` · `27ef0dd` · `89c67e2`) | **Done** | ✅ |
| KAN-21 | TASK-003-011 — montagem deny-by-default + suíte de conformidade | KAN-9 | ✅ Done (`02c1361` · `c5188cf`) | **Done** | ✅ |
| KAN-22 | TASK-003-012 — seed do primeiro ADMIN | KAN-10 | ✅ Done (`8efc829`) | **Done** | ✅ |
| KAN-23 | TASK-003-013 — store do frontend com reautenticação | KAN-9 | ✅ Done (`0ce714a` · `e75a11f` · `6281039`) | **Done** | ✅ |
| KAN-24 | TASK-003-014 — tela de login | KAN-8 | ✅ Done (`9aabaf1` · `f6cc4ed`) | **Done** | ✅ |
| KAN-25 | TASK-003-015 — shell da área interna | KAN-9 | ✅ Done (`3946b60` · `0c54b96` · `f6cc4ed` · `e6d0c75`) | **Done** | ✅ |
| KAN-26 | TASK-003-016 — harness de teste de integração com banco (chore) | KAN-8 | ✅ Done (`f956aec`) — criada nesta sessão | **Done** | ✅ |

---

## Resumo (Wave 7 fechada; PLAN-003 completo; transições aplicadas em parte)

**16 sub-tasks → Concluído: FEITO** (KAN-11 a KAN-26). KAN-24 e KAN-25 movidas pelo assistente nesta sessão; o resto já estava.
**Pendente para o Diretor:** mover **KAN-8** e **KAN-9** para **"Em análise"** (transição `31`) — o assistente foi barrado pelo classifier. KAN-10 já está lá. Teto AI: `Concluído` da Story só no merge + Entrega.
**Não mexer:** KAN-7 (Épico) — segue "Em andamento" até a Entrega de F1 (merge das 2 branches).

## Notas de reconciliação (do `tracker-sync`)

- O mapa `docs/_meta/jira.KAN.md` segue incompleto — seções *Etapas/Colunas* e *Trilho do board*
  "A preencher", ids de transição não medidos. Sem isso o keelson não pode migrar para
  `transition: auto`; enquanto for manual, este arquivo é a fonte.
- KAN-24 (TASK-003-014) nasceu sob KAN-8 e KAN-25 (TASK-003-015) sob KAN-9 no gancho `tasks`.
  TASK-014 é primária de FEAT-002-001 (ok sob KAN-8); TASK-015 é primária de FEAT-002-002/003 —
  parent KAN-9 é uma das duas, aceitável. Nenhum re-parent feito (§4 do protocolo proíbe).
