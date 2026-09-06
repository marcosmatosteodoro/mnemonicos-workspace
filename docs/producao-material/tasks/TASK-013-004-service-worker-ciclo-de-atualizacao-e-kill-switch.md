# TASK-013-004: Service worker — ciclo de atualização e kill-switch

**Slug**: producao-material
**Pertence a**: PLAN-013
**Realiza (FRs)**: FR-013-005, FR-013-006
**Componente**: COMP-013-003 (principal)
**Wave**: 4
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-pwa-support` — **cwd obrigatório do
`developer`**: `C:/kwt/pwa/mnemonicos-frontend` (worktree isolado). **NUNCA** rodar
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
      `isKillVersion(KILL_VERSION)` → `true`.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`), produção e teste.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem — nenhuma dependência
      nova (DEC-013-001); nenhum endpoint novo (DEC-013-002).
- [ ] Code review aprovado.

## Riscos específicos

- **TRISK-013-001**: o efeito real do `activate` (caches efetivamente limpos,
  `clients.claim()` disparando o reload de fato) não é simulável em `jsdom` — confirmado
  por inspeção manual no painel Application (DevTools), DoD item (a) do PLAN, no fecho do
  ciclo; não é um Roteiro de gate 9 desta TASK.
- **TRISK-013-003**: o kill-switch depende de um segundo deploy manual do frontend (sem
  CI/CD, RISK-006-009) — aceito nesta fatia, sem mitigação adicional nesta TASK.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-68
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
