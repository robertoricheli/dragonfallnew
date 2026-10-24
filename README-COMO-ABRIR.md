# DRAGONFALL — Protótipo Godot

> ⚠️ **LEIA O `MANUAL_DE_REGRAS.md` ANTES DE QUALQUER MUDANÇA.**
> Ele é a fonte da verdade das regras (gameplay, animações, telas, editor).
> Só muda quando o dono do projeto solicitar; qualquer alteração de código que
> exija mudar o manual deve ser **perguntada antes**.

> 🧠 **REGRAS DE CÓDIGO (KARPATHY) — REGRA PERMANENTE:** toda alteração deste
> projeto segue `KARPATHY_GUIDELINES.md` (pensar antes de codar, simplicidade
> primeiro, mudanças cirúrgicas e execução orientada a objetivos verificáveis).
> O jogo, para ser alterado, deve seguir esses princípios à risca.

Jogo de cartas 1v1 (jogador vs IA) construído em **Godot 4**, com layout e cartas
baseados no jogo **Dragonfall** disponível em:
`https://github.com/robertoricheli/-artifacts-dragonfall-public-`
(cartas, heróis e regras portados de `motor/df-data.js` e `motor/df-rules.js`).

---

## ▶ COMO ABRIR O JOGO NO GODOT (passo a passo)

1. **Instale o Godot 4.3 ou mais novo** (versão *Standard*, não a .NET):
   - Site oficial: https://godotengine.org/download
   - Descompacte o executável e rode-o (não precisa instalar).
2. **Descompacte este ZIP** (`DragonfallGodot.zip`) em uma pasta do seu computador.
3. Abra o Godot e, no **Gerenciador de Projetos**, clique em **Importar**.
4. Navegue até a pasta descompactada e selecione o arquivo **`project.godot`** →
   clique em **Abrir** e depois em **Importar e Editar**.
   (Na primeira abertura o Godot importa os assets automaticamente — aguarde.)
5. Com o projeto aberto, aperte **F5** (ou o botão ▶ “Executar o projeto”).
   A cena principal (`res://scenes/main.tscn`) já está configurada como cena inicial.

Pronto! O jogo abre na tela de título.

---

## 🎮 COMO JOGAR

- **Tela inicial:** apenas a **CAPA DO JOGO NOVA** com o botão **PLAY** recortado
  sobre o botão de pedra da arte. Clicou em PLAY → **HUB DO JOGADOR** com os
  botões **JOGAR**, **MERCADO** e **ARSENAL** (sem textos sob os botões).
  - **JOGAR** abre a **configuração da partida**: objetivo (**10 ou 15 PV**),
    baralho (**aleatório de 20 cartas** ou um dos **5 baralhos do Arsenal**) e
    **escolha do herói** (ícone + descrição). Depois, **AVANÇAR** inicia a partida.
  - **ARSENAL**: botões **HERÓIS** (lista com imagem destacada, nome, descrição
    da ultimate e usos por partida; clique na imagem para ampliar) e **CARTAS**
    (filtros TODAS/CAMPEÕES/TALENTOS/REAÇÕES, páginas de 10 cartas com setas,
    zoom navegável com ‹ › e botão ADICIONAR; à direita, criador de baralho com
    2 páginas de 10 = **20 cartas**, renomear baralho e abas 1–5).
  - **MERCADO** está reservado para as próximas fases.
- **Na batalha:**
  - Cartas com **proporção fixa 5:7** (mão 110×154, campo 100×140).
    Fundo **azul = CAMPEÃO**, **vermelho = TALENTO**, **verde = REAÇÃO**;
    o verso de todas as cartas é a arte **VERSO DAS CARTAS**.
    No hover a carta **apenas sobe um pouco** (estilo Hearthstone),
    **sem mudar tamanho, cor ou brilho**. Mão em **arco** com as bordas
    das cartas se encontrando; a mão da IA fica **acima do campo, sem encostar**.
  - Sua mão fica **embaixo** (4 cartas iniciais); a mão da IA fica **em cima**
    (versos), **sempre separada do campo** — jamais encosta nele.
  - **Arraste** uma carta da mão para a **metade de baixo do campo** para invocá-la
    (custo em ações = Poder da carta; máx. **6 campeões** por campo).
    Solte **à direita ou à esquerda de um campeão aliado** (ou entre dois) para
    invocá-lo **naquela posição**. A invocação voa da mão **direto ao slot onde
    vai ficar** (sem passar por cima de outras cartas), em **arco fluido de
    ~1 s** (ritmo ágil da versão 1.49.60), **sem mudar de tamanho** e **sem
    rastro de partículas** — e ao chegar **cai pesada** e pousa em tamanho
    normal com **IMPACTO PESADO** (nuvem de poeira + onda de choque + clarão,
    estilo Hearthstone), **sem quique, sem deslizamento e sem tremor de tela**.
  - Todas as mensagens do jogo aparecem no **painel de texto abaixo do botão
    PASSAR A VEZ** (nunca sobre o campo).
  - **Cartas TALENTO/REAÇÃO**: com **6 campeões no campo não podem ser usadas** e
    **só um Talento por vez** (o próximo só após o atual ir ao descarte).
    Quando usadas, voam direto ao slot, **ficam no campo por 2 s** e somem.
  - **Sem caixas de tooltip** ao deixar o mouse parado sobre as cartas.
  - Imagens do jogo em **alta resolução** (verso 2282×3188, fundos 2048×1152,
    importação lossless).
  - **REGRA DE ESPAÇO:** as cartas no campo **nunca excedem o espaço da sua
    metade** — se não couberem, a linha inteira é reduzida proporcionalmente.
  - **COMBATE (~1,5 s):** **arraste um campeão SEU e solte em cima de um campeão
    inimigo**. A carta arrastada **volta ao seu lugar** e então os dois campeões
    **sobem em arco um de encontro ao outro**, **colidem** com impacto (anel de
    choque, faíscas e clarão — **sem tremor de tela**); o destruído **explode em
    estilhaços** com fumaça e os sobreviventes retornam em arco.
  - **HISTÓRICO (estilo Hearthstone):** clique no **avatar do herói** (seu ou da
    IA) para ver em destaque a imagem, o nome e a habilidade do herói e, abaixo,
    a lista rolável do **histórico de cartas usadas** (da última para a
    primeira), com a miniatura da carta e **quem usou** (para a IA, aparece o
    **nome do herói** dela, ex.: "Sinistrela usou esta carta").
    **Clique numa miniatura do histórico para ampliá-la**; clique nela de novo
    ou fora para fechar o zoom.
    Nenhum texto de log aparece na tela de jogo.
  - **AMPLIAR CARTA:** **clique** numa carta da mão (Campeão ou Talento) ou num
    campeão do campo, **a qualquer momento**, para vê-la ampliada. Clique nela
    de novo ou fora dela para fechar.
  - Botões do **lado esquerdo**: **COMPRAR CARTA** (1 ação, mostra o nº de cartas
    do baralho) e **PASSAR A VEZ**.
  - **Botão ULTIMATE** no **lado direito** (adaptado do jogo original do GitHub):
    1 uso por turno, usos limitados por herói (+1 com cartas Energizar).
    O efeito de cada herói é aplicado com alvo automático.
  - **Timer de 70 s** com relógio abaixo do painel de AÇÕES: ao zerar, a vez
    do jogador atual termina automaticamente.
  - **Zoom nítido**: a carta ampliada é reconstruída em tamanho real (fontes em
    alta resolução), centralizada e **nada fica sobreposta a ela**.
  - Botão **OPÇÕES** no **canto superior esquerdo** (continuar / reiniciar / sair).
  - O **banner central** mostra **SUA VEZ** / **VEZ DO ADVERSÁRIO**.
  - As **4 cartas iniciais** já começam na mão, **sem animação**. O **saque
    livre** do início e todas as **compras** voam em animação fluida de
    **1,5 s**: a sua entra pela **lateral direita** (região central) e a da IA
    pela **lateral esquerda** (região central).
  - No início de cada turno o jogador **compra 1 carta automaticamente** e ganha
    **PV passivo** (+1 por campeão, máx. 2).
  - Campeões são invocados **no centro** de cada metade do campo (junto ao banner);
    conforme novos campeões entram, a linha se reajusta **sempre centralizada**.
  - A **IA pensa 2 segundos** entre cada ação dela (invocar, atacar, comprar...).
  - **Vença chegando a 15 PV** (destruindo campeões inimigos e por PV passivo).
  - **PROTEÇÃO:** campeões protegidos exibem um **ícone pequeno de escudo** no
    **canto superior direito** da carta (sobre um selo escuro). **Arcanjo/
    Panteão** protegem só os OUTROS aliados por 1 rodada; **Sir Dunkan/Nobre
    Elfa** têm Proteção permanente. Ampliar um protegido mostra o **ícone de
    escudo** ao lado da carta. (A antiga redoma de energia azul saiu do jogo
    na 1.49.91.)
  - **FORTALECER:** ao invocar **Fauno/Gaia** ou usar o Talento
    **FORTALECER**, os aliados aptos ficam **destacados em verde**; escolha
    um — **anéis verdes no chão** (base imóvel, maior que a carta, abaixo
    dela) emitem **feixes verticais, cruzes de energia e pontos** que sobem
    **por dentro da carta** por 2 s; o aliado ganha **+1 de Poder** no fim
    (e o número atualiza na hora em campo).
  - **MURALHA:** enquanto a habilidade constante está ativa (fora do próprio
    turno), Cavaleiro Juramentado/Alexander exibem um **muro de pedra grosso
    e detalhado** na borda da carta (topo para você; base, invertido, para a
    IA): ele **sobe do chão** com poeira ao ativar e **se destrói** em
    estilhaços ao desativar. Se o campeão **perder Poder fora do turno**, a
    muralha quebra; no próprio turno não perde Poder de novo; no fim do
    turno, reativa.
  - **SEM HONRA:** campeões com o status (constante Sem Honra ou Corromper/
    CORROMPER) exibem um **ícone pequeno de caveira roxa** no **canto
    superior direito** da carta; ao serem destruídos, a **carta explode em
    fumaça roxa** e a caveira surge no fim (2 s, animação especial) e os
    aliados **só se reorganizam 0,5 s depois** do fim dela. No zoom, ícone da
    caveira + "quem o destruir não ganha PV".
  - **RECOMPENSA DUPLA:** campeões destruídos por GAMER/ARCADIA explodem em
    **burst de raios + estrelas + selo "x2" dourado** (2 s, animação
    especial).
  - **BARREIRA:** campeões com Barreira exibem um **painel de energia
    semitransparente curvado** sobre a carta (topo para você; base, apontada
    para o seu campo, para a IA), pulsando enquanto dura; no zoom, ícone +
    "bloqueia a redução de Poder".
  - **ROUBAR:** 0,5 s após invocar TAGARELA/RAZIEL, a carta roubada (**verso**)
    **voa 1,5 s** da mão do alvo até a sua mão; o roubo efetiva no fim do voo.
  - **FORJA:** 0,5 s após invocar JOVEM ARTÍFICE/TINKER, o jogador ganha 1
    carta com a **mesma animação de compra** (saque livre, sem gastar ação);
    o campeão entra em campo normalmente.
  - **CONGELAR / ZERO ABSOLUTO:** inimigos aptos ficam **destacados em azul**;
    ao escolher, o alvo **congela** (1 rodada na Rajada Congelante, 2 no Zero
    Absoluto — que **destrói** se já estava congelado) com **coluna de luz +
    anel de gelo + burst de cristais**; o congelado fica **azulado e SOMENTE
    com o ícone de CONGELADO no canto superior direito** (o cristal sobre a
    carta saiu no 1.49.92) e o zoom mostra o ícone do status.
  - **CANSADO:** campeões que já agiram no turno ficam **escurecidos e
    dormindo** ("z z z" subindo da carta); o zoom mostra o ícone de lua +
    zzz com a descrição.
  - **STATUS NO CANTO (1.49.91/92):** PROTEÇÃO, SEM HONRA, ENVENENADO, FÚRIA
    e CONGELADO aparecem em campo **SOMENTE** como ícones pequenos no **canto
    superior direito** da carta; com vários status, os ícones **empilham de
    cima para baixo na ordem de aquisição** (o 1º no topo). Os detalhes
    (rodadas restantes, etc.) continuam no zoom da carta.
  - **BAFORADA VENENOSA (1.49.93):** o Talento abre **mira verde-veneno** nos
    inimigos (você escolhe o alvo) e abre o **SOPRO DO DRAGÃO VERDE**: um
    **cone sustentado de fogo verde** (núcleo incandescente, línguas de
    chama, fumaça escura e brasas) jorra da carta e **engolfa** o Campeão
    escolhido com chamas lambendo a carta; só quando o sopro cessa ele fica
    ENVENENADO (ícone no canto).
  - **MORDIDA VENENOSA (1.49.93):** inimigos aptos ficam **destacados em
    verde-veneno**; ao confirmar, a **cabeça da serpente venenosa** (arte
    pintada) dá o **BOTE** do céu e **crava as presas** no alvo — clarão
    verde, anel de choque, respingos de veneno, marcas de presa e baba —
    e, no fim da animação, ele fica ENVENENADO (destruído em 2 rodadas) —
    ícone no canto, sem bolhas sobre a carta.
  - **FÚRIA / GRITO DE GUERRA:** 1 s após invocar, um **raio vermelho** cai
    sobre o campeão (no Grito, um raio por aliado, um a um); 0,5 s após o
    raio ele ganha FÚRIA (+1 Poder) — ícone no canto, sem aura persistente.
  - **DEFENSOR (1.49.93):** 0,5 s após o pouso, uma **defensa épica dourada**
    (runas no chão, domo de energia e brasão de luz, 1,5 s) cobre o Campeão;
    o ícone de PROTEÇÃO aparece 0,5 s após o início dela.
  - **GUARDIÃO (1.49.93):** 0,5 s após o pouso, um **pilar de luz do céu**
    (1 s) cai sobre cada campeão aliado, **um por um**; 0,5 s após o pilar de
    cada aliado, o ícone de PROTEÇÃO aparece sobre ele.
  - **INVOCAR DRAGÃO (1.49.93):** 0,5 s após o pouso, um **OVO DE DRAGÃO**
    (arte pintada) aparece no slot do Filhote, treme, racha com luz vazando e
    **CHOCA** com explosão de luz e pilar de energia (1,5 s); só então o
    **FILHOTE DE DRAGÃO** cai no campo.
  - **PESADELO (1.49.93):** 0,5 s após o pouso, o campeão lança **muitos
    fantasmas (estilo Boo) e fumaça negra** em cone sobre o campo adversário
    (2 s); depois, **fantasmas e fumaça sobem em loop sobre a moldura do
    herói afetado** até o fim do turno dele — ele **não faz o próximo saque
    livre**.

