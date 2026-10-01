---
area: Design
estado: ativa
validade: indeterminada
confirmada: 1
contestada: 0
paths:
  - mnemonicos-frontend/src/components/**/*.tsx
tags: [acessibilidade, foco, teclado, rtk-query, paginacao, estado-de-carregamento]
---
## [Design] Controle que dispara a troca de conteúdo (paginação, filtro, retry) fica montado durante o carregamento — só o miolo é condicional

**Erro:** na TASK-049-003 (PLAN-049, KAN-179, 2026-09-30) a lista paginada de contas fazia
`if (!currentData) return <Carregando/>`. A troca de página zera `currentData` para os args
novos, então o ramo derrubava a árvore inteira, inclusive a barra Anterior/Seguinte. Quem
usava teclado focava "Seguinte", acionava, o botão desmontava e o foco caía no `<body>`. No
limite, o `disabled` aplicado ao botão focado fazia o mesmo. Pego pelo `product-designer`
(gate 11, Wave 2), NFR-048-003 (teclado).
**Causa:** o ramo de carregamento foi escrito para trocar as linhas pelo indicador (o estado
pedido pela SPEC), mas também removeu o controle que disparou o fetch. Os testes usavam
`fireEvent.click` e nunca conferiam `document.activeElement`.
**Solução:** quando um estado de carregamento ou de erro troca o conteúdo de uma vista, o
controle que disparou a troca fica montado na MESMA posição da árvore (um único `return`;
só o miolo é condicional; a barra é irmã estável). Os valores da barra vêm de `data` (o
último resultado retido pelo RTK Query), não de `currentData`. Se o botão acionado ficar
`disabled`, o foco vai a um alvo estável nomeado (o botão oposto; senão o título com
`tabIndex={-1}`). Prova: teste com a resposta segurada que confere `document.activeElement`
durante e depois do fetch, mais o caso do limite. Referência:
`mnemonicos-frontend/src/components/users-list.tsx` e
`users-list.integration.test.tsx` (F1–F4), commit `85d190f`. Eixo de prova complementar: a
lição "Critério de restauração de foco redigido pelo EVENTO de transição…" (lessons.md).

**Reincidência (2026-10-01, TASK-049-004, Wave 3 do mesmo PLAN — `confirmada: 1`):** o botão
"Criar conta" fica `disabled` em voo e, na falha do servidor (409/422/500), o foco ficava no
`<body>`. O título da lição falava de "troca de conteúdo (paginação, filtro, retry)" e o envio
de formulário não foi reconhecido como o mesmo caso. **Extensão:** todo botão que recebe
`disabled` enquanto focado (envio de formulário em voo, confirmação de diálogo) nomeia o alvo
de foco de CADA desfecho — na falha, o primeiro campo com erro ou o campo que precisa ser
redigitado; no sucesso, um alvo estável — aplicado depois do commit (ref + `useEffect` sobre os
erros) para o leitor de tela ler `aria-invalid`/`aria-describedby` novos. Prova:
`document.activeElement` após cada desfecho. Referência: `mnemonicos-frontend/src/components/create-user-form.tsx`
(`pendingFocusRef`), commit `8522792`; molde correto do diálogo: `account-confirm-dialog.tsx` (efeito de `busy`).
