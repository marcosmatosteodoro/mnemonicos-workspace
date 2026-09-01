# Produção de Material

> Arquivo gerado automaticamente. Não edite manualmente.
> Para alterar conteúdo, use /keelson:specify, /keelson:plan, /keelson:tasks ou /keelson:implement.

**Slug**: producao-material
**Última atualização**: 2026-08-31T14:30:00-03:00
**Mapa do território**: MAP.md

## Resumo

Fábrica interna de produção do material mnemônico: o acervo estruturado (10 camadas do método,
tira como sequência de quadros) entra, o PDF diagramado sai — com versão, data de fechamento de
legislação e checklist de revisão jurídica. O estudante não é usuário deste software; o que ele
compra é o PDF. A régua de valor é tempo de produção por página, instrumentado por etapa.

## Capacidades

### Implementadas
- Provisionamento de contas internas por ADMIN + seed do 1º ADMIN (SPEC-002/FEAT-002-003, PLAN-003, ✅ 2026-08-30) — módulo `users/` (criar/listar/desativar/resetar senha) + seed; gate 9 APROVADO. Montagem das rotas em `apiRoutes` fica com TASK-003-011 (Wave 6).
- Autenticação de sessão da equipe interna (SPEC-002/FEAT-002-001, PLAN-003, ✅ 2026-08-31) — login com três estados observáveis + mensagem genérica pt-BR + sessão expirada; rotação de família, freio de login, cookies `httpOnly`. Gate 9 **pendente_handoff** (trânsito real à área interna no sucesso — causa: credencial; seed em HANDOFF-PLAN-003.md).
- Autorização por papel deny-by-default no servidor (SPEC-002/FEAT-002-002, PLAN-003, ✅ 2026-08-31) — `assertDenyByDefault` no boot + suíte `route-authz-matrix` (28/28) + store do frontend com re-auth + shell da área interna (`InternalShell` com 3 estados, logout com 3 estados, `config.matcher` derivado do grupo `(interno)`). Gate 9 **pendente_handoff** (caminhada e2e de AC-002-013/AC-002-027 — causa: credencial).

### Em desenvolvimento
(nenhuma — PLAN-003 completo; F1 do épico MNEMORA STUDIO aguarda merge + Entrega)

### Especificadas, ainda não planejadas
(nenhuma — SPEC-002 coberta por PLAN-003)

_Épico MNEMORA STUDIO decomposto em 11 fatias (BRIEF-2026-08-27-mnemora-studio-epic); F1 em ciclo (BRIEF-002)._

## SPECs

| ID | Título | Status | Data |
|----|--------|--------|------|
| SPEC-002 | Acesso interno e papéis de produção | Approved | 2026-08-28 |

## PLANs

| ID | Cobre | FRs cobertos | Tasks | Status |
|----|-------|--------------|-------|--------|
| PLAN-003 | SPEC-002 | 24/24 FRs + 9 NFRs (autenticação de sessão, autorização deny-by-default, gestão de contas por ADMIN) | 16/16 ✅ | Done |

> **Métrica §1.3 da SPEC-002** (`Fonte de medição: externa`): a fonte é a suíte de conformidade
> `mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts` (TASK-003-011).
> Dono: time de engenharia. Natureza: **conformidade** (verde/vermelha no CI — toda rota
> não-pública prova 401 sem sessão / 403 com papel insuficiente ou não-declarado), **não**
> instrumentação de evento. O boot também recusa a app (`assertDenyByDefault`) se a árvore
> montada divergir do registro.

## Glossário consolidado

