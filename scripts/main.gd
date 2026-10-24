extends Control
## Raiz: Menu(Hub) → Config → Batalha | Arsenal | Mercado | telas de meta
## (Perfil, Conquistas, Jornada, Notas, RANK/PASSE/HISTÓRIA/COMO JOGAR/OPÇÕES).

var last_opts := {}
var meta_stack := []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_show_menu()


func _clear() -> void:
	_clear_meta()
	for c in get_children():
		remove_child(c)
		c.queue_free()


func _clear_meta() -> void:
	for n in meta_stack:
		if is_instance_valid(n):
			n.queue_free()
	meta_stack.clear()


func _show_menu(page: int = 0) -> void:
	_clear()
	var m := MenuScreen.new()
	m.config_requested.connect(_show_config)
	m.arsenal_requested.connect(_show_arsenal)
	m.market_requested.connect(_show_market)
	m.meta_requested.connect(_open_meta)
	add_child(m)
	if page == 1:
		m.show_hub()


func _show_config() -> void:
	_clear()
	var c := ConfigScreen.new()
	c.start_match.connect(_show_battle)
	c.back_requested.connect(func() -> void: _show_menu(1))
	add_child(c)


func _show_arsenal() -> void:
	_clear()
	var a := ArsenalScreen.new()
	a.back_requested.connect(func() -> void: _show_menu(1))
	add_child(a)


func _show_market() -> void:
	_clear()
	var mk := MarketScreen.new()
	mk.back_requested.connect(func() -> void: _show_menu(1))
	add_child(mk)


func _show_battle(opts: Dictionary = {}) -> void:
	last_opts = opts
	_clear()
	var b := BattleScreen.new()
	b.match_opts = opts
	b.exit_to_menu.connect(func() -> void: _show_menu(1))
	b.restart_requested.connect(func() -> void: _show_battle(last_opts))
	add_child(b)


func _open_meta(which: String) -> void:
	var scr: Control = null
	match which:
		"profile":
			scr = ProfileScreen.new()
			(scr as ProfileScreen).open_achievements.connect(func() -> void: _open_meta("achievements"))
			(scr as ProfileScreen).open_journey.connect(func() -> void: _open_meta("journey"))
			(scr as ProfileScreen).open_options.connect(func() -> void: _open_meta("options"))
		"achievements":
			scr = AchievementsScreen.new()
		"journey":
			scr = JourneyScreen.new()
		"notes":
			scr = NotesScreen.new()
		"rank":
			scr = PlaceholderScreen.new()
			(scr as PlaceholderScreen).setup_screen("RANK", "Ranqueado online em construção. O rank local por % de vitórias já aparece no Perfil.", "user://layout_rank.cfg", true)
		"passe":
			scr = PlaceholderScreen.new()
			(scr as PlaceholderScreen).setup_screen("PASSE DE BATALHA", "Em construção — em breve!", "user://layout_passe.cfg")
		"history":
			scr = PlaceholderScreen.new()
			(scr as PlaceholderScreen).setup_screen("HISTÓRIA", "Em construção — em breve!", "user://layout_history.cfg")
		"howto":
			scr = PlaceholderScreen.new()
			(scr as PlaceholderScreen).setup_screen("COMO JOGAR", "Em construção — em breve! (veja o README e o Manual de Regras)", "user://layout_howto.cfg")
		"options":
			scr = PlaceholderScreen.new()
			(scr as PlaceholderScreen).setup_screen("OPÇÕES", "Ajustes de áudio/vídeo em construção. O Editor de Layout está no botão EDITOR.", "user://layout_options.cfg")
	if scr == null:
		return
	scr.back_requested.connect(_pop_meta)
	add_child(scr)
	meta_stack.append(scr)


func _pop_meta() -> void:
	if meta_stack.is_empty():
		return
	var n: Control = meta_stack.pop_back()
	if is_instance_valid(n):
		n.queue_free()
