# TASK-031-007: Tirar cabeçalho e rodapé de /login e pôr o link "Voltar para o início" (emenda v0.2)

**Slug**: producao-material
**Pertence a**: PLAN-031
**Realiza (FRs)**: FR-030-013
**Componente**: COMP-031-004 (principal)
**Wave**: 5
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: TASK-031-004, TASK-031-005
- **Bloqueia**: nenhuma

## Contexto

Emenda v0.2 da SPEC-030 (BRIEF-039, Jira KAN-177 — História; sem subtask, modo link). Estende
COMP-031-004 (`LoginCardFrame`, `page.tsx`, dono do cartão): `/login` perde o rodapé (o
cabeçalho já saía por BRIEF-032) e ganha, no cartão, um link discreto "Voltar para o início"
→ `/`, fora do `<form>`, após o botão de envio. Realiza FR-030-013 (campo de aresta) e também
**FR-030-015** (link) e **FR-030-016** (link acionável durante "Entrando…"), que a SPEC v0.2
criou e o PLAN-031 v0.1 ainda não lista em "FRs cobertos" — citados aqui em texto para não
quebrar a referência do grafo. Execução inline pela rota emenda (developer no
`mnemonicos-frontend`, branch `feat/producao-material-login-sem-rodape-voltar`); esta TASK é
o registro SDD dessa unidade. Premissas P-039-001..005 do BRIEF-039 valem como decididas.

## Escopo

### Inclui
- Fonte única de "rotas sem moldura do app": a lista `CHROME_HIDDEN_ROUTES`
  (`mnemonicos-frontend/src/components/app-chrome-gate.tsx`, renomeado de
  `site-header-gate.tsx`, com teste em `app-chrome-gate.test.tsx`) governa cabeçalho e
  rodapé (P-039-001), sem segunda lista e sem `if (pathname === '/login')` solto. `mnemonicos-frontend/src/app/layout.tsx` deixa de
  renderizar `<footer>` incondicional; `RootLayout` continua Server Component testável sem
  `render`.
- Regra vale para o caminho `/login` com qualquer query (`?next=…`, `?sessao=expirada`) —
  P-039-005.
- Em `mnemonicos-frontend/src/app/login/page.tsx`: link (`next/link`) com o texto exato
  "Voltar para o início" e `href="/"`, **fora** do `<form>` (obrigatório — P-039-003), logo
  depois de `<LoginForm>` no painel de formulário; texto pequeno, cor secundária por token
  do `@theme` (ex.: `text-muted`), sem fundo nem borda de botão, foco visível; não é
  desabilitado durante "Entrando…" (P-039-004).
- Testes: asserções novas em `mnemonicos-frontend/src/app/layout.test.tsx` (ausência do
  rodapé em `/login`, presença nas demais rotas),
  `mnemonicos-frontend/src/components/app-chrome-gate.test.tsx` e
  `mnemonicos-frontend/src/app/login/page-back-link.test.tsx` (arquivo novo: link, destino,
  posição fora do form, inventário do cartão, ordem de Tab, estado "Entrando…" e Enter). Essas
  asserções não vivem em `page.test.tsx` porque ele mocka o `LoginForm` (`page.test.tsx:9`) e
  a ordem de Tab, o estado "Entrando…" e o Enter exigem o form real.

### Não inclui
- Cabeçalho, rodapé ou contêiner de qualquer outra rota; texto do rodapé (AC-030-006 segue
  como está).
- Qualquer alteração em `LoginForm`/`PasswordField`, guarda de `next`, mensagens de erro e de
  sessão expirada (NFR-030-002/003/004) — inclusive `login-form.test.tsx` e
  `password-field.test.tsx`, que não mudam.
- Redirecionar quem já tem sessão (KAN-180) e cancelar a requisição de login ao sair da tela.
- O ramo "permanece em `/` após a resposta" durante o login em andamento: o AC prova só que o
  clique navega para `/` sem erro e sem travar (P-039-004).
- Provas já entregues por TASK-031-004 e não reabertas aqui: AC-030-013 e AC-030-014 (o grep
  de cor literal é reexecutado no critério de token abaixo, para o arquivo tocado).

## Critérios de pronto

- [ ] `/login` sem rodapé e demais rotas com rodapé; lista única de rotas — Testes cobrem
      AC-030-011 (parte — asserções novas de `layout.test.tsx` e `page-back-link.test.tsx`,
      esta última pelo motivo do Escopo: `page.test.tsx` mocka o `LoginForm`; nenhuma
      asserção existente afrouxada; a prova do link é do AC-030-015): verificação executável:
      `npm --prefix mnemonicos-frontend test -- src/app/layout.test.tsx src/app/login/page src/components/app-chrome-gate.test.tsx src/components/login-form.test.tsx src/components/password-field.test.tsx`
      (o padrão `src/app/login/page` casa `page.test.tsx` e `page-back-link.test.tsx`)
      → OK (N tests), N ≥ contagem-baseline capturada **antes** do diff (mesmo comando no
      commit-pai; a contagem final tem de ser maior, pelas asserções novas) e nenhum arquivo
      com "No tests found". Prova de falsificação: remover a checagem de rota do rodapé (ou
      reintroduzir `<footer>` incondicional) reprova a asserção nova de ausência em `/login`.
      Suíte sob `testEnvironment` customizado (`<rootDir>/test/jsdom-fetch-env.js`), nunca
      `jest.mock('@/proxy', ...)` — lição ativa
      `jsdom-sem-request-response-fetch-por-import-transitivo-de-next-server-testenvironment-can-nico-nunca-mock-do-m-dulo-sob-guarda`.
- [ ] Ausência de segunda regra de rota (P-039-001): verificação executável:
      `grep -rEn "pathname *===? *['\"]/login['\"]" mnemonicos-frontend/src --include=*.tsx --include=*.ts | grep -v '\.test\.'`
      → saída vazia; e `grep -n "CHROME_HIDDEN_ROUTES\|'/login'" mnemonicos-frontend/src/components/app-chrome-gate.tsx`
      → ≥ 1 linha (a lista existe e é a única fonte). Rodar também contra o commit-pai: a
      primeira busca já é vazia ali (ausência não herdada).
- [ ] Inventário do cartão (AC-030-005): `<form>` com exatamente 4 controles (e-mail, senha,
      toggle, botão de envio) e o cartão com esses 4 mais o link "Voltar para o início" fora
      do `<form>` — Testes cobrem AC-030-005: verificação executável:
      `npm --prefix mnemonicos-frontend test -- src/components/login-form.test.tsx src/app/login/page`
      (roda `page.test.tsx` e `page-back-link.test.tsx`)
      → OK, com asserção de contagem de controles dentro do `<form>` (4, nenhum link), de
      `link.closest('form') === null` no cartão e de contagem fechada de interativos do CARTÃO
      (5: 1 textbox, 2 buttons, 1 link). Falsificação: mutante "button extra depois do link"
      reprova a contagem.
- [ ] Link (AC-030-015, parte de gate 1 — destino, posição, ordem, token; contraste visual,
      clique em voo e alinhamento em 360/768/1280 são do roteiro do gate 9): link com texto
      "Voltar para o início", `href="/"`, fora do `<form>`, posterior ao botão de envio na
      ordem do DOM, classes de texto pequeno e cor por token sem `bg-`/`border` de botão; Enter
      em um campo continua submetendo o formulário — verificação executável:
      `npm --prefix mnemonicos-frontend test -- src/app/login/page`
      (roda `page.test.tsx` e `page-back-link.test.tsx`)
      → OK (N tests) com asserções de `getByRole('link', { name: 'Voltar para o início' })`,
      `toHaveAttribute('href', '/')`, `compareDocumentPosition` contra o botão, ausência de
      classe de fundo/borda, classe `underline` no link em repouso, Enter em campo chamando o
      trigger de `useLoginMutation` e "clique não prevenido" provado por
      `defaultPrevented === false` durante o `isLoading` ("Entrando…"). Falsificação: mover o link para dentro do `<form>` ou mudar o
      `href` reprova.
- [ ] Contraste AA do link nos dois temas (AC-030-015 parte — contraste): a cor do link é
      token semântico já medido sobre o painel; confirmar que o par do token escolhido contra
      `--surface`/`--color-night-panel-bg` está em `night-palette-tokens.ts` e, se faltar,
      acrescentá-lo — verificação executável:
      `npm --prefix mnemonicos-frontend test -- src/app/globals-theme-contrast.test.ts`
      → OK (N tests, N > 0), incluindo o par do token do link, ≥ 4,5:1 nos temas claro e
      escuro.
- [ ] Sem cor literal nova (AC-030-015 parte — token do `@theme`): verificação executável:
      `grep -En "#[0-9a-fA-F]{3,8}|rgb\(|rgba\(|hsl\(" mnemonicos-frontend/src/app/login/page.tsx | grep -vE '^[0-9]+:\s*(//|/\*|\*)'`
      → saída vazia (também vazia no commit-pai — critério de ausência não herdado).
- [ ] Composição em `/login` (AC-030-001, gate 9): card em duas metades sobre o fundo, nos
      dois temas, sem cabeçalho e sem rodapé — em `/login`, `/login?next=/studio` e
      `/login?sessao=expirada` (passos 1–2 do roteiro).
- [ ] Lint e typecheck limpos: `npm --prefix mnemonicos-frontend run lint` e
      `npm --prefix mnemonicos-frontend run typecheck` (nomes conforme scripts da ficha) →
      exit 0, sobre todos os arquivos do diff (`git diff --name-only main...HEAD`), produção
      e teste.
- [ ] Sem warnings/lints novos.

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente**: app real local — em `mnemonicos-backend/`: `npm run db:up` seguido de
`npm run dev` (API em `http://localhost:3333`); em `mnemonicos-frontend/` (worktree
`wt-login-voltar`): `npm run dev` (`http://localhost:3000/login`). Porta ocupada sobe na
próxima livre com o ajuste de `CORS_ORIGINS`/`BACKEND_API_URL` declarado no fecho (CLAUDE.md
do workspace). Tema alternado por emulação de `prefers-color-scheme` no DevTools.

**Sujeito**: ADMIN semeado por `npm run db:seed`, credenciais lidas de
`SEED_ADMIN_EMAIL`/`SEED_ADMIN_PASSWORD` do `.env` do backend — nunca chutadas nem
reproduzidas no registro.

**Pré-condição**: sessão limpa (aba anônima ou cookies do domínio apagados) antes de cada
passo; após login bem-sucedido, logout para restaurar o estado limpo.

1. (AC-030-001) Em `http://localhost:3000/login`, `/login?next=/studio` e
   `/login?sessao=expirada`, nos temas claro e escuro × 360/768/1280px (6 combinações por
   URL; capturas das 6 do `/login` puro anexadas): card central em duas metades sobre o fundo,
   sombra, **sem cabeçalho e sem rodapé** do app; sem rolagem horizontal.
2. (AC-030-006, não-regressão) Em `/` e numa rota interna (ex.: `INTERNAL_HOME`, autenticado):
   cabeçalho, rodapé (texto "Projeto Material Mnemônico de Alta Retenção para Concursos") e
   contêiner idênticos ao estado anterior.
3. (AC-030-015 — ordem de foco e Enter) Em `/login`, Tab a partir do topo: ordem e-mail →
   senha → toggle → botão "Entrar" → link "Voltar para o início", cada parada com foco
   visível ≥ 3:1; em campo preenchido, Enter envia o login (segue o redirecionamento de
   `INTERNAL_HOME`, ou de `next` seguro em `/login?next=/studio`).
4. (AC-030-015 — discrição e alinhamento) Nos dois temas e em 360/768/1280px: o link é texto
   pequeno em cor secundária, sem fundo nem borda, legível, e o cartão não desalinha.
5. (AC-030-015 — clique durante o login em andamento) Com interceptação de rede segurando a
   resposta do POST de login (técnica do passo — latência real não garante a janela), enviar
   o formulário, confirmar "Entrando…" visível e clicar no link: o navegador vai para `/`
   sem erro de console e sem travar. Não afirmar que permanece em `/` depois da resposta (no
   sucesso, o `LoginForm` leva à área interna — P-039-004). Efeito é do próprio cliente;
   observador: painel de rede e console do navegador.
6. (AC-030-015 — clique normal) Sem login em andamento, clicar no link leva a `/` (rota
   pública) e a página inicial renderiza com cabeçalho e rodapé.

## Riscos específicos

- TRISK-031-004 (foco de teclado, herdado do PLAN-031): o passo 3 estende a ordem de foco
  com o link ao final; RISK-030-003 da SPEC v0.2 já o inclui.
- Fixação parcial: o scribe não tem shell — os comandos acima **não foram executados** na
  fixação (evidência de conjunto não-vazio e de ausência no commit-pai fica pendente para o
  developer capturar antes do diff). Registrar a baseline no fecho.
- O gate 11 já precisou de rodada extra em `/login` (BRIEF-032 e PLAN-031): reservar margem
  para um retry do `product-designer`.

---

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 2026-09-30T13:16:27-0300
**Data conclusão**: 2026-09-30T13:43:09-0300
**Commit SHA**: `f35c4f3` (mnemonicos-frontend, branch `feat/producao-material-login-sem-rodape-voltar`; 1 retry consolidado dos gates 1–7 e 11 antes do commit)
**Jira**: KAN-177 (História, modo link; sem subtask)

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado — security-engineer, 0 achados (superfície: tela de login; o diff não toca auth, sessão nem a guarda de `next`). gitleaks ausente: segredos só por grep
- [x] Comportamento (gate 9): verificado — qa, 2 rodadas; a final, sobre o código final com login real de ADMIN, fechou os passos A–E do roteiro. Capturas em `thoughts/screen-verify/gate9-login-voltar-r2/`
- [x] Design (gate 11): aprovado — product-designer no retry (sublinhado em repouso)
- [x] Performance (gate 10): n/a — sem consulta, laço, dependência nova nem render pesado

**Baseline dos critérios** (medida pelo code-reviewer): escopo da TASK 76/76 (6 suítes) no commit-pai `b729a76` → 88/88 (7 suítes) na 1ª rodada; `npm run validate` final: 58 suítes, 741 testes. O grep de segunda regra de rota volta vazio fora dos testes; `CHROME_HIDDEN_ROUTES` está em `app-chrome-gate.tsx:12`.
