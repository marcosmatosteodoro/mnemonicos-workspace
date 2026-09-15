# TASK-025-012: EMENDA `content-form.tsx` — enxerto do controle de exportação

**Slug**: producao-material
**Pertence a**: PLAN-025
**Realiza (FRs)**: FR-024-012
**Componente**: COMP-025-012 (principal)
**Wave**: 7
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: TASK-025-011
- **Bloqueia**: nenhuma

## Contexto

`ContentForm` (`mnemonicos-frontend/src/components/content-form.tsx`, COMP-006-014) já
existe e cobre os dois modos `create`/`edit` (`mode: 'create'` sem `contentId`; `mode:
'edit'; contentId: string`) — este enxerto só acrescenta o ponto de acionamento da
exportação (FR-024-012) na tela do Conteúdo bruto, ao lado das ações já existentes do
formulário. **AC-024-014 é coberto por 2 TASKs em paralelo** (TASK-025-012 e TASK-025-013,
nenhuma depende da outra): esta TASK prova a faceta da tela do Conteúdo bruto; a faceta da
tela da Tira mnemônica é da TASK-025-013.

## Escopo

### Inclui

- `mnemonicos-frontend/src/components/content-form.tsx` (EMENDA — arquivo existente):
  `<PublicationExportControl rawContentId={contentId} />` renderizado só quando `mode ===
  'edit'` (o modo `create` ainda não tem `contentId` — nada para exportar antes de salvar).
- `mnemonicos-frontend/src/components/content-form.test.tsx` (EMENDA — arquivo existente):
  novo caso cobrindo a presença/ausência do controle por modo (ver Critérios de pronto).

### Não inclui

- Qualquer mudança no modo `create` do formulário.
- O componente `PublicationExportControl` em si (TASK-025-011).

## Critérios de pronto

- [ ] **Testes cobrem AC-024-014 (parte content-form — a faceta da tela da Tira é da
      TASK-025-013)** — verificação executável: `npx jest --runTestsByPath
      src/components/content-form.test.tsx` (cwd `mnemonicos-frontend`) → `PASS`. Cenários:
      (a) `ContentForm` montado com `mode="edit"` e `contentId` existente → o controle de
      exportação (`PublicationExportControl`) está presente na árvore, recebendo o mesmo
      `contentId` como `rawContentId`; (b) `ContentForm` montado com `mode="create"` → o
      controle de exportação NÃO está presente.
- [ ] Regressão: a suíte `content-form.test.tsx` já existente continua verde após o enxerto
      — mesmo comando acima → `PASS`, todos os casos pré-existentes (criação/edição/remoção)
      + os 2 novos desta TASK.
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git diff --name-only
      main...HEAD`) — verificação executável: `npx eslint src/components/content-form.tsx
      src/components/content-form.test.tsx` (cwd `mnemonicos-frontend`) → 0 problemas.

## Riscos específicos

- Enxerto cirúrgico em componente existente com 2 modos (`create`/`edit`) — condicionar
  a renderização a `mode === 'edit'` sem tocar nenhum outro ramo condicional já existente
  no arquivo (mesma disciplina de emenda mínima de TASK-025-013).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-14T21:15:00-0300
**Data conclusão**: 2026-09-14T22:05:00-0300
**Commit SHA**: 87b4f70 (implementação) · 453d84f (retry — gate 11: reordena controle após link da Quebra da regra)
**Jira**: KAN-119

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (Wave 7)
- [x] ACs verificados
- [x] Segurança (gate 8): n/a — sem superfície sensível (composição client pura, nenhum auth/injeção nova)
- [x] Comportamento (gate 9): **verificado** — V1 de `HANDOFF-PLAN-025.md` exercitado com ambiente real (migração aplicada, servidor reiniciado): as 2 Variantes exportadas com sucesso na tela do Conteúdo bruto, download real, sem regressão entre estados.
<!-- Branch, tentativas, arquivos, revisores e narrativa (retries, escalações) vivem no
ledger da sessão e no commit da closure (4.76) — não se repetem aqui (4.409). -->
