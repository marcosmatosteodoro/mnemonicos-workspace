# BRIEF-007: Fechar o gap de CSRF em `POST /auth/refresh` e generalizar a prova estrutural

**Slug**: producao-material
**Tipo**: avulso
**Status**: Aberto
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

## Interpretação

`POST /auth/refresh` (COMP-003-010, F1/PLAN-003, já mergeado e em produção) não tem
`verifyOrigin` como 1º handler — a asserção estrutural repo-wide de CSRF filtra por
`NON_PUBLIC` (recorte de autorização) e as 2 rotas POST públicas (`/auth/login`,
`/auth/refresh`) ficam fora do escopo da prova. `/auth/login` tem teste comportamental
próprio; `/auth/refresh` não tem nenhum. Correção: (1) adicionar `verifyOrigin` como 1º
handler de `POST /auth/refresh`; (2) generalizar a asserção estrutural para particionar por
MÉTODO (muta estado?) em vez de por público/não-público, fechando a classe inteira — não só
esta rota — para qualquer rota futura que mude estado sem exigir sessão.

## Critério de aceite

- `mnemonicos-backend/src/modules/auth/auth.routes.ts` — `POST /auth/refresh` monta
  `verifyOrigin` como 1º handler (mesmo padrão de `POST /auth/login`, `POST /contents`, etc.).
- `route-authz-matrix.integration.test.ts` — a asserção estrutural de CSRF (bloco
  "EMENDA DEC-003-004 — verifyOrigin por POSIÇÃO...") passa a ter como base de população
  **todas as rotas montadas** (`ROUTES`, não `NON_PUBLIC`) para o caso de mutação: toda rota
  POST/PATCH/PUT/DELETE tem `handlers[0] === verifyOrigin`, pública ou não. O caso de leitura
  (GETs sem `verifyOrigin`) continua como está.
- Mutante que remove `verifyOrigin` de `POST /auth/refresh` **morre** no comando do critério
  (suíte inteira, nunca `-t` isolado) — confirmado ao vivo, revertido, `git status --porcelain`
  limpo.
- `POST /auth/login` continua coberto (já tinha prova própria — não pode regredir).
- Suíte completa do backend verde (unit + integração), lint/typecheck limpos, sem regressão
  em nenhuma das 19+ rotas do tripwire.
- Comportamento observável: uma requisição de `POST /auth/refresh` com `Origin`/`Referer`
  de terceiro passa a receber 403 (mesmo padrão de `/auth/login`) em vez de processar a
  renovação — sem quebrar o fluxo legítimo (mesma origem).

## TASKs

nenhuma — o brief é a unidade de execução (1 executor, diff concentrado em 2 arquivos:
`auth.routes.ts` + `route-authz-matrix.integration.test.ts`).

## Execução

- **Implementado por**: developer
- **Revisado por**: code-reviewer (gates 1-7) · security-engineer (gate 8 — fatia sensível,
  autenticação/CSRF)
- **Commit**: pendente — commit é ato do Diretor no modo sob demanda (decisão 4.91), mas esta
  mudança nasce dentro de uma sessão em `/keelson:auto` já autorizada a commitar por TASK; o
  Tech Lead commita como as demais correções desta sessão, seguindo a mesma prática já em uso.
