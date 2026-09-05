# BRIEF-007: Fechar o gap de CSRF em `POST /auth/refresh` e generalizar a prova estrutural

**Slug**: producao-material
**Tipo**: avulso
**Status**: Concluído
**Data**: 2026-09-05
**Largada**: 2026-09-05T12:41:22-03:00
**Origem**: Diretor (pedido em sessão — AskUserQuestion, escolha "Corrigir agora, fora do ciclo")
**Jira**: KAN-43

## Pedido como dito

O Diretor escolheu "Corrigir agora, fora do ciclo (recomendado)" em resposta à pergunta:
"O re-review da Wave 4 achou uma vulnerabilidade real (não um gap de teste) em código JÁ EM
PRODUÇÃO (F1/PLAN-003, mergeado): `POST /auth/refresh` pode perder `verifyOrigin` sem
nenhuma suíte acusar — é a rota que emite cookies novos a partir do cookie de refresh, alvo
clássico de CSRF. Confirmado com mutante ao vivo (removi `verifyOrigin` dali e as 2 suítes,
208+213 testes, continuaram verdes)."

## Resultado

**A premissa do "Pedido como dito" acima foi REFUTADA pela investigação — registro factual,
não opinião.** `POST /auth/refresh` (COMP-003-010, F1/PLAN-003) **sempre teve**
`verifyOrigin` como 1º handler, desde o commit original (`git log -L 160,161:src/modules/auth/auth.routes.ts`
→ `d2560a9`), idêntico no commit-pai deste brief. **Não houve vulnerabilidade ativa em
produção em nenhum momento.** O que existia era um buraco na REDE DE PROVA: a asserção
estrutural de CSRF filtrava por `NON_PUBLIC` (recorte de autorização), e as 2 rotas POST
públicas (`/auth/login`, `/auth/refresh`) ficavam fora do escopo dela — `/auth/login` tinha
teste comportamental próprio cobrindo o guard por outra via; `/auth/refresh` não tinha
nenhum. Se `verifyOrigin` fosse removido dali por engano num diff futuro, nenhuma suíte
acusaria — esse era o risco real (RISK-006-008, já fechado no INDEX do slug), nunca um
`fix:` de produção.

Diante disso, dos 2 itens do "Critério de aceite" original, o item 1 (adicionar
`verifyOrigin`) já estava satisfeito **antes** do diff — nenhuma linha de `auth.routes.ts`
foi tocada. Só o item 2 (generalizar a asserção estrutural) exigiu trabalho real: 1 arquivo,
3 linhas, `test:` — nunca `fix:`.

## Critério de aceite (estado final provado)

- `mnemonicos-backend/src/modules/auth/auth.routes.ts` — `POST /auth/refresh` monta
  `verifyOrigin` como 1º handler (mesmo padrão de `POST /auth/login`, `POST /contents`,
  etc.) — **já satisfeito antes deste brief**, confirmado por `git log -L`.
- `route-authz-matrix.integration.test.ts` — a asserção estrutural de CSRF (bloco
  "EMENDA DEC-003-004 — verifyOrigin por POSIÇÃO...") tem como base de população **todas as
  rotas montadas** (`ROUTES`, não `NON_PUBLIC`) para o caso de mutação: toda rota
  POST/PATCH/PUT/DELETE tem `handlers[0] === verifyOrigin`, pública ou não. O caso de leitura
  (GETs sem `verifyOrigin`) continua sobre `NON_PUBLIC`. — **item efetivamente implementado
  por este diff (commit `d0d9294`).**
- Mutante que remove `verifyOrigin` de `POST /auth/refresh` **morre** no comando do critério
  (suíte inteira, nunca `-t` isolado) — confirmado ao vivo por 3 partes independentes
  (developer, code-reviewer, security-engineer), revertido, `git status --porcelain` limpo
  em todas as rodadas.
- `POST /auth/login` continua coberto (já tinha prova própria — sem regressão).
- Suíte completa do backend verde (unit 208/208 + integração 213/213), lint/typecheck
  limpos, sem regressão em nenhuma das 19 rotas do tripwire.
- Comportamento observável (estado final, não mudança): uma requisição de `POST
  /auth/refresh` com `Origin`/`Referer` de terceiro recebe 403 (mesmo padrão de
  `/auth/login`); com a mesma origem, segue o fluxo normal de renovação — confirmado ao vivo
  pelo security-engineer.

## TASKs

nenhuma — o brief é a unidade de execução (1 executor, diff concentrado em 2 arquivos:
`auth.routes.ts` + `route-authz-matrix.integration.test.ts`).

## Execução

- **Implementado por**: developer
- **Revisado por**: code-reviewer (gates 1-7 — REPROVADO 1x por rastro durável falso no
  brief/tipo de commit, não por código; re-review APROVADO após reconciliação) ·
  security-engineer (gate 8 — APROVADO direto)
- **Commit**: `test(producao-material): KAN-43 generaliza prova estrutural de CSRF para toda rota mutante montada` (amend do assunto original, ainda não pushado no momento do amend — nenhuma linha de conteúdo alterada, só tipo/escopo/key do Conventional Commit)
