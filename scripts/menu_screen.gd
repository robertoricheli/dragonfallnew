class_name MenuScreen
extends Control
## Tela inicial: PLAY → três botões (JOGAR, MERCADO, ARSENAL).
## MERCADO e ARSENAL entram como telas de "em construção" (fase focada no JOGAR).

signal play_requested
signal config_requested
signal arsenal_requested
signal market_requested
signal meta_requested(which)

var _pages: Array = []
var bg: ColorRect
var play_ref: Control
var title_ref: Control
var jogar_ref: Control
var mercado_ref: Control
var arsenal_ref: Control
var voltar_ref: Control
var soon_panel_ref: Control
var voltar_soon_ref: Control
var icons_container: Control
var ed: ScreenEditor
var icon_btns := []
var icon_rects := []
var profile_widget: Control
var prof_avatar: Panel
var prof_ini: Label
var prof_name: Label
var prof_xp: Label
var mode_ia_ref: Control
var mode_mp_ref: Control
var mode_lbl: Label
var ed_btn_ref: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	bg = ColorRect.new()
	bg.color = Color(0.07, 0.05, 0.12)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	add_child(bg)
	_build_title_page()
	_build_menu_page()
	_build_soon_page()
	_build_mode_page()
	_show_page(0)
	var eb := Button.new()
	eb.text = "EDITOR"
	ed_btn_ref = eb
	eb.position = Vector2(12, 10)
	eb.size = Vector2(112, 42)
	var esb := StyleBoxFlat.new()
	esb.bg_color = Color(0.2, 0.32, 0.3)
	esb.border_color = Color(0.2, 0.32, 0.3).lightened(0.4)
	esb.set_border_width_all(1)
	esb.set_corner_radius_all(8)
	eb.add_theme_stylebox_override("normal", esb)
	eb.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
	eb.add_theme_font_size_override("font_size", 13)
	add_child(eb)
	eb.visible = false  # a capa não mostra o EDITOR
	ed = ScreenEditor.new()
	add_child(ed)
	var groups := {
		"editorbtn": eb,
		"play_btn": play_ref,
		"jogar": jogar_ref,
		"mercado": mercado_ref,
		"arsenal": arsenal_ref,
		"voltar_menu": voltar_ref,
		"voltar_soon": voltar_soon_ref,
		"mode_ia": mode_ia_ref,
		"mode_mp": mode_mp_ref,
		"profile": profile_widget,
	}
	var rects := {
		"editorbtn": Rect2(12, 10, 112, 42),
		"play_btn": Rect2(481, 554, 325, 166),
		"jogar": Rect2(450, 220, 380, 72),
		"mercado": Rect2(450, 330, 380, 72),
		"arsenal": Rect2(450, 440, 380, 72),
		"voltar_menu": Rect2(540, 560, 200, 48),
		"voltar_soon": Rect2(540, 400, 200, 48),
		"mode_ia": Rect2(450, 260, 380, 72),
		"mode_mp": Rect2(450, 370, 380, 72),
		"profile": Rect2(1020, 6, 250, 56),
	}
	# (1.49.83) cada ícone do hub é um elemento INDIVIDUAL no editor
	for i in icon_btns.size():
		groups["icon_%d" % i] = icon_btns[i]
		rects["icon_%d" % i] = icon_rects[i]
	ed.setup(groups, rects, "user://layout_menu.cfg")
	ed.toggled.connect(func(a: bool) -> void:
		if a:
			pass)
	eb.pressed.connect(func() -> void: ed.toggle())


func _deco(parent: Control, pos: Vector2, sz: float, col: Color) -> void:
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 10:
		var r: float = sz if i % 2 == 0 else sz * 0.45
		var ang: float = TAU * float(i) / 10.0 - PI / 2.0
		pts.append(Vector2(cos(ang), sin(ang)) * r)
	poly.polygon = pts
	poly.color = col
	poly.position = pos
	parent.add_child(poly)


