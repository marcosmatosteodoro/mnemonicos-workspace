# BRIEF-014: Login não redireciona para `next` após autenticar

**Slug**: producao-material
**Tipo**: avulso
**Status**: Concluído
**Data**: 2026-09-07
**Largada**: 2026-09-07T10:21:37-0300
**Origem**: key do tracker (rota pull, KAN-75)
**Jira**: KAN-75

## Pedido como dito
[BUG] Login não redireciona para a rota de destino após autenticar (fica em
/login?next=...). Ambiente: produção (Vercel).

Passos: (1) acessar uma rota protegida sem estar autenticado (ex.: `/studio`); (2) o
sistema redireciona para `/login?next=%2Fstudio`; (3) informar credenciais válidas e
submeter o login.

Resultado atual: a URL permanece em `/login?next=%2Fstudio`. Resultado esperado: após
autenticação bem-sucedida, o usuário é redirecionado para a rota indicada em `next`.

## Interpretação
Causa raiz identificada em `mnemonicos-frontend`: `proxy.ts` já monta
`/login?next=<path>` corretamente, mas `src/app/login/page.tsx` nunca lê o parâmetro
`next` de `searchParams`, e `LoginForm` (`login-form.tsx:43`) sempre chama
`router.push(INTERNAL_HOME)` no sucesso, ignorando qualquer destino pedido. Diverge do
próprio desenho do mecanismo (o `next=` existe para ser consumido) e do item V3 do
`HANDOFF-PLAN-003.md`, que já previa esta verificação — nunca provada em navegador real
por falta de credencial. SPEC-002/PLAN-003 (Autenticação de sessão) seguem corretos;
isto é um bugfix, não mudança de contrato.

**Achado de segurança na rodada 1 do gate 8 (autorizou tocar `proxy.ts`, ver "Fora de
escopo" abaixo)**: `isSafeRelativePath` validava a FORMA da string, mas o consumo real
(`router.push`) resolve com o parser WHATWG de URL, que remove `%09`/`%0A`/`%0D` antes
de interpretar — `next=%2F%0A%2Fevil.com` decodifica `/\n/evil.com`, passava no guard
textual, e resolvia para `https://evil.com/`. Reescrita para validação-por-resolução
(`new URL` contra base sentinela + comparação de origin) + allowlist por
`INTERNAL_ROUTE_PREFIXES`, com o path normalizado devolvido em vez do candidato cru.
Retry #1 do gate 8 achou uma segunda vulnerabilidade na própria correção (o retorno
podia começar com `//`, protocolo-relativo) — fechada no retry #2, reconstruindo o
retorno a partir dos segmentos normalizados (nunca repassando `url.pathname` cru).

**Severidade**: 🟠 Significativo — reproduzível a 100% no subfluxo (qualquer usuário que
chegue a rota protegida sem sessão e depois autentique), sem dado em risco.
**Impacto**: todo usuário que acessa rota interna sem sessão ativa e depois faz login.
**Como reproduzir**: acessar `/studio` deslogado → `/login?next=%2Fstudio` → logar com
credencial válida → esperado `/studio`, observado permanece em `/login?next=...`.
**Desde**: relato do Diretor em 2026-09-07 (Jira KAN-75, criado 2026-09-07T09:42-0300).
**Evidência**: descrição do card KAN-75.

## Premissas decididas
- `page.tsx` lê e valida `next` de `searchParams` reaproveitando a mesma régua de
  caminho relativo seguro já usada em `proxy.ts` (`isSafeRelativePath`) — nunca
  confiar em `next` sem validar (guard de open-redirect, §6.6 do perfil).
- `next` inválido/ausente cai no fallback atual: `INTERNAL_HOME`.

## Fora de escopo
- Mudança em `proxy.ts` **não motivada por achado de gate 8** (fora disso, o mecanismo
  de sessão/cookies não muda). `isSafeRelativePath` foi reescrita dentro deste brief —
  ver "Achado de segurança" na Interpretação — porque o gate 8 provou que o guard
  textual original tinha um bypass real, não por preferência de estilo.
- Extrair `isSafeRelativePath` para módulo compartilhado (`src/lib/`) é decisão à
  parte, fora deste bugfix (reúso pode ser sugestão do gate 7, não bloqueia).

## Critério de aceite
- Dado um usuário não autenticado acessando uma rota protegida, quando ele é
  redirecionado para `/login` com o parâmetro `next`, e informa credenciais válidas,
  então é redirecionado para a rota indicada em `next` (cobre AC-002-009 / o item V3 do
  HANDOFF-PLAN-003.md).
- Dado um `next` inseguro (`//evil.com`, `https://evil.com`, `/\evil.com`) ou ausente,
  quando o login é bem-sucedido, então o usuário é redirecionado para `INTERNAL_HOME`,
  nunca para o valor não-confiável.

## TASKs
<nenhuma — o brief é a unidade de execução>

## Execução
- **Implementado por**: developer
- **Revisado por**: (registro não encontrado neste ledger de sessão — commit já mergeado antes desta reconciliação; não reconstruído retroativamente)
- **Commit**: `6e67f30` (`fix(frontend): KAN-75 login respeita next apos autenticar`, 2026-09-07T14:08:52-0300) — branch `feat/producao-material-fix-login-redirect-next`, mergeada via PR #7 em `mnemonicos-frontend`. Documentação deste brief reconciliada em `mnemonicos-workspace` em 2026-09-08 (sessão de `/keelson:implement` de PLAN-021) — o commit e o merge já existiam, só a doc do brief nunca tinha sido registrada no workspace.