| Termo | Definição | Origem |
|-------|-----------|--------|
| Tira mnemônica | Sequência ordenada de quadros que reconstrói uma regra (CONCEITO → AÇÃO → OBJETO → CONDIÇÃO/EXCEÇÃO) | BRIEF-001 |
| Quebra da regra | Decomposição do texto normativo bruto nos cinco blocos, mais a síntese da regra | BRIEF-001 |
| Radar de prova | Classificação por risco de prova: alta, média, detalhe, exceção, pegadinha | BRIEF-001 |
| Associação visual | Imagem/cena/símbolo a serviço da recuperação; reprovada se removê-la não perde função cognitiva | BRIEF-001 |
| Versão aprovada | Checagem jurídica e pedagógica passaram; material liberado para exportação (gate) | BRIEF-001 |
| Fonte normativa | Dispositivo oficial que sustenta a regra (CF, CTN, lei, LC, súmula, ato normativo) | BRIEF-001 |
| Fechamento legislativo | Data até a qual a legislação foi verificada para aquela versão | BRIEF-001 |
| Sessão autenticada | Vínculo entre uma requisição e uma conta interna ativa, estabelecido por login e válido enquanto não expira nem é revogado | SPEC-002 |
| Credencial de acesso | Prova de sessão de vida curta (~15 min) em cookie inacessível a script, conferida a cada requisição | SPEC-002 |
| Token de renovação | Segredo de vida mais longa, persistido de forma revogável, que troca uma credencial de acesso expirada por uma nova sem novo login | SPEC-002 |
| Rotação de token | A cada renovação, o token usado é invalidado e um novo é emitido; apresentar um token já rotacionado é sinal de reuso | SPEC-002 |
| Família de sessão | Conjunto de tokens de renovação encadeados por rotação a partir de um mesmo login; revogada por inteiro em reuso ou logout | SPEC-002 |
| Papel | Atributo da conta: STUDENT (dormente), EDITOR (produção/autoria), ADMIN (gestão de contas + revisão jurídica + aprovação de versão) — enum inalterado | SPEC-002 |
| Deny-by-default | Postura em que uma rota é inacessível a menos que declare explicitamente os papéis que a alcançam; ausência de declaração nega | SPEC-002 |
| Conta desativada | Conta marcada inativa de forma reversível, com marca temporal; não autentica e tem as sessões revogadas | SPEC-002 |
| Provisionamento de conta | Criação de conta interna por um ADMIN ou pelo seed — nunca por auto-registro | SPEC-002 |
| Auditoria de autenticação | Registro dos eventos de login, renovação, logout, bloqueio temporário e decisão de autorização, sem dado sensível | SPEC-002 |

## Decisões irreversíveis

(nenhuma — as 12 DECs de PLAN-003 são todas reversíveis; ver §6 do PLAN para as condições `Reabrir se:`)

## Riscos ativos

| ID | Risco | Mitigação | Origem |
|----|-------|-----------|--------|
| PIL-001 | Teste da tira aprovado sem limiar (Q-11) e cinco das seis métricas da §5.4 sem instrumento (Q-12) — não bloqueiam a SPEC, bloqueiam a conclusão do piloto | decidir antes do beta; retomar via /keelson:brief producao-material | BRIEF-001 |
| RDR-001 | Mapeamento entre as cinco classes do radar de prova (TAP §3.2) e as três prioridades das telas sugeridas não está decidido | resolver como premissa na SPEC da fatia F2 | BRIEF-001 |
| RISK-002-001 | "Revisor jurídico ≠ autor" (A-010) inexequível com operação de 1 pessoa; com o papel de revisão acumulado no ADMIN, com 1 pessoa o gate de "Versão aprovada" de F9 fica só em disciplina operacional | 2 ADMINs distintos no piloto (A-002-017); F9 decide se separa o papel de revisor | SPEC-002 §9 |
| RISK-002-002 | Token de renovação persistido é superfície de dado sensível — vazamento do repositório permitiria continuar sessões | guardar só o necessário, valores não reversíveis onde viável, revogar família em reuso, expiração absoluta curta (7 dias) | SPEC-002 §9 |
| RISK-002-003 | Dependências novas de criptografia/sessão (derivação de senha, geração de token, leitura de cookie) entram na árvore — superfície de cadeia de suprimento | gate de auditoria de dependências sobre o diff de F1 (/keelson:audit); fixar versão e revisar | SPEC-002 §9 |
| TRISK-003-001 | `trust proxy: 1` pode ser o nº errado de proxies no deploy — erra `req.ip` e recoloca o bypass do freio de login; contador do rate-limit é por instância em serverless | verificar no ambiente real; store compartilhado para proteção multi-instância (fora do escopo de F1) | PLAN-003 §8 |
| TRISK-003-002 | Cookie cross-domain (SameSite=None + anti-CSRF) não desenhado; F1 assume mesmo site | verificação de `Origin`/`Host` nas rotas POST de auth agora; token anti-CSRF quando o deploy for cross-domain | PLAN-003 §8 |
| HANDOFF-003 | Verificação de tela — HANDOFF-PLAN-003. Parcialmente exercitada (2026-09-01, Playwright): **V1–V4 OK** (login→`/studio`, mensagem genérica sem enumeração, guard redireciona anônimo, vista protegida renderiza). **V5 FALHOU**: logout de sucesso leva a `/login?sessao=expirada` ("Sua sessão expirou") + tempestade de ~90 `me`/`refresh` 401 — diverge de AC-002-027/FR-002-023 (é o "logout success race" adiado na Wave 7). Servidor OK (logout 204, revogação real). **V6** não exercitado (precisa de 500 seletivo). | **fast-follow em `main`**: developer corrige o V5 (desmontar/pausar `useMeQuery` antes do `resetApiState` no logout de sucesso; ou marcar "logout deliberado") + re-gate; depois reexercitar V5/V6 e fechar o handoff | qa (gate 9 PARCIAL) + Playwright 2026-09-01 |
| RISK-002-003-audit | `/keelson:audit` sobre o diff de F1 (3 deps novas de cripto/sessão: `@node-rs/argon2`, `cookie-parser`) — DoD do PLAN-003 sem ato registrado (E2 do PO). `npm audit --omit=dev --audit-level=high` no backend = 0 vulns (2026-08-31); falta a revisão de cadeia de suprimento | ato do Diretor: rodar `/keelson:audit` antes do merge (o assistente não pode invocá-lo) | PO (Entrega F1) |
| MET-002-001 | Veredito da métrica §1.3 da SPEC-002 pendente — a fonte (`route-authz-matrix` 28/28 verde) prova **conformidade** (deny-by-default aplicado), não o número de negócio da §1.3. O veredito é cobrado no início do próximo ciclo do slug (decisão 4.99) | próximo `/keelson:specify`/`/keelson:brief` em `producao-material` repassa ao Diretor | PLAN-003 §9 / SPEC-002 §1.3 |

## Histórico recente

- 2026-08-28: Wave 1 do PLAN-003 fechada (TASK-003-001/002/005 Done) — gate 8 reprovou e convergiu em 1 retry (fail-open no COOKIE_SECURE, redação do pino, contrato HMAC); errata propagada ao PLAN e TASKs; 2 lições registradas (pendentes de merge)
- 2026-08-28: Wave 2 do PLAN-003 fechada (TASK-003-016 harness de integração, -003 libs cripto/audit, -004 rotação pura) — gates 1–8 aprovados após 1 retry de convergência (precedência de ramos falsificável, prova de params de env, guarda fail-closed do banco de teste); 2 lições registradas (pendentes de merge)
- 2026-08-29: furo no plano em TASK-003-006 — `refresh`/`logout` emitem eventos de auditoria mas suas assinaturas não recebiam `ip`, obrigatório em `AuthAuditEvent` (audit.ts selado na Wave 2) por NFR-002-005 — destino: `refresh`/`logout` passam a receber `ctx: { ip; userAgent? }` (aditivo; rota passa `req.ip`); PLAN + TASK-003-006/009 emendados
- 2026-08-29: DEC-003-003 emendada (decisão degrau 1 do Tech Lead, veto na Entrega) — cláusula `replay-grace` idempotente era infeasible sob DEC-003-002 (só hashes persistidos); replay-grace passa a tratar como rotate (nova ponta, sem revogação/token.reuse na graça); cliente serializa o refresh (TASK-003-013)
- 2026-08-29: Wave 3 do PLAN-003 fechada (TASK-003-006 auth.service, -008 freio de login, -012 seed do 1º ADMIN) — gates 1–10 aprovados após 1 retry de convergência + 1 furo no plano (ctx de origem); 3 lições registradas (pendentes de merge)
- 2026-08-29: Wave 4 do PLAN-003 fechada (TASK-003-007 middlewares authenticate/authorize + ROUTE_ROLES) — gate 8 APROVADO; gates 1–7 REPROVARAM 1º passe (4 achados críticos de authz: registro populado em request, requireAuth só checava existência, chave sem método, curinga vaza) → retry `ead57a2` fechou os 4; re-review reprovou só gate 1 por regressão de prova (caso de teste perdido na reescrita) → resolvido `b106b84` test-only (teto de convergência 4.88 → decisão autônoma, ao veto do Diretor). DEC-003-005 EMENDA Wave 4 (chave `"<MÉTODO> <caminho>"`, declaração em montagem, `sealRouteRoles`, `requireAuth` piso de autz); resíduo `:param` de irmã estática → critério em TASK-003-011; 4 lições candidatas (pendentes de rota/merge)
- 2026-08-29: sync Jira reconciliado (gancho closure — conector Atlassian de volta após o bloqueio AWS WAF "Human Verification" das Waves 2–3; prova `atlassianUserInfo` retornou JSON) — sub-task de TASK-003-016 criada (KAN-26 sob KAN-8); marco "TASK concluída" comentado em 10 sub-tasks (KAN-11/12/13/14/15/16/17/18/22/26); "Trabalho iniciado (Story)" comentado em KAN-8/KAN-9/KAN-10; `transition: comment` → nenhum card movido, nenhuma FEAT fechada (KAN-8 0/5+harness, KAN-9 1/3, KAN-10 2/3)
- 2026-08-30: Wave 5 do PLAN-003 fechada (TASK-003-009 rotas de auth + cookies + `getSessionUser`; TASK-003-010 módulo `users/`) — gate 10 APROVADO, gate 9 APROVADO (FEAT-002-003 completa → Implementadas); gate 8 REPROVOU (race condition na guarda do último ADMIN + CSRF nas 3 mutações de `users/`) → retry `27ef0dd` fechou; re-review REPROVOU só o gate 1 (2ª vez → teto 4.88) por ausência de prova (fixture de corrida fora da fronteira + par de precedência de `disableUser` sem caso) → resolvido `89c67e2` test-only (decisão autônoma, veto do Diretor). Furos no plano: `getSessionUser` nasce na TASK-009 (`req.auth` sem `name`/`email`); falha de serialização é `DriverAdapterError`, não P2034 (Prisma 7 + adapter-pg). EMENDAS: COMP-003-008/013/014/015, DEC-003-004. 6 lições candidatas (2 projeto registradas; processo → agile-coach). Incidente de higiene: gates poluíram a árvore compartilhada 2× (npm install + `@babel/core`; npm ci em worktree junctionada) → restaurado com `npm ci`.
- 2026-08-30: Wave 6 do PLAN-003 fechada (TASK-003-011 montagem deny-by-default + suíte `route-authz-matrix`; TASK-003-013 store do frontend com re-auth + `proxy.ts`) — gate 10 n/a, gate 1–7 REPROVOU 1º passe (CR1 `assertDenyByDefault` sem wiring; CR2 matcher catch-all; CR3 ramo `://`) → retry `c5188cf`/`e75a11f` fechou, re-review APROVADO; gate 8 REPROVOU 1º passe (S1 alta: re-auth ressuscita sessão no 401 de `/auth/login`; +S4 allowlist cega ao método) → retry fechou os 4, mas ABRIU regressão alta (`/auth/logout` no espelho → logout no-op com access expirado) → resolvida `6281039` (teto 4.88 → decisão autônoma, veto do Diretor). EMENDAS: DEC-003-005 (allowlist método-aware — lição da Wave 4 aplicada), COMP-003-022 (matcher enumerado). Métrica §1.3: fonte = `route-authz-matrix`, registrada no INDEX. 5 lições candidatas (3 projeto + node-22/next-16; processo → agile-coach). Incidentes de higiene: gate concorrente escreveu `tests/zz-probe.test.ts` na árvore durante o re-review (reincidência 4); worktree órfão com `.env` real podado.
- 2026-09-01: PLAN-003 **mergeado** (backend `25cdafd` · frontend `834f117`, PR #1); Status → **Done**; Stories KAN-8/9/10 e sub-tasks KAN-11..26 → Concluído no Jira (KAN-7 Épico segue aberto — multi-fatia). Caminhada de tela do HANDOFF-PLAN-003 exercitada (Playwright, app local): **V1–V4 OK**, **V5 FALHOU** (logout de sucesso → `/login?sessao=expirada` + laço de `me`/`refresh` 401 — "logout success race" da Wave 7, agora com evidência ao vivo), V6 não exercitado. Handoff **permanece Pendente**; fast-follow em `main` (developer + re-gate). Ambiente de dev: ADMIN `admin@mnemonicos.local` semeado, 4 usuários-fixture removidos do DB de dev, `SEED_ADMIN_*` no `.env` local (gitignored).
- 2026-08-31: `/keelson:integrate` de PLAN-003 — DoD §9 validada (14 itens; `npm audit` backend 0 vulns; `gates.screenVerify` parcial via HANDOFF-003 aceito). Suíte completa verde (be unit 165/165 · be integração 133/133 · fe 86/86 · lint/typecheck/build). **Convergência de fecho: CONVERGIU** (code-reviewer — 0 gaps `ausente`/`parcial`/`contradiz`; 24 FR + 9 NFR + 29 AC provados; 12 DEC + EMENDAS refletidas; métrica §1.3 verde; paridade de tipos por leitura cross-repo; sem segredo em log/resposta). `quality.mutation`/`quality.e2e` = não configurados (opt-in). **PR não aberto** — `gh` ausente / sem `GH_TOKEN` no ambiente; descrições dos 2 PRs prontas (backend + frontend, base `main`, head `feat/producao-material-mnemora-studio`). Aberto pendente: 2 decisões não-bloqueantes declaradas (comentário de `api.ts` × teste de divergência cross-repo; superfície declarada sem consumidor em F1). 1 lição de projeto registrada.
- 2026-08-31: Wave 7 do PLAN-003 fechada (TASK-003-014 tela de login; TASK-003-015 shell da área interna) — PLAN-003 **16/16**, FEAT-002-001 e FEAT-002-002 → Implementadas. gate 10 n/a. gate 1–7 REPROVOU 1º passe (`config.matcher` via `.flatMap()` derruba `next build` — Next lê `config` por AST estático; `roleSatisfies('STUDENT',*)` sem caso; `INTERNAL_HOME` literal duplicado; costura `resetApiState()`×`missingSession` sem oráculo) → retry `f6cc4ed` fechou 5 de 6; gate 8 REPROVOU 1º passe (mesma raiz do `config.matcher` + `<form>` sem `method=`) → fechou no mesmo retry. A4 (AC-002-027) não fechou no retry (oráculo trocado por função pura; bug real verde na suíte: `resetApiState()` no `finally` do `logout` desmontava `LogoutControl` e matava a mensagem de falha) → teto 4.88 batido → **rodada dirigida A4 `e6d0c75`** autorizada pelo Tech Lead (veto do Diretor na Entrega): `logout.onQueryStarted` reseta o cache só após sucesso (EMENDA COMP-003-021 Wave 7); re-review APROVADO (3 mutantes mortos, oráculo montado contra a `api` real). gate 9 **pendente_handoff** para as duas FEATs (tela bloqueada — causa: credencial). EMENDAS: COMP-003-021 Wave 7, COMP-003-022 (matcher literal), TASK-003-014/015 (critérios de retry). 3 lições projeto em `lessons.md` + `next-16.md` §6.3/§11; 3 lições processo → agile-coach (Etapa 4.5). Incidentes de higiene: gates paralelos escreveram mutantes/sonda na árvore compartilhada + alteração estagiada invertendo oráculo A4 (restaurado pelo security-engineer; árvore confirmada pristina em `e6d0c75`).
