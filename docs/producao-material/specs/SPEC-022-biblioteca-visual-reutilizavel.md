# SPEC-022: Biblioteca visual reutilizável

**Slug**: producao-material
**Status**: Approved
**Versão**: 0.2
**Autor**: keelson (scribe)
**Data**: 2026-09-13
**Brief**: BRIEF-022
**Jira**: KAN-85

## 1. Contexto e objetivo

### 1.1 Problema

F4 (Tira mnemônica, SPEC-011/PLAN-012) entregou o Quadro como unidade atômica de texto —
mas nenhum Quadro tem hoje qualquer camada visual: não existe modelo, upload nem reuso de
imagem, ícone ou símbolo no acervo (MAP.md, "Acervo (modelo de dados)": "não existe modelo
para (...) associação visual/imagem no schema atual"). A TAP (BRIEF-001) nomeia a
**Associação visual** como a 4ª camada do método — imagem/cena/símbolo a serviço da
recuperação da regra — e nomeia explicitamente o risco crítico que esta fatia mitiga:
*"se cada página se tornar artesanal demais, o modelo não escala"* (§6.2), tratado com
"templates, biblioteca de ícones, padrões de tira". Sem um acervo pesquisável e
reutilizável, cada Quadro que precisar de imagem exige produção do zero — o mesmo
artesanato que o risco da TAP nomeia.

### 1.2 Outcome esperado

O EDITOR compõe um acervo de associações visuais (imagem + categoria + descrição da
função cognitiva) upload-ável uma única vez e reutilizável entre Quadros de Tiras
diferentes: encontra uma associação existente por categoria a partir de uma tela de
biblioteca, e a vincula a um Quadro específico a partir da própria tela da Tira mnemônica
(F4) — sem reproduzir upload nem produção da mesma imagem para cada Quadro que precisar
dela.

### 1.3 Métrica de sucesso

A régua central do épico ("tempo de produção por página") pertence a F3/F10 e não é
antecipada aqui (mesma postura de SPEC-009/SPEC-011 §1.3). O efeito verificável próprio
desta fatia passa a ser a **proporção de vínculos criados que reusaram uma associação
visual já existente no acervo, sobre o total de vínculos criados** ("uploads evitados") —
mede trabalho poupado pelo acervo, não só o formato final que ele assume. A **taxa de
reuso** original (associações vinculadas a 2 ou mais Quadros sobre o total de associações
visuais existentes) permanece como indicador **secundário**, útil para acompanhar a forma
do acervo ao longo do tempo. Como a biblioteca ainda não existe, não há medição prévia — o
limiar abaixo é estimativa inicial (A-022-010, §8), não fato medido; e o contrapeso
qualitativo do critério herdado da TAP ("reprovada se removê-la não perde função
cognitiva") é gate de F9 (qualidade/aprovação), fora desta fatia — esta métrica mede
reuso, não valida se o reuso preserva função cognitiva.

**Fonte de medição**: instrumentação — consulta que conta, na criação de cada vínculo, se
a associação visual vinculada é reuso de uma já existente ou recém-criada nesse mesmo
fluxo (razão "reuso" sobre total de vínculos criados no período), apurável a qualquer
momento sobre o modelo de vínculo desta fatia; a taxa de reuso secundária (2+ Quadros por
associação) segue apurável pela mesma consulta original; dono: time de engenharia. Meta
inicial: ao menos 30% de "uploads evitados" em 60 dias corridos após a entrega desta
fatia — vira veredito de métrica no ciclo seguinte, mesma régua das demais SPECs do slug
(decisão 4.99).

## 2. Personas e jobs-to-be-done

Como EDITOR da fábrica, preciso de um acervo de imagens/ícones que eu possa buscar por
categoria e vincular ao Quadro que estou produzindo, para ilustrar a Tira mnemônica sem
desenhar ou providenciar uma imagem nova toda vez que uma regra parecida precisar da mesma
associação visual.

Anti-persona (decisão 4.98, herdada): não é para o estudante — a biblioteca é ferramenta
interna de produção, mesma postura de todo o slug.

## 3. Glossário (Ubiquitous Language)

| Termo | Definição | Origem |
|-------|-----------|--------|
| Associação visual | Imagem/cena/símbolo a serviço da recuperação da regra; reprovada se removê-la não faz perder função cognitiva (reusado, não redefinido) | INDEX.md / BRIEF-001 |
| Biblioteca visual | Acervo pesquisável e navegável de associações visuais, organizado por categoria, reutilizável entre Quadros de Tiras diferentes — tela nomeada nas telas sugeridas do épico | BRIEF-001 (telas sugeridas) / BRIEF-022 |
| Categoria (da associação visual) | Rótulo textual atribuído pelo EDITOR para agrupar e filtrar associações visuais na biblioteca; campo de texto livre nesta fatia, não uma lista fechada (A-022-004, §8), com sugestão das categorias já existentes ao digitar (FR-022-025) e normalização (trim/case-fold) aplicada na exibição e no filtro (NFR-022-007) — não é mais texto livre puro sem qualificação | Decisão do PO, gate de aprovação desta SPEC (crítica do product-analyst + veredito do po) |
| Função cognitiva (da associação visual) | Justificativa textual, escrita pelo EDITOR, de por que a imagem apoia a recuperação da regra — não decoração; critério herdado da TAP ("reprovada se removê-la não perde função cognitiva") | BRIEF-001 |
| Vínculo (associação visual ↔ Quadro) | Relação N:N que liga uma associação visual a um ou mais Quadros — o que torna a associação visual reutilizável; a mesma associação pode ilustrar Quadros de Tiras diferentes | Decisão do Diretor, largada desta SPEC (BRIEF-022) |

## 4. Escopo

### 4.1 In-scope

- Modelo de associação visual: imagem (formato raster), categoria (texto) e descrição da
  função cognitiva, cada um obrigatório.
- Upload de imagem com validação **server-side** por assinatura de bytes (magic number) —
  aceita somente raster (PNG/JPEG/WebP), recusa qualquer arquivo cuja assinatura não
  corresponda, independentemente de extensão ou `Content-Type` declarado.
- Validação server-side de tamanho máximo do arquivo enviado.
- CRUD completo da associação visual: criar, editar categoria/descrição/imagem
  (in-place), remover.
- Trava de remoção: associação visual vinculada a 1 ou mais Quadros não pode ser removida
  enquanto o vínculo existir.
- Tela de navegação/busca da biblioteca visual, com listagem e filtro por categoria.
- Vínculo N:N entre associação visual e Quadro (`MnemonicFrame`, F4) — a mesma associação
  visual pode vincular a múltiplos Quadros, de Tiras diferentes ou da mesma Tira — ação de
  vincular e desvincular a partir da tela da Tira mnemônica (`(interno)/content/[id]/tira`).
- Exibição da associação visual vinculada ao reabrir a tela da Tira mnemônica (par de
  leitura, decisão 4.225).
- Barreira de autorização EDITOR/ADMIN (nunca STUDANTE/STUDENT nem acesso anônimo) em toda
  superfície desta fatia, mesmo padrão das fatias anteriores.

### 4.2 Out-of-scope

- Motor de publicação/diagramação em PDF (F6) — quem lê "biblioteca visual" poderia
  assumir o posicionamento da imagem na página impressa junto; esta fatia só produz o
  acervo e o vínculo, não a saída diagramada.
- Geração ou sugestão automática de imagem por IA generativa — fora do inventário
  original do PM e sem pedido do Diretor.
- Upload de SVG ou qualquer formato vetorial/baseado em marcação — quem lê "imagem"
  poderia assumir vetor editável junto; esta fatia aceita só raster (A-022-001, §8), pelo
  risco de XSS/XXE sem sanitização (A02/A08) já declarado no épico; reabrir quando o
  motor de PDF (F6) exigir vetor editável.
- Edição de imagem dentro do produto (recorte, redimensionamento, filtro) — o EDITOR
  envia o arquivo já pronto; o sistema não transforma o binário.
- Versionamento/histórico da imagem de uma associação visual — quem lê "editar a
  associação visual" poderia assumir histórico de versões junto; esta fatia trata a edição
  como substituição in-place, sem trilha (A-022-008, §8); versionamento editorial fica
  para F8.
- Segmentação de "categoria" e "estilo" como dois campos independentes — a TAP e as
  telas sugeridas citam "categoria e estilo" juntos; esta fatia modela uma única dimensão
  textual de categorização (A-022-009, §8); segmentar em dois campos é revisão futura.
- Job de limpeza/alerta de associação visual sem nenhum Quadro vinculado (órfã) — permitir
  a existência de associações órfãs é o comportamento esperado de uma biblioteca (upload
  adiantado, vínculo posterior); não há rotina de limpeza nesta fatia (A-022-006, §8).
- Decisão de armazenamento do binário (sistema de arquivos local vs. blob externo) —
  decisão técnica do PLAN, não desta SPEC.
- Contrastes, pegadinhas e flashcards impressos (F7), versionamento editorial e
  fechamento legislativo (F8), gate de qualidade/aprovação (F9), painel estratégico
  (F10) — fatias futuras do épico, sem sobreposição com esta.
- Acesso de STUDENT/estudante final — ferramenta interna de produção, anti-persona.

## 5. Requisitos funcionais (EARS)

### FEAT-022-001: Gestão do acervo de associações visuais

**Jira**: KAN-86

> Do ponto de vista do QA: um EDITOR faz upload de uma imagem raster com categoria e
> descrição, edita ou substitui esses dados depois, e remove uma associação visual —
> exceto quando ela ainda está vinculada a algum Quadro, caso em que a remoção é recusada.

**Verificação (gate 9)**: 2026-09-13 — APROVADO (comportamento funcional). Exercitado com
execução real (backend `createApp()` via `npm run dev` :3333 + Postgres real de dev;
frontend `next dev` :3000; identidade confirmada pelos processos já de pé apontando para
este worktree; branch `feat/producao-material-mnemora-studio`, backend HEAD `cfbded7`,
frontend HEAD `28c2894`, `git status` limpo antes/depois, sem mudança concorrente):
AC-022-001 (PNG real por assinatura de bytes → 201), AC-022-002 (SVG renomeado `.png` →
400, sem criar), AC-022-003 (PNG válido de 6 MB → 413 antes de processar), AC-022-004
(campos obrigatórios ausentes → 422/400), AC-022-006 (PATCH edita in-place, mesmo id, sem
duplicar), AC-022-007 (DELETE sem vínculo → 204, some), AC-022-008 (DELETE com vínculo
ativo real, criado via link de verdade a um Quadro → 409, linha íntegra), AC-022-019
(cenário com 2 autores: EDITOR só vê o próprio vínculo em `reachableLinks` e
`outOfReachCount` sem identificar; ADMIN vê os 2 identificados), AC-022-020 (2º EDITOR
recebe 403 com a MESMA mensagem em PATCH e DELETE da associação de outro autor; ADMIN
escreve com sucesso), NFR-022-003 cross-cutting (STUDENT 403, anônimo 401 nas 3 rotas).
Suíte automatizada (por arquivo): rotas 31/31, service 2/2, model 3/3, storage 2/2,
route-authz-matrix 36/36, guard-order 2/2; frontend `visual-library-board.test.tsx` 9/9
(3 estados AC-022-005, filtro AC-022-010, sugestão AC-022-022). Dados de teste criados e
removidos ao final, banco restaurado. **Pendente de tela** (causa: artefato ausente —
`GET /visual-associations` e a rota `/visual-library` só chegam em TASK-023-014/015, Wave
5 — não é credencial/runtime): a caminhada em browser real do Roteiro do gate 9 já fixado
em TASK-023-012 (upload via `<input type=file>` real, miniatura `next/image`, F5 reload,
sugestão viva). Seed de verificação registrada no report do `qa` (handoff a consolidar
quando TASK-023-014/015 fecharem). **Nota de sequência — resolvida**: gate 8 da mesma wave achou uma corrida TOCTOU real em
`removeVisualAssociation` (AC-022-008 sob concorrência) — fechada com `SELECT ... FOR
UPDATE` na linha pai antes do `deleteMany`, provada por execução real de concorrência
(`Promise.all` disputando link×remove contra Postgres de teste, mutante que remove o lock
reprova 4/4). Gate 8 reaprovado na 2ª rodada da Wave 4; FEAT-022-001 completou nesta wave
(5/5 TASKs Done).

- **FR-022-001** [MUST] Quando um EDITOR ou ADMIN envia um arquivo para criar uma nova
  associação visual, o sistema deve validar a assinatura de bytes (magic number) do
  arquivo e aceitar somente arquivos cuja assinatura corresponda a um formato raster
  (PNG, JPEG ou WebP).
- **FR-022-002** [MUST] Se o arquivo enviado não corresponder, por sua assinatura de
  bytes, a nenhum dos formatos raster aceitos — independentemente da extensão do nome do
  arquivo ou do `Content-Type` declarado pelo cliente —, então o sistema deve recusar o
  upload e informar o motivo, sem criar a associação visual.
- **FR-022-003** [MUST] Se o arquivo enviado exceder o tamanho máximo permitido, então o
  sistema deve recusar o upload e informar o motivo, sem criar a associação visual.
- **FR-022-004** [MUST] O sistema deve exigir, para toda associação visual criada, uma
  categoria (texto) e uma descrição da função cognitiva que a imagem cumpre, além da
  imagem — a ausência de qualquer um dos três impede o salvamento.
- **FR-022-005** [MUST] Quando um EDITOR ou ADMIN cria, edita ou remove uma associação
  visual, o sistema deve expor três estados observáveis ao usuário: em andamento (ação
  disparada, resultado pendente — controle desabilitado e/ou indicador visível), sucesso
  e falha, cada um com indicação visível.
- **FR-022-006** [MUST] O sistema deve permitir editar a categoria, a descrição e
  substituir a imagem de uma associação visual existente sem criar uma nova entidade.
- **FR-022-007** [MUST] Quando um EDITOR ou ADMIN remove uma associação visual sem
  nenhum Quadro vinculado, o sistema deve excluí-la do acervo.
- **FR-022-008** [MUST] Se um EDITOR ou ADMIN tenta remover uma associação visual
  vinculada a 1 ou mais Quadros, então o sistema deve recusar a remoção e informar a
  existência de vínculos ativos.
- **FR-022-009** [MUST] Quando uma associação visual é criada ou editada com sucesso, o
  sistema deve exibir os dados salvos (imagem, categoria, descrição) ao reabrir a tela de
  gestão do acervo.

### FEAT-022-002: Navegação e busca da biblioteca por categoria

**Jira**: KAN-87

> Do ponto de vista do QA: um EDITOR abre a biblioteca, vê o acervo existente com
> miniatura, categoria e quantos Quadros cada associação já ilustra, e filtra por
> categoria para achar a que precisa.

**Verificação (gate 9)**: 2026-09-14 — APROVADO (comportamento funcional). Exercitado com
execução real (backend `createApp()` via `npm run dev` :3333 + Postgres real de dev;
frontend `next dev` :3000; identidade confirmada: processos iniciados nesta sessão a
partir do próprio worktree, backend HEAD `3fc9b9a`, frontend HEAD `51f4a50`, branch
`feat/producao-material-mnemora-studio`, `git status` idêntico antes/depois do exercício
em ambos os repos — sem mudança concorrente): AC-022-009 (`GET /visual-associations` real
+ tela `/visual-library` real, logado como EDITOR: listagem mostra categoria e `linkCount`
corretos, refletindo dados reais do backend em tempo real), AC-022-010 (filtro por
categoria — via UI e via HTTP direto — devolve só a associação daquela categoria; filtro é
por categoria específica/normalizada, não substring — comportamento correto por design do
`equals` normalizado do service, confirmado não ser regressão), AC-022-022 (sugestão de
categoria ao digitar "Categ" no formulário de criação exibe, via HTTP real, as 2
categorias existentes que combinam), AC-022-025 (normalização trim/case-fold: filtro por
"categoria qa gate9" minúsculo casa com "Categoria QA Gate9" armazenada, texto original
preservado, confirmado por leitura direta). Suíte automatizada (rodada pelo `qa`, filtro
mais amplo que o gate 2 por cobrir a FEAT inteira): `visual-associations.routes.integration.test.ts`
47/47, `visual-associations.service.test.ts` (`normalizeCategoryKey`/`suggestCategories`)
11/11, `route-authz-matrix.integration.test.ts` 36/36, frontend `visual-library-board.test.tsx`
18/18, `proxy.test.ts` (guard de `/visual-library`) 55/55. Dados de teste (2 associações
visuais, 2 Conteúdos brutos/Tiras) criados via API real e removidos ao final (`db:psql`),
acervo restaurado a vazio (`GET /visual-associations` → `total:0` confirmado).
**Achado fora de escopo** (não bloqueia, sinal ao Tech Lead): `GET
/visual-associations/:id/image` (TASK-023-016, ainda não implementada) devolve 403
(deny-by-default de rota não montada) — miniaturas não carregam na tela ainda; esperado,
fora do escopo desta wave.


- **FR-022-010** [MUST] O sistema deve prover uma tela de navegação da biblioteca visual
  que lista as associações visuais existentes no acervo.
- **FR-022-011** [MUST] Quando o usuário filtra a biblioteca por uma categoria, o sistema
  deve exibir somente as associações visuais daquela categoria.
- **FR-022-012** [MUST] O sistema deve exibir, para cada associação visual listada, a
  miniatura da imagem, a categoria e o número de Quadros aos quais está vinculada.
- **FR-022-025** [MUST] Quando o usuário digita uma categoria nova no formulário de
  associação visual, o sistema deve sugerir as categorias já existentes no acervo que
  combinam com o texto digitado.

### FEAT-022-003: Vínculo de associação visual a Quadros da Tira mnemônica

**Jira**: KAN-88

> Do ponto de vista do QA: a partir da tela da Tira mnemônica de um Quadro específico, o
> EDITOR seleciona uma associação visual da biblioteca (nova ou já usada em outro Quadro)
> e a vincula; pode desvincular depois sem apagar a associação do acervo; e a imagem
> vinculada reaparece ao recarregar a tela.

**Verificação (gate 9)**: 2026-09-14 — APROVADO (comportamento funcional). Mesma execução
real e mesma prova de identidade/estabilidade do bloco de FEAT-022-002 acima (mesmos HEADs,
mesma janela, sem mudança concorrente nos dois repos). Exercitado ponta-a-ponta via HTTP
real e via UI (Playwright, logado como EDITOR, tela `/content/<id>/tira`): AC-022-011
(vincular associação nova a um Quadro sem vínculo — via API e via UI/picker; e vincular a
MESMA associação a um Quadro de OUTRA Tira — `linkCount` sobe para 2, `total` do acervo
permanece 1, sem duplicar a imagem), AC-022-012 (desvincular — via UI: miniatura/estado
somem do Quadro desvinculado, associação permanece vinculada ao outro Quadro, `linkCount`
decrementa corretamente 2→1, confirmado por leitura direta do backend), AC-022-013 (reload
real da tela da Tira após login exibe o vínculo persistido — confirmado pela renderização
de "Desvincular"/"Trocar associação visual" no Quadro certo ao reabrir a rota), AC-022-008/
AC-022-019 (`DELETE` da associação vinculada → 409 com `reachableLinks` identificando os 2
vínculos do próprio EDITOR e `outOfReachCount:0`; listagem confirma o item intacto com
`linkCount` correto durante a recusa), AC-022-017 (remoção de Quadro vinculado pela UI —
diálogo `alertdialog`, confirmar — conclui sem bloqueio; associação preservada no acervo,
`linkCount` decrementa), AC-022-018 (troca de associação vinculada — diálogo de confirmação
de substituição abre ANTES da mutação, foco no botão "Confirmar substituição", controles
dos OUTROS Quadros ficam desabilitados enquanto o diálogo está aberto; ao confirmar, A
desvinculada e B única vinculada, confirmado via leitura direta do backend; repetir
vinculando a MESMA associação já vinculada não reabre diálogo — idempotente, sem erro).
Suíte automatizada: `mnemonic-strip-board.test.tsx` 46/46 (inclui os `describe` novos de
vincular/desvincular/substituir + regressão de PLAN-012 — NFR-022-006), demais suítes
compartilhadas com FEAT-022-002 acima. Dados de teste (2 Tiras, 2 associações, vínculos
cruzados) criados via API real e removidos ao final, acervo restaurado a vazio.
**Achado fora de escopo** (não viola nenhum AC citado acima, sinal ao Tech Lead):
`linkVisualAssociationToFrame`/`unlinkVisualAssociationFromFrame` (`store/api.ts`) só têm
`invalidatesTags: ['MnemonicStrip']` — não invalidam `'VisualAssociationList'`. Confirmado
ao vivo: após vincular "Categoria QA Gate9" a um Quadro (`linkCount` real = 1, confirmado
por `GET /visual-associations` direto), o picker embutido reaberto na MESMA sessão
(componente canônico compartilhado com a tela `/visual-library`,
`visual-association-list-states.tsx`) ainda mostrava "0 vínculos" para essa associação —
contagem desatualizada até um refetch por outro caminho (ex.: navegar para
`/visual-library`). Não viola nenhum AC-022-011/012/013/.../018 citado (nenhum exige
contagem ao vivo no picker embutido, só na tela da biblioteca — AC-022-009 — onde a
contagem sempre bateu no teste acima), mas é uma lacuna real de cache que pode subestimar
o reuso visível ao EDITOR durante a mesma sessão de vínculo. Correção sugerida: somar
`'VisualAssociationList'` a `invalidatesTags` das 2 mutações de vínculo/desvínculo.


- **FR-022-013** [MUST] Quando um EDITOR ou ADMIN está na tela da Tira mnemônica de um
  Quadro específico, o sistema deve permitir selecionar uma associação visual da
  biblioteca e vinculá-la a esse Quadro.
- **FR-022-014** [MUST] O sistema deve permitir vincular a mesma associação visual a
  múltiplos Quadros, de Tiras diferentes ou da mesma Tira, sem duplicar a imagem no
  acervo.
- **FR-022-015** [MUST] Quando um EDITOR ou ADMIN desvincula uma associação visual de um
  Quadro, o sistema deve remover o vínculo sem remover a associação visual do acervo.
- **FR-022-016** [MUST] Quando um Quadro com associação visual vinculada é exibido na
  tela da Tira mnemônica — inclusive ao recarregar a tela —, o sistema deve exibir essa
  associação visual junto ao Quadro.
- **FR-022-017** [MUST] Quando um EDITOR ou ADMIN aciona vincular ou desvincular uma
  associação visual a um Quadro, o sistema deve expor três estados observáveis ao
  usuário: em andamento, sucesso e falha, cada um com indicação visível.
- **FR-022-018** [MUST] Se um EDITOR ou ADMIN tenta vincular, desvincular ou consultar o
  vínculo de um Quadro fora do alcance por autoria que F4 já aplica ao Quadro (resolução
  da cadeia rawContentId→RuleBreakdown→MnemonicStrip→MnemonicFrame — NFR-011-001 de
  SPEC-011; MAP.md, seção F4: "o rawContentId a autorizar é sempre resolvido pela CADEIA
  Frame→Strip→RuleBreakdown→RawContent, nunca aceito cru do path"), então o sistema deve
  responder da mesma forma que responderia a um Quadro inexistente, nunca distinguindo
  "não existe" de "existe mas não alcança" (mesmo padrão de AC-011-022 de SPEC-011). ADMIN
  alcança qualquer Quadro.
- **FR-022-019** [MUST] O sistema deve desconsiderar, para a trava de remoção
  (FR-022-008), para a contagem exibida (FR-022-012) e para a métrica de §1.3, qualquer
  vínculo cujo Quadro tenha Conteúdo bruto de origem removido (soft-delete, inalcançável —
  NFR-011-006/AC-011-020 de SPEC-011).
- **FR-022-020** [MUST] Quando um Quadro vinculado a uma associação visual é removido
  (ação de F4), o sistema deve remover o vínculo e preservar a associação visual no
  acervo — a remoção do Quadro nunca deve ser bloqueada por causa do vínculo.
- **FR-022-021** [MUST] Quando um EDITOR ou ADMIN vincula uma associação visual a um
  Quadro que já tem uma associação vinculada, o sistema deve pedir confirmação explícita
  e, ao confirmar, substituir o vínculo anterior (cardinalidade: no máximo 1 associação
  visual por Quadro nesta fatia); quando o EDITOR ou ADMIN vincula a mesma associação já
  vinculada ao mesmo Quadro, o sistema deve tratar a operação como idempotente, sem
  duplicar o vínculo nem retornar erro.
- **FR-022-022** [MUST] Quando a remoção de uma associação visual é recusada por vínculo
  ativo (FR-022-008), o sistema deve identificar, para o usuário que aciona a remoção, os
  Quadros/Tiras vinculados que ele alcança por autoria (ADMIN vê todos); vínculo fora do
  alcance do usuário deve ser informado como existente, sem identificar o Quadro/Tira.
- **FR-022-023** [MUST] O sistema deve restringir a escrita sobre uma associação visual
  (editar categoria/descrição, substituir imagem, remover) ao EDITOR que a criou, com
  exceção do ADMIN, que pode escrever em qualquer uma; a leitura, a busca e o vínculo
  (ler/vincular/desvincular) do acervo devem ser comuns a todo EDITOR/ADMIN, independente
  de quem criou a associação.
- **FR-022-024** [MUST] Quando um EDITOR ou ADMIN vincula pela primeira vez uma associação
  visual a um Quadro sem vínculo (1ª mutação humana de vínculo daquele Conteúdo bruto), o
  sistema deve emitir um evento de etapa de produção (valor novo, aditivo, mesmo padrão de
  F3/SPEC-009 e F4/SPEC-011 — `ProductionStageEvent`); o CRUD isolado do acervo
  (criar/editar/remover associação visual, fora de uma ação de vínculo) não deve emitir
  evento — não pertence a um Conteúdo bruto específico.

## 6. Requisitos não-funcionais

- **NFR-022-001** [MUST] Toda validação de tipo de arquivo desta superfície DEVE ocorrer
  no servidor, por assinatura de bytes (magic number) — nunca confiar em extensão de
  nome de arquivo nem em `Content-Type` declarado pelo cliente.
- **NFR-022-002** [MUST] O sistema NÃO PODE aceitar arquivos SVG nem qualquer formato
  vetorial/baseado em marcação como imagem de associação visual, mitigando o risco de
  XSS/XXE por upload sem sanitização (A02/A08 do OWASP).
- **NFR-022-003** [MUST] Toda rota e tela desta superfície DEVE exigir sessão autenticada
  com papel EDITOR ou ADMIN — nunca STUDENT nem acesso anônimo (deny-by-default, mesmo
  padrão herdado de SPEC-002).
- **NFR-022-004** [MUST] O sistema DEVE recusar, no servidor, qualquer upload cujo
  tamanho exceda o teto máximo configurado (A-022-005, §8), antes de processar ou
  persistir o arquivo.
- **NFR-022-005** [MUST] A barreira de NFR-022-003 (deny-by-default EDITOR/ADMIN) DEVE se
  estender à entrega do binário da imagem (download/exibição direta), nunca só à
  rota/tela de gestão — requisição anônima ou sem o alcance por autoria de FR-022-018 DEVE
  ser recusada mesmo pedindo o binário diretamente.
- **NFR-022-006** [MUST] Esta fatia NÃO PODE regredir o comportamento já entregue da tela
  `(interno)/content/[id]/tira` (F4/PLAN-012): geração inicial idempotente via `POST`,
  CRUD e reordenação atômica dos Quadros, emissão do evento `TIRA_MNEMONICA`, e o alcance
  por autoria de F4 continuam intactos.
- **NFR-022-007** [SHOULD] O agrupamento e o filtro por categoria (FR-022-011) DEVEM
  aplicar normalização (trim + case-fold) para reduzir fragmentação por variação de
  digitação — sem impedir texto livre na entrada (FR-022-025 cobre a sugestão; esta é a
  normalização na exibição/filtro).

## 7. Critérios de aceitação (Given-When-Then)

- **AC-022-001** (cobre FR-022-001, NFR-022-001)
  Dado um EDITOR enviando um arquivo cuja assinatura de bytes corresponde a um PNG,
  JPEG ou WebP válido, quando ele confirma o upload, então o sistema aceita o arquivo e
  cria a associação visual.

- **AC-022-002** (cobre FR-022-002, NFR-022-001, NFR-022-002)
  Dado um EDITOR enviando um arquivo renomeado com extensão ".png" cujo conteúdo binário
  não corresponde a nenhum formato raster aceito — incluindo um arquivo SVG renomeado —,
  quando ele confirma o upload, então o sistema recusa o upload, informa o motivo e não
  cria a associação visual.

- **AC-022-003** (cobre FR-022-003, NFR-022-004)
  Dado um EDITOR enviando um arquivo de imagem raster válido que excede o tamanho máximo
  permitido, quando ele confirma o upload, então o sistema recusa o upload antes de
  processar o arquivo e informa o motivo.

- **AC-022-004** (cobre FR-022-004)
  Dado um EDITOR preenchendo o formulário de nova associação visual sem categoria ou sem
  descrição da função cognitiva, quando ele tenta salvar, então o sistema recusa o
  salvamento e indica os campos obrigatórios pendentes.

- **AC-022-005** (cobre FR-022-005)
  Dado um EDITOR acionando a criação de uma nova associação visual, então, enquanto o
  upload está em andamento, o controle de salvar fica desabilitado com indicador visível;
  ao concluir com sucesso, o sistema confirma a criação de forma visível; e, se a
  operação falhar por qualquer motivo, o sistema informa o erro de forma visível sem
  perder os dados já preenchidos no formulário.

- **AC-022-006** (cobre FR-022-006, FR-022-009)
  Dada uma associação visual existente, quando um EDITOR edita a categoria, a descrição
  ou substitui a imagem e salva com sucesso, então o sistema persiste a alteração sem
  criar uma nova entidade e a exibe atualizada ao reabrir a tela de gestão do acervo.

- **AC-022-007** (cobre FR-022-007)
  Dada uma associação visual sem nenhum Quadro vinculado, quando um EDITOR aciona
  remover, então o sistema exclui a associação visual e ela deixa de aparecer na
  biblioteca.

- **AC-022-008** (cobre FR-022-008)
  Dada uma associação visual vinculada a 1 ou mais Quadros, quando um EDITOR aciona
  remover, então o sistema recusa a remoção e informa a existência de vínculos ativos,
  sem excluir a associação visual.

- **AC-022-009** (cobre FR-022-010, FR-022-012)
  Dado um acervo com associações visuais cadastradas, quando a tela de navegação da
  biblioteca visual é aberta, então o sistema lista as associações existentes, cada uma
  com miniatura, categoria e o número de Quadros aos quais está vinculada.

- **AC-022-010** (cobre FR-022-011)
  Dado um acervo com associações visuais de mais de uma categoria, quando o usuário
  filtra a biblioteca por uma categoria específica, então o sistema exibe somente as
  associações visuais daquela categoria.

- **AC-022-011** (cobre FR-022-013, FR-022-014, FR-022-017)
  Dado um EDITOR na tela da Tira mnemônica de um Quadro sem associação visual vinculada,
  quando ele seleciona uma associação visual da biblioteca já vinculada a outro Quadro e
  confirma o vínculo, então, enquanto a operação está em andamento, o controle de
  vincular fica desabilitado com indicador visível, e, ao concluir com sucesso, a mesma
  associação visual passa a estar vinculada a ambos os Quadros, sem duplicar a imagem no
  acervo.

- **AC-022-012** (cobre FR-022-015, FR-022-017)
  Dado um Quadro com uma associação visual vinculada, quando o EDITOR aciona
  desvincular, então, enquanto a operação está em andamento, o controle de desvincular
  fica desabilitado com indicador visível, e, ao concluir com sucesso, o vínculo é
  removido sem que a associação visual seja apagada do acervo.

- **AC-022-013** (cobre FR-022-016)
  Dado um Quadro com uma associação visual vinculada, quando a tela da Tira mnemônica é
  recarregada, então o sistema exibe a associação visual junto ao Quadro.

- **AC-022-014** (cobre NFR-022-003)
  Dado um usuário autenticado com papel STUDENT, ou uma requisição sem sessão válida,
  quando ele tenta criar, editar, vincular, desvincular ou remover uma associação visual,
  então o sistema recusa a operação.

- **AC-022-015** (cobre FR-022-018)
  Dado um EDITOR autenticado tentando vincular, desvincular ou consultar o vínculo de um
  Quadro cujo Conteúdo bruto de origem ele não alcança (registrado por outro EDITOR),
  quando ele aciona a operação, então o sistema recusa com a mesma resposta que usa para
  um Quadro inexistente, sem distinguir "não existe" de "existe mas não alcança"; um
  ADMIN, na mesma situação, realiza a operação normalmente.

- **AC-022-016** (cobre FR-022-019)
  Dado um Quadro vinculado a uma associação visual cujo Conteúdo bruto de origem foi
  removido (soft-delete, inalcançável), quando o sistema avalia a trava de remoção da
  associação visual (FR-022-008), calcula a contagem exibida na biblioteca (FR-022-012)
  ou apura a métrica de §1.3, então esse vínculo não é contado como ativo em nenhuma das
  três situações.

- **AC-022-017** (cobre FR-022-020)
  Dado um Quadro vinculado a uma associação visual, quando um EDITOR ou ADMIN remove esse
  Quadro pela tela da Tira mnemônica (F4), então o sistema remove o vínculo, preserva a
  associação visual no acervo, e a remoção do Quadro conclui sem ser bloqueada pela
  existência do vínculo.

- **AC-022-018** (cobre FR-022-021)
  Dado um Quadro já vinculado a uma associação visual A, quando um EDITOR ou ADMIN
  seleciona vincular a associação visual B ao mesmo Quadro, então o sistema pede
  confirmação explícita antes de substituir o vínculo, e, ao confirmar, A é desvinculada e
  B passa a ser a única associação vinculada; dado o mesmo Quadro já vinculado à
  associação B, quando o EDITOR aciona vincular B novamente, então o sistema não duplica
  o vínculo nem retorna erro.

- **AC-022-019** (cobre FR-022-022)
  Dada uma associação visual vinculada a Quadros de Tiras de diferentes autores, quando um
  EDITOR tenta removê-la e o sistema recusa por vínculo ativo (FR-022-008), então o
  sistema identifica, para esse EDITOR, os Quadros/Tiras vinculados que ele alcança por
  autoria, e informa a existência dos demais vínculos sem identificar o Quadro/Tira que o
  EDITOR não alcança; um ADMIN vê todos os vínculos identificados.

- **AC-022-020** (cobre FR-022-023)
  Dada uma associação visual criada por um EDITOR, quando outro EDITOR tenta editar sua
  categoria/descrição, substituir a imagem ou removê-la, então o sistema recusa a
  escrita; quando esse mesmo outro EDITOR busca, lista ou vincula/desvincula essa
  associação a um Quadro que alcança, então o sistema permite a operação normalmente; um
  ADMIN escreve em qualquer associação visual.

- **AC-022-021** (cobre FR-022-024)
  Dado um Quadro sem vínculo, quando um EDITOR ou ADMIN vincula pela primeira vez uma
  associação visual a ele, então o sistema emite um evento de etapa de produção para o
  Conteúdo bruto correspondente; dado um CRUD isolado do acervo (criar, editar ou remover
  uma associação visual fora de uma ação de vínculo), quando ele ocorre, então nenhum
  evento de etapa é emitido.

- **AC-022-022** (cobre FR-022-025)
  Dado um EDITOR digitando uma categoria no formulário de associação visual, quando o
  texto digitado combina com categorias já existentes no acervo, então o sistema sugere
  essas categorias para seleção.

- **AC-022-023** (cobre NFR-022-005)
  Dada uma requisição anônima ou de sessão STUDENT, pedindo diretamente o binário de uma
  imagem de associação visual (download ou exibição), quando a requisição chega ao
  servidor, então o sistema recusa a entrega do binário, mesmo sem passar pela rota ou
  tela de gestão. Sessão EDITOR/ADMIN válida basta — a barreira é a MESMA deny-by-default
  comum a toda a fatia (NFR-022-003), nunca uma restrição adicional por alcance de
  FR-022-018: o acervo é comum a todo EDITOR/ADMIN (FR-022-023), então mesmo um EDITOR
  sem nenhum vínculo com o Quadro que usa a imagem lê o binário normalmente (A-023-001,
  PLAN-023 §1).

  **Verificação (gate 9)**: 2026-09-14 — VERIFICADO. Exercitado via suíte de integração
  (60/60 + 36/36 `route-authz-matrix`) + HTTP real (`curl`, upload multipart PNG real +
  comparação md5 byte-a-byte) + browser real (Playwright, login EDITOR, `/visual-library`
  carregando a miniatura pela URL do endpoint): 401 sem sessão, 403 STUDENT, 200 para
  EDITOR sem alcance por FR-022-018 sobre o Quadro (comportamento intencional, A-023-001),
  200 para ADMIN, 404 id inexistente, `Content-Type` nunca ecoa a coluna `mimeType`
  corrompida (500 genérico). Detalhe completo no ledger de sessão.

- **AC-022-024** (cobre NFR-022-006)
  Dada a suíte de testes automatizados já existente de PLAN-012 (F4) para a tela
  `(interno)/content/[id]/tira` — geração inicial idempotente via `POST`, CRUD e
  reordenação atômica dos Quadros, emissão do evento `TIRA_MNEMONICA` e alcance por
  autoria —, quando essa suíte roda após a implementação desta fatia, então todos os
  casos continuam passando sem alteração de comportamento, no mesmo espírito de
  AC-016-007/NFR-016-003 de SPEC-016.

- **AC-022-025** (cobre NFR-022-007)
  Dado o acervo com associações visuais cujas categorias variam por capitalização ou
  espaçamento (ex.: "Tributário" e " TRIBUTÁRIO "), quando o usuário agrupa ou filtra a
  biblioteca por categoria, então o sistema trata essas variações como a mesma categoria
  na exibição e no filtro, sem alterar o texto livre armazenado na entrada original.
  Variação por ACENTO (ex.: "Tributário" vs. "Tributario") fica FORA desta normalização
  — NFR-022-007 é trim + case-fold, nunca accent-fold; texto anterior deste AC citava um
  exemplo com variação de acento simultânea à de capitalização, inconsistente com o
  mecanismo prescrito (corrigido nesta revisão — achado do code-reviewer, Wave 5 de
  PLAN-023). `Reabrir se:` reincidência real de queixa de fragmentação por acento
  demandar accent-folding — aí DEC-023-008 (PLAN-023) reabre para prever `unaccent`/
  coluna normalizada, decisão do Diretor por envolver migração.

## 8. Premissas e decisões prévias

- **A-022-001** [assumido] [evidência: crença] Formato de imagem aceito: raster
  (PNG/JPEG/WebP), sem SVG cru — decisão já tomada na origem (BRIEF-022) pelo risco de
  XSS/XXE sem sanitização (A02/A08), declarado desde a decomposição do épico (F5,
  BRIEF-2026-08-27-mnemora-studio-epic). Reabrir só se a fábrica precisar de vetor
  editável, decisão de F6 (motor de PDF) em diante.
- **A-022-002** [assumido] [evidência: crença] Validação de tipo e tamanho do arquivo é
  server-side, por assinatura de bytes — nunca por extensão ou `Content-Type` declarado
  pelo cliente — decisão já tomada na origem (BRIEF-022), antecipando a mesma régua que
  F6 vai exigir para qualquer asset que entra no pipeline de exportação.
- **A-022-003** [assumido] [evidência: crença] O armazenamento do binário (sistema de
  arquivos local vs. blob externo) é decisão técnica do PLAN, fora do escopo desta SPEC.
- **A-022-004** [assumido] [evidência: crença] Categoria é um campo de texto livre, não
  um enum fechado, nesta fatia — nem a TAP nem as telas sugeridas nomeiam uma lista
  fechada de categorias, e fechar uma taxonomia agora, sem inventário real do acervo,
  arriscaria uma lista errada. Reabrir se o volume do acervo tornar a navegação por texto
  livre inconsistente (RISK-022-001, §9).
- **A-022-005** [assumido] [evidência: crença] Tamanho máximo de arquivo: 5 MB por
  imagem — default razoável para raster destinado a uma página de PDF impresso, sem
  medição real de uso. Reabrir se o motor de PDF (F6) exigir resolução maior
  (RISK-022-003, §9).
- **A-022-006** [assumido] [evidência: crença] Uma associação visual pode existir sem
  nenhum Quadro vinculado (órfã) — comportamento esperado de uma biblioteca (upload
  adiantado, vínculo posterior); não há job de limpeza de órfãs nesta fatia.
- **A-022-007** [assumido] [evidência: crença] A remoção de uma associação visual
  vinculada a 1 ou mais Quadros é recusada — o EDITOR precisa desvincular antes. Default
  seguro que evita quebrar Tiras existentes silenciosamente, consistente com a filosofia
  de remoção reversível já usada em Conteúdo bruto (SPEC-005).
- **A-022-008** [assumido] [evidência: crença] Substituir a imagem, a categoria ou a
  descrição de uma associação visual existente é edição in-place, sem histórico de
  versões — versionamento fica para F8 (versionamento editorial).
- **A-022-009** [assumido] [evidência: crença] "Categoria" cobre também a noção de
  "estilo" citada na TAP e nas telas sugeridas — uma única dimensão textual de
  categorização nesta fatia. Segmentar em dois campos independentes é revisão futura,
  sem pedido do Diretor até aqui.
- **A-022-010** [assumido] [evidência: crença] Métrica §1.3: o limiar de 30% de taxa de
  reuso em 60 dias é uma estimativa inicial sem medição prévia (a biblioteca ainda não
  existe) — vira veredito de métrica no ciclo seguinte, mesma régua das demais SPECs do
  slug (decisão 4.99).
- **A-022-011** [assumido] [evidência: medido] O acervo de associações visuais é de
  leitura/busca/vínculo comum a todo EDITOR/ADMIN, mas a escrita (editar/substituir/
  remover) é restrita ao autor (ADMIN alcança tudo, FR-022-023) — default do `po` sobre
  uma ambiguidade escalada ao Diretor, **confirmado pelo Diretor na Entrega de PLAN-023
  (2026-09-14)**: decisão definitiva, não mais pendente.
- **A-022-012** [assumido] [evidência: medido] A instrumentação de etapa desta fatia
  (FR-022-024) é mínima por decisão do `po` sobre uma ambiguidade escalada ao Diretor —
  **confirmado pelo Diretor na Entrega de PLAN-023 (2026-09-14)**: decisão definitiva,
  não mais pendente.

## 9. Riscos e questões abertas

- **RISK-022-001** Categoria como texto livre sem normalização pode fragmentar a
  navegação por categoria se o acervo crescer sem curadoria (ex.: "Tributário" vs.
  "tributario" tratados como categorias distintas) — mitigação recomendada: normalização
  (trim/case-fold) na exibição e no filtro, sem impedir o texto livre na entrada; decisão
  técnica do PLAN.
- **RISK-022-002** A métrica primária de §1.3 ("uploads evitados") depende da disciplina
  de busca do EDITOR antes de subir uma imagem nova: se ele não busca no acervo antes de
  fazer upload, sempre cria uma associação nova, mesmo que já exista uma equivalente — o
  número medido reflete esse hábito, não só o valor real de reuso possível das imagens.
  Mitigada em parte pela sugestão de categorias já existentes ao digitar (FR-022-025), mas
  não pela busca de imagem em si (fora do escopo desta fatia); revisitar se o piloto
  mostrar baixa adesão à busca antes do upload.
- **RISK-022-003** O teto de tamanho de arquivo (5 MB, A-022-005) é uma estimativa sem
  dado real de uso; se o motor de PDF (F6) exigir resolução ou qualidade maior, o teto
  pode precisar subir, reabrindo a validação de tamanho e possivelmente a decisão de
  armazenamento (A-022-003).
- **RISK-022-004** O reuso da mesma associação visual em Quadros/Tiras diferentes reduz
  a rastreabilidade de "quem introduziu a imagem originalmente" por vínculo — sem
  requisito de proveniência de autoria por vínculo nesta fatia; pode importar para F8/F9
  (revisão jurídica/editorial de imagem).
- **RISK-022-005** Listar N associações visuais com miniatura (FR-022-012) sem derivar
  arquivo processado (a miniatura é o binário original redimensionado na exibição, "sem
  processamento de imagem" mantido da premissa do brief) tem custo de banda real com
  acervo grande e arquivos de até 5 MB (A-022-005) — entra como atenção obrigatória do
  gate 10 (performance) e do PLAN junto com Q-022-001 (paginação).
- **Q-022-001** Se o acervo crescer substancialmente, a listagem/filtro da biblioteca por
  categoria pode precisar de paginação ou ordenação — não decidido nesta SPEC; fica para
  o PLAN avaliar o volume esperado.

## 10. Fora deste documento

Arquitetura, stack, modelagem de dados e plano de tarefas vão para `/keelson:plan` e
`/keelson:tasks`.
