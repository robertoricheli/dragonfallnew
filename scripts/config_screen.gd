class_name ConfigScreen
extends Control
## Tela de configuração da partida (botão JOGAR): objetivo (10/15 PV),
## baralho (aleatório de 20 ou um dos 5 do Arsenal) e herói.

signal start_match(opts)
signal back_requested

var win_points := 15
var deck_choice := -1          # -1 = aleatório 20 | 0..4 = baralho do Arsenal
var hero_idx := 0
var decks: Array = []
var ed: ScreenEditor
var ed_btn: Button
var title_lbl: Label
var cont_obj: Control
var cont_deck: Control
var heroes_scroll: Control
var obj_btns := []
var deck_btns := []
var hero_tiles := []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.045, 0.11)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	add_child(bg)
	decks = DeckStore.load_decks()
	hero_idx = randi() % CardDB.HEROES.size()

	var t := Label.new()
	title_lbl = t
	t.text = "CONFIGURAR PARTIDA"
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector2(340, 18)
	t.size = Vector2(600, 40)
	add_child(t)

	# ---- objetivo ----
	_sec(30, 76, "OBJETIVO DA PARTIDA")
	obj_btns.append(_opt_btn(Vector2(40, 104), Vector2(150, 44), "10 PV", 0))
	obj_btns.append(_opt_btn(Vector2(200, 104), Vector2(150, 44), "15 PV", 1))

	# ---- baralho ----
	_sec(400, 76, "SEU BARALHO")
	deck_btns.append(_opt_btn(Vector2(410, 104), Vector2(230, 44), "Aleatório (20 cartas)", -1))
	for i in 5:
		var d: Dictionary = decks[i]
		var b := _opt_btn(Vector2(650 + (i % 3) * 190, 104 + (i / 3) * 50), Vector2(180, 44), "%d: %s (%d)" % [i + 1, String(d["name"]).substr(0, 10), (d["cards"] as Array).size()], i)
		if (d["cards"] as Array).size() < 10:
			b.disabled = true
		deck_btns.append(b)

	# ---- heróis ----
	_sec(30, 210, "ESCOLHA SEU HERÓI")
	var scroll := ScrollContainer.new()
	heroes_scroll = scroll
	scroll.position = Vector2(40, 240)
	scroll.size = Vector2(1200, 330)
	add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	for i in CardDB.HEROES.size():
		var h: Dictionary = CardDB.HEROES[i]
		var tile := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.12, 0.1, 0.2, 0.9)
		sb.border_color = Color(0.4, 0.36, 0.55)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		tile.add_theme_stylebox_override("panel", sb)
		tile.custom_minimum_size = Vector2(160, 130)
		tile.mouse_filter = Control.MOUSE_FILTER_STOP
		tile.gui_input.connect(_on_hero_click.bind(i))
		grid.add_child(tile)
		hero_tiles.append(tile)
		var med := Panel.new()
		var msb := StyleBoxFlat.new()
		msb.bg_color = Color.from_hsv(fmod(float(hash(h["id"]) % 360) / 360.0, 1.0), 0.55, 0.35)
		msb.set_corner_radius_all(10)
		msb.border_color = Color(0.85, 0.7, 0.35)
		msb.set_border_width_all(2)
		med.add_theme_stylebox_override("panel", msb)
		med.position = Vector2(44, 8)
		med.size = Vector2(72, 72)
		med.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(med)
		var ini := Label.new()
		var words := String(h["name"]).split(" ")
		ini.text = (String(words[0]).left(1) + (String(words[words.size() - 1]).left(1) if words.size() > 1 else "")).to_upper()
		ini.add_theme_font_size_override("font_size", 22)
		ini.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
		ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ini.position = Vector2.ZERO
		ini.size = Vector2(1280, 720)
		ini.mouse_filter = Control.MOUSE_FILTER_IGNORE
		med.add_child(ini)
		var nm := Label.new()
		nm.text = String(h["name"])
		nm.add_theme_font_size_override("font_size", 10)
		nm.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.clip_text = true
		nm.position = Vector2(4, 84)
		nm.size = Vector2(152, 14)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(nm)
		var ul := Label.new()
		ul.text = String(h["ult"])
		ul.add_theme_font_size_override("font_size", 8)
		ul.add_theme_color_override("font_color", Color(0.7, 0.68, 0.8))
		ul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ul.clip_text = true
		ul.position = Vector2(4, 100)
		ul.size = Vector2(152, 12)
		ul.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(ul)
		var ds := Label.new()
		ds.text = String(h["ult_desc"]).substr(0, 60)
		ds.add_theme_font_size_override("font_size", 7)
		ds.add_theme_color_override("font_color", Color(0.6, 0.58, 0.7))
		ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ds.clip_text = true
		ds.position = Vector2(4, 114)
		ds.size = Vector2(152, 12)
		ds.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(ds)

	# ---- ações ----
	var adv := Button.new()
	adv.text = "AVANÇAR ▶"
	adv.position = Vector2(540, 640)
	adv.size = Vector2(200, 56)
	_style(adv, Color(0.18, 0.42, 0.24), 20)
	adv.pressed.connect(_advance)
	add_child(adv)
	var bk := Button.new()
	bk.text = "VOLTAR"
	bk.position = Vector2(30, 640)
	bk.size = Vector2(140, 56)
	_style(bk, Color(0.28, 0.25, 0.38), 16)
	bk.pressed.connect(func() -> void: back_requested.emit())
	add_child(bk)
	cont_obj = Control.new()
	cont_obj.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cont_obj)
	for b in obj_btns:
		var bp2: Vector2 = b.position
		remove_child(b)
		cont_obj.add_child(b)
		b.position = bp2
	cont_deck = Control.new()
	cont_deck.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cont_deck)
	for b in deck_btns:
		var bp3: Vector2 = b.position
		remove_child(b)
		cont_deck.add_child(b)
		b.position = bp3
	ed_btn = Button.new()
	ed_btn.text = "EDITOR"
	ed_btn.position = Vector2(12, 10)
	ed_btn.size = Vector2(110, 42)
	_style(ed_btn, Color(0.2, 0.32, 0.3), 13)
	add_child(ed_btn)
	ed = ScreenEditor.new()
	add_child(ed)
	ed.setup({
		"editorbtn": ed_btn,
		"title": title_lbl,
		"obj": cont_obj,
		"deck": cont_deck,
		"heroes": heroes_scroll,
		"avancar": adv,
		"voltar": bk,
	}, {
		"editorbtn": Rect2(12, 10, 110, 42),
		"title": Rect2(340, 18, 600, 40),
		"obj": Rect2(30, 76, 330, 80),
		"deck": Rect2(400, 76, 830, 110),
		"heroes": Rect2(40, 240, 1200, 330),
		"avancar": Rect2(540, 640, 200, 56),
		"voltar": Rect2(30, 640, 140, 56),
	}, "user://layout_config.cfg")
	_refresh()


