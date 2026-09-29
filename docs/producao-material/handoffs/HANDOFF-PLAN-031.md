---
id: HANDOFF-PLAN-031
slug: producao-material
branch: feat/producao-material-login-redesign (pushada em origin)
status: Pendente
criado: 2026-09-29T18:15:14+0000
origem: PLAN-031
commits: [f1d119b, 7d8373e, 5795754, 3ea00ea, 4b1b6b9, 80d7879, 2702b1b, 17069ae, ab1e32a, cab074e, 9c49fb3, 7e49c5a, 71b606c, c89d3cb, 55dbf61, e32a23c, f328321]
motivo: permissao_ambiente
sonda: >-
  qa (gate 9, TASK-031-004) tentou digitar a senha real da credencial ADMIN de
  screenVerify.realms diretamente no campo de senha da UI de `/login` via
  `mcp__playwright__browser_type` para completar o clique físico de AC-030-012. A
  chamada foi negada pelo classificador de segurança do harness (materialização de
  credencial em ambiente de subagent) — mesma classe de bloqueio já registrada em
  HANDOFF-PLAN-013 (`permissao_ambiente`, decisão 4.133: negativa não é flakiness,
  não repetida). Reparo não é técnico (não é ausência de runtime/app/credencial): só
  uma sessão sem essa restrição de sandbox — Diretor ou execução local — pode digitar
  a senha de verdade. Evidência composta obtida no lugar do clique físico: POST real
  ao endpoint que `LoginForm` chama, direto (`:3333`) e via proxy do Next
  (`:3000/api/auth/login` → `rewrites()`), retornou 200 + `Set-Cookie` `HttpOnly` +
  `role: ADMIN` no corpo, nos dois caminhos.
---

# Handoff de verificação de tela — Redesenho visual da tela de login (clique físico)

## 1. Contexto da entrega

PLAN-031 (SPEC-030, BRIEF-030, KAN-73) redesenha o visual de `/login` no
`mnemonicos-frontend`: card em duas metades sobre fundo em tela cheia com a mesma
ilustração desfocada, paleta nova em tokens `@theme` (dois temas, contraste AA), campos
em pílula com ícone, sem alterar o comportamento contratado de `LoginForm`/`page.tsx`/
`PasswordField`. Dos 12 passos do roteiro de gate 9, 11 foram exercitados e VERIFICADOS
via navegador real (Playwright MCP) nesta sessão — capturas em `thoughts/screen-verify/
login-{claro,escuro}-{360,768,1280}.png`. Este handoff cobre só o item que a sandbox do
subagent bloqueou: o clique físico de login com credencial real (AC-030-012).

## 2. Já verificado (não repetir)

- **Testes** (`quality.test`, frontend): 627/627 (50 suítes) — verde no HEAD `f328321`.
- **Lint/typecheck** (`quality.lint`/`quality.typecheck`, frontend): limpos no mesmo HEAD.
- **API exercitada sem tela**: POST direto a `http://localhost:3333/api/v1/auth/login`
  e via proxy `http://localhost:3000/api/auth/login` — ambos 200, cookie `HttpOnly` de
  sessão presente, `role: ADMIN` no corpo. Guard `isSafeRelativePath`/redirect para
  `INTERNAL_HOME` coberto por teste automatizado (sem regressão em nenhuma wave).
- **Estados visuais/estruturais de `/login`** (10/11 passos do roteiro): card em duas
  metades, fundo em tela cheia, temas claro/escuro, responsivo 360/768/1280, contraste
  AA (inclusive header/footer herdado — corrigido na convergência de fecho),
  `prefers-reduced-motion`, ausência de controles sem função, aviso de sessão expirada —
  todos VERIFICADOS via navegador real, capturas salvas.

## 3. Pré-requisitos de ambiente

- **Subir o frontend**: `npm --prefix mnemonicos-frontend run dev` (porta `3000` padrão;
  ocupada → próxima livre, e então acrescentar a origem nova a `CORS_ORIGINS` do backend —
  CLAUDE.md do workspace, seção "Ambiente local — portas").
