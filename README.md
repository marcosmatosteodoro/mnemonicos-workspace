# mnemonicos-workspace

Pasta de trabalho do **Projeto Material Mnemônico de Alta Retenção para Concursos**.
Reúne os dois repositórios do produto (symlinkados, cada um com seu próprio `.git` e seu
remote no GitHub) e versiona o que é compartilhado entre eles: a ficha keelson, as
guidelines de projeto e os artefatos SDD em `docs/`.

| Symlink | Repositório | Stack |
| --- | --- | --- |
| `mnemonicos-backend` | `marcosmatosteodoro/mnemonicos-backend` | Node 22 · Express 5 · Prisma 7 · PostgreSQL |
| `mnemonicos-frontend` | `marcosmatosteodoro/mnemonicos-frontend` | Next 16 · React 19 · Tailwind 4 · Redux Toolkit |

## Setup inicial

```bash
./start.sh
```

O script faz os setups abaixo, sem repetir o que já estiver pronto:

- **Symlinks dos repositórios:** oferece a pasta irmã de mesmo nome como default (o layout
  esperado é os três diretórios lado a lado) e aceita outro caminho. Symlink quebrado é
  detectado e recriado.
- **Claude Code:** instala o CLI (`claude.ai/install.sh`) se não estiver no PATH.
- **Plugin keelson:** garante marketplace `fernandopetry/keelson` configurado e plugin
  `keelson@keelson` instalado e ativado.
- **MCP playwright:** garante o MCP `@playwright/mcp` em escopo `user`, usado na
  verificação visual de telas.
- **MCP atlassian (Jira/Confluence):** garante o MCP `atlassian` registrado em escopo
  `user`. No primeiro uso é preciso completar o login OAuth (`/mcp` numa sessão
  interativa).
- **GitHub CLI:** confere se `gh` existe e está autenticado — a skill
  `responder-code-review` depende dele. **Não instala automaticamente**: o pacote oficial
  exige `sudo`, e o script não roda comando privilegiado sem você pedir.
- **Atualização de plugins:** ao final, atualiza marketplaces e todos os plugins já
  instalados. Requer `jq`. Rodar o `start.sh` de novo já cobre isso.

Erros aparecem em vermelho; sucessos, em verde. Ao final, avisa se `keelson.local.json`
não existir — use `keelson.local.example.json` como molde.

### Primeiro comando: `/keelson:init`

Abra o Claude Code **nesta pasta** (não na pasta pai — o `init` escreve na raiz do projeto
da sessão) e rode:

```
/keelson:init
```

O que falta e só ele resolve: **gerar os perfis de linguagem** deste projeto
(`guidelines/project/backend/node-22.md` e `guidelines/project/frontend/next-16.md`, via
agent `staff-engineer`) e gravar o caminho deles em `profile.<role>.file`. Até isso
acontecer, a ficha aponta para o fallback embarcado do plugin (`plugin:*/none.md`) — nada
quebra, mas o ciclo roda sem perfil de linguagem, com as guidelines de projeto carregando
sozinhas o rigor.

O `init` é **idempotente e preservador**: completa e repara, nunca destrói. Ele mantém a
ficha que já está aqui (comandos de qualidade, `sensitiveGlobs`, gates, Jira desligado) e
preenche o que falta. Rodá-lo de novo também é o caminho de migração quando o plugin
atualizar.

## Como trabalhar

Modo padrão é o ciclo keelson autônomo: descreva a demanda em linguagem natural e o ciclo
`specify → plan → tasks → implement` roda com o time (po, developer, code-reviewer, qa,
security-engineer, performance-engineer, product-designer). Você é o **Diretor**: veto, PR,
merge e deploy são seus.

Demanda grande → `/keelson:specify-epic` decompõe em demandas independentes priorizadas,
cada uma com seu próprio ciclo. `/keelson:continue` retoma de onde parou.

Detalhes de doutrina, precedência e gates: [CLAUDE.md](CLAUDE.md).

## Skills do workspace

Skills de projeto vivem em `.claude/skills/` e são invocáveis por nome numa sessão.

| Skill | Para quê |
| --- | --- |
| `/responder-code-review` | Responder apontamentos de revisor humano num PR do **GitHub**, no registro da casa — curto, com medição, sem markdown pesado, com o 🤖 de autoria |

