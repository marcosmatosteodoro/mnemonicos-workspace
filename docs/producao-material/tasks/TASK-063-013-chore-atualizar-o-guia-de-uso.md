# TASK-063-013: Atualizar o Guia de uso e documentar as pendências de ambiente (CORS do bucket, envs no deploy)

**Slug**: producao-material
**Pertence a**: PLAN-063
**Realiza (FRs)**: nenhuma
**Componente**: COMP-063-009 (principal)
**Wave**: 8
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Todo

## Dependências

- **Depende de**: TASK-063-002, TASK-063-006, TASK-063-011, TASK-063-012
- **Bloqueia**: nenhuma

## Contexto

O Guia de uso (`docs/GUIA-DE-USO.md`) passa a descrever o Acervo de PDFs, os Pacotes, a Ficha e a exportação, diz que o sistema não atesta a revisão jurídica do PDF enviado e registra, para o Diretor, o que falta provisionar fora do código (NFR-061-003, AC-061-028; regra do `CLAUDE.md` do workspace: tela, fluxo, papel ou mensagem visível nova atualiza o guia no mesmo ciclo). É a única TASK do PLAN-063 que toca o guia: as closures das TASKs 005, 006, 009, 011 e 012 registram "guia: TASK-063-013". O texto só afirma o que existe no código nesta wave (último a fechar: 012).

## Escopo

### Inclui
- `docs/GUIA-DE-USO.md`:
  - nova seção `## Vendendo pacotes de PDF, passo a passo`, no estilo de "Produzindo um material, passo a passo", com os passos `### 1. Envie os PDFs ao Acervo`, `### 2. Monte o Pacote` e `### 3. Baixe a Ficha e exporte`. Cobre: enviar (Título, Versão, Data de fechamento legislativo, limite de tamanho), editar, substituir (o arquivo anterior deixa de existir) e remover PDF (só o autor ou um administrador substitui e remove; PDF que está num Pacote não é removido), cadastrar Pacote (preço de referência), compor (adicionar do Acervo com busca, reordenar, remover Item), Ficha e tamanho total, exportar (arquivo compactado só com os PDFs, nomes prefixados pela posição; a exportação só conta depois que o download termina; mensagem "exporte de novo" quando algo falha) e remover Pacote (o registro das exportações fica guardado). Diz, em frase inteira numa só linha, `O sistema não atesta a revisão jurídica do PDF enviado`;
  - o passo "No menu lateral" de `## Como entrar e se orientar` passa a listar, na ordem do menu, Painel, Conteúdos, Biblioteca visual, Usuários (só administradores), Acervo de PDFs e Pacotes; e a abertura de `## O que é, e o que ainda não é` passa a citar o Acervo de PDFs e os Pacotes;
  - duas linhas novas na tabela de `## Quando algo não funciona`: a mensagem de armazenamento de arquivos não configurado (texto literal copiado do código, ver critérios) e a falha de rede no envio ou no download do PDF (texto literal da tela, com a pista de CORS do bucket);
  - nova seção `## Armazenamento de arquivos`, para quem instala, com `### Ambiente local` (subir o MinIO local pelo comando de `db:up` do backend, as envs `OBJECT_STORAGE_*` e os dois tetos, em tabela) e `### Pendências do Diretor` (provisionar conta, bucket e credenciais; a configuração de CORS do bucket reproduzida do `mnemonicos-backend/docker-compose.yml` da TASK-063-002, com as origens do frontend de produção em vez das locais; as envs no deploy; recomendação de regra de lifecycle do bucket para o prefixo `pending/`, TRISK-063-001);
  - novos termos no `## Glossário`: Acervo de PDFs, Pacote, Item, Ficha do pacote, Exportação, Data de fechamento legislativo (declarada);
  - a data de "Última atualização" da entrega;
  - ajuste mínimo do próprio texto de manutenção: a frase de abertura do guia e o bullet de `## Como manter este guia` que proíbem setup e configuração passam a ressalvar a seção `## Armazenamento de arquivos` (é a única que fala de ambiente).

### Não inclui
- `docs/producao-material/INDEX.md` (main session).
- Código de produção e de teste.
- Atualizar o guia em cada closure de tela (decisão do Tech Lead: só aqui).
- Atualizar a versão online do guia (artefato do claude.ai citado na linha "Versão online"): fora do alcance da TASK; o relatório de fecho declara que ela ficou pendente do Diretor.
- Reescrever seções que não mudam.

## Critérios de pronto

