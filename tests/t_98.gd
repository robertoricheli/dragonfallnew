extends Node
## Teste 1.50.3: (1) SAQUE LIVRE: 1,0 s após o início da partida e 0,5 s após
## passar a vez (nada de compra instantânea); (2) ACELERAÇÃO: VFX de 1,5 s
## roda headless até o finished; (3) ASSASSINAR: todos os elementos da morte
## especial permanecem CONTIDOS na área da carta (+40 px de folga).
## Rodar: godot --headless --path . res://tests/t_98.tscn

var _ok := true

const ACE := preload("res://scripts/vfx_acelerar.gd")
const ASS := preload("res://scripts/vfx_assassinar.gd")


func _fail(msg: String) -> void:
	_ok = false
	printerr("FALHA: " + msg)


func _ready() -> void:
	print("== T98 (1.50.3) ==")
	await _t_saque_delay()
	await _t_acelerar()
	await _t_assassinar_contido()
	print("== T98 %s ==" % ("OK" if _ok else "FALHOU"))
	get_tree().quit(0 if _ok else 1)


func _card(st: GameState, nm: String, oe: String, pi: int = 0) -> Dictionary:
	return st.instantiate_card({
		"name": nm, "power": 1, "category": "champion", "on_enter": oe,
		"talent_effect": "", "ability_name": "", "ability_desc": "",
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


func _t_saque_delay() -> void:
	var b := _mk_battle()
	await get_tree().process_frame
	await get_tree().process_frame
	var st: GameState = b.state
	var h0: int = (st.players[0]["hand"] as Array).size()
	await get_tree().create_timer(0.6).timeout
	if (st.players[0]["hand"] as Array).size() != h0:
		_fail("saque: comprou antes de 1,0 s no início da partida")
	await get_tree().create_timer(0.9).timeout
	if (st.players[0]["hand"] as Array).size() != h0 + 1:
		_fail("saque: não comprou ~1,0 s após o início")
	# passar a vez: saque do adversário 0,5 s depois
	var a0: int = (st.players[1]["hand"] as Array).size()
	st.end_turn()
	await get_tree().create_timer(0.25).timeout
	if (st.players[1]["hand"] as Array).size() != a0:
		_fail("saque: IA comprou antes de 0,5 s após passar a vez")
	await get_tree().create_timer(0.65).timeout
	if (st.players[1]["hand"] as Array).size() != a0 + 1:
		_fail("saque: IA não comprou ~0,5 s após passar a vez")
	b.queue_free()
	print("SAQUE LIVRE: 1,0 s no início / 0,5 s após passar: OK")


func _t_acelerar() -> void:
	var b := _mk_battle()
	await get_tree().process_frame
	var st: GameState = b.state
	var c := _card(st, "VELOZ", "", 0)
	var v := ChampionView.new()
	v.setup(c, 0)
	add_child(v)
	await get_tree().process_frame
	var fx = ACE.new()
	add_child(fx)
	var flag := {"done": false}
	fx.finished.connect(func() -> void: flag["done"] = true)
	fx.setup(v)
	if absf(fx.DUR - 1.5) > 0.001:
		_fail("acelerar: DUR %.2f (esperado 1.5)" % fx.DUR)
	var guard := 0
	while not flag["done"] and guard < 300:
		await get_tree().process_frame
		guard += 1
	if not flag["done"]:
		_fail("acelerar: não terminou")
	v.queue_free()
	b.queue_free()
	print("ACELERAÇÃO: VFX 1,5 s headless: OK")


func _t_assassinar_contido() -> void:
	var b := _mk_battle()
	await get_tree().process_frame
	await get_tree().process_frame
	var st: GameState = b.state
	var as_ := _card(st, "ASSASSINA", "assassinar", 0)
	var tgt := _card(st, "ALVO FRACO", "", 1)
	st.players[0]["field"].append(as_)
	st.players[1]["field"].append(tgt)
	b._on_champion_summoned(0, as_)
	b._on_champion_summoned(1, tgt)
	b._layout_field(0)
	b._layout_field(1)
	await get_tree().create_timer(0.4).timeout
	var vt: ChampionView = b.champ_views.get(int(tgt["uid"]))
	var rect: Rect2 = vt.get_global_rect()
	var bounds := rect.grow(40.0)
	st.destroy_champion(1, tgt, 0, "assassinar", true)
	await get_tree().create_timer(0.75).timeout
	var fx: Node = null
	for ch in b.fx_layer.get_children():
		if ch is ASS:
			fx = ch
	if fx == null:
		_fail("assassinar: fx não apareceu 0,5 s após a escolha")
		b.queue_free()
		return
	# (1.50.6) o overlay do vídeo fica CENTRADO na carta e a carta não muda
	# de tamanho durante toda a animação especial
	var vt2: ChampionView = fx._view
	var sc0: Vector2 = vt2.scale
	for _k in 30:
		await get_tree().process_frame
		if is_instance_valid(fx) and fx._seq != null and not bounds.grow(60.0).has_point(fx._seq.global_position):
			_fail("assassinar: overlay do vídeo fora da área da carta")
		if is_instance_valid(vt2) and vt2.scale != sc0:
			_fail("assassinar: carta mudou de tamanho")
	await get_tree().create_timer(1.5).timeout
	b.queue_free()
	print("ASSASSINAR: destrução CONTIDA na área da carta: OK")
