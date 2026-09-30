# TASK-031-008: Botão de envio do login vira "Entrando" com spinner (emenda v0.3)

**Slug**: producao-material
**Pertence a**: PLAN-031
**Realiza (FRs)**: FR-030-017, FR-030-012
**Componente**: COMP-031-005 (principal)
**Wave**: 6
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo
**Jira**: KAN-185

## Dependências

- **Depende de**: TASK-031-005, TASK-031-007
- **Bloqueia**: nenhuma

## Contexto

Emenda v0.3 da SPEC-030 (BRIEF-043, Jira KAN-185). Estende COMP-031-005 (`LoginForm`,
restyle): durante o envio do login, o próprio botão de envio passa de "Entrar" a "Entrando"
com um spinner decorativo, e o texto solto "Entrando…" abaixo dele deixa de existir (a
invariante "status Entrando…" do BRIEF-030 foi revogada pelo Diretor no card). Realiza
**FR-030-017** (botão em envio, novo) e **FR-030-012** (movimento reduzido passa a cobrir o
indicador de progresso); toca NFR-030-001 (contraste do botão desabilitado nos dois temas),
NFR-030-002 (estado de envio no botão, anunciado a tecnologia assistiva), NFR-030-005 e
AC-030-009/010/011/015, citados aqui em texto, e prova o AC-030-016 (novo). Execução inline
pela rota emenda (developer no `mnemonicos-frontend`); esta TASK é o registro SDD dessa
unidade. Premissas P-043-001..006 do BRIEF-043 valem como decididas (com o endurecimento do
PO).

## Escopo

### Inclui
- Em `mnemonicos-frontend/src/components/login-form.tsx`: o botão `type="submit"` mostra, com
  `isLoading`, o rótulo "Entrando" com o spinner à esquerda do texto, par centralizado, sem
  mudar largura nem altura (o spinner não passa da altura da linha do texto — P-043-006); fora
  do envio, rótulo "Entrar", sem spinner. O bloco `<span role="status" aria-live="polite">
  Entrando…</span>` é removido.
- Anúncio acessível (P-043-001): região viva `sr-only`, **fora do fluxo** (não gera o `gap-4`
  do form nem desloca o link), **sempre montada**, vazia fora do envio e com o texto
  "Entrando" só durante o envio; anuncia **uma vez**; ao falhar, esvazia sem anunciar
  "Entrar" (o erro segue só no `role="alert"`). O `aria-busy` do formulário continua. Onde a
  região fica, para não ser silenciada pelo `aria-busy`, é decisão técnica do developer,
  cobrada pelo gate 11.
- Botão desabilitado sem `disabled:opacity-60` — só o botão de envio de `/login` (P-043-003);
  rótulo e spinner com os tokens `night-button-*` já medidos para AA; token novo só se a
  medição exigir, no `@theme` de `mnemonicos-frontend/src/app/globals.css`, sem cor literal
  (NFR-030-006). O `disabled:opacity-60` dos outros botões do app não se toca.
- Componente novo `mnemonicos-frontend/src/components/spinner.tsx` (P-043-004): SVG inline +
  CSS, sem dependência nova, `currentColor`, `aria-hidden`, fora da ordem de foco, gira só
  quando o movimento é permitido e fica estático sob `prefers-reduced-motion: reduce`; API
  mínima, sem props de tamanho, variante ou cor. Nenhum outro botão do app passa a usá-lo.
- Enter duplicado (P-043-005): provado por teste (botão desabilitado → Enter num campo não
  reenvia). Só se o teste mostrar reenvio entra uma guarda em `handleSubmit` que ignora envio
  com envio em andamento — a única exceção nomeada da §4.2 da SPEC.
- Testes: em `mnemonicos-frontend/src/components/login-form.test.tsx` (e nos
  `login-form*.test.tsx` irmãos que afirmem o estado de envio) e em
  `mnemonicos-frontend/src/app/login/page-back-link.test.tsx`, as asserções do texto
  "Entrando…"/`role=status` e do botão desabilitado durante o envio são **substituídas** pelas
  do estado no botão (AC-030-011, exceção nomeada); testes novos para spinner (`aria-hidden`,
  estático sob movimento reduzido), ausência do texto solto, retorno a "Entrar" após falha de
  credencial e de rede, botão desabilitado sem reenvio por clique ou Enter e anúncio
  acessível único (região consultada pelo texto, nunca por `getByRole('status')` sem filtro —
  o aviso `?sessao=expirada` também é `role="status"`).

### Não inclui
- Lógica do login: mutação, `next`, `INTERNAL_HOME`, mensagem genérica e aviso de sessão
  expirada (NFR-030-002/003) — salvo a guarda condicional de reenvio acima.
- Comportamento do link "Voltar para o início" (FR-030-016 continua como está).
- Outros botões com estado de progresso no app (logout do header, formulários internos);
  paleta e tokens de outros papéis além do botão de envio de `/login`.
- Backend; `password-field.test.tsx`, `page.test.tsx` e `page.next-param.test.ts`, que não
  mudam.

## Critérios de pronto

- [ ] Botão em envio (AC-030-016 — FR-030-017): com o login em andamento, o botão mostra
      "Entrando" e o spinner, está desabilitado, não reenvia por clique nem por Enter num
      campo; nenhum texto "Entrando…" existe fora do botão em nenhum estado; fora do envio o
      botão é "Entrar" sem spinner — Testes cobrem AC-030-016: verificação executável:
      `npm --prefix mnemonicos-frontend test -- src/components/login-form src/app/login/page`
      → OK (N tests), nenhum arquivo com "No tests found", com asserções de rótulo e spinner
      durante `isLoading`, `toBeDisabled()`, ausência do texto "Entrando…" (`queryByText`),
      Enter num campo com o botão desabilitado sem segunda chamada do trigger de
      `useLoginMutation`. Falsificação: reintroduzir o `<span role="status">Entrando…</span>`
      solto, ou manter o rótulo "Entrar" durante o envio, reprova.
- [ ] Retorno a "Entrar" após falha (AC-030-016): falha de credencial e falha de rede devolvem
      o botão a "Entrar", sem spinner, com a mensagem de erro em `role="alert"` como hoje e a
      região viva vazia (sem anunciar "Entrar") — mesma verificação executável acima, com os
      dois ramos de falha. Falsificação: deixar o spinner após o erro reprova.
- [ ] Anúncio acessível único e spinner decorativo (AC-030-016, NFR-030-002): região viva
      `sr-only` consultada pelo texto "Entrando", presente e vazia fora do envio, com o texto
      só durante o envio; `aria-busy` no `<form>` durante o envio; spinner com
      `aria-hidden="true"` e fora da ordem de foco — mesma verificação executável. Sem nenhum
      elemento novo no fluxo do form entre os estados (P-043-006).
- [ ] Movimento reduzido (AC-030-009/AC-030-016, FR-030-012): com `prefers-reduced-motion:
      reduce`, o spinner não gira (estático) e o rótulo "Entrando" continua — verificação
      executável: `npm --prefix mnemonicos-frontend test -- src/components/spinner`
      → OK (N tests, N > 0), com asserção de que a animação de giro é condicionada a
      `motion-safe`/equivalente (ou supressão na media query) e de que o spinner estático
      permanece renderizado.
- [ ] Contraste AA do botão desabilitado nos dois temas (AC-030-010/AC-030-016, NFR-030-001):
      sem `disabled:opacity-60` no botão de envio; par rótulo × fundo do botão desabilitado
      ≥ 4,5:1 e spinner ≥ 3:1 nos temas claro e escuro — verificação executável:
      `npm --prefix mnemonicos-frontend test -- src/app/globals-theme-contrast.test.ts`
      → OK (N tests, N > 0), incluindo o par do botão desabilitado (envio e pré-hidratação);
      e `grep -n "disabled:opacity-60" mnemonicos-frontend/src/components/login-form.tsx`
      → saída vazia (capturar também no commit-pai, para provar que a ausência não é herdada).
- [ ] Sem cor literal nova (NFR-030-006): verificação executável:
      `grep -En "#[0-9a-fA-F]{3,8}|rgb\(|rgba\(|hsl\(" mnemonicos-frontend/src/components/login-form.tsx mnemonicos-frontend/src/components/spinner.tsx | grep -vE '^[^:]+:[0-9]+:\s*(//|/\*|\*)'`
      → saída vazia (e nenhum valor literal novo em `globals.css`, se tocado).
- [ ] Testes existentes sem afrouxamento (AC-030-011, NFR-030-005): só as asserções do texto
      "Entrando…"/`role=status` e do botão desabilitado durante o envio são substituídas;
      `aria-busy`, ausência de `aria-invalid`, `method="post"`, hidratação, `role="alert"` e
      redirecionamento seguem afirmados — verificação executável:
      `npm --prefix mnemonicos-frontend test -- src/app/login/page src/components/login-form src/components/password-field`
      → OK (N tests), N ≥ contagem-baseline capturada **antes** do diff (mesmo comando no
      commit-pai); revisão do diff de teste confirma que nenhuma outra asserção foi removida
      ou enfraquecida. Suíte sob `testEnvironment` customizado
      (`<rootDir>/test/jsdom-fetch-env.js`), nunca `jest.mock('@/proxy', ...)`.
- [ ] Dimensões e link parados (AC-030-016, AC-030-015, gate 9): largura e altura do botão
      iguais em "Entrar" e "Entrando" e o link "Voltar para o início" sem deslocamento em
      360/768/1280px, nos dois temas — passos 2–3 do roteiro.
- [ ] Composição, contraste visual e falhas em tela (AC-030-016, gate 9): estado "Entrando"
      capturado nos dois temas; falha de credencial e de rede devolvem "Entrar" — roteiro
      abaixo.
- [ ] Lint e typecheck limpos: `npm --prefix mnemonicos-frontend run lint` e
      `npm --prefix mnemonicos-frontend run typecheck` (nomes conforme scripts da ficha) →
      exit 0, sobre todos os arquivos do diff (`git diff --name-only main...HEAD`), produção
      e teste.
- [ ] Sem warnings/lints novos.

## Arquivos previstos (mnemonicos-frontend)

- `src/components/login-form.tsx` (botão, região viva, remoção do texto solto; guarda só se
  o teste exigir)
- `src/components/spinner.tsx` (novo) e seu teste
- `src/app/globals.css` (só se precisar de token novo; sem cor literal)
- `src/components/login-form*.test.tsx`
- `src/app/login/page-back-link.test.tsx`

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente**: app real local — em `mnemonicos-backend/`: `npm run db:up` seguido de
`npm run dev` (API em `http://localhost:3333`); em `mnemonicos-frontend/`: `npm run dev`
(`http://localhost:3000/login`). Porta ocupada sobe na próxima livre com o ajuste de
`CORS_ORIGINS`/`BACKEND_API_URL` declarado no fecho (CLAUDE.md do workspace). Tema alternado
por emulação de `prefers-color-scheme` no DevTools.

**Sujeito**: ADMIN semeado por `npm run db:seed`, credenciais lidas de
`SEED_ADMIN_EMAIL`/`SEED_ADMIN_PASSWORD` do `.env` do backend — nunca chutadas nem
reproduzidas no registro.

**Pré-condição**: sessão limpa (aba anônima ou cookies do domínio apagados) antes de cada
passo; após login bem-sucedido, logout.

1. (AC-030-016 — estado "Entrando") Com interceptação de rede/throttle segurando a resposta
   do POST de login (latência real não garante a janela), enviar o formulário em `/login`:
   o botão mostra "Entrando" com o spinner girando, desabilitado, sem texto "Entrando…"
   abaixo; clique e Enter repetidos não geram segundo POST (painel de rede). Capturas nos dois
   temas.
2. (AC-030-016 — dimensões e link) Em 360, 768 e 1280px, nos dois temas: largura e altura do
   botão iguais em "Entrar" e "Entrando", link "Voltar para o início" na mesma posição nos dois
   estados, sem rolagem horizontal.
3. (AC-030-010 — contraste) Botão desabilitado em envio e na pré-hidratação, nos dois temas:
   rótulo e spinner legíveis (≥ 4,5:1 e ≥ 3:1), sem esmaecimento por opacidade.
4. (AC-030-009 — movimento reduzido) Com `prefers-reduced-motion: reduce` emulado, repetir o
   passo 1: o spinner fica estático e o rótulo "Entrando" continua.
5. (AC-030-016 — falha de credencial) Senha errada: o botão volta a "Entrar", sem spinner, e a
   mensagem genérica aparece em `role="alert"` como hoje.
6. (AC-030-016 — falha de rede) Backend indisponível/requisição bloqueada: o botão volta a
   "Entrar", sem spinner, e o erro aparece como hoje.
7. (AC-030-016 — anúncio acessível) Com leitor de tela (ou inspeção da árvore de
   acessibilidade): "Entrando" é anunciado uma vez no envio, o spinner não é exposto, e a
   falha não anuncia "Entrar"; o erro é anunciado só pelo `role="alert"`.
8. (AC-030-015 / AC-030-012 — não-regressão) Sucesso: login real de ADMIN leva a `INTERNAL_HOME`
   (e a `next` seguro em `/login?next=/studio`); clique no link durante o envio leva a `/` sem
   erro de console.

## Riscos específicos

- Captura de estado passageiro: o "Entrando" só existe durante a requisição; exige
  interceptação/throttle (passo 1), nunca latência natural.
- Região viva silenciada pelo `aria-busy` do formulário: o gate 11 cobra a posição escolhida
  (P-043-001).
- AA do botão desabilitado sem opacidade depende dos tokens `night-button-*` (medição do PO:
  escuro ~5,06:1, claro ~14,16:1); token novo, se preciso, nasce no `@theme`.
- Fixação parcial: o scribe não tem shell — os comandos acima **não foram executados** na
  fixação (baseline no commit-pai e prova de ausência ficam pendentes para o developer
  capturar antes do diff). Registrar a baseline no fecho.
- O gate 11 já precisou de rodada extra em `/login` (BRIEF-032, PLAN-031): reservar margem
  para um retry do `product-designer`.

---

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-185

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8)
- [ ] Comportamento (gate 9)
- [ ] Design (gate 11)
- [ ] Performance (gate 10)

**Baseline dos critérios**:
