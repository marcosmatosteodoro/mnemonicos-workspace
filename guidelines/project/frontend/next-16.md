---
lang: next
version: "16"
charter: 0.5.1
generated-by: staff-engineer
reviewed: false
---

# Next 16 + React 19 — Perfil de linguagem (frontend)

> Instância do `QUALITY-CHARTER.md` (v0.5.1) para a stack de frontend deste projeto:
> **Next.js 16.3.2 (App Router · Turbopack) · React 19.2 · TypeScript 6 · Tailwind 4 ·
> Redux Toolkit 2 + RTK Query · Jest 30 + Testing Library · ESLint 9 (flat config)**.
>
> ⚠️ **`reviewed: false`** — perfil **gerado** (`staff-engineer`), não curado. Toda
> afirmação de segurança que não pôde ser confirmada com alta confiança carrega a tag
> inline `⚠️ não confirmado`; o roteiro de conferência humana mora no companheiro
> [`_review/next-16.md`](_review/next-16.md).
>
> **Precedência:** este perfil cobre o **idiomático geral** da stack. As decisões
> **específicas desta aplicação** (Server Component como default e onde desce o
> `'use client'`, o corte entre RTK Query e slice, `makeStore()` como função, tokens no
> `@theme`, mapa de rótulos pt-BR em `domain.ts`, gate `screenVerify`) moram em
> [`README.md`](README.md) — e **em conflito, o README vence este perfil**.
>
> **Superfície ainda inexistente.** Hoje a aplicação não tem Route Handler, Server Action,
> autenticação nem upload. As regras destas superfícies estão aqui **antes** de existirem,
> porque a primeira vez que alguém escrever um `route.ts` é tarde para descobri-las.

---

## 1. Identidade & versão

O alvo é **Next.js 16.3.2** (pin exato no `package.json`, sem `^`) com **App Router**,
**Turbopack** como bundler de `dev` e `build`, **React 19.2.8** (também pinado) e
**TypeScript 6.0** em `strict` + `noUncheckedIndexedAccess`, `moduleResolution: bundler`,
`jsx: react-jsx`, alias `@/*` → `./src/*`. Estilo por **Tailwind 4.3** com configuração
**no CSS** (`@theme`), via `@tailwindcss/postcss`.

`next` e `eslint-config-next` estão pinados na **mesma versão** de propósito: o config de
lint acompanha a major/minor do framework. Suba os dois juntos, num commit só.

**Recursos desta versão que se DEVE preferir:**

| Recurso | Uso | Desde |
|---|---|---|
| Server Components (default) | buscar dado no servidor e enviar HTML/RSC payload, sem custo de bundle | Next 13 |
| `async`/`await` direto no componente servidor | substitui `getServerSideProps`/`useEffect`+`fetch` | Next 13 |
| `loading.tsx` + `<Suspense>` | estado de carregamento **streamado**, sem flag `isLoading` manual | Next 13 |
| `error.tsx` / `global-error.tsx` / `not-found.tsx` | fronteira de erro declarativa por segmento | Next 13 |
| Metadata API (`export const metadata` / `generateMetadata`) | `<title>`/OG sem `next/head` | Next 13 |
| `next/link`, `next/image`, `next/font` | prefetch, otimização de imagem e fonte sem CLS | ≤14 |
| `proxy.ts` (ex-`middleware.ts`) rodando em **Node.js** | borda de rede com acesso a APIs Node | **16** |
| `use cache` + `cacheLife`/`cacheTag` (flag `cacheComponents`) | cache **explícito**; o default do 16 é dinâmico | **16** |
| `useActionState`, `useFormStatus`, `useOptimistic`, `<form action={fn}>` | mutação com estado pendente/otimista sem reducer manual | React 19 |
| `use(promise)` / `use(context)` | ler promise ou contexto em client component | React 19 |
| `ref` como prop comum (sem `forwardRef`) | componente que encaminha ref | React 19 |
| `<Ctx value={...}>` como provider (sem `.Provider`) | contexto | React 19 |
| `useId`, `useTransition`, `useDeferredValue` | id estável em SSR, atualização não bloqueante | ≤19 |
| `useEffectEvent`, `<Activity>`, `cacheSignal` | efeito com callback estável; esconder UI preservando estado | React **19.2** |
| `combineSlices`, `selectors` no `createSlice`, `withTypes` | store tipada sem boilerplate | RTK 2 |
| RTK Query (`createApi` + `fetchBaseQuery`) | estado de servidor no cliente: cache, tags, `isLoading` | RTK ≥1.6 |
| `@theme` / `@utility` / `@variant` no CSS | tokens e utilitários — **sem** `tailwind.config.js` | Tailwind 4 |

**O que NÃO existe / NÃO DEVE mais aparecer nesta versão:**

- **Pages Router** e tudo dele: `pages/`, `getServerSideProps`, `getStaticProps`,
  `getInitialProps`, `next/head`, `next/router` (`useRouter` vem de `next/navigation`),
  `_app.tsx`, `_document.tsx`. A base é App Router — não misture os dois modelos.
- **`middleware.ts`** — renomeado para `proxy.ts` (export `proxy`, não `middleware`).
- **`next lint`** — removido; o lint é a CLI do ESLint (`eslint .`), como já está aqui.
- **Acesso síncrono** a `params`, `searchParams`, `cookies()`, `headers()`, `draftMode()`:
  todos são **assíncronos** e exigem `await`. O acesso síncrono foi **removido** no 16.
- **Config de webpack** — `next build` **falha** ao detectar `webpack` no
  `next.config.ts` (saída de emergência: `--webpack`). Loader de webpack caseiro morreu.
- **AMP**, `next/legacy/image`, `@next/font` (é `next/font`), `experimental_ppr`,
  prefixos `unstable_*` que viraram estáveis.
- **De React ≤18:** `forwardRef` por obrigação, `propTypes`/`defaultProps` em componente
  de função, refs por string, `ReactDOM.render`/`hydrate`, `react-dom/test-utils.act`
  (é `act` de `react`), `useFormState` (é `useActionState`), `React.FC` (não tipa
  `children` mais e atrapalha genéricos).
- **`tailwind.config.js`**, `@tailwind base/components/utilities`, `theme()` em CSS
  (use `var(--color-*)`), `tailwindcss` como plugin direto do PostCSS (é
  `@tailwindcss/postcss`).
- **De Redux pré-RTK:** `createStore`, action type como string solta, `connect`/`mapState`,
  reducer com `switch` e spread manual, `redux-thunk` importado à mão (já vem),
  imutabilidade manual (o Immer do `createSlice` cuida).
- **`any` explícito ou implícito**, `as` para calar o compilador, `@ts-ignore` (se
  inevitável: `@ts-expect-error` **com o motivo na linha acima**).
- **`enum` do TypeScript**: o padrão da base é `as const` + união de literais
  (`MNEMONIC_TECHNIQUES` / `MnemonicTechnique` em `src/types/domain.ts`).

---

## 2. Estilo, formatação & lint → Charter Art. 5, 7

**Formatação é do Prettier, não do gosto de ninguém.** `.prettierrc.json` versionado
(`singleQuote`, `semi`, `trailingComma: all`, `printWidth: 100`, `tabWidth: 2`,
`arrowParens: always`, `endOfLine: lf`) + `.editorconfig`. O plugin
**`prettier-plugin-tailwindcss`** ordena as classes utilitárias e lê os tokens de
`tailwindStylesheet: './src/app/globals.css'` — discussão sobre ordem de classe em review
é ruído: `prettier --write` decide.

**Lint é o ESLint 9 em flat config** (`eslint.config.mjs`, ESM, na raiz do
`mnemonicos-frontend`), composto assim e **nesta ordem**:

1. `globalIgnores(['.next/**', 'out/**', 'build/**', 'coverage/**', 'next-env.d.ts'])` —
   artefato de build nunca é lintado;
2. `eslint-config-next/core-web-vitals` — regras do framework **com** as de Core Web Vitals
   promovidas a erro;
3. `eslint-config-next/typescript` — camada TS;
4. bloco de regras da casa (`no-unused-vars` com `^_` isento, `no-console` permitindo
   `warn`/`error`, `eqeqeq: smart`);
5. bloco de globals para arquivos de teste;
6. **`eslint-config-prettier/flat` por último** — desliga o que conflita com o formatter.

Regras que mais importam nesta stack:

| Regra | Por quê |
|---|---|
| `react-hooks/rules-of-hooks` | hook em condicional/laço corrompe a ordem de hooks — é bug de runtime, não estilo |
| `react-hooks/exhaustive-deps` | dependência faltando em `useEffect` = closure velha, dado obsoleto na tela |
| `@next/next/no-img-element` | `<img>` cru perde otimização, `sizes` e prevenção de CLS → `next/image` |
| `@next/next/no-html-link-for-pages` | `<a href="/rota">` faz full reload e joga fora o roteamento no cliente |
| `@next/next/no-sync-scripts` | script síncrono bloqueia o parse — mata LCP |
| `@next/next/no-head-element` / `no-page-custom-font` | Metadata API e `next/font` são o caminho |
| `eqeqeq: smart` | `==` só contra `null` (cobre `undefined`) |
| `no-console` (**warn**) | `console.log` sobrevive até produção e vaza no DevTools do usuário |

**O que bloqueia:** no `pre-commit` (husky + lint-staged) tudo bloqueia — o comando é
`eslint --fix --max-warnings=0`, então **aviso reprova igual a erro**. Já o gate de
qualidade roda `npm run lint` = `eslint .` **sem** `--max-warnings=0`: hoje um
`console.log` passa pelo gate e é barrado só no commit. Assimetria conhecida — se o gate
deve reprovar aviso, é `quality.lint` que precisa mudar (§12).

**Comandos:** `npm run lint` (= `eslint .` — flat config descobre os arquivos, **não** use
`--ext`), `npm run format:check` (= `prettier --check .`), `npm run validate` para o
conjunto.

**Armadilha comum (gate):** rodar `eslint --fix` / `prettier --write` **no gate**. O gate
**reprova**; quem corrige é o autor (ou o hook do husky). Gate que conserta esconde que a
entrega saiu fora do padrão.

**Armadilha comum (lint verde, tela quebrada):** o ESLint **não** vê hidratação, tamanho de
bundle nem acessibilidade real. Lint limpo não substitui `screenVerify` (README) nem o
teste do Art. 1.

---

## 3. Nomenclatura & idioma → Charter Art. 5

| Símbolo | Convenção | Exemplo |
|---|---|---|
| Componente React | `PascalCase` | `TechniqueCard`, `SiteHeader`, `ApiStatus` |
| Arquivo de componente | `kebab-case.tsx` (nome do componente em kebab) | `technique-card.tsx` |
| Props do componente | `interface <Componente>Props`, exportada quando reusada | `TechniqueCardProps` |
| Hook | `use` + verbo/substantivo, `camelCase` | `useAppSelector`, `useListMnemonicsQuery` |
| Slice / arquivo de slice | `<domínio>-slice.ts`, `name` igual ao ramo do estado | `study-slice.ts` → `study` |
| Action do slice | **fato no passado**, `camelCase` | `sessionStarted`, `cardRated`, `answerRevealed` |
| Selector | `select` + o que devolve | `selectCurrentCard`, `selectIsFinished` |
| Endpoint RTK Query | verbo + recurso; o hook é gerado | `listMnemonics` → `useListMnemonicsQuery` |
| Constante de módulo | `UPPER_SNAKE_CASE` | `TECHNIQUES`, `MNEMONIC_TECHNIQUE_LABELS` |
| Tipo / união de literais | `PascalCase`, **sem** prefixo `I` | `MnemonicTechnique`, `Paginated<T>` |
| Handler local | `handle` + evento | `handleReveal`, `handleSubmit` |
| Prop de callback | `on` + evento | `onReveal`, `onRate` |
| Booleano | predicado | `isAnswerRevealed`, `hasSession`, `shouldPrefetch` |
| Arquivo de convenção do Next | **nome reservado, minúsculo** | `page.tsx`, `layout.tsx`, `route.ts` |
| Teste | `<alvo>.test.ts(x)` em `tests/` espelhando `src/` | `technique-card.test.tsx` |

**Action nomeia o fato, não o setter.** `cardRated(rating)` diz o que aconteceu no domínio;
`setCurrentIndex(n)` transfere a regra para quem despacha e espalha decisão pela árvore.

**Nome revela efeito colateral (Art. 5).** Um hook chamado `useDisciplines()` que também
dispara analytics ou grava `localStorage` surpreende quem chama — separe ou renomeie.
Componente cujo nome não diz que faz *fetch* (`<TechniqueCard>` que busca dado) é a mesma
violação em outra roupa: quem busca é a página/servidor, quem apresenta recebe por prop.

**Idioma:** identificadores, nomes de arquivo e tipos em **inglês**; todo texto que o
usuário lê em **pt-BR** (`lang="pt-BR"` no `<html>`), com o rótulo de valor de domínio
saindo do mapa de `src/types/domain.ts` — regra do [`README.md`](README.md). Comentários em
**pt-BR**, consistentes com a base. Não misture idioma dentro do mesmo arquivo.

**Comentário e JSDoc (Art. 7):** em TSX a assinatura e o JSX **já contam o *como***. O teste
é único: *apagá-lo perde informação que o código não devolve?*

