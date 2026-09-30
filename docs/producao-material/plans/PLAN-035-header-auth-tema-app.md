# PLAN-035: Botão de sessão e tema dark/light no header do app

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.2
**Autor**: scribe
**Data**: 2026-09-29

## Aderência a guidelines

**Decisões irreversíveis do slug tocadas**: nenhuma — `DEC-029-003` (PLAN-029/F8) trata do
`contentSnapshot` JSON de `ContentVersion` (versionamento editorial de Conteúdo bruto), sem
relação com header, sessão ou tema do frontend.
**Decisões irreversíveis de outros slugs em conflito**: nenhuma — `docs/infra-vercel/INDEX.md`:
sem bloco de decisões (o slug `infra-vercel` não tem `INDEX.md` — ausência declarada, decisão
4.241).
**Exceções aos guidelines**: nenhuma.

## Cobertura

**SPEC referenciada**: SPEC-034
**Slice declarado**: cobertura total restante — Caso D (nenhum PLAN anterior cobre nenhum
FR/NFR de SPEC-034; slug já existente, mas SPEC nova).

**FRs cobertos**:
- FR-034-001
- FR-034-002
- FR-034-003
- FR-034-004
- FR-034-005
- FR-034-006
- FR-034-007
- FR-034-008
- FR-034-009
- FR-034-010
- FR-034-011
- FR-034-012
- FR-034-013
- FR-034-014
- FR-034-015
- FR-034-016

**NFRs cobertos**:
- NFR-034-001
- NFR-034-002
- NFR-034-003
- NFR-034-004
- NFR-034-005

## 1. Visão técnica

Esta fatia é 100% `mnemonicos-frontend`, sem tocar backend: `/auth/me`, `/auth/login` e
`/auth/logout` já existem e não mudam de contrato (SPEC-002/SPEC-016). O desenho consolida
dois controles hoje ausentes ou espalhados — sessão e tema — num único lugar visível, o
`SiteHeader` (`mnemonicos-frontend/src/components/site-header.tsx:7-18`), montado por
`SiteHeaderGate` em toda rota exceto `/login` (`site-header-gate.tsx:12,23-25`) via
`RootLayout` (`src/app/layout.tsx:30-44`).

**Consolidação do controle de sessão.** Hoje o único botão "Sair" vive dentro de
`InternalShell` (`internal-shell.tsx:70-124`, `LogoutControl`), com um `<header>` próprio
que a área interna monta por conta. `AuthControl` (COMP-035-001, novo) absorve esse
comportamento — mesmos três estados observáveis de AC-002-027 — e passa a viver no
`SiteHeader`, alcançável de qualquer rota; `InternalShell` (COMP-035-006) perde o `<header>`
e o `LogoutControl` próprios (FR-034-014). Para saber se há sessão sem herdar o efeito
colateral do mecanismo existente — `baseQueryWithReauth` (`store/api.ts:368-427`) tenta
`POST /auth/refresh` e, falhando, `resetApiState()` + redirect `/login?sessao=expirada` em
qualquer 401 fora de login/refresh/janela de logout recente (`store/api.ts:392-424`) —,
`AuthControl` não reusa `useMeQuery` (que o `InternalShell` continua usando exatamente como
hoje, `internal-shell.tsx:37`). Em vez disso, consome um novo endpoint `meSilent`
(COMP-035-004) que chama `rawBaseQuery` (`store/api.ts:308-312`) diretamente, contornando
`baseQueryWithReauth` (DEC-035-005).

**Alternador de tema.** Hoje o tema é 100% `prefers-color-scheme`, sem override manual nem
persistência (`globals.css:62-132`). Dois mecanismos novos cobrem o ciclo completo: um
script de bootstrap inline (COMP-035-003), embutido no `<head>` de `RootLayout` e executado
antes da hidratação, que aplica `document.documentElement.dataset.theme` a partir de
`localStorage` quando há escolha salva (default por dispositivo "de graça" quando não há —
FR-034-007/008, sem flash perceptível — NFR-034-004); e `ThemeToggle` (COMP-035-002), que
troca e persiste a escolha manual (FR-034-009/010/011). O CSS de `globals.css` ganha uma
terceira camada de seletor (DEC-035-002) para a escolha manual prevalecer sobre a preferência
do dispositivo (FR-034-012).

**Paleta unificada.** Os papéis de UI do app inteiro fora de `/login` (`--surface`,
`--surface-raised`, `--border-subtle`) passam a usar a paleta noturna já validada em
`/login` (SPEC-030/PLAN-031), reaproveitando tokens e pares de contraste já medidos em
`night-palette-tokens.ts` (COMP-035-005, DEC-035-003/004) — sem tocar `--text-strong`,
`--text-muted`, `--danger` nem `--link`, que já passam ou permanecem por decisão explícita
(RISK-034-002 endereçado; NFR-034-005 verificado no gate 11, não nesta decisão).

Nenhuma dependência nova entra no projeto — mesmo espírito de PLAN-031 (DEC-031-002): tudo
aqui é CSS, um script inline autoral e uma extensão pequena de `store/api.ts`.

## 2. Stack e dependências

Stack herdada sem reescolha: Next 16 (App Router, Turbopack), React 19, TypeScript 6
(`strict`), Tailwind 4 (`@theme` em `globals.css`, sem `tailwind.config.js`), RTK Query
(`@reduxjs/toolkit/query/react`) como única fonte de estado de servidor. Nenhuma dependência
nova (mesmo espírito de "sem asset/dependência nova" de DEC-031-002/PLAN-031): sem
`next-themes`, sem lib de ícone adicional — SVG inline (mesmo padrão de
`password-field.tsx`) para os dois controles, se precisarem de ícone.

## 3. Componentes

### COMP-035-001: AuthControl
**Responsabilidade**: Controle único de autenticação/sessão do header — exibe "Entrar" (sem
sessão), "Sair" com os três estados observáveis herdados de `LogoutControl` (em
andamento/sucesso/falha, `LOGOUT_ERROR_MESSAGE`), ou um estado neutro enquanto a sessão
ainda não foi resolvida; nunca aciona logout a partir de um clique sem sessão ativa — só
navegação para `/login`.
**Realiza**: FR-034-001, FR-034-002, FR-034-003, FR-034-004, FR-034-005, FR-034-006, FR-034-014, FR-034-016, NFR-034-002
**Interface pública**: `export function AuthControl(): JSX.Element` — sem props; `'use
client'`; consome `useMeSilentQuery()` (COMP-035-004) para o estado de sessão e
`useLogoutMutation()` (já existente, `store/api.ts:693`) para o logout; navega via
`useRouter()` (`next/navigation`).
**Dependências**: COMP-035-004

### COMP-035-002: ThemeToggle
**Responsabilidade**: Alternador de tema claro/escuro do header — reflete visualmente o
tema ativo (lido de `document.documentElement.dataset.theme`, com fallback a
`matchMedia('(prefers-color-scheme: dark)')` quando não há override salvo), troca de forma
síncrona e imediata ao clique, grava a escolha em `localStorage` (chave dedicada,
independente de sessão/conta — A-034-005) e aplica `data-theme` no `<html>`.
**Realiza**: FR-034-009, FR-034-010, FR-034-011, NFR-034-001
**Interface pública**: `export function ThemeToggle(): JSX.Element` — sem props; `'use
client'`.
**Dependências**: nenhuma

### COMP-035-003: Script de bootstrap de tema
**Responsabilidade**: Função pura que gera o texto de um script inline
(`getThemeBootstrapScript(): string`, `mnemonicos-frontend/src/lib/theme-bootstrap.ts`),
embutido por `RootLayout` num `<head>` explícito via `<script
dangerouslySetInnerHTML={{ __html: ... }} />`, antes de qualquer conteúdo que dependa do
tema. Executa antes da hidratação: lê a escolha salva em `localStorage`; se existir, aplica
`document.documentElement.dataset.theme` de imediato; se não existir, não seta o atributo —
o CSS de `prefers-color-scheme` decide sozinho, inclusive reagindo a mudança de preferência
do SO em tempo real quando não há override (FR-034-007/008 "de graça").
**Realiza**: FR-034-007, FR-034-008, FR-034-012, NFR-034-004
**Interface pública**: `export function getThemeBootstrapScript(): string` — função pura,
sem JSX (`src/lib/*`, mesmo papel de `src/lib/env.ts`); consumida só por
`src/app/layout.tsx`.
**Dependências**: nenhuma

### COMP-035-004: meSilent (endpoint RTK Query)
**Responsabilidade**: Verificação de ausência/presença de sessão sem nenhum efeito
colateral — extensão de `store/api.ts` com um endpoint implementado via `queryFn` (não
`query`), chamando `rawBaseQuery('/auth/me', ...)` diretamente e contornando
`baseQueryWithReauth` por completo. 401 → `{ data: null }` (sem sessão, sem erro); sucesso →
`{ data: SessionUser }`; qualquer outro erro (rede, 5xx) → também `{ data: null }` (o pior
caso observável é mostrar "Entrar" a quem tem sessão, nunca side-effect indevido).
**Realiza**: FR-034-015
**Interface pública**: `useMeSilentQuery()` — hook gerado pelo endpoint `meSilent:
build.query<SessionUser | null, void>({ queryFn: ... })` acrescentado a `api.ts`; `useMeQuery`
existente não muda.
**Dependências**: nenhuma

### COMP-035-005: Paleta unificada (globals.css + night-palette-tokens.ts)
**Responsabilidade**: Estende os papéis de UI do app inteiro fora de `/login` (`--surface`,
`--surface-raised`, `--border-subtle`) para a paleta noturna, nas três camadas de seletor de
DEC-035-002, nos dois temas; adiciona a `night-palette-tokens.ts` os pares de contraste
novos que essa extensão introduz (mesmo padrão de fonte única de
`NIGHT_PALETTE_CONTRAST_PAIRS`/`findMeasuredPair`), consumidos por um teste de contraste
dedicado ou por extensão do existente.
**Realiza**: FR-034-013, NFR-034-003, NFR-034-005
**Interface pública**: variáveis CSS (`--surface`, `--surface-raised`, `--border-subtle`) em
`globals.css`; exports de `night-palette-tokens.ts` (`NIGHT_PALETTE_CONTRAST_PAIRS`
estendido) — nenhuma API de componente.
**Dependências**: nenhuma

### COMP-035-006: InternalShell (modificado)
**Responsabilidade**: Remove o `<header className="flex items-center justify-end border-b
px-4 py-3 sm:px-6">` e o componente `LogoutControl` (`internal-shell.tsx:70-124`) —
`InternalShell` passa a renderizar só `<div className="mx-auto w-full max-w-5xl flex-1
px-4 py-8 sm:px-6">{children}</div>`, mantendo o container existente; a área interna passa a
depender exclusivamente do `AuthControl` do header para logout.
**Realiza**: FR-034-014
**Interface pública**: `export function InternalShell({ requiredRole, children }:
InternalShellProps)` — assinatura e demais estados (carregando/redirect/sem permissão)
inalterados.
**Dependências**: COMP-035-001

### COMP-035-007: SiteHeader (modificado)
**Responsabilidade**: Monta `AuthControl` e `ThemeToggle` ao lado de `ApiStatus`
(dev-only, `site-header.tsx:14`, inalterado), sempre visíveis — inclusive em produção — em
toda rota onde `SiteHeader` aparece hoje.
**Realiza**: FR-034-005, FR-034-009
**Interface pública**: `export function SiteHeader()` — assinatura inalterada (Server
Component).
**Dependências**: COMP-035-001, COMP-035-002

## 4. Fluxos principais

**Carregamento inicial de qualquer rota (exceto `/login`)**: o `<head>` de `RootLayout`
executa `getThemeBootstrapScript()` (COMP-035-003) antes da hidratação — aplica
`data-theme` salvo ou deixa o CSS decidir pela preferência do dispositivo. `SiteHeader`
(COMP-035-007) monta `AuthControl` (COMP-035-001) e `ThemeToggle` (COMP-035-002).
`AuthControl` dispara `useMeSilentQuery()` (COMP-035-004): enquanto pendente, mostra o
estado neutro (FR-034-016); resolvido, mostra "Entrar" ou "Sair" sem nenhum redirect nem
aviso associado a essa checagem (FR-034-015/AC-034-015).

**Clique em "Entrar"**: navegação simples para `/login`, sem estado assíncrono próprio
(FR-034-003/006).

**Clique em "Sair"**: `AuthControl` dispara `useLogoutMutation()` (já existente), com os
mesmos três estados de `AC-002-027` — em andamento, sucesso (navega para `/login`), falha
(mensagem genérica, permanece na página).

**Clique no alternador de tema**: `ThemeToggle` troca `data-theme` no `<html>` de forma
síncrona (sem estado "em andamento", FR-034-010), grava a escolha em `localStorage`
(independente de sessão — sobrevive a login/logout, AC-034-017) e o CSS de 3 camadas
(DEC-035-002) aplica os tokens do tema escolhido.

**Reload ou navegação após escolha manual**: o script de bootstrap (COMP-035-003) lê a
escolha salva e reaplica `data-theme` antes da hidratação — a preferência do dispositivo é
ignorada a partir da escolha manual (FR-034-011/012/AC-034-011).

**Login/logout com tema escolhido**: como a chave de `localStorage` do tema é independente
de sessão/conta (A-034-005), nenhum dos dois fluxos acima toca o tema — ele permanece
aplicado (AC-034-017).

## 5. Modelo de dados

Nenhum model Prisma novo, nenhuma migração, nenhum endpoint de backend novo — 100%
frontend. Persistência client-side via `localStorage`: chave dedicada (ex.:
`mnemonicos:theme`), valor `'light' | 'dark'` — ausência de valor significa "sem escolha
manual salva", e o CSS de `prefers-color-scheme` decide. O mesmo enum de dois valores é
espelhado no atributo DOM `data-theme` do `<html>` (`'light'` força claro, `'dark'` força
escuro, ausente = segue o dispositivo).

## 6. Decisões arquiteturais

### Decisões herdadas
- **DEC-035-007** [herdada] `'use client'` só em `AuthControl`/`ThemeToggle` (componentes
  com estado/evento); `SiteHeader` e `RootLayout` continuam Server Component — fonte: perfil
  `next-16.md` §4 + CLAUDE.md do workspace (seção "Padrão de codificação — Frontend").
- **DEC-035-008** [herdada] Tokens de cor/tema vivem no `@theme` de `globals.css`, nunca em
  `tailwind.config.js` (que não existe no projeto) — fonte: perfil `next-16.md` §1/§11 +
  CLAUDE.md do workspace (seção "Padrão de codificação — Frontend").
- **DEC-035-009** [herdada] Estado de servidor (sessão) só via RTK Query
  (`store/api.ts`), sem slice manual replicando o mesmo dado — fonte: perfil `next-16.md`
  §4 + CLAUDE.md do workspace (seção "Padrão de codificação — Frontend").

### DEC-035-001: Bootstrap de tema via script inline bloqueante, sem biblioteca
**Contexto**: FR-034-007/008/011/012 exigem que o tema (default por dispositivo ou escolha
salva) já esteja aplicado no primeiro paint, com o mínimo de flash perceptível
(NFR-034-004, SHOULD) — mas os componentes React (`ThemeToggle`, `RootLayout`) só hidratam
depois do HTML estático já ter sido pintado pelo navegador. RISK-034-001 da SPEC alerta
justamente para essa janela.
**Decisão**: Script inline, gerado por `getThemeBootstrapScript()` (COMP-035-003) e embutido
no `<head>` de `RootLayout` (Server Component) via `<script
dangerouslySetInnerHTML>`, executado antes da hidratação: lê `localStorage` (chave
dedicada); havendo valor salvo, aplica `document.documentElement.dataset.theme = <valor>`
imediatamente; sem valor salvo, não seta o atributo — o CSS de `prefers-color-scheme` cobre
sozinho, inclusive reagindo a mudança de preferência do SO em tempo real quando não há
override.
**Alternativas consideradas**:
- Biblioteca `next-themes` — resolve o mesmo problema, mas é dependência nova para ~15
  linhas de script autoral; descartada pelo custo concreto de bundle/manutenção de terceiro
  para um problema já resolvido localmente com pouco código (mesmo espírito de
  DEC-031-002/PLAN-031, "sem dependência nova").
**Consequências**: o app ganha um pequeno script inline, fora do grafo TypeScript, que
precisa ser mantido sincronizado manualmente com a chave de `localStorage` usada por
`ThemeToggle` (COMP-035-002) — os dois lendo/escrevendo a mesma chave é contrato implícito,
não tipado; em compensação, FR-034-007/008 saem "de graça" da cascata CSS existente.
**Reabrir se**: o app precisar de SSR do tema correto sem qualquer flash (exigiria cookie
lido no servidor) — não é o caso hoje (NFR-034-004 é SHOULD, não MUST).
**Irreversível**: nao
**Aderência à ficha/perfil**: nova

### DEC-035-002: CSS de tema em 3 camadas
**Contexto**: hoje `globals.css` define os papéis de UI (`--surface` etc.) só em `:root`
(claro, default) e `@media (prefers-color-scheme: dark) { :root { ... } }` (escuro pela
preferência do SO) — sem nenhum mecanismo de override manual persistente. FR-034-011/012
exigem que a escolha manual do usuário prevaleça sobre a preferência do dispositivo a partir
de então, inclusive quando as duas divergem.
**Decisão**: Estender para 3 camadas: (a) `:root { ... }` — valores do tema claro (default);
(b) `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { ... } }` —
valores do tema escuro quando o SO prefere escuro E o usuário não forçou claro; (c)
`:root[data-theme="dark"] { ... }` — mesmos valores do tema escuro, force-aplicados quando o
usuário escolheu escuro manualmente, independente do SO.
**Alternativas consideradas**:
- Classe `.dark` no `<html>` (padrão Tailwind `darkMode: 'class'`) — descartada porque
  exigiria configurar `darkMode` no `@theme`/Tailwind 4, mecanismo diferente do já usado
  neste projeto (100% `prefers-color-scheme` + custom properties), sem trazer benefício de
  substância: o custo concreto seria introduzir um segundo mecanismo de tema convivendo com
  o já existente, sem necessidade.
**Consequências**: cada bloco de tokens de tema (`--surface`, `--surface-raised`,
`--border-subtle`, os pares novos da paleta noturna) é escrito uma vez para o claro e
repetido nos dois seletores do escuro ((b) e (c)) com o mesmo valor — risco de divergência
se alguém editar só um dos dois blocos escuros no futuro, mitigado por ficarem adjacentes no
arquivo e cobertos pelo teste de contraste de DEC-035-004.
**Reabrir se**: nunca — a alternativa de classe `.dark` não traz benefício concreto aqui.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova

### DEC-035-003: Mapeamento de papéis de UI para a paleta noturna
**Contexto**: FR-034-013/NFR-034-003 exigem que os papéis de UI do app inteiro (fora de
`/login`) usem a família roxo/rosa/mauve com o piso AA já validado; RISK-034-002 da SPEC
aponta que a paleta noturna hoje só tem contraste medido para os papéis de UI de `/login`
(fundo, campo em pílula, botão, texto).
**Decisão**: `--surface` (fundo de página) ← `--color-night-panel-bg`; `--surface-raised`
(cards/`surface-card`) ← `--color-night-pill-bg`; `--border-subtle` ←
`--color-night-pill-border` (os três já provados ≥3:1 contra os fundos relevantes em
`NIGHT_PALETTE_CONTRAST_PAIRS`). `--text-strong`/`--text-muted`/`--danger` permanecem como
estão (ink/red) — já provados AA contra `night-panel-bg`
(`NIGHT_PALETTE_PANEL_LABEL_PAIR`, ~17-18,65:1); remapeá-los seria trabalho sem necessidade
e risco de regressão de contraste sem medição prévia. `--link` permanece como está
(`--color-brand-400`/`--color-brand-600`) nesta fatia.
**Alternativas consideradas**:
- Remapear `--link` para um tom da paleta noturna (ex. `--color-night-button-bg`) —
  descartada porque aproximaria visualmente o link do acento decorativo roxo/rosa,
  arriscando a distinguibilidade que NFR-034-005 exige, sem nenhuma medição de contraste de
  `--link` contra o novo `--surface` (=`night-panel-bg`) feita ainda.
**Consequências**: `--text-strong`/`--text-muted`/`--danger`/`--link` não precisam de
nenhuma alteração de valor — só `--surface`/`--surface-raised`/`--border-subtle` trocam de
fonte (de `--color-ink-*` para `--color-night-*`); a medição de contraste de `--link`/
`--danger` contra o novo `--surface` fica para o gate 11/TASK, não é resolvida por este
PLAN.
**Reabrir se**: o gate 11 medir contraste insuficiente de `--link`/`--danger` contra o novo
`--surface`, ou o Diretor pedir uniformidade visual maior entre link e acento.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova

### DEC-035-004: Extensão de `night-palette-tokens.ts` com os pares novos
**Contexto**: `night-palette-tokens.ts` já é a fonte única dos pares de contraste medidos
(`NIGHT_PALETTE_CONTRAST_PAIRS`), consumida por teste dedicado; DEC-035-003 introduz três
papéis novos (`--surface`/`--surface-raised`/`--border-subtle`, agora ligados a tokens
noturnos) sem par de contraste próprio registrado ali.
**Decisão**: Estender `night-palette-tokens.ts` com os pares de contraste novos que este
PLAN introduz — mesmo padrão de fonte única, consumido por um teste novo (ex.:
`globals-theme-contrast.test.ts`, ou extensão do teste equivalente já existente).
**Alternativas consideradas**:
- Hard-code dos valores de contraste esperados dentro do teste novo, sem tocar
  `night-palette-tokens.ts` — descartada por duplicar a fonte da verdade que o arquivo já
  centraliza: o custo concreto é 2 lugares divergindo silenciosamente quando alguém mudar 1
  token em `globals.css` sem lembrar do valor hard-coded no teste.
**Consequências**: `findMeasuredPair(name)` segue sendo o único ponto de leitura dos pares;
qualquer teste novo referencia por nome, nunca redeclara hex solto.
**Reabrir se**: nunca — a alternativa descartada (hard-code no teste) não tem nenhum
cenário em que passa a ser preferível à fonte única já convencionada no arquivo.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova

### DEC-035-005: Verificação de sessão sem efeito colateral via `meSilent`/`queryFn`
**Contexto**: A-034-004/RISK-034-003 da SPEC — `useMeQuery` hoje passa por
`baseQueryWithReauth`, que em qualquer 401 fora de login/refresh/janela de logout recente
tenta `POST /auth/refresh` e, falhando, `resetApiState()` + redirect para
`/login?sessao=expirada`. FR-034-015 exige checagem de sessão sem nenhum efeito colateral
(nem redirect, nem aviso) para visitante anônimo em rota pública.
**Decisão**: Novo endpoint RTK Query `meSilent` em `store/api.ts`, implementado com
`queryFn` (não `query`) chamando `rawBaseQuery('/auth/me', ...)` diretamente — contornando
`baseQueryWithReauth` por completo (o `queryFn` substitui o `baseQuery` compartilhado só
para este endpoint). Mapeia 401 → `{ data: null }` (sem sessão, sem erro); sucesso → `{
data: SessionUser }`; qualquer outro erro (rede, 5xx) também vira `{ data: null }` (o pior
caso observável é mostrar "Entrar" a quem tem sessão, nunca side-effect indevido).
`useMeQuery` existente não muda — `InternalShell` continua usando-o como hoje.
**Alternativas consideradas**:
- Reusar `useMeQuery` no header e suprimir o redirect via uma flag global nova em
  `baseQueryWithReauth` (tipo `justLoggedOut`) — descartada por acoplar lógica de
  apresentação de um widget a infraestrutura compartilhada por toda a store, ampliando a
  superfície de um mecanismo já historicamente delicado (comentários extensos no arquivo
  sobre janelas de corrida); o custo concreto é o risco de regressão em todo consumidor de
  `useMeQuery`/`baseQueryWithReauth`, não só no header.
**Consequências**: dois caminhos de leitura de sessão coexistem no mesmo módulo
(`useMeQuery` via `baseQueryWithReauth` para a área protegida; `meSilent` via
`rawBaseQuery` para o header) — divergência documentada, não acidental; qualquer alteração
futura ao contrato de `/auth/me` precisa lembrar dos dois consumidores.
**Reabrir se**: surgir um 2º consumidor com a mesma necessidade de leitura silenciosa de
sessão — aí sim vale extrair um helper comum.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova

### DEC-035-006: Consolidação do logout em `AuthControl`, com remoção do controle da área interna
**Contexto**: FR-034-014/AC-034-014 exigem um único controle de logout no app; hoje existe
`LogoutControl` dentro de `InternalShell` (área interna), sem nenhum controle equivalente
nas rotas públicas. O PO, na aprovação de SPEC-034, escalou a confirmação da remoção
(degrau 2, default aplicado — INDEX.md) e o Diretor recebe a pergunta em lote na Entrega
desta demanda.
**Decisão**: Novo componente `AuthControl` (`'use client'`, em `SiteHeader`) absorve o botão
"Sair" hoje em `InternalShell`/`LogoutControl` — mesmo comportamento (três estados,
`LOGOUT_ERROR_MESSAGE`, `useLogoutMutation`, navegação para `/login` no sucesso), relocado.
O `<header>` e o `LogoutControl` de `internal-shell.tsx` são removidos (não duplicados).
Sem sessão (via `meSilent`), `AuthControl` renderiza "Entrar" (navega para `/login`, sem
estado assíncrono — FR-034-003). Estado neutro (FR-034-016) enquanto `meSilent` ainda não
resolveu.
**Alternativas consideradas**:
- Manter os dois controles de logout (header + área interna) — descartada por criar 2
  botões "Sair" simultâneos nas rotas internas, o custo concreto é a confusão de produto já
  registrada pelo `product-analyst`/PO (RISK-034 correspondente no INDEX): dois pontos de
  acionamento para a mesma ação observável.
**Consequências**: `internal-shell.tsx` perde o `<header>` e o `LogoutControl` (COMP-035-006);
toda a lógica de três estados de logout muda de dono de arquivo, mas não de comportamento —
`AC-002-027` continua provado, agora a partir de `AuthControl`; qualquer teste que hoje monta
`InternalShell` isoladamente esperando encontrar o botão "Sair" precisa mudar de alvo
(`AuthControl`/`SiteHeader`).
**Reabrir se**: o Diretor, na pergunta escalada pelo PO (registrada no INDEX), pedir para
manter os dois controles — reverteria esta DEC.
**Irreversível**: nao
**Aderência à ficha/perfil**: nova

## 8. Riscos técnicos

- **TRISK-035-001** FOUC do tema errado na 1ª pintura se, por algum caminho de renderização
  (ex.: streaming com `<Suspense>` atrasando o `<head>`), o script de bootstrap
  (COMP-035-003) não rodar antes do primeiro paint (herdado de RISK-034-001 da SPEC)
  (mitigação: script síncrono, sem `async`/`defer`, o primeiro filho do `<head>`; medição
  real no gate 9 — NFR-034-004 é SHOULD, não bloqueia o PLAN).
