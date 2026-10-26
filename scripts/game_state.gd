class_name GameState
extends RefCounted
## Estado e regras de uma partida 1v1 do Dragonfall (portado de motor/df-rules.js + df-engine.js).
## Regras principais: 15 PV para vencer, 3 ações por turno, custo de invocação = Poder da carta,
## máx. 6 campeões no campo, máx. 8 cartas na mão, PV passivo (+1 por campeão, teto 2/turno),
## compra automática de 1 carta no início do turno.

signal log_msg(text)
signal card_drawn(pidx, card, animated)
signal hand_changed(pidx)
signal champion_summoned(pidx, card)
signal champion_destroyed(pidx, card, reason, gave_vp)
signal champion_morphed(pidx, card)
signal attack_done(att_p, att_card, def_p, def_card, result_text)
signal vp_changed(pidx)
signal actions_changed(pidx)
signal turn_started(pidx)
signal game_over(winner_pidx)
signal field_changed(pidx)
signal talent_played(pidx, card)
signal ultimate_used(pidx)
signal fx_fire(from_pi, from_uid, target_uid)
signal fx_fortalecer(from_pi, from_uid, target_uid)
## (1.49.77) ROUBAR: avisa a Tela de Combate para animar o voo da carta
## roubada (0,5 s de atraso + 1,5 s de voo); o roubo efetivo é resolve_roubo.
signal fx_roubo(pi, foe_pi, uid)
## (1.49.77) FORJA: avisa para animar martelo/bigorna; o saque é resolve_forja.
signal fx_forja(pi, source_uid)
signal fx_congelar(pi, source_uid, target_uid)
signal fx_mordida(pi, source_uid, target_uid)
signal fx_baforada(pi, source_uid, target_uid)
## (1.49.76) estilo de animação de destruição especial: "semhonra" | "recompensa" | ""
signal destroy_style(uid, style)
signal sync_views()
signal targeting_started(pi, effect, source_uid, candidates)
signal targeting_ended(pi)

var win_points := 15
const MAX_ACTIONS := 3
const MAX_FIELD := 6
const MAX_HAND := 8

var players: Array = []
var current: int = 0
var turn_number: int = 0
var winner: int = -1
var rng := RandomNumberGenerator.new()
var talent_active: Array = [false, false]
var _animate_draw := true
var play_history: Array = []  # [{card, pi}] — histórico de cartas usadas
var _uid_seq: int = 1
# MIRA (escolha de alvo): habilidades como BOLA DE FOGO exigem que o jogador
# escolha um Campeão adversário ANTES do efeito (e da animação) acontecer.
# targeting = {pi, effect, source_uid, card_uid, candidates:[uids]}
var targeting: Dictionary = {}
# quando true (simulações/testes), o alvo é resolvido automaticamente
var auto_target := false
# danos de BOLA DE FOGO aguardando o impacto da animação: [{pi, uid}]
var pending_bola: Array = []
var pending_fort: Array = []
var pending_roubo: Array = []
var pending_forja: Array = []
# (1.49.93) habilidades de entrada ANIMADAS: o efeito real só aplica quando a
# Tela de Combate termina a respectiva animação (resolve_defensor/guardiao/
# pesadelo/invoke_dragon); sem tela (simulação) aplica na hora.
var pending_defensor: Array = []      # {"uid":int,"ms":int}
var pending_guardiao: Array = []      # {"uid":int,"ms":int}
var _pending_pesadelo: Dictionary = {}
var _pending_invoke: Dictionary = {}
## (1.49.77) TRUE quando há uma Tela de Combate conectada para animar
## ROUBAR/FORJA; sem ela (simulações), os efeitos resolvem imediatamente.
var fx_enabled := false


func _make_player(pname: String, hero: Dictionary, is_ai: bool) -> Dictionary:
	return {
		"name": pname, "hero": hero, "is_ai": is_ai,
		"vp": 0, "actions": MAX_ACTIONS,
		"hand": [], "field": [], "deck": [], "discard": [],
		"skip_draw": false, "skip_next_action": false, "curse_next": false,
		"energy": 0, "ult_remaining": 0, "ult_used_this_turn": false,
		"stats": {"summons": 0, "attacks": 0, "talents": 0, "ultimates": 0, "champKills": 0},
	}


func setup(hero_a: Dictionary, hero_b: Dictionary, opts: Dictionary = {}) -> void:
	rng.randomize()
	winner = -1
	turn_number = 1
	current = 0
	_uid_seq = 1
	win_points = int(opts.get("win_points", 15))
	players = [_make_player(hero_a.get("name", "Você"), hero_a, false), _make_player(hero_b.get("name", "IA"), hero_b, true)]
	# as 4 cartas iniciais entram SEM animação; só saques/compras voam
	_animate_draw = false
	for pi in 2:
		var hd: Dictionary = players[pi]["hero"]
		players[pi]["ult_remaining"] = 4 if "4 usos" in String(hd.get("ult_desc", "")) else 3
		var names: Array = opts.get("deck_a" if pi == 0 else "deck_b", [])
		_build_deck(pi, names)
		for i in 4:
			_raw_draw(pi)
		hand_changed.emit(pi)
	_animate_draw = true
	start_turn(0)


func _build_deck(pi: int, names: Array = []) -> void:
	var p: Dictionary = players[pi]
	p["deck"] = []
	p["discard"] = []
	var by_name := {}
	for defc in CardDB.playable_defs():
		by_name[defc["name"]] = defc
	if names.size() >= 10:
		var seen := {}
		for nm in names:
			var key := String(nm)
			if seen.has(key) or not by_name.has(key):
				continue
			seen[key] = true
			p["deck"].append(instantiate_card(by_name[key], pi))
	if p["deck"].size() < 10:
		# baralho aleatório de 20 cartas do Arsenal
		var pool: Array = CardDB.playable_defs().duplicate()
		_shuffle(pool)
		p["deck"] = []
		for defc in pool.slice(0, 20):
			p["deck"].append(instantiate_card(defc, pi))
	_shuffle(p["deck"])


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func instantiate_card(defc: Dictionary, owner_pi: int) -> Dictionary:
	var c := defc.duplicate(true)
	c["uid"] = _uid_seq
	_uid_seq += 1
	c["owner"] = owner_pi
	c["power"] = int(defc.get("power", 0))
	c["current_power"] = c["power"]
	c["tapped"] = false
	c["frozen_turns"] = 0
	c["shield_turns"] = 0        # -1 = permanente (Proteção)
	c["barrier_turns"] = 0       # -1 = permanente (Aura Anti-Magia)
	c["poison_turns"] = 0
	c["poison_by"] = -1
	c["burn_turns"] = 0
	c["burn_by"] = -1
	c["fury_stacks"] = 0
	c["fury_turns"] = 0
	c["tecnicas_turns"] = 0
	c["silenced"] = false
	c["corrupted"] = false
	c["vulnerable"] = false
	c["prision"] = false
	c["free_attack"] = false
	c["charm_turns"] = 0
	c["charm_owner"] = -1
	c["charm_orig_owner"] = -1
	c["wall_buff"] = 0
	c["desafiante_buff"] = 0
	c["inspirar_buff"] = 0
	c["podridao"] = false
	c["ult_growth"] = false
	return c


# ----------------------------------------------------------------------------
# Turno
# ----------------------------------------------------------------------------

func start_turn(pi: int) -> void:
	if winner != -1:
		return
	current = pi
	var p: Dictionary = players[pi]
	_tick_statuses(pi)
	_tick_charms(pi)
	if p["skip_next_action"]:
		p["actions"] = MAX_ACTIONS - 1
		p["skip_next_action"] = false
		log_msg.emit("%s começa com 2 ações (Desacelerar)." % p["name"])
	else:
		p["actions"] = MAX_ACTIONS
	p["ult_used_this_turn"] = false
	for c in p["field"]:
		c["tapped"] = false
		c["free_attack"] = false
		if c.get("constant", "") == "investida" and not c["silenced"]:
			c["free_attack"] = true
	actions_changed.emit(pi)
	# PV passivo: +1 por campeão em campo, teto 2 (regra original)
	var n: int = p["field"].size()
	if n > 0 and winner == -1:
		var passive: int = mini(n, 2)
		gain_vp(pi, passive)
		log_msg.emit("PV passivo: +%d por seus campeões em campo." % passive)
	_recalc_constants()
	# Compra automática do início do turno (regra pedida; original: "saque livre")
	if winner == -1:
		if p["skip_draw"]:
			p["skip_draw"] = false
			log_msg.emit("Pesadelo: %s não comprou carta neste turno!" % p["name"])
		else:
			# (1.50.3) SAQUE LIVRE com atraso: 1,0 s no início da partida;
			# 0,5 s após um jogador passar a vez (demais turnos).
			var delay: float = 1.0 if turn_number <= 1 else 0.5
			var st_tree := Engine.get_main_loop() as SceneTree
			if st_tree == null:
				draw_cards(pi, 1)
			else:
				st_tree.create_timer(delay).timeout.connect(func() -> void:
					if winner == -1:
						draw_cards(pi, 1))
	turn_started.emit(pi)
	sync_views.emit()
	_check_winner()


func end_turn() -> void:
	if winner != -1:
		return
	# (1.49.63) segurança: danos de Bola de Fogo pendentes há mais de 3,5 s
	# (a animação inteira já passou) são aplicados agora. Entradas recentes
	# NÃO são tocadas — a bola de fogo pode estar voando neste momento.
	if not pending_bola.is_empty():
		for e in pending_bola.duplicate():
			if Time.get_ticks_msec() - int(e.get("ms", 0)) > 3500:
				resolve_bola(int(e["uid"]))
	if not pending_fort.is_empty():
		# (1.49.70) segurança: buffs de Fortalecer pendentes há mais de 3,5 s
		# (a animação de 2 s inteira já passou) são aplicados agora.
		for e in pending_fort.duplicate():
			if Time.get_ticks_msec() - int(e.get("ms", 0)) > 3500:
				resolve_fortalecer(int(e["uid"]))
	# (1.49.93) o turno NÃO termina com efeito de entrada pendente: Proteção,
	# Pesadelo (saque) e o ovo do Filhote resolvem agora se ainda aguardando.
	_flush_enter_fx()
	if not targeting.is_empty():
		# mira pendente ao fim da vez: resolve sozinha no alvo mais forte
		var uid := auto_pick_uid()
		if uid >= 0:
			confirm_targeting(uid)
		else:
			var p_end: int = int(targeting["pi"])
			targeting = {}
			targeting_ended.emit(p_end)
	turn_number += 1
	start_turn(1 - current)


# ----------------------------------------------------------------------------
# Compra / descarte
# ----------------------------------------------------------------------------

func _raw_draw(pi: int) -> Dictionary:
	var p: Dictionary = players[pi]
	if p["deck"].is_empty():
		return {}
	var card: Dictionary = p["deck"].pop_back()
	if card.get("podridao", false):
		p["discard"].append(card)
		log_msg.emit("Carta contaminada (Podridão): %s apodreceu e foi descartada!" % card["name"])
		return {}
	if p["hand"].size() >= MAX_HAND:
		p["discard"].append(card)
		log_msg.emit("Mão cheia! %s foi queimada." % card["name"])
		return {}
	card["owner"] = pi
	p["hand"].append(card)
	card_drawn.emit(pi, card, _animate_draw)
	return card


func draw_cards(pi: int, n: int) -> int:
	var got := 0
	for i in n:
		if winner != -1:
			break
		var c := _raw_draw(pi)
		if not c.is_empty():
			got += 1
	hand_changed.emit(pi)
	return got


func can_manual_draw(pi: int) -> Dictionary:
	if winner != -1 or current != pi:
		return {"ok": false, "reason": "Não é o seu turno."}
	var p: Dictionary = players[pi]
	if p["actions"] < 1:
		return {"ok": false, "reason": "Ações insuficientes (custa 1)."}
	if p["deck"].is_empty():
		return {"ok": false, "reason": "Baralho vazio."}
	if p["hand"].size() >= MAX_HAND:
		return {"ok": false, "reason": "Mão cheia (máx. 8)."}
	return {"ok": true, "reason": ""}


func manual_draw(pi: int) -> bool:
	var chk := can_manual_draw(pi)
	if not chk["ok"]:
		log_msg.emit(chk["reason"])
		return false
	players[pi]["actions"] -= 1
	actions_changed.emit(pi)
	draw_cards(pi, 1)
	log_msg.emit("%s comprou 1 carta (1 ação)." % players[pi]["name"])
	return true


func discard_from_hand(pi: int, hand_idx: int, reason: String) -> void:
	var p: Dictionary = players[pi]
	if hand_idx < 0 or hand_idx >= p["hand"].size():
		return
	var card: Dictionary = p["hand"][hand_idx]
	p["hand"].remove_at(hand_idx)
	p["discard"].append(card)
	log_msg.emit("%s descartou %s (%s)." % [p["name"], card["name"], reason])
	hand_changed.emit(pi)


# ----------------------------------------------------------------------------
# Invocação (campeões) e Talentos
# ----------------------------------------------------------------------------

func summon_cost(card: Dictionary) -> int:
	if card.get("podridao", false) or card.get("name", "") == "APODRECIDA":
		return 0
	return maxi(0, int(card["current_power"]))


func can_play(pi: int, hand_idx: int) -> Dictionary:
	if winner != -1 or current != pi:
		return {"ok": false, "reason": "Não é o seu turno."}
	var p: Dictionary = players[pi]
	if hand_idx < 0 or hand_idx >= p["hand"].size():
		return {"ok": false, "reason": "Carta inválida."}
	var card: Dictionary = p["hand"][hand_idx]
	var cost: int = summon_cost(card)
	if card["category"] == "champion":
		if p["field"].size() >= MAX_FIELD:
			return {"ok": false, "reason": "Campo cheio (máx. 6 campeões)."}
		if card.get("summon_ritual", 0) > 0:
			var req: int = int(card["summon_ritual"])
			if _find_ally_with_power(pi, req) < 0:
				return {"ok": false, "reason": "Ritual: exige um aliado de Poder %d para sacrificar." % req}
		elif p["actions"] < cost:
			return {"ok": false, "reason": "Ações insuficientes: custa %d." % cost}
	else:
		if p["field"].size() >= MAX_FIELD:
			return {"ok": false, "reason": "Com 6 campeões no campo, Talentos e Reações não podem ser usados."}
		if talent_active[pi]:
			return {"ok": false, "reason": "Só um Talento por vez: aguarde o atual ir para o descarte."}
		if p["actions"] < cost:
			return {"ok": false, "reason": "Ações insuficientes: custa %d." % cost}
	return {"ok": true, "reason": "", "cost": cost}


func play_card(pi: int, hand_idx: int, insert_at: int = -1) -> bool:
	var chk := can_play(pi, hand_idx)
	if not chk["ok"]:
		log_msg.emit(chk["reason"])
		return false
	var p: Dictionary = players[pi]
	var card: Dictionary = p["hand"][hand_idx]
	p["hand"].remove_at(hand_idx)
	hand_changed.emit(pi)
	card["owner"] = pi
	if card["category"] == "champion":
		var cost: int = 0 if card.get("summon_ritual", 0) > 0 else summon_cost(card)
		if card.get("summon_ritual", 0) > 0:
			var sac_idx: int = _find_ally_with_power(pi, int(card["summon_ritual"]))
			if sac_idx >= 0:
				var sac: Dictionary = p["field"][sac_idx]
				log_msg.emit("Ritual: %s foi sacrificado!" % sac["name"])
				destroy_champion(pi, sac, -1, "sacrifício", false)
		p["actions"] -= cost
		actions_changed.emit(pi)
		# invocação posicionada: à direita/esquerda/entre campeões aliados,
		# conforme o ponto onde o jogador soltou a carta (respeitando máx. 6)
		if insert_at >= 0 and insert_at < p["field"].size():
			p["field"].insert(insert_at, card)
		else:
			p["field"].append(card)
		play_history.append({"card": card.duplicate(), "pi": pi})
		p["stats"]["summons"] = int(p["stats"]["summons"]) + 1
		card["tapped"] = false
		if p["curse_next"]:
			p["curse_next"] = false
			card["silenced"] = true
			log_msg.emit("Maldição dos Sete Mares: %s entra sem habilidade!" % card["name"])
		champion_summoned.emit(pi, card)
		field_changed.emit(pi)
		log_msg.emit("%s invocou %s (P%d)." % [p["name"], card["name"], card["current_power"]])
		if not card["silenced"] and card.get("on_enter", "") != "":
			_resolve_on_enter(pi, card)
	else:
		p["actions"] -= summon_cost(card)
		actions_changed.emit(pi)
		log_msg.emit("%s usou o talento %s." % [p["name"], card["name"]])
		play_history.append({"card": card.duplicate(), "pi": pi})
		p["stats"]["talents"] = int(p["stats"]["talents"]) + 1
		talent_active[pi] = true
		talent_played.emit(pi, card)
		if not card["silenced"]:
			_resolve_talent(pi, card)
		p["discard"].append(card)
	_recalc_constants()
	sync_views.emit()
	_check_winner()
	return true


func talent_released(pi: int) -> void:
	talent_active[pi] = false


func _find_ally_with_power(pi: int, power: int) -> int:
	var f: Array = players[pi]["field"]
	for i in f.size():
		if int(f[i]["current_power"]) == power:
			return i
	return -1


# ----------------------------------------------------------------------------
# Combate
# ----------------------------------------------------------------------------

func _is_pesado(c: Dictionary) -> bool:
	return c.get("ability_name", "") == "Pesado Demais" and not c["silenced"]


func _is_resistente(c: Dictionary) -> bool:
	return c.get("ability_name", "") == "Resistente" and not c["silenced"]


func _is_overpower(c: Dictionary) -> bool:
	if c["silenced"]:
		return false
	if c.get("ability_name", "") == "Sobrepujar":
		return true
	return int(c.get("tecnicas_turns", 0)) > 0


func attack_cost(att: Dictionary, defc: Dictionary) -> int:
	if att.get("prision", false) and not att["silenced"]:
		return 2
	if att["free_attack"] and not _is_pesado(att) and not att.get("prision", false):
		return 0
	var cost := 1
	if _is_resistente(defc):
		cost = 2
	if _is_pesado(att):
		cost = maxi(cost, 2)
	return cost


func can_attack(pi: int, att_idx: int, def_idx: int) -> Dictionary:
	if winner != -1 or current != pi:
		return {"ok": false, "reason": "Não é o seu turno."}
	var att: Dictionary = players[pi]["field"][att_idx] if att_idx < players[pi]["field"].size() else {}
	var ef: Array = players[1 - pi]["field"]
	var defc: Dictionary = ef[def_idx] if def_idx < ef.size() else {}
	if att.is_empty() or defc.is_empty():
		return {"ok": false, "reason": "Alvo inválido."}
	if att["tapped"]:
		return {"ok": false, "reason": "%s já atacou neste turno." % att["name"]}
	if int(att["frozen_turns"]) > 0:
		return {"ok": false, "reason": "%s está congelado." % att["name"]}
	if int(att["charm_turns"]) > 0:
		return {"ok": false, "reason": "%s está enfeitiçado e não ataca." % att["name"]}
	if int(defc.get("shield_turns", 0)) != 0:
		return {"ok": false, "reason": "%s está com Proteção." % defc["name"]}
	if _is_resistente(defc) and (att["free_attack"] or _is_pesado(att) or att.get("prision", false)):
		return {"ok": false, "reason": "%s não pode ser atacado por %s." % [defc["name"], att["name"]]}
	var cost: int = attack_cost(att, defc)
	if cost > 0 and players[pi]["actions"] < cost:
		return {"ok": false, "reason": "Ações insuficientes (custa %d)." % cost}
	return {"ok": true, "reason": "", "cost": cost}


func attack(pi: int, att_idx: int, def_idx: int) -> bool:
	var chk := can_attack(pi, att_idx, def_idx)
	if not chk["ok"]:
		log_msg.emit(chk["reason"])
		return false
	var p: Dictionary = players[pi]
	var att: Dictionary = p["field"][att_idx]
	var defc: Dictionary = players[1 - pi]["field"][def_idx]
	var cost: int = chk["cost"]
	if cost > 0:
		p["actions"] -= cost
		actions_changed.emit(pi)
	att["tapped"] = true
	att["free_attack"] = false
	p["stats"]["attacks"] = int(p["stats"]["attacks"]) + 1
	var out := _combat_outcome(att, defc)
	var result := "%s (P%d) ataca %s (P%d)." % [att["name"], att["current_power"], defc["name"], defc["current_power"]]
	var dp: int = 1 - pi
	if out["kill_d"]:
		var reward: int = 2 if (att.get("constant", "") == "recompensaDupla" and not att["silenced"]) else 1
		result += " %s foi destruído!" % defc["name"]
		destroy_champion(dp, defc, pi, "combate", true, reward)
		if att.get("constant", "") == "lacoDeSangue" and not att["silenced"]:
			var ally := _random_card(p["field"])
			if not ally.is_empty():
				ally["current_power"] += 1
				log_msg.emit("Laço de Sangue: %s ganha +1 de Poder." % ally["name"])
	if out["kill_a"]:
		result += " %s foi destruído no contra-ataque!" % att["name"]
		# Regra original (§5.2): na destruição mútua SÓ o atacante pontua.
		destroy_champion(pi, att, dp, "combate", not out["kill_d"], 1)
	if out["kill_a"] and out["kill_d"]:
		result += " Destruição mútua — o atacante pontua."
	elif not out["kill_a"] and not out["kill_d"]:
		result += " Sobrepujar duplo: ninguém cai!"
	attack_done.emit(pi, att, dp, defc, result)
	log_msg.emit(result)
	_recalc_constants()
	sync_views.emit()
	_check_winner()
	return true


func _combat_outcome(a: Dictionary, d: Dictionary) -> Dictionary:
	var oa := _is_overpower(a)
	var od := _is_overpower(d)
	if a["current_power"] > d["current_power"]:
		return {"kill_a": false, "kill_d": true}
	if a["current_power"] < d["current_power"]:
		return {"kill_a": true, "kill_d": false}
	if oa and not od:
		return {"kill_a": false, "kill_d": true}
	if not oa and od:
		return {"kill_a": true, "kill_d": false}
	if oa and od:
		return {"kill_a": false, "kill_d": false}
	return {"kill_a": true, "kill_d": true}


func _no_vp_on_destroy(card: Dictionary) -> bool:
	if card.get("corrupted", false):
		return true
	if card.get("silenced", false):
		return false
	return card.get("on_destroy", "") == "noHonor" or card.get("ability_name", "") == "Sem Honra"


func is_sem_honra(card: Dictionary) -> bool:
	## (1.49.76) público: o campeão tem o STATUS SEM HONRA agora?
	return _no_vp_on_destroy(card)


func destroy_champion(owner_pi: int, card: Dictionary, by_pi: int, reason: String, grant_vp: bool = true, vp_amount: int = 1) -> void:
	var f: Array = players[owner_pi]["field"]
	var idx := _idx_of(f, int(card["uid"]))
	if idx < 0:
		return
	f.remove_at(idx)
	# charmed: se morrer, dono original não recebe de volta
	players[owner_pi]["discard"].append(card)
	var gave_vp := false
	if by_pi >= 0 and by_pi != owner_pi:
		players[by_pi]["stats"]["champKills"] = int(players[by_pi]["stats"]["champKills"]) + 1
	# (1.49.76) animação de destruição especial substitui a padrão:
	# SEM HONRA => explosão roxa + caveira; RECOMPENSA DUPLA => burst de
	# estrelas + "x2".
	var style := ""
	if _no_vp_on_destroy(card):
		style = "semhonra"
	elif vp_amount >= 2 and by_pi >= 0 and by_pi != owner_pi:
		style = "recompensa"
	if style != "":
		destroy_style.emit(int(card["uid"]), style)
	if grant_vp and by_pi >= 0 and by_pi != owner_pi and not _no_vp_on_destroy(card):
		gain_vp(by_pi, vp_amount)
		gave_vp = true
	champion_destroyed.emit(owner_pi, card, reason, gave_vp)
	field_changed.emit(owner_pi)
	if not card.get("silenced", false):
		match String(card.get("on_destroy", "")):
			"vinganca":
				var foe := _random_card(players[1 - owner_pi]["field"])
				if not foe.is_empty():
					log_msg.emit("Vingança: %s perde 1 de Poder!" % foe["name"])
					reduce_power(1 - owner_pi, foe, 1, -1, false, "vingança")
			"legado":
				var ally := _random_card(players[owner_pi]["field"])
				if not ally.is_empty():
					ally["current_power"] += 1
					log_msg.emit("Legado: %s ganha +1 de Poder!" % ally["name"])
	_recalc_constants()
	sync_views.emit()


func reduce_power(owner_pi: int, card: Dictionary, amount: int, by_pi: int, grant_vp: bool, reason: String) -> void:
	if amount <= 0 or winner != -1:
		return
	if _idx_of(players[owner_pi]["field"], int(card["uid"])) < 0:
		return  # já não está em campo
	if int(card.get("barrier_turns", 0)) != 0:
		log_msg.emit("Barreira: %s bloqueou a redução de Poder." % card["name"])
		return
	if card.get("vulnerable", false):
		log_msg.emit("Fumaça Tóxica: %s é destruído ao perder Poder!" % card["name"])
		destroy_champion(owner_pi, card, by_pi, reason, grant_vp)
		return
	card["current_power"] = int(card["current_power"]) - amount
	# (1.49.74) MURALHA: se o campeão perder Poder FORA do próprio turno, a
	# Muralha QUEBRA (o ponto adicional de Poder é o ponto perdido) — e no
	# início do próximo turno próprio ele NÃO perde Poder de novo, porque
	# wall_buff já é 0. No fim do turno, _recalc_constants reativa a Muralha.
	if int(card.get("wall_buff", 0)) > 0 and current != owner_pi:
		card["wall_buff"] = 0
		log_msg.emit("Muralha: %s perde o bônus e a Muralha quebra!" % card["name"])
	sync_views.emit()
	if int(card["current_power"]) <= 0:
		destroy_champion(owner_pi, card, by_pi, reason, grant_vp)


func can_use_ultimate(pi: int) -> Dictionary:
	if winner != -1 or current != pi:
		return {"ok": false, "reason": "Não é o seu turno."}
	var p: Dictionary = players[pi]
	if p["ult_used_this_turn"]:
		return {"ok": false, "reason": "Ultimate já usada neste turno."}
	if int(p["ult_remaining"]) <= 0:
		return {"ok": false, "reason": "Sem usos de Ultimate restantes."}
	return {"ok": true, "reason": ""}


func use_ultimate(pi: int) -> bool:
	var chk := can_use_ultimate(pi)
	if not chk["ok"]:
		log_msg.emit(chk["reason"])
		return false
	var p: Dictionary = players[pi]
	var foe_pi: int = 1 - pi
	var ff: Array = players[foe_pi]["field"]
	var mf: Array = p["field"]
	var hero: Dictionary = p["hero"]
	var utype: String = String(hero.get("ultimateType", ""))
	var hname: String = String(hero.get("name", ""))
	var uname: String = String(hero.get("ult", ""))
	p["ult_used_this_turn"] = true
	p["ult_remaining"] = int(p["ult_remaining"]) - 1
	p["stats"]["ultimates"] = int(p["stats"]["ultimates"]) + 1
	match utype:
		"targetEnemy":
			var t := _strongest(ff)
			if t.is_empty():
				log_msg.emit("%s: sem alvo." % uname)
			else:
				log_msg.emit("%s usa %s: %s perde 1 Poder!" % [hname, uname, t["name"]])
				reduce_power(foe_pi, t, 1, pi, true, "ultimate")
		"targetEnemyFreeze":
			var t := _strongest(ff)
			if t.is_empty():
				log_msg.emit("%s: sem alvo." % uname)
			else:
				t["frozen_turns"] = maxi(int(t["frozen_turns"]), 3)
				log_msg.emit("%s usa %s: %s congelado por 3 rodadas!" % [hname, uname, t["name"]])
		"targetAlly":
			var t := _strongest(mf)
			if t.is_empty():
				log_msg.emit("%s: nenhum aliado." % uname)
			else:
				t["current_power"] += 1
				log_msg.emit("%s usa %s: %s ganha +1 Poder." % [hname, uname, t["name"]])
		"targetAllyFreeAttack":
			var t := _strongest(mf)
			if t.is_empty():
				log_msg.emit("%s: nenhum aliado." % uname)
			else:
				t["free_attack"] = true
				t["tapped"] = false
				log_msg.emit("%s usa %s: %s ataca como ação livre!" % [hname, uname, t["name"]])
		"drawCard":
			draw_cards(pi, 1)
			log_msg.emit("%s usa %s: comprou 1 carta!" % [hname, uname])
		"targetAllyShield":
			var any := false
			for c in mf:
				if int(c["current_power"]) == 1:
					_add_shield(c, 1)
					any = true
			log_msg.emit("%s usa %s: campeões P1 protegidos por 1 rodada." % [hname, uname] if any else "%s: nenhum campeão P1." % uname)
		"trickerySwap":
			var mine := mf.filter(func(c): return int(c["current_power"]) == 1)
			if mine.is_empty() or ff.is_empty():
				log_msg.emit("%s: sem par para trocar." % uname)
			else:
				_swap_champions(pi, _random_card(mine), foe_pi, _random_card(ff))
				log_msg.emit("%s usa %s!" % [hname, uname])
		"thunderDiscard":
			var fh: Array = players[foe_pi]["hand"]
			if fh.is_empty():
				log_msg.emit("%s: adversário sem cartas." % uname)
			else:
				var i: int = rng.randi_range(0, fh.size() - 1)
				var gone: Dictionary = fh[i]
				fh.remove_at(i)
				players[foe_pi]["discard"].append(gone)
				hand_changed.emit(foe_pi)
				log_msg.emit("%s usa %s: %s descartada!" % [hname, uname, gone["name"]])
		"fireAndIce":
			if ff.is_empty():
				log_msg.emit("%s: sem alvos." % uname)
			for c in ff.duplicate():
				if _idx_of(ff, int(c["uid"])) < 0:
					continue
				if rng.randf() < 0.5:
					c["frozen_turns"] = maxi(int(c["frozen_turns"]), 2)
					log_msg.emit("Fogo e Gelo: %s CONGELADO!" % c["name"])
				else:
					log_msg.emit("Fogo e Gelo: bola de fogo em %s!" % c["name"])
					reduce_power(foe_pi, c, 1, pi, true, "ultimate")
		"summonDragon":
			_summon_token(pi, "DRAGÃO AZUL")
		"hook":
			var elig := ff.filter(func(c): return int(c["current_power"]) <= 2 and int(c.get("shield_turns", 0)) == 0)
			if elig.is_empty() or mf.size() >= MAX_FIELD:
				log_msg.emit("%s: sem alvo puxável ou campo cheio." % uname)
			else:
				var t: Dictionary = _random_card(elig)
				ff.remove_at(_idx_of(ff, int(t["uid"])))
				t["owner"] = pi
				t["tapped"] = true
				mf.append(t)
				log_msg.emit("%s usa %s: %s foi ROUBADO!" % [hname, uname, t["name"]])
				champion_summoned.emit(pi, t)
				field_changed.emit(foe_pi)
				field_changed.emit(pi)
		"resurrect":
			var cand: Array = p["discard"].filter(func(c): return c["category"] == "champion" and int(c.get("power", 0)) == 2)
			if cand.is_empty() or mf.size() >= MAX_FIELD:
				log_msg.emit("%s: sem Campeão P2 no descarte ou campo cheio." % uname)
			else:
				var t: Dictionary = cand[cand.size() - 1]
				p["discard"].erase(t)
				_reset_champion(t)
				t["owner"] = pi
				mf.append(t)
				log_msg.emit("%s usa %s: %s retorna!" % [hname, uname, t["name"]])
				champion_summoned.emit(pi, t)
				field_changed.emit(pi)
		"potion":
			var t := _random_card(mf)
			if t.is_empty():
				log_msg.emit("%s: nenhum aliado." % uname)
			elif rng.randf() < 0.6:
				t["current_power"] += 2
				log_msg.emit("Poção: %s ganha +2 Poder!" % t["name"])
			else:
				log_msg.emit("Poção ruim: %s perde 1 Poder!" % t["name"])
				reduce_power(pi, t, 1, -1, false, "poção")
		"vampirism":
			var elig := ff.filter(func(c): return int(c["current_power"]) >= 2)
			if elig.is_empty() or mf.is_empty():
				log_msg.emit("%s: sem alvo/alido." % uname)
			else:
				var t: Dictionary = _random_card(elig)
				log_msg.emit("Vampirismo: %s perde 1 Poder." % t["name"])
				reduce_power(foe_pi, t, 1, pi, true, "vampirismo")
				var a := _random_card(mf)
				if not a.is_empty():
					a["current_power"] += 1
					log_msg.emit("Vampirismo: %s ganha +1 Poder." % a["name"])
		"banish":
			var elig := ff.filter(func(c): return int(c["current_power"]) <= 2)
			if elig.is_empty():
				log_msg.emit("%s: sem alvo banível." % uname)
			else:
				var t: Dictionary = _random_card(elig)
				ff.remove_at(_idx_of(ff, int(t["uid"])))
				log_msg.emit("Outra Dimensão: %s foi BANIDO do jogo!" % t["name"])
				champion_destroyed.emit(foe_pi, t, "banido", false)
				field_changed.emit(foe_pi)
		"poison":
			var t := _strongest(ff)
			if t.is_empty():
				log_msg.emit("%s: sem alvo." % uname)
			else:
				t["poison_turns"] = 2
				t["poison_by"] = pi
				log_msg.emit("%s usa %s: %s envenenado!" % [hname, uname, t["name"]])
		"infinitePower":
			if mf.is_empty():
				log_msg.emit("%s: nenhum aliado." % uname)
			for c in mf:
				c["ult_growth"] = true
			if not mf.is_empty():
				log_msg.emit("%s usa %s: aliados ganham +1 Poder por rodada!" % [hname, uname])
		"scareReturn":
			var elig := ff.filter(func(c): return int(c["current_power"]) <= 2)
			if elig.is_empty():
				log_msg.emit("%s: sem alvo." % uname)
			else:
				var t: Dictionary = _random_card(elig)
				ff.remove_at(_idx_of(ff, int(t["uid"])))
				_reset_champion(t)
				if players[foe_pi]["hand"].size() < MAX_HAND:
					t["owner"] = foe_pi
					players[foe_pi]["hand"].append(t)
					hand_changed.emit(foe_pi)
				else:
					players[foe_pi]["discard"].append(t)
				log_msg.emit("%s usa %s: %s voltou para a mão!" % [hname, uname, t["name"]])
				field_changed.emit(foe_pi)
		"cometStarfall":
			for q in 2:
				for c in players[q]["field"].duplicate():
					if _idx_of(players[q]["field"], int(c["uid"])) < 0:
						continue
					log_msg.emit("Cometa Estrelar atingiu %s." % c["name"])
					reduce_power(q, c, 1, pi if q != pi else -1, q != pi, "cometa")
		"incinerate":
			var t := _strongest(ff)
			if t.is_empty():
				log_msg.emit("%s: sem alvo." % uname)
			else:
				t["burn_turns"] = maxi(int(t["burn_turns"]), 4)
				t["burn_by"] = pi
				log_msg.emit("%s usa %s: %s em chamas!" % [hname, uname, t["name"]])
		"reuseInstant":
			var cand := mf.filter(func(c): return String(c.get("ability_type", "")) == "instant" and String(c.get("on_enter", "")) != "" and not c["silenced"])
			if cand.is_empty():
				log_msg.emit("%s: nenhum aliado com habilidade instantânea." % uname)
			else:
				var t: Dictionary = _random_card(cand)
				log_msg.emit("%s usa %s: %s repete a habilidade!" % [hname, uname, t["name"]])
				_resolve_on_enter(pi, t)
		_:
			log_msg.emit("Ultimate de %s ainda não implementada." % hname)
	ultimate_used.emit(pi)
	sync_views.emit()
	_check_winner()
	return true


func gain_vp(pi: int, n: int) -> void:
	if n == 0 or winner != -1:
		return
	players[pi]["vp"] = int(players[pi]["vp"]) + n
	vp_changed.emit(pi)
	_check_winner()


func lose_vp(pi: int, n: int) -> void:
	players[pi]["vp"] = maxi(0, int(players[pi]["vp"]) - n)
	vp_changed.emit(pi)


func _check_winner() -> void:
	if winner != -1:
		return
	for pi in 2:
		if int(players[pi]["vp"]) >= win_points:
			winner = pi
			if not targeting.is_empty():
				var tp: int = int(targeting["pi"])
				targeting = {}
				targeting_ended.emit(tp)
			game_over.emit(pi)
			return


func _idx_of(arr: Array, uid: int) -> int:
	for i in arr.size():
		if int(arr[i]["uid"]) == uid:
			return i
	return -1


func idx_of_uid(pi: int, uid: int, where: String = "field") -> int:
	return _idx_of(players[pi][where], uid)


func _add_shield(c: Dictionary, turns: int) -> void:
	if int(c.get("shield_turns", 0)) == -1:
		return  # já permanente
	c["shield_turns"] = maxi(int(c.get("shield_turns", 0)), turns)


func _add_barrier(c: Dictionary, turns: int) -> void:
	# (1.49.79) sem sync_views o painel da Barreira não aparecia em campo
	sync_views.emit()
	if int(c.get("barrier_turns", 0)) == -1:
		return  # já permanente
	c["barrier_turns"] = maxi(int(c.get("barrier_turns", 0)), turns)


func _random_card(arr: Array) -> Dictionary:
	if arr.is_empty():
		return {}
	return arr[rng.randi_range(0, arr.size() - 1)]


func _strongest(arr: Array) -> Dictionary:
	var best := {}
	for c in arr:
		if best.is_empty() or int(c["current_power"]) > int(best["current_power"]):
			best = c
	return best


# ----------------------------------------------------------------------------
# Status por turno (manutenção)
# ----------------------------------------------------------------------------

func _tick_statuses(pi: int) -> void:
	var f: Array = players[pi]["field"].duplicate()
	for card in f:
		if _idx_of(players[pi]["field"], int(card["uid"])) < 0:
			continue  # já morreu neste tick
		if int(card["frozen_turns"]) > 0:
			card["frozen_turns"] -= 1
			if int(card["frozen_turns"]) <= 0:
				log_msg.emit("%s descongelou." % card["name"])
		if int(card["shield_turns"]) > 0:
			card["shield_turns"] -= 1
		if int(card["barrier_turns"]) > 0:
			card["barrier_turns"] -= 1
			sync_views.emit()
		if int(card["fury_turns"]) > 0:
			card["fury_turns"] -= 1
			if int(card["fury_turns"]) <= 0 and int(card["fury_stacks"]) > 0:
				card["current_power"] = maxi(0, int(card["current_power"]) - int(card["fury_stacks"]))
				log_msg.emit("Fúria expirou: %s -%d de Poder." % [card["name"], card["fury_stacks"]])
				card["fury_stacks"] = 0
				if int(card["current_power"]) <= 0:
					destroy_champion(pi, card, -1, "fúria expirou", false)
					continue
		if int(card["tecnicas_turns"]) > 0:
			card["tecnicas_turns"] -= 1
		if int(card["poison_turns"]) > 0:
			card["poison_turns"] -= 1
			if int(card["poison_turns"]) <= 0:
				log_msg.emit("Veneno consumiu %s!" % card["name"])
				destroy_champion(pi, card, int(card["poison_by"]), "veneno", true)
				continue
		if int(card["burn_turns"]) > 0:
			card["burn_turns"] -= 1
			log_msg.emit("Em Chamas: %s perde 1 de Poder." % card["name"])
			reduce_power(pi, card, 1, int(card["burn_by"]), true, "em chamas")
			if _idx_of(players[pi]["field"], int(card["uid"])) < 0:
				continue
		if card.get("ult_growth", false):
			card["current_power"] += 1
		if card.get("ability_name", "") == "Crescimento" and not card["silenced"]:
			card["current_power"] += 1
			log_msg.emit("Crescimento: %s agora tem P%d." % [card["name"], card["current_power"]])
	sync_views.emit()


func _tick_charms(pi: int) -> void:
	# Campeões enfeitiçados POR pi voltam ao dono no início do turno de pi
	var f: Array = players[pi]["field"].duplicate()
	for card in f:
		if int(card.get("charm_turns", 0)) > 0 and int(card.get("charm_owner", -1)) == pi:
			card["charm_turns"] -= 1
			if int(card["charm_turns"]) <= 0:
				_return_charmed(pi, card)


func _return_charmed(charmer_pi: int, card: Dictionary) -> void:
	var f: Array = players[charmer_pi]["field"]
	var idx := _idx_of(f, int(card["uid"]))
	if idx < 0:
		return
	f.remove_at(idx)
	var orig: int = int(card["charm_orig_owner"])
	card["charm_turns"] = 0
	card["charm_owner"] = -1
	card["charm_orig_owner"] = -1
	card["tapped"] = true
	if orig >= 0 and orig != charmer_pi and players[orig]["field"].size() < MAX_FIELD:
		card["owner"] = orig
		players[orig]["field"].append(card)
		log_msg.emit("Charme terminou: %s voltou para %s." % [card["name"], players[orig]["name"]])
		champion_summoned.emit(orig, card)
		field_changed.emit(orig)
	else:
		players[charmer_pi]["discard"].append(card)
		log_msg.emit("Charme terminou sem espaço: %s foi descartado." % card["name"])
	field_changed.emit(charmer_pi)


# ----------------------------------------------------------------------------
# Constantes dinâmicas (Desafiante, Inspirar, Muralha)
# ----------------------------------------------------------------------------

func _recalc_constants() -> void:
	for pi in 2:
		var f: Array = players[pi]["field"]
		for c in f:
			if int(c["desafiante_buff"]) > 0:
				c["current_power"] -= int(c["desafiante_buff"])
				c["desafiante_buff"] = 0
			if int(c["inspirar_buff"]) > 0:
				c["current_power"] -= int(c["inspirar_buff"])
				c["inspirar_buff"] = 0
			if int(c["wall_buff"]) > 0:
				c["current_power"] -= int(c["wall_buff"])
				c["wall_buff"] = 0
		for i in f.size():
			var c: Dictionary = f[i]
			if c["silenced"]:
				continue
			if c.get("constant", "") == "desafiante" and f.size() == 1:
				c["desafiante_buff"] = 2
				c["current_power"] += 2
			if c.get("constant", "") == "inspirar":
				for j in [i - 1, i + 1]:
					if j >= 0 and j < f.size():
						f[j]["inspirar_buff"] += 1
						f[j]["current_power"] += 1
			if c.get("constant", "") == "muralha" and int(c.get("charm_turns", 0)) <= 0:
				if pi != current:
					c["wall_buff"] = 1
					c["current_power"] += 1
	for c0 in players[0]["field"]:
		c0["current_power"] = maxi(0, int(c0["current_power"]))
	for c1 in players[1]["field"]:
		c1["current_power"] = maxi(0, int(c1["current_power"]))
	# (1.49.81) sem isto a Muralha (wall_buff) não aparecia/não saía na hora
	# da virada de turno para o jogador principal
	sync_views.emit()


# ----------------------------------------------------------------------------
# MIRA / escolha de alvo (BOLA DE FOGO e similares)
# ----------------------------------------------------------------------------

func effect_needs_target(effect: String) -> bool:
	return effect == "bolaDeFogo" or effect == "bolaDeFogoTalento" or effect == "fortalecer" or effect == "fortalecerTalento" or effect == "corromper" or effect == "corromperTalento" or effect == "rajadaCongelante" or effect == "zeroAbsoluto" or effect == "mordidaVenenosa" or effect == "baforadaVenenosa"


func _effect_is_ally(effect: String) -> bool:
	# (1.49.70/79) FORTALECER e CORROMPER escolhem um Campeão ALIADO (verde).
	# CONGELAR/ZERO ABSOLUTO miram INIMIGOS (azul) — não entram aqui.
	return effect == "fortalecer" or effect == "fortalecerTalento" or effect == "corromper" or effect == "corromperTalento"


func targeting_active_for(uid: int) -> bool:
	if targeting.is_empty():
		return false
	return int(targeting.get("card_uid", -1)) == uid or int(targeting.get("source_uid", -2)) == uid


