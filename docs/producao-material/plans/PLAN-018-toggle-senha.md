# PLAN-018: Toggle de mostrar/ocultar senha nos campos de senha

**Slug**: producao-material
**Status**: Done (sugerido)
**Versão**: 0.1
**Autor**: keelson (scribe)
**Data**: 2026-09-07

## Aderência a guidelines

**Ficha/perfil de linguagem**: frontend — Next 16 (`guidelines/project/frontend/next-16.md`;
Next.js 16.3.2 App Router · React 19.2 · TypeScript 6 `strict` · Tailwind 4 · Jest 30 +
Testing Library, `jsdom`). Esta fatia é só frontend (nenhum FR/NFR de SPEC-016 toca
`mnemonicos-backend`, §5 da SPEC — "sem par de leitura") — o perfil de backend
(`guidelines/project/backend/node-22.md`) não se aplica.

**Stack vigente herdado**: `'use client'` já em uso em `login-form.tsx:1` (padrão de client
component mínimo do guideline de projeto); `useState` local já em uso no mesmo arquivo para
`email`/`password`/`hasFailed`; Jest 30 + Testing Library + `jsdom`, molde de teste existente
colocado junto do componente (`src/components/login-form.test.tsx`, não em `tests/`); tokens
de tema em `@theme` de `globals.css` (sem arquivo de config JS). Nenhuma dependência nova
entra na árvore (DEC-018-002): o ícone é SVG inline, sem lib de ícones — confirmado por
leitura direta de `mnemonicos-frontend/package.json` (sem `dependencies`/`devDependencies`
de ícone hoje).

