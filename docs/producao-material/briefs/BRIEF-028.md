# BRIEF-028: Versionamento editorial e fechamento legislativo

**Slug**: producao-material
**Status**: Emitido
**Data**: 2026-09-26
**Largada**: 2026-09-26T14:26:48-0300
**Epico**: docs/producao-material/briefs/BRIEF-2026-08-27-mnemora-studio-epic.md
**Jira**: —

## Pedido como dito

> Continuar o épico MNEMORA STUDIO pela fatia 8 da fila: "Versionamento editorial e
> fechamento legislativo" — confirmado pelo Diretor via `/keelson:continue` em
> 2026-09-26 como a próxima fatia a largar (depende de F2 e F6, ambas entregues e
> mergeadas; sem dependência mútua com F9, que depende desta).

Texto completo do pedido épico original: ver BRIEF-2026-08-27-mnemora-studio-epic.md
(seção "Pedido épico", herdado de BRIEF-001).

## Interpretação do PO

**Contexto**: a TAP (§4.4) exige controle de qualidade jurídica com **versão** e **data
de fechamento de legislação** estampadas no PDF que a fábrica emite. Hoje `RawContent`
(F2) só guarda `sourceType`/`sourceCitation`/`sourceUrl` como texto livre e um carimbo
fraco de última edição (`lastEditedById`/`lastEditedAt`, sem trilha histórica) — nenhuma
noção de versão, nenhuma data de fechamento, nenhum histórico append-only
(`mnemonicos-backend/prisma/schema.prisma:302-343`). F9 (Controle de qualidade e gate de
versão aprovada) depende desta fatia para ter o que aprovar; sem F8, o carimbo de F9
seria decorativo.

**Pedido**: dar ao Conteúdo bruto um mecanismo de **versionamento append-only** — cada
edição relevante gera uma versão nova e imutável, com data de fechamento de legislação
declarada pelo EDITOR (não a data de edição do sistema) — e expor essa versão/data no
material publicado (reuso de F6).

**Premissas decididas**: (1) histórico é **append-only** (A08) — nenhuma versão
publicada é editável ou apagável, só superada por uma versão nova; (2) a escolha entre
snapshot imutável do conteúdo inteiro × referência mutável com campo de data isolado é
**decisão arquitetural irreversível**, cabe ao PLAN com alternativas explícitas (risco já
nomeado na fila do épico); (3) F8 não implementa o gate de aprovação em si (isso é F9) —
só o versionamento e a data de fechamento que o gate de F9 vai consumir.

**Fora de escopo**: gate de aprovação/QC jurídico (F9); painel/métricas (F10); fila e
calendário editorial (F11, fora do MVP); qualquer tela ou rota consumida pelo papel
STUDENT.

## Premissas decididas

- [assumido] Histórico de versão é append-only — nenhuma versão publicada é editável ou
  removível, só superada.
- [assumido] Data de fechamento de legislação é campo declarado pelo EDITOR, distinto do
  carimbo técnico de edição (`updatedAt`/`lastEditedAt`).
- [assumido] F8 não decide o gate de aprovação (F9) nem altera o pipeline de PDF em si
  além de estampar versão/data — só cria o mecanismo de versionamento que F9 e F6
  consomem.

## Fora de escopo

- Gate de aprovação / QC jurídico (F9).
- Painel estratégico e tempo por página (F10).
- Fila de produção e calendário editorial (F11, fora do MVP).
- Qualquer tela ou rota consumida pelo papel STUDENT.

## Cronologia

- largada: 2026-09-26T14:26:48-0300