Baseline antes de começar: `git grep -nE '^## ' -- docs/GUIA-DE-USO.md` e `grep -m1 -E '^> Última atualização: ' docs/GUIA-DE-USO.md` (o guia já traz `2026-10-18`; fechando no mesmo dia, o critério de data sozinho aprovaria o estado atual, então o falsificador são as seções e os termos novos abaixo, ausentes no baseline).

- [ ] Seções novas presentes (AC-061-028, descreve o Acervo de PDFs, os Pacotes e a exportação) — verificação executável: `grep -nE '^(## Vendendo pacotes de PDF, passo a passo|### 1\. Envie os PDFs ao Acervo|### 2\. Monte o Pacote|### 3\. Baixe a Ficha e exporte|## Armazenamento de arquivos|### Ambiente local|### Pendências do Diretor)$' docs/GUIA-DE-USO.md` → exatamente 7 linhas (no baseline: 0).
- [ ] Aviso jurídico (AC-061-028, diz que o sistema não atesta revisão jurídica) — verificação executável: `grep -nE '^.*O sistema não atesta a revisão jurídica do PDF enviado' docs/GUIA-DE-USO.md` → 1 linha ou mais, todas dentro da seção `## Vendendo pacotes de PDF, passo a passo` (a frase inteira numa só linha; no baseline: 0).
- [ ] Data de "Última atualização" (AC-061-028, traz a data da entrega) — verificação executável: `date +%F` imprime a data do dia do fecho, e `grep -m1 -E '^> Última atualização: ' docs/GUIA-DE-USO.md` imprime `> Última atualização: ` seguido dessa mesma data.
- [ ] Menu e abertura (item "menu lateral" e "O que é") — verificação executável: `grep -n -A4 -E '^3\. No menu lateral' docs/GUIA-DE-USO.md` → o trecho lista Painel, Conteúdos, Biblioteca visual, Usuários, Acervo de PDFs e Pacotes nessa ordem, igual à ordem de `mnemonicos-frontend/src/lib/internal-nav.ts` (`grep -nE '^ +\{ label: ' mnemonicos-frontend/src/lib/internal-nav.ts`, lido pela ordem das linhas); `grep -n -A3 -E '^## O que é, e o que ainda não é' docs/GUIA-DE-USO.md` → o parágrafo cita "Acervo de PDFs" e "Pacotes".
- [ ] Rótulos citados existem no código de produção (descrever só o que existe) — verificação executável: `git grep -nF -e 'Exportar Pacote' -e 'Adicionar PDF' -e 'Baixar Ficha (.txt)' -e 'Mover para cima' -e 'Nenhum PDF no acervo ainda.' -e 'Acervo de PDFs' -- mnemonicos-frontend/src | grep -v '\.test\.' | grep -vE '^[^:]+:[0-9]+:[[:space:]]*(//|\*|/\*)'` → pelo menos 1 linha por literal (6 literais, lidos um a um); todo rótulo de botão ou mensagem entre aspas no texto novo do guia aparece nessa saída ou numa busca equivalente do mesmo formato (literal que não existe no código reprova o critério e é corrigido no guia, nunca no código).
- [ ] Mensagens da tabela "Quando algo não funciona" copiadas do código — verificação executável: `grep -nE '^.*STORAGE_NOT_CONFIGURED_MESSAGE =' mnemonicos-backend/src/modules/object-storage/object-storage.service.ts` mostra o texto do 503 de armazenamento não configurado, e a linha correspondente do guia traz esse texto literal; a linha da falha de rede traz o texto literal da mensagem do envio em `mnemonicos-frontend/src/components/pdf-upload-form.tsx` (`git grep -nE '^.*CORS' -- mnemonicos-frontend/src/components/pdf-upload-form.tsx` mostra a linha de origem), com a mesma pista de CORS.
- [ ] Envs e tetos conferidos contra a fonte — verificação executável: `grep -nE '^(OBJECT_STORAGE_[A-Z_]+|PDF_LIBRARY_MAX_FILE_SIZE_BYTES|SALES_PACKAGE_MAX_EXPORT_BYTES)=' mnemonicos-backend/.env.example` → 7 linhas, e `grep -cE '^\| (OBJECT_STORAGE_ENDPOINT|OBJECT_STORAGE_REGION|OBJECT_STORAGE_BUCKET|OBJECT_STORAGE_ACCESS_KEY_ID|OBJECT_STORAGE_SECRET_ACCESS_KEY|PDF_LIBRARY_MAX_FILE_SIZE_BYTES|SALES_PACKAGE_MAX_EXPORT_BYTES) \|' docs/GUIA-DE-USO.md` → `7` (uma linha de tabela por variável, no formato `| NOME | …`); os padrões do guia (50 MB para o arquivo e 500 MB para a exportação) batem com `grep -nE '^ +.*(PDF_LIBRARY_MAX_FILE_SIZE_BYTES|SALES_PACKAGE_MAX_EXPORT_BYTES)' mnemonicos-backend/src/config/env.ts` (52428800 e 524288000); nenhum valor de segredo no guia (a tabela traz só nomes e para que servem).
- [ ] CORS do bucket reproduzido do compose (pendência do Diretor) — verificação executável: `grep -cE '^.*http://localhost:3000' mnemonicos-backend/docker-compose.yml docs/GUIA-DE-USO.md` → 1 ou mais em cada arquivo; a seção `### Pendências do Diretor` lista os mesmos métodos (PUT e GET) que o compose libera e diz que, em produção, as origens são as do frontend publicado (lidos lado a lado).
- [ ] Termos no Glossário — verificação executável: `grep -cE '^\| (Acervo de PDFs|Pacote|Item|Ficha do pacote|Exportação|Data de fechamento legislativo \(declarada\)) \|' docs/GUIA-DE-USO.md` → `6` (no baseline: 0).
- [ ] Ressalva da regra de manutenção — verificação executável: `grep -nE '^.*Armazenamento de arquivos' docs/GUIA-DE-USO.md` mostra a menção na frase de abertura (linhas 3 a 6) e no bullet de `## Como manter este guia`, além do título da seção (3 linhas ou mais).
- [ ] Sem warnings/lints novos sobre todos os arquivos do diff (`git diff --name-only <commit-pai da TASK>..HEAD`): `npm --prefix mnemonicos-frontend run format:check` e `npm --prefix mnemonicos-backend run format:check` seguem como na baseline (o guia vive no workspace, fora dos repos de código; nenhum arquivo de código é tocado).

### Critérios herdados dos gates (retry — gates 7 e 11)
- [ ] **Diagnóstico de CORS aponta a tela que de fato depende dele (gates 7 e 11, alta; lição `linha-de-diagnostico-do-guia-copia-a-mensagem-da-tela-que-faz-o-pedido`)** — o "Baixar" do Acervo é navegação (`pdf-library-board.tsx` `<a href>`, sem CORS); dependem do CORS do bucket o envio (`pdf-upload-form.tsx`, "Enviar PDF"), a substituição (`pdf-replace-dialog.tsx`, "Confirmar substituição") e a exportação do Pacote (`export-package-archive.ts` `fetch`). No guia: (1) a linha da tabela "Quando algo não funciona" sobre origem não liberada troca "A mesma pista vale para baixar o PDF" por "Ao substituir, a mesma mensagem cita \"Confirmar substituição\""; (2) linha nova na tabela com o literal de `ARCHIVE_FAILED_MESSAGE` (`sales-package-export-control.tsx`) → "Exporte de novo; se persistir, avise a equipe técnica (o CORS do bucket pode não liberar o site — ver Pendências do Diretor)"; (3) em "Pendências do Diretor", item do CORS: "Sem isso o envio e a substituição falham com a mensagem de origem não liberada, e a exportação do Pacote falha com \"Não foi possível gerar o arquivo\"". Prova: `grep -nF 'A mesma pista vale para baixar o PDF' docs/GUIA-DE-USO.md` → vazio; o literal de `ARCHIVE_FAILED_MESSAGE` (lido por grep no frontend) aparece 1 vez na tabela.
- [ ] **Quem remove o Pacote (gate 11, média)** — no passo "2. Monte o Pacote", junto de "Remover": "Só o autor do Pacote ou um administrador remove o Pacote; editar e compor fica aberto a qualquer editor." (regra de `sales-packages.service.ts`, mensagem de 403). Prova: grep da frase → 1 linha dentro de `### 2. Monte o Pacote`.
- [ ] **Jargão fora da linha de quem usa (gate 11, sugestão)** — nas linhas da tabela voltadas a quem usa, a ação vem primeiro ("avise a equipe técnica") e "CORS do bucket" fica entre parênteses.
- [ ] **Sem estado de processo no guia (gate 7, sugestão)** — remover a frase de que a versão online "fica pendente do Diretor" (estado do ciclo vai ao relatório de fecho, não ao guia); prosa nova quebrada em ~95 colunas como o resto do guia.

## Riscos específicos

- Textos de interface e mensagens do guia dependem do código das TASKs 003 a 012 já mergeado na branch; divergência entre o guia e a tela se corrige no guia (o código manda).
- A versão online do guia (claude.ai) não é atualizada por esta TASK e fica pendente do Diretor.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
**Jira**: KAN-260

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
