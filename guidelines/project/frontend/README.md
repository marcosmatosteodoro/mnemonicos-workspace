# mnemonicos-frontend — guia de projeto (keelson)

Leia antes de codar no frontend. Vale junto de
[../README.md](../README.md) (regras dos dois repos) e do perfil de linguagem
[next-16.md](next-16.md) — em conflito, **este arquivo vence o perfil**.

## O que a aplicação é

Interface de estudo do acervo mnemônico. Next 16 (App Router, Turbopack) · React 19 ·
TypeScript 6 (`strict`) · Tailwind 4 · Redux Toolkit + RTK Query. Deploy na Vercel.

## Server e Client Components

**Server Component é o default.** `'use client'` só onde há estado, efeito ou evento — e a
diretiva desce para o componente mais fundo possível, não para a página inteira. Marcar um
layout como client arrasta a árvore toda para o browser.

Padrão da casa: a página é server (`src/app/page.tsx`), e o pedaço interativo é um client
component próprio (`src/components/api-status.tsx`).

## Estado — duas fatias com papéis que não se misturam

- **Estado do servidor → RTK Query** (`src/store/api.ts`). Disciplinas, mnemônicos, cartões
  vencidos. Cache, revalidação e `isLoading` saem de graça. **Não replicar isso em slice
  manual** — é a duplicação que produz tela mostrando dado velho.
- **Estado só-do-cliente → slice** (`src/store/study-slice.ts`). A fila da sessão, o índice
  atual, se o verso foi revelado, as notas dadas. Nada que o servidor já saiba.

`makeStore()` é **função, nunca singleton de módulo**: no SSR um singleton vaza estado de um
usuário para o request seguinte. A store nasce por árvore renderizada, via `useState` lazy
em `src/app/providers.tsx`.

Selectors moram no próprio slice (`selectors` do `createSlice`), não espalhados nos
componentes.

## Estilo

Tailwind 4 — **a configuração vive no CSS**, em `@theme` de `src/app/globals.css`. Não
existe `tailwind.config.js` e não se deve criar um.

- Cor, fonte e espaçamento novos entram como **token** no `@theme`, não como valor literal
  na classe. Literal repetido em três lugares é token faltando.
- Tema claro/escuro sai dos tokens de superfície (`--surface`, `--text-strong`, …)
  redefinidos sob `prefers-color-scheme`. Componente não decide cor por conta própria.
- Utilitário próprio recorrente → `@utility` no `globals.css` (ver `surface-card`).
- O Prettier ordena as classes (`prettier-plugin-tailwindcss`) — não brigue com a ordem.

## Texto e domínio

- **Identificadores de código em inglês; todo texto visível em pt-BR.** O rótulo em pt-BR
  de um valor de domínio vem do mapa em `src/types/domain.ts`
  (`MNEMONIC_TECHNIQUE_LABELS`, `REVIEW_RATING_LABELS`), nunca escrito solto no JSX — é
  assim que o mesmo enum não aparece traduzido de dois jeitos em duas telas.
- `src/types/domain.ts` espelha `mnemonicos-backend/src/domain/types.ts`. Mudou um enum de
  um lado → o outro entra no **mesmo diff**.

## Variáveis de ambiente

Tudo prefixado `NEXT_PUBLIC_` é embutido no bundle e **é público**. Segredo nenhum ali.
A leitura acontece num ponto só (`src/lib/env.ts`), com default — não espalhe
`process.env` pelos componentes.

## Testes

- Componente → Testing Library em `tests/components/`, consultando por **papel e texto
  visível** (`getByRole`, `getByText`), não por classe CSS ou id. Teste que quebra ao
  renomear uma classe está testando a implementação.
- Slice e lógica pura → `tests/store/`, exercitando reducer e selectors direto.
- Não teste o que o Next garante (roteamento, prerender). Teste o comportamento que você
  escreveu.

## Verificação visual

Mudança de tela fecha com o gate `screenVerify` (skill `keelson:screen-verify`, Playwright
MCP headless). Telas atrás de login usam o realm de `keelson.local.json` (molde em
`keelson.local.example.json`).

