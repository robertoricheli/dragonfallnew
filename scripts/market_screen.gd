class_name MarketScreen
extends Control
## MERCADO: ofertas de cartas compráveis com moedas (baseado no df-market
## do projeto original do GitHub). Ofertas persistidas no Perfil.

signal back_requested

var ed: ScreenEditor
var ed_btn: Button
var title_lbl: Label
var coins_lbl: Label
var xp_lbl: Label
var reroll_btn: Button
var voltar_btn: Button
var content: Control
var flash_lbl: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.05, 0.12)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	add_child(bg)
	Profile.ensure()
	Profile.ensure_offers()
	title_lbl = Label.new()
	title_lbl.text = "MERCADO"
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.position = Vector2(440, 14)
	title_lbl.size = Vector2(400, 40)
	add_child(title_lbl)
	coins_lbl = Label.new()
	coins_lbl.add_theme_font_size_override("font_size", 16)
	coins_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	coins_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins_lbl.position = Vector2(940, 20)
	coins_lbl.size = Vector2(200, 22)
	add_child(coins_lbl)
	xp_lbl = Label.new()
	xp_lbl.add_theme_font_size_override("font_size", 12)
	xp_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	xp_lbl.position = Vector2(940, 44)
	xp_lbl.size = Vector2(200, 18)
	add_child(xp_lbl)
	voltar_btn = _btn(Vector2(30, 16), Vector2(140, 44), "VOLTAR", Color(0.28, 0.25, 0.38), 15)
	voltar_btn.pressed.connect(func() -> void: back_requested.emit())
	add_child(voltar_btn)
	reroll_btn = _btn(Vector2(30, 660), Vector2(260, 44), "TROCAR OFERTAS (1 moeda)", Color(0.4, 0.32, 0.18), 12)
	reroll_btn.pressed.connect(func() -> void:
		if Profile.reroll():
			_rebuild()
		else:
			_flash("Moedas insuficientes!"))
	add_child(reroll_btn)
	flash_lbl = Label.new()
	flash_lbl.add_theme_font_size_override("font_size", 13)
	flash_lbl.add_theme_color_override("font_color", Color(1, 0.5, 0.4))
	flash_lbl.position = Vector2(310, 672)
	flash_lbl.size = Vector2(400, 20)
	add_child(flash_lbl)
	content = Control.new()
	content.position = Vector2.ZERO
	content.size = Vector2(1280, 720)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	ed_btn = _btn(Vector2(1150, 16), Vector2(110, 40), "EDITOR", Color(0.2, 0.32, 0.3), 13)
	add_child(ed_btn)
	ed = ScreenEditor.new()
	add_child(ed)
	ed.setup({
		"editorbtn": ed_btn,
		"title": title_lbl,
		"coins": coins_lbl,
		"voltar": voltar_btn,
		"reroll": reroll_btn,
	}, {
		"editorbtn": Rect2(1150, 16, 110, 40),
		"title": Rect2(440, 14, 400, 40),
		"coins": Rect2(940, 20, 200, 22),
		"voltar": Rect2(30, 16, 140, 44),
		"reroll": Rect2(30, 660, 260, 44),
	}, "user://layout_market.cfg")
	ed_btn.pressed.connect(func() -> void: ed.toggle())
	_rebuild()


func _rebuild() -> void:
	for c in content.get_children():
		c.queue_free()
	coins_lbl.text = "Moedas: %d" % int(Profile.data["coins"])
	xp_lbl.text = "XP: %d" % int(Profile.data["xp"])
	var offers: Array = Profile.data["offers"]
	for i in offers.size():
		var defc := _def_by_name(String(offers[i]))
		if defc.is_empty():
			continue
		var col := i % 3
		var row := i / 3
		var px: float = 170.0 + col * 330.0
		var py: float = 120.0 + row * 290.0
		var cv := CardView.new()
		cv.setup(defc, false, 1.4)
		cv.hover_enabled = false
		cv.drag_enabled = false
		cv.position = Vector2(px, py)
		content.add_child(cv)
		var owned: bool = (Profile.data["owned"] as Array).has(String(defc["name"]))
		if owned:
			cv.set_dimmed(true)
		var price: int = Profile.price_of(defc)
		var b := _btn(Vector2(px - 10, py + 226), Vector2(174, 44), ("ADQUIRIDA" if owned else "COMPRAR: %d moedas" % price), Color(0.2, 0.4, 0.25) if not owned else Color(0.25, 0.24, 0.3), 12)
		if owned:
			b.disabled = true
		else:
			var dn: String = String(defc["name"])
			b.pressed.connect(func() -> void:
				if Profile.spend(price):
					(Profile.data["owned"] as Array).append(dn)
					Profile.save()
					_rebuild()
				else:
					_flash("Moedas insuficientes!"))
		content.add_child(b)


func _flash(t: String) -> void:
	flash_lbl.text = t
	var tw := flash_lbl.create_tween()
	tw.tween_interval(1.5)
	tw.tween_callback(func() -> void: flash_lbl.text = "")


func _def_by_name(nm: String) -> Dictionary:
	for c in CardDB.playable_defs():
		if c["name"] == nm:
			return c
	return {}


func _btn(pos: Vector2, sz: Vector2, text: String, bg: Color, fs: int) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = sz
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = bg.lightened(0.4)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	b.add_theme_stylebox_override("normal", sb)
	var hov := sb.duplicate() as StyleBoxFlat
	hov.bg_color = bg.lightened(0.16)
	var dis := sb.duplicate() as StyleBoxFlat
	dis.bg_color = Color(0.16, 0.15, 0.2)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", hov)
	b.add_theme_stylebox_override("disabled", dis)
	b.add_theme_color_override("font_color", Color(0.96, 0.94, 0.9))
	b.add_theme_font_size_override("font_size", fs)
	return b
