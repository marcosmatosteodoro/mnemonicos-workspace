# TASK-065-017: Escrever no Guia de uso a seção "Como ilustrar uma tira e gerar o PDF"

**Slug**: producao-material
**Pertence a**: PLAN-065
**Realiza (FRs)**: FR-064-028
**Funcionalidade**: FEAT-064-004 (primária)
**Componente**: COMP-065-019
**Wave**: 10
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Todo

## Dependências

- **Depende de**: TASK-065-002, TASK-065-003, TASK-065-010, TASK-065-014, TASK-065-015, TASK-065-016
- **Bloqueia**: nenhuma

## Contexto

O Guia de uso (`docs/GUIA-DE-USO.md`) ganha a seção que ensina o editor a ilustrar uma tira (Biblioteca visual, seletor, indicador de quadros com imagem, Resolução recomendada), a escolher entre rascunho e PDF final, a ler o Aviso de exportação e a publicar e baixar PDFs. Desvio declarado da regra "guia no mesmo ciclo da mudança" do `CLAUDE.md` do workspace: o guia é uma TASK final única porque o ciclo é o mesmo PLAN e o mesmo PR, e só depois das telas prontas os rótulos congelados podem ser conferidos contra o código. Território e convenção do guia: `docs/GUIA-DE-USO.md:176-185` ("Como manter este guia"); contrato: PLAN-065 COMP-019.

**Ambiente de execução**: os comandos rodam na raiz `Mnemonico/kan237/` (contém `mnemonicos-backend/` e `mnemonicos-frontend/`, worktrees da branch do épico, e `docs/`, symlink para o workspace); `docs/GUIA-DE-USO.md` e `mnemonicos-frontend/src` resolvem a partir dela. Os comandos `git` sobre o guia usam `git -C docs …` (o repositório do workspace); `git diff --name-only` nesse modo lista caminhos a partir da raiz do repositório do workspace (`docs/GUIA-DE-USO.md`).

## Escopo

### Inclui
- `docs/GUIA-DE-USO.md`:
  - seção nova `## Como ilustrar uma tira e gerar o PDF`, entre o fim do passo "7. Feche a versão e peça a aprovação" e `## Acompanhando o trabalho no Painel`, escrita para quem usa (o que clicar, o que esperar, o que fazer quando falha): ilustrar pela Biblioteca visual (o link "Ir para a Biblioteca visual" do seletor vazio e o "Voltar para a tira"), o indicador "N de M quadros com imagem", a Resolução recomendada de 2000 px no lado maior (o aviso no envio da imagem), exportar rascunho × PDF final (o final exige versão aprovada e válida; o que fazer quando o botão "Exportar PDF final" está desabilitado, com o caminho por "Histórico de Versões"), o "Aviso de exportação" e as três categorias (sem imagem, imagem que não entrou, abaixo da resolução recomendada, só informativa), publicar com "Publicar PDF final" e "Confirmar publicação", a confirmação quando faltam imagens e a de republicar a mesma versão, o painel "PDFs publicados", a marca “atual” e “Baixar”, e o que fazer quando publicar ou baixar falha;
  - ajuste do passo "4. Cuide da Biblioteca visual": a frase de WebP deixa de dizer que "ainda não aparece no PDF" e passa a dizer que no rascunho o WebP segue sem aparecer e no PDF final aparece (`docs/GUIA-DE-USO.md:91-92`);
  - ajuste do passo "6. Exporte o PDF": os dois modos (rascunho, marcado como RASCUNHO, e PDF final, que exige versão aprovada) com o rótulo "Exportar PDF final" (`docs/GUIA-DE-USO.md:105-110`);
  - na seção nova, um parágrafo diz que o PDF final ajusta as imagens maiores que 2000 px (o número vem da constante `RECOMMENDED_LONG_SIDE_PX` do backend, `mnemonicos-backend/src/modules/publication/strip-coverage.ts`, e do aviso do formulário; o guia não afirma outro valor), sem alterar a imagem guardada na Biblioteca visual;
  - a data de "Última atualização" (`docs/GUIA-DE-USO.md:10`) passa a ser a data do commit de fecho desta TASK (`git -C docs log -1 --format=%cs` depois do commit).