## Indicador de andamento (KAN-192)

Andamento se mostra com **spinner, nunca com texto de reticências**. Não existe "Carregando…"
nem "Salvando…" visível na tela.

- **Carregamento de tela ou seção** → `LoadingArea` (`src/components/progress-indicator.tsx`):
  spinner centralizado na área que vai receber o conteúdo, texto só em `sr-only` dentro de
  `role="status"`. Quem usa leitor de tela continua ouvindo "Carregando".
- **Ação em botão** → `BusyButton`: o próprio botão vira o gerúndio **sem reticências** com
  spinner (`Salvar` → `Salvando`, `Remover` → `Removendo`), desabilitado e com `aria-busy`.
  Não existe `<span>` solto ao lado com o gerúndio.
- **Anúncio da ação** → `BusyAnnouncement`, região viva `sr-only` **sempre montada** (região
  inserida já com texto não é anunciada de forma confiável). Fica fora de `<form aria-busy>`:
  o `aria-busy` do form silenciaria o anúncio se a região fosse descendente dele.
- **Proibido**: texto visível terminado em "…" como indicador de andamento. Placeholder de
  campo ("Selecione…", "Filtrar por categoria…") não é indicador e fica de fora.

```tsx
{isLoading ? <LoadingArea label="Carregando flashcards" /> : <FlashcardTable … />}

<form aria-busy={isSaving} onSubmit={…}>
  <BusyButton type="submit" isBusy={isSaving} label="Salvar" busyLabel="Salvando" />
</form>
<BusyAnnouncement isBusy={isSaving} busyLabel="Salvando" />
```

Testes do padrão: `src/components/progress-indicator.test.tsx`. Ao migrar um componente, o teste
que procurava o texto visível com "…" passa a procurar o rótulo do botão ou o `role="status"`.

## Campo obrigatório (KAN-216)

Todo campo obrigatório mostra **"\*"** no rótulo, e nenhum campo opcional mostra. É padrão do
projeto: formulário novo já nasce com ele.

- **Rótulo** (`src/components/required-mark.tsx`) → em `<label>` que envolve o controle
  (`flex flex-col`), use `RequiredLabelText`: texto e `*` viram **um único item flex**, e o `*`
  acompanha a última palavra. `RequiredMark` solto como irmão do texto nesse layout empilha o
  asterisco em linha própria (KAN-228); ele só vale em `<label htmlFor>` separado do controle
  (login, criar usuário, `password-field`). O asterisco é `aria-hidden`: não entra no nome
  acessível do campo.
- **Controle** → `aria-required="true"` no `input`/`select`/`textarea`. Não usar o `required`
  nativo em campo validado no envio: o balão do navegador mudaria o fluxo de erro atual. O
  `required` nativo só se mantém onde já existe (login, data de fechamento legislativo).
- **Obrigatoriedade condicional** (ex.: Citação do dispositivo só com Tipo selecionado) → o
  asterisco e o `aria-required` aparecem só quando a condição vale
  (`<RequiredLabelText required={cond}>`).
- **Legenda** → `RequiredLegend` ("\* campo obrigatório") uma vez em cada formulário com dois
  ou mais campos obrigatórios. Bloco de um campo só (pegadinha, quadro novo da tira) não repete.

```tsx
<label className="flex flex-col gap-1 text-sm">
  <RequiredLabelText>Pergunta</RequiredLabelText>
  <textarea aria-required="true" aria-invalid={…} … />
</label>
```

Teste: buscar campo por nome acessível (`getByRole(..., { name: 'Pergunta' })`) e afirmar
`aria-required`. Para `getByLabelText`, o texto do rótulo inclui o "\*": usar `requiredLabel`
de `tests/support/required-label.ts`, que aceita o asterisco opcional.

## Botão de ação (KAN-230)

Botão = ícone à esquerda + rótulo curto, via `ActionButton`; nome acessível completo começando
pelo rótulo. Regra completa em [botoes-acao.md](botoes-acao.md).

## Comandos

`npm run validate` = `format:check` + `lint` + `typecheck` + `test`. É o conjunto que o
gate roda; rode antes de despachar.
