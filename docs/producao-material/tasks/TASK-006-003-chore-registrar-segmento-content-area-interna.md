# TASK-006-003: Registrar o segmento de rota `content` na área interna (prefixo + `config.matcher`)

**Slug**: producao-material
**Pertence a**: PLAN-006
**Realiza (FRs)**: nenhuma
**Componente**: COMP-006-012 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico MNEMORA STUDIO — `git.branchStrategy: unica`; não criar branch por task; a closure commita TASK a TASK)
**Padrão de commit**: Conventional Commits (`chore:` para esta TASK — registro de segmento de rota, sem página nem endpoint)
**Framework de teste**: Jest via `next/jest` (`testEnvironment: jsdom`), em `mnemonicos-frontend/`. Gates: `npm --prefix mnemonicos-frontend test` / `run lint` / `run typecheck` / `run build`.

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-006-012, TASK-006-013, TASK-006-014

## Contexto

As telas de F2 vivem sob a área interna de F1 (grupo de rota `(interno)/`). Hoje `src/lib/internal-routes.ts:14` traz `INTERNAL_ROUTE_PREFIXES = ['studio']` (fonte única do contrato de área interna) e `src/proxy.ts` traz `config.matcher` como **array literal de strings literais** — lido pelo Next por AST estático, sem `.flatMap`/spread/template (lição "[Testes] Valor de configuração lido por analisador de build"). Esta TASK registra o segmento novo `content` (identificador en; textos das telas seguem pt-BR pelo mapa de `domain.ts` — DEC-006-006) nos **dois** pontos obrigatórios no mesmo diff, e estende `src/proxy.test.ts` para travar a divergência diretório × símbolo × matcher. Nenhum `page.tsx` nasce aqui. NFR-005-001 (borda do frontend) é verificado via `src/proxy.test.ts` estendido → g1. Gates: g1; g8 (guarda de borda de navegação); g9/g10/g11 n/a.

## Escopo

### Inclui

- `mnemonicos-frontend/src/lib/internal-routes.ts`: `INTERNAL_ROUTE_PREFIXES` passa a `['studio', 'content']` (fonte única).
- `mnemonicos-frontend/src/proxy.ts`: `config.matcher` (array literal de strings literais — sem `.flatMap`/spread/template) ganha `'/content'` e `'/content/:path*'`, ao lado dos matchers de `studio`.
- `mnemonicos-frontend/src/proxy.test.ts`: assere os **dois** lados — um caminho sob `/content/**` é guardado **E** `/` (e as rotas públicas existentes) segue livre; enumera os segmentos reais de `src/app/(interno)/` falhando se algum não estiver coberto pelo matcher; equivalência literal↔símbolo (mutar o literal de `config.matcher` sem tocar `INTERNAL_ROUTE_PREFIXES`, ou vice-versa → vermelho); extrator AST do Next (`extractExportedConstValue`) devolve `value`, não `unsupported`.

### Não inclui

- Qualquer `page.tsx`/`layout.tsx` sob `(interno)/content/**` (TASK-006-012/013/014).
- Endpoints ou hooks RTK Query (TASK-006-010).
- Alteração do `InternalShell` ou de `INTERNAL_MIN_ROLE`/`roleSatisfies`.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. `internal-routes.ts` — acrescentar `'content'` a `INTERNAL_ROUTE_PREFIXES`.
2. `proxy.ts` — acrescentar `'/content'` e `'/content/:path*'` ao array literal de `config.matcher` (manter literal puro; nada de derivação em runtime).
3. `proxy.test.ts` — estender os casos existentes (`:84-146`) para cobrir `content`: guardado sob `/content/**`, `/` livre, enumeração de segmentos de `src/app/(interno)/`, equivalência literal↔símbolo, wiring do extrator AST.
4. `npm --prefix mnemonicos-frontend run build` para confirmar que o Next aceita o `config` literal.

## Critérios de pronto

