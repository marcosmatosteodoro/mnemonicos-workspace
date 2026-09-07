# TASK-013-004: Service worker — ciclo de atualização e kill-switch

**Slug**: producao-material
**Pertence a**: PLAN-013
**Realiza (FRs)**: FR-013-005, FR-013-006
**Componente**: COMP-013-003 (principal)
**Wave**: 4
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-pwa-support` — **cwd obrigatório do
`developer`**: `C:/kwt/pwa` (worktree isolado). **NUNCA** rodar
`dev`/`test`/`lint`/`typecheck`/`build` em `mnemonicos-frontend/` da working tree
principal — outra sessão executa PLAN-012/F4 ali concorrentemente (RISK-013-005,
TRISK-013-002).
**Padrão de commit**: Conventional Commits (`feat:`).
**Framework de teste**: Jest 30 + `next/jest`, `testEnvironment: 'jsdom'` — lógica de
decisão pura (TRISK-013-001).

## Dependências

- **Depende de**: TASK-013-003
- **Bloqueia**: TASK-013-005

## Contexto

Estende o mesmo `public/sw.js` e `src/lib/service-worker-policy.ts` da TASK-013-003 (o
contrato do módulo — nomes de export, formato de `install`/`fetch` — já está fechado por
ela) com o handler `activate`: no caminho normal, limpa caches de versão anterior **sem**
`skipWaiting()`/`clients.claim()` (a versão nova só assume na reabertura seguinte,
NFR-013-003/FR-013-006); quando a versão de build é a versão de "kill" (DEC-013-002), toma
o caminho de recuperação (`unregister()` + limpar todos os caches + `clients.claim()` +
mensagem de reload).

## Escopo

### Inclui
- `src/lib/service-worker-policy.ts` — adicionar `isKillVersion(currentVersion: string):
  boolean` (nome do PLAN, COMP-013-003).
- `public/sw.js` — handler `activate`: (a) caminho normal — `caches.keys()` +
  `caches.delete()` das versões antigas do app-shell, **sem** `self.skipWaiting()` nem
  `clients.claim()`; (b) caminho de kill-switch (quando `isKillVersion(CURRENT_VERSION)`
  é verdadeiro) — `self.registration.unregister()`, limpar todos os caches, e
  `clients.claim()` + mensagem de reload aos clientes abertos.
- `self.skipWaiting()`/`clients.claim()` só existem dentro do ramo de kill-switch — nenhum
  outro ponto do arquivo os chama.

### Não inclui
- `install`/`fetch` (contrato já fechado pela TASK-013-003) — só leitura, sem alterar a
  forma dos exports existentes.
- Registro do `sw.js` no app — TASK-013-005.
- UI/mensagem visível ao usuário sobre o reload forçado (fora de escopo — o reload em si é
  o mecanismo, sem controle de instalação custom, A-013-004).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. `isKillVersion(currentVersion)` compara contra uma constante de versão de "kill"
   embutida no próprio `sw.js` (ex.: `KILL_VERSION`) — nunca lida de rede/config runtime
   (DEC-013-002: sem endpoint novo).
2. No `activate`, `event.waitUntil(...)` encadeia: se `isKillVersion` → ramo de
   recuperação; senão → limpeza de cache antigo só, sem tocar no ciclo de vida do cliente
   ativo.

## Critérios de pronto

- [ ] `isKillVersion` implementada e exportada de `service-worker-policy.ts`.
- [ ] `sw.js` liga `isKillVersion` ao `activate`, com os dois ramos descritos no Escopo.
- [ ] Testes cobrem AC-013-006/AC-013-012 (versão normal nunca ativa sob cliente vivo) —
      verificação executável: `npx jest --runTestsByPath
      src/lib/service-worker-policy.test.ts` → `OK (N tests)`, casos:
      `isKillVersion(CURRENT_APP_VERSION)` → `false` (fluxo normal); e teste estrutural
      lendo `public/sw.js` como texto confirmando que **toda** ocorrência de
      `skipWaiting()`/`clients.claim()` aparece só dentro do bloco delimitado pelo `if
      (isKillVersion(...))` do `activate` (contagem de ocorrências fora desse bloco === 0)
      — fixada antes do código.
- [ ] Testes cobrem AC-013-009 (ramo de kill-switch) — mesmo comando acima:
      `isKillVersion(KILL_VERSION)` → `true`; **e** teste estrutural com controle
      **positivo** (achado do `qa` pré-código, decisão 4.107(a) — o teste acima só prova
      ausência fora do bloco, nunca presença dentro dele; passaria com o kill-switch
      inteiramente não implementado): dentro do bloco `if (isKillVersion(...))`, a
      contagem de ocorrências de `self.registration.unregister(`, `caches.delete(` (ou
      `caches.keys(...).then(...delete...)`) e do envio de mensagem de reload aos
      clientes (`postMessage`/`clients.claim()` seguido do sinal de reload) é **≥ 1 cada**
      — mutante que remove qualquer uma das três chamadas do bloco deve reprovar este
      teste.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`), produção e teste.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem — nenhuma dependência
      nova (DEC-013-001); nenhum endpoint novo (DEC-013-002).
- [ ] Code review aprovado.

## Riscos específicos

- **TRISK-013-001**: o efeito real do `activate` (caches efetivamente limpos,
  `clients.claim()` disparando o reload de fato) não é simulável em `jsdom` — o gate 1
  acima prova a estrutura do código (presença das chamadas certas, dentro do bloco certo,
  falsificável por mutante), mas não o efeito real no navegador. Confirmado pelo roteiro
  concreto do DoD item (a) do PLAN §9 (não é um Roteiro de gate 9 desta TASK — é
  confirmação única no fecho do ciclo, cobrindo esta e as demais TASKs afetadas por
  TRISK-013-001).
- **TRISK-013-003**: o kill-switch depende de um segundo deploy manual do frontend (sem
  CI/CD, RISK-006-009) — aceito nesta fatia, sem mitigação adicional nesta TASK.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-07T02:33:09+0000
**Data conclusão**: 2026-09-07T03:38:00+0000
**Branch**: feat/producao-material-pwa-support
**Commit SHA**: 50f1d8f
**Jira**: KAN-68
**Implementado por**: developer
**Revisado por**: code-reviewer, security-engineer
**Tentativas**: 2
**Cobertura final**: n/a (231/231 → 232/232 testes verdes na suíte completa)
**Arquivos modificados**:
  - public/sw.js
  - src/lib/service-worker-policy.ts
  - src/lib/service-worker-policy.test.ts
  - src/lib/sw-loader.ts
  - src/lib/sw-parity.test.ts
  - src/lib/sw-execution.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (232/232, 21 suítes)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (rodada 2 — 3 achados bloqueantes: universo de leitura estrutural estreito demais, ramo normal do activate sem prova de efeito, `new Function()` violando perfil §6.1; todos fechados com mutante morto)
- [x] ACs verificados (AC-013-006, AC-013-009, AC-013-012)
- [x] Segurança (gate 8): aprovado — gatilho de kill-switch sem vetor remoto, fail-secure confirmado, blast radius restrito à própria origem
- [ ] Comportamento (gate 9): n/a — SPEC sem FEATs; nenhum AC desta TASK atribuído a gate 9 (TRISK-013-001, ciclo real confirmado no DoD item (a) do PLAN, no fecho do ciclo)

**Notas**: Rodada 1 reprovada pelo code-reviewer (gates 1 e 6): prova estrutural de ausência de `skipWaiting`/`clients.claim` lia só o corpo do handler `activate`, não o arquivo inteiro (mutante no handler `install` sobrevivia); ramo normal do `activate` sem teste de efeito (2 mutantes sobreviviam); `new Function()` em `sw-loader.ts` violava o perfil §6.1. Retry: universo ampliado para arquivo inteiro (`stripComments` passou a tratar `/* */` também), novo teste expõe `CachesStub` e prova limpeza seletiva do ramo normal, `new Function` trocado por arquivo temporário (`mkdtempSync`) + `require()` sem rastro. Nova lição registrada em `guidelines/project/lessons.md` ("Prova de ausência por leitura de texto-fonte precisa declarar o universo lido"). Achado `fora_de_escopo` do gate 1: `CACHE_NAME` sem versionamento faz o ramo normal do `activate` ser no-op em produção hoje — decisão futura do Tech Lead/PO (versionar a chave ou aceitar).

**Notas**: 