### Não inclui
- Código: nenhum arquivo de `mnemonicos-backend` nem de `mnemonicos-frontend`.
- Mudança nas demais seções ("Quando algo não funciona", "Glossário", "Para administradores", passos 1 a 3, 5 e 7, "Acompanhando o trabalho no Painel", "Como manter este guia").
- A versão online do documento (linha 8, artefato fora do repositório): fica como pendência do Diretor no relatório de fecho, porque o guia manda mantê-la igual e esta TASK não tem acesso a ela.
- Termos técnicos, nomes de arquivo, portas e configuração (o guia é escrito para o editor: `docs/GUIA-DE-USO.md:182-183`).

## Critérios de pronto

- [ ] AC-064-022 — a seção existe, cobre os temas pedidos e distingue os modos (WebP sem aparecer no rascunho, aparecendo no final), verificado executando na raiz de execução (`Mnemonico/kan237/`):
  ```
  node -e "const fs=require('fs');const g=fs.readFileSync('docs/GUIA-DE-USO.md','utf8');const cut=(a,b)=>{const i=g.indexOf(a);if(i<0)return '';const j=g.indexOf(b,i+a.length);return g.slice(i,j<0?undefined:j)};const s=cut('\n## Como ilustrar uma tira e gerar o PDF\n','\n## ');const p4=cut('### 4. Cuide da Biblioteca visual','### 5.');const p6=cut('### 6. Exporte o PDF','### 7.');const L=['Exportar PDF final','Publicar PDF final','Confirmar publicação','PDFs publicados','Aviso de exportação','Histórico de Versões','quadros com imagem','Ir para a Biblioteca visual','Voltar para a tira','“atual”','“Baixar”','2000 px','WebP'];const T=['sha256','ETag','endpoint','API','409','JSON','localhost','.tsx'];console.log(L.filter(l=>s.includes(l)).length,p4.includes('PDF final')&&p4.includes('ainda não aparece no PDF')===false,p6.includes('Exportar PDF final')&&p6.includes('rascunho'),g.indexOf('### 7. Feche')<g.indexOf('\n## Como ilustrar')&&g.indexOf('\n## Como ilustrar')<g.indexOf('\n## Acompanhando o trabalho'),T.filter(t=>s.includes(t)).length)"
  ```
  → `13 true true true 0` (no commit-pai: `0 false false false 0`, porque a seção não existe; o último número é a contagem de termos técnicos proibidos, que fica em 0). O rótulo é escrito entre aspas curvas para “atual” e “Baixar” (a palavra solta "atual" casaria "atualização"), e o texto da seção cita 2000 px e WebP.
- [ ] Título exato da seção — `grep -c '^## Como ilustrar uma tira e gerar o PDF$' docs/GUIA-DE-USO.md` → 1 (0 no commit-pai).
- [ ] Rótulos congelados conferidos na fonte do frontend (o guia descreve só o que existe no código: `docs/GUIA-DE-USO.md:184`), depois de as TASKs de tela (002, 003, 010, 014, 015, 016) estarem no código — executando na raiz de execução (`Mnemonico/kan237/`):
  ```
  node -e "const fs=require('fs'),p=require('path');const walk=d=>fs.readdirSync(d,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(p.join(d,e.name)):[p.join(d,e.name)]);const src=walk('mnemonicos-frontend/src').filter(f=>/\.tsx?$/.test(f)&&/\.test\./.test(f)===false).map(f=>fs.readFileSync(f,'utf8')).join('\n');const L=['Exportar PDF final','Publicar PDF final','Confirmar publicação','PDFs publicados','Aviso de exportação','Histórico de Versões','quadros com imagem','Ir para a Biblioteca visual','Voltar para a tira'];console.log(L.filter(l=>src.includes(l)).length,/[>'\x22]\s*atual\s*[<'\x22]/.test(src),/[>'\x22]\s*Baixar\s*[<'\x22]/.test(src))"
  ```
  → `9 true true` (cada rótulo do guia existe como texto de interface em arquivo de produção do frontend, fora dos testes; "atual" e "Baixar" são conferidos como texto inteiro de um elemento ou literal, nunca como pedaço de outra palavra). Se um rótulo mudou na implementação das TASKs de tela, o guia segue o código e a lista dos dois comandos acima é ajustada no mesmo diff.
- [ ] Rótulos ancorados ao componente que os emite (a busca no conjunto inteiro de `src` casaria um rótulo em arquivo errado) — executando na raiz de execução:
  ```
  node -e "const fs=require('fs');const r=f=>fs.readFileSync('mnemonicos-frontend/src/components/'+f,'utf8');const c={'published-pdfs-panel.tsx':['PDFs publicados','Publicar PDF final','Baixar'],'publish-pdf-dialog.tsx':['Confirmar publicação'],'export-warnings-list.tsx':['Aviso de exportação'],'visual-association-picker.tsx':['Ir para a Biblioteca visual'],'publication-export-control.tsx':['Exportar PDF final']};console.log(Object.entries(c).every(([f,ls])=>{const t=r(f);return ls.every(l=>t.includes(l))}))"
  ```
  → `true` (se um rótulo migrou de componente na implementação, o mapa acima é ajustado no mesmo diff e o motivo vai no relatório; "Voltar para a tira" e "quadros com imagem" são conferidos pelo comando do critério anterior, o 2º emitido pelo módulo `published-pdf-labels.ts`).
- [ ] Data de "Última atualização" — executando na raiz de execução, com a data do commit de fecho (`git -C docs log -1 --format=%cs`, lida depois do commit) informada como argumento (o relógio não é lido):
  ```
  node -e "const g=require('fs').readFileSync('docs/GUIA-DE-USO.md','utf8');const m=/^> Última atualização: (\d{4}-\d{2}-\d{2})$/m.exec(g);console.log(m!==null&&m[1]===process.argv[1],m!==null&&m[1]>='2026-10-18')" <AAAA-MM-DD do fecho>
  ```
  → `true true` (`2026-10-18` é a data do commit-pai; no mesmo dia a linha pode não mudar de valor, por isso o oráculo é "igual à data do fecho", não "mudou").
- [ ] Nenhuma outra seção foi tocada — executando na raiz de execução (`Mnemonico/kan237/`), com o SHA do commit-pai da TASK (capturado no baseline do developer):
  ```
  node -e "const cp=require('child_process'),fs=require('fs');const cur=fs.readFileSync('docs/GUIA-DE-USO.md','utf8');const old=cp.execSync('git show '+process.argv[1]+':docs/GUIA-DE-USO.md',{encoding:'utf8',cwd:'docs'});const cut=(t,a,b)=>{const i=t.indexOf(a);const j=t.indexOf(b,i+a.length);return t.slice(i,j<0?undefined:j)};const parts=[['## O que é, e o que ainda não é','### 4. Cuide da Biblioteca visual'],['### 5.','### 6.'],['### 7.','\n## '],['\n## Acompanhando o trabalho no Painel','\u0000']];console.log(JSON.stringify(parts.map(([a,b])=>cut(cur,a,b)===cut(old,a,b))))" <commit-pai>
  ```
  → `[true,true,true,true]` (trechos da abertura aos passos 1 a 3, passo 5, passo 7 e do Painel ao fim idênticos ao commit-pai; a seção nova, os passos 4 e 6 e a data são as únicas mudanças).
- [ ] Só documento — `git -C docs diff --name-only <commit-pai>..HEAD | grep -v '^docs/'` → saída vazia, e `git -C docs diff --name-only <commit-pai>..HEAD | grep -c '^docs/GUIA-DE-USO.md$'` → 1 (o 2º comando é o controle positivo do 1º: o diff não está vazio).

## Riscos específicos

- Os rótulos congelados vêm das TASKs de tela: se alguma sair com texto diferente, o guia segue o código (o segundo comando acusa) e a TASK não inventa rótulo.
- A versão online do guia (linha 8) não é atualizada aqui: a pendência vai no relatório de fecho como ato do Diretor.
- O guia é escrito para o editor: os motivos de recusa são ditos em linguagem de uso ("a versão precisa estar aprovada por um administrador que não a produziu"), sem códigos de erro nem termos de API.

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Commit SHA**: 
**Jira**: KAN-277

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>
