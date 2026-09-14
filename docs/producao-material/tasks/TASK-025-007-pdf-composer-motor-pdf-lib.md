# TASK-025-007: pdf-composer.ts — motor pdf-lib (buildSummaryPdf + buildStripPdf)

**Slug**: producao-material
**Pertence a**: PLAN-025
**Realiza (FRs)**: FR-024-001, FR-024-003, FR-024-004, FR-024-005, FR-024-009, FR-024-014, FR-024-016
**Componente**: COMP-025-003 (principal)
**Wave**: 2
**Tamanho estimado**: medium
**Tipo**: feature
**Status**: Done

## Dependências

- **Depende de**: TASK-025-004, TASK-025-002
- **Bloqueia**: TASK-025-008

## Contexto

Motor de composição do PDF (COMP-025-003, DEC-025-001 — biblioteca `pdf-lib`) —
`buildSummaryPdf`/`buildStripPdf` desenham por coordenada (texto/imagem), sem
template/HTML e sem I/O de rede, eliminando por construção as duas superfícies que
NFR-024-001/002 pedem para mitigar. Ver PLAN-025 §3 (COMP-025-003) e §6 (DEC-025-001);
`pdf-layout.ts` (TASK-025-004, `wrapTextToLines`) já entregue como dependência.

## Escopo

### Inclui

- `npm install pdf-lib` no `mnemonicos-backend` (dependência nova, DEC-025-001) — supply
  chain de 1ª classe (TRISK-025-002): `npm audit`/gate 8 sobre ela é critério de pronto
  desta TASK.
- `mnemonicos-backend/src/modules/publication/pdf-composer.ts` (novo arquivo):
  - `export interface PublicationPdfMeta { variant: PublicationVariant; generatedAt:
    Date }` e `export interface StripFrameForPdf { text: string; image: { buffer:
    Buffer; format: 'PNG' | 'JPEG' } | null }` — texto exato da Interface pública de
    COMP-025-003 no PLAN-025 §3.
  - `buildSummaryPdf(breakdown, meta): Promise<Buffer>` — texto corrido na ordem
    `CANONICAL_RULE_BREAKDOWN_ORDER` (importada de `tira.service.ts`, TASK-025-005 —
    nunca reduplicada, mesma lição [DRY] de DEC-025-003), Blocos vazios (`null`/`''`)
    pulados, mais a Síntese (`essence`) ao final.
  - `buildStripPdf(frames, meta): Promise<Buffer>` — 1 página por `StripFrameForPdf`, na
    ORDEM RECEBIDA (nunca reordenada); `frame.image === null` → só texto;
    `frame.image !== null` → `embedJpg`/`embedPng` conforme `format`. O `try/catch` de
    decodificação é escopado SÓ a essa chamada de embed de CADA Quadro: qualquer exceção
    lançada por `embedJpg`/`embedPng` (buffer corrompido/irrenderizável) é CAPTURADA por
    Quadro e cai no MESMO caminho "só texto" daquele Quadro — nunca propaga para fora de
    `buildStripPdf` nem descarta o documento inteiro (FR-024-014/AC-024-016). Uma
    exceção de `page.drawText(...)` (ex.: caractere fora de WinAnsi, TRISK-025-007) NÃO
    é capturada por esse mesmo bloco — propaga para fora de `buildStripPdf`/
    `buildSummaryPdf` (FR-024-009: falha do documento como um todo é distinta da falha
    isolada de 1 Associação visual de FR-024-014).
  - Rótulo de rascunho + `meta.generatedAt` desenhados via `page.drawText(...)` em TODA
    página recém-criada — a função que desenha roda por página, chamada tanto no laço de
    `buildStripPdf` quanto (1 vez) em `buildSummaryPdf`, nunca só na 1ª página.
  - Todo texto do usuário (Blocos da Quebra, texto de Quadro) desenhado via
    `page.drawText(...)` LITERAL — nenhuma interpolação de template/marcação em nenhum
    caminho (NFR-024-002 por construção: não existe camada de template entre o dado e a
    página).
  - Nenhuma chamada de rede em nenhum caminho do arquivo (NFR-024-001) — nenhum
    `fetch`/`axios`/`XMLHttpRequest`/`WebSocket`/`require('http'|'https'|'net'|'dns')`
    no arquivo inteiro.
  - Imagem usada exatamente como recebida — `frame.image.buffer` passado a
    `embedJpg`/`embedPng` sem nenhuma cópia/transformação prévia (sem `sharp`, `jimp`,
    `resize`, recompressão) — NFR-024-004.
- `mnemonicos-backend/tests/unit/pdf-composer.test.ts` (novo) — ver Critérios de pronto
  (define os casos e as fixtures de imagem que este arquivo precisa).

### Não inclui

- Leitura do banco (`RuleBreakdown`, `MnemonicFrameDetail`, binário de
  `VisualAssociation`) — orquestrado por `publication.service.ts` (TASK-025-008).
- Geração de nome de arquivo (TASK-025-008).
- Wrapper de timeout / `Promise.race` (TASK-025-008).
- Mapeamento de `WEBP`/formato indetectável para `image: null` — decisão de
  `publication.service.ts` (TASK-025-008, antes de chamar `buildStripPdf`);
  `pdf-composer.ts` só recebe `format: 'PNG' | 'JPEG'` ou `image: null`, nunca
  `'WEBP'` como valor de `format`.

## Critérios de pronto

- [ ] Dependência nova `pdf-lib` sem vulnerabilidade conhecida não mitigada — gate 8
      (`npm audit --prefix mnemonicos-backend`, ou o comando de auditoria declarado na
      ficha) roda sobre o `package-lock.json` atualizado, sem achado alto/crítico não
      mitigado; revisão de `security-engineer` (TRISK-025-002, item do Inclui "npm
      install pdf-lib"). Item do PLAN §9 (DoD).
- [ ] **Fixtures de imagem** (pré-condição dos itens abaixo, não um AC isolado): os
      stubs já existentes no repo (`PNG_FIXTURE_BUFFER` de
      `tests/support/visual-association-fixtures.ts`, `JPEG_FIXTURE` de
      `visual-associations.routes.integration.test.ts:39`) são só prefixo de assinatura
      de bytes, sem `IDAT`/`IEND` nem payload JPEG completo — confirmado por leitura
      direta (decisão 4.307): passá-los a `embedPng`/`embedJpg` do `pdf-lib` LANÇA
      (úteis, ao contrário, como fixture do caso "falha de decodificação" abaixo). Este
      arquivo cria 2 fixtures NOVAS, mínimas e REALMENTE decodíveis (1 PNG 1×1 válido, 1
      JPEG 1×1 válido) — só para `pdf-composer.test.ts`.
- [ ] **AC-024-002** (FR-024-003, gate 1) — `buildSummaryPdf` com uma Quebra cujos Blocos
      `condition`/`exception` são `null`: o texto extraído do PDF gerado (técnica
      descrita abaixo) contém `concept`/`action`/`object`/`essence`, na ordem relativa
      CONCEITO→AÇÃO→OBJETO→(CONDIÇÃO e EXCEÇÃO pulados)→SÍNTESE, e NÃO contém nenhum
      marcador dos 2 Blocos vazios; nenhuma página tem diagramação de Quadro (documento
      de texto corrido, não 1-Quadro-por-página). Verificação executável: `npm --prefix
      mnemonicos-backend test -- pdf-composer` → `OK (N tests)`. Fixada antes do código.
- [ ] **AC-024-003**/**AC-024-020** (FR-024-004/005/016, gate 1) — `buildStripPdf` com N
      `StripFrameForPdf` (N ≥ 3), alguns com `image` válida (PNG/JPEG real de fixture),
      outros com `image: null`: o PDF gerado tem EXATAMENTE N páginas
      (`PDFDocument.load(buffer).getPageCount() === N`), na ORDEM recebida, cada página
      com o texto do Quadro correspondente; página cujo `image !== null` embute a
      imagem, página cujo `image === null` só tem texto — sem bloquear a geração por
      nenhum Quadro sem imagem. Mesmo comando.
- [ ] **AC-024-016** (FR-024-014, gate 1) — `StripFrameForPdf` com `image: { buffer:
      <buffer corrompido — ex.: os stubs truncados citados no item de fixtures acima>,
      format: 'PNG' | 'JPEG' }`: `buildStripPdf` NÃO lança, a exportação conclui com
      `Buffer` válido, e a página desse Quadro cai no MESMO caminho "só texto" de um
      Quadro sem `image`. Mutante que remove o `try/catch` ao redor de
      `embedJpg`/`embedPng` faz este caso reprovar (a exceção propagaria e derrubaria o
      documento inteiro). Mesmo comando.
- [ ] Exceção de `page.drawText(...)` (caractere fora de WinAnsi, ex. emoji) sobre o
      texto PRINCIPAL de um Bloco/Quadro NÃO é engolida pelo `try/catch` de imagem —
      `buildStripPdf`/`buildSummaryPdf` REJEITAM (propagam), nunca devolvem um `Buffer`
      parcial. Mesmo comando.
- [ ] **AC-024-005** (FR-024-001, gate 1) — para um PDF de N páginas (`buildStripPdf`
      com N ≥ 2 Quadros, e separadamente `buildSummaryPdf`), o rótulo textual de
      rascunho aparece em TODAS as N páginas (busca do texto do rótulo em cada página
      individualmente, nunca só na 1ª — mutante que move o `drawText` do rótulo para
      fora do laço por página reprova), e ao menos uma página exibe `meta.generatedAt`
      formatada, rotulada como geração/rascunho, nunca como data de fechamento de
      legislação (nenhum texto tipo "fechamento"/"aprovação" no documento). Mesmo
      comando.
- [ ] **AC-024-010** (NFR-024-001, NFR-024-002, gate 1) — postura de segurança do motor,
      provada, não só declarada (2 provas no mesmo teste):
      (a) ESTRUTURAL — universo de busca = `pdf-composer.ts` inteiro, linhas de
      comentário excluídas (item b da régua de contorno, decisão 4.161): `grep -vE
      '^\s*(\*|//)' mnemonicos-backend/src/modules/publication/pdf-composer.ts | grep
      -inE 'fetch\(|axios|XMLHttpRequest|new WebSocket|require\([^)]*(http|https|net|dns)|from
      [\x27"](http|https|net|dns)'` → 0 linhas (nenhuma ocorrência de identificador de
      rede fora de comentário).
      (b) COMPORTAMENTAL — `buildSummaryPdf`/`buildStripPdf` chamados com um texto
      "hostil" no Bloco/Quadro (ex.: `'{{ 7 * 7 }}'` e `'<%= 7*7 %>'`, sequências que se
      pareceriam com diretiva de template/marcação): o texto sai LITERAL no PDF gerado
      (busca binária pela string exata — técnica abaixo), NUNCA interpretado/avaliado
      (o PDF nunca contém `'49'` no lugar da expressão); e
      `jest.spyOn(global, 'fetch').mockImplementation(() => { throw new Error('rede
      chamada'); })` permanece `not.toHaveBeenCalled()` durante as duas chamadas. Mesmo
      comando.
      **Técnica de extração de texto** (documentada aqui, não repetida a cada item
      acima): `pdf-lib` desenha texto via operador `Tj`/`TJ` de PDF sem comprimir o
      content stream por padrão — o `Buffer` final, lido como `latin1`, contém a string
      literal entre parênteses do operador (`(<texto>) Tj`); a asserção busca a
      substring exata (ou a sequência de bytes WinAnsi correspondente) em
      `buffer.toString('latin1')`. Sem parser de PDF externo, sem dependência nova além
      de `pdf-lib`.
- [ ] **AC-024-011** (NFR-024-004, gate 1) — imagem usada exatamente como recebida, 2
      provas (JPEG e PNG divergem no comportamento interno do `pdf-lib`, cada formato
      exige a prova que de fato o alcança):
      - JPEG: `embedJpg` preserva o payload `DCTDecode` original sem re-encoding —
        depois de `buildStripPdf`, recarregar o PDF (`PDFDocument.load`) e localizar o
        stream do XObject de imagem embutida (filtro `DCTDecode`) —
        `Buffer.compare(<stream extraído>, <JPEG de fixture original>) === 0` (mesmo
        padrão de `visual-associations.routes.integration.test.ts:1137-1154`,
        `Buffer.compare` byte-a-byte, confirmado por leitura direta como
        molde/exemplar — decisão 4.307).
      - PNG: `pdf-lib` decodifica e reconstrói o XObject internamente (sem garantia de
        byte-igualdade do stream interno) — a prova aqui é de AUSÊNCIA de
        redimensionamento: a imagem embutida (`PDFImage.width`/`.height`, devolvida por
        `pdfDoc.embedPng(buffer)`) tem as MESMAS dimensões intrínsecas do PNG de
        fixture (lidas do cabeçalho `IHDR`, bytes 16-23 big-endian do PRÓPRIO buffer de
        fixture no teste — nunca um valor hardcoded, para não coincidir por acaso), e
        nenhuma chamada a `sharp`/`jimp`/qualquer redimensionamento aparece no arquivo
        (mesmo grep estrutural do item de segurança acima, padrão estendido a
        `sharp|jimp`).
      Falsificável: qualquer recompressão/redimensionamento (ex.: `sharp(buffer).resize(...)`
      antes do `embedPng`) faria a comparação JPEG divergir de `0` ou as dimensões do
      PNG divergirem do `IHDR` de fixture. Mesmo comando.
- [ ] Contrato do próprio item (sem AC isolado): `buildSummaryPdf`/`buildStripPdf`
      devolvem o `Buffer` só ao final, via `PDFDocument.save()` — nenhum `write`/I/O
      parcial no meio da função (verificação estrutural: nenhuma chamada a
      `fs`/`stream`/`res.write` no arquivo — mesmo grep de rede acima, padrão estendido
      a `\bfs\.|createWriteStream`).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git diff --name-only
      main...HEAD`), produção e teste — `npm --prefix mnemonicos-backend run lint` →
      exit 0.

## Riscos específicos

- TRISK-025-002 (dependência nova `pdf-lib`, supply chain A03) — gate 8 (`npm audit`)
  cobre.
- TRISK-025-006 (`WEBP` nunca chega a este arquivo — mapeado para `image: null` em
  TASK-025-008; se essa fronteira mudar, revisitar o item correspondente do "Não
  inclui").
- TRISK-025-007 (fontes padrão do `pdf-lib`, WinAnsi/cp1252, não cobrem caractere fora
  de Latin-1 — `drawText` lança) — tratado como falha da geração inteira (item de
  Critérios acima), sem sanitização de charset nesta TASK (aceito pelo PLAN).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-14T16:25:23-0300
**Data conclusão**: 2026-09-14T18:24:06-0300
**Commit SHA**: b52d131 (implementação) · 4d06303 (gate 8 ALTA: teto de pixels/APNG) · f7d2511 (gate 1/7: F1-F4) · df7a706 (gate 8: bypass IHDR offset) · d39c674 (gate 7: F5 APNG substring) · 0f3ab64 (gate 8: unificação walkPngChunks, fecha 3º bypass IHDR duplicado) · 45d02aa (gate 7: dedup de fixtures de teste)
**Jira**: KAN-114

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado (Wave 2 — 3 rodadas de retry: F1-F4 gate 1/7, F5 gate 7, dedup de fixtures gate 7; convergiu e APROVADO)
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 2 — 3 rodadas de retry: teto de pixels/APNG ausente, bypass por decoy antes do IHDR, bypass por IHDR duplicado/last-wins; fechado com refatoração estrutural de leitura de chunk PNG unificada)
- [x] Comportamento (gate 9): consolidado (DoD, Etapa 4) — SPEC-024 sem FEATs