**Padrão arquitetural seguido**: guideline de projeto frontend (`README.md` §"Server e Client
Components", §"Estilo") — `'use client'` só onde há estado/evento, descendo ao componente
mais fundo possível (`PasswordField`, não o formulário inteiro — que já é client component
por outro motivo, login); componente não decide cor por conta própria, usa classes/tokens já
redefinidos sob `prefers-color-scheme` (nenhuma cor nova introduzida — o ícone herda
`currentColor`/classes já existentes, sem paleta própria).

**Decisões irreversíveis do slug tocadas**: nenhuma (`docs/producao-material/INDEX.md`,
seção "Decisões irreversíveis" — vazia; as 12 DECs de PLAN-003 são todas reversíveis).

**Decisões irreversíveis de outros slugs em conflito**: nenhuma — `docs/producao-material/
INDEX.md` é o único `INDEX.md` existente no workspace hoje (`docs/infra-vercel/` não tem
`INDEX.md`, único artefato ali é um brief avulso).

**Exceções aos guidelines**: nenhuma.

## Cobertura

**SPEC referenciada**: SPEC-016
**Slice declarado**: cobertura total restante (Caso D — nenhum PLAN anterior cobre esta SPEC)

**FRs cobertos**:
- FR-016-001, FR-016-002, FR-016-003, FR-016-004, FR-016-005, FR-016-006, FR-016-007

**NFRs cobertos**:
- NFR-016-001, NFR-016-002, NFR-016-003, NFR-016-004

**Cobertura agregada do slug**:
- Total na SPEC: 7 FRs + 4 NFRs = 11
- Cobertos por planos anteriores: 0
- Cobertos por este: 11
- Gap restante: 0

(SPEC-016 não declara FEATs — sem linha de funcionalidades cobertas.)

## 1. Visão técnica

Esta fatia extrai o campo de senha nu do `LoginForm` (`mnemonicos-frontend/src/components/
login-form.tsx`, linhas ~72-83) para um componente de apresentação reutilizável,
`PasswordField`, que passa a ser o único caminho idiomático para qualquer campo de senha do
sistema (FR-016-007) — hoje consumido só pelo `LoginForm`, amanhã por telas de cadastro/troca
de senha ainda não criadas (Q-016-001, fora de escopo). Nenhuma mudança de domínio, schema ou
backend: o estado de visibilidade é efêmero, local à interação de UI (nota "par de leitura",
SPEC-016 §5).

O desenho resolve três eixos, cada um por uma decisão desta execução (§6):

- **Onde vive o toggle e como não perder o valor** (DEC-018-001, DEC-018-004): `PasswordField`
  é controlado (recebe `value`/`onChange` do consumidor, como o campo de e-mail já existente),
  e só é dono do próprio estado de visibilidade (`useState<boolean>`) — nunca do valor
  digitado. Como o componente nunca desmonta durante o ciclo de submit-falha de `LoginForm`
  (`hasFailed` é um `useState` irmão, não uma condição de render do próprio campo), o estado de
  visibilidade sobrevive naturalmente a uma submissão recusada (AC-016-009), sem precisar ser
  elevado a um estado externo.
- **Como o ícone de olho é renderizado** (DEC-018-002): dois SVGs inline (olho aberto/fechado)
  escritos no próprio `password-field.tsx` — não há biblioteca de ícones instalada hoje
  (`package.json` confirmado), e instalar uma só para 2 ícones fixos é dependência nova
  desproporcional (OWASP A03:2025 Software Supply Chain Failures).
- **Como alternar `type` sem quebrar acessibilidade/submit** (DEC-018-003, DEC-018-005): botão
  `type="button"` com `aria-label` dinâmico e ordem de tabulação natural (sem `tabIndex={-1}`,
  aceito por NFR-016-003/veredito do PO), e atributos anti-canal (`name`, `autoComplete`,
  `spellCheck={false}`, `autoCorrect="off"`, `autoCapitalize="off"`) fixos independentemente do
  `type` corrente.

**Estratégia de teste**: `src/components/password-field.test.tsx` (novo, cobre AC-016-001 a
006, AC-016-008, AC-016-010 — estado inicial oculto, alternância por clique e por teclado,
rótulo acessível dinâmico, não-submissão, ausência de requisição/log novo, atributos
anti-canal em ambos os estados, foco após ativação por teclado) e extensão de
`src/components/login-form.test.tsx` (cobre AC-016-007 — os 7 casos existentes continuam
verdes, comportamento de login idêntico a SPEC-002 — e AC-016-009 — estado do toggle
sobrevive a uma submissão recusada). Colocação dos arquivos de teste junto do componente,
mesmo padrão já usado por `login-form.test.tsx`/`service-worker-registration.test.tsx`
(PLAN-013), não em `tests/components/`.

## 2. Stack e dependências

Nenhuma dependência nova (DEC-018-002). Reuso integral do que já existe em
`mnemonicos-frontend`:

| Peça | Origem |
|---|---|
| `'use client'` + `useState` | padrão já usado em `login-form.tsx` |
| Jest 30 + Testing Library + `jsdom`, `userEvent` | `jest.config.ts`/`login-form.test.tsx` existentes |
| Tokens de tema (`--surface`, cor via `currentColor`) | `globals.css` existente |
| TypeScript 6 `strict` | `tsconfig.json` existente |
| SVG inline (ícone de olho, 2 variantes) | markup próprio, sem lib — DEC-018-002 |

## 3. Componentes

### COMP-018-001: PasswordField
**Responsabilidade**: componente de apresentação `'use client'` que encapsula um
`<input>` de senha com controle de alternância de visibilidade (SVG inline, 2 variantes —
olho aberto/fechado), estado de visibilidade local (`useState<boolean>`, inicia `false` —
oculto, FR-016-002), rótulo acessível dinâmico no botão de alternância (`aria-label`),
operável por teclado nativo (`<button type="button">`, ordem de tabulação natural), e
atributos anti-canal fixos em ambos os estados de `type` (`spellCheck={false}`,
`autoCorrect="off"`, `autoCapitalize="off"`, mais `name`/`autoComplete` herdados via props).
Recebe `value`/`onChange` como props — controlado pelo consumidor, sem estado de valor
próprio (só a visibilidade é estado interno, DEC-018-001/DEC-018-004).
**Realiza**: FR-016-001, FR-016-002, FR-016-003, FR-016-004, FR-016-005, FR-016-006, FR-016-007, NFR-016-001, NFR-016-002, NFR-016-004
**Interface pública**: named export `PasswordField` em `mnemonicos-frontend/src/components/
password-field.tsx`. Props: `{ id: string; name: string; label: string; value: string;
onChange: (event: ChangeEvent<HTMLInputElement>) => void; autoComplete: string; required?:
boolean }`. Estado interno `const [visible, setVisible] = useState(false)`. O `<input>`
recebe `type={visible ? 'text' : 'password'}`, `spellCheck={false}`, `autoCorrect="off"`,
`autoCapitalize="off"`, e os atributos herdados (`name`, `autoComplete`, `required`). O botão
de alternância: `<button type="button" onClick={() => setVisible((v) => !v)} aria-label=
{visible ? 'ocultar senha' : 'mostrar senha'}>` com o SVG correspondente ao estado corrente.
Teste: `mnemonicos-frontend/src/components/password-field.test.tsx` (Testing Library,
`userEvent` para clique e teclado — mesmo padrão de `login-form.test.tsx`).
**Dependências**: nenhuma

### COMP-018-002: Integração do PasswordField no LoginForm
**Responsabilidade**: substituir o bloco `<label>...<input type="password" .../></label>`
nu de `LoginForm` (linhas ~72-83) pelo `PasswordField`, mantendo `email`/`password`/
`hasFailed`/`handleSubmit` inalterados — nenhum comportamento do fluxo de login (SPEC-002)
muda; o estado de visibilidade do toggle vive dentro do próprio `PasswordField` (montado uma
única vez, nunca desmontado por `hasFailed`), sobrevivendo naturalmente a uma submissão
recusada (AC-016-009) sem exigir estado elevado ao `LoginForm`.
**Realiza**: FR-016-001, FR-016-007, NFR-016-003
**Interface pública**: edição em `mnemonicos-frontend/src/components/login-form.tsx` — o
`<label>` do campo de senha passa a renderizar `<PasswordField id="password" name="password"
label="Senha" autoComplete="current-password" required value={password} onChange={(event) =>
setPassword(event.target.value)} />` no lugar do `<input type="password">` atual. Nenhuma
outra linha de `LoginForm` muda. Teste: extensão de `mnemonicos-frontend/src/components/
login-form.test.tsx` — os 7 casos existentes continuam intactos (sem alteração de contrato
observável do formulário) e 2 casos novos cobrem AC-016-007 (fluxo de login completo idêntico
a SPEC-002 com `PasswordField` aplicado) e AC-016-009 (estado de visibilidade sobrevive a uma
submissão recusada).
**Dependências**: COMP-018-001

## 4. Fluxos principais

**Fluxo de alternância** (AC-016-002/003/004/010): o usuário clica no ícone de olho, ou
navega até ele só por teclado (Tab) e o ativa (Enter/Espaço) → `setVisible` alterna o estado
interno de `PasswordField` → o `type` do `<input>` muda entre `password`/`text`, o ícone e o
`aria-label` do botão acompanham o novo estado, o valor digitado não é alterado → o foco
permanece no próprio botão (comportamento nativo do DOM ao ativar um `<button>`; nenhum
remount ocorre).

**Fluxo de não-submissão** (AC-016-005): o botão de alternância é `type="button"` dentro do
`<form method="post">` de `LoginForm` — ativá-lo (clique ou teclado) nunca dispara
`onSubmit`, mesmo com e-mail e senha preenchidos.

**Fluxo de persistência pós-falha** (AC-016-009): `handleSubmit` de `LoginForm` rejeita
(credencial inválida) → `setHasFailed(true)` → `LoginForm` re-renderiza exibindo a mensagem
genérica, mas `PasswordField` permanece montado na mesma posição da árvore → seu `useState
(visible)` local não é reinicializado → o campo continua exibindo o valor no estado
(oculto/visível) em que o usuário o deixou antes de submeter.

**Fluxo de login completo** (AC-016-007/008): inalterado em relação a SPEC-002 —
`PasswordField` só troca a apresentação (`type`) do mesmo `<input name="password">`; nenhuma
requisição, log/console ou estado de rede novo é introduzido pelo toggle, e o campo mantém
`name`/`autoComplete="current-password"` identificáveis pelo gerenciador de senha do
navegador em ambos os estados de visibilidade.

## 5. Modelo de dados

Não há modelo de dados novo — nenhuma mudança em `mnemonicos-backend`, nenhum model/coluna/
migração. O estado de visibilidade (oculto/texto plano) é efêmero, local à interação do
componente de UI, sem persistência em armazenamento, sessão ou backend — conforme a própria
nota "par de leitura" da SPEC (§5, decisão 4.225). Nenhuma superfície de API/schema é
verificada nesta fatia (item 9 da Etapa 4 do contrato de `/keelson:plan` — n/a, sem entidade
nova).

## 6. Decisões arquiteturais

### DEC-018-001: Componente de apresentação controlado (`PasswordField`), sem estado de valor próprio
**Contexto**: FR-016-007 exige um único componente reutilizável de campo de senha, usado por
`LoginForm` hoje e por telas futuras (Q-016-001) que ainda não existem. `LoginForm` já lê
`password` a cada tecla para compor o payload de `login({ email, password })`
(`login-form.tsx:42`).
**Decisão**: `PasswordField` é puramente de apresentação — recebe `value`/`onChange` como
props e não gerencia o valor do campo, só o estado de visibilidade (oculto/texto plano);
`LoginForm` continua dono do `useState(password)`.
**Alternativas consideradas**:
- Toggle escrito inline dentro de `LoginForm`, sem componente separado, descartada porque
  FR-016-007 exige um único componente reutilizável por qualquer campo de senha futuro —
  lógica inline no `LoginForm` não seria consumível por uma tela de cadastro/troca de senha
  futura sem duplicar a implementação inteira quando essa tela for criada.
- `PasswordField` não-controlado, com estado de valor interno próprio (ex.: `useRef`,
  expondo o valor só na submissão via `FormData`), descartada porque `LoginForm` precisa do
  valor a cada tecla, de forma síncrona, para compor o payload da mutation — um componente
  não-controlado exigiria refatorar esse acesso ao valor digitado (código que já funciona e
  está fora do escopo desta SPEC, NFR-016-003 proíbe regressão no fluxo de login).
**Consequências**: `PasswordField` fica trivialmente reusável em qualquer form futuro (basta
prover `value`/`onChange`, mesmo padrão do campo de e-mail já existente); em troca, cada
consumidor continua responsável pelo próprio `useState` do valor — sem ganho de
encapsulamento sobre isso, só sobre a visibilidade.
**Reabrir se**: um consumidor futuro precisar de um modo não-controlado (ex.: formulário sem
React state, `FormData` puro sem `useState`) — nenhum sinal disso hoje.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova (nenhuma DEC anterior do slug trata componente de campo de
senha).

### DEC-018-002: Ícone do toggle em SVG inline, sem biblioteca de ícones
**Contexto**: FR-016-001 exige um ícone de "olho" para o controle de alternância;
`mnemonicos-frontend/package.json` não tem hoje nenhuma biblioteca de ícones instalada
(confirmado por leitura direta do arquivo — nem em `dependencies` nem em `devDependencies`).
**Decisão**: dois SVGs inline (olho aberto/olho fechado) escritos diretamente em
`password-field.tsx`, sem dependência nova.
**Alternativas consideradas**:
- Instalar uma biblioteca de ícones (ex.: `lucide-react`, `@heroicons/react`), descartada
  porque soma uma dependência de terceiro nova — superfície de cadeia de suprimento a
  auditar e manter atualizada (OWASP A03:2025 Software Supply Chain Failures) — só para dois
  ícones fixos que nunca variam de estilo dinamicamente; custo de manutenção da árvore de
  dependências desproporcional ao ganho de um par de SVGs estáticos.
**Consequências**: zero dependência nova, controle total do markup (tamanho, `stroke`, cor
via `currentColor`/classe Tailwind já existente — sem paleta própria, guideline §Estilo); em
troca, se o sistema crescer para um conjunto maior de ícones, o padrão de SVG inline por
componente deixa de escalar e a decisão precisa ser reaberta.
**Reabrir se**: o sistema precisar de um conjunto de ícones maior (dezena ou mais) que
justifique o custo de manutenção de uma biblioteca dedicada — não é o caso hoje (2 ícones).
**Irreversível**: nao
**Aderência à ficha/perfil**: nova.

### DEC-018-003: Alternância de `type` via `useState` local, botão `type="button"` com tab-stop natural
**Contexto**: FR-016-003 exige alternar `type="password"`/`type="text"` sem perder foco ou
valor; FR-016-004/NFR-016-004 exigem que o controle nunca submeta o formulário; AC-016-010
exige que o foco permaneça no próprio controle após ativação por teclado; NFR-016-003
(resolução do PO) declara que o tab-stop extra do toggle não é regressão de acessibilidade.
**Decisão**: `useState<boolean>(false)` local a `PasswordField` guarda a visibilidade; o
botão de alternância é `<button type="button">` com `aria-label` dinâmico (FR-016-005) e
ordem de tabulação natural (sem `tabIndex={-1}`).
**Alternativas consideradas**:
- Alternar por CSS/truque de máscara visual sem trocar o `type` real do `<input>` (ex.:
  sobrepor/ocultar caracteres visualmente), descartada porque o gerenciador de senha do
  navegador e a tecnologia assistiva continuariam enxergando o campo como sempre mascarado
  — quebra NFR-016-001/NFR-016-002 (o campo precisa ser identificável corretamente em ambos
  os estados), além de não ter suporte consistente entre navegadores.
- `tabIndex={-1}` no botão de alternância, para retirá-lo da ordem de tabulação, descartada
  porque violaria diretamente FR-016-006/NFR-016-001 — e a resolução do PO em NFR-016-003 já
  declara explicitamente que o tab-stop extra não constitui regressão.
**Consequências**: implementação mínima, sem novo estado de rede/persistência; o foco após
clique ou ativação por teclado é o comportamento nativo do DOM (um `<button>` ativado mantém
o foco em si mesmo, sem `event.preventDefault()` que o desviasse) — nenhum código extra é
necessário para satisfazer AC-016-010.
**Reabrir se**: nunca — mecanismo padrão de qualquer toggle de senha acessível, sem condição
de mundo que o invalide.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova.

### DEC-018-004: Estado de visibilidade vive dentro do PasswordField, não elevado ao LoginForm
**Contexto**: AC-016-009 exige que o estado do toggle sobreviva a uma submissão recusada;
`LoginForm` não desmonta `PasswordField` em caso de falha — `hasFailed` é um `useState`
irmão que só condiciona a exibição da mensagem de erro, o `<form>` inteiro permanece montado
(`login-form.tsx:40-49,85-89`).
**Decisão**: o estado `visible` fica local a `PasswordField` (não elevado/"lifted" ao
`LoginForm` nem a um contexto/store). Como o componente nunca desmonta durante o ciclo de
submit-falha, o estado local sobrevive naturalmente, sem persistência externa.
**Alternativas consideradas**:
- Elevar o estado de visibilidade ao `LoginForm` (prop `visible`/`onToggle` controlada pelo
  pai), descartada porque adicionaria uma prop e um `useState` extra ao `LoginForm` só para
  replicar um comportamento (sobrevivência ao remount) que o React já garante de graça —
  nenhum caminho de código deste PLAN desmonta `PasswordField`, então o estado elevado não
  teria ganho algum, só mais uma peça a manter sincronizada entre os dois componentes.
**Consequências**: `PasswordField` fica mais autocontido (a visibilidade é um detalhe interno
de apresentação, não uma preocupação do consumidor); em troca, se um consumidor futuro
precisar forçar um estado de visibilidade a partir de fora (ex.: resetar ao trocar de tela
sem desmontar), esta decisão precisaria ser reaberta.
**Reabrir se**: um consumidor futuro precisar controlar a visibilidade de fora do componente
— nenhum caso concreto hoje (Q-016-001 não pede isso).
**Irreversível**: nao
**Aderência à ficha/perfil**: nova.

### DEC-018-005: Atributos anti-canal fixos, independentes do `type` corrente
**Contexto**: NFR-016-002 (ampliado pelo veredito do PO, SPEC-016 §6) exige que o campo
continue identificável como credencial pelo gerenciador de senha do navegador em ambos os
estados, e que nenhum canal de correção ortográfica/autocorreção do navegador seja aberto
pelo estado texto-plano.
**Decisão**: `name` e `autoComplete` (herdados via props, ex.: `autoComplete=
"current-password"`) e `spellCheck={false}`/`autoCorrect="off"`/`autoCapitalize="off"`
(fixos no próprio `PasswordField`) são aplicados ao `<input>` sempre, independentemente de
`visible` — nenhum desses atributos muda quando o `type` alterna.
**Alternativas consideradas**:
- Aplicar `spellCheck`/`autoCorrect`/`autoCapitalize` só quando `type="text"` (já que
  `type="password"` já é nativamente imune a esses canais em todo navegador), descartada
  porque introduziria uma ramificação condicional sem benefício observável (os atributos são
  inertes, mas inofensivos, sob `type="password"`) e aumentaria o risco de regressão futura
  caso a condição seja removida por engano — manter os três atributos sempre presentes é mais
  simples e mais seguro por padrão.
**Consequências**: um único bloco de atributos fixos no `<input>`, sem condicional a auditar;
nenhum custo observável (os atributos são no-op quando já cobertos nativamente por
`type="password"`).
**Reabrir se**: nunca — atributos estáticos, sem custo a economizar com uma condicional.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova.

## 7. Mapeamento FR -> componente

| FR | Componente | AC cobertos |
|----|------------|-------------|
| FR-016-001 | COMP-018-001, COMP-018-002 | AC-016-002 |
| FR-016-002 | COMP-018-001 | AC-016-001 |
| FR-016-003 | COMP-018-001 | AC-016-002 |
| FR-016-004 | COMP-018-001 | AC-016-005 |
| FR-016-005 | COMP-018-001 | AC-016-003 |
| FR-016-006 | COMP-018-001 | AC-016-004, AC-016-010 |
| FR-016-007 | COMP-018-001, COMP-018-002 | AC-016-006 |
| NFR-016-001 | COMP-018-001 | AC-016-004, AC-016-010 |
| NFR-016-002 | COMP-018-001 | AC-016-008 |
| NFR-016-003 | COMP-018-002 | AC-016-007, AC-016-009 |
| NFR-016-004 | COMP-018-001 | AC-016-005 |

## 8. Riscos técnicos

- **TRISK-018-001** Comportamento de autofill/gerenciador de senha varia entre motores de
  navegador (Chrome/Firefox/Safari) quanto a como um valor preenchido automaticamente reage
  à troca de `type` de um input controlado por React em tempo real — padrão conhecido de
  atrito entre autofill nativo e inputs controlados. Mitigação: aceito nesta fatia (mesmo
  raciocínio de A-016-006 da SPEC — revelar autofill é aceitável); o teste automatizado
  cobre o comportamento do componente sob interação simulada (Testing Library/`jsdom`), não
  o autofill real do navegador — resíduo de verificação manual, mesma classe de RISK-016-001
  (conformidade automatizada, não caminhada real em dispositivo/navegador).
- **TRISK-018-002** `jsdom` não reproduz com fidelidade total o comportamento de foco do
  navegador real após clique/ativação de teclado em um `<button>` aninhado dentro de um
  `<label>` — um teste ingênuo com `fireEvent` poderia dar falso-positivo em AC-016-010 (foco
  permanece no controle). Mitigação: usar `@testing-library/user-event` (já presente na
  suíte, `login-form.test.tsx` já o adota) para os casos de teclado, com asserção explícita
  via `document.activeElement` — sem depender de inspeção manual.

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs — FR-016-001 a FR-016-007.
- [ ] Todos os NFRs cobertos têm verificação — NFR-016-001 a NFR-016-004.
- [ ] Decisões DEC refletidas no código — DEC-018-001 a DEC-018-005.
- [ ] Aderência à ficha/perfil validada (guideline de projeto frontend + perfil `next-16.md`).
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates) — AC-016-001 a AC-016-010,
      via `password-field.test.tsx` (novo) + extensão de `login-form.test.tsx`.
