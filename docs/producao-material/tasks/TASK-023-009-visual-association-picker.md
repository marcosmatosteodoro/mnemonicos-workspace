# TASK-023-009: `visual-association-picker.tsx` (seletor reusável)

**Slug**: producao-material
**Pertence a**: PLAN-023
**Realiza (FRs)**: FR-022-013
**Funcionalidade**: FEAT-022-003 (primária)
**Componente**: COMP-023-015 (principal)
**Wave**: 3
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch do EPICO MNEMORA STUDIO, Estrategia unica -- decisao 4.126: F5 e uma fatia do epico, nunca abre branch propria; a sessao ja fez o sync de largada nela)

**Padrão de commit**: Conventional Commits (`commit.convention: "conventional"`) — `feat:`.
**Framework de teste**: Jest 30 + Testing Library (`@testing-library/react`, `@testing-library/user-event`, `jest-environment-jsdom` via `test/jsdom-fetch-env.js`) — componente montado contra store real (`makeStore()` + `Provider` + `fetch` mockado), mesmo padrão de `internal-shell.integration.test.tsx`.

## Dependências

- **Depende de**: TASK-023-007
- **Bloqueia**: TASK-023-012, TASK-023-013

## Contexto

Seletor embutido e reusável de associações visuais (COMP-023-015) — sem tela própria,
consumido por `visual-library-board.tsx` (COMP-023-014, TASK-023-012) e pelo enxerto em
`mnemonic-strip-board.tsx` (COMP-023-016, TASK-023-013) para vincular uma associação a um
Quadro. Busca/filtra por categoria via `useListVisualAssociationsQuery` (RTK Query,
COMP-023-012/TASK-023-007) e devolve só o `id` escolhido via `onSelect` — nunca chama a
mutação de vínculo em si; essa decisão é de quem o usa.

## Escopo

### Inclui

- `mnemonicos-frontend/src/components/visual-association-picker.tsx` (novo) — `'use
  client'`, named export `VisualAssociationPicker`, prop `onSelect(associationId: string):
  void`. Busca/filtra por categoria via `useListVisualAssociationsQuery`; miniatura via
  `next/image` (`<Image src={`/api/v1/visual-associations/${id}/image`} width={40}
  height={40} unoptimized alt="" />` — `unoptimized` porque o endpoint devolve o binário
  puro, sem passar pelo pipeline de otimização do Next, e não há domínio externo a
  declarar em `next.config.ts` `images`; raw `<img>` dispara `@next/next/no-img-element`
  do `eslint-config-next/core-web-vitals` já ativo no projeto — WARNING novo que quebra o
  critério padrão "sem warnings/lints novos"). URL relativa **com o prefixo `/api/v1`**
  (o componente de imagem bypassa o `baseUrl` do RTK Query, que já prefixa `/api/v1`
  internamente — `store/api.ts:155-158`; sem o prefixo literal aqui, o `rewrites()` de
  `next.config.ts:28` não intercepta e a requisição cai no roteamento do próprio Next,
  404); mesmo mecanismo same-origin de `rewrites()` já usado pelo restante do frontend
  (DEC-021-001); cada item da lista chama `onSelect(id)` ao ser escolhido.
- `mnemonicos-frontend/src/components/visual-association-picker.test.tsx` (novo).

### Não inclui

- A chamada HTTP de vincular/desvincular a um Quadro — fica em TASK-023-012/013, quem
  consome o `onSelect`.
- Upload/edição/remoção de associação visual — backend (TASK-023-008/010) e UI do acervo
  (TASK-023-012).
- Qualquer noção de "já vinculado"/estado de substituição — o picker é um seletor puro,
  sem saber se o Quadro que o usa já tem vínculo (responsabilidade do consumidor,
  COMP-023-014/016).
- Paginação/ordenação avançada da listagem — delega inteiramente ao parâmetro `category` de
  `useListVisualAssociationsQuery` (COMP-023-012), sem lógica própria de página.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Reaproveite `useListVisualAssociationsQuery` (COMP-023-012, TASK-023-007) — nenhuma
   chamada HTTP paralela.
2. Um `<input>` de filtro de categoria controla o argumento `category` da query — sem
   `useState` que duplique o que o RTK Query já resolve (estado do servidor é a query, não
   um slice manual).
3. Renderize cada associação como um item clicável (`<button>`/`role="option"`) que, ao
   ser ativado, chama só `onSelect(item.id)` — nenhum efeito colateral de rede aqui.
4. `visual-association-picker.test.tsx`: monte o componente com `makeStore()` real +
   `Provider` + `fetch` mockado (harness `test/jsdom-fetch-env.js`), molde/exemplar
   `internal-shell.integration.test.tsx` — nunca extraia o predicado de
   carregamento/vazio/erro como função pura testada isolada da store.

## Critérios de pronto

- [ ] Contrato do próprio item (sem AC fechado isoladamente aqui — AC-022-011 fecha
      combinando este componente com TASK-023-012/013, gate 9 nas duas): `onSelect` é
      chamado com o `id` (string não-nula) da associação clicada — exercitado com um valor
      de fixture concreto (nunca `undefined`/string vazia).
- [ ] Filtro por categoria: alterar o valor do filtro restringe a lista exibida às
      associações daquela categoria (asserção sobre os itens renderizados após a resposta
      mockada da query filtrada — sem duplicar lógica de filtro no componente).
- [ ] Miniatura exibida usa a URL relativa `/api/v1/visual-associations/{id}/image`, com o
      prefixo `/api/v1` (asserção sobre o atributo `src` renderizado — nunca URL absoluta
      com host do backend, nunca sem o prefixo que o `rewrites()` exige).
- [ ] **Lição "[Testes] Predicado de decisão de UI a partir de estado de RTK Query só se
      prova no componente montado" (`guidelines/project/lessons.md`)**: nenhum predicado de
      carregamento/erro/lista-vazia é extraído como função pura testada isolada da store —
      o oráculo de todo estado (carregando, erro, lista vazia, lista com itens) passa pelo
      componente MONTADO contra `makeStore()` real + `fetch` mockado, nunca por
      `api.endpoints.listVisualAssociations.select()` testado à parte.
- [ ] Verificação executável: `npx jest --runTestsByPath
      src/components/visual-association-picker.test.tsx` (molde/exemplar de convenção:
      `src/components/internal-shell.integration.test.tsx`, que já roda com o mesmo padrão
      de comando trocando o caminho — arquivo-alvo ainda não existe, comando roda contra o
      molde na fixação) → `PASS ... Tests: N passed, N total`.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npx eslint src/components/visual-association-picker.tsx
      src/components/visual-association-picker.test.tsx` → 0 problemas.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil `next-16.md` — Client Component só
      onde há estado/evento; estado de servidor via RTK Query (nenhum slice manual
      duplicando o que `useListVisualAssociationsQuery` já resolve).
- [ ] Code review aprovado.

## Riscos específicos

- TRISK-023-005 (PLAN §8, herdado) — custo de listar N associações com miniatura; mitigado
  pela paginação de TASK-023-014 na fonte da query (`listVisualAssociations`), fora do
  escopo deste componente reusável.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-97
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
