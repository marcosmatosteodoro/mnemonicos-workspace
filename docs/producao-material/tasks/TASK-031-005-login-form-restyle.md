# TASK-031-005: Reestilizar o formulário de login (LoginForm)

**Slug**: producao-material
**Pertence a**: PLAN-031
**Realiza (FRs)**: FR-030-004 (parte — campo de e-mail), FR-030-005, FR-030-006, FR-030-007
**Componente**: COMP-031-005 (principal), COMP-031-001, COMP-031-006
**Wave**: 3
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Dependências

- **Depende de**: TASK-031-001, TASK-031-006
- **Bloqueia**: TASK-031-004

## Contexto

Reestiliza o formulário de login (`login-form.tsx:1-113`, memo de exploração) — campo de
e-mail em pílula, botão de largura total — sem tocar hidratação, mensagem genérica de
erro, status de envio ou redirecionamento; confirma a ausência de controles sem função
real (NFR-030-002).

## Escopo

### Inclui
- Restyle de `mnemonicos-frontend/src/components/login-form.tsx`: campo de e-mail em
  formato de pílula (bordas totalmente arredondadas, fundo preenchido em tom da paleta
  nova, ícone indicador à esquerda), rótulo "E-mail" (não "Username"), botão de envio de
  largura total em tom escuro da paleta nova — todas as cores vindas dos tokens de
  COMP-031-001.
- Confirmação, por leitura e por teste, de que nenhum controle sem função real
  (lembrar-me, esqueci a senha, criar conta) está presente no card redesenhado.
- Preservação do `PasswordField` (COMP-031-006, já reestilizado em TASK-031-006) como
  consumidor sem alteração de props/contrato.

### Não inclui
- Alteração de `method="post"`, do gate de hidratação (`useSyncExternalStore`), da
  mensagem genérica de erro `role="alert"`, do status "Entrando…", do redirecionamento
  para `next`/`INTERNAL_HOME`, de `aria-busy` ou da ausência de `aria-invalid` — NFR-030-002.
- Montagem do formulário dentro de `page.tsx` (COMP-031-004, TASK-031-004).
- Restyle do próprio `PasswordField` (COMP-031-006, TASK-031-006 — já concluído).

## Critérios de pronto

- [ ] Campo de e-mail em pílula (bordas totalmente arredondadas, fundo preenchido, ícone à
      esquerda) com rótulo "E-mail" — Testes cobrem AC-030-003 (parte — e-mail),
      AC-030-004: verificação executável:
      `npm --prefix mnemonicos-frontend test -- src/components/login-form.test.tsx` → OK
      (N tests), incluindo `getByLabelText('E-mail')` e asserção de classe/estrutura de
      pílula.
- [ ] Botão de envio ocupa a largura total (ou próxima) do painel de formulário, em tom
      escuro da paleta nova — Testes cobrem AC-030-003 (parte — botão): mesmo comando
      acima, asserção de classe de largura total no botão de envio.
- [ ] Nenhum controle de "lembrar-me", "esqueci a senha", "criar conta" ou qualquer outro
      controle sem função real está presente — Testes cobrem AC-030-005: mesmo comando
      acima, `queryByText`/`queryByRole` retornando `null` para os três rótulos, mais um
      inventário fechado dos controles interativos do formulário (`getAllByRole` sobre os
      papéis interativos dentro do formulário) com contagem fixa esperada de 4 (campo
      e-mail, campo senha, toggle de mostrar/ocultar senha, botão de envio) — fechando a
      cláusula "qualquer outro controle sem função real" com prova, não inferência.
- [ ] Cores do campo de e-mail e do botão vêm exclusivamente dos tokens de COMP-031-001;
      contraste ≥4,5:1 (texto/placeholder) e ≥3:1 (borda/ícone) sobre o fundo preenchido da
      pílula, nos dois temas; o rótulo "E-mail" é renderizado visualmente sobre a pílula
      (nunca `sr-only`/visualmente oculto — SPEC-030/NFR-030-001 já compromete rótulo
      visível sobre o fundo preenchido do campo, releitura do texto já aprovado pelo PO) —
      Testes cobrem AC-030-010 (parte — e-mail): verificação executável: mesmo comando
      acima, incluindo asserção que liga o token/classe CSS efetivamente aplicado ao
      texto/placeholder/borda/ícone do campo (ex.: `className` contém o token esperado, ou
      leitura do valor computado da CSS custom property) ao mesmo par de token medido no
      teste de contraste de TASK-031-001 — nome exato do token a critério do developer,
      mas a asserção não pode ficar solta do valor medido; mais o teste de contraste de
      TASK-031-001 (`src/app/globals-theme-contrast.test.ts`) cobrindo os pares de token
      usados aqui e cobrindo o rótulo visível (nunca apenas `getByLabelText`, que passa
      também com rótulo oculto).
- [ ] `login-form.test.tsx` continua passando sem alteração de asserção — `method="post"`,
      gate de hidratação, mensagem genérica de erro `role="alert"`, `aria-busy` durante o
      envio, ausência de `aria-invalid`, status "Entrando…", redirecionamento para
      `next`/`INTERNAL_HOME` — Testes cobrem AC-030-011 (parte — `login-form.test.tsx`):
      verificação executável:
      `npm --prefix mnemonicos-frontend test -- src/components/login-form.test.tsx` → OK
      (mesma contagem de asserções do commit-pai, capturada como baseline antes do diff).
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff, produção e teste).

## Riscos específicos

- TRISK-031-001 (contraste AA): medido nesta TASK para o campo de e-mail (texto,
  placeholder, rótulo); reservar margem para uma rodada extra do `product-designer` se o
  par escolhido em TASK-031-001 não alcançar o piso aqui.
- Lição ativa `cor-sem-ntica-de-texto-erro-sucesso-link-vem-de-token-do-tema-nunca-de-literal-da-paleta`:
  a mensagem de erro (`role="alert"`) já usa `text-danger`/token — não regredir para
  `text-red-*` literal ao reestilizar em volta dela.

---

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**:
**Data conclusão**:
**Commit SHA**:
**Jira**: KAN-147

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
