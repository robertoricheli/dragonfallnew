extends Node
## Teste 1.49.92: (1) CONGELADO sem cristal de gelo persistente — SOMENTE o
## ícone no canto superior direito (pilha na ordem de aquisição); (2) BAFORADA
## VENENOSA: mira verde + veneno aplicado SÓ após a animação; (3) o VFX do
## sopro do Dragão Verde roda do início ao fim e emite `finished`.
## Rodar: godot --headless --path . res://tests/t_92.tscn

var _ok := true


func _fail(msg: String) -> void:
	_ok = false
	printerr("FALHA: " + msg)


func _ready() -> void:
	print("== T92 (1.49.92) ==")
	await _t_cong_icon()
	await _t_baforada_flow()
	await _t_baforada_vfx()
	await _t_battle_integration()
	print("== T92 %s ==" % ("OK" if _ok else "FALHOU"))
	get_tree().quit(0 if _ok else 1)


func _champ_card(uid: int) -> Dictionary:
	for d in CardDB.playable_defs():
		if String(d["category"]) == "champion":
			var c: Dictionary = d.duplicate(true)
			c["uid"] = uid
			c["current_power"] = int(c.get("power", 1))
			c["shield_turns"] = 0
			c["poison_turns"] = 0
			c["fury_turns"] = 0
			c["fury_stacks"] = 0
			c["barrier_turns"] = 0
			c["wall_buff"] = 0
			c["frozen_turns"] = 0
			c["on_destroy"] = ""
			c["ability_name"] = ""
			c["corrupted"] = false
			c["silenced"] = false
			c["tapped"] = false
			return c
	_fail("sem def de campeão")
	return {}


func _t_cong_icon() -> void:
	var v := ChampionView.new()
	v.setup(_champ_card(9101), 0)
	add_child(v)
	await get_tree().process_frame
	# o cristal de gelo persistente NÃO existe mais no código
	if "_frost" in v or v.has_method("_frost_show") or v.has_method("_frost_hide"):
		_fail("cristal de gelo persistente ainda presente em ChampionView")
	var c: Dictionary = v.card
	# CONGELADO -> somente o ícone no canto superior direito
	c["frozen_turns"] = 2
	v.refresh()
	if v._status_order != ["cong"]:
		_fail("pilha com cong != %s" % str(v._status_order))
	var ent: Dictionary = v._status_icons.get("cong", {})
	if ent.is_empty():
		_fail("ícone cong não criado")
	else:
		var ico: TextureRect = ent["ico"]
		if ico.position.x < 70.0 or ico.position.y < 3.0:
			_fail("ícone cong fora do canto superior direito: %s" % ico.position)
	# nenhum filho usa o floco de gelo como textura (cristal extinto)
	for ch in v.get_children():
		if ch is TextureRect and ch.texture != null and String(ch.texture.resource_path).ends_with("VFX_FLOCO.png"):
			_fail("cristal/floco persistente encontrado como filho da carta")
	# tinta azulada continua (não é animação)
	if v.modulate != Color(0.72, 0.86, 1.05):
		_fail("tinta azulada do congelado sumiu: %s" % str(v.modulate))
	# 2º status entra ABAIXO do 1º (ordem de aquisição)
	c["poison_turns"] = 2
	v.refresh()
	if v._status_order != ["cong", "veneno"]:
		_fail("ordem [cong,veneno] != %s" % str(v._status_order))
	var y0: float = (v._status_icons["cong"]["ico"] as TextureRect).position.y
	var y1: float = (v._status_icons["veneno"]["ico"] as TextureRect).position.y
	if y1 <= y0:
		_fail("veneno não ficou abaixo do cong: %s <= %s" % [y1, y0])
	# expirou o congelamento -> ícone sai e o de baixo sobe
	c["frozen_turns"] = 0
	v.refresh()
	if v._status_order != ["veneno"]:
		_fail("cong expirado não saiu da pilha: %s" % str(v._status_order))
	print("CONGELADO = só ícone no canto (sem cristal): OK")
	v.queue_free()
	await get_tree().process_frame


func _t_baforada_flow() -> void:
	# com fx ligado, o veneno NÃO é aplicado antes da animação
	var st := GameState.new()
	st.setup({}, {})
	st.fx_enabled = true
	var foe: Dictionary = {"uid": 777, "name": "ALVO", "current_power": 3, "poison_turns": 0, "category": "champion"}
	st.players[1]["field"].append(foe)
	if not st.effect_needs_target("baforadaVenenosa"):
		_fail("baforadaVenenosa não exige mira")
	var got: Array = []
	st.fx_baforada.connect(func(pi: int, s: int, t: int) -> void: got.append([pi, s, t]))
	st._begin_or_resolve_target(0, {"uid": 555}, "baforadaVenenosa", 555)
	if st.targeting.is_empty():
		_fail("mira da baforada não abriu")
	elif (st.targeting["candidates"] as Array).size() != 1 or int((st.targeting["candidates"] as Array)[0]) != 777:
		_fail("candidatos da mira errados: %s" % str(st.targeting.get("candidates")))
	st.confirm_targeting(777)
	if got.size() != 1:
		_fail("fx_baforada não emitido ao confirmar a mira")
	elif int(got[0][1]) != 555 or int(got[0][2]) != 777:
		_fail("fx_baforada com args errados: %s" % str(got[0]))
	if int(foe["poison_turns"]) != 0:
		_fail("veneno aplicado ANTES da animação da baforada")
	st.resolve_baforada(777)
	if int(foe["poison_turns"]) != 2 or int(foe["poison_by"]) != 0:
		_fail("resolve_baforada não aplicou veneno: %s" % str(foe))
	# sem tela de batalha (simulação), aplica na hora
	var st2 := GameState.new()
	st2.setup({}, {})
	st2.fx_enabled = false
	var foe2: Dictionary = {"uid": 888, "name": "ALVO2", "current_power": 2, "poison_turns": 0, "category": "champion"}
	st2.players[1]["field"].append(foe2)
	st2._apply_baforada(0, 555, foe2)
	if int(foe2["poison_turns"]) != 2:
		_fail("simulação não aplicou veneno na hora")
	print("BAFORADA VENENOSA: mira + veneno após animação: OK")


func _t_baforada_vfx() -> void:
	var fx = load("res://scripts/vfx_baforada.gd").new()
	add_child(fx)
	var done: Array = []   # lambda captura locais POR VALOR: usa-se Array
	fx.finished.connect(func() -> void: done.append(1))
	fx.setup(Vector2(120.0, 460.0), Vector2(620.0, 180.0))
	var t0 := Time.get_ticks_msec()
	var guard := 0
	while done.is_empty() and guard < 400:
		await get_tree().process_frame
		guard += 1
	var dt := (Time.get_ticks_msec() - t0) / 1000.0
	if done.is_empty():
		_fail("vfx_baforada não emitiu finished (guard estourou)")
	elif dt < 0.9 or dt > 2.2:
		_fail("duração do sopro fora do esperado: %.2fs" % dt)
	await get_tree().process_frame
	if is_instance_valid(fx):
		_fail("vfx_baforada não se liberou após o finished")
	print("VFX sopro do Dragão Verde (%.2fs): OK" % dt)


func _t_battle_integration() -> void:
	# na Tela de Combate: o sopro voa e, NO FIM, o campeão alvo ganha o ícone
	if FileAccess.file_exists("user://layout_battle.cfg"):
		var d := DirAccess.open("user://")
		if d != null:
			d.remove("layout_battle.cfg")
	var b := BattleScreen.new()
	b.ai_step_delay = 0.02
	add_child(b)
	await get_tree().process_frame
	await get_tree().process_frame
	var st: GameState = b.state
	var uid := -1
	for i in range(st.players[1]["deck"].size()):
		if String(st.players[1]["deck"][i]["category"]) == "champion":
			var c: Dictionary = st.players[1]["deck"][i]
			uid = int(c["uid"])
			st.players[1]["field"].append(c)
			b._on_champion_summoned(1, c)
			break
	if uid < 0:
		_fail("sem campeão p/ integração")
		return
	b._layout_field(1)
	await get_tree().create_timer(0.8).timeout
	b._on_fx_baforada(0, -1, uid)
	await get_tree().create_timer(1.9).timeout
	var alvo: Dictionary = {}
	for c in st.players[1]["field"]:
		if int(c["uid"]) == uid:
			alvo = c
	if alvo.is_empty():
		_fail("alvo sumiu do campo")
	elif int(alvo.get("poison_turns", 0)) != 2:
		_fail("veneno não aplicado após o sopro na batalha: %s" % str(alvo.get("poison_turns")))
	var v: ChampionView = b.champ_views.get(uid)
	if v == null or not (v._status_order as Array).has("veneno"):
		_fail("ícone de ENVENENADO não entrou na pilha da view")
	print("Integração na Tela de Combate (sopro -> ícone): OK")
	b.queue_free()
	await get_tree().process_frame
