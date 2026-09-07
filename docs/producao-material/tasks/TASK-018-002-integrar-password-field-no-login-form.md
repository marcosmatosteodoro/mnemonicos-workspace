# TASK-018-002: Integrar `PasswordField` no `LoginForm`

**Slug**: producao-material
**Pertence a**: PLAN-018
**Realiza (FRs)**: FR-016-001, FR-016-007
**Componente**: COMP-018-002 (principal)
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/campos-senha-toggle` — **cwd obrigatório do `developer`**:
`C:/kwt/kan72-toggle-senha` (worktree isolado; raiz do `mnemonicos-frontend`, sem
subcaminho `mnemonicos-frontend/`).
**Padrão de commit**: Conventional Commits (`feat:`).
**Framework de teste**: Jest 30 + Testing Library — mesma suíte que já existe em
`src/components/login-form.test.tsx` (8 casos, ver Contexto), estendida por esta TASK.

## Dependências

- **Depende de**: TASK-018-001
- **Bloqueia**: nenhuma

## Contexto

`login-form.tsx` renderiza hoje o campo de senha nu (`<label>Senha<input
type="password" name="password" autoComplete="current-password" required
value={password} onChange={...} .../></label>`, linhas ~72-83). Esta TASK substitui esse
bloco pelo `PasswordField` criado na TASK-018-001, mantendo `email`/`password`/
`hasFailed`/`handleSubmit` inalterados — nenhum comportamento do fluxo de login (SPEC-002)
muda. O estado de visibilidade do toggle vive dentro do próprio `PasswordField` (DEC-018-004)
e, como o componente nunca desmonta durante o ciclo de submit-falha (`hasFailed` é um
`useState` irmão que só condiciona a mensagem de erro — `login-form.tsx:85-89` —, o
`<form>` inteiro permanece montado), sobrevive naturalmente a uma submissão recusada
(AC-016-009) sem exigir estado elevado ao `LoginForm`. `login-form.test.tsx` já tem 8
casos verdes (estados em andamento/falha/sucesso de AC-002-009, destino de sucesso pelo
símbolo canônico, submit seguro pré-hidratação) que não podem regredir.

## Escopo

### Inclui

- Edição em `mnemonicos-frontend/src/components/login-form.tsx`: o bloco do campo de
  senha passa a renderizar `<PasswordField id="password" name="password" label="Senha"
  autoComplete="current-password" required value={password} onChange={(event) =>
  setPassword(event.target.value)} />` no lugar do `<label>...<input
  type="password".../></label>` atual (PLAN §3, COMP-018-002). Nenhuma outra linha de
  `login-form.tsx` muda — `email`, `hasFailed`, `handleSubmit`, `hydrated` e o botão de
  submit permanecem intocados.
- Extensão de `mnemonicos-frontend/src/components/login-form.test.tsx`: os 8 casos
  existentes continuam intactos (nenhuma asserção removida ou enfraquecida) + 3 casos
  novos cobrindo AC-016-005, AC-016-007 e AC-016-009, mais a faceta restante de
  AC-016-006 (ver Critérios).

### Não inclui

- Qualquer edição em `password-field.tsx` — componente já fechado e testado pela
  TASK-018-001; esta TASK só o consome.
- Qualquer alteração de comportamento do fluxo de autenticação (SPEC-002) — submissão,
  validação de credenciais, os três estados observáveis de FR-002-009, `hydrated`,
  mensagem genérica de falha (NFR-016-003 proíbe regressão; SPEC-016 §4.2).
- Telas de cadastro/troca de senha (Out-of-scope SPEC-016 §4.2, Q-016-001).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Importar `PasswordField` de `@/components/password-field` em `login-form.tsx` e
   substituir o `<label>` do campo de senha pela chamada descrita no Escopo — preservando
   o texto visível "Senha" como rótulo do campo (prop `label`).
2. Conferir que `screen.getByLabelText('Senha')` continua resolvendo o `<input>` real nos
   8 casos existentes de `login-form.test.tsx` (o rótulo acessível do campo não muda,
   só ganha o botão de alternância ao lado) — sem isso, os 8 casos existentes quebram por
   mudança de contrato de acessibilidade, não por regressão de comportamento.
3. Escrever o caso de AC-016-007: percorrer o fluxo de login completo (preencher
   e-mail/senha, submeter, sucesso ou falha) com `PasswordField` aplicado — mesmo
   `arrangeMutation`/`resolvingTrigger`/`rejectingTrigger` já usados nos casos existentes
   — e confirmar que o comportamento observável é idêntico ao descrito em SPEC-002 (nada
   novo, nada a menos).
4. Escrever o caso de AC-016-009: alternar o toggle para texto plano (via
   `userEvent.click` no botão renderizado **dentro do `LoginForm` montado** — nunca em
   `PasswordField` isolado, para que o teste exercite a integração real e não apenas o
   componente por si — mesma régua da lição ativa "predicado de decisão de UI só se prova
   no componente montado", `lessons.md`), preencher credencial inválida, submeter, esperar
   a mensagem de erro (`findByText`/`findByRole('alert')`, padrão já usado nos casos
   existentes) e então afirmar que o campo de senha **continua** com `type="text"` (o
   estado do toggle não foi revertido pela submissão recusada).
5. Escrever o caso de AC-016-005 no `LoginForm` real (achado do QA pré-código — o teste
   isolado de TASK-018-001 prova só a forma genérica, não o cenário literal do AC): montar
   `LoginForm`, preencher e-mail e senha, clicar/ativar por teclado o botão de alternância
   e então afirmar que o mock de `useLoginMutation`/`login` **não** foi chamado (o mesmo
   mock já usado nos 8 casos existentes) — nenhuma submissão foi disparada pelo toggle.
6. Para a faceta restante de AC-016-006, um comando estrutural determinístico (achado do
   QA pré-código — "conferido no code review" não é verificação executável): nenhum outro
   `<input type="password">` do `mnemonicos-frontend` implementa alternância própria —
   ver Critérios de pronto para o comando exato.

## Critérios de pronto

- [ ] Os 8 casos pré-existentes de `login-form.test.tsx` continuam verdes, sem nenhuma
      asserção removida/enfraquecida (baseline capturada antes desta TASK: 8/8 passando
      contra o `login-form.tsx` atual, comando abaixo).
- [ ] AC-016-007: dado o `LoginForm` com `PasswordField` aplicado, o fluxo de login
      completo (sucesso navega para `INTERNAL_HOME`; falha mostra a mensagem genérica
      exata `"E-mail ou senha inválidos."`, formulário permanece utilizável) é idêntico ao
      descrito em SPEC-002 — nenhuma requisição, campo ou comportamento novo introduzido
      pelo toggle.
- [ ] AC-016-009: dado o usuário que alternou o campo de senha para texto plano (clique no
      botão de alternância renderizado dentro do `LoginForm` montado) e submeteu com
      credencial inválida, quando a mensagem de erro é exibida, então o campo de senha
      permanece com `type="text"` (visível) — o estado do toggle não é revertido pela
      submissão recusada.
- [ ] AC-016-005 (cenário literal do AC, no `LoginForm` real — achado do QA pré-código):
      dado o `LoginForm` com e-mail e senha preenchidos, quando o botão de alternância é
      acionado (clique ou teclado), então o mock de `login`/`useLoginMutation` NÃO é
      chamado — nenhuma submissão ocorre.
- [ ] AC-016-006 (faceta restante — fecha nesta TASK, verificação executável, não só code
      review — achado do QA pré-código; comando de grep original substituído no retry
      pós gate 1-7 por não ser confiável — ver Notas de correção abaixo): nenhum arquivo
      de produção `.ts`/`.tsx` sob `src/` (fora de `password-field.tsx`, único componente
      autorizado, TASK-018-001) declara um input de senha com alternância própria, na
      forma literal (`type="password"`) OU na forma dinâmica
      (`type={cond ? 'text' : 'password'}`) — teste estrutural que lê o código-fonte real
      (mesmo padrão de `service-worker-policy.test.ts`), com controles positivo/negativo
      embutidos provando que o detector de fato casa as duas formas —
      `npx jest --runTestsByPath src/components/login-form.test.tsx -t "AC-016-006"` (cwd
      `C:/kwt/kan72-toggle-senha`) → `PASS`, todos os casos do describe verdes.
- [ ] Testes cobrem AC-016-005, AC-016-006, AC-016-007, AC-016-009 — verificação
      executável: `npx jest --runTestsByPath src/components/login-form.test.tsx` (cwd
      `C:/kwt/kan72-toggle-senha`) → `PASS ... Tests: 16 passed, 16 total` (8
      pré-existentes + 3 de AC-016-005/007/009 + 5 do describe estrutural de AC-016-006:
      universo não vazio, ausência de ofensor, 2 controles positivos e 1 negativo) —
      fixada antes do código; comando já roda hoje contra o `login-form.tsx` atual com
      `Tests: 8 passed, 8 total` (baseline capturada nesta TASK, antes da integração —
      não-regressão via NFR-016-003).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`), produção e teste —
      `npx eslint src/components/login-form.tsx src/components/login-form.test.tsx` →
      0 problemas.
