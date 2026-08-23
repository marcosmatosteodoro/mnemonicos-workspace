# BRIEF-001: Fábrica interna do material mnemônico

**Slug**: producao-material
**Status**: pronto
**Data**: 2026-08-23
**Origem** (versionada, só-leitura — a forja nunca a edita):
- `docs/producao-material/origin/TAP_Projeto_Material_Mnemonico_Alta_Retencao.pdf` — TAP v1.0, 23/08/2026, status "APROVADO PARA DESENVOLVIMENTO DO MVP" (§9.6).
- `docs/producao-material/origin/telas-sugeridas-1-studio.png` — "MNEMORA STUDIO: plataforma interna de produção de material mnemônico", 6 telas do fluxo de produção.
- `docs/producao-material/origin/telas-sugeridas-2-administracao.png` — "Administração da plataforma", 6 painéis de gestão.
- `docs/producao-material/origin/parecer-produto-BRIEF-001.pdf` — Parecer de produto sobre este BRIEF, 23/08/2026: **FAVORÁVEL COM AJUSTES** (8,5/10), "ajustar e aprovar" para SPEC-001.
- Cópias fiéis de `thoughts/implementacoes/1-mvp/` (diretório não versionado), entregues pelo Diretor em 2026-08-23.
**SPEC**: SPEC-001 (ainda não criada — a forja precede o ciclo)

## Pedido como dito

A TAP formaliza um **método** de converter conteúdo jurídico denso em memória recuperável, e é
explícita em que o ativo não é o PDF: *"O ativo principal do projeto não é o PDF. É o método
replicável de converter conhecimento denso em memória recuperável"* (capa, diretriz central).

- **Problema** (§1.2): três — excesso de informação, falsa sensação de aprendizagem (*"reler gera
  familiaridade; familiaridade não equivale a recuperação"*) e interferência da linguagem jurídica.
- **Produto do MVP** (ficha, §3.1): PDF de 15–30 páginas sobre **Obrigação Tributária**.
- **Método** (§3.2): 10 camadas — radar de prova · regra essencial · tira mnemônica (sequência de
  quadros) · associação visual · contraste · pegadinha · pergunta de recuperação (10–15s) ·
  flashcards · recuperação ativa · revisão espaçada R0/R24/R3/R7/R14/R30.
- **Excluído do MVP** (§4.2, §9.2): plataforma própria · aplicativo · assinatura · personalização
  individual · impressão · site complexo.
- **Risco crítico** (§6.2): *"Se cada página se tornar artesanal demais, o modelo não escala.
  Tempo de produção por página deve ser uma métrica do MVP"* — tratado com templates, biblioteca
  de ícones, padrões de tira, prompts reutilizáveis, checklists e layouts padronizados.
- **Validação** (§5.2–§5.4): beta com 10–20 estudantes, teste T0/T24/T7, 20 compras reais a
  R$ 19,90–29,90; princípio 9 (§8.3): *"vender antes de escalar"*.

As **telas sugeridas** (origem, 2026-08-23) nomeiam o produto — "MNEMORA STUDIO, plataforma interna
de produção" — e as páginas necessárias. Fluxo de produção (imagem 1): **Dashboard** (produção em
números) · **Novo Conteúdo** (colar texto jurídico bruto → disciplina, tema, prioridade → *extrair
regra essencial*) · **Quebra da Regra** (blocos CONCEITO → AÇÃO → OBJETO → CONDIÇÃO → EXCEÇÃO, mais
síntese — o modelo da §3.3) · **Gerador de Tiras** (storyboard de quadros numerados, com prévia) ·
**Contrastes e Pegadinhas** (lado a lado, modo comparação) · **Exportação Final** (prévia do PDF,
versão + data da legislação + responsável, checklist de revisão, *Exportar PDF*). Navegação:
Dashboard · Conteúdos · Tiras · Revisão · Biblioteca Visual · Exportações · Configurações.
Gestão (imagem 2): **Fila de Produção** (kanban texto bruto → extração → tiras → revisão jurídica →
pronto, com prioridade e prazo) · **Calendário Editorial** (revisões periódicas R1/R7/R14/R24/R30 do
material, entregas e publicações) · **Biblioteca Visual** (associações por categoria e estilo) ·
**Controle de Qualidade** (checklist de auditoria de 7 itens, com "versão aprovada" como gate) ·
**Versionamento** (versão, data, **mudança legislativa nomeada**, responsável, status, comparar,
histórico) · **Painel Estratégico** (conclusão por módulo, **tempo médio por página**, mais
vendidos, erros na revisão, backlog, próximos lançamentos). Fluxo operacional declarado:
Produzir → Revisar → Aprovar → Exportar → Publicar.

## Interpretação

### Contexto
O workspace tem dois repos de software (`mnemonicos-backend`, `mnemonicos-frontend`) que a TAP não
previu, e cujo escopo até aqui foi construído para um **estudante** consumindo a app. O Diretor
decidiu nesta forja que o software existe, mas **do lado de dentro**: é a fábrica que produz o
material, não o produto que o estudante compra.

### Pedido
Construir a **ferramenta interna de produção** do material mnemônico — o que a §6.2 chama de
templates, biblioteca, padrões de tira e checklists, e o que a §4.4 chama de controle de qualidade
jurídica com versão e data de fechamento de legislação. O que o estudante compra continua sendo o
PDF (§4.2), e **é a fábrica que o emite**: o acervo estruturado entra e o PDF diagramado sai, com
versão e data de fechamento de legislação (§4.4) estampadas pelo próprio pipeline. A régua de valor
da fábrica é a métrica que a própria TAP nomeia e não mede: **tempo de produção por página**.

Quatro capacidades independentes aparecem no inventário, e é por isso que esta demanda não cabe num
ciclo único: (1) **estrutura do acervo** — as 10 camadas modeladas, com a tira como sequência
ordenada de quadros; (2) **pipeline de publicação** — acervo → PDF diagramado, com versão e data de
legislação estampadas; (3) **controle de qualidade jurídica** — checklist da §4.4, fonte normativa
estruturada e histórico de alterações; (4) **medição da própria fábrica** — horas/página
instrumentado, que é a régua de valor. (1) precede (2); (3) e (4) correm em paralelo.

### Premissas decididas
- **A-001** O software é ferramenta interna; o estudante nunca entra nele. `[assumido]`
  `[evidência: crença]` — decidido pelo Diretor nesta forja (2026-08-23, Q-01/Q-02). O selo mede o
  que sustenta a aposta, não a autoridade de quem decidiu: nada foi observado sobre o ganho real da
  fábrica sobre uma ferramenta de mercado.
- **A-002** A tira mnemônica é o ativo defensável (§4.1) e precisa existir como **sequência
  ordenada de quadros**, não como texto corrido. `[assumido]` `[evidência: crença]` — a TAP
  afirma a defensabilidade (§4.1 + capa) sem lastro citado; o `product-analyst` contesta que
  método descrito publicamente seja defensável.
- **A-003** O conteúdo do MVP é Obrigação Tributária (§3.1), não o Direito Administrativo que
  está no seed hoje. `[assumido]` `[evidência: crença]` — §2.2 justifica o nicho por argumento
  (densidade, interferência, testabilidade), sem número que o sustente.
- **A-004** Camadas 7, 9 e 10 (pergunta cronometrada, recuperação ativa, revisão espaçada) são
  **mecanismo**, e em PDF são honor system: a fábrica as **imprime como protocolo** e não as
  executa. A medição do beta acontece **fora do software** — formulário + planilha, com T0 medido
  logo após o estudo e lembretes de T24/T7. `[assumido]` `[evidência: crença]` — decidido pelo
  Diretor nesta forja (2026-08-23, Q-03); nenhuma taxa de resposta de beta anterior foi observada. Consequência aceita: não se mede tempo de resposta nem se
  detecta consulta à resposta.
- **A-005** O código construído para o estudante (`User` + auth, `CardState`, `Review`, scheduler
  SM-2, `study-slice`, vitrine pública) **fica dormente**, sem rota que o exponha, com o motivo
  registrado: construído para a plataforma de estudo, adiada pela §4.2. `[assumido]`
  `[evidência: crença]` — decidido pelo Diretor nesta forja (2026-08-23, Q-05).

- **A-006** As telas sugeridas valem como **UX** — estrutura, fluxo, páginas necessárias e
  vocabulário. **Não** valem como referência visual: desenho, paleta e ilustração são livres, por
  decisão explícita do Diretor (2026-08-23). Por isso este BRIEF **não tem** seção
  `## Referência visual`: a régua do gate de design será o grupo de irmãos do próprio produto, não
  as imagens. `[assumido]` `[evidência: crença]`
- **A-007 — fronteira humano × software** (redação recomendada pelo parecer, incorporada): *"A
  produção intelectual e a aprovação editorial permanecem humanas. A fábrica automatiza estruturação,
  aplicação de templates, paginação, composição, versionamento e exportação do PDF final."*
  `[assumido]` `[evidência: crença]` — resolve a ambiguidade que o parecer apontou entre "diagramação
  é trabalho humano" e "a fábrica emite o PDF diagramado".
- **A-008 — mudança de escopo em relação à TAP, formalizada** (redação recomendada pelo parecer,
  incorporada): *"Esta decisão substitui, exclusivamente quanto à ferramenta interna de produção, a
  exclusão de plataforma própria prevista na TAP. O estudante continua fora do software e o produto
  comercial do MVP continua sendo o PDF."* `[assumido]` `[evidência: crença]` — sem isso, TAP §4.2 e
  este BRIEF ficam como duas fontes em conflito.
- **A-009 — retenção medida ≠ facilidade percebida** (fecha Q-06): duas métricas com nomes e status
  distintos — desempenho em T0/T24/T7 é **decisório**; percepção (Likert) é **diagnóstica**.
  Divergência entre as duas é informação, não erro de medição. `[assumido]`
  `[evidência: crença]` — recomendação de produto no parecer, ainda sem dado.
- **A-010 — revisor jurídico independente no piloto** (fecha Q-08): ao menos um revisor diferente de
  quem produziu o conteúdo. `[assumido]` `[evidência: crença]` — decidido por produto no parecer.
- **A-011 — tempo por página instrumentado desde o primeiro conteúdo** (redação recomendada pelo
  parecer, incorporada): *"O tempo de produção por página será instrumentado desde o primeiro módulo
  e decomposto por etapa, incluindo retrabalho, revisão e exportação."* É **requisito operacional** da
  fábrica, não relatório opcional. `[assumido]` `[evidência: crença]`
- **A-012 — o A/B da tira acontece, sem virar pesquisa acadêmica** (fecha Q-07): o piloto compara
  tira mnemônica × resumo textual de extensão semelhante, mantendo recuperação ativa e revisão
  **iguais nos dois braços**. `[assumido]` `[evidência: crença]` — aprovado por produto no parecer;
  os dois números que tornam o teste falsificável seguem pendentes (Q-11).

### Fora de escopo
- Plataforma de estudo voltada ao estudante, login de estudante, assinatura, personalização
  individual (§4.2, §9.2) — e, por consequência de A-001, também o `CardState` por usuário e o
  scheduler SM-2 que já existem no código.
- **Produção intelectual e aprovação editorial**: redação jurídica, escolha do que entra, julgamento
  da associação e liberação da versão são humanas. A fábrica **não** as substitui — ver A-007 para a
  fronteira exata, que não é "diagramação é humana".
- Instrumento de medição do beta: é formulário + planilha operados à mão (A-004), não software
  deste ciclo. Página de recuperação ativa cronometrada foi considerada e **recusada** — seria
  software voltado ao estudante, contra a anti-persona.
- Checkout, preço, página de oferta (§9.3 item 9) — comercialização é outra capacidade.
- Módulos além de Obrigação Tributária (§7.2 lista 16): "a coleção só deve crescer depois de
  comprovada a demanda" (§7.2).

**Anti-persona**: o **estudante concursando** não é usuário deste software. Se um requisito só faz
sentido para ele, está no slug errado.

## Glossário mínimo

Exigido pelo parecer de produto (ajuste 7) **antes** de os termos virarem entidades e rotas. Cada
termo tem proveniência: âncora na origem, ou premissa declarada quando a origem não decide.

| Termo | Definição | Origem |
|---|---|---|
| **Tira mnemônica** | Sequência **ordenada** de quadros que reconstrói uma regra; cada quadro é uma unidade semanticamente recuperável, no modelo CONCEITO → AÇÃO → OBJETO → CONDIÇÃO/EXCEÇÃO | TAP §3.2 camada 3 e §3.3; tela "Gerador de Tiras" (storyboard numerado). **Não** é o `Mnemonic.hook` atual, que é texto único (`schema.prisma:96-120`) |
| **Quebra da regra** | Decomposição do texto normativo bruto nos blocos CONCEITO · AÇÃO · OBJETO · CONDIÇÃO · EXCEÇÃO, mais a síntese da regra em linguagem tecnicamente correta e reduzida ao núcleo | TAP §3.2 camadas 2–3 e §3.3; tela "Quebra da Regra" |
| **Radar de prova** | Classificação do conteúdo por risco de prova: prioridade alta, média, detalhe, exceção e pegadinha recorrente | TAP §3.2 camada 1. ⚠️ As telas usam três prioridades (Alta/Média/Baixa); o mapeamento entre as **cinco** classes da TAP e as três do mockup **não está decidido** — premissa a resolver na SPEC |
| **Associação visual** | Imagem, cena ou símbolo que serve à recuperação da regra, nunca à decoração; reprovada quando sua remoção não faz perder função cognitiva | TAP §3.3 (regra de descarte) e §8.2 (critério "Necessidade"); tela "Biblioteca Visual" |
| **Versão aprovada** | Estado em que a checagem jurídica e a pedagógica passaram e o material está liberado para exportação — é o **gate**, último item do checklist de auditoria | TAP §4.4; tela "Controle de Qualidade" ("Material liberado para publicação?") |
| **Fonte normativa** | O dispositivo oficial que sustenta a regra: CF, CTN, lei, lei complementar, súmula, ato normativo | TAP §4.3. Hoje é texto livre em `Mnemonic.source`; passa a referência estruturada |
| **Fechamento legislativo** | Data até a qual a legislação foi verificada para aquela versão do material ("legislação verificada até 20/08/2026") | TAP §4.4; telas, campo "Data da legislação" e coluna "Mudança legislativa" |

## Fatos do código

- `Mnemonic.hook` e `Mnemonic.decoding` são campos de **texto único** — a tira como sequência de
  quadros não tem representação estrutural: `mnemonicos-backend/prisma/schema.prisma:96-120`.
- Não existe modelo para radar de prova/priorização, contraste, pegadinha nem associação visual/
  imagem (busca no schema não retornou nada) — 4 das 10 camadas cobertas parcialmente, nenhuma na
  forma que a TAP pede.
- Revisão espaçada existe e é **incompatível por design** com a TAP: variante SM-2 com *ease
  factor* dinâmico e teto de 365 dias (`mnemonicos-backend/src/modules/review/scheduler.ts:43-93`,
  provado em `mnemonicos-backend/tests/unit/scheduler.test.ts:40-58`) contra os seis marcos fixos
  R0/R24/R3/R7/R14/R30 da §3.2 camada 10.
- Rotas montadas hoje: só `health`, `health/db` e `disciplines`
  (`mnemonicos-backend/src/http/routes.ts:9-10`). O frontend já chama `/mnemonics` e
  `/flashcards/due`, que **não existem** no backend (`mnemonicos-frontend/src/store/api.ts:28-35`).
- `User` com `passwordHash` Argon2id e `JWT_SECRET` validado no boot existem
  (`schema.prisma:44-61`, `src/config/env.ts:32-33`), mas **nenhuma rota** de login/registro.
- **Nenhuma** geração ou exportação de PDF nos dois repos — nem dependência, nem rota, nem script.
- Nenhum versionamento editorial: sem data de fechamento de legislação, sem histórico de revisão,
  sem fonte normativa estruturada (só `source` em texto livre no `Mnemonic`).
- Seed tem Direito Administrativo e Constitucional, **não** Direito Tributário
  (`mnemonicos-backend/prisma/seed.ts:28-101`).
- Tipos de domínio **fora de sincronia**: `USER_ROLES` só no backend
  (`src/domain/types.ts:24-26`); `CardState`/`Review` ausentes em
  `mnemonicos-frontend/src/types/domain.ts:41-83`.
- Tamanho real: 13 arquivos de produção + 3 de teste no backend, 12 + 2 no frontend, uma única
  página (`/`), nenhuma tela de estudo; `study-slice` existe e não é consumido por ninguém.

## Perguntas

### Respondidas
- **Q-01** — A TAP exclui plataforma e aplicativo (§4.2, §9.2) e define o MVP como PDF, mas os dois
  repos existem. Qual é o veículo? · **Resposta** (Diretor, 2026-08-23): *"A ideia inicial era usar
  algo do mercado, mas vamos fabricar sim, tão tanto que já temos dois repo pra isso back e front"*
  — construir software próprio.
- **Q-02** — O software é o produto que o estudante compra, ou a ferramenta que produz o material?
  · **Resposta** (Diretor, 2026-08-23): **fábrica interna** — o estudante compra o PDF.
- **Q-03** — As camadas 7/9/10 em PDF são exortação: rebaixar a promessa da §1.5/§8.1 ou entrar
  instrumento de medição? · **Resposta** (Diretor, 2026-08-23): **instrumento mínimo fora da
  fábrica** — formulário + planilha, zero código; a promessa se mantém, medida por fora.
- **Q-04** — O PDF sai da fábrica ou a diagramação é manual em outra ferramenta? · **Resposta**
  (Diretor, 2026-08-23): **a fábrica emite o PDF** — o acervo entra, o PDF diagramado sai. Pipeline
  de publicação é o núcleo do software.
- **Q-05** — O que fazer com o código construído para o estudante? · **Resposta** (Diretor,
  2026-08-23): **manter dormente, com o motivo declarado** (A-005).
- **Q-10** — O "Publicar" do fluxo operacional (imagem 2) diz "publicação na plataforma e
  disponibilização ao aluno", e o painel mostra "módulos mais vendidos" — isso encosta na
  anti-persona? · **Resposta** (Diretor, 2026-08-23): **empacota e entrega por fora** — a fábrica
  fecha a versão, gera o PDF e registra a liberação; a entrega ao aluno é canal externo, e número de
  venda é dado importado, não checkout. A anti-persona fica intacta.
- **Q-06** — Instrumento de cada métrica da §5.4, e a retenção medida se separa da facilidade
  percebida? · **Resposta** (produto, parecer de 2026-08-23): **sim, separar** — percepção mede
  experiência; desempenho mede retenção, via T0/T24/T7 (A-009). Marcada por produto como
  bloqueadora da SPEC e agora fechada. Resíduo: o instrumento das outras cinco dimensões da §5.4
  não veio → Q-12.
- **Q-07** — Qual número refutaria o método, e qual n mínimo torna o piloto inconclusivo? ·
  **Resposta** (produto, parecer de 2026-08-23): **fazer o A/B** tira × resumo com protocolo igual
  nos dois braços, sem transformar o MVP em pesquisa acadêmica (A-012). Resíduo: os dois números —
  limiar de refutação e n mínimo — não vieram → Q-11.
- **Q-08** — Haverá revisor jurídico que não escreveu o material? · **Resposta** (produto, parecer de
  2026-08-23): **sim, revisor independente no piloto** (A-010).
- **Q-09** — Política de atualização e reembolso · **Resposta** (produto, parecer de 2026-08-23):
  **definir antes da primeira venda, não bloqueia código**; distinguir correção de erro do produto
  de grandes atualizações legislativas. Fora do escopo deste software (a fábrica registra versão e
  fechamento legislativo; a política comercial é decisão de produto).

### Pendentes a produto
- **Q-11** — destrava: falsificabilidade de A-002/A-012 · **não bloqueia a SPEC** · contexto: produto
  aprovou o A/B mas não fixou limiar; o protocolo do menor teste exige critério de passa/falha escrito
  **antes** de rodar, senão o resultado vira leitura de borra de café · Qual diferença de recuperação
  em T7 refuta a tira, e com quantas respostas abaixo de N o piloto se declara **inconclusivo** em vez
  de negativo? · **Resposta**: — (pendente desde 2026-08-23)
- **Q-12** — destrava: métricas Uso, Compreensão, Utilidade, Compra e Continuidade (§5.4) · **não
  bloqueia a SPEC** · contexto: Q-06 resolveu Retenção; as outras cinco seguem sem instrumento
  declarado, e "Continuidade" hoje é medida por intenção declarada ("eu compraria o próximo"), que a
  própria §5.3 desqualifica · Qual o instrumento de cada uma? · **Resposta**: — (pendente desde
  2026-08-23)

## Riscos declarados

- **A tira é o ativo declarado e o teste não a isola** (crítica do `product-analyst`, §5.2 vs §4.1):
  a hipótese aplica três tratamentos juntos — reduzir a unidades essenciais, codificar visualmente e
  recuperação ativa. Sinal positivo em T24/T7 não distingue "a codificação visual funciona" de
  "recuperação ativa e espaçamento funcionam, como já se sabe, e as tiras pegaram carona". A coleção
  de 16 módulos (§7.2) está apoiada nisso. `[evidência: crença]`
- **Defensabilidade do método** `[evidência: crença]`: publicar o Manual do Método (§9.3 item 1)
  pode ser publicar o próprio ativo.
- **Preço R$ 19,90–29,90** `[evidência: crença]`: sem benchmark nem teste de preço citado.
- **Tempo de produção por página nunca foi medido** — é a régua de valor desta fábrica e a §5.4 não
  a lista como métrica, embora a §6.2 diga que deve ser uma.
- **Layout como código** (consequência aceita de Q-04): o padrão visual das 10 camadas passa a
  viver no pipeline de publicação, e mudar o padrão passa a exigir deploy. O motor de geração
  (HTML→PDF, LaTeX, outro) é decisão do PLAN, não desta forja.
- **Contrato de API adiantado**: o frontend chama duas rotas inexistentes
  (`mnemonicos-frontend/src/store/api.ts:28-35`) — quebra em runtime sem o typecheck acusar.
- **Medição cega a dois vetores** (consequência aceita de Q-03): formulário + planilha não medem
  tempo de resposta — a única régua que discrimina reconhecimento de evocação — nem detectam quem
  consultou a resposta antes de responder, que é exatamente o estudante que gera a falsa sensação de
  aprendizagem da §1.2.
- **Tabelas dormentes no schema** (consequência aceita de Q-05): `User`, `CardState` e `Review`
  seguem no schema sem escritor. Motivo registrado aqui e no MAP do slug; sem isso, todo leitor
  futuro do código lê como sujeira.
- **Teste da tira aprovado sem limiar** (Q-11): produto aprovou o A/B (A-012) mas não fixou o número
  que refuta nem o n que torna o piloto inconclusivo. Sem eles, qualquer resultado será lido como
  "houve sinal" — e é essa leitura que sustenta a coleção de 16 módulos. Não bloqueia a SPEC da
  fábrica; bloqueia a conclusão do piloto. `[evidência: crença]`
- **Cinco das seis métricas da §5.4 sem instrumento** (Q-12): Q-06 resolveu Retenção; Uso,
  Compreensão, Utilidade, Compra e Continuidade seguem sem fonte de medição declarada.
- **Vocabulário do mockup ainda não é glossário**: "tira", "quebra da regra", "radar de prova",
  "biblioteca visual" aparecem nas telas sugeridas com significado aparente, mas quem escolheu cada
  palavra não está registrado. A SPEC precisa decidir cada termo do domínio com âncora ou premissa —
  não herdar por osmose do desenho.
