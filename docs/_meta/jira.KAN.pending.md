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
> Última atualização deste arquivo: **2026-08-31T14:45 -03** (Wave 7 fechada; PLAN-003 completo 16/16; Entrega de F1 em preparação — aguarda veto do Diretor + merge).

---

## Épico

| Key | Item | Estado keelson | Ação no Jira |
|-----|------|----------------|--------------|
| KAN-7 | SPEC-002 — Acesso interno e papéis de produção (fatia F1) | Implementação concluída (PLAN-003, 16/16 TASKs); Entrega em preparação | **nenhuma** — segue em andamento até o merge das 2 branches de código + Entrega (ato do Diretor) |

## Stories (FEATs)

| Key | FEAT | TASKs (Done / total) | Estado real | Coluna-alvo no Jira | ☐ aplicado |
|-----|------|----------------------|-------------|---------------------|:---:|
| KAN-8 | FEAT-002-001 — Autenticação de sessão | **5 / 5 ✅** (004, 006, 008, 014, 015 ✔) + harness KAN-26 ✔ | **completa** — telas de login entregues; gate 9 pendente_handoff (tela, causa: credencial); falta o merge | **Code review / Review** (teto AI — não `Done`) | ☐ |
| KAN-9 | FEAT-002-002 — Autorização deny-by-default | **3 / 3 ✅** (007, 013, 015 ✔) | **completa** — barreira + store + shell entregues; gate 9 pendente_handoff (tela, causa: credencial); falta o merge | **Code review / Review** (teto AI — não `Done`) | ☐ |
| KAN-10 | FEAT-002-003 — Provisionamento de contas por ADMIN | **3 / 3 ✅** (006, 010, 012 ✔) | **completa** — TASK-011 montou as rotas; gate 9 APROVADO; falta só o merge | **Code review / Review** (teto AI — não `Done`) | ☐ |

> **As 3 Stories prontas para review** — todas as sub-tasks Done. KAN-10 com gate 9 APROVADO;
> KAN-8 e KAN-9 com gate 9 pendente_handoff de tela (causa: credencial — ver HANDOFF-PLAN-003).
> `Done` da Story é merge + Entrega (ato do Diretor).

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
| KAN-24 | TASK-003-014 — tela de login | KAN-8 | ✅ Done (`9aabaf1` · `f6cc4ed`) | **Done** | ☐ |
| KAN-25 | TASK-003-015 — shell da área interna | KAN-9 | ✅ Done (`3946b60` · `0c54b96` · `f6cc4ed` · `e6d0c75`) | **Done** | ☐ |
| KAN-26 | TASK-003-016 — harness de teste de integração com banco (chore) | KAN-8 | ✅ Done (`f956aec`) — criada nesta sessão | **Done** | ☐ |

---

## Resumo da ação agora (atualizado — Wave 7 fechada; PLAN-003 completo)

**Todas as 16 sub-tasks → Done:** KAN-11 a KAN-26. Entram agora: **KAN-24** e **KAN-25**.
**As 3 Stories → Code review / Review** — KAN-8 (FEAT-002-001), KAN-9 (FEAT-002-002) e KAN-10 (FEAT-002-003) estão **completas** (5/5, 3/3, 3/3). Gate 9 de KAN-10 APROVADO; de KAN-8 e KAN-9 pendente_handoff de tela (causa: credencial — HANDOFF-PLAN-003). Teto AI: `Done` da Story só no merge da branch + Entrega, ato do Diretor.
**Não mexer:** KAN-7 (Épico) — segue em andamento até a Entrega de F1 (merge das 2 branches de código).

## Notas de reconciliação (do `tracker-sync`)

- O mapa `docs/_meta/jira.KAN.md` segue incompleto — seções *Etapas/Colunas* e *Trilho do board*
  "A preencher", ids de transição não medidos. Sem isso o keelson não pode migrar para
  `transition: auto`; enquanto for manual, este arquivo é a fonte.
- KAN-24 (TASK-003-014) nasceu sob KAN-8 e KAN-25 (TASK-003-015) sob KAN-9 no gancho `tasks`.
  TASK-014 é primária de FEAT-002-001 (ok sob KAN-8); TASK-015 é primária de FEAT-002-002/003 —
  parent KAN-9 é uma das duas, aceitável. Nenhum re-parent feito (§4 do protocolo proíbe).
