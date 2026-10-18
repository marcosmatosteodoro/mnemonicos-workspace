# BRIEF-064: PDF final da tira ilustrada (versão para venda)

**Slug**: producao-material
**Status**: Emitido
**Data**: 2026-10-18
**Largada**: 2026-10-18T01:15:09-0300
**SPEC**: SPEC-064
**Jira**: KAN-237 (Epic; Em andamento desde 2026-10-18). Histórias já existentes no quadro, a vincular (não criar): KAN-244, KAN-245, KAN-246, KAN-247

## Pedido como dito
"Implemente o jira KAN-237
Coloque o épico em Em andamento e comece a desenvolver os jiras, crie uma branch  do épico e siga tuodos de lá"

"Assim que terminar tudo abra PR"

Respostas do Diretor à última chamada (2026-10-18):

- Isolamento: **git worktree** de cada repo na branch do épico, saindo de `origin/main` (outra
  sessão roda o KAN-236 na cópia de trabalho principal).
- KAN-246: o PDF publicado fica **no Postgres** (bytes, como a biblioteca visual já faz).
  **Migração aditiva autorizada** (só tabela nova); entra no diff para revisão.
- KAN-245: sem a referência visual de Produtos, **o time propõe o layout** (capa, quadro com a
  ilustração em destaque, numeração, fonte embutida pt-BR) sob o gate de design. A aprovação da
  amostra impressa fica pendente de Produtos.

Épico KAN-237, lido via conector em 2026-10-18 (resumo): Produtos exportou a tira e recebeu um
PDF com cabeçalho "RASCUNHO / Variante / Gerado em / Sem versão fechada" em toda página e só o
texto do quadro, sem imagem. "Não é isso que eu quero. Quero meus arquivos em PDF com as tiras
ilustradas com o conteúdo das provas." Objetivo: PDF final sem marcas internas, com cada quadro
e sua ilustração, em qualidade de impressão, só de conteúdo com versão aprovada, e guardado
para compor um pacote de venda. Histórias:

1. **KAN-244**: PDF final sem marcas de rascunho, só para conteúdo com versão aprovada e válida.
   Dois modos de exportação (rascunho igual ao atual; final). Rodapé discreto "Versão N —
   legislação verificada até DD/MM/AAAA". O backend recusa o modo final sem versão aprovada ou
   com alteração depois do fechamento. Altera a SPEC-024 (AC-024-005).
2. **KAN-245**: diagramação da tira ilustrada: capa (conteúdo, prova, versão), quadros com a
   ilustração em destaque, numeração de página, fonte embutida que cubra pt-BR. WEBP entra no
   PDF (ou é recusado no upload; decisão no PLAN). Aviso na exportação listando quadros sem
   imagem ou com imagem que não entrou. Resolução mínima recomendada, com aviso no upload.
3. **KAN-246**: "Publicar PDF final" grava o arquivo ligado ao conteúdo e à versão aprovada.
   Imutável: nova aprovação gera novo arquivo e o anterior fica no histórico. Lista de PDFs
   publicados por conteúdo, com download interno, byte a byte igual em todo download.
4. **KAN-247**: no estado vazio do seletor "Vincular associação visual", link para a Biblioteca
   visual. Na tira, indicador "N de M quadros com imagem". Seção "Como ilustrar uma tira e gerar
   o PDF" no `docs/GUIA-DE-USO.md`.

## Interpretação do PO
**Contexto**: o PDF de hoje é um rascunho interno: marcado como rascunho em toda página, só com
texto, e descartado depois do download. Produtos quer o material de venda: a tira ilustrada,
limpa e guardada.

**Pedido**: (1) um **modo final** de exportação, liberado só para conteúdo com versão aprovada e
sem alteração depois dela, sem marcas internas; (2) o PDF final **diagramado** como material de
estudo, com capa, quadros ilustrados e fonte que não quebra com acento ou aspas curvas, avisando
quando um quadro sai sem imagem; (3) **publicar** esse PDF, que fica guardado e imutável por
versão aprovada, com histórico e download; (4) deixar **descobrível** o caminho para ilustrar a
tira.

## Premissas decididas
- O PDF de **rascunho continua idêntico** ao atual. O modo final é um caminho novo, não uma
  troca do rascunho.
- "Versão aprovada e válida" usa a regra que já existe (F8/F9, gate de versão aprovada da
  SPEC-032). O time não inventa regra nova de aprovação.
- O PDF publicado fica no Postgres, ligado ao conteúdo e à versão aprovada, e nunca é
  sobrescrito. A migração só cria tabela.
- A recusa do modo final e da publicação sem versão aprovada é **do backend**. A tela só espelha.
- Só quem já exporta PDF hoje exporta e publica o final (mesmos papéis da rota atual).
- O layout é proposta do time, revisada pelo `product-designer`. A amostra impressa aprovada
  por Produtos é pendência de Produtos, não do time.
- Uma branch do épico em cada repo (`feat/producao-material-pdf-final-tira-ilustrada`) e, no fim,
  um PR por repo com links cruzados. O merge é do Diretor.

## Fora de escopo
- Montar pacote e exportar para marketplace (KAN-236, outra sessão). Este épico só deixa o PDF
  publicado disponível para uma fatia futura do KAN-236 consumir.
- Storage de objetos externo (Vercel Blob/S3).
- Editar o PDF dentro do sistema, marca d'água e dados do comprador.
- Cadastro de associação visual em painel sobre a tira, sem sair do contexto. O KAN-247 pede
  "se der"; a entrega mínima é o atalho de 1 clique e a volta ao quadro.

## Estimativa
- **Base**: BRIEF-064 · INDEX producao-material · ficha (security/review/screenVerify ativos) · módulo `publication` no worktree · calibração (8 demandas; fator ×0,3 do modo autônomo)
- **Dimensão**: ~5 waves · ~11 tasks (~5 small · ~6 medium)
- **Por fase**: forja 0,15–0,5h · artefatos 1,2–2,4h · implementação 2,7–10,5h · gates 1,5–4,2h
- **Total**: 5,5–18h (horas de ciclo, não prazo de calendário)
- **Confiança**: média — WEBP e fonte embutida ainda abertos (decisões do PLAN) e layout sem referência abrem a faixa
- **Lacunas**: decisão WEBP (recusar × converter; `sharp` nativo leva ao teto) e fonte/licença; aprovação da amostra impressa por Produtos (reprovação gera ciclo de ajuste fora da faixa)

## Cronologia
- specify: 2026-10-18T01:31:25-0300 · correções: 1 · classes: spec-secao-ausente(1) · spec-ac-fora-gwt(7) · spec-ears-nao-casa(1) · janelas: redação 2min/480l · correção 3min/480l
- plan: 2026-10-18T01:39:49-0300 · correções: 1 · classes: plan-dec-irreversivel(8) · janelas: redação 6min/527l
- tasks: 2026-10-18T02:44:10-0300 · correções: 2 · classes: criterio-esperado-inatingivel(2) · task-wave-overlap-arquivo(1) · dependencia-contrato-divergente(1) · contrato-harness-divergente(1) · criterio-ausencia-vacuo(1) · criterio-raiz-execucao(2) · janelas: redação 40min/1613l · correção 5min/1613l
