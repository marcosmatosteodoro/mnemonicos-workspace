# BRIEF-002: Acesso interno e papéis de produção

**Slug**: producao-material
**Status**: Emitido
**Data**: 2026-08-28
**Largada**: 2026-08-28T10:10:08-0300
**SPEC**: SPEC-002
**Epico**: docs/producao-material/briefs/BRIEF-2026-08-27-mnemora-studio-epic.md

## Pedido como dito

Fatia 1 da fila do BRIEF épico MNEMORA STUDIO (decomposição do `pm` confirmada pelo
Diretor em 2026-08-27):

> | 1 | Acesso interno e papéis de produção | producao-material | pendente |

Dependências: `F1 → nenhuma`. É a primeira fatia do épico.

Risco declarado da fatia (BRIEF épico, seção "Riscos por fatia"), verbatim:

> **F1**: sem authz server-side (deny-by-default), o gate de F9 é decorativo; rotas de
> login novas exigem rate limit/expiração/rotação de sessão (A07); reinterpreta A-005 —
> `User`/auth acordam para o time interno, mas `CardState`/`Review`/scheduler/papel
> STUDENT continuam dormentes.

Pergunta ao Diretor respondida na decomposição (BRIEF épico), verbatim:

> 1. F1 entra em primeiro e reinterpreta A-005 (só `User`/auth acordam; `CardState`,
>    `Review`, scheduler e papel STUDENT seguem dormentes) — **confirmado**.

Contexto herdado do BRIEF-001 (pedido épico verbatim): a ferramenta interna de produção
existe "do lado de dentro" — é a fábrica que emite o PDF, e o **estudante concursando não
é usuário deste software** (anti-persona). O gate de "versão aprovada" (F9) pressupõe
papéis internos e autorização server-side, que não existem hoje.

## Interpretação do PO

**Contexto.** O backend tem `User` com `passwordHash` Argon2id no schema e `JWT_SECRET`
validado no boot (`schema.prisma:44-61`, `env.ts:32-33`), mas **nenhuma rota** de
login/registro os liga — só `health`, `health/db` e `disciplines` estão montadas
(`routes.ts:9-10`). O frontend já assume sessão por cookie httpOnly
(`store/api.ts` — `credentials: 'include'`, "nada de token em localStorage"). `USER_ROLES`
existe só no backend (`domain/types.ts:24-26`); o frontend não tem o tipo espelho.

**Pedido.** Ligar o acesso da equipe interna da fábrica: autenticação (login/logout,
sessão), **autorização server-side deny-by-default** por papel, e gestão de contas
internas restrita a ADMIN. É o pré-requisito do gate de aprovação editorial (F9) e da
regra "revisor ≠ autor" (A-010), que precisa de 2+ pessoas com conta.

**Premissas decididas** (Diretor, última chamada de 2026-08-28):
- **Escopo da fatia** = autenticação + middleware de autorização deny-by-default + papéis
  + **endpoints de gestão de usuários restritos a ADMIN** (criar, listar, desativar,
  resetar senha). **Sem auto-registro.** O seed cria o primeiro ADMIN.
- **Papéis** = mantém o enum atual `STUDENT` / `EDITOR` / `ADMIN`. STUDENT segue
  dormente (A-005). EDITOR = produção/autoria; ADMIN = gestão de contas + revisão
  jurídica + aprovação de versão (acumula, até F9 decidir se separa). **Sem migração de
  enum.** Consequência aceita: A-010 (revisor ≠ autor) se cumpre com **dois ADMINs**
  distintos no piloto — risco registrado abaixo.
- **Sessão** = access token JWT curto (`JWT_EXPIRES_IN=15m`) em cookie httpOnly +
  **refresh token com rotação**, persistido em **tabela nova revogável**. Logout e
  "desativar usuário" invalidam a sessão de verdade (revogação server-side). Atende ao
  A07 do risco da fatia.
- **Migração** = o ciclo roda `prisma migrate dev` contra o Postgres do docker-compose
  **local** durante o implement; o arquivo versionado entra no diff da TASK para revisão
  do Diretor. `migrate deploy` em produção e o merge continuam atos do Diretor.

## Fora de escopo

- Qualquer superfície voltada ao **estudante** (anti-persona): login de estudante,
  vitrine pública, `CardState` por usuário, scheduler SM-2, `study-slice`, papel STUDENT
  ativo — seguem dormentes com o motivo já registrado (A-005).
- Auto-registro / cadastro aberto e fluxo de convite por e-mail.
- Separar papel de revisor jurídico do de ADMIN — é decisão de F9 (Controle de
  qualidade e gate de versão aprovada).
- As rotas fantasma `/mnemonics` e `/flashcards/due` que o frontend já chama
  (`store/api.ts:28-35`) — são de F2, não desta fatia.
- Telas de administração no frontend além do mínimo para exercitar login e o guard de
  rota; a UI de gestão de equipe completa pode vir em fatia posterior.
- 2FA / SSO / recuperação de senha por e-mail — reset de senha nesta fatia é ação de
  ADMIN sobre a conta, não fluxo self-service.

## Cronologia

- Largada (Etapa 0.5): 2026-08-28T10:10:08-0300
- Etapa 1 (SPEC-002 `Approved`): 2026-08-28T10:41:00-0300
- Etapa 2 (PLAN-003 `Approved`): 2026-08-28T11:06:00-0300
- Etapa 3 + 3.5 (15 TASKs / 7 waves; verificabilidade pré-código): 2026-08-28T11:40:00-0300
