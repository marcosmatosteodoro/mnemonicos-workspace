---
area: Código
estado: em-observacao
validade: indeterminada
confirmada: 0
contestada: 0
paths:
  - mnemonicos-backend/src/modules/**/*.service.ts
tags: [prazo, timeout, promise-race, escrita, idempotencia, compensacao]
---
## [Código] Prazo por `Promise.race` sobre fluxo que termina em escrita durável declara ponto de não-retorno

**Erro:** no PLAN-063 (TASK-063-003, KAN-250, 2026-10-18) a confirmação de envio corria contra um prazo
total. Se o temporizador vencia durante o `db.libraryPdf.create`, a resposta era 504 "use Enviar PDF
novamente", mas o registro ficava gravado e a chave definitiva no storage — reenviar duplicava.
**Causa:** o race rejeita assim que o temporizador vence, mas o job continua em segundo plano; as
checagens de prazo cobriam só os pontos ANTES da escrita, não a escrita em voo.
**Solução:** todo teto por `Promise.race`/`withDeadline` sobre um fluxo com escrita durável declara um
ponto de não-retorno — desarma o temporizador (`commit()`) logo antes da escrita, sem `await` entre a
última checagem e o commit, ou compensa depois da escrita se o prazo venceu. A prova é um dublê de
escrita que resolve após o prazo e exige o par coerente: sucesso gravado, ou erro sem gravação. Em
serverless, a limpeza do caminho de erro é aguardada antes da resposta (a função pode congelar depois).
Referência: `mnemonicos-backend/src/modules/pdf-library/pdf-library.service.ts` (`runWithDeadline`).
