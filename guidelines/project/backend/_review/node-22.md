# Backlog de revisão humana — `node-22.md`

> Companheiro de [`../node-22.md`](../node-22.md) (`reviewed: false`, gerado por
> `staff-engineer`). Roteiro de verificação das **10** afirmações marcadas
> `⚠️ não confirmado` no perfil — lido **só no fluxo de revisão de perfil**, nunca em
> runtime de implementer/reviewer.
>
> **Protocolo:** a afirmação permanece inline no perfil (com a tag) porque já carrega a
> restrição acionável — o revisor não fica sem regra enquanto confirma. Item confirmado →
> corrigir ou ratificar a frase no perfil, **remover a tag lá e a entrada aqui**. Zero
> pendências → promover `reviewed: true` e preencher `reviewer` no frontmatter.
>
> **Gerador ≠ avaliador:** nada aqui é auto-aprovável pelo agente que escreveu o perfil.
> Todos os 10 itens são da §6 (Segurança) — a seção `[CRÍTICA]` do Charter Art. 2 —, então
> um item errado é vulnerabilidade documentada como boa prática, não imprecisão de estilo.

| # | Seção | Assunto | Risco se estiver errado |
|---|-------|---------|-------------------------|
| 1 | §6.1 | `$queryRaw` template tag sob driver adapter do Prisma 7 | SQL Injection (A05) |
| 2 | §6.1 | `mode: 'insensitive'` sob o query compiler TS/WASM | SQL Injection (A05) |
| 3 | §6.2 | Defaults do helmet 8 (CSP inclusa?) | Security Misconfiguration (A02) |
| 4 | §6.2 | `express.json()` neutraliza `__proto__`? | Prototype pollution (A05/A08) |
| 5 | §6.3 | `trust proxy: 1` correto no deploy + rate limit por instância | Spoof de `req.ip` / bypass de rate limit (A01/A06) |
| 6 | §6.4 | Semântica de wildcard do `redact` do pino | Vazamento de segredo em log (A04/A09) |
| 7 | §6.4 | Argon2id fora do core do Node 22 + parâmetros | Cryptographic Failures (A04) |
| 8 | §6.5 | `sameSite` viável para o par de domínios + CSRF | CSRF / sessão inutilizável (A01/A07) |
| 9 | §6.5 | Rotação e revogação de refresh token em serverless | Authentication Failures (A07) |
| 10 | §6.6 | Ausência de guarda de SSRF no `fetch`/undici | SSRF (A01) |

---

## 1. §6.1 — `$queryRaw`/`$executeRaw` com template tag sob o driver adapter do Prisma 7

**Afirmação do perfil (linhas 329–331):**

> "`$queryRaw`/`$executeRaw` com **template tag** interpolam os valores como parâmetros do
> driver `pg` (`$1`, `$2`), não como texto — inclusive sob o driver adapter do Prisma 7."

**O que confirmar e como.** O que está estabelecido é o comportamento histórico do Prisma
(template tag → placeholder). O que **não** está confirmado é que ele seja idêntico sob a
arquitetura nova da major 7 (query compiler em TS/WASM + `@prisma/adapter-pg` no lugar do
engine Rust).

1. Ler a página de **Raw queries** e a de **driver adapters** da documentação do Prisma da
   major instalada (confira a major exata com
   `npm --prefix mnemonicos-backend ls prisma @prisma/client @prisma/adapter-pg`), mais o
   **guia de upgrade para o Prisma 7** — procurando qualquer nota sobre mudança de
   parametrização em raw queries com adapter.
2. Prova empírica, que é a que vale: teste de integração contra o Postgres real do
   `docker-compose.yml` com entrada maliciosa clássica — `$queryRaw` com template tag
   recebendo o valor `' OR 1=1 --` — afirmando que o resultado é **vazio** (o valor foi
   tratado como literal), não a tabela inteira.
3. Confirmar no fio (o mais direto): ligar `log: [{ emit: 'event', level: 'query' }]` no
   client, ou `DEBUG=prisma:query`, e verificar que o SQL emitido tem `$1` e que a entrada
   aparece na lista de `params`, não embutida no texto da query.

**Por que importa.** Esta é a frase que autoriza `$queryRaw` com dado de usuário em todo o
projeto. Se sob o adapter a interpolação virar texto, cada uso de raw query passa a ser SQL
Injection direta — a classe de falha que o próprio perfil declara "rejeição imediata no
review".

---

## 2. §6.1 — `mode: 'insensitive'` traduzido para comparação parametrizada

**Afirmação do perfil (linhas 332–334):**

> "`mode: 'insensitive'` é traduzido pelo Prisma para comparação case-insensitive
> parametrizada no Postgres (`ILIKE`), sem interpolação da entrada — vale reconfirmar sob o
> compilador TS/WASM do Prisma 7, que substituiu o engine Rust."

**O que confirmar e como.** Duas coisas separadas: (a) que o operador gerado continua sendo
`ILIKE` (ou `LOWER(x) LIKE LOWER($1)`) e (b) que o valor segue como parâmetro.

1. Executar `prisma.discipline.findMany({ where: { name: { contains: s, mode: 'insensitive' } } })`
   com `DEBUG=prisma:query` e **ler o SQL emitido**, com atenção ao `$n` no lado direito da
   comparação.
2. Checar a referência de **filtering / case-insensitive filtering** na documentação do
   Prisma da major instalada, e as **release notes / changelog do Prisma 7** quanto a
   mudanças de tradução de operadores pelo query compiler.
3. Complemento com valor real: testar entrada contendo os metacaracteres de `LIKE` (`%`, `_`)
   e registrar o comportamento. Eles **não** são injeção de SQL, mas viram *wildcard*
   semântico (busca que retorna tudo) e podem custar full scan — se o endpoint for público,
   esse é o item do Art. 8 escondido dentro do item de segurança.

**Por que importa.** É o exemplo "✅ parametrizado" que abre a seção crítica. Exemplo
positivo errado numa doutrina é pior que ausência de exemplo: ele é copiado sem crítica.

---

## 3. §6.2 — Composição dos defaults do helmet 8

**Afirmação do perfil (linhas 378–382):**

> "`helmet()` está montado em `createApp()` e cobre `X-Content-Type-Options: nosniff`,
> `X-Frame-Options`, HSTS, `Referrer-Policy` e CSP; […] A composição exata dos defaults do
> helmet 8 (em especial se a CSP vem ligada e com qual policy) precisa ser conferida contra
> o CHANGELOG da major instalada."

**O que confirmar e como.**

1. Fixar a versão real: `npm --prefix mnemonicos-backend ls helmet`.
2. Ler o **README e o CHANGELOG do helmet** da major instalada — a lista de middlewares
   habilitados por `helmet()` sem argumentos muda entre majors (headers entram, saem e
   trocam de default; `X-XSS-Protection`, `Cross-Origin-Embedder-Policy` e a policy de CSP
   são os pontos historicamente móveis).
3. Prova falsificável, preferível à leitura de doc: teste de integração com `supertest` sobre
   a `app` real afirmando **header a header** o que a API promete (`x-content-type-options`
   = `nosniff`, presença/ausência de `content-security-policy`, ausência de `x-powered-by`).
   Isso transforma a dúvida num oráculo permanente: um upgrade de helmet que mude o default
   passa a **quebrar o teste**, em vez de mudar a postura de segurança em silêncio.
4. Decidir e registrar: numa API que **só emite JSON**, uma CSP explícita com
   `default-src 'none'` + `frame-ancestors 'none'` é a postura defensável. Se a doutrina
   quiser CSP explícita em vez de default, isso é decisão para o perfil (ou para o
   `README.md` do projeto, que tem precedência) — não inferência.

**Por que importa.** O perfil afirma cobertura de headers que o revisor vai tratar como fato
ao aprovar código. Se a CSP não vem ligada (ou vem com policy pensada para página HTML, não
para API), a §6.2 promete uma defesa que não existe — e ninguém revisita uma linha já
escrita como concluída.

---

## 4. §6.2 — `express.json()` neutraliza `__proto__`?

**Afirmação do perfil (linhas 386–391):**

> "A crença é que o `body-parser` embutido no Express 5 já neutralize `__proto__`, mas isso
> **precisa ser confirmado** — o mitigador que **não** depende disso é o parse Zod na
> fronteira […] e nunca fazer merge recursivo de objeto do cliente."

**O que confirmar e como.**

1. Ler a documentação do **`body-parser`** (opção de JSON reviver e tratamento de
   `__proto__`) e o **CHANGELOG do body-parser e do Express 5**; conferir também se há
   advisory relevante no **GitHub Advisory Database** para a versão instalada
   (`npm --prefix mnemonicos-backend ls express body-parser`).
2. Teste de integração direto: `POST` numa rota real com corpo
   `{"__proto__": {"isAdmin": true}}` e depois `{"constructor": {"prototype": {"x": 1}}}`,
   afirmando que (a) um objeto literal criado depois da request **não** ganhou `isAdmin` e
   (b) a rota responde 422 pelo Zod, não 200.
3. Registrar a conclusão como regra, não como curiosidade: se o parser **não** neutraliza, a
   frase do perfil deve virar proibição explícita de `Object.assign`/spread recursivo e de
   qualquer lib de deep merge sobre objeto do cliente. Vale notar que a §8 do perfil já cita
   `overrides` para `deepmerge-ts` — então **existe** deep merge na árvore de dependências:
   verificar quem o usa e se algum caminho recebe dado externo.

**Por que importa.** Prototype pollution é escalada de privilégio silenciosa: um campo
`isAdmin` que "aparece" em todo objeto do processo derrota checagens de autorização escritas
corretamente. O perfil acerta ao apontar o mitigador independente (Zod), mas o revisor
precisa saber se há **uma** ou **duas** camadas.

---

## 5. §6.3 — `trust proxy` numérico e rate limit por instância

**Afirmação do perfil (linhas 411–417):**

> "[…] logo, o valor **numérico** (`app.set('trust proxy', 1)`) é o caminho. Que `1` seja o
> número correto de proxies confiáveis na plataforma de deploy (Vercel) precisa ser
> verificado no ambiente real: errar o número recoloca o bypass. E o contador em memória é
> **por instância** em serverless — proteção real exige store compartilhado."

**O que confirmar e como.**

1. Ler a documentação de **`trust proxy` do Express** e o guia de **troubleshooting de proxy
   do `express-rate-limit`** (a página que documenta `ERR_ERL_PERMISSIVE_TRUST_PROXY` e a
   opção `validate`), mais a documentação da plataforma de deploy sobre **quais headers de IP
   do cliente ela injeta** (`x-forwarded-for` e o header proprietário de IP real, se houver).
2. Medir em vez de deduzir: em ambiente de preview (**nunca** produção pública), logar
   temporariamente `req.ips`, `req.ip` e o `x-forwarded-for` bruto; então fazer uma request
   **com** `X-Forwarded-For` forjado no início da cadeia e verificar se `req.ip` muda. Se
   muda, o número está errado. Critério de aceite: **`req.ip` imune a header forjado pelo
   cliente**. Remover o diagnóstico depois.
3. Considerar o caminho que não depende de contar proxies: derivar a chave do rate limit do
   header de IP confiável da própria plataforma via `keyGenerator`, ou de identidade
   autenticada — e documentar a escolha.
4. Rate limit distribuído: decidir se há store compartilhado (Redis/Postgres) ou se o limite
   é declaradamente *best-effort*. Enquanto for em memória, o perfil deve dizer o **fator**:
   com N instâncias quentes, o teto real é ~N× o configurado.

**Por que importa.** São duas falhas independentes no mesmo mecanismo: número errado ⇒ o
atacante escolhe sua própria chave de rate limit (e envenena o log de auditoria e o bloqueio
por IP da §6.5); contador local ⇒ o limite anunciado não é o limite aplicado. Proteção
contra *brute force* de login que não funciona é pior que ausência dela, porque consta como
mitigada.

---

## 6. §6.4 — Semântica do `redact` do pino

**Afirmação do perfil (linhas 431–435):**

> "A semântica dos wildcards (`*.password` cobre **um** nível de aninhamento; caminho mais
> profundo exige entrada própria) precisa ser conferida na documentação da major do pino
> instalada […] e o `err` serializado pode arrastar `err.config`/`err.cause` com credencial
> dentro."

**O que confirmar e como.**

1. Ler a documentação de **`redact` do pino** (que delega a semântica de caminhos ao
   **`fast-redact`**) da major instalada — em especial a diferença entre wildcard de um nível
   e wildcard intermediário, o comportamento de `censor` e as limitações declaradas de
   caminhos com bracket notation. Versões:
   `npm --prefix mnemonicos-backend ls pino pino-http`.
2. Teste unitário com sink capturado — este é um teste **de segurança** e deveria ficar na
   suíte permanente: logar um objeto com segredo em vários níveis (`{ password }`,
   `{ user: { password } }`, `{ a: { b: { password } } }`, `{ headers: { authorization } }`,
   erro com `cause` aninhado carregando `authorization`, e uma `DATABASE_URL` com senha
   embutida) e afirmar que a string final **não contém** os valores sentinela. Cada caminho
   que passar cru é uma entrada de `redact` que falta.
3. Conferir o que o `pino-http` loga por padrão de `req`/`res` (headers inclusos?) e se o
   serializer de erro do pino percorre `cause` — o encadeamento por `Error.cause`
   recomendado na §5 do perfil é justamente o que pode arrastar o objeto original de um
   cliente HTTP (com `Authorization`) para dentro do log.
4. Complemento estrutural, se algum caminho escapar: sanear na origem (nunca passar
   `req.body` nem objeto de erro de lib HTTP para o logger), em vez de depender só da lista.

**Por que importa.** Expectativa errada sobre wildcard produz **vazamento silencioso**: o
log parece redigido (há um `[Redacted]` em algum lugar) enquanto o token viaja completo um
nível abaixo. E log é o sink de onde o segredo é mais difícil de retirar — sai para o
agregador, o backup e a retenção. Vazou ⇒ **rotação obrigatória**; não é conserto de código.

---

## 7. §6.4 — Argon2id no Node 22 e escolha de parâmetros

**Afirmação do perfil (linhas 436–440):**

> "Senha: hash com **Argon2id** (parâmetros OWASP atuais) ou bcrypt com custo ≥12. Node 22
> **não** traz Argon2 no core — o built-in disponível é `crypto.scrypt`; Argon2id exige
> dependência (`argon2` nativo ou `@node-rs/argon2`). A escolha, e os parâmetros de
> memória/tempo, devem ser decididos com a documentação da lib e do OWASP na mão."

**O que confirmar e como.**

1. Ausência no core: checar a documentação do **`node:crypto`** da linha 22 (a lista de KDFs
   expostas — `scrypt`, `pbkdf2`, `hkdf`) e confirmar que Argon2 não aparece. Verificação
   rápida no runtime do ambiente-alvo: inspecionar as chaves exportadas por `node:crypto`
   procurando `argon` — deve dar lista vazia.
2. Parâmetros: ler a **OWASP Password Storage Cheat Sheet** vigente e transcrever os valores
   recomendados de Argon2id (memória, iterações, paralelismo) e o custo de bcrypt — **com a
   data da consulta**, porque esses números sobem com o tempo e parâmetro citado sem data
   envelhece como fato.
3. Escolher a dependência com a régua da §8: `argon2` compila nativo (node-gyp — verificar se
   o build funciona no runtime serverless do deploy e no CI); `@node-rs/argon2` distribui
   binário pré-compilado por plataforma (verificar se há binário para a plataforma-alvo).
   Registrar qual foi escolhida **e por quê**.
4. Restrição desta stack, que o item precisa resolver junto: hashing de senha é **CPU-bound**.
   A §10 proíbe bloquear o event loop e a plataforma tem limite de tempo/memória por
   invocação — validar que os parâmetros escolhidos rodam dentro do orçamento da função
   (medir a latência real de `hash` e `verify`) e usar **sempre** a API assíncrona.
   Parâmetro forte demais para o ambiente vira DoS de login; fraco demais anula o item.
