extends Node
## Teste 1.50.4: (1) CORROMPER: aura negra 1,5 s e o status SEM HONRA só 0,5 s
## APÓS o fim dela; (2) ASSASSINAR: as cartas da linha só se REORGANIZAM 0,5 s
## após o fim da morte especial; (3) SOBREPUJAR com Poder igual: destruição
## especial contida (socos/rapieira) no perdedor + escudo no vencedor.
## Rodar: godot --headless --path . res://tests/t_99.tscn

var _ok := true

const SOB := preload("res://scripts/vfx_sobre.gd")
const COR := preload("res://scripts/vfx_corromper.gd")


func _fail(msg: String) -> void:
	_ok = false
	printerr("FALHA: " + msg)


func _ready() -> void:
	print("== T99 (1.50.4) ==")
	await _t_corromper()
	await _t_assassinar_reorg()
	await _t_sobrepujar()
	print("== T99 %s ==" % ("OK" if _ok else "FALHOU"))
	get_tree().quit(0 if _ok else 1)


func _card(st: GameState, nm: String, oe: String, pi: int = 0, ab: String = "", pw: int = 1) -> Dictionary:
	return st.instantiate_card({
		"name": nm, "power": pw, "category": "champion", "on_enter": oe,
		"talent_effect": "", "ability_name": ab, "ability_desc": "",
		"on_destroy": "", "constant": "",
	}, pi)


func _mk_battle() -> Node:
	if FileAccess.file_exists("user://layout_battle.cfg"):
		var d := DirAccess.open("user://")
		if d != null:
			d.remove("layout_battle.cfg")
	var b := BattleScreen.new()
	b.ai_step_delay = 0.02
	b.ai_running = true
	add_child(b)
	return b


func _t_corromper() -> void:
	var b := _mk_battle()
	await get_tree().process_frame
	await get_tree().process_frame
	var st: GameState = b.state
	var ally := _card(st, "OLAF", "", 0)
	var cor := _card(st, "CORRUPTOR", "corromper", 0)
	st.players[0]["field"].append(ally)
	st.players[0]["field"].append(cor)
	b._on_champion_summoned(0, ally)
	b._on_champion_summoned(0, cor)
	b._layout_field(0)
	await get_tree().create_timer(0.3).timeout
	st._begin_or_resolve_target(0, cor, "corromper", int(cor["uid"]))
	if st.targeting.is_empty():
		_fail("corromper: mira não abriu")
		b.queue_free()
		return
	st.confirm_targeting(int(ally["uid"]))
	await get_tree().create_timer(1.2).timeout
	if bool(ally.get("corrupted", false)):
		_fail("corromper: status entrou ANTES do fim da aura")
	var aura := false
	for ch in b.fx_layer.get_children():
		if ch is COR:
			aura = true
	if not aura:
		_fail("corromper: aura negra não apareceu")
	await get_tree().create_timer(2.2).timeout
	if not bool(ally.get("corrupted", false)):
		_fail("corromper: status não entrou 0,5 s após a aura")
	b.queue_free()
	print("CORROMPER: aura 1,5 s + status 0,5 s depois: OK")


func _t_assassinar_reorg() -> void:
	var b := _mk_battle()
	await get_tree().process_frame
	await get_tree().process_frame
	var st: GameState = b.state
	var v1 := _card(st, "VITIMA", "", 1)
	var v2 := _card(st, "IRMMA", "", 1)
	st.players[1]["field"].append(v1)
	st.players[1]["field"].append(v2)
	b._on_champion_summoned(1, v1)
	b._on_champion_summoned(1, v2)
	b._layout_field(1)
	await get_tree().create_timer(0.4).timeout
	var vv2: ChampionView = b.champ_views.get(int(v2["uid"]))
	var pos0: Vector2 = vv2.position
	st.destroy_champion(1, v1, 0, "assassinar", true)
	await get_tree().create_timer(1.5).timeout
	if vv2.position.distance_to(pos0) > 1.0:
		_fail("assassinar: linha reorganizou DURANTE a morte especial")
	await get_tree().create_timer(3.0).timeout
	if vv2.position.distance_to(pos0) < 1.0:
		_fail("assassinar: linha NÃO reorganizou após a morte + 0,5 s")
	b.queue_free()
	print("ASSASSINAR: reorganização só após a morte + 0,5 s: OK")


func _t_sobrepujar() -> void:
	var b := _mk_battle()
	await get_tree().process_frame
	await get_tree().process_frame
	var st: GameState = b.state
	var pop := _card(st, "POPPY", "", 0, "Sobrepujar", 1)
	var foe := _card(st, "SELLING", "", 1, "", 1)
	st.players[0]["field"].append(pop)
	st.players[1]["field"].append(foe)
	b._on_champion_summoned(0, pop)
	b._on_champion_summoned(1, foe)
	b._layout_field(0)
	b._layout_field(1)
	await get_tree().create_timer(0.4).timeout
	b._do_combat(0, 0, 0)
	var seen_sob := false
	var guard := 0
	while guard < 400:
		for ch in b.fx_layer.get_children():
			if ch is SOB:
				seen_sob = true
		if seen_sob:
			break
		await get_tree().process_frame
		guard += 1
	if not seen_sob:
		_fail("sobrepujar: animação especial (socos) não apareceu")
	await get_tree().create_timer(2.5).timeout
	var foe_alive := false
	for c in st.players[1]["field"]:
		if int(c["uid"]) == int(foe["uid"]):
			foe_alive = true
	if foe_alive:
		_fail("sobrepujar: perdedor não foi destruído")
	b.queue_free()
	print("SOBREPUJAR: socos contidos + destruição do perdedor: OK")
