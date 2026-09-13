# TASK-023-015: `(interno)/visual-library/page.tsx` — Server Component (casca)

**Slug**: producao-material
**Pertence a**: PLAN-023
**Realiza (FRs)**: FR-022-010
**Funcionalidade**: FEAT-022-002 (primária)
**Componente**: COMP-023-013 (principal)
**Wave**: 5
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

```yaml
override-erros: task-criterio-sem-ac
override-justificativa: >-
  Esta TASK não fecha nenhum AC isoladamente: a tela compõe o que TASK-023-012
  já prova em gate 9 (a casca em si não tem comportamento próprio além de
  compor `VisualLibraryBoard`). O oráculo é o contrato do próprio item —
  confirmação de rota alcançável — mais a garantia estrutural do guard de
  navegação (regra 4.286/4.229). Mesmo padrão de TASK-023-003/005 (Done nesta
  mesma decomposição) e de `(interno)/content/page.tsx`
  (`mnemonicos-frontend/src/app/(interno)/content/page.tsx`, casca análoga já
  mergeada sem AC próprio).
override-aprovador: Tech Lead (autônomo, /keelson:auto)
```

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch do EPICO MNEMORA STUDIO, Estrategia unica -- decisao 4.126: F5 e uma fatia do epico, nunca abre branch propria; a sessao ja fez o sync de largada nela)

**Padrão de commit**: Conventional Commits (`commit.convention: "conventional"`) — `feat:`.
**Framework de teste**: Jest 30 (`next/jest`) + Testing Library (`@testing-library/react`) —
render direto do Server Component, mesmo padrão de `(interno)/content/page.tsx` (sem teste
próprio hoje — ver Critérios de pronto) e `login/page.test.tsx`
(`render(await Componente(...))`, se necessário para este componente síncrono).

## Dependências

- **Depende de**: TASK-023-012
- **Bloqueia**: nenhuma

## Contexto

`(interno)/content/page.tsx` (`mnemonicos-frontend/src/app/(interno)/content/page.tsx`, lido
integralmente nesta redação) é o molde exato: Server Component puro, `<h1>` +
opcionalmente um `<Link>` de ação, sem estado — só compõe o client component. Com
`visual-library-board.tsx` pronto (TASK-023-012), falta a casca `/visual-library`. A
navegação principal já existente cobre a entrada na rota (o PLAN não pede um link de volta
específico, mesmo padrão de `(interno)/content/page.tsx`, que também não tem).
`INTERNAL_ROUTE_PREFIXES` (`mnemonicos-frontend/src/lib/internal-routes.ts:14`, lido
integralmente nesta redação) hoje é `['studio', 'content']` — **NÃO inclui
`'visual-library'`**, ao contrário da premissa do PLAN §3/COMP-023-013 de que já estaria;
esta TASK corrige isso no mesmo diff (ver Escopo > Inclui).

## Escopo

### Inclui

- `mnemonicos-frontend/src/app/(interno)/visual-library/page.tsx` (novo) — Server Component
  puro, `export default function VisualLibraryPage()`, `export const metadata: Metadata =
  { title: '<título pt-BR>' }` (mesmo padrão de `content/page.tsx:6-8`); renderiza um
  `<h1>` + `<VisualLibraryBoard />` (COMP-023-014), sem `'use client'`.
- **Correção autorizada pelo Tech Lead na consolidação da rodada** (achado do redator,
  degrau 1 — extensão puramente aditiva de um allowlist já deny-by-default, nunca
  afrouxamento): a premissa do PLAN §3/COMP-023-013 estava errada — `/visual-library` NÃO
  cai no prefixo hoje. Acrescentar `'visual-library'` a `INTERNAL_ROUTE_PREFIXES`
  (`mnemonicos-frontend/src/lib/internal-routes.ts:14`) e as 2 entradas correspondentes em
  `config.matcher` (`mnemonicos-frontend/src/proxy.ts:97`, mesmo símbolo compartilhado que
  já liga os dois — comentário existente no arquivo aponta onde) no MESMO diff desta TASK.

### Não inclui

- Qualquer alteração em `visual-library-board.tsx` (TASK-023-012, já pronto — só consumido
  aqui).
- Qualquer OUTRA alteração em `proxy.ts` além das 2 entradas de `config.matcher` acima
  (ex.: lógica de `isSafeRelativePath`, ordem de precedência guard×404 — fora de escopo).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Copiar a estrutura de `content/page.tsx` (Server Component, `metadata`, `<h1>` + client
   component).
2. Acrescentar `'visual-library'` a `INTERNAL_ROUTE_PREFIXES` (`internal-routes.ts:14`) e as
   2 entradas de `config.matcher` (`proxy.ts:97`) — mesmo padrão de `'studio'`/`'content'`.
3. Confirmar por leitura direta (não presumir) e por teste que `/visual-library` agora está
   coberto — ver Critério de pronto correspondente.

## Critérios de pronto

- [ ] `VisualLibraryPage` renderiza `<h1>` com título pt-BR e `<VisualLibraryBoard />` —
      contrato do próprio item (sem AC isolado, override acima). Verificação executável:
      `npx jest --runTestsByPath src/app/(interno)/visual-library/page.test.tsx` se um teste
      próprio for escrito (opcional, dado que `content/page.tsx` não tem teste próprio
      equivalente hoje — `git-scout`/leitura direta confirma a ausência); alternativa
      aceitável: confirmação por leitura estrutural do arquivo (o componente não tem estado/
      efeito a exercitar além de compor o client component já provado por TASK-023-012).
- [ ] **Guard de navegação** (lição "[Testes] Valor de configuração lido por analisador de
      build só é provado por oráculo que passe pelo build"): ANTES da edição, `grep -n
      "'visual-library'" mnemonicos-frontend/src/lib/internal-routes.ts` → vazio (baseline,
      confirma que o segmento realmente não estava coberto — a premissa do PLAN
      §3/COMP-023-013 estava errada). DEPOIS da edição: `grep -n "'visual-library'"
      mnemonicos-frontend/src/lib/internal-routes.ts` → 1 ocorrência; `grep -n
      "visual-library" mnemonicos-frontend/src/proxy.ts` → 2 ocorrências (`config.matcher`).
      Teste estrutural (mesmo molde de `proxy.test.ts` existente) prova que
      `/visual-library` cai sob o guard — comando: `npm --prefix mnemonicos-frontend test --
      proxy.test.ts` → `OK (N tests)`, incluindo o caso novo.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npx eslint "src/app/(interno)/visual-library/page.tsx"` (cwd
      `mnemonicos-frontend`) → 0 problemas.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil `next-16.md` — Server Component sem
      `'use client'`, `metadata` estático (mesmo padrão de `content/page.tsx`).
- [ ] Code review aprovado.

## Riscos específicos

- **Achado do redator, corrigido pelo Tech Lead**: a premissa do PLAN §3/COMP-023-013 (de
  que `/visual-library` já cairia no prefixo guardado) estava errada — confirmado por
  leitura direta do código real. Sem esta correção, a rota ficaria INACESSÍVEL por trás do
  guard de navegação até um ajuste manual futuro. Resolvido dentro desta TASK (escopo
  ampliado, ver Escopo > Inclui) em vez de deixado como bloqueio para depois.
- Lição "[Segurança] Guard de navegação enumera o que GUARDA, nunca o que dispensa" — o
  ajuste soma `'visual-library'` ao `INTERNAL_ROUTE_PREFIXES` (o que GUARDA), nunca um
  catch-all/exclusão.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-103
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
