# Produção de Material

> Arquivo gerado automaticamente. Não edite manualmente.
> Para alterar conteúdo, use /keelson:specify, /keelson:plan, /keelson:tasks ou /keelson:implement.

**Slug**: producao-material
**Última atualização**: 2026-10-03 (PLAN-051/KAN-219 criado e Approved — rota de reativar + coluna de Ações em ícone; SPEC-050 emenda a SPEC-048; PLAN-049/KAN-179 mergeado em `main` (PR #27, `6adbdf8`) — gate 9 PARCIAL em HANDOFF-PLAN-049, KAN-179 Concluído; PLAN-046/KAN-178 mergeado em `main` — PR #26; gate 9 com login pendente em HANDOFF-PLAN-046; SPEC-044 Approved, emenda SPEC-040 v0.5; PLAN-041/KAN-180 em implementação — 4/4 ✅ TASKs)
`main` e fechadas no Jira — PLAN-036/KAN-77: gate 9 PARCIAL, handoff pendente. PLAN-035/F10
KAN-165: 8/8 TASKs Done, FEAT-034-001/002 VERIFICADAS, épico fechado; pendência de deploy
em DEPLOY-035-001)
**Mapa do território**: MAP.md

## Resumo

Fábrica interna de produção do material mnemônico: o acervo estruturado (10 camadas do método,
tira como sequência de quadros) entra, o PDF diagramado sai — com versão, data de fechamento de
legislação e checklist de revisão jurídica. O estudante não é usuário deste software; o que ele
compra é o PDF. A régua de valor é tempo de produção por página, instrumentado por etapa.

## Capacidades

### Em desenvolvimento
- Reativação de conta desativada e coluna de Ações da Tela Usuários em controles compactos (Ativar/Desativar), com log de auditoria pontual da reativação (SPEC-050/PLAN-051, KAN-219, primeira fatia do épico v2 de gestão de usuários KAN-218) — PLAN Approved, implementação ainda não iniciada.

### Implementadas
- Redefinir senha com confirmação (SPEC-048/FEAT-048-004, PLAN-049, ✅ 2026-10-01) — `ResetPasswordDialog` com nova senha (política única `src/lib/password-policy.ts`), trava de duplo envio provada no canal Enter, `redactSecret` nos 2 canais, aviso "Senha redefinida." (região limpa ao começar cada operação), redefinir a própria senha encerra a sessão. Gate 9 PARCIAL: HANDOFF-PLAN-049. Mergeado em `main` (PR #27, `6adbdf8`).
- Criar conta interna pela tela (SPEC-048/FEAT-048-002, PLAN-049, ✅ 2026-10-01) — painel inline com validação local, papel EDITOR pré-selecionado e ajuda do ADMIN, senha via `PasswordField` (prop `error` aditiva) nunca retida (`track:false`, limpa em sucesso e falha, `redactSecret` nos 3 canais de mensagem), foco nomeado em cada desfecho, conta nova na 1ª linha sem recarregar. Gate 9 em HANDOFF-PLAN-049. Mergeado em `main` (PR #27, `6adbdf8`).
- Desativar conta com confirmação (SPEC-048/FEAT-048-003, PLAN-049, ✅ 2026-10-01) — `AccountConfirmDialog` novo (alertdialog com véu, foco contido, Esc, erro visível), recusas do servidor (último ADMIN, corrida, 404) na confirmação, desativar a própria conta encerra a sessão (`endOwnSession`), lista atualiza pela invalidação mesmo na falha. 3 pendências mecânicas roteadas à TASK-049-006. Gate 9 em HANDOFF-PLAN-049. Mergeado em `main` (PR #27, `6adbdf8`).
- Acesso e lista de contas (SPEC-048/FEAT-048-001, PLAN-049, ✅ 2026-09-30) — rota `/users` só para ADMIN (mapa de papel por rota na fonte única, shell deriva do `usePathname()`), item "Usuários" no menu só para ADMIN, camada de dados com senha fora do store (`initiate(..., {track:false})`, `redactSecret`, `toUserMessage`), lista paginada com busca (debounce 300 ms, foco preservado ao paginar). Gate 9 em HANDOFF-PLAN-049. Mergeado em `main` (PR #27, `6adbdf8`).
- Sidebar de navegação da área interna (SPEC-044/**PLAN-046**, BRIEF-044, Jira KAN-178 — sub-tasks KAN-187..191, ✅ 2026-09-30) — menu lateral Painel/Conteúdos/Biblioteca visual no estado pronto da casca (lista declarada `internal-nav.ts`), fixo a partir de `xl` (1280px) e recolhível abaixo (disclosure no fluxo, fecha no `click` fora); seção atual com `aria-current`; `SiteLogo` por sessão ativa + papel (logout em outra aba → Home pública); "Voltar ao conteúdo" na Tira; container sai do `<main>` raiz para `PageContainer` (BRIEF-037 absorvido). 5/5 TASKs Done, 3 waves, 6 retries (2 pela escada degrau 1). Gate 9 **PARCIAL / pendente_handoff** (HANDOFF-PLAN-046, `permissao_ambiente`). Alinhamento de header/footer à área interna: BRIEF-047 (avulso, aberto).
- Sessão reconhecida abre a área logada (SPEC-040/**PLAN-041**, BRIEF-040, Jira KAN-180 — sub-tasks KAN-181..184, ✅ 2026-09-30) — quem tem sessão reconhecida (aceita agora ou renovável sem nova senha) e papel EDITOR/ADMIN abre a página inicial e chega direto à página inicial da área interna, sem ver a Home pública; anônimo, falha da conferência, papel sem acesso, navegador sem script ou estouro do teto de 3 s ficam na Home pública, sem ir ao login e sem aviso; ida tardia à área interna quando a conferência conclui depois do teto. Login, logout e guarda das rotas internas inalterados. 4/4 TASKs Done, 4 waves sequenciais — decisão no navegador na própria home (`proxy.ts` intocado, DEC-041-001), pista local de sessão, estado neutro por script inline da página com teto único de 3 s, `homeSessionCheck` com renovação silenciosa extraída do reauth. Gate 9 **PARCIAL**: parte anônima VERIFICADA em Chromium real (sem aviso de hidratação, AC-040-013 9(a), variantes forjada/pista velha sem login, teto de 3 s, AC-040-014 (ii) mediana 40 ms); ACs com sessão pendentes por credencial dos realms — `HANDOFF-PLAN-041.md`. Ressalva aceita: 1ª abertura de `/` após o deploy mostra a home pública a quem já tinha sessão (RISK-040-006).
- Controle único de sessão (Entrar/Sair/neutro) e alternador de tema claro/escuro no header
  do app (SPEC-036/**PLAN-036**, Jira Story KAN-77, ✅ 2026-09-30) — presentes em toda
  rota (pública e interna, inclusive produção), consolidando o logout hoje próprio da área
  interna num único ponto de acionamento; paleta unificada roxo/rosa/mauve herdada de
  `/login` (SPEC-030) estendida ao app inteiro, com o mesmo piso de contraste AA e sem a
  ilustração decorativa; persistência de tema por dispositivo/navegador, independente de
  conta. 6/6 TASKs Done, 3 waves — 5 rodadas de retry reais (cobertura de mutante/DEC em
  TASK-036-002, cadeia de fallback sem teste em TASK-036-004, mutante enfraquecido por
  migração de topologia de teste em TASK-036-005, mock duplicado em TASK-036-006) + 1
  achado bloqueante de acessibilidade (cursor/hover ausente, depois `brightness`
  imperceptível no tema escuro) corrigido em 2 rodadas por erro de escopo do Tech Lead no
  1º retry (declarado no ledger). Gate 9 (`qa`) **PARCIAL**: 11/19 ACs VERIFICADOS por
  execução real (Playwright, sem sessão); 8 ACs pendentes de login real —
  `HANDOFF-PLAN-036.md` (backend indisponível neste ambiente, Docker Desktop fora do ar).
  4 itens de dívida de design não-bloqueante (layout shift, posição de erro, altura dos
  controles, `next/link`). PO da SPEC: ACEITA_COM_RESSALVAS — remoção do "Sair" duplicado
  da área interna **confirmada pelo Diretor na Entrega**. **Mergeado em `main`**
  (`mnemonicos-frontend`, PR #18, `e254bd1`, 2026-09-30) e KAN-77 fechado no Jira
  (Concluído) — sem épico-pai (projeção compacta), sem passo 2/3 do trilho a aplicar.
  Handoff de verificação de tela (8 ACs) segue aberto até rodar com backend saudável.
  (Numeração original desta demanda era SPEC-034/PLAN-035/TASK-035-00X — renumerada para
  036 em 2026-09-30 por colisão real com outra demanda paralela deste mesmo slug, ver
  Histórico recente.)
- Painel estratégico (SPEC-034/FEAT-034-002, PLAN-035, ✅ 2026-09-30) — `GET /strategic-panel` (EDITOR/ADMIN, allowlist, 7 statements fixos, O(N+E); p95 medido 176 ms em 200×50) e a página inicial da área interna `/studio`: tempo total/por página/por etapa por Conteúdo, agregados por Módulo e fábrica com cobertura, conclusão por Módulo, correções após revisão por etapa (fábrica e por Conteúdo), backlog ativos − concluídos com prioridade, etapa mais avançada, idade e marcador "aprovada, alterada depois". Gate 9 VERIFICADO em tela real, já sobre a nova identidade visual da main do frontend. **Mergeado em `main`** (backend PR #11 `39d033d`, frontend PR #19 `f975939`, 2026-09-30) — épico KAN-165 fechado no Jira (Concluído), filhos KAN-166/167 consultados por JQL (2/2 em Concluído). Pendência de deploy em DEPLOY-035-001.
- Registro de páginas na Exportação (SPEC-034/FEAT-034-001, PLAN-035, ✅ 2026-09-30) — `PublicationEvent.pageCount` (migração aditiva `20260930062551_add_publication_event_page_count`, aplicada em dev/teste; produção pelo deploy), contagem fail-safe na composição (falha → `null`, Exportação segue), leitura no Painel pela 1ª Exportação Tira após o 1º fechamento de Versão. Gate 9 VERIFICADO (HTTP + banco reais).
- Aprovação da Versão vigente com checklist de qualidade e segregação de funções (SPEC-032/FEAT-032-001, PLAN-033, ✅ 2026-09-29) — `POST /contents/:id/versions/:number/approve` (ADMIN, 2 confirmações, segregação de funções por 3 identidades produtoras, fonte normativa obrigatória, guarda de edição pós-fechamento ordenada por `sequence`, duplo travamento anti-corrida); leitura do estado de aprovação e de `validApprovalForExport` no histórico; painel na tela com cada linha do histórico mostrando a própria aprovação. Gate 9 VERIFICADO (tela real + integração). Resolve RISK-002-001/RISK-028-004. Pendências ao Diretor na Entrega: Tira no escopo do gate (E-1) e linha de validade para EDITOR (FR-032-007(b)).
- Carimbo de Versão aprovada no PDF exportado (SPEC-032/FEAT-032-002, ✅ 2026-09-29) — a 1ª linha do cabeçalho de toda página troca "RASCUNHO" por "Conteúdo normativo e Tira mnemônica — Versão N aprovada" só quando a Versão vigente está aprovada e sem alteração posterior (conteúdo ou Tira); gate 9 VERIFICADO por execução real (6/6 ACs, pdftotext nas 2 Variantes).
- Provisionamento de contas internas por ADMIN + seed do 1º ADMIN (SPEC-002/FEAT-002-003, PLAN-003, ✅ 2026-08-30) — módulo `users/` (criar/listar/desativar/resetar senha) + seed; gate 9 APROVADO. Montagem das rotas em `apiRoutes` fica com TASK-003-011 (Wave 6).
- Autenticação de sessão da equipe interna (SPEC-002/FEAT-002-001, PLAN-003, ✅ 2026-08-31) — login com três estados observáveis + mensagem genérica pt-BR + sessão expirada; rotação de família, freio de login, cookies `httpOnly`. Gate 9 **pendente_handoff** (trânsito real à área interna no sucesso — causa: credencial; seed em HANDOFF-PLAN-003.md).
- Autorização por papel deny-by-default no servidor (SPEC-002/FEAT-002-002, PLAN-003, ✅ 2026-08-31) — `assertDenyByDefault` no boot + suíte `route-authz-matrix` (28/28) + store do frontend com re-auth + shell da área interna (`InternalShell` com 3 estados, logout com 3 estados, `config.matcher` derivado do grupo `(interno)`). Gate 9 **pendente_handoff** (caminhada e2e de AC-002-013/AC-002-027 — causa: credencial).
- Conteúdo bruto e Quebra da regra (SPEC-005 → **PLAN-006**, F2 do épico MNEMORA STUDIO, ✅ 2026-09-05) — models `RawContent` + `RuleBreakdown` 1:1, enums `ProofRadarClass` (5)/`NormativeSourceType` (6), módulo backend `contents/` (7 rotas sob a barreira EDITOR/ADMIN de F1 + `verifyOrigin`, tripwire 12→19), soft-delete (`deletedAt`), fonte normativa embutida, carimbo de última alteração com autoria imutável; saneamento do `api.ts` (remoção de `listMnemonics`/`listDueFlashcards`); 4 telas em `(interno)/content` (listagem, formulário, Quebra da regra) com tokens de tema `--link`/`--danger`; seed → Obrigação Tributária; migração Prisma aditiva (autorizada pelo Diretor). 15 COMPs, 9 DECs (todas reversíveis), 4 TRISKs (todos resolvidos). Gate 9 **VERIFICADO** (AC-005-011/019/033, execução real com browser + Postgres). Fora do escopo de PLAN-006, corrigidos junto por briefs avulsos autorizados: CSRF em `POST /auth/refresh` (BRIEF-007 — investigação mostrou que a proteção já existia desde F1, gap era só na rede de prova) e contraste AA residual em 2 arquivos de F1 (BRIEF-008).
- Instrumentação de etapas da fábrica (SPEC-009/**PLAN-010**, F3 do épico MNEMORA STUDIO, ✅ 2026-09-06) — mecanismo append-only de evento de etapa de produção (`ProductionStageEvent`, 2 enums, migração aditiva `prisma/migrations/20260906143159_add_production_stage_event/migration.sql` — mergeada em `main` (backend, PR #3, `6541d49`, 2026-09-06), aplicada em dev/teste; aplicação em produção **automatizada em 2026-09-06** por BRIEF-010 — o `vercel-build` do backend roda `prisma migrate deploy` a cada deploy (`2bb9dc0`), então esta migração entra no próximo deploy junto com as 4 anteriores; RISK-006-009 segue aberto no que importa: sem CI, o DDL alcança produção sem teste automatizado antes, e `migrate deploy` é forward-only: 2 `CREATE TYPE`, 1 `CREATE TABLE`, 1 `CREATE INDEX`, 2 `ADD CONSTRAINT`, sem `DROP`/`ALTER` destrutivo) para Conteúdo bruto e Quebra da regra: `production-events.service.ts` (regra de decisão pura + emissão transacional + leitura ordenada), integração em `contents.service.ts` (`createRawContent`/`updateRawContent`/`saveRuleBreakdown` dentro de `$transaction`, fail-secure), sem UI de consumo — infraestrutura de captura para a métrica futura de tempo por página (F10). 6 COMPs, 7 DECs (todas reversíveis), 7 TRISKs (2 resolvidos com medição real). Gate 9 **consolidado (DoD, Etapa 4)** — SPEC-009 sem FEATs. 3 waves, 1 retry (dedup de fixture), 0 vulnerabilidade. 231/231 integração + 217/217 unit.
- Suporte a PWA no mnemonicos-frontend (SPEC-013/**PLAN-013**, ✅ 2026-09-07) — instalabilidade padrão de navegador (manifesto, ícones 192/512, service worker artesanal restrito a assets estáticos do app-shell, nunca navegação/cache de API, kill-switch por autodesregistro) para os papéis internos EDITOR/ADMIN; sem caso de uso de produto identificado (A-013-001, premissa aberta). Demanda avulsa fora do épico MNEMORA STUDIO — brief BRIEF-013, Jira Story KAN-64 (projeção compacta, sem Epic). 4 COMPs, 2 DECs (ambas reversíveis), 3 TRISKs. Execução isolada em worktree próprio (`C:/kwt/pwa`, branch `feat/producao-material-pwa-support`, não pushada — merge é decisão do Diretor, RISK-013-005 ordem com PLAN-012/F4). 6/6 TASKs Done, 6 waves — 2 retries reais (Wave 2 e 3), 1 rodada dirigida por teto de retry (Wave 3), 1 achado de segurança real fechado (Wave 3 — SW sem checagem de origem). Gate 9 **pendente_handoff** parcial: AC-013-007 e confirmação de SW ativo VERIFICADOS; AC-013-001/002 (instalação nativa) e o ciclo login/logout completo (AC-013-005/011) pendentes — ver `HANDOFF-PLAN-013.md`. PO da SPEC: ESCALAR (E-01, não-bloqueante, origem HTTPS — vai à Entrega). 4 lições novas/estendidas em `lessons.md`.
- Tira mnemônica como sequência de quadros (SPEC-011/**PLAN-012**, F4 do épico MNEMORA STUDIO, implementado 2026-09-07) — models `MnemonicStrip` (1:1 `RuleBreakdown`) + `MnemonicFrame` (N:1, posição indexada, `@@unique([stripId,position])`), geração automática de Quadros a partir dos Blocos não-vazios da Quebra na ordem canônica, CRUD completo + reordenação atômica (reindexação em 2 fases), valor aditivo `TIRA_MNEMONICA` no `ProductionStageType`, fronteira abertura/conclusão/retrabalho na 1ª mutação humana (correção do PO), alcance por autoria herdado de F2 (`assertRawContentReachable` exportado), tela `(interno)/content/[id]/tira` (Server Component + client component com CRUD/reordenação/3-estados/diálogo de confirmação com gestão de foco), link condicional de entrada a partir da tela da Quebra da regra. Furo no plano corrigido em voo: **DEC-012-011 supersede DEC-012-009** — geração migrou de `GET` para `POST /contents/:id/strip` (achado de CSRF do security-engineer, Wave 5; cookie `sameSite: 'lax'` + regra repo-wide sem `verifyOrigin` em GET). 14 COMPs, 11 DECs (todas reversíveis, incluindo a nova), 5 TRISKs. PO da SPEC: ESCALAR (E-01, não-bloqueante, vai à Entrega). 13/13 TASKs Done, 7 waves — a Wave 4/5/6 tiveram as convergências mais longas do slug até aqui (4 rodadas cada em Wave 5 e 6; 2 escalações genuínas ao Diretor — CSRF e um achado de acessibilidade não-óbvio; 2 decisões de degrau 1 do Tech Lead sem reescalar, ambas correções mecânicas já simuladas pelo próprio revisor). Gate 9 **n/a** (SPEC-011 sem FEATs — consolidação pendente na Etapa 4). Lições novas/estendidas em `lessons.md`: 2 reincidências de "guarda reusada exige prova própria" (agora estendida a métodos de LEITURA); reincidência do universo do teste estrutural (vocabulário incompleto); reúso de padrão canônico por CÓPIA DE MARKUP sem o contrato completo (efeito de foco) é regressão, não reúso (em-observação). Pendência para a Entrega: `mnemonic-strip-board.tsx` pode ter a mesma forma "data em cache + 404" que motivou uma correção em `rule-breakdown-form.tsx` nesta wave — não investigado a fundo, sinal do code-reviewer.
- Toggle de mostrar/ocultar senha nos campos de senha (SPEC-016/**PLAN-018**, done (sugerido) 2026-09-07) — componente `PasswordField` reutilizável (SVG inline, sem dependência nova, toggle por `useState` local, atributos anti-canal fixos, foco visível via `has-[input:focus-visible]`, alvo de toque 28x28 WCAG 2.2 SC 2.5.8), aplicado ao campo de senha do `LoginForm` (único hoje), sem alterar o fluxo de autenticação de SPEC-002 (NFR-016-003 provado). 2 COMPs, 5 DECs (todas reversíveis), 2 TRISKs + 1 dívida declarada (detector de AC-016-006 não cobre forma indireta via variável, pede AST/regra ESLint). Demanda avulsa fora do épico MNEMORA STUDIO — brief BRIEF-016, Jira KAN-72 (Em andamento, subtasks KAN-79/KAN-80 concluídas). 2/2 TASKs Done, 2 waves — 3 retries reais no total (2 na Wave 1: oráculo morto + atributos anti-canal sem prova, foco visível ausente + alvo de toque pequeno; 1 na Wave 2: prova de AC-016-006 não-executável). Gate 9 n/a (ação síncrona local sem I/O, decisão 4.67) — todos os ACs fecham por gate 1 (teste automatizado, 24 suítes/251 testes, 0 regressão). Sem verificação de tela pendente. PO da SPEC: ESCALAR (E-01, não-bloqueante — KAN-72 fecha só com o LoginForm ou nasce card de follow-up para as telas de troca/reset de senha, cuja API já existe — vai à Entrega).
- Rewrite same-origin do cookie de sessão para produção cross-site (SPEC-002/**PLAN-021**, re-cobertura técnica de FEAT-002-001, done (sugerido) 2026-09-08) — `mnemonicos-frontend` e `mnemonicos-backend` são dois sites Vercel distintos; o cookie `sameSite: 'lax'` de DEC-003-004/PLAN-003 nunca persistia em produção sob essa topologia (confirmado por execução real com Playwright, KAN-75). `rewrites()` em `next.config.ts` (`/api/v1/:path*` → backend real, `BACKEND_API_URL` server-only) + `resolveApiBaseUrl()` same-origin em `store/api.ts`, sem mudar flags do cookie nem `verifyOrigin`/`CORS_ORIGINS` do backend (DEC-021-001, reabre DEC-003-004 pela condição que ela mesma previu); remoção de `env.apiUrl`/`NEXT_PUBLIC_API_URL` (configuração morta). 3 COMPs, 3 DECs (todas reversíveis), 3 TRISKs (todos resolvidos, ver Riscos ativos). Demanda avulsa fora do épico MNEMORA STUDIO — Jira Story KAN-8, subtasks KAN-83/KAN-84 (sincronização degradou para comentário nas duas — mapa `jira.KAN.md` §Etapas/Colunas ainda não promovido, `transition: auto` sem status-alvo). 2/2 TASKs Done, 2 waves — 2 retries reais (Wave 1: uso de `as` apagando `undefined` inferido em teste; Wave 2: 2 achados de mutation testing — mutantes sobreviviam por placeholder de teste coincidir com origem default do jsdom e por consumidor real nunca ter oráculo de URL absoluta — + 1 achado de comentário afirmando paridade não provada). 34 suites/363 testes frontend + 26/243 backend, 0 regressão, 0 vulnerabilidade (gate 8 aprovado nas 2 waves). Gate 9 **VERIFICADO em produção 2026-09-08** (item de DoD do PLAN, verificação manual pós-deploy) — após o Diretor configurar `BACKEND_API_URL` na Vercel e mergear/deployar, login real em `https://mnemonicos-frontend.vercel.app` confirmou os 2 `Set-Cookie` distintos sob o domínio do frontend, sessão reconhecida (`/api/v1/auth/me` → 200, redirect para `/studio`) e `verifyOrigin` recusando origem forjada (403) através do rewrite. TRISK-021-001/002/003 resolvidos (ver Riscos ativos). Anomalia declarada: PLAN-021 nunca teve o Status promovido a Approved antes de `/keelson:tasks`/`/keelson:implement` prosseguirem (front-matter seguia "Draft") — sinal ao Diretor, não corrigido silenciosamente. 1 lição existente estendida em `lessons.md` (5ª reincidência — comentário suavizado também precisa de mutante por lado).
- Página 404 personalizada (SPEC-019/**PLAN-020**, done (sugerido) 2026-09-07) — `not-found.tsx` nativo do App Router (Server Component `NotFoundPage`), `metadata.title` próprio (não herda o título da home), herda `SiteHeader`/`Providers`/footer do root layout automaticamente, tokens `@theme`/`text-link`/`text-muted`, `<Link href="/">` de volta à home pública. Precedência guard×404 delegada inteiramente ao `proxy.ts` existente (SPEC-002), sem lógica nova — rota interna sem sessão continua indo para `/login?next=<path>` (decisão do PO, E-019-01); rota interna com sessão prova a 404 personalizada ponta-a-ponta via HTTP real. 1 COMP, 4 DECs (todas reversíveis), 2 TRISKs. Demanda avulsa fora do épico MNEMORA STUDIO — brief BRIEF-019, Jira Story KAN-76 (subtasks KAN-81/KAN-82 concluídas). 2/2 TASKs Done, 1 wave — TASK-020-001: 1 retry (achado do product-designer: sem `metadata.title`, título herdava o da home). TASK-020-002: 4 rodadas de convergência (acima do teto padrão de 1 retry, todas mecânicas — asserção de corpo não-discriminante, âncora de regex de stream, bind loopback do servidor de teste, branch defasada de `origin/main` sincronizada por merge fast-forward); nenhuma decisão de arquitetura/produto pendente, degrau 1 da escada de reação aplicado pelo Tech Lead na última rodada. Gate 9 consolidado (DoD, Etapa 4) — SPEC-019 sem FEATs, todos os ACs fecham por gate 1 (teste automatizado com servidor `next start` real: HTTP 404 + `<title>` discriminante). 4 lições novas em `lessons.md` (discriminação de rota por `<title>`; bind loopback de servidor de teste; parser de token sobre buffer de stream; metadata.title em arquivo de convenção do App Router).
- Biblioteca visual reutilizável (SPEC-022/**PLAN-023**, F5 do épico MNEMORA STUDIO, ✅ 2026-09-14, PR #6 backend `e316ab6`/PR #12 frontend `677b836` mergeados em `main`) — acervo de associações visuais (upload raster validado por assinatura de bytes, categoria, função cognitiva) vinculável (N:1, no máximo 1 por Quadro) a Quadros da Tira mnemônica (F4); binário como coluna `Bytes` no Postgres (não filesystem — incompatível com a topologia serverless do backend, corrigido ainda no PLAN); CRUD completo com guarda de autoria, trava de remoção com corrida TOCTOU real fechada (`SELECT...FOR UPDATE`), listagem/busca/sugestão de categoria, tela `(interno)/visual-library`, entrega autenticada do binário; alcance por autoria herdado de F4 (leitura comum a EDITOR/ADMIN, sem restrição adicional); métrica de "uploads evitados" instrumentada (`VisualAssociationLinkEvent`). 17 COMPs, 12 DECs (todas reversíveis), 7 TRISKs. 17/17 TASKs Done, 6 waves — a convergência mais longa e mais séria do slug até aqui: **2 vulnerabilidades/defeitos reais encontrados e fechados**, ambos com prova por mutação executada pelos próprios revisores — (1) corrida TOCTOU real na trava de remoção (Wave 4, a trava por `deleteMany` condicional da Wave 1 não fechava a corrida sob READ COMMITTED; fechada travando a linha pai) e (2) filtro de categoria interpretando metacaractere LIKE do cliente como padrão (Wave 5, `?category=%` devolvia o acervo inteiro; parametrizado, sem SQL injection, mas violava o contrato do filtro — fechado com escape). Múltiplas reincidências da lição DRY dentro do próprio PLAN (3ª manifestação na Wave 5) e da lição de "guarda reusada exige prova própria" (Wave 4). Tech Lead aplicou degrau 1 da escada repetidamente (>10 vezes ao longo do PLAN) para achados mecânicos com correção já prescrita pelo próprio revisor, sem ambiguidade de produto — nenhuma escalação genuína ao Diretor foi necessária durante a implementação. As 3 FEATs (Gestão do acervo, Navegação e busca, Vínculo a Quadros) VERIFICADAS por execução real (HTTP + browser via Playwright). 2 migrações aplicadas ao DEV com autorização do Diretor (schema inicial + nenhuma migração de índice, mesmo com Seq Scan confirmado em `visual_associations` — decisão explicitamente deixada para o Diretor, sem volume que justifique hoje). 15+ lições novas/estendidas em `lessons.md` e `docs/_meta/learning-log.md` (LRN-020 a LRN-024, PROPOSTA_PLUGIN).

- Versionamento editorial e fechamento legislativo (SPEC-028/**PLAN-029**, F8 do épico MNEMORA STUDIO, ✅ 2026-09-26) — fechamento explícito de Versão editorial (autor-ou-ADMIN) do Conteúdo bruto, recortado por CAMPO (texto normativo, radar, fonte normativa, blocos da Quebra da regra — Pegadinha elaborada fora, mesmo residindo na mesma linha de dado), append-only via `ContentVersion` com **snapshot JSON** (`contentSnapshot`, não hash — DEC-029-003, irreversível: capturar o texto agora preserva a opção de reprodução histórica futura, hash sozinho perderia o texto para sempre se o Conteúdo mudasse depois do fechamento), lock de linha do `RawContent` pai (`SELECT...FOR UPDATE`) fechando corrida real de numeração (provado com `Promise.all`), histórico exposto para leitura (`GET /contents/:id/versions`), e carimbo de Versão/Data de fechamento legislativo em toda página do PDF exportado (extensão de `publication.service.ts`/`pdf-composer.ts`, F6) — ou marca "sem versão" quando nenhuma foi fechada, coexistindo com o rótulo "Rascunho" (F6, sem alteração), com marca fail-secure "alterado após o fechamento" quando o texto muda depois da Versão vigente (`toVersionedContentFields`/`versioned-content-diff.ts`, ponto único de manutenção travado por `satisfies` no typecheck). 14 COMPs, 7 DECs (1 irreversível, DEC-029-003 — aplicada pelo Tech Lead via escada de reação sem pausar o ciclo, **confirmada pelo Diretor na Entrega**), 6 TRISKs/RISKs. 4/4 TASKs Done, 3 waves — furo de processo na Wave 1 (migração aplicada em dev+teste sem perguntar antes ao Diretor, contra regra incondicional do CLAUDE.md do workspace — achado pelo `code-reviewer`, ratificado retroativamente pelo Diretor, LRN-036 roteada); furo no plano sancionado na Wave 2 (baseline vermelho pré-existente e não-relacionado em `publication.service.integration.test.ts`, teste de teto de duração CPU-bound sensível a hardware, território F6). Rodadas de gate: Wave 1 1 retry (asserção não-discriminante); Wave 2 1 retry (3 achados de prova, todos confirmados por mutation testing real — inclui lição nova sobre espionar o client Prisma raiz em vez do `tx` de transação); Wave 3 2 rodadas de retry (gate 1-7 + gate 11 convergentes: mensagens de erro genéricas para recusas permanentes, ordem divergente dos irmãos no slot `supplementary`, campo de data não resetado pós-sucesso, fuso UTC indevido no timestamp — todos corrigidos; 2ª rodada fechou um achado de cobertura de fallback só-teste, aplicado diretamente pelo Tech Lead dado o caráter mecânico/reversível). Gates 8/10 aprovados 1ª rodada em todas as waves aplicáveis. **As 2 FEATs VERIFICADAS por execução real** (`qa` com MCP Playwright, servidor + Postgres reais): FEAT-028-002 (carimbo no PDF, 4 cenários × 2 Variantes) e FEAT-028-001 (fechamento + histórico, fluxo completo em browser). 3 lições novas em `lessons.md` (espionar client Prisma errado numa transação; componente novo em slot ocupado deve citar irmão canônico por eixo, não só para os "3 estados"; extrator com cadeia de fallback exige 1 teste por ramo) + 1 `PROPOSTA_PLUGIN` (LRN-037, `commands/tasks.md` não prescreve enumerar causas de recusa por status antes do código, mensagem ao mantenedor pronta na Entrega) além da LRN-036 da Wave 1. Migração aplicada só em dev/teste local, com ratificação do Diretor — produção não tocada.

- Contrastes, pegadinha elaborada, flashcards e protocolo impresso de revisão (SPEC-026/**PLAN-027**, F7 do épico MNEMORA STUDIO, 8/8 TASKs Done 2026-09-26, branch `feat/producao-material-mnemora-studio` não mergeada) — 3 registros novos pendurados em `RawContent` (Contraste e `ProductionFlashcard`, N:1 diretos, guarda `assertRawContentReachable`+autor-ou-ADMIN; Pegadinha elaborada como coluna `pegadinhaText` nullable, guarda em 1 `updateMany` composto — mais seguro que o padrão de 2 passos, fecha janela TOCTOU), `ConfirmRemoveDialog` compartilhado com foco gerenciado por desfecho (survivor/restore), valor aditivo `MATERIAL_REFORCO` no `ProductionStageType`, composição suplementar no PDF exportado (F6) com título por seção e Protocolo impresso de 6 Marcos fixos (sem cálculo de tempo), fundida via `copyPages` nas 2 Variantes. Contraste/Pegadinha/Flashcard **alcançáveis pela tela real** de `content/[id]` desde a Wave 6 (`ContentSupplementaryPanel`, TASK-027-007) — furo achado na convergência de fecho da Entrega (nenhuma TASK 001-006 montava o componente numa página), corrigido antes do PR por decisão do Diretor; Pegadinha **recarregada a cada visita** desde a Wave 7 (TASK-027-008 — 2º furo, achado na RECONFIRMAÇÃO da convergência: `refetchOnMountOrArgChange` faltava para o único dos 3 sujeitos de FR-026-005/011/017 sem COMP de lista próprio; retry moveu a opção do subscriber secundário para o primário depois que gate 10 mediu 1 GET redundante na 1ª tentativa). 18 COMPs, 8 DECs (todas reversíveis), 7 TRISKs (2 são risco de produto ainda aberto — ver TRISK-027-006/007) + 1 risco novo fora de escopo (RISK-027-010, território F2). 8/8 TASKs Done, 7 waves — retomada de sessão múltiplas vezes (pausa de ~9 dias entre Wave 3 e 4, developer interrompido por rate-limit e por reinício de sessão host na Wave 4, trabalho parcial sempre preservado e continuado, nunca refeito). Todas as 5 rodadas de gate reprovaram na 1ª tentativa e fecharam na 2ª (Wave 6 precisou de uma 3ª passada — retry consolidado resolveu a substância mas introduziu regressão de prova mecânica em 4 asserções de teste, corrigida à parte): Wave 2 (2 bloqueantes de prova + 3 de acessibilidade), Wave 3 (1 bloqueante — reflexo real na UI, mesma classe da Wave 4), Wave 4 (3 bloqueantes de prova + 3 de UX), Wave 5 (3 bloqueantes de prova + 1 achado alta de design — Pegadinha sem rótulo no PDF, risco pedagógico real, corrigido com título de seção), Wave 6 (achado alta de design + 4 bloqueantes de código — Pegadinha falso-vazia em loading/erro do titular, id duplicado em `aria-*`, 404 mal atribuído em edição, DRY). 6 reincidências da lição DRY (fixture de teste duplicada) ao longo do slug + 1 nova reincidência da lição de posicionamento de exportação (Wave 6), 1 lição nova de teste (critério com efeito repartido entre componentes irmãos), 1 de performance (docstring citando precedente não verificado), 3 lições novas da Wave 6 (composição de wrapper com prop nullable ambíguo; mensagem de erro por status com causa múltipla; rename de nome acessível quebrando asserção negativa). 6 FEATs VERIFICADAS por execução real (HTTP+Postgres+PDF gerado nas 2 Variantes; componente montado com store real para as 3 de remoção) — **FEAT-026-001/002/003 reverificadas na Wave 6 em browser real** (1ª verificação de tela de fato do PLAN, `gates.screenVerify`), fechando a lacuna que as 3 primeiras verificações (Wave 4/5) tinham deixado PARCIAL por falta de tela. **2 riscos de produto abertos para decisão do Diretor na Entrega**: TRISK-027-006 (caractere fora de WinAnsi em Contraste/Flashcard/Pegadinha derruba a Exportação inteira) e TRISK-027-007 (DEC-027-005 diverge de COMP-027-018/DEC-025-007 no alcance de leitura da exportação). Migração aplicada só em dev local nesta sessão, com autorização do Diretor — produção não tocada. Tracker: `jira.enabled: true` — degradado (grant só para `autoavaliar.atlassian.net`) nas Waves 4/5, **reconciliado com sucesso em 2026-09-26** via `/keelson:jira-sync` (conector respondeu no cloudId correto na 3ª tentativa) — 6/6 Stories e 6/6 sub-tasks sincronizadas, marco "Funcionalidade pronta p/ QA" comentado nas 6 FEATs.

- Redesenho visual da tela de login (SPEC-030/**PLAN-031**, ✅ 2026-09-29) — card central
  em duas metades (painel ilustrado decorativo: dunas/montanhas em camadas, lua cheia,
  estrelas, estrelas cadentes, céu em degradê roxo→rosa; painel de formulário) sobre um
  fundo de página em tela cheia com a mesma atmosfera desfocada (`position: fixed` dentro
  da árvore normal do root layout, sem route group — DEC-031-001, achado técnico do
  `code-scout`: este projeto só tem 1 root layout); campos em pílula com ícone à esquerda
  (e-mail e senha, mesma soma de larguras); botão largo em tom da paleta; paleta noturna
  nova como 15+ tokens aditivos no `@theme` (DEC-031-003); `SiteHeader`/footer e o
  comportamento de autenticação (SPEC-002/SPEC-016) 100% preservados; `prefers-reduced-motion`
  respeitado. 6 COMPs, 3 DECs (todas reversíveis), 4+ TRISKs (todos fechados com medição
  real — contraste AA nos dois temas, bundle sem JS extra do cliente, `@utility` sem
  dependência de custom properties internas do Tailwind). Demanda avulsa fora do épico
  MNEMORA STUDIO — brief BRIEF-030, Jira Story KAN-73 (projeção compacta, sub-tasks
  KAN-143..148 concluídas). 6/6 TASKs Done, 4 waves — 6 rodadas de retry reais ao todo
  (achados genuínos de `product-designer`/`code-reviewer`: prova de ausência tautológica,
  ícone à esquerda faltando na senha, DRY real entre `LoginForm`/`PasswordField`,
  dependência de custom property Tailwind não registrada — regressão de a11y evitada
  antes de chegar a produção, botão sem hover/cursor). 5 lições novas/estendidas em
  `lessons.md`. 1 furo de plano (branch local não pushada, corrigido em degrau 1). 627/627
  testes verdes (HEAD `f328321`). Gate 9 (`qa`) consolidado na Entrega: 10/11 passos do
  roteiro VERIFICADOS via navegador real; AC-030-012 (clique físico de login)
  **pendente_handoff** (causa `permissao_ambiente` — ver HANDOFF-PLAN-031). Convergência
  de fecho (revisão da branch inteira, fora do escopo de qualquer wave/TASK isolada)
  achou e fechou 1 gap real: contraste do header/footer herdado do root layout contra o
  novo fundo em tela cheia. PO: ACEITA_COM_RESSALVAS (5 ressalvas — ver Entrega).
  **Emenda v0.2 (2026-09-30, BRIEF-039/KAN-177, TASK-031-007):** a moldura já não é preservada
  em `/login`. O cabeçalho saiu no BRIEF-032 e o rodapé saiu agora, pela lista única
  `CHROME_HIDDEN_ROUTES` (`app-chrome-gate.tsx`). O cartão ganhou o link "Voltar para o início"
  → `/`, fora do `<form>` (FR-030-015/016, AC-030-015). O ajuste BRIEF-042 deixou o link centralizado e sem sublinhado, por decisão do Diretor.

### Especificadas, ainda não planejadas
- Cadastro de tema/assunto novo pelo EDITOR, dentro de disciplina existente (E-01/Q-005-004, respondido pelo Diretor na Entrega de PLAN-006 — reabre A-005-007 de SPEC-005). Fora do escopo de PLAN-006, que foi implementado e entregue sob o comportamento anterior (seleção restrita ao acervo semeado). Precisa de PLAN/brief próprio para decidir a forma (endpoint de criação, validação/dedup, UI).
- Pipeline de publicação — geração sob demanda de PDF rascunho em duas variantes (tira/resumo) a partir de Conteúdo bruto com Quebra salva, reusando Tira (F4) e Biblioteca visual (F5), com postura de segurança agnóstica de motor (sem rede a partir de conteúdo do usuário, sem template executável) — SPEC-024, F6 do épico MNEMORA STUDIO, `Approved` 2026-09-14, **mergeada em `main`**.

_Épico MNEMORA STUDIO decomposto em 11 fatias (BRIEF-2026-08-27-mnemora-studio-epic); F1 entregue e mergeada (BRIEF-002/SPEC-002/PLAN-003); F2 entregue e mergeada 2026-09-06 (BRIEF-005/SPEC-005/PLAN-006, PRs #2 backend/#3 frontend); F3 entregue e mergeada 2026-09-06 (BRIEF-009/SPEC-009/PLAN-010, 3/3 TASKs Done, PR #3 backend `6541d49`). F4 entregue e mergeada (BRIEF-011/SPEC-011/PLAN-012, 13/13 TASKs Done, DoD+Entrega ACEITA_COM_RESSALVAS 2026-09-07, PR #5 backend/#9 frontend). F5 entregue e mergeada 2026-09-14
(BRIEF-022/SPEC-022/PLAN-023, 17/17 TASKs Done, 6 waves, DoD satisfeito, PR #6 backend
`e316ab6`/PR #12 frontend `677b836`). F6 entregue e mergeada em `main` 2026-09-15
(BRIEF-024/SPEC-024/PLAN-025, 14/14 TASKs Done, PR #7 backend `5d6b4df`/PR #13 frontend
`b54b6ef`). **F7 entregue e mergeada 2026-09-26** (BRIEF-026/SPEC-026/PLAN-027, 8/8 TASKs
Done, 7 waves — Wave 6 e 7 fecharam furos achados nas 2 passadas da convergência de fecho
da Entrega — PR #8 backend `9b87acc`/PR #14 frontend `2ceaa6f`). Jira: Épico KAN-121
fechado._

## SPECs

| ID | Título | Status | Data |
|----|--------|--------|------|
| SPEC-002 | Acesso interno e papéis de produção | Approved | 2026-08-28 |
| SPEC-005 | Conteúdo bruto e quebra da regra | Approved | 2026-09-01 |
| SPEC-009 | Instrumentação de etapas da fábrica | Approved | 2026-09-06 |
| SPEC-011 | Tira mnemônica como sequência de quadros | Approved | 2026-09-06 |
| SPEC-013 | Suporte a PWA no mnemonicos-frontend | Approved | 2026-09-06 |
| SPEC-016 | Toggle de mostrar/ocultar senha nos campos de senha | Approved | 2026-09-07 |
| SPEC-019 | Página 404 personalizada com volta à home | Approved | 2026-09-07 |
| SPEC-022 | Biblioteca visual reutilizável | Approved | 2026-09-13 |
| SPEC-024 | Pipeline de publicação — PDF (rascunho) | Approved | 2026-09-14 |
| SPEC-026 | Contrastes, pegadinhas, flashcards e protocolos impressos | Approved | 2026-09-16 |
| SPEC-028 | Versionamento editorial e fechamento legislativo | Approved | 2026-09-26 |
| SPEC-030 | Redesenho visual da tela de login (v0.2: emenda BRIEF-039/KAN-177, `/login` sem moldura + link de volta ao início; v0.3: emenda BRIEF-043/KAN-185, botão em envio com spinner) | Approved | 2026-09-30 |
| SPEC-032 | Controle de qualidade e gate de versão aprovada | Approved | 2026-09-27 |
| SPEC-034 | Painel estratégico e tempo por página | Approved | 2026-09-30 |
| SPEC-036 | Botão de sessão e tema dark/light no header do app (renumerada de SPEC-034 por colisão de ID entre sessões paralelas) | Done | 2026-09-29 |
| SPEC-040 | Sessão reconhecida abre a área logada (v0.5 — logo emendado pela SPEC-044) | Approved | 2026-09-30 |
| SPEC-044 | Sidebar de navegação da área interna | Approved | 2026-09-30 |
| SPEC-048 | Gestão de usuários (ADMIN) — emenda a navegação da SPEC-044 | Approved | 2026-09-30 |
| SPEC-050 | Usuários — ações em ícone e reativação de conta (emenda a SPEC-048) | Approved | 2026-10-01 |

## PLANs

| ID | Cobre | FRs cobertos | Tasks | Status |
|----|-------|--------------|-------|--------|
| PLAN-003 | SPEC-002 | 24/24 FRs + 9 NFRs (autenticação de sessão, autorização deny-by-default, gestão de contas por ADMIN) | 16/16 ✅ | Done |
| PLAN-006 | SPEC-005 | 24/24 FRs + 7/7 NFRs (conteúdo bruto, quebra da regra 1:1, fonte normativa estruturada, radar de prova, saneamento do contrato fantasma, semente de Obrigação Tributária) | 14/14 ✅ | Approved |
| PLAN-010 | SPEC-009 | 10/10 FRs + 5/5 NFRs (mecanismo append-only de evento de etapa, emissão transacional nas 2 estações existentes, rede de paridade cross-repo backend-only) | 3/3 ✅ | Done |
| PLAN-012 | SPEC-011 | 11/11 FRs + 6/6 NFRs (models `MnemonicStrip`/`MnemonicFrame`, geração automática + CRUD + reordenação atômica, instrumentação aditiva `TIRA_MNEMONICA`, alcance por autoria herdado) | 13/13 ✅ | Approved |
| PLAN-013 | SPEC-013 | 6/6 FRs + 8/8 NFRs (manifesto, ícones 192/512, service worker artesanal restrito a assets estáticos, kill-switch por autodesregistro, postura de exposição, não-regressão de sessão) | 6/6 ✅ | Done (sugerido) |
| PLAN-018 | SPEC-016 | 7/7 FRs + 4/4 NFRs (componente PasswordField com toggle de visibilidade, SVG inline, atributos anti-canal, aplicado ao LoginForm) | 2/2 ✅ | Done (sugerido) |
| PLAN-020 | SPEC-019 | 4/4 FRs + 4/4 NFRs (página 404 nativa do App Router `not-found.tsx`, precedência guard×404 delegada ao `proxy.ts` existente, link de volta via `next/link`) | 2/2 ✅ | Done (sugerido) |
| PLAN-021 | SPEC-002 | 1 FR + 1 NFR re-cobertos (FR-002-001/NFR-002-008, já contabilizados em PLAN-003) — rewrite same-origin do cookie de sessão para topologia cross-site em produção, reabre DEC-003-004 | 2/2 ✅ | Done (sugerido) |
| PLAN-023 | SPEC-022 | 25/25 FRs + 7/7 NFRs (módulo `visual-associations` — CRUD, upload validado por assinatura de bytes, binário como bytea no Postgres; extensão de `tira` para vínculo N:1 com `MnemonicFrame`, alcance por autoria herdado, evento de etapa `ASSOCIACAO_VISUAL`, log dedicado de reuso) | 17/17 ✅ | Approved |
| PLAN-025 | SPEC-024 | 17/17 FRs + 4/4 NFRs (módulo `publication` — motor `pdf-lib`, 2 Variantes tira/resumo, supressão de evento de abertura na auto-geração de Tira, teto de duração interno, evento `PUBLICACAO_PDF` + tabela `publication_events`; FR-024-017 emendada na Entrega — recusa de Tira com 0 Quadros) | 14/14 🟢 | Approved — **mergeado em `main`** (PR #7 backend `5d6b4df`/PR #13 frontend `b54b6ef`, 2026-09-15) |
| PLAN-027 | SPEC-026 | 29/29 FRs + 5/5 NFRs (models `Contrast`/`ProductionFlashcard` N:1 diretos com `RawContent`; coluna `pegadinhaText` nullable; valor aditivo `MATERIAL_REFORCO` no `ProductionStageType`; composição suplementar no PDF via `buildSupplementaryPagesPdf` + `copyPages`, ambas Variantes; diálogo de confirmação com foco gerenciado compartilhado; telas alcançáveis via `ContentSupplementaryPanel`, refetch na revisita) | 8/8 ✅ | Done (sugerido) |
| PLAN-029 | SPEC-028 | 11/11 FRs + 3/3 NFRs (model `ContentVersion` append-only com `contentSnapshot: Json`; valor aditivo `VERSAO_EDITORIAL` no `ProductionStageType`; lock de linha do `RawContent` pai para numeração sequencial; extensão de `publication.service.ts`/`pdf-composer.ts` para o carimbo de Versão/Data no PDF, com marca fail-secure de alteração pós-fechamento) | 4/4 ✅ | Approved |
| PLAN-031 | SPEC-030 | 14/14 FRs + 6/6 NFRs (fundo em tela cheia via `position: fixed` sem route group — DEC-031-001; ilustração SVG inline + CSS puro, sem asset/dependência nova — DEC-031-002; paleta como tokens aditivos no `@theme` — DEC-031-003; restyle de `LoginForm`/`PasswordField` sem tocar comportamento; emenda v0.2: TASK-031-007 realiza FR-030-013 reescrito + FR-030-015/016 novos, fora do "FRs cobertos" do PLAN v0.1) | 7/7 ✅ | Approved |
| PLAN-033 | SPEC-032 | 18/18 FRs + 3/3 NFRs (colunas `approvedById`/`approvedAt` em `ContentVersion` + valor aditivo `APROVACAO_VERSAO`; `approveContentVersion` com o mesmo lock transacional de F8 + idempotência por `updateMany` condicional; segregação de funções por 3 identidades produtoras lidas ao vivo; `resolveAlterationSignal` estendendo o sinal de F8 para cobrir a Tira mnemônica via reuso de `ProductionStageEvent`; carimbo "Versão aprovada" no PDF substituindo "Rascunho") | 7/7 ✅ | Approved |
| PLAN-035 | SPEC-034 | 34/34 FRs + 4/4 NFRs (`PublicationEvent.pageCount Int?` com contagem fail-safe na composição; módulo `strategic-panel` com 5 consultas de contagem fixa + funções puras com `now`; correlação Exportação×evento de etapa por (rawContentId, occurredAt), ordem sempre por `sequence`; predicado de F9 extraído para função pura reusada em lote; `/studio` vira o Painel; 22 COMPs, 20 DECs todas reversíveis, 4 TRISKs) | 8/8 ✅ | Done — **mergeado em `main`** (PR #11 backend, PR #19 frontend, 2026-09-30) |
| PLAN-036 | SPEC-036 | 16/16 FRs + 5/5 NFRs (`AuthControl`/`ThemeToggle` novos no `SiteHeader`; script de bootstrap de tema sem dependência nova; `meSilent` via `queryFn` contornando `baseQueryWithReauth`; mapeamento de `--surface`/`--surface-raised`/`--border-subtle` para a paleta noturna, extensão de `night-palette-tokens.ts`; consolidação do logout — `internal-shell.tsx` perde seu `LogoutControl` próprio) | 6/6 ✅ | Done — **mergeado em `main`** (PR #18, `e254bd1`, 2026-09-30) |
| PLAN-041 | SPEC-040 | 16/16 FRs + 6/6 NFRs (decisão no navegador na própria home com `proxy.ts` intocado; pista local de sessão decide só se há conferência; estado neutro por script inline da página + teto de 3 s; `homeSessionCheck` RTK Query com renovação silenciosa extraída do `baseQueryWithReauth`; `router.replace` + reconferência em volta/bfcache) | 4/4 ✅ | Done (sugerido) |
| PLAN-046 | SPEC-044 | 27/27 FRs + 4/4 NFRs (sidebar no ramo pronto da casca; lista declarada amarrada às rotas; breakpoint `xl` + container `max-w-7xl` com conta nas 5 larguras; container sai do `<main>` raiz para `PageContainer`; disclosure no fluxo com fechamento derivado da rota; `SiteLogo` por `meSilent` + pista no clique; sem token novo) | 5/5 ✅ | Approved — **mergeado em `main`** (PR #26, `5bce413`, 2026-09-30) |
| PLAN-049 | SPEC-048 | 25/25 FRs + 5/5 NFRs (guarda ADMIN por mapa de papel na fonte única `internal-routes.ts`, shell único deriva do `usePathname()`; menu de 4 itens filtrado por papel vindo do shell, 0 chamadas novas; senha fora do store por `initiate(args, {track:false})`; paginação anterior/seguinte; busca com debounce de 300 ms; `AccountConfirmDialog` novo; `PasswordField` com prop de erro aditiva; só frontend) | 6/6 ✅ | Approved — **mergeado em `main`** (PR #27, `6adbdf8`, 2026-10-01) |
| PLAN-051 | SPEC-050 | 14/14 FRs + 3/3 NFRs (rota `PATCH /users/:id/enable` espelhando `disableUser`, sem migração; log de auditoria pontual via tipo paralelo `UserAuditType`/`recordUserAuditEvent` em `lib/audit.ts`, sem tabela nova; coluna de Ações migra a célula de "render condicional por ação" para "1 botão só, props computadas da Situação" — ícone SVG inline + tooltip CSS, foco pós-ação estável na mesma linha; remove "Redefinir senha" da linha) | 0/? ⏸ | Approved |

> **Métrica §1.3 da SPEC-002** (`Fonte de medição: externa`): a fonte é a suíte de conformidade
> `mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts` (TASK-003-011).
> Dono: time de engenharia. Natureza: **conformidade** (verde/vermelha no CI — toda rota
> não-pública prova 401 sem sessão / 403 com papel insuficiente ou não-declarado), **não**
> instrumentação de evento. O boot também recusa a app (`assertDenyByDefault`) se a árvore
> montada divergir do registro.

## Glossário consolidado

| Termo | Definição | Origem |
|-------|-----------|--------|
| Tira mnemônica | Sequência ordenada de quadros que reconstrói uma regra (CONCEITO → AÇÃO → OBJETO → CONDIÇÃO/EXCEÇÃO) — entidade própria de F4 | BRIEF-001 |
| Quebra da regra | Decomposição do texto normativo bruto nos cinco blocos, mais a síntese da regra; 1:1 com o Conteúdo bruto | BRIEF-001 / SPEC-005 |
| Radar de prova | Classificação por risco de prova | BRIEF-001 |
| Classe do radar de prova | Uma de `ALTA`, `MEDIA`, `DETALHE`, `EXCECAO`, `PEGADINHA` — as 5 classes da TAP §3.2 camada 1; dado persistido no Conteúdo bruto (RDR-001 selado por A-005-001) | SPEC-005 |
| Prioridade de apresentação | Rótulo derivado não persistido (`ALTA`→Alta, `MEDIA`→Média, `DETALHE`/`EXCECAO`/`PEGADINHA`→Baixa); exibição adiada para F10 | SPEC-005 |
| Conteúdo bruto | Texto normativo colado + disciplina + tema/assunto + classe do radar de prova; a primeira estação da linha de produção | SPEC-005 |
| Bloco da quebra | Cada um dos cinco campos textuais independentes: CONCEITO, AÇÃO, OBJETO, CONDIÇÃO, EXCEÇÃO (CONDIÇÃO/EXCEÇÃO em branco = "não se aplica") | SPEC-005 |
| Síntese da regra essencial | A regra reduzida ao núcleo, em linguagem tecnicamente correta | BRIEF-001 / SPEC-005 |
| Tipo do dispositivo | Gênero da fonte normativa: CF, CTN, lei, lei complementar, súmula, ato normativo | SPEC-005 |
| Citação do dispositivo | Apontador textual do dispositivo dentro da fonte (ex.: "CTN, art. 113") | SPEC-005 |
| Remoção reversível (Conteúdo bruto) | Item e Quebra vinculada saem da listagem e ficam inalcançáveis (inclusive por id direto), dados preservados para expurgo futuro (F8) | SPEC-005 |
| Carimbo de última alteração | Par quem/quando de estado atual no Conteúdo bruto, sem trilha histórica (trilha é F8); não sobrescreve a autoria original | SPEC-005 |
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
| Quadro | Unidade atômica da Tira mnemônica: um texto livre com uma posição/sequência inteira dentro da tira a que pertence — sem vínculo funcional fixo com o Bloco da quebra de origem depois da geração inicial (carimbo de proveniência é metadado informativo, não vínculo) | SPEC-011 |
| Posição do quadro | Número de ordem de um Quadro dentro de sua Tira mnemônica — contígua, sem lacuna nem duplicidade em nenhum estado observável | SPEC-011 |
| Geração inicial (da Tira mnemônica) | Ato do sistema, disparado na 1ª abertura da Tira mnemônica de uma Quebra da regra já salva, que cria automaticamente um Quadro por Bloco não-vazio, ordem canônica CONCEITO → AÇÃO → OBJETO → CONDIÇÃO → EXCEÇÃO | SPEC-011 |
| Mnemônico legado | Modelo de dados anterior à Tira mnemônica (`Mnemonic.hook`/`decoding`), texto livre sem estrutura de sequência; sem consumidor na fábrica desde F4 (reclassifica, não encerra, RISK-005-004) | SPEC-005 (A-005-013) → SPEC-011 |
| App instalado | Instância do `mnemonicos-frontend` adicionada pelo usuário à tela inicial/dock do dispositivo via mecanismo do navegador, executando em janela própria (modo standalone), sem a barra de navegação do navegador | SPEC-013 |
| App-shell | Conjunto de assets estáticos (JS, CSS, ícones, manifesto de aplicação) cacheável pelo service worker independentemente de qualquer dado de sessão ou de conteúdo — nunca inclui documento HTML/navegação | SPEC-013 |
| Modo standalone | Modo de exibição do app instalado sem a barra de endereço/navegação do navegador, declarado no manifesto de aplicação | SPEC-013 |
| Instalabilidade | Conjunto de critérios do navegador (manifesto válido, ícones nos tamanhos exigidos, service worker registrado, contexto seguro) que habilitam o prompt nativo de instalação/"Adicionar à tela inicial" | SPEC-013 |
| Service worker | Script registrado pelo navegador que intercepta requisições do app instalado para controlar cache e ciclo de vida do app-shell — restrito a assets estáticos, nunca navegação (NFR-013-005) | SPEC-013 |
| Toggle de visibilidade de senha | Controle (ícone de "olho") que alterna a exibição do valor de um campo de senha entre oculto (mascarado) e texto plano, sem alterar o valor digitado | SPEC-016 |
| Campo de senha (componente) | Componente de entrada reutilizável que encapsula um `<input>` de senha e o toggle de visibilidade associado — usado pelo `LoginForm` hoje e por qualquer campo de senha futuro | SPEC-016 |
| Rótulo acessível dinâmico (do toggle) | Texto acessível (ex.: `aria-label`) do controle de alternância, que muda conforme o estado atual do campo — "mostrar senha" quando oculto, "ocultar senha" quando visível | SPEC-016 |
| Página 404 (personalizada) | Tela exibida quando o usuário acessa uma rota inexistente, com a identidade visual da aplicação (paleta, tipografia, componentes de marca) e um link/botão de volta — em contraste com a página de erro genérica do framework | SPEC-019 |
| Rota inexistente | Qualquer URL solicitada na aplicação que não corresponde a nenhuma rota definida — cai na 404 personalizada na área pública sempre, e na área interna só com sessão ativa (sem sessão, o guard de SPEC-002 prevalece) | SPEC-019 |
| Home pública | A página inicial da aplicação em `/`, exibida a quem não tem sessão reconhecida com papel com acesso à área interna. `/` segue destino fixo do link de volta da 404, e do logo quando não há sessão ativa com papel com acesso à área interna (com essa sessão, o logo vai a `/studio` — SPEC-044); quem tem sessão reconhecida é levado dali à área interna. Promessa mantida: `/` nunca exige sessão nem leva à tela de login | SPEC-019 · emendada por SPEC-040 e SPEC-044 |
| Sessão reconhecida | Sessão que o sistema aceita agora **ou** que se renova sem pedir senha de novo; corresponde à "sessão ativa" do card KAN-180 e não redefine "sessão ativa" da SPEC-036 (= sessão aceita agora) | SPEC-040 |
| Conferência da sessão | Verificação, feita quando a página inicial é aberta (nunca por pré-carregamento), de se há sessão reconhecida e de qual é o papel da conta | SPEC-040 |
| Estado neutro (página inicial) | Aparência da página inicial enquanto a conferência da sessão dura: sem conteúdo da Home pública e sem "Entrar"/"Sair" (o neutro do cabeçalho de FR-036-016) | SPEC-040 |
| Teto da conferência | Limite de 3 s, da abertura da página inicial, em qualquer ambiente; passado o teto, o estado neutro termina na Home pública | SPEC-040 |
| Biblioteca visual | Acervo pesquisável e navegável de associações visuais, organizado por categoria, reutilizável entre Quadros de Tiras diferentes | SPEC-022 |
| Categoria (da associação visual) | Rótulo textual atribuído pelo EDITOR para agrupar e filtrar associações visuais na biblioteca; texto livre com sugestão das categorias existentes e normalização (trim/case-fold) no filtro | SPEC-022 |
| Função cognitiva (da associação visual) | Justificativa textual, escrita pelo EDITOR, de por que a imagem apoia a recuperação da regra — não decoração; critério herdado da TAP | SPEC-022 |
| Vínculo (associação visual ↔ Quadro) | Relação entre uma associação visual e um Quadro (no máximo 1 associação por Quadro nesta fatia) — o que torna a associação visual reutilizável entre Tiras diferentes | SPEC-022 |
| Publicação | Ato de gerar um documento PDF a partir de um Conteúdo bruto, numa das duas Variantes de F6, sempre marcado como rascunho | SPEC-024 |
| Variante do PDF | "tira" (Quadros em ordem, com Associação visual vinculada quando existir) ou "resumo" (texto corrido da Quebra da regra, sem diagramação de Quadros — braço de controle do A/B de retenção, A-012) | SPEC-024 |
| Rascunho (PDF) | Rótulo textual visível estampado em toda página de todo PDF emitido por F6, indicando que o documento não passou pelo carimbo de Versão aprovada (F8+F9) | SPEC-024 |
| Exportação | Ação disparada pelo EDITOR ou ADMIN, na tela do Conteúdo bruto ou da Tira mnemônica, que aciona a Publicação e resulta no download do PDF gerado | SPEC-024 |
| Contraste | Comparação registrada pelo EDITOR entre um Conteúdo bruto titular e um instituto/regra confundível (texto livre), com explicação sucinta da distinção — reforça a discriminação na memória | SPEC-026 |
| Confundível | O texto livre que descreve o instituto/regra com o qual o Conteúdo bruto titular costuma ser confundido, dentro de um Contraste | SPEC-026 |
| Pegadinha elaborada | Texto explicando por que um ponto de um Conteúdo bruto é um erro comum de prova — acrescenta explicação à Classe do radar de prova já persistida, não a redefine | SPEC-026 |
| Flashcard | Par pergunta/resposta (frente/verso) derivado de um Conteúdo bruto/Quebra da regra, autorado pelo EDITOR, incluído no documento da Exportação | SPEC-026 |
| Protocolo impresso de revisão | Checklist textual, gerada no momento da Exportação, listando os 6 Marcos de revisão na ordem fixa, sem cálculo nem rastreamento de cumprimento pelo sistema | SPEC-026 |
| Marco de revisão | Cada um dos 6 rótulos fixos do Protocolo impresso — R0, R24, R3, R7, R14, R30 — herdados da TAP, nunca calculados pelo scheduler SM-2 existente (dormente) | SPEC-026 |
| Versão editorial (do Conteúdo bruto) | Registro imutável (número sequencial, Data de fechamento legislativo, autor do fechamento, timestamp técnico), recortado por campo (texto normativo, radar, fonte normativa, blocos da Quebra da regra — Pegadinha elaborada fora) — a trilha histórica que o Carimbo de última alteração (SPEC-005) já previa como pendente para F8 | SPEC-028 |
| Fechar uma Versão (ato) | Ação explícita do EDITOR-autor ou ADMIN sobre um Conteúdo bruto, disparando o registro de uma nova Versão editorial — nunca automática a cada edição | SPEC-028 |
| Versão vigente | A Versão editorial mais recente fechada de um Conteúdo bruto — a que aparece estampada no PDF exportado dele | SPEC-028 |
| Card em duas metades | Unidade visual central de `/login`: um painel ilustrado no topo e um painel de formulário na base, percebidos como um único bloco flutuante sobre o fundo da página | SPEC-030 |
| Painel ilustrado | Metade superior do card de `/login`, com ilustração autoral decorativa (motivo noturno: montanhas/dunas em camadas, lua cheia, estrelas, estrelas cadentes, céu em degradê), sem função interativa nem conteúdo lido por tecnologia assistiva | SPEC-030 |
| Fundo em tela cheia (do login) | Camada de fundo da página `/login`, atrás do card, que estende a mesma atmosfera visual do painel ilustrado em escala maior e com profundidade/desfoque | SPEC-030 |
| Campo em pílula | Estilo visual de campo de formulário com bordas totalmente arredondadas e um indicador visual (ícone) à esquerda do valor digitado | SPEC-030 |
| Checagem jurídica (confirmação) | Atestação, feita pelo ADMIN no ato de aprovação, de que o texto normativo e a fonte normativa da Versão vigente estão corretos e correspondem entre si | SPEC-032 |
| Checagem pedagógica (confirmação) | Atestação, feita pelo ADMIN no ato de aprovação, de que o material — incluindo a Tira mnemônica vinculada — cumpre a função de recuperação | SPEC-032 |
| Segregação de funções (do ato de aprovação) | Regra aplicada pelo sistema (fail-secure, não disciplina operacional): o aprovador não pode ser nenhuma identidade produtora do conteúdo normativo da Versão (quem a fechou, autor original do Conteúdo bruto, ou último editor antes do fechamento) | SPEC-032 |
| Conteúdo normativo (escopo da aprovação) | O recorte avaliado pela aprovação: texto normativo, Classe do radar de prova, fonte normativa, blocos/síntese da Quebra da regra (já versionados por F8) mais a Tira mnemônica vinculada; exclui Contraste, Pegadinha elaborada, Flashcard e Associação visual | SPEC-032 |
| Painel estratégico | Tela de leitura agregada, interna a EDITOR/ADMIN, página inicial da área interna: tempo de produção por página, tempo por etapa, conclusão por módulo, correções após revisão e backlog de produção — só com o que a fábrica mede sozinha | SPEC-034 |
| Página (da Exportação) | Número de páginas reais do PDF emitido por uma Exportação (Variante Tira inclui as suplementares), registrado no momento da Exportação, nunca recomputado | SPEC-034 |
| Sem medida | Estado de dado numérico não capturado — nunca zero nem estimado | SPEC-034 |
| Tempo de produção por página | Tempo do início registrado da produção (criação instrumentada) até a 1ª Exportação Tira após o 1º fechamento de Versão, dividido pelas Páginas dessa Exportação | SPEC-034 |
| Tempo por etapa | Lead time de calendário do 1º ao último evento de uma etapa (retrabalho incluso), só com abertura e conclusão registradas; senão "em aberto", "não percorrida" ou "sem duração medida" | SPEC-034 |
| Correções após revisão | Retrabalho de etapa de conteúdo ocorrido, por sequência, depois do 1º fechamento de Versão; contado por etapa, nunca somado entre etapas | SPEC-034 |
| Módulo | Um Tema do acervo agrupado por Disciplina (a TAP chama de "módulo") | SPEC-034 |
| Concluído | Conteúdo com Versão vigente aprovada e válida para exportação (regra única de F9) | SPEC-034 |
| Backlog de produção | Conteúdos ativos não concluídos (ativos − concluídos), com etapa mais avançada (Conteúdo bruto → … → Aprovação), prioridade de apresentação e idade | SPEC-034 |
| Controle de autenticação (do header) | Botão sempre visível no header que alterna entre "Entrar" (sem sessão) e "Sair" (com sessão), consumindo o estado de sessão já existente — não redefine login/logout; é o único ponto de acionamento de logout do app | SPEC-036 |
| Alternador de tema | Controle sempre visível no header que permite ao usuário trocar manualmente entre tema claro e escuro | SPEC-036 |
| Escolha de tema salva | Preferência de tema definida manualmente pelo usuário, por dispositivo/navegador (independente de conta), que passa a prevalecer sobre a preferência do dispositivo | SPEC-036 |
| Preferência de esquema de cores do dispositivo | Sinal do sistema operacional/navegador indicando se o ambiente do usuário está configurado para tema claro ou escuro (equivalente a `prefers-color-scheme`) | SPEC-036 |
| Paleta unificada (do app) | Família de cores (roxo/rosa/mauve) e piso de contraste AA já validados em `/login` (SPEC-030), estendidos aos dois temas do restante do app, sem a ilustração decorativa daquela tela | SPEC-036 |
| Casca da área interna | Componente que envolve toda página interna e resolve os estados de sessão e permissão (carregando, sem sessão, sem permissão, pronto) | SPEC-044 |
| Estado pronto (da casca) | Sessão ativa e papel suficiente: a vista interna é renderizada | SPEC-044 |
| Sidebar | Menu lateral de navegação da área interna, com itens de uma lista declarada: Painel (`/studio`), Conteúdos (`/content`) e Biblioteca visual (`/visual-library`) | SPEC-044 |
| Item de menu | Entrada da sidebar, definida por rótulo e destino numa lista declarada | SPEC-044 |
| Conteúdos (item) | Item da sidebar que leva à mesma lista (`/content`) que o link "Conteúdos brutos" das páginas; os dois rótulos coexistem | SPEC-044 |
| Seção atual | Item de menu cujo destino é a rota aberta ou prefixo dela em fronteira de segmento; subpáginas de `/content` pertencem a Conteúdos | SPEC-044 |
| Logo do header | Logo do cabeçalho do app, link cujo destino é `/studio` ou `/` conforme a sessão (SPEC-044) | SPEC-044 |
| Páginas públicas | Home pública, login e página 404 | SPEC-044 |
| Breakpoint da sidebar fixa | Menor largura de viewport em que a sidebar fixa cabe sem estreitar o conteúdo abaixo da largura de antes da SPEC-044; medido pelo PLAN (esperado ~1280px) | SPEC-044 |
| Menu recolhível | Forma da sidebar abaixo do breakpoint da sidebar fixa: fechada por padrão, aberta por botão; disclosure não modal | SPEC-044 |
| Container de largura | Envoltório que limita a largura máxima e define o espaçamento lateral do conteúdo da página | SPEC-044 |
| Volta ao conteúdo | Link "Voltar ao conteúdo" na Tira mnemônica, que leva à página do conteúdo (`/content/[id]`) | SPEC-044 |
| Tela Usuários | Tela da área interna (`/users`), exclusiva do ADMIN, que lista contas internas e permite criar, desativar e redefinir senha | SPEC-048 |
| Conta interna | O que a Tela Usuários lista: o que o servidor devolve, sem filtro de papel; hoje só existem contas EDITOR e ADMIN | SPEC-048 |
| Situação (da conta) | Estado exibido na lista: "Ativa" ou "Desativada" | SPEC-048 |
| Último ADMIN ativo | A única conta ADMIN ativa restante; o servidor recusa desativá-la (FR-002-019) | SPEC-048 |
| Busca de contas | Trecho de nome ou e-mail aplicado à lista, aparado; vazio equivale a sem busca; máximo 120 caracteres | SPEC-048 |
| Confirmação (de ação sobre conta) | Passo antes de desativar ou redefinir senha que identifica a conta-alvo (nome e e-mail), diz a consequência e exige decisão | SPEC-048 |
| Ação sobre a própria conta | Desativar a própria conta ou redefinir a própria senha pela Tela Usuários; encerra a sessão do ADMIN | SPEC-048 |
| Ativar | Ação oposta de "Desativar": move a Situação da conta de "Desativada" para "Ativa", liberando a pessoa para autenticar de novo. Mesmo par de estado de "Situação (da conta)" | SPEC-050 |
| Controle de ação (coluna Ações) | Elemento interativo da coluna "Ações" na linha de uma conta: visualmente compacto, sem rótulo de texto permanente ao lado, disponível/indisponível conforme a Situação, com nome acessível identificando a pessoa-alvo e a ação | SPEC-050 |

## Decisões irreversíveis

- **DEC-029-003** (PLAN-029/F8): `ContentVersion` guarda um **snapshot JSON**
  (`contentSnapshot`) dos campos versionados a cada fechamento, não só um hash —
  capturar o texto agora preserva a opção de reprodução histórica futura; podar depois
  é reversível, não ter capturado não seria. `Reabrir se:` volume real de armazenamento
  (medido) justificar poda — reter só as N versões mais recentes com snapshot completo,
  ou migrar para hash-only a partir de um corte (ambas as direções são remoção de dado
  já existente, não invenção de dado perdido). **Confirmada pelo Diretor na Entrega**
  (AskUserQuestion, 2026-09-26) — aplicada pelo Tech Lead como default seguro/reversível
  da escada de reação (degrau 2, `/keelson:auto`), sem pausar o ciclo, e ratificada.
- (as 12 DECs de PLAN-003 seguem todas reversíveis; ver §6 do PLAN para as condições `Reabrir se:`)

## Riscos ativos

| ID | Risco | Mitigação | Origem |
|----|-------|-----------|--------|
| — | Verificação de tela pendente — HANDOFF-PLAN-046 (`docs/producao-material/handoffs/HANDOFF-PLAN-046.md`) — V1–V7: 22 ACs da SPEC-044 que exigem sessão real + métrica §1.3; motivo `permissao_ambiente` (login automatizado barrado pelo classificador). Exercício anônimo verde, 0 divergências | executar o roteiro com login manual (Diretor) ou autorizar o QA a preencher o login sem ecoar a senha | PLAN-046 |
| TRISK-046-002 | Tirar o container do `<main>` raiz afeta as páginas públicas e cria contrato novo: página pública futura precisa envolver-se em `PageContainer` | classes `default` idênticas às de hoje; `layout.test.tsx` prova `<main>` sem container; integrações HTTP da home/404 verdes; prova em tela nas 5 larguras e 2 temas | PLAN-046 |
| TRISK-046-004 | Disclosure (foco, Esc, toque fora, cruzar `xl`) não se prova em jsdom e já gerou re-gate de design no slug | testes por comportamento nos 4 meios de fechamento + ordem de Tab; `matchMedia` controlável; efeito real no gate 9/11 | PLAN-046 |
| RISK-044-001 | Interação mobile e acessibilidade do menu recolhível (disclosure não modal: foco, Esc, toque fora, troca de rota) já geraram re-gate de design neste slug | ACs 009–012, 021, 022 e gate 11 | SPEC-044 |
| — | Verificação de tela pendente — HANDOFF-PLAN-049 (`docs/producao-material/handoffs/HANDOFF-PLAN-049.md`) — V1–V10: todos os ACs de tela com sessão da SPEC-048; motivo `permissao_ambiente` (login de admin1/editor depende do Diretor; receita 2 vetada pelo PO). Exercício anônimo verde (AC-048-003). | Diretor faz login manual na janela do Playwright, ou autoriza por regra de permissão a leitura do realm | PLAN-049 |
| MET-048 | Métrica de SPEC-048 sem veredito: 100% das contas internas novas provisionadas pela tela (zero por seed ou API manual) até 30 dias após o **deploy em produção** (ainda não houve deploy; sem conta nova = inconclusivo) | medir via declaração do Diretor conferida contra a lista de contas (fonte externa; o sistema não distingue o canal) | SPEC-048 |
| RISK-048-001 | Senha retida no estado do cliente (o cache de requisições guarda os argumentos da mutação) ou em log | NFR-048-001; AC-048-013/025/028 provados por teste que lê o estado; gate 8 | SPEC-048 |
| RISK-048-008 | OWASP A09: criar, desativar e redefinir senha não deixam trilha de autor (só `authz.denied` é auditado); a tela reduz o atrito de usar a API | história de backend de auditoria **candidata** (decisão do Diretor 2026-10-01: sem card até autorização; inclui redigir `?search=` no log de acesso) | SPEC-048 |
| RISK-048-009 | A tela torna trivial criar a 2ª conta ADMIN: destrava RISK-032-001, mas expõe RISK-032-005 e RISK-032-006 (conserto "obrigatório antes de um 2º ADMIN real operar") | texto de ajuda no papel ADMIN (FR-048-009); decisão do Diretor 2026-10-01: merge livre; brief avulso do RISK-032-006 logo após o merge; nenhum 2º ADMIN real até ele entrar | SPEC-048 |
| RISK-048-010 | `%` ou `_` na busca de contas podem trazer contas a mais (classe LIKE não corrigida em `users.service.ts`) | PLAN mede o comportamento real; correção na história de backend | SPEC-048 |
| RISK-048-012 | OWASP A07: senha inicial/redefinida escolhida pelo ADMIN e repassada fora do sistema, sem tela de troca da própria senha | história de UI de troca da própria senha proposta na Entrega | SPEC-048 |
| RISK-050-001 | "Redefinir senha" sai da linha sem realocação (SPEC-050): sem caminho de tela até a página de edição existir — inclui conta recém-reativada que esqueceu a senha | risco aceito, pendência do épico KAN-218; rota de servidor (FR-048-019..024) intacta, só a UI na linha é removida | SPEC-050 |
| RISK-050-002 | OWASP A09: reativar ganha log pontual (NFR-050-001), mas criar/desativar/redefinir senha continuam sem trilha de autor — RISK-048-008 permanece aberto para essas três | história de backend de auditoria candidata (mesma decisão do Diretor de RISK-048-008) | SPEC-050 |
| RISK-050-003 | Troca de botões de texto por controles compactos pode regressar acessibilidade (histórico de re-gate de AA no slug) | AC-050-009/AC-050-010; gate 11 | SPEC-050 |
| RISK-050-005 | Censo de rotas do backend (`route-authz-matrix`) travado em número fixo de pares; rota nova de reativar precisa entrar no array e no comentário do título | tripwire por desenho — atualização manual do array e do comentário | SPEC-050 |
| RISK-050-006 | Origem do controle visual (SVG próprio ou biblioteca) é decisão do PLAN; biblioteca nova soma auditoria de dependência e pode acionar gate 10 pelo peso de bundle | decisão do PLAN-050 | SPEC-050 |
| RISK-050-007 | Reativar conta ADMIN desativada produz um 2º ADMIN ativo; herda RISK-048-009/RISK-032-006 e a decisão do Diretor de 2026-10-01 (nenhum 2º ADMIN real até RISK-032-006 entrar) | diretriz operacional do Diretor; gate 9 só com conta descartável (nunca `admin2` real de dev); Entrega relembra a diretriz | SPEC-050 |
| Q-050-001 | Existe necessidade de, no mesmo fluxo de reativar, também mudar o papel da conta ou prepará-la para edição? (herdado de Q-048-001, ainda sem resposta) | fora desta SPEC se a resposta for sim — viraria outro card | SPEC-050 |
| TRISK-051-001 | Métrica §1.3 da SPEC-050 (contagem de eventos em 30 dias) depende de o log de produção reter/ser consultável por esse período — não confirmável pelo código do repo | gate 9 prova que o evento existe e tem o formato certo, não que sobrevive 30 dias; fonte/dono a declarar no veredito de métrica | PLAN-051 |
| TRISK-051-007 | Reativar conta ADMIN desativada produz um 2º ADMIN ativo (mesma exposição de RISK-050-007/RISK-048-009/RISK-032-006) | diretriz operacional do Diretor; gate 9 só com conta descartável, nunca `admin2` real de dev | PLAN-051 |
| TRISK-051-008 | Troca de botões de texto por controles de ícone tem histórico de re-gate de AA no slug (severidade alta) | só tokens/utilitários já provados (`surface-card`, `FOCUS_CLASS`); contraste medido nos dois temas no gate 11; teste de fonte confere o conjunto de pares de `night-palette-tokens.ts` | PLAN-051 |
| TRISK-049-002 | Senha: `track:false` a mantém fora do estado, mas a ação Redux despachada carrega `meta.arg` e é visível ao Redux DevTools em desenvolvimento | teste de store real durante/depois do voo e no 401 com controle positivo; `devTools` desligado em produção; gate 8 | PLAN-049 |
| TRISK-049-005 | AA e foco de tabela, painel de criação, `AccountConfirmDialog` e `PasswordField` (`night-pill`) dentro da área interna, nos dois temas | só pares de token já provados + teste de fonte; foco/Esc/trap por comportamento; prova em tela no gate 9/11 | PLAN-049 |
| RISK-044-002 | Unificar o container de largura pode regredir as páginas públicas (BRIEF-037 absorvido) | AC-044-019 provado em tela nos dois temas | SPEC-044 |
| RISK-044-003 | Gate 9 do estado "sem permissão" depende de conta sem o papel exigido (não há seed); sem ela a prova em tela fica em handoff | A-044-006/A-044-010; prova por teste automatizado | SPEC-044 |
| RISK-044-004 | Conferência de sessão falha deixa o logo em `/` para pessoa logada | fail-secure; recuperação pelo login ou pela Home pública | SPEC-044 |
| RISK-044-005 | Sem filtro por papel: o 1º item de menu cuja rota exija papel mais restrito que o da área interna reabre o filtro por papel | gatilho de reabertura; exposição nula hoje | SPEC-044 |
| RISK-044-006 | Breakpoint da sidebar fixa (~1280px) é medido pelo PLAN; divergência muda a fração de telas com menu recolhível | A-044-008; AC-044-018 nas larguras 360/768/1024/1280/1440 | SPEC-044 |
| — | Verificação de tela pendente — HANDOFF-PLAN-041 (`docs/producao-material/handoffs/HANDOFF-PLAN-041.md`) — V1–V8: ACs de SPEC-040 que exigem sessão real (002/003/009/012/013 literal/016/017/018/019/025, 010, 020, passo 0 com pista); causa `credencial` (realms `admin1`/`admin2` do `keelson.local.json` desatualizados: `admin1` sem e-mail → 422, senhas → 401) | Diretor atualiza os realms (e pode criar `editor` a partir do `SEED_EDITOR_*`) e roda o roteiro — ~20 min | HANDOFF-PLAN-041 |
| RISK-040-001 | Conferência da sessão pela página inicial concorrendo com renovação de outra aba/requisição pode, fora da janela de graça, revogar a família de sessão e derrubar sessão válida | NFR-040-001 / NFR-040-006 / AC-040-012 / AC-040-020; estratégia no PLAN | SPEC-040 |
| — | Verificação de tela pendente — HANDOFF-PLAN-033 (`docs/producao-material/handoffs/HANDOFF-PLAN-033.md`) — V1–V3: leitura "Válida para a próxima exportação" para EDITOR e ADMIN após o R-1 da aceitação (FR-032-007(b)); `qa` sem credencial utilizável (realms `app`/`admin1` do `keelson.local.json` com placeholder) — comportamento coberto por teste de componente com mutante; 2 rodadas anteriores de browser real verificadas | Diretor preenche os 2 realms e exercita V1–V3 (≈5 min) ou roda `/keelson:verify-handoff` | HANDOFF-PLAN-033 |
| RISK-032-006 | `saveRuleBreakdown` não registra a identidade de quem salva a Quebra da regra: com 2+ contas, quem montou a estrutura pedagógica pode aprovar a própria checagem pedagógica — fora das 3 identidades produtoras de FR-032-004 (lacuna de SPEC) | Q1 ao Diretor na Entrega. Default: brief avulso logo após o merge, obrigatório antes de um 2º ADMIN real operar; exposição nula com 1 ADMIN | PO, aceitação da F9 |
| TRISK-033-004 | Sinal de alteração da Tira compara `occurredAt` do último evento `TIRA_MNEMONICA` com `closedAt` (relógio de aplicação × relógio do banco), a mesma classe que a Emenda 2 da DEC-033-006 trocou por `sequence` para `CONTEUDO_BRUTO`; sem prova de interleaving. Sustenta a métrica-guarda (b) da SPEC-032 §1.3 | Risco prático baixo (exige skew maior que o intervalo fechamento→edição); próxima mudança em `resolveAlterationSignal` traz a comparação por `sequence` + teste de interleaving | code-reviewer (convergência de fecho) e PO |
| — | Verificação de tela pendente — HANDOFF-PLAN-031 (`docs/producao-material/handoffs/HANDOFF-PLAN-031.md`) — V1 (AC-030-012, login real por clique físico com e sem `next`): sandbox do subagent `qa` bloqueou digitação de credencial real em UI (causa `permissao_ambiente`, não indisponibilidade); evidência composta forte já obtida (POST real ao endpoint que `LoginForm` chama, direto e via proxy, 200 + cookies `HttpOnly` + role correta nos dois caminhos; guard `isSafeRelativePath`/`INTERNAL_HOME` coberto por teste automatizado sem regressão) · **V2 (KAN-185, TASK-031-008, branch `feat/producao-material-login-botao-entrando`)**: login de sucesso com o botão em "Entrando" — mesma causa; passos 1–7 do gate 9 VERIFICADOS em app real | roteiro completo no handoff; 1 clique real de login (com `next` e sem `next`) por alguém sem a mesma restrição de sandbox — Diretor ou sessão local, 2 min por item | HANDOFF-PLAN-031 |
| — | Borda de 1px do `SiteHeader` cruza a ilustração da lua em `/login` (achado do `product-designer`, verificado por captura real + medição de luminância) — comportamento pré-existente de TODAS as rotas (não é regressão nem parte deste diff), só fica mais visível sobre a ilustração noturna | Nenhuma — registrado a critério do Diretor, se quiser tratar em outra rodada | product-designer, convergência de fecho de PLAN-031 |
| — | Ausência de regra CSS `:-webkit-autofill`/`:autofill` nos campos de `/login` (`login-form.tsx`/`password-field.tsx`/`globals.css`) — risco plausível para o autofill do navegador sobrescrever o estilo em pílula, não confirmado empiricamente (Chromium headless não expõe o password manager nativo) | Verificar com navegador real + credencial salva; se confirmado, adicionar regra de override usando os tokens `night-pill-*` | qa, gate 9 de PLAN-031 (achado fora de escopo) |
| — | Verificação de tela pendente — HANDOFF-PLAN-013 (`docs/producao-material/handoffs/HANDOFF-PLAN-013.md`) — V1/V2 (instalação nativa, UI fora do alcance de Playwright headless) e V3/V4 (ciclo login/logout com SW ativo, bloqueado por `CORS_ORIGINS` de origem única do backend) | roteiro completo no handoff; exercitar em navegador real com backend aceitando a origem do frontend | HANDOFF-PLAN-013 |
| ~~TRISK-021-001/002~~ | **RESOLVIDO 2026-09-08** — verificação manual pós-deploy executada em produção real (`https://mnemonicos-frontend.vercel.app`): login legítimo grava os 2 `Set-Cookie` distintos (`mnemo_access`/`mnemo_refresh`, `httpOnly`/`Secure`/`SameSite=Lax`) sob o domínio do frontend; sessão reconhecida (`GET /api/v1/auth/me` → 200, redirect para `/studio`); requisição forjada de outra origem contra `POST /api/v1/auth/login` recusada (403, `verifyOrigin` intacto através do rewrite). | — nenhuma | Tech Lead, verificação direta em produção (curl + Playwright) |
| ~~TRISK-021-003~~ | **RESOLVIDO 2026-09-08** — Diretor confirmou `BACKEND_API_URL` configurada no painel Vercel do `mnemonicos-frontend` e redeploy feito. Causa raiz confirmada por evidência direta antes da correção: `X-Vercel-Error: DNS_HOSTNAME_RESOLVED_PRIVATE` no rewrite (fallback de dev local `http://localhost:3333` resolvendo para endereço de loopback, bloqueado pela proteção anti-SSRF da Vercel) — exatamente o modo de falha visível previsto na TASK. | — nenhuma | Diretor (config Vercel) + Tech Lead (diagnóstico e revalidação) |
| — | Paridade do prefixo `/api/v1` entre `next.config.ts:28` (`source`) e `store/api.ts:157-158` (literal em `resolveApiBaseUrl()`) sem tripwire — cada lado tem teste próprio, mas nenhum lê as duas fontes e compara; divergir os dois ao mesmo tempo derrubaria toda chamada de API em produção sem nenhum gate acusar. Não é gap (estado atual satisfaz o requisito), achado da passada de dedup da convergência de fecho de PLAN-021 | consolidação barata (~8 linhas, precedente no próprio repo: `sw-parity.test.ts`) — decisão do Diretor, diff novo | code-reviewer, convergência de fecho de PLAN-021 |
| — | 2 docblocks desatualizados por PLAN-021 em arquivos que ele não tocou: `src/lib/service-worker-policy.ts:26-30` e o bloco equivalente de `public/sw.js` (`isSameOriginRequest`) ainda afirmam que a API é cross-origin — DEC-021-001 tornou-a same-origin. Comportamento intacto e provado (`sw-parity.test.ts`), mas a garantia de NFR-013-001 (SW nunca cacheia resposta de API) passou de 2 camadas (origem + pathname) para 1 (só pathname) sem nada declarar isso | atualizar os 2 comentários; avaliar se a garantia de NFR-013-001 ainda precisa de 2 camadas — dono de SPEC-013, diff novo | code-reviewer, convergência de fecho de PLAN-021 |
| ~~RISK-006-008~~ | **RESOLVIDO 2026-09-05 — não era vulnerabilidade ativa.** O re-review do gate 1-7 da Wave 4 de PLAN-006 achou que a asserção estrutural de CSRF filtrava por "rota não-pública" (eixo de autorização), excluindo `/auth/login` e `/auth/refresh` (POST públicas) do escopo da prova — `/auth/refresh` sem nenhum teste dedicado. A investigação do BRIEF-007 confirmou que `POST /auth/refresh` **sempre teve** `verifyOrigin` como 1º handler, desde o commit original de F1 (`d2560a9`) — o gap era só na REDE DE PROVA, nunca na proteção real. | Diretor autorizou correção imediata (AskUserQuestion). BRIEF-007 (avulso, KAN-43): asserção estrutural generalizada para toda rota mutante montada (`ROUTES`, não `NON_PUBLIC`), pública ou não — fecha a classe inteira, não só esta rota. Gates 1-7/8 aprovados. | code-reviewer + security-engineer, BRIEF-007 |
| PIL-001 | Teste da tira aprovado sem limiar (Q-11) e cinco das seis métricas da §5.4 sem instrumento (Q-12) — não bloqueiam a SPEC, bloqueiam a conclusão do piloto | decidir antes do beta; retomar via /keelson:brief producao-material | BRIEF-001 |
| ~~RDR-001~~ | **RESOLVIDO 2026-09-01** — SPEC-005 A-005-001: as 5 classes da TAP são o dado persistido; as 3 prioridades do mockup são derivação de apresentação, exibição adiada para F10. Não é 2ª dimensão gravada. | selado (premissa com `Reabrir se:` F7/F10/F11 precisarem priorizar natureza acima de grau) | BRIEF-001 → SPEC-005 |
| RISK-005-001 | Colapso das 5 classes do radar numa prioridade única de apresentação: reverter o mapeamento exigiria reclassificação **manual** de todo o acervo já produzido (trabalho humano, A-007), não só migração de schema | classe das 5 fica persistida; exibição da prioridade adiada p/ F10; `Reabrir se:` em A-005-001 | SPEC-005 §9 |
| RISK-005-004 | **Reclassificado por SPEC-011 (2026-09-06), não baixado**: a fatia F4 não migra nem expurga dado — apenas desliga o `Mnemonic` legado da fábrica (já sem consumidor desde F2/A-005-013). Severidade cai de "duas representações vivas da fonte" para "dado dormente duplicado", sucedido por RISK-011-001. **F8 (SPEC-028) confirmou, em §4.2, que não é esta fatia** — destino segue em aberto (limpeza de schema dedicada), não mais "F8 ou..." | Baixa exige ato destrutivo (migração/expurgo) do Diretor, fatia de limpeza de schema dedicada | SPEC-005 §9 → SPEC-011 §9 → SPEC-028 §4.2 |
| RISK-011-001 | `Mnemonic.hook`/`decoding`/`source` permanecem no schema sem consumidor após F4 — dado dormente duplicado (sucessor de RISK-005-004) | Nomeado no Out-of-scope de SPEC-011; **SPEC-028 (§4.2) declarou que F8 não resolve isso** — revisitar em limpeza de schema dedicada | SPEC-011 §9 → SPEC-028 §4.2 |
| RISK-011-002 | Sem drag-and-drop, usabilidade de reordenar Tiras com mais Quadros do que o teto inicial de 5 pode ficar pobre com controles simples | Aceito nesta fatia; revisitar se o piloto (PIL-001) reportar atrito real | SPEC-011 §9 |
| RISK-011-003 | Atomicidade da reordenação (NFR-011-002) depende do mecanismo técnico que o PLAN escolher — estratégia sem reversão conjunta reabre o risco original do épico na prática | Gate de revisão de código do PLAN/TASKs deve provar a atomicidade, não apenas declará-la | SPEC-011 §9 |
| RISK-011-004 | Payload mínimo do evento de etapa (herdado de RISK-009-001) não distingue qual ação de CRUD gerou um retrabalho de "Tira mnemônica" | Aceito nesta fatia pelo mesmo motivo de RISK-009-001; gap só se soma para eventos futuros | SPEC-011 §9 |
| RISK-011-005 | Conflito de intenção na reordenação concorrente entre 2 EDITORES — last-write-wins sobre payload calculado contra conjunto de Quadros que já mudou | Aceito nesta fatia (operação de 1 pessoa, RISK-002-001); reabrir se o piloto rodar com 2+ editores simultâneos | SPEC-011 §9 |
| RISK-011-006 | Granularidade do retrabalho não comparável entre F2 (1 evento/salvamento de tela) e F4 (1 evento/mutação atômica de Quadro) — F10 não pode comparar CONTAGEM entre etapas sem normalizar | Duração (lead time) segue comparável; contagem não | SPEC-011 §9 |
| RISK-011-007 | Sem teto de Quadros por Tira nem limite de tamanho de texto por Quadro — unidade destinada a uma página do PDF de F5/F6 | Aceito nesta fatia; revisitável quando a paginação (F5/F6) existir | SPEC-011 §9 |
| ~~RISK-011-008~~ | ~~`mnemonic-strip-board.tsx` pode ter a mesma forma "`data` em cache + `isNotFound` derivado só de `error`, sem guarda de mutualidade"~~ — **RESOLVIDO 2026-09-15 (Wave 7 de PLAN-025, TASK-025-013)**: deixou de ser hipótese, confirmado por probe real (refetch 200→404 retinha `hasData=true` — RTK Query preserva `data` do último sucesso); corrigido derivando `hasData` de `isSuccess` em vez de `data !== undefined`, com teste que prova a mutualidade e a trava de reentrância no mesmo cenário | selado — nenhum caminho de leitura deixa `hasData`/`isNotFound` coexistirem `true` | code-reviewer, gate 1-7 Wave 7 de PLAN-025 (re-review) |
| TRISK-012-001 | `ALTER TYPE ProductionStageType ADD VALUE 'TIRA_MNEMONICA'` dentro de migração transacional pode exigir commit intermediário antes de uso na mesma sessão, dependendo da versão real do Postgres | TASK de migração aplica e testa a gravação com o valor novo logo em seguida; se recusado, dividir em 2 migrações sequenciais | PLAN-012 §8 |
| TRISK-012-002 | Reindexação em 2 fases (DEC-012-003) custa até 2×N `UPDATE`s por operação — sem medição real ainda, sem teto de Quadros (RISK-011-007) | Aceito nesta fatia (N esperado pequeno); performance-engineer mede round-trips reais no gate 10 | PLAN-012 §8 |
| TRISK-012-003 | Reindexação em 2 fases garante atomicidade por CHAMADA isolada, não resolve last-write-wins entre 2 chamadas concorrentes (mesma natureza de RISK-011-005) | Aceito (operação de 1 pessoa, RISK-002-001); revisitar se o piloto rodar com 2+ editores simultâneos | PLAN-012 §8 |
| TRISK-012-004 | Payload mínimo do evento (herdado de RISK-009-001/RISK-011-004) não distingue qual ação de CRUD gerou o retrabalho — este PLAN não resolve, só herda | Aceito, mesmo raciocínio de RISK-011-004 | PLAN-012 §8 |
| ~~TRISK-012-005~~ | ~~`GET /contents/:id/strip` com efeito colateral de geração~~ — **EXTINTO** (Entrega, ressalva R-1): DEC-012-009 supersedida por DEC-012-011 na Wave 5 (achado de CSRF, não o risco de cache que este item previa); GET virou leitura pura, geração migrou para POST | n/a — risco não existe mais na superfície atual | PLAN-012 §8 |
| ~~Q-005-004 (E-01)~~ | **RESPONDIDA 2026-09-06 (Entrega de PLAN-006)** — Diretor confirmou que o EDITOR PODE criar tema/assunto novo em disciplina existente. Reabre A-005-007 (SPEC-005) — mas **não** reabre PLAN-006 (já implementado e entregue sob o comportamento anterior, só seleção do acervo semeado, AC-005-027 provado). | Capacidade nova registrada em "Especificadas, ainda não planejadas" — entra num PLAN/brief futuro para decidir a forma (endpoint de criação de tema, validação/dedup, UI inline em `content/new`) | Diretor, Entrega de PLAN-006 |
| ~~TRISK-006-001~~ | **RESOLVIDO 2026-09-01** — Diretor confirmou "Gerar e executar" (ledger `intervencao` 2026-09-01T13:27:23Z, anterior à aplicação). Migração aditiva aplicada em dev + `mnemonicos_test`; auditada linha a linha pelo gate 8 (0 `DROP`/`ALTER` destrutivo). | — nenhuma | PLAN-006 §8 / Wave 1 |
| RISK-006-005 | `npm audit` do backend (pós-`npm ci` de recuperação, Wave 2) = 3 vulnerabilidades nas deps transitivas via `prisma` (1 high — mysql2 auth plugin downgrade; 2 moderate — mysql2 decompression bomb, `qs`). Não introduzidas por este diff (lockfile intocado) | `/keelson:audit` na Entrega; `fixAvailable` do npm exige downgrade maior de Prisma (7→6, inaceitável); superfície `mysql2` provavelmente inalcançável em projeto PostgreSQL — hipótese a confirmar, não medição | security-engineer, re-review Wave 2 |
| RISK-025-003 | `code-reviewer` (gate 1-7, Wave 6 de PLAN-025) achou 3 sinais de *staleness*/débito no frontend: (a) `guidelines/project/frontend/next-16.md` §7 prescreve `tests/components/<x>.test.tsx`, mas a casa real tem 12 arquivos co-localizados em `src/components` contra 2 em `tests/components`; (b) o mesmo §7 prescreve `user-event`, mas 4 arquivos (incl. o exemplar canônico da família, `visual-association-picker.test.tsx`) usam `fireEvent`, sem decisão declarada; (c) `renderWithProviders` (helper de `mount()`+`Provider`+`makeStore()`) foi previsto no perfil "a criar quando houver a 2ª cópia" — já são 9 cópias locais | atualizar o perfil (a/b) ou migrar os 4 arquivos; extrair `renderWithProviders` (c) — nenhum bloqueia esta wave, consolidação em diff próprio | code-reviewer, gate 1-7 Wave 6 de PLAN-025 |
| RISK-025-007 | `performance-engineer` (gate 10, Etapa 5/Entrega de PLAN-025, medido contra Postgres real) — sem teto de custo CUMULATIVO (bytes+pixels de imagem), uma Tira com N Quadros grande o bastante pode: (a) estourar o teto de duração interno mesmo após o fix do event-loop-yield (N=20 com imagem de 4,76 MB = 12080ms, bate o teto de 12000ms; resíduo de `doc.save()` sozinho ~3,1s, sem ponto de cessão possível); (b) chegar perto do teto de memória da function (872 MB de 1024 MB); (c) **o corpo de resposta (95,3 MB) já excede o limite de ~4,5 MB de function serverless da Vercel hoje, para qualquer Tira acima de ~1 Quadro com imagem de 5 MB** — item (c) é o mais grave: pode já falhar em produção mesmo sem volume extremo | **decisão de produto do Diretor, não corrigível dentro do escopo desta fatia**: teto de custo cumulativo (bytes+pixels) antes de compor e/ou mover a composição para job assíncrono com entrega por URL (perfil node-22.md §10: "trabalho longo não roda no request"); Q-024-001 (SPEC-024) deixa de ser questão aberta | performance-engineer, gate 10 Etapa 5/Entrega de PLAN-025 |
| ~~RISK-025-005~~ | ~~pool de compilação do Turbopack do servidor de dev do frontend permanentemente quebrado~~ (`turbopack.root` ausente) — **RESOLVIDO 2026-09-15**: fix de config commitado (`3115fec`) e Diretor reiniciou o servidor de dev (`npm run dev` limpo, sem o aviso de raiz ambígua); confirmado saudável servindo `/content/:id` e `/content/:id/tira` reais no exercício de gate 9 | selado — servidor de dev reiniciado, gate 9 exercitado com sucesso sobre ele | qa, gate 9 (re-verificação real, Entrega de PLAN-025) |
| RISK-025-004 | `product-designer` (gate 11, Wave 7 de PLAN-025, re-revisão do retry de TASK-025-013) achou que o feedback de uma exportação em voo (`isLoading`/`successMessage`/`errorMessage`, estado LOCAL de `PublicationExportControl`, COMP-025-010) se perde se o componente desmontar antes de resolver — 3 gatilhos mapeados em `mnemonic-strip-board.tsx`: remoção do último Quadro (`frames.length` 1→0), refetch que devolve 404, e erro real de leitura. Mesma classe já aceita no componente canônico (`content-form.tsx`: "Confirmar remoção" navega para `/content` e destrói o mesmo feedback) — não é regressão desta TASK, é debito pré-existente do componente compartilhado | follow-up sobre `publication-export-control.tsx` (COMP-025-010): elevar o resultado da exportação para um ponto que sobreviva ao desmonte, ou desabilitar o gatilho de remoção/navegação enquanto há exportação em voo — fora de escopo de PLAN-025, brief/ajuste pontual futuro | product-designer, gate 11 Wave 7 de PLAN-025 (re-revisão) |
| — | `product-designer`/`code-reviewer` (Wave 6): o estado de SUCESSO de `PublicationExportControl` (download real) só é confirmável em browser real — jsdom não distingue "revogou depois do clique" de "revogou cedo demais", nem se o download efetivamente inicia. `gates.screenVerify.enabled: true` — recomendado que o gate 9 confirme o download real das 2 Variantes antes da Entrega desta fatia | gate 9 (consolidado, Etapa 4) confirma em ambiente com tela; sem tela disponível, vira handoff | code-reviewer, gate 1-7 Wave 6 de PLAN-025 |
| RISK-025-002 | Confirmado por `security-engineer` (gate 8, Wave 2 de PLAN-025, com `provider = "postgresql"` em `schema.prisma:20` visto): `mysql2` (via `@prisma/client`) inalcançável nesta configuração — confirma a hipótese de RISK-006-005, rebaixa `high` catalogado para risco residual não-explorável. `qs` (via `express@5.2.1`) segue moderate e ALCANÇÁVEL (Express parseia query string com `qs`), com fix disponível sem downgrade major (`npm audit fix`) — não aplicado neste PLAN (fora do diff da wave, mudança de lockfile é ajuste pontual próprio) | rodar `npm audit fix` no backend como ajuste pontual antes do próximo PR, ou via `/keelson:audit` | security-engineer, gate 8 Wave 2 de PLAN-025 |
| ~~TRISK-006-003~~ | **RESOLVIDO 2026-09-05** — filtro `deletedAt = null` centralizado em `contents.service.ts` (helper reusado por T006/T008/T009, nunca recriado) e confirmado end-to-end na superfície HTTP por T011 (AC-005-031/037: conteúdo removido → 404 no acesso direto E na Quebra; linha órfã confirmada presente no banco mas inalcançável). Verificado ao vivo pelo `qa` (gate 9, execução real com Postgres). | selado — nenhum caminho de leitura ficou sem o filtro | PLAN-006 §8 / Wave 4-5 |
| ~~TRISK-006-004~~ | **RESOLVIDO 2026-09-05** — `domain-types-parity.test.ts` estendido a `PROOF_RADAR_CLASSES`/`NORMATIVE_SOURCE_TYPES` (TASK-006-007); rede equivalente criada para as INTERFACES de F2 (`contents-frontend-contract.test.ts`, Wave 3 retry) — gap que DEC-006-005 tinha deixado aberto (interfaces fora do escopo original da DEC) e que causou a reprovação inicial da Wave 3. | selado — nenhuma condição de reabertura pendente | PLAN-006 §8 / Wave 3 |
| RISK-006-006 | Contrato cross-repo por leitura de texto (`domain-types-parity.test.ts`, `contents-frontend-contract.test.ts`) prova DECLARAÇÃO×DECLARAÇÃO, não `select`×declaração — uma chave nova no `select` do Prisma sem a mesma chave na interface do frontend passa pelo typecheck (extra property em valor não-literal) e pelos dois testes. Achado do code-reviewer (re-review Wave 3), declarado como "próximo degrau da rede, não gap desta rodada" | disciplina de mesmo-diff continua sendo a defesa; revisitar se doer (campo novo no backend some silenciosamente do frontend) | code-reviewer, re-review Wave 3 |
| RISK-006-007 | **Causa raiz identificada** (code-reviewer, BRIEF-007) — não é acúmulo de conexão do `withQueryProbe` (hipótese original): é `TRUNCATE ... CASCADE` concorrente sobre o mesmo `mnemonicos_test` quando 2+ runners de integração rodam em paralelo (gates/worktrees da mesma wave). `maxWorkers: 1` do Jest só serializa DENTRO do processo — nada impede runners de processos distintos se truncarem mutuamente, produzindo violação de FK / deadlock que imita bug de produto. Reproduzido 2× com processos `node` alheios ativos; 213/213 em janelas ociosas | todo harness que roda DDL/TRUNCATE em schema compartilhado precisa de exclusividade REAL — banco por execução (nome derivado de PID/worker em `db-url.ts`) ou `pg_advisory_lock` no `globalSetup`/`globalTeardown`; gate que observar vermelho de integração não-determinístico confirma ausência de runner concorrente antes de emitir veredito | code-reviewer, BRIEF-007 (reforça achado do security-engineer, re-review Wave 3) |
| RISK-006-009 | Nenhum dos dois repos (`mnemonicos-backend`, `mnemonicos-frontend`) tem pipeline de CI configurado (sem `.github/workflows` nem equivalente) — condição de projeto pré-existente, achada na Etapa 4 (DoD) de PLAN-006 ao validar a cláusula "verde no CI" da métrica §1.3/SPEC-005 (item (a): tripwire `route-authz-matrix` 19/19, mas só localmente). Toda suíte (unit/integração dos 2 repos) só roda sob comando manual | decisão de infra do Diretor: configurar CI (ao menos lint+test+build nos 2 repos) antes do próximo PLAN, ou aceitar o gap conscientemente por mais um ciclo | Tech Lead, Etapa 4/Entrega de PLAN-006 |
| ~~RISK-002-001~~ | **RESOLVIDO 2026-09-27 por SPEC-032** — segregação de funções aplicada pelo sistema (fail-secure): aprovador ≠ nenhuma identidade produtora do conteúdo (quem fechou, autor original, último editor). Residual aceito: com 1 ADMIN só, a métrica de adoção fica em 0% por construção (RISK-032-001), e a segregação compara CONTA, não pessoa (RISK-032-005, conta-fantoche) | Ver RISK-032-001/RISK-032-005 | SPEC-002 §9 → SPEC-032 |
| RISK-002-002 | Token de renovação persistido é superfície de dado sensível — vazamento do repositório permitiria continuar sessões | guardar só o necessário, valores não reversíveis onde viável, revogar família em reuso, expiração absoluta curta (7 dias) | SPEC-002 §9 |
| RISK-002-003 | Dependências novas de criptografia/sessão (derivação de senha, geração de token, leitura de cookie) entram na árvore — superfície de cadeia de suprimento | gate de auditoria de dependências sobre o diff de F1 (/keelson:audit); fixar versão e revisar | SPEC-002 §9 |
| TRISK-003-001 | `trust proxy: 1` pode ser o nº errado de proxies no deploy — erra `req.ip` e recoloca o bypass do freio de login; contador do rate-limit é por instância em serverless | verificar no ambiente real; store compartilhado para proteção multi-instância (fora do escopo de F1) | PLAN-003 §8 |
| TRISK-003-002 | Cookie cross-domain (SameSite=None + anti-CSRF) não desenhado; F1 assume mesmo site | verificação de `Origin`/`Host` nas rotas POST de auth agora; token anti-CSRF quando o deploy for cross-domain | PLAN-003 §8 |
| ~~HANDOFF-003~~ | **RESOLVIDO 2026-09-01** — `HANDOFF-PLAN-003` `status: Concluído`. V1–V5 OK na tela (Playwright, código mergeado: login→`/studio`, mensagem genérica sem enumeração, guard redireciona anônimo, vista protegida renderiza, logout de sucesso → `/login` exato com 0 `refresh` e sessão revogada). V6 `n/a` (coberto por `internal-shell.integration.test.tsx`). O V5 foi corrigido em BRIEF-004 (mergeado, PR #2 `f60659c`). | — nenhuma | qa + Playwright 2026-09-01 |
| RISK-002-003-audit | `/keelson:audit` sobre o diff de F1 (3 deps novas de cripto/sessão: `@node-rs/argon2`, `cookie-parser`) — DoD do PLAN-003 sem ato registrado (E2 do PO). `npm audit --omit=dev --audit-level=high` no backend = 0 vulns (2026-08-31); falta a revisão de cadeia de suprimento | ato do Diretor: rodar `/keelson:audit` antes do merge (o assistente não pode invocá-lo) | PO (Entrega F1) |
| MET-002-001 | Veredito da métrica §1.3 da SPEC-002 pendente — a fonte (`route-authz-matrix` 28/28 verde) prova **conformidade** (deny-by-default aplicado), não o número de negócio da §1.3. Cobrança aberta neste ciclo (decisão 4.99): SPEC-005 Q-005-001 repassa ao Diretor na **Entrega de F2**, junto de E-01 | veredito ao Diretor na Entrega de F2 (`/keelson:auto`, item 6.4) | PLAN-003 §9 / SPEC-002 §1.3 |
| ~~TRISK-010-001~~ | **RESOLVIDO 2026-09-06** — medido (n=300, banco isolado): criação 4,16→21,74ms/1→8 round-trips; conexão presa ~16-22ms; folga de ~3 ordens de grandeza sobre uso real. | `Reabrir se:` F10 introduzir emissão automatizada/em lote | PLAN-010 §8, gate 10 Wave 3 |
| TRISK-010-002 | Leitura interna (`listProductionStageEvents`) não pagina — FR-009-010 proíbe agregação, mas não previu paginação | aceito nesta fatia (sem consumo real ainda); F10 decide se precisa paginar quando existir consumidor | PLAN-010 §8 |
| TRISK-010-003 | Sem painel/consumo nesta fatia, evento não emitido ou com tipo errado passaria despercebido até F10 expor os dados (herdado de RISK-009-002) | cobertura de teste dos 5 gatilhos + fail-secure é condição de pronto (COMP-010-006), não opcional — **verificado, gate 8/1-7 Wave 3 confirmaram por mutation testing** | PLAN-010 §8 |
| TRISK-010-004 | Rede de paridade cross-repo (COMP-010-005) nasce autoconsistente (backend-only), não comparativa, por causa do adiamento do espelho frontend (DEC-010-006) — risco de não pegar drift real com o frontend até o espelho existir | comentário explícito no teste apontando a condição de upgrade; DEC-010-006 registra o gatilho (F10 consumir os tipos no frontend) | PLAN-010 §8 |
| ~~TRISK-010-005~~ | **RESOLVIDO 2026-09-06** — provado por mutation testing (gate 8 Wave 3): mutante que reordena a emissão antes do upsert mata o teste de concorrência real. Emergente por chamador — 3º consumidor futuro (F4-F9) que emitir antes de escrever pode reabrir. | `Reabrir se:` `stageType` novo cujo chamador emita antes da escrita de negócio — considerar índice único parcial | PLAN-010 §8, gate 8 Wave 3 |
| TRISK-010-006 | Recomputo: 1º salvamento relê histórico que a própria criação acabou de escrever na mesma tx (3 SELECTs/criação, 24% do tempo) — custo de DEC-010-005, não do developer | aceito — `Reabrir se:` volume real esbarrar no teto do pool (hoje ~3 ordens de grandeza de folga) | PLAN-010 §8, gate 10 Wave 3 |
| TRISK-010-007 | `recordProductionStageEvent` materializa todo o histórico do par para decidir entre 3 estados — O(n²) acumulado com retrabalho alto | aceito nesta faixa (2-13ms medidos até 5k eventos); correção de 1 linha (`distinct`) disponível se necessário | PLAN-010 §8, gate 10 Wave 3 |
| ~~E-02 (SPEC-009)~~ | **RESPONDIDA 2026-09-06 (Entrega de F3)** — Diretor confirmou os 2 pontos que o PO escalou na aprovação de SPEC-009: (1) a série capturada mede **lead time** (calendário) por etapa, não esforço — mantido; (2) emissão do evento **atômica com fail-secure** — mantido. Ambos já implementados de fato (confirmado pela convergência de fecho), nenhuma mudança de código necessária. | — nenhuma | Diretor, Entrega de F3 |
| E-01 (SPEC-011) | PO escalou (não-bloqueante, vai à Entrega de F4): antes do piloto, produto precisa fixar o que conta como "tira" no A/B (A-012) e o limiar de aprovação de Q-11 — a tira default gerada por F4 é a Quebra da regra reorganizada em linhas (mesmo texto), risco de o A/B comparar tira × resumo textual quando as duas coisas podem ser o mesmo conteúdo empilhado | Default do PO: seguir F4 como está; elegibilidade do A/B fica restrita a Tiras que alcançaram CONCLUSÃO da etapa E cujos Quadros divergem do texto do Bloco de origem (§1.3 de SPEC-011, itens i/ii) — resposta ao Diretor na Entrega de F4 | PO, aprovação de SPEC-011 |
| Q-011-001 | SPEC-011 assume que nenhuma outra superfície (fora da fábrica) ainda lê `Mnemonic` legado — scheduler/revisão espaçada seguem dormentes (A-005). Se isso mudar, a reclassificação de RISK-005-004 precisa ser revisitada antes de remoção física futura | acompanhar se alguma tela do estudante voltar a depender de `Mnemonic` | SPEC-011 §9 |
| RISK-013-001 | Sem caso de uso de produto identificado (A-013-001), a capacidade PWA pode nunca ser usada organicamente | revisitar quando um caso de uso real aparecer; métrica observacional §1.3(b), janela 90 dias, valor de partida 0 | SPEC-013 §9 |
| RISK-013-002 | Cobertura de navegador desigual (Safari com suporte parcial ao manifesto/instalação) | aceito nesta fatia (A-013-005); revisitar se uso real em Safari/iOS for reportado | SPEC-013 §9 |
| RISK-013-003 | Sem controle de instalação custom, a descoberta da instalabilidade depende só da heurística do navegador | aceito nesta fatia, coerente com A-013-001; revisitar se adoção real for baixa | SPEC-013 §9 |
| RISK-013-004 | Recuperação de service worker quebrado (NFR-013-006) depende de deploy manual do Diretor — sem CI/CD (RISK-006-009) | aceito nesta fatia; revisitar quando o projeto ganhar pipeline de CI/CD | SPEC-013 §9 |
| RISK-013-005 | Ordem de merge com PLAN-012 (F4, mesma superfície `app/`/layout do frontend) | branches isoladas em worktrees distintas evitam conflito no desenvolvimento; ordem de merge é ato do Diretor | SPEC-013 §9 |
| RISK-013-006 | Sob aba viva, o navegador pode pedir um chunk já purgado pelo servidor (condição pré-existente, agravada pela expectativa de continuidade de NFR-013-003) | aceito nesta fatia; se ocorrer, o usuário recarrega a aba | SPEC-013 §9 |
| E-01 (SPEC-013) | PO escalou (não-bloqueante, vai à Entrega): qual a origem HTTPS real de produção do `mnemonicos-frontend` — não confirmada em nenhum artefato do workspace (único deploy registrado é do backend, `infra-vercel/BRIEF-001`) | Default do PO: seguir com A-013-006 registrando "não confirmada"; AC-013-001/002 fecham em `localhost`; prova na origem real e início da janela de 90 dias da métrica ficam como pendência de handoff ao deploy | PO, aprovação de SPEC-013 |
| E-01 (SPEC-016) | PO escalou (não-bloqueante, vai à Entrega): KAN-72 fecha entregando só o toggle no `LoginForm`, ou nasce card de follow-up para as telas de troca de senha/gestão de contas — a capacidade já existe na API (`POST /auth/change-password`, `POST /users/:id/reset-password`) e nos hooks RTK Query (`api.ts:406,430`), só falta a tela | Default do PO: fechar KAN-72 com o `LoginForm` e não criar card novo — expectativa registrada em Q-016-001 | PO, aprovação de SPEC-016 |
| E-019-01 (SPEC-019) | PO escalou (não-bloqueante, vai à Entrega): aceita que a 404 personalizada NÃO apareça para quem não tem sessão e erra a URL sob `/studio/**` ou `/content/**` (continua indo para `/login?next=<path>`, como hoje) — servir 404 antes do guard exigiria tirar os prefixos internos do matcher de `proxy.ts:56`, regredindo SPEC-002/FEAT-002-002 e revelando rotas internas a anônimo (A01) | Default do PO: manter SPEC-002 prevalecendo, AC-019-001 partido em 2 cenários (público sempre; interno com sessão) — não bloqueia o `/keelson:plan` | PO, aprovação de SPEC-019 |
| RISK-019-002 | A home pública (`/`) hoje não tem link de volta à área interna (`/studio`) — o CTA sensível a sessão de BRIEF-015/KAN-74 está implementado mas ainda não mergeado no `main` do frontend; até lá, EDITOR/ADMIN que sai da 404 personalizada chega a `/` sem caminho direto a `/studio` (2 cliques via `/login`, não 1) | Nenhuma ação desta SPEC; merge de KAN-74 fecha a lacuna por conta própria | SPEC-019 §9, sugestão S-01 do PO |
| RISK-022-001 | Categoria como texto livre sem normalização pode fragmentar a navegação por categoria se o acervo crescer sem curadoria | mitigado por FR-022-025 (sugestão de categorias existentes) e NFR-022-007 (normalização trim/case-fold no filtro); decisão técnica de implementação fica com o PLAN | SPEC-022 §9 |
| RISK-022-002 | Métrica primária "uploads evitados" depende da disciplina de busca do EDITOR antes de subir imagem nova — se ele não busca antes, sempre cria nova mesmo havendo equivalente | mitigado em parte por FR-022-025; aceito nesta fatia, revisitar se o piloto mostrar baixo reuso | SPEC-022 §9 |
| RISK-022-003 | Teto de tamanho de arquivo (5 MB, A-022-005) é estimativa sem dado real; se o motor de PDF (F6) exigir resolução maior, pode precisar subir | reabrir a validação de tamanho (e possivelmente a decisão de armazenamento, A-022-003) se/quando F6 exigir | SPEC-022 §9 |
| RISK-025-001 | `security-engineer` (gate 8, Wave 2 de PLAN-025) achou que o teto de 5 MB de F5/`visual-associations` limita bytes COMPRIMIDOS do upload, não DIMENSÃO decodificada — decompression bomb via PNG (poucos KB comprimidos, cabeçalho declarando dimensão gigante) passa pela admissão de F5 intacto; F6 (`pdf-composer.ts`) ganhou teto de pixels antes do decode (achado ALTA, corrigido no retry de TASK-025-007), mas a ADMISSÃO do upload em F5 continua sem esse teto | fora de escopo de PLAN-025 (não mexer em F5 já mergeado); considerar teto de dimensão na admissão do upload (`visual-associations.routes.ts`) numa fatia/brief futuro | security-engineer, gate 8 Wave 2 de PLAN-025 |
| RISK-022-004 | Reuso da mesma associação visual em Quadros/Tiras diferentes reduz a rastreabilidade de "quem introduziu a imagem originalmente" por vínculo | sem requisito de proveniência de autoria por vínculo nesta fatia; pode importar para F8/F9 | SPEC-022 §9 |
| RISK-022-005 | Listagem de associações visuais com miniatura (sem processamento/thumbnail derivado) tem custo de banda real em acervo grande com arquivos de até 5 MB | atenção obrigatória do gate 10 (performance) e do PLAN, junto com Q-022-001 (paginação) | SPEC-022 §9 |
| Q-022-001 | Volume do acervo pode exigir paginação/ordenação na listagem/filtro da biblioteca — não decidido na SPEC | fica para o PLAN avaliar o volume esperado | SPEC-022 §9 |
| E-01 (SPEC-022) | PO escalou (não-bloqueante, vai à Entrega de F5): o acervo de associações visuais é de leitura/busca/vínculo comum a todo EDITOR/ADMIN, mas a escrita (editar/substituir/remover) é restrita ao autor — alternativa seria escrita também comum, ou acervo totalmente privado por autor | Default do PO: acervo comum na leitura, escrita restrita ao autor (ADMIN alcança tudo) — já implementado na SPEC (FR-022-023, A-022-011); resposta ao Diretor na Entrega de F5 | PO, aprovação de SPEC-022 |
| E-02 (SPEC-022) | PO escalou (não-bloqueante, vai à Entrega de F5): a instrumentação de etapa desta fatia (evento na 1ª mutação de vínculo) entra já nesta fatia, ou fica declaradamente fora do escopo — instrumentar depois não recupera o passado | Default do PO: instrumentação mínima entra nesta fatia — já implementado na SPEC (FR-022-024, A-022-012); resposta ao Diretor na Entrega de F5 | PO, aprovação de SPEC-022 |
| TRISK-023-002 | `multer` (parser multipart) é dependência nova no backend — supply chain de primeira classe (A03) | `/keelson:audit` no gate 8 antes do merge; `memoryStorage()` nunca `diskStorage()` | PLAN-023 §8 |
| TRISK-023-006 | `route-authz-matrix.integration.test.ts` (tripwire, hoje 25 pares) precisa crescer para as 8 chaves novas de F5 (6 de `visual-associations.routes.ts` + 2 de `tira.routes.ts`) | TASK de rotas atualiza o tripwire junto; suíte acusa se alguma ficar de fora | PLAN-023 §8 |
| RISK-024-001 | Variantes "tira" e "resumo" podem ficar informacionalmente quase idênticas quando a Tira nunca foi editada por humano, ameaçando o isolamento da variável do A/B (A-012) — mesma classe de E-01/SPEC-011. **Elevado pelo `po` na aceitação de PLAN-025 (E-2): agora sustenta código entregue, não só premissa de SPEC** — proposta: assim que a migração for aplicada, gerar os 2 PDFs de um mesmo Conteúdo bruto real e o Diretor julgar lado a lado se são materiais distintos o bastante para o piloto | A-024-006 declara a composição pretendida; decisão final sobre o que o A/B compara cabe ao Diretor, junto de E-01/SPEC-011 — resposta fecha os dois de uma vez | SPEC-024 §9 · po, aceitação de PLAN-025 |
| RISK-025-006 | `po` (aceitação de PLAN-025, E-3): Associação visual em formato WEBP (aceito no upload de F5) ou acima do teto de pixels nunca aparece no PDF — degradação para só-texto é silenciosa para o EDITOR, só há log no backend; decisão de formatos aceitos é de F5, não desta fatia | registrar como pendência de produto para F5/F7 (restringir upload a PNG/JPEG, ou converter na publicação); nesta fatia, no máximo um aviso visível ao EDITOR quando uma imagem foi descartada — não implementado, fora de escopo de PLAN-025 | po, aceitação de PLAN-025 |
| RISK-024-002 | O motor de PDF concreto (DEC do PLAN) pode não sustentar por padrão a postura "sem rede/sem template executável" (NFR-024-001/002) — a escolha da biblioteca não elimina a necessidade de prova no gate 8 | PLAN prova a postura por biblioteca escolhida; gate 8 confirma | SPEC-024 §9 |
| RISK-024-003 | Geração automática da Tira na exportação (FR-024-006) pode surpreender um EDITOR que só queria "resumo" — mitigado parcialmente por FR-024-013 (não distorce a métrica de tempo-por-etapa de F3/F10) | Aceito nesta fatia; sem tela de confirmação prévia | SPEC-024 §9 |
| RISK-024-004 | Sem teto de tamanho de texto por Quadro (RISK-011-007 parcialmente resolvido por FR-024-016 — 1 Quadro = 1 página), Quadro com texto muito longo pode gerar leiaute pobre | Revisitável quando o PLAN escolher o motor | SPEC-024 §9 |
| RISK-024-005 | Falha segura (FR-024-009 — nunca entregar PDF parcial) depende do motor escolhido suportar geração atômica da resposta | PLAN prova; SPEC só declara o comportamento observável exigido | SPEC-024 §9 |
| RISK-024-006 | Escolha do motor de PDF no PLAN fixa, na prática, o padrão visual das 10 camadas do método (nomeado "irreversível na prática" pelo épico) | DEC do PLAN que escolhe o motor deve apresentar essa consequência entre as alternativas avaliadas | BRIEF-2026-08-27-epico (Riscos por fatia, F6) → SPEC-024 §9 |
| RISK-024-007 | Herdado de RISK-022-003: teto de 5 MB / resolução da imagem de F5 pode não bastar para impressão de qualidade a partir do PDF de F6 (NFR-024-004 proíbe reprocessamento nesta fatia) | `Reabrir se:` verificação real de impressão mostrar resolução insuficiente — reabre A-022-003/A-022-005, não SPEC-024 | SPEC-022 §9 → SPEC-024 §9 |
| Q-024-001 | Teto de tamanho de texto por Quadro (paginação já fixada em 1 Quadro/página por FR-024-016) fica para o PLAN — não fecha o denominador de "página" da régua de tempo-por-página de F10 | PLAN avalia junto da escolha do motor | SPEC-024 §9 |
| E-024-01 | `po` escalou (degrau 2, default aplicado — vai à Entrega de F6): a auto-geração da Tira mnemônica pela exportação (FR-024-006) deve, ou não, emitir o evento de abertura da etapa de produção "Tira mnemônica" (afeta a série de tempo-por-etapa de F3/F10)? | Default aplicado: **não** emite abertura na auto-geração via exportação (FR-024-013, correção aditiva sobre FR-011-008/SPEC-011) — confirmação ou reversão do Diretor na Entrega de F6 | po, aprovação de SPEC-024 |
| RISK-026-001 | Soft-delete do Conteúdo bruto titular torna o Contraste inalcançável junto; reverter A-026-004 para vínculo estruturado exige re-vinculação MANUAL de todo Contraste já escrito (mesma classe de custo de RISK-005-001) | Aceito nesta fatia; reabrir se: antes de F8, ou ao 1º pedido real de Contraste entre 2 Conteúdos brutos estruturados | SPEC-026 §9 |
| RISK-026-003 | Protocolo impresso sem persistência (A-026-006) — customizar os 6 Marcos por Conteúdo bruto no futuro exige retrofit de modelo de dados | Aceito nesta fatia, a TAP não pede customização hoje | SPEC-026 §9 |
| RISK-026-004 | Concorrência de 2 EDITORES editando a Pegadinha elaborada do mesmo Conteúdo bruto (campo único) resolve por last-write-wins (herda RISK-011-005) | Aceito nesta fatia (operação de 1 pessoa); revisitar se o piloto rodar com 2+ editores simultâneos | SPEC-026 §9 |
| RISK-026-005 | Flashcards sem teto (FR-026-014) somados a Contraste/Pegadinha/Protocolo agora todos exportados amplificam RISK-025-007 (limite de corpo de resposta serverless da Vercel) | Sem teto nesta fatia (default do `po`, E-03); decisão de introduzir teto fica com quem fechar RISK-025-007 antes do deploy em produção | SPEC-026 §9, po (E-03) |
| E-026-01 | `po` escalou (degrau 2, default aplicado — vai à Entrega de F7): Contraste e Pegadinha elaborada também devem sair impressos no PDF (não só Flashcard/Protocolo)? | Default aplicado: **sim** — FR-026-026/027/028 acrescentados, os 4 conceitos entram na Exportação | po, aprovação de SPEC-026 (E-01) |
| E-026-02 | `po` escalou (degrau 2, default aplicado — vai à Entrega de F7): a autoria desta fatia (Contraste/Pegadinha/Flashcard) deve emitir evento de etapa de produção, como F4/F5/F6 fizeram? | Default aplicado: **sim** — FR-026-029/NFR-026-005, novo valor aditivo no `ProductionStageType` | po, aprovação de SPEC-026 (E-02) |
| TRISK-027-001 | `ALTER TYPE ... ADD VALUE` do Postgres não pode ser usado na mesma transação em que o novo valor (`MATERIAL_REFORCO`) é lido/escrito | Mesma mitigação já aplicada em `ASSOCIACAO_VISUAL`/`PUBLICACAO_PDF`: valor só referenciado pelo código após a migração já aplicada num deploy anterior | PLAN-027 §8 |
| TRISK-027-002 | Volume de Contraste/`ProductionFlashcard` sem teto (FR-026-014) amplifica RISK-025-007/RISK-026-005 (limite de corpo de resposta serverless da Vercel) | Decisão de introduzir teto fica com quem fechar RISK-025-007, fora deste PLAN | PLAN-027 §8 |
| TRISK-027-004 | Guarda de leitura de Contraste/`ProductionFlashcard`/Pegadinha (autoria herdada de `RawContent`, DEC-027-005) diverge da leitura irrestrita de `VisualAssociation` (F5) dentro do mesmo slug | DEC-027-005 documenta a distinção explicitamente; risco de confusão em extensão futura que copie o padrão errado | PLAN-027 §6, §8 |
| TRISK-027-005 | Merge de 2 `PDFDocument`s (principal + suplementar) via `copyPages` pode tensionar NFR-026-003 (teto de duração já existente da Exportação) em Tiras grandes | Medir com teste de performance na implementação (gate 10), mesma régua de DEC-025-002 | PLAN-027 §8 |
| — | **Pendência de veredito de métrica** (SPEC-026 §1.3, `Fonte de medição: instrumentação`): "≥50% dos Conteúdos brutos ativos com Quebra da regra salva ganham 1+ Flashcards", medido 6 SEMANAS após o lançamento em produção desta fatia (A-026-010, §8 — estimativa sem medição prévia, nunca meta garantida). Consulta executável já confirmada contra o schema real na Entrega (`prisma.productionFlashcard.groupBy` cruzado com `rawContent.count` filtrado por `breakdown: { isNot: null }`), mas sem dado real de produção ainda (feature não deployada) | Cobrar o Veredito de métrica no ciclo seguinte deste slug, 6 semanas após o deploy em produção — não antes | SPEC-026 §1.3/§8, Etapa 5 de `/keelson:integrate` (Entrega de PLAN-027) |
| RISK-027-009 | `npm audit --omit=dev` do FRONTEND na Entrega de PLAN-027 = 2 vulnerabilidades: **1 CRÍTICA** (`next@16.3.6` — RCE não-autenticado em servidor hospedado no Windows + RCE na API de otimização de imagem com AVIF, GHSA-p293-qw3h-jr36/GHSA-2xp9-vwfh-vxw4) e 1 alta (`sharp` — GHSA-rgj7-g3m4-5g8c, libheif). Não introduzidas por este diff (`package.json`/lockfile do frontend intocados por PLAN-027 — confirmado em 5 gates de segurança ao longo do ciclo). Nunca antes registrada no INDEX (achado novo desta Entrega, não do ciclo) | Ambos os fixes disponíveis SEM major bump (`npm audit fix`, sem `--force`) — ajuste pontual antes do merge, ou via `/keelson:audit`; a crítica do Next.js merece prioridade alta independente deste PLAN (produção não roda em Windows, mas a superfície de otimização de imagem AVIF é alcançável se o app aceitar upload/URL de imagem) | Tech Lead, Etapa 2 de `/keelson:integrate` (Entrega de PLAN-027) |
| RISK-027-011 | `npm audit --omit=dev` do BACKEND na Entrega de PLAN-027 = 3 vulnerabilidades: 1 alta (`mysql2` — downgrade de auth plugin vazando credencial em texto claro + DoS por zlib inflate ilimitado, dependência TRANSITIVA do Prisma mesmo num projeto 100% PostgreSQL) e 2 moderadas (`qs` — bypass de array-limit + DoS via `isBuffer`). Confirmado PRÉ-EXISTENTE em `main` (`5d6b4df`, checado em worktree isolado) — não introduzido por PLAN-027 (`package.json`/lockfile do backend intocados, `git diff main..HEAD` vazio nesses arquivos) | `qs` corrige sem breaking change (`npm audit fix`); `mysql2` exige bump do Prisma (`npm audit fix --force`, "breaking change" reportado pelo npm) — avaliar se vale a pena isolar o driver mysql2 (dependência morta, projeto não usa MySQL) em vez de subir o Prisma inteiro | Tech Lead, Etapa 2 de `/keelson:integrate` (Entrega de PLAN-027) |
| TRISK-027-006 | `code-reviewer` (gate 1-7, Wave 5 de PLAN-027) achou que a Exportação passou a DESENHAR o texto de Contraste/Flashcard/Pegadinha (TASK-027-006) — a fonte `StandardFonts.Helvetica`/WinAnsi (cp1252) usada por `pdf-composer.ts` não codifica caracteres fora dela (ex.: `→` U+2192, `≠` U+2260, confirmado por execução: `page.drawText` lança). Os 3 schemas de escrita (Contraste/Flashcard/Pegadinha, TASK-027-003/004/005, já Done) aceitam QUALQUER string sem restrição de charset — um único registro com esse caractere derruba a Exportação inteira nas 2 Variantes, sem que nada tenha impedido a gravação. TRISK-025-007 (mesma limitação, já aceita para conteúdo pré-existente) não foi estendido pelo PLAN-027 a estes 3 campos novos | **Decisão de produto do Diretor, não corrigível dentro do escopo de PLAN-027 fechado**: validar/sanear o charset no schema de escrita (TASK futura) e/ou trocar a fonte por uma com cobertura Unicode ampla, e/ou aceitar o risco declarado até a Exportação virar caminho quente para EDITORES que digitam esses caracteres | code-reviewer, gate 1-7 Wave 5 de PLAN-027 |
| TRISK-027-007 | `code-reviewer`/`security-engineer` (Wave 5): DEC-027-005 (leitura DIRETA de Contraste/Flashcard/Pegadinha restrita ao autor-ou-ADMIN, decisão explícita de não abrir "porta lateral") diverge de COMP-027-018/DEC-025-007 (a Exportação lê os mesmos 3 registros SEM `scopeWhere`, para qualquer EDITOR/ADMIN que exporte o Conteúdo) — um EDITOR B que exporta o Conteúdo de A recebe, dentro do PDF, os Contrastes/Flashcards/Pegadinha que A escreveu e que B não alcançaria pela rota direta. Ambas as decisões estão documentadas e a leitura sem escopo é o que a TASK prescreveu (SPEC A-026-009: "qualquer um vê, independente de quem criou") — não é bug, é divergência de alcance entre 2 DECs do mesmo PLAN, nunca confrontada explicitamente | Confirmar com o Diretor se esse é o alcance pretendido (exportação como "visão agregada" que ultrapassa a autoria) ou se DEC-027-005 deveria valer também para a Exportação | code-reviewer + security-engineer, Wave 5 de PLAN-027 |
| RISK-027-008 | `code-reviewer`/`product-designer` (Wave 5, rodada 2): o achado alta do gate 11 (Pegadinha sem rótulo, indistinguível do texto principal) foi corrigido com título de seção — mas a página de TRANSBORDO da seção Pegadinha (quando o texto é longo o bastante para virar página) NÃO repete o título, e `updatePegadinhaSchema` não limita tamanho — resíduo do mesmo risco pedagógico, agora restrito a Pegadinha longa | Decisão do `product-designer`/PO: repetir o título no transbordo (mesma régua de custo zero do achado original) ou aceitar como risco residual de baixa incidência | code-reviewer + product-designer, Wave 5 de PLAN-027 (re-review) |
| RISK-027-010 | `code-reviewer` (verificação do retry de TASK-027-008, Wave 7): confirmado por sonda que `content-form.tsx` hidrata os campos do próprio Conteúdo bruto (`rawText`/`topicId`/`radarClass`/`source*`) a partir do cache UMA VEZ (guard `hydrated`, :145-155) — na revisita, mesmo com `refetchOnMountOrArgChange` já ligado (TASK-027-008), esses campos continuam mostrando o valor VELHO; só `PegadinhaField`/painel suplementar (que leem a prop, não hidratam estado local) ficam frescos. Território FR-005/F2 (`SPEC-005`, PLAN-006, já entregue), **fora do escopo de SPEC-026/PLAN-027** — não bloqueia esta Entrega, mas a tela hoje fica inconsistente (Pegadinha fresca, form do Conteúdo bruto velho) e um "Salvar" nesses campos sobrescreve mudança de outro escritor sem tê-la exibido | Decisão do Diretor/PO: gate na hidratação por `isFetching`/`fulfilledTimeStamp` no 1º mount, ou aceitar como risco de F2 pré-existente (comportamento não piorado por PLAN-027, só ficou mais visível ao lado da Pegadinha agora fresca) — candidato a brief avulso ou próxima fatia que tocar `content-form.tsx` | code-reviewer, verificação de TASK-027-008 (Wave 7 de PLAN-027) |
| — | `code-reviewer` (Wave 5): `tests/integration/contrasts.service.integration.test.ts:37` e `flashcards.service.integration.test.ts:38` continuam com `seedContrast`/`seedFlashcard` LOCAIS, equivalentes ao helper canônico `tests/support/material-reforco-fixtures.ts` que a Wave 5 criou — migração explicitamente aceita como fora de escopo pela régua da rodada 1, mas segue pendente | Migrar os 2 arquivos para importar do helper compartilhado — candidata a diff de limpeza na convergência de fecho do PLAN, ou task própria | code-reviewer, Wave 5 de PLAN-027 |
| RISK-028-001 | Decisão entre snapshot imutável e referência mutável (A-028-004) ainda não tomada — muda a forma como o histórico de Versões preserva (ou não) o texto de Versões anteriores | Decisão arquitetural irreversível, cabe ao PLAN-028 com alternativas explícitas | SPEC-028 §9 |
| RISK-028-002 | `Mnemonic` legado dormente (RISK-011-001/RISK-005-004) segue sem solução — SPEC-028 não o expurga nem migra | Aceito nesta fatia; revisitar em limpeza de schema dedicada | SPEC-028 §9 |
| RISK-028-003 | Sem teto de cadência entre fechamentos de Versão (A-028-011) — histórico pode acumular Versões sem mudança real de texto | Aceito nesta fatia; revisitar se o piloto (PIL-001) reportar ruído real | SPEC-028 §9 |
| ~~RISK-028-004~~ | **RESOLVIDO 2026-09-27 por SPEC-032** — o gate de "Versão aprovada" cobre conteúdo normativo + Tira mnemônica (decisão do PO em nome do Diretor, pendente de confirmação explícita na Entrega); Contraste/Pegadinha elaborada/Flashcard/Associação visual ficam fora, com o carimbo do PDF declarando esse alcance explicitamente (RISK-032-002) | Ver RISK-032-002 | SPEC-028 §9 → SPEC-032 |
| RISK-032-001 | Operação com 1 único ADMIN bloqueia toda aprovação por construção (segregação de funções recusa autoaprovação) — a métrica de adoção de SPEC-032 §1.3 fica estruturalmente em 0% até existirem 2+ ADMINs distintos; não é falha de adoção | Dotação de equipe é decisão do Diretor (A-002-017); métrica-guarda invariante (SPEC-032 §1.3) não depende dessa condição | SPEC-032 §9 |
| RISK-032-002 | Contraste/Pegadinha elaborada/Flashcard/Associação visual ficam fora do gate de aprovação; a Tira mnemônica ENTRA (decisão em nome do Diretor, degrau 2 — pendente de confirmação explícita na Entrega, já que o BRIEF-032 a listava no checklist original) | Aceito nesta fatia; carimbo do PDF declara o próprio alcance | SPEC-032 §9 |
| RISK-032-005 | Segregação de funções compara CONTA, não pessoa — com operação de 1 pessoa, o contorno natural é criar uma 2ª conta ADMIN e aprovar consigo mesma através dela | Nenhum controle técnico detecta isso nesta fatia; controle detectivo fica para fatia futura, se o piloto reportar o padrão | SPEC-032 §9 |
| RISK-028-005 | Um expurgo físico futuro de Conteúdo bruto, em cascata, apagaria as Versões editoriais dele — contradiz o requisito append-only (FR-028-004) | A fatia que definir expurgo (fora de F8, ver §4.2 de SPEC-028) precisa resolver o destino das Versões antes de agir; nenhum mecanismo futuro pode remover uma Versão, direta ou indiretamente | SPEC-028 §9 |
| TRISK-029-006 | Sem teto de retenção, o armazenamento de `ContentVersion.contentSnapshot` cresce sem limite com fechamentos sucessivos (A-028-011 não exige mudança real de texto entre eles) | Aceito nesta fatia; revisitar via PIL-001 ou medição real de armazenamento em produção — poda é decisão reversível (ver `Reabrir se` de DEC-029-003) | PLAN-029 §8 |
| RISK-030-001 | Contraste AA de placeholder/rótulo sobre o fundo preenchido da pílula (NFR-030-001) é o ponto mais provável de retrabalho no gate de design | Medir contraste nos dois temas antes de fechar a wave que toca os campos; margem para 1 rodada extra do `product-designer` | SPEC-030 §9 |
| RISK-030-002 | Peso do SVG/CSS autoral da ilustração no bundle de `/login` pode acionar o gate de performance | PLAN mantém a ilustração simples (poucos paths); `performance-engineer` avalia na implementação | SPEC-030 §9 |
| RISK-030-003 | Cenários de cenário/robustez sem AC formal (trânsito guard→`/login?next=`→login→`next`, foco de teclado, robustez da ilustração/autofill/`forced-colors`, aviso de sessão expirada acima da dobra em 360px) — decisão do PO: cobertos pelo roteiro de verificação dos gates 9/11, não por AC | Roteiro do `qa`/`product-designer` na implementação deve exercitar os itens listados em SPEC-030 §9 | SPEC-030 §9 (veredito PO) |
| ~~Q-030-001~~ | **RESOLVIDO 2026-09-28 (PLAN-031)** — route group dedicado rejeitado: `code-scout` achou que este projeto só tem um root layout, e um `layout.tsx` de route group aninha DENTRO dele, não o substitui; promover um 2º root exigiria mover todas as rotas soltas de `src/app/` para um grupo irmão. DEC-031-001: fundo em tela cheia via `position: fixed; inset: 0` dentro da árvore normal da página (sem route group) — preserva header/footer de graça (FR-030-013). | — nenhuma | SPEC-030 §9 → PLAN-031 DEC-031-001 |
| TRISK-031-003 | `position: fixed` do fundo em tela cheia (COMP-031-002) depende de nenhum ancestral (`Providers`/`SiteHeader`/`<main>`) declarar `transform`/`filter`/`perspective`/`contain` — se algum declarar, o backdrop deixa de posicionar relativo ao viewport | Verificação visual na implementação, item de roteiro do gate 9/11 — não bloqueante | PLAN-031 §8 |
| RISK-034-001 | Lead time de calendário não é esforço: Conteúdo parado infla tempo por etapa/página | Rótulo e leitura como lead time; nunca métrica por pessoa (NFR-034-004) | SPEC-034 §9 |
| RISK-034-003 | Conteúdos cuja 1ª Exportação Tira pós-fechamento é anterior a F10 ficam "sem medida" para sempre; cobertura nasce baixa | Cobertura (medidos/ativos) exibida no Painel | SPEC-034 §9 |
| RISK-034-004 | Ambiente semeado direto (sem eventos) mostra Painel vazio/"sem medida" — reflexo fiel do dado | Gate 9 gera dado exercitando rotas | SPEC-034 §9 |
| RISK-034-005 | 1º consumidor real da leitura de eventos de etapa, sem paginação (herdado de TRISK-010-002) | PLAN/gate 10 decidem | SPEC-034 §9 |
| RISK-034-006 | O Painel fornece o número, não o critério de escala; o limiar segue em PIL-001 | — | SPEC-034 §9 |
| DEPLOY-035-001 | **Pendência de deploy (PLAN-035)**: migração aditiva `mnemonicos-backend/prisma/migrations/20260930062551_add_publication_event_page_count` (`ALTER TABLE publication_events ADD COLUMN "pageCount" INTEGER`, nullable) — aplicada em dev/teste; em produção roda pelo `vercel-build` (`prisma migrate deploy`) no próximo deploy do backend. **Pré-requisito do código**: o backend novo grava e lê `pageCount`; deploy do código sem a migração quebra a Exportação e o Painel. Ordem: migração antes (o `vercel-build` já garante). Frontend depende do backend novo (`GET /strategic-panel`) — deploy do backend primeiro. | aditiva, sem DROP/ALTER destrutivo; linhas antigas ficam `null` ("sem medida") | Diretor (deploy) |
| RISK-036-001 | Sem mecanismo de persistência de tema definido na SPEC (decisão do PLAN), a estratégia escolhida pode causar troca visível do tema errado na 1ª pintura (FOUC) se a leitura da escolha salva depender só do cliente | NFR-036-004 declara o comportamento esperado (SHOULD); técnica cabe ao PLAN | SPEC-036 §9 |
| RISK-036-002 | Paleta noturna só tem contraste AA medido para os papéis de UI de `/login` (fundo, pílula, botão, texto) — estendê-la ao app pode expor papéis novos (erro/sucesso/link/foco/hover) sem token equivalente já validado | Mapeamento e prova de contraste dos papéis novos ficam com o PLAN; NFR-036-005 exige distinguibilidade mínima | SPEC-036 §9 |
| RISK-036-003 | O mecanismo de detecção de sessão do controle de autenticação precisa conviver com `baseQueryWithReauth` (`mnemonicos-frontend/src/store/api.ts`) sem disparar sua rota de expulsão (`resetApiState`+redirect `/login?sessao=expirada`) para visitante anônimo em rota pública | FR-036-015 trava o requisito observável; mecanismo exato de adaptação é decisão técnica do PLAN | SPEC-036 §9 |
| ~~—~~ | **RESOLVIDO 2026-09-30 (Entrega)** — PO escalou a remoção do botão "Sair" próprio da área interna em favor do controle único do header (FR-036-014); Diretor confirmou a remoção na Entrega (AskUserQuestion). | — nenhuma | po, aprovação de SPEC-036 → Diretor, Entrega de PLAN-036 |
| — | Dívida de design não-bloqueante (gate 11, Wave 3): (1) estado neutro do `AuthControl` (`return null`) causa layout shift quando resolve para Entrar/Sair, o `ThemeToggle` ao lado salta; (2) mensagem de erro do logout (`flex-col`, abaixo do botão) pode empurrar o header verticalmente; (3) `ThemeToggle` (`h-9 rounded-full`) e os botões de `AuthControl` (`px-4 py-2 surface-card`) não têm altura/forma idênticas; (4) "Entrar" é `<button onClick={router.push}>` em vez de `next/link` (produto usa `next/link` em outros pontos de navegação) | Nenhuma ação nesta entrega — 4 ajustes opcionais de composição, nenhum fura piso de acessibilidade; candidatos a diff de limpeza futuro ou brief avulso | product-designer, gate 11 Wave 3 de PLAN-036 |
| — | Verificação de tela pendente — HANDOFF-PLAN-036 (`docs/producao-material/handoffs/HANDOFF-PLAN-036.md`) — 8 ACs (AC-036-002/004/006/014/015/016/017/018) dependem de login real (realm `editor`); backend indisponível neste ambiente (Docker Desktop não sobe, Postgres fora do ar) — 11/19 ACs já VERIFICADOS por execução real (Playwright, sem sessão) | roteiro completo no handoff; exercitar com backend saudável (outra máquina/CI, ou este ambiente reparado) | HANDOFF-PLAN-036 |
| TRISK-036-004 | `data-theme` setado pelo script de bootstrap (fora do React) pode divergir do estado interno de `ThemeToggle` se o componente assumir um tema default fixo no 1º render em vez de ler o atributo já aplicado no `<html>`/a escolha salva — risco de hidratação ou de o alternador "nascer" com rótulo/estado errado | `ThemeToggle` deve ler `document.documentElement.dataset.theme`, nunca assumir default hardcoded — item de verificação da TASK/gate 1 | PLAN-036 §8 |

## Histórico recente

- 2026-10-03 10:03: **PLAN-051 criado e Approved** (SPEC-050, 14/14 FRs + 3/3 NFRs; 2 rodadas de `code-scout` — confirmou guarda de login só por `disabledAt` (A-050-007), logger pino existente sem tabela de auditoria). 8 COMPs (4 backend + 4 frontend), 14 DECs (9 herdadas + 5 novas, nenhuma irreversível), 9 TRISKs. DEC-051-010: ícone SVG próprio (sem biblioteca nova). DEC-051-011: log via tipo paralelo `UserAuditType` em `lib/audit.ts` (sem tabela/migração nova) — TRISK-051-001 registra a dependência da métrica no coletor de produção. DEC-051-013: coluna de Ações migra para 1 botão estável por linha (props computadas da Situação), permitindo o foco pós-ação voltar ao mesmo controle (AC-050-001). `plan-validator`: 5 ERROR mecânicos (`plan-dec-irreversivel-enum`) calibrados como falso-positivo do script (bug confirmado — `gsub` de byte octal não casa "ã" multibyte no gawk 5.0/UTF-8 desta máquina; reproduzido também contra as 11 DECs já `Approved`/mergeadas do PLAN-049) — `agile-coach` despachado, `PROPOSTA_PLUGIN` pendente para o relatório de fecho.
- 2026-10-01 17:10: **SPEC-050 criada e Approved** via `/keelson:auto` (BRIEF-050, Jira KAN-219 em modo link — História pré-existente do épico KAN-218, filha do Diretor; tracker-sync gravou `**Jira Story**: KAN-219`, sem Epic-stub nem Stories por FEAT). 14 FRs, 3 NFRs, 14 ACs, 7 RISKs, 2 FEATs. spec-validator 0 ERROR (WARNINGs estilísticos aceitos, mesmo nível do slug). product-analyst REVISAR_ANTES_DE_APROVAR (9 achados: remoção de "Redefinir senha" sem realocação quebra o caminho de tela de quem esqueceu a senha; conflito aparente com a diretriz do Diretor sobre 2º ADMIN; emenda não declarada à SPEC-048; + 6 achados menores) → po APROVAR, 0 escalação (verificou as duas diretrizes citadas no INDEX e confirmou que não conflitam — o próprio card KAN-219 é a diretriz mais recente, e a liberação de 2º ADMIN já cobre a exposição equivalente). **Emenda a SPEC-048** (subseção §8): textos de reativação indisponível (FR-048-013/015) superados por FR-050-007/008; FEAT-048-004 (redefinir senha) perde o ponto de entrada na linha, comportamento continua especificado para quando for realocado.

> Nota de numeração (2026-09-30): `SPEC-034`/`PLAN-035`/`TASK-035-00X`/`BRIEF-034` foram
> alocados por DUAS demandas paralelas neste slug (colisão real de `next-id.sh` entre
> sessões concorrentes). O Painel estratégico (F10, KAN-165) manteve a numeração original,
> por já ter mais entradas e ter sido a 1ª a chegar na `main`. O header de sessão/tema
> (KAN-77) foi renumerado para `SPEC-036`/`PLAN-036`/`TASK-036-00X`/`BRIEF-036` na
> reconciliação do pull — nenhum dos dois lados foi descartado.

- 2026-10-01 10:26: **PR #27 mergeado pelo Diretor** (`mnemonicos-frontend`, merge `6adbdf8`, 2026-10-01 12:50 UTC). Jira reconciliado: KAN-179 `21` (movido sem conector) → `31` → `41` Concluído + comentário `10264`; sem épico-pai. Gate 9 em tela continua pendente em HANDOFF-PLAN-049 (agora sobre a `main`). Próximo: brief avulso do RISK-032-006 (decisão do Diretor).
- 2026-10-01 10:24: **Jira reconciliado pós-merge** (acesso restabelecido, ordem do Diretor): KAN-178 Em análise → **Concluído** (41) + comentário de merge (PR #26, `5bce413`); KAN-187..191 conferidas em Concluído; sem épico-pai. `tracker-local-KAN-178.md` marcado como RECONCILIADO.
- 2026-10-01 09:38: **PR #27 aberto a pedido do Diretor** (`mnemonicos-frontend`, `feat/producao-material-gestao-usuarios` → `main`, HEAD 056bf21). Gate 9 em tela segue pendente (HANDOFF-PLAN-049); merge é do Diretor.
- 2026-10-01 09:33: **Diretor respondeu às escalações da Entrega do BRIEF-048**: (1) 2º ADMIN — merge da tela livre; o brief avulso do RISK-032-006 abre logo após o merge e nenhum 2º ADMIN real é criado até ele entrar (contas descartáveis de teste não contam); (2) auditoria das operações de conta — história de backend **candidata** (sem card até autorização), juntando a redação do termo de busca no log de acesso do pino-http (RISK-048-008).
- 2026-10-01 00:57: **Entrega do BRIEF-048 (KAN-179)** — po ACEITA_COM_RESSALVAS (gate 9 em tela pendente em HANDOFF-PLAN-049). Branch `feat/producao-material-gestao-usuarios` (mnemonicos-frontend, HEAD 056bf21) pushada; PR e merge com o Diretor. Jira sem acesso: fila em `tracker-local-KAN-179.md` (start-dev `21` e finish-dev `31` pendentes). MET-048 plantada. 2 escalações ao Diretor: RISK-032-006 antes de 2º ADMIN real; história de backend de auditoria das operações de conta.
- 2026-10-01 00:53: convergência de fecho verde em 056bf21 (dedup: aplicada) — SPEC-048 × PLAN-049, 0 gap, 0 não solicitado; 2 pendências de consolidação (asserção "sem literal de paleta" triplicada nas suítes de fonte; dois mecanismos de foco pós-commit no formulário e no diálogo).
- 2026-10-01 00:49: **PLAN-049 implementado (6 TASKs), aguardando promoção manual de Status.** 4 waves (1 retry de gate em cada TASK, 2 furos no plano tratados: premissa da DEC-049-010 sobre o RTK e coluna Ações quebrando o C3), suíte do frontend 91 suítes / 1303 testes verdes (baseline 73/1037), lint/typecheck 0, backend sem diff. Gates 8 e 11 aprovados em todas as waves; gate 10 aprovado na W2, n/a nas demais. Gate 9 PARCIAL — HANDOFF-PLAN-049. MAP com seção nova; memo de exploração removido.
- 2026-09-30 23:35: furo no plano em TASK-049-005 — a coluna "Ações" quebra o C3 de `users-screen.create.integration.test.tsx` (arquivo da TASK-004, fora do Inclui) — destino: ajuste localizado (Inclui estendido com critério próprio, re-despacho). Sonda do TRISK-049-003: `invalidatesTags` roda também em mutação que falha → `refreshAccountList` não criado; TASK-049-006 ajustada.
- 2026-09-30 22:52: furo no plano em TASK-049-002 — DEC-049-010 supunha `originalArgs` (com a senha) em `state.api.mutations`; no RTK 2.12.0 o slice de mutação nunca grava args (`buildSlice.ts:437-447`), eles ficam na promise do hook — destino: ajuste do PLAN sem mudar contrato (track:false mantido como defesa em profundidade; controle positivo passa a ser a contagem de chaves em `state.api.mutations`); NFR-048-001 intacto.
- 2026-09-30 22:16: **PLAN-049 decomposto em 6 TASKs** (4 waves: W1 001 guarda ADMIN + menu por papel e 002 camada de dados sensível; W2 003 lista; W3 004 criar e 005 desativar; W4 006 redefinir + rodada final consolidada do gate 9), todas medium; 25/25 FRs, 28/28 ACs. Rodada consolidada 3.5: task-validator 1 ERROR (`ac-sem-task` AC-048-023) + qa pré-código 16 achados (3 de produto → po APROVAR: página vazia com page>1 mostra "Nenhuma conta nesta página."; cliente redige eco da senha com `[senha oculta]` via `redactSecret`; gate 9 consolidado numa rodada final com um único login manual) → 2 pacotes de correção paralelos (modo edits) → revalidação limpa.
- 2026-09-30 21:35: **PLAN-049 criado e Approved** (SPEC-048, 25/25 FRs + 5/5 NFRs, só frontend). 10 COMPs, 7 DECs herdadas + 11 novas (todas reversíveis), 10 TRISKs. plan-validator 0 ERROR; 2 WARNING (COMP-049-006 com 8 FRs e COMP-049-008 com 11 — coesos, a decomposição reparte). DEC-049-010: senha fora do store por `initiate(args, {track:false})`, conferido no RTK instalado. Colisão possível com BRIEF-047 em `internal-shell.tsx`/`internal-routes.ts` (TRISK-049-001).
- 2026-09-30 21:23: **SPEC-048 criada e Approved** via `/keelson:auto --from=KAN-179` (BRIEF-048, Jira KAN-179 em modo link; conector sem acesso, sync em `tracker-local-KAN-179.md`). 25 FRs, 6 NFRs, 28 ACs, 4 FEATs. spec-validator 0 ERROR (1 auto-fix mecânico: subtítulos de FEAT na §7). product-analyst REVISAR_ANTES_DE_APROVAR (14 riscos) → po ESCALAR com 14 resoluções aplicadas e 2 escalações seguidas pelo default, estacionadas para a Entrega: auditoria das operações de conta (RISK-048-008) e ordem do RISK-032-006 frente ao 2º ADMIN (RISK-048-009). **Emenda a SPEC-044**: EDITOR continua com 3 itens; ADMIN ganha "Usuários" em 4º (subseção "Emendas à SPEC-044" da §8 da SPEC-048).
- 2026-09-30 21:05: **PR #26 mergeado pelo Diretor** (`mnemonicos-frontend`, merge `5bce413`). Jira sem acesso: KAN-178 → Concluído (41) + comentário de merge **registrados como pendentes** em `tracker-local-KAN-178.md`, para reconciliar quando o acesso voltar. Sem épico-pai: não há filhos a consultar. Verificação de tela com login segue em HANDOFF-PLAN-046; alinhamento de header/footer em BRIEF-047.
- 2026-09-30 21:05: **PR #26 aberto a pedido do Diretor** (`mnemonicos-frontend`, `feat/producao-material-sidebar-navegacao` → `main`). Merge de teste com a `main` atual (já com o #25, botão "Saindo") sem conflito; 71 suítes / 1023 testes verdes no resultado do merge. Pendente antes do merge: HANDOFF-PLAN-046 (login manual). KAN-178 Concluído em 2026-10-01.
- 2026-09-30 20:58: **Diretor decidiu o alinhamento de header/footer** (pergunta estacionada da Entrega do KAN-178): "Brief avulso depois" → `briefs/BRIEF-047-header-footer-alinhados-area-interna-avulso.md` aberto (sem card até autorizar a execução); a entrega do KAN-178 segue como está (TRISK-046-005 passa a ter destino).
- 2026-09-30 20:40: **BRIEF-037 fechado como absorvido** pela SPEC-044/PLAN-046 (TASK-046-001, commits 9b60fc2/1915183; sem card próprio). **Aceitação do PO do BRIEF-044: ACEITA_COM_RESSALVAS** — prova em tela com login pendente (HANDOFF-PLAN-046), alinhamento header/footer à área interna aguardando o Diretor.
- 2026-09-30 20:39: convergência de fecho verde em 06a7932 (dedup: aplicada) — PLAN-046/SPEC-044, 0 gaps; pendência de consolidação: `stripComments` duplicado em 2 testes.
- 2026-09-30 20:39: **PLAN-046 implementado (5 TASKs)** — Etapa 4: suíte completa 73/1032 verdes (baseline 900, 0 regressão), lint e typecheck limpos; gate 9 PARCIAL (anônimo verde, 0 divergências; 22 ACs + métrica §1.3 em HANDOFF-PLAN-046 por `permissao_ambiente`); MAP com delta (seção PLAN-046) e entrada PLAN-035 do container duplicado marcada como resolvida; sem pendência de deploy (só frontend, sem migração nem env nova). DoD com item de tela pendente → PLAN segue `Approved` (não `Done (sugerido)`) até o handoff fechar.
- 2026-09-30 19:42: **PLAN-046 Wave 3 fechada** (TASK-046-005 menu recolhível abaixo de `xl`). Gates: 8 n/a (sem superfície sensível); 10 n/a; 11 REPROVADO (toque fora no `pointerdown` com painel no fluxo; hovers sem efeito) e 1–7 REPROVADO (remoção do listener `change` sem prova) → retry e6c01d2 + PLAN v0.3 → 11 APROVADO; 1–7 REPROVADO de novo (K7 vivo após a troca para `click`) → teto 4.88 → escada degrau 1 (só teste) → APROVADO em 06a7932. Lições novas em observação: `painel-no-fluxo-fecha-por-toque-fora-no-click-nunca-no-pointerdown` e `trocar-o-evento-de-um-listener-reexecuta-todo-mutante-cujo-sujeito-e-ele`. 2 reports de developer vieram vazios (commits conferidos pelo Tech Lead e mutantes pelos revisores).
- 2026-09-30 19:35: furo no plano em TASK-046-005 — DEC-046-006 fechava o menu por toque fora no `pointerdown`; composto com o painel no fluxo (DEC-046-005), desloca o conteúdo antes do click (gate 11, Wave 3) — destino: ajuste de DEC (PLAN-046 v0.3: toque fora no `click`; foco volta ao botão só se `activeElement` for body/nulo ou no componente), TASK re-emitida com critério herdado.
- 2026-09-30 19:16: **PLAN-046 Wave 2 fechada** (TASK-046-004 sidebar fixa com seção atual, montada no ramo pronto da casca). Gates: 8 APROVADO; 11 APROVADO (achado médio: header/footer `max-w-5xl` × área interna `max-w-7xl`, nenhuma borda coincide acima de 1024px — **pergunta estacionada ao Diretor**; texto de DEC-046-003/TRISK-046-005 diz ≥1280, o correto é >1024); 1–7 REPROVADO 2× (extrator de cor cego a `@utility`/`@theme`, depois a type hint e `!`) → teto 4.88 → escada degrau 1 (correção só de teste, decisão do Tech Lead em nome do Diretor) → APROVADO em 581bfeb. Lição `extrator-textual-…` estendida (confirmada 2). K1 do critério era inerte (dedupe do RTK Query); NFR-044-002 fecha pelo G17.
- 2026-09-30 18:58: **PLAN-046 Wave 1 fechada** (TASK-046-001 container `PageContainer`, 002 `SiteLogo`, 003 Volta ao conteúdo) — sequencial (sem `worktreeBootstrap`; 002 sensível). Gates: 8 APROVADO (security-engineer); 1–7 REPROVADO na 002 (L3–L7 liam a 1ª pintura) → retry 8c60101 → APROVADO; 11 REPROVADO na 003 (Tira sem `flex-wrap` a 360px) → retry 583049a → APROVADO; 10 n/a. Lições: extensão da ativa `predicado-de-decis-o-de-ui-…-componente-montado` (confirmada 1) e nova `linha-flex-de-titulo-e-acoes-soma-larguras-contra-328px` (em observação). Fora de escopo: ficha `codePaths.frontend` sem `tests/`; perfil next-16 §3/§7 desatualizado (testes junto do código); páginas irmãs da Tira sem `flex-wrap` a 360px.
- 2026-09-30 18:27: **PLAN-046 decomposto em 5 TASKs** via `/keelson:tasks` (rota única; W1: 001 container `PageContainer`, 002 `SiteLogo`, 003 Volta ao conteúdo; W2: 004 sidebar fixa na casca; W3: 005 menu recolhível). Etapa 3.5 consolidada: task-validator 0 ERROR; qa pré-código 16 achados mecânicos com fixação executada (integrações HTTP 14, baseline 86), 0 de produto → sem despacho ao PO; 1 volta de correção (scribe, `modo: edits`, 42 edits) + PLAN v0.2 (DEC-046-006 com reset de `openPath` na troca de rota; foco em 3 meios; sem `encodeURIComponent`; "Voltar ao conteúdo" antes de "Conteúdos brutos"). Revalidação mecânica limpa. Jira desligado: 5 sub-tarefas pendentes em `tracker-local-KAN-178.md`.
- 2026-09-30 17:52: **PLAN-046 criado e Approved** via `/keelson:plan` (Caso D, 100% da SPEC-044: 27 FRs + 4 NFRs). 7 COMPs, 9 DECs novas (todas reversíveis) + 8 herdadas, 7 TRISKs (2 altos no INDEX). plan-validator 0 ERROR, 1 WARNING (COMP-046-002 realiza 14 FRs — coeso; TASKs repartem). Reconhecimento do code-scout antecipado no fecho da Etapa 1. Decisões: breakpoint da sidebar fixa = `xl` (1280px), container da área interna `max-w-7xl` (conteúdo +32 a +56px nas 5 larguras); `homeSessionCheck` não reusado (reúso do KAN-180 é `hasSessionHint`); `auth-control.tsx` fora do diff (BRIEF-045 em paralelo).
- 2026-09-30 17:43: **SPEC-044 criada e Approved** via `/keelson:auto --from=KAN-178` (BRIEF-044, Jira KAN-178 em modo link, sem card novo). v0.2: 27 FRs, 4 NFRs, 26 ACs, sem FEATs. spec-validator v0.1 1 ERROR (termo fora do glossário) + 13 WARNING → revalidação v0.2 0 ERROR (4 FR >30 palavras, MUST 25/27). product-analyst REVISAR_ANTES_DE_APROVAR (14 riscos) → po APROVAR, 0 escalações, decisões em nome do Diretor: logo exige sessão ativa + papel com acesso; AC-040-018 preservado; **sidebar fixa só a partir do breakpoint em que não estreita o conteúdo (~1280px), no lugar do default `md`** (motivo: AC de largura do card); 404 raiz sem sidebar; Tira mantém "Conteúdos brutos". **Emenda SPEC-040 v0.4 → v0.5** (FR-040-009, AC-040-010, §4.1/§4.2, A-040-008, A-040-012 e termo Home pública deste INDEX): o logo com sessão ativa e papel com acesso vai direto a `/studio`; o link da 404 segue fixo em `/`. BRIEF-037 absorvido (fecha na Entrega).
- 2026-09-30 19:35: **PR #25 mergeado pelo Diretor** (`mnemonicos-frontend`, merge `8633200`, KAN-186). BRIEF-045 → Concluído. O Diretor devolveu o acesso ao Jira e a fila de `tracker-local-KAN-186.md` foi aplicada: comentário `10260` e transição direta `21` → `41` Concluído (o `31` foi pulado porque o acesso caiu antes do finish-dev). O card agora é do tipo História (`10009`), trocado fora do conector. Não tem épico pai, então não há filhos a consultar.
- 2026-09-30 17:44: **BRIEF-045 entregue (KAN-186): "Sair" vira "Saindo" com spinner.** Commit `0edec2a` no frontend, **PR #25** aberto a pedido do Diretor. Gates 1–7 aprovados no re-gate, depois de 1 retry: o teste de ordem com `firstElementChild` era vazio, e a lição nova é `ordem-entre-elemento-e-texto-se-prova-por-childnodes…`. Gate 8 aprovado sem achados, gate 9 verificado em app real com `auth/me` e logout interceptados, gate 11 aprovado com medição em Chromium, gate 10 n/a. Aceitação do PO: ACEITA. Suíte 905/905. **Jira sem acesso por ordem do Diretor**: o finish-dev (KAN-186 → `31`) e o comentário do PR ficaram em `tracker-local-KAN-186.md`.
- 2026-09-30 17:28: **BRIEF-045 (avulso, KAN-186): botão "Sair" do header vira "Saindo" com spinner**, a pedido do Diretor depois do merge do KAN-185. KAN-186 é uma Tarefa criada nesta largada, com `Relates` para o KAN-185. É avulso porque SPEC-036/SPEC-002 prometem só os três estados do logout (em andamento = desabilitado + indicador), não o texto "Saindo…". O padrão já foi decidido no BRIEF-043, então não há DEC. Implementação pelo developer na branch `feat/producao-material-logout-botao-saindo`.
- 2026-09-30 17:25: **PR #24 mergeado pelo Diretor** (`mnemonicos-frontend`, merge `f7760a2`, KAN-185). BRIEF-043 → Concluído. KAN-185 → Concluído (41) no Jira, comentário 10259. Não tem épico pai, então não há filhos a consultar. O V2 do HANDOFF-PLAN-031 (login de sucesso real) segue aberto até o Diretor preencher a evidência.
- 2026-09-30 17:22: **PR #24 aberto** (`mnemonicos-frontend`, `feat/producao-material-login-botao-entrando` → `main`, KAN-185) a pedido do Diretor, com o build OK na branch. O merge espera o V2 do HANDOFF-PLAN-031 (login de sucesso real). KAN-185 segue em Em análise.
- 2026-09-30 17:13: **TASK-031-008 Done (BRIEF-043, KAN-185): botão de login em "Entrando" com spinner.** Commit `f8e8709` no frontend, na branch `feat/producao-material-login-botao-entrando`. Gates 1–7 aprovados pelo code-reviewer, com 14 mutantes mortos e 1 comentário de prova falsa corrigido e re-gateado. Gate 8 aprovado sem achados, gate 11 aprovado com medição em navegador, gate 10 n/a. Gate 9 **parcial**: os passos 1–7 foram verificados em app real, e o ramo de sucesso com ADMIN real ficou no V2 do HANDOFF-PLAN-031 (`permissao_ambiente`, KAN-185). Aceitação do PO: ACEITA_COM_RESSALVAS. Suíte 760/760.
- 2026-09-30 16:57: **Emenda SPEC-030 v0.3 (BRIEF-043, KAN-185)**: estado de envio no próprio botão ("Entrando" + spinner), sem o status solto "Entrando…". PO APROVOU sem escalação (a invariante "status Entrando…" do BRIEF-030 foi revogada pelo próprio Diretor no card KAN-185). Cláusulas tocadas: FR-030-012 (cobre o indicador do botão), FR-030-017 novo, NFR-030-001/002/005, AC-030-009/010/011/015 e AC-030-016 novo, §4.1/§4.2 (exceção nomeada: guarda de reenvio só se o teste mostrar reenvio), glossário "Botão em envio", gate 9 reaberto; âncora de NFR-030-002 atualizada. TASK-031-008 registrada (KAN-185).
- 2026-09-30 16:40: /keelson:triage (`--from=KAN-185`) classificou demanda "botão de login vira 'Entrando' com spinner, sem o texto solto 'Entrando…' abaixo" como **categoria 1b** (emenda da SPEC-030 → v0.3: NFR-030-002 promete "o status 'Entrando…' durante o envio" e AC-030-011 exige os testes "sem alteração de asserção"; sem DEC nova — spinner segue DEC-031-002, SVG/CSS inline sem dependência). Ação: rota emenda do `/keelson:auto` com BRIEF-043 do card, `**Jira**: KAN-185` em modo `link`. Aguarda confirmação do Diretor.
- 2026-09-30 16:31: **Jira reconciliado (KAN-177 → Concluído).** O acesso foi devolvido pelo Diretor. O card estava em `31` Em análise, movido sem conector desde o `21` medido às 13:16. Comentário `10254` com branches, PRs #21/#22 e gates; transição `41` confirmada (`10007`); sem épico-pai. `tracker-local-KAN-177.md` marcado como RECONCILIADO.
- 2026-09-30 14:12: **PRs #21 e #22 mergeados pelo Diretor** (`mnemonicos-frontend`, merges `539575a` e `05cc3e1`). BRIEF-039 e BRIEF-042 → Concluído. O Jira segue sem acesso por ordem do Diretor, e a fila de reconciliação do KAN-177 (comentário de fim de dev, `41` Concluído, comentário de merge; sem épico) fica em `docs/producao-material/tracker-local-KAN-177.md`, para aplicar quando o acesso voltar.
- 2026-09-30 14:08: **BRIEF-042 (avulso, KAN-177): link "Voltar para o início" centralizado e sem sublinhado**, por decisão do Diretor depois do merge do PR #21 (`539575a`). Ela substitui o sublinhado que o gate 11 do BRIEF-039 tinha pedido. Commit `9b2e920`, PR #22. Gates: code-reviewer APROVADO, product-designer APROVADO (risco aceito: folga de 14px em 360px até o "Entrando…"), qa VERIFICADO, segurança n/a. Lição `link-discreto…` contestada e reformulada. Jira sem acesso: pendentes KAN-177 → `41` (merge do #21) e o comentário do PR #22.
- 2026-09-30 13:44: **Emenda v0.2 da SPEC-030 entregue (BRIEF-039/KAN-177, rota emenda do `/keelson:auto`).**
  - **Emenda:** o PO APROVOU a emenda sem escalação. A promessa de "cabeçalho e rodapé em `/login`" vinha de uma resolução do PO no BRIEF-030. Ela revoga a decisão do BRIEF-032 de manter o rodapé.
  - **SPEC-030 v0.1 → v0.2:** FR-030-013 reescrito; FR-030-015/016 e AC-030-015 novos; AC-030-001/005/011 ajustados; gate 9 datado de novo.
  - **Implementação:** inline, registrada como TASK-031-007 (Done) para fechar o `ac-sem-task`. Commit `f35c4f3` no frontend, branch `feat/producao-material-login-sem-rodape-voltar`.
  - **Gates:**
    - 1–7: REPROVADO por prova (inventário do cartão, Enter, espião cego) → retry → APROVADO.
    - 8: APROVADO.
    - 9: VERIFICADO com login real.
    - 10: n/a.
    - 11: REPROVADO (link sem sublinhado em repouso) → retry → APROVADO.
  - **Aceitação do PO:** ACEITA_COM_RESSALVAS; as 3 ressalvas foram fechadas nos artefatos.
  - **Lições:** 3 lições novas (link discreto, inventário que sobe de contêiner, espião de `useRouter`), `next-16.md` §7 atualizado e 3 propostas ao plugin (LRN-056..058).
  - **Pendência do Diretor:** destino do scrim do `LoginNightBackdrop`, agora que nenhum texto senta sobre ele em `/login`.
  - **Jira:** acesso retirado temporariamente pelo Diretor. KAN-177 medido em `21`; o `finish-dev` (→ `31`) e o comentário de branch/PR ficam para a reconexão.
- 2026-09-30 15:20: **TASK-041-001 Done** (Wave 1/4 do PLAN-041, commits frontend `ef94cd7` → `833e35d` → `82b508f`): `silentRefresh` extraída do `baseQueryWithReauth` + endpoint `homeSessionCheck` (access/no-access/no-session/failed). Gate 8 e gate 10 aprovados de 1ª; gates 1–7 reprovaram 2× (mutante de colapso invertido no chamador antigo, re-busca em `no-access` sem caso, casts `as`; depois a guarda `=== null` do escoteiro sem caso) → 1 retry + 1 rodada dirigida (escada degrau 1, veto do Diretor na Entrega). 37 casos, 24 mutantes mortos. Lições: nova `refactor-que-alarga-o-tipo-de-retorno-exige-caso-por-valor-novo-em-cada-chamador-antigo` (em-observação); reincidência de `corre-o-acrescentada-de-carona-num-retry-passa-pela-mesma-r-gua-do-achado-original` (confirmada 1 → ativa). Jira: sub-task não criada (acesso retirado).
- 2026-09-30 15:37: **TASK-041-002 Done** (Wave 2/4 do PLAN-041, commits frontend `0cd1cd1` → `ccb7fea`): pista local de sessão (`src/lib/session-hint.ts`, valor fixo `'1'`) gravada no login e no `InternalShell` com `data`, apagada no logout. Gate 8 aprovado de 1ª; gates 1–7 reprovaram 1× só na prova (W6 instável por mock no-op de navegação; W9 com asserção vácua) → 1 retry, convergiu. Suíte completa 783/783. Lição nova `mock-no-op-de-navegacao-que-desmontaria-a-arvore-transforma-contagem-exata-em-corrida` (em-observação). Jira: sub-task não criada (acesso retirado).
- 2026-09-30 16:24: **TASK-041-003 Done** (Wave 3/4 do PLAN-041, commits frontend `3585dd7` → `23f2d22` → `95fb386`): a home decide pela sessão — script inline da página (estado neutro antes da pintura + teto único de 3 s), CSS aditivo (`visibility:hidden`), `data-auth-control`, `HomeSessionGate` (predicado positivo, `router.replace(INTERNAL_HOME)`, ida tardia, bfcache). `layout.tsx` intocado; `/` segue estática (JS da home +1 KB gzip). Gates 8, 10 e 11 aprovados de 1ª; gates 1–7 reprovaram 2× (A1 guarda de cache velho descartava conferência pendente — StrictMode/remontagem sem decisão; assinatura `storage` sem pai removida; push-0 em todo caso; depois o lado `rejected` da guarda sem caso) → 1 retry + 1 rodada dirigida (degrau 1, veto do Diretor). 41 casos no gate, 39 mutantes. Suíte completa 844/844. Lição nova `guarda-de-descarte-por-requestid-distingue-entrada-concluida-de-pendente-e-se-prova-nos-dois-lados` (em-observação, confirmada 1). Fora de escopo: CSP com nonce para os scripts inline (quando a CSP entrar). Jira: sub-task não criada.
- 2026-09-30 17:25: **PR #23 mergeado pelo Diretor** (`mnemonicos-frontend`, merge `12a0a25`), BRIEF-040 → Concluído. KAN-180 → Concluído (41) no Jira; sub-tasks KAN-181..184 já em 41 (conferido por JQL `parent = KAN-180`). Sem épico-pai, então não há épico a consultar. Segue aberto: HANDOFF-PLAN-041 (verificação com login real, V1–V8), com credenciais de teste já atualizadas (`admin1` e realm novo `editor`; `admin2` desativado no banco de dev). A largada do KAN-178 fica liberada.
- 2026-09-30 17:12: **Entrega do KAN-180 — aceitação do PO: ACEITA_COM_RESSALVAS** (BRIEF-040 → Aceito). Convergência de fecho (code-reviewer) em `da7f529`: 1 gap parcial (logo clicado já em `/` não remonta o gate) resolvido por **emenda SPEC-040 v0.4** (FR-040-013 e RISK-040-005 restritos a abertura vinda de outra página; clique no logo já em `/` → fora de escopo, recuperação por recarga) — decisão do PO em nome do Diretor; `não solicitado` 0; dedup: aplicada (2 pendências de consolidação de harness de teste, família RISK-025-003). Lição nova `a-cada-abertura-da-rota-no-app-router-nao-e-a-cada-montagem-navegar-para-a-url-atual-nao-remonta` (em-observação). Varredura de segredos da branch por regex: 0 (gitleaks ausente). Mutação: não configurada (opt-in).
- 2026-09-30 17:05: **PLAN-041 implementado (4 TASKs), aguardando promoção manual de Status** — suíte completa 65 suítes / 865 verdes, lint/typecheck 0, `/` estática; merge-tree contra `origin/main` (com o PR #22/KAN-177) sem conflito; sem pendência de deploy (diff-facts). Gate 9 PARCIAL → HANDOFF-PLAN-041 (credencial). RISK-040-002 resolvido por preservação (proxy intocado). MAP com o delta do território (seção "Home com sessão reconhecida"). Incidente de ambiente declarado: o `qa` leu credenciais de seed do `.env` do backend durante a sondagem (sem imprimir; 2 logins de dev) — rotação recomendada ao Diretor.
- 2026-09-30 16:53: **TASK-041-004 Done** (Wave 4/4 do PLAN-041, commits frontend `af703d2` → `be8624b` → `da7f529`): prova HTTP real (`src/app/home.integration.test.ts`, 11 casos) — `/` estática com conteúdo público, título e descrição sem script; rota interna sem cookie → `/login?next=`; `proxy.ts`/`proxy.test.ts` com diff vazio; manifesto com `start_url` `/`. **Furo no plano em TASK-041-004**: dois arquivos de integração fazem `next build` no mesmo `.next` e a suíte completa paralela (comando da ficha) ficou vermelha e instável (3 e 11 falhas) — destino: ajuste localizado da TASK, trava entre processos `test/next-build-lock.ts` usada por home e not-found (extensão sancionada ao teste do PLAN-020, só acquire/release). Gates 1–7 reprovaram 1× (3 ramos de detecção da trava sem caso; orçamento do timeout do hook) → 1 retry, convergiu. Suíte completa 65 suítes / 865 verdes, 3×. Reincidência da lição ativa `extrator-com-cadeia-de-fallback…` (confirmada +1). Jira: KAN-184.
- 2026-09-30 14:50: **PLAN-041 decomposto em 4 TASKs / 4 waves** (001 medium sensível · 002 small · 003 medium, com Roteiro do gate 9 · 004 small chore). Rodada 3.5 consolidada: task-validator 6 ERROR (sobreposição de api.ts na W1, contagem do proxy.test 16→55, re-busca do meSilent × contagens, realm de gate 9 inexistente) + qa pré-código 3 de produto e 14 mecânicos (premissa A-040-006 REFUTADA no backend — a falha de renovação anônima não é auditada; marca removida antes do replace; dois tetos de 3 s). po (resolução) RESOLVIDO sem escalar → **SPEC-040 emendada para v0.3** (A-040-006 reescrita com o fato medido; pista de sessão mantida como A-040-014 + FR-040-017 + AC-040-025 + RISK-040-006; AC-040-013 com oráculo no stdout do backend; AC-040-014 informativo; AC-040-015 Given 'com pista'; gate 9 com admin1/admin2, sem realm EDITOR). Revalidação delta: 1 ERROR novo (PLAN desalinhado das TASKs) → 2ª volta declarada (escada degrau 1): **PLAN-041 v0.3**. Grafo/lint limpos. Jira: sub-tasks não criadas (acesso retirado pelo Diretor), pendente de reconciliação.
- 2026-09-30 16:41: /keelson:triage classificou demanda "tela de gestão de usuários só para ADMIN: listar, criar, desativar e redefinir senha" (KAN-179) como **categoria 1**. É capacidade nova, e a SPEC-002 §4.2 põe explicitamente fora do escopo a "UI completa de gestão de equipe no frontend". Não cabe como emenda 1b, porque traz componentes novos e exige DECs: guarda ADMIN por sub-rota (hoje `(interno)/layout.tsx:16` só aplica EDITOR ao grupo inteiro), a senha fora do estado Redux (RTK Query guarda `originalArgs` da mutation) e o item de menu provisório × a sidebar do KAN-178. A API e os hooks já existem (`users.routes.ts:44-80`, `api.ts:782-865`), então é só frontend, sem migração, mas a paginação ainda precisa entrar em `AdminListUsersArgs`. Estimativa do estimator: ~4 waves, 5–7 TASKs, 7–18 h de ciclo, confiança média. Ação: `/keelson:auto --from=KAN-179` (SPEC em modo `link`, sem card novo), aguardando confirmação do Diretor.
- 2026-09-30 13:50: **PLAN-041 criado e Approved** (SPEC-040, 100% dos FRs/NFRs). 5 COMPs, 5 DECs novas (todas reversíveis) + 7 herdadas, 6 TRISKs. `proxy.ts`/DEC-003-011/COMP-003-022 preservados literalmente (RISK-040-002 resolvido por preservação). plan-validator 0 ERROR; 1 WARNING mecânico (DEC-041-005 alternativa única) e TRISK-041-006 atualizado pelo Tech Lead inline (precedente DEC-035-001). Ponto de reúso para o KAN-178: `homeSessionCheck` + pista local de sessão.
- 2026-09-30 13:44: **SPEC-040 criada e Approved** via `/keelson:auto --from=KAN-180` (BRIEF-040, Jira KAN-180 em modo link). 16 FRs, 6 NFRs, 24 ACs, sem FEATs. spec-validator 0 ERROR (1 auto-fix). product-analyst REVISAR_ANTES_DE_APROVAR (11 riscos) → po APROVAR com 14 resoluções: termo "Sessão reconhecida" (sem emenda à SPEC-036), emenda do glossário "Home pública" (SPEC-019), teto de 3 s + ida tardia, conferência atual a cada abertura e nunca por pré-carregamento, página pública sem script, ACs de execução real nomeados. Jira: acesso retirado temporariamente pelo Diretor; sync pendente de reconciliação.
- 2026-09-30 13:20: /keelson:triage (re-triagem, `--from=KAN-180`) confirmou a classificação de 12:52 para "usuário com sessão que entra na aplicação vai direto à área logada" como **categoria 1**. A demanda muda a promessa de guarda de rota da SPEC-002 (DEC-003-011 / COMP-003-022, `proxy.ts:97` só cobre rotas internas) e exige DECs, então não cabe como emenda 1b: presença × validade do cookie (`proxy.ts:68` só confere se existe), `/login` com sessão, papel `STUDENT`, e o destino `/` da 404 (SPEC-019). Duas coisas mudaram desde as 12:52. (a) O KAN-176 foi mergeado (`b729a76`) e hoje quem tem sessão e abre `/` fica sem link para `/studio`. (b) O KAN-178 foi triado com a DEC "destino do logo × KAN-180", e o redirecionamento de `/` resolveria o logo sem mudar o link (`site-header.tsx:13`). Recomendação: rodar o KAN-180 antes do KAN-178. Ação: `/keelson:auto --from=KAN-180` (SPEC em modo `link`, sem card novo), aguardando confirmação do Diretor.
- 2026-09-30 13:25: /keelson:triage classificou demanda "sidebar de navegação da área interna (Painel, Conteúdos, Biblioteca visual)" (KAN-178) como categoria 1 (capacidade nova sem SPEC que a cubra; promete destaque da seção atual, menu recolhível no celular e logo por estado de sessão, e exige DEC: montagem na casca × layout do grupo `(interno)`, padrão do menu no celular, regra de seção ativa, destino do logo × KAN-180). O card cita "BRIEF-036" para o container duplicado, mas o brief certo é o **BRIEF-037** (renumeração de 2026-09-30); a proposta é absorvê-lo no escopo. Ação: `/keelson:auto` com `--from=KAN-178` (modo `link`, sem card novo), aguardando confirmação do Diretor.
- 2026-09-30 13:30: **Diretor respondeu à triagem do KAN-178**: o KAN-180 roda primeiro, e o logo por sessão do KAN-178 vai reusar a DEC de sinal de sessão do KAN-180. O Diretor também reforçou que a sidebar só aparece na área logada, nunca na área não logada nem em `/login` (isso já estava nos ACs do card e agora é restrição explícita para o BRIEF). A absorção do BRIEF-037 continua em aberto.
- 2026-09-30 14:20: **Diretor autorizou absorver o BRIEF-037 no escopo do KAN-178**. O container duplicado sai junto com a sidebar, e o BRIEF-037 fecha como absorvido pela SPEC nova. A largada continua esperando o merge do KAN-180.
- 2026-09-30 13:10: **PR #20 mergeado pelo Diretor** (`mnemonicos-frontend`, merge `b729a76`), BRIEF-038 → Concluído. KAN-176 → Concluído (41) no Jira. Ele não tem épico-pai, então não há filhos a consultar. Até o KAN-180 entrar, quem tem sessão e cai em `/` fica sem link para `/studio`.
- 2026-09-30 13:05: **BRIEF-038 (KAN-176) implementado e revisado.** Gates 1–7 aprovados depois de 1 retry, e gates 8 e 11 aprovados. O gate 9 foi VERIFICADO em tela e o gate 10 é n/a. Commit `6ff6519` no frontend e PR #20 aberto, com KAN-176 em Em análise. Falta o merge do Diretor, lembrando da ordem em relação ao KAN-180.
- 2026-09-30 12:52: /keelson:triage classificou demanda "remover o 'Entrar' duplicado do corpo da home pública" (KAN-176) como brief avulso (categoria 5 recusada: o link é a entrega do KAN-74 e o único caminho de `/` até `/studio` com sessão), ação: `briefs/BRIEF-038-home-sem-entrar-duplicado-avulso.md` (`**Jira**: KAN-176`). O Diretor decidiu que usuário com sessão não vê a área não logada, o que substitui o AC do KAN-74 na home.
- 2026-09-30 12:52: /keelson:triage classificou demanda "usuário com sessão que entra na aplicação vai direto à área logada" (KAN-180, card criado a pedido do Diretor e ligado ao KAN-176 por `Relates`) como categoria 1 (muda a guarda de rota da SPEC-002 / DEC-003-011 e exige DEC: presença × validade do cookie, `/login` com sessão, papel `STUDENT`), ação: `/keelson:auto` com `--from=KAN-180`, ainda não disparado.
- 2026-09-30 12:58: /keelson:triage classificou demanda "tela de login sem rodapé e com link discreto 'Voltar' para `/` abaixo do Entrar" (KAN-177) como categoria 1b (emenda da SPEC-030: FR-030-013 [MUST] ainda promete cabeçalho e rodapé em `/login`; o cabeçalho já saiu pelo BRIEF-032 sem a SPEC ser emendada, e a emenda corrige as duas coisas; técnica já dada pelo card, estender o gate de `HIDDEN_ROUTES`, sem DEC), ação: rota emenda do `/keelson:auto` com `--from=KAN-177` (modo `link`, sem card novo), aguardando confirmação do Diretor.

- 2026-09-30: **PLAN-036 mergeado em `main`** (`mnemonicos-frontend`, PR #18, `e254bd1`) e
  KAN-77 fechado no Jira (Concluído) — ato do Diretor. Sem épico-pai (projeção compacta,
  como KAN-73): trilho do card para nesse passo, sem filho de épico a consultar. Handoff
  de verificação de tela (`HANDOFF-PLAN-036.md`, 8 ACs) segue aberto — próximo passo é
  rodar o roteiro com o backend de pé.

- 2026-09-30 11:49: **F10 mergeada pelo Diretor** — PR #11 backend (`39d033d`) e PR #19 frontend (`f975939`) em `main`. Jira: Histórias KAN-166 e KAN-167 → Concluído (41); filhos do épico consultados por JQL (`parent = KAN-165`: 2/2 em 41) e épico KAN-165 → Concluído com confirmação do Diretor (SPEC-034 entregue inteira); comentário de merge no épico. Pendente: deploy na ordem de DEPLOY-035-001.

- 2026-09-30 10:58: **PRs da F10 abertos a pedido do Diretor** — backend PR #11 e frontend PR #19 (`feat/producao-material-mnemora-studio` → `main`), ambos com a ordem de deploy DEPLOY-035-001 destacada (backend + migração antes do frontend). Merge é do Diretor; KAN-166/167 seguem em "Em análise" até o aviso de merge.

- 2026-09-30 10:50: **Perguntas estacionadas da Entrega de F10 respondidas pelo Diretor** — (1) `stash@{0}` do mnemonicos-frontend (WIP TASK-035-008 retry 2) descartado após conferência: todo o código contido no HEAD `4673869` (só um comentário reescrito depois pela revisão); (2) índice `PublicationEvent(rawContentId, variant)` **não criado agora** — volta com pergunta ao Diretor quando o volume se aproximar do teto medido em DEC-035-018 (~2.500 Conteúdos); (3) A-034-006 (abertura órfã conta como etapa alcançada no backlog) **mantida** — olhar no uso real, ajuste reversível em fatia futura; (4) `max-w-5xl` duplicado (InternalShell × `<main>` do root layout) → brief avulso BRIEF-037 (renumerado de 036 por colisão com o brief do header/tema deste mesmo slug), aberto, sem código nem card até o Diretor autorizar.

- 2026-09-30 10:43: **Entrega da F10 — aceitação do PO: ACEITA_COM_RESSALVAS, 0 escalações** (BRIEF-034 → Aceito). Pedidos (1)–(4) e premissas A-034-001..005 conferidos; nada do fora de escopo vazou. Ressalvas: V8(b) — etapa mais avançada conta a abertura órfã de "Quebra da regra" do Conteúdo recém-criado (A-034-006, selo crença; reversível, olhar no 1º uso real); AC-034-015 (vazio global) só por teste de componente; deploy na ordem de DEPLOY-035-001 (backend + `migrate deploy` antes do frontend). Fila do épico: F10 entregue.

- 2026-09-30 10:40: convergência de fecho verde em `a3ed523` (mnemonicos-backend; frontend `4673869`) (dedup: aplicada) — 1ª rodada achou 2 gaps parciais (FR-034-026/AC-034-020: início registrado era o 1º `CONTEUDO_BRUTO` de qualquer transição; FR-034-029/027: "sem registro" com eventos presentes), corrigidos em `2f55ea0` (início = par ABERTURA+CONCLUSAO de criação no mesmo instante; etapa por "há algum evento"); re-convergência sobre o delta CONVERGIU, carona `a3ed523` (teste da igualdade de instante). Teste instável de query-count corrigido antes (`8a89f3b`, seed em lotes). Suíte final: backend 476 unit + 596 integração, frontend 724 — verdes.

- 2026-09-30 10:10: **PLAN-035 implementado (8 TASKs), aguardando promoção manual de Status** — Wave 5 fechada: TASK-035-008 (tela do Painel) após retry 1 (gates 1/7/11 — prova por valor literal no slot, vazio por seção sem esconder métrica irmã, FR-034-026 no frontend por furo no plano), retry 2 (teto 4.88 resolvido com "aplicar e fechar"), merge da `main` do frontend com a nova identidade visual (pedido do Diretor, `ac107a6`) e correção de contraste da barra na paleta nova (`--progress-fill`). Gate 9 da FEAT-034-002 VERIFICADO em tela real (V8(b): etapa mais avançada conta abertura órfã como alcançada — conforme A-034-006, a revisitar). Pendência de deploy registrada (DEPLOY-035-001).

- 2026-09-30 09:21: **pausa** de PLAN-035 a pedido do Diretor (reinício do PC) — 7/8 TASKs Done; TASK-035-008 (tela do Painel) implementada com gates 8/10 aprovados e 1/7/11 em retry 2 (WIP em `git stash` do mnemonicos-frontend: "WIP TASK-035-008 retry 2"; pacote de retry na casa da sessão, gates/w5-retry2.md). Faltam: gate 9 da FEAT-034-002, Etapa 4 e Entrega. Retomar com `/keelson:continue producao-material`.
- 2026-09-30 08:12: **Wave 4 de PLAN-035 fechada** — TASK-035-007 (espelho de `PRODUCTION_STAGE_TYPES`/`CONTENT_STAGE_TYPES`/`PresentationPriority` e dos tipos `*Response` do Painel no frontend; contrato cross-repo por nome+tipo; endpoint `getStrategicPanel` com `forceRefetch` — `refetchOnMountOrArgChange` não é opção de endpoint no RTK Query, DEC-035-019/COMP-035-018 corrigidos no PLAN). Gates: code-reviewer reprovou (paridade só por nomes; Record de retrabalho mais largo; docblock), retry APROVADO; security-engineer APROVADO; performance-engineer APROVADO com regra de 1 subscriber (critério herdado na TASK-035-008).
- 2026-09-30: convergência de fecho verde em `92542c5` (dedup: aplicada) — PLAN-036/
  SPEC-036, 0 gaps, 9 DECs confirmadas no código final. 3 achados não-bloqueantes fora de
  escopo: `layout.test.tsx` tem helper duplicado (`findElementByType`/
  `containsComponentType`); `viewport.themeColor` (`layout.tsx:24-28`) continua preso à
  paleta antiga (ink) e a `prefers-color-scheme`, ignorando a escolha manual de tema —
  candidato a diff de limpeza futuro; nota de coesão (`THEME_STORAGE_KEY`/`ThemeName` em
  `night-palette-tokens.ts`, importados por `theme-bootstrap.ts`, lib dependendo de app).
- 2026-09-30: **PLAN-036 implementado (6 tasks), aguardando promoção manual de Status.**
  Header unificado de sessão (`AuthControl`) e tema (`ThemeToggle`) com paleta noturna
  estendida ao app inteiro. 3 waves, 6/6 TASKs Done — 5 rodadas de retry reais (cobertura
  de mutante/DEC, cadeia de fallback sem teste, mutante enfraquecido por mudança de
  topologia de teste, mock duplicado) + 2 rodadas de acessibilidade visual (cursor/hover
  ausente, depois `brightness` imperceptível no tema escuro — 2ª rodada por erro de escopo
  do Tech Lead no 1º retry, declarado). Gates 1-7/8/11 aprovados em todas as waves
  aplicáveis. Gate 9 (`qa`) **PARCIAL**: 11/19 ACs VERIFICADOS por execução real
  (Playwright); 8 ACs (login real) em `HANDOFF-PLAN-036.md` — backend indisponível neste
  ambiente (Docker Desktop não sobe). PO da SPEC: ESCALAR (E-01, não-bloqueante —
  confirmação da remoção do "Sair" duplicado da área interna, default aplicado, vai à
  Entrega). 4 itens de dívida de design não-bloqueante registrados em Riscos ativos.
- 2026-09-30 07:20: **Wave 3 de PLAN-035 fechada** — TASK-035-006 (`GET /strategic-panel`, EDITOR/ADMIN, allowlist por ramo, `contents[]` por Conteúdo, 7 statements fixos, agrupamento O(N+E)). Gates: code-reviewer reprovou (bloco por Conteúdo ausente — furo no plano; ramo medido sem prova; estado entre `it`), retry; 2ª reprovação no critério `res.json(payload)` → teto 4.88 resolvido pela escada com "aplicar e fechar"; extrator textual novo reprovado e trocado por prova comportamental; security-engineer APROVADO (wave + delta); performance-engineer reprovou O(N·E) e aprovou após `Map` — **NFR-034-002 medido: p95 176 ms em 200×50 (alvo 1.500), 572 ms em 1000×50, corpo 193 KiB**. FEAT-034-001 completa: gate 9 VERIFICADO pelo `qa` (linha na SPEC).
- 2026-09-30 06:50: gate 10 da Wave 3 de PLAN-035 reprovou TASK-035-006 por agrupamento O(N·E) (`.filter` por Conteúdo): NFR-034-002 medido passa no volume de referência (p95 216 ms, 200×50, corpo 193 KiB) mas estoura a 5× (p95 1.611 ms); variante `Map` medida em 594 ms. Critério novo na TASK-035-006; DEC-035-018 ganha o teto medido no `Reabrir se` (~2.500 Conteúdos p/ o alvo, ~4.700 p/ corpo Vercel, RISK-025-007).
- 2026-09-30: furo no plano em TASK-036-001 — `useMeSilentQuery` foi declarado no endpoint
  `meSilent` (`store/api.ts`) mas nunca entrou na lista de export nomeado que os outros 30+
  hooks do arquivo usam (`export const { ... } = api;`), então a importação que
  TASK-036-005 precisa fazer não compilava — destino: ajuste localizado, sancionado dentro
  de TASK-036-005 (1 linha adicional no export, sem mudar o comportamento já provado de
  TASK-036-001).
- 2026-09-30 06:00: furo no plano em TASK-035-006 — o payload do Painel (TASK-035-004) nasceu sem o bloco por Conteúdo e a rota o omitiu (achado do gate 4 da Wave 3: FR-034-004/005/006/025 sem dado na fronteira HTTP) — destino: ajuste localizado da TASK (Tech Lead): `StrategicPanelPayload.contents` em `aggregateStrategicPanel` (strategic-panel-calculations.ts entra no Inclui só para isso) + critérios de um caso por ramo, allowlist por unit e sem estado entre `it`; retry.
- 2026-09-30 05:32: **Wave 2 de PLAN-035 fechada** — TASK-035-004 (cálculo puro por Conteúdo + agregação/backlog + prioridade derivada) e TASK-035-005 (6 leituras em lote, factory-wide, snapshot só das vigentes aprovadas). Gates: code-reviewer reprovou as duas no gate 1 (testes não discriminantes), retry consolidado; TASK-035-005 reprovada 2ª vez no gate 7 (sonda de query duplicada) → teto 4.88 resolvido pela escada (Diretor ausente) com o default "aplicar e fechar" — `withQueryEventProbe` em tests/support; performance-engineer reprovou o `contentSnapshot` do histórico → PLAN-035 v0.2, re-review APROVADO; security-engineer APROVADO (wave e delta; gitleaks ausente). Lições: 4 novas + 1 confirmada.
- 2026-09-30 05:15: ajuste de PLAN pós-gates da Wave 2 de PLAN-035 — gate 10 (performance-engineer) reprovou a leitura de versões com `contentSnapshot` de todo o histórico append-only: PLAN-035 v0.2 (COMP-035-007 chave leve + `listApprovedVersionSnapshots`; DEC-035-014 passa a 7 statements fixos); TASK-035-005/006 ajustadas com critérios; gate 1 (code-reviewer) reprovou TASK-035-004/005 por testes não discriminantes (16/17 mutantes do produtor e eixo pertencimento) — retry consolidado.
- 2026-09-30 04:33: furo no plano em TASK-035-005 — `RAW_CONTENT_VERSIONED_SELECT`/`RULE_BREAKDOWN_VERSIONED_SELECT` não eram exportadas por `content-versions.service.ts` (a TASK presumia que sim) — destino: ajuste localizado da TASK (Tech Lead): `content-versions.service.ts` entra no Escopo > Inclui só para acrescentar `export` às 2 constantes, com critério próprio; re-emitida.
- 2026-09-30 04:10: **Wave 1 de PLAN-035 fechada** — TASK-035-001 (`PublicationEvent.pageCount`, migração aditiva `20260930062551_add_publication_event_page_count` aplicada em dev/teste; contagem fail-safe), TASK-035-002 (predicado de F9 extraído para `isVersionAltered`, comportamento idêntico, curto-circuito de I/O mantido), TASK-035-003 (`formatDurationPtBr`). Gates: code-reviewer reprovou 001 (gate 1: par de reexportações não discriminante) e 003 (gate 6: `!`), 1 retry cada, re-review APROVADO; security-engineer APROVADO (gitleaks ausente); performance-engineer APROVADO. Fora de escopo estacionado: predicado TIRA de F9 compara por relógio de aplicação (herdado). Lição de projeto nova: prova-de-escrita-que-nao-reescreve-registro-anterior-usa-valores-distintos.
- 2026-09-30 03:21: **PLAN-035 decomposto em 8 TASKs / 5 waves** (6 medium, 2 small; rota única). Lint: 1 volta de correção (task-criterio-sem-ac TASK-007, task-refactor-sem-identidade TASK-002, greps ancorados); grafo limpo; task-validator PASS. Rodada 3.5: `qa` pré-código 3 achados mecânicos + 1 de produto → `po` (resolução) opção B — roteiro do gate 9 da TASK-035-008 ganha V7 (correções após revisão) e V8 (ordenação do backlog) por rotas reais; V5 (vazio global) provado por teste de componente, não-exercitável sem alterar o acervo de dev (decisão do Tech Lead). Jira: sub-tasks KAN-168..KAN-175.
- 2026-09-30 02:37: **PLAN-035 criado e Approved** (via `/keelson:auto`, cobertura total de SPEC-034 — Caso D). `scribe` sobre o reconhecimento do `code-scout`; plan-validator: 0 ERROR após 2 correções mecânicas de forma (bullets de FRs cobertos e campos `Realiza` multilinha, que o parser lia só na 1ª linha — mesma classe de PLAN-033) + 2 `Reabrir se: nunca` sem motivo; 4 WARNING `plan-dec-alternativa-unica` aceitos (precedente PLAN-033). 22 COMPs, 20 DECs (10 herdadas, 10 novas, nenhuma irreversível), 4 TRISKs. Achado da redação: `RawContent` não tem título — identificação mínima = id + disciplina/tema (DEC-035-016).
- 2026-09-30 02:20: **SPEC-034 criada e Approved (F10, via `/keelson:auto`, BRIEF-034).** Última chamada: Diretor decidiu página = páginas do PDF (coluna nova na Exportação), "erros na revisão" = correções pós-fechamento, migração aditiva autorizada em dev/teste. `scribe` redigiu v0.1 (2 FEATs/18 FRs); spec-validator PASS (0 ERROR); `product-analyst` REVISAR_ANTES_DE_APROVAR (13 riscos); `po` APROVAR com pacote R0–R13, 0 escalações, 10 decisões em nome do Diretor (a mais sensível: janela até a 1ª Exportação Tira pós-fechamento). Reescrita v0.2: 2 FEATs, 34 FRs, 4 NFRs, 24 ACs, 14 premissas, 6 riscos; revalidação 0 ERROR (spec-porte-epico WARNING aceito — inflação por repartição EARS, decisão registrada). Responde Q-009-001/Q-009-002 (SPEC-009) e avalia o gatilho de A-005-001 (não disparou). Jira: Épico KAN-165 (Relates KAN-6), Stories KAN-166 (FEAT-034-001) e KAN-167 (FEAT-034-002).
- 2026-09-30 00:25: **F9 mergeada pelo Diretor** — PR #10 backend (`3ba13b5`) e PR #17 frontend
  (`1728d78`) em `main`. Jira: KAN-150/KAN-151 → Concluído (trilho pós-merge); `parent = KAN-149`
  lido do quadro: 2/2 filhos em Concluído; épico KAN-149 → Concluído por confirmação do Diretor. A migração `20260927135234_add_content_version_approval` entra no próximo deploy do
  backend. Pendentes: HANDOFF-PLAN-033, Q1 (RISK-032-006).
- 2026-09-30 00:20: **Entrega da F9 — convergência de fecho e aceitação do PO.** Convergência
  (code-reviewer): merge APROVADO, 1 gap parcial FR-032-007(b); o PO aceitou com ressalvas e pediu
  a mesma correção (R-1). Retry R-1 (frontend `3043b46`): a leitura "Válida para a próxima
  exportação" sai do bloco de ação ADMIN e passa a aparecer na linha da Versão vigente para
  qualquer papel; `caf6ea6` troca a copy do "não" por uma frase neutra (a do ADMIN mandava um
  passo que a segregação recusa) e prova o filtro da Versão vigente. Backend `c76dbc1`: só
  comentário no schema. Gate 9 do R-1 `pendente_handoff` (credencial com placeholder no
  `keelson.local.json`) → HANDOFF-PLAN-033. Riscos novos: RISK-032-006 (Q1) e TRISK-033-004.
  Frontend 656/656. Os dois repos contêm `origin/main`, sem conflito.
- 2026-09-29 23:35: **Wave 5 de PLAN-033 fechada — TASK-033-007 Done; PLAN-033 7/7; FEAT-032-001
  VERIFICADA.** Painel de aprovação em `content-version-history.tsx`. Antes do retry, merge de
  `origin/main` no frontend (`e4c8461`, sem conflito). Retry 1 fechou B1-B3 (prova: ordem das
  caixas, fake espelhando `z.literal(true)`, 2 Versões) e A1-A4 (reset do estado por Versão,
  `updateRawContent` invalida `ContentVersion`, copy minúscula, fieldset "Aprovação da versão N");
  B4 (achado novo do retry, resets sem prova própria) teve retry próprio. Decisão do Tech Lead:
  FR-032-007(a) prevalece — cada linha do histórico mostra a própria aprovação (Emenda 1 na
  TASK). Gates 8/10 aprovados; gate 9 verificado 2× por browser. Frontend `a4e828f`/`e68553d`/
  `43d49dc`. 654/654 frontend, 418+565 backend. Lições: 3 de projeto + LRN-048 e reincidência
  de LRN-004 (processo).
- 2026-09-29 23:20: **PLAN-036 criado via `/keelson:auto` (cobre 100% de SPEC-036) e
  promovido a Approved.** 100% frontend, sem tocar backend. 6 DECs novas (todas
  reversíveis): script de bootstrap de tema sem dependência nova (`data-theme` +
  localStorage); CSS em 3 camadas (`:root` claro / `@media prefers-color-scheme:
  dark):not([data-theme=light])` / `:root[data-theme=dark]`); mapeamento de
  `--surface`/`--surface-raised`/`--border-subtle` para a paleta noturna (mantendo
  `--text-strong`/`--text-muted`/`--danger`/`--link` como estão, já provados ou
  deliberadamente não remapeados); extensão de `night-palette-tokens.ts`; endpoint
  `meSilent` (`queryFn` contornando `baseQueryWithReauth`) para checar sessão sem efeito
  colateral em rota pública; consolidação do logout em `AuthControl` (remove
  `LogoutControl` de `internal-shell.tsx`). 7 COMPs, 4 TRISKs (3 herdados dos RISK-036-00X
  da SPEC, 1 novo — TRISK-036-004, hidratação do tema). `artifact-lint`/`graph.sh`: 0
  ERROR (2 achados mecânicos corrigidos — enum `Irreversível: nao`, `**Realiza**` quebrado
  em 2 linhas invisível ao parser).
- 2026-09-29 22:59: **SPEC-036 criada via `/keelson:auto` (KAN-77, BRIEF-036) e promovida a
  Approved.** Botão único de sessão (Entrar/Sair/neutro) + alternador de tema claro/escuro no
  header, em toda rota inclusive produção, consolidando o logout hoje próprio da área
  interna; paleta unificada roxo/rosa/mauve de `/login` (SPEC-030) estendida ao app inteiro
  com o mesmo piso AA, sem a ilustração decorativa; tema por dispositivo, sobrevive a
  login/logout. `product-analyst` achou 7 riscos reais (verificados contra o código: header
  ausente em `/login` confirmado correto; "Sair" duplicado na área interna; `useMeQuery` em
  rota pública dispararia expulsão indevida por `baseQueryWithReauth`) — 1 rodada de
  correção fechou 6/7; PO (modo aprovação) ESCALOU o 7º (remoção do "Sair" da área interna)
  com default aplicado (mantida), pergunta em lote na Entrega. `spec-validator`: 0 ERROR.
- 2026-09-29 21:56: **Wave 4 de PLAN-033 fechada — TASK-033-006 Done.** `approveContentVersion`
  (RTK Query, `POST /contents/:id/versions/:number/approve`, invalida só `ContentVersion`) e o hook
  `useApproveContentVersionMutation`; paridade de `ContentVersion` conferida nos 2 lados (entregue
  pelas TASKs 003/004). Gates 1-7 aprovados sem retry; 8/10/11 n/a; gate 9 consolidado em
  FEAT-032-001. Frontend `7c83015`/`ebda177`. `ApproveContentVersionArgs` fica `boolean` como o
  COMP-033-010 prescreve (tipar `true` literal vai à Entrega como sugestão).
- 2026-09-29 21:45: **Wave 3 de PLAN-033 fechada — TASK-033-004 Done.** `listContentVersions`
  expõe `approvedById`/`approvedAt` e o campo computado `validApprovalForExport` (só a vigente,
  aprovada e sem sinal de alteração; mesmo predicado do carimbo do PDF), espelhado nos 2
  `domain.ts`. Custo constante medido: 2/5/5/4 statements (N=3 e N=8 iguais). 1 retry nos gates
  1/7: caso por par de ramos (mutantes de propagação e índice errado) e chaves exatas do payload
  do GET (mutante spread) — este no teste HTTP de rotas, extensão só-de-teste declarada. Gate 8
  aprovado (0 vulnerabilidade), gate 10 aprovado (2 sugestões à Entrega), gate 9 consolidado em
  FEAT-032-001 (TASK-033-007). Backend `923f60e`/`e1d8426`/`eba5603`, frontend `d19ecfd`. Lições:
  `select-exposto-que-le-campo-interno-prova-as-chaves-do-payload` (projeto) e LRN-046 (processo,
  proposta ao plugin).
- 2026-09-29 20:46: **Wave 2 de PLAN-033 fechada — TASK-033-003/005 Done; FEAT-032-002 VERIFICADA.**
  Retomada via `/keelson:continue` (parado 2h06min). Âncoras de ID do código da F9
  renumeradas (backend `5984073`, 101 ocorrências; frontend `94711c9`, 3) — verificação
  mecânica (word-diff só do mapeamento) + integração completa 555/555. Docker Desktop e
  `mnemonicos-db` estavam parados (ECONNREFUSED) e foram religados. Gate 9 da FEAT-032-002:
  `qa` exercitou os 6 ACs contra o backend real, PDFs inspecionados por `pdftotext`.
  Tracker: sem acesso ao Jira nesta sessão — operações acumuladas em
  `tracker-local-F9.md` (instrução do Diretor). Próximo: Wave 3 (TASK-033-004).
- 2026-09-29 19:11: **Colisão de IDs resolvida no merge com `origin/main`.** Uma sessão paralela
  entregou o redesenho visual da tela de login como BRIEF-030/SPEC-030/PLAN-031/TASK-031-*,
  alocados ao mesmo tempo que a F9 (controle de qualidade e gate de versão aprovada). A `main`
  manteve os seus IDs; a F9 foi renumerada antes do merge: BRIEF/SPEC-030 → 032, PLAN-031 → 033,
  TASK-031-* → TASK-033-*, e as lições de processo LRN-038..041 → LRN-041..044. As entradas
  abaixo que citam SPEC-032/PLAN-033/TASK-033 foram reescritas pela renumeração. Pendente: os
  comentários/nomes de teste do código da F9 (branch `feat/producao-material-mnemora-studio`)
  ainda citam os IDs antigos (FR-030-*, AC-030-*, DEC-031-*, TASK-031-*) — atualizar antes do
  PR, senão as âncoras apontam para o PLAN do login.
- 2026-09-29 18:24: **PLAN-033 pausado a pedido do Diretor, no meio da Wave 2.** Estado
  exato para retomar (`/keelson:continue producao-material`):
  - **Wave 1 fechada** (TASK-033-001/002 Done, closure `723805a`).
  - **Wave 2 com código pronto e aprovado, closure ainda NÃO feita.** TASK-033-003 (backend
    `2e9998c` → retries `e9a1360`, `563f350`, `49489c9`; frontend `053a6ab`) e TASK-033-005
    (`8160cd1` → `8d01262`, `08e6452`): gates 1-7, 8, 10 e 11 APROVADOS na última rodada.
    DEC-033-006 recebeu 2 emendas no PLAN (guarda de edição pós-fechamento, agora ordenada
    por `ProductionStageEvent.sequence` — bypass sequencial e concorrente de segregação de
    funções, achados do gate 8, ambos fechados). TASKs 003/004/006 editadas (espelho de tipos
    movido para quem cria o campo; heranças do gate 8 da Wave 1 como critérios).
  - **Falta na Wave 2**: (1) gate 9 da FEAT-032-002 (carimbo no PDF) — o `qa` foi
    interrompido pelo limite de uso no meio da execução; ele já tinha criado uma 2ª conta
    ADMIN no banco de **dev** (`01a0e589-e5fe-73b9-a0cd-47f0b6768d6b`, "admin2", ativa —
    reusar no gate 9 ou desativar via `POST /users/:id/disable`); redespachar o `qa` do zero;
    (2) closure de TASK-033-003/005 (Histórico de execução, TASK-INDEX, célula Tasks 2/7 →
    4/7); (3) rotear ao `agile-coach` a lição de processo "DEC cuja segurança depende de 'o
    campo X só muda quando Y' enumera os escritores de X" (code-reviewer, W2) — as 5 lições
    de projeto da Wave 2 já estão em `guidelines/project/lessons/` e 2 reincidências
    atualizadas no `lessons.md`.
  - Depois: Waves 3-5 (TASK-033-004, 006, 007) e a Entrega.
  - Pendências para o Diretor já acumuladas (ledger da sessão `b1505f46`): E-1 (Tira no
    escopo do gate — default aplicado), N5 (troca de imagem de Associação visual não acende o
    sinal), sufixo "(não cobre o material de reforço)" na marca do PDF, lacuna de SPEC
    (`saveRuleBreakdown` não carimba identidade), 4 propostas ao mantenedor do plugin
    (LRN-041..041).
- 2026-09-29: **Convergência de fecho de PLAN-031** (revisão da branch inteira,
  `code-reviewer`, Entrega do `/keelson:auto`) — achou um GAP real: o texto de
  `SiteHeader`/footer (fora do card, herdado do root layout) perdia contraste AA no tema
  claro contra o `LoginNightBackdrop` (~2,0-2,4:1). Corrigido com scrim (faixas
  translúcidas topo/base do fundo, `color-mix`, 85% opacidade) — 1º retry usou faixa
  chapada, `product-designer` reprovou (aresta dura cortando a lua, quebrando a atmosfera
  do BRIEF); 2º retry trocou para gradiente com parada segura + desvanecimento, aprovado
  com captura real e medição de luminância pixel a pixel. `po` (modo aceitação):
  ACEITA_COM_RESSALVAS (5 ressalvas, nenhuma bloqueante — AC-030-012 parcial aceito para
  merge, tom do botão sujeito ao aceite visual do Diretor, autofill não confirmado). 6
  capturas recapturadas no estado final. 627/627 testes verdes. Lição de processo:
  inventário de contraste precisa cobrir todo texto visível da rota contra o fundo
  efetivo, não só os componentes do diff.
- 2026-09-29: **Gate 9 consolidado de PLAN-031** (DoD, Etapa 4 do implement — SPEC-030
  sem FEATs) — `qa` executou os 11 passos do roteiro fixado em TASK-031-004 via navegador
  real (branch `feat/producao-material-login-redesign`, HEAD `55dbf61`). 10/11
  VERIFICADO: card em duas metades sem vazamento de stacking context (TRISK-031-003
  refutado empiricamente), sem rolagem horizontal em 360/768/1280px, `reduced-motion`
  suprime toda animação, ordem de foco correta, ilustração degradando sem quebrar o
  formulário, `forced-colors` funcional, aviso de sessão expirada visível em 360px.
  AC-030-012 (clique real de login) PARCIAL — sandbox do subagent bloqueou digitação de
  credencial real (política de segurança, não app indisponível); evidência de rede
  equivalente obtida via `curl` real no endpoint que `LoginForm` chama (200 + cookies
  `HttpOnly` + role correta, direto e via proxy). 6 capturas salvas para o aceite estético
  do Diretor. Achado não-bloqueante: falta regra CSS de autofill nos campos.
- 2026-09-29: **TASK-031-004 Done — PLAN-031 implementado (6/6 TASKs)** (Wave 4/4, final)
  — `page.tsx` monta `LoginNightBackdrop` + card em duas metades (`LoginIllustratedPanel`
  + `LoginForm`) por inteiro pela 1ª vez. Token `--color-night-panel-bg` definido; os 3
  `it.todo` pendentes (borda×painel, botão×painel, rótulo×painel) promovidos a provas
  reais, todos ≥3:1/4,5:1 nos dois temas. `--color-night-button-bg` (tema escuro)
  reajustado para mauve `#6e5d77` — prova matemática de que nenhum tom quase-preto da
  paleta atinge 3:1 contra um painel também quase-preto; `product-designer` confirmou
  coerência visual e fechamento do achado da Wave 1. `code-reviewer` sinalizou (não
  bloqueante, decisão do Tech Lead registrada): o botão ficou mais claro que o painel,
  tensionando a letra de FR-030-005 ("tom escuro") — contraste AA prevalece sobre o
  adjetivo, nota para a Entrega. Hover do botão trocado de `opacity-90` (que derrubava o
  contraste no tema escuro) para `brightness-105`. `performance-engineer` mediu o bundle
  real: os 2 componentes SVG decorativos não vazam JS ao cliente — TRISK-031-002 fechado.
  `security-engineer` confirmou guard de open-redirect e aviso de sessão expirada
  intactos. 620/620 testes verdes, 0 `it.todo` restante. Jira: KAN-146/KAN-73 movidos —
  KAN-73 permanece no teto do trilho (Em andamento) até o merge do Diretor.
- 2026-09-29: **TASK-031-005 Done** (Wave 3/4 de PLAN-031) — `LoginForm` reestilizado:
  campo de e-mail em pílula com `MailIcon` (mesma soma de larguras do `LockIcon` da
  senha, achado ALTA da Wave 2 já respeitado), botão largura total em tom escuro,
  comportamento 100% preservado. 3 rodadas de retry: (1) `product-designer` REPROVOU —
  botão sem `cursor-pointer`/`hover` (média, corrigido); (2) `code-reviewer` REPROVOU 2x
  — gate 1 (rótulo "E-mail" sem par de contraste rastreado; placeholder ligado ao par
  errado, piso 3:1 em vez de 4,5:1) e gate 7 (DRY real: helpers de teste e cadeia de
  classes duplicados entre `login-form.tsx`/`password-field.tsx`) — escopo ampliado pelo
  Tech Lead (degrau 1) para extrair `@utility`/helper compartilhado, migrando
  `password-field.tsx` só por className (NFR-030-004 intacto); (3) `code-reviewer`
  REPROVOU de novo — o `@utility` novo dependia de `var(--tw-border-style)`/
  `var(--tw-outline-style)`, custom properties do Tailwind 4 que só existem quando um
  utilitário NATIVO as registra no scan de produção; sem os testes na árvore, o anel de
  foco sumiria de verdade (regressão de a11y) — corrigido com valor literal `solid`,
  verificado com `next build` real excluindo `.test.tsx`. Lição de processo nova
  registrada (`@utility` nunca referencia `--tw-*`). 611/611 testes verdes (+3 todo
  rastreáveis, aguardando o token do painel em TASK-031-004). Jira: KAN-147 movido para
  Concluído.
- 2026-09-28: **TASK-031-002/003/006 Done** (Wave 2/4 de PLAN-031) —
  `LoginNightBackdrop`/`LoginIllustratedPanel` (SVG decorativo, `aria-hidden`,
  `prefers-reduced-motion`, sem cor literal) e `PasswordField` reestilizado em pílula
  (comportamento 100% preservado). `product-designer` REPROVOU a wave na 1ª rodada:
  achado ALTA real — FR-030-004 exige ícone à esquerda nos DOIS campos (e-mail e senha),
  a decomposição só cobriu o e-mail; corrigido com `LockIcon` decorativo em
  `password-field.tsx`, e critério de alinhamento roteado para TASK-031-005 (ainda Todo).
  + 3 sugestões não-bloqueantes (direção da estrela cadente, visibilidade sob
  `reduced-motion`, halo do blur — este último é achado VISUAL, não de performance,
  registrado para verificação no gate 9/screen-verify). Retry aprovado por todos os 4
  gates (code-reviewer, security-engineer, performance-engineer, product-designer). Lição
  de processo estendida (prova assimétrica entre componentes irmãos corrigidos por
  developers distintos no mesmo retry). `it.todo` de borda×painel roteado como obrigação
  explícita de TASK-031-004. 596/596 testes verdes (+1 todo rastreável). Jira: KAN-144/
  145/148 movidos para Concluído.
- 2026-09-28: fora de escopo achado em TASK-031-002 — 11 erros de lint em
  `mnemonicos-backend/.claude/worktrees/kan-49-vercel-entrypoint/` (worktree paralelo de
  outra feature, KAN-49; parsing error de `eslint.config.mjs` + 10 `console` em
  `prisma/seed.ts`), fora do repo/escopo desta TASK (frontend-only) — não corrigido,
  sinal para quem estiver com KAN-49 aberto.
- 2026-09-28: furo no plano em TASK-031-002 — branch
  `feat/producao-material-login-redesign` existia só no checkout local da main session,
  nunca pushada para `origin`; o subagent `developer` (ambiente isolado) não a encontrou,
  devolveu Blocked — destino: `git push -u origin` a partir do checkout local (degrau 1,
  ajuste localizado), TASK redespachada.
- 2026-09-28: **TASK-031-001 Done** (Wave 1/4 de PLAN-031) — 12 tokens `--color-night-*`
  aditivos no `@theme` de `globals.css` (céu, dunas, lua, estrela, pílula, botão),
  contraste AA medido e provado nos dois temas (`pill-text` 11,92/14,08:1, `pill-icon`
  6,45/7,97:1, `pill-border` 4,20/5,13:1, `button-text` 14,16/15,26:1). 1 retry no gate
  1-7 (`code-reviewer` REPROVOU: prova de ausência de colisão de tokens era tautológica,
  só lia a constante do próprio teste — corrigida para ler `globals.css` real, fixada com
  2 mutantes plantados e confirmados vermelhos pelo revisor em worktree própria). Gate 11
  (`product-designer`) aprovou de primeira, com 3 sugestões não-bloqueantes roteadas como
  critério explícito para TASK-031-005/006 (contraste borda/botão contra o fundo adjacente
  externo — só medível quando os tokens forem consumidos; token de placeholder
  `--color-night-pill-icon`). Gates 8/9/10 n/a (sem superfície sensível/observável/custo
  nesta wave). 569/569 testes verdes. Jira: KAN-143/KAN-73 movidos para Em andamento no
  despacho.
- 2026-09-28: **TASK-031-001..006 criadas via `/keelson:tasks`** (6 tasks, 4 waves: W1
  tokens `@theme` — TASK-001 chore; W2 backdrop/painel ilustrado/PasswordField restyle —
  TASK-002/003/006, paralelas; W3 LoginForm restyle — TASK-005; W4 LoginCardFrame/
  `page.tsx` — TASK-004, integra tudo). Jira: 6 sub-tasks criadas sob KAN-73 (KAN-143..
  148). Rodada consolidada (task-validator + `qa` pré-código, decisão 4.116): 0 ERROR;
  achados reais do `qa` (credencial de seed ambígua no roteiro do gate 9, TRISK-031-004
  sem passos numerados, AC-030-010 sem asserção ligando token usado ao medido, rótulo
  sr-only vs visível, AC-030-005 sem inventário fechado de controles) resolvidos em
  degrau 1 (sem escalação — nenhum era decisão de produto nova). `TASK-031-001` renomeada
  para incluir marcador `-chore-` (achado `task-nome-tipo`). Revalidação: 0 ERROR/WARNING
  nos 6 arquivos.
- 2026-09-28: **PLAN-031 criado via `/keelson:plan`**, cobrindo 100% de SPEC-030 (14 FRs
  + 6 NFRs). `code-scout` (triagem técnica) achou que este projeto tem um único root
  layout — route group não desliga a moldura de `/login` sem reestruturar todo
  `src/app/`. DEC-031-001: fundo em tela cheia via `position: fixed` dentro da árvore
  normal da página (sem route group) — preserva `SiteHeader`/footer de graça. 6 COMPs, 3
  DECs (todas reversíveis), 4 TRISKs. `artifact-lint`/`graph.sh`: 3 ERROR (bug de
  acentuação em "ã" no enum `Irreversível`, mesma classe já roteada ao `agile-coach`) + 2
  WARNING de parsing multi-linha do campo `Realiza` — todos corrigidos mecanicamente, 0
  ERROR na revalidação. Capacidade movida para "Em desenvolvimento".
- 2026-09-28: **SPEC-030 criada via `/keelson:specify`** (BRIEF-030, KAN-73) — redesenho
  visual da tela `/login`. 14 FRs, 6 NFRs, 14 ACs, 6 premissas, 3 RISKs + 1 Q. `po` (modo
  aprovação): APROVAR sobre crítica do `product-analyst`, com pacote de correção de 17
  ajustes (header/footer preservados em `/login`, motivo noturno fixo nos 2 temas,
  cobertura título/preenchimento de pílula/tom escuro/tokens-only, aria-busy/aria-invalid,
  juiz de outcome estético por capturas na Entrega). `spec-validator`: 0 ERROR (2
  falso-positivos conhecidos da ferramenta — `spec-ac-fora-gwt` por acentuação,
  `spec-nfr-sem-numero` por leitura de 1 linha só em bloco multi-linha — roteados ao
  `agile-coach` na Etapa 4.5). Demanda avulsa fora do épico MNEMORA STUDIO — Jira Story
  KAN-73 (issuetype 10009, standalone, projeção compacta — sem Epic).
- 2026-09-27 19:50: furo no plano em TASK-033-003 — estender `ContentVersionDetail` com
  `approvedById`/`approvedAt` quebra a paridade cross-repo (`contents-frontend-contract.test.ts`),
  e o espelho dos tipos estava alocado a TASK-033-006 — destino: ajuste localizado (Tech
  Lead) — quem cria o campo no payload espelha no mesmo diff (regra do CLAUDE.md):
  TASK-033-003 espelha os 2 campos, TASK-033-004 espelha `validApprovalForExport`,
  TASK-033-006 fica só com a mutation RTK Query. Baseline vermelho pré-existente
  (`publication.service.integration.test.ts`, teto de duração CPU-bound — já sancionado
  em PLAN-029) sancionado de novo, gate 2 mede contra ele.
- 2026-09-27 19:15: **Wave 1 de PLAN-033 fechada — TASK-033-001/002 Done.** Migração
  aditiva `20260927135234_add_content_version_approval` (2 colunas nullable
  `approvedById`/`approvedAt` + FK `ON DELETE RESTRICT` + valor `APROVACAO_VERSAO`)
  aplicada em dev e `mnemonicos_test` com autorização do Diretor — a aplicação foi feita
  por ele no terminal: o classificador de permissão do harness recusou `prisma migrate
  dev` e `test:integration` para os agents até ele liberar a regra de permissão.
  `resolveAlterationSignal` (sinal de alteração de conteúdo OU Tira, via
  `ProductionStageEvent`). Gates: 8 APROVADO (0 achados; notas de herança N1/N2/N3/N6
  viraram critérios de TASK-033-003/004/005 antes do despacho, 4.140; N5 — troca de
  imagem de Associação visual não acende o sinal — vai ao Diretor na Entrega, junto de
  E-1); 10 APROVADO (EXPLAIN real confirma DEC-033-007: sem índice composto); 1-7
  TASK-033-001 APROVADO, TASK-033-002 1 retry + degrau 1 da escada (docblocks maiores
  que o código — só-texto). Critério C1 de TASK-033-001 contava "3 ocorrências" num
  universo com 2 pré-existentes (devolve 5; condição verificada pelo delta). Fora de
  escopo: COMP-033-003 do PLAN cita tipo inexistente `ContentVersionRecord`; fixture de
  `VersionedContentFields` duplicada → builder em `tests/support` entrou como critério
  de TASK-033-003.
- 2026-09-27: **PLAN-033 criado e aprovado para SPEC-032 (F9).** Cobertura derivada
  (`graph.sh --format=tables`): 18/18 FRs + 3/3 NFRs, gap 0. 13 COMPs — migração
  aditiva (2 colunas nullable `approvedById`/`approvedAt` + FK + valor
  `APROVACAO_VERSAO`); `approveContentVersion` no mesmo padrão transacional/lock de
  F8 (DEC-029-004 herdada), idempotência por `updateMany` condicionado a
  `approvedById: null` (2ª camada de defesa, DEC-033-009); segregação de funções por
  3 identidades produtoras lidas ao vivo (`ContentVersion.authorId`,
  `RawContent.authorId`/`lastEditedById` — seguro por construção, já que
  FR-032-015 bloqueia aprovação sempre que há edição pós-fechamento, DEC-033-006);
  `resolveAlterationSignal` estende o sinal de F8 (`hasVersionedContentChanged`)
  com um sinal novo para a Tira mnemônica, reusando o `ProductionStageEvent` que
  `tira.service.ts` já emite — zero mudança naquele módulo (DEC-033-007); carimbo
  de aprovação no PDF (`pdf-composer.ts`) substitui "Rascunho" só quando aprovada e
  sem sinal de alteração aceso. 9 DECs (3 herdadas + 6 novas, todas reversíveis).
  `artifact-lint`: 0 ERROR (5 WARNING `plan-dec-alternativa-unica`, mesmo padrão
  aceito de PLAN-029). `graph.sh --check --stage=plan`: 0 ERROR após 2 correções
  mecânicas (campo `**Realiza**` de COMP-033-004 quebrado em 3 linhas escondia
  FR-032-013/017/018 do parser; `**Dependências**` de COMP-033-003 com anotação
  extra quebrava o parse) — aplicadas diretamente pelo Tech Lead. Próximo:
  `/keelson:tasks`.
- 2026-09-27: **SPEC-032 criada e aprovada via `/keelson:continue` → `/keelson:auto`
  (BRIEF-032, F9 do épico MNEMORA STUDIO).** `spec-validator`: 0 ERROR, 4 WARNING
  não-bloqueantes (`spec-must-ratio`, `spec-nfr-sem-numero` ×2, `spec-sem-should-may`
  — aceitos: gate de segurança/correção, MUST é o padrão correto). `product-analyst`:
  REVISAR_ANTES_DE_APROVAR, 3 achados ancorados (escopo do checklist 7×2 contra o
  próprio BRIEF; identidade da segregação de funções divergindo de A-010 dado
  `RawContent.authorId`/`lastEditedById`; atribuição da exclusão de material de
  reforço ao Diretor sem rastro) + vários de reforço (ACs de negação faltantes,
  métrica zerada por construção, selos de evidência incorretos). `po` (modo
  aprovação): **ESCALAR**, 1 escalação não-bloqueante (E-1 — o carimbo deve cobrir
  também a Tira mnemônica? default do PO aplicado: sim), demais achados resolvidos
  como decisões em nome do Diretor — segregação endurecida para o piso de 3
  identidades produtoras (não só quem fechou a Versão), fonte normativa obrigatória
  como pré-condição (herda A-005-008/SPEC-005), duplo travamento anti-corrida (número
  revisado + sinal de alteração pós-fechamento), 6 ACs de negação novos, métrica
  condicionada a 2+ ADMINs + métrica-guarda invariante (0 autoaprovações, 0 carimbos
  indevidos), selos de evidência corrigidos. Pacote de correção aplicado pelo `scribe`
  em modo reescrita (v0.1→v0.2): 18 FRs (2 FEATs), 24 ACs, 11 premissas, 5 riscos.
  RISK-002-001 e RISK-028-004 **resolvidos** por esta SPEC (ver Riscos ativos).
  Pendência para a Entrega: confirmação explícita do Diretor sobre a inclusão da
  Tira mnemônica no escopo do gate (RISK-032-002, default do PO já aplicado). Branch
  do épico `feat/producao-material-mnemora-studio` sincronizada com `origin/main` nos
  2 repos (fast-forward, F8 já mergeado) na largada.
- 2026-09-27: **PRs de F8 mergeados pelo Diretor** — backend
  [#9](https://github.com/marcosmatosteodoro/mnemonicos-backend/pull/9), frontend
  [#15](https://github.com/marcosmatosteodoro/mnemonicos-frontend/pull/15). Trilho
  pós-merge (CLAUDE.md) executado: Histórias KAN-137/138 movidas para Concluído;
  filhos do Épico **KAN-136** consultados por JQL (`parent = KAN-136`, nunca por
  memória) — 3/3 Concluído (KAN-137, KAN-138, KAN-142). **Épico KAN-136 NÃO movido**:
  a transição foi recusada pelo classificador de permissão desta sessão ("ação
  perigosa", sem detalhe) — mover épicos parece exigir ação humana direta no Jira ou
  uma sessão com essa permissão liberada. Pendência declarada, não contornada.
- 2026-09-26: **Entrega de PLAN-029 (F8) fechada — DEC-029-003 confirmada pelo
  Diretor.** `po`: ACEITA_COM_RESSALVAS (nenhum item do brief sem entrega). Sync
  `entrega`: reconciliação (§12) corrigiu 2 sub-tasks presas em "Tarefas pendentes"
  apesar de Done (KAN-139/140 → Concluído) e as 2 Stories (KAN-137/138) para "Em
  andamento" (teto do §9 — marco "Funcionalidade pronta p/ QA" degradado a comentário,
  além do teto); Épico KAN-136 intocado, comentado com branch/push (§11). Achado
  incidental: os marcos automáticos de "TASK iniciada"/"Trabalho iniciado (Story)" de
  waves anteriores parecem ter degradado em silêncio em pelo menos 2 ocasiões nesta
  fatia — sinal para revisão do fluxo de despacho, não investigado a fundo. Branches
  pushadas nos 2 repos (backend `5cfdb18`, frontend `8f76e6d`) e no workspace — merge,
  PR e deploy ficam para o Diretor via `/keelson:integrate`.
- 2026-09-26: **Convergência de fecho verde de PLAN-029 (F8)** — backend `5cfdb18`/
  frontend `8f76e6d` (dedup: aplicada — 1 achado). `graph.sh --check`: 0 achados em
  SPEC-028/PLAN-029/TASK-029-*. Cobertura semântica confirmada FR a FR contra o código
  final (11/11 FRs, 7/7 DECs respeitadas, nenhuma inconsistência entre as 3 waves).
  Achado de dedup, não-bloqueante, registrado como pendência (não desta fatia):
  `content-version-history.tsx` (2 extratores do envelope de erro do backend) repete o
  mesmo caminho já presente em `publication-export-control.tsx`/`visual-library-board.tsx`
  — candidato a consolidar em `lib/fetch-error.ts` (o canônico já existe e já é
  importado por todos), diff de limpeza futuro. Nota de manutenção (não-gap): o
  "único ponto de manutenção" de `versioned-content-diff.ts` não tem checagem de
  exaustividade de tipo — um 12º campo futuro em `VersionedContentFields` entraria no
  snapshot sem entrar automaticamente na comparação (falso negativo silencioso);
  correção barata (lista de chaves `as const`), candidata a fatia futura que tocar o
  recorte. `/keelson:integrate` pode dispensar a repetição desta convergência.
- 2026-09-26: **Wave 2 de PLAN-029 concluída — TASK-029-002/003 Done, FEAT-028-002
  VERIFICADA (F8).** Backend completo de fechamento de Versão + histórico
  (`content-versions.service.ts`, lock `SELECT...FOR UPDATE` + `Promise.all` provando
  corrida real, guarda autor-ou-ADMIN, allowlist explícita do `contentSnapshot`) e
  carimbo de Versão/Data no PDF exportado (`versioned-content-diff.ts`,
  `toVersionedContentFields` consolidado num só ponto de manutenção com `satisfies`
  travando por typecheck). Gates: code-reviewer 1 retry (3 bloqueantes de prova, cada
  um confirmado por mutation testing real em worktree isolada — spy no client Prisma
  ERRADO (raiz em vez do `tx` de transação) nunca falsifica ausência, lição nova em
  `lessons.md`; teste HTTP fail-secure faltando; conversão duplicada) — 2ª rodada
  aprovada; security-engineer e performance-engineer aprovados 1ª rodada (medição real
  de `withQueryProbe`: 2 statements fixos, independente de N). Gate 9 (`qa`) VERIFICOU
  FEAT-028-002 de ponta a ponta com execução real (servidor + Postgres reais, 4
  cenários nas 2 Variantes) — linha gravada na SPEC. Achados fora de escopo
  registrados, não corrigidos: cópias locais de `query-probe.ts` em 2 arquivos de
  teste pré-existentes (`contents.service`/`tira.service`, DRY — candidato a limpeza
  avulsa); ambiguidade de fuso em "hoje" da validação de data futura (DEC-029-006,
  UTC vs. fuso do operador — nuance de produto, não defeito). Próximo: Wave 3
  (TASK-029-004, frontend).
- 2026-09-26: **furo no plano (baseline vermelho) em TASK-029-003 — sancionado, não
  corrigido.** `tests/integration/publication.service.integration.test.ts` (teste de
  teto de duração CPU-bound, AC-024-017/F6, última alteração TASK-027-006) falha
  nesta máquina — a composição real termina DENTRO do teto de 400ms/1500ms
  (calibrado para hardware mais lento), então `GenerationTimeoutError` nunca dispara.
  Confirmado independentemente por 2 developers (Wave 1 e Wave 2 de PLAN-029),
  reproduzível, não-relacionado a F8. Destino: sancionado — a TASK-029-003 prossegue
  com esse vermelho declarado como baseline conhecido (gate 2 mede regressão contra
  ele, não contra suíte 100% verde); corrigir o threshold é fora de escopo de F8
  (território F6/SPEC-024), candidato a `/keelson:triage` futuro.
- 2026-09-26: **Wave 1 de PLAN-029 concluída — TASK-029-001 Done (F8).** Migração
  `20260926185454_add_content_version_versao_editorial` (model `ContentVersion` +
  enum `VERSAO_EDITORIAL`) aplicada em dev+teste. **Furo de processo**: o Tech Lead
  instruiu o developer a aplicar a migração sem antes perguntar ao Diretor — o
  `CLAUDE.md` do workspace exige autorização explícita antes de QUALQUER migração,
  incondicionalmente, mesmo aditiva/dev/modo autônomo; a própria TASK já previa isso
  ("`/keelson:implement` escala via AskUserQuestion antes do 1º passo que aplica"),
  mas o despacho não seguiu. Achado pelo `code-reviewer` (gate 1-7); Diretor
  perguntado via AskUserQuestion **depois do fato** e ratificou a aplicação (100%
  aditiva, produção intocada). Lição de processo roteada ao `agile-coach`: LRN-036
  (`docs/_meta/learning-log.md`) — `PROPOSTA_PLUGIN` contra `commands/auto.md`
  Etapa 0/bullet "Risco" (não confere se a ficha/CLAUDE.md do projeto aperta o piso
  genérico de "migração reversível simples = decide e registra"); mensagem ao
  mantenedor vai na Entrega. Gates: code-reviewer (1 retry — asserção de `closedAt`
  não-discriminante + 2 comentários imprecisos, todos corrigidos) e security-engineer
  (aprovado 1ª rodada) — ambos sobre o diff acumulado da Wave 1. **Pendência de
  deploy**: migração ainda não aplicada em produção — mesmo protocolo de F3/F6/F7
  (`vercel-build` roda `prisma migrate deploy` a cada deploy do backend; entra no
  próximo deploy junto com as anteriores). Próximo: Wave 2 (TASK-029-002/003).
- 2026-09-26: **sync Jira (gancho `tasks`, PLAN-029/F8) — 4 sub-tasks criadas.**
  `TASK-029-002` → KAN-139 (sub-task de KAN-137, FEAT-028-001) · `TASK-029-003` → KAN-140
  (sub-task de KAN-138, FEAT-028-002) · `TASK-029-004` → KAN-141 (sub-task de KAN-137,
  FEAT-028-001) · `TASK-029-001` (sem `Funcionalidade` declarada — chore transversal às
  duas FEATs) → KAN-142, projetada como Tarefa sob o Epic KAN-136 (regra "TASK transversal
  sem primária honesta", `jira-sync-feat.md`) + link "relates to" com KAN-137 e KAN-138;
  **julgamento do sync, não do artefato — revisar com o Diretor se o parentesco pretendido
  para TASK-029-001 era outro.** Nenhuma transição aplicada (gancho de criação, não de
  despacho); as 4 issues nasceram na coluna padrão do projeto (`11` Tarefas pendentes).
- 2026-09-26: **TASK-029-001..004 geradas (F8), rota única.** 4 TASKs em 3 waves: Wave 1
  `TASK-029-001` (chore, migração `ContentVersion`+`VERSAO_EDITORIAL`); Wave 2 paralelas
  `TASK-029-002` (fechamento+histórico, backend, fatia sensível) e `TASK-029-003`
  (carimbo de Versão no PDF); Wave 3 `TASK-029-004` (frontend completo — o scribe
  corrigiu a dependência sugerida pelo Tech Lead, acrescentando TASK-029-003 além de
  TASK-029-002, porque o roteiro do gate 9 exporta o PDF e confere o carimbo). 14/14
  COMPs distribuídos, 11/11 FRs + 3/3 NFRs + 13/13 ACs cobertos. Achado real do scribe
  via cadeia do dado: `recordProductionStageEvent` precisou ganhar um parâmetro opcional
  `transitionType` (retrocompatível) para DEC-029-005 (emissão sempre `CONCLUSAO` direta)
  ser cumprível — extensão de arquivo compartilhado por 6 chamadores existentes,
  conferida sem mudança de comportamento. `graph.sh --check`: 0 ERROR (1 correção do
  Tech Lead — `TASK-029-002` tinha 3 NFRs indevidamente no campo `Realiza (FRs)`, que é
  TASK→FR only por contrato; NFR se verifica na DoD do PLAN, nunca por TASK — e
  `task-overlap-fr` apontou FR-028-005 duplicado entre `TASK-029-002`/`004`: removido de
  `TASK-029-004`, que só CONSOME o endpoint já realizado por `TASK-029-002`, nunca o
  realiza de novo). `task-validator`: 0 ERROR, WARNINGs de `task-criterio-grep-nao-
  ancorado` revisados um a um (nenhum atinge o padrão de escalação a ERROR, exceto 1 em
  `TASK-029-002`/AC-028-006 que foi corrigido — grep de ausência de
  `contentVersion.update/delete` passou a excluir linha de comentário, evitando falso-
  positivo/negativo). Próximo: `/keelson:implement`.
- 2026-09-26: **PLAN-029 criado e aprovado (F8).** Cobertura: 11/11 FRs + 3/3 NFRs de
  SPEC-028 (Caso D). Reconhecimento técnico via `code-scout` (schema de RawContent/
  RuleBreakdown, precedente append-only `ProductionStageEvent`, 2 padrões distintos de
  guarda autor-ou-ADMIN no código, ponto exato do rótulo "Rascunho" em `pdf-composer.ts`,
  slot genérico `supplementary` de `ContentForm`). 7 DECs (2 herdadas + 5 novas), 1
  irreversível: **DEC-029-003 corrigida em voo pelo Tech Lead antes da aprovação** — a
  1ª redação do scribe guardava só um hash SHA-256 para detectar alteração pós-fechamento
  (FR-028-011); o Tech Lead re-julgou contra a escada de reação do `/keelson:auto` para
  DEC irreversível ("prefira alternativa reversível que preserve a decisão para o
  humano") e reverteu para **snapshot JSON completo** dos campos versionados — hash
  sozinho perderia o texto histórico para sempre se o conteúdo mudasse depois do
  fechamento, e essa perda não seria reversível; snapshot com poda futura é. `plan-
  validator`: 0 ERROR, 4 WARNING não-bloqueantes (`plan-dec-alternativa-unica` em 4 DECs
  reversíveis — cada uma com alternativa descartada e custo concreto nomeado,
  verificado). Status Draft → Approved. Pendência: DEC-029-003 não foi confirmada pelo
  Diretor antes de aplicar (default seguro da escada, degrau 2) — entra em lote na
  Entrega. Próximo: `/keelson:tasks`.
- 2026-09-26: **SPEC-028 criada e aprovada (F8, `/keelson:continue` → `/keelson:auto`,
  BRIEF-028).** `spec-validator`: 0 ERROR, 4 WARNING não-bloqueantes (`spec-must-ratio`,
  `spec-nfr-sem-numero` ×2, `spec-sem-should-may`). `product-analyst`: veredito
  `REVISAR_ANTES_DE_APROVAR`, 3 riscos de mérito (carimbo verdadeiro pós-edição; escopo
  do versionamento por tabela vs. o que a Exportação realmente imprime — `pegadinhaText`
  é coluna do próprio `RawContent`; promessas herdadas de expurgo/restauração de
  Conteúdo bruto de SPEC-005/PLAN-006/PLAN-027 não endereçadas). `po` (modo aprovação):
  `APROVAR` com 3 resoluções em nome do Diretor, nenhuma escalação (nenhum dos 3 pontos
  batia nos critérios de escalação) — FR-028-011 nova (marca fail-secure "alterado após
  o fechamento" quando campo versionado muda pós-fechamento, com AC-028-013 e ajuste em
  AC-028-009/métrica §1.3); A-028-002 reescrita recortando o versionamento por CAMPO
  (texto normativo, radar, fonte normativa, 5 blocos+síntese da Quebra — Pegadinha
  elaborada fora, RISK-028-004 novo sobre o alcance do gate de F9); §4.2 ganhou item
  explícito declarando expurgo/restauração de Conteúdo bruto fora de F8 (RISK-028-005
  novo sobre expurgo futuro × append-only). Status Draft → Approved, Versão 0.1 → 0.2.
  0 escalação pendente ao Diretor. Próximo: `/keelson:plan` (DEC irreversível
  snapshot × referência, A-028-004/RISK-028-001, decide lá com alternativas explícitas).
- 2026-09-26: **Sync Jira — gancho `specify` de SPEC-028 (F8).** KAN-136 (Epic-raiz da
  largada, §16) enriquecido: descrição do stub substituída pelo template Epic real
  (Contexto/Escopo/Funcionalidades). `epicPolicy: multi-feature` com 2 FEATs → projeção
  plena confirmada; Stories criadas via `jira-sync-feat.md`: KAN-137 (FEAT-028-001,
  parent KAN-136) e KAN-138 (FEAT-028-002, parent KAN-136), ambas com descrição completa
  (Como testar por AC). Keys gravadas em SPEC-028 (`**Jira**:` sob cada heading FEAT).
  Sem sub-tasks nesta passada (gancho `specify` não cria TASKs — fica para `/keelson:tasks`).
- 2026-09-26: **Reconciliação Jira + `--phase finish-dev` (`/keelson:jira-sync
  producao-material --phase finish-dev`).** Sub-tasks criadas para os 2 furos de PLAN-027
  achados após a reconciliação anterior: KAN-134 (TASK-027-007, sub-task de KAN-122/
  FEAT-026-001 — primária, links "relates to" com KAN-123/FEAT-026-002 e KAN-124/
  FEAT-026-003) e KAN-135 (TASK-027-008, sub-task de KAN-123/FEAT-026-002), ambas nascidas
  já em Concluído (TASKs Done na origem). Verbo `finish-dev` aplicado de baixo para cima:
  as 4 Histórias em "Em andamento" (KAN-122/123/124/126) avançaram para "Em análise" — ato
  explícito do humano, ultrapassando o teto dos ganchos automáticos (§9/§13). KAN-125
  (FEAT-026-004) e KAN-129 (FEAT-026-006) **seguem em "Tarefas pendentes", não movidas**:
  nenhuma TASK do slug as lista como Funcionalidade (primária ou secundária) — cobertura
  existe só via link "relates to" de TASKs concluídas (KAN-133→KAN-125, KAN-130→KAN-129),
  nunca como sub-task filha; sem filho algum, não há sinal de estado real das TASKs para
  alinhar a Story, e mover por impressão seria chute (mesma anomalia já registrada acima,
  2ª sessão sem correção — decisão de produto/organização das FEATs é do Diretor, não do
  sync). Epic KAN-121 intocado (nenhuma linha `epic` para `finish-dev` no mapa — doutrina
  confirmada). Estado final da árvore: Epic `Tarefas pendentes` · 4 Histórias `Em análise`
  · 2 Histórias `Tarefas pendentes` (sem sinal) · 8/8 sub-tasks `Concluído`.
- 2026-09-26: **Reconciliação Jira (`/keelson:jira-sync producao-material`) — conector
  disponível no cloudId correto (`455dadeb-…`, `mp-consultoria`) nesta passada, ao
  contrário das Waves 4/5 (grant só cobria `autoavaliar.atlassian.net`).** Sub-task de
  TASK-027-006 criada (KAN-133, sub-task de KAN-122/FEAT-026-001, links "relates to" com
  KAN-123/124/125) e transicionada a Concluído; KAN-132 (TASK-027-005) alinhada de "Em
  andamento" para Concluído (estado real da TASK não refletido antes). As 6 Stories
  (KAN-122/123/124/125/126/129) comentadas com o marco "Funcionalidade pronta para QA"
  (todas as FEATs de SPEC-026 completas) — sem transição, alvo "Em análise" além do teto
  de desenvolvimento. Anomalia registrada: FEAT-026-004 (KAN-125) e FEAT-026-006
  (KAN-129) nunca receberam sub-task própria (só TASKs com FEAT secundária as cobrem) —
  seguem em "Tarefas pendentes" sem o marco "Trabalho iniciado", apesar de prontas para
  QA. Epic KAN-121 intocado (doutrina). 12 issues pré-existentes com descrição íntegra
  (marcador presente, conteúdo sem drift da SPEC/TASKs) — não re-renderizadas.
- 2026-09-26: **Wave 6 de PLAN-027 concluída — TASK-027-007 (furo no plano fechado),
  PLAN INTEIRO com 7/7 TASKs Done.** Achado na convergência de fecho de `/keelson:integrate`
  (código-reviewer, modo convergência): nenhuma TASK 001-006 montava `ContrastList`/
  `FlashcardList`/`PegadinhaField` em tela — CRUD completo, mas só alcançável via API
  direta. Decisão do Diretor: corrigir agora, antes do PR. Frontend `1cc4c5d` (implementação)
  → `3280af7` (retry consolidado — gates 1-7 e 11 reprovaram na 1ª rodada: achado alta
  de design idêntico em ambos os gates — Pegadinha falso-vazia durante loading/erro do
  titular, permitindo sobrescrever dado real; + posição do bloco de exportação; + id
  duplicado em `aria-*`; + 404 mal atribuído em edição; + DRY; substância corrigida, mas
  o retry introduziu regressão de prova mecânica em 4 asserções de teste — achado
  detectado pelo próprio code-reviewer via mutação) → `3b91a8b` (correção mecânica,
  só teste, aprovado). Gate 9 (qa) **VERIFICADO em browser real** — 1ª verificação de
  tela de fato do PLAN (`gates.screenVerify`), Postgres real, login EDITOR seed dev:
  FEAT-026-001/002/003 confirmadas ponta a ponta. 3 lições novas em `lessons.md`
  ([Design] wrapper com prop nullable ambíguo; [Código] mensagem de erro por status
  com causa múltipla; [Testes] rename de nome acessível quebrando asserção negativa) +
  1 reincidência (posicionamento de exportação depois do material consumido, agora
  confirmada 4×). Ajuste de ambiente local declarado pelo qa: `mnemonicos-backend/.env`
  (não commitado) ganhou `CORS_ORIGINS` com porta alternativa e credenciais de seed
  dev-only, para viabilizar o login real na verificação.
- 2026-09-26: **PRs de PLAN-027 mergeados pelo Diretor** — backend
  [#8](https://github.com/marcosmatosteodoro/mnemonicos-backend/pull/8) (`9b87acc`),
  frontend [#14](https://github.com/marcosmatosteodoro/mnemonicos-frontend/pull/14)
  (`2ceaa6f`), ambos em `main`. Trilho pós-merge (CLAUDE.md) executado: 6 Histórias
  (KAN-122/123/124/125/126/129) movidas para Concluído; filhos do Épico **KAN-121**
  consultados por JQL (`parent = KAN-121`, nunca por memória) — 7/7 Concluído; Diretor
  confirmou que F7 não recebe mais filho e o Épico foi movido para Concluído também.
  Pendente: promoção do front-matter `Status` de PLAN-027 para `Done` (decisão do
  Diretor, ainda não pedida explicitamente).
- 2026-09-26: **PRs abertos para PLAN-027** — backend
  [#8](https://github.com/marcosmatosteodoro/mnemonicos-backend/pull/8) (`d30a705`),
  frontend [#14](https://github.com/marcosmatosteodoro/mnemonicos-frontend/pull/14)
  (`94d1c88`), branch `feat/producao-material-mnemora-studio` nos 2 repos, base `main`.
  `/keelson:integrate` Etapa 1-4: DoD validada, suíte completa reconfirmada (369+479
  backend — 1 flake de teste sensível a CPU, `publication.service.integration.test.ts`
  teto de duração, reproduzido verde isolado e em 2 reruns completos — 519 frontend), lint/
  typecheck limpos nos 2 repos, convergência de fecho **verde na 3ª passada** (backend
  `d30a705`/frontend `94d1c88`, dedup aplicada sem achado novo), 0 segredo nas 2 branches
  inteiras. Mutação/E2E: não configurados (opt-in). `RISK-027-011` registrado (npm audit do
  backend — `mysql2`/`qs`, confirmado pré-existente em `main`, não introduzido por este
  PLAN). Aguardando revisão humana, merge e deploy — Status de PLAN-027 → `Done` é sugestão,
  promoção é decisão do Diretor no merge.
- 2026-09-26: **Wave 7 de PLAN-027 concluída — TASK-027-008 (2º furo no plano fechado),
  PLAN INTEIRO com 8/8 TASKs Done.** Achado na RECONFIRMAÇÃO da convergência de fecho
  (código-reviewer, modo convergência, 2ª passada, depois que a Wave 6 fechou os 2 gaps da
  1ª passada): FR-026-011 ("Pegadinha elaborada recarregada a cada visita") sem mecanismo —
  Contraste e Flashcard já tinham `refetchOnMountOrArgChange` (COMP-027-005/014), a
  Pegadinha (sem COMP de lista próprio, lida via `getRawContent` herdado) nunca ganhou o
  mesmo tratamento em nenhuma das 6 waves anteriores. Frontend `eabdf7b` (implementação —
  opção no painel, subscriber secundário) → gate 10 (performance) e gate 1-7
  (code-reviewer) reprovaram, convergentes: medido 1 GET redundante em série na carga fria
  (o painel monta depois do 1º GET já resolvido; RTK Query não dedupa refetch forçado
  contra entrada `fulfilled`) → `94d1c88` (retry — opção movida para o subscriber
  PRIMÁRIO, `content-form.tsx:129`; teste de revisita reescrito sobre a composição real,
  fria=1/revisita=+1 GET medido por 2 gates independentes) — aprovado nos 2 gates. Achado
  fora de escopo (não bloqueia, registrado): `content-form.tsx` hidrata os campos do
  próprio Conteúdo bruto uma única vez a partir do cache, então o refetch não os atualiza
  na revisita (só a Pegadinha, que lê por prop) — território FR-005/F2, `RISK-027-010`.
  3 lições novas em `lessons.md` ([Performance] refetch em subscriber secundário; [Testes]
  prova de revisita precisa de mesmo store; [Código] refetch não alcança hidratação única)
  + LRN-035 de processo (PROPOSTA_PLUGIN contra `commands/plan.md`, mapeamento FR→mecanismo
  precisa cobrir sujeito sem COMP de lista próprio).
- 2026-09-26: **PLAN-027 implementado (6/6 TASKs), Status → `Done (sugerido)`.** DoD
  validado na Etapa 4: suíte completa 100% verde (479+369 backend, 504 frontend), lint/
  typecheck limpos nos 2 repos; métrica da SPEC (§1.3) confirmada executável contra o
  schema real (`ProductionFlashcard` por `RawContent` ativo com `RuleBreakdown`); as 6
  FEATs (001-006) com linha `**Verificação (gate 9)**:` gravada na SPEC-026 (`graph.sh
  --check` não acusa `feat-sem-verificacao`); `diff-facts.sh --deploy-pending` limpo
  (migração já declarada no INDEX); delta do MAP.md escrito (seção "F7 · PLAN-027") e
  memo de exploração removido (já ausente nesta máquina). Promoção do front-matter do
  PLAN a `Done` é decisão do Diretor, no merge. Aguardando `/keelson:integrate`.
- 2026-09-26: **Wave 5 de PLAN-027 concluída — PLAN INTEIRO com 6/6 TASKs Done.**
  TASK-027-006 (Exportação — Protocolo impresso e composição suplementar no PDF), backend
  `4dc5c91`/`976736b`/`d30a705`. Gates 8 (security) e 10 (performance) aprovados 1ª rodada
  sem achados — segurança confirmou guarda sem `scopeWhere` como intencional (DEC-025-007);
  performance mediu NFR-026-003 por execução real (folga de 3-12x sobre o teto de 12s,
  conforme a máquina). Gates 1-7 e 11 reprovaram 1ª rodada — 3 bloqueantes de prova (6ª
  reincidência da lição DRY — fixture duplicada; comentário sem condição de reversão;
  comentário falso sobre `Function.length`) + 1 achado alta de design (as 4 seções do PDF
  suplementar sem título, Pegadinha sem rótulo nenhum — risco pedagógico real, chegou no
  meio do retry e foi dobrado no mesmo despacho) — todos corrigidos com prova por mutação,
  aprovados 2ª rodada; limpeza de fim de wave aplicada. Gate 9 (qa) verificou as 4 FEATs
  finais (FEAT-026-001/002/003/004) via HTTP real + Postgres real + PDF gerado nas 2
  Variantes, incluindo os 4 títulos de seção e a omissão sem erro. **2 riscos de produto
  registrados para decisão do Diretor na Entrega** (TRISK-027-006: caractere fora de
  WinAnsi em conteúdo do usuário derruba a Exportação inteira; TRISK-027-007: divergência
  DEC-027-005 × COMP-027-018 no alcance de leitura) + 1 risco residual (RISK-027-008,
  Pegadinha longa transborda sem título) + 1 pendência de dedup (fixtures antigas de
  Contraste/Flashcard não migradas para o helper compartilhado). Capacidade movida para
  "Implementadas" (ver acima) — branch `feat/producao-material-mnemora-studio` pronta para
  Etapa 4 (DoD)/Entrega; ainda não pushada, não mergeada.
- 2026-09-26: **Wave 4 de PLAN-027 concluída** (TASK-027-005, Pegadinha elaborada —
  backend `477909f`/`2cb738e`, frontend `3dc4a0f`/`3773048`/`be21bb6`). Retomada após pausa
  de ~9 dias e 4 reinícios de sessão (developer caiu por rate-limit e por encerramento da
  sessão host; trabalho parcial preservado e continuado, nunca refeito). Gates 8 e 10
  aprovados 1ª rodada sem achados — gate 8 confirmou que a guarda em 1 `updateMany` é mais
  segura que o padrão de 2 passos de Contraste/Flashcard (fecha janela TOCTOU; se aquele
  padrão for revisto, o modelo é este). Gates 7 e 11 reprovaram 1ª rodada — 3 bloqueantes de
  prova (eixo soft-delete de `removePegadinhaText`, valor do evento, reflexo real do salvar —
  reincidências de lições ativas, contadores incrementados) e 3 achados de UX (validação
  por erro-no-campo, vazio com próximo passo, verbo canônico "Remover") — corrigidos em 1
  retry, aprovados 2ª rodada; limpeza de fim de wave 4/4 aplicada. FEAT-026-005 e
  FEAT-026-006 completaram nesta wave — gate 9 (qa) em execução. **Tracker degradado**: o
  conector Atlassian desta sessão só tem grant para `autoavaliar.atlassian.net` (outro
  produto); KAN-132 não transicionou — reconexão: autorizar `mp-consultoria.atlassian.net` e
  rodar `/keelson:jira-sync producao-material`. Pendência não-bloqueante (gate 8):
  `store/api.ts` monta paths sem `encodeURIComponent` (~30 ocorrências pré-existentes) — só
  vira risco quando um componente montar com id vindo de `params` da URL.
- 2026-09-16: **KAN-106 (Epic F6, Pipeline de publicação — PDF) fechado no Jira**
  (transição `41`, Concluído), a pedido direto do Diretor — reverte, no mesmo dia, a
  decisão registrada mais cedo de mantê-lo aberto porque "ainda receberia trabalho".
  RISK-025-007 (Tira grande pode exceder o limite de corpo de resposta da Vercel,
  recomendado resolver antes do deploy em produção) e RISK-024-001 (comparação A/B das
  Variantes pendente de julgamento do Diretor) seguem **abertos como risco no INDEX**,
  sem card Jira associado — se algum virar trabalho, nasce em brief/SPEC novo, não
  reabre KAN-106.
- 2026-09-16: **Wave 3 de PLAN-027 concluída** (TASK-027-004, CRUD completo de Flashcard —
  commits `4a27fb4`/`a0a892b`/`adce2b3`/`dcaea3b` backend, `dcd5881`/`c0fdfd4`/`5799394`
  frontend). Gate 8 (security) e gate 10 (performance) aprovados 1ª rodada sem achados —
  TRISK-027-002 (sem teto de volume) desta vez rastreado corretamente no docstring (não
  reincidiu o silêncio da Wave 2). Gate 11 (design) aprovado 1ª rodada — os 3 achados alta
  da Wave 2 honrados de fábrica. Gate 1-7 (code-reviewer) reprovou 1ª rodada — achado
  bloqueante: critério com efeito repartido entre `FlashcardForm`/`FlashcardList` provava
  só os efeitos do componente sob teste, faltando prova de que criar/editar reflete na
  lista exibida (mutante `invalidatesTags` sobrevivia) — corrigido em retry com prova por
  mutação, aprovado 2ª rodada. **Achado confirmado por MEDIÇÃO (não inferência) do mesmo
  buraco em `contrast-list.test.tsx` (Wave 2, já aprovada, não reaberta — 4.88)**: decisão
  de consolidação pendente do Diretor.
  **3 pendências roteadas para ANTES da Wave 4** (TASK-027-005 traz a 5ª/6ª cópia da guarda
  autor-ou-ADMIN e não tem par-de-2-textos, então DEC-027-008 não dispara a mesma forma):
  (1) guarda `actor.role !== 'ADMIN' && ...authorId !== actor.id` inline 4× (Contraste ×2,
  Flashcard ×2) — extrair helper compartilhado quebraria a âncora textual dos testes
  estruturais existentes; decisão de reescrever essa âncora ou aceitar a duplicação fica
  com quem retomar; (2) `extractFunctionBody`/`firstExecutableLine` triplicados em
  `tira`/`contrasts`/`flashcards.service.guard-order.test.ts` (~90 linhas de mecanismo puro
  cada) — candidato a `tests/support/`; (3) `ContrastList`/`FlashcardList` ainda não
  montados em nenhuma página (FR-026-017/FR-026-020 sem tela hospedeira declarada em
  nenhum COMP do PLAN-027) — item para a convergência de fecho ou próxima fatia.
  **Ciclo pausado a pedido do Diretor** — `/keelson:continue` retoma na Wave 4
  (TASK-027-005, Pegadinha elaborada).
- 2026-09-16: **Wave 2 de PLAN-027 concluída** (TASK-027-003, CRUD completo de Contraste —
  commits `9b6115f`/`7b6380a`/`f4e97e6` backend, `6ccb21a`/`cbcc850` frontend). Gate 8
  (security) e gate 10 (performance) aprovados 1ª rodada sem achados. Gates 1-7
  (code-reviewer) e 11 (design) reprovaram 1ª rodada — 2 bloqueantes de prova
  (500 genérico da rota, paridade cross-repo medindo tipo errado) e 3 achados alta de
  acessibilidade (id de erro duplicado entre 2 instâncias de `ContrastForm`; edição
  in-place sem "Cancelar"; nome acessível não-único nos botões da lista) — todos
  corrigidos em 1 retry consolidado com prova por mutação, aprovados 2ª rodada. Pendência
  não-bloqueante roteada a TASK-027-004/006: falta prova de forma do corpo de sucesso HTTP
  de Contraste (`CONTRAST_DETAIL_SELECT` sem asserção comportamental — a rede de paridade
  cobre só a interface declarada). Guarda autor-ou-ADMIN inline 2× (Contraste); nasce 3ª/4ª
  cópia em TASK-027-004/005 — ponto natural de extração de helper compartilhado na Wave 3,
  não é gap desta wave. Tracker (`jira.enabled: true`): ver ledger da sessão.
- 2026-09-16: **Wave 1 de PLAN-027 concluída** (TASK-027-001 schema/migração aditiva —
  Contrast/ProductionFlashcard/pegadinhaText/MATERIAL_REFORCO, commit `c6f37f1`;
  TASK-027-002 `ConfirmRemoveDialog` compartilhado — commits `27e68b0`/`cf11054`/
  `8bab246`). Gates 1-7/8/10 aprovados 1ª rodada; gate 11 reprovou TASK-027-002 na 1ª
  rodada (foco pós-sucesso incompleto), corrigido em retry e aprovado 2ª rodada — mesmo
  achado reabriu gates 1/7 do code-reviewer, também aprovados na 2ª rodada. Migração
  aplicada no Postgres de dev local (autorização do Diretor); produção não tocada.
  Tracker (`jira.enabled: true`, KAN-121): gancho de closure best-effort, ver ledger da
  sessão. Próximo: Wave 2 (TASK-027-003, Contraste CRUD).
- 2026-09-16: gancho `closure` do sync Jira (Wave 1 de PLAN-027) executado — conector
  autorizado (`atlassianUserInfo` respondeu). Story implícita de FEAT-026-005 criada
  (`KAN-126`, sem key prévia); TASK-027-001 projetada como tarefa transversal sob o Epic
  por não ter Funcionalidade primária (`KAN-127`, achado: TASK sem campo `Funcionalidade`
  nem marcador `transversal (...)` — tratada pela régua de "TASK transversal sem
  primária honesta" do `jira-sync-feat.md` por analogia, decisão de best-effort do
  tracker-sync, não do humano); TASK-027-002 virou sub-task de `KAN-126` (`KAN-128`).
  Transições `auto`: KAN-127/KAN-128 → Concluído; KAN-126 → Em andamento (teto de
  desenvolvimento — marco "Funcionalidade pronta p/ QA" não se aplica, FEAT-026-005 tem
  outras TASKs (003/004/005) ainda não concluídas). Descrição de `KAN-127` sem cenário
  Dado/Quando/Então (chore sem AC) — lacuna nomeada, não é card ausente.
- 2026-09-16: refino de waves ainda não despachadas (decisão 4.301) em TASK-027-003/
  004/005 — critério "Integração do diálogo de confirmação" prescrevia "devolver o foco
  ao gatilho" também no desfecho de SUCESSO, mas nesse caso o gatilho (botão "Remover" do
  item) é desmontado pelo `invalidatesTags`; ficaria focando um nó morto. Origem: achado
  alta do gate 11 (`product-designer`) na Wave 1 de PLAN-027 — `ConfirmRemoveDialog`
  (TASK-027-002) reprovou por não distinguir o ramo 'survivor' (sucesso) do 'restore'
  (cancelar/falha), mesmo defeito já corrigido no molde `mnemonic-strip-board.tsx`
  (`ae7bb78`). Corrigidos os 3 critérios para nomear o alvo estável do SUCESSO
  explicitamente (formulário de criação em 003/004, textarea em 005) via nova prop
  obrigatória `focusAfterRemoveRef`; TASK-027-002 volta ao developer em retry para
  implementar a prop e o ramo faltante. Lição registrada: `guidelines/project/lessons.md`
  ("Item de lista que renderiza a MESMA entidade..." — corolário de extração entre
  waves distintas).
- 2026-09-16: **PLAN-027 decomposto em 6 TASKs via `/keelson:tasks`** (rota fan-out,
  18 COMPs > teto de 10 — decompositor + 2 redatores em paralelo, decisão 4.310). 5
  waves (não 3 como o manifesto original propunha): o `task-validator` achou uma
  colisão de escrita real (`task-wave-overlap-arquivo`) — TASK-027-003/004/005
  (Contraste/Flashcard/Pegadinha) editam os MESMOS arquivos compartilhados
  (`domain/types.ts`, `types/domain.ts`, `store/api.ts`, `http/routes.ts`,
  `contents-frontend-contract.test.ts`) e não podiam ficar na mesma wave
  paralelizável — re-sequenciadas em cadeia (003→004→005, Waves 2-3-4), TASK-027-006
  (Exportação) passa a Wave 5. 2ª correção mecânica: TASK-027-001 (chore) sem o
  marcador `-chore-` no nome do arquivo, renomeada. Cobertura: 29/29 FRs, 5/5 NFRs,
  23/23 ACs, 18/18 COMPs, 0 gap. `task-overlap-fr` (FR-026-024/029 realizados por
  3-4 TASKs) é sobreposição justificada por desenho — mecanismo compartilhado
  (TASK-002) + efeito por tipo (TASK-003/004/005), não erro de decomposição.
- 2026-09-16: **PLAN-027 criado via `/keelson:plan` e promovido a `Approved`** (SPEC-026,
  F7, cobertura total Caso D: 29/29 FRs + 5/5 NFRs). 18 COMPs, 8 DECs (todas reversíveis),
  5 TRISKs. Decisões estruturais: `Contrast`/`ProductionFlashcard` como models N:1 diretos
  com `RawContent` (sem precedente pronto no slug — mais próximo é `MnemonicFrame`, um
  nível abaixo); achado real do `scribe` durante a redação — já existe `model Flashcard`
  legado (SRS/`CardState`/`Review`, dormente desde F2) que colidiria de nome com o
  Flashcard novo, resolvido nomeando o model novo `ProductionFlashcard` (DEC-027-003) —
  "Flashcard" na UI/vocabulário passa a cobrir 2 conceitos de backend distintos, sem
  confusão para o usuário (rotas/telas usam só o termo de produto). Pegadinha elaborada
  vira coluna nullable em `RawContent` (sem tabela própria). Protocolo impresso continua
  sem persistência. Exportação ganha composição suplementar (`buildSupplementaryPagesPdf`
  + `copyPages`) nas 2 Variantes. Validação: 0 errors reais — achado de mais um falso
  positivo do lint (`plan-dec-irreversivel-enum` reprova `Irreversível: não` acentuado,
  quando o próprio template e 2 PLANs aprovados do slug usam essa forma; roteado como
  aprendizado junto do achado equivalente de SPEC-026). Próximo passo: `/keelson:tasks`.
- 2026-09-16: **SPEC-026 criada via `/keelson:specify` e promovida a `Approved`**
  (F7 do épico MNEMORA STUDIO — Contrastes, pegadinha elaborada, flashcards e
  protocolo impresso de revisão). Validação de forma: 0 errors (`spec-validator`);
  achado de falso positivo do lint no check `spec-ac-fora-gwt` roteado como
  aprendizado (2 SPECs aprovadas do slug já usam o mesmo formato de AC). Crítica
  de mérito do `product-analyst`: `REVISAR_ANTES_DE_APROVAR`, 9 achados reais.
  `po` (modo aprovação): `ESCALAR` — 7 resoluções aplicadas direto (fecha
  Q-026-001 amarrando-a a A-012 do A/B tira×resumo; selo de evidência corrigido
  em A-026-001/002/003; novo estado de Exportação sem material; falha/confirmação
  de remoção; herança de A-022-011/RISK-011-005) + 3 escalações (E-01/E-02/E-03,
  ver Riscos ativos) resolvidas pelo Tech Lead via degrau 2 da escada (default do
  `po` aplicado, reversível, não contamina o ciclo — confirmação em lote na
  Entrega de F7). Maior mudança: Contraste e Pegadinha elaborada passam a entrar
  na Exportação junto com Flashcard e Protocolo (os 4 conceitos, não 2). SPEC
  final: 6 FEATs, 29 FRs, 5 NFRs, 23 ACs, 10 premissas, 5 riscos (RISK-026-002
  resolvido). Jira: Epic KAN-121 (linked a KAN-6), Stories KAN-122/123/124/125.
- 2026-09-15: **F6 (PLAN-025) mergeada em `main` nos 2 repos** — PR #7 backend
  (`5d6b4df`) e PR #13 frontend (`b54b6ef`), Diretor. Épico avança para F7/F8
  (ambas dependem só de F2/F6, entregues). RISK-025-007 segue aberto — Tira
  grande com imagens pode exceder o limite de corpo de resposta da Vercel;
  não bloqueou o merge, mas recomendado resolver antes do deploy em produção.
- 2026-09-15: **Gate 9 (comportamento) de PLAN-025 — VERIFICADO de verdade,
  `HANDOFF-PLAN-025.md` fechado (`status: Concluído`).** Diretor autorizou e
  aplicou a migração (`npx prisma migrate dev`) e reiniciou o servidor de dev
  do frontend — `qa` exercitou os 3 itens do roteiro (V1-V3) com ambiente
  real: **V1** — as 2 Variantes exportadas com sucesso na tela do Conteúdo
  bruto, download real confirmado (`%PDF-1.7`), `Content-Disposition`
  coerente, os 2 status simultâneos sem regressão entre Variantes. **V2** —
  fixtures antigos já não cobriam mais "Tira vazia" (Quadros de rodadas
  anteriores); criados 2 RawContents novos, confirmando gating nos 2
  sentidos (vazio → controle ausente; ≥1 Quadro → presente) e — achado
  valioso — **exatamente 1 evento `ABERTURA` gravado** mesmo com a Tira
  auto-gerada fora do fluxo da UI (via chamada direta à API) seguida de 2
  visitas humanas subsequentes no browser, confirmando FR-024-013/DEC-025-003
  na prática, não só em teste isolado. **V3** — falha controlada sem Quebra
  da regra: 404 estruturado (`NOT_FOUND`) nas 2 Variantes, nunca 500 cru,
  `role="alert"` correto, sem regressão entre os 2 alertas. RISK-025-005
  (Turbopack) selado. Achado não-bloqueante (sugestão): aviso de dev do RTK
  Query sobre `Blob` não-serializável no cache — cosmético.
- 2026-09-15: **Gate 10 (performance) de PLAN-025, rodado pela 1ª vez nesta fatia
  (gap identificado pelo próprio Tech Lead — o DoD do PLAN já pedia essa medição e
  nunca tinha sido despachada).** REPROVOU com 2 achados reais, medidos contra
  Postgres real e composição de PDF real (não estimados): **(1) defeito real,
  corrigido** — o teto de duração (`withDeadline`/`Promise.race`+`setTimeout`,
  DEC-025-002) não cortava no prazo quando a composição envolve decode/encode
  síncrono de imagem (`pdf-lib`); medido: timer de 200ms atrasava 8318ms numa
  composição de 20 Quadros — o teste de AC-024-017 usava um dublê `setTimeout` que
  não provava nada. Corrigido cedendo o event loop 1x por Quadro no laço de
  composição (commits `16bb218`/`6a5af2b`, gate 1-7 aprovado com 2 mutantes reais);
  resíduo medido: `doc.save()` em si é um bloco síncrono sem ponto de cessão
  possível, ~3,1s para N=20 — overshoot caiu de ~8,3s para ~3,2s, não foi
  eliminado. **(2) risco real de produção, NÃO corrigido, escalado ao Diretor** —
  sem teto cumulativo de custo (bytes+pixels), N=20 Quadros com imagem de 4,76 MB
  cada bate o teto de 12s e chega a 872 MB de rss (perto do teto de 1024 MB da
  function); pior, o CORPO DE RESPOSTA chega a 95,3 MB, muito acima do limite de
  ~4,5 MB de function serverless da Vercel — qualquer Tira acima de ~1 Quadro com
  imagem de 5 MB provavelmente já falha em produção hoje, antes mesmo de estourar
  tempo/memória. TRISK-025-003 atualizado (REPROVOU); Q-024-001 deixa de ser
  questão aberta e vira requisito (teto cumulativo e/ou job assíncrono — decisão de
  produto do Diretor, fora do escopo desta fatia). TRISK-025-001 fechado por
  medição (migração aditiva sem lock/reescrita, confirmado com 500k linhas). Lição
  de código registrada (`lessons.md` + `node-22.md` §10).
- 2026-09-15: **Etapa 5 (Entrega) de PLAN-025 — aceitação do PO contra BRIEF-024:
  ACEITA_COM_RESSALVAS.** Correspondência pedido×entregue confirmada em todos os itens
  do BRIEF (2 Variantes, rótulo rascunho, postura de segurança, imagem-nunca-bloqueia,
  sem reprocessamento, escopo negativo respeitado, DEC-025-001/007 e E-024-01
  implementados como descrito). 1 ressalva de correspondência real (**R-1**): a tela do
  Conteúdo bruto não tinha a mesma guarda de "Tira vazia" aplicada à tela da Tira na
  Wave 7 — nem no frontend nem no backend, então um PDF em branco seria baixado como
  sucesso por esse caminho. **Corrigido via TASK-025-014** (Wave 8 retroativa): nova
  classe `NothingToExportError` (409) recusa a Variante "tira" com 0 Quadros no backend
  (fecha as duas telas de uma vez); `PublicationExportControl` discrimina o código e
  mostra mensagem orientada em vez de "tente novamente". 1ª rodada de gate 1-7
  REPROVOU por 3 eixos (escopo — sem artefato-pai; decisões — SPEC contradizia o
  código; qualitativo — mensagem falsa ao usuário); todos fechados: SPEC-024 emendada
  (FR-024-017/AC-024-021, 17/17 FRs, 21 ACs), TASK-025-014 criada retroativamente,
  mensagem do frontend corrigida. Rodada 2: APROVADO. RISK-024-001 elevado (E-2 da PO —
  agora sustenta código entregue, decisão do A/B fica para o Diretor) e RISK-025-006
  registrado (E-3 — imagem WEBP/acima do teto de pixels nunca aparece no PDF,
  degradação silenciosa, já catalogado tecnicamente em TRISK-025-006). E-4 (audit de
  `pdf-lib` + `npm audit fix` do `qs`) fica para o Diretor (`/keelson:audit` é
  humano-only). Gate 9 de TASK-025-014 segue `pendente_handoff`, mesmo bloqueio de
  ambiente do `HANDOFF-PLAN-025.md`.
- 2026-09-15: **Etapa 4 (DoD) de PLAN-025 — gate 9 consolidado PARCIAL,
  `HANDOFF-PLAN-025.md` criado.** Suítes completas rodadas 1x: backend 353/353
  (unit) + 395/395 (integration — migração da fatia já aplicada no
  `mnemonicos_test`, confirmando o degrau 1 de sempre), frontend 444/444;
  typecheck/lint limpos (exceto a worktree órfã não relacionada, pendência
  antiga). `qa` tentou exercitar de ponta a ponta com os 2 enxertos da Wave 7
  já no ar (fixtures reais criados/reaproveitados) e achou 2 bloqueios, ambos
  de AMBIENTE — nenhum defeito de código: (1) migração
  `20260914175940_add_publicacao_pdf_publication_event` segue não aplicada no
  Postgres de dev (autorização é ato do Diretor); (2) achado NOVO — o pool de
  compilação do Turbopack do servidor de dev do frontend estava
  permanentemente quebrado desde o boot desta sessão (`turbopack.root`
  ausente, workspace-mãe symlinkado com lockfile próprio confundindo a
  resolução de raiz), devolvendo 500 em QUALQUER rota nova — confirmado
  não-específico do diff (mesmo 500 em `/content/:id/breakdown`, rota
  intocada por esta fatia). RISK-025-005 registrado; fix de config aplicado e
  commitado (`3115fec`, `next build` limpo confirma), mas o PROCESSO já em
  execução precisa ser reiniciado pelo Diretor para pegar o fix — ambos os
  bloqueios documentados em `docs/producao-material/handoffs/HANDOFF-PLAN-025.md`
  com roteiro de re-verificação (V1-V3) e fixtures prontos. MAP.md recebeu o
  delta completo de F6 (seção "Publicação"); memo de exploração removido
  (superado pelo MAP). Lição de projeto "[Config] turbopack.root ausente..."
  registrada em `lessons.md`.
- 2026-09-14: **Wave 7/7 de PLAN-025 concluída (13/13 TASKs Done — todas as TASKs do
  PLAN entregues)** — os 2 enxertos finais que expõem `PublicationExportControl`
  (TASK-025-011) nas telas reais: `content-form.tsx` (TASK-025-012, Conteúdo bruto) e
  `mnemonic-strip-board.tsx` (TASK-025-013, Tira mnemônica). TASK-025-012 fechou com 1
  retry (gate 11 — reordenar o controle para depois do link da Quebra da regra, já que
  exportar sem Quebra falha no backend). TASK-025-013 foi a mais convergente da wave: 1º
  retry corrigiu 3 achados reais simultâneos — (a) mesmo problema de posicionamento; (b)
  achado mais sério: exportar a Tira com `frames.length === 0` produzia PDF de 1 página
  em branco mas a UI anunciava sucesso — corrigido condicionando todo o controle a
  `frames.length > 0`; (c) RISK-011-008 deixou de ser hipótese — `hasData`/`isNotFound`
  não eram mutuamente exclusivos por construção (confirmado por probe real: refetch que
  vira 404 retinha `hasData=true` por o RTK Query preservar `data` do último sucesso),
  corrigido derivando `hasData` de `isSuccess` em vez de `data !== undefined`; 2º retry
  (só-texto, 4.88, não reabriu o ciclo comportamental) removeu narrativa de rodada de
  revisão que tinha vazado para dentro de comentários/nomes de teste. RISK-025-004
  registrado (achado não-bloqueante: feedback de exportação em voo se perde se o
  componente desmontar — débito pré-existente do componente compartilhado
  `PublicationExportControl`, fora de escopo de PLAN-025). Gate 9 (`qa`) de ambas
  segue `pendente_handoff`, mesmo bloqueio já registrado na Wave 6 (migração
  `20260914175940_add_publicacao_pdf_publication_event` não aplicada no Postgres de
  dev) — agora com as 3 TASKs de frontend prontas, a Etapa 4 (DoD) é o próximo passo, e
  a autorização do Diretor para aplicar a migração é urgente.
- 2026-09-14: **Wave 6/7 de PLAN-025 concluída (11/13 TASKs Done)** —
  `PublicationExportControl`, componente client que reage aos 3 estados observáveis por
  Variante (AC-024-006: em andamento/sucesso/falha), `role="status"`/`role="alert"`
  conforme o padrão canônico. 1 retry (gate 11 — product-designer: faltava estado de
  sucesso visível in-page; a página só reagia via download de arquivo, sem confirmação
  textual — corrigido, `role="status"` de sucesso adicionado). Gate 9 (`qa`,
  `screenVerify.enabled`) devolveu **PARCIAL**: ambiente real confirmado (app/browser/
  login EDITOR reais, RawContent + Quebra reais criados), mas 2 bloqueios reais impedem
  a verificação E2E completa — (1) `POST /contents/:id/publication` → 500 nas 2
  Variantes porque a migração `20260914175940_add_publicacao_pdf_publication_event`
  (já commitada) não está aplicada no Postgres de dev — **autorização do Diretor para
  aplicar a migração agora urgente**, QA corretamente não a aplicou por conta própria;
  (2) o componente ainda não está enxertado em nenhuma tela (TASK-025-012/013, Wave 7,
  ainda não implementadas). Handoff consolidado na Etapa 4 (DoD), após a Wave 7. QA
  trouxe 1 `licao_candidata` (alvo: processo) propondo uma 5ª causa nomeada
  ("schema_desatualizado") no enum de indisponibilidade de `handoff-protocol.md` §8.1 —
  ainda não roteada ao `agile-coach`.
- 2026-09-14: **Wave 5/7 de PLAN-025 concluída (10/13 TASKs Done)** — mutation
  `exportPublication` (RTK Query, primeiro `responseHandler` binário do frontend). 1
  retry (gate 1: ramo de fallback de parsing de `Content-Disposition` sem aspas nunca
  exercitado por teste — removido, já que o único emissor real sempre emite com aspas;
  lição estendida em `guidelines/project/lessons.md`). 2 pendências não-bloqueantes para
  TASK-025-011: (a) armazenar o `Blob` no cache RTK dispara `console.error` do
  `serializableStateInvariantMiddleware` (ruído de dev, não afeta build/runtime); (b) o
  guard `filename === ''` (header ausente) segue sem consumidor e sem teste — vira
  exigência real quando o componente de download existir.
- 2026-09-14: **Wave 4/7 de PLAN-025 concluída (9/13 TASKs Done)** — `POST
  /contents/:id/publication`, a barreira de autorização REAL do pipeline
  (NFR-024-003, `requireRole('EDITOR','ADMIN')` + `verifyOrigin`; o service de baixo
  nível não checa papel por desenho). 1 retry (gate 1: a rota tinha sido excluída do
  bloco de topologia de `route-authz-matrix` em vez de enumerada — deixava o conjunto
  `{EDITOR, ADMIN}` sem prova completa, mutante que remove `'ADMIN'` sobrevivia;
  corrigido enumerando a rota, mutante agora morre). Tripwire 34→35 pares. Gates 1-7 e
  8 aprovados. Achados fora de escopo registrados (não corrigidos): `eslint.config.mjs`
  não ignora `.claude/worktrees/**` (deixa `npm run lint` completo estruturalmente
  vermelho); falta `.gitattributes` (ruído CRLF em `format:check`); texto de
  TASK-025-006 cita símbolo (`exportPublicationParamsSchema`) que não existe (o código,
  correto, reusa `rawContentIdParamSchema`).
- 2026-09-14: sync Jira pulado (conector Atlassian caído — `getJiraIssue` sem resposta em
  300s, 2 tentativas) — KAN-115 (TASK-025-008) não transicionada para Concluído. Retomar:
  `/keelson:jira-sync producao-material --phase finish-dev`.
- 2026-09-14: **Wave 3/7 de PLAN-025 concluída (8/13 TASKs Done)** — `exportPublication`,
  função central de orquestração (guarda de alcance + leitura + composição + evento).
  Confirma em código a resolução do achado do PLAN sobre AC-024-018/DEC-025-007: LEITURA
  de material já existente (Quebra, Tira já aberta) usa a guarda nova sem autoria; só a
  AUTO-GERAÇÃO da Tira continua restrita ao autor original (herdado de F4) — comportamento
  real medido é 404/`NotFoundError`, não 409/`ConflictError` como o texto original do
  PLAN presumia (corrigido). 1 retry (gate 1: faltava prova do cabeamento de
  `suppressOpeningEvent`; gate 6: `relationLoadStrategy` não medido/fixado para relação
  de lista; gate 7: 2 achados de DRY — `actorOf` e fixture WEBP duplicados). Gates 1-7 e
  8 aprovados após o retry.
- 2026-09-14: **Wave 2/7 de PLAN-025 concluída (7/13 TASKs Done)** — schema Zod de
  exportação (dedup com `rawContentIdParamSchema` de F2) e motor de composição de PDF
  (`pdf-lib`, `buildSummaryPdf`/`buildStripPdf`). Convergência mais longa e mais séria do
  slug até aqui: **3 vulnerabilidades reais de decompression bomb** encontradas e
  fechadas em sequência pelo gate 8 (falta de teto de pixels/APNG antes do decode →
  bypass por chunk decoy antes do IHDR → bypass por IHDR duplicado com semântica
  last-wins no decoder real) — fechado com refatoração estrutural (`walkPngChunks`,
  varredura única de chunk reusada pelos dois predicados de leitura de PNG), não mais
  patches pontuais. Mais 5 achados do gate 1-7 (rótulo de Variante ausente no cabeçalho,
  prova de ausência de rede cega ao especificador `node:`, buffer JPEG com ArrayBuffer
  não-exato quebrando silenciosamente em produção, schema duplicado, fixtures de teste
  duplicadas — 5ª reincidência da lição DRY). 7 commits de retry ao todo. 2 achados de
  supply chain (RISK-025-002): `mysql2` rebaixado de high para risco não-explorável
  (projeto é PostgreSQL) e `qs` moderate alcançável, com fix disponível — registrado como
  ajuste pontual pendente, fora do diff desta wave.
- 2026-09-14: **Wave 1/7 de PLAN-025 concluída (5/13 TASKs Done)** — migração aditiva
  gerada (não aplicada em dev/prod), tipos `PublicationVariant` cross-repo,
  `GenerationTimeoutError`, `wrapTextToLines` (função pura), EMENDA de `tira.service.ts`
  (supressão do evento de abertura na auto-geração, FR-024-013/AC-024-015). Gate 8
  (security-engineer): APROVADO, 0 achados. Gate 1-7 (code-reviewer): 1 retry em
  TASK-025-005 — 2 achados bloqueantes fechados (prova estrutural de ordem de guarda
  quebrada pelo novo parâmetro, extrator corrigido; DEC-025-003 não seguida à risca,
  `decideStageTransition` canônica agora importada — 4ª reincidência da lição DRY,
  atualizada em `guidelines/project/lessons.md`). Nova lição registrada: "[Testes]
  Extrator textual de código para prova estrutural precisa de controle positivo
  OBRIGATÓRIO". 2 notas prospectivas do security-engineer para a Wave 3 (TASK-025-008):
  corrida check-then-act na decisão de reabertura sob concorrência, e
  `GenerationTimeoutError` não deve receber mensagem crua do motor de PDF.
- 2026-09-14: furo no plano em TASK-025-001 — Escopo não incluía a extensão de
  `domain/types.ts`/`PRODUCTION_STAGE_TYPES` (necessária de verdade: sem ela,
  `npm run typecheck` quebra em `production-events.service.ts:96`), diferente do
  precedente `TASK-023-001` que incluía o passo equivalente — destino: ajuste localizado
  no próprio arquivo da TASK (Inclui), aplicado pelo developer como auxiliar necessário,
  mesmo padrão mínimo do precedente.
- 2026-09-14: decisão em autonomia (Tech Lead, degrau 1) — `npm run test:integration`
  rodado pelo developer de TASK-025-001 (verificação extra, além do exigido pela TASK)
  disparou `globalSetup` do harness de integração, que aplica `prisma migrate deploy`
  incondicionalmente contra `mnemonicos_test` (banco local descartável, não
  dev/produção) — aplicou a migração aditiva `20260914175940_...` nesse banco sem
  pergunta prévia. Avaliado como comportamento padrão e pré-existente do harness (todo
  `test:integration` já sincroniza esse banco descartável; mesmo mecanismo que
  permitiu F3/F4/F5 testarem migrações próprias antes do merge) — não é a leitura que a
  regra do CLAUDE.md do workspace ("toda migração exige perguntar antes") mirava (banco
  de dev/produção). Nenhuma ação de reversão tomada (reverter empilharia mais DDL não
  perguntado). Registrado para a Entrega — Diretor pode pedir `docker compose down -v`
  se preferir o banco de teste limpo antes do próximo `test:integration`.
- 2026-09-14: achado fora de escopo (developer, TASK-025-001) — `mnemonicos-backend/
  .claude/worktrees/kan-49-vercel-entrypoint/` é um worktree git de outra branch
  (`fix/kan-49-vercel-entrypoint-500`), untracked, aninhado dentro do repo; o comando
  literal `quality.lint` da ficha (`npm run lint`) sai estruturalmente vermelho por
  causa dele (11 erros, todos lá dentro) para qualquer TASK futura rodada a partir desta
  working copy. Pré-existente, não introduzido por esta fatia. Estacionado — sugestão:
  mover o worktree para fora do diretório do repo, ou excluir `.claude/worktrees/**` do
  `eslint.config.mjs`; candidato a `/keelson:triage`.
- 2026-09-14: **PLAN-025 decomposto em 13 TASKs via `/keelson:tasks`** (rota fan-out,
  decisão 4.310 — 1 decompositor + 3 redatores em paralelo), 7 waves. `graph.sh --check`
  limpo. `task-validator`: 2 seções ausentes + 1 override incompleto corrigidos; 3
  `task-criterio-sem-ac` mantidos `OVERRIDDEN` (calibrados por exemplares Done). `qa`
  (pré-código, Etapa 3.5): achou e fechou 1 gap real (leitura de binário real de
  Associação visual + mapeamento WEBP→null sem prova em nenhuma TASK — corrigido em
  TASK-025-008). Índice: `tasks/TASK-025-INDEX.md`.
- 2026-09-14: **sync Jira das TASKs de PLAN-025** — 13 sub-tasks criadas sob KAN-107
  (KAN-108..KAN-120, uma por `TASK-025-{001..013}`), keys gravadas em `**Jira**:` de cada
  TASK.
- 2026-09-14: **PLAN-025 aprovado via `/keelson:plan`** (F6, SPEC-024) — cobertura total
  (16/16 FRs, 4/4 NFRs), 13 COMPs, 7 DECs, 8 TRISKs. Motor de PDF: `pdf-lib` (DEC-025-001,
  Irreversível: sim — vai à Entrega em lote, junto de DEC-025-007, achado do PLAN sobre
  tensão entre AC-024-018 e a guarda de autoria real herdada de F4). Próximo passo:
  `/keelson:tasks`.
- 2026-09-14: **SPEC-024 criada e aprovada via `/keelson:specify`** (F6 do épico MNEMORA
  STUDIO, BRIEF-024) — pipeline de publicação, geração sob demanda de PDF rascunho em 2
  Variantes (tira/resumo). 16 FRs, 4 NFRs, 20 ACs após pacote de correção consolidado do
  `po` (métrica com fonte mista, imagem irrenderizável degrada sem derrubar tudo, teto de
  duração como falha informada, 1 Quadro/página, autorização herdada com prova própria,
  rótulo de rascunho em toda página + data de geração). 1 escalação pendente para a
  Entrega (E-024-01, default aplicado). Jira `KAN-106` (Epic-raiz) + `KAN-107` (Story).
  Próximo passo: `/keelson:plan`.
- 2026-09-14: **Wave 6/6 de PLAN-023 concluída — PLAN-023 IMPLEMENTADO (17/17 TASKs)** —
  `getVisualAssociationBinary`/`GET /visual-associations/:id/image` (entrega autenticada
  do binário) e a rede de paridade cross-repo do acervo visual (`visual-associations-
  frontend-contract.test.ts`, 7+4 campos conferidos contra o código real dos 2 repos).
  Achado real confirmado por mutação: `Content-Type` allowlist fechada — sem a guarda, a
  rota refletiria a coluna `mimeType` corrompida verbatim (`text/html`). Achado de
  staleness de perfil: `guidelines/project/backend/node-22.md` §6.2 afirmava "Esta API só
  emite JSON" — falsificado por esta wave (1º emissor binário do backend); corrigido como
  CONDIÇÃO ("toda rota que ecoa Content-Type de valor armazenado valida contra allowlist
  fechado"), não como exceção pontual. AC-022-023 da SPEC tinha a mesma inconsistência
  SPEC↔PLAN do AC-022-025 (Wave 5) — prometia restrição por autoria que A-023-001 já havia
  decidido não existir; corrigido. **Gate 9 VERIFICADO via HTTP real (curl + comparação
  md5 byte-a-byte) e browser real (Playwright, miniatura carregando em `/visual-library`
  pela primeira vez)** — a última capacidade do PLAN provada de ponta a ponta.
  0 retry de código nesta wave (os 2 achados bloqueantes foram de documentação, delta
  inerte para o comportamento). Com esta wave, **F5 (Biblioteca visual reutilizável) está
  implementada por completo** — falta a Entrega (Etapa 5 do `/keelson:auto`): DoD final,
  relatório de aceitação, commit/push da branch e handoff ao Diretor.
- 2026-09-14: **Wave 5/6 de PLAN-023 concluída (2 TASKs Done)** — `listVisualAssociations`/
  `listVisualAssociationCategories`/`normalizeCategoryKey`/`suggestCategories` (backend) e
  a página `(interno)/visual-library/page.tsx` + correção do guard de navegação (achado do
  redator: `INTERNAL_ROUTE_PREFIXES` não incluía `'visual-library'`, corrigido no mesmo
  diff). **As 3 FEATs de SPEC-022 completaram e foram VERIFICADAS** (gate 9, execução real
  browser+HTTP): FEAT-022-001, FEAT-022-002 e FEAT-022-003 — ver as linhas
  "**Verificação (gate 9)**:" na própria SPEC-022. Achado real de segurança-adjacente no
  backend: o filtro de categoria (`equals`+`mode:'insensitive'` do Prisma) compilava para
  `ILIKE`, então o valor do CLIENTE era interpretado como PADRÃO LIKE — `?category=%`
  devolvia o acervo inteiro, sem SQL injection (parametrizado) mas violando o "SOMENTE"
  de AC-022-010; achado pelo code-reviewer, fechado com escape de metacaracteres +
  4 provas por mutação (1 por metacaractere), e roteado como lição nova em
  `guidelines/project/lessons.md` (mesma classe pré-existente identificada, não corrigida
  por estar fora do escopo do PLAN, em `disciplines.service.ts`/`users.service.ts`).
  Medição obrigatória de performance (lição ativa) rodada de verdade: `EXPLAIN ANALYZE`
  contra 12k linhas semeadas confirma `Seq Scan` (sem índice em `category`), custo
  aceitável no volume atual (≤16ms) — candidato a índice/migração registrado para
  gate 10/Diretor, NENHUMA migração feita nesta wave. Achado de honestidade do developer:
  AC-022-025 da SPEC prometia accent-folding que `DEC-023-008`/NFR-022-007 nunca
  implementaram (mecanismo real é só trim+case-fold) — inconsistência SPEC↔SPEC, não erro
  do developer; Tech Lead aplicou degrau 1 e corrigiu a prosa do AC para o exemplo que o
  mecanismo realiza, com `Reabrir se:` explícito. Achado do `qa` durante o gate 9 (fora
  desta wave, em TASK-023-011): mutações de vínculo/desvínculo não invalidavam a tag de
  listagem do acervo, deixando `linkCount` do picker desatualizado na mesma sessão —
  corrigido à parte. TASK-023-015 foi a ÚNICA TASK do PLAN-023 aprovada sem nenhum achado
  em nenhuma rodada. Próximo: Wave 6 (TASK-023-016 entrega do binário, TASK-023-017 rede
  de paridade cross-repo) — última wave do PLAN-023.
- 2026-09-14: **Wave 4/6 de PLAN-023 concluída (4 TASKs Done — 2 fatias sensíveis + 2 UI)**
  — `removeVisualAssociation` (trava de vínculo), `linkVisualAssociationToFrame`/
  `unlinkVisualAssociationFromFrame` (backend), `visual-library-board.tsx` (CRUD do
  acervo) e enxerto de vínculo em `mnemonic-strip-board.tsx` (frontend). **FEAT-022-001
  ("Gestão do acervo") completou e foi VERIFICADA** (gate 9) por execução real (HTTP +
  Postgres de dev): AC-022-001/002/003/004/006/007/008/019/020 + NFR-022-003.
  Convergência mais longa e mais séria do slug até aqui — **1 vulnerabilidade REAL
  encontrada e corrigida**: a trava de vínculo ativo por `deleteMany` condicional (achado
  da Wave 1) NÃO fechava a corrida TOCTOU sob READ COMMITTED — um vinculador concorrente
  que commitasse durante a espera de lock do `DELETE` tinha o vínculo ativo anulado em
  SILÊNCIO pelo `ON DELETE SET NULL` (o predicado do `where` é avaliado no snapshot do
  statement, não reavaliado após a espera). Provado por execução real de concorrência
  contra Postgres pelo `security-engineer`; fechado travando a linha pai (`SELECT ... FOR
  UPDATE`, parametrizado) antes de qualquer decisão — mutante que remove o lock reprova
  4/4, fix passa 22/22. Backend: 2 rodadas de gate (rodada 1 REPROVADA nos gates 1-7 E 8;
  retry único corrigindo os dois; rodada 2 APROVADA nos dois, com prova de mutação
  executada pelos próprios revisores). Frontend: 4 rodadas — reincidência da lição DRY
  (3ª vez dentro do próprio PLAN-023), reincidência de nome-acessível-não-único (corrigido
  na Wave 3 no picker, reintroduzido no board novo), 2 achados ALTA de design (remoção
  destrutiva sem confirmação, formulário sem validação), 1 regressão introduzida pela
  própria correção de "nunca 2 diálogos simultâneos" (escondia feedback assíncrono de
  Quadros não-relacionados) e 1 teste flaky real (~5%, filtro por categoria sem debounce
  com `waitFor` mal ancorado). Todas as rodadas excederam o teto padrão de 1 retry —
  **Tech Lead aplicou degrau 1 da escada de reação repetidamente** (decidir e registrar,
  sem escalar) para cada achado mecânico com correção já prescrita pelo próprio revisor,
  sem ambiguidade de produto pendente. 6+ lições novas/estendidas roteadas (DRY 3ª
  manifestação, corrida real, precedência com ramo no-op, design de diálogo cruzado,
  nome acessível herdado entre componentes-irmãos, teste assíncrono mal ancorado) — ver
  `guidelines/project/lessons.md` e `docs/_meta/learning-log.md` (LRN-022+). Próximo:
  Wave 5 (TASK-023-014/015 — completa FEAT-022-003 e FEAT-022-002).
- 2026-09-13: **Wave 3/6 de PLAN-023 concluída (2 TASKs Done — fatia sensível)** —
  `createVisualAssociation`/`updateVisualAssociation` (upload validado por assinatura de
  bytes, guarda `assertVisualAssociationWritable` DEC-023-006) e
  `visual-association-picker.tsx` (seletor reusável). História de convergência mais longa
  do slug até aqui — 3 rodadas de gate no backend: **rodada 1 REPROVADA**
  (code-reviewer/security-engineer/product-designer) — teto de campo multipart cobria só o
  arquivo (bypass via JSON), prova HTTP de spoof de `authorId` (DEC-023-012) insuficiente,
  3 fixtures duplicadas, ARIA incorreta no picker (`role="listbox"`/`"option"` sem
  interação de teclado, nome acessível não-único, sem feedback de `isFetching`, copy do
  vazio enganosa) — corrigida em retry (`ad13a0d` backend/`aa526d4` frontend). **Rodada 2
  REPROVADA** (code-reviewer): 2 achados mecânicos — mutante M1 (reintroduzir `authorId`
  no `data` do update) sobrevivia porque só a via HTTP tinha prova (o Zod descarta o campo
  antes do service; faltava o par no nível de service) e reincidência da lição DRY em
  `env.test.ts` (`loadEnvModule()` re-derivado inline). O code-reviewer propôs escalar
  (teto de convergência); **Tech Lead aplicou degrau 1 da escada** (decidir e registrar,
  não pausar) — achados mecânicos, reversíveis, sem ambiguidade de produto (ledger
  `20260913-222341-decisao-tech-lead.md`) — corrigidos em retry (`ddc56cb`). **Verificação
  final APROVADA** (ledger `20260913-225257-gate-tech-lead.md`): M1 confirmado morto por
  execução própria do revisor em worktree isolada (não por relato) — achado colateral: a
  prova HTTP sozinha de fato NÃO mata M1, validando a reprovação da rodada 2;
  `env.test.ts` sem re-derivação solta; varredura de comentários residuais achou 1 sobra
  real (`visual-associations.routes.ts:18`), corrigida no commit de fechamento
  (`c57c5f7`) junto de um estado `MM` de formatação (renormalizado antes de commitar).
  Unit 272/272, integration 312/312, 0 vulnerabilidade, 0 warning de lint. 2 lições
  roteadas: reincidência da lição DRY (`guidelines/project/lessons.md:783`, contador
  "confirmada 2" — a 2ª ocorrência de re-derivação de `loadEnvModule` no MESMO arquivo só
  fechou nas edições do Tech Lead, não no retry que a citou) e lição de processo nova
  sobre despacho de retry (`docs/_meta/learning-log.md` LRN-022, PROPOSTA_PLUGIN —
  achado de classe deve levar o COMANDO de varredura como critério de pronto, não como
  ilustração). Próximo: Wave 4 (TASK-023-010/011/012/013 — 2 fatias sensíveis).
- 2026-09-13: **Wave 2/6 de PLAN-023 concluída (2 TASKs Done)** — `visual-association-storage.ts`
  (leitura/escrita de `imageData Bytes` sobre a MESMA transação do chamador, nunca
  filesystem) e extensão de `store/api.ts` com os 6 endpoints RTK Query do acervo. Gate 1-7
  aprovado (code-reviewer fez mutation testing próprio — 1 MiB de alta entropia + controle
  negativo — para confirmar que os casts de tipo do Prisma 7 não perdem byte). Achados fora
  de escopo: `quality.test` da ficha não alcança a suíte de integração (pré-existente,
  estrutural — decisão de ficha para o Diretor); gotcha Prisma 7 `Bytes`/`Buffer`
  documentado em `node-22.md`. Próximo: Wave 3 (TASK-023-008/009).
- 2026-09-13: **Wave 1/6 de PLAN-023 concluída (5 TASKs Done)** — migração de schema
  (`VisualAssociation`, FK `SetNull`, `ASSOCIACAO_VISUAL` aditivo, `VisualAssociationLinkEvent`),
  `image-signature.ts` (detecção de assinatura de bytes), `visual-associations.schema.ts`
  (Zod), extensão de `tira.schema.ts` (vínculo) e de `types/domain.ts` (frontend). Gate 8
  (security-engineer): APROVADO, com 4 achados roteados como critérios herdados em
  TASK-023-008/010/014/016 (TOCTOU na remoção — trava agora atômica via `deleteMany`
  condicional; Content-Type nunca ecoa a coluna livre; `multer` precisa de
  `fieldSize`/`files`/`fields`; `select` explícito em toda leitura sem precisar do binário).
  Gate 1-7 (code-reviewer): REPROVADO na 1ª rodada — achado bloqueante real: a rede de
  paridade cross-repo já existente (`tira-frontend-contract.test.ts`, ativa desde
  TASK-012-011) ficou vermelha porque o campo `visualAssociationId` entrou no frontend
  (TASK-023-005) sem o par no backend, que estava alocado para a Wave 4 (TASK-023-011).
  Corrigido via retry (commit `84b1f08`, mesma wave) — campo trazido ao backend agora,
  antecipando parte do escopo de TASK-023-011/017 (registrado nos dois arquivos). 2 lições
  de processo registradas e propostas ao mantenedor do plugin: (1) decomposição de TASKs
  deve varrer redes de paridade cross-repo EXISTENTES antes de declarar uma como "trabalho
  de wave futura"; (2) `tolower()` do awk em `artifact-lint.sh` corrompe UTF-8 sob este
  ambiente (Windows/gawk), causando falsos ERROR/WARNING em SPEC/PLAN com "não"/"então" —
  diff de correção proposto para os 2 checks afetados. **Incidente de migração**: a
  suíte de integração aplicou a migração ao banco de TESTE como efeito colateral do
  `globalSetup` (sem autorização prévia explícita) — banco de DEV/produção não foram
  tocados; Diretor autorizado e confirmou a aplicação ao DEV após disclosure completa.
  Achados fora de escopo registrados (não bloqueiam): paginação copiada em 3 módulos
  (candidato a consolidação futura), inconsistência de mensagem pt-BR entre schemas de
  corpo e de query. Próximo: Wave 2 (TASK-023-006/007).
- 2026-09-13: **TASK-023-001 a 017 geradas via `/keelson:auto` (rota fan-out, decisão
  4.310 — 1 decompositor + 3 redatores em paralelo).** 6 waves: setup (migração +
  assinatura de bytes + schemas + tipos, Wave 1), storage/RTK Query (Wave 2), CRUD de
  escrita + picker (Wave 3), remoção/vínculo/telas (Wave 4), listagem + página (Wave 5),
  binário + paridade cross-repo (Wave 6). 4 TASKs marcadas fatia sensível (princípio 8):
  assinatura de bytes, upload+CRUD write, remoção+alcance, vínculo+reuso de guarda de F4.
  Achados corrigidos pelo Tech Lead na consolidação: nome de branch errado em todas as 17
  (apontava branch nova em vez da branch do épico `feat/producao-material-mnemora-studio`
  — decisão 4.126); URL da miniatura sem prefixo `/api/v1` + `<img>` cru em vez de
  `next/image` (3 arquivos, teria dado 404 e warning de lint); `/visual-library` não
  coberto por `INTERNAL_ROUTE_PREFIXES`/`config.matcher` (achado real do redator,
  premissa do PLAN estava errada — TASK-023-015 corrigida para incluir o ajuste,
  puramente aditivo); `FEAT-022-003` faltando em TASK-023-014 (FR-022-019 mal atribuído
  no manifesto); 2 TASKs de UI (012/013) só tinham gate 9 para ACs testáveis em unidade —
  acrescentado critério de gate 1 (3 estados observáveis testados no componente montado)
  em ambas, sem remover o gate 9. Validação mecânica (`artifact-lint.sh`/`graph.sh`): 0
  ERROR real (3 ERRORs mecânicos de `task-criterio-sem-ac` aceitos via override
  documentado + precedente real do slug — TASK-006-004/007, TASK-012-003/010). Cobertura:
  25/25 FRs, 25/25 ACs, 3/3 FEATs. Próximo: `/keelson:implement`.
- 2026-09-13: **PLAN-023 criado e aprovado via `/keelson:auto` (F5, cobertura 100% de
  SPEC-022 — 25/25 FRs, 7/7 NFRs).** 17 COMPs, 12 DECs (todas reversíveis), 7 TRISKs.
  Reconhecimento técnico do `code-scout` confirmou greenfield total (nenhuma dependência de
  upload/multipart, rota de binário autenticado ou env var de storage nos dois repos).
  **Correção do Tech Lead em voo** (degrau 1 da escada — decisão registrada, não
  ambiguidade nova): a 1ª redação do PLAN escolhia armazenamento em disco local para o
  binário; o próprio PLAN identificou (`TRISK-023-003`) que isso é incompatível com a
  função serverless do backend na Vercel (mesma topologia de PLAN-021) — filesystem efêmero
  por instância, upload não sobreviveria de forma confiável. Corrigido para armazenar o
  binário como coluna `Bytes` (bytea) no próprio Postgres — elimina o risco por completo,
  sem infraestrutura nova, mantém a reversibilidade (interface isolada para trocar por blob
  externo depois). Cardinalidade do vínculo modelada como FK N:1 (`MnemonicFrame.
  visualAssociationId`), não tabela de junção N:N — SPEC já fixa no máximo 1 associação por
  Quadro. Validação de forma (`artifact-lint.sh`/`graph.sh`): corrigido erro real (lista de
  FRs/NFRs cobertos em formato wrapped multi-linha, não reconhecido pelo parser — 1 ID por
  linha é o formato canônico) e reconciliado `Realiza` × §7 em 6 componentes. Falso positivo
  confirmado do ambiente (mesmo bug de `tolower()`/UTF-8 do Windows local da SPEC-022):
  `plan-dec-irreversivel-enum` acusa ERROR nas 12 DECs (`Irreversível: não`, com acento) —
  candidato a lição de processo/plugin, ainda não roteado. Migração 100% aditiva; execução
  exige autorização do Diretor antes de `prisma migrate dev` (DEC-023-007, regra do
  CLAUDE.md do workspace). Próximo: `/keelson:tasks`.
- 2026-09-13: **SPEC-022 criada e aprovada via `/keelson:auto` (F5 do épico, BRIEF-022).**
  0 ERROR de forma (achado de ambiente: `tolower()` do awk local corrompe "ã" em UTF-8,
  disparando falso positivo de `spec-ac-fora-gwt` em todos os ACs — leitura manual
  confirma Dado/Quando/Então corretos; candidato a lição de processo/plugin). Crítica de
  mérito do `product-analyst` (11 pontos) resolvida pelo `po`: 9 aplicadas diretamente
  (alcance por autoria do vínculo herdado de F4/SPEC-011; vínculo com Quadro soft-deleted
  não conta na trava/contagem/métrica; remover Quadro preserva a associação; métrica
  primária virou "uploads evitados"; categoria texto livre + sugestão + normalização;
  binário exige sessão/alcance; 1 associação por Quadro, vínculo idempotente; trava de
  remoção identifica Quadros alcançáveis; NFR de não-regressão da tela da Tira), 2
  escaladas ao Diretor com default já aplicado (acervo comum na leitura × escrita
  restrita ao autor; instrumentação mínima de etapa) — perguntas vão ao lote da Entrega
  de F5. SPEC final: 25 FRs, 7 NFRs, 25 ACs, 12 premissas, 5 riscos, 1 questão aberta.
  Próximo: `/keelson:plan`.
- 2026-09-08 16:33: **PLAN-021 mergeado e verificado em produção real.** Diretor
  mergeou o PR e configurou `BACKEND_API_URL` no painel Vercel do
  `mnemonicos-frontend`. 1ª tentativa de login em produção falhou:
  `POST /api/v1/auth/login` → 404, header `X-Vercel-Error:
  DNS_HOSTNAME_RESOLVED_PRIVATE` — diagnosticado como `BACKEND_API_URL`
  ausente no deploy inicial, rewrite caindo no fallback de dev local
  (`http://localhost:3333`, resolve para loopback, bloqueado pela proteção
  anti-SSRF da Vercel) — exatamente TRISK-021-003. Confirmado por curl direto
  no backend (`mnemonicos-backend.vercel.app`): `/health` 200, login com as
  credenciais reais 200 (seed ADMIN existente, senha correta), CORS correto,
  `verifyOrigin` recusando origem forjada (403) — backend saudável, só o
  rewrite do frontend estava quebrado. Diretor corrigiu a env var + redeploy;
  revalidação completa via Playwright + curl no domínio do frontend: login →
  `/studio`, 2 `Set-Cookie` distintos sob o domínio do frontend, sessão
  reconhecida, CSRF recusado através do rewrite. TRISK-021-001/002/003
  resolvidos — DoD de PLAN-021 100% satisfeita. **Nota de segurança**: o
  Diretor colou senha de teste e a `DATABASE_URL`/`PRISMA_DATABASE_URL` de
  produção em texto plano no chat desta sessão — recomendada rotação de
  ambas; não usadas/ecoadas além da checagem via curl no endpoint de login
  (a consulta direta ao Postgres não foi necessária).
- 2026-09-08 16:10: **`/keelson:integrate` de PLAN-021** — branch
  `feat/producao-material-rewrite-same-origin-cookie-sessao` pushada
  (`mnemonicos-frontend`, `e54f562`). **PR não aberto automaticamente** —
  mesma limitação já registrada na Entrega de PLAN-020: token do `gh` sem
  acesso ao repo `mnemonicos-frontend`; link manual:
  https://github.com/marcosmatosteodoro/mnemonicos-frontend/pull/new/feat/producao-material-rewrite-same-origin-cookie-sessao .
  Título e descrição completos preparados e entregues ao Diretor no output
  desta execução. Jira: sync de link do PR não aplicado (nenhum PR real
  existe ainda para linkar) — pendente até o Diretor abrir manualmente.
- 2026-09-08 16:04: **Convergência de fecho verde em `e54f562`** (dedup: aplicada) —
  code-reviewer, modo convergência, via `/keelson:integrate`: confronto semântico
  completo de PLAN-021 (FR-002-001/NFR-002-008 realizados sob a topologia
  same-origin, com prova que mata o mutante do host cross-site; DEC-021-001/002/003
  refletidas fielmente, backend confirmado intocado por leitura direta; nenhuma
  condição `Reabrir se:` satisfeita). CONVERGIU, 0 gaps. Dedup achou 2 pendências
  novas (tripwire de paridade `/api/v1` ausente entre `next.config.ts`/`store/api.ts`;
  2 docblocks do service worker desatualizados por esta branch, reduzindo em silêncio
  a margem declarada de NFR-013-001 de 2 camadas para 1) + reconfirmou 1 conhecida
  (`asRequest`, 6ª cópia local) — nenhuma bloqueia, roteadas em Riscos ativos. Suíte
  completa reconfirmada verde no checkpoint de integrate: backend 26/26 suites e
  243/243 testes, frontend 34/34 suites e 363/363 testes, lint/typecheck do frontend
  limpos (lint do backend tem 11 erros pré-existentes numa worktree alheia,
  `kan-49-vercel-entrypoint`, sem relação com o diff desta branch).
- 2026-09-08 15:26: **PLAN-021 implementado — 2/2 TASKs Done, 2 waves, via
  `/keelson:implement`.** Wave 2 (TASK-021-002, KAN-84 — `baseUrl` same-origin em
  `store/api.ts` + remoção de `env.apiUrl`/`NEXT_PUBLIC_API_URL`) REPROVOU na 1ª
  rodada do gate 1-7: 2 achados confirmados por mutation testing real do
  code-reviewer (mutante que apaga o ramo same-origin de `resolveApiBaseUrl()`
  sobrevivia — placeholder de fora-do-browser coincidia byte-a-byte com a origem
  default do `jest-environment-jsdom`; mutante que troca `baseUrl` por host
  absoluto fixo também sobrevivia — nenhum teste asseria a URL absoluta do
  consumidor real) + 1 achado de gate 7 (docblock afirmava paridade não provada
  entre o prefixo `/api/v1` de `api.ts` e `next.config.ts`). 1 retry corrigiu os 3
  (origem discriminante no teste jsdom + teste novo de URL absoluta sob o
  ambiente canônico `test/jsdom-fetch-env.js` + docblock suavizado), com os 2
  mutantes confirmados mortos pelo próprio revisor em worktree isolada antes da
  aprovação. 1 correção não-bloqueante adicional aplicada no fecho (cláusula do
  docblock suavizado ainda estava factualmente errada na direção oposta) —
  gerou a 5ª reincidência da lição `[Testes] Comentário que afirma paridade...`
  em `lessons.md` (direção inversa: suavizar também exige mutante por lado).
  Gate 8 (security-engineer) aprovou as duas waves de primeira, 0 achados.
  34 suites/363 testes frontend + 26 suites/243 testes backend (suíte completa,
  Etapa 4), lint/typecheck limpos, 0 regressão. Gate 9 **n/a por TASK** — o
  resíduo real (TRISK-021-001/002: `Origin`/múltiplos `Set-Cookie` sob dois
  sites `*.vercel.app` reais) é tecnicamente irreproduzível localmente, fica
  como item de DoD do PLAN (verificação manual pós-deploy). **Pendência de
  deploy declarada**: `BACKEND_API_URL` precisa ser configurada no painel
  Vercel do frontend antes do próximo deploy (TRISK-021-003). Anomalia
  declarada ao Diretor: o PLAN nunca teve o Status promovido a Approved antes
  de `/keelson:tasks`/`/keelson:implement` prosseguirem (front-matter seguia
  "Draft") — não corrigida silenciosamente. PLAN-021 marcado Done (sugerido) —
  promoção formal de Status e merge são ato do Diretor.

- 2026-09-08 14:20: **Wave 1 de PLAN-021 concluída via `/keelson:implement`** (TASK-021-001,
  KAN-83 — `rewrites()` same-origin em `next.config.ts`). Gate 1-7 (code-reviewer) REPROVOU
  na 1ª rodada: `next.config.test.ts:9` usava `as` para apagar o `| undefined` que o
  TypeScript infere para valor capturado dentro do callback de `jest.isolateModules` — 1
  retry trocou por guard clause que lança, no molde do exemplar mergeado
  `src/lib/sw-loader.ts:139-147`; delta re-aprovado. Gate 8 (security-engineer) aprovou de
  primeira, 0 achados — 2 notas não-bloqueantes para o checklist de deploy (header em
  resposta de rewrite; validação de esquema/TLS de `BACKEND_API_URL`, TRISK-021-003).
  32 suites/360 testes verdes (2 novos), lint/typecheck limpos. Lição nova em
  `guidelines/project/lessons.md` (`[Testes] Valor capturado dentro de callback...`) +
  anti-pattern equivalente em `guidelines/project/frontend/next-16.md` §1. Fora de escopo
  (registrado, não é dívida da TASK): `next.config.ts`/`headers()` (CSP-lite) nunca teve
  teste próprio no repo; 4 arquivos do working tree do frontend mostravam `M` no
  `git status` com diff de conteúdo vazio (ruído LF/CRLF, sugestão de `.gitattributes`).
  Tracker: marco "TASK iniciada" degradou para comentário em KAN-83 (mapa de colunas do
  board `jira.KAN.md` ainda não promovido, `transition: auto` sem status-alvo seguro).
  Wave 2 (TASK-021-002) segue para implementação.

- 2026-09-08: `/keelson:triage` classificou o relato de KAN-75 persistindo em produção pós-merge como bug **diferente e mais grave**: login autentica (200 + perfil), mas o cookie de sessão nunca é gravado pelo navegador — causa raiz é topologia (frontend e backend como dois sites Vercel distintos, `sameSite: 'lax'` de DEC-003-004 não sobrevive a isso), não o fix de `next` do KAN-75 (que segue correto e mergeado). Classificado Categoria 2 (novo PLAN da mesma SPEC-002 — contrato não muda, estratégia técnica muda, DEC real entre alternativas). Diretor escolheu proxy same-origin (rewrite) em vez de `SameSite=None`+anti-CSRF via `AskUserQuestion`. `/keelson:plan` gerou **PLAN-021** (alocado inicialmente como PLAN-020; colisão de id com `PLAN-020-pagina-404-personalizada.md` de sessão paralela detectada pelo `graph.sh` e corrigida por renumeração antes da publicação). `plan-validator` limpo — 3 ERRORs de `plan-dec-irreversivel-enum` identificados como falso positivo do `artifact-lint.sh` (bug de portabilidade do `awk` nesta plataforma: `gsub` octal não casa o byte UTF-8 de "ã" em `não`, a forma exata que `commands/plan.md` prescreve) — reproduzido e documentado, não é defeito do PLAN. Status: Draft, aguardando `/keelson:tasks`.

- 2026-09-07 16:27: **PLAN-020 (página 404 personalizada) implementado — 2/2 TASKs Done,
  wave única, via `/keelson:implement`.** TASK-020-001 (`not-found.tsx`): 1 retry —
  product-designer reprovou a 1ª rodada (sem `metadata.title`, aba/histórico herdavam o
  título da home; className do link divergia do padrão canônico de 8 ocorrências
  existentes), aprovado na 2ª. TASK-020-002 (teste de integração HTTP real): 4 rodadas
  de convergência — acima do teto padrão de 1 retry, mas todas mecânicas, sem decisão de
  arquitetura/produto pendente em nenhuma delas: (1) achados de asserção fraca
  (`toContain` de corpo não discrimina a 404 personalizada do 404 default do framework —
  o payload RSC do App Router embute a string em QUALQUER resposta 200) + cobertura
  faltante do ramo "rota interna COM sessão" (AC-019-001/FR-019-004) + âncora de regex
  de descoberta de porta aceitando fim-de-buffer como delimitador + bind do servidor de
  teste em `0.0.0.0` (achado do security-engineer) + branch 8 commits defasada de
  `origin/main` (proxy.ts pré-KAN-75, mesmo achado); (2)-(4) rodadas fechando o residual
  mecânico até o `<title>Página não encontrada · Mnemônicos</title>` (discriminante real,
  sugestão do product-designer) cobrir os 3 casos. Branch sincronizada com `origin/main`
  por merge fast-forward antes do fecho (sem conflito). Gate 9 consolidado (DoD, Etapa
  4) — SPEC-019 sem FEATs, 6/6 ACs por gate 1 (teste automatizado, incl. servidor
  `next start` real). 312/312 testes do frontend verdes, 0 regressão; lint/typecheck
  limpos. 4 lições novas em `guidelines/project/lessons.md`. PLAN-020 marcado Done
  (sugerido) — promoção formal de Status e merge são ato do Diretor.
- 2026-09-07 16:45: **Entrega de PLAN-020** — convergência de fecho achou 1 gap parcial
  (AC-019-001 marca 1 sem asserção automatizada), fechado antes do push. PO: `ACEITA_COM_RESSALVAS`
  (E-019-01 ratificada, sem nova escalação). Branch `feat/pagina-404-personalizada`
  pushada (`f10d509`). **PR não aberto automaticamente** — token do `gh` sem acesso ao
  repo `mnemonicos-frontend`; link manual:
  https://github.com/marcosmatosteodoro/mnemonicos-frontend/pull/new/feat/pagina-404-personalizada .
  Jira: KAN-81/KAN-82 → Concluído; KAN-76 → Em análise (trilho do board, `jira.KAN.md`).
- 2026-09-07 15:45: **Wave 2 de PLAN-018 concluída via `/keelson:implement`** (TASK-018-002, KAN-80 — integração do `PasswordField` no `LoginForm`). Gate 1-7 (code-reviewer) REPROVOU na 1ª rodada: o comando de grep do Critério de pronto de AC-016-006 era infalsificável em 2 eixos (não excluía `password-field.test.tsx`; não cobria a forma dinâmica `type={cond ? "text" : "password"}`, deixando passar um componente duplicado com toggle próprio). 1 retry substituiu o grep por teste estrutural (mesmo padrão de `service-worker-policy.test.ts`), com controles positivo/negativo para as duas formas — aprovado na revalidação, mas o próprio revisor, levando a correção ao extremo oposto, achou um 3º defeito simétrico (exclusão por nome de arquivo, não por caminho completo) e uma dívida declarada (forma indireta via variável, fora do teto de 2 rodadas). Corrigido no fecho sem nova rodada de gate (achado de severidade baixa, correção de 1 linha). Gate 11 (product-designer) APROVOU de primeira, com aritmética de altura de linha confirmando paridade visual com o campo de e-mail (38px nos dois). PLAN-018 fecha: 2/2 TASKs Done, 7/7 FRs + 4/4 NFRs + 10/10 ACs cobertos, 24 suítes/251 testes, 0 regressão. KAN-72 pronta para revisão (In Review) — PLAN-018 marcado Done (sugerido), promoção formal de Status é ato do Diretor.
- 2026-09-07 18:04: **PLAN-012 (F4, MNEMORA STUDIO) implementado — 13/13 TASKs Done, todas as 7 waves concluídas via `/keelson:implement`.** Wave 7 (última, TASK-012-013 — link condicional Quebra→Tira em `rule-breakdown-form.tsx`) convergiu de primeira nos 2 gates (code-reviewer + product-designer), depois das 4 rodadas em cada um nas Waves 5 e 6. 1 sugestão não-bloqueante aplicada na closure: `data !== undefined`/`isNotFound` não eram mutuamente exclusivas por construção (RTK Query preserva `data` em cache num refetch com erro) — provado por sonda do próprio revisor; corrigido para `data === undefined && isNotFound`. Sinal fora de escopo, mesma classe, pré-existente em `mnemonic-strip-board.tsx` (TASK-012-012, já Done) — não investigado a fundo, registrado como pendência para a Entrega. Resumo do PLAN inteiro: 2 escalações genuínas ao Diretor (Wave 5 — CSRF real em GET get-or-generate, resolvida com DEC-012-011 supersedendo DEC-012-009; Wave 6 — achado de acessibilidade de foco em diálogo, não-óbvio mas real) e 2 decisões de degrau 1 do Tech Lead sem reescalar (achados mecânicos já simulados pelo revisor). Migração 100% aditiva (`Mnemonic` legado intocado). Próximo passo: Etapa 4 (DoD do PLAN, suíte completa, gate 9 consolidado) e Entrega (relatório de aceitação do PO, PR — merge/deploy seguem sendo ato do Diretor).
- 2026-09-07 14:52: **Wave 6 de PLAN-012 concluída via `/keelson:implement`** (12/13 TASKs Done — 012 tela `(interno)/content/[id]/tira`, quadro a quadro). A task mais disputada do PLAN até agora (empatada com a Wave 5): 4 rodadas de convergência em CADA um dos 2 gates (code-reviewer + product-designer, gate 11 — primeira vez neste PLAN que o gate de design roda). 1ª rodada: REPROVADO nos 2 — 3 achados de falsificabilidade (prova da cascata de abertura GET→POST só cobria a 1ª janela pendente) + 8 achados de UX (página sem cabeçalho/saída, estados sem prova, ações destrutivas sem confirmação, feedback silencioso). Retry consolidado fechou os 8, mas o PRÓPRIO retry introduziu 2 problemas sem review: cabeçalho novo sem teste e diálogo de confirmação copiado de `content-form.tsx` sem o efeito de foco que o acompanha — 2ª REPROVAÇÃO nos 2 gates, escalada ao Diretor (aprovou aplicar). 3ª rodada: code-reviewer APROVOU; product-designer achou uma 4ª porta de desmonte do diálogo (clicar "Editar" com a confirmação aberta) — decisão de degrau 1 do Tech Lead (correção já simulada pelo próprio revisor, continuação direta da decisão já aprovada, sem reescalar). 4ª rodada: APROVADO nos 2. Lição registrada (em-observação): reúso de padrão canônico por CÓPIA DE MARKUP sem copiar o contrato completo (efeito de foco) é regressão, não reúso. Furo no plano corrigido antes do despacho: TASK-012-010 (RTK Query, Done) ainda esperava o contrato GET get-or-generate antigo — emendado no card antes de despachar (endpoint renomeado + mutation nova). Achado não-bloqueante fora de escopo: controles de mover para cima/baixo perdem foco na fronteira da lista (independente do diálogo) — vira brief avulso para o Diretor. Correção de critério na closure: AC-011-024 citava símbolo apagado pela EMENDA e pedia prova mecânica que contradizia `invalidatesTags` pré-existente de TASK-012-010 — reescrito para provar ausência de REGENERAÇÃO, não de leitura.
- 2026-09-07 14:41: **SPEC-019 criada via `/keelson:specify`** (BRIEF-019, Jira KAN-76) —
  página 404 personalizada com identidade visual da aplicação e link/botão de volta para
  `/`. Validator de forma: 0 errors (WARNINGs não-bloqueantes: `spec-ac-fora-gwt` x5 —
  falso-positivo de acentuação da ferramenta de lint, ACs conferidos manualmente em forma
  Dado/Quando/Então —, `spec-must-ratio`, `spec-sem-should-may`). Crítica de mérito do
  `product-analyst` identificou conflito real com o guard de sessão de SPEC-002
  (`proxy.ts:56` redireciona rota interna inexistente sem sessão para `/login`, nunca
  404) — resolvido pelo `po` (ESCALAR não-bloqueante, E-019-01, default seguido):
  AC-019-001 partido em 2 cenários (pública sempre; interna com sessão ativa), 2 exclusões
  novas em §4.2, não-regressão de SPEC-002/`proxy.test.ts` nomeada em §1.3, marcas visuais
  observáveis enumeradas em AC-019-001/NFR-019-001. Aprovada (`Approved`). Aguarda
  `/keelson:plan`.
- 2026-09-07 15:10: **Wave 1 de PLAN-018 concluída via `/keelson:implement`** (TASK-018-001,
  KAN-79 — componente `PasswordField`). Gate 1-7 (code-reviewer) REPROVOU na 1ª rodada: 2
  achados bloqueantes — AC-016-005 tinha oráculo morto (`<input required>` vazio no harness
  bloqueava toda submissão nativa no jsdom, então o mutante `type="button"`→`type="submit"`
  sobrevivia) e AC-016-008/DEC-018-005 sem asserção nenhuma dos 3 atributos anti-canal. Gate
  11 (product-designer) REPROVOU no mesmo turno: foco visível ausente (`outline-none` sem
  substituto, único caso em `src/`) e alvo de toque do botão de alternância abaixo do piso
  WCAG 2.2 SC 2.5.8 (20×20, mínimo 24×24). 1 retry consolidado corrigiu os 4 — developer
  confirmou cada mutante morto manualmente antes de reverter, e ambos os revisores
  reconfirmaram por si mesmos na rodada 2 (mutação real / CSS compilado com
  `tailwindcss@4.3.3`), não por relato. Bônus aplicado (convergência dos 2 revisores): label
  e botão deixaram de ser aninhados (risco de content model inválido + contaminação de nome
  acessível). 2 lições candidatas registradas pelos revisores: `[Testes]` teste de
  ausência-de-efeito exige controle positivo no mesmo harness; `[Design]` produto sem token/
  utilitário de foco declarado, cada componente improvisa o próprio anel. Suíte completa
  24/243, 0 regressão. TASK-018-001 → Done.
- 2026-09-07 14:20: **QA pré-código (Etapa 3.5) de TASK-018-001/002** — 5 achados
  (nenhum bloqueante): AC-016-006 tinha prova "code review only", não executável, nos
  dois lados — trocado por checagem estrutural determinística (`grep` confirmando 0
  `type="password"` fora de `password-field.tsx`); AC-016-005 só era provado num form
  genérico isolado, não no `LoginForm` real — TASK-018-002 ganhou caso próprio (mock de
  `login` não chamado ao acionar o toggle); AC-016-010 fortalecido para exigir foco E
  valor no mesmo teste; resíduo de encaminhamento de foco cross-browser (`<button>`
  aninhado em `<label>`) declarado fora do escopo da prova (PLAN §10, mesma classe de
  RISK-016-001). Jira: subtasks KAN-79 (TASK-018-001) e KAN-80 (TASK-018-002) criadas
  sob KAN-72; KAN-72 movida para "Em andamento".
- 2026-09-07: **PLAN-018 decomposto em 2 TASKs via `/keelson:tasks`** (rota única, 2
  waves sequenciais — a cadeia de dependência dos 2 COMPs é linear: `PasswordField`
  isolado → integração no `LoginForm`). TASK-018-001 (Wave 1) cria o componente + teste
  próprio (`password-field.test.tsx`, 8 ACs); TASK-018-002 (Wave 2, depende da 001)
  substitui o campo de senha nu do `LoginForm` e estende `login-form.test.tsx` (7 casos
  pré-existentes preservados + 2 novos). Cobertura 7/7 FRs, 10/10 ACs — AC-016-006 split
  entre as duas TASKs (parte "implementação única" na 001, parte "LoginForm de fato
  consome" na 002), sem duplicar cobertura. Todos os ACs fecham por gate 1 (teste
  automatizado); nenhum exige gate 9 apesar de `gates.screenVerify` ativo na ficha (toggle
  síncrono, local, sem I/O). Aguarda `/keelson:implement`.
- 2026-09-07 14:05: **PLAN-018 criado via `/keelson:plan`** (cobre SPEC-016) — 2 COMPs
  (`PasswordField` + integração no `LoginForm`), 5 DECs (todas reversíveis: SVG inline em
  vez de lib de ícones nova; toggle via `useState` local sem elevar estado ao `LoginForm`;
  atributos anti-canal fixos independentes do `type`), 2 TRISKs (autofill cross-browser;
  limitação de jsdom para foco pós-teclado). Mapeamento §7 cobre 100% dos FRs/NFRs de
  SPEC-016 (11/11), 10 ACs mapeados.
- 2026-09-07 13:45: **SPEC-016 promovida a Approved** — crítica de mérito do
  product-analyst (5 riscos de produto) resolvida pelo PO (`decisao: ESCALAR`, 1 item
  não-bloqueante — E-01 acima). Aplicado: §4.2/A-016-002 precisam distinguir "tela" de
  "capacidade" (API de troca/reset de senha já existe); NFR-016-003 declara que o tab-stop
  extra do toggle não é regressão; NFR-016-002/AC-016-008 ampliados para cobrir atributos
  anti-canal do navegador (`type="text"`); 2 ACs novos (AC-016-009 estado do toggle
  sobrevive a login recusado; AC-016-010 continuidade de foco pós-teclado); 2 premissas
  novas (A-016-005 caret best-effort; A-016-006 autofill revelado é aceitável).
- 2026-09-07: **SPEC-016 criada via `/keelson:specify`** (BRIEF-016, KAN-72) — toggle de
  mostrar/ocultar senha nos campos de senha: componente reutilizável de campo de senha com
  ícone de olho, operável por teclado, rótulo acessível dinâmico, aplicado ao campo de
  senha do `LoginForm` (único campo de senha existente hoje), sem alterar o fluxo de
  autenticação de SPEC-002 (não-regressão formalizada em NFR-016-003/AC-016-007). 7 FRs, 4
  NFRs, 8 ACs, 4 premissas `[assumido]` (sem `[confirmar]`), 1 risco, 1 questão aberta.
  Sem meta de negócio numérica associada (A-016-001) — régua de conformidade via teste
  automatizado.
- 2026-09-07 13:17: **Wave 5 de PLAN-012 concluída via `/keelson:implement`** (11/13 TASKs Done — 008 rotas HTTP da Tira sob a barreira EDITOR/ADMIN). A wave mais disputada do PLAN até aqui: 4 rodadas de code-reviewer. 1ª: REPROVADO nos 2 gates — security-engineer achou CSRF real (GET /contents/:id/strip get-or-generate, cookie sameSite=lax, sonda provou forjar actorId da vítima no evento ABERTURA) e recusou rotular como conserto de developer, escalando ao Tech Lead; code-reviewer achou regressão de prova (route-authz-matrix:421 virou tautológico) + duplicação DRY. Diretor decidiu mover a geração para POST /contents/:id/strip (GET vira leitura pura) — **DEC-012-011 supersede DEC-012-009** no PLAN (furo no plano documentado com EMENDA). Retry 1 fechou os 3 achados, mas levou consigo as únicas 2 asserções de sucesso do GET (2ª REPROVAÇÃO). Retry 2 corrigiu isso, mas usou fixture não-discriminante na prova de negação por autoria de `getMnemonicStrip` (3ª REPROVAÇÃO — não vulnerabilidade viva, produção confirmada correta por sonda do revisor, só faltava a prova de teste; code-reviewer recusou se autorrotular "mecânico" por decisão de processo e **escalou ao Diretor**, que aprovou o retry). Retry 3 fechou com fixture discriminante (vítima com Tira realmente aberta via POST antes da leitura do não-dono) — 4ª rodada **APROVADA** nos 2 gates. Endurecimento de 1 linha aplicado na closure (regex do teste estrutural passa a cobrir o cliente de módulo `prisma`, não só `tx`/`db`). 2 lições de segurança atualizadas (guarda reusada — 3ª ocorrência, agora estendida a métodos de LEITURA; universo do teste estrutural — 2ª ocorrência, vocabulário do padrão textual incompleto). Pendência explícita para TASK-012-012 (Wave 6): TASK-012-010 (RTK Query, Done) ainda espera o contrato antigo — a tela já nasce consumindo POST-gera/GET-lê. Pendência fora de escopo: `tira-frontend-contract.test.ts` não roda em git worktree (resolve caminho relativo ao checkout) — sinal para correção futura.
- 2026-09-07 04:54: **PLAN-013 implementado (6/6 tasks Done), aguardando promoção manual de Status.** Wave 6 (TASK-013-006, fatia sensível — verificação de não-regressão de sessão com SW ativo) fechou o ciclo: baseline automatizada verde (9/9, sem alteração), gate 8 (security-engineer) APROVADO — Cache Storage sob duas camadas independentes (origem + allowlist de path), nenhuma lacuna nova exposta pela integração das 5 waves anteriores. Gate 9 (qa) **PARCIAL** — AC-013-011 (guarda de rota) VERIFICADO idêntico ao precedente de `HANDOFF-PLAN-003`; AC-013-005 (controle positivo, cache do app-shell sem API/HTML pré-login) confirmado; o ciclo completo login→uso→logout (V1/V2/V4/V5) ficou bloqueado por ambiente — `CORS_ORIGINS` do backend fixo em origem única (`:3000`), porta ocupada pela sessão paralela de PLAN-012/F4, sem fallback possível sem alterar `.env` (decisão do Diretor, não tomada). Nova lição registrada (`em-observacao`, `lessons.md`): `CORS_ORIGINS` de origem única quebra silenciosamente o padrão de porta alternativa entre sessões concorrentes. Etapa 4 (DoD): `npm run build`/`test`/`lint`/`typecheck` limpos (235/235 testes), `diff-facts.sh --deploy-pending` sem pendência (fatia pura de assets estáticos, sem migração/env). DoD do PLAN-013 fechado com ressalva declarada nos 2 últimos itens (AC-013-001/002 e a métrica operacional item (a) ficam PARCIAIS, mesma classe de `HANDOFF-PLAN-013.md`). `HANDOFF-PLAN-013.md` criado consolidando os 2 handoff_seeds das Waves 5 e 6 (V1–V4). Branch `feat/producao-material-pwa-support` no worktree `C:/kwt/pwa`, ainda **não pushada** — Entrega segue com push + tracker-sync + relatório de fecho ao Diretor (E-01 de SPEC-013 + 4 `PROPOSTA_PLUGIN` acumuladas na sessão).
- 2026-09-07 04:27: **Wave 5 de PLAN-013 concluída via `/keelson:implement`** (5/6 TASKs Done — TASK-013-005, registro do service worker + instalabilidade). Gate 1-7 (code-reviewer): REPROVOU — montagem de `<ServiceWorkerRegistration />` em `layout.tsx` sem prova de wiring (apagar linha+import deixava 234/234 verde); reincidência da lição ativa "função + wiring" (lessons.md:190), agora em composition root de React. 1 retry: `layout.test.tsx` prova a presença do componente na árvore devolvida por `RootLayout`, mutante confirmado morto — CONVERGIU. Gate 9 (qa, `screenVerify`): **PARCIAL** — AC-013-007 (contexto seguro) e a confirmação de que o SW registra/ativa de fato (fechando o resíduo declarado pelo code-reviewer) VERIFICADOS via Playwright contra build de produção real (worktree isolado). AC-013-001 (prompt nativo de instalação) e AC-013-002 (ícone/nome no app instalado) ficam `pendente_handoff` — UI nativa do navegador fora do alcance de automação headless (causa `runtime_browser`, sondagem provada, não presumida). Risco ativo registrado; seed guardado para `HANDOFF-PLAN-013.md` (consolidação após Wave 6). Achado de processo roteado ao mantenedor (LRN-016): `scripts/probe-env.sh` mascara erro de encoding (UTF-8 não lido no Windows) como "credencial ausente".
- 2026-09-07 03:39: **Wave 4 de PLAN-013 concluída via `/keelson:implement`** (4/6 TASKs Done — TASK-013-004, ciclo de atualização e kill-switch do service worker). Gate 8 (security-engineer): APROVADO de primeira — gatilho de kill-switch sem vetor remoto (literal embutido no artefato de deploy, sem canal de rede/config), fail-secure confirmado, blast radius restrito à própria origem. Gate 1-7 (code-reviewer): REPROVOU — prova estrutural de ausência de `skipWaiting`/`clients.claim` lia só o corpo do handler `activate`, não o arquivo inteiro (mutante no handler `install` sobrevivia); ramo normal do `activate` sem teste de efeito real (2 mutantes sobreviviam); `new Function()` em `sw-loader.ts` violava o perfil §6.1. 1 retry: universo ampliado para arquivo inteiro, novo teste expõe `CachesStub` provando limpeza seletiva real, `new Function` trocado por arquivo temporário + `require()` sem rastro — CONVERGIU (4 mutantes confirmados mortos). Nova lição registrada em `guidelines/project/lessons.md` ("Prova de ausência por leitura de texto-fonte precisa declarar o universo lido, derivado do quantificador do critério"). Achado `fora_de_escopo`: `CACHE_NAME` sem versionamento faz o ramo normal do `activate` ser no-op em produção hoje — decisão futura pendente (versionar a chave ou aceitar).
- 2026-09-07 03:15: **Wave 4 de PLAN-012 concluída via `/keelson:implement`** (10/13 TASKs Done — 007 CRUD de Quadro: `addMnemonicFrame`/`updateMnemonicFrameText`/`removeMnemonicFrame`). Gates: security-engineer REPROVOU (severidade alta) e code-reviewer REPROVOU no mesmo turno, mesma causa-raiz — os 3 métodos novos tinham alcance por autoria provado só ESTRUTURALMENTE, e o próprio card da TASK mandava não duplicar a prova comportamental (2ª ocorrência exata da lição ativa "[Segurança] Guarda reusada continua exigindo prova comportamental própria por novo método de escrita", registrada na Wave 3 — reincidiu na wave seguinte, mesmo arquivo). Confirmado por mutação real (`{...actor, role:'ADMIN'}`, controle negativo/positivo, worktree isolada): suíte ficava 100% verde com o alcance desligado nos 3 pontos. 1 retry consolidado (3 testes comportamentais cross-tenant + soft-delete, 1 por método) convergiu nos dois gates. Contador da lição bumpado (confirmada 2). Lição de processo derivada (roteada ao agile-coach): geração de TASK deve confrontar o "Critério de pronto" contra as lições `ativas` do projeto antes de espelhar o critério da TASK anterior. Achado fora de escopo do code-reviewer: rodar jest do backend a partir de uma 2ª worktree dentro do repo envenena o cache haste compartilhado (`%TEMP%\jest`) — sinal ao Diretor, não é defeito de código. Reincidência (3ª manifestação) da lição de TRUNCATE em banco compartilhado: processo jest zumbi no Windows não encerra após `test:integration` e corrompeu 2 rodadas de mutação até o security-engineer isolar a causa e matar os processos.
- 2026-09-07 02:31: **Wave 3 de PLAN-013 concluída via `/keelson:implement`** (3/6 TASKs Done — TASK-013-003, service worker de precache/fetch). A wave mais disputada do PLAN até aqui: 3 rodadas de gate. Rodada 1: `security-engineer` REPROVOU (severidade alta — SW sem checagem de `origin`, garantia de NFR-013-001 dependia por coincidência do esquema de URL do backend cross-origin credenciado) + `code-reviewer` REPROVOU no mesmo turno (nenhum teste executava `public/sw.js` real, só paridade de dados como texto) — retry consolidado fechou os dois. Rodada 2: `code-reviewer` REPROVOU de novo — mutante residual (`exactPaths` neutralizado) sobrevivia com suíte verde, comentário de paridade ainda overclaim; teto de retry (4.88) atingido, **decisão autônoma do Tech Lead** (degrau 1 da escada do `/keelson:auto` — achado estreito/mecânico, sem decisão de produto, revisor já prototipou o fix) por rodada dirigida em vez de escalar ao Diretor agora. Rodada 3: tabela de casos compartilhada (`sw-parity.test.ts`) dirigindo as 2 cópias reais ao mesmo caso, com verificação bidirecional (+3 mutantes extra) — APROVADO. Gate 8 (rodada 2): APROVADO. 2 reincidências roteadas em `guidelines/project/lessons.md:553` (a mesma lição já estendida na Wave 2 para fronteira de arquivo intra-repo, agora estendida para lógica/comportamento duplicado, não só dado — contadores 3→4). Achado `fora_de_escopo`: `sw-loader.ts` inaugura convenção de helper-só-de-teste dentro de `src/lib/` sem marcador — decisão de convenção pendente do Tech Lead antes das próximas waves reusarem o padrão.
- 2026-09-07 01:43: **Wave 3 de PLAN-012 concluída via `/keelson:implement`** (9/13 TASKs Done — 006 `reassignPositions`/`reorderMnemonicFrames` (reindexação em 2 fases) · 011 paridade cross-repo `tira-frontend-contract.test.ts`). A wave mais disputada do PLAN até aqui: security-engineer REPROVOU (falta prova comportamental de negação cross-autor para `reorderMnemonicFrames` — só havia prova estrutural) e code-reviewer REPROVOU no mesmo turno (eixo de cardinalidade de `isExactFrameSet` sem prova, mutante sobrevivia) — 1 retry consolidado corrigiu os 2 + 1 achado médio de segurança (guard de `count` em `applyPositions`). Na convergência, code-reviewer achou um 2º problema (o próprio guard de `count`, pedido de carona no retry, sem teste próprio) — 2ª reprovação do gate 1 na mesma wave, teto de retry atingido; escalou com proposta+default, decisão aceita (degrau 1, ação pequena e reversível) sem subir ao Diretor. Correção pontual (1 teste + mutation testing) fechou por reverificação de delta inerte. Performance: APROVADO (delta de custo exatamente 2×N medido contra Postgres real, 3 pontos de volume). 4 lições novas/reincidentes em `lessons.md` (guarda reusada exige prova própria; predicado de conjunto exige prova por eixo, não por método; código de carona em retry passa pela mesma régua; reincidência de TRUNCATE concorrente — possivelmente agravada pela sessão paralela de PLAN-013). 2 `PROPOSTA_PLUGIN` novas do `agile-coach` (LRN-015 e o incidente de ambiente do worktree de mutação), vão ao Diretor na Entrega. Achado de higiene fechado (git reset de sujeira CRLF staged); achado de higiene aberto (ESLint sem `ignores` para o worktree residual `.claude/worktrees/kan-49-vercel-entrypoint/`, degradando `quality.lint` de toda wave futura — sinal ao Diretor).
- 2026-09-07 00:49: **Wave 2 de PLAN-013 concluída via `/keelson:implement`** (2/6 TASKs Done — TASK-013-002, manifesto de aplicação). Gate 1-7 (code-reviewer): REPROVOU na 1ª rodada — 2 achados reais de falsificabilidade ("teste que não pode falhar"): paridade de cor com `layout.tsx` provada só por literal transcrito (mutante em `layout.tsx` sozinho deixava a suíte verde), e NFR-013-007 provado só pelas 2 instâncias nomeadas, não pela condição universal (mutante `scope: '/studio'` vazava sem ser pego). 1 retry: paridade agora lê `viewport` de `./layout`; NFR-013-007 agora deriva `INTERNAL_ROUTE_PREFIXES` e prova ausência na serialização JSON inteira, com controle positivo. Re-review delta-scoped (rodada 2): APROVADO, 6 mutantes confirmados matando a suíte no eixo certo. Gate 8 n/a (task não toca NFRs sensíveis de cache/rede). Lição roteada como reincidência em `guidelines/project/lessons.md` (linha 553 — Validade estendida de cross-repo para qualquer fronteira de arquivo, contadores 2→3). 3 comentários de narrativa de processo removidos no fecho (Art. 7).
- 2026-09-07 00:10: **Furo no plano em TASK-012-006** (PLAN-012) — o critério de
  NFR-011-002 pedia contagem ABSOLUTA de queries estável entre 3 e 5 Quadros, mas
  AC-011-011 exige que a Fase 2 da reindexação seja um laço de N invocações Prisma
  separadas (para permitir injeção de falha intermediária) — as duas exigências são
  incompatíveis por desenho. Destino: ajuste localizado da TASK (contrato intacto) —
  critério reescrito para o DELTA marginal entre N (2 queries por Quadro adicional,
  medido contra Postgres real), não a contagem absoluta. Corrigido também o flag de CLI
  `--testPathPattern=` → `--testPathPatterns=` (Jest 30.4.2 renomeou a flag) em
  TASK-012-006/007, antes do despacho.
- 2026-09-07 00:09: **Wave 1 de PLAN-013 concluída via `/keelson:implement`** (1/6 TASKs Done — TASK-013-001, ícones estáticos do app-shell, worktree `C:/kwt/pwa`). Gate 1-7 (code-reviewer): APROVADO de primeira, com medição direta dos bytes IHDR dos PNGs (não inspeção visual) e mutação manual do developer confirmada. Gate 8 n/a (task não toca as NFRs sensíveis de cache). 3 achados não-bloqueantes viraram `acoes_sugeridas` (ponto cego de assinatura PNG no teste, convenção `node:fs` ausente do perfil, `jsdom` desnecessário) — carona no fecho da wave. **Fora de escopo registrado**: (a) dívida de formatação pré-existente na base do `mnemonicos-frontend` — `npx prettier --check .` reprova 55 arquivos não tocados por este diff (nenhum do diff está na lista); `npm run validate` está vermelho na base por essa razão, não por regressão — correção é diff próprio, decisão do Diretor; (b) `guidelines/project/frontend/next-16.md` não enuncia a convenção `node:fs`/`node:path` para imports de builtins do Node, apesar de a base ter exemplar único e consistente — proposta de linha no perfil, fora do escopo desta TASK. Ícones nascem como placeholder de cor sólida (`--color-brand-500`, medido nos bytes do PNG) — documentado na TASK conforme A-013-002, refinamento de design fica para pedido futuro. Achado de path corrigido nas TASKs 013-002..006/PLAN-013: cwd do worktree isolado é `C:/kwt/pwa`, não `C:/kwt/pwa/mnemonicos-frontend` (esse subcaminho não existe).
- 2026-09-06 23:54: **Wave 2 de PLAN-012 concluída via `/keelson:implement`** (7/13 TASKs Done — 004 fecha o vermelho sancionado da Wave 1 (`domain-types-parity`/`typecheck`, 231/231 verde) · 005 `tira.service.ts` (regra central: `buildInitialFrames` + `openMnemonicStrip` get-or-generate idempotente, fail-secure, alcance por autoria) · 010 endpoints RTK Query). Gates: code-reviewer REPROVOU na 1ª rodada (achado A1 bloqueante em TASK-012-005 — 2ª reincidência da lição de duplicação de tipo canônico, mesma classe da Wave 1) — 1 retry, CONVERGIU (mutation testing: 4 mutantes independentes mortos — corrida real, fail-secure, N+1, ordem do guard). Gate 8 (security-engineer): APROVADO sem achados. Gate 10 (performance-engineer): APROVADO sem achados (join medido contra Postgres real, 4 queries para reabertura com 5 Quadros, sem N+1). Lição "[Código] Interface pública do PLAN é contrato mínimo" promovida de em-observação para **ativa** (2ª ocorrência confirmada). Pendência herdada incorporada como critério explícito em TASK-012-006/007/008 (confused deputy em `:frameId`, achado do security-engineer na Wave 1).
- 2026-09-06 23:34: **PLAN-013 decomposto em 6 TASKs via `/keelson:tasks`** (rota única, 6 waves sequenciais — a cadeia de dependência dos 4 COMPs é linear: ícones → manifesto → SW precache/fetch → SW ciclo de atualização/kill-switch → registro do SW → verificação de não-regressão de sessão). Cobertura 6/6 FRs, 12/12 ACs (10 gate 1, 2 ACs parcialmente split entre TASKs — AC-013-002 ícones+registro, AC-013-010 manifesto+precache — sem duplicar cobertura). TASK-013-006 isolada como fatia sensível (princípio 8): NFR-013-002/008 tocam a superfície de sessão já sensível do slug (histórico do "logout success race", BRIEF-004) — roteiro de gate 9 próprio reexercitando V1/V2/V3/V5 de HANDOFF-PLAN-003 com o SW ativo. `graph.sh --check`: 0 ERROR após 2 ajustes mecânicos (TASK-013-001 sem AC nos critérios — corrigido com cobertura parcial de AC-013-002; TASK-013-006 sem marcador `-chore-` no nome — renomeada). `task-validator`: 0 ERROR (WARNINGs remanescentes são overlap de FR-013-001/COMPs — esperado, requisito composto de instalabilidade). Aguarda `/keelson:implement`.
- 2026-09-06 23:15: **PLAN-013 criado e aprovado via `/keelson:plan`** (cobre 100% de SPEC-013 — 6/6 FRs + 8/8 NFRs, Caso D). Reconhecimento técnico do `code-scout` (antecipado no fecho da Etapa 1 do specify) reusado sem re-despacho. 4 COMPs (manifesto, ícones estáticos, service worker do app-shell, registro do SW), 2 DECs (ambas reversíveis: service worker artesanal sem biblioteca — NFR-013-005 proíbe exatamente o fallback de navegação que `serwist`/`next-pwa` dariam por padrão, custo de dependência nova sem benefício; kill-switch por autodesregistro do SW, sem endpoint novo — evita mudança no backend e superfície de rede adicional). 3 TRISKs (limite de `jsdom` para ciclo de vida real do SW — fecha por inspeção manual/gate 9; ordem de merge com PLAN-012; kill-switch dependente de deploy manual sem CI/CD). `plan-validator`: 0 ERROR após 1 volta de correção mecânica — 4 ERRORs `fr-mapeado-fora-cobertura` eram falso-positivo (mesma classe de PLAN-010: lista "NFRs cobertos" quebrada em linha de continuação, parser não segue); achado novo nesta rodada: vírgula dentro de anotação parentética no campo `Realiza` também quebra o parser (`parselist` faz split por vírgula antes de tratar parênteses) — corrigido trocando por ponto-e-vírgula; `plan-dec-alternativa-unica` (2 DECs) calibrado como WARNING aceito, mesmo padrão de PLAN-006/PLAN-010. Execução isolada em worktree `C:/kwt/pwa` (branch `feat/producao-material-pwa-support`), sem tocar a working tree principal onde PLAN-012/F4 está em andamento concorrente. DoD cobre só o item (a) da métrica mista da SPEC (conformidade por inspeção manual); item (b) (observacional, 90 dias) fica como pendência pós-Entrega. Aguarda `/keelson:tasks`.
- 2026-09-06 22:59: **SPEC-013 criada e aprovada via `/keelson:specify`** (demanda avulsa fora do épico MNEMORA STUDIO, BRIEF-013) — suporte a PWA no `mnemonicos-frontend`: instalabilidade padrão de navegador (manifesto, ícones, service worker) para EDITOR/ADMIN, sem caso de uso de produto identificado (A-013-001, premissa aberta explícita do Diretor). 6 FRs, 8 NFRs, 12 ACs, 6 premissas, 6 riscos + Q-013-001. Validator: 0 ERROR (12 WARNINGs — `spec-ac-fora-gwt` confirmado falso-positivo de calibração ao rodar o mesmo lint sobre SPEC-011 já Approved, 25/25 ACs; `spec-must-ratio`/`spec-sem-should-may` aceitos, sem FR opcional real). Crítica de mérito do `product-analyst`: `REVISAR_ANTES_DE_APROVAR`, 9 eixos de risco (destaque: sem caminho de recuperação de service worker quebrado — projeto sem CI/CD, RISK-006-009 —, e premissa de origem HTTPS de produção não confirmada nos artefatos). `po`: `ESCALAR` 1 ponto não-bloqueante (E-01, origem HTTPS — vai à Entrega) + 10 resoluções em nome do Diretor aplicadas via pacote de correção (métrica com sinal de adoção observacional, fonte de medição corrigida, aba viva preserva versão antiga, kill-switch vira NFR obrigatório, NFR de navegação sempre à rede, AC de cache com controle positivo, postura de exposição de rotas, NFR de não-regressão de sessão, selos de evidência corrigidos). Sync Jira: Story **KAN-64** em projeção compacta (sem Epic — SPEC-013 não é fatia do épico MNEMORA STUDIO, não reusa KAN-6). Código isolado em worktree próprio (`C:/kwt/pwa`, branch `feat/producao-material-pwa-support`) para não disputar árvore com PLAN-012/F4 em andamento concorrente. Aguarda `/keelson:plan`.
- 2026-09-06: **Wave 1 de PLAN-012 concluída via `/keelson:implement`** (4/13 TASKs Done — 001 migração aditiva `MnemonicStrip`/`MnemonicFrame`+`TIRA_MNEMONICA`, autorizada pelo Diretor · 002 export de `assertRawContentReachable` · 003 schemas Zod de Quadro · 009 tipos de domínio no frontend). Gates: code-reviewer REPROVOU na 1ª rodada (achados A1 export especulativo + A2 duplicação DRY em TASK-012-003; A3 fixture `position: 0` inválido em TASK-012-009) — 1 retry por TASK, CONVERGIU no re-review delta-scoped. Gate 8 (security-engineer): APROVADO sem achados (migração 100% aditiva confirmada linha a linha; export de guard byte-idêntico). 2 lições registradas em `guidelines/project/lessons.md` (reincidência de "paridade cross-repo" para faixa de valores; nova lição "[Código] lista de Interface pública do PLAN é contrato mínimo, não gabarito de transcrição", em-observação) + 1 `PROPOSTA_PLUGIN` do `agile-coach` (critério de pronto ancorado em endereço em vez de condição — item novo (j) no catálogo "resistir a contorno" de `commands/tasks.md`; vai ao Diretor na Entrega, não aplicada). Vermelho conhecido e sancionado até a Wave 2: `domain-types-parity.test.ts`/`typecheck` do backend (TIRA_MNEMONICA no schema sem espelho em `domain/types.ts` — TASK-012-004 fecha). Sinal fora de escopo: worktree residual `.claude/worktrees/kan-49-vercel-entrypoint/` no backend (outra iniciativa, não tocado).
- 2026-09-06: **13 TASKs de PLAN-012 decompostas via `/keelson:tasks`** (rota fan-out, decisão 4.310 — 1 `scribe` decompositor + 3 redatores em paralelo + `TASK-012-INDEX.md` consolidado pelo Tech Lead). 7 waves: setup-first (migração aditiva + guard exportado + schemas, wave 1) → geração/abertura idempotente (wave 2) → reindexação atômica em 2 fases + paridade cross-repo (wave 3) → CRUD de Quadro (wave 4) → rotas HTTP sob a barreira, gate 8 obrigatório (wave 5) → tela com gate 9/screenVerify (wave 6) → navegação (wave 7). Cobertura 25/25 ACs, 11/11 FRs, 6/6 NFRs — sem decomposição parcial. Correções mecânicas na redação: 5 arquivos renomeados com marcador `-chore-`; 1 seção "Riscos específicos" ausente adicionada; 6 campos `Realiza (FRs)` com NFR misturado corrigidos (campo é FR-only no grafo, `graph.sh:371`) e FR-011-010 recuperado (estava perdido pela mesma causa) em TASK-012-008/012. Validator: 3 ERRORs overridden (`task-criterio-sem-ac` em TASK-012-003/010/011 — item sem AC, oráculo é o contrato do próprio item, mesmo padrão de TASK-006-004/007 Done), demais WARNINGs calibration-consistent com os exemplares do slug. Sync Jira: 13 sub-tasks (KAN-51 a KAN-63, ver linha abaixo).
- 2026-09-06: **sync Jira (gancho `tasks`, §7) concluído para as 13 TASKs de PLAN-012** — 13 sub-tasks criadas (`issueType` Subtask, 10007) sob a Story implícita **KAN-50** (SPEC-011, degrau (0) do §7.0 — Epic-raiz reusado KAN-6): KAN-51 (TASK-012-001) · KAN-52 (002) · KAN-53 (003) · KAN-54 (004) · KAN-55 (005) · KAN-56 (006) · KAN-57 (007) · KAN-58 (008) · KAN-59 (009) · KAN-60 (010) · KAN-61 (011) · KAN-62 (012) · KAN-63 (013). Keys gravadas no campo `Jira:` da closure de cada TASK. Nenhuma transição (gancho `tasks` não move card, §9 é do `despacho`/`closure`).
- 2026-09-06: **sync Jira pulado (13 TASKs de PLAN-012 recém-geradas via `/keelson:tasks`, rota fan-out — decisão 4.310)** — 10/13 arquivos gravados neste instante (2 de 3 `scribe` redatores retornaram, 1 ainda em voo); o protocolo (`jira-sync-protocol.md`) proíbe explicitamente despachar o `tracker-sync` "nunca com o scribe ainda editando as TASKs". Prova: `ls docs/producao-material/tasks/TASK-012-*.md` = 10/13 arquivos do manifesto neste instante. Sync roda na Etapa 7 do `/keelson:tasks` assim que os 13 existirem e o grafo (`graph.sh --check --stage=tasks`) estiver limpo — não é indisponibilidade do conector, é sequenciamento do próprio protocolo.
- 2026-09-06: `/keelson:triage` classificou demanda "Adicionar suporte a PWA (manifest, service worker, ícones, instalável) ao mnemonicos-frontend" como **Categoria 1 (Nova SPEC — capacidade nova, muda o que o sistema promete)**; ação: **não executada a pedido do Diretor** — registrada como TODO/backlog para triagem futura, sem abrir `/keelson:specify` agora. Ponto em aberto para quando for retomada: o produto é fábrica interna (EDITOR/ADMIN, uso desktop) — o estudante não usa este software (compra só o PDF) — então o racional de instalabilidade/PWA para este público interno precisa ser justificado antes do ciclo, não presumido.
- 2026-09-06: **PLAN-012 criado e aprovado via `/keelson:plan`** (SPEC-011, F4) — cobertura total (11/11 FRs + 6/6 NFRs, Caso D). 14 COMPs: models `MnemonicStrip` (1:1 `RuleBreakdown`) + `MnemonicFrame` (N:1, `@@unique([stripId,position])` como defesa em profundidade); módulo backend `tira/` em camadas (schema Zod → service com `$transaction` → routes); reuso por export de `assertRawContentReachable`; extensão aditiva de `ProductionStageType`/`domain-types-parity.test.ts`; rede de paridade cross-repo nova para Tira/Quadro; tela `(interno)/content/[id]/tira` (Server Component + client component com CRUD/reordenação/3-estados). 10 DECs, todas reversíveis (destaque: reindexação atômica em 2 fases; geração idempotente via `create`+unique-violation, precedente de `saveRuleBreakdown`; fronteira abertura/conclusão na 1ª mutação humana). 5 TRISKs novos (destaque: `ALTER TYPE ADD VALUE` em migração transacional — verificar versão real do Postgres). Migração 100% aditiva, `Mnemonic` legado intocado no schema. Validator: 0 errors, 8 warnings (`plan-dec-alternativa-unica`, mesmo padrão do exemplar PLAN-010) — 2 correções mecânicas aplicadas (formato `Reabrir se: nunca`; campos `Realiza` multilinha colapsados, 1 gap real preenchido em COMP-012-012).
- 2026-09-06: **SPEC-011 criada e aprovada via `/keelson:specify`** (F4 do épico MNEMORA STUDIO, BRIEF-011) — Tira mnemônica como sequência de quadros: geração automática 1 Quadro/Bloco não-vazio da Quebra da regra, CRUD completo + reordenação atômica (NFR-011-002), instrumentação da etapa "Tira mnemônica" (aditiva a F3). Validator: 0 errors, 23 warnings (falso-positivo de concordância de gênero no lint, registrado como pendência de processo). Crítica de mérito do product-analyst (9 eixos) resolvida pelo PO — correções aplicadas: fronteira abertura/conclusão da etapa movida da geração para a 1ª mutação humana (preserva o lead time real da etapa central do método); alcance por autoria de F2 restabelecido em NFR-011-001 (OWASP A01 — superfície nova não nasce mais permissiva); RISK-005-004 reclassificado, não encerrado (RISK-011-001); carimbo de proveniência nullable acrescentado (F9 pode precisar); +5 ACs (Tira vazia, sem Quebra salva, corrida na 1ª abertura, EDITOR-B-inalcançável, etapa aberta sem conclusão); 3 riscos novos aceitos (RISK-011-005/006/007). PO: ESCALAR não-bloqueante (E-01 — limiar do piloto A/B, molde E-01/E-02 de F3), vai à Entrega. Sync Jira: Story implícita **KAN-50** (parent KAN-6).
- 2026-09-06: **Sync Jira do gancho `specify` (SPEC-011).** SPEC sem FEATs declaradas (fluxo único, A-011-010) → degrau (0) do §7.0, Story implícita espelhando a SPEC inteira. Reusado o Epic-raiz **KAN-6** como issue principal (mesma regra já aplicada em SPEC-002/005/009 — nenhum Epic novo criado). Story implícita criada como **KAN-50** (parent KAN-6, nasce em "Tarefas pendentes"). Keys gravadas no cabeçalho da SPEC-011 (`**Jira**: KAN-6`, `**Jira Story**: KAN-50`). Descrição com 11 cenários manuais + 9 ACs cobertos só por verificação automatizada (falhas forjadas, eventos de instrumentação sem tela e assertiva de código sobre o modelo legado — regra (a) da receita §6.2).
- 2026-09-06: **PLAN-010 mergeado** (backend `6541d49`, PR #3) — Status → **Done**. Suíte completa reconfirmada verde pós-merge na `main`: unit 217/217 (20 suítes), integração 231/231 (13 suítes), typecheck/lint limpos. Frontend sem mudança nesta fatia (nada a mergear). Migração `20260906143159_add_production_stage_event` agora em `main`; aplicação em produção segue pendente (ato manual do Diretor, sem pipeline de CI/CD — RISK-006-009).
- 2026-09-06: **F3 do épico MNEMORA STUDIO entregue** (`/keelson:continue` → `/keelson:auto`, ciclo completo SPEC→PLAN→TASKs→implement). Diretor respondeu as 2 escalações parqueadas (E-02) na Entrega: lead-time e fail-secure confirmados como entregues, sem mudança de código. Branch `feat/producao-material-mnemora-studio` pushada (backend `c50448e`); merge/PR/deploy pendentes do Diretor (inclusive a migração aditiva em produção). Sync Jira: KAN-45 (Story) em "Em análise", KAN-46/47/48 (Subtasks) "Concluído", reconciliação confirmada sem correção necessária.
- 2026-09-06: **Convergência de fecho verde em `c50448e`** (dedup: aplicada) — code-reviewer, modo convergência: confronto semântico completo (10/10 FRs, 5/5 NFRs, 10/10 ACs de SPEC-009 realizados no código final; 7/7 DECs de PLAN-010 refletidas; nenhuma condição `Reabrir se:` satisfeita). As 2 escalações do PO (A-009-010 fail-secure, A-009-012 lead-time) confirmadas **implementadas de fato**, não só declaradas. 1 achado de dedup não-bloqueante (Wave 3 duplicou fixture local em vez do helper da Wave 2 — 2ª reincidência de LRN-009, roteada). CONVERGIU.
- 2026-09-06: **PLAN-010 IMPLEMENTADO POR COMPLETO — 3/3 TASKs, sem FEATs (SPEC-009 sem heading FEAT)** — fecho da Wave 3 (TASK-010-003, integração transacional em `contents.service.ts`: `createRawContent`/`updateRawContent`/`saveRuleBreakdown` dentro de `$transaction`, 5 gatilhos de emissão + concorrência real + fail-secure). Gates 1-7/8/10 aprovados de primeira (0 retry) — falsificados por mutation testing real (mutantes que reordenam emissão ou removem `$transaction` matam os testes de concorrência/fail-secure). TRISK-010-001 e TRISK-010-005 fechados com medição real em vez de aceitos por raciocínio (criação: 4,16→21,74ms/1→8 round-trips, folga de ~3 ordens de grandeza; serialização do lock único provada por mutante). 3 achados `media` não-bloqueantes viraram TRISK-010-006/007 (recomputo de histórico, materialização sem teto — ambos com `Reabrir se:` explícito). **Incidente de processo na rodada de gates**: os 3 gates rodaram em paralelo sobre a árvore principal sem `git worktree` própria (violação de 4.134/4.361/4.334) — `performance-engineer` truncou o banco de teste compartilhado no meio de sondas de outro gate, `code-reviewer` flagrou a árvore em 3 conteúdos distintos do mesmo arquivo (evitou veredito falso ancorando por hash de conteúdo), e o Tech Lead removeu arquivos de sonda de um gate ainda em voo. Todos os vereditos finais são confiáveis (cada gate se auto-corrigiu); lição de processo roteada ao `agile-coach`. Cobertura final: 217/217 unit + 231/231 integração. Status sugerido do PLAN: **Done** (promoção manual é do Diretor, na Entrega).
- 2026-09-06: **Wave 2 de PLAN-010 fechada** (TASK-010-002 — `production-events.service.ts`: regra de decisão pura + emissão transacional + leitura ordenada com `select` explícito). code-reviewer REPROVOU 1ª rodada (fixture `createUser`/`createTopic`/`createRawContent` duplicada byte-a-byte do irmão da Wave 1 — a própria TASK mandava seguir esse molde, contra o perfil §7); retry criou `tests/support/production-events-fixtures.ts` (helper único), migrou de carona o irmão da Wave 1, aplicou 2 remoções de comentário Art. 7 e reforçou o tripwire estrutural com controle positivo — aprovado. performance-engineer: aprovado, medido ao vivo (índice usado sem Seq Scan a 30k linhas, DEC-010-005 confirmada em números). Lição de processo roteada ao `agile-coach`: `PROPOSTA_PLUGIN` (LRN-009, `docs/_meta/learning-log.md`) para `commands/tasks.md` — molde citado como exemplar deveria se confrontar também contra a doutrina do perfil, não só contra `lessons.md`. Cobertura final: 217/217 unit + 221/221 integração. TASK-010-INDEX: 2/3 Done.
- 2026-09-06: **Wave 1 de PLAN-010 fechada** (TASK-010-001 — migração aditiva `ProductionStageEvent` + 2 enums, espelho de tipos, rede de paridade). Bloqueio ambiental no meio da wave: Docker Desktop desta sessão ficou indisponível (WSL2 `docker-desktop` parado); Diretor autorizou reiniciar (via `wsl --shutdown` + relaunch) e autorizou a migração. Aplicada, 100% aditiva (2 `CREATE TYPE`, 1 `CREATE TABLE`, 1 `CREATE INDEX`, 2 `ADD CONSTRAINT` — 0 `DROP`/`ALTER` destrutivo). Achado real na 1ª rodada de testes: FK `onDelete: Restrict` no Postgres levanta SQLSTATE 23001, que o adapter-pg não mapeia — chega como `P2039`, não `P2003` como o teste (e o critério da TASK) presumiam; corrigido, com 2ª asserção (sobrevivência da linha) tornando o oráculo robusto ao código de driver. Lição registrada (`guidelines/project/lessons.md`, `[Dados/Persistência]`) + gotcha em `node-22.md` §11 + correção de claim stale em §7 (suíte de integração existe desde F1, 12 suítes/215 testes). code-reviewer: 1 retry (format:check), aprovado; security-engineer: aprovado, 0 achados; performance-engineer: aprovado, medido ao vivo (EXPLAIN 60k linhas, índice cobre a leitura ordenada sem Seq Scan). Cobertura final: 210/210 unit + 215/215 integração. TASK-010-INDEX: 1/3 Done.
- 2026-09-06: **TASK-010-INDEX gerado via `/keelson:tasks`** (PLAN-010 decomposto em 3 TASKs, 3 waves sequenciais: migração+tipos+parity → mecanismo de emissão/leitura → integração transacional+suíte dos 5 gatilhos). Cobertura 10/10 FRs, 10/10 ACs (nenhuma lacuna). `graph.sh --check --stage=tasks`: 1 WARNING (`index-desatualizado` em AC-009-008, corrigido — TASK-010-001 também cobre parcialmente via desempate no nível do schema); `task-validator`: 0 ERROR (mecânico limpo; revisão de julgamento confirmou verificação executável falsificável em todos os critérios, escopo simétrico, nenhum gate 9 — mecanismo sem UI). Sync Jira (gancho `tasks`): 3 sub-tasks criadas sob a Story implícita KAN-45 — KAN-46 (TASK-010-001), KAN-47 (TASK-010-002), KAN-48 (TASK-010-003).
- 2026-09-06: **PLAN-010 criado via `/keelson:plan` e promovido a Approved** (cobre 100% de SPEC-009 — 10 FRs + 5 NFRs, Caso D). Reconhecimento técnico do `code-scout` (antecipado na Etapa 1 do `/keelson:auto`) reusado sem re-despacho. 6 COMPs (modelagem de dados, mecanismo de emissão/leitura, integração transacional em `contents.service.ts`, espelho backend de tipos, extensão da rede de paridade, suíte de teste dos 5 gatilhos+fail-secure), 6 DECs (todas reversíveis — enum Prisma fixo p/ tipo de etapa/transição; coluna `sequence` BigInt autoincrement p/ desempate determinístico, território greenfield; emissão do evento na mesma transação Prisma da mutação de negócio; módulo `production-events/` dedicado sem schema/routes; decisão de transição resolvida internamente pelo histórico; espelho cross-repo do enum adiado — YAGNI, sem consumidor). 4 TRISKs registrados acima. `plan-validator`: 0 ERROR após 1 volta de correção de forma (enum `Irreversível` em ASCII `nao`; listas `FRs/NFRs cobertos` uma linha por ID — o parser mecânico não segue continuação de linha; §7 ganhou linhas de NFR, não só FR, e `Realiza` de 2 COMPs teve o mesmo bug de wrap corrigido); `plan-dec-alternativa-unica` (4 DECs) calibrado como WARNING aceito, mesmo padrão de PLAN-006. PLAN → **Approved** v0.2.
- 2026-09-06: **SPEC-009 criada, revisada e promovida a Approved (F3, via `/keelson:auto` retomado por `/keelson:continue`).** `scribe` redigiu 10 FRs/4 NFRs/8 ACs/10 premissas a partir do BRIEF-009. Validação de forma (`spec-validator`): 0 ERROR (só WARNINGs — 2 classes ambientais que atingem igualmente as SPECs já Approved deste projeto, não defeito desta SPEC). Crítica de mérito (`product-analyst`): `REVISAR_ANTES_DE_APROVAR`, 8 eixos de risco de produto (semântica lead-time×esforço, retrabalho como contagem×duração, abertura órfã, fronteira com F8, semente sem evento, métrica autorreferente, ausência de não-regressão de F2, empate de instante em AC-009-008, selo de evidência uniforme). `po` (modo aprovação): `ESCALAR` 2 pontos (registrados como E-02 acima), resolveu os demais 8 dentro do brief — pacote de correção aplicado pelo `scribe` (11 edições: §1.3 reescrita no molde de SPEC-002/005 com fonte externa+observacional; AC-009-008 com desempate determinístico; FR-009-010 sem agregação; A-009-011 gap da semente declarado; fronteira F8 explicitada em §4.2; NFR-009-005+AC-009-009 de não-regressão de F2; AC-009-010 fail-secure; Q-009-002 nova; selos de A-009-005/008/009 corrigidos para `observação`; A-009-012 lead-time declarado). Revalidação mecânica limpa (0 ERROR). SPEC → **Approved** v0.2. Estimativa do `estimator` na largada: ~4–5 waves, ~8 tasks, 20–48h de ciclo — registrada em BRIEF-009.
- 2026-09-06: **Fila do épico corrigida (`/keelson:continue`, princípio 2).** F2 estava `em ciclo (BRIEF-005.md)` mas os artefatos mostram **entregue**: PLAN-006 Done 14/14, PR #2 (backend `ac5c4f8`) e PR #3 (frontend `0bcbacd`) mergeados em `main` nos dois repos. Largada de F3 (BRIEF-009): branch do épico sincronizada com `main` (fast-forward, sem conflito) nos 2 repos.
- 2026-09-06: **Sync Jira do gancho `specify` (SPEC-009).** SPEC sem FEATs declaradas (fluxo único) → degrau (0) do §7.0, Story implícita espelhando a SPEC inteira. Por instrução do Diretor, reusado o Epic-raiz **KAN-6** como issue principal (mesma regra já aplicada em SPEC-002/SPEC-005 — nenhum Epic novo criado). Story implícita criada como **KAN-45** (parent KAN-6, nasce em "Tarefas pendentes"). Keys gravadas no cabeçalho da SPEC-009 (`**Jira**: KAN-6`, `**Jira Story**: KAN-45`). Descrição da Story sem cenário manual em "Como testar": os 8 ACs desta SPEC (captura de eventos de instrumentação) não têm caminho manual observável — nenhuma tela/rota/endpoint expõe os eventos nesta fatia (A-009-004) — todos cobertos só pela linha de verificação automatizada, conforme a regra (a) da receita §6.2; gap declarado, não é falha do sync.
- 2026-09-06: **Divergência de tracker corrigida.** Checagem ao vivo (`searchJiraIssuesUsingJql`) achou as 17 issues de PLAN-006 (Epic KAN-6, Histórias KAN-27/28, 14 subtasks KAN-29..42) todas em "Tarefas pendentes" — a ficha estava com `jira.transition: "comment"` (nunca move card), então o sync criou/vinculou as issues certas mas nunca refletiu o avanço real no board; a doc local ("14/14 Done") e o Jira divergiam. Diretor trocou a ficha para `jira.transition: "auto"`. Transições medidas ao vivo em 3 cards de 2 tipos (Subtask, História) — idênticas, sem validator/post-function com tela própria (`docs/_meta/jira.KAN.md` "Transições medidas"). Por instrução explícita do Diretor: 14 subtasks → **Concluído** (id 41); 2 Histórias → **Em análise** (id 31, não Concluído — a História só fecha após revisão própria). Epic KAN-6 não movido (fora do pedido). Todas as 16 transições confirmadas ao vivo pós-execução.
- 2026-09-06: **Etapa 4 (DoD) de PLAN-006 concluída** — 6/6 itens do §9 verificados com evidência e marcados no PLAN. Reconfirmação ao vivo, ao fecho: backend unit 208/208 (19 suítes), backend integração 213/213 (11 suítes), frontend 166/166 (16 suítes) — todos verdes. Item da métrica §1.3 fechado **parcial, gap declarado**: (a) tripwire `route-authz-matrix` 19/19 provado, mas a cláusula "verde no CI" é insatisfazível hoje — nenhum dos 2 repos tem pipeline de CI configurado (gap pré-existente ao PLAN, registrado como RISK-006-009); (b) invariante `radarClass` provado; (c) número primário observacional apurado por inspeção humana no Postgres de dev (autoria EDITOR vs. ADMIN da semente): **0 Conteúdos de Obrigação Tributária com Quebra completa produzidos pela tela** — as únicas interações reais até aqui foram as sessões do gate 9, que restauram os dados ao final; estado esperado de pré-lançamento (mesma natureza de MET-002-001), série passa a acumular no primeiro uso real pós-Entrega. Também nesta Entrega: Diretor autorizou exclusão de 2 arquivos suspeitos na raiz do workspace (nomes com cara de caminho Windows quebrado/token — nenhum lido/ecoado, `.gitignore` endurecido com `*.gh-token`/`C:*`) e respondeu E-01 (Q-005-004): EDITOR PODE cadastrar tema/assunto novo em disciplina existente — reabre A-005-007 (SPEC-005) sem reabrir PLAN-006 (já entregue sob o comportamento anterior); capacidade nova registrada em "Especificadas, ainda não planejadas".
- 2026-09-05: **PLAN-006 IMPLEMENTADO POR COMPLETO — 14/14 TASKs, 2 FEATs (8/8 cada)** — fecho da Wave 5 (TASK-006-012 listagem, TASK-006-013 formulário de Conteúdo bruto, TASK-006-014 tela da Quebra da regra). As 3 telas rodaram em paralelo (territórios disjuntos). Convergência de gate foi a mais longa do PLAN: 4 rodadas de gate 1-7/11 até fechar limpo — achados reais e bem fundamentados em cada rodada (grafo de navegação incompleto, estados de UI não tratados, contraste AA, ação primária duplicada, guarda de hidratação sem oráculo, regressão de prova ao resolver ambiguidade de query), nunca ruído. 2 dessas rodadas passaram do teto de 1 retry (decisão 4.88) — código escalou explicitamente ao Diretor via AskUserQuestion antes de prosseguir, nas duas vezes autorizado. Tokens `--link`/`--danger` criados em `globals.css` como padrão canônico de cor semântica do produto (medidos ≥4.5:1 nos 2 temas, verificado no CSS compilado). Gate 9 (qa): **VERIFICADO** para as 2 FEATs com execução real (browser + Postgres) — AC-005-033 (navegação listagem→Quebra), AC-005-011 (remoção com DELETE real interceptado/retido), AC-005-019 (round-trip da Quebra com reload real do browser + checagem de não-vazamento). **2 briefs avulsos autorizados pelo Diretor no meio do fecho**: BRIEF-007 (investigação de um achado de CSRF em `POST /auth/refresh` — concluiu que a proteção já existia desde F1, o gap era só na rede de prova automatizada) e BRIEF-008 (aplicar o token `--danger` retroativamente em 2 arquivos de F1 com o mesmo defeito de contraste). Lições roteadas: [Design] cor semântica vem de token nunca de literal da paleta (nova); [Testes] `npx jest` com route group entre parênteses é interpretado como regex e sub-seleciona silenciosamente (registrada em `next-16.md` §7, doutrina de perfil); [Processo] LRN-001 generalizado pela 3ª vez (recurso mutável compartilhado agora inclui banco de teste, não só git/node_modules); [Processo] LRN-008 nova (brief avulso não força reconciliar premissa refutada pela própria execução). TASK-006-INDEX: 14/14 Done.
- 2026-09-05: **Wave 4 de PLAN-006 fechada** (TASK-006-011 — `contents.routes.ts`, 7 rotas de Conteúdo bruto/Quebra da regra sob a barreira deny-by-default de F1, tripwire 12→19). Task única, implementada limpa na 1ª passada pelo developer (212/212, 4 mutantes adversariais confirmados ao vivo). Gate 8 (security-engineer) APROVOU direto — varredura completa por 13 categorias OWASP, 0 achados, 4 mutantes reexecutados. Gate 1-7 (code-reviewer) REPROVOU 1x: o critério de `verifyOrigin` prometia posição ("1º handler") e ausência nos GETs, mas a asserção só provava pertencimento (2 mutantes sobreviventes) — código de produção já correto, gap só de prova. Retry test-only (1 arquivo, `route-authz-matrix.integration.test.ts`) fortaleceu a asserção repo-wide; re-review APROVOU com 5 mutantes ao vivo (2 de controle fora de `/contents`, confirmando alcance repo-wide). **Achado relevante do re-review, fora do escopo desta wave**: `POST /auth/refresh` (rota PRÉ-EXISTENTE de F1) podia perder `verifyOrigin` sem nenhuma suíte acusar — gap na rede de prova (RISK-006-008; investigação do BRIEF-007 confirmou que o código já estava protegido desde F1, não havia vulnerabilidade ativa — fechado no mesmo dia, ver entrada abaixo). Também descoberta, na mesma rodada: contenção real de banco entre gates paralelos da Wave 3/4 (worktree isola arquivo, não `mnemonicos_test` compartilhado) — vermelho não-determinístico diagnosticado corretamente como infra, não defeito. 2 remoções de comentário Art. 7 aplicadas antes do fecho. TASK-006-INDEX: 11/14 Done.
- 2026-09-05: **Wave 3 de PLAN-006 fechada** (TASK-006-007 rede de paridade cross-repo, TASK-006-008 `listRawContents` com alcance, TASK-006-009 Quebra da regra upsert 1:1, TASK-006-010 saneamento do `api.ts`) — sub-wave 3a paralela (T007/T008/T010, territórios disjuntos) + T009 sequencial após T008 (overlap de arquivo). Os 3 gates (1-7, 8, 10) REPROVARAM na 1ª rodada: (1) `assertRawContentReachable` avaliava `soft-deleted` antes de `fora do alcance` — vazava oráculo de autoria via mensagem (EDITOR A distinguia "não encontrado" de "foi removido" sobre conteúdo de EDITOR B), achado convergente code-reviewer+security-engineer; (2) CLASSE de divergência de contrato cross-repo entre `contents.service.ts` e os tipos do frontend (`rawText`/`rawTextExcerpt`, `RuleBreakdown` com 4 campos fantasma, `condition`/`exception` null-vs-optional — levaria 400 no caminho feliz de T014) — causa raiz: DEC-006-005 só cobria enums, "mesmo diff + typecheck" para interfaces era garantia vazia (typecheck é por repo); (3) `listRawContents` sem índice cobrindo `where{authorId,deletedAt}+orderBy createdAt` — Seq Scan medido crescendo com o volume (170,9-218,9ms); (4) `withQueryProbe` duplicado; (5) ramo "pai alcançável sem Quebra ainda" sem teste. Migração de índice **autorizada pelo Diretor** via `AskUserQuestion` antes de gerar/aplicar. Retry consolidado único (commits `8262cb7`/`d041e77` backend, `6cdf54e` frontend): reordenou guards (`inexistente → fora do alcance → soft-deleted`), criou `contents-frontend-contract.test.ts` (rede de paridade para as interfaces, não só enums), adicionou `@@index([authorId,createdAt])`+`@@index([createdAt])` (migração aditiva `20260905130131_add_raw_content_listing_indexes`), estendeu prova de `total` por autoria, içou `withQueryProbe`, testou o ramo faltante. Re-review APROVOU os 3 gates com todos os mutantes decisivos reexecutados ao vivo (não aceitos por leitura) — EXPLAIN confirmou fim do Seq Scan (ADMIN 36,1ms→0,16-0,914ms; EDITOR 10,2-170,9ms→0,28-0,631ms) em 2 medições independentes. Limpeza pós-aprovação (commits `6eccd54`/`e789c6d`): removida narrativa de processo ("EMENDA pós gate N") de 19 pontos do código/docblocks/nomes de teste (Art. 7), sinalizada pelo próprio code-reviewer com causa apontada no despacho do Tech Lead. 509+ testes verdes nas 2 pontas, typecheck/lint/build limpos. 3 lições [Processo]/[Testes]/[Performance] roteadas ao `agile-coach`. Worktrees isoladas (`C:/kwt/sec`, `C:/kwt/perf`) usadas pelos 3 gates para mutar/medir sem disputar a árvore principal entre si — removidas ao fim.
- 2026-08-28: Wave 1 do PLAN-003 fechada (TASK-003-001/002/005 Done) — gate 8 reprovou e convergiu em 1 retry (fail-open no COOKIE_SECURE, redação do pino, contrato HMAC); errata propagada ao PLAN e TASKs; 2 lições registradas (pendentes de merge)
- 2026-08-28: Wave 2 do PLAN-003 fechada (TASK-003-016 harness de integração, -003 libs cripto/audit, -004 rotação pura) — gates 1–8 aprovados após 1 retry de convergência (precedência de ramos falsificável, prova de params de env, guarda fail-closed do banco de teste); 2 lições registradas (pendentes de merge)
- 2026-08-29: furo no plano em TASK-003-006 — `refresh`/`logout` emitem eventos de auditoria mas suas assinaturas não recebiam `ip`, obrigatório em `AuthAuditEvent` (audit.ts selado na Wave 2) por NFR-002-005 — destino: `refresh`/`logout` passam a receber `ctx: { ip; userAgent? }` (aditivo; rota passa `req.ip`); PLAN + TASK-003-006/009 emendados
- 2026-08-29: DEC-003-003 emendada (decisão degrau 1 do Tech Lead, veto na Entrega) — cláusula `replay-grace` idempotente era infeasible sob DEC-003-002 (só hashes persistidos); replay-grace passa a tratar como rotate (nova ponta, sem revogação/token.reuse na graça); cliente serializa o refresh (TASK-003-013)
- 2026-08-29: Wave 3 do PLAN-003 fechada (TASK-003-006 auth.service, -008 freio de login, -012 seed do 1º ADMIN) — gates 1–10 aprovados após 1 retry de convergência + 1 furo no plano (ctx de origem); 3 lições registradas (pendentes de merge)
- 2026-08-29: Wave 4 do PLAN-003 fechada (TASK-003-007 middlewares authenticate/authorize + ROUTE_ROLES) — gate 8 APROVADO; gates 1–7 REPROVARAM 1º passe (4 achados críticos de authz: registro populado em request, requireAuth só checava existência, chave sem método, curinga vaza) → retry `ead57a2` fechou os 4; re-review reprovou só gate 1 por regressão de prova (caso de teste perdido na reescrita) → resolvido `b106b84` test-only (teto de convergência 4.88 → decisão autônoma, ao veto do Diretor). DEC-003-005 EMENDA Wave 4 (chave `"<MÉTODO> <caminho>"`, declaração em montagem, `sealRouteRoles`, `requireAuth` piso de autz); resíduo `:param` de irmã estática → critério em TASK-003-011; 4 lições candidatas (pendentes de rota/merge)
- 2026-08-29: sync Jira reconciliado (gancho closure — conector Atlassian de volta após o bloqueio AWS WAF "Human Verification" das Waves 2–3; prova `atlassianUserInfo` retornou JSON) — sub-task de TASK-003-016 criada (KAN-26 sob KAN-8); marco "TASK concluída" comentado em 10 sub-tasks (KAN-11/12/13/14/15/16/17/18/22/26); "Trabalho iniciado (Story)" comentado em KAN-8/KAN-9/KAN-10; `transition: comment` → nenhum card movido, nenhuma FEAT fechada (KAN-8 0/5+harness, KAN-9 1/3, KAN-10 2/3)
- 2026-08-30: Wave 5 do PLAN-003 fechada (TASK-003-009 rotas de auth + cookies + `getSessionUser`; TASK-003-010 módulo `users/`) — gate 10 APROVADO, gate 9 APROVADO (FEAT-002-003 completa → Implementadas); gate 8 REPROVOU (race condition na guarda do último ADMIN + CSRF nas 3 mutações de `users/`) → retry `27ef0dd` fechou; re-review REPROVOU só o gate 1 (2ª vez → teto 4.88) por ausência de prova (fixture de corrida fora da fronteira + par de precedência de `disableUser` sem caso) → resolvido `89c67e2` test-only (decisão autônoma, veto do Diretor). Furos no plano: `getSessionUser` nasce na TASK-009 (`req.auth` sem `name`/`email`); falha de serialização é `DriverAdapterError`, não P2034 (Prisma 7 + adapter-pg). EMENDAS: COMP-003-008/013/014/015, DEC-003-004. 6 lições candidatas (2 projeto registradas; processo → agile-coach). Incidente de higiene: gates poluíram a árvore compartilhada 2× (npm install + `@babel/core`; npm ci em worktree junctionada) → restaurado com `npm ci`.
- 2026-08-30: Wave 6 do PLAN-003 fechada (TASK-003-011 montagem deny-by-default + suíte `route-authz-matrix`; TASK-003-013 store do frontend com re-auth + `proxy.ts`) — gate 10 n/a, gate 1–7 REPROVOU 1º passe (CR1 `assertDenyByDefault` sem wiring; CR2 matcher catch-all; CR3 ramo `://`) → retry `c5188cf`/`e75a11f` fechou, re-review APROVADO; gate 8 REPROVOU 1º passe (S1 alta: re-auth ressuscita sessão no 401 de `/auth/login`; +S4 allowlist cega ao método) → retry fechou os 4, mas ABRIU regressão alta (`/auth/logout` no espelho → logout no-op com access expirado) → resolvida `6281039` (teto 4.88 → decisão autônoma, veto do Diretor). EMENDAS: DEC-003-005 (allowlist método-aware — lição da Wave 4 aplicada), COMP-003-022 (matcher enumerado). Métrica §1.3: fonte = `route-authz-matrix`, registrada no INDEX. 5 lições candidatas (3 projeto + node-22/next-16; processo → agile-coach). Incidentes de higiene: gate concorrente escreveu `tests/zz-probe.test.ts` na árvore durante o re-review (reincidência 4); worktree órfão com `.env` real podado.
- 2026-09-01: **HANDOFF-PLAN-003 FECHADO** — caminhada de tela V1–V5 OK (Playwright, código mergeado); V6 `n/a` (coberto por teste montado). Risco HANDOFF-003 removido dos Riscos ativos. F1 do épico MNEMORA STUDIO entregue e verificado.
- 2026-09-01: **BRIEF-004** (avulso, fast-follow do V5) Concluído — branch `fix/producao-material-logout-success-race` (`9f2225c`·`8f91d3b`·`635314c`) **mergeada** (PR #2 `f60659c`). Flag `justLoggedOut`: logout de sucesso não dispara "sessão expirou" nem laço de `refresh`. Gates 1–9 APROVADO/CONVERGE (teto 4.88 num gap de briefing → addendum autorizado pelo Diretor; §6.3 do `next-16.md` amendada = 3 oráculos). V5 verificado no browser (Playwright 2×). 1 MEDIA não-bloqueante (dívida): `__resetAuthGuards()` test-hook exportado sem cerca de lint. Falta: merge (Diretor) + caminhada de tela de V5/V6.
- 2026-09-01: PLAN-003 **mergeado** (backend `25cdafd` · frontend `834f117`, PR #1); Status → **Done**; Stories KAN-8/9/10 e sub-tasks KAN-11..26 → Concluído no Jira (KAN-7 Épico segue aberto — multi-fatia). Caminhada de tela do HANDOFF-PLAN-003 exercitada (Playwright, app local): **V1–V4 OK**, **V5 FALHOU** (logout de sucesso → `/login?sessao=expirada` + laço de `me`/`refresh` 401 — "logout success race" da Wave 7, agora com evidência ao vivo), V6 não exercitado. Handoff **permanece Pendente**; fast-follow em `main` (developer + re-gate). Ambiente de dev: ADMIN `admin@mnemonicos.local` semeado, 4 usuários-fixture removidos do DB de dev, `SEED_ADMIN_*` no `.env` local (gitignored).
- 2026-08-31: `/keelson:integrate` de PLAN-003 — DoD §9 validada (14 itens; `npm audit` backend 0 vulns; `gates.screenVerify` parcial via HANDOFF-003 aceito). Suíte completa verde (be unit 165/165 · be integração 133/133 · fe 86/86 · lint/typecheck/build). **Convergência de fecho: CONVERGIU** (code-reviewer — 0 gaps `ausente`/`parcial`/`contradiz`; 24 FR + 9 NFR + 29 AC provados; 12 DEC + EMENDAS refletidas; métrica §1.3 verde; paridade de tipos por leitura cross-repo; sem segredo em log/resposta). `quality.mutation`/`quality.e2e` = não configurados (opt-in). **PR não aberto** — `gh` ausente / sem `GH_TOKEN` no ambiente; descrições dos 2 PRs prontas (backend + frontend, base `main`, head `feat/producao-material-mnemora-studio`). Aberto pendente: 2 decisões não-bloqueantes declaradas (comentário de `api.ts` × teste de divergência cross-repo; superfície declarada sem consumidor em F1). 1 lição de projeto registrada.
- 2026-08-31: Wave 7 do PLAN-003 fechada (TASK-003-014 tela de login; TASK-003-015 shell da área interna) — PLAN-003 **16/16**, FEAT-002-001 e FEAT-002-002 → Implementadas. gate 10 n/a. gate 1–7 REPROVOU 1º passe (`config.matcher` via `.flatMap()` derruba `next build` — Next lê `config` por AST estático; `roleSatisfies('STUDENT',*)` sem caso; `INTERNAL_HOME` literal duplicado; costura `resetApiState()`×`missingSession` sem oráculo) → retry `f6cc4ed` fechou 5 de 6; gate 8 REPROVOU 1º passe (mesma raiz do `config.matcher` + `<form>` sem `method=`) → fechou no mesmo retry. A4 (AC-002-027) não fechou no retry (oráculo trocado por função pura; bug real verde na suíte: `resetApiState()` no `finally` do `logout` desmontava `LogoutControl` e matava a mensagem de falha) → teto 4.88 batido → **rodada dirigida A4 `e6d0c75`** autorizada pelo Tech Lead (veto do Diretor na Entrega): `logout.onQueryStarted` reseta o cache só após sucesso (EMENDA COMP-003-021 Wave 7); re-review APROVADO (3 mutantes mortos, oráculo montado contra a `api` real). gate 9 **pendente_handoff** para as duas FEATs (tela bloqueada — causa: credencial). EMENDAS: COMP-003-021 Wave 7, COMP-003-022 (matcher literal), TASK-003-014/015 (critérios de retry). 3 lições projeto em `lessons.md` + `next-16.md` §6.3/§11; 3 lições processo → agile-coach (Etapa 4.5). Incidentes de higiene: gates paralelos escreveram mutantes/sonda na árvore compartilhada + alteração estagiada invertendo oráculo A4 (restaurado pelo security-engineer; árvore confirmada pristina em `e6d0c75`).
- 2026-09-01: sync Jira (gancho specify — SPEC-005 "Conteúdo bruto e quebra da regra", 2 FEATs) — issue principal SPEC-005 = **KAN-6** (reuso do Epic-raiz MNEMORA STUDIO por instrução do Tech Lead: "sem criar Epic novo"; nenhum Epic criado); Stories das FEATs: **KAN-27** (FEAT-005-001) + **KAN-28** (FEAT-005-002), ambas com `parent` = KAN-6 (Epic▸História, adjacência OK). `transition: comment` → nenhum card movido. Achado reportado ao Tech Lead: F1 usou Epic dedicado por fatia (KAN-7, sem `parent` para KAN-6); F2 diverge desse padrão — decisão de estrutura pendente do Diretor.
- 2026-09-01: **SPEC-005 criada via /keelson:specify** (F2 do épico MNEMORA STUDIO, nasce de BRIEF-005) — 2 FEATs, 24 FRs, 7 NFRs, 36 ACs (vão intencional em AC-005-017), 13 premissas. spec-validator PASS (0 ERROR, 1 auto-fix); graph.sh 0 achado. `product-analyst` REVISAR_ANTES_DE_APROVAR (10 pontos de mérito); `po` ESCALAR → 10 pontos resolvidos pelo BRIEF-005 / decisão reversível em nome do Diretor (prioridade de apresentação → F10; remoção reversível; ADMIN escreve com autoria imutável + carimbo; métrica §1.3 ganha número observacional na Entrega; 3 estados + ordenação na listagem; navegação listagem→Quebra vira FR+AC; A-005-012/013 novas), **1 escalação E-01** (cadastro de tema pelo EDITOR) que não bloqueia — vai ao Diretor na Entrega com MET-002-001. SPEC promovida a **Approved** (v0.2). RDR-001 resolvido.
- 2026-09-01: **PLAN-006 criado via /keelson:plan** (cobre 100% da SPEC-005) — 15 COMPs (10 backend + 5 frontend), 9 DECs (todas reversíveis: soft-delete, fonte embutida, Quebra 1:1 como model, rotas `/contents`, rede de paridade cross-repo estendida, segmento `(interno)/content`, `Paginated<T>` consolidado, `onDelete` Restrict/Cascade, não adicionar mapa de prioridade em F2), 4 TRISKs. plan-validator PASS (0 ERROR após 1 volta de forma — enum `Irreversível`, campos de lista, `Realiza:` dos COMPs; `plan-dec-alternativa-unica` WARNING calibrado). graph.sh 0 achado sobre PLAN-006. Status → **Approved**.
- 2026-09-05: **Wave 2 de PLAN-006 fechada** (TASK-006-004 espelho de tipos cross-repo, TASK-006-005 seed Obrigação Tributária + EDITOR dev, TASK-006-006 `contents.service`/`contents.schema` ciclo de vida) — paralela. gates 1-7 e 8 REPROVARAM 1ª passe: `.env.example` com `SEED_EDITOR_*=` vazio derrubava o boot inteiro (fail-fast do env); `contents.schema.ts` reimplementava os 2 enums de domínio (fora da rede de paridade de T007); AC-005-027(iv) sem prova falsificável de que a semente substitui o legado; `seedDevEditor` sem prova de hash; `removeLegacyDisciplines` sem guarda de ambiente; `sourceUrl` sem allowlist de esquema; race condition check-then-act em update/softDelete → retry consolidado (8 itens, commits `bf21d2c`/`f4fa5b7`) fechou tudo com mutantes discriminantes reais (não só número batendo); re-review delta APROVADO nos 3 gates (1-7, 8, 10). Fechamento contável "4 métodos, 4 provas" de `contents.service` confirmado com o código na mão. `npm audit` pós-incidente de recuperação (`npm ci`) revelou 3 vulnerabilidades (2 moderate, 1 high) nas deps do backend — não introduzidas por este diff; risco registrado abaixo p/ `/keelson:audit` na Entrega. 3 lições [Segurança]/[Código] confirmadas/registradas em `guidelines/project/lessons.md`; 1 lição [processo] (junção NTFS corrompendo node_modules durante mutação isolada) roteada ao `agile-coach`.
- 2026-09-04: **Wave 1 de PLAN-006 fechada** (TASK-006-001 migração schema, TASK-006-002 `Paginated<T>`+`/disciplines` com temas, TASK-006-003 segmento de rota `content`) — sequencial (migração). Migração aditiva **executada** com autorização do Diretor confirmada na largada do implement (`AskUserQuestion`; ledger `intervencao` 2026-09-01T13:27:23Z, anterior à aplicação). gates 1–7 REPROVOU 1ª passe (achado de escopo já autorizado — resolvido por documentação, não por retry do Diretor — + 3 achados baratos: `zz-.*` faltando no runner unit, teste sobre-prometendo 2ª cláusula do deny-by-default, probe duplicado) → retry `827e36e`/`db9d60a` fechou os 4 + 2 remoções Art.7; re-review delta APROVADO; carona `ed12238` ajustou título de teste. gate 8 APROVADO (2 achados MEDIA não-bloqueantes: regex de exclusão de teste não ancorada, `topics` sem `take`); gate 10 APROVADO (round-trips medidos e fixados, `join` escolhido). 2 lições [projeto] confirmadas (lint-staged/LF estendida com distinção ` M`/`MM`); 2 lições [processo] roteadas ao `agile-coach`. TRISK-006-001 fechado.
- 2026-09-01: sync Jira (gancho tasks — PLAN-006, 14 TASKs) — 14 sub-tasks criadas sob as Stories de FEAT (KAN-29..KAN-42): KAN-27 recebe 001/002/003/004/005/006/007/008/010/011/012/013 (KAN-29..36, 38..41), KAN-28 recebe 009/014 (KAN-37, KAN-42); hierarquia Epic(1)▸História(0)▸Subtask(-1) validada. 6 links "relates to" com KAN-28 para as TASKs de FEAT secundária/transversal (KAN-29/36/38/39/40/41). Keys gravadas no campo `**Jira**:` da closure de cada TASK. `transition: comment` → nenhum card movido. TASKs sem `**Funcionalidade**` (003/004/005/007, FRs nenhuma) → empate resolvido pelo menor ID → FEAT-005-001/KAN-27.
