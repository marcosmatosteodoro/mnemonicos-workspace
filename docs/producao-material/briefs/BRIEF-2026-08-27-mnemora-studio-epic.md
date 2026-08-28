# BRIEF épico: MNEMORA STUDIO — fábrica interna do material mnemônico

**Slug**: producao-material
**Status**: em execução
**Data**: 2026-08-27
**Origem**: docs/producao-material/briefs/BRIEF-001.md
**Branch**: feat/producao-material-mnemora-studio
**Estratégia**: unica
**Jira**: KAN-6

## Pedido épico (verbatim, herdado de BRIEF-001)

> A TAP formaliza um **método** de converter conteúdo jurídico denso em memória recuperável,
> e é explícita em que o ativo não é o PDF: *"O ativo principal do projeto não é o PDF. É o
> método replicável de converter conhecimento denso em memória recuperável"* (capa, diretriz
> central).
>
> Construir a **ferramenta interna de produção** do material mnemônico — o que a §6.2 chama
> de templates, biblioteca, padrões de tira e checklists, e o que a §4.4 chama de controle
> de qualidade jurídica com versão e data de fechamento de legislação. O que o estudante
> compra continua sendo o PDF (§4.2), e **é a fábrica que o emite**: o acervo estruturado
> entra e o PDF diagramado sai, com versão e data de fechamento de legislação (§4.4)
> estampadas pelo próprio pipeline. A régua de valor da fábrica é a métrica que a própria TAP
> nomeia e não mede: **tempo de produção por página**.
>
> Anti-persona: o **estudante concursando** não é usuário deste software. Se um requisito só
> faz sentido para ele, está no slug errado.

Texto completo, premissas seladas (A-001 a A-012), glossário, fatos do código e perguntas
pendentes (Q-11, Q-12): ver BRIEF-001.md (origem, acima).

## Decomposição do PM

O BRIEF original propunha 4 capacidades ("(1) precede (2); (3) e (4) em paralelo"). O `pm`
confirmou parcialmente e corrigiu: (1) não cabe numa fatia só (vira 4: conteúdo/quebra, tira,
biblioteca visual, contrastes+protocolos); (3) QC jurídico **não** é paralelo a (2) — o
pipeline v1 emite rascunho, o carimbo oficial vem do QC; (4) medição separa-se em captura
cedo (F3) e painel tarde (F10); e o inventário original não continha **acesso/papéis
internos** (pré-requisito do gate de aprovação) nem **fila/calendário editorial** (proposto
fora do MVP).

## Fila

| # | Fatia | Slug de destino | Estado |
|---|---|---|---|
| 1 | Acesso interno e papéis de produção | producao-material | em ciclo (docs/producao-material/briefs/BRIEF-002.md) |
| 2 | Conteúdo bruto, quebra da regra e fonte normativa | producao-material | pendente |
| 3 | Instrumentação de etapas da fábrica | producao-material | pendente |
| 4 | Tira mnemônica como sequência de quadros | producao-material | pendente |
| 5 | Biblioteca visual reutilizável | producao-material | pendente |
| 6 | Pipeline de publicação — PDF (rascunho) | producao-material | pendente |
| 7 | Contrastes, pegadinhas, flashcards e protocolos impressos | producao-material | pendente |
| 8 | Versionamento editorial e fechamento legislativo | producao-material | pendente |
| 9 | Controle de qualidade e gate de versão aprovada | producao-material | pendente |
| 10 | Painel estratégico e tempo por página | producao-material | pendente |
| 11 | Fila de produção e calendário editorial *(fora do MVP — confirmado pelo Diretor)* | producao-material | pendente |

## Dependências por fatia

- F1 → nenhuma.
- F2 → F1.
- F3 → F2.
- F4 → F2.
- F5 → F4.
- F6 → F4, F5.
- F7 → F2, F6.
- F8 → F2, F6.
- F9 → F1, F8.
- F10 → F3 (essencial); F8, F9 (parcial).
- F11 → F2, F9. Fora do MVP por decisão do Diretor (2026-08-27) — reavaliar quando existir o
  2º/3º módulo (§7.2 da TAP: "a coleção só cresce depois de comprovada a demanda").

## Riscos por fatia

