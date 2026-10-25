extends Node
## Teste 1.49.94: (1) PESADELO da IA: UM só cone, nascendo NO MEIO da tela
## (campo afetado), nunca no topo/esquerda, e guarda anti-duplicata; (2) NENHUM
## texto de status (amarelo) sobre a carta em campo — só ícones no canto;
## (3) BARREIRA sem painel pulsante: vira ícone na pilha do canto; (4) os VFX
## reescritos/novos (Ovo 5 frames, Mordida sem cobra e Relógio DESACELERAR)
## rodam headless até o finished (e o burst do ovo); (5) integração na Tela de
## Combate: relógio aparece no campo adversário 0,5 s após o pouso e o efeito
## de 1 ação a menos continua aplicado.
## Rodar: godot --headless --path . res://tests/t_94.tscn

var _ok := true

const PES := preload("res://scripts/vfx_pesadelo.gd")
const OVO := preload("res://scripts/vfx_ovo.gd")
const MOR := preload("res://scripts/vfx_mordida.gd")
const DES := preload("res://scripts/vfx_desacelerar.gd")


func _fail(msg: String) -> void:
	_ok = false
	printerr("FALHA: " + msg)


func _ready() -> void:
	print("== T94 (1.49.94) ==")
	await _t_view_sem_texto_status()
	await _t_view_barreira_icone()
	await _t_vfx_all()
	await _t_battle_pesadelo_ia()
	await _t_battle_desacelerar()
	print("== T94 %s ==" % ("OK" if _ok else "FALHOU"))
	get_tree().quit(0 if _ok else 1)


func _card(st: GameState, nm: String, oe: String, pi: int = 0) -> Dictionary:
	return st.instantiate_card({
		"name": nm, "power": 1, "category": "champion", "on_enter": oe,
		"talent_effect": "", "ability_name": "", "ability_desc": "",
		"on_destroy": "", "constant": "",
	}, pi)


# ---------------------------------------------------------------- views

func _t_view_sem_texto_status() -> void:
	var st := GameState.new()
	st.setup({}, {})
	var c := _card(st, "BAFEDOR DE FOGO", "")
	c["poison_turns"] = 2
	c["fury_turns"] = 1
	c["fury_stacks"] = 1
	c["burn_turns"] = 1
	c["barrier_turns"] = 1
	c["silenced"] = true
	var v := ChampionView.new()
	v.setup(c, 0)
	add_child(v)
	await get_tree().process_frame
	await get_tree().process_frame
	# NENHUM Label filho com texto de status (regra do dono: nada de amarelo)
	for ch in v.get_children():
		if ch is Label and String((ch as Label).text).strip_edges() != "":
			_fail("texto de status sobre a carta: '%s'" % (ch as Label).text)
	# e a view não tem mais nem o nó de label de status
	if v.get("_status_label") != null:
		_fail("_status_label ainda existe na ChampionView")
	v.queue_free()
	print("View sem texto de status amarelo: OK")


func _t_view_barreira_icone() -> void:
	var st := GameState.new()
	st.setup({}, {})
	var c := _card(st, "MURO REAL", "")
	c["barrier_turns"] = 2
	var v := ChampionView.new()
	v.setup(c, 0)
	add_child(v)
	await get_tree().process_frame
	await get_tree().process_frame
	if v.get("_barrier") != null:
		_fail("painel _barrier ainda existe na ChampionView")
	if not (v._status_order as Array).has("barreira"):
		_fail("BARREIRA não virou ícone na pilha do canto")
	v.queue_free()
	print("BARREIRA como ícone (sem painel): OK")


# ---------------------------------------------------------------- VFX headless

func _run_fx(scr: GDScript, args: Array, expect_burst: bool) -> bool:
	var fx = scr.new()
	add_child(fx)
	# (lambda GDScript captura locals POR VALOR: usa-se Dictionary p/ mutar)
	var flag := {"done": false, "burst": not expect_burst}
	fx.finished.connect(func() -> void: flag["done"] = true)
	if expect_burst:
		fx.burst.connect(func() -> void: flag["burst"] = true)
	if args.size() == 2:
		fx.setup(args[0], args[1])
	else:
		fx.setup(args[0])
	var t0 := Time.get_ticks_msec()
	while not flag["done"] and Time.get_ticks_msec() - t0 < 4000:
		await get_tree().process_frame
	if not flag["done"]:
		_fail("%s não terminou (finished)" % scr.resource_path)
	if not flag["burst"]:
		_fail("%s não emitiu burst" % scr.resource_path)
	return bool(flag["done"])


func _t_vfx_all() -> void:
	var a := Vector2(640, 473)
	await _run_fx(OVO, [a], true)
	await _run_fx(MOR, [a], false)
	await _run_fx(DES, [a], false)
	print("VFX Ovo(5 frames)/Mordida(sem cobra)/Relógio headless: OK")


# ---------------------------------------------------------------- battle

func _t_battle_pesadelo_ia() -> void:
	var b := _mk_battle()
	var st: GameState = b.state
	var ak := _card(st, "AKASHA", "pesadelo", 1)
	st.players[1]["field"].append(ak)
	st._resolve_on_enter_named(1, ak, "pesadelo")
	b._on_champion_summoned(1, ak)
	b._layout_field(1)
	# (1.49.99) paridade: sem voo da IA — cone nasce ~0,6 s; confere em 1,2 s
	await get_tree().create_timer(1.2).timeout
	var cones := []
	for ch in b.fx_layer.get_children():
		if ch is PES:
			cones.append(ch)
	if cones.size() != 1:
		_fail("pesadelo IA: %d cones (esperado 1)" % cones.size())
	elif cones.size() == 1:
		# (1.49.99) PARIDADE: o cone nasce do campeão que invocou (IA ou não)
		var fx = cones[0]
		var vc: ChampionView = b.champ_views.get(int(ak["uid"]))
		var want: Vector2 = vc.global_position + vc.size / 2.0
		if fx._from.distance_to(want) > 2.0:
			_fail("pesadelo IA: cone não nasce do caster (%s vs %s)" % [str(fx._from), str(want)])
	# guarda anti-duplicata: segundo disparo no mesmo uid NÃO cria outro cone
	b._pesadelo_sequence(1, int(ak["uid"]))
	await get_tree().create_timer(0.3).timeout
	var cones2 := 0
	for ch in b.fx_layer.get_children():
		if ch is PES:
			cones2 += 1
	if cones2 != 1:
		_fail("pesadelo IA: guarda anti-duplicata falhou (%d cones)" % cones2)
	# no fim: loop sobre o herói AFETADO (jogador 0)
	await get_tree().create_timer(1.6).timeout
	if b._pesadelo_hero_pi != 0:
		_fail("pesadelo IA: loop do herói não ligou no jogador afetado")
	b.queue_free()
	print("PESADELO da IA: 1 cone do caster (paridade) + anti-duplicata: OK")


func _t_battle_desacelerar() -> void:
	var b := _mk_battle()
	var st: GameState = b.state
	var mg := _card(st, "MAGA DO TEMPO", "desacelerar", 0)
	st.players[0]["field"].append(mg)
	st._resolve_on_enter_named(0, mg, "desacelerar")
	b._on_champion_summoned(0, mg)
	b._layout_field(0)
	# relógio aparece ~0,6-0,7 s após o pouso; poll até 2,0 s
	var seen := false
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 2000:
		for ch in b.fx_layer.get_children():
			if ch is DES:
				seen = true
				# deve estar sobre o campo da IA (linha de cima)
				if absf(ch.position.y - 246.0) > 1.0:
					_fail("relógio DESACELERAR em y=%.0f (esperado 246)" % ch.position.y)
				break
		if seen:
			break
		await get_tree().process_frame
	if not seen:
		_fail("relógio DESACELERAR não apareceu no campo adversário")
	# efeito de jogo continua aplicado + relógio some após o vídeo (2,6 s)
	if not bool(st.players[1]["skip_next_action"]):
		_fail("desacelerar: adversário sem skip_next_action")
	await get_tree().create_timer(3.1).timeout
	for ch in b.fx_layer.get_children():
		if ch is DES:
			_fail("relógio DESACELERAR não sumiu após o vídeo")
			break
	b.queue_free()
	print("DESACELERAR: relógio 2 s no campo adversário + efeito: OK")


func _mk_battle() -> Node:
	if FileAccess.file_exists("user://layout_battle.cfg"):
		var d := DirAccess.open("user://")
		if d != null:
			d.remove("layout_battle.cfg")
	var b := BattleScreen.new()
	b.ai_step_delay = 0.02
	b.ai_running = true   # o teste dirige os turnos manualmente
	add_child(b)
	return b
