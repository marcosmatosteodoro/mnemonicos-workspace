# BRIEF-061: Pacotes de PDF prontos para vender em marketplace

**Slug**: producao-material
**Status**: Emitido
**Data**: 2026-10-18
**Largada**: 2026-10-18T00:59:09-0300
**SPEC**: SPEC-061
**Jira**: KAN-236 (Epic; Em andamento desde 2026-10-18). Histórias em escopo: KAN-239 (decisão), KAN-240 (pacotes), KAN-241 (upload)

## Pedido como dito
"Implemente o jira KAN-236
Coloque o épico em Em andamento e comece a desenvolver os jiras, crie uma branch  do épico e siga tuodos de lá"

Respostas do Diretor à última chamada (2026-10-18), que respondem a História KAN-239:

- Onde acontece a venda: **Marketplace** (Hotmart/Kiwify/Eduzz).
- De onde vêm os PDFs: **upload primeiro, gerado pelo sistema depois**.
- Gateway, se a venda fosse neste site: Mercado Pago.
- Acesso do aluno, se a entrega fosse neste site: conta criada na compra com link mágico.

## Interpretação do PO
**Contexto**: Produtos quer vender pacotes de PDFs das tiras ilustradas. O Diretor decidiu que a
venda acontece num **marketplace**, que já cuida de pagamento, nota, reembolso e entrega ao aluno.
O sistema continua uma fábrica interna, e o aluno não entra nele.

**Pedido**: dentro do sistema, Produtos (1) **envia PDFs prontos**, diagramados fora, para um acervo
de PDFs; (2) **monta pacotes** (nome, descrição, preço de referência, prova ou assunto) escolhendo
esses PDFs; (3) **exporta o pacote** num arquivo único para subir no marketplace.

**Premissas decididas**: ver abaixo. **Fora de escopo**: ver abaixo.

## Premissas decididas
- Venda, pagamento, área do aluno e entrega ao comprador ficam **no marketplace**. O sistema não
  tem checkout, pedido, comprador nem login de aluno. O papel `STUDENT` continua dormente.
- O PDF enviado é **validado pelo conteúdo** (assinatura `%PDF-`), não pela extensão nem pelo
  tipo declarado. Arquivo que não é PDF é recusado com mensagem clara.
- O PDF enviado **nunca fica em URL pública permanente**. Só a equipe interna autenticada baixa.
- Só a equipe interna que já produz material (EDITOR e ADMIN) envia PDF e monta pacote.
- O **preço** do pacote é referência para o cadastro no marketplace. O sistema não cobra nada.
- A versão e a data de fechamento legislativo do PDF enviado são **informadas à mão** por
  Produtos, porque o arquivo não passa pelo carimbo do sistema.
- Ordem de entrega: upload (KAN-241) primeiro, depois pacote e exportação (KAN-240), na mesma
  branch do épico.
- **Contingência**, sem efeito nesta entrega: se um dia a venda vier para este site, o gateway é o
  Mercado Pago e o aluno acessa por conta criada na compra com link mágico.

## Fora de escopo
- **KAN-242** (checkout e pagamento) e **KAN-243** (área do aluno): substituídas pelo marketplace.
  O descarte dos cards é proposto ao Diretor na Entrega, e o time não os fecha sozinho.
- Integração por API com o marketplace (publicar o produto ou receber venda por webhook). A
  exportação é um arquivo que Produtos sobe à mão.
- PDF **gerado pelo sistema** como item do pacote. Depende do épico KAN-237 (KAN-246, "Guardar o
  PDF final publicado") e entra numa fatia posterior.
- Marca d'água com dados do comprador e proteção contra compartilhamento: o sistema não conhece o
  comprador.
- Edição do PDF dentro do sistema.

## Estimativa — Acervo de PDFs, pacotes e exportação para marketplace (2026-10-18)

- **Base**: pedido (BRIEF-061) · INDEX e MAP de producao-material (análogo estrutural: F5/PLAN-023, upload validado por assinatura com `multer` em memória e entrega autenticada do binário; RISK-025-007, limite de corpo de 4,5 MB do Vercel) · ficha (security, review, screenVerify ativos) · calibração (7 demandas da era 4.437, todas no modo autônoma · fator ×0,3 do modo autônoma, mediana de realizado/ponto médio da faixa, usando a parede do ciclo quando medida)
- **Dimensão**: ~5 waves · ~9 tasks (~3 small · ~6 medium)
- **Por fase**: forja 0,2–0,5h · artefatos 1,2–2,7h · implementação 2,4–9h · gates 1,2–3,6h
- **Total**: 5–16h (horas de ciclo, não prazo de calendário)
- **Confiança**: média. A decomposição tem análogo forte (F5), mas a forma do armazenamento (upload direto ao bucket ou via função) ainda está aberta e é o maior fator de variação da implementação e dos gates 8/10
- **Premissas**: PDF guardado em armazenamento de objetos (não `bytea`), lido só por URL assinada de vida curta ou por streaming autenticado, nunca por URL pública · reaproveita o padrão de validação por assinatura de F5 · o ZIP usa uma dependência nova (supply chain no gate 8) · 2 telas novas mais a entrada no `internal-nav.ts` · tipos sincronizados nos dois repos e GUIA-DE-USO no mesmo ciclo · o gate 9 tende a PARCIAL por credencial de login · ficam fora da faixa os atos do Diretor: criar o bucket e o segredo, autorizar a migração, PR e merge
- **Lacunas**: (1) provedor de armazenamento e quem cria a conta/token · (2) tamanho máximo do PDF contra o teto de ~4,5 MB da função (ida e volta) · (3) conteúdo do ZIP além dos PDFs · (4) remoção ou substituição de PDF vinculado a pacote

## Cronologia
- specify: 2026-10-18T01:14:42-0300 · correções: 1 · classes: spec-fr-palavras(12) · spec-glossario-nao-usado(2) · spec-nfr-sem-numero(2) · spec-must-ratio(1) · spec-sem-should-may(1) · janelas: redação 1min/256l · correção 4min/256l