- **TRISK-035-002** Contraste insuficiente de `--link`/`--danger` contra o novo `--surface`
  (`--color-night-panel-bg`) nunca medido nesta extensão de paleta (herdado de
  RISK-034-002/NFR-034-005 da SPEC) (mitigação: medição real no gate 11/TASK dedicada;
  DEC-035-003 documenta a decisão de não remapear até haver medição).
- **TRISK-035-003** `meSilent` contornando `baseQueryWithReauth` pode divergir de
  comportamento se o backend mudar o contrato de `/auth/me` (ex.: exigir rotação de refresh
  token em toda chamada) sem que os dois caminhos de leitura de sessão (`me`/`meSilent`)
  sejam atualizados juntos (herdado de RISK-034-003 da SPEC) (mitigação: comentário cruzado
  nos dois endpoints em `api.ts`; DEC-035-005 documenta o motivo do contorno deliberado).
- **TRISK-035-004** `data-theme` setado pelo script de bootstrap fora do controle do React
  pode divergir do estado interno de `ThemeToggle` se o componente assumir um tema default
  fixo no primeiro render em vez de ler o atributo já aplicado no `<html>`/a escolha salva
  (risco de hidratação ou de o alternador "nascer" mostrando o rótulo/estado errado)
  (mitigação: `ThemeToggle` lê `document.documentElement.dataset.theme` — nunca assume um
  default hardcoded — item de verificação da TASK/gate 1).

## 9. Definition of Done deste PLAN

- [ ] Todos os FRs cobertos têm implementação satisfazendo os ACs — 16/16 FRs, 19/19 ACs
- [ ] Todos os NFRs cobertos têm verificação — 5/5 NFRs
- [ ] Decisões DEC-035-001..009 refletidas no código
- [ ] Aderência à ficha/perfil validada (frontend `next-16.md`; CLAUDE.md do workspace)
- [ ] Todos os ACs cobertos por teste (gate 1 dos quality gates)
- [ ] `gates.security` (gate 8): n/a — sem superfície sensível nova de autenticação/dado
      pessoal além do já provado por SPEC-002/SPEC-016 (`meSilent`/`AuthControl` só leem e
      disparam ações já existentes; nenhum endpoint novo no backend)
- [ ] `gates.screenVerify` (gate 9, ativo na ficha): roteiro cobrindo os dois temas em
      múltiplas rotas — no mínimo 1 rota pública, 1 rota interna e a home, em tema claro e
      em tema escuro cada (SPEC-034 §1.3, "Juiz do outcome estético"); inclui AC-034-019
      (360px, sem rolagem horizontal, com os dois controles + `ApiStatus` em dev)
- [ ] Gate 10 (performance): não crítico para esta fatia — rodar se o `queryFn` novo
      (`meSilent`) introduzir latência de rede perceptível
- [ ] Gate 11 (design/UX): aplicável — superfície de interface grande (paleta do app
      inteiro fora de `/login`); contraste AA verificado nos papéis remapeados
      (DEC-035-003) e nos pares novos registrados em `night-palette-tokens.ts`
      (DEC-035-004)

## 10. Não coberto por este PLAN

Nenhum — cobertura 100% dos FRs/NFRs de SPEC-034 (Caso D). O que fica fora é escopo da
própria SPEC (§4.2 Out-of-scope): mudança ao comportamento/lógica de login-logout em si,
mecanismo alternativo de persistência de tema, forma visual exata dos dois controles além do
comportamento/rótulo exigidos, ilustração decorativa de `/login` fora daquela tela, qualquer
alteração ao desenho já entregue de `/login`, remoção/alteração do `ApiStatus`, e métrica de
produto numérica de adoção — nenhum item pendente para PLAN futuro dentro do escopo desta
SPEC.
