extends Node
## Teste 1.50.5: (1) BOLHAS: ao trigger, TODOS os campeões da mão adversária
## ganham o status; bolhas em loop sobre o herói afetado após o cone; o 1º
## campeão invocado entra SILENCIADO e com BOLHAS, os demais perdem o status
## e as bolhas do herói somem; (2) RAPIDEZ gera a animação de velocidade
## ~1 s após o pouso; (3) central Sfx com 31 chaves.
## Rodar: godot --headless --path . res://tests/t_100.tscn

var _ok := true


func _fail(msg: String) -> void:
	_ok = false
	printerr("FALHA: " + msg)


func _ready() -> void:
	print("== T100 (1.50.5) ==")
	_t_sfx31()
	await _t_bolhas()
	await _t_rapidez()
	print("== T100 %s ==" % ("OK" if _ok else "FALHOU"))
	get_tree().quit(0 if _ok else 1)


func _t_sfx31() -> void:
	var sfx := get_node_or_null("/root/Sfx")
	if sfx == null or (sfx.KEYS as Dictionary).size() != 31:
		_fail("Sfx: %d chaves (esperado 31)" % (0 if sfx == null else (sfx.KEYS as Dictionary).size()))
	elif sfx._streams.get("bolhas") == null:
		_fail("Sfx: som bolhas ausente")
	else:
		print("SFX: 31 chaves (bolhas inclusa): OK")


func _card(st: GameState, nm: String, oe: String, pi: int = 0) -> Dictionary:
	return st.instantiate_card({
		"name": nm, "power": 1, "category": "champion", "on_enter": oe,
		"talent_effect": "", "ability_name": "", "ability_desc": "",
		"on_destroy": "", "constant": "",
	}, pi)


func _t_bolhas() -> void:
	if FileAccess.file_exists("user://layout_battle.cfg"):
		var d := DirAccess.open("user://")
		if d != null:
			d.remove("layout_battle.cfg")
	var b := BattleScreen.new()
	b.ai_step_delay = 0.02
	b.ai_running = true
	add_child(b)
	await get_tree().process_frame
	await get_tree().process_frame
	var st: GameState = b.state
	# garante 2 campeões na mão da IA
	var h1 := _card(st, "ALVO UM", "", 1)
	var h2 := _card(st, "ALVO DOIS", "", 1)
	st.players[1]["hand"].append(h1)
	st.players[1]["hand"].append(h2)
	# campeã com BOLHAS entra no campo do jogador
	var oc := _card(st, "Oceana", "bolhas", 0)
	st.players[0]["field"].append(oc)
	st._resolve_on_enter_named(0, oc, "bolhas")
	b._on_champion_summoned(0, oc)
	b._layout_field(0)
	if not bool(h1.get("bolhas", false)) or not bool(h2.get("bolhas", false)):
		_fail("bolhas: mão adversária não marcou TODOS os campeões")
	# cone + loop no herói
	await get_tree().create_timer(2.4).timeout
	if b._bolhas_hero_pi != 1:
		_fail("bolhas: loop de bolhas não ligou sobre o herói afetado")
	# IA invoca o 1º campeão com bolhas: entra silenciado e segura o status;
	# os demais perdem; as bolhas do herói somem
	var idx: int = (st.players[1]["hand"] as Array).find(h1)
	st.current = 1                      # teste dirige a invocação diretamente
	st.players[1]["actions"] = 2
	if not st.play_card(1, idx, -1):
		_fail("bolhas: play_card do 1º campeão com bolhas falhou")
	if not bool(h1.get("silenced", false)):
		_fail("bolhas: 1º invocado NÃO entrou sem habilidade")
	if not bool(h1.get("bolhas", false)):
		_fail("bolhas: 1º invocado perdeu o próprio status")
	if bool(h2.get("bolhas", false)):
		_fail("bolhas: demais da mão mantiveram o status")
	await get_tree().create_timer(0.4).timeout
	if b._bolhas_hero_pi != -1:
		_fail("bolhas: loop do herói não sumiu após o 1º invocado")
	b.queue_free()
	print("BOLHAS: mão marcada -> 1º sem habilidade -> herói limpo: OK")


func _t_rapidez() -> void:
	if FileAccess.file_exists("user://layout_battle.cfg"):
		var d := DirAccess.open("user://")
		if d != null:
			d.remove("layout_battle.cfg")
	var b := BattleScreen.new()
	b.ai_step_delay = 0.02
	b.ai_running = true
	add_child(b)
	await get_tree().process_frame
	await get_tree().process_frame
	var st: GameState = b.state
	var g := _card(st, "GAROU TESTE", "rapidez", 0)
	st.players[0]["field"].append(g)
	b._on_champion_summoned(0, g)
	b._layout_field(0)
	var seen := false
	var guard := 0
	while guard < 260:
		for ch in b.fx_layer.get_children():
			if ch.get_script() != null and String(ch.get_script().resource_path).ends_with("vfx_acelerar.gd"):
				seen = true
		if seen:
			break
		await get_tree().process_frame
		guard += 1
	if not seen:
		_fail("rapidez: animação de velocidade não apareceu ~1 s após o pouso")
	b.queue_free()
	print("RAPIDEZ: animação de velocidade 1,5 s: OK")
