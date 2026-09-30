---
id: HANDOFF-PLAN-033
slug: producao-material
branch: feat/producao-material-mnemora-studio (backend e frontend)
status: Pendente
criado: 2026-09-30
origem: PLAN-033
commits: [frontend 3043b46, caf6ea6; backend c76dbc1]
motivo: credencial_placeholder
sonda: >-
  qa (gate 9 do retry R-1 da Entrega, TASK-033-007) subiu backend e frontend, limpou o
  Service Worker e confirmou que o bundle servido era o do commit sob teste, mas não
  autenticou: em `keelson.local.json` o realm `app` (EDITOR) está com
  loginPath/username/password nulos e o realm `admin1` com o marcador
  "__SEE_BACKEND_ENV__". As tentativas de ler as credenciais de dev do `.env` do backend
  foram negadas pelo classificador de permissões (materialização/vazamento de
  credencial), e o qa parou sem contornar. Reparo: o Diretor preenche os 2 realms com as
  credenciais de dev (o arquivo é local e está no .gitignore).
---

# Handoff de verificação de tela — leitura de validade para qualquer papel (F9)

## 1. Contexto da entrega

PLAN-033 (SPEC-032, BRIEF-032, KAN-149) entrega o gate de Versão aprovada: aprovação por
ADMIN com checklist e segregação de funções, leitura do estado de aprovação no histórico e
carimbo no PDF. Na aceitação, o PO pediu (R-1) que a linha "Válida para a próxima
exportação" apareça a qualquer papel, e não só no bloco de ação do ADMIN (FR-032-007(b),
persona EDITOR da SPEC §2). A correção entrou e está coberta por teste de componente com
mutante; este handoff cobre só a confirmação na tela real.

## 2. Já verificado (não repetir)

- **Testes**: frontend `npm test` verde no HEAD final (contagem na linha de SHA acima); backend
  lint 0, tsc 0, unit 418/418, integração 565/565.
- **Gate 9 por browser real, 2 rodadas anteriores** (frontend `a4e828f` e `e68553d`):
  aprovação por ADMIN não-produtor com envio represado, estado persistido após recarregar,
  negação de autoaprovação ao produtor, ramo "não" da validade após editar na mesma página
  (visão ADMIN), reset do estado ao fechar nova Versão, linha "Aprovada por…" por Versão para
  ADMIN e EDITOR, e ausência do bloco de ação para o EDITOR.
- **Carimbo do PDF** (FEAT-032-002): verificado por HTTP + `pdftotext` nas 2 Variantes.

## 3. Pré-requisitos de ambiente

- **Backend**: `npm --prefix mnemonicos-backend run dev` (porta 3333; sobe o Postgres via
  `db:up`).
- **Frontend**: `npm --prefix mnemonicos-frontend run dev` (porta 3000; `CORS_ORIGINS` já
  inclui `http://localhost:3000`).
- **Migração desta branch**: `20260927135234_add_content_version_approval` (aditiva), já
  aplicada no banco de dev.
- **Credenciais**: preencher em `keelson.local.json` › `screenVerify.realms` o realm `app`
  com o EDITOR de dev (`SEED_EDITOR_EMAIL`/`SEED_EDITOR_PASSWORD`) e o realm `admin1` com o
  ADMIN semeado (`SEED_ADMIN_EMAIL`/`SEED_ADMIN_PASSWORD`), mais `loginPath: /login`.
- **Navegador**: antes do 1º passo, desregistre o Service Worker e limpe o Cache Storage
  (DevTools › Application), ou use uma janela anônima. O SW de app-shell serve bundle antigo
  de sessões anteriores.

## 4. Roteiro de verificação (itens pendentes)

Preparação: como EDITOR, crie um Conteúdo bruto descartável, salve a Quebra da regra,
registre a fonte normativa e feche a Versão 1. Como admin1, aprove a Versão 1.

### V1 — EDITOR vê a validade (FR-032-007(b), AC-032-020)
- **Tela/rota**: `http://localhost:3000/content/<id>`, realm `app`.
- **Passos**: abrir o Conteúdo sem alterar nada.
- **Esperado**: a linha da Versão 1 mostra "Aprovada por … em …" e "Válida para a próxima
  exportação: sim"; o bloco de ação de aprovação não aparece.
- **Evidência**: _(preencher)_

### V2 — EDITOR vê a validade cair após editar
- **Passos**: ainda como EDITOR, editar o texto normativo no formulário da mesma página e
  salvar, sem recarregar.
- **Esperado**: a linha passa a "não — a próxima exportação sai como rascunho. Uma nova
  versão precisa ser fechada e aprovada por um ADMIN que não a produziu."
- **Evidência**: _(preencher)_

### V3 — ADMIN vê a mesma leitura, uma vez só
- **Passos**: sair, entrar como admin1 e abrir o mesmo Conteúdo.
- **Esperado**: a mesma frase de V2, uma única vez na tela; o bloco de ação mostra só
  "Versão 1 aprovada por … em …".
- **Evidência**: _(preencher)_

**Restaurar**: "Remover" o Conteúdo bruto descartável (soft-delete).

## 5. Riscos e pontos de atenção

- **Se V1 ou V2 falharem**, o EDITOR volta a não saber que o PDF sai como rascunho. É o
  defeito que motivou o R-1.
- **Com um único ADMIN real em produção, nenhuma aprovação é possível** (segregação de
  funções, RISK-032-001). Isso é o comportamento esperado, e não um defeito.

## 6. Protocolo de conclusão

1. Exercitar V1–V3 e preencher cada **Evidência** (✅/❌ + o que foi observado).
2. Divergência → corrigir na branch `feat/producao-material-mnemora-studio` (escopo
   restrito + testes + gates) e re-exercitar.
3. Tudo ✅ → `status: Concluído`; atualizar `docs/producao-material/INDEX.md`; commit
   `chore(producao-material): close verification handoff HANDOFF-PLAN-033`. Ou rode
   `/keelson:verify-handoff`.
4. Merge e deploy continuam decisão do Diretor.
