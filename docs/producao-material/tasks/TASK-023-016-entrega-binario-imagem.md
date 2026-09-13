# TASK-023-016: Entrega do binário da imagem (`GET /visual-associations/:id/image`)

**Slug**: producao-material
**Pertence a**: PLAN-023
**Realiza (FRs)**: nenhuma
**Componente**: COMP-023-005 (parcial — `getVisualAssociationBinary`), COMP-023-006 (parcial — `GET /visual-associations/:id/image`)
**Wave**: 6
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch do EPICO MNEMORA STUDIO, Estrategia unica -- decisao 4.126: F5 e uma fatia do epico, nunca abre branch propria; a sessao ja fez o sync de largada nela)

**Padrão de commit**: Conventional Commits (`commit.convention: "conventional"`) — `feat:`.
**Framework de teste**: Jest 30 + ts-jest + `supertest` — `tests/integration/
visual-associations.routes.integration.test.ts` (Postgres real, `jest.integration.config.ts`,
`--runInBand`, arquivo já existente desde TASK-023-008 — esta TASK ESTENDE).

## Dependências

- **Depende de**: TASK-023-006, TASK-023-014
- **Bloqueia**: nenhuma

## Contexto

Última superfície de leitura do acervo: entrega do binário já armazenado como coluna
`imageData Bytes` (DEC-023-002, COMP-023-003/TASK-023-006) — rota autenticada com
`res.type(mimeType).send(imageData)`, nunca `express.static` (DEC-023-004): não há caminho de
arquivo em nenhum momento desta fatia, a superfície de path traversal não existe aqui.
`route-authz-matrix.integration.test.ts` cresce de 32 (após TASK-023-014) para 33 pares (a 1
chave nova montada nesta TASK — `GET /visual-associations/:id/image` — entra
automaticamente).

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/visual-associations/visual-associations.service.ts`
  (EMENDA): `getVisualAssociationBinary(id: string, db?): Promise<{ imageData: Buffer;
  mimeType: string } | null>` — leitura pura: `findUnique` selecionando só `imageData`/
  `mimeType`; devolve `null` se o `id` não existir (nenhuma checagem de autoria — a leitura/
  busca/vínculo do acervo é comum a todo EDITOR/ADMIN, FR-022-023).
- `mnemonicos-backend/src/modules/visual-associations/visual-associations.routes.ts`
  (EMENDA): `GET /visual-associations/:id/image` → `requireRole('GET',
  '/visual-associations/:id/image', 'EDITOR', 'ADMIN')` — SEM `verifyOrigin` (leitura pura,
  mesmo raciocínio de `GET /contents/:id/strip` em `tira.routes.ts`, NFR-022-005) — parseia
  `visualAssociationIdParamSchema` (já existente, TASK-023-003), chama
  `getVisualAssociationBinary`; `null` → 404; encontrado → `res.type(mimeType)
  .send(imageData)` (sem stream de arquivo, é um `Buffer` já em memória).
- `mnemonicos-backend/tests/integration/visual-associations.routes.integration.test.ts`
  (ESTENDE): ver Critérios de pronto.
- `route-authz-matrix.integration.test.ts`: nenhuma alteração de asserção fixa — a chave
  nova entra automaticamente, confirmando o crescimento de 32 para 33 pares
  (TRISK-023-006).

### Não inclui

- Qualquer restrição adicional por autoria da associação em si sobre esta rota — A-023-001
  [assumido] do PLAN é aplicado literalmente: a barreira é sessão EDITOR/ADMIN válida
  (NFR-022-003/005), NÃO uma restrição de alcance por autoria de FR-022-018 (essa cadeia é
  sobre Quadro↔RawContent, e uma associação órfã sem Quadro nenhum não tem cadeia alguma a
  alcançar, A-022-006).
- Cache/CDN/otimização de entrega (DEC-023-004, consequência aceita — 1 rota HTTP por
  imagem servida, sem cache de `express.static`).
- Consumo desta URL pelo frontend (`<img src=...>`) — já implementado por TASK-023-009/
  012/013.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. `getVisualAssociationBinary` é leitura pura — nenhuma guarda de autoria, nenhuma
   `$transaction` (não há escrita).
2. A rota segue o padrão plano já estabelecido (`requireRole` na montagem, sem
   `verifyOrigin` por ser `GET` de leitura pura — mesma régua de `GET /contents/:id/strip`).
3. `res.type(mimeType).send(imageData)` — nunca `res.sendFile`/`express.static` (DEC-023-004,
   já não há caminho de arquivo a servir).

## Critérios de pronto

- [ ] Testes cobrem AC-022-023 (cobre NFR-022-005): (a) requisição SEM sessão (`401`); (b)
      sessão STUDENT (`403`); (c) sessão EDITOR ou ADMIN válida, mas SEM alcance por FR-022-018
      sobre o Quadro que usa a imagem (ex.: associação vinculada só a Quadros de OUTRO
      EDITOR) → **200, o binário é entregue normalmente** — este é o teste que distingue a
      leitura CORRETA (A-023-001: barreira é sessão válida, não autoria da associação) do
      erro que a redação errada produziria (barrar por autoria); (d) `id` inexistente → 404.
      Fixture: associação criada por EDITOR A, vinculada a um Quadro de uma Tira TAMBÉM de
      autoria de EDITOR A; EDITOR B (sem nenhum vínculo com essa Tira) requisita o binário
      diretamente pelo `id` da associação → 200 (não é restringido pela cadeia de autoria do
      Quadro, porque a leitura do acervo é comum, FR-022-023).
- [ ] Contrato do próprio item (sem AC dedicado além de AC-022-023): `Content-Type` da
      resposta é exatamente o `mimeType` gravado na criação (`image/png`/`image/jpeg`/
      `image/webp` — nunca um valor fixo), e o corpo da resposta é BYTE-A-BYTE idêntico ao
      `imageData` gravado (comparação de buffer, não só de tamanho).
- [ ] `route-authz-matrix.integration.test.ts` continua verde com a chave nova montada
      (`GET /visual-associations/:id/image`) — nenhuma asserção fixa a alterar; confirma 401
      sem sessão / 403 papel insuficiente (STUDENT) na rota nova — AC-022-014 (parte),
      AC-022-023 (partes 401/403 acima, redundante de propósito com o item específico —
      a matriz genérica confirma o padrão comum, o item específico confirma o caso b/c com o
      fixture de alcance).
- [ ] Verificação executável (gate 1, todos os itens de teste acima): `npm --prefix
      mnemonicos-backend run test:integration --
      --testPathPatterns=visual-associations.routes.integration.test.ts` → `OK (N tests)`
      (estende o arquivo de TASK-023-008/010/014); `npm --prefix mnemonicos-backend run
      test:integration -- --testPathPatterns=route-authz-matrix.integration.test.ts` → `OK
      (N tests)`.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`), produção e teste — `npm --prefix mnemonicos-backend run lint` → exit 0.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil `node-22.md` — leitura pura sem
      `$transaction`, sem `express.static` (DEC-023-004).
- [ ] Code review aprovado.

## Riscos específicos

- Aplica diretamente A-023-001 [assumido] do PLAN (NFR-022-005 reafirma a MESMA barreira
  deny-by-default, NÃO uma restrição adicional por autoria) — o critério de pronto acima
  testa exatamente essa leitura: EDITOR sem alcance por FR-022-018 sobre o Quadro que usa a
  imagem AINDA lê o binário normalmente; STUDENT/anônimo é recusado. `Reabrir se`: o
  Diretor/PO confirmar que a leitura deveria, na prática, ficar restrita à mesma autoria de
  FR-022-018 (o que tornaria associações órfãs sem Quadro algum inacessíveis por imagem,
  contradizendo A-022-006) — decisão do PLAN, não desta TASK.
- Sem restrição adicional aqui: se o volume de leitura de imagens crescer, DEC-023-004 já
  nomeia CDN/token assinado como reabertura futura — fora de escopo.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-104
**Implementado por**: 
**Revisado por**: 
**Tentativas**: 
**Cobertura final**: 
**Arquivos modificados**:
  - 

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>

**Notas**: 
