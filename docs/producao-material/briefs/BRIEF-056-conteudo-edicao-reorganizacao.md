# BRIEF-056: Reorganizar a tela de edição do Conteúdo bruto, hoje grande e confusa

**Slug**: producao-material
**Tipo**: candidato a ciclo (`/keelson:auto`). **Não é avulso**: exige escolher entre alternativas
de organização da tela (régua do CLAUDE.md: decisão entre alternativas → ciclo)
**Status**: Concluído, PR #50 mergeado em 2026-10-05 (2026-10-05, `/keelson:auto` a pedido do Diretor: "Implemente o jira KAN-232")
**Largada**: 2026-10-05T16:38:55-0300
**Data**: 2026-10-05
**Origem**: Diretor, em sessão, sobre `/content/<id>`. O acesso ao Jira está retirado.
**Jira**: KAN-232 (História; Em andamento desde 2026-10-05)

## Pedido como dito
"Outra coisa é que esssa tela ta muito grande e confusa, vc poderia ter dividio ela melhor, talverz
com wizard form não sei, mas ta confuso demais, a distribuição dos links tbm não achei legal"

## O problema
A edição do Conteúdo bruto (`app/(interno)/content/[id]/page.tsx` + `components/content-form.tsx`)
empilha numa coluna única, sem nenhuma separação de navegação, **cinco assuntos diferentes**
(conferido na `origin/main` em 2026-10-05):

1. **Conteúdo bruto**: Texto normativo, Disciplina, Tema/assunto, Classe do radar e o bloco
   Fonte normativa, com o Salvar.
2. **Material de reforço** (`ContentSupplementaryPanel`): Contrastes (lista + formulário),
   Pegadinha (campo próprio) e Flashcards (lista + formulário). Cada um tem seu próprio salvar.
3. **Histórico de Versões** (`ContentVersionHistory`): a lista de versões e o formulário de fechar
   versão.
4. **Ações**: Ir para a Quebra da regra, Exportar Tira mnemônica, Exportar Resumo e Remover
   (BRIEF-055).
5. **Navegação**: o "Conteúdos brutos" do cabeçalho (BRIEF-051). A Quebra e a Tira ficam em outras
   rotas, mas o acesso a elas está espalhado: a Quebra no rodapé, a Tira em nenhum lugar desta tela.

Vários "salvar" independentes na mesma rolagem, sem fronteira visual clara entre o que pertence a
quê, fazem a tela parecer um formulário único gigante. O Diretor não consegue ler a tela.

## Alternativas a decidir no ciclo
| Alternativa | A favor | Contra |
|---|---|---|
| **A. Abas** (Conteúdo · Reforço · Versões), com a barra de ações e a navegação no cabeçalho | Acesso direto a qualquer parte; cada aba tem o seu salvar; padrão conhecido em edição | Parte do conteúdo fica escondida; precisa resolver o que acontece com alterações não salvas ao trocar de aba |
| **B. Wizard** (passo 1 Conteúdo → 2 Reforço → 3 Versões) | Guia a ordem natural de produção; bom para a **criação** | Na **edição** obriga a passar pelos passos para mexer só num; o Histórico de Versões não é etapa de produção |
| **C. Seções recolhíveis + índice lateral/âncoras** | Mantém tudo numa página, com estrutura visível | Continua longa; melhora a leitura, mas não a sensação de "uma tela só gigante" |
| **D. Hub do conteúdo**: cabeçalho com resumo e ações, e cada assunto em página própria (como já são Quebra e Tira) | Coerente com as rotas `/breakdown` e `/tira`; cada tela fica pequena | Mais navegação; precisa decidir rotas novas |

**Recomendação inicial do Tech Lead**: **A** (abas) na edição, mais um cabeçalho fixo com o
"Voltar", o título e a barra de ações. O wizard (B) faz mais sentido na **criação**, onde há ordem
natural. Mas a criação hoje tem só o bloco 1 (o reforço e as versões existem só depois de salvar),
então ali o wizard teria um passo só. A escolha é do ciclo, com o PO e o product-designer, e o
Diretor pode decidir antes.

## Premissas decididas
- **P-056-001** [assumido]: nenhum dado, regra ou endpoint muda; é reorganização de interface.
  Se o ciclo concluir que precisa de contrato novo no backend, isso é declarado na SPEC.
- **P-056-002** [assumido]: os BRIEF-051 (Voltar), 053 (layout dos campos e Salvar/Cancelar),
  054 (padrão de botão) e 055 (barra de ações) são **peças** desta reorganização e podem ser
  entregues antes dela. O ciclo do 056 as reaproveita e não as refaz.
- **P-056-003** [assumido]: a navegação entre Conteúdo, Quebra e Tira entra no escopo
  ("distribuição dos links"): o ciclo decide onde ficam os acessos a Quebra e Tira a partir da
  edição.

## Critério de aceite (de produto — a SPEC detalha)
- Um editor que abre um Conteúdo bruto identifica, sem rolar a página inteira, quais partes
  existem (conteúdo, reforço, versões) e chega a qualquer uma em **uma** ação.
- Cada parte com salvamento próprio deixa claro o que o seu "Salvar" grava.
- Ao sair de uma parte com alteração não salva, o editor é avisado ou a alteração fica preservada.
  O ciclo escolhe qual.
- As ações do conteúdo (Quebra, Tira, exportar, remover) ficam num lugar previsível e único.
- Nenhuma regressão nos fluxos atuais: salvar conteúdo, contrastes, pegadinha, flashcards, fechar
  versão, exportar e remover.

## Decisão da largada (Tech Lead, em nome do Diretor; veto na Entrega)
- **Alternativa A (abas)** escolhida: é a recomendação do próprio brief e o Diretor mandou implementar
  sem escolher outra. B (wizard) fica fora: a criação tem um passo só.
- **Rota**: a escolha entre alternativas está resolvida e nada de contrato muda (P-056-001), então o que
  resta é reorganização de interface em um repo: **TASK avulsa sobre este brief**, sem SPEC/PLAN, com
  gates 1-7, 9 (comportamento) e 11 (design/UX). Gate 8: n/a (sem auth/dado novo); 10: n/a.
- **Alterações não salvas**: a **alteração fica preservada** — os três painéis permanecem montados e a
  aba inativa só é ocultada, então trocar de aba não perde digitação.
- **Barra de ações** (Quebra da regra, **Tira mnemônica**, Exportar Tira, Exportar Resumo, Remover) sobe
  para o cabeçalho, acima das abas, visível em qualquer aba; Tira ganha o acesso que faltava.
- **Base**: o KAN-231 (barra de ações, PR #48) ainda não está mergeado e mexe na mesma tela; a branch
  sai dele e o PR é empilhado (base `feat/kan-231-barra-de-acoes-edicao`).

## Próximo passo
`/keelson:auto` a partir deste brief quando o Diretor priorizar (ou escolher a alternativa antes).

## Execução
- 2026-10-05: KAN-232 implementado (alternativa A, abas). Frontend PR #49 (empilhado sobre o #48) foi mergeado na
  branch do #48, não na `main`; o KAN-232 chegou à `main` pelo **PR #50**, mergeado pelo Diretor. Nenhuma mudança de backend, dado ou contrato.
- Gates: 1-7 aprovado (code-reviewer); 11 reprovado 1x (`overflow-x-auto` no tablist cortava o anel de
  foco e criava rolagem de 1px) e aprovado no re-gate (product-designer); 8 e 10 n/a; **9 pendente de
  verificação de tela** (Playwright MCP não conectou; conferir abas, foco por teclado, 328px e tema escuro).
  Suíte 102/102 (1379), tsc e eslint limpos.
- Lição: `guidelines/project/lessons/conteiner-com-overflow-corta-o-anel-de-foco-e-cria-rolagem-de-1px.md`.
- Jira: KAN-232 Concluído após o merge (sem épico pai nem filhos). Verificação de tela (gate 9) segue sem registro.
