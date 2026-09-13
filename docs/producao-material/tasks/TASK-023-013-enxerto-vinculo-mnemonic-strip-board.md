# TASK-023-013: Enxerto em `mnemonic-strip-board.tsx` — vínculo/desvínculo de associação visual por Quadro

**Slug**: producao-material
**Pertence a**: PLAN-023
**Realiza (FRs)**: FR-022-013, FR-022-015, FR-022-016, FR-022-017
**Funcionalidade**: FEAT-022-003 (primária)
**Componente**: COMP-023-016 (principal)
**Wave**: 4
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch do EPICO MNEMORA STUDIO, Estrategia unica -- decisao 4.126: F5 e uma fatia do epico, nunca abre branch propria; a sessao ja fez o sync de largada nela)

**Padrão de commit**: Conventional Commits (`commit.convention: "conventional"`) — `feat:`,
ex.: `feat(producao-material): vincular associacao visual a quadro da tira`.
**Framework de teste**: Jest 30 (`next/jest`) + Testing Library, componente montado contra
`makeStore()` + `Provider` + `fetch` mockado (harness `test/jsdom-fetch-env.js`) — mesmo
padrão de `mnemonic-strip-board.test.tsx` já existente (TASK-012-012), estendido nesta TASK.

## Dependências

- **Depende de**: TASK-023-007, TASK-023-009
- **Bloqueia**: nenhuma

## Contexto

`mnemonic-strip-board.tsx` (`mnemonicos-frontend/src/components/mnemonic-strip-board.tsx:1-505`,
lido integralmente nesta redação) já existe (PLAN-012/TASK-012-012): CRUD/reordenação de
Quadros, 3 estados por ação, e um diálogo `role="alertdialog"` de confirmação de remoção com
gestão de foco explícita (linhas 108-142, 395-426) — ponto de enxerto por Quadro é o `<li>`
de cada `frame` (linha 310 em diante) e o bloco de ações por Quadro (linhas 352-394).
TASK-023-007 já entrega `useLinkVisualAssociationToFrameMutation`/
`useUnlinkVisualAssociationFromFrameMutation` (RTK Query) e TASK-023-009 já entrega
`visual-association-picker.tsx` (COMP-023-015) para a seleção. `MnemonicFrame` já ganhou o
5º campo `visualAssociationId: string | null` (TASK-023-005, dependência transitiva de
TASK-023-007).

## Escopo

### Inclui

- `mnemonicos-frontend/src/components/mnemonic-strip-board.tsx` (EMENDA — arquivo
  existente): por Quadro (dentro do `<li>` de cada `frame`, ao lado do bloco de ações já
  existente):
  - Se `frame.visualAssociationId !== null`: exibe a miniatura vinculada via `next/image`
    (`<Image src={`/api/v1/visual-associations/${frame.visualAssociationId}/image`}
    width={40} height={40} unoptimized alt="" />` — URL com o prefixo `/api/v1`
    obrigatório e `next/image unoptimized` em vez de `<img>` cru, mesma correção de
    TASK-023-009/012 (evita 404 do `rewrites()` e o warning `@next/next/no-img-element`))
    com uma ação "Desvincular" que chama
    `useUnlinkVisualAssociationFromFrameMutation({ rawContentId, frameId })`.
  - Se `frame.visualAssociationId === null`: um controle que abre `VisualAssociationPicker`
    (COMP-023-015) embutido/inline para este Quadro; ao `onSelect(associationId)`, chama
    `useLinkVisualAssociationToFrameMutation({ rawContentId, frameId, visualAssociationId })`.
  - Substituição (Quadro já vinculado a A, EDITOR escolhe B no picker): reusa o MESMO
    mecanismo de diálogo `role="alertdialog"` já existente (linhas 395-426) — outro estado
    de "confirmação pendente" por Quadro (mesmo padrão de `confirmingRemoveFrameId`), texto
    adaptado para "substituir a associação visual vinculada"; ao confirmar, chama a mesma
    mutação de vínculo com o novo id (o backend, TASK-023-011, trata como substituição
    atômica — 1 única chamada, sem desvincular+vincular separados).
  - Três estados observáveis (em andamento/sucesso/falha) por ação de vincular/desvincular —
    mesmo padrão de indicador `role="status"`/`role="alert"` já usado nas demais ações do
    arquivo (FR-022-017).
  - **Gestão de foco na 4ª porta do diálogo reusado** (lição ativa citada abaixo): o novo
    estado de confirmação de substituição precisa entrar no MESMO `useEffect` de foco
    (linhas 130-142) ou ter o seu próprio, cobrindo TODOS os setters que decidem o ramo em
    que ele vive — grep de todo setter de estado que troca o Quadro em edição/remoção/
    vínculo ativo ENQUANTO a confirmação de substituição está aberta, e destino de foco (ou
    `disabled`) explícito para cada um.
- `mnemonicos-frontend/src/components/mnemonic-strip-board.test.tsx` (EMENDA — arquivo
  existente, TASK-012-012): novos `describe` para vincular/desvincular/substituir — ver
  Critérios de pronto (contrato do componente; os ACs de negócio fecham em gate 9).

### Não inclui

- A lógica de decisão do backend (idempotência, substituição, alcance por autoria,
  cadastro do `VisualAssociationLinkEvent`) — TASK-023-011.
- A tela `/visual-library` e seu board de CRUD do acervo — TASK-023-012/015.
- Qualquer alteração no mecanismo de remoção de QUADRO já existente (linhas 264-284,
  395-426) além do necessário para o diálogo reusado coexistir com o novo estado de
  confirmação de substituição — nenhuma regressão no fluxo de remoção (NFR-022-006).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Adicionar um novo estado por Quadro para "confirmação de substituição pendente" (mesmo
   padrão de `confirmingRemoveFrameId` — um único id por vez, `useState<string | null>`).
2. Reusar a estrutura JSX do `role="alertdialog"` existente (linhas 395-426) — não duplicar
   o markup, extrair se necessário para não divergir o padrão de acessibilidade
   (`aria-describedby`, foco programático).
3. Antes de fechar, grep TODOS os setters de estado que trocam de Quadro/ramo
   (`setEditingFrameId`, `setConfirmingRemoveFrameId`, o novo setter de substituição, e
   qualquer novo setter de "vinculando/desvinculando") e confirme destino de foco ou
   `disabled` para cada combinação cruzada — a lição ativa nomeia exatamente esta classe de
   defeito.
4. Nas duas mutações novas, seguir o MESMO padrão de invalidação (`invalidatesTags:
   ['MnemonicStrip']`, já declarado em TASK-023-007) — sem atualização otimista, mesmo
   padrão herdado das 4 mutations de Quadro já existentes.

## Critérios de pronto

- [ ] Contrato do próprio componente (sem AC de negócio fechado aqui — todos os ACs desta
      TASK fecham no "Roteiro do gate 9" abaixo, conforme o manifesto congelado desta
      decomposição): para um Quadro com `visualAssociationId` não-nulo, a miniatura é
      renderizada com `src` apontando para o id correto; para um Quadro com
      `visualAssociationId: null`, o controle de vincular (picker embutido) é exibido —
      exercitado no componente MONTADO (`makeStore()` + `fetch` mockado), nunca por
      predicado extraído isolado (lição "[Testes] Predicado de decisão de UI a partir de
      estado de RTK Query só se prova no componente montado").
- [ ] **Testes cobrem AC-022-011/AC-022-012 (3 estados observáveis de vincular/desvincular)
      em unidade — gate 1, não só gate 9** (correção do Tech Lead na consolidação, mesma
      régua de TASK-023-012): componente MONTADO exercitando a mutação de vínculo com
      resposta interceptada/controlada: (a) em voo → controle desabilitado + indicador
      visível; (b) sucesso → miniatura aparece/some conforme a ação; (c) erro → mensagem de
      erro visível, estado do Quadro inalterado. Verificação executável: `npx jest
      --runTestsByPath src/components/mnemonic-strip-board.test.tsx` (cwd
      `mnemonicos-frontend`) → `PASS`, com os 3 cenários nomeados no relatório.
- [ ] **Lição "[Design] Diálogo in-place em ramo condicional exige grep de TODOS os setters
      do estado que decide o ramo, não só de quem o fecha"** (`guidelines/project/
      lessons.md`, aplicação direta — mesmo arquivo, mesmo padrão de diálogo
      `alertdialog` reusado): teste dedicado — com a confirmação de substituição aberta
      para o Quadro A, acionar "Editar" no MESMO Quadro A (ou iniciar vínculo/desvínculo em
      outro Quadro B) e confirmar que o foco tem destino explícito (nunca cai no `<body>`) e
      que o estado de confirmação pendente não fica órfão (reaparecendo sozinho depois).
      Mutante: remover o tratamento desse cruzamento faz o teste falhar (foco não
      encontrado/estado inconsistente).
- [ ] **Testes cobrem AC-022-018 (abertura do diálogo de substituição) em unidade — gate 1**
      (achado do `qa` pré-código: o teste de foco acima PRESSUPÕE o diálogo já aberto; falta
      provar que ele de fato ABRE): componente MONTADO, Quadro já vinculado à associação A;
      selecionar a associação B (diferente) no picker embutido → o diálogo
      `role="alertdialog"` de confirmação aparece ANTES de qualquer chamada de mutação
      (`useLinkVisualAssociationToFrameMutation` ainda não disparada); selecionar
      novamente A (a MESMA já vinculada) → nenhum diálogo abre (idempotência de UI, sem
      confirmação desnecessária). Verificação executável: mesmo comando de teste desta TASK
      → `PASS`, 2 cenários nomeados.
- [ ] Cor semântica (lição "[Design] Cor semântica de texto vem de token do tema"): `grep
      -nE "text-(red|green|blue|yellow|orange|purple|pink)-[0-9]"
      src/components/mnemonic-strip-board.tsx` (cwd `mnemonicos-frontend`) → esperado vazio
      (confere que o enxerto não introduziu literal de paleta).
- [ ] Regressão: a suíte `mnemonic-strip-board.test.tsx` já existente (TASK-012-012)
      continua verde após o enxerto — nenhum caso pré-existente (adicionar/editar/remover/
      reordenar/abertura) muda de comportamento (NFR-022-006). Verificação executável: `npx
      jest --runTestsByPath src/components/mnemonic-strip-board.test.tsx` (cwd
      `mnemonicos-frontend`) → `PASS`, todos os casos pré-existentes + os novos desta TASK.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`) — `npx eslint src/components/mnemonic-strip-board.tsx
      src/components/mnemonic-strip-board.test.tsx` (cwd `mnemonicos-frontend`) → 0
      problemas.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil `next-16.md`.
- [ ] Code review aprovado.

## Roteiro do gate 9 (fixado ANTES do código)

Nenhum handoff anterior do slug registra este fluxo como não-exercitável — roteiro novo.

**Ambiente**: mesma receita de TASK-023-012 — backend em `http://localhost:3333/api/v1`,
frontend em `http://localhost:3000`. Tela alvo:
`http://localhost:3000/content/<rawContentId>/tira` (já existente, PLAN-012).

**Sujeito concreto**: EDITOR de teste (realm `editor`, `keelson.local.json`) e, para o passo
de fronteira (abaixo), uma 2ª Tira de autoria do MESMO EDITOR (não é preciso 2º EDITOR nem
ADMIN neste roteiro — o cruzamento exigido pela lição é entre Quadros/Tiras, não entre
autores).

**Pré-condição (montar)**: reusar a receita de `TASK-012-012` (criar Conteúdo bruto como o
EDITOR, salvar a Quebra com os 5 blocos, abrir a Tira — gera 5 Quadros) DUAS VEZES, gerando
`<rawContentId-A>` e `<rawContentId-B>` (2 Tiras distintas do mesmo EDITOR); mais uma
associação visual criada pelo EDITOR (`POST /visual-associations`, fixture PNG real).

**Restaurar ao fim**: mesma receita de `TASK-012-012` para as `production_stage_events`/
`raw_contents` das duas Tiras, mais a limpeza da associação visual (receita de
TASK-023-012).

**Passos (um por AC)**:

1. **AC-022-011 (parte — 3 estados/seleção de UI)**: na Tira A, Quadro 1 sem vínculo,
   acionar "Vincular associação visual" → abrir o picker → selecionar a associação da
   pré-condição. Esperado (via interceptação de rede, decisão 4.319, segurando a resposta):
   controle desabilitado com indicador visível durante a chamada; ao concluir, a miniatura
   aparece no Quadro 1.
2. **Passo de fronteira (lição "AC de interação hierárquica... inclui um passo que cruza a
   fronteira", decisão 4.107 — cruzando TIRAS, não só Quadros do mesmo agrupamento)**: na
   Tira B (Quadro 1, Tira DIFERENTE), vincular a MESMA associação visual já vinculada ao
   Quadro 1 da Tira A. Esperado: a associação passa a estar vinculada a AMBOS os Quadros,
   de Tiras diferentes, sem duplicar a imagem no acervo (AC-022-011, "vinculada a outro
   Quadro" — o código que vincula "dentro" de uma Tira raramente é o que resolve o vínculo
   "entre" Tiras diferentes; este passo é o que alcança essa classe de defeito).
3. **AC-022-012 (parte — 3 estados/UI de desvínculo)**: no Quadro 1 da Tira A (vinculado),
   acionar "Desvincular". Esperado: indicador de "em andamento" com controle desabilitado;
   ao concluir, a miniatura some do Quadro 1 da Tira A, e a associação PERMANECE vinculada
   ao Quadro 1 da Tira B (não removida do acervo).
4. **AC-022-013**: com o Quadro 1 da Tira B ainda vinculado (passo 2), recarregar a página
   (F5). Esperado: a miniatura reaparece junto ao Quadro ao recarregar.
5. **AC-022-017 (parte — comportamento de UI ao remover Quadro vinculado)**: com um Quadro
   vinculado (repetir o vínculo do passo 1 em outro Quadro se necessário), remover esse
   Quadro pelo fluxo de remoção já existente (`role="alertdialog"`, confirmar). Esperado: a
   remoção do Quadro conclui normalmente (sem bloqueio pela existência do vínculo); a
   associação visual permanece no acervo (verificável em `/visual-library`, se TASK-023-015
   já estiver implementada; senão, via `GET /visual-associations` direto).
6. **AC-022-018 (diálogo de confirmação de substituição)**: com um Quadro já vinculado à
   associação A, acionar vincular a associação B (diferente) ao MESMO Quadro. Esperado: o
   diálogo de confirmação de substituição aparece (foco programático no botão de
   confirmação, mesmo padrão do diálogo de remoção); ao confirmar, A é desvinculada e B
   passa a ser a única associação vinculada; repetir vinculando B novamente ao mesmo Quadro
   (já vinculado a B) — esperado: operação idempotente, sem diálogo de confirmação
   (mesma associação já vinculada) e sem erro.

## Riscos específicos

- Reuso do diálogo `role="alertdialog"` já existente (linhas 395-426) para um 2º propósito
  (substituição de vínculo, além de remoção de Quadro) é a MESMA classe de defeito já
  registrada em `lessons.md` (4ª porta do diálogo de remoção, TASK-012-012) — mitigado pelo
  grep exaustivo de setters exigido no Critério de pronto acima.
- **Resolvido pelo Tech Lead na consolidação da rodada**: URL da miniatura corrigida com o
  prefixo `/api/v1` e `<img>` cru trocado por `next/image` (`unoptimized`) — mesma correção
  aplicada em TASK-023-009/012.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-101
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
