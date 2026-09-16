# BRIEF-026: Contrastes, pegadinhas, flashcards e protocolos impressos

**Slug**: producao-material
**Status**: Emitido
**Data**: 2026-09-15
**Largada**: 2026-09-15T19:36:12-0300
**SPEC**: SPEC-026
**Epico**: docs/producao-material/briefs/BRIEF-2026-08-27-mnemora-studio-epic.md
**Jira**: KAN-121

## Pedido como dito

> Continuar o épico MNEMORA STUDIO pela fatia 7 da fila: "Contrastes, pegadinhas,
> flashcards e protocolos impressos" — confirmado pelo Diretor via `/keelson:continue`
> em 2026-09-15 como a próxima fatia a largar (depende de F2 e F6, ambas entregues;
> sem dependência mútua com F8, a ordem declarada da fila decide).

Texto completo do pedido épico original: ver BRIEF-2026-08-27-mnemora-studio-epic.md
(seção "Pedido épico", herdado de BRIEF-001).

## Interpretação do PO

**Contexto**: F7 reúne os 4 sub-temas que o `pm` não separou em fatia própria na
decomposição original do épico — contraste entre institutos semelhantes, pegadinha
(erro comum de prova), flashcard e protocolo impresso de revisão com os 6 marcos fixos
R0/R24/R3/R7/R14/R30 que a TAP pede. Depende de F2 (Conteúdo bruto + radar de prova,
já persiste a classe `PEGADINHA`) e F6 (pipeline de PDF), ambas entregues e mergeadas.

**Pedido**: dar a esses 4 conceitos, ainda sem modelo de dados, uma representação
estruturada na fábrica — culminando em material impresso/PDF (reuso de F6), nunca em
tela interativa.

**Premissas decididas**: (1) anti-persona vale à risca — flashcard e protocolo de
revisão são conteúdo **autorado pelo EDITOR** e emitido como PDF, nunca uma tela de
estudo/revisão para o STUDENT; (2) os 6 marcos fixos do protocolo impresso são
etiqueta/checklist textual impressa — o scheduler SM-2 existente (`review/scheduler.ts`,
dormente por A-005) não é reusado, por incompatibilidade de design já registrada no
risco da fatia no épico; (3) "pegadinha" já tem a classe do radar persistida em
`RawContent.radarClass` (F2) — F7 acrescenta o campo elaborado (por que o erro é comum),
não recria a classificação existente.

**Fora de escopo**: qualquer interação do STUDENT com o sistema (marcar "revisei",
progresso de revisão); o carimbo de versão aprovada (F9); geração automática de
contraste/pegadinha por IA.

## Premissas decididas

- [assumido] Flashcard e protocolo impresso são artefatos de autoria/exportação, nunca
  tela de estudo — anti-persona do épico, risco já nomeado na fila de F7.
- [assumido] Os 6 marcos fixos (R0/R24/R3/R7/R14/R30) do protocolo impresso não reusam
  o scheduler SM-2 (`review/scheduler.ts`) — modelo de dados novo e independente.
- [assumido] Radar de prova (`ProofRadarClass`) permanece a fonte da classificação
  "pegadinha"; F7 não duplica nem redefine essa taxonomia.

## Fora de escopo

- Qualquer tela ou rota consumida pelo papel STUDENT.
- Carimbo de versão aprovada / gate de QC jurídico (F9).
- Geração automática (IA) de contraste, pegadinha ou flashcard a partir do texto bruto.

## Cronologia
- largada: 2026-09-15T19:36:12-0300
- specify: 2026-09-16T07:45:06-0300 · correções: 1 · classes: spec-ac-fora-gwt(23, falso positivo) · spec-ears-nao-casa(3) · spec-nfr-sem-numero(5) · spec-must-ratio(1) · spec-sem-should-may(1)
- plan: 2026-09-16T08:11:22-0300 · correções: 1 · classes: plan-dec-irreversivel-enum(8, falso positivo) · plan-dec-alternativa-unica(7)
