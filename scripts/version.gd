class_name GameVersion
## Versionamento oficial do jogo (regra do manual):
## - começa em 1.49.60 e SOBE a cada atualização (nunca chega a 2.0);
## - a aba NOTAS deve ser atualizada JUNTO com cada atualização do jogo;
## - somente as 10 ÚLTIMAS atualizações ficam listadas em Notas.

const CURRENT := "1.50.4"

const NOTES := [
	{
		"ver": "1.50.4",
		"data": "2026-10-26",
		"mudancas": [
			"INVOCAÇÃO: som de impacto AINDA mais pesado (transiente + sub 50->20 Hz saturado + doble baque + detritos + rumble de poeira) no instante exato da chegada.",
			"DESACELERAR: o som agora começa SOMENTE quando o relógio fica visível (0,25 s de animação) e termina ANTES do fim da animação (2,2 s de som em 2,6 s de VFX).",
			"ASSASSINAR: as cartas da linha só se REORGANIZAM 0,5 s APÓS o fim da morte especial da adaga (antes deslizavam durante a animação).",
			"GUARDIÃO: som de CHORUS CELESTIAL com vozes sopranas (formantes de 'ah' cantado em acorde C5-E5-G5-C6 com vibrato), breve — toca em cada pilar de luz de cada aliado.",
			"NOVA animação CORROMPER (Habilidade e Talento): 0,5 s após a escolha, AURA NEGRA de 1,5 s envolve o campeão (vórtices contrarrotativos, névoa, partículas sugadas, carta escurecida) com som de medo/trevas; o status SEM HONRA só entra 0,5 s DEPOIS do fim da aura.",
			"NOVA animação SOBREPUJAR: em combate com Poder igual, ao voltarem aos lugares o vencedor ganha ESCUDO dourado de 1,5 s e o perdedor tem destruição especial CONTIDA no slot: SOCOS (POPPY: estrelas de impacto, sacudidas e poeira) ou RAPIEIRA (A DUELISTA: 5 cortes finos com faíscas) por 1,5 s, e então a destrução padrão — sem mudar tamanho, sem sair do lugar.",
			"Sons novos: corromper (drone + sussurros + tritono + batidas), punch, rapier e escudo; central Sfx com 30 chaves.",
			"Testes t_90–t_99 + smoke OK (t_99: corromper pendente, reorg do assassinar, sobrepujar); pack web reexportado — Ctrl+F5.",
		],
	},
	{
		"ver": "1.50.3",
		"data": "2026-10-25",
		"mudancas": [
			"SAQUE LIVRE com ritmo: a compra automática do início da partida só acontece 1,0 s após o começo; após passar a vez, o saque do próximo jogador acontece 0,5 s depois (antes era instantâneo).",
			"NOVA animação ACELERAÇÃO (Talento): 1 s após a carta entrar em campo, 1,5 s de velocidade divertida — dashes zig-zag com PÓS-IMAGENS translúcidas da própria carta, linhas de velocidade, poeira cartoon e boom sônico com anel duplo, tudo contido no slot; som de zip-zip-vroom.",
			"ASSASSINAR CONTIDO no espaço da carta (regra do dono): adaga menor (70 px), corte e metades separando no MÁXIMO 8 px no próprio lugar, pedaços pequenos voando baixo e perto (+ fumaça/anel/faíscas contidos, impacto igual à destruição padrão); nada cresce nem ocupa a tela.",
			"SONS ESPECÍFICOS (nada de campainha): DESACELERAR = relógio com ponteiros girando RÁPIDO e DESACELERANDO (ticks 25 Hz -> 2 Hz + catraca + tock final); COMPRA = página de livro CURTA; INVOCAÇÃO = impacto pesado de pedra no instante da chegada; OVO = crackle/rangido de casca e choco com boom+asas (sem sino); CONGELAR/FORTALECER/ROUBO/ULTIMATE sem pings de sino.",
			"Testes t_90–t_98 + smoke OK (t_98: saque 1,0 s/0,5 s, aceleração 1,5 s e Assassinar contido na área da carta); pack web reexportado — Ctrl+F5.",
		],
	},
	{
		"ver": "1.50.2",
		"data": "2026-10-25",
		"mudancas": [
			"INVOCAR DRAGÃO: MESMO roteiro/animação, agora com TEXTURAS PINTADAS semi-3D estilo Hearthstone (linguagem da BAFORADA VENENOSA): 4 estados recortados do fundo preto com keying profissional (sem caixa preta).",
			"CARTA TALENTO: só sai do campo 0,5 s DEPOIS do fim da animação dela (Filhote de Dragão e Desacelerar registrados no _talent_anim_until; regra já valia p/ Bola de Fogo/Forja/Fortalecer).",
			"ASSASSINAR agora abre MIRA de verdade: campeões adversários com Poder 1 ficam DESTACADOS (vermelho) e o jogador ESCOLHE o alvo (IA pensa 1,6 s e escolhe); animação inicia 0,5 s após a escolha; a carta destruída NÃO muda de tamanho (metades/pedaços na escala real em tela); som de ESPADA DESEMBAINHADA no corte e estilhaços sem sino.",
			"PESADELO: a fumaça negra e os fiapos agora nascem NO CAMPEÃO que invocou — nunca mais no canto da tela (emissores estavam na origem do layer).",
			"SONS REFEITOS: PROTEÇÃO = baque pesado de escudo (placa grossa + sub + domo, sem campainha); GUARDIÃO = hit divino/orquestral (boom + coro formante + shimmer de ar); DESACELERAR = relógio com ponteiros girando rápido e DESACELERANDO (ticks + catraca desacelerando + tick final); COMPRA = virar página de livro; MORDIDA = mordida impactante (clap de mandíbula + crunch + squelch).",
			"Testes t_90–t_97 + smoke OK (t_97 valida mira do Assassinar com escolha + delay); pack web reexportado — Ctrl+F5.",
		],
	},
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