func auto_pick_uid() -> int:
	# alvo automático (IA / testes): o Campeão mais forte entre os candidatos
	if targeting.is_empty():
		return -1
	var pi: int = int(targeting["pi"])
	var cands: Array = targeting.get("candidates", [])
	if _effect_is_ally(String(targeting.get("effect", ""))):
		var pool: Array = players[pi]["field"].filter(func(c): return cands.has(int(c["uid"])))
		var ta := _strongest(pool)
		return int(ta.get("uid", -1)) if not ta.is_empty() else -1
	var t := _strongest(players[1 - pi]["field"])
	return int(t.get("uid", -1)) if not t.is_empty() else -1


func _begin_or_resolve_target(pi: int, card: Dictionary, effect: String, source_uid: int) -> void:
	var ally_eff := _effect_is_ally(effect)
	var pool: Array
	if effect == "assassinar":
		# (1.50.2) só Campeões adversários com Poder 1 estão aptos
		pool = players[1 - pi]["field"].filter(func(c): return int(c["power"]) == 1)
		if pool.is_empty():
			log_msg.emit("Assassinar: nenhum Campeão P1 adversário.")
			return
	elif ally_eff:
		# (1.49.70) FORTALECER: os OUTROS campeões aliados ficam aptos (verde)
		pool = players[pi]["field"].filter(func(c): return int(c["uid"]) != int(card["uid"]))
	else:
		pool = players[1 - pi]["field"]
	if pool.is_empty():
		if ally_eff:
			if effect == "fortalecer":
				# sem outros aliados: o próprio invocado recebe o +1
				# (comportamento anterior do motor, mantido)
				card["current_power"] += 1
				log_msg.emit("Fortalecer: %s ganha +1 de Poder." % card["name"])
			elif effect == "fortalecerTalento":
				log_msg.emit("Fortalecer: nenhum aliado.")
			elif _is_congelar(effect):
				log_msg.emit("Congelar: sem alvo.")
			else:
				log_msg.emit("Corromper: nenhum aliado.")
		elif effect == "mordidaVenenosa":
			log_msg.emit("Mordida Venenosa: sem alvo.")
		elif effect == "baforadaVenenosa":
			log_msg.emit("Baforada Venenosa: sem alvo.")
		else:
			log_msg.emit("Bola de Fogo: sem alvo.")
		return
	if auto_target or not targeting.is_empty():
		# sem espera (simulações) ou mira já ocupada: resolve no mais forte
		var t := _strongest(pool)
		if not t.is_empty():
			if effect == "assassinar":
				_apply_assassinar(pi, t)
			elif _is_congelar(effect):
				_apply_congelar(pi, source_uid, t, effect)
			elif effect == "mordidaVenenosa":
				_apply_mordida(pi, source_uid, t)
			elif effect == "baforadaVenenosa":
				_apply_baforada(pi, source_uid, t)
			elif not ally_eff:
				_apply_bola(pi, source_uid, t)
			elif effect.begins_with("fortalecer"):
				_apply_fortalecer(pi, source_uid, t)
			else:
				_apply_corromper(pi, t)
		return
	var cands: Array = []
	for c in pool:
		cands.append(int(c["uid"]))
	targeting = {
		"pi": pi, "effect": effect, "source_uid": source_uid,
		"card_uid": int(card["uid"]), "candidates": cands,
	}
	if ally_eff:
		log_msg.emit("Fortalecer: escolha um Campeão aliado destacado em verde!")
	elif effect == "mordidaVenenosa":
		log_msg.emit("Mordida Venenosa: escolha um Campeão adversário destacado em verde!")
	elif effect == "baforadaVenenosa":
		log_msg.emit("Baforada Venenosa: escolha um Campeão adversário destacado em verde!")
	else:
		log_msg.emit("Bola de Fogo: escolha um Campeão adversário iluminado em vermelho!")
	targeting_started.emit(pi, effect, source_uid, cands.duplicate())


func confirm_targeting(uid: int) -> void:
	if targeting.is_empty():
		return
	var pi: int = int(targeting["pi"])
	var src: int = int(targeting["source_uid"])
	var cands: Array = targeting["candidates"]
	var ally_eff := _effect_is_ally(String(targeting["effect"]))
	var targeting_effect: String = String(targeting["effect"])
	targeting = {}
	targeting_ended.emit(pi)
	if not cands.has(uid):
		return
	var field: Array = players[pi]["field"] if ally_eff else players[1 - pi]["field"]
	var t: Dictionary = {}
	for c in field:
		if int(c["uid"]) == uid:
			t = c
			break
	if t.is_empty():
		log_msg.emit("Fortalecer: sem aliado." if ally_eff else "Bola de Fogo: sem alvo.")
	elif String(targeting_effect) == "assassinar":
		_apply_assassinar(pi, t)
	elif _is_congelar(String(targeting_effect)):
		_apply_congelar(pi, src, t, String(targeting_effect))
	elif String(targeting_effect) == "mordidaVenenosa":
		_apply_mordida(pi, src, t)
	elif String(targeting_effect) == "baforadaVenenosa":
		_apply_baforada(pi, src, t)
	elif not ally_eff:
		_apply_bola(pi, src, t)
	elif String(targeting_effect).begins_with("fortalecer"):
		_apply_fortalecer(pi, src, t)
	else:
		_apply_corromper(pi, t)


func _apply_fortalecer(pi: int, source_uid: int, t: Dictionary) -> void:
	# (1.49.70) O +1 NÃO é imediato: fica PENDENTE até o fim da animação VFX
	# de Fortalecer (2 s), chamada pela Tela de Combate via resolve_fortalecer.
	if auto_target:
		log_msg.emit("Fortalecer: %s ganha +1 de Poder." % t["name"])
		t["current_power"] += 1
		field_changed.emit(pi)
		return
	pending_fort.append({"pi": pi, "uid": int(t["uid"]), "ms": Time.get_ticks_msec()})
	fx_fortalecer.emit(pi, int(source_uid), int(t["uid"]))


func resolve_roubo(pi: int, uid: int) -> void:
	## Efetiva o roubo (chamado pela Tela de Combate no fim do voo da carta).
	var done: Dictionary = {}
	for e in pending_roubo:
		if int(e["pi"]) == pi and int(e["uid"]) == uid:
			done = e
	if done.is_empty():
		return
	pending_roubo.erase(done)
	var foe: int = int(done["foe"])
	var fh: Array = players[foe]["hand"]
	var idx := -1
	for j in fh.size():
		if int(fh[j]["uid"]) == uid:
			idx = j
	if idx < 0:
		return
	var stolen: Dictionary = fh[idx]
	fh.remove_at(idx)
	stolen["owner"] = pi
	players[pi]["hand"].append(stolen)
	log_msg.emit("Roubar: %s pegou uma carta da mão adversária!" % players[pi]["name"])
	hand_changed.emit(foe)
	hand_changed.emit(pi)


func resolve_forja(pi: int) -> void:
	## Efetiva o saque livre da Forja (após a animação do martelo).
	if not pending_forja.has(pi):
		return
	pending_forja.erase(pi)
	if players[pi]["deck"].is_empty():
		return
	draw_cards(pi, 1)
	log_msg.emit("Forja: %s comprou 1 carta como ação livre." % players[pi]["name"])


func _apply_furia_now(c: Dictionary) -> void:
	c["fury_stacks"] += 1
	c["current_power"] += 1
	c["fury_turns"] = maxi(int(c["fury_turns"]), 1)
	log_msg.emit("Fúria: %s ganha +1 de Poder por 1 rodada." % c["name"])


func resolve_furia(uid: int) -> void:
	# (1.49.89) aplica o status FÚRIA após a animação do raio.
	for p in players:
		for c in p["field"]:
			if int(c["uid"]) == uid:
				_apply_furia_now(c)
				sync_views.emit()
				return


func resolve_defensor(uid: int) -> void:
	# (1.49.93) aplica a Proteção PERMANENTE após a animação defensiva épica.
	for e in pending_defensor.duplicate():
		if int(e["uid"]) == uid:
			pending_defensor.erase(e)
	for p in players:
		for c in p["field"]:
			if int(c["uid"]) == uid:
				c["shield_turns"] = -1
				log_msg.emit("Defensor: %s recebe Proteção permanente." % c["name"])
				sync_views.emit()
				return


func resolve_guardiao(uid: int) -> void:
	# (1.49.93) aplica a Proteção (1 rodada) no aliado após o pilar de luz dele.
	for e in pending_guardiao.duplicate():
		if int(e["uid"]) == uid:
			pending_guardiao.erase(e)
	for p in players:
		for c in p["field"]:
			if int(c["uid"]) == uid:
				_add_shield(c, 1)
				sync_views.emit()
				return


func resolve_pesadelo() -> void:
	# (1.49.93) marca o saque bloqueado NO FIM da enxurrada de fantasmas.
	if _pending_pesadelo.is_empty():
		return
	var foe: int = int(_pending_pesadelo.get("foe", -1))
	_pending_pesadelo = {}
	if foe < 0 or foe > 1:
		return
	players[foe]["skip_draw"] = true
	log_msg.emit("Pesadelo: %s não comprará carta no próximo turno!" % players[foe]["name"])
	sync_views.emit()


func resolve_invoke_dragon() -> void:
	# (1.49.93) invoca o FILHOTE DE DRAGÃO quando o ovo choca (burst de luz).
	if _pending_invoke.is_empty():
		return
	var pi: int = int(_pending_invoke.get("pi", 0))
	_pending_invoke = {}
	_summon_token(pi, "FILHOTE DE DRAGÃO")


func _flush_enter_fx() -> void:
	# (1.49.93) segurança de fim de turno: nenhum efeito de entrada animado
	# (Defensor/Guardião/Pesadelo/Invocar Dragão) atravessa o turno pendente.
	for e in pending_defensor.duplicate():
		resolve_defensor(int(e["uid"]))
	for e in pending_guardiao.duplicate():
		resolve_guardiao(int(e["uid"]))
	if not _pending_pesadelo.is_empty():
		resolve_pesadelo()
	if not _pending_invoke.is_empty():
		resolve_invoke_dragon()


var _pending_mordida: Dictionary = {}
var _pending_baforada: Dictionary = {}


func resolve_baforada(uid: int) -> void:
	# (1.49.92) aplica ENVENENADO (morte em 2 rodadas) APÓS a baforada verde.
	for p in players:
		for c in p["field"]:
			if int(c["uid"]) == uid:
				c["poison_turns"] = 2
				c["poison_by"] = int(_pending_baforada.get("pi", 0))
				_pending_baforada = {}
				sync_views.emit()
				log_msg.emit("Baforada Venenosa: %s será destruído em 2 rodadas!" % c["name"])
				return


func _apply_baforada(pi: int, source_uid: int, t: Dictionary) -> void:
	# (1.49.92) veneno aplicado DEPOIS da baforada do Dragão Verde (a batalha
	# chama resolve_baforada); sem tela de batalha, aplica na hora.
	_pending_baforada = {"pi": pi, "uid": int(t["uid"])}
	if not fx_enabled:
		resolve_baforada(int(t["uid"]))
	else:
		fx_baforada.emit(pi, source_uid, int(t["uid"]))


func resolve_mordida(uid: int) -> void:
	# (1.49.89) aplica ENVENENADO (morte em 2 rodadas) após a animação da mordida.
	for p in players:
		for c in p["field"]:
			if int(c["uid"]) == uid:
				c["poison_turns"] = 2
				c["poison_by"] = int(_pending_mordida.get("pi", 0))
				_pending_mordida = {}
				sync_views.emit()
				log_msg.emit("ENVENENADO: %s será destruído em 2 rodadas!" % c["name"])
				return


func _is_congelar(effect: String) -> bool:
	return effect == "rajadaCongelante" or effect == "zeroAbsoluto"


func _apply_congelar(pi: int, source_uid: int, t: Dictionary, effect: String) -> void:
	# (1.49.87) aplica o CONGELAMENTO escolhido pela mira azul
	if effect == "zeroAbsoluto" and int(t.get("frozen_turns", 0)) > 0:
		log_msg.emit("Zero Absoluto: %s já estava congelado e foi destruído!" % t["name"])
		destroy_champion(1 - pi, t, pi, "zero absoluto", true)
		return
	var rounds: int = 2 if effect == "zeroAbsoluto" else 1
	t["frozen_turns"] = maxi(int(t.get("frozen_turns", 0)), rounds)
	log_msg.emit("Congelar: %s congelou por %d rodada(s)!" % [t["name"], rounds])
	sync_views.emit()
	if not auto_target:
		fx_congelar.emit(pi, source_uid, int(t["uid"]))


func _apply_mordida(pi: int, source_uid: int, t: Dictionary) -> void:
	# (1.49.89) veneno aplicado DEPOIS da animação da mordida (a batalha chama
	# resolve_mordida); sem tela de batalha, aplica na hora.
	_pending_mordida = {"pi": pi, "uid": int(t["uid"])}
	if not fx_enabled:
		resolve_mordida(int(t["uid"]))
	else:
		fx_mordida.emit(pi, source_uid, int(t["uid"]))


func _apply_corromper(pi: int, t: Dictionary) -> void:
	# (1.49.79) aplica o status SEM HONRA ao aliado escolhido (imediato)
	t["corrupted"] = true
	log_msg.emit("Corromper: destruir %s não dará PV." % t["name"])
	sync_views.emit()


func resolve_fortalecer(uid: int) -> void:
	## Aplicado no FIM da animação de Fortalecer (ou por segurança no fim da vez).
	var done: Array = []
	for e in pending_fort:
		if int(e["uid"]) == uid:
			done.append(e)
	for e in done:
		pending_fort.erase(e)
		var pi: int = int(e["pi"])
		for c in players[pi]["field"]:
			if int(c["uid"]) == uid:
				c["current_power"] += 1
				log_msg.emit("Fortalecer: %s ganha +1 de Poder." % c["name"])
				field_changed.emit(pi)
				# (1.49.75) sem isto a face baked da carta não atualizava em
				# campo durante o turno (o +1 só aparecia no fim do turno)
				sync_views.emit()
				break


func _apply_assassinar(pi: int, t: Dictionary) -> void:
	# (1.50.2) eliminação especial: a Tela de Combate roda a morte da ADAGA.
	log_msg.emit("Assassinar: %s (P1) foi eliminado!" % t["name"])
	destroy_champion(1 - pi, t, pi, "assassinar", true)


func _apply_bola(pi: int, source_uid: int, t: Dictionary) -> void:
	# (1.49.63) O dano NÃO é imediato: fica PENDENTE até a animação da Bola de
	# Fogo chegar no alvo (resolve_bola é chamado pela Tela de Combate no
	# impacto). Assim o Campeão só pode ser destruído DEPOIS da animação.
	if auto_target:
		# simulações sem tela: aplica na hora
		log_msg.emit("Bola de Fogo: %s perde 1 de Poder!" % t["name"])
		reduce_power(1 - pi, t, 1, pi, true, "bola de fogo")
		return
	pending_bola.append({"pi": pi, "uid": int(t["uid"]), "ms": Time.get_ticks_msec()})
	fx_fire.emit(pi, int(source_uid), int(t["uid"]))


func resolve_bola(uid: int) -> void:
	## Aplicado no IMPACTO da Bola de Fogo (ou por segurança no fim da vez).
	var done: Array = []
	for e in pending_bola:
		if int(e["uid"]) == uid:
			done.append(e)
	for e in done:
		pending_bola.erase(e)
		var pi: int = int(e["pi"])
		var t: Dictionary = {}
		for c in players[1 - pi]["field"]:
			if int(c["uid"]) == uid:
				t = c
				break
		if t.is_empty():
			continue
		log_msg.emit("Bola de Fogo: %s perde 1 de Poder!" % t["name"])
		reduce_power(1 - pi, t, 1, pi, true, "bola de fogo")


func _resolve_on_enter(pi: int, card: Dictionary) -> void:
	_resolve_on_enter_named(pi, card, String(card.get("on_enter", "")))


func _resolve_on_enter_named(pi: int, card: Dictionary, effect: String) -> void:
	var foe_pi: int = 1 - pi
	var foe_field: Array = players[foe_pi]["field"]
	var my_field: Array = players[pi]["field"]
	match effect:
		"defensor":
			if fx_enabled:
				# (1.49.93) a Proteção PERMANENTE só aparece 0,5 s após o início
				# da animação defensiva épica (a batalha chama resolve_defensor).
				pending_defensor.append({"uid": int(card["uid"]), "ms": Time.get_ticks_msec()})
				return
			card["shield_turns"] = -1
			log_msg.emit("Defensor: %s recebe Proteção permanente." % card["name"])
		"rajadaCongelante":
			# (1.49.87) MIRA AZUL: o dono escolhe o alvo a congelar (1 rodada)
			_begin_or_resolve_target(pi, card, "rajadaCongelante", int(card["uid"]))
		"corromper":
			# (1.49.79) MIRA ALIADA igual ao Fortalecer: o dono escolhe qual
			# aliado recebe o status SEM HONRA (IA escolhe após 1,6 s).
			_begin_or_resolve_target(pi, card, "corromper", int(card["uid"]))
		"mordidaVenenosa":
			# (1.49.89) MIRA VERDE: o jogador escolhe o inimigo mordido; o veneno
			# (morte em 2 rodadas) é aplicado após a animação (resolve_mordida).
			_begin_or_resolve_target(pi, card, "mordidaVenenosa", int(card["uid"]))
		"gritoDeGuerra":
			# (1.49.89) animada: raios em cascata nos aliados (menos nele mesmo);
			# resolve_furia aplica o status em cada um após o respectivo raio.
			if fx_enabled:
				return
			for c in my_field:
				_apply_furia_now(c)
		"pesadelo":
			if fx_enabled:
				# (1.49.93) o saque bloqueado só é marcado NO FIM da enxurrada de
				# fantasmas (2 s); a batalha chama resolve_pesadelo.
				_pending_pesadelo = {"pi": pi, "foe": foe_pi, "ms": Time.get_ticks_msec()}
				return
			players[foe_pi]["skip_draw"] = true
			log_msg.emit("Pesadelo: %s não comprará carta no próximo turno!" % players[foe_pi]["name"])
		"roubar":
			var fh: Array = players[foe_pi]["hand"]
			if fh.is_empty():
				log_msg.emit("Roubar: o adversário não tem cartas na mão.")
			else:
				var i: int = rng.randi_range(0, fh.size() - 1)
				var stolen: Dictionary = fh[i]
				if not fx_enabled:
					# simulações sem Tela de Combate: roubo imediato (clássico)
					fh.remove_at(i)
					stolen["owner"] = pi
					players[pi]["hand"].append(stolen)
					log_msg.emit("Roubar: %s pegou uma carta da mão adversária!" % players[pi]["name"])
					hand_changed.emit(foe_pi)
					hand_changed.emit(pi)
				else:
					# (1.49.77) o roubo efetivo espera a animação: 0,5 s de
					# atraso + 1,5 s de voo; resolve_roubo no fim do voo.
					var uid: int = int(stolen["uid"])
					pending_roubo.append({"pi": pi, "foe": foe_pi, "uid": uid})
					fx_roubo.emit(pi, foe_pi, uid)
		"desacelerar":
			players[foe_pi]["skip_next_action"] = true
			log_msg.emit("Desacelerar: %s fará 1 ação a menos no próximo turno." % players[foe_pi]["name"])
		"invokeDragon":
			if fx_enabled:
				# (1.49.93) o Filhote só entra quando o OVO choca (burst de luz);
				# a batalha chama resolve_invoke_dragon.
				if my_field.size() >= MAX_FIELD:
					log_msg.emit("Campo cheio: não há espaço para %s." % "FILHOTE DE DRAGÃO")
				else:
					_pending_invoke = {"pi": pi, "ms": Time.get_ticks_msec()}
				return
			_summon_token(pi, "FILHOTE DE DRAGÃO")
		"bolaDeFogo":
			_begin_or_resolve_target(pi, card, "bolaDeFogo", int(card["uid"]))
		"assassinar":
			# (1.50.2) MIRA com ESCOLHA: campeões adversários com Poder 1 ficam
			# destacados (vermelho) e o dono da habilidade ESCOLHE o alvo.
			_begin_or_resolve_target(pi, card, "assassinar", int(card["uid"]))
		"rapidez":
			players[pi]["actions"] += 1
			actions_changed.emit(pi)
			log_msg.emit("Rapidez: +1 ação neste turno!")
		"fortalecer":
			# (1.49.70) MIRA ALIADA: aliados destacados em verde; o +1 só
			# aplica após a animação VFX de 2 s (resolve_fortalecer).
			_begin_or_resolve_target(pi, card, "fortalecer", int(card["uid"]))
		"devorar":
			var allies := my_field.filter(func(c): return int(c["uid"]) != int(card["uid"]))
			var t := _strongest(allies)
			if t.is_empty():
				log_msg.emit("Devorar: nenhum aliado para devorar.")
			else:
				var gained: int = int(t["current_power"])
				log_msg.emit("Devorar: %s devorou %s (+%d Poder)!" % [card["name"], t["name"], gained])
				destroy_champion(pi, t, -1, "devorado", false)
				if _idx_of(players[pi]["field"], int(card["uid"])) >= 0:
					card["current_power"] += gained
		"transformarBichinho":
			_do_transformar_bichinho(pi, foe_pi, foe_field)
		"maldicaoSeteMares":
			players[foe_pi]["curse_next"] = true
			log_msg.emit("Maldição dos Sete Mares: o próximo campeão adversário entra sem habilidade!")
		"imitar":
			var allies := my_field.filter(func(c): return int(c["uid"]) != int(card["uid"]))
			var t := _random_card(allies)
			if t.is_empty():
				log_msg.emit("Imitar: nenhum aliado para copiar.")
			else:
				card["ability_name"] = t.get("ability_name", "")
				card["ability_desc"] = t.get("ability_desc", "")
				card["on_destroy"] = t.get("on_destroy", "")
				card["constant"] = t.get("constant", "")
				var copied: String = String(t.get("on_enter", ""))
				card["on_enter"] = ""
				log_msg.emit("Imitar: %s copiou a habilidade de %s!" % [card["name"], t["name"]])
				if copied != "" and copied != "imitar":
					_resolve_on_enter_named(pi, card, copied)
		"necromancia":
			var disc: Array = players[pi]["discard"]
			if disc.is_empty():
				log_msg.emit("Necromancia: descarte vazio.")
			else:
				var i: int = rng.randi_range(0, disc.size() - 1)
				var back: Dictionary = disc[i]
				disc.remove_at(i)
				players[pi]["hand"].append(back)
				log_msg.emit("Necromancia: %s voltou para a sua mão!" % back["name"])
				hand_changed.emit(pi)
		"trocaInjusta":
			var targets := foe_field.filter(func(c): return int(c["current_power"]) == 2)
			if targets.is_empty():
				log_msg.emit("Troca Injusta: nenhum Campeão P2 adversário.")
			else:
				var t: Dictionary = _random_card(targets)
				_swap_champions(pi, card, foe_pi, t)
		"ursificacao":
			var allies := my_field.filter(func(c): return int(c["uid"]) != int(card["uid"]))
			var t := _strongest(allies)
			if t.is_empty():
				t = card
			t["current_power"] += 2
			log_msg.emit("Ursificação: %s vira um urso gigante e ganha +2 de Poder!" % t["name"])
		"furia":
			# (1.49.89) animada: raio cai 1s após invocar e resolve_furia aplica o
			# status meio segundo depois do impacto. Sem tela de batalha: na hora.
			if fx_enabled:
				return
			_apply_furia_now(card)
		"guardiao":
			if fx_enabled:
				# (1.49.93) pilares de luz UM A UM nos aliados; cada Proteção
				# aparece 0,5 s após o pilar do aliado (resolve_guardiao).
				for c in my_field:
					if int(c.get("uid", -1)) != int(card.get("uid", -2)):
						pending_guardiao.append({"uid": int(c["uid"]), "ms": Time.get_ticks_msec()})
				log_msg.emit("Guardião: seus campeões ganham Proteção por 1 rodada.")
				return
			for c in my_field:
				# (1.49.65) Guardião protege OS OUTROS aliados em campo: quem
				# tem a habilidade NÃO ganha Proteção ao ser invocado.
				if int(c.get("uid", -1)) != int(card.get("uid", -2)):
					_add_shield(c, 1)
			log_msg.emit("Guardião: seus campeões ganham Proteção por 1 rodada.")
		"fumacaToxica":
			if foe_field.is_empty():
				log_msg.emit("Fumaça Tóxica: sem alvos.")
			for c in foe_field:
				c["vulnerable"] = true
			if not foe_field.is_empty():
				log_msg.emit("Fumaça Tóxica: adversários ficam vulneráveis (morrem ao perder Poder)!")
		"auraAntiMagia":
			card["barrier_turns"] = -1
			log_msg.emit("Aura Anti-Magia: %s recebe Barreira permanente." % card["name"])
			sync_views.emit()
		"incendiar":
			var t := _strongest(foe_field)
			if t.is_empty():
				log_msg.emit("Incendiar: sem alvo.")
			else:
				t["burn_turns"] = maxi(int(t["burn_turns"]), 4)
				t["burn_by"] = pi
				log_msg.emit("Incendiar: %s ficará Em Chamas por 4 rodadas!" % t["name"])
		"enfraquecer":
			lose_vp(foe_pi, 1)
			log_msg.emit("Enfraquecer: %s perde 1 PV!" % players[foe_pi]["name"])
		"energizar":
			players[pi]["ult_remaining"] = int(players[pi]["ult_remaining"]) + 1
			log_msg.emit("Energizar: +1 uso de Ultimate nesta partida!")
		"charme":
			if foe_field.is_empty() or my_field.size() >= MAX_FIELD:
				log_msg.emit("Charme: sem alvo ou campo cheio.")
			else:
				var t := _strongest(foe_field)
				var tidx := _idx_of(foe_field, int(t["uid"]))
				foe_field.remove_at(tidx)
				t["charm_turns"] = 2
				t["charm_owner"] = pi
				t["charm_orig_owner"] = foe_pi
				t["owner"] = pi
				t["tapped"] = true
				my_field.append(t)
				log_msg.emit("Charme: %s veio para o seu campo por 2 rodadas!" % t["name"])
				champion_summoned.emit(pi, t)
				field_changed.emit(foe_pi)
				field_changed.emit(pi)
		"podridao":
			_do_podridao(pi, foe_pi)
		"raioDuplo":
			var pool: Array = foe_field.duplicate()
			var hits := 0
			for i in 2:
				var t := _random_card(pool)
				if t.is_empty():
					break
				pool.erase(t)
				hits += 1
				log_msg.emit("Raio Duplo: %s perde 1 de Poder (sem PV)." % t["name"])
				reduce_power(foe_pi, t, 1, pi, false, "raio duplo")
			if hits == 0:
				log_msg.emit("Raio Duplo: sem alvos.")
		"separar":
			var targets := foe_field.filter(func(c): return int(c["current_power"]) == 2)
			if targets.is_empty():
				log_msg.emit("Separar: nenhum Campeão P2 adversário.")
			else:
				var t: Dictionary = _random_card(targets)
				var tidx := _idx_of(foe_field, int(t["uid"]))
				var base_def := {"name": t["name"], "power": 1, "category": "champion", "ability_type": "constant", "ability_name": "Dividido", "ability_desc": "Sem habilidade."}
				foe_field.remove_at(tidx)
				players[foe_pi]["discard"].append(t)
				champion_destroyed.emit(foe_pi, t, "separado", false)
				for i in 2:
					if foe_field.size() >= MAX_FIELD:
						break
					var tok := instantiate_card(base_def, foe_pi)
					tok["silenced"] = true
					foe_field.append(tok)
					champion_summoned.emit(foe_pi, tok)
				log_msg.emit("Separar: %s se dividiu em 2 Campeões P1!" % t["name"])
				field_changed.emit(foe_pi)
		"prisaoPrismatica":
			var t := _strongest(foe_field)
			if t.is_empty():
				log_msg.emit("Prisão Prismática: sem alvo.")
			else:
				t["prision"] = true
				log_msg.emit("Prisão Prismática: atacar com %s custa 2 ações." % t["name"])
		"roletaRussa":
			var all: Array = []
			for q in 2:
				for c in players[q]["field"]:
					all.append({"p": q, "c": c})
			if all.is_empty():
				log_msg.emit("Roleta Russa: campo vazio.")
			else:
				var pick: Dictionary = all[rng.randi_range(0, all.size() - 1)]
				log_msg.emit("Roleta Russa girou... %s foi destruído!" % pick["c"]["name"])
				destroy_champion(int(pick["p"]), pick["c"], -1, "roleta russa", false)
		"forja":
			if players[pi]["deck"].is_empty():
				log_msg.emit("Forja: baralho vazio.")
			else:
				if not fx_enabled:
					draw_cards(pi, 1)
					log_msg.emit("Forja: %s comprou 1 carta como ação livre." % players[pi]["name"])
				else:
					# (1.49.77) 0,5 s depois: martelo na bigorna; o saque
					# livre vem 0,5 s APÓS o fim da animação (resolve_forja).
					pending_forja.append(pi)
					fx_forja.emit(pi, int(card["uid"]))
		"tecnicasDeCombate":
			for c in my_field:
				c["tecnicas_turns"] = maxi(int(c["tecnicas_turns"]), 2)
			log_msg.emit("Técnicas de Combate: aliados vencem empates por 1 rodada.")


func _do_transformar_bichinho(pi: int, foe_pi: int, foe_field: Array) -> void:
	var targets := foe_field.filter(func(c): return int(c["current_power"]) >= 2)
	if targets.is_empty():
		log_msg.emit("Transformar em Bichinho: nenhum alvo P2+.")
		return
	var t: Dictionary = _strongest(targets)
	var old_name: String = t["name"]
	if rng.randf() < 0.8:
		var np: int = maxi(0, int(t["current_power"]) / 2)
		t["name"] = "BICHINHO FOFINHO"
		t["ability_name"] = "Fofura"
		t["ability_desc"] = "Ser fofo é sua principal arma. Sem habilidade."
		t["power"] = np
		t["current_power"] = np
		t["morphed"] = true
		log_msg.emit("Transformar em Bichinho: %s virou um Bichinho Fofinho (P%d)!" % [old_name, np])
	else:
		t["name"] = "O CHEFÃO"
		t["ability_name"] = "Ameaça Iminente"
		t["ability_desc"] = "Gosta de uma boa briga! Sem habilidade."
		t["power"] = int(t["current_power"]) + 1
		t["current_power"] = int(t["power"])
		t["morphed"] = true
		log_msg.emit("Deu errado! %s virou O CHEFÃO (P%d)!" % [old_name, t["power"]])
	for k in ["on_enter", "on_destroy", "constant", "talent_effect"]:
		t[k] = ""
	t["silenced"] = true
	t["frozen_turns"] = 0
	t["poison_turns"] = 0
	t["burn_turns"] = 0
	t["vulnerable"] = false
	champion_morphed.emit(foe_pi, t)


func _swap_champions(pi: int, my_card: Dictionary, foe_pi: int, foe_card: Dictionary) -> void:
	var mf: Array = players[pi]["field"]
	var ff: Array = players[foe_pi]["field"]
	var mi := _idx_of(mf, int(my_card["uid"]))
	var fi := _idx_of(ff, int(foe_card["uid"]))
	if mi < 0 or fi < 0:
		return
	mf.remove_at(mi)
	ff.remove_at(fi)
	my_card["owner"] = foe_pi
	foe_card["owner"] = pi
	my_card["tapped"] = true
	foe_card["tapped"] = true
	ff.append(my_card)
	mf.append(foe_card)
	log_msg.emit("Troca: %s trocou de lado com %s!" % [my_card["name"], foe_card["name"]])
	champion_summoned.emit(pi, foe_card)
	champion_summoned.emit(foe_pi, my_card)
	field_changed.emit(pi)
	field_changed.emit(foe_pi)


func _summon_token(pi: int, token_name: String, free: bool = true) -> bool:
	if players[pi]["field"].size() >= MAX_FIELD:
		log_msg.emit("Campo cheio: não há espaço para %s." % token_name)
		return false
	var defc := CardDB.token_def(token_name)
	if defc.is_empty():
		return false
	var tok := instantiate_card(defc, pi)
	players[pi]["field"].append(tok)
	log_msg.emit("Invocar Dragão: %s entrou em campo como ação livre!" % tok["name"])
	champion_summoned.emit(pi, tok)
	field_changed.emit(pi)
	return true


func _do_podridao(pi: int, foe_pi: int) -> void:
	var deck: Array = players[foe_pi]["deck"]
	if deck.is_empty():
		log_msg.emit("Podridão: baralho adversário vazio.")
		return
	var idxs: Array = range(deck.size())
	_shuffle(idxs)
	var n: int = mini(5, idxs.size())
	for i in n:
		deck[idxs[i]]["podridao"] = true
	log_msg.emit("Podridão: %d cartas do baralho adversário foram contaminadas!" % n)


# ----------------------------------------------------------------------------
# Talentos (arrastar para o campo = usar)
# ----------------------------------------------------------------------------

