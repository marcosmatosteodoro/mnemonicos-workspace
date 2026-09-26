# TASK-027-008: Pegadinha elaborada não refaz a leitura na revisita da tela

**Slug**: producao-material
**Pertence a**: PLAN-027
**Realiza (FRs)**: FR-026-011 (parte — "recarregada a cada visita")
**Funcionalidade**: FEAT-026-002
**Componente**: `ContentSupplementaryPanel` (COMP-027-019 — pendente registrar no PLAN)
**Wave**: 7
**Tamanho estimado**: small
**Tipo**: bug (correção de furo no plano)
**Status**: Done

## Origem

Achada pela **reconfirmação da convergência de fecho** (`code-reviewer`, modo convergência)
na Entrega de PLAN-027 (`/keelson:integrate`), 2026-09-26 — 2ª passada, depois que
TASK-027-007 (Wave 6) fechou os 2 gaps da 1ª passada. Não é achado de nenhum gate de wave.

FR-026-005/011/017 repetem a mesma qualidade não-funcional: "recarregada a cada visita".
Contraste e Flashcard cumprem via `refetchOnMountOrArgChange` nomeado em COMP-027-005/014
(`contrast-list.tsx:81`, `flashcard-list.tsx:85`). Pegadinha elaborada não tem COMP de
lista próprio — é lida pela mesma `useGetRawContentQuery` que `ContentForm` já usa
(`content-supplementary-panel.tsx:30`), **sem** a opção de refetch. Resultado: quem sai da
tela do Conteúdo bruto e volta em até `keepUnusedDataFor` (60s, padrão RTK Query) vê o
valor em cache — se outro EDITOR/ADMIN (ou outra aba da mesma sessão) mudou a Pegadinha
nesse intervalo, a tela mostra texto velho, e um novo "Salvar" o sobrescreve sem o usuário
nunca ter visto a versão real (o campo é last-write-wins por decisão de produto,
RISK-026-004 — o que não está aceito é a EXIBIÇÃO de texto velho, que o FR proíbe).
Mutações feitas na própria sessão continuam coerentes (invalidam a tag `'RawContent'`); o
gap só se manifesta com escritor externo.

**Decisão**: mesma régua de TASK-027-007 — corrigir antes do PR, não estacionar como risco
aceito (achado de severidade baixa, mas é MUST literal do FR e a correção é de 1 linha).

## Escopo

### Inclui

- **Desvio da letra original, registrado na closure**: a implementação inicial (commit
  `eabdf7b`) pôs a opção em `content-supplementary-panel.tsx:36` (o painel), conforme
  redigido abaixo — mas gate 10 (performance) mediu 1 GET redundante em série a cada carga
  FRIA da tela (o painel é subscriber SECUNDÁRIO da mesma cache entry de `ContentForm`,
  monta depois do 1º GET já resolvido, e o RTK Query não dedupa um refetch forçado contra
  entrada `fulfilled`). Retry (commit `94d1c88`) moveu a opção para
  **`mnemonicos-frontend/src/components/content-form.tsx:129`** (o subscriber PRIMÁRIO,
  que sempre monta antes do painel) — medido: fria=1 GET/revisita=+1 GET, sem duplicação.
  Local final: `content-form.tsx:129`, não o painel.
- ~~`mnemonicos-frontend/src/components/content-supplementary-panel.tsx:30` — acrescentar
  `{ refetchOnMountOrArgChange: true }` à chamada de `useGetRawContentQuery` usada para ler
  `pegadinhaText`.~~ (redação original — superada pelo desvio acima)
- Teste de revisita: monta a **composição real** (`ContentDetailPage`), mesmo store nas 2
  montagens, afirmando fria=1 GET e revisita=+1 GET com valor NOVO exibido — mutante
  "remover a opção de `content-form.tsx:129`" e mutante "opção nos 2 subscribers"
  confirmados como capazes de derrubar o teste.

### Não inclui

- Qualquer mudança em Contraste/Flashcard (já corretos).
- RISK-026-004 (concorrência last-write-wins do campo) — decisão de produto já aceita,
  fora desta TASK.
- Os 4 achados de dedup (fora de escopo, declarados na convergência) — não tocar.

## Critérios de pronto

- [ ] `useGetRawContentQuery` em `content-form.tsx:129` (subscriber primário — local final,
      após o desvio registrado em Escopo) usa `refetchOnMountOrArgChange: true`; painel SEM
      a opção.
- [ ] Teste de revisita prova que o request é refeito ao remontar com cache pré-existente,
      SEM GET redundante na carga fria (mutante que remove a opção, e mutante que a duplica
      nos 2 subscribers, falham o teste).
- [ ] Suíte completa (unit + integration) verde, lint/typecheck limpos.
- [ ] Convergência de fecho reconfirmada sem gap novo.

## Riscos específicos

- 2º furo no plano encontrado por convergência de fecho neste mesmo PLAN — mesma classe de
  raiz do 1º (FR com qualidade transversal repetida em sujeitos irmãos, mecanizada só para
  alguns), lição de processo roteada ao `agile-coach`.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-26
**Data conclusão**: 2026-09-26
**Commit SHA**: eabdf7b (implementação, local revisto no retry) · 94d1c88 (retry consolidado gate 1-7+10)
**Jira**: —

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (520/520, mnemonicos-frontend)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (reprovado em eabdf7b — docblock falso + convergente com gate 10; retry 94d1c88 aprovado)
- [x] ACs verificados
- [x] Segurança (gate 8): n/a — mudança de opção de refetch em query existente, sem superfície sensível nova
- [x] Comportamento (gate 9): consolidado FEAT-026-002 — comportamento provado por mutação com composição real (`ContentDetailPage`, mesmo store, 2 gates independentes mediram fria=1/revisita=+1 GET); FEAT-026-002 já tinha gate 9 VERIFICADO em browser real na Wave 6 (TASK-027-007) — esta TASK refina timing de cache, sem nova rodada de browser
- [x] Performance (gate 10): reprovado em eabdf7b (1 GET redundante em série na carga fria, medido) — aprovado no retry 94d1c88 (fria=1/revisita=1, medido de novo, independente)
