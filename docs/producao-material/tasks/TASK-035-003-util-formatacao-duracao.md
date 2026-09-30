# TASK-035-003: Util de formatação de duração pt-BR

**Slug**: producao-material
**Pertence a**: PLAN-035
**Realiza (FRs)**: nenhuma
**Componente**: COMP-035-019
**Wave**: 1
**Tamanho estimado**: small
**Tipo**: chore
**Status**: Done

## Dependências

- **Depende de**: nenhuma
- **Bloqueia**: TASK-035-008

## Contexto

Único ponto de formatação de tempo do Painel (FR-034-006, exibido só na TASK-035-008) —
nenhuma seção da tela reimplementa `Intl`/cálculo de duração. Território e precedentes:
`docs/producao-material/MAP.md` (nenhum util de data/duração existe hoje em
`mnemonicos-frontend/src/lib/` — `content-version-history.tsx:39-47` usa
`Intl.DateTimeFormat` por módulo, para DATA pura, não duração), e PLAN-035 §3
(COMP-035-019).

## Escopo

### Inclui

- `mnemonicos-frontend/src/lib/format-duration.ts` (novo):
  ```ts
  /**
   * Formata uma duração em milissegundos como texto pt-BR legível (ex.: "3 dias e 4
   * horas") — único ponto de formatação de tempo do Painel estratégico (FR-034-006,
   * COMP-035-019). Lead time de calendário (A-034-003): unidades de dia/hora/minuto,
   * arredondadas para baixo, sem casas decimais.
   */
  export function formatDurationPtBr(ms: number): string {
    const totalMinutes = Math.floor(ms / 60_000);
    const days = Math.floor(totalMinutes / (24 * 60));
    const hours = Math.floor((totalMinutes % (24 * 60)) / 60);
    const minutes = totalMinutes % 60;

    const parts: string[] = [];
    if (days > 0) parts.push(`${days} ${days === 1 ? 'dia' : 'dias'}`);
    if (hours > 0) parts.push(`${hours} ${hours === 1 ? 'hora' : 'horas'}`);
    if (parts.length === 0 && minutes > 0) {
      parts.push(`${minutes} ${minutes === 1 ? 'minuto' : 'minutos'}`);
    }
    if (parts.length === 0) return 'menos de 1 minuto';
    if (parts.length === 1) return parts[0]!;
    return `${parts[0]} e ${parts[1]}`;
  }
  ```
  Regra de composição: no máximo 2 unidades (dia+hora, nunca dia+hora+minuto — minuto só
  aparece quando dias E horas são 0, mesmo grão de granularidade que "lead time de
  calendário" pede, A-034-002/A-034-003 — não é um cronômetro de precisão).
- `mnemonicos-frontend/src/lib/format-duration.test.ts` (co-localizado, perfil §7): 1 caso
  por combinação observável — 0 (< 1 min) → `'menos de 1 minuto'`; 45 min → `'45 minutos'`;
  1 min → `'1 minuto'` (singular); 2h30 → `'2 horas'` (minuto descartado quando há hora,
  nunca "2 horas e 30 minutos" — grão de 2 unidades no máximo, dia+hora); 1h → `'1 hora'`
  (singular); 3 dias e 4 horas → `'3 dias e 4 horas'`; 1 dia e 1 hora →
  `'1 dia e 1 hora'` (singular nos dois); 10 dias, 0 horas → `'10 dias'` (hora zerada não
  aparece colada por "e").

### Não inclui

- Qualquer chamada a `formatDurationPtBr` — TASK-035-008 (seções do Painel).
- Formatação de DATA (já resolvida por `Intl.DateTimeFormat` em outros componentes,
  padrão existente, não tocado aqui).

## Critérios de pronto

- [ ] Testes cobrem os 8 casos acima (contrato do próprio item — sem AC, decisão 4.286:
      cada combinação observável exercitada com valor não-nulo) — verificação executável:
      `npm --prefix mnemonicos-frontend test -- format-duration.test.ts` → `OK (8 tests)`.
      Fixada antes do código.
- [ ] Grão de no máximo 2 unidades, nunca 3 — mutante: remover o `if (parts.length ===
      1)` (deixando sempre `parts.join(' e ')` sem limite) faz o caso "3 dias, 4 horas, 30
      minutos" (se algum teste cobrir 3 unidades cheias) divergir do esperado — o teste de
      "2h30" acima já é esse mutante: sem o descarte de minuto quando há hora, o resultado
      seria `'2 horas e 30 minutos'`, e o `toBe('2 horas')` do caso reprova.
- [ ] Singular/plural corretos nos 2 pontos de fronteira (1 dia, 1 hora, 1 minuto) — já
      cobertos nos casos acima; mutante que trocar `days === 1 ? 'dia' : 'dias'` por
      sempre `'dias'` reprova o caso "1 dia e 1 hora".
- [ ] Sem warnings/lints novos sobre TODOS os arquivos do diff
      (`git diff --name-only main...HEAD`) — `npm --prefix mnemonicos-frontend run lint`
      → exit 0.
- [ ] Code review aprovado.

## Riscos específicos

- Nenhum — função pura, sem I/O, sem dependência de fuso horário (opera só sobre a
  diferença em milissegundos já calculada pelo chamador, TASK-035-004/008).

---

## Histórico de execução (preenchido pelo /keelson:implement)

<!-- /keelson:implement preenche durante closure. Não editar manualmente. -->

**Data início**: 2026-09-30T03:23:59-0300
**Data conclusão**: 2026-09-30T03:55:43-0300
**Commit SHA**: 6cf87ca (impl) · a78437e (retry gate 6)
**Jira**: KAN-170

**Quality gates**:
- [x] Implementação completa
- [x] Testes passando
- [x] Lint limpo
- [x] Aderência à ficha/perfil
- [x] Code review aprovado
- [x] ACs verificados
- [x] Segurança (gate 8): aprovado — security-engineer (wave 1; função pura sem superfície sensível)
- [x] Comportamento (gate 9): consolidado FEAT-034-002 — carregador: roteiro do gate 9 da TASK-035-008 (durações exibidas no Painel)
