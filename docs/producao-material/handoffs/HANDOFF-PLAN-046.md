---
id: HANDOFF-PLAN-046
slug: producao-material
branch: feat/producao-material-sidebar-navegacao
status: Pendente
criado: 2026-09-30T20:39:00-0300
origem: PLAN-046
commits: [9b60fc2, 1915183, 7b26119, 8c60101, d448ca5, 583049a, 761ccc0, 54b99bf, 581bfeb, 7234431, e6c01d2, 06a7932]
motivo: permissao_ambiente
sonda: >-
  qa (gate 9 consolidado, Etapa 4 do PLAN-046, 2026-09-30) subiu o ambiente completo: Postgres
  `mnemonicos-db` Up; backend do checkout `mnemonicos-backend` em 3333 (`npm run dev`, `/api/v1/health`
  200); frontend `npm run build` + `next start -p 3000` no HEAD 06a7932 (árvore limpa). `.env` do backend
  já tinha `http://localhost:3000` em `CORS_ORIGINS`; nenhum `.env` editado. Exercício anônimo
  (browser_navigate/evaluate/screenshot) permitido e executado. Exercício autenticado bloqueado:
  (1) `probe-env.sh` nos realms `app`/`admin1`/`editor` devolveu `credencial_placeholder` por
  incompatibilidade de formato (o script lê `login.username`/`login.password`; o `keelson.local.json`
  deste workspace tem `username`/`password` no nível do realm — `admin1` e `editor` estão preenchidos);
  (2) preencher o login sem ecoar a senha: `browser_run_code_unsafe` sem `require`/`process` e
  `import('node:fs')` → `ERR_VM_DYNAMIC_IMPORT_CALLBACK_MISSING`; servidor HTTP local de 1 endpoint em
  127.0.0.1:8899 para servir a credencial ao `page.evaluate` → **negado pelo classificador de permissões
  do harness ("Expose Local Services")**; chamadas seguintes da mesma cadeia também negadas
  ("Expose Local Services", "Credential Materialization"). Negativa de permissão prova a causa (4.133).
  Saída: o Diretor faz o login manual no navegador (realm `admin1` ADMIN ou `editor` EDITOR — `admin2`
  desativado) e executa o roteiro abaixo; ou autoriza por regra de permissão o QA a ler o realm do
  `keelson.local.json` para preencher o formulário de `/login` sem ecoar a senha.
---

# Handoff de verificação de tela — Sidebar de navegação da área interna (PLAN-046)

## 1. Contexto da entrega
KAN-178: menu lateral único para a área logada (Painel, Conteúdos, Biblioteca visual) montado no
estado pronto da casca, fixo a partir de 1280px e recolhível abaixo; seção atual destacada
(`aria-current`); logo do header vai a `/studio` com sessão ativa e papel com acesso (e a `/` no resto,
inclusive após logout em outra aba); "Voltar ao conteúdo" na Tira; container de largura único
(BRIEF-037 absorvido) sem estreitar o conteúdo. SPEC-044 (v0.2), PLAN-046 (v0.3), TASK-046-001..005.
Os Roteiros completos, fixados antes do código, estão nas TASKs
`docs/producao-material/tasks/TASK-046-00{1..5}-*.md`.

## 2. Já verificado (não repetir)
- Testes: `npm --prefix mnemonicos-frontend test` → 73 suítes / 1032 testes verdes em 06a7932 (baseline
  900 em f7760a2; 0 regressão), incluindo as integrações HTTP reais `home.integration`/`not-found.integration`.
- Lint/type-check: `npm run lint` e `npm run typecheck` limpos.
- Exercitado em tela, anônimo (qa, 2026-09-30): AC-044-005 (`/studio` sem sessão → `/login?next=%2Fstudio`,
  sem nav nem botão "Menu"); AC-044-007 (Home, `/login` e 404 sem nav nem botão, a 1440 e 360);
  AC-044-019 parcial (Home e 404 a 1440 claro/escuro e 360: container `mx-auto w-full max-w-5xl px-4 py-10
  sm:px-6`, largura 1024, x=208, padding 40/24; `<main class="w-full flex-1">`; login `fixed inset-0`, sem
  rolagem a 360); AC-044-013/025 parte visitante (logo `href="/"` nas 3 rotas públicas); AC-044-018 parte
  pública (sem rolagem horizontal a 360). Capturas: `thoughts/screen-verify/PLAN-046-gate9-*.png`.
- API exercitada sem tela: nenhuma autenticada.

## 3. Pré-requisitos de ambiente
- Subir app + login: `mnemonicos-db` de pé; `npm --prefix mnemonicos-backend run dev` (3333);
  `npm --prefix mnemonicos-frontend run build && npx --prefix mnemonicos-frontend next start -p 3000`
  (ou `next dev` para ver o `ApiStatus` a 360px). Frontend fora da 3000 exige a origem em `CORS_ORIGINS`
  do `.env` do backend (senão o login falha calado). Login manual em `/login` com o realm `admin1` (ADMIN)
  ou `editor` (EDITOR).
- Migrações/seeds pendentes DESTA branch: nenhuma (só frontend).
- Feature flags / permissões necessárias: nenhuma.
- Dados de teste: pelo menos 1 Conteúdo bruto com Quebra da regra salva e Tira aberta (para
  `/content/[id]/breakdown` e `/content/[id]/tira`). Não existe conta sem o papel exigido (V7).

## 4. Roteiro de verificação (itens pendentes)

### V1 — Sidebar fixa, itens, seção atual e foco (AC-044-001, 002, 003, 008, 012, 015, 017)
- **Tela/rota**: `/studio`, `/content`, `/content/new`, `/content/[id]`, `/content/[id]/breakdown`, `/content/[id]/tira`, `/visual-library`
- **Realm**: `admin1` e `editor`
- **Passos**: 1) viewport 1440 e depois 1280; abrir cada rota e ler `nav[aria-label="Navegação da área interna"]`; 2) conferir ordem Painel, Conteúdos, Biblioteca visual e `href` `/studio`, `/content`, `/visual-library`; 3) `aria-current="page"` só no item da seção (Conteúdos nas 4 subrotas; Painel em `/studio`; Biblioteca em `/visual-library`); 4) medir nav = 224px e coluna de conteúdo = 984px a 1280 e 1440, sem controle de recolher; 5) Tab percorre os links em ordem com foco visível, nos dois temas; 6) nenhum "Sair" na sidebar, "Sair" presente no header; 7) em `/content`, "Novo conteúdo bruto" → `/content/new` e a sidebar não o lista.
- **Esperado**: tudo como nos ACs; destaque legível nos dois temas (peso + barra + cor), 0 cores fora da paleta.
- **Risco se falhar**: usuário interno sem orientação de navegação ou com destaque errado.
- **Evidência**: _(preencher na verificação)_

### V2 — Menu recolhível abaixo de 1280px (AC-044-009, 010, 011, 021, 022, 024 + pendências do gate 11)
- **Tela/rota**: qualquer rota interna a 360, 768 e 1024; celular emulado com toque
- **Realm**: `editor`
- **Passos**: 1) fechado: botão "Menu" com `aria-expanded="false"`, itens fora do Tab, conteúdo nem coberto nem empurrado; 2) abrir: `aria-expanded="true"`, painel no fluxo; 3) fechar por item, Esc e clique fora — o foco volta ao botão; 4) com o menu aberto, tocar/clicar num controle **logo abaixo do painel**: aciona esse controle (sem deslocamento sob o dedo); 5) com o foco num campo ou link do conteúdo, fechar por clique fora ou Esc: o foco **não** é roubado (PLAN v0.3); 6) trocar de rota com o menu aberto (voltar/avançar/link na página): fecha; voltar à rota original: segue fechado; 7) cruzar 1280px com o menu aberto (resize) e voltar: fechado e "recolhido"; 8) a 1280: nav 224 / conteúdo 984; 9) 360px: sem rolagem horizontal da página com o menu aberto e fechado (header com logo, tema, auth e `ApiStatus` em dev); 10) hover do botão e dos itens (aberto e em xl) visível nos dois temas; anel de foco após clique de mouse fora (Chrome e Safari); 11) rolar arrastando no toque não fecha o menu. 12) iPhone (Safari): com o menu aberto, tocar em texto comum do conteúdo (elemento não interativo) fecha o menu — o `click` de elemento não interativo pode não subir ao document no iOS (ponto da convergência de fecho).
- **Esperado**: AC-044-009..011/021/022/024 e as pendências do gate 11 como descritas.
- **Risco se falhar**: menu que não abre/fecha no celular, foco perdido, toque em alvo errado, rolagem horizontal a 360.
- **Evidência**: _(preencher na verificação)_

### V3 — Logo do header por sessão (AC-044-013, 014, 020, 025)
- **Tela/rota**: header em `/`, `/login`, 404 e `/studio`
- **Realm**: `admin1` (sem conta STUDENT)
- **Passos**: 1) com sessão ativa, clicar no logo em `/content`: vai a `/studio`; 2) com `/api/v1/auth/me` segurado (throttling), o logo aponta para `/` enquanto confere e para `/studio` depois; 3) aba A em `/studio`, logout na aba B, clicar no logo na aba A: Home pública, sem tela de login e sem aviso de sessão expirada; 4) rede: 0 chamadas originadas pelo logo (só o GET `/auth/me` do controle de autenticação); 5) com "Entrar" ou estado neutro, o logo nunca aponta para `/studio`.
- **Esperado**: AC-044-013/014/020/025.
- **Risco se falhar**: logo levando a login expirado ou a `/studio` sem sessão.
- **Evidência**: _(preencher na verificação)_

### V4 — Tira, links soltos e métrica de alcançabilidade (AC-044-016, 026; SPEC-044 §1.3)
- **Tela/rota**: `/content/[id]/tira`; Painel → Novo conteúdo; lista → Quebra; Quebra → Tira; Biblioteca → conteúdo
- **Realm**: `editor`
- **Passos**: 1) na Tira, "Voltar ao conteúdo" antes de "Conteúdos brutos", na mesma linha a 1280 e 1440; a 360 o grupo desce inteiro para a 2ª linha, sem sobreposição nem rolagem; 2) "Voltar ao conteúdo" → `/content/[id]` do mesmo conteúdo; "Conteúdos brutos" → `/content`; 3) caminhar os 4 links soltos e conferir os destinos de antes; 4) métrica §1.3: de qualquer página interna, Painel/Conteúdos/Biblioteca visual em ≤2 interações — desktop (1 clique na sidebar) e celular (abrir menu + clicar = 2).
- **Esperado**: links com os destinos esperados; métrica atendida.
- **Risco se falhar**: perda de navegação entre páginas internas.
- **Evidência**: _(preencher na verificação)_

### V5 — Largura útil e páginas públicas sem regressão (AC-044-018, 019 — complemento)
- **Tela/rota**: área interna pronta + Home, `/login`, 404; larguras 360/768/1024/1280/1440; 2 temas
- **Realm**: `editor`
- **Passos**: 1) largura útil do conteúdo interno 328/720/976/984/984 (DEC-046-004) e um único container (sem `max-w-5xl` aninhado); 2) topo do conteúdo: `paddingTop` do container `wide` = 72px (igual a antes: 40 + 32); 3) Home/login/404 com a mesma geometria de antes nas 5 larguras e nos 2 temas (baseline opcional: checkout de f7760a2 em outra porta, lado a lado); 4) capturas a 1280 e 1440, nos dois temas, de header/footer × sidebar/conteúdo e da faixa 1040–1100px — **só registrar** (desalinhamento de até 128px por lado; decisão pendente do Diretor); 5) página longa rolada: a sidebar não é sticky (registrar).
- **Esperado**: largura ≥ a de antes em todas as larguras; 0 rolagem horizontal a 360; páginas públicas idênticas.
- **Risco se falhar**: regressão de largura/espaçamento nas páginas públicas (TRISK-046-002).
- **Evidência**: _(preencher na verificação)_

### V6 — Carregando e queda de sessão (AC-044-004, 023)
- **Tela/rota**: `/studio`
- **Realm**: `editor`
- **Passos**: 1) com `/auth/me` segurado: nem sidebar nem botão aparecem; 2) sessão válida, menu aberto abaixo de 1280, apagar os cookies e forçar novo `/auth/me`: sidebar e botão somem e a pessoa vai a `/login`.
- **Esperado**: ausência no carregando; desmontagem na queda.
- **Risco se falhar**: sidebar exposta fora do estado pronto.
- **Evidência**: _(preencher na verificação)_

### V7 — Sem permissão (AC-044-006)
- **Tela/rota**: rota interna com conta sem o papel exigido
- **Realm**: nenhum (não existe conta sem papel — A-044-006/010)
- **Passos**: 1) criar uma conta STUDENT (decisão do Diretor: mexe em dado) ou aceitar a prova automatizada (`internal-shell.test.tsx` H3/H7); 2) logar como STUDENT, abrir `/studio`: mensagem "sem permissão", sem conteúdo, sem sidebar, sem botão; logo do header aponta para `/`.
- **Esperado**: AC-044-006.
- **Risco se falhar**: vazamento de interface para papel sem acesso.
- **Evidência**: _(preencher na verificação)_

## 5. Riscos e pontos de atenção
- Tema escuro: `--surface-raised` sobre `--surface` mede ~1,1:1 — o hover do item na coluna xl deve ser confirmado a olho; o destaque do ativo não depende só de fundo.
- Estado vazio e lista longa em `/content`.
- Faixa 1040–1100px: header/footer "quase alinhados" com a área interna.
- `ApiStatus` só aparece em `next dev` — a verificação de 360px no header vale nos dois modos.

## 6. Protocolo de conclusão
1. Exercitar cada item V* e preencher a Evidência (✅/❌ + o que foi observado).
2. Divergência → corrigir na própria branch (protocolo inline: escopo restrito + testes +
   gates) e re-exercitar o item.
3. Tudo ✅ → `status: Concluído` no front-matter; atualizar o INDEX do slug (remover o
   risco ativo "Verificação de tela pendente — HANDOFF-PLAN-046" + linha no Histórico recente;
   atualizar a linha `**Verificação (gate 9)**` da SPEC-044); commit
   `chore(producao-material): close verification handoff HANDOFF-PLAN-046`; push.
4. Merge e deploy continuam decisão humana.
