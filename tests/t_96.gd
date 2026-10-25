extends Node
## Teste 1.49.98: (1) ÁUDIO: autoload Sfx presente com os 22 sons carregados e
## play() seguro headless em todas as chaves; (2) OVO: ao começar a animação,
## a linha abre o slot do Filhote ANTES (quem está na linha desliza para os
## slots de uma linha de n+1) e o ovo fica a >= 100 px do campeão que usou
## (nunca sobre a carta); (3) DEFENSOR: o 2º círculo (runas) fica no CENTRO
## da carta (0,0), enquanto o domo/aro ao redor da carta não mudam.
## Rodar: godot --headless --path . res://tests/t_96.tscn

var _ok := true


func _fail(msg: String) -> void:
	_ok = false
	printerr("FALHA: " + msg)


func _ready() -> void:
	print("== T96 (1.49.98) ==")
	_t_sfx()
	await _t_ovo_slot_livre()
	_t_defensor_centro()
	print("== T96 %s ==" % ("OK" if _ok else "FALHOU"))
	get_tree().quit(0 if _ok else 1)


func _t_sfx() -> void:
	var sfx := get_node_or_null("/root/Sfx")
	if sfx == null:
		_fail("autoload Sfx ausente")
		return
	if (sfx.KEYS as Dictionary).size() != 25:
		_fail("Sfx: %d chaves (esperado 25)" % (sfx.KEYS as Dictionary).size())
	for k in sfx.KEYS:
		if sfx._streams.get(k) == null:
			_fail("Sfx: stream não carregado: %s" % k)
		sfx.play(k, 640.0, 0.5)   # headless: não deve crashar
	print("SFX: 25 sons carregados e play() seguro: OK")


func _t_ovo_slot_livre() -> void:
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
	var wy := st.instantiate_card({
		"name": "WYVERN", "power": 1, "category": "champion", "on_enter": "invokeDragon",
		"talent_effect": "", "ability_name": "", "ability_desc": "",
		"on_destroy": "", "constant": "",
	}, 0)
	st.players[0]["field"].append(wy)
	st._resolve_on_enter_named(0, wy, "invokeDragon")
	b._on_champion_summoned(0, wy)
	b._layout_field(0)
	# ovo começa 0,5 s após o pouso (+queda): espera 1,2 s e mede
	await get_tree().create_timer(1.2).timeout
	var vc: ChampionView = b.champ_views.get(int(wy["uid"]))
	var egg: Node2D = null
	for ch in b.fx_layer.get_children():
		if ch.get_script() != null and String(ch.get_script().resource_path).ends_with("vfx_ovo.gd"):
			egg = ch
	if egg == null:
		_fail("ovo: fx não encontrado")
		b.queue_free()
		return
	var caster_x: float = vc.global_position.x + vc.size.x / 2.0
	var dist := absf(egg.position.x - caster_x)
	if dist < 100.0:
		_fail("ovo: a %.0f px do caster (< 100 = encosta/sobre a carta)" % dist)
	# o caster já deve estar no slot 0 de uma linha de 2
	var want := b._slot_for(0, 0, 2)
	if vc.position.distance_to(want) > 2.0:
		_fail("ovo: linha não abriu o slot (caster em %s, esperado %s)" % [str(vc.position), str(want)])
	b.queue_free()
	print("OVO: slot livre antes do ovo (%.0f px do caster): OK" % dist)


func _t_defensor_centro() -> void:
	var fx = load("res://scripts/vfx_defensor.gd").new()
	add_child(fx)
	fx.setup(Vector2(640, 473))
	await get_tree().process_frame
	if fx._rune.position != Vector2.ZERO:
		_fail("defensor: runa 1 em %s (esperado centro 0,0)" % str(fx._rune.position))
	if fx._rune2.position != Vector2.ZERO:
		_fail("defensor: runa 2 em %s (esperado centro 0,0)" % str(fx._rune2.position))
	if fx._rim.position != Vector2.ZERO:
		_fail("defensor: aro ao redor da carta mudou (%s)" % str(fx._rim.position))
	fx.queue_free()
	print("DEFENSOR: 2º círculo no centro da carta (aro intacto): OK")
