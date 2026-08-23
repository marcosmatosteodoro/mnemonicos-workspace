# Lições do projeto

> Registradas pelo ciclo keelson após erro real (code review, retry, correção humana).
> Formato: uma lição por bloco, deduplicada — lição equivalente existente é atualizada,
> não duplicada.
>
> Uma lição só nasce de **erro que aconteceu aqui**. Não se importa lição de outro
> projeto: doutrina portável vira regra em `README.md`/perfil, não lição.

<!-- Adicionar lições abaixo desta linha -->

## [Exploração] Repos symlinkados não são atravessados por varredura ingênua

**Erro:** o `product-analyst`, na forja do BRIEF-001, afirmou que os diretórios de
`codePaths` "não existem no workspace" e que "os dois repositórios ainda não existem no
disco" — e construiu parte da crítica sobre isso. Os dois repos existem, com suíte verde e
schema Prisma completo, lidos pelo `code-scout` na mesma rodada.
**Causa:** `mnemonicos-backend` e `mnemonicos-frontend` são **symlinks** para fora do
workspace (ver `.gitignore`), e ferramenta de listagem/glob não segue symlink por padrão.
Quem lista a raiz vê dois links e conclui ausência.
**Solução:** para varrer código nestes repos, use o caminho **dentro** do link
(`mnemonicos-backend/src/...` direto no Read/Grep, que resolve o link) ou `find -L`. E,
sobretudo: **ausência detectada por varredura não é fato** neste workspace — antes de
afirmar que algo não existe, confirme com leitura direta do caminho. Quem passa contexto a
subagente que vai varrer código deve avisar que os repos são symlinks.
**Validade:** enquanto os dois repos entrarem no workspace por symlink (ver `.gitignore`).
**Estado:** ativa
**Contadores:** confirmada 0 · contestada 0