- [ ] Padrão de commit respeitado (Conventional Commits, `feat:`).
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem (`next-16.md`) —
      nenhuma dependência nova; `PasswordField` consumido como componente controlado
      (props `value`/`onChange`), sem duplicar `useState` de valor.
- [ ] Code review aprovado.

## Riscos específicos

- Nenhum risco técnico próprio desta TASK além dos já herdados de TASK-018-001
  (TRISK-018-001/002, PLAN §8) — esta TASK não introduz componente novo, só consome o
  já testado.

**Notas de correcao (retry pos gate 1-7, 2 rodadas)**: o comando de grep original substituido por teste estruturado em login-form.test.tsx cobre a forma literal e a dinamica de type=password. Na revalidacao (rodada 2), o revisor achou e o Tech Lead corrigiu no mesmo commit: a exclusao de password-field.tsx era por nome de arquivo, nao por caminho - uma copia do componente em outro diretorio com o mesmo nome escapava da exclusao. Corrigido para comparar o caminho completo.

**Divida declarada (nao fechada nesta TASK, teto de 2 rodadas de varredura)**: o detector ainda nao cobre a forma indireta - type atribuido a partir de uma variavel ou constante nomeada fora do proprio atributo JSX. Fechar essa classe pede analise sintatica (AST) ou uma regra ESLint dedicada, nao mais uma regex sobre o texto-fonte. Registrado como risco tecnico residual - ver INDEX do slug.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-07
**Data conclusão**: 2026-09-07
**Branch**: feat/campos-senha-toggle
**Commit SHA**: fed03e3 (fix pos-review; base 8b8ed16, 8a97ddc)
**Jira**: KAN-80
**Implementado por**: developer
**Revisado por**: code-reviewer, product-designer
**Tentativas**: 3 (2 retries — AC-016-006 sem prova executavel real na 1a rodada, corrigido com teste estrutural; exclusao por basename em vez de caminho completo achada na revalidacao da 2a rodada e corrigida no fecho, sem nova rodada de gate)
**Cobertura final**: 4/4 ACs desta TASK (005 cenario real, 006 faceta restante, 007, 009) + 8/8 pre-existentes preservados — 16/16 testes no arquivo, suite completa 24/251 sem regressao
**Arquivos modificados**:
  - src/components/login-form.tsx
  - src/components/login-form.test.tsx

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): n/a - sem I/O, sem endpoint, sem dado de sessao; integracao so troca o campo de senha nu pelo componente ja aprovado
- [x] Comportamento (gate 9): n/a - acao sincrona local sem I/O (nota FR-016-003, decisao 4.67); todos os ACs desta TASK fecham por gate 1 (teste automatizado)

**Notas**:
