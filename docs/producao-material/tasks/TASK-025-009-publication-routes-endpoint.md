# TASK-025-009: Expor `POST /contents/:id/publication` — superfície HTTP da exportação

**Slug**: producao-material
**Pertence a**: PLAN-025
**Realiza (FRs)**: FR-024-007, FR-024-008, FR-024-009, FR-024-011
**Componente**: COMP-025-006 (principal)
**Wave**: 4
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: TASK-025-008, TASK-025-006
- **Bloqueia**: TASK-025-010

## Contexto

`publication.routes.ts` é o único ponto de entrada HTTP de `exportPublication`
(`publication.service.ts`, TASK-025-008): recebe o pedido, valida com os schemas de
TASK-025-006 e transporta o `Buffer`/erro de volta ao cliente. Cobertura parcial: FR-024-007
aqui é só a base HTTP sobre a qual o frontend constrói os 3 estados observáveis (completo em
TASK-025-010/011); FR-024-009 aqui é a propagação do erro pelo canal HTTP — a garantia de
falha segura em si (nenhum `Buffer` parcial montado) é de COMP-025-003/COMP-025-005.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/publication/publication.routes.ts`: `POST
  /contents/:id/publication`, montada em `apiRoutes` — EMENDA em
  `mnemonicos-backend/src/http/routes.ts:37-52` (import da rota + `apiRoutes.use(...)`, mesmo
  padrão de linha de `tiraRoutes`/`visualAssociationsRoutes`).
- Cadeia de handlers, na ordem: `verifyOrigin` (1º — DEC-025-004, a rota tem efeito
  colateral real) → `requireRole('POST', '/contents/:id/publication', 'EDITOR', 'ADMIN')`.
- `:id` validado por `exportPublicationParamsSchema`, corpo por
  `exportPublicationBodySchema` (TASK-025-006).
- Sucesso: `res.type('application/pdf').set('Content-Disposition', \`attachment;
  filename="${filename}"\`).send(buffer)` — `attachment`, nunca `inline` (distingue de
  `visual-associations.routes.ts:153`, que serve imagem para exibição embutida).
- Sem `try/catch` — Express 5 encaminha a rejeição ao `errorHandler`
  (`NotFoundError`/`ConflictError`/`GenerationTimeoutError` do service viram 404/409/503
  automaticamente).
- EMENDA `mnemonicos-backend/tests/integration/route-authz-matrix.integration.test.ts:154-192`
  — soma `POST /contents/:id/publication` ao array de 33 pares (→ 34) e à contagem do
  tripwire (TRISK-025-008).

### Não inclui

- Lógica de orquestração (`exportPublication` em si — TASK-025-008).
- Os schemas Zod (TASK-025-006).
- A camada de consumo do frontend (TASK-025-010).

## Critérios de pronto

- [ ] **Testes cobrem AC-024-007** (nome do arquivo indica rascunho + Variante) — verificação
      executável: novo `mnemonicos-backend/tests/integration/publication.routes.integration.test.ts`,
      comando `npm --prefix mnemonicos-backend run test:integration -- publication.routes` →
      `PASS`. Cenário: EDITOR com Conteúdo bruto + Quebra da regra salvos, `POST
      /api/v1/contents/:id/publication` com `{ variant: 'RESUMO' }` → header
      `Content-Disposition` casa `attachment; filename="<id>-resumo-rascunho.pdf"`; o mesmo
      Conteúdo bruto com `{ variant: 'TIRA' }` → `attachment;
      filename="<id>-tira-rascunho.pdf"` — 2 casos nomeados, um por Variante.
- [ ] **Testes cobrem AC-024-009** (STUDENT ou sem sessão recusados) — mesmo arquivo/comando
      acima → `PASS`. Cenário: `POST /api/v1/contents/:id/publication` sem cookie de sessão →
      401; a mesma chamada com sessão de papel `STUDENT` → 403 — 2 casos nomeados.
- [ ] `route-authz-matrix.integration.test.ts` passa com **34/34 pares** (contagem
      confirmada, não presumida) — verificação executável: `npm --prefix mnemonicos-backend
      run test:integration -- route-authz-matrix` → `PASS`, incluindo o teste-tripwire do
      censo de rotas (`describe('fonte de medição da métrica §1.3...')`) com o array atualizado
      e o bloco `EMENDA DEC-003-004` (posição de `verifyOrigin`) cobrindo a rota nova sem
      exclusão adicional — a suíte itera `ROUTES` (derivado de `apiRoutes.stack`, nunca lista
      hardcoded), então a rota nova entra automaticamente nos blocos estruturais existentes;
      nenhum filtro do arquivo precisa mudar para alcançá-la (lição ativa "[Segurança]
      Asserção estrutural repo-wide de `verifyOrigin` já se baseia em `ROUTES`").
- [ ] `PUBLIC_PATH_ALLOWLIST` permanece com os mesmos 4 pares (`GET /health`, `GET
      /health/db`, `POST /auth/login`, `POST /auth/refresh`) — a rota nova não entra na
      allowlist (lição ativa "[Segurança] `POST /contents/:id/publication` não entra em
      `PUBLIC_PATH_ALLOWLIST`"); verificado pelo mesmo teste-tripwire de
      `PUBLIC_PATH_ALLOWLIST` já existente (`[...PUBLIC_PATH_ALLOWLIST].sort()`), sem
      alteração no arquivo `public-paths.ts`.
- [ ] `assertDenyByDefault(apiRoutes)` continua aceitando a árvore real montada com a rota
      nova (mesmo teste já existente, `'o passo de boot assertDenyByDefault aceita a árvore
      real montada'`) — verificação executável: mesmo comando `test:integration --
      route-authz-matrix` acima → `PASS`.
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git diff --name-only
      main...HEAD`) — verificação executável: `npm --prefix mnemonicos-backend run lint` → 0
      problemas.

## Riscos específicos

- TRISK-025-008 (PLAN §8): `route-authz-matrix.integration.test.ts` (hoje 33 pares) precisa
  crescer para a rota nova — mitigado pelo item de Inclui/Critério acima; se ficar de fora,
  nada acusa isso no boot, só a suíte.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-14T19:42:30-0300
**Data conclusão**: 2026-09-14T20:23:54-0300
**Commit SHA**: 288fa02 (implementação) · 246d27d (retry — gate 1: enumeração de rota na topologia de authz) · 2f45711 (carona Art. 7)
**Jira**: KAN-116

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (Wave 4 — 1 retry, achado bloqueante fechado, re-review APROVADO)
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 4)
- [x] Comportamento (gate 9): consolidado (DoD, Etapa 4) — SPEC-024 sem FEATs
<!-- Branch, tentativas, arquivos, revisores e narrativa (retries, escalações) vivem no
ledger da sessão e no commit da closure (4.76) — não se repetem aqui (4.409). -->
