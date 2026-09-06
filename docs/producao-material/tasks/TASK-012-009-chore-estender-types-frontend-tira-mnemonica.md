# TASK-012-009: Estender `types/domain.ts` (frontend) com `MnemonicStrip`/`MnemonicFrame`

**Slug**: producao-material
**Pertence a**: PLAN-012
**Realiza (FRs)**: nenhuma
**Componente**: COMP-012-009 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Done

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch única do épico, estratégia `unica`)
**Padrão de commit**: Conventional Commits (`chore:` — espelho de tipos, sem lógica)
**Framework de teste**: Jest via `next/jest` (`npm --prefix mnemonicos-frontend test`)

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-012-010, TASK-012-011

## Contexto

Espelha, no frontend, o formato que `tira.service.ts` (backend, TASK-012-005) devolve —
`MnemonicStripDetail`/`MnemonicFrameDetail` — mesma resolução já aplicada a
`RawContentSummary`/`RuleBreakdown` em TASK-006-004: o contrato é provado pela rede de
paridade cross-repo (COMP-012-008, `tira-frontend-contract.test.ts`), não pela declaração
em si — esta TASK não a redige (fora desta lista; a prova de paridade real é da
TASK-012-011). Sem dependência de TASK-012-005 porque o formato já está congelado no PLAN
§3 (COMP-012-004/COMP-012-009), no mesmo espírito de contrato-primeiro que já rendeu
`RawContentSummary` "forma provisória" em TASK-006-004 até o consumidor real confirmar.

## Escopo

### Inclui

- `mnemonicos-frontend/src/types/domain.ts`:
  ```ts
  export interface MnemonicFrame {
    id: string;
    text: string;
    position: number;
    originBlock: string | null;
  }

  export interface MnemonicStrip {
    id: string;
    frames: MnemonicFrame[];
  }
  ```
  — campos literais exatamente como declarados na interface pública de COMP-012-004/
  COMP-012-009 do PLAN §3 (`MnemonicFrameDetail`/`MnemonicStripDetail` no backend).
  Comentário de fonte (mesmo estilo de `RawContent`/`RuleBreakdown` já no arquivo):
  declara que o formato REAL vem de `MnemonicStripDetail`/`MnemonicFrameDetail` em
  `mnemonicos-backend/src/modules/tira/tira.service.ts` e que a rede de paridade
  cross-repo é `mnemonicos-backend/tests/unit/tira-frontend-contract.test.ts`
  (TASK-012-008/011, ainda a criar — o comentário NÃO afirma que a paridade já é testada
  aqui, lição ativa [Testes] "Comentário que afirma paridade entre os dois repos só vale
  se o teste LER as duas fontes").
- `mnemonicos-frontend/tests/types/mnemonic-strip.test.ts` (novo): uso não-nulo — constrói
  um `MnemonicStrip` literal com ≥1 `MnemonicFrame` e acessa cada campo.

### Não inclui

- `PRODUCTION_STAGE_TYPES`/`PRODUCTION_EVENT_TRANSITIONS` no frontend — DEC-010-006
  permanece (SPEC-011 §10 confirma que isso fica fora de escopo desta fatia); o frontend
  só espelha `MnemonicStrip`/`MnemonicFrame`, nunca o enum de tipo de etapa.
- A rede de paridade cross-repo (`tira-frontend-contract.test.ts`, COMP-012-008) — fora
  desta lista (TASK-012-008/011).
- Consumo destes tipos em `src/store/api.ts` (TASK-012-010) ou em qualquer tela
  (TASK-012-011/012).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Acrescentar `interface MnemonicFrame`/`interface MnemonicStrip` a
   `mnemonicos-frontend/src/types/domain.ts`, no mesmo bloco de estilo de
   `RawContent`/`RuleBreakdown` (docblock de fonte canônica).
2. Escrever `tests/types/mnemonic-strip.test.ts` com um objeto literal exercitando todos
   os campos, inclusive `originBlock: null` (caso de Quadro criado manualmente) e
   `originBlock: 'concept'` (caso gerado automaticamente).

## Critérios de pronto

- [ ] `mnemonicos-frontend/src/types/domain.ts` exporta `interface MnemonicFrame` (`id`,
      `text`, `position`, `originBlock: string | null`) e `interface MnemonicStrip` (`id`,
      `frames: MnemonicFrame[]`) — item do Inclui sem AC, oráculo é o contrato do próprio
      item (uso não-nulo de cada campo). Verificação executável:
      `npm --prefix mnemonicos-frontend test -- mnemonic-strip` → `Tests: ≥1 passed` — o
      teste constrói um `MnemonicStrip` com `frames` contendo 2 itens (1 com
      `originBlock: 'concept'`, 1 com `originBlock: null`) e afirma o valor de cada campo
      dos 2 objetos (`id`, `text`, `position`, `originBlock`). Falsificável: omitir um
      campo da interface faz o objeto literal do teste falhar o typecheck.
- [ ] `npm --prefix mnemonicos-frontend run typecheck` → exit 0.
- [ ] O comentário de fonte de `MnemonicFrame`/`MnemonicStrip` declara (i) que o formato
      real vem de `mnemonicos-backend/src/modules/tira/tira.service.ts`
      (`MnemonicStripDetail`/`MnemonicFrameDetail`) e (ii) aponta
      `mnemonicos-backend/tests/unit/tira-frontend-contract.test.ts` como a rede de
      paridade cross-repo (ainda a criar) — sem afirmar que a paridade já é testada por
      esta TASK. Verificação executável (checagem de conteúdo textual, contrato §273(b)):
      `grep -nE "tira\.service\.ts|tira-frontend-contract" mnemonicos-frontend/src/types/
      domain.ts` → ao menos 1 âncora de fonte e 1 de teste. Falsificável: comentário
      ausente faz o `grep` vir vazio, vermelho.
- [ ] `PRODUCTION_STAGE_TYPES`/`PRODUCTION_EVENT_TRANSITIONS` **não** entram em
      `mnemonicos-frontend/src/types/domain.ts` por esta TASK (DEC-010-006) — verificação
      executável (ausência, contrato §273): `git diff main...HEAD -- mnemonicos-frontend/
      src/types/domain.ts | grep -cE "PRODUCTION_STAGE_TYPES|PRODUCTION_EVENT_TRANSITIONS"`
      → `0`. Falsificável: introduzir qualquer um dos 2 símbolos faz o `grep` casar,
      vermelho.
- [ ] Sem warnings/lints novos (`npm --prefix mnemonicos-frontend run lint` → exit 0).
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil (`next-16.md` §3 — identificadores em
      inglês; texto de interface, quando houver, em pt-BR; nenhum rótulo `_LABELS` exigido
      aqui, pois `originBlock` não tem enum — DEC-012-004).
- [ ] Code review aprovado.

## Riscos específicos

- A prova de paridade real cross-repo (o formato aqui bater com o que `tira.service.ts`
  de fato devolve) é da TASK-012-011, fora desta lista — esta TASK não a redige; o
  formato declarado aqui é o congelado no PLAN §3, não verificado contra código real de
  serviço ainda.
- Nenhuma lição ativa de `guidelines/project/lessons.md` se aplica diretamente a esta
  TASK além da já citada no Escopo (comentário de paridade não pode prometer o que ainda
  não existe).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-06T19:13:24-0300
**Data conclusão**: 2026-09-06T19:33:33-0300
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 8191deb (implementação inicial `ae259c0`, retry `8191deb`)
**Jira**: KAN-59
**Implementado por**: developer
**Revisado por**: code-reviewer (REPROVADO na 1ª rodada — achado A3; CONVERGIU no re-review delta-scoped)
**Tentativas**: 2 (1 retry, roteado pelo achado A3 do code-reviewer)
**Cobertura final**: n/a (item do Inclui sem AC — oráculo é o contrato do próprio item)
**Arquivos modificados**:
  - mnemonicos-frontend/src/types/domain.ts
  - mnemonicos-frontend/tests/types/mnemonic-strip.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando (1/1, typecheck exit 0)
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (convergiu após retry — fixture de `position` corrigido para valores válidos de domínio)
- [x] ACs verificados (n/a — sem AC numerado)
- [x] Segurança (gate 8): n/a — declaração de tipo pura, sem lógica
- [x] Comportamento (gate 9): n/a — tipos de domínio, sem efeito observável

**Notas**: achado A3 (fixture com `position: 0`, inválido pelo domínio — SPEC AC-011-001/008/010 e `tira.schema.ts` da mesma wave exigem posição ≥ 1) corrigido no retry; lição registrada em `guidelines/project/lessons.md` (reincidência da lição "paridade cross-repo" — a rede de paridade prova nome/tipo, nunca faixa de valores).

**Notas**:
