# MAP — producao-material

> Espelho do território de código deste slug (contrato: map-contract.md do keelson).
> Acelerador de exploração — régua 4.58: confira a âncora antes de decidir por ela.
> Checagem mecânica: scripts/map-check.sh (idade e âncoras; WARNING nunca bloqueia).

## Acervo (modelo de dados)

- [2026-08-27 · epico] `Mnemonic.hook`/`Mnemonic.decoding` são campos de texto único — a tira mnemônica como sequência ordenada de quadros não tem representação estrutural ainda; F4 substitui, não estende — mnemonicos-backend/prisma/schema.prisma:96-120
- [2026-08-27 · epico] Não existe modelo para radar de prova/priorização, contraste, pegadinha nem associação visual/imagem no schema atual — 4 das 10 camadas do método sem cobertura, nenhuma na forma que a TAP pede — mnemonicos-backend/prisma/schema.prisma:1-189
- [2026-08-27 · epico] Seed carrega Direito Administrativo e Constitucional, não Direito Tributário (A-003 exige trocar para Obrigação Tributária em F2) — mnemonicos-backend/prisma/seed.ts:28-101

## Identidade e autorização

- [2026-08-27 · epico] `User` com `passwordHash` Argon2id e `JWT_SECRET` validado no boot já existem no schema/config, mas nenhuma rota de login/registro os usa — F1 é quem primeiro os liga — mnemonicos-backend/prisma/schema.prisma:44-61
- [2026-08-27 · epico] `JWT_SECRET` é validado no boot em env.ts — mnemonicos-backend/src/config/env.ts:32-33
- [2026-08-27 · epico] `USER_ROLES` existe só no backend; frontend não tem os tipos correspondentes — fonte de dessincronia entre repos que F1/F2 precisam fechar — mnemonicos-backend/src/domain/types.ts:24-26
- [2026-08-31 · F1] Sessão completa (branch `feat/producao-material-mnemora-studio`, aguarda merge): tabela `Session` só com hashes, `familyId` agrupa a rotação, `revokedAt`; `auth.service.ts` faz login/refresh/rotação/reuso→revogação da família/logout/`getSessionUser`/`changeOwnPassword`; rotação é função pura recebendo `now` — mnemonicos-backend/src/modules/auth/auth.service.ts:1-200
- [2026-08-31 · F1] Rotação de sessão como lógica pura sem I/O, `now` por parâmetro — mnemonicos-backend/src/modules/auth/session-rotation.ts:1-90
- [2026-08-31 · F1] Barreira deny-by-default: `ROUTE_ROLES` indexado por `"<MÉTODO> <caminho>"` em `route-roles.ts`; `requireRole(method,path,...roles)` declara na montagem, `sealRouteRoles()` sela pós-boot, `requireAuth` é o piso (nega sessão indefinida OU papel fora do conjunto) — mnemonicos-backend/src/http/middlewares/authenticate.ts:1-120
- [2026-08-31 · F1] `assertDenyByDefault(apiRoutes)` no escopo do módulo derruba o boot em topologia adversarial; `PUBLIC_PATH_ALLOWLIST` são pares método+caminho (`isPublicPath` por igualdade exata) — mnemonicos-backend/src/http/public-paths.ts:1-60
- [2026-08-31 · F1] `route-authz-matrix.integration.test.ts` é a fonte de medição da métrica §1.3 da SPEC-002 (censo de 12 rotas, 28 asserções) — mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts:1-40
- [2026-08-31 · F1] `USER_ROLES`/`UserRole`/`SessionUser` agora espelhados no frontend, mantidos à mão em sincronia com o backend — mnemonicos-frontend/src/types/domain.ts:1-40
- [2026-08-31 · F1] Frontend de sessão: `baseQueryWithReauth` (401 → `POST /auth/refresh` 1× → repete; morta → `resetApiState()` + `/login?sessao=expirada`); `logout.onQueryStarted` reseta o cache só após sucesso — mnemonicos-frontend/src/store/api.ts:1-220
- [2026-08-31 · F1] Guard de navegação: `proxy.ts` `config.matcher` é array literal (o Next lê `config` por AST estático — sem `.flatMap`/spread); a equivalência com `INTERNAL_ROUTE_PREFIXES` vive no teste; `(interno)` é route group, nunca catch-all por exclusão — mnemonicos-frontend/src/proxy.ts:42-52
- [2026-08-31 · F1] `INTERNAL_ROUTE_PREFIXES` / `INTERNAL_MIN_ROLE` / `roleSatisfies` — fonte única do contrato de área interna — mnemonicos-frontend/src/lib/internal-routes.ts:1-40
- [2026-08-31 · F1] Telas mínimas de F1: `/login` (`LoginForm`, 3 estados, `<form method="post">`, gate de hidratação) e `(interno)/` (`InternalShell` resolve `me`, 3 estados de navegação protegida + logout com 3 estados). Apresentação, não fronteira — mnemonicos-frontend/src/components/internal-shell.tsx:1-125

## Revisão espaçada (dormente por A-005)

- [2026-08-27 · epico] Scheduler é variante SM-2 com ease factor dinâmico e teto de 365 dias — incompatível por design com os 6 marcos fixos R0/R24/R3/R7/R14/R30 que a TAP pede (F7 não reusa, imprime como protocolo) — mnemonicos-backend/src/modules/review/scheduler.ts:43-93
- [2026-08-27 · epico] Comportamento do scheduler é provado em teste unitário — mnemonicos-backend/tests/unit/scheduler.test.ts:40-58

## Rotas e contrato de API

- [2026-08-27 · epico] Rotas montadas hoje: só `health`, `health/db` e `disciplines` — F1/F2 partem de uma superfície quase vazia — mnemonicos-backend/src/http/routes.ts:9-10
- [2026-08-31 · F1] `apiRoutes` monta em ordem: `healthRoutes` (público) → auth pública (`POST /auth/login`, `/auth/refresh`) → `requireAuth` → auth protegida (`/auth/logout`, `/auth/me`, `/auth/change-password`) → `usersRoutes` (`requireRole('ADMIN')`) → `disciplinesRoutes` (`requireRole('EDITOR','ADMIN')`); `verifyOrigin` em toda mutação autenticada por cookie — mnemonicos-backend/src/http/routes.ts:1-60
- [2026-08-27 · epico] Frontend já chama `/mnemonics` e `/flashcards/due`, que não existem no backend — contrato adiantado, quebra em runtime sem o typecheck acusar; F2 precisa fechar isso primeiro — mnemonicos-frontend/src/store/api.ts:28-35
- [2026-08-27 · epico] Tipos de domínio do frontend não têm `CardState`/`Review` — espelho do `USER_ROLES` ausente do lado do backend — mnemonicos-frontend/src/types/domain.ts:41-83

## Publicação (ausente)

- [2026-08-27 · epico] Nenhuma geração ou exportação de PDF existe nos dois repos — nem dependência, nem rota, nem script; F6 é greenfield total nesta área — busca em ambos os repos não retornou nada
- [2026-08-27 · epico] Nenhum versionamento editorial existe — sem data de fechamento de legislação, sem histórico de revisão, sem fonte normativa estruturada (só `source` como texto livre em `Mnemonic`) — mnemonicos-backend/prisma/schema.prisma:96-120

## Tamanho do código (linha de base do épico)

- [2026-08-27 · epico] 13 arquivos de produção + 3 de teste no backend, 12 + 2 no frontend, uma única página (`/`), nenhuma tela de estudo; `study-slice` existe e não é consumido por ninguém — contagem via ferramentas de busca, sem arquivo único âncora