func _big_button(parent: Control, pos: Vector2, sz: Vector2, text: String, sub: String, bg: Color, font_size: int = 22) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = sz
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = bg.lightened(0.4)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	var hov := sb.duplicate() as StyleBoxFlat
	hov.bg_color = bg.lightened(0.16)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", hov)
	b.add_theme_color_override("font_color", Color(0.98, 0.96, 0.9))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_font_size_override("font_size", font_size)
	parent.add_child(b)
	if sub != "":
		var l := Label.new()
		l.text = sub
		l.add_theme_font_size_override("font_size", 10)
		l.add_theme_color_override("font_color", Color(0.62, 0.6, 0.75))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.position = Vector2(pos.x, pos.y + sz.y + 4)
		l.size = Vector2(sz.x, 14)
		parent.add_child(l)
	return b


func _title_label(parent: Control, text: String, pos: Vector2, sz: Vector2, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = pos
	l.size = sz
	parent.add_child(l)
	return l


func _page() -> Control:
	var c := Control.new()
	c.position = Vector2.ZERO
	c.size = Vector2(1280, 720)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	_pages.append(c)
	return c


func _build_title_page() -> void:
	# Tela inicial: SOMENTE a capa ("CAPA DO JOGO NOVA") + botão PLAY
	# posicionado exatamente sobre o botão de pedra da arte.
	var p := _page()
	var tex: Texture2D = null
	if ResourceLoader.exists("res://assets/CAPA_DO_JOGO_NOVA.png"):
		tex = load("res://assets/CAPA_DO_JOGO_NOVA.png")
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.position = Vector2.ZERO
		tr.size = Vector2(1280, 720)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(tr)
		# recorte profissional do botão de pedra da arte (normais medidos)
		var iw: float = tex.get_width()
		var ih: float = tex.get_height()
		var sc: float = 1280.0 / iw  # capa em STRETCH_SCALE: mapeia 1:1 no canvas
		var sy: float = 720.0 / ih
		var rx: float = 1190.0 * sc
		var ry: float = 1035.0 * sy
		var rw: float = 805.0 * sc
		var rh: float = 309.0 * sy
		play_ref = Control.new()
		play_ref.position = Vector2(rx, ry)
		play_ref.size = Vector2(rw, rh)
		play_ref.pivot_offset = Vector2(rw / 2.0, rh / 2.0)
		play_ref.mouse_filter = Control.MOUSE_FILTER_STOP
		p.add_child(play_ref)
		var btex: Texture2D = load("res://assets/BTN_PLAY.png") if ResourceLoader.exists("res://assets/BTN_PLAY.png") else null
		if btex != null:
			var btr := TextureRect.new()
			btr.texture = btex
			btr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			btr.stretch_mode = TextureRect.STRETCH_SCALE
			btr.position = Vector2.ZERO
			btr.size = Vector2(rw, rh)
			btr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			play_ref.add_child(btr)
		var pl := Label.new()
		pl.text = "PLAY"
		pl.add_theme_font_size_override("font_size", int(rh * 0.40))
		if CardArt.heavy_font() != null:
			pl.add_theme_font_override("font", CardArt.heavy_font())
		pl.add_theme_color_override("font_color", Color(1, 0.9, 0.45))
		pl.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.02, 0.95))
		pl.add_theme_constant_override("outline_size", 10)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pl.position = Vector2(0, rh * 0.06)
		pl.size = Vector2(rw, rh * 0.72)
		pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		play_ref.add_child(pl)
		play_ref.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
				if ev.pressed:
					_play_zoom(0.94)
				else:
					_play_zoom(1.0)
					_show_page(1))
		play_ref.mouse_entered.connect(func() -> void: _play_zoom(1.05))
		play_ref.mouse_exited.connect(func() -> void: _play_zoom(1.0))
	else:
		play_ref = _big_button(p, Vector2(500, 420), Vector2(280, 78), "PLAY", "", Color(0.55, 0.38, 0.12), 30)
		play_ref.pressed.connect(func(): _show_page(1))


func _build_menu_page() -> void:
	var p := _page()
	# ícones pequenos do Hub (8 atalhos)
	var icons := [
		["options", "OPÇÕES", false],
		["journey", "JORNADA", false],
		["rank", "RANK *", true],
		["passe", "PASSE *", true],
		["achievements", "CONQUISTAS", false],
		["history", "HISTÓRIA *", true],
		["howto", "COMO JOGAR *", true],
		["notes", "NOTAS", false],
	]
	icons_container = Control.new()
	icons_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(icons_container)
	for i in icons.size():
		var b := _big_button(icons_container, Vector2(30 + i * 122, 64), Vector2(116, 54), icons[i][1], "", Color(0.22, 0.2, 0.32) if not icons[i][2] else Color(0.18, 0.17, 0.24), 9)
		icon_btns.append(b)
		icon_rects.append(Rect2(30 + i * 122, 64, 116, 54))
		var which: String = icons[i][0]
		b.pressed.connect(func() -> void: meta_requested.emit(which))
	# widget de PERFIL do jogador (canto superior direito)
	profile_widget = Control.new()
	profile_widget.mouse_filter = Control.MOUSE_FILTER_STOP
	profile_widget.position = Vector2(1020, 6)
	profile_widget.size = Vector2(250, 56)
	p.add_child(profile_widget)
	prof_avatar = Panel.new()
	prof_avatar.position = Vector2(0, 4)
	prof_avatar.size = Vector2(48, 48)
	profile_widget.add_child(prof_avatar)
	prof_ini = Label.new()
	prof_ini.add_theme_font_size_override("font_size", 16)
	prof_ini.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	prof_ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prof_ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prof_ini.set_anchors_preset(Control.PRESET_FULL_RECT)
	prof_ini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prof_avatar.add_child(prof_ini)
	prof_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prof_name = Label.new()
	prof_name.add_theme_font_size_override("font_size", 13)
	prof_name.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	prof_name.position = Vector2(56, 6)
	prof_name.size = Vector2(190, 18)
	prof_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_widget.add_child(prof_name)
	prof_xp = Label.new()
	prof_xp.add_theme_font_size_override("font_size", 10)
	prof_xp.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	prof_xp.position = Vector2(56, 28)
	prof_xp.size = Vector2(190, 16)
	prof_xp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_widget.add_child(prof_xp)
	profile_widget.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			meta_requested.emit("profile"))
	_refresh_profile_widget()
	_title_label(p, "DRAGONFALL", Vector2(390, 128), Vector2(500, 56), 38, Color(0.95, 0.78, 0.35))
	var jogar := _big_button(p, Vector2(450, 220), Vector2(380, 72), "JOGAR", "", Color(0.18, 0.42, 0.24))
	jogar_ref = jogar
	jogar.pressed.connect(func(): _show_page(3))
	var mercado := _big_button(p, Vector2(450, 330), Vector2(380, 72), "MERCADO", "", Color(0.16, 0.32, 0.5))
	mercado_ref = mercado
	mercado.pressed.connect(func(): market_requested.emit())
	var arsenal := _big_button(p, Vector2(450, 440), Vector2(380, 72), "ARSENAL", "", Color(0.36, 0.24, 0.5))
	arsenal_ref = arsenal
	arsenal.pressed.connect(func(): arsenal_requested.emit())
	var voltar := _big_button(p, Vector2(540, 560), Vector2(200, 48), "VOLTAR", "", Color(0.28, 0.25, 0.38), 15)
	voltar_ref = voltar
	voltar.pressed.connect(func(): _show_page(0))


