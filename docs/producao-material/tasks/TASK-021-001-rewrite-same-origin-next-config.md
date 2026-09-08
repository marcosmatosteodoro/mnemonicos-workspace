# TASK-021-001: Adicionar rewrite same-origin em `next.config.ts`

**Slug**: producao-material
**Pertence a**: PLAN-021
**Realiza (FRs)**: FR-002-001
**Funcionalidade**: FEAT-002-001 (primária)
**Componente**: COMP-021-001 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-rewrite-same-origin-cookie-sessao` (`git.branchNaming: slug`, `branchStrategy: unica` — uma branch cobre as duas TASKs de PLAN-021, como em `feat/producao-material-pwa-support`).
**Padrão de commit**: Conventional Commits (`commit.convention: conventional`) — ex.: `feat(frontend): PLAN-021 rewrite same-origin em next.config.ts`. PLAN-021 ainda não tem chave Jira própria; a sub-task da Etapa 7 de `/keelson:tasks` (tracker-sync) grava a key no campo `Jira:` da closure — referencie `PLAN-021` até lá.
**Framework de teste**: Jest 30 + Testing Library (`guidelines/project/frontend/next-16.md` §7). Rodada escopada a um caminho usa `--runTestsByPath` (nunca o argumento posicional — regex de `testPathPattern`).

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-021-002

## Contexto

`mnemonicos-frontend` e `mnemonicos-backend` são dois sites Vercel distintos; o cookie `sameSite: 'lax'` (DEC-003-004) nunca persiste em produção porque a chamada de `store/api.ts` ao host absoluto do backend é cross-**site** do ponto de vista do navegador. Esta TASK cria o lado servidor da correção (DEC-021-001/DEC-021-002): um `rewrites()` nativo do Next que mapeia `/api/v1/:path*` para o backend real, sem tocar `headers()` nem qualquer arquivo de `mnemonicos-backend`. A TASK-021-002 (wave seguinte) depende deste rewrite existir antes de apontar o cliente para a própria origem — sem ele, uma chamada same-origin cairia em 404.

## Escopo

### Inclui

- Edição em `mnemonicos-frontend/next.config.ts`: nova constante de módulo `const backendApiUrl = process.env.BACKEND_API_URL ?? 'http://localhost:3333';` (server-only, lida direto de `process.env` — nunca via `src/lib/env.ts`, documentado como só `NEXT_PUBLIC_*`), e novo método `async rewrites()` retornando `[{ source: '/api/v1/:path*', destination: '${backendApiUrl}/api/v1/:path*' }]`. `headers()` existente (CSP-lite) permanece byte-a-byte inalterado.
- Nova env var `BACKEND_API_URL` documentada em `mnemonicos-frontend/.env.example` — comentário explícito: "URL real do backend — server-only, nunca embutida no bundle do browser".
- Nova linha na tabela de variáveis de `mnemonicos-frontend/README.md` (seção "Deploy (Vercel)", linhas 96-99 hoje), ao lado de `NEXT_PUBLIC_API_URL`/`NEXT_PUBLIC_APP_NAME` (a remoção de `NEXT_PUBLIC_API_URL` é da TASK-021-002 — aqui só se acrescenta `BACKEND_API_URL`).
- Teste novo `mnemonicos-frontend/next.config.test.ts`: `jest.isolateModules()` + `require('./next.config')` com `process.env.BACKEND_API_URL` definida (confirma a regra usando o valor configurado) e ausente (confirma o fallback `http://localhost:3333`) — mesmo padrão de "testar o caminho com valor fornecido, não só o default" já usado no perfil backend (`node-22.md` §6.4, exemplar `mnemonicos-backend/tests/unit/env.test.ts:23-30`, que usa exatamente `jest.isolateModules` + `require`), aplicado aqui a uma env var de rede em vez de segurança.

### Não inclui

- Remoção de `NEXT_PUBLIC_API_URL`/`env.apiUrl` (config morta) — TASK-021-002 (COMP-021-003), que só pode remover depois que `store/api.ts` parar de consumi-la.
- Qualquer edição em `mnemonicos-frontend/src/store/api.ts` (`baseUrl` same-origin) — TASK-021-002.
- Qualquer alteração em `mnemonicos-backend` (`CORS_ORIGINS`, `verifyOrigin`) — DEC-021-001 mantém os dois intocados nesta rodada.
- Verificação real de encaminhamento de `Origin`/preservação de múltiplos `Set-Cookie` pelo `rewrites()` sob dois sites `*.vercel.app` distintos — tecnicamente impossível localmente/CI sem staging cross-site (TRISK-021-001/002); fica para a verificação manual pós-deploy do DoD do PLAN (item de gate 9 do PLAN, não desta TASK).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Adicionar `const backendApiUrl = process.env.BACKEND_API_URL ?? 'http://localhost:3333';` no topo de `next.config.ts`, fora do objeto `nextConfig`.
2. Adicionar o método `rewrites()` (assíncrono, devolvendo a regra `/api/v1/:path*` → `${backendApiUrl}/api/v1/:path*`) ao objeto `nextConfig`, ao lado (não dentro) de `headers()`.
3. Escrever `next.config.test.ts`: `jest.isolateModules(() => { mod = require('./next.config'); })` com `process.env.BACKEND_API_URL` setada, chamar `mod.default.rewrites()` e conferir o array retornado; repetir com `delete process.env.BACKEND_API_URL` e conferir o fallback de dev local.
4. Documentar `BACKEND_API_URL` em `.env.example` e na tabela do README.

