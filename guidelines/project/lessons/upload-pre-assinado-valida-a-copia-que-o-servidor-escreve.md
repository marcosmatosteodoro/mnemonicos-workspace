---
area: Segurança
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/pdf-library/**
  - mnemonicos-backend/src/modules/object-storage/**
tags: [upload, presigned-url, toctou, cwe-367, integridade, s3]
---
## [Segurança] Upload por URL pré-assinada valida e calcula o digest sobre a cópia que só o servidor escreve

**Erro:** no PLAN-063 (TASK-063-003, KAN-250, 2026-10-18) a confirmação do envio fazia HEAD, Range
(`%PDF-`) e SHA-256 sobre a chave `pending/` e só depois copiava para `library/`. A URL de PUT seguia
válida por 900 s: um 2º PUT no mesmo endereço, durante a confirmação, promoveu um corpo `<html>…` para
o Acervo com o SHA-256 do PDF original gravado (provado contra o MinIO em 2 de 3 execuções).
**Causa:** enquanto a URL de PUT não expira, o objeto `pending/` é mutável pelo cliente; HEAD, Range,
stream e Copy são leituras separadas sem fixar versão (sem `If-Match`), e a sequência foi tratada como
leitura de um objeto imutável.
**Solução:** promover primeiro (`pending/` → chave definitiva sem URL de escrita emitida) e validar,
medir e hashear a CÓPIA; recusa apaga cópia e `pending/`. Alternativa equivalente: fixar a versão por
ETag (`IfMatch` / `CopySourceIfMatch`). A prova inclui um 2º PUT na mesma URL nas janelas antes, durante
e depois da cópia, com o mutante "ordem antiga" reproduzindo o defeito. Referência:
`mnemonicos-backend/src/modules/pdf-library/pdf-library.service.ts` (`finalizePendingObject`).
