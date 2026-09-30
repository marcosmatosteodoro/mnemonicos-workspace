# TASK-035-008: Tela do Painel estratégico — casca, 3 estados, seções e vazios

**Slug**: producao-material
**Pertence a**: PLAN-035
**Realiza (FRs)**: FR-034-004, FR-034-005, FR-034-006, FR-034-008, FR-034-009, FR-034-010, FR-034-011, FR-034-012, FR-034-013, FR-034-017, FR-034-018, FR-034-022, FR-034-023, FR-034-024, FR-034-025, FR-034-027, FR-034-028, FR-034-029, FR-034-030, FR-034-031, FR-034-032, FR-034-033, FR-034-034
**Funcionalidade**: FEAT-034-002 (primária)
**Componente**: COMP-035-020 (principal), COMP-035-021, COMP-035-022
**Wave**: 5
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: TASK-035-007, TASK-035-003
- **Bloqueia**: nenhuma

## Contexto

O placeholder de `(interno)/studio` vira a casca do Painel: Server Component + 1 client
component consumindo `useGetStrategicPanelQuery()`, 3 estados observáveis + vazio global +
vazio por seção, sem biblioteca de gráfico (números/tabelas/barras em CSS com tokens já
existentes). Território e precedentes: `mnemonicos-frontend/src/app/(interno)/studio/page.tsx`
(placeholder atual, INTERNAL_HOME), `mnemonicos-frontend/src/components/content-list.tsx`
(molde de 3 estados: carregando/erro+retry/sucesso, linhas 32-77),
`mnemonicos-frontend/src/app/globals.css` (tokens `--surface`/`--surface-raised`/
`--border-subtle`/`--text-strong`/`--text-muted`/`--link`/`--danger`, utilities
`surface-card`/`text-muted`/`text-link`/`text-danger`; `--color-recall-500`/`-600` — sem
uso hoje, código-scout confirmou), e PLAN-035 §1, §3 (COMP-035-019/020/021/022), §4
Fluxo 5, §6 (DEC-035-020).

**Vertical slicing (princípio 4, deliberadamente maior nesta wave)**: as ACs desta TASK
(AC-034-014/015/016/017/023) descrevem o Painel como comportamento HOLÍSTICO — "sucesso
com as métricas" e "vazio por seção sem ocultar as demais" só se provam com TODAS as
seções coexistindo na mesma tela; dividir por seção fabricaria estados parciais que
nenhuma AC pede isoladamente. É a única TASK de tela do PLAN — igual à orientação do Tech
Lead na decomposição (item 6).

## Escopo

### Inclui

- `mnemonicos-frontend/src/app/(interno)/studio/page.tsx` (reescreve — deixa de ser
  placeholder): casca Server Component (`metadata` mantido, título "Studio" →
  "Painel estratégico") que monta `StrategicPanelBoard` (client component). `INTERNAL_HOME`
  permanece `/studio` — sem mudança em `internal-routes.ts`/`proxy.ts` (DEC-035-020).
- `mnemonicos-frontend/src/components/strategic-panel-board.tsx` (novo, `'use client'`,
  molde de 3 estados de `content-list.tsx:32-77`):
  ```tsx
  export function StrategicPanelBoard() {
    const { data, isLoading, isError, isSuccess, refetch } = useGetStrategicPanelQuery();

    if (isLoading) { /* role="status" aria-live="polite", mesmo padrão de content-list.tsx */ }
    if (isError) { /* role="alert" + botão "Tentar novamente" (refetch()) — NUNCA error.tsx de segmento (DEC-035-020) */ }
    if (!isSuccess) return null;
    if (data.contents.length === 0) { /* vazio global (FR-034-033) */ }

    return (
      <div className="flex flex-col gap-6">
        <TimePerPageSection data={data} />
        <ModuleAggregatesSection data={data} />
        <ModuleCompletionSection data={data} />
        <ReworkSection data={data} />
        <BacklogSection data={data} />
      </div>
    );
  }
  ```
  A falha do Painel é um retorno do CLIENT component (estado de falha com "Tentar
  novamente"), nunca um `error.tsx` de segmento — não regride o destino pós-login
  (AC-034-023, DEC-035-020).
- 5 componentes de seção, co-localizados ou em arquivos próprios (escolha do developer,
  registrada no report — cada um recebe o slice do payload que usa, nunca o payload
  inteiro por prop-drilling cego):
  - **Tempo por página/por etapa por Conteúdo**: tabela — "sem medida"/"em aberto"/"não
    percorrida"/"sem duração medida" como TEXTO (`formatDurationPtBr` só para os valores
    numéricos, TASK-035-003), nunca zero. Vazio da seção (FR-034-034): nenhum Conteúdo com
    tempo por página medido → mensagem própria, sem ocultar as demais seções.
  - **Agregados por Módulo e fábrica**: tabela — média/mediana/n/cobertura
    (`formatDurationPtBr` para média/mediana). Vazio: `n: 0` em todos → mensagem própria.
  - **Conclusão por Módulo**: barra simples em CSS — `@utility bar-fill` novo em
    `globals.css` (`background-color: var(--color-recall-500)`, token já existente e sem
    uso — DEC de escopo desta fatia: nenhuma biblioteca de gráfico, §4.2 SPEC-034), largura
    calculada em JS (`concluidos / ativos * 100`, `style={{ width: ... }}`), fundo em
    `var(--border-subtle)`.
  - **Correções após revisão**: contagem por etapa + legenda fixa (FR-034-032):
    `"edições feitas depois do fechamento de uma Versão"` (texto literal do AC-034-009 —
    conferido contra a SPEC antes de escrito, item h) + indicador geral (FR-034-031).
  - **Backlog**: cada item com etapa mais avançada, prioridade (rótulo pt-BR), idade e o
    marcador `"aprovada, alterada depois — aguarda nova aprovação"` quando aplicável
    (texto literal do glossário SPEC-034 §3), com `<Link href={`/content/${item.contentId}`}>`
    (mesmo padrão de navegação de `content-list.tsx:96`).
- `mnemonicos-frontend/src/types/domain.ts` (estende — COMP-035-022, junto da tela que os
  usa): `PRESENTATION_PRIORITY_LABELS` (`ALTA: 'Alta'`, `MEDIA: 'Média'`, `BAIXA: 'Baixa'`
  — mesmo padrão de `PROOF_RADAR_CLASS_LABELS`), rótulos dos 4 estados de tempo por etapa
  (`'em-aberto': 'Em aberto'`, `'nao-percorrida': 'Não percorrida'`,
  `'sem-duracao-medida': 'Sem duração medida'`, mais o rótulo textual de "sem medida" — os
  NOMES exatos das chaves conferidos contra `StrategicPanelResponse`/`StagePeriodResponse`
  REAIS da TASK-035-007, nunca deduzidos daqui) — nunca string solta no JSX (padrão já
  usado por `PROOF_RADAR_CLASS_LABELS`/`PUBLICATION_VARIANT_LABELS`).
- `mnemonicos-frontend/src/app/globals.css`: `@utility bar-fill` (ver acima).
- Testes co-localizados (perfil §7, Jest+RTL): `strategic-panel-board.test.tsx` — 3
  estados provados no componente MONTADO contra `makeStore()` + `fetch` mockado (lição
  ativa "predicado de decisão de UI a partir de estado RTK Query só se prova no
  componente montado"); **vazio global (AC-034-015, FR-034-033 — prova de gate 1)**:
  resposta mockada com `data.contents: []` (0 Conteúdos ativos), asserção do estado vazio
  global RENDERIZADO e distinto, por conteúdo/role, do estado de sucesso com dado — esta é
  a prova que sustenta AC-034-015 nesta TASK, porque o passo V5 do Roteiro do gate 9 abaixo
  está registrado como não exercitável neste ambiente (nomeando o motivo); vazio por seção
  (fixture de sucesso com 1 seção sem dado, as demais com dado — confirma que as demais
  RENDERIZAM, não some a árvore inteira); marcador "aprovada, alterada depois"; legenda
  fixa das correções após revisão (texto EXATO); barra de conclusão por módulo (largura
  proporcional, checagem do `style` inline ou de um seletor `data-testid`).
- `mnemonicos-frontend/src/app/(interno)/studio/page.test.tsx` (estende o teste já
  existente do placeholder — molde `content/page.tsx` + seu teste, se houver): confirma
  que a página monta `StrategicPanelBoard`, não mais o texto placeholder.

### Não inclui

- `useGetStrategicPanelQuery`/tipos espelhados — TASK-035-007 (consumidos aqui, não
  criados).
- Menu global de navegação — fora de escopo da SPEC (§4.2).
- Filtro por período, exportação do Painel — fora de escopo da SPEC (§4.2).

## Critérios de pronto

- [ ] **Pendência herdada (gate 10 da Wave 4, performance-engineer) — 1 GET por visita**: o endpoint
      usa `forceRefetch: () => true` (não `refetchOnMountOrArgChange` no endpoint). Na tela: (1) UM único
      subscriber de `useGetStrategicPanelQuery` (`StrategicPanelBoard`); as seções recebem slices por
      prop e nunca chamam o hook; (2) não passar `refetchOnMountOrArgChange` no hook; (3) nenhum
      componente montado depois da resposta ou condicionado a `isFetching`/`isSuccess` assina a chave.
      Prova: teste de componente com UM store e `fetch` contado — carga fria = 1 GET `/strategic-panel`;
      desmonta e remonta no mesmo store (revisita) = 2 GETs; mutante (em `git worktree add`) que faz uma
      seção chamar o hook → a contagem da carga fria sobe e o teste reprova.
- [ ] Testes cobrem AC-034-014, AC-034-015, AC-034-016, AC-034-017, AC-034-023 —
      verificação executável: `npm --prefix mnemonicos-frontend test --
      strategic-panel-board.test.tsx` → `OK (N tests)`. Fixada antes do código.
- [ ] `npm --prefix mnemonicos-frontend test -- studio/page.test.tsx` → `OK (N tests)` —
      confirma a casca monta `StrategicPanelBoard`.
- [ ] Falha nunca vira `error.tsx` de segmento (DEC-035-020) — verificação: `find
      mnemonicos-frontend/src/app/\(interno\)/studio -name "error.tsx"` (raiz do
      workspace) → nenhum arquivo; o estado de falha é só o retorno condicional do client
      component, provado no teste montado acima com `queryFulfilled` rejeitando.
- [ ] Legenda das correções após revisão é o texto EXATO da SPEC (item h — literal
      conferido, não parafraseado): `grep -rn "edições feitas depois do fechamento de uma
      Versão" mnemonicos-frontend/src/components | grep -vE '\{/\*|^\s*//|^\s*\*'` (raiz
      do workspace, exclui comentário JSX/docblock — o texto tem de estar no JSX
      renderizado, não só citado num comentário) → ≥ 1 ocorrência.
- [ ] Marcador do backlog é o texto EXATO do glossário (item h): `grep -rn "aprovada,
      alterada depois — aguarda nova aprovação" mnemonicos-frontend/src/components | grep
      -vE '\{/\*|^\s*//|^\s*\*'` (mesma exclusão de comentário) → ≥ 1 ocorrência.
- [ ] Nenhum valor "sem medida"/"em aberto"/"não percorrida"/"sem duração medida"
      renderizado como `0`/vazio silencioso — checagem no teste montado: fixture com
      esses 4 estados produz os 4 TEXTOS na árvore renderizada (`getByText`), nunca `'0'`.
- [ ] Rótulos pt-BR vêm de `Record` em `types/domain.ts`, nunca string solta no JSX —
      `grep -rn "'Alta'\|'Média'\|'Baixa'" mnemonicos-frontend/src/components | grep -vE
      ':\s*(//|\*)'` (raiz do workspace) → 0 ocorrências fora de comentário (os rótulos só
      existem em `domain.ts`, consumidos via `PRESENTATION_PRIORITY_LABELS[...]`).
- [ ] `@utility bar-fill` usa só tokens já existentes (`--color-recall-500`,
      `--border-subtle`) — `grep -n "^@utility bar-fill" -A 3
      mnemonicos-frontend/src/app/globals.css` (âncora em início de linha — a declaração
      do utility, não uma menção em comentário CSS) → nenhuma cor literal da paleta
      Tailwind (`bg-green-500` etc.), só `var(--color-...)`.
- [ ] `npm --prefix mnemonicos-frontend run typecheck` → exit 0.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`) — `npm --prefix mnemonicos-frontend run lint`
      → exit 0.
- [ ] Design/UX (gate 11): `product-designer` revisa contraste dos novos textos de estado
      (usam `text-muted`/`text-danger` já medidos, nenhuma cor literal nova) e a barra de
      conclusão por módulo (contraste do preenchimento contra o fundo, AA componente).
- [ ] Code review aprovado.

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente**: frontend `http://localhost:3000` (`npm --prefix mnemonicos-frontend run
dev`), backend `http://localhost:3333` (`npm --prefix mnemonicos-backend run dev`) —
portas alternativas exigem `CORS_ORIGINS`/`BACKEND_API_URL` ajustados no mesmo turno
(CLAUDE.md do workspace). **Antes do 1º passo**: desregistrar o Service Worker e limpar
Cache Storage (DevTools › Application) ou usar janela anônima — o SW de app-shell pode
servir bundle obsoleto de sessão anterior (HANDOFF-PLAN-033, RISK herdado). Realms de
`keelson.local.json`: `app` (EDITOR) e `admin1` (ADMIN), `loginPath: /login` — mesmas
credenciais de dev já preenchidas para F9 (HANDOFF-PLAN-033).

**Sujeito concreto**: EDITOR autenticado via realm `app` para os passos de leitura;
ADMIN via realm `admin1` só para aprovar a Versão do Conteúdo-piloto (passo de
pré-condição).

**Pré-condição com receita — gerar o Conteúdo-piloto por rotas reais (nunca seed,
RISK-034-004/TRISK-035-004)**:

**Antes do passo 1 — baseline do Módulo (M3)**: como EDITOR ou ADMIN, abra `/studio` e
anote, em Conclusão por Módulo, o Módulo Obrigação Tributária: N Conteúdos ativos, M
Concluídos (valores exibidos agora, antes de qualquer ação do piloto — o acervo de dev
pode já ter Conteúdo permanente do seed, ativo e nunca Concluído, no mesmo Módulo).

1. Como EDITOR, crie um Conteúdo bruto descartável em `/content/new` (módulo Obrigação
   Tributária, mesmo do seed de dev, **Classe no radar: Média**) e salve a Quebra da
   regra em `/content/:id/breakdown`. A classe Média é deliberada: o V8 compara o piloto
   com um Conteúdo Alta mais novo.
2. Abra `/content/:id/tira` e acrescente ao menos 1 Quadro (gera a Tira).
3. Em `/content/:id`, feche uma Versão editorial (registre a fonte normativa antes, senão
   a aprovação recusa).
4. Ainda em `/content/:id`, acione a Exportação da Variante Tira (botão de
   `PublicationExportControl`) — grava `pageCount` (TASK-035-001) e o evento
   `PUBLICACAO_PDF` correlato.
5. Saia, entre como `admin1`, abra o mesmo `/content/:id` e aprove a Versão vigente
   (segregação de funções: `admin1` precisa ser diferente do autor/último editor).
6. Volte como EDITOR (ou fique como `admin1` — o Painel é o mesmo para os 2 papéis,
   FR-034-015) para os passos abaixo.

**Restaurar ao fim**: "Remover" (soft-delete) em `/content/:id` o Conteúdo-piloto **e o
Conteúdo-ordenação do V8**. É reversível, porque o Painel volta a excluí-los de toda
métrica e do backlog (FR-034-014). Depois reabra `/studio` e confirme que nenhum dos dois
aparece no backlog e que as contagens voltaram ao valor anotado no início do V7. Se não
voltaram, registre na Evidência: não restaurado é pendência declarada, nunca omitida.

### V1 — Home da área interna mostra o Painel (AC-034-016, FR-034-018)
- **Passos**: login bem-sucedido como EDITOR (`app`).
- **Esperado**: redireciona para `/studio`, que mostra o Painel (não mais o placeholder
  "A produção de material chega numa próxima fatia").
- **Evidência**: _(preencher)_

### V2 — 3 estados observáveis (AC-034-014, FR-034-017)
- **Passos**: (a) recarregue `/studio` com a aba de rede do DevTools configurada para
  **atrasar** (throttle/`Slow 3G`, ou intercepte `GET /strategic-panel` via DevTools ›
  Network › "Block request URL" temporário) — técnica de interceptação de rede, nunca
  clique+snapshot em API rápida (lição ativa "roteiro que pede falsificar estado
  transitório prescreve interceptação de rede"); (b) deixe a requisição resolver
  normalmente; (c) com o backend ativo, bloqueie especificamente `GET /strategic-panel`
  (DevTools › Network conditions, ou pare o backend um instante) e recarregue.
- **Esperado**: (a) estado "carregando" observável antes da resposta; (b) estado de
  sucesso com as métricas do Conteúdo-piloto visíveis; (c) estado de falha com "Tentar
  novamente" — clicar o botão com o backend religado leva ao sucesso.
- **Evidência**: _(preencher)_

### V3 — Falha nunca vira página de erro (AC-034-023, FR-034-017)
- **Passos**: durante o estado de falha do passo V2(c), confira a URL e a árvore da
  página.
- **Esperado**: a URL continua `/studio` (nenhum redirect), o layout da área interna
  (header, "Sair") permanece visível — nunca uma tela de erro genérica do Next.
- **Evidência**: _(preencher)_

### V4 — Seção sem dado próprio não oculta as demais (AC-034-017, FR-034-034)
- **Passos**: após o passo 2 da pré-condição (Tira registrada) e antes do passo 3
  (fechamento da Versão editorial) — ainda sem Exportação Tira medida para nenhum
  Conteúdo do módulo-piloto, se for o único ativo do Módulo — abra `/studio`.
- **Esperado**: a seção de tempo por página mostra o vazio PRÓPRIO dela ("sem medida"/
  cobertura 0 de N), enquanto Conclusão por Módulo e Backlog aparecem com dado (o
  Conteúdo-piloto no backlog, ainda não Concluído).
- **Evidência**: _(preencher)_

### V5 — Vazio global (AC-034-015, FR-034-033) — não exercitável neste ambiente
- **Decisão do Tech Lead (pacote de correção do PLAN-035)**: este passo NÃO esvazia o
  acervo de dev nem restaura por `UPDATE` direto no Postgres — o acervo de dev é dado
  compartilhado do Diretor (`CLAUDE.md` do workspace), não há rota de undelete, e o único
  caminho de UI para o vazio global exigiria soft-delete em massa de TODO `RawContent`
  ativo com restauração manual arriscada (id esquecido, sessão interrompida no meio).
- **Registro**: passo **não exercitável neste ambiente** — o motivo é o acima, nomeado
  nesta TASK (não herança silenciosa de um handoff anterior).
- **Prova substitutiva aceita**: `strategic-panel-board.test.tsx` (ver Escopo > Inclui) —
  teste de componente MONTADO com resposta mockada de 0 Conteúdos ativos
  (`data.contents: []`), asserção do estado vazio global renderizado e distinto do estado
  de sucesso com dado. Cobre AC-034-015 no gate 1; este passo V5 fica registrado como não
  executado no gate 9.
- **Reabrir se**: um handoff futuro nomear o que mudou no ambiente (ex.: ambiente de dev
  isolado por sessão, rota de undelete) que torne o passo manual seguro de repetir.
- **Evidência**: _(preencher — referenciar a execução do teste de componente citado
  acima; nenhum passo manual em produção/dev é esperado aqui)_

### V6 — Métricas do Conteúdo-piloto batem com as ações reais (AC-034-008/009/010/018/020/021, parte exibição)
- **Passos**: com o Conteúdo-piloto Concluído (pós passo 5 da pré-condição), abra
  `/studio`. **Rode o V6 antes do V7**: o V7 altera o piloto depois da aprovação e o tira
  do estado Concluído.
- **Esperado**: (a) o Módulo do piloto mostra N+1 Conteúdos ativos e M+1 Concluídos, onde
  N/M é a baseline anotada antes do passo 1 da pré-condição (Conclusão por Módulo) — nunca
  o valor absoluto "1 ativo, 1 Concluído" (o acervo de dev pode já ter Conteúdo permanente
  ativo e nunca Concluído, no mesmo Módulo, via seed); (b) o piloto NÃO aparece no backlog
  (Concluído); (c) tempo por página do piloto é um número (não "sem medida"), coerente com
  o intervalo real entre a criação e a Exportação (minutos, não dias, se o roteiro foi
  feito numa sessão); (d) nenhuma etapa aparece com "0".
- **Evidência**: _(preencher — registrar N/M da baseline e N+1/M+1 observados)_

### V7 — Correções após revisão contra ação real (AC-034-009, FR-034-010/011/031/032; marcador FR-034-028/AC-034-018)
- **Passos**: (a) com o piloto Concluído (estado do V6), abra `/studio` e **anote** na
  seção Correções após revisão a contagem da etapa "Conteúdo bruto" do piloto, o total da
  fábrica dessa etapa e o indicador geral de Conteúdos com ao menos uma correção. Anote
  também, em Conclusão por Módulo, os Concluídos do Módulo do piloto. (b) Como EDITOR, em
  `/content/:id` do piloto, edite o texto do Conteúdo bruto (acrescente uma frase, sem
  mudar a Classe no radar) e salve **uma única vez**. Isso gera 1 evento de retrabalho de
  "Conteúdo bruto" depois do fechamento da Versão (RISK-034-002: 1 evento por salvamento
  em F2). (c) Recarregue `/studio`.
- **Esperado**: (a) o piloto não tem correção após revisão antes da edição: os
  retrabalhos anteriores ao fechamento não contam (AC-034-009, parte negativa). (c) Na
  etapa "Conteúdo bruto", a contagem do piloto e o total da fábrica sobem **exatamente
  +1**, sem somar com outras etapas. O indicador geral sobe +1. A legenda "edições feitas
  depois do fechamento de uma Versão" está visível junto da seção. O piloto volta ao
  backlog com o marcador "aprovada, alterada depois — aguarda nova aprovação". Os
  Concluídos do Módulo caem −1 em relação ao valor anotado. O tempo por página do piloto
  não muda (a Exportação de referência continua a mesma).
- **Evidência**: _(preencher — valores antes/depois, não só o valor final: o acervo de
  dev é compartilhado e o total absoluto pode ter dado de outra sessão)_

### V8 — Ordenação do backlog por prioridade (AC-034-010, FR-034-012/013/027; FR-034-030 se observável)
- **Passos**: depois do V7 (piloto no backlog, prioridade Média), como EDITOR, crie em
  `/content/new` um 2º Conteúdo bruto descartável, o "Conteúdo-ordenação", com **Classe no
  radar: Alta** (qualquer Módulo; basta salvar, sem Quebra da regra). Ele é **mais novo**
  que o piloto. Recarregue `/studio`.
- **Esperado**: (a) no backlog, o Conteúdo-ordenação (Alta, mais novo) aparece **acima**
  do piloto (Média, mais antigo): a prioridade vence a idade. Se a ordem fosse só por
  idade, o piloto viria primeiro, e esse é o resultado que falsifica. (b) Cada um mostra a
  etapa mais avançada (Conteúdo-ordenação: "Conteúdo bruto"; piloto: a etapa alcançada no
  roteiro), o rótulo da prioridade ("Alta"/"Média") e uma idade numérica, nunca "0". (c)
  Se o acervo de dev tiver Conteúdo do seed com prioridade Alta (idade "sem medida", seed
  sem eventos), o Conteúdo-ordenação aparece antes dele dentro de Alta (FR-034-030). Se
  não houver, registre "não observável — sem Alta no seed".
- **Evidência**: _(preencher — print ou recorte do backlog com a ordem)_
- **Resíduo declarado**: o desempate por idade dentro da mesma prioridade (FR-034-013, 2ª
  metade) fica provado pelo teste por eixo da TASK-035-004, não por este passo (decisão do
  PO em nome do Diretor, modo resolução, 2026-09-30).

## Riscos específicos

- TRISK-035-004 (PLAN §8) — ambiente sem eventos reais (seed direto não gera
  `ProductionStageEvent`) até o Conteúdo-piloto ser produzido pelas rotas reais; o roteiro
  acima é a mitigação.
- V5 do Roteiro do gate 9 é decidido **não-exercitável neste ambiente** (decisão do Tech
  Lead, pacote de correção do PLAN-035): esvaziar o acervo de dev ou restaurar por
  `UPDATE` direto no Postgres foi descartado por risco ao ambiente compartilhado sem rota
  de undelete. A prova aceita é o teste de componente `strategic-panel-board.test.tsx`
  (vazio global com fixture de 0 Conteúdos ativos, gate 1). Reabrir só mediante handoff
  que nomeie o que mudou no ambiente.
- As quatro seções do Painel são conferidas contra dado real por rotas reais (V4/V6 tempo
  por página e conclusão, V7 correções após revisão, V8 backlog), como pede
  FEAT-034-002. V7 e V8 são aditivos no acervo de dev compartilhado (1 edição e 1
  Conteúdo novo) e são desfeitos por soft-delete no "Restaurar ao fim". A execução fora da
  ordem V6 → V7 → V8 invalida as asserções de delta do V7 e a ordem esperada do V8.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-30T08:10:55-0300
**Data conclusão**: 2026-09-30T10:04:38-0300
**Commit SHA**: 530ee37 (impl) · 75f93dc · afb8798 (retry 1 gates 1/7/11) · 41b59a5 (retry 2) · ac107a6 (merge da main, nova identidade) · 90d7be6 (fim de wave) · d6d1940 (gate 11 contraste da barra na paleta nova) · 4673869 (comentários)
**Jira**: KAN-175

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado — security-engineer (wave 5)
- [x] Comportamento (gate 9): verificado — qa em tela real (Roteiro V1–V4, V6–V8 executados com deltas; V5 n/a por decisão registrada, prova substitutiva no teste de componente); linha na SPEC FEAT-034-002
