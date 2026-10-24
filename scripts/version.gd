class_name GameVersion
## Versionamento oficial do jogo (regra do manual):
## - começa em 1.49.60 e SOBE a cada atualização (nunca chega a 2.0);
## - a aba NOTAS deve ser atualizada JUNTO com cada atualização do jogo;
## - somente as 10 ÚLTIMAS atualizações ficam listadas em Notas.

const CURRENT := "1.49.93"

const NOTES := [
	{
		"ver": "1.49.93",
		"data": "2026-10-22",
		"mudancas": [
			"DEFENSOR: 0,5 s após o pouso, uma DEFESA ÉPICA dourada de 1,5 s (runas no chão, domo de energia, brasão de luz e poeira dourada) cobre o Campeão; o ícone de PROTEÇÃO aparece 0,5 s após o início dela.",
			"GUARDIÃO: 0,5 s após o pouso, um PILAR DE LUZ DO CÉU (1 s) cai sobre cada campeão aliado UM POR UM; 0,5 s após o pilar de cada um, o ícone de PROTEÇÃO aparece sobre aquele aliado.",
			"BAFORADA VENENOSA refeita: agora é um SOPRO DE DRAGÃO VERDE de verdade — cone SUSTENTADO de fogo verde com núcleo incandescente, línguas de chama, fumaça escura e brasas que ENGOLFA o alvo (chamas lambendo a carta) e só cessa no fim.",
			"MORDIDA VENENOSA AAA: a cabeça da SERPENTE VENENOSA (arte pintada com presas neon) dá o BOTE do céu, CRAVA AS PRESAS no alvo (clarão, anel, respingos, marcas de presa, baba e névoa tóxica) e recua; o veneno entra só no fim.",
			"INVOCAR DRAGÃO: 0,5 s após o pouso um OVO DE DRAGÃO (arte pintada em 3 estados: inteiro, rachado com luz e chocando) aparece no slot do Filhote, treme, racha e CHOCA com explosão de luz e pilar de energia (1,5 s); só então o FILHOTE cai no campo.",
			"PESADELO: 0,5 s após o pouso o campeão lança MUITOS FANTASMAS (estilo Boo, arte pintada) e FUMAÇA NEGRA em cone sobre o campo adversário (2 s); depois, fantasminhas e fumaça sobem em LOOP acima da moldura do herói afetado até o fim do turno dele (sem saque livre).",
			"Segurança de motor: Defensor/Guardião/Pesadelo/Invocar Dragão ficam PENDENTES durante a animação e o flush de fim de turno aplica qualquer efeito restante (gameplay nunca espera a tela); novo teste t_93; pack web reexportado — Ctrl+F5.",
		],
	},
	{
		"ver": "1.49.92",
		"data": "2026-10-23",
		"mudancas": [
			"CONGELADO sem cristal de gelo sobre a carta (Rajada Congelante e Zero Absoluto): após a explosão de gelo, o campeão fica SOMENTE com o ÍCONE de CONGELADO no canto superior direito, empilhado na ordem de aquisição; a tinta azulada e os detalhes no zoom continuam.",
			"BAFORADA VENENOSA (Talento) agora abre MIRA VERDE-VENENO (o dono escolhe o Campeão adversário, como diz o texto da carta; a IA escolhe após 1,6 s) e ganhou a animação do SOPRO DO DRAGÃO VERDE: cometa de chamas verdes com núcleo incandescente, fumaça escura, brasas pontilhadas e feixe na cauda, voando da carta Talento até o alvo.",
			"O ENVENENADO da Baforada só é aplicado NO FIM do sopro e aparece em campo SOMENTE como ícone no canto superior direito; SEM HONRA segue só com o ícone de caveira no canto e a morte especial preservada.",
			"Novo teste de regressão t_92 (ícone do CONGELADO sem cristal + mira/veneno da Baforada + VFX do sopro + integração na Tela de Combate); pack web (index.pck) reexportado — no navegador, Ctrl+F5.",
		],
	},
	{
		"ver": "1.49.91",
		"data": "2026-10-23",
		"mudancas": [
			"STATUS EM CAMPO SEM ANIMAÇÃO PERSISTENTE: PROTEÇÃO (redoma), SEM HONRA (caveira pulsante), ENVENENADO (símbolo + bolhas) e FÚRIA (aura vermelha com olhos) viraram SOMENTE um ÍCONE PEQUENO no CANTO SUPERIOR DIREITO da carta; com vários status, os ícones empilham de CIMA para BAIXO na ORDEM DE AQUISIÇÃO; os detalhes de cada status continuam no zoom da carta.",
			"SEM HONRA: após a destruição de um campeão com o status, os aliados só se REORGANIZAM no campo 0,5 s APÓS o FIM da animação de morte especial (explosão roxa + caveira) — antes, deslizavam durante a explosão.",
			"FÚRIA e GRITO DE GUERRA mantêm o RAIO VERMELHO caindo sobre o campeão e a MORDIDA VENENOSA mantém a animação da mordida — somente as camadas PERSISTENTES (aura/olhos, bolhas, redoma, caveira) saíram do jogo.",
			"Novo teste de regressão t_91 (pilha de ícones + ordem de aquisição + reorganização tardia do SEM HONRA); pack web (index.pck) reexportado — no navegador, Ctrl+F5.",
		],
	},
	{
		"ver": "1.49.90",
		"data": "2026-10-23",
		"mudancas": [
			"O JOGO VOLTA A ABRIR: corrigidos os erros de compilação da 1.49.89 — a chamada _apply_mordida passava os argumentos trocados e o blend aditivo 'CanvasItem.BLEND_MODE_ADD' NÃO existe no Godot 4.7 (os VFX de Mordida, Raio/Fúria e as camadas de status agora usam o material aditivo oficial do projeto, Vfx.add_mat()).",
			"MORDIDA VENENOSA, FÚRIA e GRITO DE GUERRA revalidados headless: o status só entra DEPOIS do fim da animação (porta fx) e na hora em simulações; os VFX de mordida e raio tocam inteiros e emitem 'finished' sem nenhum erro de script.",
			"Pack web (index.pck) REEXPORTADO com as correções — no navegador, atualize com Ctrl+F5.",
		],
	},
	{
		"ver": "1.49.89",
		"data": "2026-10-23",
		"mudancas": [
			"NOVA ANIMAÇÃO MORDIDA VENENOSA: ao entrar em campo, os inimigos aptos ficam destacados em VERDE-VENENO; ao confirmar, duas mandíbulas verdes se fecham sobre o alvo com impacto (clarão, anel, respingos e marcas de presa) e ele recebe ENVENENADO (morre em 2 rodadas).",
			"ENVENENADO persistente: a carta fica ESVERDEADA e ganha um símbolo de veneno (bio-risco verde com bolhas subindo) pulsando SOBRE ela; novo ícone do status na carta ampliada com contagem de rodadas.",
			"NOVA ANIMAÇÃO FÚRIA: 1s após invocar, um RAIO VERMELHO serrilhado (1,5s) cai do céu sobre o campeão com estrela de impacto, lascas e brasa no chão; 0,5s depois ele ganha FÚRIA: aura vermelha que SOBE do chão com dois OLHOS FURIOSOS, persistente enquanto o status durar.",
			"NOVA ANIMAÇÃO GRITO DE GUERRA (campeão e carta TALENTO): 1s após invocar, raios vermelhos de 1,0s caem UM A UM em cada campeão aliado (menos no invocador); 0,5s após cada raio o aliado ganha FÚRIA com a mesma aura persistente.",
			"TEXTOS DAS CARTAS: entrelinha padrão 0.88 e TODOS os textos centralizados por padrão; a descrição nunca fica incompleta nem vaza da área branca (fit automático por fonte).",
		],
	},
	{
		"ver": "1.49.87",
		"data": "2026-10-22",
		"mudancas": [
			"EDITOR DE CARTA em tempo real: arrastar as alças já redimensiona o box E o texto ao vivo (igual ao resize de elementos); box de seleção agora envolve o texto de verdade (alinhado à esquerda quando não centralizado).",
			"EDITOR DE CARTA: dois cliques num texto abrem o editor de texto SOMENTE daquela zona (nome, habilidade, descrição ou selo); selo Campeão/Talento/Reação também redimensionável (alças com afastamento mínimo).",
			"EDITOR DE CARTA: ZOOM com scroll do mouse (1x–4x, estilo visualizador de imagem); clicar fora NÃO fecha mais — só ESC ou o novo botão VOLTAR; SALVAR mostra 'ATUALIZAÇÕES SALVAS!' e permanece no editor.",
			"NOVA ANIMAÇÃO CONGELAR / ZERO ABSOLUTO: mira AZUL nos inimigos aptos (como a Bola de Fogo); ao confirmar, coluna de luz + anel de gelo no chão + burst de cristais; o congelado fica azulado com cristal de gelo no centro; Zero Absoluto congela 2 rodadas (destrói se já congelado); ícone de floco no zoom.",
		],
	},
	{
		"ver": "1.49.86",
		"data": "2026-10-22",
		"mudancas": [
			"MÃO corrigida: todas as cartas com o MESMO tamanho (spawn por fade, sem escala residual) e mão mais junta/centrada na tela com arco menor — 8 cartas não encostam mais nos hubs dos heróis.",
			"FORJA simplificada e sem bug: o campeão entra NORMALMENTE e 0,5 s depois o jogador ganha 1 carta com a MESMA animação de compra (saque livre, sem ação); martelo/bigorna removidos.",
			"EDITOR DE CARTA: o box vermelho de edição agora ACOMPANHA o tamanho real do texto (nome/habilidade/descrição/selo) e arrastar as alças LATERAIS re-quebra o parágrafo na nova largura (estilo Photoshop).",
			"EDITOR DE CARTA: a troca de FONTE agora vale para TODOS os textos da carta (nome, habilidade, selo, descrição), não só a descrição.",
		],
	},
	{
		"ver": "1.49.85",
		"data": "2026-10-22",
		"mudancas": [
			"EDITOR DE CARTA: removidos os botões A+/A- — agora cada zona de texto selecionada ganha ALÇAS estilo Ctrl+T que aumentam/diminuem o TEXTO só daquela zona e só daquela carta (sem espelhar em outros textos); setas do teclado movem a zona.",
			"EDITOR: clicar em outro elemento/zona já SELECIONA ele na hora (sem sair e voltar); setas do teclado movem o elemento selecionado também no editor de layout.",
			"EDITOR: destaca e seleciona SOMENTE elementos da tela/página ATUAL (nada de highlights de outras telas).",
		],
	},
	{
		"ver": "1.49.84",
		"data": "2026-10-22",
		"mudancas": [
			"EDITOR: barra compacta com botões SALVAR/RESETAR/SAIR PEQUENOS e sempre funcionais (o clique não era mais consumido na barra); nós de páginas trocadas são purgados — fim do congelamento 'previously freed' após salvar carta.",
			"EDITOR DE CARTA: botões A+/A- ajustam o tamanho dos TEXTOS da carta; editor de texto ganhou ENTRELINHA (L-/L+), além de Enter=quebra real, negrito por trecho, centralizar e fonte.",
			"CANSADO: zzz mais GROSSOS (corpo maior + contorno) saindo da JANELA DE ARTE do campeão; ícone de sono refeito (lua + olhos fechados + Zz).",
			"FORJA: VFX carregado por caminho direto (imune a cache de classes) — a animação aparece e o campeão NÃO some durante ela.",
		],
	},
	{
		"ver": "1.49.83",
		"data": "2026-10-22",
		"mudancas": [
			"Linha central e banner de turno MAIS FINOS (banner 32 px, borda 1 px) e SEM o contador 'Turno N'.",
			"Fim da 'parede invisível': o banner não fica mais por cima de cartas/VFX (zzz do CANSADO e MURALHA aparecem inteiros); clip das cartas removido.",
			"FORJA corrigida: a animação do martelo/bigorna agora é orquestrada pela Tela de Combate (aparece sempre) e a carta entra no campo só no fim dela, com saque livre 0,5 s depois.",
			"EDITOR estilo Photoshop: botões -/+ removidos — redimensione pelas 8 ALÇAS arrastáveis (cantos/bordas) do elemento selecionado; seleção pelo MENOR retângulo (pega o banner sob o field); cada ícone do Hub é elemento INDIVIDUAL; Arsenal e páginas com mais elementos registrados.",
			"EDITOR DE TEXTO da carta: ENTER vira quebra de linha real, NEGRITO por trecho selecionado, CENTRALIZAR e troca de FONTE (Baloo/Fredoka/Heavy).",
		],
	},
]


static func next_version() -> String:
	# incremento 1.49.X -> 1.49.X+1 (jamais 2.0)
	var parts := CURRENT.split(".")
	var minor := int(parts[2]) + 1
	return "%s.%s.%d" % [parts[0], parts[1], mini(minor, 99)]
