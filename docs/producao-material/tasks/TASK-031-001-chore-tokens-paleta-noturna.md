# TASK-031-001: Definir tokens da paleta noturna no `@theme`

**Slug**: producao-material
**Pertence a**: PLAN-031
**Realiza (FRs)**: nenhuma
**Componente**: COMP-031-001 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Todo

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-031-002, TASK-031-003, TASK-031-004, TASK-031-005, TASK-031-006

## Contexto

Introduz a paleta noturna aditiva no bloco `@theme` de `globals.css` que sustenta todo o
redesenho de `/login` — tokens de céu, montanhas/dunas, lua, estrelas, campo em pílula e
botão, redefinidos sob `prefers-color-scheme: dark`, sem tocar os tokens semânticos hoje
usados pelas demais rotas (memo de exploração — `globals.css:1-80`).

## Escopo

### Inclui
- Tokens de cor aditivos no bloco `@theme` de `mnemonicos-frontend/src/app/globals.css`
  para céu em degradê, montanhas/dunas, lua, estrelas, campo em pílula (fundo/ícone) e
  botão — nomes a critério da implementação (ex.: `--color-dusk-*`/`--color-night-*`),
  desde que não colidam com `--color-ink-*`/`--color-brand-*`/`--color-recall-*`
  existentes.
- Redefinição dos mesmos tokens sob `@media (prefers-color-scheme: dark)`, no mesmo bloco,
  seguindo o padrão das variáveis semânticas já existentes (`globals.css:32-34`).
- Comentário de contraste AA (4,5:1 texto, 3:1 borda/ícone) ao lado de cada par
  claro/escuro dos tokens de texto/borda/ícone — mesmo padrão já usado para
  `--danger`/`--link`.

### Não inclui
- Aplicação dos tokens a qualquer componente visual (COMP-031-002 a COMP-031-006, TASKs
  seguintes).
- Criação de `tailwind.config.js` (vetado pelo guideline de projeto —
  `guidelines/project/frontend/README.md`, "Não existe `tailwind.config.js` e não se deve
  criar um").
- Alteração, renomeação ou substituição de tokens semânticos existentes (`--surface`,
  `--surface-raised`, `--border-subtle`, `--text-strong`, `--text-muted`, `--link`,
  `--danger`).

## Critérios de pronto

- [ ] Cada token novo (céu, montanhas/dunas, lua, estrelas, pílula, botão) está definido
      no bloco `@theme` e redefinido sob `@media (prefers-color-scheme: dark)`, sem
      reutilizar nem sobrescrever `--color-ink-*`/`--color-brand-*`/`--color-recall-*` —
      verificação executável: `npm --prefix mnemonicos-frontend test -- src/app/globals-theme-tokens.test.ts`
      → OK (teste novo que lê `globals.css` e confere, por nome, a presença de cada token
      declarado nos dois blocos `@theme`/`prefers-color-scheme: dark`; fixado antes do
      código, com controle negativo de um nome ausente reprovando).
- [ ] Contraste AA medido e comentado para cada par claro/escuro dos tokens de
      texto/borda/ícone da paleta nova (4,5:1 texto, 3:1 borda/ícone) — mesmo padrão de
      `globals.css:32-34` (lição ativa
      `cor-sem-ntica-de-texto-erro-sucesso-link-vem-de-token-do-tema-nunca-de-literal-da-paleta`:
      cor semântica nunca nasce como literal solta, sempre como token com contraste
      medido) — verificação executável:
      `npm --prefix mnemonicos-frontend test -- src/app/globals-theme-contrast.test.ts` →
      OK (teste novo que calcula a razão de contraste WCAG dos pares hex declarados contra
      o fundo do par e reprova abaixo do piso; fixado antes do código).
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff, produção e teste).

## Riscos específicos

- TRISK-031-001 (contraste AA de placeholder/rótulo sobre o fundo preenchido da pílula) é
  mitigado aqui só na origem (par de token com contraste medido); a medição no contexto
  real de uso (placeholder/rótulo sobre a pílula preenchida) é critério de
  TASK-031-005/TASK-031-006, que tocam os campos.

---

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-143

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
