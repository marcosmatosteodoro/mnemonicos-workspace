# Produção de Material

> Arquivo gerado automaticamente. Não edite manualmente.
> Para alterar conteúdo, use /keelson:specify, /keelson:plan, /keelson:tasks ou /keelson:implement.

**Slug**: producao-material
**Última atualização**: 2026-08-29T01:35:00-03:00
**Mapa do território**: MAP.md

## Resumo

Fábrica interna de produção do material mnemônico: o acervo estruturado (10 camadas do método,
tira como sequência de quadros) entra, o PDF diagramado sai — com versão, data de fechamento de
legislação e checklist de revisão jurídica. O estudante não é usuário deste software; o que ele
compra é o PDF. A régua de valor é tempo de produção por página, instrumentado por etapa.

## Capacidades

### Implementadas
(vazio até a primeira entrega)

### Em desenvolvimento
- Autenticação de sessão da equipe interna (SPEC-002/FEAT-002-001, PLAN-003, 🟡 3/5 tasks Done)
- Autorização por papel deny-by-default no servidor (SPEC-002/FEAT-002-002, PLAN-003, 🟡 0/3 tasks Done)
- Provisionamento de contas internas por ADMIN + seed do 1º ADMIN (SPEC-002/FEAT-002-003, PLAN-003, 🟡 2/3 tasks Done)

### Especificadas, ainda não planejadas
(nenhuma — SPEC-002 coberta por PLAN-003)

_Épico MNEMORA STUDIO decomposto em 11 fatias (BRIEF-2026-08-27-mnemora-studio-epic); F1 em ciclo (BRIEF-002)._

## SPECs

| ID | Título | Status | Data |
|----|--------|--------|------|
| SPEC-002 | Acesso interno e papéis de produção | Approved | 2026-08-28 |

## PLANs

| ID | Cobre | FRs cobertos | Tasks | Status |
|----|-------|--------------|-------|--------|
| PLAN-003 | SPEC-002 | 24/24 FRs + 9 NFRs (autenticação de sessão, autorização deny-by-default, gestão de contas por ADMIN) | 9/16 🟡 | Approved |

## Glossário consolidado

| Termo | Definição | Origem |
|-------|-----------|--------|
| Tira mnemônica | Sequência ordenada de quadros que reconstrói uma regra (CONCEITO → AÇÃO → OBJETO → CONDIÇÃO/EXCEÇÃO) | BRIEF-001 |
| Quebra da regra | Decomposição do texto normativo bruto nos cinco blocos, mais a síntese da regra | BRIEF-001 |
| Radar de prova | Classificação por risco de prova: alta, média, detalhe, exceção, pegadinha | BRIEF-001 |
| Associação visual | Imagem/cena/símbolo a serviço da recuperação; reprovada se removê-la não perde função cognitiva | BRIEF-001 |
| Versão aprovada | Checagem jurídica e pedagógica passaram; material liberado para exportação (gate) | BRIEF-001 |
| Fonte normativa | Dispositivo oficial que sustenta a regra (CF, CTN, lei, LC, súmula, ato normativo) | BRIEF-001 |
| Fechamento legislativo | Data até a qual a legislação foi verificada para aquela versão | BRIEF-001 |
| Sessão autenticada | Vínculo entre uma requisição e uma conta interna ativa, estabelecido por login e válido enquanto não expira nem é revogado | SPEC-002 |
| Credencial de acesso | Prova de sessão de vida curta (~15 min) em cookie inacessível a script, conferida a cada requisição | SPEC-002 |
| Token de renovação | Segredo de vida mais longa, persistido de forma revogável, que troca uma credencial de acesso expirada por uma nova sem novo login | SPEC-002 |
| Rotação de token | A cada renovação, o token usado é invalidado e um novo é emitido; apresentar um token já rotacionado é sinal de reuso | SPEC-002 |
| Família de sessão | Conjunto de tokens de renovação encadeados por rotação a partir de um mesmo login; revogada por inteiro em reuso ou logout | SPEC-002 |
| Papel | Atributo da conta: STUDENT (dormente), EDITOR (produção/autoria), ADMIN (gestão de contas + revisão jurídica + aprovação de versão) — enum inalterado | SPEC-002 |
| Deny-by-default | Postura em que uma rota é inacessível a menos que declare explicitamente os papéis que a alcançam; ausência de declaração nega | SPEC-002 |
| Conta desativada | Conta marcada inativa de forma reversível, com marca temporal; não autentica e tem as sessões revogadas | SPEC-002 |
| Provisionamento de conta | Criação de conta interna por um ADMIN ou pelo seed — nunca por auto-registro | SPEC-002 |
| Auditoria de autenticação | Registro dos eventos de login, renovação, logout, bloqueio temporário e decisão de autorização, sem dado sensível | SPEC-002 |

## Decisões irreversíveis

(nenhuma — as 12 DECs de PLAN-003 são todas reversíveis; ver §6 do PLAN para as condições `Reabrir se:`)

## Riscos ativos

| ID | Risco | Mitigação | Origem |
|----|-------|-----------|--------|
| PIL-001 | Teste da tira aprovado sem limiar (Q-11) e cinco das seis métricas da §5.4 sem instrumento (Q-12) — não bloqueiam a SPEC, bloqueiam a conclusão do piloto | decidir antes do beta; retomar via /keelson:brief producao-material | BRIEF-001 |
| RDR-001 | Mapeamento entre as cinco classes do radar de prova (TAP §3.2) e as três prioridades das telas sugeridas não está decidido | resolver como premissa na SPEC da fatia F2 | BRIEF-001 |
| RISK-002-001 | "Revisor jurídico ≠ autor" (A-010) inexequível com operação de 1 pessoa; com o papel de revisão acumulado no ADMIN, com 1 pessoa o gate de "Versão aprovada" de F9 fica só em disciplina operacional | 2 ADMINs distintos no piloto (A-002-017); F9 decide se separa o papel de revisor | SPEC-002 §9 |
| RISK-002-002 | Token de renovação persistido é superfície de dado sensível — vazamento do repositório permitiria continuar sessões | guardar só o necessário, valores não reversíveis onde viável, revogar família em reuso, expiração absoluta curta (7 dias) | SPEC-002 §9 |
| RISK-002-003 | Dependências novas de criptografia/sessão (derivação de senha, geração de token, leitura de cookie) entram na árvore — superfície de cadeia de suprimento | gate de auditoria de dependências sobre o diff de F1 (/keelson:audit); fixar versão e revisar | SPEC-002 §9 |
| TRISK-003-001 | `trust proxy: 1` pode ser o nº errado de proxies no deploy — erra `req.ip` e recoloca o bypass do freio de login; contador do rate-limit é por instância em serverless | verificar no ambiente real; store compartilhado para proteção multi-instância (fora do escopo de F1) | PLAN-003 §8 |
| TRISK-003-002 | Cookie cross-domain (SameSite=None + anti-CSRF) não desenhado; F1 assume mesmo site | verificação de `Origin`/`Host` nas rotas POST de auth agora; token anti-CSRF quando o deploy for cross-domain | PLAN-003 §8 |

## Histórico recente

- 2026-08-28: PLAN-003 decomposto em 15 TASKs / 7 waves via /keelson:tasks; sync Jira (gancho tasks) — 15 sub-tasks KAN-11..KAN-25 sob KAN-8/KAN-9/KAN-10
- 2026-08-28: Etapa 3.5 (verificabilidade pré-código) — qa pré-código resolvido (18 achados); PO fixou deny-by-default "por papel" (leitura B): DEC-003-005 emendada com registro central ROUTE_ROLES (rota sem declaração nega 403 mesmo com sessão válida) — custo adicional de F1 pendente de veto do Diretor na entrega
- 2026-08-28: furo no plano em TASK-003-002 — a suíte de teste do backend não abre conexão com banco (`tests/setup-env.ts` fictício), mas 6 TASKs assumem integração com Prisma real — destino: TASK-003-016 nova (harness de integração, COMP-003-025) na Wave 2, PLAN-003 emendado
- 2026-08-28: sync Jira pulado (sub-task de TASK-003-016) — `atlassianUserInfo` / `getAccessibleAtlassianResources` retornaram AWS WAF "Human Verification" CAPTCHA em vez de JSON — conector bloqueado nesta execução; reconciliar via /keelson:jira-sync quando voltar (parent-alvo KAN-8)
- 2026-08-28: Wave 1 do PLAN-003 fechada (TASK-003-001/002/005 Done) — gate 8 reprovou e convergiu em 1 retry (fail-open no COOKIE_SECURE, redação do pino, contrato HMAC); errata propagada ao PLAN e TASKs; 2 lições registradas (pendentes de merge)
- 2026-08-28: Wave 2 do PLAN-003 fechada (TASK-003-016 harness de integração, -003 libs cripto/audit, -004 rotação pura) — gates 1–8 aprovados após 1 retry de convergência (precedência de ramos falsificável, prova de params de env, guarda fail-closed do banco de teste); 2 lições registradas (pendentes de merge)
- 2026-08-29: furo no plano em TASK-003-006 — `refresh`/`logout` emitem eventos de auditoria mas suas assinaturas não recebiam `ip`, obrigatório em `AuthAuditEvent` (audit.ts selado na Wave 2) por NFR-002-005 — destino: `refresh`/`logout` passam a receber `ctx: { ip; userAgent? }` (aditivo; rota passa `req.ip`); PLAN + TASK-003-006/009 emendados
- 2026-08-29: DEC-003-003 emendada (decisão degrau 1 do Tech Lead, veto na Entrega) — cláusula `replay-grace` idempotente era infeasible sob DEC-003-002 (só hashes persistidos); replay-grace passa a tratar como rotate (nova ponta, sem revogação/token.reuse na graça); cliente serializa o refresh (TASK-003-013)
- 2026-08-29: Wave 3 do PLAN-003 fechada (TASK-003-006 auth.service, -008 freio de login, -012 seed do 1º ADMIN) — gates 1–10 aprovados após 1 retry de convergência + 1 furo no plano (ctx de origem); 3 lições registradas (pendentes de merge)
