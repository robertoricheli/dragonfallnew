class_name AIBrain
## IA do adversário: planeja UMA ação por vez (a cena de batalha executa com pausas).
## Prioridade: invocar/fortalecer → talentos úteis → ataques vantajosos → comprar → passar.


static func next_action(state: GameState) -> Dictionary:
	var pi: int = state.current
	var p: Dictionary = state.players[pi]
	var foe: Array = state.players[1 - pi]["field"]

	# 1) Invocações (preparam ataques e PV passivo)
	var summon := _best_summon(state, pi)
	if not summon.is_empty():
		return summon

	# 2) Talentos com valor claro
	var talent := _best_talent(state, pi)
	if not talent.is_empty():
		return talent

	# 2.5) Ultimate do herói (1x por turno, usos limitados)
	var ultchk: Dictionary = state.can_use_ultimate(pi)
	if ultchk["ok"]:
		var ut: String = String(p["hero"].get("ultimateType", ""))
		var use := false
		match ut:
			"targetEnemy", "targetEnemyFreeze", "fireAndIce", "banish", "scareReturn", "vampirism", "incinerate", "poison":
				use = not foe.is_empty()
			"targetAlly", "targetAllyFreeAttack", "targetAllyShield", "infinitePower", "reuseInstant", "potion":
				use = not p["field"].is_empty()
			"drawCard", "thunderDiscard", "summonDragon":
				use = true
			"trickerySwap":
				use = not p["field"].is_empty() and not foe.is_empty()
			"hook":
				use = not foe.is_empty() and p["field"].size() < GameState.MAX_FIELD
			"resurrect":
				use = p["discard"].any(func(c): return c["category"] == "champion" and int(c.get("power", 0)) == 2) and p["field"].size() < GameState.MAX_FIELD
			"cometStarfall":
				use = foe.size() > p["field"].size()
		if use:
			return {"type": "ultimate"}

	# 3) Ataques vantajosos
	var atk := _best_attack(state, pi, foe)
	if not atk.is_empty():
		return atk

	# 4) Comprar carta (se ainda houver o que fazer depois, o laço reavalia)
	if p["actions"] >= 1 and not p["deck"].is_empty() and p["hand"].size() < GameState.MAX_HAND:
		var has_cheap := false
		for c in p["hand"]:
			if state.summon_cost(c) <= int(p["actions"]) and (c["category"] == "talent" or p["field"].size() < GameState.MAX_FIELD):
				has_cheap = true
				break
		if not has_cheap or p["hand"].size() <= 2:
			return {"type": "draw"}

	return {"type": "end_turn"}


static func _best_summon(state: GameState, pi: int) -> Dictionary:
	var p: Dictionary = state.players[pi]
	if p["field"].size() >= GameState.MAX_FIELD:
		return {}
	var best := {}
	var best_score := 0.0
	for i in p["hand"].size():
		var card: Dictionary = p["hand"][i]
		if card["category"] != "champion":
			continue
		var chk: Dictionary = state.can_play(pi, i)
		if not chk["ok"]:
			continue
		var score: float = float(card["current_power"]) * 10.0
		var oe: String = String(card.get("on_enter", ""))
		var foes: Array = state.players[1 - pi]["field"]
		var allies: Array = p["field"]
		match oe:
			"bolaDeFogo", "incendiar", "mordidaVenenosa", "rajadaCongelante", "fumacaToxica", "transformarBichinho", "prisaoPrismatica", "separar":
				score += 8.0 if not foes.is_empty() else -6.0
			"assassinar":
				score += 10.0 if foes.any(func(c): return int(c["power"]) == 1) else -6.0
			"invokeDragon", "forja", "rapidez":
				score += 7.0
			"fortalecer", "ursificacao", "devorar", "corromper":
				score += 4.0 if not allies.is_empty() else 0.0
			"roubar", "pesadelo", "desacelerar", "bolhas", "enfraquecer", "podridao":
				score += 5.0
			"defensor", "auraAntiMagia", "guardiao", "gritoDeGuerra", "furia", "tecnicasDeCombate":
				score += 4.0
			"charme", "trocaInjusta":
				score += 6.0 if not foes.is_empty() else -4.0
			"roletaRussa":
				score += 2.0 if foes.size() > allies.size() else -8.0
		# constantes valiosas
		match String(card.get("constant", "")):
			"recompensaDupla", "lacoDeSangue", "investida":
				score += 5.0
			"desafiante":
				score += 6.0 if allies.is_empty() else 0.0
			"muralha", "inspirar":
				score += 3.0
		if String(card.get("ability_name", "")) == "Crescimento":
			score += 4.0
		if String(card.get("ability_name", "")) == "Sem Honra":
			score += 2.0
		score -= float(chk.get("cost", 0)) * 2.0
		if score > best_score:
			best_score = score
			best = {"type": "summon", "hand_idx": i}
	return best


static func _best_talent(state: GameState, pi: int) -> Dictionary:
	var p: Dictionary = state.players[pi]
	if p["field"].size() >= GameState.MAX_FIELD:
		return {}
	if state.talent_active[pi]:
		return {}
	var foes: Array = state.players[1 - pi]["field"]
	var allies: Array = p["field"]
	for i in p["hand"].size():
		var card: Dictionary = p["hand"][i]
		if card["category"] != "talent":
			continue
		var chk: Dictionary = state.can_play(pi, i)
		if not chk["ok"]:
			continue
		var eff: String = String(card.get("talent_effect", ""))
		var play := false
		match eff:
			"bolaDeFogoTalento", "explosao", "tornadoDeFogo", "baforadaVenenosa", "missemagicos", "transformarBichinhoTalento", "prisaoPrismaticaTalento":
				play = not foes.is_empty()
			"zeroAbsoluto":
				play = foes.any(func(c): return int(c["frozen_turns"]) > 0 or int(c["current_power"]) >= 2)
			"medoTalento":
				play = foes.any(func(c): return int(c["current_power"]) >= 2)
			"chuvaDeCometas":
				play = foes.size() > allies.size()
			"fortalecerTalento", "investidaTalento", "doppelganger", "corromperTalento", "tecnicasDeCombateTalento", "gritoDeGuerraTalento":
				play = not allies.is_empty()
			"barreira", "protecaoDivina", "bloquearAtaque":
				play = not allies.is_empty() and not foes.is_empty()
			"arsenalDeGuerra", "aceleracao":
				play = true
			"invocarDragaoTalento":
				play = p["field"].size() < GameState.MAX_FIELD
			"ressuscitarTalento":
				play = p["discard"].any(func(c): return c["category"] == "champion" and int(c.get("power", 0)) == 2) and p["field"].size() < GameState.MAX_FIELD
			"enfraquecerTalento":
				play = int(state.players[1 - pi]["vp"]) > 0
			"podridaoTalento", "bolhasTalento", "desacelerarTalento", "cancelarUltimate":
				play = true
			"contramagica", "exaustao":
				play = not foes.is_empty() or not state.players[1 - pi]["hand"].is_empty()
			"trocaDeLugar":
				play = allies.any(func(c): return int(c["current_power"]) == 1) and foes.any(func(c): return int(c["current_power"]) == 2)
			"apodrecidaDescarte":
				play = true
		if play:
			return {"type": "talent", "hand_idx": i}
	return {}


static func _best_attack(state: GameState, pi: int, foes: Array) -> Dictionary:
	var p: Dictionary = state.players[pi]
	var best := {}
	var best_score := 0.0
	for ai in p["field"].size():
		var att: Dictionary = p["field"][ai]
		for di in foes.size():
			var defc: Dictionary = foes[di]
			var chk: Dictionary = state.can_attack(pi, ai, di)
			if not chk["ok"]:
				continue
			var pa: int = int(att["current_power"])
			var pd: int = int(defc["current_power"])
			var oa := _over(att)
			var od := _over(defc)
			var score := 0.0
			var kill_d := false
			var kill_a := false
			if pa > pd:
				kill_d = true
			elif pa < pd:
				kill_a = true
			else:
				if oa and not od:
					kill_d = true
				elif od and not oa:
					kill_a = true
				elif not oa and not od:
					kill_d = true
					kill_a = true
			var vp_gain := 0.0
			if kill_d and not _no_vp(defc):
				vp_gain = 2.0 if (String(att.get("constant", "")) == "recompensaDupla" and not att["silenced"]) else 1.0
			if kill_d and not kill_a:
				score = 100.0 + vp_gain * 10.0 + float(pd) * 2.0
			elif kill_d and kill_a:
				score = 40.0 + vp_gain * 10.0 + float(pd - pa) * 2.0
			elif kill_a:
				score = -50.0
			else:
				score = 5.0
			score -= float(chk.get("cost", 0)) * 3.0
			if score > best_score:
				best_score = score
				best = {"type": "attack", "att_idx": ai, "def_idx": di}
	return best


static func _over(c: Dictionary) -> bool:
	if c["silenced"]:
		return false
	return String(c.get("ability_name", "")) == "Sobrepujar" or int(c.get("tecnicas_turns", 0)) > 0


static func _no_vp(c: Dictionary) -> bool:
	if c.get("corrupted", false):
		return true
	if c.get("silenced", false):
		return false
	return String(c.get("on_destroy", "")) == "noHonor" or String(c.get("ability_name", "")) == "Sem Honra"
