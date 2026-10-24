# 📜 MANUAL DE REGRAS DO DRAGONFALL (Godot)

> **GOVERNANÇA DESTE MANUAL — LEIA PRIMEIRO.**
> Este manual é a **fonte da verdade** das regras do jogo.
> 1. Ele **SÓ é alterado quando o DONO DO PROJETO solicitar explicitamente**.
> 2. Qualquer mudança de código que **conflite ou exija alterar** uma regra deste
>    manual **deve ser interrompida**: é obrigatório **perguntar antes** ao dono
>    do projeto se a mudança pode ser feita.
> 3. Ao implementar QUALQUER feature nova, revise este manual primeiro: nenhuma
>    regressão às regras abaixo é aceitável.

---

## 0. GLOSSÁRIO OFICIAL (nomes usados pelo dono do projeto)

- **HUB PRINCIPAL:** a tela com JOGAR / MERCADO / ARSENAL (+ ícones e Perfil).
- **TELA DE COMBATE:** a tela onde a partida acontece (invocar, atacar, comprar).
- **HUB DO HERÓI:** a área dentro da Tela de Combate com avatar do herói,
  nome e PV (canto inferior esquerdo = IA; direito = Jogador Principal).
- **PERFIL DO JOGADOR:** tela com CONQUISTAS, RANK, TROCAR DE FUNDO, XP,
  nome editável, JORNADA, OPÇÕES, avatar (quadrado arredondado) e moldura.
- **JOGADOR IA:** o oponente controlado pela IA. **JOGADOR PRINCIPAL:** você.

## 0bis. REGRAS DE INFRAESTRUTURA

1. **LOCALHOST SEMPRE ATIVO:** após CADA atualização, gerar o build Web
   (`web_export/`) e **deixar o servidor local rodando**
   (`ferramentas/servir_local.py`) para testes no PC e no
   celular: **HTTP porta 8060 para todos** (`http://localhost:8060` no PC e
   `http://SEU_IP:8060` no celular/tablet da mesma rede Wi-Fi). O build sai
   patchado (`ferramentas/patch_web.py`) para **abrir DIRETO, sem NENHUM aviso
   de certificado/segurança** no celular (sem HTTPS/autoassinado). O ZIP já
   sai com `web_export/` pronto e os scripts `SERVIR_LOCAL.bat` /
   `servir_local.py`.
2. **RESPONSIVO:** o jogo deve se adaptar a **mobile, tablet e PC desktop**
   (stretch `canvas_items` + `aspect=ignore`, orientação landscape no handheld,
   entrada por mouse, toque e teclado).
3. **VFX:** animações de efeito (ex.: **Bola de Fogo**) em estilo Hearthstone,
   vistas 100% de cima: projétil com núcleo flamejante + rastro de brasas e
   fumaça saindo da carta, voo em arco até o alvo e explosão com clarão, anel
   de choque, faíscas, fogo e fumaça — **SEM tremor de tela** (nem durante nem
   depois da animação). Teste rápido: tecla
   **F9** na Tela de Combate.
4. **MIRA (ESCOLHA DE ALVO):** habilidades como **BOLA DE FOGO** (Talento
   usado ou Campeão invocado com essa habilidade) exigem escolha de alvo:
   os Campeões adversários aptos ficam com **cor AVERMELHADA constante** e um
   **LEVE efeito de zoom in/out** (sem piscar e sem brilho), e o jogador
   escolhe (a IA escolhe após 1,6 s); só então a animação começa, saindo
   **SEMPRE DA CARTA** (Talento no campo ou Campeão invocado) até o alvo —
   nunca de fora da tela. O **dano/destruição do alvo só é aplicado NO
   IMPACTO** da Bola de Fogo (depois que a animação chega nele) — o Campeão
   **nunca** é destruído antes ou durante o voo. Os voos de **compra/saque**
   e da **Bola de Fogo**
   duram **1,5 s**; **invocação e combate** seguem o ritmo **ágil da versão
   1.49.60** (regra restaurada em 1.49.62).

---

## 1. Telas e fluxo

1. **Tela inicial (CAPA):** contém **SOMENTE** a imagem `CAPA DO JOGO NOVA`
   (preenchendo a tela **sem cortes e sem barras**, stretch `aspect=ignore` +
   `STRETCH_SCALE`) e o **botão de pedra recortado** (`BTN_PLAY.png`, corte
   profissional sobre o slab da arte) com a palavra **PLAY** em fonte grossa
   (Bungee) e **efeito leve de zoom** (hover 1,05 / pressionado 0,94).
   Nenhum outro elemento visível (o EDITOR não aparece nesta tela).
2. **PLAY → HUB DO JOGADOR:** tela com **fundo liso escuro (SEM imagem)** e os
   botões **JOGAR**, **MERCADO** e **ARSENAL**. **Não há NENHUM texto abaixo
   desses botões.**
3. Sair do **ARSENAL** (ou do MERCADO / da configuração) retorna ao **HUB**.
4. **JOGAR → tela de MODO:** botões **JOGADOR CONTRA IA** (abre a configuração
   da partida) e **MULTIPLAYER ONLINE** (reservado, sem ação por enquanto).
4. **JOGAR → Configuração da partida:** objetivo (**10 ou 15 PV**), baralho
   (**aleatório de 20 cartas** ou um dos **5 baralhos do Arsenal**) e **herói**
   (ícone + descrição). **AVANÇAR** inicia a partida.
5. **ARSENAL:** botões destacados **HERÓIS** e **CARTAS**; tela grande,
   preenchendo quase todo o viewport.
   - **HERÓIS:** lista com imagem destacada, nome, descrição da ultimate e
     **usos por partida**; clicar na imagem **amplia** o herói.
   - **CARTAS:** filtros **TODAS / CAMPEÕES / TALENTOS / REAÇÕES**; páginas de
     **10 cartas (5 em cima + 5 embaixo)** com setas ‹ ›; clicar numa carta
     **amplia** e permite navegar ‹ › / setas do teclado / swipe; à direita, **criador de
     baralho** com 2 páginas de 10 (**até 20 cartas**), campo para **renomear**
     e abas **1–5** (cinco baralhos persistidos).
   - **Adicionar carta ao baralho: ARRASTAR da esquerda (Arsenal) e SOLTAR na
     área do baralho (direita). Remover: ARRASTAR do baralho e SOLTAR na
     esquerda.** Não existe botão "adicionar" no zoom.
   - Carta que **já está no baralho** aparece **BEM ESCURECIDA** na grade do
     Arsenal (não pode ser adicionada de novo) — e mesmo assim pode ser
     **ampliada** clicando nela no baralho (navegação entre as cartas do
     baralho).
   - **EDITOR DE CARTAS** (botão dentro da carta ampliada no Arsenal): enquanto
     aberto, **não se troca de carta** (setas/swipe/‹ › desativados); arrastar
     um elemento move **livremente com o mouse** (aplica ao soltar);
     **clique seleciona a zona de texto**, que ganha **alças estilo Ctrl+T**
     que redimensionam o texto **EM TEMPO REAL** (o box acompanha ao vivo),
     somente daquela zona/carta (sem espelhar); **dois cliques** numa zona
     abrem o editor de texto **SOMENTE daquela zona** (nome, habilidade,
     descrição ou selo); **scroll do mouse dá ZOOM** na carta (1x–4x);
     **arrastar alças laterais re-quebra o parágrafo** sem mudar a fonte;
     **setas do teclado** movem a zona; **SALVAR** mostra "ATUALIZAÇÕES
     SALVAS!" e **permanece no editor**; só **ESC** ou **VOLTAR** saem (clicar
     fora NÃO fecha); **Ctrl+Z** desfaz.
     Mover altera o **layout de TODAS as cartas do mesmo tipo**; o tamanho
     dos textos é **por carta**. **TEXTO DESTA CARTA** (painel modal) altera
     **somente aquela carta** e suporta: **ENTER = quebra de linha real**
     (persiste no texto final), **NEGRITO** por trecho selecionado
     (`**trecho**`), **CENTRALIZAR**, **troca de FONTE** (Baloo/Fredoka/Heavy)
     e **ENTRELINHA (L-/L+)**. Tudo persiste em `user://card_layout.cfg`.
7bis. **MERCADO** (botão do Hub): 6 ofertas de cartas compráveis com **moedas**
   (preço = 2 + Poder); carta comprada vira **ADQUIRIDA** (escurecida);
   **TROCAR OFERTAS** custa 1 moeda; moedas/XP visíveis no topo.
7ter. **Recompensas de partida Jogador vs IA:** vitória = **+4 XP e +1 moeda**;
   derrota = **+2 XP e 0 moedas** (mostradas na tela de fim de partida).

## 2. Cartas (visual)

1. Proporção **fixa 5:7 na vertical** (mão 110×154, campo 100×140).
2. **Frentes com molduras finais** (altíssima qualidade), uma por tipo:
   `MOLDURA_CAMPEAO_FINAL` (todas as cartas CAMPEÃO), `MOLDURA_TALENTO_FINAL`
   (TALENTOS) e `MOLDURA_REACAO_FINAL` (REAÇÕES). Zonas oficiais das molduras:
   - **Esfera superior esquerda:** PODER/CUSTO centralizado nela.
   - **Barra ao lado da esfera:** NOME da carta perfeitamente centralizado
     (azul no Campeão, branca no Talento/Reação).
   - **Janela vazia central:** reservada à **imagem futura** do campeão/
     talento/reação, que ficará posicionada **dentro** dessa janela, nunca
     maior que a carta.
   - **Barra azul (só Campeão):** nome da habilidade + "(Constante)"/
     "(Instantânea)", centralizados.
   - **Espaço branco grande:** descrição da habilidade/carta, centralizada.
   - **Selo inferior:** "Campeão" / "Talento" / "Reação", centralizado.
   O **verso** de todas as cartas é a arte `VERSO DAS CARTAS`.
2bis. **Tipografia oficial das cartas: fonte BALOO 2 com pesos** (mesmo estilo
   da arte de referência): poder/nome/habilidade/selo **800**, descrição **600**.
   A fonte **Bungee** fica SOMENTE no texto PLAY da capa.
   - **NOME em linha única**, perfeitamente centrado dentro da barra superior
     (Campeão/Talento/Reação), peso 800, **maior** que o corpo de descrição.
   - **Poder/Custo** maior, peso 800, **SEM borda/contorno**, perfeitamente
     centrado no círculo da esfera (nenhum nudge).
   - **Habilidade + (Constante)/(Instantânea)** (só Campeão) perfeitamente
     centrada na barra central, peso 800, **maior** que o corpo de descrição.
   - **Descrição** com corpo único (igual à referência), **no MÁXIMO 3 linhas**,
     sempre COMPLETA e dentro da caixa branca; nas cartas TALENTO e REAÇÃO a
     descrição ocupa a caixa **inteira**, **SEM** repetir o nome da carta ou da
     habilidade e **SEM** "(Talento)"/"(Reação)" (o selo inferior já informa o
     tipo).
   - **Selo inferior** ("Campeão"/"Talento"/"Reação") peso 800, corpo maior que
     o mínimo antigo; no TALENTO/REAÇÃO um pouquinho mais acima.
   - **Poder/Custo** um pouquinho mais para cima (nudge -1,0% da altura).
   - **Tamanho de fonte ÚNICO** por zona; redução mínima só para textos longos.
   - **Tipografia DETERMINÍSTICA centralizada** (`CardArt.layout_for`): calculada
     1x por carta no tamanho base (quebras de linha incluídas).
   - **BAKE ÚNICO POR CARTA** (`CardBaker`, autoload): cada carta é renderizada
     UMA vez em 440×616 e **todas** as instâncias (miniatura do Arsenal, mão,
     campo, zoom, histórico, mercado) usam **essa mesma textura** ⇒
     **miniatura == mão == ampliada, por construção (pixel-perfect)**.
     Cache invalidado automaticamente por edições de layout/texto.
   - Descrição requebrada com **quebras explícitas** (máx. 3 linhas): o texto
     renderizado é idêntico ao medido — **jamais incompleto ou cortado**.
   - **NENHUM fundo branco atrás das cartas**; molduras em `STRETCH_SCALE`.
