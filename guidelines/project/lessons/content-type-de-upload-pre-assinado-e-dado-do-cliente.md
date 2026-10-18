---
area: Segurança
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/object-storage/**
  - mnemonicos-backend/src/modules/pdf-library/**
tags: [upload, presigned-url, s3, content-type, xss, cwe-79]
---
## [Segurança] Content-Type de upload por URL pré-assinada é dado do cliente — o GET e a cópia impõem o tipo

**Erro:** no PLAN-063 (TASK-063-002, KAN-249, 2026-10-18) a porta de object storage passava
`ContentType: 'application/pdf'` ao presign PUT acreditando que ele seria imposto. Um PUT com
`Content-Type: text/html` e corpo começando por `%PDF-` (que passa na validação por assinatura) foi
gravado como `text/html`, copiado assim para a chave definitiva e servido inline pelo GET assinado
(XSS armazenado, provado contra o MinIO).
**Causa:** no AWS SDK v3 o `S3RequestPresigner` marca `content-type` como não assinável (só
`content-length` entra via `signableHeaders`), e o `CopyObject` herda os metadados da origem por padrão.
**Solução:** todo GET assinado de objeto vindo de upload do browser fixa `ResponseContentType` pela
allowlist do domínio e `ResponseContentDisposition` `attachment` (com `filename*=UTF-8''…` quando há
nome), e a promoção `pending/` → chave final copia com `MetadataDirective: 'REPLACE'` e o
`ContentType` canônico. O teste de integração confere o tipo GRAVADO no destino por `HeadObject` (o
GET com `response-content-type` forçado mascara um REPLACE quebrado). Referência:
`mnemonicos-backend/src/modules/object-storage/s3-object-storage.ts` (`presignGet`, `copy`).
