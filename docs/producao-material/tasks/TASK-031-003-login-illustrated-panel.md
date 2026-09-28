# TASK-031-003: Renderizar o painel ilustrado do card (LoginIllustratedPanel)

**Slug**: producao-material
**Pertence a**: PLAN-031
**Realiza (FRs)**: FR-030-001 (parte — painel ilustrado), FR-030-003 (parte — painel), FR-030-011 (parte — painel), FR-030-012 (parte — painel)
**Componente**: COMP-031-003 (principal), COMP-031-001
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-031-001
- **Bloqueia**: TASK-031-004

## Contexto

Introduz o painel ilustrado do card de `/login` (metade superior), com o mesmo motivo
noturno decorativo do fundo em tela cheia (TASK-031-002), em escala de card, também imune
a tecnologia assistiva.

## Escopo

### Inclui
- `LoginIllustratedPanel` (Server Component, sem props) em
  `mnemonicos-frontend/src/components/login-illustrated-panel.tsx`: motivo noturno
  decorativo (montanhas/dunas em camadas, lua cheia, estrelas, estrelas cadentes, céu em
  degradê) via SVG inline (formas geométricas simples, sem geometria pesada — DEC-031-002)
  + gradiente CSS, usando exclusivamente os tokens de COMP-031-001, `aria-hidden="true"`.
- Estrelas cadentes animadas via `@keyframes` CSS puro, suprimidas sob `@media
  (prefers-reduced-motion: reduce) { animation: none }`.

### Não inclui
- Montagem do componente dentro do card em `page.tsx` (COMP-031-004, TASK-031-004).
- O fundo em tela cheia (COMP-031-002, TASK-031-002) — mesmo motivo, componente distinto.
- Medição de peso de bundle da ilustração (TRISK-031-002) — critério de TASK-031-004, após
  a árvore de `/login` estar completa.

## Critérios de pronto

- [ ] `LoginIllustratedPanel` renderiza como Server Component, `aria-hidden="true"`, sem
      nenhum papel/texto alcançável por `getByRole`/`getByText` — Testes cobrem
      AC-030-002 (parte — painel): verificação executável:
      `npm --prefix mnemonicos-frontend test -- src/components/login-illustrated-panel.test.tsx`
      → OK (N tests), incluindo asserção de `queryByRole` retornando `null` para qualquer
      papel de conteúdo e do atributo `aria-hidden="true"` no nó raiz.
- [ ] As estrelas cadentes (se implementadas) têm a regra `@media
      (prefers-reduced-motion: reduce) { animation: none }` associada ao `@keyframes` —
      verificação executável: `grep -n "\bprefers-reduced-motion\b" mnemonicos-frontend/src/components/login-illustrated-panel.tsx | grep -vE '^[0-9]+:\s*(//|/\*|\*)'`
      → ao menos 1 ocorrência fora de comentário/docblock (a supressão real da animação
      decorativa sob `prefers-reduced-motion` é confirmada no roteiro do gate 9 de
      TASK-031-004).
- [ ] Nenhuma cor literal (hex/rgb/hsl) no componente — todas as cores vêm dos tokens de
      COMP-031-001 — verificação executável:
      `grep -En "#[0-9a-fA-F]{3,8}|rgb\(|rgba\(|hsl\(" mnemonicos-frontend/src/components/login-illustrated-panel.tsx | grep -vE '^[0-9]+:\s*(//|/\*|\*)' | wc -l`
      → `0` fora de comentário/docblock (contribui para AC-030-014, consolidado em
      TASK-031-004).
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff, produção e teste).

## Riscos específicos

- TRISK-031-002 (peso do SVG/CSS): manter poucos `<path>`/`<circle>`, sem geometria
  pesada (DEC-031-002) — medição real do bundle de `/login` é critério de TASK-031-004.
- Lição ativa `item-de-lista-que-renderiza-a-mesma-entidade-em-2-componentes-nascidos-na-mesma-wave-herda-a-corre-o-de-acessibilidade-j-aplicada-no-irm-o-can-nico-n-o-s-a-estrutura`:
  esta TASK e TASK-031-002 nascem na mesma wave e reaproveitam o mesmo motivo/técnica
  (SVG + `aria-hidden` + `prefers-reduced-motion`) em componentes irmãos — o revisor
  confere que uma correção de acessibilidade/técnica achada num não fica de fora do outro.

---

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-145

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