- [ ] Métrica da SPEC operacional (§1.3: `Fonte de medição: instrumentação — suíte de teste
      automatizado ... cobrindo os ACs desta SPEC`, dono Tech Lead/QA) — a mesma suíte do
      item anterior (`password-field.test.tsx` + extensão de `login-form.test.tsx`) é a
      própria fonte de medição desta métrica de conformidade; não há evento de runtime
      distinto a instrumentar (natureza de conformidade verde/vermelha, não contagem). Item
      satisfeito quando a suíte cobre os 10 ACs e roda verde no fecho do ciclo.

## 10. Não coberto por este PLAN

- Telas de cadastro e troca de senha (Out-of-scope, SPEC-016 §4.2) — a capacidade já existe
  na API/hooks RTK Query, sem UI consumidora; fica para um PLAN/brief futuro que criar essas
  telas, reusando `PasswordField` (Q-016-001).
- Prova de acessibilidade por caminhada real com leitor de tela em dispositivo (RISK-016-001)
  — esta fatia prova por atributo (rótulo acessível, ordem de tabulação) via teste
  automatizado, mesma postura das demais SPECs deste slug.
- Comportamento de autofill/gerenciador de senha em navegador real, entre os três motores
  principais (TRISK-018-001) — resíduo de verificação manual, fora do alcance de `jsdom`.
- Posição exata do caret/cursor de texto ao trocar `type` do input (A-016-005, SPEC-016) —
  comportamento best-effort do navegador, não é objeto de AC.
- Encaminhamento de foco/clique de um `<button>` aninhado em `<label>` entre motores de
  navegador reais (Safari/Firefox vs. Chrome) — achado do QA pré-código (Etapa 3.5):
  `jsdom` prova AC-016-010 por simulação (`userEvent` + `document.activeElement`), não por
  caminhada real; mesma classe de RISK-016-001/TRISK-018-001 (conformidade automatizada).