3. **NUNCA** exibir caixa de tooltip ao deixar o mouse parado sobre cartas.
4. **Hover:** a carta **apenas sobe um pouco**; **não** muda tamanho, cor ou
   brilho.
5. Mãos em **arco/leque** com as **bordas das cartas se tocando** (leve
   sobreposição) e curvatura moderada; a mão da IA fica **de cabeça para baixo**,
   **acima do campo, sem jamais encostar nele** (pode ficar cortada no topo).
   A mão é **centrada na tela**, com largura máxima que **NUNCA encosta nos
   hubs dos heróis** (mesmo com 8 cartas), e **todas as cartas da mão têm
   exatamente o mesmo tamanho** (spawn por fade, sem escala residual).
6. Todas as imagens do jogo em **alta resolução** (verso 2282×3188; capas/fundos
   ≥ 2048 de largura; importação lossless). A **carta ampliada (zoom)** é
   reconstruída em tamanho real (3,2×) — texto nítido, **espelho perfeito** da
   carta original.

## 3. Campo e linhas

1. Campo central retangular **dividido em 2 metades** (IA em cima, jogador
   embaixo), **centralizado na tela**, com **banner de turno FINO** (32 px,
   borda 1 px, **sem contador de turnos**) entre as metades ("SUA VEZ" /
   "VEZ DO ADVERSÁRIO"), sempre **acima** do campo e **ABAIXO** das cartas e
   VFX em z-order (nada de "parede invisível" sobre animações).
2. **Máximo 6 campeões** por campo.
3. A linha de campeões é **sempre centralizada** no eixo do campo; campeões
   invocados entram na posição definida pela **soltura** (à direita, à esquerda
   ou entre aliados).
4. **REGRA DE ESPAÇO:** cartas no campo **nunca excedem** a sua metade; se não
   couberem, a linha inteira é reduzida proporcionalmente.
5. Após uma **destruição**, as cartas restantes esperam **1 segundo** antes de
   se reajustar.
6. Hubs: herói do **jogador no canto inferior direito**; herói da **IA no canto
   inferior esquerdo**; retrato em **quadrado arredondado**; nome da IA **sem**
   o sufixo "(IA)". O hub mostra **SOMENTE**: imagem do herói, nome e PV
   (**sem** nome da ultimate); clicar na **imagem** abre o histórico com nome,
   habilidade/ultimate e demais informações do herói.
7. Coluna esquerda: **COMPRAR CARTA** (mostra apenas o número de cartas do
   baralho) e **PASSAR A VEZ**. **Nenhum texto cinza (ou de qualquer cor) abaixo
   do botão PASSAR A VEZ** — não há log de mensagens na tela.
8. Canto superior direito: painel de **AÇÕES** e, abaixo, **relógio + timer de
   70 s** (contagem regressiva; ao zerar, a vez do jogador atual termina). A
   caixa de AÇÕES é **ÚNICA** (uma só para os dois jogadores) e mede as ações
   restantes do **jogador ativo** (principal ou IA); no início de cada vez ela
   volta a 3.
9. Lado direito: botão **ULTIMATE** (não encosta no campo).

## 4. Animações oficiais (não regressar)

### 4.1 Compra / saque
1. As **4 cartas iniciais** entram na mão **SEM animação**.
2. **Saque livre** do início do turno e **toda compra** voam da lateral até a
   mão em **exatamente 1,5 s**, de forma muito fluida (bezier + easing seno,
   **SEM rastro de partículas**):
   - **Jogador:** entra pela **lateral DIREITA** da tela, região central.
   - **IA:** entra pela **lateral ESQUERDA** da tela, região central.
3. Durante o voo, a carta fica **acima de tudo** (z-index 200).

### 4.2 Invocação (Campeão)
1. A carta voa da mão **direto ao slot final** onde ficará — **nunca** passa
   antes pelo centro do campo.
2. Durante o voo, a carta **NUNCA passa por baixo** das cartas da mão
   (z-index 200).
3. Os campeões aliados **abrem espaço durante o voo** (deslize sutil, ~0,45 s,
   easing seno) — incluindo o caso de invocar **entre** dois campeões.
4. Ao chegar: a carta **NÃO encolhe nem cresce**, **NÃO quica (sem sobe-e-
   desce)** e **NÃO desliza** no campo: o voo termina acima do slot e a carta
   **cai pesada na vertical** (~0,12 s, acelerada), pousando firme com
   **IMPACTO PESADO**, como se fosse uma carta muito, muito pesada caindo no
   chão (referência **Hearthstone**): nuvem de **poeira**, **onda de choque
   dupla**, clarão e faíscas — **SEM tremor de tela**. O voo também é **sem
   pulso de tamanho** e **SEM rastro de partículas** (a carta mantém o
   tamanho do início ao fim). Ritmo **ágil**, como na versão **1.49.60**
   (voo ≈ 1,05 s; a invocação **NÃO** dura 1,5 s). O reajuste da linha só
   começa depois do impacto assentar (~0,3 s).
5. Posição de soltura define o índice de inserção (direita/esquerda/entre),
   respeitando o máx. de 6.

### 4.3 Invocação (Talento/Reação)
1. Mesmo princípio de voo direto ao slot (fim da linha do campo).
2. A carta **permanece no campo por NO MÍNIMO 2 segundos** e **só desaparece
   MEIO SEGUNDO depois que a sua animação terminar** (ex.: Talento
   FORTALECER fica até 0,5 s após o fim do VFX de 2 s), sumindo em fade
   rápido (~0,5 s). Um Talento **NUNCA sai de campo antes de 2 s**.
   - A **posição de soltura** do Talento define onde ele aparece na linha do
     campo (à esquerda/à direita de qualquer Campeão), como nos Campeões.
3. **Só um Talento por vez** por jogador: o próximo só após o atual ir para o
   descarte.
4. Com **6 campeões no campo**, Talentos e Reações **não podem ser usados**.

### 4.4 Combate (1,5 s)
1. Inicia **arrastando** um campeão próprio e **soltando sobre** um campeão
   inimigo — **basta sobreposição parcial**. Durante o arrasto,
   **SOMENTE o campeão inimigo sob a carta arrastada** fica destacado em
   vermelho (alvo apto), trocando conforme o mouse se move.
2. A carta arrastada **volta ao seu slot** (0,25 s) **ANTES** do combate começar.
3. Os dois campeões **saem levemente do chão** (scale up ~1,14/1,10) e
   **sobem em arco** um de encontro ao outro (0,6 s) e
   **colidem borda a borda** no ponto médio — **nunca um por cima do outro**.
4. No choque: **impacto rápido** (anel duplo, faíscas e clarão, ~0,5 s —
   ritmo da versão 1.49.60), **SEM tremor de tela** (a tela não treme em
   nenhum momento do combate).
5. Resolução do combate; o destruído **explode em estilhaços + fumaça**
   (~0,5 s), **SEM inclinar** em nenhum momento.
6. Sobreviventes **retornam em arco** (0,6 s). Total = **1,5 s**; o
   reposicionamento da linha após a destruição é **ágil (~0,45 s)**.
7. Durante toda a animação, os combatentes ficam **ACIMA** das demais cartas do
   campo (z-index 60).

### 4.5 Proteção — ícone de status (VFX oficial)
1. Campeões com **Proteção** (`shield_turns` ≠ 0) exibem **SOMENTE o ícone
   pequeno de escudo** (`assets/ICO_PROTECAO.svg`) no **CANTO SUPERIOR
   DIREITO** da carta, sobre um selo redondo escuro com filete dourado (regra
   geral dos ícones de status, §4.15). A antiga **redoma** azul-dourada
   girando com escudo central foi **RETIRADA DO JOGO** (1.49.91).
2. Com mais de um status, os ícones **empilham de CIMA para BAIXO na ORDEM DE
   AQUISIÇÃO** (o 1º status adquirido fica no topo) — §4.15.
3. **Guardião** (ARCANJO/PANTEÃO): protege **somente os outros** aliados em
   campo por 1 rodada — quem tem a habilidade **NÃO** ganha Proteção ao ser
   invocado (pode recebê-la de outras fontes). **Defensor** (SIR DUNKAN/
   NOBRE ELFA): Proteção **permanente**. As **animações de entrada** de
   Defensor e Guardião (domo dourado / pilares de luz um a um) estão no
   §4.18.
4. **Zoom** de campeão protegido exibe o **ícone de escudo**
   (`assets/ICO_PROTECAO.svg`) ao lado da carta ampliada + o aviso
   "PROTEGIDO (não pode ser atacado)" (coluna de status, §6).

### 4.6 Fortalecer (aura verde) — mira aliada e VFX oficial
1. **MIRA ALIADA:** ao invocar um Campeão com **Fortalecer** (FAUNO/GAIA) ou
   ao usar a carta Talento **FORTALECER**, os campeões aliados aptos ficam
   destacados em **VERDE** (borda + tinta + leve zoom in/out, sem piscar) —
   como a Bola de Fogo, mas para aliados; o dono escolhe um (a IA escolhe
   após 1,6 s).
2. **VFX (2 s exatos), vista 100% DE CIMA e fiel à arte de referência:** a
   **BASE** no CHÃO são **anéis concêntricos VERDES** (círculo perfeito,
   nunca oval) com preenchimento suave, **MAIOR que a carta** (~250 px),
   **ABAIXO dela em z-order** (under_layer), **IMÓVEL** no lugar porém
   animada (anéis e brilho pulsando/respirando); **a partir dessa base**, as
   luzes sobem **PASSANDO POR DENTRO da carta** (camada de cima), como na
   referência: **FEIXES VERTICAIS retos** de larguras variadas, **CRUZES de
   energia verdes** de vários tamanhos subindo com piscar suave, pontos de
   luz e uma lavagem de brilho vertical (tudo em blend aditivo).
3. O **+1 de Poder** do aliado escolhido só é aplicado **NO FIM** dos 2 s da
   animação (`resolve_fortalecer`) — nunca antes ou durante.
4. Sem outros aliados em campo: o próprio Campeão invocado recebe o +1
   (comportamento do motor mantido); Talento sem aliado não faz efeito.

### 4.7 Muralha (muro de pedra) — VFX oficial
1. Campeões com a habilidade constante **Muralha** (CAVALEIRO JURAMENTADO /
   ALEXANDER) exibem, enquanto `wall_buff` > 0 (fora do próprio turno), um
   **MURO DE PEDRA GROSSO E DETALHADO** (`assets/VFX_MURO_PEDRA.png`, estilo
   Hearthstone: tijolos de pedra com musgo, ameias e rim de luz), na
   **borda da carta**: **parte de CIMA** para o jogador principal; **parte
   de BAIXO** (invertido, apontando para o campo do jogador principal) para
   o IA.
2. O muro **SOBE DO CHÃO** ao ativar (com poeira na base) e **SE DESTRÓI** ao
   desativar (estilhaços de pedra + poeira + afundamento, ~0,3 s). Enquanto
   ativo, permanece firme (é pedra — sem pulso de energia).
3. **BARREIRA é OUTRO status** (ver §4.10): o Talento BARREIRA concede
   Barreira (painel de energia que bloqueia redução de Poder) e **NUNCA**
   reproduz a animação da Muralha.

### 4.8 Sem Honra (caveira roxa) — status, ícone e VFX oficial
1. **STATUS SEM HONRA:** têm o status os campeões com a habilidade
   constante **Sem Honra** (CAVALEIRO DA NOITE / REI CAVEIRA) e os que o
   adquirem via **Corromper** (HELA / BARGANHA) ou Talento **CORROMPER**
   (`corrupted`). Quem os destrói **não ganha PV**. A aplicação via Corromper
   usa **MIRA ALIADA** (mesmo processo do FORTALECER: aliados destacados em
   verde, o dono escolhe um, a IA escolhe após 1,6 s).
2. **Ícone no canto:** enquanto o status dura, o campeão exibe **SOMENTE o
   ícone pequeno de caveira roxa** (`assets/ICO_CAVEIRA.svg`) no **CANTO
   SUPERIOR DIREITO** da carta, empilhado com os demais status (§4.15). A
   antiga **caveira pulsante sobre a carta** foi **RETIRADA DO JOGO**
   (1.49.91).
3. **Morte especial (2 s), 100% PROCEDURAL (sem recortes):** um campeão com
   SEM HONRA destruído **NÃO usa a animação padrão**: a **CARTA EXPLODE** num
   clarão nuclear roxo com **anel de choque duplo**, **pétalas de energia**
   voando com rotação, **fumaça volumétrica suave em camadas** (blobs grandes
   que sobem, expandem e giram devagar) e **brasas** subindo; **NO FIM da
   fumaça** (~1,15 s) a **caveira vetorial** surge flutuando e se apaga no
   fim dos 2 s.
3bis. **NUNCA sobrepor animações:** se o campeão com SEM HONRA morre em
   **COMBATE**, o combate conclui normalmente e o campeão **retorna ao seu
   lugar no campo**; **0,5 s depois** roda a morte especial. Fora de combate
   (ex.: **Bola de Fogo**), a animação gatilho termina primeiro (~1,0 s de
   espera) e só então roda a morte especial.
3ter. **REORGANIZAÇÃO TARDIA DOS ALIADOS (1.49.91):** após a destruição de um
   campeão com SEM HONRA, os campeões aliados **só se reorganizam** no campo
   **0,5 s APÓS o FIM** da animação de morte especial (o VFX emite `finished`
   aos 2 s). Durante a explosão e esse +0,5 s, os aliados permanecem nas
   posições originais.
4. **PILHA DE ÍCONES DE STATUS:** os ícones não se anulam (§4.15): cada status
   mantém o seu efeito e, ao expirar, o ícone sai da pilha; o SEM HONRA
   continua visível no zoom enquanto ativo.
5. **Zoom (status ACUMULADOS):** o campeão ampliado exibe, no padrão do
   ícone de Proteção (coluna de ícones + descrições ao lado da carta),
   **TODOS** os status ativos acumulados — um não anula o outro: PROTEÇÃO,
   SEM HONRA, BARREIRA, CONGELADO, VENENO, CHAMAS, FÚRIA, PRESO, SILENCIADO,
   ENFEITIÇADO e EXAUSTO, cada um com seu ícone vetorial próprio.

### 4.9 Recompensa Dupla (burst de estrelas) — VFX oficial
1. Quando um campeão com a constante **Recompensa Dupla** (GAMER / ARCADIA)
   **destrói** outro campeão em combate, o campeão destruído tem animação de
   destruição **especial de 2 s** (substitui a padrão): clarão nuclear,
   **raios em leque** violeta/dourado/branco, **estrelas AFIADAS** (sparkles
   de 4 pontas finas e estrelas clássicas de 5 pontas com bordas retas,
   douradas e violetas — sem "florzinhas") subindo e o selo **"x2" DOURADO
   com contorno VIOLETA** (identidade visual da própria animação) subindo um
   pouco durante a animação.

### 4.10 Barreira (painel de energia) — VFX oficial
1. Campeões com **Barreira** (`barrier_turns` ≠ 0: ANTI-MAGOS / SOLDADO DO
   FUTURO permanentes, Talento BARREIRA ou Proteção Divina) exibem o
   **painel de energia semitransparente curvado** da arte de referência
   (`assets/VFX_BARREIRA_MAGICA.png`, blend aditivo, bem visível), que **pode
   ficar sobre a carta**: para o **JOGADOR PRINCIPAL** na **parte de CIMA** da
   carta; para o **JOGADOR IA** na **parte de BAIXO**, **apontado em direção
   ao campo do jogador principal** (painel invertido verticalmente).
2. O painel **pulsa sutilmente** enquanto o status dura e desvanece ao
   expirar; entra na **pilha de animações de status** (a última aplicada
   prevalece, sem anular efeitos).
3. **Zoom:** campeão com Barreira ampliado exibe o **ícone do painel**
   (`assets/ICO_BARREIRA.svg`) fora da carta + a descrição breve "BARREIRA
   (bloqueia a redução de Poder)".

### 4.11 Forja (saque livre) — VFX oficial
1. Ao invocar um campeão com **Forja** (JOVEM ARTÍFICE / TINKER), o campeão
   entra em campo **NORMALMENTE** (não some); **0,5 s depois**, o jogador
   ganha **1 carta como SAQUE LIVRE** (sem gastar ação), com a **MESMA
   animação de compra de carta** (voo lateral de 1,5 s).
2. **0,5 s após o fim** da animação, o jogador ganha o **SAQUE LIVRE** com a
   animação normal de compra de carta.

### 4.12 Roubar (voo da carta) — VFX oficial
1. Ao invocar um campeão com **Roubar** (TAGARELA / RAZIEL), **0,5 s depois**
   uma carta (**verso**) **sai da mão do alvo** e voa **fluida e natural por
   1,5 s** até a mão de quem usou a habilidade; o roubo só **efetiva** no fim
   do voo (sem tela, simulações resolvem na hora).

### 4.13 Cansado (dormindo) — VFX oficial
1. Campeões **CANSADOS** (`tapped`, já agiram no turno) ficam **ESCURECIDOS**
   (independente de outros status) e **dormem**: letras **"z z z" GROSSAS**
   (corpo 18–30 com contorno escuro) sobem saindo da **JANELA DE ARTE** (a
   área vazia onde ficará a imagem do campeão) em loop enquanto o status
   durar.
2. Ícone próprio do status: `assets/ICO_CANSADO.svg` (lua + zzz), exibido na
   coluna de status do zoom com a descrição "(já agiu neste turno —
   dormindo)".
3. O chip amarelo "EXAUSTO" não existe mais (o sono + o escurecimento
   comunicam o status).

### 4.14 Congelar (gelo) — mira azul e VFX oficial
1. **MIRA AZUL:** ao invocar um campeão com **Rajada Congelante** (TIGRE DE
   GELO / MAGO DE GELO) ou ao usar o Talento **ZERO ABSOLUTO**, os campeões
   **inimigos** aptos ficam destacados em **AZUL** (borda + tinta + leve
   zoom, sem piscar); o dono escolhe o alvo (a IA escolhe após 1,6 s).
2. O alvo escolhido fica **CONGELADO por 1 rodada** (Rajada) ou **2 rodadas**
   (Zero Absoluto); se o alvo do Zero Absoluto **já estava congelado**, é
   **destruído**.
3. **VFX de congelação (≈1,4 s):** coluna de luz + anel de gelo no chão e
   **burst de cristais** sobre o alvo (`assets/VFX_GELO_ANEL.png` +
   `assets/VFX_GELO_BURST.png`), estilhaços e flocos subindo.
4. **Campeão CONGELADO (1.49.92):** fica **azulado** (tinta, não animação) e
   exibe **SOMENTE o ícone pequeno de CONGELADO** (`assets/ICO_CONGELADO.svg`)
   no **CANTO SUPERIOR DIREITO** da carta, empilhado com os demais status
   (§4.15). O **cristal de gelo que ficava sobre a carta enquanto o status
   durava foi RETIRADO DO JOGO**; no zoom, o status CONGELADO aparece na
   coluna de status com o ícone de floco.

### 4.15 Ícones de status no canto superior direito (regra oficial, 1.49.91)
1. Em campo, os status **PROTEÇÃO, SEM HONRA, ENVENENADO, FÚRIA e CONGELADO**
   são representados **SOMENTE** por um ícone pequeno (18 px) no **CANTO
   SUPERIOR DIREITO** da carta, sobre um selo redondo escuro com filete
   dourado: `ICO_PROTECAO.svg`, `ICO_CAVEIRA.svg`, `ICO_VENENO.svg`,
   `ICO_FURIA.svg` e `ICO_CONGELADO.svg`. As antigas animações persistentes
   sobre a carta (redoma de Proteção, caveira pulsante, símbolo+bolhas de
   veneno, aura vermelha com olhos da Fúria e cristal de gelo do CONGELADO)
   **NÃO existem mais** no jogo.
2. **PILHA NA ORDEM DE AQUISIÇÃO:** com mais de um status, os ícones se
   alinham de **CIMA para BAIXO** na ordem em que foram adquiridos — o
   primeiro status fica no topo e os demais **ABAIXO** dele. Quando um status
   expira, o ícone sai e os de baixo sobem.
3. **Exceções visuais (mantidas):** ENVENENADO conserva a carta **esverdeada**
   e CONGELADO conserva a carta **azulada** (tintas, não animações); BARREIRA
   mantém o painel de energia (§4.10); MURALHA mantém o muro de pedra (§4.7);
   CANSADO mantém os zzz (§4.13).
4. **ZOOM:** os detalhes de cada status (ícone + legenda, ex.: rodadas
   restantes) continuam na coluna ao lado da carta ampliada (§6) — esta regra
   não altera o zoom.

### 4.16 Mordida Venenosa / Fúria / Grito de Guerra — VFX oficial (1.49.89/91/93)
1. **MORDIDA VENENOSA (1.49.93, AAA):** os inimigos aptos ficam destacados em
   **VERDE-VENENO**; ao confirmar, a **CABEÇA DA SERPENTE VENENOSA** (arte
   pintada `assets/MANDIBULA_VENENO.png`, presas neon com veneno pingando)
   surge do alto, faz o **BOTE** (~0,2 s) e **CRAVA AS PRESAS** no Campeão:
   clarão verde, anel de choque, respingos de veneno, **marcas de presa** na
   carta, baba escorrendo, poça e névoa tóxica; então recua para o céu
   (~1,6 s no total). **SÓ NO FIM** o alvo recebe ENVENENADO (destruído em 2
   rodadas), marcado pelo **ícone** no canto (§4.15). O loop de **bolhas
   venenosas** sobre a carta **NÃO existe mais**.
2. **FÚRIA (OLAF/URSA):** 1 s após invocar, um **RAIO VERMELHO** serrilhado
   (1,5 s) cai do céu sobre o campeão com estrela de impacto; 0,5 s depois do
   impacto ele ganha FÚRIA (+1 Poder por pilha), marcada pelo **ícone** no
   canto. A **aura vermelha com olhos** persistente **NÃO existe mais**.
3. **GRITO DE GUERRA (campeão e carta TALENTO):** 1 s após invocar, raios
   vermelhos de 1,0 s caem **UM A UM** em cada campeão aliado (menos no
   invocador); 0,5 s após cada raio o aliado ganha FÚRIA (**ícone** no canto,
   empilhado na ordem de aquisição).

### 4.17 Baforada Venenosa (Talento) — mira verde e sopro do Dragão Verde (1.49.92)
1. **MIRA VERDE-VENENO:** ao jogar o Talento **BAFORADA VENENOSA**, os
   campeões **inimigos** aptos ficam destacados em **VERDE-VENENO** (mesmo
   padrão da Mordida Venenosa); o dono escolhe o alvo (a IA escolhe após
   1,6 s), como promete o texto da carta ("Escolha um Campeão"). Em
   simulações/IA sem espera, o alvo é o mais forte.
2. **SOPRO DO DRAGÃO VERDE (~1,7 s, cone sustentado):** carga de energia verde
   na carta Talento e então um **CONE CONTÍNUO DE FOGO VERDE** jorra da origem
   até o Campeão escolhido: núcleo incandescente fino, ventre verde-vivo com
   **línguas de chama turbulentas** nas bordas, **fumaça escura** e **brasas**
   na esteira; o alvo fica **ENGOLFADO** (chamas verdes lambendo a carta de
   baixo para cima + lavagem de brilho). Quando o sopro **cessa**, recolhe em
   direção ao alvo e restam **clarão**, **anel de choque**, **respingos de
   veneno** e **névoa tóxica** subindo.
3. **SÓ NO FIM DO SOPRO** o alvo recebe **ENVENENADO** (destruído em 2
   rodadas), representado em campo **SOMENTE pelo ícone** no canto superior
   direito (§4.15), empilhado na ordem de aquisição; a antiga animação
   persistente de veneno sobre a carta **NÃO existe mais**.

### 4.18 Defensor e Guardião — VFX de entrada (1.49.93)
1. **DEFENSOR (SIR DUNKAN/NOBRE ELFA):** **0,5 s após o pouso**, uma defesa
   épica dourada de **1,5 s** cobre o Campeão: **runas girando no chão**,
   faíscas convergindo, **DOMO de energia** varrendo de baixo para cima com
   **brasão de luz**, feixes verticais e poeira dourada subindo. O ícone de
   **PROTEÇÃO** (§4.5) aparece **0,5 s após o INÍCIO** da animação
   (`resolve_defensor`); sem Tela de Combate (simulação), aplica na hora.
2. **GUARDIÃO (ARCANJO/PANTEÃO):** **0,5 s após o pouso**, um **PILAR DE LUZ
   DO CÉU** dourado (1,0 s: o feixe desce do alto, firma pulsando com poeira
   de luz por dentro e anel no chão, então recolhe) cai sobre **cada campeão
   aliado, UM POR UM**; **0,5 s após o fim do pilar** de cada aliado, o ícone
   de **PROTEÇÃO** (1 rodada) aparece sobre aquele aliado
   (`resolve_guardiao`). Quem tem Guardião **não** se protege (§4.5 item 3).
3. Se o turno terminar antes de uma dessas animações resolver, o **flush de
   fim de turno** do motor aplica os efeitos pendentes na hora (o gameplay
   nunca espera a tela).

### 4.19 Invocar Dragão — o ovo que choca (1.49.93)
1. **CAMPEÃO (WYVERN/FERAGROSS) e TALENTO INVOCAR DRAGÃO:** **0,5 s após o
   pouso**, um **OVO DE DRAGÃO** (arte pintada `assets/OVO_DRAGAO*.png`,
   casca de escamas teal com faixas rúnicas douradas) é **materializado** no
   slot onde o Filhote aparecerá (espiral de faíscas + sombra + brilho),
   **treme** cada vez mais forte, **RACHA** com luz dourada vazando pelas
   fissuras e então **CHOCA**: a casca superior voa em lascas, uma
   **EXPLOSÃO DE LUZ** com **pilar de energia** e anel no chão inunda o slot
   (1,5 s no total).
2. **SÓ NO BURST DE LUZ** o **FILHOTE DE DRAGÃO** é invocado (`burst` →
   `resolve_invoke_dragon`) e cai no campo com a queda pesada padrão (§4.2)
   sobre o brilho que ainda esmaece. Campo cheio: avisa e não anima.
3. Sem Tela de Combate (simulação), o Filhote entra na hora.

### 4.20 Pesadelo — fantasmas sobre o campo e sobre o herói (1.49.93)
1. **ENXURRADA (2,0 s):** **0,5 s após o pouso** do Campeão com **PESADELO**
   (AKASHA/SUCCUBUS), ele abre um **vórtice sombrio** e lança **MUITOS
   FANTASMAS** (arte pintada estilo Boo, `assets/FANTASMA_PESADELO*.png`) e
   **FUMAÇA NEGRA** quase em **CONE** em direção ao campo adversário; cada
   fantasma voa ondulando e **implode em névoa roxa** ao chegar.
2. **SÓ NO FIM** da enxurrada o jogador afetado fica sem o **próximo saque
   livre** (`resolve_pesadelo` → `skip_draw`).
3. **HERÓI ASSOMBRADO:** após a enxurrada, **fantasminhas sobem em loop do
   topo do avatar do herói afetado, acima da moldura**, com fumaça negra e
   brilho roxo pulsante (versão simplificada da animação); o efeito visual
   **some quando TERMINA o turno do jogador afetado** (mesmo momento em que o
   bloqueio de saque já foi consumido no início desse turno).

## 5. Regras de partida (motor)

1. **3 ações** por turno; invocar custa o **Poder** da carta; atacar custa 1
   ação (2 contra Resistente/pesados; 0 com Investida/ação livre); comprar
   custa 1 ação.
2. **Compra automática de 1 carta** no início do turno (com a animação oficial).
3. **PV passivo:** +1 por campeão em campo no início do turno, teto 2/turno.
4. Combate: Poder maior vence; empate destrói ambos e **só o atacante pontua**
   (Sobrepujar altera empates); destruir campeão inimigo dá **1 PV** (2 com
   Recompensa Dupla); Sem Honra/Corrompido não dão PV.
5. **Vitória ao alcançar o objetivo** (10 ou 15 PV, escolhido na configuração).
6. **Ultimate:** 1 uso por turno, usos limitados por herói (3 ou 4; +1 com
   Energizar), alvo automático conforme o tipo do herói.
7. **Timer de 70 s:** ao zerar, a vez termina automaticamente.
8. **IA:** espera **2 segundos após o fim da animação de CADA ação** antes da
   próxima ação.
9. **MURALHA (constante):** fora do próprio turno o campeão ganha +1 de Poder
   e a muralha ativa; no início do próprio turno o bônus sai e a muralha
   some. **Se o campeão perder Poder FORA do próprio turno, ele perde o
   bônus da Muralha e a muralha QUEBRA na hora** (o ponto adicional é o ponto
   perdido); no início do próximo turno próprio ele **NÃO** perde Poder de
   novo; no fim do turno, a muralha é **reativada**.

## 6. Zoom, histórico e editor

1. **Zoom:** clique numa carta (mão/campo/histórico) amplia **centrado**, sem
   cortes, **nada por cima** (z 1000); fecha com clique na carta, fora dela,
   ou **ESC**. Os **status ativos** aparecem em coluna de linhas AO LADO da
   carta: **ícone à esquerda e texto SEMPRE à direita do ícone**, uma linha
   por status, sem sobreposição (um status não anula o outro).
2. **Histórico:** clique no **avatar do herói** abre painel com imagem/nome/
   habilidade do herói + lista **da última carta usada para a primeira**, com
   miniatura e **quem usou** (para a IA, o **nome do herói**).
3. No **zoom do Arsenal**, navega-se entre cartas com **setas do teclado** ou
   **swipe** (dedo no celular / arrasto do mouse), além dos botões ‹ ›; o
   contador de posição é único e legível.
4. **EDITOR** disponível em **TODAS as telas** (Hub, configuração da partida,
   Arsenal e batalha; exceto a CAPA): todo elemento de UI é registrado
   **INDIVIDUALMENTE** e editável — arrastar; **redimensionar estilo
   Photoshop (Ctrl+T)** com **8 alças arrastáveis** (cantos e meios das
   bordas) no elemento selecionado (sem botões −/+); **clique seleciona o
   MENOR retângulo que contém o ponto** (pega elementos sob outras camadas,
   ex.: o banner dentro do field); **DELETE exclui**, **Ctrl+Z desfaz**,
   **setas do teclado MOVEM** o elemento selecionado (Shift = passo maior),
   **ESC/SAIR salva automaticamente** (um arquivo por tela). O editor
   destaca/seleciona **SOMENTE elementos da tela/página ATUAL**. A barra do
   editor é **compacta** e os botões SALVAR/RESETAR/SAIR são **pequenos e
   sempre clicáveis** (o release do mouse sobre a barra não é consumido);
   nós liberados por troca de página são **purgados** automaticamente (sem
   "previously freed" / congelamento).

---
*Fim do manual. Alterações apenas por solicitação explícita do dono do projeto.*

## 7. PERFIL, PROGRESSÃO E HUB (imitados do projeto original do GitHub)

1. **Hub do Jogador:** widget de **PERFIL** (avatar em quadrado arredondado com
   moldura personalizável, nome editável, XP/nível/moedas) — clicar abre a
   tela de Perfil; e **8 ícones pequenos**: OPÇÕES, JORNADA, RANK*, PASSE DE
   BATALHA*, CONQUISTAS, HISTÓRIA*, COMO JOGAR* e NOTAS (* = em construção).
2. **PERFIL:** nome editável, XP, nível, rank, estatísticas, TROCAR DE FUNDO
   (4 fundos, aplicados à **batalha** — o Hub permanece sem imagem), personalização de **cor do avatar** e **moldura do avatar**,
   atalhos para CONQUISTAS / JORNADA / OPÇÕES.
3. **CONQUISTAS:** 10 famílias portadas do original (duelist, scourge,
   collector, openhand, medal, victor, hunter, heroes, fury, master) com 5
   níveis cada e moedas; claim automático ao concluir.
4. **JORNADA DO JOGADOR:** níveis 1–62 portados do original (herói liberado em
   níveis específicos; +4 moedas nos demais), claim automático.
5. **RANK local:** faixas do original (Bronze→Mítico) por % de vitórias com
   mínimo de 15 partidas; ranqueado online = em construção.
6. **Recompensas de partida vs IA:** vitória +4 XP/+1 moeda; derrota +2 XP.
7. **VERSIONAMENTO (REGRA PERMANENTE):** a versão atual começa em **1.49.60**
   e **sobe a cada atualização** (nunca chegando a 2.0). A aba **NOTAS** deve
   ser atualizada **junto com cada atualização do jogo**, listando o resumo
   das mudanças da versão; somente as **10 últimas** atualizações ficam em
   Notas.
8. **Editor de layout presente em TODAS as telas novas** (perfil, conquistas,
   jornada, notas, placeholders, mercado, etc.).
