# TASK-031-004: Montar o card em duas metades sobre o fundo (LoginCardFrame / page.tsx)

**Slug**: producao-material
**Pertence a**: PLAN-031
**Realiza (FRs)**: FR-030-001 (parte — montagem do card), FR-030-008, FR-030-009, FR-030-010, FR-030-013, FR-030-014
**Componente**: COMP-031-004 (principal), COMP-031-001, COMP-031-002, COMP-031-003, COMP-031-005
**Wave**: 4
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-031-001, TASK-031-002, TASK-031-003, TASK-031-005
- **Bloqueia**: nenhuma

## Contexto

Reestrutura `page.tsx` (`mnemonicos-frontend/src/app/login/page.tsx:16-41`, memo de
exploração) para montar o fundo, o card em duas metades e o formulário num único
comportamento observável de `/login`, preservando o aviso de sessão expirada e o guard de
`next`, responsivo nos três breakpoints exigidos, sem mover de caminho (DEC-031-001) — os
dois testes que importam `page.tsx` via `@/app/login/page` continuam válidos sem ajuste de
import.

## Escopo

### Inclui
- Reestruturação de `mnemonicos-frontend/src/app/login/page.tsx`: monta
  `LoginNightBackdrop` (COMP-031-002) e o card central com `LoginIllustratedPanel`
  (COMP-031-003) na metade superior e o painel de formulário (título curto e de destaque
  alinhado à esquerda + aviso de sessão expirada condicional `role="status"` +
  `LoginForm`/COMP-031-005) na metade inferior; sombra/efeito de flutuação do card.
- Responsividade sem rolagem horizontal em 360/768/1280px; em 360px, painel ilustrado em
  faixa baixa e formulário acima da dobra.
- Preservação do guard de open-redirect via `isSafeRelativePath` (`@/proxy`) sobre o
  parâmetro `next`, no mesmo arquivo e mesmo caminho.
- Grep consolidado de ausência de cor literal (hex/rgb/hsl) em todos os arquivos de
  `/login` produzidos pelas TASKs 001–006.
- Medição do bundle de `/login` via `next build` (entrada para o gate 10/TRISK-031-002).

### Não inclui
- Qualquer alteração de comportamento/lógica de `LoginForm`, `PasswordField` ou da própria
  lógica de autenticação (SPEC-002/SPEC-016) — só composição/estilo.
- Mudança de caminho de `page.tsx` ou criação de route group (DEC-031-001 — descartado).
- Verificação de login real, responsividade real e `prefers-reduced-motion` real — Roteiro
  do gate 9 abaixo, nesta mesma TASK.

## Critérios de pronto

- [ ] `page.tsx` monta `LoginNightBackdrop` + card (`LoginIllustratedPanel` + painel de
      formulário com `LoginForm`) preservando o aviso de sessão expirada (`role="status"`)
      e o guard `isSafeRelativePath` sobre `next`, sem mover de caminho — Testes cobrem
      AC-030-011 (parte — `page.test.tsx`, `page.next-param.test.ts`): verificação
      executável: `npm --prefix mnemonicos-frontend test -- src/app/login/page` → OK (N
      tests), mesma contagem de asserções do commit-pai (baseline capturada antes do
      diff). Suíte roda sob `testEnvironment` customizado
      (`<rootDir>/test/jsdom-fetch-env.js`), nunca `jest.mock('@/proxy', ...)` — lição
      ativa
      `jsdom-sem-request-response-fetch-por-import-transitivo-de-next-server-testenvironment-can-nico-nunca-mock-do-m-dulo-sob-guarda`:
      `page.tsx` importa `@/proxy`, que importa `next/server` transitivamente; mockar o
      guard de open-redirect como sempre-permissivo reprova o gate mesmo com o resto do
      diff correto.
- [ ] Painel de formulário abre com título curto e de destaque, alinhado à esquerda —
      Testes cobrem AC-030-013: mesmo comando acima, asserção de heading/texto e de classe
      de alinhamento à esquerda.
- [ ] Nenhuma cor literal (hex/rgb/hsl) em nenhum arquivo de `/login` (page.tsx +
      `login-night-backdrop.tsx`, `login-illustrated-panel.tsx`, `login-form.tsx`,
      `password-field.tsx`) — Testes cobrem AC-030-014: verificação executável:
      `grep -rEn "#[0-9a-fA-F]{3,8}|rgb\(|rgba\(|hsl\(" mnemonicos-frontend/src/app/login/page.tsx mnemonicos-frontend/src/components/login-night-backdrop.tsx mnemonicos-frontend/src/components/login-illustrated-panel.tsx mnemonicos-frontend/src/components/login-form.tsx mnemonicos-frontend/src/components/password-field.tsx | grep -vE '^[^:]+:[0-9]+:\s*(//|/\*|\*)'`
      → saída vazia (nenhuma ocorrência fora de comentário/docblock).
- [ ] `next build` do frontend conclui com sucesso e reporta o First Load JS da rota
      `/login` (entrada para a medição de TRISK-031-002 pelo `performance-engineer` no
      gate 10) — verificação executável:
      `npm --prefix mnemonicos-frontend run build` → exit 0, linha `/login` presente na
      tabela de rotas impressa pelo build.
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff, produção e teste).

## Roteiro do gate 9 (fixado ANTES do código)

**Ambiente**: app real rodando localmente — em `mnemonicos-backend/`: `npm run db:up`
(sobe o Postgres local — ou `npm run db:setup`, que já encadeia `db:up`+`db:deploy`+
`db:seed`, `mnemonicos-backend/package.json:37`) seguido de `npm run dev` (API em
`http://localhost:3333`); em `mnemonicos-frontend/`: `npm run dev` (app em
`http://localhost:3000/login`); portas ocupadas sobem na próxima livre, com o ajuste de
`CORS_ORIGINS`/`BACKEND_API_URL` correspondente declarado no fecho, conforme o `CLAUDE.md`
do workspace. O `db:up`/`db:setup` antes dos dois `npm run dev` garante que o ADMIN
semeado exista no banco local usado no exercício.

**Sujeito**: o ADMIN semeado por `npm run db:seed` (persistente — não o EDITOR de teste
ad-hoc que `HANDOFF-PLAN-003.md` manda criar via API e deletar ao fim do roteiro,
`HANDOFF-PLAN-003.md:96-102`). Credenciais lidas de `SEED_ADMIN_EMAIL`/
`SEED_ADMIN_PASSWORD` no `.env` do backend — nunca chutadas (mesma régua de
`HANDOFF-PLAN-003.md:19`, "nunca chutar credencial").

**Pré-condição**: sessão limpa em `/login` (sem cookie de sessão) — usar aba anônima ou
limpar os cookies do domínio antes de cada tentativa de login; ao final de cada submissão
bem-sucedida, fazer logout para restaurar o estado limpo antes do próximo passo.

1. (AC-030-001) Acessar `http://localhost:3000/login` sem sessão, no tema claro e depois
   no tema escuro (alternar `prefers-color-scheme` via DevTools) — confirmar card central
   em duas metades (painel ilustrado no topo, painel de formulário na base) sobre o fundo
   em tela cheia com a mesma atmosfera, card percebido flutuando (sombra), cabeçalho e
   rodapé do aplicativo presentes e navegáveis nos dois temas. Confirmar, no mesmo passo,
   que o fundo (`LoginNightBackdrop`) pinta atrás de `SiteHeader`/`<main>`/rodapé — sem
   ser cortado dentro de `<main max-w-5xl>` — evidência de que nenhum ancestral introduz
   `transform`/`filter`/`perspective`/`contain` (TRISK-031-003).
2. (AC-030-006) Em outra aba, navegar para outra rota do aplicativo (ex.: a home pública
   `/` ou uma tela já autenticada da área interna) e confirmar que cabeçalho, rodapé e
   contêiner permanecem visualmente idênticos ao estado anterior ao redesenho.
3. (AC-030-007) Com `/login` aberto, redimensionar a viewport do DevTools para 360px,
   768px e 1280px de largura e confirmar ausência de rolagem horizontal nas três.
4. (AC-030-008) Com a viewport em 360px, confirmar que o painel ilustrado ocupa uma faixa
   baixa (não dominante) da tela e que o painel de formulário aparece acima da dobra, sem
   precisar rolar.
5. (AC-030-009) Ativar `prefers-reduced-motion: reduce` (emulação do DevTools) e recarregar
   `/login`; confirmar que nenhuma animação decorativa (estrela cadente/brilho) ocorre no
   fundo nem no painel ilustrado, e que o formulário permanece funcional (foco por
   teclado, digitação e botão de envio habilitado após a hidratação).
6. (AC-030-012) Submeter e-mail e senha corretos do sujeito de seed em dois ramos: (a)
   acessando `/login` diretamente (sem `next`) — confirmar autenticação e redirecionamento
   para `INTERNAL_HOME`; (b) acessando `/login?next=<caminho interno seguro>` — confirmar
   autenticação e redirecionamento para o `next` informado. Restaurar (logout) ao final de
   cada tentativa.
7. (TRISK-031-004 — foco de teclado) Com `/login` aberto e sessão limpa, pressionar Tab
   repetidamente a partir do topo da página até alcançar o formulário: confirmar que a
   ordem de foco visita e-mail → senha → toggle de mostrar/ocultar senha → botão de envio,
   sem passar por nenhum elemento do fundo (`LoginNightBackdrop`) nem do painel ilustrado
   (`LoginIllustratedPanel`) — ambos `aria-hidden="true"`, herdado das TASKs 002/003 — e
   que o indicador de foco visível em cada parada tem contraste ≥3:1 contra o fundo
   imediato.
8. (TRISK-031-004 — robustez da ilustração) Bloquear/remover o SVG inline do painel
   ilustrado via DevTools (ex.: `display: none` no `<svg>` ou desabilitar a folha de
   estilo que o pinta) e confirmar que o formulário de login permanece funcional (campos,
   toggle e botão operáveis, submissão bem-sucedida) — a ilustração é puramente
   decorativa, sua ausência/degradação não pode quebrar a tela.
9. (TRISK-031-004 — autofill) Com um e-mail/senha já salvos pelo navegador para o domínio
   local, focar o campo de e-mail e aceitar a sugestão de autofill: confirmar que o texto
   preenchido permanece legível (contraste mantido) sobre o fundo em pílula, sem o
   navegador sobrescrever a forma pilulada com o estilo padrão de autofill.
10. (TRISK-031-004 — `forced-colors`) Ativar a emulação `forced-colors: active` no
    DevTools e recarregar `/login`: confirmar que campos, botão e indicador de foco
    permanecem distinguíveis e operáveis (bordas/contornos não desaparecem sob o modo de
    alto contraste forçado do SO).
11. (TRISK-031-004 — aviso de sessão expirada acima da dobra) Pré-condição: viewport em
    360px. Navegar diretamente para `http://localhost:3000/login?sessao=expirada`
    (parâmetro real de `SESSION_EXPIRED_PARAM`/`SESSION_EXPIRED_VALUE` —
    `mnemonicos-frontend/src/store/api.ts:203-204`) e confirmar que o aviso `role="status"`
    ("Sua sessão expirou. Entre novamente.") está visível sem rolagem, acima do
    formulário.

## Riscos específicos

- TRISK-031-003: confirmado no passo 1 do roteiro acima — se algum ancestral introduzir
  contexto de empilhamento, o backdrop vaza/corta dentro do `<main max-w-5xl>`; reabrir
  DEC-031-001 se isso ocorrer.
- TRISK-031-004 (cobertura por roteiro, não por AC formal): trânsito guard →
  `/login?next=` → login → `next` (passo 6); foco de teclado visível (passo 7); robustez
  da ilustração (passo 8); autofill do navegador sobre o campo em pílula (passo 9);
  `forced-colors` (passo 10); aviso de sessão expirada visível acima da dobra em 360px
  (passo 11) — itens adicionais do roteiro de implementação, sem AC formal associado.

---

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-146

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
