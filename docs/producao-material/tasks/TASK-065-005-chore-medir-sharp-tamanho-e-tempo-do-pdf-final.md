# TASK-065-005: Medir sharp, tamanho e tempo do PDF final

**Slug**: producao-material
**Pertence a**: PLAN-065
**Realiza (FRs)**: nenhuma
**Componente**: COMP-065-003 (principal), COMP-065-004
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Done

## Dependências

- **Depende de**: TASK-065-001
- **Bloqueia**: TASK-065-008

## Contexto

Mede, antes da implementação da conversão WEBP→PNG, os números com incerteza do PLAN-065 que nunca foram medidos: o inchaço do PNG sobre o WEBP de origem, o tempo de conversão por resolução, o pico de memória ao converter M Quadros, o tamanho e o tempo de um PDF de 12 páginas com fonte embutida, e o M máximo de Quadros dentro do teto de 12 s (TRISK-065-001, TRISK-065-004 e TRISK-065-005, incerteza numérica, princípio 8 do `/keelson:tasks`). O número medido decide se DEC-065-004 e DEC-065-010 se reabrem, confirma ou corrige o teto-default de 4.000.000 bytes e fixa os parâmetros de cache e concorrência do `sharp` que a TASK-065-008 usa. Depende da TASK-065-001 só para medir o custo da fonte embutida (`embedFinalFonts`, TRISK-065-003). Território e decisões: PLAN-065 COMP-065-003, DEC-065-004, DEC-065-010; memo e `MAP.md` do slug.

**Raiz de execução**: os comandos rodam a partir de `Mnemonico/kan237/`, que contém `mnemonicos-backend/` e `mnemonicos-frontend/` (worktrees da branch do épico) e `docs/` (symlink para o workspace); os paths `mnemonicos-backend/…`, `mnemonicos-frontend/…` e `docs/…` desta TASK resolvem a partir dela. O `sharp` só existe no worktree (instalado aqui): os comandos `node -e "require('sharp')…"` rodam com cwd em `mnemonicos-backend` do kan237.

## Escopo

### Inclui
- `mnemonicos-backend/package.json` e `mnemonicos-backend/package-lock.json`: `sharp` em versão EXATA (sem `^`/`~`, perfil node-22 §8), lock commitado.
- `docs/producao-material/medicoes/MEDICAO-065-sharp-pdf.md` (pasta nova do slug): o código da sonda em bloco cercado, o ambiente, os números, a decisão escrita, as licenças e o estado da árvore. A sonda NÃO nasce em `tests/**` nem fica untracked no backend (lição `sonda-de-investiga-o-n-o-nasce-em-tests-contagem-de-teste-declara-a-rvore`): roda por caminho explícito do scratchpad da sessão, resolvendo `sharp`, `pdf-lib` e o módulo de fonte a partir de `mnemonicos-backend` (`createRequire`, ou `tsx` para o `.ts` de fonte).
- Medidas (uma linha-resumo por medida, identificador exato como primeira célula): `razao-png-webp` (tamanho do PNG convertido ÷ tamanho do WEBP de origem, em 3 imagens sintéticas — gradiente, ruído e mista — nas resoluções 1000x667, 2000x1333, 3000x2000 e 5000x4000, esta o limite do orçamento de 20 M px); `ms-conversao` (mediana de 10 conversões por resolução); `pico-rss` (pico de RSS ao converter 12 Quadros 2000x1333 em sequência liberando cada buffer, contra em paralelo); `pdf-12-paginas` (bytes e ms de um PDF de 12 páginas com 12 PNG e as fontes de `embedFinalFonts`); `m-maximo` (maior M de Quadros 3000x2000 dentro de 12 s com margem 2x, ou seja, até 6 s). Linhas de detalhe usam outro prefixo (`| detalhe-<medida>-… |`). Reprodutibilidade das imagens sintéticas: o gerador pseudoaleatório usa semente literal registrada no registro; o conjunto inclui ao menos uma imagem fotográfica ou de textura natural (além de gradiente, ruído e mista); a qualidade do WEBP de origem é registrada; `ms` e `rss` valem como ordem de grandeza, não como valor exato.
- Medidas da redução no modo final (DEC-065-010, linhas-resumo com identificador exato como primeira célula): `pdf-final-reduzido` (tira de referência com M ≥ 8 Quadros, cada um com foto JPEG de cerca de 5 MB e 4000 px: bytes e ms do PDF final depois da redução ao lado maior `RECOMMENDED_LONG_SIDE_PX`), `recompressao` (parâmetros de recompressão/redução do `sharp` adotados: formato de saída, qualidade, `fit`), `sharp-cache` e `sharp-concurrency` (valores de `sharp.cache` e `sharp.concurrency` usados na medição, consumidos pela TASK-065-008).
- Decisão escrita e parâmetros: "Reabrir DEC-065-004 / DEC-065-010? sim/não" com o número que a sustenta; teto-default de `PUBLICATION_FINAL_PDF_MAX_BYTES` (4.000.000) confirmado ou corrigido; parâmetros de cache e concorrência do `sharp` adotados.

