extends Node
## Teste 1.49.99: (1) PARIDADE IA/jogador: a invocação da IA usa o MESMO
## processo do jogador (queda + impacto, visível em < 0,5 s — sem voo especial
## da mão) e o Talento idem; (2) ASSASSINAR: destruição ESPECIAL — adaga
## aparece 0,5 s após a escolha, corta a carta ao meio e ela se desfaz em
## pedaços (view oculta no corte e liberada ao fim, ~2,5 s); (3) ÁUDIO: 26
## chaves de SFX carregadas no autoload e play() seguro headless.
## Rodar: godot --headless --path . res://tests/t_97.tscn

var _ok := true

const ASS := preload("res://scripts/vfx_assassinar.gd")


func _fail(msg: String) -> void:
	_ok = false
	printerr("FALHA: " + msg)


func _ready() -> void:
	print("== T97 (1.49.99) ==")
	_t_sfx26()
	await _t_paridade_invocacao()
	await _t_assassinar()
	print("== T97 %s ==" % ("OK" if _ok else "FALHOU"))
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


func _t_sfx26() -> void:
	var sfx := get_node_or_null("/root/Sfx")
	if sfx == null:
		_fail("autoload Sfx ausente")
		return
	if (sfx.KEYS as Dictionary).size() != 31:
		_fail("Sfx: %d chaves (esperado 31)" % (sfx.KEYS as Dictionary).size())
	for k in sfx.KEYS:
		if sfx._streams.get(k) == null:
			_fail("Sfx: stream ausente: %s" % k)
		sfx.play(k, 640.0, 0.4)
	print("SFX v2: 31 sons carregados e play() seguro: OK")


func _t_paridade_invocacao() -> void:
	var b := _mk_battle()
	await get_tree().process_frame
	await get_tree().process_frame
	var st: GameState = b.state
	# IA invoca: a view deve ficar VISÍVEL logo (mesmo processo do jogador),
	# sem o antigo voo de 1,05 s da mão da IA
	var ak := _card(st, "AKASHA", "", 1)
	st.players[1]["field"].append(ak)
	b._on_champion_summoned(1, ak)
	b._layout_field(1)
	await get_tree().create_timer(0.45).timeout
	var v: ChampionView = b.champ_views.get(int(ak["uid"]))
	if v == null or not v.visible:
		_fail("paridade: invocação da IA não usou o processo do jogador (view oculta em 0,45 s)")
	# jogador invoca: mesmo caminho
	var ol := _card(st, "OLAF", "", 0)
	st.players[0]["field"].append(ol)
	b._on_champion_summoned(0, ol)
	b._layout_field(0)
	await get_tree().create_timer(0.45).timeout
	var v2: ChampionView = b.champ_views.get(int(ol["uid"]))
	if v2 == null or not v2.visible:
		_fail("paridade: invocação do jogador não visível em 0,45 s")
	b.queue_free()
	print("PARIDADE invocação IA/jogador (mesmo processo): OK")


func _t_assassinar() -> void:
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
	# (1.50.2) MIRA com escolha: Poder 1 destacado e o jogador confirma o alvo
	st._resolve_on_enter_named(0, as_, "assassinar")
	if st.targeting.is_empty():
		_fail("assassinar: mira não abriu para escolha")
	elif not (st.targeting["candidates"] as Array).has(int(tgt["uid"])):
		_fail("assassinar: alvo P1 não está entre os candidatos")
	st.confirm_targeting(int(tgt["uid"]))
	# (1.50.1) a animação só inicia 0,5 s após a escolha
	await get_tree().create_timer(0.3).timeout
	for ch in b.fx_layer.get_children():
		if ch is ASS:
			_fail("assassinar: animação iniciou ANTES dos 0,5 s")
	await get_tree().create_timer(0.45).timeout
	var fx: Node = null
	for ch in b.fx_layer.get_children():
		if ch is ASS:
			fx = ch
	if fx == null:
		_fail("assassinar: fx da adaga não apareceu")
		b.queue_free()
		return
	# no corte (0,62 s) a carta some da tela
	await get_tree().create_timer(0.6).timeout
	var vt: ChampionView = fx._view
	if is_instance_valid(vt) and vt.visible:
		_fail("assassinar: carta não foi ocultada no corte")
	# ao fim (~2,5 s) a view é liberada
	await get_tree().create_timer(2.2).timeout
	if is_instance_valid(vt):
		_fail("assassinar: view não liberada ao fim da destruição especial")
	b.queue_free()
	print("ASSASSINAR: adaga 0,5 s + corte ao meio + pedaços (2,0 s): OK")
