# TASK-036-004: `ThemeToggle` — alternador manual de tema

**Slug**: producao-material
**Pertence a**: PLAN-036
**Realiza (FRs)**: FR-036-009, FR-036-010, FR-036-011
**Funcionalidade**: FEAT-036-002 (primária)
**Componente**: COMP-036-002 (principal)
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: TASK-036-002 (consome `THEME_STORAGE_KEY`/`ThemeName`)
- **Bloqueia**: TASK-036-006

## Contexto

O tema hoje só reage a `prefers-color-scheme`; `ThemeToggle` acrescenta a troca manual
síncrona, persistida independente de sessão (A-036-005), prevalecendo sobre a preferência
do dispositivo a partir da escolha (FR-036-011; memo — PLAN-036 §3 COMP-036-002, §4).

## Escopo

### Inclui
- `mnemonicos-frontend/src/components/theme-toggle.tsx` — `'use client'`. Lê o tema
  efetivo atual via `useSyncExternalStore`, com `getSnapshot` lendo
  `document.documentElement.dataset.theme` (fallback a
  `matchMedia('(prefers-color-scheme: dark)').matches` quando o atributo não está setado —
  nunca um default hardcoded, TRISK-036-004) e `subscribe` combinando (a) o listener de
  `matchMedia('(prefers-color-scheme: dark)').addEventListener('change', ...)` (mudança de
  preferência do SO) e (b) um pub/sub de módulo próprio, notificado pelo próprio
  `ThemeToggle` depois de escrever `dataset.theme` no clique — não há evento nativo de
  mutação de `dataset`, e o mesmo módulo é o único mutador desse atributo no lado cliente
  (a leitura inicial de TASK-036-003 roda antes da hidratação, fora do ciclo de vida do
  componente).
- Ao clicar: calcula o tema oposto do lido; grava `localStorage[THEME_STORAGE_KEY]`
  (constante de `night-palette-tokens.ts`, TASK-036-002); seta
  `document.documentElement.dataset.theme = <novo tema>`; notifica os subscribers do
  próprio módulo (para o próprio componente re-renderizar no mesmo tick — sem esperar
  evento externo).
- A escrita em `localStorage` no clique é envolvida em `try/catch` — se lançar (mesmas
  causas acima: modo privado, `SecurityError`, bloqueio de storage), o `dataset.theme`/
  estado em memória do componente ainda muda (a troca visual funciona nesta sessão), só a
  PERSISTÊNCIA entre reloads é que fica comprometida; sem propagar erro ao usuário.
- `aria-label` reflete a AÇÃO disponível no estado atual (NFR-036-001) — ex. tema claro
  ativo → `"Mudar para tema escuro"`; tema escuro ativo → `"Mudar para tema claro"`.

### Não inclui
- Script de bootstrap (TASK-036-003) — só compartilha a constante `THEME_STORAGE_KEY`.
- Montagem no header (TASK-036-006) — inclusive a prova de PRESENÇA em toda rota
  (AC-036-005, AC-036-007, parte "presente e visível em toda rota").

## Critérios de pronto

- [ ] Render inicial reflete o atributo já presente no `<html>` — teste que seta
      `document.documentElement.dataset.theme = 'dark'` ANTES de montar e afirma o rótulo
      acessível correspondente (`"Mudar para tema claro"`, já que o estado atual é escuro) —
      cobre AC-036-007 (parte "dois estados distinguíveis" — a parte "presente em toda
      rota" é de TASK-036-006), NFR-036-001 e AC-036-013 (parte — rótulo do alternador; a
      parte do controle de autenticação é de TASK-036-005). Verificação executável: `npm --prefix
      mnemonicos-frontend test -- src/components/theme-toggle.test.tsx` → `PASS`, com
      `render(<ThemeToggle />)` e `screen.getByRole('button', { name: 'Mudar para tema claro'
      })`. Mutante: hardcodar o rótulo/estado inicial como sempre "claro" reprova este
      caso.
- [ ] `userEvent.click` no botão → `document.documentElement.dataset.theme` muda
      IMEDIATAMENTE (mesmo tick, sem indicador de carregamento renderizado) E
      `localStorage.getItem(THEME_STORAGE_KEY)` reflete o novo valor — cobre
      AC-036-010, AC-036-011. Mesmo arquivo, `user-event` (nunca `fireEvent` — perfil `next-16.md`),
      afirmando as duas mudanças logo após o `await user.click(...)`, sem nenhum `role="status"`/
      indicador de progresso no DOM. Mutante: remover a escrita em `localStorage` dentro do
      handler de clique reprova a asserção de `localStorage.getItem`.
- [ ] Sem preferência salva, com `matchMedia` mockado sem `matches` (SO sem preferência
      detectável) → o rótulo inicial assume tema claro como efetivo (default de
      FR-036-008, em conjunto com o CSS de TASK-036-002) — contrato do próprio item, sem AC
      próprio isolado (a aplicação visual final depende do CSS; este critério prova só a
      leitura do componente). Mesmo arquivo, `matchMedia` mockado com `matches: false`.
- [ ] `localStorage.setItem` lançando ao clicar → o clique NÃO lança exceção não capturada e
      `document.documentElement.dataset.theme` ainda muda (troca visual funciona mesmo sem
      conseguir persistir) — mesmo arquivo, mock de `localStorage.setItem` lançando.
      Mutante: propagar a exceção sem capturar faz o teste (que espera o clique completar
      sem throw) reprovar.
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff.

## Riscos específicos

- TRISK-036-004 (`ThemeToggle` "nascer" com o rótulo/estado errado por assumir um default
  fixo) é mitigado pelo critério de render inicial acima — o `getSnapshot` nunca assume
  tema fixo, sempre lê `dataset.theme`/`matchMedia`.
- Nota de molde (item h — leitura no eixo em pauta): a única ocorrência de
  `useSyncExternalStore` hoje no repo é `login-form.tsx:66-70`, mas ali o `subscribe` é
  `noopSubscribe` — serve só para distinguir o valor de servidor do de cliente num gate de
  hidratação (`true`/`false`), não para ler estado externo mutável real com notificação de
  mudança. Não é molde de COMO implementar o `subscribe`/`getSnapshot` reais que esta TASK
  precisa (leitura de `dataset.theme` + `matchMedia` + pub/sub de módulo) — só confirma que
  o hook já é usado no projeto e que o padrão de import (`react`) é o mesmo.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-30T02:43:19-0300
**Data conclusão**: 2026-09-30T03:35:31-0300
**Commit SHA**: 482b1a9
**Jira**: KAN-162

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (672/672 na suíte)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (wave 2 — 1 retry, cadeia de fallback sem teste por ramo)
- [x] ACs verificados (AC-036-007, AC-036-010, AC-036-011, AC-036-013 parcial)
- [ ] Segurança (gate 8): n/a — sem superfície de sessão/dado sensível
- [ ] Comportamento (gate 9): n/a — FEAT-036-002 ainda não completou (todas as TASKs Done, mas gate 9 roda no fecho da wave em que a FEAT completa — Wave 3, TASK-036-006 é quem monta os controles)
- [x] Design (gate 11): aprovado (wave 2 — 1 retry, botão sem cursor-pointer/hover perceptível)
