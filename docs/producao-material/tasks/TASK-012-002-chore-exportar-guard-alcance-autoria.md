# TASK-012-002: Exportar `assertRawContentReachable` de `contents.service.ts`

**Slug**: producao-material
**Pertence a**: PLAN-012
**Realiza (FRs)**: nenhuma
**Componente**: COMP-012-005 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico, estratégia `unica`)
**Padrão de commit**: Conventional Commits (`refactor:` — muda só visibilidade, nenhuma lógica nova)
**Framework de teste**: Jest 30 + ts-jest (`npm --prefix mnemonicos-backend test`)

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-012-005

## Contexto

Fatia sensível (segurança — OWASP A01, guard de alcance por autoria). `tira.service.ts`
(TASK-012-005) precisa da mesma garantia de alcance que `contents.service.ts` já prova para
`RuleBreakdown` (NFR-011-001, DEC-012-007) — reuso por `export`, nunca duplicação da lógica
(RISK-006-006, mesma classe de risco de paridade declaração×declaração sem sincronismo
automático). `assertRawContentReachable` hoje é função privada (`contents.service.ts:360`,
não exportada) usada por `getRuleBreakdown`/`saveRuleBreakdown`; esta TASK só promove sua
visibilidade — a lógica (ordem de guardas inexistente → fora do alcance → soft-deleted,
mensagens idênticas "Conteúdo bruto não encontrado."/"Conteúdo bruto foi removido.") e a
suíte que já a exercita (`contents.service.integration.test.ts`) não mudam.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/contents/contents.service.ts` (linha 360): acrescenta a
  palavra `export` na declaração de `assertRawContentReachable` — assinatura, corpo e ordem
  de guardas idênticos ao atual. Nada mais neste arquivo.
- `mnemonicos-backend/tests/unit/contents-service-exports.test.ts` (novo, mínimo): 1 teste
  que importa `assertRawContentReachable` de fora do módulo e confirma que o símbolo é
  importável — prova de que a mudança de visibilidade realmente alcança quem consome de
  outro módulo (consumidor real só chega em TASK-012-005; este teste não espera por ela).

### Não inclui

- Qualquer mudança de ordem de guardas (`inexistente → fora do alcance → soft-deleted`) ou
  das mensagens de erro (`"Conteúdo bruto não encontrado."`/`"Conteúdo bruto foi
  removido."`) — a lógica de `assertRawContentReachable` permanece byte-a-byte a mesma.
  Recriar essa lógica em `tira.service.ts` em vez de importar (lição ativa [Código]
  "Correção de duplicação (DRY) introduz nova re-derivação do canônico no mesmo diff" —
  aplicável ao CONSUMIDOR desta função, TASK-012-005, não a esta TASK).
- Consumo real da função em `tira.service.ts` — TASK-012-005.
- Qualquer outra função de `contents.service.ts` — só `assertRawContentReachable` muda.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Capturar a baseline: rodar `npm --prefix mnemonicos-backend run test:integration --
   contents.service` e anotar a contagem de testes verdes atual.
2. Adicionar `export` antes de `async function assertRawContentReachable` (linha 360 de
   `contents.service.ts`) — nenhuma outra mudança no arquivo.
3. Criar `tests/unit/contents-service-exports.test.ts` com um único `it()` que importa a
   função e confere `typeof assertRawContentReachable === 'function'`.
4. Rodar a mesma suíte de integração da baseline e confirmar a mesma contagem, toda verde.

## Critérios de pronto

- [ ] `assertRawContentReachable` está `export`ada em `contents.service.ts`, ausente como
      export no commit-pai (mudança puramente aditiva de visibilidade) — verificação
      executável (padrão ancorado em declaração, contrato §273(b)): `grep -n "^export
      async function assertRawContentReachable" mnemonicos-backend/src/modules/contents/
      contents.service.ts` → 1 linha; `git show main:mnemonicos-backend/src/modules/
      contents/contents.service.ts | grep -c "^export async function
      assertRawContentReachable"` → `0` (confirma que é aditivo, não já existia). Fixada
      antes do código.
- [ ] Import de `assertRawContentReachable` a partir de outro módulo compila e resolve em
      runtime — item do Inclui sem AC, oráculo é o contrato do próprio item (função agora
      pública). Verificação executável:
      `npm --prefix mnemonicos-backend test -- contents-service-exports` →
      `Tests: 1 passed, 1 total`. Falsificável: reverter o `export` faz o `import` falhar
      em tempo de compilação (TS2305, "has no exported member") e o teste nem rodar.
- [ ] `contents.service.integration.test.ts` permanece 100% verde, com a MESMA contagem de
      testes de antes da mudança (nenhuma asserção alterada, nenhum teste novo/removido
      neste arquivo por esta TASK) — critério de não-regressão com baseline capturada.
      Verificação executável: `npm --prefix mnemonicos-backend run test:integration --
      contents.service` rodado ANTES de tocar o arquivo → captura a contagem real (ex.:
      "Tests: N passed, N total", N fixado na execução real desta TASK); o MESMO comando
      depois da mudança de visibilidade → a MESMA contagem N, todos verdes. Falsificável:
      qualquer alteração na ordem dos guards ou nas mensagens de erro literais
      (`"Conteúdo bruto não encontrado."`/`"Conteúdo bruto foi removido."`) reprovaria
      alguma asserção já existente nesse arquivo — o critério cobre exatamente esse
      mutante ao exigir a suíte pré-existente inalterada.
- [ ] Nenhuma outra função de `contents.service.ts` é tocada — verificação executável:
      `git diff main...HEAD -- mnemonicos-backend/src/modules/contents/contents.service.ts`
      mostra exatamente 1 linha modificada (a declaração de `assertRawContentReachable`)
      — `git diff --stat main...HEAD -- mnemonicos-backend/src/modules/contents/
      contents.service.ts` → `1 file changed, 1 insertion(+), 1 deletion(-)`.
- [ ] Sem warnings/lints novos (`npm --prefix mnemonicos-backend run lint` → exit 0, sobre
      todos os arquivos do diff, produção e teste).
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem.
- [ ] Code review aprovado.

## Riscos específicos

- Fatia sensível (segurança): `security-engineer` (gate 8) confirma que a mudança de
  visibilidade não abre nenhuma superfície nova de chamada além do módulo `tira`
  (TASK-012-005) — a função continua fail-secure (recusa por padrão), só deixa de ser
  privada ao arquivo.
- Lição ativa [Código] "Correção de duplicação (DRY) introduz nova re-derivação do
  canônico no mesmo diff": o risco real desta lição recai sobre o CONSUMIDOR
  (TASK-012-005) — se `tira.service.ts` reimplementar a lógica em vez de importar, o
  guard duplica e diverge silenciosamente; nada a corrigir nesta TASK, só o alerta
  registrado para quem a consome a seguir.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-06T19:00:58-0300
**Data conclusão**: 2026-09-06T19:04:23-0300
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 60be101
**Jira**: KAN-52
**Implementado por**: developer
**Revisado por**: code-reviewer (aprovado sem achados, Wave 1) · security-engineer (gate 8 aprovado, Wave 1 — diff de 1 linha confirmado byte-idêntico)
**Tentativas**: 1
**Cobertura final**: n/a (item do Inclui sem AC — oráculo é o contrato do próprio item)
**Arquivos modificados**:
  - mnemonicos-backend/src/modules/contents/contents.service.ts
  - mnemonicos-backend/tests/unit/contents-service-exports.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (47/47, mesma contagem da baseline + 1 novo)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados (n/a — sem AC numerado)
- [x] Segurança (gate 8): aprovado — export aditivo puro, ordem de guardas e mensagens byte-idênticas confirmadas por diff
- [x] Comportamento (gate 9): n/a — chore de visibilidade, sem efeito observável

**Notas**:
