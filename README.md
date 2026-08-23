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

## Tracker (Jira)

**Desligado** (`jira.enabled: false`). O ciclo roda sem tracker; SPEC, PLAN e TASKs vivem
em `docs/`. Para ligar, os ids têm de ser **medidos na instância** — nunca herdados de
outro workspace, sob pena de escrever os cards deste produto no board do projeto alheio.
Passo a passo em [docs/_meta/README.md](docs/_meta/README.md).

## Git deste repositório

Este workspace fica **sempre na `main`**: os artefatos SDD são consumidos por outros ciclos
e sessões paralelas, e esconder isso numa branch de feature é a origem dos conflitos em
`docs/`. Os dois repos de código seguem branch por demanda
(`feat/<slug>-<descrição-curta>`) com PR para `main`.

Os repositórios symlinkados estão no `.gitignore` daqui — não são submódulos e não são
versionados por este repo.
