class_name CardDB
## Banco de cartas/heróis do Dragonfall — portado fielmente de motor/df-data.js (GitHub).

const HEROES := [
	{"id": "vaughan", "name": "Rei Bomba", "ult": "Bomba Explosiva", "ult_desc": "Escolha um Campeão adversário. Ele perde 1 ponto de Poder. Se chegar a 0 será destruído. Até 4 usos."},
	{"id": "iceWitch", "name": "Frosty", "ult": "Congelar", "ult_desc": "Escolha um campeão adversário. Ele fica congelado por 3 rodadas. Até 3 usos."},
	{"id": "linguarudo", "name": "Florisbella", "ult": "Fortalecer", "ult_desc": "Escolha um campeão aliado. Ele ganha +1 de poder. Até 4 usos."},
	{"id": "pirate", "name": "Tina Punker", "ult": "Investida", "ult_desc": "Escolha um campeão aliado. Ele pode realizar um ataque com ação livre neste turno. Até 4 usos."},
	{"id": "euravia", "name": "Eurávia", "ult": "Conjuração", "ult_desc": "Compre uma carta imediatamente (ação livre). Pode usar até 4 vezes."},
	{"id": "ironGuard", "name": "Bastion", "ult": "Proteção", "ult_desc": "Todos os seus Campeões com Poder 1 em campo ficam com Proteção (não podem ser atacados) por 1 rodada. Até 3 usos."},
	{"id": "princesaSlime", "name": "Princesa Slime", "ult": "Travessura", "ult_desc": "Escolha um Campeão aliado de Poder 1. Ele troca de lugar com um Campeão adversário (prioriza Poder 2, depois 3+, depois 1). Até 3 usos."},
	{"id": "thor", "name": "Thor", "ult": "Trovoada", "ult_desc": "Todos os jogadores adversários descartam 1 carta da mão imediatamente. Até 4 usos."},
	{"id": "jekiro", "name": "Jekiro", "ult": "Fogo e Gelo", "ult_desc": "Afeta TODOS os Campeões adversários. Cada um tem 50% de chance de ser CONGELADO por 2 rodadas e 50% de chance de receber BOLA DE FOGO (-1 Poder). Até 3 usos."},
	{"id": "sangueDragao", "name": "Sangue de Dragão", "ult": "Invocar Dragão", "ult_desc": "Invoca um Dragão Azul no seu campo como ação livre. Até 3 usos."},
	{"id": "gancho", "name": "Gancho", "ult": "Puxão", "ult_desc": "Puxa um Campeão adversário com Poder menor que 3 (65% chance de Poder 1, 35% de Poder 2) e o ROUBA permanentemente pro seu campo. Até 3 usos."},
	{"id": "paladino", "name": "Paladino", "ult": "O Retorno do Herói", "ult_desc": "Traz de volta ao campo um Campeão de Poder 2 do seu descarte. Campeões com Habilidade Constante voltam aptos a usá-la; Habilidades Instantâneas não disparam nesta invocação. Até 3 usos."},
	{"id": "alquimista", "name": "Alquimista", "ult": "Poção Improvável", "ult_desc": "Escolha um Campeão seu: 60% de chance de +2 de Poder ou 40% de -1 (pode destruir se zerar). Até 3 usos."},
	{"id": "valmont", "name": "Valmont", "ult": "Vampirismo", "ult_desc": "Escolha um Campeão adversário com Poder 2 ou mais. Ele perde 1 Poder e um Campeão aliado aleatório ganha +1 Poder. Até 3 usos."},
	{"id": "tecnomago", "name": "Tecnomago", "ult": "Outra Dimensão", "ult_desc": "Escolha um Campeão adversário com Poder 2 ou menos. Ele é Banido do jogo (nem vai pro descarte) — você NÃO ganha PV. Até 3 usos."},
	{"id": "quimera", "name": "Quimera", "ult": "Envenenar", "ult_desc": "Escolha um Campeão adversário. Ele fica envenenado e será destruído em 2 rodadas (no início do seu 2º próximo turno). Até 3 usos."},
	{"id": "hercules", "name": "Hércules", "ult": "Força Infinita", "ult_desc": "TODOS os seus Campeões aliados em campo ganham +1 de Poder permanente a cada rodada (igual ao Filhote de Dragão). Até 3 usos por partida."},
	{"id": "sinistrela", "name": "Sinistrela", "ult": "Amedrontar", "ult_desc": "Escolha um Campeão adversário com Poder 2 ou menos. Ele retorna à mão do dono com o Poder base. Até 3 usos."},
	{"id": "estrelar", "name": "Estrelar", "ult": "Cometa Estrelar", "ult_desc": "Um cometa cai no campo: TODOS os Campeões (aliados e adversários) perdem 1 de Poder. Você só ganha PV pelos Campeões adversários destruídos — destruir os seus próprios não dá PV. Até 3 usos."},
	{"id": "diablos", "name": "Diablos", "ult": "Incinerar", "ult_desc": "Escolha um Campeão adversário. Ele fica Em Chamas por 4 rodadas, perdendo 1 ponto de Poder por rodada (igual à Habilidade Incendiar). Até 3 usos."},
	{"id": "tristana", "name": "Tristana", "ult": "Reutilização", "ult_desc": "Escolha um Campeão aliado com Habilidade Instantânea. Ele usa a Habilidade Instantânea de novo, como se tivesse acabado de entrar em campo. Até 3 usos."},
]

const CARDS := [
	{"name": "CAVALEIRO DA NOITE", "power": 1, "category": "champion", "ability_type": "constant", "ability_name": "Sem Honra", "ability_desc": "O Adversário Não ganha\nPonto de Vitória, ao\ndestruir esse Campeão.", "on_destroy": "noHonor"},
	{"name": "REI CAVEIRA", "power": 2, "category": "champion", "ability_type": "constant", "ability_name": "Sem Honra", "ability_desc": "O Adversário Não ganha\nPonto de Vitória, ao\ndestruir esse Campeão.", "on_destroy": "noHonor"},
	{"name": "NOBRE ELFA", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Defensor", "ability_desc": "Ao entrar em campo, recebe Proteção permanente.", "on_enter": "defensor"},
	{"name": "SIR DUNKAN", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Defensor", "ability_desc": "Ao entrar em campo, recebe Proteção permanente.", "on_enter": "defensor"},
	{"name": "GAMER", "power": 2, "category": "champion", "ability_type": "constant", "ability_name": "Recompensa Dupla", "ability_desc": "Ao destruir um Campeão em combate, ganhe 2 pvs.", "constant": "recompensaDupla"},
	{"name": "ARCADIA", "power": 1, "category": "champion", "ability_type": "constant", "ability_name": "Recompensa Dupla", "ability_desc": "Ao destruir um Campeão em combate, ganhe 2 pvs.", "constant": "recompensaDupla"},
	{"name": "TIGRE DE GELO", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Rajada Congelante", "ability_desc": "Escolha um Campeão adversário. Ele ficará congelado.", "on_enter": "rajadaCongelante"},
	{"name": "MAGO DE GELO", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Rajada Congelante", "ability_desc": "Escolha um Campeão adversário. Ele ficará congelado.", "on_enter": "rajadaCongelante"},
	{"name": "HELA", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Corromper", "ability_desc": "Escolha um Campeão aliado. O jogador que o destruir, não ganhará PV.", "on_enter": "corromper"},
	{"name": "MANDAGORA", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Mordida Venenosa", "ability_desc": "Escolha um Campeão adversário. Ele ficará envenenado.", "on_enter": "mordidaVenenosa"},
	{"name": "VIPER", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Mordida Venenosa", "ability_desc": "Escolha um Campeão adversário. Ele ficará envenenado.", "on_enter": "mordidaVenenosa"},
	{"name": "VIOLÊNCIA", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Grito de Guerra", "ability_desc": "Campeões aliados ganham Fúria, durante 1 rodada.", "on_enter": "gritoDeGuerra"},
	{"name": "BATEDOR FEROZ", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Grito de Guerra", "ability_desc": "Campeões aliados ganham Fúria, durante 1 rodada.", "on_enter": "gritoDeGuerra"},
	{"name": "AKASHA", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Pesadelo", "ability_desc": "Escolha um Jogador. Ele não\npoderá fazer Saque Livre,\ndurante 1 rodada.", "on_enter": "pesadelo"},
	{"name": "SUCCUBUS", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Pesadelo", "ability_desc": "Escolha um Jogador. Ele não\npoderá fazer Saque Livre,\ndurante 1 rodada.", "on_enter": "pesadelo"},
	{"name": "TAGARELA", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Roubar", "ability_desc": "Pegue 1 carta aleatória da Mão do adversário.", "on_enter": "roubar"},
	{"name": "RAZIEL", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Roubar", "ability_desc": "Pegue 1 carta aleatória da Mão do adversário.", "on_enter": "roubar"},
	{"name": "MAGA DO TEMPO", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Desacelerar", "ability_desc": "O Jogador adversário faz 1 ação a menos no turno dele!", "on_enter": "desacelerar"},
	{"name": "WYVERN", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Invocar Dragão", "ability_desc": "Invoque o Campeão:\nFilhote de dragão, para seu\nCampo , como ação Livre.", "on_enter": "invokeDragon"},
	{"name": "FERAGROSS", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Invocar Dragão", "ability_desc": "Invoque o Campeão:\nFilhote de dragão, para seu\nCampo , como ação Livre.", "on_enter": "invokeDragon"},
	{"name": "LILITH", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Bola de Fogo", "ability_desc": "Reduza o Poder de um Campeão\nadversário em 1 Ponto!", "on_enter": "bolaDeFogo"},
	{"name": "ELEMENTISTA", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Bola de Fogo", "ability_desc": "Reduza o Poder de um Campeão\nadversário em 1 Ponto!", "on_enter": "bolaDeFogo"},
	{"name": "VEGA", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Assassinar", "ability_desc": "Reduza o Poder de um Campeão P1 a zero!", "on_enter": "assassinar"},
	{"name": "MIRA OCULTA", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Assassinar", "ability_desc": "Reduza o Poder de um Campeão P1 a zero!", "on_enter": "assassinar"},
	{"name": "A DUELISTA", "power": 2, "category": "champion", "ability_type": "constant", "ability_name": "Sobrepujar", "ability_desc": "Nunca é destruída quando entra em Combate contra um Campeão com Poder igual."},
	{"name": "POPPY", "power": 1, "category": "champion", "ability_type": "constant", "ability_name": "Sobrepujar", "ability_desc": "Nunca é destruída quando entra em Combate contra um Campeão com Poder igual."},
	{"name": "GAROU", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Rapidez", "ability_desc": "Ao entrar em campo, concede +1 ação extra neste turno.", "on_enter": "rapidez"},
	{"name": "PISTOLEIRA NEON", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Rapidez", "ability_desc": "Ao entrar em campo, concede +1 ação extra neste turno.", "on_enter": "rapidez"},
	{"name": "FAUNO", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Fortalecer", "ability_desc": "Acrescente +1 de Poder a um Campeão.", "on_enter": "fortalecer"},
	{"name": "GAIA", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Fortalecer", "ability_desc": "Acrescente +1 de Poder a um Campeão.", "on_enter": "fortalecer"},
	{"name": "COME PEDRA", "power": 1, "category": "champion", "ability_type": "constant", "ability_name": "Resistente", "ability_desc": "São necessárias 2 Ações para Atacar esse Campeão. Campeões com Investida não podem Atacá-lo."},
	{"name": "CROCOLOSSO", "power": 2, "category": "champion", "ability_type": "constant", "ability_name": "Resistente", "ability_desc": "São necessárias 2 Ações para Atacar esse Campeão. Campeões com Investida não podem Atacá-lo."},
	{"name": "TIRÂNICO", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Devorar", "ability_desc": "Destrua um Campeão aliado em campo. Agora some o poder da carta destruída a esse Campeão.", "on_enter": "devorar"},
	{"name": "CARNIVORA", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Devorar", "ability_desc": "Destrua um Campeão aliado em campo. Agora some o poder da carta destruída a esse Campeão.", "on_enter": "devorar"},
	{"name": "ÔMEGA", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Ritual", "ability_desc": "Sacrifique um Campeão P1 no seu Campo, e invoque Ômega como Ação Livre.", "summon_ritual": 1},
	{"name": "TIAMAT", "power": 3, "category": "champion", "ability_type": "instant", "ability_name": "Ritual Superior", "ability_desc": "Sacrifique um Campeão P2 no seu Campo, e invoque o Tiamat como Ação Livre.", "summon_ritual": 2},
	{"name": "BOLA DE FOGO", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Bola de Fogo (Talento)", "ability_desc": "Reduza o Poder de um Campeão em 1 ponto.", "talent_effect": "bolaDeFogoTalento"},
	{"name": "EXPLOSÃO", "power": 1, "category": "talent", "ability_type": "talent", "ability_name": "Explosão (Talento)", "ability_desc": "Reduza o Poder de um Campeão adversário em 2 pontos.", "talent_effect": "explosao"},
	{"name": "ZERO ABSOLUTO", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Zero Absoluto (Talento)", "ability_desc": "Escolha um Campeão. Ele ficará congelado por 2 rodadas. Se já estiver congelado, será destruído.", "talent_effect": "zeroAbsoluto"},
	{"name": "AMEDRONTAR", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Amedrontar (Talento)", "ability_desc": "Escolha um campeão adversário. Ele retornará à mão do jogador afetado.", "talent_effect": "medoTalento"},
	{"name": "BLOQUEAR ATAQUE", "power": 0, "category": "talent", "subcategory": "reaction", "ability_type": "talent", "ability_name": "Bloquear Ataque (Reação)", "ability_desc": "Cancele um ataque contra seu Campeão.", "talent_effect": "bloquearAtaque"},
	{"name": "PROTEÇÃO DIVINA", "power": 0, "category": "talent", "subcategory": "reaction", "ability_type": "talent", "ability_name": "Proteção Divina (Reação)", "ability_desc": "Impeça o Adversário de reduzir Poder de seu Campeão.", "talent_effect": "protecaoDivina"},
	{"name": "CANCELAR ULTIMATE", "power": 0, "category": "talent", "subcategory": "reaction", "ability_type": "talent", "ability_name": "Cancelar Ultimate (Reação)", "ability_desc": "Cancele a Ultimate de um Herói.", "talent_effect": "cancelarUltimate"},
	{"name": "EXAUSTÃO", "power": 0, "category": "talent", "subcategory": "reaction", "ability_type": "talent", "ability_name": "Exaustão (Reação)", "ability_desc": "Cancele a Habilidade instantânea de um Campeão.", "talent_effect": "exaustao"},
	{"name": "CONTRAMÁGICA", "power": 0, "category": "talent", "subcategory": "reaction", "ability_type": "talent", "ability_name": "Contramágica (Reação)", "ability_desc": "Cancele uma Carta Talento do adversário.", "talent_effect": "contramagica"},
	{"name": "FORTALECER", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Fortalecer (Talento)", "ability_desc": "Escolha um campeão aliado, ele ganhará 1 Ponto de Poder.", "talent_effect": "fortalecerTalento"},
	{"name": "DUPLICAR", "power": 1, "category": "talent", "ability_type": "talent", "ability_name": "Duplicar (Talento)", "ability_desc": "Escolha um Campeão aliado em campo, com Poder 2. Ele será duplicado!", "talent_effect": "doppelganger"},
	{"name": "BARREIRA", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Barreira (Talento)", "ability_desc": "TODOS os Campeões aliados ganham Barreira durante 2 rodadas, ficando resistentes a redução de Poder.", "talent_effect": "barreira"},
	{"name": "BAFORADA VENENOSA", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Baforada Venenosa (Talento)", "ability_desc": "Escolha um Campeão. Ele ficará envenenado, e em 2 rodadas será destruído.", "talent_effect": "baforadaVenenosa"},
	{"name": "ACELERAÇÃO", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Aceleração (Talento)", "ability_desc": "Faça 1 ação adicional durante este turno.", "talent_effect": "aceleracao"},
	{"name": "MÍSSEIS MÁGICOS", "power": 1, "category": "talent", "ability_type": "talent", "ability_name": "Mísseis Mágicos (Talento)", "ability_desc": "Campeões do adversário são atingidos por mísseis que tem 60% de Chance de reduzir 1 ponto de Poder.", "talent_effect": "missemagicos"},
	{"name": "ARSENAL DE GUERRA", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Arsenal de Guerra (Talento)", "ability_desc": "Compre 2 cartas como ação livre.", "talent_effect": "arsenalDeGuerra"},
	{"name": "INVESTIDA", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Investida (Talento)", "ability_desc": "Escolha um Campeão aliado e ele fará um Ataque como ação Livre.", "talent_effect": "investidaTalento"},
	{"name": "GRITO DE GUERRA", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Grito de Guerra (Talento)", "ability_desc": "Campeões aliados ganham fúria durante 1 rodada, recebendo +1 de Poder.", "talent_effect": "gritoDeGuerraTalento"},
	{"name": "PRISÃO PRISMÁTICA", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Prisão Prismática (Talento)", "ability_desc": "Escolha um Campeão. Ele ficará aprisionado, tendo que usar 2 ações para atacar.", "talent_effect": "prisaoPrismaticaTalento"},
	{"name": "TORNADO DE FOGO", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Tornado de Fogo (Talento)", "ability_desc": "Escolha 1 Campeão adversário. Ele perderá 1 ponto de Poder por rodada.", "talent_effect": "tornadoDeFogo"},
	{"name": "MALDIÇÃO DOS SETE MARES", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Maldição dos Sete Mares (Talento)", "ability_desc": "O Próximo Campeão que o adversário invocar, não terá Habilidade.", "talent_effect": "maldicaoSeteMaresTalento"},
	{"name": "TROCA DE LUGAR", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Troca de Lugar (Talento)", "ability_desc": "Escolha um Campeão aliado P1 e troque por um campeão do adversário P2.", "talent_effect": "trocaDeLugar"},
	{"name": "TÉCNICAS DE COMBATE", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Técnicas de Combate (Talento)", "ability_desc": "Campeões aliados poderão vencer combates contra campeões com poder igual, durante 1 rodada.", "talent_effect": "tecnicasDeCombateTalento"},
	{"name": "PODRIDÃO", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Podridão (Talento)", "ability_desc": "Contamine 5 cartas do BARALHO do adversário. As cartas contaminadas são inúteis quando chegam à mão do alvo.", "talent_effect": "podridaoTalento"},
	{"name": "APODRECIDA", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Apodrecida", "ability_desc": "Carta Apodrecida. Descarte-a!", "talent_effect": "apodrecidaDescarte", "hidden": true},
	{"name": "RESSUSCITAR", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Ressuscitar (Talento)", "ability_desc": "O último Campeão P2 seu destruído, retorna a seu campo.", "talent_effect": "ressuscitarTalento"},
	{"name": "CORROMPER", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Corromper (Talento)", "ability_desc": "Escolha um Campeão. O adversário não ganhará PVs ao destruí-lo.", "talent_effect": "corromperTalento"},
	{"name": "CHUVA DE COMETAS", "power": 1, "category": "talent", "ability_type": "talent", "ability_name": "Chuva de Cometas (Talento)", "ability_desc": "Todos os Campeões em campo, seus e do adversário perdem 1 ponto de Poder.", "talent_effect": "chuvaDeCometas"},
	{"name": "TRANSFORMAR EM BICHINHO", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Transformar em Bichinho (Talento)", "ability_desc": "Escolha um Campeão. O poder dele será reduzido pela metade, arredondado para baixo. Não funciona em Campeões P1.", "talent_effect": "transformarBichinhoTalento"},
	{"name": "DESACELERAR", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Desacelerar (Talento)", "ability_desc": "O jogador adversário faz 1 ação a menos no turno dele.", "talent_effect": "desacelerarTalento"},
	{"name": "ENFRAQUECER", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Enfraquecer (Talento)", "ability_desc": "Escolha um Campeão. O Jogador adversário perde 1 PV.", "talent_effect": "enfraquecerTalento"},
	{"name": "INVOCAR DRAGÃO", "power": 0, "category": "talent", "ability_type": "talent", "ability_name": "Invocar Dragão (Talento)", "ability_desc": "Invoque o Campeão FILHOTE DE DRAGÃO para seu campo.", "talent_effect": "invocarDragaoTalento"},
	{"name": "BOLA DE PELOS", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Transformar em Bichinho", "ability_desc": "Reduza o Poder de um Campeão pela metade, transformando-o em Bichinho, ou em Alguma coisa pior.", "on_enter": "transformarBichinho"},
	{"name": "APRENDIZ DE ARQUIMAGO", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Transformar em Bichinho", "ability_desc": "Reduza o Poder de um Campeão pela metade, transformando-o em Bichinho, ou em Alguma coisa pior.", "on_enter": "transformarBichinho"},
	{"name": "BOLHAS", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Maldição dos Sete Mares", "ability_desc": "O próximo campeão que seu Adversário invocar, não terá habilidade.", "on_enter": "maldicaoSeteMares"},
	{"name": "TUBARÃO BORRIFANTE", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Maldição dos Sete Mares", "ability_desc": "O próximo campeão que seu Adversário invocar, não terá habilidade.", "on_enter": "maldicaoSeteMares"},
	{"name": "WU-KONG", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Imitar", "ability_desc": "Tem a Habilidade igual a de um Campeão Aliado a sua escolha.", "on_enter": "imitar"},
	{"name": "ENIGMA", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Imitar", "ability_desc": "Tem a Habilidade igual a de um Campeão Aliado a sua escolha.", "on_enter": "imitar"},
	{"name": "FURIOSA", "power": 2, "category": "champion", "ability_type": "constant", "ability_name": "Vingança", "ability_desc": "Após morrer, um Campeão aleatório do adversário, terá 1 ponto de Poder reduzido.", "on_destroy": "vinganca"},
	{"name": "GRIZZLY", "power": 1, "category": "champion", "ability_type": "constant", "ability_name": "Vingança", "ability_desc": "Após morrer, um Campeão aleatório do adversário, terá 1 ponto de Poder reduzido.", "on_destroy": "vinganca"},
	{"name": "BARBALONGA", "power": 1, "category": "champion", "ability_type": "constant", "ability_name": "Legado", "ability_desc": "Após morrer, um Campeão aliado aleatório ganhará 1 ponto de Poder!", "on_destroy": "legado"},
	{"name": "BEATRIX", "power": 2, "category": "champion", "ability_type": "constant", "ability_name": "Legado", "ability_desc": "Após morrer, um Campeão aliado aleatório ganhará 1 ponto de Poder!", "on_destroy": "legado"},
	{"name": "LICH", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Necromancia", "ability_desc": "Escolha 1 carta dentre as últimas 4 cartas que você usou, e ela retornará para sua Mão.", "on_enter": "necromancia"},
	{"name": "MÁSCARA DA MORTE", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Necromancia", "ability_desc": "Escolha 1 carta dentre as últimas 4 cartas que você usou, e ela retornará para sua Mão.", "on_enter": "necromancia"},
	{"name": "GRISELDA", "power": 2, "category": "champion", "ability_type": "constant", "ability_name": "Investida", "ability_desc": "Pode Atacar como Ação Livre. Não pode Atacar Campeões Resistentes.", "constant": "investida"},
	{"name": "CAVALEIRA BRINQUEDO", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Troca Injusta", "ability_desc": "Troque essa Campeã, com um Campeão aleatório de Poder 2 do Adversário.", "on_enter": "trocaInjusta"},
	{"name": "PANDA", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Ursificação", "ability_desc": "Transforme um Campeão aliado em um Urso gigante e pesado. Ele ganha +2 de Poder.", "on_enter": "ursificacao"},
	{"name": "MENINA URSO", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Ursificação", "ability_desc": "Transforme um Campeão aliado em um Urso gigante e pesado. Ele ganha +2 de Poder.", "on_enter": "ursificacao"},
	{"name": "OLAF", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Fúria", "ability_desc": "Ao entrar em campo, ganha +1 de Poder por 1 rodada (status Fúria).", "on_enter": "furia"},
	{"name": "URSA", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Fúria", "ability_desc": "Ao entrar em campo, ganha +1 de Poder por 1 rodada (status Fúria).", "on_enter": "furia"},
	{"name": "ARCANJO", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Guardião", "ability_desc": "Campeões aliados ganham Proteção!", "on_enter": "guardiao"},
	{"name": "PANTEÃO", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Guardião", "ability_desc": "Campeões aliados ganham Proteção!", "on_enter": "guardiao"},
	{"name": "TOXINA", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Fumaça Tóxica", "ability_desc": "Os Campeões adversários ficam vulneráveis e são destruídos quando recebem qualquer redução de poder.", "on_enter": "fumacaToxica"},
	{"name": "MARTIS", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Fumaça Tóxica", "ability_desc": "Os Campeões adversários ficam vulneráveis e são destruídos quando recebem qualquer redução de poder.", "on_enter": "fumacaToxica"},
	{"name": "ANTI-MAGOS", "power": 2, "category": "champion", "ability_type": "constant", "ability_name": "Aura Anti-Magia", "ability_desc": "Ao entrar, recebe Barreira permanente. Bloqueia redução de Poder sem perder o status.", "on_enter": "auraAntiMagia"},
	{"name": "SOLDADO DO FUTURO", "power": 1, "category": "champion", "ability_type": "constant", "ability_name": "Aura Anti-Magia", "ability_desc": "Ao entrar, recebe Barreira permanente. Bloqueia redução de Poder sem perder o status.", "on_enter": "auraAntiMagia"},
	{"name": "CALCIFER", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Incendiar", "ability_desc": "Escolha um Campeão adversário. Ele ficará Em Chamas, perdendo 1 ponto de poder por rodada.", "on_enter": "incendiar"},
	{"name": "EFREET", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Incendiar", "ability_desc": "Escolha um Campeão adversário. Ele ficará Em Chamas, perdendo 1 ponto de poder por rodada.", "on_enter": "incendiar"},
	{"name": "MINOTAURO", "power": 2, "category": "champion", "ability_type": "constant", "ability_name": "Crescimento", "ability_desc": "Ganha +1 de Poder, a cada\nrodada completa que permanecer\nno seu campo."},
	{"name": "GUARDIÃO DA CHAVE", "power": 1, "category": "champion", "ability_type": "constant", "ability_name": "Crescimento", "ability_desc": "Ganha +1 de Poder, a cada\nrodada completa que permanecer\nno seu campo."},
	{"name": "ZEUS", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Raio Duplo", "ability_desc": "Reduza em 1 ponto o poder de dois campeões do oponente. Você Não ganha Pvs por isso.", "on_enter": "raioDuplo"},
	{"name": "PATRULHEIRA ESPACIAL", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Desacelerar", "ability_desc": "O Jogador adversário faz 1 ação a menos no turno dele!", "on_enter": "desacelerar"},
	{"name": "CRISÁLIDA", "power": 1, "category": "champion", "ability_type": "constant", "ability_name": "Inspirar", "ability_desc": "Campeões adjacentes tem +1 de Poder, enquanto a Crisálida estiver em campo.", "constant": "inspirar"},
	{"name": "BARGANHA", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Corromper", "ability_desc": "Escolha um Campeão aliado. O jogador que o destruir, não ganhará PV.", "on_enter": "corromper"},
	{"name": "KUMIKO", "power": 1, "category": "champion", "ability_type": "constant", "ability_name": "Investida", "ability_desc": "Pode Atacar como Ação Livre. Não pode Atacar Campeões Resistentes.", "constant": "investida"},
	{"name": "JOVEM ARTÍFICE", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Forja", "ability_desc": "Compre 1 Carta como ação livre.", "on_enter": "forja"},
	{"name": "TINKER", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Forja", "ability_desc": "Compre 1 Carta como ação livre.", "on_enter": "forja"},
	{"name": "CENTAURO GUERREIRO", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Técnicas de Combate", "ability_desc": "Seus Campeões aliados ganham SOBREPUJAR (sempre vencem combates contra campeões com poder igual), durante 1 rodada.", "on_enter": "tecnicasDeCombate"},
	{"name": "MULAN", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Técnicas de Combate", "ability_desc": "Seus Campeões aliados ganham SOBREPUJAR (sempre vencem combates contra campeões com poder igual), durante 1 rodada.", "on_enter": "tecnicasDeCombate"},
	{"name": "CAÇADORA DE RECOMPENSAS", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Roleta Russa", "ability_desc": "Ao entrar em campo, uma roleta gira sobre todos os campeões. 1 Campeão aleatório é destruído.", "on_enter": "roletaRussa"},
	{"name": "ERIS A PIRATA", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Roleta Russa", "ability_desc": "Ao entrar em campo, uma roleta gira sobre todos os campeões. 1 Campeão aleatório é destruído.", "on_enter": "roletaRussa"},
	{"name": "SHINOBI", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Podridão", "ability_desc": "Contamine 5 cartas do BARALHO do adversário. As cartas contaminadas são inúteis quando chegam à mão do alvo.", "on_enter": "podridao"},
	{"name": "KORUSBELLA", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Podridão", "ability_desc": "Contamine 5 cartas do BARALHO do adversário. As cartas contaminadas são inúteis quando chegam à mão do alvo.", "on_enter": "podridao"},
	{"name": "TEMPESTA", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Raio Duplo", "ability_desc": "Reduza em 1 ponto o poder de dois campeões do oponente. Você Não ganha Pvs por isso.", "on_enter": "raioDuplo"},
	{"name": "PRINCESA AURORA", "power": 2, "category": "champion", "ability_type": "constant", "ability_name": "Inspirar", "ability_desc": "Campeões adjacentes tem +1 de Poder, enquanto a Princesa Aurora estiver em campo.", "constant": "inspirar"},
	{"name": "CAVALEIRO JURAMENTADO", "power": 1, "category": "champion", "ability_type": "constant", "ability_name": "Muralha", "ability_desc": "Enquanto estiver fora do turno, ganha +1 de Poder. No início do seu turno, perde o ponto de poder recebido.", "constant": "muralha"},
	{"name": "ALEXANDER", "power": 2, "category": "champion", "ability_type": "constant", "ability_name": "Muralha", "ability_desc": "Enquanto estiver fora do turno, ganha +1 de Poder. No início do seu turno, perde o ponto de poder recebido.", "constant": "muralha"},
	{"name": "APRENDIZ DE FEITICEIRA", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Separar", "ability_desc": "Escolha um Campeão com Poder 2. Ele irá se dividir em 2 Campeões com Poder 1!", "on_enter": "separar"},
	{"name": "RONIN", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Separar", "ability_desc": "Escolha um Campeão com Poder 2. Ele irá se dividir em 2 Campeões com Poder 1!", "on_enter": "separar"},
	{"name": "GUERREIRO CÚBICO", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Prisão Prismática", "ability_desc": "Escolha um Campeão. Ele ficará aprisionado, tendo que usar 2 ações para atacar.", "on_enter": "prisaoPrismatica"},
	{"name": "GUERREIRO CÚBICO CORROMPIDO", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Prisão Prismática", "ability_desc": "Escolha um Campeão. Ele ficará aprisionado, tendo que usar 2 ações para atacar.", "on_enter": "prisaoPrismatica"},
	{"name": "ELFO GLADIADOR", "power": 1, "category": "champion", "ability_type": "constant", "ability_name": "Desafiante", "ability_desc": "Enquanto esse Campeão for o único no seu campo, terá +2 pontos de Poder.", "constant": "desafiante"},
	{"name": "PUNHOS DE FERRO", "power": 2, "category": "champion", "ability_type": "constant", "ability_name": "Desafiante", "ability_desc": "Enquanto essa Campeã for a única no seu campo, terá +2 pontos de Poder.", "constant": "desafiante"},
	{"name": "ASSOMBRAÇÃO", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Enfraquecer", "ability_desc": "Ao entrar em campo, o jogador adversário perde 1 Ponto de Vitória.", "on_enter": "enfraquecer"},
	{"name": "DEMÔNIO ALADO", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Enfraquecer", "ability_desc": "Ao entrar em campo, o jogador adversário perde 1 Ponto de Vitória.", "on_enter": "enfraquecer"},
	{"name": "AMIGÃO", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Energizar", "ability_desc": "Ao entrar em campo, você ganha 1 Energia: +1 uso de Ultimate nesta partida.", "on_enter": "energizar"},
	{"name": "ELFAS GÊMEAS", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Energizar", "ability_desc": "Ao entrar em campo, você ganha 1 Energia: +1 uso de Ultimate nesta partida.", "on_enter": "energizar"},
	{"name": "CAVALEIRO SANGUINÁRIO", "power": 1, "category": "champion", "ability_type": "constant", "ability_name": "Laço de Sangue", "ability_desc": "Sempre que atacar e destruir um Campeão em COMBATE, um Campeão aliado aleatório ganha +1 de Poder.", "constant": "lacoDeSangue"},
	{"name": "SCARLET", "power": 2, "category": "champion", "ability_type": "constant", "ability_name": "Laço de Sangue", "ability_desc": "Sempre que atacar e destruir um Campeão em COMBATE, um Campeão aliado aleatório ganha +1 de Poder.", "constant": "lacoDeSangue"},
	{"name": "EUGINE", "power": 1, "category": "champion", "ability_type": "instant", "ability_name": "Charme", "ability_desc": "Um Campeão do Adversário fica enfeitiçado e vem para seu campo durante 2 rodadas.", "on_enter": "charme"},
	{"name": "WISP A TELEPATA", "power": 2, "category": "champion", "ability_type": "instant", "ability_name": "Charme", "ability_desc": "Um Campeão do Adversário fica enfeitiçado e vem para seu campo durante 2 rodadas.", "on_enter": "charme"},
	{"name": "BANJO", "power": 0, "category": "champion", "ability_type": "constant", "ability_name": "Pesado Demais", "ability_desc": "Precisa de 2 Ações para Atacar. Não pode Atacar Campeões Resistentes.", "hidden": true},
	{"name": "BICHINHO FOFINHO", "power": 0, "category": "champion", "ability_type": "constant", "ability_name": "Fofura", "ability_desc": "Ser fofo é sua principal arma. Sem habilidade.", "hidden": true},
	{"name": "O CHEFÃO", "power": 0, "category": "champion", "ability_type": "constant", "ability_name": "Ameaça Iminente", "ability_desc": "Gosta de uma boa briga! Sem habilidade.", "hidden": true},
]

const TOKEN_BABY_DRAGON := {"name": "FILHOTE DE DRAGÃO", "power": 1, "category": "champion", "ability_type": "constant", "ability_name": "Crescimento", "ability_desc": "Ganha +1 de Poder, a cada\nrodada completa que permanecer\nno seu campo."}
const TOKEN_BLUE_DRAGON := {"name": "DRAGÃO AZUL", "power": 2, "category": "champion", "ability_type": "constant", "ability_name": "Crescimento", "ability_desc": "Ganha +1 de Poder, a cada\nrodada completa que permanecer\nno seu campo."}


static func token_def(tname: String) -> Dictionary:
	for c in CARDS:
		if c.get("hidden", false) and c["name"] == tname:
			return c
	if tname == "FILHOTE DE DRAGÃO":
		return TOKEN_BABY_DRAGON
	if tname == "DRAGÃO AZUL":
		return TOKEN_BLUE_DRAGON
	return {}


static func playable_defs() -> Array:
	## Cartas únicas jogáveis (não-hidden), mesma ordem de buildDecks do servidor.
	var seen := {}
	var out := []
	for c in CARDS:
		if c.get("hidden", false):
			continue
		if seen.has(c["name"]):
			continue
		seen[c["name"]] = true
		out.append(c)
	return out


static func random_hero(rng: RandomNumberGenerator) -> Dictionary:
	return HEROES[rng.randi_range(0, HEROES.size() - 1)]
