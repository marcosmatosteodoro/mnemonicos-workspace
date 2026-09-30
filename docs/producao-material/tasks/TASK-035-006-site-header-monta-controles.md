# TASK-035-006: `SiteHeader` — monta os dois controles, verificação ponta-a-ponta

**Slug**: producao-material
**Pertence a**: PLAN-035
**Realiza (FRs)**: FR-034-005, FR-034-009
**Funcionalidade**: transversal (FEAT-034-001, FEAT-034-002)
**Componente**: COMP-035-007 (principal)
**Wave**: 3
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-035-003, TASK-035-004, TASK-035-005
- **Bloqueia**: nenhuma

## Contexto

`SiteHeader` hoje só mostra logo e, fora de produção, `ApiStatus` (`site-header.tsx:7-18`).
Esta TASK monta `AuthControl` e `ThemeToggle` ao lado dele, tornando os dois controles
novos visíveis em toda rota onde o header aparece (`SiteHeaderGate`, exceto `/login`) —
fecha a presença exigida por FR-034-005/009 e é o ponto de integração final do PLAN (memo —
PLAN-035 §3 COMP-035-007, §4).

## Escopo

### Inclui
- `mnemonicos-frontend/src/components/site-header.tsx`: monta `<AuthControl />` e
  `<ThemeToggle />` ao lado de `<ApiStatus />` (que continua dev-only,
  `process.env.NODE_ENV !== 'production'`, `site-header.tsx:14`, inalterado), dentro do
  `<div className="mx-auto flex w-full max-w-5xl items-center justify-between px-4 py-4
  sm:px-6">` que hoje só tem o `Link` e o `ApiStatus`. `SiteHeader` continua Server
  Component — os 2 filhos novos é que são `'use client'` (DEC-035-007 herdada).

### Não inclui
- Qualquer mudança em `ApiStatus`/`site-header-gate.tsx` — `/login` continua sem
  `SiteHeader` (A-034-003, `site-header-gate.tsx:12`, `HIDDEN_ROUTES`).

## Critérios de pronto

- [ ] Render de `SiteHeader` com sessão mockada e sem sessão mockada → ambos os controles
      presentes e visíveis; `ApiStatus` presente só quando `NODE_ENV !== 'production'`
      (comportamento já existente, não regredir) — cobre AC-034-005. Verificação
      executável: `npm --prefix mnemonicos-frontend test --
      src/components/site-header.test.tsx` → `PASS`, novo arquivo mockando
      `@/components/auth-control`/`@/components/theme-toggle` (ou `@/store/api`, a critério
      do developer) e afirmando presença de `AuthControl`/`ThemeToggle` no DOM nos dois
      cenários de sessão, mais o teste negativo já implícito de `ApiStatus` sob
      `NODE_ENV=production` (mesmo padrão de asserção condicional já usado no componente).
      Mutante: remover a montagem de um dos dois controles do JSX reprova a asserção de
      presença correspondente.
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff.

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente**: `http://localhost:3000` (ou a porta viva da sessão frontend; se ocupada,
ajuste `CORS_ORIGINS` do backend ANTES de trocar a porta — CLAUDE.md do workspace, seção
"Ambiente local — portas"). Realms `keelson.local.json`: `app` (público, `baseUrl`
`http://localhost:3000`, sem credencial) e `editor` (área interna, `loginPath: /login`,
credencial semeada por `seedDevEditor` a partir de `SEED_EDITOR_EMAIL`/
`SEED_EDITOR_PASSWORD` do `.env` do backend — preencher `keelson.local.json` local com os
MESMOS valores, nunca reproduzir o valor em texto).

**Sujeito concreto**: EDITOR de dev do realm `editor` para os passos internos; nenhuma
identidade para os passos públicos (realm `app`).

**Pré-condição com receita**: `localStorage` da origem `http://localhost:3000` limpo
(DevTools → Application → Local Storage → remover a chave de tema) antes do passo 1; o
passo 1 exige poder alternar a preferência de esquema de cores do SO/navegador (DevTools →
Rendering → "Emulate CSS media feature prefers-color-scheme", ou a preferência real do SO)
sem nenhuma escolha manual salva ainda. Restaurar `localStorage` limpo e a emulação de
`prefers-color-scheme` desligada ao final do roteiro (o tema escolhido durante os passos
não deve vazar para outra verificação).

1. (AC-034-008, AC-034-009, FR-034-007/008 — cascata CSS pura, não coberta em gate 1 por
   TASK-035-003, ver "Não inclui" daquela TASK) Com `localStorage` ainda limpo (nenhuma
   escolha manual): emular `prefers-color-scheme: dark` e carregar `/` (realm `app`, sem
   sessão) → confirmar tema escuro aplicado (AC-034-008); em seguida emular
   `prefers-color-scheme: light` (ou "no preference", se o navegador expuser) e recarregar
   `/` → confirmar tema claro aplicado (AC-034-009).
2. (AC-034-005, AC-034-007) Ainda em `/` (realm `app`, sem sessão) → confirmar "Entrar" e o
   alternador de tema visíveis no header.
3. (AC-034-001, AC-034-003) Clicar "Entrar" → navega para `/login`.
4. (AC-034-002, AC-034-004, AC-034-014) Logar com a credencial do realm `editor`, navegar para uma rota
   interna (ex. `(interno)/content`) → confirmar "Sair" único visível no header (sem
   duplicata do antigo botão da área interna), clicar → os 3 estados observados (em
   andamento/sucesso/falha simulada via rede lenta, se aplicável — falha real exigiria
   derrubar o backend, fora do escopo deste roteiro; registrar como observação se não
   exercitável), volta a `/login` no sucesso.
5. (AC-034-017) Antes de logar (ainda em `/`), escolher tema escuro pelo alternador; logar
   (passo 4); confirmar que o tema continua escuro na área interna após o login.
6. (AC-034-010, AC-034-011, AC-034-012) Alternar tema numa rota pública e numa rota interna; recarregar a
   página em cada uma; confirmar persistência e a paleta roxo/rosa/mauve (TASK-035-002)
   aplicada nos dois temas, sem a ilustração decorativa de `/login` (comparar com `/login`
   só para confirmar a AUSÊNCIA da ilustração fora dela).
7. (AC-034-019) Redimensionar a janela para 360px de largura com os controles presentes
   (incluindo `ApiStatus`, se em ambiente de dev) → confirmar ausência de rolagem
   horizontal.
8. (AC-034-013, AC-034-018) Inspecionar os rótulos acessíveis dos 2 controles nos 2 temas (leitor
   de acessibilidade ou painel de acessibilidade do DevTools); confirmar que uma mensagem
   de erro e um link, quando visíveis lado a lado com o acento roxo/rosa da paleta,
   permanecem distinguíveis entre si — se a inspeção encontrar problema, registrar como
   achado do gate 11 (design), não falha desta TASK per se (NFR-034-005 é MUST, mas a
   medição fina de contraste é do gate 11).

## Riscos específicos

- Nenhum específico desta TASK além dos já cobertos pelas TRISKs do PLAN — esta TASK é o
  ponto de integração, sem lógica nova própria.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**:

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
