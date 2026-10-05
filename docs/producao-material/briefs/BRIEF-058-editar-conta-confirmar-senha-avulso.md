# BRIEF-058: "Confirmar senha" ausente na redefinição de senha da edição de conta (o KAN-223 foi aplicado em código morto)

**Slug**: producao-material
**Tipo**: avulso (bug)
**Status**: Aberto (card local, aguardando sync com o Jira)
**Data**: 2026-10-05
**Origem**: Diretor, em sessão, com print de `/users/<id>/edit` (tema escuro; dados da conta no
print não reproduzidos aqui). O acesso ao Jira está retirado.
**Jira**: KAN-234 (Tarefa, status medido: Backlog; sincronizado em 2026-10-05); links `Relates` → KAN-223 e KAN-220

## Pedido como dito
"outra coisa que pedi e nã́o ta ai é o Nova senha com confirmar senha, cd o segundo?"

## Diagnóstico (conferido na `origin/main` em 2026-10-05)
- O **KAN-223** (`1de97f9`, mergeado) pôs "Confirmar senha" em dois lugares: no `create-user-form`,
  onde chega à tela, e no `ResetPasswordDialog` de `src/components/account-action-dialogs.tsx`.
- Só que o **KAN-220** (`6bcde76`) já tinha tirado a redefinição de senha da linha da tabela de
  usuários e levado para a página `/users/<id>/edit`. Lá ela é renderizada por um formulário
  **próprio**, `ResetPasswordSection` em `src/components/user-edit-screen.tsx`, com um único
  `PasswordField` "Nova senha" e **sem confirmação**.
- O `ResetPasswordDialog` não é importado por nenhum código de produção, só pelos próprios testes.
  A confirmação do KAN-223 foi para código morto, e os testes do KAN-223 passaram provando um
  componente que nenhuma tela usa.

Resultado: a Nova conta tem confirmação, mas a redefinição de senha que o ADMIN realmente usa não
tem.

## Interpretação
Na seção "Redefinir senha" da edição de conta entra o campo **"Confirmar senha"** logo abaixo de
"Nova senha", com a mesma regra do KAN-223:

- senhas diferentes ou confirmação vazia não enviam a requisição;
- o erro aparece no campo de confirmação;
- a confirmação é só do cliente e não vai no corpo da requisição.

A regra vem do mesmo ponto já usado pela Nova conta (`confirmationError`, de
`src/lib/password-policy.ts`), sem cópia. O código morto sai: o `ResetPasswordDialog` e os testes
que só provavam ele.

## Premissas decididas
- **P-058-001** [assumido]: o comportamento é o do KAN-223 sem mudanças: mesmas mensagens, mesmo
  momento de validação, a confirmação limpa junto com a nova senha depois do sucesso, e o mesmo
  `PasswordField` com o botão de mostrar/ocultar.
- **P-058-002** [assumido]: remover o `ResetPasswordDialog` morto está no escopo, porque é a causa
  do defeito: duas implementações da mesma ação, e só a sem uso foi corrigida. Se houver outro
  código exportado em `account-action-dialogs.tsx` ainda em uso, ele fica.
- **P-058-003** [assumido]: o aviso "As sessões da conta serão encerradas." e o botão "Redefinir
  senha" ficam como estão. O visual da seção acompanha o BRIEF-059.

## Fora de escopo
- O layout da página de edição de conta (BRIEF-059).
- Política de senha (tamanho, força) e o endpoint de redefinição no backend.

## Critério de aceite
- Em `/users/<id>/edit`, a seção "Redefinir senha" tem "Nova senha" e "Confirmar senha", e as
  duas são obrigatórias.
- Com as senhas diferentes, ou a confirmação vazia, nenhuma requisição de redefinição sai (prova
  por interceptação), e o erro aparece associado ao campo de confirmação (`aria-describedby`).
- Com as senhas iguais e válidas, a requisição sai **sem** o campo de confirmação no corpo, e os
  dois campos são limpos depois do sucesso.
- A regra de confirmação vem do mesmo módulo usado pela Nova conta, sem lógica copiada.
- O `ResetPasswordDialog` não existe mais em `src/` e nenhum teste prova componente sem uso em
  produção.
- `npm run validate` e `npm run build` limpos.

## Gates previstos
code-reviewer (régua avulsa) · **security-engineer** (gate 8: fluxo de senha, superfície de
autenticação) · product-designer (gate 11: campo novo, erro, estados) · qa (gate 9: redefinir com
senha diferente, vazia e igual, com a requisição interceptada) · performance-engineer n/a.

## Lição candidata (para a closure)
Uma entrega que corrige um componente sem conferir que ele é **o que a tela renderiza** passa nos
testes e não chega ao usuário. Antes de mudar uma ação, ache o ponto de uso em produção
(`grep` pelo import fora de `*.test.*`). Alvo: projeto (`guidelines/project/lessons/`).

## TASKs
<nenhuma — o brief é a unidade de execução>

## Execução
<a preencher na implementação>