- [ ] `INTERNAL_ROUTE_PREFIXES` em `src/lib/internal-routes.ts` passa a conter `'studio'` **e** `'content'` (fonte única). Verificação executável: `npm --prefix mnemonicos-frontend test -- proxy` cobre um caso que lê `INTERNAL_ROUTE_PREFIXES` e assere a presença de `'content'` e `'studio'`; `Tests: ≥1 passed`. Baseline (commit-pai): `INTERNAL_ROUTE_PREFIXES` == `['studio']` (`internal-routes.ts:14`). Falsificável: manter só `['studio']` → caso vermelho. Fixada antes do código.
- [ ] `config.matcher` em `src/proxy.ts` é **array literal de strings literais** (sem `.flatMap`/spread/template) e contém `'/content'` e `'/content/:path*'` além dos matchers de `studio`. Verificação executável (lição [Testes] "Valor de configuração lido por analisador de build só é provado por oráculo que passe pelo build"): teste de wiring `extractExportedConstValue(parse('src/proxy.ts'), 'config')` devolve `value` (não `unsupported`) **e** `npm --prefix mnemonicos-frontend run build` → exit 0 (baseline: build verde hoje nos dois repos). Falsificável: escrever `matcher: INTERNAL_ROUTE_PREFIXES.flatMap(...)` → `extractExportedConstValue` devolve `unsupported` e/ou `next build` aborta com `matcher needs to be a static string or array of static strings`. Fixada antes do código.
- [ ] Lição ativa [Segurança] "Guard de navegação (proxy/middleware) enumera o que GUARDA, nunca o que dispensa". Texto da lição (solução): *"o matcher enumera os prefixos internos, e a lista é derivada de um símbolo único compartilhado com o layout do grupo `(interno)` (não grafada à mão em dois lugares). O teste do matcher afirma os dois lados: as rotas internas são guardadas E `/` (e toda rota pública existente) não é; e enumera os segmentos de `src/app/(interno)/` falhando se algum não estiver coberto — a mesma régua de `assertDenyByDefault`/`route-authz-matrix` no backend. Rota nova sem asserção de 'segue livre' (ou 'é guardada', conforme o lado) é regressão esperando acontecer."* Item verificável em `src/proxy.test.ts`: (a) um caminho sob `/content/**` (`/content`, `/content/new`, `/content/abc/breakdown`) é **guardado** pelo matcher; (b) `/` e as rotas públicas existentes (`/login`, `/_next/*`) **seguem livres**; (c) o teste enumera os segmentos reais de `src/app/(interno)/` (lendo o diretório) e **falha** se algum não casar o matcher — `content` entra nessa enumeração; (d) equivalência literal↔símbolo: mutar o literal de `config.matcher` sem tocar `INTERNAL_ROUTE_PREFIXES` (ou vice-versa) → vermelho. Verificação executável: `npm --prefix mnemonicos-frontend test -- proxy` → todos os casos, `Tests: ≥4 passed`. Falsificável: remover os matchers de `/content` mantendo `'content'` no símbolo → (c)/(d) vermelho; tornar `/` guardado → (b) vermelho. Fixada antes do código.
- [ ] Lição ativa [Testes] "Valor de configuração lido por analisador de build só é provado por oráculo que passe pelo build" (reforço do 2º critério): o `config` de `proxy.ts` permanece literal; "derivado de um símbolo" = o **teste** assere a equivalência literal↔símbolo (oráculo de defasagem); estão presentes no Critério **os dois** — o wiring `extractExportedConstValue(...)` devolve `value` **e** `npm --prefix mnemonicos-frontend run build` → exit 0.
- [ ] Não-regressão: `npm --prefix mnemonicos-frontend test` — suíte inteira verde (baseline 90/90); `src/proxy.test.ts` não perde nenhum caso pré-existente (se o arquivo for reescrito, inventário de `it()`/`test()` antes — `git show <commit-pai>:mnemonicos-frontend/src/proxy.test.ts` — e depois; cada nome ausente classificado: renomeado / removido com motivo / perdido → volta).
- [ ] Sem warnings/lints novos — `npm --prefix mnemonicos-frontend run lint` → exit 0 (baseline capturada); `npm --prefix mnemonicos-frontend run typecheck` → exit 0.
- [ ] Padrão de commit respeitado (Conventional Commits — `chore:`).
- [ ] Aderência à stack/padrões da ficha e do perfil (`next-16.md` §6.3/§11: `config.matcher` array literal lido por AST; `INTERNAL_ROUTE_PREFIXES` fonte única; identificador de rota em inglês, texto de interface em pt-BR — DEC-006-006; guidelines de projeto vencem o perfil).
- [ ] Code review aprovado.

## Riscos específicos

- Tensão entre as duas lições (matcher "derivado de um símbolo" × `config` literal para o AST do Next): resolvida como o próprio texto da lição de build manda — o **teste** assere a equivalência literal↔símbolo; o `config.matcher` fica literal puro.
- O grupo `(interno)` não é endereçável por matcher (não aparece na URL): os dois extremos (exclusão / enumeração à mão) deixam o default frágil — daí a enumeração de segmentos de `src/app/(interno)/` no teste.
- Repos symlinkados (lição [Exploração]): editar/verificar pelo caminho dentro do link (`mnemonicos-frontend/src/...`); ausência detectada por varredura não é fato.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-04T19:16:40-03:00
**Data conclusão**: 2026-09-04T19:21:37-03:00
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 5ee6501 (impl) · db9d60a (carona gate 7)
**Jira**: KAN-31
**Implementado por**: developer
**Revisado por**: code-reviewer (gates 1-7) · security-engineer (gate 8)
**Tentativas**: 2 (1 code-review aprovou o mérito do arquivo, mas reprovou a wave por achado de outra TASK; retry aplicou a remoção Art.7 sugerida; re-review delta aprovou)
**Cobertura final**: n/a (91/91 no frontend pós-implementação; 23/23 no escopo `proxy`)
**Arquivos modificados**:
  - mnemonicos-frontend/src/lib/internal-routes.ts
  - mnemonicos-frontend/src/proxy.ts
  - mnemonicos-frontend/src/proxy.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados: NFR-005-001 (faceta de borda do frontend, via proxy.test.ts)
- [x] Segurança (gate 8): aprovado — security-engineer, Wave 1 (guard permanece conveniência; reformulação do teste de mirror→subconjunto conferida sem brecha)
- [ ] Comportamento (gate 9): n/a — sem AC de tela; nenhuma page.tsx criada nesta TASK

**Notas**: A equivalência exata do mirror (`INTERNAL_ROUTE_PREFIXES` == diretórios reais) foi reformulada para checagem de sentido único (subconjunto) + cobertura pelo símbolo, para acomodar "content" declarado antes de a página existir (Wave 5) — garantia original preservada, inventário de `it()` 14→15 sem perda. Carona Art. 7 trocou a referência temporal ("Wave 5") por porquê durável no comentário.
