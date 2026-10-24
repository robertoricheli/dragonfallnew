extends Node
## Teste 1.49.93: (1) DEFENSOR/GUARDIÃO/PESADELO/INVOCAR DRAGÃO ficam PENDENTES
## com fx ligado e só aplicam via resolve_* (ou no flush de fim de turno);
## (2) os seis VFX novos/reescritos (Defensor, Guardião, Ovo, Pesadelo,
## Mordida AAA e Baforada em cone) rodam headless até o `finished` (e o
## `burst` do ovo); (3) integração na Tela de Combate: Proteção tardia, pilar
## por aliado, ovo que invoca o Filhote e fantasmas do Pesadelo sobre o herói
## (com remoção no fim do turno do afetado).
## Rodar: godot --headless --path . res://tests/t_93.tscn

var _ok := true


func _fail(msg: String) -> void:
	_ok = false
	printerr("FALHA: " + msg)


func _ready() -> void:
	print("== T93 (1.49.93) ==")
	await _t_state_defensor()
	await _t_state_guardiao()
	await _t_state_pesadelo()
	await _t_state_invoke()
	await _t_vfx_all()
	await _t_battle_integration()
	print("== T93 %s ==" % ("OK" if _ok else "FALHOU"))
	get_tree().quit(0 if _ok else 1)


func _card(st: GameState, nm: String, oe: String, pi: int = 0) -> Dictionary:
	# carta COMPLETA pelo motor (todas as chaves que _recalc_statuses usa)
	return st.instantiate_card({
		"name": nm, "power": 1, "category": "champion", "on_enter": oe,
		"talent_effect": "", "ability_name": "", "ability_desc": "",
		"on_destroy": "", "constant": "",
	}, pi)


# ---------------------------------------------------------------- estado

func _t_state_defensor() -> void:
	var st := GameState.new()
	st.setup({}, {})
	st.fx_enabled = true
	var c := _card(st, "SIR DUNKAN", "defensor")
	var uid := int(c["uid"])
	st.players[0]["field"].append(c)
	st._resolve_on_enter_named(0, c, "defensor")
	if int(c["shield_turns"]) != 0:
		_fail("defensor: Proteção aplicada ANTES da animação")
	if st.pending_defensor.size() != 1:
		_fail("defensor: pending não registrado")
	st.resolve_defensor(uid)
	if int(c["shield_turns"]) != -1:
		_fail("defensor: resolve não aplicou Proteção permanente")
	if not st.pending_defensor.is_empty():
		_fail("defensor: pending não limpo")
	# simulação sem tela: na hora
	var st2 := GameState.new()
	st2.setup({}, {})
	st2.fx_enabled = false
	var c2 := _card(st2, "SIR DUNKAN", "defensor")
	st2.players[0]["field"].append(c2)
	st2._resolve_on_enter_named(0, c2, "defensor")
	if int(c2["shield_turns"]) != -1:
		_fail("defensor sim: não aplicou na hora")
	print("DEFENSOR pendente -> resolve_defensor: OK")


func _t_state_guardiao() -> void:
	var st := GameState.new()
	st.setup({}, {})
	st.fx_enabled = true
	var ally := _card(st, "OLAF", "")
	var gua := _card(st, "ARCANJO", "guardiao")
	st.players[0]["field"].append(ally)
	st.players[0]["field"].append(gua)
	st._resolve_on_enter_named(0, gua, "guardiao")
	if int(ally["shield_turns"]) != 0:
		_fail("guardiao: Proteção aplicada ANTES dos pilares")
	if st.pending_guardiao.size() != 1 or int(st.pending_guardiao[0]["uid"]) != int(ally["uid"]):
		_fail("guardiao: pending errado: %s" % str(st.pending_guardiao))
	st.resolve_guardiao(int(ally["uid"]))
	if int(ally["shield_turns"]) != 1:
		_fail("guardiao: resolve não deu 1 rodada de Proteção")
	if int(gua["shield_turns"]) != 0:
		_fail("guardiao: o próprio guardião ganhou Proteção")
	print("GUARDIÃO pendente -> resolve_guardiao por aliado: OK")


func _t_state_pesadelo() -> void:
	var st := GameState.new()
	st.setup({}, {})
	st.fx_enabled = true
	var ak := _card(st, "AKASHA", "pesadelo")
	st.players[0]["field"].append(ak)
	st._resolve_on_enter_named(0, ak, "pesadelo")
	if bool(st.players[1]["skip_draw"]):
		_fail("pesadelo: saque bloqueado ANTES da animação")
	# fim do turno SEM a animação terminar: o flush garante o efeito — e o
	# start_turn do afetado consome a flag SEM comprar carta.
	var h1: int = (st.players[1]["hand"] as Array).size()
	st.end_turn()
	if (st.players[1]["hand"] as Array).size() != h1:
		_fail("pesadelo: flush do fim do turno não bloqueou o saque do afetado")
	if bool(st.players[1]["skip_draw"]):
		_fail("pesadelo: flag não consumida no turno do afetado")
	# resolve idempotente após o flush
	st.resolve_pesadelo()
	# com resolve normal (sem end_turn)
	var st2 := GameState.new()
	st2.setup({}, {})
	st2.fx_enabled = true
	var ak2 := _card(st2, "AKASHA", "pesadelo")
	st2.players[0]["field"].append(ak2)
	st2._resolve_on_enter_named(0, ak2, "pesadelo")
	st2.resolve_pesadelo()
	if not bool(st2.players[1]["skip_draw"]):
		_fail("pesadelo: resolve_pesadelo não bloqueou o saque")
	print("PESADELO pendente -> resolve/flush de turno: OK")


func _t_state_invoke() -> void:
	var st := GameState.new()
	st.setup({}, {})
	st.fx_enabled = true
	var wy := _card(st, "WYVERN", "invokeDragon")
	st.players[0]["field"].append(wy)
	st._resolve_on_enter_named(0, wy, "invokeDragon")
	if st.players[0]["field"].size() != 1:
		_fail("invokeDragon: Filhote entrou ANTES do ovo chocar")
	st.resolve_invoke_dragon()
	if st.players[0]["field"].size() != 2:
		_fail("invokeDragon: resolve não invocou o Filhote")
	elif String(st.players[0]["field"][1]["name"]) != "FILHOTE DE DRAGÃO":
		_fail("invokeDragon: token errado: %s" % str(st.players[0]["field"][1]["name"]))
	# flush de fim de turno também invoca
	var st2 := GameState.new()
	st2.setup({}, {})
	st2.fx_enabled = true
	var wy2 := _card(st2, "WYVERN", "invokeDragon")
	st2.players[0]["field"].append(wy2)
	st2._resolve_on_enter_named(0, wy2, "invokeDragon")
	st2.end_turn()
	if st2.players[0]["field"].size() != 2:
		_fail("invokeDragon: flush do fim do turno não invocou o Filhote")
	print("INVOCAR DRAGÃO pendente -> ovo choca/flush: OK")


# ---------------------------------------------------------------- VFX

func _run_fx(path: String, args: Array, expect_min: float, expect_max: float, want_burst: bool) -> float:
	var fx = load(path).new()
	add_child(fx)
	var done: Array = []
	var bursted: Array = []
	fx.finished.connect(func() -> void: done.append(1))
	if want_burst and fx.has_signal("burst"):
		fx.burst.connect(func() -> void: bursted.append(Time.get_ticks_msec()))
	fx.callv("setup", args)
	var t0 := Time.get_ticks_msec()
	var guard := 0
	while done.is_empty() and guard < 500:
		await get_tree().process_frame
		guard += 1
	var dt := (Time.get_ticks_msec() - t0) / 1000.0
	if done.is_empty():
		_fail("%s: não emitiu finished (guard estourou)" % path)
	elif dt < expect_min or dt > expect_max:
		_fail("%s: duração fora do esperado: %.2fs" % [path, dt])
	if want_burst:
		if bursted.is_empty():
			_fail("%s: não emitiu burst" % path)
		else:
			var bd := (int(bursted[0]) - t0) / 1000.0
			# (1.49.96) burst do ovo-vídeo: fim dos 2,0 s (Filhote surge em seguida)
			if bd < 1.6 or bd > 2.1:
				_fail("%s: burst fora da janela: %.2fs" % [path, bd])
	await get_tree().process_frame
	if is_instance_valid(fx):
		_fail("%s: não se liberou após o finished" % path)
	return dt


func _t_vfx_all() -> void:
	var a := Vector2(300.0, 460.0)
	var b := Vector2(760.0, 240.0)
	var d1 := await _run_fx("res://scripts/vfx_defensor.gd", [a], 1.3, 1.9, false)
	print("VFX Defensor (%.2fs): OK" % d1)
	var d2 := await _run_fx("res://scripts/vfx_guardiao.gd", [a], 0.85, 1.3, false)
	print("VFX Guardião/pilar (%.2fs): OK" % d2)
	var d3 := await _run_fx("res://scripts/vfx_ovo.gd", [a], 1.8, 2.4, true)
	print("VFX Ovo do Dragão (%.2fs, com burst): OK" % d3)
	var d4 := await _run_fx("res://scripts/vfx_pesadelo.gd", [a, b], 1.8, 2.4, false)
	print("VFX Pesadelo/enxurrada (%.2fs): OK" % d4)
	var d5 := await _run_fx("res://scripts/vfx_mordida.gd", [a], 1.1, 1.6, false)
	print("VFX Mordida vídeo (%.2fs): OK" % d5)
	var d6 := await _run_fx("res://scripts/vfx_baforada.gd", [a, b], 1.5, 2.0, false)
	print("VFX Baforada em cone (%.2fs): OK" % d6)
	# assets atuais das animações existem (sheets do dono desde a 1.49.95)
	for p in ["res://assets/FILHOTE_DE_DRAGAO_F01.png", "res://assets/FILHOTE_DE_DRAGAO_F54.png", "res://assets/MORDIDA_VENENOSA_F01.png", "res://assets/MORDIDA_VENENOSA_F40.png", "res://assets/DESACELERAR_F01.png", "res://assets/DESACELERAR_F78.png", "res://assets/FANTASMA_PESADELO.png", "res://assets/FANTASMA_PESADELO2.png"]:
		if not ResourceLoader.exists(p):
			_fail("asset ausente: " + p)
	print("Assets atuais (vídeos recortados + fantasmas): OK")


# ---------------------------------------------------------------- batalha

func _t_battle_integration() -> void:
	if FileAccess.file_exists("user://layout_battle.cfg"):
		var d := DirAccess.open("user://")
		if d != null:
			d.remove("layout_battle.cfg")
	var b := BattleScreen.new()
	b.ai_step_delay = 0.02
	b.ai_running = true   # o teste dirige os turnos manualmente
	add_child(b)
	await get_tree().process_frame
	await get_tree().process_frame
	var st: GameState = b.state
	# --- DEFENSOR: pouso -> 0,5 s -> VFX -> +0,5 s -> Proteção
	var cd := _card(st, "SIR DUNKAN", "defensor")
	st.players[0]["field"].append(cd)
	st._resolve_on_enter_named(0, cd, "defensor")
	b._on_champion_summoned(0, cd)
	b._layout_field(0)
	await get_tree().create_timer(1.9).timeout
	if int(cd["shield_turns"]) != -1:
		_fail("batalha defensor: Proteção não entrou no tempo: %s" % str(cd["shield_turns"]))
	var vd: ChampionView = b.champ_views.get(int(cd["uid"]))
	if vd == null or not (vd._status_order as Array).has("prot"):
		_fail("batalha defensor: ícone de Proteção ausente na view")
	print("Batalha DEFENSOR (VFX -> Proteção tardia): OK")
	# --- GUARDIÃO: pilares UM A UM nos dois aliados já em campo
	var ally := _card(st, "OLAF", "")
	st.players[0]["field"].append(ally)
	b._on_champion_summoned(0, ally)
	b._layout_field(0)
	await get_tree().create_timer(0.7).timeout
	var cg := _card(st, "ARCANJO", "guardiao")
	st.players[0]["field"].append(cg)
	st._resolve_on_enter_named(0, cg, "guardiao")
	b._on_champion_summoned(0, cg)
	b._layout_field(0)
	await get_tree().create_timer(4.2).timeout
	if int(ally["shield_turns"]) != 1:
		_fail("batalha guardiao: aliado sem Proteção: %s" % str(ally["shield_turns"]))
	if int(cd["shield_turns"]) != -1:
		_fail("batalha guardiao: defensor perdeu a Proteção permanente")
	if int(cg["shield_turns"]) != 0:
		_fail("batalha guardiao: o guardião se protegeu")
	print("Batalha GUARDIÃO (pilar por aliado -> Proteção): OK")
	# --- INVOCAR DRAGÃO: ovo choca -> Filhote em campo
	var wy := _card(st, "WYVERN", "invokeDragon")
	st.players[0]["field"].append(wy)
	st._resolve_on_enter_named(0, wy, "invokeDragon")
	b._on_champion_summoned(0, wy)
	b._layout_field(0)
	await get_tree().create_timer(2.9).timeout
	var has_filhote := false
	for c in st.players[0]["field"]:
		if String(c["name"]) == "FILHOTE DE DRAGÃO":
			has_filhote = true
	if not has_filhote:
		_fail("batalha invokeDragon: Filhote não entrou após o ovo")
	print("Batalha INVOCAR DRAGÃO (ovo choca -> Filhote): OK")
	# --- PESADELO: enxurrada -> saque bloqueado + fantasmas no herói inimigo
	var ak := _card(st, "AKASHA", "pesadelo")
	st.players[0]["field"].append(ak)
	st._resolve_on_enter_named(0, ak, "pesadelo")
	b._on_champion_summoned(0, ak)
	b._layout_field(0)
	await get_tree().create_timer(3.3).timeout
	if not bool(st.players[1]["skip_draw"]):
		_fail("batalha pesadelo: jogador 1 sem saque bloqueado")
	if b._pesadelo_hero_pi != 1:
		_fail("batalha pesadelo: overlay do herói não ligou (pi=%s)" % str(b._pesadelo_hero_pi))
	# o efeito some quando termina o turno do jogador afetado
	b._on_turn_started(1)
	if b._pesadelo_hero_pi != 1:
		_fail("batalha pesadelo: overlay sumiu durante o turno do afetado")
	b._on_turn_started(0)
	if b._pesadelo_hero_pi != -1:
		_fail("batalha pesadelo: overlay não sumiu no fim do turno do afetado")
	print("Batalha PESADELO (enxurrada -> herói assombrado -> some no fim do turno): OK")
	b.queue_free()
	await get_tree().process_frame
