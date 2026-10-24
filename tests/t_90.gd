extends Node
## Teste 1.49.90: portas de VFX da 1.49.89 (Mordida Venenosa e Fúria só aplicam
## o status DEPOIS da animação) + padrões de texto (lh 0.88, centralizado).
## Rodar: godot --headless --path . res://tests/t_90.tscn

var _ok := true


func _fail(msg: String) -> void:
	_ok = false
	printerr("FALHA: " + msg)


func _ready() -> void:
	print("== T90 (1.49.90) ==")
	_t_mordida(true)
	_t_mordida(false)
	_t_furia(true)
	_t_furia(false)
	_t_texto()
	print("== T90 %s ==" % ("OK" if _ok else "FALHOU"))
	get_tree().quit(0 if _ok else 1)


func _deck_with(first: String) -> Array:
	var names: Array = [first]
	for d in CardDB.playable_defs():
		if names.size() >= 10:
			break
		var nm := String(d["name"])
		if not names.has(nm):
			names.append(nm)
	return names


func _new_state(fx: bool, need: String) -> GameState:
	var st := GameState.new()
	st.auto_target = false
	st.fx_enabled = fx
	st.setup(CardDB.HEROES[0], CardDB.HEROES[1], {"deck_a": _deck_with(need), "deck_b": _deck_with("VIPER")})
	return st


func _move_to_hand(st: GameState, pi: int, cname: String) -> int:
	for i in st.players[pi]["hand"].size():
		if String(st.players[pi]["hand"][i]["name"]) == cname:
			return i
	for i in st.players[pi]["deck"].size():
		if String(st.players[pi]["deck"][i]["name"]) == cname:
			st.players[pi]["hand"].append(st.players[pi]["deck"].pop_at(i))
			return st.players[pi]["hand"].size() - 1
	_fail("carta " + cname + " nao achada no deck")
	return -1


func _put_enemy(st: GameState, pi: int) -> Dictionary:
	for i in st.players[1 - pi]["deck"].size():
		if String(st.players[1 - pi]["deck"][i]["category"]) == "champion":
			var c: Dictionary = st.players[1 - pi]["deck"].pop_at(i)
			st.players[1 - pi]["field"].append(c)
			return c
	_fail("sem campeao inimigo p/ colocar em campo")
	return {}


func _t_mordida(fx: bool) -> void:
	var st := _new_state(fx, "MANDAGORA")
	var hi := _move_to_hand(st, 0, "MANDAGORA")
	var enemy := _put_enemy(st, 0)
	if hi < 0 or enemy.is_empty():
		return
	var euid: int = int(enemy["uid"])
	var fx_hits := [0]
	st.fx_mordida.connect(func(_a, _b, _c): fx_hits[0] += 1)
	var played: bool = st.play_card(0, hi)
	if not played:
		_fail("mordida: play_card falhou")
		return
	if st.targeting.is_empty():
		_fail("mordida: mira nao abriu")
		return
	st.confirm_targeting(euid)
	var pois_agora: int = int(enemy.get("poison_turns", 0))
	if fx:
		if fx_hits[0] != 1:
			_fail("mordida fx: fx_mordida nao emitido")
		if pois_agora != 0:
			_fail("mordida fx: veneno aplicado ANTES da animacao")
		st.resolve_mordida(euid)
		if int(enemy.get("poison_turns", 0)) != 2:
			_fail("mordida fx: resolve_mordida nao aplicou veneno")
		else:
			print("mordida fx: porta OK (veneno apos animacao)")
	else:
		if pois_agora != 2:
			_fail("mordida sim: veneno nao aplicado na hora")
		else:
			print("mordida sim: imediato OK")


func _t_furia(fx: bool) -> void:
	var st := _new_state(fx, "OLAF")
	var hi := _move_to_hand(st, 0, "OLAF")
	if hi < 0:
		return
	var pow0: int = 2
	var played: bool = st.play_card(0, hi)
	if not played:
		_fail("furia: play_card falhou")
		return
	var card: Dictionary = st.players[0]["field"].back()
	var u: int = int(card["uid"])
	if fx:
		if int(card["fury_stacks"]) != 0 or int(card["current_power"]) != pow0:
			_fail("furia fx: status aplicado ANTES do raio")
		st.resolve_furia(u)
		if int(card["fury_stacks"]) != 1 or int(card["current_power"]) != pow0 + 1:
			_fail("furia fx: resolve_furia nao aplicou")
		else:
			print("furia fx: porta OK (status apos raio)")
	else:
		if int(card["fury_stacks"]) != 1 or int(card["current_power"]) != pow0 + 1:
			_fail("furia sim: status nao imediato")
		else:
			print("furia sim: imediato OK")


func _t_texto() -> void:
	var la: Dictionary = CardArt.layout_for(CardDB.HEROES[0], 300.0, 420.0)
	if abs(float(la.get("desc_lh", 0.0)) - 0.88) > 0.001:
		_fail("desc_lh != 0.88 (%s)" % str(la.get("desc_lh", 0.0)))
		return
	if not bool(la.get("desc_center", false)):
		_fail("desc_center != true")
		return
	print("texto: lh 0.88 + centralizado OK")