func _build_soon_page() -> void:
	var p := _page()
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.08, 0.17, 0.97)
	sb.border_color = Color(0.85, 0.68, 0.3)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(390, 200)
	panel.size = Vector2(500, 280)
	p.add_child(panel)
	soon_panel_ref = panel
	var t := Label.new()
	t.name = "SoonTitle"
	t.add_theme_font_size_override("font_size", 28)
	t.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector2(0, 34)
	t.size = Vector2(500, 40)
	panel.add_child(t)
	var d := Label.new()
	d.name = "SoonDesc"
	d.add_theme_font_size_override("font_size", 14)
	d.add_theme_color_override("font_color", Color(0.8, 0.78, 0.88))
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.position = Vector2(30, 96)
	d.size = Vector2(440, 70)
	panel.add_child(d)
	var v := _big_button(p, Vector2(540, 400), Vector2(200, 48), "VOLTAR", "", Color(0.28, 0.25, 0.38), 15)
	voltar_soon_ref = v
	v.pressed.connect(func(): _show_page(1))


func _build_mode_page() -> void:
	var p := _page()
	_title_label(p, "ESCOLHA O MODO", Vector2(390, 150), Vector2(500, 50), 30, Color(0.95, 0.78, 0.35))
	mode_ia_ref = _big_button(p, Vector2(450, 260), Vector2(380, 72), "JOGADOR CONTRA IA", "", Color(0.18, 0.42, 0.24))
	mode_ia_ref.pressed.connect(func(): config_requested.emit())
	mode_mp_ref = _big_button(p, Vector2(450, 370), Vector2(380, 72), "MULTIPLAYER ONLINE", "", Color(0.16, 0.32, 0.5))
	mode_mp_ref.pressed.connect(func():
		mode_lbl.text = "Multiplayer online: em configuração futura.")
	mode_lbl = Label.new()
	mode_lbl.add_theme_font_size_override("font_size", 12)
	mode_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	mode_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_lbl.position = Vector2(340, 460)
	mode_lbl.size = Vector2(600, 20)
	p.add_child(mode_lbl)
	var voltar := _big_button(p, Vector2(540, 520), Vector2(200, 48), "VOLTAR", "", Color(0.28, 0.25, 0.38), 15)
	voltar.pressed.connect(func(): _show_page(1))


func _show_soon(title: String, desc: String) -> void:
	var panel: Control = _pages[2]
	# encontra o painel e ajusta textos
	for c in panel.get_children():
		if c is Panel:
			for cc in c.get_children():
				if cc.name == "SoonTitle":
					(cc as Label).text = title
				elif cc.name == "SoonDesc":
					(cc as Label).text = desc
	_show_page(2)


func _play_zoom(scl: float) -> void:
	if play_ref == null or not is_instance_valid(play_ref):
		return
	var tw := play_ref.create_tween()
	tw.tween_property(play_ref, "scale", Vector2(scl, scl), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func show_hub() -> void:
	_refresh_profile_widget()
	_show_page(1)


func _refresh_profile_widget() -> void:
	if prof_avatar == null:
		return
	Profile.ensure()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Profile.avatar_color()
	var fr: Dictionary = Profile.frame_style()
	sb.border_color = fr["color"]
	sb.set_border_width_all(int(fr["w"]))
	sb.set_corner_radius_all(12)
	prof_avatar.add_theme_stylebox_override("panel", sb)
	prof_ini.text = Profile.initials_of(Profile.player_name())
	prof_name.text = Profile.player_name()
	prof_xp.text = "XP %d  •  Nível %d  •  %d moedas" % [Profile.data["xp"], Profile.level(), Profile.data["coins"]]


func _show_page(i: int) -> void:
	for k in _pages.size():
		_pages[k].visible = (k == i)
	if ed_btn_ref != null:
		ed_btn_ref.visible = (i != 0)
	# (1.49.85) o editor só destaca elementos da tela/página ATUAL
	if ed != null and is_instance_valid(ed):
		ed._update_highlights()
