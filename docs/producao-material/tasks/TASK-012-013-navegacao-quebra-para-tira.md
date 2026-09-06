# TASK-012-013: Adicionar navegação condicional da Quebra da regra para a Tira

**Slug**: producao-material
**Pertence a**: PLAN-012
**Realiza (FRs)**: FR-011-001
**Componente**: COMP-012-013 (principal)
**Wave**: 7
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-tira-mnemonica` (`git.branchStrategy: "unica"`; `git.branchNaming: "slug"`)
**Padrão de commit**: Conventional Commits (`commit.convention: "conventional"`) — ex.: `feat(producao-material): link condicional da quebra da regra para a tira`
**Framework de teste**: Jest 30 + Testing Library, montado contra `makeStore()` + `fetch` mockado — extensão do harness já existente em `rule-breakdown-form.test.tsx`

## Dependências

- **Depende de**: TASK-012-012
- **Bloqueia**: nenhuma

## Contexto

Com a tela da Tira mnemônica pronta (TASK-012-012), falta o ponto de entrada a partir da tela existente da Quebra da regra: um link condicional, habilitado só quando a Quebra já foi salva. `rule-breakdown-form.tsx` já resolve esse estado via `useGetRuleBreakdownQuery` (`data`/`isNotFound`/`isRealError`) — esta TASK reusa o mesmo hook já montado no componente, sem duplicar lógica de estado.

## Escopo

### Inclui

- 1 link condicional em `mnemonicos-frontend/src/components/rule-breakdown-form.tsx` (arquivo já existente, relido antes de editar):
  - Quebra da regra salva (`data !== undefined`, isto é, sucesso de `useGetRuleBreakdownQuery`): renderiza `<Link href={\`/content/${contentId}/tira\`}>Ir para a Tira mnemônica</Link>` (mesmo padrão do `<Link>` "Ir para o Conteúdo bruto" já presente no arquivo, token `text-link` já em uso ali).
  - Quebra da regra **não** salva (`isNotFound === true`, o mesmo estado que já abre o formulário vazio): renderiza uma orientação em português — "Conclua a Quebra da regra antes de gerar a Tira mnemônica." — sem oferecer a ação/link de gerar a Tira.
  - Estado de carregamento ou erro real (`isLoading`/`isRealError`): nenhum dos dois elementos acima aparece (mesmo padrão dos ramos já existentes no componente, que retornam cedo).
- Extensão do teste existente `mnemonicos-frontend/src/components/rule-breakdown-form.test.tsx` com os 2 casos novos (link presente / orientação presente), usando o mesmo `mount()`/`handler()`/`fetchSpy` já definidos no arquivo — nenhum harness novo.

### Não inclui

- Qualquer rota nova (a rota `/content/[id]/tira` já existe, TASK-012-012).
- Qualquer mudança em `useGetRuleBreakdownQuery`/`useSaveRuleBreakdownMutation` (`store/api.ts`) — o estado necessário já é exposto pelo hook tal como está.
- Qualquer mudança em `mnemonic-strip-board.tsx`/`page.tsx` da Tira (TASK-012-012, já entregues).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem; nunca siga um passo que enfraqueça um critério.

1. Reler `rule-breakdown-form.tsx` por inteiro antes de editar (arquivo já existente).
2. Adicionar o `<Link>`/orientação condicional próximo ao `<Link>` "Ir para o Conteúdo bruto" já existente, usando as variáveis `data`/`isNotFound` já computadas no componente — nenhum novo estado local, nenhuma nova chamada de hook.
3. Estender `rule-breakdown-form.test.tsx` com os 2 casos, reusando `mount()`/`handler()`/`breakdown()`/`NOT_FOUND_RESPONSE` já definidos no arquivo.

## Critérios de pronto

**Gate 9 (screenVerify)**: `n/a` para esta TASK, declarado — o passo 1 do "Roteiro do gate 9"
de TASK-012-012 já exercita este exato link em browser real (login → tela da Quebra da
regra com Quebra salva e Tira ainda não gerada → link visível → clique navega para
`/content/<id>/tira`), na mesma sessão/fixture da jornada da Tira. Criar um 2º roteiro
duplicaria ambiente/sujeito/pré-condição sem provar nada de novo — achado do `qa`
(pré-código, Etapa 3.5), resolvido apontando para o roteiro já fixado em vez de duplicá-lo.

- [ ] **AC-011-023 (parte — faceta UI, fechamento)**: extensão de `rule-breakdown-form.test.tsx`, montado com `makeStore()` + `Provider` + `fetch` mockado (harness já existente no arquivo, `mount()`/`handler()`), com 2 casos novos:
  1. Resposta `GET /api/v1/contents/<id>/breakdown` = 200 com o fixture `breakdown()` já existente no arquivo → `screen.getByRole('link', { name: 'Ir para a Tira mnemônica' })` presente, com `href` igual a `/content/content-1/tira` (usando o `CONTENT_ID` já constante no arquivo).
  2. Resposta `GET /api/v1/contents/<id>/breakdown` = `NOT_FOUND_RESPONSE` (404, já existente no arquivo) → texto exato "Conclua a Quebra da regra antes de gerar a Tira mnemônica." visível, **e** `screen.queryByRole('link', { name: 'Ir para a Tira mnemônica' })` é `null` (o link fica AUSENTE, não apenas desabilitado — AC-011-023 exige "sem oferecer a ação").
  Comando: `npm --prefix mnemonicos-frontend test -- rule-breakdown-form.test` → os 2 casos novos verdes, junto dos já existentes (nenhuma regressão nos casos herdados do arquivo).
- [ ] Token `text-link` reusado para o novo `<Link>` (mesmo token do `<Link>` "Ir para o Conteúdo bruto" já presente no arquivo) — confirmado por leitura: `grep -c 'text-link' mnemonicos-frontend/src/components/rule-breakdown-form.tsx` → contagem cresce de 1 (o link existente) para 2 (o novo), nunca introduz classe literal de paleta.
- [ ] Sem warnings/lints novos sobre `git diff --name-only main...HEAD` (produção e teste).
- [ ] Padrão de commit respeitado (Conventional Commits).
- [ ] Aderência à stack/padrões da ficha e do perfil (`guidelines/project/frontend/next-16.md`).
- [ ] Code review aprovado.

## Riscos específicos

- Nenhuma lição ativa de `guidelines/project/lessons.md` nomeia `rule-breakdown-form.tsx`
  ou o padrão de link condicional que esta TASK acrescenta (confirmado por leitura).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Branch**:
**Commit SHA**:
**Jira**: KAN-63
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
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a>

**Notas**:
