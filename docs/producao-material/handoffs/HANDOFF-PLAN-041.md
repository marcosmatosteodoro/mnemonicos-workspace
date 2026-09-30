---
id: HANDOFF-PLAN-041
slug: producao-material
branch: feat/producao-material-home-sessao-vai-ao-studio
status: Pendente
criado: 2026-09-30T16:58:00-0300
origem: PLAN-041
commits: [ef94cd7, 833e35d, 82b508f, 0cd1cd1, ccb7fea, 3585dd7, 23f2d22, 95fb386, af703d2, be8624b, da7f529]
motivo: credencial
sonda: >-
  qa (gate 9 consolidado, 2026-09-30) subiu o ambiente completo: Postgres `mnemonicos-db` Up;
  backend do checkout `mnemonicos-backend` em 3333 (`/api/v1/health` 200); frontend do worktree
  `wt-home-sessao` @ da7f529 em `next dev` (passo 0) e depois `next build` + `next start -p 3000`
  (`/login` 200). Login pela receita 2 (POST `<frontend>/api/v1/auth/login` via `context.request`,
  Origin = frontend): realm `admin1` → 422 "Informe um e-mail válido" (o `username` do realm não é
  e-mail, e o `loginSchema` exige e-mail); `admin1` com o e-mail do seed → 401 (`auth:login.failure`);
  realm `admin2` → 401 (`auth:login.failure`). Causa: as credenciais de `screenVerify.realms` em
  `keelson.local.json` estão desatualizadas em relação ao banco de dev. Saída: o Diretor atualiza
  `admin1` (username = e-mail) e as senhas vigentes de `admin1`/`admin2`, e pode acrescentar um realm
  `editor` a partir da conta EDITOR que o seed já cria (`SEED_EDITOR_*` no `.env` do backend).
---

# Handoff de verificação de tela — Home com sessão reconhecida abre a área interna (PLAN-041)

## 1. Contexto da entrega
KAN-180: quem tem sessão reconhecida (aceita agora ou renovável sem senha) e papel EDITOR/ADMIN abre
`/` e vai direto a `/studio`, sem a home pública aparecer; anônimo, falha, papel sem acesso, sem
script ou estouro do teto de 3 s ficam na home pública, sem login e sem aviso. SPEC-040 (v0.3),
PLAN-041 (v0.3), TASK-041-001..004. O Roteiro completo, fixado antes do código, está em
`docs/producao-material/tasks/TASK-041-003-home-decide-pela-sessao-sem-flash.md`,
seção "Roteiro do gate 9" (passos 0–12).

## 2. Já verificado (não repetir)
- Testes: `npx jest` no worktree — 65 suítes / 865 testes verdes (3× no modo paralelo default);
  prova HTTP real de `/` estática com conteúdo, título e descrição sem script (TASK-041-004).
- Lint/type-check: `eslint .` e `tsc --noEmit` exit 0.
- Exercitado em Chromium real, sem sessão (qa, 2026-09-30):
  - controle positivo do amostrador: 209 quadros com conteúdo presente e visível em `/` sem pista;
  - passo 0 (anônimo, `next dev`): nenhum aviso de hidratação no console;
  - AC-040-013 9(a): anônimo sem pista → delta 0 de linhas `auth:` no backend e 0 `POST /auth/refresh`;
  - variante sem login do 9(b): pista injetada à mão e sem cookies → 1 `POST /auth/refresh` 401,
    pista apagada, delta `auth:` 0, nunca `/login` nem "expirou";
  - variante sem login do 9(c): cookies forjados `forged-sentinel-xyz` → `d_home = d_direto = 0`,
    sentinela ausente da página e do console;
  - AC-040-015: pista + `/api/v1/auth/**` segurados 8 s → home pública visível aos 3054 ms;
  - AC-040-014 (ii), informativo: sem pista, mediana 40 ms e máximo 67 ms (`next start`).
  - Screenshots: `thoughts/screen-verify/PLAN-041-gate9-home-anonima.png`,
    `thoughts/screen-verify/PLAN-041-gate9-home-teto-pendurado.png`.

## 3. Pré-requisitos de ambiente
- Subir app + login: backend `npm run dev` no checkout `mnemonicos-backend` (porta 3333; stdout
  redirecionado a arquivo fora do versionamento, para contar linhas `auth:` no V4 — só contagens no
  registro). Frontend: branch `feat/producao-material-home-sessao-vai-ao-studio` com `node_modules`
  REAL (`npm ci`; symlink quebra o `next build` do Turbopack); `npm run dev` para o V1, depois
  `npm run build && npx next start -p 3000` para o resto (nunca os dois juntos, o `.next` é
  compartilhado). O `.env` do backend já tem `CORS_ORIGINS` com `http://localhost:3000`.
- Credenciais: **atualizadas em 2026-09-30** a pedido do Diretor — `admin1` = ADMIN do seed (e-mail + senha do `.env` do backend) e realm novo `editor` = EDITOR do seed; login conferido por POST real (ambos 200, papéis ADMIN e EDITOR). `admin2` está **desativado** no banco de dev (401) e foi substituído por `editor` nos itens abaixo — reativá-lo é alteração de dado, decisão do Diretor.
- Migrações/seeds pendentes DESTA branch: nenhuma.
- Feature flags / permissões necessárias: nenhuma.
- Dados de teste: a pista de sessão é gravada pelo próprio app no login e ao passar pela área interna
  (`localStorage['mnemonicos:session-hint'] = '1'`).

## 4. Roteiro de verificação (itens pendentes)

Siga os passos literais da seção "Roteiro do gate 9" da TASK-041-003, com as 4 reconciliações abaixo
(o código mudou depois do Roteiro ser fixado):
(1) o evento `storage` não arma mais a conferência: login em outra aba não leva a aba parada em `/`
à área interna até a próxima abertura ou `pageshow`;
(2) sob `next dev` (StrictMode) a home decide normalmente;
(3) o aviso do React 19 sobre `<script>` renderizado no cliente, na navegação client-side até `/`,
é só registrado e não reprova; aviso de hidratação reprova;
(4) o `AuthControl` do cabeçalho faz 1 `GET /api/v1/auth/me` por página: conte separado do que a
conferência origina.

### V1 — Passo 0 com pista, em `next dev` (TRISK-041-006)
- **Tela/rota**: http://localhost:3000/
- **Realm**: admin1
- **Passos**: seguir o passo 0 do Roteiro com login e pista; incluir a navegação client-side pelo logo até `/`.
- **Esperado**: 0 avisos com "hydrat" no console em `/`; a home decide normalmente sob StrictMode.
- **Risco se falhar**: divergência de hidratação no `<html>` por causa da marca posta fora do React.
- **Evidência**: _(preencher na verificação)_

### V2 — Sessão aceita vai direto à área interna (AC-040-002; AC-040-014 (i), informativo)
- **Tela/rota**: http://localhost:3000/
- **Realm**: admin1
- **Passos**: passo 1 do Roteiro (amostrador por quadro, controle positivo na mesma execução), mais a medida informativa (i).
- **Esperado**: URL final `/studio`; 0 quadros com conteúdo público presente e visível; mediana registrada (> 1 s é achado ao PO, não reprova).
- **Risco se falhar**: EDITOR/ADMIN vê a vitrine piscando antes do estúdio.
- **Evidência**: _(preencher na verificação)_

### V3 — Sessão renovável sem senha (AC-040-003) e duas abas (AC-040-012)
- **Tela/rota**: http://localhost:3000/
- **Realm**: editor (V3a) e admin1 (V3b)
- **Passos**: passos 2 e 4 do Roteiro, incluindo a 2ª rodada de "família viva" do passo 4.
- **Esperado**: renovação sem senha, com 1 `POST /auth/refresh` 200 e ida a `/studio`; nas duas abas a sessão continua válida. Registrar `AUTH_REFRESH_GRACE_SECONDS` (default 10).
- **Risco se falhar**: quem entrou ontem cai na vitrine, ou a família de sessão é revogada.
- **Evidência**: _(preencher na verificação)_

