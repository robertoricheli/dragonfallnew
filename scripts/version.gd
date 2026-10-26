class_name GameVersion
## Versionamento oficial do jogo (regra do manual):
## - começa em 1.49.60 e SOBE a cada atualização (nunca chega a 2.0);
## - a aba NOTAS deve ser atualizada JUNTO com cada atualização do jogo;
## - somente as 10 ÚLTIMAS atualizações ficam listadas em Notas.

const CURRENT := "1.50.1"

const NOTES := [
	{
		"ver": "1.50.1",
		"data": "2026-10-25",
		"mudancas": [
			"INVOCAR DRAGÃO REFEITA SEM NENHUM ASSET: o ovo agora é PINTADO POR CÓDIGO em runtime (4 estados: casca teal com escamas e faixas rúnicas -> fissuras finas -> fissuras fundas com luz -> casca aberta com miolo de luz), no MESMO roteiro (materializa no slot, treme, racha, choca com pilar e faíscas, 2,0 s, Filhote no burst); os PNGs do ovo foram excluídos.",
			"SONS DURANTE as animações (problema sério corrigido): Pesadelo, Desacelerar e Ovo tocavam 0,5 s ANTES do VFX existir — agora cada som dispara no instante em que a animação nasce na tela.",
			"ASSASSINAR corrigido: a carta destruída NÃO cresce mais (metades e pedaços escalados para o tamanho real da carta) e a animação inicia MEIO SEGUNDO após a escolha do alvo (alvos Poder 1 continuam destacados em vermelho na mira).",
			"SOM DE INVOCAÇÃO = IMPACTO puro no instante em que o campeão chega ao campo (baque profundo de pedra sem swish antes); SOM DE COMPRA = virar página de livro; SOM DE COMBATE = golpe de arma real (whoosh + clang seco + baque), sem sino/campainha.",
			"Assets não usados excluídos (regra permanente): OVO_ARTE_P1..P4.png.",
			"Testes t_90–t_97 + smoke OK (t_97 agora valida o delay de 0,5 s e que nada aparece antes); pack web reexportado — Ctrl+F5.",
		],
	},
	{
		"ver": "1.50.0",
		"data": "2026-10-25",
		"mudancas": [
			"CRASH da animação ASSASSINAR corrigido: Sprite2D não tem pivot_offset — as metades/pedaços agora giram ao redor do próprio centro via offset (erro de runtime eliminado).",
			"ADAGA repintada no estilo Hearthstone (semi-3D pintado, proporções estilizadas — nada fotorealista) e recortada do fundo preto com keying profissional (sem caixa preta na cena).",
			"SOM DE TURNO REMOVIDO: nada toca ao passar a vez nem no início da partida (regras do dono); a chave 'turn' saiu da central Sfx.",
			"SOM DE INVOCAÇÃO COM MAIS IMPACTO: baque profundo de pedra (sub 68->26 Hz com drive), corpo de impacto, 'tock' de madeira, detritos e poeira assentando, com reverberação.",
			"ASSETS NÃO USADOS EXCLUÍDOS (regra permanente): ICO_CORROMPIDO/ICO_CRISTAL/ICO_EXAUSTO.svg, VFX_FORTALECER.png, VFX_VENENO.png, protecao.gdshader e turn.wav.",
			"Testes t_90–t_97 + smoke OK (t_97 valida a adaga ponta-a-ponta sem erros); pack web reexportado — Ctrl+F5.",
		],
	},
	{
		"ver": "1.49.99",
		"data": "2026-10-25",
		"mudancas": [
			"ÁUDIO v2 (projeto aprovado): os 26 sons das animações foram REFEITOS com síntese profissional em camadas (grãos de ruído varrido, sub-graves com pitch-drop, parciais inarmônicos metálicos, crackles, caudas de reverberação) — nada de sons 8-bit; cada som toca DURANTE a animação (raio no impacto do raio, defensor no selamento do domo, guardião no pilar firmando, mordida no bote, ovo no choco...) e casa com a habilidade (whoosh+explosão na Bola de Fogo, cristais no Congelar, ticks no Relógio, sussurros no Pesadelo...).",
			"PARIDADE IA/jogador (regra do dono): invocação de Campeões e entrada de Talento/Reação agora usam o MESMO processo nos dois lados (queda + impacto pesado); o cone do PESADELO volta a nascer do campeão que invocou TAMBÉM para a IA (guarda anti-duplicata mantida).",
			"INVOCAR DRAGÃO REFEITA DO ZERO (mesmo roteiro, identidade BOLA DE FOGO/MORDIDA): 4 estados pintados semi-3D novos (inteiro -> fissuras -> fissuras fundas -> choco) com CROSSFADE, materialização com espiral de faíscas, tremor crescente com squash, poeira, anel rúnico, feixes, lascas orbitando, explosão com pilar de energia e faíscas — contida no slot (<=112x132 px), 2,0 s, Filhote imediato no burst.",
			"NOVA animação ASSASSINAR (morte especial): alvos com Poder 1 já destacados em VERMELHO pela mira do motor; 0,5 s após a escolha, uma ADAGA espectral pintada materializa, golpeia em diagonal com rastro de corte, a carta é CORTADA AO MEIO (metades com a textura real caem girando) e se DESFAZ em 9 pedaços + fumaça — 2,0 s entre o corte e a destruição; sons de marca/corte/divisão/estilhaços.",
			"Testes t_90–t_97 + smoke OK (t_97: paridade, assassinar e 26 SFX); pack web reexportado — Ctrl+F5.",
		],
	},
	{
		"ver": "1.49.98",
		"data": "2026-10-25",
		"mudancas": [
			"ÁUDIO DAS ANIMAÇÕES (Fase 3 aprovada): central Sfx (autoload) com 22 sons sintetizados sob medida — simples e impactantes, um por animação/evento (invocar, comprar, atacar, destruir, bola de fogo, mordida, raio, congelar, baforada, fortalecer, defensor, guardião, pesadelo, desacelerar, ovo, forja, roubo, ultimate, turno...); pan pela posição X na tela, pitch ±4% e volume por evento.",
			"OVO DO DRAGÃO (Habilidade e Talento) com o vídeo NOVO do dono ('OVO NOVO', 71 frames recortados do fundo preto): e agora a linha ABRE o slot do Filhote ANTES do ovo aparecer (quem está em campo desliza 0,25 s para os slots da linha de n+1) — o ovo NUNCA mais aparece sobre a carta de quem usou; 2,0 s e Filhote imediato após o fim.",
			"DEFENSOR: o 2º círculo (rodas de runa) subiu da parte de baixo para o CENTRO da carta (regra do dono); o domo/aro ao redor da carta permanece intocado.",
			"Novo teste t_96 (Sfx com 22 sons + play headless; slot do ovo livre a >= 100 px do caster; runas do defensor no centro); pack web reexportado — Ctrl+F5.",
		],
	},
	{
		"ver": "1.49.97",
		"data": "2026-10-25",
		"mudancas": [
			"INVOCAR DRAGÃO (Habilidade E Carta Talento) com o NOVO vídeo do dono ('OVO DE DRAGÃO', fundo PRETO): 67 frames recortados com keying profissional por conectividade — NADA do fundo preto aparece; pretos internos da arte preservados; bordas semi-transparentes com unblend; vinheta suave dissolve as lascas laterais.",
			"O ovo aparece SOMENTE no slot do Filhote (<= 112 px de largura, <= 140 px de altura): NUNCA em cima do campeão que usou a habilidade, nem encostando nele; duração 2,0 s e IMMEDIATAMENTE após o fim do vídeo o Filhote surge em campo.",
			"DESACELERAR (Habilidade e Talento) com o NOVO vídeo do dono (fundo PRETO): 60 frames do relógio arcano com engrenagens e vórtice de tempo, recortados sem nenhum resquício de fundo; 2,6 s sobre o campo adversário, um pouco maior que uma carta, contido na linha.",
			"MORDIDA VENENOSA mantida como na 1.49.96 (vídeo recortado do fundo branco, 0,5 s após o alvo, menor que a carta).",
			"Testes t_90–t_95 + smoke OK (t_95 valida 67/60 frames, largura do ovo <= 116 px e relógio > carta); pack web reexportado — Ctrl+F5.",
		],
	},
	{
		"ver": "1.49.96",
		"data": "2026-10-24",
		"mudancas": [
			"INVOCAR DRAGÃO (Habilidade E Carta Talento) agora usa o VÍDEO do dono 'FILHOTE DE DRAGÃO': 54 frames recortados do fundo branco com keying profissional (bg transparente, miolo de luz preservado com glow aditivo 'de dentro'); o ovo aparece SOMENTE no slot do Filhote (94x132 px, nunca encosta no campeão que usou) por 2,0 s e IMMEDIATAMENTE após o fim do vídeo o Filhote surge em campo.",
			"MORDIDA VENENOSA agora usa o VÍDEO do dono: 40 frames recortados profissionalmente; 0,5 s após a seleção do alvo a mandíbula venenosa (120 px, MENOR que as cartas) aparece SOBRE o campeão alvo com brilho tóxico, anel e gotas no impacto; veneno aplicado no fim (1,33 s).",
			"DESACELERAR (Habilidade e Talento) agora usa o VÍDEO do dono: 78 frames recortados do fundo branco; o relógio arcano (170 px, um pouco maior que a carta) roda integralmente por 2,6 s sobre o campo adversário, contido na linha, com anel rúnico local, ticks e areia de tempo.",
			"Recortes dos vídeos feitos com keying profissional: fundo branco virou alpha transparente por conectividade (brancos internos do glow preservados), bordas semi-transparentes com unblend — sem nenhum resquício de fundo branco em campo.",
			"Assets das animações anteriores (sheets 1.49.95) removidos do projeto; teste t_95 reescrito (tamanhos/slot/delay/veneno); pack web reexportado — Ctrl+F5.",
		],
	},
	{
		"ver": "1.49.95",
		"data": "2026-10-24",
		"mudancas": [
			"INVOCAR DRAGÃO com o SPRITE SHEET pintado do dono (20 frames: ovo aparece, racha, choca e vira luz): a sequencia roda SOMENTE sobre o slot onde o Filhote vai cair (nada de flash/pilar na tela inteira), com cadencia variavel, sombra, anel runico, tremor, clarao contido, lascas e faiscas locais.",
			"MORDIDA VENENOSA refeita com a SERPENTE MAGICA VERDE pintada (arte do dono): ela NASCE da carta Campeao em campo, DESLIZA pelo campo em curva com ondulacao e rastro de vapores, mira uma pausa e da o BOTE cravando a mordida no alvo (clarao, anel, marcas de presa, respingos e poca de veneno); nunca maior que uma carta em campo; duracao 2,0 s.",
			"DESACELERAR (Campeao e Talento) refeito com o SPRITE SHEET do relogio arcano do dono (20 frames: materializa, ponteiros para tras, vortice de tempo, dissolve): aparece por 2,0 s sobre o campo adversario UM POUCO MAIOR que uma carta, contido na linha adversaria, com anel runico local, ticks e areia de tempo.",
			"Assets antigos das animacoes substituidas foram removidos do projeto (ovo/mordida/relogio da 1.49.94 e anteriores) — o historico do git os preserva.",
			"Novo teste de regressao t_95 (tamanhos/limites das 3 animacoes: ovo no slot, serpente <= carta, relogio > carta e contido; mordida origem->alvo na Tela de Combate com veneno no fim); pack web reexportado — Ctrl+F5.",
		],
	},
	{
		"ver": "1.49.94",
		"data": "2026-10-24",
		"mudancas": [
			"DIREÇÃO DE ARTE NOVA (pintura digital semi-3D, referência Hearthstone): todos os assets de animação criados agora (ovo, mandíbula, relógio) são arte pintada sobre fundo preto com blend aditivo — nunca cartoon, nunca fotorrealista.",
			"PESADELO da IA não abre mais no topo/esquerda da tela: o cone de fantasmas desce do centro da tela direto sobre o campo do jogador afetado; guarda anti-duplicata garante UM cone por invocação.",
			"INVOCAR DRAGÃO refeito com o MESMO roteiro: 5 estados pintados do ovo (inteiro -> fissuras finas -> fissuras fundas com feixes -> casca explodindo -> casca aberta) + tremor crescente com squash&stretch, poeira, anel rúnico no chão, lascas, explosão, anel de choque e pilar de energia.",
			"NUNCA mais texto amarelo/redundante de status sobre a carta do campeão em campo: BARREIRA/ENVENENADO/CHAMAS/FÚRIA/PRESO/SILENCIADO/ENFEITICADO são comunicados SOMENTE pelos ícones no canto superior direito (pilha por ordem de aquisição) e pelos detalhes no zoom.",
			"BARREIRA sem o painel pulsante sobre a carta (Campeões e Talento): o status virou ícone na pilha do canto (mesma linguagem da 1.49.91); os detalhes continuam no zoom da carta.",
			"MORDIDA VENENOSA NOVA sem cobra: uma MANDÍBULA ESPECTRAL DE PRESAS venenosas (4 frames pintados) abre sobre o alvo, dá o BOTE em 0,12 s com clarão, anel, marcas de presa e respingos de veneno, treme cravada escorrendo veneno e dissolve em névoa tóxica.",
			"NOVA animação DESACELERAR (Campeão e Talento): 0,5 s após a carta entrar em campo, um RELÓGIO MÁGICO de fantasia (bronze, runas, cristal ciano — nada moderno) aparece por 2,0 s sobre o campo adversário com ponteiros VOLTANDO PARA TRÁS em ticks, ondas temporais em câmera lenta e areia rúnica.",
			"Novo teste de regressão t_94 (pesadelo da IA sem duplicata no topo + campo afetado; sem texto de status; barreira como ícone; VFX ovo/mordida/relógio rodando headless); pack web reexportado — Ctrl+F5.",
		],
	},
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
]


static func next_version() -> String:
	# incremento 1.49.X -> 1.49.X+1 (jamais 2.0)
	var parts := CURRENT.split(".")
	var minor := int(parts[2]) + 1
	return "%s.%s.%d" % [parts[0], parts[1], mini(minor, 99)]