func _sec(x: float, y: float, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	l.position = Vector2(x, y)
	l.size = Vector2(400, 20)
	add_child(l)


func _opt_btn(pos: Vector2, sz: Vector2, text: String, tag: int) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = sz
	_style(b, Color(0.2, 0.24, 0.4), 12)
	b.pressed.connect(func() -> void:
		if tag == -2:
			return
		if b in obj_btns:
			win_points = 10 if tag == 0 else 15
		else:
			deck_choice = tag
		_refresh())
	b.set_meta("tag", tag)
	add_child(b)
	return b


func _on_hero_click(ev: InputEvent, i: int) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		hero_idx = i
		_refresh()


func _refresh() -> void:
	for b in obj_btns:
		var tag: int = int(b.get_meta("tag"))
		_mark(b, (tag == 0 and win_points == 10) or (tag == 1 and win_points == 15))
	for b in deck_btns:
		var tag: int = int(b.get_meta("tag"))
		_mark(b, tag == deck_choice)
	for i in hero_tiles.size():
		var sb: StyleBoxFlat = hero_tiles[i].get_theme_stylebox("panel")
		if i == hero_idx:
			sb.border_color = Color(1, 0.85, 0.4)
			sb.set_border_width_all(3)
		else:
			sb.border_color = Color(0.4, 0.36, 0.55)
			sb.set_border_width_all(2)


func _mark(b: Button, on: bool) -> void:
	var sb: StyleBoxFlat = b.get_theme_stylebox("normal")
	if on:
		sb.bg_color = Color(0.35, 0.55, 0.25)
		sb.border_color = Color(1, 0.9, 0.5)
		sb.set_border_width_all(2)
	else:
		sb.bg_color = Color(0.2, 0.24, 0.4)
		sb.border_color = Color(0.2, 0.24, 0.4).lightened(0.35)
		sb.set_border_width_all(1)


func _style(b: Button, bg: Color, fs: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = bg.lightened(0.4)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	b.add_theme_stylebox_override("normal", sb)
	var hov := sb.duplicate() as StyleBoxFlat
	hov.bg_color = bg.lightened(0.16)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", hov)
	b.add_theme_color_override("font_color", Color(0.97, 0.95, 0.9))
	b.add_theme_font_size_override("font_size", fs)


func _advance() -> void:
	var opts := {
		"win_points": win_points,
		"deck_a": (decks[deck_choice]["cards"] if deck_choice >= 0 else []),
		"hero_id": String(CardDB.HEROES[hero_idx]["id"]),
	}
	start_match.emit(opts)