### V4 — AC-040-013 literal: 9(b) pista velha e 9(c) forjado com login prévio
- **Tela/rota**: http://localhost:3000/
- **Realm**: admin1
- **Passos**: passo 9 (b) e (c) do Roteiro.
- **Esperado**: (b) delta `auth:` 0, exatamente 1 refresh 401, pista apagada; (c) `d_home = d_direto`, sentinela ausente.
- **Risco se falhar**: a home passa a poluir o monitoramento de segurança ou a vazar o identificador.
- **Evidência**: _(preencher na verificação)_

### V5 — Teto com ida tardia (AC-040-016)
- **Tela/rota**: http://localhost:3000/
- **Realm**: editor
- **Passos**: passo 5 do Roteiro, com `page.route` atrasando `/api/v1/auth/me` além de 3 s.
- **Esperado**: home pública ao fim do teto e depois `/studio` via `replace`; o "voltar" não retorna a `/`.
- **Risco se falhar**: sessão sob serviço frio fica na vitrine ou entra em laço.
- **Evidência**: _(preencher na verificação)_

### V6 — Logout e revogação (AC-040-017, AC-040-018)
- **Tela/rota**: http://localhost:3000/
- **Realm**: admin1
- **Passos**: passos 6 e 7 do Roteiro, incluindo a rodada 2 de revogação real (captura de `mnemo_refresh` e `addCookies`).
- **Esperado**: home pública, sem `/login` e sem "sessão expirada"; `token.reuse` contado no stdout do backend na rodada 2.
- **Risco se falhar**: quem saiu vê `/login?sessao=expirada` só por abrir `/`.
- **Evidência**: _(preencher na verificação)_

### V7 — "Voltar" e bfcache (AC-040-009, AC-040-019)
- **Tela/rota**: http://localhost:3000/
- **Realm**: editor
- **Passos**: passos 3 e 8 do Roteiro (login pela UI ou receita alternativa, com o Esperado de cada uma).
- **Esperado**: nenhum laço `/` ↔ `/studio`; a volta até `/` com sessão leva a `/studio`.
- **Risco se falhar**: a pessoa fica presa no histórico ou vê a vitrine logada.
- **Evidência**: _(preencher na verificação)_

### V8 — Sessão sem pista (AC-040-025) e complementares (AC-040-010, AC-040-020)
- **Tela/rota**: http://localhost:3000/ e http://localhost:3000/studio
- **Realm**: editor (V8a) e admin1 (V8b/c)
- **Passos**: passos 10, 11 e 12 do Roteiro.
- **Esperado**: (a) sem pista, a home pública aparece uma vez, sem conferência, e depois de passar por `/studio` vai direto; (b) clique no logo e link da 404 com sessão levam a `/studio` sem a vitrine visível; (c) `/studio` ociosa não origina conferência nem renovação da home.
- **Risco se falhar**: exceção da pista maior que a declarada, ou prefetch disparando renovação.
- **Evidência**: _(preencher na verificação)_

## 5. Riscos e pontos de atenção
- Primeira abertura de `/` após o deploy mostra a home pública a quem já tinha sessão (sem pista) até
  passar pela área interna ou pelo login — ressalva aceita (RISK-040-006), não é defeito.
- Tema claro/escuro durante o estado neutro (o fundo vem do token de tema).
- O pulo do `ThemeToggle` quando o `AuthControl` sai de `null` já existia (SPEC-036), não é deste diff.
- Colisão com o KAN-177 (PR #22 já mergeado na `main`) em `globals.css`: após o merge do Diretor,
  reexecutar V2 contra a `main`.

## 6. Protocolo de conclusão
1. Exercitar cada item V* e preencher a Evidência (✅/❌ + o que foi observado).
2. Divergência → corrigir na própria branch (protocolo inline: escopo restrito + testes +
   gates) e re-exercitar o item.
3. Tudo ✅ → `status: Concluído` no front-matter; atualizar o INDEX do slug (remover o
   risco ativo + linha no Histórico recente); commit
   `chore(producao-material): close verification handoff HANDOFF-PLAN-041`; push.
4. Merge e deploy continuam decisão humana.
