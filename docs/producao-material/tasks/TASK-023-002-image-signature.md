# TASK-023-002: `image-signature.ts` — detecção de assinatura de bytes

**Slug**: producao-material
**Pertence a**: PLAN-023
**Realiza (FRs)**: FR-022-001, FR-022-002
**Funcionalidade**: FEAT-022-001 (primária)
**Componente**: COMP-023-002 (principal)
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

**FATIA SENSÍVEL (princípio 8)**: `security-engineer` focado nesta TASK, mesmo sendo função
pura sem I/O — é o controle central de NFR-022-001/NFR-022-002 (mitigação de XSS/XXE por
upload sem sanitização, A02/A08 do OWASP citados na SPEC).

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-mnemora-studio` (branch do EPICO MNEMORA STUDIO, Estrategia unica -- decisao 4.126: F5 e uma fatia do epico, nunca abre branch propria; a sessao ja fez o sync de largada nela)

**Padrão de commit**: Conventional Commits (`feat:`).
**Framework de teste**: Jest 30 + ts-jest (`npm --prefix mnemonicos-backend test`).

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-023-008

## Contexto

Fronteira de segurança do upload (COMP-023-002 do PLAN §3): detecta o formato raster real de
um `Buffer` pelos primeiros bytes (magic number), nunca por extensão de nome nem
`Content-Type` declarado pelo cliente — a assinatura da própria função (`buffer: Buffer`
como único parâmetro) já é a prova estrutural de NFR-022-001. Pura, sem I/O, mesmo espírito
de `buildInitialFrames`/`decideStageTransition` (testável sem mocks). Consumida por
COMP-023-005 (`visual-associations.service.ts`) e pela rota de entrega do binário
(COMP-023-006) em TASKs futuras, fora desta lista.

## Escopo

### Inclui

- `mnemonicos-backend/src/modules/visual-associations/image-signature.ts` (novo arquivo,
  sem sufixo `.schema/.service/.routes` — função pura, mesmo tratamento de
  `production-events.service.ts` para módulo sem rota/schema, ainda que aqui nem sequer
  seja `.service.ts` por não ter I/O nenhum):
  - `export type RasterImageFormat = 'PNG' | 'JPEG' | 'WEBP';`
  - `export function detectImageSignature(buffer: Buffer): RasterImageFormat | null;` — PNG
    (bytes `89 50 4E 47`), JPEG (bytes `FF D8 FF`), WebP (bytes `52 49 46 46` nos 4
    primeiros + `57 45 42 50` no offset 8); `null` para qualquer outra coisa, inclusive SVG
    textual (cujos bytes iniciais nunca casam nenhuma assinatura raster).
  - `export function extensionForFormat(format: RasterImageFormat): '.png' | '.jpg' |
    '.webp';`
  - `export function mimeTypeForFormat(format: RasterImageFormat): 'image/png' |
    'image/jpeg' | 'image/webp';`
- `mnemonicos-backend/tests/unit/image-signature.test.ts` (novo): tabela de casos —
  - PNG/JPEG/WebP válidos (assinatura exata, incluindo o offset 8 do WebP).
  - SVG renomeado `.png` (buffer de texto `<?xml version="1.0"?><svg ...>`) — caso citado
    literalmente em AC-022-002.
  - Arquivo truncado — buffer com menos bytes que o magic number mais longo (WebP exige 12
    bytes; ex.: `Buffer.from([0x89, 0x50])`), sem lançar exceção.
  - `extensionForFormat`/`mimeTypeForFormat` exercitados para os 3 formatos.

### Não inclui

- Chamada a este módulo a partir de rota/service (COMP-023-005/COMP-023-006, fora desta
  lista).
- Persistência do binário (`visual-association-storage.ts`, TASK-023-006).

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Criar `image-signature.ts` com os 3 exports, checando o comprimento do buffer antes de
   acessar qualquer byte (evita `RangeError` no caso truncado).
2. Escrever a tabela de casos de `image-signature.test.ts`: 1 por formato válido, 1 SVG, 1
   truncado, 3 de `extensionForFormat`/`mimeTypeForFormat`.

## Critérios de pronto

- [ ] **AC-022-001** (FR-022-001, NFR-022-001, gate 1) — PNG/JPEG/WebP com assinatura de
      bytes válida são aceitos e o formato certo é devolvido. Verificação executável: `npm
      --prefix mnemonicos-backend test -- image-signature` → `Tests: ≥3 passed` (1 caso por
      formato), cada um afirmando `detectImageSignature(buffer) === 'PNG' | 'JPEG' |
      'WEBP'`. Fixada antes do código.
- [ ] **AC-022-002** (FR-022-002, NFR-022-001, NFR-022-002, gate 1) — arquivo cuja
      assinatura de bytes não corresponde a nenhum formato raster — incluindo o caso
      literal do AC, "SVG renomeado .png" — devolve `null`. Verificação executável: mesmo
      comando, caso com buffer de conteúdo SVG textual afirmando `detectImageSignature
      (buffer) === null`. Falsificável: qualquer heurística que dependesse de nome de
      arquivo ou `Content-Type` (nenhum dos dois é parâmetro da função) faria este caso
      divergir de um SVG genuinamente `.svg` sem alterar o resultado esperado — a própria
      assinatura de tipo já garante a ausência desses parâmetros.
- [ ] Arquivo truncado (menos bytes que o magic number mais longo, WebP) devolve `null`,
      sem lançar exceção — caso próprio, mesmo comando. Falsificável: acesso a byte fora do
      índice do buffer sem checagem prévia de comprimento lançaria `RangeError` em vez de
      devolver `null`, e o teste (`expect(() => detectImageSignature(truncated)).not.toThrow()`
      + `expect(detectImageSignature(truncated)).toBeNull()`) capturaria isso.
- [ ] `extensionForFormat`/`mimeTypeForFormat` exercitados para os 3 formatos com valor
      não-nulo — item do Inclui sem AC isolado, oráculo é o contrato do próprio item.
      Verificação executável: mesmo comando, 3 casos afirmando o par exato
      (`'.png'`/`'image/png'`, `'.jpg'`/`'image/jpeg'`, `'.webp'`/`'image/webp'`).
- [ ] Sem warnings/lints novos (sobre todos os arquivos do diff, `git diff --name-only
      main...HEAD`).
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem.
- [ ] Code review aprovado.

## Riscos específicos

- Fatia sensível: mesmo sem I/O, este arquivo é o único controle server-side contra upload
  de SVG/vetor (XSS/XXE, A02/A08) — `security-engineer` revisa o diff completo desta TASK.
- Nenhuma lição ativa de `guidelines/project/lessons.md` nomeia `image-signature.ts` ou o
  padrão que ele encarna (confirmado por leitura) além do espírito geral de função pura
  testável sem mock, já citado no PLAN.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**:
**Data conclusão**:
**Branch**:
**Commit SHA**:
**Jira**: KAN-90
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
