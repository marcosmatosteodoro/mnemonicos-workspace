# TASK-013-002: Criar manifesto de aplicação (`app/manifest.ts`)

**Slug**: producao-material
**Pertence a**: PLAN-013
**Realiza (FRs)**: FR-013-001, FR-013-002, FR-013-003, FR-013-004
**Componente**: COMP-013-001 (principal), COMP-013-002
**Wave**: 2
**Tamanho estimado**: small
**Tipo**: feature
**Status**: Todo

## Convenções (do projeto)

**Branch sugerida**: `feat/producao-material-pwa-support` — **cwd obrigatório do
`developer`**: `C:/kwt/pwa/mnemonicos-frontend` (worktree isolado). **NUNCA** rodar
`dev`/`test`/`lint`/`typecheck`/`build` em `mnemonicos-frontend/` da working tree
principal — outra sessão executa PLAN-012/F4 ali concorrentemente (RISK-013-005,
TRISK-013-002).
**Padrão de commit**: Conventional Commits (`feat:`).
**Framework de teste**: Jest 30 + `next/jest`. Este teste é de função pura (chamada direta,
sem `jsdom` — molde de teste de função pura, PLAN §3/COMP-013-001).

## Dependências

- **Depende de**: TASK-013-001
- **Bloqueia**: TASK-013-003

## Contexto

`mnemonicos-frontend/src/app/layout.tsx:13-27` já declara `metadata`/`viewport` (Metadata
API nativa) — `app/manifest.ts` é a mesma família de convenção (Next ≥13), mesmo nível de
`layout.tsx` (memo, item 1/3). Nenhum `manifest.ts` existe hoje. Esta TASK declara nome,
ícones (dos arquivos criados em TASK-013-001), cores de tema e `display: "standalone"`,
com `start_url` neutro e sem `shortcuts` (postura de exposição, NFR-013-007).

## Escopo

### Inclui
- `mnemonicos-frontend/src/app/manifest.ts` — `export default function
  manifest(): MetadataRoute.Manifest`, exposto automaticamente em
  `/manifest.webmanifest` pelo Next.
- Campos: `name`/`short_name` (identidade visual atual, A-013-002), `icons` (referenciando
  `/icons/icon-192.png` e `/icons/icon-512.png`, `purpose: "any"`, `type: "image/png"`),
  `theme_color`/`background_color` — **usar os mesmos valores literais já em
  `layout.tsx:24-25`** (`#f6f7f9`/`#0a0d13`), nunca reinventar/re-derivar um par novo de
  cor —, `display: "standalone"`, `start_url: "/"` (neutro, funciona com e sem sessão
  ativa).
- **Sem `shortcuts`** (NFR-013-007) — declaração explícita de ausência, não omissão
  silenciosa.

### Não inclui
- Ícone `maskable` (Out-of-scope, SPEC-013 §4.2).
- Lista de precache do service worker (NFR-013-007 também exige isso — parte de
  AC-013-010; essa metade é da TASK-013-003, que depende desta).
- A cobertura de **AC-013-001**/**AC-013-002** (prompt de instalação, nome/ícone no app
  instalado) fecha só por gate 9 na TASK-013-005, que depende desta.
- Nenhum controle de instalação custom (banner/botão) — A-013-004/SPEC-013 §4.2.

## Implementação sugerida

Passos NÃO-VINCULANTES — em tensão com os "Critérios de pronto", os critérios prevalecem;
nunca siga um passo que enfraqueça um critério.

1. Criar `src/app/manifest.ts` como função pura, sem `'use client'`, sem estado (perfil
   §4 — Server Component/função de rota, nunca hook).
2. Referenciar os dois ícones de `public/icons/` (TASK-013-001) com os tamanhos exatos.
3. Copiar `theme_color`/`background_color` literalmente de `layout.tsx:24-25` — não
   recalcular a partir dos tokens CSS (manifesto JSON não lê `@theme`).

## Critérios de pronto

- [ ] `manifest.ts` exporta `name`, `short_name`, `icons` (192 e 512, `purpose: "any"`),
      `theme_color`, `background_color`, `display: "standalone"`, `start_url: "/"`, e
      **não** declara `shortcuts`.
- [ ] Testes cobrem AC-013-010 (parte — manifesto: `start_url` neutro e ausência de
      `shortcuts` apontando rota interna; a parte "precache restrito a estáticos" é da
      TASK-013-003) — verificação executável: `npx jest --runTestsByPath
      src/app/manifest.test.ts` → `OK (N tests)`, chamando `manifest()` diretamente e
      afirmando `start_url === '/'` e `shortcuts` ausente/vazio; fixada antes do código.
- [ ] Teste confirma `theme_color`/`background_color` idênticos aos literais de
      `layout.tsx:24-25` (contrato do item, sem AC associado) — mesmo comando acima cobre.
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`), produção e teste.
- [ ] Padrão de commit respeitado.
- [ ] Aderência à stack/padrões da ficha e do perfil de linguagem (função pura, sem
      `'use client'`, sem I/O — perfil §4).
- [ ] Code review aprovado.

## Riscos específicos

- Nenhum — riscos do manifesto em si já cobertos por A-013-002 (aceito).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 
**Data conclusão**: 
**Branch**: 
**Commit SHA**: 
**Jira**: KAN-66
**Implementado por**: 
**Revisado por**: 
**Tentativas**: 
**Cobertura final**: 
**Arquivos modificados**:
  - 

**Quality gates**:
- [ ] Implementação completa
- [ ] Testes passando
- [ ] Lint limpo
- [ ] Aderência à ficha/perfil
- [ ] Code review aprovado
- [ ] ACs verificados
- [ ] Segurança (gate 8): aprovado | n/a — <security-engineer ou motivo do n/a>
- [ ] Comportamento (gate 9): consolidado <FEAT-NNN-XXX | DoD, Etapa 4> | verificado | pendente_handoff | n/a — <qa, consolidação ou motivo do n/a; enum, forma preenchida e régua do "verificado": implement.md §3.4.1 (4.291)>

**Notas**: 
