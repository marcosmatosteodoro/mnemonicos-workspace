# BRIEF-016: Toggle de mostrar/ocultar senha nos campos de senha

**Slug**: producao-material
**Status**: Emitido
**Data**: 2026-09-07
**Largada**: 2026-09-07T13:31:49+0000
**SPEC**: SPEC-016
**Jira**: KAN-72

## Pedido como dito
"Com worktree analise o KAN-72 e implemente. E atualize o jira até revisão (a história) e
termine me mandando o link do pr (sub pode ir até done normal)."

KAN-72 (História, Jira): "Adicionar toggle de mostrar/ocultar senha em todos os campos de
password" — "Adicionar um ícone de 'olho' nos campos de senha da aplicação, permitindo
alternar entre texto oculto e visível. Padronizar esse comportamento em **todos** os campos
de senha do sistema (login, cadastro, troca de senha etc.) — não só num formulário
isolado." AC do card: dado um campo de senha em qualquer formulário, ao clicar no ícone de
olho, o conteúdo alterna entre oculto (••••) e visível; todos os campos de senha existentes
recebem o mesmo componente/comportamento.

## Interpretação do PO

**Contexto**: a autenticação de sessão (SPEC-002/PLAN-003) já entrega o `LoginForm` com um
campo `type="password"` sem alternância de visibilidade. É hoje o **único** campo de senha
real do sistema — não existem ainda telas de cadastro ou troca de senha implementadas.

**Pedido**: extrair um componente de campo de senha reutilizável com toggle de
visibilidade (ícone de olho, acessível via teclado e leitor de tela) e aplicá-lo no
`LoginForm`, de forma que qualquer campo de senha futuro (cadastro, troca de senha) reuse o
mesmo componente sem trabalho extra.

**Premissas decididas**: (1) escopo é frontend-only — não há dado novo, endpoint novo nem
mudança de contrato; (2) "todos os campos de senha existentes" hoje = 1 (`LoginForm`); a
reutilização em telas futuras é satisfeita pelo componente existir e ser o único caminho
idiomático, não por retrofitar telas que não existem; (3) o valor da senha nunca é logado
nem exposto fora do DOM — o toggle é puramente de apresentação (`type` do input), sem novo
estado de rede; (4) o botão de alternância não é o botão de submit do formulário
(`type="button"`), para não disparar submit acidental.

**Fora de escopo**: telas de cadastro/troca de senha (não existem ainda); validação de
força de senha; qualquer alteração de contrato de autenticação.

## Premissas decididas

- (1)–(4) acima.

## Fora de escopo

- Telas de cadastro/troca de senha (inexistentes).
- Regra de força/política de senha.

## Cronologia
- Largada: 2026-09-07T13:31:49+0000
