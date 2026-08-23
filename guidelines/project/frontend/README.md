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
MCP headless). A aplicação hoje é pública — quando a autenticação entrar, preencha o realm
em `keelson.local.json` (molde em `keelson.local.example.json`).

## Comandos

`npm run validate` = `format:check` + `lint` + `typecheck` + `test`. É o conjunto que o
gate roda; rode antes de despachar.
