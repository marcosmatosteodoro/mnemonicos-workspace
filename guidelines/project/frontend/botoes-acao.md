# Botão de ação: ícone + rótulo curto (KAN-230)

Botão de ação da aplicação = **ícone à esquerda + rótulo curto**, num componente único.
Vale **daqui para frente**: tela e botão novos já nascem assim.

## Regra

- **Quando usar**: toda ação do usuário em botão ou link com aparência de botão (criar, editar,
  ver, voltar, salvar, cancelar).
- **Ícone à esquerda**, decorativo (`aria-hidden`, `focusable="false"`), cor por `currentColor`
  (segue o texto nos dois temas, em hover e foco), traço 2 como os ícones da navegação.
- **Rótulo curto**: um verbo quando der ("Novo", "Editar", "Ver", "Criar"). O contexto (qual
  conteúdo, qual objeto) vai no nome acessível, não no texto visível.
- **Nome acessível completo, começando pelo rótulo visível** (WCAG 2.5.3, label in name):
  `Editar conteúdo bruto: <trecho>`. Em lista com vários itens, o nome distingue um do outro
  (sufixo com trecho do item). Passa-se em `accessibleName`; sem ele, o nome é o rótulo.
- **Componente único**: `ActionButton` (`src/components/action-button.tsx`) — com `href` é
  `<Link>`, sem `href` é `<button type="button">`. Ícones em `src/components/action-icons.tsx`
  (`plus`, `pencil`, `eye`; ícone novo entra ali, não inline no consumidor). Aparência vem de
  `ACTION_LINK_CLASS`; cor nova só como token no `@theme`.
- Não copiar markup de ícone nem de aparência de botão em cada tela.

```tsx
<ActionButton href="/content/new" icon="plus" label="Novo" accessibleName="Novo conteúdo bruto" />
```

## Escopo

- Estreia: listagem `/content` (Novo, Editar, Ver/Criar).
- Telas existentes: a migração é card seguinte; esta regra não é retroativa.
- `/users`: ações de linha **só-ícone** por decisão anterior (KAN-219); não é tocado. Se o
  padrão vale para ação de linha de tabela é pergunta aberta ao Diretor (P-054-004).
- Hierarquia (primário × secundário) e cor não mudam aqui.
- Botão de andamento segue `BusyButton` (ver README, KAN-192).

## Testes

Nome acessível por `getByRole(..., { name })`, `href` do link, `svg` com `aria-hidden="true"`.
Exemplos: `src/components/action-button.test.tsx`, `content-list.action-links.test.tsx`.
