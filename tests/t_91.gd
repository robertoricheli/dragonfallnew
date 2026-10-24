extends Node
## Teste 1.49.91: (1) status em campo = SOMENTE ícones pequenos no canto
## superior direito, empilhados na ordem de aquisição (sem redoma/caveira/
## bolhas/aura persistentes); (2) SEM HONRA: aliados só se reorganizam 0,5 s
## APÓS o fim da animação de morte especial.
## Rodar: godot --headless --path . res://tests/t_91.tscn

var _ok := true


func _fail(msg: String) -> void:
	_ok = false
	printerr("FALHA: " + msg)


func _ready() -> void:
	print("== T91 (1.49.91) ==")
	await _t_icons()
	await _t_desonra_reorg()
	print("== T91 %s ==" % ("OK" if _ok else "FALHOU"))
	get_tree().quit(0 if _ok else 1)


func _champ_card(uid: int) -> Dictionary:
	for d in CardDB.playable_defs():
		if String(d["category"]) == "champion":
			var c: Dictionary = d.duplicate(true)
			c["uid"] = uid
			c["current_power"] = int(c.get("power", 1))
			# zera TODO status para o teste controlar a ordem de aquisição
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


func _t_icons() -> void:
	var v := ChampionView.new()
	v.setup(_champ_card(9001), 0)
	add_child(v)
	await get_tree().process_frame
	# animações persistentes extintas NÃO existem mais no código
	if v.has_method("_set_furia") or v.has_method("_set_veneno"):
		_fail("aura/bolhas persistentes ainda existem como método")
	for prop in ["_prot", "_prot_shield", "_skull", "_veneno", "_furia_col"]:
		if prop in v:
			_fail("propriedade extinta ainda presente: " + prop)
	var c: Dictionary = v.card
	# 1º status: PROTEÇÃO -> ícone único no canto superior direito
	c["shield_turns"] = 1
	v.refresh()
	if v._status_order != ["prot"]:
		_fail("ordem [prot] != %s" % str(v._status_order))
	# 2º: ENVENENADO (abaixo do 1º)
	c["poison_turns"] = 2
	v.refresh()
	if v._status_order != ["prot", "veneno"]:
		_fail("ordem [prot,veneno] != %s" % str(v._status_order))
	# 3º: FÚRIA
	c["fury_turns"] = 2
	c["fury_stacks"] = 1
	v.refresh()
	if v._status_order != ["prot", "veneno", "furia"]:
		_fail("ordem [prot,veneno,furia] != %s" % str(v._status_order))
	# geometria: canto superior direito, pilha de cima para baixo
	for i in v._status_order.size():
		var ent: Dictionary = v._status_icons[v._status_order[i]]
		var ico: TextureRect = ent["ico"]
		if ico.position.x < 70.0 or ico.position.y < 0.0 or ico.position.y + ico.size.y > ChampionView.CHAMP_H - 3.0:
			_fail("ícone %s fora do canto superior direito: %s" % [v._status_order[i], ico.position])
		var want_y: float = 3.0 + i * ChampionView.STATUS_ICON_STEP + (ChampionView.STATUS_ICON_BG - ChampionView.STATUS_ICON_SZ) / 2.0
		if abs(ico.position.y - want_y) > 0.01:
			_fail("ícone %s na linha errada: y=%s want=%s" % [v._status_order[i], ico.position.y, want_y])
	# carta esverdeada continua (tinta do veneno, não é animação)
	if v.modulate != Color(0.84, 1.06, 0.86, 1.0):
		_fail("tinta verde do veneno sumiu: %s" % str(v.modulate))
	# status expirado sai da pilha e os de baixo sobem
	c["shield_turns"] = 0
	v.refresh()
	if v._status_order != ["veneno", "furia"]:
		_fail("ordem após expirar prot != %s" % str(v._status_order))
	var ent0: Dictionary = v._status_icons["veneno"]
	if abs((ent0["ico"] as TextureRect).position.y - (3.0 + (ChampionView.STATUS_ICON_BG - ChampionView.STATUS_ICON_SZ) / 2.0)) > 0.01:
		_fail("veneno não subiu para o topo após expirar prot")
	# SEM HONRA entra no fim da pilha
	c["on_destroy"] = "noHonor"
	v.refresh()
	if v._status_order != ["veneno", "furia", "semhonra"]:
		_fail("ordem com sem honra != %s" % str(v._status_order))
	# sem nós de aura/bolhas como filhos (só ícones + camadas fixas)
	for ch in v.get_children():
		if ch is Sprite2D:
			_fail("Sprite2D persistente (bolha/aura) encontrado em campo")
	print("ícones de status no canto superior direito: OK")
	v.queue_free()
	await get_tree().process_frame


func _t_desonra_reorg() -> void:
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
	# 3 campeões do jogador em campo (views criadas e assentadas)
	var uids: Array = []
	for i in range(st.players[0]["deck"].size()):
		if uids.size() >= 3:
			break
		if String(st.players[0]["deck"][i]["category"]) == "champion":
			var c: Dictionary = st.players[0]["deck"][i]
			uids.append(int(c["uid"]))
			st.players[0]["field"].append(c)
			b._on_champion_summoned(0, c)
	if uids.size() != 3:
		_fail("não conseguiu 3 campeões p/ teste de reorganização")
		return
	b._layout_field(0)
	await get_tree().create_timer(1.6).timeout
	var pos0: Dictionary = {}
	for u in uids:
		var vv: ChampionView = b.champ_views.get(int(u))
		if vv == null:
			_fail("view do campeão %s não existe" % u)
			return
		pos0[int(u)] = vv.position
	# destrói o do MEIO com SEM HONRA (como em combate)
	var dead_uid: int = int(uids[1])
	var dead_card: Dictionary = st.players[0]["field"][1]
	b._death_style[dead_uid] = "semhonra"
	st.players[0]["field"].remove_at(1)
	b._on_champion_destroyed(0, dead_card, "combate", false)
	await b._on_field_changed(0)
	# 1,4 s depois (o reajuste ANTIGO aconteceria aqui): NADA se move
	await get_tree().create_timer(1.4).timeout
	for u in [uids[0], uids[2]]:
		var vv: ChampionView = b.champ_views.get(int(u))
		if vv == null or (vv.position - (pos0[int(u)] as Vector2)).length() > 1.0:
			_fail("aliado se reorganizou ANTES da animação do sem honra")
	# roda a morte especial (VFX de 2 s)
	b._finish_desonra(dead_uid)
	await get_tree().create_timer(2.2).timeout
	for u in [uids[0], uids[2]]:
		var vv: ChampionView = b.champ_views.get(int(u))
		if vv == null or (vv.position - (pos0[int(u)] as Vector2)).length() > 1.0:
			_fail("aliado se reorganizou DURANTE a animação do sem honra")
	# 0,5 s após o fim do VFX (2,0 s) + deslize (0,45 s): reorganizado
	await get_tree().create_timer(1.0).timeout
	for i in 2:
		var u: int = int(uids[0] if i == 0 else uids[2])
		var vv: ChampionView = b.champ_views.get(u)
		var want: Vector2 = b._slot_for(0, i, 2)
		if vv == null:
			_fail("view sumiu após reorganização")
		elif (vv.position - want).length() > 4.0:
			_fail("reorganização não centralizou: %s != %s" % [vv.position, want])
	print("reorganização 0,5 s após a morte do SEM HONRA: OK")
	b.queue_free()
