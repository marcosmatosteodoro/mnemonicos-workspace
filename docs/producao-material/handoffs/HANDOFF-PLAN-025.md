---
id: HANDOFF-PLAN-025
slug: producao-material
branch: feat/producao-material-mnemora-studio
status: Concluído
criado: 2026-09-15T02:15:00+0000
origem: PLAN-025
commits: [09b9fbf, 554e929, db1a3e4, a66e7da, 87b4f70, 453d84f, 9a70284, 242899e, a55a2c9, e4c47c8, e2745c4, 913cc49, 3115fec]
motivo: schema_desatualizado (migração `20260914175940_add_publicacao_pdf_publication_event` não aplicada no Postgres de dev — autorização é ato do Diretor) + app_fora_do_ar (pool de compilação do Turbopack do frontend quebrado desde o boot desta sessão; fix de config já commitado em `3115fec`, mas o processo em execução precisa ser reiniciado para pegá-lo)
sonda: >-
  qa (Etapa 4/DoD, consolidação final de gate 9): login EDITOR real funcionou
  (POST /login → /studio). Criou RawContent real
  (01a0a2ce-8ec0-77a9-9221-f09a5c38bf5f, sem Quebra) e localizou outro já
  existente com Quebra da regra registrada
  (01a0a271-2f18-7499-b4ef-5cdb699de1e8). Ao navegar para /content/:id
  (content-form) e /content/:id/tira (mnemonic-strip-board), ambas as rotas
  devolveram 500 ("Jest worker encountered 2 child process exceptions,
  exceeding retry limit"). Testou também /content/:id/breakdown (rota NÃO
  tocada por nenhuma TASK desta fatia) — mesmo 500: confirma que o defeito é
  do AMBIENTE (pool de compilação do Turbopack morto), não do diff. Causa raiz
  no log do servidor: Turbopack resolvia `next/package.json` a partir da raiz
  do workspace-mãe (que tem seu próprio `package-lock.json`) em vez da raiz de
  `mnemonicos-frontend`, por falta de `turbopack.root` — corrigido no commit
  `3115fec` (`next build` limpo confirma o fix, todas as rotas compilando),
  mas o PROCESSO já em execução continua com o pool quebrado até reiniciar.
  qa tentou reiniciar (matar o processo travado) e foi bloqueado pelo
  classificador de permissão da sessão ("Interfere With Workloads") — não
  insistiu. Migração confirmada ainda pendente via `npx prisma migrate status`
  (read-only, não aplicada).
achado_verificado_ambiente_real: >-
  Identidade/estabilidade confirmadas: backend HEAD 2f45711c622f, frontend
  HEAD a55a2c99ae94 (mesma branch), git status idêntico na abertura e no
  fecho do exercício nos dois repos. Processos de pé nas portas 3000/3333
  apontando para este worktree. Login real como EDITOR funcionou e navegou
  para `/studio` — o ambiente é real, só as 2 rotas ainda não compiladas
  quebravam.
---

# Handoff de verificação de tela — Pipeline de publicação de PDF (F6)

## 1. Contexto da entrega

PLAN-025 entrega o módulo `publication` (backend: `pdf-lib`, 2 Variantes
tira/resumo, supressão de evento de abertura na auto-geração de Tira, teto de
duração, evento `PUBLICACAO_PDF`; frontend: mutation `exportPublication` com
`responseHandler` binário, componente `PublicationExportControl` enxertado em
`content-form.tsx` e `mnemonic-strip-board.tsx`). Todas as 13 TASKs estão
`Done`, com gates 1-7/8/11 aprovados em cada uma. Este handoff cobre
especificamente o **gate 9 (comportamento verificado, `screenVerify.enabled:
true`)**, que ficou `pendente_handoff` em TASK-025-011/012/013 por 2 bloqueios
de AMBIENTE (não de código) — nenhum dos dois é um defeito do diff desta
fatia.

## 2. Já verificado (não repetir)

- **Testes**: backend 353/353 (unit) + 395/395 (integration, migração já
  aplicada em `mnemonicos_test` — "No pending migrations to apply"),
  frontend 444/444. Lint e typecheck limpos nos dois repos (exceto a worktree
  órfã não relacionada `.claude/worktrees/kan-49-vercel-entrypoint`, pendência
  antiga já registrada, fora de escopo).
- **Gates 1-7 (code-review)**: aprovado em todas as 13 TASKs; 2 retries reais
  na Wave 2 (defesa de decompression bomb PNG, convergência em 3 rodadas) e 2
  retries na Wave 7 (TASK-025-013 — posicionamento/estado vazio/mutualidade
  hasData-isNotFound, depois narrativa de rodada nos testes).
- **Gate 8 (segurança)**: aprovado nas Waves 2 (PNG hardening) e 4 (barreira
  de autorização real da rota); n/a nas TASKs de frontend puro (sem
  superfície sensível nova).
- **Gate 11 (design)**: aprovado em Wave 6 (3 estados observáveis,
  `role="status"`/`role="alert"`) e Wave 7 (posicionamento dos 2 enxertos,
  gating por Tira vazia).
- **Ambiente confirmado REAL** nesta própria rodada de gate 9 — ver
  `achado_verificado_ambiente_real` acima. O bloqueio não é "não consigo
  chegar ao app", é "2 rotas específicas não compilavam nesta sessão de dev".
- **`turbopack.root` já corrigido** (commit `3115fec`) — `next build` limpo
  confirma; só falta reiniciar o PROCESSO de dev em execução.

## 3. Pré-requisitos de ambiente

- **Autorizar e aplicar a migração de dev** (ato do Diretor, nunca automático):
  `npx prisma migrate dev` (ou `migrate deploy`) em `mnemonicos-backend`, para
  a migração `20260914175940_add_publicacao_pdf_publication_event`. Sem isso,
  `POST /contents/:id/publication` devolve 500 nas 2 Variantes — esperado,
  não é um achado novo.
- **Reiniciar o servidor de dev do frontend**: encerrar o processo Next atual
  (travado com o pool de compilação morto — PID pode ter mudado desde a
  sondagem) e rodar `npm run dev` limpo em `mnemonicos-frontend`, agora com
  `turbopack.root` fixado (`3115fec`). Confirmar que `/content/:id/breakdown`
  responde 200 antes de prosseguir (controle de sanidade — rota não tocada
  por esta fatia, serve para provar que o pool de compilação está saudável).
- **Credenciais de tela**: `keelson.local.json` › realm `editor` (formato
  `username`/`password` soltos, não aninhado sob `login` — ver nota de tooling
  abaixo).
- **Fixtures reais já existentes**, prontos para reuso (não recriar):
  - RawContent SEM Quebra da regra: `01a0a2ce-8ec0-77a9-9221-f09a5c38bf5f`
  - RawContent COM Quebra da regra (Wave 6): `01a0a271-2f18-7499-b4ef-5cdb699de1e8`

## 4. Roteiro de verificação (itens pendentes)

### V1 — Exportação nas 2 Variantes, tela do Conteúdo bruto (AC-024-014 parte content-form, FR-024-007/008/012)
- **Tela/rota**: `http://localhost:3000/content/01a0a271-2f18-7499-b4ef-5cdb699de1e8`
- **Realm**: `editor`
- **Pré-condição**: migração aplicada; servidor de dev reiniciado.
- **Passos**:
  1. Confirmar os 2 controles ("Exportar Tira mnemônica" / "Exportar Resumo")
     visíveis no formulário, depois do link "Ir para a Quebra da regra".
  2. Clicar em cada um; observar "Gerando…" (`role="status"`), depois sucesso
     (`role="status"`, download real) ou falha (`role="alert"`).
- **Esperado**: download real de PDF nas 2 Variantes, nome de arquivo
  coerente (`Content-Disposition`), sem regressão de estado (a Variante que
  falhar, se falhar, continua identificável).
- **Risco se falhar**: FR-024-007/008/012 é o comportamento central da fatia.
- **Evidência**: ✅ Exercitado em `01a0a271-2f18-7499-b4ef-5cdb699de1e8`
  (RawContent COM Quebra) logado como `editor@mnemonicos.local` via
  `keelson.local.json`. Os 2 controles apareceram depois do link "Ir para a
  Quebra da regra", como esperado. "Exportar Tira mnemônica":
  `POST /contents/:id/publication {"variant":"TIRA"}` → `200`,
  `content-type: application/pdf`,
  `content-disposition: attachment; filename="01a0a271-...-tira-rascunho.pdf"`,
  `content-length: 2702`; download real confirmado (`%PDF-1.7`, 2702 bytes) e
  `role="status"`: "Tira mnemônica exportada." "Exportar Resumo":
  `POST .../publication {"variant":"RESUMO"}` → `200`,
  `content-disposition: ...-resumo-rascunho.pdf`, `content-length: 1360`,
  download real (`%PDF-1.7`, 1360 bytes), `role="status"`: "Resumo exportado."
  Os 2 status ficaram visíveis simultaneamente, cada um sob seu próprio
  controle — sem regressão de estado entre as Variantes. **V1: VERIFICADO.**

### V2 — Gating por Tira vazia/não-vazia + exportação na tela da Tira (AC-024-014 parte mnemonic-strip-board, FR-024-013)
- **Tela/rota**: `http://localhost:3000/content/01a0a271-2f18-7499-b4ef-5cdb699de1e8/tira`
- **Realm**: `editor`
- **Passos**:
  1. Com a Tira ainda vazia (usar o RawContent sem Quebra primeiro, ou um
     RawContent com Quebra mas Tira recém-aberta sem Quadros), confirmar que
     NENHUM controle de exportação aparece.
  2. Adicionar 1 Quadro; confirmar que os 2 controles passam a aparecer no
     fim da tela (depois do formulário de novo Quadro).
  3. Exportar "Tira mnemônica"; confirmar download real (não um PDF de 0
     páginas).
  4. Numa 1ª visita humana a uma Tira já aberta (auto-gerada por uma
     exportação anterior, evento de ABERTURA suprimido), confirmar via
     network/log do backend que `POST /contents/:id/strip` dispara
     EXATAMENTE 1 vez.
- **Esperado**: gating correto (vazio → ausente; ≥1 Quadro → presente),
  download real, 1 único POST de confirmação de abertura.
- **Risco se falhar**: FR-024-013/AC-011-024 e o achado de PDF vazio
  (já corrigido em `242899e`) reabririam se regredirem.
- **Evidência**: ✅ Os fixtures documentados já não cobriam mais o estado
  "Tira vazia" (a Tira de `01a0a271-...` já tinha 5 Quadros de rodadas
  anteriores da sessão) — criados 2 RawContents novos com Quebra da regra
  para cobrir os 2 sub-casos do roteiro:
  - `01a0a71b-bccf-71ce-baa9-3ebf17862546`: a auto-geração da Tira (1ª
    abertura) já populou 3 Quadros a partir de Conceito/Ação/Objeto da
    Quebra — os 3 foram removidos manualmente (com confirmação) até 0
    Quadros. Com 0 Quadros: nenhum controle de exportação presente
    (mensagem de estado vazio "Adicione o primeiro quadro..."). Adicionado 1
    Quadro: os 2 controles reapareceram no fim da tela, depois do formulário
    de novo Quadro — gating confirmado nos 2 sentidos. "Exportar Tira
    mnemônica" com 1 Quadro: download real, não-vazio (`%PDF-1.7`,
    1069 bytes) — não é PDF de 0 páginas.
  - `01a0a71d-d73e-74fa-acfc-729fba4b7a36`: Quebra da regra registrada e a
    Tira **nunca aberta no browser**; a Tira foi auto-gerada por uma chamada
    direta a `POST /contents/:id/publication` (curl autenticado como
    `editor`, fora do fluxo do frontend) — confirmado via
    `GET .../strip` (404 antes, 200 com 3 frames depois). Só então a tela
    `/tira` foi aberta pela 1ª vez no browser (network:
    `GET .../strip → 200`, `POST .../strip → 200`, `GET .../strip → 200`) e
    recarregada uma 2ª vez (hard reload, `location.reload()` — mesmo padrão
    de 3 chamadas, incluindo um novo `POST .../strip → 200`). Consulta
    read-only em `production_stage_events` (via Prisma Client do próprio
    backend, `stageType='TIRA_MNEMONICA'`) confirma **exatamente 1** evento
    `ABERTURA` para este `rawContentId` apesar da auto-geração fora do fluxo
    da UI e das 2 aberturas subsequentes no browser — o `POST /strip` da UI
    é idempotente (get-or-generate) e a emissão do evento é guardada pelo
    histórico, não pela contagem de chamadas HTTP. **V2: VERIFICADO**
    (gating vazio/não-vazio, download real e exatamente 1 evento de
    abertura confirmados).

### V3 — Falha controlada sem Quebra da regra (DEC-025-007)
- **Tela/rota**: `http://localhost:3000/content/01a0a2ce-8ec0-77a9-9221-f09a5c38bf5f`
- **Realm**: `editor`
- **Passos**: clicar "Exportar Resumo" (ou "Exportar Tira mnemônica") num
  RawContent sem Quebra da regra salva.
- **Esperado**: falha visível (`role="alert"`) — o backend recusa com 404
  (`NotFoundError`, `assertRawContentExportable`/leitura da Quebra), nunca
  500 cru nem sucesso parcial.
- **Risco se falhar**: FR-024-009 (nunca entregar PDF parcial) e a barreira
  de pré-requisito (achado do product-designer, TASK-025-012).
- **Evidência**: ✅ Exercitado em `01a0a2ce-8ec0-77a9-9221-f09a5c38bf5f`
  (RawContent SEM Quebra da regra, confirmado na tela — só "Registrar Quebra
  da regra", sem "Tem Quebra da regra"). "Exportar Resumo":
  `POST .../publication` → `404`, corpo
  `{"error":{"code":"NOT_FOUND","message":"Quebra da regra não
  encontrada."}}` — nunca 500 cru, sem download, `role="alert"`: 'Não foi
  possível exportar a variante "Resumo" agora. Tente novamente.' Repetido
  com "Exportar Tira mnemônica" na mesma tela: mesmo 404/NOT_FOUND, mesmo
  padrão de alerta próprio ("Não foi possível exportar a variante "Tira
  mnemônica" agora."), sem regressão do alerta da Variante anterior (os 2
  ficaram visíveis, cada um sob seu controle). **V3: VERIFICADO.**

## 5. Riscos e pontos de atenção

- **Migração de dev** — nenhuma verificação de V1-V3 é possível sem ela
  aplicada; não é um achado, é a pré-condição inteira deste handoff.
- **`turbopack.root`** (RISK-025-005, a registrar em INDEX) — o fix é
  config-only e já commitado, mas só se aplica a um processo NOVO; qualquer
  sessão futura que reaproveitar um processo de dev já quebrado por este
  motivo (antes do fix existir) tem o mesmo sintoma até reiniciar.
- **Nota de tooling, não-bloqueante**: `probe-env.sh --realm editor` deu
  falso-negativo (`credencial_placeholder`) porque o script espera
  `screenVerify.realms.<nome>.login.{username,password}` aninhado, mas
  `keelson.local.json` deste projeto usa `username`/`password` soltos direto
  no realm (mesmo formato do `.example.json` versionado) — possível
  descompasso de schema entre a versão do script (0.173.0) e a convenção
  deste projeto; não classificado como `licao_candidata` formal, sinalizado
  para avaliação do Diretor/agile-coach se recorrer.
- **RISK-025-004** (já em INDEX): feedback de exportação em voo se perde se o
  componente desmontar (3 gatilhos) — débito aceito, fora de escopo, não
  bloqueia este handoff.
- **Achado não-bloqueante (sugestão, gate 11)**: cada exportação bem-sucedida
  dispara no console de dev (RTK Query) o aviso "A non-serializable value was
  detected... payload.blob" / "...api.mutations.<id>.data.blob" — o
  `responseHandler` binário guarda o `Blob` no cache RTK Query, e o
  middleware de serializability do Redux (dev-only, não afeta produção nem o
  comportamento observado) sinaliza isso. Não bloqueou nenhum download nem
  gerou erro visível ao usuário nos 4 exercícios (V1 x2, V2 x1); registrado
  aqui como sinal ao `product-designer`/`developer` para uma futura
  configuração de `serializableCheck.ignoredPaths` no store, se incomodar.
- **3 fixtures novos criados nesta rodada** (os documentados na Seção 3 não
  cobriam mais "Tira vazia" — ver Evidência de V2): RawContents
  `01a0a71b-bccf-71ce-baa9-3ebf17862546` (Quebra da regra salva, Tira com 1
  Quadro ao final do exercício), `01a0a71d-d73e-74fa-acfc-729fba4b7a36`
  (Quebra da regra salva, Tira com 3 Quadros auto-gerados, 1 evento ABERTURA
  confirmado). Dados de teste reais no Postgres de dev, não precisam de
  limpeza para este handoff, mas ficam disponíveis para reuso/descarte por
  sessões futuras.
- **Identidade/estabilidade reconfirmadas no fecho do exercício**: backend
  HEAD `6a5af2b43509414a1f5f4f33df2d27bdbc1463e7`, frontend HEAD
  `5c406abd15fc0c92e4760cf55ed3a26afe65d334` (ambos avançaram da sondagem
  original — `2f45711c622f`/`a55a2c99ae94` — com commits adicionais da mesma
  fatia, incluindo o próprio `3115fec` do fix de `turbopack.root`); `git
  status --porcelain` idêntico na abertura e no fecho nos dois repos (só
  ruído de normalização de fim de linha CRLF/LF pré-existente em 5 arquivos
  do backend e 1 do frontend, sem diff de conteúdo — `git diff --stat`
  vazio; fora do escopo tocado por esta fatia) — nenhuma mudança concorrente
  durante o exercício.

## 6. Protocolo de conclusão

1. Diretor autoriza e aplica a migração + reinicia o servidor de dev do
   frontend.
2. Exercitar V1–V3 e preencher a **Evidência** (✅/❌ + o que foi observado).
3. Divergência → corrigir na branch `feat/producao-material-mnemora-studio`
   (protocolo inline: escopo restrito + testes + gates) e re-exercitar o
   item.
4. Tudo ✅ → `status: Concluído` no front-matter; atualizar
   `docs/producao-material/INDEX.md` (remover o risco ativo de migração
   pendente + linha no Histórico recente); commit
   `chore(producao-material): close verification handoff HANDOFF-PLAN-025`.
5. Merge e deploy continuam decisão humana (do Diretor).
