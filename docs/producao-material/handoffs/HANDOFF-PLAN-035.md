---
id: HANDOFF-PLAN-035
slug: producao-material
branch: feat/producao-material-header-auth-tema
status: Pendente
criado: 2026-09-30T10:29:23+0000
origem: PLAN-035
commits: [ca5d00d, 4f6df40, 290b52e, 1549f8e, 53587b3, 981e81e, 4c6dd19, 276a431, 31dae40, 482b1a9, 628d0c1, 3ea0f61, b44d129, 5580c52, 92542c5]
motivo: app_fora_do_ar
sonda: >-
  qa (gate 9, TASK-035-006) confirmou o frontend de pé (`curl http://localhost:3000` → 200)
  e tentou exercitar os passos do roteiro que dependem de login real (realm `editor`,
  `keelson.local.json`). O backend (`http://localhost:3333`) não sobe neste ambiente:
  `docker info` → "Server: ERROR: Error response from daemon: Docker Desktop is unable to
  start"; `curl http://localhost:3333/health` → connection refused, reconfirmado ao fim do
  exercício; no navegador, `GET /api/v1/auth/me` e `GET /api/v1/health` (via `rewrites()`
  do Next) devolveram 500. Causa é infraestrutura (Postgres via Docker Compose fora do ar),
  não permissão de sandbox nem falta de credencial — `editor@mnemonicos.local` já está
  semeada em `keelson.local.json`. Reparo não é de código: exige um ambiente onde o Docker
  Desktop suba (outra máquina, ou este ambiente reparado) para `npm --prefix
  mnemonicos-backend run dev` completar `docker compose up -d --wait`.
---

# Handoff de verificação de tela — Header unificado de sessão e tema (PLAN-035)

## 1. Contexto da entrega

PLAN-035 (SPEC-034, BRIEF-034, KAN-77) consolida no `SiteHeader` do `mnemonicos-frontend`
um controle único de sessão (Entrar/Sair/neutro, substituindo o botão que hoje vive só
dentro da área interna) e um alternador de tema claro/escuro, com a paleta roxo/rosa/mauve
de `/login` (SPEC-030) estendida ao app inteiro. Das 19 ACs da SPEC, 11 foram exercitadas e
VERIFICADAS por execução real via Playwright nesta sessão (screenshots listados abaixo) —
todas as que não dependem de sessão autenticada. Este handoff cobre os 8 itens que exigem
login real (realm `editor`), bloqueados pela indisponibilidade do backend neste ambiente.

## 2. Já verificado (não repetir)

- **Testes** (`quality.test`, frontend): 676/676 (55 suítes) — verde no HEAD `92542c5`.
- **Lint/typecheck** (`quality.lint`/`quality.typecheck`, frontend): limpos no mesmo HEAD.
- **Gates 1-7 (code-reviewer)**: aprovados nas 3 waves (com retries fechados e re-revisados).
- **Gate 8 (security-engineer)**: aprovado nas Waves 1 e 2 (superfície de sessão).
- **Gate 11 (product-designer)**: aprovado nas 3 waves (com retries de acessibilidade
  visual fechados) — 4 itens de dívida de design NÃO-bloqueante permanecem registrados no
  INDEX do slug (layout shift do estado neutro, posição da mensagem de erro do logout,
  consistência de altura entre os 2 controles, `next/link` para "Entrar").
- **11 ACs verificadas por execução real** (Playwright, `http://localhost:3000`, sem
  sessão — não repetir):
  - AC-034-001, AC-034-003 (controle de auth mostra "Entrar", clique navega para `/login`).
  - AC-034-005, AC-034-007 (os 2 controles presentes e visíveis no header).
  - AC-034-008, AC-034-009 (tema segue `prefers-color-scheme`; sem preferência, cai claro).
  - AC-034-010, AC-034-011 (troca de tema imediata; escolha manual sobrevive a reload,
    prevalecendo sobre o dispositivo).
  - AC-034-012 — só a fração de rota PÚBLICA (paleta consistente com `/login`, sem
    ilustração fora dali); a fração de rota INTERNA é V6 abaixo.
  - AC-034-013 — só a fração do rótulo "Entrar"/alternador (sem sessão); a fração "Sair" é
    V1 abaixo.
  - AC-034-019 (360px sem rolagem horizontal, com os 3 controles presentes).

## 3. Pré-requisitos de ambiente

- **Subir o backend**: `npm --prefix mnemonicos-backend run dev` (depende de
  `docker compose up -d --wait` para o Postgres — falhou neste ambiente; confirme
  `docker info` antes de tentar).
- **Subir o frontend**: `npm --prefix mnemonicos-frontend run dev` (porta `3000` padrão).
- **Migrações/seeds pendentes desta branch**: nenhuma — PLAN-035 é só frontend, sem
  mudança de schema/Prisma.
- **Credencial de tela**: `keelson.local.json` › `screenVerify.realms.editor`
  (`editor@mnemonicos.local`, já semeada).
- **Navegador**: Playwright MCP ou navegador real, sem restrição adicional conhecida (os
  itens pendentes não exigem digitar credencial fora de um campo de formulário normal —
  diferente do bloqueio de sandbox visto em HANDOFF-PLAN-031/013).

## 4. Roteiro de verificação (itens pendentes)

### V1 — Controle de sessão mostra "Sair" após login (AC-034-002)
- **Tela/rota**: `http://localhost:3000/login` → logar → `http://localhost:3000/content`
- **Realm**: `editor`
- **Passos**: acessar `/login`; logar com a credencial do realm `editor`; navegar para uma
  rota interna (ex. `/content`); inspecionar o header.
- **Esperado**: o controle de autenticação mostra "Sair" (não "Entrar"); nenhum controle de
  logout duplicado na área interna (fecha junto com V4/AC-034-014).
- **Risco se falhar**: colaborador autenticado não identifica seu estado de sessão no
  header.
- **Evidência**: _(preencher na verificação)_

### V2 — Logout com os 3 estados observáveis (AC-034-004)
- **Tela/rota**: rota interna, com sessão ativa (após V1)
- **Realm**: `editor`
- **Passos**: clicar "Sair"; observar o botão durante a chamada (`disabled` + `aria-busy` +
  texto "Saindo…"); confirmar navegação para `/login` no sucesso.
- **Esperado**: os 3 estados (em andamento/sucesso/falha) observáveis; sucesso leva a
  `/login`.
- **Risco se falhar**: logout sem feedback visual deixa o usuário sem saber se a ação foi
  processada.
- **Evidência**: _(preencher na verificação)_

### V3 — Clique com sessão ativa nunca navega direto (AC-034-006)
- **Tela/rota**: rota interna, com sessão ativa
- **Realm**: `editor`
- **Passos**: confirmar que o clique no controle, autenticado, sempre aciona logout — nunca
  navegação direta para `/login` sem tentar revogar a sessão primeiro.
- **Esperado**: clique com sessão ativa sempre dispara a mutation de logout.
- **Risco se falhar**: sessão continuaria válida no servidor após o usuário "sair"
  visualmente.
- **Evidência**: _(preencher na verificação)_

### V4 — Controle de logout único na área interna (AC-034-014)
- **Tela/rota**: qualquer rota interna, ex. `/content`
- **Realm**: `editor`
- **Passos**: inspecionar a página inteira (não só o header) por qualquer outro
  botão/link de logout remanescente.
- **Esperado**: exatamente 1 controle de logout na tela (o do header).
- **Risco se falhar**: regressão do controle duplicado que esta entrega removeu de
  `InternalShell`.
- **Evidência**: _(preencher na verificação)_

### V5 — Estado neutro sem clique acidental (AC-034-016)
- **Tela/rota**: `/` ou rota interna, no instante do carregamento
- **Realm**: `app` ou `editor`
- **Passos**: com a rede throttled (DevTools → Slow 3G), carregar a página e observar o
  controle de autenticação nos primeiros ~1-2s; tentar clicar nele durante essa janela.
- **Esperado**: nem "Entrar" nem "Sair" visíveis nesse intervalo; clique não aciona nada.
- **Risco se falhar**: flash de estado errado ou clique acidental disparando ação indevida.
- **Evidência**: _(preencher na verificação)_

### V6 — Tema sobrevive a login e a logout (AC-034-017)
- **Tela/rota**: `/` → login → `/content` → logout
- **Realm**: `editor`
- **Passos**: em `/`, escolher tema escuro manualmente; logar; confirmar tema escuro na
  área interna; clicar "Sair"; confirmar tema escuro continua em `/login` (destino do
  logout).
- **Esperado**: a escolha de tema sobrevive tanto ao login quanto ao logout.
- **Risco se falhar**: escolha do usuário se perde numa transição de sessão.
- **Evidência**: _(preencher na verificação)_

### V7 — Distinguibilidade de erro/link/acento (AC-034-018)
- **Tela/rota**: rota interna com um erro de logout provocado (ex. backend derrubado no
  meio da ação) ao lado de um link
- **Realm**: `editor`
- **Passos**: provocar falha no logout (ex. parar o backend momentaneamente e clicar
  "Sair"); com a mensagem de erro (`role="alert"`) visível, localizar um link próximo;
  comparar visualmente erro × link × acento decorativo da paleta, nos 2 temas.
- **Esperado**: os três permanecem distinguíveis entre si, não só contra o fundo (a fração
  NUMÉRICA de contraste já foi provada em gate 1 por TASK-035-002 — este item cobre só a
  fração qualitativa).
- **Risco se falhar**: mensagem de erro confundida com decoração ou com um link clicável.
- **Evidência**: _(preencher na verificação)_

### V8 — Checagem de sessão sem efeito colateral, com 401 real (AC-034-015)
- **Tela/rota**: `/` (rota pública, sem sessão), com backend SAUDÁVEL
- **Realm**: `app`
- **Passos**: carregar `/` sem sessão, com o backend respondendo normalmente (401 real em
  `GET /auth/me`, não o 500 de proxy visto neste ambiente); observar se há redirect, aviso
  de sessão expirada, ou qualquer navegação forçada.
- **Esperado**: nenhum efeito colateral; permanece em `/`, mostra "Entrar".
- **Nota**: neste ambiente (backend fora do ar), o erro observado foi 500 genérico de
  proxy — `AuthControl` tratou como "sem sessão" e mostrou "Entrar" sem redirect, o que é
  coerente com o esperado, mas não é a prova "oficial" (401 real). Reexecutar com backend
  saudável antes de marcar ✅.
- **Risco se falhar**: visitante anônimo expulso/avisado indevidamente — sinalizaria
  vazamento do mecanismo de `baseQueryWithReauth` que `meSilent` foi desenhado para evitar
  (RISK-034-003/TRISK-035-003).
- **Evidência**: _(preencher na verificação)_

## 5. Riscos e pontos de atenção

- **Dívida de design não-bloqueante** (gate 11, Wave 3, `product-designer`): 4 itens
  registrados no INDEX do slug (layout shift do estado neutro do `AuthControl`; mensagem
  de erro do logout deslocando o header verticalmente; inconsistência de altura/forma
  entre `ThemeToggle` e os botões de `AuthControl`; `"Entrar"` como `<button>` em vez de
  `next/link`) — nenhum bloqueia esta entrega, mas merecem observação durante V1-V7 (se a
  captura de tela mostrar algo pior do que a análise estática previu, atualize a
  severidade no INDEX).
- **AC-034-015 sob 500 vs. 401**: ver nota de V8 acima — o comportamento observado neste
  ambiente (sem backend) é coerente com o esperado, mas a prova formal exige refazer com o
  backend saudável.

## 6. Protocolo de conclusão

1. Exercitar V1–V8 e preencher a **Evidência** de cada um (✅/❌ + o que foi observado).
2. Divergência → corrigir na branch `feat/producao-material-header-auth-tema` (protocolo
   de retry: developer + code-reviewer/security-engineer/product-designer conforme o
   achado) e re-exercitar o item.
3. Tudo ✅ → `status: Concluído` no front-matter; atualizar `docs/producao-material/INDEX.md`
   (remover a linha de risco "Verificação de tela pendente — HANDOFF-PLAN-035" + linha no
   Histórico recente); atualizar as linhas `**Verificação (gate 9)**:` de FEAT-034-001/002
   em SPEC-034 de PARCIAL para VERIFICADO; commit
   `chore(producao-material): close verification handoff HANDOFF-PLAN-035`; push.
4. Merge e deploy continuam decisão humana (do Diretor).
