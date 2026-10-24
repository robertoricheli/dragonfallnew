# 🧠 KARPATHY GUIDELINES — REGRAS DE CÓDIGO DO DRAGONFALL (Godot)

> **REGRA DO PROJETO (solicitada pelo dono):** o jogo, PARA SER ALTERADO,
> deve seguir estes princípios **à risca**. Toda mudança de código deste
> repositório nasce e é revisada contra este arquivo.
> Adaptado de
> [andrej-karpathy-skills / karpathy-guidelines](https://github.com/multica-ai/andrej-karpathy-skills/blob/main/skills/karpathy-guidelines/SKILL.md)
> (diretrizes comportamentais derivadas das observações de Andrej Karpathy
> sobre erros comuns de LLMs ao codar), com as regras locais do
> `MANUAL_DE_REGRAS.md` (fonte da verdade do jogo).
>
> **Trade-off:** estas regras priorizam cautela sobre velocidade. Para tarefas
> triviais, use julgamento.

---

## 1. Pense antes de codar

**Não assuma. Não esconda confusão. Exponha os trade-offs.**

Antes de implementar:

- Leia o `MANUAL_DE_REGRAS.md` primeiro (governança: nenhuma regressão às
  regras do manual é aceitável; se a mudança conflitar com o manual,
  **pare e pergunte** ao dono antes).
- Declare suas suposições explicitamente. Se estiver incerto, pergunte.
- Se existirem múltiplas interpretações do pedido, apresente-as — não escolha
  em silêncio.
- Se existir uma abordagem mais simples, diga-o. Contrarie quando necessário.
- Se algo não estiver claro, pare. Nomeie o que está confuso. Pergunte.

## 2. Simplicidade primeiro

**Mínimo de código que resolve o problema. Nada especulativo.**

- Nenhuma feature além da pedida.
- Nenhuma abstração para código de uso único.
- Nenhuma "flexibilidade" ou "configurabilidade" que não foi pedido.
- Nenhum tratamento de erro para cenários impossíveis.
- Se você escreveu 200 linhas e daria 50, reescreva.

Pergunta de teste: "um engenheiro sênior diria que isto está complicado
demais?" Se sim, simplifique.

## 3. Mudanças cirúrgicas

**Toque só no que precisa. Limpe só a sua própria sujeira.**

Ao editar código existente:

- Não "melhore" código vizinho, comentários ou formatação.
- Não refatore o que não está quebrado.
- Combine com o estilo existente, mesmo que você faria diferente.
- Se notar código morto não relacionado, mencione — não apague.

Quando as SUAS mudanças criarem órfãos:

- Remova imports/variáveis/funções que a SUA mudança tornou não usados.
- Não remova código morto pré-existente, a não ser que peçam.

Teste: **cada linha alterada deve rastrear diretamente até o pedido do dono.**

## 4. Execução orientada a objetivo

**Defina critérios de sucesso. Repita até verificar.**

Transforme tarefas em objetivos verificáveis:

- "Conserte o bug" → "escreva um teste/traço que reproduz o bug; depois faça-o
  passar" (ex.: `tests/` headless — `godot --headless --path . res://tests/smoke.tscn`).
- "Refatore X" → "garanta que os testes passam antes e depois".
- Animações/VFX: verifique com traço de posição/estado em headless quando o
  efeito for de movimento; o que o manual descreve (tempos, arcos, impactos,
  "sem tremor de tela") é o critério de aceite.

Para tarefas multi-passo, declare um plano breve:

```
1. [passo] → verifica: [checagem]
2. [passo] → verifica: [checagem]
3. [passo] → verifica: [checagem]
```

Critérios fortes de sucesso deixam você iterar sozinho. Critérios fracos
("faça funcionar") exigem esclarecimento constante.

---

## Checklist fim de tarefa (obrigatório)

1. `godot --headless --path . res://tests/smoke.tscn` passa (regras + UI).
2. Nenhuma regra do `MANUAL_DE_REGRAS.md` regrediu (rever §4 Animações,
   §2 Cartas, §3 Campo e linhas).
3. Versão sobe em `scripts/version.gd` e a aba NOTAS ganha o resumo
   (regra permanente §7.7 do manual; só as 10 últimas atualizações).
4. Build Web regenerado em `web_export/` (regra de infraestrutura §0bis.1) e
   ZIP entregue com `web_export/` + `ferramentas/`.
5. Cada linha alterada rastreia até um pedido do dono (princípio 3).