## Critérios de pronto

- [ ] `rewrites()` em `mnemonicos-frontend/next.config.ts` retorna exatamente a regra `{ source: '/api/v1/:path*', destination: '${backendApiUrl}/api/v1/:path*' }`, tanto com `BACKEND_API_URL` configurada (usa o valor) quanto ausente (cai no fallback `http://localhost:3333`); `headers()` existente permanece com o mesmo conteúdo de hoje (`git diff main...HEAD -- mnemonicos-frontend/next.config.ts` mostra só adição, nenhuma linha de `headers()` removida/alterada).
- [ ] Testes cobrem AC-002-001 (parte — a faceta de topologia de rede/rewrite; a faceta de emissão da sessão em si já está provada em PLAN-003) e NFR-002-008 (parte — a faceta "trafega através de rede same-origin", não as flags do cookie, que não mudam) — verificação executável: `cd mnemonicos-frontend && npx jest --runTestsByPath next.config.test.ts` → `Tests: 2 passed, 2 total` (1 caso com `BACKEND_API_URL` definida, 1 caso com a variável ausente), fixada antes do código. Arquivo-alvo ainda não existe nesta base (confirmado por leitura direta em 2026-09-08); molde de técnica de teste (env var com/sem valor, não só o default, mesmo mecanismo `jest.isolateModules`+`require`): `mnemonicos-backend/tests/unit/env.test.ts:23-30`.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only main...HEAD`) — `cd mnemonicos-frontend && npm run lint` → exit 0, sem novo warning nos arquivos tocados (`next.config.ts`, `next.config.test.ts`, `.env.example`, `README.md`).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem: `BACKEND_API_URL` é lida direto de `process.env` em `next.config.ts`, nunca via `src/lib/env.ts` — confirmado por `git diff main...HEAD -- mnemonicos-frontend/src/lib/env.ts` vazio nesta TASK (a edição desse arquivo é da TASK-021-002).
- [ ] Code review aprovado.

## Riscos específicos

- **Superfície sensível (gates.security: true)**: o `rewrite` é o ponto por onde o cookie de sessão (`Set-Cookie` de `mnemo_access`/`mnemo_refresh`) e o header `Origin` passam a trafegar entre o browser e o backend real. Mesmo sendo uma mudança pequena de configuração de rede, pede revisão de segurança focada (gate 8) — "só config" não dispensa a checagem de que nenhum caminho de rede novo se abre além do mapeado. Ver TRISK-021-001/002 do PLAN (resíduo de verificação, fora do alcance desta TASK).
- **TRISK-021-003**: `BACKEND_API_URL` ausente no ambiente de produção cai no fallback de dev local (`http://localhost:3333`) — toda chamada de API em produção falharia de forma visível (erro de rede/timeout), nunca silenciosamente. Confirmar a env var no painel Vercel é item do checklist de deploy do Diretor (DoD do PLAN), fora do escopo desta TASK.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-08T13:58:49-0300
**Data conclusão**: 2026-09-08T14:17:54-0300
**Branch**: feat/producao-material-rewrite-same-origin-cookie-sessao
**Commit SHA**: cc3b9f6
**Jira**: KAN-83
**Implementado por**: developer
**Revisado por**: code-reviewer, security-engineer
**Tentativas**: 2 (1 retry — achado bloqueante do gate 1-7, `as` apagando `| undefined` inferido em `next.config.test.ts:9`; corrigido com guard clause no molde de `src/lib/sw-loader.ts:139-147`, delta re-aprovado)
**Cobertura final**: n/a (sem instrumento de cobertura na ficha)
**Arquivos modificados**:
  - mnemonicos-frontend/next.config.ts
  - mnemonicos-frontend/next.config.test.ts
  - mnemonicos-frontend/.env.example
  - mnemonicos-frontend/README.md

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (32 suites/360 testes verdes, 2 novos)
- [x] Lint limpo (0 warnings; `tsc --noEmit` limpo)
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (gate 1-7, delta cc3b9f6 sobre fcfaf92)
- [x] ACs verificados (AC-002-001 parte — topologia/rewrite; NFR-002-008 parte — trafega same-origin)
- [x] Segurança (gate 8): aprovado (Wave 1) — security-engineer, 0 achados; 2 notas não-bloqueantes para o checklist de deploy (header em resposta de rewrite; validação de esquema/TLS de `BACKEND_API_URL`)
- [x] Comportamento (gate 9): n/a — resíduo de verificação manual pós-deploy (TRISK-021-001/002), item de DoD do PLAN (Etapa 4), não roteiro de TASK: comportamento cross-site sob dois sites `*.vercel.app` reais é tecnicamente irreproduzível localmente (TASK-021-INDEX.md, nota de cobertura). Faceta local (AC-002-001 topologia/rewrite) coberta por gate 1.

**Notas**: `headers()` (CSP-lite) permanece byte-a-byte inalterado, confirmado por diff+md5. Achado fora de escopo do code-reviewer (não desta TASK): `next.config.ts`/`headers()` nunca teve teste próprio no repo — sinal registrado no Histórico do INDEX. Lição nova registrada em `guidelines/project/lessons.md` (`[Testes] Valor capturado dentro de callback...`) e anti-pattern equivalente adicionado a `guidelines/project/frontend/next-16.md` §1.