- **Subir o backend**: `npm --prefix mnemonicos-backend run dev` (porta `3333` padrão).
- **Migrações/seeds pendentes desta branch**: nenhuma — PLAN-031 é só frontend
  (CSS/componentes), sem mudança de schema/Prisma.
- **Credencial de tela**: `keelson.local.json` › `screenVerify.realms.app` (ADMIN
  semeado) — mesma credencial já usada por HANDOFF-PLAN-013/003.
- **Navegador**: real ou Playwright MCP fora de sandbox com bloqueio de materialização
  de credencial (a UI em si não exige navegador não-headless, só a digitação da senha
  real precisa de uma sessão sem essa restrição).

## 4. Roteiro de verificação (itens pendentes)

### V1 — Login real por clique físico, com e sem `next` (AC-030-012)
- **Tela/rota**: `http://localhost:3000/login` e `http://localhost:3000/login?next=%2Festudo`
- **Realm**: `app`
- **Passos**:
  1. Abrir `/login`, digitar e-mail e senha reais da credencial ADMIN de
     `screenVerify.realms.app` nos campos em pílula redesenhados.
  2. Clicar o botão primário — observar o estado "Entrando…" (`aria-busy`) e o
     desfecho.
  3. Confirmar o redirecionamento para `INTERNAL_HOME` (sem `next` na URL).
  4. Repetir os passos 1–2 partindo de `/login?next=%2Festudo` — confirmar
     redirecionamento para `/estudo` em vez de `INTERNAL_HOME`.
- **Esperado**: nos dois casos, login bem-sucedido leva à rota esperada sem erro
  visível; nenhuma diferença de comportamento em relação ao `LoginForm` pré-redesenho
  (só o estilo mudou) — mesmo fluxo já provado por evidência composta de rede (POST
  200 + cookie + role), agora confirmado pelo clique físico na UI redesenhada.
- **Risco se falhar**: o redesenho visual (pílula, ícones, novo layout de campos) teria
  quebrado o `onSubmit`/estado de hidratação do `LoginForm` sem que nenhum teste
  automatizado ou a evidência de rede tivesse capturado — superfície central do produto
  (login é o único ponto de entrada autenticado).
- **Evidência**: _(preencher na verificação)_

## 5. Riscos e pontos de atenção

- **Autofill do navegador** (achado `fora_de_escopo` do `qa`, já registrado no INDEX):
  ausência de regra `:-webkit-autofill`/`:-autofill` nos campos de `/login` — risco
  estético plausível (o autofill pode sobrescrever o fundo preenchido em pílula), não
  confirmado (Chromium headless não expõe o password manager nativo). Se V1 usar um
  navegador com senha salva, observe também esse ponto e registre o resultado aqui
  mesmo que fora do escopo formal de AC-030-012.
- **Tom do botão no tema escuro** (ressalva 2 da aceitação do PO): o botão primário
  (`#6e5d77`, mauve médio) ficou mais claro que o painel escuro que o envolve —
  decisão do Tech Lead documentada no ledger da sessão (contraste AA prevalece sobre a
  leitura literal de "tom escuro" do FR-030-005) e já confirmada pelo `product-designer`
  (3,33:1). Sem ação pendente aqui — mencionado para o Diretor correlacionar com o que
  vir na tela durante V1.

## 6. Protocolo de conclusão

1. Exercitar V1 e preencher a **Evidência** (✅/❌ + o que foi observado, para os dois
   casos — com e sem `next`).
2. Divergência → corrigir na branch `feat/producao-material-login-redesign` (protocolo
   inline: escopo restrito + testes + gates) e re-exercitar o item.
3. Tudo ✅ → `status: Concluído` no front-matter; atualizar `docs/producao-material/INDEX.md`
   (remover a linha de AC-030-012 da tabela de pendências + linha no Histórico recente);
   commit `chore(producao-material): close verification handoff HANDOFF-PLAN-031`; push.
4. Merge e deploy continuam decisão humana (do Diretor).
