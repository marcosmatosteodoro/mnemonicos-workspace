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

## Revisão espaçada (dormente por A-005)

- [2026-08-27 · epico] Scheduler é variante SM-2 com ease factor dinâmico e teto de 365 dias — incompatível por design com os 6 marcos fixos R0/R24/R3/R7/R14/R30 que a TAP pede (F7 não reusa, imprime como protocolo) — mnemonicos-backend/src/modules/review/scheduler.ts:43-93
- [2026-08-27 · epico] Comportamento do scheduler é provado em teste unitário — mnemonicos-backend/tests/unit/scheduler.test.ts:40-58

## Rotas e contrato de API

- [2026-08-27 · epico] Rotas montadas hoje: só `health`, `health/db` e `disciplines` — F1/F2 partem de uma superfície quase vazia — mnemonicos-backend/src/http/routes.ts:9-10
- [2026-08-27 · epico] Frontend já chama `/mnemonics` e `/flashcards/due`, que não existem no backend — contrato adiantado, quebra em runtime sem o typecheck acusar; F2 precisa fechar isso primeiro — mnemonicos-frontend/src/store/api.ts:28-35
- [2026-08-27 · epico] Tipos de domínio do frontend não têm `CardState`/`Review` — espelho do `USER_ROLES` ausente do lado do backend — mnemonicos-frontend/src/types/domain.ts:41-83

## Publicação (ausente)

- [2026-08-27 · epico] Nenhuma geração ou exportação de PDF existe nos dois repos — nem dependência, nem rota, nem script; F6 é greenfield total nesta área — busca em ambos os repos não retornou nada
- [2026-08-27 · epico] Nenhum versionamento editorial existe — sem data de fechamento de legislação, sem histórico de revisão, sem fonte normativa estruturada (só `source` como texto livre em `Mnemonic`) — mnemonicos-backend/prisma/schema.prisma:96-120

## Tamanho do código (linha de base do épico)

- [2026-08-27 · epico] 13 arquivos de produção + 3 de teste no backend, 12 + 2 no frontend, uma única página (`/`), nenhuma tela de estudo; `study-slice` existe e não é consumido por ninguém — contagem via ferramentas de busca, sem arquivo único âncora