### Não inclui
- TRISK-065-002 (binário nativo do `sharp` na função Vercel: tamanho do pacote, cold start, empacotamento): só se prova em deploy de preview e no gate 10, e esta TASK não finge medi-lo localmente (lição `config-de-plataforma-de-deploy-s-prova-o-que-fica-p-blico-ap-s-o-deploy-real`).
- A implementação da conversão WEBP no PDF final (TASK-065-008) e o tempo do compositor real (gate 10).
- Qualquer arquivo em `mnemonicos-backend/src/` ou `mnemonicos-backend/tests/`.

## Critérios de pronto

- [ ] Dependência nova fixada em versão exata e instalável (gate 8, TRISK-065-011) — verificação executável: `grep -cE '^ +"sharp": "[0-9]+\.[0-9]+\.[0-9]+",?' mnemonicos-backend/package.json` → `1` (e `0` no commit-pai); `npm --prefix mnemonicos-backend ls sharp` → exit 0; `git -C mnemonicos-backend diff --name-only <SHA-pai-da-TASK>..HEAD` → exatamente 2 linhas (`package.json`, `package-lock.json`). Falha se a versão vier com `^`/`~` ou se algum arquivo além dos dois entrar no repositório do backend.
- [ ] Smoke do binário nativo no ambiente de testes (TRISK-065-012) — verificação executável: `cd mnemonicos-backend && node -e "require('sharp')"` → exit 0. Falha se o pacote de plataforma opcional (`@img/sharp-*`) não foi instalado.
- [ ] Sem vulnerabilidade `high`/`critical` nova (gate 8) — verificação executável: `npm --prefix mnemonicos-backend audit --omit=dev --audit-level=high` → exit 0; se o baseline do developer já sair diferente de 0, o critério vira "mesmo conjunto de achados do baseline, nenhum novo", com a saída do baseline anexada ao commit.
- [ ] As cinco medidas estão registradas, cada uma com número (não com placeholder) — verificação executável: `grep -cE '^\| (razao-png-webp|ms-conversao|pico-rss|pdf-12-paginas|m-maximo) ' docs/producao-material/medicoes/MEDICAO-065-sharp-pdf.md` → `5` (exatamente uma linha-resumo por medida); `grep -cE '^\| (razao-png-webp|ms-conversao|pico-rss|pdf-12-paginas|m-maximo) \| [^|]*[0-9]' docs/producao-material/medicoes/MEDICAO-065-sharp-pdf.md` → `5` (a célula de valor traz ao menos um dígito). Falha se faltar uma medida ou se a célula de valor ficar vazia.
- [ ] A decisão está escrita e amarrada a um número — verificação executável: `grep -cE '^Decisão: Reabrir DEC-065-004 / DEC-065-010\? (sim|não) — ver (razao-png-webp|ms-conversao|pico-rss|pdf-12-paginas|m-maximo)' docs/producao-material/medicoes/MEDICAO-065-sharp-pdf.md` → `1`; `grep -cE '^Teto-default PUBLICATION_FINAL_PDF_MAX_BYTES: (confirmado em 4000000|corrigido para [0-9]+)' docs/producao-material/medicoes/MEDICAO-065-sharp-pdf.md` → `1`; `grep -cE '^Parâmetros do sharp: .*cache.*concurrency|^Parâmetros do sharp: .*concurrency.*cache' docs/producao-material/medicoes/MEDICAO-065-sharp-pdf.md` → `1` (a TASK-065-008 adota esses parâmetros, não os redescobre).
- [ ] Medição: uma tira de referência com M ≥ 8 Quadros, cada um com foto JPEG de cerca de 5 MB e 4000 px, gera PDF final ≤ 4 000 000 bytes após a redução; o tamanho e o tempo medidos ficam registrados, junto dos parâmetros de recompressão e de `sharp.cache`/`sharp.concurrency` (DEC-065-010). Se não couber, o "Reabrir se" do DEC-065-010 dispara e a decisão volta ao PO antes do código — verificação executável: `grep -cE '^\| pdf-final-reduzido \| [^|]*[0-9]' docs/producao-material/medicoes/MEDICAO-065-sharp-pdf.md` → `1`; `grep -cE '^\| recompressao \| [^|]*[0-9a-zA-Z]' docs/producao-material/medicoes/MEDICAO-065-sharp-pdf.md` → `1`; `grep -cE '^\| sharp-cache \| [^|]*[0-9]' docs/producao-material/medicoes/MEDICAO-065-sharp-pdf.md` → `1`; `grep -cE '^\| sharp-concurrency \| [^|]*[0-9]' docs/producao-material/medicoes/MEDICAO-065-sharp-pdf.md` → `1`; a linha `pdf-final-reduzido` traz o tamanho em bytes e, se for maior que 4000000, a linha `Decisão:` do critério anterior traz `sim`.
- [ ] O registro tem a estrutura que a leitura posterior espera — verificação executável: `grep -cE '^## (Ambiente|Sonda|Medidas|Decisão|Licenças e scripts de instalação|Estado da árvore)' docs/producao-material/medicoes/MEDICAO-065-sharp-pdf.md` → `6`; a seção "Ambiente" traz versão do Node, CPU e sistema operacional da máquina de medição (os números só valem para ela e para a ordem de grandeza).
- [ ] Licenças e scripts de instalação conferidos (gate 8, libvips LGPL-3) — verificação executável: `grep -cE '^(Licença sharp|Licença libvips|Scripts de instalação): ' docs/producao-material/medicoes/MEDICAO-065-sharp-pdf.md` → `3`, com os valores lidos do `package.json` instalado de `sharp` e do pacote de libvips em `node_modules`, não de memória.
- [ ] A sonda é reproduzível a partir do registro e não deixa rastro no repositório (lição `sonda-de-investiga-o-n-o-nasce-em-tests-contagem-de-teste-declara-a-rvore`) — verificação executável: copiar o bloco da seção "Sonda" para um arquivo do scratchpad da sessão e rodá-lo por caminho explícito devolve as mesmas linhas-resumo (mesmos identificadores, `razao-png-webp` idêntica por ser determinística, tempos na mesma ordem de grandeza); `git -C mnemonicos-backend status --porcelain` → vazio depois do commit da TASK, e a saída está colada na seção "Estado da árvore" do registro; `git -C docs status --porcelain -- producao-material/medicoes` → vazio depois do commit.
- [ ] O repositório compila e passa lint e format com a dependência nova — verificação executável: `npm --prefix mnemonicos-backend run lint`, `npm --prefix mnemonicos-backend run format:check` e `npm --prefix mnemonicos-backend run typecheck` → exit 0 (o lock fica fora do format por `.prettierignore`).
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff (`git -C mnemonicos-backend diff --name-only main...HEAD`), produção e teste.

## Riscos específicos

- A máquina de medição não é a função Vercel (1024 MB, 15 s): os números dão ordem de grandeza e a decisão de reabrir ou não; o valor definitivo sai do gate 10 e do deploy de preview.
- A medição de `pico-rss` com `sharp` depende do cache interno da libvips: os parâmetros de cache e concorrência medidos são parte da decisão e entram no registro, porque a TASK-065-008 depende deles.
- Gate 1 sem AC (chore sem FR); gate 8 (supply chain: `sharp`/libvips LGPL-3). Gate 9: n/a — sem tela.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-10-18T08:20:57-0300
**Data conclusão**: 2026-10-18T09:04:58-03:00
**Commit SHA**: a4792d8
**Jira**: KAN-265

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado (wave 2)
- [x] Comportamento (gate 9): n/a — chore de medição sem efeito observável
<!-- Branch, tentativas, arquivos, revisores e narrativa (retries, escalações) vivem no
ledger da sessão e no commit da closure (4.76) — não se repetem aqui (4.409). -->
