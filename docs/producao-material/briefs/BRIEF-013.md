# BRIEF-013: Suporte a PWA no mnemonicos-frontend

**Slug**: producao-material
**Status**: Emitido
**Data**: 2026-09-06
**Largada**: 2026-09-06T21:57:36+0000
**SPEC**: SPEC-013
**Jira**: KAN-64

## Pedido como dito
"Crie uma história para adicionar PDW na aplicação deixe em TODO mesmo" — esclarecido em
seguida que "PDW" era "PWA (Progressive Web App)". A demanda ficou registrada como TODO no
histórico do INDEX.md (triagem `/keelson:triage`, classificada como Categoria 1 — Nova
SPEC). Questionado o racional de produto (a fábrica é uso interno EDITOR/ADMIN, desktop —
o estudante não usa este software), o Diretor respondeu: "Nenhum caso de uso específico, só
quero a capacidade disponível". Em seguida, autorizou: "pode seguir e implementar", com
"Sim, ciclo completo da PWA" confirmado explicitamente.

## Interpretação do PO
Contexto: o mnemonicos-frontend é a fábrica interna de produção do material mnemônico
(uso por EDITOR/ADMIN, desktop) — hoje sem manifest, service worker ou instalabilidade.
Pedido: adicionar suporte a PWA (manifest.json, ícones, service worker, app instalável) ao
mnemonicos-frontend. Premissas decididas: o Diretor confirmou que não há caso de uso de
produto específico agora — a capacidade é pedida por completude/boa prática técnica, sem
gatilho de produto, e entra na SPEC como premissa aberta (revisitável se um caso de uso
real de instalação/uso mobile aparecer — ex.: EDITOR revisando em tablet). Fora de escopo:
comportamento offline de dados (cache de API, fila de sincronização) e push notifications
— PWA aqui é instalabilidade/shell, não app offline-first.

## Premissas decididas

- A capacidade nasce sem gatilho de produto identificado — Diretor confirmou "nenhum caso
  de uso específico, só quero a capacidade disponível" (2026-09-06). Registrada como
  premissa aberta na SPEC, não como racional forte de FR de negócio.
- A fábrica é ferramenta interna de uso desktop por EDITOR/ADMIN; instalabilidade não
  resolve um problema de usuário hoje identificado — risco de produto nomeado, não
  bloqueante.

## Fora de escopo

- Funcionamento offline de dados/API (cache de requests, fila de sincronização em
  background)
- Push notifications
- Qualquer mudança no mnemonicos-backend

## Cronologia

- Largada: 2026-09-06T21:57:36+0000
