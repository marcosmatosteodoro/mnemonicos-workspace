# TASK-021-002: Resolver `baseUrl` same-origin em `store/api.ts` e remover `env.apiUrl`

**Slug**: producao-material
**Pertence a**: PLAN-021
**Realiza (FRs)**: FR-002-001
**Funcionalidade**: FEAT-002-001 (primária)
**Componente**: COMP-021-002 (principal), COMP-021-003
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-rewrite-same-origin-cookie-sessao` (mesma branch de TASK-021-001 — `branchStrategy: unica`).
**Padrão de commit**: Conventional Commits — ex.: `feat(frontend): PLAN-021 baseUrl same-origin em store/api.ts e remoção de env.apiUrl`. Referencie `PLAN-021` até a sincronização Jira (Etapa 7 de `/keelson:tasks`) gravar a key na closure.
**Framework de teste**: Jest 30 + Testing Library (`guidelines/project/frontend/next-16.md` §7). Rodada escopada a um caminho usa `--runTestsByPath`.

## Dependências

- **Depende de**: TASK-021-001
- **Bloqueia**: nenhuma

## Contexto

Com o rewrite de TASK-021-001 montado, o cliente RTK Query precisa chamar a própria origem do documento (`window.location.origin`) em vez do host absoluto do backend, para que o browser trate a chamada como same-origin e o `Set-Cookie` seja gravado sob o domínio do frontend (DEC-021-001/DEC-021-003). Isso esgota o único consumidor de `env.apiUrl`/`NEXT_PUBLIC_API_URL` no repositório (confirmado por busca — `mnemonicos-frontend/src/store/api.ts:138` é a única ocorrência fora de `env.ts` e da documentação) — a remoção do campo morto (COMP-021-003) é decorrente e sem teste dedicado. Por essa dependência direta e a ausência de teste próprio para a remoção, as duas mudanças formam uma única fatia revisável (princípio 8: "duas tasks que só fazem sentido revisadas juntas são uma") em vez de nascerem como TASKs separadas.

## Escopo

### Inclui

- Edição em `mnemonicos-frontend/src/store/api.ts`: nova função exportada `resolveApiBaseUrl(): string` — retorna a origem do documento (`window.location.origin`) mais `/api/v1` quando `window` existe, e `'http://localhost/api/v1'` caso contrário (SSR do próprio Client Component, testes Jest `@jest-environment node`). `rawBaseQuery` passa a usar `baseUrl: resolveApiBaseUrl()` no lugar do host absoluto de `env.apiUrl` (linha 138 hoje). Remove o import `import { env } from '@/lib/env';` (único uso no arquivo). `isPublicAuthRequest` e `baseQueryWithReauth` não mudam — confirmado por leitura: ambos operam sobre `args.url` (caminho relativo do endpoint), nunca sobre `baseUrl`.
- Edição em `mnemonicos-frontend/src/lib/env.ts`: remove o campo `apiUrl` do objeto `env` (mantém `appName`).
- Edição em `mnemonicos-frontend/.env.example`: remove a linha `NEXT_PUBLIC_API_URL` (substituída por `BACKEND_API_URL`, já documentada pela TASK-021-001).
- Edição em `mnemonicos-frontend/README.md`: linha 25 (comentário de `cp .env.example .env.local` ajustado de `NEXT_PUBLIC_API_URL` para `BACKEND_API_URL`) e a linha `NEXT_PUBLIC_API_URL` da tabela de variáveis da seção "Deploy (Vercel)" (linha 97 hoje) removida.
- Teste novo `mnemonicos-frontend/src/store/api.browser-base-url.test.ts` (`@jest-environment jsdom`): `resolveApiBaseUrl()` retorna exatamente a origem do documento seguida de `/api/v1`.
- Extensão de `mnemonicos-frontend/src/store/api.test.ts` (existente, `@jest-environment node` no topo do arquivo — o novo caso já roda fora de `window` sem override adicional): 1 caso novo confirmando que `resolveApiBaseUrl()` cai no placeholder `'http://localhost/api/v1'` fora do browser; **nenhuma das 46 asserções pré-existentes muda** (não-regressão de `isPublicAuthRequest`/S1/S1b — os `hadCall`/`countCalls` existentes comparam só `pathname`, que não muda com a troca de host).
- Censo grep de saneamento (mesmo padrão de PLAN-006/TASK-006-010): zero ocorrência de `env.apiUrl`/`NEXT_PUBLIC_API_URL` restante em `mnemonicos-frontend/src` ao final da TASK.

### Não inclui

- Qualquer edição em `mnemonicos-frontend/next.config.ts`/`rewrites()` — já concluída pela TASK-021-001.
- Qualquer alteração em `mnemonicos-backend`.
- Verificação real do encaminhamento de `Origin`/preservação de `Set-Cookie` sob dois sites `*.vercel.app` reais (TRISK-021-001/002) — resíduo do DoD do PLAN, fora do alcance de TASK.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Adicionar `resolveApiBaseUrl()` em `store/api.ts`, exportada, logo antes de `rawBaseQuery`.
2. Trocar o `baseUrl` de `fetchBaseQuery({...})` de `${env.apiUrl}/api/v1` para `resolveApiBaseUrl()`; remover o import de `env`.
3. Escrever `api.browser-base-url.test.ts` sob `@jest-environment jsdom` chamando `resolveApiBaseUrl()` diretamente e comparando com a origem do documento.
4. Adicionar 1 `it()` em `api.test.ts` (mesmo arquivo, mesmo `@jest-environment node` do topo) chamando `resolveApiBaseUrl()` e comparando com o literal `'http://localhost/api/v1'` — sem tocar nenhum `it()` existente.
5. Remover `apiUrl` de `env.ts`, a linha de `.env.example` e a linha da tabela do README.
6. Rodar o censo grep de saneamento antes de fechar a TASK.

## Critérios de pronto

- [ ] `resolveApiBaseUrl()` existe, é exportada de `mnemonicos-frontend/src/store/api.ts`, e `rawBaseQuery` usa `baseUrl: resolveApiBaseUrl()`; nenhum import de `@/lib/env` permanece no arquivo.
- [ ] `isPublicAuthRequest`/`baseQueryWithReauth` permanecem byte-a-byte inalterados (`git diff main...HEAD -- mnemonicos-frontend/src/store/api.ts` mostra só a troca do `baseUrl` + a função nova + remoção do import — nenhuma linha dentro do corpo de `isPublicAuthRequest`/`baseQueryWithReauth` aparece no diff).
- [ ] Testes cobrem AC-002-001 (parte — faceta de topologia de rede/`baseUrl` same-origin) e NFR-002-008 (parte — mesma faceta de TASK-021-001) — verificação executável: `cd mnemonicos-frontend && npx jest --runTestsByPath src/store/api.browser-base-url.test.ts` → `Tests: 1 passed, 1 total`, fixada antes do código. Arquivo-alvo ainda não existe nesta base (confirmado por leitura direta em 2026-09-08).
- [ ] Não-regressão de `api.test.ts`: comando `cd mnemonicos-frontend && npx jest --runTestsByPath src/store/api.test.ts` → `Tests: 47 passed, 47 total` — baseline capturada agora por contagem de `it(` no arquivo = **46** (confirmado mecanicamente nesta fixação, 2026-09-08); a extensão soma exatamente 1 caso (`resolveApiBaseUrl` fora do browser), e os 46 nomes de `it(...)` existentes permanecem idênticos (inventário antes/depois, lição "[Testes] Retry que reescreve arquivo de teste... entrega o inventário antes/depois dos `it()`").
- [ ] Censo de saneamento: `grep -rn "env\.apiUrl\|NEXT_PUBLIC_API_URL" mnemonicos-frontend/src` → vazio (0 ocorrências). Baseline não-vazia confirmada agora, antes da TASK: 2 ocorrências (`mnemonicos-frontend/src/lib/env.ts:6` e `mnemonicos-frontend/src/store/api.ts:138`), mais 2 ocorrências fora de `src/` já confirmadas por leitura (`mnemonicos-frontend/.env.example:1-2`, `mnemonicos-frontend/README.md:25,97`) — as 4 ficam em 0 ao final desta TASK.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only main...HEAD`) — `cd mnemonicos-frontend && npm run lint` → exit 0.
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem: `env.ts` mantém `appName` como único campo restante, sem quebrar o único outro consumidor de `env` (`src/store/index.ts`, que não usa `apiUrl` — confirmar por leitura antes de remover, já que o campo é removido do objeto exportado).
- [ ] Code review aprovado.

## Riscos específicos

- **Superfície sensível (gates.security: true)**: `baseUrl` do cliente RTK Query passa de host absoluto para same-origin — é o lado do browser que ativa o rewrite de TASK-021-001. Revisão de segurança focada (gate 8) confirma que `isPublicAuthRequest`/`baseQueryWithReauth` seguem operando sobre `args.url` (caminho relativo), independente do host, e que nenhum outro caminho de código ficou órfão da mudança de `baseUrl`.
- TRISK-021-001/002 residuais — não fecham nesta TASK (verificação manual pós-deploy, DoD do PLAN).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Branch**:
**Commit SHA**:
**Jira**: KAN-84
**Implementado por**:
**Revisado por**:
**Tentativas**:
**Cobertura final**:
**Arquivos modificados**:
  -

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>

**Notas**:
