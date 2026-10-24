extends Node
## Smoke test headless: valida regras (IA vs IA) e a construção da UI de batalha.
## Rodar:  godot --headless --path . res://tests/smoke.tscn

var _rules_ok := true


func _ready() -> void:
	print("== DRAGONFALL SMOKE TEST ==")
	_rules_ok = _test_rules()
	_rules_ok = _test_targeting() and _rules_ok
	_test_ui()


func _test_rules() -> bool:
	var st := GameState.new()
	st.auto_target = true   # simulacao: alvos resolvidos automaticamente
	var logs := [0]
	st.log_msg.connect(func(_t): logs[0] += 1)
	st.setup(CardDB.HEROES[0], CardDB.HEROES[1])
	assert(st.players[0]["hand"].size() == 5)  # 4 iniciais + saque do 1º turno
	assert(st.players[1]["hand"].size() == 4)
	assert(st.players[0]["deck"].size() == 20 - 5)
	var turns := 0
	var guard := 0
	while st.winner == -1 and turns < 150:
		var pi: int = st.current
		var fails := 0
		while fails < 3 and guard < 30000:
			guard += 1
			var act: Dictionary = AIBrain.next_action(st)
			if String(act["type"]) == "end_turn":
				break
			var ok := false
			match String(act["type"]):
				"summon", "talent":
					ok = st.play_card(pi, int(act["hand_idx"]))
				"attack":
					ok = st.attack(pi, int(act["att_idx"]), int(act["def_idx"]))
				"draw":
					ok = st.manual_draw(pi)
			if ok:
				fails = 0
			else:
				fails += 1
		st.end_turn()
		turns += 1
	print("regras: turns=%d winner=%d vp=%dx%d logs=%d guard=%d" % [turns, st.winner, st.players[0]["vp"], st.players[1]["vp"], logs[0], guard])
	# invariantes
	var inv_ok := true
	for pi in 2:
		if st.players[pi]["field"].size() > GameState.MAX_FIELD:
			printerr("FALHA: campo > 6")
			inv_ok = false
		if st.players[pi]["hand"].size() > GameState.MAX_HAND:
			printerr("FALHA: mão > 8")
			inv_ok = false
	if st.winner == -1:
		printerr("AVISO: ninguém venceu em 150 turnos")
	return inv_ok and st.winner != -1


func _test_targeting() -> bool:
	# BOLA DE FOGO: efeito ESPERA a escolha do alvo; animacao so depois
	var st := GameState.new()
	st.setup(CardDB.HEROES[0], CardDB.HEROES[1])
	var foe: Dictionary = {
		"id": "alvo", "name": "ALVO TESTE", "category": "champion",
		"power": 3, "current_power": 3, "uid": 9001, "owner": 1,
		"tapped": false, "silenced": false, "frozen_turns": 0,
		"fury_stacks": 0, "fury_turns": 0, "barrier_turns": 0, "vulnerable": false,
		"desafiante_buff": 0, "inspirar_buff": 0, "wall_buff": 0, "charm_turns": 0,
	}
	st.players[1]["field"].append(foe)
	var caster: Dictionary = {
		"id": "lilith", "name": "LILITH", "category": "champion",
		"ability_type": "instant", "ability_name": "Bola de Fogo",
		"power": 1, "current_power": 1, "uid": 9002, "owner": 0,
		"on_enter": "bolaDeFogo", "silenced": false, "tapped": false,
		"frozen_turns": 0, "fury_stacks": 0, "fury_turns": 0,
		"desafiante_buff": 0, "inspirar_buff": 0, "wall_buff": 0, "charm_turns": 0,
		"barrier_turns": 0, "vulnerable": false,
	}
	st.players[0]["hand"].append(caster)
	var fired := [0]
	var started := [0]
	st.fx_fire.connect(func(_a, _b, _c): fired[0] += 1)
	st.targeting_started.connect(func(_a, _b, _c, _d): started[0] += 1)
	st.auto_target = false
	var okplay: bool = st.play_card(0, st.players[0]["hand"].size() - 1)
	if not okplay or st.targeting.is_empty() or started[0] != 1 or fired[0] != 0:
		printerr("FALHA mira: okplay=%s pend=%s started=%d fired=%d" % [okplay, st.targeting.is_empty(), started[0], fired[0]])
		return false
	st.confirm_targeting(9001)
	# (1.49.63) o dano fica PENDENTE até o impacto da animação: poder segue 3
	if not st.targeting.is_empty() or fired[0] != 1 or int(foe["current_power"]) != 3:
		printerr("FALHA mira confirm: pend=%s fired=%d poder=%d" % [st.targeting.is_empty(), fired[0], int(foe["current_power"])])
		return false
	st.resolve_bola(9001)  # simula o impacto da bola de fogo
	if int(foe["current_power"]) != 2:
		printerr("FALHA resolve_bola: poder=%d" % int(foe["current_power"]))
		return false
	print("mira: OK (alvo confirmado; dano só no IMPACTO, poder 3->2)")
	return true


func _test_ui() -> void:
	# layout limpo e determinístico para o teste
	if FileAccess.file_exists("user://layout_battle.cfg"):
		var d := DirAccess.open("user://")
		if d != null:
			d.remove("layout_battle.cfg")
	var b := BattleScreen.new()
	b.ai_step_delay = 0.02
	add_child(b)
	await get_tree().process_frame
	await get_tree().process_frame
	print("ui: construída, mão do jogador = ", b.hand_views[0].size(), " views")
	assert(b.hand_views[0].size() == 5)
	assert(b.hand_views[1].size() == 4)
	# força jogadas do jogador via estado (headless, sem mouse)
	var st := b.state
	var played := 0
	for i in range(st.players[0]["hand"].size() - 1, -1, -1):
		if st.can_play(0, i)["ok"]:
			if st.play_card(0, i):
				played += 1
		# (1.49.92) efeitos com MIRA (ex.: BAFORADA VENENOSA) abrem a escolha:
		# headless não tem mouse — confirma no mais forte, como a IA faria
		if not st.targeting.is_empty():
			var pu := st.auto_pick_uid()
			if pu >= 0:
				st.confirm_targeting(pu)
	await get_tree().process_frame
	print("ui: cartas jogadas = %d | campo jogador = %d | champ_views = %d" % [played, st.players[0]["field"].size(), b.champ_views.size()])
	# passa a vez e deixa a IA jogar até voltar
	st.end_turn()
	var t0 := Time.get_ticks_msec()
	while st.current == 1 and st.winner == -1 and Time.get_ticks_msec() - t0 < 30000:
		await get_tree().process_frame
	print("ui: turno IA concluído. current=%d winner=%d vp=%dx%d" % [st.current, st.winner, st.players[0]["vp"], st.players[1]["vp"]])
	# ataque por arrasto (via animação de combate da batalha)
	if st.current == 0 and st.winner == -1:
		# garante um par de combate: invoca um token em cada lado
		st._summon_token(0, "FILHOTE DE DRAGÃO")
		st._summon_token(1, "FILHOTE DE DRAGÃO")
		for i in 20:
			await get_tree().process_frame
		var a: int = st.players[0]["field"].size() - 1
		var d: int = st.players[1]["field"].size() - 1
		if st.can_attack(0, a, d)["ok"]:
			await b._do_combat(0, a, d)
			print("ui: animação de combate (arrasto) OK")
		else:
			printerr("FALHA: token não conseguiu atacar")
	# VFX bola de fogo: voa e explode sem erros
	var fx := FireballFX.new()
	b.fx_layer.add_child(fx)
	fx.setup(Vector2(200, 600), Vector2(700, 250), 0.3, 60.0)
	var t0f := Time.get_ticks_msec()
	while is_instance_valid(fx) and Time.get_ticks_msec() - t0f < 3000:
		await get_tree().process_frame
	print("ui: VFX bola de fogo OK")
	# zoom de carta: espelho fiel em tamanho real (3,2x)
	if st.players[0]["hand"].size() > 0:
		b._open_zoom(st.players[0]["hand"][0])
		await get_tree().process_frame
		assert(b.zoom_overlay != null)
		var zv: CardView = b.zoom_overlay.get_child(1)
		assert(abs(zv.size.x - 110.0 * 3.2) < 1.0 and abs(zv.size.y - 154.0 * 3.2) < 1.0)
		assert(zv._face != null and zv._face.texture != null)  # textura bakeada única
		b._close_zoom()
		await get_tree().process_frame
		print("ui: zoom de carta OK (espelho 3,2x)")
	# histórico de cartas (clique no herói)
	assert(st.play_history.size() > 0)
	b._open_history(0)
	await get_tree().process_frame
	assert(b.history_overlay != null)
	b._close_history()
	await get_tree().process_frame
	print("ui: histórico de cartas OK")
	# editor de layout: arrasto simulado via ScreenEditor
	b.ed.toggle()
	await get_tree().process_frame
	assert(b.ed.active and b.ed.overlay.visible)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(700, 300)
	press.global_position = Vector2(700, 300)
	b.ed._input(press)
	assert(b.ed.drag_id == "field")
	var mov := InputEventMouseMotion.new()
	mov.position = Vector2(740, 330)
	mov.global_position = Vector2(740, 330)
	b.ed._input(mov)
	assert((b.ed.groups["field"] as Control).position == Vector2(40, 30))
	var rel := InputEventMouseButton.new()
	rel.button_index = MOUSE_BUTTON_LEFT
	rel.pressed = false
	rel.position = Vector2(740, 330)
	rel.global_position = Vector2(740, 330)
	b.ed._input(rel)
	var esc := InputEventKey.new()
	esc.pressed = true
	esc.keycode = KEY_ESCAPE
	b.ed._input(esc)  # ESC fecha (e salva)
	assert(not b.ed.active)
	b.ed._reset()
	assert((b.ed.groups["field"] as Control).position == Vector2.ZERO)
	b.ed.selected = "actions"
	b.ed._delete_selected()
	assert(b.act_panel.visible == false)
	b.ed._undo()
	assert(b.act_panel.visible == true)
	print("ui: editor de layout (arrastar) OK")
	# editor: todos os elementos registrados
	for gid in ["field", "banner", "buy", "pass", "options", "actions", "timer", "ult", "editorbtn", "hero0", "hero1", "hand_p", "hand_ai"]:
		assert(b.ed.hls.has(gid))
	print("ui: editor delete/undo/ESC OK")
	# invocação posicionada (insert entre aliados)
	if st.current == 0 and st.winner == -1 and st.players[0]["field"].size() >= 1:
		var before: int = st.players[0]["field"].size()
		var hi := -1
		for k in st.players[0]["hand"].size():
			var cd: Dictionary = st.players[0]["hand"][k]
			if cd["category"] == "champion" and int(cd.get("summon_ritual", 0)) == 0 and st.can_play(0, k)["ok"]:
				hi = k
				break
		if hi >= 0:
			var nm2: String = st.players[0]["hand"][hi]["name"]
			st.play_card(0, hi, 0)
			assert(st.players[0]["field"][0]["name"] == nm2)
			assert(st.players[0]["field"].size() == before + 1)
			print("ui: invocação inserida à esquerda OK")
	# ultimate: apenas 1 por turno
	if st.current == 0 and st.winner == -1:
		var u1 := st.use_ultimate(0)
		var u2: bool = st.can_use_ultimate(0)["ok"]
		print("ui: ultimate usada=", u1, " | 2ª no turno bloqueada=", not u2)
		assert(u1 and not u2)
	# gate: só um talento por vez
	st.talent_active[0] = true
	for k in st.players[0]["hand"].size():
		if st.players[0]["hand"][k]["category"] == "talent":
			assert(not st.can_play(0, k)["ok"])
			break
	st.talent_active[0] = false
	print("ui: gate de talento OK")
	# espera tweens assentarem
	for i in 45:
		await get_tree().process_frame
	# regra de espaço: campeões sempre dentro da sua metade do campo
	for pi in 2:
		var half := Rect2(170, 157 if pi == 1 else 383, 932, 180)
		for c in st.players[pi]["field"]:
			var v: ChampionView = b.champ_views.get(int(c["uid"]))
			if v == null or v.dying:
				continue
			var r := v.get_global_rect()
			var vis := Rect2(r.position + (r.size - r.size * v.scale) / 2.0, r.size * v.scale)
			if not half.grow(2).encloses(vis):
				printerr("FALHA: campeão fora do campo: %s %s" % [v.card["name"], vis])
	print("ui: regra de espaço do campo OK")
	# layout centralizado: confere posição dos campeões (sem extras vivos)
	for pi in 2:
		var t0b := Time.get_ticks_msec()
		while (b.field_extras[pi] as Array).size() > 0 and Time.get_ticks_msec() - t0b < 6000:
			await get_tree().process_frame
		for i in 140:
			await get_tree().process_frame
		var f: Array = st.players[pi]["field"]
		var n: int = f.size() + (b.field_extras[pi] as Array).size()
		if f.size() > 0:
			var total: float = n * 100.0 + (n - 1) * 10.0
			var x0: float = 638.0 - total / 2.0
			for i in f.size():
				var v: ChampionView = b.champ_views.get(int(f[i]["uid"]))
				if v != null and not v.dying:
					var want := Vector2(x0 + i * 110.0, (246.0 if pi == 1 else 473.0) - 70.0)
					if (v.position - want).length() > 4.0:
						printerr("FALHA layout: champ %s pos %s != %s" % [f[i]["name"], v.position, want])
	print("ui: layout de campo centralizado OK")
	# telas novas: menu / configuração / arsenal
	var m := MenuScreen.new()
	add_child(m)
	await get_tree().process_frame
	var c := ConfigScreen.new()
	add_child(c)
	await get_tree().process_frame
	var a := ArsenalScreen.new()
	add_child(a)
	await get_tree().process_frame
	a._show_heroes()
	await get_tree().process_frame
	a._show_cards()
	await get_tree().process_frame
	if not a.filtered.is_empty():
		a._open_browse(0)
		await get_tree().process_frame
		a._zoom_overlay_clear()
	var mk := MarketScreen.new()
	add_child(mk)
	await get_tree().process_frame
	var c0: int = int(Profile.data["coins"])
	var r: Dictionary = Profile.add_match_rewards(true)
	assert(r["xp"] == 4 and r["coins"] == 1)
	var r2: Dictionary = Profile.add_match_rewards(false)
	assert(r2["xp"] == 2 and r2["coins"] == 0)
	assert(int(Profile.data["coins"]) == c0 + 1)
	var pf := ProfileScreen.new()
	add_child(pf)
	await get_tree().process_frame
	var ac := AchievementsScreen.new()
	add_child(ac)
	await get_tree().process_frame
	var jo := JourneyScreen.new()
	add_child(jo)
	await get_tree().process_frame
	var no := NotesScreen.new()
	add_child(no)
	await get_tree().process_frame
	var pl := PlaceholderScreen.new()
	pl.setup_screen("RANK", "teste", "user://layout_test.cfg", true)
	add_child(pl)
	await get_tree().process_frame
	m.queue_free()
	c.queue_free()
	a.queue_free()
	mk.queue_free()
	pf.queue_free()
	ac.queue_free()
	jo.queue_free()
	no.queue_free()
	pl.queue_free()
	print("ui: menu/config/arsenal/mercado/perfil/conquistas/jornada/notas OK")
	b.queue_free()
	print("== SMOKE TEST CONCLUÍDO ==")
	get_tree().quit(0 if _rules_ok else 1)
