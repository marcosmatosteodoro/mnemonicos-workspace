# MAP — producao-material

> Espelho do território de código deste slug (contrato: map-contract.md do keelson).
> Acelerador de exploração — régua 4.58: confira a âncora antes de decidir por ela.
> Checagem mecânica: scripts/map-check.sh (idade e âncoras; WARNING nunca bloqueia).

## Acervo (modelo de dados)

- [2026-08-27 · epico] `Mnemonic.hook`/`Mnemonic.decoding` são campos de texto único — a tira mnemônica como sequência ordenada de quadros não tem representação estrutural ainda; F4 substitui, não estende — mnemonicos-backend/prisma/schema.prisma:96-120
- [2026-08-27 · epico] Não existe modelo para radar de prova/priorização, contraste, pegadinha nem associação visual/imagem no schema atual — 4 das 10 camadas do método sem cobertura, nenhuma na forma que a TAP pede — mnemonicos-backend/prisma/schema.prisma:1-189
- [2026-09-06 · PLAN-006] **Corrige entrada acima**: seed trocado para Direito Tributário/Obrigação Tributária + EDITOR de dev (`seedMaterial`, `authorId` = ADMIN; distinto do `authorId` do EDITOR que a tela produz) — mnemonicos-backend/prisma/seed-material.ts:126-168
- [2026-09-06 · PLAN-006] `RawContent` (texto normativo + disciplina/tema + `radarClass`, soft-delete via `deletedAt`) e `RuleBreakdown` 1:1 (5 blocos + síntese, sem `deletedAt` própria — herda inalcançabilidade do pai) são o modelo novo da fábrica de F2 — mnemonicos-backend/prisma/schema.prisma:263-331
- [2026-09-06 · PLAN-006] Filtro `deletedAt: null` centralizado em `contents.service.ts` (não redeclarado por chamador) — todo caminho de leitura novo (listagem/detalhe/Quebra/censo) herda daqui, não reimplementa — mnemonicos-backend/src/modules/contents/contents.service.ts:1-408

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
- [2026-09-06 · PLAN-006] `contentsRoutes` acrescenta 7 rotas sob a mesma barreira (`requireRole('EDITOR','ADMIN')`), tripwire de `route-authz-matrix` atualizado de 12 para 19 pares — mnemonicos-backend/src/modules/contents/contents.routes.ts:1-144
- [2026-09-06 · PLAN-006] Rede de paridade cross-repo cobre DECLARAÇÃO×DECLARAÇÃO (enums + interfaces), não `select`×declaração — chave nova só no `select` do Prisma sem a mesma chave no frontend passa pelo typecheck e pelos 2 testes (RISK-006-006, gap conhecido, não fechado nesta fatia) — mnemonicos-backend/tests/unit/contents-frontend-contract.test.ts:1-40
- [2026-08-27 · epico] Frontend já chama `/mnemonics` e `/flashcards/due`, que não existem no backend — contrato adiantado, quebra em runtime sem o typecheck acusar; F2 precisa fechar isso primeiro — mnemonicos-frontend/src/store/api.ts:28-35
- [2026-08-27 · epico] Tipos de domínio do frontend não têm `CardState`/`Review` — espelho do `USER_ROLES` ausente do lado do backend — mnemonicos-frontend/src/types/domain.ts:41-83

## Produção de conteúdo bruto e Quebra da regra (F2 · PLAN-006)

- [2026-09-06 · PLAN-006] Telas `(interno)/content` (listagem), `/content/new` (formulário) e `/content/[id]/breakdown` (Quebra da regra) — Server Component default, `'use client'` só onde há estado/evento — mnemonicos-frontend/src/app/(interno)/content/page.tsx:1-40
- [2026-09-06 · PLAN-006] Tokens de cor semântica `--link`/`--danger` (light/dark em `:root`/`@media (prefers-color-scheme: dark)`, expostos via `@utility text-link`/`@utility text-danger`) — padrão canônico do produto para texto de erro/sucesso/link, substitui literal de paleta Tailwind (`text-brand-500`/`text-red-500`, que falhava contraste AA num dos 2 temas) — mnemonicos-frontend/src/app/globals.css:31-78

## Instrumentação de etapas de produção (F3 · PLAN-010)

- [2026-09-06 · PLAN-010] `ProductionStageEvent` (append-only real — só `create`/`findMany`
  em todo o código escrito; sem `updatedAt`/`deletedAt`, a imutabilidade é ausência de
  caminho de update/delete, não campo de estado) + enums `ProductionStageType`
  (`CONTEUDO_BRUTO`, `QUEBRA_DA_REGRA` — extensível, F4-F9 acrescentam valor por migração
  aditiva) e `ProductionEventTransition` (`ABERTURA`/`CONCLUSAO`/`RETRABALHO`) — primeira
  tabela append-only real do projeto (antes greenfield) e primeira sequência monotônica
  (`sequence BigInt @default(autoincrement())`, desempata `occurredAt` idêntico) —
  mnemonicos-backend/prisma/schema.prisma:352-388.
- [2026-09-06 · PLAN-010] `production-events.service.ts` — módulo sem `.schema.ts` nem
  `.routes.ts` (nunca chamado por rota, só por outro `.service.ts`): `decideStageTransition`
  (regra pura, decide por histórico lido dentro da mesma tx — nenhum chamador sabe se é
  abertura/conclusão/retrabalho), `recordProductionStageEvent` (emissão, recebe o `tx` do
  chamador, nunca abre transação própria), `listProductionStageEvents` (leitura interna,
  sem rota) — mnemonicos-backend/src/modules/production-events/production-events.service.ts:1-105.
- [2026-09-06 · PLAN-010] `contents.service.ts` ganhou `prisma.$transaction` em
  `createRawContent`/`updateRawContent`/`saveRuleBreakdown` (antes 1 statement cada) —
  chama `recordProductionStageEvent` dentro do mesmo `tx`, fail-secure (falha na emissão
  reverte a mutação de negócio inteira). `softDeleteRawContent` não muda (nenhuma emissão
  na remoção) — mnemonicos-backend/src/modules/contents/contents.service.ts:78-490.
- [2026-09-06 · PLAN-010] Serialização do "1º salvamento" concorrente de
  `RuleBreakdown` (nunca 2 `CONCLUSAO` para o mesmo par) depende de propriedade EMERGENTE
  do lock de índice único de `RuleBreakdown.rawContentId` (de F2) — não de mecanismo desta
  fatia; provado por mutation testing (mutante que reordena emissão antes do upsert mata o
  teste de concorrência). Garantia é por-chamador: um 3º consumidor futuro (F4-F9) que
  emita antes de escrever sua própria linha reintroduz o risco — considerar índice único
  parcial `(rawContentId, stageType) WHERE transitionType='CONCLUSAO'` se isso acontecer.
- [2026-09-06 · PLAN-010] `tests/support/production-events-fixtures.ts` — primeiro helper
  de fixture compartilhado do projeto (perfil §7); `createUser`/`createTopic`/
  `createRawContent` usados pelos 2 arquivos de teste de `production-events`. Ainda
  convivem 6 cópias locais equivalentes em outros arquivos de teste (`auth.routes`,
  `auth.service`, `contents`, `contents.service`, `disciplines`, `users`) — consolidação
  pendente, fora do escopo desta fatia.

## Publicação (ausente)

- [2026-08-27 · epico] Nenhuma geração ou exportação de PDF existe nos dois repos — nem dependência, nem rota, nem script; F6 é greenfield total nesta área — busca em ambos os repos não retornou nada
- [2026-08-27 · epico] Nenhum versionamento editorial existe — sem data de fechamento de legislação, sem histórico de revisão, sem fonte normativa estruturada (só `source` como texto livre em `Mnemonic`) — mnemonicos-backend/prisma/schema.prisma:96-120

## Tamanho do código (linha de base do épico)

- [2026-08-27 · epico] 13 arquivos de produção + 3 de teste no backend, 12 + 2 no frontend, uma única página (`/`), nenhuma tela de estudo; `study-slice` existe e não é consumido por ninguém — contagem via ferramentas de busca, sem arquivo único âncora
