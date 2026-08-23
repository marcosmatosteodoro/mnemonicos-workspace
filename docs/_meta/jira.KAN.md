# Mapa Jira — projeto KAN (mp-consultoria)

Configuração do sync keelson↔Jira. **Config, nunca ledger** — a régua do que entra e do
que não entra está em [README.md](README.md).

## Identidade do projeto

| Campo | Valor | Como foi obtido |
| --- | --- | --- |
| `site` | `https://mp-consultoria.atlassian.net/` | URL do board informada pelo Diretor, 2026-08-23 |
| `cloudId` | `455dadeb-0906-4adf-9500-c9bfb2b979bd` | Resolvido pelo conector a partir do hostname |
| `projectKey` | `KAN` | Segmento `/projects/KAN/` da URL |
| `boardId` | `2` | Segmento `/boards/2` da URL |

O `cloudId` veio de uma resolução hostname → cloudId feita pela própria API da Atlassian,
mas **nenhum dado do projeto foi lido ainda**: o conector desta máquina não tem grant para
este site (`isn't explicitly granted by the user`). Confirme-o na primeira sessão
autorizada, com `getAccessibleAtlassianResources`.

## 🔴 Pendente de medição — sem isto o sync não funciona

`jira.enabled` está **`false`** na ficha, e é o estado correto: o sync é *best-effort* e
não bloqueia o ciclo, então config incompleta produz **falha silenciosa a cada gancho** —
o pior dos dois mundos, porque parece ligado.

### 1. Autorizar o conector para este site

Na máquina dedicada, `/mcp` numa sessão interativa do Claude Code e concluir o OAuth **na
conta que enxerga `mp-consultoria`**. Prova de que funcionou:

```
mcp__atlassian__getAccessibleAtlassianResources
→ deve listar mp-consultoria.atlassian.net com o cloudId acima
```

### 2. Medir os ids de `issueType`

```
mcp__atlassian__getJiraProjectIssueTypesMetadata
  cloudId: 455dadeb-0906-4adf-9500-c9bfb2b979bd
  projectIdOrKey: KAN
```

Mapear os quatro papéis da ficha para os ids devolvidos:

| Papel na ficha | O que é no ciclo | Tipo esperado | Id |
| --- | --- | --- | --- |
| `spec` | Épico da SPEC (2+ funcionalidades) | Epic | *a medir* |
| `feature` | História por funcionalidade | Story | *a medir* |
| `task` | Subtarefa por TASK | Subtask | *a medir* |
| `standalone` | Brief avulso (mudança pontual) | Task | *a medir* |

**Leia o nome no `createmeta`, nunca fixe o literal** — o mesmo papel tem nomes diferentes
entre instâncias, e em projeto pt-BR os nomes vêm traduzidos.

⚠️ `KAN` é a key default do template **Kanban**, que normalmente nasce *team-managed*
(next-gen). Nesses projetos os ids de tipo são **escopados ao projeto** — não reaproveite
id visto em outro projeto do mesmo site. Confirme também que Epic existe como tipo próprio:
sem Epic, `epicPolicy: multi-feature` não tem onde pendurar a SPEC, e a decisão passa a ser
usar `standaloneParent` ou mudar a política.

### 3. Medir as transições

Os ids de transição **têm de ser medidos card a card**, nunca deduzidos do nome da coluna:
instância com validator ou post-function recusa transição que "deveria" funcionar.

```
mcp__atlassian__getTransitionsForJiraIssue   # num card real de cada tipo
```

Cada id medido vira linha na seção *Trilho do board* abaixo. A ficha está em
`transition: "comment"` (só comenta, não move) — só troque para `"auto"` depois de os ids
estarem medidos e registrados aqui.

## Campos

*A preencher na primeira medição: campos obrigatórios por tipo, prioridade, responsável,
estratégia de escrita.*

## Etapas/Colunas

*A preencher: colunas do board 2, status-alvo de cada etapa do ciclo, coluna de nascimento
por tipo de issue.*

## Trilho do board

*A preencher: ids de transição medidos, na ordem do trilho, por tipo de issue. Validators e
post-functions descobertos entram aqui como regra — sem a narrativa do card em que foram
vistos.*

## Achados de config

*A preencher conforme a execução revelar: validator invisível, id que mudou, post-function
que não dispara. A medição justifica a régua; ela não é a régua.*