5. Pré-requisito de escopo: não existe autenticação implementada hoje. Este item deve ser
   fechado **antes** da primeira rota autenticada (mesmo gate dos itens 8 e 9).

**Por que importa.** Escolha de KDF e de parâmetros é decisão irreversível na prática: o hash
gravado no banco carrega o custo com que foi criado, e migrar exige re-hash no login de cada
usuário. Errar aqui é dívida que só se paga no vazamento do dump.

---

## 8. §6.5 — `sameSite`, cenário cross-site e CSRF

**Afirmação do perfil (linhas 451–455):**

> "Front em **domínio diferente** do backend + `credentials: true` no CORS costuma forçar
> `sameSite: 'none'`, que por sua vez **exige** `secure: true` — e `none` remove a proteção
> CSRF do cookie, exigindo token anti-CSRF ou verificação de `Origin` no servidor. A
> combinação válida para o par de domínios deste deploy precisa ser verificada em ambiente
> real antes de expor rota autenticada."

**O que confirmar e como.**

1. Determinar o **fato de infraestrutura** primeiro: em produção, frontend e backend ficam no
   mesmo *site* (mesmo domínio registrável — ex.: `app.exemplo.com` e `api.exemplo.com` ⇒
   same-site, `sameSite: 'lax'` funciona) ou em sites diferentes (dois subdomínios de
   plataforma distintos ⇒ cross-site, exige `none`)? Isso decide todo o resto e não é
   inferível do código, só do deploy. Vale checar se domínio próprio para a API está no plano
   — ele converte o problema no caso fácil.
2. Ler a documentação de **`Set-Cookie` / atributo SameSite (MDN)** e a **OWASP CSRF
   Prevention Cheat Sheet** para fixar o par (atributo escolhido × mitigação exigida):
   `lax` + verificação de `Origin`, ou `none` + `secure` + token anti-CSRF (double-submit ou
   synchronizer token).
3. Verificar em ambiente real (preview deploy), **não** em `localhost` — `localhost` conta
   como contexto seguro e mascara o requisito de `secure`. Critério: a request autenticada do
   front **chega com o cookie**, e a mesma request disparada de origem terceira **é
   rejeitada**.
4. Escrever os dois testes de integração que ficam: (a) a resposta de login traz
   `Set-Cookie` com todas as flags esperadas (`HttpOnly`, `Secure`, `SameSite=<escolhido>`,
   `Path`, `Max-Age`); (b) request autenticada com `Origin` fora da allowlist recebe 403 — é
   este teste que cobre o furo aberto por `sameSite: 'none'`.
5. Se a decisão for token anti-CSRF, ela é **desenho** e não cabe numa linha do perfil:
   promover ao ciclo junto com o item 9.

**Por que importa.** Errar para o lado frouxo (`none` sem contra-medida) entrega CSRF em toda
rota mutante autenticada; errar para o lado rígido (`lax` em cenário cross-site) produz uma
sessão que simplesmente não funciona em produção — e o reflexo, sob prazo, é afrouxar sem
projetar. Decidir antes da primeira rota autenticada é o único momento barato.

---

## 9. §6.5 — Rotação e revogação de refresh token em serverless

**Afirmação do perfil (linhas 461–465):**

> "Access token curto (`JWT_EXPIRES_IN` = `15m`) + refresh token com **rotação e revogação**.
> […] O desenho de rotação/revogação apropriado ao serverless (onde não há memória
> compartilhada) ainda não existe neste projeto e precisa ser especificado antes da primeira
> rota autenticada."

**O que confirmar e como.** Este item não se resolve lendo documentação: é **lacuna de
desenho** declarada, e o encaminhamento correto é promovê-la ao ciclo (brief → `specify`),
não fechá-la aqui com uma frase.

1. Referências para o desenho: **OWASP Authentication Cheat Sheet** e **Session Management
   Cheat Sheet** (tempo de vida, rotação, detecção de reuso, logout do lado do servidor) e a
   documentação da lib de JWT que for adotada (`npm --prefix mnemonicos-backend ls jsonwebtoken jose`
   — a API de verificação difere entre elas).
2. Decisões que a SPEC precisa fixar, cada uma com AC testável: onde vive o estado do refresh
   token (tabela no Postgres é a resposta natural aqui, já que não há memória compartilhada
   nem Redis) · armazena-se **hash** do token, nunca o valor · rotação a cada uso, com
   invalidação do anterior · **detecção de reuso** de token rotacionado ⇒ revogar a família
   inteira · revogação em logout e em troca de senha · expurgo dos expirados.
3. Enquanto esse desenho não existir, a regra operacional que o perfil já implica deve ser
   dita como tal: **não expor rota autenticada**. É bloqueio de escopo, não recomendação.
4. Testes que provam o item, quando implementado: reuso de refresh token rotacionado devolve
   401 **e** invalida a família; logout invalida de fato (segunda chamada com o mesmo refresh
   falha); access token expirado não passa.

**Por que importa.** JWT *stateless* sem estado de revogação significa que **não existe
logout** no servidor: token roubado vale até expirar e não há botão de emergência. É a falha
que aparece só no incidente — quando já não há como cortar a sessão do atacante.

---

## 10. §6.6 — Ausência de guarda de SSRF no `fetch`/undici e comportamento de redirect

**Afirmação do perfil (linhas 472–477):**

> "Não há guarda de SSRF embutida no `fetch`/undici do Node 22 (nem bloqueio de IP privado, e
> redirect é seguido por padrão) — validar a URL **antes** não impede o redirect para IP
> interno, então o controle precisa ser no host resolvido/`redirect: 'manual'`."

**O que confirmar e como.**

1. Confirmar o default de `redirect` do `fetch` no Node 22 na documentação da **Fetch API do
   Node** e na do **undici** (`maxRedirections` / handler de redirect), e que não há
   filtragem de destino privado. Teste local: servidor HTTP efêmero que responde 302 para
   `http://127.0.0.1:<porta>`, afirmando que o `fetch` **seguiu** o redirect.
2. Ler a **OWASP SSRF Prevention Cheat Sheet** e escolher a forma que o projeto adota —
   porque a §6.6 hoje descreve o problema melhor que a solução. O controle robusto é:
   allowlist de host → resolver o nome (`dns.promises.lookup`) → rejeitar
   privado/loopback/link-local/CGNAT/IPv6 mapeado → conectar **ao IP** preservando o `Host`
   original (via `lookup` customizado no dispatcher do undici), fechando a janela de **DNS
   rebinding** entre validar e conectar. Alternativa mais simples e defensável:
   `redirect: 'manual'` + revalidação de cada `Location` no mesmo pipeline.
3. Confirmar se há **caminho ativo** hoje: `grep -rn "fetch(" mnemonicos-backend/src`. Se
   nenhuma chamada de saída recebe URL derivada de entrada do usuário, o item é
   **preventivo** — e deve ser dito assim no perfil, com o gate explícito: a primeira chamada
   de saída com URL do usuário abre o desenho antes do merge.
4. Preservar o que já é regra e é fácil de perder no meio da discussão de SSRF:
   `AbortSignal.timeout()` **sempre** — `fetch` sem timeout é o item de disponibilidade
   colado a este.

**Por que importa.** Em plataforma de nuvem, SSRF alcança o endpoint de metadados
(`169.254.169.254`) e serviços internos sem autenticação de rede — é o caminho conhecido para
credenciais de instância. A frase do perfil, como está, poderia ser lida como "valide a URL e
pronto", que é exatamente a mitigação que o redirect derrota.

---

## Nota de escopo

Fora da régua de tags: a §9 do perfil registra `⚠️ ainda não configurada` para os guards
determinísticos de ESLint (`no-restricted-imports` para o client gerado do Prisma e para
`process.env`). Aquilo **não** é afirmação a confirmar — é melhoria conhecida do projeto, com
dono no `README.md` das guidelines, e não bloqueia a promoção deste perfil a `reviewed: true`.