func _resolve_talent(pi: int, card: Dictionary) -> void:
	var foe_pi: int = 1 - pi
	var foe_field: Array = players[foe_pi]["field"]
	var my_field: Array = players[pi]["field"]
	match String(card.get("talent_effect", "")):
		"bolaDeFogoTalento":
			_begin_or_resolve_target(pi, card, "bolaDeFogoTalento", int(card["uid"]))
		"explosao":
			var t := _strongest(foe_field)
			if t.is_empty():
				log_msg.emit("Explosão: sem alvo.")
			else:
				log_msg.emit("Explosão: %s perde 2 de Poder!" % t["name"])
				reduce_power(foe_pi, t, 2, pi, true, "explosão")
		"zeroAbsoluto":
			# (1.49.87) MIRA AZUL: alvo congela 2 rodadas (ou destrói se já congelado)
			_begin_or_resolve_target(pi, card, "zeroAbsoluto", int(card["uid"]))
		"medoTalento":
			var t := _strongest(foe_field)
			if t.is_empty():
				log_msg.emit("Amedrontar: sem alvo.")
			else:
				var tidx := _idx_of(foe_field, int(t["uid"]))
				foe_field.remove_at(tidx)
				_reset_champion(t)
				if players[foe_pi]["hand"].size() < MAX_HAND:
					t["owner"] = foe_pi
					players[foe_pi]["hand"].append(t)
					log_msg.emit("Amedrontar: %s voltou para a mão do dono!" % t["name"])
					hand_changed.emit(foe_pi)
				else:
					players[foe_pi]["discard"].append(t)
					log_msg.emit("Amedrontar: mão cheia — %s foi exilado!" % t["name"])
				field_changed.emit(foe_pi)
		"bloquearAtaque":
			for c in my_field:
				_add_shield(c, 1)
			log_msg.emit("Bloquear Ataque: seus campeões ganham Proteção por 1 rodada. (Reação simplificada)")
		"protecaoDivina":
			for c in my_field:
				_add_barrier(c, 2)
			log_msg.emit("Proteção Divina: seus campeões ganham Barreira por 2 rodadas. (Reação simplificada)")
		"cancelarUltimate":
			players[foe_pi]["skip_next_action"] = true
			log_msg.emit("Cancelar Ultimate: %s fará 1 ação a menos no próximo turno. (Reação simplificada)" % players[foe_pi]["name"])
		"exaustao":
			var t := _strongest(foe_field)
			if t.is_empty():
				log_msg.emit("Exaustão: sem alvo.")
			else:
				t["silenced"] = true
				log_msg.emit("Exaustão: %s perdeu a habilidade! (Reação simplificada)" % t["name"])
		"contramagica":
			var fh: Array = players[foe_pi]["hand"]
			if fh.is_empty():
				log_msg.emit("Contramágica: o adversário não tem cartas. (Reação simplificada)")
			else:
				var pick := -1
				for i in fh.size():
					if fh[i]["category"] == "talent":
						pick = i
						break
				if pick < 0:
					pick = rng.randi_range(0, fh.size() - 1)
				var gone: Dictionary = fh[pick]
				fh.remove_at(pick)
				players[foe_pi]["discard"].append(gone)
				log_msg.emit("Contramágica: %s do adversário foi descartada! (Reação simplificada)" % gone["name"])
				hand_changed.emit(foe_pi)
		"fortalecerTalento":
			# (1.49.70) mesma mira aliada + VFX de 2 s do Fortalecer
			_begin_or_resolve_target(pi, card, "fortalecerTalento", int(card["uid"]))
		"doppelganger":
			var targets := my_field.filter(func(c): return int(c["current_power"]) == 2)
			if targets.is_empty() or my_field.size() >= MAX_FIELD:
				log_msg.emit("Duplicar: sem aliado P2 ou campo cheio.")
			else:
				var t: Dictionary = _random_card(targets)
				var base_def := {"name": t["name"], "power": 2, "category": "champion", "ability_type": t.get("ability_type", ""), "ability_name": t.get("ability_name", ""), "ability_desc": t.get("ability_desc", "")}
				var copy := instantiate_card(base_def, pi)
				copy["silenced"] = true
				copy["ability_name"] = "Cópia"
				copy["ability_desc"] = "Duplicado por Duplicar. Sem habilidade."
				my_field.append(copy)
				log_msg.emit("Duplicar: uma cópia de %s entrou em campo!" % t["name"])
				champion_summoned.emit(pi, copy)
				field_changed.emit(pi)
		"barreira":
			for c in my_field:
				_add_barrier(c, 2)
			log_msg.emit("Barreira: todos os seus campeões bloqueiam redução de Poder por 2 rodadas.")
			sync_views.emit()
		"baforadaVenenosa":
			# (1.49.92) MIRA VERDE-VENENO: o dono escolhe o Campeão adversário
			# que receberá a BAFORADA DO DRAGÃO VERDE (texto da carta: "Escolha
			# um Campeão"); a IA escolhe após 1,6 s; simulações, no mais forte.
			_begin_or_resolve_target(pi, card, "baforadaVenenosa", int(card["uid"]))
		"aceleracao":
			players[pi]["actions"] += 1
			actions_changed.emit(pi)
			log_msg.emit("Aceleração: +1 ação neste turno!")
		"missemagicos":
			if foe_field.is_empty():
				log_msg.emit("Mísseis Mágicos: sem alvos.")
			for c in foe_field.duplicate():
				if _idx_of(foe_field, int(c["uid"])) < 0:
					continue
				if rng.randf() < 0.6:
					log_msg.emit("Mísseis Mágicos acertou %s (-1 Poder)." % c["name"])
					reduce_power(foe_pi, c, 1, pi, true, "mísseis mágicos")
				else:
					log_msg.emit("Mísseis Mágicos errou %s." % c["name"])
		"arsenalDeGuerra":
			draw_cards(pi, 2)
			log_msg.emit("Arsenal de Guerra: 2 cartas compradas como ação livre!")
		"investidaTalento":
			var t := _strongest(my_field)
			if t.is_empty():
				log_msg.emit("Investida: nenhum aliado.")
			else:
				t["free_attack"] = true
				t["tapped"] = false
				log_msg.emit("Investida: %s pode atacar como ação livre!" % t["name"])
		"gritoDeGuerraTalento":
			# (1.49.89) animada (mesma orquestração do Grito de Guerra campeão).
			if fx_enabled:
				return
			for c in my_field:
				_apply_furia_now(c)
		"prisaoPrismaticaTalento":
			var t := _strongest(foe_field)
			if t.is_empty():
				log_msg.emit("Prisão Prismática: sem alvo.")
			else:
				t["prision"] = true
				log_msg.emit("Prisão Prismática: atacar com %s custa 2 ações." % t["name"])
		"tornadoDeFogo":
			var t := _strongest(foe_field)
			if t.is_empty():
				log_msg.emit("Tornado de Fogo: sem alvo.")
			else:
				t["burn_turns"] = maxi(int(t["burn_turns"]), 4)
				t["burn_by"] = pi
				log_msg.emit("Tornado de Fogo: %s perde 1 de Poder por rodada!" % t["name"])
		"maldicaoSeteMaresTalento":
			players[foe_pi]["curse_next"] = true
			log_msg.emit("Maldição dos Sete Mares: o próximo campeão adversário entra sem habilidade!")
		"trocaDeLugar":
			var mine := my_field.filter(func(c): return int(c["current_power"]) == 1)
			var theirs := foe_field.filter(func(c): return int(c["current_power"]) == 2)
			if mine.is_empty() or theirs.is_empty():
				log_msg.emit("Troca de Lugar: sem par válido (você P1 x adversário P2).")
			else:
				_swap_champions(pi, _random_card(mine), foe_pi, _random_card(theirs))
		"tecnicasDeCombateTalento":
			for c in my_field:
				c["tecnicas_turns"] = maxi(int(c["tecnicas_turns"]), 2)
			log_msg.emit("Técnicas de Combate: aliados vencem empates por 1 rodada.")
		"podridaoTalento":
			_do_podridao(pi, foe_pi)
		"apodrecidaDescarte":
			log_msg.emit("Carta Apodrecida descartada.")
		"ressuscitarTalento":
			var disc: Array = players[pi]["discard"]
			var cand := disc.filter(func(c): return c["category"] == "champion" and int(c.get("power", 0)) == 2)
			if cand.is_empty() or my_field.size() >= MAX_FIELD:
				log_msg.emit("Ressuscitar: sem Campeão P2 no descarte ou campo cheio.")
			else:
				var t: Dictionary = cand[cand.size() - 1]
				disc.erase(t)
				_reset_champion(t)
				t["owner"] = pi
				my_field.append(t)
				log_msg.emit("Ressuscitar: %s voltou ao campo!" % t["name"])
				champion_summoned.emit(pi, t)
				field_changed.emit(pi)
		"corromperTalento":
			# (1.49.79) mesma mira aliada do Corromper
			_begin_or_resolve_target(pi, card, "corromperTalento", int(card["uid"]))
		"chuvaDeCometas":
			for q in 2:
				for c in players[q]["field"].duplicate():
					if _idx_of(players[q]["field"], int(c["uid"])) < 0:
						continue
					log_msg.emit("Chuva de Cometas atingiu %s (-1 Poder)." % c["name"])
					reduce_power(q, c, 1, pi if q != pi else -1, q != pi, "chuva de cometas")
		"transformarBichinhoTalento":
			_do_transformar_bichinho(pi, foe_pi, foe_field)
		"desacelerarTalento":
			players[foe_pi]["skip_next_action"] = true
			log_msg.emit("Desacelerar: %s fará 1 ação a menos no próximo turno." % players[foe_pi]["name"])
		"enfraquecerTalento":
			lose_vp(foe_pi, 1)
			log_msg.emit("Enfraquecer: %s perde 1 PV!" % players[foe_pi]["name"])
		"invocarDragaoTalento":
			if fx_enabled:
				# (1.49.93) mesmo ovo chocando do Campeão com Invocar Dragão.
				if my_field.size() >= MAX_FIELD:
					log_msg.emit("Campo cheio: não há espaço para %s." % "FILHOTE DE DRAGÃO")
				else:
					_pending_invoke = {"pi": pi, "ms": Time.get_ticks_msec()}
				return
			_summon_token(pi, "FILHOTE DE DRAGÃO")
		_:
			log_msg.emit("%s: efeito ainda não implementado neste protótipo." % card["name"])


func _reset_champion(t: Dictionary) -> void:
	t["current_power"] = int(t.get("power", 0))
	t["tapped"] = false
	t["frozen_turns"] = 0
	t["shield_turns"] = 0
	t["barrier_turns"] = 0
	t["poison_turns"] = 0
	t["burn_turns"] = 0
	t["fury_stacks"] = 0
	t["fury_turns"] = 0
	t["tecnicas_turns"] = 0
	t["vulnerable"] = false
	t["prision"] = false
	t["free_attack"] = false
	t["charm_turns"] = 0
	t["charm_owner"] = -1
	t["wall_buff"] = 0
	t["desafiante_buff"] = 0
	t["inspirar_buff"] = 0


# ----------------------------------------------------------------------------
# Consultas para a UI / IA
# ----------------------------------------------------------------------------

func is_active() -> bool:
	return winner == -1


func started_ok() -> bool:
	return players.size() == 2


func is_my_turn(pi: int) -> bool:
	return current == pi and winner == -1


func can_attack_any(pi: int) -> bool:
	for ai in players[pi]["field"].size():
		for di in players[1 - pi]["field"].size():
			if can_attack(pi, ai, di)["ok"]:
				return true
	return false


func any_playable(pi: int) -> bool:
	for hi in players[pi]["hand"].size():
		if can_play(pi, hi)["ok"]:
			return true
	return false
