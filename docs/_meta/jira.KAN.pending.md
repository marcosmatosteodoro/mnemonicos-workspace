# Jira KAN — transições pendentes (aplicação manual pelo Diretor)

> **Para que serve**: o `tracker-sync` do keelson roda em modo `transition: comment` — ele
> comenta o marco em cada issue, mas **não move os cards**. Este arquivo é o delta
> keelson → Jira: a coluna-alvo de cada issue segundo o estado real dos artefatos SDD.
> O keelson **atualiza este arquivo** a cada fecho de wave/TASK; **o Diretor muda o status
> no Jira** e marca a caixa.
>
> **Teto de autorização desta sessão** (decisão do Diretor, 2026-08-29):
> - **Sub-tasks** de TASK `Done` → **Done**.
> - **Stories** (KAN-8/9/10) → avançam **até a coluna de code review / review**, nunca `Done`
>   (Done de Story = merge da branch + Entrega, ato do Diretor).
> - **Épico** KAN-7 → intocado.
>
> Site: `mp-consultoria.atlassian.net` · projeto `KAN` · board `2`.
> Última atualização deste arquivo: **2026-08-30T14:50 -03** (Wave 6 fechada; Wave 7 em curso).

---

## Épico

| Key | Item | Estado keelson | Ação no Jira |
|-----|------|----------------|--------------|
| KAN-7 | SPEC-002 — Acesso interno e papéis de produção (fatia F1) | Em implementação (PLAN-003, 14/16 TASKs) | **nenhuma** — segue em andamento até a Entrega de F1 |

## Stories (FEATs)

| Key | FEAT | TASKs (Done / total) | Estado real | Coluna-alvo no Jira | ☐ aplicado |
|-----|------|----------------------|-------------|---------------------|:---:|
| KAN-8 | FEAT-002-001 — Autenticação de sessão | 3 / 5 (004, 006, 008 ✔ · 014, 015 na Wave 7) + harness KAN-26 ✔ | parcial, em implementação | **In Progress / Em andamento** | ☐ |
| KAN-9 | FEAT-002-002 — Autorização deny-by-default | 2 / 3 (007, 013 ✔ e revisados · 015 na Wave 7) | barreira montada (TASK-011) + store do frontend (TASK-013); falta o shell | **In Progress / Em andamento** | ☐ |
| KAN-10 | FEAT-002-003 — Provisionamento de contas por ADMIN | **3 / 3 ✅** (006, 010, 012 ✔) | **completa** — TASK-011 montou as rotas; gate 9 APROVADO; falta só o merge | **Code review / Review** (teto AI — não `Done`) | ☐ |

> **KAN-10 pronta para review** — as 3 TASKs Done + gate 9 APROVADO + rotas montadas (TASK-011).
> `Done` da Story é merge + Entrega (ato do Diretor). KAN-8 e KAN-9 seguem incompletas → In Progress.

## Sub-tasks (TASKs do PLAN-003)

| Key | TASK | Parent | Estado keelson | Coluna-alvo no Jira | ☐ aplicado |
|-----|------|--------|----------------|---------------------|:---:|
| KAN-11 | TASK-003-001 — env vars e fixtures de teste (chore) | KAN-8 | ✅ Done (`6c60682`) | **Done** | ☐ |
| KAN-12 | TASK-003-002 — migração `add_session_and_user_disabled` | KAN-8 | ✅ Done (`f956aec`/`254e00c`) | **Done** | ☐ |
| KAN-13 | TASK-003-003 — libs de cripto e auditoria | KAN-8 | ✅ Done (`98b5256`) | **Done** | ☐ |
| KAN-14 | TASK-003-004 — lógica pura de rotação de sessão | KAN-8 | ✅ Done (`5f7cb73`) | **Done** | ☐ |
| KAN-15 | TASK-003-005 — tipos de domínio espelhados | KAN-8 | ✅ Done (`46a1d5f`/`e783f1e`) | **Done** | ☐ |
| KAN-16 | TASK-003-006 — serviço de autenticação | KAN-8 | ✅ Done (`036031b`) | **Done** | ☐ |
| KAN-17 | TASK-003-007 — middlewares authenticate/authorize + ROUTE_ROLES | KAN-9 | ✅ Done (`03d5fc3` · `ead57a2` · `b106b84`) | **Done** | ☐ |
| KAN-18 | TASK-003-008 — freio de login por chave composta | KAN-8 | ✅ Done (`928a750`) | **Done** | ☐ |
| KAN-19 | TASK-003-009 — rotas de auth + cookies + cookie-parser | KAN-8 | ✅ Done (`d2560a9` · `27ef0dd` · `89c67e2`) | **Done** | ☐ |
| KAN-20 | TASK-003-010 — gestão de contas por ADMIN (módulo `users/`) | KAN-10 | ✅ Done (`efaef57` · `27ef0dd` · `89c67e2`) | **Done** | ☐ |
| KAN-21 | TASK-003-011 — montagem deny-by-default + suíte de conformidade | KAN-9 | ✅ Done (`02c1361` · `c5188cf`) | **Done** | ☐ |
| KAN-22 | TASK-003-012 — seed do primeiro ADMIN | KAN-10 | ✅ Done (`8efc829`) | **Done** | ☐ |
| KAN-23 | TASK-003-013 — store do frontend com reautenticação | KAN-9 | ✅ Done (`0ce714a` · `e75a11f` · `6281039`) | **Done** | ☐ |
| KAN-24 | TASK-003-014 — tela de login | KAN-8 | 🟡 Wave 7 — em implementação | **In Progress** | ☐ |
| KAN-25 | TASK-003-015 — shell da área interna | KAN-9 | ⏸ Todo (Wave 7) | **To Do / Backlog** | ☐ |
| KAN-26 | TASK-003-016 — harness de teste de integração com banco (chore) | KAN-8 | ✅ Done (`f956aec`) — criada nesta sessão | **Done** | ☐ |

---

## Resumo da ação agora (atualizado — Wave 6 fechada)

**14 sub-tasks → Done:** KAN-11 a KAN-23 (todas) + KAN-26. Ou seja, **KAN-21** e **KAN-23** entram agora.
**KAN-24 → In Progress** (TASK-003-014, Wave 7 em curso). KAN-25 segue To Do / Backlog.
**KAN-10 (Story) → Code review / Review** — FEAT-002-003 completa e revisada (gate 9 APROVADO) + rotas montadas; teto AI, `Done` só no merge.
**KAN-8 / KAN-9 (Stories) → In Progress** (incompletas: 3/5 e 2/3 — as duas dependem de TASK-003-015, Wave 7).
**Não mexer:** KAN-7 (Épico), KAN-25 (backlog — Wave 7).

## Notas de reconciliação (do `tracker-sync`)

- O mapa `docs/_meta/jira.KAN.md` segue incompleto — seções *Etapas/Colunas* e *Trilho do board*
  "A preencher", ids de transição não medidos. Sem isso o keelson não pode migrar para
  `transition: auto`; enquanto for manual, este arquivo é a fonte.
- KAN-24 (TASK-003-014) nasceu sob KAN-8 e KAN-25 (TASK-003-015) sob KAN-9 no gancho `tasks`.
  TASK-014 é primária de FEAT-002-001 (ok sob KAN-8); TASK-015 é primária de FEAT-002-002/003 —
  parent KAN-9 é uma das duas, aceitável. Nenhum re-parent feito (§4 do protocolo proíbe).
