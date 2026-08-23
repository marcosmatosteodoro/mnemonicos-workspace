# Guidelines do projeto

Lidos pelo ciclo keelson a partir da ficha (`keelson.config.json`) e do `CLAUDE.md` da
raiz. **Precedência**: em conflito, o que está aqui **vence** o perfil de linguagem.

| Arquivo | Para quê |
| --- | --- |
| [backend/README.md](backend/README.md) | Regras do `mnemonicos-backend` — leia antes de codar lá |
| [frontend/README.md](frontend/README.md) | Regras do `mnemonicos-frontend` — leia antes de codar lá |
| [lessons.md](lessons.md) | Lições registradas após erro real (code review, retry, correção humana) |

## Duas regras que valem nos dois repos

Herdadas do `b2b-workspace`, onde foram aprendidas com dano medido e reincidência. As
medições citadas são **daquele** projeto — a régua é o que se importa, não o número.

### 🔴 Narrativa de rodada não entra no código — nem em comentário, nem em nome de teste

Comentário, cabeçalho de `describe` **e nome de `it`** nunca citam rodada de correção,
revisor, achado numerado, data de decisão nem estado anterior da suíte (*"antes só X tinha
oráculo"*, *"esta faltava"*). O **porquê durável** fica; a **proveniência** vai para o
report do gate e para o histórico da TASK.

Em arquivo de teste o endereço errado se disfarça de documentação legítima do oráculo — é
por isso que a regra precisa estar aqui, e não só nos artefatos do slug. Lá, 11 linhas de
narrativa voltaram ao código **4 commits depois** do commit que existiu só para removê-las.

### 🔴 Comentário é para a ARMADILHA, não para o requisito — e a casa comenta pouco

O que **fica**: a armadilha que o próximo leitor não deduz do código, o "não copie o
vizinho X", o `>` que não é `>=`. Exemplos do próprio código daqui:

- `mnemonicos-backend/src/lib/prisma.ts` — *por que* o client vive no `globalThis` (pool
  novo por reavaliação esgotaria as conexões).
- `mnemonicos-backend/docker-compose.yml` — *por que* o mount é `/var/lib/postgresql` e
  não `.../data` (Postgres 18+ sobe unhealthy no caminho antigo).
- `mnemonicos-frontend/src/app/providers.tsx` — *por que* a store nasce por árvore e não
  como singleton de módulo (vazaria estado entre requests no SSR).

O que **sai**: reenunciar o FR/AC que o código já implementa, justificar a decisão (isso é
do PLAN), narrar medição e citar `COMP-`/`TASK-`.

**Régua prática: bloco de no máximo 3–4 linhas.** Bloco de 10+ linhas é sinal de que a
explicação pertence ao artefato SDD, não ao fonte.