- **Perde → DEVE existir.** O invariante que o tipo não expressa (o comentário de
  `isAnswerRevealed` em `study-slice.ts`: *"o gesto de tentar lembrar antes de ver é o que
  gera retenção"* — o tipo diz `boolean`, o comentário diz **por que existe**); o porquê de
  uma decisão de arquitetura com âncora (`DEC-03`, `FR-07`) — como o comentário de
  `useState(makeStore)` em `providers.tsx`, que registra o vazamento de estado no SSR que o
  singleton causaria; a armadilha e a condição de remoção; o caminho tentado que falhou.
- **Não perde → NÃO DEVE existir.** `// componente do cartão` acima de `TechniqueCard`,
  `@param props`, `{/* header */}` acima de `<header>`, cabeçalho ritual por arquivo.

**O que não é comentário e carrega semântica:** `role`, `aria-live`, `aria-hidden`, `alt`.
Estes são **contrato com o leitor de tela** e com o teste (`getByRole`) — não os remova
tratando como decoração, e não os invente sem necessidade (`role="button"` num `<button>` é
ruído).

---

## 4. Estrutura & arquitetura → Charter Art. 4, 7

A fronteira arquitetural mais importante desta stack **não é** uma pasta: é a linha
**servidor/cliente**. Ela decide o que vai para o bundle, o que pode ler segredo e o que
pode ter estado.

```
src/app/**        rotas: page/layout (servidor por default) — composição e busca de dado
src/components/** apresentação reusável; 'use client' só no que tem estado/evento
src/store/**      estado do cliente: api.ts (RTK Query) + slices + hooks tipados
src/lib/**        adaptadores e utilidades puras (env, formatação) — sem JSX
src/types/**      contrato de domínio compartilhado com o backend
tests/**          provas, espelhando a estrutura de src/
```

**Convenções de arquivo do App Router** (nome reservado — não os use para outra coisa):

| Arquivo | Papel | Cuidado |
|---|---|---|
| `page.tsx` | rota acessível publicamente | só `page` cria URL; componente solto na pasta não vira rota |
| `layout.tsx` | shell que **persiste** entre navegações de filhos | não re-executa por navegação do filho — nunca ponha aqui checagem que precisa rodar a cada request (§6.3) |
| `template.tsx` | como layout, mas **remonta** por navegação | use quando o estado deve zerar |
| `loading.tsx` | fallback de `<Suspense>` do segmento | é o que torna o streaming visível |
| `error.tsx` | error boundary do segmento (**client**, recebe `reset`) | não captura erro do layout do mesmo nível |
| `global-error.tsx` | boundary do root layout (substitui `<html>`) | último recurso |
| `not-found.tsx` | par de `notFound()` | 404 semântico, não redirect |
| `route.ts` | Route Handler (API) | **não coexiste** com `page.tsx` no mesmo segmento |
| `(grupo)` · `_pasta` · `[slug]` · `[...all]` · `@slot` | agrupamento sem URL · pasta privada · dinâmico · catch-all · slot paralelo | `(grupo)` não aparece na URL; `_pasta` nunca vira rota |

**Regras de dependência:**

| Unidade | PODE conter | NÃO PODE conter |
|---|---|---|
| `page.tsx` / `layout.tsx` (servidor) | busca de dado, composição, `metadata` | `useState`/`useEffect`, handler de evento, `window` |
| componente `'use client'` | estado, efeito, evento, hooks do RTK Query | segredo, import de módulo servidor, `fs`/`node:*` |
| `src/store/*` | cache de servidor (RTK Query) e estado de UI (slice) | JSX, `window` no corpo do módulo |
| `src/lib/*` | função pura, leitura de env pública, adaptador | JSX, dependência de React |
| `src/types/*` | tipos e mapas de rótulo | lógica, I/O |

> O corte **específico deste projeto** entre RTK Query (estado do servidor) e slice (estado
> só-do-cliente), e o `makeStore()` como função, estão normatizados no
> [`README.md`](README.md). Aqui interessa a **propriedade idiomática**: um componente de
> apresentação não sabe de onde vem o dado, e o componente que sabe não desenha.

**`'use client'` é uma fronteira, não uma anotação.** A diretiva marca o **ponto de entrada**
do grafo cliente: tudo que ela importa vai para o bundle do browser, transitivamente. Daí a
regra: **desça a diretiva ao componente mais fundo possível** e, quando um pedaço interativo
precisa envolver conteúdo estático, passe esse conteúdo como **`children`** — children de um
client component podem ser renderizados no servidor:

```tsx
// ✅ o painel é client (tem estado); o conteúdo continua sendo renderizado no servidor
<CollapsiblePanel title="Revisão de hoje">
  <DueCardsList />           {/* Server Component */}
</CollapsiblePanel>
```

**Isolamento de efeito colateral (Art. 4) — a forma idiomática em React é o parâmetro/prop,
não a interface.** Não crie `IClock`/`IRepository`; injete o valor.

```tsx
// ✅ pura: o teste fixa o tempo
export function sessionSummary(ratings: Record<string, ReviewRating>, now: Date): Summary

// ❌ lê o relógio por dentro: o teste vira refém de fake timers
export function sessionSummary(ratings: Record<string, ReviewRating>): Summary
```

`new Date()`, `Math.random()`, `crypto.randomUUID()` e `Intl` com locale implícito **no
corpo do render** são, além de impuros, a causa nº 1 de **erro de hidratação** (§11).

**Agrupamento de parâmetros (Art. 4):** o objeto de props **já é** o objeto de parâmetro
idiomático — nomeie-o (`TechniqueCardProps`) e desestruture na assinatura. A partir de ~5
props soltas, ou quando duas têm o mesmo tipo (`(front: string, back: string)` — trocar a
ordem compila e mente), agrupe num tipo de domínio (`card: Flashcard`).

**Condicionais (Art. 7):** *guard clause* com `return` cedo — inclusive no JSX:

```tsx
if (isLoading) return <SkeletonList />;
if (isError) return <ErrorNotice onRetry={refetch} />;
if (cards.length === 0) return <EmptyState />;
return <CardList cards={cards} />;
```

Ternário aninhado em JSX é dívida imediata (o `isLoading ? … : isError ? … : …` de
`api-status.tsx` está no limite aceitável: dois níveis, valores literais). Despacho repetido
pela mesma variante pede **mapa de literal → valor/componente**, não `if` em cascata:

```ts
const RATING_TONE: Record<ReviewRating, string> = { AGAIN: 'text-red-500', /* … */ };
```

`switch` exaustivo sobre união de literais + `assertNever(default)` deixa o compilador
garantir que nenhuma variante ficou de fora.

**Padrões: a construção idiomática vem antes do padrão clássico.**

| Padrão clássico | Forma idiomática em React 19 / Next 16 |
|---|---|
| HOC (`withX`) | **hook** customizado; para envolver marcação, componente com `children` |
| Render props | `children` / prop de composição — antes de função como filho |
| Container/Presentational | Server Component busca + Client Component apresenta: a divisão já é da plataforma |
| Observer / pub-sub | estado no slice + `useAppSelector`; `useSyncExternalStore` para fonte externa real |
| Singleton | módulo é singleton — mas **store, não**: `makeStore()` (README) |
| Strategy | objeto `as const` mapeando literal → função/componente |
| Factory | função `createX()`; para componente, variantes por prop tipada |
| Facade sobre `fetch` | `createApi` do RTK Query **já é** — não escreva outro cliente HTTP |
| Memoização manual | `createSelector` (RTK) para derivação; `useMemo`/`memo` só com medição (§10) |
| Injeção de dependência | props e contexto; container DI não tem lugar aqui |

**Armadilhas nesta stack:**

- **`'use client'` no `layout.tsx`** (ou na página inteira) — arrasta a árvore toda para o
  browser e apaga o benefício de RSC. Sintoma: bundle da rota cresce sem motivo aparente.
- **`useEffect` para buscar dado** — é *waterfall* de rede, duplica o que o RTK Query e o
  Server Component fazem melhor, e roda duas vezes em dev (StrictMode).
- **`useEffect` para derivar estado** de props/estado — derive no render ou num selector.
- **Barrel file** (`index.ts` reexportando a pasta) importado por client component: puxa
  módulos irmãos para o bundle e cria ciclos. Importe o arquivo direto.
- **`export default`** para componente reusável — dificulta refactor/renomeio automático; a
  base usa named exports, exceto onde o Next **exige** default (`page`, `layout`, `error`).
- **Estado duplicado**: mesmo dado no cache do RTK Query e num slice (README) — é a origem da
  tela mostrando dado velho.
- **Prop drilling de 4+ níveis**: sintoma de fronteira errada, não de falta de contexto.
- **`window`/`document` no corpo do módulo** de um client component: o módulo é avaliado no
  servidor durante o SSR e estoura. Acesse dentro de `useEffect` ou guarde com
  `typeof window !== 'undefined'`.

---

## 5. Gestão de erro → Charter Art. 2, 7

**Erro em frontend tem três origens distintas, e cada uma tem sua fronteira:** render
(boundary), rede (estado do RTK Query), interação (handler/action).

**1. Render — `error.tsx` por segmento.** É um Client Component que recebe
`{ error, reset }`. Coloque-o no segmento mais **próximo** do que pode falhar: um
`error.tsx` só no root transforma qualquer falha numa página inteira de erro.
`global-error.tsx` é o último recurso (substitui o root layout, logo precisa de `<html>` e
`<body>`). Error boundary **não** captura: erro em handler de evento, rejeição de promise
assíncrona, nem erro durante o SSR do root layout.

**2. Rede — o estado é dado, não exceção.** RTK Query devolve
`{ data, isLoading, isError, error }`; o `error` é `FetchBaseQueryError | SerializedError`.
Estreite antes de ler:

```ts
function isFetchError(e: unknown): e is FetchBaseQueryError {
  return typeof e === 'object' && e !== null && 'status' in e;
}
```

`try/catch` em volta de `useQuery` **não** faz nada — o erro nunca é lançado.

**3. Interação — `unwrap()` explícito.** `dispatch(mutation(args))` devolve um objeto que
**não** rejeita; `.unwrap()` rejeita e permite `try/catch`. Ignorar o resultado da mutação é
o *fire and forget* silencioso: a UI diz "salvo" e nada foi salvo.

**Nunca engolir:**

- `catch {}` vazio, `.catch(() => null)` sem comentário do porquê;
- promise pendurada em handler (`onClick={() => save()}` com `save` async que pode rejeitar);
- `error.tsx` que mostra "algo deu errado" e **não** reporta em lugar nenhum — o erro deixa
  de existir para quem mantém o sistema (Charter Art. 2, categoria A09).

**Fail secure (Art. 2):** no `catch`, o default é **negar/esconder**. Falhou a checagem que
decidiria mostrar um recurso restrito → não mostre. `catch { return true }` num leitor de
permissão é vulnerabilidade com cara de robustez — e, no frontend, esconder nunca substitui
a checagem no servidor (§6.3).

**Fronteira de mensagem: uma só, e ela é pt-BR e genérica.** A mensagem que o usuário lê é
escrita **aqui**, no frontend, a partir do `status`; **nunca** é o `error.message` do backend
renderizado cru. A mensagem do backend pode citar tabela, coluna, host ou stack — e, se um
dia vier HTML dentro dela, renderizá-la com `dangerouslySetInnerHTML` fecha o circuito do
XSS (§6.2).

**O que logar, e onde:** o console do browser é **visível ao usuário** e o `console.error` de
produção acaba em ferramenta de terceiro. Logue **código de erro e rota**, nunca token,
cookie, corpo de resposta cru, e-mail ou qualquer PII. Erro lançado no servidor (Server
Component, Route Handler) tem sua mensagem **substituída por um digest** em produção pelo
próprio Next — a mensagem real fica no log do servidor. ⚠️ não confirmado

---

## 6. Segurança mapeada à linguagem → Charter Art. 2 `[CRÍTICA]`

> Cada subseção é um item da **Régua do Art. 2** traduzido para "como se faz e como se erra
> nesta stack". Achado aqui é **rejeição imediata** no review.
>
> Tag `⚠️ não confirmado` = afirmação que este perfil **infere** e que o revisor humano
> precisa validar (roteiro em [`_review/next-16.md`](_review/next-16.md)).
>
> **Premissa de fundo:** o frontend **não é** o guardião. Toda regra de acesso vive no
> `mnemonicos-backend`; o que se faz aqui é (a) não abrir vetor novo no browser e (b) não
> transformar a conveniência do App Router em autorização de mentira.

### 6.1 Injeção → sempre parametrizar

Não há SQL neste repositório — o banco é do backend. As superfícies de injeção aqui são
**URL, HTML e código**:

```ts
// ❌ concatenação de entrada na URL: o valor pode conter & = # e escapar do parâmetro
const url = `/api/v1/mnemonics?topic=${topicId}&q=${search}`;

// ✅ o RTK Query serializa params; fora dele, URLSearchParams
query: (args) => ({ url: '/mnemonics', params: args ?? undefined }),
```

- **Parâmetro de query**: use o campo `params` do `fetchBaseQuery` (que serializa e escapa)
  ou `new URLSearchParams`. Que o `fetchBaseQuery` faça encoding completo de valor com
  `&`/`=`/`#` precisa ser confirmado. ⚠️ não confirmado
- **Segmento de path**: `encodeURIComponent(id)` — um `id` com `../` ou `?` reescreve a rota
  chamada.
- **Código como dado é proibido**: `eval`, `new Function`, `setTimeout('string')`,
  `JSON.parse` de texto que não veio da API, `<script>` montado com dado de usuário
  (inclusive via `next/script` com `dangerouslySetInnerHTML`).
- **Se algum dia existir Route Handler ou Server Action** falando com banco/shell: as regras
  do perfil de backend valem inteiras (consulta parametrizada, `execFile` com array,
  allowlist para identificador). O `route.ts` é backend morando no repositório do frontend —
  não herda inocência do vizinho.
- **Validação na fronteira**: entrada de Server Action ou Route Handler é **não confiável** e
  atravessa um schema (Zod) antes de qualquer uso. Tipo de TypeScript **não valida nada em
  runtime** — `formData.get('rating') as ReviewRating` é uma mentira compilada.

### 6.2 Saída / escaping → escapar no destino

**React escapa `{expressão}` em nó de texto por padrão** — é a razão pela qual XSS é raro
aqui, e a razão pela qual as exceções são tão perigosas:

- **`dangerouslySetInnerHTML` é proibido com dado que veio de fora** (API, URL, storage). O
  corpo do mnemônico é texto do usuário: renderize como texto. Se um dia for preciso rich
  text, a decisão vai para uma DEC e a sanitização é biblioteca dedicada (DOMPurify) no
  ponto de renderização — **nunca** regex caseira, e nunca sanitização feita só no servidor
  "confiando" que o cliente não altera.
- **URL é contexto próprio.** `href`/`src`/`action` com string do usuário aceita
  `javascript:` e `data:text/html`. Regra: allowlist de protocolo (`https:`, `mailto:`, ou
  path relativo) **antes** de renderizar. A crença é que o React 19 bloqueie `javascript:`
  em `href`, mas o comportamento exato (erro, remoção silenciosa ou apenas aviso em dev)
  precisa ser confirmado — e a validação própria não depende disso. ⚠️ não confirmado
- **Atributo/estilo:** nunca monte `className` ou `style` concatenando entrada do usuário
  (`style={{ background: userColor }}` permite injetar `url(...)` e, no mínimo, quebra o
  layout). Cor/variante vem de mapa de literal → token (§4).
- **`target="_blank"`** exige `rel="noopener noreferrer"` em link externo (o React já
  adiciona `noopener` em alguns casos — não conte com isso).
- **Cabeçalhos de resposta:** `next.config.ts` já envia `X-Content-Type-Options: nosniff`,
  `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin` e uma
  `Permissions-Policy` restritiva, com `poweredByHeader: false`. **Não há CSP** — e é a
  defesa em profundidade que mais falta. CSP eficaz com Next exige nonce por request
  (gerado no `proxy.ts` e propagado para os scripts inline do framework); `unsafe-inline`
  numa CSP de App Router é CSP decorativa. O mecanismo exato de propagação do nonce no Next
  16 precisa ser confirmado antes de escrever a policy. ⚠️ não confirmado
- **Markdown / SVG / HTML de terceiro:** qualquer renderizador que produza HTML é um vetor.
  SVG inline executa script — trate arquivo `.svg` de origem externa como código.

### 6.3 Autorização → negar por padrão

**A regra de ouro desta stack: esconder não é autorizar.** Ocultar um botão, filtrar uma
lista no cliente ou redirecionar no `useEffect` é **UX**. O dado só está protegido se o
backend nega — e é lá que a prova (Art. 1) tem de existir.

- **Nunca envie ao cliente o que ele não pode ver.** Server Component que busca o registro
  inteiro e passa `{...user}` para um client component **entregou** os campos sensíveis: eles
  estão no RSC payload, legíveis no *view-source*, mesmo que nenhum JSX os desenhe. Passe
  campos selecionados, nunca o objeto inteiro.
- **`layout.tsx` não é ponto de controle.** O layout **não re-executa** a cada navegação de
  filho, então uma checagem feita nele pode não rodar na navegação seguinte — e um `page.tsx`
  novo dentro daquele segmento nasce desprotegido. A verificação pertence a **cada** rota
  (ou a uma camada de acesso a dado chamada por cada rota). ⚠️ não confirmado
- **`proxy.ts` (ex-middleware) é checagem otimista, não a fronteira.** Serve para
  redirecionar quem não tem cookie — não para decidir acesso a dado. Historicamente essa
  camada já teve bypass explorável por header interno forjado (a classe de falha do
  `x-middleware-subrequest` em versões anteriores), o que reforça a regra: nenhuma decisão
  de segurança **só** aqui. Se 16.3.2 está na faixa corrigida daquele advisory precisa ser
  confirmado. ⚠️ não confirmado
- **Server Action é um endpoint POST público.** Ter sido chamada de dentro de uma página
  protegida não protege nada: ela é invocável direto. Toda Server Action verifica sessão **e**
  pertencimento do recurso, no seu próprio corpo, antes de agir. O mesmo vale para cada
  `route.ts`.
- **Nunca confie em id vindo do cliente para escopo.** `deleteCard(cardId)` precisa provar que
  o cartão é do usuário da sessão — do lado do servidor. Confiar no id é IDOR.
- **Cache do RTK Query é por store, e a store é por sessão de browser.** Depois de logout,
  `dispatch(api.util.resetApiState())` — senão o cache continua servindo dado do usuário
  anterior na mesma aba.
- **Prova (Art. 1):** o teste de frontend que importa é *"a UI se comporta corretamente
  quando o servidor responde 401/403"* — não *"o botão está escondido"*.

### 6.4 Segredos & configuração → fora do código, fora do bundle

- **`NEXT_PUBLIC_*` é público e é *inlined* no build**: o valor entra no JavaScript enviado ao
  browser e **não** muda em runtime. Rotacionar depois do build não muda o que já foi servido.
  Só valor não sensível (URL da API, nome do app), lido num ponto único (`src/lib/env.ts`) —
  regra do [`README.md`](README.md).
- **Segredo lido em código servidor só existe se o módulo nunca cruzar a fronteira.** Um
  `process.env.API_SECRET` num módulo que um client component importa **vai para o bundle**
  (ou vira `undefined` e cria um bug de segurança silencioso). O mecanismo canônico de
  proteção é o pacote **`server-only`** (`import 'server-only'` no topo do módulo), que faz o
  build **falhar** ao ser importado do grafo cliente. Que esse erro seja de build (e não de
  runtime) no Next 16 precisa ser confirmado. ⚠️ não confirmado
- **Closure de Server Action é criptografada, mas não é cofre.** O Next cifra as variáveis
  capturadas por uma action e elimina do bundle as actions não referenciadas — ainda assim, a
  orientação oficial é **não capturar dado sensível** em closure. Em deploy multi-instância há
  uma chave compartilhada a definir (`NEXT_SERVER_ACTIONS_ENCRYPTION_KEY`); o que a plataforma
  de deploy faz por padrão precisa ser confirmado. ⚠️ não confirmado
- **PII e telemetria:** nada de e-mail, CPF ou conteúdo de estudo em `console.*`, em query
  string, em `localStorage` ou em evento de analytics. URL vaza em `Referer` e em log de CDN.
- **Source map em produção** expõe o código-fonte original; se houver segredo no código, o
  problema já era outro, mas o mapa amplia a superfície. O default do Next 16 para
  `productionBrowserSourceMaps` precisa ser confirmado antes de assumir que não são
  publicados. ⚠️ não confirmado
- **`.env` no `.gitignore`; `.env.example` só com placeholders** (já é o caso). Segredo que
  vazou, rotaciona — remover do histórico não desvaza.

### 6.5 Sessão & estado de autenticação

Hoje a aplicação é **pública** — nada disto está exercitado. Vale como contrato para a
primeira rota autenticada.

- **Token vive em cookie `httpOnly`, emitido pelo backend.** É o desenho já embutido no
  `fetchBaseQuery` (`credentials: 'include'`, com o comentário *"nada de token em
  localStorage"*). **Nunca** guarde token em `localStorage`, `sessionStorage`, slice do Redux
  ou variável de módulo: qualquer XSS lê tudo isso, e o estado do Redux é serializado para o
  cliente na hidratação.
- **Flags do cookie** (responsabilidade do backend, verificável daqui): `httpOnly`, `secure`
  em produção, `sameSite`, `path`, expiração curta.
- **Frontend e API em domínios diferentes** (Vercel + host do backend) com
  `credentials: 'include'` normalmente força `SameSite=None`, que exige `Secure` e **remove**
  a proteção CSRF que o cookie dava — passando a exigir token anti-CSRF ou verificação de
  `Origin` no servidor. A combinação válida para este par de domínios precisa ser verificada
  em ambiente real antes de expor rota autenticada. ⚠️ não confirmado
- **CSRF em Server Actions:** o Next só aceita `POST` e compara `Origin` com
  `Host`/`X-Forwarded-Host`, rejeitando divergência —
  `experimental.serverActions.allowedOrigins` amplia a lista quando há proxy. Isso cobre o
  caso comum, mas **não** é um token anti-CSRF, já houve reporte de falha de
  case-sensitivity nessa comparação, e **Route Handlers não recebem essa proteção
  automaticamente**: um `POST /api/x` que confia só no cookie é CSRF-vulnerável e precisa de
  verificação de `Origin` própria. ⚠️ não confirmado
- **`cookies()` é assíncrona no Next 16** (`await cookies()`) e **só pode escrever** em Server
  Action ou Route Handler — tentar `set` durante o render de um Server Component é erro. ⚠️ não confirmado
- **Após login/logout:** invalide o cache (`api.util.resetApiState()`), zere slices de sessão
  e force revalidação do que era do usuário anterior.
- **Mensagem de falha de autenticação é genérica** — distinguir "usuário não existe" de
  "senha errada" na UI é enumeração de contas, mesmo que a API tenha sido cuidadosa.

### 6.6 Saída de rede, imagem e volume (síntese)

- **SSRF vive em `route.ts` e em Server Action**, não no browser: `fetch(userUrl)` do lado do
  servidor alcança rede interna e endpoint de metadados da plataforma. Regra: URL de saída sai
  de **allowlist de host**, `https` obrigatório, `AbortSignal.timeout()` sempre, e
  `redirect: 'manual'` — validar a URL antes **não** impede o redirect para IP interno. Que o
  `fetch` do runtime Node do Next siga redirect por padrão e não tenha guarda de IP privado
  precisa ser confirmado. ⚠️ não confirmado
- **Open redirect:** `redirect(searchParams.next)` manda o usuário para onde o atacante
  quiser. Destino de redirect é **path relativo validado** ou allowlist.
- **`next/image` é um otimizador rodando na sua infraestrutura**, logo uma superfície de DoS e
  de proxy: configure `remotePatterns` estreito (host **e** path — nunca `hostname: '**'`),
  `localPatterns` quando aplicável, e mantenha `dangerouslyAllowSVG` **desligado**. No Next 16
  a lista de `qualities` permitidas passou a ser obrigatória/estrita, justamente para impedir
  que um atacante gere variantes infinitas de uma imagem; o formato exato dessa configuração
  precisa ser confirmado na doc da minor instalada. ⚠️ não confirmado
- **Volume:** paginação em toda listagem (o `Paginated<T>` do domínio já existe); nunca
  renderize lista de tamanho ilimitado vinda da API.
- **Dependência é código que roda no browser do usuário** — supply chain aqui é execução
  direta na sessão de quem estuda. Ver §8.
- **`postMessage` / `iframe` / storage:** se algum dia entrarem, valide `event.origin` sempre;
  `X-Frame-Options: DENY` já bloqueia o *clickjacking* da nossa página.

---

## 7. Testes → Charter Art. 1, 9

**Runner canônico: Jest 30 via `next/jest`** (`jest.config.ts`), `testEnvironment: 'jsdom'`,
`setupFilesAfterEach` em `jest.setup.ts` (`@testing-library/jest-dom`), alias `@/` mapeado.
O wrapper `next/jest` cuida da transformação SWC, dos mocks de `next/font` e do CSS —
**não** troque por `ts-jest` configurado à mão. Comando: `npm test`.

Organização:

| Tipo | Onde | Como |
|---|---|---|
| Componente | `tests/components/<x>.test.tsx` | Testing Library, consulta por papel/texto |
| Slice, selector, lógica pura | `tests/store/<x>.test.ts` | reducer e selectors direto, sem React |
| Hook isolado | junto do componente que o usa | prefira testar pelo componente |
| Helper compartilhado | `tests/support/` (a criar quando houver a segunda cópia) | `renderWithProviders`, builders |

**Convenções:**

- `describe('<Componente ou unidade>')` + `it('<comportamento observável em pt-BR>')` — a
  frase descreve a **regra**, não o método: `it('devolve o cartão ao fim da fila quando o
  estudante erra')`, não `it('testa cardRated')`.
- **AAA**: arrange, act, assert, separados por linha em branco (é o formato do
  `technique-card.test.tsx`).
- **Consulta por papel e texto visível** — `getByRole('button', { name: 'Revelar' })`,
  `getByLabelText`, `getByText`. **Nunca** por `className`, `id` ou estrutura de DOM: teste
  que quebra ao renomear uma classe está testando a implementação (regra do
  [`README.md`](README.md)). `data-testid` é último recurso, não atalho.
- **`user-event` em vez de `fireEvent`** — `await userEvent.click(...)` reproduz a sequência
  real de eventos (foco, pointer, teclado) e pega bug que `fireEvent` não pega.
- **Assíncrono é `findBy*` / `waitFor`**, nunca `setTimeout`. `act()` manual quase sempre é
  sinal de que faltou `await` num `userEvent`.
- Uma asserção **de comportamento** por caso (várias `expect` sobre o mesmo resultado contam
  como uma).

**Testar comportamento, não implementação.** Prove a regra: o rótulo pt-BR que aparece, o
verso que só surge depois do clique, o cartão que volta para a fila em `AGAIN`, o estado
vazio, a mensagem quando a API responde erro. **Não** teste o que o Next garante
(roteamento, prerender, `<Link>`), nem o RTK, nem "renderizou sem quebrar".

**O que mockar:** a **fronteira de rede**. Para RTK Query, o caminho robusto é interceptar
HTTP (MSW) e exercitar a store real, em vez de mockar o hook gerado — mockar
`useListMnemonicsQuery` testa o mock. Quando o componente sob teste precisa de store,
envolva com `<Provider store={makeStore()}>` num helper (`renderWithProviders`), **uma store
nova por teste**. O que **não** mockar: o componente sob teste, o reducer, o Immer, o `Intl`.

**Componente servidor `async` não renderiza em jsdom.** A cobertura de um Server Component
se faz (a) extraindo a lógica para função pura testável e (b) pelo gate `screenVerify`
(README) / E2E. Se a versão atual da Testing Library já renderiza RSC de forma suportada,
isso precisa ser confirmado antes de virar padrão da casa. ⚠️ não confirmado

**Oráculo tem de poder falhar (Art. 1):** teste que continua verde com o corpo do componente
trocado por `return null` não é teste. Ao escrever, quebre o código de propósito e confirme o
vermelho. **Snapshot não é prova de comportamento** — aceita qualquer mudança com um `-u`;
use no máximo para marcação estável, nunca como único teste de uma regra.

**Fixtures compartilhadas (Art. 3):** dado de teste repetido vira **builder com defaults +
overrides** em `tests/support/`, não `const card = {...}` copiado em cinco arquivos — um
campo novo em `Flashcard` quebraria as cinco cópias uma a uma.

**Acessibilidade é comportamento**, não enfeite: se o teste não consegue achar o elemento por
`getByRole`/`getByLabelText`, provavelmente o usuário de leitor de tela também não consegue.
O teste que falha aqui achou um bug de UX, não um problema de teste.

**Cobertura:** `npm run test:ci` (`--coverage`), piso global de **50%** no
`coverageThreshold`, com `layout.tsx` e `index.ts` fora do `collectCoverageFrom`. O piso é
rede contra regressão de disciplina — **não** é meta: 100% de linhas com asserção fraca não
prova nada, e a régua real é o Art. 1.

**Mutation testing (`quality.mutation`, opt-in):** a ferramenta canônica em TS é o **Stryker**
(`@stryker-mutator/core` + `@stryker-mutator/jest-runner`), tipicamente
`npx stryker run --mutate <arquivos-do-diff>`. Hoje `quality.mutation` é `null` na ficha —
instalação via `/keelson:mutation-setup`.

---

## 8. Dependências → Charter Art. 2, 8

**Gerenciador: npm** (`package-lock.json`). O lock é **commitado** e é a fonte da verdade da
árvore instalada.

- **CI/produção usam `npm ci`** (instala exatamente o lock e falha se `package.json` e lock
  divergirem); `npm install` é para a máquina do dev; `npm update` só deliberadamente, em
  commit próprio.
- **Política de versão:** `next`, `react`, `react-dom` e `eslint-config-next` estão **pinados
  exatos** — a tríade React/Next é acoplada e um patch inesperado quebra hidratação ou tipos.
  Caret (`^`) para o resto. `engines.node: ">=22.0.0"` é contrato.
- **Auditoria:** `npm audit` (endpoint de advisories do registry npm, alimentado pelo **GitHub
  Advisory Database**, sincronizado com CVE/NVD). No pipeline:
  `npm audit --omit=dev --audit-level=high` reprova, **citando o GHSA/CVE**. `npm audit fix
  --force` **não** é correção aceitável: sobe major e muda comportamento. Auditoria completa
  via `/keelson:audit`.
- **Supply chain (A03) tem peso extra no frontend:** dependência de runtime **executa no
  browser do usuário**, com acesso ao DOM e ao que estiver na página. Antes de adicionar:
  downloads, última publicação, issues, se tem script de `install`/`postinstall`, e se o nome
  não é *typosquatting* do pacote popular. Confira **licença**.
- **Peso é critério de aceitação, não detalhe.** Toda dependência de runtime nova declara
  quanto adiciona ao bundle da rota e por que a plataforma não resolve (§9). "É só 40 kB" são
  40 kB no LCP de quem estuda no 4G.
- **`@types/*` acompanham a lib** — `@types/react` e `@types/react-dom` na linha 19; tipo
  desatualizado produz erro de typecheck que parece bug do código.
- **`overrides`** é remendo de transitiva com data de validade: cada entrada **DEVE** ter
  registro do porquê e da condição de remoção.

**Antes de adicionar dependência, pergunte se a plataforma já resolve** (§9: `Intl` em vez de
date-fns/moment, `fetch`+RTK Query em vez de axios, CSS moderno + Tailwind em vez de
component kit, `useId` em vez de uuid). Dependência a menos é CVE a menos e bundle a menos.

**Armadilha comum:** rodar `npm install` (não `ci`) no deploy — resolve versões diferentes das
testadas e produz o bug "só em produção".

---

## 9. Reúso: o que já existe → Charter Art. 3

**Procure antes de criar.** Nesta base, o canônico mora em lugares fixos:

| Preciso de… | Já existe em |
|---|---|
| Chamada à API | `src/store/api.ts` — **adicione um endpoint** ao `createApi`; não escreva `fetch` solto nem um segundo cliente HTTP |
| Store / dispatch / selector tipados | `src/store/hooks.ts` (`useAppDispatch`, `useAppSelector`, `useAppStore`) — nunca `useSelector` cru |
| Estado da sessão de estudo | `src/store/study-slice.ts` (actions + `selectors` do próprio slice) |
| Montagem da store | `src/store/index.ts` (`makeStore`) e `src/app/providers.tsx` |
| Env pública | `src/lib/env.ts` — nunca `process.env` espalhado |
| Tipo de domínio e rótulo pt-BR | `src/types/domain.ts` (`MNEMONIC_TECHNIQUE_LABELS`, `REVIEW_RATING_LABELS`) — espelhado no backend |
| Cor, espaço, fonte | tokens `@theme` de `src/app/globals.css` |
| Padrão visual recorrente | `@utility` do `globals.css` (`surface-card`, `text-muted`) |
| Componente de apresentação | `src/components/` (`TechniqueCard`, `SiteHeader`, `ApiStatus`) |

**Prefira a plataforma ao helper caseiro:**

| Em vez de | Use |
|---|---|
| `<a>` interno, roteador próprio | `next/link`; `useRouter`/`usePathname`/`useSearchParams` de `next/navigation` |
| `<img>`, lazy-load manual | `next/image` (com `sizes`) |
| `@font-face` na mão | `next/font` (já em uso: Geist) |
| `<Helmet>`, `document.title` | Metadata API (`metadata` / `generateMetadata`) |
| flag `isLoading` manual | `loading.tsx` + `<Suspense>`, ou o `isLoading` do RTK Query |
| `useState` + `useEffect` para buscar | Server Component `async`, ou hook do RTK Query |
| `uuid` para id de DOM | `useId` |
| debounce caseiro para busca | `useDeferredValue` / `useTransition` |
| formatação de data/número na mão | `Intl.DateTimeFormat` / `Intl.NumberFormat` com locale `pt-BR` |
| memo manual de derivação | `createSelector` (RTK) |
| normalização de lista à mão | `createEntityAdapter` |
| `useState` para estado de formulário + envio | `<form action>` + `useActionState` + `useFormStatus` |

**Como descobrir:** `grep`/`rg` pelo conceito em `mnemonicos-frontend/src` (o
`codePaths.frontend` da ficha) antes de escrever; varredura mais ampla → `code-scout`;
território de um slug → o `MAP.md` dele, primeiro.

**O guard determinístico é preferível a "lembre de reusar":** regras `no-restricted-imports`
(proibir `process.env` fora de `src/lib/env.ts`, proibir `react-redux` cru fora de
`src/store/hooks.ts`) transformam disciplina em falha de build. ⚠️ ainda não configuradas —
é uma melhoria conhecida.

**Régua:** ver Charter Art. 3 — a mudança não introduz segundo caminho para o que já existia;
conceito repetido é **extraído**, não copiado.

---

## 10. Performance & armadilhas → Charter Art. 8

**A moeda aqui é dupla: bytes enviados ao browser e re-renders.**

**Custo patológico nº 1: fronteira cliente larga.** Cada `'use client'` alto na árvore leva
consigo tudo que importa. Sintomas e correções:

- `'use client'` em `layout.tsx` → desça para o componente interativo (§4);
- lib pesada (gráfico, editor, markdown) importada no topo de um client component →
  `next/dynamic` / `React.lazy` no ponto de uso;
- import de barrel (`from '@/components'`) → importe o arquivo direto;
- imagem grande sem `sizes` → CLS e LCP ruins.

**Custo patológico nº 2: waterfall de rede.**

```tsx
// ❌ sequencial: 2 round-trips em série
const disciplines = await getDisciplines();
const due = await getDueCards();

// ✅ paralelo
const [disciplines, due] = await Promise.all([getDisciplines(), getDueCards()]);
```

E o pior caso: **N+1 no cliente** — uma lista onde cada item monta seu próprio
`useQuery(item.id)`. Busque a coleção de uma vez (o backend expõe `include`/paginação) e
distribua por prop.

**Custo patológico nº 3: re-render em cascata.**

- prop de objeto/array/função **criada inline** muda de identidade a cada render e invalida
  qualquer `memo`;
- selector que **cria** objeto novo (`useAppSelector(s => ({ a: s.x, b: s.y }))`) faz o
  componente re-renderizar em toda action → `createSelector` ou dois selectors;
- `key={index}` em lista que reordena/insere → estado do item migra para o vizinho errado;
  use id estável;
- estado global para o que é local (um `isOpen` de modal no slice) → re-renderiza meia árvore.

**Não memoize por reflexo.** `useMemo`/`useCallback`/`memo` custam alocação e leitura; entram
quando **a medição** mostra o problema (Art. 8). O React Compiler resolve boa parte disso
automaticamente, mas **não está habilitado** neste projeto — não escreva código contando com
ele.

**Cache: o default do Next 16 é dinâmico.** Nada é cacheado implicitamente; `fetch` não
cacheia sem `cache: 'force-cache'`, e o cache explícito é `use cache` +
`cacheLife`/`cacheTag` sob a flag `cacheComponents`. Consequência prática: página que parece
lenta provavelmente está **correta e sem cache** — a decisão de cachear é deliberada e vai
para uma DEC, não é ajuste solto. No RTK Query, o equivalente é `keepUnusedDataFor`,
`providesTags`/`invalidatesTags` e não ligar `refetchOnMountOrArgChange` por hábito.

**Ferramentas de medição (o Art. 8 exige medir, não palpitar):**

| Quero medir | Ferramenta |
|---|---|
| Tamanho por rota / First Load JS | saída de `npm run build`; `@next/bundle-analyzer` |
| O que engordou o bundle | saída do build Turbopack + analyzer, comparando antes/depois |
| Render e re-render | React DevTools **Profiler** (e "Highlight updates") |
| Timeline detalhada | **Performance Tracks** do React 19.2 no DevTools do browser |
| Core Web Vitals reais (LCP/CLS/INP) | Lighthouse local, `useReportWebVitals`, RUM da plataforma |
| Requisições e waterfall | aba Network; log do RTK Query em dev |
| Custo de uma query | medir no backend (`EXPLAIN`) — o frontend só vê latência |

**Régua:** ver Charter Art. 8 — sem requisição dentro de laço sobre volume variável; qualquer
otimização não óbvia (memo, dynamic import, cache) **cita a medição** que a justifica, no
comentário ou na DEC.

---

## 11. Gotchas da versão → Charter Art. 1, 7

**Next 16**

- **`params` e `searchParams` são `Promise`** — `const { slug } = await params;`. O acesso
  síncrono foi removido, e o erro aparece como propriedade `undefined`, não como falha clara.
  Idem `cookies()`, `headers()`, `draftMode()`.
- **`middleware.ts` → `proxy.ts`**, com export `proxy` e runtime **Node.js** (não mais Edge):
  APIs Node passaram a funcionar ali — o que também significa que erro de arquitetura ali
  agora tem alcance maior (§6.3).
- **Turbopack é o default de `dev` e `build`.** `next build` **falha** se detectar config de
  webpack. Loader/plugin de webpack precisa de equivalente Turbopack ou de `--webpack`
  (temporário, com prazo).
- **`next lint` não existe** — o lint é `eslint .` (já é o caso aqui).
- **Cache dinâmico por default** (§10): quem vem do 13/14 espera `fetch` cacheado e vai
  encontrar comportamento diferente. `use cache`/`cacheComponents` é opt-in.
- **`next/image`:** `qualities`/`remotePatterns` mais estritos (§6.6); `<Image>` sem `sizes`
  em layout responsivo baixa a nota de LCP.
- **`useSearchParams` em client component torna a rota dinâmica** e exige `<Suspense>` em
  volta no build estático — o erro de build aponta o componente, não a causa.
- **Node ≥ 20.9** (aqui: 22) e TypeScript recente são pré-requisitos.
- **Hidratação** continua sendo o erro nº 1 de quem vem do CSR: `Date.now()`,
  `Math.random()`, `Intl` com locale do sistema, `typeof window` decidindo marcação,
  extensão de browser injetando DOM, HTML inválido (`<div>` dentro de `<p>`). Regra: servidor
  e cliente **DEVEM** produzir a mesma árvore no primeiro render; o que difere vai para
  `useEffect` ou para `suppressHydrationWarning` **com comentário do porquê**.
- **Fronteiras que o compilador não protege:** `'use client'` + componente `async` é inválido;
  hook ou handler em Server Component é erro; `export const metadata` num client component é
  ignorado/erro; passar função como prop de servidor para cliente só funciona se for Server
  Action.

**React 19 / 19.2**

- `ref` é **prop comum**; `forwardRef` está a caminho da aposentadoria. **Breaking sutil:**
  callback de ref que **retorna** algo agora é interpretado como função de cleanup —
  `ref={el => (myRef.current = el)}` (com retorno implícito) quebra; use corpo com chaves.
- `propTypes`/`defaultProps` em componente de função foram **removidos** (defaults vão na
  desestruturação); refs por string e `ReactDOM.render`/`hydrate`, removidos.
- `useFormState` → **`useActionState`**; `act` vem de `react`, não de `react-dom/test-utils`.
- Contexto se usa como `<Ctx value>` (sem `.Provider`) e pode ser lido com `use(Ctx)`.
- **StrictMode em dev monta duas vezes** de propósito: efeito que não é idempotente aparece
  como requisição/animação dupla. É diagnóstico, não bug do React.
- 19.2 traz `useEffectEvent` (callback estável dentro de efeito, sem virar dependência),
  `<Activity>` (esconder preservando estado) e `cacheSignal`. Prefira `useEffectEvent` ao
  truque de `useRef` para "última versão do callback".

**TypeScript 6**

- `strict` + **`noUncheckedIndexedAccess`**: `queue[currentIndex]` é `Flashcard | undefined`.
  Isso **não** é incômodo — é o bug que o compilador pegou (o `if (!card) return;` do
  `study-slice.ts` existe por isso). Trate; não use `!`.
- `exactOptionalPropertyTypes` está **desligado**: `{ a?: string }` aceita `{ a: undefined }`.
- `moduleResolution: bundler` + `isolatedModules`: import só-de-tipo precisa de `import type`.
- Defaults novos do TS 6 (`types: []`, `module: esnext`, `rootDir`) só valem para projeto sem
  config explícita; ainda assim, mudou `tsconfig` → rode `typecheck` **e** `test`.
- `.next/types/**` está no `include` de propósito: é de lá que vem a tipagem de rota/`Link`.

**Tailwind 4**

- **Sem `tailwind.config.js`**: `@import 'tailwindcss'` + `@theme` no `globals.css`; o plugin
  PostCSS é `@tailwindcss/postcss`. `@tailwind base/components/utilities` não existe mais.
- Token declarado em `@theme` gera a utilitária **e** a variável CSS: `--color-brand-500` →
  `bg-brand-500` e `var(--color-brand-500)`. Em CSS, use `var(--…)`, não `theme()`.
- Utilitárias **renomeadas** na v4 (a família de `shadow-*`, `outline-none`/`outline-hidden`,
  o `ring` default) e defaults mudados (cor de borda `currentColor`) — a lista exata precisa
  ser conferida no guia de upgrade ao portar marcação antiga. ⚠️ não confirmado
- Requer browser moderno (`@property`, `color-mix()`): não há build "legado".
- Classe montada por concatenação (`` `bg-${cor}-500` ``) **não é detectada** pelo scanner —
  use mapa de literais completos (§4).

**Redux Toolkit 2**

- `combineSlices` + `selectors` dentro do `createSlice` são o padrão da base — selector
  espalhado em componente é regressão.
- `useDispatch.withTypes<AppDispatch>()` substitui os aliases manuais.
- O Immer permite "mutar" **dentro** do reducer; fora dele, jamais. Devolver **e** mutar no
  mesmo reducer é bug (`sessionReset` devolve `initialState` sem mutar — é o jeito certo).
- O middleware de serializabilidade reclama de `Date`/`Map` no estado: guarde ISO string
  (`startedAt: string | null` é exatamente isso).

**Régua (Art. 1/7):** surpresa de versão de que a base depende **DEVE** estar coberta por
teste (o comportamento, não o detalhe) ou **comentada com o porquê** onde a escolha não é
óbvia — como já fazem os comentários de `providers.tsx`, `store/index.ts` e `lib/env.ts`.

---

## 12. Ferramentas & comandos

Comandos **dentro de `mnemonicos-frontend/`**:

| Papel | Comando idiomático | Ficha |
|---|---|---|
| **test** | `npm test` (= `jest`); CI: `npm run test:ci` (`--ci --coverage`) | `quality.test` |
| **lint** | `npm run lint` (= `eslint .`) — formatação: `npm run format:check` | `quality.lint` |
| **typecheck** | `npm run typecheck` (= `tsc --noEmit`) | `quality.typecheck` |
| **build** | `npm run build` (= `next build`, Turbopack) | `quality.build` |
| **boot local** | `npm run dev` (= `next dev`, Turbopack, porta 3000) | `quality.boot` |
| **tudo** | `npm run validate` (= `format:check && lint && typecheck && test`) | — |

Como este workspace agrega dois repositórios, a ficha embrulha cada comando com
`npm --prefix mnemonicos-frontend …` (encadeado com o backend). O que a ficha tem hoje:

```jsonc
{
  "profile": { "frontend": { "lang": "next", "version": "16", "file": "guidelines/project/frontend/next-16.md" } },
  "codePaths": { "frontend": ["mnemonicos-frontend/src"] },
  "quality": {
    "test": "npm --prefix mnemonicos-backend test && npm --prefix mnemonicos-frontend test",
    "lint": "npm --prefix mnemonicos-backend run lint && npm --prefix mnemonicos-frontend run lint",
    "typecheck": "npm --prefix mnemonicos-backend run typecheck && npm --prefix mnemonicos-frontend run typecheck",
    "build": "npm --prefix mnemonicos-backend run build && npm --prefix mnemonicos-frontend run build",
    "mutation": null,
    "e2e": null
  },
  "gates": { "screenVerify": { "enabled": true, "method": "skill:screen-verify" } }
}
```

**Observações para quem mexer na ficha:**

- `quality.lint` roda **só** o ESLint, e **sem** `--max-warnings=0`: aviso (ex.: `no-console`)
  passa no gate e só é barrado no `pre-commit`. Se o gate deve reprovar aviso e formatação,
  é `quality.lint` que precisa encadear `format:check` e o flag.
- `quality.build` = `next build`: é o único comando que exercita o bundler de produção — e,
  portanto, o único que pega erro de fronteira servidor/cliente e de rota dinâmica sem
  `<Suspense>` (§11). Typecheck verde **não** substitui build verde nesta stack.
- `quality.e2e` é `null`, mas o gate **`screenVerify` está ligado** (Playwright MCP via
  `skill:screen-verify`): mudança de tela fecha por ali — ver [`README.md`](README.md).
  `/keelson:e2e-setup` (Playwright) e `/keelson:mutation-setup` (Stryker) só gravam na ficha
  **após prova**.
- Comando que altera dado ou estrutura **não** entra em `quality.*`. Aqui não há nenhum — o
  banco é do backend, e migração exige autorização humana explícita.
