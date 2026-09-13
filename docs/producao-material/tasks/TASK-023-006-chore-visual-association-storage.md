# TASK-023-006: `visual-association-storage.ts` — camada de acesso ao binário no Postgres

**Slug**: producao-material
**Pertence a**: PLAN-023
**Realiza (FRs)**: nenhuma
**Componente**: COMP-023-003 (principal)
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Done

```yaml
override-erros: task-criterio-sem-ac
override-justificativa: >-
  Item do Inclui sem AC vinculado — oráculo é o contrato do próprio item
  (regra 4.286): COMP-023-003 é camada de storage pura, consumida por
  COMP-023-005 (visual-associations.service.ts, fora desta lista), sem FR
  realizado diretamente. Mesmo padrão de TASKs chore aprovadas do slug
  (TASK-006-004, TASK-006-007, TASK-012-002 — Done, sem AC numerado).
  Registrado como pendência de processo (lição candidata ao agile-coach).
override-aprovador: Tech Lead (autônomo, /keelson:auto)
```

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch do EPICO MNEMORA STUDIO, Estrategia unica -- decisao 4.126: F5 e uma fatia do epico, nunca abre branch propria; a sessao ja fez o sync de largada nela)

**Padrão de commit**: Conventional Commits (`feat:` — entrega a capacidade real de
persistir/ler o binário da imagem, mesmo padrão de TASK-012-001/TASK-023-001 para camadas
que introduzem I/O novo).
**Framework de teste**: Jest 30 + ts-jest com `@prisma/adapter-pg` real (`npm --prefix
mnemonicos-backend run test:integration`).

## Dependências

- **Depende de**: TASK-023-001
- **Bloqueia**: TASK-023-008, TASK-023-016

## Contexto

Camada fina sobre o Prisma que lê/escreve/apaga o binário como coluna `imageData Bytes` da
própria linha `VisualAssociation` (DEC-023-002 — Postgres, não filesystem nem blob externo,
incompatível com a topologia serverless do backend) — não é módulo de filesystem. As 2
funções operam sobre a MESMA `$transaction`/client recebido do chamador, nunca abrindo
transação própria (elimina a antiga preocupação de arquivo órfão fora da transação:
COMP-023-005, fora desta lista, é quem decide QUANDO chamar, dentro do `create`/`update` da
linha). Depende de TASK-023-001 pelo model `VisualAssociation` existir no Prisma Client
gerado.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/visual-associations/visual-association-storage.ts` (novo
  arquivo, sem sufixo `.schema/.service/.routes` — camada fina, mesmo espírito de
  `image-signature.ts` para módulo sem rota/schema próprios):
  ```ts
  export async function saveVisualAssociationImage(
    tx: PrismaClientOrTx,
    id: string,
    buffer: Buffer,
  ): Promise<void>;

  export async function readVisualAssociationImage(
    db: PrismaClientOrTx,
    id: string,
  ): Promise<Buffer | null>;
  ```
  `PrismaClientOrTx` é o mesmo tipo de parâmetro (`tx`/`db` recebido do chamador, nunca
  `$transaction` aberta localmente) já usado por `tira.service.ts`
  (`MnemonicStripClient`/`MnemonicFrameWriteClient`) — `saveVisualAssociationImage` faz
  `tx.visualAssociation.update({ where: { id }, data: { imageData: buffer } })`;
  `readVisualAssociationImage` faz `db.visualAssociation.findUnique({ where: { id },
  select: { imageData: true } })` e devolve `null` se a linha não existir.
- `mnemonicos-backend/tests/integration/visual-association-storage.integration.test.ts`
  (novo): dentro de uma `$transaction` real (`testPrisma.$transaction`), cria 1
  `VisualAssociation` (via `testPrisma`, autor próprio — fixture de `User`), chama
  `saveVisualAssociationImage` com um buffer PNG real de fixture (assinatura de bytes válida,
  reaproveitando um dos buffers de `image-signature.test.ts` se conveniente), e
  `readVisualAssociationImage` na MESMA transação confirmando round-trip byte-a-byte
  (`Buffer.compare(written, read) === 0`); e 1 caso `readVisualAssociationImage` para um id
  inexistente devolvendo `null`.

### Não inclui

- `image-signature.ts` (já pronto, TASK-023-002) — esta TASK não valida formato, só
  persiste/lê o buffer já validado por quem chama.
- Qualquer rota HTTP.
- A decisão de QUANDO chamar (no mesmo `create`/`update` da linha, ou em passo separado) —
  isso é COMP-023-005, fora desta lista.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Criar `visual-association-storage.ts` com as 2 funções, reusando o padrão de tipo de
   parâmetro `tx`/`db` já em uso em `tira.service.ts`.
2. Escrever `visual-association-storage.integration.test.ts` com
   `@prisma/adapter-pg` real, dentro de uma `$transaction`, seguindo o molde de
   `tira.service.integration.test.ts` para fixtures de `User`.

## Critérios de pronto

- [ ] `saveVisualAssociationImage`/`readVisualAssociationImage` fazem round-trip
      byte-a-byte de um buffer real contra o Postgres real, dentro da MESMA `$transaction`
      recebida — item do Inclui sem AC isolado, oráculo é o contrato do próprio item
      (não-nulo). Verificação executável: `npm --prefix mnemonicos-backend run
      test:integration -- visual-association-storage` → `OK (≥2 tests)`, incluindo o caso
      que grava um buffer PNG de fixture e o lê de volta na MESMA `$transaction`, afirmando
      `Buffer.compare(written, read) === 0`. Falsificável: qualquer serialização/encoding
      intermediário (ex.: base64 acidental, truncamento) faria o `Buffer.compare` divergir
      de `0`. Fixada antes do código.
- [ ] `readVisualAssociationImage` devolve `null` para um id inexistente, sem lançar
      exceção — mesmo comando, caso próprio.
- [ ] Nenhuma das 2 funções abre `$transaction` própria — verificação executável (condição
      estrutural, contrato §273(b)): `grep -c "\$transaction"
      mnemonicos-backend/src/modules/visual-associations/visual-association-storage.ts` →
      `0` (o arquivo só recebe `tx`/`db` como parâmetro). Falsificável: qualquer chamada
      própria a `$transaction` dentro do arquivo faz o `grep` casar, vermelho.
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff, `git diff --name-only
      main...HEAD`).
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil (Prisma 7, `@prisma/adapter-pg`).
- [ ] Code review aprovado.

## Riscos específicos

- Lição ativa "[Testes] Suíte de integração com DDL/TRUNCATE em banco compartilhado exige
  exclusividade real entre execuções concorrentes" — esta é a 2ª TASK a exercitar o banco
  de teste nesta fatia (depois de TASK-023-001); rodar isolado (sem gates concorrentes na
  mesma máquina, sem processo `jest` zumbi remanescente) na fixação dos critérios acima.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-13T20:12:19+0000
**Data conclusão**: 2026-09-13T20:23:22+0000
**Branch**: feat/producao-material-mnemora-studio
**Commit SHA**: 2f901ee
**Jira**: KAN-94
**Implementado por**: developer
**Revisado por**: code-reviewer (gate 1-7, wave 2 — mutation testing próprio: 1 MiB + controle negativo)
**Tentativas**: 1
**Cobertura final**: n/a (integração 2/2 verde)
**Arquivos modificados**:
  - mnemonicos-backend/src/modules/visual-associations/visual-association-storage.ts
  - mnemonicos-backend/tests/integration/visual-association-storage.integration.test.ts

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [ ] Segurança (gate 8): n/a — camada de storage sem decisão de autorização (delegada ao chamador, COMP-023-005)
- [ ] Comportamento (gate 9): n/a — sem efeito observável de tela

**Notas**: comentário de fixture corrigido pós-review ("prefixo de PNG", não "PNG de 1x1");
gotcha Prisma 7 `Bytes`/`Buffer` documentado em `guidelines/project/backend/node-22.md` §11.

**Notas**:
