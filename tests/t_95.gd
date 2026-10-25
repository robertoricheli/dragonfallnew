extends Node
## Teste 1.49.96: animações vindas dos VÍDEOS do dono (fundo branco recortado
## com keying profissional): (1) OVO/FILHOTE: 54 frames, 2,0 s, renderizado
## DENTRO do slot (largura <= 100 px, altura ~132 px) — nunca encosta no
## campeão que usou — e burst no fim (Filhote surge em seguida); (2) MORDIDA:
## 40 frames, 1,33 s, 120 px de largura (MENOR que a carta 140 px) e, na Tela
## de Combate, aparece 0,5 s após a seleção do alvo, com veneno no fim;
## (3) DESACELERAR: 78 frames, 2,6 s, relógio com ~170 px (um pouco maior que
## a carta) contido na linha adversária. Os três rodam headless até o
## finished (e burst do ovo).
## Rodar: godot --headless --path . res://tests/t_95.tscn

var _ok := true

const OVO := preload("res://scripts/vfx_ovo.gd")
const MOR := preload("res://scripts/vfx_mordida.gd")
const DES := preload("res://scripts/vfx_desacelerar.gd")


func _fail(msg: String) -> void:
	_ok = false
	printerr("FALHA: " + msg)


func _ready() -> void:
	print("== T95 (1.49.96) ==")
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
	var flag := {"done": false, "burst": false, "tb": -1.0}
	var t0 := Time.get_ticks_msec()
	fx.finished.connect(func() -> void: flag["done"] = true)
	fx.burst.connect(func() -> void:
		flag["burst"] = true
		flag["tb"] = (Time.get_ticks_msec() - t0) / 1000.0)
	fx.setup(Vector2(640, 473))
	if fx._frames.size() != 71:
		_fail("ovo: %d frames (esperado 71)" % fx._frames.size())
	var tw: float = fx._frames[0].get_width() * fx._scale
	var th: float = fx._frames[0].get_height() * fx._scale
	if th < 90.0 or th > 140.0:
		_fail("ovo: altura %.0f px (esperado 90..140)" % th)
	if tw > 116.0:
		_fail("ovo: largura %.0f px > 116 (encostaria no campeão ao lado)" % tw)
	var guard := 0
	while not flag["done"] and guard < 400:
		await get_tree().process_frame
		guard += 1
	if not flag["done"]:
		_fail("ovo: não terminou")
	if not flag["burst"]:
		_fail("ovo: não emitiu burst")
	elif float(flag["tb"]) < 1.5 or float(flag["tb"]) > 2.1:
		_fail("ovo: burst em %.2fs (esperado ~1.97)" % float(flag["tb"]))
	print("OVO-vídeo 71 frames no slot (%.0fx%.0f px), burst no fim: OK" % [tw, th])


func _t_mordida_tamanho() -> void:
	var fx = MOR.new()
	add_child(fx)
	var flag := {"done": false}
	fx.finished.connect(func() -> void: flag["done"] = true)
	fx.setup(Vector2(700, 246))
	if fx._frames.size() != 40:
		_fail("mordida: %d frames (esperado 40)" % fx._frames.size())
	if absf(fx.DUR - 1.33) > 0.01:
		_fail("mordida: DUR %.2f (esperado 1.33)" % fx.DUR)
	var tw: float = fx._frames[0].get_width() * fx._scale
	if tw >= 140.0:
		_fail("mordida: largura %.0f px >= carta 140" % tw)
	var guard := 0
	while not flag["done"] and guard < 400:
		await get_tree().process_frame
		guard += 1
	if not flag["done"]:
		_fail("mordida: não terminou")
	print("MORDIDA-vídeo 40 frames, %.0f px (< carta): OK" % tw)


func _t_relogio_tamanho() -> void:
	var fx = DES.new()
	add_child(fx)
	var flag := {"done": false}
	fx.finished.connect(func() -> void: flag["done"] = true)
	fx.setup(Vector2(640, 246))
	if fx._frames.size() != 60:
		_fail("relogio: %d frames (esperado 60)" % fx._frames.size())
	var th: float = fx._frames[0].get_height() * fx._scale
	if th <= 140.0 or th > 190.0:
		_fail("relogio: altura %.0f px (esperado um pouco > 140 e <= 190)" % th)
	var guard := 0
	while not flag["done"] and guard < 500:
		await get_tree().process_frame
		guard += 1
	if not flag["done"]:
		_fail("relogio: não terminou")
	print("DESACELERAR-vídeo 60 frames, %.0f px (> carta): OK" % th)


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
	# 0,5 s de delay: o fx NÃO pode existir antes disso
	await get_tree().create_timer(0.25).timeout
	for ch in b.fx_layer.get_children():
		if ch is MOR:
			_fail("mordida battle: fx apareceu antes dos 0,5 s")
	var seen := false
	var guard := 0
	while guard < 120:
		for ch in b.fx_layer.get_children():
			if ch is MOR:
				seen = true
				break
		if seen:
			break
		await get_tree().process_frame
		guard += 1
	if not seen:
		_fail("mordida battle: fx não apareceu após 0,5 s")
	await get_tree().create_timer(2.2).timeout
	var veneno := false
	for c in st.players[1]["field"]:
		if int(c["uid"]) == int(c1["uid"]) and int(c.get("poison_turns", 0)) > 0:
			veneno = true
	if not veneno:
		_fail("mordida battle: veneno não aplicado no alvo ao fim")
	b.queue_free()
	print("MORDIDA battle: delay 0,5 s + vído no alvo + veneno no fim: OK")