## 🛠 EDITOR DE LAYOUT (arrastar e soltar) — EM TODAS AS TELAS

- O botão **EDITOR** existe no **menu**, na **batalha** e nas demais telas.
- Na batalha: logo abaixo de OPÇÕES, no canto superior esquerdo.
- Áreas destacadas em amarelo podem ser **arrastadas**: campo inteiro, banner,
  coluna esquerda (comprar/passar/ações), blocos dos heróis e as **barras
  amarelas** que controlam a altura das mãos (do jogador e da IA).
- **Todos os elementos são editáveis** (regra do projeto: todo elemento de UI
  novo é registrado no editor): campo, banner de turno, botão comprar, botão
  passar, botão opções, botão EDITOR, painel de AÇÕES, **relógio/timer**, botão
  **ULTIMATE**, hubs dos heróis, mão do jogador e mão da IA.
- Cada elemento selecionado ganha **8 alças arrastáveis** (cantos e meios das
  bordas, estilo Ctrl+T do Photoshop) para **esticar/encolher** — sem botões
  −/+. O clique seleciona o **menor retângulo** sob o mouse (pega elementos
  sob outras camadas). Cada ícone/botão é um elemento **individual**.
- **Clique** num elemento para **selecioná-lo** (borda vermelha); **DELETE**
  **exclui** o elemento selecionado; **Ctrl+Z** **desfaz** (move/redimensiona/
  exclui). Tudo é salvo ao sair (SAIR) em `user://layout_override.cfg`.
  **SALVAR** grava na hora; **RESETAR** volta ao padrão.
- **Ao fechar o editor (SAIR ou ESC) as mudanças são salvas automaticamente**
  (um arquivo por tela: `layout_battle.cfg`, `layout_menu.cfg`) e aplicadas nas
  próximas partidas. **SALVAR** grava na hora (com aviso "SALVO!");
  **RESETAR** volta ao padrão. **DELETE** exclui o elemento selecionado e
  **Ctrl+Z** desfaz.

---

## 🗂 ESTRUTURA DO PROJETO

```
project.godot            Configuração do projeto (Godot 4.3+)
scenes/main.tscn         Cena inicial (gerencia menu ↔ batalha)
scripts/main.gd          Alterna telas (menu / batalha / reinício)
scripts/menu_screen.gd   Tela PLAY → JOGAR / MERCADO / ARSENAL
scripts/battle_screen.gd Layout da batalha, arrastar-e-soltar, animações, IA em turnos
scripts/game_state.gd    Regras completas (portadas de df-rules.js / df-engine.js)
scripts/ai_brain.gd      IA do adversário (planeja uma ação por vez)
scripts/card_db.gd       126 cartas + 21 heróis (portados de df-data.js)
scripts/card_view.gd     Visual da carta na mão (frente sólida 5:7 / verso)
scripts/champion_view.gd Visual do campeão no campo (procedural)
scripts/card_art.gd      Verso das cartas + cores de fundo por tipo
tests/smoke.tscn         Teste automático headless (opcional)
assets/                  Fundos gerados para menu e batalha
```

## 🧪 TESTE AUTOMÁTICO (opcional, para desenvolvedores)

Com o Godot instalado, rode no terminal:

```
godot --headless --path <pasta do projeto> res://tests/smoke.tscn
```

Ele simula partidas completas (IA vs IA), valida regras (campo ≤ 6, mão ≤ 8,
vitória aos 15 PV) e o layout centralizado dos campeões.

## 📌 NOTAS DESTA FASE

- Foco da fase: botão **JOGAR** (partida completa contra a IA).
- Cartas de **Reação** foram simplificadas (usáveis no seu turno com efeito defensivo).
- **Ultimates dos heróis** entram em uma próxima fase (herói é sorteado por partida).
- Habilidades com “escolha um alvo”: a **BOLA DE FOGO** (Talento ou Campeão)
  deixa VOCÊ escolher: os Campeões adversários aptos ficam com **cor
  AVERMELHADA** e um **leve efeito de zoom in/out** (sem piscar) e,
  ao tocar em um deles, a animação da Bola de Fogo sai **da carta** até o alvo.
  O alvo **só perde Poder/é destruído NO IMPACTO** (depois que a animação
  chega nele) e a explosão **não treme a tela**.
  As demais habilidades de alvo seguem automáticas (melhor alvo válido).

---

## 🌐 LOCAL HOST (regra permanente: sempre ativo após atualizações)

O ZIP já sai com o build Web pronto em `web_export/` e o servidor em
`ferramentas/`:

1. **Dê dois cliques em `ferramentas/SERVIR_LOCAL.bat`** (Windows) ou rode
   `python3 ferramentas/servir_local.py` (Linux/Mac).
2. No **PC**: abra `http://localhost:8060`.
3. No **celular/tablet (mesmo Wi-Fi)**: abra `http://SEU_IP:8060`
   (o IP aparece na janelinha do servidor). **Abre DIRETO, sem nenhum aviso**
   de certificado ou de segurança: o build Web já sai patchado
   (`ferramentas/patch_web.py`, rodado automaticamente após cada exportação)
   para não exigir HTTPS, e o servidor usa só HTTP na porta 8060.

**VFX de teste:** na Tela de Combate, aperte **F9** para disparar uma Bola de
Fogo de demonstração.
