extends Node
## Teste 1.49.95: (1) OVO: sequencia de 20 frames contida no SLOT (altura =
## carta 140 px, largura <= 175 px, nada de elemento > 200 px de tela);
## (2) MORDIDA: serpente NUNCA maior que uma carta (<= 140 px) durante TODO o
## voo, duracao 2,0 s, e na Tela de Combate ela nasce da carta de origem e
## morde o alvo (veneno aplicado no fim); (3) RELOGIO DESACELERAR: 20 frames,
## UM POUCO MAIOR que a carta (150..190 px de altura) e contido na linha
## adversaria; os tres rodam headless ate o finished (e burst do ovo).
## Rodar: godot --headless --path . res://tests/t_95.tscn

var _ok := true

const OVO := preload("res://scripts/vfx_ovo.gd")
const MOR := preload("res://scripts/vfx_mordida.gd")
const DES := preload("res://scripts/vfx_desacelerar.gd")


func _fail(msg: String) -> void:
	_ok = false
	printerr("FALHA: " + msg)


func _ready() -> void:
	print("== T95 (1.49.95) ==")
	await _t_ovo_slot()
	await _t_mordida_tamanho()
	await _t_relogio_tamanho()
	await _t_battle_mordida()
	print("== T95 %s ==" % ("OK" if _ok else "FALHOU"))
	get_tree().quit(0 if _ok else 1)


func _card(st: GameState, nm: String, oe: String, pi: int = 0) -> Dictionary:
	return st.instantiate_card({
		"name": nm, "power": 1, "category": "champion", "on_enter": oe,
		"talent_effect": "", "ability_name": "", "ability_desc": "",
		"on_destroy": "", "constant": "",
	}, pi)


func _t_ovo_slot() -> void:
	var fx = OVO.new()
	add_child(fx)
	var flag := {"done": false, "burst": false}
	fx.finished.connect(func() -> void: flag["done"] = true)
	fx.burst.connect(func() -> void: flag["burst"] = true)
	fx.setup(Vector2(640, 473))
	if fx.FRAMES.size() != 20:
		_fail("ovo: %d frames (esperado 20)" % fx.FRAMES.size())
	# medidas contidas no slot
	var tw: float = fx.FRAMES[0].get_width() * fx.SCALE
	var th: float = fx.FRAMES[0].get_height() * fx.SCALE
	if absf(th - 140.0) > 2.0:
		_fail("ovo: altura %.0f px (esperado ~140 = carta)" % th)
	if tw > 175.0:
		_fail("ovo: largura %.0f px (> 175)" % tw)
	var t0 := Time.get_ticks_msec()
	var max_flash := 0.0
	while not flag["done"] and Time.get_ticks_msec() - t0 < 4000:
		await get_tree().process_frame
		if is_instance_valid(fx):
			max_flash = maxf(max_flash, 150.0 * fx._flash.scale.x)
	if not flag["done"]:
		_fail("ovo: não terminou")
	if not flag["burst"]:
		_fail("ovo: não emitiu burst")
	if max_flash > 200.0:
		_fail("ovo: clarão de %.0f px vaza do slot (>200)" % max_flash)
	print("OVO 20 frames contido no slot (140 px): OK")


func _t_mordida_tamanho() -> void:
	var fx = MOR.new()
	add_child(fx)
	var flag := {"done": false}
	fx.finished.connect(func() -> void: flag["done"] = true)
	fx.setup(Vector2(400, 473), Vector2(700, 246))
	if absf(fx.DUR - 2.0) > 0.001:
		_fail("mordida: DUR %.2f (esperado 2.0)" % fx.DUR)
	var t0 := Time.get_ticks_msec()
	var max_sz := 0.0
	while not flag["done"] and Time.get_ticks_msec() - t0 < 5000:
		await get_tree().process_frame
		if is_instance_valid(fx):
			max_sz = maxf(max_sz, fx._serp.scale.x * fx.TEX_SZ)
	if not flag["done"]:
		_fail("mordida: não terminou")
	if max_sz > 140.0:
		_fail("mordida: serpente de %.0f px > carta (140)" % max_sz)
	print("MORDIDA serpente <= carta (%.0f px máx) em 2,0 s: OK" % max_sz)


func _t_relogio_tamanho() -> void:
	var fx = DES.new()
	add_child(fx)
	var flag := {"done": false}
	fx.finished.connect(func() -> void: flag["done"] = true)
	fx.setup(Vector2(640, 246))
	if fx.FRAMES.size() != 20:
		_fail("relogio: %d frames (esperado 20)" % fx.FRAMES.size())
	var th: float = fx.FRAMES[0].get_height() * fx.SCALE
	if th <= 140.0 or th > 190.0:
		_fail("relogio: altura %.0f px (esperado um pouco > 140 e <= 190)" % th)
	var t0 := Time.get_ticks_msec()
	while not flag["done"] and Time.get_ticks_msec() - t0 < 5000:
		await get_tree().process_frame
	if not flag["done"]:
		_fail("relogio: não terminou")
	print("RELOGIO 20 frames um pouco maior que a carta (%.0f px): OK" % th)


func _t_battle_mordida() -> void:
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
	var c0 := _card(st, "SERPENTE REAL", "mordidaVenenosa", 0)
	var c1 := _card(st, "ALVO FRIO", "", 1)
	st.players[0]["field"].append(c0)
	st.players[1]["field"].append(c1)
	b._on_champion_summoned(0, c0)
	b._on_champion_summoned(1, c1)
	b._layout_field(0)
	b._layout_field(1)
	await get_tree().create_timer(0.4).timeout
	b._on_fx_mordida(0, int(c0["uid"]), int(c1["uid"]))
	var seen := false
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1200:
		for ch in b.fx_layer.get_children():
			if ch is MOR:
				seen = true
				break
		if seen:
			break
		await get_tree().process_frame
	if not seen:
		_fail("mordida battle: fx não apareceu")
	await get_tree().create_timer(2.4).timeout
	var veneno := false
	for c in st.players[1]["field"]:
		if int(c["uid"]) == int(c1["uid"]) and int(c.get("poison_turns", 0)) > 0:
			veneno = true
	if not veneno:
		_fail("mordida battle: veneno não aplicado no alvo ao fim")
	b.queue_free()
	print("MORDIDA battle: serpente origem->alvo + veneno no fim: OK")