Code review do próprio diff vem do plugin, não daqui: `/keelson:review` (diff avulso) e o
gate de review dentro do ciclo. A skill acima é para a outra ponta — **responder** o que o
revisor humano apontou.

## Guidelines

[guidelines/project/](guidelines/project/) — em conflito, **vencem** o perfil de linguagem.
Leia o README do papel antes de codar:
[backend](guidelines/project/backend/README.md) ·
[frontend](guidelines/project/frontend/README.md).

`guidelines/project/lessons.md` recebe lição só de **erro que aconteceu aqui**.

## Rodar noutra máquina (dedicada a este projeto)

É o cenário previsto: uma máquina apontada 100% para este produto, com a conta Atlassian
**deste** projeto — não a corporativa.

```bash
git clone <remote-deste-workspace> mnemonicos-workspace
cd mnemonicos-workspace
git clone git@github.com:marcosmatosteodoro/mnemonicos-backend.git  ../mnemonicos-backend
git clone git@github.com:marcosmatosteodoro/mnemonicos-frontend.git ../mnemonicos-frontend
./start.sh          # aceita os defaults dos symlinks (as pastas irmãs)
```

Depois, dentro da pasta:

1. `claude` e então `/mcp` — conclua o OAuth do conector **atlassian com a conta deste
   projeto**. É esse passo que não dá para adiantar aqui: o conector desta máquina está
   autenticado na conta corporativa, e os ids do Jira só existem depois do login certo.
2. `/keelson:init` — gera os perfis de linguagem (ver acima).
3. Ligar o Jira — [docs/_meta/README.md](docs/_meta/README.md) traz a ordem de medição.

## Tracker (Jira)

O projeto existe: **`KAN`** em `mp-consultoria.atlassian.net`, board `2`. Site, `cloudId`,
`projectKey`, `boardId` e `mapFile` já estão na ficha.

**Ainda `enabled: false`**, e de propósito: faltam os ids de `issueType`, que são por
projeto e só saem do `createmeta` de um conector autorizado neste site. O sync é
*best-effort* e não bloqueia o ciclo — então ligar incompleto produz **falha silenciosa a
cada gancho**, que é pior que desligado, porque parece ligado.

Faltam exatamente dois passos, ambos na máquina dedicada:

1. `/mcp` numa sessão interativa → OAuth do conector atlassian na conta que enxerga
   `mp-consultoria` (o conector desta máquina só tem grant para o corporativo).
2. Medir os ids de `issueType` (e as transições, se for usar `transition: "auto"`).

Passo a passo com os comandos exatos: [docs/_meta/jira.KAN.md](docs/_meta/jira.KAN.md).
Até então o ciclo roda sem tracker — épico → histórias → subtarefas vivem em `docs/` e
nada bloqueia.

🔴 **Tripwire:** os valores certos são `mp-consultoria.atlassian.net` /
`455dadeb-0906-4adf-9500-c9bfb2b979bd` / `KAN`. Se algum dia aparecerem
`autoavaliar.atlassian.net` ou `c58a7785-1d06-4c7a-a5ed-d2734bbb1b69` nesta ficha, alguém
colou config do `b2b-workspace` — e o keelson criaria os épicos e histórias deste produto
no board `NOVA`, do Jira corporativo de outro produto.

## Design system do frontend

Ainda não existe, por opção: um arquétipo de tela extraído de zero telas seria molde
inventado. As regras de estilo que já valem estão em
[guidelines/project/frontend/README.md](guidelines/project/frontend/README.md) (tokens no
`@theme`, sem `tailwind.config.js`). O design system e a skill que o mantém serão criados
para este projeto quando houver tela real de onde extrair o molde.

## Git deste repositório

Este workspace fica **sempre na `main`**: os artefatos SDD são consumidos por outros ciclos
e sessões paralelas, e esconder isso numa branch de feature é a origem dos conflitos em
`docs/`. Os dois repos de código seguem branch por demanda
(`feat/<slug>-<descrição-curta>`) com PR para `main`.

Os repositórios symlinkados estão no `.gitignore` daqui — não são submódulos e não são
versionados por este repo.