- **F1**: sem authz server-side (deny-by-default), o gate de F9 é decorativo; rotas de login
  novas exigem rate limit/expiração/rotação de sessão (A07); reinterpreta A-005 — `User`/auth
  acordam para o time interno, mas `CardState`/`Review`/scheduler/papel STUDENT continuam
  dormentes.
- **F2**: RDR-001 sem decisão (5 classes de radar da TAP × 3 prioridades do mockup) — resolver
  como premissa na SPEC; contrato de API fantasma (`/mnemonics`, `/flashcards/due`) já
  chamado pelo frontend sem existir no backend; tipos de domínio fora de sincronia entre os
  dois repos.
- **F3**: se confundida com o painel (F10) e adiada, viola A-011 (instrumentação desde o
  primeiro conteúdo); "página" ainda sem denominador definido antes de F6 existir.
- **F4**: A-002 é `[evidência: crença]`, contestada pelo product-analyst; ordenação de quadros
  sem transação quebra a tira silenciosamente.
- **F5**: upload de imagem exige validação server-side de tipo/tamanho, sem SVG cru (A02/A08);
  antecipa decisão de formato que o motor de PDF (F6) ainda vai exigir.
- **F6**: motor HTML→PDF com rede aberta ou sem escape de conteúdo é SSRF (A01) e injeção
  (A05) a partir do servidor; escolha do motor é irreversível na prática (muda o padrão
  visual das 10 camadas para dentro do deploy); emite também a variante "resumo" do braço de
  controle do A/B (A-012) por decisão do Diretor (2026-08-27).
- **F7**: risco de deslize para tela de estudo (viola a anti-persona); scheduler SM-2
  existente é incompatível por design com os marcos fixos R0/R24/R3/R7/R14/R30 — não reusar.
- **F8**: histórico editável destrói a própria função (A08 — precisa ser append-only);
  snapshot imutável × referência mutável é decisão arquitetural irreversível do PLAN.
- **F9**: fail-open no catch é o defeito clássico e aqui tem consequência jurídica; A-010
  (revisor ≠ autor) exige 2+ pessoas no time interno — inexequível com operação de 1 pessoa.
- **F10**: Q-12 em aberto (5 das 6 métricas da §5.4 sem instrumento) — nasce só com o que a
  fábrica mede sozinha (tempo/página por etapa, retrabalho, erros de revisão, backlog); venda
  e métricas do beta entram, se entrarem, como dado importado rotulado como tal.
- **F11**: nome R1/R7/R14/R24/R30 do calendário editorial colide em vocabulário (não em
  função) com a revisão espaçada do estudante — distinguir explicitamente se a fatia for
  retomada.

## Premissas e perguntas sem fatia de software (portfólio, não órfãs)

- **A-009** (retenção decisória × facilidade percebida diagnóstica) e **A-012** (exceto a
  variante "resumo" do braço de controle, que é saída de F6) vivem na operação do beta
  (formulário + planilha, A-004) — nenhuma fatia as implementa.
- **Q-11** (limiar de refutação e n mínimo do piloto) — já registrado como risco ativo
  PIL-001 no INDEX; não bloqueia nenhuma SPEC, bloqueia a conclusão do piloto e a decisão
  sobre os 16 módulos futuros (§7.2).

## Perguntas ao Diretor — respondidas na decomposição (2026-08-27)

1. F1 entra em primeiro e reinterpreta A-005 (só `User`/auth acordam; `CardState`, `Review`,
   scheduler e papel STUDENT seguem dormentes) — **confirmado**.
2. Pipeline v1 (F6) emite PDF marcado como rascunho; carimbo oficial só com F8+F9 —
   **confirmado**.
3. F6 também emite a variante "resumo" do braço de controle do A/B (A-012) —
   **confirmado**.
4. F11 (fila de produção + calendário editorial) fica fora do MVP — **confirmado**.
5. F10 nasce só com o que a fábrica mede sozinha; venda e métricas do beta ficam fora até
   Q-12 responder — **confirmado**.

## Cronologia

- 2026-08-27: decomposição via /keelson:specify-epic (agent `pm`), confirmada pelo Diretor.
- 2026-08-27: Diretor liga `jira.enabled: true`; `createmeta` do projeto KAN medido
  (Epic `10006`, Story `10009`, Subtask `10007`, Task `10008`) e gravado na ficha e em
  `docs/_meta/jira.KAN.md`; Epic-raiz criado — `KAN-6`.
