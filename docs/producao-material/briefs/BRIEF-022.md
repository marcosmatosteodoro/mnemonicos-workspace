# BRIEF-022: Biblioteca visual reutilizável

**Slug**: producao-material
**Status**: Emitido
**Data**: 2026-09-13
**Largada**: 2026-09-13T15:33:11+0000 (UTC — tzdata America/Sao_Paulo indisponível neste ambiente; ambiente Windows, mesma limitação de sessões anteriores)
**SPEC**: SPEC-022
**Epico**: docs/producao-material/briefs/BRIEF-2026-08-27-mnemora-studio-epic.md
**Jira**: KAN-85

## Pedido como dito

> Continuar com a fatia 5 do épico MNEMORA STUDIO: "Biblioteca visual reutilizável" —
> confirmado pelo Diretor via `/keelson:continue producao-material`, seguindo a fila do
> BRIEF épico (F5, depende de F4, entregue).

## Interpretação do PO

**Contexto**: F4 entregou a Tira mnemônica (`MnemonicStrip`/`MnemonicFrame`, sequência de
Quadros de texto livre). A TAP (BRIEF-001) nomeia a camada 4 do método como **Associação
visual** — imagem/cena/símbolo a serviço da recuperação da regra, "reprovada quando sua
remoção não faz perder função cognitiva" — e pede uma "Biblioteca Visual" navegável por
categoria/estilo (tela nomeada nas telas sugeridas), motivada pelo risco crítico da própria
TAP: "se cada página se tornar artesanal demais, o modelo não escala" — tratado com
biblioteca de ícones/imagens reutilizáveis.

**Pedido**: modelar e produzir a Biblioteca visual — acervo de associações visuais
(imagem + categoria/estilo + descrição textual da função cognitiva que ela cumpre)
upload-ável e reutilizável entre Quadros de Tiras mnemônicas diferentes, com tela de
navegação/busca por categoria e vínculo (N:N — a mesma associação visual serve a mais de
um Quadro) a partir da tela da Tira mnemônica (F4).

**Premissas decididas**:
- Formato aceito: raster (PNG/JPEG/WebP) — **sem SVG cru**, pelo risco já declarado do
  épico (upload de SVG sem sanitização é vetor de XSS/XXE, A02/A08); reabrir só se a
  fábrica precisar de vetor editável, decisão de F6 (motor de PDF) em diante.
- Validação de tipo/tamanho é **server-side** (assinatura de bytes, não só extensão/MIME
  declarado pelo cliente) — antecipa a mesma régua que F6 (motor de publicação PDF) vai
  exigir para qualquer asset que entra no pipeline de exportação.
- Armazenamento do binário fica como decisão técnica do PLAN (filesystem local vs. blob
  externo) — sem infra de object storage contratada ainda; reversível.
- Reuso é modelado como associação N:N entre `MnemonicFrame` e a associação visual (mesma
  imagem ilustra Quadros de Tiras diferentes) — é o que "reutilizável" no nome da fatia
  exige; sem isso, a fatia degenera em upload de imagem por Quadro (sem biblioteca).

**Fora de escopo**: motor de publicação PDF/diagramação (F6 — esta fatia só produz o
acervo, não a saída), contrastes/pegadinhas/flashcards impressos (F7), versionamento
editorial e fechamento legislativo (F8), gate de qualidade/aprovação (F9), painel
estratégico (F10), geração/sugestão automática de imagem (IA generativa) — fora do
inventário original do PM e sem pedido do Diretor.

## Estimativa — Biblioteca visual reutilizável (2026-09-13)

- **Base**: pedido (BRIEF-022, 4 premissas já decididas) · `MAP.md` de producao-material ·
  INDEX estruturais do mesmo épico (PLAN-003 16t/7w · PLAN-006 14t/5w · PLAN-010 3t/3w ·
  PLAN-012 13t/7w) · ficha (`gates.security: true`, `screenVerify` ativo, `e2e`/`mutation`
  `null`) — **sem base histórica** de tempo: `guidelines/project/estimates.md` tem 1
  demanda fechada (mínimo 3), nenhum corretor aplicado.
- **Dimensão**: ~7 waves · ~16 tasks (~9 small · ~7 medium)
- **Por fase**: forja 1–3h · artefatos 4–10h · implementação 14–55h · gates 8–25h
- **Total**: 27–93h (horas de ciclo, não prazo de calendário)
- **Confiança**: média — estrutura bem ancorada em 4 fatias comparáveis do mesmo épico;
  faixa larga porque upload/persistência de binário é greenfield nos dois repos e o único
  par realizado do projeto fechou 4–10× abaixo do piso estimado — 1 ponto não calibra.
- **Premissas**: storage filesystem local (reversível, sem object storage contratado);
  categoria/estilo como enum fechado espelhado cross-repo; validação por assinatura de
  bytes sem processamento de imagem (sem resize/thumbnail/strip EXIF); vínculo N:N reusa a
  cadeia de autoria de F4 (Frame→Strip→RuleBreakdown→RawContent); as 2 telas caem no gate 9
  `screenVerify` (risco de handoff remoto, como em PLAN-013); gate 8 com margem de re-gate
  (A01 authz do binário/path traversal, A05 tipo/tamanho, A06/A10 DoS por tamanho/volume).
- **Lacunas**: quem pode ver o binário (público por URL vs. stream autenticado) · teto de
  tamanho por arquivo e volume do acervo · categoria/estilo como lista fechada definida
  agora vs. taxonomia editável pelo EDITOR (editável = +1 wave) · busca por categoria+texto
  basta, ou precisa full-text.

## Cronologia
