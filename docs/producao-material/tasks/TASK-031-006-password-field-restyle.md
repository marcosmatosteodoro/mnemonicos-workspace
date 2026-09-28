# TASK-031-006: Reestilizar o campo de senha em pílula (PasswordField)

**Slug**: producao-material
**Pertence a**: PLAN-031
**Realiza (FRs)**: FR-030-004 (parte — campo de senha)
**Componente**: COMP-031-006 (principal), COMP-031-001
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: TASK-031-001
- **Bloqueia**: TASK-031-005

## Contexto

Reestiliza o campo de senha existente (`password-field.tsx:60-99`, memo de exploração)
para o formato de pílula com ícone de toggle, preservando alvo de toque 28×28, foco
visível e o comportamento de alternância mostrar/ocultar intocado — mesmo componente, sem
reescrita (NFR-030-004).

## Escopo

### Inclui
- Restyle de `mnemonicos-frontend/src/components/password-field.tsx`: bordas totalmente
  arredondadas, fundo preenchido em tom da paleta nova (tokens de COMP-031-001), ícone de
  toggle mostrar/ocultar mantido à direita do campo, alvo de toque 28×28 (`h-7 w-7`)
  preservado, foco visível (`has-[input:focus-visible]:outline-2`) preservado com o token
  novo aplicável.
- Substituição de qualquer literal de cor hoje eventualmente usado por token de
  COMP-031-001.

### Não inclui
- Alteração do comportamento de alternância mostrar/ocultar senha, do `useState` local ou
  das props (`value`/`onChange`) — NFR-030-004.
- O campo de e-mail e o botão de envio (COMP-031-005, TASK-031-005).
- Contraste do painel ilustrado/fundo (COMP-031-002/003).

## Critérios de pronto

- [ ] Campo de senha em formato de pílula (bordas totalmente arredondadas, fundo
      preenchido em tom da paleta nova), ícone de toggle à direita, alvo de toque 28×28 e
      foco visível preservados — Testes cobrem AC-030-003 (parte — campo de senha):
      verificação executável:
      `npm --prefix mnemonicos-frontend test -- src/components/password-field.test.tsx` →
      OK (N tests), incluindo asserção de classe/estrutura de pílula e do alvo de toque
      28×28 do botão de toggle.
- [ ] Cores do campo (fundo, borda, ícone) vêm exclusivamente dos tokens de COMP-031-001;
      contraste ≥4,5:1 (texto) e ≥3:1 (borda/ícone) sobre o fundo preenchido da pílula, nos
      dois temas; o rótulo do campo é renderizado visualmente sobre a pílula (nunca
      `sr-only`/visualmente oculto — SPEC-030/NFR-030-001 já compromete rótulo visível
      sobre o fundo preenchido do campo) — Testes cobrem AC-030-010 (parte — senha):
      verificação executável:
      `npm --prefix mnemonicos-frontend test -- src/components/password-field.test.tsx` →
      OK, incluindo asserção que liga o token/classe CSS efetivamente aplicado ao
      texto/borda/ícone do campo (ex.: `className` contém o token esperado, ou leitura do
      valor computado da CSS custom property) ao mesmo par de token medido no teste de
      contraste de TASK-031-001 — nome exato do token a critério do developer, mas a
      asserção não pode ficar solta do valor medido; mais o teste de contraste de
      TASK-031-001 (`src/app/globals-theme-contrast.test.ts`) cobrindo os pares de token
      usados aqui e cobrindo o rótulo visível (nunca apenas `getByLabelText`, que passa
      também com rótulo oculto).
- [ ] **Herdado do gate 11 de TASK-031-001** (product-designer, achado não-bloqueante
      roteado como critério — decisão 4.140): a borda da pílula precisa de contraste
      ≥3:1 contra o **fundo adjacente externo** ao campo (o painel de formulário, não o
      fundo interno da própria pílula — WCAG 1.4.11, "identifica o componente"), medido
      contra o token real que TASK-031-004/005 definirem para o painel; se o painel
      ainda não existir nesta wave, deixe o teste de contraste preparado para o par
      borda×painel (parametrizado pelo token, não hardcoded) e documente em comentário
      no teste qual token falta — verificação executável: mesmo comando de
      `globals-theme-contrast.test.ts` acima, com o par borda×painel incluído assim que
      o token do painel existir.
- [ ] **Herdado do gate 11 de TASK-031-001**: o placeholder do campo (quando aplicável)
      usa `--color-night-pill-icon` (medido 6,45:1/7,97:1, passa o piso de texto) como
      cor — nunca opacidade de `pill-text` sem medir. Verificação executável: asserção no
      teste de estilo/contraste ligando a cor computada do placeholder ao token
      `pill-icon`.
- [ ] `password-field.test.tsx` continua passando sem alteração de asserção (toggle
      mostrar/ocultar idêntico, `value`/`onChange`, alvo de toque, foco visível) — Testes
      cobrem AC-030-011 (parte — `password-field.test.tsx`): verificação executável:
      `npm --prefix mnemonicos-frontend test -- src/components/password-field.test.tsx` →
      OK (mesma contagem de asserções do commit-pai, capturada como baseline antes do
      diff).
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff, produção e teste).

## Riscos específicos

- TRISK-031-001 (contraste AA de placeholder/rótulo sobre o fundo preenchido da pílula):
  medido nesta TASK para o campo de senha (borda/ícone); reservar margem para uma rodada
  extra do `product-designer` se o par escolhido em TASK-031-001 não alcançar o piso aqui.
- Lição ativa `cor-sem-ntica-de-texto-erro-sucesso-link-vem-de-token-do-tema-nunca-de-literal-da-paleta`:
  qualquer cor de estado (foco, erro) usada aqui vem de token, nunca de classe utilitária
  de paleta solta (ex.: `text-red-*`).

---

## Histórico de execução (preenchido pelo /keelson:implement)

**Data início**: 2026-09-28T20:06:08-0300
**Data conclusão**: 2026-09-28T20:40:28-0300
**Commit SHA**: `17069ae` (retry gate 11 — ícone à esquerda — sobre `80d7879`)
**Jira**: KAN-148

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado — security-engineer (superfície: `password-field.tsx`, campo de senha do formulário de login)
- [ ] Comportamento (gate 9): n/a — SPEC-030 sem FEATs; gate 9 consolida na Etapa 4 contra o DoD do PLAN-031
