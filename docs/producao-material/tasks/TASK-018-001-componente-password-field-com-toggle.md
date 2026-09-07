# TASK-018-001: Criar o componente `PasswordField` com toggle de visibilidade

**Slug**: producao-material
**Pertence a**: PLAN-018
**Realiza (FRs)**: FR-016-001, FR-016-002, FR-016-003, FR-016-004, FR-016-005, FR-016-006, FR-016-007
**Componente**: COMP-018-001 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/campos-senha-toggle` (já criada a partir de `origin/main`) —
**cwd obrigatório do `developer`**: `C:/kwt/kan72-toggle-senha` (worktree isolado; é a
RAIZ do `mnemonicos-frontend` — `package.json` mora direto ali, **não** em
`C:/kwt/kan72-toggle-senha/mnemonicos-frontend`, subcaminho que não existe — mesmo
achado de path já registrado no Histórico recente do INDEX para o worktree de PLAN-013).
**Padrão de commit**: Conventional Commits (`feat:`).
**Framework de teste**: Jest 30 + Testing Library (`@testing-library/react`,
`@testing-library/user-event`, `jest-environment-jsdom`) via `next/jest` — mesmo padrão
de `src/components/login-form.test.tsx` (molde/exemplar desta TASK), sem dependência
nova.

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-018-002

## Contexto

`mnemonicos-frontend` tem hoje um único campo de senha real, nu, dentro de
`login-form.tsx:74-83` (`<label>Senha<input type="password" .../></label>`, sem nenhum
controle de visibilidade). Esta TASK extrai o comportamento de toggle para um componente
de apresentação novo e autocontido — `PasswordField` —, que nasce **sem consumidor**
(a substituição do campo nu do `LoginForm` é a TASK-018-002, Wave 2, dependente desta).
O componente é controlado (`value`/`onChange` como props, DEC-018-001/DEC-018-004): só é
dono do próprio estado de visibilidade, nunca do valor digitado.

## Escopo

### Inclui

- `mnemonicos-frontend/src/components/password-field.tsx` (novo) — `'use client'`,
  named export `PasswordField`, props `{ id: string; name: string; label: string; value:
  string; onChange: (event: ChangeEvent<HTMLInputElement>) => void; autoComplete: string;
  required?: boolean }` (PLAN §3, COMP-018-001). Estado interno único:
  `const [visible, setVisible] = useState(false)` — inicia oculto (FR-016-002). O
  `<input>` recebe `type={visible ? 'text' : 'password'}`, mais os atributos anti-canal
  fixos independentes do estado (`spellCheck={false}`, `autoCorrect="off"`,
  `autoCapitalize="off"` — DEC-018-005) e os herdados via props (`name`, `autoComplete`,
  `required`). O botão de alternância: `<button type="button" onClick={() =>
  setVisible((v) => !v)} aria-label={visible ? 'ocultar senha' : 'mostrar senha'}>`
  (FR-016-005), com um dos dois SVGs inline (olho aberto/fechado) conforme o estado
  corrente — sem biblioteca de ícones (DEC-018-002), cor via `currentColor`/classe já
  existente (sem paleta própria). Ordem de tabulação natural — sem `tabIndex={-1}`
  (DEC-018-003).
- `mnemonicos-frontend/src/components/password-field.test.tsx` (novo) — Testing Library +
  `userEvent`, molde/exemplar `login-form.test.tsx`. Cobre AC-016-001, AC-016-002,
  AC-016-003, AC-016-004, AC-016-005, AC-016-006 (parte — ver Critérios), AC-016-008,
  AC-016-010.

### Não inclui

- Qualquer edição em `login-form.tsx` — a integração é a TASK-018-002 (Wave 2, dependente
  desta), única a tocar esse arquivo.
- Biblioteca de ícones nova — DEC-018-002 fecha essa decisão; nenhuma dependência entra em
  `package.json`.
- Estado do valor digitado — `PasswordField` não tem `useState` de valor; `value`/
  `onChange` são sempre props do consumidor (DEC-018-001).
- AC-016-006 (faceta "o `LoginForm` de fato consome o componente, sem implementação
  própria") e AC-016-007/AC-016-009 (fluxo de login completo e persistência do toggle após
  falha) — fecham em TASK-018-002, sobre o `LoginForm` real montado.
- Ícone `maskable`/refinamento visual de marca — fora do pedido (SPEC-016 §4.2).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Criar `password-field.tsx` com a assinatura de props e o `useState(visible)` local
   descritos no PLAN §3 (COMP-018-001, "Interface pública").
2. Escrever os dois SVGs inline (olho aberto quando `visible === true`, fechado quando
   `visible === false`) — `currentColor`, sem `fill`/`stroke` de paleta literal (guideline
   de projeto, "componente não decide cor por conta própria").
3. Botão de alternância como elemento acessível nativo (`<button type="button">`) — o
   `aria-label` muda com `visible`; nenhum `preventDefault()` no `onClick`/`onKeyDown` que
   desviasse o foco do próprio botão (garante AC-016-010 de graça, comportamento nativo do
   DOM).
4. `password-field.test.tsx`: renderizar `PasswordField` dentro de um `<form
   onSubmit={...}>` de teste (para AC-016-005) com um `useState` local simulando o
   consumidor controlado; usar `userEvent.click`/`userEvent.tab()` +
   `userEvent.keyboard('{Enter}')`/`'{ }'` para os casos de teclado (AC-016-004,
   AC-016-010), com asserção via `document.activeElement` (mesma técnica de
   `login-form.test.tsx`, sem depender de inspeção manual — TRISK-018-002).
5. Para AC-016-006 (parte), o teste desta TASK confirma que a lógica de alternância vive
   **inteiramente** dentro de `PasswordField` — nenhum outro estado/handler de
   visibilidade fora do componente é necessário para o consumidor de exemplo funcionar; a
   faceta "o `LoginForm` real consome exatamente este componente, sem reimplementar nada"
   fecha em TASK-018-002.

## Critérios de pronto

- [ ] `PasswordField` inicia sempre oculto (`type="password"`), antes de qualquer
      alternância — AC-016-001.
- [ ] Clique no botão de alternância troca `type` entre `password`/`text` sem alterar o
      valor exibido; clique novamente reverte — AC-016-002.
- [ ] `aria-label` do botão é `"mostrar senha"` quando oculto e `"ocultar senha"` quando
      visível, nos dois estados — AC-016-003.
- [ ] Navegação só por teclado (Tab até o botão) + ativação por Enter e por Espaço
      alternam a visibilidade da mesma forma que o clique, e o botão é identificável por
      `getByRole('button', { name: /mostrar senha|ocultar senha/i })` — AC-016-004.
- [ ] Acionar o botão (clique ou teclado) dentro de um `<form>` com `onSubmit` NÃO dispara
      o `onSubmit` — AC-016-005.
- [ ] AC-016-006 (parte — a lógica de alternância existe em um único lugar, dentro de
      `PasswordField`, sem estado/handler de visibilidade duplicado no consumidor de
      teste; a faceta "o `LoginForm` real consome este componente" fecha na
      TASK-018-002).
- [ ] Acionar o toggle não dispara nenhuma chamada de rede/mock de `fetch`, não escreve em
      `console.*`, e o `<input>` mantém `name`/`autoComplete` fornecidos via props em
      ambos os estados de `type` — AC-016-008.
- [ ] Após ativação por teclado (Enter ou Espaço), no MESMO caso de teste:
      `document.activeElement` continua sendo o próprio botão de alternância E o valor
      exibido no `<input>` permanece o mesmo digitado antes da ativação (nenhum
      remount/perda de valor) — AC-016-010. Resíduo declarado (não coberto por este
      critério, achado do QA pré-código): `jsdom` não reproduz com fidelidade total o
      encaminhamento de foco/clique de um `<button>` aninhado em `<label>` entre motores
      de navegador reais (Safari/Firefox vs. Chrome) — mesma classe de RISK-016-001/
      TRISK-018-001 (conformidade automatizada, não caminhada real em navegador);
      registrado no PLAN §10 como fora do alcance desta prova.
- [ ] Testes cobrem AC-016-001, AC-016-002, AC-016-003, AC-016-004, AC-016-005,
      AC-016-006 (parte), AC-016-008, AC-016-010 — verificação executável:
      `npx jest --runTestsByPath src/components/password-field.test.tsx` (cwd
      `C:/kwt/kan72-toggle-senha`) → `PASS ... Tests: 8 passed, 8 total` (mínimo 1 caso
      por AC listado, controle positivo e negativo nos dois estados de `visible`) —
      fixada antes do código (arquivo-alvo ainda não existe; comando roda contra
      `password-field.test.tsx` assim que gravado, mesma rodada do commit; molde de
      convenção: `src/components/login-form.test.tsx`, que já roda com o mesmo comando
      trocando o caminho).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`), produção e teste —
      `npx eslint src/components/password-field.tsx src/components/password-field.test.tsx`
      → 0 problemas.
- [ ] Padrão de commit respeitado (Conventional Commits, `feat:`).
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem (`next-16.md`) —
      nenhuma dependência nova adicionada ao `package.json`; SVG inline, sem lib de
      ícones (DEC-018-002); cor via token/`currentColor`, nunca literal de paleta
      (guideline de projeto, "Estilo").
- [ ] Code review aprovado.

## Riscos específicos

- **TRISK-018-001** (PLAN §8): comportamento de autofill/gerenciador de senha entre
  motores de navegador não é reproduzido por `jsdom` — o teste desta TASK cobre a
  interação simulada (clique/teclado), não o autofill real; resíduo de verificação manual
  aceito nesta fatia.
- **TRISK-018-002** (PLAN §8): `jsdom` não reproduz com fidelidade total o comportamento
  de foco do navegador real após ativação de um `<button>` por teclado — usar
  `@testing-library/user-event` (nunca `fireEvent` cru) para os casos de teclado, com
  asserção explícita via `document.activeElement`, é a mitigação já fixada no Critério
  AC-016-010 acima.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-07
**Data conclusão**: 2026-09-07
**Branch**: feat/campos-senha-toggle
**Commit SHA**: abbfea6 (fix pos-review; base a33a848)
**Jira**: KAN-79
**Implementado por**: developer
**Revisado por**: code-reviewer, product-designer
**Tentativas**: 2 (1 retry - 2 achados bloqueantes do code-reviewer + 2 de severidade alta do product-designer, todos corrigidos e reverificados por mutacao/CSS compilado na rodada 2)
**Cobertura final**: 8/8 ACs (AC-016-001 a 006 parte, 008, 010) - 8/8 testes, suite completa 24/243 sem regressao
**Arquivos modificados**:
  - src/components/password-field.tsx (novo)
  - src/components/password-field.test.tsx (novo)

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): n/a - sem I/O, sem endpoint, sem dado de sessão; toggle é atributo `type` client-side sobre input já existente
- [x] Comportamento (gate 9): n/a - ação síncrona local sem I/O (nota FR-016-003, decisão 4.67); todos os ACs desta TASK fecham por gate 1 (teste automatizado)

**Notas**:
