# TASK-036-001: `meSilent` — checagem de sessão sem efeito colateral

**Slug**: producao-material
**Pertence a**: PLAN-036
**Realiza (FRs)**: FR-036-015
**Funcionalidade**: FEAT-036-001 (primária)
**Componente**: COMP-036-004 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-036-005

## Contexto

O header precisa saber se há sessão ativa sem herdar o efeito colateral de
`baseQueryWithReauth` (renovação + `resetApiState`/redirect `/login?sessao=expirada` em
qualquer 401 fora de login/refresh/janela de logout — `store/api.ts:368-427`). `meSilent`
lê `/auth/me` direto por `rawBaseQuery` (`api.ts:308-312`), sempre resolvendo `{ data }`,
nunca side-effect (DEC-036-005; memo — PLAN-036 §1 e §6/DEC-036-005).

## Escopo

### Inclui
- Novo endpoint `meSilent: build.query<SessionUser | null, void>({ queryFn: ... })` em
  `mnemonicos-frontend/src/store/api.ts`, ao lado do endpoint `me` existente
  (`api.ts:727-730`): o `queryFn` chama `rawBaseQuery('/auth/me', bqApi, extraOptions)`
  diretamente (a mesma instância declarada em `api.ts:308-312`), nunca
  `baseQueryWithReauth`. Mapeamento do resultado: `result.error?.status === 401` →
  `{ data: null }`; sem erro → `{ data: result.data as SessionUser }`; qualquer outro erro
  (rede, timeout, 5xx) → também `{ data: null }` — nunca `{ error }`, nunca dispatch nem
  chamada a `reauth.redirect`.
- Hook `useMeSilentQuery` (gerado automaticamente pelo RTK Query a partir do nome do
  endpoint — nenhum código adicional além de declará-lo).
- Sem `providesTags`/`invalidatesTags` que acoplem `meSilent` ao ciclo de cache de
  `me`/`SessionUser` — os dois caminhos de leitura de sessão permanecem desacoplados
  (DEC-036-005, consequências).

### Não inclui
- `useMeQuery`/endpoint `me` (`api.ts:727-730`) — intocado.
- `InternalShell`, que continua usando `useMeQuery` exatamente como hoje
  (`internal-shell.tsx:37`).
- Qualquer mudança de contrato do backend — `GET /auth/me` já existe e não muda
  (SPEC-002).

## Critérios de pronto

- [ ] 401 em `GET /auth/me` → `meSilent` resolve `{ data: null }`, **sem** disparar
      `POST /auth/refresh` e **sem** chamar `reauth.redirect` — cobre AC-036-015 e a
      proibição de efeito colateral de FR-036-015. Verificação executável:
      `npm --prefix mnemonicos-frontend test -- src/store/api.test.ts -t "meSilent"` →
      `PASS`, com um caso novo no mesmo arquivo (reaproveitando o harness já declarado ali —
      `route`/`fetchSpy`/`newStore()`/`track()`, `api.test.ts:24-105`) que arma `route` para
      `GET /api/v1/auth/me` devolver `401`, despacha
      `store.dispatch(api.endpoints.meSilent.initiate())` e afirma `result.data === null`,
      `countCalls('POST', '/api/v1/auth/refresh') === 0` e `reauth.redirect` não chamado.
      Mutante: reverter o `queryFn` para delegar a `baseQueryWithReauth` faz
      `countCalls('POST', '/api/v1/auth/refresh')` sair de `0` — reprova.
- [ ] 200 em `GET /auth/me` → `meSilent` resolve `{ data: <SessionUser> }` com o mesmo
      formato que `me` resolveria hoje — mesmo teste, caso com o corpo já usado no teste
      existente de `me` (`{ id: '1', name: 'Ana', email: 'ana@example.com', role: 'EDITOR' }`,
      `api.test.ts:1035`), afirmando `result.data` igual a esse objeto.
- [ ] Erro de rede/5xx em `GET /auth/me` → `meSilent` resolve `{ data: null }`, mesma
      ausência de efeito colateral do caso 401 — caso com `route` devolvendo `{ status: 500
      }`, mesmas duas asserções de zero `/auth/refresh` e zero `reauth.redirect`.
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git diff --name-only
      main...HEAD`, produção e teste).

## Riscos específicos

- TRISK-036-003 (divergência futura entre `me`/`meSilent` se o contrato de `/auth/me`
  mudar) é só documentado aqui (comentário cruzado nos dois endpoints, DEC-036-005) — não
  há mitigação de código adicional nesta TASK.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-30T00:05:05-0300
**Data conclusão**: 2026-09-30T01:19:41-0300
**Commit SHA**: ca5d00d
**Jira**: KAN-159

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (69/69)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (wave 1)
- [x] ACs verificados (AC-036-015)
- [x] Segurança (gate 8): aprovado (wave 1) — security-engineer
- [ ] Comportamento (gate 9): n/a — FEAT-036-001 ainda não completou (aguarda TASK-036-005)
