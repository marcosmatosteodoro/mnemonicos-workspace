# TASK-020-002: Provar o status HTTP 404 real e a não-regressão do guard de sessão (`proxy.ts`)

**Slug**: producao-material
**Pertence a**: PLAN-020
**Realiza (FRs)**: nenhuma
**Componente**: COMP-020-001 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/pagina-404-personalizada` (já criada a partir de `origin/main` —
não recriar; mesma branch de TASK-020-001).
**Padrão de commit**: Conventional Commits (`chore:` — arquivo de teste novo, nenhum
código de produção).
**Framework de teste**: Jest 30, override `@jest-environment node` (mesmo mecanismo já
usado em `src/proxy.test.ts:2-3`) + `child_process`/`fetch` nativos do Node — sem
dependência nova (DEC-020-004). `proxy.test.ts` (reexecução) usa o mesmo override, sem
alteração.

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: nenhuma

> Independente de TASK-020-001 por desenho: o status HTTP 404 verificado aqui é produzido
> nativamente pelo App Router para **qualquer** rota sem correspondência — com ou sem um
> `not-found.tsx` customizado na árvore (o 404 padrão do framework já responde 404; o que
> muda com TASK-020-001 é o CONTEÚDO da página, não o código de status). As duas TASKs
> desta wave podem ser implementadas em qualquer ordem sem que uma bloqueie o oráculo da
> outra.

## Contexto

`jsdom` (ambiente padrão de `jest.config.ts`) não sobe um servidor Next real nem expõe
status de resposta HTTP — só prova conteúdo renderizado. Não há suíte E2E instalada
(`quality.e2e: null` na ficha) nem harness de integração HTTP no repositório hoje
(reconhecimento técnico do PLAN, item 10). Esta TASK acrescenta o teste de integração
dedicado que DEC-020-004 decide: `next build` + `next start` reais, porta dinâmica,
requisição HTTP real a uma rota inexistente (fora dos prefixos guardados de
`proxy.ts` — `/studio/**`, `/content/**` —, para não confundir o 404 com o redirect
307 do guard de sessão), asserindo `response.status === 404` (AC-019-004, NFR-019-003).
Em paralelo, reexecuta `proxy.test.ts` (existente, intocado) como prova de não-regressão
de AC-019-001b — este PLAN não cria nenhuma lógica de exclusão dentro de `NotFoundPage`;
a precedência guard×404 continua 100% do `proxy.ts` (DEC-020-002). É o único teste do
slug com o padrão "servidor real dentro do próprio processo de teste" (TRISK-020-001).

## Escopo

### Inclui

- `mnemonicos-frontend/src/app/not-found.integration.test.ts` (novo) — `@jest-environment
  node`. `beforeAll` roda `next build` (via `child_process.spawnSync`/`execFileSync`,
  timeout dedicado maior que o default do Jest) e sobe `next start` numa porta dinâmica
  (porta 0 ou faixa reservada de teste — TRISK-020-001) via `child_process.spawn`,
  aguardando o processo sinalizar pronto (parse do stdout, ex. `"Ready in"`/`"started
  server on"`) antes de prosseguir; `afterAll` encerra o processo filho
  (`child.kill()`) mesmo em caso de falha do teste, liberando a porta. 3 casos — todos
  com asserção de `<title>Página não encontrada · Mnemônicos</title>` no corpo, não só
  `toContain` de texto solto (achado do code-reviewer, rodada 3: o payload RSC do App
  Router embute a string do `not-found` em QUALQUER resposta, inclusive `/`/`/login`
  200 — só o `<title>` da rota efetivamente resolvida discrimina):
  (1) `fetch` contra uma rota que não existe (`/rota-inexistente-<sufixo>`, fora de
  `/studio`/`/content`) e assere `response.status === 404`; (2) `fetch` contra um
  segmento malformado, **também fora** de `/studio`/`/content` (ex.:
  `/rota-inexistente-%ZZ` — percent-encoding inválido) — assere
  `response.status === 404`, **nunca** `500` (TRISK-020-002/RISK-019-001: prova que o
  caso-limite cai no `not-found.tsx` e não num caminho de erro não tratado do App
  Router; deliberadamente fora dos prefixos guardados, para não confundir com o 307 do
  guard já coberto por `proxy.test.ts`).

### Não inclui

- Qualquer edição em `src/proxy.ts` ou em `not-found.tsx` (DEC-020-002; TASK-020-001 é
  quem cria este último) — este arquivo só lê o comportamento já existente/entregue por
  outra TASK, nunca o modifica.
- Instalação de suíte E2E (Playwright/`quality.e2e`) — alternativa descartada por DEC-020-004
  nesta fatia; fica como gatilho de reabertura (PLAN §6, "Reabrir se").
- Porta fixa/hardcoded — o teste usa porta dinâmica; um roteiro que fixe uma porta
  conhecida (ex. 3000) reintroduziria o conflito já registrado em `lessons.md`
  ("`CORS_ORIGINS` de origem única quebra silenciosamente o padrão de porta alternativa
  entre sessões paralelas") e colidiria com qualquer `next dev` local em execução.
- Rota sob prefixo guardado (`/studio/**`, `/content/**`) **sem sessão** como alvo do
  teste de status — sem cookie `mnemo_access`, essas retornam 307 (redirect do guard),
  não 404; usá-las aqui provaria o guard, não a convenção 404 (AC-019-001b é a asserção
  correta para elas, coberta abaixo pela reexecução de `proxy.test.ts`). **Ressalva
  (achado do code-reviewer, rodada 2)**: rota sob prefixo guardado **com** sessão ativa
  não está excluída — é o 3º caso do Escopo/Inclui acima, exigido por AC-019-001/
  FR-019-004 ("interna com sessão ativa"); a exclusão desta linha vale só para o
  cenário sem sessão.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. `not-found.integration.test.ts`: `@jest-environment node` no topo do arquivo (molde:
   `src/proxy.test.ts:1-3`).
2. `beforeAll`: `execFileSync('npm', ['run', 'build'], { cwd: <raiz de
   mnemonicos-frontend>, timeout: <generoso> })` — sem variável de ambiente extra
   necessária (`src/lib/env.ts` já tem defaults para `NEXT_PUBLIC_API_URL`/
   `NEXT_PUBLIC_APP_NAME`, build não exige `.env` real). Depois, `spawn('npm', ['run',
   'start', '--', '-p', '0'])` (ou variável de porta dinâmica equivalente), capturando o
   stdout para extrair a porta realmente aberta antes de liberar os testes.
3. `afterAll`: `child.kill()` incondicional (inclusive em `try/finally` cobrindo o corpo
   do `beforeAll`, para não deixar processo órfão se o `build`/`start` falhar no meio —
   mesma classe de cuidado da lição "processo jest zumbi" de `lessons.md`, agora aplicada
   ao processo `next start` filho, não ao próprio `jest`).
4. Caso (1): `const res = await fetch(\`http://localhost:${port}/rota-inexistente-xyz\`)`
   → `expect(res.status).toBe(404)`. Caso (2): `const res2 = await
   fetch(\`http://localhost:${port}/rota-inexistente-%ZZ\`)` →
   `expect(res2.status).toBe(404)` (nunca `500`).
5. `jest.setTimeout(<valor generoso — build + start reais são lentos>)` no topo do
   arquivo, só para esta suíte (não altera o timeout global de `jest.config.ts`).
6. Reexecutar `proxy.test.ts` sem alteração, capturando a contagem real de testes como
   baseline de não-regressão (AC-019-001b) — nenhuma linha desse arquivo muda.

## Critérios de pronto

- [ ] Requisição HTTP real (servidor `next start` de build de teste, porta dinâmica) a
      uma rota inexistente fora de `/studio`/`/content` responde com status 404 —
      AC-019-004, NFR-019-003.
- [ ] Requisição HTTP real a uma rota com segmento malformado (percent-encoding
      inválido), também fora de `/studio`/`/content`, responde 404 e nunca 500 —
      TRISK-020-002/RISK-019-001 (caso-limite de segmento dinâmico malformado).
- [ ] O processo filho (`next start`) é sempre encerrado ao final da suíte, inclusive em
      falha do `beforeAll`/`build` — nenhum processo `node`/`next` órfão nem porta presa
      após a execução (mesma classe de cuidado de `lessons.md`, "processo jest zumbi").
- [ ] `proxy.test.ts` (existente, sem nenhuma alteração de arquivo) permanece verde após
      esta TASK — não-regressão de AC-019-001b (precedência guard×404 continua 100% do
      `proxy.ts`, DEC-020-002; nenhum arquivo deste PLAN toca `src/proxy.ts`).
- [ ] Testes cobrem AC-019-004, TRISK-020-002/RISK-019-001 e a não-regressão de
      AC-019-001b — verificação executável:
      (a) `npx jest --runTestsByPath src/app/not-found.integration.test.ts` (cwd
      `mnemonicos-frontend`) → `PASS` (3 testes, cada um com asserção de
      `<title>Página não encontrada · Mnemônicos</title>` — não só `status === 404`,
      que o 404 default do framework também satisfaz: rota pública simples, segmento
      malformado, e rota sob prefixo interno com sessão ativa) —
      fixada antes do código (arquivo-alvo ainda não existe; mesmo mecanismo de override
      `@jest-environment node` já em produção nesta base — `src/proxy.test.ts`, que já
      roda hoje sob esse ambiente); (b) `npx jest --runTestsByPath src/proxy.test.ts`
      (cwd `mnemonicos-frontend`) → `PASS`, baseline capturada ANTES de qualquer mudança
      desta TASK — baseline **atualizada** (a contagem original de 23, de 2026-09-07,
      ficou obsoleta pelo merge de `origin/main`/KAN-75, que estendeu `proxy.test.ts`
      com o guard de open-redirect por resolução WHATWG: `password-field.tsx`/
      `login-form.tsx` etc.): confirmado por execução real em 2026-09-07 (rodada de
      code review, pós-merge) **54 casos**, todos verdes, sem alteração de arquivo — a
      mesma contagem se repete ao final da TASK, sem alteração de asserção).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`), produção e teste —
      `npx eslint src/app/not-found.integration.test.ts` (cwd `mnemonicos-frontend`) → 0
      problemas.
- [ ] Padrão de commit respeitado (Conventional Commits, `chore:`).
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem (`next-16.md`) —
      nenhuma dependência nova em `package.json` (child_process/fetch nativos do Node);
      porta dinâmica, nunca fixa; processo filho sempre encerrado.
- [ ] Code review aprovado.

## Riscos específicos

- **TRISK-020-001** (PLAN §8): `next build` + `next start` reais são mais lentos e mais
  frágeis (porta ocupada, tempo de subida do processo, timeout) do que os testes `jsdom`
  do resto da suíte, e é o primeiro teste do slug com este padrão. Mitigação: porta
  dinâmica, timeout generoso e dedicado (maior que o default do Jest), e `afterAll`/
  `finally` garantindo o encerramento do processo filho mesmo em falha — escopo deste
  padrão restrito a este único teste até haver suíte E2E formal (gatilho de reabertura,
  DEC-020-004).
- Suíte lenta: por rodar um `next build` completo, este teste soma tempo relevante a
  `npm test`/`npm run test:ci` — aceito nesta fatia (único teste do slug com o padrão);
  revisitar se o tempo total da suíte incomodar (candidato a `testPathIgnorePatterns`
  seletivo ou script dedicado, decisão futura, fora desta TASK).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-07T15:18:00-0300
**Data conclusão**: 2026-09-07T16:27:22-0300
**Branch**: feat/pagina-404-personalizada
**Commit SHA**: c96239c
**Jira**: KAN-82
**Implementado por**: developer (+ ajuste mecânico final aplicado pelo Tech Lead, item roteado abaixo)
**Revisado por**: code-reviewer, security-engineer
**Tentativas**: 4 (implementação + 3 rodadas de correção — 2 pelo developer, 1 mecânica pelo Tech Lead após o `code-reviewer` propor "aplicar e fechar" sem decisão de arquitetura pendente)
**Cobertura final**: n/a (critérios da TASK não exigem `--coverage`)
**Arquivos modificados**:
  - mnemonicos-frontend/src/app/not-found.integration.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 1, 2 achados média fechados: bind loopback + branch defasada, resolvida por merge de `origin/main`)
- [x] Comportamento (gate 9): consolidado (DoD, Etapa 4) — SPEC-019 sem FEATs

**Notas**: Rodadas de convergência acima do teto padrão de 1 retry (4 no total) — todos os
achados residuais das rodadas 2-4 foram mecânicos (âncora de regex, asserção de corpo
não-discriminante, reconciliação de contagem no artefato), sem nenhuma decisão de
arquitetura ou produto pendente; o `code-reviewer` propôs explicitamente "aplicar e
fechar" nas duas últimas rodadas. Decisão registrada em nome do Diretor (Tech Lead,
degrau 1 da escada de reação): prosseguir com a correção mecânica final em vez de
escalar — opção segura e reversível, sem ambiguidade de produto. Branch sincronizada com
`origin/main` (merge fast-forward, sem conflito) antes do fecho da wave — achado do
`security-engineer` (proxy.ts da branch estava pré-KAN-75). 4 lições registradas em
`guidelines/project/lessons.md` (discriminação de rota por `<title>` em teste HTTP;
bind loopback em servidor de teste; parser de token sobre buffer de stream).
