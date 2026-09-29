# TASK-031-002: Renderizar o fundo em tela cheia de `/login` (LoginNightBackdrop)

**Slug**: producao-material
**Pertence a**: PLAN-031
**Realiza (FRs)**: FR-030-002, FR-030-003 (parte — fundo), FR-030-011 (parte — fundo), FR-030-012 (parte — fundo)
**Componente**: COMP-031-002 (principal), COMP-031-001
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: TASK-031-001
- **Bloqueia**: TASK-031-004

## Contexto

Introduz o fundo em tela cheia de `/login`, pintando atrás de
`SiteHeader`/`<main>`/rodapé via `position: fixed; inset: 0` + `z-index` negativo dentro
da árvore normal do root layout (DEC-031-001; memo de exploração — `layout.tsx:31-44`),
decorativo e imune a tecnologia assistiva, estendendo em escala maior o mesmo motivo
noturno do painel ilustrado (TASK-031-003).

## Escopo

### Inclui
- `LoginNightBackdrop` (Server Component, sem props ou `className` opcional) em
  `mnemonicos-frontend/src/components/login-night-backdrop.tsx`: `position: fixed;
  inset: 0`, `z-index` negativo (utilitário Tailwind ou `@utility` próprio), `filter:
  blur()` para profundidade/desfoque, `aria-hidden="true"`.
- Motivo noturno decorativo (montanhas/dunas em camadas, lua cheia, estrelas, céu em
  degradê) via SVG inline com formas geométricas simples (poucos `<path>`/`<circle>`, sem
  geometria pesada — DEC-031-002) + gradiente CSS, usando exclusivamente os tokens de
  COMP-031-001.
- Estrelas cadentes animadas via `@keyframes` CSS puro, suprimidas sob `@media
  (prefers-reduced-motion: reduce) { animation: none }`.

### Não inclui
- Montagem do componente em `page.tsx` (TASK-031-004).
- O painel ilustrado do card (COMP-031-003, TASK-031-003) — mesmo motivo, componente
  distinto.
- Verificação visual de que nenhum ancestral (`Providers`/`SiteHeader`/`<main>`) introduz
  `transform`/`filter`/`perspective`/`contain` quebrando o `position: fixed` relativo ao
  viewport (TRISK-031-003) — só provável com a árvore inteira montada, roteiro do gate 9
  de TASK-031-004.
- Medição de peso de bundle da ilustração (TRISK-031-002) — critério de TASK-031-004, após
  a árvore de `/login` estar completa.

## Critérios de pronto

- [ ] `LoginNightBackdrop` renderiza como Server Component, `position: fixed; inset: 0`,
      `z-index` negativo, `aria-hidden="true"`, sem nenhum papel/texto alcançável por
      `getByRole`/`getByText` — Testes cobrem AC-030-002 (parte — fundo): verificação
      executável: `npm --prefix mnemonicos-frontend test -- src/components/login-night-backdrop.test.tsx`
      → OK (N tests), incluindo asserção de `queryByRole` retornando `null` para qualquer
      papel de conteúdo e do atributo `aria-hidden="true"` no nó raiz.
- [ ] As estrelas cadentes (se implementadas) têm a regra `@media
      (prefers-reduced-motion: reduce) { animation: none }` associada ao `@keyframes` —
      verificação executável: `grep -n "\bprefers-reduced-motion\b" mnemonicos-frontend/src/components/login-night-backdrop.tsx | grep -vE '^[0-9]+:\s*(//|/\*|\*)'`
      → ao menos 1 ocorrência fora de comentário/docblock (a supressão real da animação
      decorativa sob `prefers-reduced-motion` é confirmada no roteiro do gate 9 de
      TASK-031-004).
- [ ] Nenhuma cor literal (hex/rgb/hsl) no componente — todas as cores vêm dos tokens de
      COMP-031-001 — verificação executável:
      `grep -En "#[0-9a-fA-F]{3,8}|rgb\(|rgba\(|hsl\(" mnemonicos-frontend/src/components/login-night-backdrop.tsx | grep -vE '^[0-9]+:\s*(//|/\*|\*)' | wc -l`
      → `0` fora de comentário/docblock (contribui para AC-030-014, consolidado em
      TASK-031-004).
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff, produção e teste).

## Riscos específicos

- TRISK-031-002 (peso do SVG/CSS): manter poucos `<path>`/`<circle>`, sem geometria
  pesada (DEC-031-002) — medição real do bundle de `/login` é critério de TASK-031-004.
- TRISK-031-003 (`position: fixed` quebrado por contexto de empilhamento ancestral):
  esta TASK não prova sozinha — a verificação visual real acontece no roteiro do gate 9
  de TASK-031-004, quando a árvore completa (`SiteHeader`/`<main>`/rodapé) existe.
- Lição ativa `item-de-lista-que-renderiza-a-mesma-entidade-em-2-componentes-nascidos-na-mesma-wave-herda-a-corre-o-de-acessibilidade-j-aplicada-no-irm-o-can-nico-n-o-s-a-estrutura`:
  esta TASK e TASK-031-003 nascem na mesma wave e reaproveitam o mesmo motivo/técnica
  (SVG + `aria-hidden` + `prefers-reduced-motion`) em componentes irmãos — o revisor
  confere que uma correção de acessibilidade/técnica achada num não fica de fora do outro.

---

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 2026-09-28T16:53:05-0300
**Data conclusão**: 2026-09-28T20:42:30-0300
**Commit SHA**: `f328321` (retries da convergência de fecho da Entrega — scrim de
contraste do header/footer `e32a23c` + forma em gradiente `f328321` — sobre `ab1e32a`,
fechamento original da Wave 2)
**Jira**: KAN-144

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [ ] Segurança (gate 8): n/a — wave sem superfície de auth/dado sensível neste arquivo (decorativo/aria-hidden); gate 8 rodou na wave por causa de `password-field.tsx` (TASK-031-006), aprovado
- [ ] Comportamento (gate 9): n/a — SPEC-030 sem FEATs; gate 9 consolida na Etapa 4 contra o DoD do PLAN-031
