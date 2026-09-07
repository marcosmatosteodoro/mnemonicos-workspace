# TASK-018-002: Integrar `PasswordField` no `LoginForm`

**Slug**: producao-material
**Pertence a**: PLAN-018
**Realiza (FRs)**: FR-016-001, FR-016-007
**Componente**: COMP-018-002 (principal)
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/campos-senha-toggle` — **cwd obrigatório do `developer`**:
`C:/kwt/kan72-toggle-senha` (worktree isolado; raiz do `mnemonicos-frontend`, sem
subcaminho `mnemonicos-frontend/`).
**Padrão de commit**: Conventional Commits (`feat:`).
**Framework de teste**: Jest 30 + Testing Library — mesma suíte que já existe em
`src/components/login-form.test.tsx` (7 casos, ver Contexto), estendida por esta TASK.

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
(AC-016-009) sem exigir estado elevado ao `LoginForm`. `login-form.test.tsx` já tem 7
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
- Extensão de `mnemonicos-frontend/src/components/login-form.test.tsx`: os 7 casos
  existentes continuam intactos (nenhuma asserção removida ou enfraquecida) + 2 casos
  novos cobrindo AC-016-007 e AC-016-009, mais a faceta restante de AC-016-006 (ver
  Critérios).

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
   7 casos existentes de `login-form.test.tsx` (o rótulo acessível do campo não muda,
   só ganha o botão de alternância ao lado) — sem isso, os 7 casos existentes quebram por
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
5. Para a faceta restante de AC-016-006, um caso estrutural simples: `login-form.tsx`
   não declara nenhum `useState` de visibilidade próprio nem lógica de alternância fora
   de `PasswordField` — pode ser conferido por leitura do próprio diff no code review
   (nenhum símbolo `visible`/`showPassword`/handler de toggle é introduzido em
   `login-form.tsx`), sem exigir teste dedicado além dos já listados.

## Critérios de pronto

- [ ] Os 7 casos pré-existentes de `login-form.test.tsx` continuam verdes, sem nenhuma
      asserção removida/enfraquecida (baseline capturada antes desta TASK: 7/7 passando
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
- [ ] AC-016-006 (faceta restante — fecha nesta TASK): `login-form.tsx` não declara
      `useState`/handler de alternância de visibilidade próprio; o único caminho para
      `type="password"`/`type="text"` no formulário é o `PasswordField` importado —
      conferido por leitura do diff no code review (nenhum símbolo de toggle fora de
      `password-field.tsx` no `git diff main...HEAD -- src/components/login-form.tsx`).
- [ ] Testes cobrem AC-016-006 (faceta restante), AC-016-007, AC-016-009 — verificação
      executável: `npx jest --runTestsByPath src/components/login-form.test.tsx` (cwd
      `C:/kwt/kan72-toggle-senha`) → `PASS ... Tests: 9 passed, 9 total` (7 pré-existentes
      + 2 novos) — fixada antes do código; comando já roda hoje contra o `login-form.tsx`
      atual com `Tests: 7 passed, 7 total` (baseline capturada nesta TASK, antes da
      integração — não-regressão via NFR-016-003).
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

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Branch**:
**Commit SHA**:
**Jira**:
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
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a>

**Notas**:
