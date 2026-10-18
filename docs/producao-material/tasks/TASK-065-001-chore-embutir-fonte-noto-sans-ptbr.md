# TASK-065-001: Embutir a fonte Noto Sans (pt-BR) e o extrator de texto de fonte embutida

**Slug**: producao-material
**Pertence a**: PLAN-065
**Realiza (FRs)**: FR-064-011
**Funcionalidade**: FEAT-064-002 (primária)
**Componente**: COMP-065-004 (principal)
**Wave**: 1
**Tamanho estimado**: medium
**Tipo**: chore
**Status**: Done

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-065-005, TASK-065-006

## Contexto

Prepara o documento `pdf-lib` para desenhar português completo (acentos, travessão, aspas curvas) com fonte TrueType embutida via `@pdf-lib/fontkit`, em vez da Helvetica/WinAnsi do rascunho, e cria o extrator de teste que lê esse texto de volta (o `decodedPageTexts` de `tests/support/pdf-text.ts:101` só decodifica hex WinAnsi e não enxerga texto em fonte Identity-H). É setup de supply chain (dependência nova, asset OFL) que o compositor final (TASK-065-006) consome. Território e decisões: PLAN-065 COMP-065-004, DEC-065-003, TRISK-065-003 e TRISK-065-011; memo e `MAP.md` do slug.

**Raiz de execução**: os comandos rodam a partir de `Mnemonico/kan237/`, que contém `mnemonicos-backend/` e `mnemonicos-frontend/` (worktrees da branch do épico) e `docs/` (symlink para o workspace); os paths `mnemonicos-backend/…`, `mnemonicos-frontend/…` e `docs/…` desta TASK resolvem a partir dela.

## Escopo

### Inclui
- `mnemonicos-backend/package.json` e `mnemonicos-backend/package-lock.json`: `@pdf-lib/fontkit` em versão EXATA (sem `^`/`~`, perfil node-22 §8), lock commitado.
- `mnemonicos-backend/scripts/build-font-modules.mjs` (script gerador versionado, só Node, determinístico) e as fontes-fonte já reduzidas e versionadas em `mnemonicos-backend/scripts/font-sources/` (Basic Latin, Latin-1, Latin Extended-A e pontuação geral: travessão, aspas curvas, reticências, euro).
- Módulos gerados `mnemonicos-backend/src/modules/publication/fonts/noto-sans-regular.ts` (`NOTO_SANS_REGULAR_BASE64`) e `mnemonicos-backend/src/modules/publication/fonts/noto-sans-bold.ts` (`NOTO_SANS_BOLD_BASE64`), mais `fonts/OFL.txt` e `fonts/NOTICE.md` (origem, versão e conjunto de caracteres da fonte).
- `mnemonicos-backend/eslint.config.mjs` e `mnemonicos-backend/.prettierignore`: os módulos gerados ficam fora de lint e de format, e o `scripts/build-font-modules.mjs` não quebra o `eslint .` (o `projectService` só enxerga o `tsconfig.json`, que não inclui `scripts/**`; mesmo motivo de `eslint.config.mjs` constar em `allowDefaultProject`, eslint.config.mjs:18 — o developer escolhe entre ignorar o script ou listá-lo em `allowDefaultProject`, conforme o que o `lint` real aceitar).
- `mnemonicos-backend/src/modules/publication/final-pdf-font.ts`: `embedFinalFonts` (`registerFontkit` + `embedFont` com `subset: true`), `FinalFonts` e `sanitizeForFont`.
- `mnemonicos-backend/tests/unit/final-pdf-font.test.ts` e `mnemonicos-backend/tests/support/pdf-embedded-text.ts` (`decodedEmbeddedPageTexts(doc): string[]`: decodifica texto Identity-H pelo ToUnicode CMap, uma string por página).
- `mnemonicos-backend/tests/support/pdf-text.ts`: único ponto tocado é exportar `decodedPageContent` (hoje não exportada, :64); `decodedEmbeddedPageTexts` a reusa em vez de reimplementar a leitura de content stream (DRY).

### Não inclui
- Layout e compositor do PDF final (TASK-065-006).
- Leitura da fonte do disco em tempo de execução: DEC-065-003 manda o binário entrar como módulo `.ts` (`import` normal), sem depender de file tracing da Vercel.
- Tradução de caracteres fora do latino: viram `?` por `sanitizeForFont`, sem transliteração.
- Medição de bundle, parse e cold start na Vercel (gate 10 e deploy de preview) e qualquer mudança em `mnemonicos-backend/vercel.json` (lição `config-de-plataforma-de-deploy-s-prova-o-que-fica-p-blico-ap-s-o-deploy-real`: config de plataforma só se prova no deploy real, e esta TASK não a toca).

## Critérios de pronto

- [ ] Dependência nova fixada em versão exata e com lock commitado (gate 8, TRISK-065-011) — verificação executável: `grep -cE '^ +"@pdf-lib/fontkit": "[0-9]+\.[0-9]+\.[0-9]+",?' mnemonicos-backend/package.json` → `1` (e `0` no commit-pai, onde a dependência não existe); `npm --prefix mnemonicos-backend ls @pdf-lib/fontkit` → exit 0 com a mesma versão; `git -C mnemonicos-backend diff --name-only <SHA-pai-da-TASK>..HEAD -- package.json package-lock.json` → exatamente 2 linhas (`package.json`, `package-lock.json`). Falha se a versão vier com `^`/`~` ou se o lock não for commitado.
- [ ] Sem vulnerabilidade `high`/`critical` nova no grafo de produção (gate 8) — verificação executável: `npm --prefix mnemonicos-backend audit --omit=dev --audit-level=high` → exit 0; se o baseline do developer já sair diferente de 0, o critério vira "mesmo conjunto de achados do baseline, nenhum novo", com a saída do baseline anexada ao commit.
- [ ] AC-064-009 (parte nível fonte — acentos, travessão e aspas curvas embutidos e recuperados íntegros; a faceta "texto de Quadro dentro do PDF final" é do gate 1 da TASK-065-006) — verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/final-pdf-font.test.ts` → `OK (N tests)`, N > 0, com o caso de ida e volta: `embedFinalFonts` num `PDFDocument`, desenhar `Ação — “quadro” ‘x’ … ç ã õ é ü` e o alfabeto acentuado completo (minúsculas e maiúsculas de á à â ã ä é è ê ë í ì î ï ó ò ô õ ö ú ù û ü ç ñ), `save()`, `PDFDocument.load`, e `decodedEmbeddedPageTexts(doc)` devolve exatamente o texto de entrada, por página, com `toEqual` do valor completo. A geração conclui sem exceção. Falha se o glifo faltar, se o `?` substituir um acento ou se a fonte não for embutida (o texto sairia ilegível na decodificação).
- [ ] O extrator de texto embutido tem controle positivo e negativo próprios (lição `extrator-textual-de-c-digo-para-prova-estrutural-precisa-de-controle-positivo-obrigat-rio-e-o-conserto-precisa-varrer-a-classe-ast-n-o-s-a-inst-ncia-que-quebrou`) — verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/final-pdf-font.test.ts` → `OK (N tests)`, N > 0; o arquivo cobre: (1) positivo: o MESMO helper acha um texto conhecido desenhado no documento do teste; (2) negativo: um texto que não foi desenhado não é achado; (3) o helper devolve uma string por página (documento de 2 páginas com textos distintos → 2 strings, cada uma com o seu texto e sem o da outra). Mutante em worktree (`git -C mnemonicos-backend worktree add <TMP>/mnemonicos-backend HEAD`; a árvore principal nunca é editada): `decodedEmbeddedPageTexts` devolvendo `[]` ou string vazia → os casos (1) e (3) saem vermelhos (sem controle positivo, o "não achei nada" de uma prova de ausência seria vazio verde).
- [ ] `sanitizeForFont` troca só o que não tem glifo, com um mutante por classe de caractere — verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/final-pdf-font.test.ts` → `OK (N tests)`, com um teste por classe: (a) nenhum acento latino é trocado, (b) `—` (travessão) não é trocado, (c) `“ ” ‘ ’` não são trocados, (d) um caractere CJK vira `?` e o texto em volta fica intacto; `FinalFonts.hasGlyph('ç')` é `true` e `hasGlyph('漢')` é `false`. Mutantes em worktree, um por classe: trocar acento por `?` → (a) vermelho; trocar `—` → (b) vermelho; trocar aspas curvas → (c) vermelho; não trocar CJK → (d) vermelho.
- [ ] Subset ligado (TRISK-065-003) — verificação executável: `npm --prefix mnemonicos-backend test -- tests/unit/final-pdf-font.test.ts` → `OK (N tests)`, N > 0; o arquivo cobre: o `byteLength` do PDF salvo com `embedFinalFonts` e uma linha desenhada é menor que o do documento de referência com a mesma fonte embutida sem subset, e menor que N bytes (N fixado pelo developer no baseline, a metade do tamanho sem subset). Mutante em worktree: `subset: false` em `final-pdf-font.ts` → vermelho.
- [ ] Os módulos gerados são reproduzíveis (idempotência; `scripts/**` está fora do `tsconfig.json`, então o oráculo é a regeneração, não o typecheck) — verificação executável: depois do commit dos módulos, `node mnemonicos-backend/scripts/build-font-modules.mjs` e então `git -C mnemonicos-backend status --porcelain -- src/modules/publication/fonts` → saída vazia. Controle: alterar um byte de `noto-sans-regular.ts` torna a saída não vazia, e rodar o script de novo a zera; `git -C mnemonicos-backend ls-files -- src/modules/publication/fonts` → lista os 4 arquivos (`noto-sans-regular.ts`, `noto-sans-bold.ts`, `OFL.txt`, `NOTICE.md`).
- [ ] Licença e origem da fonte no repositório (gate 8) — verificação executável: `grep -c '^SIL OPEN FONT LICENSE' mnemonicos-backend/src/modules/publication/fonts/OFL.txt` → ao menos `1`; `grep -cE '^(Origem|Versão|Conjunto de caracteres): ' mnemonicos-backend/src/modules/publication/fonts/NOTICE.md` → `3`.
- [ ] Os módulos gerados e o script convivem com lint e format — verificação executável: `npm --prefix mnemonicos-backend run lint` → exit 0 e `npm --prefix mnemonicos-backend run format:check` → exit 0, com os módulos, o script e as fontes presentes (lição `entrega-roda-format-check-nos-arquivos-tocados-alem-de-lint-e-jest`: o `format:check` roda além de eslint, tsc e jest); `npm --prefix mnemonicos-backend run typecheck` → exit 0.
- [ ] O helper de teste tem uma definição só (lição `corre-o-de-duplica-o-dry-introduz-nova-re-deriva-o-do-can-nico-no-mesmo-diff`) — verificação executável: `git -C mnemonicos-backend diff --name-only --diff-filter=AM <SHA-pai-da-TASK>..HEAD -- tests | xargs git -C mnemonicos-backend grep -l -E '^(export )?(async )?function decodedEmbeddedPageTexts'` → exatamente `tests/support/pdf-embedded-text.ts` e nenhum outro (condição sobre o universo real do diff, não lista nominal).
- [ ] A superfície pública é a do manifesto, não a transcrição do PLAN (lição `lista-de-interface-p-blica-do-plan-contrato-m-nimo-n-o-gabarito-de-transcri-o`) — verificação executável: `git -C mnemonicos-backend grep -n -E '^export ' -- src/modules/publication/final-pdf-font.ts` → exatamente `embedFinalFonts`, `FinalFonts` e `sanitizeForFont`, e o teste de `FinalFonts` acima exercita `regular`, `bold` (ambos embutidos, nomes distintos) e `hasGlyph` com valor não nulo.
- [ ] Escopo respeitado — verificação executável: `git -C mnemonicos-backend diff --name-only <SHA-pai-da-TASK>..HEAD -- vercel.json src/modules/publication/pdf-composer.ts src/modules/publication/publication.service.ts` → vazio (os três existem no commit-pai, então o vazio é possível e prova que esta TASK não toca plataforma, rascunho nem serviço).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git -C mnemonicos-backend diff --name-only main...HEAD`), produção e teste.

## Riscos específicos

- O módulo base64 de duas fontes aumenta o bundle e o parse da função (TRISK-065-003): a redução do conjunto de caracteres e o `subset: true` são a mitigação; o número real só sai no gate 10 e no deploy de preview.
- `@pdf-lib/fontkit` não recebe release há anos (a série 1.1.x, como o próprio `pdf-lib`): versão exata, lock commitado e `npm audit` são o controle; a licença da Noto Sans é SIL OFL 1.1 e o texto vai no repositório.
- O reaproveitamento da leitura de content stream de `tests/support/pdf-text.ts` (`decodedPageContent`, :64) está decidido: o arquivo entra no `Inclui` só para exportar essa função, e `decodedEmbeddedPageTexts` a reusa (uma definição só, lição de DRY).
- Gate 8 (supply chain). Gate 9: n/a — sem tela nem fluxo observável pelo usuário.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-10-18T02:48:17-0300
**Data conclusão**: 2026-10-18T08:09:20-03:00
**Commit SHA**: 16a2f38
**Jira**: KAN-261

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 1)
- [x] Comportamento (gate 9): consolidado (FEAT-064-002)
<!-- Branch, tentativas, arquivos, revisores e narrativa (retries, escalações) vivem no
ledger da sessão e no commit da closure (4.76) — não se repetem aqui (4.409). -->
