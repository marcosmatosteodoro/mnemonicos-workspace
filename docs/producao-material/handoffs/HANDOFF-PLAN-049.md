---
id: HANDOFF-PLAN-049
slug: producao-material
branch: feat/producao-material-gestao-usuarios
status: Pendente
criado: 2026-10-01T00:50:00-0300
origem: PLAN-049
commits: [ffda6b1, 0449ca1, 3a469f3, c39e6f7, 85d190f, 88ff4e5, 8522792, 3e633ac, 454219f, 1625443, 384fd79, 056bf21]
motivo: permissao_ambiente
sonda: >-
  qa (rodada final consolidada do gate 9, PLAN-049, 2026-10-01) subiu o ambiente completo: Postgres em
  5432; backend do checkout `mnemonicos-backend` em 3333 (`npm run dev`, `GET /api/v1/health` 200);
  frontend `npm run dev` na worktree `wt-gestao-usuarios` em 3000 (cwd do processo conferido em /proc,
  HEAD 056bf21, árvore limpa). Nenhum `.env` editado; nenhuma porta fora do padrão. Exercício anônimo
  executado (AC-048-003). Exercício autenticado NÃO realizado: por decisão do PO na Etapa 3.5 (BRIEF-048),
  a "receita 2" (login por `context.request` com a senha do realm em `browser_run_code_unsafe`) não é
  tentada — o mesmo gesto foi negado pelo classificador de permissões no HANDOFF-PLAN-046 ("Credential
  Materialization"); o caminho previsto é um login manual do Diretor, ausente nesta execução (modo
  autônomo). Sondagem barata: `GET /api/v1/users` sem sessão → 401 (frontend 3000 e backend 3333), então
  nenhum passo autenticado é observável anonimamente. Saídas: (1) o Diretor faz o login manual na janela
  do Playwright (realm `admin1` ADMIN; realm `editor` EDITOR para V2/V3) e executa o roteiro abaixo; ou
  (2) o Diretor autoriza por regra de permissão a leitura do realm do `keelson.local.json` para o QA
  preencher o formulário de `/login` sem ecoar a senha.
---

# Handoff de verificação de tela — Tela de gestão de usuários (PLAN-049)

## 1. Contexto da entrega
KAN-179: tela `/users` só para ADMIN — lista paginada com busca, criar conta, desativar e redefinir senha,
item "Usuários" no menu só para ADMIN, senha nunca retida no cliente. Só frontend (backend sem diff).
SPEC-048 (v0.2), PLAN-049, TASK-049-001..006. O Roteiro completo, fixado antes do código e reconciliado
pelo Tech Lead, está em `docs/producao-material/tasks/TASK-049-006-redefinir-senha-com-confirmacao.md`
(seção "Roteiro do gate 9"; o passo 0 executa o Roteiro de `TASK-049-001-*.md`).

## 2. Já verificado (não repetir)
- Testes: `npx jest` na worktree → 91 suítes / 1303 testes verdes em 056bf21 (baseline da execução
  73 / 1037 em 5bce413; 0 regressão). Inclui as provas de senha fora de store/storage/URL/DOM/console
  (`tests/support/password-sinks.ts`), a matriz de mutantes de cada TASK e o `home.integration` (next build
  real, H7 com `/users`).
- Lint/type-check: `npm run lint` e `npm run typecheck` limpos.
- Backend: `route-authz-matrix.integration.test.ts` (48 testes) verde — as 4 rotas de conta respondem 403
  a sessão EDITOR (evidência complementar do AC-048-004; não substitui V3).
- Exercitado em tela, anônimo (qa, 2026-10-01): AC-048-003 (`/users` sem sessão → 307
  `/login?next=%2Fusers`; snapshot `thoughts/screen-verify/page-2026-10-01T03-45-18-279Z.yml`); item
  "Usuários" ausente sem sessão.
- API exercitada sem tela: `GET /api/v1/users` sem sessão → 401.

## 3. Pré-requisitos de ambiente
- Subir app + login: Postgres de pé; `npm --prefix mnemonicos-backend run dev` (3333); na worktree
  `wt-gestao-usuarios`, `npm run dev` (3000). Frontend fora da 3000 exige a origem em `CORS_ORIGINS` do
  `.env` local do backend (senão o login falha calado). Login manual em `/login` com o realm `admin1`
  (ADMIN) e, para V2/V3, `editor` (EDITOR). `admin2` está desativado — não usar.
- Migrações/seeds pendentes DESTA branch: nenhuma (só frontend).
- Feature flags / permissões necessárias: nenhuma.
- Dados de teste: as contas descartáveis D1 (ADMIN) e D2 (EDITOR) são criadas pela própria tela no V4,
  com e-mail `descartavel-049-<d1|d2>-aaaammdd@example.com` e senha inventada na hora (12+ caracteres,
  nunca gravada em arquivo, log ou relatório). **Restauro obrigatório**: ao fim, D1 e D2 ficam
  "Desativada"; se V10/V11 não rodarem, admin1 desativa D1 pela tela. Nunca desativar nem redefinir a
  senha de admin1.

## 4. Roteiro de verificação (itens pendentes)

### V1 — Menu e acesso do ADMIN (AC-048-001, AC-048-027)
- **Tela/rota**: `/studio` → `/users`
- **Realm**: `admin1`
- **Passos**: 1) logado como admin1, abrir `/studio`; 2) ler a sidebar: Painel, Conteúdos, Biblioteca visual, Usuários (4º e último); 3) CLICAR em "Usuários" (não digitar a URL); 4) conferir URL `/users` e `aria-current="page"` no item; 5) a lista de contas aparece.
- **Esperado**: 4 itens na ordem, destino `/users`, item destacado, lista exibida.
- **Risco se falhar**: ADMIN sem caminho para a tela; menu inconsistente.
- **Evidência**: _(preencher na verificação)_

### V2 — EDITOR recusado e sem item (AC-048-001 parte EDITOR, AC-048-002, AC-048-027)
- **Tela/rota**: `/studio` e `/users`
- **Realm**: `editor`
- **Passos**: 1) logado como editor, ler a sidebar em `/studio`: exatamente Painel, Conteúdos, Biblioteca visual; 2) com o painel de rede aberto, digitar `/users`; 3) ler a tela; 4) conferir as requisições.
- **Esperado**: sem item "Usuários"; em `/users`, "Você não tem permissão para ver esta página." sem sidebar; 0 requisições a `/api/v1/users` (só `/auth/me`).
- **Risco se falhar**: EDITOR vê a tela ou dispara consulta de contas.
- **Evidência**: _(preencher na verificação)_

### V3 — Servidor recusa EDITOR nas 4 operações (AC-048-004)
- **Tela/rota**: console do navegador, sessão `editor`
- **Realm**: `editor`
- **Passos**: 1) logado como editor, chamar pelo `fetch` do console (com credentials) `GET /api/v1/users`, `POST /api/v1/users` (corpo válido fictício), `PATCH /api/v1/users/<UUID-inexistente>/disable`, `POST /api/v1/users/<UUID-inexistente>/reset-password`; 2) conferir status e corpo; 3) no log do backend, contar `authz.denied`.
- **Esperado**: 403 nas 4 (não 404 — prova que a recusa vem antes do schema do param), nenhuma conta listada/criada/alterada; 4 linhas `authz.denied`.
- **Risco se falhar**: autorização no servidor furada.
- **Evidência**: _(preencher na verificação)_

### V4 — Criar conta: D2, D1 e e-mail repetido (AC-048-009..013, AC-048-026)
- **Tela/rota**: `/users`
- **Realm**: `admin1`
- **Passos**: 1) "Nova conta"; conferir campos, EDITOR pré-selecionado, ajuda ao escolher ADMIN ("Administradores gerenciam contas, fazem a checagem jurídica e aprovam versões de conteúdo."); 2) enviar com nome vazio, e-mail inválido e senha de 11 → mensagens por campo, nada enviado, foco no 1º inválido; 3) criar D2 (EDITOR) e D1 (ADMIN) com senhas inventadas → "Conta criada.", painel fecha, busca limpa, a conta nova é a 1ª linha "Ativa", sem recarregar; 4) repetir o e-mail de D2 → "Já existe uma conta com este e-mail." + "Se essa pessoa já teve uma conta desativada, a reativação ainda não está disponível por esta tela." junto ao e-mail, foco no e-mail, lista inalterada; 5) em cada caso, a senha não aparece na tela, na URL nem no armazenamento (DevTools → Application).
- **Esperado**: como nos ACs.
- **Risco se falhar**: conta criada com senha exposta ou sem feedback.
- **Evidência**: _(preencher na verificação)_

### V5 — Lista, busca e paginação (AC-048-005..007, RISK-048-010)
- **Tela/rota**: `/users`
- **Realm**: `admin1`
- **Passos**: 1) "(você)" só na linha de admin1; 2) com `route.fulfill` do Playwright, devolver `GET /api/v1/users` com 20 itens e `total: 45` (sintético) → 20 linhas, "Seguinte"/"Anterior", "Página N", foco preservado ao paginar por teclado; 3) buscar `descartavel-049` → só D1 e D2, página volta a 1, sem recarregar (marcador `window.__m=1` sobrevive); 4) `   ` (só espaços) → lista completa, sem erro, sem `search` na requisição; 5) `zzz-049-sem-resultado` → "Nenhum resultado para a busca."; 6) colar 121 caracteres → o campo fica com 120; 7) medir `%` e `_` (registro, não reprova).
- **Esperado**: como nos ACs.
- **Risco se falhar**: lista enganosa ou presa.
- **Evidência**: _(preencher na verificação)_

### V6 — Desativar D2 e recusas (AC-048-014..017, AC-048-028)
- **Tela/rota**: `/users`
- **Realm**: `admin1`
- **Passos**: 1) só contas ativas oferecem "Desativar"; 2) abrir "Desativar" SÓ na linha de D2: véu de fundo, nome e e-mail de D2, "a pessoa será desconectada", "a reativação não está disponível nesta tela", ordem [Confirmar desativação][Cancelar], foco em Cancelar, Esc fecha e devolve o foco; 3) com `route.fulfill` no `PATCH`: 409 "Não é possível desativar o último ADMIN ativo.", 409 "Não foi possível desativar a conta agora. Tente novamente.", 404 "Conta não encontrada." → mensagem na confirmação, situação inalterada; 4) `POST /auth/refresh` e a mutação em 401 → `/login?sessao=expirada`; 5) confirmar de verdade em D2 → "Desativada" em seguida e "Conta desativada." anunciado; repetir com outra conta descartável: o 2º anúncio também aparece.
- **Esperado**: como nos ACs.
- **Risco se falhar**: desativação sem confirmação clara ou recusa que quebra a tela.
- **Evidência**: _(preencher na verificação)_

### V7 — Redefinir senha (AC-048-019..023, AC-048-025, AC-048-026)
- **Tela/rota**: `/users`
- **Realm**: `admin1`
- **Passos**: 1) "Redefinir senha" só em conta ativa (usar D1 enquanto ativa); 2) diálogo com nome e e-mail, "as sessões da conta serão encerradas", foco no campo; 3) 11 caracteres → mensagem no campo, nada enviado; 4) Enter no campo e clique em Confirmar em voo → 1 só envio; 5) sucesso → diálogo fecha, "Senha redefinida." sem a senha; 6) campo vazio ao reabrir; a senha não aparece em nenhum lugar.
- **Esperado**: como nos ACs.
- **Risco se falhar**: senha exposta ou redefinição duplicada.
- **Evidência**: _(preencher na verificação)_

### V8 — Acessibilidade e 360 px (AC-048-008, NFR-048-003/004)
- **Tela/rota**: `/users` com o painel de criação e os dois diálogos
- **Realm**: `admin1`
- **Passos**: 1) temas claro e escuro: contraste AA de textos, controles, foco e véu; 2) só teclado: tudo alcançável, foco visível (anel `--link`), foco contido nos diálogos; 3) 360 px: a tabela rola dentro do contêiner, sem rolagem horizontal da página; e-mail longo quebra dentro do diálogo; em janela baixa (ou zoom 400%) o topo do diálogo continua alcançável.
- **Esperado**: AA nos dois temas; teclado completo; sem rolagem horizontal.
- **Risco se falhar**: tela inacessível.
- **Evidência**: _(preencher na verificação)_

### V9 — D1 redefine a própria senha (AC-048-024)
- **Tela/rota**: `/users` → `/login`
- **Realm**: D1 (login pelo formulário `/login` com a senha inventada no V4)
- **Passos**: 1) logado como D1, "Redefinir senha" na própria linha: aviso de que será desconectado; 2) confirmar com nova senha → `/login?sessao=expirada`; 3) registrar o texto exibido no login; 4) a nova senha entra; a antiga é recusada.
- **Esperado**: como no AC; o texto do login é registrado para a pergunta de produto pendente (A-048-013).
- **Risco se falhar**: ADMIN preso ou sessão antiga viva.
- **Evidência**: _(preencher na verificação)_

### V10 — D1 desativa a própria conta (AC-048-018)
- **Tela/rota**: `/users` → `/login`
- **Realm**: D1
- **Passos**: 1) logado como D1 (admin1 continua ADMIN ativo), "Desativar" na própria linha: aviso de que será desconectado; 2) confirmar → `/login?sessao=expirada`; 3) registrar o texto exibido; 4) login de D1 recusado.
- **Esperado**: como no AC; o texto exibido ("Sua sessão expirou. Entre novamente.") é a premissa A-048-013, pergunta de produto pendente — registrar, não reprovar.
- **Risco se falhar**: auto-desativação que deixa a tela em estado inconsistente.
- **Evidência**: _(preencher na verificação)_

## 5. Riscos e pontos de atenção
- Redirecionamento possivelmente repetido em série no isSelf (o refetch pós-`resetApiState` recebe 401 e
  agenda outro redirect): confirmar no navegador real que a navegação ao `/login` não reinicia.
- No isSelf, redefinir fecha e anuncia antes do redirect; desativar fica ocupado até o redirect
  (divergência registrada — pergunta de produto pendente).
- Termo com `%` ou `_` pode trazer contas a mais (limitação do backend, RISK-048-010).
- O navegador pode oferecer salvar a senha da conta nova no cofre do próprio ADMIN (pergunta de produto pendente).
- Tema escuro do véu do diálogo sobre a tabela; foco após 404 seguido de cancelar.

## 6. Protocolo de conclusão
1. Exercitar cada item V* e preencher a Evidência (✅/❌ + o que foi observado).
2. Divergência → corrigir na própria branch (protocolo inline: escopo restrito + testes +
   gates) e re-exercitar o item.
3. Tudo ✅ → `status: Concluído` no front-matter; atualizar INDEX do slug (remover o
   risco ativo + linha no Histórico recente); commit
   `chore(producao-material): close verification handoff HANDOFF-PLAN-049`; push.
4. Merge e deploy continuam decisão humana.
